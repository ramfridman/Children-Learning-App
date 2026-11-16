import 'package:flutter/painting.dart';

import 'hints/hint_marks.dart';
import 'hints/hint_player.dart';
import 'hints/pointer_plans.dart';
import 'template_session.dart';

// What the host does on a stage in a Show or in the lead of a Together item, for the templates that have no art of their own for it (M11 Stage 2,
// docs/milestones/M11-stage2.md section 2.1): its hand goes to a place on the stage, presses, and the stage changes there (a coin lies on the
// counter, a block is on the pan, a marker has hopped). Kubi's pointer, which draws along the sides of a shape, is `show_stage.dart`; every other
// host's hand is the pointing hand of the hints, as the worked example of a hint uses it.

/// One thing the host does: its hand goes to [tip] (null: no hand is drawn, the stage only changes), presses, and [act] changes what the stage
/// shows; then the host rests [rest] milliseconds before the next. [marks] are what the hint layer draws from this move on and what stays
/// when the hand has gone (an arc and the number of a hop): the whole list, so that each move carries what the ones before drew.
class HostMove {
  const HostMove(this.tip, this.act, {this.rest = 700, this.marks = const <HintMark>[]});

  final Offset? tip;
  final void Function() act;
  final int rest;
  final List<HintMark> marks;
}

/// How long the hand takes to reach its place (`handTravelMs`), and how the moves are paced for the look and for movement: the youngest looks
/// (P1 and P2) are 40% slower, a reminder 40% faster. With reduced movement no hand travels: each move is in place after a pause, one after the
/// other (the pause is the same as the rest, so a Show still reads as steps).
extension HostMoves on TemplateSession {
  /// The pace of this session's host: 1 for the usual, more for the slower look.
  double get hostPace => slowHost ? 1.4 : 1;

  /// Plays [moves] one after the other on [hint]'s stage: the hand goes to each tip and presses, then the move's act. [fast] is a reminder, which
  /// is shorter (the hand's travel and the rests are cut by 40%).
  Future<void> hostTour(
    HintPlayer hint,
    List<HostMove> moves, {
    bool fast = false,
    List<HintMark> before = const <HintMark>[],
  }) async {
    if (moves.isEmpty) return;
    final double k = fast ? 0.6 : hostPace;
    final bool hand = !stillHost && moves.every((HostMove m) => m.tip != null);
    final int travel = (handTravelMs * (fast ? 0.6 : 1)).round();
    if (hand) {
      // Two stops for each move at the same place: the hand arrives while the marks of the moves before are still all there is, and presses
      // while the move's own marks come.
      hint.play(
        handTourPlan(<HandStop>[
          for (final (int i, HostMove m) in moves.indexed) ...<HandStop>[
            HandStop(m.tip!, _legMs(i, travel), marks: i == 0 ? before : moves[i - 1].marks),
            HandStop(m.tip!, (m.rest * k).round(), marks: m.marks),
          ],
        ], rest: moves.last.marks),
      );
    }
    for (final HostMove m in moves) {
      await pause(Duration(milliseconds: hand ? _legMs(moves.indexOf(m), travel) : (m.rest * k).round()));
      m.act();
      notify();
      // Without the hand (reduced movement) what the move drew stays at once.
      if (!hand && m.marks.isNotEmpty) hint.play(HintPlan(const <HintFrame>[], rest: m.marks));
      if (hand) await pause(Duration(milliseconds: (m.rest * k).round()));
    }
  }
}

/// How long the hand takes to reach move [i]'s place: the whole [travel] for the first (it comes in from off the stage), little more than half of it for
/// the next, which are a step along from where it is (a run of ten objects is not ten full glides).
int _legMs(int i, int travel) => i == 0 ? travel : (travel * 0.55).round();
