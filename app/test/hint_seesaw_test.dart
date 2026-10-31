import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/child/activity_shell.dart';
import 'package:nitznutz/content/models.dart';
import 'package:nitznutz/design/token_types.dart' show Band;
import 'package:nitznutz/play/hints/hint_marks.dart';
import 'package:nitznutz/play/hints/hint_pictures.dart';
import 'package:nitznutz/play/hints/seesaw_picture.dart';
import 'package:nitznutz/play/hints/tap_geometry.dart';
import 'package:nitznutz/play/hints/tap_plans.dart';

import 'support/harness.dart';
import 'support/starter.dart';

/// B-40, TA-11 heavy and light (MATH-A-04): the seesaw. Level 1 lights the two things; level 2 stands them on a seesaw that two
/// blocks hold level (nothing weighed, no tile marked); level 3 the hand takes the blocks away, the plank tips the heavy end down,
/// and the hand ends on the right tile. With "reduce motion" the plank does not turn: the tipped plank fades in.
void main() {
  late PackContent content;
  setUpAll(() async {
    await loadAppFonts();
    content = await loadStarter();
  });

  const List<String> ids = <String>['math.size.heavy', 'math.size.light'];
  const List<ActivitySpec> boards = <ActivitySpec>[
    ActivitySpec.phone,
    ActivitySpec.phoneSE,
    ActivitySpec.tabletLandscape,
    ActivitySpec.tabletPortrait,
  ];
  Size stageOf(ActivitySpec s) =>
      s.stageIsCard ? Size(s.stage.width - 32, s.stage.height - 32) : s.stage.size;
  TapAnswerActivity act(String id) => content.activities[id]! as TapAnswerActivity;
  TapGeometry geo(TapAnswerActivity a, ActivitySpec s) => TapGeometry(a, stageOf(s), s);
  String stoneOf(TapAnswerActivity a) =>
      a.options.firstWhere((ChoiceOption o) => o.sprite!.contains('stone')).sprite!;
  String featherOf(TapAnswerActivity a) =>
      a.options.firstWhere((ChoiceOption o) => o.sprite!.contains('feather')).sprite!;

  test('level 1 lights the two things in turn and draws no seesaw', () {
    for (final String id in ids) {
      for (final ActivitySpec s in boards) {
        final TapAnswerActivity a = act(id);
        final HintPlan p = tapHintPlan(a, geo(a, s), 1)!;
        expect(p.frames.map((HintFrame f) => f.litOption), <int>[0, 1], reason: id);
        expect(p.frames.expand((HintFrame f) => f.marks), isEmpty, reason: id);
        expect(p.endsDemo, isFalse);
      }
    }
  });

  test(
    'level 2 is the seesaw held level by two blocks, the things in the order of their tiles, no tile marked',
    () {
      for (final String id in ids) {
        for (final ActivitySpec s in boards) {
          final TapAnswerActivity a = act(id);
          final TapGeometry g = geo(a, s);
          final HintPlan p = tapHintPlan(a, g, 2)!;
          expect(p.endsDemo, isFalse, reason: id);
          final List<HintMark> all = <HintMark>[...p.frames.expand((HintFrame f) => f.marks), ...p.rest];
          expect(all.whereType<HandMark>(), isEmpty, reason: '$id: no hand at level 2');
          expect(all.whereType<TileMark>(), isEmpty, reason: '$id: no tile is marked');
          expect(p.frames.where((HintFrame f) => f.litOption != null), isEmpty, reason: id);
          for (final SeesawMark m in all.whereType<SeesawMark>()) {
            expect(m.down, 0, reason: '$id: level, not tipped');
            expect(m.propLeft && m.propRight, isTrue, reason: '$id: both blocks under it');
          }
          final SeesawMark m = p.rest.whereType<SeesawMark>().single;
          // The thing on the left end is the one whose tile is on the left (the tiles run right to left).
          final int leftTile = g.optionTip(0).dx < g.optionTip(1).dx ? 0 : 1;
          expect(m.left, inkedSvg(a.assets.svg(a.options[leftTile].sprite!)).$1, reason: id);
          expect(m.right, inkedSvg(a.assets.svg(a.options[1 - leftTile].sprite!)).$1, reason: id);
          expect(m.rect, Offset.zero & g.size, reason: id);
        }
      }
      // The two items show their tiles in opposite orders, so their seesaws are mirror images of each other in what stands where.
      final TapAnswerActivity heavy = act('math.size.heavy');
      final TapAnswerActivity light = act('math.size.light');
      SeesawMark l2(TapAnswerActivity a) =>
          tapHintPlan(a, geo(a, ActivitySpec.phone), 2)!.rest.whereType<SeesawMark>().single;
      expect(l2(heavy).left, inkedSvg(heavy.assets.svg(stoneOf(heavy))).$1, reason: 'stone tile on the left');
      expect(
        l2(light).left,
        inkedSvg(light.assets.svg(featherOf(light))).$1,
        reason: 'feather tile on the left',
      );
    },
  );

  test('level 3 takes the light end\'s block, then the heavy end\'s; the stone end tips down; the hand ends on the answer', () {
    for (final String id in ids) {
      for (final ActivitySpec s in boards) {
        final TapAnswerActivity a = act(id);
        final TapGeometry g = geo(a, s);
        final HintPlan p = tapHintPlan(a, g, 3)!;
        expect(p.endsDemo, isTrue, reason: id);
        final List<SeesawMark> saws = <SeesawMark>[
          for (final HintFrame f in p.frames) f.marks.whereType<SeesawMark>().single,
        ];
        // The seesaw is the first mark of every step (so the overlay keeps one seesaw and turns its plank).
        for (final HintFrame f in p.frames) {
          expect(f.marks.first, isA<SeesawMark>(), reason: id);
        }
        final SeesawMark l2 = tapHintPlan(a, g, 2)!.rest.whereType<SeesawMark>().single;
        final bool stoneLeft = l2.left == inkedSvg(a.assets.svg(stoneOf(a))).$1;
        expect(saws.first.down, 0, reason: id);
        expect(saws.first.propLeft && saws.first.propRight, isTrue, reason: id);
        // Step 2: only the light end's block is gone, and the plank is still level.
        expect(saws[1].down, 0, reason: id);
        expect(
          stoneLeft ? saws[1].propLeft : saws[1].propRight,
          isTrue,
          reason: '$id: the heavy end still on its block',
        );
        expect(
          stoneLeft ? saws[1].propRight : saws[1].propLeft,
          isFalse,
          reason: '$id: the light end\'s block is gone',
        );
        // Then both are gone and the stone's end is down, to the end.
        for (final SeesawMark m in saws.skip(2)) {
          expect(m.down, stoneLeft ? -1 : 1, reason: '$id: the stone end rests on the ground');
          expect(m.propLeft || m.propRight, isFalse, reason: id);
        }
        final Offset answer = g.optionTip(g.correctIndex);
        final HandMark last = p.frames.last.marks.whereType<HandMark>().single;
        expect((last.tip - answer).distance, lessThan(0.5), reason: '$id ends on the right tile');
        expect(last.press, isTrue);
        for (final HintFrame f in p.frames.take(p.frames.length - 1)) {
          for (final HandMark h in f.marks.whereType<HandMark>()) {
            expect((h.tip - answer).distance, greaterThan(20), reason: '$id: the answer only at the end');
            expect(
              (Offset.zero & g.size).contains(h.tip),
              isTrue,
              reason: '$id: the hand works on the stage first',
            );
          }
        }
      }
    }
  });

  test(
    'the seesaw fits every stage, level and tipped: the plank and the thing on the high end stay inside',
    () {
      for (final ActivitySpec s in boards) {
        final SeesawBox b = SeesawBox(stageOf(s));
        final double t = b.tilt;
        expect(t, greaterThan(10 * math.pi / 180));
        expect(t, lessThan(20 * math.pi / 180));
        // The high end: the outer top corner of the box a thing is drawn in, turned about the pivot.
        final Offset corner = Offset(-(b.thingX + b.thingW / 2), -(b.thick / 2 + b.thingH));
        final double top = b.pivotY + corner.dx * math.sin(t) + corner.dy * math.cos(t);
        expect(top, greaterThanOrEqualTo(0), reason: '${s.stage}');
        expect(b.cx - b.half, greaterThan(0), reason: '${s.stage}');
        expect(b.cx + b.half, lessThan(stageOf(s).width), reason: '${s.stage}');
        // The low end's pad rests on the floor, no lower.
        final double pad = b.pivotY + b.padX * math.sin(t) + (b.thick / 2 + b.padH) * math.cos(t);
        expect(pad, closeTo(b.ground, 0.01), reason: '${s.stage}');
      }
    },
  );

  Future<double> plankAfter(WidgetTester t, {required bool still, required Duration after}) async {
    final TapAnswerActivity a = act('math.size.heavy');
    final TapGeometry g = geo(a, ActivitySpec.phone);
    final HintPlan p = tapHintPlan(a, g, 3)!;
    final SeesawMark level = p.frames.first.marks.whereType<SeesawMark>().single;
    final SeesawMark tipped = p.frames.last.marks.whereType<SeesawMark>().single;
    Widget overlay(SeesawMark m) => MediaQuery(
      data: MediaQueryData(disableAnimations: still),
      child: Center(
        child: HintOverlay(marks: <HintMark>[m], size: g.size),
      ),
    );
    await pumpScreen(t, overlay(level), band: Band.a);
    await t.pump(const Duration(milliseconds: 400));
    await pumpScreen(t, overlay(tipped), band: Band.a);
    await t.pump(after);
    final CustomPaint plank = t.widget<CustomPaint>(find.byKey(const Key('hint-seesaw-plank')));
    return (plank.painter! as SeesawPlankPainter).t;
  }

  testWidgets('the plank tips slowly where motion is allowed', (WidgetTester t) async {
    final double early = await plankAfter(t, still: false, after: const Duration(milliseconds: 300));
    expect(early.abs(), greaterThan(0.0));
    expect(early.abs(), lessThan(0.5), reason: 'still on its way after 300 ms');
    await t.pump(const Duration(milliseconds: 1500));
    final CustomPaint plank = t.widget<CustomPaint>(find.byKey(const Key('hint-seesaw-plank')));
    expect((plank.painter! as SeesawPlankPainter).t.abs(), 1);
  });

  testWidgets('with reduce motion the plank does not turn: the tipped plank is there at once and fades in', (
    WidgetTester t,
  ) async {
    final double t0 = await plankAfter(t, still: true, after: Duration.zero);
    expect(t0.abs(), 1, reason: 'no tilt animation');
    // It fades in, in 200 ms.
    final Opacity fade = t.widget<Opacity>(
      find.ancestor(of: find.byKey(const Key('hint-seesaw-plank')), matching: find.byType(Opacity)).first,
    );
    expect(fade.opacity, lessThan(1));
    await t.pump(const Duration(milliseconds: 250));
    expect(
      t
          .widget<Opacity>(
            find
                .ancestor(of: find.byKey(const Key('hint-seesaw-plank')), matching: find.byType(Opacity))
                .first,
          )
          .opacity,
      1,
    );
  });
}
