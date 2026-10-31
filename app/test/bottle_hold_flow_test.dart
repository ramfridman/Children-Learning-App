// B-39: what happens between the touch on the bottle and the stop it opens. The line is held in front of the child (about
// 2.2 s, or until its recording ends), a second touch opens the stop at once, leaving the home drops it, and a touch that
// finds nothing to open only wobbles the bottle.
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/app/companion.dart';
import 'package:nitznutz/child/home_island_name.dart';
import 'package:nitznutz/child/home_island_screen.dart';
import 'package:nitznutz/content/models.dart';
import 'package:nitznutz/data/app_database.dart';
import 'package:nitznutz/content/pack_verify.dart';
import 'package:nitznutz/play/lesson_screen.dart';
import 'package:nitznutz/voice/voice_bank.dart';
import 'package:nitznutz/voice/voice_director.dart';

import '../tool/pack_builder_lib.dart';
import 'support/app_harness.dart';
import 'support/harness.dart';
import 'support/pack_fixtures.dart';
import 'support/starter.dart';
import 'support/voice_fixtures.dart';

String bubbleText(WidgetTester tester) => tester
    .widget<Text>(
      find.descendant(
        of: find.byKey(const Key('home-island-bubble'), skipOffstage: false),
        matching: find.byType(Text, skipOffstage: false),
      ),
    )
    .data!;

Future<void> openHome(WidgetTester tester, AppRig rig) async {
  await rig.pump(tester);
  await tester.tap(find.text('נועה'));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const Key('home-pill')));
  await tester.pumpAndSettle();
  expect(find.byType(HomeIslandScreen), findsOneWidget);
}

/// Touches the bottle and steps on until the bubble says the line of the stop.
Future<String> tapUntilLine(WidgetTester tester) async {
  final String welcome = bubbleText(tester);
  await tester.tap(find.byKey(const Key('home-island-bottle')));
  for (int i = 0; i < 20 && bubbleText(tester) == welcome; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
  expect(bubbleText(tester), isNot(welcome), reason: 'the bubble says the line');
  return welcome;
}

Future<void> seedChild(AppRig rig) async {
  await rig.seedFinishedSetup();
  // A lesson already finished, so that the line is "sameLand" and nothing about a first visit gets in the way.
  final DateTime at = DateTime.utc(2026, 10, 25, 9);
  final int s = await rig.db.startSession('p-1', at, plan: 'lesson:butterflies');
  await rig.db.recordAttempt(
    AttemptsCompanion.insert(
      at: at,
      profileId: 'p-1',
      packId: 'starter',
      packVersion: '0.10.0',
      lessonId: const Value<String>('butterflies'),
      activityId: 'count.butterflies.3',
      activityRevision: 1,
      template: 'count_tap',
      templateVersion: '1.0',
      skillId: 'NUM-A-01',
      result: 'correct',
      attemptNo: 1,
      hintLevel: 0,
      sessionId: Value<int?>(s),
    ),
  );
  await rig.db.endSession(s, at, 'finished');
  await rig.db.addReward(
    RewardsCompanion.insert(profileId: 'p-1', awardKey: 'sticker:butterflies:1', kind: 'sticker', at: at),
  );
}

void main() {
  setUpAll(() async {
    await loadAppFonts();
  });

  testWidgets('a second touch on the bottle opens the stop at once', (WidgetTester tester) async {
    final AppRig rig = AppRig();
    await seedChild(rig);
    await openHome(tester, rig);
    await tapUntilLine(tester);
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(LessonScreen), findsNothing, reason: 'the line is still being held');
    await tester.tap(find.byKey(const Key('home-island-bottle')));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpAndSettle();
    expect(find.byType(LessonScreen), findsOneWidget);
    // The rest of the hold has no one waiting for it any more.
    await tester.pump(const Duration(seconds: 3));
    expect(find.byType(LessonScreen), findsOneWidget, reason: 'one lesson, not two');
  });

  testWidgets('leaving the home during the hold drops the stop', (WidgetTester tester) async {
    final AppRig rig = AppRig();
    await seedChild(rig);
    await openHome(tester, rig);
    await tapUntilLine(tester);
    await tester.tap(find.byKey(const Key('home-island-back')));
    await tester.pumpAndSettle();
    expect(find.byType(HomeIslandScreen), findsNothing);
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
    expect(find.byType(LessonScreen), findsNothing, reason: 'nobody is waiting for the lesson any more');
  });

  testWidgets('touching the sticker book during the hold drops the stop, the book opens', (
    WidgetTester tester,
  ) async {
    final AppRig rig = AppRig();
    await seedChild(rig);
    await openHome(tester, rig);
    await tapUntilLine(tester);
    await tester.tap(find.byKey(const Key('home-island-book')));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
    expect(find.byType(LessonScreen), findsNothing);
  });

  group('with a recording of the line', () {
    late VoiceBank bank;

    setUpAll(() async {
      final PackKey key = await newTestKey();
      bank = VoiceBank.fromPack(
        await verifyPack(
          (await buildVoicePack(key, 'hero-son', <String, List<(int, int)>>{
            'core.adventure.same_land.counting': <(int, int)>[(0, 1)],
          })).bytes,
          publicKey: key.publicKey,
        ),
      );
    });

    AppRig rigWithClip(FakePlayer player) {
      final VoiceDirector director = VoiceDirector(player: player)..useBank(bank);
      addTearDown(director.dispose);
      return AppRig(
        player: player,
        extraOverrides: <Override>[voiceDirectorProvider.overrideWithValue(director)],
      );
    }

    testWidgets('the stop opens when the recording ends, not at 2.2 s', (WidgetTester tester) async {
      final FakePlayer player = FakePlayer()..endsAfter = const Duration(milliseconds: 900);
      final AppRig rig = rigWithClip(player);
      await seedChild(rig);
      await openHome(tester, rig);
      await tapUntilLine(tester);
      expect(player.played.length, 1, reason: 'the line is said in its voice');
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(LessonScreen), findsNothing, reason: 'the recording is still playing');
      expect(player.at, isNotNull, reason: 'the sound is playing');
      await tester.pump(const Duration(milliseconds: 900));
      await tester.pumpAndSettle();
      expect(find.byType(LessonScreen), findsOneWidget, reason: 'it ended: the stop opens');
    });

    testWidgets('a second touch during the recording opens the stop and does not cut the recording', (
      WidgetTester tester,
    ) async {
      final FakePlayer player = FakePlayer()..endsAfter = const Duration(milliseconds: 1500);
      final AppRig rig = rigWithClip(player);
      await seedChild(rig);
      await openHome(tester, rig);
      await tapUntilLine(tester);
      final int stops = player.stops;
      await tester.pump(const Duration(milliseconds: 200));
      await tester.tap(find.byKey(const Key('home-island-bottle')));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();
      expect(find.byType(LessonScreen), findsOneWidget);
      expect(player.stops, stops, reason: 'the lesson did not stop the recording');
      expect(player.at, isNotNull, reason: 'it is still playing under the lesson');
      await tester.pump(const Duration(seconds: 2));
      expect(player.at, isNull, reason: 'it ended by itself');
    });
  });

  group('with nothing to open', () {
    Future<AppRig> emptyHome(WidgetTester tester, {bool reduceMotion = true}) async {
      final PackContent empty = await loadStarter();
      empty.lessons.clear();
      final AppRig rig = AppRig(content: empty);
      await rig.seedFinishedSetup();
      await rig.pump(tester, reduceMotion: reduceMotion);
      await tester.tap(find.text('נועה'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('home-pill')));
      await tester.pumpAndSettle();
      return rig;
    }

    testWidgets('the touch opens nothing and the bubble keeps its words', (WidgetTester tester) async {
      await emptyHome(tester);
      final String welcome = bubbleText(tester);
      await tester.tap(find.byKey(const Key('home-island-bottle')));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();
      expect(find.byType(LessonScreen), findsNothing);
      expect(find.byType(HomeIslandScreen), findsOneWidget);
      expect(bubbleText(tester), welcome);
      // And the bottle can be touched again: the touch is not left busy.
      await tester.tap(find.byKey(const Key('home-island-bottle')));
      await tester.pumpAndSettle();
      expect(find.byType(LessonScreen), findsNothing);
    });
  });

  group('the wobble of the bottle', () {
    double rockOf(WidgetTester tester) {
      double most = 0;
      for (final Transform t in tester.widgetList<Transform>(
        find.descendant(
          of: find.byKey(const Key('home-island-bottle-box')),
          matching: find.byType(Transform),
        ),
      )) {
        final double sin = t.transform.entry(1, 0).abs();
        if (sin > most) most = sin;
      }
      return most;
    }

    Future<ValueNotifier<int>> pumpWobbling(WidgetTester tester, {required bool reduceMotion}) async {
      tester.platformDispatcher.accessibilityFeaturesTestValue = FakeAccessibilityFeatures(
        disableAnimations: reduceMotion,
      );
      addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
      final ValueNotifier<int> wobble = ValueNotifier<int>(0);
      addTearDown(wobble.dispose);
      await pumpScreen(
        tester,
        HomeIslandScreen(
          island: homeIslandName('נֹעָה'),
          companion: const SizedBox.expand(),
          onBottle: () {},
          bottleWobble: wobble,
        ),
      );
      await tester.pump();
      return wobble;
    }

    testWidgets('a touch that found nothing rocks the bottle by about 5 degrees, then it settles', (
      WidgetTester tester,
    ) async {
      final ValueNotifier<int> wobble = await pumpWobbling(tester, reduceMotion: false);
      // The bob alone never takes the bottle past 3 degrees (sin 3 degrees = 0.052).
      expect(rockOf(tester), lessThan(0.053));
      wobble.value++;
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 90));
      expect(rockOf(tester), greaterThan(0.075), reason: 'it rocks');
      await tester.pump(const Duration(milliseconds: 800));
      expect(rockOf(tester), lessThan(0.053), reason: 'and settles back to the bob');
    });

    testWidgets('with reduce motion the bottle stays still', (WidgetTester tester) async {
      final ValueNotifier<int> wobble = await pumpWobbling(tester, reduceMotion: true);
      wobble.value++;
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 90));
      expect(rockOf(tester), 0);
    });
  });
}
