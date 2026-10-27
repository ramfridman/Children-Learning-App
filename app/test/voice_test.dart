import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/characters/lip_sync.dart';
import 'package:nitznutz/content/pack_verify.dart';
import 'package:nitznutz/voice/voice_bank.dart';
import 'package:nitznutz/voice/voice_director.dart';

import '../tool/pack_builder_lib.dart';
import 'support/pack_fixtures.dart';
import 'support/voice_fixtures.dart';

/// Lets the director's poll timer fire and its (asynchronous) reading of the position finish.
Future<void> tick(WidgetTester tester, [int ms = 40]) async {
  await tester.pump(Duration(milliseconds: ms));
  await tester.pump();
  await tester.pump();
}

void main() {
  group('the mouth track', () {
    final MouthTrack track = MouthTrack(<(int, bool)>[(0, false), (100, true), (250, false), (400, true)]);

    test('is closed before the first cue and follows the cues after it', () {
      expect(track.openAt(0), isFalse);
      expect(track.openAt(99), isFalse);
      expect(track.openAt(100), isTrue);
      expect(track.openAt(249), isTrue);
      expect(track.openAt(250), isFalse);
      expect(track.openAt(399), isFalse);
      expect(track.openAt(400), isTrue);
      expect(track.openAt(60000), isTrue);
      expect(MouthTrack(<(int, bool)>[(50, true)]).openAt(10), isFalse);
      expect(MouthTrack(<(int, bool)>[]).openAt(10), isFalse);
    });

    test('is made from the cue document of a pack', () {
      final MouthTrack t = MouthTrack.fromJson(<Object?>[
        <String, Object?>{'t': 0, 'o': 0},
        <String, Object?>{'t': 120, 'o': 1},
      ]);
      expect(t.length, 2);
      expect(t.lastMs, 120);
      expect(t.openAt(130), isTrue);
    });
  });

  group('the flap never flickers', () {
    test('it changes at most once in 70 ms however fast the cues switch', () {
      final MouthFlap flap = MouthFlap();
      int changes = 0;
      bool last = false;
      for (int ms = 0; ms < 2000; ms += 5) {
        final bool now = flap.update(ms, (ms ~/ 5).isEven); // the cues want a change every 5 ms
        if (now != last) changes++;
        last = now;
      }
      expect(changes, lessThanOrEqualTo(2000 ~/ 70 + 1));
      expect(changes, greaterThan(15));
    });

    test('it follows slow cues faithfully', () {
      final MouthFlap flap = MouthFlap();
      expect(flap.update(0, true), isTrue);
      expect(flap.update(80, true), isTrue);
      expect(flap.update(40, false), isTrue, reason: 'it opened at 0 and is held for 70 ms');
      expect(flap.update(100, false), isFalse);
    });
  });

  group('a voice bank', () {
    late PackKey key;
    setUpAll(() async => key = await newTestKey());

    test('is made from a signed voice pack: the sound and the cues of each line', () async {
      final BuiltPack built = await buildVoicePack(key, 'hero-son', <String, List<(int, int)>>{
        'pick.red.flower.prompt': <(int, int)>[(0, 0), (150, 1), (300, 0)],
        'fb.almost': <(int, int)>[(0, 1)],
      });
      final VerifiedPack pack = await verifyPack(built.bytes, publicKey: key.publicKey);
      final VoiceBank bank = VoiceBank.fromPack(pack);
      expect(bank.characterId, 'hero-son');
      expect(bank.length, 2);
      expect(bank.has('vo:fb.almost'), isTrue);
      expect(bank.has('vo:fb.nothing'), isFalse);
      expect(utf8.decode(bank.clip('vo:pick.red.flower.prompt')!.mp3), 'mp3:hero-son:pick.red.flower.prompt');
      expect(bank.clip('vo:pick.red.flower.prompt')!.mouth.openAt(200), isTrue);
    });

    test('a changed byte in a voice pack is refused like any pack', () async {
      final BuiltPack built = await buildVoicePack(key, 'hero-son', <String, List<(int, int)>>{
        'fb.almost': <(int, int)>[(0, 1)],
      });
      for (int i = 0; i < built.bytes.length; i += 17) {
        final Uint8List bad = Uint8List.fromList(built.bytes)..[i] ^= 1;
        await expectLater(
          verifyPack(bad, publicKey: key.publicKey),
          throwsA(isA<PackRejected>()),
          reason: 'byte $i',
        );
      }
    });

    test('a recorded line without its cue file is refused', () async {
      final BuiltPack built = await buildVoicePack(key, 'hero-son', <String, List<(int, int)>>{
        'fb.almost': <(int, int)>[(0, 1)],
      });
      final Map<String, Uint8List> parts = unzip(built.bytes);
      final Uint8List bad = await forge(
        key,
        built.bytes,
        files: (Map<String, Uint8List> f) => f.remove('cue.fb.almost.json'),
        manifest: (Map<String, Object?> m) => (m['entries']! as Map<String, Object?>).remove('cues'),
      );
      expect(parts.keys, contains('cue.fb.almost.json'));
      await expectLater(
        verifyPack(bad, publicKey: key.publicKey),
        throwsA(
          isA<PackRejected>().having(
            (PackRejected e) => e.problems.join(),
            'problems',
            contains('has no mouth-cue file'),
          ),
        ),
      );
    });

    test('cue times that do not increase are refused', () async {
      final BuiltPack built = await buildVoicePack(key, 'hero-son', <String, List<(int, int)>>{
        'fb.almost': <(int, int)>[(0, 0), (100, 1)],
      });
      final Uint8List bad = await forge(
        key,
        built.bytes,
        files: (Map<String, Uint8List> f) => f['cue.fb.almost.json'] = Uint8List.fromList(
          utf8.encode('{"schema":"cue/v1","id":"fb.almost","cues":[{"t":100,"o":1},{"t":100,"o":0}]}'),
        ),
      );
      await expectLater(
        verifyPack(bad, publicKey: key.publicKey),
        throwsA(
          isA<PackRejected>().having(
            (PackRejected e) => e.problems.join(),
            'problems',
            contains('times must increase'),
          ),
        ),
      );
    });
  });

  group('the voice director', () {
    late PackKey key;
    late VoiceBank hero;
    late VoiceBank nitzi;
    late FakePlayer player;
    late VoiceDirector director;

    setUpAll(() async {
      key = await newTestKey();
      Future<VoiceBank> bank(String id) async => VoiceBank.fromPack(
        await verifyPack(
          (await buildVoicePack(key, id, <String, List<(int, int)>>{
            'a': <(int, int)>[(0, 0), (100, 1), (200, 0), (300, 1)],
            'b': <(int, int)>[(0, 1)],
            'plain': <(int, int)>[],
          })).bytes,
          publicKey: key.publicKey,
        ),
      );
      hero = await bank('hero-son');
      nitzi = await bank('nitzi');
    });

    setUp(() {
      player = FakePlayer();
      director = VoiceDirector(player: player);
    });
    tearDown(() => director.dispose());

    testWidgets('plays the line of the active voice and moves the mouth with the sound', (
      WidgetTester tester,
    ) async {
      director.useBank(hero);
      await director.say('vo:a');
      expect(director.speaking, isTrue);
      expect(utf8.decode(player.played.single), 'mp3:hero-son:a');
      final Map<int, bool> mouth = <int, bool>{};
      for (int ms = 0; ms <= 400; ms += 20) {
        player.at = Duration(milliseconds: ms);
        await tick(tester, 20);
        mouth[ms] = director.mouthOpen;
      }
      // Closed at the start, open while the cue says so (the flap holds a change for 70 ms), shut again, open again.
      expect(mouth[0], isFalse);
      expect(<bool>[for (int ms = 120; ms <= 200; ms += 20) mouth[ms]!], contains(true));
      expect(mouth[160], isTrue);
      expect(mouth[280], isFalse);
      expect(mouth[400], isTrue);
      player.finish();
      await tester.pump();
      expect(director.speaking, isFalse);
      expect(director.mouthOpen, isFalse);
    });

    testWidgets('the voice follows the companion: the other bank, the other sound', (
      WidgetTester tester,
    ) async {
      director.useBank(hero);
      await director.say('vo:b');
      director.useBank(nitzi);
      expect(director.speaking, isFalse, reason: 'a change of voice stops what was playing');
      await director.say('vo:b');
      expect(player.played.map(utf8.decode), <String>['mp3:hero-son:b', 'mp3:nitzi:b']);
      await director.stop();
      await tester.pump();
    });

    testWidgets('never two lines at once: a new line stops the old one first', (WidgetTester tester) async {
      director.useBank(hero);
      await director.say('vo:a');
      final int stopsBefore = player.stops;
      await director.say('vo:b');
      expect(player.stops, greaterThan(stopsBefore));
      expect(player.plays, 2);
      expect(director.current, 'vo:b');
      await director.stop();
      await tester.pump();
    });

    testWidgets('a line with no recording, no id, or no bank is silent and breaks nothing', (
      WidgetTester tester,
    ) async {
      director.useBank(hero);
      await director.say('vo:missing');
      expect(director.speaking, isFalse);
      await director.say(null);
      expect(director.speaking, isFalse);
      director.useBank(null);
      await director.say('vo:a');
      expect(director.speaking, isFalse);
      expect(player.plays, 0);
    });

    testWidgets('stop() silences it, and leaving the screen can stop it', (WidgetTester tester) async {
      director.useBank(hero);
      await director.say('vo:a');
      await director.stop();
      expect(director.speaking, isFalse);
      expect(director.mouthOpen, isFalse);
      player.at = const Duration(milliseconds: 150);
      await tick(tester, 100);
      expect(director.mouthOpen, isFalse, reason: 'the mouth is not driven after the stop');
      await director.stop();
      await tester.pump();
    });

    testWidgets('a line without cues still moves the mouth while it plays', (WidgetTester tester) async {
      director.useBank(hero);
      await director.say('vo:plain');
      final Set<bool> seen = <bool>{};
      for (int ms = 0; ms < 1000; ms += 40) {
        player.at = Duration(milliseconds: ms);
        await tick(tester);
        seen.add(director.mouthOpen);
      }
      expect(seen, <bool>{true, false});
      await director.stop();
      await tester.pump();
    });

    testWidgets('a sound device that fails is a silent line, not a broken screen', (
      WidgetTester tester,
    ) async {
      director.useBank(hero);
      player.failToPlay = true;
      await director.say('vo:a');
      expect(director.speaking, isFalse);
    });

    testWidgets('the same line said again plays again (replay)', (WidgetTester tester) async {
      director.useBank(hero);
      await director.say('vo:b');
      player.finish();
      await tester.pump();
      await director.say('vo:b');
      expect(player.plays, 2);
      await director.stop();
      await tester.pump();
    });
  });
}
