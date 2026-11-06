import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Names of the few values kept in secure storage.
abstract final class StoreKeys {
  static const String deviceId = 'device_id';
  static const String role = 'device_role';
  static const String refreshToken = 'refresh_token';
}

/// How every item sits in the iOS Keychain (SEC-B29-2): readable after the first unlock (the sync runs while the phone is locked),
/// never moved to another phone by a backup or a restore, and never synced through iCloud Keychain. The package's own default is
/// `unlocked`, which is not "this device only".
const IOSOptions iosSecureOptions = IOSOptions(
  accessibility: KeychainAccessibility.first_unlock_this_device,
  synchronizable: false,
);

/// The storage for every item: the iOS options above on every call.
const FlutterSecureStorage platformSecureStorage = FlutterSecureStorage(iOptions: iosSecureOptions);

/// Small key-value store backed by the platform's secure storage (Android Keystore, iOS Keychain).
abstract interface class SecureStore {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> delete(String key);
  Future<void> clear();
}

class PlatformSecureStore implements SecureStore {
  PlatformSecureStore([FlutterSecureStorage? storage]) : _storage = storage ?? platformSecureStorage;

  final FlutterSecureStorage _storage;

  /// The storage this store reads and writes through (for the test that checks its iOS options).
  @visibleForTesting
  FlutterSecureStorage get storage => _storage;

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> write(String key, String value) => _storage.write(key: key, value: value);

  @override
  Future<void> delete(String key) => _storage.delete(key: key);

  @override
  Future<void> clear() => _storage.deleteAll();
}
