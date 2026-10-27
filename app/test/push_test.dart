// Alerts on a parent's phone: the switch in the parent area (permission, the address given to the server, off again), and
// what the app does with the push service while it is open (renew the address, sync on a message, open the gate on a tap).
import 'dart:async';

import 'package:flutter/material.dart' show Key, Scrollable, Switch;
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/app/push_providers.dart';
import 'package:nitznutz/parent/gate_screen.dart';
import 'package:nitznutz/push/push_backend.dart';
import 'package:nitznutz/strings/he.dart';

import 'support/app_harness.dart';
import 'support/harness.dart';

class FakePush implements PushBackend {
  PushStart startResult = PushStart.ready;
  String? address = 'token-aaaaaaaaaaaaaaaaaaaa';
  bool launchedByTap = false;
  final List<bool> startedAsking = <bool>[];
  int stops = 0;
  final StreamController<String> refreshes = StreamController<String>.broadcast();
  final StreamController<void> messages = StreamController<void>.broadcast();
  final StreamController<void> taps = StreamController<void>.broadcast();

  @override
  Future<PushStart> start({required bool askPermission}) async {
    startedAsking.add(askPermission);
    return startResult;
  }

  @override
  Future<String?> token() async => address;

  @override
  Stream<String> get tokenRefreshed => refreshes.stream;

  @override
  Stream<void> get arrived => messages.stream;

  @override
  Stream<void> get opened => taps.stream;

  @override
  Future<bool> startedByNotification() async => launchedByTap;

  @override
  Future<void> stop() async => stops++;
}

class Server {
  final List<String> registered = <String>[];
  int removals = 0;
  bool offline = false;

  List<Override> overrides(FakePush push) => <Override>[
    pushBackendProvider.overrideWithValue(push),
    pushRegistrarProvider.overrideWithValue((String t) async {
      if (offline) throw StateError('offline');
      registered.add(t);
    }),
    pushRemoverProvider.overrideWithValue(() async {
      if (offline) throw StateError('offline');
      removals++;
    }),
  ];
}

Future<void> openArea(WidgetTester tester, AppRig rig) async {
  await tester.tap(find.text('נועה'));
  await tester.pumpAndSettle();
  await tester.tap(find.text(He.homeParents.text));
  await tester.pumpAndSettle();
  await tapDigits(tester, '${rig.gateQuestion.answer}');
  await tester.tap(find.text(He.pinOk.text));
  await tester.pumpAndSettle();
  await tapDigits(tester, testPin);
  await tester.tap(find.text(He.pinOk.text));
  await tester.pumpAndSettle();
}

Future<void> flip(WidgetTester tester) async {
  final Finder sw = find.byKey(const Key('push-switch'));
  await tester.scrollUntilVisible(sw, 200, scrollable: find.byType(Scrollable).first);
  await tester.tap(sw);
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(loadAppFonts);

  group('the switch', () {
    testWidgets('on: asks permission, gives the server this address, and stays on', (
      WidgetTester tester,
    ) async {
      final FakePush push = FakePush();
      final Server server = Server();
      final AppRig rig = AppRig(extraOverrides: server.overrides(push));
      await rig.seedFinishedSetup();
      await rig.pump(tester);
      await openArea(tester, rig);
      await flip(tester);
      expect(push.startedAsking, <bool>[true], reason: 'the permission is asked when the parent turns it on');
      expect(server.registered, <String>['token-aaaaaaaaaaaaaaaaaaaa']);
      expect(await rig.db.setting('push_on'), 'on');
      expect(tester.widget<Switch>(find.byKey(const Key('push-switch'))).value, isTrue);
    });

    testWidgets('permission refused: says so, tells the server nothing, stays off', (
      WidgetTester tester,
    ) async {
      final FakePush push = FakePush()..startResult = PushStart.denied;
      final Server server = Server();
      final AppRig rig = AppRig(extraOverrides: server.overrides(push));
      await rig.seedFinishedSetup();
      await rig.pump(tester);
      await openArea(tester, rig);
      await flip(tester);
      expect(find.text(He.areaPushDenied.text), findsOneWidget);
      expect(server.registered, isEmpty);
      expect(await rig.db.setting('push_on'), isNull);
      expect(tester.widget<Switch>(find.byKey(const Key('push-switch'))).value, isFalse);
    });

    testWidgets(
      'a build without push, or a server that cannot be reached, leaves it off with a calm sentence',
      (WidgetTester tester) async {
        final FakePush push = FakePush()..startResult = PushStart.unavailable;
        final Server server = Server();
        final AppRig rig = AppRig(extraOverrides: server.overrides(push));
        await rig.seedFinishedSetup();
        await rig.pump(tester);
        await openArea(tester, rig);
        await flip(tester);
        expect(find.text(He.areaPushUnavailable.text), findsOneWidget);
        push.startResult = PushStart.ready;
        server.offline = true;
        await flip(tester);
        expect(find.text(He.areaPushFailed.text), findsOneWidget);
        expect(
          await rig.db.setting('push_on'),
          isNull,
          reason: 'it is on only when the server has the address',
        );
      },
    );

    testWidgets('off: takes the phone off the server list and the push service', (WidgetTester tester) async {
      final FakePush push = FakePush();
      final Server server = Server();
      final AppRig rig = AppRig(extraOverrides: server.overrides(push));
      await rig.seedFinishedSetup();
      await rig.db.putSetting('push_on', 'on');
      await rig.pump(tester);
      await openArea(tester, rig);
      await flip(tester);
      expect(server.removals, 1);
      expect(push.stops, 1);
      expect(await rig.db.setting('push_on'), 'off');
    });
  });

  group('while the app is open', () {
    Future<(AppRig, FakePush, Server)> started(
      WidgetTester tester, {
      bool on = true,
      bool launchedByTap = false,
    }) async {
      final FakePush push = FakePush()..launchedByTap = launchedByTap;
      final Server server = Server();
      final AppRig rig = AppRig(extraOverrides: server.overrides(push));
      await rig.seedFinishedSetup();
      if (on) await rig.db.putSetting('push_on', 'on');
      await rig.pump(tester);
      await tester.pumpAndSettle();
      return (rig, push, server);
    }

    testWidgets(
      'it starts without asking, registers the address, and renews it when the service changes it',
      (WidgetTester tester) async {
        final (AppRig _, FakePush push, Server server) = await started(tester);
        expect(push.startedAsking, <bool>[false], reason: 'never a question at app start');
        expect(server.registered, <String>['token-aaaaaaaaaaaaaaaaaaaa']);
        push.refreshes.add('token-bbbbbbbbbbbbbbbbbbbb');
        await tester.pump();
        expect(server.registered.last, 'token-bbbbbbbbbbbbbbbbbbbb');
      },
    );

    testWidgets('a tap on the notification opens the parent gate, and nothing opens by itself', (
      WidgetTester tester,
    ) async {
      final (AppRig _, FakePush push, Server _) = await started(tester);
      expect(find.byType(GateScreen), findsNothing);
      push.messages.add(null);
      await tester.pumpAndSettle();
      expect(find.byType(GateScreen), findsNothing, reason: 'a message while the app is open opens nothing');
      push.taps.add(null);
      await tester.pumpAndSettle();
      expect(find.byType(GateScreen), findsOneWidget);
    });

    testWidgets('starting the app from the notification opens the gate', (WidgetTester tester) async {
      await started(tester, launchedByTap: true);
      expect(find.byType(GateScreen), findsOneWidget);
    });

    testWidgets('with the switch off the push service is never started', (WidgetTester tester) async {
      final (AppRig _, FakePush push, Server server) = await started(tester, on: false);
      expect(push.startedAsking, isEmpty);
      expect(server.registered, isEmpty);
    });
  });
}
