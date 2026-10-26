import 'dart:async';

import 'package:flutter/widgets.dart';

import '../core/platform_service.dart';

/// Whether the parent area is open on this device right now.
///
/// It closes by itself after 5 idle minutes and as soon as the app goes to the background. While it
/// is open the window is marked secure (no screenshots, no recent-apps preview on Android). The
/// child space never reads or writes anything here except to ask the gate to open it.
class ParentSession with WidgetsBindingObserver {
  ParentSession({required PlatformService platform, this.idleLimit = const Duration(minutes: 5)})
    : _platform = platform {
    WidgetsBinding.instance.addObserver(this);
  }

  final PlatformService _platform;
  final Duration idleLimit;

  /// True while the parent area is open.
  final ValueNotifier<bool> unlocked = ValueNotifier<bool>(false);

  Timer? _idle;

  /// Opens the parent area. Call only after the gate and the PIN have both been passed.
  Future<void> unlock() async {
    await _platform.setSecure(secure: true);
    unlocked.value = true;
    touch();
  }

  /// Any tap or key press in the parent area calls this, which restarts the idle clock.
  void touch() {
    if (!unlocked.value) return;
    _idle?.cancel();
    _idle = Timer(idleLimit, lock);
  }

  void lock() {
    _idle?.cancel();
    _idle = null;
    if (!unlocked.value) return;
    unlocked.value = false;
    unawaited(_platform.setSecure(secure: false));
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.detached) {
      lock();
    }
  }

  void dispose() {
    _idle?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    unlocked.dispose();
  }
}
