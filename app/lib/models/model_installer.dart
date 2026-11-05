import 'dart:async';
import 'dart:io';

import '../speech/model_spec.dart';

/// Where the bytes of a model file come from. The app has no model host yet (the owner has not chosen R2): [NoModelHost] is
/// the only fetcher in the app, and a model comes onto a phone by `adb push` into its folder, as the Hebrew model does. When a
/// host is chosen it is added to `app/network_hosts.json` and a fetcher over the app's own HTTP client implements this; this
/// file has no network code and no address.
abstract interface class ModelFetcher {
  /// The bytes of [file] of [spec]. Throws [ModelHostMissing] when there is nowhere to fetch from.
  Stream<List<int>> fetch(SpeechModelSpec spec, ModelFile file);
}

class ModelHostMissing implements Exception {
  const ModelHostMissing();

  @override
  String toString() => 'no model host is configured';
}

class NoModelHost implements ModelFetcher {
  const NoModelHost();

  @override
  Stream<List<int>> fetch(SpeechModelSpec spec, ModelFile file) =>
      Stream<List<int>>.error(const ModelHostMissing());
}

enum InstallOutcome {
  /// Every file is there and exactly the pinned one.
  installed,

  /// There is no host to fetch from (or the fetch failed): nothing was kept that is not verified.
  unavailable,

  /// A file arrived that is not the pinned one: it was deleted.
  rejected,
}

/// Puts a model on the phone safely: each file is written under a temporary name, checked for size and SHA-256 while it is
/// written, and renamed to its real name only when both are right. A file that is wrong, or a fetch that stops half way, leaves
/// no file under the real name. Files already there and right are not fetched again.
class ModelInstaller {
  const ModelInstaller({this.fetcher = const NoModelHost()});

  final ModelFetcher fetcher;

  static const String partSuffix = '.part';

  Future<InstallOutcome> install(SpeechModelSpec spec, Directory dir) async {
    await dir.create(recursive: true);
    _clearParts(dir);
    for (final ModelFile f in spec.files) {
      final File target = spec.fileIn(dir, f);
      if (target.existsSync() && target.lengthSync() == f.size && sha256Of(target) == f.sha256Hex) continue;
      if (target.existsSync()) target.deleteSync();
      final File part = File('${target.path}$partSuffix');
      final IOSink out = part.openWrite();
      final Sha256Accumulator acc = Sha256Accumulator();
      try {
        await for (final List<int> chunk in fetcher.fetch(spec, f)) {
          acc.add(chunk);
          // Never more than the pinned size: a host that keeps sending is stopped.
          if (acc.length > f.size) break;
          out.add(chunk);
        }
        await out.flush();
        await out.close();
      } on Object {
        await _discard(out, part);
        return InstallOutcome.unavailable;
      }
      final int written = acc.length;
      if (written != f.size || acc.close() != f.sha256Hex) {
        part.deleteSync();
        return InstallOutcome.rejected;
      }
      part.renameSync(target.path);
    }
    return spec.looksInstalled(dir) ? InstallOutcome.installed : InstallOutcome.rejected;
  }

  void _clearParts(Directory dir) {
    for (final FileSystemEntity e in dir.listSync()) {
      if (e is File && e.path.endsWith(partSuffix)) e.deleteSync();
    }
  }

  Future<void> _discard(IOSink out, File part) async {
    try {
      await out.close();
    } on Object {
      // Already closed.
    }
    if (part.existsSync()) part.deleteSync();
  }

  /// Removes the model of a course (the parent turned its voice off and asked for the space back).
  void remove(Directory dir) {
    if (dir.existsSync()) dir.deleteSync(recursive: true);
  }
}
