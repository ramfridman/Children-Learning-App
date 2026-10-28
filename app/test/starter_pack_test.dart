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

const String _packPath = 'assets/packs/starter-0.8.0.nnpack';
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

/// Changes the byte at [first], [first] + [stride], ... of the real pack, one at a time, and runs the full
/// [verifyPack] on each changed pack. The byte is changed in place and put back after its check, so each
/// check sees the real pack with exactly one byte changed (and no 3.5 MB copy is made per byte).
Future<_FlipReport> _flipEach(int first, int stride) async {
  final Uint8List bytes = File(_packPath).readAsBytesSync();
  final Uint8List key = _publicKey();
  int refused = 0;
  final List<int> accepted = <int>[];
  for (int i = first; i < bytes.length; i += stride) {
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

/// Changes every [step]th byte of the real pack in turn (offsets 0, step, 2 x step, ...), spread over one
/// worker isolate per processor: worker w takes the offsets w x step, (w + workers) x step, ... so together
/// they take each offset exactly once, and every worker gets bytes from all over the pack. Expects every
/// changed pack to be refused and returns how many were.
Future<int> _refusedFlipsOfEvery(int step) async {
  final int workers = Platform.numberOfProcessors;
  final List<_FlipReport> reports = await Future.wait(<Future<_FlipReport>>[
    for (int w = 0; w < workers; w++) _flipEachInWorker(w * step, workers * step),
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
    expect(pack.version, '0.8.0');
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

  test('every single byte of the real starter pack, changed in turn, is refused (all bytes with NN_EXHAUSTIVE=1 or in CI)', () async {
    final bool full = Platform.environment['NN_EXHAUSTIVE'] == '1' || Platform.environment['CI'] == 'true';
    final Uint8List bytes = File(_packPath).readAsBytesSync();
    final int tried = await _refusedFlipsOfEvery(full ? 1 : 97);
    expect(tried, full ? bytes.length : greaterThan(300));
  }, timeout: const Timeout(Duration(minutes: 60)));

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
    expect((await db.installedPack('starter'))!.version, '0.8.0');
    expect((await installer.load('starter'))!.docs, isNotEmpty);
    // The zip reader accepts the bundled file as a canonical zip.
    expect(readStoredZip(File(_packPath).readAsBytesSync()).length, pack.files.length + 2);
  });
}
