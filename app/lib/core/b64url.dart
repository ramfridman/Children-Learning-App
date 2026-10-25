import 'dart:convert';
import 'dart:typed_data';

/// Base64url without padding, the encoding every field of the signed-request format uses.
String b64urlEncode(List<int> bytes) => base64Url.encode(bytes).replaceAll('=', '');

/// Throws [FormatException] on anything that is not valid base64url.
Uint8List b64urlDecode(String text) => Uint8List.fromList(base64Url.decode(base64Url.normalize(text)));
