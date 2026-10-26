import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show FutureProviderFamily;

import '../characters/character.dart';
import '../characters/character_source.dart';
import '../characters/resolver.dart';
import '../content/pack_installer.dart';
import '../data/app_database.dart';
import '../voice/voice_bank.dart';
import '../voice/voice_director.dart';
import '../voice/voice_player.dart';
import 'state.dart';

/// Where characters and voices come from: the packs installed on this phone, Nitzi first.
final FutureProvider<CharacterSource> characterSourceProvider = FutureProvider<CharacterSource>((
  Ref ref,
) async {
  final PackInstaller installer = await ref.watch(packInstallerProvider.future);
  return InstalledCharacterSource(
    installer: installer,
    bundledHouse: () async =>
        (await rootBundle.load('assets/characters/char-nitzi-1.0.0.nnpack')).buffer.asUint8List(),
  );
});

/// Every character that can be shown. Invalidate it after a character pack is installed or removed.
final FutureProvider<CharacterResolver> resolverProvider = FutureProvider<CharacterResolver>(
  (Ref ref) async => (await ref.watch(characterSourceProvider.future)).resolver(),
);

/// The companion the playing child chose (a character id), or null for the house character. Changing it is
/// written to the database, and every screen that asks for a role follows.
class CompanionNotifier extends AsyncNotifier<String?> {
  @override
  Future<String?> build() async {
    final Profile? child = ref.watch(activeProfileProvider);
    if (child == null) return null;
    final AppDatabase db = await ref.watch(databaseProvider.future);
    return db.companionOf(child.id);
  }

  Future<void> choose(String? characterId) async {
    final Profile? child = ref.read(activeProfileProvider);
    if (child == null) return;
    final AppDatabase db = await ref.read(databaseProvider.future);
    await db.setCompanion(child.id, characterId);
    state = AsyncData<String?>(characterId);
  }
}

final AsyncNotifierProvider<CompanionNotifier, String?> companionProvider =
    AsyncNotifierProvider<CompanionNotifier, String?>(CompanionNotifier.new);

/// Whoever plays [role] for the playing child: the companion if it may, else the house character.
final FutureProviderFamily<Character, CharacterRole> characterForRoleProvider =
    FutureProvider.family<Character, CharacterRole>((Ref ref, CharacterRole role) async {
      final CharacterResolver resolver = await ref.watch(resolverProvider.future);
      final String? companion = await ref.watch(companionProvider.future);
      return resolver.resolve(role, companionId: companion);
    });

/// A character with its voice, ready to teach.
class Guide {
  const Guide(this.character, this.bank);

  final Character character;
  final VoiceBank bank;
}

/// The guide of the playing child: the character that teaches, and the bank of its voice.
final FutureProvider<Guide> guideProvider = FutureProvider<Guide>((Ref ref) async {
  final Character c = await ref.watch(characterForRoleProvider(CharacterRole.guideTutor).future);
  final CharacterSource source = await ref.watch(characterSourceProvider.future);
  return Guide(c, await source.voice(c.id));
});

final Provider<VoicePlayer> voicePlayerProvider = Provider<VoicePlayer>(
  (Ref ref) => AudioPlayersVoicePlayer(),
);

/// The one speaker of the app. It always uses the voice of the guide, so changing the companion changes the voice
/// on every screen at once.
final Provider<VoiceDirector> voiceDirectorProvider = Provider<VoiceDirector>((Ref ref) {
  final VoiceDirector director = VoiceDirector(player: ref.watch(voicePlayerProvider));
  ref.onDispose(director.dispose);
  ref.listen<AsyncValue<Guide>>(
    guideProvider,
    (AsyncValue<Guide>? _, AsyncValue<Guide> next) => director.useBank(next.value?.bank),
    fireImmediately: true,
  );
  return director;
});
