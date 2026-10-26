import 'dart:typed_data';

import '../content/pack_installer.dart';
import '../content/pack_verify.dart';
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

  @override
  Future<VoiceBank> voice(String characterId) async {
    try {
      final VerifiedPack? pack = await installer.load('voice-$characterId');
      if (pack == null || pack.hidden) return VoiceBank.empty(characterId);
      return VoiceBank.fromPack(pack);
    } on PackRejected {
      return VoiceBank.empty(characterId);
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
