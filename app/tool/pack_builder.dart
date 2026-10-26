// The pack builder. Run from the app/ folder:
//
//   dart run tool/pack_builder.dart keygen [--out <key file>] [--replace-public]
//   dart run tool/pack_builder.dart build <source folder> [--key <key file>] [--out <folder>]
//   dart run tool/pack_builder.dart verify <pack file> [--public-key <file>]
//   dart run tool/pack_builder.dart inspect <pack file> [--public-key <file>]
//   dart run tool/pack_builder.dart build-character <character folder> [--key <key file>] [--out <folder>]
//   dart run tool/pack_builder.dart publish <pack file>... [--voices <voices.json>] [--url <project url>] [--dry-run]
//   dart run tool/pack_builder.dart schema [--out <folder>] [--check]
//   dart run tool/pack_builder.dart damage <pack file> [--source <folder>] [--out <folder>]
//
// `keygen` writes the private key to %USERPROFILE%\nitznutz-secrets\pack-signing.key (outside the repo;
// it refuses a path inside any git working tree) and the public key to assets/pack_signing_public_key.txt.
// The private key is never printed.
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:nitznutz/content/pack_verify.dart';

import 'pack_builder_lib.dart';
import 'publish_lib.dart';

const String _publicKeyAsset = 'assets/pack_signing_public_key.txt';
const String _schemaFolder = '../content/schemas';

Future<void> main(List<String> args) async {
  if (args.isEmpty) {
    _usage();
    exit(2);
  }
  final List<String> rest = args.sublist(1);
  try {
    switch (args.first) {
      case 'keygen':
        await _keygen(rest);
      case 'build':
        await _build(rest);
      case 'build-character':
        await _buildCharacter(rest);
      case 'verify':
        await _verify(rest, inspect: false);
      case 'inspect':
        await _verify(rest, inspect: true);
      case 'publish':
        await _publish(rest);
      case 'schema':
        _schema(rest);
      case 'damage':
        await _damage(rest);
      default:
        _usage();
        exit(2);
    }
  } on BuildFailed catch (e) {
    stderr.writeln('FAILED: $e');
    exit(1);
  } on PackRejected catch (e) {
    stderr.writeln('REFUSED: $e');
    exit(1);
  }
}

void _usage() {
  stderr.writeln(
    'usage: dart run tool/pack_builder.dart keygen|build|verify|inspect|schema ... (see the top of this file)',
  );
}

String? _option(List<String> args, String name) {
  final int i = args.indexOf(name);
  return i >= 0 && i + 1 < args.length ? args[i + 1] : null;
}

List<String> _positional(List<String> args) {
  final List<String> out = <String>[];
  for (int i = 0; i < args.length; i++) {
    if (args[i].startsWith('--')) {
      if (args[i] != '--check' && args[i] != '--replace-public' && args[i] != '--dry-run') i++;
    } else {
      out.add(args[i]);
    }
  }
  return out;
}

Future<void> _keygen(List<String> args) async {
  final String path = _option(args, '--out') ?? defaultKeyPath();
  final File publicFile = File(_publicKeyAsset);
  if (publicFile.existsSync() && !args.contains('--replace-public')) {
    throw BuildFailed(
      '$_publicKeyAsset already exists; the app already trusts a key. Pass --replace-public to change it on purpose.',
    );
  }
  final PackKey key = await generateKeyFile(path);
  publicFile.parent.createSync(recursive: true);
  publicFile.writeAsStringSync('${hex(key.publicKey)}\n');
  stdout.writeln('Private key written to $path (not shown; save it in your password manager).');
  stdout.writeln('Public key written to $_publicKeyAsset:');
  stdout.writeln(hex(key.publicKey));
}

Future<void> _build(List<String> args) async {
  final List<String> pos = _positional(args);
  if (pos.length != 1) throw const BuildFailed('build needs one source folder');
  final PackKey key = readKeyFile(_option(args, '--key') ?? defaultKeyPath());
  final BuiltPack built = await buildPack(Directory(pos.single), key);
  final Directory out = Directory(_option(args, '--out') ?? '.')..createSync(recursive: true);
  final File file = File('${out.path}${Platform.pathSeparator}${built.fileName}');
  file.writeAsBytesSync(built.bytes);
  stdout.writeln('Built ${file.path}: ${built.bytes.length} bytes, manifest sha256 ${built.manifestSha256}');
}

Future<void> _buildCharacter(List<String> args) async {
  final List<String> pos = _positional(args);
  if (pos.length != 1) throw const BuildFailed('build-character needs one character folder');
  final PackKey key = readKeyFile(_option(args, '--key') ?? defaultKeyPath());
  final BuiltPack built = await buildCharacterPack(Directory(pos.single), key);
  final Directory out = Directory(_option(args, '--out') ?? '.')..createSync(recursive: true);
  final File file = File('${out.path}${Platform.pathSeparator}${built.fileName}');
  file.writeAsBytesSync(built.bytes);
  stdout.writeln('Built ${file.path}: ${built.bytes.length} bytes, manifest sha256 ${built.manifestSha256}');
}

Future<void> _verify(List<String> args, {required bool inspect}) async {
  final List<String> pos = _positional(args);
  if (pos.length != 1) throw const BuildFailed('this command needs one pack file');
  final Uint8List publicKey = readPublicKeyFile(_option(args, '--public-key') ?? _publicKeyAsset);
  final VerifiedPack pack = await verifyPack(File(pos.single).readAsBytesSync(), publicKey: publicKey);
  stdout.writeln('OK: ${pack.id} ${pack.version} is genuine (manifest sha256 ${pack.manifestSha256})');
  if (inspect) {
    final Map<String, Object?> entries = pack.manifest['entries']! as Map<String, Object?>;
    stdout.writeln('needs app >= ${pack.manifest['minAppVersion']}, templates ${pack.manifest['templates']}');
    stdout.writeln(
      '${pack.files.length} files, ${pack.files.values.fold<int>(0, (int a, Uint8List b) => a + b.length)} bytes',
    );
    for (final MapEntry<String, Object?> e in entries.entries) {
      stdout.writeln('${e.key}: ${(e.value! as List<Object?>).join(', ')}');
    }
    stdout.writeln(
      'voice lines recorded: ${(pack.manifest['vo']! as List<Object?>).length}, pending: ${(pack.manifest['voPending']! as List<Object?>).length}',
    );
  }
}

/// Writes copies of a pack that the app must refuse (and, with --source, a pack of a newer version signed by
/// a key the app does not trust), for showing on a phone that they are.
Future<void> _damage(List<String> args) async {
  final List<String> pos = _positional(args);
  if (pos.length != 1) throw const BuildFailed('damage needs one pack file');
  final Directory out = Directory(_option(args, '--out') ?? 'damaged')..createSync(recursive: true);
  final Uint8List pack = File(pos.single).readAsBytesSync();
  final Map<String, Uint8List> variants = damagedVariants(pack);
  final String? source = _option(args, '--source');
  if (source != null) {
    // A well-made pack of a newer version, but signed with a key made just now: genuine in form, not from us.
    final File scratch = File(
      '${Directory.systemTemp.createTempSync('nn_damage_').path}${Platform.pathSeparator}k.key',
    );
    final PackKey stranger = await generateKeyFile(scratch.path);
    final BuiltPack built = await buildPack(Directory(source), stranger);
    variants['stranger-key.nnpack'] = built.bytes;
    scratch.parent.deleteSync(recursive: true);
  }
  for (final MapEntry<String, Uint8List> v in variants.entries) {
    File('${out.path}${Platform.pathSeparator}${v.key}').writeAsBytesSync(v.value);
    stdout.writeln('wrote ${v.key} (${v.value.length} bytes)');
  }
}

/// Sends the item index of verified packs to the gateway (`content-publish`). `--dry-run` only shows what would be sent.
/// The secret is read from NITZNUTZ_PUBLISH_SECRET and the project from `--url` or app/config/dev.local.json.
Future<void> _publish(List<String> args) async {
  final List<String> files = _positional(args);
  if (files.isEmpty) throw const BuildFailed('publish needs at least one pack file');
  final bool dry = args.contains('--dry-run');
  final File voicesFile = File(_option(args, '--voices') ?? '../content/voices.json');
  final Map<String, String> voices = voicesFile.existsSync() ? readVoices(voicesFile) : <String, String>{};
  final Uint8List publicKey = readPublicKeyFile(_publicKeyAsset);
  String? url = _option(args, '--url');
  String? publishable;
  final File cfg = File('config/dev.local.json');
  if (cfg.existsSync()) {
    final Map<String, Object?> j = jsonDecode(cfg.readAsStringSync()) as Map<String, Object?>;
    url ??= j['SUPABASE_URL'] as String?;
    publishable = j['SUPABASE_PUBLISHABLE_KEY'] as String?;
  }
  final String secret = Platform.environment['NITZNUTZ_PUBLISH_SECRET'] ?? '';
  if (!dry && (url == null || secret.length < 24)) {
    throw const BuildFailed(
      'set NITZNUTZ_PUBLISH_SECRET (24 characters or more) and a project url (--url or config/dev.local.json)',
    );
  }
  for (final String f in files) {
    final VerifiedPack pack = await verifyPack(File(f).readAsBytesSync(), publicKey: publicKey);
    final Map<String, Object?> body = indexOf(pack, voices: voices);
    stdout.writeln(
      '${pack.id} ${pack.version}: ${(body['items']! as List<Object?>).length} items, '
      '${(body['misconceptions']! as List<Object?>).length} misconceptions, '
      '${(body['characters']! as List<Object?>).length} characters, ${utf8.encode(jsonEncode(body)).length} bytes',
    );
    if (dry) continue;
    final Map<String, Object?> answer = await publish(
      body,
      baseUrl: url!,
      secret: secret,
      publishableKey: publishable,
    );
    stdout.writeln('  server: ${answer['result']}');
  }
}

void _schema(List<String> args) {
  final Directory out = Directory(_option(args, '--out') ?? _schemaFolder);
  final Map<String, String> files = renderSchemas();
  if (args.contains('--check')) {
    bool current = true;
    for (final MapEntry<String, String> e in files.entries) {
      final File f = File('${out.path}${Platform.pathSeparator}${e.key}');
      if (!f.existsSync() || f.readAsStringSync().replaceAll('\r\n', '\n') != e.value) {
        stderr.writeln('${f.path} is out of date: run `dart run tool/pack_builder.dart schema`.');
        current = false;
      }
    }
    if (!current) exit(1);
    stdout.writeln('The JSON Schema files in ${out.path} are up to date.');
    return;
  }
  out.createSync(recursive: true);
  for (final MapEntry<String, String> e in files.entries) {
    File('${out.path}${Platform.pathSeparator}${e.key}').writeAsStringSync(e.value);
  }
  stdout.writeln('Wrote ${files.length} schema files to ${out.path}');
}
