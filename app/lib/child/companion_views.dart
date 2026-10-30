import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/companion.dart';
import '../app/reward_providers.dart';
import '../characters/character.dart';
import '../characters/character_view.dart';
import '../rewards/outfits.dart';
import '../voice/voice_director.dart';

/// A character that talks when the voice director says its line is playing and rests in [resting] otherwise.
/// It asks for no one in particular: [character] is whoever the resolver chose for the role.
class SpeakingCharacter extends StatelessWidget {
  const SpeakingCharacter({
    super.key,
    required this.character,
    required this.director,
    this.resting = CharacterState.idle,
    this.voiceOf,
    this.outfit,
  });

  final Character character;
  final VoiceDirector director;
  final CharacterState resting;

  /// The prize the character wears, or null.
  final Outfit? outfit;

  /// The id of the character whose voice the director uses now. The mouth moves only when it is this one.
  final String? voiceOf;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: director,
    builder: (BuildContext context, Widget? _) {
      final bool talks = director.speaking && (voiceOf == null || voiceOf == character.id);
      return CharacterView(
        character: character,
        state: talks ? CharacterState.talk : resting,
        mouthOpen: talks && director.mouthOpen,
        outfit: outfit,
      );
    },
  );
}

/// The companion on the world map: it breathes, and when touched it waves and says hello in its own voice. In the child's
/// home (B-26) it also waves once when it appears, and silently ([greetingVoice] null: nothing is voiced there yet).
class MapCompanion extends ConsumerStatefulWidget {
  const MapCompanion({super.key, this.greetingVoice, this.waveOnStart = false});

  /// The voice line (`vo:...`) it says when touched, or null for a wave without a word.
  final String? greetingVoice;

  /// Waves once as soon as it appears.
  final bool waveOnStart;

  @override
  ConsumerState<MapCompanion> createState() => MapCompanionState();
}

class MapCompanionState extends ConsumerState<MapCompanion> with SingleTickerProviderStateMixin {
  bool _waving = false;
  late final VoiceDirector _director;

  /// How long one wave holds the waving picture, also with reduce motion on (a picture, not a movement). A controller
  /// rather than a delayed future, so it stops with the widget and a screen settles once the wave is over.
  late final AnimationController _wave =
      AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1600),
        animationBehavior: AnimationBehavior.preserve,
      )..addStatusListener((AnimationStatus s) {
        if (s == AnimationStatus.completed && mounted) setState(() => _waving = false);
      });

  /// Waves and greets.
  void greet() {
    _wave.forward(from: 0);
    setState(() => _waving = true);
    final String? voice = widget.greetingVoice;
    if (voice != null) unawaited(_director.say(voice));
  }

  @override
  void initState() {
    super.initState();
    _director = ref.read(voiceDirectorProvider);
    if (widget.waveOnStart) {
      _waving = true;
      _wave.forward();
    }
  }

  @override
  void dispose() {
    _wave.dispose();
    unawaited(_director.stop());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<Character> character = ref.watch(characterForRoleProvider(CharacterRole.mapCompanion));
    final AsyncValue<Guide> guide = ref.watch(guideProvider);
    final Character? c = character.value;
    if (c == null) return const SizedBox.shrink();
    return SpeakingCharacter(
      character: c,
      director: _director,
      resting: _waving ? CharacterState.wave : CharacterState.idle,
      voiceOf: guide.value?.character.id,
      outfit: wornOutfit(ref.watch(outfitProvider)),
    );
  }
}
