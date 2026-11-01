import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/child/activity_shell.dart';
import 'package:nitznutz/content/models.dart';
import 'package:nitznutz/play/hints/hint_marks.dart';
import 'package:nitznutz/play/hints/tap_geometry.dart';
import 'package:nitznutz/play/hints/tap_plans.dart';

import 'support/starter.dart';

/// B-38 (item 5): the transfer items of SHP-A-08 show a cat and a basket (`pos_cat_in`, `pos_cat_on`, `pos_cat_next`). The hint
/// for them acts the relation out with the duck and a basket of its own, never with the picture of the answer tile. The bundled
/// pack does not have these pictures yet, so the activity is made here from `b15.shpa08.1` with the next pack's sprite names.
void main() {
  late PackContent content;
  setUpAll(() async {
    content = await loadStarter();
  });

  const ActivitySpec spec = ActivitySpec.phone;

  /// An activity of the shape of `b15.shpa08.1` whose tiles are the cat pictures [tiles] (o1, o2, o3), the right one [right].
  TapAnswerActivity catItem(List<String> tiles, int right) {
    final Map<String, Object?> json =
        jsonDecode(jsonEncode(content.activities['b15.shpa08.1']!.json)) as Map<String, Object?>;
    final Map<String, Object?> answer = json['answer']! as Map<String, Object?>;
    final List<Object?> options = answer['options']! as List<Object?>;
    for (int i = 0; i < 3; i++) {
      (options[i]! as Map<String, Object?>)['sprite'] = 'asset:${tiles[i]}';
    }
    answer['correct'] = 'o${right + 1}';
    final Map<String, String> svg = <String, String>{
      for (final String t in tiles) t: '<svg viewBox="0 0 10 10"><title>$t</title></svg>',
      'duck': content.assets.svg('asset:duck'),
    };
    return Activity.fromJson(json, PackAssets(svg)) as TapAnswerActivity;
  }

  HintPlan plan(TapAnswerActivity a, int level) =>
      tapHintPlan(a, TapGeometry(a, spec.stage.size, spec), level)!;

  const List<String> tiles = <String>['pos_cat_on', 'pos_cat_in', 'pos_cat_next'];

  String thingOf(TapAnswerActivity a, HintPlan p) {
    final String duck = a.assets.svg('asset:duck');
    return p.rest.whereType<CopyMark>().map((CopyMark m) => m.svg).firstWhere((String s) => s != duck);
  }

  test('the cat items get the position card (a duck and a basket), not the generic hint', () {
    for (final (int, String) right in <(int, String)>[(0, 'on'), (1, 'in'), (2, 'next')]) {
      final TapAnswerActivity a = catItem(tiles, right.$1);
      final HintPlan l2 = plan(a, 2);
      final List<CopyMark> drawn = l2.rest.whereType<CopyMark>().toList();
      expect(drawn, hasLength(2), reason: right.$2);
      expect(l2.rest.whereType<CardMark>(), hasLength(1), reason: '${right.$2}: a sky card');
      expect(
        drawn.map((CopyMark m) => m.svg),
        contains(a.assets.svg('asset:duck')),
        reason: '${right.$2}: the toy is the duck',
      );
    }
  });

  test('the card never shows a picture of the tiles, and the basket is the hint\'s own', () {
    for (int right = 0; right < 3; right++) {
      final TapAnswerActivity a = catItem(tiles, right);
      final Set<String> tileArt = <String>{for (final ChoiceOption o in a.options) a.assets.svg(o.sprite!)};
      final List<CopyMark> drawn = plan(a, 2).rest.whereType<CopyMark>().toList();
      for (final CopyMark m in drawn) {
        expect(tileArt, isNot(contains(m.svg)), reason: 'right is tile $right');
      }
      expect(thingOf(a, plan(a, 2)), contains('<path'), reason: 'a drawn basket');
    }
  });

  test(
    'in: an open basket drawn over the duck; on: the duck over a basket with a lid; next to: side by side',
    () {
      TapAnswerActivity a = catItem(tiles, 1);
      HintPlan p = plan(a, 2);
      final String duck = a.assets.svg('asset:duck');
      Rect rect(HintPlan p, bool toy) =>
          p.rest.whereType<CopyMark>().firstWhere((CopyMark m) => (m.svg == duck) == toy).rect;
      final List<String> inOrder = p.rest.whereType<CopyMark>().map((CopyMark m) => m.svg).toList();
      expect(inOrder.first, duck, reason: 'in: the basket is drawn over the duck');
      expect(
        rect(p, true).center.dy,
        lessThan(rect(p, false).center.dy),
        reason: 'in: the duck is in the top of the basket',
      );
      expect(rect(p, true).center.dx, closeTo(rect(p, false).center.dx, 0.5));
      final String open = thingOf(a, p);

      a = catItem(tiles, 0);
      p = plan(a, 2);
      expect(
        p.rest.whereType<CopyMark>().first.svg,
        isNot(duck),
        reason: 'on: the duck is drawn over the basket',
      );
      expect(
        rect(p, true).bottom,
        lessThan(rect(p, false).center.dy),
        reason: 'on: the duck is over the basket',
      );
      expect(thingOf(a, p), isNot(open), reason: 'on: a basket with a lid, not the open one');

      a = catItem(tiles, 2);
      p = plan(a, 2);
      expect(rect(p, true).left, greaterThan(rect(p, false).center.dx), reason: 'next to: side by side');
      expect((rect(p, true).center.dy - rect(p, false).center.dy).abs(), lessThan(rect(p, false).height / 2));
    },
  );

  test('the same relation is drawn the same way whichever tile is right and wherever the tiles stand', () {
    final HintPlan a = plan(catItem(<String>['pos_cat_in', 'pos_cat_on', 'pos_cat_next'], 0), 2);
    final HintPlan b = plan(catItem(<String>['pos_cat_next', 'pos_cat_in', 'pos_cat_on'], 1), 2);
    expect(
      a.rest.whereType<CopyMark>().map((CopyMark m) => m.rect).toList(),
      b.rest.whereType<CopyMark>().map((CopyMark m) => m.rect).toList(),
    );
  });

  test('level 1 and level 3 still have their plans', () {
    final TapAnswerActivity a = catItem(tiles, 1);
    expect(plan(a, 1).frames, isNotEmpty);
    expect(plan(a, 3).frames, isNotEmpty);
  });
}
