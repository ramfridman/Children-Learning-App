// The language packs that ship inside the app: found by file name, installed through the verifying installer only for a language some
// child has turned on, never installed over a newer copy, put right when the installed copy is damaged, and never a reason for another
// course (or a land) to fail. The packs are the pilot sources of the three courses, signed with a throw-away key.
import 'dart:io';
import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/app/language_providers.dart';
import 'package:nitznutz/app/state.dart';
import 'package:nitznutz/content/bundled_packs.dart';
import 'package:nitznutz/content/content_repository.dart';
import 'package:nitznutz/content/models.dart';
import 'package:nitznutz/content/pack_installer.dart';
import 'package:nitznutz/data/app_database.dart';
import 'package:nitznutz/engine/course.dart';
import 'package:nitznutz/parent/language_settings.dart';

import '../tool/pack_builder_lib.dart';
import 'support/pack_fixtures.dart';

const String _languages = '../content/languages';
const String _kid = 'child-bundle-0001';

/// The bundle as a test sees it: the files by asset path, and how often each was read.
class _Bundle {
  _Bundle(this.files);

  final Map<String, Uint8List> files;
  final List<String> reads = <String>[];
  int lists = 0;

  Future<List<String>> list() async {
    lists++;
    return <String>['assets/packs/starter-0.10.0.nnpack', ...files.keys, 'assets/art/x.svg'];
  }

  Future<Uint8List> read(String asset) async {
    reads.add(asset);
    return files[asset]!;
  }

  BundledAssets get assets => BundledAssets(list: list, read: read);
}

void main() {
  late PackKey key;
  late Map<String, Uint8List> built;
  late Directory dir;
  late AppDatabase db;
  late PackInstaller installer;
  late ContentRepository repo;

  setUpAll(() async {
    key = await newTestKey();
    built = <String, Uint8List>{
      for (final String c in Course.languages)
        'assets/packs/lang-$c-0.1.0.nnpack': (await buildPack(languageSource(c, _languages), key)).bytes,
    };
  });

  setUp(() {
    dir = Directory.systemTemp.createTempSync('nn_bundle_');
    db = AppDatabase(NativeDatabase.memory());
    installer = PackInstaller(
      root: Directory('${dir.path}${Platform.pathSeparator}packs'),
      registry: DbPackRegistry(db),
      publicKey: key.publicKey,
    );
    repo = ContentRepository(installer: installer, bundled: () async => Uint8List(0));
  });

  tearDown(() async {
    await db.close();
    dir.deleteSync(recursive: true);
  });

  group('the file names', () {
    test('the newest pack of each course, and nothing that is not a language pack', () {
      final Map<String, BundledLanguagePack> m = BundledLanguagePack.newestOf(<String>[
        'assets/packs/starter-0.10.0.nnpack',
        'assets/packs/lang-eng-0.2.0.nnpack',
        'assets/packs/lang-eng-0.10.0.nnpack',
        'assets/packs/lang-eng-0.9.1.nnpack',
        'assets/packs/lang-heb-1.0.0.nnpack',
        'assets/packs/lang-fra-1.0.0.nnpack',
        'assets/packs/lang-rus-1.0.nnpack',
        'assets/packs/lang-rus-1.0.0.zip',
        'assets/characters/lang-rus-1.0.0.nnpack',
        'assets/art/x.svg',
      ]);
      expect(m.keys.toSet(), <String>{'eng', 'heb'});
      expect(m['eng']!.version, '0.10.0', reason: 'compared as numbers, not as text');
      expect(m['eng']!.asset, 'assets/packs/lang-eng-0.10.0.nnpack');
      expect(m['heb']!.version, '1.0.0');
    });

    test('nothing at all when no language pack ships', () {
      expect(BundledLanguagePack.newestOf(const <String>['assets/packs/starter-0.10.0.nnpack']), isEmpty);
    });
  });

  group('the repository', () {
    Future<Map<String, PackContent>> load(_Bundle b, Iterable<String> wanted) async => repo.languagePacks(
      wanted: wanted,
      bundled: BundledLanguagePack.newestOf(await b.list()),
      read: b.read,
    );

    test('a family with no language on installs nothing and reads no file', () async {
      final _Bundle b = _Bundle(built);
      expect(await load(b, const <String>[]), isEmpty);
      expect(b.reads, isEmpty);
      expect(await repo.installedLanguages(), isEmpty);
    });

    test('a language that is on gets its bundled pack, and only that language', () async {
      final _Bundle b = _Bundle(built);
      final Map<String, PackContent> packs = await load(b, <String>['eng']);
      expect(packs.keys, <String>['eng']);
      expect(packs['eng']!.packId, 'lang-eng');
      expect(b.reads, <String>['assets/packs/lang-eng-0.1.0.nnpack']);
      expect(await repo.installedLanguages(), <String>['eng']);
    });

    test('the next start reads no file again: the installed copy is the bundled version', () async {
      final _Bundle b = _Bundle(built);
      await load(b, <String>['eng', 'heb']);
      b.reads.clear();
      final Map<String, PackContent> packs = await load(b, <String>['eng', 'heb']);
      expect(packs.keys, <String>['eng', 'heb']);
      expect(b.reads, isEmpty);
    });

    test(
      'a language that was on and is off now still plays from what is installed (nothing is deleted)',
      () async {
        final _Bundle b = _Bundle(built);
        await load(b, <String>['eng']);
        expect((await load(b, const <String>[])).keys, <String>['eng']);
      },
    );

    test('a newer copy that arrived first is kept; an older one is replaced', () async {
      final Directory src = Directory.systemTemp.createTempSync('nn_bundle_src_');
      addTearDown(() => src.deleteSync(recursive: true));
      for (final FileSystemEntity e in languageSource('eng', _languages).listSync()) {
        if (e is File) e.copySync('${src.path}${Platform.pathSeparator}${e.uri.pathSegments.last}');
      }
      final File pack = File('${src.path}${Platform.pathSeparator}pack.json');
      pack.writeAsStringSync(pack.readAsStringSync().replaceFirst('"0.1.0"', '"0.2.0"'));
      await installer.install((await buildPack(src, key)).bytes);

      final _Bundle old = _Bundle(built);
      final Map<String, PackContent> packs = await load(old, <String>['eng']);
      expect(old.reads, isEmpty, reason: 'the installed 0.2.0 is newer than the bundled 0.1.0');
      expect(packs['eng'], isNotNull);
      expect((await installer.registry.find('lang-eng'))!.version, '0.2.0');

      pack.writeAsStringSync(pack.readAsStringSync().replaceFirst('"0.2.0"', '"0.3.0"'));
      final _Bundle newer = _Bundle(<String, Uint8List>{
        'assets/packs/lang-eng-0.3.0.nnpack': (await buildPack(src, key)).bytes,
      });
      await load(newer, <String>['eng']);
      expect((await installer.registry.find('lang-eng'))!.version, '0.3.0');
      expect(Directory('${installer.root.path}${Platform.pathSeparator}lang-eng').listSync().length, 1);
    });

    test('an installed copy that no longer proves itself is put right from the bundle', () async {
      final _Bundle b = _Bundle(built);
      await load(b, <String>['eng']);
      final File skill = File(
        '${installer.packDir('lang-eng', '0.1.0').path}${Platform.pathSeparator}skill.ENG-A-01.json',
      );
      skill.writeAsStringSync('${skill.readAsStringSync()} ');
      b.reads.clear();
      final Map<String, PackContent> packs = await load(b, <String>['eng']);
      expect(packs.keys, <String>['eng'], reason: 'repaired');
      expect(b.reads, <String>['assets/packs/lang-eng-0.1.0.nnpack']);
    });

    test('a bundled pack signed by a stranger is left out, and the other courses are not hurt', () async {
      final PackKey stranger = await newTestKey();
      final _Bundle b = _Bundle(<String, Uint8List>{
        ...built,
        'assets/packs/lang-eng-0.1.0.nnpack': (await buildPack(
          languageSource('eng', _languages),
          stranger,
        )).bytes,
      });
      final Map<String, PackContent> packs = await load(b, <String>['eng', 'heb', 'rus']);
      expect(packs.keys, <String>['heb', 'rus']);
      expect(await repo.installedLanguages(), <String>['heb', 'rus']);
    });

    test('a bundled file that is not a pack at all changes nothing', () async {
      final _Bundle b = _Bundle(<String, Uint8List>{
        'assets/packs/lang-rus-0.1.0.nnpack': Uint8List.fromList(<int>[1, 2, 3]),
      });
      expect(await load(b, <String>['rus']), isEmpty);
    });

    test('a pack under the wrong name cannot stand for another course', () async {
      // The file says rus, the pack says eng: the installer installs the pack it proved (lang-eng), and the rus slot stays empty.
      final _Bundle b = _Bundle(<String, Uint8List>{
        'assets/packs/lang-rus-0.1.0.nnpack': built['assets/packs/lang-eng-0.1.0.nnpack']!,
      });
      final Map<String, PackContent> packs = await load(b, <String>['rus']);
      expect(packs.containsKey('rus'), isFalse);
    });
  });

  group('the provider', () {
    late _Bundle bundle;
    late ProviderContainer c;

    setUp(() {
      bundle = _Bundle(built);
      c = ProviderContainer(
        overrides: [
          databaseProvider.overrideWith((Ref ref) async => db),
          packInstallerProvider.overrideWith((Ref ref) async => installer),
          bundledAssetsProvider.overrideWithValue(bundle.assets),
        ],
      );
      addTearDown(c.dispose);
    });

    Future<void> setSwitches(String course, LanguageSwitches s) async {
      await c.read(languagesProvider.future);
      expect(await c.read(languagesProvider.notifier).setSwitches(_kid, course, s), isTrue);
    }

    test('no language on: the packs are the empty map, and the bundle is not read', () async {
      expect(await c.read(languagePacksProvider.future), isEmpty);
      expect(bundle.reads, isEmpty);
    });

    test('turning a language on installs its pack; the door appears only then (frame 1.1)', () async {
      expect(await c.read(languagePacksProvider.future), isEmpty);
      await setSwitches('eng', const LanguageSwitches(on: true));
      final Map<String, PackContent> packs = await c.read(languagePacksProvider.future);
      expect(packs.keys, <String>['eng']);
      expect(c.read(languagesAvailableProvider(_kid)), <String>['eng']);
      expect(bundle.reads, <String>['assets/packs/lang-eng-0.1.0.nnpack']);
    });

    test('another switch of a language does not read the packs again', () async {
      await setSwitches('eng', const LanguageSwitches(on: true));
      await c.read(languagePacksProvider.future);
      final int lists = bundle.lists;
      await setSwitches('eng', const LanguageSwitches(on: true, personal: false));
      await c.read(languagePacksProvider.future);
      expect(bundle.lists, lists, reason: 'the same languages are on, so nothing is read again');
    });

    test('a second language on installs the second pack and keeps the first', () async {
      await setSwitches('eng', const LanguageSwitches(on: true));
      await c.read(languagePacksProvider.future);
      await setSwitches('rus', const LanguageSwitches(on: true));
      final Map<String, PackContent> packs = await c.read(languagePacksProvider.future);
      expect(packs.keys, <String>['eng', 'rus']);
    });
  });
}
