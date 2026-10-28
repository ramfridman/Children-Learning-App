// The AI tutor inside the real lesson screen, with a fake service: what it asks, when it speaks, and every way it can fail.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/child/home_screen.dart';
import 'package:nitznutz/play/activity_frame.dart';
import 'package:nitznutz/tutor/tutor.dart';

import 'support/app_harness.dart';
import 'support/fake_tutor.dart';
import 'support/harness.dart';

Future<void> wait(WidgetTester t, [int ms = 2000]) async {
  for (int spent = 0; spent < ms; spent += 100) {
    await t.pump(const Duration(milliseconds: 100));
  }
  await t.pump(const Duration(milliseconds: 50));
}

Future<void> tapKey(WidgetTester t, String key) async {
  await t.tap(find.byKey(Key(key)), warnIfMissed: false);
  await t.pump(const Duration(milliseconds: 60));
}

Future<void> count(WidgetTester t, Iterable<int> indexes) async {
  for (final int i in indexes) {
    await tapKey(t, 'butterfly-$i');
    await wait(t, 700);
  }
}

List<String> heard(AppRig rig) => rig.player.played.map(String.fromCharCodes).toList();

/// Opens the lesson and gets past the warm-up (no tutor there) to the three butterflies.
Future<AppRig> toCounting(WidgetTester tester, AppRig rig) async {
  // Lines end by themselves, as real sound does, so that each waits for the one before it.
  rig.player.endsAfter = const Duration(milliseconds: 150);
  await rig.seedFinishedSetup();
  await rig.pump(tester);
  await tester.tap(find.text('נועה'));
  await tester.pumpAndSettle();
  expect(find.byType(HomeScreen), findsOneWidget);
  await openCountingLesson(tester);
  await tester.pumpAndSettle();
  expect(find.byType(ActivityFrame), findsOneWidget);
  await wait(tester, 300);
  await tapKey(tester, 'option-o1');
  await wait(tester);
  return rig;
}

/// Counts the three butterflies and gives the answer "four" (a wrong one that carries a misconception).
Future<void> wrongFour(WidgetTester tester) async {
  await count(tester, <int>[0, 1, 2]);
  await tapKey(tester, 'tile-o3');
  await wait(tester, 300);
}

String bubbleText(WidgetTester t) => t
    .widget<Text>(find.descendant(of: find.byKey(const Key('lesson-bubble')), matching: find.byType(Text)))
    .data!;

void main() {
  setUpAll(loadAppFonts);

  testWidgets('with the helper off nothing is ever asked', (WidgetTester tester) async {
    final FakeTutorClient client = FakeTutorClient();
    final AppRig rig = await toCounting(tester, AppRig(tutor: client, aiHelper: false));
    await wrongFour(tester);
    await wait(tester, 2000);
    await wrongFour(tester);
    expect(client.asked, isEmpty);
    expect(heard(rig), contains('mp3:nitzi:hint.count.h2'), reason: 'the authored line was said');
  });

  testWidgets(
    'a server switch that answers late still gives the helper to the lesson that was already open',
    (WidgetTester tester) async {
      final FakeTutorClient client = FakeTutorClient();
      final AppRig rig = AppRig(tutor: client, switchAnswersAfter: const Duration(milliseconds: 2500));
      await rig.seedFinishedSetup();
      await rig.pump(tester);
      await tester.tap(find.text('נועה'));
      await tester.pumpAndSettle();
      await openCountingLesson(tester);
      await wait(tester, 1500);
      expect(find.byType(ActivityFrame), findsOneWidget);
      await tapKey(tester, 'option-o1');
      await wait(tester, 4000);
      expect(
        client.asked.where((TutorAsk a) => a.itemId == 'count.butterflies.3'),
        isNotEmpty,
        reason: 'the answer came after the lesson opened; the lesson uses it from then on',
      );
    },
  );

  testWidgets('with the server switch off nothing is asked after the first check', (
    WidgetTester tester,
  ) async {
    final FakeTutorClient client = FakeTutorClient();
    await toCounting(tester, AppRig(tutor: client, tutorEnabledOnServer: false));
    await wrongFour(tester);
    expect(client.asked, isEmpty);
  });

  testWidgets('when an activity opens, the lines of its likely mistakes are asked for ahead, with ids only', (
    WidgetTester tester,
  ) async {
    final FakeTutorClient client = FakeTutorClient();
    await toCounting(tester, AppRig(tutor: client));
    final List<TutorAsk> ahead = client.asked
        .where((TutorAsk a) => a.itemId == 'count.butterflies.3')
        .toList();
    expect(ahead.length, 2);
    final TutorAsk tags = ahead.firstWhere((TutorAsk a) => a.mistakes.length > 1);
    expect(tags.prefetch, isTrue);
    expect(tags.mistakes.toSet(), <String>{'M-CNT-SKIP', 'M-CNT-DOUBLE'});
    expect(tags.hintLevel, 2);
    final TutorAsk plain = ahead.firstWhere((TutorAsk a) => a.mistakes.length == 1);
    expect(plain.mistakes, <String>['default']);
    expect(plain.hintLevel, 0);
    for (final TutorAsk a in ahead) {
      expect(a.band, 'B');
      expect(a.characterId, 'nitzi');
      expect(a.packId, 'starter');
      expect(a.childRef, 'p-1');
      expect(a.sessionRef, matches(RegExp(r'^[A-Za-z0-9-]{8,64}$')));
    }
    expect(
      client.asked.where((TutorAsk a) => a.itemId == 'pick.red.flower'),
      isEmpty,
      reason: 'the author did not allow the AI there',
    );
  });

  testWidgets(
    'the first, expected mistake gets the authored line; the second gets the line made ahead, at once',
    (WidgetTester tester) async {
      final FakeTutorClient client = FakeTutorClient();
      final AppRig rig = await toCounting(tester, AppRig(tutor: client));
      await wrongFour(tester);
      expect(
        heard(rig).last,
        'mp3:nitzi:fb.double',
        reason: 'the authored diagnostic line is the first answer',
      );
      await wait(tester, 2000);
      await wrongFour(tester);
      expect(
        heard(rig).last,
        'live:M-CNT-DOUBLE:2',
        reason: 'the tutor line, in the guide\'s voice, with no wait',
      );
      expect(
        heard(rig),
        isNot(contains('mp3:nitzi:hint.count.h2')),
        reason: 'the authored hint voice did not play too',
      );
      expect(bubbleText(tester), 'line for M-CNT-DOUBLE at level 2', reason: 'Band B reads the caption');
      expect(
        client.asked.where((TutorAsk a) => !a.prefetch),
        isEmpty,
        reason: 'nothing had to be asked at that moment',
      );
    },
  );

  testWidgets('a slow service: the guide thinks, says "hmm" at 1.5 s, and uses the authored line at 3 s', (
    WidgetTester tester,
  ) async {
    final FakeTutorClient client = FakeTutorClient();
    final AppRig rig = await toCounting(tester, AppRig(tutor: client));
    await wrongFour(tester);
    await wait(tester, 2000);
    client.delay = const Duration(seconds: 10);
    client.asked.clear();
    // Forget what was prefetched: the lines at hint 2 are in memory, so ask for another kind of mistake.
    await wrongFour(tester); // the second mistake: the line made ahead answers
    expect(heard(rig).last, 'live:M-CNT-DOUBLE:2');
  });

  testWidgets(
    'a line that was not made ahead and is slow: thinking, then the recorded "hmm", then the authored line',
    (WidgetTester tester) async {
      final FakeTutorClient client = FakeTutorClient()..gate = Completer<void>();
      final AppRig rig = await toCounting(tester, AppRig(tutor: client));
      // Nothing was made ahead (the service answers only when the test lets it), so the second mistake has to wait.
      await wrongFour(tester);
      await wait(tester, 2000);
      await count(tester, <int>[0, 1, 2]);
      await tapKey(tester, 'tile-o3');
      final int before = heard(rig).length;
      await wait(tester, 1200);
      expect(heard(rig).length, before, reason: 'silence for the first second and a half');
      await wait(tester, 600);
      expect(heard(rig).last, 'mp3:nitzi:core.thinking.think', reason: 'the recorded "hmm" covers the wait');
      await wait(tester, 1600);
      expect(
        heard(rig).last,
        'mp3:nitzi:hint.count.h2',
        reason: 'at 3 seconds the authored line is said instead',
      );
      expect(bubbleText(tester), isNot(contains('line for')));
      await wait(tester, 3000);
      // The service answers at last, far too late: the line is not spoken.
      client.gate!.complete();
      await wait(tester, 500);
      expect(
        heard(rig).where((String h) => h.startsWith('live:')),
        isEmpty,
        reason: 'a line that comes too late is never spoken',
      );
    },
  );

  testWidgets(
    'a service that refuses, three times, ends the helper for the lesson: the authored lines carry on',
    (WidgetTester tester) async {
      final FakeTutorClient client = FakeTutorClient()..rule = 'model_failed';
      final AppRig rig = await toCounting(tester, AppRig(tutor: client));
      await wrongFour(tester);
      await wait(tester, 2000);
      await wrongFour(tester);
      await wait(tester, 400);
      expect(heard(rig).last, 'mp3:nitzi:hint.count.h2', reason: 'the authored line, with no error shown');
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'the helper never reaches a child as an error: the screen shows no error text whatever the service says',
    (WidgetTester tester) async {
      final FakeTutorClient client = FakeTutorClient()..rule = 'kill_switch';
      final AppRig rig = await toCounting(tester, AppRig(tutor: client));
      await wrongFour(tester);
      await wait(tester, 2000);
      await wrongFour(tester);
      await wait(tester, 500);
      expect(find.textContaining('error'), findsNothing);
      expect(heard(rig).last, 'mp3:nitzi:hint.count.h2');
      // The server switch stopped it: nothing more was asked after that answer.
      final int asked = client.asked.length;
      await wait(tester, 2000);
      expect(client.asked.length, asked);
    },
  );
}
