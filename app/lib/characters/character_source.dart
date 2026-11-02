import 'dart:typed_data';

import '../content/capabilities.dart' show compareSemver;
import '../content/pack_installer.dart';
import '../content/pack_verify.dart';
import '../data/app_database.dart';
import '../voice/voice_bank.dart';
import '../voice/voice_pack_ids.dart';
import 'character.dart';
import 'resolver.dart';

/// Where the characters and their voices come from. The app reads installed packs; tests give a fixed set.
abstract interface class CharacterSource {
  /// Every character that may be shown now, with the house character (Nitzi) as the last resort.
  Future<CharacterResolver> resolver();

  /// The recorded lines of a character's voice (an empty bank if it has no voice pack).
  Future<VoiceBank> voice(String characterId);
}

/// Reads the characters from the packs installed on this phone. Nitzi ships inside the app and goes through
/// the same checks as any pack; every other character is a signed personal pack that was installed on this phone.
/// A pack that fails its checks is left out, never shown.
class InstalledCharacterSource implements CharacterSource {
  InstalledCharacterSource({
    required this.installer,
    required this.bundledHouse,
    this.housePackId = 'char-nitzi',
  });

  final PackInstaller installer;

  /// The bytes of the pack file of the house character that is part of the app.
  final Future<Uint8List> Function() bundledHouse;
  final String housePackId;

  @override
  Future<CharacterResolver> resolver() async {
    try {
      await installer.install(await bundledHouse());
    } on PackRejected catch (e) {
      // "rules": a copy that is the same or newer is installed already, and that copy is the one to use.
      if (e.stage != 'rules') rethrow;
    }
    final List<Character> found = <Character>[];
    for (final InstalledPack row in await installer.registry.all()) {
      if (!row.id.startsWith('char-') || row.hidden) continue;
      try {
        final VerifiedPack? pack = await installer.load(row.id);
        if (pack == null || pack.hidden) continue;
        found.add(Character.fromPack(pack));
      } on PackRejected {
        continue;
      }
    }
    final Iterable<Character> house = found.where((Character c) => c.packId == housePackId);
    if (house.isEmpty) throw StateError('the house character is not available');
    return CharacterResolver(available: found, house: house.first);
  }

  /// The voice of [characterId]: all the voice packs installed for it (one for a friend, about sixteen for a narrator) as one
  /// bank that reads them lazily. Only the manifests are read here, to know which pack holds which line, and the shared
  /// lines (the plain `voice-<character>` pack) are loaded; every other pack is loaded, and proven again, when one of its
  /// lines is first wanted (see [LazyVoicePacks]). A pack that fails its checks or that this app cannot play is left out
  /// then, and its lines are silent (or the narrator's).
  @override
  Future<VoiceBank> voice(String characterId) async {
    final List<InstalledPack> rows =
        <InstalledPack>[
          for (final InstalledPack row in await installer.registry.all())
            if (isVoicePackOf(characterId, row.id)) row,
        ]..sort((InstalledPack a, InstalledPack b) {
          final int newer = compareSemver(b.version, a.version);
          return newer != 0 ? newer : a.id.compareTo(b.id);
        });
    // The tool builds all the packs of a voice with one version. A part of another version is left over from an earlier layout
    // (dropped or renamed since, its lines perhaps pulled for their wording), so it is not heard: the version of the shared pack
    // counts, or the newest one when the shared pack is not installed.
    final String? voiceVersion = rows.isEmpty
        ? null
        : rows
              .firstWhere((InstalledPack r) => r.id == voicePackId(characterId), orElse: () => rows.first)
              .version;
    final Map<String, String> index = <String, String>{};
    for (final InstalledPack row in rows) {
      if (row.version != voiceVersion) continue;
      final Map<String, Object?>? manifest = await installer.installedManifest(row.id);
      if (manifest == null) continue;
      for (final Object? v in manifest['vo'] as List<Object?>? ?? const <Object?>[]) {
        if (v is Map<String, Object?> && v['id'] is String) index.putIfAbsent('vo:${v['id']}', () => row.id);
      }
    }
    if (index.isEmpty) return VoiceBank.empty(characterId);
    final LazyVoicePacks packs = LazyVoicePacks(
      index: index,
      pinned: <String>{voicePackId(characterId)},
      loader: (String packId) async {
        try {
          final VerifiedPack? pack = await installer.load(packId);
          return pack == null || pack.hidden ? null : pack;
        } on PackRejected catch (e) {
          // Files that are missing or not the ones recorded may be a moment's trouble; a failed check never passes.
          throw VoicePackUnavailable(permanent: e.stage != 'disk');
        }
      },
    );
    await packs.loadPinned();
    return VoiceBank.lazy(characterId, packs);
  }
}

/// A fixed set, for tests and previews.
class FixedCharacterSource implements CharacterSource {
  FixedCharacterSource({
    required this.characters,
    required this.house,
    this.voices = const <String, VoiceBank>{},
  });

  final List<Character> characters;
  final Character house;
  final Map<String, VoiceBank> voices;

  @override
  Future<CharacterResolver> resolver() async => CharacterResolver(available: characters, house: house);

  @override
  Future<VoiceBank> voice(String characterId) async => voices[characterId] ?? VoiceBank.empty(characterId);
}
