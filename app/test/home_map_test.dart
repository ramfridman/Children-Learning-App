// Board B-23: every land is on the map of every board, and opens with a still tap once it is brought into view. On a
// phone the map is a strip that pans sideways (home at the right), on a tablet in portrait it scrolls up; a drag that
// starts on a sign moves the map and opens nothing. The home island's sign opens the child's home (B-26). The real app
// with the real pack.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/child/home_island_name.dart';
import 'package:nitznutz/child/home_island_screen.dart';
import 'package:nitznutz/child/home_screen.dart';
import 'package:nitznutz/child/land_screen.dart';

import 'support/app_harness.dart';
import 'support/harness.dart';

const Map<String, Size> boards = <String, Size>{
  'phone': Size(852, 393),
  'phoneSE': Size(667, 375),
  'tabletLandscape': Size(1180, 820),
  'tabletPortrait': Size(820, 1180),
};

const List<Land> learningLands = <Land>[
  Land.counting,
  Land.colors,
  Land.shapes,
  Land.logic,
  Land.robots,
  Land.market,
];

Future<AppRig> home(WidgetTester tester, Size size) async {
  final AppRig rig = AppRig();
  await rig.seedFinishedSetup();
  await rig.pump(tester, size: size);
  await tester.tap(find.text('נועה'));
  await tester.pumpAndSettle();
  expect(find.byType(HomeScreen), findsOneWidget);
  return rig;
}

void main() {
  setUpAll(loadAppFonts);

  for (final MapEntry<String, Size> board in boards.entries) {
    group('the map on ${board.key}', () {
      testWidgets('all seven signs are on the map, and the home island\'s sign opens the child\'s home', (
        WidgetTester tester,
      ) async {
        await home(tester, board.value);
        for (final Land l in Land.values) {
          expect(find.byKey(Key('sign-${l.name}')), findsOneWidget, reason: l.name);
        }
        expect(find.byKey(const Key('land-tap-nitzi')), findsOneWidget);
        await tester.tap(find.byKey(const Key('sign-nitzi')));
        await tester.pumpAndSettle();
        expect(find.byType(LandScreen), findsNothing, reason: 'the home island is not a land');
        expect(find.byType(HomeIslandScreen), findsOneWidget);
        expect(find.text(homeIslandName('נועה').title), findsOneWidget);
        await tester.tap(find.byKey(const Key('home-island-back')));
        await tester.pumpAndSettle();
        expect(find.byType(HomeIslandScreen), findsNothing);
        expect(find.byType(HomeScreen), findsOneWidget);
      });

      for (final Land land in learningLands) {
        testWidgets('${land.name}: brought into view and tapped, its island opens', (
          WidgetTester tester,
        ) async {
          await home(tester, board.value);
          final Finder tap = find.byKey(Key('land-tap-${land.name}'));
          await tester.ensureVisible(tap);
          await tester.pumpAndSettle();
          final Rect area = tester.getRect(tap);
          final Rect screen = Offset.zero & board.value;
          expect(
            screen.contains(area.center),
            isTrue,
            reason: 'the middle of the tap area is on screen: $area',
          );
          await tester.tap(tap);
          await tester.pumpAndSettle();
          expect(find.byType(LandScreen), findsOneWidget);
          expect(tester.widget<LandScreen>(find.byType(LandScreen)).land.name, land.name);
        });
      }

      testWidgets('a drag that starts on a sign moves the map and opens nothing', (
        WidgetTester tester,
      ) async {
        await home(tester, board.value);
        final Finder sign = find.byKey(const Key('sign-counting'));
        final Offset before = tester.getCenter(sign);
        final Offset pull = board.key == 'tabletPortrait' ? const Offset(0, 200) : const Offset(200, 0);
        await tester.drag(sign, pull);
        await tester.pumpAndSettle();
        expect(find.byType(LandScreen), findsNothing);
        expect(find.byType(HomeScreen), findsOneWidget);
        if (board.key != 'tabletLandscape') {
          expect(tester.getCenter(sign), isNot(before), reason: 'the map moved under the finger');
        }
      });
    });
  }

  testWidgets('coming back from the child\'s home, the map is where the child left it', (
    WidgetTester tester,
  ) async {
    await home(tester, boards['phone']!);
    // Panned part way towards Market Village, then the home opened from Today's Adventure, which never moves.
    final ScrollPosition map = tester
        .state<ScrollableState>(
          find.descendant(
            of: find.byKey(const PageStorageKey<String>('home-map')),
            matching: find.byType(Scrollable),
          ),
        )
        .position;
    map.jumpTo(420);
    await tester.pumpAndSettle();
    final Offset counting = tester.getCenter(find.byKey(const Key('sign-counting')));
    await tester.tap(find.byKey(const Key('home-pill')));
    await tester.pumpAndSettle();
    expect(find.byType(HomeIslandScreen), findsOneWidget);
    await tester.tap(find.byKey(const Key('home-island-back')));
    await tester.pumpAndSettle();
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(map.pixels, 420);
    expect(tester.getCenter(find.byKey(const Key('sign-counting'))), counting);
  });

  testWidgets('coming back from a land, the map is where the child left it', (WidgetTester tester) async {
    await home(tester, boards['phone']!);
    final Finder market = find.byKey(const Key('land-tap-market'));
    await tester.ensureVisible(market);
    await tester.pumpAndSettle();
    final Offset at = tester.getCenter(market);
    await tester.tap(market);
    await tester.pumpAndSettle();
    expect(find.byType(LandScreen), findsOneWidget);
    tester.state<NavigatorState>(find.byType(Navigator).first).pop();
    await tester.pumpAndSettle();
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(tester.getCenter(market), at);
  });
}
