import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/content/models.dart';
import 'package:nitznutz/play/lesson_controller.dart';

import 'support/fakes.dart';
import 'support/starter.dart';

void main() {
  late PackContent content;
  late List<AttemptRecord> written;
  late FixedClock clock;

  setUpAll(() async => content = await loadStarter());

  LessonController make({int start = 0}) {
    written = <AttemptRecord>[];
    clock = FixedClock(1793000000000);
    final LessonController c = LessonController(
      content: content,
      lesson: content.lessons['butterflies']!,
      profileId: 'p-1',
      clock: clock,
      record: (AttemptRecord r) async => written.add(r),
    );
    for (int i = 0; i < start; i++) {
      c.next();
    }
    return c;
  }

  test('the lesson starts on the warm-up with its question in the bubble', () {
    final LessonController c = make();
    expect(c.items.map((Activity a) => a.id), <String>[
      'pick.red.flower',
      'count.butterflies.3',
      'count.butterflies.4',
      'count.butterflies.5',
      'give.butterflies.4',
    ]);
    expect(c.index, 0);
    expect(c.bubble, c.current.promptLine.caption);
    expect(c.feedback, FeedbackKind.none);
    expect(c.finished, isFalse);
  });

  group('a right answer', () {
    test('is written with everything the engine will need, and praised', () async {
      final LessonController c = make(start: 1); // count 3
      clock.now += 4200;
      final Outcome o = await c.chooseOption('o2');
      expect(o.correct, isTrue);
      expect(c.feedback, FeedbackKind.correct);
      expect(c.bubble, (c.current as CountTapActivity).feedback.correct.caption);
      final AttemptRecord r = written.single;
      expect(r.profileId, 'p-1');
      expect(r.packId, 'starter');
      expect(r.packVersion, '0.10.0');
      expect(r.lessonId, 'butterflies');
      expect(r.activityId, 'count.butterflies.3');
      expect(r.activityRevision, 1);
      expect(r.template, 'count_tap');
      expect(r.templateVersion, '1.0');
      expect(r.skillId, 'NUM-A-03');
      expect(r.result, 'correct');
      expect(r.attemptNo, 1);
      expect(r.hintLevel, 0);
      expect(r.misconceptionTag, '');
      expect(r.response, 'o2');
      expect(r.durationMs, 4200);
    });

    test(
      'during the praise the lamp and "not sure" do nothing: the praise stays, nothing is written (QA-5)',
      () async {
        final LessonController c = make(start: 1);
        await c.chooseOption('o2');
        final String praise = c.bubble;
        final int moves = c.actionNonce;
        c.showHint();
        await c.unsure();
        expect(written.map((AttemptRecord r) => r.result), <String>['correct']);
        expect(c.bubble, praise);
        expect(c.hintLevel, 0);
        expect(c.actionNonce, moves, reason: 'not a move: a praise line waiting to be said is not dropped');
        c.next();
        c.showHint();
        expect(c.hintLevel, 1, reason: 'the next activity takes help again');
      },
    );

    test('moves on, and after the fifth activity the lesson ends with the celebration', () async {
      final LessonController c = make();
      for (int i = 0; i < 4; i++) {
        c.next();
      }
      expect(c.current.id, 'give.butterflies.4');
      expect((await c.giveN(4)).correct, isTrue);
      c.next();
      expect(c.finished, isTrue);
      expect(c.bubble, content.lessons['butterflies']!.celebration.caption);
    });
  });

  group('wrong answers carry the misconception of the tapped distractor', () {
    test('n+1 is M-CNT-DOUBLE with its own line', () async {
      final LessonController c = make(start: 1);
      final Outcome o = await c.chooseOption('o3');
      expect(o.correct, isFalse);
      expect(o.tag, 'M-CNT-DOUBLE');
      expect(c.feedback, FeedbackKind.notYet);
      expect(c.bubble, c.current.feedback.forIncorrect('M-CNT-DOUBLE').caption);
      expect(c.bubble, contains('פַּעֲמַיִם'));
      expect(written.single.result, 'incorrect');
      expect(written.single.misconceptionTag, 'M-CNT-DOUBLE');
      expect(written.single.response, 'o3');
    });

    test('n-1 is M-CNT-SKIP with its own line', () async {
      final LessonController c = make(start: 2);
      final Outcome o = await c.chooseOption('o1');
      expect(o.tag, 'M-CNT-SKIP');
      expect(c.bubble, c.current.feedback.forIncorrect('M-CNT-SKIP').caption);
      expect(c.bubble, contains('פִּסְפַּסְנוּ'));
    });

    test('a wrong answer with no tag gets the default line', () async {
      final LessonController c = make(); // red flower: yellow is not a tagged distractor
      final Outcome o = await c.chooseOption('o2');
      expect(o.tag, '');
      expect(c.bubble, c.current.feedback.forIncorrect(null).caption);
      expect(written.single.misconceptionTag, '');
    });

    test('giving all seven is M-CNT-CARD; other wrong numbers are plain not-yets', () async {
      final LessonController c = make(start: 4);
      final Outcome all = await c.giveN(7);
      expect(all.tag, 'M-CNT-CARD');
      expect(c.bubble, c.current.feedback.forIncorrect('M-CNT-CARD').caption);
      final Outcome some = await c.giveN(5);
      expect(some.tag, '');
      expect(written.map((AttemptRecord r) => r.response), <String>['n=7', 'n=5']);
      expect(written.map((AttemptRecord r) => r.misconceptionTag), <String>['M-CNT-CARD', '']);
    });

    test('evidence from the count (the same butterfly touched twice) travels with the answer', () async {
      final LessonController c = make(start: 1);
      expect(
        (await c.chooseOption('o2', traceTag: 'M-CNT-DOUBLE')).tag,
        'M-CNT-DOUBLE',
      ); // right, but counted one twice
      final LessonController d = make(start: 1);
      expect(
        (await d.chooseOption('o1', traceTag: 'M-CNT-DOUBLE')).tag,
        'M-CNT-SKIP',
      ); // the chosen distractor wins
      final LessonController e = make();
      expect(
        (await e.chooseOption('o2', traceTag: 'M-CNT-DOUBLE')).tag,
        'M-CNT-DOUBLE',
      ); // untagged distractor: the trace is kept
    });
  });

  group('help escalates and always ends in success', () {
    test(
      'three mistakes: a line, then fingers, then the worked example and the turn is handed back',
      () async {
        final LessonController c = make(start: 1);
        await c.chooseOption('o3');
        expect(c.errors, 1);
        // The first mistake: the diagnostic line, and the picture of hint 1 with it (B-40, A6). The hint's own line is not said.
        expect(c.hintLevel, 1);
        expect(c.hintShown, 1);
        expect(c.hintAction, HintAction.replayPromptSlow);
        expect(c.bubble, isNot(c.current.hints[0].say.caption));
        expect(c.guided, isFalse);

        await c.chooseOption('o1');
        expect(c.errors, 2);
        expect(c.hintLevel, 2);
        expect(c.hintAction, HintAction.showFingers);
        expect(c.bubble, c.current.hints[1].say.caption);
        expect(c.guided, isFalse);

        await c.chooseOption('o3');
        expect(c.errors, 3);
        expect(c.hintLevel, 3);
        expect(c.hintAction, HintAction.workedExample);
        expect(c.bubble, c.current.hints[2].say.caption);
        expect(c.guided, isTrue);
        // The halo on the right answer waits for the end of the worked example.
        expect(c.answerShown, isFalse);
        c.demoDone();
        expect(c.answerShown, isTrue);

        final Outcome last = await c.chooseOption('o2');
        expect(last.correct, isTrue);
        expect(written.map((AttemptRecord r) => r.result), <String>[
          'incorrect',
          'incorrect',
          'incorrect',
          'correct',
        ]);
        expect(written.map((AttemptRecord r) => r.attemptNo), <int>[1, 2, 3, 4]);
        expect(written.map((AttemptRecord r) => r.hintLevel), <int>[0, 1, 2, 3]);
      },
    );

    test('a two-choice item allows one retry, then the model is shown', () async {
      final LessonController c = make(); // maxAttempts 2, one hint
      await c.chooseOption('o2');
      expect(c.guided, isFalse);
      await c.chooseOption('o2');
      expect(c.guided, isTrue);
      expect(c.hintLevel, 1);
      expect(c.bubble, c.current.hints.single.say.caption);
    });

    test(
      'a two-choice item with three hints: the first mistake shows hint 2, the second the worked example',
      () async {
        final TapAnswerActivity two = content.activities.values.whereType<TapAnswerActivity>().firstWhere(
          (TapAnswerActivity a) => a.options.length == 2 && a.hints.length == 3,
        );
        final Lesson lesson = Lesson.mission(
          id: 'one-two',
          itemIds: <String>[two.id],
          skillIds: <String>[two.skillId],
          celebration: content.lessons['butterflies']!.celebration,
        );
        written = <AttemptRecord>[];
        final LessonController c = LessonController(
          content: content,
          lesson: lesson,
          profileId: 'p-1',
          clock: FixedClock(1793000000000),
          record: (AttemptRecord r) async => written.add(r),
        );
        final String wrong = two.options.firstWhere((ChoiceOption o) => o.id != two.correctId).id;
        await c.chooseOption(wrong);
        expect(c.hintShown, 2, reason: 'one retry: the other way of seeing it comes at once');
        expect(c.guided, isFalse);
        await c.chooseOption(wrong);
        expect(c.hintShown, 3);
        expect(c.guided, isTrue, reason: 'then the worked example');
        expect(c.answerShown, isFalse);
      },
    );

    test('a three-choice item keeps the ladder: hint 1, hint 2, then the worked example', () async {
      final TapAnswerActivity three = content.activities.values.whereType<TapAnswerActivity>().firstWhere(
        (TapAnswerActivity a) => a.options.length == 3 && a.hints.length == 3,
      );
      final Lesson lesson = Lesson.mission(
        id: 'one-three',
        itemIds: <String>[three.id],
        skillIds: <String>[three.skillId],
        celebration: content.lessons['butterflies']!.celebration,
      );
      final LessonController c = LessonController(
        content: content,
        lesson: lesson,
        profileId: 'p-1',
        clock: FixedClock(1793000000000),
        record: (AttemptRecord r) async {},
      );
      final List<String> wrongs = <String>[
        for (final ChoiceOption o in three.options)
          if (o.id != three.correctId) o.id,
      ];
      final List<int> shown = <int>[];
      for (final String w in wrongs) {
        await c.chooseOption(w);
        shown.add(c.hintShown);
      }
      expect(shown, <int>[1, 2]);
      expect(c.guided, isFalse);
      await c.chooseOption(wrongs.first);
      expect(c.hintShown, 3);
      expect(c.guided, isTrue);
    });

    test(
      'with fewer than three hints there is no worked example to wait for: the halo may show at once',
      () async {
        final LessonController c = make(); // the warm-up has one hint
        await c.chooseOption('o2');
        await c.chooseOption('o2');
        expect(c.guided, isTrue);
        expect(c.answerShown, isTrue);
      },
    );

    test('the lamp gives the next hint each time and stops at the last', () {
      final LessonController c = make(start: 1);
      final List<int> shown = <int>[];
      for (int i = 0; i < 5; i++) {
        c.showHint();
        shown.add(c.hintLevel);
      }
      expect(shown, <int>[1, 2, 3, 3, 3]);
      expect(c.hintAction, HintAction.workedExample);
      expect(written, isEmpty); // asking for help writes nothing and costs nothing
    });

    test('each hint changes the support: the three actions are different', () {
      final LessonController c = make(start: 1);
      final List<HintAction> actions = <HintAction>[];
      for (int i = 0; i < 3; i++) {
        c.showHint();
        actions.add(c.hintAction!);
      }
      expect(actions, <HintAction>[
        HintAction.replayPromptSlow,
        HintAction.showFingers,
        HintAction.workedExample,
      ]);
      expect(actions.toSet(), hasLength(3));
    });

    test('"not sure" is recorded as unsure, is not a mistake, and is welcomed with help', () async {
      final LessonController c = make(start: 1);
      await c.unsure();
      expect(written.single.result, 'unsure');
      expect(written.single.misconceptionTag, '');
      expect(c.errors, 0);
      expect(c.feedback, FeedbackKind.none);
      expect(c.bubble, c.current.feedback.unsure.caption);
      expect(c.hintLevel, 1);
      expect(c.guided, isFalse);
      await c.unsure();
      await c.unsure();
      await c.unsure();
      expect(c.hintLevel, 3);
      expect(c.errors, 0);
    });

    test('replaying the question shows it again without any help', () {
      final LessonController c = make(start: 1);
      c.showHint();
      final int before = c.replayNonce;
      c.replayPrompt();
      expect(c.bubble, c.current.promptLine.caption);
      expect(c.replayNonce, before + 1);
      expect(c.hintLevel, 1); // what was shown stays counted
    });

    test('a new activity starts clean', () async {
      final LessonController c = make(start: 1);
      await c.chooseOption('o3');
      await c.chooseOption('o3');
      c.next();
      expect(c.errors, 0);
      expect(c.hintLevel, 0);
      expect(c.attemptNo, 1);
      expect(c.guided, isFalse);
      expect(c.bubble, c.current.promptLine.caption);
    });
  });

  test('the controller never writes a name, only ids, numbers and fixed words', () async {
    final LessonController c = make(start: 1);
    await c.chooseOption('o3');
    await c.chooseOption('o2');
    final AttemptRecord r = written.first;
    for (final String value in <String>[
      r.profileId,
      r.packId,
      r.activityId,
      r.result,
      r.misconceptionTag,
      r.response,
    ]) {
      expect(value, matches(RegExp(r'^[A-Za-z0-9._=:-]*$')), reason: value);
    }
  });
}
