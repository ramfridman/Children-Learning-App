import 'dart:typed_data';

import 'models.dart';
import 'pack_installer.dart';
import 'pack_verify.dart';

/// Gets the lessons the app plays: installs the pack that ships inside the app (the same safe path
/// as any pack, so it is checked against the built-in key), then reads the installed pack back and
/// proves it again before anything is shown.
class ContentRepository {
  ContentRepository({required this.installer, required this.bundled, this.packId = 'starter'});

  final PackInstaller installer;

  /// The bytes of the pack file that is part of the app.
  final Future<Uint8List> Function() bundled;
  final String packId;

  /// The starter pack, ready to play. Throws [PackRejected] if the installed copy is not genuine, and
  /// [StateError] if there is nothing to play.
  Future<PackContent> starter() async {
    try {
      await installer.install(await bundled());
    } on PackRejected catch (e) {
      // "rules" means a copy that is the same or newer is already installed (an updated pack arrived
      // earlier): that copy is the one to play. Anything else about the bundled file is a real problem.
      if (e.stage != 'rules') rethrow;
    }
    await installer.sweep();
    final VerifiedPack? pack = await installer.load(packId);
    if (pack == null) throw StateError('the pack $packId is not installed');
    if (pack.hidden) throw StateError('the pack $packId needs a newer app: ${pack.hiddenReason}');
    return PackContent.fromPack(pack);
  }
}
