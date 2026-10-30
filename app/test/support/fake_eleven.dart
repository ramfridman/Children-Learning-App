import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../../tool/voice_gen_lib.dart';

/// A pretend ElevenLabs: a mock HTTP client (nothing leaves the test) that answers every request with a short sound and
/// one timestamp per character, and keeps every request it got.
class FakeEleven {
  final List<Map<String, Object?>> requests = <Map<String, Object?>>[];

  /// Answer every request with this status (0: answer normally).
  int failWith = 0;

  /// Answer 500 to every request after this many (-1: never).
  int failAfter = -1;

  /// Answer every request with a 303 to this address (null: never).
  String? redirectTo;

  /// Never answer.
  bool hang = false;

  late final http.Client client = MockClient((http.Request req) async {
    final Map<String, Object?> body = jsonDecode(utf8.decode(req.bodyBytes)) as Map<String, Object?>;
    requests.add(<String, Object?>{
      'method': req.method,
      'host': req.url.host,
      'scheme': req.url.scheme,
      'path': req.url.path,
      'query': req.url.query,
      'key': req.headers['xi-api-key'],
      'followRedirects': req.followRedirects,
      'body': body,
    });
    if (hang) return Completer<http.Response>().future;
    if (redirectTo != null) {
      return http.Response('', 303, headers: <String, String>{'location': redirectTo!});
    }
    if (failWith != 0 || (failAfter >= 0 && requests.length > failAfter)) {
      return http.Response.bytes(
        utf8.encode('{"detail":"echo ${jsonEncode(body)}"}'),
        failWith != 0 ? failWith : 500,
      );
    }
    final List<String> chars = (body['text']! as String).split('');
    return http.Response.bytes(
      utf8.encode(
        jsonEncode(<String, Object?>{
          'audio_base64': base64Encode(utf8.encode('mp3:${body['text']}')),
          'alignment': <String, Object?>{
            'characters': chars,
            'character_start_times_seconds': <double>[for (int i = 0; i < chars.length; i++) i * 0.1],
            'character_end_times_seconds': <double>[for (int i = 0; i < chars.length; i++) (i + 1) * 0.1],
          },
        }),
      ),
      200,
      headers: <String, String>{'content-type': 'application/json'},
    );
  });

  /// The body of every request, in order.
  List<Map<String, Object?>> get bodies => <Map<String, Object?>>[
    for (final Map<String, Object?> r in requests) r['body']! as Map<String, Object?>,
  ];
}

/// A pretend keyboard: a terminal or not, and the lines "typed" on it, in order.
class FakeKeyboard implements Keyboard {
  FakeKeyboard({this.isTerminal = true, List<String> typed = const <String>[]})
    : _typed = List<String>.of(typed);

  @override
  final bool isTerminal;
  final List<String> _typed;

  /// How many times a line was read.
  int reads = 0;

  @override
  String? readLine() {
    reads++;
    return _typed.isEmpty ? null : _typed.removeAt(0);
  }
}
