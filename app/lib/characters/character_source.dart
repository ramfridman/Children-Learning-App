import 'dart:typed_data';

import '../content/bundled_packs.dart';
import '../content/capabilities.dart' show compareSemver;
import '../content/pack_installer.dart';
import '../content/pack_verify.dart';
import '../core/log.dart';
import '../data/app_database.dart';
import '../voice/voice_bank.dart';
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
    this.maxVoiceClipBytes = maxVoiceBytes,
    this.bundledVoices,
    this.readAsset,
  });

  final PackInstaller installer;

  /// The bytes of the pack file of the house character that is part of the app.
  final Future<Uint8List> Function() bundledHouse;
  final String housePackId;

  /// The most clip bytes one voice may hold across its parts (tests make it small).
  final int maxVoiceClipBytes;

  /// The voice packs that ship inside the app (the asset manifest, filtered: [BundledVoicePack.newestOf]) and how to read one
  /// file. Null for a source with no bundled voice.
  final Future<List<BundledVoicePack>> Function()? bundledVoices;
  final Future<Uint8List> Function(String asset)? readAsset;

  Future<void>? _bundledVoicesDone;

  /// The bundled voice packs installed through the verifying installer, once per run, before the first voice is read: one at a
  /// time, in the order of their ids, each only when this phone does not hold that version or a newer one already (the
  /// registry row is read first, so a phone that has them does no work), or when its folder is gone. A file the installer
  /// refuses (any stage, 'rules' included), or one that cannot be read, is left out and logged by stage; it never stops the
  /// others or the app. The voices are read here and not with the characters, so the first start does not wait for a hundred
  /// megabytes to be proven before the home island is shown.
  Future<void> _ensureBundledVoices() => _bundledVoicesDone ??= _installBundledVoices();

  Future<void> _installBundledVoices() async {
    final Future<List<BundledVoicePack>> Function()? list = bundledVoices;
    final Future<Uint8List> Function(String asset)? read = readAsset;
    if (list == null || read == null) return;
    final List<BundledVoicePack> packs;
    try {
      packs = await list();
    } on Object catch (e) {
      Log.d('bundled voices not listed: ${e.runtimeType}');
      return;
    }
    for (final BundledVoicePack v in packs) {
      try {
        final InstalledPack? row = await installer.registry.find(v.packId);
        if (row != null &&
            compareSemver(row.version, v.version) >= 0 &&
            installer.packDir(v.packId, row.version).existsSync()) {
          continue;
        }
        await installer.install(await read(v.asset));
      } on PackRejected catch (e) {
        Log.d('bundled voice ${v.packId} refused at ${e.stage}');
      } on Object catch (e) {
        Log.d('bundled voice ${v.packId} not installed: ${e.runtimeType}');
      }
    }
  }

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

  /// The voice of a character: `voice-<id>` and any `voice-<id>-N` (N from 2 to 9) that are installed, each proven again on
  /// its own as any pack is, and joined into one bank. The first part read sets the version of the build: a part of
  /// another version is left out (SEC-VP-3), and so is a part that would take the voice over [maxVoiceClipBytes]
  /// (SEC-VP-4), one that is not installed, is hidden, fails its checks, or has a line that is in an earlier part: those
  /// lines are text only, never an error. The parts are read one after the other and each one's files are let go as soon
  /// as its clips are in the bank, so no two parts are held whole at once.
  @override
  Future<VoiceBank> voice(String characterId) async {
    await _ensureBundledVoices();
    VoiceBank bank = VoiceBank.empty(characterId);
    String? version;
    for (int part = 1; part <= lastVoicePart; part++) {
      if (part > 1 && await _isAnotherVoice(characterId, part)) continue;
      final ({VoiceBank bank, String version})? loaded = await _loadVoicePart(voicePackId(characterId, part));
      if (loaded == null) continue;
      if (version != null && loaded.version != version) continue;
      if (bank.clipBytes + loaded.bank.clipBytes > maxVoiceClipBytes) continue;
      try {
        bank = bank.withPart(loaded.bank);
        version ??= loaded.version;
      } on PackRejected {
        continue;
      }
    }
    return bank;
  }

  /// `voice-<id>-N` is the voice of the character `<id>-N` when there is one: it is not a part of `<id>`. A character id
  /// never ends in `-2` to `-9` (the character schema), so this is a second layer.
  Future<bool> _isAnotherVoice(String characterId, int part) async =>
      await installer.registry.find('char-$characterId-$part') != null;

  Future<({VoiceBank bank, String version})?> _loadVoicePart(String packId) async {
    try {
      final VerifiedPack? pack = await installer.load(packId);
      if (pack == null || pack.hidden) return null;
      return (bank: VoiceBank.fromPack(pack), version: pack.version);
    } on PackRejected {
      return null;
    }
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
