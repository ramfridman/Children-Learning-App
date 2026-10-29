// QA, B-26 step 2: an independent, adversarial check of the home island's sign on the map (the fit, the placement, the
// taps, the semantics, the bubble that only speaks), beyond the developer's home_sign_test.dart
// (docs/qa/b26-step2-verification.md). Its two defects, QA-25 and QA-26, were fixed in the step 2 follow-up (the tablet
// bubble at most 210 wide, broken after the name); QA-29 in step 3 (a name too long for its line is shortened in the
// bubble too). All their tests run in every run.
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/child/home_island_name.dart';
import 'package:nitznutz/child/home_screen.dart';
import 'package:nitznutz/design/board.dart';
import 'package:nitznutz/design/layout.dart';
import 'package:nitznutz/strings/he.dart';

import 'support/app_harness.dart';
import 'support/harness.dart';

/// A board, the home sign's box in world x (docs/design/nitzi-home.md section 4, table "Width box per board"), and
/// the world x of the Counting Hills sign's centre (from the board spec), which gives the world-to-screen offset.
typedef Board = ({String name, Size size, double boxLeft, double boxRight, double countingX});

const List<Board> boards = <Board>[
  (name: 'phone', size: Size(852, 393), boxLeft: 1770, boxRight: 1978, countingX: 1610),
  (name: 'phoneSE', size: Size(667, 375), boxLeft: 1577, boxRight: 1764, countingX: 1435),
  (name: 'tabletLandscape', size: Size(1180, 820), boxLeft: 890, boxRight: 1130, countingX: 700),
  (name: 'tabletPortrait', size: Size(820, 1180), boxLeft: 480, boxRight: 720, countingX: 260),
];

/// QA's own names: none of them is in the developer's list.
const Map<String, String> qaNames = <String, String>{
  'geresh': 'ג\'ורג\'ינה',
  'geresh_curly_long': 'צ’ארלי-ג’ורג’ינה-ז’אן',
  'hyphen': 'אנה-מריה',
  'maqaf_long': 'אביגיל־אלכסנדרה־שושנה',
  'latin_accents': 'Zoë Élodie Ñúñez-Øverås',
  'latin_wide': 'WWWWWWWWWWWWWWWWWWWW',
  'one_letter': 'א',
  'two_letters': 'אב',
  'two_latin': 'Jo',
  'wide_6': 'שששששש',
  'wide_9': 'ששששששששש',
  'wide_12': 'שששששששששששש',
  'wide_40': 'שששששששששששששששששששששששששששששששששששששששש',
  'nikud': 'נֹעָה',
  'nikud_long': 'אֲבִיגַיִל-אֲלֶכְּסַנְדְּרָה',
  'mixed_scripts': 'Noa נועה',
  'spaces_and_bidi': '  \u200Fמיכל \u202Aבת\u202C  שבע  ',
  'digits_only': '2018',
  'emoji_only': '🦊🌈',
  'blank': '   ',
  'empty': '',
};

const List<double> scales = <double>[1.0, 1.15, 1.3, 2.0];

const Set<String> gereshes = <String>{'\'', '׳', '’', '‘', '`'};
const Set<String> separators = <String>{' ', '-', '־'};

class Calls {
  int home = 0;
  int companion = 0;
  int friends = 0;
  final List<Land> lands = <Land>[];
}

Future<Calls> pumpHome(
  WidgetTester tester,
  Size size, {
  HomeIslandName? island,
  bool opens = true,
  Set<Land>? openable,
  Offset? mouth,
  String childName = 'נועה',
}) async {
  final Calls calls = Calls();
  await pumpScreen(
    tester,
    HomeScreen(
      childName: childName,
      avatarId: 'avatar-noa',
      onParents: () {},
      onSwitchChild: () {},
      onOpenActivity: () {},
      onOpenLand: calls.lands.add,
      openableLands:
          openable ??
          const <Land>{Land.counting, Land.colors, Land.shapes, Land.logic, Land.robots, Land.market},
      companion: const SizedBox.expand(),
      companionMouth: mouth,
      onCompanion: () => calls.companion++,
      onFriends: () => calls.friends++,
      homeIsland: island,
      onOpenHome: opens ? () => calls.home++ : null,
    ),
    size: size,
  );
  return calls;
}

/// Every flex in the tree whose children run past it, with the keys above it (so the known QA-19 pill can be told
/// apart from anything new).
List<String> overflowingFlexes(WidgetTester tester) {
  final List<String> out = <String>[];
  for (final Element e in find.byWidgetPredicate((Widget w) => w is Flex).evaluate()) {
    final RenderFlex flex = e.renderObject! as RenderFlex;
    final bool horizontal = flex.direction == Axis.horizontal;
    double used = 0;
    for (RenderBox? c = flex.firstChild; c != null; c = (c.parentData! as FlexParentData).nextSibling) {
      used += horizontal ? c.size.width : c.size.height;
    }
    final double room = horizontal ? flex.size.width : flex.size.height;
    if (used > room + 0.01) {
      final List<String> keys = <String>[];
      e.visitAncestorElements((Element a) {
        if (a.widget.key is ValueKey<String>) keys.add((a.widget.key! as ValueKey<String>).value);
        return true;
      });
      out.add('${(used - room).toStringAsFixed(1)} past, under ${keys.take(3).join(' < ')}');
    }
  }
  return out;
}

Finder signText() => find.descendant(of: find.byKey(const Key('sign-nitzi')), matching: find.byType(Text));

Rect rectOf(WidgetTester tester, String key) => tester.getRect(find.byKey(Key(key)));

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

/// The width of [text] in the sign's style at [size], measured with [scale] (independent of the product's painter).
double measure(String text, double size, double scale) {
  final TextPainter p = TextPainter(
    text: TextSpan(
      text: text,
      style: TextStyle(fontFamily: 'Heebo', fontSize: size, fontWeight: FontWeight.w700, height: 1.7),
    ),
    textDirection: TextDirection.rtl,
    textScaler: TextScaler.linear(scale),
    maxLines: 1,
  )..layout();
  final double w = p.width;
  p.dispose();
  return w;
}

/// The name as shown between the isolates of a sign line, without the ellipsis.
String shownName(String line) {
  final int a = line.indexOf('\u2068');
  final int b = line.lastIndexOf('\u2069');
  final String inner = line.substring(a + 1, b);
  return inner.endsWith(ellipsis) ? inner.substring(0, inner.length - 1) : inner;
}

void main() {
  setUpAll(loadAppFonts);

  group('breaking the fit: QA names x text scale x board', () {
    for (final Board b in boards) {
      for (final double scale in scales) {
        for (final MapEntry<String, String> n in qaNames.entries) {
          testWidgets('${b.name} x$scale ${n.key}', (WidgetTester tester) async {
            final List<FlutterErrorDetails> errors = <FlutterErrorDetails>[];
            final void Function(FlutterErrorDetails)? before = FlutterError.onError;
            FlutterError.onError = errors.add;
            tester.platformDispatcher.textScaleFactorTestValue = scale;
            final HomeIslandName island = homeIslandName(n.value);
            final SemanticsHandle sem = tester.ensureSemantics();
            try {
              await pumpHome(tester, b.size, island: island);
            } finally {
              FlutterError.onError = before;
              tester.platformDispatcher.clearTextScaleFactorTestValue();
            }
            // 1. No exception except a flex overflow, and no flex overflowing except the daily pill (QA-19, open).
            for (final FlutterErrorDetails e in errors) {
              expect('${e.exception}', contains('RenderFlex overflowed'), reason: '${e.exception}');
            }
            final List<String> flows = overflowingFlexes(tester);
            for (final String f in flows) {
              expect(f, contains('home-pill'), reason: 'an overflow other than the pill: $f');
            }
            if (flows.isNotEmpty) debugPrint('QA ${b.name} x$scale ${n.key}: known pill overflow: $flows');

            // 2. The sign stands inside its box.
            final Rect sign = rectOf(tester, 'sign-nitzi');
            final double dx = rectOf(tester, 'sign-counting').center.dx - b.countingX;
            expect(sign.left, greaterThanOrEqualTo(b.boxLeft + dx - 0.01), reason: 'left of the box: $sign');
            expect(sign.right, lessThanOrEqualTo(b.boxRight + dx + 0.01), reason: 'right of the box: $sign');

            // 3. The text is drawn inside the sign (also when the last guard scales it down).
            final Rect drawn = tester.getRect(signText());
            expect(drawn.left, greaterThanOrEqualTo(sign.left - 0.01));
            expect(drawn.right, lessThanOrEqualTo(sign.right + 0.01));
            expect(drawn.top, greaterThanOrEqualTo(sign.top - 0.01));
            expect(drawn.bottom, lessThanOrEqualTo(sign.bottom + 0.01));
            final bool squeezed = drawn.width < tester.getSize(signText()).width - 0.01;

            // 4. What it says.
            final Text text = tester.widget<Text>(signText());
            final String shown = text.data!;
            final double size = text.style!.fontSize!;
            expect(<double>[18, 17, 16, 15], contains(size));
            if (!island.isNamed) {
              expect(shown, He.homeIslandMine.text, reason: 'the fallback');
              expect(
                n.value.contains(RegExp(r'\p{L}', unicode: true)),
                isFalse,
                reason: 'fallback only without a letter',
              );
            } else {
              expect(shown, isNot(He.homeIslandMine.text));
              final String part = shownName(shown);
              expect(island.name.startsWith(part), isTrue, reason: '"$part" is a start of "${island.name}"');
              expect(part.characters.isNotEmpty, isTrue);
              if (shown != island.sign) {
                expect(shown.contains(ellipsis), isTrue);
                final String next = island.name.characters.skip(part.characters.length).first;
                expect(
                  gereshes.contains(next),
                  isFalse,
                  reason: 'a letter shown without its geresh: "$part"',
                );
                expect(
                  separators.contains(part.characters.last),
                  isFalse,
                  reason: 'ends on a separator: "$part"',
                );
                // The longest shortened form that fits at 15: the next longer distinct form does not fit there.
                final double maxText = b.boxRight - b.boxLeft - 46;
                final List<String> forms = <String>[
                  for (int k = 3; k < island.name.characters.length; k++) island.signShortened(k),
                  island.sign,
                ];
                final int at = forms.indexOf(shown);
                expect(at, greaterThanOrEqualTo(0), reason: 'a form of the shortening rule');
                final String longer = forms
                    .skip(at + 1)
                    .firstWhere((String f) => f != shown, orElse: () => '');
                if (longer.isNotEmpty && !squeezed) {
                  expect(
                    measure(longer, 15, scale),
                    greaterThan(maxText - 0.5),
                    reason: '"$longer" would fit',
                  );
                }
              } else {
                // Whole: and at the largest size that fits.
                if (size < 18) {
                  final double maxText = b.boxRight - b.boxLeft - 46;
                  expect(
                    measure(shown, size + 1, scale),
                    greaterThan(maxText - 0.5),
                    reason: 'a size up would fit',
                  );
                }
              }
            }

            // 5. Clear of the "+" and of the Counting Hills sign.
            expect(separation(sign, rectOf(tester, 'home-friends')), greaterThanOrEqualTo(12 - 0.01));
            // At text scale 2.0 the Counting Hills sign itself grows towards home (it has no fit; QA-19), so there only
            // "not touching" is asked of the home sign, which stays in its box.
            final double toCounting = separation(sign, rectOf(tester, 'sign-counting'));
            expect(
              toCounting,
              scale >= 2 ? greaterThan(0) : greaterThanOrEqualTo(24),
              reason: 'to Counting: $toCounting',
            );

            // 6. The screen reader gets the whole name, never the shortened one.
            expect(find.bySemanticsLabel(island.semantics), findsNWidgets(2), reason: 'sign and tap area');
            expect(island.semantics.contains(ellipsis), isFalse);
            sem.dispose();

            final Rect screen = Offset.zero & b.size;
            debugPrint(
              'QA sign ${b.name} x$scale ${n.key}: $size pt, w ${sign.width.toStringAsFixed(1)}, '
              '${shown == island.sign ? 'whole' : 'short'}${squeezed ? ', SQUEEZED by the guard' : ''}, '
              'bottom ${sign.bottom.toStringAsFixed(1)} of ${screen.bottom}, to Counting ${toCounting.toStringAsFixed(1)}',
            );
          });
        }
      }
    }
  });

  group('without onOpenHome: today\'s behaviour', () {
    for (final Board b in boards) {
      testWidgets('${b.name}: no Nitzi tap area, the pill is not a button, taps do nothing', (
        WidgetTester tester,
      ) async {
        final SemanticsHandle sem = tester.ensureSemantics();
        final Calls calls = await pumpHome(tester, b.size, opens: false);
        expect(find.byKey(const Key('land-tap-nitzi')), findsNothing);
        expect(tester.widget<Text>(signText()).data, He.landNitzi.text);
        expect(tester.widget<Text>(signText()).style!.fontSize, 18);
        final SemanticsNode pill = tester.getSemantics(find.byKey(const Key('home-pill')));
        expect(pill.getSemanticsData().flagsCollection.isButton, isFalse);
        expect(pill.getSemanticsData().hasAction(SemanticsAction.tap), isFalse);
        await tester.tap(find.byKey(const Key('home-pill')));
        await tester.tap(find.byKey(const Key('sign-nitzi')));
        expect(calls.home, 0);
        expect(calls.lands, isEmpty);
        sem.dispose();
      });
    }

    testWidgets('even if Nitzi were listed as openable, the home island never goes to onOpenLand', (
      WidgetTester tester,
    ) async {
      // `_openLand` does TrophyLand.values.byName and TrophyLand has no nitzi: reaching it would crash the app.
      for (final bool opens in <bool>[false, true]) {
        final Calls calls = await pumpHome(
          tester,
          boards.first.size,
          island: homeIslandName('נועה'),
          opens: opens,
          openable: Land.values.toSet(),
        );
        await tester.tap(find.byKey(const Key('sign-nitzi')));
        if (opens) {
          // The free strip of the island's tap area, left of the companion.
          final Rect area = rectOf(tester, 'land-tap-nitzi');
          final Rect friend = rectOf(tester, 'home-companion');
          await tester.tapAt(Offset((area.left + friend.left) / 2, area.center.dy));
        }
        expect(calls.lands, isEmpty, reason: 'opens $opens');
        expect(calls.home, opens ? 2 : 0);
      }
    });
  });

  group('the tap area and the companion', () {
    for (final Board b in boards) {
      testWidgets('${b.name}: the companion and the "+" keep their own taps over the home tap area', (
        WidgetTester tester,
      ) async {
        final Calls calls = await pumpHome(tester, b.size, island: homeIslandName('נועה'));
        await tester.tap(find.byKey(const Key('home-companion')));
        await tester.tap(find.byKey(const Key('home-friends')));
        expect(calls.companion, 1);
        expect(calls.friends, 1);
        expect(calls.home, 0);
        await tester.tap(find.byKey(const Key('sign-nitzi')));
        expect(calls.home, 1);
        expect(calls.lands, isEmpty);
      });
    }
  });

  group('a drag never opens the home', () {
    for (final Board b in boards) {
      testWidgets('${b.name}: a drag from the sign, the tap area or the pill', (WidgetTester tester) async {
        final Calls calls = await pumpHome(tester, b.size, island: homeIslandName('אלכסנדרה'));
        final Offset move = b.name == 'tabletPortrait' ? const Offset(0, -120) : const Offset(120, 0);
        await tester.drag(find.byKey(const Key('sign-nitzi')), move);
        await tester.pumpAndSettle();
        await pumpHome(tester, b.size, island: homeIslandName('אלכסנדרה'));
        await tester.drag(find.byKey(const Key('sign-nitzi')), -move);
        await tester.pumpAndSettle();
        await pumpHome(tester, b.size, island: homeIslandName('אלכסנדרה'));
        await tester.drag(find.byKey(const Key('home-pill')), const Offset(60, 0));
        await tester.pumpAndSettle();
        expect(calls.home, 0, reason: 'a drag is not a tap');
        expect(calls.lands, isEmpty);
      });
    }

    testWidgets('phone: a drag that starts on the sign moves the map', (WidgetTester tester) async {
      await pumpHome(tester, boards.first.size, island: homeIslandName('אלכסנדרה'));
      final ScrollPosition map = tester
          .state<ScrollableState>(
            find.descendant(
              of: find.byKey(const PageStorageKey<String>('home-map')),
              matching: find.byType(Scrollable),
            ),
          )
          .position;
      expect(map.pixels, 0);
      await tester.drag(find.byKey(const Key('sign-nitzi')), const Offset(200, 0));
      await tester.pumpAndSettle();
      expect(map.pixels, greaterThan(100));
    });
  });

  group('the bubble only speaks (the real app, four boards)', () {
    for (final (String n, Size s) in <(String, Size)>[
      ('phone', const Size(852, 393)),
      ('phoneSE', const Size(667, 375)),
      ('tabletLandscape', const Size(1180, 820)),
      ('tabletPortrait', const Size(820, 1180)),
    ]) {
      testWidgets('$n: a touch on the bubble reaches what is under it; its words stay readable', (
        WidgetTester tester,
      ) async {
        final AppRig rig = AppRig();
        await rig.seedFinishedSetup(name: 'נֹעָה');
        await rig.pump(tester, size: s);
        await tester.tap(find.text('נֹעָה'));
        await tester.pumpAndSettle();
        final SemanticsHandle sem = tester.ensureSemantics();
        await tester.pump();
        final Finder body = find.byKey(const Key('bubble-body'));
        expect(body, findsOneWidget);
        final String words = He.homeBubble.fill(<String, String>{'child': isolatedName('נֹעָה')});
        expect(find.text(words), findsOneWidget);
        expect(
          find.bySemanticsLabel(words),
          findsOneWidget,
          reason: 'the screen reader still reads the bubble',
        );
        final Rect bubble = tester.getRect(body);
        final RenderObject bubbleBox = tester.renderObject(body);
        for (final Offset p in <Offset>[
          bubble.center,
          bubble.centerLeft + const Offset(6, 0),
          bubble.centerRight - const Offset(6, 0),
        ]) {
          final HitTestResult hit = tester.hitTestOnBinding(p);
          final bool inBubble = hit.path.any((HitTestEntry e) {
            final Object t = e.target;
            if (t is! RenderObject) return false;
            for (RenderObject? r = t; r != null; r = r.parent) {
              if (identical(r, bubbleBox)) return true;
            }
            return false;
          });
          expect(inBubble, isFalse, reason: 'the bubble took the touch at $p');
        }
        expect(
          find.ancestor(
            of: body,
            matching: find.byWidgetPredicate((Widget w) => w is IgnorePointer && w.ignoring),
          ),
          findsOneWidget,
        );
        debugPrint('QA bubble $n: $bubble; counting sign ${rectOf(tester, 'sign-counting')}');
        sem.dispose();
      });
    }
  });

  group('the bubble and Counting Hills (the real app)', () {
    testWidgets('QA-25 (fixed): on the landscape tablet the bubble does not hide the Counting Hills stairs', (
      WidgetTester tester,
    ) async {
      final AppRig rig = AppRig();
      await rig.seedFinishedSetup(name: 'נֹעָה');
      await rig.pump(tester, size: const Size(1180, 820));
      await tester.tap(find.text('נֹעָה'));
      await tester.pumpAndSettle();
      expect(AppLayout.of(tester.element(find.byType(HomeScreen))).board, BoardClass.tabletLandscape);
      final Rect bubble = rectOf(tester, 'bubble-body');
      // The red stairs of Counting Hills end at x 747 in home_tablet_landscape.png (the scene does not move there).
      expect(bubble.left, greaterThanOrEqualTo(747 + 8), reason: 'the bubble covers the stairs: $bubble');
    });

    testWidgets('QA-26 (fixed): on the portrait tablet the bubble stays clear of the Counting Hills sign', (
      WidgetTester tester,
    ) async {
      final AppRig rig = AppRig();
      await rig.seedFinishedSetup(name: 'נֹעָה');
      await rig.pump(tester, size: const Size(820, 1180));
      await tester.tap(find.text('נֹעָה'));
      await tester.pumpAndSettle();
      final double gap = separation(rectOf(tester, 'bubble-body'), rectOf(tester, 'sign-counting'));
      expect(gap, greaterThanOrEqualTo(12), reason: 'bubble to Counting sign: $gap');
    });
  });

  group('re-verification: the tablet bubble is at most 210, phones one line, touches pass through', () {
    for (final (String n, Size s) in bubbleBoards) {
      testWidgets('$n: width, lines and touches for every name at text scale 1.0 and 1.3', (
        WidgetTester tester,
      ) async {
        final BubbleCheck c = await checkBubbles(tester, n, s);
        expect(c.problems, isEmpty, reason: c.problems.join('\n'));
      });
    }
    for (final (String n, Size s) in bubbleBoards.skip(2)) {
      testWidgets('QA-29 (fixed): $n: the bubble never takes more than two lines', (
        WidgetTester tester,
      ) async {
        final BubbleCheck c = await checkBubbles(tester, n, s);
        expect(c.tooManyLines, isEmpty, reason: c.tooManyLines.join('\n'));
      });
    }
  });
}

const List<(String, Size)> bubbleBoards = <(String, Size)>[
  ('phone', Size(852, 393)),
  ('phoneSE', Size(667, 375)),
  ('tabletLandscape', Size(1180, 820)),
  ('tabletPortrait', Size(820, 1180)),
];

/// Names as parents type them (unpointed, one pointed), up to the server's 24 letters; the bubble shows the raw
/// profile name.
const List<String> bubbleNames = <String>[
  'דן',
  'נועה',
  'נֹעָה',
  'אלכסנדרה',
  'אביגיל-אלכסנדרה',
  'אביגיל אלכסנדרה',
  'Alexandra',
  'שששששששששש',
  'אבגדהוזחטיכלמנסעפצקרשתאב',
];

typedef BubbleCheck = ({List<String> problems, List<String> tooManyLines});

/// The bubble for every name at text scale 1.0 and 1.3, beside the friend's real mouth (read from the app).
Future<BubbleCheck> checkBubbles(WidgetTester tester, String n, Size s) async {
  final AppRig rig = AppRig();
  await rig.seedFinishedSetup(name: 'נועה');
  await rig.pump(tester, size: s);
  await tester.tap(find.text('נועה'));
  await tester.pumpAndSettle();
  final Offset? mouth = tester.widget<HomeScreen>(find.byType(HomeScreen)).companionMouth;
  expect(mouth, isNotNull);
  final bool tablet = n.startsWith('tablet');
  final double font = tablet ? 24 : (n == 'phone' ? 20 : 18);
  final List<String> problems = <String>[];
  final List<String> tooManyLines = <String>[];
  for (final double scale in <double>[1.0, 1.3]) {
    for (final String name in bubbleNames) {
      final List<FlutterErrorDetails> errors = <FlutterErrorDetails>[];
      final void Function(FlutterErrorDetails)? before = FlutterError.onError;
      FlutterError.onError = errors.add;
      tester.platformDispatcher.textScaleFactorTestValue = scale;
      late final Calls calls;
      try {
        calls = await pumpHome(tester, s, mouth: mouth, childName: name);
      } finally {
        FlutterError.onError = before;
        tester.platformDispatcher.clearTextScaleFactorTestValue();
      }
      for (final FlutterErrorDetails e in errors) {
        if (!'${e.exception}'.contains('RenderFlex overflowed')) {
          problems.add('$scale "$name": ${e.exception}');
        }
      }
      for (final String f in overflowingFlexes(tester)) {
        if (!f.contains('home-pill')) problems.add('$scale "$name": overflow $f');
      }
      final Finder body = find.byKey(const Key('bubble-body'));
      final Rect r = tester.getRect(body);
      final RenderParagraph para = tester.renderObject<RenderParagraph>(
        find.descendant(of: body, matching: find.byType(RichText)),
      );
      final int lines = (para.size.height / (font * scale * 1.7)).round();
      final String text = tester.widget<Text>(find.descendant(of: body, matching: find.byType(Text))).data!;
      debugPrint(
        'QA bubble $n x$scale "$name": ${r.width.toStringAsFixed(1)} wide, $lines line(s), '
        'break ${text.contains('\n') ? 'after the name' : 'none'}, left ${r.left.toStringAsFixed(1)}, '
        'top ${r.top.toStringAsFixed(1)}',
      );
      if (tablet) {
        if (r.width > 210 + 0.01) problems.add('$scale "$name": ${r.width} wide');
        if (lines > 2) tooManyLines.add('$scale "$name": $lines lines');
      } else if (lines != 1) {
        problems.add('$scale "$name": $lines lines on a phone');
      }
      if (r.left < 0 || r.right > s.width || r.top < 0) problems.add('$scale "$name": off screen $r');
      // A touch on the middle of the bubble reaches the map under it, never the bubble.
      final HitTestResult hit = tester.hitTestOnBinding(r.center);
      final RenderObject box = tester.renderObject(body);
      final bool inBubble = hit.path.any((HitTestEntry e) {
        for (Object? t = e.target; t is RenderObject; t = t.parent) {
          if (identical(t, box)) return true;
        }
        return false;
      });
      if (inBubble) problems.add('$scale "$name": the bubble took the touch');
      if (calls.lands.isNotEmpty) problems.add('$scale "$name": a land opened');
    }
  }
  return (problems: problems, tooManyLines: tooManyLines);
}
