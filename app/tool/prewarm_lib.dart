// The pre-warm client: asks the gateway's `tutor-prewarm` to make tutor lines ahead of time, and measures its speed.
// PC only. It sends ids and numbers (which pack, which characters, how many) and the publish secret in one header;
// the secret is never printed or written.
import 'dart:convert';
import 'dart:io';

class PrewarmFailed implements Exception {
  const PrewarmFailed(this.message);

  final String message;

  @override
  String toString() => message;
}

/// What the owner asked for: the lines of one pack version, for these characters, bands and address forms.
class PrewarmRequest {
  const PrewarmRequest({
    required this.packId,
    required this.packVersion,
    required this.characters,
    this.bands = const <String>['A', 'B', 'C'],
    this.forms = const <String>['f', 'm', 'n'],
    this.hintLevelOfTags = 2,
  });

  final String packId;
  final String packVersion;
  final List<String> characters;
  final List<String> bands;
  final List<String> forms;
  final int hintLevelOfTags;

  Map<String, Object?> body(String mode, {int limit = 25, int offset = 0, int maxMicro = 0, int count = 1}) =>
      <String, Object?>{
        'mode': mode,
        'pack_id': packId,
        'pack_version': packVersion,
        'character_ids': characters,
        'bands': bands,
        'address_forms': forms,
        'hint_level_tags': hintLevelOfTags,
        'limit': limit,
        'offset': offset,
        'max_micro_usd': maxMicro,
        'count': count,
      };
}

/// Sends one request to `tutor-prewarm`. [baseUrl] is changed only by tests, to a local fake.
typedef PrewarmSend = Future<Map<String, Object?>> Function(Map<String, Object?> body);

PrewarmSend httpSend({required String baseUrl, required String secret, String? publishableKey}) {
  return (Map<String, Object?> body) async {
    final HttpClient client = HttpClient();
    try {
      final HttpClientRequest req = await client.postUrl(Uri.parse('$baseUrl/functions/v1/tutor-prewarm'));
      req.headers
        ..set('content-type', 'application/json')
        ..set('x-publish-secret', secret)
        ..set('x-region', 'eu-central-1');
      if (publishableKey != null) req.headers.set('apikey', publishableKey);
      req.add(utf8.encode(jsonEncode(body)));
      final HttpClientResponse res = await req.close().timeout(const Duration(minutes: 5));
      final String text = await utf8.decodeStream(res);
      if (res.statusCode != 200) {
        String code = 'error';
        try {
          code = ((jsonDecode(text) as Map<String, Object?>)['error'] ?? 'error').toString();
        } on FormatException {
          // keep the generic word
        }
        throw PrewarmFailed('the server refused: ${res.statusCode} $code');
      }
      return jsonDecode(text) as Map<String, Object?>;
    } finally {
      client.close();
    }
  };
}

/// "0.43" for 430000 micro-dollars.
String dollars(int micro) => (micro / 1000000).toStringAsFixed(2);

class PrewarmPlan {
  const PrewarmPlan({
    required this.lines,
    required this.cached,
    required this.toMake,
    required this.estMicro,
    required this.voiceChars,
  });

  factory PrewarmPlan.from(Map<String, Object?> j) => PrewarmPlan(
    lines: j['lines']! as int,
    cached: j['cached']! as int,
    toMake: j['to_make']! as int,
    estMicro: j['est_micro_usd']! as int,
    voiceChars: j['est_voice_chars']! as int,
  );

  final int lines;
  final int cached;
  final int toMake;
  final int estMicro;
  final int voiceChars;

  /// What the owner reads before saying yes.
  String describe() =>
      '$lines lines in all, $cached already made, $toMake to make: about $voiceChars voice characters and '
      '${dollars(estMicro)} USD (an estimate, from the prices in the server config).';
}

Future<PrewarmPlan> plan(PrewarmSend send, PrewarmRequest r) async =>
    PrewarmPlan.from(await send(r.body('plan')));

class PrewarmOutcome {
  const PrewarmOutcome({
    required this.made,
    required this.cached,
    required this.failed,
    required this.spentMicro,
  });

  final int made;
  final int cached;
  final Map<String, int> failed;
  final int spentMicro;
}

/// Makes the lines in batches. It refuses to start unless [confirmLines] equals the number of lines the plan
/// says are still to be made, and it gives the server a ceiling of one and a half times the estimate.
Future<PrewarmOutcome> make(
  PrewarmSend send,
  PrewarmRequest r, {
  required int? confirmLines,
  void Function(String)? say,
}) async {
  final PrewarmPlan p = await plan(send, r);
  say?.call(p.describe());
  if (p.toMake == 0) return const PrewarmOutcome(made: 0, cached: 0, failed: <String, int>{}, spentMicro: 0);
  if (confirmLines != p.toMake) {
    throw PrewarmFailed(
      'nothing was made. To go ahead, run again with --confirm-lines ${p.toMake} (the number of lines to make).',
    );
  }
  final int ceiling = (p.estMicro * 3 / 2).ceil() + 1;
  int made = 0;
  int cached = 0;
  int spent = 0;
  final Map<String, int> failed = <String, int>{};
  int offset = 0;
  bool done = false;
  while (!done) {
    final Map<String, Object?> j = await send(r.body('make', offset: offset, maxMicro: ceiling - spent));
    made += j['made']! as int;
    cached += j['cached']! as int;
    spent += j['spent_micro_usd']! as int;
    (j['failed']! as Map<String, Object?>).forEach((String k, Object? v) {
      failed[k] = (failed[k] ?? 0) + (v! as int);
    });
    final int next = j['next_offset']! as int;
    done = j['done']! as bool;
    say?.call('  $next of ${j['total']} lines done, ${dollars(spent)} USD spent so far');
    if (!done && next <= offset) throw const PrewarmFailed('the server made no progress; stopping');
    offset = next;
    if (spent >= ceiling) {
      say?.call('  the spending ceiling (${dollars(ceiling)} USD) was reached; stopping');
      break;
    }
  }
  return PrewarmOutcome(made: made, cached: cached, failed: failed, spentMicro: spent);
}

class Measurement {
  const Measurement({
    required this.serverMs,
    required this.modelMs,
    required this.voiceMs,
    required this.rules,
  });

  final List<int> serverMs;
  final List<int> modelMs;
  final List<int> voiceMs;
  final List<String> rules;

  static int _median(List<int> v) {
    if (v.isEmpty) return 0;
    final List<int> s = List<int>.of(v)..sort();
    return s[s.length ~/ 2];
  }

  int get medianServer => _median(serverMs);

  int get medianModel => _median(modelMs);

  int get medianVoice => _median(voiceMs);

  String describe() =>
      '${serverMs.length} fresh lines: server median $medianServer ms (model $medianModel ms, voice $medianVoice ms)'
      '${rules.isEmpty ? '' : '; fell back to the authored line ${rules.length} times: ${rules.toSet().join(', ')}'}';
}

/// Makes [count] fresh lines on the server (kept nowhere) and reports how long each part took. Capped at one
/// dollar, which is far more than ten lines cost.
Future<Measurement> measure(PrewarmSend send, PrewarmRequest r, {int count = 5}) async {
  final Map<String, Object?> j = await send(r.body('measure', count: count, maxMicro: 1000000));
  final List<Map<String, Object?>> runs = (j['runs']! as List<Object?>).cast<Map<String, Object?>>();
  return Measurement(
    serverMs: <int>[
      for (final Map<String, Object?> e in runs)
        if (e['rule'] == null) e['server_ms']! as int,
    ],
    modelMs: <int>[
      for (final Map<String, Object?> e in runs)
        if (e['rule'] == null) e['model_ms']! as int,
    ],
    voiceMs: <int>[
      for (final Map<String, Object?> e in runs)
        if (e['rule'] == null) e['voice_ms']! as int,
    ],
    rules: <String>[
      for (final Map<String, Object?> e in runs)
        if (e['rule'] != null) e['rule']! as String,
    ],
  );
}
