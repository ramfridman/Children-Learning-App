// The voice generator. Run from the app/ folder:
//
//   dart run tool/voice_gen.dart plan [--characters a,b,c] [--price <per 1,000 characters>]
//   dart run tool/voice_gen.dart mock <character> [--key <key file>] [--out <folder>]
//   dart run tool/voice_gen.dart audition <character> "<text>" [--out <file>]
//   dart run tool/voice_gen.dart generate <character> --confirm-chars <N> [--key <key file>] [--out <folder>] [--pack-version <x.y.z>]
//
// `plan` writes and calls nothing: it lists the lines and prints the number of characters, and the cost at the
// price you give. `mock` makes a free voice pack of test tones (no network). `audition` says one short text with the
// character's configured voice, to choose a voice by ear. `generate` calls ElevenLabs and refuses to start unless
// --confirm-chars equals the number `plan` printed for that character.
//
// The ElevenLabs key is read from the environment variable ELEVENLABS_API_KEY only. It is never printed, written to a
// file or put on a command line.
import 'dart:convert';
import 'dart:io';

import 'pack_builder_lib.dart';
import 'voice_gen_lib.dart';

const String _voicesConfig = '../content/voices.json';
const String _coreLines = '../content/lines/core.he.json';
const String _starter = '../content/starter';
const String _keyVariable = 'ELEVENLABS_API_KEY';

Future<void> main(List<String> args) async {
  if (args.isEmpty) {
    _usage();
    exit(2);
  }
  final List<String> rest = args.sublist(1);
  try {
    switch (args.first) {
      case 'plan':
        _plan(rest);
      case 'mock':
        await _mock(rest);
      case 'audition':
        await _audition(rest);
      case 'generate':
        await _generate(rest);
      default:
        _usage();
        exit(2);
    }
  } on VoiceGenFailed catch (e) {
    stderr.writeln('FAILED: $e');
    exit(1);
  } on BuildFailed catch (e) {
    stderr.writeln('FAILED: $e');
    exit(1);
  }
}

void _usage() {
  stderr.writeln(
    'usage: dart run tool/voice_gen.dart plan|mock|audition|generate ... (see the top of this file)',
  );
}

String? _option(List<String> args, String name) {
  final int i = args.indexOf(name);
  return i >= 0 && i + 1 < args.length ? args[i + 1] : null;
}

List<String> _positional(List<String> args) {
  final List<String> out = <String>[];
  for (int i = 0; i < args.length; i++) {
    if (args[i].startsWith('--')) {
      i++;
    } else {
      out.add(args[i]);
    }
  }
  return out;
}

Map<String, Object?> _config() {
  final File f = File(_voicesConfig);
  if (!f.existsSync()) throw const VoiceGenFailed('content/voices.json is missing');
  return jsonDecode(f.readAsStringSync()) as Map<String, Object?>;
}

Map<String, Object?> _voiceOf(Map<String, Object?> config, String character) {
  final Object? v = (config['voices']! as Map<String, Object?>)[character];
  if (v is! Map<String, Object?>) throw VoiceGenFailed('content/voices.json has no voice for "$character"');
  return v;
}

List<String> _characters(List<String> args, Map<String, Object?> config) {
  final String? given = _option(args, '--characters');
  if (given != null) return given.split(',').where((String s) => s.isNotEmpty).toList();
  return (config['voices']! as Map<String, Object?>).keys.toList()..sort();
}

Map<String, String> _pronunciation(Map<String, Object?> config) => <String, String>{
  for (final MapEntry<String, Object?> e
      in ((config['pronunciation'] ?? <String, Object?>{}) as Map<String, Object?>).entries)
    e.key: e.value! as String,
};

List<SpokenLine> _lines() => <SpokenLine>[
  ...linesOfContent(Directory(_starter)),
  ...coreLines(File(_coreLines)),
];

String _outFolder(List<String> args, String character) =>
    _option(args, '--out') ??
    '${Platform.environment['USERPROFILE'] ?? '.'}${Platform.pathSeparator}nitznutz-voice${Platform.pathSeparator}$character';

void _plan(List<String> args) {
  final Map<String, Object?> config = _config();
  final double price = double.tryParse(_option(args, '--price') ?? '') ?? 0;
  final VoicePlan plan = planVoices(
    _characters(args, config),
    _lines(),
    pronunciation: _pronunciation(config),
  );
  stdout.write(plan.describe(price));
  if (price == 0) {
    stdout.writeln(
      '(Pass --price <what your ElevenLabs plan charges per 1,000 characters> to see the cost.)',
    );
  }
}

Future<BuiltPack> _make(
  String character,
  List<String> args,
  Synthesizer synth,
  Map<String, Object?> config,
) async {
  final PackKey key = readKeyFile(_option(args, '--key') ?? defaultKeyPath());
  final Directory work = Directory(_outFolder(args, character));
  final BuiltPack built = await generateVoicePack(
    characterId: character,
    lines: _lines(),
    synth: synth,
    key: key,
    workDir: work,
    pronunciation: _pronunciation(config),
    version: _option(args, '--pack-version') ?? '1.0.0',
    progress: stdout.writeln,
  );
  final File file = File('${work.path}${Platform.pathSeparator}${built.fileName}');
  file.writeAsBytesSync(built.bytes);
  stdout.writeln('Built ${file.path}: ${built.bytes.length} bytes');
  return built;
}

Future<void> _mock(List<String> args) async {
  final List<String> pos = _positional(args);
  if (pos.length != 1) throw const VoiceGenFailed('mock needs one character id');
  await _make(pos.single, args, MockSynthesizer(pos.single), _config());
}

ElevenLabsSynthesizer _eleven(String character, Map<String, Object?> config) {
  final String? key = Platform.environment[_keyVariable];
  if (key == null || key.isEmpty) {
    throw const VoiceGenFailed(
      'set the environment variable $_keyVariable first (it is never printed or saved)',
    );
  }
  final Map<String, Object?> voice = _voiceOf(config, character);
  final String id = (voice['voiceId'] ?? '') as String;
  if (id.isEmpty) throw VoiceGenFailed('"$character" has no voiceId in content/voices.json yet');
  final String model = (config['modelId'] ?? '') as String;
  if (model.isEmpty) throw const VoiceGenFailed('content/voices.json has no modelId yet');
  return ElevenLabsSynthesizer(
    apiKey: key,
    voiceId: id,
    modelId: model,
    voiceSettings: ((voice['settings'] ?? config['settings'] ?? <String, Object?>{}) as Map<String, Object?>),
  );
}

Future<void> _audition(List<String> args) async {
  final List<String> pos = _positional(args);
  if (pos.length != 2) throw const VoiceGenFailed('audition needs a character id and a text');
  final Map<String, Object?> config = _config();
  final Synthesis s = await _eleven(pos[0], config).say(respelled(pos[1], _pronunciation(config)));
  final File out = File(_option(args, '--out') ?? 'audition-${pos[0]}.${s.extension}')
    ..writeAsBytesSync(s.audio);
  stdout.writeln('Wrote ${out.path} (${pos[1].runes.length} characters used)');
}

Future<void> _generate(List<String> args) async {
  final List<String> pos = _positional(args);
  if (pos.length != 1) throw const VoiceGenFailed('generate needs one character id');
  final Map<String, Object?> config = _config();
  final VoicePlan plan = planVoices(<String>[pos.single], _lines(), pronunciation: _pronunciation(config));
  final int? confirmed = int.tryParse(_option(args, '--confirm-chars') ?? '');
  if (confirmed != plan.total) {
    throw VoiceGenFailed(
      'this would use ${plan.total} characters of ElevenLabs text for "${pos.single}". '
      'Nothing was sent. To go ahead, run again with --confirm-chars ${plan.total}',
    );
  }
  await _make(pos.single, args, _eleven(pos.single, config), config);
}
