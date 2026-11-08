// B-29 step 6, items 3, 5 and 9 on the lesson controller: the tutor's live line follows the captions setting (not the band); the choice cap
// reaches the items a lesson plays and the two-choice retry rule reads the options after the cap; the youngest look's first mistake shows
// the second picture and the worked example comes after two tries.
import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/content/models.dart';

import 'package:nitznutz/play/choice_cap.dart';
import 'package:nitznutz/play/lesson_controller.dart';

import 'support/fakes.dart';
import 'support/starter.dart';

void main() {
  late PackContent content;
  setUpAll(() async => content = await loadStarter());

  Lesson one(Activity a) => Lesson.mission(
    id: 'one-${a.id}',
    itemIds: <String>[a.id],
    skillIds: <String>[a.skillId],
    celebration: content.lessons['butterflies']!.celebration,
  );

  LessonController play(Activity a, {bool fastHints = false, int? maxChoices}) => LessonController(
    content: content,
    lesson: one(a),
    profileId: 'p-1',
    clock: FixedClock(1793000000000),
    record: (AttemptRecord r) async {},
    fastHints: fastHints,
    personalise: maxChoices == null ? null : (Activity x) => capChoices(x, maxChoices),
  );

  TapAnswerActivity threeChoice() => content.activities.values.whereType<TapAnswerActivity>().firstWhere(
    (TapAnswerActivity a) => a.options.length == 3 && a.hints.length == 3 && a.numberAnswer == null,
  );

  List<String> wrongs(TapAnswerActivity a) => <String>[
    for (final ChoiceOption o in a.options)
      if (o.id != a.correctId) o.id,
  ];

  group('hint pace by look (D6 and step 6 item 9)', () {
    test('P2 to P4: a three-choice item shows hint 1 at the first mistake, as today', () async {
      final TapAnswerActivity a = threeChoice();
      final LessonController c = play(a);
      await c.chooseOption(wrongs(a).first);
      expect(c.hintShown, 1);
      expect(c.guided, isFalse);
    });

    test(
      'P1: the first mistake already shows the second picture, and the worked example comes after two tries',
      () async {
        final TapAnswerActivity a = threeChoice();
        final LessonController c = play(a, fastHints: true);
        await c.chooseOption(wrongs(a).first);
        expect(c.hintShown, 2);
        expect(c.guided, isFalse, reason: 'one retry');
        await c.chooseOption(wrongs(a).last);
        expect(c.hintShown, 3);
        expect(c.guided, isTrue, reason: 'the worked example after two tries');
      },
    );

    test('a two-choice item behaves as P1 does in every look (one retry, hint 2 first)', () async {
      final TapAnswerActivity two = content.activities.values.whereType<TapAnswerActivity>().firstWhere(
        (TapAnswerActivity a) => a.options.length == 2 && a.hints.length == 3,
      );
      for (final bool fast in <bool>[false, true]) {
        final LessonController c = play(two, fastHints: fast);
        await c.chooseOption(wrongs(two).first);
        expect(c.hintShown, 2, reason: 'fast $fast');
        await c.chooseOption(wrongs(two).first);
        expect(c.guided, isTrue, reason: 'fast $fast');
      }
    });

    test('a right answer is a right answer in every look: no hint, no mistake', () async {
      final TapAnswerActivity a = threeChoice();
      for (final bool fast in <bool>[false, true]) {
        final LessonController c = play(a, fastHints: fast);
        await c.chooseOption(a.correctId);
        expect(c.hintShown, 0);
        expect(c.errors, 0);
      }
    });
  });

  group('the choice cap reaches what a lesson plays', () {
    TapAnswerActivity wide() => content.activities.values.whereType<TapAnswerActivity>().firstWhere(
      (TapAnswerActivity a) => a.options.length > 3 && a.numberAnswer == null && !a.all,
    );

    test('an item of four or more options plays with three under the youngest look, and still has its right answer', () {
      final TapAnswerActivity a = wide();
      final LessonController c = play(a, maxChoices: 3);
      final TapAnswerActivity shown = c.current as TapAnswerActivity;
      expect(shown.options.length, 3);
      expect(shown.options.map((ChoiceOption o) => o.id), contains(a.correctId));
    });

    test('the two-choice retry rule reads the options after the cap', () async {
      // A four-option item capped to two (a cap smaller than any look gives, to reach the rule) plays as a two-choice item.
      final TapAnswerActivity a = wide();
      final LessonController c = play(a, maxChoices: 2);
      expect((c.current as TapAnswerActivity).optionCount, 2);
      final String wrong = (c.current as TapAnswerActivity).options
          .firstWhere((ChoiceOption o) => o.id != a.correctId)
          .id;
      await c.chooseOption(wrong);
      if (a.hints.length >= 2) {
        expect(c.hintShown, 2, reason: 'one retry: the second kind of help comes at once');
      }
    });

    test('with the cap above the options, the item is the one the pack holds', () {
      final TapAnswerActivity a = wide();
      expect(identical(play(a, maxChoices: 9).current, a), isTrue);
    });
  });
}
