import 'dart:typed_data';

import '../characters/lip_sync.dart';
import '../content/capabilities.dart';
import '../content/pack_verify.dart';
import 'voice_pack_ids.dart';

/// One recorded line: the sound and when the mouth is open in it.
class VoiceClip {
  const VoiceClip(this.mp3, this.mouth, {this.mime = 'audio/mpeg'});

  final Uint8List mp3;
  final String mime;
  final MouthTrack mouth;
}

/// The recorded lines of one character's voice packs, by `vo:` id. A line with no recording is simply absent.
class VoiceBank {
  VoiceBank._(this.characterId, this._clips) : fallback = null;

  /// Reads one verified voice pack (`voice-<character id>`): the audio files of its manifest and its cue documents.
  factory VoiceBank.fromPack(VerifiedPack pack) =>
      VoiceBank.fromPacks(characterOfVoicePack(pack.id), <VerifiedPack>[pack]);

  /// Reads all the verified voice packs of [characterId] into one bank, so a line is found whichever pack holds it. If
  /// two packs hold the same line (a pack of an older layout left behind), the newer pack's clip is used, and between
  /// equal versions the pack that comes first by id: always the same one.
  factory VoiceBank.fromPacks(String characterId, Iterable<VerifiedPack> packs) {
    final List<VerifiedPack> ordered = packs.toList()
      ..sort((VerifiedPack a, VerifiedPack b) {
        final int newer = compareSemver(b.version, a.version);
        return newer != 0 ? newer : a.id.compareTo(b.id);
      });
    final Map<String, VoiceClip> clips = <String, VoiceClip>{};
    for (final VerifiedPack pack in ordered) {
      for (final Object? v in pack.manifest['vo']! as List<Object?>) {
        final Map<String, Object?> entry = v! as Map<String, Object?>;
        final String id = entry['id']! as String;
        if (clips.containsKey('vo:$id')) continue;
        final String file = entry['file']! as String;
        final Uint8List? mp3 = pack.files[file];
        if (mp3 == null) continue;
        final Object? cue = pack.docs['cue.$id.json'];
        final List<Object?> cues = cue is Map<String, Object?>
            ? (cue['cues'] as List<Object?>? ?? const <Object?>[])
            : const <Object?>[];
        clips['vo:$id'] = VoiceClip(
          mp3,
          MouthTrack.fromJson(cues),
          mime: file.endsWith('.wav') ? 'audio/wav' : 'audio/mpeg',
        );
      }
    }
    return VoiceBank._(characterId, clips);
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

  bool has(String voId) => _clips.containsKey(voId) || (fallback?.has(voId) ?? false);

  VoiceClip? clip(String voId) => _clips[voId] ?? fallback?.clip(voId);
}
