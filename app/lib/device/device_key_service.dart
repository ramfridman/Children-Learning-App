import 'dart:typed_data';

import 'package:flutter/services.dart';

/// A freshly made signing key: its public half (X.509 SubjectPublicKeyInfo, 91 bytes for P-256)
/// and the attestation certificate chain (leaf first) that proves it lives in secure hardware.
class DeviceKeyMaterial {
  const DeviceKeyMaterial({required this.publicKey, required this.chain});

  final Uint8List publicKey;
  final List<Uint8List> chain;
}

class KeystoreException implements Exception {
  const KeystoreException(this.code);
  final String code;

  @override
  String toString() => 'KeystoreException($code)';
}

/// The device's non-exportable signing key. The private half never leaves secure hardware.
abstract interface class DeviceKeyService {
  /// Replaces any existing key with a new one whose attestation carries [challenge].
  Future<DeviceKeyMaterial> createKey(Uint8List challenge);

  /// ECDSA P-256 / SHA-256 over [message], DER encoded.
  Future<Uint8List> sign(Uint8List message);

  Future<bool> hasKey();

  Future<void> deleteKey();
}

/// Talks to `DeviceKeyChannel.kt`, which uses the Android Keystore (StrongBox when present).
class AndroidDeviceKeyService implements DeviceKeyService {
  AndroidDeviceKeyService([MethodChannel? channel])
    : _channel = channel ?? const MethodChannel('app.nitznutz/device_key');

  final MethodChannel _channel;

  Future<T?> _invoke<T>(String method, [Map<String, Object?>? args]) async {
    try {
      return await _channel.invokeMethod<T>(method, args);
    } on PlatformException catch (e) {
      throw KeystoreException(e.code);
    } on MissingPluginException {
      throw const KeystoreException('unsupported');
    }
  }

  @override
  Future<DeviceKeyMaterial> createKey(Uint8List challenge) async {
    final Object? raw = await _invoke<Object?>('createKey', <String, Object?>{'challenge': challenge});
    if (raw is! Map<Object?, Object?>) throw const KeystoreException('bad_result');
    final Object? key = raw['publicKey'];
    final Object? chain = raw['chain'];
    if (key is! Uint8List || chain is! List<Object?>) throw const KeystoreException('bad_result');
    final List<Uint8List> certs = <Uint8List>[];
    for (final Object? cert in chain) {
      if (cert is! Uint8List) throw const KeystoreException('bad_result');
      certs.add(cert);
    }
    return DeviceKeyMaterial(publicKey: key, chain: certs);
  }

  @override
  Future<Uint8List> sign(Uint8List message) async {
    final Object? raw = await _invoke<Object?>('sign', <String, Object?>{'message': message});
    if (raw is! Uint8List) throw const KeystoreException('bad_result');
    return raw;
  }

  @override
  Future<bool> hasKey() async => (await _invoke<bool>('hasKey')) ?? false;

  @override
  Future<void> deleteKey() async {
    await _invoke<Object?>('deleteKey');
  }
}
