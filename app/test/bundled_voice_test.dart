// Nitzi's voice inside the app: `assets/characters/voice-nitzi(-N)?-<version>.nnpack`, installed through the verifying installer
// the first time a voice is read, only when the phone does not hold that version or a newer one. The files are not in the
// repository (about 98 MiB; .gitignore), so the checks of the real files pass with them and without them, and a guard fails
// if any asset is named for a personal character.
import 'dart:io';
import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/characters/character.dart';
import 'package:nitznutz/app/companion.dart' show languageVoices;
import 'package:nitznutz/characters/character_source.dart';
import 'package:nitznutz/content/bundled_packs.dart';
import 'package:nitznutz/content/capabilities.dart';
import 'package:nitznutz/content/pack_installer.dart';
import 'package:nitznutz/content/pack_verify.dart';
import 'package:nitznutz/content/zip_store.dart';
import 'package:nitznutz/data/app_database.dart';
import 'package:nitznutz/voice/voice_bank.dart';

import '../tool/pack_builder_lib.dart';
import 'support/pack_fixtures.dart';
import 'support/voice_fixtures.dart';

const List<(int, int)> _cues = <(int, int)>[(0, 1), (100, 0)];

/// Every character of the family that is personal and must never be bundled.
const List<String> _personal = <String>[
  'hero-son',
  'friend-daughter',
  'alien-jili',
  'climber-tzuri',
  'compass-romi',
  'inventor-gali',
  'tower-tamir',
  'weaver-keshet',
];

void main() {
  group('the names of bundled voice files', () {
    test(
      'only Nitzi, part 1 without a number and parts 2 to 9, in the characters folder, with a plain version',
      () {
        final List<BundledVoicePack> found = BundledVoicePack.newestOf(<String>[
          'assets/characters/voice-nitzi-2.0.0.nnpack',
          'assets/characters/voice-nitzi-2-2.0.0.nnpack',
          'assets/characters/voice-nitzi-9-2.0.0.nnpack',
          'assets/characters/char-nitzi-1.0.0.nnpack',
          'assets/packs/starter-0.11.0.nnpack',
        ]);
        expect(found.map((BundledVoicePack v) => v.packId), <String>[
          'voice-nitzi',
          'voice-nitzi-2',
          'voice-nitzi-9',
        ]);
        expect(found.map((BundledVoicePack v) => v.part), <int>[1, 2, 9]);
        expect(found.every((BundledVoicePack v) => v.characterId == 'nitzi'), isTrue);
      },
    );

    test('every other name is left out: personal characters, parts 0, 1 and 10, another folder, a path, a version that is not plain', () {
      final List<String> others = <String>[
        for (final String id in _personal) 'assets/characters/voice-$id-2.0.0.nnpack',
        'assets/characters/voice-nitzi-1-2.0.0.nnpack',
        'assets/characters/voice-nitzi-0-2.0.0.nnpack',
        'assets/characters/voice-nitzi-10-2.0.0.nnpack',
        'assets/characters/voice-nitzi-22-2.0.0.nnpack',
        'assets/characters/voice-nitzi-x-2.0.0.nnpack',
        'assets/characters/voice-nitzi-2.0.nnpack',
        'assets/characters/voice-nitzi-2.0.0-beta.nnpack',
        'assets/characters/voice-nitzi-2.0.0.nnpack.bak',
        'assets/characters/voice-nitzi2-2.0.0.nnpack',
        'assets/characters/sub/voice-nitzi-2.0.0.nnpack',
        'assets/packs/voice-nitzi-2.0.0.nnpack',
        '../assets/characters/voice-nitzi-2.0.0.nnpack',
        'assets/characters/voice-nitzi-2.0.0.nnpack\n',
        'assets/characters/voice-lang-eng-1.0.0.nnpack',
        'assets/packs/voice-lang-fra-1.0.0.nnpack',
        'assets/packs/voice-lang-eng-2-1.0.0.nnpack',
        'assets/packs/voice-lang-eng-1.0.nnpack',
        'assets/packs/sub/voice-lang-eng-1.0.0.nnpack',
        'assets/characters/voice-lang-heb-1.0.0.nnpack',
      ];
      expect(BundledVoicePack.newestOf(others), isEmpty, reason: '$others');
      expect(bundledVoiceCharacters, <String>{'nitzi'});
    });

    test('the voice of a language course is a bundled voice pack of the character lang-<course>, from the packs folder', () {
      final List<BundledVoicePack> found = BundledVoicePack.newestOf(<String>[
        'assets/packs/voice-lang-rus-1.0.0.nnpack',
        'assets/packs/voice-lang-eng-1.0.0.nnpack',
        'assets/packs/voice-lang-eng-1.2.0.nnpack',
        'assets/packs/voice-lang-heb-1.0.0.nnpack',
        'assets/packs/lang-eng-0.1.0.nnpack',
      ]);
      expect(found.map((BundledVoicePack v) => '${v.packId} ${v.version}'), <String>[
        'voice-lang-eng 1.2.0',
        'voice-lang-heb 1.0.0',
        'voice-lang-rus 1.0.0',
      ]);
      expect(found.map((BundledVoicePack v) => v.characterId), <String>['lang-eng', 'lang-heb', 'lang-rus']);
      expect(found.every((BundledVoicePack v) => v.part == 1), isTrue);
    });

    test('the newest version of each pack wins, by the numbers and not the letters', () {
      final List<BundledVoicePack> found = BundledVoicePack.newestOf(<String>[
        'assets/characters/voice-nitzi-2.0.0.nnpack',
        'assets/characters/voice-nitzi-10.0.0.nnpack',
        'assets/characters/voice-nitzi-9.9.9.nnpack',
        'assets/characters/voice-nitzi-2-2.0.0.nnpack',
      ]);
      expect(found.map((BundledVoicePack v) => '${v.packId} ${v.version}'), <String>[
        'voice-nitzi 10.0.0',
        'voice-nitzi-2 2.0.0',
      ]);
    });
  });

  group('installing the bundled voice', () {
    late PackKey key;
    late Directory dir;
    late AppDatabase db;
    late PackInstaller installer;
    late Map<String, Uint8List> files;
    late List<String> reads;
    late int listed;

    setUpAll(() async => key = await newTestKey());

    setUp(() {
      dir = Directory.systemTemp.createTempSync('nn_bundled_voice_');
      db = AppDatabase(NativeDatabase.memory());
      installer = PackInstaller(
        root: Directory('${dir.path}${Platform.pathSeparator}packs'),
        registry: DbPackRegistry(db),
        publicKey: key.publicKey,
        capabilities: AppCapabilities.current,
      );
      files = <String, Uint8List>{};
      reads = <String>[];
      listed = 0;
    });

    tearDown(() async {
      await db.close();
      dir.deleteSync(recursive: true);
    });

    Future<void> bundle(
      String asset,
      String packOf,
      List<String> lines, {
      String version = '2.0.0',
      PackKey? signer,
    }) async {
      files[asset] = (await buildVoicePack(signer ?? key, packOf, <String, List<(int, int)>>{
        for (final String l in lines) l: _cues,
      }, version: version)).bytes;
    }

    InstalledCharacterSource source() => InstalledCharacterSource(
      installer: installer,
      bundledHouse: () async => Uint8List(0),
      bundledVoices: () async {
        listed++;
        return BundledVoicePack.newestOf(files.keys);
      },
      readAsset: (String asset) async {
        reads.add(asset);
        return files[asset]!;
      },
    );

    const String one = 'assets/characters/voice-nitzi-2.0.0.nnpack';
    const String two = 'assets/characters/voice-nitzi-2-2.0.0.nnpack';

    test('the parts are installed one at a time in order, through the installer, and the voice is read from them', () async {
      await bundle(one, 'nitzi', <String>['a.one', 'a.two']);
      await bundle(two, 'nitzi-2', <String>['b.one']);
      final VoiceBank bank = await source().voice('nitzi');
      expect(reads, <String>[one, two]);
      expect(bank.ids.toSet(), <String>{'vo:a.one', 'vo:a.two', 'vo:b.one'});
      expect((await db.installedPack('voice-nitzi'))!.version, '2.0.0');
      expect((await db.installedPack('voice-nitzi-2'))!.version, '2.0.0');
    });

    test('a phone that has the version, or a newer one, reads no asset at all', () async {
      await bundle(one, 'nitzi', <String>['a.one']);
      await bundle(two, 'nitzi-2', <String>['b.one']);
      await source().voice('nitzi');
      reads.clear();
      final InstalledCharacterSource again = source();
      expect((await again.voice('nitzi')).length, 2);
      await again.voice('nitzi');
      expect(reads, isEmpty, reason: 'the registry rows were read first');
      expect(listed, 2, reason: 'once for each source, not for each voice read');

      // A newer copy on the phone (an update) is kept; an older bundled file does not replace it.
      await installer.install(
        (await buildVoicePack(key, 'nitzi', <String, List<(int, int)>>{
          'a.new': _cues,
        }, version: '3.0.0')).bytes,
      );
      await bundle(one, 'nitzi', <String>['a.one']);
      reads.clear();
      // Part 2 is still the 2.0.0 one: parts of two builds are never joined, so the newer part 1 stands alone until its part 2
      // arrives (an update ships every part of a build together).
      expect((await source().voice('nitzi')).ids.toSet(), <String>{'vo:a.new'});
      expect(reads, isEmpty);
    });

    test('an older copy on the phone is replaced by the bundled one', () async {
      await installer.install(
        (await buildVoicePack(key, 'nitzi', <String, List<(int, int)>>{
          'old.one': _cues,
        }, version: '1.0.0')).bytes,
      );
      await bundle(one, 'nitzi', <String>['a.one']);
      expect((await source().voice('nitzi')).ids, <String>['vo:a.one']);
      expect(reads, <String>[one]);
    });

    test('an installed copy whose folder is gone is put back from the bundle', () async {
      await bundle(one, 'nitzi', <String>['a.one']);
      await source().voice('nitzi');
      Directory('${dir.path}/packs/voice-nitzi').deleteSync(recursive: true);
      reads.clear();
      expect((await source().voice('nitzi')).ids, <String>['vo:a.one']);
      expect(reads, <String>[one]);
    });

    test('a file the installer refuses (damaged, wrong key, not a pack, an older version) never stops the others or the app', () async {
      await bundle(one, 'nitzi', <String>['a.one']);
      files[two] = Uint8List.fromList(<int>[1, 2, 3, 4]);
      await bundle('assets/characters/voice-nitzi-3-2.0.0.nnpack', 'nitzi-3', <String>[
        'c.one',
      ], signer: await newTestKey());
      await bundle('assets/characters/voice-nitzi-4-2.0.0.nnpack', 'nitzi-4', <String>['d.one']);
      final VoiceBank bank = await source().voice('nitzi');
      expect(bank.ids.toSet(), <String>{'vo:a.one', 'vo:d.one'});
      // The manifest says what a pack is, not its name: a file named for part 5 that holds part 6 installs as part 6.
      await bundle('assets/characters/voice-nitzi-5-2.0.0.nnpack', 'nitzi-6', <String>['f.one']);
      expect((await source().voice('nitzi')).ids.toSet(), <String>{'vo:a.one', 'vo:d.one', 'vo:f.one'});
    });

    test(
      'a list that fails, and a source with no bundled voice, leave the voice as the installed packs say',
      () async {
        await installer.install(
          (await buildVoicePack(key, 'nitzi', <String, List<(int, int)>>{'a.one': _cues})).bytes,
        );
        final InstalledCharacterSource failing = InstalledCharacterSource(
          installer: installer,
          bundledHouse: () async => Uint8List(0),
          bundledVoices: () async => throw const FileSystemException('no manifest'),
          readAsset: (String asset) async => Uint8List(0),
        );
        expect((await failing.voice('nitzi')).ids, <String>['vo:a.one']);
        final InstalledCharacterSource none = InstalledCharacterSource(
          installer: installer,
          bundledHouse: () async => Uint8List(0),
        );
        expect((await none.voice('nitzi')).ids, <String>['vo:a.one']);
      },
    );

    test('the voices of the language courses are installed with Nitzi\'s and joined for the guide in the course order', () async {
      await bundle(one, 'nitzi', <String>['a.one']);
      await bundle('assets/packs/voice-lang-eng-1.0.0.nnpack', 'lang-eng', <String>[
        'eng.en_apple',
        'eng.he_bye',
      ], version: '1.0.0');
      await bundle('assets/packs/voice-lang-rus-1.0.0.nnpack', 'lang-rus', <String>[
        'rus.f01',
      ], version: '1.0.0');
      final InstalledCharacterSource src = source();
      expect((await src.voice('lang-eng')).ids.toSet(), <String>{'vo:eng.en_apple', 'vo:eng.he_bye'});
      expect((await src.voice('lang-heb')).length, 0, reason: 'a course with no voice adds nothing');
      final VoiceBank languages = await languageVoices(src);
      expect(languages.ids.toSet(), <String>{'vo:eng.en_apple', 'vo:eng.he_bye', 'vo:rus.f01'});
      expect(languages.has('vo:a.one'), isFalse, reason: 'Nitzi\'s own lines are not in it');
    });

    test(
      'a personal character\'s voice is never read from the bundle, whatever the files are called',
      () async {
        await bundle('assets/characters/voice-hero-son-2.0.0.nnpack', 'hero-son', <String>['h.one']);
        expect((await source().voice('hero-son')).length, 0);
        expect(reads, isEmpty);
      },
    );
  });

  group('the real files (checked when they are copied in, skipped when they are not)', () {
    final Directory characters = Directory('assets/characters');
    final Directory packs = Directory('assets/packs');
    final List<File> voices = <File>[
      for (final Directory d in <Directory>[characters, packs])
        for (final FileSystemEntity e in d.listSync())
          if (e is File && e.uri.pathSegments.last.startsWith('voice-') && e.path.endsWith('.nnpack')) e,
    ];
    final Uint8List publicKey = unhex(File('assets/pack_signing_public_key.txt').readAsStringSync());

    test('no asset of the app is named for a personal character', () {
      final List<String> named = <String>[
        for (final FileSystemEntity e in Directory('assets').listSync(recursive: true))
          if (e is File && _personal.any((String id) => e.uri.pathSegments.last.toLowerCase().contains(id)))
            e.path,
      ];
      expect(named, isEmpty, reason: 'personal characters are never bundled (CLAUDE.md): $named');
    });

    test('the .gitignore keeps the voice files out of the repository', () {
      final String ignore = File('../.gitignore').readAsStringSync();
      expect(ignore, contains('app/assets/characters/voice-*.nnpack'));
      expect(ignore, contains('app/assets/packs/voice-lang-*.nnpack'));
    });

    test('every bundled voice file is named for Nitzi or a language course, verifies with the real key, and says what its name says', () async {
      final RegExp nitzi = RegExp(r'^voice-nitzi(?:-([2-9]))?-(\d{1,3}\.\d{1,3}\.\d{1,3})\.nnpack$');
      final RegExp lang = RegExp(r'^voice-lang-(eng|heb|rus)-(\d{1,3}\.\d{1,3}\.\d{1,3})\.nnpack$');
      for (final File f in voices) {
        final String name = f.uri.pathSegments.last;
        final bool isNitzi = nitzi.hasMatch(name) && f.parent.uri.pathSegments.contains('characters');
        final bool isLang = lang.hasMatch(name) && f.parent.uri.pathSegments.contains('packs');
        expect(isNitzi || isLang, isTrue, reason: '$name is not a voice file the app reads');
        expect(f.lengthSync(), lessThanOrEqualTo(ZipLimits.maxZipBytes), reason: name);
        final VerifiedPack pack = await verifyPack(f.readAsBytesSync(), publicKey: publicKey);
        final RegExpMatch m = (isNitzi ? nitzi : lang).firstMatch(name)!;
        final String expectedId = isNitzi
            ? voicePackId('nitzi', m.group(1) == null ? 1 : int.parse(m.group(1)!))
            : 'voice-lang-${m.group(1)}';
        expect(pack.id, expectedId, reason: name);
        expect(pack.version, m.group(2), reason: name);
        expect(pack.hidden, isFalse, reason: name);
      }
    }, timeout: const Timeout(Duration(minutes: 5)));

    test('Nitzi\'s voice belongs to a bundled character, its parts share one version and no line, and it is under the voice limit', () async {
      final List<File> nitziParts = <File>[
        for (final File f in voices)
          if (f.uri.pathSegments.last.startsWith('voice-nitzi-')) f,
      ]..sort((File a, File b) => a.path.compareTo(b.path));
      if (nitziParts.isEmpty) {
        // No voice copied in: nothing to check, and the app plays Nitzi as text until it is.
        return;
      }
      final Character nitziCharacter = Character.fromPack(
        await verifyPack(
          File('assets/characters/char-nitzi-1.0.0.nnpack').readAsBytesSync(),
          publicKey: publicKey,
        ),
      );
      expect(nitziCharacter.id, 'nitzi');
      expect(
        nitziCharacter.personalUseOnly,
        isFalse,
        reason: 'only a bundled character may have its voice bundled',
      );
      VoiceBank joined = VoiceBank.empty('nitzi');
      final Set<String> versions = <String>{};
      for (final File f in nitziParts) {
        final VerifiedPack pack = await verifyPack(f.readAsBytesSync(), publicKey: publicKey);
        versions.add(pack.version);
        joined = joined.withPart(VoiceBank.fromPack(pack));
      }
      expect(versions, hasLength(1), reason: 'the parts of one voice are one build');
      expect(joined.length, greaterThan(0));
      expect(joined.clipBytes, lessThan(maxVoiceBytes), reason: 'a part over this is left out by the app');
      expect(
        nitziParts.fold<int>(0, (int s, File f) => s + f.lengthSync()),
        lessThan(maxVoiceBytes + 8 * 1024 * 1024),
      );
    }, timeout: const Timeout(Duration(minutes: 5)));
  });
}
