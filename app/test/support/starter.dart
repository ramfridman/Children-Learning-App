import 'dart:io';

import 'package:nitznutz/content/models.dart';
import 'package:nitznutz/content/pack_verify.dart';

/// The bundled starter pack, verified with the public key built into the app, ready to play.
Future<PackContent> loadStarter() async {
  final VerifiedPack pack = await verifyPack(
    File('assets/packs/starter-0.10.0.nnpack').readAsBytesSync(),
    publicKey: unhex(File('assets/pack_signing_public_key.txt').readAsStringSync()),
  );
  return PackContent.fromPack(pack);
}

/// The starter pack with NUM-A-01 taken out of the prerequisites of NUM-A-03, so that the butterflies lesson is the first lesson of the
/// Counting Hills again, as it was before the path gate (M10, E0, holds `butterflies` back until counting words are known). For the tests
/// of how a lesson plays and looks, which open "the first lesson" of the land: not for a test of the path, which uses [loadStarter].
Future<PackContent> loadStarterButterfliesFirst() async {
  final VerifiedPack pack = await verifyPack(
    File('assets/packs/starter-0.10.0.nnpack').readAsBytesSync(),
    publicKey: unhex(File('assets/pack_signing_public_key.txt').readAsStringSync()),
  );
  final Map<String, Object?> skill = pack.docs['skill.NUM-A-03.json']! as Map<String, Object?>;
  skill['prerequisites'] = <Object?>[];
  return PackContent.fromPack(pack);
}
