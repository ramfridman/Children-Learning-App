import 'package:flutter/widgets.dart';

import '../../child/activity_shell.dart';
import '../template_session.dart';
import 'hint_marks.dart';
import 'hint_pictures.dart';

/// Plays the [HintPlan]s of one session (B-40): each step on its timers for its time, then what stays. A session owns one player,
/// asks it to [play] a plan when the hint comes, to [clear] it when the child moves, and draws [marks] with [hands] (the pointing
/// hand's layer, above the speech bubble) and a [HintOverlay] over its stage (everything else).
///
/// Starting another plan, or clearing, stops the one that is playing: the steps of an old plan check their generation and do
/// nothing when a newer one has begun. The timers are the session's own, so they all end when the session is disposed.
class HintPlayer {
  HintPlayer(this.session);

  final TemplateSession session;

  /// What is on the stage now, how much of the stage's end side a card takes, and the answer tile (by its place in the row) that
  /// glows in this step (see [HintFrame]).
  List<HintMark> marks = const <HintMark>[];
  double reserve = 0;
  int? litOption;
  int _gen = 0;

  /// True while a plan is running (its steps have not all been shown).
  bool get playing => _playing;
  bool _playing = false;

  /// Shows [plan] from its first step. [onEnd] runs when the last step is over and the plan's rest is shown.
  void play(HintPlan plan, {VoidCallback? onEnd}) {
    final int gen = ++_gen;
    _playing = true;
    Duration at = Duration.zero;
    for (final HintFrame f in plan.frames) {
      session.later(at, () {
        if (gen != _gen) return;
        marks = f.marks;
        reserve = f.reserve;
        litOption = f.litOption;
        session.notify();
      });
      at += f.hold;
    }
    session.later(at, () {
      if (gen != _gen) return;
      marks = plan.rest;
      reserve = plan.restReserve;
      litOption = null;
      _playing = false;
      session.notify();
      onEnd?.call();
    });
  }

  /// Takes the hint off the stage and stops the plan that is playing.
  void clear() {
    _gen++;
    _playing = false;
    marks = const <HintMark>[];
    reserve = 0;
    litOption = null;
  }

  /// The layer of the pointing hand over a stage of [size] (see `TemplateSession.buildHands`); empty while no hand is shown.
  Widget hands(Size size, ActivitySpec spec, {double tileHalf = 48, double? rowEnd}) => ListenableBuilder(
    listenable: session,
    builder: (BuildContext c, Widget? _) => marks.whereType<HandMark>().isEmpty
        ? const SizedBox()
        : HintOverlay(
            marks: marks,
            size: size,
            clearOf: handClearOf(spec),
            tileHalf: tileHalf,
            rowEnd: rowEnd,
            layer: HintLayer.hands,
          ),
  );

  /// Everything of the hint but the hand, over a stage of [size].
  Widget body(Size size) => ListenableBuilder(
    listenable: session,
    builder: (BuildContext c, Widget? _) =>
        marks.isEmpty ? const SizedBox() : HintOverlay(marks: marks, size: size, layer: HintLayer.body),
  );
}
