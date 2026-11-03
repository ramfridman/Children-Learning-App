import 'dart:typed_data';

import '../data/app_database.dart' show InstalledPack;
import '../engine/course.dart';
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

  /// The pack of a language course, ready to play, or null when it is not installed or this app cannot play it yet. There is
  /// one signed pack per course, named `lang-<course>`; a language pack is downloaded when its language is turned on and is
  /// never part of the app (`docs/languages/frame.md` section 1.5). Throws [PackRejected] if the installed copy is not genuine,
  /// so one damaged course can be told apart from one that is simply not there.
  Future<PackContent?> languagePack(String course) async {
    final String? id = Course.packIdOf(course);
    if (id == null) throw ArgumentError.value(course, 'course', 'is not a language course');
    final VerifiedPack? pack = await installer.load(id);
    if (pack == null || pack.hidden) return null;
    final PackContent content = PackContent.fromPack(pack);
    if (content.course != course) {
      throw const PackRejected('rules', 'the pack is not of the course its id names');
    }
    return content;
  }

  /// The language courses that have a playable pack on this device, in the fixed order of the doors.
  Future<List<String>> installedLanguages() async => <String>[
    for (final String c in Course.languages)
      if (await _playable(Course.packIdOf(c)!)) c,
  ];

  Future<bool> _playable(String id) async {
    final InstalledPack? row = await installer.registry.find(id);
    return row != null && !row.hidden;
  }
}
