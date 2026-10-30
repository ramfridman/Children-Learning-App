import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/child/friends_beach.dart';
import 'package:nitznutz/child/home_screen.dart';
import 'package:nitznutz/content/models.dart';
import 'package:nitznutz/data/app_database.dart';
import 'package:nitznutz/design/components.dart';
import 'package:nitznutz/play/activity_frame.dart';
import 'package:nitznutz/strings/he.dart';

import 'support/app_harness.dart';
import 'support/harness.dart';
import 'support/starter.dart';
import 'support/voice_fixtures.dart';

/// Lets timers of the stage and the pauses between moves run, then draws.
Future<void> wait(WidgetTester t, [int ms = 2000]) async {
  // In steps, so that every animation gets frames while the time passes, like on a phone.
  for (int spent = 0; spent < ms; spent += 100) {
    await t.pump(const Duration(milliseconds: 100));
  }
  await t.pump(const Duration(milliseconds: 50));
}

Finder _bubble() => find.descendant(of: find.byKey(const Key('lesson-bubble')), matching: find.byType(Text));

String _bubbleText(WidgetTester t) => t.widget<Text>(_bubble()).data!;

Future<void> _tapKey(WidgetTester t, String key) async {
  await t.tap(find.byKey(Key(key)), warnIfMissed: false);
  await t.pump(const Duration(milliseconds: 60));
}

/// Touches butterflies [indexes] of a counting activity, with time for each to fly.
Future<void> _count(WidgetTester t, Iterable<int> indexes) async {
  for (final int i in indexes) {
    await _tapKey(t, 'butterfly-$i');
    await wait(t, 700);
  }
}

Future<List<Attempt>> _attempts(AppRig rig) => rig.db.attemptsOf('p-1');

String _row(Attempt a) =>
    '${a.activityId} ${a.result} hint${a.hintLevel} #${a.attemptNo} ${a.misconceptionTag} ${a.response}';

void main() {
  late PackContent content;
  setUpAll(() async {
    await loadAppFonts();
    content = await loadStarter();
  });

  String say(String id) => content.activities[id]!.promptLine.caption;

  for (final (String, Size) device in <(String, Size)>[
    ('phone', const Size(852, 393)),
    ('tablet landscape', const Size(1180, 820)),
    ('tablet portrait', const Size(820, 1180)),
  ]) {
    testWidgets('the scripted child plays the whole butterflies lesson by touch on a ${device.$1}', (
      WidgetTester tester,
    ) async {
      final AppRig rig = AppRig();
      await rig.seedFinishedSetup();
      // Two trophies are waiting for their ceremony (earned on another phone, say): the lesson's end gets only one.
      for (final String key in <String>['trophy:counting:bronze', 'trophy:counting:silver']) {
        await rig.db.addReward(
          RewardsCompanion.insert(
            profileId: 'p-1',
            awardKey: key,
            kind: 'trophy',
            at: DateTime.utc(2026, 10, 27),
          ),
        );
      }
      await rig.pump(tester, size: device.$2);
      await tester.tap(find.text('נועה'));
      await tester.pumpAndSettle();
      expect(find.byType(HomeScreen), findsOneWidget);

      // The counting hills start the lesson.
      await openCountingLesson(tester);
      await tester.pumpAndSettle();
      expect(find.byType(ActivityFrame), findsOneWidget);
      expect(tester.takeException(), isNull);

      // ---- 1. warm-up: where is the red flower? A wrong try first, then the right one ----
      expect(_bubbleText(tester), say('pick.red.flower'));
      await _tapKey(tester, 'option-o2'); // yellow
      expect(_bubbleText(tester), content.activities['pick.red.flower']!.feedback.forIncorrect(null).caption);
      await wait(tester, 1200);
      await _tapKey(tester, 'option-o1'); // red
      expect(_bubbleText(tester), content.activities['pick.red.flower']!.feedback.correct.caption);
      await wait(tester);

      // ---- 2. three butterflies in a line: count, answer 4 (counted one twice), look at the hint, count again ----
      expect(_bubbleText(tester), say('count.butterflies.3'));
      expect(
        find.byKey(const Key('tile-o2')).hitTestable(),
        findsNothing,
      ); // no answers before the counting is done
      await _count(tester, <int>[0, 1, 2]);
      expect(find.byKey(const Key('counter')), findsOneWidget);
      expect(
        _bubbleText(tester),
        (content.activities['count.butterflies.3']! as CountTapActivity).answerPrompt.caption,
      );
      await _tapKey(tester, 'tile-o3'); // 4
      expect(_bubbleText(tester), contains('פַּעֲמַיִם')); // the M-CNT-DOUBLE line
      await wait(tester, 2000);
      expect(find.byKey(const Key('counter')), findsNothing); // counting starts over
      await tester.tap(find.byKey(const Key('lesson-hint')));
      await wait(tester, 100);
      expect(_bubbleText(tester), content.activities['count.butterflies.3']!.hints[0].say.caption);
      await _count(tester, <int>[0, 1, 2]);
      await _tapKey(tester, 'tile-o2'); // 3
      expect(_bubbleText(tester), contains('שָׁלוֹשׁ'));
      await wait(tester);

      // ---- 3. four scattered: the same butterfly touched twice, then the right answer ----
      expect(_bubbleText(tester), say('count.butterflies.4'));
      await _tapKey(tester, 'butterfly-0');
      await tester.pump(const Duration(milliseconds: 100));
      await _tapKey(tester, 'butterfly-0'); // again, while it flies
      await wait(tester, 700);
      await _count(tester, <int>[1, 2, 3]);
      await _tapKey(tester, 'tile-o2'); // 4
      await wait(tester);

      // ---- 4. five that stay where they are and glow: three mistakes, fingers, the worked example, then success ----
      expect(_bubbleText(tester), say('count.butterflies.5'));
      await _count(tester, <int>[0, 1, 2, 3, 4]);
      await _tapKey(tester, 'tile-o1'); // 4: skipped one
      expect(_bubbleText(tester), contains('פִּסְפַּסְנוּ'));
      await wait(tester, 2000);
      await _count(tester, <int>[0, 1, 2, 3, 4]);
      await _tapKey(tester, 'tile-o3'); // 6: counted one twice
      final CountTapActivity five = content.activities['count.butterflies.5']! as CountTapActivity;
      expect(_bubbleText(tester), five.hints[1].say.caption);
      await wait(tester, 2000);
      expect(find.byKey(const Key('fingers-hint')), findsOneWidget); // the hand counts on its fingers
      await wait(tester, 6000);
      expect(find.byKey(const Key('fingers-hint')), findsNothing);
      await _count(tester, <int>[0, 1, 2, 3, 4]);
      await _tapKey(tester, 'tile-o1'); // a third mistake
      expect(_bubbleText(tester), five.hints[2].say.caption);
      await wait(tester, 1300);
      await wait(tester, 6000); // the guide counts them all and hands the turn back
      expect(find.byKey(const Key('counter')), findsOneWidget);
      await _tapKey(tester, 'tile-o1'); // only the right answer answers now
      expect(_bubbleText(tester), isNot(five.feedback.correct.caption));
      await _tapKey(tester, 'tile-o2');
      expect(_bubbleText(tester), five.feedback.correct.caption);
      await wait(tester);

      // ---- 5. give four of seven: take all of them (M-CNT-CARD), then give exactly four, touching and dragging ----
      expect(_bubbleText(tester), say('give.butterflies.4'));
      final Finder flower = find.byKey(const Key('give-flower'));
      for (int i = 0; i < 7; i++) {
        await _tapKey(tester, 'give-butterfly-$i');
        await tester.tapAt(tester.getCenter(flower));
        await wait(tester, 400);
      }
      await _tapKey(tester, 'give-done');
      expect(_bubbleText(tester), contains('לָקַחְנוּ'));
      await wait(tester, 1300);
      for (int i = 0; i < 2; i++) {
        await _tapKey(tester, 'give-butterfly-$i');
        await tester.tapAt(tester.getCenter(flower));
        await wait(tester, 400);
      }
      for (final int i in <int>[2, 3]) {
        // The same by dragging.
        final Offset from = tester.getCenter(find.byKey(Key('give-butterfly-$i')));
        await tester.dragFrom(from, tester.getCenter(flower) - from);
        await wait(tester, 400);
      }
      expect(find.text('4'), findsWidgets); // the counter on the flower says 4
      await _tapKey(tester, 'give-done');
      expect(_bubbleText(tester), content.activities['give.butterflies.4']!.feedback.correct.caption);
      await wait(tester);

      // ---- the end: the celebration, the trail full, and the way home ----
      expect(find.byKey(const Key('lesson-celebration')), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(const Key('lesson-celebration')),
          matching: find.text(content.lessons['butterflies']!.celebration.caption),
        ),
        findsOneWidget,
      );
      // The finished lesson gives a sticker, which pops in beside the guide and is kept (never random, never lost).
      await wait(tester, 600);
      expect(find.byKey(const Key('lesson-sticker')), findsOneWidget);
      final List<Reward> given = await rig.db.rewardsOf('p-1');
      expect(given.where((Reward r) => r.kind == 'sticker').map((Reward r) => r.awardKey), <String>[
        'sticker:butterflies:1',
      ]);
      expect(
        given.firstWhere((Reward r) => r.kind == 'sticker').seenAt,
        isNotNull,
        reason: 'shown, so not shown again',
      );
      await tester.tap(find.byKey(const Key('lesson-done')));
      await tester.pumpAndSettle();
      // Back on the map the highest waiting trophy gets its ceremony, and only that one; the other waits in the Hall.
      expect(find.byKey(const Key('ceremony')), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(const Key('ceremony-title')),
          matching: find.textContaining(He.trophySilver.text),
        ),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const Key('ceremony-continue')));
      await tester.pumpAndSettle();
      final Map<String, Reward> trophies = <String, Reward>{
        for (final Reward r in await rig.db.rewardsOf('p-1'))
          if (r.kind == 'trophy') r.awardKey: r,
      };
      expect(trophies['trophy:counting:silver']!.seenAt, isNotNull);
      expect(
        trophies['trophy:counting:bronze']!.seenAt,
        isNull,
        reason: 'one ceremony for each end of a lesson',
      );
      // After the first finished lesson the child is taken once to Friends' Beach to choose a companion.
      expect(find.byType(FriendsBeach), findsOneWidget);
      await tester.tap(find.byKey(const Key('friends-home')));
      await tester.pumpAndSettle();
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(tester.takeException(), isNull);

      // ---- what was written: the evidence the engine will read ----
      final List<String> rows = (await _attempts(rig)).map(_row).toList();
      expect(rows, <String>[
        'pick.red.flower incorrect hint0 #1  o2',
        'pick.red.flower correct hint0 #2  o1',
        'count.butterflies.3 incorrect hint0 #1 M-CNT-DOUBLE o3',
        'count.butterflies.3 correct hint1 #2  o2',
        'count.butterflies.4 correct hint0 #1 M-CNT-DOUBLE o2',
        'count.butterflies.5 incorrect hint0 #1 M-CNT-SKIP o1',
        'count.butterflies.5 incorrect hint0 #2 M-CNT-DOUBLE o3',
        'count.butterflies.5 incorrect hint2 #3 M-CNT-SKIP o1',
        'count.butterflies.5 correct hint3 #4  o2',
        'give.butterflies.4 incorrect hint0 #1 M-CNT-CARD n=7',
        'give.butterflies.4 correct hint0 #2  n=4',
      ]);
      final Attempt first = (await _attempts(rig)).first;
      expect(first.packId, 'starter');
      expect(first.packVersion, '0.10.0');
      expect(first.lessonId, 'butterflies');
      expect(first.activityRevision, 1);
      expect(first.templateVersion, '1.0');
      expect(first.profileId, 'p-1');
      // The visit is one session, ended as finished, and every answer belongs to it.
      final List<Session> visits = await rig.db.sessionsOf('p-1');
      expect(visits, hasLength(1));
      expect(visits.single.plan, 'lesson:butterflies');
      expect(visits.single.endReason, 'finished');
      expect(visits.single.endedAt, isNotNull);
      expect((await _attempts(rig)).every((Attempt a) => a.sessionId == visits.single.id), isTrue);
    });
  }

  testWidgets('"show me" is welcomed, never counted as a mistake, and gives the next help', (
    WidgetTester tester,
  ) async {
    final AppRig rig = AppRig();
    await rig.seedFinishedSetup();
    await rig.pump(tester);
    await tester.tap(find.text('נועה'));
    await tester.pumpAndSettle();
    await openCountingLesson(tester);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('lesson-show-me')));
    await wait(tester, 200);
    expect(_bubbleText(tester), content.activities['pick.red.flower']!.feedback.unsure.caption);
    final List<Attempt> rows = await _attempts(rig);
    expect(rows.single.result, 'unsure');
    expect(rows.single.misconceptionTag, '');
    await tester.tap(find.byKey(const Key('activity-home')));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 100));
    // Leaving in the middle ends the visit as "home".
    final List<Session> visits = await rig.db.sessionsOf('p-1');
    expect(visits.single.endReason, 'home');
    expect(rows.single.sessionId, visits.single.id);
  });

  testWidgets('the congratulation for a right answer is heard to its end before the next question is read', (
    WidgetTester tester,
  ) async {
    // A line ends only when the test says so, to see the next one wait for it.
    final AppRig rig = AppRig(player: FakePlayer());
    await rig.seedFinishedSetup();
    await rig.pump(tester);
    await tester.tap(find.text('נועה'));
    await tester.pumpAndSettle();
    await openCountingLesson(tester);
    await tester.pumpAndSettle();
    final int before = rig.player.plays;
    await _tapKey(tester, 'option-o1'); // red: right
    await wait(tester, 3000); // long enough for the lesson to move on
    expect(
      _bubbleText(tester),
      say('count.butterflies.3'),
      reason: 'the screen has moved to the next question',
    );
    // The congratulation is still "playing" (the fake player has not ended it): the next question waits for it.
    final int heardMeanwhile = rig.player.plays - before;
    expect(heardMeanwhile, lessThanOrEqualTo(1), reason: 'only the first line has been started');
    rig.player.finish();
    await wait(tester, 600);
    expect(
      rig.player.plays,
      before + heardMeanwhile + 1,
      reason: 'after the congratulation ends, the question is read',
    );
  });

  testWidgets(
    'a child who races hears what is still true: no question that is already answered, no old congratulation',
    (WidgetTester tester) async {
      final AppRig rig = AppRig(
        player: FakePlayer(),
      ); // no line ends by itself: the child is faster than every sentence
      await rig.seedFinishedSetup();
      await rig.pump(tester);
      await tester.tap(find.text('נועה'));
      await tester.pumpAndSettle();
      await openCountingLesson(tester);
      await tester.pumpAndSettle();
      await _tapKey(tester, 'option-o1'); // the first activity, right
      await wait(tester, 3000); // the lesson moves on while the first sounds are still "playing"
      expect(_bubbleText(tester), say('count.butterflies.3'));
      await _count(tester, <int>[0, 1, 2]);
      await _tapKey(tester, 'tile-o2'); // answers the second activity at once
      await wait(tester, 500);
      final List<String> lines = rig.player.played.map(utf8.decode).toList();
      expect(
        lines.where((String l) => l.endsWith('count.butterflies.3.prompt')),
        isEmpty,
        reason: 'the question was answered before it was ever read: it is not read late',
      );
      expect(lines.first, endsWith('pick.red.flower.prompt'));
      expect(
        lines.last,
        contains('count.butterflies.3'),
        reason: 'the answer to the second question is what is heard now',
      );
    },
  );

  testWidgets('the guide repeats the question when touched, and leaving the lesson stops everything', (
    WidgetTester tester,
  ) async {
    final AppRig rig = AppRig();
    await rig.seedFinishedSetup();
    await rig.pump(tester);
    await tester.tap(find.text('נועה'));
    await tester.pumpAndSettle();
    await openCountingLesson(tester);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('lesson-hint')));
    await wait(tester, 100);
    expect(_bubbleText(tester), isNot(say('pick.red.flower')));
    await tester.tap(find.byKey(const Key('lesson-replay')));
    await wait(tester, 100);
    expect(_bubbleText(tester), say('pick.red.flower'));
    // Leave in the middle of a wrong answer: its timers must not fire afterwards.
    await _tapKey(tester, 'option-o2');
    await tester.tap(find.byKey(const Key('activity-home')));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 5));
    expect(tester.takeException(), isNull);
    expect(find.byType(PebbleButton), findsWidgets);
  });
}
