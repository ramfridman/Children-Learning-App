import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

import '../core/b64url.dart';
import '../core/canonical.dart';
import '../core/clock.dart';
import '../core/errors.dart';
import '../device/device_key_service.dart';
import 'net_gate.dart';

/// How a call to the gateway is authenticated.
enum Signing {
  /// No device signature (for example `enroll-challenge`).
  none,

  /// Signed by the enrolled device's key; needs a device id.
  device,

  /// Signed with a brand new key that is not enrolled yet (`device-enroll`, `device-pair`).
  /// The device id in the signed string is the nil UUID.
  selfSigned,
}

/// The one client for our Edge Functions. It builds the canonical string, signs it with the
/// device key, and retries once if the phone's clock is off (using the server's time).
class GatewayClient {
  GatewayClient({
    required Uri baseUrl,
    required String publishableKey,
    required NetGate gate,
    required DeviceKeyService keys,
    required Clock clock,
    Uuid? uuid,
  }) : _base = baseUrl,
       _publishableKey = publishableKey,
       _gate = gate,
       _keys = keys,
       _clock = clock,
       _uuid = uuid ?? Uuid();

  static const String region = 'eu-central-1';

  final Uri _base;
  final String _publishableKey;
  final NetGate _gate;
  final DeviceKeyService _keys;
  final Clock _clock;
  final Uuid _uuid;

  /// Server time minus phone time, learned from a `clock_skew` answer.
  int _skewMs = 0;

  Uri _functionUri(String name) => _base.replace(path: '/functions/v1/$name');

  /// Calls function [name] and returns its JSON object. Throws [GatewayException] on any failure.
  Future<Map<String, Object?>> call(
    String name,
    Map<String, Object?> body, {
    Signing signing = Signing.device,
    String? deviceId,
    String? accessToken,
  }) async {
    try {
      return await _once(name, body, signing, deviceId, accessToken);
    } on GatewayException catch (e) {
      final int? serverTime = e.serverTimeMs;
      if (e.code == 'clock_skew' && serverTime != null && signing != Signing.none) {
        _skewMs = serverTime - _clock.nowMs();
        return _once(name, body, signing, deviceId, accessToken);
      }
      rethrow;
    }
  }

  Future<Map<String, Object?>> _once(
    String name,
    Map<String, Object?> body,
    Signing signing,
    String? deviceId,
    String? accessToken,
  ) async {
    final List<int> bytes = utf8.encode(jsonEncode(body));
    final Map<String, String> headers = <String, String>{
      'content-type': 'application/json; charset=utf-8',
      'apikey': _publishableKey,
      'x-region': region,
      'authorization': ?(accessToken == null ? null : 'Bearer $accessToken'),
    };

    if (signing != Signing.none) {
      final String id = signing == Signing.selfSigned ? nilDeviceId : (deviceId ?? '');
      if (signing == Signing.device && deviceId == null) throw ArgumentError('device id needed');
      final int timestamp = _clock.nowMs() + _skewMs;
      final String nonce = _uuid.v4();
      final String canonical = canonicalString(
        functionName: name,
        timestampMs: timestamp,
        nonce: nonce,
        bodyHashB64url: bodyHash(bytes),
        deviceId: id,
      );
      final Uint8List signature = await _keys.sign(Uint8List.fromList(utf8.encode(canonical)));
      headers['x-device-id'] = id;
      headers['x-timestamp'] = '$timestamp';
      headers['x-nonce'] = nonce;
      headers['x-signature'] = b64urlEncode(signature);
    }

    final http.Response response = await _gate.post(_functionUri(name), headers: headers, body: bytes);
    return _parse(response);
  }

  Map<String, Object?> _parse(http.Response response) {
    final Object? decoded;
    try {
      decoded = jsonDecode(utf8.decode(response.bodyBytes));
    } on FormatException {
      throw GatewayException('bad_response', status: response.statusCode);
    }
    if (decoded is! Map<String, dynamic>) {
      throw GatewayException('bad_response', status: response.statusCode);
    }
    if (response.statusCode >= 400) {
      final Object? code = decoded['error'];
      final Object? serverTime = decoded['server_time'];
      throw GatewayException(
        code is String ? code : 'internal',
        status: response.statusCode,
        serverTimeMs: serverTime is num ? serverTime.toInt() : null,
      );
    }
    return Map<String, Object?>.from(decoded);
  }
}
