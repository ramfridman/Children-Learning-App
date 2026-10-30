// QA, B-26 step 4: an independent check of the child's home in the real app (docs/qa/b26-step4-verification.md): every
// door on four boards at text scale 1.0 and 1.3 for five names, the way back to the home and the map, rapid taps and a
// back during a push, the bottle when a warm-up is due, the Hall's "something waits" on all boards, the friend's
// screen-reader label, the phone map at 1.3 (QA-19), the title after a text-scale change (D-1), and the wedge tail of the
// home's bubble (its tip, its outline, that it never takes a touch).
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/app/state.dart';
import 'package:nitznutz/child/home_island_name.dart';
import 'package:nitznutz/child/home_island_screen.dart';
import 'package:nitznutz/child/home_screen.dart';
import 'package:nitznutz/child/land_screen.dart';
import 'package:nitznutz/child/profile_picker.dart';
import 'package:nitznutz/child/sticker_island.dart';
import 'package:nitznutz/child/trophy_hall.dart';
import 'package:nitznutz/data/app_database.dart';
import 'package:nitznutz/design/components.dart';
import 'package:nitznutz/play/lesson_screen.dart';
import 'package:nitznutz/strings/he.dart';

import 'support/app_harness.dart';
import 'support/harness.dart';

const Map<String, Size> boards = <String, Size>{
  'phone': Size(852, 393),
  'phoneSE': Size(667, 375),
  'tabletLandscape': Size(1180, 820),
  'tabletPortrait': Size(820, 1180),
};

const Map<String, String> names = <String, String>{
  'noa': 'נועה',
  'wide_24': 'שששששששששששששששששששששששש',
  'letters_25': 'אבגדהוזחטיכלמנסעפצקרשתאבג',
  'blank': '   ',
  'latin_double': 'Alexandra Massimiliano',
};

/// The map for a child named [name], chosen through the state (the picker is QA-19's at 1.3).
Future<AppRig> openMap(
  WidgetTester tester,
  Size size,
  String name, {
  bool warmUp = false,
  bool motion = false,
  Future<void> Function(AppRig rig)? seed,
}) async {
  final AppRig rig = AppRig();
  await rig.seedFinishedSetup(name: name, warmUp: warmUp);
  if (seed != null) await seed(rig);
  await rig.pump(tester, size: size, reduceMotion: !motion);
  tester.takeException();
  final ProviderContainer c = ProviderScope.containerOf(tester.element(find.byType(ProfilePicker)));
  c.read(activeProfileProvider.notifier).choose((await c.read(appStateProvider.future)).profiles.single);
  await settle(tester, motion);
  expect(find.byType(HomeScreen), findsOneWidget);
  return rig;
}

/// With motion on the friends breathe for ever, so the screen never settles: a few seconds of frames instead.
Future<void> settle(WidgetTester tester, bool motion) async {
  if (!motion) {
    await tester.pumpAndSettle();
    return;
  }
  for (int i = 0; i < 30; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<void> tapAndSettle(WidgetTester tester, String key) async {
  await tester.tap(find.byKey(Key(key)));
  await tester.pumpAndSettle();
}

/// How many of [type] are mounted (also under other routes).
int mounted(Type type) => find.byType(type, skipOffstage: false).evaluate().length;

/// The flexes that run past their room, with the keys above them.
List<String> overflowing(WidgetTester tester) => <String>[
  for (final Element e in find.byWidgetPredicate((Widget w) => w is Flex).evaluate())
    if (_overflow(e.renderObject! as RenderFlex) > 0.01)
      '${_overflow(e.renderObject! as RenderFlex).toStringAsFixed(1)} under ${_keys(e)}',
];

double _overflow(RenderFlex f) {
  double used = 0;
  for (RenderBox? c = f.firstChild; c != null; c = (c.parentData! as FlexParentData).nextSibling) {
    used += f.direction == Axis.horizontal ? c.size.width : c.size.height;
  }
  return used - (f.direction == Axis.horizontal ? f.size.width : f.size.height);
}

String _keys(Element e) {
  final List<String> keys = <String>[];
  e.visitAncestorElements((Element a) {
    if (a.widget.key is ValueKey<String>) keys.add((a.widget.key! as ValueKey<String>).value);
    return keys.length < 3;
  });
  return keys.join(' < ');
}

/// The larger of the horizontal and the vertical gap between two rectangles (0 when they overlap).
double separation(Rect a, Rect b) => math.max(
  math.max(math.max(a.left - b.right, b.left - a.right), 0),
  math.max(math.max(a.top - b.bottom, b.top - a.bottom), 0),
);

void main() {
  setUpAll(loadAppFonts);

  group('every door, every board, text scale 1.0 and 1.3', () {
    for (final MapEntry<String, Size> b in boards.entries) {
      for (final double scale in <double>[1.0, 1.3]) {
        for (final MapEntry<String, String> n in names.entries) {
          testWidgets('${b.key} x$scale ${n.key}', (WidgetTester tester) async {
            tester.platformDispatcher.textScaleFactorTestValue = scale;
            addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
            await openMap(tester, b.value, n.value);
            tester.takeException(); // QA-19 on the phone map at 1.3 (the pill), checked on its own below
            final HomeIslandName island = homeIslandName(n.value);

            // In by the sign; the home is the child's, whole and on the board.
            await tapAndSettle(tester, 'sign-nitzi');
            expect(find.byType(HomeIslandScreen), findsOneWidget);
            expect(tester.takeException(), isNull, reason: 'the home lays out without an error');
            expect(overflowing(tester), isEmpty);
            expect(
              tester
                  .widget<Text>(
                    find.descendant(
                      of: find.byKey(const Key('home-island-title')),
                      matching: find.byType(Text),
                    ),
                  )
                  .data,
              island.title,
            );
            final Rect screen = Offset.zero & b.value;
            for (final String k in <String>[
              'home-island-title',
              'home-island-back',
              'home-island-bottle',
              'home-island-companion',
              'home-island-book',
              'home-island-lighthouse',
              'bubble-body',
            ]) {
              final Rect r = tester.getRect(find.byKey(Key(k)));
              expect(
                screen.contains(r.topLeft) && screen.contains(r.bottomRight - const Offset(0.01, 0.01)),
                isTrue,
                reason: '$k $r on the board',
              );
            }
            final String bubble = tester
                .widget<Text>(
                  find.descendant(
                    of: find.byKey(const Key('home-island-bubble')),
                    matching: find.byType(Text),
                  ),
                )
                .data!;
            expect(bubble, island.isNamed ? contains('\u2068') : He.nitziHomeWelcomeNoName.text);

            // The book: stickers, and back to the home.
            await tapAndSettle(tester, 'home-island-book');
            expect(find.byType(StickerIsland), findsOneWidget);
            await tapAndSettle(tester, 'stickers-back');
            expect(find.byType(HomeIslandScreen), findsOneWidget);
            // The lighthouse: the Hall, and back.
            await tapAndSettle(tester, 'home-island-lighthouse');
            expect(find.byType(TrophyHall), findsOneWidget);
            await tapAndSettle(tester, 'hall-back');
            expect(find.byType(HomeIslandScreen), findsOneWidget);
            // The bottle: a Counting Hills lesson (never a land screen), and back to the home.
            await tester.tap(find.byKey(const Key('home-island-bottle')));
            await tester.pumpAndSettle();
            expect(find.byType(LessonScreen), findsOneWidget);
            expect(find.byType(LandScreen), findsNothing);
            await tapAndSettle(tester, 'activity-home');
            expect(find.byType(LessonScreen), findsNothing);
            expect(find.byType(HomeIslandScreen), findsOneWidget);
            // The friend: a wave, the hello in the bubble, nothing opens.
            await tapAndSettle(tester, 'home-island-companion');
            expect(find.text(He.nitziHomeHi.text), findsOneWidget);
            expect(find.byType(HomeIslandScreen), findsOneWidget);
            // Back to the map, which never offered Nitzi as a land.
            await tapAndSettle(tester, 'home-island-back');
            expect(find.byType(HomeIslandScreen), findsNothing);
            expect(
              tester.widget<HomeScreen>(find.byType(HomeScreen)).openableLands.contains(Land.nitzi),
              isFalse,
            );
            final Object? e = tester.takeException();
            if (e != null) expect('$e', contains('RenderFlex overflowed'), reason: 'only QA-19');
          });
        }
      }
    }
  });

  group('rapid taps and a back during a push (phone)', () {
    for (final (String key, Type screen) in <(String, Type)>[
      ('home-island-bottle', LessonScreen),
      ('home-island-book', StickerIsland),
      ('home-island-lighthouse', TrophyHall),
    ]) {
      testWidgets('a double tap on $key opens one $screen', (WidgetTester tester) async {
        await openMap(tester, boards['phone']!, 'נועה');
        await tapAndSettle(tester, 'home-pill');
        await tester.tap(find.byKey(Key(key)));
        await tester.pump(const Duration(milliseconds: 60));
        await tester.tap(find.byKey(Key(key)), warnIfMissed: false);
        await tester.pumpAndSettle();
        expect(mounted(screen), 1, reason: 'two taps, $screen');
      });
    }

    testWidgets('a double tap on the sign and on the pill opens one home', (WidgetTester tester) async {
      await openMap(tester, boards['phone']!, 'נועה');
      await tester.tap(find.byKey(const Key('sign-nitzi')));
      await tester.pump(const Duration(milliseconds: 60));
      await tester.tap(find.byKey(const Key('home-pill')), warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(mounted(HomeIslandScreen), 1);
    });

    testWidgets('back pressed while the home is still coming in: the map, with nothing left over', (
      WidgetTester tester,
    ) async {
      await openMap(tester, boards['phone']!, 'נועה');
      await tester.tap(find.byKey(const Key('home-pill')));
      // The new route's first frame is offstage; the next is its first visible one, still in its transition.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tap(find.byKey(const Key('home-island-back')), warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(mounted(HomeIslandScreen), 0);
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('the system back from a door returns to the home, and from the home to the map', (
      WidgetTester tester,
    ) async {
      await openMap(tester, boards['phone']!, 'נועה');
      await tapAndSettle(tester, 'home-pill');
      await tapAndSettle(tester, 'home-island-book');
      final NavigatorState nav = tester.state<NavigatorState>(find.byType(Navigator).first);
      await nav.maybePop();
      await tester.pumpAndSettle();
      expect(find.byType(HomeIslandScreen), findsOneWidget);
      await nav.maybePop();
      await tester.pumpAndSettle();
      expect(find.byType(HomeIslandScreen), findsNothing);
      expect(find.byType(HomeScreen), findsOneWidget);
    });
  });

  testWidgets('a warm-up due: the bottle opens the warm-up first, as the map does; leaving it is the home', (
    WidgetTester tester,
  ) async {
    await openMap(tester, boards['phone']!, 'נועה', warmUp: true);
    await tapAndSettle(tester, 'home-pill');
    await tester.tap(find.byKey(const Key('home-island-bottle')));
    await tester.pumpAndSettle();
    final LessonScreen lesson = tester.widget<LessonScreen>(find.byType(LessonScreen));
    expect(lesson.mission, isNotNull, reason: 'the warm-up is a mission lesson');
    await tapAndSettle(tester, 'activity-home');
    expect(find.byType(LessonScreen), findsNothing, reason: 'leaving the warm-up does not start the lesson');
    expect(find.byType(HomeIslandScreen), findsOneWidget);
  });

  testWidgets('the bottle and the pill say the same thing', (WidgetTester tester) async {
    final SemanticsHandle sem = tester.ensureSemantics();
    await openMap(tester, boards['phone']!, 'נועה');
    expect(tester.getSemantics(find.byKey(const Key('home-pill'))).label, He.homeDaily.text);
    await tapAndSettle(tester, 'home-pill');
    expect(tester.getSemantics(find.byKey(const Key('home-island-bottle'))).label, He.homeDaily.text);
    expect(tester.widget<Text>(find.byKey(const Key('home-island-label-bottle'))).data, He.homeDaily.text);
    sem.dispose();
  });

  group('something waits in the Hall, on every board', () {
    for (final MapEntry<String, Size> b in boards.entries) {
      testWidgets(b.key, (WidgetTester tester) async {
        final SemanticsHandle sem = tester.ensureSemantics();
        await openMap(
          tester,
          b.value,
          'נועה',
          seed: (AppRig rig) async {
            await rig.db.putSetting('ceremonies', 'off');
            await rig.db.addReward(
              RewardsCompanion.insert(
                profileId: 'p-1',
                awardKey: 'trophy:counting:silver',
                kind: 'trophy',
                at: DateTime.utc(2026, 10, 27),
              ),
            );
          },
        );
        final Rect sign = tester.getRect(find.byKey(const Key('sign-nitzi')));
        final Rect badge = tester.getRect(find.byKey(const Key('home-sign-trophy')));
        final Rect plus = tester.getRect(find.byKey(const Key('home-friends')));
        // The badge sits on the sign's start (right) corner, over its border, on the screen, and clear of the "+".
        expect(badge.center.dx, closeTo(sign.right - 12, 0.6), reason: 'on the start corner');
        expect(badge.center.dy, closeTo(sign.top, 0.6), reason: 'over the top border');
        expect((Offset.zero & b.value).contains(badge.topLeft), isTrue);
        expect(badge.overlaps(plus), isFalse, reason: 'badge $badge, "+" $plus');
        final String label = '${homeIslandName('נועה').semantics}, ${He.trophyNewSemantics.text}';
        expect(tester.getSemantics(find.byKey(const Key('land-tap-nitzi'))).label, label);
        expect(tester.getSemantics(find.byKey(const Key('sign-nitzi'))).label, label);
        // The sign keeps its width with the badge (it is drawn over the border).
        await tapAndSettle(tester, 'sign-nitzi');
        expect(find.byKey(const Key('home-island-lantern-trophy')), findsOneWidget);
        expect(find.byKey(const Key('home-island-lantern-glow')), findsOneWidget);
        sem.dispose();
      });
    }
  });

  testWidgets('what the screen reader says for the friend in the home (recorded)', (
    WidgetTester tester,
  ) async {
    final SemanticsHandle sem = tester.ensureSemantics();
    await openMap(tester, boards['phone']!, 'נועה');
    await tapAndSettle(tester, 'home-pill');
    final SemanticsData friend = tester
        .getSemantics(find.byKey(const Key('home-island-companion')))
        .getSemanticsData();
    debugPrint(
      'QA4 friend: label "${friend.label}", button ${friend.flagsCollection.isButton}, '
      'tap ${friend.hasAction(SemanticsAction.tap)}',
    );
    expect(friend.flagsCollection.isButton, isTrue);
    expect(friend.hasAction(SemanticsAction.tap), isTrue);
    sem.dispose();
  });

  testWidgets('QA-19 on the phone map at text scale 1.3, after the pebbles left (recorded)', (
    WidgetTester tester,
  ) async {
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await openMap(tester, boards['phone']!, 'נועה');
    final Object? e = tester.takeException();
    final List<String> flows = overflowing(tester);
    debugPrint(
      'QA4 phone map x1.3: exception ${e == null ? 'none' : '$e'.split('\n').first}; overflowing $flows',
    );
    expect(flows.every((String f) => f.contains('home-pill')), isTrue, reason: '$flows');
  });

  group('with motion on (the real transitions, 300 ms): taps while a screen comes in', () {
    for (final (String key, Type screen) in <(String, Type)>[
      ('home-island-bottle', LessonScreen),
      ('home-island-book', StickerIsland),
      ('home-island-lighthouse', TrophyHall),
    ]) {
      testWidgets('a double tap on $key opens one $screen', (WidgetTester tester) async {
        await openMap(tester, boards['phone']!, 'נועה', motion: true);
        await tester.tap(find.byKey(const Key('home-pill')));
        await settle(tester, true);
        await tester.tap(find.byKey(Key(key)));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 80));
        await tester.tap(find.byKey(Key(key), skipOffstage: false), warnIfMissed: false);
        await settle(tester, true);
        expect(mounted(screen), 1, reason: 'two taps 80 ms apart, $screen');
      });
    }

    testWidgets('the sign then the pill 80 ms apart open one home', (WidgetTester tester) async {
      await openMap(tester, boards['phone']!, 'נועה', motion: true);
      await tester.tap(find.byKey(const Key('sign-nitzi')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 80));
      await tester.tap(find.byKey(const Key('home-pill'), skipOffstage: false), warnIfMissed: false);
      await settle(tester, true);
      expect(mounted(HomeIslandScreen), 1);
    });

    testWidgets('back tapped while the home is still coming in: the map, nothing switched or left over', (
      WidgetTester tester,
    ) async {
      await openMap(tester, boards['phone']!, 'נועה', motion: true);
      await tester.tap(find.byKey(const Key('home-pill')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      // Where the back pebble will be (the start corner), which on the map is the avatar's corner.
      await tester.tap(find.byKey(const Key('home-island-back')), warnIfMissed: false);
      await settle(tester, true);
      debugPrint(
        'QA4 back mid-push: homes ${mounted(HomeIslandScreen)}, map ${mounted(HomeScreen)}, '
        'picker ${mounted(ProfilePicker)}',
      );
      expect(mounted(ProfilePicker), 0, reason: 'the tap never reached the avatar (switch child) under it');
      expect(mounted(HomeScreen), 1);
    });
  });

  group('D-1: the text scale changes while the home is open (the title follows it)', () {
    // Board, base size and max text width of the title (nitzi-home.md section 3.1).
    const List<(String, Size, double, double)> titleBoards = <(String, Size, double, double)>[
      ('phone', Size(852, 393), 22, 610),
      ('phoneSE', Size(667, 375), 20, 425),
      ('tabletLandscape', Size(1180, 820), 28, 872),
      ('tabletPortrait', Size(820, 1180), 28, 512),
    ];

    /// The title is the size and line count the fit rule gives for [scale], and the name is never broken between its
    /// letters (all its glyphs on one line).
    void expectTitleFits(
      WidgetTester tester,
      String board,
      String name,
      double base,
      double maxText,
      double scale,
    ) {
      final HomeIslandName island = homeIslandName(name);
      final IslandTitleFit want = fitIslandTitle(
        island.title,
        base: base,
        maxText: maxText,
        scaler: TextScaler.linear(scale),
      );
      final Finder title = find.descendant(
        of: find.byKey(const Key('home-island-title')),
        matching: find.byType(Text),
      );
      final Finder rich = find.descendant(
        of: find.byKey(const Key('home-island-title')),
        matching: find.byType(RichText),
      );
      final RenderParagraph para = tester.renderObject<RenderParagraph>(rich);
      expect(para.textScaler.scale(1), closeTo(scale, 0.001), reason: '$board: painted at $scale');
      expect(
        tester.widget<Text>(title).style!.fontSize,
        want.size,
        reason: '$board: the size the rule gives at $scale',
      );
      final String text = island.title;
      final List<double> tops = <double>[
        for (int i = text.indexOf('\u2068') + 1; i < text.lastIndexOf('\u2069'); i++)
          ...para
              .getBoxesForSelection(TextSelection(baseOffset: i, extentOffset: i + 1))
              .map((TextBox b) => b.top.roundToDouble()),
      ];
      expect(
        tops.toSet(),
        hasLength(1),
        reason: '$board: the name on one line, never broken between its letters',
      );
      final int lines = para
          .getBoxesForSelection(TextSelection(baseOffset: 0, extentOffset: text.length))
          .map((TextBox b) => b.top.round())
          .toSet()
          .length;
      expect(lines, want.lines, reason: '$board: ${want.lines} line(s) at $scale');
    }

    for (final (String n, Size size, double base, double maxText) in titleBoards) {
      for (final (double from, double to) in <(double, double)>[(1.0, 1.3), (1.3, 1.0)]) {
        testWidgets('$n: opened at $from, then $to, 24 x ש', (WidgetTester tester) async {
          tester.platformDispatcher.textScaleFactorTestValue = from;
          addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
          await openMap(tester, size, names['wide_24']!);
          tester.takeException();
          await tapAndSettle(tester, 'home-pill');
          expectTitleFits(tester, n, names['wide_24']!, base, maxText, from);
          tester.platformDispatcher.textScaleFactorTestValue = to;
          await tester.pumpAndSettle();
          tester.takeException();
          expectTitleFits(tester, n, names['wide_24']!, base, maxText, to);
        });
      }
    }

    testWidgets('many app instances in one test, the scale raised after each home opened', (
      WidgetTester tester,
    ) async {
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      for (int round = 0; round < 2; round++) {
        for (final (String n, Size size, double base, double maxText) in titleBoards) {
          tester.platformDispatcher.textScaleFactorTestValue = 1.0;
          await tester.pumpWidget(const SizedBox.shrink());
          await openMap(tester, size, names['wide_24']!);
          tester.takeException();
          await tapAndSettle(tester, 'home-pill');
          tester.platformDispatcher.textScaleFactorTestValue = 1.3;
          await tester.pumpAndSettle();
          tester.takeException();
          expectTitleFits(tester, '$n (round $round)', names['wide_24']!, base, maxText, 1.3);
        }
      }
    });
  });

  group('the wedge tail of the home bubble (final)', () {
    // The tip per board (companion.topLeft + (0.74 w, 0.47 h)), the friend's and the doors' tap areas (section 3).
    final List<(String, Size, Offset, Rect, List<Rect>)> wedgeBoards =
        <(String, Size, Offset, Rect, List<Rect>)>[
          (
            'phone',
            const Size(852, 393),
            const Offset(498.4, 235.2),
            const Rect.fromLTWH(380, 160, 160, 160),
            const <Rect>[
              Rect.fromLTWH(600, 192, 160, 144),
              Rect.fromLTWH(208, 216, 128, 120),
              Rect.fromLTWH(32, 88, 128, 248),
            ],
          ),
          (
            'phoneSE',
            const Size(667, 375),
            const Offset(401.68, 234.04),
            const Rect.fromLTWH(304, 172, 132, 132),
            const <Rect>[
              Rect.fromLTWH(468, 188, 136, 136),
              Rect.fromLTWH(168, 212, 112, 112),
              Rect.fromLTWH(24, 96, 112, 228),
            ],
          ),
          (
            'tabletLandscape',
            const Size(1180, 820),
            const Offset(777.6, 492.8),
            const Rect.fromLTWH(600, 380, 240, 240),
            const <Rect>[
              Rect.fromLTWH(900, 480, 200, 200),
              Rect.fromLTWH(360, 516, 176, 176),
              Rect.fromLTWH(80, 220, 200, 480),
            ],
          ),
          (
            'tabletPortrait',
            const Size(820, 1180),
            const Offset(477.6, 492.8),
            const Rect.fromLTWH(300, 380, 240, 240),
            const <Rect>[
              Rect.fromLTWH(500, 760, 220, 200),
              Rect.fromLTWH(150, 780, 176, 176),
              Rect.fromLTWH(48, 200, 160, 440),
            ],
          ),
        ];

    Future<void> pumpHomeScreen(WidgetTester tester, Size size, String name, double scale) async {
      tester.platformDispatcher.textScaleFactorTestValue = scale;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      tester.platformDispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(
        disableAnimations: true,
      );
      addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
      await tester.pumpWidget(const SizedBox.shrink());
      await pumpScreen(
        tester,
        HomeIslandScreen(
          island: homeIslandName(name),
          companion: const SizedBox.expand(),
          onCompanion: () {},
          onBottle: () => fail('the bottle took a touch'),
          onStickers: () => fail('the book took a touch'),
          onHall: () => fail('the lighthouse took a touch'),
        ),
        size: size,
      );
      await tester.pump();
    }

    for (final (String n, Size size, Offset tip, Rect friend, List<Rect> doors) in wedgeBoards) {
      for (final double scale in <double>[1.0, 1.3]) {
        for (final String name in <String>['נֹעָה', names['wide_24']!, names['latin_double']!]) {
          testWidgets('$n x$scale ${name.characters.take(6)}', (WidgetTester tester) async {
            await pumpHomeScreen(tester, size, name, scale);
            expect(tester.takeException(), isNull);
            final Rect body = tester.getRect(find.byKey(const Key('bubble-body')));
            final Finder tail = find.byKey(const Key('bubble-tail'));
            final Finder outline = find.byKey(const Key('bubble-outline'));
            expect(tail, findsOneWidget);
            expect(outline, findsOneWidget);
            // The tip where the design puts it: the wedge holds a point 2 inside its rounded end and not one 3 beyond it,
            // in the bubble's own coordinates; the painted paths agree.
            final Offset local = tip - body.topLeft;
            final Offset toBase = Offset(38, body.height - 4) - local;
            final Offset unit = toBase / toBase.distance;
            final Path wedge = bubbleWedgeTail(body.size, local);
            expect(wedge.contains(local + unit * 2), isTrue, reason: '$n: the tip at $tip');
            expect(wedge.contains(local - unit * 3), isFalse, reason: '$n: nothing beyond the tip');
            expect(tester.getSize(tail), body.size, reason: 'the painter works in the body coordinates');
            // (The wedge itself is painted after its shadow copies, so the outline is the one checked by its painted path.)
            expect(
              outline,
              paints..path(includes: <Offset>[local + unit * 2], excludes: <Offset>[local - unit * 3]),
            );
            // The tip below the bubble, on the friend; the wedge over none of the three doors.
            expect(
              tip.dy - body.bottom,
              greaterThanOrEqualTo(25),
              reason: '$n: tip ${tip.dy - body.bottom} below',
            );
            expect(friend.contains(tip), isTrue);
            final Path global = wedge.shift(body.topLeft);
            double clearance = double.infinity;
            for (final Rect door in doors) {
              for (double x = door.left; x <= door.right; x += 2) {
                for (double y = door.top; y <= door.bottom; y += 2) {
                  expect(
                    global.contains(Offset(x, y)),
                    isFalse,
                    reason: '$n: the wedge over a door at ($x, $y)',
                  );
                }
              }
              clearance = math.min(clearance, separation(global.getBounds(), door));
            }
            // A touch on the tip and in the middle of the wedge never lands on the bubble; the tip is on the friend.
            final Offset mid = (Offset(body.left + 38, body.bottom - 4) + tip) / 2;
            final Set<RenderObject> mine = <RenderObject>{
              tester.renderObject(tail),
              tester.renderObject(outline),
              tester.renderObject(find.byKey(const Key('bubble-body'))),
            };
            for (final Offset p in <Offset>[tip, mid]) {
              final HitTestResult hit = tester.hitTestOnBinding(p);
              expect(
                hit.path.any((HitTestEntry e) => mine.contains(e.target)),
                isFalse,
                reason: '$n: the bubble took $p',
              );
            }
            await tester.tapAt(tip);
            await tester.pump();
            expect(
              find.text(He.nitziHomeHi.text),
              findsOneWidget,
              reason: '$n: the tip is on the friend, who greets',
            );
            debugPrint(
              'QA4 wedge $n x$scale: tip ${(tip.dy - body.bottom).toStringAsFixed(1)} below the bubble, '
              'wedge bounds to the nearest door ${clearance.toStringAsFixed(1)}',
            );
          });
        }
      }
    }

    testWidgets('text scale 2.0, portrait tablet, a long name: no error, the outline closes', (
      WidgetTester tester,
    ) async {
      await pumpHomeScreen(tester, const Size(820, 1180), names['wide_24']!, 2.0);
      expect(tester.takeException(), isNull);
      final Rect body = tester.getRect(find.byKey(const Key('bubble-body')));
      final Path outline = bubbleOutline(body.size, const Offset(477.6, 492.8) - body.topLeft);
      expect(outline.getBounds().isFinite, isTrue);
      debugPrint('QA4 wedge portrait x2.0: bubble bottom ${body.bottom}, tip y 492.8');
    });

    testWidgets('the map bubble keeps its old tail, with no wedge and no outline', (
      WidgetTester tester,
    ) async {
      await openMap(tester, boards['phone']!, 'נועה');
      expect(find.byKey(const Key('bubble-body')), findsOneWidget);
      expect(find.byKey(const Key('bubble-tail')), findsNothing);
      expect(find.byKey(const Key('bubble-outline')), findsNothing);
      expect(tester.widget<BoardBubble>(find.byType(BoardBubble)).tailTip, isNull);
    });
  });
}
