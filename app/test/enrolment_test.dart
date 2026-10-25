import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:nitznutz/auth/auth_client.dart';
import 'package:nitznutz/auth/session_manager.dart';
import 'package:nitznutz/core/b64url.dart';
import 'package:nitznutz/core/canonical.dart';
import 'package:nitznutz/core/config.dart';
import 'package:nitznutz/core/errors.dart';
import 'package:nitznutz/device/enrolment_service.dart';
import 'package:nitznutz/device/secure_store.dart';
import 'package:nitznutz/net/gateway_client.dart';
import 'package:nitznutz/net/net_gate.dart';

import 'support/fakes.dart';

const String challengeB64 = 'AAECAwQFBgcICQoLDA0ODxAREhMUFRYXGBkaGxwdHh8';
const String newDeviceId = 'b6f0ed2e-0d4e-4dec-957b-0c0513f36096';

class Rig {
  Rig({bool dev = false, http.Response Function(http.Request)? extra}) : config = testConfig(dev: dev) {
    recorder = Recorder((http.Request r) {
      final http.Response? custom = extra?.call(r);
      if (custom != null) return custom;
      switch (r.url.path) {
        case '/functions/v1/enroll-challenge':
          return jsonReply(<String, Object?>{'challenge': challengeB64, 'expires_at': 1});
        case '/functions/v1/device-enroll':
          return jsonReply(<String, Object?>{
            'device_id': newDeviceId,
            'role': 'parent',
            'security_level': 'tee',
          });
        case '/functions/v1/device-pair':
          return jsonReply(<String, Object?>{
            'device_id': newDeviceId,
            'role': 'child',
            'security_level': 'tee',
            'token_hash': 'hash_hash_hash_hash',
          });
        case '/auth/v1/verify':
        case '/auth/v1/token':
          return jsonReply(<String, Object?>{
            'access_token': 'access-1',
            'refresh_token': 'refresh-1',
            'expires_in': 3600,
          });
      }
      return jsonReply(<String, Object?>{'error': 'not_found'}, status: 404);
    });
    final NetGate gate = NetGate(client: recorder.client, hosts: testHosts());
    final Uri base = config.supabaseUrl;
    final AuthClient auth = AuthClient(baseUrl: base, publishableKey: testKey, gate: gate, clock: clock);
    sessions = SessionManager(auth: auth, store: store, clock: clock);
    service = EnrolmentService(
      gateway: GatewayClient(baseUrl: base, publishableKey: testKey, gate: gate, keys: keys, clock: clock),
      auth: auth,
      sessions: sessions,
      keys: keys,
      store: store,
      config: config,
    );
  }

  final AppConfig config;
  final FakeKeys keys = FakeKeys();
  final MemoryStore store = MemoryStore();
  final FixedClock clock = FixedClock(1793000000000);
  late final Recorder recorder;
  late final SessionManager sessions;
  late final EnrolmentService service;

  Map<String, dynamic> bodyOf(String path) {
    final http.Request r = recorder.requests.lastWhere((http.Request q) => q.url.path == path);
    return jsonDecode(r.body) as Map<String, dynamic>;
  }

  http.Request last(String path) => recorder.requests.lastWhere((http.Request q) => q.url.path == path);
}

Future<void> signedIn(Rig rig) => rig.sessions.setSession(
  AuthSession(accessToken: 'access-0', refreshToken: 'refresh-0', expiresAtMs: rig.clock.now + 3600000),
);

void main() {
  group('parent enrolment', () {
    test('asks for a challenge, puts it in the key, and sends the attestation chain', () async {
      final Rig rig = Rig();
      await signedIn(rig);

      final Enrolled e = await rig.service.enrolParent();

      expect(e.deviceId, newDeviceId);
      expect(e.role, 'parent');
      expect(rig.last('/functions/v1/enroll-challenge').headers['authorization'], 'Bearer access-0');
      expect(rig.keys.challenges.single, b64urlDecode(challengeB64));
      final Map<String, dynamic> body = rig.bodyOf('/functions/v1/device-enroll');
      expect(body['challenge'], challengeB64);
      expect(body['platform'], 'android');
      expect(body['attestation_kind'], 'key_attestation');
      expect((body['chain'] as List<dynamic>).length, 2);
      expect((b64urlDecode(body['public_key'] as String)).length, 91);
      expect(body.containsKey('dev_secret'), isFalse);
      expect(body.containsKey('replace_device_id'), isFalse);
      expect(rig.last('/functions/v1/device-enroll').headers['x-device-id'], nilDeviceId);
      expect(rig.store.data[StoreKeys.deviceId], newDeviceId);
    });

    test('refuses to enrol twice unless replacing, and then names the old device', () async {
      final Rig rig = Rig();
      await signedIn(rig);
      await rig.service.enrolParent();

      await expectLater(rig.service.enrolParent(), throwsStateError);

      await rig.service.enrolParent(replaceThisDevice: true);
      expect(rig.bodyOf('/functions/v1/device-enroll')['replace_device_id'], newDeviceId);
    });

    test('needs a sign-in first', () async {
      final Rig rig = Rig();
      await expectLater(
        rig.service.enrolParent(),
        throwsA(isA<GatewayException>().having((GatewayException e) => e.code, 'code', 'unauthorized')),
      );
      expect(rig.recorder.requests, isEmpty);
    });

    test('the dev secret is used in the dev flavour and sends no chain', () async {
      final Rig rig = Rig(dev: true);
      await signedIn(rig);

      await rig.service.enrolParent(devSecret: 'dev-secret-dev-secret');

      final Map<String, dynamic> body = rig.bodyOf('/functions/v1/device-enroll');
      expect(body['attestation_kind'], 'dev_allowlist');
      expect(body['dev_secret'], 'dev-secret-dev-secret');
      expect(body.containsKey('chain'), isFalse);
    });

    test('the dev secret is refused outside the dev flavour', () async {
      final Rig rig = Rig();
      await signedIn(rig);
      await expectLater(rig.service.enrolParent(devSecret: 'dev-secret-dev-secret'), throwsStateError);
      expect(rig.recorder.requests, isEmpty);
    });

    test('a refusal from the server leaves nothing stored', () async {
      final Rig rig = Rig(
        extra: (http.Request r) => r.url.path == '/functions/v1/device-enroll'
            ? jsonReply(<String, Object?>{'error': 'device_limit'}, status: 409)
            : null,
      );
      await signedIn(rig);

      await expectLater(
        rig.service.enrolParent(),
        throwsA(isA<GatewayException>().having((GatewayException e) => e.code, 'code', 'device_limit')),
      );
      expect(rig.store.data.containsKey(StoreKeys.deviceId), isFalse);
    });
  });

  group('child pairing', () {
    test('uses no sign-in for the challenge, then finishes with the one-time token', () async {
      final Rig rig = Rig();

      final Enrolled e = await rig.service.pairChild('123456');

      expect(e.role, 'child');
      expect(rig.last('/functions/v1/enroll-challenge').headers.containsKey('authorization'), isFalse);
      expect(rig.bodyOf('/functions/v1/enroll-challenge'), <String, dynamic>{'purpose': 'pair'});
      expect(rig.bodyOf('/functions/v1/device-pair')['code'], '123456');
      final Map<String, dynamic> verify = rig.bodyOf('/auth/v1/verify');
      expect(verify, <String, dynamic>{'type': 'magiclink', 'token_hash': 'hash_hash_hash_hash'});
      expect(rig.store.data[StoreKeys.deviceId], newDeviceId);
      expect(rig.store.data[StoreKeys.refreshToken], 'refresh-1');
    });

    test('an enrolled phone can not pair again', () async {
      final Rig rig = Rig();
      await rig.service.pairChild('123456');
      await expectLater(rig.service.pairChild('654321'), throwsStateError);
    });
  });

  test('forgetting this phone deletes the key and everything stored', () async {
    final Rig rig = Rig();
    await rig.service.pairChild('123456');

    await rig.service.forgetThisDevice();

    expect(rig.keys.deleted, isTrue);
    expect(rig.store.data, isEmpty);
    expect(await rig.service.enrolledDeviceId(), isNull);
  });
}
