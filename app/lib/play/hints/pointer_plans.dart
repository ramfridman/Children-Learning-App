import 'dart:math' as math;

import 'package:flutter/painting.dart';

import '../sprite_group.dart';
import 'hint_marks.dart';

// The pointing hand of the worked example (level 3) for the templates that count things on the stage (B-40 part 3): count and
// tap, give N and flash. The hand touches each thing in turn and a number badge stays on it; the session's own demonstration
// (things fly, things are placed) runs on its own timers, and these plans are timed to meet it: the hand reaches a thing at the
// moment the session counts it. Everything is in the stage's own points; the hand's fingertip is the anchor.

/// How long the hand takes to reach the first thing, and between two things: the same steps as the sessions' demonstrations (800 ms,
/// the first one 300 ms in). The hand leaves 450 ms (its travel) before the session counts, so that it is there when it does.
const int pointerStepMs = 800;

/// The hand counts [targets] in turn (the fingertip on each, a press, and a badge that stays when [badges]), then leaves; [tailMs]
/// is how long the stage holds still after the last one. The plan ends when the session's demonstration does, and nothing stays.
HintPlan pointerCountPlan(
  List<Offset> targets, {
  required bool badges,
  Offset Function(int i)? badgeAt,
  int tailMs = 650,
}) {
  final List<HintFrame> frames = <HintFrame>[];
  List<HintMark> counted(int upTo) => <HintMark>[
    if (badges)
      for (int j = 0; j < upTo; j++) BadgeMark(badgeAt!(j), j + 1),
  ];
  for (int i = 0; i < targets.length; i++) {
    frames.add(
      HintFrame(<HintMark>[
        ...counted(i + 1),
        HandMark(targets[i], press: true),
      ], hold: Duration(milliseconds: i == 0 ? pointerStepMs - 150 : pointerStepMs)),
    );
  }
  frames.add(HintFrame(counted(targets.length), hold: Duration(milliseconds: tailMs)));
  return HintPlan(frames);
}

/// Give N: the hand takes each thing from the pile ([pile]) and puts it on the flower ([slots]), one after the other, the badge of
/// each on its place on the flower, then leaves while the session holds the full flower for a moment ([tailMs]).
HintPlan pointerGivePlan(List<Offset> pile, List<Offset> slots, {int tailMs = 1850}) {
  final List<HintFrame> frames = <HintFrame>[];
  List<HintMark> given(int n, Offset Function(int) at) => <HintMark>[
    for (int j = 0; j < n; j++) BadgeMark(at(j), j + 1),
  ];
  for (int i = 0; i < slots.length; i++) {
    frames.add(
      HintFrame(<HintMark>[
        ...given(i, (int j) => slots[j] + const Offset(10, -10)),
        HandMark(pile[i], press: true),
      ], hold: Duration(milliseconds: i == 0 ? 400 : 550)),
    );
    frames.add(
      HintFrame(<HintMark>[
        ...given(i, (int j) => slots[j] + const Offset(10, -10)),
        HandMark(slots[i], press: true),
      ], hold: const Duration(milliseconds: 250)),
    );
  }
  final List<HintMark> all = given(slots.length, (int j) => slots[j] + const Offset(10, -10));
  frames.add(HintFrame(all, hold: Duration(milliseconds: tailMs)));
  return HintPlan(frames);
}

/// Flash: where the pictures of a group stand when it is drawn in a box of [box] with [padding] around it (the same numbers the
/// flash stage uses), in the stage's own points, in reading order.
List<Offset> flashObjectCentres(
  Size stage,
  double room, {
  required String arrangement,
  required int count,
  required int seed,
  required double scale,
}) {
  const double padding = 10;
  final Size box = Size(stage.width - 2 * padding, room - 2 * padding);
  final List<Rect> rects = spriteRects(box, arrangement, count, seed: seed, scale: scale);
  final List<Rect> sorted = List<Rect>.of(rects);
  final double band = rects.isEmpty ? 1 : rects.first.height * 0.7;
  sorted.sort((Rect p, Rect q) {
    final int row = (p.center.dy / band).round().compareTo((q.center.dy / band).round());
    return row != 0 ? row : p.center.dx.compareTo(q.center.dx);
  });
  return <Offset>[for (final Rect r in sorted) r.center + const Offset(padding, padding)];
}

/// Flash, level 3: the group stays in view, and the hand touches each picture in turn with a badge that stays, ending on the
/// last number (the badge of the last one is the group's count). [stepMs] is how long each one is held; the plan is as long as the
/// group stays in view.
HintPlan pointerFlashPlan(List<Offset> centres, {int stepMs = 700, int tailMs = 600}) {
  final List<HintFrame> frames = <HintFrame>[];
  List<HintMark> counted(int n) => <HintMark>[
    for (int j = 0; j < n; j++) BadgeMark(centres[j] + const Offset(10, -10), j + 1),
  ];
  for (int i = 0; i < centres.length; i++) {
    frames.add(
      HintFrame(<HintMark>[
        ...counted(i + 1),
        HandMark(centres[i], press: true),
      ], hold: Duration(milliseconds: math.max(stepMs, 500))),
    );
  }
  frames.add(HintFrame(counted(centres.length), hold: Duration(milliseconds: tailMs)));
  return HintPlan(frames);
}
