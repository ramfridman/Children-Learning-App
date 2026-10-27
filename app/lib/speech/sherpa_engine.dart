import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:record/record.dart';
import 'package:sherpa_onnx/sherpa_onnx.dart' as sherpa;

import 'answer_matcher.dart';
import 'model_spec.dart';
import 'speech_engine.dart';

/// The real recogniser: ivrit.ai's streaming Hebrew model run by sherpa-onnx on the device, fed from the microphone.
///
/// The audio is read in small pieces, held in memory only while the child speaks, and dropped: nothing is written to a
/// file and nothing leaves the phone. The microphone is closed before the last words are decoded.
class SherpaEngine implements SpeechEngine {
  SherpaEngine({required this.modelDir, AudioRecorder Function()? recorder})
    : _newRecorder = recorder ?? AudioRecorder.new;

  /// The folder of the model files.
  final Future<Directory> Function() modelDir;
  final AudioRecorder Function() _newRecorder;

  sherpa.OnlineRecognizer? _recognizer;
  Completer<void>? _cancel;

  static const int _rate = 16000;

  /// If nobody says anything for this long, the listen ends as silence.
  static const Duration _noSpeech = Duration(seconds: 5);

  @override
  bool get ready => _recognizer != null;

  @override
  Future<bool> modelInstalled() async => SpeechModel.looksInstalled(await modelDir());

  @override
  Future<bool> requestPermission() async {
    final AudioRecorder r = _newRecorder();
    try {
      return await r.hasPermission();
    } finally {
      await r.dispose();
    }
  }

  @override
  Future<void> prepare() async {
    if (_recognizer != null) return;
    final Directory dir = await modelDir();
    final List<String> bad = await SpeechModel.verify(dir);
    if (bad.isNotEmpty) throw StateError('the speech model is not the trusted one: ${bad.join(', ')}');
    sherpa.initBindings();
    String path(String name) => '${dir.path}${Platform.pathSeparator}$name';
    _recognizer = sherpa.OnlineRecognizer(
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
        // The app decides when the child has finished, not the model.
        enableEndpoint: false,
      ),
    );
  }

  @override
  Stream<ListenEvent> listen({required Duration silence, required Duration maxLength}) {
    final StreamController<ListenEvent> out = StreamController<ListenEvent>();
    unawaited(_run(out, silence, maxLength));
    return out.stream;
  }

  @override
  Future<void> cancel() async {
    final Completer<void>? c = _cancel;
    if (c != null && !c.isCompleted) c.complete();
  }

  Future<void> _run(StreamController<ListenEvent> out, Duration silence, Duration maxLength) async {
    final sherpa.OnlineRecognizer? rec = _recognizer;
    final AudioRecorder recorder = _newRecorder();
    final Completer<void> cancelled = _cancel = Completer<void>();
    sherpa.OnlineStream? stream;
    StreamSubscription<Uint8List>? sub;
    ListenEnd end = ListenEnd.silence;
    String text = '';
    try {
      if (rec == null || !await recorder.hasPermission(request: false)) {
        throw StateError('voice is not ready');
      }
      stream = rec.createStream();
      final Stream<Uint8List> pcm = await recorder.startStream(
        const RecordConfig(
          encoder: AudioEncoder.pcm16bits,
          sampleRate: _rate,
          numChannels: 1,
          echoCancel: true,
          noiseSuppress: true,
        ),
      );
      final Stopwatch clock = Stopwatch()..start();
      final Completer<ListenEnd> finished = Completer<ListenEnd>();
      int carry = -1;
      int lastVoiceMs = 0;
      bool heardVoice = false;
      bool padded = false;
      final List<double> floorSamples = <double>[];
      double threshold = 0.02;

      void decodeAll() {
        while (rec.isReady(stream!)) {
          rec.decode(stream);
        }
        text = rec.getResult(stream).text.trim();
      }

      sub = pcm.listen(
        (Uint8List bytes) {
          // 16 bit little-endian samples; a chunk may end in the middle of one.
          final BytesBuilder joined = BytesBuilder(copy: false);
          if (carry >= 0) joined.addByte(carry);
          joined.add(bytes);
          final Uint8List all = joined.takeBytes();
          final int n = all.length ~/ 2;
          carry = all.length.isOdd ? all.last : -1;
          final Float32List samples = Float32List(n);
          double energy = 0;
          final ByteData view = ByteData.sublistView(all);
          for (int i = 0; i < n; i++) {
            final double v = view.getInt16(i * 2, Endian.little) / 32768;
            samples[i] = v;
            energy += v * v;
          }
          if (n == 0) return;
          final double rms = math.sqrt(energy / n);
          final int now = clock.elapsedMilliseconds;
          // The first moments are the room: the voice has to stand clear of it.
          if (floorSamples.length < 3) {
            floorSamples.add(rms);
            threshold = math.max(0.02, floorSamples.reduce(math.max) * 2.5);
          } else if (rms > threshold) {
            heardVoice = true;
            lastVoiceMs = now;
            padded = false;
          }
          stream!.acceptWaveform(samples: samples, sampleRate: _rate);
          decodeAll();
          if (!out.isClosed) out.add(ListenLevel(math.min(1, rms * 8)));
          final int quiet = now - lastVoiceMs;
          if (heardVoice && quiet >= 500 && !padded) {
            // The model decodes in chunks of over a second: push a little silence so the last word is read now.
            padded = true;
            stream.acceptWaveform(samples: Float32List(_rate * 3 ~/ 2), sampleRate: _rate);
            decodeAll();
          }
          if (heardVoice && text.isNotEmpty && !out.isClosed) {
            out.add(ListenPartial(text, 0.85, quiet));
          }
          if (finished.isCompleted) return;
          if (heardVoice && quiet >= silence.inMilliseconds) {
            finished.complete(ListenEnd.silence);
          } else if (!heardVoice && now >= _noSpeech.inMilliseconds) {
            finished.complete(ListenEnd.silence);
          } else if (now >= maxLength.inMilliseconds) {
            finished.complete(ListenEnd.maxLength);
          }
        },
        onError: (Object _) {
          if (!finished.isCompleted) finished.complete(ListenEnd.failed);
        },
        onDone: () {
          if (!finished.isCompleted) finished.complete(ListenEnd.silence);
        },
      );
      end = await Future.any<ListenEnd>(<Future<ListenEnd>>[
        finished.future,
        cancelled.future.then((_) => ListenEnd.cancelled),
      ]);
    } on Object {
      end = ListenEnd.failed;
    } finally {
      // The microphone is closed before anything else happens.
      await sub?.cancel();
      try {
        await recorder.stop();
      } on Object {
        // Already stopped.
      }
      await recorder.dispose();
    }
    // The last words: the rest of the audio is decoded and the stream is freed. Nothing of it is kept.
    String finalText = text;
    final sherpa.OnlineStream? s = stream;
    if (s != null && rec != null) {
      try {
        s.acceptWaveform(samples: Float32List(_rate * 3 ~/ 2), sampleRate: _rate);
        s.inputFinished();
        while (rec.isReady(s)) {
          rec.decode(s);
        }
        finalText = rec.getResult(s).text.trim();
      } on Object {
        // Keep what was heard so far.
      } finally {
        s.free();
      }
    }
    if (!out.isClosed) {
      out.add(
        ListenDone(
          finalText.isEmpty || end == ListenEnd.failed
              ? const <Hypothesis>[]
              : <Hypothesis>[Hypothesis(finalText, 0.85)],
          end,
        ),
      );
      await out.close();
    }
    if (identical(_cancel, cancelled)) _cancel = null;
  }

  @override
  Future<void> dispose() async {
    await cancel();
    _recognizer?.free();
    _recognizer = null;
  }
}
