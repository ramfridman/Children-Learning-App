import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart' show sha256;
import 'package:cryptography/cryptography.dart';

import 'capabilities.dart';
import 'pack_validation.dart';
import 'schema.dart';
import 'schemas.dart';
import 'zip_store.dart';

// How a pack is proven genuine, in the order that keeps everything from outside untrusted:
//
//   1. the zip container is read with the narrow reader (zip_store.dart): no parsing of any content;
//   2. the Ed25519 signature over the exact bytes of manifest.json is checked with the built-in key;
//   3. only then is the manifest parsed, and every other file's size and SHA-256 are compared with it;
//   4. only when every file is proven are the JSON documents parsed and cross-checked.
//
// The pack builder (`tool/pack_builder.dart verify`) and the app's installer both call [verifyPack],
// so what the builder accepts is exactly what the app accepts.

const String manifestName = 'manifest.json';
const String signatureName = 'manifest.sig';

/// What is signed: this label, then the exact bytes of manifest.json. The label means a signature made
/// for a pack can never be mistaken for a signature over anything else made with the same key.
const String signatureLabel = 'nitznutz-pack-v1\n';

/// The deepest nesting a JSON file of a pack may have (the schemas need about 8).
const int maxJsonDepth = 24;

Uint8List signingInput(Uint8List manifestBytes) =>
    Uint8List.fromList(<int>[...utf8.encode(signatureLabel), ...manifestBytes]);

/// A pack that was refused: [stage] says how far it got, [reason] why it stopped.
class PackRejected implements Exception {
  const PackRejected(this.stage, this.reason, [this.problems = const <Problem>[]]);

  /// One of `zip`, `signature`, `manifest`, `files`, `content`.
  final String stage;
  final String reason;
  final List<Problem> problems;

  @override
  String toString() => 'PackRejected($stage): $reason${problems.isEmpty ? '' : '\n${problems.join('\n')}'}';
}

/// A pack that passed every check. Nothing here has been installed or shown.
class VerifiedPack {
  const VerifiedPack({
    required this.manifestBytes,
    required this.signature,
    required this.manifestSha256,
    required this.manifest,
    required this.docs,
    required this.files,
    this.hiddenReason,
  });

  final Uint8List manifestBytes;

  /// The 64 bytes of manifest.sig that were checked.
  final Uint8List signature;

  /// Lower-case hex SHA-256 of manifest.json; it names this exact pack (the manifest lists every file's hash).
  final String manifestSha256;
  final Map<String, Object?> manifest;

  /// Each JSON file by name, parsed.
  final Map<String, Object?> docs;

  /// Set when the pack is genuine but this app cannot play it (a newer app or template is needed). Its
  /// content has not been read or validated, so [docs] is empty; keep it hidden.
  final String? hiddenReason;

  bool get hidden => hiddenReason != null;

  /// Every content file by name (not manifest.json or manifest.sig), as the bytes that were verified.
  final Map<String, Uint8List> files;

  String get id => manifest['id']! as String;
  String get version => manifest['version']! as String;
}

typedef JsonParse = Object? Function(String text);

final Ed25519 _ed25519 = Ed25519();

String hex(List<int> bytes) => bytes.map((int b) => b.toRadixString(16).padLeft(2, '0')).join();

Uint8List unhex(String text) {
  final String t = text.trim();
  if (t.length.isOdd || !RegExp(r'^[0-9a-fA-F]*$').hasMatch(t)) {
    throw const FormatException('not hexadecimal');
  }
  return Uint8List.fromList(<int>[
    for (int i = 0; i < t.length; i += 2) int.parse(t.substring(i, i + 2), radix: 16),
  ]);
}

String sha256Hex(List<int> bytes) => hex(sha256.convert(bytes).bytes);

/// True if [bytes], read as JSON text, nests arrays and objects no deeper than [maxJsonDepth].
bool jsonDepthWithinLimit(Uint8List bytes) {
  int depth = 0;
  bool inString = false;
  bool escaped = false;
  for (final int b in bytes) {
    if (inString) {
      if (escaped) {
        escaped = false;
      } else if (b == 0x5C) {
        escaped = true;
      } else if (b == 0x22) {
        inString = false;
      }
    } else if (b == 0x22) {
      inString = true;
    } else if (b == 0x5B || b == 0x7B) {
      if (++depth > maxJsonDepth) return false;
    } else if (b == 0x5D || b == 0x7D) {
      depth--;
    }
  }
  return true;
}

Object? _parse(Uint8List bytes, JsonParse decode, String what, String stage) {
  if (!jsonDepthWithinLimit(bytes)) throw PackRejected(stage, '$what is nested too deeply');
  final String text;
  try {
    text = utf8.decode(bytes);
  } on FormatException {
    throw PackRejected(stage, '$what is not valid UTF-8');
  }
  try {
    return decode(text);
  } on FormatException {
    throw PackRejected(stage, '$what is not valid JSON');
  }
}

/// Checks [bytes] as a pack signed by the holder of [publicKey] (32 bytes). [decode] is how JSON text
/// becomes a value; tests pass a spy to prove nothing is parsed before the checks that come first.
///
/// Throws [PackRejected]; never returns a pack that failed any step.
Future<VerifiedPack> verifyPack(
  Uint8List bytes, {
  required Uint8List publicKey,
  JsonParse decode = jsonDecode,
  AppCapabilities capabilities = AppCapabilities.current,
}) async {
  // 1. The container.
  final List<ZipEntry> entries;
  try {
    entries = readStoredZip(bytes);
  } on ZipException catch (e) {
    throw PackRejected('zip', e.reason);
  }
  return verifyEntries(
    <String, Uint8List>{for (final ZipEntry e in entries) e.name: e.data},
    publicKey: publicKey,
    decode: decode,
    capabilities: capabilities,
  );
}

/// Steps 2 to 4 for the entries of a pack that is already unpacked (an installed pack read back from
/// disk is proven again this way before it is used).
Future<VerifiedPack> verifyEntries(
  Map<String, Uint8List> entries, {
  required Uint8List publicKey,
  JsonParse decode = jsonDecode,
  AppCapabilities capabilities = AppCapabilities.current,
}) async {
  final Map<String, Uint8List> byName = Map<String, Uint8List>.of(entries);
  final Uint8List? manifestBytes = byName.remove(manifestName);
  final Uint8List? signature = byName.remove(signatureName);
  if (manifestBytes == null || signature == null) {
    throw const PackRejected('zip', 'manifest.json or manifest.sig is missing');
  }

  // 2. The signature, over the exact manifest bytes, before anything is parsed.
  if (signature.length != 64) throw const PackRejected('signature', 'the signature has the wrong length');
  if (publicKey.length != 32) throw const PackRejected('signature', 'the public key has the wrong length');
  final bool genuine = await _ed25519.verify(
    signingInput(manifestBytes),
    signature: Signature(signature, publicKey: SimplePublicKey(publicKey, type: KeyPairType.ed25519)),
  );
  if (!genuine) throw const PackRejected('signature', 'the signature is not from this app\'s publisher key');

  // 3. The manifest is now trusted as written by the publisher; read it, then prove every other file.
  final Object? manifest = _parse(manifestBytes, decode, 'manifest.json', 'manifest');
  if (manifest is! Map<String, Object?>) {
    throw const PackRejected('manifest', 'manifest.json is not an object');
  }
  final List<Problem> shape = validate(manifestSchema, manifest);
  if (shape.isNotEmpty) throw PackRejected('manifest', 'manifest.json does not follow its schema', shape);

  final Map<String, Map<String, Object?>> listed = <String, Map<String, Object?>>{
    for (final Object? f in manifest['files']! as List<Object?>)
      (f! as Map<String, Object?>)['name']! as String: f as Map<String, Object?>,
  };
  for (final String name in byName.keys) {
    if (!listed.containsKey(name)) {
      throw PackRejected('files', '"$name" is in the pack but not in the manifest');
    }
  }
  for (final MapEntry<String, Map<String, Object?>> f in listed.entries) {
    final Uint8List? data = byName[f.key];
    if (data == null) throw PackRejected('files', '"${f.key}" is listed in the manifest but missing');
    if (data.length != f.value['size']) throw PackRejected('files', '"${f.key}" has the wrong size');
    if (sha256Hex(data) != f.value['sha256']) {
      throw PackRejected('files', '"${f.key}" does not match its hash');
    }
  }

  // 4. Every byte is proven. A pack this app cannot play is kept as it is, unread.
  final String? hidden = capabilities.incompatibility(manifest);
  if (hidden != null) {
    return VerifiedPack(
      manifestBytes: manifestBytes,
      signature: signature,
      manifestSha256: sha256Hex(manifestBytes),
      manifest: manifest,
      docs: const <String, Object?>{},
      files: byName,
      hiddenReason: hidden,
    );
  }

  // Now the documents may be read.
  final Map<String, Object?> docs = <String, Object?>{};
  for (final String name in byName.keys) {
    if (name.endsWith('.json')) docs[name] = _parse(byName[name]!, decode, name, 'content');
  }
  final List<Problem> problems = validatePack(manifest: manifest, docs: docs, files: byName.keys.toSet());
  if (problems.isNotEmpty) {
    throw PackRejected('content', 'the pack does not follow the content rules', problems);
  }

  return VerifiedPack(
    manifestBytes: manifestBytes,
    signature: signature,
    manifestSha256: sha256Hex(manifestBytes),
    manifest: manifest,
    docs: docs,
    files: byName,
  );
}
