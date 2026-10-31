import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/child/activity_shell.dart';
import 'package:nitznutz/content/hint_ladder.dart';
import 'package:nitznutz/content/models.dart';
import 'package:nitznutz/design/components.dart';
import 'package:nitznutz/play/balance_session.dart';
import 'package:nitznutz/play/build_pattern_session.dart';
import 'package:nitznutz/play/clock_set_session.dart';
import 'package:nitznutz/play/count_tap_session.dart';
import 'package:nitznutz/play/flash_session.dart';
import 'package:nitznutz/play/give_n_session.dart';
import 'package:nitznutz/play/hint_hand.dart';
import 'package:nitznutz/play/hint_widgets.dart';
import 'package:nitznutz/play/lesson_controller.dart';
import 'package:nitznutz/play/match_pairs_session.dart';
import 'package:nitznutz/play/number_line_session.dart';
import 'package:nitznutz/play/robot_path_session.dart';
import 'package:nitznutz/play/shape_builder_session.dart';
import 'package:nitznutz/play/shop_pay_session.dart';
import 'package:nitznutz/play/sort_drag_session.dart';
import 'package:nitznutz/play/spot_error_session.dart';
import 'package:nitznutz/play/tap_answer_session.dart';
import 'package:nitznutz/play/template_session.dart';
import 'package:nitznutz/play/trace_session.dart';

import 'support/fakes.dart';
import 'support/harness.dart';
import 'support/starter.dart';

/// B-40 part 1: the hint ladder. Every template draws something different at each level (the table is `HintLadder`), levels 1
/// and 2 never mark the answer (an option, a bin, a coin, a cell, a hand), the worked example of level 3 ends by marking it, the
/// fingers and ten-frames show exactly the number, and a row's cells come in one by one from the left.
void main() {
  late PackContent content;
  setUpAll(() async {
    await loadAppFonts();
    content = await loadStarter();
  });

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

  Future<void> host(WidgetTester tester, TemplateSession s, {bool reduceMotion = true}) async {
    const ActivitySpec spec = ActivitySpec.phone;
    await tester.pumpWidget(
      MaterialApp(
        builder: (BuildContext context, Widget? child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: reduceMotion),
          child: child!,
        ),
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

  Future<void> pass(WidgetTester t, int ms) async {
    for (int spent = 0; spent < ms; spent += 100) {
      await t.pump(const Duration(milliseconds: 100));
    }
  }

  /// The child asks for help [times] times with the lamp, and the stage plays it for [ms] each.
  Future<void> lamp(WidgetTester t, LessonController c, {int ms = 20000}) async {
    c.showHint();
    await t.pump(const Duration(milliseconds: 1));
    await t.pump(Duration(milliseconds: ms));
  }

  Future<void> end(WidgetTester t, TemplateSession s) async {
    s.dispose();
    await t.pumpWidget(const SizedBox());
  }

  List<T> all<T extends Activity>() => content.activities.values.whereType<T>().toList();

  /// How many fingers the hands on the screen have up (the hand is the design-director's art, or a placeholder until it is loaded).
  int raised(WidgetTester t) =>
      t.widgetList<HintHand>(find.byType(HintHand)).fold(0, (int sum, HintHand h) => sum + h.fingers);

  // ---- the table ----

  group('the ladder table', () {
    test('every template of the pack has a ladder, and none of them shows the answer at level 1 or 2', () {
      final Set<String> used = content.activities.values.map((Activity a) => a.template).toSet();
      expect(used, isNotEmpty);
      for (final String template in used) {
        expect(HintLadder.problemWith(template), isNull, reason: template);
        expect(HintLadder.of(template)!.pictures, hasLength(3));
      }
      expect(HintLadder.problemWith('sort_drag', share: true), isNull);
      expect(HintLadder.problemWith('a_template_nobody_made'), contains('no hint ladder'));
    });

    test('only the demonstration marks the answer, and it is always level 3', () {
      expect(HintPicture.values.where((HintPicture p) => p.marksAnswer), <HintPicture>[
        HintPicture.demonstration,
      ]);
      for (final String t in HintLadder.templates) {
        expect(HintLadder.of(t)!.at(3), HintPicture.demonstration, reason: t);
        expect(HintLadder.of(t)!.at(1).marksAnswer, isFalse, reason: t);
        expect(HintLadder.of(t)!.at(2).marksAnswer, isFalse, reason: t);
      }
    });

    test('no template draws at a level what it draws at the level below', () {
      for (final String t in HintLadder.templates) {
        final HintLadder l = HintLadder.of(t)!;
        expect(l.at(2), isNot(l.at(1)), reason: '$t level 2');
        expect(l.at(3), isNot(l.at(2)), reason: '$t level 3');
      }
      expect(HintLadder.of('sort_drag', share: true)!.at(2), HintPicture.firstRound);
    });
  });

  // ---- the fingers, the ten-frames ----

  group('the number shown another way is the number counted', () {
    for (int n = 1; n <= 20; n++) {
      testWidgets('$n: ${n <= 10 ? 'two hands' : 'ten-frames'} with $n raised or filled', (
        WidgetTester t,
      ) async {
        await t.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Center(
                child: CountingAid(n: n, shown: n),
              ),
            ),
          ),
        );
        if (n <= 10) {
          expect(raised(t), n);
          expect(find.byKey(const Key('ten-frames')), findsNothing);
          // A full hand of five, and the rest on the other hand.
          expect(t.widget<HintHand>(find.byKey(const Key('hand-first'))).fingers, n > 5 ? 5 : n);
          expect(t.widget<HintHand>(find.byKey(const Key('hand-second'))).fingers, n > 5 ? n - 5 : 0);
        } else {
          expect(find.byKey(const Key('frame-counter')), findsNWidgets(n));
          expect(find.byType(HintHand), findsNothing);
        }
      });
    }

    testWidgets('a hint shows fewer when fewer are counted so far (the aid grows with the count)', (
      WidgetTester t,
    ) async {
      await t.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: Center(child: CountingAid(n: 13, shown: 4))),
        ),
      );
      expect(find.byKey(const Key('frame-counter')), findsNWidgets(4));
    });

    testWidgets(
      'every counting and giving activity of the pack ends its level-2 aid on its own number (all 70)',
      (WidgetTester t) async {
        int checked = 0;
        for (final CountTapActivity a in all<CountTapActivity>()) {
          final LessonController c = controllerFor(a);
          final CountTapSession s = CountTapSession(c, a);
          c.showHint();
          await t.pump(const Duration(milliseconds: 1));
          c.showHint();
          await t.pump(Duration(milliseconds: 600 * a.count + 300));
          expect(s.fingers, a.count, reason: a.id);
          s.dispose();
          checked++;
        }
        for (final GiveNActivity a in all<GiveNActivity>()) {
          final LessonController c = controllerFor(a);
          final GiveNSession s = GiveNSession(c, a);
          c.showHint();
          await t.pump(const Duration(milliseconds: 1));
          c.showHint();
          await t.pump(Duration(milliseconds: 600 * a.n + 300));
          expect(s.fingers, a.n, reason: a.id);
          s.dispose();
          checked++;
        }
        expect(checked, 70);
      },
    );

    testWidgets('NUM-A-09 count 7: level 1 leaves a dot on each, level 2 shows two hands with seven up', (
      WidgetTester t,
    ) async {
      final CountTapActivity a = content.activities['count.apples.7']! as CountTapActivity;
      final LessonController c = controllerFor(a);
      final CountTapSession s = CountTapSession(c, a);
      await host(t, s);
      c.showHint(); // level 1
      await pass(t, 450 * 7 + 200);
      expect(
        find.byKey(const Key('seen-dot')),
        findsNWidgets(7),
        reason: 'a dot stays on each object the light visited',
      );
      expect(find.byKey(const Key('fingers-hint')), findsNothing);
      c.showHint(); // level 2
      await pass(t, 600 * 7 + 300);
      expect(find.byKey(const Key('fingers-hint')), findsOneWidget);
      expect(raised(t), 7);
      expect(find.byKey(const Key('ten-frames')), findsNothing);
      await pass(t, 3000);
      expect(
        find.byKey(const Key('fingers-hint')),
        findsNothing,
        reason: 'the card goes when it has been shown',
      );
      await end(t, s);
    });

    testWidgets('NUM-B-04 (teens): level 2 shows ten-frames, and the counters equal the count', (
      WidgetTester t,
    ) async {
      final CountTapActivity a = content.activities['b.numb04.3']! as CountTapActivity;
      final LessonController c = controllerFor(a);
      final CountTapSession s = CountTapSession(c, a);
      await host(t, s);
      c.showHint();
      await pass(t, 450 * a.count + 200);
      c.showHint();
      await pass(t, 600 * a.count + 300);
      expect(a.count, greaterThan(10));
      expect(find.byKey(const Key('ten-frames')), findsOneWidget);
      expect(find.byKey(const Key('frame-counter')), findsNWidgets(a.count));
      expect(find.byType(HintHand), findsNothing);
      await end(t, s);
    });

    testWidgets(
      'give N: level 1 shows the goal as a numeral with its dots, level 2 the same number as hands',
      (WidgetTester t) async {
        final GiveNActivity a = all<GiveNActivity>().firstWhere((GiveNActivity g) => g.n <= 10);
        final LessonController c = controllerFor(a);
        final GiveNSession s = GiveNSession(c, a);
        await host(t, s);
        c.showHint();
        await pass(t, 300);
        expect(find.byKey(const Key('goal-card')), findsOneWidget);
        expect(find.text('${a.n}'), findsWidgets);
        expect(find.byKey(const Key('give-flower-ring')), findsOneWidget);
        c.showHint();
        await pass(t, 600 * a.n + 300);
        expect(raised(t), a.n);
        await end(t, s);
      },
    );
  });

  // ---- level 1 and 2 never mark the answer; level 3 ends by marking it ----

  group('no hint of level 1 or 2 marks the answer; the worked example ends on it', () {
    testWidgets(
      'sort: no bin is lit at rest after level 1 or 2; level 3 sorts one picture and leaves its bin lit',
      (WidgetTester t) async {
        int n = 0;
        for (final SortDragActivity a in all<SortDragActivity>()) {
          final LessonController c = controllerFor(a);
          final SortDragSession s = SortDragSession(c, a);
          await lamp(t, c, ms: 9000);
          expect(s.hintBin, isNull, reason: '${a.id} level 1');
          expect(s.litBin, isNull, reason: '${a.id} level 1 rests on no bin');
          await lamp(t, c, ms: 9000);
          expect(s.hintBin, isNull, reason: '${a.id} level 2');
          if (a.share) {
            expect(s.placed.length, a.bins.length, reason: '${a.id}: one round dealt, one for each friend');
          } else {
            expect(s.hintItem, s.tray.first.id, reason: '${a.id}: the next picture is lit, not its bin');
          }
          await lamp(t, c, ms: 30000);
          expect(s.demoRunning, isFalse, reason: a.id);
          if (!a.share) expect(s.hintBin, s.tray.first.bin, reason: '${a.id} level 3 ends on the bin');
          s.dispose();
          n++;
        }
        expect(n, 33);
      },
    );

    testWidgets(
      'build a pattern: level 1 lights a place only, level 2 the model cell above it; level 3 ends on the picture',
      (WidgetTester t) async {
        for (final BuildPatternActivity a in all<BuildPatternActivity>()) {
          final LessonController c = controllerFor(a);
          final BuildPatternSession s = BuildPatternSession(c, a);
          await lamp(t, c, ms: 12000);
          expect(s.hintSprite, isNull, reason: '${a.id} level 1');
          expect(s.hintSlot, 0, reason: '${a.id}: it ends on the next empty place');
          await lamp(t, c, ms: 12000);
          expect(s.hintSprite, isNull, reason: '${a.id} level 2');
          await lamp(t, c, ms: 30000);
          expect(s.demoRunning, isFalse, reason: a.id);
          expect(s.hintSprite, a.sequence[0], reason: '${a.id} level 3 ends on the first picture');
          expect(s.filled, everyElement(isNull));
          s.dispose();
        }
      },
    );

    testWidgets('match: level 2 lights the first card only; level 3 joins one pair and leaves both lit', (
      WidgetTester t,
    ) async {
      for (final MatchPairsActivity a in all<MatchPairsActivity>()) {
        final LessonController c = controllerFor(a);
        final MatchPairsSession s = MatchPairsSession(c, a);
        await lamp(t, c, ms: 12000);
        expect(s.hintLeft, isNull, reason: '${a.id} level 1 rests on no card');
        expect(s.hintRight, isNull);
        await lamp(t, c, ms: 12000);
        expect(s.hintLeft, a.pairs.keys.first, reason: a.id);
        expect(s.hintRight, isNull, reason: '${a.id} level 2 does not light its partner');
        await lamp(t, c, ms: 12000);
        expect(s.hintLeft, a.pairs.keys.first);
        expect(s.hintRight, a.pairs.values.first, reason: '${a.id} level 3 ends on the pair');
        expect(s.matched, isEmpty, reason: 'the pair is taken out again for the child');
        s.dispose();
      }
    });

    testWidgets('shape builder: no piece is lit at level 1 or 2; level 3 ends on the place and its piece', (
      WidgetTester t,
    ) async {
      for (final ShapeBuilderActivity a in all<ShapeBuilderActivity>()) {
        final LessonController c = controllerFor(a);
        final ShapeBuilderSession s = ShapeBuilderSession(c, a);
        await lamp(t, c, ms: 12000);
        expect(s.hintPiece, isNull, reason: '${a.id} level 1');
        expect(s.hintSlot, isNull, reason: '${a.id} level 1 rests on no place');
        await lamp(t, c, ms: 12000);
        expect(s.hintPiece, isNull, reason: '${a.id} level 2');
        expect(s.hintSlot, a.slots.first.id, reason: '${a.id}: where, not which piece');
        await lamp(t, c, ms: 12000);
        expect(s.hintPiece, isNotNull, reason: '${a.id} level 3');
        expect(s.filled, isEmpty);
        s.dispose();
      }
    });

    testWidgets('number line: the tick of the answer is never lit at level 1 or 2; level 3 ends on it', (
      WidgetTester t,
    ) async {
      for (final NumberLineActivity a in all<NumberLineActivity>()) {
        final LessonController c = controllerFor(a);
        final NumberLineSession s = NumberLineSession(c, a);
        await lamp(t, c, ms: 3000);
        expect(s.trail, isNotEmpty, reason: '${a.id} level 1 lights the start');
        expect(s.trail.contains(a.target), isFalse, reason: '${a.id} level 1');
        await lamp(t, c, ms: 3000);
        expect(
          s.trail.contains(a.target),
          isFalse,
          reason: '${a.id} level 2 hops one unit and not onto the answer',
        );
        await lamp(t, c, ms: 30000);
        expect(s.trail.contains(a.target), isTrue, reason: '${a.id} level 3 ends on the answer');
        s.dispose();
      }
    });

    testWidgets(
      'robot: level 1 lights the robot and the flag and no arrow; level 3 ends on the first arrow',
      (WidgetTester t) async {
        for (final RobotPathActivity a in all<RobotPathActivity>()) {
          final LessonController c = controllerFor(a);
          final RobotPathSession s = RobotPathSession(c, a);
          await lamp(t, c, ms: 3000);
          expect(s.spotlight, isTrue, reason: a.id);
          expect(s.hintStep, isNull, reason: '${a.id} level 1 names no step');
          await lamp(t, c, ms: 3000);
          expect(s.spotlight, isFalse);
          expect(s.hintStep, isNotNull, reason: '${a.id} level 2: one step');
          expect(s.pos, a.robotAt, reason: 'the ghost takes the step, not the robot');
          await lamp(t, c, ms: 30000);
          expect(s.running, isFalse, reason: a.id);
          expect(s.hintStep, isNotNull, reason: '${a.id} level 3 ends on the arrow to press first');
          expect(s.pos, a.robotAt, reason: 'the robot is back at the start, for the child');
          s.dispose();
        }
      },
    );

    testWidgets('shop: no coin is lit at level 1 or 2; level 3 pays, takes the coins back and lights them', (
      WidgetTester t,
    ) async {
      for (final ShopPayActivity a in all<ShopPayActivity>()) {
        final LessonController c = controllerFor(a);
        final ShopPaySession s = ShopPaySession(c, a);
        await lamp(t, c, ms: 3000);
        expect(s.hinted, isEmpty, reason: '${a.id} level 1');
        expect(s.lightPrice, isTrue);
        await lamp(t, c, ms: 3000);
        expect(s.hinted, isEmpty, reason: '${a.id} level 2');
        expect(s.total, lessThan(a.price), reason: '${a.id}: the first coin alone never pays the price');
        await lamp(t, c, ms: 30000);
        expect(s.onCounter, isEmpty, reason: a.id);
        expect(s.hinted, s.solution(), reason: '${a.id} level 3 ends on the coins of the way');
        s.dispose();
      }
    });

    testWidgets('clock: no target hand at level 1 or 2; level 3 steps the hand and leaves the faint hands', (
      WidgetTester t,
    ) async {
      for (final ClockSetActivity a in all<ClockSetActivity>()) {
        final LessonController c = controllerFor(a);
        final ClockSetSession s = ClockSetSession(c, a);
        await lamp(t, c, ms: 2000);
        expect(s.ghost, isFalse, reason: '${a.id} level 1');
        expect(s.lightHand, isTrue);
        expect(s.numeralRing, isFalse);
        await lamp(t, c, ms: 2000);
        expect(s.ghost, isFalse, reason: '${a.id} level 2');
        expect(s.numeralRing, isTrue);
        await lamp(t, c, ms: 30000);
        expect(s.demoRunning, isFalse);
        expect(s.ghost, isTrue, reason: '${a.id} level 3');
        expect(s.hour, a.startHour, reason: 'the child\'s hand was never moved by the guide');
        s.dispose();
      }
    });

    testWidgets('balance: the beam never leans at level 1 or 2; level 3 lets it go and marks the tile', (
      WidgetTester t,
    ) async {
      for (final BalanceActivity a in all<BalanceActivity>()) {
        final LessonController c = controllerFor(a);
        final BalanceSession s = BalanceSession(c, a);
        await lamp(t, c, ms: 3000);
        expect(s.revealed, isFalse, reason: '${a.id} level 1');
        expect(s.litPan, isNull);
        await lamp(t, c, ms: 3000);
        expect(s.revealed, isFalse, reason: '${a.id} level 2');
        expect(s.chosen, isNull);
        expect(s.towers, isTrue);
        await lamp(t, c, ms: 30000);
        expect(s.demoRunning, isFalse, reason: a.id);
        if (a.weigh) {
          expect(s.added, 0, reason: '${a.id}: the blocks come off again');
        } else {
          expect(s.revealed, isTrue, reason: a.id);
          expect(s.chosen, a.result, reason: '${a.id} level 3 ends on the tile');
        }
        s.dispose();
      }
    });

    testWidgets('spot the mistake: no cell is picked out at level 1 or 2; level 3 stops on the mistake', (
      WidgetTester t,
    ) async {
      for (final SpotErrorActivity a in all<SpotErrorActivity>()) {
        final LessonController c = controllerFor(a);
        final SpotErrorSession s = SpotErrorSession(c, a);
        await lamp(t, c, ms: 700 * (a.cells.length + 2));
        expect(s.hintCell, isNull, reason: '${a.id} level 1');
        expect(s.lit, isNull, reason: '${a.id} level 1 rests on no cell');
        await lamp(t, c, ms: 700 * (a.cells.length + 2));
        expect(s.hintCell, isNull, reason: '${a.id} level 2');
        expect(s.barTo, a.cells.length - 1);
        await lamp(t, c, ms: 700 * (a.cells.length + 2));
        expect(s.hintCell, a.wrong, reason: '${a.id} level 3');
        s.dispose();
      }
    });

    testWidgets('tap the answer: no tile is lit or dimmed before the end of level 3 (all 626)', (
      WidgetTester t,
    ) async {
      int n = 0;
      for (final TapAnswerActivity a in all<TapAnswerActivity>()) {
        final LessonController c = controllerFor(a);
        final TapAnswerSession s = TapAnswerSession(c, a);
        await lamp(t, c, ms: 3000);
        await lamp(t, c, ms: 3000);
        expect(c.answerShown, isFalse, reason: a.id);
        s.dispose();
        n++;
      }
      expect(n, 626);
    });

    testWidgets('counting, flash and trace: levels 1 and 2 leave the tiles alone', (WidgetTester t) async {
      for (final CountTapActivity a in all<CountTapActivity>()) {
        final LessonController c = controllerFor(a);
        final CountTapSession s = CountTapSession(c, a);
        await lamp(t, c, ms: 600 * a.count + 3000);
        await lamp(t, c, ms: 600 * a.count + 3000);
        expect(c.answerShown, isFalse, reason: a.id);
        expect(s.chosenId, isNull);
        s.dispose();
      }
      for (final FlashActivity a in all<FlashActivity>()) {
        final LessonController c = controllerFor(a);
        final FlashSession s = FlashSession(c, a);
        await lamp(t, c, ms: 6000);
        await lamp(t, c, ms: 6000);
        expect(c.answerShown, isFalse, reason: a.id);
        s.dispose();
      }
      for (final TraceActivity a in all<TraceActivity>()) {
        final LessonController c = controllerFor(a);
        final TraceSession s = TraceSession(c, a);
        await lamp(t, c, ms: 8000);
        expect(s.showWay, isFalse, reason: '${a.id} level 1 draws only the start');
        await lamp(t, c, ms: 8000);
        expect(s.showWay, isTrue, reason: '${a.id} level 2 draws the whole path');
        s.dispose();
      }
    });
  });

  // ---- each level changes the stage ----

  group('each level changes the stage', () {
    testWidgets(
      'spot the mistake, a row that no family draws (the steps of washing): the light, then the sky bar under the row, then the stop on the mistake',
      (WidgetTester t) async {
        final SpotErrorActivity a = all<SpotErrorActivity>().firstWhere(
          (SpotErrorActivity x) => x.skillId == 'CS-A-05',
        );
        final LessonController c = controllerFor(a);
        final SpotErrorSession s = SpotErrorSession(c, a);
        await host(t, s);
        expect(find.byKey(const Key('spot-bar')), findsNothing);
        c.showHint();
        await pass(t, 800);
        expect(find.byKey(const Key('seen-dot')), findsWidgets);
        expect(find.byKey(const Key('spot-bar')), findsNothing);
        await pass(t, 700 * a.cells.length + 300);
        c.showHint();
        await pass(t, 800);
        expect(find.byKey(const Key('spot-bar')), findsOneWidget);
        await pass(t, 700 * a.cells.length + 300);
        c.showHint();
        await pass(t, 700 * (a.wrong + 1) + 400);
        expect(s.hintCell, a.wrong);
        await end(t, s);
      },
    );

    testWidgets('number line, a jump: the hop size pill at level 1, one dot used at level 2', (
      WidgetTester t,
    ) async {
      final NumberLineActivity a = all<NumberLineActivity>().firstWhere(
        (NumberLineActivity x) => x.jump && x.hops.length >= 2,
      );
      final LessonController c = controllerFor(a);
      final NumberLineSession s = NumberLineSession(c, a);
      await host(t, s);
      c.showHint();
      await pass(t, 300);
      expect(find.byKey(const Key('hop-pill')), findsOneWidget);
      expect(find.byKey(const Key('hop-dot')), findsNWidgets(a.hops.first.abs()));
      c.showHint();
      await pass(t, 1500);
      expect(find.byKey(const Key('hop-dot-used')), findsOneWidget);
      await end(t, s);
    });

    testWidgets(
      'clock: the card with the hour at level 1, the ring on the dial at level 2, the steps at level 3',
      (WidgetTester t) async {
        final ClockSetActivity a = all<ClockSetActivity>().first;
        final LessonController c = controllerFor(a);
        final ClockSetSession s = ClockSetSession(c, a);
        await host(t, s);
        expect(find.byKey(const Key('clock-hour-card')), findsNothing);
        c.showHint();
        await pass(t, 300);
        expect(find.byKey(const Key('clock-hour-card')), findsOneWidget);
        expect(s.numeralRing, isFalse);
        c.showHint();
        await pass(t, 300);
        expect(s.numeralRing, isTrue);
        c.showHint();
        await pass(t, 400);
        expect(s.demoRunning, isTrue, reason: 'the guide moves the short hand');
        await pass(t, 800 * 12 + 2000);
        expect(s.ghost, isTrue);
        await end(t, s);
      },
    );

    testWidgets(
      'balance: each pan lights in turn; then the towers and the level line; the beam stays level until level 3',
      (WidgetTester t) async {
        final BalanceActivity a = all<BalanceActivity>().firstWhere(
          (BalanceActivity x) => x.hideTilt && !x.weigh,
        );
        final LessonController c = controllerFor(a);
        final BalanceSession s = BalanceSession(c, a);
        await host(t, s);
        c.showHint();
        await pass(t, 300);
        expect(find.byKey(const Key('pan-lit')), findsOneWidget);
        await pass(t, 2000);
        expect(find.byKey(const Key('pan-lit')), findsNothing);
        c.showHint();
        await pass(t, 300);
        expect(find.byKey(const Key('hint-line')), findsOneWidget);
        expect(find.byKey(const Key('hint-block')), findsWidgets);
        expect(find.byKey(const Key('pan-lit')), findsNothing);
        expect(s.lean, 0, reason: 'a hidden tilt stays hidden');
        await end(t, s);
      },
    );

    testWidgets('robot: the flag and the robot glow at level 1; a ghost robot one step on at level 2', (
      WidgetTester t,
    ) async {
      final RobotPathActivity a = all<RobotPathActivity>().first;
      final LessonController c = controllerFor(a);
      final RobotPathSession s = RobotPathSession(c, a);
      await host(t, s);
      expect(find.byKey(const Key('robot-ghost')), findsNothing);
      c.showHint();
      await pass(t, 300);
      expect(s.spotlight, isTrue);
      expect(find.byKey(const Key('robot-ghost')), findsNothing);
      c.showHint();
      await pass(t, 300);
      expect(find.byKey(const Key('robot-ghost')), findsOneWidget);
      await end(t, s);
    });

    testWidgets(
      'build a pattern with a model: the light walks the model, then rests on the cell above the next place',
      (WidgetTester t) async {
        final BuildPatternActivity a = all<BuildPatternActivity>().firstWhere(
          (BuildPatternActivity x) => x.model.isNotEmpty,
        );
        final LessonController c = controllerFor(a);
        final BuildPatternSession s = BuildPatternSession(c, a);
        await host(t, s);
        c.showHint();
        await pass(t, 200);
        expect(find.byKey(const Key('model-lit')), findsOneWidget);
        await pass(t, 450 * (a.model.length + 2));
        expect(
          find.byKey(const Key('model-lit')),
          findsNothing,
          reason: 'level 1 ends on a place, not on the model',
        );
        c.showHint();
        await pass(t, 300);
        expect(
          find.byKey(const Key('model-lit')),
          findsOneWidget,
          reason: 'level 2 keeps the cell above the place',
        );
        await end(t, s);
      },
    );

    testWidgets(
      'shop: the price and the counter glow; a coin goes on at level 2; the running total at level 3',
      (WidgetTester t) async {
        final ShopPayActivity a = all<ShopPayActivity>().firstWhere((ShopPayActivity x) {
          final ShopPaySession probe = ShopPaySession(controllerFor(x), x);
          final bool several = probe.solution().length > 1;
          probe.dispose();
          return several;
        });
        final LessonController c = controllerFor(a);
        final ShopPaySession s = ShopPaySession(c, a);
        await host(t, s);
        c.showHint();
        await pass(t, 300);
        expect(s.lightPrice, isTrue);
        expect(s.onCounter, isEmpty);
        c.showHint();
        await pass(t, 300);
        expect(s.onCounter, hasLength(1), reason: 'the biggest coin of the way, and no more');
        c.showHint();
        await pass(t, 1600);
        expect(find.byKey(const Key('running-total')), findsOneWidget);
        await end(t, s);
      },
    );

    testWidgets('flash: level 2 shows the number again as hands while the group is in view', (
      WidgetTester t,
    ) async {
      final FlashActivity a = all<FlashActivity>().first;
      final LessonController c = controllerFor(a);
      final FlashSession s = FlashSession(c, a);
      await host(t, s);
      await pass(t, FlashSession.startDelay.inMilliseconds + a.flashMs + 600);
      c.showHint(); // level 1: the group again, longer
      await pass(t, 200);
      expect(s.visible, isTrue);
      expect(find.byKey(const Key('fingers-hint')), findsNothing);
      await pass(t, a.flashMs * 2 + 600);
      c.showHint(); // level 2: and the same number as hands
      await pass(t, 200);
      expect(s.aid, isTrue);
      expect(raised(t), a.group.count);
      await end(t, s);
    });

    testWidgets(
      'tap the answer: the tiles are not touched by level 1 or 2, and nothing is dimmed before level 3 ends',
      (WidgetTester t) async {
        final TapAnswerActivity a = all<TapAnswerActivity>().firstWhere(
          (TapAnswerActivity x) => x.optionsInTiles,
        );
        final LessonController c = controllerFor(a);
        final TapAnswerSession s = TapAnswerSession(c, a);
        await host(t, s);
        c.showHint();
        await pass(t, 3000);
        c.showHint();
        await pass(t, 3000);
        final List<AnswerState> states = <AnswerState>[
          for (final AnswerTile tile in t.widgetList<AnswerTile>(find.byType(AnswerTile))) tile.state,
        ];
        expect(states, everyElement(AnswerState.idle));
        expect(t.widgetList<Opacity>(find.byType(Opacity)).where((Opacity o) => o.opacity < 1), isEmpty);
        await end(t, s);
      },
    );
  });

  // ---- the guided state: the demonstration first, then the halo ----

  group('the guided state starts with the demonstration', () {
    testWidgets(
      'count and tap: three mistakes, the guide counts, and only then the right tile has its halo',
      (WidgetTester t) async {
        final CountTapActivity a = content.activities['count.butterflies.3']! as CountTapActivity;
        final LessonController c = controllerFor(a);
        final CountTapSession s = CountTapSession(c, a);
        await host(t, s);
        final String wrong = a.options.firstWhere((ChoiceOption o) => o.id != a.correctId).id;
        for (int k = 0; k < 3; k++) {
          for (int i = 0; i < a.count; i++) {
            s.tapObject(i);
            await pass(t, 100);
          }
          await s.choose(wrong);
          await pass(t, 1300);
          if (k < 2) await pass(t, 1500);
        }
        expect(c.guided, isTrue);
        expect(c.answerShown, isFalse, reason: 'the guide is counting');
        expect(s.demoRunning, isTrue);
        AnswerTile tile() => t.widget<AnswerTile>(find.byKey(Key('tile-${a.correctId}')));
        expect(tile().state, isNot(AnswerState.selected));
        await pass(t, 300 + 800 * a.count + 1500);
        expect(c.answerShown, isTrue);
        expect(tile().state, AnswerState.selected);
        await end(t, s);
      },
    );
  });

  // ---- A8: the row comes in from the left ----

  group('a row appears one cell at a time from the left (A8)', () {
    testWidgets('with reduce motion every cell is there at once, with a still start dot under the first', (
      WidgetTester t,
    ) async {
      final TapAnswerActivity a = all<TapAnswerActivity>().firstWhere(
        (TapAnswerActivity x) => x.row.isNotEmpty,
      );
      final TapAnswerSession s = TapAnswerSession(controllerFor(a), a);
      await host(t, s);
      expect(find.byKey(const Key('row-start-dot')), findsOneWidget);
      final Rect dot = t.getRect(find.byKey(const Key('row-start-dot')));
      final Rect row = t.getRect(find.byKey(const Key('tap-row')));
      expect(
        dot.center.dx,
        lessThan(row.left + row.width / a.row.length),
        reason: 'the dot is under the leftmost cell',
      );
      await end(t, s);
    });

    testWidgets('without reduce motion the cells fade in from the left, 120 ms apart, the last cell last', (
      WidgetTester t,
    ) async {
      final TapAnswerActivity a = all<TapAnswerActivity>().firstWhere(
        (TapAnswerActivity x) => x.row.length >= 4,
      );
      final TapAnswerSession s = TapAnswerSession(controllerFor(a), a);
      await host(t, s, reduceMotion: false);
      expect(find.byKey(const Key('row-start-dot')), findsNothing);
      double opacityOf(int i) {
        final Finder cells = find.descendant(
          of: find.byKey(const Key('tap-row')),
          matching: find.byType(FadeTransition),
        );
        return t.widget<FadeTransition>(cells.at(i)).opacity.value;
      }

      await t.pump(const Duration(milliseconds: 150));
      expect(opacityOf(0), greaterThan(0.5), reason: 'the first cell is already there');
      expect(opacityOf(a.row.length - 1), 0, reason: 'the last cell (the gap) is not');
      await t.pump(RowEntrance.step * (a.row.length + 2));
      expect(opacityOf(a.row.length - 1), 1);
      await end(t, s);
    });

    testWidgets('build a pattern: the model comes first, from the left, and the places after it', (
      WidgetTester t,
    ) async {
      final BuildPatternActivity a = all<BuildPatternActivity>().firstWhere(
        (BuildPatternActivity x) => x.model.length >= 3,
      );
      final BuildPatternSession s = BuildPatternSession(controllerFor(a), a);
      await host(t, s, reduceMotion: false);
      await t.pump(const Duration(milliseconds: 150));
      final Finder modelCells = find.descendant(
        of: find.byKey(const Key('pattern-model')),
        matching: find.byType(FadeTransition),
      );
      final Finder slotCells = find.descendant(
        of: find.byKey(const Key('pattern-slots')),
        matching: find.byType(FadeTransition),
      );
      expect(t.widget<FadeTransition>(modelCells.first).opacity.value, greaterThan(0.5));
      expect(
        t.widget<FadeTransition>(slotCells.first).opacity.value,
        0,
        reason: 'the places wait for the model',
      );
      await t.pump(RowEntrance.step * (a.model.length + a.slots + 3));
      expect(t.widget<FadeTransition>(slotCells.last).opacity.value, 1);
      await end(t, s);
    });

    testWidgets('spot the mistake: the row never mirrors, the first cell is at the left', (
      WidgetTester t,
    ) async {
      final SpotErrorActivity a = all<SpotErrorActivity>().first;
      final SpotErrorSession s = SpotErrorSession(controllerFor(a), a);
      await host(t, s);
      final double first = t.getCenter(find.byKey(const Key('cell-0'))).dx;
      final double last = t.getCenter(find.byKey(Key('cell-${a.cells.length - 1}'))).dx;
      expect(first, lessThan(last));
      expect(find.byKey(const Key('row-start-dot')), findsOneWidget);
      await end(t, s);
    });
  });
}
