// B-26 step 4: the child's home (HomeIslandScreen) on the four boards, against docs/design/nitzi-home.md sections 3 and
// 3.1: the tap areas, labels, bubble and title at text scale 1.0 and 1.3; the title's fit rule; the overlays on the
// pictures; the touch (a squash, a drag never opens); the bob (still with reduce motion). The real app's ways in and out
// are in home_island_flow_test.dart.
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/child/home_island_name.dart';
import 'package:nitznutz/child/home_island_screen.dart';
import 'package:nitznutz/design/board.dart';
import 'package:nitznutz/design/components.dart';
import 'package:nitznutz/strings/he.dart';

import 'support/harness.dart';

/// A board and the design's numbers for it (section 3 and 3.1), in board coordinates.
typedef Board = ({
  String name,
  Size size,
  Rect bottle,
  Rect companion,
  Rect book,
  Rect lighthouse,
  Offset bubble,
  double bubbleMax,
  double titleTop,
  double maxText,
  double frame,
  double backStart,
  double backTop,
  double backTap,
  double gap,
});

const List<Board> boards = <Board>[
  (
    name: 'phone',
    size: Size(852, 393),
    bottle: Rect.fromLTWH(600, 192, 160, 144),
    companion: Rect.fromLTWH(380, 160, 160, 160),
    book: Rect.fromLTWH(208, 216, 128, 120),
    lighthouse: Rect.fromLTWH(32, 88, 128, 248),
    bubble: Offset(548, 100),
    bubbleMax: 260,
    titleTop: 8,
    maxText: 610,
    frame: 50,
    backStart: 16,
    backTop: 8,
    backTap: 72,
    gap: 24,
  ),
  (
    name: 'phoneSE',
    size: Size(667, 375),
    bottle: Rect.fromLTWH(468, 188, 136, 136),
    companion: Rect.fromLTWH(304, 172, 132, 132),
    book: Rect.fromLTWH(168, 212, 112, 112),
    lighthouse: Rect.fromLTWH(24, 96, 112, 228),
    bubble: Offset(420, 104),
    bubbleMax: 230,
    titleTop: 8,
    maxText: 425,
    frame: 50,
    backStart: 16,
    backTop: 8,
    backTap: 72,
    gap: 24,
  ),
  (
    name: 'tabletLandscape',
    size: Size(1180, 820),
    bottle: Rect.fromLTWH(900, 480, 200, 200),
    companion: Rect.fromLTWH(600, 380, 240, 240),
    book: Rect.fromLTWH(360, 516, 176, 176),
    lighthouse: Rect.fromLTWH(80, 220, 200, 480),
    bubble: Offset(800, 296),
    bubbleMax: 356,
    titleTop: 24,
    maxText: 872,
    frame: 68,
    backStart: 24,
    backTop: 24,
    backTap: 88,
    gap: 60,
  ),
  (
    name: 'tabletPortrait',
    size: Size(820, 1180),
    bottle: Rect.fromLTWH(500, 760, 220, 200),
    companion: Rect.fromLTWH(300, 380, 240, 240),
    book: Rect.fromLTWH(150, 780, 176, 176),
    lighthouse: Rect.fromLTWH(48, 200, 160, 440),
    bubble: Offset(500, 300),
    bubbleMax: 296,
    titleTop: 32,
    maxText: 512,
    frame: 68,
    backStart: 24,
    backTop: 32,
    backTap: 88,
    gap: 60,
  ),
];

Board board(String name) => boards.firstWhere((Board b) => b.name == name);

/// The names of section 3.1's checks: a typical one (pointed), the widest 24 letters, 25 letters (the title shows 23
/// and "…"), none, and a Latin double name.
final Map<String, String> names = <String, String>{
  'noa': 'נֹעָה',
  'wide_24': 'ש' * 24,
  'letters_25': 'אבגדהוזחטיכלמנסעפצקרשתאבג',
  'blank': '',
  'latin': 'Alexandra Massimiliano',
};

/// What the screen's callbacks were asked to do.
class Taps {
  int bottle = 0;
  int companion = 0;
  int stickers = 0;
  int hall = 0;
}

Future<Taps> pumpIsland(
  WidgetTester tester,
  Board b, {
  String name = 'נֹעָה',
  double scale = 1,
  bool still = true,
  bool hallGlow = false,
  String sticker = firstStickerAsset,
}) async {
  if (scale != 1) {
    tester.platformDispatcher.textScaleFactorTestValue = scale;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  }
  if (still) {
    tester.platformDispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(
      disableAnimations: true,
    );
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
  }
  final Taps taps = Taps();
  // A fresh screen each time (its bob starts from the beginning).
  await tester.pumpWidget(const SizedBox.shrink());
  await pumpScreen(
    tester,
    HomeIslandScreen(
      island: homeIslandName(name),
      companion: const SizedBox.expand(key: Key('friend')),
      onCompanion: () => taps.companion++,
      onBottle: () => taps.bottle++,
      onStickers: () => taps.stickers++,
      onHall: () => taps.hall++,
      hallGlow: hallGlow,
      sticker: sticker,
    ),
    size: b.size,
  );
  await tester.pump();
  return taps;
}

Rect rectOf(WidgetTester tester, String key) => tester.getRect(find.byKey(Key(key)));

/// The larger of the horizontal and the vertical gap between two rectangles (0 when they overlap).
double separation(Rect a, Rect b) {
  final double dx = <double>[
    a.left - b.right,
    b.left - a.right,
    0,
  ].reduce((double x, double y) => x > y ? x : y);
  final double dy = <double>[
    a.top - b.bottom,
    b.top - a.bottom,
    0,
  ].reduce((double x, double y) => x > y ? x : y);
  return dx > dy ? dx : dy;
}

void expectRect(Rect actual, Rect expected, String why) {
  expect(actual.left, closeTo(expected.left, 0.01), reason: why);
  expect(actual.top, closeTo(expected.top, 0.01), reason: why);
  expect(actual.width, closeTo(expected.width, 0.01), reason: why);
  expect(actual.height, closeTo(expected.height, 0.01), reason: why);
}

/// How many lines the text inside [key] takes.
int linesIn(WidgetTester tester, String key) => tester
    .renderObject<RenderParagraph>(find.descendant(of: find.byKey(Key(key)), matching: find.byType(RichText)))
    .getBoxesForSelection(const TextSelection(baseOffset: 0, extentOffset: 1 << 20))
    .map((TextBox t) => t.top.round())
    .toSet()
    .length;

String bubbleText(WidgetTester tester) => tester
    .widget<Text>(
      find.descendant(of: find.byKey(const Key('home-island-bubble')), matching: find.byType(Text)),
    )
    .data!;

const List<String> targets = <String>['bottle', 'companion', 'book', 'lighthouse'];

void main() {
  setUpAll(loadAppFonts);

  group('geometry: four boards, text scale 1.0 and 1.3 (nitzi-home.md section 3)', () {
    for (final Board b in boards) {
      for (final double scale in <double>[1, 1.3]) {
        for (final MapEntry<String, String> n in names.entries) {
          testWidgets('${b.name} x$scale ${n.key}', (WidgetTester tester) async {
            await pumpIsland(tester, b, name: n.value, scale: scale);
            expect(tester.takeException(), isNull, reason: 'no overflow');
            final Rect screen = Offset.zero & b.size;
            final double band = b.size.height - 24;

            // The tap areas are the design's rectangles, on the board, above the bottom-24 band.
            final Map<String, Rect> tap = <String, Rect>{
              // The bottle's box is the design's rectangle; its live area inside it is checked in 'the bottle'.
              for (final String t in targets)
                t: rectOf(tester, t == 'bottle' ? 'home-island-bottle-box' : 'home-island-$t'),
            };
            expectRect(tap['bottle']!, b.bottle, 'bottle');
            expectRect(tap['companion']!, b.companion, 'companion');
            expectRect(tap['book']!, b.book, 'book');
            expectRect(tap['lighthouse']!, b.lighthouse, 'lighthouse');
            final Rect back = rectOf(tester, 'home-island-back');
            expectRect(
              back,
              Rect.fromLTWH(b.size.width - b.backStart - b.backTap, b.backTop, b.backTap, b.backTap),
              'back pebble at the start corner',
            );
            tap['back'] = back;
            for (final MapEntry<String, Rect> t in tap.entries) {
              expect(
                screen.contains(t.value.topLeft) && screen.contains(t.value.bottomRight),
                isTrue,
                reason: t.key,
              );
              expect(t.value.bottom, lessThanOrEqualTo(band), reason: '${t.key} is above the bottom-24 band');
              expect(t.value.shortestSide, greaterThanOrEqualTo(72), reason: t.key);
            }
            // No two tap areas overlap; the four objects keep the design's gaps.
            final List<String> keys = tap.keys.toList();
            for (int i = 0; i < keys.length; i++) {
              for (int j = i + 1; j < keys.length; j++) {
                final double gap = separation(tap[keys[i]]!, tap[keys[j]]!);
                expect(gap, greaterThan(0), reason: '${keys[i]} and ${keys[j]} overlap');
                if (keys[i] != 'back' && keys[j] != 'back') {
                  expect(gap, greaterThanOrEqualTo(b.gap), reason: '${keys[i]} to ${keys[j]}');
                }
              }
            }

            // The labels: under their object, on the board, above the band, clear of the other tap areas.
            for (final String t in <String>['bottle', 'book', 'lighthouse']) {
              final Rect label = rectOf(tester, 'home-island-label-$t');
              // Under the object; lifted into its bottom edge only as far as the band needs (the SE at 1.3: 4 pt).
              final double lift = tap[t]!.bottom - label.top;
              expect(lift, inInclusiveRange(-0.01, 5), reason: '$t label under it');
              if (scale == 1) {
                expect(lift, closeTo(0, 0.01), reason: '$t label right under it at text scale 1');
              }
              expect(label.center.dx, closeTo(tap[t]!.center.dx, 0.6), reason: '$t label centred');
              expect(label.left, greaterThanOrEqualTo(0), reason: '$t label on the board');
              expect(label.right, lessThanOrEqualTo(b.size.width), reason: '$t label on the board');
              expect(label.bottom, lessThanOrEqualTo(band), reason: '$t label above the bottom-24 band');
              for (final MapEntry<String, Rect> other in tap.entries) {
                if (other.key == t) continue;
                expect(label.overlaps(other.value), isFalse, reason: '$t label over ${other.key}');
              }
            }

            // The bubble: on the board, at its place, at most its width and two lines, clear of the bottle.
            final Rect bubble = rectOf(tester, 'bubble-body');
            expect(bubble.topLeft, offsetMoreOrLessEquals(b.bubble, epsilon: 0.01));
            expect(bubble.width, lessThanOrEqualTo(b.bubbleMax + 0.01));
            expect(bubble.right, lessThanOrEqualTo(b.size.width - 16));
            // Two lines as designed; a third only at a larger text scale on a tablet, where it still ends above the bottle.
            final int most = scale > 1 && b.name.startsWith('tablet') ? 3 : 2;
            expect(linesIn(tester, 'bubble-body'), lessThanOrEqualTo(most), reason: bubbleText(tester));
            expect(
              separation(bubble, tap['bottle']!),
              greaterThan(0),
              reason: 'the bubble is clear of the bottle (the least: 4 on the SE at 1.3)',
            );
            // A shortened name keeps at least as many letters as the shortening rule's floor (3 and "…").
            final String said = bubbleText(tester);
            if (said.contains('…')) {
              expect(
                said.substring(said.indexOf('\u2068') + 1, said.indexOf('…')).characters.length,
                greaterThan(2),
              );
            }

            // The title card: centred at its top, inside its box, clear of the back pebble, the lighthouse and the bubble.
            final Rect card = rectOf(tester, 'home-island-title');
            expect(card.top, closeTo(b.titleTop, 0.01));
            expect(card.center.dx, closeTo(b.size.width / 2, 0.6));
            expect(card.width, lessThanOrEqualTo(b.maxText + b.frame + 0.01));
            for (final String other in <String>['back', 'lighthouse', 'companion']) {
              expect(card.overlaps(tap[other]!), isFalse, reason: 'title over $other');
            }
            expect(card.overlaps(bubble), isFalse, reason: 'title over the bubble');
            final Text title = tester.widget<Text>(
              find.descendant(of: find.byKey(const Key('home-island-title')), matching: find.byType(Text)),
            );
            expect(title.data, homeIslandName(n.value).title, reason: 'the whole title, never cut');
            final Rect text = tester.getRect(find.byWidget(title));
            expect(
              text.width,
              closeTo(tester.getSize(find.byWidget(title)).width, 0.01),
              reason: 'not squeezed',
            );
            debugPrint(
              'home ${b.name} x$scale ${n.key}: title ${title.style!.fontSize} pt, '
              '${linesIn(tester, 'home-island-title')} line(s), card ${card.width.toStringAsFixed(1)} x '
              '${card.height.toStringAsFixed(1)}; bubble ${bubble.width.toStringAsFixed(1)} x '
              '${bubble.height.toStringAsFixed(1)}, "${bubbleText(tester)}"',
            );
          });
        }
      }
    }
  });

  group('the title: section 3.1', () {
    // The worst name, 24 x ש: size and lines per board and text scale, and the card (width x height) the design measured.
    const List<(String, double, double, int, double, double)> worst =
        <(String, double, double, int, double, double)>[
          ('phone', 1, 22, 1, 581.4, 43.4),
          ('phone', 1.3, 19, 1, 646.6, 48.0),
          ('phoneSE', 1, 18, 2, 421.3, 67.2),
          ('phoneSE', 1.3, 15, 2, 452.2, 72.3),
          ('tabletLandscape', 1, 28, 1, 744.3, 53.6),
          ('tabletLandscape', 1.3, 27, 1, 915.5, 65.7),
          ('tabletPortrait', 1, 21, 1, 575.2, 41.7),
          ('tabletPortrait', 1.3, 18, 2, 550.6, 85.6),
        ];
    for (final (String name, double scale, double size, int lines, double w, double h) in worst) {
      testWidgets('24 x ש on $name at text scale $scale: $size pt, $lines line(s), card $w x $h', (
        WidgetTester tester,
      ) async {
        final Board b = board(name);
        await pumpIsland(tester, b, name: names['wide_24']!, scale: scale);
        final Text title = tester.widget<Text>(
          find.descendant(of: find.byKey(const Key('home-island-title')), matching: find.byType(Text)),
        );
        expect(title.style!.fontSize, size);
        expect(linesIn(tester, 'home-island-title'), lines);
        final Rect card = rectOf(tester, 'home-island-title');
        // The design measured in Chrome; Flutter's own measure may differ by a little.
        expect(card.width, closeTo(w, 3), reason: 'card width');
        // Lines x size x scale x 1.7 + 6, the design's height; the text engine rounds each line to a whole point.
        expect(card.height, closeTo(lines * size * scale * 1.7 + 6, 0.5 * lines + 0.01));
        expect(card.height, closeTo(h, 0.5 * lines + 0.1), reason: 'the design\'s height');
        if (lines == 2) {
          // A break only before the name: line 1 is the frame, line 2 the whole name.
          final RenderParagraph p = tester.renderObject<RenderParagraph>(
            find.descendant(of: find.byKey(const Key('home-island-title')), matching: find.byType(RichText)),
          );
          final String text = title.data!;
          final int nameAt = text.indexOf('\u2068');
          final List<TextBox> frame = p.getBoxesForSelection(
            TextSelection(baseOffset: 0, extentOffset: nameAt - 1),
          );
          expect(
            frame.map((TextBox t) => t.top.round()).toSet(),
            hasLength(1),
            reason: 'the frame is on one line',
          );
          final double firstTop = frame.first.top;
          final List<TextBox> name = p.getBoxesForSelection(
            TextSelection(baseOffset: nameAt, extentOffset: text.length),
          );
          expect(
            name.map((TextBox t) => t.top.round()).toSet(),
            hasLength(1),
            reason: 'the name is on one line',
          );
          expect(name.first.top, greaterThan(firstTop), reason: 'the name is on line 2');
        }
      });
    }

    test('typical names stay at the base size on one line on every board', () {
      const Map<String, double> base = <String, double>{
        'phone': 22,
        'phoneSE': 20,
        'tabletLandscape': 28,
        'tabletPortrait': 28,
      };
      for (final Board b in boards) {
        for (final String name in <String>['נֹעָה', 'אלכסנדרה', 'אביגיל-אלכסנדרה רחל שושנה', '']) {
          final IslandTitleFit fit = fitIslandTitle(
            homeIslandName(name).title,
            base: base[b.name]!,
            maxText: b.maxText,
            scaler: TextScaler.noScaling,
          );
          expect((fit.size, fit.lines), (base[b.name], 1), reason: '${b.name} "$name"');
          expect(fit.box, b.maxText);
        }
      }
    });

    test('the frame words never part: a break falls only at a space', () {
      final String title = homeIslandName('נועה').title;
      expect(title, startsWith('הָאִי\u00A0שֶׁל '));
      expect(homeIslandName('').title, 'הָאִי\u00A0שֶׁלִּי');
    });

    test(
      'a word too wide even at 15 is never broken between its letters: the last guard lays it out whole',
      () {
        // 40 wide letters with no space: more than any board's max text at 15 (the 24 guard of the name never lets it in).
        final String title = 'הָאִי\u00A0שֶׁל ${'ש' * 40}';
        final IslandTitleFit fit = fitIslandTitle(
          title,
          base: 20,
          maxText: 425,
          scaler: TextScaler.noScaling,
        );
        expect(fit.size, 15);
        expect(
          fit.box,
          greaterThan(425),
          reason: 'laid out in the widest word, then scaled down by the card',
        );
        expect(fit.lines, 2);
      },
    );

    testWidgets(
      'the 24 guard: a 25-letter name shows 23 letters and "…", and the screen reader the whole name',
      (WidgetTester tester) async {
        final SemanticsHandle semantics = tester.ensureSemantics();
        await pumpIsland(tester, board('phoneSE'), name: names['letters_25']!, scale: 1.3);
        final HomeIslandName island = homeIslandName(names['letters_25']);
        expect(find.text(island.title), findsOneWidget);
        expect(island.title, endsWith('…\u2069'));
        expect(
          tester.getSemantics(find.byKey(const Key('home-island-title'))),
          matchesSemantics(label: island.semantics, isHeader: true),
        );
        semantics.dispose();
      },
    );
  });

  group('the objects', () {
    testWidgets(
      'each opens its own place; the friend greets and the bubble says hello, and keeps saying it',
      (WidgetTester tester) async {
        final Taps taps = await pumpIsland(tester, board('phone'));
        expect(
          bubbleText(tester),
          He.nitziHomeWelcome.fill(<String, String>{'child': isolatedName('נֹעָה')}),
        );
        await tester.tap(find.byKey(const Key('home-island-bottle')));
        await tester.tap(find.byKey(const Key('home-island-book')));
        await tester.tap(find.byKey(const Key('home-island-lighthouse')));
        expect((taps.bottle, taps.stickers, taps.hall, taps.companion), (1, 1, 1, 0));
        await tester.tap(find.byKey(const Key('home-island-companion')));
        await tester.pump();
        expect(taps.companion, 1);
        expect(bubbleText(tester), He.nitziHomeHi.text);
        await tester.pump(const Duration(minutes: 5));
        expect(bubbleText(tester), He.nitziHomeHi.text, reason: 'nothing on this screen goes away by itself');
      },
    );

    // The bubble's tail (nitzi-home.md section 3, "Bubble tail"): a wedge from the bubble's bottom edge (24 to 52 in
    // from its left) to a tip fixed on the board beside the friend's mouth, at (left + 0.74 w, top + 0.47 h) of the
    // friend's tap area (off the sparkle at the end of the friend's tail); out of the bottle's tap area and pointing
    // down, at text scale 1.0 and 1.3, also for the tallest bubble (24 x ש); one faint outline around body and wedge.
    const Map<String, Offset> tips = <String, Offset>{
      'phone': Offset(498.4, 235.2),
      'phoneSE': Offset(401.68, 234.04),
      'tabletLandscape': Offset(777.6, 492.8),
      'tabletPortrait': Offset(477.6, 492.8),
    };
    for (final Board b in boards) {
      testWidgets('${b.name}: the bubble\'s wedge tail ends beside the friend\'s mouth, clear of the bottle', (
        WidgetTester tester,
      ) async {
        for (final double scale in <double>[1, 1.3]) {
          for (final String name in <String>['נֹעָה', 'ש' * 24]) {
            await pumpIsland(tester, b, name: name, scale: scale);
            final String why = '${b.name} x$scale "$name"';
            final Rect body = rectOf(tester, 'bubble-body');
            final BoardBubble bubble = tester.widget<BoardBubble>(
              find.descendant(
                of: find.byKey(const Key('home-island-bubble')),
                matching: find.byType(BoardBubble),
              ),
            );
            final Offset tip = body.topLeft + bubble.tailTip!;
            expect(tip, offsetMoreOrLessEquals(tips[b.name]!, epsilon: 0.01), reason: why);
            // At least 25 below the bubble (the least: portrait, 1.3, three lines, 492.8 - 467).
            expect(tip.dy - body.bottom, greaterThanOrEqualTo(25), reason: '$why: the wedge points down');
            // One outline around the body and the wedge together, drawn over both (after the body).
            final Path outline = bubbleOutline(body.size, bubble.tailTip!).shift(body.topLeft);
            expect(outline.contains(body.center), isTrue, reason: why);
            expect(
              outline.getBounds().bottom,
              closeTo(tip.dy, 3),
              reason: '$why: the outline runs round the tip',
            );
            expect(outline.getBounds().top, closeTo(body.top, 0.01), reason: why);
            final Stack layers = tester.widget<Stack>(
              find.descendant(of: find.byType(BoardBubble), matching: find.byType(Stack)).first,
            );
            int layerOf(String key) => layers.children.indexWhere(
              (Widget w) =>
                  w.key == Key(key) ||
                  find.descendant(of: find.byWidget(w), matching: find.byKey(Key(key))).evaluate().isNotEmpty,
            );
            expect(
              layerOf('bubble-tail'),
              lessThan(layerOf('bubble-body')),
              reason: '$why: the wedge under the body',
            );
            expect(
              layerOf('bubble-outline'),
              greaterThan(layerOf('bubble-body')),
              reason: '$why: the outline over it',
            );
            // The drawn wedge, in board coordinates: its base inside the body, its tip at the point (rounded off by 3).
            final Path wedge = bubbleWedgeTail(body.size, bubble.tailTip!).shift(body.topLeft);
            expect(wedge.contains(Offset(body.left + 38, body.bottom - 2)), isTrue, reason: '$why: the base');
            final Offset towardsBase = Offset(body.left + 38, body.bottom - 4) - tip;
            expect(
              wedge.contains(tip + towardsBase / towardsBase.distance * 8),
              isTrue,
              reason: '$why: reaches the tip',
            );
            expect(wedge.getBounds().bottom, closeTo(tip.dy, 3), reason: '$why: the tip, rounded');
            // Out of the bottle's tap area: no point of the area's edges facing the bubble lies inside the wedge.
            final Rect bottle = rectOf(tester, 'home-island-bottle-box');
            for (double t = 0; t <= 1; t += 1 / 400) {
              final Offset onTop = Offset(bottle.left + t * bottle.width, bottle.top);
              final Offset onLeft = Offset(bottle.left, bottle.top + t * bottle.height);
              expect(
                wedge.contains(onTop) || wedge.contains(onLeft),
                isFalse,
                reason: '$why: over the bottle',
              );
            }
            expect(bottle.contains(wedge.getBounds().topLeft), isFalse, reason: why);
            // The free sand between the wedge and the bottle at the bottle's top edge.
            double right = -1;
            for (double x = body.left; x < bottle.left; x += 0.25) {
              if (wedge.contains(Offset(x, bottle.top))) right = x;
            }
            debugPrint(
              'tail $why: tip ${tip.dx.toStringAsFixed(1)}, ${tip.dy.toStringAsFixed(1)}; '
              '${(tip.dy - body.bottom).toStringAsFixed(1)} below the bubble; '
              '${right < 0 ? 'above the bottle\'s top' : '${(bottle.left - right).toStringAsFixed(1)} left of the bottle at its top'}',
            );
          }
        }
      });
    }

    testWidgets('the map\'s bubble keeps its small tail on the right edge, and no outline', (
      WidgetTester tester,
    ) async {
      await pumpScreen(tester, const Center(child: BoardBubble(text: 'שָׁלוֹם')));
      expect(find.byKey(const Key('bubble-tail')), findsNothing);
      expect(find.byKey(const Key('bubble-outline')), findsNothing);
      expect(find.descendant(of: find.byType(BoardBubble), matching: find.byType(CustomPaint)), findsNothing);
      final Rect body = rectOf(tester, 'bubble-body');
      final Offset side = tester.getCenter(
        find.descendant(
          of: find.descendant(of: find.byType(BoardBubble), matching: find.byType(Transform)).first,
          matching: find.byType(Container),
        ),
      );
      expect(side.dx, closeTo(body.right - 1, 0.01), reason: 'right: -10, a 22 square');
      expect(side.dy, closeTo(body.bottom - 18 - 11, 0.01), reason: '18 above the bottom');
    });

    testWidgets('a touch on the bubble reaches the friend under it', (WidgetTester tester) async {
      final Taps taps = await pumpIsland(tester, board('tabletLandscape'));
      final Rect bubble = rectOf(tester, 'bubble-body');
      final Rect friend = rectOf(tester, 'home-island-companion');
      final Rect both = bubble.intersect(friend);
      expect(both.isEmpty, isFalse, reason: 'on this board the bubble reaches over the friend');
      await tester.tapAt(both.center);
      expect(taps.companion, 1);
    });

    testWidgets('no usable name: the welcome without one', (WidgetTester tester) async {
      await pumpIsland(tester, board('phoneSE'), name: '  ');
      expect(bubbleText(tester), He.nitziHomeWelcomeNoName.text);
    });

    testWidgets('a long name in the bubble is shortened with "…" so the bubble keeps two lines', (
      WidgetTester tester,
    ) async {
      await pumpIsland(tester, board('phoneSE'), name: names['wide_24']!, scale: 1.3);
      final String text = bubbleText(tester);
      expect(text, contains('…\u2069!'), reason: text);
      expect(linesIn(tester, 'bubble-body'), lessThanOrEqualTo(2));
    });

    testWidgets('a touch squashes the object at once, and a drag that starts on it never opens it', (
      WidgetTester tester,
    ) async {
      final Taps taps = await pumpIsland(tester, board('phone'));
      final Finder bottle = find.byKey(const Key('home-island-bottle'));
      double scaleOf() => tester
          .widget<Transform>(
            find
                .descendant(
                  of: find.byKey(const Key('home-island-bottle-box')),
                  matching: find.byType(Transform),
                )
                .first,
          )
          .transform
          .entry(0, 0);
      expect(scaleOf(), closeTo(1, 1e-9));
      final TestGesture finger = await tester.startGesture(tester.getCenter(bottle));
      await tester.pump();
      expect(scaleOf(), closeTo(0.96, 1e-9), reason: 'within one frame');
      await finger.moveBy(const Offset(0, 60));
      await finger.up();
      await tester.pump();
      expect(scaleOf(), closeTo(1, 1e-9));
      expect(taps.bottle, 0, reason: 'a drag never opens');
      await tester.tap(bottle);
      expect(taps.bottle, 1);
    });

    // The owner's phone check: Today's Adventure opened from the empty part above the bottle. The design's rectangle for
    // the bottle is only its box; a touch counts where the bottle is drawn (and 6 pt around it for the bob), at least 48
    // pt each way, and the same area is what a screen reader finds. The rest of the box lets a touch through.
    const Map<String, Size> bottleLive = <String, Size>{
      'phone': Size(136.56, 88.32),
      'phoneSE': Size(128.4, 84.08),
      'tabletLandscape': Size(185, 118),
      'tabletPortrait': Size(185, 118),
    };
    for (final Board b in boards) {
      testWidgets(
        '${b.name}: only the drawn bottle opens Today\'s Adventure, not the empty part of its box',
        (WidgetTester tester) async {
          final SemanticsHandle semantics = tester.ensureSemantics();
          final Taps taps = await pumpIsland(tester, b);
          final Rect box = rectOf(tester, 'home-island-bottle-box');
          final Rect live = rectOf(tester, 'home-island-bottle');
          expectRect(box, b.bottle, 'the box is the design\'s rectangle, unchanged');
          expect(live.size.width, closeTo(bottleLive[b.name]!.width, 0.01), reason: 'live width');
          expect(live.size.height, closeTo(bottleLive[b.name]!.height, 0.01), reason: 'live height');
          expect(live.shortestSide, greaterThanOrEqualTo(48), reason: 'a comfortable target');
          expect(box.expandToInclude(live), box, reason: 'inside the box');
          // The tilted bottle lies in the lower part of its box and a little to the right of its middle.
          expect(live.center.dx, closeTo(box.center.dx, 8), reason: 'centred on the picture');
          expect(live.center.dy, greaterThan(box.center.dy), reason: 'on the lower part, where it is drawn');

          // The empty part of the old rectangle: the corners, and the strip above the bottle.
          final List<Offset> empty = <Offset>[
            box.topLeft + const Offset(4, 4),
            box.topRight + const Offset(-4, 4),
            Offset(box.center.dx, box.top + 4),
            Offset(box.center.dx, live.top - 4),
            box.bottomLeft + const Offset(4, -2),
            box.bottomRight + const Offset(-4, -2),
          ];
          for (final Offset p in empty) {
            expect(live.contains(p), isFalse, reason: 'the test point $p is outside the live area');
            await tester.tapAt(p);
            expect(taps.bottle, 0, reason: '${b.name}: a touch at $p must not open it');
            final HitTestResult hit = tester.hitTestOnBinding(p);
            expect(
              hit.path.any((HitTestEntry e) => e.target is RenderSemanticsGestureHandler),
              isFalse,
              reason: '${b.name}: nothing takes a touch at $p, it reaches what lies under',
            );
          }

          // On the bottle: the middle and just inside every edge of the live area.
          for (final Offset p in <Offset>[
            live.center,
            live.topLeft + const Offset(2, 2),
            live.bottomRight - const Offset(2, 2),
          ]) {
            await tester.tapAt(p);
          }
          expect(taps.bottle, 3);

          // The screen reader finds the same area.
          final SemanticsNode node = tester.getSemantics(find.byKey(const Key('home-island-bottle')));
          expect(node.rect.size.width, closeTo(live.width, 0.01));
          expect(node.rect.size.height, closeTo(live.height, 0.01));
          semantics.dispose();
        },
      );
    }

    testWidgets('the book and the lighthouse keep their whole boxes: their pictures fill them', (
      WidgetTester tester,
    ) async {
      final Taps taps = await pumpIsland(tester, board('phone'));
      expect(find.byKey(const Key('home-island-book-box')), findsNothing);
      expect(find.byKey(const Key('home-island-lighthouse-box')), findsNothing);
      final Board b = board('phone');
      await tester.tapAt(b.book.topLeft + const Offset(4, 4));
      await tester.tapAt(b.lighthouse.topLeft + const Offset(4, 4));
      expect((taps.stickers, taps.hall), (1, 1));
    });

    testWidgets('screen-reader labels, in reading order: back, title, bottle, friend, book, lighthouse', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle semantics = tester.ensureSemantics();
      await pumpIsland(tester, board('phone'));
      expect(
        tester.getSemantics(find.byKey(const Key('home-island-bottle'))),
        isSemantics(label: He.homeDaily.text, isButton: true, hasTapAction: true),
      );
      expect(
        tester.getSemantics(find.byKey(const Key('home-island-book'))),
        isSemantics(label: He.stickersSemantics.text, isButton: true, hasTapAction: true),
      );
      expect(
        tester.getSemantics(find.byKey(const Key('home-island-lighthouse'))),
        isSemantics(label: He.hallSemantics.text, isButton: true, hasTapAction: true),
      );
      expect(
        tester.getSemantics(find.byKey(const Key('home-island-back'))),
        isSemantics(label: He.landBackSemantics.text, isButton: true, hasTapAction: true),
      );
      expect(
        tester.getSemantics(find.byKey(const Key('home-island-companion'))),
        isSemantics(isButton: true, hasTapAction: true),
      );
      double order(String key) =>
          (tester.getSemantics(find.byKey(Key(key))).sortKey! as OrdinalSortKey).order;
      expect(
        <double>[
          order('home-island-back'),
          order('home-island-title'),
          order('home-island-bottle'),
          order('home-island-companion'),
          order('home-island-book'),
          order('home-island-lighthouse'),
        ],
        <double>[0, 1, 2, 3, 4, 5],
      );
      // The labels under the objects are for the eye; the screen reader hears each object once.
      expect(find.bySemanticsLabel(He.homeHallLabel.text), findsNothing);
      semantics.dispose();
    });

    testWidgets(
      'something waits in the Hall: a trophy in the lantern window, in a warm halo, and the label says so',
      (WidgetTester tester) async {
        final SemanticsHandle semantics = tester.ensureSemantics();
        await pumpIsland(tester, board('phone'));
        expect(find.byKey(const Key('home-island-lantern-trophy')), findsNothing);
        await pumpIsland(tester, board('phone'), hallGlow: true);
        expect(
          tester.getSemantics(find.byKey(const Key('home-island-lighthouse'))),
          isSemantics(label: '${He.hallSemantics.text}, ${He.trophyNewSemantics.text}'),
        );
        // In the lighthouse's own coordinates (100 x 220, drawn contain and standing on the area's bottom): the window is
        // x 35..65, y 36..60; the trophy is 0.8 of its width, centred on (50, 48), and so is the halo.
        final Rect area = board('phone').lighthouse;
        final double k = area.height / 220;
        final Offset origin = Offset(area.center.dx - 50 * k, area.bottom - 220 * k);
        Offset at(double x, double y) => origin + Offset(x * k, y * k);
        final Rect trophy = rectOf(tester, 'home-island-lantern-trophy');
        expect(trophy.width, closeTo(24 * k, 0.01));
        expect(trophy.center, offsetMoreOrLessEquals(at(50, 48), epsilon: 0.01));
        expect(
          rectOf(tester, 'home-island-lantern-glow').center,
          offsetMoreOrLessEquals(at(50, 48), epsilon: 0.01),
        );
        final BoxShadow halo =
            (tester.widget<DecoratedBox>(find.byKey(const Key('home-island-lantern-glow'))).decoration
                    as BoxDecoration)
                .boxShadow!
                .single;
        expect((halo.color, halo.blurRadius), (const Color(0xAAFFD45C), 20));
        semantics.dispose();
      },
    );

    testWidgets('the book wears the sticker it is given, on its cover panel', (WidgetTester tester) async {
      const String latest = 'assets/art/stickers/sticker_07.svg';
      await pumpIsland(tester, board('tabletPortrait'), sticker: latest);
      final Finder cover = find.descendant(
        of: find.byKey(const Key('home-island-book')),
        matching: find.byWidgetPredicate((Widget w) => w is BoardSvg && w.asset == latest),
      );
      expect(cover, findsOneWidget);
      // The cover panel is x 33..63, y 19..49 of the book's 100 x 100.
      final Rect area = board('tabletPortrait').book;
      final double k = area.width / 100;
      expect(
        tester.getRect(cover),
        rectMoreOrLessEquals(
          Rect.fromLTWH(area.left + 33 * k, area.top + 19 * k, 30 * k, 30 * k),
          epsilon: 0.01,
        ),
      );
    });
  });

  group('the bottle bobs, gently and only with motion on', () {
    double angle(WidgetTester tester) {
      final Matrix4 m = tester
          .widgetList<Transform>(
            find.descendant(
              of: find.byKey(const Key('home-island-bottle-box')),
              matching: find.byType(Transform),
            ),
          )
          .elementAt(2)
          .transform;
      return m.entry(1, 0);
    }

    double lift(WidgetTester tester) => tester
        .widgetList<Transform>(
          find.descendant(
            of: find.byKey(const Key('home-island-bottle-box')),
            matching: find.byType(Transform),
          ),
        )
        .elementAt(1)
        .transform
        .getTranslation()
        .y;

    testWidgets('with reduce motion it stands still', (WidgetTester tester) async {
      await pumpIsland(tester, board('phone'));
      await tester.pump(const Duration(milliseconds: 600));
      expect(lift(tester), 0);
      expect(angle(tester), 0);
    });

    testWidgets('otherwise ±4 up and down and ±3° over 2.4 s, about its bottom centre', (
      WidgetTester tester,
    ) async {
      await pumpIsland(tester, board('phone'), still: false);
      double highest = 0;
      double widest = 0;
      for (int i = 0; i < 48; i++) {
        await tester.pump(const Duration(milliseconds: 50));
        highest = highest > lift(tester).abs() ? highest : lift(tester).abs();
        widest = widest > angle(tester).abs() ? widest : angle(tester).abs();
      }
      expect(highest, closeTo(4, 0.05));
      expect(widest, closeTo(math.sin(3 * math.pi / 180), 0.002));
      // A quarter of the way round (0.6 s) it is at its highest.
      await pumpIsland(tester, board('phone'), still: false);
      await tester.pump(const Duration(milliseconds: 600));
      expect(lift(tester), closeTo(-4, 0.05));
    });
  });
}
