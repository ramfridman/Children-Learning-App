// The working parts of `voice_gen`: which lines a character says, what generating them would cost, the
// ElevenLabs call, the conversion of its character timestamps into mouth cues, and the voice pack.
//
// This runs on the owner's PC only, never in the app. The ElevenLabs key is passed in by the command line
// (from an environment variable) and is never written anywhere.
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:nitznutz/content/pack_verify.dart';

import 'pack_builder_lib.dart';

/// One line to be said: its voice id (`vo:...`) and its Hebrew text with niqqud.
class SpokenLine {
  const SpokenLine(this.voId, this.text);

  final String voId;
  final String text;

  String get fileId => voId.substring('vo:'.length);
}

class VoiceGenFailed implements Exception {
  const VoiceGenFailed(this.message);

  final String message;

  @override
  String toString() => message;
}

// ---- which lines ----

/// Every line (voice id and caption) that a content pack's documents ask for.
List<SpokenLine> linesOfContent(Directory folder) {
  final Map<String, String> found = <String, String>{};
  void walk(Object? node) {
    if (node is Map<String, Object?>) {
      final Object? vo = node['vo'];
      final Object? caption = node['caption'];
      if (vo is String && vo.startsWith('vo:') && caption is List<Object?> && caption.isNotEmpty) {
        final Object? first = caption.first;
        if (first is Map<String, Object?> && first['v'] is String) found[vo] = first['v']! as String;
      }
      node.values.forEach(walk);
    } else if (node is List<Object?>) {
      node.forEach(walk);
    }
  }

  for (final FileSystemEntity e in folder.listSync()) {
    if (e is! File || !e.path.endsWith('.json')) continue;
    final String name = e.uri.pathSegments.last;
    if (!name.startsWith('activity.') && !name.startsWith('lesson.')) continue;
    walk(jsonDecode(e.readAsStringSync()));
  }
  return <SpokenLine>[for (final MapEntry<String, String> l in found.entries) SpokenLine(l.key, l.value)];
}

/// The core lines (greetings, encouragement ...) of `content/lines/core.he.json`.
List<SpokenLine> coreLines(File file) {
  final Map<String, Object?> doc = jsonDecode(file.readAsStringSync()) as Map<String, Object?>;
  return <SpokenLine>[
    for (final Object? l in doc['lines']! as List<Object?>)
      SpokenLine('vo:${(l! as Map<String, Object?>)['id']}', (l as Map<String, Object?>)['text']! as String),
  ];
}

/// Respells known tricky words (names, words the voice gets wrong) before they are sent.
String respelled(String text, Map<String, String> pronunciation) {
  String out = text;
  pronunciation.forEach((String from, String to) => out = out.replaceAll(from, to));
  return out;
}

// ---- the plan ----

class VoicePlan {
  const VoicePlan({
    required this.characters,
    required this.lines,
    required this.perCharacter,
    required this.total,
    this.toSay = 0,
    this.reused = 0,
  });

  final List<String> characters;
  final List<SpokenLine> lines;

  /// Characters of text still to be said for each voice (the lines are the same for every character; the ones whose
  /// sound already exists are reused and cost nothing).
  final int perCharacter;
  final int total;

  /// How many lines are still to be said, over all voices, and how many are reused.
  final int toSay;
  final int reused;

  /// The cost at [pricePer1000Chars] (the price per thousand characters that the owner reads off his ElevenLabs plan).
  double cost(double pricePer1000Chars) => total / 1000 * pricePer1000Chars;

  String describe(double pricePer1000Chars) {
    final StringBuffer b = StringBuffer()
      ..writeln('Voices: ${characters.join(', ')}')
      ..writeln('Lines per voice: ${lines.length}')
      ..writeln(
        'Lines still to say, over all voices: $toSay (the other $reused already have their sound and are reused for free)',
      )
      ..writeln('Characters of text per voice: $perCharacter')
      ..writeln('Characters of text in total: $total')
      ..writeln(
        'Cost at $pricePer1000Chars per 1,000 characters: ${cost(pricePer1000Chars).toStringAsFixed(2)}',
      )
      ..writeln()
      ..writeln('To generate, run again with:  generate ... --confirm-chars $total');
    return b.toString();
  }
}

VoicePlan planVoices(
  List<String> characters,
  List<SpokenLine> lines, {
  Map<String, String> pronunciation = const <String, String>{},

  /// True for a line of a character whose sound already exists (it is reused, not said again).
  bool Function(String character, SpokenLine line)? alreadyMade,
}) {
  int per = 0;
  int total = 0;
  int toSay = 0;
  int reused = 0;
  for (final String c in characters) {
    int mine = 0;
    for (final SpokenLine l in lines) {
      if (alreadyMade != null && alreadyMade(c, l)) {
        reused++;
        continue;
      }
      toSay++;
      mine += respelled(l.text, pronunciation).runes.length;
    }
    total += mine;
    if (mine > per) per = mine;
  }
  return VoicePlan(
    characters: characters,
    lines: lines,
    perCharacter: per,
    total: total,
    toSay: toSay,
    reused: reused,
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

/// Turns the alignment into cues. Each letter with its points forms a syllable-like group; a group with a
/// vowel point holds the mouth open from its start to its end, a bare consonant or a pause leaves it closed.
/// A letter written without niqqud (a vav or yod that carries a vowel, or text without points) is closed;
/// that is why the core lines are all written with niqqud.
List<(int, int)> cuesFromAlignment(Alignment a) {
  final List<(int, bool)> raw = <(int, bool)>[];
  int i = 0;
  while (i < a.characters.length) {
    final int r = a.characters[i].isEmpty ? 0x20 : a.characters[i].runes.first;
    if (!_isLetter(r)) {
      i++;
      continue;
    }
    final double start = a.starts[i];
    double end = a.ends[i];
    bool open = false;
    int j = i + 1;
    while (j < a.characters.length) {
      final int p = a.characters[j].isEmpty ? 0x20 : a.characters[j].runes.first;
      if (!_isPoint(p)) break;
      if (_opens(p)) open = true;
      end = math.max(end, a.ends[j]);
      j++;
    }
    if (open) {
      raw
        ..add(((start * 1000).round(), true))
        ..add(((end * 1000).round(), false));
    }
    i = j;
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
  /// Says [text]. [settings] (stability, style ...) replace the voice's usual settings for this one line.
  Future<Synthesis> say(String text, {Map<String, Object?>? settings});
}

/// The name of the style a line is said in (for example `cheer` for the celebrations), by the start of its voice id, or
/// null for the usual voice. [rules] maps a style to the voice-id prefixes it covers.
String? styleOf(String voId, Map<String, List<String>> rules) {
  for (final MapEntry<String, List<String>> r in rules.entries) {
    if (r.value.any(voId.startsWith)) return r.key;
  }
  return null;
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
  Future<Synthesis> say(String text, {Map<String, Object?>? settings}) async {
    final List<String> chars = text.split('');
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

/// ElevenLabs text to speech with timestamps. [baseUrl] is changed only by tests, to a local fake.
class ElevenLabsSynthesizer implements Synthesizer {
  ElevenLabsSynthesizer({
    required this.apiKey,
    required this.voiceId,
    required this.modelId,
    this.baseUrl = 'https://api.elevenlabs.io',
    this.languageCode = 'he',
    this.voiceSettings = const <String, Object?>{},
    this.outputFormat = 'mp3_22050_32',
  });

  final String apiKey;
  final String voiceId;
  final String modelId;
  final String baseUrl;
  final String languageCode;
  final Map<String, Object?> voiceSettings;
  final String outputFormat;

  @override
  Future<Synthesis> say(String text, {Map<String, Object?>? settings}) async {
    final Map<String, Object?> used = settings ?? voiceSettings;
    final HttpClient client = HttpClient();
    try {
      final Uri uri = Uri.parse(
        '$baseUrl/v1/text-to-speech/$voiceId/with-timestamps?output_format=$outputFormat',
      );
      final HttpClientRequest req = await client.postUrl(uri);
      req.headers
        ..set('xi-api-key', apiKey)
        ..set('content-type', 'application/json');
      req.add(
        utf8.encode(
          jsonEncode(<String, Object?>{
            'text': text,
            'model_id': modelId,
            'language_code': languageCode,
            if (used.isNotEmpty) 'voice_settings': used,
          }),
        ),
      );
      final HttpClientResponse res = await req.close();
      final String body = await utf8.decodeStream(res);
      if (res.statusCode != 200) {
        // The body of an error can echo the request; show the status only.
        throw VoiceGenFailed('ElevenLabs answered ${res.statusCode}');
      }
      final Map<String, Object?> json = jsonDecode(body) as Map<String, Object?>;
      return Synthesis(
        base64Decode(json['audio_base64']! as String),
        'mp3',
        Alignment.fromJson((json['alignment'] ?? json['normalized_alignment'])! as Map<String, Object?>),
      );
    } finally {
      client.close();
    }
  }
}

// ---- making the voice pack ----

/// Says every line in [lines] (the ones in [skip] are not said again) and builds the signed voice pack of
/// [characterId]. Writes the sources to [workDir] first, so that a run that stops can be continued.
Future<BuiltPack> generateVoicePack({
  required String characterId,
  required List<SpokenLine> lines,
  required Synthesizer synth,
  required PackKey key,
  required Directory workDir,
  Map<String, String> pronunciation = const <String, String>{},
  String version = '1.0.0',
  Map<String, List<String>> styleRules = const <String, List<String>>{},
  Map<String, Map<String, Object?>> styles = const <String, Map<String, Object?>>{},
  void Function(String)? progress,
}) async {
  workDir.createSync(recursive: true);
  final List<Map<String, String>> vo = <Map<String, String>>[];
  for (final SpokenLine l in lines) {
    final String id = l.fileId;
    final File cueFile = File('${workDir.path}${Platform.pathSeparator}cue.$id.json');
    File? audio;
    for (final String ext in <String>['mp3', 'wav']) {
      final File f = File('${workDir.path}${Platform.pathSeparator}vo.$id.$ext');
      if (f.existsSync()) audio = f;
    }
    if (audio == null || !cueFile.existsSync()) {
      final String? style = styleOf(l.voId, styleRules);
      final Synthesis s = await synth.say(
        respelled(l.text, pronunciation),
        settings: style == null ? null : styles[style],
      );
      audio = File('${workDir.path}${Platform.pathSeparator}vo.$id.${s.extension}')
        ..writeAsBytesSync(s.audio);
      cueFile.writeAsStringSync(
        jsonEncode(<String, Object?>{
          'schema': 'cue/v1',
          'id': id,
          'cues': <Object?>[
            for (final (int, int) c in cuesFromAlignment(s.alignment))
              <String, Object?>{'t': c.$1, 'o': c.$2},
          ],
        }),
      );
      progress?.call('said $id');
    }
    vo.add(<String, String>{'id': id, 'file': audio.uri.pathSegments.last});
  }
  File('${workDir.path}${Platform.pathSeparator}pack.json').writeAsStringSync(
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
