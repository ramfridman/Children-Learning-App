import 'dart:async';

import 'package:flutter/foundation.dart';

import '../characters/lip_sync.dart';
import 'voice_bank.dart';
import 'voice_player.dart';

/// A line waiting for the one that is playing to finish.
class _Waiting {
  _Waiting(this.voId, this.clip, this.owner, this.relevant, this.at);

  final String? voId;
  final VoiceClip clip;
  final Object? owner;

  /// Asks whether the line is still worth saying (the child has not moved on since it was made); null means always.
  final bool Function()? relevant;
  final DateTime at;

  bool get stale => relevant != null && !relevant!();
}

/// Speaks the guide's lines, one at a time, in the voice of the child's companion, and tells the character
/// when its mouth is open. It never plays two lines at once, stops when told to (the child leaves the screen),
/// and does nothing for a line with no recording (the caption is on screen anyway).
///
/// Lines are said at the right time, not at every time. [sayNext] waits for the line that is playing to end (the
/// congratulation is heard to its last word, then the next question is read), so nothing is cut off while it still
/// matters. But a line is only worth saying while the child has not moved on: each line can say whether it is still
/// relevant. A waiting line that is no longer relevant is dropped, never played late; a playing line that is no longer
/// relevant gives way to the new one; at most two lines wait (the congratulation and the next question), and a line that
/// has waited too long is dropped. [say] is for the child's own touch (the replay button) and replaces what is playing.
class VoiceDirector extends ChangeNotifier {
  VoiceDirector({
    required VoicePlayer player,
    this.poll = const Duration(milliseconds: 40),
    this.gap = Duration.zero,
    this.maxWait = const Duration(seconds: 6),
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now,
       _player = player {
    _done = _player.completed.listen((_) => _finish(_generation));
  }

  final VoicePlayer _player;

  /// A short pause between a line and the one that was waiting for it.
  final Duration gap;

  /// A waiting line older than this is dropped: it is about something that has long passed.
  final Duration maxWait;
  final DateTime Function() _now;
  final List<_Waiting> _waiting = <_Waiting>[];
  Timer? _gapTimer;
  bool _starting = false;
  Object? _owner;
  bool Function()? _playingRelevant;

  /// The line playing has been overtaken by the child's own moves.
  bool get _playingStale => _playingRelevant != null && !_playingRelevant!();

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
  Future<void> say(String? voId, {Object? owner, bool Function()? relevant}) =>
      _run(voId, voId == null ? null : _bank?.clip(voId), owner: owner, relevant: relevant);

  /// Says a line that is not in the pack: the live line of the AI tutor, as sound that was just checked and made.
  /// It has no mouth cues, so the mouth moves at a gentle rhythm while it plays.
  Future<void> sayBytes(
    Uint8List sound, {
    String mime = 'audio/mpeg',
    Object? owner,
    bool Function()? relevant,
  }) => _run(
    'live',
    VoiceClip(sound, MouthTrack(const <(int, bool)>[]), mime: mime),
    owner: owner,
    relevant: relevant,
  );

  /// Says the line [voId] after the line that is playing has ended; at once if none is playing. A line with no recording
  /// is skipped and never cuts a playing one. Only the newest waiting line is kept.
  Future<void> sayNext(String? voId, {Object? owner, bool Function()? relevant}) {
    final VoiceClip? clip = voId == null ? null : _bank?.clip(voId);
    return clip == null ? Future<void>.value() : _next(voId, clip, owner, relevant);
  }

  /// [sayNext] for a line that is not in the pack (the tutor's live line).
  Future<void> sayBytesNext(
    Uint8List sound, {
    String mime = 'audio/mpeg',
    Object? owner,
    bool Function()? relevant,
  }) => _next('live', VoiceClip(sound, MouthTrack(const <(int, bool)>[]), mime: mime), owner, relevant);

  Future<void> _next(String? voId, VoiceClip clip, Object? owner, bool Function()? relevant) {
    _forgetStale();
    final bool free = !(_speaking || _starting || _waiting.isNotEmpty);
    _waiting.add(_Waiting(voId, clip, owner, relevant, _now()));
    // Only the two newest lines wait (the congratulation and the next question): older ones are about the past.
    while (_waiting.length > 2) {
      _waiting.removeAt(0);
    }
    // Nothing is playing, or the line that is playing no longer matters (the child answered again, or moved on): the first
    // waiting line goes now. Otherwise it waits for the line that is playing to end.
    if (free || (_speaking && _playingStale)) {
      final _Waiting go = _waiting.removeAt(0);
      return _run(go.voId, go.clip, owner: go.owner, relevant: go.relevant, keepWaiting: true);
    }
    return Future<void>.value();
  }

  /// Drops the waiting lines that are no longer relevant or have waited too long.
  void _forgetStale() {
    final DateTime now = _now();
    _waiting.removeWhere((_Waiting w) => w.stale || now.difference(w.at) > maxWait);
  }

  Future<void> _run(
    String? voId,
    VoiceClip? clip, {
    Object? owner,
    bool Function()? relevant,
    bool keepWaiting = false,
  }) async {
    final int gen = ++_generation;
    _timer?.cancel();
    _gapTimer?.cancel();
    if (!keepWaiting) _waiting.clear();
    _starting = clip != null;
    _owner = owner;
    _playingRelevant = relevant;
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
    _forgetStale();
    if (_waiting.isEmpty) return;
    final _Waiting next = _waiting.first;
    // The line that was waiting goes now (after a short pause). It stays "waiting" until it starts, so that a line that
    // arrives meanwhile finds it there.
    void start() {
      if (_disposed || _waiting.isEmpty || !identical(_waiting.first, next)) return;
      _forgetStale();
      if (_waiting.isEmpty) return;
      final _Waiting go = _waiting.removeAt(0);
      unawaited(_run(go.voId, go.clip, owner: go.owner, relevant: go.relevant, keepWaiting: true));
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
    _waiting.clear();
    _starting = false;
    _owner = null;
    _playingRelevant = null;
    final bool was = _speaking;
    _speaking = false;
    _mouthOpen = false;
    await _player.stop();
    if (was && !_disposed) notifyListeners();
  }

  /// Stops only what [owner] said (a screen that closes must not silence a line that the next screen has just started).
  Future<void> stopFor(Object owner) async {
    _waiting.removeWhere((_Waiting w) => identical(w.owner, owner));
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
