import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/child/activity_shell.dart';
import 'package:nitznutz/content/hint_ladder.dart';
import 'package:nitznutz/content/models.dart';
import 'package:nitznutz/play/hint_hand.dart';
import 'package:nitznutz/play/hints/hint_marks.dart';
import 'package:nitznutz/play/hints/hint_pictures.dart';
import 'package:nitznutz/play/hints/prompt_numbers.dart';
import 'package:nitznutz/play/hints/sprite_outline.dart';
import 'package:nitznutz/play/hints/tap_geometry.dart';
import 'package:nitznutz/play/hints/tap_plans.dart';

import 'support/harness.dart';
import 'support/starter.dart';

/// B-40 part 4: the pictures of the Band B skills of `tap_answer` (325 activities, 36 skills). Every activity has a plan for each
/// level; level 1 and level 2 never mark the right answer or reach over the tiles; each level draws something the level below does
/// not; level 3 is the sky hand's demonstration and ends on the right tile; and what each skill draws is what it is meant to.
void main() {
  late PackContent content;
  setUpAll(() async {
    await loadAppFonts();
    content = await loadStarter();
  });

  const ActivitySpec spec = ActivitySpec.phone;

  List<TapAnswerActivity> bandB() => <TapAnswerActivity>[
    for (final TapAnswerActivity a in content.activities.values.whereType<TapAnswerActivity>())
      if (a.skillId.contains('-B-')) a,
  ];

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
  TapAnswerActivity act(String id) => content.activities[id]! as TapAnswerActivity;

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

  group('every Band B tap_answer activity has a plan for each level', () {
    test('325 activities in 36 skills belong to a family, and the plain pulse is gone', () {
      final List<TapAnswerActivity> all = bandB();
      expect(all, hasLength(325));
      expect(<String>{for (final TapAnswerActivity a in all) a.skillId}, hasLength(36));
      for (final TapAnswerActivity a in all) {
        expect(
          tapFamilyOf(a.skillId, numeralOnStage: a.stageNumeral != null),
          isNotNull,
          reason: '${a.id} (${a.skillId}) has a family',
        );
      }
      expect(HintPicture.values.map((HintPicture p) => p.id), isNot(contains('pulse')));
      expect(HintLadder.problemWith('tap_answer'), isNull);
    });

    test('each level has steps, no step is empty of time, and a demonstration is over in 10 seconds', () {
      for (final TapAnswerActivity a in bandB()) {
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
          for (final TapAnswerActivity a in bandB()) {
            final TapGeometry g = geo(a, s: board);
            for (int level = 1; level <= 2; level++) {
              final HintPlan p = plan(a, level, s: board);
              expect(p.endsDemo, isFalse, reason: '${a.id} level $level');
              expect(marksOf(p).whereType<HandMark>(), isEmpty, reason: '${a.id} level $level draws no hand');
              for (final HintMark m in marksOf(p)) {
                final Rect? r = rectOf(m);
                final bool underTile = m is CopyMark && r != null && r.top >= g.optionTip(0).dy - 1;
                if (r != null && !underTile) {
                  final String why =
                      '${a.id} (${a.skillId}) level $level on ${board.stage}: ${m.runtimeType} $r in $room';
                  expect(r.bottom, lessThanOrEqualTo(room.height + 1), reason: why);
                  expect(r.top, greaterThanOrEqualTo(-1), reason: why);
                  expect(r.left, greaterThanOrEqualTo(-1), reason: why);
                  expect(r.right, lessThanOrEqualTo(room.width + 1), reason: why);
                }
                if (m is OutlineMark) {
                  for (final Offset p in m.points) {
                    expect(
                      Rect.fromLTWH(-1, -1, room.width + 2, room.height + 2).contains(p),
                      isTrue,
                      reason: a.id,
                    );
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

    test(
      'level 3 is the hand: it never starts on the answer tile and ends on it, with the turn handed back',
      () {
        for (final ActivitySpec board in boards) {
          for (final TapAnswerActivity a in bandB()) {
            final TapGeometry g = geo(a, s: board);
            final HintPlan p = plan(a, 3, s: board);
            expect(p.endsDemo, isTrue, reason: a.id);
            final List<HandMark> hands = marksOf(p).whereType<HandMark>().toList();
            expect(hands, isNotEmpty, reason: a.id);
            final HandMark last = p.frames.last.marks.whereType<HandMark>().single;
            expect(
              (last.tip - g.optionTip(g.correctIndex)).distance,
              lessThan(0.5),
              reason: '${a.id}: the last step',
            );
            expect(p.frames.length, greaterThan(1), reason: a.id);
            for (final HandMark h
                in p.frames
                    .take(p.frames.length - 1)
                    .expand((HintFrame f) => f.marks.whereType<HandMark>())) {
              expect(
                (h.tip - g.optionTip(g.correctIndex)).distance,
                greaterThan(0.5),
                reason: '${a.id}: the hand is not on the answer before the last step',
              );
            }
          }
        }
      },
    );

    test('each level draws something the level below does not, and the sky hand is level 3 only', () {
      for (final TapAnswerActivity a in bandB()) {
        final Set<String> k1 = kinds(plan(a, 1));
        final Set<String> k2 = kinds(plan(a, 2));
        final Set<String> k3 = kinds(plan(a, 3));
        expect(
          k2.difference(k1).isNotEmpty || k1.difference(k2).isNotEmpty,
          isTrue,
          reason: '${a.id} (${a.skillId}): $k1 vs $k2',
        );
        expect(k3, contains('HandMark'), reason: a.id);
        expect(k3.difference(k2).isNotEmpty, isTrue, reason: '${a.id}: $k2 vs $k3');
        expect(k1.contains('HandMark') || k2.contains('HandMark'), isFalse, reason: a.id);
      }
    });

    test('a plan that reads what it needs from the activity does not fall back to the generic one (a question mark card)', () {
      // The generic plan's second level is a card with a question mark and nothing else.
      final List<String> generic = <String>[];
      for (final TapAnswerActivity a in bandB()) {
        final HintPlan l2 = plan(a, 2);
        // What stays is the one card with a question mark (marksOf also counts the step that shows it, so it never sees one mark).
        final HintMark? only = l2.rest.length == 1 ? l2.rest.single : null;
        if (only is CardMark && only.child is Text && (only.child as Text).data == '?') {
          generic.add('${a.id} (${a.skillId})');
        }
      }
      expect(generic, isEmpty, reason: '$generic');
    });

    test('no hint at level 1 or 2 draws the right answer\'s own picture alone: the other answers are drawn with it', () {
      for (final TapAnswerActivity a in bandB()) {
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

    test('no swatch, outline or path in the stage runs right to left, and nothing is red', () {
      for (final TapAnswerActivity a in bandB()) {
        for (int level = 1; level <= 3; level++) {
          for (final HintMark m in marksOf(plan(a, level))) {
            if (m is SwatchMark) expect(hintColours.keys, contains(m.colour), reason: a.id);
            if (m is PathMark) {
              expect(m.step, greaterThan(0), reason: a.id);
              expect(
                m.numberAt(1),
                lessThan(m.numberAt(m.count)),
                reason: '${a.id}: the numbers grow to the right',
              );
            }
          }
        }
      }
    });
  });

  group('the numbers a question says', () {
    test('words become numbers, in order: units, teens, tens with and without a unit, ten', () {
      expect(numbersIn('עֶשֶׂר זֶה שָׁלוֹשׁ וְעוֹד כַּמָּה'), <int>[10, 3]);
      expect(numbersIn('מָה בָּא אַחֲרֵי עֶשְׂרִים וְתֵשַׁע'), <int>[29]);
      expect(numbersIn('אַחַת עֶשְׂרֵה'), <int>[11]);
      expect(numbersIn('סוֹפְרִים בַּעֲשָׂרוֹת: חֲמִשִּׁים, שִׁשִּׁים, שִׁבְעִים'), <int>[50, 60, 70]);
      expect(numbersIn('יֵשׁ שְׁנֵי כּוֹכָבִים בַּסַּל, וַחֲמִשָּׁה כּוֹכָבִים בַּחוּץ'), <int>[2, 5]);
      expect(numbersIn('אֵין כְּלוּם'), isEmpty);
    });

    test('the corners of the shapes of the pack are read from their pictures', () {
      SpriteOutline? of(String id) => outlineOf(content.activities.values.first.assets.svg('asset:$id'));
      expect(of('shape_triangle')!.sides, 3);
      expect(of('shape_square')!.sides, 4);
      expect(of('shape_rect')!.sides, 4);
      expect(of('shape_pentagon')!.sides, 5);
      expect(of('shape_hexagon')!.sides, 6);
      expect(of('shape_open')!.closed, isFalse, reason: 'its last side does not come back to the start');
      expect(of('shape_open')!.sides, 3);
      expect(of('shape_circle'), isNull);
    });
  });

  group('what each Band B skill draws', () {
    test('mixing with one paint on the stage: the paint, an empty place for the other, and the colour that is made', () {
      final TapAnswerActivity a = act('b.colb01.7');
      final HintPlan l2 = plan(a, 2);
      expect(l2.rest.whereType<SwatchMark>().map((SwatchMark s) => s.colour), <String>['red', 'orange']);
      expect(l2.rest.whereType<GhostMark>(), hasLength(1));
      expect(
        plan(a, 3).frames.last.marks.whereType<SwatchMark>().map((SwatchMark s) => s.colour),
        contains('yellow'),
      );
    });

    test('mixing: the two paints and an empty place, and the mixed colour last', () {
      final TapAnswerActivity a = act('b.colb01.1');
      final HintPlan l2 = plan(a, 2);
      final List<SwatchMark> swatches = l2.rest.whereType<SwatchMark>().toList();
      expect(swatches.map((SwatchMark s) => s.colour), <String>['red', 'yellow']);
      expect(l2.rest.whereType<GhostMark>(), hasLength(1), reason: 'the empty place');
      final HintPlan l3 = plan(a, 3);
      final List<HintMark> last = l3.frames.last.marks;
      expect(last.whereType<SwatchMark>().map((SwatchMark s) => s.colour), contains('orange'));
      expect(
        l3.frames
            .take(3)
            .expand((HintFrame f) => f.marks)
            .whereType<SwatchMark>()
            .map((SwatchMark s) => s.colour),
        isNot(contains('orange')),
        reason: 'the mix appears only after the hand has poured',
      );
    });

    test('shades: the shades of one colour in their order with an arrow from the lightest', () {
      final HintPlan l2 = plan(act('b.colb02.1'), 2);
      expect(l2.rest.whereType<CopyMark>(), hasLength(3));
      final ArrowMark arrow = l2.rest.whereType<ArrowMark>().single;
      expect(arrow.to.dx, greaterThan(arrow.from.dx));
      // In a row (the one in the middle) the arrow follows the row from its lighter end.
      final TapAnswerActivity row = act('b.colb02.10');
      final ArrowMark rowArrow = plan(row, 2).rest.whereType<ArrowMark>().single;
      expect(rowArrow.to.dx, greaterThan(rowArrow.from.dx), reason: 'shade 1 is at the left of the row');
    });

    test('the colour of "where else is blue" is the hue of its shade, with the swatch of the colour', () {
      expect(colourOfSprite('asset:shade_blue_1'), 'blue');
      expect(colourOfSprite('asset:ball_red'), 'red');
      expect(colourOfSprite('asset:shape_circle_yellow'), 'yellow');
      expect(colourOfSprite('asset:apple'), isNull);
      expect(marksOf(plan(act('b.colb03.1'), 2)).whereType<SwatchMark>().first.colour, 'blue');
    });

    test('a number after, before, one more, one less: the path has the two numbers and the hop', () {
      PathMark path(String id, int level) => marksOf(plan(act(id), level)).whereType<PathMark>().first;
      expect(path('b.numb01.1', 2).gap, 12);
      expect(path('b.numb01.1', 2).ring, 11);
      expect(path('b.numb01.6', 2).gap, 13, reason: 'before fourteen');
      expect(path('b.numb01.6', 2).ring, 14);
      expect(path('b.numb02.2', 2).gap, 30, reason: 'after twenty nine');
      expect(path('b.numb02.2', 2).ring, 29);
      expect(path('b.numb11.10', 2).gap, 12, reason: 'one more than eleven');
      expect(path('b.numb11.13', 2).gap, 3, reason: 'one less than four');
      expect(path('b.numb11.13', 2).ring, 4);
      final PathMark p = path('b.numb02.2', 2);
      expect(p.numberAt(1), lessThan(29));
      expect(p.numberAt(p.count), greaterThan(30));
      // Level 3: a hop (an arc) from the number given to the place, left to right when the sequence grows.
      final ArcMark hop = marksOf(plan(act('b.numb01.1'), 3)).whereType<ArcMark>().first;
      expect(hop.to.dx, greaterThan(hop.from.dx));
      final ArcMark back = marksOf(plan(act('b.numb01.6'), 3)).whereType<ArcMark>().first;
      expect(back.to.dx, lessThan(back.from.dx), reason: 'before: the hop goes back, along the same path');
    });

    test('counting by twos and tens: a path of the numbers counted by, hops between the numbers said, the next place empty', () {
      final PathMark twos = plan(act('b.numb17.10'), 2).rest.whereType<PathMark>().single;
      expect(twos.step, 2);
      expect(twos.gap, 8);
      expect(plan(act('b.numb17.10'), 2).rest.whereType<ArcMark>(), hasLength(2));
      final PathMark tens = plan(act('b.numb17.8'), 2).rest.whereType<PathMark>().single;
      expect(tens.step, 10);
      expect(tens.gap, 50);
      expect(tens.numberAt(2) - tens.numberAt(1), 10);
    });

    test('a number of ten and some: the full frame and the ones, the numeral only at the end', () {
      final TapAnswerActivity a = act('b.numb08.1');
      final HintPlan l2 = plan(a, 2);
      expect(l2.rest.whereType<CardMark>(), hasLength(1));
      final HintPlan l3 = plan(a, 3);
      expect(l3.frames[l3.frames.length - 2].marks.whereType<CardMark>(), hasLength(1));
      expect(
        plan(act('b.numb08.13'), 2).rest.whereType<PathMark>().single.gap,
        13,
        reason: 'a missing number of a row',
      );
    });

    test('which number is bigger: a bar of cubes for each, as long as the number, from one start line', () {
      final HintPlan l2 = plan(act('b.numb10.1'), 2);
      final List<BlockMark> blocks = l2.rest.whereType<BlockMark>().toList();
      expect(blocks, hasLength(7 + 4));
      expect(plan(act('b.numb10.1'), 1).frames.every((HintFrame f) => f.litOption != null), isTrue);
      final List<double> lefts = <double>{for (final BlockMark b in blocks) b.rect.left}.toList()..sort();
      expect(lefts.first, closeTo(blocks.first.rect.left, 0.01), reason: 'both bars start at one place');
    });

    test('coins: the value of each coin as cubes beside a coin of the same size', () {
      final HintPlan l2 = plan(act('x.mathb16.8'), 2);
      expect(l2.rest.whereType<CopyMark>().map((CopyMark c) => c.rect.size).toSet(), hasLength(1));
      expect(l2.rest.whereType<BlockMark>(), hasLength(5 + 10));
      final HintPlan agorot = plan(act('x.mathb16.7'), 2);
      expect(
        agorot.rest.whereType<BlockMark>(),
        hasLength(1 + 1),
        reason: 'a shekel, and half of one for fifty agorot',
      );
    });

    test('pairs of two: a line for each pair, the odd one left alone is ringed', () {
      final PairsMark odd = plan(act('b.numb18.10'), 2).rest.whereType<PairsMark>().single;
      expect(odd.lines, hasLength(3));
      expect(odd.unpaired, hasLength(1));
      final PairsMark even = plan(act('b.numb18.1'), 2).rest.whereType<PairsMark>().single;
      expect(even.lines, hasLength(2));
      expect(even.unpaired, isEmpty);
    });

    test('a chart: every column is counted, and equal groups keep a running total', () {
      final TapAnswerActivity most = act('x.mathb19.1');
      final List<BadgeMark> counts = plan(most, 2).rest.whereType<BadgeMark>().toList();
      expect(counts.map((BadgeMark b) => b.n), <int>[3, 5, 2]);
      final TapAnswerActivity total = act('b.mathb10.2');
      final List<BadgeMark> running = plan(total, 3).frames.last.marks.whereType<BadgeMark>().toList();
      expect(running.map((BadgeMark b) => b.n), <int>[2, 4, 6]);
    });

    test(
      'a number sentence: cubes over the numbers, the unknown part counted as the places that are left',
      () {
        final HintPlan sum = plan(act('b.mathb03.1'), 2);
        expect(sum.rest.whereType<BlockMark>(), hasLength(3 + 4), reason: '3 + 4 = ?');
        expect(sum.rest.whereType<BlockMark>().every((BlockMark b) => !b.empty), isTrue);
        final HintPlan part = plan(act('b.mathb18.1'), 2);
        final List<BlockMark> cubes = part.rest.whereType<BlockMark>().toList();
        expect(cubes.where((BlockMark b) => b.empty), hasLength(4), reason: '3 + ? = 7: four places left');
        expect(cubes.where((BlockMark b) => !b.empty), hasLength(3 + 3));
        final HintPlan zero = plan(act('b.mathb07.1'), 2);
        expect(zero.rest.whereType<BlockMark>(), hasLength(5), reason: '5 + 0: nothing over the zero');
        // Level 1 lights the signs.
        expect(
          plan(act('b.mathb03.1'), 1).frames.single.marks.whereType<VeilMark>().single.holes,
          hasLength(2),
        );
        // The answer stands in the empty cell only at level 3.
        expect(marksOf(plan(act('b.mathb03.1'), 2)).whereType<BadgeMark>(), isEmpty);
        expect(plan(act('b.mathb03.1'), 3).frames.last.marks.whereType<BadgeMark>().single.n, 7);
      },
    );

    test('a whole and its parts with nothing on the stage: six is two and how many', () {
      final HintPlan l2 = plan(act('b.mathb02.7'), 2);
      final List<BlockMark> blocks = l2.rest.whereType<BlockMark>().toList();
      expect(blocks, hasLength(6));
      expect(
        blocks.where((BlockMark b) => b.empty),
        hasLength(4),
        reason: 'the known part is drawn, the rest is left to count',
      );
      final HintPlan l3 = plan(act('b.mathb02.7'), 3);
      expect(l3.frames.last.marks.whereType<BadgeMark>().single.n, 4);
    });

    test('how many more to make ten: the empty cells of the frame are counted', () {
      final HintPlan own = plan(act('b.mathb06.1'), 2);
      expect(
        own.rest.whereType<SeenMark>(),
        hasLength(5),
        reason: 'five empty cells of the frame the apples stand in',
      );
      final TapAnswerActivity coins = act('b.mathb06.10');
      final HintPlan l2 = plan(coins, 2);
      expect(
        l2.rest.whereType<BlockMark>().where((BlockMark b) => b.empty),
        hasLength(4),
        reason: 'six coins, four places',
      );
    });

    test(
      'the days of the week: the week in order, the day asked for an empty place, the day given ringed',
      () {
        final HintPlan l2 = plan(act('b.mathb14.1'), 2);
        expect(l2.rest.whereType<CopyMark>(), hasLength(6));
        expect(l2.rest.whereType<GhostMark>(), hasLength(1), reason: 'the day after Tuesday');
        expect(l2.rest.whereType<RingMark>(), hasLength(1));
        final List<CopyMark> cards = l2.rest.whereType<CopyMark>().toList();
        expect(<double>[
          ...cards.map((CopyMark c) => c.rect.left),
        ], orderedEquals(<double>[...cards.map((CopyMark c) => c.rect.left)]..sort()));
        // Yesterday and tomorrow are read too, and the day before Sunday is Saturday.
        expect(plan(act('b.mathb14.7'), 2).rest.whereType<GhostMark>(), hasLength(1));
        expect(plan(act('b.mathb14.7'), 2).rest.whereType<RingMark>(), hasLength(1));
      },
    );

    test('the hour: the short hand lit, a ray to the dial\'s edge with the 12 marked, then the hours counted round', () {
      final TapAnswerActivity a = act('b.mathb15.1');
      expect(plan(a, 1).frames.single.marks.whereType<VeilMark>(), hasLength(1));
      final HintPlan l2 = plan(a, 2);
      expect(l2.rest.whereType<LineMark>(), hasLength(1));
      expect(l2.rest.whereType<BadgeMark>().single.n, 12);
      final List<int> badges = <int>[
        for (final BadgeMark b in plan(a, 3).frames.last.marks.whereType<BadgeMark>()) b.n,
      ];
      expect(badges, <int>[1, 2, 3], reason: 'the hand has counted three hours');
    });

    test(
      'shapes: the corners of the named shape lit one by one, the sides of the stage\'s shape followed round',
      () {
        final HintPlan hex = plan(act('b.shpb01.6'), 2);
        expect(
          hex.frames.whereType<HintFrame>().where(
            (HintFrame f) => f.marks.whereType<OutlineMark>().isNotEmpty,
          ),
          hasLength(7),
        );
        final OutlineMark whole = hex.rest.whereType<OutlineMark>().single;
        expect(whole.points, hasLength(6));
        final HintPlan sides = plan(act('b.shpb02.1'), 3);
        expect(sides.frames.last.marks.whereType<BadgeMark>().map((BadgeMark b) => b.n), <int>[1, 2, 3]);
        final HintPlan open = plan(act('b.shpb04.2'), 2);
        expect(
          open.rest.whereType<OutlineMark>().single.closed,
          isFalse,
          reason: 'an open shape does not come back to its start',
        );
        expect(
          marksOf(open).whereType<BadgeMark>(),
          isEmpty,
          reason: 'no counting of sides in a closed-or-not question',
        );
      },
    );

    test('equal sides: every option\'s shape with its sides as sticks, none marked', () {
      final TapAnswerActivity a = act('b.shpb03.1');
      final HintPlan l2 = plan(a, 2);
      expect(l2.rest.whereType<CopyMark>(), hasLength(a.options.length));
      final List<BlockMark> sticks = l2.rest.whereType<BlockMark>().toList();
      expect(sticks, hasLength(4 + 4 + 3), reason: 'square, rectangle, triangle');
      Set<int> lengths(List<BlockMark> l) => <int>{for (final BlockMark b in l) b.rect.width.round()};
      expect(lengths(sticks.sublist(0, 4)), hasLength(1), reason: 'four sides of one length');
      expect(lengths(sticks.sublist(4, 8)), hasLength(2), reason: 'two long and two short');
    });

    test('a solid: its outline as drawn on paper, and the stamp question stays generic', () {
      expect(marksOf(plan(act('b.shpb08.1'), 2)).whereType<GhostMark>().first.kind, GhostKind.cylinder);
      expect(
        marksOf(plan(act('b.shpb08.3'), 2)).whereType<GhostMark>().first.kind,
        isIn(<GhostKind>[GhostKind.cone, GhostKind.circle, GhostKind.pyramid, GhostKind.box]),
      );
    });

    test('a growing row shows how many cubes each step has, but not under the empty place', () {
      final TapAnswerActivity a = act('b.logb04.1');
      final List<BadgeMark> counts = plan(a, 2).rest.whereType<BadgeMark>().toList();
      expect(counts.map((BadgeMark b) => b.n), <int>[1, 2, 4]);
    });

    test('what do they share: each picture of the row linked to the next, and the hand along the row', () {
      final TapAnswerActivity a = act('b.logb06.1');
      expect(plan(a, 2).rest.whereType<ArcMark>(), hasLength(2));
      expect(
        plan(a, 3).frames.where((HintFrame f) => f.marks.whereType<HandMark>().isNotEmpty).length,
        greaterThanOrEqualTo(4),
      );
    });

    test('two clues: the options in a row, the first clue fades one, the second another, and the one left is the answer', () {
      final TapAnswerActivity a = act('b.logb09.1');
      final HintPlan l2 = plan(a, 2);
      final List<CopyMark> row = l2.rest.whereType<CopyMark>().toList();
      expect(row, hasLength(3));
      expect(
        row.where((CopyMark c) => c.opacity < 1),
        hasLength(1),
        reason: 'one is out after the first clue',
      );
      final HintPlan l3 = plan(a, 3);
      final List<CopyMark> end = l3.frames[l3.frames.length - 2].marks.whereType<CopyMark>().toList();
      expect(end.where((CopyMark c) => c.opacity < 1), hasLength(2));
      expect(l3.frames[l3.frames.length - 2].marks.whereType<RingMark>(), hasLength(1));
    });

    test(
      'adding on past ten counts the ones on the group, and "how many more" counts the second group from one',
      () {
        final HintPlan more = plan(act('b.numb16.1'), 3);
        final List<int> badges = <int>[
          for (final HintFrame f in more.frames)
            for (final BadgeMark b in f.marks.whereType<BadgeMark>().where((BadgeMark b) => !b.big)) b.n,
        ];
        expect(badges.first, 1, reason: 'eleven is ten and how many: the one more is counted from one');
        final HintPlan all = plan(act('b.numb16.10'), 3);
        final List<int> running = <int>[
          for (final HintFrame f in all.frames)
            for (final BadgeMark b in f.marks.whereType<BadgeMark>().where((BadgeMark b) => !b.big)) b.n,
        ];
        expect(running.last, 14, reason: 'ten and four: the running total ends on fourteen');
      },
    );
  });

  group('the part of the hand', () {
    testWidgets(
      'a hand to a tile under the speech bubble comes in from the right, clear of the bubble and of the tile',
      (WidgetTester t) async {
        await t.runAsync(warmHintHands);
        final TapAnswerActivity a = act('b.numb08.1');
        final TapGeometry g = geo(a);
        // The first tile is the right-hand one, under the bubble that starts at x 413 of the board (342 in the stage).
        final Offset tip = g.optionTip(0);
        final double bubble = spec.bubbleLeft! - spec.stage.left;
        expect(tip.dx, greaterThan(bubble), reason: 'the tile stands under the bubble');
        await t.pumpWidget(
          MaterialApp(
            home: Center(
              child: SizedBox(
                width: 330,
                height: 128,
                child: HintOverlay(
                  marks: <HintMark>[HandMark(tip, press: true)],
                  size: const Size(330, 128),
                  clearOf: handClearOf(spec),
                  layer: HintLayer.hands,
                ),
              ),
            ),
          ),
        );
        await t.pump(const Duration(milliseconds: 600));
        final Rect stage = t.getRect(find.byType(HintOverlay));
        // The hand's whole box (turned) in the stage's own points.
        final RenderBox box = t.renderObject<RenderBox>(find.byType(PointingHand));
        final List<Offset> corners = <Offset>[
          for (final Offset c in <Offset>[
            Offset.zero,
            Offset(box.size.width, 0),
            Offset(0, box.size.height),
            Offset(box.size.width, box.size.height),
          ])
            box.localToGlobal(c) - stage.topLeft,
        ];
        final double left = corners.map((Offset c) => c.dx).reduce((double p, double q) => p < q ? p : q);
        final double top = corners.map((Offset c) => c.dy).reduce((double p, double q) => p < q ? p : q);
        final double bubbleBottom = spec.bubbleTop + spec.bubbleMaxHeight - spec.stage.top;
        expect(
          top,
          greaterThanOrEqualTo(bubbleBottom - 1),
          reason: 'the whole box of the hand is below the bubble',
        );
        expect(
          left,
          greaterThan(tip.dx - 60),
          reason: 'its body is to the right of the fingertip, not over the tile\'s middle',
        );
      },
    );
  });
}
