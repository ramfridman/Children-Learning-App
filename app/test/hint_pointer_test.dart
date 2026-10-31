import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/child/activity_shell.dart';
import 'package:nitznutz/content/models.dart';
import 'package:nitznutz/play/count_tap_session.dart';
import 'package:nitznutz/play/flash_session.dart';
import 'package:nitznutz/play/give_n_session.dart';
import 'package:nitznutz/play/hint_hand.dart';
import 'package:nitznutz/play/hints/hint_marks.dart';
import 'package:nitznutz/play/hints/pointer_plans.dart';
import 'package:nitznutz/play/lesson_controller.dart';
import 'package:nitznutz/play/spot_error_session.dart';
import 'package:nitznutz/play/trace_session.dart';
import 'package:nitznutz/play/template_session.dart';

import 'support/fakes.dart';
import 'support/harness.dart';
import 'support/starter.dart';

/// B-40 part 3: the pointing hand of the worked example in count and tap, give N and flash. The hand touches each thing in turn,
/// a badge stays on it, the hand leaves, and the session's own demonstration runs as before; with "reduce motion" the same
/// pictures appear in the same order.
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

  const ActivitySpec spec = ActivitySpec.phone;

  Future<void> host(WidgetTester tester, TemplateSession s, {bool reduceMotion = true}) async {
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
                  height: spec.stage.height + 200,
                  child: Column(
                    children: <Widget>[
                      SizedBox(
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

  group('the plans', () {
    test('count: the hand reaches each thing in turn, the badge of each stays, and nothing stays after the demonstration', () {
      final List<Offset> at = <Offset>[const Offset(20, 30), const Offset(80, 40), const Offset(140, 30)];
      final HintPlan p = pointerCountPlan(at, badges: true, badgeAt: (int i) => at[i] + const Offset(8, -8));
      final List<HandMark> hands = <HandMark>[
        for (final HintFrame f in p.frames) ...f.marks.whereType<HandMark>(),
      ];
      expect(hands.map((HandMark h) => h.tip), at);
      expect(hands.every((HandMark h) => h.press), isTrue);
      expect(p.frames[1].marks.whereType<BadgeMark>().map((BadgeMark b) => b.n), <int>[1, 2]);
      expect(p.frames.last.marks.whereType<HandMark>(), isEmpty, reason: 'the hand leaves');
      expect(p.frames.last.marks.whereType<BadgeMark>(), hasLength(3));
      expect(p.rest, isEmpty);
      // The hand is at the first thing 300 ms before the session counts it (it travels 450 ms), and 800 ms apart after.
      expect(p.frames.first.hold, const Duration(milliseconds: 650));
      expect(p.frames[1].hold, const Duration(milliseconds: 800));
      expect(
        pointerCountPlan(at, badges: false).frames.expand((HintFrame f) => f.marks).whereType<BadgeMark>(),
        isEmpty,
      );
    });

    test('give: the hand takes each one from the pile and puts it on the flower, in the order the guide gives them', () {
      final List<Offset> pile = <Offset>[const Offset(10, 10), const Offset(40, 10), const Offset(70, 10)];
      final List<Offset> slots = <Offset>[
        const Offset(200, 20),
        const Offset(230, 20),
        const Offset(200, 60),
      ];
      final HintPlan p = pointerGivePlan(pile, slots);
      final List<Offset> tips = <Offset>[
        for (final HintFrame f in p.frames) ...f.marks.whereType<HandMark>().map((HandMark h) => h.tip),
      ];
      expect(tips, <Offset>[pile[0], slots[0], pile[1], slots[1], pile[2], slots[2]]);
      expect(p.frames.last.marks.whereType<BadgeMark>().map((BadgeMark b) => b.n), <int>[1, 2, 3]);
      expect(p.rest, isEmpty);
      // Each one is taken 800 ms after the one before (the session's own step).
      final int firstPile = p.frames[0].hold.inMilliseconds + p.frames[1].hold.inMilliseconds;
      expect(firstPile + p.frames[2].hold.inMilliseconds + p.frames[3].hold.inMilliseconds - firstPile, 800);
    });

    test(
      'flash: the pictures of the group are counted in reading order, and the last badge is the count',
      () {
        final List<Offset> c = flashObjectCentres(
          const Size(330, 128),
          128,
          arrangement: 'scatter',
          count: 5,
          seed: 3,
          scale: 1,
        );
        expect(c, hasLength(5));
        final HintPlan p = pointerFlashPlan(c);
        expect(p.frames.last.marks.whereType<BadgeMark>().last.n, 5);
        expect(
          p.length,
          lessThan(const Duration(milliseconds: 4500)),
          reason: 'it ends before the group is covered again',
        );
      },
    );
  });

  group('on the lesson stage', () {
    testWidgets(
      'count and tap: the hand counts each apple in turn at level 3, and leaves; the answer is on offer after',
      (WidgetTester t) async {
        await t.runAsync(warmHintHands);
        final CountTapActivity a = content.activities['count.apples.7']! as CountTapActivity;
        final LessonController c = controllerFor(a);
        final CountTapSession s = CountTapSession(c, a);
        await host(t, s);
        expect(find.byKey(const Key('hint-p12')), findsNothing);
        c.showHint();
        await pass(t, 9000);
        c.showHint();
        await pass(t, 12000);
        expect(find.byKey(const Key('hint-p12')), findsNothing, reason: 'no hand before level 3');
        c.showHint();
        await pass(t, 2500);
        expect(find.byKey(const Key('hint-p12')), findsOneWidget, reason: 'the hand is counting');
        expect(s.counter, greaterThan(0));
        await pass(t, 800 * a.count);
        expect(s.counter, a.count);
        await pass(t, 3000);
        expect(find.byKey(const Key('hint-p12')), findsNothing, reason: 'the hand leaves');
        expect(s.answering, isTrue);
        expect(
          find.byKey(const Key('hint-badge')),
          findsNothing,
          reason: 'the badges go with the demonstration',
        );
        s.dispose();
        await t.pumpWidget(const SizedBox());
      },
    );

    testWidgets(
      'give N: the hand carries each butterfly to the flower at level 3, and leaves; the flower is emptied',
      (WidgetTester t) async {
        await t.runAsync(warmHintHands);
        final GiveNActivity a = content.activities['give.butterflies.4']! as GiveNActivity;
        final LessonController c = controllerFor(a);
        final GiveNSession s = GiveNSession(c, a);
        await host(t, s);
        c.showHint();
        await pass(t, 3000);
        c.showHint();
        await pass(t, 9000);
        expect(find.byKey(const Key('hint-p12')), findsNothing, reason: 'no hand before level 3');
        c.showHint();
        await pass(t, 2000);
        expect(find.byKey(const Key('hint-p12')), findsOneWidget);
        expect(s.placed, isNotEmpty);
        await pass(t, 2000);
        expect(find.byKey(const Key('hint-badge')), findsWidgets, reason: 'a badge on each one given');
        await pass(t, 6000);
        expect(find.byKey(const Key('hint-p12')), findsNothing);
        expect(s.placed, isEmpty, reason: 'the flower is emptied for the child');
        s.dispose();
        await t.pumpWidget(const SizedBox());
      },
    );

    testWidgets(
      'flash: the group stays in view at level 3 and the hand counts its pictures, a badge on each',
      (WidgetTester t) async {
        await t.runAsync(warmHintHands);
        final FlashActivity a = content.activities['flash.dice.3']! as FlashActivity;
        final LessonController c = controllerFor(a);
        final FlashSession s = FlashSession(c, a);
        await host(t, s);
        await pass(t, 4000);
        c.showHint();
        await pass(t, 6000);
        c.showHint();
        await pass(t, 6000);
        expect(find.byKey(const Key('hint-p12')), findsNothing, reason: 'no hand before level 3');
        c.showHint();
        await pass(t, 1500);
        expect(find.byKey(const Key('hint-p12')), findsOneWidget);
        expect(find.byKey(const Key('flash-group')), findsOneWidget, reason: 'the group stays in view');
        await pass(t, 800);
        expect(
          find.byKey(const Key('hint-badge')),
          findsNWidgets(a.group.count),
          reason: 'the last badge is the count',
        );
        await pass(t, 3000);
        expect(find.byKey(const Key('hint-p12')), findsNothing);
        s.dispose();
        await t.pumpWidget(const SizedBox());
      },
    );

    testWidgets('trace: the hand goes with the dot along the whole stroke at level 3 only, and leaves', (
      WidgetTester t,
    ) async {
      await t.runAsync(warmHintHands);
      final TraceActivity a = content.activities['x.shpa02.1']! as TraceActivity;
      final LessonController c = controllerFor(a);
      final TraceSession s = TraceSession(c, a);
      await host(t, s);
      c.showHint();
      await pass(t, 1500);
      expect(find.byKey(const Key('hint-p12')), findsNothing, reason: 'level 1 walks a dot only');
      await pass(t, 6000);
      c.showHint();
      await pass(t, 1500);
      expect(
        find.byKey(const Key('hint-p12')),
        findsNothing,
        reason: 'level 2 walks a dot and draws the way',
      );
      await pass(t, 6000);
      c.showHint();
      await pass(t, 1000);
      expect(
        find.byKey(const Key('hint-p12')),
        findsOneWidget,
        reason: 'level 3: the hand goes with the dot',
      );
      final Offset early = t.getTopLeft(find.byKey(const Key('hint-p12')));
      await pass(t, 800);
      expect(
        t.getTopLeft(find.byKey(const Key('hint-p12'))),
        isNot(early),
        reason: 'it moves along the stroke',
      );
      await pass(t, 6000);
      expect(find.byKey(const Key('hint-p12')), findsNothing, reason: 'it leaves when the stroke is done');
      s.dispose();
      await t.pumpWidget(const SizedBox());
    });

    testWidgets(
      'spot the mistake: the hand reads the row from the left with the light, stops on the mistake, and leaves',
      (WidgetTester t) async {
        await t.runAsync(warmHintHands);
        final SpotErrorActivity a = content.activities['b15.cola02.5']! as SpotErrorActivity;
        final LessonController c = controllerFor(a);
        final SpotErrorSession s = SpotErrorSession(c, a);
        await host(t, s);
        c.showHint();
        await pass(t, 9000);
        c.showHint();
        await pass(t, 9000);
        expect(find.byKey(const Key('hint-p12')), findsNothing, reason: 'no hand before level 3');
        c.showHint();
        await pass(t, 800);
        expect(find.byKey(const Key('hint-p12')), findsOneWidget);
        final List<Offset> cells = SpotErrorSession.cellCentres(spec.stage.size, a.cells.length);
        expect(
          cells.map((Offset o) => o.dx).toList(),
          orderedEquals(<double>[...cells.map((Offset o) => o.dx)]..sort()),
        );
        await pass(t, 700 * (a.wrong + 1) + 600);
        expect(
          find.byKey(const Key('hint-p12')),
          findsNothing,
          reason: 'the hand leaves where the light stops',
        );
        expect(s.hintCell, a.wrong, reason: 'the mistake is picked out at the end of the walk');
        s.dispose();
        await t.pumpWidget(const SizedBox());
      },
    );

    testWidgets('with motion allowed the hand travels and the same hint plays', (WidgetTester t) async {
      await t.runAsync(warmHintHands);
      final CountTapActivity a = content.activities['count.apples.7']! as CountTapActivity;
      final LessonController c = controllerFor(a);
      final CountTapSession s = CountTapSession(c, a);
      await host(t, s, reduceMotion: false);
      c.showHint();
      await pass(t, 9000);
      c.showHint();
      await pass(t, 12000);
      c.showHint();
      await pass(t, 2500);
      expect(find.byKey(const Key('hint-p12')), findsOneWidget);
      await pass(t, 9000);
      expect(s.answering, isTrue);
      s.dispose();
      await t.pumpWidget(const SizedBox());
    });
  });
}
