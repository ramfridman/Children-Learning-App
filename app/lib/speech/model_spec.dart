import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:crypto/crypto.dart';

import '../engine/course.dart';

/// One file of a speech model, with the size and SHA-256 it must have. The numbers are written here, in the app: a file
/// that differs by one byte is refused, whoever put it there.
class ModelFile {
  const ModelFile(this.name, this.size, this.sha256Hex);

  final String name;
  final int size;
  final String sha256Hex;
}

/// How a recogniser reads the audio of a word check.
enum Decoding {
  /// Greedy search, no list of words: the text is whatever the model heard (the Hebrew model, M5).
  open,

  /// Modified beam search with the words of the item as hotwords (docs/milestones/L3.md section 7.3): the options are boosted
  /// equally, so the decision between them is made by the matcher, not by the boost.
  biased,
}

/// A speech model of one course: where it came from, the files it is made of, and how it is run. The files are put in one
/// folder under the app's private storage by `tools/make-asr-models.ps1` (an `adb push`, as for Hebrew) or, once the owner has
/// chosen a host, by the installer in `lib/models/model_installer.dart`.
class SpeechModelSpec {
  const SpeechModelSpec({
    required this.course,
    required this.id,
    required this.folderName,
    required this.licence,
    required this.source,
    required this.revision,
    required this.files,
    required this.modelType,
    this.decoding = Decoding.open,
    this.hotwordBoost = 0,
    this.upperCaseWords = false,
    this.leadSilenceMs = 0,
  });

  /// The course whose speech this is (`heb` also serves the lands).
  final String course;
  final String id;

  /// The folder name under the private "no backup" folder; the number changes when the file set changes.
  final String folderName;
  final String licence;

  /// Where the files were taken from, and the revision of that page they were taken at.
  final String source;
  final String revision;
  final List<ModelFile> files;

  /// The `modelType` of sherpa-onnx ('' lets the library read it from the model).
  final String modelType;
  final Decoding decoding;

  /// The boost of each hotword (biased decoding only).
  final double hotwordBoost;

  /// The model's tokens are upper case (English LibriSpeech), so its hotwords must be.
  final bool upperCaseWords;

  /// Silence put in front of the word: the streaming models read an isolated word only with a second of lead (section 7.3).
  final int leadSilenceMs;

  // The names the files have in the folder (the same for every model, so the engine reads any of them).
  static const String encoder = 'encoder.int8.onnx';
  static const String joiner = 'joiner.int8.onnx';
  static const String tokens = 'tokens.txt';
  static const String bpeVocab = 'bpe.vocab';

  /// The decoder is int8 for most models, a plain one for the Russian small model (the source has no int8 decoder).
  String get decoder =>
      files.any((ModelFile f) => f.name == 'decoder.int8.onnx') ? 'decoder.int8.onnx' : 'decoder.onnx';

  bool get biased => decoding == Decoding.biased;

  File fileIn(Directory dir, ModelFile f) => File('${dir.path}${Platform.pathSeparator}${f.name}');

  /// A quick look: every file is there with the right size (no hashing). Used to decide whether voice can be offered.
  bool looksInstalled(Directory dir) {
    for (final ModelFile f in files) {
      final File file = fileIn(dir, f);
      if (!file.existsSync() || file.lengthSync() != f.size) return false;
    }
    return true;
  }

  /// The slow, complete check: every file hashed and compared. Returns the names of files that are wrong or missing (empty when
  /// the model is exactly the one the app trusts). It reads whole files: call it from an isolate, never from the main one.
  List<String> verifySync(Directory dir) {
    final List<String> bad = <String>[];
    for (final ModelFile f in files) {
      final File file = fileIn(dir, f);
      if (!file.existsSync() || file.lengthSync() != f.size || sha256Of(file) != f.sha256Hex) bad.add(f.name);
    }
    return bad;
  }

  /// The same check, off the caller's isolate.
  Future<List<String>> verify(Directory dir) {
    final String path = dir.path;
    return Isolate.run(() => verifySync(Directory(path)));
  }
}

/// The SHA-256 of bytes that arrive in pieces (a file read in blocks, a download).
class Sha256Accumulator {
  Sha256Accumulator() {
    _input = sha256.startChunkedConversion(_sink);
  }

  final _DigestSink _sink = _DigestSink();
  late final ByteConversionSink _input;
  int length = 0;

  void add(List<int> bytes) {
    length += bytes.length;
    _input.add(bytes);
  }

  /// The digest as 64 lower-case hex digits; no more bytes may be added after it.
  String close() {
    _input.close();
    return _sink.value.toString();
  }
}

/// The SHA-256 of a file, read in pieces so a 70 MB model never sits in memory whole.
String sha256Of(File file) {
  final Sha256Accumulator acc = Sha256Accumulator();
  final RandomAccessFile raf = file.openSync();
  try {
    final List<int> buffer = List<int>.filled(1 << 20, 0);
    while (true) {
      final int n = raf.readIntoSync(buffer);
      if (n <= 0) break;
      acc.add(n == buffer.length ? buffer : buffer.sublist(0, n));
    }
  } finally {
    raf.closeSync();
  }
  return acc.close();
}

class _DigestSink implements Sink<Digest> {
  late Digest value;

  @override
  void add(Digest data) => value = data;

  @override
  void close() {}
}

/// The models of the app, one per course. Each file set is a pinned artefact: a new revision is a new `folderName`.
abstract final class SpeechModels {
  /// ivrit.ai `zipformer2-66m-streaming-he` (author Yakov Kolani, CC-BY-4.0), the `sherpa-onnx` int8 export, at revision
  /// `ee769a2a13b887f91572eec349458bfb0fe79e7a` of the model page. Open decoding: it is the child's own language, and its
  /// speech is optional practice that never counts as evidence.
  static const SpeechModelSpec hebrew = SpeechModelSpec(
    course: Course.heb,
    id: 'zipformer2-66m-streaming-he',
    folderName: 'speech-model-he-1',
    licence: 'CC-BY-4.0',
    source: 'huggingface.co/ivrit-ai/zipformer2-66m-streaming-he (sherpa-onnx folder)',
    revision: 'ee769a2a13b887f91572eec349458bfb0fe79e7a',
    modelType: 'zipformer2',
    files: <ModelFile>[
      ModelFile(
        'encoder.int8.onnx',
        70478964,
        '6c6febcb74a09435315a1d872a6539f6e7fc2c333533f14c74edc0e85c49ffcd',
      ),
      ModelFile(
        'decoder.int8.onnx',
        1049105,
        'feb03e7c8aa761593a9284a6fa1e91259be3702de75f630062256c1a59c5a906',
      ),
      ModelFile(
        'joiner.int8.onnx',
        771805,
        '1d2c6d8e6dabc5eb52de52e95718e9bdfbffbfe7ead3808fb5ffd74e83bd9cae',
      ),
      ModelFile('tokens.txt', 17086, 'e4ebb5e72a6aeef47437a55fa2308ebbedb7c51c557de7a89bf965c23ea9af4a'),
    ],
  );

  /// k2-fsa `sherpa-onnx-streaming-zipformer-en-20M-2023-02-17`, int8 (Apache-2.0), at revision
  /// `d42f2d9f7ca24806fb667456a18a9f1b60f70d16`; `bpe.vocab` is made from the icefall repository's `bpe.model` (SHA-256
  /// `c53433de083c4a6ad12d034550ef22de68cec62c4f58932a7b6b8b2f1e743fa5`, Apache-2.0) by `tools/bpe_vocab.py`.
  static const SpeechModelSpec english = SpeechModelSpec(
    course: Course.eng,
    id: 'zipformer-en-20M-2023-02-17',
    folderName: 'speech-model-eng-1',
    licence: 'Apache-2.0',
    source: 'huggingface.co/csukuangfj/sherpa-onnx-streaming-zipformer-en-20M-2023-02-17',
    revision: 'd42f2d9f7ca24806fb667456a18a9f1b60f70d16',
    modelType: '',
    decoding: Decoding.biased,
    hotwordBoost: 8,
    upperCaseWords: true,
    leadSilenceMs: 1000,
    files: <ModelFile>[
      ModelFile(
        'encoder.int8.onnx',
        42845182,
        '3810755ce7c3ab26b42a8bcf39d191308fa27fb0f53358823ba46141d03b7eb3',
      ),
      ModelFile(
        'decoder.int8.onnx',
        539499,
        '21e2a2acd961b3ac72f55be2f10f1a285e1b0b0ba010d7c0b6eab141411b163c',
      ),
      ModelFile(
        'joiner.int8.onnx',
        259572,
        'e085d73b593cf9b0707f370dbd656d58327d3fe36d80d849202ef81df02cb01e',
      ),
      ModelFile('tokens.txt', 5048, '49e3c2646595fd907228b3c6787069658f67b17377c60aeb8619c4551b2316fb'),
      ModelFile('bpe.vocab', 12590, 'f191a4935f668fa8cd8e607bcd378404f948321cd3134a5ea13d324ba921673d'),
    ],
  );

  /// k2-fsa `sherpa-onnx-streaming-zipformer-small-ru-vosk-int8-2025-08-16` from `alphacep/vosk-model-small-streaming-ru`
  /// (Apache-2.0 upstream), at revision `31fa603e4f31279c6e1f7600fed13dc4312663ab`; `bpe.vocab` is made from its `bpe.model`
  /// (SHA-256 `c7a756aeb3550417d6b2ed3efde9a7aa3eea54787d4eac011e9cce6090c9c64a`).
  static const SpeechModelSpec russian = SpeechModelSpec(
    course: Course.rus,
    id: 'zipformer-small-ru-vosk-2025-08-16',
    folderName: 'speech-model-rus-1',
    licence: 'Apache-2.0',
    source: 'huggingface.co/csukuangfj/sherpa-onnx-streaming-zipformer-small-ru-vosk-int8-2025-08-16',
    revision: '31fa603e4f31279c6e1f7600fed13dc4312663ab',
    modelType: 'zipformer2',
    decoding: Decoding.biased,
    hotwordBoost: 8,
    leadSilenceMs: 1000,
    files: <ModelFile>[
      ModelFile(
        'encoder.int8.onnx',
        26214060,
        'e0db705e94ec35d803b1df4f40cda23d064e1142977c80ab288430b109777a9d',
      ),
      ModelFile('decoder.onnx', 2093080, '89b3088a9e20e1ef7f2e85ce1a3478afe6a9c4ac57369cabcc4beb8e95328ea0'),
      ModelFile(
        'joiner.int8.onnx',
        259417,
        'b55784b071ab7512eab4c7c44e4f5478284ef33c83562cc6a249b972515a31e5',
      ),
      ModelFile('tokens.txt', 6388, '93bbbc0bae6b78c0bbb743d4aa9fded3bb5ff3aac5f0200e3a769a5a05e0fdf6'),
      ModelFile('bpe.vocab', 13916, '52649881bb41fafe4257c74d77a85320524494a9d8c48e93d4aaa216cc45113d'),
    ],
  );

  static const List<SpeechModelSpec> all = <SpeechModelSpec>[hebrew, english, russian];

  /// The model of a course; the lands (`core`) speak Hebrew. Null for a name that is no course.
  static SpeechModelSpec? forCourse(String course) => switch (course) {
    Course.core || Course.heb => hebrew,
    Course.eng => english,
    Course.rus => russian,
    _ => null,
  };
}
