import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/child/activity_shell.dart';
import 'package:nitznutz/content/models.dart';
import 'package:nitznutz/play/clock_set_session.dart';
import 'package:nitznutz/play/hint_hand.dart';
import 'package:nitznutz/play/lesson_controller.dart';
import 'package:nitznutz/play/match_pairs_session.dart';
import 'package:nitznutz/play/number_line_session.dart';
import 'package:nitznutz/play/template_session.dart';

import 'support/fakes.dart';
import 'support/harness.dart';
import 'support/starter.dart';

/// B-40 part 4, the Band B templates: the number line (an arc and a number for each hop, left to right), the clock (a link from
/// the card to the numeral, the hours numbered on the dial, the hand pressing the plus tile) and match with coins and solids.
/// Level 1 and 2 never mark the answer; level 3 is the pointing hand, and then the turn is the child's.
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

  /// The stage, the hand's layer over it and the tiles, placed as the lesson screen places them.
  Future<void> host(WidgetTester tester, TemplateSession s) async {
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
                    child: s.buildTiles(ctx, spec) ?? const SizedBox(),
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

  /// The lamp, [times] times: the levels before the last play for 12 s each, the last one for [last] ms.
  Future<void> lamp(WidgetTester t, LessonController c, int times, {int last = 0}) async {
    for (int i = 1; i <= times; i++) {
      c.showHint();
      await t.pump(const Duration(milliseconds: 1));
      await pass(t, i < times ? 12000 : last);
    }
  }

  Future<void> end(WidgetTester t, TemplateSession s) async {
    s.dispose();
    await t.pumpWidget(const SizedBox());
  }

  List<T> all<T extends Activity>() => content.activities.values.whereType<T>().toList();

  final Finder hand = find.byKey(const Key('hint-p12'));
  Finder badge(String n) => find.descendant(of: find.byKey(const Key('hint-badge')), matching: find.text(n));

  group('number line', () {
    testWidgets(
      'a jump counted in units: an arc and a number for each hop, left to right, the hand on each landing',
      (WidgetTester t) async {
        await t.runAsync(warmHintHands);
        // From 2, a hop of three, to 5.
        final NumberLineActivity a = content.activities['b.numb13.13']! as NumberLineActivity;
        final LessonController c = controllerFor(a);
        final NumberLineSession s = NumberLineSession(c, a);
        await host(t, s);
        c.showHint();
        await pass(t, 1500);
        expect(find.byKey(const Key('hint-arc')), findsNothing, reason: 'level 1 draws no hop');
        c.showHint();
        await t.pump(const Duration(milliseconds: 1));
        await pass(t, 1500);
        expect(find.byKey(const Key('hint-arc')), findsOneWidget, reason: 'level 2: one unit hop');
        expect(badge('1'), findsOneWidget);
        expect(hand, findsNothing);
        c.showHint();
        await t.pump(const Duration(milliseconds: 1));
        await pass(t, 500 * 2 + 100);
        expect(hand, findsOneWidget);
        await pass(t, 500 * 3);
        expect(find.byKey(const Key('hint-arc')), findsNWidgets(3), reason: 'three units, three arcs');
        for (final String n in <String>['1', '2', '3']) {
          expect(badge(n), findsOneWidget);
        }
        expect(s.markerAt, 5, reason: 'the marker has landed');
        await pass(t, 1500);
        expect(hand, findsNothing, reason: 'the hand leaves at the end');
        await end(t, s);
      },
    );

    testWidgets(
      'the answer is shown only when the demonstration is over, and the tick it lands on stays lit',
      (WidgetTester t) async {
        await t.runAsync(warmHintHands);
        // From 8 back by 2 and 3 to 3.
        final NumberLineActivity a = content.activities['b.numb13.19']! as NumberLineActivity;
        final LessonController c = controllerFor(a);
        final NumberLineSession s = NumberLineSession(c, a);
        await host(t, s);
        await lamp(t, c, 3, last: 100);
        expect(s.demoRunning, isTrue);
        await pass(t, 500 * 8 + 1500);
        expect(s.demoRunning, isFalse);
        expect(s.trail, contains(3));
        await end(t, s);
      },
    );

    testWidgets(
      'a line that is put on by touch counts the way with one number over the marker, and has no arcs',
      (WidgetTester t) async {
        await t.runAsync(warmHintHands);
        // To 13 on a line to 20.
        final NumberLineActivity a = content.activities['b.numb13.7']! as NumberLineActivity;
        final LessonController c = controllerFor(a);
        final NumberLineSession s = NumberLineSession(c, a);
        await host(t, s);
        await lamp(t, c, 3, last: 380 * 4);
        expect(find.byKey(const Key('hint-arc')), findsNothing);
        expect(find.byKey(const Key('hint-badge')), findsOneWidget, reason: 'one running number');
        await pass(t, 380 * 10 + 2500);
        expect(s.demoRunning, isFalse);
        expect(s.trail, contains(a.target));
        await end(t, s);
      },
    );

    testWidgets(
      'every number line item plays its three levels: no hand before level 3, the answer tick lit only at its end',
      (WidgetTester t) async {
        await t.runAsync(warmHintHands);
        for (final NumberLineActivity a in all<NumberLineActivity>()) {
          final LessonController c = controllerFor(a);
          final NumberLineSession s = NumberLineSession(c, a);
          await host(t, s);
          for (int level = 1; level <= 3; level++) {
            c.showHint();
            await t.pump(const Duration(milliseconds: 1));
            await pass(t, level < 3 ? 1500 : 800);
            expect(hand, level < 3 ? findsNothing : findsOneWidget, reason: '${a.id} level $level');
            if (level < 3) {
              expect(s.trail, isNot(contains(a.target)), reason: '${a.id}: no answer tick at level $level');
            }
          }
          await pass(t, 500 * 22 + 2000);
          expect(s.demoRunning, isFalse, reason: a.id);
          expect(s.trail, contains(a.target), reason: a.id);
          await end(t, s);
        }
      },
    );
  });

  group('clock', () {
    testWidgets(
      'level 2 rings the card like the numeral on the dial; level 3 numbers the hours the short hand passes',
      (WidgetTester t) async {
        await t.runAsync(warmHintHands);
        final ClockSetActivity a = content.activities['x.mathb15.1']! as ClockSetActivity;
        final LessonController c = controllerFor(a);
        final ClockSetSession s = ClockSetSession(c, a);
        await host(t, s);
        c.showHint();
        await pass(t, 1500);
        expect(find.byKey(const Key('clock-hour-card')), findsOneWidget);
        expect(find.byKey(const Key('hint-p2')), findsNothing, reason: 'level 1: the card, not ringed yet');
        c.showHint();
        await t.pump(const Duration(milliseconds: 1));
        await pass(t, 1500);
        expect(
          find.byKey(const Key('hint-p2')),
          findsOneWidget,
          reason: 'level 2: the card is ringed like the numeral on the dial',
        );
        expect(hand, findsNothing);
        c.showHint();
        await t.pump(const Duration(milliseconds: 1));
        await pass(t, 800 * 2 + 400);
        expect(hand, findsOneWidget, reason: 'level 3: the hand is on the plus tile');
        final int steps = (a.hour - a.startHour + 12) % 12;
        await pass(t, 800 * steps);
        expect(
          find.byKey(const Key('hint-badge')),
          findsNWidgets(steps),
          reason: 'one number for each hour passed',
        );
        await pass(t, 2500);
        expect(hand, findsNothing);
        expect(s.ghost, isTrue, reason: 'the faint hands stay where the time belongs');
        await end(t, s);
      },
    );
  });

  group('match, coins and solids', () {
    testWidgets(
      'level 2 shows a coin as that many dots and a solid as the print of its face; levels 1 and 2 pair nothing',
      (WidgetTester t) async {
        await t.runAsync(warmHintHands);
        for (final (String id, Key shown) in <(String, Key)>[
          ('x.mathb16.1', const Key('dot-row')),
          ('x.shpb09.1', const Key('hint-p9')),
        ]) {
          final MatchPairsActivity a = content.activities[id]! as MatchPairsActivity;
          final LessonController c = controllerFor(a);
          final MatchPairsSession s = MatchPairsSession(c, a);
          await host(t, s);
          c.showHint();
          await pass(t, 4000);
          expect(find.byKey(shown), findsNothing, reason: '$id level 1');
          c.showHint();
          await t.pump(const Duration(milliseconds: 1));
          await pass(t, 1000);
          expect(find.byKey(shown), findsOneWidget, reason: '$id level 2');
          expect(find.byKey(const Key('hint-p5')), findsNothing, reason: '$id level 2 draws no pair line');
          expect(hand, findsNothing);
          await end(t, s);
        }
      },
    );
  });
}
