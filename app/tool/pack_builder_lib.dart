// The pack builder's working parts, kept apart from the command line so tests can use them.
//
// A source folder is flat: `pack.json` (id, version, assets, voice lines) next to the content files
// (`activity.<id>.json`, `lesson.<id>.json`, `skill.<id>.json`, `misconception.<tag>.json`, pictures,
// recordings). `buildPack` checks all of it with the same validator the app uses, writes the manifest,
// signs the exact manifest bytes with Ed25519 and packs everything into a deterministic zip.
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:nitznutz/content/pack_validation.dart';
import 'package:nitznutz/content/pack_verify.dart';
import 'package:nitznutz/content/schema.dart';
import 'package:nitznutz/content/schemas.dart';
import 'package:nitznutz/content/zip_store.dart';

/// The build stopped; [problems] says what to fix.
class BuildFailed implements Exception {
  const BuildFailed(this.reason, [this.problems = const <Problem>[]]);

  final String reason;
  final List<Problem> problems;

  @override
  String toString() =>
      problems.isEmpty ? reason : '$reason\n${problems.map((Problem p) => '  $p').join('\n')}';
}

class BuiltPack {
  const BuiltPack({required this.fileName, required this.bytes, required this.manifestSha256});

  /// `<id>-<version>.nnpack`
  final String fileName;
  final Uint8List bytes;
  final String manifestSha256;
}

// ---- keys ----

const String keyFileHeader = 'nitznutz pack-signing key v1';

class PackKey {
  const PackKey({required this.seed, required this.publicKey});

  final Uint8List seed;
  final Uint8List publicKey;

  Future<SimpleKeyPair> toKeyPair() async {
    final SimpleKeyPair pair = await Ed25519().newKeyPairFromSeed(seed);
    final SimplePublicKey pub = await pair.extractPublicKey();
    if (hex(pub.bytes) != hex(publicKey)) {
      throw const BuildFailed('the key file is damaged: the public half does not match');
    }
    return pair;
  }
}

/// The folder (if any) of a git working tree that contains [path]: the signing key must never be written there.
String? gitRootAbove(String path) {
  Directory dir = File(path).absolute.parent;
  while (true) {
    if (FileSystemEntity.typeSync('${dir.path}${Platform.pathSeparator}.git') !=
        FileSystemEntityType.notFound) {
      return dir.path;
    }
    final Directory up = dir.parent;
    if (up.path == dir.path) return null;
    dir = up;
  }
}

String defaultKeyPath() {
  final String? home = Platform.environment['USERPROFILE'] ?? Platform.environment['HOME'];
  if (home == null) throw const BuildFailed('no home folder: pass --out');
  return '$home${Platform.pathSeparator}nitznutz-secrets${Platform.pathSeparator}pack-signing.key';
}

/// Makes a new signing key and writes it to [path]. Refuses a path inside a git working tree and a
/// file that already exists. The private half is never printed; the public half is returned.
Future<PackKey> generateKeyFile(String path) async {
  final String? root = gitRootAbove(path);
  if (root != null) {
    throw BuildFailed(
      'refusing to write the private key inside a git working tree ($root); use a folder outside the repo',
    );
  }
  final File file = File(path);
  if (file.existsSync()) throw BuildFailed('$path already exists; not overwriting a signing key');
  final SimpleKeyPair pair = await Ed25519().newKeyPair();
  final SimpleKeyPairData data = await pair.extract();
  final SimplePublicKey pub = await pair.extractPublicKey();
  final PackKey key = PackKey(
    seed: Uint8List.fromList(await pair.extractPrivateKeyBytes()),
    publicKey: Uint8List.fromList(pub.bytes),
  );
  assert(data.bytes.length == 32);
  file.parent.createSync(recursive: true);
  file.writeAsStringSync(
    '$keyFileHeader\npublic: ${hex(key.publicKey)}\nseed: ${hex(key.seed)}\n',
    flush: true,
  );
  return key;
}

PackKey readKeyFile(String path) {
  final File file = File(path);
  if (!file.existsSync()) throw BuildFailed('no key file at $path');
  final List<String> lines = file.readAsLinesSync();
  if (lines.length < 3 || lines[0] != keyFileHeader) {
    throw BuildFailed('$path is not a pack-signing key file');
  }
  try {
    final Uint8List pub = unhex(lines[1].replaceFirst('public:', ''));
    final Uint8List seed = unhex(lines[2].replaceFirst('seed:', ''));
    if (pub.length != 32 || seed.length != 32) throw const FormatException('wrong length');
    return PackKey(seed: seed, publicKey: pub);
  } on FormatException {
    throw BuildFailed('$path is damaged');
  }
}

/// A public key file holds the 64 hex digits and a newline.
Uint8List readPublicKeyFile(String path) {
  final File file = File(path);
  if (!file.existsSync()) throw BuildFailed('no public key file at $path');
  try {
    final Uint8List key = unhex(file.readAsStringSync());
    if (key.length != 32) throw const FormatException('wrong length');
    return key;
  } on FormatException {
    throw BuildFailed('$path does not hold a 32-byte public key in hexadecimal');
  }
}

// ---- building ----

final RegExp _textFile = RegExp(r'\.(json|svg|txt)$');

Uint8List _normalised(String name, Uint8List bytes) {
  if (!_textFile.hasMatch(name)) return bytes;
  // The same bytes on every operating system: git on Windows may check text out with CRLF line ends.
  final List<int> out = <int>[];
  for (int i = 0; i < bytes.length; i++) {
    if (bytes[i] == 0x0D && i + 1 < bytes.length && bytes[i + 1] == 0x0A) continue;
    out.add(bytes[i]);
  }
  return Uint8List.fromList(out);
}

int _versionNumber(String v) {
  final List<int> parts = v.split('.').map(int.parse).toList();
  return parts[0] * 100 + parts[1];
}

Object? _jsonOrNull(Uint8List bytes) {
  try {
    return jsonDecode(utf8.decode(bytes));
  } on FormatException {
    return null;
  }
}

/// Builds the pack in [source] and signs it with [key]. The same sources and key always give the same bytes
/// (Ed25519 signatures are deterministic).
Future<BuiltPack> buildPack(Directory source, PackKey key) async {
  if (!source.existsSync()) throw BuildFailed('no source folder at ${source.path}');
  final File descriptor = File('${source.path}${Platform.pathSeparator}pack.json');
  if (!descriptor.existsSync()) throw const BuildFailed('the source folder has no pack.json');
  final Object? pack = _jsonOrNull(descriptor.readAsBytesSync());
  if (pack is! Map<String, Object?>) throw const BuildFailed('pack.json is not a JSON object');
  final List<Problem> shape = validate(packSourceSchema, pack);
  if (shape.isNotEmpty) {
    throw BuildFailed('pack.json does not follow its schema', <Problem>[
      for (final Problem p in shape)
        Problem(p.path.isEmpty ? 'pack.json' : 'pack.json › ${p.path}', p.message),
    ]);
  }

  // Every other file in the folder goes into the pack.
  final Map<String, Uint8List> files = <String, Uint8List>{};
  final List<Problem> problems = <Problem>[];
  for (final FileSystemEntity e in source.listSync(followLinks: false)) {
    final String name = e.uri.pathSegments.where((String s) => s.isNotEmpty).last;
    if (name == 'pack.json') continue;
    if (e is! File) {
      problems.add(Problem(name, 'is a folder or link; a pack is flat'));
      continue;
    }
    final String? why = unsafeNameReason(name);
    if (why != null) {
      problems.add(Problem(name, why));
      continue;
    }
    files[name] = _normalised(name, e.readAsBytesSync());
  }
  if (problems.isNotEmpty) {
    throw BuildFailed('the source folder has files that cannot go into a pack', problems);
  }

  final Map<String, Object?> docs = <String, Object?>{};
  for (final MapEntry<String, Uint8List> f in files.entries) {
    if (!f.key.endsWith('.json')) continue;
    final Object? doc = _jsonOrNull(f.value);
    if (doc == null) {
      problems.add(Problem(f.key, 'is not valid JSON'));
    } else {
      docs[f.key] = doc;
    }
  }
  if (problems.isNotEmpty) throw BuildFailed('some files are not valid JSON', problems);

  // Which template versions the activities need, and the ids of each kind.
  final Map<String, String> templates = <String, String>{};
  final Map<String, List<String>> entries = <String, List<String>>{
    'activities': <String>[],
    'lessons': <String>[],
    'skills': <String>[],
    'misconceptions': <String>[],
  };
  const Map<String, String> kinds = <String, String>{
    'activity': 'activities',
    'lesson': 'lessons',
    'skill': 'skills',
    'misconception': 'misconceptions',
  };
  for (final String name in docs.keys) {
    final RegExpMatch? m = RegExp(r'^([a-z]+)\.(.+)\.json$').firstMatch(name);
    if (m == null) continue; // validatePack reports it
    final String? list = kinds[m.group(1)];
    if (list != null) entries[list]!.add(m.group(2)!);
    if (m.group(1) == 'activity') {
      final Object? doc = docs[name];
      if (doc is Map<String, Object?> && doc['template'] is String && doc['templateVersion'] is String) {
        final String t = doc['template']! as String;
        final String v = doc['templateVersion']! as String;
        if (!RegExp('^${Patterns.templateVersion}\$').hasMatch(v)) continue; // the schema reports it
        final String? known = supportedTemplates[t];
        if (known != null && _versionNumber(v) > _versionNumber(known)) {
          problems.add(Problem(name, 'templateVersion $v is newer than this builder supports ($known)'));
        }
        final String? have = templates[t];
        if (have == null || _versionNumber(v) > _versionNumber(have)) templates[t] = v;
      }
    }
  }
  for (final List<String> l in entries.values) {
    l.sort();
  }

  final List<String> names = files.keys.toList()..sort();
  final Map<String, Object?> manifest = <String, Object?>{
    'schema': SchemaIds.manifest,
    'id': pack['id'],
    'version': pack['version'],
    'minAppVersion': pack['minAppVersion'],
    'templates': <String, Object?>{for (final String t in (templates.keys.toList()..sort())) t: templates[t]},
    'files': <Object?>[
      for (final String n in names)
        <String, Object?>{'name': n, 'sha256': sha256Hex(files[n]!), 'size': files[n]!.length},
    ],
    'assets': pack['assets'],
    'vo': pack['vo'],
    'voPending': pack['voPending'],
    'entries': entries,
  };
  problems.addAll(validatePack(manifest: manifest, docs: docs, files: names.toSet()));
  if (problems.isNotEmpty) {
    throw BuildFailed('the pack does not follow the content rules; nothing was signed', problems);
  }

  final Uint8List manifestBytes = Uint8List.fromList(
    utf8.encode('${const JsonEncoder.withIndent('  ').convert(manifest)}\n'),
  );
  final SimpleKeyPair pair = await key.toKeyPair();
  final Signature signature = await Ed25519().sign(signingInput(manifestBytes), keyPair: pair);
  final Uint8List zip = writeStoredZip(<ZipEntry>[
    ZipEntry(manifestName, manifestBytes),
    ZipEntry(signatureName, Uint8List.fromList(signature.bytes)),
    for (final String n in names) ZipEntry(n, files[n]!),
  ]);

  // The builder trusts nothing it made: run the app's own check before handing the file over.
  final VerifiedPack check = await verifyPack(zip, publicKey: key.publicKey);
  return BuiltPack(
    fileName: '${pack['id']}-${pack['version']}.nnpack',
    bytes: zip,
    manifestSha256: check.manifestSha256,
  );
}

// ---- JSON Schema files ----

// Written by the tool, never by the app: the app holds no web address (CLAUDE.md rule 9).
const String _dialect = 'https://json-schema.org/draft/2020-12/schema';

/// The JSON Schema file for every document kind, by file name, made from the same definitions the validator uses.
Map<String, String> renderSchemas() => <String, String>{
  for (final MapEntry<String, Schema> e in allSchemas.entries)
    '${e.key}.schema.json':
        '${const JsonEncoder.withIndent('  ').convert(<String, Object?>{r'$schema': _dialect, ...toJsonSchema(e.value, id: 'urn:nitznutz:schema:${e.key}', title: 'Nitznutz ${e.key}')})}\n',
};
