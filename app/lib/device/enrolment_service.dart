import '../auth/auth_client.dart';
import '../auth/session_manager.dart';
import '../core/b64url.dart';
import '../core/config.dart';
import '../core/errors.dart';
import '../net/gateway_client.dart';
import 'device_key_service.dart';
import 'secure_store.dart';

class Enrolled {
  const Enrolled({required this.deviceId, required this.role, required this.securityLevel});

  final String deviceId;
  final String role;
  final String securityLevel;
}

/// Turns this phone into a parent device (after an email sign-in) or a child device (with a
/// pairing code). A new key is made for each, with the server's challenge inside its attestation.
class EnrolmentService {
  EnrolmentService({
    required GatewayClient gateway,
    required AuthClient auth,
    required SessionManager sessions,
    required DeviceKeyService keys,
    required SecureStore store,
    required AppConfig config,
  }) : _gateway = gateway,
       _auth = auth,
       _sessions = sessions,
       _keys = keys,
       _store = store,
       _config = config;

  final GatewayClient _gateway;
  final AuthClient _auth;
  final SessionManager _sessions;
  final DeviceKeyService _keys;
  final SecureStore _store;
  final AppConfig _config;

  Future<String?> enrolledDeviceId() => _store.read(StoreKeys.deviceId);

  /// Enrols this phone as a parent device. If it is already enrolled, [replaceThisDevice] must be
  /// true: making a new key would otherwise orphan the old device record.
  /// [devSecret] is for emulators in the dev flavour only.
  Future<Enrolled> enrolParent({bool replaceThisDevice = false, String? devSecret}) async {
    if (devSecret != null && !_config.isDev) throw StateError('dev enrolment is dev-flavour only');
    final String? existing = await _store.read(StoreKeys.deviceId);
    if (existing != null && !replaceThisDevice) throw StateError('already enrolled');
    final String? token = await _sessions.accessToken();
    if (token == null) throw const GatewayException('unauthorized');

    final Map<String, Object?> issued = await _gateway.call(
      'enroll-challenge',
      <String, Object?>{'purpose': 'enroll'},
      signing: Signing.none,
      accessToken: token,
    );
    final String challenge = _text(issued, 'challenge');
    final DeviceKeyMaterial key = await _keys.createKey(b64urlDecode(challenge));

    final Map<String, Object?> body = <String, Object?>{
      ..._enrolFields(challenge, key, devSecret),
      'replace_device_id': ?existing,
    };
    final Map<String, Object?> result = await _gateway.call(
      'device-enroll',
      body,
      signing: Signing.selfSigned,
      accessToken: token,
    );
    final Enrolled enrolled = _enrolled(result);
    await _store.write(StoreKeys.deviceId, enrolled.deviceId);
    await _store.write(StoreKeys.role, enrolled.role);
    return enrolled;
  }

  /// Joins a family as a child device using the 6-digit [code] a parent made.
  Future<Enrolled> pairChild(String code, {String? devSecret}) async {
    if (devSecret != null && !_config.isDev) throw StateError('dev enrolment is dev-flavour only');
    if (await _store.read(StoreKeys.deviceId) != null) throw StateError('already enrolled');

    final Map<String, Object?> issued = await _gateway.call('enroll-challenge', <String, Object?>{
      'purpose': 'pair',
    }, signing: Signing.none);
    final String challenge = _text(issued, 'challenge');
    final DeviceKeyMaterial key = await _keys.createKey(b64urlDecode(challenge));

    final Map<String, Object?> result = await _gateway.call('device-pair', <String, Object?>{
      ..._enrolFields(challenge, key, devSecret),
      'code': code,
    }, signing: Signing.selfSigned);
    final Enrolled enrolled = _enrolled(result);
    final AuthSession session = await _auth.signInWithTokenHash(_text(result, 'token_hash'));
    await _sessions.setSession(session);
    await _store.write(StoreKeys.deviceId, enrolled.deviceId);
    await _store.write(StoreKeys.role, enrolled.role);
    return enrolled;
  }

  /// Dev tool: forgets this phone locally (key, device id, sign-in). The server record stays
  /// until a parent revokes it.
  Future<void> forgetThisDevice() async {
    await _keys.deleteKey();
    await _sessions.signOut();
    await _store.clear();
  }

  Map<String, Object?> _enrolFields(String challenge, DeviceKeyMaterial key, String? devSecret) {
    final bool dev = devSecret != null && devSecret.isNotEmpty;
    return <String, Object?>{
      'challenge': challenge,
      'public_key': b64urlEncode(key.publicKey),
      'platform': 'android',
      'attestation_kind': dev ? 'dev_allowlist' : 'key_attestation',
      if (!dev) 'chain': key.chain.map(b64urlEncode).toList(),
      'dev_secret': ?(dev ? devSecret : null),
      'app_version': appVersion,
    };
  }

  String _text(Map<String, Object?> json, String field) {
    final Object? value = json[field];
    if (value is! String) throw const GatewayException('bad_response');
    return value;
  }

  Enrolled _enrolled(Map<String, Object?> json) => Enrolled(
    deviceId: _text(json, 'device_id'),
    role: _text(json, 'role'),
    securityLevel: _text(json, 'security_level'),
  );
}
