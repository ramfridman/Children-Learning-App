import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/content/models.dart';
import 'package:nitznutz/data/app_database.dart';
import 'package:nitznutz/play/lesson_controller.dart';
import 'package:nitznutz/world/placement.dart';

import 'support/fakes.dart';
import 'support/starter.dart';

Attempt _attempt(String lesson, String activity, {String result = 'correct', int no = 1, int hint = 0}) =>
    Attempt(
      id: 1,
      at: DateTime.utc(2026, 10, 28),
      profileId: 'p-1',
      packId: 'starter',
      packVersion: '0.4.0',
      lessonId: lesson,
      activityId: activity,
      activityRevision: 1,
      template: 'tap_answer',
      templateVersion: '1.1',
      skillId: 'NUM-A-01',
      result: result,
      attemptNo: no,
      hintLevel: hint,
      misconceptionTag: '',
      response: 'o1',
      durationMs: 1000,
      sessionId: null,
      input: 'touch',
    );

void main() {
  late PackContent content;
  setUpAll(() async => content = await loadStarter());

  test('the warm-up of Numbers has up to eight activities spread from the first lesson to the last', () {
    final Lesson w = placementLesson(content, 'numbers')!;
    expect(w.id, placementId);
    expect(w.itemIds.length, inInclusiveRange(5, placementItems));
    expect(w.itemIds.toSet().length, w.itemIds.length);
    final List<Lesson> path =
        content.lessons.values
            .where((Lesson l) => l.skillIds.any((String s) => content.skills[s]?.domain == 'numbers'))
            .toList()
          ..sort((Lesson a, Lesson b) => a.sequence.compareTo(b.sequence));
    int lessonOf(String id) => path.indexWhere((Lesson l) => l.itemIds.contains(id));
    final List<int> places = <int>[for (final String id in w.itemIds) lessonOf(id)];
    expect(places.first, lessThanOrEqualTo(1), reason: 'starts near the beginning');
    expect(places.last, greaterThanOrEqualTo(path.length - 3), reason: 'reaches the end of the path');
    expect(<int>[...places]..sort(), places, reason: 'in the order of the path');
    expect(w.stopAfterStruggles, placementStruggles);
  });

  test('a land with fewer than three lessons has no warm-up', () {
    expect(placementLesson(content, 'none'), isNull);
    expect(placementLesson(content, 'none'), isNull);
  });

  test(
    'the warm-up is due once: not after it was played, and not for a child who already played in the land',
    () {
      expect(placementDue(content, 'numbers', const <Attempt>[]), isTrue);
      expect(placementDue(content, 'numbers', <Attempt>[_attempt(placementId, 'next.after.4')]), isFalse);
      expect(
        placementDue(content, 'numbers', <Attempt>[_attempt('butterflies', 'count.butterflies.3')]),
        isFalse,
      );
      expect(placementDue(content, 'none', const <Attempt>[]), isFalse);
    },
  );

  test('only an activity answered right at the first try without help puts its lesson behind the child', () {
    final String item = content.lessons['giving']!.itemIds.first;
    expect(placedLessons(content, <Attempt>[_attempt(placementId, item)]), <String>{'giving'});
    expect(placedLessons(content, <Attempt>[_attempt(placementId, item, no: 2)]), isEmpty);
    expect(placedLessons(content, <Attempt>[_attempt(placementId, item, hint: 1)]), isEmpty);
    expect(placedLessons(content, <Attempt>[_attempt(placementId, item, result: 'incorrect')]), isEmpty);
    expect(
      placedLessons(content, <Attempt>[_attempt('giving', item)]),
      isEmpty,
      reason: 'a lesson played is not a warm-up',
    );
  });

  test(
    'the warm-up ends kindly after two activities that needed all the help, and goes on after one',
    () async {
      final Lesson w = placementLesson(content, 'numbers')!;
      LessonController start() => LessonController(
        content: content,
        lesson: w,
        profileId: 'p-1',
        clock: FixedClock(1793000000000),
        record: (AttemptRecord r) async {},
      );
      Future<void> struggle(LessonController c) async {
        final Activity a = c.current;
        for (int k = 0; k < a.maxAttempts; k++) {
          switch (a) {
            case TapAnswerActivity():
              await c.chooseOption(a.options.firstWhere((ChoiceOption o) => o.id != a.correctId).id);
            case CountTapActivity():
              await c.chooseOption(a.options.firstWhere((ChoiceOption o) => o.id != a.correctId).id);
            case FlashActivity():
              await c.chooseOption(a.options.firstWhere((ChoiceOption o) => o.id != a.correctId).id);
            case GiveNActivity():
              await c.giveN(a.n == 1 ? 2 : a.n - 1);
            case SortDragActivity() ||
                BuildPatternActivity() ||
                RobotPathActivity() ||
                ShapeBuilderActivity() ||
                NumberLineActivity() ||
                BalanceActivity() ||
                SpotErrorActivity() ||
                MatchPairsActivity() ||
                ShopPayActivity() ||
                ClockSetActivity() ||
                TraceActivity():
              await c.submitPlacement(right: false);
          }
        }
        expect(c.guided, isTrue);
      }

      final LessonController two = start();
      await struggle(two);
      two.next();
      expect(two.finished, isFalse, reason: 'one struggle does not end it');
      await struggle(two);
      two.next();
      expect(two.finished, isTrue);
      expect(two.bubble, w.celebration.caption);

      final LessonController mixed = start();
      await struggle(mixed);
      mixed.next();
      final Activity b = mixed.current;
      switch (b) {
        case TapAnswerActivity():
          await mixed.chooseOption(b.correctId);
        case CountTapActivity():
          await mixed.chooseOption(b.correctId);
        case FlashActivity():
          await mixed.chooseOption(b.correctId);
        case GiveNActivity():
          await mixed.giveN(b.n);
        case SortDragActivity() ||
            BuildPatternActivity() ||
            RobotPathActivity() ||
            ShapeBuilderActivity() ||
            NumberLineActivity() ||
            BalanceActivity() ||
            SpotErrorActivity() ||
            MatchPairsActivity() ||
            ShopPayActivity() ||
            ClockSetActivity() ||
            TraceActivity():
          await mixed.submitPlacement(right: true);
      }
      mixed.next();
      await struggle(mixed);
      mixed.next();
      expect(mixed.finished, isFalse, reason: 'the struggles were not in a row');
    },
  );
}
