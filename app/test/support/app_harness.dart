import 'dart:async';
import 'dart:math';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/parent/parent_rules.dart';
import 'package:nitznutz/app/app.dart';
import 'package:nitznutz/app/companion.dart';
import 'package:nitznutz/app/sync_providers.dart';
import 'package:nitznutz/app/tutor_providers.dart';
import 'package:nitznutz/app/voice_input.dart';
import 'package:nitznutz/tutor/tutor.dart';
import 'package:nitznutz/characters/character_source.dart';
import 'package:nitznutz/content/models.dart';
import 'package:nitznutz/play/lesson_screen.dart';
import 'package:nitznutz/app/providers.dart';
import 'package:nitznutz/app/state.dart';
import 'package:nitznutz/core/errors.dart';
import 'package:nitznutz/data/app_database.dart';
import 'package:nitznutz/device/secure_store.dart';
import 'package:nitznutz/parent/backends.dart';
import 'package:nitznutz/parent/keypad.dart';
import 'package:nitznutz/security/parent_gate.dart';
import 'package:nitznutz/security/pin_service.dart';

import 'companion_fixtures.dart';
import 'fake_speech.dart';
import 'fakes.dart';
import 'security_fakes.dart';
import 'voice_fixtures.dart';
import 'starter.dart';

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
  AppRig({
    this.dev = false,
    int gateSeed = 7,
    this.characters,
    FakePlayer? player,
    this.voice = false,
    FakeSpeechEngine? speech,
    this.tutor,
    this.aiHelper = true,
    this.tutorEnabledOnServer = true,
    this.switchAnswersAfter = Duration.zero,
    this.holdCharacters,
    this.rules,
    this.extraOverrides = const <Override>[],
    int? clockMs,
  }) : player = player ?? FakePlayer(),
       speech = speech ?? FakeSpeechEngine(),
       store = MemoryStore(),
       platform = FakePlatform(),
       clock = ControlledClock(clockMs ?? 1793000000000),
       db = AppDatabase(NativeDatabase.memory()) {
    setup = FakeSetupBackend(store);
    gateQuestion = ParentGate(store: MemoryStore(), clock: clock, random: Random(gateSeed)).newQuestion();
    this.gateSeed = gateSeed;
  }

  final bool dev;

  /// The characters and voices of the test; Nitzi alone, with a voice, when not given.
  final CharacterSource? characters;

  /// The sound device: it records what was played instead of playing it.
  final FakePlayer player;

  /// A parent has turned "Voice answers" on, and the recogniser is a fake that answers from a script.
  final bool voice;
  final FakeSpeechEngine speech;

  /// The AI tutor service of the test (a fake), whether the helper is switched on in this phone, and the server switch.
  final TutorClient? tutor;
  final bool aiHelper;
  final bool tutorEnabledOnServer;

  /// The parent's time rules to start with (the app's defaults when null).
  final ParentRules? rules;

  /// More provider overrides for one test (a sync test gives its own engine here); they come last and win.
  final List<Override> extraOverrides;

  /// How long the server takes to answer the helper switch (the first call after the function slept).
  final Duration switchAnswersAfter;

  /// While set and not completed, the characters take their time to load (a slow phone with many packs).
  final Completer<void>? holdCharacters;
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
    bool warmUp = false,
  }) async {
    // The warm-up game (M9) is off in the tests that are about something else; its own tests turn it on.
    await db.putSetting('warm_up', warmUp ? 'on' : 'off');
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
    contentProvider.overrideWith((Ref ref) => loadStarter()),
    characterSourceProvider.overrideWith((Ref ref) async {
      if (holdCharacters != null) await holdCharacters!.future;
      return characters ?? await makeSource();
    }),
    voicePlayerProvider.overrideWithValue(player),
    speechEngineProvider.overrideWithValue(speech),
    if (tutor != null) tutorClientProvider.overrideWithValue(tutor!),
    // Nothing reaches for the network behind a test's back; sync tests give their own engine.
    syncEnabledProvider.overrideWithValue(false),
    remoteSwitchesProvider.overrideWithValue(
      RemoteSwitches(() async {
        if (switchAnswersAfter > Duration.zero) await Future<void>.delayed(switchAnswersAfter);
        return tutorEnabledOnServer;
      }, () => 0),
    ),
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
    ...extraOverrides,
  ];

  Future<void> pump(WidgetTester tester, {Size size = const Size(852, 393), bool reduceMotion = true}) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    addTearDown(db.close);
    // The characters breathe for ever; with "reduce motion" on they stand still, so the screens can settle.
    // How they move is tested on its own (character_view_test.dart).
    if (reduceMotion) {
      tester.platformDispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(
        disableAnimations: true,
      );
      addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    }
    if (voice) await db.putSetting('voice_enabled', 'on');
    if (rules != null) await db.putSetting('parent_rules', rules!.encode());
    if (tutor != null && aiHelper) await db.putSetting('ai_helper', 'on');
    await tester.pumpWidget(ProviderScope(overrides: overrides, child: const NitznutzApp()));
    await tester.pumpAndSettle();
  }
}

/// Opens a lesson of just the activities [ids] of the starter pack for the child 'p-1', the way a revisit mission is
/// opened (no map, any activity). The child must already be chosen; pump afterwards to let the lesson start.
Future<void> openActivities(WidgetTester tester, List<String> ids) async {
  final PackContent content = await loadStarter();
  final Lesson lesson = Lesson.mission(
    id: 'test',
    itemIds: ids,
    skillIds: <String>{
      for (final String id in ids)
        for (final Skill s in content.activities[id]!.skills) s.id,
    }.toList(),
    celebration: content.lessons['butterflies']!.celebration,
  );
  unawaited(
    tester
        .state<NavigatorState>(find.byType(Navigator).first)
        .push(
          MaterialPageRoute<void>(
            builder: (BuildContext c) => LessonScreen(profileId: 'p-1', mission: lesson),
          ),
        ),
  );
}

/// Types [digits] on the on-screen keypad, one tap per digit.
Future<void> tapDigits(WidgetTester tester, String digits) async {
  for (final String d in digits.split('')) {
    await tester.tap(find.descendant(of: find.byType(ParentKeypad), matching: find.text(d)));
    await tester.pump();
  }
}
