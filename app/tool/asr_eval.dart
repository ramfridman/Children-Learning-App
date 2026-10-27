// Measures the speech model and the matcher together on recordings. Run from the app/ folder on the PC:
//
//   dart run tool/asr_eval.dart <folder with .wav files and labels.csv> [--model <model folder>] [--lib <sherpa-onnx dll folder>] [--csv <result file>]
//
// On Windows use tools/run-asr-eval.ps1, which fetches the matching x64 libraries once and sets everything up.
//
// labels.csv has one line per recording:  file,type,intended,options
//   type      number | colour | word
//   intended  the answer meant: a number (3), a colour id (red) or a word (אדום)
//   options   what the activity would show, separated by | (2|3|4, red|blue|yellow, אדום|צהוב)
// Example:    dana_three_1.wav,number,3,2|3|4
//
// Files must be 16-bit PCM WAV (mono or stereo, any rate). Nothing is copied, kept or sent anywhere; the results are
// printed, and written to --csv if you ask. File names that start with "<speaker>_" are also reported per speaker.
//
// The numbers it prints (the share of accepted answers that were right, how many were asked to confirm or repeat, the
// time to decide) are what the report of milestone 5 quotes. Adult recordings measure the machinery; the milestone's
// goal is for children, and only recordings of children can show that.
import 'dart:ffi' show DynamicLibrary;
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:nitznutz/speech/answer_matcher.dart';
import 'package:nitznutz/speech/hebrew_text.dart';
import 'package:nitznutz/speech/model_spec.dart';
import 'package:sherpa_onnx/sherpa_onnx.dart' as sherpa;

class Label {
  Label(this.file, this.type, this.intended, this.options);

  final String file;
  final String type;
  final String intended;
  final List<String> options;

  List<Expected> expected() => <Expected>[
    for (final String o in options)
      switch (type) {
        'number' => Expected.number(o, int.parse(o), correct: o == intended),
        'colour' => Expected.colour(o, o, correct: o == intended),
        _ => Expected.words(o, <String>[o], correct: o == intended),
      },
  ];
}

class Wav {
  Wav(this.samples, this.rate);

  final Float32List samples;
  final int rate;
}

Wav readWav(File file) {
  final Uint8List b = file.readAsBytesSync();
  final ByteData d = ByteData.sublistView(b);
  if (b.length < 44 || String.fromCharCodes(b.sublist(0, 4)) != 'RIFF') {
    throw FormatException('${file.path} is not a WAV file');
  }
  int pos = 12;
  int channels = 1;
  int rate = 16000;
  int bits = 16;
  int format = 1;
  while (pos + 8 <= b.length) {
    final String id = String.fromCharCodes(b.sublist(pos, pos + 4));
    final int size = d.getUint32(pos + 4, Endian.little);
    if (id == 'fmt ') {
      format = d.getUint16(pos + 8, Endian.little);
      channels = d.getUint16(pos + 10, Endian.little);
      rate = d.getUint32(pos + 12, Endian.little);
      bits = d.getUint16(pos + 22, Endian.little);
    } else if (id == 'data') {
      if (format != 1 || bits != 16) throw FormatException('${file.path}: use 16-bit PCM WAV files');
      final int frames = math.min(size, b.length - pos - 8) ~/ (2 * channels);
      final Float32List out = Float32List(frames);
      for (int i = 0; i < frames; i++) {
        double sum = 0;
        for (int c = 0; c < channels; c++) {
          sum += d.getInt16(pos + 8 + (i * channels + c) * 2, Endian.little) / 32768;
        }
        out[i] = sum / channels;
      }
      return Wav(out, rate);
    }
    pos += 8 + size + (size.isOdd ? 1 : 0);
  }
  throw FormatException('${file.path} has no audio');
}

Float32List resample(Float32List s, int from, int to) {
  if (from == to) return s;
  final int n = (s.length * to / from).floor();
  final Float32List out = Float32List(n);
  for (int i = 0; i < n; i++) {
    final double src = i * from / to;
    final int a = src.floor();
    final int c = math.min(a + 1, s.length - 1);
    out[i] = s[a] + (s[c] - s[a]) * (src - a);
  }
  return out;
}

List<Label> readLabels(File f) {
  final List<Label> out = <Label>[];
  for (final String line in f.readAsLinesSync()) {
    final String t = line.replaceAll('﻿', '').trim();
    if (t.isEmpty || t.startsWith('#') || t.startsWith('file,')) continue;
    final List<String> p = t.split(',');
    if (p.length != 4) throw FormatException('labels.csv: expected file,type,intended,options in "$line"');
    out.add(Label(p[0].trim(), p[1].trim(), p[2].trim(), p[3].trim().split('|')));
  }
  return out;
}

String pct(int a, int b) => b == 0 ? 'n/a' : '${(100 * a / b).toStringAsFixed(1)}%';

Future<void> main(List<String> args) async {
  if (args.isEmpty || args.first.startsWith('--')) {
    stderr.writeln('usage: dart run tool/asr_eval.dart <folder> [--model <dir>] [--csv <file>]');
    exit(2);
  }
  String? option(String name) {
    final int i = args.indexOf(name);
    return i >= 0 && i + 1 < args.length ? args[i + 1] : null;
  }

  final Directory folder = Directory(args.first);
  final Directory model = Directory(option('--model') ?? '../out/speech-model');
  final List<String> bad = await SpeechModel.verify(model);
  if (bad.isNotEmpty) {
    stderr.writeln(
      'The model in ${model.path} is not the trusted one (wrong or missing: ${bad.join(', ')}).',
    );
    exit(1);
  }
  final List<Label> labels = readLabels(File('${folder.path}${Platform.pathSeparator}labels.csv'));
  final String? lib = option('--lib');
  if (lib != null && Platform.isWindows) {
    // Windows ships an old onnxruntime.dll in System32 that would be found first: load ours by its full path, so that
    // the library that needs it reuses it.
    DynamicLibrary.open('$lib${Platform.pathSeparator}onnxruntime.dll');
    DynamicLibrary.open('$lib${Platform.pathSeparator}onnxruntime_providers_shared.dll');
  }
  sherpa.initBindings(lib);
  String path(String n) => '${model.path}${Platform.pathSeparator}$n';
  final sherpa.OnlineRecognizer rec = sherpa.OnlineRecognizer(
    sherpa.OnlineRecognizerConfig(
      model: sherpa.OnlineModelConfig(
        transducer: sherpa.OnlineTransducerModelConfig(
          encoder: path('encoder.int8.onnx'),
          decoder: path('decoder.int8.onnx'),
          joiner: path('joiner.int8.onnx'),
        ),
        tokens: path('tokens.txt'),
        numThreads: 2,
        modelType: 'zipformer2',
        debug: false,
      ),
      enableEndpoint: false,
    ),
  );

  const AnswerMatcher matcher = AnswerMatcher();
  final StringBuffer csv = StringBuffer('file,speaker,type,intended,heard,decision,why,option,decide_ms\n');
  final Map<String, List<int>> bySpeaker = <String, List<int>>{}; // accepted, right, confirm, retry
  final List<int> times = <int>[];
  final List<String> misses = <String>[];
  int accepted = 0, right = 0, confirm = 0, retry = 0, intents = 0;

  for (final Label l in labels) {
    final File f = File('${folder.path}${Platform.pathSeparator}${l.file}');
    if (!f.existsSync()) {
      stderr.writeln('missing: ${l.file}');
      continue;
    }
    final Wav wav = readWav(f);
    final Float32List samples = resample(wav.samples, wav.rate, 16000);
    final sherpa.OnlineStream stream = rec.createStream();
    final Stopwatch sw = Stopwatch();
    // As the engine does: audio in pieces of 100 ms, then a little silence to flush the last words.
    const int piece = 1600;
    for (int i = 0; i < samples.length; i += piece) {
      stream.acceptWaveform(
        samples: Float32List.sublistView(samples, i, math.min(i + piece, samples.length)),
        sampleRate: 16000,
      );
      while (rec.isReady(stream)) {
        rec.decode(stream);
      }
    }
    sw.start();
    stream.acceptWaveform(samples: Float32List(24000), sampleRate: 16000);
    stream.inputFinished();
    while (rec.isReady(stream)) {
      rec.decode(stream);
    }
    final String heard = rec.getResult(stream).text.trim();
    stream.free();
    final MatchResult r = matcher.decide(<Hypothesis>[Hypothesis(heard, 0.85)], l.expected());
    sw.stop();
    times.add(sw.elapsedMilliseconds);

    final String speaker = l.file.contains('_') ? l.file.split('_').first : 'all';
    final List<int> s = bySpeaker.putIfAbsent(speaker, () => <int>[0, 0, 0, 0]);
    final bool isRight = r.optionId == l.intended;
    if (r.decision == Decision.accept && r.intent == null) {
      accepted++;
      s[0]++;
      if (isRight) {
        right++;
        s[1]++;
      } else {
        misses.add('${l.file}: heard "$heard", accepted ${r.optionId}, meant ${l.intended}');
      }
    } else if (r.decision == Decision.accept) {
      intents++;
    } else if (r.decision == Decision.confirm) {
      confirm++;
      s[2]++;
    } else {
      retry++;
      s[3]++;
      misses.add('${l.file}: heard "$heard" (${r.decision.name}), meant ${l.intended}');
    }
    csv.writeln(
      '${l.file},$speaker,${l.type},${l.intended},"${heard.replaceAll('"', '')}",${r.decision.name},${r.why.name},${r.optionId ?? ''},${sw.elapsedMilliseconds}',
    );
  }
  rec.free();

  final int total = labels.length;
  times.sort();
  stdout.writeln('Recordings: $total   model: ${SpeechModel.id}');
  stdout.writeln(
    'Accepted: $accepted (${pct(accepted, total)})   right among accepted: $right of $accepted = ${pct(right, accepted)}   (the goal is 97% or more)',
  );
  stdout.writeln(
    'Asked to confirm: $confirm (${pct(confirm, total)})   asked to repeat: $retry (${pct(retry, total)})   heard as a command: $intents',
  );
  if (times.isNotEmpty) {
    stdout.writeln(
      'Time to decide after the end of the audio: median ${times[times.length ~/ 2]} ms, 90th percentile ${times[(times.length * 0.9).floor().clamp(0, times.length - 1)]} ms',
    );
  }
  if (bySpeaker.length > 1) {
    stdout.writeln('Per speaker (accepted, right, confirm, repeat):');
    bySpeaker.forEach(
      (String k, List<int> v) =>
          stdout.writeln('  $k: ${v.join(', ')}  right among accepted: ${pct(v[1], v[0])}'),
    );
  }
  if (misses.isNotEmpty) {
    stdout.writeln('Misses:');
    for (final String m in misses.take(40)) {
      stdout.writeln('  $m');
    }
  }
  final String? out = option('--csv');
  if (out != null) File(out).writeAsStringSync(csv.toString());
  // Only to quiet the unused-import check when a label set has no Hebrew at all.
  assert(normalizeHebrew('') == '');
}
