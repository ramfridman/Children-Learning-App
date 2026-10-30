import 'dart:io';
import 'dart:typed_data';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../content/content_repository.dart';
import '../content/models.dart';
import '../content/pack_installer.dart';
import '../content/pack_verify.dart';
import '../core/platform_service.dart';
import '../data/app_database.dart';
import '../data/encrypted_storage.dart';
import '../security/parent_gate.dart';
import '../security/parent_session.dart';
import '../play/lesson_controller.dart';
import '../security/pin_service.dart';
import 'providers.dart';

final Provider<PlatformService> platformProvider = Provider<PlatformService>(
  (Ref ref) => AndroidPlatformService(),
);

/// The encrypted local database. Opened once; the key comes from secure storage.
final FutureProvider<AppDatabase> databaseProvider = FutureProvider<AppDatabase>((Ref ref) async {
  final String folder = await ref.watch(platformProvider).noBackupDir();
  final String key = await DatabaseKeyService(ref.watch(secureStoreProvider)).keyHex();
  final AppDatabase db = openAppDatabase(folder: folder, keyHex: key);
  ref.onDispose(db.close);
  return db;
});

/// Security events (wrong PIN, gate failures) are written to the local database, with fixed words only.
Future<void> Function(String, String) _eventSink(Ref ref) =>
    (String kind, String detail) async =>
        (await ref.read(databaseProvider.future)).recordEvent(kind, DateTime.now(), detail: detail);

final Provider<PinService> pinServiceProvider = Provider<PinService>(
  (Ref ref) => PinService(
    store: ref.watch(secureStoreProvider),
    clock: ref.watch(clockProvider),
    platform: ref.watch(platformProvider),
    onEvent: _eventSink(ref),
  ),
);

final Provider<ParentGate> parentGateProvider = Provider<ParentGate>(
  (Ref ref) => ParentGate(
    store: ref.watch(secureStoreProvider),
    clock: ref.watch(clockProvider),
    onEvent: _eventSink(ref),
  ),
);

final Provider<ParentSession> parentSessionProvider = Provider<ParentSession>((Ref ref) {
  final ParentSession session = ParentSession(platform: ref.watch(platformProvider));
  ref.onDispose(session.dispose);
  return session;
});

/// What the app needs to know to choose its first screen.
class AppState {
  const AppState({required this.profiles, required this.pinSet, required this.enrolled});

  final List<Profile> profiles;
  final bool pinSet;
  final bool enrolled;

  /// Setup is finished when the device is registered, the PIN exists and one child exists. The PIN
  /// always comes before the first child profile.
  bool get setupDone => enrolled && pinSet && profiles.isNotEmpty;
}

class AppStateNotifier extends AsyncNotifier<AppState> {
  @override
  Future<AppState> build() async {
    final AppDatabase db = await ref.watch(databaseProvider.future);
    try {
      // At the start: alerts past 30 days go, and the words go if "keep the words" is off (SEC-28).
      await db.tidyAlerts(DateTime.fromMillisecondsSinceEpoch(ref.read(clockProvider).nowMs()));
    } on Object {
      // Never a reason for the app not to start; the next sync tidies again.
    }
    return AppState(
      profiles: await db.allProfiles(),
      pinSet: await ref.read(pinServiceProvider).isSet(),
      enrolled: await ref.read(enrolmentProvider).enrolledDeviceId() != null,
    );
  }

  Future<void> reload() async {
    ref.invalidateSelf();
    await future;
  }
}

final AsyncNotifierProvider<AppStateNotifier, AppState> appStateProvider =
    AsyncNotifierProvider<AppStateNotifier, AppState>(AppStateNotifier.new);

/// The child who is playing now; null on the picker.
class ActiveProfile extends Notifier<Profile?> {
  @override
  Profile? build() => null;

  void choose(Profile? p) => state = p;
}

final NotifierProvider<ActiveProfile, Profile?> activeProfileProvider =
    NotifierProvider<ActiveProfile, Profile?>(ActiveProfile.new);

/// The installer of content packs: its folder is `packs/` in the no-backup area, and it trusts only
/// the public key built into the app.
final FutureProvider<PackInstaller> packInstallerProvider = FutureProvider<PackInstaller>((Ref ref) async {
  final String folder = await ref.watch(platformProvider).noBackupDir();
  final AppDatabase db = await ref.watch(databaseProvider.future);
  final Uint8List key = unhex(await rootBundle.loadString('assets/pack_signing_public_key.txt'));
  return PackInstaller(
    root: Directory('$folder${Platform.pathSeparator}packs'),
    registry: DbPackRegistry(db),
    publicKey: key,
    clock: ref.watch(clockProvider),
  );
});

/// The lessons: the pack that ships in the app, installed through the same checks as any pack (signature
/// against the built-in key, every hash) and read back from disk before use.
final FutureProvider<PackContent> contentProvider = FutureProvider<PackContent>((Ref ref) async {
  final PackInstaller installer = await ref.watch(packInstallerProvider.future);
  return ContentRepository(
    installer: installer,
    bundled: () async => (await rootBundle.load('assets/packs/starter-0.10.0.nnpack')).buffer.asUint8List(),
  ).starter();
});

/// Where each answer a child gives is written: the `attempt` table of the local database.
final Provider<AttemptSink> attemptSinkProvider = Provider<AttemptSink>((Ref ref) {
  return (AttemptRecord r) async {
    final AppDatabase db = await ref.read(databaseProvider.future);
    await db.recordAttempt(
      AttemptsCompanion.insert(
        at: r.at,
        profileId: r.profileId,
        packId: r.packId,
        packVersion: r.packVersion,
        lessonId: Value<String>(r.lessonId),
        activityId: r.activityId,
        activityRevision: r.activityRevision,
        template: r.template,
        templateVersion: r.templateVersion,
        skillId: r.skillId,
        result: r.result,
        attemptNo: r.attemptNo,
        hintLevel: r.hintLevel,
        misconceptionTag: Value<String>(r.misconceptionTag),
        response: Value<String>(r.response),
        durationMs: Value<int>(r.durationMs),
        sessionId: Value<int?>(r.sessionId),
        input: Value<String>(r.input),
      ),
    );
  };
});

/// Starts and ends the rows of the `session` table (a visit: a lesson or, later, a planned session).
class SessionRecorder {
  const SessionRecorder(this._ref);

  final Ref _ref;

  Future<int> start(String profileId, String plan) async {
    final AppDatabase db = await _ref.read(databaseProvider.future);
    return db.startSession(
      profileId,
      DateTime.fromMillisecondsSinceEpoch(_ref.read(clockProvider).nowMs(), isUtc: true),
      plan: plan,
    );
  }

  Future<void> end(int id, String reason) async {
    final AppDatabase db = await _ref.read(databaseProvider.future);
    await db.endSession(
      id,
      DateTime.fromMillisecondsSinceEpoch(_ref.read(clockProvider).nowMs(), isUtc: true),
      reason,
    );
  }
}

final Provider<SessionRecorder> sessionRecorderProvider = Provider<SessionRecorder>(SessionRecorder.new);
