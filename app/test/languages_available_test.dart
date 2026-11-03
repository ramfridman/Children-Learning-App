// A language gets a door, an island and a place in Today's Adventure only when it is on for the child AND its signed pack is
// installed and verified on this device (orchestrator decision, from QA's release note on L0; docs/languages/frame.md 1.1).
// If no language qualifies the map is the 7-land one. Until a language pack is published the island therefore never shows.
// The map also waits for the settings and the packs, so it never flashes the 7-land scene first (QA-L0-4).
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/app/language_providers.dart';
import 'package:nitznutz/child/calm_loading.dart';
import 'package:nitznutz/child/home_screen.dart';
import 'package:nitznutz/child/languages_doors.dart';
import 'package:nitznutz/parent/language_pages.dart';
import 'package:nitznutz/parent/language_settings.dart';
import 'package:nitznutz/strings/he.dart';

import 'support/app_harness.dart';
import 'support/harness.dart';
import 'support/language_screens.dart';

const Map<String, LanguageSwitches> allOn = <String, LanguageSwitches>{
  'eng': LanguageSwitches(on: true),
  'heb': LanguageSwitches(on: true),
  'rus': LanguageSwitches(on: true),
};

Future<void> openMap(WidgetTester tester, AppRig rig) async {
  await rig.pump(tester);
  await tester.tap(find.text('נועה'));
  await tester.pumpAndSettle();
  expect(find.byType(HomeScreen), findsOneWidget);
}

void main() {
  setUpAll(loadAppFonts);

  group('the map', () {
    testWidgets('all three languages on but no pack installed: the 7-land map, as if they were off', (
      WidgetTester tester,
    ) async {
      final AppRig rig = await langRig(languages: allOn, installed: const <String>[]);
      await openMap(tester, rig);
      expect(find.byKey(const Key('sign-languages')), findsNothing);
      expect(find.byKey(const Key('land-tap-languages')), findsNothing);
      expect(find.byKey(const PageStorageKey<String>('home-map-lang')), findsNothing);
    });

    testWidgets('a pack installed but the language off for this child: no island', (
      WidgetTester tester,
    ) async {
      final AppRig rig = await langRig(
        languages: <String, LanguageSwitches>{'eng': const LanguageSwitches(on: false)},
        installed: const <String>['eng'],
      );
      await openMap(tester, rig);
      expect(find.byKey(const Key('sign-languages')), findsNothing);
    });

    testWidgets('on and installed: the island, and only the installed languages get a door', (
      WidgetTester tester,
    ) async {
      final AppRig rig = await langRig(languages: allOn, installed: const <String>['eng', 'rus']);
      await openMap(tester, rig);
      expect(find.byKey(const Key('sign-languages')), findsOneWidget);
      final Finder tap = find.byKey(const Key('land-tap-languages'));
      await tester.ensureVisible(tap);
      await tester.pumpAndSettle();
      await tester.tap(tap);
      await tester.pumpAndSettle();
      expect(find.byType(LanguagesDoorsScreen), findsOneWidget);
      expect(find.byKey(const Key('door-eng')), findsOneWidget);
      expect(find.byKey(const Key('door-rus')), findsOneWidget);
      expect(
        find.byKey(const Key('door-heb')),
        findsNothing,
        reason: 'on, but its lessons are not on this phone',
      );
    });

    testWidgets(
      'one language on and installed, two more on without a pack: it opens straight, no door screen',
      (WidgetTester tester) async {
        final AppRig rig = await langRig(languages: allOn, installed: const <String>['heb']);
        await openMap(tester, rig);
        final Finder tap = find.byKey(const Key('land-tap-languages'));
        await tester.ensureVisible(tap);
        await tester.pumpAndSettle();
        await tester.tap(tap);
        await tester.pumpAndSettle();
        expect(find.byType(LanguagesDoorsScreen), findsNothing);
        expect(find.byType(CourseHomeScreen), findsOneWidget);
      },
    );

    testWidgets(
      'QA-L0-4: the map waits for the settings and the packs, then its first frame is the 8-land scene',
      (WidgetTester tester) async {
        final Completer<void> packs = Completer<void>();
        final AppRig rig = await langRig(languages: allOn, installed: const <String>['eng']);
        rig.holdLanguagePacks = packs;
        await rig.pump(tester);
        await tester.tap(find.text('נועה'));
        for (int i = 0; i < 20; i++) {
          await tester.pump(const Duration(milliseconds: 50));
        }
        expect(
          find.byType(CalmLoading),
          findsOneWidget,
          reason: 'the map is not drawn until the packs are known',
        );
        expect(find.byType(HomeScreen), findsNothing);
        packs.complete();
        final List<bool> frames = <bool>[];
        for (int i = 0; i < 30; i++) {
          await tester.pump(const Duration(milliseconds: 16));
          if (find.byType(HomeScreen).evaluate().isEmpty) continue;
          frames.add(find.byKey(const PageStorageKey<String>('home-map-lang')).evaluate().isNotEmpty);
        }
        expect(frames, isNotEmpty);
        expect(frames.toSet(), <bool>{true}, reason: 'no frame of the 7-land scene: $frames');
      },
    );
  });

  group('the providers', () {
    test('available = on for the child and installed, in the fixed order of the doors', () async {
      final AppRig rig = await langRig(languages: allOn, installed: const <String>['rus', 'eng']);
      final ProviderContainer c = ProviderContainer(overrides: rig.overrides);
      addTearDown(c.dispose);
      addTearDown(rig.db.close);
      await c.read(languagesProvider.future);
      await c.read(languagePacksProvider.future);
      expect(c.read(languagesAvailableProvider(langKid)), <String>['eng', 'rus']);
      expect(c.read(languagesAvailableProvider('child-lang-0002')), isEmpty, reason: 'a sibling has none on');
    });

    test('nothing is available before the settings and the packs are read', () {
      final AppRig rig = AppRig();
      final ProviderContainer c = ProviderContainer(overrides: rig.overrides);
      addTearDown(c.dispose);
      addTearDown(rig.db.close);
      expect(c.read(languagesReadyProvider), isFalse);
      expect(c.read(languagesAvailableProvider(langKid)), isEmpty);
    });
  });

  group('the parent page', () {
    testWidgets('a language that is on without its lessons says they have not arrived yet', (
      WidgetTester tester,
    ) async {
      final AppRig rig = await langRig(
        languages: <String, LanguageSwitches>{'rus': const LanguageSwitches(on: true)},
        installed: const <String>[],
      );
      await pumpParentScreen(tester, rig, LanguagePage(profile: await langProfile(rig), course: 'rus'));
      expect(
        tester
            .widget<Switch>(
              find.descendant(of: find.byKey(const Key('page-on')), matching: find.byType(Switch)),
            )
            .value,
        isTrue,
        reason: 'the switch is still on',
      );
      expect(find.byKey(const Key('page-no-course')), findsOneWidget);
      expect(find.text(He.langProgressNoCourse.text), findsOneWidget);
    });

    testWidgets('with its lessons installed there is no such line; off, there is none either', (
      WidgetTester tester,
    ) async {
      final AppRig installed = await langRig(
        languages: <String, LanguageSwitches>{'rus': const LanguageSwitches(on: true)},
        installed: const <String>['rus'],
      );
      await pumpParentScreen(
        tester,
        installed,
        LanguagePage(profile: await langProfile(installed), course: 'rus'),
      );
      expect(find.byKey(const Key('page-no-course')), findsNothing);

      final AppRig off = await langRig(
        languages: const <String, LanguageSwitches>{},
        installed: const <String>[],
      );
      await pumpParentScreen(tester, off, LanguagePage(profile: await langProfile(off), course: 'rus'));
      expect(find.byKey(const Key('page-no-course')), findsNothing);
    });
  });
}
