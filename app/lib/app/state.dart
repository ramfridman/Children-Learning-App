import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/platform_service.dart';
import '../data/app_database.dart';
import '../data/encrypted_storage.dart';
import '../security/parent_gate.dart';
import '../security/parent_session.dart';
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
