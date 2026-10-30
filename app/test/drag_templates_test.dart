import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/child/activity_shell.dart';
import 'package:nitznutz/content/models.dart';
import 'package:nitznutz/play/balance_session.dart';
import 'package:nitznutz/play/trace_session.dart';
import 'package:nitznutz/play/shop_pay_session.dart';
import 'package:nitznutz/play/match_pairs_session.dart';
import 'package:nitznutz/play/clock_set_session.dart';
import 'package:nitznutz/play/build_pattern_session.dart';
import 'package:nitznutz/play/lesson_controller.dart';
import 'package:nitznutz/play/number_line_session.dart';
import 'package:nitznutz/play/robot_path_session.dart';
import 'package:nitznutz/play/shape_builder_session.dart';
import 'package:nitznutz/play/sort_drag_session.dart';
import 'package:nitznutz/play/spot_error_session.dart';
import 'package:nitznutz/play/template_session.dart';

import 'support/fakes.dart';
import 'support/harness.dart';
import 'support/starter.dart';

/// The drag templates (T03 sort and share, T05 build a pattern): every move by touch and by drag, the wrong ones with their
/// misconception, the help that points at the right place, and the answers as the engine will read them.
void main() {
  late PackContent content;
  setUpAll(() async {
    await loadAppFonts();
    content = await loadStarter();
  });

  final List<AttemptRecord> written = <AttemptRecord>[];

  LessonController start(String lessonId, int index) {
    written.clear();
    final LessonController c = LessonController(
      content: content,
      lesson: content.lessons[lessonId]!,
      profileId: 'p-1',
      clock: FixedClock(1793000000000),
      record: (AttemptRecord r) async => written.add(r),
    );
    for (int i = 0; i < index; i++) {
      c.next();
    }
    return c;
  }

  Future<void> host(WidgetTester tester, TemplateSession s) async {
    const ActivitySpec spec = ActivitySpec.phone;
    await tester.pumpWidget(
      MaterialApp(
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            body: Builder(
              builder: (BuildContext ctx) => Center(
                child: SizedBox(
                  width: spec.tilesWidth,
                  height: spec.stage.height + 160,
                  child: Column(
                    children: <Widget>[
                      SizedBox(
                        width: spec.stage.width,
                        height: spec.stage.height,
                        child: s.buildStage(ctx, spec.stage.size, spec),
                      ),
                      Expanded(
                        child: SizedBox(
                          width: spec.tilesWidth,
                          child: s.buildTiles(ctx, spec) ?? const SizedBox(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));
  }

  Future<void> tap(WidgetTester t, String key) async {
    await t.tap(find.byKey(Key(key)), warnIfMissed: false);
    await t.pump(const Duration(milliseconds: 60));
  }

  Future<void> settle(WidgetTester t, [int ms = 2400]) async {
    for (int spent = 0; spent < ms; spent += 100) {
      await t.pump(const Duration(milliseconds: 100));
    }
  }

  group('sorting into bins', () {
    testWidgets(
      'a picture goes to its bin by touch; a wrong bin is a not-yet with its misconception and the picture stays',
      (WidgetTester tester) async {
        final LessonController c = start('sort-by-hand', 0);
        final SortDragSession s = SortDragSession(c, c.current as SortDragActivity);
        await host(tester, s);
        // i1 is a red ball (bin b1). Wrong bin first.
        await tap(tester, 'item-i1');
        await tap(tester, 'bin-b2');
        await settle(tester, 300);
        expect(written.single.result, 'incorrect');
        expect(written.single.misconceptionTag, 'M-SORT-SHIFT');
        expect(s.placed, isEmpty, reason: 'the picture goes back to the tray');
        await settle(tester);
        // The right bin.
        await tap(tester, 'item-i1');
        await tap(tester, 'bin-b1');
        expect(s.placed['i1'], 'b1');
        expect(find.byKey(const Key('item-i1')), findsNothing, reason: 'it left the tray');
        s.dispose();
        await tester.pumpWidget(const SizedBox());
      },
    );

    testWidgets(
      'a drag does the same as two touches, and the last right drop ends the activity with one right answer',
      (WidgetTester tester) async {
        final LessonController c = start('sort-by-hand', 0);
        final SortDragActivity a = c.current as SortDragActivity;
        final SortDragSession s = SortDragSession(c, a);
        await host(tester, s);
        for (final SortItem item in a.items) {
          final Offset from = tester.getCenter(find.byKey(Key('item-${item.id}')));
          final Offset to = tester.getCenter(find.byKey(Key('bin-${item.bin}')));
          await tester.dragFrom(from, to - from);
          await tester.pump(const Duration(milliseconds: 100));
        }
        expect(s.placed.length, a.items.length);
        await tester.pump(const Duration(milliseconds: 100));
        expect(written.where((AttemptRecord r) => r.result == 'correct').length, 1);
        expect(written.where((AttemptRecord r) => r.result == 'incorrect'), isEmpty);
        expect(c.feedback, FeedbackKind.correct);
        await settle(tester);
        s.dispose();
        await tester.pumpWidget(const SizedBox());
      },
    );

    testWidgets('after three wrong drops only the right bin takes a picture, and the help points at it', (
      WidgetTester tester,
    ) async {
      final LessonController c = start('sort-by-hand', 0);
      final SortDragActivity a = c.current as SortDragActivity;
      final SortDragSession s = SortDragSession(c, a);
      await host(tester, s);
      for (int k = 0; k < a.maxAttempts; k++) {
        await tap(tester, 'item-i1');
        await tap(tester, 'bin-b2');
        await settle(tester);
      }
      expect(c.guided, isTrue);
      // The guide demonstrates first: the bin is lit only as the last step, when the picture comes back out of it.
      expect(s.hintBin, isNull, reason: 'the help does not point before the worked example');
      expect(c.answerShown, isFalse);
      expect(s.demoRunning, isTrue);
      await settle(tester, 2500);
      expect(s.demoRunning, isFalse);
      expect(c.answerShown, isTrue);
      expect(s.hintBin, 'b1', reason: 'the help shows the bin of the picture');
      final int before = written.length;
      await tap(tester, 'item-i1');
      await tap(tester, 'bin-b2');
      expect(written.length, before, reason: 'a wrong bin is simply not taken now, and not counted again');
      expect(s.placed, isEmpty);
      await tap(tester, 'bin-b1');
      expect(s.placed['i1'], 'b1');
      s.dispose();
      await tester.pumpWidget(const SizedBox());
    });
  });

  group('sharing between two friends', () {
    testWidgets(
      'unequal shares are a not-yet with M-SHARE-UNEQ and the dealing starts again; equal shares are right',
      (WidgetTester tester) async {
        final LessonController c = start('sharing', 1); // four apples
        final SortDragActivity a = c.current as SortDragActivity;
        expect(a.share, isTrue);
        final SortDragSession s = SortDragSession(c, a);
        await host(tester, s);
        // three for the first friend, one for the second
        for (int k = 1; k <= 3; k++) {
          await tap(tester, 'item-i$k');
          await tap(tester, 'bin-b1');
        }
        await tap(tester, 'item-i4');
        await tap(tester, 'bin-b2');
        await settle(tester, 300);
        expect(written.single.result, 'incorrect');
        expect(written.single.misconceptionTag, 'M-SHARE-UNEQ');
        await settle(tester);
        expect(s.placed, isEmpty, reason: 'the pictures are dealt out again');
        // two and two
        for (int k = 1; k <= 4; k++) {
          await tap(tester, 'item-i$k');
          await tap(tester, k.isEven ? 'bin-b2' : 'bin-b1');
        }
        await tester.pump(const Duration(milliseconds: 100));
        expect(written.last.result, 'correct');
        await settle(tester);
        s.dispose();
        await tester.pumpWidget(const SizedBox());
      },
    );

    testWidgets(
      'after three unfair tries the guide deals them one for each in turn, and hands the move back',
      (WidgetTester tester) async {
        final LessonController c = start('sharing', 1);
        final SortDragActivity a = c.current as SortDragActivity;
        final SortDragSession s = SortDragSession(c, a);
        await host(tester, s);
        for (int round = 0; round < a.maxAttempts; round++) {
          // Everything that is still in the tray goes to the first friend: never fair. From the second try on the guide has
          // dealt the first round (one for each), so the child only has the rest to deal.
          for (final SortItem item in List<SortItem>.of(s.tray)) {
            await tap(tester, 'item-${item.id}');
            await tap(tester, 'bin-b1');
          }
          await settle(tester);
        }
        expect(c.guided, isTrue);
        await tester.pump(const Duration(milliseconds: 1500));
        expect(s.demoRunning, isTrue, reason: 'the demonstration is on');
        expect(s.placed.length, greaterThan(0));
        await settle(tester, 6000);
        expect(s.demoRunning, isFalse);
        expect(s.placed, isEmpty, reason: 'then the move is the child\'s again');
        expect(c.answerShown, isTrue);
        s.dispose();
        await tester.pumpWidget(const SizedBox());
      },
    );
  });

  group('building a pattern', () {
    testWidgets(
      'touching the palette fills the next place; a wrong pattern is a not-yet with M-PAT-COPY and empties the places',
      (WidgetTester tester) async {
        final LessonController c = start('copy-patterns', 0);
        final BuildPatternActivity a = c.current as BuildPatternActivity;
        final BuildPatternSession s = BuildPatternSession(c, a);
        await host(tester, s);
        expect(a.sequence, <String>[
          'asset:ball_red',
          'asset:ball_blue',
          'asset:ball_red',
          'asset:ball_blue',
        ]);
        // the palette is [blue, red]: red, red, red, red is wrong
        for (int k = 0; k < 4; k++) {
          await tap(tester, 'palette-1');
        }
        await settle(tester, 300);
        expect(written.single.result, 'incorrect');
        expect(written.single.misconceptionTag, 'M-PAT-COPY');
        await settle(tester);
        expect(s.filled, everyElement(isNull));
        s.dispose();
        await tester.pumpWidget(const SizedBox());
      },
    );

    testWidgets(
      'the right pattern ends the activity; a drag puts a picture in a chosen place; a touch on a place empties it',
      (WidgetTester tester) async {
        final LessonController c = start('copy-patterns', 0);
        final BuildPatternSession s = BuildPatternSession(c, c.current as BuildPatternActivity);
        await host(tester, s);
        // a drag into place 1 (the second place): the blue ball, palette 0
        final Offset from = tester.getCenter(find.byKey(const Key('palette-0')));
        final Offset to = tester.getCenter(find.byKey(const Key('slot-1')));
        await tester.dragFrom(from, to - from);
        await tester.pump(const Duration(milliseconds: 100));
        expect(s.filled[1], 'asset:ball_blue');
        expect(s.filled[0], isNull);
        await tap(tester, 'slot-1');
        expect(s.filled[1], isNull, reason: 'a touch empties a filled place');
        // red, blue, red, blue by touch
        for (final int p in <int>[1, 0, 1, 0]) {
          await tap(tester, 'palette-$p');
        }
        await tester.pump(const Duration(milliseconds: 100));
        expect(written.single.result, 'correct');
        await settle(tester);
        s.dispose();
        await tester.pumpWidget(const SizedBox());
      },
    );

    testWidgets('after three wrong patterns only the right picture is taken, and the help points at it', (
      WidgetTester tester,
    ) async {
      final LessonController c = start('copy-patterns', 0);
      final BuildPatternActivity a = c.current as BuildPatternActivity;
      final BuildPatternSession s = BuildPatternSession(c, a);
      await host(tester, s);
      for (int round = 0; round < a.maxAttempts; round++) {
        for (int k = 0; k < a.slots; k++) {
          await tap(tester, 'palette-1');
        }
        await settle(tester);
      }
      expect(c.guided, isTrue);
      expect(s.hintSprite, isNull, reason: 'the picture is pointed at only after the worked example');
      expect(s.demoRunning, isTrue, reason: 'the guide fills the places first');
      await settle(tester, 6000);
      expect(s.demoRunning, isFalse);
      expect(s.filled, everyElement(isNull), reason: 'then the places are empty again, for the child');
      expect(s.hintSprite, 'asset:ball_red', reason: 'the help shows the picture of the first place');
      await tap(tester, 'palette-0'); // blue in the first place: not taken
      expect(s.filled[0], isNull);
      await tap(tester, 'palette-1');
      expect(s.filled[0], 'asset:ball_red');
      s.dispose();
      await tester.pumpWidget(const SizedBox());
    });
  });

  group('the robot path', () {
    testWidgets(
      'direct: each arrow moves the robot at once, the edge stops it without a mistake, the flag ends it',
      (WidgetTester tester) async {
        final LessonController c = start(
          'robot-moves',
          0,
        ); // 3 by 2, robot at the top left, flag two squares right
        final RobotPathSession s = RobotPathSession(c, c.current as RobotPathActivity);
        await host(tester, s);
        expect(s.pos, (0, 0));
        await tap(tester, 'arrow-left'); // the edge
        expect(s.pos, (0, 0));
        expect(s.bumped, isTrue);
        expect(written, isEmpty, reason: 'a bump into the edge is not a mistake');
        await settle(tester, 500);
        await tap(tester, 'arrow-down');
        expect(s.pos, (0, 1));
        await tap(tester, 'arrow-up');
        await tap(tester, 'arrow-right');
        await tap(tester, 'arrow-right');
        await tester.pump(const Duration(milliseconds: 100));
        expect(s.pos, (2, 0));
        expect(written.single.result, 'correct');
        await settle(tester);
        s.dispose();
        await tester.pumpWidget(const SizedBox());
      },
    );

    testWidgets(
      'plan: the steps are planned and run on go; one square short is M-CS-OFF1 and the program stays to be changed',
      (WidgetTester tester) async {
        final LessonController c = start('robot-plans', 0); // 4 by 2, the flag two squares right
        final RobotPathSession s = RobotPathSession(c, c.current as RobotPathActivity);
        await host(tester, s);
        await tap(tester, 'arrow-right');
        await tap(tester, 'robot-go'); // one step: the robot stops one square short
        expect(s.running, isTrue);
        await settle(tester, 1500);
        expect(s.pos, (1, 0));
        expect(written.single.result, 'incorrect');
        expect(written.single.misconceptionTag, 'M-CS-OFF1');
        await settle(tester);
        expect(s.program, <String>['right'], reason: 'the program stays, so the child can change it');
        expect(s.pos, (0, 0), reason: 'the robot is back at the start');
        await tap(tester, 'arrow-right');
        await tap(tester, 'robot-go');
        await settle(tester, 1500);
        expect(written.last.result, 'correct');
        await settle(tester);
        s.dispose();
        await tester.pumpWidget(const SizedBox());
      },
    );

    testWidgets('plan: undo takes back the last step, and a run that goes past the flag is a mistake too', (
      WidgetTester tester,
    ) async {
      final LessonController c = start('robot-plans', 0);
      final RobotPathSession s = RobotPathSession(c, c.current as RobotPathActivity);
      await host(tester, s);
      await tap(tester, 'arrow-down');
      await tap(tester, 'robot-undo');
      expect(s.program, isEmpty);
      for (int k = 0; k < 3; k++) {
        await tap(tester, 'arrow-right');
      }
      await tap(tester, 'robot-go');
      await settle(tester, 2200);
      expect(written.single.result, 'incorrect');
      expect(written.single.misconceptionTag, 'M-CS-OFF1', reason: 'one square past the flag');
      await settle(tester);
      s.dispose();
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets(
      'after three wrong runs only the right next step is taken, and the help points at its arrow',
      (WidgetTester tester) async {
        final LessonController c = start('robot-plans', 0);
        final RobotPathActivity a = c.current as RobotPathActivity;
        final RobotPathSession s = RobotPathSession(c, a);
        await host(tester, s);
        for (int round = 0; round < a.maxAttempts; round++) {
          await tap(tester, 'arrow-down');
          await tap(tester, 'robot-go');
          await settle(tester, 4200);
        }
        expect(c.guided, isTrue);
        expect(s.program, isEmpty);
        // The guide walks the robot along the right way, and then the move is the child's again.
        await settle(tester, 4500);
        expect(s.running, isFalse);
        expect(s.hintStep, 'right');
        await tap(tester, 'arrow-down'); // not the right step now
        expect(s.program, isEmpty);
        await tap(tester, 'arrow-right');
        expect(s.program, <String>['right']);
        s.dispose();
        await tester.pumpWidget(const SizedBox());
      },
    );
  });

  group('the shape builder', () {
    /// A point on a place that no other place covers: pictures overlap (a door on the body of a house), so the touch goes a
    /// little above the middle of an upright place, and to the middle of a turned one.
    Offset onSlot(WidgetTester t, ShapeBuilderActivity a, String id) {
      final ShapeSlot slot = a.slots.firstWhere((ShapeSlot s) => s.id == id);
      final Rect r = t.getRect(find.byKey(Key('slot-$id')));
      return slot.rot == 0 ? r.center - Offset(0, r.height * 0.3) : r.center;
    }

    testWidgets(
      'a shape snaps into its own place by touch, a wrong place is a not-yet and the shape stays in the tray',
      (WidgetTester tester) async {
        final LessonController c = start('build-with-shapes', 0); // the house
        final ShapeBuilderActivity a = c.current as ShapeBuilderActivity;
        final ShapeBuilderSession s = ShapeBuilderSession(c, a);
        await host(tester, s);
        final int square = s.pieces.indexOf('asset:shape_square_blue');
        await tap(tester, 'piece-$square');
        await tester.tapAt(onSlot(tester, a, 's2'));
        await tester.pump(const Duration(milliseconds: 60));
        await settle(tester, 300);
        expect(written.single.result, 'incorrect');
        expect(s.filled, isEmpty);
        expect(s.isUsed(square), isFalse, reason: 'the shape is still in the tray');
        await settle(tester);
        await tap(tester, 'piece-$square');
        await tester.tapAt(onSlot(tester, a, 's1'));
        await tester.pump(const Duration(milliseconds: 60));
        expect(s.filled, <String>{'s1'});
        expect(s.isUsed(square), isTrue);
        s.dispose();
        await tester.pumpWidget(const SizedBox());
      },
    );

    testWidgets(
      'drag does the same; the last shape ends the activity with one right answer; a decoy is never placed',
      (WidgetTester tester) async {
        final LessonController c = start('build-with-shapes', 0);
        final ShapeBuilderActivity a = c.current as ShapeBuilderActivity;
        final ShapeBuilderSession s = ShapeBuilderSession(c, a);
        await host(tester, s);
        expect(s.pieces.length, a.slots.length + a.decoys.length);
        for (final ShapeSlot slot in a.slots) {
          final int piece = <int>[for (int i = 0; i < s.pieces.length; i++) i]
              .firstWhere((int i) => !s.isUsed(i) && s.pieces[i] == slot.sprite);
          final Offset from = tester.getCenter(find.byKey(Key('piece-$piece')));
          final Offset to = onSlot(tester, a, slot.id);
          await tester.dragFrom(from, to - from);
          await tester.pump(const Duration(milliseconds: 100));
        }
        expect(s.filled.length, a.slots.length);
        await tester.pump(const Duration(milliseconds: 100));
        expect(written.where((AttemptRecord r) => r.result == 'correct').length, 1);
        expect(written.where((AttemptRecord r) => r.result == 'incorrect'), isEmpty);
        final int decoy = s.pieces.indexOf(a.decoys.first);
        expect(s.isUsed(decoy), isFalse);
        await settle(tester);
        s.dispose();
        await tester.pumpWidget(const SizedBox());
      },
    );

    testWidgets('after three wrong places only the right place takes a shape, and the help points at it', (
      WidgetTester tester,
    ) async {
      final LessonController c = start('build-with-shapes', 0);
      final ShapeBuilderActivity a = c.current as ShapeBuilderActivity;
      final ShapeBuilderSession s = ShapeBuilderSession(c, a);
      await host(tester, s);
      final int square = s.pieces.indexOf('asset:shape_square_blue');
      for (int k = 0; k < a.maxAttempts; k++) {
        await tap(tester, 'piece-$square');
        await tester.tapAt(onSlot(tester, a, 's2'));
        await tester.pump(const Duration(milliseconds: 60));
        await settle(tester);
      }
      expect(c.guided, isTrue);
      expect(s.demoRunning, isTrue, reason: 'the guide puts one piece in its place first');
      await settle(tester, 3000);
      expect(s.demoRunning, isFalse);
      expect(s.filled, isEmpty, reason: 'then the piece is out again, for the child');
      expect(s.hintSlot, 's1', reason: 'the help shows the first empty place');
      final int before = written.length;
      await tap(tester, 'piece-$square');
      await tester.tapAt(onSlot(tester, a, 's2'));
      await tester.pump(const Duration(milliseconds: 60));
      expect(written.length, before, reason: 'not counted again');
      await tester.tapAt(onSlot(tester, a, 's1'));
      await tester.pump(const Duration(milliseconds: 60));
      expect(s.filled, <String>{'s1'});
      s.dispose();
      await tester.pumpWidget(const SizedBox());
    });
  });

  group('the number line', () {
    /// A point on the line for the number [n], whatever the width of the stage.
    Offset onTick(WidgetTester t, NumberLineActivity a, int n) {
      final Rect r = t.getRect(find.byKey(const Key('line-touch')));
      const double pad = 22;
      return Offset(r.left + pad + (n - a.from) / (a.to - a.from) * (r.width - 2 * pad), r.center.dy);
    }

    testWidgets(
      'a touch on the right tick is the answer; a wrong tick is a not-yet, and the mirror has its own tag',
      (WidgetTester tester) async {
        final LessonController c = start('frog-line-10', 0);
        final NumberLineActivity a = c.current as NumberLineActivity;
        final NumberLineSession s = NumberLineSession(c, a);
        await host(tester, s);
        await tester.tapAt(onTick(tester, a, 5));
        await tester.pump(const Duration(milliseconds: 60));
        expect(written.single.result, 'incorrect');
        expect(written.single.misconceptionTag, 'M-NL-SPACE');
        await settle(tester);
        await tester.tapAt(onTick(tester, a, a.from + a.to - a.target));
        await tester.pump(const Duration(milliseconds: 60));
        expect(written.last.result, 'incorrect');
        expect(written.last.misconceptionTag, 'M-NL-DIR', reason: 'the line read from the right');
        await settle(tester);
        await tester.tapAt(onTick(tester, a, a.target));
        await tester.pump(const Duration(milliseconds: 60));
        expect(written.last.result, 'correct');
        await settle(tester);
        s.dispose();
        await tester.pumpWidget(const SizedBox());
      },
    );

    testWidgets(
      'after three wrong touches only the right tick is taken, and the guide counts along the line',
      (WidgetTester tester) async {
        final LessonController c = start('frog-line-10', 0);
        final NumberLineActivity a = c.current as NumberLineActivity;
        final NumberLineSession s = NumberLineSession(c, a);
        await host(tester, s);
        for (int k = 0; k < a.maxAttempts; k++) {
          await tester.tapAt(onTick(tester, a, 9));
          await tester.pump(const Duration(milliseconds: 60));
          await settle(tester);
        }
        expect(c.guided, isTrue);
        final int before = written.length;
        await tester.tapAt(onTick(tester, a, 9));
        await tester.pump(const Duration(milliseconds: 60));
        expect(written.length, before, reason: 'not counted again');
        await settle(tester, 6000);
        await tester.tapAt(onTick(tester, a, a.target));
        await tester.pump(const Duration(milliseconds: 60));
        expect(written.last.result, 'correct');
        await settle(tester);
        s.dispose();
        await tester.pumpWidget(const SizedBox());
      },
    );
  });

  group('the balance', () {
    testWidgets('compare: the wrong side carries the misconception, the right answer ends the activity', (
      WidgetTester tester,
    ) async {
      final LessonController c = start('equals-balance', 0);
      final BalanceActivity a = c.current as BalanceActivity;
      expect(a.result, 'same');
      final BalanceSession s = BalanceSession(c, a);
      await host(tester, s);
      expect(s.lean, 0, reason: 'a sum that is being compared must not lean before the answer');
      await tap(tester, 'balance-left');
      expect(written.single.result, 'incorrect');
      expect(written.single.misconceptionTag, 'M-EQ-OPER');
      await settle(tester);
      await tap(tester, 'balance-same');
      expect(written.last.result, 'correct');
      await settle(tester);
      s.dispose();
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('balance: blocks are added one by one, and a level scale is the answer', (
      WidgetTester tester,
    ) async {
      final LessonController c = start('balance-it', 0);
      final BalanceActivity a = c.current as BalanceActivity;
      final int need = int.parse(a.result);
      final BalanceSession s = BalanceSession(c, a);
      await host(tester, s);
      for (int k = 0; k < need; k++) {
        await tap(tester, 'balance-plus');
      }
      expect(s.added, need);
      expect(written.single.result, 'correct');
      await settle(tester);
      s.dispose();
      await tester.pumpWidget(const SizedBox());
    });
  });

  group('spot the mistake', () {
    testWidgets('a touch on the mistake is right; any other cell is a not-yet with the misconception', (
      WidgetTester tester,
    ) async {
      final LessonController c = start('count-order', 0);
      final SpotErrorActivity a = c.current as SpotErrorActivity;
      final SpotErrorSession s = SpotErrorSession(c, a);
      await host(tester, s);
      final int other = a.wrong == 0 ? 1 : 0;
      await tap(tester, 'cell-$other');
      expect(written.single.result, 'incorrect');
      expect(written.single.misconceptionTag, 'M-CNT-SEQ');
      await settle(tester);
      await tap(tester, 'cell-${a.wrong}');
      expect(written.last.result, 'correct');
      await settle(tester);
      s.dispose();
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('after three wrong touches only the mistake is taken, and the help rings it', (
      WidgetTester tester,
    ) async {
      final LessonController c = start('count-order', 0);
      final SpotErrorActivity a = c.current as SpotErrorActivity;
      final SpotErrorSession s = SpotErrorSession(c, a);
      await host(tester, s);
      final int other = a.wrong == 0 ? 1 : 0;
      for (int k = 0; k < a.maxAttempts; k++) {
        await tap(tester, 'cell-$other');
        await settle(tester);
      }
      expect(c.guided, isTrue);
      // The guide walks along the row and stops at the mistake: it is rung only at the end of the walk.
      await settle(tester, 700 * (a.cells.length + 2));
      expect(s.hintCell, a.wrong);
      expect(c.answerShown, isTrue);
      final int before = written.length;
      await tap(tester, 'cell-$other');
      expect(written.length, before, reason: 'not counted again');
      await tap(tester, 'cell-${a.wrong}');
      expect(written.last.result, 'correct');
      await settle(tester);
      s.dispose();
      await tester.pumpWidget(const SizedBox());
    });
  });

  group('matching pairs', () {
    testWidgets(
      'a wrong pair is a not-yet with its misconception; the right pairs stay joined and end the activity',
      (WidgetTester tester) async {
        final LessonController c = start('match-numbers-sets', 0);
        final MatchPairsActivity a = c.current as MatchPairsActivity;
        final MatchPairsSession s = MatchPairsSession(c, a);
        await host(tester, s);
        final String l = a.pairs.keys.first;
        final String wrongRight = a.pairs.values.firstWhere((String r) => r != a.pairs[l]);
        await tap(tester, 'top-$l');
        await tap(tester, 'bottom-$wrongRight');
        expect(written.single.result, 'incorrect');
        expect(written.single.misconceptionTag, 'M-CNT-SIZE');
        expect(s.matched, isEmpty);
        await settle(tester);
        for (final MapEntry<String, String> e in a.pairs.entries) {
          await tap(tester, 'top-${e.key}');
          await tap(tester, 'bottom-${e.value}');
        }
        expect(s.matched.length, a.pairs.length);
        expect(written.last.result, 'correct');
        await settle(tester);
        s.dispose();
        await tester.pumpWidget(const SizedBox());
      },
    );

    testWidgets('after three wrong pairs only a right pair is taken, and the help lights it', (
      WidgetTester tester,
    ) async {
      final LessonController c = start('match-numbers-sets', 0);
      final MatchPairsActivity a = c.current as MatchPairsActivity;
      final MatchPairsSession s = MatchPairsSession(c, a);
      await host(tester, s);
      final String l = a.pairs.keys.first;
      final String wrongRight = a.pairs.values.firstWhere((String r) => r != a.pairs[l]);
      for (int k = 0; k < a.maxAttempts; k++) {
        await tap(tester, 'top-$l');
        await tap(tester, 'bottom-$wrongRight');
        await settle(tester);
      }
      expect(c.guided, isTrue);
      expect(s.hintLeft, isNotNull);
      final int before = written.length;
      await tap(tester, 'top-$l');
      await tap(tester, 'bottom-$wrongRight');
      expect(written.length, before, reason: 'not counted again');
      expect(s.matched, isEmpty);
      s.dispose();
      await tester.pumpWidget(const SizedBox());
    });
  });

  group('the shop', () {
    testWidgets('paying the exact price is right; as many coins as shekels is M-MONEY-COUNT', (
      WidgetTester tester,
    ) async {
      final LessonController c = start('pay-exactly', 0); // three shekels; purse: three 1s and two 2s
      final ShopPayActivity a = c.current as ShopPayActivity;
      expect(a.price, 300);
      final ShopPaySession s = ShopPaySession(c, a);
      await host(tester, s);
      for (final String id in <String>['c3', 'c4', 'c0']) {
        await tap(tester, 'coin-$id'); // 2 + 2 + 1 = five shekels, three coins
      }
      expect(s.total, 500);
      await tap(tester, 'pay');
      expect(written.single.result, 'incorrect');
      expect(written.single.misconceptionTag, 'M-MONEY-COUNT');
      await settle(tester);
      expect(s.onCounter, isEmpty, reason: 'the coins go back to the purse');
      await tap(tester, 'coin-c0');
      await tap(tester, 'coin-c3');
      await tap(tester, 'pay');
      expect(written.last.result, 'correct');
      await settle(tester);
      s.dispose();
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets(
      'a coin on the counter goes back by a touch; after three mistakes the help lights a way to pay',
      (WidgetTester tester) async {
        final LessonController c = start('pay-exactly', 0);
        final ShopPaySession s = ShopPaySession(c, c.current as ShopPayActivity);
        await host(tester, s);
        await tap(tester, 'coin-c0');
        expect(s.onCounter, <String>['c0']);
        await tap(tester, 'on-c0');
        expect(s.onCounter, isEmpty);
        for (int k = 0; k < c.current.maxAttempts; k++) {
          // From the second mistake the guide may have put its first coin on the counter already.
          if (!s.onCounter.contains('c3')) await tap(tester, 'coin-c3');
          await tap(tester, 'pay');
          await settle(tester);
        }
        expect(c.guided, isTrue);
        expect(s.solution().length, 2, reason: 'the fewest coins for three shekels: a 2 and a 1');
        expect(s.hinted, isEmpty, reason: 'the coins are lit only after the guide has paid');
        expect(s.demoRunning, isTrue);
        await settle(tester, 4000);
        expect(s.demoRunning, isFalse);
        expect(s.hinted, isNotEmpty);
        s.dispose();
        await tester.pumpWidget(const SizedBox());
      },
    );
  });

  group('the clock', () {
    testWidgets(
      'the arrows move the short hand; twelve for another hour is M-CLOCK-HANDS; the right hour is right',
      (WidgetTester tester) async {
        final LessonController c = start('set-the-clock', 0); // three o'clock, starting at twelve
        final ClockSetActivity a = c.current as ClockSetActivity;
        expect((a.hour, a.startHour), (3, 12));
        final ClockSetSession s = ClockSetSession(c, a);
        await host(tester, s);
        await tap(tester, 'clock-ok');
        expect(written.single.result, 'incorrect');
        expect(written.single.misconceptionTag, 'M-CLOCK-HANDS');
        await settle(tester);
        for (int k = 0; k < 3; k++) {
          await tap(tester, 'clock-next');
        }
        expect(s.hour, 3);
        await tap(tester, 'clock-ok');
        expect(written.last.result, 'correct');
        await settle(tester);
        s.dispose();
        await tester.pumpWidget(const SizedBox());
      },
    );

    testWidgets(
      'dragging the face turns the short hand to the nearest hour, and the help shows where it belongs',
      (WidgetTester tester) async {
        final LessonController c = start('set-the-clock', 0);
        final ClockSetSession s = ClockSetSession(c, c.current as ClockSetActivity);
        await host(tester, s);
        final Rect r = tester.getRect(find.byKey(const Key('clock-face')));
        await tester.tapAt(r.center + Offset(r.width * 0.3, 0)); // pointing at the three
        await tester.pump(const Duration(milliseconds: 60));
        expect(s.hour, 3);
        await tester.tapAt(r.center + Offset(0, r.height * 0.3)); // the six
        await tester.pump(const Duration(milliseconds: 60));
        expect(s.hour, 6);
        for (int k = 0; k < c.current.maxAttempts; k++) {
          await tap(tester, 'clock-ok');
          await settle(tester);
        }
        expect(c.guided, isTrue);
        expect(s.ghost, isFalse, reason: 'the faint hands wait for the end of the worked example');
        expect(s.demoRunning, isTrue, reason: 'the short hand steps to the hour first');
        await settle(tester, 6000);
        expect(s.demoRunning, isFalse);
        expect(s.ghost, isTrue);
        s.dispose();
        await tester.pumpWidget(const SizedBox());
      },
    );
  });

  group('tracing', () {
    Offset at(WidgetTester t, Offset unit) {
      final Rect r = t.getRect(find.byKey(const Key('trace-stage')));
      return r.topLeft + Offset(unit.dx / 100 * r.width, unit.dy / 100 * r.height);
    }

    Future<void> follow(WidgetTester t, List<Offset> units) async {
      final TestGesture g = await t.startGesture(at(t, units.first));
      for (final Offset u in units.skip(1)) {
        await g.moveTo(at(t, u));
        await t.pump(const Duration(milliseconds: 16));
      }
      await g.up();
      await t.pump(const Duration(milliseconds: 60));
    }

    testWidgets(
      'tracing the path from its start is right; the same path from the other end is the direction tag',
      (WidgetTester tester) async {
        final LessonController c = start('trace-numbers-0-4', 1); // the numeral one
        final TraceActivity a = c.current as TraceActivity;
        final TraceSession s = TraceSession(c, a);
        await host(tester, s);
        final List<Offset> path = a.strokes.first;
        await follow(tester, path.reversed.toList());
        expect(written.single.result, 'incorrect');
        expect(written.single.misconceptionTag, 'M-NUM-WRITE', reason: 'drawn from the wrong end');
        await settle(tester);
        await follow(tester, <Offset>[const Offset(80, 80), const Offset(90, 90)]);
        expect(written.last.result, 'incorrect');
        await settle(tester);
        await follow(tester, path);
        expect(written.last.result, 'correct');
        await settle(tester);
        s.dispose();
        await tester.pumpWidget(const SizedBox());
      },
    );

    testWidgets('after three mistakes the whole path is shown and a dot walks along it', (
      WidgetTester tester,
    ) async {
      final LessonController c = start(
        'write-from-the-dot-0-4',
        1,
      ); // the numeral one, only the start dot shown
      final TraceActivity a = c.current as TraceActivity;
      expect(a.fullGuide, isFalse);
      final TraceSession s = TraceSession(c, a);
      await host(tester, s);
      expect(s.guideShown, isFalse);
      for (int k = 0; k < a.maxAttempts; k++) {
        await follow(tester, <Offset>[const Offset(80, 80), const Offset(90, 90)]);
        await settle(tester);
      }
      expect(c.guided, isTrue);
      expect(s.guideShown, isTrue);
      s.dispose();
      await tester.pumpWidget(const SizedBox());
    });
  });
}
