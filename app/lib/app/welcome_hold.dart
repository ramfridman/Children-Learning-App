import 'dart:async';

import 'package:flutter/foundation.dart';

import '../child/welcome_shown.dart';
import '../voice/voice_director.dart';
import 'bottle_hold.dart' show bottleClipMostWait, bottleLineHold;

/// One sentence of the daily welcome: what the bubble shows, and what is said while it shows ([nameClip] first, then
/// [voice]).
class WelcomeStep {
  const WelcomeStep({
    required this.text,
    required this.withName,
    this.voice,
    this.nameClip,
    this.pointsAtBottle = false,
  });

  /// The sentence with its niqqud.
  final String text;

  /// The bubble puts the child's name before it. True whenever the child has a usable name, whether or not there is a clip
  /// of it: the caption says the name as the map's bubble always has.
  final bool withName;

  /// The `vo:` id of the recording, or null for a sentence that is only shown.
  final String? voice;

  /// The child's own name clip, said right before [voice]: the sound only, from the device's store.
  final Uint8List? nameClip;

  /// The pill with the bottle glows during this sentence (the closing line).
  final bool pointsAtBottle;
}

/// The daily welcome in time (B-42, `docs/milestones/B42.md` sections 2.3 and 2.4): shows one sentence at a time in the
/// friend's bubble ([shown]) and says it in the friend's voice, a short pause between the sentences ([gap]), and glows the
/// pill during the sentence that points at the bottle ([glow]). Any touch stops it ([skip]): the voice stops at once, the
/// bubble goes back to its own words, and nothing else changes. It never blocks play and never repeats itself.
///
/// Without a recording ([run] with `voiced` false: a missing clip, the sound off) every sentence is shown for
/// [textHold], the same time the bottle's line stays. A recording that cannot start leaves the sentence in the same hold.
/// Nothing counts down on screen.
class WelcomeHold {
  WelcomeHold(
    this._director, {
    this.gap = const Duration(milliseconds: 350),
    this.textHold = bottleLineHold,
    this.clipMostWait = bottleClipMostWait,
  });

  final VoiceDirector _director;

  /// The pause between two sentences: longer for the youngest, who need time to take a sentence in (B42.md 2.5).
  final Duration gap;

  /// How long a sentence with no recording stays.
  final Duration textHold;

  /// The most that a recording is waited for.
  final Duration clipMostWait;

  /// What the bubble says now; null when it says its own words.
  final ValueNotifier<WelcomeShown?> shown = ValueNotifier<WelcomeShown?>(null);

  /// The pill glows.
  final ValueNotifier<bool> glow = ValueNotifier<bool>(false);

  final Completer<void> _stop = Completer<void>();
  bool _running = false;
  bool _used = false;
  bool _disposed = false;

  /// The welcome is on now.
  bool get running => _running;

  /// The welcome has been stopped, by [skip] or [dispose].
  bool get stopped => _stop.isCompleted;

  /// Runs the welcome once. Completes when it has ended or been stopped; the bubble and the pill are back to their own
  /// state by then.
  Future<void> run(List<WelcomeStep> steps, {required bool voiced}) async {
    if (_used || stopped) return;
    _used = true;
    _running = true;
    try {
      for (int i = 0; i < steps.length && !stopped; i++) {
        final WelcomeStep step = steps[i];
        shown.value = WelcomeShown(text: step.text, withName: step.withName);
        glow.value = step.pointsAtBottle;
        if (voiced) {
          await _say(step);
        } else {
          await _sleep(textHold);
        }
        if (i < steps.length - 1 && !stopped) await _sleep(gap);
      }
    } finally {
      _running = false;
      _clear();
    }
  }

  void _clear() {
    if (_disposed) return;
    shown.value = null;
    glow.value = false;
  }

  Future<void> _say(WelcomeStep step) async {
    final Uint8List? name = step.nameClip;
    if (name != null) {
      await _director.sayBytes(name, owner: this);
      await _untilQuiet();
    }
    final String? voice = step.voice;
    if (voice == null || stopped) return;
    await _director.say(voice, owner: this);
    if (stopped) return;
    // A recording that really plays is waited for to its end; one that could not start leaves the plain hold.
    if (_director.speaking) {
      await _untilQuiet();
    } else {
      await _sleep(textHold);
    }
  }

  /// Completes when nothing is playing, when the welcome is stopped, or after [clipMostWait].
  Future<void> _untilQuiet() {
    if (!_director.speaking || stopped) return Future<void>.value();
    final Completer<void> done = Completer<void>();
    void check() {
      if (!_director.speaking && !done.isCompleted) done.complete();
    }

    _director.addListener(check);
    final Timer limit = Timer(clipMostWait, () {
      if (!done.isCompleted) done.complete();
    });
    unawaited(
      _stop.future.then((_) {
        if (!done.isCompleted) done.complete();
      }),
    );
    return done.future.whenComplete(() {
      limit.cancel();
      _director.removeListener(check);
    });
  }

  /// Waits [d], or until the welcome is stopped.
  Future<void> _sleep(Duration d) {
    if (stopped) return Future<void>.value();
    final Completer<void> done = Completer<void>();
    final Timer t = Timer(d, () {
      if (!done.isCompleted) done.complete();
    });
    unawaited(
      _stop.future.then((_) {
        if (!done.isCompleted) done.complete();
      }),
    );
    return done.future.whenComplete(t.cancel);
  }

  /// Any touch: the voice stops at once, the bubble goes back to its own words. A touch before or after the welcome does
  /// nothing.
  void skip() {
    if (!_running || stopped) return;
    _stop.complete();
    unawaited(_director.stopFor(this));
    _clear();
  }

  /// The map was left: the same as a touch, and the notifiers are let go.
  void dispose() {
    if (_disposed) return;
    if (!_stop.isCompleted) _stop.complete();
    unawaited(_director.stopFor(this));
    _disposed = true;
    shown.dispose();
    glow.dispose();
  }
}
