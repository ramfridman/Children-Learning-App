import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/play/activity_frame.dart';
import 'package:nitznutz/child/home_screen.dart';
import 'package:nitznutz/child/profile_picker.dart';
import 'package:nitznutz/data/app_database.dart';
import 'package:nitznutz/design/components.dart';
import 'package:nitznutz/parent/gate_screen.dart';
import 'package:nitznutz/parent/parent_area.dart';
import 'package:nitznutz/parent/pin_screens.dart';
import 'package:nitznutz/parent/setup_flow.dart';
import 'package:nitznutz/strings/he.dart';

import 'support/app_harness.dart';
import 'support/fake_speech.dart';
import 'support/harness.dart';
import 'support/starter.dart';

Future<void> _enterGate(WidgetTester tester, AppRig rig) async {
  expect(find.byType(GateScreen), findsOneWidget);
  expect(find.text(rig.gateQuestion.hebrew), findsOneWidget, reason: 'the question is shown in Hebrew words');
  await tapDigits(tester, '${rig.gateQuestion.answer}');
  await tester.tap(find.text(He.pinOk.text));
  await tester.pumpAndSettle();
}

Future<void> _openAreaFromHome(WidgetTester tester, AppRig rig) async {
  await tester.tap(find.text(He.homeParents.text));
  await tester.pumpAndSettle();
  await _enterGate(tester, rig);
  expect(find.byType(PinEntryScreen), findsOneWidget);
  await tapDigits(tester, testPin);
  await tester.tap(find.text(He.pinOk.text));
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(loadAppFonts);

  group('first run', () {
    testWidgets('setup: sign in, register the device, choose the PIN, then add the first child', (
      WidgetTester tester,
    ) async {
      final AppRig rig = AppRig();
      await rig.pump(tester);
      expect(find.byType(SetupFlow), findsOneWidget);

      await tester.tap(find.text(He.setupStart.text));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'parent@example.com');
      await tester.tap(find.text(He.setupSendCode.text));
      await tester.pumpAndSettle();
      expect(rig.setup.calls, contains('send parent@example.com'));
      expect(find.text(He.setupCodeSent.text), findsOneWidget);

      await tester.enterText(find.byType(TextField).last, '000000');
      await tester.tap(find.text(He.setupVerify.text));
      await tester.pumpAndSettle();
      expect(find.text(He.setupWrongCode.text), findsOneWidget, reason: 'a wrong code says so and stays');

      await tester.enterText(find.byType(TextField).last, testEmailCode);
      await tester.tap(find.text(He.setupVerify.text));
      await tester.pumpAndSettle();
      expect(find.text(He.setupEnrolBody.text), findsOneWidget);

      await tester.tap(find.text(He.setupEnrolButton.text).last);
      await tester.pumpAndSettle();
      expect(rig.setup.calls, contains('enrol'));

      // The PIN comes first: no child form until it is set.
      expect(find.byType(PinSetupScreen), findsOneWidget);
      expect(find.text(He.setupChildTitle.text), findsNothing);
      await tapDigits(tester, testPin);
      await tester.tap(find.text(He.pinOk.text));
      await tester.pumpAndSettle();
      expect(find.text(He.pinConfirm.text), findsOneWidget);
      await tapDigits(tester, '1111');
      await tester.tap(find.text(He.pinOk.text));
      await tester.pumpAndSettle();
      expect(find.text(He.pinMismatch.text), findsOneWidget, reason: 'two different PINs are refused');

      await tapDigits(tester, testPin);
      await tester.tap(find.text(He.pinOk.text));
      await tester.pumpAndSettle();
      await tapDigits(tester, testPin);
      await tester.tap(find.text(He.pinOk.text));
      await tester.pumpAndSettle();
      expect(find.text(He.setupChildTitle.text), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'נועה');
      await tester.pump();
      await tester.tap(find.text(He.setupSave.text));
      await tester.pumpAndSettle();

      expect(find.byType(ProfilePicker), findsOneWidget);
      expect(find.text('נועה'), findsOneWidget);
      final List<Profile> saved = await rig.db.allProfiles();
      expect(saved.single.name, 'נועה');
      expect(saved.single.ageBand, 1, reason: 'age 5 is band B');
    });

    testWidgets('an interrupted setup resumes at the PIN, not at the start', (WidgetTester tester) async {
      final AppRig rig = AppRig();
      await rig.store.write('device_id', 'aaaa');
      await rig.store.write('device_role', 'parent');
      await rig.pump(tester);
      expect(find.byType(PinSetupScreen), findsOneWidget);
    });

    testWidgets('a finished setup goes straight to the picker', (WidgetTester tester) async {
      final AppRig rig = AppRig();
      await rig.seedFinishedSetup();
      await rig.pump(tester);
      expect(find.byType(ProfilePicker), findsOneWidget);
      expect(find.byType(SetupFlow), findsNothing);
    });
  });

  group('the child space', () {
    testWidgets('pick a child, see the home with their name, switch back', (WidgetTester tester) async {
      final AppRig rig = AppRig();
      await rig.seedFinishedSetup();
      await rig.pump(tester);

      await tester.tap(find.text('נועה'));
      await tester.pumpAndSettle();
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.text(He.homeBubble.fill(<String, String>{'child': 'נועה'})), findsOneWidget);
      expect(find.text(He.homeParents.text), findsOneWidget);

      await tester.tap(find.bySemanticsLabel(He.switchChildSemantics.text));
      await tester.pumpAndSettle();
      expect(find.byType(ProfilePicker), findsOneWidget);
    });

    testWidgets('the counting hills open the activity frame, and its home button comes back', (
      WidgetTester tester,
    ) async {
      final AppRig rig = AppRig();
      await rig.seedFinishedSetup();
      await rig.pump(tester);
      await tester.tap(find.text('נועה'));
      await tester.pumpAndSettle();

      await tester.tap(find.text(He.landCounting.text));
      await tester.pumpAndSettle();
      expect(find.byType(ActivityFrame), findsOneWidget);
      expect(
        find.text((await loadStarter()).activities['pick.red.flower']!.promptLine.caption),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const Key('activity-home')));
      await tester.pumpAndSettle();
      expect(find.byType(HomeScreen), findsOneWidget);
    });

    testWidgets('a child cannot add a profile: the plus card only leads to the gate', (
      WidgetTester tester,
    ) async {
      final AppRig rig = AppRig();
      await rig.seedFinishedSetup();
      await rig.pump(tester);
      await tester.tap(find.byKey(const Key('picker-add')));
      await tester.pumpAndSettle();
      expect(find.byType(GateScreen), findsOneWidget);
      expect((await rig.db.allProfiles()).length, 1);
    });
  });

  group('the way into the parent area', () {
    testWidgets(
      'gate, then PIN, then the area; the screen is secure while it is open; locking returns to the child',
      (WidgetTester tester) async {
        final AppRig rig = AppRig();
        await rig.seedFinishedSetup();
        await rig.pump(tester);
        await tester.tap(find.text('נועה'));
        await tester.pumpAndSettle();

        await _openAreaFromHome(tester, rig);
        expect(find.byType(ParentArea), findsOneWidget);
        expect(rig.platform.secure, isTrue);

        await tester.tap(find.byTooltip(He.areaLockNow.text));
        await tester.pumpAndSettle();
        expect(find.byType(HomeScreen), findsOneWidget);
        expect(find.byType(ParentArea), findsNothing);
        expect(rig.platform.secure, isFalse);
      },
    );

    testWidgets('a wrong gate answer gives a new question and nothing opens', (WidgetTester tester) async {
      final AppRig rig = AppRig();
      await rig.seedFinishedSetup();
      await rig.pump(tester);
      await tester.tap(find.text('נועה'));
      await tester.pumpAndSettle();
      await tester.tap(find.text(He.homeParents.text));
      await tester.pumpAndSettle();

      await tapDigits(tester, '${rig.gateQuestion.answer + 1}');
      await tester.tap(find.text(He.pinOk.text));
      await tester.pumpAndSettle();
      expect(find.text(He.gateWrong.text), findsOneWidget);
      expect(find.byType(PinEntryScreen), findsNothing);
      expect(find.byType(ParentArea), findsNothing);
    });

    testWidgets('a wrong PIN is refused, and five wrong PINs lock the keypad with a countdown', (
      WidgetTester tester,
    ) async {
      final AppRig rig = AppRig();
      await rig.seedFinishedSetup();
      await rig.pump(tester);
      await tester.tap(find.text('נועה'));
      await tester.pumpAndSettle();
      await tester.tap(find.text(He.homeParents.text));
      await tester.pumpAndSettle();
      await _enterGate(tester, rig);

      for (int i = 0; i < 5; i++) {
        await tapDigits(tester, '1111');
        await tester.tap(find.text(He.pinOk.text));
        await tester.pumpAndSettle();
      }
      expect(find.byType(ParentArea), findsNothing);
      expect(find.textContaining('30'), findsWidgets, reason: 'the 30 second lock is shown');
      expect(
        tester.widget<ParentButton>(find.widgetWithText(ParentButton, He.pinOk.text)).onPressed,
        isNull,
        reason: 'the OK button is off while locked',
      );
      // Even the right PIN does nothing during the lock.
      await tapDigits(tester, testPin);
      await tester.pump();
      expect(find.byType(ParentArea), findsNothing);
      // Let the lock-out run out so no timer is left behind.
      rig.platform.advance(const Duration(seconds: 31));
      await tester.pump(const Duration(seconds: 40));
    });

    testWidgets('the area closes by itself after 5 idle minutes', (WidgetTester tester) async {
      final AppRig rig = AppRig();
      await rig.seedFinishedSetup();
      await rig.pump(tester);
      await tester.tap(find.text('נועה'));
      await tester.pumpAndSettle();
      await _openAreaFromHome(tester, rig);
      expect(find.byType(ParentArea), findsOneWidget);

      await tester.pump(const Duration(minutes: 5, seconds: 1));
      await tester.pumpAndSettle();
      expect(find.byType(ParentArea), findsNothing);
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(rig.platform.secure, isFalse);
    });

    testWidgets('the area closes the moment the app goes to the background', (WidgetTester tester) async {
      final AppRig rig = AppRig();
      await rig.seedFinishedSetup();
      await rig.pump(tester);
      await tester.tap(find.text('נועה'));
      await tester.pumpAndSettle();
      await _openAreaFromHome(tester, rig);

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pumpAndSettle();
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(find.byType(ParentArea), findsNothing);
      expect(find.byType(HomeScreen), findsOneWidget, reason: 'coming back lands in the child space');
    });

    testWidgets('the system back button locks the area as well', (WidgetTester tester) async {
      final AppRig rig = AppRig();
      await rig.seedFinishedSetup();
      await rig.pump(tester);
      await tester.tap(find.text('נועה'));
      await tester.pumpAndSettle();
      await _openAreaFromHome(tester, rig);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byType(ParentArea), findsNothing);
      expect(rig.platform.secure, isFalse);
    });
  });

  group('inside the parent area', () {
    Future<AppRig> openArea(WidgetTester tester) async {
      final AppRig rig = AppRig();
      await rig.seedFinishedSetup();
      await rig.pump(tester);
      await tester.tap(find.text('נועה'));
      await tester.pumpAndSettle();
      await _openAreaFromHome(tester, rig);
      return rig;
    }

    testWidgets(
      'the voice switch is off, needs the model and the microphone permission, and turns on only with both',
      (WidgetTester tester) async {
        final AppRig rig = AppRig(speech: FakeSpeechEngine()..installed = false);
        await rig.seedFinishedSetup();
        await rig.pump(tester);
        await tester.tap(find.text('נועה'));
        await tester.pumpAndSettle();
        await _openAreaFromHome(tester, rig);
        final Finder sw = find.byKey(const Key('voice-switch'));
        await tester.scrollUntilVisible(sw, 200, scrollable: find.byType(Scrollable).first);
        expect(tester.widget<Switch>(sw).value, isFalse, reason: 'off until a parent turns it on');
        expect(
          find.text(He.areaVoiceCredit.text),
          findsOneWidget,
          reason: 'the credit of the model is shown',
        );

        await tester.tap(sw);
        await tester.pumpAndSettle();
        expect(tester.widget<Switch>(sw).value, isFalse);
        expect(find.text(He.areaVoiceNoModel.text), findsOneWidget);
        expect(await rig.db.setting('voice_enabled'), isNull);

        rig.speech.installed = true;
        rig.speech.permission = false;
        await tester.tap(sw);
        await tester.pumpAndSettle();
        expect(tester.widget<Switch>(sw).value, isFalse);
        expect(find.text(He.areaVoiceNoPermission.text), findsOneWidget);

        rig.speech.permission = true;
        await tester.tap(sw);
        await tester.pumpAndSettle();
        expect(tester.widget<Switch>(sw).value, isTrue);
        expect(find.text(He.areaVoiceNoPermission.text), findsNothing);
        expect(await rig.db.setting('voice_enabled'), 'on');
        expect(rig.speech.listens, 0, reason: 'turning it on never opens the microphone');

        await tester.tap(sw);
        await tester.pumpAndSettle();
        expect(await rig.db.setting('voice_enabled'), 'off');
      },
    );

    testWidgets('lists the family\'s devices and revokes another one after a confirmation', (
      WidgetTester tester,
    ) async {
      final AppRig rig = await openArea(tester);
      expect(find.textContaining(He.areaThisDevice.text), findsOneWidget);
      expect(find.text(He.areaRevoke.text), findsOneWidget, reason: 'this device has no revoke button');

      await tester.tap(find.text(He.areaRevoke.text));
      await tester.pumpAndSettle();
      await tester.tap(find.text(He.confirmNo.text));
      await tester.pumpAndSettle();
      expect(rig.devices.revoked, isEmpty);

      await tester.tap(find.text(He.areaRevoke.text));
      await tester.pumpAndSettle();
      await tester.tap(find.text(He.confirmYes.text));
      await tester.pumpAndSettle();
      expect(rig.devices.revoked, <String>['bbbb']);
      expect(find.text(He.areaRevoke.text), findsNothing);
      await tester.tap(find.byTooltip(He.areaLockNow.text));
      await tester.pumpAndSettle();
    });

    testWidgets('offline, it says so and does not crash', (WidgetTester tester) async {
      final AppRig rig = AppRig();
      rig.devices.offline = true;
      await rig.seedFinishedSetup();
      await rig.pump(tester);
      await tester.tap(find.text('נועה'));
      await tester.pumpAndSettle();
      await _openAreaFromHome(tester, rig);
      expect(find.text(He.areaOffline.text), findsOneWidget);
      await tester.tap(find.byTooltip(He.areaLockNow.text));
      await tester.pumpAndSettle();
    });

    testWidgets('removing a profile asks first, deletes it, and sends the child back to the picker', (
      WidgetTester tester,
    ) async {
      final AppRig rig = await openArea(tester);
      await tester.ensureVisible(find.text(He.areaRemove.text));
      await tester.tap(find.text(He.areaRemove.text));
      await tester.pumpAndSettle();
      expect(find.textContaining('נועה'), findsWidgets);
      await tester.tap(find.text(He.confirmYes.text));
      await tester.pumpAndSettle();
      expect(await rig.db.allProfiles(), isEmpty);
      await tester.tap(find.byTooltip(He.areaLockNow.text));
      await tester.pumpAndSettle();
    });

    testWidgets('the dev page is hidden in the prod flavour', (WidgetTester tester) async {
      final AppRig rig = await openArea(tester);
      await tester.ensureVisible(find.textContaining(He.areaVersion.text));
      await tester.longPress(find.textContaining(He.areaVersion.text));
      await tester.pumpAndSettle();
      expect(find.byType(ParentArea), findsOneWidget);
      expect(find.text('Nitznutz dev harness'), findsNothing);
      await tester.tap(find.byTooltip(He.areaLockNow.text));
      await tester.pumpAndSettle();
      expect(rig.platform.secure, isFalse);
    });
  });

  group('layouts: every screen fits every reference device without overflow', () {
    final List<(String, Size)> devices = <(String, Size)>[
      ('phone 852x393', const Size(852, 393)),
      ('phone SE 667x375', const Size(667, 375)),
      ('tablet landscape 1180x820', const Size(1180, 820)),
      ('tablet portrait 820x1180', const Size(820, 1180)),
    ];
    for (final (String name, Size size) in devices) {
      testWidgets('picker, home, activity frame, gate, PIN and area at $name', (WidgetTester tester) async {
        final AppRig rig = AppRig();
        await rig.seedFinishedSetup(name: 'שִׁירָה-עם-שם-ארוך-מאוד');
        await rig.pump(tester, size: size);
        expect(tester.takeException(), isNull);
        await tester.tap(find.text('שִׁירָה-עם-שם-ארוך-מאוד'));
        await tester.pumpAndSettle();
        expect(find.byType(HomeScreen), findsOneWidget);
        expect(tester.takeException(), isNull);

        await tester.tap(find.text(He.landCounting.text));
        await tester.pumpAndSettle();
        expect(find.byType(ActivityFrame), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.tap(find.byKey(const Key('activity-home')));
        await tester.pumpAndSettle();

        await _openAreaFromHome(tester, rig);
        expect(find.byType(ParentArea), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.tap(find.byTooltip(He.areaLockNow.text));
        await tester.pumpAndSettle();
      });
    }

    testWidgets('phones lock to landscape, tablets follow the device', (WidgetTester tester) async {
      final List<MethodCall> calls = <MethodCall>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (
        MethodCall c,
      ) async {
        calls.add(c);
        return null;
      });
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, null),
      );

      final AppRig phone = AppRig();
      await phone.seedFinishedSetup();
      await phone.pump(tester);
      final String phoneArgs = calls
          .where((MethodCall c) => c.method == 'SystemChrome.setPreferredOrientations')
          .last
          .arguments
          .toString();
      expect(phoneArgs, contains('landscapeLeft'));
      expect(phoneArgs, isNot(contains('portraitUp')));

      calls.clear();
      final AppRig tablet = AppRig();
      await tablet.seedFinishedSetup();
      await tablet.pump(tester, size: const Size(820, 1180));
      final String tabletArgs = calls
          .where((MethodCall c) => c.method == 'SystemChrome.setPreferredOrientations')
          .last
          .arguments
          .toString();
      expect(tabletArgs, contains('portraitUp'));
      expect(tabletArgs, contains('landscapeLeft'));
    });
  });
}
