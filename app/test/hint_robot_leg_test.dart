import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/child/activity_shell.dart';
import 'package:nitznutz/content/models.dart';
import 'package:nitznutz/design/components.dart';
import 'package:nitznutz/play/hint_hand.dart';
import 'package:nitznutz/play/lesson_controller.dart';
import 'package:nitznutz/play/robot_path_session.dart';

import 'support/fakes.dart';
import 'support/harness.dart';
import 'support/starter.dart';

/// B-40, the robot at level 2 in plan mode. The skill CS-B-01 (b.csb01.1, .3, .5, .7) shows the first leg of the stored way: from
/// the start square, or from the end of the child's plan when the plan is the way's beginning, the next run of arrows in one
/// direction, one numbered footprint on each square, the ghost robot on the last footprint and the run's arrow lit. The run ends at
/// the first turn and is at most half the steps (rounded down, one at least). Every other robot item keeps the ghost of one step,
/// which in plan mode stands one step on from the end of the plan.
void main() {
  late PackContent content;
  setUpAll(() async {
    await loadAppFonts();
    content = await loadStarter();
  });

  const ActivitySpec spec = ActivitySpec.phone;

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

  Future<void> host(WidgetTester tester, RobotPathSession s) async {
    await tester.pumpWidget(
      MaterialApp(
        builder: (BuildContext context, Widget? child) =>
            MediaQuery(data: MediaQuery.of(context).copyWith(disableAnimations: true), child: child!),
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            body: Builder(
              builder: (BuildContext ctx) => Stack(
                clipBehavior: Clip.none,
                children: <Widget>[
                  Positioned(
                    left: spec.stage.left,
                    top: spec.stage.top,
                    width: spec.stage.width,
                    height: spec.stage.height,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: <Widget>[
                        Positioned.fill(child: s.buildStage(ctx, spec.stage.size, spec)),
                        Positioned.fill(child: s.buildHands(ctx, spec.stage.size, spec)!),
                      ],
                    ),
                  ),
                  Positioned(
                    left: spec.tilesLeft,
                    top: spec.tilesTop - 12,
                    width: spec.tilesWidth,
                    child: s.buildTiles(ctx, spec)!,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));
  }

  Future<void> pass(WidgetTester t, int ms) async {
    for (int spent = 0; spent < ms; spent += 100) {
      await t.pump(const Duration(milliseconds: 100));
    }
  }

  /// The child plans [plan], then asks for the first level (it plays 12 s) and the second one (it plays 500 ms).
  Future<RobotPathSession> levelTwo(WidgetTester t, String id, List<String> plan) async {
    await t.runAsync(warmHintHands);
    final RobotPathActivity a = content.activities[id]! as RobotPathActivity;
    final LessonController c = controllerFor(a);
    final RobotPathSession s = RobotPathSession(c, a);
    await host(t, s);
    for (final String d in plan) {
      await s.arrow(d);
    }
    await t.pump(const Duration(milliseconds: 100));
    c.showHint();
    await t.pump(const Duration(milliseconds: 1));
    await pass(t, 12000);
    c.showHint();
    await t.pump(const Duration(milliseconds: 1));
    await pass(t, 500);
    return s;
  }

  /// The number badge [n] of the hint, on the board.
  Finder badge(int n) => find.ancestor(of: find.text('$n'), matching: find.byKey(const Key('hint-badge')));

  /// Where footprint [n] of the square [p] stands on the board.
  Offset footprintAt(RobotPathActivity a, (int, int) p) {
    final double side = RobotPathSession.cellSide(spec.stage.size, a.cols, a.rows);
    return spec.stage.topLeft +
        RobotPathSession.cellCentre(spec.stage.size, a.cols, a.rows, p) +
        Offset(side * 0.26, side * 0.26);
  }

  /// A level 2 that must show [squares] with the footprints [first], [first] + 1, ..., the ghost on the last of them and [lit] lit.
  Future<void> expectLeg(
    WidgetTester t,
    String id,
    List<String> plan,
    List<(int, int)> squares, {
    required int first,
    required String lit,
  }) async {
    final RobotPathActivity a = content.activities[id]! as RobotPathActivity;
    final RobotPathSession s = await levelTwo(t, id, plan);
    final String why = '$id after $plan';
    expect(s.ghost, squares.last, reason: '$why: the ghost stands on the last footprint');
    expect(s.hintStep, lit, reason: '$why: the arrow of the run is lit');
    expect(find.byKey(const Key('hint-badge')), findsNWidgets(squares.length), reason: why);
    for (int i = 0; i < squares.length; i++) {
      expect(badge(first + i), findsOneWidget, reason: '$why: footprint ${first + i}');
      expect(
        (t.getCenter(badge(first + i)) - footprintAt(a, squares[i])).distance,
        lessThan(0.6),
        reason: '$why: footprint ${first + i} is on ${squares[i]}',
      );
    }
    final Rect ghost = t.getRect(find.byKey(const Key('robot-ghost')));
    final Offset cell =
        spec.stage.topLeft + RobotPathSession.cellCentre(spec.stage.size, a.cols, a.rows, squares.last);
    expect(
      (ghost.center - cell).distance,
      lessThan(0.6),
      reason: '$why: the ghost is drawn on the last square',
    );
    expect(find.byKey(const Key('hint-p12')), findsNothing, reason: 'no hand before level 3');
    s.dispose();
    await t.pumpWidget(const SizedBox());
  }

  group('CS-B-01 in plan mode: the first leg of the way', () {
    // b.csb01.1: 4 by 4, the robot at (0, 3), up up right right up. Half of 5 steps is 2.
    testWidgets('b.csb01.1: up, up from the start; one up after one planned; right, right after two', (
      WidgetTester t,
    ) async {
      await expectLeg(t, 'b.csb01.1', <String>[], <(int, int)>[(0, 2), (0, 1)], first: 1, lit: 'up');
      await expectLeg(t, 'b.csb01.1', <String>['up'], <(int, int)>[(0, 1)], first: 2, lit: 'up');
      await expectLeg(
        t,
        'b.csb01.1',
        <String>['up', 'up'],
        <(int, int)>[(1, 1), (2, 1)],
        first: 3,
        lit: 'right',
      );
    });

    // b.csb01.3: 5 by 3, the robot at (0, 2), right right up right right up. Half of 6 is 3.
    testWidgets(
      'b.csb01.3: right, right from the start; one up after two planned; right, right after three',
      (WidgetTester t) async {
        await expectLeg(t, 'b.csb01.3', <String>[], <(int, int)>[(1, 2), (2, 2)], first: 1, lit: 'right');
        await expectLeg(
          t,
          'b.csb01.3',
          <String>['right', 'right'],
          <(int, int)>[(2, 1)],
          first: 3,
          lit: 'up',
        );
        await expectLeg(
          t,
          'b.csb01.3',
          <String>['right', 'right', 'up'],
          <(int, int)>[(3, 1), (4, 1)],
          first: 4,
          lit: 'right',
        );
      },
    );

    // b.csb01.5: 5 by 4, the robot at (4, 3), left left up up left up. Half of 6 is 3.
    testWidgets('b.csb01.5: left, left from the start; up, up after two planned; one left after four', (
      WidgetTester t,
    ) async {
      await expectLeg(t, 'b.csb01.5', <String>[], <(int, int)>[(3, 3), (2, 3)], first: 1, lit: 'left');
      await expectLeg(
        t,
        'b.csb01.5',
        <String>['left', 'left'],
        <(int, int)>[(2, 2), (2, 1)],
        first: 3,
        lit: 'up',
      );
      await expectLeg(
        t,
        'b.csb01.5',
        <String>['left', 'left', 'up', 'up'],
        <(int, int)>[(1, 1)],
        first: 5,
        lit: 'left',
      );
    });

    // b.csb01.7: 5 by 4, the robot at (0, 3), right up right up right up: every run is one step.
    testWidgets('b.csb01.7: one step each time, from the start or from the end of the plan', (
      WidgetTester t,
    ) async {
      await expectLeg(t, 'b.csb01.7', <String>[], <(int, int)>[(1, 3)], first: 1, lit: 'right');
      await expectLeg(t, 'b.csb01.7', <String>['right'], <(int, int)>[(1, 2)], first: 2, lit: 'up');
      await expectLeg(t, 'b.csb01.7', <String>['right', 'up'], <(int, int)>[(2, 2)], first: 3, lit: 'right');
    });

    testWidgets(
      "a plan that is not the way's beginning: the undo button is lit, with no footprints and no ghost",
      (WidgetTester t) async {
        for (final (String id, List<String> plan) in <(String, List<String>)>[
          ('b.csb01.1', <String>['right']),
          ('b.csb01.5', <String>['left', 'up']),
          ('cs.robot.plan.2', <String>['down']),
        ]) {
          final RobotPathSession s = await levelTwo(t, id, plan);
          expect(s.hintStep, 'undo', reason: '$id after $plan');
          expect(s.ghost, isNull, reason: id);
          expect(find.byKey(const Key('hint-badge')), findsNothing, reason: id);
          expect(find.byKey(const Key('robot-ghost')), findsNothing, reason: id);
          expect(
            t.widget<AnswerTile>(find.byKey(const Key('robot-undo'))).state,
            AnswerState.selected,
            reason: '$id: the undo tile is lit',
          );
          for (final String d in RobotPathSession.arrowOrder) {
            expect(
              t.widget<AnswerTile>(find.byKey(Key('arrow-$d'))).state,
              AnswerState.idle,
              reason: '$id $d',
            );
          }
          // It stays lit until what is left of the plan is the way's beginning.
          final RobotPathActivity a = content.activities[id]! as RobotPathActivity;
          while (s.hintStep == 'undo') {
            expect(s.program, isNotEmpty, reason: id);
            s.undo();
            await t.pump(const Duration(milliseconds: 100));
          }
          expect(
            s.program,
            a.solution.take(s.program.length).toList(),
            reason: '$id: what is left is the start of the way',
          );
          expect(t.widget<AnswerTile>(find.byKey(const Key('robot-undo'))).state, AnswerState.idle);
          s.dispose();
          await t.pumpWidget(const SizedBox());
        }
      },
    );

    testWidgets('the undo button stays lit until the plan is the way\'s beginning again', (
      WidgetTester t,
    ) async {
      // up, right, up: the second step is wrong. After one undo it is still wrong; after two the plan is [up], the way's beginning.
      final RobotPathSession s = await levelTwo(t, 'b.csb01.1', <String>['up', 'right', 'up']);
      expect(s.hintStep, 'undo');
      s.undo();
      await t.pump(const Duration(milliseconds: 100));
      expect(s.hintStep, 'undo');
      s.undo();
      await t.pump(const Duration(milliseconds: 100));
      expect(s.hintStep, isNull);
      s.dispose();
      await t.pumpWidget(const SizedBox());
    });

    testWidgets('a run is never longer than half the steps, whatever the way is', (WidgetTester t) async {
      for (final String id in <String>['b.csb01.1', 'b.csb01.3', 'b.csb01.5', 'b.csb01.7']) {
        final RobotPathActivity a = content.activities[id]! as RobotPathActivity;
        final int most = a.solution.length ~/ 2;
        for (int done = 0; done < a.solution.length; done++) {
          final RobotPathSession s = await levelTwo(t, id, a.solution.sublist(0, done));
          final int shown = find.byKey(const Key('hint-badge')).evaluate().length;
          expect(shown, inInclusiveRange(1, most), reason: '$id after $done steps');
          expect(s.hintStep, a.solution[done], reason: '$id after $done steps: the next arrow is lit');
          s.dispose();
          await t.pumpWidget(const SizedBox());
        }
      }
    });

    testWidgets('a plan that is the whole way leaves nothing to show', (WidgetTester t) async {
      final RobotPathActivity a = content.activities['b.csb01.1']! as RobotPathActivity;
      final RobotPathSession s = await levelTwo(t, a.id, a.solution);
      expect(s.ghost, isNull);
      expect(s.hintStep, isNull);
      expect(find.byKey(const Key('hint-badge')), findsNothing);
      expect(find.byKey(const Key('robot-ghost')), findsNothing);
      s.dispose();
      await t.pumpWidget(const SizedBox());
    });

    testWidgets('level 3 is unchanged: its footprints land on the squares of the leg', (
      WidgetTester t,
    ) async {
      await t.runAsync(warmHintHands);
      final RobotPathActivity a = content.activities['b.csb01.1']! as RobotPathActivity;
      final LessonController c = controllerFor(a);
      final RobotPathSession s = RobotPathSession(c, a);
      await host(t, s);
      for (int i = 0; i < 2; i++) {
        c.showHint();
        await t.pump(const Duration(milliseconds: 1));
        await pass(t, 12000);
      }
      c.showHint();
      await t.pump(const Duration(milliseconds: 1));
      await pass(t, 600 * a.solution.length + 300);
      final int n = find.byKey(const Key('hint-badge')).evaluate().length;
      expect(n, a.solution.length);
      final List<Offset> centres = <Offset>[
        for (int i = 0; i < n; i++) t.getCenter(find.byKey(const Key('hint-badge')).at(i)),
      ];
      for (final (int, int) p in <(int, int)>[(0, 2), (0, 1)]) {
        expect(
          centres.any((Offset o) => (o - footprintAt(a, p)).distance < 0.6),
          isTrue,
          reason: 'a footprint of level 3 stands on $p, a square of the leg',
        );
      }
      s.dispose();
      await t.pumpWidget(const SizedBox());
    });
  });

  group('the other robot items keep the ghost of one step', () {
    testWidgets('direct mode of CS-B-01: one step from where the robot stands, footprint 1', (
      WidgetTester t,
    ) async {
      // b.csb01.2: the robot at (3, 3), the flag at (0, 1): the first step is left.
      final RobotPathActivity a = content.activities['b.csb01.2']! as RobotPathActivity;
      final RobotPathSession s = await levelTwo(t, a.id, <String>[]);
      expect(s.ghost, (2, 3));
      expect(s.hintStep, 'left');
      expect(find.byKey(const Key('hint-badge')), findsOneWidget);
      expect(badge(1), findsOneWidget);
      s.dispose();
      await t.pumpWidget(const SizedBox());
    });

    testWidgets('direct mode: after the robot has moved, the ghost is one step on from there', (
      WidgetTester t,
    ) async {
      final RobotPathActivity a = content.activities['b.csb01.2']! as RobotPathActivity;
      final RobotPathSession s = await levelTwo(t, a.id, <String>['left']);
      expect(s.pos, (2, 3));
      expect(s.ghost, (1, 3));
      s.dispose();
      await t.pumpWidget(const SizedBox());
    });

    testWidgets(
      'another skill in plan mode: the ghost stands one step on from the END of the plan (the bug)',
      (WidgetTester t) async {
        // cs.robot.plan.2 (CS-A-04): the robot at (0, 0), right right down. After one right the ghost is at (2, 0), not at (1, 0).
        final RobotPathActivity a = content.activities['cs.robot.plan.2']! as RobotPathActivity;
        expect(a.skillId, isNot('CS-B-01'));
        final RobotPathSession none = await levelTwo(t, a.id, <String>[]);
        expect(none.ghost, (1, 0));
        expect(badge(1), findsOneWidget);
        none.dispose();
        await t.pumpWidget(const SizedBox());
        final RobotPathSession s = await levelTwo(t, a.id, <String>['right']);
        expect(s.ghost, (2, 0), reason: 'one step on from the end of the plan');
        expect(s.hintStep, 'right');
        expect(find.byKey(const Key('hint-badge')), findsOneWidget, reason: 'one step, one footprint');
        expect(badge(2), findsOneWidget, reason: 'it is the second step of the way');
        final Rect ghost = t.getRect(find.byKey(const Key('robot-ghost')));
        final double cell = RobotPathSession.cellSide(spec.stage.size, a.cols, a.rows);
        final Offset want =
            spec.stage.topLeft + RobotPathSession.cellCentre(spec.stage.size, a.cols, a.rows, (2, 0));
        expect((ghost.center - want).distance, lessThan(0.6), reason: 'drawn on the square, cell $cell');
        s.dispose();
        await t.pumpWidget(const SizedBox());
        final RobotPathSession two = await levelTwo(t, a.id, <String>['right', 'right']);
        expect(two.ghost, (2, 1));
        expect(two.hintStep, 'down');
        two.dispose();
        await t.pumpWidget(const SizedBox());
      },
    );
  });

  group('the plan row', () {
    testWidgets(
      'in the right-to-left app the first step is the leftmost and every arrow points its own way',
      (WidgetTester t) async {
        await t.runAsync(warmHintHands);
        final RobotPathActivity a = content.activities['b.csb01.1']! as RobotPathActivity;
        final RobotPathSession s = RobotPathSession(controllerFor(a), a);
        await host(t, s);
        expect(
          Directionality.of(t.element(find.byType(Scaffold))),
          TextDirection.rtl,
          reason: 'the app is right to left',
        );
        for (final String d in <String>['up', 'left', 'down', 'right']) {
          await s.arrow(d);
        }
        await t.pump(const Duration(milliseconds: 100));
        final Finder row = find.descendant(
          of: find.byKey(const Key('robot-program')),
          matching: find.byType(Icon),
        );
        expect(
          <IconData?>[for (int i = 0; i < 4; i++) t.widget<Icon>(row.at(i)).icon],
          <IconData>[
            Icons.arrow_upward_rounded,
            Icons.arrow_back_rounded,
            Icons.arrow_downward_rounded,
            Icons.arrow_forward_rounded,
          ],
        );
        final List<double> xs = <double>[for (int i = 0; i < 4; i++) t.getCenter(row.at(i)).dx];
        expect(xs, orderedEquals(<double>[...xs]..sort()), reason: 'the first step is at the left');
        for (int i = 0; i < 4; i++) {
          expect(
            Directionality.of(t.element(row.at(i))),
            TextDirection.ltr,
            reason: 'step $i is drawn left to right, so the back arrow points left',
          );
        }
        s.dispose();
        await t.pumpWidget(const SizedBox());
      },
    );
  });
}
