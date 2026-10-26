// Golden screenshots of the new screens, in right to left with the real fonts. They are compared
// with a tolerance of 3 percent of the pixels, because text rendering differs a little between Windows and Linux.
//
// Regenerate after a deliberate visual change:  flutter test --update-goldens test/golden_screens_test.dart
// The owner compares them with the design boards (see docs/milestones/M1.md, E11).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/child/activity_shell.dart';
import 'package:nitznutz/child/home_screen.dart';
import 'package:nitznutz/child/profile_picker.dart';
import 'package:nitznutz/parent/gate_screen.dart';
import 'package:nitznutz/parent/parent_area.dart';
import 'package:nitznutz/parent/pin_screens.dart';
import 'package:nitznutz/strings/he.dart';

import 'support/app_harness.dart';
import 'support/golden_comparator.dart';
import 'support/harness.dart';

const Size phone = Size(852, 393);
const Size phoneSE = Size(667, 375);
const Size tabletL = Size(1180, 820);
const Size tabletP = Size(820, 1180);

Future<AppRig> _rig(WidgetTester tester, Size size) async {
  final AppRig rig = AppRig();
  await rig.seedFinishedSetup(name: 'נֹעָה');
  await rig.pump(tester, size: size);
  return rig;
}

Future<void> _shot(WidgetTester tester, String name) async {
  await tester.pumpAndSettle();
  await expectLater(find.byType(MaterialApp), matchesGoldenFile('goldens/$name.png'));
}

void main() {
  setUpAll(() async {
    await loadAppFonts();
    useTolerantGoldens(0.03);
  });

  group('child space', () {
    for (final (String n, Size s) in <(String, Size)>[
      ('phone', phone),
      ('phone_se', phoneSE),
      ('tablet_landscape', tabletL),
      ('tablet_portrait', tabletP),
    ]) {
      testWidgets('picker, $n', (WidgetTester tester) async {
        await _rig(tester, s);
        expect(find.byType(ProfilePicker), findsOneWidget);
        await _shot(tester, 'picker_$n');
      });

      testWidgets('home, $n', (WidgetTester tester) async {
        await _rig(tester, s);
        await tester.tap(find.text('נֹעָה'));
        await tester.pumpAndSettle();
        expect(find.byType(HomeScreen), findsOneWidget);
        await _shot(tester, 'home_$n');
      });

      testWidgets('activity frame, $n', (WidgetTester tester) async {
        await _rig(tester, s);
        await tester.tap(find.text('נֹעָה'));
        await tester.pumpAndSettle();
        await tester.tap(find.text(He.landCounting.text));
        await tester.pumpAndSettle();
        expect(find.byType(ActivityShell), findsOneWidget);
        await _shot(tester, 'activity_$n');
      });
    }
  });

  group('parent side', () {
    for (final (String n, Size s) in <(String, Size)>[('phone', phone), ('tablet_portrait', tabletP)]) {
      testWidgets('gate, $n', (WidgetTester tester) async {
        await _rig(tester, s);
        await tester.tap(find.text('נֹעָה'));
        await tester.pumpAndSettle();
        await tester.tap(find.text(He.homeParents.text));
        await tester.pumpAndSettle();
        expect(find.byType(GateScreen), findsOneWidget);
        await _shot(tester, 'gate_$n');
      });

      testWidgets('PIN entry, $n', (WidgetTester tester) async {
        final AppRig rig = await _rig(tester, s);
        await tester.tap(find.text('נֹעָה'));
        await tester.pumpAndSettle();
        await tester.tap(find.text(He.homeParents.text));
        await tester.pumpAndSettle();
        await tapDigits(tester, '${rig.gateQuestion.answer}');
        await tester.tap(find.text(He.pinOk.text));
        await tester.pumpAndSettle();
        await tapDigits(tester, '48');
        expect(find.byType(PinEntryScreen), findsOneWidget);
        await _shot(tester, 'pin_$n');
      });

      testWidgets('parent area, $n', (WidgetTester tester) async {
        final AppRig rig = await _rig(tester, s);
        await tester.tap(find.text('נֹעָה'));
        await tester.pumpAndSettle();
        await tester.tap(find.text(He.homeParents.text));
        await tester.pumpAndSettle();
        await tapDigits(tester, '${rig.gateQuestion.answer}');
        await tester.tap(find.text(He.pinOk.text));
        await tester.pumpAndSettle();
        await tapDigits(tester, testPin);
        await tester.tap(find.text(He.pinOk.text));
        await tester.pumpAndSettle();
        expect(find.byType(ParentArea), findsOneWidget);
        await _shot(tester, 'parent_area_$n');
        await tester.tap(find.byTooltip(He.areaLockNow.text));
        await tester.pumpAndSettle();
      });
    }
  });
}
