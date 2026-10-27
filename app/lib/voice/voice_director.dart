import 'dart:async';

import 'package:flutter/foundation.dart';

import '../characters/lip_sync.dart';
import 'voice_bank.dart';
import 'voice_player.dart';

/// Speaks the guide's lines, one at a time, in the voice of the child's companion, and tells the character
/// when its mouth is open. It never plays two lines at once, stops when told to (the child leaves the screen),
/// and does nothing for a line with no recording (the caption is on screen anyway).
class VoiceDirector extends ChangeNotifier {
  VoiceDirector({required VoicePlayer player, this.poll = const Duration(milliseconds: 40)})
    : _player = player {
    _done = _player.completed.listen((_) => _finish(_generation));
  }

  final VoicePlayer _player;

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

  /// Says the line [voId] (`vo:...`) in the current voice. A null id or a line with no recording is silence.
  Future<void> say(String? voId) => _run(voId, voId == null ? null : _bank?.clip(voId));

  /// Says a line that is not in the pack: the live line of the AI tutor, as sound that was just checked and made.
  /// It has no mouth cues, so the mouth moves at a gentle rhythm while it plays.
  Future<void> sayBytes(Uint8List sound, {String mime = 'audio/mpeg'}) =>
      _run('live', VoiceClip(sound, MouthTrack(const <(int, bool)>[]), mime: mime));

  Future<void> _run(String? voId, VoiceClip? clip) async {
    final int gen = ++_generation;
    _timer?.cancel();
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
  }

  /// Stops the line now.
  Future<void> stop() async {
    _generation++;
    _timer?.cancel();
    final bool was = _speaking;
    _speaking = false;
    _mouthOpen = false;
    await _player.stop();
    if (was && !_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    unawaited(_done.cancel());
    unawaited(_player.dispose());
    super.dispose();
  }
}
