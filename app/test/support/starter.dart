import 'dart:io';

import 'package:nitznutz/content/models.dart';
import 'package:nitznutz/content/pack_verify.dart';

/// The bundled starter pack, verified with the public key built into the app, ready to play.
Future<PackContent> loadStarter() async {
  final VerifiedPack pack = await verifyPack(
    File('assets/packs/starter-0.9.0.nnpack').readAsBytesSync(),
    publicKey: unhex(File('assets/pack_signing_public_key.txt').readAsStringSync()),
  );
  return PackContent.fromPack(pack);
}
