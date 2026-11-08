import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:nitznutz/content/bundled_packs.dart';
import 'package:nitznutz/content/models.dart';
import 'package:nitznutz/content/pack_verify.dart';

/// The bundled starter pack, verified with the public key built into the app, ready to play.
Future<PackContent> loadStarter() async {
  final VerifiedPack pack = await verifyPack(
    File(bundledStarterAsset).readAsBytesSync(),
    publicKey: unhex(File('assets/pack_signing_public_key.txt').readAsStringSync()),
  );
  return PackContent.fromPack(pack);
}

/// The starter pack with NUM-A-01 taken out of the prerequisites of NUM-A-03, so that the butterflies lesson is the first lesson of the
/// Counting Hills again, as it was before the path gate (M10, E0, holds `butterflies` back until counting words are known). For the tests
/// of how a lesson plays and looks, which open "the first lesson" of the land: not for a test of the path, which uses [loadStarter].
Future<PackContent> loadStarterButterfliesFirst() async {
  final VerifiedPack pack = await verifyPack(
    File(bundledStarterAsset).readAsBytesSync(),
    publicKey: unhex(File('assets/pack_signing_public_key.txt').readAsStringSync()),
  );
  final Map<String, Object?> skill = pack.docs['skill.NUM-A-03.json']! as Map<String, Object?>;
  skill['prerequisites'] = <Object?>[];
  return PackContent.fromPack(pack);
}

/// The starter pack's manifest, with the docs and pictures read from the sources in content/starter.
Future<PackContent> loadSourcePack() async {
  final VerifiedPack signed = await verifyPack(
    File(bundledStarterAsset).readAsBytesSync(),
    publicKey: unhex(File('assets/pack_signing_public_key.txt').readAsStringSync()),
  );
  final Map<String, Object?> docs = <String, Object?>{};
  final Map<String, Uint8List> files = <String, Uint8List>{};
  final List<Map<String, Object?>> assets = <Map<String, Object?>>[];
  for (final FileSystemEntity e in Directory('../content/starter').listSync()) {
    if (e is! File) continue;
    final String name = e.uri.pathSegments.last;
    final Uint8List bytes = e.readAsBytesSync();
    files[name] = bytes;
    if (name.endsWith('.json')) docs[name] = jsonDecode(utf8.decode(bytes));
    if (name.endsWith('.svg')) {
      assets.add(<String, Object?>{'id': name.substring(0, name.length - 4), 'file': name});
    }
  }
  final Map<String, Object?> manifest = Map<String, Object?>.of(signed.manifest)..['assets'] = assets;
  return PackContent.fromPack(
    VerifiedPack(
      manifestBytes: signed.manifestBytes,
      signature: signed.signature,
      manifestSha256: signed.manifestSha256,
      manifest: manifest,
      docs: docs,
      files: files,
    ),
  );
}
