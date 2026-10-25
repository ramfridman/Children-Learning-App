import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/core/b64url.dart';
import 'package:nitznutz/core/canonical.dart';

void main() {
  // The same vectors the gateway's tests use, so the two sides can not drift apart.
  final Object? root = jsonDecode(File('../testvectors/signed-request.json').readAsStringSync());
  final List<dynamic> cases = (root! as Map<String, dynamic>)['cases']! as List<dynamic>;

  group('shared test vectors', () {
    for (final dynamic raw in cases) {
      final Map<String, dynamic> c = raw as Map<String, dynamic>;
      test('${c['name']}', () {
        final String body = c['body']! as String;
        final String hash = bodyHash(utf8.encode(body));
        expect(hash, c['body_sha256_b64url']);
        expect(
          canonicalString(
            functionName: c['function']! as String,
            timestampMs: c['timestamp_ms']! as int,
            nonce: c['nonce']! as String,
            bodyHashB64url: hash,
            deviceId: c['device_id']! as String,
          ),
          c['canonical'],
        );
      });
    }
  });

  group('canonicalString refuses malformed parts', () {
    const String nonce = '8202f017-9804-468f-8fe0-329006075f8a';
    const String hash = 'RBNvo1WzZ4oRRq0W9-hknpT7T8If536DEMBg9hyq_4o';

    String build({String fn = 'signed-ping', String n = nonce, String h = hash, String id = nilDeviceId}) =>
        canonicalString(functionName: fn, timestampMs: 1, nonce: n, bodyHashB64url: h, deviceId: id);

    test('accepts a good set', () => expect(build(), contains('/signed-ping')));
    test('newline in function name', () => expect(() => build(fn: 'a\nb'), throwsArgumentError));
    test('upper case function name', () => expect(() => build(fn: 'Ping'), throwsArgumentError));
    test('nonce that is not v4', () => expect(() => build(n: nilDeviceId), throwsArgumentError));
    test('short hash', () => expect(() => build(h: 'abc'), throwsArgumentError));
    test('bad device id', () => expect(() => build(id: 'not-a-uuid'), throwsArgumentError));
  });

  test('base64url round trip has no padding', () {
    final String text = b64urlEncode(<int>[251, 255, 190, 1]);
    expect(text, '-_--AQ');
    expect(b64urlDecode(text), <int>[251, 255, 190, 1]);
  });
}
