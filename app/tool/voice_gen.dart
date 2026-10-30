// The voice generator. Run from the app/ folder:
//
//   dart run tool/voice_gen.dart plan [--characters a,b,c] [--price <per 1,000 characters>] [--list] [--out <folder>]
//   dart run tool/voice_gen.dart mock <character> [--key <key file>] [--out <folder>]
//   dart run tool/voice_gen.dart generate <character> [--key <key file>] [--out <folder>] [--pack-version <x.y.z>]
//   dart run tool/voice_gen.dart audition-batch plan <spec.json> [--out <folder>] [--price <per 1,000 characters>]
//   dart run tool/voice_gen.dart audition-batch run <spec.json> [--out <folder>]
//   dart run tool/voice_gen.dart audition <character> "<text>" [--model <id>] [--settings stability=0.25,similarity=0.8,boost=true] [--format <mp3_44100_...>] [--allow exclamation,ipa] [--out <folder>]
//
// The free commands also take --repo <folder> (the repository root, `..` by default), so tests can run them on their
// own data. A paid command refuses any --repo that is not this repository. Every plan starts with the repository folder.
//
// The words sent are the voice_text column of docs/review/hebrew-master.csv (voice_text_lib.dart), never the screen
// captions, and only for lines the owner approved (owner-approved, voice-ready or voiced); every text passes the
// pre-flight check first. Every request carries explicit voice settings from content/voices.json (no style or speed on a
// v4 model) and asks for 44.1 kHz audio. Each clip's hash (text, voice, model, settings, format) is recorded next to the
// work folder, so a changed line is said again and an unchanged one is reused.
//
// `plan`, `audition-batch plan` and `mock` are free and need no terminal: `plan` counts new, changed and unchanged lines
// for each voice, the characters and the cost (--list prints every line still to say with its exact text); `mock` makes
// a voice pack of test tones (no network). The paid commands, `generate`, `audition-batch run` and `audition`, work only
// in an interactive terminal: in the same process they plan exactly what they will send, print that plan, and go ahead
// only when the owner types its total on the keyboard. No flag can pass that gate.
//
// The ElevenLabs key is read from the environment variable ELEVENLABS_API_KEY only, after the gate. It is never printed,
// written to a file or put on a command line.
import 'dart:convert';
import 'dart:io';

import 'package:nitznutz/content/pack_verify.dart' show sha256Hex;

import 'audition_lib.dart';
import 'pack_builder_lib.dart';
import 'voice_gen_lib.dart';

const String _keyVariable = 'ELEVENLABS_API_KEY';
const Keyboard _keyboard = TerminalKeyboard();

/// The commands that spend money.
const Set<String> _paid = <String>{'generate', 'audition'};

Future<void> main(List<String> args) async {
  if (args.isEmpty) {
    _usage();
    exit(2);
  }
  final List<String> rest = args.sublist(1);
  try {
    final bool paid =
        _paid.contains(args.first) || (args.first == 'audition-batch' && rest.firstOrNull == 'run');
    if (paid && !_isDefaultRepo(args)) {
      throw const VoiceGenFailed(
        '--repo is accepted only by the free commands (plan, audition-batch plan, mock): a paid run voices the texts '
        'of this repository only. Nothing was sent.',
      );
    }
    if (paid && args.contains('--confirm-chars')) {
      throw const VoiceGenFailed(
        '--confirm-chars is not accepted: a paid run works only in an interactive terminal, where it shows its plan '
        'and you type the count yourself. Nothing was sent.',
      );
    }
    switch (args.first) {
      case 'plan':
        _plan(rest);
      case 'mock':
        await _mock(rest);
      case 'generate':
        await _generate(rest);
      case 'audition-batch':
        await _auditionBatch(rest);
      case 'audition':
        await _audition(rest);
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
  } on Object catch (e) {
    // Only the kind of error: its message could quote anything, the key included.
    stderr.writeln('FAILED: unexpected ${e.runtimeType}');
    exit(1);
  }
}

void _usage() {
  stderr.writeln(
    'usage: dart run tool/voice_gen.dart plan|mock|generate|audition-batch|audition ... (see the top of this file)',
  );
}

String? _option(List<String> args, String name) {
  final int i = args.indexOf(name);
  return i >= 0 && i + 1 < args.length ? args[i + 1] : null;
}

/// The options that take no value.
const Set<String> _flags = <String>{'--list'};

List<String> _positional(List<String> args) {
  final List<String> out = <String>[];
  for (int i = 0; i < args.length; i++) {
    if (_flags.contains(args[i])) continue;
    if (args[i].startsWith('--')) {
      i++;
    } else {
      out.add(args[i]);
    }
  }
  return out;
}

/// The repository root (--repo, `..` by default) as a normalised absolute path.
String _repoRoot(List<String> args) => normalisedFolder(Directory(_option(args, '--repo') ?? '..'));

/// Whether the repository is the default one (no --repo, or one that resolves to it).
bool _isDefaultRepo(List<String> args) {
  String norm(String p) => Platform.isWindows ? p.toLowerCase() : p;
  return norm(_repoRoot(args)) == norm(normalisedFolder(Directory('..')));
}

/// The first line of every plan: where the texts, statuses and voices come from.
String _repoHeading(List<String> args) => 'Repository: ${_repoRoot(args)}';

/// A path under the repository root (--repo, `..` by default).
String _repo(List<String> args, String path) =>
    '${_option(args, '--repo') ?? '..'}${Platform.pathSeparator}${path.replaceAll('/', Platform.pathSeparator)}';

Map<String, Object?> _config(List<String> args) {
  final File f = File(_repo(args, 'content/voices.json'));
  if (!f.existsSync()) throw const VoiceGenFailed('content/voices.json is missing');
  return jsonDecode(f.readAsStringSync()) as Map<String, Object?>;
}

List<String> _characters(List<String> args, Map<String, Object?> config) {
  final String? given = _option(args, '--characters');
  if (given != null) return given.split(',').where((String s) => s.isNotEmpty).toList();
  return (config['voices']! as Map<String, Object?>).keys.toList()..sort();
}

/// The price per 1,000 characters of [model]: --price, or the list price in content/voices.json, or 0.
double Function(String model) _prices(List<String> args, Map<String, Object?> config) {
  final double? given = double.tryParse(_option(args, '--price') ?? '');
  final Map<String, Object?> list =
      (config['listPricePer1000Chars'] ?? <String, Object?>{}) as Map<String, Object?>;
  return (String model) => given ?? ((list[model] as num?)?.toDouble() ?? 0);
}

VoiceTexts _voiceTexts(List<String> args) {
  final File master = File(_repo(args, 'docs/review/hebrew-master.csv'));
  if (!master.existsSync()) throw const VoiceGenFailed('docs/review/hebrew-master.csv is missing');
  return voiceTextsOf(
    content: Directory(_repo(args, 'content/starter')),
    core: File(_repo(args, 'content/lines/core.he.json')),
    master: readMaster(master.readAsStringSync()),
  );
}

String _home() => '${Platform.environment['USERPROFILE'] ?? '.'}${Platform.pathSeparator}nitznutz-voice';

String _outFolder(List<String> args, String character) =>
    _option(args, '--out') ?? '${_home()}${Platform.pathSeparator}$character';

void _plan(List<String> args) {
  final Map<String, Object?> config = _config(args);
  final VoiceTexts texts = _voiceTexts(args);
  final List<String> characters = _characters(args, config);
  final Map<String, Map<String, String>> made = <String, Map<String, String>>{
    for (final String c in characters) c: ClipLedger(Directory(_outFolder(args, c))).hashes(),
  };
  final VoicePlan plan = planVoices(
    <String, VoiceProfile>{for (final String c in characters) c: VoiceProfile.fromConfig(config, c)},
    texts.ready,
    stateOf: (String c, SpokenLine l, ClipRequest r) =>
        clipState(Directory(_outFolder(args, c)), l.fileId, r, made[c]!),
  );
  final String model = plan.clips.isEmpty
      ? (config['modelId'] ?? '') as String
      : plan.clips.first.request.modelId;
  final double price = _prices(args, config)(model);
  stdout.writeln(_repoHeading(args));
  stdout.writeln(
    'Words from the voice_text column of docs/review/hebrew-master.csv; only lines the owner approved '
    '(${voiceableStatuses.join(', ')}) are voiced.',
  );
  stdout.write(
    plan.describe(
      price,
      list: args.contains('--list'),
      priceSource: _option(args, '--price') != null ? '' : ' ($model list price in content/voices.json)',
    ),
  );
  if (texts.blocked.isNotEmpty) {
    stdout
      ..writeln()
      ..write(texts.describeBlocked())
      ..writeln(
        'Nothing is voiced until the owner marks these rows owner-approved; generate refuses until every line '
        'above is approved.',
      );
  }
  if (price == 0) {
    stdout.writeln(
      '(Pass --price <what your ElevenLabs plan charges per 1,000 characters> to see the cost.)',
    );
  }
}

/// Free test tones for every line that has a voice_text, approved or not: nothing is sent anywhere. They go to a
/// folder of their own (`nitznutz-voice/mock/<character>` unless --out says otherwise), and never into a folder that
/// holds ElevenLabs clips: the tones would replace the paid sound.
Future<void> _mock(List<String> args) async {
  final List<String> pos = _positional(args);
  if (pos.length != 1) throw const VoiceGenFailed('mock needs one character id');
  final String character = pos.single;
  final Directory dir = Directory(
    _option(args, '--out') ?? '${_home()}${Platform.pathSeparator}mock${Platform.pathSeparator}$character',
  );
  bool isMp3(FileSystemEntity e) => e is File && e.path.toLowerCase().endsWith('.mp3');
  if (dir.existsSync() && dir.listSync().any(isMp3)) {
    throw VoiceGenFailed(
      '${dir.path} holds ElevenLabs clips, and test tones would replace them. Use another --out',
    );
  }
  final BuiltPack built = await generateVoicePack(
    characterId: character,
    lines: _voiceTexts(args).forTestVoices,
    synth: MockSynthesizer(character),
    profile: VoiceProfile.mock,
    key: readKeyFile(_option(args, '--key') ?? defaultKeyPath()),
    workDir: dir,
    progress: stdout.writeln,
  );
  _writePack(dir, built);
}

void _writePack(Directory dir, BuiltPack built) {
  final File file = File('${dir.path}${Platform.pathSeparator}${built.fileName}')
    ..writeAsBytesSync(built.bytes);
  stdout.writeln('Built ${file.path}: ${built.bytes.length} bytes');
}

Future<void> _generate(List<String> args) async {
  final List<String> pos = _positional(args);
  if (pos.length != 1) throw const VoiceGenFailed('generate needs one character id');
  final String character = pos.single;
  requireTerminal(_keyboard, 'generate');
  final Map<String, Object?> config = _config(args);
  final VoiceTexts texts = _voiceTexts(args);
  if (texts.blocked.isNotEmpty) throw VoiceGenFailed('Nothing was sent. ${texts.describeBlocked()}');
  final VoiceProfile profile = VoiceProfile.fromConfig(config, character);
  final Directory work = Directory(_outFolder(args, character));
  final BuiltPack built = await generateGated(
    characterId: character,
    lines: texts.ready,
    profile: profile,
    workDir: work,
    key: readKeyFile(_option(args, '--key') ?? defaultKeyPath()),
    keyboard: _keyboard,
    synth: _eleven,
    write: stdout.writeln,
    pricePer1000Chars: _prices(args, config)(profile.modelId),
    heading: _repoHeading(args),
    version: _option(args, '--pack-version') ?? '1.0.0',
  );
  _writePack(work, built);
}

/// The ElevenLabs voice, made only after the gate: the key is read from the environment here and nowhere else, and
/// the synthesizer refuses it by name if it is not a plain key.
ElevenLabsSynthesizer _eleven() {
  final String? key = Platform.environment[_keyVariable];
  if (key == null || key.isEmpty) {
    throw const VoiceGenFailed(
      'set the environment variable $_keyVariable first (it is never printed or saved)',
    );
  }
  return ElevenLabsSynthesizer(apiKey: key);
}

/// Runs [clips] through the gate: in a terminal, plans, prints, asks for the total, and only then makes them into [out].
Future<void> _gatedAudition(
  List<String> args,
  String title,
  List<AuditionClip> clips,
  Directory out,
  String run,
) async {
  final List<File> files = await runAudition(
    AuditionPlan(title: title, clips: clips, made: madeAuditionClips(clips, out)),
    keyboard: _keyboard,
    synth: _eleven,
    out: out,
    write: stdout.writeln,
    pricePer1000: _prices(args, _config(args)),
    runCommand: run,
    heading: _repoHeading(args),
  );
  if (files.isNotEmpty) stdout.writeln('Made ${files.length} clips in ${out.path}');
}

Future<void> _auditionBatch(List<String> args) async {
  final List<String> pos = _positional(args);
  if (pos.length != 2 || (pos[0] != 'plan' && pos[0] != 'run')) {
    throw const VoiceGenFailed('audition-batch needs plan or run, and a spec file');
  }
  final bool run = pos[0] == 'run';
  if (run) requireTerminal(_keyboard, 'audition-batch run');
  final File specFile = File(pos[1]);
  if (!specFile.existsSync()) throw VoiceGenFailed('no spec file at ${pos[1]}');
  final Object? spec = jsonDecode(specFile.readAsStringSync());
  if (spec is! Map<String, Object?>) throw const VoiceGenFailed('the spec is not a JSON object');
  final String name = specFile.uri.pathSegments.last.replaceAll(RegExp(r'\.json$'), '');
  final Directory out = Directory(
    _option(args, '--out') ?? '${_home()}${Platform.pathSeparator}auditions${Platform.pathSeparator}$name',
  );
  final bool needsLines =
      (spec['clips'] is List<Object?>) &&
      (spec['clips']! as List<Object?>).any(
        (Object? c) => c is Map<String, Object?> && c.containsKey('line'),
      );
  final List<AuditionClip> clips = readAuditionSpec(
    spec,
    config: _config(args),
    lines: needsLines ? _lineTexts(args) : const LineTexts(),
  );
  final String title = (spec['title'] ?? name) as String;
  final String runCommand = 'dart run tool/voice_gen.dart audition-batch run ${pos[1]}';
  if (run) {
    await _gatedAudition(args, title, clips, out, runCommand);
  } else {
    stdout
      ..writeln(_repoHeading(args))
      ..write(
        AuditionPlan(
          title: title,
          clips: clips,
          made: madeAuditionClips(clips, out),
        ).describe(_prices(args, _config(args)), runCommand: runCommand),
      );
  }
}

LineTexts _lineTexts(List<String> args) => LineTexts(
  voiceText: _voiceTexts(args).textById,
  caption: <String, String>{
    for (final SpokenLine l in <SpokenLine>[
      ...linesOfContent(Directory(_repo(args, 'content/starter'))),
      ...coreLines(File(_repo(args, 'content/lines/core.he.json'))),
    ])
      l.voId: l.text,
  },
);

/// `stability=0.25,similarity=0.8,boost=true` as voice settings (a command line cannot carry JSON quotes).
Map<String, Object?> _settingsOf(String text) {
  final Map<String, Object?> out = <String, Object?>{};
  for (final String pair in text.split(',')) {
    final List<String> kv = pair.split('=');
    if (kv.length != 2) {
      throw VoiceGenFailed('settings look like stability=0.25,similarity=0.8,boost=true, not "$pair"');
    }
    final String key = switch (kv[0].trim()) {
      'boost' => 'use_speaker_boost',
      'similarity' => 'similarity_boost',
      final String k => k,
    };
    final String v = kv[1].trim();
    out[key] = v == 'true' || v == 'false'
        ? v == 'true'
        : (double.tryParse(v) ?? (throw VoiceGenFailed('"$v" is not a number')));
  }
  return out;
}

/// One text, as a one-clip audition through the same gate.
Future<void> _audition(List<String> args) async {
  final List<String> pos = _positional(args);
  if (pos.length != 2) throw const VoiceGenFailed('audition needs a character id and a text');
  requireTerminal(_keyboard, 'audition');
  final String? settings = _option(args, '--settings');
  final String? allow = _option(args, '--allow');
  final Map<String, Object?> clip = <String, Object?>{
    'character': pos[0],
    'text': pos[1],
    if (_option(args, '--model') != null) 'model': _option(args, '--model'),
    if (_option(args, '--format') != null) 'format': _option(args, '--format'),
    if (settings != null) 'settings': _settingsOf(settings),
    if (allow != null) 'allow': allow.split(','),
  };
  // The id follows the text and the settings, so a different try is a different file.
  final String id = 'audition-${pos[0]}-${sha256Hex(utf8.encode(jsonEncode(clip))).substring(0, 8)}';
  final List<AuditionClip> clips = readAuditionSpec(<String, Object?>{
    'schema': auditionSchema,
    'title': 'one text',
    'clips': <Object?>[
      <String, Object?>{'id': id, ...clip},
    ],
  }, config: _config(args));
  final Directory out = Directory(
    _option(args, '--out') ?? '${_home()}${Platform.pathSeparator}auditions${Platform.pathSeparator}single',
  );
  await _gatedAudition(args, 'one text', clips, out, 'the same audition command');
}
