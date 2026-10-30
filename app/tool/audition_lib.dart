// The gated audition: a spec file lists a few clips to hear side by side. `plan` prints every clip (id, exact text,
// model, settings, characters) and the total and cost, and writes nothing. `run` works only in an interactive
// terminal: in the same process it plans the clips it will send, prints that plan, and makes them only when the owner
// types its total on the keyboard. So the spec, the model and the price cannot change between what he read and what is
// sent. The one-text `audition` command goes through the same gate. One clip may be at most 300 characters.
//
// The spec format (schema audition/v1; a tiny example with mock texts is tool/audition_example.json):
//
//   {
//     "schema": "audition/v1",
//     "title": "what this round decides",
//     "review": "needs-editor",
//     "defaults": { "character": "nitzi", "model": "eleven_v4_turbo", "format": "mp3_44100_64",
//                   "settings": { "stability": 0.5, "similarity_boost": 0.75, "use_speaker_boost": true } },
//     "clips": [
//       { "id": "L1v-turbo", "text": "איפה הפרח האדום?", "tests": "P1" },
//       { "id": "L1v-v4", "text": "איפה הפרח האדום?", "model": "eleven_v4" },
//       { "id": "L4x", "text": "כל הכבוד!", "allow": ["exclamation"] },
//       { "id": "L2v", "line": "vo:count.butterflies.3.prompt", "from": "voice_text" },
//       { "id": "L2p", "line": "vo:count.butterflies.3.prompt", "from": "caption", "allow": ["exclamation", "rare-points"] }
//     ]
//   }
//
// A clip has either "text" (sent exactly as written) or "line" and "from": "voice_text" is the master table's spoken
// text of that line, respelled as the packs are; "caption" is today's screen caption, to compare with the old clips.
// "character", "model", "format" and "settings" replace the defaults (settings key by key, over the usual settings of
// content/voices.json); every clip is still sent with an explicit stability and similarity, never with style or speed
// on a v4 model, and only at 44.1 kHz. "allow" lets one clip carry what packs never may: "exclamation" (!),
// "rare-points" (U+05C7, U+05B3), "ipa" (one /…/ word of IPA letters), "audio-tags" (a tag of the closed list
// `audioTags` in voice_text_lib.dart, like [gently]), "line-breaks" (several lines in one clip). Digits, placeholders,
// markup and look-alike signs never pass. "tests" and "note" are free text for the listener. Clip ids are file names:
// letters, digits, dot, dash and underscore, and no name Windows reserves.
//
// Each clip is written to the output folder as <id>.mp3 with <id>.json beside it (what was sent and its hash); a clip
// whose .json has the same hash is not made, or paid for, again.
import 'dart:convert';
import 'dart:io';

import 'package:nitznutz/content/zip_store.dart' show unsafeNameReason;

import 'voice_gen_lib.dart';

const String auditionSchema = 'audition/v1';

/// The longest text one audition clip may send: an audition compares a few short lines, it does not voice a lesson.
const int maxAuditionClipCharacters = 300;

/// One clip of an audition, resolved: who says it and exactly what is sent.
class AuditionClip {
  const AuditionClip({
    required this.id,
    required this.character,
    required this.request,
    required this.source,
    this.dropped = const <String>[],
    this.tests = '',
    this.note = '',
  });

  final String id;
  final String character;
  final ClipRequest request;

  /// Where the text came from: `text`, or `voice_text of vo:...` / `caption of vo:...`.
  final String source;

  /// Settings left out because the model does not use them (style and speed on v4).
  final List<String> dropped;
  final String tests;
  final String note;
}

/// The texts a "line" clip can refer to: the master table's voice_text and the screen caption of each voice id.
class LineTexts {
  const LineTexts({this.voiceText = const <String, String>{}, this.caption = const <String, String>{}});

  final Map<String, String> voiceText;
  final Map<String, String> caption;
}

const Set<String> _specKeys = <String>{'schema', 'title', 'note', 'review', 'defaults', 'clips'};
const Set<String> _defaultKeys = <String>{'character', 'model', 'format', 'settings'};
const Set<String> _clipKeys = <String>{
  'id',
  'character',
  'model',
  'format',
  'settings',
  'text',
  'line',
  'from',
  'allow',
  'tests',
  'note', //
};
final RegExp _clipId = RegExp(r'^[A-Za-z0-9][A-Za-z0-9._-]{0,59}$');

void _onlyKeys(Map<String, Object?> m, Set<String> known, String where) {
  final List<String> unknown = m.keys.where((String k) => !known.contains(k)).toList();
  if (unknown.isNotEmpty) {
    throw VoiceGenFailed('$where has unknown keys ${unknown.join(', ')} (known: ${known.join(', ')})');
  }
}

T _as<T>(Object? v, String what) {
  if (v is T) return v;
  throw VoiceGenFailed('$what has the wrong type');
}

/// Reads and checks an audition spec. [config] is content/voices.json; [lines] resolves "line" clips (needed only when
/// the spec has some).
List<AuditionClip> readAuditionSpec(
  Map<String, Object?> spec, {
  required Map<String, Object?> config,
  LineTexts lines = const LineTexts(),
}) {
  _onlyKeys(spec, _specKeys, 'the spec');
  if (spec['schema'] != auditionSchema) {
    throw const VoiceGenFailed('the spec\'s schema must be "$auditionSchema"');
  }
  final Map<String, Object?> defaults = _as<Map<String, Object?>>(
    spec['defaults'] ?? <String, Object?>{},
    'defaults',
  );
  _onlyKeys(defaults, _defaultKeys, 'defaults');
  final List<Object?> raw = _as<List<Object?>>(spec['clips'], 'clips');
  if (raw.isEmpty) throw const VoiceGenFailed('the spec has no clips');
  final Set<String> ids = <String>{};
  final List<AuditionClip> out = <AuditionClip>[];
  for (final Object? c in raw) {
    final Map<String, Object?> clip = _as<Map<String, Object?>>(c, 'a clip');
    final String id = _as<String>(clip['id'], 'a clip id');
    if (!_clipId.hasMatch(id) || unsafeNameReason('$id.mp3') != null) {
      throw VoiceGenFailed('the clip id "$id" is not a plain file name');
    }
    if (!ids.add(id.toLowerCase())) throw VoiceGenFailed('the clip id "$id" is used twice');
    _onlyKeys(clip, _clipKeys, 'clip $id');
    out.add(_clip(id, clip, defaults, config, lines));
  }
  return out;
}

AuditionClip _clip(
  String id,
  Map<String, Object?> clip,
  Map<String, Object?> defaults,
  Map<String, Object?> config,
  LineTexts lines,
) {
  String? pick(String key) => _as<String?>(clip[key] ?? defaults[key], 'clip $id › $key');
  final String? character = pick('character');
  if (character == null) throw VoiceGenFailed('clip $id has no character');
  final VoiceProfile profile = VoiceProfile.fromConfig(config, character, model: pick('model'));
  final String format = pick('format') ?? profile.outputFormat;
  checkFormat(format);
  final Map<String, Object?> asked = <String, Object?>{
    ...profile.settings,
    ..._as<Map<String, Object?>>(defaults['settings'] ?? <String, Object?>{}, 'defaults › settings'),
    ..._as<Map<String, Object?>>(clip['settings'] ?? <String, Object?>{}, 'clip $id › settings'),
  };

  final String? text = _as<String?>(clip['text'], 'clip $id › text');
  final String? line = _as<String?>(clip['line'], 'clip $id › line');
  if ((text == null) == (line == null)) throw VoiceGenFailed('clip $id needs either "text" or "line"');
  final String sent;
  final String source;
  if (text != null) {
    if (clip.containsKey('from')) throw VoiceGenFailed('clip $id: "from" goes with "line" only');
    sent = text;
    source = 'text';
  } else {
    final String from = _as<String?>(clip['from'], 'clip $id › from') ?? '';
    final String? found = switch (from) {
      'voice_text' => lines.voiceText[line],
      'caption' => lines.caption[line],
      _ => throw VoiceGenFailed('clip $id: "from" is "voice_text" or "caption", not "$from"'),
    };
    if (found == null || found.isEmpty) throw VoiceGenFailed('clip $id: $line has no $from');
    sent = from == 'voice_text' ? respelled(found, profile.pronunciation) : found;
    source = '$from of $line';
  }
  if (sent.runes.length > maxAuditionClipCharacters) {
    throw VoiceGenFailed(
      'clip $id has ${sent.runes.length} characters; an audition clip has at most $maxAuditionClipCharacters',
    );
  }
  return AuditionClip(
    id: id,
    character: character,
    request: ClipRequest(
      text: sent,
      voiceId: profile.voiceId,
      modelId: profile.modelId,
      settings: settingsToSend(profile.modelId, asked),
      outputFormat: format,
      allow: <Allowance>{
        for (final Object? a in _as<List<Object?>>(clip['allow'] ?? <Object?>[], 'clip $id › allow'))
          Allowance.parse(_as<String>(a, 'clip $id › allow')),
      },
    ),
    source: source,
    dropped: <String>[
      for (final String k in asked.keys)
        if (isV4Model(profile.modelId) && notForV4.contains(k)) k,
    ],
    tests: _as<String?>(clip['tests'], 'clip $id › tests') ?? '',
    note: _as<String?>(clip['note'], 'clip $id › note') ?? '',
  );
}

/// The clips of [clips] already made in [out] from the same request (read only; nothing is created).
Set<String> madeAuditionClips(List<AuditionClip> clips, Directory out) => <String>{
  for (final AuditionClip c in clips)
    if (_recordedHash(out, c.id) == c.request.hash && File(_path(out, '${c.id}.mp3')).existsSync()) c.id,
};

String _path(Directory dir, String name) => '${dir.path}${Platform.pathSeparator}$name';

String? _recordedHash(Directory out, String id) {
  final File f = File(_path(out, '$id.json'));
  if (!f.existsSync()) return null;
  try {
    final Object? j = jsonDecode(f.readAsStringSync());
    return j is Map<String, Object?> && j['hash'] is String ? j['hash']! as String : null;
  } on FormatException {
    return null;
  }
}

/// What an audition would send and cost.
class AuditionPlan {
  const AuditionPlan({required this.title, required this.clips, this.made = const <String>{}});

  final String title;
  final List<AuditionClip> clips;

  /// Clips already made from the same request: not sent, not counted.
  final Set<String> made;

  Iterable<AuditionClip> get toMake => clips.where((AuditionClip c) => !made.contains(c.id));

  /// The characters still to send: the number the owner types at the keyboard.
  int get total => toMake.fold<int>(0, (int s, AuditionClip c) => s + c.request.characters);

  /// Characters still to send, by model.
  Map<String, int> get byModel {
    final Map<String, int> out = <String, int>{};
    for (final AuditionClip c in toMake) {
      out[c.request.modelId] = (out[c.request.modelId] ?? 0) + c.request.characters;
    }
    return out;
  }

  /// What the pre-flight check refuses among the clips still to make.
  List<TextProblem> get problems => <TextProblem>[
    for (final AuditionClip c in toMake) ...c.request.problems(c.id),
  ];

  /// The cost, with [pricePer1000] giving the price per 1,000 characters of each model (0 when unknown).
  double cost(double Function(String model) pricePer1000) => byModel.entries.fold<double>(
    0,
    (double s, MapEntry<String, int> e) => s + e.value / 1000 * pricePer1000(e.key),
  );

  /// [inRun] is true inside `run`, which asks for the total right after the plan.
  String describe(
    double Function(String model) pricePer1000, {
    String runCommand = 'audition-batch run <spec>',
    bool inRun = false,
  }) {
    final StringBuffer b = StringBuffer()..writeln('Audition: $title');
    for (final AuditionClip c in clips) {
      final ClipRequest r = c.request;
      b
        ..writeln()
        ..writeln(
          '${c.id}${made.contains(c.id) ? ' (already made, not sent again)' : ''}: ${c.character}, ${r.modelId}, '
          '${r.outputFormat}, ${jsonEncode(r.settings)}, ${r.characters} characters',
        )
        ..writeln('  text (${c.source}): ${r.text}');
      if (c.dropped.isNotEmpty) b.writeln('  not sent, ${r.modelId} does not use: ${c.dropped.join(', ')}');
      if (r.allow.isNotEmpty) {
        b.writeln('  allowed in this clip: ${r.allow.map((Allowance a) => a.key).join(', ')}');
      }
      if (c.tests.isNotEmpty) b.writeln('  tests: ${c.tests}');
      if (c.note.isNotEmpty) b.writeln('  note: ${c.note}');
    }
    b
      ..writeln()
      ..writeln('Clips to make: ${toMake.length} of ${clips.length}')
      ..writeln(
        'Characters by model: ${byModel.entries.map((MapEntry<String, int> e) => '${e.key} ${e.value}').join(', ')}',
      )
      ..writeln('Characters of text in total: $total');
    final double price = cost(pricePer1000);
    b.writeln(
      price == 0
          ? 'Cost: unknown (no price for these models in content/voices.json; pass --price)'
          : 'Estimated cost at list prices: ${price.toStringAsFixed(price < 1 ? 4 : 2)} USD '
                '(your ElevenLabs plan may differ)',
    );
    final List<TextProblem> refused = problems;
    if (refused.isNotEmpty) {
      b.writeln(
        'The pre-flight check refuses ${refused.length} texts; run sends nothing until they are fixed:',
      );
      for (final TextProblem p in refused) {
        b.writeln('  $p');
      }
    } else if (total > 0 && inRun) {
      b.writeln('Type the total below to make them; anything else stops and sends nothing.');
    } else if (total > 0) {
      b.writeln(
        'Nothing was sent. To make them, run in a terminal:  $runCommand  (it plans again, shows this plan and asks '
        'you to type the total)',
      );
    }
    return b.toString();
  }
}

/// Makes the clips of [plan] that are not made yet, into [out]. Only at an interactive terminal: the plan is printed
/// with [write], every text must pass the pre-flight check, and the owner must type the plan's total on [keyboard];
/// [synth] is asked for only after that (so the key is read only then). [heading] (where the texts come from) is printed
/// above the plan, after the terminal check. Returns the files written.
Future<List<File>> runAudition(
  AuditionPlan plan, {
  required Keyboard keyboard,
  required Synthesizer Function() synth,
  required Directory out,
  required void Function(String) write,
  double Function(String model) pricePer1000 = _unknownPrice,
  String runCommand = 'audition-batch run <spec>',
  String heading = '',
}) async {
  if (plan.total == 0) {
    write('Every clip is made already; nothing to send.');
    return <File>[];
  }
  requireTerminal(keyboard, 'this audition');
  if (heading.isNotEmpty) write(heading);
  write(plan.describe(pricePer1000, runCommand: runCommand, inRun: true));
  final List<TextProblem> refused = plan.problems;
  if (refused.isNotEmpty) {
    throw VoiceGenFailed(
      'the pre-flight check refuses ${refused.length} texts. Nothing was sent:\n${refused.join('\n')}',
    );
  }
  requireTyped(keyboard, plan.total, 'this audition', write);
  final Synthesizer voice = synth();
  out.createSync(recursive: true);
  final List<File> written = <File>[];
  for (final AuditionClip c in plan.toMake) {
    final Synthesis s = await voice.say(c.request);
    final File audio = File(_path(out, '${c.id}.${s.extension}'))..writeAsBytesSync(s.audio);
    File(_path(out, '${c.id}.json')).writeAsStringSync(
      '${const JsonEncoder.withIndent('  ').convert(<String, Object?>{'id': c.id, 'hash': c.request.hash, 'character': c.character, 'source': c.source, 'characters': c.request.characters, 'voice': c.request.voiceId, 'format': c.request.outputFormat, ...c.request.body})}\n',
    );
    written.add(audio);
    write('made ${audio.path}');
  }
  return written;
}

double _unknownPrice(String model) => 0;
