import 'dart:async';

import 'package:flutter/foundation.dart';

import '../characters/lip_sync.dart';
import 'voice_bank.dart';
import 'voice_player.dart';

/// A line waiting for the one that is playing to finish.
class _Waiting {
  const _Waiting(this.voId, this.clip, this.owner);

  final String? voId;
  final VoiceClip clip;
  final Object? owner;
}

/// Speaks the guide's lines, one at a time, in the voice of the child's companion, and tells the character
/// when its mouth is open. It never plays two lines at once, stops when told to (the child leaves the screen),
/// and does nothing for a line with no recording (the caption is on screen anyway).
///
/// A line is never cut off by the next one: [sayNext] waits for the line that is playing to end (the congratulation is
/// heard to its last word, then the next question is read). Only the newest waiting line is kept, so a child who moves
/// fast does not build a queue of old questions. [say] is for the child's own touch (the guide is tapped, the replay
/// button) and replaces what is playing.
class VoiceDirector extends ChangeNotifier {
  VoiceDirector({
    required VoicePlayer player,
    this.poll = const Duration(milliseconds: 40),
    this.gap = Duration.zero,
  }) : _player = player {
    _done = _player.completed.listen((_) => _finish(_generation));
  }

  final VoicePlayer _player;

  /// A short pause between a line and the one that was waiting for it.
  final Duration gap;
  _Waiting? _waiting;
  Timer? _gapTimer;
  bool _starting = false;
  Object? _owner;

  /// How often the position of the sound is read to move the mouth.
  final Duration poll;
  late final StreamSubscription<void> _done;
  Timer? _timer;
  VoiceBank? _bank;
  VoiceClip? _clip;
  final MouthFlap _flap = MouthFlap();
  int _generation = 0;
  bool _disposed = false;

  bool _speaking = false;
  bool _mouthOpen = false;
  String? _current;

  /// A line is playing now.
  bool get speaking => _speaking;

  /// The mouth should be open at this moment (only meaningful while [speaking]).
  bool get mouthOpen => _mouthOpen;

  /// The id of the line that is playing or that played last.
  String? get current => _current;

  VoiceBank? get bank => _bank;

  /// Changes whose voice is heard (the companion changed). Whatever is playing stops.
  void useBank(VoiceBank? bank) {
    if (identical(bank, _bank)) return;
    unawaited(stop());
    _bank = bank;
  }

  /// Says the line [voId] (`vo:...`) in the current voice, replacing whatever is playing. A null id or a line with no
  /// recording is silence. [owner] says who spoke (see [stopFor]).
  Future<void> say(String? voId, {Object? owner}) =>
      _run(voId, voId == null ? null : _bank?.clip(voId), owner: owner);

  /// Says a line that is not in the pack: the live line of the AI tutor, as sound that was just checked and made.
  /// It has no mouth cues, so the mouth moves at a gentle rhythm while it plays.
  Future<void> sayBytes(Uint8List sound, {String mime = 'audio/mpeg', Object? owner}) =>
      _run('live', VoiceClip(sound, MouthTrack(const <(int, bool)>[]), mime: mime), owner: owner);

  /// Says the line [voId] after the line that is playing has ended; at once if none is playing. A line with no recording
  /// is skipped and never cuts a playing one. Only the newest waiting line is kept.
  Future<void> sayNext(String? voId, {Object? owner}) {
    final VoiceClip? clip = voId == null ? null : _bank?.clip(voId);
    return clip == null ? Future<void>.value() : _next(voId, clip, owner);
  }

  /// [sayNext] for a line that is not in the pack (the tutor's live line).
  Future<void> sayBytesNext(Uint8List sound, {String mime = 'audio/mpeg', Object? owner}) =>
      _next('live', VoiceClip(sound, MouthTrack(const <(int, bool)>[]), mime: mime), owner);

  Future<void> _next(String? voId, VoiceClip clip, Object? owner) {
    if (_speaking || _starting || _waiting != null) {
      _waiting = _Waiting(voId, clip, owner);
      return Future<void>.value();
    }
    return _run(voId, clip, owner: owner);
  }

  Future<void> _run(String? voId, VoiceClip? clip, {Object? owner}) async {
    final int gen = ++_generation;
    _timer?.cancel();
    _gapTimer?.cancel();
    _waiting = null;
    _starting = clip != null;
    _owner = owner;
    if (_speaking) {
      _speaking = false;
      _mouthOpen = false;
    }
    await _player.stop();
    if (_disposed || gen != _generation) return;
    _current = voId;
    if (clip == null) {
      notifyListeners();
      return;
    }
    _clip = clip;
    _flap.reset();
    _speaking = true;
    _starting = false;
    _mouthOpen = false;
    notifyListeners();
    try {
      await _player.play(clip.mp3, mime: clip.mime);
    } on Object {
      // A sound that cannot play is a silent line, not a broken screen.
      _finish(gen);
      return;
    }
    if (_disposed || gen != _generation) {
      // The line was stopped (or replaced) while the player was still starting it: it must not be left playing.
      if (_disposed || !_speaking) await _player.stop();
      return;
    }
    _timer = Timer.periodic(poll, (Timer t) => unawaited(_tick(gen)));
  }

  Future<void> _tick(int gen) async {
    if (_disposed || gen != _generation || !_speaking) return;
    final Duration? at = await _player.position();
    if (_disposed || gen != _generation || !_speaking || at == null) return;
    final VoiceClip clip = _clip!;
    final int ms = at.inMilliseconds;
    // A line with no cue file still moves its mouth while the sound plays, at a gentle rhythm.
    final bool wanted = clip.mouth.length == 0 ? (ms ~/ 140).isOdd : clip.mouth.openAt(ms);
    final bool open = _flap.update(ms, wanted);
    if (open != _mouthOpen) {
      _mouthOpen = open;
      notifyListeners();
    }
  }

  void _finish(int gen) {
    if (_disposed || gen != _generation) return;
    _timer?.cancel();
    final bool was = _speaking;
    _speaking = false;
    _mouthOpen = false;
    if (was) notifyListeners();
    final _Waiting? next = _waiting;
    if (next == null) return;
    // The line that was waiting goes now (after a short pause). It stays "waiting" until it starts, so that a line that
    // arrives meanwhile replaces it instead of cutting in.
    void start() {
      if (_disposed || !identical(_waiting, next)) return;
      _waiting = null;
      unawaited(_run(next.voId, next.clip, owner: next.owner));
    }

    if (gap == Duration.zero) {
      start();
    } else {
      _gapTimer?.cancel();
      _gapTimer = Timer(gap, start);
    }
  }

  /// Stops the line now, and forgets any line waiting.
  Future<void> stop() async {
    _generation++;
    _timer?.cancel();
    _gapTimer?.cancel();
    _waiting = null;
    _starting = false;
    _owner = null;
    final bool was = _speaking;
    _speaking = false;
    _mouthOpen = false;
    await _player.stop();
    if (was && !_disposed) notifyListeners();
  }

  /// Stops only what [owner] said (a screen that closes must not silence a line that the next screen has just started).
  Future<void> stopFor(Object owner) async {
    if (identical(_waiting?.owner, owner)) {
      _waiting = null;
      _gapTimer?.cancel();
    }
    if (identical(_owner, owner)) await stop();
  }

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    _gapTimer?.cancel();
    unawaited(_done.cancel());
    unawaited(_player.dispose());
    super.dispose();
  }
}
