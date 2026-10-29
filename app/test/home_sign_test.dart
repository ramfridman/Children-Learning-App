// B-26 step 2: the home island's sign is named after the child and opens the child's home. The sign fits a box per
// board (docs/design/nitzi-home.md section 4): 18, 17, 16 or 15 points with the screen's own text scale, then the
// name shortened (whole parts first, then letters, with "…"), placed `clamp(centre - w / 2, boxLeft, boxRight - w)`.
// Checked on the four boards at text scale 1.0 and 1.3; goldens of three names on the phone and the SE.
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/child/home_island_name.dart';
import 'package:nitznutz/child/home_screen.dart';
import 'package:nitznutz/strings/he.dart';

import 'support/golden_comparator.dart';
import 'support/harness.dart';

/// A board, the home sign's box in world x, and the world x of the Counting Hills sign (centred, so it gives the
/// offset between the world and the screen at the start view).
typedef BoardBox = ({String name, Size size, double boxLeft, double boxRight, double countingX});

const List<BoardBox> boards = <BoardBox>[
  (name: 'phone', size: Size(852, 393), boxLeft: 1770, boxRight: 1978, countingX: 1610),
  (name: 'phoneSE', size: Size(667, 375), boxLeft: 1577, boxRight: 1764, countingX: 1435),
  (name: 'tabletLandscape', size: Size(1180, 820), boxLeft: 890, boxRight: 1130, countingX: 700),
  (name: 'tabletPortrait', size: Size(820, 1180), boxLeft: 480, boxRight: 720, countingX: 260),
];

/// The sample names of the brief: an everyday name, a long one, a double name, a Latin one, the server's 24, the
/// widest letter 24 times, the parent form's 40 in four parts, and no name.
final Map<String, String> names = <String, String>{
  'noa': 'נועה',
  'alexandra': 'אלכסנדרה',
  'avigail_alexandra': 'אביגיל-אלכסנדרה',
  'alexandra_latin': 'Alexandra',
  'long_24': 'אבגדהוזחטיכלמנסעפצקרשתאב',
  'wide_24': 'ש' * 24,
  'parts_40': 'אבגדהוזחטי אבגדהוזחטי אבגדהוזחטי אבגדהוזח',
  'none': '',
};

final String pdi = String.fromCharCode(0x2069);

const Set<Land> learningLands = <Land>{
  Land.counting,
  Land.colors,
  Land.shapes,
  Land.logic,
  Land.robots,
  Land.market,
};

/// What the callbacks of the map were asked to do.
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
  double scale = 1,
  Offset? mouth,
  String childName = 'נועה',
}) async {
  if (scale != 1) {
    tester.platformDispatcher.textScaleFactorTestValue = scale;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  }
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
      openableLands: learningLands,
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

/// How far the children of the first [Row] under [owner] run past the row (0 when they fit).
double rowOverflow(WidgetTester tester, Key owner) {
  final RenderFlex row = tester.renderObject<RenderFlex>(
    find.descendant(of: find.byKey(owner), matching: find.byType(Row)).first,
  );
  double children = 0;
  for (RenderBox? c = row.firstChild; c != null; c = (c.parentData! as FlexParentData).nextSibling) {
    children += c.size.width;
  }
  return children > row.size.width ? children - row.size.width : 0;
}

/// The one overflow the map already had before B-26 (QA-19, open): at text scale 1.3 the daily pill is wider than the
/// phone board's 270 point pill frame. It is taken out of the way only when it is really the pill's row that overflows.
void drainKnownPillOverflow(WidgetTester tester) {
  final Object? e = tester.takeException();
  if (e == null) return;
  expect('$e', contains('RenderFlex overflowed'), reason: '$e');
  expect(rowOverflow(tester, const Key('home-pill')), greaterThan(0), reason: 'QA-19 is the pill: $e');
}

Finder signText() => find.descendant(of: find.byKey(const Key('sign-nitzi')), matching: find.byType(Text));

Rect rectOf(WidgetTester tester, String key) => tester.getRect(find.byKey(Key(key)));

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

void main() {
  setUpAll(() async {
    await loadAppFonts();
    useTolerantGoldens(0.03);
  });

  group('the sign fits its box', () {
    for (final BoardBox b in boards) {
      for (final double scale in <double>[1, 1.3]) {
        for (final MapEntry<String, String> n in names.entries) {
          testWidgets('${b.name}, text scale $scale, ${n.key}', (WidgetTester tester) async {
            final HomeIslandName island = homeIslandName(n.value);
            await pumpHome(tester, b.size, island: island, scale: scale);
            if (b.name == 'phone' && scale > 1) {
              drainKnownPillOverflow(tester);
            } else {
              expect(tester.takeException(), isNull, reason: 'no overflow');
            }
            final Rect sign = rectOf(tester, 'sign-nitzi');
            final double dx = rectOf(tester, 'sign-counting').center.dx - b.countingX;
            final Rect box = Rect.fromLTRB(b.boxLeft + dx, sign.top, b.boxRight + dx, sign.bottom);
            expect(sign.left, greaterThanOrEqualTo(box.left - 0.01), reason: '$sign in $box');
            expect(sign.right, lessThanOrEqualTo(box.right + 0.01), reason: '$sign in $box');

            expect(rowOverflow(tester, const Key('sign-nitzi')), 0, reason: 'the row of the sign fits');
            // The text is drawn whole: inside the sign, at its own size (never squeezed by the last guard).
            final Text text = tester.widget<Text>(signText());
            final Rect drawn = tester.getRect(signText());
            expect(drawn.width, closeTo(tester.getSize(signText()).width, 0.01), reason: 'not scaled down');
            expect(
              sign.contains(drawn.topLeft) && sign.contains(drawn.bottomRight - const Offset(0.01, 0.01)),
              isTrue,
            );
            expect(homeSignSizes, contains(text.style!.fontSize));

            // What it says: the whole line, a shortened name, or the fallback.
            final String shown = text.data!;
            if (!island.isNamed) {
              expect(shown, He.homeIslandMine.text);
            } else if (shown != island.sign) {
              expect(shown, endsWith('…$pdi'));
              expect(text.style!.fontSize, greaterThanOrEqualTo(15));
              // The longest shortened form that fits at 15: one cluster more would not have fitted there.
              expect(<String>[for (int k = 3; k < 41; k++) island.signShortened(k)], contains(shown));
            }

            // Clear of the "+" (its tap area) and of the Counting Hills sign.
            expect(separation(sign, rectOf(tester, 'home-friends')), greaterThanOrEqualTo(12 - 0.01));
            expect(separation(sign, rectOf(tester, 'sign-counting')), greaterThanOrEqualTo(24));
            debugPrint(
              'home sign ${b.name} x$scale ${n.key}: ${text.style!.fontSize} pt, '
              'width ${sign.width.toStringAsFixed(1)}, ${shown == island.sign ? 'whole' : 'shortened'}',
            );
          });
        }
      }
    }
  });

  group('the fit, by the design-director\'s table (nitzi-home.md section 4)', () {
    testWidgets('a typical name is whole at 18 on every board', (WidgetTester tester) async {
      for (final BoardBox b in boards) {
        await pumpHome(tester, b.size, island: homeIslandName('נועה'));
        final Text text = tester.widget<Text>(signText());
        expect(text.data, homeIslandName('נועה').sign, reason: b.name);
        expect(text.style!.fontSize, 18, reason: b.name);
      }
    });

    testWidgets(
      'Alexandra is whole on the phone and the SE; the double name is shortened to its first part',
      (WidgetTester tester) async {
        for (final BoardBox b in boards.take(2)) {
          await pumpHome(tester, b.size, island: homeIslandName('אלכסנדרה'));
          expect(tester.widget<Text>(signText()).data, homeIslandName('אלכסנדרה').sign, reason: b.name);
          final HomeIslandName double = homeIslandName('אביגיל-אלכסנדרה');
          await pumpHome(tester, b.size, island: double);
          expect(tester.widget<Text>(signText()).data, endsWith('אביגיל…$pdi'), reason: b.name);
        }
      },
    );

    testWidgets('centred under the island while it fits; a wider sign is held at the box\'s right edge', (
      WidgetTester tester,
    ) async {
      final BoardBox phone = boards.first;
      await pumpHome(tester, phone.size, island: homeIslandName('נועה'));
      double dx = rectOf(tester, 'sign-counting').center.dx - phone.countingX;
      expect(rectOf(tester, 'sign-nitzi').center.dx - dx, closeTo(1890, 0.6));
      await pumpHome(tester, phone.size, island: homeIslandName('אלכסנדרה'));
      dx = rectOf(tester, 'sign-counting').center.dx - phone.countingX;
      expect(rectOf(tester, 'sign-nitzi').right - dx, closeTo(1978, 0.6));
    });

    testWidgets('no profile name given: Nitzi\'s island at 18, centred, exactly as before', (
      WidgetTester tester,
    ) async {
      await pumpHome(tester, boards.first.size, opens: false);
      final Text text = tester.widget<Text>(signText());
      expect(text.data, He.landNitzi.text);
      expect(text.style!.fontSize, 18);
      expect(rectOf(tester, 'sign-nitzi').center.dx, closeTo(1890 - 1250, 0.6));
    });

    test('the fit measures with the text scale it is given', () {
      final HomeIslandName island = homeIslandName('אלכסנדרה');
      final HomeSignFit at1 = fitHomeSign(island, 141, TextScaler.noScaling);
      final HomeSignFit at13 = fitHomeSign(island, 141, const TextScaler.linear(1.3));
      expect(at1.text, island.sign);
      expect(at1.width, lessThanOrEqualTo(141));
      expect(at13.width, lessThanOrEqualTo(141));
      expect(at13.text, isNot(island.sign), reason: 'at 1.3 the SE box needs the shortened name');
    });
  });

  group('the sign opens the child\'s home', () {
    testWidgets(
      'the sign and the free part of the island open it; the companion and its "+" keep their own taps',
      (WidgetTester tester) async {
        final Calls calls = await pumpHome(tester, boards.first.size, island: homeIslandName('נועה'));
        await tester.tap(find.byKey(const Key('sign-nitzi')));
        expect(calls.home, 1);
        // The free strip of the island's tap area, left of the companion.
        final Rect area = rectOf(tester, 'land-tap-nitzi');
        final Rect friend = rectOf(tester, 'home-companion');
        await tester.tapAt(Offset((area.left + friend.left) / 2, area.center.dy));
        expect(calls.home, 2);
        await tester.tap(find.byKey(const Key('home-companion')));
        await tester.tap(find.byKey(const Key('home-friends')));
        expect(calls.home, 2);
        expect(calls.companion, 1);
        expect(calls.friends, 1);
        expect(calls.lands, isEmpty, reason: 'the home island is never opened as a land');
      },
    );

    testWidgets('the tap area is under the companion and the "+", and names the whole island', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle semantics = tester.ensureSemantics();
      const String long = 'אבגדהוזחטי אבגדהוזחטי אבגדהוזחטי אבגדהוזח';
      await pumpHome(tester, boards[1].size, island: homeIslandName(long));
      expect(
        tester.getSemantics(find.byKey(const Key('land-tap-nitzi'))),
        matchesSemantics(label: 'האי של $long', isButton: true, hasTapAction: true),
      );
      final Iterable<Element> stack = find
          .ancestor(of: find.byKey(const Key('land-tap-nitzi')), matching: find.byType(Stack))
          .evaluate();
      final List<Widget> layers = (stack.first.widget as Stack).children;
      int indexOf(String key) => layers.indexWhere(
        (Widget w) =>
            find.descendant(of: find.byWidget(w), matching: find.byKey(Key(key))).evaluate().isNotEmpty,
      );
      expect(indexOf('land-tap-nitzi'), lessThan(indexOf('home-companion')));
      expect(indexOf('land-tap-nitzi'), lessThan(indexOf('home-friends')));
      semantics.dispose();
    });

    testWidgets('without onOpenHome the home island stays a sign, as before', (WidgetTester tester) async {
      final Calls calls = await pumpHome(
        tester,
        boards.first.size,
        island: homeIslandName('נועה'),
        opens: false,
      );
      expect(find.byKey(const Key('land-tap-nitzi')), findsNothing);
      await tester.tap(find.byKey(const Key('sign-nitzi')));
      expect(calls.home, 0);
      expect(calls.lands, isEmpty);
    });
  });

  group('the daily pill', () {
    testWidgets('it opens the home and is announced as a button', (WidgetTester tester) async {
      final SemanticsHandle semantics = tester.ensureSemantics();
      final Calls calls = await pumpHome(tester, boards.first.size);
      await tester.tap(find.byKey(const Key('home-pill')));
      expect(calls.home, 1);
      expect(
        tester.getSemantics(find.byKey(const Key('home-pill'))),
        matchesSemantics(label: He.homeDaily.text, isButton: true, hasTapAction: true),
      );
      semantics.dispose();
    });

    testWidgets('without onOpenHome it is not announced as a button, and a tap does nothing', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle semantics = tester.ensureSemantics();
      final Calls calls = await pumpHome(tester, boards.first.size, opens: false);
      await tester.tap(find.byKey(const Key('home-pill')));
      expect(calls.home, 0);
      expect(
        tester.getSemantics(find.byKey(const Key('home-pill'))),
        matchesSemantics(label: He.homeDaily.text),
      );
      semantics.dispose();
    });

    testWidgets('the three stops are not drawn until the daily plan exists', (WidgetTester tester) async {
      for (final BoardBox b in boards) {
        await pumpHome(tester, b.size);
        final Iterable<Container> discs = tester
            .widgetList<Container>(
              find.descendant(of: find.byKey(const Key('home-pill')), matching: find.byType(Container)),
            )
            .where((Container c) => (c.decoration as BoxDecoration?)?.shape == BoxShape.circle);
        expect(discs, hasLength(1), reason: '${b.name}: only the bottle\'s disc');
      }
    });
  });

  group('the bubble', () {
    // Where Nitzi's mouth is on the map: the bubble stands beside it, held by its bottom.
    const Offset mouth = Offset(0.5, 0.56);
    const String long = 'אלכסנדרה';
    String brokenLine(String name) => He.homeBubble.text.replaceFirst('{child}, ', '$name,\n');

    for (final BoardBox b in boards.skip(2)) {
      testWidgets(
        '${b.name}: a short name stays on one line, a long one breaks after the name; at most 210 wide',
        (WidgetTester tester) async {
          await pumpHome(tester, b.size, mouth: mouth, childName: 'דן');
          final Rect short = rectOf(tester, 'bubble-body');
          expect(find.text(He.homeBubble.fill(<String, String>{'child': 'דן'})), findsOneWidget);
          expect(short.width, lessThanOrEqualTo(210));

          await pumpHome(tester, b.size, mouth: mouth, childName: long);
          final Rect broken = rectOf(tester, 'bubble-body');
          expect(
            find.text(brokenLine(long)),
            findsOneWidget,
            reason: 'the words after the name stay whole on line 2',
          );
          expect(broken.width, lessThanOrEqualTo(210));
          expect(broken.bottom, closeTo(short.bottom, 0.6), reason: 'held by its bottom beside the mouth');
          expect(broken.right, closeTo(short.right, 0.6));
          expect(broken.top, lessThan(short.top - 20), reason: 'the second line grows upwards');
          expect(
            separation(broken, rectOf(tester, 'sign-counting')),
            greaterThanOrEqualTo(12),
            reason: 'clear of the Counting Hills sign',
          );
        },
      );
    }

    testWidgets('at text scale 1.3 on a tablet the bubble still keeps to 210 and to two lines', (
      WidgetTester tester,
    ) async {
      await pumpHome(tester, boards[2].size, mouth: mouth, childName: long, scale: 1.3);
      expect(tester.takeException(), isNull);
      final Rect body = rectOf(tester, 'bubble-body');
      expect(body.width, lessThanOrEqualTo(210));
      final Text text = tester.widget<Text>(
        find.descendant(of: find.byKey(const Key('bubble-body')), matching: find.byType(Text)),
      );
      expect(text.data, brokenLine(long));
      expect(body.height, lessThan(2 * 24 * 1.3 * 1.7 + 8 + 1), reason: 'two lines, never three');
    });

    for (final BoardBox b in boards.take(2)) {
      testWidgets('${b.name}: one line over the open sea, also with a long name', (
        WidgetTester tester,
      ) async {
        await pumpHome(tester, b.size, mouth: mouth, childName: long);
        expect(find.text(He.homeBubble.fill(<String, String>{'child': long})), findsOneWidget);
      });
    }

    // QA-29: a name too long for its line is shortened by the sign's rule, so a tablet bubble never takes three lines.
    for (final BoardBox b in boards.skip(2)) {
      for (final double scale in <double>[1, 1.3]) {
        testWidgets(
          '${b.name}, text scale $scale: a 24-letter name is shortened so the bubble keeps two lines',
          (WidgetTester tester) async {
            const String name = 'אבגדהוזחטיכלמנסעפצקרשתאב';
            await pumpHome(tester, b.size, mouth: mouth, island: homeIslandName(name), scale: scale);
            final String text = tester
                .widget<Text>(
                  find.descendant(of: find.byKey(const Key('bubble-body')), matching: find.byType(Text)),
                )
                .data!;
            final List<String> lines = text.split('\n');
            expect(lines, hasLength(2));
            expect(lines.first, endsWith('…,'), reason: 'the name, shortened, then the comma');
            expect(name.startsWith(lines.first.substring(0, lines.first.length - 2)), isTrue);
            expect(
              lines.last,
              He.homeBubble.text.split('{child}, ').last,
              reason: 'the words after the name, whole',
            );
            final Rect body = rectOf(tester, 'bubble-body');
            expect(body.width, lessThanOrEqualTo(210));
            expect(body.height, lessThan(3 * 24 * scale * 1.7), reason: 'two lines, never three');
          },
        );
      }
    }

    testWidgets('on a phone a name is shortened only when the line would leave the open sea', (
      WidgetTester tester,
    ) async {
      // 40 letters in four parts, the longest the parent form takes, at text scale 1.3 on the smallest phone.
      const String name = 'אבגדהוזחטי אבגדהוזחטי אבגדהוזחטי אבגדהוזח';
      await pumpHome(tester, boards[1].size, mouth: mouth, island: homeIslandName(name), scale: 1.3);
      final Rect body = rectOf(tester, 'bubble-body');
      expect(body.width, lessThanOrEqualTo(667 - 154 - 16));
      expect(body.left, greaterThanOrEqualTo(16));
      final String text = tester
          .widget<Text>(
            find.descendant(of: find.byKey(const Key('bubble-body')), matching: find.byType(Text)),
          )
          .data!;
      expect(text, contains('…,'));
      expect(text, isNot(contains('\n')), reason: 'one line on a phone');
      // A 24-letter name still fits there whole.
      await pumpHome(
        tester,
        boards[1].size,
        mouth: mouth,
        island: homeIslandName('אבגדהוזחטיכלמנסעפצקרשתאב'),
      );
      expect(
        find.text(He.homeBubble.fill(<String, String>{'child': 'אבגדהוזחטיכלמנסעפצקרשתאב'})),
        findsOneWidget,
      );
    });

    testWidgets('with no usable name the bubble says only the words after the name', (
      WidgetTester tester,
    ) async {
      await pumpHome(tester, boards.first.size, mouth: mouth, island: homeIslandName(' '));
      final String text = tester
          .widget<Text>(
            find.descendant(of: find.byKey(const Key('bubble-body')), matching: find.byType(Text)),
          )
          .data!;
      expect(text, He.homeBubble.text.split('{child}, ').last);
      expect(text, isNot(contains('{')));
    });

    testWidgets('a touch on it reaches what is under it', (WidgetTester tester) async {
      final Calls calls = await pumpHome(
        tester,
        boards[2].size,
        island: homeIslandName(long),
        mouth: mouth,
        childName: long,
      );
      final Rect bubble = rectOf(tester, 'bubble-body');
      // The bubble's lower line lies over the home island's tap area.
      final Offset low = Offset(bubble.center.dx, bubble.bottom - 8);
      expect(rectOf(tester, 'land-tap-nitzi').contains(low), isTrue, reason: '$bubble');
      await tester.tapAt(low);
      expect(calls.home, 1, reason: 'the touch went through the bubble to the home island');
      expect(calls.lands, isEmpty);
    });
  });

  group('goldens: the sign with three names', () {
    for (final BoardBox b in boards.take(2)) {
      for (final String key in <String>['noa', 'alexandra', 'avigail_alexandra']) {
        testWidgets('${b.name}, $key', (WidgetTester tester) async {
          await pumpHome(tester, b.size, island: homeIslandName(names[key]));
          final String board = b.name == 'phone' ? 'phone' : 'phone_se';
          await expectLater(
            find.byType(MaterialApp),
            matchesGoldenFile('goldens/home_sign_${key}_$board.png'),
          );
        });
      }
    }
  });
}
