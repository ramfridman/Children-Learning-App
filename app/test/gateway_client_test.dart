import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:nitznutz/core/b64url.dart';
import 'package:nitznutz/core/canonical.dart';
import 'package:nitznutz/core/errors.dart';
import 'package:nitznutz/core/hosts.dart';
import 'package:nitznutz/net/gateway_client.dart';
import 'package:nitznutz/net/net_gate.dart';

import 'support/fakes.dart';

GatewayClient clientFor(Recorder rec, FakeKeys keys, FixedClock clock, {NetworkHosts? hosts}) => GatewayClient(
  baseUrl: Uri.parse('https://$testHost'),
  publishableKey: testKey,
  gate: NetGate(client: rec.client, hosts: hosts ?? testHosts()),
  keys: keys,
  clock: clock,
);

void main() {
  const String deviceId = 'b6f0ed2e-0d4e-4dec-957b-0c0513f36096';

  test('a device-signed call signs exactly the canonical string it sends', () async {
    final Recorder rec = Recorder((http.Request r) => jsonReply(<String, Object?>{'ok': true}));
    final FakeKeys keys = FakeKeys();
    final GatewayClient client = clientFor(rec, keys, FixedClock(1793000000000));

    final Map<String, Object?> out = await client.call(
      'signed-ping',
      <String, Object?>{},
      deviceId: deviceId,
      accessToken: 'tok',
    );

    expect(out['ok'], true);
    final http.Request sent = rec.requests.single;
    expect(sent.url.toString(), 'https://$testHost/functions/v1/signed-ping');
    expect(sent.headers['x-region'], 'eu-central-1');
    expect(sent.headers['apikey'], testKey);
    expect(sent.headers['authorization'], 'Bearer tok');
    expect(sent.headers['x-device-id'], deviceId);
    expect(sent.headers['x-timestamp'], '1793000000000');
    expect(sent.headers['x-signature'], b64urlEncode(<int>[0x30, 0x06, 0x02, 0x01, 0x01, 0x02, 0x01, 0x01]));
    expect(sent.body, '{}');

    final String expected = canonicalString(
      functionName: 'signed-ping',
      timestampMs: 1793000000000,
      nonce: sent.headers['x-nonce']!,
      bodyHashB64url: bodyHash(sent.bodyBytes),
      deviceId: deviceId,
    );
    expect(utf8.decode(keys.signed.single), expected);
  });

  test('a self-signed call uses the nil device id and a new nonce each time', () async {
    final Recorder rec = Recorder((http.Request r) => jsonReply(<String, Object?>{}));
    final FakeKeys keys = FakeKeys();
    final GatewayClient client = clientFor(rec, keys, FixedClock(5));

    await client.call('device-enroll', <String, Object?>{'a': 1}, signing: Signing.selfSigned);
    await client.call('device-enroll', <String, Object?>{'a': 1}, signing: Signing.selfSigned);

    expect(rec.requests.map((http.Request r) => r.headers['x-device-id']).toSet(), <String?>{nilDeviceId});
    expect(rec.requests.map((http.Request r) => r.headers['x-nonce']).toSet().length, 2);
    expect(rec.requests.first.headers.containsKey('authorization'), isFalse);
  });

  test('an unsigned call carries no signature headers', () async {
    final Recorder rec = Recorder((http.Request r) => jsonReply(<String, Object?>{'challenge': 'x'}));
    final GatewayClient client = clientFor(rec, FakeKeys(), FixedClock(5));

    await client.call('enroll-challenge', <String, Object?>{'purpose': 'pair'}, signing: Signing.none);

    final Map<String, String> h = rec.requests.single.headers;
    for (final String name in <String>['x-device-id', 'x-timestamp', 'x-nonce', 'x-signature']) {
      expect(h.containsKey(name), isFalse, reason: name);
    }
  });

  test('a clock_skew answer is retried once with the server time', () async {
    int calls = 0;
    final Recorder rec = Recorder((http.Request r) {
      calls++;
      return calls == 1
          ? jsonReply(<String, Object?>{'error': 'clock_skew', 'server_time': 2000000}, status: 401)
          : jsonReply(<String, Object?>{'ok': true});
    });
    final GatewayClient client = clientFor(rec, FakeKeys(), FixedClock(1000));

    final Map<String, Object?> out = await client.call('signed-ping', <String, Object?>{}, deviceId: deviceId);

    expect(out['ok'], true);
    expect(rec.requests.length, 2);
    expect(rec.requests.first.headers['x-timestamp'], '1000');
    expect(rec.requests.last.headers['x-timestamp'], '2000000');
  });

  test('a second clock_skew is not retried again', () async {
    final Recorder rec = Recorder(
      (http.Request r) => jsonReply(<String, Object?>{'error': 'clock_skew', 'server_time': 9}, status: 401),
    );
    final GatewayClient client = clientFor(rec, FakeKeys(), FixedClock(1000));

    await expectLater(
      client.call('signed-ping', <String, Object?>{}, deviceId: deviceId),
      throwsA(isA<GatewayException>().having((GatewayException e) => e.code, 'code', 'clock_skew')),
    );
    expect(rec.requests.length, 2);
  });

  test('error codes and statuses are passed on', () async {
    final Recorder rec = Recorder((http.Request r) => jsonReply(<String, Object?>{'error': 'forbidden'}, status: 403));
    final GatewayClient client = clientFor(rec, FakeKeys(), FixedClock(1));

    await expectLater(
      client.call('device-list', <String, Object?>{}, deviceId: deviceId),
      throwsA(
        isA<GatewayException>()
            .having((GatewayException e) => e.code, 'code', 'forbidden')
            .having((GatewayException e) => e.status, 'status', 403),
      ),
    );
  });

  test('a body that is not JSON is a bad_response', () async {
    final Recorder rec = Recorder((http.Request r) => http.Response('<html>', 502));
    final GatewayClient client = clientFor(rec, FakeKeys(), FixedClock(1));

    await expectLater(
      client.call('signed-ping', <String, Object?>{}, deviceId: deviceId),
      throwsA(isA<GatewayException>().having((GatewayException e) => e.code, 'code', 'bad_response')),
    );
  });

  test('a host that is not in the allowlist is refused before anything is sent', () async {
    final Recorder rec = Recorder((http.Request r) => jsonReply(<String, Object?>{}));
    final NetworkHosts other = NetworkHosts.parse(
      '{"hosts":[{"name":"o","host":"other.example","scheme":"https","roles":[]}]}',
    );
    final GatewayClient client = clientFor(rec, FakeKeys(), FixedClock(1), hosts: other);

    await expectLater(
      client.call('signed-ping', <String, Object?>{}, deviceId: deviceId),
      throwsA(isA<GatewayException>().having((GatewayException e) => e.code, 'code', 'host_not_allowed')),
    );
    expect(rec.requests, isEmpty);
  });

  test('a device-signed call without a device id is a programming error', () async {
    final Recorder rec = Recorder((http.Request r) => jsonReply(<String, Object?>{}));
    final GatewayClient client = clientFor(rec, FakeKeys(), FixedClock(1));
    await expectLater(client.call('signed-ping', <String, Object?>{}), throwsArgumentError);
    expect(rec.requests, isEmpty);
  });
}
