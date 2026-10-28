// The voice never cuts a sentence off (M8 phone test): a line waits for the one that is playing, only the newest line waits,
// a screen closing silences only what it said, and the child's own touch still replaces what is playing.
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/content/pack_verify.dart';
import 'package:nitznutz/voice/voice_bank.dart';
import 'package:nitznutz/voice/voice_director.dart';

import '../tool/pack_builder_lib.dart';
import 'support/pack_fixtures.dart';
import 'support/voice_fixtures.dart';

void main() {
  late VoiceBank bank;
  late FakePlayer player;
  late VoiceDirector director;

  setUpAll(() async {
    final PackKey key = await newTestKey();
    bank = VoiceBank.fromPack(
      await verifyPack(
        (await buildVoicePack(key, 'hero-son', <String, List<(int, int)>>{
          'a': <(int, int)>[(0, 1)],
          'b': <(int, int)>[(0, 1)],
          'c': <(int, int)>[(0, 1)],
        })).bytes,
        publicKey: key.publicKey,
      ),
    );
  });

  setUp(() {
    player = FakePlayer();
    director = VoiceDirector(player: player)..useBank(bank);
  });
  tearDown(() => director.dispose());

  List<String> heard() => player.played.map(utf8.decode).toList();

  test('a line that arrives while another plays waits for it, and the first is heard to its end', () async {
    final int stopsAtStart = player.stops;
    await director.sayNext('vo:a');
    await director.sayNext('vo:b');
    expect(heard(), <String>['mp3:hero-son:a'], reason: 'b waits');
    expect(
      player.stops,
      stopsAtStart + 1,
      reason: 'nothing stopped the first line (the one stop is its own clean start)',
    );
    player.finish();
    await Future<void>.delayed(Duration.zero);
    expect(heard(), <String>['mp3:hero-son:a', 'mp3:hero-son:b']);
    expect(director.current, 'vo:b');
  });

  test(
    'at most two lines wait (the congratulation and the next question): older ones are about the past',
    () async {
      await director.sayNext('vo:a');
      await director.sayNext('vo:b');
      await director.sayNext('vo:c');
      await director.sayNext('vo:a');
      player.finish();
      await Future<void>.delayed(Duration.zero);
      expect(heard(), <String>['mp3:hero-son:a', 'mp3:hero-son:c'], reason: 'b was dropped, c is next');
      player.finish();
      await Future<void>.delayed(Duration.zero);
      expect(heard(), <String>['mp3:hero-son:a', 'mp3:hero-son:c', 'mp3:hero-son:a']);
    },
  );

  test('a waiting line that is no longer relevant is dropped, not played late', () async {
    bool moved = false;
    await director.sayNext('vo:a');
    await director.sayNext('vo:b', relevant: () => !moved);
    moved = true; // the child answered again while the first line played
    player.finish();
    await Future<void>.delayed(Duration.zero);
    expect(heard(), <String>['mp3:hero-son:a']);
    expect(director.speaking, isFalse);
  });

  test('a playing line that no longer matters gives way to the new one at once', () async {
    bool moved = false;
    await director.sayNext('vo:a', relevant: () => !moved);
    await director.sayNext('vo:b'); // still waits: a matters
    expect(heard(), <String>['mp3:hero-son:a']);
    moved = true;
    await director.sayNext('vo:c');
    expect(heard(), <String>[
      'mp3:hero-son:a',
      'mp3:hero-son:b',
    ], reason: 'a gave way; the oldest relevant line goes first');
    player.finish();
    await Future<void>.delayed(Duration.zero);
    expect(heard().last, 'mp3:hero-son:c');
  });

  test('a line that has waited too long is dropped', () async {
    DateTime clock = DateTime(2026, 10, 28, 12);
    director.dispose();
    player = FakePlayer();
    director = VoiceDirector(player: player, maxWait: const Duration(seconds: 6), now: () => clock)
      ..useBank(bank);
    await director.sayNext('vo:a');
    await director.sayNext('vo:b');
    clock = clock.add(const Duration(seconds: 7));
    player.finish();
    await Future<void>.delayed(Duration.zero);
    expect(heard(), <String>['mp3:hero-son:a']);
  });

  test('the child\'s own touch replaces what is playing, as before', () async {
    await director.sayNext('vo:a');
    await director.say('vo:b');
    expect(heard(), <String>['mp3:hero-son:a', 'mp3:hero-son:b']);
  });

  test('a line with no recording never cuts a playing line and does not wait', () async {
    await director.sayNext('vo:a');
    await director.sayNext('vo:missing');
    await director.sayNext(null);
    player.finish();
    await Future<void>.delayed(Duration.zero);
    expect(heard(), <String>['mp3:hero-son:a']);
    expect(director.speaking, isFalse);
  });

  test('a short pause is kept between the line and the one that was waiting', () async {
    director.dispose();
    player = FakePlayer();
    director = VoiceDirector(player: player, gap: const Duration(milliseconds: 60))..useBank(bank);
    await director.sayNext('vo:a');
    await director.sayNext('vo:b');
    player.finish();
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(heard(), <String>['mp3:hero-son:a'], reason: 'still in the pause');
    await Future<void>.delayed(const Duration(milliseconds: 80));
    expect(heard(), <String>['mp3:hero-son:a', 'mp3:hero-son:b']);
  });

  test('a screen that closes silences only its own lines, never one the next screen started', () async {
    final Object lesson = Object();
    final Object ceremony = Object();
    await director.sayNext('vo:a', owner: lesson);
    await director.sayNext('vo:b', owner: ceremony); // waits for the lesson's line
    await director.stopFor(lesson);
    expect(director.speaking, isFalse, reason: 'the lesson\'s own line is silenced');
    // the ceremony's line was waiting for it and was kept: it plays when the lesson's line is gone
    expect(heard(), <String>['mp3:hero-son:a']);
    await director.say('vo:b', owner: ceremony);
    await director.stopFor(lesson);
    expect(director.speaking, isTrue, reason: 'closing the lesson does not touch the ceremony\'s line');
    await director.stop();
  });

  test('stop() silences everything and forgets any waiting line', () async {
    await director.sayNext('vo:a');
    await director.sayNext('vo:b');
    await director.stop();
    player.finish();
    await Future<void>.delayed(Duration.zero);
    expect(heard(), <String>['mp3:hero-son:a']);
  });
}
