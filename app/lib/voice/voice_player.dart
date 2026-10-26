import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';

/// Plays one spoken line at a time. A small interface so that tests can use a fake that knows exactly what played.
abstract interface class VoicePlayer {
  /// Starts playing [mp3], replacing whatever was playing.
  Future<void> play(Uint8List mp3);

  /// How far into the line the sound is now, or null if nothing is playing.
  Future<Duration?> position();

  /// Fires when the line has played to its end (not when it was stopped).
  Stream<void> get completed;

  Future<void> stop();

  Future<void> dispose();
}

/// The real player, from the `audioplayers` package: plays the verified bytes of a voice pack from memory.
class AudioPlayersVoicePlayer implements VoicePlayer {
  AudioPlayersVoicePlayer() : _player = AudioPlayer() {
    _player.setReleaseMode(ReleaseMode.stop);
  }

  final AudioPlayer _player;

  @override
  Future<void> play(Uint8List mp3) => _player.play(BytesSource(mp3, mimeType: 'audio/mpeg'));

  @override
  Future<Duration?> position() => _player.getCurrentPosition();

  @override
  Stream<void> get completed => _player.onPlayerComplete;

  @override
  Future<void> stop() => _player.stop();

  @override
  Future<void> dispose() => _player.dispose();
}
