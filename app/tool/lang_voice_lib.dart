// The voicing of a language course (English, Russian, Hebrew words): the clips of `content/languages/<course>/voice-plan.json`
// as a signed voice pack `voice-lang-<course>`. Each line of a course is a Hebrew clip, then one or two clips in the
// language taught (docs/languages/frame.md). The plan file lists them (tools/lang_pack.py writes it):
//
//   frameLines  the Hebrew lines: `voice` is the spoken text (plain, no "!"); a line with none is not voiced
//   targetClips the clips in the language taught: `say` is what the voice reads, or `shown` when `say` is empty
//   cutClips    single words (Hebrew course) cut from the clip of a page by the time of each word: nothing is voiced
//
// What is sent, and what is not paid for:
//  - a "!" in a target clip is sent as "." (the pre-flight check refuses "!", and a v4 voice shouts it);
//  - a text with a placeholder like {puppet} is refused: the editor gives one text for each value;
//  - a `<name>-slow` clip with the same text as `<name>` is made from the normal clip with ffmpeg (atempo), not voiced;
//  - a cut word is made from its page's clip and the character times the voice returned for it, with ffmpeg;
//  - lines with exactly the same request are voiced once and copied (voice_gen_lib.dart, sharingSameText).
// Every clip that is voiced goes through the same gate as `generate`: the plan, then the owner types the characters.
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:nitznutz/content/pack_verify.dart' show sha256Hex;

import 'audio_tool_lib.dart';
import 'pack_builder_lib.dart';
import 'voice_gen_lib.dart';

/// The `language_code` of the language each course teaches.
const Map<String, String> courseLanguage = <String, String>{'eng': 'en', 'rus': 'ru', 'heb': 'he'};

/// The name a slow copy of a target clip ends with.
const String slowSuffix = '-slow';

/// The speed of a slow copy (ffmpeg atempo): a fifth slower.
const double slowTempo = 0.8;

/// The seconds kept before and after a cut word, so that the cut does not clip its first or last sound.
const double cutPadBefore = 0.03;
const double cutPadAfter = 0.06;

final RegExp _voId = RegExp(r'^vo:[a-z0-9_.]{1,80}$');
final RegExp _placeholder = RegExp(r'\{[^{}]*\}');
const String _placeholderWhy = 'has a placeholder';
final RegExp _cutWord = RegExp(r'-w(\d+)$');

// ---- the plan file ----

class LangFrameLine {
  const LangFrameLine(this.voId, this.voice, this.review);

  final String voId;

  /// The spoken text, or null when the line has none (it is then not voiced).
  final String? voice;
  final String review;
}

class LangTargetClip {
  const LangTargetClip(this.id, this.voId, this.shown, this.say);

  final String id;
  final String voId;
  final String shown;
  final String say;

  /// What the voice reads: `say`, or `shown` when the teacher gave no spoken form.
  String get spoken => say.trim().isNotEmpty ? say : shown;
}

class LangCutClip {
  const LangCutClip(this.id, this.voId, this.from, this.text);

  final String id;
  final String voId;

  /// The id of the target clip (the page) this word is cut from.
  final String from;
  final String text;
}

/// The voice plan of one course, checked.
class LangSource {
  const LangSource({required this.course, required this.frame, required this.targets, required this.cuts});

  factory LangSource.fromJson(Object? json) {
    if (json is! Map<String, Object?>) throw const VoiceGenFailed('the voice plan is not a JSON object');
    final Object? course = json['course'];
    if (course is! String || !courseLanguage.containsKey(course)) {
      throw VoiceGenFailed(
        'the voice plan names the course "$course"; use ${courseLanguage.keys.join(', ')}',
      );
    }
    if (json['pack'] != 'lang-$course') {
      throw VoiceGenFailed('the voice plan of $course must name the pack "lang-$course"');
    }
    List<Map<String, Object?>> maps(String key) => <Map<String, Object?>>[
      for (final Object? o in (json[key] ?? <Object?>[]) as List<Object?>) o! as Map<String, Object?>,
    ];
    String voId(Map<String, Object?> m) {
      final Object? vo = m['vo'];
      if (vo is! String || !_voId.hasMatch(vo) || vo.contains('..')) {
        throw VoiceGenFailed('"$vo" is not a plain voice id');
      }
      return vo;
    }

    return LangSource(
      course: course,
      frame: <LangFrameLine>[
        for (final Map<String, Object?> m in maps('frameLines'))
          LangFrameLine(voId(m), (m['voice'] as String?)?.trim(), (m['review'] ?? '') as String),
      ],
      targets: <LangTargetClip>[
        for (final Map<String, Object?> m in maps('targetClips'))
          LangTargetClip(
            m['id']! as String,
            voId(m),
            (m['shown'] ?? '') as String,
            (m['say'] ?? '') as String,
          ),
      ],
      cuts: <LangCutClip>[
        for (final Map<String, Object?> m in maps('cutClips'))
          LangCutClip(m['id']! as String, voId(m), m['from']! as String, (m['text'] ?? '') as String),
      ],
    );
  }

  final String course;
  final List<LangFrameLine> frame;
  final List<LangTargetClip> targets;
  final List<LangCutClip> cuts;

  /// The `language_code` of the target clips.
  String get language => courseLanguage[course]!;
}

// ---- the plan ----

/// A clip made from another clip of the pack with no voice: a slow copy or a cut word.
class DerivedClip {
  const DerivedClip({
    required this.voId,
    required this.sourceVoId,
    required this.hash,
    required this.state,
    this.slow = false,
    this.word = 0,
    this.text = '',
  });

  final String voId;
  final String sourceVoId;

  /// What it is made from (the source's request, and the way): another hash means it is made again.
  final String hash;
  final ClipState state;
  final bool slow;

  /// A cut word: its place in its page (0 for the first) and its text.
  final int word;
  final String text;

  String get fileId => voId.substring('vo:'.length);
  String get sourceFileId => sourceVoId.substring('vo:'.length);
  bool get toMake => state != ClipState.unchanged;
}

String _derivedHash(Map<String, Object?> how) => sha256Hex(utf8.encode(jsonEncode(how)));

/// The folder next to [workDir] where the character times of each voiced clip are kept (a cut word needs the times of its
/// page). Not in the work folder: everything in that folder is a candidate for the pack.
Directory alignmentFolder(Directory workDir) => Directory('${normalisedFolder(workDir)}.align');

File _alignmentFile(Directory workDir, String id) =>
    File('${alignmentFolder(workDir).path}${Platform.pathSeparator}$id.json');

void _saveAlignment(Directory workDir, String id, Alignment a) {
  alignmentFolder(workDir).createSync(recursive: true);
  _alignmentFile(workDir, id).writeAsStringSync(jsonEncode(a.toJson()));
}

Alignment? _readAlignment(Directory workDir, String id) {
  final File f = _alignmentFile(workDir, id);
  return f.existsSync() ? Alignment.fromJson(jsonDecode(f.readAsStringSync()) as Map<String, Object?>) : null;
}

/// What voicing one course takes: the clips to voice (with the copies among them), the clips to make from others, the lines
/// that have no voice text, and what stops the run.
class LangPlan {
  const LangPlan({
    required this.source,
    required this.frameCharacter,
    required this.targetCharacter,
    required this.voices,
    required this.derived,
    required this.noVoice,
    required this.softened,
    required this.problems,
    required this.warnings,
  });

  final LangSource source;
  final String frameCharacter;
  final String targetCharacter;

  /// The clips to voice, the Hebrew frame lines first and then the target clips.
  final VoicePlan voices;
  final List<DerivedClip> derived;

  /// Frame lines with no voice text.
  final List<String> noVoice;

  /// Target clips whose "!" is sent as ".".
  final int softened;

  /// What stops the run besides the pre-flight check of the texts.
  final List<TextProblem> problems;
  final List<String> warnings;

  int get total => voices.total;

  /// Everything that stops the run: the texts the check refuses, and the other problems. A clip with a placeholder is
  /// named once (by [problems]), not again for each letter of the name inside the braces.
  List<TextProblem> get refusals {
    final Set<String> named = <String>{
      for (final TextProblem p in problems)
        if (p.why.contains(_placeholderWhy)) p.id,
    };
    return <TextProblem>[...voices.problems.where((TextProblem p) => !named.contains(p.id)), ...problems];
  }

  int get slowToMake => derived.where((DerivedClip d) => d.slow && d.toMake).length;
  int get cutToMake => derived.where((DerivedClip d) => !d.slow && d.toMake).length;
  bool get needsAudioTool => derived.any((DerivedClip d) => d.toMake);

  /// Every voice id of the pack, sorted.
  List<String> get voiceIds =>
      <String>[...voices.clips.map((PlannedClip c) => c.line.voId), ...derived.map((DerivedClip d) => d.voId)]
        ..sort();

  /// The plan as the owner reads it. [audioProblem] is why ffmpeg cannot be used here, or null; [inRun] is true inside a
  /// `generate-lang` run, which asks for the total right after.
  String describe(
    double Function(String model) priceOf, {
    bool list = false,
    String priceSource = '',
    bool inRun = false,
    String? audioProblem,
  }) {
    final StringBuffer b = StringBuffer()
      ..writeln(
        'Course ${source.course} (pack lang-${source.course}), voice pack voice-lang-${source.course}',
      )
      ..writeln(
        'Hebrew frame lines are voiced by $frameCharacter, the clips in ${source.language} by $targetCharacter',
      )
      ..writeln(
        'Frame lines ${source.frame.length}, target clips ${source.targets.length}, cut words ${source.cuts.length}',
      )
      ..write(voices.describeVoices());
    if (noVoice.isNotEmpty) {
      b.writeln('Frame lines with no voice text, not voiced: ${noVoice.length}');
    }
    if (softened > 0) b.writeln('Target clips sent with "." for their "!": $softened');
    if (derived.isNotEmpty) {
      b.writeln(
        'Made from another clip with ffmpeg, no voice and no cost: slow copies at $slowTempo times the speed '
        '$slowToMake, cut words $cutToMake (of ${derived.length} in the pack)',
      );
    }
    for (final String w in warnings) {
      b.writeln('Note: $w');
    }
    if (list) {
      b
        ..writeln()
        ..write(voices.describeClips());
    }
    b
      ..writeln()
      ..write(
        voices.describeTotals(
          priceOf(voices.clips.firstOrNull?.request.modelId ?? ''),
          priceSource: priceSource,
          priceOf: priceOf,
        ),
      );
    final List<TextProblem> refused = refusals;
    if (needsAudioTool && audioProblem != null) {
      b
        ..writeln()
        ..writeln('BLOCKED: $audioProblem');
    }
    if (refused.isNotEmpty) {
      b
        ..writeln()
        ..writeln(
          'The check refuses ${refused.length} texts; generate-lang sends nothing until they are fixed:',
        );
      for (final TextProblem p in refused) {
        b.writeln('  $p');
      }
    } else if (voices.clips.isEmpty) {
      b
        ..writeln()
        ..writeln('Nothing to voice yet.');
    } else if (inRun) {
      b
        ..writeln()
        ..writeln('This run sends the $total characters above, and nothing else.');
    } else {
      b
        ..writeln()
        ..writeln(
          'Nothing is sent by this command. In a terminal, `generate-lang ${source.course}` makes this plan again and '
          'asks you to type the characters to send: the count of exactly what that run sends.',
        );
    }
    return b.toString();
  }
}

/// The plan for voicing [source]: the Hebrew frame lines with [frameProfile] (as [frameCharacter]) and the clips in the
/// language taught with [targetProfile]. [workDir] tells which clips exist already.
LangPlan planLang(
  LangSource source, {
  required String frameCharacter,
  required VoiceProfile frameProfile,
  required String targetCharacter,
  required VoiceProfile targetProfile,
  required Directory workDir,
  bool shareSameText = true,
}) {
  final Map<String, String> made = ClipLedger(workDir).hashes();
  final Set<String> pages = <String>{for (final LangCutClip c in source.cuts) c.from};
  int softened = 0;
  final List<TextProblem> problems = <TextProblem>[];
  final List<String> warnings = <String>[];

  // What is sent for each target clip: the spoken text, with "." for "!".
  final Map<String, SpokenLine> sent = <String, SpokenLine>{};
  for (final LangTargetClip t in source.targets) {
    final String text = t.spoken.replaceAll('!', '.');
    if (text != t.spoken) softened++;
    sent[t.id] = SpokenLine(t.voId, text);
  }

  // A `-slow` clip with the same text as its normal clip is made from it.
  final Set<String> slowIds = <String>{
    for (final LangTargetClip t in source.targets)
      if (t.id.endsWith(slowSuffix) &&
          sent[t.id.substring(0, t.id.length - slowSuffix.length)]?.text == sent[t.id]!.text)
        t.id,
  };
  final int slowOwnText = source.targets
      .where((LangTargetClip t) => t.id.endsWith(slowSuffix) && !slowIds.contains(t.id))
      .length;
  if (slowOwnText > 0) {
    warnings.add('$slowOwnText "-slow" clips have a text of their own, or no normal clip, and are voiced');
  }
  final int needsEditor = source.frame
      .where((LangFrameLine f) => f.voice != null && f.voice!.isNotEmpty && f.review == 'needs-editor')
      .length;
  if (needsEditor > 0) {
    warnings.add('$needsEditor Hebrew frame lines are still marked needs-editor in the course');
  }

  final List<PlannedClip> clips = <PlannedClip>[];
  final List<String> noVoice = <String>[];
  void plan(String character, VoiceProfile profile, SpokenLine line, String language, {bool page = false}) {
    final ClipRequest request = profile.requestFor(line, language: language);
    final RegExpMatch? holder = _placeholder.firstMatch(line.text);
    if (holder != null) {
      problems.add(
        TextProblem(
          line.voId,
          '',
          '$_placeholderWhy ${holder.group(0)} that is not filled in: it needs one text for each value (the editor '
              'gives them), because a placeholder is never sent',
        ),
      );
    }
    final ClipState state = clipState(workDir, line.fileId, request, made);
    // A page whose character times were not kept cannot give its words: it is voiced again.
    final bool lostTimes =
        page && state == ClipState.unchanged && _readAlignment(workDir, line.fileId) == null;
    clips.add(PlannedClip(character, line, request, lostTimes ? ClipState.changed : state));
  }

  for (final LangFrameLine f in source.frame) {
    if (f.voice == null || f.voice!.isEmpty) {
      noVoice.add(f.voId);
    } else {
      plan(frameCharacter, frameProfile, SpokenLine(f.voId, f.voice!), 'he');
    }
  }
  for (final LangTargetClip t in source.targets) {
    if (slowIds.contains(t.id)) continue;
    plan(targetCharacter, targetProfile, sent[t.id]!, source.language, page: pages.contains(t.id));
  }
  final Map<String, ClipRequest> requestOf = <String, ClipRequest>{
    for (final PlannedClip c in clips) c.line.voId: c.request,
  };

  final List<DerivedClip> derived = <DerivedClip>[];
  for (final LangTargetClip t in source.targets) {
    if (!slowIds.contains(t.id)) continue;
    final LangTargetClip base = source.targets.firstWhere(
      (LangTargetClip o) => o.id == t.id.substring(0, t.id.length - slowSuffix.length),
    );
    final String hash = _derivedHash(<String, Object?>{
      'op': 'slow',
      'tempo': slowTempo,
      'source': requestOf[base.voId]!.hash,
    });
    derived.add(
      DerivedClip(
        voId: t.voId,
        sourceVoId: base.voId,
        hash: hash,
        state: clipStateOfHash(workDir, t.voId.substring(3), hash, made),
        slow: true,
      ),
    );
  }

  for (final LangCutClip c in source.cuts) {
    final LangTargetClip? page = source.targets.where((LangTargetClip t) => t.id == c.from).firstOrNull;
    final ClipRequest? request = page == null ? null : requestOf[page.voId];
    final RegExpMatch? number = _cutWord.firstMatch(c.id);
    if (request == null || number == null) {
      problems.add(
        TextProblem(
          c.voId,
          '',
          request == null
              ? 'is cut from "${c.from}", which is not a voiced target clip'
              : 'has no -w<number> at the end of its id, so its place in the page is not known',
        ),
      );
      continue;
    }
    final int word = int.parse(number.group(1)!) - 1;
    final RegExp space = RegExp(r'\s+');
    // The words are those of the screen text; the times are those of the spoken text, so both must have the same words.
    final List<String> shownWords = page!.shown.replaceAll('!', '.').trim().split(space);
    final int spokenWords = request.text.trim().split(space).length;
    final String wanted = c.text.replaceAll('!', '.');
    if (word < 0 || word >= shownWords.length || shownWords[word] != wanted) {
      problems.add(
        TextProblem(
          c.voId,
          '',
          'is word ${word + 1} of "${c.from}", which does not read "$wanted" there (the page shows "${page.shown}")',
        ),
      );
      continue;
    }
    if (spokenWords != shownWords.length) {
      problems.add(
        TextProblem(
          c.voId,
          '',
          'is cut from "${c.from}", which is voiced as $spokenWords words and shown as ${shownWords.length}: the '
              'times of the words would not line up',
        ),
      );
      continue;
    }
    final String hash = _derivedHash(<String, Object?>{
      'op': 'cut',
      'source': request.hash,
      'word': word,
      'text': wanted,
      'before': cutPadBefore,
      'after': cutPadAfter,
    });
    derived.add(
      DerivedClip(
        voId: c.voId,
        sourceVoId: page.voId,
        hash: hash,
        state: clipStateOfHash(workDir, c.voId.substring(3), hash, made),
        word: word,
        text: wanted,
      ),
    );
  }

  final List<String> characters = <String>[
    frameCharacter,
    if (targetCharacter != frameCharacter) targetCharacter,
  ];
  return LangPlan(
    source: source,
    frameCharacter: frameCharacter,
    targetCharacter: targetCharacter,
    voices: VoicePlan(
      characters: characters,
      lines: <SpokenLine>[for (final PlannedClip c in clips) c.line],
      clips: shareSameText ? sharingSameText(clips) : clips,
    ),
    derived: derived,
    noVoice: noVoice,
    softened: softened,
    problems: problems,
    warnings: warnings,
  );
}

// ---- making the pack ----

/// The first and last character of word number [word] (0 for the first) among the characters of [chars], where a word
/// is what lies between white space; null when there are fewer words.
({int first, int last})? wordSpan(List<String> chars, int word) {
  int seen = -1;
  int i = 0;
  while (i < chars.length) {
    if (chars[i].trim().isEmpty) {
      i++;
      continue;
    }
    final int first = i;
    while (i < chars.length && chars[i].trim().isNotEmpty) {
      i++;
    }
    if (++seen == word) return (first: first, last: i - 1);
  }
  return null;
}

/// The cues of a slow copy: those of the normal clip, [tempo] times as fast, so each is later by the same factor.
List<(int, int)> slowCues(List<(int, int)> cues, double tempo) {
  final List<(int, int)> out = <(int, int)>[];
  int last = -1;
  for (final (int t, int o) in cues) {
    final int at = (t / tempo).round();
    out.add((at <= last ? last + 1 : at, o));
    last = out.last.$1;
  }
  return out;
}

Future<void> _makeSlow(Directory workDir, DerivedClip d, AudioTool audio, ClipLedger ledger) async {
  final Uint8List sound = await audio.slow(audioBytesOf(workDir, d.sourceFileId), slowTempo);
  writeClip(workDir, d.fileId, 'mp3', sound, slowCues(readCues(workDir, d.sourceFileId), slowTempo));
  ledger.recordMade(d.fileId, 'vo.${d.fileId}.mp3', d.hash, 'slow $slowTempo of ${d.sourceVoId}');
}

Future<void> _makeCut(Directory workDir, DerivedClip d, AudioTool audio, ClipLedger ledger) async {
  final Alignment? page = _readAlignment(workDir, d.sourceFileId);
  if (page == null) {
    throw VoiceGenFailed(
      'the character times of ${d.sourceVoId} are missing, so ${d.voId} cannot be cut from it',
    );
  }
  final ({int first, int last})? span = wordSpan(page.characters, d.word);
  if (span == null) {
    throw VoiceGenFailed(
      'the times of ${d.sourceVoId} have no word ${d.word + 1} for ${d.voId} to be cut from',
    );
  }
  final double from = (page.starts[span.first] - cutPadBefore).clamp(0, double.infinity);
  final double to = page.ends[span.last] + cutPadAfter;
  final Uint8List sound = await audio.cut(audioBytesOf(workDir, d.sourceFileId), from, to);
  final Alignment word = Alignment(
    page.characters.sublist(span.first, span.last + 1),
    <double>[for (int i = span.first; i <= span.last; i++) (page.starts[i] - from).clamp(0, double.infinity)],
    <double>[for (int i = span.first; i <= span.last; i++) (page.ends[i] - from).clamp(0, double.infinity)],
  );
  writeClip(workDir, d.fileId, 'mp3', sound, cuesFromAlignment(word));
  ledger.recordMade(d.fileId, 'vo.${d.fileId}.mp3', d.hash, 'cut word ${d.word + 1} of ${d.sourceVoId}');
}

/// `generate-lang` for one course, gated like `generate`: checks the terminal, plans in this process, prints the plan,
/// refuses what cannot be sent (a refused text, a voice with no id, ffmpeg missing when a slow copy or a cut word has to be
/// made), asks the owner to type the characters, and only then asks for the voice ([synth], which reads the key). It voices
/// the new and changed clips, makes the slow copies and the cut words, and builds `voice-lang-<course>`.
Future<BuiltPack> generateLangGated({
  required LangSource source,
  required String frameCharacter,
  required VoiceProfile frameProfile,
  required String targetCharacter,
  required VoiceProfile targetProfile,
  required Directory workDir,
  required PackKey key,
  required Keyboard keyboard,
  required Synthesizer Function() synth,
  required AudioTool audio,
  required void Function(String) write,
  required double Function(String model) priceOf,
  String priceSource = '',
  String heading = '',
  String version = '1.0.0',
  bool shareSameText = true,
}) async {
  requireTerminal(keyboard, 'generate-lang');
  if (heading.isNotEmpty) write(heading);
  checkWorkFolder(workDir);
  final LangPlan plan = planLang(
    source,
    frameCharacter: frameCharacter,
    frameProfile: frameProfile,
    targetCharacter: targetCharacter,
    targetProfile: targetProfile,
    workDir: workDir,
    shareSameText: shareSameText,
  );
  final String? audioProblem = plan.needsAudioTool ? await audio.unavailableReason() : null;
  write(plan.describe(priceOf, priceSource: priceSource, inRun: true, audioProblem: audioProblem));
  for (final (String name, VoiceProfile profile) in <(String, VoiceProfile)>[
    (frameCharacter, frameProfile),
    (targetCharacter, targetProfile),
  ]) {
    if (profile.voiceId.isEmpty) {
      throw VoiceGenFailed(
        'no voice id yet for "$name" in content/voices.json. Nothing was sent. The owner copies the id from the '
        'ElevenLabs Voice Library first.',
      );
    }
  }
  final List<TextProblem> refused = plan.refusals;
  if (refused.isNotEmpty) {
    throw VoiceGenFailed(
      'the check refuses ${refused.length} texts. Nothing was sent:\n${refused.join('\n')}',
    );
  }
  if (audioProblem != null) throw VoiceGenFailed('$audioProblem Nothing was sent.');
  final Synthesizer voice;
  if (plan.total == 0) {
    voice = const SilentVoice();
  } else {
    requireTyped(keyboard, plan.total, 'voicing the ${source.course} course', write);
    voice = synth();
  }
  return _makeLangPack(plan, voice, audio, workDir, key, version, write);
}

Future<BuiltPack> _makeLangPack(
  LangPlan plan,
  Synthesizer voice,
  AudioTool audio,
  Directory workDir,
  PackKey key,
  String version,
  void Function(String) write,
) async {
  final ClipLedger ledger = ClipLedger(workDir);
  if (isInsideFolder(ledger.file, workDir)) {
    throw VoiceGenFailed('the hashes of ${workDir.path} would land inside it. Nothing was sent.');
  }
  workDir.createSync(recursive: true);
  final List<PlannedClip> clips = plan.voices.clips;
  // The clips that hold their own sound first, then the copies, which need theirs to be there.
  for (final bool copies in <bool>[false, true]) {
    for (final PlannedClip c in clips) {
      if (c.isCopy != copies || c.state == ClipState.unchanged) continue;
      final String id = c.line.fileId;
      if (copies) {
        final String from = c.copyOf!.substring('vo:'.length);
        final String extension = audioNameOf(workDir, from).split('.').last;
        writeClip(workDir, id, extension, audioBytesOf(workDir, from), readCues(workDir, from));
        final Alignment? times = _readAlignment(workDir, from);
        if (times != null) _saveAlignment(workDir, id, times);
        ledger.record(id, 'vo.$id.$extension', c.request);
        write('copied $id');
      } else {
        final Synthesis s = await voice.say(c.request);
        writeClip(workDir, id, s.extension, s.audio, cuesFromAlignment(s.alignment));
        _saveAlignment(workDir, id, s.alignment);
        ledger.record(id, 'vo.$id.${s.extension}', c.request);
        write('said $id');
      }
    }
  }
  for (final DerivedClip d in plan.derived.where((DerivedClip d) => d.toMake)) {
    if (d.slow) {
      await _makeSlow(workDir, d, audio, ledger);
    } else {
      await _makeCut(workDir, d, audio, ledger);
    }
    write('made ${d.fileId}');
  }
  final Map<String, String> holder = <String, String>{
    for (final PlannedClip c in clips) c.line.voId: c.copyOf ?? c.line.voId,
  };
  final List<Map<String, String>> vo = <Map<String, String>>[
    for (final String voId in plan.voiceIds)
      <String, String>{
        'id': voId.substring('vo:'.length),
        'file': audioNameOf(workDir, (holder[voId] ?? voId).substring('vo:'.length)),
      },
  ];
  File('${workDir.path}${Platform.pathSeparator}pack.json').writeAsStringSync(
    jsonEncode(<String, Object?>{
      'schema': 'pack-source/v1',
      'id': 'voice-lang-${plan.source.course}',
      'version': version,
      'minAppVersion': '0.5.0',
      'assets': <Object?>[],
      'vo': vo,
    }),
  );
  return buildStagedPack(workDir, vo, key);
}
