// B-26 step 3: in the real app the home island's sign is named after the playing child and opens the child's home (a
// placeholder until step 4: the island's title and the way back). The name is worked out again when it changes.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/app/state.dart';
import 'package:nitznutz/child/home_island_name.dart';
import 'package:nitznutz/child/home_island_screen.dart';
import 'package:nitznutz/child/home_screen.dart';
import 'package:nitznutz/child/land_screen.dart';
import 'package:nitznutz/data/app_database.dart';
import 'package:nitznutz/strings/he.dart';

import 'support/app_harness.dart';
import 'support/harness.dart';

Future<AppRig> home(WidgetTester tester, {String name = 'נועה', Size size = const Size(852, 393)}) async {
  final AppRig rig = AppRig();
  await rig.seedFinishedSetup(name: name);
  await rig.pump(tester, size: size);
  await tester.tap(find.text(name));
  await tester.pumpAndSettle();
  expect(find.byType(HomeScreen), findsOneWidget);
  return rig;
}

String signText(WidgetTester tester) => tester
    .widget<Text>(find.descendant(of: find.byKey(const Key('sign-nitzi')), matching: find.byType(Text)))
    .data!;

String bubbleText(WidgetTester tester) => tester
    .widget<Text>(find.descendant(of: find.byKey(const Key('bubble-body')), matching: find.byType(Text)))
    .data!;

void main() {
  setUpAll(loadAppFonts);

  testWidgets(
    'the sign carries the child\'s name; tapping it opens the home with the title, and back is the map',
    (WidgetTester tester) async {
      final SemanticsHandle semantics = tester.ensureSemantics();
      await home(tester);
      final HomeIslandName island = homeIslandName('נועה');
      expect(signText(tester), island.sign);
      await tester.tap(find.byKey(const Key('sign-nitzi')));
      await tester.pumpAndSettle();
      expect(find.byType(HomeIslandScreen), findsOneWidget);
      expect(find.byType(LandScreen), findsNothing);
      expect(find.text(island.title), findsOneWidget);
      expect(
        tester.getSemantics(find.byKey(const Key('home-island-title'))),
        matchesSemantics(label: island.semantics, isHeader: true),
      );
      expect(
        tester.getSemantics(find.byKey(const Key('home-island-back'))),
        isSemantics(label: He.landBackSemantics.text, isButton: true, hasTapAction: true),
      );
      await tester.tap(find.byKey(const Key('home-island-back')));
      await tester.pumpAndSettle();
      expect(find.byType(HomeIslandScreen), findsNothing);
      expect(find.byType(HomeScreen), findsOneWidget);
      semantics.dispose();
    },
  );

  testWidgets('Today\'s Adventure opens the same home', (WidgetTester tester) async {
    await home(tester);
    await tester.tap(find.byKey(const Key('home-pill')));
    await tester.pumpAndSettle();
    expect(find.byType(HomeIslandScreen), findsOneWidget);
  });

  testWidgets('the bubble uses the cleaned name, and a long title shows without an overflow', (
    WidgetTester tester,
  ) async {
    // As a parent might type it: spaces around, a direction mark inside, 30 letters in three parts (over the title's 24).
    final String typed = '  אבגדהוזחטי אבגדהוזחטי ${String.fromCharCode(0x200F)}אבגדהוזח ';
    await home(tester, name: typed.trim());
    final HomeIslandName island = homeIslandName(typed);
    expect(bubbleText(tester), startsWith('${island.name},'), reason: 'cleaned: no mark, no outer space');
    await tester.tap(find.byKey(const Key('home-pill')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text(island.title), findsOneWidget);
  });

  testWidgets('a name changed by the family is shown at once, on the sign and in the bubble', (
    WidgetTester tester,
  ) async {
    final AppRig rig = await home(tester);
    await rig.db.upsertProfileFromFamily(
      ProfilesCompanion.insert(
        id: 'p-1',
        name: 'דן',
        avatar: 'avatar-noa',
        addressForm: 'm',
        ageBand: 1,
        createdAt: DateTime.utc(2026, 10, 26),
      ),
      isNew: false,
    );
    ProviderScope.containerOf(tester.element(find.byType(HomeScreen))).invalidate(appStateProvider);
    await tester.pumpAndSettle();
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(signText(tester), homeIslandName('דן').sign);
    expect(bubbleText(tester), He.homeBubble.fill(<String, String>{'child': 'דן'}));
  });
}
