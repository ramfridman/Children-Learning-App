import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/child/activity_shell.dart';
import 'package:nitznutz/content/models.dart';
import 'package:nitznutz/design/board.dart';
import 'package:nitznutz/play/lesson_controller.dart';
import 'package:nitznutz/play/hint_hand.dart';
import 'package:nitznutz/play/robot_path_session.dart';

import 'support/fakes.dart';
import 'support/harness.dart';
import 'support/starter.dart';

/// B-38 (the curriculum-expert's decision (a)): on a phone a robot board with four rows has squares of 50 points or more (29 before),
/// because the stage is tall and the arrows stand in a block of 2 by 2 beside it. The tablets keep the board's own numbers.
void main() {
  late PackContent content;
  setUpAll(() async {
    await loadAppFonts();
    content = await loadStarter();
  });

  List<RobotPathActivity> robots() => content.activities.values.whereType<RobotPathActivity>().toList();

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

  /// The room of the stage itself (a tablet's stage sits on a card with a 16 point border).
  Rect room(ActivitySpec spec) => spec.stageIsCard ? spec.stage.deflate(16) : spec.stage;

  Future<void> host(WidgetTester tester, RobotPathSession s, ActivitySpec spec) async {
    await tester.pumpWidget(
      MaterialApp(
        builder: (BuildContext context, Widget? child) =>
            MediaQuery(data: MediaQuery.of(context).copyWith(disableAnimations: true), child: child!),
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            body: Builder(
              builder: (BuildContext ctx) => Stack(
                children: <Widget>[
                  Positioned.fromRect(
                    rect: room(spec),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: <Widget>[
                        Positioned.fill(child: s.buildStage(ctx, room(spec).size, spec)),
                        Positioned.fill(child: s.buildHands(ctx, room(spec).size, spec)!),
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

  final Map<String, (ActivitySpec, Size)> phones = <String, (ActivitySpec, Size)>{
    'phone': (ActivitySpec.phone, BoardClass.phone.size),
    'phoneSE': (ActivitySpec.phoneSE, BoardClass.phoneSE.size),
  };

  test('the pack has 9 boards of four rows: 2 of CS-A-03 and 7 of CS-B-01', () {
    final List<RobotPathActivity> four = robots().where((RobotPathActivity a) => a.rows == 4).toList();
    expect(four, hasLength(9));
    expect(four.where((RobotPathActivity a) => a.skillId == 'CS-A-03'), hasLength(2));
    expect(four.where((RobotPathActivity a) => a.skillId == 'CS-B-01'), hasLength(7));
  });

  group('a square of the grid, as drawn', () {
    for (final MapEntry<String, (ActivitySpec, Size)> board in phones.entries) {
      testWidgets('every board of the pack has squares of at least 50 points on the ${board.key}', (
        WidgetTester t,
      ) async {
        final ActivitySpec spec = RobotPathSession.laidOut(board.value.$1);
        for (final RobotPathActivity a in robots()) {
          final RobotPathSession s = RobotPathSession(controllerFor(a), a);
          await host(t, s, spec);
          final Size robot = t.getSize(find.byKey(const Key('robot')));
          // The robot is drawn 6 points smaller than its square.
          final double cell = robot.width + 6;
          expect(cell, greaterThanOrEqualTo(50), reason: '${a.id} (${a.cols} by ${a.rows})');
          // The plan's steps stand in the stage, under the squares of the grid.
          if (a.plan) {
            final Rect stage = t.getRect(find.byKey(const Key('robot-stage')));
            final Rect steps = t.getRect(find.byKey(const Key('robot-program')));
            expect(stage.contains(steps.topLeft) && stage.contains(steps.bottomRight), isTrue, reason: a.id);
            final double gridBottom = stage.top + (stage.height - 30 - cell * a.rows) / 2 + cell * a.rows;
            expect(
              steps.top,
              greaterThanOrEqualTo(gridBottom - 0.01),
              reason: '${a.id}: the steps are under the grid',
            );
          }
          s.dispose();
          await t.pumpWidget(const SizedBox());
        }
      });
    }

    testWidgets('the small phone was 23 points on a board of four rows; the tablets are as they were', (
      WidgetTester t,
    ) async {
      expect(RobotPathSession.cellSide(ActivitySpec.phoneSE.stage.size, 4, 4), closeTo(23, 0.01));
      expect(RobotPathSession.cellSide(ActivitySpec.phone.stage.size, 4, 4), closeTo(29, 0.01));
      expect(
        identical(RobotPathSession.laidOut(ActivitySpec.tabletLandscape), ActivitySpec.tabletLandscape),
        isTrue,
      );
      expect(
        identical(RobotPathSession.laidOut(ActivitySpec.tabletPortrait), ActivitySpec.tabletPortrait),
        isTrue,
      );
    });
  });

  group('where the stage and the arrows stand on the board', () {
    for (final MapEntry<String, (ActivitySpec, Size)> board in phones.entries) {
      test(
        '${board.key}: the controls are on the board, clear of the stage, the speech bubble, the guide and the microphone',
        () {
          final ActivitySpec base = board.value.$1;
          final ActivitySpec spec = RobotPathSession.laidOut(base);
          final Size boardSize = board.value.$2;
          final Rect controls = Rect.fromLTWH(spec.tilesLeft, spec.tilesTop - 12, spec.tilesWidth, 140);
          expect((Offset.zero & boardSize).contains(controls.topLeft), isTrue);
          expect(controls.right, lessThanOrEqualTo(boardSize.width));
          expect(controls.bottom, lessThanOrEqualTo(boardSize.height));
          expect(spec.stage.bottom, lessThanOrEqualTo(boardSize.height));
          expect(controls.left, greaterThanOrEqualTo(spec.stage.right), reason: 'beside the stage');
          // Under the longest question the bubble can hold.
          expect(controls.top, greaterThanOrEqualTo(base.bubbleTop + base.bubbleMaxHeight));
          final Rect guide = Rect.fromLTWH(base.nitziLeft, base.nitziTop, base.nitziSize, base.nitziSize);
          final Rect mic = Rect.fromLTWH(base.micLeft, base.micTop, base.micSize, base.micSize);
          // The tap margin of a tile is the only part of it that may reach the guide's empty corner; the tiles themselves do not.
          final Rect tiles = controls.deflate(6);
          expect(tiles.overlaps(mic), isFalse, reason: 'the microphone');
          expect(tiles.overlaps(guide), isFalse, reason: 'the guide');
          // The other numbers of the board are the board's own.
          expect(spec.stage.left, base.stage.left);
          expect(spec.stage.top, base.stage.top);
          expect(spec.stage.width, base.stage.width);
          expect(spec.bubbleLeft, base.bubbleLeft);
          expect(spec.micTop, base.micTop);
        },
      );
    }
  });

  group('the arrows', () {
    testWidgets('each arrow of the block moves the robot the way it points, in a right-to-left screen', (
      WidgetTester t,
    ) async {
      final ActivitySpec spec = RobotPathSession.laidOut(ActivitySpec.phone);
      final RobotPathActivity a = content.activities['b.csb01.4']! as RobotPathActivity;
      final RobotPathSession s = RobotPathSession(controllerFor(a), a);
      await host(t, s, spec);
      // b.csb01.4: 4 by 4, the robot at (0, 0).
      expect(s.pos, (0, 0));
      await t.tap(find.byKey(const Key('arrow-right')));
      await t.pump(const Duration(milliseconds: 100));
      expect(s.pos, (1, 0), reason: 'right is right');
      await t.tap(find.byKey(const Key('arrow-down')));
      await t.pump(const Duration(milliseconds: 100));
      expect(s.pos, (1, 1), reason: 'down is down');
      await t.tap(find.byKey(const Key('arrow-left')));
      await t.pump(const Duration(milliseconds: 100));
      expect(s.pos, (0, 1), reason: 'left is left');
      await t.tap(find.byKey(const Key('arrow-up')));
      await t.pump(const Duration(milliseconds: 100));
      expect(s.pos, (0, 0), reason: 'up is up');
      s.dispose();
      await t.pumpWidget(const SizedBox());
    });

    testWidgets(
      'a plan: the arrows add steps to the row under the grid, undo takes one back, go is under undo',
      (WidgetTester t) async {
        final ActivitySpec spec = RobotPathSession.laidOut(ActivitySpec.phone);
        final RobotPathActivity a = content.activities['b.csb01.1']! as RobotPathActivity;
        final RobotPathSession s = RobotPathSession(controllerFor(a), a);
        await host(t, s, spec);
        await t.tap(find.byKey(const Key('arrow-up')));
        await t.tap(find.byKey(const Key('arrow-right')));
        await t.pump(const Duration(milliseconds: 100));
        expect(s.program, <String>['up', 'right']);
        final Rect steps = t.getRect(find.byKey(const Key('robot-program')));
        final Rect grid = t.getRect(find.byKey(const Key('robot-stage')));
        expect(steps.center.dy, greaterThan(grid.center.dy), reason: 'the steps stand under the grid');
        expect(steps.left, greaterThanOrEqualTo(grid.left));
        expect(steps.right, lessThanOrEqualTo(grid.right));
        await t.tap(find.byKey(const Key('robot-undo')));
        await t.pump(const Duration(milliseconds: 100));
        expect(s.program, <String>['up']);
        s.dispose();
        await t.pumpWidget(const SizedBox());
      },
    );
  });
  group('level 3: the pointing hand', () {
    final Map<String, ActivitySpec> boards = <String, ActivitySpec>{
      'phone': ActivitySpec.phone,
      'phoneSE': ActivitySpec.phoneSE,
      'tabletLandscape': ActivitySpec.tabletLandscape,
      'tabletPortrait': ActivitySpec.tabletPortrait,
    };
    final Map<String, Size> sizes = <String, Size>{
      'phone': BoardClass.phone.size,
      'phoneSE': BoardClass.phoneSE.size,
      'tabletLandscape': BoardClass.tabletLandscape.size,
      'tabletPortrait': BoardClass.tabletPortrait.size,
    };

    for (final MapEntry<String, ActivitySpec> board in boards.entries) {
      testWidgets(
        'on the ${board.key}, at every stop of every robot item the hand is on the screen and hides neither the bubble, the robot nor the flag',
        (WidgetTester t) async {
          await t.runAsync(warmHintHands);
          final ActivitySpec spec = RobotPathSession.laidOut(board.value);
          final Size screen = sizes[board.key]!;
          // The room of the longest question: the bubble's whole box.
          final Rect bubble = spec.bubbleLeft != null
              ? Rect.fromLTWH(spec.bubbleLeft!, spec.bubbleTop, spec.bubbleMaxWidth, spec.bubbleMaxHeight)
              : Rect.fromLTRB(
                  screen.width - spec.bubbleRight! - spec.bubbleMaxWidth,
                  spec.bubbleTop,
                  screen.width - spec.bubbleRight!,
                  spec.bubbleTop + spec.bubbleMaxHeight,
                );
          int stops = 0;
          for (final RobotPathActivity a in robots()) {
            final LessonController c = controllerFor(a);
            final RobotPathSession s = RobotPathSession(c, a);
            await host(t, s, spec);
            c.showHint();
            await t.pump(const Duration(seconds: 12));
            c.showHint();
            await t.pump(const Duration(seconds: 12));
            c.showHint();
            await t.pump(const Duration(milliseconds: 1));
            // The worked example: 600 ms for each arrow of the way, a glide of 450 ms between.
            for (int ms = 0; ms < 600 * a.solution.length + 600; ms += 50) {
              await t.pump(const Duration(milliseconds: 50));
              final Finder hand = find.byKey(const Key('hint-p12'));
              if (hand.evaluate().isEmpty) continue;
              stops++;
              final Rect box = t.getRect(hand);
              final String why = '${a.id} at $ms ms, hand $box';
              expect(
                box.left >= 0 && box.top >= 0 && box.right <= screen.width && box.bottom <= screen.height,
                isTrue,
                reason: '$why is not on the screen',
              );
              expect(box.overlaps(bubble), isFalse, reason: '$why covers the bubble $bubble');
              expect(
                box.overlaps(t.getRect(find.byKey(const Key('robot')))),
                isFalse,
                reason: '$why covers the robot',
              );
              expect(
                box.overlaps(t.getRect(find.byKey(const Key('robot-goal')))),
                isFalse,
                reason: '$why covers the flag',
              );
            }
            s.dispose();
            await t.pumpWidget(const SizedBox());
          }
          expect(stops, greaterThan(robots().length * 10), reason: 'the hand was shown at every item');
        },
      );
    }
  });
}
