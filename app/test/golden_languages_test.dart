// Goldens of the Languages island: the 8-land map on the four boards (and the end of the phone's strip), the door screen with
// three doors and with two, and the parent pages (the course home's goldens are in `golden_course_home_test.dart`). The 7-land map's own goldens are untouched.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/app/language_providers.dart';
import 'package:nitznutz/child/home_screen.dart';
import 'package:nitznutz/child/languages_doors.dart';
import 'package:nitznutz/parent/language_pages.dart';
import 'package:nitznutz/parent/language_settings.dart';
import 'package:nitznutz/strings/he.dart';

import 'languages_parent_test.dart' show sample;
import 'support/app_harness.dart';
import 'support/golden_comparator.dart';
import 'support/harness.dart';
import 'support/language_screens.dart';

const Size phone = Size(852, 393);
const Size phoneSE = Size(667, 375);
const Size tabletL = Size(1180, 820);
const Size tabletP = Size(820, 1180);

const Map<String, Size> boards = <String, Size>{
  'phone': phone,
  'phoneSE': phoneSE,
  'tabletLandscape': tabletL,
  'tabletPortrait': tabletP,
};

Future<void> _shot(WidgetTester tester, String name) async {
  await tester.pumpAndSettle();
  await expectLater(find.byType(MaterialApp), matchesGoldenFile('goldens/$name.png'));
}

/// The child's map with the given languages on.
Future<AppRig> _map(WidgetTester tester, Size size, List<String> on) async {
  final AppRig rig = await langRig(
    languages: <String, LanguageSwitches>{for (final String c in on) c: const LanguageSwitches(on: true)},
  );
  await rig.pump(tester, size: size);
  await tester.tap(find.text('נועה'));
  await tester.pumpAndSettle();
  expect(find.byType(HomeScreen), findsOneWidget);
  return rig;
}

Future<void> _doors(WidgetTester tester, Size size, List<String> on) async {
  await _map(tester, size, on);
  final Finder tap = find.byKey(const Key('land-tap-languages'));
  await tester.ensureVisible(tap);
  await tester.pumpAndSettle();
  await tester.tap(tap);
  await tester.pumpAndSettle();
  expect(find.byType(LanguagesDoorsScreen), findsOneWidget);
}

void main() {
  setUpAll(() async {
    await loadAppFonts();
    useTolerantGoldens(0.03);
  });

  group('the 8-land map', () {
    for (final MapEntry<String, Size> b in boards.entries) {
      testWidgets('${b.key}, a language on', (WidgetTester tester) async {
        await _map(tester, b.value, const <String>['eng', 'heb', 'rus']);
        await _shot(tester, 'home_${b.key}_lang');
      });
    }

    testWidgets('phone, the far end of the strip: Market Village and the lands behind the island', (
      WidgetTester tester,
    ) async {
      await _map(tester, phone, const <String>['eng', 'heb', 'rus']);
      final ScrollPosition map = tester
          .state<ScrollableState>(
            find.descendant(
              of: find.byKey(const PageStorageKey<String>('home-map-lang')),
              matching: find.byType(Scrollable),
            ),
          )
          .position;
      map.jumpTo(map.maxScrollExtent);
      await _shot(tester, 'home_phone_lang_end');
    });
  });

  group('the door screen', () {
    for (final MapEntry<String, Size> b in boards.entries) {
      testWidgets('${b.key}, three doors', (WidgetTester tester) async {
        await _doors(tester, b.value, const <String>['eng', 'heb', 'rus']);
        await _shot(tester, 'languages_doors_${b.key}');
      });
    }

    testWidgets('phone, two doors', (WidgetTester tester) async {
      await _doors(tester, phone, const <String>['rus', 'eng']);
      await _shot(tester, 'languages_doors_phone_two');
    });

    testWidgets('tablet portrait, two doors', (WidgetTester tester) async {
      await _doors(tester, tabletP, const <String>['heb', 'rus']);
      await _shot(tester, 'languages_doors_tabletPortrait_two');
    });

    testWidgets('phone, the Hebrew door opening', (WidgetTester tester) async {
      await _doors(tester, phone, const <String>['eng', 'heb', 'rus']);
      await tester.tap(find.byKey(const Key('door-heb')));
      await tester.pump(const Duration(milliseconds: 300));
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/languages_doors_phone_opening_heb.png'),
      );
      await tester.pump(const Duration(milliseconds: 700));
      await tester.pumpAndSettle();
    });
  });

  group('the parent pages', () {
    for (final (String, Size) b in <(String, Size)>[
      ('phone', Size(852, 1300)),
      ('tabletPortrait', Size(820, 1180)),
    ]) {
      testWidgets('the Languages card, ${b.$1}', (WidgetTester tester) async {
        final AppRig rig = await langRig(
          languages: <String, LanguageSwitches>{
            'eng': const LanguageSwitches(on: true),
            'heb': const LanguageSwitches(on: true),
          },
        );
        await pumpParentScreen(
          tester,
          rig,
          ChildSettingsScreen(profile: await langProfile(rig), onClose: () {}),
          size: b.$2,
        );
        await _shot(tester, 'parent_languages_list_${b.$1}');
      });
    }

    testWidgets('Russian page, tablet portrait', (WidgetTester tester) async {
      final AppRig rig = await langRig(
        languages: <String, LanguageSwitches>{'rus': const LanguageSwitches(on: true, route: 'new')},
      );
      await pumpParentScreen(
        tester,
        rig,
        LanguagePage(profile: await langProfile(rig), course: 'rus'),
        size: const Size(820, 1180),
      );
      await _shot(tester, 'parent_language_page_rus_tabletPortrait');
    });

    testWidgets('English page, phone', (WidgetTester tester) async {
      final AppRig rig = await langRig(
        languages: <String, LanguageSwitches>{'eng': const LanguageSwitches(on: true, oralOnly: true)},
      );
      await pumpParentScreen(
        tester,
        rig,
        LanguagePage(profile: await langProfile(rig), course: 'eng'),
        size: const Size(852, 1100),
      );
      await _shot(tester, 'parent_language_page_eng_phone');
    });

    testWidgets('the questionnaire', (WidgetTester tester) async {
      final AppRig rig = await langRig(
        languages: <String, LanguageSwitches>{
          'rus': const LanguageSwitches(
            on: true,
            questionnaire: <String, String>{'home': 'bothParents', 'speaks': 'words'},
          ),
        },
      );
      await pumpParentScreen(
        tester,
        rig,
        QuestionnairePage(profile: await langProfile(rig), course: 'rus'),
        size: const Size(820, 1180),
      );
      await _shot(tester, 'parent_language_questionnaire_rus');
    });

    testWidgets('the progress in English, tablet portrait', (WidgetTester tester) async {
      final AppRig rig = await langRig(
        languages: <String, LanguageSwitches>{'eng': const LanguageSwitches(on: true)},
      );
      await pumpParentScreen(
        tester,
        rig,
        LanguageProgressPage(profile: await langProfile(rig), course: 'eng'),
        size: const Size(820, 1180),
        extra: <Override>[
          languageProgressProvider.overrideWith(
            (Ref ref, ({String childId, String course}) key) async => sample(),
          ),
        ],
      );
      await _shot(tester, 'parent_language_progress_eng_tabletPortrait');
      expect(find.text(He.areaLangGateEng.text), findsOneWidget);
    });
  });
}
