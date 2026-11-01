import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/child/activity_shell.dart';
import 'package:nitznutz/content/models.dart';
import 'package:nitznutz/play/hint_hand.dart';
import 'package:nitznutz/play/hints/hint_marks.dart';
import 'package:nitznutz/play/hints/tap_geometry.dart';
import 'package:nitznutz/play/hints/tap_plans.dart';
import 'package:nitznutz/play/hint_widgets.dart';

/// B-36 part G: the hint pictures of the second-way items of part D (`tap_plans_c.dart`). They are read from the pack sources, so
/// the test holds before the new pack is signed and bundled: the plate to pick out of a pile, zero, a numeral written the right way,
/// a pile counted in twos, the value of each coin, the part that hides behind a stone, and the plates of ten and more.
void main() {
  const String sources = '../content/starter';
  late Map<String, String> svg;

  setUpAll(() {
    final Map<String, Object?> pack =
        jsonDecode(File('$sources/pack.json').readAsStringSync()) as Map<String, Object?>;
    svg = <String, String>{
      for (final Object? a in pack['assets']! as List<Object?>)
        (a! as Map<String, Object?>)['id']! as String: File('$sources/${(a as Map<String, Object?>)['file']}')
            .readAsStringSync(),
    };
  });

  TapAnswerActivity item(String id) => Activity.fromJson(
    jsonDecode(File('$sources/activity.$id.json').readAsStringSync()) as Map<String, Object?>,
    PackAssets(svg),
  ) as TapAnswerActivity;

  Size stageOf(ActivitySpec s) =>
      s.stageIsCard ? Size(s.stage.width - 32, s.stage.height - 32) : s.stage.size;

  final List<ActivitySpec> boards = <ActivitySpec>[
    ActivitySpec.phone,
    ActivitySpec.phoneSE,
    ActivitySpec.tabletLandscape,
    ActivitySpec.tabletPortrait,
  ];

  HintPlan plan(TapAnswerActivity a, int level, [ActivitySpec spec = ActivitySpec.phone]) =>
      tapHintPlan(a, TapGeometry(a, stageOf(spec), spec), level)!;

  Iterable<HintMark> marks(HintPlan p) sync* {
    for (final HintFrame f in p.frames) {
      yield* f.marks;
    }
    yield* p.rest;
  }

  bool isQuestionCard(HintPlan p) {
    final HintMark only = p.rest.length == 1 ? p.rest.single : const VeilMark(<Rect>[]);
    return only is CardMark && only.child is Text && (only.child as Text).data == '?';
  }

  const List<String> second = <String>[
    'b36.numa06.1',
    'b36.numa06.2',
    'b36.numa14.1',
    'b36.numa14.2',
    'b.numb05.11',
    'b.numb05.12',
    'x.numb07.21',
    'x.numb07.22',
    'b.numb08.15',
    'b.numb08.16',
    'b.numb17.13',
    'x.mathb17.12',
    'x.mathb17.13',
    'b.mathb07.9',
    'b.mathb07.10',
    'b.mathb08.15',
    'b.mathb08.16',
    'b.mathb18.10',
    'b.mathb18.11',
    'b.shpb08.10',
    'b15.shpa07.2',
  ];

  test('every second-way item has a picture of its own at each level, on every board, and a demonstration under 10 seconds', () {
    for (final String id in second) {
      final TapAnswerActivity a = item(id);
      for (final ActivitySpec board in boards) {
        for (int level = 1; level <= 3; level++) {
          final HintPlan p = plan(a, level, board);
          expect(p.frames, isNotEmpty, reason: '$id level $level');
          for (final HintFrame f in p.frames) {
            expect(f.hold, greaterThan(Duration.zero), reason: '$id level $level');
          }
          if (level == 2) expect(isQuestionCard(p), isFalse, reason: '$id: level 2 is the generic card');
          if (level < 3) {
            expect(marks(p).whereType<HandMark>(), isEmpty, reason: '$id level $level has no hand');
          } else {
            expect(p.endsDemo, isTrue, reason: id);
            expect(p.length, lessThanOrEqualTo(const Duration(seconds: 10)), reason: '$id: ${p.length}');
            final HandMark last = p.frames.last.marks.whereType<HandMark>().single;
            final TapGeometry g = TapGeometry(a, stageOf(board), board);
            expect(
              (last.tip - g.optionTip(g.correctIndex)).distance,
              lessThan(0.5),
              reason: '$id ends on the answer',
            );
          }
        }
      }
    }
  });

  test(
    'a plate out of a pile: the asked number on fingers beside the pile, counted up one finger at a time',
    () {
      for (final (String, int) c in <(String, int)>[('b36.numa06.1', 3), ('b36.numa06.2', 2)]) {
        final TapAnswerActivity a = item(c.$1);
        final List<CardMark> card = plan(a, 2).rest.whereType<CardMark>().toList();
        expect(card, hasLength(1), reason: c.$1);
        expect((card.single.child as HintHand).fingers, c.$2, reason: c.$1);
        final HintPlan l3 = plan(a, 3);
        final List<int> raised = <int>[
          for (final HintFrame f in l3.frames)
            for (final CardMark m in f.marks.whereType<CardMark>())
              if (m.child is HintHand) (m.child as HintHand).fingers,
        ];
        expect(raised, <int>[for (int j = 0; j <= c.$2; j++) j, c.$2], reason: c.$1);
      }
    },
  );

  test('zero on the stage is an empty ten-frame, and level 1 lights the numeral', () {
    for (final String id in <String>['b36.numa14.1', 'b36.numa14.2']) {
      final TapAnswerActivity a = item(id);
      expect(plan(a, 1).frames.single.marks.whereType<VeilMark>(), hasLength(1), reason: id);
      final TenFrames frame = plan(a, 2).rest.whereType<CardMark>().single.child as TenFrames;
      expect(frame.filled, 0, reason: id);
    }
  });

  test(
    'a numeral written the right way: its sample is the numeral of the name, never the glyph on a tile',
    () {
      for (final (String, int) c in <(String, int)>[('x.numb07.21', 3), ('x.numb07.22', 7)]) {
        final TapAnswerActivity a = item(c.$1);
        final List<BadgeMark> sample = plan(a, 2).rest.whereType<BadgeMark>().toList();
        expect(sample.single.n, c.$2, reason: c.$1);
        expect(
          marks(plan(a, 2)).whereType<CopyMark>(),
          isEmpty,
          reason: '${c.$1}: no tile picture is copied',
        );
      }
    },
  );

  test('plates of ten and more (NUM-B-05, NUM-B-08) are the teens picture of their number', () {
    for (final (String, int) c in <(String, int)>[
      ('b.numb05.11', 12),
      ('b.numb05.12', 16),
      ('b.numb08.15', 13),
      ('b.numb08.16', 17),
    ]) {
      final TapAnswerActivity a = item(c.$1);
      final TenFrames frames = plan(a, 2).rest.whereType<CardMark>().single.child as TenFrames;
      expect(frames.total, c.$2, reason: c.$1);
      expect(frames.filled, c.$2, reason: c.$1);
    }
  });

  test('a pile counted in twos is ringed pair by pair with the count so far', () {
    final TapAnswerActivity a = item('b.numb17.13');
    final List<int> said = <int>[for (final BadgeMark m in plan(a, 2).rest.whereType<BadgeMark>()) m.n];
    expect(said, <int>[2, 4, 6, 8, 10]);
    expect(plan(a, 2).rest.whereType<RingMark>(), hasLength(5));
    expect(plan(a, 3).frames.last.marks.whereType<BadgeMark>().where((BadgeMark m) => m.big).single.n, 10);
  });

  test('the coins of a chart show their own value, and the hand keeps a running sum', () {
    final TapAnswerActivity a = item('x.mathb17.12');
    expect(<int>[for (final BadgeMark m in plan(a, 2).rest.whereType<BadgeMark>()) m.n], <int>[5, 2, 1]);
    expect(
      <int>[for (final BadgeMark m in plan(a, 3).frames.last.marks.whereType<BadgeMark>()) m.n],
      <int>[5, 7, 8],
    );
    final TapAnswerActivity b = item('x.mathb17.13');
    expect(<int>[for (final BadgeMark m in plan(b, 2).rest.whereType<BadgeMark>()) m.n], <int>[10, 2, 2]);
    expect(
      <int>[for (final BadgeMark m in plan(b, 3).frames.last.marks.whereType<BadgeMark>()) m.n],
      <int>[10, 14],
    );
  });

  test('the part that hides: a frame of the whole with the seen filled, the empty places counted last', () {
    for (final (String, int, int) c in <(String, int, int)>[('b.mathb18.10', 3, 4), ('b.mathb18.11', 5, 4)]) {
      final TapAnswerActivity a = item(c.$1);
      final List<BlockMark> cells = plan(a, 2).rest.whereType<BlockMark>().toList();
      expect(cells, hasLength(c.$2 + c.$3), reason: c.$1);
      expect(cells.where((BlockMark b) => b.empty), hasLength(c.$3), reason: c.$1);
      expect(plan(a, 3).frames.last.marks.whereType<BadgeMark>().single.n, c.$3, reason: c.$1);
    }
  });

  test('the cube is drawn as a cube, and it stacks like a box', () {
    final TapAnswerActivity ask = item('b.shpb08.10');
    expect(marks(plan(ask, 2)).whereType<GhostMark>().first.kind, GhostKind.box);
    final TapAnswerActivity stack = item('b15.shpa07.2');
    final List<CopyMark> drawn = plan(stack, 2).rest.whereType<CopyMark>().toList();
    expect(drawn, hasLength(4), reason: 'two solids and a second one of each');
  });
}
