import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/child/activity_shell.dart';
import 'package:nitznutz/content/models.dart';
import 'package:nitznutz/play/build_pattern_session.dart';
import 'package:nitznutz/play/hint_hand.dart';
import 'package:nitznutz/play/hints/hint_marks.dart';
import 'package:nitznutz/play/hints/right_cell.dart';
import 'package:nitznutz/play/lesson_controller.dart';
import 'package:nitznutz/play/match_pairs_session.dart';
import 'package:nitznutz/play/robot_path_session.dart';
import 'package:nitznutz/play/shape_builder_session.dart';
import 'package:nitznutz/play/sort_drag_session.dart';
import 'package:nitznutz/play/spot_error_session.dart';
import 'package:nitznutz/play/template_session.dart';

import 'support/fakes.dart';
import 'support/harness.dart';
import 'support/starter.dart';

/// B-40 part 3, the rest of Band A: sort and share, build a pattern, match, shape builder, robot and spot the mistake. Level 1 and
/// 2 never mark the answer; level 3 is the pointing hand, taking the answer to its place as the last step, and then the turn is
/// the child's. With "reduce motion" the same pictures appear in the same order.
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

  /// Where the hand's fingertip is now, in the stage's own points (the ripple of its last press names the place), or null.
  Offset? handTip(WidgetTester t) {
    for (final Element e in find.byWidgetPredicate((Widget w) => w.key is ValueKey<String>).evaluate()) {
      final String k = (e.widget.key! as ValueKey<String>).value;
      if (!k.startsWith('ripple-')) continue;
      final List<String> p = k.split('-');
      return Offset(double.parse(p[1]), double.parse(p[2]));
    }
    return null;
  }

  /// A point of the board (as the tests host it) in the stage's own points.
  Offset inStage(Offset board) => board - Offset(spec.stage.left, spec.stage.top);

  /// The middle of the top edge of the tile that [f] finds, in the stage's own points, [slop] under the widget's top.
  Offset tileTopOf(WidgetTester t, Finder f, double slop) {
    final Rect r = t.getRect(f);
    return inStage(Offset(r.center.dx, r.top + slop));
  }

  void near(Offset a, Offset b, String why) {
    expect((a - b).distance, lessThan(3), reason: '$why: $a is not $b');
  }

  // ---- spot the mistake ----

  group('spot the mistake: the right one', () {
    testWidgets('level 3 stops the hand on the mistake and a sky card shows what belongs there', (
      WidgetTester t,
    ) async {
      await t.runAsync(warmHintHands);
      final SpotErrorActivity a = content.activities['b15.numa01.4']! as SpotErrorActivity;
      final LessonController c = controllerFor(a);
      final SpotErrorSession s = SpotErrorSession(c, a);
      await host(t, s);
      await lamp(t, c, 2);
      expect(find.byKey(const Key('hint-card')), findsNothing, reason: 'no right one before level 3');
      await lamp(t, c, 1, last: 700 * (a.wrong + 1) + 500);
      expect(hand, findsNothing, reason: 'the hand has left');
      expect(find.byKey(const Key('hint-card')), findsOneWidget);
      expect(
        find.descendant(of: find.byKey(const Key('hint-card')), matching: find.text('3')),
        findsOneWidget,
        reason: 'the row counts 1, 2, 3, 4, 5: a 3 belongs where the 4 stands twice',
      );
      expect(s.hintCell, a.wrong);
      // The card stands over the mistake, not over another cell.
      final Offset mistake = SpotErrorSession.cellCentres(spec.stage.size, a.cells.length)[a.wrong];
      expect(inStage(t.getCenter(find.byKey(const Key('hint-card')))).dx, closeTo(mistake.dx, 1));
      await end(t, s);
    });

    testWidgets('a child who touches a cell clears the card', (WidgetTester t) async {
      await t.runAsync(warmHintHands);
      final SpotErrorActivity a = content.activities['b15.numa01.4']! as SpotErrorActivity;
      final LessonController c = controllerFor(a);
      final SpotErrorSession s = SpotErrorSession(c, a);
      await host(t, s);
      await lamp(t, c, 3, last: 700 * (a.wrong + 1) + 500);
      expect(find.byKey(const Key('hint-card')), findsOneWidget);
      await t.tap(find.byKey(Key('cell-${a.wrong}')));
      await pass(t, 300);
      expect(find.byKey(const Key('hint-card')), findsNothing);
      await end(t, s);
    });

    test(
      'the right cell of a counting row, a repeating row, an all-alike-but-one row and a number sentence',
      () {
        expect(rightCellOf(<String>['n:1', 'n:2', 'n:4', 'n:4', 'n:5'], 2), 'n:3');
        expect(rightCellOf(<String>['n:8', 'n:7', 'n:6', 'n:4', 'n:4'], 3), 'n:5', reason: 'counting back');
        expect(
          rightCellOf(<String>['n:20', 'n:30', 'n:40', 'n:50', 'n:51'], 4),
          'n:60',
          reason: 'the last one',
        );
        expect(rightCellOf(<String>['n:3', 'n:9', 'n:5', 'n:6', 'n:7'], 1), 'n:4');
        expect(rightCellOf(<String>['n:9', 'n:2', 'n:3', 'n:4'], 0), 'n:1', reason: 'the first one');
        expect(
          rightCellOf(<String>['asset:tower_1', 'asset:tower_2', 'asset:tower_2', 'asset:tower_4'], 2),
          'asset:tower_3',
        );
        expect(
          rightCellOf(<String>[
            'asset:cat',
            'asset:dog',
            'asset:cat',
            'asset:dog',
            'asset:dog',
            'asset:dog',
          ], 4),
          'asset:cat',
        );
        expect(
          rightCellOf(<String>['asset:ball_red', 'asset:ball_red', 'asset:ball_orange', 'asset:ball_red'], 2),
          'asset:ball_red',
        );
        expect(
          rightCellOf(<String>['dir:up', 'dir:right', 'dir:up', 'dir:left', 'dir:up', 'dir:right'], 3),
          'dir:right',
        );
        expect(rightCellOf(<String>['n:6', 'op:+', 'n:2', 'op:=', 'n:9'], 4), 'n:8');
        expect(rightCellOf(<String>['n:7', 'op:=', 'n:5', 'op:+', 'n:3'], 4), 'n:2');
        expect(rightCellOf(<String>['n:9', 'op:-', 'n:4', 'op:=', 'n:6'], 4), 'n:5');
      },
    );

    test(
      'a row that does not tell gives no card (a rainbow, the steps of washing, a place outside the row)',
      () {
        expect(
          rightCellOf(<String>[
            'asset:ball_red',
            'asset:ball_orange',
            'asset:ball_purple',
            'asset:ball_green',
            'asset:ball_blue',
            'asset:ball_purple',
          ], 2),
          isNull,
        );
        expect(
          rightCellOf(<String>[
            'asset:step_paste',
            'asset:step_brush',
            'asset:step_soap',
            'asset:step_rinse',
          ], 2),
          isNull,
        );
        expect(rightCellOf(<String>['n:1', 'n:2', 'n:4'], 7), isNull);
      },
    );

    test(
      'every spot-the-mistake activity: the card would make the row right and never repeats the mistake',
      () {
        int told = 0;
        for (final SpotErrorActivity a in all<SpotErrorActivity>()) {
          final String? right = rightCellOf(a.cells, a.wrong);
          if (right == null) continue;
          told++;
          expect(right, isNot(a.cells[a.wrong]), reason: a.id);
        }
        expect(told, greaterThan(50), reason: 'the card is there for most of the 71');
      },
    );
  });

  // ---- sort and share ----

  group('sort and share', () {
    testWidgets(
      'level 1 lights each bin in turn and draws no hand; level 2 glides a copy of the next picture past the bins',
      (WidgetTester t) async {
        await t.runAsync(warmHintHands);
        final SortDragActivity a = content.activities['log.sortdrag.colour']! as SortDragActivity;
        final LessonController c = controllerFor(a);
        final SortDragSession s = SortDragSession(c, a);
        await host(t, s);
        c.showHint();
        await pass(t, 300);
        expect(s.litBin, isNotNull);
        expect(find.byKey(const Key('hint-copy')), findsNothing, reason: 'level 1 only lights the bins');
        expect(hand, findsNothing);
        await pass(t, 3000);
        c.showHint();
        await pass(t, 200);
        expect(find.byKey(const Key('hint-copy')), findsOneWidget, reason: 'the next picture, drawn again');
        final double first = inStage(t.getCenter(find.byKey(const Key('hint-copy')))).dx;
        expect(
          first,
          closeTo(SortDragSession.sampleCentre(spec.stage.size, a.bins.length, 0).dx, 2),
          reason: 'first over the sample of the first bin',
        );
        await pass(t, 700);
        expect(
          inStage(t.getCenter(find.byKey(const Key('hint-copy')))).dx,
          closeTo(SortDragSession.sampleCentre(spec.stage.size, a.bins.length, 1).dx, 2),
          reason: 'then over the sample of the next',
        );
        await pass(t, 1500);
        expect(find.byKey(const Key('hint-copy')), findsNothing, reason: 'it comes to rest nowhere');
        expect(s.hintBin, isNull, reason: 'no bin is chosen');
        await end(t, s);
      },
    );

    testWidgets(
      "level 3: the hand takes the first picture from the tray to its bin, and then it is the child's turn",
      (WidgetTester t) async {
        await t.runAsync(warmHintHands);
        final SortDragActivity a = content.activities['log.sortdrag.colour']! as SortDragActivity;
        final LessonController c = controllerFor(a);
        final SortDragSession s = SortDragSession(c, a);
        await host(t, s);
        await lamp(t, c, 3, last: 700);
        expect(hand, findsOneWidget);
        near(
          handTip(t)!,
          tileTopOf(t, find.byKey(Key('item-${a.items.first.id}')), 4),
          'the fingertip is on the top edge of the first picture of the tray',
        );
        await pass(t, 1500);
        expect(s.placed, isNotEmpty, reason: 'the picture is in the bin');
        final int bin = a.bins.indexWhere((SortBin b) => b.id == a.items.first.bin);
        near(
          handTip(t)!,
          SortDragSession.dropPlace(spec.stage.size, a.bins.length, bin),
          'the hand is in its bin',
        );
        await pass(t, 2500);
        expect(hand, findsNothing);
        expect(s.placed, isEmpty, reason: 'the picture goes back to the tray');
        expect(s.hintBin, a.items.first.bin, reason: 'the bin keeps its halo for the child');
        await end(t, s);
      },
    );

    testWidgets('a child who touches a picture while the hand is at work ends the demonstration at once', (
      WidgetTester t,
    ) async {
      await t.runAsync(warmHintHands);
      final SortDragActivity a = content.activities['log.sortdrag.colour']! as SortDragActivity;
      final LessonController c = controllerFor(a);
      final SortDragSession s = SortDragSession(c, a);
      await host(t, s);
      await lamp(t, c, 3, last: 500);
      expect(hand, findsOneWidget);
      await t.tap(find.byKey(Key('item-${a.items.last.id}')));
      await pass(t, 200);
      expect(hand, findsNothing);
      expect(s.demoRunning, isFalse);
      await end(t, s);
    });

    testWidgets(
      'share: the hand carries each picture from the tray to a plate in turn, then they all go back',
      (WidgetTester t) async {
        await t.runAsync(warmHintHands);
        final SortDragActivity a = content.activities['math.share.apples']! as SortDragActivity;
        expect(a.share, isTrue);
        final LessonController c = controllerFor(a);
        final SortDragSession s = SortDragSession(c, a);
        await host(t, s);
        await lamp(t, c, 2, last: 3000);
        expect(s.placed.length, a.bins.length, reason: 'level 2 dealt one round, one for each friend');
        c.showHint();
        await t.pump(const Duration(milliseconds: 1));
        await pass(t, 200);
        expect(hand, findsOneWidget);
        int most = 0;
        final List<String> order = <String>[];
        for (int ms = 0; ms < 900 * a.items.length + 1800; ms += 100) {
          await pass(t, 100);
          if (s.placed.length > most) {
            most = s.placed.length;
            order.add(s.placed.keys.last);
          }
        }
        expect(most, a.items.length, reason: 'all of them are dealt');
        expect(order, <String>[for (final SortItem i in a.items) i.id], reason: 'in the order of the tray');
        expect(hand, findsNothing);
        expect(s.placed, isEmpty, reason: 'and put back for the child');
        await end(t, s);
      },
    );

    test(
      "the bins are side by side in the language's direction: the first at the right, none over another",
      () {
        for (final int n in <int>[2, 3]) {
          final List<Rect> bins = <Rect>[
            for (int i = 0; i < n; i++) SortDragSession.binRect(spec.stage.size, n, i),
          ];
          for (int i = 1; i < n; i++) {
            expect(bins[i].right, lessThan(bins[i - 1].left), reason: 'bin $i is left of bin ${i - 1}');
          }
          expect(bins.first.right, lessThanOrEqualTo(spec.stage.width));
          expect(bins.last.left, greaterThanOrEqualTo(0));
        }
      },
    );
  });

  // ---- build a pattern ----

  group('build a pattern', () {
    test('the unit of a row: the shortest part that repeats', () {
      expect(BuildPatternSession.unitLength(<String>['a', 'b', 'c', 'a', 'b', 'c']), 3);
      expect(BuildPatternSession.unitLength(<String>['a', 'b', 'a', 'b']), 2);
      expect(BuildPatternSession.unitLength(<String>['a', 'a', 'a', 'a']), 1);
      expect(BuildPatternSession.unitLength(<String>['a', 'b', 'b', 'a', 'b', 'b']), 3);
      expect(BuildPatternSession.unitLength(<String>['a', 'b', 'c']), isNull, reason: 'nothing repeats');
      expect(
        BuildPatternSession.unitLength(<String>['a', 'b', 'a']),
        isNull,
        reason: 'a unit repeats at least once',
      );
    });

    test(
      'the rows run left to right: the first cell is the leftmost, and the places line up with the model',
      () {
        final Size size = spec.stage.size;
        for (int i = 1; i < 6; i++) {
          expect(
            BuildPatternSession.modelCell(size, 6, i).left,
            greaterThan(BuildPatternSession.modelCell(size, 6, i - 1).left),
          );
          expect(
            BuildPatternSession.slotCell(size, 6, i, hasModel: true).left,
            greaterThan(BuildPatternSession.slotCell(size, 6, i - 1, hasModel: true).left),
          );
        }
        expect(
          BuildPatternSession.slotCell(size, 6, 0, hasModel: true).left,
          BuildPatternSession.modelCell(size, 6, 0).left,
        );
      },
    );

    testWidgets(
      'level 2 puts a bracket under each copy of the unit of the model and keeps them, and marks no picture',
      (WidgetTester t) async {
        await t.runAsync(warmHintHands);
        final BuildPatternActivity a = content.activities['log.copy.three']! as BuildPatternActivity;
        final LessonController c = controllerFor(a);
        final BuildPatternSession s = BuildPatternSession(c, a);
        await host(t, s);
        await lamp(t, c, 1, last: 4000);
        expect(
          find.byKey(const Key('hint-bracket')),
          findsNothing,
          reason: 'level 1 walks the row, no brackets',
        );
        await lamp(t, c, 1, last: 400);
        expect(find.byKey(const Key('hint-bracket')), findsOneWidget, reason: 'the first copy');
        await pass(t, 1500);
        expect(find.byKey(const Key('hint-bracket')), findsNWidgets(2), reason: 'three, three: two copies');
        expect(s.hintSprite, isNull, reason: 'no picture of the palette is marked');
        expect(hand, findsNothing);
        await end(t, s);
      },
    );

    testWidgets('a model with nothing that repeats gets no brackets, and a row without a model neither', (
      WidgetTester t,
    ) async {
      await t.runAsync(warmHintHands);
      for (final String id in <String>['log.copy.balloons', 'b.colb06.4']) {
        final BuildPatternActivity a = content.activities[id]! as BuildPatternActivity;
        final LessonController c = controllerFor(a);
        final BuildPatternSession s = BuildPatternSession(c, a);
        await host(t, s);
        await lamp(t, c, 2, last: 4000);
        expect(find.byKey(const Key('hint-bracket')), findsNothing, reason: id);
        await end(t, s);
      }
    });

    testWidgets(
      'level 3: the hand takes each picture from the model to its place, left to right, and the places fill in order',
      (WidgetTester t) async {
        await t.runAsync(warmHintHands);
        final BuildPatternActivity a = content.activities['log.copy.three']! as BuildPatternActivity;
        final LessonController c = controllerFor(a);
        final BuildPatternSession s = BuildPatternSession(c, a);
        await host(t, s);
        await lamp(t, c, 3, last: 300);
        expect(hand, findsOneWidget);
        near(
          handTip(t)!,
          BuildPatternSession.modelCell(spec.stage.size, a.model.length, 0).center,
          'the hand starts at the first picture of the model',
        );
        final List<double> tips = <double>[];
        int filledNow = 0;
        for (int ms = 0; ms < 900 * a.slots + 1300; ms += 100) {
          await pass(t, 100);
          final Offset? tip = handTip(t);
          if (tip != null && (tips.isEmpty || (tip.dx - tips.last).abs() > 1)) tips.add(tip.dx);
          final int now = s.filled.where((String? f) => f != null).length;
          if (now > filledNow) {
            expect(
              s.filled[now - 1],
              a.sequence[now - 1],
              reason: 'place ${now - 1} is filled with its own picture',
            );
            expect(
              s.filled.take(now).every((String? f) => f != null),
              isTrue,
              reason: 'from the left, in order',
            );
            filledNow = now;
          }
        }
        expect(filledNow, a.slots);
        expect(hand, findsNothing);
        expect(s.filled, everyElement(isNull), reason: 'the places are emptied for the child');
        expect(s.hintSprite, a.sequence[0]);
        expect(tips.first, lessThan(tips.last), reason: 'the row is read from the left');
        await end(t, s);
      },
    );

    testWidgets('with no model the hand takes each picture from the palette', (WidgetTester t) async {
      await t.runAsync(warmHintHands);
      final BuildPatternActivity a = content.activities['b.colb06.4']! as BuildPatternActivity;
      final LessonController c = controllerFor(a);
      final BuildPatternSession s = BuildPatternSession(c, a);
      await host(t, s);
      await lamp(t, c, 3, last: 300);
      final int first = a.palette.indexOf(a.sequence.first);
      near(
        handTip(t)!,
        tileTopOf(t, find.byKey(Key('palette-$first')), 6),
        'the fingertip is on the top edge of the first picture that goes in',
      );
      await pass(t, 900 * a.slots + 1500);
      expect(hand, findsNothing);
      await end(t, s);
    });
  });

  // ---- match ----

  group('match', () {
    testWidgets('level 2: the first card, a numeral, shows that many dots under it, and no partner is lit', (
      WidgetTester t,
    ) async {
      await t.runAsync(warmHintHands);
      final MatchPairsActivity a = content.activities['x.numa07.1']! as MatchPairsActivity;
      final LessonController c = controllerFor(a);
      final MatchPairsSession s = MatchPairsSession(c, a);
      await host(t, s);
      await lamp(t, c, 1, last: 4000);
      expect(find.byKey(const Key('dot-row')), findsNothing, reason: 'level 1 only lights the cards');
      await lamp(t, c, 1, last: 500);
      expect(find.byKey(const Key('dot-row')), findsOneWidget);
      final int n = a.left.firstWhere((MatchFace f) => f.id == a.pairs.keys.first).numeral!;
      expect(
        find.descendant(of: find.byKey(const Key('dot-row')), matching: find.byType(Container)),
        findsNWidgets(n),
        reason: 'as many dots as the numeral says',
      );
      expect(s.hintRight, isNull);
      expect(hand, findsNothing);
      await end(t, s);
    });

    testWidgets('the dots go when the card is joined', (WidgetTester t) async {
      await t.runAsync(warmHintHands);
      final MatchPairsActivity a = content.activities['x.numa07.1']! as MatchPairsActivity;
      final LessonController c = controllerFor(a);
      final MatchPairsSession s = MatchPairsSession(c, a);
      await host(t, s);
      await lamp(t, c, 2, last: 500);
      expect(find.byKey(const Key('dot-row')), findsOneWidget);
      final String l = a.pairs.keys.first;
      await t.tap(find.byKey(Key('top-$l')));
      await t.tap(find.byKey(Key('bottom-${a.pairs[l]}')));
      await pass(t, 300);
      expect(find.byKey(const Key('dot-row')), findsNothing);
      await end(t, s);
    });

    testWidgets(
      'level 3: the hand goes to the first card, then to its partner, and draws one dotted line between them',
      (WidgetTester t) async {
        await t.runAsync(warmHintHands);
        final MatchPairsActivity a = content.activities['x.numa07.1']! as MatchPairsActivity;
        final LessonController c = controllerFor(a);
        final MatchPairsSession s = MatchPairsSession(c, a);
        await host(t, s);
        await lamp(t, c, 3, last: 300);
        final int top = a.left.indexWhere((MatchFace f) => f.id == a.pairs.keys.first);
        near(
          handTip(t)!,
          MatchPairsSession.topFace(spec.stage.size, a.left.length, top).center,
          'the hand is on the first card',
        );
        expect(find.byKey(const Key('hint-p5')), findsNothing, reason: 'no line yet');
        await pass(t, 1400);
        near(
          handTip(t)!,
          tileTopOf(t, find.byKey(Key('bottom-${a.pairs.values.first}')), 0),
          'then on the top edge of its partner',
        );
        await pass(t, 1000);
        expect(find.byKey(const Key('hint-p5')), findsOneWidget, reason: 'one line');
        expect(s.matched, isNotEmpty);
        await pass(t, 2500);
        expect(hand, findsNothing);
        expect(find.byKey(const Key('hint-p5')), findsNothing);
        expect(s.matched, isEmpty, reason: 'the pair is taken out again for the child');
        expect(s.hintLeft, a.pairs.keys.first);
        expect(s.hintRight, a.pairs.values.first);
        await end(t, s);
      },
    );

    test('the faces of the top row run left to right', () {
      for (final int n in <int>[2, 3, 4]) {
        for (int i = 1; i < n; i++) {
          expect(
            MatchPairsSession.topFace(spec.stage.size, n, i).left,
            greaterThan(MatchPairsSession.topFace(spec.stage.size, n, i - 1).right),
          );
        }
      }
    });
  });

  // ---- shape builder ----

  group('shape builder', () {
    test("the ghost has the outline of the slot's shape", () {
      expect(ShapeBuilderSession.ghostKindOf('asset:shape_square_blue'), GhostKind.square);
      expect(ShapeBuilderSession.ghostKindOf('asset:shape_triangle_green'), GhostKind.triangle);
      expect(ShapeBuilderSession.ghostKindOf('asset:shape_circle_red'), GhostKind.circle);
      expect(ShapeBuilderSession.ghostKindOf('asset:shape_rect_orange'), GhostKind.rect);
      expect(ShapeBuilderSession.ghostKindOf('asset:house'), isNull);
    });

    testWidgets(
      'level 2: the next outline lifts off as a ghost and floats beside the picture; no piece is marked',
      (WidgetTester t) async {
        await t.runAsync(warmHintHands);
        final ShapeBuilderActivity a = content.activities['shp.build.house']! as ShapeBuilderActivity;
        final LessonController c = controllerFor(a);
        final ShapeBuilderSession s = ShapeBuilderSession(c, a);
        await host(t, s);
        await lamp(t, c, 1, last: 3000);
        expect(find.byKey(const Key('hint-p9')), findsNothing, reason: 'level 1 only lights the outlines');
        await lamp(t, c, 1, last: 1500);
        expect(find.byKey(const Key('hint-p9')), findsOneWidget);
        final Rect ghost = t.getRect(find.byKey(const Key('hint-p9')));
        final Rect picture = s.pictureBox(spec.stage.size).shift(Offset(spec.stage.left, spec.stage.top));
        expect(ghost.overlaps(picture), isFalse, reason: 'it floats beside the picture, not over it');
        expect(s.hintPiece, isNull, reason: 'no piece of the tray is marked');
        expect(hand, findsNothing);
        await end(t, s);
      },
    );

    testWidgets('a wide picture with no room beside it gets no ghost', (WidgetTester t) async {
      await t.runAsync(warmHintHands);
      final ShapeBuilderActivity a = content.activities['shp.build.train']! as ShapeBuilderActivity;
      final LessonController c = controllerFor(a);
      final ShapeBuilderSession s = ShapeBuilderSession(c, a);
      await host(t, s);
      await lamp(t, c, 2, last: 2000);
      expect(find.byKey(const Key('hint-p9')), findsNothing);
      expect(s.hintSlot, isNotNull, reason: 'the place is still lit');
      await end(t, s);
    });

    testWidgets(
      'level 3: the hand takes the piece that fits from the tray, puts it in its place, and the piece goes back',
      (WidgetTester t) async {
        await t.runAsync(warmHintHands);
        final ShapeBuilderActivity a = content.activities['shp.build.house']! as ShapeBuilderActivity;
        final LessonController c = controllerFor(a);
        final ShapeBuilderSession s = ShapeBuilderSession(c, a);
        await host(t, s);
        await lamp(t, c, 3, last: 300);
        expect(hand, findsOneWidget);
        final int fit = a.pieces.indexOf(a.slots.first.sprite);
        near(
          handTip(t)!,
          tileTopOf(t, find.byKey(Key('piece-$fit')), 4),
          'the hand starts on the top edge of the piece that fits',
        );
        await pass(t, 1600);
        expect(s.filled, isNotEmpty, reason: 'the piece is in its place');
        near(handTip(t)!, s.slotRect(spec.stage.size, a.slots.first).center, 'the hand is in the place');
        await pass(t, 1800);
        expect(hand, findsNothing);
        expect(s.filled, isEmpty);
        expect(s.hintPiece, isNotNull, reason: 'the piece keeps its halo for the child');
        await end(t, s);
      },
    );
  });

  // ---- robot ----

  group('robot', () {
    testWidgets(
      'the arrows are drawn left, up, down, right, and the hand lands on their top edges in both modes',
      (WidgetTester t) async {
        await t.runAsync(warmHintHands);
        for (final String id in <String>['cs.robot.plan.2', 'cs.robot.direct.1']) {
          final RobotPathActivity a = content.activities[id]! as RobotPathActivity;
          final LessonController c = controllerFor(a);
          final RobotPathSession s = RobotPathSession(c, a);
          await host(t, s);
          double last = -1;
          for (final String d in RobotPathSession.arrowOrder) {
            final Finder tile = find.byKey(Key('arrow-$d'));
            expect(
              t.getCenter(tile).dx,
              greaterThan(last),
              reason: '$id: $d is right of the one before (never mirrored)',
            );
            last = t.getCenter(tile).dx;
            near(s.arrowTip(spec, d), tileTopOf(t, tile, 6), '$id: $d');
          }
          await end(t, s);
        }
      },
    );

    testWidgets('level 2 leaves the footprint 1 where the ghost robot stands', (WidgetTester t) async {
      await t.runAsync(warmHintHands);
      final RobotPathActivity a = content.activities['cs.robot.plan.2']! as RobotPathActivity;
      final LessonController c = controllerFor(a);
      final RobotPathSession s = RobotPathSession(c, a);
      await host(t, s);
      await lamp(t, c, 1, last: 500);
      expect(find.byKey(const Key('hint-badge')), findsNothing);
      await lamp(t, c, 1, last: 500);
      expect(find.byKey(const Key('robot-ghost')), findsOneWidget);
      expect(find.byKey(const Key('hint-badge')), findsOneWidget);
      expect(
        find.descendant(of: find.byKey(const Key('hint-badge')), matching: find.text('1')),
        findsOneWidget,
      );
      expect(hand, findsNothing);
      await end(t, s);
    });

    testWidgets(
      'level 3: the hand presses each arrow of the way in turn, and a numbered footprint stays on each square',
      (WidgetTester t) async {
        await t.runAsync(warmHintHands);
        final RobotPathActivity a = content.activities['cs.robot.plan.2']! as RobotPathActivity;
        final LessonController c = controllerFor(a);
        final RobotPathSession s = RobotPathSession(c, a);
        await host(t, s);
        await lamp(t, c, 3, last: 200);
        for (int i = 0; i < a.solution.length; i++) {
          near(
            handTip(t)!,
            tileTopOf(t, find.byKey(Key('arrow-${a.solution[i]}')), 6),
            'step ${i + 1} is pressed on the arrow ${a.solution[i]}',
          );
          expect(
            find.byKey(const Key('hint-badge')),
            findsNWidgets(i),
            reason: 'the footprints of the steps done',
          );
          await pass(t, 600);
        }
        await pass(t, 300);
        expect(hand, findsNothing, reason: 'the hand leaves');
        expect(find.byKey(const Key('hint-badge')), findsNWidgets(a.solution.length));
        for (int i = 1; i <= a.solution.length; i++) {
          expect(
            find.descendant(of: find.byKey(const Key('hint-badge')), matching: find.text('$i')),
            findsOneWidget,
          );
        }
        expect(s.pos, a.goalAt, reason: 'the robot stands on the flag');
        await pass(t, 2500);
        expect(
          find.byKey(const Key('hint-badge')),
          findsNothing,
          reason: 'the footprints go with the demonstration',
        );
        expect(s.pos, a.robotAt, reason: 'and the robot is back at the start');
        await end(t, s);
      },
    );

    testWidgets('direct mode: the same demonstration with the arrows of the way', (WidgetTester t) async {
      await t.runAsync(warmHintHands);
      final RobotPathActivity a = content.activities['cs.robot.direct.1']! as RobotPathActivity;
      final LessonController c = controllerFor(a);
      final RobotPathSession s = RobotPathSession(c, a);
      await host(t, s);
      await lamp(t, c, 3, last: 200);
      near(handTip(t)!, tileTopOf(t, find.byKey(Key('arrow-${a.solution.first}')), 6), 'the first arrow');
      await pass(t, 600 * (a.solution.length + 1) + 1500);
      expect(hand, findsNothing);
      expect(find.byKey(const Key('hint-badge')), findsNothing);
      await end(t, s);
    });
  });

  // ---- the whole pack ----

  group('every activity of these templates', () {
    testWidgets('no hand, line or count before level 3; the hand has left at the end of level 3', (
      WidgetTester t,
    ) async {
      await t.runAsync(warmHintHands);
      int n = 0;
      final List<Activity> these = <Activity>[
        ...all<SortDragActivity>(),
        ...all<BuildPatternActivity>(),
        ...all<MatchPairsActivity>(),
        ...all<ShapeBuilderActivity>(),
        ...all<RobotPathActivity>(),
        ...all<SpotErrorActivity>(),
      ];
      for (final Activity a in these) {
        final LessonController c = controllerFor(a);
        final TemplateSession s = switch (a) {
          SortDragActivity() => SortDragSession(c, a),
          BuildPatternActivity() => BuildPatternSession(c, a),
          MatchPairsActivity() => MatchPairsSession(c, a),
          ShapeBuilderActivity() => ShapeBuilderSession(c, a),
          RobotPathActivity() => RobotPathSession(c, a),
          _ => SpotErrorSession(c, a as SpotErrorActivity),
        };
        await host(t, s);
        for (int level = 1; level <= 2; level++) {
          c.showHint();
          await t.pump(const Duration(milliseconds: 1));
          for (int i = 0; i < 24; i++) {
            await t.pump(const Duration(milliseconds: 500));
          }
          expect(hand, findsNothing, reason: '${a.id} level $level');
          expect(find.byKey(const Key('hint-p5')), findsNothing, reason: '${a.id} level $level');
        }
        c.showHint();
        await t.pump(const Duration(milliseconds: 1));
        for (int i = 0; i < 40; i++) {
          await t.pump(const Duration(milliseconds: 500));
        }
        expect(hand, findsNothing, reason: '${a.id}: the hand has left at the end of level 3');
        expect(find.byKey(const Key('hint-p5')), findsNothing, reason: a.id);
        await end(t, s);
        n++;
      }
      expect(n, 165);
    }, timeout: const Timeout(Duration(minutes: 4)));

    testWidgets('with motion allowed the hand travels and the same hint plays', (WidgetTester t) async {
      await t.runAsync(warmHintHands);
      final SortDragActivity a = content.activities['log.sortdrag.colour']! as SortDragActivity;
      final LessonController c = controllerFor(a);
      final SortDragSession s = SortDragSession(c, a);
      await host(t, s, reduceMotion: false);
      await lamp(t, c, 3, last: 1000);
      expect(hand, findsOneWidget);
      await pass(t, 4000);
      expect(hand, findsNothing);
      expect(s.hintBin, a.items.first.bin);
      await end(t, s);
    });
  });
}
