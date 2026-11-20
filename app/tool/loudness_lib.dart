// Loudness of the voice packs, made level at pack-build time (never at play time). Free, local and keyless: it reads finished
// voice packs, measures every clip with ffmpeg (EBU R128 integrated loudness and true peak), gives each clip its own gain
// to the target with a true-peak limiter, encodes it again as the app expects (MP3, mono, 44.1 kHz, 64 kbps, never a
// change of speed or length) and builds a pack of the same ids and cues under a new version, signed with the owner's
// pack-signing key. It sends nothing over the network and reads no key of any voice service; a test pins both.
//
// Why a pack and not the work folder: the pack already says which line has which clip (and which lines share one), so the
// result is the same pack in the same parts, whatever the lines, groups or parts were, and the clips in the work folders and
// their `.voiced.jsonl` records are never touched, so `verify` still passes on the originals.
//
// ffmpeg is started once for a batch of clips, never once for a clip: a start costs about a second on a PC with a virus
// scanner, and a voice is 4,000 clips.
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:nitznutz/content/pack_verify.dart';
import 'package:nitznutz/content/zip_store.dart' show ZipLimits;

import 'audio_tool_lib.dart' show ffmpegMissing, mp3Output;
import 'pack_builder_lib.dart';
import 'voice_text_lib.dart' show VoiceGenFailed;

/// The loudness every clip is brought to: integrated LUFS, the level of the voices that were loud enough.
const double targetLufs = -16;

/// The loudest a clip may peak after it is encoded, in dBTP (true peak).
const double maxTruePeak = -1;

/// A clip is "on target" when its integrated loudness is within this many LU of the target (the voice director's 1.5 LU).
const double onTargetLu = 1.5;

/// The limiter starts here (dBFS, sample peak): a little under [maxTruePeak], because the true peak of the encoded clip is
/// higher than the sample peak of the one that went in. Every clip is measured again after it is encoded and, if its true peak
/// is still over [maxTruePeak], made again with the limiter lower.
const double _limiterStart = -2.0;

/// A clip is never given more gain than takes its peak this far (dB) above the limiter: a clip with one sharp peak far above its
/// body would otherwise be squashed to get its loudness. It stays quieter than the target instead, and is listed as off target.
/// `--max-limit` changes it.
const double defaultMaxLimiting = 10;

/// A clip whose second measurement is further than this from the target gets its gain corrected (the limiter takes some
/// level off a clip with sharp peaks).
const double _correctAbove = 0.3;
const double _maxGain = 30;
const double _minGain = -30;
const int _rounds = 8;

/// The gain of a clip is corrected only in the first rounds; the last ones only put the peaks right, so the run always ends.
const int _correctingRounds = 3;

/// A clip with no integrated loudness gets one estimated from its peak: the peak of the pack's clips is this far above their
/// integrated loudness (their median), or this much when none could be measured.
const double _defaultPeakAbove = 16;

// ---- what ffmpeg says ----

/// The loudness of one clip. [lufs] is null when the clip is shorter than 0.4 s (or too quiet) to be measured.
class Loudness {
  const Loudness({required this.lufs, required this.truePeak});

  final double? lufs;

  /// dBTP: negative infinity for a clip of digital silence.
  final double truePeak;

  bool get silent => truePeak == double.negativeInfinity;

  /// The part of a clip's peak above its loudness, in dB; null when either is not known.
  double? get peakAbove => lufs == null || silent ? null : truePeak - lufs!;
}

double _db(String text) => text == '-inf' ? double.negativeInfinity : double.parse(text);

final RegExp _summary = RegExp(r'ebur128@m(\d+) @ [^\]]*\] Summary:([^\[]*)');
final RegExp _integrated = RegExp(r'Integrated loudness:\s*I:\s*(-?[\d.]+|-inf)\s*LUFS');
final RegExp _peak = RegExp(r'True peak:\s*Peak:\s*(-?[\d.]+|-inf)\s*dBFS');

/// The summaries of an ffmpeg run of [measureArguments], by the number of the clip. `-70` is what ffmpeg says when it has no
/// loudness to give.
Map<int, Loudness> parseSummaries(String log) {
  final Map<int, Loudness> out = <int, Loudness>{};
  for (final RegExpMatch m in _summary.allMatches(log)) {
    final String block = m.group(2)!;
    final RegExpMatch? i = _integrated.firstMatch(block);
    final RegExpMatch? p = _peak.firstMatch(block);
    if (i == null || p == null) {
      throw const VoiceGenFailed('ffmpeg gave a loudness summary this tool cannot read');
    }
    final double lufs = _db(i.group(1)!);
    out[int.parse(m.group(1)!)] = Loudness(lufs: lufs <= -69.95 ? null : lufs, truePeak: _db(p.group(1)!));
  }
  return out;
}

/// The ffmpeg arguments that measure every file in [inputs] at once (one `ebur128` for each, named `m<number>`).
List<String> measureArguments(List<String> inputs) => <String>[
  '-nostdin',
  '-hide_banner',
  '-nostats',
  '-loglevel',
  'info',
  for (final String i in inputs) ...<String>['-i', i],
  '-filter_complex',
  <String>[for (int k = 0; k < inputs.length; k++) '[$k:a]ebur128@m$k=peak=true:framelog=quiet[o$k]']
      .join(';'),
  for (int k = 0; k < inputs.length; k++) ...<String>['-map', '[o$k]', '-f', 'null', '-'],
];

/// One clip to make again: [gainDb] on top, then a limiter at [ceilingDb] (dBFS).
class RenderJob {
  const RenderJob(this.input, this.output, this.gainDb, this.ceilingDb);

  final String input;
  final String output;
  final double gainDb;
  final double ceilingDb;
}

/// The ffmpeg arguments that make every job at once: gain, then a limiter with the level control off (it would otherwise
/// bring the clip back to full scale), then the same MP3 the voice's own clips are. No filter changes the speed.
List<String> renderArguments(List<RenderJob> jobs) => <String>[
  '-nostdin',
  '-hide_banner',
  '-nostats',
  '-loglevel',
  'error',
  '-y',
  for (final RenderJob j in jobs) ...<String>['-i', j.input],
  '-filter_complex',
  <String>[
    for (int k = 0; k < jobs.length; k++)
      '[$k:a]volume=${jobs[k].gainDb.toStringAsFixed(3)}dB:precision=double,'
          'alimiter=limit=${math.pow(10, jobs[k].ceilingDb / 20).toStringAsFixed(5)}:attack=5:release=60:level=0[o$k]',
  ].join(';'),
  for (int k = 0; k < jobs.length; k++) ...<String>['-map', '[o$k]', ...mp3Output, jobs[k].output],
];

/// What the tool needs of ffmpeg; tests may stand in for it.
abstract interface class LoudnessTool {
  /// Why the tool cannot be used on this PC, or null when it can.
  Future<String?> unavailableReason();

  /// The loudness of each of [clips], in the same order.
  Future<List<Loudness>> measure(List<File> clips);

  /// Makes every job's output from its input.
  Future<void> render(List<RenderJob> jobs);
}

/// ffmpeg, started with an argument list (never through a shell), once for each [batch] clips and at most [jobs] at a time.
class FfmpegLoudness implements LoudnessTool {
  const FfmpegLoudness({this.executable = 'ffmpeg', this.batch = 32, this.jobs = 3});

  final String executable;
  final int batch;
  final int jobs;

  @override
  Future<String?> unavailableReason() async {
    try {
      final ProcessResult r = await Process.run(executable, const <String>['-version']);
      return r.exitCode == 0 ? null : ffmpegMissing;
    } on ProcessException {
      return ffmpegMissing;
    }
  }

  @override
  Future<List<Loudness>> measure(List<File> clips) async {
    final List<Loudness?> out = List<Loudness?>.filled(clips.length, null);
    await _inBatches(clips.length, (int from, int to) async {
      final String log = await _run(
        measureArguments(<String>[for (int i = from; i < to; i++) clips[i].path]),
      );
      final Map<int, Loudness> found = parseSummaries(log);
      for (int i = from; i < to; i++) {
        out[i] = found[i - from] ?? (throw VoiceGenFailed('ffmpeg did not measure ${clips[i].path}'));
      }
    });
    return out.cast<Loudness>();
  }

  @override
  Future<void> render(List<RenderJob> jobs) => _inBatches(jobs.length, (int from, int to) async {
    await _run(renderArguments(jobs.sublist(from, to)));
    for (final RenderJob j in jobs.sublist(from, to)) {
      final File made = File(j.output);
      if (!made.existsSync() || made.lengthSync() == 0) {
        throw VoiceGenFailed('ffmpeg made no clip for ${j.input}');
      }
    }
  });

  Future<void> _inBatches(int count, Future<void> Function(int from, int to) body) async {
    final List<(int, int)> ranges = <(int, int)>[
      for (int from = 0; from < count; from += batch) (from, math.min(from + batch, count)),
    ];
    int next = 0;
    bool failed = false;
    Future<void> worker() async {
      while (!failed && next < ranges.length) {
        final (int, int) r = ranges[next++];
        try {
          await body(r.$1, r.$2);
        } catch (_) {
          failed = true;
          rethrow;
        }
      }
    }

    await Future.wait(<Future<void>>[for (int i = 0; i < math.min(jobs, ranges.length); i++) worker()]);
  }

  Future<String> _run(List<String> arguments) async {
    try {
      final ProcessResult r = await Process.run(executable, arguments);
      if (r.exitCode != 0) {
        throw VoiceGenFailed('ffmpeg stopped with exit code ${r.exitCode}: ${_lastLine(r.stderr)}');
      }
      return '${r.stderr}';
    } on ProcessException {
      throw const VoiceGenFailed(ffmpegMissing);
    }
  }
}

String _lastLine(Object? text) {
  final List<String> lines = '$text'.trim().split(RegExp(r'[\r\n]+'));
  return lines.isEmpty ? '' : lines.last;
}

// ---- the clips ----

/// What was done to one clip.
class ClipResult {
  const ClipResult({
    required this.file,
    required this.before,
    required this.after,
    required this.gainDb,
    required this.limitedDb,
    required this.notes,
  });

  final String file;
  final Loudness before;
  final Loudness after;

  /// The gain given, in dB.
  final double gainDb;

  /// How far the limiter had to take the loudest peak down, in dB (0: not at all).
  final double limitedDb;

  /// `short` (no integrated loudness: the gain came from the peak), `silent`, `gain capped`, `off target`.
  final List<String> notes;

  Map<String, Object?> toJson() => <String, Object?>{
    'file': file,
    'lufsBefore': before.lufs,
    'truePeakBefore': before.silent ? null : before.truePeak,
    'lufsAfter': after.lufs,
    'truePeakAfter': after.silent ? null : after.truePeak,
    'gainDb': double.parse(gainDb.toStringAsFixed(2)),
    'limitedDb': double.parse(limitedDb.toStringAsFixed(2)),
    if (notes.isNotEmpty) 'notes': notes,
  };
}

/// The most gain [clip] may be given with the limiter at [ceiling] (dBFS).
double _gainCap(Loudness clip, double ceiling, double maxLimiting) =>
    math.min(_maxGain, ceiling - clip.truePeak + maxLimiting);

double _median(List<double> sorted) {
  final int n = sorted.length;
  return n.isOdd ? sorted[n ~/ 2] : (sorted[n ~/ 2 - 1] + sorted[n ~/ 2]) / 2;
}

/// How much the peaks of these clips stand above their loudness, as a median; [_defaultPeakAbove] when none could be measured.
double medianPeakAbove(Iterable<Loudness> clips) {
  final List<double> above = <double>[
    for (final Loudness l in clips)
      if (l.peakAbove != null) l.peakAbove!,
  ]..sort();
  return above.isEmpty ? _defaultPeakAbove : _median(above);
}

/// Minimum, median and maximum of the integrated loudness and the loudest true peak of a set of clips.
class LoudnessStats {
  factory LoudnessStats(Iterable<Loudness> clips) {
    final List<double> lufs = <double>[
      for (final Loudness l in clips)
        if (l.lufs != null) l.lufs!,
    ]..sort();
    double peak = double.negativeInfinity;
    int unmeasured = 0;
    int count = 0;
    for (final Loudness l in clips) {
      count++;
      if (l.lufs == null) unmeasured++;
      peak = math.max(peak, l.truePeak);
    }
    return LoudnessStats._(
      count,
      unmeasured,
      lufs.isEmpty ? null : lufs.first,
      lufs.isEmpty ? null : _median(lufs),
      lufs.isEmpty ? null : lufs.last,
      peak,
    );
  }

  const LoudnessStats._(this.clips, this.unmeasured, this.min, this.median, this.max, this.maxTruePeak);

  final int clips;

  /// Clips with no integrated loudness (shorter than 0.4 s, or silent).
  final int unmeasured;
  final double? min;
  final double? median;
  final double? max;
  final double maxTruePeak;

  String describe() {
    String n(double? v) => v == null ? 'n/a' : v.toStringAsFixed(1);
    return 'LUFS min ${n(min)}, median ${n(median)}, max ${n(max)}; loudest true peak ${n(maxTruePeak)} dBTP';
  }

  Map<String, Object?> toJson() => <String, Object?>{
    'clips': clips,
    'unmeasured': unmeasured,
    'lufsMin': min,
    'lufsMedian': median,
    'lufsMax': max,
    'maxTruePeak': maxTruePeak,
  };
}

/// Brings every clip of [inputs] to [target] and writes it to the same place in [outputs] (MP3 again), and returns what was
/// done to each.
///
/// The gain is [target] minus the measured loudness. A clip too short to have a loudness (under 0.4 s) is given the gain its peak
/// asks for, taking the peaks of this set of clips to stand as far above their loudness as the median of those that were
/// measured does. A clip of digital silence is copied as it is. A limiter takes the peaks to [_limiterStart]; every clip is
/// then measured again, and one whose true peak is over [maxTruePeak] is made again with the limiter lower, one that the
/// limiter left quieter than the target is made again with the gain corrected, up to [_rounds] times. A clip whose true peak is
/// still over [maxTruePeak] after that stops the run.
Future<List<ClipResult>> normaliseClips({
  required List<File> inputs,
  required List<File> outputs,
  required LoudnessTool tool,
  List<String>? labels,
  double target = targetLufs,
  double maxLimiting = defaultMaxLimiting,
  void Function(String)? progress,
}) async {
  final int n = inputs.length;
  progress?.call('measuring $n clips');
  final List<Loudness> before = await tool.measure(inputs);
  final double peakAbove = medianPeakAbove(before);
  final List<double> gain = <double>[
    for (final Loudness l in before)
      l.silent
          ? 0
          : (target - (l.lufs ?? l.truePeak - peakAbove))
                .clamp(_minGain, _gainCap(l, _limiterStart, maxLimiting))
                .toDouble(),
  ];
  final List<double> ceiling = List<double>.filled(n, _limiterStart);
  final List<Loudness> after = List<Loudness>.of(before);
  final List<double> limited = List<double>.filled(n, 0);
  final List<bool> capped = List<bool>.filled(n, false);
  final List<bool> peakFailed = List<bool>.filled(n, false);
  List<int> pending = <int>[];
  for (int i = 0; i < n; i++) {
    if (before[i].silent) {
      outputs[i].writeAsBytesSync(inputs[i].readAsBytesSync());
    } else {
      pending.add(i);
    }
  }
  for (int round = 1; pending.isNotEmpty && round <= _rounds; round++) {
    progress?.call('round $round: encoding ${pending.length} clips');
    await tool.render(<RenderJob>[
      for (final int i in pending) RenderJob(inputs[i].path, outputs[i].path, gain[i], ceiling[i]),
    ]);
    final List<Loudness> measured = await tool.measure(<File>[for (final int i in pending) outputs[i]]);
    final List<int> again = <int>[];
    for (int k = 0; k < pending.length; k++) {
      final int i = pending[k];
      final Loudness a = measured[k];
      after[i] = a;
      limited[i] = math.max(0, before[i].truePeak + gain[i] - ceiling[i]);
      bool retry = false;
      if (a.truePeak > maxTruePeak) {
        // The limiter works on the sample peak and the encoder adds its own overshoot, which does not follow the ceiling
        // closely: each round steps further than the last, and a clip that peaked over is not given more gain again.
        ceiling[i] -= a.truePeak - maxTruePeak + 0.4 + 0.3 * (round - 1);
        peakFailed[i] = true;
        retry = true;
      }
      if (!peakFailed[i] && round <= _correctingRounds && a.lufs != null && before[i].lufs != null) {
        final double missing = target - a.lufs!;
        final double asked = gain[i] + missing;
        final double wanted = asked.clamp(_minGain, _gainCap(before[i], ceiling[i], maxLimiting)).toDouble();
        if (wanted < asked - 0.05) capped[i] = true;
        if (missing.abs() > _correctAbove && (wanted - gain[i]).abs() > 0.05) {
          gain[i] = wanted;
          retry = true;
        }
      }
      if (retry) again.add(i);
    }
    pending = again;
  }
  // Only a true peak is made again after the correcting rounds, so what is still pending here peaks over the limit.
  final List<String> over = <String>[
    for (final int i in pending)
      if (after[i].truePeak > maxTruePeak) inputs[i].path,
  ];
  if (over.isNotEmpty) {
    throw VoiceGenFailed(
      '${over.length} clips still peak over ${maxTruePeak.toStringAsFixed(0)} dBTP after $_rounds rounds, for example ${over.first}. '
      'Nothing was built.',
    );
  }
  return <ClipResult>[
    for (int i = 0; i < n; i++)
      ClipResult(
        file: labels?[i] ?? inputs[i].uri.pathSegments.last,
        before: before[i],
        after: after[i],
        gainDb: gain[i],
        limitedDb: limited[i],
        notes: <String>[
          if (before[i].silent) 'silent' else if (before[i].lufs == null) 'short',
          if (capped[i]) 'gain capped',
          if (after[i].lufs != null && (after[i].lufs! - target).abs() > onTargetLu) 'off target',
        ],
      ),
  ];
}

// ---- the packs ----

/// A voice pack made level: [built] is null in a dry run (nothing is signed).
class PackLoudness {
  const PackLoudness({
    required this.id,
    required this.sourceVersion,
    required this.version,
    required this.clips,
    required this.audioBytesBefore,
    required this.audioBytesAfter,
    required this.filesBytes,
    required this.built,
  });

  final String id;
  final String sourceVersion;
  final String version;
  final List<ClipResult> clips;

  /// The sound files, each once: what the app holds in memory for the pack ([maxVoiceBytes] counts it).
  final int audioBytesBefore;
  final int audioBytesAfter;

  /// Every file of the pack, as the app's reader limit counts them ([ZipLimits.maxTotalBytes]).
  final int filesBytes;
  final BuiltPack? built;

  LoudnessStats get statsBefore => LoudnessStats(<Loudness>[for (final ClipResult c in clips) c.before]);
  LoudnessStats get statsAfter => LoudnessStats(<Loudness>[for (final ClipResult c in clips) c.after]);

  int get limitedHard => clips.where((ClipResult c) => c.limitedDb > 6).length;
  int get offTarget => clips.where((ClipResult c) => c.notes.contains('off target')).length;

  /// The first few clips that are off target (the limiter was not let to take them further), for the report.
  String get offTargetNames {
    final List<String> names = <String>[
      for (final ClipResult c in clips)
        if (c.notes.contains('off target')) c.file,
    ];
    return names.isEmpty
        ? ''
        : ' (${names.take(8).join(', ')}${names.length > 8 ? ', ...' : ''}; all in the .loudness.json)';
  }

  String describe() {
    String mib(int b) => (b / (1024 * 1024)).toStringAsFixed(1);
    final List<double> gains = <double>[for (final ClipResult c in clips) c.gainDb]..sort();
    final LoudnessStats b = statsBefore;
    return '$id $sourceVersion -> $version: ${clips.length} clips'
        '${b.unmeasured == 0 ? '' : ' (${b.unmeasured} under 0.4 s or silent: set from their peak)'}\n'
        '  before: ${b.describe()}\n'
        '  after:  ${statsAfter.describe()}\n'
        '  gain min ${gains.first.toStringAsFixed(1)}, median ${_median(gains).toStringAsFixed(1)}, max ${gains.last.toStringAsFixed(1)} dB; '
        'peaks taken down over 6 dB in $limitedHard clips\n'
        '  more than $onTargetLu LU off target: $offTarget clips$offTargetNames\n'
        '  size: sound ${mib(audioBytesBefore)} -> ${mib(audioBytesAfter)} MiB; files in the pack ${mib(filesBytes)} MiB of '
        '${mib(ZipLimits.maxTotalBytes)} MiB the app reads'
        '${built == null ? '' : ', the pack file ${mib(built!.bytes.length)} MiB'}';
  }

  /// What the sidecar file says: the summary and every clip.
  Map<String, Object?> toJson() => <String, Object?>{
    'schema': 'loudness/v1',
    'pack': id,
    'sourceVersion': sourceVersion,
    'version': version,
    'target': targetLufs,
    'maxTruePeak': maxTruePeak,
    'before': statsBefore.toJson(),
    'after': statsAfter.toJson(),
    'audioBytesBefore': audioBytesBefore,
    'audioBytesAfter': audioBytesAfter,
    'clips': <Object?>[for (final ClipResult c in clips) c.toJson()],
  };
}

/// [version] (`x.y.z`) with its minor number one higher and its patch 0.
String nextMinor(String version) {
  final RegExpMatch? m = RegExp(r'^(\d{1,3})\.(\d{1,3})\.(\d{1,3})$').firstMatch(version);
  if (m == null) throw VoiceGenFailed('"$version" is not a version like 2.0.1');
  return '${m.group(1)}.${int.parse(m.group(2)!) + 1}.0';
}

/// The sound files of a pack, by name. Only MP3 is made level; a pack with another kind of sound is refused, so no clip is left as it was.
Iterable<String> _audioFiles(VerifiedPack pack) sync* {
  for (final String name in pack.files.keys) {
    final String lower = name.toLowerCase();
    if (lower.endsWith('.mp3')) {
      yield name;
    } else if (RegExp(r'\.(wav|ogg|m4a|aac|flac|opus)$').hasMatch(lower)) {
      throw VoiceGenFailed(
        '$name is not an MP3: this tool makes MP3 clips level, and a pack of another sound is left alone',
      );
    }
  }
}

/// Makes the pack in [source] level and, when [key] is given, builds it again under [version] and signs it. [publicKey] checks the
/// source first: a pack that does not verify is never read further. Everything but the sound stays as it was: the ids, the
/// lines and the files that are not sound (the cues), byte for byte; the result is checked against the source before it is
/// returned. Without [key] (a dry run) the clips are measured and encoded but no pack is made.
Future<PackLoudness> normalisePack({
  required Uint8List source,
  required Uint8List publicKey,
  required LoudnessTool tool,
  required String version,
  PackKey? key,
  double target = targetLufs,
  double maxLimiting = defaultMaxLimiting,
  void Function(String)? progress,
}) async {
  final VerifiedPack pack = await verifyPack(source, publicKey: publicKey);
  if (pack.hidden) {
    throw VoiceGenFailed('${pack.id} ${pack.version} needs a newer app than this tool; it was not read');
  }
  final List<String> names = _audioFiles(pack).toList()..sort();
  if (names.isEmpty) throw VoiceGenFailed('${pack.id} ${pack.version} holds no sound');
  final Directory work = Directory.systemTemp.createTempSync('nn_loud_');
  try {
    String at(String folder, int i) =>
        '${work.path}${Platform.pathSeparator}$folder${Platform.pathSeparator}$i.mp3';
    for (final String folder in <String>['in', 'out']) {
      Directory('${work.path}${Platform.pathSeparator}$folder').createSync();
    }
    for (int i = 0; i < names.length; i++) {
      File(at('in', i)).writeAsBytesSync(pack.files[names[i]]!);
    }
    final List<ClipResult> results = await normaliseClips(
      inputs: <File>[for (int i = 0; i < names.length; i++) File(at('in', i))],
      outputs: <File>[for (int i = 0; i < names.length; i++) File(at('out', i))],
      tool: tool,
      labels: names,
      target: target,
      maxLimiting: maxLimiting,
      progress: progress,
    );
    final Map<String, Uint8List> files = <String, Uint8List>{
      for (final MapEntry<String, Uint8List> f in pack.files.entries) f.key: f.value,
      for (int i = 0; i < names.length; i++) names[i]: File(at('out', i)).readAsBytesSync(),
    };
    int sum(Iterable<Uint8List> b) => b.fold<int>(0, (int s, Uint8List f) => s + f.length);
    final int filesBytes = sum(files.values);
    BuiltPack? built;
    if (key != null) {
      built = await _build(pack, files, version, key);
    }
    return PackLoudness(
      id: pack.id,
      sourceVersion: pack.version,
      version: version,
      clips: results,
      audioBytesBefore: sum(<Uint8List>[for (final String n in names) pack.files[n]!]),
      audioBytesAfter: sum(<Uint8List>[for (final String n in names) files[n]!]),
      filesBytes: filesBytes,
      built: built,
    );
  } finally {
    try {
      work.deleteSync(recursive: true);
    } on FileSystemException {
      // A file Windows still holds; the system's own temporary folder is cleared in time.
    }
  }
}

Future<BuiltPack> _build(VerifiedPack pack, Map<String, Uint8List> files, String version, PackKey key) async {
  final Directory stage = Directory.systemTemp.createTempSync('nn_loud_pack_');
  try {
    for (final MapEntry<String, Uint8List> f in files.entries) {
      File('${stage.path}${Platform.pathSeparator}${f.key}').writeAsBytesSync(f.value);
    }
    File('${stage.path}${Platform.pathSeparator}pack.json').writeAsStringSync(
      jsonEncode(<String, Object?>{
        'schema': 'pack-source/v1',
        'id': pack.id,
        'version': version,
        'minAppVersion': pack.manifest['minAppVersion'],
        if (pack.manifest['course'] is String) 'course': pack.manifest['course'],
        'assets': pack.manifest['assets'],
        'vo': pack.manifest['vo'],
      }),
    );
    final BuiltPack built = await buildPack(stage, key);
    await _checkSamePack(pack, await verifyPack(built.bytes, publicKey: key.publicKey));
    return built;
  } finally {
    try {
      stage.deleteSync(recursive: true);
    } on FileSystemException {
      // The system's temporary folder is cleared in time.
    }
  }
}

/// Refuses a result that differs from its source in anything but the version, the sound and what follows from the sound (the
/// size and hash of its files): same manifest, same files by name, every file that is not an MP3 byte for byte.
Future<void> _checkSamePack(VerifiedPack old, VerifiedPack made) async {
  const Set<String> allowed = <String>{'version', 'files'};
  final Set<String> keys = <String>{...old.manifest.keys, ...made.manifest.keys}..removeAll(allowed);
  for (final String k in keys) {
    if (jsonEncode(old.manifest[k]) != jsonEncode(made.manifest[k])) {
      throw VoiceGenFailed('the new pack differs from its source in "$k"; nothing was written');
    }
  }
  if (jsonEncode(old.files.keys.toList()..sort()) != jsonEncode(made.files.keys.toList()..sort())) {
    throw const VoiceGenFailed('the new pack has other files than its source; nothing was written');
  }
  for (final MapEntry<String, Uint8List> f in old.files.entries) {
    if (f.key.toLowerCase().endsWith('.mp3')) continue;
    if (sha256Hex(f.value) != sha256Hex(made.files[f.key]!)) {
      throw VoiceGenFailed('${f.key} changed in the new pack; nothing was written');
    }
  }
}

// ---- finding the packs of a voice ----

/// One pack of a voice folder: [part] is 1 for `voice-<id>`, N for `voice-<id>-N`.
typedef FoundPack = ({File file, int part, String version});

int _versionOrder(String a, String b) {
  List<int> parts(String v) => v.split('.').map(int.parse).toList();
  final List<int> x = parts(a);
  final List<int> y = parts(b);
  for (int i = 0; i < 3; i++) {
    if (x[i] != y[i]) return x[i].compareTo(y[i]);
  }
  return 0;
}

/// The packs `<prefix>[-N]-<version>.nnpack` of the newest version in [folder] (the rule of `tools/copy-release-voices.ps1`),
/// by part. Throws when there is none.
List<FoundPack> newestVoicePacks(Directory folder, String prefix) {
  if (!folder.existsSync()) throw VoiceGenFailed('no folder ${folder.path}');
  final RegExp name = RegExp(
    '^${RegExp.escape(prefix)}(?:-([2-9]))?-(\\d{1,3}\\.\\d{1,3}\\.\\d{1,3})\\.nnpack\$',
  );
  final List<FoundPack> found = <FoundPack>[];
  for (final FileSystemEntity e in folder.listSync(followLinks: false)) {
    if (e is! File) continue;
    final RegExpMatch? m = name.firstMatch(e.uri.pathSegments.last);
    if (m != null) found.add((file: e, part: int.parse(m.group(1) ?? '1'), version: m.group(2)!));
  }
  if (found.isEmpty) throw VoiceGenFailed('no $prefix pack in ${folder.path}');
  final String newest = found
      .map((FoundPack p) => p.version)
      .reduce((String a, String b) => _versionOrder(a, b) >= 0 ? a : b);
  return found.where((FoundPack p) => p.version == newest).toList()
    ..sort((FoundPack a, FoundPack b) => a.part.compareTo(b.part));
}

/// Refuses an output folder that is the source folder or inside it (the originals are only ever read).
void checkOutputFolder(Directory source, Directory out) {
  String norm(Directory d) {
    String p = d.absolute.uri.normalizePath().toFilePath();
    while (p.length > 1 && (p.endsWith('/') || p.endsWith(r'\'))) {
      p = p.substring(0, p.length - 1);
    }
    return Platform.isWindows ? p.toLowerCase() : p;
  }

  final String from = norm(source);
  final String to = norm(out);
  if (to == from || to.startsWith('$from${Platform.pathSeparator}')) {
    throw VoiceGenFailed(
      'the output folder ${out.path} is the folder of the originals, or inside it: use another --out-root',
    );
  }
}
