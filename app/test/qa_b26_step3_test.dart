// QA, B-26 step 3: an independent check of the home island in the real app (docs/qa/b26-step3-verification.md): the
// sign, the free part of the island and Today's Adventure open the child's home (a placeholder until step 4) on four
// boards at text scale 1.0 and 1.3, for names a parent may type (empty, blank, direction marks, emoji, Latin, 24, 25 and
// 40 letters); the title, the bubble, the way back and the scroll; a name changed by the family; the lands.
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
import 'package:nitznutz/data/app_database.dart';
import 'package:nitznutz/strings/he.dart';

import 'support/app_harness.dart';
import 'support/harness.dart';

const Map<String, Size> boards = <String, Size>{
  'phone': Size(852, 393),
  'phoneSE': Size(667, 375),
  'tabletLandscape': Size(1180, 820),
  'tabletPortrait': Size(820, 1180),
};

/// The bubble's widest body per board (padding included): the open sea on phones, 210 on tablets.
const Map<String, double> bubbleMax = <String, double>{
  'phone': 852 - 212 - 16,
  'phoneSE': 667 - 154 - 16,
  'tabletLandscape': 210,
  'tabletPortrait': 210,
};

/// Names as a parent may type them (the profile form takes up to 40).
const Map<String, String> names = <String, String>{
  'noa': 'נועה',
  'marks_only': '\u200F\u200E',
  'blank': '   ',
  'bidi': '\u200F\u202Aמיכל\u202C\u200E',
  'emoji': '🦊🌈',
  'latin': 'Zoë Élodie',
  'wide_24': 'שששששששששששששששששששששששש',
  'letters_25': 'אבגדהוזחטיכלמנסעפצקרשתאבג',
  'parts_40': 'אבגדהוזחטי אבגדהוזחטי אבגדהוזחטי אבגדהוז',
};

/// The bubble's own line for a child with no usable name (B-26 step 3b).
final String bubbleWithoutName = He.homeBubbleNoName.text;

/// The errors list of the running test, and how many of them the profile picker raised (before the map).
List<FlutterErrorDetails>? errorsSoFar;
int pickerErrors = 0;

Future<AppRig> openMap(WidgetTester tester, Size size, String name) async {
  final AppRig rig = AppRig();
  await rig.seedFinishedSetup(name: name);
  await rig.pump(tester, size: size);
  pickerErrors = errorsSoFar?.length ?? 0;
  // The picker shows the name as typed; choosing through the state works for an empty name too.
  final ProviderContainer c = ProviderScope.containerOf(tester.element(find.byType(ProfilePicker)));
  final AppState app = await c.read(appStateProvider.future);
  c.read(activeProfileProvider.notifier).choose(app.profiles.single);
  await tester.pumpAndSettle();
  expect(find.byType(HomeScreen), findsOneWidget);
  return rig;
}

Finder inKey(String key, Type type) => find.descendant(of: find.byKey(Key(key)), matching: find.byType(type));

String textIn(WidgetTester tester, String key) => tester.widget<Text>(inKey(key, Text)).data!;

/// The exceptions so far, except the known QA-19 pill overflow (phone, text scale 1.3).
List<String> unexpected(WidgetTester tester, List<FlutterErrorDetails> errors) => <String>[
  for (final FlutterErrorDetails e in errors)
    if (!'${e.exception}'.contains('RenderFlex overflowed') || !_pillOverflows(tester)) _describe(e),
];

/// The error and the widget that caused it (printed in full to the log).
String _describe(FlutterErrorDetails e) {
  FlutterError.dumpErrorToConsole(e, forceReport: true);
  return '${e.exception}';
}

bool _pillOverflows(WidgetTester tester) {
  final Finder pill = find.byKey(const Key('home-pill'));
  if (pill.evaluate().isEmpty) return false;
  final RenderFlex row = tester.renderObject<RenderFlex>(
    find.descendant(of: pill, matching: find.byType(Row)).first,
  );
  double used = 0;
  for (RenderBox? ch = row.firstChild; ch != null; ch = (ch.parentData! as FlexParentData).nextSibling) {
    used += ch.size.width;
  }
  return used > row.size.width;
}

Future<void> backToMap(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('home-island-back')));
  await tester.pumpAndSettle();
  expect(find.byType(HomeIslandScreen), findsNothing);
  expect(find.byType(HomeScreen), findsOneWidget);
}

void main() {
  setUpAll(loadAppFonts);

  group('the real app: every way into the home, every board, text scale 1.0 and 1.3', () {
    for (final MapEntry<String, Size> b in boards.entries) {
      for (final double scale in <double>[1.0, 1.3]) {
        for (final MapEntry<String, String> n in names.entries) {
          testWidgets('${b.key} x$scale ${n.key}', (WidgetTester tester) async {
            final List<FlutterErrorDetails> errors = <FlutterErrorDetails>[];
            final void Function(FlutterErrorDetails)? before = FlutterError.onError;
            FlutterError.onError = errors.add;
            errorsSoFar = errors;
            tester.platformDispatcher.textScaleFactorTestValue = scale;
            addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
            final HomeIslandName island = homeIslandName(n.value);
            try {
              await openMap(tester, b.value, n.value);
              final List<String> problems = <String>[];

              // The sign: the whole line, a shortened form of it, or the fallback; never Nitzi's island.
              final String sign = textIn(tester, 'sign-nitzi');
              expect(sign, isNot(He.landNitzi.text));
              if (island.isNamed) {
                expect(
                  sign == island.sign ||
                      <String>[for (int k = 3; k < 41; k++) island.signShortened(k)].contains(sign),
                  isTrue,
                  reason: sign,
                );
              } else {
                expect(sign, He.homeIslandMine.text);
              }

              // The bubble: the cleaned name (or none), within its width, one line on phones, two at most on tablets.
              final String bubble = textIn(tester, 'bubble-body');
              if (!island.isNamed) {
                expect(bubble, bubbleWithoutName);
              } else {
                expect(bubble.contains('\u200F') || bubble.contains('\u202A'), isFalse, reason: 'cleaned');
                // The name sits in an isolate (B-26 step 3b), so its "…" stays on its right.
                final String shown = bubble.split(',').first;
                expect(shown, startsWith('\u2068'), reason: bubble);
                expect(shown, endsWith('\u2069'), reason: bubble);
                final String inner = shown.substring(1, shown.length - 1);
                expect(island.name.startsWith(inner.replaceAll(ellipsis, '')), isTrue, reason: bubble);
              }
              final Rect body = tester.getRect(find.byKey(const Key('bubble-body')));
              if (body.width > bubbleMax[b.key]! + 0.01) problems.add('bubble ${body.width} wide');
              if (body.left < 0 || body.top < 0 || body.right > b.value.width) {
                problems.add('bubble off screen $body');
              }
              final RenderParagraph para = tester.renderObject<RenderParagraph>(
                inKey('bubble-body', RichText),
              );
              final double font = b.key.startsWith('tablet') ? 24 : (b.key == 'phone' ? 18 : 17);
              final int lines = (para.size.height / (font * scale * 1.7)).round();
              if (lines > (b.key.startsWith('tablet') ? 2 : 1)) {
                problems.add('bubble $lines lines: "$bubble"');
              }
              debugPrint(
                'QA3 ${b.key} x$scale ${n.key}: bubble ${body.width.toStringAsFixed(1)} wide, left '
                '${body.left.toStringAsFixed(1)}, $lines line(s): "${bubble.replaceAll('\n', ' / ')}"',
              );

              // 1. The sign opens the home, with the whole title (24 guard) and no overflow.
              await tester.tap(find.byKey(const Key('sign-nitzi')));
              await tester.pumpAndSettle();
              expect(find.byType(HomeIslandScreen), findsOneWidget);
              expect(find.byType(LandScreen), findsNothing);
              expect(find.text(island.title), findsOneWidget);
              final Rect title = tester.getRect(find.byKey(const Key('home-island-title')));
              final Rect back = tester.getRect(find.byKey(const Key('home-island-back')));
              if (title.left < 0 || title.right > b.value.width || title.bottom > b.value.height) {
                problems.add('title off screen $title');
              }
              if (title.overlaps(back)) problems.add('title $title over the back pebble $back');
              debugPrint('QA3 ${b.key} x$scale ${n.key}: title $title');
              await backToMap(tester);

              // 2. Today's Adventure.
              await tester.tap(find.byKey(const Key('home-pill')));
              await tester.pumpAndSettle();
              expect(find.byType(HomeIslandScreen), findsOneWidget);
              await backToMap(tester);

              // 3. The free part of the island's tap area (beside the companion).
              final Rect area = tester.getRect(find.byKey(const Key('land-tap-nitzi')));
              final Rect friend = tester.getRect(find.byKey(const Key('home-companion')));
              await tester.tapAt(Offset((area.left + friend.left) / 2, area.center.dy));
              await tester.pumpAndSettle();
              expect(find.byType(HomeIslandScreen), findsOneWidget, reason: 'free part $area beside $friend');
              await backToMap(tester);

              expect(problems, isEmpty, reason: problems.join('\n'));
            } finally {
              FlutterError.onError = before;
            }
            errorsSoFar = null;
            // What the profile picker raised before the map is QA-19 (its cards overflow 2 to 3 at 1.3; open, logged).
            for (final FlutterErrorDetails e in errors.take(pickerErrors)) {
              debugPrint('QA3 ${b.key} x$scale ${n.key}: in the picker: ${e.exception}');
            }
            expect(unexpected(tester, errors.skip(pickerErrors).toList()), isEmpty);
          });
        }
      }
    }
  });

  group('a name changed by the family', () {
    for (final MapEntry<String, Size> b in boards.entries) {
      testWidgets('${b.key}: to another name, then to none; the sign and the bubble follow', (
        WidgetTester tester,
      ) async {
        final AppRig rig = await openMap(tester, b.value, 'נועה');
        Future<void> rename(String to) async {
          await rig.db.upsertProfileFromFamily(
            ProfilesCompanion.insert(
              id: 'p-1',
              name: to,
              avatar: 'avatar-noa',
              addressForm: 'f',
              ageBand: 1,
              createdAt: DateTime.utc(2026, 10, 26),
            ),
            isNew: false,
          );
          ProviderScope.containerOf(tester.element(find.byType(HomeScreen))).invalidate(appStateProvider);
          await tester.pumpAndSettle();
        }

        await rename('אלכסנדרה');
        expect(textIn(tester, 'sign-nitzi'), homeIslandName('אלכסנדרה').sign);
        expect(textIn(tester, 'bubble-body'), startsWith('${isolatedName('אלכסנדרה')},'));
        await tester.tap(find.byKey(const Key('home-pill')));
        await tester.pumpAndSettle();
        expect(find.text(homeIslandName('אלכסנדרה').title), findsOneWidget);
        await backToMap(tester);
        await rename('   ');
        expect(textIn(tester, 'sign-nitzi'), He.homeIslandMine.text);
        expect(textIn(tester, 'bubble-body'), bubbleWithoutName);
        await tester.tap(find.byKey(const Key('sign-nitzi')));
        await tester.pumpAndSettle();
        expect(find.text(homeIslandName('').title), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('coming back from the home, the map is where the child left it', () {
    testWidgets('portrait tablet, scrolled up, opened from the pill', (WidgetTester tester) async {
      await openMap(tester, boards['tabletPortrait']!, 'נועה');
      final ScrollPosition map = tester
          .state<ScrollableState>(
            find.descendant(
              of: find.byKey(const PageStorageKey<String>('home-map')),
              matching: find.byType(Scrollable),
            ),
          )
          .position;
      map.jumpTo(300);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('home-pill')));
      await tester.pumpAndSettle();
      await backToMap(tester);
      expect(map.pixels, 300);
    });

    testWidgets('phone, panned a little, opened from the sign itself', (WidgetTester tester) async {
      await openMap(tester, boards['phone']!, 'נועה');
      final ScrollPosition map = tester
          .state<ScrollableState>(
            find.descendant(
              of: find.byKey(const PageStorageKey<String>('home-map')),
              matching: find.byType(Scrollable),
            ),
          )
          .position;
      map.jumpTo(120);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('sign-nitzi')));
      await tester.pumpAndSettle();
      expect(find.byType(HomeIslandScreen), findsOneWidget);
      await backToMap(tester);
      expect(map.pixels, 120);
    });
  });

  testWidgets('the real app never offers the home island as a land', (WidgetTester tester) async {
    await openMap(tester, boards['phone']!, 'נועה');
    final HomeScreen screen = tester.widget<HomeScreen>(find.byType(HomeScreen));
    expect(screen.openableLands.contains(Land.nitzi), isFalse);
    expect(screen.onOpenHome, isNotNull);
    expect(screen.homeIsland?.name, 'נועה');
  });
}
