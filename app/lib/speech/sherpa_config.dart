import 'dart:io';

import 'package:sherpa_onnx/sherpa_onnx.dart' as sherpa;

import 'model_spec.dart';

// What the app and the PC tool share about running a model with sherpa-onnx: the configuration and the hotword list. Nothing here
// touches the microphone, so a command-line tool can use it.

/// The hotword list of one listen: one line per word, `word :boost`, for a biased model; empty for an open one. The words are
/// the item's own (signed content), but the characters that change a list (`:`, `#`, `@`, `/` and line breaks) are dropped
/// here too, so that no word can add a line or change a boost. A word that is empty after that is left out.
String hotwordList(SpeechModelSpec spec, Iterable<String> words, {double? boost}) {
  if (!spec.biased) return '';
  final Set<String> lines = <String>{};
  for (final String w in words) {
    final String clean = w.replaceAll(RegExp(r'[:#@/\r\n\t]'), ' ').trim().replaceAll(RegExp(r'\s+'), ' ');
    if (clean.isEmpty) continue;
    lines.add(
      '${spec.upperCaseWords ? clean.toUpperCase() : clean.toLowerCase()} :${boost ?? spec.hotwordBoost}',
    );
  }
  return lines.join('\n');
}

/// The sherpa-onnx configuration of a model in [dir]: the same for the app, the isolate that loads it and the PC tool.
sherpa.OnlineRecognizerConfig recognizerConfig(SpeechModelSpec spec, String dir) {
  String path(String name) => '$dir${Platform.pathSeparator}$name';
  return sherpa.OnlineRecognizerConfig(
    model: sherpa.OnlineModelConfig(
      transducer: sherpa.OnlineTransducerModelConfig(
        encoder: path(SpeechModelSpec.encoder),
        decoder: path(spec.decoder),
        joiner: path(SpeechModelSpec.joiner),
      ),
      tokens: path(SpeechModelSpec.tokens),
      numThreads: 2,
      modelType: spec.modelType,
      modelingUnit: spec.biased ? 'bpe' : '',
      bpeVocab: spec.biased ? path(SpeechModelSpec.bpeVocab) : '',
      debug: false,
    ),
    decodingMethod: spec.biased ? 'modified_beam_search' : 'greedy_search',
    maxActivePaths: 4,
    // The app decides when the child has finished, not the model.
    enableEndpoint: false,
  );
}
