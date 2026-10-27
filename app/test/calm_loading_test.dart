// The loading scene a child sees while the map gets ready.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/child/calm_loading.dart';
import 'package:nitznutz/child/home_screen.dart';

import 'support/app_harness.dart';
import 'support/harness.dart';

void main() {
  setUpAll(loadAppFonts);

  testWidgets('three pearls rise and fall one after the other, with no words', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: CalmLoading()));
    expect(find.byType(Text), findsNothing);
    final Finder pearls = find.descendant(of: find.byType(CalmLoading), matching: find.byType(DecoratedBox));
    final List<Offset> before = <Offset>[for (int i = 0; i < 3; i++) tester.getTopLeft(pearls.at(i))];
    await tester.pump(const Duration(milliseconds: 400));
    final List<Offset> after = <Offset>[for (int i = 0; i < 3; i++) tester.getTopLeft(pearls.at(i))];
    expect(before.length, 3);
    expect(
      <double>[for (int i = 0; i < 3; i++) after[i].dy - before[i].dy].any((double d) => d.abs() > 1),
      isTrue,
    );
  });

  testWidgets('with reduce motion on they stand still and nothing keeps running', (
    WidgetTester tester,
  ) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(
      disableAnimations: true,
    );
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await tester.pumpWidget(const MaterialApp(home: CalmLoading()));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('calm-loading')), findsOneWidget);
  });

  testWidgets('choosing a child shows the loading scene until the map is ready, then the whole map', (
    WidgetTester tester,
  ) async {
    final Completer<void> hold = Completer<void>();
    final AppRig rig = AppRig(holdCharacters: hold);
    await rig.seedFinishedSetup();
    await rig.pump(tester);
    await tester.tap(find.text('נועה'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byKey(const Key('calm-loading')), findsOneWidget);
    expect(find.byType(HomeScreen), findsNothing, reason: 'no half-loaded map');
    hold.complete();
    await tester.pumpAndSettle();
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.byKey(const Key('calm-loading')), findsNothing);
    expect(
      find.byKey(const Key('home-companion')),
      findsOneWidget,
      reason: 'the friend is there from the first frame',
    );
  });
}
