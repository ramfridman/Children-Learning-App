import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show FutureProviderFamily;

import '../characters/character.dart';
import '../characters/character_source.dart';
import '../characters/resolver.dart';
import '../content/bundled_packs.dart';
import '../content/pack_installer.dart';
import '../content/pack_verify.dart' show PackRejected;
import '../data/app_database.dart';
import '../engine/course.dart';
import '../voice/voice_bank.dart';
import '../voice/voice_director.dart';
import '../voice/voice_player.dart';
import 'language_providers.dart' show BundledAssets, bundledAssetsProvider;
import 'state.dart';

/// Where characters and voices come from: the packs installed on this phone, Nitzi first.
final FutureProvider<CharacterSource> characterSourceProvider = FutureProvider<CharacterSource>((
  Ref ref,
) async {
  final PackInstaller installer = await ref.watch(packInstallerProvider.future);
  final BundledAssets assets = ref.watch(bundledAssetsProvider);
  return InstalledCharacterSource(
    installer: installer,
    bundledHouse: () async =>
        (await rootBundle.load('assets/characters/char-nitzi-1.0.0.nnpack')).buffer.asUint8List(),
    bundledVoices: () async => BundledVoicePack.newestOf(await assets.list()),
    readAsset: assets.read,
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
  final VoiceBank own = await source.voice(c.id);
  // The narrator speaks the lines a friend has no recording of (the lessons); the friend keeps its own greetings and cheers.
  // The recordings of the language courses (`voice-lang-<course>`) are the last resort for every guide: their lines (`vo:eng.…`)
  // are in no character's voice, and a course plays them in the voice the teacher chose for it.
  final VoiceBank languages = await languageVoices(source);
  final String narrator = narratorFor(c);
  final VoiceBank spoken = c.id == narrator
      ? languages
      : VoiceBank.withFallback(await source.voice(narrator), languages);
  return Guide(c, VoiceBank.withFallback(own, spoken));
});

/// The recordings of the language courses, joined in one bank (a course that has none installed adds nothing). The ids of
/// one course begin with its code, so no two courses share a line.
Future<VoiceBank> languageVoices(CharacterSource source) async {
  VoiceBank bank = VoiceBank.empty('languages');
  for (final String course in Course.languages) {
    try {
      bank = bank.withPart(await source.voice('lang-$course'));
    } on PackRejected {
      continue;
    }
  }
  return bank;
}

/// The two characters whose voices say every line of the lessons: Nitzi for a friend with a girl's voice, Hero-son for a friend
/// with a boy's voice, so a borrowed line never comes in the voice of the other gender. A friend's grammar in Hebrew
/// (a jelly is a masculine word) says nothing about its voice, so the choice follows the voice each friend has.
const String narratorFemaleId = 'nitzi';
const String narratorMaleId = 'hero-son';

const Map<String, String> _narratorOf = <String, String>{
  'nitzi': narratorFemaleId,
  'alien-jili': narratorFemaleId,
  'compass-romi': narratorFemaleId,
  'friend-daughter': narratorFemaleId,
  'inventor-gali': narratorFemaleId,
  'weaver-keshet': narratorFemaleId,
  'hero-son': narratorMaleId,
  'climber-tzuri': narratorMaleId,
  'tower-tamir': narratorMaleId,
};

/// The narrator for [c]: by the friend's id, and for a character that is not listed (a new family character) by its gender.
String narratorFor(Character c) => _narratorOf[c.id] ?? (c.gender == 'm' ? narratorMaleId : narratorFemaleId);

final Provider<VoicePlayer> voicePlayerProvider = Provider<VoicePlayer>(
  (Ref ref) => AudioPlayersVoicePlayer(),
);

/// The one speaker of the app. It always uses the voice of the guide, so changing the companion changes the voice
/// on every screen at once.
final Provider<VoiceDirector> voiceDirectorProvider = Provider<VoiceDirector>((Ref ref) {
  final VoiceDirector director = VoiceDirector(
    player: ref.watch(voicePlayerProvider),
    gap: const Duration(milliseconds: 250),
  );
  ref.onDispose(director.dispose);
  ref.listen<AsyncValue<Guide>>(
    guideProvider,
    (AsyncValue<Guide>? _, AsyncValue<Guide> next) => director.useBank(next.value?.bank),
    fireImmediately: true,
  );
  return director;
});
