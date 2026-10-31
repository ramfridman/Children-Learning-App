import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/child/activity_shell.dart';
import 'package:nitznutz/content/models.dart';
import 'package:nitznutz/play/balance_session.dart';
import 'package:nitznutz/play/hint_hand.dart';
import 'package:nitznutz/play/lesson_controller.dart';
import 'package:nitznutz/play/shop_pay_session.dart';
import 'package:nitznutz/play/spot_error_session.dart';
import 'package:nitznutz/play/hints/tile_points.dart';
import 'package:nitznutz/play/template_session.dart';

import 'support/fakes.dart';
import 'support/harness.dart';
import 'support/starter.dart';

/// B-40 part 5, the last three templates: the shop (the places for the price's coins, the hand putting the coins in), the balance
/// (towers on the pans and a level line, the hand adding cubes or pointing the way the beam tips) and spot the mistake in Band B
/// (a picture by family at level 2). Level 1 and 2 never mark the answer; level 3 is the pointing hand.
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
  Future<void> host(WidgetTester tester, TemplateSession s, {ActivitySpec on = ActivitySpec.phone}) async {
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
                    left: on.stage.left,
                    top: on.stage.top,
                    width: on.stage.width,
                    height: on.stage.height,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: <Widget>[
                        Positioned.fill(child: s.buildStage(ctx, on.stage.size, on)),
                        Positioned.fill(child: s.buildHands(ctx, on.stage.size, on) ?? const SizedBox()),
                      ],
                    ),
                  ),
                  Positioned(
                    left: on.tilesLeft,
                    top: on.tilesTop - 12,
                    width: on.tilesWidth,
                    child: s.buildTiles(ctx, on) ?? const SizedBox(),
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

  /// The next level of the lamp, played for [ms].
  Future<void> lamp(WidgetTester t, LessonController c, int ms) async {
    c.showHint();
    await t.pump(const Duration(milliseconds: 1));
    await pass(t, ms);
  }

  Future<void> end(WidgetTester t, TemplateSession s) async {
    s.dispose();
    await t.pumpWidget(const SizedBox());
  }

  List<T> all<T extends Activity>() => content.activities.values.whereType<T>().toList();

  final Finder hand = find.byKey(const Key('hint-p12'));
  final Finder places = find.byKey(const Key('hint-place'));
  final Finder gold = find.byKey(const Key('hint-place-full'));

  /// A point of the stage, on the board.
  Offset onBoard(Offset p) => p + spec.stage.topLeft;

  group('shop', () {
    testWidgets('the layout of the purse and the pay button is the one the tiles are drawn with', (
      WidgetTester t,
    ) async {
      for (final ShopPayActivity a in all<ShopPayActivity>()) {
        final LessonController c = controllerFor(a);
        final ShopPaySession s = ShopPaySession(c, a);
        await host(t, s);
        final Offset box = Offset(spec.tilesLeft, spec.tilesTop - 12);
        // Once with the whole purse, once with the first two coins on the counter.
        for (int round = 0; round < 2; round++) {
          final List<PurseCoin> inPurse = <PurseCoin>[
            for (final PurseCoin p in s.purse)
              if (!s.onCounter.contains(p.id)) p,
          ];
          final PurseLayout layout = PurseLayout(<String>[
            for (final PurseCoin p in inPurse) p.kind,
          ], spec.tilesWidth);
          for (int i = 0; i < inPurse.length; i++) {
            final Rect real = t.getRect(find.byKey(Key('coin-${inPurse[i].id}'))).deflate(CoinFace.pad);
            final Rect mine = layout.faces[i].shift(box);
            expect(
              (real.center - mine.center).distance,
              lessThan(0.6),
              reason: '${a.id} coin $i, round $round',
            );
            expect(real.width, closeTo(mine.width, 0.6));
          }
          final Rect pay = t.getRect(find.byKey(const Key('pay'))).deflate(PurseLayout.payMargin);
          expect(
            (pay.center - layout.pay.shift(box).center).distance,
            lessThan(0.6),
            reason: '${a.id} pay, round $round',
          );
          if (round == 0) {
            s.toggle(s.purse[0].id);
            s.toggle(s.purse[1].id);
            await t.pump(const Duration(milliseconds: 100));
          }
        }
        await end(t, s);
      }
    });

    testWidgets(
      'level 1 draws the places of the price, level 2 puts the biggest coin on in gold, level 3 is the hand; nothing pays before the end',
      (WidgetTester t) async {
        await t.runAsync(warmHintHands);
        // Eight shekels, with one 5, two 2s and three 1s: the way is 5 + 2 + 1.
        final ShopPayActivity a = content.activities['x.mathb17.6']! as ShopPayActivity;
        final LessonController c = controllerFor(a);
        final ShopPaySession s = ShopPaySession(c, a);
        await host(t, s);
        await lamp(t, c, 1000);
        expect(places, findsNWidgets(8), reason: 'a place for each shekel');
        expect(gold, findsNothing);
        expect(hand, findsNothing);
        expect(s.hinted, isEmpty);
        expect(find.byKey(const Key('on-c0')), findsNothing);
        await lamp(t, c, 1500);
        expect(gold, findsNWidgets(5), reason: 'the 5 is on: five places are gold');
        expect(places, findsNWidgets(3), reason: 'three stay empty');
        expect(s.onCounter, hasLength(1));
        expect(s.total, 500);
        expect(hand, findsNothing);
        expect(s.hinted, isEmpty, reason: 'no coin is lit before level 3 ends');
        await lamp(t, c, 300);
        expect(hand, findsOneWidget);
        expect(s.demoRunning, isTrue);
        await pass(t, 1400);
        expect(s.total, 700, reason: 'the 5 and a 2 are on');
        expect(gold, findsNWidgets(7));
        expect(find.byKey(const Key('running-total')), findsOneWidget);
        await pass(t, 900 * 3 + 1400);
        expect(hand, findsNothing, reason: 'the hand leaves at the end');
        expect(s.demoRunning, isFalse);
        expect(s.onCounter, isEmpty, reason: 'the coins are back in the purse');
        expect(s.hinted, s.solution(), reason: 'they stay lit');
        expect(places, findsNothing);
        await end(t, s);
      },
    );

    testWidgets('a touch of the child ends the hand and the places at once, and the coin is taken', (
      WidgetTester t,
    ) async {
      await t.runAsync(warmHintHands);
      final ShopPayActivity a = content.activities['x.mathb17.6']! as ShopPayActivity;
      final LessonController c = controllerFor(a);
      final ShopPaySession s = ShopPaySession(c, a);
      await host(t, s);
      await lamp(t, c, 100);
      await lamp(t, c, 100);
      await lamp(t, c, 1000);
      expect(hand, findsOneWidget);
      s.toggle(s.purse[0].id);
      await pass(t, 300);
      expect(hand, findsNothing);
      expect(places, findsNothing);
      expect(gold, findsNothing);
      expect(s.demoRunning, isFalse);
      expect(s.onCounter, <String>[s.purse[0].id]);
      expect(
        find.byKey(Key('on-${s.purse[0].id}')),
        findsOneWidget,
        reason: 'the coin is on the counter, as a coin',
      );
      await end(t, s);
    });

    testWidgets(
      'all 11 shop items: places at level 1, no hand and no lit coin before level 3, the coins lit at its end',
      (WidgetTester t) async {
        await t.runAsync(warmHintHands);
        for (final ShopPayActivity a in all<ShopPayActivity>()) {
          final LessonController c = controllerFor(a);
          final ShopPaySession s = ShopPaySession(c, a);
          await host(t, s);
          await lamp(t, c, 1000);
          expect(places, findsNWidgets(a.price ~/ 100), reason: a.id);
          expect(gold, findsNothing, reason: a.id);
          await lamp(t, c, 1500);
          expect(hand, findsNothing, reason: '${a.id} level 2');
          expect(s.hinted, isEmpty, reason: '${a.id} level 2');
          expect(s.total, lessThan(a.price), reason: '${a.id}: the first coin alone never pays');
          expect(gold.evaluate().length + places.evaluate().length, a.price ~/ 100, reason: a.id);
          await lamp(t, c, 300);
          expect(hand, findsOneWidget, reason: '${a.id} level 3');
          await pass(t, 900 * s.solution().length + 2000);
          expect(s.demoRunning, isFalse, reason: a.id);
          expect(s.hinted, s.solution(), reason: a.id);
          expect(hand, findsNothing, reason: a.id);
          await end(t, s);
        }
      },
    );
  });

  group('balance', () {
    testWidgets('the hand goes to the real tiles: the top edge of each tile of the row', (
      WidgetTester t,
    ) async {
      for (final (String id, String key, int n, int i, double slot) in <(String, String, int, int, double)>[
        ('b.mathb09.5', 'balance-left', 3, 0, 104),
        ('b.mathb09.5', 'balance-same', 3, 1, 104),
        ('b.mathb09.5', 'balance-right', 3, 2, 104),
        ('b.mathb13.7', 'balance-plus', 2, 1, 96),
      ]) {
        final BalanceActivity a = content.activities[id]! as BalanceActivity;
        final BalanceSession s = BalanceSession(controllerFor(a), a);
        await host(t, s);
        final Rect tile = t.getRect(find.byKey(Key(key)));
        final Offset mine = spec.tileTip(n, i, slot: slot, slop: 12, rtl: false);
        expect(
          (onBoard(mine) - Offset(tile.center.dx, tile.top + 12)).distance,
          lessThan(0.6),
          reason: '$id $key',
        );
        await end(t, s);
      }
    });

    testWidgets(
      'a lean that is hidden: the peg and the lit pans at level 1, towers on one floor with a line across at level 2, the beam let go and the hand at level 3',
      (WidgetTester t) async {
        await t.runAsync(warmHintHands);
        // 5 + 4 against 3 + 2: the left is heavier.
        final BalanceActivity a = content.activities['b.mathb09.5']! as BalanceActivity;
        final LessonController c = controllerFor(a);
        final BalanceSession s = BalanceSession(c, a);
        await host(t, s);
        expect(find.byKey(const Key('scale-peg')), findsNothing);
        await lamp(t, c, 500);
        expect(find.byKey(const Key('pan-lit')), findsOneWidget);
        expect(find.byKey(const Key('scale-peg')), findsOneWidget, reason: 'a peg holds the beam level');
        expect(s.lean, 0);
        await pass(t, 12000);
        await lamp(t, c, 800);
        expect(
          find.byKey(const Key('hint-block')),
          findsNWidgets(9 + 5),
          reason: 'a cube for each unit on each pan',
        );
        expect(find.byKey(const Key('hint-block-empty')), findsNothing);
        expect(find.byKey(const Key('hint-line')), findsOneWidget);
        expect(find.byKey(const Key('pan-lit')), findsNothing);
        expect(s.lean, 0, reason: 'the lean stays hidden');
        expect(s.chosen, isNull);
        expect(hand, findsNothing);
        await pass(t, 12000);
        await lamp(t, c, 500);
        expect(s.revealed, isTrue, reason: 'the peg is out and the beam is let go');
        expect(s.demoRunning, isTrue);
        expect(find.byKey(const Key('hint-block')), findsNothing, reason: 'the towers are gone');
        expect(hand, findsNothing, reason: 'the hand waits for the beam to tip');
        await pass(t, 1500);
        expect(hand, findsOneWidget);
        expect(s.chosen, isNull, reason: 'the tile is marked only at the end');
        await pass(t, 800 + 1100 + 200);
        expect(hand, findsNothing);
        expect(s.chosen, 'left');
        expect(s.demoRunning, isFalse);
        await end(t, s);
      },
    );

    testWidgets(
      'weighing: the missing cubes are empty places at level 2; level 3 presses plus while the cubes go on until level',
      (WidgetTester t) async {
        await t.runAsync(warmHintHands);
        // 5 blocks against 2: three to add.
        final BalanceActivity a = content.activities['b.mathb13.7']! as BalanceActivity;
        final LessonController c = controllerFor(a);
        final BalanceSession s = BalanceSession(c, a);
        await host(t, s);
        await lamp(t, c, 12000);
        await lamp(t, c, 800);
        expect(find.byKey(const Key('hint-block')), findsNWidgets(5 + 2));
        expect(
          find.byKey(const Key('hint-block-empty')),
          findsNWidgets(3),
          reason: 'what the right pan still needs',
        );
        expect(s.added, 0);
        await pass(t, 12000);
        await lamp(t, c, 600);
        expect(hand, findsOneWidget);
        expect(s.added, 1);
        await pass(t, 700 * 2);
        expect(s.added, 3);
        await pass(t, 700);
        expect(
          find.byKey(const Key('hint-line')),
          findsOneWidget,
          reason: 'the beam is level, and a line says so',
        );
        expect(s.lean, 0);
        await pass(t, 2000);
        expect(s.added, 0, reason: 'the blocks come off again');
        expect(hand, findsNothing);
        expect(s.demoRunning, isFalse);
        await end(t, s);
      },
    );

    testWidgets('a move of the child takes the towers off and shows what is on the pans', (
      WidgetTester t,
    ) async {
      await t.runAsync(warmHintHands);
      final BalanceActivity a = content.activities['b.mathb13.7']! as BalanceActivity;
      final LessonController c = controllerFor(a);
      final BalanceSession s = BalanceSession(c, a);
      await host(t, s);
      await lamp(t, c, 12000);
      await lamp(t, c, 800);
      expect(s.towers, isTrue);
      await s.addBlock();
      await pass(t, 300);
      expect(s.towers, isFalse);
      expect(find.byKey(const Key('hint-block')), findsNothing);
      expect(s.added, 1);
      await end(t, s);
    });

    testWidgets(
      'every balance item: no hand and no lean before level 3, towers as tall as the weights, the answer at the end',
      (WidgetTester t) async {
        await t.runAsync(warmHintHands);
        for (final BalanceActivity a in all<BalanceActivity>()) {
          final LessonController c = controllerFor(a);
          final BalanceSession s = BalanceSession(c, a);
          await host(t, s);
          await lamp(t, c, 12000);
          expect(hand, findsNothing, reason: '${a.id} level 1');
          await lamp(t, c, 1000);
          expect(hand, findsNothing, reason: '${a.id} level 2');
          expect(s.revealed, isFalse, reason: a.id);
          expect(
            find.byKey(const Key('hint-block')),
            findsNWidgets(s.leftWeight + s.rightWeight),
            reason: '${a.id}: a cube for each unit of weight',
          );
          expect(
            find.byKey(const Key('hint-block-empty')),
            findsNWidgets(a.weigh ? s.leftWeight - s.rightWeight : 0),
            reason: a.id,
          );
          expect(s.chosen, isNull, reason: a.id);
          await pass(t, 12000);
          await lamp(t, c, 300);
          expect(s.demoRunning, isTrue, reason: a.id);
          await pass(t, 9000);
          expect(s.demoRunning, isFalse, reason: a.id);
          expect(hand, findsNothing, reason: a.id);
          if (!a.weigh) expect(s.chosen, a.result, reason: a.id);
          await end(t, s);
        }
      },
    );
  });

  group('spot the mistake', () {
    testWidgets('a row that counts: a correct number path under it, a cell at a time, and no cell marked', (
      WidgetTester t,
    ) async {
      await t.runAsync(warmHintHands);
      // 1 2 3 8 5: the 8 should be a 4.
      final SpotErrorActivity a = content.activities['b.numb11.1']! as SpotErrorActivity;
      final LessonController c = controllerFor(a);
      final SpotErrorSession s = SpotErrorSession(c, a);
      await host(t, s);
      await lamp(t, c, 12000);
      await lamp(t, c, 450 + 200);
      expect(find.byKey(const Key('hint-p6')), findsOneWidget);
      expect(find.byKey(const Key('path-square-2')), findsOneWidget);
      expect(find.byKey(const Key('path-square-3')), findsNothing, reason: 'a cell at a time');
      await pass(t, 450 * 4);
      for (final int n in <int>[1, 2, 3, 4, 5]) {
        expect(find.byKey(Key('path-square-$n')), findsOneWidget, reason: 'the row as it should read');
      }
      expect(s.hintCell, isNull);
      expect(find.byKey(const Key('hint-p2')), findsNothing, reason: 'nothing is ringed');
      expect(find.byKey(const Key('hint-card')), findsNothing, reason: 'what belongs there is for level 3');
      expect(find.byKey(const Key('spot-bar')), findsNothing, reason: 'the sky bar is the fallback only');
      expect(hand, findsNothing);
      await end(t, s);
    });

    testWidgets(
      'a sentence: as many cubes over each number as it says; a pattern: a bracket under each copy of the unit',
      (WidgetTester t) async {
        await t.runAsync(warmHintHands);
        // 3 + 4 = 8: 15 cubes. Red red blue, red yellow blue, red red: two whole copies of a unit of three.
        for (final (String id, Key shown, int count) in <(String, Key, int)>[
          ('b.mathb03.9', const Key('hint-block'), 3 + 4 + 8),
          ('b.logb02.1', const Key('hint-bracket'), 2),
          ('b.csb04.1', const Key('hint-bracket'), 3),
        ]) {
          final SpotErrorActivity a = content.activities[id]! as SpotErrorActivity;
          final LessonController c = controllerFor(a);
          final SpotErrorSession s = SpotErrorSession(c, a);
          await host(t, s);
          await lamp(t, c, 12000);
          await lamp(t, c, 700 * 8);
          expect(find.byKey(shown), findsNWidgets(count), reason: id);
          expect(s.hintCell, isNull, reason: id);
          expect(find.byKey(const Key('hint-p2')), findsNothing, reason: id);
          await end(t, s);
        }
      },
    );

    testWidgets(
      'towers that grow: a floor under the row; the rainbow: its six paints in order, under the cells',
      (WidgetTester t) async {
        await t.runAsync(warmHintHands);
        for (final (String id, Key shown, int count) in <(String, Key, int)>[
          ('b.logb11.4', const Key('hint-line'), 1),
          ('b.colb06.5', const Key('hint-p9'), 6),
        ]) {
          final SpotErrorActivity a = content.activities[id]! as SpotErrorActivity;
          final LessonController c = controllerFor(a);
          final SpotErrorSession s = SpotErrorSession(c, a);
          await host(t, s);
          await lamp(t, c, 12000);
          await lamp(t, c, 450 * 8);
          expect(find.byKey(shown), findsNWidgets(count), reason: id);
          await end(t, s);
        }
      },
    );

    testWidgets(
      'a sort: the sample (a picture, a paint or an outline) goes past each cell in turn and rests on none',
      (WidgetTester t) async {
        await t.runAsync(warmHintHands);
        for (final (String id, Key shown) in <(String, Key)>[
          ('b15.cola02.5', const Key('hint-copy')), // red red orange red: the others are the same red ball
          ('b15.cola06.1', const Key('hint-p9')), // brown things and an orange one: the brown paint
          ('b.colb04.6', const Key('hint-p9')), // circles and a square: the outline of a circle
        ]) {
          final SpotErrorActivity a = content.activities[id]! as SpotErrorActivity;
          final LessonController c = controllerFor(a);
          final SpotErrorSession s = SpotErrorSession(c, a);
          await host(t, s);
          await lamp(t, c, 12000);
          await lamp(t, c, 700 + 300);
          expect(find.byKey(shown), findsOneWidget, reason: id);
          await pass(t, 700 * a.cells.length);
          expect(find.byKey(shown), findsNothing, reason: '$id: it rests on no cell');
          expect(s.hintCell, isNull, reason: id);
          await end(t, s);
        }
      },
    );

    testWidgets(
      'all 71 rows: level 2 draws a picture of its family where the row has one, else the light with the sky bar; no cell is marked',
      (WidgetTester t) async {
        await t.runAsync(warmHintHands);
        final List<String> withoutPicture = <String>[];
        for (final SpotErrorActivity a in all<SpotErrorActivity>()) {
          final LessonController c = controllerFor(a);
          final SpotErrorSession s = SpotErrorSession(c, a);
          await host(t, s);
          await lamp(t, c, 12000);
          await lamp(t, c, 700 * (a.cells.length + 2));
          expect(s.hintCell, isNull, reason: '${a.id} level 2 marks no cell');
          expect(find.byKey(const Key('hint-p2')), findsNothing, reason: a.id);
          expect(
            find.byKey(const Key('hint-card')),
            findsNothing,
            reason: '${a.id}: no right-one card before level 3',
          );
          expect(hand, findsNothing, reason: a.id);
          if (s.barTo != null) withoutPicture.add(a.id);
          await end(t, s);
        }
        expect(
          withoutPicture,
          unorderedEquals(<String>['b.shpb03.7', 'b.shpb04.9', 'b15.csa05.1', 'b15.csa05.2']),
          reason: 'the rows that keep the sky bar',
        );
      },
    );
  });
}
