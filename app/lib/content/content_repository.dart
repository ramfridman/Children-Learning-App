import 'dart:typed_data';

import '../core/log.dart';
import '../data/app_database.dart' show InstalledPack;
import '../engine/course.dart';
import 'bundled_packs.dart';
import 'capabilities.dart' show compareSemver;
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
  /// one signed pack per course, named `lang-<course>` (`docs/languages/frame.md` section 1.5): it ships inside the app and is
  /// installed when its language is first turned on ([languagePacks]), or arrives later as an update. Throws [PackRejected] if
  /// the installed copy is not genuine, so one damaged course can be told apart from one that is simply not there.
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

  /// The language packs on this device, by course. First the bundled copy of each course in [wanted] (a language some child has
  /// turned on) is installed through the verifying installer, unless this phone already holds that version or a newer one (an
  /// update that arrived first): a family that has turned no language on installs and reads nothing. Then every installed course is
  /// read back and proven again. A copy that no longer proves itself is put right from the bundle once; a course that still does
  /// not prove itself is left out, and never hurts another (the child's other courses and the lands play on).
  Future<Map<String, PackContent>> languagePacks({
    required Iterable<String> wanted,
    required Map<String, BundledLanguagePack> bundled,
    required Future<Uint8List> Function(String asset) read,
  }) async {
    for (final String course in wanted) {
      final BundledLanguagePack? pack = bundled[course];
      if (pack != null) await _installBundled(pack, read, repair: false);
    }
    final Map<String, PackContent> out = <String, PackContent>{};
    for (final String course in await installedLanguages()) {
      PackContent? content = await _proven(course);
      final BundledLanguagePack? pack = bundled[course];
      if (content == null && pack != null && await _installBundled(pack, read, repair: true)) {
        content = await _proven(course);
      }
      if (content != null) out[course] = content;
    }
    return out;
  }

  /// The course's pack read back and proven, or null. Any failure of one course (a rejected pack, but also a file that cannot be read or a
  /// pack that cannot be built into content) leaves the course out and the others as they are. Only the course and the type of the error
  /// are logged, never the message (it could quote a file).
  Future<PackContent?> _proven(String course) async {
    try {
      return await languagePack(course);
    } on PackRejected {
      return null;
    } on Object catch (e) {
      Log.d('language pack $course not played: ${e.runtimeType}');
      return null;
    }
  }

  /// Installs the bundled copy. Without [repair] only when nothing, or something older, is installed. A file the installer refuses
  /// (a build defect the tests catch), a file that cannot be read or a newer copy already there changes nothing, for this course or
  /// any other. True if the copy is now installed.
  Future<bool> _installBundled(
    BundledLanguagePack pack,
    Future<Uint8List> Function(String asset) read, {
    required bool repair,
  }) async {
    final String course = pack.course;
    try {
      final InstalledPack? row = await installer.registry.find(Course.packIdOf(course)!);
      if (!repair && row != null && compareSemver(row.version, pack.version) >= 0) return false;
      await installer.install(await read(pack.asset));
      return true;
    } on PackRejected {
      return false;
    } on Object catch (e) {
      Log.d('language pack $course not installed: ${e.runtimeType}');
      return false;
    }
  }

  Future<bool> _playable(String id) async {
    final InstalledPack? row = await installer.registry.find(id);
    return row != null && !row.hidden;
  }
}
