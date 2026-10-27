import 'dart:io';

import 'package:crypto/crypto.dart';

/// One file of the speech model, with the size and SHA-256 it must have. The numbers are written here, in the app:
/// a file that differs by one byte is refused, whoever put it there.
class ModelFile {
  const ModelFile(this.name, this.size, this.sha256Hex);

  final String name;
  final int size;
  final String sha256Hex;
}

/// ivrit.ai `zipformer2-66m-streaming-he` (author Yakov Kolani, licence CC-BY-4.0), the `sherpa-onnx` int8 export,
/// at revision `ee769a2a13b887f91572eec349458bfb0fe79e7a` of the model page. The files are put on the phone by
/// `tools/make-m5-model.ps1` (and, from M6, downloaded from the app's own pack host) into one folder.
abstract final class SpeechModel {
  static const String id = 'zipformer2-66m-streaming-he';
  static const String folderName = 'speech-model-he-1';

  static const List<ModelFile> files = <ModelFile>[
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
    ModelFile('joiner.int8.onnx', 771805, '1d2c6d8e6dabc5eb52de52e95718e9bdfbffbfe7ead3808fb5ffd74e83bd9cae'),
    ModelFile('tokens.txt', 17086, 'e4ebb5e72a6aeef47437a55fa2308ebbedb7c51c557de7a89bf965c23ea9af4a'),
  ];

  static File fileIn(Directory dir, ModelFile f) => File('${dir.path}${Platform.pathSeparator}${f.name}');

  /// A quick look: every file is there with the right size (no hashing). Used to decide whether voice can be offered.
  static bool looksInstalled(Directory dir) {
    for (final ModelFile f in files) {
      final File file = fileIn(dir, f);
      if (!file.existsSync() || file.lengthSync() != f.size) return false;
    }
    return true;
  }

  /// The slow, complete check: every file hashed and compared. Returns the names of files that are wrong or missing
  /// (empty when the model is exactly the one the app trusts).
  static Future<List<String>> verify(Directory dir) async {
    final List<String> bad = <String>[];
    for (final ModelFile f in files) {
      final File file = fileIn(dir, f);
      if (!file.existsSync() || file.lengthSync() != f.size) {
        bad.add(f.name);
        continue;
      }
      final Digest d = await sha256.bind(file.openRead()).first;
      if (d.toString() != f.sha256Hex) bad.add(f.name);
    }
    return bad;
  }
}
