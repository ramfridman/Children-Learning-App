import 'dart:async';

import 'package:flutter/foundation.dart';

import '../child/adventure_line.dart';
import '../voice/voice_director.dart';

/// How long the bottle's line stays in front of the child when there is no recording of it (a few words to read and
/// take in, or to have read to them), and the most it waits for a recording that does not end.
const Duration bottleLineHold = Duration(milliseconds: 2200);
const Duration bottleClipMostWait = Duration(seconds: 8);

/// What happens between the touch on the bottle in the child's home and the stop that it opens (B-39): the friend's
/// bubble says the line of the stop ([line]), in its voice when the pack has the recording, and the stop opens when the
/// recording has ended, or [bottleLineHold] after the line appeared when there is none. A second touch on the bottle
/// opens the stop at once; leaving the home ([cancel]) or touching something else on it drops the stop. Nothing counts
/// down on screen: the line is simply there until the stop opens.
class BottleHold {
  BottleHold(this._director);

  final VoiceDirector _director;

  /// What the bubble says now; null when it says its own words.
  final ValueNotifier<AdventureLine?> line = ValueNotifier<AdventureLine?>(null);

  /// Counts the touches that found nothing to open (a gentle wobble of the bottle, no line).
  final ValueNotifier<int> wobble = ValueNotifier<int>(0);

  Completer<bool>? _waiting;
  bool _gone = false;

  /// A touch is being worked out or the line is being held: another touch must not start a second stop.
  bool busy = false;

  /// The line is in front of the child, waiting to open its stop.
  bool get waiting => _waiting != null;

  /// The home was left: no stop opens any more.
  bool get gone => _gone;

  /// Shows [words] and waits for them to be seen and heard. True when the stop should open, false when it was dropped.
  Future<bool> hold(AdventureLine words) async {
    if (_gone) return false;
    final Completer<bool> done = _waiting = Completer<bool>();
    line.value = words;
    void finish(bool go) {
      if (!done.isCompleted) done.complete(go);
    }

    void whenQuiet() {
      if (!_director.speaking) finish(true);
    }

    Duration most = bottleLineHold;
    if (_director.bank?.has(words.voice) ?? false) {
      await _director.say(words.voice, owner: this);
      // Only a recording that is really playing is waited for to its end; one that could not start leaves the plain hold.
      if (!done.isCompleted && _director.speaking) {
        _director.addListener(whenQuiet);
        most = bottleClipMostWait;
      }
    }
    // The longest the stop waits; a hold that ends sooner (a second touch, the home left, the recording) cancels it.
    final Timer limit = Timer(most, () => finish(true));
    final bool go = await done.future;
    limit.cancel();
    _director.removeListener(whenQuiet);
    if (identical(_waiting, done)) _waiting = null;
    if (!go) {
      clear();
      unawaited(_director.stopFor(this));
    }
    return go;
  }

  /// The second touch: the stop opens now (the recording, if it still plays, is heard on by the lesson, which waits for it).
  void releaseNow() => _waiting?.complete(true);

  /// The home was left, or the child touched something else on it: the waiting stop is dropped.
  void cancel() {
    _gone = true;
    final Completer<bool>? w = _waiting;
    if (w != null && !w.isCompleted) w.complete(false);
  }

  /// Another touch on the home while the line waits: the stop is dropped, the home stays.
  void drop() {
    final Completer<bool>? w = _waiting;
    if (w != null && !w.isCompleted) w.complete(false);
  }

  /// The bubble goes back to its own words.
  void clear() {
    if (!_gone) line.value = null;
  }

  /// A touch on the bottle that found nothing to open.
  void nudge() {
    if (!_gone) wobble.value++;
  }

  void dispose() {
    cancel();
    line.dispose();
    wobble.dispose();
  }
}
