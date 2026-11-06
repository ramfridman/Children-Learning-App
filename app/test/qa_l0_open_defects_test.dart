// QA's defects of milestone L0 (docs/qa/l0-languages-verification.md): QA-L0-1 to QA-L0-4, each fixed. Their proofs run in
// every build.
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/child/companion_views.dart' show MapCompanion;
import 'package:nitznutz/child/home_screen.dart';
import 'package:nitznutz/child/course_home.dart';
import 'package:nitznutz/child/languages_doors.dart';
import 'package:nitznutz/parent/language_settings.dart';

import 'support/app_harness.dart';
import 'support/harness.dart';

const String kid = 'child-lang-0001';

/// [motion]: the test rig turns "reduce motion" on for every screen; this turns it off again just before the island is tapped.
Future<void> toDoors(WidgetTester tester, Size size, {bool motion = false}) async {
  final AppRig rig = AppRig()..installedLanguages = <String>['eng', 'heb', 'rus'];
  await rig.seedFinishedSetup(id: kid);
  FamilyLanguages f = const FamilyLanguages();
  for (final String c in <String>['eng', 'heb', 'rus']) {
    f = f.withSwitches(kid, c, const LanguageSwitches(on: true))!;
  }
  await rig.db.putSetting(languagesSettingKey, f.encode());
  await rig.pump(tester, size: size);
  await tester.tap(find.text('נועה'));
  await tester.pumpAndSettle();
  final Finder tap = find.byKey(const Key('land-tap-languages'));
  await tester.ensureVisible(tap);
  await tester.pumpAndSettle();
  if (motion) {
    tester.platformDispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures();
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
  }
  await tester.tap(tap);
  for (int i = 0; i < 30 && find.byType(LanguagesDoorsScreen).evaluate().isEmpty; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
  await tester.pump(const Duration(milliseconds: 500));
  expect(find.byType(LanguagesDoorsScreen), findsOneWidget);
}

void main() {
  setUpAll(loadAppFonts);

  // QA-L0-1. The door waits 600 ms and then opens the course whether or not the child has already pressed the back pebble: the
  // screen stays mounted while its pop transition runs, so a back press soon after the tap is followed by the course opening
  // on top of the map. With reduced motion the window is a back press 300 to 600 ms after the tap; with motion the pop takes
  // longer (500 ms or more here) and a press at 100 ms is enough. Design section 4.4: "the back pebble always works".
  for (final (String, bool, int) c in <(String, bool, int)>[
    ('reduced motion, 450 ms after the tap', false, 450),
    ('with motion, 100 ms after the tap', true, 100),
  ]) {
    testWidgets(
      'QA-L0-1: a back press while the door is opening (${c.$1}) is not followed by the course opening',
      (WidgetTester tester) async {
        await toDoors(tester, const Size(852, 393), motion: c.$2);
        await tester.tap(find.byKey(const Key('door-heb')));
        await tester.pump(Duration(milliseconds: c.$3));
        await tester.tap(find.byKey(const Key('doors-back')));
        for (int i = 0; i < 30; i++) {
          await tester.pump(const Duration(milliseconds: 100));
        }
        expect(find.byType(CourseHomeScreen), findsNothing, reason: 'the child went back to the map');
        expect(find.byType(HomeScreen), findsOneWidget);
      },
    );
  }

  // QA-L0-2. A door unit is as high as the whole board (its Stack has only positioned children and takes the biggest size), so
  // a tap on the empty grass above or below a door, on the title, or on the friend in the corner opens a door. On the portrait
  // tablet the whole companion lies under the Russian door's column. Design section 4.2: the whole unit (bubble, door, host)
  // is one tap target, not the board.
  for (final (String, Size, Offset Function(WidgetTester)) c
      in <(String, Size, Offset Function(WidgetTester))>[
        (
          'the friend in the corner, portrait tablet',
          const Size(820, 1180),
          (WidgetTester t) => t.getCenter(find.byType(MapCompanion)),
        ),
        (
          'the grass below the doors, landscape tablet',
          const Size(1180, 820),
          (WidgetTester t) => Offset(t.getCenter(find.byKey(const Key('door-heb'))).dx, 700),
        ),
        (
          'the sea above the doors, phone',
          const Size(852, 393),
          (WidgetTester t) => Offset(t.getCenter(find.byKey(const Key('door-heb'))).dx, 70),
        ),
      ]) {
    testWidgets('QA-L0-2: a tap on ${c.$1} opens no door', (WidgetTester tester) async {
      await toDoors(tester, c.$2);
      await tester.tapAt(c.$3(tester));
      for (int i = 0; i < 15; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(find.byType(CourseHomeScreen), findsNothing, reason: 'nothing the child touched was a door');
    });
  }

  // QA-L0-3. The budgerigar's long blue tail runs past the bottom of its door's picture (the tail reaches y 304.3 of a 300 high
  // viewBox: `tools/make_languages_art.py`, `host_eng()` and `door_svg()` place the 512 canvas host with its base at 300), so the
  // tail is cut off by a straight edge in `door_eng.svg` and `door_eng_open.svg` (see goldens/languages_doors_*.png).
  for (final String file in <String>['door_eng', 'door_eng_open']) {
    testWidgets(
      'QA-L0-3: the tail of the budgerigar in $file.svg is not cut by the bottom edge of its picture',
      (WidgetTester tester) async {
        final GlobalKey box = GlobalKey();
        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: Center(
              child: RepaintBoundary(
                key: box,
                child: SvgPicture.asset('assets/art/languages/$file.svg', width: 240, height: 300),
              ),
            ),
          ),
        );
        await tester.pump(const Duration(seconds: 1));
        final RenderRepaintBoundary b = tester.renderObject<RenderRepaintBoundary>(find.byKey(box));
        final ByteData data = (await tester.runAsync(() async {
          final ui.Image image = await b.toImage();
          return (await image.toByteData())!;
        }))!;
        int blue = 0;
        for (int y = 297; y < 300; y++) {
          for (int x = 0; x < 240; x++) {
            final int i = (y * 240 + x) * 4;
            final int r = data.getUint8(i),
                g = data.getUint8(i + 1),
                bl = data.getUint8(i + 2),
                a = data.getUint8(i + 3);
            if (a > 200 && bl > r + 70 && bl > g + 40) blue++;
          }
        }
        expect(blue, 0, reason: 'blue tail pixels on the last three rows of the picture: $blue');
      },
    );
  }

  // QA-L0-4. For a child with a language on, the first frame of the map is the 7-land map: `languagesOnProvider` is first read when
  // the map is built and answers "none" until the family's settings are read, so the scene (and the scroll key) swap one frame
  // later. The map should wait for the settings, as it waits for the friend and the guide (`CalmLoading`).
  testWidgets('QA-L0-4: no frame of the map shows the 7-land scene to a child who has a language on', (
    WidgetTester tester,
  ) async {
    final AppRig rig = AppRig()..installedLanguages = <String>['eng'];
    await rig.seedFinishedSetup(id: kid);
    final FamilyLanguages f = const FamilyLanguages().withSwitches(
      kid,
      'eng',
      const LanguageSwitches(on: true),
    )!;
    await rig.db.putSetting(languagesSettingKey, f.encode());
    await rig.pump(tester);
    await tester.tap(find.text('נועה'));
    final List<String> frames = <String>[];
    for (int i = 0; i < 30; i++) {
      await tester.pump(const Duration(milliseconds: 16));
      if (find.byType(HomeScreen).evaluate().isEmpty) continue;
      frames.add(
        find.byKey(const PageStorageKey<String>('home-map')).evaluate().isNotEmpty ? '7-land' : '8-land',
      );
    }
    expect(frames, isNotEmpty);
    expect(frames.toSet(), <String>{'8-land'}, reason: 'the frames of the map: $frames');
  });
}
