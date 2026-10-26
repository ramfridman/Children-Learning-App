import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:drift/drift.dart' show Value;

import '../core/clock.dart';
import '../data/app_database.dart';
import 'capabilities.dart';
import 'pack_verify.dart';

/// Where the list of installed packs is kept. The database implements it; tests use a failing one to
/// prove a crash between the files and the list never leaves half a pack.
abstract interface class PackRegistry {
  Future<InstalledPack?> find(String id);

  Future<List<InstalledPack>> all();

  Future<void> save({
    required String id,
    required String version,
    required String manifestSha256,
    required DateTime at,
    required bool hidden,
    required String hiddenReason,
  });
}

class DbPackRegistry implements PackRegistry {
  const DbPackRegistry(this._db);

  final AppDatabase _db;

  @override
  Future<InstalledPack?> find(String id) => _db.installedPack(id);

  @override
  Future<List<InstalledPack>> all() => _db.allInstalledPacks();

  @override
  Future<void> save({
    required String id,
    required String version,
    required String manifestSha256,
    required DateTime at,
    required bool hidden,
    required String hiddenReason,
  }) => _db.saveInstalledPack(
    InstalledPacksCompanion(
      id: Value<String>(id),
      version: Value<String>(version),
      manifestSha256: Value<String>(manifestSha256),
      installedAt: Value<DateTime>(at),
      hidden: Value<bool>(hidden),
      hiddenReason: Value<String>(hiddenReason),
    ),
  );
}

enum InstallOutcome { installed, alreadyInstalled }

class InstallResult {
  const InstallResult(this.outcome, this.pack);

  final InstallOutcome outcome;
  final VerifiedPack pack;

  bool get hidden => pack.hidden;
}

/// Installs content packs. Everything about a pack is proven in memory first (`verifyPack`); nothing
/// touches the disk or the database until the signature, every hash and every content rule have passed.
///
/// On disk: `<root>/<pack id>/<version>/…`, written into a temporary folder and moved into place in
/// one step, then recorded in the registry. A crash at any point leaves the old pack or the new one,
/// never half of one; leftovers are removed by [sweep].
class PackInstaller {
  PackInstaller({
    required this.root,
    required this.registry,
    required this.publicKey,
    this.capabilities = AppCapabilities.current,
    this.decode = jsonDecode,
    Clock clock = const SystemClock(),
    Random? random,
  }) : _clock = clock,
       _random = random ?? Random.secure();

  /// The folder that holds all packs (inside the no-backup folder of the app).
  final Directory root;
  final PackRegistry registry;
  final Uint8List publicKey;
  final AppCapabilities capabilities;
  final JsonParse decode;
  final Clock _clock;
  final Random _random;

  Future<void> _queue = Future<void>.value();

  /// One install or load at a time.
  Future<T> _serial<T>(Future<T> Function() job) {
    final Future<T> result = _queue.then((_) => job());
    _queue = result.then((_) {}, onError: (Object _) {});
    return result;
  }

  Directory packDir(String id, String version) =>
      Directory('${root.path}${Platform.pathSeparator}$id${Platform.pathSeparator}$version');

  /// Verifies [bytes] and installs the pack. Throws [PackRejected] and changes nothing if any check fails.
  Future<InstallResult> install(Uint8List bytes) => _serial(() async {
    final VerifiedPack pack = await verifyPack(
      bytes,
      publicKey: publicKey,
      decode: decode,
      capabilities: capabilities,
    );
    final InstalledPack? existing = await registry.find(pack.id);
    if (existing != null) {
      final int order = compareSemver(pack.version, existing.version);
      if (order < 0) {
        throw PackRejected(
          'rules',
          'version ${pack.version} is older than the installed ${existing.version}',
        );
      }
      if (order == 0) {
        if (existing.manifestSha256 != pack.manifestSha256) {
          throw PackRejected(
            'rules',
            'version ${pack.version} is installed already, with different contents',
          );
        }
        if (packDir(pack.id, pack.version).existsSync()) {
          return InstallResult(InstallOutcome.alreadyInstalled, pack);
        }
        // The registry says installed but the folder is gone: fall through and write it again.
      }
    }

    root.createSync(recursive: true);
    final Directory incoming = Directory('${root.path}${Platform.pathSeparator}$_incomingPrefix${_token()}');
    final Directory target = packDir(pack.id, pack.version);
    try {
      incoming.createSync();
      void put(String name, List<int> data) =>
          File('${incoming.path}${Platform.pathSeparator}$name').writeAsBytesSync(data, flush: true);
      put(manifestName, pack.manifestBytes);
      put(signatureName, pack.signature);
      for (final MapEntry<String, Uint8List> f in pack.files.entries) {
        put(f.key, f.value);
      }
      target.parent.createSync(recursive: true);
      if (target.existsSync()) {
        target.deleteSync(recursive: true); // a leftover that no registry row points at
      }
      incoming.renameSync(target.path);
    } catch (_) {
      _deleteQuietly(incoming);
      rethrow;
    }

    try {
      await registry.save(
        id: pack.id,
        version: pack.version,
        manifestSha256: pack.manifestSha256,
        at: DateTime.fromMillisecondsSinceEpoch(_clock.nowMs(), isUtc: true),
        hidden: pack.hidden,
        hiddenReason: pack.hiddenReason ?? '',
      );
    } catch (_) {
      // The new files are not recorded: remove them so the old pack (if any) is all there is.
      if (existing == null || existing.version != pack.version) {
        _deleteQuietly(target);
        final Directory idDir = target.parent;
        if (idDir.existsSync() && idDir.listSync().isEmpty) _deleteQuietly(idDir);
      }
      rethrow;
    }
    _removeOtherVersions(pack.id, keep: pack.version);
    return InstallResult(InstallOutcome.installed, pack);
  });

  /// Reads an installed pack back from disk and proves it again, as if it had just arrived. A file
  /// that changed on disk makes this throw [PackRejected]. Returns null if no such pack is installed.
  /// A pack stored hidden becomes playable here once this app can play it (after an app update).
  Future<VerifiedPack?> load(String id) => _serial(() async {
    final InstalledPack? row = await registry.find(id);
    if (row == null) return null;
    final Directory dir = packDir(id, row.version);
    if (!dir.existsSync()) throw const PackRejected('disk', 'the files of the installed pack are missing');
    final Map<String, Uint8List> entries = <String, Uint8List>{};
    for (final FileSystemEntity e in dir.listSync(followLinks: false)) {
      if (e is! File) {
        throw const PackRejected('disk', 'the installed pack holds something that is not a file');
      }
      entries[e.uri.pathSegments.last] = e.readAsBytesSync();
    }
    final VerifiedPack pack = await verifyEntries(
      entries,
      publicKey: publicKey,
      decode: decode,
      capabilities: capabilities,
    );
    if (pack.manifestSha256 != row.manifestSha256 || pack.version != row.version || pack.id != row.id) {
      throw const PackRejected('disk', 'the installed pack is not the one that was recorded');
    }
    if (pack.hidden != row.hidden) {
      await registry.save(
        id: row.id,
        version: row.version,
        manifestSha256: row.manifestSha256,
        at: row.installedAt,
        hidden: pack.hidden,
        hiddenReason: pack.hiddenReason ?? '',
      );
    }
    return pack;
  });

  /// Removes what an interrupted install left behind: temporary folders, versions the registry does
  /// not point at, and folders of packs that are not installed.
  Future<void> sweep() => _serial(() async {
    if (!root.existsSync()) return;
    final Map<String, String> current = <String, String>{
      for (final InstalledPack p in await registry.all()) p.id: p.version,
    };
    for (final FileSystemEntity e in root.listSync(followLinks: false)) {
      final String name = e.uri.pathSegments.where((String s) => s.isNotEmpty).last;
      if (name.startsWith(_incomingPrefix) || !current.containsKey(name)) {
        _deleteQuietly(e);
        continue;
      }
      _removeOtherVersions(name, keep: current[name]!);
    }
  });

  void _removeOtherVersions(String id, {required String keep}) {
    final Directory idDir = Directory('${root.path}${Platform.pathSeparator}$id');
    if (!idDir.existsSync()) return;
    for (final FileSystemEntity e in idDir.listSync(followLinks: false)) {
      if (e.uri.pathSegments.where((String s) => s.isNotEmpty).last != keep) _deleteQuietly(e);
    }
  }

  static const String _incomingPrefix = '.incoming-';

  String _token() =>
      <String>[for (int i = 0; i < 8; i++) _random.nextInt(256).toRadixString(16).padLeft(2, '0')].join();

  void _deleteQuietly(FileSystemEntity e) {
    try {
      if (e.existsSync()) e.deleteSync(recursive: true);
    } on FileSystemException {
      // Left for the next sweep.
    }
  }
}
