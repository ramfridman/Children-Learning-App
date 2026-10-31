// B-26 step 5 in the real app: the bottle in the child's home opens the stop that Today's Adventure chooses from what the
// child has played (not always Counting Hills), a call for help opens the revisit of the map's own bell, the stop is only
// decided when the bottle is touched, and a bottle that is never touched changes nothing.
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/child/home_island_screen.dart';
import 'package:nitznutz/content/engine_adapter.dart';
import 'package:nitznutz/content/models.dart';
import 'package:nitznutz/data/app_database.dart';
import 'package:nitznutz/engine/engine.dart';
import 'package:nitznutz/engine/types.dart';
import 'package:nitznutz/play/lesson_screen.dart';
import 'package:nitznutz/rewards/award.dart';
import 'package:nitznutz/rewards/names.dart';
import 'package:nitznutz/strings/he.dart';
import 'package:nitznutz/world/placement.dart';

import 'support/bottle.dart';
import 'support/app_harness.dart';
import 'support/harness.dart';
import 'support/starter.dart';

Future<AppRig> homeIsland(WidgetTester tester, Future<void> Function(AppRig rig) seed) async {
  final AppRig rig = AppRig();
  await rig.seedFinishedSetup();
  await seed(rig);
  await rig.pump(tester);
  await tester.tap(find.text('נועה'));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const Key('home-pill')));
  await tester.pumpAndSettle();
  expect(find.byType(HomeIslandScreen), findsOneWidget);
  return rig;
}

/// Taps the bottle and returns the lesson screen that opened.
Future<LessonScreen> tapBottle(WidgetTester tester) async {
  await tapBottleAndWait(tester);
  return tester.widget<LessonScreen>(find.byType(LessonScreen));
}

/// The child finished these lessons, one visit each, with the sticker the lesson gives.
Future<void> finishLessons(AppRig rig, PackContent content, List<String> ids) async {
  DateTime at = DateTime.utc(2026, 10, 25, 9);
  for (final String id in ids) {
    final Lesson lesson = content.lessons[id]!;
    final int s = await rig.db.startSession('p-1', at, plan: 'lesson:$id');
    await rig.db.recordAttempt(
      AttemptsCompanion.insert(
        at: at,
        profileId: 'p-1',
        packId: 'starter',
        packVersion: '0.10.0',
        lessonId: Value<String>(id),
        activityId: lesson.itemIds.first,
        activityRevision: 1,
        template: 'count_tap',
        templateVersion: '1.0',
        skillId: lesson.skillIds.first,
        result: 'correct',
        attemptNo: 1,
        hintLevel: 0,
        sessionId: Value<int?>(s),
      ),
    );
    await rig.db.endSession(s, at, 'finished');
    await rig.db.addReward(
      RewardsCompanion.insert(profileId: 'p-1', awardKey: 'sticker:$id:1', kind: 'sticker', at: at),
    );
    at = at.add(const Duration(minutes: 20));
  }
}

/// An invented child who knew NUM-A-01 well, a month before the app's clock: its check has fallen due.
Future<void> seedDueCheck(AppRig rig, PackContent content) async {
  final Engine probe = Engine(catalog: engineCatalog(content));
  final List<ItemMeta> items = probe.catalog.itemsFor('NUM-A-01')
    ..sort((ItemMeta a, ItemMeta b) => a.id.compareTo(b.id));
  int n = 0;
  for (int day = 0; day < 4; day++) {
    for (final ItemMeta item in items) {
      await rig.db.recordAttempt(
        AttemptsCompanion.insert(
          at: DateTime.utc(2026, 9, 1, 9).add(Duration(days: day, minutes: n++)),
          profileId: 'p-1',
          packId: 'starter',
          packVersion: '0.10.0',
          activityId: item.id,
          activityRevision: 1,
          template: 'count_tap',
          templateVersion: '1.0',
          skillId: 'NUM-A-01',
          result: 'correct',
          attemptNo: 1,
          hintLevel: 0,
        ),
      );
    }
  }
}

/// What the friend's bubble on the home says (the home stays under the lesson that the bottle opened).
String bubbleText(WidgetTester tester) => tester
    .widget<Text>(
      find.descendant(
        of: find.byKey(const Key('home-island-bubble'), skipOffstage: false),
        matching: find.byType(Text, skipOffstage: false),
      ),
    )
    .data!;

String lineOf(Str line, TrophyLand land) => line.fill(<String, String>{'land': landName(land).text});

void main() {
  late PackContent content;

  setUpAll(() async {
    await loadAppFonts();
    content = await loadStarter();
  });

  testWidgets('after three Counting Hills lessons in a row the bottle opens the next land\'s first lesson', (
    WidgetTester tester,
  ) async {
    // numbers path: butterflies, counting-words, glance-small, ...; colours path begins with butterflies, then colour-match.
    await homeIsland(
      tester,
      (AppRig rig) => finishLessons(rig, content, <String>['butterflies', 'counting-words', 'glance-small']),
    );
    final LessonScreen lesson = await tapBottle(tester);
    expect(lesson.mission, isNull);
    expect(lesson.lessonId, 'colour-match');
    expect(find.byType(HomeIslandScreen), findsNothing, reason: 'the lesson is on top of the home');
    await tester.tap(find.byKey(const Key('activity-home')));
    await tester.pumpAndSettle();
    expect(
      find.byType(HomeIslandScreen),
      findsOneWidget,
      reason: 'a lesson from the bottle comes back to the home',
    );
  });

  testWidgets('after one lesson the bottle goes on in the same land', (WidgetTester tester) async {
    await homeIsland(tester, (AppRig rig) => finishLessons(rig, content, <String>['butterflies']));
    expect((await tapBottle(tester)).lessonId, 'counting-words');
  });

  testWidgets('a check that is due: the bottle opens the revisit of the map\'s own bell', (
    WidgetTester tester,
  ) async {
    await homeIsland(tester, (AppRig rig) async {
      await finishLessons(rig, content, <String>['butterflies']);
      await seedDueCheck(rig, content);
    });
    final LessonScreen lesson = await tapBottle(tester);
    expect(lesson.mission, isNotNull);
    expect(lesson.mission!.id, 'mission-num-a-01');
    expect(lesson.mission!.skillIds, <String>['NUM-A-01']);
  });

  testWidgets('a child who has played everything is given a game to play again, never an empty bottle', (
    WidgetTester tester,
  ) async {
    await homeIsland(
      tester,
      (AppRig rig) =>
          finishLessons(rig, content, <String>[for (final Lesson l in content.lessons.values) l.id]),
    );
    final LessonScreen lesson = await tapBottle(tester);
    expect(content.lessons.keys, contains(lesson.lessonId));
    expect(lesson.mission, isNull);
  });

  testWidgets('a bottle that is never touched changes nothing', (WidgetTester tester) async {
    final AppRig rig = await homeIsland(
      tester,
      (AppRig rig) => finishLessons(rig, content, <String>['butterflies']),
    );
    final int attempts = (await rig.db.attemptsOf('p-1')).length;
    final int sessions = (await rig.db.sessionsOf('p-1')).length;
    final int rewards = (await rig.db.rewardsOf('p-1')).length;
    await tester.pump(const Duration(hours: 5));
    await tester.tap(find.byKey(const Key('home-island-back')));
    await tester.pumpAndSettle();
    expect((await rig.db.attemptsOf('p-1')).length, attempts);
    expect((await rig.db.sessionsOf('p-1')).length, sessions);
    expect((await rig.db.rewardsOf('p-1')).length, rewards);
  });

  testWidgets('QA: a band B child new to the app gets the Counting Hills warm-up first from the bottle', (
    WidgetTester tester,
  ) async {
    final AppRig rig = AppRig();
    await rig.seedFinishedSetup(ageBand: 1, warmUp: true);
    await rig.pump(tester);
    await tester.tap(find.text('נועה'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('home-pill')));
    await tester.pumpAndSettle();
    final LessonScreen lesson = await tapBottle(tester);
    expect(lesson.mission, isNotNull, reason: 'the warm-up is a mission-shaped lesson');
    expect(lesson.mission!.id, 'placement');
  });

  testWidgets('B-39: the bottle sends a band B child on to a second land, and its warm-up comes first', (
    WidgetTester tester,
  ) async {
    final Lesson countingHills = placementLesson(content, 'numbers')!;
    final Lesson colourBay = placementLesson(content, 'colors')!;
    final AppRig rig = AppRig();
    await rig.seedFinishedSetup(ageBand: 1, warmUp: true);
    // The child did the Counting Hills warm-up, then three lessons there (not the first one, which Colour Bay shares).
    int n = 0;
    for (final String item in countingHills.itemIds) {
      await rig.db.recordAttempt(
        AttemptsCompanion.insert(
          at: DateTime.utc(2026, 10, 24, 9, n++),
          profileId: 'p-1',
          packId: 'starter',
          packVersion: '0.10.0',
          lessonId: const Value<String>(placementId),
          activityId: item,
          activityRevision: 1,
          template: 'count_tap',
          templateVersion: '1.0',
          skillId: content.activities[item]!.skills.first.id,
          result: 'incorrect',
          attemptNo: 3,
          hintLevel: 3,
        ),
      );
    }
    await finishLessons(rig, content, <String>['counting-words', 'glance-small', 'giving']);
    await rig.pump(tester);
    await tester.tap(find.text('נועה'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('home-pill')));
    await tester.pumpAndSettle();
    final LessonScreen lesson = await tapBottle(tester);
    expect(lesson.mission, isNotNull, reason: 'the second land begins with its warm-up');
    expect(lesson.mission!.id, placementId);
    expect(lesson.mission!.itemIds, colourBay.itemIds);
    expect(lesson.mission!.itemIds, isNot(countingHills.itemIds));
  });

  testWidgets('B-39: a band A child gets no warm-up from the bottle, in any land', (
    WidgetTester tester,
  ) async {
    final AppRig rig = AppRig();
    await rig.seedFinishedSetup(ageBand: 0, warmUp: true);
    await finishLessons(rig, content, <String>['counting-words', 'glance-small', 'giving']);
    await rig.pump(tester);
    await tester.tap(find.text('נועה'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('home-pill')));
    await tester.pumpAndSettle();
    expect((await tapBottle(tester)).mission, isNull);
  });

  group('B-39: the friend\'s bubble says the line of the stop when the bottle is tapped', () {
    testWidgets('welcome: a child who has not played yet', (WidgetTester tester) async {
      await homeIsland(tester, (AppRig rig) async {});
      await tapBottle(tester);
      expect(bubbleText(tester), lineOf(He.adventureWelcome, TrophyLand.counting));
    });

    testWidgets('sameLand: after one lesson, in the same land', (WidgetTester tester) async {
      await homeIsland(tester, (AppRig rig) => finishLessons(rig, content, <String>['butterflies']));
      await tapBottle(tester);
      expect(bubbleText(tester), lineOf(He.adventureSameLand, TrophyLand.counting));
    });

    testWidgets('otherLand: after three lessons, the next land by name', (WidgetTester tester) async {
      await homeIsland(
        tester,
        (AppRig rig) =>
            finishLessons(rig, content, <String>['butterflies', 'counting-words', 'glance-small']),
      );
      await tapBottle(tester);
      expect(bubbleText(tester), lineOf(He.adventureOtherLand, TrophyLand.colors));
    });

    testWidgets('callForHelp: a check that is due, in its land', (WidgetTester tester) async {
      await homeIsland(tester, (AppRig rig) async {
        await finishLessons(rig, content, <String>['butterflies']);
        await seedDueCheck(rig, content);
      });
      await tapBottle(tester);
      expect(bubbleText(tester), lineOf(He.adventureCallForHelp, TrophyLand.counting));
    });

    testWidgets('playAgain: everything played, a game once more, with no land in the line', (
      WidgetTester tester,
    ) async {
      await homeIsland(
        tester,
        (AppRig rig) =>
            finishLessons(rig, content, <String>[for (final Lesson l in content.lessons.values) l.id]),
      );
      await tapBottle(tester);
      expect(bubbleText(tester), He.adventurePlayAgain.text);
    });

    testWidgets('the line goes when the child comes back, and the bottle\'s label never changed', (
      WidgetTester tester,
    ) async {
      await homeIsland(tester, (AppRig rig) => finishLessons(rig, content, <String>['butterflies']));
      String label() => tester.getSemantics(find.byKey(const Key('home-island-bottle'))).label;
      expect(label(), He.homeDaily.text);
      final String welcome = bubbleText(tester);
      await tapBottle(tester);
      expect(bubbleText(tester), isNot(welcome));
      await tester.tap(find.byKey(const Key('activity-home')));
      await tester.pumpAndSettle();
      expect(bubbleText(tester), welcome, reason: 'back at the home the bubble is as it was');
      expect(label(), He.homeDaily.text, reason: 'the label is neutral: the stop is only chosen at the tap');
    });
  });

  testWidgets('QA: touching the bottle twice quickly opens one lesson, not two', (WidgetTester tester) async {
    await homeIsland(tester, (AppRig rig) => finishLessons(rig, content, <String>['butterflies']));
    final Finder bottle = find.byKey(const Key('home-island-bottle'));
    await tester.tap(bottle);
    await tester.pump(const Duration(milliseconds: 30));
    await tester.tap(bottle, warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(find.byType(LessonScreen), findsOneWidget);
  });
}
