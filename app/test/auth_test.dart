import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:nitznutz/auth/auth_client.dart';
import 'package:nitznutz/auth/session_manager.dart';
import 'package:nitznutz/core/errors.dart';
import 'package:nitznutz/device/secure_store.dart';
import 'package:nitznutz/net/net_gate.dart';

import 'support/fakes.dart';

AuthClient authFor(Recorder rec, FixedClock clock) => AuthClient(
  baseUrl: Uri.parse('https://$testHost'),
  publishableKey: testKey,
  gate: NetGate(client: rec.client, hosts: testHosts()),
  clock: clock,
);

http.Response session(String access, String refresh, {int expiresIn = 3600}) => jsonReply(<String, Object?>{
  'access_token': access,
  'refresh_token': refresh,
  'expires_in': expiresIn,
});

void main() {
  test('the email code request never creates a user', () async {
    final Recorder rec = Recorder((http.Request r) => http.Response('{}', 200));
    await authFor(rec, FixedClock(0)).sendEmailCode('a@example.test');

    final http.Request sent = rec.requests.single;
    expect(sent.url.path, '/auth/v1/otp');
    expect(sent.headers['apikey'], testKey);
    expect(jsonDecode(sent.body), <String, Object?>{'email': 'a@example.test', 'create_user': false});
  });

  test('verifying the email code returns a session with an absolute expiry', () async {
    final Recorder rec = Recorder((http.Request r) => session('a', 'r', expiresIn: 100));
    final AuthSession s = await authFor(rec, FixedClock(1000)).verifyEmailCode('a@example.test', '123456');

    expect(s.accessToken, 'a');
    expect(s.expiresAtMs, 1000 + 100000);
    expect(jsonDecode(rec.requests.single.body), <String, Object?>{
      'type': 'email',
      'email': 'a@example.test',
      'token': '123456',
    });
  });

  test('refreshing uses the refresh_token grant', () async {
    final Recorder rec = Recorder((http.Request r) => session('a2', 'r2'));
    await authFor(rec, FixedClock(0)).refresh('r1');

    expect(rec.requests.single.url.path, '/auth/v1/token');
    expect(rec.requests.single.url.queryParameters, <String, String>{'grant_type': 'refresh_token'});
    expect(jsonDecode(rec.requests.single.body), <String, Object?>{'refresh_token': 'r1'});
  });

  test('a rejected code is auth_failed, a throttled one is rate_limited', () async {
    final Recorder bad = Recorder((http.Request r) => http.Response('{}', 403));
    await expectLater(
      authFor(bad, FixedClock(0)).verifyEmailCode('a@example.test', '000000'),
      throwsA(isA<GatewayException>().having((GatewayException e) => e.code, 'code', 'auth_failed')),
    );
    final Recorder slow = Recorder((http.Request r) => http.Response('{}', 429));
    await expectLater(
      authFor(slow, FixedClock(0)).sendEmailCode('a@example.test'),
      throwsA(isA<GatewayException>().having((GatewayException e) => e.code, 'code', 'rate_limited')),
    );
  });

  group('SessionManager', () {
    test('keeps a fresh token and stores only the refresh token', () async {
      final FixedClock clock = FixedClock(0);
      final MemoryStore store = MemoryStore();
      final Recorder rec = Recorder((http.Request r) => session('x', 'y'));
      final SessionManager m = SessionManager(auth: authFor(rec, clock), store: store, clock: clock);

      await m.setSession(const AuthSession(accessToken: 'a', refreshToken: 'r', expiresAtMs: 3600000));

      expect(await m.accessToken(), 'a');
      expect(rec.requests, isEmpty);
      expect(store.data, <String, String>{StoreKeys.refreshToken: 'r'});
    });

    test('renews a token that is about to expire and keeps the new refresh token', () async {
      final FixedClock clock = FixedClock(0);
      final MemoryStore store = MemoryStore();
      final Recorder rec = Recorder((http.Request r) => session('a2', 'r2'));
      final SessionManager m = SessionManager(auth: authFor(rec, clock), store: store, clock: clock);
      await m.setSession(const AuthSession(accessToken: 'a', refreshToken: 'r', expiresAtMs: 30000));

      expect(await m.accessToken(), 'a2');
      expect(store.data[StoreKeys.refreshToken], 'r2');
    });

    test('signs out when the refresh token is rejected', () async {
      final FixedClock clock = FixedClock(0);
      final MemoryStore store = MemoryStore()..data[StoreKeys.refreshToken] = 'old';
      final Recorder rec = Recorder((http.Request r) => http.Response('{}', 400));
      final SessionManager m = SessionManager(auth: authFor(rec, clock), store: store, clock: clock);

      expect(await m.accessToken(), isNull);
      expect(store.data, isEmpty);
    });

    test('without any session or stored token there is nothing to renew', () async {
      final FixedClock clock = FixedClock(0);
      final Recorder rec = Recorder((http.Request r) => session('x', 'y'));
      final SessionManager m = SessionManager(auth: authFor(rec, clock), store: MemoryStore(), clock: clock);

      expect(await m.accessToken(), isNull);
      expect(rec.requests, isEmpty);
    });
  });
}
