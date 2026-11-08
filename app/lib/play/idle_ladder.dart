import 'dart:async';

import 'package:flutter/widgets.dart';

import '../design/stage_spec.dart';
import 'hints/hint_marks.dart';
import 'hints/hint_pictures.dart';

// The idle ladder (B-29 D5, docs/design/b29-steps5-6.md section 6.3): what happens when a child has not touched anything for a while. Never a
// countdown and nothing is shown as time. Each step is reached after the stage's own stillness (8, 15, 30 and 120 seconds for P1 and P2,
// 12, 25, 45 and 120 for P3, 20, 40, 60 and 120 for P4), counted from the last touch; any touch starts it over. The screen holds it
// while a line is playing, so a prompt never talks over a line.

/// The four steps of the ladder.
enum IdleStep {
  /// Nitzi says the question again, the place it is said from rings once, and (P1 to P3) a hand points into the stage.
  firstPrompt,

  /// The same, with the hand in P4 too.
  secondPrompt,

  /// "Do you want a hint, or to think a bit more?": the "I'm not sure" pebble glows.
  offer,

  /// The soft pause: a rest, never a punishment.
  softPause,
}

/// Counts the stillness and tells [onStep] when each step is reached. [start] begins; [touch] starts over; [hold] and [release] stop and
/// resume the count while a line plays; [stop] ends it for good (the lesson is over).
class IdleLadder {
  IdleLadder({required this.stage, required this.onStep, this.onReset});

  final StageSpec stage;

  /// Called when [step] is reached.
  final void Function(IdleStep step) onStep;

  /// Called when a touch (or anything that restarts the count) sends the ladder back from a step that had been reached.
  final VoidCallback? onReset;

  Timer? _timer;
  int _reached = 0;
  bool _held = false;
  bool _stopped = false;

  /// How many steps have been reached since the last touch (0 for none).
  int get reached => _reached;

  void start() => _arm();

  /// Any touch, a new activity, an answer: the count starts over.
  void touch() {
    if (_stopped) return;
    final bool wasUp = _reached > 0;
    _reached = 0;
    _arm();
    if (wasUp) onReset?.call();
  }

  /// A line is playing: the count stops where it is, and starts over when it ends ([release]).
  void hold() {
    _held = true;
    _timer?.cancel();
  }

  void release() {
    if (!_held) return;
    _held = false;
    touch();
  }

  void stop() {
    _stopped = true;
    _timer?.cancel();
  }

  void _arm() {
    _timer?.cancel();
    if (_stopped || _held || _reached >= IdleStep.values.length) return;
    final Duration since = _reached == 0 ? Duration.zero : stage.idle(_reached - 1);
    final Duration wait = stage.idle(_reached) - since;
    _timer = Timer(wait, () {
      _reached++;
      onStep(IdleStep.values[_reached - 1]);
      _arm();
    });
  }
}

/// Whether the hand of the idle prompt shows at [step] in [stage]: P1 to P3 from the first prompt, P4 only from the second.
bool idleHandShows(StageSpec stage, IdleStep step) => switch (step) {
  IdleStep.firstPrompt => stage.focal <= 1,
  IdleStep.secondPrompt => true,
  IdleStep.offer || IdleStep.softPause => false,
};

/// Where the idle hand's fingertip goes in a stage of [room]: the middle of the stage. Never a tile, never the answer (the stage holds the
/// question's picture, and the tiles stand below it).
Offset idleTarget(Size room) => Offset(room.width / 2, room.height / 2);

/// The hand of the idle prompt over a stage of [room]: the pointing hand, its body below the fingertip, coming up from the grass. It is
/// the hint's own hand art; with "reduce motion" it appears without travelling.
Widget idleHand(Size room) => HintOverlay(
  key: const Key('idle-hand'),
  marks: <HintMark>[HandMark(idleTarget(room), from: HandFrom.below)],
  size: room,
);
