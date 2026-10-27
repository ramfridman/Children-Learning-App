import 'dart:async';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/app_database.dart';
import '../device/secure_store.dart';
import '../parent/entry_flow.dart';
import '../push/firebase_push.dart';
import '../push/push_backend.dart';
import 'providers.dart';
import 'state.dart';
import 'sync_providers.dart';

/// The phone's push service. Tests give a fake one; the real one is only ever asked on a parent's phone.
final Provider<PushBackend> pushBackendProvider = Provider<PushBackend>((Ref ref) => FirebasePush());

/// The navigator of the app, so that a tap on a notification can open the parent gate from outside the widget tree.
final Provider<GlobalKey<NavigatorState>> navigatorKeyProvider = Provider<GlobalKey<NavigatorState>>(
  (Ref ref) => GlobalKey<NavigatorState>(),
);

/// A child's tablet is never offered push: only phones enrolled as a parent's.
final FutureProvider<bool> isParentDeviceProvider = FutureProvider<bool>(
  (Ref ref) async => (await ref.watch(secureStoreProvider).read(StoreKeys.role)) != 'child',
);

/// Whether this start of the app came from a tap on a push notification. While it is not known (a moment) or known to be
/// a tap, the app shows a calm loading screen instead of the child picker, so a parent who tapped never sees the child
/// space flash by on the way to the gate.
enum TapState { checking, pending, none }

class NotificationTap extends Notifier<TapState> {
  @override
  TapState build() {
    unawaited(_check());
    return TapState.checking;
  }

  Future<void> _check() async {
    bool tapped = false;
    try {
      tapped = await ref.read(platformProvider).takeNotificationTap();
    } on Object {
      // Nothing to learn from the phone: start as usual.
    }
    if (ref.mounted) state = tapped ? TapState.pending : TapState.none;
  }

  /// The gate has been opened (or could not be); the app shows its usual first screen behind it.
  void handled() {
    if (state != TapState.none) state = TapState.none;
  }
}

final NotifierProvider<NotificationTap, TapState> notificationTapProvider =
    NotifierProvider<NotificationTap, TapState>(NotificationTap.new);

/// What happened when a parent flipped the "Alerts on this phone" switch.
enum PushSwitch { on, off, denied, unavailable, failed }

const String _pushKey = 'push_on';

/// Tells the server this phone's push address (parent phones only; the server refuses any other).
Future<void> registerPushToken(Ref ref, String token) async {
  final String? id = await ref.read(secureStoreProvider).read(StoreKeys.deviceId);
  final String? access = await ref.read(sessionManagerProvider).accessToken();
  if (id == null || access == null) throw StateError('not signed in');
  await ref
      .read(gatewayProvider)
      .call(
        'push-token-register',
        <String, Object?>{'token': token, 'platform': Platform.isIOS ? 'ios' : 'android'},
        deviceId: id,
        accessToken: access,
      );
}

/// Gives the scope below a way to register an address without holding a [Ref].
final Provider<Future<void> Function(String)> pushRegistrarProvider = Provider<Future<void> Function(String)>(
  (Ref ref) =>
      (String token) => registerPushToken(ref, token),
);

/// Takes this phone off the server's push list.
final Provider<Future<void> Function()> pushRemoverProvider = Provider<Future<void> Function()>(
  (Ref ref) =>
      () => _removePushToken(ref),
);

Future<void> _removePushToken(Ref ref) async {
  final String? id = await ref.read(secureStoreProvider).read(StoreKeys.deviceId);
  final String? access = await ref.read(sessionManagerProvider).accessToken();
  if (id == null || access == null) return;
  await ref
      .read(gatewayProvider)
      .call('push-token-remove', const <String, Object?>{}, deviceId: id, accessToken: access);
}

/// The parent's switch for push on this phone: off until a parent turns it on, for this device only. Turning it on asks
/// Android for permission to show notifications (of a parent, never of a child) and gives the server this phone's address.
class PushEnabled extends AsyncNotifier<bool> {
  @override
  Future<bool> build() async => (await (await ref.watch(databaseProvider.future)).setting(_pushKey)) == 'on';

  Future<PushSwitch> set(bool on) async {
    final AppDatabase db = await ref.read(databaseProvider.future);
    final PushBackend push = ref.read(pushBackendProvider);
    if (!on) {
      try {
        await ref.read(pushRemoverProvider)();
      } on Object {
        // Without a connection the server keeps the old address; it drops it itself when the push service calls it dead.
      }
      await push.stop();
      await db.putSetting(_pushKey, 'off');
      state = const AsyncData<bool>(false);
      return PushSwitch.off;
    }
    switch (await push.start(askPermission: true)) {
      case PushStart.denied:
        return PushSwitch.denied;
      case PushStart.unavailable:
        return PushSwitch.unavailable;
      case PushStart.ready:
        break;
    }
    final String? token = await push.token();
    if (token == null) return PushSwitch.failed;
    try {
      await ref.read(pushRegistrarProvider)(token);
    } on Object {
      return PushSwitch.failed;
    }
    await db.putSetting(_pushKey, 'on');
    state = const AsyncData<bool>(true);
    return PushSwitch.on;
  }
}

final AsyncNotifierProvider<PushEnabled, bool> pushEnabledProvider = AsyncNotifierProvider<PushEnabled, bool>(
  PushEnabled.new,
);

/// Keeps push working while the app is open, on a parent's phone that turned it on: the address is renewed when the push
/// service changes it, a message that arrives while the app is open makes the alerts sync at once, and a tap on the
/// notification opens the parent gate (the alerts themselves are behind it). It does nothing on any other phone.
class PushScope extends ConsumerStatefulWidget {
  const PushScope({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<PushScope> createState() => _PushScopeState();
}

class _PushScopeState extends ConsumerState<PushScope> with WidgetsBindingObserver {
  final List<StreamSubscription<Object?>> _subs = <StreamSubscription<Object?>>[];
  DateTime? _gateOpenedAt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // The app was started by a tap: open the gate as soon as the first frame exists, before anything else is ready.
    ref.listenManual<TapState>(notificationTapProvider, (TapState? _, TapState now) {
      if (now != TapState.pending) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _openGate();
        // Until the gate has slid fully over it, the screen below stays the loading screen.
        Future<void>.delayed(const Duration(milliseconds: 500), () {
          if (mounted) ref.read(notificationTapProvider.notifier).handled();
        });
      });
    }, fireImmediately: true);
    unawaited(_begin());
  }

  /// The app was already running and a tap on a notification brought it forward.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    unawaited(
      ref
          .read(platformProvider)
          .takeNotificationTap()
          .then((bool tapped) {
            if (tapped && mounted) _openGate();
          })
          .catchError((Object _) {}),
    );
  }

  Future<void> _begin() async {
    try {
      if (!await ref.read(isParentDeviceProvider.future)) return;
      final AppDatabase db = await ref.read(databaseProvider.future);
      if ((await db.setting(_pushKey)) != 'on' || !mounted) return;
      final PushBackend push = ref.read(pushBackendProvider);
      final Future<void> Function(String) register = ref.read(pushRegistrarProvider);
      if (await push.start(askPermission: false) != PushStart.ready || !mounted) return;
      _subs
        ..add(
          push.tokenRefreshed.listen((String t) {
            unawaited(register(t).catchError((Object _) {}));
          }),
        )
        ..add(push.arrived.listen((_) => unawaited(ref.read(syncRunnerProvider).now(force: true))))
        ..add(push.opened.listen((_) => _openGate()));
      // The address may have changed while the app was closed, or the server may have dropped it.
      final String? token = await push.token();
      if (token != null) unawaited(register(token).catchError((Object _) {}));
    } on Object {
      // Push is a convenience; the alerts are always in the app.
    }
  }

  void _openGate() {
    if (!mounted) return;
    final BuildContext? context = ref.read(navigatorKeyProvider).currentState?.overlay?.context;
    if (context == null || !context.mounted) return;
    if (ref.read(parentSessionProvider).unlocked.value) return;
    // The same tap can arrive by two routes (the phone and the push library); the gate opens once.
    final DateTime now = DateTime.now();
    if (_gateOpenedAt != null && now.difference(_gateOpenedAt!) < const Duration(seconds: 3)) return;
    _gateOpenedAt = now;
    unawaited(openParentArea(context, ref));
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    for (final StreamSubscription<Object?> s in _subs) {
      unawaited(s.cancel());
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
