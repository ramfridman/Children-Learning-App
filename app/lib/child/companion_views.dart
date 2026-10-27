import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/companion.dart';
import '../characters/character.dart';
import '../characters/character_view.dart';
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
  });

  final Character character;
  final VoiceDirector director;
  final CharacterState resting;

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
      );
    },
  );
}

/// The companion on the world map: it breathes, and when touched it waves and says hello in its own voice.
class MapCompanion extends ConsumerStatefulWidget {
  const MapCompanion({super.key, required this.greetingVoice});

  /// The voice line (`vo:...`) it says when touched.
  final String greetingVoice;

  @override
  ConsumerState<MapCompanion> createState() => MapCompanionState();
}

class MapCompanionState extends ConsumerState<MapCompanion> {
  int _waveId = 0;
  bool _waving = false;
  late final VoiceDirector _director;

  /// Waves and greets.
  void greet() {
    final int id = ++_waveId;
    setState(() => _waving = true);
    unawaited(_director.say(widget.greetingVoice));
    unawaited(
      Future<void>.delayed(const Duration(milliseconds: 1600)).then((_) {
        if (mounted && id == _waveId) setState(() => _waving = false);
      }),
    );
  }

  @override
  void initState() {
    super.initState();
    _director = ref.read(voiceDirectorProvider);
  }

  @override
  void dispose() {
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
    );
  }
}
