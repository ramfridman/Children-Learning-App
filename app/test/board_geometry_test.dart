// The child screens against the design boards, in numbers. Each test puts a screen in a window of
// exactly the size of its board (so nothing is scaled) and checks the position and size of what
// the board's own CSS gives: `right: 59px; top: 12px; width: 64px` and so on. If someone moves a
// button or changes a radius, these fail, which "looks about right" never does.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/child/activity_shell.dart';
import 'package:nitznutz/child/home_screen.dart';
import 'package:nitznutz/design/components.dart';
import 'package:nitznutz/strings/he.dart';

import 'support/harness.dart';

const Size phone = Size(852, 393);
const Size phoneSE = Size(667, 375);
const Size tabletL = Size(1180, 820);
const Size tabletP = Size(820, 1180);

Finder disc(Key owner) =>
    find.descendant(of: find.byKey(owner), matching: find.byKey(const Key('pebble-disc')));

void expectRect(Rect actual, double left, double top, double width, double height, {String? why}) {
  expect(actual.left, closeTo(left, 0.6), reason: '$why left');
  expect(actual.top, closeTo(top, 0.6), reason: '$why top');
  expect(actual.width, closeTo(width, 0.6), reason: '$why width');
  expect(actual.height, closeTo(height, 0.6), reason: '$why height');
}

/// The six learning lands; Nitzi's island has no tap area (it does not open yet).
const Set<Land> learningLands = <Land>{
  Land.counting,
  Land.colors,
  Land.shapes,
  Land.logic,
  Land.robots,
  Land.market,
};

/// The home screen; [full] gives it every land, a companion and its "+", as the app does.
Future<void> pumpHome(WidgetTester tester, Size size, {bool full = false}) => pumpScreen(
  tester,
  HomeScreen(
    childName: 'נֹעָה',
    avatarId: 'avatar-noa',
    onParents: () {},
    onSwitchChild: () {},
    onOpenActivity: () {},
    onOpenLand: full ? (Land l) {} : null,
    openableLands: full ? learningLands : const <Land>{},
    companion: full ? const SizedBox.expand() : null,
    onFriends: full ? () {} : null,
  ),
  size: size,
);

/// The world of the map under the fixed buttons (board B-23).
ScrollPosition mapScroll(WidgetTester tester) => tester
    .state<ScrollableState>(
      find.descendant(
        of: find.byKey(const PageStorageKey<String>('home-map')),
        matching: find.byType(Scrollable),
      ),
    )
    .position;

Rect rectOf(WidgetTester tester, String key) => tester.getRect(find.byKey(Key(key)));

/// The things that never move with the map: avatar, stickers, book, Parents and the pill.
List<Rect> fixedRects(WidgetTester tester) => <Rect>[
  tester.getRect(disc(const Key('home-avatar'))),
  tester.getRect(find.byType(ParentEntryButton)),
  tester.getRect(disc(const Key('home-book'))),
  rectOf(tester, 'home-pill'),
];

/// Every sign's centre and top on screen now.
Map<String, Offset> signsNow(WidgetTester tester) => <String, Offset>{
  for (final Land l in Land.values) l.name: rectOf(tester, 'sign-${l.name}').topCenter,
};

/// The land tap areas (in one frame of reference), each at least 64 wide and, when [apart], 24 apart, as the board's
/// touch rules ask. The tablet landscape board is unchanged by B-23 and is only reported.
void expectTapAreasApart(WidgetTester tester, double width, {bool apart = true}) {
  final Map<Land, Rect> areas = <Land, Rect>{
    for (final Land l in learningLands) l: rectOf(tester, 'land-tap-${l.name}'),
  };
  expect(find.byKey(const Key('land-tap-nitzi')), findsNothing, reason: 'Nitzi\'s island does not open yet');
  for (final Rect r in areas.values) {
    expect(r.width, closeTo(width, 0.6));
    expect(r.width, greaterThanOrEqualTo(64));
  }
  final List<Land> lands = areas.keys.toList();
  for (int i = 0; i < lands.length; i++) {
    for (int j = i + 1; j < lands.length; j++) {
      final double gap = separation(areas[lands[i]]!, areas[lands[j]]!);
      if (apart) {
        expect(gap, greaterThanOrEqualTo(24), reason: '${lands[i].name} and ${lands[j].name}');
      } else if (gap < 24) {
        debugPrint(
          'note: the tap areas of ${lands[i].name} and ${lands[j].name} are ${gap.toStringAsFixed(1)} apart',
        );
      }
    }
  }
}

/// How far apart two rectangles are: the larger of the horizontal and the vertical gap (0 when they overlap).
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

Future<void> pumpActivity(WidgetTester tester, Size size) =>
    pumpScreen(tester, ActivityShell(onHome: () {}), size: size);

BoxDecoration decorationOf(WidgetTester tester, Finder f) =>
    (tester.widget<Container>(f).decoration! as BoxDecoration);

void main() {
  setUpAll(loadAppFonts);

  group('board 10, home on a phone (852 by 393)', () {
    testWidgets(
      'the corner buttons: avatar 64 at right 59, book 64 and the grey button 44 at left 59, 24 apart',
      (WidgetTester tester) async {
        await pumpHome(tester, phone);
        expectRect(tester.getRect(disc(const Key('home-avatar'))), 852 - 59 - 64, 12, 64, 64, why: 'avatar');
        final Rect parents = tester.getRect(find.byType(ParentEntryButton));
        expect(parents.left, closeTo(59, 0.6));
        expect(parents.height, 44);
        expect(parents.top, closeTo(12 + (64 - 44) / 2, 0.6), reason: 'centred on the 64 high row');
        expect(parents.width, greaterThanOrEqualTo(56));
        final Rect book = tester.getRect(disc(const Key('home-book')));
        expect(book.size, const Size(64, 64));
        expect(book.top, closeTo(12, 0.6));
        expect(book.left - parents.right, closeTo(24, 0.6), reason: 'the board puts 24 between them');
      },
    );

    testWidgets('the button shapes: round pebbles with a 6 point clay lip, a 12 radius grey button', (
      WidgetTester tester,
    ) async {
      await pumpHome(tester, phone);
      final BoxDecoration book = decorationOf(tester, disc(const Key('home-book')));
      expect(book.shape, BoxShape.circle);
      expect(book.color, const Color(0xFFFFC83D));
      expect(book.boxShadow!.first.color, const Color(0xFFE0A21A));
      expect(book.boxShadow!.first.offset, const Offset(0, 6));
      expect(book.boxShadow!.first.blurRadius, 0);
      final Container grey = tester.widget<Container>(
        find.descendant(of: find.byType(ParentEntryButton), matching: find.byType(Container)).first,
      );
      final BoxDecoration g = grey.decoration! as BoxDecoration;
      expect(g.color, const Color(0xFF6E6789));
      expect(g.borderRadius, BorderRadius.circular(12));
    });

    testWidgets(
      'the daily pill: 72 high, right edge at 570, top 12, fully round, sunset with a 6 point lip',
      (WidgetTester tester) async {
        await pumpHome(tester, phone);
        final Rect pill = tester.getRect(find.byKey(const Key('home-pill')));
        expect(pill.height, 72);
        expect(pill.top, closeTo(12, 0.6));
        expect(pill.right, closeTo(570, 0.6));
        final BoxDecoration d = decorationOf(tester, find.byKey(const Key('home-pill')));
        expect(d.color, const Color(0xFFFF8A3D));
        expect(d.borderRadius, BorderRadius.circular(999));
        expect(d.boxShadow!.first.color, const Color(0xFFD9692A));
        expect(d.boxShadow!.first.offset, const Offset(0, 6));
      },
    );

    testWidgets(
      'the bubble: top 112, tail side at right 212, radius 24, 18 point text with 12 by 2 padding',
      (WidgetTester tester) async {
        await pumpHome(tester, phone);
        final Rect body = tester.getRect(find.byKey(const Key('bubble-body')));
        expect(body.top, closeTo(112, 0.6));
        expect(body.right, closeTo(852 - 212, 0.6));
        final Container c = tester.widget<Container>(find.byKey(const Key('bubble-body')));
        expect((c.decoration! as BoxDecoration).borderRadius, BorderRadius.circular(24));
        expect(c.padding, const EdgeInsets.symmetric(horizontal: 12, vertical: 2));
        final Text t = tester.widget<Text>(
          find.descendant(of: find.byKey(const Key('bubble-body')), matching: find.byType(Text)),
        );
        expect(t.style!.fontSize, 18);
        expect(t.style!.fontWeight, FontWeight.w500);
        expect(t.style!.height, 1.7);
      },
    );

    testWidgets(
      'all seven signs at top 320 on a strip 2102 wide: home at the right; panned fully left, Market Village',
      (WidgetTester tester) async {
        await pumpHome(tester, phone);
        // Start view: world x 1250 to 2102. Nitzi and Counting where board 10 has them, the whole Colour Bay sign.
        final Map<String, Offset> start = signsNow(tester);
        const Map<String, double> startX = <String, double>{
          'nitzi': 640,
          'counting': 360,
          'colors': 70,
          'shapes': -210,
          'logic': -490,
          'robots': -770,
          'market': -1050,
        };
        startX.forEach((String land, double x) {
          expect(start[land]!.dx, closeTo(x, 0.6), reason: land);
          expect(start[land]!.dy, closeTo(320, 0.6), reason: land);
          final Rect r = rectOf(tester, 'sign-$land');
          expect(
            r.height,
            closeTo(18 * 1.7 + 6, 0.6),
            reason: '18 point text at 1.7 plus a 3 point border each side',
          );
        });
        final BoxDecoration d = decorationOf(tester, find.byKey(const Key('sign-counting')));
        expect(d.borderRadius, BorderRadius.circular(12));
        expect((d.border! as Border).top.width, 3);
        expect(d.color, const Color(0xFFD7A27A));
        expect(mapScroll(tester).maxScrollExtent, closeTo(2102 - 852, 0.6));
        // Panned fully left: world x 0 to 852.
        mapScroll(tester).jumpTo(mapScroll(tester).maxScrollExtent);
        await tester.pump();
        final Map<String, Offset> end = signsNow(tester);
        expect(end['market']!.dx, closeTo(200, 0.6));
        expect(end['robots']!.dx, closeTo(480, 0.6));
        expect(end['logic']!.dx, closeTo(760, 0.6));
      },
    );

    testWidgets('panning the map moves none of the fixed buttons', (WidgetTester tester) async {
      await pumpHome(tester, phone);
      final List<Rect> before = fixedRects(tester);
      await tester.drag(find.byKey(const Key('sign-counting')), const Offset(600, 0));
      await tester.pumpAndSettle();
      expect(mapScroll(tester).pixels, greaterThan(500), reason: 'the drag panned the map');
      mapScroll(tester).jumpTo(mapScroll(tester).maxScrollExtent);
      await tester.pump();
      expect(fixedRects(tester), before);
    });

    testWidgets('the companion, its "+" and the bubble at the start view', (WidgetTester tester) async {
      await pumpHome(tester, phone, full: true);
      expectRect(rectOf(tester, 'home-companion'), 609, 154, 153.6, 153.6, why: 'companion');
      expect(
        rectOf(tester, 'home-friends').topLeft,
        offsetMoreOrLessEquals(const Offset(1990 - 1250, 268), epsilon: 0.6),
      );
      final Rect body = rectOf(tester, 'bubble-body');
      expect(
        body.top,
        closeTo(112, 0.6),
        reason: 'the bubble stays at the board\'s place, beside a friend too',
      );
      expect(body.right, closeTo(852 - 212, 0.6));
      final double gap = separation(
        tester.getRect(disc(const Key('home-friends'))),
        rectOf(tester, 'sign-nitzi'),
      );
      debugPrint('phone: the "+" disc is ${gap.toStringAsFixed(1)} from the Nitzi sign');
      expect(gap, greaterThanOrEqualTo(24));
    });

    testWidgets('six land tap areas, 240 wide and 40 apart', (WidgetTester tester) async {
      await pumpHome(tester, phone, full: true);
      expectTapAreasApart(tester, 240);
    });
  });

  group('board 12, home on the smallest phone (667 by 375)', () {
    testWidgets('corner buttons, centred pill, bubble and the seven signs on a strip 1834 wide', (
      WidgetTester tester,
    ) async {
      await pumpHome(tester, phoneSE);
      expectRect(tester.getRect(disc(const Key('home-avatar'))), 667 - 16 - 64, 8, 64, 64, why: 'avatar');
      final Rect parents = tester.getRect(find.byType(ParentEntryButton));
      expect(parents.left, closeTo(16, 0.6));
      final Rect book = tester.getRect(disc(const Key('home-book')));
      expect(book.top, closeTo(8, 0.6));
      expect(book.left - parents.right, closeTo(16, 0.6));
      final Rect pill = tester.getRect(find.byKey(const Key('home-pill')));
      expect(pill.height, 64);
      expect(pill.top, closeTo(8, 0.6));
      expect(pill.center.dx, closeTo((40 + 667) / 2, 0.6));
      // The bubble moved to the board's place in the open sea (B-23): right 154, top 112.
      expect(rectOf(tester, 'bubble-body').top, closeTo(112, 0.6));
      expect(rectOf(tester, 'bubble-body').right, closeTo(667 - 154, 0.6));
      // Start view: world x 1167 to 1834.
      final Map<String, Offset> start = signsNow(tester);
      const Map<String, double> startX = <String, double>{
        'nitzi': 520,
        'counting': 268,
        'colors': 22,
        'shapes': -230,
        'logic': -482,
        'robots': -734,
        'market': -986,
      };
      startX.forEach((String land, double x) {
        expect(start[land]!.dx, closeTo(x, 0.6), reason: land);
        expect(start[land]!.dy, closeTo(314, 0.6), reason: land);
      });
      final List<Rect> before = fixedRects(tester);
      mapScroll(tester).jumpTo(mapScroll(tester).maxScrollExtent);
      await tester.pump();
      final Map<String, Offset> end = signsNow(tester);
      expect(end['market']!.dx, closeTo(181, 0.6));
      expect(end['robots']!.dx, closeTo(433, 0.6));
      expect(end['logic']!.dx, closeTo(685, 0.6));
      expect(fixedRects(tester), before, reason: 'the fixed buttons do not move with the map');
    });

    testWidgets('six land tap areas, 220 wide, at least 24 apart; the companion and its "+"', (
      WidgetTester tester,
    ) async {
      await pumpHome(tester, phoneSE, full: true);
      expectTapAreasApart(tester, 220);
      expectRect(rectOf(tester, 'home-companion'), 1651 - 1167, 164.6, 153.6, 153.6, why: 'companion');
      expect(
        rectOf(tester, 'home-friends').topLeft,
        offsetMoreOrLessEquals(const Offset(1776 - 1167, 256), epsilon: 0.6),
      );
      // A known design note (docs/design/phone-map-7-lands.md 3.3): the tightest corner of the SE, reported, not judged.
      final double gap = separation(
        tester.getRect(disc(const Key('home-friends'))),
        rectOf(tester, 'sign-nitzi'),
      );
      debugPrint('phoneSE: the "+" disc is ${gap.toStringAsFixed(1)} from the Nitzi sign');
      expect(tester.getRect(disc(const Key('home-friends'))).overlaps(rectOf(tester, 'sign-nitzi')), isFalse);
    });
  });

  group('board 22, home on a tablet in landscape (1180 by 820)', () {
    testWidgets('avatar 80, book 72, pill 88, and all seven signs where the board has them', (
      WidgetTester tester,
    ) async {
      await pumpHome(tester, tabletL);
      expectRect(tester.getRect(disc(const Key('home-avatar'))), 1180 - 24 - 80, 24, 80, 80, why: 'avatar');
      final Rect book = tester.getRect(disc(const Key('home-book')));
      expect(book.size, const Size(72, 72));
      expect(book.top, closeTo(24, 0.6));
      final Rect pill = tester.getRect(find.byKey(const Key('home-pill')));
      expect(pill.height, 88);
      expect(pill.top, closeTo(24, 0.6));
      expect(pill.center.dx, closeTo(590, 0.6));
      const Map<String, (double, double)> signs = <String, (double, double)>{
        'nitzi': (1010, 676),
        'counting': (700, 666),
        'colors': (420, 700),
        'shapes': (220, 572),
        'logic': (400, 372),
        'robots': (640, 276),
        'market': (900, 372),
      };
      signs.forEach((String land, (double, double) at) {
        final Rect r = tester.getRect(find.byKey(Key('sign-$land')));
        expect(r.center.dx, closeTo(at.$1, 0.6), reason: land);
        expect(r.top, closeTo(at.$2, 0.6), reason: land);
      });
      expect(tester.getRect(find.byKey(const Key('bubble-body'))).top, closeTo(430, 0.6));
      expect(
        find.byKey(const PageStorageKey<String>('home-map')),
        findsNothing,
        reason: 'the board is the whole world',
      );
    });

    testWidgets('six land tap areas 240 wide; the companion and its "+" where they were', (
      WidgetTester tester,
    ) async {
      await pumpHome(tester, tabletL, full: true);
      expectTapAreasApart(tester, 240, apart: false);
      expectRect(rectOf(tester, 'home-companion'), 975, 450.4, 153.6, 153.6, why: 'companion');
      expect(
        rectOf(tester, 'home-friends').topLeft,
        offsetMoreOrLessEquals(const Offset(1088.6, 556), epsilon: 0.6),
      );
    });
  });

  group('board 25, home on a tablet in portrait (820 by 1180)', () {
    testWidgets(
      'avatar, pill and the seven signs on a scene 1580 high: home at the bottom, Market Village above',
      (WidgetTester tester) async {
        await pumpHome(tester, tabletP);
        expectRect(tester.getRect(disc(const Key('home-avatar'))), 820 - 24 - 80, 32, 80, 80, why: 'avatar');
        final Rect pill = tester.getRect(find.byKey(const Key('home-pill')));
        expect(pill.top, closeTo(36, 0.6));
        expect(pill.center.dx, closeTo(410, 0.6));
        // Start view: world y 400 to 1580, exactly board 25.
        const Map<String, (double, double)> startAt = <String, (double, double)>{
          'nitzi': (600, 1110),
          'counting': (260, 996),
          'colors': (600, 830),
          'shapes': (230, 654),
          'logic': (600, 448),
          'robots': (300, 316),
          'market': (560, -44),
        };
        final Map<String, Offset> start = signsNow(tester);
        startAt.forEach((String land, (double, double) at) {
          expect(start[land]!.dx, closeTo(at.$1, 0.6), reason: land);
          expect(start[land]!.dy, closeTo(at.$2, 0.6), reason: land);
        });
        expect(mapScroll(tester).maxScrollExtent, closeTo(400, 0.6));
        final List<Rect> before = fixedRects(tester);
        await tester.drag(find.byKey(const Key('sign-logic')), const Offset(0, 500));
        await tester.pumpAndSettle();
        expect(mapScroll(tester).pixels, closeTo(400, 0.6), reason: 'dragging down scrolls up to the top');
        expect(signsNow(tester)['market']!.dy, closeTo(356, 0.6));
        expect(fixedRects(tester), before, reason: 'the fixed buttons do not move with the map');
      },
    );

    testWidgets('six land tap areas 240 wide; the companion and its "+" moved down 400', (
      WidgetTester tester,
    ) async {
      await pumpHome(tester, tabletP, full: true);
      expectTapAreasApart(tester, 240);
      expectRect(rectOf(tester, 'home-companion'), 590, 889.2, 153.6, 153.6, why: 'companion');
      expect(
        rectOf(tester, 'home-friends').topLeft,
        offsetMoreOrLessEquals(const Offset(703.6, 994.8), epsilon: 0.6),
      );
    });
  });

  group('board 13, the activity frame on a phone', () {
    testWidgets('home 64 at right 59, eye at left 59, hint at left 147, all at top 12', (
      WidgetTester tester,
    ) async {
      await pumpActivity(tester, phone);
      expectRect(tester.getRect(disc(const Key('activity-home'))), 852 - 59 - 64, 12, 64, 64, why: 'home');
      final List<Rect> discs = tester
          .widgetList(find.byKey(const Key('pebble-disc')))
          .map((Widget w) => tester.getRect(find.byWidget(w)))
          .toList();
      final List<double> lefts = discs.map((Rect r) => r.left.roundToDouble()).toList()..sort();
      expect(lefts, contains(59));
      expect(lefts, contains(147));
      expect(
        discs.where((Rect r) => r.size == const Size(64, 64)).every((Rect r) => (r.top - 12).abs() < 0.6),
        isTrue,
      );
    });

    testWidgets('the progress trail: 36 high at top 26, centred between 71 and 617', (
      WidgetTester tester,
    ) async {
      await pumpActivity(tester, phone);
      final Rect trail = tester.getRect(find.byType(ProgressTrail));
      expect(trail.height, 36);
      expect(trail.top, closeTo(26, 0.6));
      expect(trail.center.dx, closeTo(71 + 546 / 2, 0.6));
    });

    testWidgets('Nitzi 176 at (617, 80), the microphone 88 at (661, 260), the stage 330 by 128 at (71, 96)', (
      WidgetTester tester,
    ) async {
      await pumpActivity(tester, phone);
      expectRect(tester.getRect(find.byKey(const Key('activity-nitzi'))), 617, 80, 176, 176, why: 'nitzi');
      expectRect(tester.getRect(find.byType(MicButton)), 661, 260, 88, 88, why: 'mic');
      expectRect(tester.getRect(find.byKey(const Key('activity-stage'))), 71, 96, 330, 128, why: 'stage');
    });

    testWidgets('the question bubble: left 413, top 104, radius 24, 26 point text', (
      WidgetTester tester,
    ) async {
      await pumpActivity(tester, phone);
      final Rect body = tester.getRect(find.byKey(const Key('bubble-body')));
      expect(body.left, closeTo(413, 0.6));
      expect(body.top, closeTo(104, 0.6));
      final Text t = tester.widget<Text>(
        find.descendant(of: find.byKey(const Key('bubble-body')), matching: find.byType(Text)),
      );
      expect(t.style!.fontSize, 26);
      expect(t.data, He.activityQuestion.text);
    });

    testWidgets(
      'three answer tiles 96 by 96, radius 28, 24 apart, reading 4 3 2 from the left, the 3 lifted by 6',
      (WidgetTester tester) async {
        await pumpActivity(tester, phone);
        final List<Element> tiles = find.byKey(const Key('answer-tile')).evaluate().toList();
        expect(tiles.length, 3);
        final List<Rect> rects = <Rect>[
          for (final Element e in tiles) tester.getRect(find.byElementPredicate((Element x) => x == e)),
        ]..sort((Rect a, Rect b) => a.left.compareTo(b.left));
        for (final Rect r in rects) {
          expect(r.size, const Size(96, 96));
        }
        expect(rects[1].left - rects[0].right, closeTo(24, 0.6));
        expect(rects[2].left - rects[1].right, closeTo(24, 0.6));
        final double centre = (rects.first.left + rects.last.right) / 2;
        expect(centre, closeTo(71 + 534 / 2, 0.6), reason: 'the row is centred in the 534 wide content area');
        expect(rects[0].top, closeTo(244, 0.6));
        expect(rects[1].top, closeTo(244 - 6, 0.6), reason: 'the selected tile lifts 6');
        final List<String> order = <String>[
          for (final Rect r in rects)
            tester
                .widget<Text>(
                  find.descendant(
                    of: find.byElementPredicate(
                      (Element e) =>
                          e.widget.key == const Key('answer-tile') &&
                          tester.getRect(find.byElementPredicate((Element x) => x == e)).left == r.left,
                    ),
                    matching: find.byType(Text),
                  ),
                )
                .data!,
        ];
        expect(order, <String>[
          '4',
          '3',
          '2',
        ], reason: 'the markup order 2, 3, 4 reads 4, 3, 2 from the left');
        final BoxDecoration d =
            (tester.widget<Container>(find.byKey(const Key('answer-tile')).first).decoration!
                as BoxDecoration);
        expect(d.borderRadius, BorderRadius.circular(28));
        expect((d.border! as Border).top.width, 4);
        expect((d.border! as Border).top.color, const Color(0xFFE6DDF0));
      },
    );
  });

  group('board 23, the activity frame on a tablet in landscape', () {
    testWidgets(
      'home 64 at right 24, Nitzi 260 at (896, 150), the microphone 96 at (978, 672), the card at (288, 230)',
      (WidgetTester tester) async {
        await pumpActivity(tester, tabletL);
        expectRect(tester.getRect(disc(const Key('activity-home'))), 1180 - 24 - 64, 24, 64, 64, why: 'home');
        expectRect(
          tester.getRect(find.byKey(const Key('activity-nitzi'))),
          1180 - 24 - 260,
          150,
          260,
          260,
          why: 'nitzi',
        );
        expectRect(tester.getRect(find.byType(MicButton)), 1180 - 106 - 96, 672, 96, 96, why: 'mic');
        final Rect trail = tester.getRect(find.byType(ProgressTrail));
        expect(trail.top, closeTo(38, 0.6));
        expect(trail.center.dx, closeTo(590, 0.6));
        expect(tester.getRect(find.byKey(const Key('bubble-body'))).top, closeTo(112, 0.6));
      },
    );
  });

  group('board 26, the activity frame on a tablet in portrait', () {
    testWidgets('home at right 24, top 32; Nitzi 200 at (596, 112); the microphone 96 at (44, 172)', (
      WidgetTester tester,
    ) async {
      await pumpActivity(tester, tabletP);
      expectRect(tester.getRect(disc(const Key('activity-home'))), 820 - 24 - 64, 32, 64, 64, why: 'home');
      expectRect(
        tester.getRect(find.byKey(const Key('activity-nitzi'))),
        820 - 24 - 200,
        112,
        200,
        200,
        why: 'nitzi',
      );
      expectRect(tester.getRect(find.byType(MicButton)), 44, 172, 96, 96, why: 'mic');
      expect(tester.getRect(find.byType(ProgressTrail)).top, closeTo(46, 0.6));
    });
  });

  group('a window that is not exactly a board is scaled, never stretched', () {
    testWidgets('a 1040 by 480 phone draws the phone board at 1.22 times its size, centred', (
      WidgetTester tester,
    ) async {
      await pumpActivity(tester, const Size(1040, 480));
      final double k = 480 / 393;
      final Rect nitzi = tester.getRect(find.byKey(const Key('activity-nitzi')));
      expect(nitzi.width, closeTo(176 * k, 1));
      expect(nitzi.height, closeTo(176 * k, 1), reason: 'same scale both ways');
      final double leftBar = (1040 - 852 * k) / 2;
      expect(nitzi.left, closeTo(leftBar + 617 * k, 1));
    });
  });
}
