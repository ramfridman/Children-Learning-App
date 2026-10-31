import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/child/activity_shell.dart';
import 'package:nitznutz/content/models.dart';
import 'package:nitznutz/play/hint_widgets.dart';
import 'package:nitznutz/play/hints/hint_marks.dart';
import 'package:nitznutz/play/hints/tap_geometry.dart';
import 'package:nitznutz/play/hints/tap_plans.dart';

import 'support/starter.dart';

/// B-40, the fixes after the QA pass: what the QA tests do not say about the pictures of the fixes themselves.
void main() {
  late PackContent content;
  setUpAll(() async => content = await loadStarter());

  TapAnswerActivity act(String id) => content.activities[id]! as TapAnswerActivity;
  Size stageOf(ActivitySpec s) =>
      s.stageIsCard ? Size(s.stage.width - 32, s.stage.height - 32) : s.stage.size;
  HintPlan plan(TapAnswerActivity a, int level, ActivitySpec s) =>
      tapHintPlan(a, TapGeometry(a, stageOf(s), s), level)!;

  double cellOf(HintPlan p) {
    final CardMark card = p.rest.whereType<CardMark>().single;
    return (card.child as TenFrames).cell;
  }

  test('a teen draws its ten-frames with cells of 24 on a phone and bigger on a tablet', () {
    final TapAnswerActivity a = act('b.numb08.1');
    expect(cellOf(plan(a, 2, ActivitySpec.phone)), 24);
    expect(cellOf(plan(a, 2, ActivitySpec.tabletLandscape)), greaterThan(30));
    expect(
      cellOf(plan(a, 2, ActivitySpec.phoneSE)),
      lessThan(24),
      reason: 'the small phone scales down to its stage',
    );
  });

  test(
    'the answer that fills the empty place of a row stands on a paper fill that hides its question mark',
    () {
      final TapAnswerActivity a = act('b.logb04.1');
      final List<CopyMark> copies = <CopyMark>[
        for (final HintFrame f in plan(a, 3, ActivitySpec.phone).frames) ...f.marks.whereType<CopyMark>(),
      ];
      expect(copies, isNotEmpty);
      expect(copies.every((CopyMark c) => c.backed), isTrue);
    },
  );
}
