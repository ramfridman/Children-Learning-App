import 'dart:typed_data';

import '../characters/lip_sync.dart';
import '../content/pack_verify.dart';

/// One recorded line: the sound and when the mouth is open in it.
class VoiceClip {
  const VoiceClip(this.mp3, this.mouth, {this.mime = 'audio/mpeg'});

  final Uint8List mp3;
  final String mime;
  final MouthTrack mouth;
}

/// The last part of a voice (`voice-<id>-9`): a voice is at most nine packs, so a pack named with a number outside 2 to 9
/// is never read as a part of anything.
const int lastVoicePart = 9;

/// The id of part [part] (1 to [lastVoicePart]) of the voice of [characterId]: `voice-<id>` for the first, `voice-<id>-N`
/// for the others. The only place that makes these ids, for the app that reads them and the tool that builds them.
String voicePackId(String characterId, int part) {
  if (part < 1 || part > lastVoicePart) throw RangeError.range(part, 1, lastVoicePart, 'part');
  return part == 1 ? 'voice-$characterId' : 'voice-$characterId-$part';
}

/// The recorded lines of one character's voice pack, by `vo:` id. A line with no recording is simply absent.
class VoiceBank {
  VoiceBank._(this.characterId, this._clips) : fallback = null;

  /// Reads a verified voice pack (`voice-<character id>`): the audio files of its manifest and its cue documents.
  factory VoiceBank.fromPack(VerifiedPack pack) {
    final Map<String, VoiceClip> clips = <String, VoiceClip>{};
    for (final Object? v in pack.manifest['vo']! as List<Object?>) {
      final Map<String, Object?> entry = v! as Map<String, Object?>;
      final String id = entry['id']! as String;
      final Uint8List? mp3 = pack.files[entry['file']! as String];
      if (mp3 == null) continue;
      final Object? cue = pack.docs['cue.$id.json'];
      final List<Object?> cues = cue is Map<String, Object?>
          ? (cue['cues'] as List<Object?>? ?? const <Object?>[])
          : const <Object?>[];
      final String file = entry['file']! as String;
      clips['vo:$id'] = VoiceClip(
        mp3,
        MouthTrack.fromJson(cues),
        mime: file.endsWith('.wav') ? 'audio/wav' : 'audio/mpeg',
      );
    }
    return VoiceBank._(pack.id.startsWith('voice-') ? pack.id.substring('voice-'.length) : pack.id, clips);
  }

  /// A bank with no recordings (a character that has no voice pack yet).
  VoiceBank.empty(this.characterId) : _clips = const <String, VoiceClip>{}, fallback = null;

  /// [primary] with the narrator behind it: a line that [primary] has no recording of is said by [fallback]'s voice, so a
  /// friend with only its own greetings and cheers still teaches aloud (M9, Q5: the flagship voices say every line).
  VoiceBank.withFallback(VoiceBank primary, VoiceBank this.fallback)
    : characterId = primary.characterId,
      _clips = primary._clips;

  final String characterId;
  final Map<String, VoiceClip> _clips;

  /// The narrator's bank, for the lines this voice does not have; null for a bank that stands alone.
  final VoiceBank? fallback;

  int get length => _clips.length;

  Iterable<String> get ids => _clips.keys;

  /// This bank with the lines of [part] added: the voice of one character is in several packs when it is more than one
  /// pack may hold ([voicePackId]). A line that is in both is refused, so a pack can never replace the recording of a
  /// line in another pack. The clips are shared, not copied.
  VoiceBank withPart(VoiceBank part) {
    for (final String id in part._clips.keys) {
      if (_clips.containsKey(id)) {
        throw PackRejected('rules', 'the voice line "$id" is in two packs of the voice of $characterId');
      }
    }
    return VoiceBank._(characterId, <String, VoiceClip>{..._clips, ...part._clips});
  }

  bool has(String voId) => _clips.containsKey(voId) || (fallback?.has(voId) ?? false);

  VoiceClip? clip(String voId) => _clips[voId] ?? fallback?.clip(voId);
}
