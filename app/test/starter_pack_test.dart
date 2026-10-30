import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/content/pack_installer.dart';
import 'package:nitznutz/content/pack_verify.dart';
import 'package:nitznutz/content/zip_store.dart';
import 'package:nitznutz/data/app_database.dart';

const String _packPath = 'assets/packs/starter-0.10.0.nnpack';
const String _keyPath = 'assets/pack_signing_public_key.txt';
const String _sourcePath = '../content/starter';

Uint8List _publicKey() => unhex(File(_keyPath).readAsStringSync());

/// The text files of the source folder as the builder reads them (line ends made the same on every system).
Uint8List _source(String name) {
  final Uint8List raw = File('$_sourcePath/$name').readAsBytesSync();
  if (!RegExp(r'\.(json|svg|txt)$').hasMatch(name)) return raw;
  return Uint8List.fromList(<int>[
    for (int i = 0; i < raw.length; i++)
      if (!(raw[i] == 0x0D && i + 1 < raw.length && raw[i + 1] == 0x0A)) raw[i],
  ]);
}

Map<String, Object?> _m(Object? o) => o! as Map<String, Object?>;

/// What one worker found: how many changed packs were refused, the offsets of any that were accepted, and
/// whether its copy, with every byte put back, was the genuine pack again at the end.
typedef _FlipReport = ({int refused, List<int> accepted, bool restoredIsGenuine});

/// The offsets [first], [first] + [stride], ... below [length].
Iterable<int> _offsets(int first, int stride, int length) sync* {
  for (int i = first; i < length; i += stride) {
    yield i;
  }
}

/// How many offsets [first], [first] + [step], ... lie below [length] (for 0 <= [first] < [step]).
int _countOf(int first, int step, int length) => (length - first + step - 1) ~/ step;

/// The part of the every-byte test this run takes, read from `NN_FLIP_SHARD` (`<index>/<total>`): the offsets i
/// with i % total == index, so that the parts 0/total to (total - 1)/total together take every offset once.
/// Unset or empty is the whole pack (`0/1`). Anything else that is not such a part fails the test: a mistyped
/// switch must never quietly test fewer bytes.
({int index, int total}) _flipShard(String? raw) {
  if (raw == null || raw.isEmpty) return (index: 0, total: 1);
  final RegExpMatch? m = RegExp(r'^(\d{1,9})/(\d{1,9})$').firstMatch(raw);
  final int index = m == null ? -1 : int.parse(m[1]!);
  final int total = m == null ? 0 : int.parse(m[2]!);
  if (total < 1 || index < 0 || index >= total) {
    fail('NN_FLIP_SHARD="$raw" is not <index>/<total> with total >= 1 and 0 <= index < total');
  }
  return (index: index, total: total);
}

/// Fails if there are more parts than the [length] bytes of the pack: such a switch (say 999999/1000000) would
/// change almost no byte and still pass.
void _expectPartsFit(({int index, int total}) shard, int length) {
  if (shard.total > length) {
    fail('NN_FLIP_SHARD=${shard.index}/${shard.total}: more parts than the $length bytes of the pack');
  }
}

/// The (first, stride) of each of [workers] workers that together take the offsets [first], [first] + [step], ...
/// each exactly once: worker w takes [first] + w x [step], then every (workers x step)th offset after it, so every
/// worker gets bytes from all over the pack.
List<({int first, int stride})> _workerSlices(int first, int step, int workers) =>
    <({int first, int stride})>[
      for (int w = 0; w < workers; w++) (first: first + w * step, stride: workers * step),
    ];

/// Changes the byte at [first], [first] + [stride], ... of the real pack, one at a time, and runs the full
/// [verifyPack] on each changed pack. The byte is changed in place and put back after its check, so each
/// check sees the real pack with exactly one byte changed (and no 3.5 MB copy is made per byte).
Future<_FlipReport> _flipEach(int first, int stride) async {
  final Uint8List bytes = File(_packPath).readAsBytesSync();
  final Uint8List key = _publicKey();
  int refused = 0;
  final List<int> accepted = <int>[];
  for (final int i in _offsets(first, stride, bytes.length)) {
    bytes[i] ^= 0x01;
    try {
      await verifyPack(bytes, publicKey: key);
      accepted.add(i);
    } on PackRejected {
      refused++;
    } finally {
      bytes[i] ^= 0x01;
    }
  }
  bool restoredIsGenuine = true;
  try {
    await verifyPack(bytes, publicKey: key);
  } on PackRejected {
    restoredIsGenuine = false;
  }
  return (refused: refused, accepted: accepted, restoredIsGenuine: restoredIsGenuine);
}

/// [_flipEach] in a new isolate (a top-level function, so the closure sent to it holds only two ints).
Future<_FlipReport> _flipEachInWorker(int first, int stride) => Isolate.run(() => _flipEach(first, stride));

/// What became of the real pack with one byte of the file [name] changed and the zip written again with
/// [writeStoredZip], so that every CRC is right and the zip is canonical (an attacker who repairs the checksums):
/// whether the zip reader takes the new zip, and the stage and reason [verifyPack] refused it with ([stage] null if it
/// was accepted).
typedef _FixedUp = ({String name, bool readsBack, String? stage, String reason});

/// Changes the middle byte of `entries[index]` (an empty file gets one byte), writes the zip again and verifies it.
Future<_FixedUp> _fixedUp(List<ZipEntry> entries, int index, Uint8List key) async {
  final ZipEntry target = entries[index];
  final Uint8List data = target.data;
  final Uint8List changed = data.isEmpty
      ? Uint8List(1)
      : (Uint8List.fromList(data)..[data.length ~/ 2] ^= 0x01);
  final Uint8List zip = writeStoredZip(<ZipEntry>[
    for (final ZipEntry e in entries) identical(e, target) ? ZipEntry(e.name, changed) : e,
  ]);
  bool readsBack = true;
  try {
    readStoredZip(zip);
  } on ZipException {
    readsBack = false;
  }
  try {
    await verifyPack(zip, publicKey: key);
    return (name: target.name, readsBack: readsBack, stage: null, reason: 'accepted');
  } on PackRejected catch (e) {
    return (name: target.name, readsBack: readsBack, stage: e.stage, reason: e.reason);
  }
}

/// [_fixedUp] for the content files number [first], [first] + [stride], ... of the real pack (every file but the
/// manifest and its signature, in zip order).
Future<List<_FixedUp>> _fixedUpEach(int first, int stride) async {
  final Uint8List key = _publicKey();
  final List<ZipEntry> entries = readStoredZip(File(_packPath).readAsBytesSync());
  final List<int> content = <int>[
    for (int i = 0; i < entries.length; i++)
      if (entries[i].name != manifestName && entries[i].name != signatureName) i,
  ];
  return <_FixedUp>[
    for (int k = first; k < content.length; k += stride) await _fixedUp(entries, content[k], key),
  ];
}

/// [_fixedUpEach] in a new isolate.
Future<List<_FixedUp>> _fixedUpEachInWorker(int first, int stride) =>
    Isolate.run(() => _fixedUpEach(first, stride));

/// [_fixedUp] for the one file [name] of the real pack.
Future<_FixedUp> _fixedUpFile(String name) {
  final List<ZipEntry> entries = readStoredZip(File(_packPath).readAsBytesSync());
  return _fixedUp(entries, entries.indexWhere((ZipEntry e) => e.name == name), _publicKey());
}

/// Changes every [step]th byte of the real pack in turn (offsets first, first + step, first + 2 x step, ...),
/// spread over one worker isolate per processor ([_workerSlices]). Expects every changed pack to be refused and
/// returns how many were.
Future<int> _refusedFlipsOfEvery(int step, {int first = 0}) async {
  final List<_FlipReport> reports = await Future.wait(<Future<_FlipReport>>[
    for (final ({int first, int stride}) s in _workerSlices(first, step, Platform.numberOfProcessors))
      _flipEachInWorker(s.first, s.stride),
  ]);
  final List<int> accepted = <int>[for (final _FlipReport r in reports) ...r.accepted]..sort();
  expect(accepted, isEmpty, reason: 'these bytes were changed and the pack was accepted');
  expect(<bool>[for (final _FlipReport r in reports) r.restoredIsGenuine], everyElement(isTrue));
  return reports.fold<int>(0, (int sum, _FlipReport r) => sum + r.refused);
}

void main() {
  late VerifiedPack pack;

  setUpAll(() async {
    pack = await verifyPack(File(_packPath).readAsBytesSync(), publicKey: _publicKey());
  });

  test('the bundled starter pack is genuine: it verifies against the public key built into the app', () {
    expect(pack.id, 'starter');
    expect(pack.version, '0.10.0');
    expect(pack.hidden, isFalse);
  });

  test('the public key is a single 32-byte Ed25519 key in hexadecimal', () {
    expect(File(_keyPath).readAsStringSync().trim(), matches(RegExp(r'^[0-9a-f]{64}$')));
  });

  test('the pack was built from the sources in content/starter and nothing else', () {
    // Anyone can rebuild with their own key to compare the contents; the signature is the owner's.
    final Set<String> sources = <String>{
      for (final FileSystemEntity e in Directory(_sourcePath).listSync())
        if (e is File && !e.path.endsWith('pack.json')) e.uri.pathSegments.last,
    };
    expect(pack.files.keys.toSet(), sources);
    for (final MapEntry<String, Uint8List> f in pack.files.entries) {
      expect(f.value, _source(f.key), reason: '${f.key} differs from content/starter: rebuild the pack');
    }
  });

  test('a signature from any other key is refused', () async {
    final Uint8List other = Uint8List.fromList(List<int>.generate(32, (int i) => i + 1));
    await expectLater(
      verifyPack(File(_packPath).readAsBytesSync(), publicKey: other),
      throwsA(isA<PackRejected>()),
    );
  });

  // The two tests below wait on worker isolates, so their timeouts really apply. (Before B-12 the flips ran
  // in one loop that never gave the event loop a turn, so neither the default 30 s nor the 10 minutes ever
  // fired: the every-31st-byte test ran 865 s here, the every-byte test 27 minutes on CI for pack 0.5.1.)
  test('one changed byte anywhere in the real pack is refused (every 31st byte here)', () async {
    final int length = File(_packPath).lengthSync();
    expect(await _refusedFlipsOfEvery(31), (length + 30) ~/ 31);
  }, timeout: const Timeout(Duration(minutes: 10)));

  // CI runs this test as several parts side by side, each with its own NN_FLIP_SHARD=<index>/<total>; each part
  // checks its own count, and the CI check requires the "flip shard" line, so a part that ignored the switch fails.
  test('every single byte of the real starter pack, changed in turn, is refused (all bytes with NN_EXHAUSTIVE=1 or in CI)', () async {
    final ({int index, int total}) shard = _flipShard(Platform.environment['NN_FLIP_SHARD']);
    final bool full = Platform.environment['NN_EXHAUSTIVE'] == '1' || Platform.environment['CI'] == 'true';
    final Uint8List bytes = File(_packPath).readAsBytesSync();
    _expectPartsFit(shard, bytes.length);
    // Full: this part's offsets (every byte with 0/1). Here: every 97th byte, whatever the part.
    final int first = full ? shard.index : 0;
    final int step = full ? shard.total : 97;
    final int tried = await _refusedFlipsOfEvery(step, first: first);
    if (full) {
      // ignore: avoid_print
      print('flip shard ${shard.index}/${shard.total}: $tried of ${bytes.length} offsets refused');
    }
    expect(tried, _countOf(first, step, bytes.length));
  }, timeout: const Timeout(Duration(minutes: 60)));

  test('the parts of the every-byte test (NN_FLIP_SHARD) take every offset exactly once, for any length', () {
    // The counts the parts expect add up to the length, the real pack's included.
    for (final int length in <int>[1, 5, 12, 97, 100, 1009, File(_packPath).lengthSync()]) {
      for (int total = 1; total <= 7; total++) {
        int expected = 0;
        for (int index = 0; index < total; index++) {
          expected += _countOf(index, total, length);
        }
        expect(expected, length, reason: 'the counts of $total parts add up to $length');
      }
    }
    // The offsets the parts' workers really take: each part only its own, as many as it expects, and all the parts
    // together every offset exactly once (lengths divisible by total and not, any number of workers).
    for (final int length in <int>[1, 5, 12, 97, 100, 1009]) {
      for (int total = 1; total <= 7; total++) {
        for (final int workers in <int>{1, 3, 4, 16, Platform.numberOfProcessors}) {
          final List<int> seen = List<int>.filled(length, 0);
          for (int index = 0; index < total; index++) {
            final ({int index, int total}) shard = _flipShard('$index/$total');
            final List<int> part = <int>[
              for (final ({int first, int stride}) s in _workerSlices(shard.index, shard.total, workers))
                ..._offsets(s.first, s.stride, length),
            ];
            final String where = 'part $index/$total, $workers workers, length $length';
            expect(part.every((int i) => i % total == index), isTrue, reason: where);
            expect(part.length, _countOf(index, total, length), reason: where);
            for (final int i in part) {
              seen[i]++;
            }
          }
          expect(
            seen,
            everyElement(1),
            reason: '$total parts, $workers workers, length $length: each offset once',
          );
        }
      }
    }
  });

  test('NN_FLIP_SHARD: unset or empty is the whole pack, a part is <index>/<total>, anything else fails', () {
    expect(_flipShard(null), (index: 0, total: 1));
    expect(_flipShard(''), (index: 0, total: 1));
    expect(_flipShard('0/1'), (index: 0, total: 1));
    expect(_flipShard('5/6'), (index: 5, total: 6));
    for (final String bad in <String>[
      '6/6',
      '7/6',
      '0/0',
      '-1/6',
      '1/-6',
      '5',
      '5/',
      '/6',
      '5/6/7',
      ' 5/6',
      '5/6 ',
      '5/6\n',
      'a/6',
      '1.0/6',
      '5\\6',
      '9999999999/6',
    ]) {
      expect(() => _flipShard(bad), throwsA(isA<TestFailure>()), reason: bad);
    }
    // A part must have bytes to take: at most as many parts as the pack has bytes.
    _expectPartsFit((index: 5, total: 6), 6);
    _expectPartsFit((index: 0, total: 1), 1);
    expect(() => _expectPartsFit((index: 0, total: 7), 6), throwsA(isA<TestFailure>()));
    expect(() => _expectPartsFit((index: 999998, total: 999999), 3505), throwsA(isA<TestFailure>()));
  });

  // Every flip above is caught by a file's CRC or the zip rules before the signature or a hash is looked at. The three
  // tests below are the attacker who repairs the CRCs: the zip they make is valid, so only the hashes and the signature
  // stand between it and the child.
  test('one changed byte in any file of the real pack, with the checksums repaired, is refused by that file\'s hash', () async {
    final int workers = Platform.numberOfProcessors;
    final List<_FixedUp> all = <_FixedUp>[
      for (final List<_FixedUp> part in await Future.wait(<Future<List<_FixedUp>>>[
        for (int w = 0; w < workers; w++) _fixedUpEachInWorker(w, workers),
      ]))
        ...part,
    ];
    expect(all.length, pack.files.length, reason: 'each file once');
    expect(<String>{for (final _FixedUp r in all) r.name}, pack.files.keys.toSet());
    final List<String> wrong = <String>[
      for (final _FixedUp r in all)
        if (!r.readsBack || r.stage != 'files' || !r.reason.contains('"${r.name}"'))
          '${r.name}: ${r.readsBack ? '' : 'the zip reader refused it, '}${r.stage ?? 'accepted'}: ${r.reason}',
    ];
    expect(wrong, isEmpty, reason: 'each must be a valid zip refused at "files", naming the file');
  }, timeout: const Timeout(Duration(minutes: 10)));

  test(
    'one changed byte in manifest.json, with the checksums repaired, is refused by the signature',
    () async {
      final _FixedUp r = await _fixedUpFile(manifestName);
      expect(r.readsBack, isTrue, reason: 'the zip is valid');
      expect(r.stage, 'signature', reason: r.reason);
    },
  );

  test(
    'one changed byte in manifest.sig, with the checksums repaired, is refused by the signature',
    () async {
      final _FixedUp r = await _fixedUpFile(signatureName);
      expect(r.readsBack, isTrue, reason: 'the zip is valid');
      expect(r.stage, 'signature', reason: r.reason);
    },
  );

  test('the lesson has the five items of the script, in order', () {
    final Map<String, Object?> lesson = _m(pack.docs['lesson.butterflies.json']);
    expect(lesson['items'], <String>[
      'pick.red.flower',
      'count.butterflies.3',
      'count.butterflies.4',
      'count.butterflies.5',
      'give.butterflies.4',
    ]);
    expect(lesson['band'], 'A');
  });

  test('the counting activities carry the misconception tags of the curriculum', () {
    for (final int n in <int>[3, 4, 5]) {
      final Map<String, Object?> a = _m(pack.docs['activity.count.butterflies.$n.json']);
      final List<Map<String, Object?>> options = <Map<String, Object?>>[
        for (final Object? o in _m(a['answer'])['options']! as List<Object?>) _m(o),
      ];
      expect(<Object?>[for (final Map<String, Object?> o in options) o['value']], <int>[n - 1, n, n + 1]);
      expect(options[0]['misconception'], 'M-CNT-SKIP');
      expect(options[1].containsKey('misconception'), isFalse);
      expect(options[2]['misconception'], 'M-CNT-DOUBLE');
    }
    final Map<String, Object?> give = _m(pack.docs['activity.give.butterflies.4.json']);
    final Map<String, Object?> answer = _m(give['answer']);
    expect(answer['n'], 4);
    expect(_m(_m(give['scene'])['source'])['count'], 7);
    expect((answer['classifiers']! as List<Object?>).single, <String, Object?>{
      'when': 'took_all',
      'misconception': 'M-CNT-CARD',
    });
  });

  test('the counting scenes follow the script: line then scatter, fly then glow', () {
    Map<String, Object?> objects(int n) =>
        _m(_m(_m(pack.docs['activity.count.butterflies.$n.json'])['scene'])['objects']);
    expect(objects(3)['arrangement'], 'line');
    expect(objects(3)['onTap'], 'fly_to_target');
    expect(objects(4)['arrangement'], 'scatter');
    expect(objects(4)['onTap'], 'fly_to_target');
    expect(objects(5)['arrangement'], 'scatter');
    expect(objects(5)['onTap'], 'glow');
  });

  test('every document is still marked needs-editor and none is marked approved', () {
    for (final MapEntry<String, Object?> d in pack.docs.entries) {
      expect(_m(d.value)['review'], 'needs-editor', reason: d.key);
    }
  });

  test('the hint ladder follows the credit table of the curriculum (1.0, 0.8, 0.5, 0.0)', () {
    for (final MapEntry<String, Object?> d in pack.docs.entries) {
      if (!d.key.startsWith('activity.')) continue;
      expect(_m(_m(d.value)['scoring'])['creditByHintLevel'], <Object?>[1, 0.8, 0.5, 0], reason: d.key);
    }
  });

  test('no voice recording is shipped yet: every spoken line is pending (voice arrives in M4)', () {
    expect(pack.manifest['vo'], isEmpty);
    expect((pack.manifest['voPending']! as List<Object?>).length, greaterThan(20));
  });

  test('the pictures are plain drawings: no script, no outside links, no embedded data', () {
    for (final MapEntry<String, Uint8List> f in pack.files.entries) {
      if (!f.key.endsWith('.svg')) continue;
      final String text = utf8.decode(f.value).toLowerCase();
      for (final String bad in <String>[
        '<script',
        'href',
        'data:',
        '<image',
        '<foreignobject',
        'onload',
        '<style',
        'url(',
      ]) {
        expect(text, isNot(contains(bad)), reason: '${f.key} contains $bad');
      }
    }
  });

  test('the starter pack installs with the key built into the app', () async {
    final Directory dir = Directory.systemTemp.createTempSync('nn_starter_');
    final AppDatabase db = AppDatabase(NativeDatabase.memory());
    addTearDown(() async {
      await db.close();
      dir.deleteSync(recursive: true);
    });
    final PackInstaller installer = PackInstaller(
      root: Directory('${dir.path}/packs'),
      registry: DbPackRegistry(db),
      publicKey: _publicKey(),
    );
    final InstallResult r = await installer.install(File(_packPath).readAsBytesSync());
    expect(r.outcome, InstallOutcome.installed);
    expect((await db.installedPack('starter'))!.version, '0.10.0');
    expect((await installer.load('starter'))!.docs, isNotEmpty);
    // The zip reader accepts the bundled file as a canonical zip.
    expect(readStoredZip(File(_packPath).readAsBytesSync()).length, pack.files.length + 2);
  });
}
