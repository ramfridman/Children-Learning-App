// The Languages island on the map and the door screen (docs/design/languages-island.md sections 1 to 4): the 8-land map is used
// only when a language is on (the 7-land map is untouched when all are off), a door for each language that is on in the fixed
// order from the right, no locked door, one language on opens its course at once, and a door opens a course home that lists
// nothing. The real app with the real pack.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/child/home_screen.dart';
import 'package:nitznutz/child/languages_doors.dart';
import 'package:nitznutz/parent/language_settings.dart';

import 'support/app_harness.dart';
import 'support/harness.dart';

const Map<String, Size> boards = <String, Size>{
  'phone': Size(852, 393),
  'phoneSE': Size(667, 375),
  'tabletLandscape': Size(1180, 820),
  'tabletPortrait': Size(820, 1180),
};

/// The app on [size] with the given languages on for the child `p-1`.
Future<AppRig> home(WidgetTester tester, Size size, List<String> on) async {
  final AppRig rig = AppRig()..installedLanguages = on;
  await rig.seedFinishedSetup(id: kid);
  FamilyLanguages f = const FamilyLanguages();
  for (final String c in on) {
    f = f.withSwitches(kid, c, const LanguageSwitches(on: true))!;
  }
  if (on.isNotEmpty) await rig.db.putSetting(languagesSettingKey, f.encode());
  await rig.pump(tester, size: size);
  await tester.tap(find.text('נועה'));
  await tester.pumpAndSettle();
  expect(find.byType(HomeScreen), findsOneWidget);
  return rig;
}

/// A child id of the shape the family's account takes (the rig's usual `p-1` is too short for it).
const String kid = 'child-lang-0001';

Finder get doorScreen => find.byType(LanguagesDoorsScreen);

void main() {
  setUpAll(loadAppFonts);

  for (final MapEntry<String, Size> board in boards.entries) {
    group('the map on ${board.key}', () {
      testWidgets('every language off: the 7-land map as it was, with no Languages island', (
        WidgetTester tester,
      ) async {
        await home(tester, board.value, const <String>[]);
        expect(find.byKey(const Key('sign-languages')), findsNothing);
        expect(find.byKey(const Key('land-tap-languages')), findsNothing);
        for (final Land l in Land.values.where((Land l) => l != Land.languages)) {
          expect(find.byKey(Key('sign-${l.name}')), findsOneWidget, reason: l.name);
        }
        expect(
          find.byKey(const PageStorageKey<String>('home-map')),
          board.key == 'tabletLandscape' ? findsNothing : findsOneWidget,
        );
        expect(find.byKey(const PageStorageKey<String>('home-map-lang')), findsNothing);
      });

      testWidgets('a language on: all eight signs and tap areas, and the map has its own scroll key', (
        WidgetTester tester,
      ) async {
        await home(tester, board.value, const <String>['eng']);
        for (final Land l in Land.values) {
          expect(find.byKey(Key('sign-${l.name}')), findsOneWidget, reason: l.name);
          expect(find.byKey(Key('land-tap-${l.name}')), findsOneWidget, reason: l.name);
        }
        expect(find.byKey(const PageStorageKey<String>('home-map')), findsNothing);
        if (board.key != 'tabletLandscape') {
          expect(find.byKey(const PageStorageKey<String>('home-map-lang')), findsOneWidget);
        }
      });

      testWidgets('the tap areas are at least 64 wide and no two touch (a gap of 16 or more)', (
        WidgetTester tester,
      ) async {
        await home(tester, board.value, const <String>['eng', 'heb']);
        final List<Rect> areas = <Rect>[
          for (final Land l in Land.values) tester.getRect(find.byKey(Key('land-tap-${l.name}'))),
        ];
        for (final Rect a in areas) {
          expect(a.width, greaterThanOrEqualTo(64));
        }
        for (int i = 0; i < areas.length; i++) {
          for (int j = i + 1; j < areas.length; j++) {
            final Rect a = areas[i];
            final Rect b = areas[j];
            final double gapX = a.left >= b.right
                ? a.left - b.right
                : b.left >= a.right
                ? b.left - a.right
                : -1;
            final double gapY = a.top >= b.bottom
                ? a.top - b.bottom
                : b.top >= a.bottom
                ? b.top - a.bottom
                : -1;
            expect(
              gapX >= 16 || gapY >= 16,
              isTrue,
              reason: 'areas ${Land.values[i].name} and ${Land.values[j].name}: $a and $b',
            );
          }
        }
      });

      testWidgets('no sign touches another, at the text size of 1.0 and of 1.3', (WidgetTester tester) async {
        for (final double scale in <double>[1.0, 1.3]) {
          tester.platformDispatcher.textScaleFactorTestValue = scale;
          addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
          await home(tester, board.value, const <String>['eng', 'heb', 'rus']);
          final List<Rect> signs = <Rect>[
            for (final Land l in Land.values) tester.getRect(find.byKey(Key('sign-${l.name}'))),
          ];
          for (int i = 0; i < signs.length; i++) {
            for (int j = i + 1; j < signs.length; j++) {
              expect(
                signs[i].overlaps(signs[j]),
                isFalse,
                reason: '$scale: ${Land.values[i].name} ${Land.values[j].name}',
              );
            }
          }
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox());
        }
      });

      testWidgets(
        'one language on: the Languages island opens its course at once, and back comes to the map',
        (WidgetTester tester) async {
          await home(tester, board.value, const <String>['rus']);
          final Finder tap = find.byKey(const Key('land-tap-languages'));
          await tester.ensureVisible(tap);
          await tester.pumpAndSettle();
          await tester.tap(tap);
          await tester.pumpAndSettle();
          expect(doorScreen, findsNothing, reason: 'no door screen for one language');
          expect(find.byType(CourseHomeScreen), findsOneWidget);
          expect(tester.widget<CourseHomeScreen>(find.byType(CourseHomeScreen)).course, 'rus');
          await tester.tap(find.byKey(const Key('course-back')));
          await tester.pumpAndSettle();
          expect(find.byType(HomeScreen), findsOneWidget);
        },
      );
    });
  }

  group('the start view of the 8-land map', () {
    testWidgets(
      'phone: home, the Languages island centred at 360, and half of Counting Hills with its whole sign',
      (WidgetTester tester) async {
        await home(tester, boards['phone']!, const <String>['eng']);
        expect(tester.getCenter(find.byKey(const Key('sign-languages'))).dx, closeTo(360, 3));
        final Rect counting = tester.getRect(find.byKey(const Key('sign-counting')));
        expect(counting.left, closeTo(12 + 1530 - 1530, 1), reason: 'pinned 12 inside the edge');
        expect(counting.left, greaterThanOrEqualTo(0));
      },
    );

    testWidgets('phone SE: the Languages island centred at 268', (WidgetTester tester) async {
      await home(tester, boards['phoneSE']!, const <String>['eng']);
      expect(tester.getCenter(find.byKey(const Key('sign-languages'))).dx, closeTo(268, 3));
    });

    testWidgets('portrait: the Languages island at 1112 at the start, 52 below the pill for Robot Harbour', (
      WidgetTester tester,
    ) async {
      await home(tester, boards['tabletPortrait']!, const <String>['eng']);
      expect(tester.getTopLeft(find.byKey(const Key('sign-languages'))).dy, closeTo(1112, 3));
    });

    testWidgets(
      'landscape: the Languages tap area reaches the screen edge and Market Village has moved left',
      (WidgetTester tester) async {
        await home(tester, boards['tabletLandscape']!, const <String>['eng']);
        final Rect lang = tester.getRect(find.byKey(const Key('land-tap-languages')));
        expect(lang.right, closeTo(1180, 1));
        expect(lang.left, closeTo(984, 1));
        final Rect market = tester.getRect(find.byKey(const Key('land-tap-market')));
        expect(market.left, closeTo(736, 1));
        expect(market.right, closeTo(964, 1));
      },
    );
  });

  group('the door screen', () {
    Future<void> toDoors(WidgetTester tester, Size size, List<String> on) async {
      await home(tester, size, on);
      final Finder tap = find.byKey(const Key('land-tap-languages'));
      await tester.ensureVisible(tap);
      await tester.pumpAndSettle();
      await tester.tap(tap);
      await tester.pumpAndSettle();
      expect(doorScreen, findsOneWidget);
    }

    for (final MapEntry<String, Size> board in boards.entries) {
      testWidgets('${board.key}: three doors, English at the right, then Hebrew, then Russian', (
        WidgetTester tester,
      ) async {
        await toDoors(tester, board.value, const <String>['rus', 'eng', 'heb']);
        final double eng = tester.getCenter(find.byKey(const Key('door-eng'))).dx;
        final double heb = tester.getCenter(find.byKey(const Key('door-heb'))).dx;
        final double rus = tester.getCenter(find.byKey(const Key('door-rus'))).dx;
        expect(eng, greaterThan(heb));
        expect(heb, greaterThan(rus));
        // A door's tap rectangle is 178, 158, 244 and 224 wide (design 4.2.1), a hand's width above the band A target.
        expect(tester.getSize(find.byKey(const Key('door-eng'))).width, greaterThanOrEqualTo(158));
      });

      testWidgets(
        '${board.key}: two doors show in the same order, and a language that is off has no door at all',
        (WidgetTester tester) async {
          await toDoors(tester, board.value, const <String>['rus', 'eng']);
          expect(
            find.byKey(const Key('door-heb')),
            findsNothing,
            reason: 'no greyed door, no lock, no coming soon',
          );
          expect(
            tester.getCenter(find.byKey(const Key('door-eng'))).dx,
            greaterThan(tester.getCenter(find.byKey(const Key('door-rus'))).dx),
          );
        },
      );
    }

    testWidgets(
      'a tap on a door opens it, then the course home, which lists nothing; back comes to the doors',
      (WidgetTester tester) async {
        await toDoors(tester, boards['phone']!, const <String>['eng', 'heb', 'rus']);
        await tester.tap(find.byKey(const Key('door-heb')));
        await tester.pump();
        // While a door is opening the other doors do nothing.
        await tester.tap(find.byKey(const Key('door-rus')), warnIfMissed: false);
        await tester.pump(const Duration(milliseconds: 700));
        await tester.pumpAndSettle();
        expect(find.byType(CourseHomeScreen), findsOneWidget);
        expect(tester.widget<CourseHomeScreen>(find.byType(CourseHomeScreen)).course, 'heb');
        expect(find.byType(Text), findsNothing, reason: 'a course home lists nothing: a host and a way back');
        await tester.tap(find.byKey(const Key('course-back')));
        await tester.pumpAndSettle();
        expect(doorScreen, findsOneWidget, reason: 'the door screen is as it was');
        await tester.tap(find.byKey(const Key('doors-back')));
        await tester.pumpAndSettle();
        expect(find.byType(HomeScreen), findsOneWidget);
      },
    );

    testWidgets('the doors are announced by the name of the language, and the hello word is not read', (
      WidgetTester tester,
    ) async {
      await toDoors(tester, boards['phone']!, const <String>['eng', 'heb', 'rus']);
      final SemanticsHandle handle = tester.ensureSemantics();
      for (final String name in <String>['אנגלית', 'עברית', 'רוסית']) {
        expect(find.bySemanticsLabel(name), findsOneWidget, reason: name);
      }
      expect(find.bySemanticsLabel('Hello'), findsNothing);
      expect(find.bySemanticsLabel('Привет'), findsNothing);
      handle.dispose();
    });

    testWidgets(
      'the hello words are set in their own script and locale: English and Russian in the teaching font',
      (WidgetTester tester) async {
        await toDoors(tester, boards['phone']!, const <String>['eng', 'heb', 'rus']);
        final Text en = tester.widget<Text>(find.text('Hello'));
        final Text ru = tester.widget<Text>(find.text('Привет'));
        expect(en.style!.fontFamily, 'NitznutzLetters');
        expect(ru.style!.fontFamily, 'NitznutzLetters');
        expect(en.locale, const Locale('en'));
        expect(ru.locale, const Locale('ru'));
        expect(ru.data!.contains('́'), isFalse, reason: 'no stress mark in a greeting');
        expect(tester.widget<Text>(find.text('שָׁלוֹם')).style!.fontFamily, 'Heebo');
      },
    );
  });
}
