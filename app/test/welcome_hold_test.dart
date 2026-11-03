// B-42 part (c): the daily welcome in time. One sentence at a time in the bubble, said in the friend's voice with the name
// clip first, the pill glowing for the closing line, any touch stopping it, and the text-only fallbacks.
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/app/welcome_hold.dart';
import 'package:nitznutz/child/welcome_shown.dart';
import 'package:nitznutz/content/pack_verify.dart';
import 'package:nitznutz/voice/voice_bank.dart';
import 'package:nitznutz/voice/voice_director.dart';

import '../tool/pack_builder_lib.dart';
import 'support/pack_fixtures.dart';
import 'support/voice_fixtures.dart';

const List<String> _ids = <String>['welcome.hello.1', 'welcome.topic.counting.glance', 'welcome.close'];

final Uint8List _name = Uint8List.fromList(utf8.encode('name-clip'));

List<WelcomeStep> _steps({bool withName = true}) => <WelcomeStep>[
  WelcomeStep(text: 'one', withName: withName, voice: 'vo:${_ids[0]}', nameClip: _name),
  const WelcomeStep(text: 'two', withName: false, voice: 'vo:welcome.topic.counting.glance'),
  const WelcomeStep(text: 'three', withName: false, voice: 'vo:welcome.close', pointsAtBottle: true),
];

void main() {
  late VoiceBank bank;

  setUpAll(() async {
    final PackKey key = await newTestKey();
    bank = VoiceBank.fromPack(
      await verifyPack(
        (await buildVoicePack(key, 'hero-son', <String, List<(int, int)>>{
          for (final String id in _ids) id: <(int, int)>[(0, 1)],
        })).bytes,
        publicKey: key.publicKey,
      ),
    );
  });

  /// A hold over a director with the bank and a player whose clips last [clip].
  ({WelcomeHold hold, FakePlayer player, VoiceDirector director, List<String> seen, List<bool> glows}) setUp(
    Duration clip,
  ) {
    final FakePlayer player = FakePlayer()..endsAfter = clip;
    final VoiceDirector director = VoiceDirector(player: player)..useBank(bank);
    addTearDown(director.dispose);
    final WelcomeHold hold = WelcomeHold(director, gap: const Duration(milliseconds: 300));
    final List<String> seen = <String>[];
    final List<bool> glows = <bool>[];
    hold.shown.addListener(() => seen.add(hold.shown.value?.text ?? '-'));
    hold.glow.addListener(() => glows.add(hold.glow.value));
    addTearDown(hold.dispose);
    return (hold: hold, player: player, director: director, seen: seen, glows: glows);
  }

  testWidgets(
    'with recordings: the name clip, then the sentence, each in turn, then the bubble is its own again',
    (WidgetTester tester) async {
      final t = setUp(const Duration(milliseconds: 800));
      unawaited(t.hold.run(_steps(), voiced: true));
      await tester.pump();
      expect(t.hold.shown.value, const WelcomeShown(text: 'one', withName: true));
      expect(t.player.played, <Uint8List>[_name], reason: 'the name first');
      await tester.pump(const Duration(milliseconds: 850));
      expect(t.player.played.length, 2, reason: 'the greeting follows the name');
      expect(utf8.decode(t.player.played[1]), 'mp3:hero-son:welcome.hello.1');
      expect(t.hold.shown.value?.text, 'one');
      await tester.pump(const Duration(milliseconds: 800));
      expect(t.hold.shown.value?.text, 'one', reason: 'it stays through the pause');
      await tester.pump(const Duration(milliseconds: 400));
      expect(t.hold.shown.value?.text, 'two');
      expect(utf8.decode(t.player.played.last), 'mp3:hero-son:welcome.topic.counting.glance');
      expect(t.hold.glow.value, isFalse);
      await tester.pump(const Duration(milliseconds: 1200));
      expect(t.hold.shown.value?.text, 'three');
      expect(t.hold.glow.value, isTrue, reason: 'the pill glows for the sentence that points at the bottle');
      await tester.pump(const Duration(milliseconds: 900));
      expect(t.hold.shown.value, isNull, reason: 'back to the bubble\'s own words');
      expect(t.hold.glow.value, isFalse);
      expect(t.hold.running, isFalse);
      expect(t.player.played.length, 4, reason: 'name, greeting, topic, closing line: nothing twice');
    },
  );

  testWidgets('any touch stops the voice at once and clears the bubble and the glow', (
    WidgetTester tester,
  ) async {
    final t = setUp(const Duration(milliseconds: 800));
    unawaited(t.hold.run(_steps(), voiced: true));
    await tester.pump(const Duration(milliseconds: 1200));
    final int plays = t.player.plays;
    final int stops = t.player.stops;
    t.hold.skip();
    await tester.pump();
    expect(t.player.stops, greaterThan(stops), reason: 'the sound is stopped');
    expect(t.hold.shown.value, isNull);
    expect(t.hold.glow.value, isFalse);
    expect(t.hold.running, isFalse);
    await tester.pump(const Duration(seconds: 5));
    expect(t.player.plays, plays, reason: 'nothing is said after a touch');
    t.hold.skip();
  });

  testWidgets(
    'without recordings every sentence is shown for the same time as the bottle\'s line, nothing is played',
    (WidgetTester tester) async {
      final t = setUp(const Duration(milliseconds: 800));
      unawaited(t.hold.run(_steps(), voiced: false));
      await tester.pump();
      expect(t.hold.shown.value?.text, 'one');
      await tester.pump(const Duration(milliseconds: 2100));
      expect(t.hold.shown.value?.text, 'one');
      await tester.pump(const Duration(milliseconds: 600));
      expect(t.hold.shown.value?.text, 'two');
      await tester.pump(const Duration(milliseconds: 2500));
      expect(t.hold.shown.value?.text, 'three');
      expect(t.hold.glow.value, isTrue);
      await tester.pump(const Duration(milliseconds: 2300));
      expect(t.hold.shown.value, isNull);
      expect(
        t.player.plays,
        0,
        reason: 'a welcome with no recording is text; the name clip is not played alone',
      );
    },
  );

  testWidgets('a recording that cannot start leaves the sentence in the plain hold', (
    WidgetTester tester,
  ) async {
    final t = setUp(const Duration(milliseconds: 800));
    t.player.failToPlay = true;
    unawaited(t.hold.run(_steps(), voiced: true));
    await tester.pump(const Duration(milliseconds: 500));
    expect(t.hold.shown.value?.text, 'one');
    await tester.pump(const Duration(milliseconds: 1500));
    expect(
      t.hold.shown.value?.text,
      'one',
      reason: 'the sound is not there; the sentence still has its time',
    );
    await tester.pump(const Duration(milliseconds: 800));
    expect(t.hold.shown.value?.text, 'two', reason: 'and then the next one comes');
    await tester.pump(const Duration(seconds: 12));
    expect(t.hold.running, isFalse);
  });

  testWidgets('a welcome runs once; a touch before it or after it does nothing', (WidgetTester tester) async {
    final t = setUp(const Duration(milliseconds: 300));
    t.hold.skip();
    unawaited(t.hold.run(_steps(withName: false), voiced: false));
    await tester.pump(const Duration(seconds: 10));
    expect(t.hold.running, isFalse);
    final int count = t.seen.length;
    await t.hold.run(_steps(), voiced: false);
    expect(t.seen.length, count, reason: 'it does not run a second time');
    t.hold.skip();
  });

  testWidgets('leaving the map stops everything and lets the notifiers go', (WidgetTester tester) async {
    final t = setUp(const Duration(milliseconds: 800));
    unawaited(t.hold.run(_steps(), voiced: true));
    await tester.pump(const Duration(milliseconds: 100));
    t.hold.dispose();
    await tester.pump(const Duration(seconds: 5));
    expect(t.hold.running, isFalse);
    t.hold.dispose();
  });
}
