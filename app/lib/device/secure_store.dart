import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Names of the few values kept in secure storage.
abstract final class StoreKeys {
  static const String deviceId = 'device_id';
  static const String role = 'device_role';
  static const String refreshToken = 'refresh_token';
}

/// Small key-value store backed by the platform's secure storage (Android Keystore).
abstract interface class SecureStore {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> delete(String key);
  Future<void> clear();
}

class PlatformSecureStore implements SecureStore {
  PlatformSecureStore([FlutterSecureStorage? storage]) : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> write(String key, String value) => _storage.write(key: key, value: value);

  @override
  Future<void> delete(String key) => _storage.delete(key: key);

  @override
  Future<void> clear() => _storage.deleteAll();
}
