import 'package:flutter/services.dart';

/// The two things `PlatformChannel.kt` offers. An interface, so tests use a fake.
abstract interface class PlatformService {
  /// A folder that is never backed up or copied to another phone.
  Future<String> noBackupDir();

  /// While true, screenshots and the recent-apps preview are blocked (parent screens).
  Future<void> setSecure({required bool secure});
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
}
