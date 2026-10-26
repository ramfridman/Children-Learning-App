import 'dart:typed_data';

import '../characters/lip_sync.dart';
import '../content/pack_verify.dart';

/// One recorded line: the sound and when the mouth is open in it.
class VoiceClip {
  const VoiceClip(this.mp3, this.mouth);

  final Uint8List mp3;
  final MouthTrack mouth;
}

/// The recorded lines of one character's voice pack, by `vo:` id. A line with no recording is simply absent.
class VoiceBank {
  VoiceBank._(this.characterId, this._clips);

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
      clips['vo:$id'] = VoiceClip(mp3, MouthTrack.fromJson(cues));
    }
    return VoiceBank._(pack.id.startsWith('voice-') ? pack.id.substring('voice-'.length) : pack.id, clips);
  }

  /// A bank with no recordings (a character that has no voice pack yet).
  VoiceBank.empty(this.characterId) : _clips = const <String, VoiceClip>{};

  final String characterId;
  final Map<String, VoiceClip> _clips;

  int get length => _clips.length;

  Iterable<String> get ids => _clips.keys;

  bool has(String voId) => _clips.containsKey(voId);

  VoiceClip? clip(String voId) => _clips[voId];
}
