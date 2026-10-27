// The review-then-voice part of the pre-warm tool: a person reads the sentences the model wrote and strikes out the
// ones that are not right; this speaks exactly the rest. The server runs the ten checks on each sentence again, asks
// no model, and keeps the voiced line as a reviewed line that a later prompt change never makes unreachable.
import 'dart:convert';

import 'prewarm_lib.dart';

/// A sentence a person approved for one cell of the grid: plain Hebrew without niqqud (the server's lexicon gives
/// each word its one reading).
class ApprovedLine {
  const ApprovedLine({
    required this.item,
    required this.mistake,
    required this.hint,
    required this.band,
    required this.form,
    required this.character,
    required this.say,
  });

  factory ApprovedLine.fromJson(Map<String, Object?> j) => ApprovedLine(
    item: j['item']! as String,
    mistake: j['mistake']! as String,
    hint: j['hint']! as int,
    band: j['band']! as String,
    form: j['form']! as String,
    character: j['character']! as String,
    say: j['say']! as String,
  );

  final String item;
  final String mistake;
  final int hint;
  final String band;
  final String form;
  final String character;
  final String say;

  Map<String, Object?> toJson() => <String, Object?>{
    'item': item,
    'mistake': mistake,
    'hint': hint,
    'band': band,
    'form': form,
    'character': character,
    'say': say,
  };
}

/// The lines of an evaluation report or approval file that stay: those not marked `"passed": false` or
/// `"review": "rejected"`, for these characters.
List<ApprovedLine> readApproved(String jsonText, {required List<String> characters}) {
  final Object? doc = jsonDecode(jsonText);
  if (doc is! List<Object?>) throw const PrewarmFailed('the lines file must be a JSON list');
  return <ApprovedLine>[
    for (final Object? e in doc)
      if (e is Map<String, Object?> &&
          e['passed'] != false &&
          e['review'] != 'rejected' &&
          e['say'] is String &&
          characters.contains(e['character']))
        ApprovedLine.fromJson(e),
  ];
}

class VoiceOutcome {
  const VoiceOutcome({required this.made, required this.failed, required this.spentMicro});

  final int made;
  final List<String> failed;
  final int spentMicro;
}

/// Voice characters, estimated: the voice is paid by the character and niqqud counts, so twice the plain letters.
int estimatedVoiceChars(List<ApprovedLine> lines) =>
    lines.fold<int>(0, (int a, ApprovedLine l) => a + l.say.length * 2);

/// Voices the approved sentences, in batches of 25, with no model call. It refuses unless [confirmLines] equals the
/// number of lines, and gives the server a ceiling of one and a half times the estimate.
Future<VoiceOutcome> voiceLines(
  PrewarmSend send,
  PrewarmRequest r,
  List<ApprovedLine> lines, {
  required int? confirmLines,
  void Function(String)? say,
}) async {
  final PrewarmPlan p = await plan(send, r);
  final int chars = estimatedVoiceChars(lines);
  final int est = (chars / 1000 * p.voiceMicroPer1k).ceil();
  say?.call(
    '${lines.length} approved lines to voice (no model call): about $chars voice characters and '
    '${dollars(est)} USD (an estimate; niqqud counts as characters).',
  );
  if (lines.isEmpty) return const VoiceOutcome(made: 0, failed: <String>[], spentMicro: 0);
  if (confirmLines != lines.length) {
    throw PrewarmFailed(
      'nothing was voiced. To go ahead, run again with --confirm-lines ${lines.length} (the number of lines).',
    );
  }
  final int ceiling = (est * 3 / 2).ceil() + 1;
  int made = 0;
  int spent = 0;
  final List<String> failed = <String>[];
  for (int i = 0; i < lines.length; i += 25) {
    final List<ApprovedLine> batch = lines.sublist(i, i + 25 > lines.length ? lines.length : i + 25);
    final Map<String, Object?> j = await send(
      r.body(
        'voice',
        maxMicro: ceiling - spent,
        lines: <Map<String, Object?>>[for (final ApprovedLine l in batch) l.toJson()],
      ),
    );
    made += j['made']! as int;
    spent += j['spent_micro_usd']! as int;
    for (final Map<String, Object?> e in (j['results']! as List<Object?>).cast<Map<String, Object?>>()) {
      if (e['ok'] != true) {
        failed.add(
          '${e['item']} ${e['mistake']} ${e['band']}${e['form']}: ${e['rule']}'
          '${(e['detail'] ?? '') == '' ? '' : ' - ${e['detail']}'}',
        );
      }
    }
    say?.call('  ${i + batch.length} of ${lines.length} lines done, ${dollars(spent)} USD spent so far');
    if (spent >= ceiling) {
      say?.call('  the spending ceiling (${dollars(ceiling)} USD) was reached; stopping');
      break;
    }
  }
  return VoiceOutcome(made: made, failed: failed, spentMicro: spent);
}
