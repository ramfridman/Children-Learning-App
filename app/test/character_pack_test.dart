import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/characters/character.dart';
import 'package:nitznutz/characters/resolver.dart';
import 'package:nitznutz/content/capabilities.dart';
import 'package:nitznutz/content/pack_verify.dart';

import '../tool/pack_builder_lib.dart';
import 'support/character_fixtures.dart';
import 'support/pack_fixtures.dart';

Matcher _fails(String part) =>
    throwsA(isA<BuildFailed>().having((BuildFailed e) => e.toString(), 'message', contains(part)));

Uint8List _publicKey() => unhex(File('assets/pack_signing_public_key.txt').readAsStringSync());

void main() {
  late Directory tmp;
  late PackKey key;

  setUpAll(() async => key = await newTestKey());
  setUp(() => tmp = Directory.systemTemp.createTempSync('nn_chars_'));
  tearDown(() {
    try {
      tmp.deleteSync(recursive: true);
    } on FileSystemException {
      // Windows may hold a file for a moment.
    }
  });

  group('building a character pack', () {
    test('a family folder becomes a signed personal pack that loads as a character', () async {
      final Directory dir = writeCharacterFolder(tmp, 'hero-son');
      final BuiltPack built = await buildCharacterPack(dir, key);
      expect(built.fileName, 'char-hero-son-1.0.0.nnpack');
      final VerifiedPack pack = await verifyPack(built.bytes, publicKey: key.publicKey);
      expect(pack.id, 'char-hero-son');
      final Character c = Character.fromPack(pack);
      expect(c.id, 'hero-son');
      expect(c.personalUseOnly, isTrue);
      expect(c.gender, 'm');
      expect(c.roles, containsAll(<CharacterRole>[CharacterRole.guideTutor, CharacterRole.sticker]));
      expect(c.mouth.dx, closeTo(0.45, 1e-9));
      expect(c.canvas.width, 64);
      expect(c.images.keys, containsAll(poseFiles));
      expect(c.displayName('נועה'), 'נועה הַמְּזַנֵּק');
    });

    test(
      'all eight family characters of design/family-pack build, verify and load (real pictures)',
      () async {
        final List<Directory> folders =
            Directory('../design/family-pack').listSync().whereType<Directory>().toList()
              ..sort((Directory a, Directory b) => a.path.compareTo(b.path));
        expect(folders, hasLength(8));
        for (final Directory d in folders) {
          final BuiltPack built = await buildCharacterPack(d, key);
          final Character c = Character.fromPack(await verifyPack(built.bytes, publicKey: key.publicKey));
          expect(c.personalUseOnly, isTrue, reason: d.path);
          expect(c.canvas.width, 1024, reason: d.path);
          expect(c.images.length, greaterThanOrEqualTo(7), reason: d.path);
          expect(c.nameHe, isNotEmpty, reason: d.path);
          expect(built.bytes.length, lessThan(8 * 1024 * 1024));
        }
      },
    );

    test('the bundled Nitzi pack is genuine, not personal, and plays every role', () async {
      final VerifiedPack pack = await verifyPack(
        File('assets/characters/char-nitzi-1.0.0.nnpack').readAsBytesSync(),
        publicKey: _publicKey(),
      );
      final Character nitzi = Character.fromPack(pack);
      expect(nitzi.id, 'nitzi');
      expect(nitzi.personalUseOnly, isFalse);
      expect(nitzi.roles, CharacterRole.values.toSet());
      expect(nitzi.images.keys, containsAll(<String>[...poseFiles, 'surprised', 'sleepy', 'wave']));
      expect(
        nitzi.imageFor(CharacterState.talk, mouthOpen: true),
        isNot(same(nitzi.imageFor(CharacterState.talk))),
      );
      expect(nitzi.nameHe, 'נִיצִי');
    });

    test('the same folder and key give the same bytes', () async {
      final Directory dir = writeCharacterFolder(tmp, 'hero-son');
      expect((await buildCharacterPack(dir, key)).bytes, (await buildCharacterPack(dir, key)).bytes);
    });
  });

  group('what the builder refuses', () {
    test('a picture of the wrong size', () async {
      final Directory dir = writeCharacterFolder(tmp, 'hero-son');
      File('${dir.path}/idle.png').writeAsBytesSync(makePng(32, 32));
      await expectLater(buildCharacterPack(dir, key), _fails('idle.png is 32×32, the canvas is 64×64'));
    });

    test('a file that is not a PNG', () async {
      final Directory dir = writeCharacterFolder(tmp, 'hero-son');
      File('${dir.path}/idle.png').writeAsBytesSync(Uint8List.fromList(<int>[1, 2, 3, 4]));
      await expectLater(buildCharacterPack(dir, key), _fails('is not a PNG'));
    });

    test('a missing picture', () async {
      final Directory dir = writeCharacterFolder(tmp, 'hero-son');
      File('${dir.path}/think.png').deleteSync();
      await expectLater(buildCharacterPack(dir, key), _fails('think.png'));
    });

    test('a missing required state in the manifest', () async {
      final Directory dir = writeCharacterFolder(tmp, 'hero-son');
      final File f = File('${dir.path}/pack.json');
      f.writeAsStringSync(f.readAsStringSync().replaceAll('"think":"think.png",', ''));
      await expectLater(buildCharacterPack(dir, key), _fails('missing "think"'));
    });

    test('a name without niqqud', () async {
      final Directory dir = writeCharacterFolder(tmp, 'hero-son', nameHe: '{name} המזנק');
      await expectLater(buildCharacterPack(dir, key), _fails('has no niqqud'));
    });

    test('a name with Latin letters', () async {
      final Directory dir = writeCharacterFolder(tmp, 'hero-son', nameHe: 'Robo');
      await expectLater(buildCharacterPack(dir, key), _fails('Latin'));
    });

    test('a mouth outside the picture', () async {
      final Directory dir = writeCharacterFolder(
        tmp,
        'hero-son',
        extra: <String, Object?>{
          'mouth': <double>[1.4, 0.5],
        },
      );
      await expectLater(buildCharacterPack(dir, key), _fails('mouth[0]'));
    });

    test('an unknown role', () async {
      final Directory dir = writeCharacterFolder(tmp, 'hero-son', roles: <String>['guide_tutor', 'dictator']);
      await expectLater(buildCharacterPack(dir, key), _fails('roles[1]'));
    });

    test('a bad character id', () async {
      final Directory dir = writeCharacterFolder(tmp, 'Hero Son');
      await expectLater(buildCharacterPack(dir, key), _fails('id'));
    });

    test('a folder with no pack.json, and a pack.json of another kind', () async {
      final Directory empty = Directory('${tmp.path}/empty')..createSync();
      await expectLater(buildCharacterPack(empty, key), _fails('no pack.json'));
      File('${empty.path}/pack.json').writeAsStringSync('{"schema":"something-else"}');
      await expectLater(buildCharacterPack(empty, key), _fails('not a character-lite/v1'));
    });

    test('an SVG that can run or fetch anything', () async {
      for (final String bad in <String>[
        '<script>x</script>',
        '<image href="http://x/y.png"/>',
        '<use href="#a"/>',
        '<style>a{}</style>',
      ]) {
        final Directory dir = Directory('${tmp.path}/s${bad.hashCode}')..createSync();
        for (final String p in poseFiles) {
          File('${dir.path}/$p.svg').writeAsStringSync('<svg xmlns="x" viewBox="0 0 64 64">$bad</svg>');
        }
        File('${dir.path}/pack.json').writeAsStringSync(
          '{"schema":"character-lite/v1","id":"svg-char","name":{"he":"נִיצִי","grammaticalGender":"feminine"},'
          '"roles":["guide_tutor"],"images":{${poseFiles.map((String p) => '"$p":"$p.svg"').join(',')}},'
          '"canvas":{"size":[64,64]},"mouth":[0.5,0.5],"palette":{"dominant":"#112233"},'
          '"availability":{"distribution":"bundled","personalUseOnly":false}}',
        );
        await expectLater(buildCharacterPack(dir, key), _fails('contains'), reason: bad);
      }
    });

    test('an SVG whose viewBox is not the canvas', () async {
      final Directory dir = Directory('${tmp.path}/vb')..createSync();
      for (final String p in poseFiles) {
        File('${dir.path}/$p.svg').writeAsStringSync('<svg xmlns="x" viewBox="0 0 100 100"></svg>');
      }
      File('${dir.path}/pack.json').writeAsStringSync(
        '{"schema":"character-lite/v1","id":"svg-char","name":{"he":"נִיצִי","grammaticalGender":"feminine"},'
        '"roles":["guide_tutor"],"images":{${poseFiles.map((String p) => '"$p":"$p.svg"').join(',')}},'
        '"canvas":{"size":[64,64]},"mouth":[0.5,0.5],"palette":{"dominant":"#112233"},'
        '"availability":{"distribution":"bundled","personalUseOnly":false}}',
      );
      await expectLater(buildCharacterPack(dir, key), _fails('viewBox'));
    });

    test('an SVG whose viewBox is not a number is a problem, not a crash', () async {
      final Directory dir = Directory('${tmp.path}/vb-dot')..createSync();
      for (final String p in poseFiles) {
        File('${dir.path}/$p.svg').writeAsStringSync('<svg xmlns="x" viewBox="0 0 . 64"></svg>');
      }
      File('${dir.path}/pack.json').writeAsStringSync(
        '{"schema":"character-lite/v1","id":"svg-char","name":{"he":"נִיצִי","grammaticalGender":"feminine"},'
        '"roles":["guide_tutor"],"images":{${poseFiles.map((String p) => '"$p":"$p.svg"').join(',')}},'
        '"canvas":{"size":[64,64]},"mouth":[0.5,0.5],"palette":{"dominant":"#112233"},'
        '"availability":{"distribution":"bundled","personalUseOnly":false}}',
      );
      await expectLater(buildCharacterPack(dir, key), _fails('viewBox'));
    });
  });

  group('a character pack is untrusted content like any other', () {
    test(
      'a changed byte anywhere is refused (every 53rd byte; the zip tests cover every byte of a zip)',
      () async {
        final BuiltPack built = await buildCharacterPack(writeCharacterFolder(tmp, 'hero-son'), key);
        int tried = 0;
        for (int i = 0; i < built.bytes.length; i += 53) {
          final Uint8List bad = Uint8List.fromList(built.bytes)..[i] ^= 1;
          await expectLater(
            verifyPack(bad, publicKey: key.publicKey),
            throwsA(isA<PackRejected>()),
            reason: 'byte $i',
          );
          tried++;
        }
        expect(tried, greaterThan(20));
      },
    );

    test('another key is refused', () async {
      final BuiltPack built = await buildCharacterPack(writeCharacterFolder(tmp, 'hero-son'), key);
      await expectLater(verifyPack(built.bytes, publicKey: _publicKey()), throwsA(isA<PackRejected>()));
    });

    test('an older app keeps a character pack hidden (it needs 0.3.0)', () async {
      final BuiltPack built = await buildCharacterPack(writeCharacterFolder(tmp, 'hero-son'), key);
      final VerifiedPack v = await verifyPack(
        built.bytes,
        publicKey: key.publicKey,
        capabilities: const AppCapabilitiesForTest(),
      );
      expect(v.hidden, isTrue);
      expect(v.hiddenReason, contains('0.3.0'));
    });
  });

  group('no personal character can be bundled in a build', () {
    test(
      'every pack under assets/ is checked: none is personalUseOnly, and none is a family character',
      () async {
        final List<File> packs = <File>[
          for (final String d in <String>['assets/packs', 'assets/characters'])
            if (Directory(d).existsSync())
              ...Directory(d).listSync().whereType<File>().where((File f) => f.path.endsWith('.nnpack')),
        ];
        expect(packs, isNotEmpty);
        for (final File f in packs) {
          final VerifiedPack p = await verifyPack(f.readAsBytesSync(), publicKey: _publicKey());
          for (final MapEntry<String, Object?> d in p.docs.entries) {
            if (!d.key.startsWith('character.')) continue;
            expect((d.value! as Map<String, Object?>)['personalUseOnly'], isFalse, reason: f.path);
            expect((d.value! as Map<String, Object?>)['distribution'], 'bundled', reason: f.path);
          }
        }
      },
    );

    test(
      'pubspec.yaml lists only the folders of bundled content, never the family pack or a personal character',
      () {
        final String pubspec = File('pubspec.yaml').readAsStringSync();
        expect(pubspec, isNot(contains('family-pack')));
        expect(pubspec, isNot(contains('design/')));
        expect(pubspec, contains('assets/characters/'));
        for (final RegExpMatch m in RegExp(r'^\s+- (assets/[^\s]+)$', multiLine: true).allMatches(pubspec)) {
          final String path = m.group(1)!;
          if (path.endsWith('/')) {
            for (final File f in Directory(path).listSync(recursive: true).whereType<File>()) {
              expect(f.path.toLowerCase(), isNot(contains('hero-son')), reason: f.path);
              expect(f.path.toLowerCase(), isNot(contains('friend-daughter')), reason: f.path);
            }
          }
        }
      },
    );
  });

  group('the resolver fills roles', () {
    late Character nitzi;
    late Character hero;
    late Character mute;

    setUp(() async {
      Future<Character> make(
        String id, {
        List<String> roles = const <String>[
          'guide_tutor',
          'map_companion',
          'celebration_cameo',
          'activity_helper',
          'sticker',
        ],
      }) async => characterFrom(
        await buildCharacterPack(writeCharacterFolder(tmp, id, roles: roles, personal: false), key),
        key,
      );
      nitzi = await make('nitzi');
      hero = await make('hero-son');
      mute = await make('only-sticker', roles: <String>['sticker']);
    });

    test('the child\'s companion first, if it may play the role', () {
      final CharacterResolver r = CharacterResolver(available: <Character>[nitzi, hero, mute], house: nitzi);
      expect(r.resolve(CharacterRole.guideTutor, companionId: 'hero-son').id, 'hero-son');
      expect(r.resolve(CharacterRole.sticker, companionId: 'only-sticker').id, 'only-sticker');
      expect(
        r.resolve(CharacterRole.guideTutor, companionId: 'only-sticker').id,
        'nitzi',
        reason: 'it may not guide',
      );
    });

    test('then the domain friend, then the activity default, then the house character', () {
      final CharacterResolver r = CharacterResolver(available: <Character>[nitzi, hero, mute], house: nitzi);
      expect(r.resolve(CharacterRole.activityHelper, domainFriendId: 'hero-son').id, 'hero-son');
      expect(r.resolve(CharacterRole.activityHelper, activityDefaultId: 'hero-son').id, 'hero-son');
      expect(
        r.resolve(CharacterRole.activityHelper, companionId: 'nitzi', domainFriendId: 'hero-son').id,
        'nitzi',
      );
      expect(r.resolve(CharacterRole.activityHelper).id, 'nitzi');
    });

    test('a companion whose pack was removed quietly gives way to the house character', () {
      final CharacterResolver gone = CharacterResolver(available: <Character>[nitzi], house: nitzi);
      for (final CharacterRole role in CharacterRole.values) {
        expect(gone.resolve(role, companionId: 'hero-son').id, 'nitzi');
      }
    });

    test('only characters that can guide are offered as a companion, the house character first', () {
      final CharacterResolver r = CharacterResolver(available: <Character>[hero, nitzi, mute], house: nitzi);
      expect(r.companions().map((Character c) => c.id), <String>['nitzi', 'hero-son']);
    });

    test('a state without its own picture borrows a close one', () {
      expect(hero.imageFor(CharacterState.surprised), same(hero.imageFor(CharacterState.celebrate)));
      expect(hero.imageFor(CharacterState.sleepy), same(hero.imageFor(CharacterState.idle)));
      expect(hero.imageFor(CharacterState.wave), same(hero.imageFor(CharacterState.celebrate)));
    });
  });
}

/// An app that is older than the character packs.
class AppCapabilitiesForTest extends AppCapabilities {
  const AppCapabilitiesForTest() : super(appVersion: '0.2.0', templates: const <String, String>{});
}
