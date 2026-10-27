import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/app_database.dart';
import '../device/secure_store.dart';
import '../sync/sync_engine.dart';
import 'alerts_provider.dart';
import 'providers.dart';
import 'rules_providers.dart';
import 'state.dart';
import 'tutor_providers.dart';

/// Tests switch syncing off (nothing may reach for the network behind a test's back) and turn it on with their own
/// engine over a fake server.
final Provider<bool> syncEnabledProvider = Provider<bool>((Ref ref) => true);

/// The engine of this device, or null while the device is not enrolled (there is no family to sync with yet).
final FutureProvider<SyncEngine?> syncEngineProvider = FutureProvider<SyncEngine?>((Ref ref) async {
  if (!ref.watch(syncEnabledProvider)) return null;
  final SecureStore store = ref.watch(secureStoreProvider);
  final String? id = await store.read(StoreKeys.deviceId);
  if (id == null) return null;
  final String? role = await store.read(StoreKeys.role);
  final AppDatabase db = await ref.watch(databaseProvider.future);
  return SyncEngine(
    db: db,
    isParent: role != 'child',
    deviceId: id,
    nowMs: ref.watch(clockProvider).nowMs,
    call: (String name, Map<String, Object?> body) async {
      final String? token = await ref.read(sessionManagerProvider).accessToken();
      if (token == null) throw StateError('not signed in');
      return ref.read(gatewayProvider).call(name, body, deviceId: id, accessToken: token);
    },
  );
});

/// Runs the sync at the moments that matter and refreshes only what a sync changed. Safe to call from anywhere and as
/// often as wanted: two calls at once share one round, and a call soon after another is skipped unless forced.
class SyncRunner {
  SyncRunner(this._ref);

  final Ref _ref;
  DateTime? _last;
  Future<SyncReport?>? _running;

  static const Duration _quiet = Duration(seconds: 15);

  Future<SyncReport?> now({bool force = false}) {
    // The app is closing: nothing to sync, and the providers are gone.
    if (!_ref.mounted) return Future<SyncReport?>.value();
    final Future<SyncReport?>? running = _running;
    if (running != null) return running;
    final DateTime at = DateTime.fromMillisecondsSinceEpoch(_ref.read(clockProvider).nowMs());
    if (!force && _last != null && at.difference(_last!) < _quiet) return Future<SyncReport?>.value();
    _last = at;
    return _running = _round().whenComplete(() => _running = null);
  }

  Future<SyncReport?> _round() async {
    try {
      final SyncEngine? engine = await _ref.read(syncEngineProvider.future);
      if (engine == null) return null;
      final SyncReport r = await engine.syncOnce();
      if (!_ref.mounted) return r;
      if (r.childrenAdded > 0 || r.childrenDeleted > 0) {
        _ref.invalidate(appStateProvider);
        // The pulled answers change what the progress view says.
      }
      if (r.rulesApplied) {
        _ref.invalidate(rulesProvider);
        _ref.invalidate(aiHelperProvider);
      }
      if (r.pulledAlerts > 0 || r.pushedAlerts > 0) {
        _ref.invalidate(alertsProvider);
        _ref.invalidate(unreadAlertsProvider);
      }
      return r;
    } on Object {
      return null;
    }
  }
}

final Provider<SyncRunner> syncRunnerProvider = Provider<SyncRunner>(SyncRunner.new);

/// Keeps the family in step while the app is open: once at the start, whenever the app comes back to the front, and
/// every few minutes. Child spaces never wait for it and never see it.
class SyncScope extends ConsumerStatefulWidget {
  const SyncScope({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<SyncScope> createState() => _SyncScopeState();
}

class _SyncScopeState extends ConsumerState<SyncScope> with WidgetsBindingObserver {
  Timer? _every;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // A visit left open by a killed app must not count as play until now: close the old ones first, then sync.
    unawaited(
      ref
          .read(databaseProvider.future)
          .then(
            (AppDatabase db) => db.closeStaleSessions(
              DateTime.fromMillisecondsSinceEpoch(
                ref.read(clockProvider).nowMs(),
                isUtc: true,
              ).subtract(const Duration(hours: 3)),
            ),
          )
          .catchError((Object _) => 0)
          .then((_) => ref.read(syncRunnerProvider).now(force: true)),
    );
    _every = Timer.periodic(
      const Duration(minutes: 5),
      (Timer _) => unawaited(ref.read(syncRunnerProvider).now()),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) unawaited(ref.read(syncRunnerProvider).now());
  }

  @override
  void dispose() {
    _every?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
