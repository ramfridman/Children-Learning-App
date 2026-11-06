// The warm-up visit in the lesson controller (M9, a staircase since M10 E0b). The ladder, the staircase and the placement have their own
// tests in `land_placement_test.dart`; here is what the controller does with a flow: it tells the flow whether the answer was right at
// the first try with no help, and it ends the visit kindly after two activities that needed all the help.
import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/content/models.dart';
import 'package:nitznutz/data/app_database.dart';
import 'package:nitznutz/play/lesson_controller.dart';
import 'package:nitznutz/world/land_placement.dart';
import 'package:nitznutz/world/placement.dart';

import 'support/fakes.dart';
import 'support/starter.dart';

/// A flow that tells what the controller said about each answer, and otherwise leaves the staircase alone.
class _Spy implements ItemFlow {
  _Spy(this.inner);

  final ItemFlow inner;
  final List<bool> rights = <bool>[];

  @override
  String first() => inner.first();

  @override
  String? after(String id, {required bool right}) {
    rights.add(right);
    return inner.after(id, right: right);
  }

  @override
  int get length => inner.length;

  @override
  Spoken get thanks => inner.thanks;

  @override
  Spoken get celebration => inner.celebration;
}

void main() {
  late PackContent content;
  setUpAll(() async => content = await loadStarter());

  ({LessonController controller, _Spy flow}) start({List<AttemptRecord>? into}) {
    final ({Lesson lesson, ItemFlow flow}) visit = placementVisit(content, 'numbers', const <Attempt>[])!;
    final _Spy flow = _Spy(visit.flow);
    return (
      controller: LessonController(
        content: content,
        lesson: visit.lesson,
        flow: flow,
        profileId: 'p-1',
        clock: FixedClock(1793000000000),
        record: (AttemptRecord r) async => into?.add(r),
      ),
      flow: flow,
    );
  }

  Future<void> answerWrong(LessonController c) async {
    final Activity a = c.current;
    switch (a) {
      case final ChoiceActivity choice:
        await c.chooseOption(choice.options.firstWhere((ChoiceOption o) => o.id != choice.correctId).id);
      case final GiveNActivity give:
        await c.giveN(give.n == 1 ? 2 : give.n - 1);
      case _:
        await c.submitPlacement(right: false);
    }
  }

  Future<void> answerRight(LessonController c) async {
    final Activity a = c.current;
    switch (a) {
      case final ChoiceActivity choice:
        await c.chooseOption(choice.correctId);
      case final GiveNActivity give:
        await c.giveN(give.n);
      case _:
        await c.submitPlacement(right: true);
    }
  }

  Future<void> struggle(LessonController c) async {
    final Activity a = c.current;
    for (int k = 0; k < a.maxAttempts; k++) {
      await answerWrong(c);
    }
    expect(c.guided, isTrue);
  }

  test('the flow is told "right" only for an answer right at the first try with no help', () async {
    final ({LessonController controller, _Spy flow}) v = start();
    await answerRight(v.controller);
    v.controller.next();
    await answerWrong(v.controller);
    await answerRight(v.controller);
    v.controller.next();
    v.controller.showHint();
    await answerRight(v.controller);
    v.controller.next();
    expect(v.flow.rights, <bool>[true, false, false]);
  });

  test(
    'the warm-up ends kindly after two activities that needed all the help, and goes on after one',
    () async {
      final ({LessonController controller, _Spy flow}) two = start();
      await struggle(two.controller);
      two.controller.next();
      expect(two.controller.finished, isFalse, reason: 'one struggle does not end it');
      await struggle(two.controller);
      two.controller.next();
      expect(two.controller.finished, isTrue);
      expect(two.controller.bubble, two.flow.celebration.caption);

      final ({LessonController controller, _Spy flow}) mixed = start();
      await struggle(mixed.controller);
      mixed.controller.next();
      await answerRight(mixed.controller);
      mixed.controller.next();
      await struggle(mixed.controller);
      mixed.controller.next();
      expect(mixed.controller.finished, isFalse, reason: 'the struggles were not in a row');
    },
  );

  test('every answer of the visit is written against the warm-up, not against a lesson', () async {
    final List<AttemptRecord> written = <AttemptRecord>[];
    final ({LessonController controller, _Spy flow}) v = start(into: written);
    await answerRight(v.controller);
    v.controller.next();
    await answerWrong(v.controller);
    expect(written.map((AttemptRecord r) => r.lessonId).toSet(), <String>{placementId});
  });
}
