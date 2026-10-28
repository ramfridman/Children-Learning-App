import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:nitznutz/voice/voice_player.dart';

import '../../tool/pack_builder_lib.dart';

/// A player that records what it was asked to play and lets a test move the clock and end the line.
class FakePlayer implements VoicePlayer {
  final List<Uint8List> played = <Uint8List>[];
  int stops = 0;
  int plays = 0;
  Duration? at;
  bool failToPlay = false;
  bool disposed = false;

  /// While set and not completed, `play` takes its time to start (a real player prepares the sound first).
  Completer<void>? holdPlay;

  /// The sound is audible now: a play that has started and has not been stopped.
  bool playing = false;

  /// When set, a line ends by itself this long after it started, like real sound (the lesson tests use it, so that lines
  /// wait for each other as they do on a phone).
  Duration? endsAfter;
  Timer? _ending;
  final StreamController<void> _done = StreamController<void>.broadcast();

  @override
  Future<void> play(Uint8List sound, {String mime = 'audio/mpeg'}) async {
    if (failToPlay) throw StateError('no sound device');
    plays++;
    played.add(sound);
    at = Duration.zero;
    if (holdPlay != null) await holdPlay!.future;
    playing = true;
    _ending?.cancel();
    final Duration? after = endsAfter;
    if (after != null) _ending = Timer(after, finish);
  }

  @override
  Future<Duration?> position() async => at;

  @override
  Stream<void> get completed => _done.stream;

  void finish() {
    at = null;
    _done.add(null);
  }

  @override
  Future<void> stop() async {
    _ending?.cancel();
    stops++;
    at = null;
    playing = false;
  }

  @override
  Future<void> dispose() async {
    disposed = true;
    await _done.close();
  }
}

/// Builds a voice pack: for each line a small mp3 (just bytes that name the line) and its mouth cues.
Future<BuiltPack> buildVoicePack(
  PackKey key,
  String characterId,
  Map<String, List<(int, int)>> lines, {
  String version = '1.0.0',
}) async {
  final Directory src = Directory.systemTemp.createTempSync('nn_voice_');
  try {
    final List<Map<String, String>> vo = <Map<String, String>>[];
    for (final MapEntry<String, List<(int, int)>> l in lines.entries) {
      File('${src.path}/vo.${l.key}.mp3').writeAsBytesSync(utf8.encode('mp3:$characterId:${l.key}'));
      File('${src.path}/cue.${l.key}.json').writeAsStringSync(
        jsonEncode(<String, Object?>{
          'schema': 'cue/v1',
          'id': l.key,
          'cues': <Object?>[
            for (final (int, int) c in l.value) <String, Object?>{'t': c.$1, 'o': c.$2},
          ],
        }),
      );
      vo.add(<String, String>{'id': l.key, 'file': 'vo.${l.key}.mp3'});
    }
    File('${src.path}/pack.json').writeAsStringSync(
      jsonEncode(<String, Object?>{
        'schema': 'pack-source/v1',
        'id': 'voice-$characterId',
        'version': version,
        'minAppVersion': '0.3.0',
        'assets': <Object?>[],
        'vo': vo,
      }),
    );
    return await buildPack(src, key);
  } finally {
    try {
      src.deleteSync(recursive: true);
    } on FileSystemException {
      // Left for the system's temp cleaner.
    }
  }
}
