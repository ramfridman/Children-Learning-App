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

/// MATH-B-01 "how many did we add?" (b.mathb01.15 and .16): the third hint line says "3 apples are already here; we count only the
/// ones we added: one, two. Your turn: press two". The picture counts the same way: the group hugs into its number on the hand
/// card and is not counted again, the added places light up beside it counted 1, 2 (3), and the last step is the answer. The
/// items are read from the pack sources, so the test holds before the new pack is signed and bundled.
void main() {
  const String sources = '../content/starter';
  late Map<String, String> svg;
  late List<TapAnswerActivity> all;

  setUpAll(() {
    final Map<String, Object?> pack =
        jsonDecode(File('$sources/pack.json').readAsStringSync()) as Map<String, Object?>;
    svg = <String, String>{
      for (final Object? a in pack['assets']! as List<Object?>)
        (a! as Map<String, Object?>)['id']! as String: File('$sources/${(a as Map<String, Object?>)['file']}')
            .readAsStringSync(),
    };
    all = <TapAnswerActivity>[
      for (final File f in Directory(sources).listSync().whereType<File>())
        if (f.uri.pathSegments.last.startsWith('activity.'))
          if (Activity.fromJson(jsonDecode(f.readAsStringSync()) as Map<String, Object?>, PackAssets(svg))
              case final TapAnswerActivity a)
            a,
    ];
  });

  Size stageOf(ActivitySpec s) =>
      s.stageIsCard ? Size(s.stage.width - 32, s.stage.height - 32) : s.stage.size;
  final List<ActivitySpec> boards = <ActivitySpec>[
    ActivitySpec.phone,
    ActivitySpec.phoneSE,
    ActivitySpec.tabletLandscape,
    ActivitySpec.tabletPortrait,
  ];
  TapGeometry geo(TapAnswerActivity a, ActivitySpec s) => TapGeometry(a, stageOf(s), s);
  HintPlan plan(TapAnswerActivity a, int level, ActivitySpec s) => tapHintPlan(a, geo(a, s), level)!;
  TapAnswerActivity item(String id) => all.firstWhere((TapAnswerActivity a) => a.id == id);
  int added(TapAnswerActivity a) => a.options.firstWhere((ChoiceOption o) => o.id == a.correctId).numeral!;

  test('only the add-missing items of MATH-B-01 take the count of the added ones', () {
    final List<String> taken = <String>[
      for (final TapAnswerActivity a in all)
        if (countsAddedOnes(a)) a.id,
    ]..sort();
    expect(taken, <String>['b.mathb01.15', 'b.mathb01.16']);
    // The cue is the skill with a reverse check over one group: these two are all of that kind in the pack, and no item of any
    // other skill, nor a practice item with one group (the take away), nor an item with a second group (the count on) is among them.
    expect(
      all.where((TapAnswerActivity a) => a.skillId == 'MATH-B-01' && a.checkType == 'reverse').length,
      2,
    );
  });

  test(
    'the two items are one group with no numeral, row or second group, and the answer is the part added',
    () {
      for (final String id in <String>['b.mathb01.15', 'b.mathb01.16']) {
        final TapAnswerActivity a = item(id);
        expect(a.group2, isNull, reason: id);
        expect(a.row, isEmpty, reason: id);
        expect(a.stageNumeral, isNull, reason: id);
        expect(added(a), id.endsWith('.15') ? 2 : 3, reason: id);
        expect(a.group!.count, id.endsWith('.15') ? 3 : 4, reason: id);
      }
    },
  );

  Iterable<T> marks<T extends HintMark>(HintFrame f) => f.marks.whereType<T>();

  test('level 1 lights the group and nothing else; level 2 counts the group on the hand card and draws no added place', () {
    for (final ActivitySpec board in boards) {
      for (final String id in <String>['b.mathb01.15', 'b.mathb01.16']) {
        final TapAnswerActivity a = item(id);
        final int start = a.group!.count;
        final HintPlan one = plan(a, 1, board);
        expect(one.frames, hasLength(1), reason: id);
        expect(one.frames.single.marks.single, isA<VeilMark>(), reason: id);
        expect((one.frames.single.marks.single as VeilMark).holes, hasLength(start), reason: id);
        final HintPlan two = plan(a, 2, board);
        expect(two.frames, hasLength(start), reason: '$id: a ring on each of the group, in turn');
        for (final HintFrame f in <HintFrame>[...two.frames, HintFrame(two.rest)]) {
          expect(
            f.marks.whereType<BlockMark>(),
            isEmpty,
            reason: '$id level 2 draws an added place (the answer)',
          );
          expect(f.marks.whereType<BadgeMark>(), isEmpty, reason: id);
          expect(f.marks.whereType<HandMark>(), isEmpty, reason: id);
          expect((f.marks.whereType<CardMark>().single.child as HintHand).fingers, start, reason: id);
        }
      }
    }
  });

  test('level 3 frames: the hug, then the added ones counted 1, 2 (3), then the answer, on every board', () {
    for (final ActivitySpec board in boards) {
      for (final String id in <String>['b.mathb01.15', 'b.mathb01.16']) {
        final TapAnswerActivity a = item(id);
        final TapGeometry g = geo(a, board);
        final int start = a.group!.count;
        final int more = added(a);
        final HintPlan p = plan(a, 3, board);
        final String why = '$id on ${board.stage.size}';
        expect(p.endsDemo, isTrue, reason: why);
        expect(p.frames, hasLength(more + 2), reason: why);
        expect(p.length, lessThanOrEqualTo(const Duration(seconds: 10)), reason: why);

        // The hug: the hand card shows the group's own number, and every picture of the group has its dot. Nothing counted yet.
        final HintFrame hug = p.frames.first;
        expect((marks<CardMark>(hug).single.child as HintHand).fingers, start, reason: why);
        expect(marks<SeenMark>(hug), hasLength(start), reason: why);
        expect(
          <Type>{for (final HintMark m in hug.marks) m.runtimeType},
          <Type>{CardMark, SeenMark},
          reason: why,
        );

        // The count: one new place each step, badge 1, 2, (3) on it, the hand on it, and the hand card still shows the group.
        final List<Rect> places = <Rect>[];
        for (int j = 1; j <= more; j++) {
          final HintFrame f = p.frames[j];
          final List<BlockMark> cubes = marks<BlockMark>(f).toList();
          expect(cubes, hasLength(j), reason: '$why step $j');
          expect(cubes.any((BlockMark b) => b.empty), isFalse, reason: why);
          places.add(cubes.last.rect);
          final BadgeMark badge = marks<BadgeMark>(f).single;
          expect(badge.n, j, reason: '$why step $j counts from one');
          expect(badge.big, isFalse, reason: why);
          expect(badge.at, cubes.last.rect.topLeft, reason: why);
          final HandMark hand = marks<HandMark>(f).single;
          expect(hand.press, isTrue, reason: why);
          expect(
            cubes.last.rect.contains(hand.tip),
            isTrue,
            reason: '$why step $j: the fingertip is on the new place',
          );
          expect(
            (marks<CardMark>(f).single.child as HintHand).fingers,
            start,
            reason: '$why: the card stays on the group',
          );
          expect(marks<SeenMark>(f), hasLength(start), reason: why);
        }

        // The end: the answer badge takes the card's place, and the hand is on the right tile. No number above the answer is drawn.
        final HintFrame last = p.frames.last;
        expect(marks<CardMark>(last), isEmpty, reason: why);
        final BadgeMark answer = marks<BadgeMark>(last).single;
        expect(answer.n, more, reason: why);
        expect(answer.big, isTrue, reason: why);
        expect(marks<BlockMark>(last), hasLength(more), reason: why);
        expect(
          (marks<HandMark>(last).single.tip - g.optionTip(g.correctIndex)).distance,
          lessThan(0.5),
          reason: why,
        );
        for (final HintFrame f in p.frames) {
          for (final BadgeMark b in marks<BadgeMark>(f)) {
            expect(
              b.n,
              lessThanOrEqualTo(more),
              reason: '$why: the group ($start) is never counted into the total',
            );
          }
        }

        // Nothing covered: the new places stand inside the stage, under the group and beside the hand card, apart from each other.
        final List<Rect> group = g
            .withReserve(g.endCard.right + 6)
            .inReadingOrder(g.withReserve(g.endCard.right + 6).groupObjects(0));
        final Rect room = Offset.zero & g.size;
        for (final Rect r in places) {
          expect(
            room.contains(r.topLeft) && room.contains(r.bottomRight),
            isTrue,
            reason: '$why: $r is outside the stage',
          );
          expect(r.shortestSide, greaterThanOrEqualTo(24), reason: '$why: a place is too small to count');
          expect(r.overlaps(g.endCard), isFalse, reason: '$why: a place is under the hand card');
          for (final Rect o in group) {
            expect(r.overlaps(o), isFalse, reason: '$why: a place covers a picture of the group');
          }
        }
        for (int i = 1; i < places.length; i++) {
          expect(
            places[i].left,
            greaterThan(places[i - 1].right - 0.01),
            reason: '$why: the places are counted left to right',
          );
          expect(places[i].overlaps(places[i - 1]), isFalse, reason: why);
        }
      }
    }
  });
}
