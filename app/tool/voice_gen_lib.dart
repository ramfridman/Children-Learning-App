// The working parts of `voice_gen`: exactly what is sent for each line (the request and its hash), which clips are
// new, changed or up to date, what generating them would cost, the gate before any money is spent, the ElevenLabs
// call, the conversion of its character timestamps into mouth cues, and the voice pack. Which lines and which words
// are in voice_text_lib.dart; the audition is in audition_lib.dart.
//
// This runs on the owner's PC only, never in the app. The ElevenLabs key is passed in by the command line
// (from an environment variable) and is never written anywhere.
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:nitznutz/content/pack_verify.dart';

import 'pack_builder_lib.dart';
import 'voice_text_lib.dart';

export 'voice_text_lib.dart';

/// Respells known tricky words (names, words the voice gets wrong) before they are sent.
String respelled(String text, Map<String, String> pronunciation) {
  String out = text;
  pronunciation.forEach((String from, String to) => out = out.replaceAll(from, to));
  return out;
}

// ---- what is sent ----

/// The number settings ElevenLabs knows, with the range each may take; `use_speaker_boost` is the one switch.
const Map<String, (double, double)> _settingRanges = <String, (double, double)>{
  'stability': (0, 1),
  'similarity_boost': (0, 1),
  'style': (0, 1),
  'speed': (0.7, 1.2),
};
const String _boost = 'use_speaker_boost';

/// Settings the Eleven v4 models do not use ("Style and Speed sliders are not available in Eleven v4"). They are never
/// sent to a v4 model.
const Set<String> notForV4 = <String>{'style', 'speed'};

/// The default format: 44.1 kHz, 64 kbps. The old 22.05 kHz / 32 kbps clips dull ש, ס and צ
/// (docs/audio/voice-quality-diagnosis.md, R1).
const String defaultOutputFormat = 'mp3_44100_64';

/// The models that read Hebrew (PLAN.md › Voices). Any other id is refused.
const Set<String> hebrewModels = <String>{
  'eleven_v4',
  'eleven_v4_turbo',
  'eleven_v3',
  'eleven_v3_conversational',
};

bool isV4Model(String modelId) => modelId.startsWith('eleven_v4');

void checkModel(String modelId) {
  if (!hebrewModels.contains(modelId)) {
    throw VoiceGenFailed('"$modelId" is not a model that reads Hebrew (${hebrewModels.join(', ')})');
  }
}

/// A voice id goes into the request path: letters and digits only, so no dot segment or separator can move the call.
void checkVoiceId(String voiceId) {
  if (!RegExp(r'^[A-Za-z0-9]{10,40}$').hasMatch(voiceId)) {
    throw const VoiceGenFailed('a voice id is 10 to 40 letters and digits (content/voices.json › voices)');
  }
}

/// Every clip is MP3 at 44.1 kHz and at least 64 kbps.
void checkFormat(String format) {
  if (!RegExp(r'^mp3_44100_(64|96|128|192)$').hasMatch(format)) {
    throw VoiceGenFailed(
      'the output format "$format" is not MP3 at 44.1 kHz and 64 kbps or more (for example $defaultOutputFormat)',
    );
  }
}

/// The settings sent with one line: [base] with [style] on top, key by key. Stability and similarity are always
/// explicit, so nothing depends on what is stored with the voice in the ElevenLabs account; what a v4 model does not
/// use is left out. Keys are sorted and numbers are decimals, so the same settings always give the same hash.
Map<String, Object?> settingsToSend(
  String modelId,
  Map<String, Object?> base, [
  Map<String, Object?>? style,
]) {
  final Map<String, Object?> merged = <String, Object?>{...base, ...?style};
  for (final MapEntry<String, Object?> e in merged.entries) {
    final (double, double)? range = _settingRanges[e.key];
    if (e.key == _boost) {
      if (e.value is! bool) throw VoiceGenFailed('$_boost is true or false, not ${e.value}');
    } else if (range == null) {
      throw VoiceGenFailed(
        '"${e.key}" is not a voice setting (${<String>[..._settingRanges.keys, _boost].join(', ')})',
      );
    } else if (e.value is! num ||
        !(e.value! as num).isFinite ||
        (e.value! as num) < range.$1 ||
        (e.value! as num) > range.$2) {
      throw VoiceGenFailed('${e.key} is a number from ${range.$1} to ${range.$2}, not ${e.value}');
    }
  }
  if (!merged.containsKey('stability') || !merged.containsKey('similarity_boost')) {
    throw const VoiceGenFailed(
      'the voice settings need an explicit stability and similarity_boost (content/voices.json › settings)',
    );
  }
  final List<String> keys =
      merged.keys.where((String k) => !(isV4Model(modelId) && notForV4.contains(k))).toList()..sort();
  return <String, Object?>{
    for (final String k in keys) k: merged[k] is num ? (merged[k]! as num).toDouble() : merged[k],
  };
}

/// Exactly what is sent to ElevenLabs for one clip, the key aside.
class ClipRequest {
  const ClipRequest({
    required this.text,
    required this.voiceId,
    required this.modelId,
    required this.settings,
    required this.outputFormat,
    this.languageCode = 'he',
    this.allow = const <Allowance>{},
  });

  final String text;
  final String voiceId;
  final String modelId;
  final Map<String, Object?> settings;
  final String outputFormat;
  final String languageCode;

  /// What this clip may carry beyond plain Hebrew (an audition clip only; never part of the hash).
  final Set<Allowance> allow;

  /// What ElevenLabs bills: the characters of the text, every point counted.
  int get characters => text.runes.length;

  Map<String, Object?> get body => <String, Object?>{
    'text': text,
    'model_id': modelId,
    'language_code': languageCode,
    'voice_settings': settings,
  };

  /// The SHA-256 of everything that shapes the sound: the text, voice, model, settings, language and format. A clip
  /// recorded under another hash is out of date and is made again.
  String get hash => sha256Hex(
    utf8.encode(jsonEncode(<String, Object?>{'voice': voiceId, 'format': outputFormat, ...body})),
  );

  List<TextProblem> problems(String id) => preflight(id, text, allow: allow);
}

/// How one character's lines are said, from content/voices.json: the voice, the model, the format, the usual settings,
/// the styles and the rules that pick them, and the respellings.
class VoiceProfile {
  const VoiceProfile({
    required this.voiceId,
    required this.modelId,
    required this.outputFormat,
    required this.settings,
    this.styles = const <String, Map<String, Object?>>{},
    this.styleRules = const <String, List<String>>{},
    this.pronunciation = const <String, String>{},
  });

  /// The profile of [character]. [model] replaces the configured model (an audition compares two).
  factory VoiceProfile.fromConfig(Map<String, Object?> config, String character, {String? model}) {
    final Object? voice = ((config['voices'] ?? <String, Object?>{}) as Map<String, Object?>)[character];
    if (voice is! Map<String, Object?>) {
      throw VoiceGenFailed('content/voices.json has no voice for "$character"');
    }
    final String voiceId = (voice['voiceId'] ?? '') as String;
    if (voiceId.isEmpty) throw VoiceGenFailed('"$character" has no voiceId in content/voices.json yet');
    checkVoiceId(voiceId);
    final String modelId = model ?? (config['modelId'] ?? '') as String;
    if (modelId.isEmpty) throw const VoiceGenFailed('content/voices.json has no modelId yet');
    checkModel(modelId);
    final String format = (config['outputFormat'] ?? defaultOutputFormat) as String;
    checkFormat(format);
    Map<String, Object?> map(Object? o) => (o ?? <String, Object?>{}) as Map<String, Object?>;
    final VoiceProfile p = VoiceProfile(
      voiceId: voiceId,
      modelId: modelId,
      outputFormat: format,
      settings: <String, Object?>{...map(config['settings']), ...map(voice['settings'])},
      styles: <String, Map<String, Object?>>{
        for (final MapEntry<String, Object?> e in map(config['styles']).entries) e.key: map(e.value),
      },
      styleRules: <String, List<String>>{
        for (final MapEntry<String, Object?> e in map(config['styleRules']).entries)
          e.key: <String>[for (final Object? p in e.value! as List<Object?>) p! as String],
      },
      pronunciation: <String, String>{
        for (final MapEntry<String, Object?> e in map(config['pronunciation']).entries)
          e.key: e.value! as String,
      },
    );
    // Fail now, not after the first lines were paid for.
    settingsToSend(modelId, p.settings);
    for (final String style in p.styleRules.keys) {
      final Map<String, Object?>? s = p.styles[style];
      if (s == null) {
        throw VoiceGenFailed('content/voices.json › styleRules names "$style", which has no style');
      }
      settingsToSend(modelId, p.settings, s);
    }
    return p;
  }

  /// The free test voices: no account and no model; the mock synthesizer uses only the text.
  static const VoiceProfile mock = VoiceProfile(
    voiceId: 'mock',
    modelId: 'mock',
    outputFormat: 'wav_8000',
    settings: <String, Object?>{'stability': 0.5, 'similarity_boost': 0.75},
  );

  final String voiceId;
  final String modelId;
  final String outputFormat;
  final Map<String, Object?> settings;
  final Map<String, Map<String, Object?>> styles;
  final Map<String, List<String>> styleRules;
  final Map<String, String> pronunciation;

  /// The request for [line]: its text respelled, and the usual settings with the line's style on top.
  ClipRequest requestFor(SpokenLine line) {
    final String? style = styleOf(line.voId, styleRules);
    return ClipRequest(
      text: respelled(line.text, pronunciation),
      voiceId: voiceId,
      modelId: modelId,
      settings: settingsToSend(modelId, settings, style == null ? null : styles[style]),
      outputFormat: outputFormat,
    );
  }

  /// The settings of [style] that [modelId] does not use, so the plan can say they were left out.
  List<String> droppedOf(String style) => <String>[
    for (final String k in <String>{...settings.keys, ...?styles[style]?.keys})
      if (isV4Model(modelId) && notForV4.contains(k)) k,
  ]..sort();
}

/// The name of the style a line is said in (for example `cheer` for the celebrations), by the start of its voice id, or
/// null for the usual voice. [rules] maps a style to the voice-id prefixes it covers.
String? styleOf(String voId, Map<String, List<String>> rules) {
  for (final MapEntry<String, List<String>> r in rules.entries) {
    if (r.value.any(voId.startsWith)) return r.key;
  }
  return null;
}

// ---- what was made ----

/// Whether a line's clip is still to be made, was made from another request, or is up to date.
enum ClipState { newLine, changed, unchanged }

/// What was sent for each clip of a work folder, by line id: one JSON line per clip, appended after its sound and cues
/// are written, so a run that stops loses nothing. It lives next to the work folder, not in it, because every file in
/// the work folder goes into the pack. Its name comes from the normalised absolute path, so `nitzi`, `nitzi\`,
/// `nitzi\\` and `nitzi\.` all share `nitzi.voiced.jsonl`.
class ClipLedger {
  ClipLedger(Directory workDir) : file = File('${normalisedFolder(workDir)}.voiced.jsonl');

  final File file;

  /// The hash each clip was last made from. A line cut short by a crash is skipped (its clip is made again).
  Map<String, String> hashes() {
    final Map<String, String> out = <String, String>{};
    if (!file.existsSync()) return out;
    for (final String line in file.readAsLinesSync()) {
      try {
        final Object? j = jsonDecode(line);
        if (j is Map<String, Object?> && j['id'] is String && j['hash'] is String) {
          out[j['id']! as String] = j['hash']! as String;
        }
      } on FormatException {
        continue;
      }
    }
    return out;
  }

  void record(String id, String audioFile, ClipRequest request) => file.writeAsStringSync(
    '${jsonEncode(<String, Object?>{'id': id, 'hash': request.hash, 'file': audioFile, 'characters': request.characters, 'voice': request.voiceId, 'format': request.outputFormat, ...request.body})}\n',
    mode: FileMode.append,
    flush: true,
  );
}

/// [dir] as a normalised absolute path with no trailing separator.
String normalisedFolder(Directory dir) {
  String p = dir.absolute.uri.normalizePath().toFilePath();
  while (p.length > 1 && (p.endsWith('/') || p.endsWith(r'\'))) {
    p = p.substring(0, p.length - 1);
  }
  return p;
}

/// Refuses a work folder written as `.` or `..`, or ending in one: where its clips and its ledger land would not be
/// what the command line seems to say.
void checkWorkFolder(Directory dir) {
  final List<String> parts = dir.path.split(RegExp(r'[/\\]')).where((String s) => s.isNotEmpty).toList();
  if (parts.isEmpty || parts.last == '.' || parts.last == '..') {
    throw VoiceGenFailed('the work folder "${dir.path}" must end in a folder name, not "." or ".."');
  }
}

/// Whether [file] lies inside [dir] (compared as normalised absolute paths, ignoring case on Windows).
bool isInsideFolder(File file, Directory dir) {
  String norm(String p) => Platform.isWindows ? p.toLowerCase() : p;
  final String folder = norm(normalisedFolder(dir));
  final String path = norm(File(file.absolute.uri.normalizePath().toFilePath()).path);
  return path.startsWith('$folder${Platform.pathSeparator}');
}

String _inFolder(Directory dir, String name) => '${dir.path}${Platform.pathSeparator}$name';

/// The sound file of line [id] in [workDir], if there is one.
File? _audioOf(Directory workDir, String id) {
  for (final String ext in <String>['mp3', 'wav']) {
    final File f = File(_inFolder(workDir, 'vo.$id.$ext'));
    if (f.existsSync()) return f;
  }
  return null;
}

/// The state of line [id]'s clip in [workDir], given the hashes in its ledger ([made]).
ClipState clipState(Directory workDir, String id, ClipRequest request, Map<String, String> made) {
  if (_audioOf(workDir, id) == null || !File(_inFolder(workDir, 'cue.$id.json')).existsSync()) {
    return ClipState.newLine;
  }
  return made[id] == request.hash ? ClipState.unchanged : ClipState.changed;
}

// ---- the plan ----

/// One clip of the plan: who says which line, the request, and whether it is still to be made.
class PlannedClip {
  const PlannedClip(this.character, this.line, this.request, this.state);

  final String character;
  final SpokenLine line;
  final ClipRequest request;
  final ClipState state;

  bool get toSay => state != ClipState.unchanged;
}

class VoicePlan {
  const VoicePlan({required this.characters, required this.lines, required this.clips});

  final List<String> characters;
  final List<SpokenLine> lines;
  final List<PlannedClip> clips;

  Iterable<PlannedClip> get _toSay => clips.where((PlannedClip c) => c.toSay);

  /// Characters of text still to be said, over all voices (unchanged clips are reused and cost nothing).
  int get total => _toSay.fold<int>(0, (int s, PlannedClip c) => s + c.request.characters);

  /// The most characters still to be said for one voice.
  int get perCharacter => characters
      .map((String ch) => _toSay.where((PlannedClip c) => c.character == ch))
      .map((Iterable<PlannedClip> cs) => cs.fold<int>(0, (int s, PlannedClip c) => s + c.request.characters))
      .fold<int>(0, math.max);

  int get toSay => _toSay.length;
  int get reused => clips.length - toSay;
  int count(ClipState s) => clips.where((PlannedClip c) => c.state == s).length;

  /// The texts the pre-flight check refuses, among those still to be said.
  List<TextProblem> get problems => <TextProblem>[
    for (final PlannedClip c in _toSay) ...c.request.problems(c.line.voId),
  ];

  /// The cost at [pricePer1000Chars] (the price per thousand characters of the model).
  double cost(double pricePer1000Chars) => total / 1000 * pricePer1000Chars;

  /// The summary; with [list], also every clip still to be made with the exact text it sends.
  ///
  /// [inRun] is true inside a `generate` run, which asks for the total right after: then the plan says what this run
  /// sends instead of how to start one.
  String describe(
    double pricePer1000Chars, {
    bool list = false,
    String priceSource = '',
    bool inRun = false,
  }) {
    final StringBuffer b = StringBuffer()
      ..writeln('Voices: ${characters.join(', ')}')
      ..writeln('Lines per voice: ${lines.length}');
    for (final String ch in characters) {
      final List<PlannedClip> mine = clips.where((PlannedClip c) => c.character == ch).toList();
      if (mine.isEmpty) continue;
      final ClipRequest r = mine.first.request;
      final int chars = mine
          .where((PlannedClip c) => c.toSay)
          .fold<int>(0, (int s, PlannedClip c) => s + c.request.characters);
      b.writeln(
        '  $ch (${r.modelId}, ${r.outputFormat}): '
        'new ${mine.where((PlannedClip c) => c.state == ClipState.newLine).length}, '
        'changed ${mine.where((PlannedClip c) => c.state == ClipState.changed).length}, '
        'unchanged ${mine.where((PlannedClip c) => c.state == ClipState.unchanged).length}; '
        'characters to send for this voice $chars',
      );
    }
    if (list) {
      b.writeln();
      for (final PlannedClip c in _toSay) {
        b.writeln(
          '  [${c.state == ClipState.newLine ? 'new' : 'changed'}] ${c.character} ${c.line.voId} '
          '(${c.request.characters}) ${jsonEncode(c.request.settings)}: ${c.request.text}',
        );
      }
    }
    b
      ..writeln()
      ..writeln(
        'Lines still to say, over all voices: $toSay (new ${count(ClipState.newLine)}, changed '
        '${count(ClipState.changed)}; the other $reused are unchanged and reused for free)',
      )
      ..writeln('Characters of text per voice: $perCharacter')
      ..writeln('Characters of text in total: $total')
      ..writeln(
        'Estimated cost at $pricePer1000Chars per 1,000 characters$priceSource: '
        '${cost(pricePer1000Chars).toStringAsFixed(2)}',
      );
    final List<TextProblem> refused = problems;
    if (refused.isNotEmpty) {
      b
        ..writeln()
        ..writeln(
          'The pre-flight check refuses ${refused.length} texts; generate sends nothing until they are fixed:',
        );
      for (final TextProblem p in refused) {
        b.writeln('  $p');
      }
    } else if (clips.isEmpty) {
      b
        ..writeln()
        ..writeln('Nothing to voice yet.');
    } else if (inRun) {
      b
        ..writeln()
        ..writeln(
          'This run sends the $total characters above for ${characters.join(', ')}, and nothing else.',
        );
    } else {
      b
        ..writeln()
        ..writeln(
          'generate voices one character per run. In a terminal, `generate <character>` makes this plan again for '
          'that voice alone and asks you to type its own figure ("characters to send for this voice" above, as it '
          'is at that moment): the count of exactly what that run sends.',
        );
    }
    return b.toString();
  }
}

/// The plan for every character of [profiles] saying every line of [lines]. [stateOf] tells which clips exist already
/// (none, when it is not given).
VoicePlan planVoices(
  Map<String, VoiceProfile> profiles,
  List<SpokenLine> lines, {
  ClipState Function(String character, SpokenLine line, ClipRequest request)? stateOf,
}) {
  final List<PlannedClip> clips = <PlannedClip>[
    for (final MapEntry<String, VoiceProfile> p in profiles.entries)
      for (final SpokenLine l in lines)
        () {
          final ClipRequest r = p.value.requestFor(l);
          return PlannedClip(p.key, l, r, stateOf?.call(p.key, l, r) ?? ClipState.newLine);
        }(),
  ];
  return VoicePlan(characters: profiles.keys.toList(), lines: lines, clips: clips);
}

// ---- the gate ----

/// Where the owner types the count: the keyboard of an interactive terminal. Tests pass a pretend one.
abstract interface class Keyboard {
  /// Whether a person can type here (stdin is an interactive terminal).
  bool get isTerminal;

  /// One line typed, or null at the end of the input.
  String? readLine();
}

/// The real keyboard.
class TerminalKeyboard implements Keyboard {
  const TerminalKeyboard();

  /// A console on both sides, and one that answers: on Windows Dart reports `hasTerminal` for the NUL device (an
  /// agent's shell, `< NUL`), but asking NUL for its echo mode throws.
  @override
  bool get isTerminal {
    if (!stdin.hasTerminal || !stdout.hasTerminal) return false;
    try {
      stdin.echoMode;
      return true;
    } on StdinException {
      return false;
    }
  }

  @override
  String? readLine() => stdin.readLineSync();
}

/// The first half of the gate, checked before anything is planned or printed: a paid run needs a person at an
/// interactive terminal. The refusal names no number, so a script cannot learn the count from it.
void requireTerminal(Keyboard keyboard, String what) {
  if (!keyboard.isTerminal) {
    throw VoiceGenFailed(
      '$what spends money, so it runs only in an interactive terminal, where you type the count yourself. '
      'Nothing was sent.',
    );
  }
}

/// The second half of the gate, after the plan of exactly what this run sends was printed in the same process: the
/// owner types [planned] on the keyboard. Anything else stops the run.
void requireTyped(Keyboard keyboard, int planned, String what, void Function(String) write) {
  requireTerminal(keyboard, what);
  write('To spend them on $what, type the number of characters shown above (anything else stops): ');
  final String? line;
  try {
    line = keyboard.readLine();
  } on StdinException {
    throw VoiceGenFailed(
      '$what spends money, so it runs only in an interactive terminal, and this keyboard cannot be read. '
      'Nothing was sent.',
    );
  }
  final int? typed = int.tryParse((line ?? '').trim());
  if (typed != planned) {
    throw const VoiceGenFailed('The number typed is not the total above. Nothing was sent.');
  }
}

/// Never says a word: the voice of a run in which every clip is up to date.
class _Silent implements Synthesizer {
  const _Silent();

  @override
  Future<Synthesis> say(ClipRequest request) =>
      throw const VoiceGenFailed('nothing should be said in this run');
}

/// `generate` for one character, gated: checks the terminal, plans in this process from the lines and the profile it
/// will send, prints the plan, refuses texts the pre-flight check refuses, asks the owner to type the total, and only
/// then asks for the voice ([synth], which reads the key) and makes the pack. [heading] (where the texts come from) is
/// printed above the plan, after the terminal check. When every clip is up to date it builds
/// the pack without asking for the voice or the count.
Future<BuiltPack> generateGated({
  required String characterId,
  required List<SpokenLine> lines,
  required VoiceProfile profile,
  required Directory workDir,
  required PackKey key,
  required Keyboard keyboard,
  required Synthesizer Function() synth,
  required void Function(String) write,
  double pricePer1000Chars = 0,
  String priceSource = '',
  String heading = '',
  String version = '1.0.0',
}) async {
  requireTerminal(keyboard, 'generate');
  if (heading.isNotEmpty) write(heading);
  checkWorkFolder(workDir);
  final Map<String, String> made = ClipLedger(workDir).hashes();
  final VoicePlan plan = planVoices(
    <String, VoiceProfile>{characterId: profile},
    lines,
    stateOf: (String c, SpokenLine l, ClipRequest r) => clipState(workDir, l.fileId, r, made),
  );
  write(plan.describe(pricePer1000Chars, priceSource: priceSource, inRun: true));
  final List<TextProblem> refused = plan.problems;
  if (refused.isNotEmpty) {
    throw VoiceGenFailed(
      'the pre-flight check refuses ${refused.length} texts. Nothing was sent:\n${refused.join('\n')}',
    );
  }
  final Synthesizer voice;
  if (plan.total == 0) {
    voice = const _Silent();
  } else {
    requireTyped(keyboard, plan.total, 'voicing $characterId', write);
    voice = synth();
  }
  return generateVoicePack(
    characterId: characterId,
    lines: lines,
    synth: voice,
    profile: profile,
    key: key,
    workDir: workDir,
    version: version,
    progress: write,
  );
}

// ---- mouth cues ----

/// What ElevenLabs returns with the audio: each character and when it starts and ends, in seconds.
class Alignment {
  const Alignment(this.characters, this.starts, this.ends);

  factory Alignment.fromJson(Map<String, Object?> j) => Alignment(
    <String>[for (final Object? c in j['characters']! as List<Object?>) c! as String],
    <double>[
      for (final Object? t in j['character_start_times_seconds']! as List<Object?>) (t! as num).toDouble(),
    ],
    <double>[
      for (final Object? t in j['character_end_times_seconds']! as List<Object?>) (t! as num).toDouble(),
    ],
  );

  final List<String> characters;
  final List<double> starts;
  final List<double> ends;
}

bool _isLetter(int r) => r >= 0x05D0 && r <= 0x05EA;
bool _isPoint(int r) => r >= 0x05B0 && r <= 0x05C7;

/// Points that open the mouth: all vowels except the silent shva (U+05B0). Holam (U+05B9) and qubuts (U+05BB) round it,
/// still open. Dagesh and the shin and sin dots (U+05BC to U+05C2) are not vowels.
bool _opens(int r) => r >= 0x05B1 && r <= 0x05BB;

/// Turns the alignment into cues. Each letter with its points forms a syllable-like group. In a word with points, a
/// group with a vowel point holds the mouth open from its start to its end, and a bare consonant or a shva leaves it
/// closed. The voice texts are mostly plain (points only on a word with two readings), so in a word without any point
/// every other letter opens the mouth, starting with the first: Hebrew syllables are mostly one consonant and a vowel,
/// so this follows the rhythm of the word. Pauses, spaces and punctuation leave it closed.
List<(int, int)> cuesFromAlignment(Alignment a) {
  int rune(int i) => a.characters[i].isEmpty ? 0x20 : a.characters[i].runes.first;
  final int n = a.characters.length;
  final List<(int, bool)> raw = <(int, bool)>[];
  int i = 0;
  while (i < n) {
    if (!_isLetter(rune(i)) && !_isPoint(rune(i))) {
      i++;
      continue;
    }
    // One word: the letters and points up to the next other character.
    int wordEnd = i;
    bool plainWord = true;
    while (wordEnd < n && (_isLetter(rune(wordEnd)) || _isPoint(rune(wordEnd)))) {
      if (_isPoint(rune(wordEnd))) plainWord = false;
      wordEnd++;
    }
    int plainLetter = 0;
    int k = i;
    while (k < wordEnd) {
      if (!_isLetter(rune(k))) {
        k++;
        continue;
      }
      final double start = a.starts[k];
      double end = a.ends[k];
      bool open = false;
      int j = k + 1;
      while (j < wordEnd && _isPoint(rune(j))) {
        if (_opens(rune(j))) open = true;
        end = math.max(end, a.ends[j]);
        j++;
      }
      if (plainWord) open = (plainLetter++).isEven;
      if (open) {
        raw
          ..add(((start * 1000).round(), true))
          ..add(((end * 1000).round(), false));
      }
      k = j;
    }
    i = wordEnd;
  }
  // Keep times strictly increasing and drop switches that change nothing.
  final List<(int, int)> out = <(int, int)>[];
  int last = -1;
  bool state = false;
  for (final (int, bool) c in raw) {
    int t = c.$1;
    if (t <= last) t = last + 1;
    if (c.$2 == state) continue;
    out.add((t, c.$2 ? 1 : 0));
    state = c.$2;
    last = t;
  }
  return out.length > 600 ? out.sublist(0, 600) : out;
}

// ---- the voices ----

/// A synthesised line: the sound, its file extension, and the alignment of its characters.
class Synthesis {
  const Synthesis(this.audio, this.extension, this.alignment);

  final Uint8List audio;
  final String extension;
  final Alignment alignment;
}

abstract interface class Synthesizer {
  /// Says what [request] asks for.
  Future<Synthesis> say(ClipRequest request);
}

/// Free test voices: a tone whose pitch depends on the character, switched on while a vowel is spoken,
/// with the alignment the real service would give (about 80 ms a character). Used by tests and to hear the app
/// before real voices exist. It makes WAV files (8 kHz, 8 bit) to keep them small.
class MockSynthesizer implements Synthesizer {
  MockSynthesizer(String characterId)
    : pitch = 180 + (characterId.runes.fold<int>(7, (int a, int r) => (a * 31 + r) & 0xFFFF) % 240);

  final double pitch;
  static const int _rate = 8000;
  static const double _perChar = 0.08;

  @override
  Future<Synthesis> say(ClipRequest request) async {
    final List<String> chars = request.text.split('');
    final List<double> starts = <double>[for (int i = 0; i < chars.length; i++) i * _perChar];
    final List<double> ends = <double>[for (int i = 0; i < chars.length; i++) (i + 1) * _perChar];
    final Alignment al = Alignment(chars, starts, ends);
    final int n = (chars.length * _perChar * _rate).round() + _rate ~/ 4;
    final Uint8List pcm = Uint8List(n)..fillRange(0, n, 128);
    final List<(int, int)> cues = cuesFromAlignment(al);
    for (int k = 0; k < cues.length; k += 2) {
      final int from = (cues[k].$1 / 1000 * _rate).round();
      final int to = k + 1 < cues.length ? (cues[k + 1].$1 / 1000 * _rate).round() : n;
      for (int s = from; s < to && s < n; s++) {
        pcm[s] = (128 + 60 * math.sin(2 * math.pi * pitch * s / _rate)).round();
      }
    }
    return Synthesis(_wav(pcm), 'wav', al);
  }

  Uint8List _wav(Uint8List pcm) {
    final ByteData h = ByteData(44);
    void s(int at, String t) {
      for (int i = 0; i < 4; i++) {
        h.setUint8(at + i, t.codeUnitAt(i));
      }
    }

    s(0, 'RIFF');
    h.setUint32(4, 36 + pcm.length, Endian.little);
    s(8, 'WAVE');
    s(12, 'fmt ');
    h.setUint32(16, 16, Endian.little);
    h.setUint16(20, 1, Endian.little);
    h.setUint16(22, 1, Endian.little);
    h.setUint32(24, _rate, Endian.little);
    h.setUint32(28, _rate, Endian.little);
    h.setUint16(32, 1, Endian.little);
    h.setUint16(34, 8, Endian.little);
    s(36, 'data');
    h.setUint32(40, pcm.length, Endian.little);
    return Uint8List.fromList(<int>[...h.buffer.asUint8List(), ...pcm]);
  }
}

/// The one host the voice is made at. Fixed in code: tests replace the HTTP client, never the host.
const String elevenLabsHost = 'api.elevenlabs.io';

/// ElevenLabs text to speech with timestamps. Tests pass a mock [client].
///
/// The key is checked before anything else: printable ASCII only, so that it can never break a header and be echoed
/// in an error. A request follows no redirect (the key header would go along to another host) and waits at most
/// [timeout]. Any failure becomes a [VoiceGenFailed] that says the status or the kind of error only: never the key,
/// never the answer's body.
class ElevenLabsSynthesizer implements Synthesizer {
  ElevenLabsSynthesizer({
    required this.apiKey,
    http.Client? client,
    this.timeout = const Duration(seconds: 60),
  }) : _client = client {
    checkApiKey(apiKey);
  }

  final String apiKey;
  final http.Client? _client;
  final Duration timeout;

  @override
  Future<Synthesis> say(ClipRequest request) async {
    // The last line of defence: whatever path a request took, it is checked again right before it is sent.
    final List<TextProblem> problems = request.problems('the text');
    if (problems.isNotEmpty) throw VoiceGenFailed('not sent: ${problems.join('; ')}');
    checkModel(request.modelId);
    checkFormat(request.outputFormat);
    checkVoiceId(request.voiceId);
    final http.Client client = _client ?? http.Client();
    try {
      final http.Request req =
          http.Request(
              'POST',
              Uri.https(
                elevenLabsHost,
                '/v1/text-to-speech/${request.voiceId}/with-timestamps',
                <String, String>{'output_format': request.outputFormat},
              ),
            )
            ..followRedirects = false
            ..headers.addAll(<String, String>{'xi-api-key': apiKey, 'content-type': 'application/json'})
            ..bodyBytes = utf8.encode(jsonEncode(request.body));
      final http.Response res = await http.Response.fromStream(await client.send(req).timeout(timeout))
          .timeout(timeout);
      if (res.statusCode != 200) {
        // The body of an error can echo the request; show the status only.
        throw VoiceGenFailed('ElevenLabs answered ${res.statusCode}');
      }
      final Map<String, Object?> json = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, Object?>;
      return Synthesis(
        base64Decode(json['audio_base64']! as String),
        'mp3',
        Alignment.fromJson((json['alignment'] ?? json['normalized_alignment'])! as Map<String, Object?>),
      );
    } on VoiceGenFailed {
      rethrow;
    } on TimeoutException {
      throw VoiceGenFailed('ElevenLabs did not answer within ${timeout.inSeconds} s');
    } catch (e) {
      // Only the kind of error: a message could quote a header, and so the key.
      throw VoiceGenFailed('the call to ElevenLabs failed (${e.runtimeType})');
    } finally {
      if (_client == null) client.close();
    }
  }
}

/// Refuses a key that is not 1 to 200 printable ASCII characters (a line break, a space or a non-ASCII letter), by the
/// name of its variable and without showing it.
void checkApiKey(String key) {
  if (!RegExp(r'^[!-~]{1,200}$').hasMatch(key)) {
    throw const VoiceGenFailed(
      'ELEVENLABS_API_KEY is not a plain key: it must be printable ASCII, with no space or line break. '
      'It was not used, and it is not shown here.',
    );
  }
}

// ---- making the voice pack ----

/// Says every line in [lines] whose clip is new or changed, and builds the signed voice pack of [characterId]. Writes
/// the sources to [workDir] first and records each clip's hash in its [ClipLedger], so that a run that stops can be
/// continued, and a line whose text, voice, model, settings or format changed is said again. Refuses before sending
/// anything if a text fails the pre-flight check.
Future<BuiltPack> generateVoicePack({
  required String characterId,
  required List<SpokenLine> lines,
  required Synthesizer synth,
  required VoiceProfile profile,
  required PackKey key,
  required Directory workDir,
  String version = '1.0.0',
  void Function(String)? progress,
}) async {
  final List<ClipRequest> requests = <ClipRequest>[for (final SpokenLine l in lines) profile.requestFor(l)];
  final List<TextProblem> problems = <TextProblem>[
    for (int i = 0; i < lines.length; i++) ...requests[i].problems(lines[i].voId),
  ];
  if (problems.isNotEmpty) {
    throw VoiceGenFailed(
      'the pre-flight check refuses ${problems.length} texts. Nothing was sent:\n${problems.join('\n')}',
    );
  }
  checkWorkFolder(workDir);
  final ClipLedger ledger = ClipLedger(workDir);
  if (isInsideFolder(ledger.file, workDir)) {
    throw VoiceGenFailed('the hashes of ${workDir.path} would land inside it. Nothing was sent.');
  }
  workDir.createSync(recursive: true);
  final Map<String, String> made = ledger.hashes();
  final List<Map<String, String>> vo = <Map<String, String>>[];
  for (int i = 0; i < lines.length; i++) {
    final String id = lines[i].fileId;
    final ClipRequest request = requests[i];
    if (clipState(workDir, id, request, made) != ClipState.unchanged) {
      final Synthesis s = await synth.say(request);
      // The old sound goes only once the new one is here (it may have had the other extension).
      _audioOf(workDir, id)?.deleteSync();
      File(_inFolder(workDir, 'vo.$id.${s.extension}')).writeAsBytesSync(s.audio);
      File(_inFolder(workDir, 'cue.$id.json')).writeAsStringSync(
        jsonEncode(<String, Object?>{
          'schema': 'cue/v1',
          'id': id,
          'cues': <Object?>[
            for (final (int, int) c in cuesFromAlignment(s.alignment))
              <String, Object?>{'t': c.$1, 'o': c.$2},
          ],
        }),
      );
      ledger.record(id, 'vo.$id.${s.extension}', request);
      progress?.call('said $id');
    }
    vo.add(<String, String>{'id': id, 'file': _audioOf(workDir, id)!.uri.pathSegments.last});
  }
  File(_inFolder(workDir, 'pack.json')).writeAsStringSync(
    jsonEncode(<String, Object?>{
      'schema': 'pack-source/v1',
      'id': 'voice-$characterId',
      'version': version,
      'minAppVersion': '0.3.0',
      'assets': <Object?>[],
      'vo': vo,
    }),
  );
  return buildPack(workDir, key);
}

/// Whether any file under [dir] contains [secret] (used by tests: the key must never be written anywhere).
bool anyFileContains(Directory dir, String secret) {
  final List<int> needle = utf8.encode(secret);
  for (final FileSystemEntity e in dir.listSync(recursive: true)) {
    if (e is! File) continue;
    final Uint8List b = e.readAsBytesSync();
    for (int i = 0; i + needle.length <= b.length; i++) {
      int k = 0;
      while (k < needle.length && b[i + k] == needle[k]) {
        k++;
      }
      if (k == needle.length) return true;
    }
  }
  return false;
}

/// Pack contents of a voice pack, for a quick look.
Future<String> describeVoicePack(Uint8List bytes, Uint8List publicKey) async {
  final VerifiedPack p = await verifyPack(bytes, publicKey: publicKey);
  return '${p.id} ${p.version}: ${(p.manifest['vo']! as List<Object?>).length} lines';
}
