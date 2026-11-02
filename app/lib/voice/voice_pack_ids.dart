// The names of the voice packs of one character, shared by the app (which finds them) and the voice tool (which builds them).
//
// A character's voice is one pack or several (B-45: a narrator says about 4,000 lines, far more than one pack may hold).
// The first holds the shared lines and has the plain id `voice-<character>`; the others are `voice-<character>-part-<group>`
// (`voice-nitzi-part-num-b-1`). A friend, who says only a handful of lines, keeps the one plain pack.

const String voicePackPrefix = 'voice-';
const String _partMarker = '-part-';

/// The pack id of [characterId]'s voice pack for [group]: the plain `voice-<character>` when [group] is null.
String voicePackId(String characterId, [String? group]) =>
    group == null ? '$voicePackPrefix$characterId' : '$voicePackPrefix$characterId$_partMarker$group';

/// Whether [packId] is one of the voice packs of [characterId]. A character whose own id holds the part marker would be
/// read as the part of another character, so the tool refuses such a character ([voicePackId] is only built for the
/// others, and `voice_packs_test.dart` checks the real ones).
bool isVoicePackOf(String characterId, String packId) =>
    packId == voicePackId(characterId) || packId.startsWith('$voicePackPrefix$characterId$_partMarker');

/// The character whose voice [packId] holds (the id itself when it is not a voice pack id).
String characterOfVoicePack(String packId) {
  if (!packId.startsWith(voicePackPrefix)) return packId;
  final String rest = packId.substring(voicePackPrefix.length);
  final int part = rest.indexOf(_partMarker);
  return part < 0 ? rest : rest.substring(0, part);
}

/// Whether [characterId] can be told apart from a part of another character's voice.
bool hasPlainVoiceId(String characterId) => !characterId.contains(_partMarker);
