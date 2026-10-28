import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/content/capabilities.dart';
import 'package:nitznutz/content/pack_installer.dart';
import 'package:nitznutz/content/pack_verify.dart';
import 'package:nitznutz/content/zip_store.dart';
import 'package:nitznutz/data/app_database.dart';

import '../tool/pack_builder_lib.dart';
import 'support/pack_fixtures.dart';

/// A registry that fails when asked to save, to prove a crash after the files are in place leaves nothing half-done.
class _FailingRegistry implements PackRegistry {
  _FailingRegistry(this._inner);

  final PackRegistry _inner;
  bool failSave = true;

  @override
  Future<InstalledPack?> find(String id) => _inner.find(id);

  @override
  Future<List<InstalledPack>> all() => _inner.all();

  @override
  Future<void> save({
    required String id,
    required String version,
    required String manifestSha256,
    required DateTime at,
    required bool hidden,
    required String hiddenReason,
  }) {
    if (failSave) throw StateError('the database went away');
    return _inner.save(
      id: id,
      version: version,
      manifestSha256: manifestSha256,
      at: at,
      hidden: hidden,
      hiddenReason: hiddenReason,
    );
  }
}

Matcher _rejected(String stage, [String? reason]) => throwsA(
  isA<PackRejected>()
      .having((PackRejected e) => e.stage, 'stage', stage)
      .having((PackRejected e) => e.reason, 'reason', reason == null ? isNotEmpty : contains(reason)),
);

List<String> _tree(Directory dir) =>
    !dir.existsSync()
          ? <String>[]
          : <String>[
              for (final FileSystemEntity e in dir.listSync(recursive: true, followLinks: false))
                e.path.substring(dir.path.length + 1).replaceAll('\\', '/'),
            ]
      ..sort();

void main() {
  late PackKey key;
  late Directory dir;
  late Directory root;
  late AppDatabase db;
  late PackInstaller installer;

  PackInstaller make({
    PackRegistry? registry,
    AppCapabilities? capabilities,
    DecodeSpy? spy,
    PackKey? trusted,
  }) => PackInstaller(
    root: root,
    registry: registry ?? DbPackRegistry(db),
    publicKey: (trusted ?? key).publicKey,
    capabilities: capabilities ?? AppCapabilities.current,
    decode: spy?.call ?? jsonDecode,
  );

  setUpAll(() async => key = await newTestKey());

  setUp(() {
    dir = Directory.systemTemp.createTempSync('nn_install_');
    root = Directory('${dir.path}${Platform.pathSeparator}packs');
    db = AppDatabase(NativeDatabase.memory());
    installer = make();
  });

  tearDown(() async {
    await db.close();
    dir.deleteSync(recursive: true);
  });

  group('installing', () {
    test('a genuine pack is installed: files on disk, a row in the database, nothing left over', () async {
      final Uint8List pack = (await buildSamplePack(key)).bytes;
      final InstallResult r = await installer.install(pack);
      expect(r.outcome, InstallOutcome.installed);
      expect(r.hidden, isFalse);
      final List<String> tree = _tree(root);
      expect(tree, contains('sample-pack/1.0.0/manifest.json'));
      expect(tree, contains('sample-pack/1.0.0/manifest.sig'));
      expect(tree, contains('sample-pack/1.0.0/activity.count.butterflies.3.json'));
      expect(tree.where((String p) => p.contains('.incoming')), isEmpty);
      final InstalledPack? row = await db.installedPack('sample-pack');
      expect(row!.version, '1.0.0');
      expect(row.manifestSha256, r.pack.manifestSha256);
      expect(row.hidden, isFalse);
    });

    test('the same pack again does nothing', () async {
      final Uint8List pack = (await buildSamplePack(key)).bytes;
      await installer.install(pack);
      final List<String> before = _tree(root);
      final InstallResult again = await installer.install(pack);
      expect(again.outcome, InstallOutcome.alreadyInstalled);
      expect(_tree(root), before);
    });

    test('a copy signed with a key the app no longer trusts is replaced by the same pack signed with the new key', () async {
      final PackKey old = await newTestKey();
      final Uint8List first = (await buildSamplePack(old)).bytes;
      final PackInstaller before = make(trusted: old);
      await before.install(first);
      expect((await before.load('sample-pack'))!.version, '1.0.0');

      // The app now trusts a new key: the old copy no longer proves itself, and the pack signed again is taken.
      final Uint8List again = (await buildSamplePack(key)).bytes;
      final InstallResult r = await installer.install(again);
      expect(r.outcome, InstallOutcome.installed);
      expect((await installer.load('sample-pack'))!.version, '1.0.0');
      expect(
        (await installer.install(again)).outcome,
        InstallOutcome.alreadyInstalled,
        reason: 'now it is protected again',
      );
    });

    test(
      'a copy that still proves itself is never changed by a pack of the same version with other contents',
      () async {
        await installer.install((await buildSamplePack(key)).bytes);
        final Uint8List other = (await buildSamplePack(key, compact: true)).bytes;
        final BuiltPack a = await buildSamplePack(key);
        final BuiltPack b = await buildSamplePack(key, compact: true);
        if (a.manifestSha256 != b.manifestSha256) {
          await expectLater(installer.install(other), _rejected('rules', 'different contents'));
        }
      },
    );

    test('a pack signed by another key is refused and nothing is written', () async {
      final PackKey other = await newTestKey();
      final Uint8List pack = (await buildSamplePack(other)).bytes;
      await expectLater(installer.install(pack), _rejected('signature'));
      expect(_tree(root), isEmpty);
      expect(await db.allInstalledPacks(), isEmpty);
    });

    test('the installer never parses JSON of a pack that fails the checks that come first', () async {
      final DecodeSpy spy = DecodeSpy();
      final PackInstaller spied = make(spy: spy);
      final Uint8List pack = (await buildSamplePack(key)).bytes;
      final Uint8List wrongKey = (await buildSamplePack(await newTestKey())).bytes;
      await expectLater(spied.install(wrongKey), _rejected('signature'));
      expect(spy.seen, isEmpty);
      final Uint8List changed = rezip(pack, (Map<String, Uint8List> e) => e['jar.svg']![3] ^= 1);
      await expectLater(spied.install(changed), _rejected('files'));
      expect(spy.seen, hasLength(1)); // the signed manifest and no other file
    });
  });

  group('versions only go up', () {
    test('a newer version replaces the older one, whose files are removed', () async {
      await installer.install((await buildSamplePack(key)).bytes);
      final InstallResult r = await installer.install((await buildSamplePack(key, version: '1.1.0')).bytes);
      expect(r.outcome, InstallOutcome.installed);
      expect((await db.installedPack('sample-pack'))!.version, '1.1.0');
      final List<String> tree = _tree(root);
      expect(tree.where((String p) => p.startsWith('sample-pack/1.0.0')), isEmpty);
      expect(tree, contains('sample-pack/1.1.0/manifest.json'));
    });

    test('an older version is refused and the installed one is untouched', () async {
      await installer.install((await buildSamplePack(key, version: '1.1.0')).bytes);
      final List<String> before = _tree(root);
      await expectLater(installer.install((await buildSamplePack(key)).bytes), _rejected('rules', 'older'));
      expect(_tree(root), before);
      expect((await db.installedPack('sample-pack'))!.version, '1.1.0');
    });

    test('the same version with different contents is refused', () async {
      await installer.install((await buildSamplePack(key)).bytes);
      final Uint8List other = await forge(
        key,
        (await buildSamplePack(key)).bytes,
        files: (Map<String, Uint8List> f) => f['jar.svg'] = Uint8List.fromList(utf8.encode('<svg/>')),
      );
      await expectLater(installer.install(other), _rejected('rules', 'different contents'));
      expect((await db.installedPack('sample-pack'))!.version, '1.0.0');
    });

    test('1.10.0 is newer than 1.9.0 (versions are numbers, not text)', () async {
      await installer.install((await buildSamplePack(key, version: '1.9.0')).bytes);
      final InstallResult r = await installer.install((await buildSamplePack(key, version: '1.10.0')).bytes);
      expect(r.outcome, InstallOutcome.installed);
    });

    test('the registry says installed but the folder is gone: the pack is written again', () async {
      final Uint8List pack = (await buildSamplePack(key)).bytes;
      await installer.install(pack);
      Directory('${root.path}${Platform.pathSeparator}sample-pack').deleteSync(recursive: true);
      final InstallResult r = await installer.install(pack);
      expect(r.outcome, InstallOutcome.installed);
      expect(_tree(root), contains('sample-pack/1.0.0/manifest.json'));
    });
  });

  group('a pack that needs a newer app or template stays hidden', () {
    Future<Uint8List> needing({String? app, Map<String, String>? templates}) async => forge(
      key,
      (await buildSamplePack(key)).bytes,
      manifest: (Map<String, Object?> m) {
        if (app != null) m['minAppVersion'] = app;
        if (templates != null) (m['templates']! as Map<String, Object?>).addAll(templates);
      },
    );

    test('a newer app is needed', () async {
      final DecodeSpy spy = DecodeSpy();
      final InstallResult r = await make(spy: spy).install(await needing(app: '9.0.0'));
      expect(r.hidden, isTrue);
      expect(r.pack.hiddenReason, contains('needs app version 9.0.0'));
      expect(r.pack.docs, isEmpty);
      expect(spy.seen, hasLength(1)); // only the manifest was read; the activities were not
      final InstalledPack row = (await db.installedPack('sample-pack'))!;
      expect(row.hidden, isTrue);
      expect(row.hiddenReason, contains('9.0.0'));
    });

    test('a template this app does not have', () async {
      final InstallResult r = await installer.install(
        await needing(templates: <String, String>{'drag_sort': '1.0'}),
      );
      expect(r.hidden, isTrue);
      expect(r.pack.hiddenReason, contains('drag_sort'));
    });

    test('a newer version of a template this app has', () async {
      final InstallResult r = await installer.install(
        await needing(templates: <String, String>{'count_tap': '2.0'}),
      );
      expect(r.hidden, isTrue);
      expect(r.pack.hiddenReason, contains('count_tap 2.0'));
    });

    test('it must still be genuine: a hidden pack with a bad signature is refused like any other', () async {
      final PackKey other = await newTestKey();
      final Uint8List forged = await forge(
        other,
        (await buildSamplePack(other)).bytes,
        manifest: (Map<String, Object?> m) => m['minAppVersion'] = '9.0.0',
      );
      await expectLater(installer.install(forged), _rejected('signature'));
      expect(_tree(root), isEmpty);
    });

    test('after an app update it becomes playable when loaded', () async {
      await installer.install(await needing(app: '9.0.0'));
      expect((await installer.load('sample-pack'))!.hidden, isTrue);
      final PackInstaller newer = make(
        capabilities: const AppCapabilities(
          appVersion: '9.0.0',
          templates: <String, String>{'tap_answer': '1.0', 'count_tap': '1.0', 'give_n': '1.0'},
        ),
      );
      final VerifiedPack v = (await newer.load('sample-pack'))!;
      expect(v.hidden, isFalse);
      expect(v.docs, isNotEmpty);
      expect((await db.installedPack('sample-pack'))!.hidden, isFalse);
    });
  });

  group('a crash never leaves half a pack', () {
    test('if the list cannot be saved, the new files are removed and the old pack stays', () async {
      await installer.install((await buildSamplePack(key)).bytes);
      final List<String> before = _tree(root);
      final PackInstaller crashing = make(registry: _FailingRegistry(DbPackRegistry(db)));
      await expectLater(
        crashing.install((await buildSamplePack(key, version: '1.1.0')).bytes),
        throwsStateError,
      );
      expect(_tree(root), before);
      expect((await db.installedPack('sample-pack'))!.version, '1.0.0');
    });

    test('a first install that cannot be saved leaves nothing', () async {
      final PackInstaller crashing = make(registry: _FailingRegistry(DbPackRegistry(db)));
      await expectLater(crashing.install((await buildSamplePack(key)).bytes), throwsStateError);
      expect(_tree(root), isEmpty);
    });

    test('sweep removes temporary folders, old versions and packs that are not installed', () async {
      await installer.install((await buildSamplePack(key)).bytes);
      Directory('${root.path}${Platform.pathSeparator}.incoming-abc').createSync();
      File('${root.path}${Platform.pathSeparator}.incoming-abc${Platform.pathSeparator}x')
          .writeAsStringSync('half');
      Directory('${root.path}${Platform.pathSeparator}sample-pack${Platform.pathSeparator}0.9.0')
          .createSync(recursive: true);
      Directory('${root.path}${Platform.pathSeparator}stranger-pack${Platform.pathSeparator}1.0.0')
          .createSync(recursive: true);
      await installer.sweep();
      final List<String> tree = _tree(root);
      expect(
        tree.where((String p) => p.contains('incoming') || p.contains('0.9.0') || p.contains('stranger')),
        isEmpty,
      );
      expect(tree, contains('sample-pack/1.0.0/manifest.json'));
    });
  });

  group('loading an installed pack proves it again', () {
    test('an untouched pack loads', () async {
      await installer.install((await buildSamplePack(key)).bytes);
      final VerifiedPack v = (await installer.load('sample-pack'))!;
      expect(v.docs, isNotEmpty);
      expect(await installer.load('no-such-pack'), isNull);
    });

    test('a file changed on disk afterwards is noticed', () async {
      await installer.install((await buildSamplePack(key)).bytes);
      final File f = File(
        '${root.path}${Platform.pathSeparator}sample-pack${Platform.pathSeparator}1.0.0${Platform.pathSeparator}jar.svg',
      );
      f.writeAsStringSync('<svg><script/></svg>');
      await expectLater(installer.load('sample-pack'), _rejected('files', 'jar.svg'));
    });

    test('a file deleted or added on disk is noticed', () async {
      await installer.install((await buildSamplePack(key)).bytes);
      final String base =
          '${root.path}${Platform.pathSeparator}sample-pack${Platform.pathSeparator}1.0.0${Platform.pathSeparator}';
      File('${base}extra.bin').writeAsBytesSync(<int>[1]);
      await expectLater(installer.load('sample-pack'), _rejected('files', 'extra.bin'));
      File('${base}extra.bin').deleteSync();
      File('${base}jar.svg').deleteSync();
      await expectLater(installer.load('sample-pack'), _rejected('files', 'jar.svg'));
    });

    test('the whole folder gone is noticed', () async {
      await installer.install((await buildSamplePack(key)).bytes);
      Directory('${root.path}${Platform.pathSeparator}sample-pack').deleteSync(recursive: true);
      await expectLater(installer.load('sample-pack'), _rejected('disk', 'missing'));
    });
  });

  group('the acceptance test: one changed byte, whatever the byte', () {
    final bool full = Platform.environment['NN_EXHAUSTIVE'] == '1' || Platform.environment['CI'] == 'true';

    test(
      'every byte of a real pack, changed in turn, is refused; nothing is installed or left behind',
      () async {
        final Uint8List pack = (await buildSamplePack(key, compact: true)).bytes;
        // Sanity: the unchanged pack installs (then we undo it).
        await installer.install(pack);
        Directory('${root.path}${Platform.pathSeparator}sample-pack').deleteSync(recursive: true);
        await db.customStatement('DELETE FROM installed_packs');

        int refused = 0;
        for (int i = 0; i < pack.length; i++) {
          final Uint8List bad = Uint8List.fromList(pack)..[i] ^= 0x01;
          try {
            await installer.install(bad);
            fail('byte $i of ${pack.length} was changed and the pack was installed');
          } on PackRejected {
            refused++;
          }
          if (i % 97 == 0 || i == pack.length - 1) {
            expect(_tree(root), isEmpty, reason: 'after byte $i');
            expect(await db.allInstalledPacks(), isEmpty, reason: 'after byte $i');
          }
        }
        expect(refused, pack.length);
      },
      timeout: const Timeout(Duration(minutes: 10)),
    );

    test(
      'the same, with the zip checksum and layout made valid again so only the signature and hashes can catch it ${full ? '(every byte)' : '(every 23rd byte; NN_EXHAUSTIVE=1 or CI does all)'}',
      () async {
        final Uint8List pack = (await buildSamplePack(key, compact: true)).bytes;
        final Map<String, Uint8List> entries = unzip(pack);
        int tried = 0;
        for (final MapEntry<String, Uint8List> e in entries.entries) {
          final Uint8List original = Uint8List.fromList(e.value);
          final int stride = full ? 1 : 23;
          for (int i = 0; i < original.length; i += (i < 8 || i > original.length - 9) ? 1 : stride) {
            entries[e.key] = Uint8List.fromList(original)..[i] ^= 0x20;
            final Uint8List bad = writeStoredZip(<ZipEntry>[
              for (final MapEntry<String, Uint8List> x in entries.entries) ZipEntry(x.key, x.value),
            ]);
            try {
              await installer.install(bad);
              fail('byte $i of ${e.key} was changed and the pack was installed');
            } on PackRejected catch (r) {
              expect(
                <String>['signature', 'files'],
                contains(r.stage),
                reason: '${e.key} byte $i: ${r.reason}',
              );
            }
            tried++;
          }
          entries[e.key] = original;
        }
        expect(_tree(root), isEmpty);
        expect(await db.allInstalledPacks(), isEmpty);
        expect(tried, greaterThan(200));
      },
      timeout: const Timeout(Duration(minutes: 15)),
    );
  });
}
