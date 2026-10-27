import 'package:flutter/services.dart';

/// A reading of the clock that changing the date cannot move: milliseconds since the phone
/// started, and which start it was (so a restart is noticed).
class MonotonicReading {
  const MonotonicReading({required this.elapsedMs, required this.bootId});

  final int elapsedMs;
  final int bootId;
}

/// What `PlatformChannel.kt` offers. An interface, so tests use a fake.
abstract interface class PlatformService {
  /// A folder that is never backed up or copied to another phone.
  Future<String> noBackupDir();

  /// While true, screenshots and the recent-apps preview are blocked (parent screens).
  Future<void> setSecure({required bool secure});

  Future<MonotonicReading> monotonic();

  /// True once for each tap on a push notification that started the app or brought it forward.
  Future<bool> takeNotificationTap();
}

class AndroidPlatformService implements PlatformService {
  AndroidPlatformService([MethodChannel? channel])
    : _channel = channel ?? const MethodChannel('app.nitznutz/platform');

  final MethodChannel _channel;

  @override
  Future<String> noBackupDir() async {
    final String? path = await _channel.invokeMethod<String>('noBackupDir');
    if (path == null || path.isEmpty) throw StateError('no folder for local data');
    return path;
  }

  @override
  Future<void> setSecure({required bool secure}) async {
    try {
      await _channel.invokeMethod<void>('setSecure', <String, Object?>{'secure': secure});
    } on MissingPluginException {
      // Tests and platforms without the channel: nothing to block.
    }
  }

  @override
  Future<bool> takeNotificationTap() async {
    try {
      return (await _channel.invokeMethod<bool>('takeNotificationTap')) ?? false;
    } on MissingPluginException {
      return false;
    }
  }

  @override
  Future<MonotonicReading> monotonic() async {
    final int? elapsed = await _channel.invokeMethod<int>('elapsedRealtime');
    final int? boot = await _channel.invokeMethod<int>('bootCount');
    return MonotonicReading(elapsedMs: elapsed ?? 0, bootId: boot ?? 0);
  }
}
