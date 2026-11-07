// QA-C1-4: every Band C `tap_answer` item of batch C1 has a hint at levels 1 to 3 (M10 section 7.2), built by the rules of B-40
// (docs/design/b40-visual-hints.md, and Appendix B of docs/curriculum/b40-visual-hint-ladder.md: nothing marks the answer before level 3).
// The source-built pack is read, as `mastery_reachable_test.dart` does, so the items that are not in a signed pack yet are checked too.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/child/activity_shell.dart';
import 'package:nitznutz/content/models.dart';
import 'package:nitznutz/play/block_layout.dart';
import 'package:nitznutz/play/hints/hint_marks.dart';
import 'package:nitznutz/play/hints/tap_geometry.dart';
import 'package:nitznutz/play/hints/tap_plans.dart';
import 'package:nitznutz/play/stage_pictures.dart';

import 'support/c1_screens.dart';
import 'support/harness.dart';

void main() {
  late List<TapAnswerActivity> items;

  setUpAll(() async {
    await loadAppFonts();
    items = <TapAnswerActivity>[...bandCActivities(await loadSourcePack()).whereType<TapAnswerActivity>()];
  });

  Size stageOf(ActivitySpec s) =>
      s.stageIsCard ? Size(s.stage.width - 32, s.stage.height - 32) : s.stage.size;
  final List<ActivitySpec> boards = <ActivitySpec>[
    ActivitySpec.phone,
    ActivitySpec.phoneSE,
    ActivitySpec.tabletLandscape,
    ActivitySpec.tabletPortrait,
  ];

  // The board as the item lays it out (blocks have their own layouts, see `BlockLayout`), the stage the session draws.
  HintPlan? planOf(TapAnswerActivity a, int level, ActivitySpec s) {
    final ActivitySpec laid = BlockLayout.of(a, s);
    return tapHintPlan(a, TapGeometry(a, stageOf(laid), laid), level);
  }

  Iterable<HintMark> marksOf(HintPlan p) sync* {
    for (final HintFrame f in p.frames) {
      yield* f.marks;
    }
    yield* p.rest;
  }

  Set<String> kinds(HintPlan p) => <String>{
    for (final HintFrame f in p.frames) ...<String>[
      for (final HintMark m in f.marks) m.runtimeType.toString(),
      if (f.litOption != null) 'lit',
    ],
    for (final HintMark m in p.rest) m.runtimeType.toString(),
  };

  test('the pack has the C1 tap_answer items to check', () {
    expect(items.length, greaterThanOrEqualTo(132));
  });

  test('every Band C tap_answer item has a plan at levels 1, 2 and 3 on every board', () {
    final List<String> missing = <String>[];
    for (final ActivitySpec board in boards) {
      for (final TapAnswerActivity a in items) {
        for (int level = 1; level <= 3; level++) {
          if (planOf(a, level, board) == null) missing.add('${a.id} level $level');
        }
      }
    }
    expect(missing, isEmpty, reason: missing.take(20).join(', '));
  });

  test('every step has time, level 3 is over in ten seconds and ends handing the turn back', () {
    for (final TapAnswerActivity a in items) {
      for (int level = 1; level <= 3; level++) {
        final HintPlan p = planOf(a, level, ActivitySpec.phone)!;
        expect(p.frames, isNotEmpty, reason: '${a.id} level $level');
        for (final HintFrame f in p.frames) {
          expect(f.hold, greaterThan(Duration.zero), reason: '${a.id} level $level');
        }
        expect(p.endsDemo, level == 3, reason: '${a.id} level $level');
        if (level == 3) {
          expect(p.length, lessThanOrEqualTo(const Duration(seconds: 10)), reason: '${a.id}: ${p.length}');
        }
      }
    }
  });

  test('level 1 and 2 never mark the answer: no hand, nothing outside the stage, every tile glows alike or none does', () {
    for (final ActivitySpec board in boards) {
      for (final TapAnswerActivity a in items) {
        final Size room = stageOf(BlockLayout.of(a, board));
        for (int level = 1; level <= 2; level++) {
          final HintPlan p = planOf(a, level, board)!;
          expect(marksOf(p).whereType<HandMark>(), isEmpty, reason: '${a.id} level $level draws no hand');
          for (final HintMark m in marksOf(p)) {
            final Rect? r = switch (m) {
              RingMark() => m.rect,
              CardMark() => m.rect,
              BlocksMark() => m.rect,
              ChartMark() => m.rect,
              BlockMark() => m.rect,
              PathMark() => m.rect,
              _ => null,
            };
            if (r == null) continue;
            expect(r.left, greaterThanOrEqualTo(-1), reason: '${a.id} level $level on ${board.stage}: $m');
            expect(r.top, greaterThanOrEqualTo(-1), reason: '${a.id} level $level on ${board.stage}: $m');
            expect(
              r.right,
              lessThanOrEqualTo(room.width + 1),
              reason: '${a.id} level $level on ${board.stage}: $m',
            );
            expect(
              r.bottom,
              lessThanOrEqualTo(room.height + 1),
              reason: '${a.id} level $level on ${board.stage}: $m',
            );
          }
          final Set<int> lit = <int>{
            for (final HintFrame f in p.frames)
              if (f.litOption != null) f.litOption!,
          };
          expect(lit.isEmpty || lit.length == a.options.length, isTrue, reason: '${a.id} level $level');
        }
      }
    }
  });

  test('level 3 is the hand: it ends on the right tile, or on the key that gives the number', () {
    for (final TapAnswerActivity a in items) {
      final ActivitySpec laid = BlockLayout.of(a, ActivitySpec.phone);
      final TapGeometry g = TapGeometry(a, stageOf(laid), laid);
      final HintPlan p = planOf(a, 3, ActivitySpec.phone)!;
      final HandMark last = p.frames.last.marks.whereType<HandMark>().single;
      final Offset tip = a.numberAnswer != null ? g.keyTip('done') : g.optionTip(g.correctIndex);
      expect((last.tip - tip).distance, lessThan(0.5), reason: a.id);
      expect(kinds(p), contains('HandMark'), reason: a.id);
    }
  });

  test('each level draws something the level below does not, and the hand is level 3 only', () {
    for (final TapAnswerActivity a in items) {
      final Set<String> k1 = kinds(planOf(a, 1, ActivitySpec.phone)!);
      final Set<String> k2 = kinds(planOf(a, 2, ActivitySpec.phone)!);
      final Set<String> k3 = kinds(planOf(a, 3, ActivitySpec.phone)!);
      expect(
        k2.difference(k1).isNotEmpty || k1.difference(k2).isNotEmpty,
        isTrue,
        reason: '${a.id}: $k1 vs $k2',
      );
      expect(k3.difference(k2).isNotEmpty, isTrue, reason: '${a.id}: $k2 vs $k3');
      expect(k1.contains('HandMark') || k2.contains('HandMark'), isFalse, reason: a.id);
    }
  });

  test('blocks are as large as the stage allows: a cube is at least 7 points beside a row on the stage, 7 in a hint', () {
    for (final ActivitySpec board in boards) {
      for (final TapAnswerActivity a in items) {
        // The cube of an item that has blocks on its own is held to 12 points by `c1_block_units_test.dart`; here the number sentences
        // that keep a row under the rods (no more than the picture's share of the stage) and the cards of the hints.
        if (TapGeometry.groupAndRow(a) && BlockLayout.onStage(a)) {
          expect(
            BlockLayout.unitOf(a, board)!,
            greaterThanOrEqualTo(7),
            reason: '${a.id} on ${board.stage}: a cube beside a row',
          );
        }
        for (int level = 2; level <= 3; level++) {
          for (final HintMark m in marksOf(planOf(a, level, board)!)) {
            if (m is! BlocksMark || m.full.blocks == 0) continue;
            final double unit = BaseTenLayout.forBox(m.full, m.rect.size).unit;
            expect(unit, greaterThanOrEqualTo(7), reason: '${a.id} level $level on ${board.stage}: $unit');
          }
        }
      }
    }
  });

  test('level 3 of an item with rods counts the cubes of a rod, each lit as its number comes (docs/design/c1-blocks.md section 6)', () {
    for (final ActivitySpec board in boards) {
      // 34 as blocks: the first rod is counted in place, ten cubes in turn.
      final HintPlan plain = planOf(
        items.firstWhere((TapAnswerActivity a) => a.id == 'c.numc03.18'),
        3,
        board,
      )!;
      final List<int> counted = <int>[
        for (final HintFrame f in plain.frames)
          for (final HintMark m in f.marks)
            if (m is CubeLitMark) m.lit,
      ];
      expect(counted, <int>[1, 2, 3, 4, 5, 6, 7, 8, 9, 10], reason: 'on ${board.stage}');
      final CubeLitMark last = plain.frames.expand((HintFrame f) => f.marks).whereType<CubeLitMark>().last;
      expect(last.cells, hasLength(10));
      expect(last.cells.map((Rect c) => c.width).toSet(), hasLength(1), reason: 'ten cubes of one size');
      expect(last.cells.first.top, lessThan(last.cells.last.top), reason: 'counted from the top down');
    }
  });

  test('a question about one rod (lit, or taken away) breaks it into ten loose cubes in a card, and counts those', () {
    for (final ActivitySpec board in boards) {
      for (final String id in <String>['c.numc03.24', 'c.mathc03.17']) {
        final HintPlan plan = planOf(items.firstWhere((TapAnswerActivity a) => a.id == id), 3, board)!;
        final List<HintMark> all = <HintMark>[for (final HintFrame f in plan.frames) ...f.marks];
        expect(
          all.whereType<BlocksMark>().any((BlocksMark m) => m.full.ones == 10 && m.full.tens == 0),
          isTrue,
          reason: '$id on ${board.stage}: the ten loose cubes',
        );
        final List<CubeLitMark> lit = all.whereType<CubeLitMark>().toList();
        expect(lit.map((CubeLitMark m) => m.lit).toSet(), <int>{1, 2, 3, 4, 5, 6, 7, 8, 9, 10}, reason: id);
        // The rod comes first and stands whole, before it breaks.
        final int rodOnly = plan.frames.indexWhere(
          (HintFrame f) =>
              f.marks.whereType<BlocksMark>().length == 1 && f.marks.whereType<CubeLitMark>().isEmpty,
        );
        final int broken = plan.frames.indexWhere(
          (HintFrame f) => f.marks.whereType<BlocksMark>().any((BlocksMark m) => m.full.ones == 10),
        );
        expect(rodOnly, lessThan(broken), reason: id);
      }
    }
  });

  test('SEC-M10-8: a coin sprite with a long run of digits is no coin, and the hint is the generic one, not an exception', () async {
    final PackContent hostile = await loadSourcePack(
      edit: (Map<String, Object?> docs) {
        final Map<String, Object?> scene =
            (docs['activity.c.numc03.12.json']! as Map<String, Object?>)['scene']! as Map<String, Object?>;
        (scene['group']! as Map<String, Object?>)['sprite'] = 'asset:coin_s${'9' * 30}';
      },
    );
    final TapAnswerActivity a = hostile.activities['c.numc03.12']! as TapAnswerActivity;
    expect(a.group!.sprite, endsWith('9' * 30));
    for (final ActivitySpec board in boards) {
      for (int level = 1; level <= 3; level++) {
        late HintPlan? p;
        expect(() => p = planOf(a, level, board), returnsNormally, reason: 'level $level');
        expect(p, isNotNull);
      }
    }
    expect(planOf(a, 3, ActivitySpec.phone)!.endsDemo, isTrue);
  });
}
