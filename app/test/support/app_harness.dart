import 'dart:math';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/app/app.dart';
import 'package:nitznutz/app/providers.dart';
import 'package:nitznutz/app/state.dart';
import 'package:nitznutz/core/errors.dart';
import 'package:nitznutz/data/app_database.dart';
import 'package:nitznutz/device/secure_store.dart';
import 'package:nitznutz/parent/backends.dart';
import 'package:nitznutz/parent/keypad.dart';
import 'package:nitznutz/security/parent_gate.dart';
import 'package:nitznutz/security/pin_service.dart';

import 'fakes.dart';
import 'security_fakes.dart';

const String testPin = '4831';
const String testEmailCode = '123456';

/// A fake for the network side of setup: the right code is [testEmailCode], enrolling stores a
/// device id exactly like the real service.
class FakeSetupBackend implements SetupBackend {
  FakeSetupBackend(this.store);

  final MemoryStore store;
  final List<String> calls = <String>[];
  bool signedIn = false;

  @override
  Future<void> sendCode(String email) async => calls.add('send $email');

  @override
  Future<void> verifyCode(String email, String code) async {
    calls.add('verify');
    if (code != testEmailCode) throw const GatewayException('auth_failed', status: 400);
    signedIn = true;
  }

  @override
  Future<bool> hasSession() async => signedIn;

  @override
  Future<bool> isEnrolled() async => (await store.read(StoreKeys.deviceId)) != null;

  @override
  Future<void> enrol() async {
    calls.add('enrol');
    await store.write(StoreKeys.deviceId, 'enrolled-test-device');
    await store.write(StoreKeys.role, 'parent');
  }
}

class FakeDevicesBackend implements DevicesBackend {
  List<DeviceInfo> devices = const <DeviceInfo>[
    DeviceInfo(id: 'aaaa', role: 'parent', thisDevice: true, platform: 'android'),
    DeviceInfo(id: 'bbbb', role: 'parent', thisDevice: false, platform: 'android'),
  ];
  final List<String> revoked = <String>[];
  bool offline = false;

  @override
  Future<List<DeviceInfo>> list() async {
    if (offline) throw const GatewayException('network');
    return devices;
  }

  @override
  Future<void> revoke(String deviceId) async {
    revoked.add(deviceId);
    devices = devices.where((DeviceInfo d) => d.id != deviceId).toList();
  }
}

/// Everything a test needs to drive the whole app with no network and no hardware.
class AppRig {
  AppRig({this.dev = false, int gateSeed = 7})
    : store = MemoryStore(),
      platform = FakePlatform(),
      clock = ControlledClock(1793000000000),
      db = AppDatabase(NativeDatabase.memory()) {
    setup = FakeSetupBackend(store);
    gateQuestion = ParentGate(store: MemoryStore(), clock: clock, random: Random(gateSeed)).newQuestion();
    this.gateSeed = gateSeed;
  }

  final bool dev;
  final MemoryStore store;
  final FakePlatform platform;
  final ControlledClock clock;
  final AppDatabase db;
  final FakeDevicesBackend devices = FakeDevicesBackend();
  late final FakeSetupBackend setup;
  late final GateQuestion gateQuestion;
  late final int gateSeed;

  /// Marks setup as already done: device registered, PIN chosen, and one child.
  Future<void> seedFinishedSetup({
    String name = 'נועה',
    int ageBand = 1,
    String avatar = 'avatar-noa',
  }) async {
    await store.write(StoreKeys.deviceId, 'aaaa');
    await store.write(StoreKeys.role, 'parent');
    await PinService(
      store: store,
      clock: clock,
      platform: platform,
      hasher: const FastHasher(),
    ).setPin(testPin);
    await db.addProfile(
      ProfilesCompanion.insert(
        id: 'p-1',
        name: name,
        avatar: avatar,
        addressForm: 'f',
        ageBand: ageBand,
        createdAt: DateTime.utc(2026, 10, 26),
      ),
    );
  }

  List<Override> get overrides => <Override>[
    configProvider.overrideWithValue(testConfig(dev: dev)),
    hostsProvider.overrideWithValue(testHosts()),
    secureStoreProvider.overrideWithValue(store),
    deviceKeysProvider.overrideWithValue(FakeKeys()),
    platformProvider.overrideWithValue(platform),
    clockProvider.overrideWithValue(clock),
    databaseProvider.overrideWith((Ref ref) async => db),
    setupBackendProvider.overrideWithValue(setup),
    devicesBackendProvider.overrideWithValue(devices),
    pinServiceProvider.overrideWith(
      (Ref ref) => PinService(
        store: store,
        clock: clock,
        platform: platform,
        hasher: const FastHasher(),
        onEvent: (String k, String d) => db.recordEvent(k, DateTime.utc(2026, 10, 26), detail: d),
      ),
    ),
    parentGateProvider.overrideWith(
      (Ref ref) => ParentGate(
        store: store,
        clock: clock,
        random: Random(gateSeed),
        onEvent: (String k, String d) => db.recordEvent(k, DateTime.utc(2026, 10, 26), detail: d),
      ),
    ),
  ];

  Future<void> pump(WidgetTester tester, {Size size = const Size(852, 393)}) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    addTearDown(db.close);
    await tester.pumpWidget(ProviderScope(overrides: overrides, child: const NitznutzApp()));
    await tester.pumpAndSettle();
  }
}

/// Types [digits] on the on-screen keypad, one tap per digit.
Future<void> tapDigits(WidgetTester tester, String digits) async {
  for (final String d in digits.split('')) {
    await tester.tap(find.descendant(of: find.byType(ParentKeypad), matching: find.text(d)));
    await tester.pump();
  }
}
