// The voice generator. Run from the app/ folder:
//
//   dart run tool/voice_gen.dart plan [--characters a,b,c] [--lines full|lessons|ui|own] [--groups a,b] [--budget N] [--each-id] [--as-if-approved] [--price <per 1,000 characters>] [--list] [--out <folder>]
//   dart run tool/voice_gen.dart mock <character> [--key <key file>] [--out <folder>]
//   dart run tool/voice_gen.dart groups [--characters a,b,c] [--lines full|lessons|own]
//   dart run tool/voice_gen.dart pack <character> [--lines full|lessons|own] [--groups a,b] [--pack-version <x.y.z>] [--key <key file>] [--out <folder>]
//   dart run tool/voice_gen.dart verify <character> [--groups a,b] [--lines full|lessons|own] [--out <folder>]
//   dart run tool/voice_gen.dart generate <character> [--lines full|lessons|own] [--groups a,b] [--budget N] [--each-id] [--key <key file>] [--out <folder>] [--pack-version <x.y.z>]
//   dart run tool/voice_gen.dart plan-lang <course> --voice <name> [--puppet-voice <name>] [--frame-voice <name>] [--model <id>] [--ffmpeg <path>] [--each-id] [--price <per 1,000 characters>] [--list] [--out <folder>]
//   dart run tool/voice_gen.dart verify-lang <course> --voice <name> [--puppet-voice <name>] [--frame-voice <name>] [--out <folder>]
//   dart run tool/voice_gen.dart generate-lang <course> --voice <name> [--puppet-voice <name>] [--frame-voice <name>] [--model <id>] [--ffmpeg <path>] [--each-id] [--key <key file>] [--out <folder>] [--pack-version <x.y.z>]
//   dart run tool/voice_gen.dart audition-batch plan <spec.json> [--out <folder>] [--price <per 1,000 characters>]
//   dart run tool/voice_gen.dart audition-batch run <spec.json> [--out <folder>]
//   dart run tool/voice_gen.dart audition <character> "<text>" [--model <id>] [--settings stability=0.25,similarity=0.8,boost=true] [--format <mp3_44100_...>] [--allow exclamation,ipa] [--language he|en|ru] [--out <folder>]
//
// Which lines: `--lines full` (the default) is a narrator's whole pack, the lessons, the core lines and the shell's lines
// (content/lines/ui.he.json: the bottle's lines for each land, the language stops, the doors, the empty bottle);
// `lessons` leaves the shell's lines out; `own` is the nine lines a friend says in its own voice (the narrator's
// recording plays for all others); `ui` is the shell's lines alone, to see their share in a `plan`. Lines that send exactly
// the same request (same text, voice, model, settings) are voiced once and copied for free; `--each-id` voices every id.
// `plan --as-if-approved` counts every line that has a voice_text as if its row were approved: a figure to expect, never
// a run (`generate` refuses the flag). Each voice may have its own `modelId` in content/voices.json; the plan shows each model's characters and price.
//
// Batches: the whole release is more characters than a month's allowance, so a run may voice whole groups. The groups are
// the voice director's, in `docs/audio/voicing-groups.json` (made by `python tools/voicing_groups.py`): core, celebrate, then
// each land and band; the shell's lines are one more group, `ui`. `--groups a,b` plans, approval-checks and voices only
// those groups (a line outside them does not block the run); `--budget N` (also `--max-characters N`) takes the groups in
// manifest order and stops before the first one that would not fit whole, prints what is left for next time, and the
// gate still asks for the exact count of the run. The pack holds every line already voiced plus the run's; a line that
// shares its text with a clip already made is copied for free, in whatever group that clip is. Resume skips what is
// made. `groups` lists each group with its lines and characters; `verify` (free) checks that every clip of the groups is
// there, matches its text and is not under 2 KB, and exits 1 if not.
//
// `pack` (free) builds the voice pack of a character again from the clips saved in its work folder, with no voice and no
// ElevenLabs key (the key file is the pack-signing key): the lines with a clip go into the pack, the others are named and
// left out. It is what finishes a run whose pack could not be built, and it pays for nothing.
//
// `plan-lang` and `generate-lang` voice a language course from content/languages/<course>/voice-plan.json (course: eng,
// rus or heb): the Hebrew lines with `--frame-voice` (a voice of content/voices.json, `nitzi` by default), the clips in the
// language taught with `--voice` (an audition candidate may be named here). A "!" is sent as "."; a `-slow` clip is made from
// the normal clip and a cut word from its page's clip, with ffmpeg (free; the plan says if it is missing); a text with a
// placeholder is refused. With `--puppet-voice` (the voice director's rule, docs/languages/voices.md section 11) the puppet's
// own lines, the `prompt.target` and `prompt.target2` clips of the course's `puppet_talk` activities, are said by that voice
// and the other clips in the language taught by `--voice`; the plan shows each voice's clips and characters.
//
// `audition-batch` writes to ~/nitznutz-voice/auditions/<spec name>, with the language in front for a spec that is not
// Hebrew (en-pilot, ru-pilot), unless --out says otherwise.
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
// `plan`, `plan-lang`, `audition-batch plan` and `mock` are free and need no terminal: `plan` counts new, changed and unchanged lines
// for each voice, the characters and the cost (--list prints every line still to say with its exact text); `mock` makes
// a voice pack of test tones (no network). The paid commands, `generate`, `generate-lang`, `audition-batch run` and `audition`, work only
// in an interactive terminal: in the same process they plan exactly what they will send, print that plan, and go ahead
// only when the owner types its total on the keyboard. No flag can pass that gate.
//
// The ElevenLabs key is read from the environment variable ELEVENLABS_API_KEY only, after the gate. It is never printed,
// written to a file or put on a command line.
import 'dart:convert';
import 'dart:io';

import 'package:nitznutz/content/pack_verify.dart' show PackRejected, sha256Hex;

import 'audio_tool_lib.dart';
import 'audition_lib.dart';
import 'lang_voice_lib.dart';
import 'pack_builder_lib.dart';
import 'voice_gen_lib.dart';
import 'voice_groups_lib.dart';

const String _keyVariable = 'ELEVENLABS_API_KEY';
const Keyboard _keyboard = TerminalKeyboard();

/// The commands that spend money.
const Set<String> _paid = <String>{'generate', 'generate-lang', 'audition'};

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
        '--repo is accepted only by the free commands (plan, plan-lang, audition-batch plan, mock): a paid run voices the texts '
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
      case 'pack':
        await _pack(rest);
      case 'groups':
        _groups(rest);
      case 'verify':
        _verify(rest);
      case 'plan-lang':
        await _planLang(rest);
      case 'verify-lang':
        _verifyLang(rest);
      case 'generate':
        await _generate(rest);
      case 'generate-lang':
        await _generateLang(rest);
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
  } on PackRejected catch (e) {
    // The reason strings are ours (a stage, a limit, a file name): no key and no text of an answer is in them. The clips
    // are saved; `pack` builds the pack again from them with no voice.
    stderr
      ..writeln('FAILED: the pack was rejected by the app\'s own check (${e.stage}): ${e.reason}')
      ..writeln(
        'Every clip is kept in the work folder. Nothing more is paid for: `pack <character>` builds the pack again from them.',
      );
    for (final Object p in e.problems) {
      stderr.writeln('  $p');
    }
    exit(1);
  } on Object catch (e) {
    // Only the kind of error: its message could quote anything, the key included.
    stderr.writeln('FAILED: unexpected ${e.runtimeType}');
    exit(1);
  }
}

void _usage() {
  stderr.writeln(
    'usage: dart run tool/voice_gen.dart plan|groups|verify|pack|plan-lang|verify-lang|mock|generate|generate-lang|audition-batch|audition ... (see the top of this file)',
  );
}

String? _option(List<String> args, String name) {
  final int i = args.indexOf(name);
  return i >= 0 && i + 1 < args.length ? args[i + 1] : null;
}

/// The options that take no value.
const Set<String> _flags = <String>{'--list', '--each-id', '--as-if-approved'};

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
  return packCharacters(config);
}

/// The price per 1,000 characters of [model]: --price, or the list price in content/voices.json, or 0.
double Function(String model) _prices(List<String> args, Map<String, Object?> config) {
  final double? given = double.tryParse(_option(args, '--price') ?? '');
  final Map<String, Object?> list =
      (config['listPricePer1000Chars'] ?? <String, Object?>{}) as Map<String, Object?>;
  return (String model) => given ?? ((list[model] as num?)?.toDouble() ?? 0);
}

/// Every line the narrators say: the lessons, the core lines and the shell's lines. [VoiceTexts.only] picks a pack's part.
VoiceTexts _voiceTexts(List<String> args) {
  final File masterFile = File(_repo(args, 'docs/review/hebrew-master.csv'));
  if (!masterFile.existsSync()) throw const VoiceGenFailed('docs/review/hebrew-master.csv is missing');
  final File ui = File(_repo(args, 'content/lines/ui.he.json'));
  if (!ui.existsSync()) throw const VoiceGenFailed('content/lines/ui.he.json is missing');
  final Map<String, MasterRow> master = readMaster(masterFile.readAsStringSync());
  final VoiceTexts lessons = voiceTextsOf(
    content: Directory(_repo(args, 'content/starter')),
    core: File(_repo(args, 'content/lines/core.he.json')),
    master: master,
  );
  return VoiceTexts(<VoicedLine>[...lessons.lines, ...uiLines(file: ui, master: master)]);
}

/// The set of lines asked for with --lines (all of them unless it says otherwise).
LineSet _lineSet(List<String> args) => LineSet.parse(_option(args, '--lines') ?? LineSet.full.name);

/// The plan for [lines] said by [profiles], as a function of the lines to voice now (null: all): clips are looked at once,
/// whatever the number of plans a choice of groups needs.
VoicePlan Function(Set<String>? scope) _planner(
  List<String> args,
  Map<String, VoiceProfile> profiles,
  List<SpokenLine> lines,
) {
  final bool share = !args.contains('--each-id');
  final Map<String, Directory> dirs = <String, Directory>{
    for (final String c in profiles.keys) c: Directory(_outFolder(args, c)),
  };
  final Map<String, Map<String, String>> made = <String, Map<String, String>>{
    for (final String c in profiles.keys) c: ClipLedger(dirs[c]!).hashes(),
  };
  final Set<String> ids = <String>{for (final SpokenLine l in lines) l.fileId};
  final Map<String, Map<String, String>> elsewhere = share
      ? <String, Map<String, String>>{
          for (final String c in profiles.keys) c: madeElsewhere(dirs[c]!, ids, made[c]!),
        }
      : const <String, Map<String, String>>{};
  final Map<String, ClipState> seen = <String, ClipState>{};
  return (Set<String>? scope) => planVoices(
    profiles,
    lines,
    stateOf: (String c, SpokenLine l, ClipRequest r) =>
        seen.putIfAbsent('$c|${l.fileId}|${r.hash}', () => clipState(dirs[c]!, l.fileId, r, made[c]!)),
    shareSameText: share,
    scope: scope,
    madeElsewhere: elsewhere,
  );
}

/// The `--budget` (or `--max-characters`) in characters, or null.
int? _budget(List<String> args) {
  final String? given = _option(args, '--budget') ?? _option(args, '--max-characters');
  if (given == null) return null;
  final int? n = int.tryParse(given);
  if (n == null || n < 0) throw VoiceGenFailed('--budget is a number of characters, not "$given"');
  return n;
}

/// Whether the run is in batches: `--groups` or `--budget` was given.
bool _batching(List<String> args) => _option(args, '--groups') != null || _budget(args) != null;

/// The voice director's groups (docs/audio/voicing-groups.json) of the repository.
GroupManifest _manifest(List<String> args) =>
    GroupManifest.read(File(_repo(args, 'docs/audio/voicing-groups.json')));

/// [texts] with the group of each line, from the manifest.
VoiceTexts _grouped(List<String> args, VoiceTexts texts) => texts.withGroups(_manifest(args).groupOf);

/// The part of each line of [texts] (which has its groups), from docs/audio/voicing-parts.json.
Map<String, int> _partOfLine(List<String> args, VoiceTexts texts) => VoiceParts.read(
  File(_repo(args, 'docs/audio/voicing-parts.json')),
  _manifest(args),
).partOfLines(texts.lines);

/// Whether the voice of this run is in parts: a narrator's pack is (the lessons and the shell lines, [LineSet.full] or
/// [LineSet.lessons]); the nine lines of a friend are one small pack.
bool _inParts(LineSet set) => set != LineSet.own;

/// The voice ids of the lines of [texts] in [groups].
Set<String> _idsOf(VoiceTexts texts, Iterable<String> groups) => <String>{
  for (final VoicedLine l in texts.inGroups(groups.toSet()).lines) l.voId,
};

/// The choice of groups of a run in batches, and the voice ids it voices. [texts] has its groups. [refuseWaiting] (a paid
/// run): a group named with --groups that has a line not approved stops the run, listing the lines; without --groups,
/// such groups are only passed over. [asIfApproved]: no line waits.
({BatchChoice choice, Set<String> scope}) _batch(
  List<String> args,
  VoiceTexts texts,
  VoicePlan Function(Set<String>? scope) planFor, {
  required bool refuseWaiting,
  bool asIfApproved = false,
}) {
  final GroupManifest manifest = _manifest(args);
  final String? named = _option(args, '--groups');
  final List<String> candidates = named == null ? manifest.order : manifest.pick(named);
  final Set<String> waiting = asIfApproved
      ? <String>{}
      : <String>{
          for (final VoicedLine l in texts.blocked)
            if (candidates.contains(l.group)) l.group,
        };
  if (refuseWaiting && named != null && waiting.isNotEmpty) {
    throw VoiceGenFailed(
      'Nothing was sent. ${texts.inGroups(waiting).describeBlocked()}'
      'The groups ${waiting.join(', ')} have lines the owner has not approved.',
    );
  }
  final BatchChoice choice = chooseBatch(
    candidates: candidates,
    waiting: waiting,
    costOf: (Set<String> groups) => planFor(_idsOf(texts, groups)).total,
    maxCharacters: _budget(args),
  );
  return (choice: choice, scope: _idsOf(texts, choice.chosen));
}

String _home() => '${Platform.environment['USERPROFILE'] ?? '.'}${Platform.pathSeparator}nitznutz-voice';

String _outFolder(List<String> args, String character) =>
    _option(args, '--out') ?? '${_home()}${Platform.pathSeparator}$character';

void _plan(List<String> args) {
  final Map<String, Object?> config = _config(args);
  final LineSet set = _lineSet(args);
  final VoiceTexts all = _voiceTexts(args).only(set);
  final bool partsFile = _inParts(set) && File(_repo(args, 'docs/audio/voicing-parts.json')).existsSync();
  final VoiceTexts texts = _batching(args) || partsFile ? _grouped(args, all) : all;
  final Map<String, int>? partOfLine = partsFile ? _partOfLine(args, texts) : null;
  final bool asIfApproved = args.contains('--as-if-approved');
  final List<String> characters = _characters(args, config);
  final VoicePlan Function(Set<String>? scope) planFor = _planner(args, <String, VoiceProfile>{
    for (final String c in characters) c: VoiceProfile.fromConfig(config, c),
  }, asIfApproved ? texts.forTestVoices : texts.ready);
  final ({BatchChoice choice, Set<String> scope})? batch = _batching(args)
      ? _batch(args, texts, planFor, refuseWaiting: false, asIfApproved: asIfApproved)
      : null;
  final VoicePlan plan = planFor(batch?.scope);
  final double Function(String model) priceOf = _prices(args, config);
  final String model = plan.clips.isEmpty
      ? (config['modelId'] ?? '') as String
      : plan.clips.first.request.modelId;
  final double price = priceOf(model);
  stdout.writeln(_repoHeading(args));
  stdout.writeln('Lines: ${set.name}');
  if (batch != null) stdout.write(batch.choice.describe(maxCharacters: _budget(args)));
  if (asIfApproved) {
    stdout.writeln(
      'AS IF every row were approved (a count to expect: generate voices approved rows only, and refuses this flag).',
    );
  }
  stdout.writeln(
    'Words from the voice_text column of docs/review/hebrew-master.csv; only lines the owner approved '
    '(${voiceableStatuses.join(', ')}) are voiced.',
  );
  stdout.write(
    plan.describe(
      price,
      list: args.contains('--list'),
      priceSource: _option(args, '--price') != null ? '' : ' (list price in content/voices.json)',
      priceOf: priceOf,
      parts: partOfLine == null ? null : partsOfVoiceIds(partOfLine),
    ),
  );
  final VoiceTexts waiting = batch == null ? texts : texts.inGroups(batch.choice.chosen.toSet());
  if (waiting.blocked.isNotEmpty && !asIfApproved) {
    stdout
      ..writeln()
      ..write(waiting.describeBlocked())
      ..writeln(
        'Nothing is voiced until the owner marks these rows owner-approved; generate refuses until every line '
        'above is approved.',
      );
    if (set == LineSet.full && texts.blocked.any((VoicedLine l) => l.ui)) {
      stdout.writeln(
        "(--lines lessons leaves the shell's lines out of the run until their rows are approved.)",
      );
    }
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
  if (args.contains('--as-if-approved')) {
    throw const VoiceGenFailed(
      '--as-if-approved is for plan only: generate voices approved rows only. Nothing was sent.',
    );
  }
  final Map<String, Object?> config = _config(args);
  final LineSet set = _lineSet(args);
  if (!set.makesAPack) {
    throw const VoiceGenFailed(
      'a voice pack holds all the lines of a character, so --lines ui alone would replace the lessons: use --lines '
      'full (the shell\'s lines are the only new ones, and the only ones paid for), lessons or own. Nothing was sent.',
    );
  }
  final VoiceTexts all = _voiceTexts(args).only(set);
  final VoiceTexts texts = _batching(args) || _inParts(set) ? _grouped(args, all) : all;
  final Map<String, int>? partOfLine = _inParts(set) ? _partOfLine(args, texts) : null;
  final VoiceProfile profile = VoiceProfile.fromConfig(config, character);
  final Directory work = Directory(_outFolder(args, character));
  // In batches only the lines of the chosen groups need their rows approved; a whole run needs them all.
  final ({BatchChoice choice, Set<String> scope})? batch = _batching(args)
      ? _batch(
          args,
          texts,
          _planner(args, <String, VoiceProfile>{character: profile}, texts.ready),
          refuseWaiting: true,
        )
      : null;
  final VoiceTexts toVoice = batch == null ? texts : texts.inGroups(batch.choice.chosen.toSet());
  if (toVoice.blocked.isNotEmpty) throw VoiceGenFailed('Nothing was sent. ${toVoice.describeBlocked()}');
  final List<BuiltPack> built = await generateGated(
    characterId: character,
    lines: texts.ready,
    profile: profile,
    workDir: work,
    key: readKeyFile(_option(args, '--key') ?? defaultKeyPath()),
    keyboard: _keyboard,
    synth: _eleven,
    write: stdout.writeln,
    pricePer1000Chars: _prices(args, config)(profile.modelId),
    heading:
        '${_repoHeading(args)}\nLines: ${set.name}'
        '${batch == null ? '' : '\n${batch.choice.describe(maxCharacters: _budget(args))}'}',
    version: _option(args, '--pack-version') ?? '1.0.0',
    shareSameText: !args.contains('--each-id'),
    scope: batch?.scope,
    partOfLine: partOfLine,
  );
  for (final BuiltPack b in built) {
    _writePack(work, b);
  }
}

/// Free: builds the pack of [character] from the clips saved in its work folder. Nothing is voiced (the voice is the one that
/// refuses to say a word) and no ElevenLabs key is read: the key file is the one that signs packs. A line with no clip yet
/// is left out and counted.
Future<void> _pack(List<String> args) async {
  final List<String> pos = _positional(args);
  if (pos.length != 1) throw const VoiceGenFailed('pack needs one character id');
  final String character = pos.single;
  final LineSet set = _lineSet(args);
  if (!set.makesAPack) {
    throw const VoiceGenFailed(
      'a voice pack holds all the lines of a character: use --lines full, lessons or own',
    );
  }
  final VoiceTexts all = _voiceTexts(args).only(set);
  final String? named = _option(args, '--groups');
  final VoiceTexts grouped = named != null || _inParts(set) ? _grouped(args, all) : all;
  final VoiceTexts texts = named == null ? grouped : grouped.inGroups(_manifest(args).pick(named).toSet());
  final Map<String, int>? partOfLine = _inParts(set) ? _partOfLine(args, grouped) : null;
  final VoiceProfile profile = VoiceProfile.fromConfig(_config(args), character);
  final Directory work = Directory(_outFolder(args, character));
  final List<SpokenLine> lines = texts.ready;
  final VoicePlan plan = _planner(args, <String, VoiceProfile>{character: profile}, lines)(<String>{});
  stdout
    ..writeln(_repoHeading(args))
    ..writeln('Pack of $character from the clips in ${work.path}')
    ..writeln(
      'Lines with a clip: ${plan.clips.length} of ${lines.length}; the other ${lines.length - plan.clips.length} '
      'have no clip yet (or one made from another text) and are left out',
    );
  final PackKey key = readKeyFile(_option(args, '--key') ?? defaultKeyPath());
  final String version = _option(args, '--pack-version') ?? '1.0.0';
  final List<BuiltPack> built = partOfLine == null
      ? <BuiltPack>[
          await generateVoicePack(
            characterId: character,
            lines: lines,
            synth: const SilentVoice(),
            profile: profile,
            workDir: work,
            key: key,
            version: version,
            shareSameText: !args.contains('--each-id'),
            scope: <String>{},
          ),
        ]
      : await generateVoiceParts(
          characterId: character,
          lines: lines,
          synth: const SilentVoice(),
          profile: profile,
          workDir: work,
          key: key,
          partOfLine: partOfLine,
          version: version,
          shareSameText: !args.contains('--each-id'),
          scope: <String>{},
        );
  for (final BuiltPack b in built) {
    _writePack(work, b);
  }
  if (partOfLine != null) {
    final int parts = VoiceParts.read(
      File(_repo(args, 'docs/audio/voicing-parts.json')),
      _manifest(args),
    ).length;
    stdout.writeln('${built.length} of $parts parts built (a part with no clip yet is not built).');
  }
}

/// Free: every group of the manifest with its lines, the lines waiting for approval and the characters a run of that group
/// alone would send for the characters given. Groups that share sounds do not add up exactly: a sound is sent once.
void _groups(List<String> args) {
  final Map<String, Object?> config = _config(args);
  final VoiceTexts texts = _grouped(args, _voiceTexts(args).only(_lineSet(args)));
  final GroupManifest manifest = _manifest(args);
  final List<String> characters = _characters(args, config);
  final VoicePlan Function(Set<String>? scope) planFor = _planner(args, <String, VoiceProfile>{
    for (final String c in characters) c: VoiceProfile.fromConfig(config, c),
  }, texts.ready);
  stdout
    ..writeln(_repoHeading(args))
    ..writeln(
      'Groups of ${characters.join(', ')} (docs/audio/voicing-groups.json, then the shell lines), in run order:',
    );
  for (final String g in manifest.order) {
    final VoiceTexts in_ = texts.inGroups(<String>{g});
    if (in_.lines.isEmpty) continue;
    stdout.writeln(
      '  ${g.padRight(12)} ${in_.lines.length.toString().padLeft(5)} lines, ${in_.blocked.length} waiting for approval, '
      '${planFor(_idsOf(texts, <String>[g])).total} characters to send',
    );
  }
  final int loose = texts.lines.where((VoicedLine l) => l.group.isEmpty).length;
  if (loose > 0) {
    stdout.writeln(
      '  $loose lines are in no group of the manifest (run python tools/voicing_groups.py); a run by groups leaves them out.',
    );
  }
}

/// Free: checks that the clip of every approved line of the groups is in the work folder of [character], with its mouth
/// cues, is not under 2 KB, and was made from the text and settings the line has now. Exit code 1 when one is not.
void _verify(List<String> args) {
  final List<String> pos = _positional(args);
  if (pos.length != 1) throw const VoiceGenFailed('verify needs one character id');
  final Map<String, Object?> config = _config(args);
  final VoiceTexts all = _voiceTexts(args).only(_lineSet(args));
  final String? named = _option(args, '--groups');
  final VoiceTexts texts = named == null && !File(_repo(args, 'docs/audio/voicing-groups.json')).existsSync()
      ? all
      : _grouped(args, all);
  final VoiceTexts chosen = named == null ? texts : texts.inGroups(_manifest(args).pick(named).toSet());
  final VerifyReport report = verifyClips(
    workDir: Directory(_outFolder(args, pos.single)),
    profile: VoiceProfile.fromConfig(config, pos.single),
    lines: <(SpokenLine, String)>[
      for (final VoicedLine l in chosen.lines)
        if (l.problem == null) (SpokenLine(l.voId, l.text), l.group.isEmpty ? 'all' : l.group),
    ],
    unapproved: <String>[for (final VoicedLine l in chosen.blocked) l.voId],
  );
  final bool partsKnown =
      _inParts(_lineSet(args)) &&
      File(_repo(args, 'docs/audio/voicing-groups.json')).existsSync() &&
      File(_repo(args, 'docs/audio/voicing-parts.json')).existsSync();
  final String? bytesWarning = voiceBytesWarning(
    pos.single,
    distinctClipBytes(
      workDir: Directory(_outFolder(args, pos.single)),
      profile: VoiceProfile.fromConfig(config, pos.single),
      lines: <SpokenLine>[
        for (final VoicedLine l in chosen.lines)
          if (l.problem == null) SpokenLine(l.voId, l.text),
      ],
      partOfLine: partsKnown ? _partOfLine(args, _grouped(args, all)) : null,
    ),
  );
  stdout
    ..writeln(_repoHeading(args))
    ..writeln('Clips of ${pos.single} in ${_outFolder(args, pos.single)}:')
    ..write(report.describe());
  if (bytesWarning != null) stdout.writeln(bytesWarning);
  if (!report.ok) exit(1);
}

/// What `plan-lang` and `generate-lang` both need: the course's voice plan, the two voices and where the clips go.
class _LangJob {
  const _LangJob(
    this.source,
    this.frameName,
    this.frame,
    this.targetName,
    this.target,
    this.work,
    this.puppet,
  );

  final LangSource source;
  final String frameName;
  final VoiceProfile frame;
  final String targetName;
  final VoiceProfile target;
  final Directory work;

  /// The puppet's voice, or null without `--puppet-voice`.
  final PuppetVoice? puppet;
}

_LangJob _langJob(List<String> args) {
  final List<String> pos = _positional(args);
  if (pos.length != 1 || !courseLanguage.containsKey(pos.single)) {
    throw VoiceGenFailed('this command needs one course: ${courseLanguage.keys.join(', ')}');
  }
  final String course = pos.single;
  final String? voice = _option(args, '--voice');
  if (voice == null) {
    throw const VoiceGenFailed(
      '--voice <name> is needed: the voice of content/voices.json that says the target clips',
    );
  }
  final File planFile = File(_repo(args, 'content/languages/$course/voice-plan.json'));
  if (!planFile.existsSync()) throw VoiceGenFailed('${planFile.path} is missing');
  final Map<String, Object?> config = _config(args);
  final String model = _option(args, '--model') ?? '';
  VoiceProfile profile(String name) =>
      VoiceProfile.fromConfig(config, name, model: model.isEmpty ? null : model, audition: true);
  final String frameName = _option(args, '--frame-voice') ?? (course == 'heb' ? voice : 'nitzi');
  final String? puppetName = _option(args, '--puppet-voice');
  return _LangJob(
    LangSource.fromJson(jsonDecode(planFile.readAsStringSync())),
    frameName,
    profile(frameName),
    voice,
    profile(voice),
    Directory(_option(args, '--out') ?? '${_home()}${Platform.pathSeparator}lang-$course'),
    puppetName == null
        ? null
        : PuppetVoice(
            puppetName,
            profile(puppetName),
            puppetLinesIn(Directory(_repo(args, 'content/languages/$course/pack'))),
          ),
  );
}

/// A note when the clips in a course's folder were made with another model than this run would use. Every clip's hash holds its
/// model, so without `--model <the one they were made with>` all of them read as "made from another setting" and a paid run
/// would voice and charge them again. Null when the model is the same, or nothing was made yet.
String? _modelNote(_LangJob job) {
  final Set<String> made = ClipLedger(job.work).models();
  if (made.isEmpty || (made.length == 1 && made.single == job.target.modelId)) return null;
  return made.length == 1
      ? 'NOTE: the clips in ${job.work.path} were made with ${made.single}, and this run uses ${job.target.modelId} '
            '(content/voices.json). Pass --model ${made.single}, or every clip counts as made from another setting.'
      : 'NOTE: the clips in ${job.work.path} were made with ${made.join(' and ')}, and this run uses '
            '${job.target.modelId}. Pass --model with the one you mean; a clip made with another model counts as changed.';
}

AudioTool _audioTool(List<String> args) => FfmpegTool(_option(args, '--ffmpeg') ?? 'ffmpeg');

/// Free: the plan of a language course, with the figure the paid command will ask for.
Future<void> _planLang(List<String> args) async {
  final _LangJob job = _langJob(args);
  final Map<String, Object?> config = _config(args);
  final LangPlan plan = planLang(
    job.source,
    frameCharacter: job.frameName,
    frameProfile: job.frame,
    targetCharacter: job.targetName,
    targetProfile: job.target,
    workDir: job.work,
    puppet: job.puppet,
    shareSameText: !args.contains('--each-id'),
  );
  stdout.writeln(_repoHeading(args));
  stdout.writeln('Clips go to ${job.work.path}');
  final String? note = _modelNote(job);
  if (note != null) stdout.writeln(note);
  stdout.write(
    plan.describe(
      _prices(args, config),
      list: args.contains('--list'),
      priceSource: _option(args, '--price') != null ? '' : ' (list price in content/voices.json)',
      audioProblem: plan.needsAudioTool ? await _audioTool(args).unavailableReason() : null,
    ),
  );
  for (final (String name, VoiceProfile profile) in <(String, VoiceProfile)>[
    (job.frameName, job.frame),
    (job.targetName, job.target),
    if (job.puppet != null) (job.puppet!.character, job.puppet!.profile),
  ]) {
    if (profile.voiceId.isEmpty) {
      stdout.writeln(
        'VOICE ID MISSING for $name: generate-lang sends nothing until the owner has filled it in '
        '(content/voices.json, voices, $name, voiceId).',
      );
    }
  }
}

/// Free: checks that every clip of a language course is in the work folder and was made from what the plan says now.
/// Exit code 1 when one is not.
void _verifyLang(List<String> args) {
  _LangJob job = _langJob(args);
  // A check of what was made: when the clips were all made with one model and none is given, they are checked against that one
  // (and the line below says so), so a complete course is not reported as changed because the default model differs.
  String? modelLine;
  if (_option(args, '--model') == null) {
    final Set<String> made = ClipLedger(job.work).models();
    if (made.length == 1 && made.single != job.target.modelId) {
      job = _langJob(<String>[...args, '--model', made.single]);
      modelLine = 'Model ${made.single}, read from what was made (pass --model to check against another).';
    } else {
      modelLine = _modelNote(job);
    }
  }
  final LangPlan plan = planLang(
    job.source,
    frameCharacter: job.frameName,
    frameProfile: job.frame,
    targetCharacter: job.targetName,
    targetProfile: job.target,
    workDir: job.work,
    puppet: job.puppet,
    shareSameText: false,
  );
  final List<String> faulty = <String>[
    for (final PlannedClip c in plan.voices.clips)
      if (c.state != ClipState.unchanged) c.line.voId,
    for (final DerivedClip d in plan.derived)
      if (d.toMake) d.voId,
  ];
  stdout
    ..writeln(_repoHeading(args))
    ..writeln('Course ${job.source.course} in ${job.work.path}:');
  if (modelLine != null) stdout.writeln(modelLine);
  stdout.writeln(
    faulty.isEmpty
        ? 'All ${plan.voiceIds.length} clips are there and match their text.'
        : '${faulty.length} of ${plan.voiceIds.length} clips are missing or were made from another text or setting.',
  );
  for (final String id in faulty.take(40)) {
    stdout.writeln('    $id');
  }
  if (faulty.length > 40) stdout.writeln('    ... and ${faulty.length - 40} more');
  if (faulty.isNotEmpty) exit(1);
}

/// Paid: a language course, through the same gate as `generate`.
Future<void> _generateLang(List<String> args) async {
  requireTerminal(_keyboard, 'generate-lang');
  final _LangJob job = _langJob(args);
  final Map<String, Object?> config = _config(args);
  final BuiltPack built = await generateLangGated(
    source: job.source,
    frameCharacter: job.frameName,
    frameProfile: job.frame,
    targetCharacter: job.targetName,
    targetProfile: job.target,
    workDir: job.work,
    puppet: job.puppet,
    key: readKeyFile(_option(args, '--key') ?? defaultKeyPath()),
    keyboard: _keyboard,
    synth: _eleven,
    audio: _audioTool(args),
    write: stdout.writeln,
    priceOf: _prices(args, config),
    priceSource: _option(args, '--price') != null ? '' : ' (list price in content/voices.json)',
    heading: '${_repoHeading(args)}${_modelNote(job) == null ? '' : '\n${_modelNote(job)}'}',
    version: _option(args, '--pack-version') ?? '1.0.0',
    shareSameText: !args.contains('--each-id'),
  );
  _writePack(job.work, built);
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
    heading: '${_repoHeading(args)}\nClips go to ${out.path}',
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
  final Directory out = Directory(
    _option(args, '--out') ??
        '${_home()}${Platform.pathSeparator}auditions${Platform.pathSeparator}${auditionFolderName(name, clips)}',
  );
  final String title = (spec['title'] ?? name) as String;
  final String runCommand = 'dart run tool/voice_gen.dart audition-batch run ${pos[1]}';
  if (run) {
    await _gatedAudition(args, title, clips, out, runCommand);
  } else {
    stdout
      ..writeln(_repoHeading(args))
      ..writeln('Clips go to ${out.path}')
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
    if (_option(args, '--language') != null) 'language': _option(args, '--language'),
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
