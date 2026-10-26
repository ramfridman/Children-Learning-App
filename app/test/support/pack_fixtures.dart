import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:nitznutz/content/pack_verify.dart';
import 'package:nitznutz/content/zip_store.dart';

import '../../tool/pack_builder_lib.dart';
import 'sample_pack.dart';

/// A throw-away signing key, made fresh. Tests never use the real one.
Future<PackKey> newTestKey() async {
  final SimpleKeyPair pair = await Ed25519().newKeyPair();
  final SimplePublicKey pub = await pair.extractPublicKey();
  return PackKey(
    seed: Uint8List.fromList(await pair.extractPrivateKeyBytes()),
    publicKey: Uint8List.fromList(pub.bytes),
  );
}

/// Writes the sample pack as a source folder: pack.json, the JSON documents, the pictures and one recording.
Directory writeSampleSource(Directory dir, {String version = '1.0.0', bool compact = false}) {
  final SamplePack p = SamplePack();
  dir.createSync(recursive: true);
  void put(String name, List<int> bytes) =>
      File('${dir.path}${Platform.pathSeparator}$name').writeAsBytesSync(bytes);
  for (final MapEntry<String, Object?> e in p.docs.entries) {
    final String text = compact ? jsonEncode(e.value) : const JsonEncoder.withIndent('  ').convert(e.value);
    put(e.key, utf8.encode('$text\n'));
  }
  for (final Map<String, Object?> a in p.manifestList('assets')) {
    put(a['file']! as String, utf8.encode('<svg viewBox="0 0 10 10"><!-- ${a['id']} --></svg>\n'));
  }
  put('prompt_butterflies.mp3', List<int>.generate(300, (int i) => (i * 7) & 0xFF));
  put(
    'pack.json',
    utf8.encode(
      const JsonEncoder.withIndent('  ').convert(<String, Object?>{
        'schema': 'pack-source/v1',
        'id': 'sample-pack',
        'version': version,
        'minAppVersion': '0.1.0',
        'assets': p.manifest['assets'],
        'vo': p.manifest['vo'],
      }),
    ),
  );
  return dir;
}

/// Builds the sample pack with [key] in a temporary folder.
Future<BuiltPack> buildSamplePack(PackKey key, {String version = '1.0.0', bool compact = false}) async {
  final Directory tmp = Directory.systemTemp.createTempSync('nn_src_');
  try {
    return await buildPack(
      writeSampleSource(
        Directory('${tmp.path}${Platform.pathSeparator}src'),
        version: version,
        compact: compact,
      ),
      key,
    );
  } finally {
    tmp.deleteSync(recursive: true);
  }
}

/// Counts how often the JSON parser is asked to read something, and what.
class DecodeSpy {
  final List<String> seen = <String>[];

  Object? call(String text) {
    seen.add(text);
    return jsonDecode(text);
  }
}

/// Convenience for tests: verify with the given public key.
Future<VerifiedPack> verifyWith(Uint8List bytes, PackKey key, {DecodeSpy? spy}) =>
    verifyPack(bytes, publicKey: key.publicKey, decode: spy?.call ?? jsonDecode);

/// Opens a built pack, lets the test change its manifest and files, and signs the result again with
/// [key]: a pack that is genuine in form but not what the builder would have made. With [fixHashes]
/// (the default) the manifest's file list is recomputed from the files, so only the change under
/// test is wrong.
Future<Uint8List> forge(
  PackKey key,
  Uint8List pack, {
  void Function(Map<String, Uint8List> files)? files,
  void Function(Map<String, Object?> manifest)? manifest,
  bool fixHashes = true,
}) async {
  final Map<String, Uint8List> byName = <String, Uint8List>{
    for (final ZipEntry e in readStoredZip(pack)) e.name: Uint8List.fromList(e.data),
  };
  final Map<String, Object?> m = jsonDecode(utf8.decode(byName[manifestName]!))! as Map<String, Object?>;
  byName.remove(manifestName);
  byName.remove(signatureName);
  files?.call(byName);
  if (fixHashes) {
    m['files'] = <Object?>[
      for (final String n in (byName.keys.toList()..sort()))
        <String, Object?>{'name': n, 'sha256': sha256Hex(byName[n]!), 'size': byName[n]!.length},
    ];
  }
  manifest?.call(m);
  final Uint8List manifestBytes = Uint8List.fromList(
    utf8.encode('${const JsonEncoder.withIndent('  ').convert(m)}\n'),
  );
  return resign(key, manifestBytes, byName);
}

/// Signs [manifestBytes] and packs them with [files].
Future<Uint8List> resign(PackKey key, Uint8List manifestBytes, Map<String, Uint8List> files) async {
  final Signature sig = await Ed25519().sign(signingInput(manifestBytes), keyPair: await key.toKeyPair());
  return writeStoredZip(<ZipEntry>[
    ZipEntry(manifestName, manifestBytes),
    ZipEntry(signatureName, Uint8List.fromList(sig.bytes)),
    for (final MapEntry<String, Uint8List> e in files.entries) ZipEntry(e.key, e.value),
  ]);
}

/// The pack's entries by name, including manifest.json and manifest.sig.
// Copies: the reader hands out views into the zip, and tests change the bytes in place.
Map<String, Uint8List> unzip(Uint8List pack) => <String, Uint8List>{
  for (final ZipEntry e in readStoredZip(pack)) e.name: Uint8List.fromList(e.data),
};

/// A pack with [changes] applied to its entries and the zip written again (so the container is
/// valid and only the content is wrong). Nothing is re-signed.
Uint8List rezip(Uint8List pack, void Function(Map<String, Uint8List> entries) changes) {
  final Map<String, Uint8List> entries = unzip(pack);
  changes(entries);
  return writeStoredZip(<ZipEntry>[
    for (final MapEntry<String, Uint8List> e in entries.entries) ZipEntry(e.key, e.value),
  ]);
}

/// A plain Ed25519 signature over [message] (no label), for tests of what the label protects.
Future<List<int>> ed25519Sign(PackKey key, Uint8List message) async =>
    (await Ed25519().sign(message, keyPair: await key.toKeyPair())).bytes;
