// Answering by voice in the real lesson screen, with a fake recogniser that says what the test tells it to.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/child/home_screen.dart';
import 'package:nitznutz/data/app_database.dart';
import 'package:nitznutz/design/components.dart';
import 'package:nitznutz/play/activity_frame.dart';

import 'support/app_harness.dart';
import 'support/fake_speech.dart';
import 'support/golden_comparator.dart';
import 'support/harness.dart';

/// Lets stage timers and the pauses between moves run, in steps, so that animations get frames.
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

/// A question whose answer is said (board B-24): "איזה צבע יש לתפוח?", with a red (right), an orange and a pink ball.
const String colourQuestion = 'col.world.apple.red';

Future<AppRig> start(
  WidgetTester tester, {
  bool voice = true,
  List<Scripted> script = const <Scripted>[],
  List<String> items = const <String>[colourQuestion],
}) async {
  final AppRig rig = AppRig(voice: voice, speech: FakeSpeechEngine(script));
  await rig.seedFinishedSetup();
  await rig.pump(tester);
  await tester.tap(find.text('נועה'));
  await tester.pumpAndSettle();
  expect(find.byType(HomeScreen), findsOneWidget);
  await openActivities(tester, items);
  await tester.pumpAndSettle();
  expect(find.byType(ActivityFrame), findsOneWidget);
  await wait(tester, 300);
  return rig;
}

Future<List<Attempt>> attempts(AppRig rig) => rig.db.attemptsOf('p-1');

Finder get mic => find.byKey(const Key('lesson-mic'));

MicLook look(WidgetTester t) => t.widget<MicButton>(mic).look;

/// Taps the mic and lets the (fake) listen and the matching run.
Future<void> speak(WidgetTester t) async {
  await t.tap(mic);
  await wait(t, 1200);
}

void main() {
  setUpAll(() async {
    await loadAppFonts();
    useTolerantGoldens(0.03);
  });

  goldens();

  testWidgets('the mic is never taken away, however badly listening went before', (
    WidgetTester tester,
  ) async {
    final AppRig rig = AppRig(voice: true, speech: FakeSpeechEngine(const <Scripted>[]));
    await rig.seedFinishedSetup();
    for (final String type in <String>['number', 'word']) {
      for (int i = 0; i < 12; i++) {
        await rig.db.recordListen(
          'p-1',
          DateTime.utc(2026, 10, 27, 9, i),
          type,
          i.isEven ? 'unclear' : 'silent',
        );
      }
    }
    await rig.pump(tester);
    await tester.tap(find.text('נועה'));
    await tester.pumpAndSettle();
    await openActivities(tester, <String>[colourQuestion]);
    await tester.pumpAndSettle();
    await wait(tester, 300);
    expect(mic, findsOneWidget, reason: 'a child who is often misheard still has the mic');
  });

  testWidgets('with voice off there is no mic and nothing listens', (WidgetTester tester) async {
    final AppRig rig = await start(tester, voice: false);
    expect(mic, findsNothing);
    expect(rig.speech.listens, 0);
    expect(rig.speech.prepares, 0);
  });

  testWidgets(
    'with voice on the mic is offered when the question is open, and a clear answer counts like a tap',
    (WidgetTester tester) async {
      final AppRig rig = await start(tester, script: <Scripted>[Scripted.says('אדום')]);
      expect(mic, findsOneWidget);
      expect(look(tester), MicLook.ready);
      expect(rig.speech.listens, 0, reason: 'the mic opens only when the child taps it');
      await tester.tap(mic);
      await tester.pump(const Duration(milliseconds: 100));
      await wait(tester, 1500);
      final List<Attempt> rows = await attempts(rig);
      expect(rows.single.result, 'correct');
      expect(rows.single.response, 'o1');
      expect(rows.single.input, 'voice');
      expect(rig.speech.micOpen, isFalse);
      // The guide stopped talking before the mic opened.
      expect(rig.speech.log.first, 'prepare');
      final List<VoiceListen> listens = await rig.db.recentListens('p-1', 'word');
      expect(listens.single.outcome, 'accepted');
    },
  );

  testWidgets('a wrong colour said aloud is checked first: a tick or "again", never a "not yet" by itself', (
    WidgetTester tester,
  ) async {
    final AppRig rig = await start(tester, script: <Scripted>[Scripted.says('כתום')]);
    await speak(tester);
    expect(await attempts(rig), isEmpty, reason: 'nothing counted yet');
    expect(find.byKey(const Key('confirm-yes')), findsOneWidget);
    expect(find.byKey(const Key('confirm-again')), findsOneWidget);
    expect(heardLines(rig).last, 'mp3:nitzi:core.listen.confirm');
    await tester.tap(find.byKey(const Key('confirm-yes')));
    await wait(tester, 1500);
    final List<Attempt> rows = await attempts(rig);
    expect(rows.single.response, 'o2');
    expect(rows.single.result, 'incorrect');
    expect(rows.single.input, 'voice');
    expect(find.byKey(const Key('confirm-yes')), findsNothing);
  });

  testWidgets('"again" on the check takes it back and nothing is written', (WidgetTester tester) async {
    final AppRig rig = await start(tester, script: <Scripted>[Scripted.says('כתום')]);
    await speak(tester);
    await tester.tap(find.byKey(const Key('confirm-again')));
    await wait(tester, 800);
    expect(await attempts(rig), isEmpty);
    expect(find.byKey(const Key('confirm-yes')), findsNothing);
  });

  testWidgets(
    'unclear speech: asked again once, then the cards invite a tap, and nothing is ever marked wrong',
    (WidgetTester tester) async {
      final AppRig rig = await start(
        tester,
        script: <Scripted>[Scripted.says('בננה'), Scripted.says('אוטובוס')],
      );
      await speak(tester);
      expect(heardLines(rig).last, 'mp3:nitzi:core.listen.mixed');
      expect(look(tester), MicLook.ready);
      await speak(tester);
      expect(heardLines(rig).last, 'mp3:nitzi:core.listen.tap');
      expect(look(tester), MicLook.faded);
      await wait(tester, 1500);
      expect(await attempts(rig), isEmpty);
      // The cards still work by touch.
      await tapKey(tester, 'tile-o1');
      await wait(tester, 400);
      final List<Attempt> rows = await attempts(rig);
      expect(rows.single.result, 'correct');
      expect(rows.single.input, 'tap');
      final List<String> outcomes = (await rig.db.recentListens(
        'p-1',
        'word',
      )).map((VoiceListen l) => l.outcome).toList();
      expect(outcomes, <String>['unclear', 'unclear']);
    },
  );

  testWidgets('silence is never wrong either', (WidgetTester tester) async {
    final AppRig rig = await start(tester, script: <Scripted>[Scripted.silence(), Scripted.silence()]);
    await speak(tester);
    await speak(tester);
    expect(look(tester), MicLook.faded);
    expect(await attempts(rig), isEmpty);
  });

  testWidgets('"I don\'t know" is welcomed like the eye button, and "again" asks the question again', (
    WidgetTester tester,
  ) async {
    final AppRig rig = await start(
      tester,
      script: <Scripted>[Scripted.says('לא יודע'), Scripted.says('עוד פעם')],
    );
    await speak(tester);
    final List<Attempt> rows = await attempts(rig);
    expect(rows.single.result, 'unsure');
    final int before = rig.player.plays;
    await speak(tester);
    expect(rig.player.plays, greaterThan(before), reason: 'the question was said again');
    expect((await attempts(rig)).length, 1);
  });

  testWidgets('a model that will not load leaves the cards to tap and nothing breaks', (
    WidgetTester tester,
  ) async {
    final AppRig rig = AppRig(voice: true, speech: FakeSpeechEngine()..failPrepare = true);
    await rig.seedFinishedSetup();
    await rig.pump(tester);
    await tester.tap(find.text('נועה'));
    await tester.pumpAndSettle();
    await openActivities(tester, <String>[colourQuestion]);
    await tester.pumpAndSettle();
    await wait(tester, 300);
    await speak(tester);
    expect(look(tester), MicLook.faded);
    expect(tester.takeException(), isNull);
    await tapKey(tester, 'tile-o1');
    await wait(tester, 400);
    expect((await attempts(rig)).single.result, 'correct');
  });

  testWidgets('leaving the lesson while listening closes the microphone', (WidgetTester tester) async {
    final AppRig rig = await start(tester, script: <Scripted>[Scripted.hangs()]);
    await tester.tap(mic);
    await tester.pump(const Duration(milliseconds: 200));
    expect(rig.speech.micOpen, isTrue);
    await tester.tap(find.byKey(const Key('activity-home')));
    await tester.pumpAndSettle();
    expect(rig.speech.micOpen, isFalse);
    expect(await attempts(rig), isEmpty);
  });

  testWidgets('the app going to the background closes the microphone at once', (WidgetTester tester) async {
    final AppRig rig = await start(tester, script: <Scripted>[Scripted.hangs()]);
    await tester.tap(mic);
    await tester.pump(const Duration(milliseconds: 200));
    expect(rig.speech.micOpen, isTrue);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await tester.pump();
    expect(
      rig.speech.micOpen,
      isFalse,
      reason: 'closed at the first sign that the app is leaving, not at a timeout',
    );
    expect(await attempts(rig), isEmpty);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(mic, findsOneWidget, reason: 'the mic is offered again when the child is back');
  });

  // Board B-24: the mic is there only where saying the answer is the answer.
  group('the mic only where speaking is the answer', () {
    testWidgets('"where is the red flower?" is answered by a tap: no mic at all, even with voice on', (
      WidgetTester tester,
    ) async {
      final AppRig rig = AppRig(voice: true, speech: FakeSpeechEngine(const <Scripted>[]));
      await rig.seedFinishedSetup();
      await rig.pump(tester);
      await tester.tap(find.text('נועה'));
      await tester.pumpAndSettle();
      // The real way in: the first lesson of the Counting land starts with pick.red.flower.
      await openCountingLesson(tester);
      await tester.pumpAndSettle();
      await wait(tester, 300);
      expect(find.byKey(const Key('option-o1')), findsOneWidget);
      expect(mic, findsNothing);
      expect(find.byKey(const Key('confirm-yes')), findsNothing);
      expect(rig.speech.prepares, 0);
      // Answering by a tap moves on to the counting, which is spoken: the mic comes (faded while the child counts).
      await tapKey(tester, 'option-o1');
      await wait(tester, 2500);
      expect(find.byKey(const Key('butterfly-0')), findsOneWidget);
      expect(mic, findsOneWidget);
      expect(look(tester), MicLook.faded);
    });

    testWidgets('counting: the mic is faded while the child counts, and ready at "how many?"', (
      WidgetTester tester,
    ) async {
      final AppRig rig = await start(
        tester,
        items: <String>['count.butterflies.3'],
        script: <Scripted>[Scripted.says('שלוש')],
      );
      expect(mic, findsOneWidget);
      expect(look(tester), MicLook.faded, reason: 'nothing to say yet: the butterflies are being counted');
      await tester.tap(mic, warnIfMissed: false);
      await wait(tester, 300);
      expect(rig.speech.listens, 0, reason: 'a faded mic does not listen');
      for (int i = 0; i < 3; i++) {
        await tapKey(tester, 'butterfly-$i');
        await wait(tester, 700);
      }
      await wait(tester, 1500);
      expect(look(tester), MicLook.ready);
      await speak(tester);
      final List<Attempt> rows = await attempts(rig);
      expect(rows.single.result, 'correct');
      expect(rows.single.input, 'voice');
    });

    for (final (String, String) c in <(String, String)>[
      ('same.apples.4v5', 'a yes or no question ("the same number?")'),
      ('b.numb08.1', '"where is the number twelve?"'),
      ('give.butterflies.4', 'giving a number of things'),
      ('b.numb13.1', 'the number line'),
      ('b.mathb13.1', 'the balance'),
    ]) {
      testWidgets('${c.$2} has no mic, even with voice on', (WidgetTester tester) async {
        final AppRig rig = await start(tester, items: <String>[c.$1]);
        expect(mic, findsNothing, reason: c.$1);
        expect(rig.speech.prepares, 0);
      });
    }

    testWidgets('a number question ("what comes after two?") has the mic, ready', (
      WidgetTester tester,
    ) async {
      await start(tester, items: <String>['next.after.2']);
      expect(mic, findsOneWidget);
      expect(look(tester), MicLook.ready);
    });
  });
}

List<String> heardLines(AppRig rig) => rig.player.played.map(String.fromCharCodes).toList();

/// The mic in each of its states, on the boards it has to fit.
void goldens() {
  Future<void> shot(WidgetTester t, String name) async {
    await t.pump(const Duration(milliseconds: 200));
    await expectLater(find.byType(MaterialApp), matchesGoldenFile('goldens/$name.png'));
  }

  for (final (String, Size) d in <(String, Size)>[
    ('phone', Size(852, 393)),
    ('tablet_landscape', Size(1180, 820)),
    ('tablet_portrait', Size(820, 1180)),
  ]) {
    testWidgets('mic states on the ${d.$1}', (WidgetTester tester) async {
      final AppRig rig = AppRig(
        voice: true,
        speech: FakeSpeechEngine(<Scripted>[
          Scripted.hangs(),
          Scripted.says('כתום'),
          Scripted.silence(),
          Scripted.silence(),
        ]),
      );
      await rig.seedFinishedSetup();
      await rig.pump(tester, size: d.$2);
      await tester.tap(find.text('נועה'));
      await tester.pumpAndSettle();
      await openActivities(tester, <String>[colourQuestion]);
      await tester.pumpAndSettle();
      await wait(tester, 300);
      await shot(tester, 'voice_mic_ready_${d.$1}');

      await tester.tap(mic); // hangs: listening
      await tester.pump(const Duration(milliseconds: 300));
      await shot(tester, 'voice_mic_listening_${d.$1}');
      // Asking the question again ends the listen; the next tap is a wrong colour: did you say...?
      await tester.tap(find.byKey(const Key('lesson-replay')));
      await wait(tester, 400);
      await tester.tap(mic);
      await wait(tester, 1200);
      await shot(tester, 'voice_mic_confirm_${d.$1}');
      await tester.tap(find.byKey(const Key('confirm-again')));
      await wait(tester, 800);

      await tester.tap(mic);
      await wait(tester, 1200);
      await tester.tap(mic);
      await wait(tester, 1200);
      await shot(tester, 'voice_mic_tap_instead_${d.$1}');
      await wait(tester, 2500);
    });
  }
}
