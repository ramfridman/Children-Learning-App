// Measures a language's say-it on recordings, on the PC, against the release gate (docs/milestones/L3.md section 4). From app/:
//
//   dart run tool/say_eval.dart <folder with .wav files and labels.csv> --course eng|rus|heb [--model <model folder>]
//        [--lib <sherpa-onnx dll folder>] [--mode biased|open] [--speakers <speakers.csv>] [--sweep] [--csv <result file>]
//
// On Windows use tools/run-asr-eval.ps1, which fetches the matching libraries once and sets everything up.
//
// labels.csv has one line per recording:   file,said,forms,foils
//   said    the word actually said; empty when nothing on the screen was said (silence, room noise, a sibling talking, the guide's voice
//           played back through the phone)
//   forms   the target and the forms its teacher lists, separated by |
//   foils   the other options of the screen, separated by |
// Example:  dana_cat_1.wav,cat,cat|a cat,cut|hat      and      dana_noise_1.wav,,cat|a cat,cut|hat
//
// speakers.csv has one line per speaker:  speaker,age   (a file named "<speaker>_..." belongs to that speaker; a speaker that is not
// listed is an adult). Results are reported per age band: A 3 to 4, B 5 to 6, C 7 to 8, and adult.
//
// Files must be 16-bit PCM WAV (mono or stereo, any rate). Nothing is copied, kept or sent anywhere; the results are printed, and
// written to --csv if you ask. The tool has no network code.
import 'dart:ffi' show DynamicLibrary;
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:nitznutz/speech/model_spec.dart';
import 'package:nitznutz/speech/release_gate.dart';
import 'package:nitznutz/speech/say_tally.dart';
import 'package:nitznutz/speech/sherpa_config.dart';
import 'package:nitznutz/speech/word_matcher.dart';
import 'package:sherpa_onnx/sherpa_onnx.dart' as sherpa;

import 'asr_eval.dart' show readWav, resample, Wav;

String pct(num a, num b) => b == 0 ? 'n/a' : '${(100 * a / b).toStringAsFixed(1)}%';

/// The text read from [samples] (16 kHz), as the engine does: the lead silence the model wants, the audio in pieces of 100 ms and a
/// little silence to flush the last word.
String readText(
  sherpa.OnlineRecognizer rec,
  SpeechModelSpec spec,
  Float32List samples, {
  required List<String> words,
  double? boost,
}) {
  final sherpa.OnlineStream stream = rec.createStream(hotwords: hotwordList(spec, words, boost: boost));
  void feed(Float32List s) {
    stream.acceptWaveform(samples: s, sampleRate: 16000);
    while (rec.isReady(stream)) {
      rec.decode(stream);
    }
  }

  if (spec.leadSilenceMs > 0) feed(Float32List(16 * spec.leadSilenceMs));
  const int piece = 1600;
  for (int i = 0; i < samples.length; i += piece) {
    feed(Float32List.sublistView(samples, i, math.min(i + piece, samples.length)));
  }
  stream.acceptWaveform(samples: Float32List(24000), sampleRate: 16000);
  stream.inputFinished();
  while (rec.isReady(stream)) {
    rec.decode(stream);
  }
  final String text = rec.getResult(stream).text.trim();
  stream.free();
  return text;
}

void report(String title, SayTally tally) {
  stdout.writeln('\n$title');
  final List<String> bands = tally.byBand.keys.toList()..sort();
  for (final String b in bands) {
    final GateResult r = releaseGate(tally.byBand[b]!);
    final GateCounts c = tally.byBand[b]!;
    stdout.writeln(
      '  band $b: heard ${c.correctConfident} of ${c.correctReadings} correct readings (${pct(c.correctConfident, c.correctReadings)}); '
      'confident ${c.negativeConfident} of ${c.negativeReadings} readings that should not be (${pct(c.negativeConfident, c.negativeReadings)}, '
      'upper bound ${(r.upperBound * 100).toStringAsFixed(1)}%)  -> ${r.verdict.name}${r.meetsStricterBar ? ' (within the stricter 3%)' : ''}',
    );
    for (final String why in r.reasons) {
      stdout.writeln('      $why');
    }
  }
  stdout.writeln('  the language: ${languageVerdict(tally.byBand).name}');
}

Future<void> main(List<String> args) async {
  String? option(String name) {
    final int i = args.indexOf(name);
    return i >= 0 && i + 1 < args.length ? args[i + 1] : null;
  }

  if (args.isEmpty || args.first.startsWith('--') || option('--course') == null) {
    stderr.writeln(
      'usage: dart run tool/say_eval.dart <folder> --course eng|rus|heb [--model <dir>] [--mode biased|open] [--sweep]',
    );
    exit(2);
  }
  final String course = option('--course')!;
  final SpeechModelSpec? spec = SpeechModels.forCourse(course);
  if (spec == null) {
    stderr.writeln('unknown course $course');
    exit(2);
  }
  final Directory folder = Directory(args.first);
  final Directory model = Directory(option('--model') ?? '../out/asr-$course');
  final List<String> bad = await spec.verify(model);
  if (bad.isNotEmpty) {
    stderr.writeln(
      'The model in ${model.path} is not the trusted one (wrong or missing: ${bad.join(', ')}).',
    );
    exit(1);
  }
  final List<SayLabel> labels = parseSayLabels(
    File('${folder.path}${Platform.pathSeparator}labels.csv').readAsStringSync(),
  );
  final String? speakersPath = option('--speakers');
  final Map<String, String> bands = speakersPath == null
      ? const <String, String>{}
      : parseSpeakers(File(speakersPath).readAsStringSync());
  final String? lib = option('--lib');
  if (lib != null && Platform.isWindows) {
    DynamicLibrary.open('$lib${Platform.pathSeparator}onnxruntime.dll');
    DynamicLibrary.open('$lib${Platform.pathSeparator}onnxruntime_providers_shared.dll');
  }
  sherpa.initBindings(lib);
  final bool open = option('--mode') == 'open' || !spec.biased;
  // `open` reads without a list of words, even with a biased model.
  final SpeechModelSpec runSpec = open && spec.biased
      ? SpeechModelSpec(
          course: spec.course,
          id: spec.id,
          folderName: spec.folderName,
          licence: spec.licence,
          source: spec.source,
          revision: spec.revision,
          files: spec.files,
          modelType: spec.modelType,
          leadSilenceMs: spec.leadSilenceMs,
        )
      : spec;
  final sherpa.OnlineRecognizer rec = sherpa.OnlineRecognizer(recognizerConfig(runSpec, model.path));

  // Read every recording once per boost (the model's own, or the boosts of the sweep); the way of deciding is tried on the readings.
  final List<double?> boosts = !spec.biased || open
      ? <double?>[null]
      : (args.contains('--sweep') ? <double?>[3, 5, 8, 12, 16] : <double?>[null]);
  final Map<double?, List<(SayLabel, String)>> readings = <double?, List<(SayLabel, String)>>{
    for (final double? b in boosts) b: <(SayLabel, String)>[],
  };
  final Stopwatch clock = Stopwatch()..start();
  int read = 0;
  for (final SayLabel l in labels) {
    final File f = File('${folder.path}${Platform.pathSeparator}${l.file}');
    if (!f.existsSync()) {
      stderr.writeln('missing: ${l.file}');
      continue;
    }
    final Wav wav = readWav(f);
    final Float32List samples = resample(wav.samples, wav.rate, 16000);
    for (final double? b in boosts) {
      readings[b]!.add((l, readText(rec, runSpec, samples, words: l.targetOf(course).hotwords, boost: b)));
    }
    read++;
  }
  stdout.writeln(
    'Recordings read: $read of ${labels.length} in ${clock.elapsedMilliseconds} ms   course: $course   model: ${spec.id}   '
    'mode: ${open ? 'open' : 'biased (boost ${spec.hotwordBoost})'}',
  );

  SayTally tallyOf(double? boost, WordMatchConfig config) {
    final SayTally t = SayTally(
      course: course,
      matcher: WordMatcher(config: config),
      bands: bands,
    );
    for (final (SayLabel l, String text) in readings[boost]!) {
      t.add(l, <String>[text]);
    }
    return t;
  }

  final WordMatchConfig own = WordMatchConfig.of(course);
  final SayTally main = tallyOf(boosts.first, own);
  report('Result (accept ${own.accept}, margin ${own.margin})', main);
  if (args.contains('--sweep')) {
    stdout.writeln(
      '\nSweep: the share heard (of the correct readings) against the share confident when it should not be',
    );
    stdout.writeln('  boost   accept   heard      false-confident   upper bound');
    for (final double? b in boosts) {
      for (final double accept in <double>[0.6, 0.7, 0.75, 0.8, 0.9, 1.0]) {
        final GateCounts c = tallyOf(b, WordMatchConfig(accept: accept, margin: own.margin)).total;
        final GateResult r = releaseGate(c);
        final String row = <String>[
          '  ${b ?? '-'}'.padRight(8),
          '$accept'.padRight(9),
          pct(c.correctConfident, c.correctReadings).padRight(11),
          pct(c.negativeConfident, c.negativeReadings).padRight(18),
          '${(r.upperBound * 100).toStringAsFixed(1)}%',
        ].join();
        stdout.writeln(row);
      }
    }
  }
  if (main.confidentFoils.isNotEmpty) {
    stdout.writeln('\nConfident when it should not be: ${main.confidentFoils.take(20).join(', ')}');
  }
  final List<String> csv = <String>['file,band,said,heard_as,result'];
  for (final (SayLabel l, String text) in readings[boosts.first]!) {
    final SayResult r = WordMatcher(config: own).decide(<String>[text], l.targetOf(course)).result;
    // The text is written to the file you asked for, on your PC, to look at the misses; nothing else keeps it.
    csv.add('${l.file},${main.bandOf(l)},${l.said},"${text.replaceAll('"', '')}",${r.name}');
  }
  final String? out = option('--csv');
  if (out != null) File(out).writeAsStringSync(csv.join('\n'));
  rec.free();
}
