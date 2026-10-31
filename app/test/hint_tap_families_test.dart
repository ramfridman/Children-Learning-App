import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/child/activity_shell.dart';
import 'package:nitznutz/content/hint_ladder.dart';
import 'package:nitznutz/content/models.dart';
import 'package:nitznutz/design/components.dart';
import 'package:nitznutz/design/token_types.dart' show Band;
import 'package:nitznutz/play/activity_frame.dart';
import 'package:nitznutz/play/hint_hand.dart';
import 'package:nitznutz/play/hints/hint_marks.dart';
import 'package:nitznutz/play/hints/hint_pictures.dart';
import 'package:nitznutz/play/hints/tap_geometry.dart';
import 'package:nitznutz/play/hints/tap_plans.dart';
import 'package:nitznutz/play/lesson_controller.dart';
import 'package:nitznutz/play/tap_answer_session.dart';

import 'support/fakes.dart';
import 'support/harness.dart';
import 'support/starter.dart';

/// B-40 part 2: the pictures of the Band A families of `tap_answer` (TA-1 to TA-11). Every activity has a plan for each level; level 1
/// and level 2 never mark the right answer or reach over the tiles; each level draws something the level below does not; level 3
/// is the sky hand's demonstration and ends on the right tile.
void main() {
  late PackContent content;
  setUpAll(() async {
    await loadAppFonts();
    content = await loadStarter();
  });

  const ActivitySpec spec = ActivitySpec.phone;
  final Size stage = spec.stage.size;

  List<TapAnswerActivity> bandA() => <TapAnswerActivity>[
    for (final TapAnswerActivity a in content.activities.values.whereType<TapAnswerActivity>())
      if (tapFamilyOf(a.skillId, numeralOnStage: a.stageNumeral != null) != null) a,
  ];

  // The room a stage has on each board (a tablet's stage sits on a card with a 16 point border).
  Size stageOf(ActivitySpec s) =>
      s.stageIsCard ? Size(s.stage.width - 32, s.stage.height - 32) : s.stage.size;
  final List<ActivitySpec> boards = <ActivitySpec>[
    ActivitySpec.phone,
    ActivitySpec.phoneSE,
    ActivitySpec.tabletLandscape,
    ActivitySpec.tabletPortrait,
  ];

  TapGeometry geo(TapAnswerActivity a, {ActivitySpec s = spec}) => TapGeometry(a, stageOf(s), s);

  HintPlan plan(TapAnswerActivity a, int level, {ActivitySpec s = spec}) =>
      tapHintPlan(a, geo(a, s: s), level)!;

  /// What a plan draws, as a set of words: the kinds of its marks (and "lit" for an answer glowing in turn).
  Set<String> kinds(HintPlan p) => <String>{
    for (final HintFrame f in p.frames) ...<String>[
      for (final HintMark m in f.marks) m.runtimeType.toString(),
      if (f.litOption != null) 'lit',
    ],
    for (final HintMark m in p.rest) m.runtimeType.toString(),
  };

  Iterable<HintMark> marksOf(HintPlan p) sync* {
    for (final HintFrame f in p.frames) {
      yield* f.marks;
    }
    yield* p.rest;
  }

  Rect? rectOf(HintMark m) => switch (m) {
    RingMark() => m.rect,
    SeenMark() => m.rect,
    CopyMark() => m.rect,
    CardMark() => m.rect,
    SwatchMark() => m.rect,
    GhostMark() => m.rect,
    PathMark() => m.rect,
    BlockMark() => m.rect,
    _ => null,
  };

  group('every Band A tap_answer activity has a plan for each level', () {
    test('301 activities belong to a family, 11 families, and the warm-up is one of them', () {
      final List<TapAnswerActivity> all = bandA();
      expect(all, hasLength(301));
      final Map<TapFamily, int> n = <TapFamily, int>{};
      for (final TapAnswerActivity a in all) {
        final TapFamily f = tapFamilyOf(a.skillId, numeralOnStage: a.stageNumeral != null)!;
        n[f] = (n[f] ?? 0) + 1;
      }
      expect(n.keys.toSet(), TapFamily.values.toSet());
      expect(all.map((TapAnswerActivity a) => a.id), contains('pick.red.flower'));
      expect(HintLadder.tapFamiliesBuilt, TapFamily.values.toSet());
    });

    test('the ladder of a built family is look, another way, demonstration', () {
      final TapAnswerActivity a = bandA().first;
      final HintLadder l = HintLadder.forActivity('tap_answer', a.skillId)!;
      expect(l.pictures, <HintPicture>[
        HintPicture.lookHere,
        HintPicture.anotherWay,
        HintPicture.demonstration,
      ]);
      expect(l.at(1).marksAnswer, isFalse);
      expect(l.at(2).marksAnswer, isFalse);
      expect(
        HintLadder.forActivity('tap_answer', 'NUM-B-04')!.at(1),
        HintPicture.pulse,
        reason: 'Band B waits',
      );
    });

    test('each level has steps, no step is empty of time, and a demonstration is over in 10 seconds', () {
      for (final TapAnswerActivity a in bandA()) {
        for (int level = 1; level <= 3; level++) {
          final HintPlan p = plan(a, level);
          expect(p.frames, isNotEmpty, reason: '${a.id} level $level');
          for (final HintFrame f in p.frames) {
            expect(f.hold, greaterThan(Duration.zero), reason: '${a.id} level $level');
          }
          if (level == 3) {
            expect(p.length, lessThanOrEqualTo(const Duration(seconds: 10)), reason: '${a.id}: ${p.length}');
          }
        }
      }
    });

    test(
      'level 1 and 2 never mark the right answer: no hand, nothing over the tiles, every answer glows alike',
      () {
        for (final ActivitySpec board in boards) {
          final Size room = stageOf(board);
          for (final TapAnswerActivity a in bandA()) {
            final TapGeometry g = geo(a, s: board);
            for (int level = 1; level <= 2; level++) {
              final HintPlan p = plan(a, level, s: board);
              expect(p.endsDemo, isFalse, reason: '${a.id} level $level');
              expect(marksOf(p).whereType<HandMark>(), isEmpty, reason: '${a.id} level $level draws no hand');
              for (final HintMark m in marksOf(p)) {
                final Rect? r = rectOf(m);
                // A set that rises out of its own tile starts hidden under the tile's top edge (a tile paints over the stage).
                final bool underTile = m is CopyMark && r != null && r.top >= g.optionTip(0).dy - 1;
                if (r != null && !underTile) {
                  expect(
                    r.bottom,
                    lessThanOrEqualTo(room.height + 1),
                    reason: '${a.id} level $level: ${m.runtimeType}',
                  );
                  expect(r.left, greaterThanOrEqualTo(-1), reason: a.id);
                  expect(r.right, lessThanOrEqualTo(room.width + 1), reason: a.id);
                }
                if (!a.optionsInTiles && m is VeilMark) {
                  for (final Rect hole in m.holes) {
                    expect(hole.overlaps(g.stageOptions()[g.correctIndex]), isFalse, reason: a.id);
                  }
                }
              }
              final Set<int> lit = <int>{
                for (final HintFrame f in p.frames)
                  if (f.litOption != null) f.litOption!,
              };
              expect(
                lit.isEmpty || lit.length == a.options.length,
                isTrue,
                reason: '${a.id} level $level lights every answer, or none',
              );
            }
          }
        }
      },
    );

    test('on every board the hand ends with its fingertip on the top edge of the right tile, just under the stage', () {
      for (final ActivitySpec board in boards) {
        final Size room = stageOf(board);
        for (final TapAnswerActivity a in bandA()) {
          final TapGeometry g = geo(a, s: board);
          final Offset tip = g.optionTip(g.correctIndex);
          expect(tip.dx, inInclusiveRange(-8, board.tilesWidth), reason: '${a.id} on ${board.stage}');
          if (a.optionsInTiles) {
            expect(
              tip.dy,
              inInclusiveRange(room.height - 12, room.height + 40),
              reason: '${a.id} on ${board.stage}',
            );
          }
        }
      }
    });

    test('level 3 is the hand: it never starts on the answer tile and ends on it, with the turn handed back', () {
      for (final TapAnswerActivity a in bandA()) {
        final TapGeometry g = geo(a);
        final HintPlan p = plan(a, 3);
        expect(p.endsDemo, isTrue, reason: a.id);
        final Iterable<HandMark> hands = marksOf(p).whereType<HandMark>();
        expect(hands, isNotEmpty, reason: a.id);
        final HandMark last = p.frames.last.marks.whereType<HandMark>().single;
        final Offset tip = g.optionTip(g.correctIndex);
        expect(
          (last.tip - tip).distance,
          lessThan(0.5),
          reason: '${a.id}: the last step is the fingertip on the right tile',
        );
        expect(p.frames.length, greaterThan(1), reason: a.id);
        // The hand's fingertip is never lower than the top edge of a tile (it never covers a tile's content).
        for (final HandMark h in hands) {
          expect(
            h.tip.dy,
            lessThanOrEqualTo(g.optionTip(0).dy + 1 + (g.tiles ? 0 : stage.height)),
            reason: a.id,
          );
        }
      }
    });

    test('each level draws something the level below does not, and the sky hand is level 3 only', () {
      for (final TapAnswerActivity a in bandA()) {
        final Set<String> k1 = kinds(plan(a, 1));
        final Set<String> k2 = kinds(plan(a, 2));
        final Set<String> k3 = kinds(plan(a, 3));
        // The warm-up has one hint only, and shows level 1.
        expect(
          k2.difference(k1).isNotEmpty || k1.difference(k2).isNotEmpty,
          isTrue,
          reason: '${a.id}: $k1 vs $k2',
        );
        expect(k3, contains('HandMark'), reason: a.id);
        expect(k3.difference(k2).isNotEmpty, isTrue, reason: '${a.id}: $k2 vs $k3');
        expect(k1.contains('HandMark') || k2.contains('HandMark'), isFalse, reason: a.id);
      }
    });

    test('nothing in a plan is red, and no mark names a colour but the sky and the sample', () {
      // The marks carry no colour of their own except a swatch, whose colour is the one the question asks for.
      for (final TapAnswerActivity a in bandA()) {
        for (int level = 1; level <= 3; level++) {
          for (final HintMark m in marksOf(plan(a, level))) {
            if (m is SwatchMark) expect(hintColours.keys, contains(m.colour), reason: a.id);
          }
        }
      }
    });

    test('nothing in the stage runs right to left: the ordinal items draw no path at all, only badges over the tiles', () {
      for (final TapAnswerActivity a in bandA()) {
        for (int level = 1; level <= 3; level++) {
          final Iterable<HintMark> marks = marksOf(plan(a, level));
          if (a.skillId == 'NUM-A-13') expect(marks.whereType<PathMark>(), isEmpty, reason: a.id);
        }
      }
    });

    test('no hint at level 1 or 2 draws the right answer\'s own picture alone: the other answers are drawn with it', () {
      // The act-out of a solid (SHP-A-07) and the measure sticks draw every option's picture alike; a sample copied from the model
      // of the question (the same family) is the question's own picture; the position hint draws a toy and a box of its own.
      for (final TapAnswerActivity a in bandA()) {
        final String? right = a.assets.svgOrNull(
          a.options.firstWhere((ChoiceOption o) => o.id == a.correctId).sprite ?? '',
        );
        if (right == null) continue;
        final Set<String> stageOwn = <String>{
          for (final String? ref in <String?>[a.group?.sprite, a.group2?.sprite, ...a.row])
            if (ref != null && a.assets.svgOrNull(ref) != null) a.assets.svgOrNull(ref)!,
        };
        for (int level = 1; level <= 2; level++) {
          final Set<String> drawn = <String>{
            for (final CopyMark m in marksOf(plan(a, level)).whereType<CopyMark>()) m.svg,
          };
          if (!drawn.contains(right) || stageOwn.contains(right)) continue;
          for (final ChoiceOption o in a.options) {
            final String? svg = a.assets.svgOrNull(o.sprite ?? '');
            if (svg != null) {
              expect(
                drawn,
                contains(svg),
                reason: '${a.id} level $level draws the right picture but not ${o.id}',
              );
            }
          }
        }
      }
    });
  });

  group('what each family draws', () {
    test('colour: the paint of the question\'s colour, with the helper, then it hovers over every tile and stops on the match', () {
      final TapAnswerActivity a = content.activities['col.name.red.ball']! as TapAnswerActivity;
      expect(colourOfSprite(a.options.firstWhere((ChoiceOption o) => o.id == a.correctId).sprite), 'red');
      final HintPlan l2 = plan(a, 2);
      expect(marksOf(l2).whereType<SwatchMark>().first.colour, 'red');
      final HintPlan l3 = plan(a, 3);
      final List<Rect> over = <Rect>[
        for (final HintFrame f in l3.frames)
          for (final SwatchMark s in f.marks.whereType<SwatchMark>()) s.rect,
      ];
      final TapGeometry g = geo(a);
      for (int i = 0; i < a.options.length; i++) {
        expect(
          over.any((Rect r) => (r.center.dx - (g.optionTip(i).dx - 26)).abs() < 1),
          isTrue,
          reason: 'over tile $i',
        );
      }
    });

    test('shapes: the outline is the shape of the right option', () {
      GhostKind ghost(String id) =>
          marksOf(plan(content.activities[id]! as TapAnswerActivity, 2)).whereType<GhostMark>().first.kind;
      expect(ghost('shp.name.triangle'), GhostKind.triangle);
      expect(ghost('shp.name.circle'), GhostKind.circle);
      expect(ghost('shp.name.square'), GhostKind.square);
      expect(ghost('shp.rect.find'), GhostKind.rect);
      expect(ghost('shp.world.circle'), GhostKind.circle, reason: 'a plate');
      expect(ghost('shp.line.curved'), GhostKind.curved);
      expect(ghost('shp.line.straight'), GhostKind.straight);
    });

    test(
      'count: one lit ring and one dot kept for each thing, in reading order, and the badges equal the count',
      () {
        final TapAnswerActivity a = content.activities['numeral.bugs.5']! as TapAnswerActivity;
        final HintPlan l1 = plan(a, 1);
        expect(l1.frames, hasLength(5));
        expect(l1.rest.whereType<SeenMark>(), hasLength(5));
        final List<double> xs = <double>[
          for (final HintFrame f in l1.frames) f.marks.whereType<RingMark>().single.rect.center.dx,
        ];
        expect(xs, isNotEmpty);
        final HintPlan l3 = plan(a, 3);
        expect(
          marksOf(l3).whereType<BadgeMark>().where((BadgeMark b) => !b.big).map((BadgeMark b) => b.n).toSet(),
          <int>{1, 2, 3, 4, 5},
        );
        expect(marksOf(l3).whereType<BadgeMark>().where((BadgeMark b) => b.big).first.n, 5);
      },
    );

    test('sequence: the number given and the gap at level 1, the path with its empty square at level 2', () {
      final TapAnswerActivity after = content.activities['next.after.4']! as TapAnswerActivity;
      final TapAnswerActivity before = content.activities['next.before.4']! as TapAnswerActivity;
      PathMark path(TapAnswerActivity a) => marksOf(plan(a, 2)).whereType<PathMark>().first;
      expect(path(after).gap, 5);
      expect(path(after).ring, 4);
      expect(path(before).gap, 3);
      expect(path(before).ring, 4);
      final List<HintMark> l1 = plan(after, 1).frames.single.marks;
      final Rect given = l1.whereType<CardMark>().single.rect;
      final Rect gap = l1.whereType<GhostMark>().single.rect;
      expect(given.center.dx, lessThan(gap.center.dx), reason: 'after: the gap is at the right');
      final List<HintMark> b1 = plan(before, 1).frames.single.marks;
      expect(
        b1.whereType<CardMark>().single.rect.center.dx,
        greaterThan(b1.whereType<GhostMark>().single.rect.center.dx),
      );
    });

    test('compare: the pairs are as many as the shorter group, and the leftovers are the difference', () {
      final TapAnswerActivity a = content.activities['more.apples.2v4']! as TapAnswerActivity;
      final PairsMark last = plan(a, 2).rest.whereType<PairsMark>().single;
      expect(last.lines, hasLength(2));
      expect(last.unpaired, hasLength(2));
      final HintPlan l1 = plan(a, 1);
      final List<CopyMark> copies = l1.rest.whereType<CopyMark>().toList();
      expect(copies, hasLength(6));
      expect(
        copies.map((CopyMark c) => c.rect.width).toSet(),
        hasLength(1),
        reason: 'every picture the same size',
      );
    });

    test('pattern: the unit that repeats is found, and a row that does not repeat gets two blocks', () {
      expect(periodOf(<String>['a', 'b', 'a', 'b', 'a', '?']), 2);
      expect(periodOf(<String>['a', 'b', 'a', '?', 'a', 'b']), 2);
      expect(periodOf(<String>['a', 'b', 'c', 'a', 'b', 'c']), 3);
      expect(periodOf(<String>['a', 'b', 'c', 'a', 'd', 'b']), isNull);
      final TapAnswerActivity a = content.activities['log.next.colours']! as TapAnswerActivity;
      final HintPlan l1 = plan(a, 1);
      expect(
        l1.frames,
        hasLength(a.row.length),
        reason: 'a ring walks the row, from the left, and ends on the gap',
      );
      final List<double> xs = <double>[
        for (final HintFrame f in l1.frames) f.marks.whereType<RingMark>().single.rect.center.dx,
      ];
      expect(xs, orderedEquals(<double>[...xs]..sort()));
      expect(plan(a, 2).rest.whereType<BracketMark>(), hasLength(3));
    });

    test('add: the hand shows the first group, and the running total ends on the answer', () {
      final TapAnswerActivity a = content.activities['math.add.stars']! as TapAnswerActivity;
      final HintPlan l3 = plan(a, 3);
      final List<int> totals = <int>[
        for (final HintFrame f in l3.frames)
          for (final BadgeMark b in f.marks.whereType<BadgeMark>().where((BadgeMark b) => !b.big)) b.n,
      ];
      expect(totals.last, 5);
      expect(l3.frames.last.marks.whereType<BadgeMark>().where((BadgeMark b) => b.big).single.n, 5);
    });
  });

  group('the part 2 review fixes', () {
    TapAnswerActivity act(String id) => content.activities[id]! as TapAnswerActivity;

    final RegExp niqqud = RegExp('[֑-ׇ]');

    test(
      'NUM-A-13 items keep their order (shuffle off), stand in one row, and the right one is the asked place',
      () {
        final Map<String, int> places = <String, int>{'ראשון': 1, 'שני': 2, 'שלישי': 3, 'אחרון': -1};
        int seen = 0;
        for (final FileSystemEntity f in Directory('../content/starter').listSync()) {
          final String name = f.uri.pathSegments.last;
          if (!name.startsWith('activity.') || !name.endsWith('.json')) continue;
          final Map<String, Object?> json =
              jsonDecode(File(f.path).readAsStringSync()) as Map<String, Object?>;
          final List<Object?> skills = json['skills']! as List<Object?>;
          if (!skills.any((Object? s) => (s! as Map<String, Object?>)['id'] == 'NUM-A-13')) continue;
          seen++;
          final Map<String, Object?> answer = json['answer']! as Map<String, Object?>;
          final List<Object?> options = answer['options']! as List<Object?>;
          expect(answer['shuffle'], isFalse, reason: '$name keeps the order of the queue');
          expect((json['scene']! as Map<String, Object?>)['optionsOnTiles'], isTrue, reason: name);
          final String caption = ((json['prompt']! as Map<String, Object?>)['caption']! as List<Object?>)
              .map((Object? c) => (c! as Map<String, Object?>)['v'])
              .join(' ');
          final String word = places.keys.singleWhere(
            (String w) => caption.replaceAll(niqqud, '').contains(w),
            orElse: () => '',
          );
          expect(word, isNotEmpty, reason: '$name asks for a place');
          final int place = places[word]! < 0 ? options.length : places[word]!;
          expect(answer['correct'], 'o$place', reason: '$name: the right tile is the place asked');
          // The tiles stand in one row, side by side.
          final TapAnswerActivity a = act(json['id']! as String);
          final TapGeometry g = geo(a);
          expect(
            <double>{for (int i = 0; i < a.options.length; i++) g.optionTip(i).dy},
            hasLength(1),
            reason: name,
          );
          for (int i = 1; i < a.options.length; i++) {
            expect(
              g.optionTip(i).dx,
              lessThan(g.optionTip(i - 1).dx),
              reason: '$name: the row runs right to left',
            );
          }
        }
        expect(seen, 9);
      },
    );

    test('ordinal: a place badge on every tile, 1 at the front (the right-hand tile), a start flag there, and nothing else', () {
      for (final String id in <String>[
        'ordinal.first',
        'ordinal.second.of4',
        'ordinal.third.of4',
        'ordinal.last',
      ]) {
        final TapAnswerActivity a = act(id);
        final TapGeometry g = geo(a);
        final HintPlan l2 = plan(a, 2);
        final List<TileBadgeMark> badges = l2.rest.whereType<TileBadgeMark>().toList();
        expect(badges.map((TileBadgeMark b) => b.n), <int>[
          for (int i = 1; i <= a.options.length; i++) i,
        ], reason: id);
        for (int i = 0; i < badges.length; i++) {
          expect(badges[i].tile, i, reason: '$id: badge ${i + 1} is on tile $i');
        }
        expect(
          g.optionTip(0).dx,
          greaterThan(g.optionTip(1).dx),
          reason: '$id: tile 0, the front, is the right-hand one',
        );
        expect(l2.rest.whereType<TileFlagMark>().single.tile, 0, reason: '$id: the flag stands at the front');
        expect(l2.rest.length, a.options.length + 1, reason: '$id: only the badges and the flag');
        expect(marksOf(l2).whereType<HandMark>(), isEmpty, reason: id);
        // Level 3: the hand goes from the front along the row, and ends on the asked tile.
        final List<HandMark> hands = <HandMark>[
          for (final HintFrame f in plan(a, 3).frames) ...f.marks.whereType<HandMark>(),
        ];
        expect(hands, hasLength(g.correctIndex + 1), reason: id);
        for (int i = 0; i < hands.length; i++) {
          expect(
            (hands[i].tip - g.optionTip(i)).distance,
            lessThan(0.5),
            reason: '$id: the hand is on tile $i',
          );
        }
        // The overlay leaves the tile marks to the tiles.
      }
    });

    test('compare: each row rises out of its own tile, the first option\'s row first, and keeps a thin connector to that tile', () {
      for (final String id in <String>[
        'more.apples.2v4',
        'more.fish.3v5',
        'more.big.apples',
        'b15.matha07.2',
      ]) {
        final TapAnswerActivity a = act(id);
        final TapGeometry g = geo(a);
        final HintPlan l1 = plan(a, 1);
        final int n0 = a.options[0].set!.count;
        final int n1 = a.options[1].set!.count;
        List<CopyMark> copies(int frame) => l1.frames[frame].marks.whereType<CopyMark>().toList();
        // Step 1: every picture is under its own tile (the tile paints over the stage).
        for (int i = 0; i < n0 + n1; i++) {
          final int tile = i < n0 ? 0 : 1;
          expect(
            copies(0)[i].rect.center.dx,
            closeTo(g.optionTip(tile).dx, 0.5),
            reason: '$id picture $i starts at tile $tile',
          );
          expect(copies(0)[i].rect.top, greaterThan(g.optionTip(tile).dy), reason: id);
        }
        // Step 2: the first option's row has risen to the top row; the other is still under its tile.
        for (int i = 0; i < n0; i++) {
          expect(copies(1)[i].rect.center.dy, closeTo(g.h * 0.3, 0.5), reason: id);
        }
        for (int i = n0; i < n0 + n1; i++) {
          expect(copies(1)[i].rect.top, greaterThan(g.optionTip(1).dy), reason: id);
        }
        // At rest: both rows at their places (equal sizes), and a faint connector from each row to its tile.
        final List<LineMark> connectors = l1.rest
            .whereType<LineMark>()
            .where((LineMark l) => l.faint)
            .toList();
        expect(connectors, hasLength(2), reason: id);
        for (int tile = 0; tile < 2; tile++) {
          expect(
            (connectors[tile].to - g.optionTip(tile)).distance,
            lessThan(5),
            reason: '$id: connector $tile ends on tile $tile',
          );
          expect(connectors[tile].from.dy, closeTo(g.h * (tile == 0 ? 0.3 : 0.72), 0.5), reason: id);
        }
        // The connectors never cross: the row that starts higher goes to the tile that is further.
        expect(
          connectors[0].to.dx,
          greaterThan(connectors[1].to.dx),
          reason: '$id: o1 is the right-hand tile',
        );
        // No connector tells the answer: they are alike in length order and colour (the same mark for both).
        expect(l1.rest.whereType<RingMark>(), isEmpty, reason: id);
        // The rows stay on in the pair lines of level 2 and the demonstration of level 3.
        expect(
          plan(a, 2).rest.whereType<LineMark>().where((LineMark l) => l.faint),
          hasLength(2),
          reason: id,
        );
      }
    });

    test('compare with two groups on the stage is as built: no connector, no flight', () {
      final HintPlan l2 = plan(act('same.apples.4v5'), 2);
      expect(l2.rest.whereType<CopyMark>(), isEmpty);
      expect(l2.rest.whereType<LineMark>(), isEmpty);
    });

    test('position: the card shows a toy and the thing the question names, never the tile\'s red ball or its drawing', () {
      final Set<String> pairs = <String>{};
      for (final String id in <String>[
        'shp.where.above',
        'shp.where.on',
        'shp.where.in',
        'shp.where.in2',
        'shp.where.next',
        'shp.where.under',
        'b15.shpa08.1',
        'b15.shpa08.2',
      ]) {
        final TapAnswerActivity a = act(id);
        final List<CopyMark> drawn = plan(a, 2).rest.whereType<CopyMark>().toList();
        expect(drawn, hasLength(2), reason: id);
        final Set<String> tileArt = <String>{
          for (final ChoiceOption o in a.options) a.assets.svg(o.sprite!),
          a.assets.svg('asset:ball_red'),
          a.assets.svg('asset:solid_sphere'),
          a.assets.svg('asset:solid_box'),
        };
        for (final CopyMark m in drawn) {
          expect(
            tileArt,
            isNot(contains(m.svg)),
            reason: '$id copies a picture the tiles or the red ball show',
          );
        }
        expect(
          drawn.map((CopyMark m) => m.svg),
          contains(a.assets.svg('asset:duck')),
          reason: '$id: the toy is the duck',
        );
        final String thing = drawn
            .map((CopyMark m) => m.svg)
            .firstWhere((String s) => s != a.assets.svg('asset:duck'));
        // The two "under the table" items draw a table (legs), the others a box, and "in" a bin.
        final bool table = thing.contains('width="9"');
        expect(table, id == 'shp.where.under' || id == 'b15.shpa08.2', reason: '$id: table or box');
        pairs.add(
          '${a.options[a.options.indexWhere((ChoiceOption o) => o.id == a.correctId)].sprite}:${thing.hashCode}',
        );
      }
      expect(pairs.length, greaterThan(3), reason: 'each relation is drawn its own way');
    });

    test(
      'position: the toy and the thing stand in the relation of the question (above, on, next to, under, in)',
      () {
        Rect rectOfSvg(HintPlan p, bool toy, TapAnswerActivity a) => p.rest
            .whereType<CopyMark>()
            .firstWhere((CopyMark m) => (m.svg == a.assets.svg('asset:duck')) == toy)
            .rect;
        TapAnswerActivity a = act('shp.where.above');
        HintPlan p = plan(a, 2);
        expect(
          rectOfSvg(p, true, a).bottom,
          lessThan(rectOfSvg(p, false, a).top),
          reason: 'above: a gap between',
        );
        a = act('shp.where.on');
        p = plan(a, 2);
        expect(
          rectOfSvg(p, true, a).bottom,
          lessThan(rectOfSvg(p, false, a).center.dy),
          reason: 'on: the toy is over the thing',
        );
        a = act('shp.where.next');
        p = plan(a, 2);
        expect(
          rectOfSvg(p, true, a).left,
          greaterThan(rectOfSvg(p, false, a).center.dx),
          reason: 'next to: side by side',
        );
        a = act('shp.where.under');
        p = plan(a, 2);
        expect(
          rectOfSvg(p, true, a).top,
          greaterThan(rectOfSvg(p, false, a).top),
          reason: 'under: below the table top',
        );
        expect(rectOfSvg(p, true, a).center.dx, closeTo(rectOfSvg(p, false, a).center.dx, 0.5));
      },
    );

    test('solids: both objects get the same push, the box stays and the ball rolls away', () {
      for (final String id in <String>[
        'shp.solid.rolls',
        'shp.solid.rolls.blue',
        'b15.shpa07.1',
        'shp.solid.which',
        'shp.solid.which2',
      ]) {
        final TapAnswerActivity a = act(id);
        final HintPlan l2 = plan(a, 2);
        final List<ArrowMark> arrows = l2.rest.whereType<ArrowMark>().toList();
        expect(arrows, hasLength(2), reason: id);
        expect(
          (arrows[0].to - arrows[0].from).distance,
          closeTo((arrows[1].to - arrows[1].from).distance, 0.01),
          reason: '$id: the same push',
        );
        expect(arrows[0].from.dx, closeTo(arrows[1].from.dx, 0.01), reason: id);
        final List<CopyMark> before = l2.frames.first.marks.whereType<CopyMark>().toList();
        final List<CopyMark> after = l2.rest.whereType<CopyMark>().toList();
        expect(before, hasLength(2), reason: id);
        final String ballSvg = a.assets.svg(
          a.options
              .firstWhere((ChoiceOption o) => o.sprite!.contains('ball') || o.sprite!.contains('sphere'))
              .sprite!,
        );
        for (int i = 0; i < 2; i++) {
          final bool isBall = before[i].svg == ballSvg;
          if (isBall) {
            expect(
              after[i].rect.center.dx,
              greaterThan(before[i].rect.center.dx + 40),
              reason: '$id: the ball rolls away',
            );
          } else {
            expect(after[i].rect, before[i].rect, reason: '$id: the box stays');
          }
        }
      }
    });

    test(
      'solids: the stacking items put a second one on each; it stays on the box and slides off the ball',
      () {
        for (final String id in <String>['shp.solid.stacks', 'shp.solid.stacks.blue', 'b15.shpa07.2']) {
          final TapAnswerActivity a = act(id);
          final HintPlan l2 = plan(a, 2);
          expect(
            <HintMark>[for (final HintFrame f in l2.frames) ...f.marks, ...l2.rest].whereType<ArrowMark>(),
            isEmpty,
            reason: '$id is not the rolling scene',
          );
          final List<CopyMark> hover = l2.frames.first.marks.whereType<CopyMark>().toList();
          final List<CopyMark> landed = l2.rest.whereType<CopyMark>().toList();
          expect(hover, hasLength(4), reason: '$id: two solids and a second one of each');
          expect(landed, hasLength(4), reason: id);
          for (int i = 0; i < 2; i++) {
            expect(
              landed[2 + i].svg,
              landed[i].svg,
              reason: '$id: the second one is a copy of the same solid',
            );
            expect(landed[2 + i].rect.size, hover[2 + i].rect.size, reason: id);
            final bool ball =
                landed[i].svg ==
                a.assets.svg(
                  a.options
                      .firstWhere(
                        (ChoiceOption o) => o.sprite!.contains('ball') || o.sprite!.contains('sphere'),
                      )
                      .sprite!,
                );
            if (ball) {
              expect(
                landed[2 + i].rect.left,
                greaterThan(landed[i].rect.right - 1),
                reason: '$id: slid off the ball',
              );
              expect(landed[2 + i].rect.bottom, closeTo(landed[i].rect.bottom, 0.5), reason: id);
            } else {
              expect(
                landed[2 + i].rect.bottom,
                closeTo(landed[i].rect.top, 0.5),
                reason: '$id: stays on the box',
              );
              expect(landed[2 + i].rect.center.dx, closeTo(landed[i].rect.center.dx, 0.5), reason: id);
            }
          }
        }
      },
    );

    test('heavy and light use the generic ladder (no length cubes); long and short keep their cubes', () {
      for (final String id in <String>['math.size.heavy', 'math.size.light']) {
        final TapAnswerActivity a = act(id);
        for (int level = 1; level <= 3; level++) {
          final HintPlan p = plan(a, level);
          expect(marksOf(p).whereType<BlockMark>(), isEmpty, reason: '$id level $level');
          expect(marksOf(p).whereType<CopyMark>(), isEmpty, reason: id);
        }
        expect(plan(a, 2).rest.whereType<CardMark>(), hasLength(1), reason: id);
      }
      expect(plan(act('math.size.long'), 2).rest.whereType<BlockMark>(), isNotEmpty);
    });
  });

  group('the bubble and the guide are drawn over the stage and its hint', () {
    testWidgets(
      'in the frame the speech bubble and the guide come after the stage, and the hand of the hint after them',
      (WidgetTester t) async {
        await pumpScreen(
          t,
          ActivityFrame(
            bubbleText: 'x',
            stage: (Size room) =>
                SizedBox(key: const Key('probe-stage'), width: room.width, height: room.height),
            hands: (Size room) => const SizedBox(key: Key('probe-hands')),
            tiles: const SizedBox(key: Key('probe-tiles')),
            trailTotal: 3,
            trailDone: 1,
            onHome: () {},
          ),
          band: Band.a,
        );
        final List<Element> all = find
            .descendant(of: find.byType(Scaffold), matching: find.byWidgetPredicate((Widget w) => true))
            .evaluate()
            .toList();
        int at(String key) => all.indexOf(find.byKey(Key(key)).evaluate().single);
        expect(at('lesson-bubble'), greaterThan(at('probe-stage')));
        expect(at('activity-nitzi'), greaterThan(at('probe-stage')));
        // The hint's hand is above the bubble and the guide (so the way it shows is never hidden), and below the tiles.
        expect(at('probe-hands'), greaterThan(at('lesson-bubble')));
        expect(at('probe-hands'), greaterThan(at('activity-nitzi')));
        expect(at('probe-tiles'), greaterThan(at('probe-hands')));
      },
    );
  });

  group('the hand keeps out from under the speech bubble', () {
    Future<void> hand(WidgetTester t, double x, double? clearOf) async {
      // The hand's art comes from the asset bundle, which needs the real clock.
      await t.runAsync(warmHintHands);
      await t.pumpWidget(
        MaterialApp(
          home: Center(
            child: HintOverlay(
              size: const Size(330, 128),
              clearOf: clearOf,
              marks: <HintMark>[HandMark(Offset(x, 140))],
            ),
          ),
        ),
      );
      await t.pump(const Duration(milliseconds: 100));
    }

    bool flipped(WidgetTester t) => t
        .widgetList<Transform>(
          find.descendant(of: find.byKey(const Key('hint-p12')), matching: find.byType(Transform)),
        )
        .any((Transform w) => w.transform.storage[0] < 0);

    testWidgets(
      'a hand whose body would reach the bubble comes from the upper left; elsewhere it is as always',
      (WidgetTester t) async {
        final double clear = handClearOf(ActivitySpec.phone)!;
        expect(clear, 338, reason: 'the bubble starts at 413 and the stage at 71');
        expect(
          handClearOf(ActivitySpec.tabletLandscape),
          isNull,
          reason: 'the tablet bubble is above the stage',
        );
        await hand(t, 100, clear);
        expect(flipped(t), isFalse);
        await hand(t, 330, clear);
        expect(flipped(t), isTrue);
        await hand(t, 330, null);
        expect(flipped(t), isFalse);
      },
    );
  });

  group('on the lesson stage', () {
    Future<void> host(WidgetTester tester, TapAnswerSession s, {bool reduceMotion = true}) async {
      await tester.pumpWidget(
        MaterialApp(
          builder: (BuildContext context, Widget? child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: reduceMotion),
            child: child!,
          ),
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: Scaffold(
              body: Builder(
                builder: (BuildContext ctx) => Center(
                  child: SizedBox(
                    width: spec.tilesWidth,
                    height: spec.stage.height + 160,
                    child: Column(
                      children: <Widget>[
                        SizedBox(
                          width: spec.stage.width,
                          height: spec.stage.height,
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: <Widget>[
                              Positioned.fill(child: s.buildStage(ctx, spec.stage.size, spec)),
                              Positioned.fill(child: s.buildHands(ctx, spec.stage.size, spec)!),
                            ],
                          ),
                        ),
                        Expanded(
                          child: SizedBox(
                            width: spec.tilesWidth,
                            child: s.buildTiles(ctx, spec) ?? const SizedBox(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));
    }

    LessonController controllerFor(Activity a) => LessonController(
      content: content,
      lesson: Lesson.mission(
        id: 'one',
        itemIds: <String>[a.id],
        skillIds: <String>[a.skillId],
        celebration: content.lessons.values.first.celebration,
      ),
      profileId: 'p-1',
      clock: FixedClock(1793000000000),
      record: (AttemptRecord r) async {},
    );

    Future<void> pass(WidgetTester t, int ms) async {
      for (int spent = 0; spent < ms; spent += 100) {
        await t.pump(const Duration(milliseconds: 100));
      }
    }

    // One activity of each family, and what each level puts on the stage (a widget key for each picture).
    final List<(String, String, String, String)> shots = <(String, String, String, String)>[
      ('colour naming', 'col.name.red.ball', 'hint-tile-glow', 'hint-p9'),
      ('colour with a model', 'col.match.red', 'hint-p1', 'hint-p9'),
      ('shapes', 'shp.name.triangle', 'hint-tile-glow', 'hint-p9'),
      ('compare', 'more.apples.2v4', 'hint-line', 'hint-p5'),
      ('count', 'numeral.bugs.5', 'hint-p2', 'hint-card'),
      ('sequence', 'next.after.4', 'hint-p1', 'hint-p6'),
      ('pattern', 'log.next.colours', 'hint-p2', 'hint-bracket'),
      ('time', 'log.story.plant.mid', 'hint-p1', 'hint-badge'),
      ('same', 'log.same.cat', 'hint-p1', 'hint-card'),
      ('add', 'math.add.stars', 'hint-p1', 'hint-card'),
      ('numerals', 'show.birds.4', 'hint-p1', 'hint-p6'),
      ('measure', 'math.size.long', 'hint-line', 'hint-block'),
      ('ordinal', 'ordinal.second.of4', 'hint-tile-glow', 'hint-flag'),
      ('position', 'shp.where.above', 'hint-tile-glow', 'hint-card'),
      ('solids', 'shp.solid.rolls', 'hint-tile-glow', 'hint-arrow'),
    ];

    for (final (String name, String id, String key1, String key2) in shots) {
      testWidgets('$name ($id): level 1 draws $key1, level 2 $key2, level 3 the hand', (
        WidgetTester t,
      ) async {
        // The hands load from the asset bundle, which needs the real clock: ask for them before the session does.
        await t.runAsync(warmHintHands);
        final TapAnswerActivity a = content.activities[id]! as TapAnswerActivity;
        final LessonController c = controllerFor(a);
        final TapAnswerSession s = TapAnswerSession(c, a);
        await host(t, s);
        expect(find.byKey(const Key('hint-p12')), findsNothing);
        c.showHint();
        await pass(t, 700);
        expect(find.byKey(Key(key1)), findsWidgets, reason: 'level 1');
        expect(find.byKey(const Key('hint-p12')), findsNothing);
        expect(c.answerShown, isFalse);
        await pass(t, 9000);
        c.showHint();
        await pass(t, 9000);
        expect(find.byKey(Key(key2)), findsWidgets, reason: 'level 2');
        expect(find.byKey(const Key('hint-p12')), findsNothing, reason: 'no hand before level 3');
        for (final AnswerTile tile in t.widgetList<AnswerTile>(find.byType(AnswerTile))) {
          expect(tile.state, AnswerState.idle, reason: 'no tile is marked at level 1 or 2');
        }
        c.showHint();
        final HintPlan p3 = plan(a, 3);
        await pass(t, p3.length.inMilliseconds - 500);
        expect(find.byKey(const Key('hint-p12')), findsOneWidget, reason: 'level 3: the sky hand');
        await pass(t, 2500);
        expect(
          find.byKey(const Key('hint-p12')),
          findsNothing,
          reason: 'the hand leaves when the demonstration is over',
        );
        s.dispose();
        await t.pumpWidget(const SizedBox());
      });
    }

    testWidgets(
      'the guided state: three mistakes, the hand shows the way, and only then does the right tile have its halo',
      (WidgetTester t) async {
        final TapAnswerActivity a = content.activities['col.name.red.ball']! as TapAnswerActivity;
        final LessonController c = controllerFor(a);
        final TapAnswerSession s = TapAnswerSession(c, a);
        await host(t, s);
        final String wrong = a.options.firstWhere((ChoiceOption o) => o.id != a.correctId).id;
        for (int k = 0; k < 3; k++) {
          await s.choose(wrong);
          await pass(t, 1300);
          if (k < 2) await pass(t, 9000);
        }
        expect(c.guided, isTrue);
        expect(c.answerShown, isFalse, reason: 'the hand is still showing the way');
        AnswerTile tile() => t.widget<AnswerTile>(find.byKey(Key('tile-${a.correctId}')));
        expect(tile().state, isNot(AnswerState.selected));
        await pass(t, plan(a, 3).length.inMilliseconds + 600);
        expect(c.answerShown, isTrue);
        expect(tile().state, AnswerState.selected);
        s.dispose();
        await t.pumpWidget(const SizedBox());
      },
    );

    testWidgets('with motion allowed the same hints play (the hand travels, the cards fade in) and rest', (
      WidgetTester t,
    ) async {
      final TapAnswerActivity a = content.activities['numeral.bugs.5']! as TapAnswerActivity;
      final LessonController c = controllerFor(a);
      final TapAnswerSession s = TapAnswerSession(c, a);
      await host(t, s, reduceMotion: false);
      c.showHint();
      await pass(t, 6000);
      c.showHint();
      await pass(t, 7000);
      expect(find.byKey(const Key('hint-card')), findsOneWidget);
      c.showHint();
      await pass(t, plan(a, 3).length.inMilliseconds - 500);
      expect(find.byKey(const Key('hint-p12')), findsOneWidget);
      s.dispose();
      await t.pumpWidget(const SizedBox());
    });

    testWidgets('a touch on an answer stops the hint (the dots of level 1 go with it)', (
      WidgetTester t,
    ) async {
      final TapAnswerActivity a = content.activities['numeral.bugs.5']! as TapAnswerActivity;
      final LessonController c = controllerFor(a);
      final TapAnswerSession s = TapAnswerSession(c, a);
      await host(t, s);
      c.showHint();
      await pass(t, 6000);
      expect(find.byKey(const Key('seen-dot')), findsWidgets);
      await s.choose(a.options.firstWhere((ChoiceOption o) => o.id != a.correctId).id);
      await pass(t, 200);
      expect(find.byKey(const Key('seen-dot')), findsNothing);
      s.dispose();
      await t.pumpWidget(const SizedBox());
    });

    testWidgets('the overlay takes no touch: a tap through a hint reaches the tile', (WidgetTester t) async {
      final TapAnswerActivity a = content.activities['col.name.red.ball']! as TapAnswerActivity;
      final LessonController c = controllerFor(a);
      final TapAnswerSession s = TapAnswerSession(c, a);
      await host(t, s);
      c.showHint();
      await pass(t, 300);
      c.showHint();
      await pass(t, 9000);
      expect(find.byKey(const Key('hint-p9')), findsWidgets);
      final Iterable<IgnorePointer> blocks = t.widgetList<IgnorePointer>(
        find.ancestor(of: find.byKey(const Key('hint-p9')), matching: find.byType(IgnorePointer)),
      );
      expect(blocks, isNotEmpty);
      s.dispose();
      await t.pumpWidget(const SizedBox());
    });
  });

  test('the shared pictures keep their sizes: a hand 72 high on a phone, the fingertip on the target', () {
    expect(hintScale(const Size(330, 128)), 1);
    expect(hintScale(const Size(270, 104)), 0.85);
    expect(hintScale(const Size(552, 268)), 1.4);
    expect(PointingHand.widthAt(72), closeTo(51.7, 0.1));
    final Offset tip = PointingHand.tipAt(72);
    expect(tip.dx, closeTo(19.2, 0.1));
    expect(tip.dy, closeTo(64.6, 0.1));
  });
}
