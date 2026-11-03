import 'dart:convert';
import 'dart:typed_data';

import '../content/pack_verify.dart' show sha256Hex;
import '../core/errors.dart';
import '../data/app_database.dart';
import '../world/welcome_lines.dart' show mayFollowNameClip;
import 'voice_director.dart';

// The sound of a child's name (B-42, docs/milestones/B42.md section 3): made by the gateway from the spelling a parent
// checked, kept on this device in the encrypted database (keyed by child, character and a hash of the spelling), and played
// right before a greeting of the welcome or the map bubble's shared clip, and nowhere else.

/// The first 16 hex characters of the SHA-256 of [spelling]: what a clip is keyed by, so that a clip made from another
/// spelling is never used.
String spellingHash(String spelling) => sha256Hex(utf8.encode(spelling)).substring(0, 16);

/// The sound of the child's name in [characterId]'s voice, or null when there is none: no spelling, no clip yet, or a clip of
/// another friend or spelling. The clips that are no longer the child's own are deleted on the way.
Future<Uint8List?> nameClipFor(AppDatabase db, String profileId, String characterId) async {
  final String? spelling = await db.nameSpokenOf(profileId);
  if (spelling == null) {
    await db.deleteNameClips(profileId);
    return null;
  }
  final String hash = spellingHash(spelling);
  final Uint8List? sound = await db.nameClipOf(profileId, characterId, hash);
  if (sound == null) await db.pruneNameClips(profileId, characterId: characterId, spellingHash: hash);
  return sound;
}

/// Says [name], then [voId], one after the other. Only a greeting of the welcome or the shared clip of the map bubble may
/// follow a name clip ([mayFollowNameClip]): the name is heard once, as a call, and never in the middle of anything else.
Future<void> sayWithName(VoiceDirector director, Uint8List name, String voId, {Object? owner}) async {
  if (!mayFollowNameClip(voId)) {
    throw ArgumentError.value(voId, 'voId', 'only a greeting or the map bubble follows a name clip');
  }
  await director.sayBytes(name, owner: owner);
  await director.sayNext(voId, owner: owner);
}

/// Why the gateway could not make a name clip.
enum NameVoiceFailure {
  /// The switch on the server is off, or the voice is not set up there.
  off,

  /// The family has made today's clips already.
  cap,

  /// The server has no spelling for this child yet (it has not been sent), or no such child or character.
  notThere,

  /// The server could not be reached, or did not answer with a sound.
  unreachable,
}

class NameVoiceException implements Exception {
  const NameVoiceException(this.failure);

  final NameVoiceFailure failure;

  @override
  String toString() => 'NameVoiceException($failure)';
}

/// Asks for the sound of a child's name. The only implementation that reaches the network is [GatewayNameVoice]; tests give
/// their own.
abstract interface class NameVoice {
  /// The mp3 of the name of [childId] in the voice of [characterId]. Throws [NameVoiceException].
  Future<Uint8List> make({required String childId, required String characterId});
}

/// `name-voice` on the gateway: the phone sends two ids; the server holds the spelling and the voice.
class GatewayNameVoice implements NameVoice {
  GatewayNameVoice(this._call);

  final Future<Map<String, Object?>> Function(String name, Map<String, Object?> body) _call;

  /// A clip of a name is a few kilobytes; anything far outside that is not one.
  static const int _smallest = 100;
  static const int _largest = 400 * 1024;

  @override
  Future<Uint8List> make({required String childId, required String characterId}) async {
    final Map<String, Object?> answer;
    try {
      answer = await _call('name-voice', <String, Object?>{'child_id': childId, 'character_id': characterId});
    } on GatewayException catch (e) {
      throw NameVoiceException(switch (e.code) {
        'unavailable' => NameVoiceFailure.off,
        'rate_limited' => NameVoiceFailure.cap,
        'bad_request' || 'not_found' => NameVoiceFailure.notThere,
        _ => NameVoiceFailure.unreachable,
      });
    } on Object {
      throw const NameVoiceException(NameVoiceFailure.unreachable);
    }
    final Object? audio = answer['audio'];
    if (audio is! String || answer['mime'] != 'audio/mpeg') {
      throw const NameVoiceException(NameVoiceFailure.unreachable);
    }
    try {
      final Uint8List sound = base64Decode(audio);
      if (sound.length < _smallest || sound.length > _largest) {
        throw const NameVoiceException(NameVoiceFailure.unreachable);
      }
      return sound;
    } on FormatException {
      throw const NameVoiceException(NameVoiceFailure.unreachable);
    }
  }
}
