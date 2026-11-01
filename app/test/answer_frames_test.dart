import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/child/activity_shell.dart';
import 'package:nitznutz/content/models.dart';
import 'package:nitznutz/play/lesson_controller.dart';
import 'package:nitznutz/play/sprite_group.dart';
import 'package:nitznutz/play/tap_answer_session.dart';

import 'support/fakes.dart';
import 'support/harness.dart';
import 'support/starter.dart';

/// QA-38-1: a ten-frame board on one answer and not on its neighbour tells the child which one to pick ("the one with the box").
/// Within one activity the answers are all drawn with a board or none is; the stage's own group keeps its board, and when two groups
/// stand on the stage (3 + 2) both are framed or neither.
void main() {
  late PackContent content;
  setUpAll(() async {
    await loadAppFonts();
    content = await loadStarter();
  });

  const ActivitySpec spec = ActivitySpec.phone;

  List<TapAnswerActivity> tapAnswers() => content.activities.values.whereType<TapAnswerActivity>().toList();

  bool couldFrame(SpriteSet g) => drawsTenFrame(g.arrangement, g.count);

  LessonController controllerFor(Activity a) => LessonController(
    content: content,
    lesson: Lesson.mission(
      id: 'one',
      itemIds: <String>[a.id],
      skillIds: <String>[a.skillId],
      celebration: content.lessons.values.first.celebration,
    ),
    profileId: 'p-1',
    clock: FixedClock(1793000000000),
    record: (AttemptRecord r) async {},
  );

  test('the pack has answers that could carry a board (so the sweep below is not empty)', () {
    final List<String> ids = <String>[
      for (final TapAnswerActivity a in tapAnswers())
        if (a.options.any((ChoiceOption o) => o.set != null && couldFrame(o.set!))) a.id,
    ];
    expect(ids, containsAll(<String>['more.spread.fish', 'more.spread.stars']));
  });

  testWidgets('no activity of the pack draws a board on only some of its answer groups', (
    WidgetTester t,
  ) async {
    int swept = 0;
    for (final TapAnswerActivity a in tapAnswers()) {
      final List<ChoiceOption> sets = <ChoiceOption>[
        for (final ChoiceOption o in a.options)
          if (o.set != null) o,
      ];
      if (sets.length < 2 || !sets.any((ChoiceOption o) => couldFrame(o.set!))) continue;
      swept++;
      final TapAnswerSession s = TapAnswerSession(controllerFor(a), a);
      await t.pumpWidget(
        MaterialApp(
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: Scaffold(
              body: Builder(builder: (BuildContext c) => s.buildTiles(c, spec) ?? const SizedBox()),
            ),
          ),
        ),
      );
      final int framed = find.byKey(const Key('group-ten-frame')).evaluate().length;
      expect(
        framed == 0 || framed == sets.length,
        isTrue,
        reason: '${a.id}: $framed of ${sets.length} answers have a board',
      );
      expect(framed, 0, reason: '${a.id}: answers are drawn with no board');
      s.dispose();
    }
    expect(swept, greaterThanOrEqualTo(2));
  });

  test('the group of the question keeps its board, and two groups on the stage are alike', () {
    for (final TapAnswerActivity a in tapAnswers()) {
      if (a.group == null || a.group2 == null) continue;
      expect(
        couldFrame(a.group!),
        couldFrame(a.group2!),
        reason: '${a.id}: one of the two groups would have a board and the other not',
      );
    }
    expect(answerGroupsFramed, isFalse);
  });
}
