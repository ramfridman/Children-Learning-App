import 'package:crypto/crypto.dart';

import 'b64url.dart';

/// Used by the pre-enrolment calls, which are signed with a brand new key and no device id yet.
const String nilDeviceId = '00000000-0000-0000-0000-000000000000';

final RegExp _uuidV4 = RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$');
final RegExp _uuidAny = RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$');
final RegExp _functionName = RegExp(r'^[a-z][a-z0-9-]{0,63}$');
final RegExp _hash = RegExp(r'^[A-Za-z0-9_-]{43}$');

/// Base64url (no padding) SHA-256 of the exact request body bytes.
String bodyHash(List<int> body) => b64urlEncode(sha256.convert(body).bytes);

/// The string that is signed. It must match the server's format exactly:
/// `v1 LF POST LF /function LF unix-ms LF nonce LF body-hash LF device-id`.
/// Throws [ArgumentError] if any part is malformed (a programming error).
String canonicalString({
  required String functionName,
  required int timestampMs,
  required String nonce,
  required String bodyHashB64url,
  required String deviceId,
}) {
  if (!_functionName.hasMatch(functionName)) throw ArgumentError('bad function name');
  if (timestampMs < 0) throw ArgumentError('bad timestamp');
  if (!_uuidV4.hasMatch(nonce)) throw ArgumentError('bad nonce');
  if (!_hash.hasMatch(bodyHashB64url)) throw ArgumentError('bad body hash');
  if (!_uuidAny.hasMatch(deviceId)) throw ArgumentError('bad device id');
  return <String>['v1', 'POST', '/$functionName', '$timestampMs', nonce, bodyHashB64url, deviceId].join('\n');
}
