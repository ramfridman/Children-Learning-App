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
    this.evalMicro = 0,
    this.movesTags = 0,
  });

  factory PrewarmPlan.from(Map<String, Object?> j) => PrewarmPlan(
    lines: j['lines']! as int,
    cached: j['cached']! as int,
    toMake: j['to_make']! as int,
    estMicro: j['est_micro_usd']! as int,
    voiceChars: j['est_voice_chars']! as int,
    evalMicro: j['est_eval_micro_usd'] as int? ?? 0,
    movesTags: j['moves_tags'] as int? ?? 0,
  );

  final int lines;
  final int cached;
  final int toMake;
  final int estMicro;
  final int voiceChars;

  /// The model only (no voice), two attempts at most for every line of the grid.
  final int evalMicro;

  /// How many mistake types have teaching moves on the server (0 means the prompts carry none).
  final int movesTags;

  String get _movesNote => 'Teaching moves loaded on the server for $movesTags mistake types.';

  /// What the owner reads before saying yes to an evaluation.
  String describeEvaluation() =>
      '$lines lines to evaluate with the model only (no voice, nothing kept): at most ${dollars(evalMicro)} USD '
      '(an estimate: two attempts for every line). $_movesNote';

  /// What the owner reads before saying yes.
  String describe() =>
      '$lines lines in all, $cached already made, $toMake to make: about $voiceChars voice characters and '
      '${dollars(estMicro)} USD (an estimate, from the prices in the server config). $_movesNote';
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
    this.notes = const <String>[],
  });

  final List<int> serverMs;
  final List<int> modelMs;
  final List<int> voiceMs;
  final List<String> rules;

  /// One line per fallback, with the time the model and the voice had taken when it gave up.
  final List<String> notes;

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
      '${rules.isEmpty ? '' : '; fell back to the authored line ${rules.length} times: ${(notes.isEmpty ? rules : notes).join('; ')}'}';
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
    notes: <String>[
      for (final Map<String, Object?> e in runs)
        if (e['rule'] != null)
          '${e['rule']}${e['detail'] == null ? '' : ' - ${e['detail']}'} '
              '(model ${e['model_ms'] ?? 0} ms, voice ${e['voice_ms'] ?? 0} ms, total ${e['server_ms'] ?? 0} ms)',
    ],
  );
}

/// The result of asking the model for every line of the grid, without voice: how often the ten checks pass, which
/// ones refuse, and which words the model reached for that the lexicon does not have.
class LineEvaluation {
  LineEvaluation(this.rows, this.spentMicro);

  final List<Map<String, Object?>> rows;
  final int spentMicro;

  int get lines => rows.length;

  bool _b(Map<String, Object?> r, String k) => r[k] == true;

  int get firstTry => rows.where((Map<String, Object?> r) => _b(r, 'firstTry')).length;

  int get passed => rows.where((Map<String, Object?> r) => _b(r, 'passed')).length;

  /// How many lines each check refused at least once (in any attempt).
  Map<String, int> get refusedBy {
    final Map<String, int> out = <String, int>{};
    for (final Map<String, Object?> r in rows) {
      for (final Object? c in (r['checks'] as List<Object?>? ?? const <Object?>[])) {
        out[c! as String] = (out[c] ?? 0) + 1;
      }
    }
    return out;
  }

  /// The plain words with no single reading, most often reached for first.
  List<MapEntry<String, int>> get unknownWords {
    final Map<String, int> out = <String, int>{};
    for (final Map<String, Object?> r in rows) {
      for (final Object? w in (r['unknown'] as List<Object?>? ?? const <Object?>[])) {
        out[w! as String] = (out[w] ?? 0) + 1;
      }
    }
    return out.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
  }

  int get failedOutright => rows.where((Map<String, Object?> r) => r['rule'] != null).length;

  String describe({int topWords = 40}) {
    final String pct = lines == 0 ? '0' : (100 * passed / lines).toStringAsFixed(0);
    final String pct1 = lines == 0 ? '0' : (100 * firstTry / lines).toStringAsFixed(0);
    return 'evaluated $lines lines for ${dollars(spentMicro)} USD: $passed passed the ten checks ($pct%), '
        '$firstTry on the first try ($pct1%)'
        '${failedOutright == 0 ? '' : ', $failedOutright could not be asked (model failed)'}.\n'
        'lines refused by each check (any attempt): $refusedBy\n'
        'words the model used that the lexicon lacks (word x times): '
        '${unknownWords.take(topWords).map((MapEntry<String, int> e) => '${e.key} x${e.value}').join(', ')}';
  }
}

/// Asks the model for the lines of the grid (no voice, nothing kept), in batches. It refuses to start unless
/// [confirmLines] equals the number of lines, and gives the server a ceiling of one and a half times the estimate.
Future<LineEvaluation> evaluate(
  PrewarmSend send,
  PrewarmRequest r, {
  required int? confirmLines,
  void Function(String)? say,
}) async {
  final PrewarmPlan p = await plan(send, r);
  say?.call(p.describeEvaluation());
  if (confirmLines != p.lines) {
    throw PrewarmFailed(
      'nothing was asked. To go ahead, run again with --confirm-lines ${p.lines} (the number of lines to evaluate).',
    );
  }
  final int ceiling = (p.evalMicro * 3 / 2).ceil() + 1;
  final List<Map<String, Object?>> rows = <Map<String, Object?>>[];
  int spent = 0;
  int offset = 0;
  bool done = p.lines == 0;
  while (!done) {
    final Map<String, Object?> j = await send(r.body('evaluate', offset: offset, maxMicro: ceiling - spent));
    rows.addAll((j['rows']! as List<Object?>).cast<Map<String, Object?>>());
    spent += j['spent_micro_usd']! as int;
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
  return LineEvaluation(rows, spent);
}
