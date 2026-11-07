// The last points of the C1 screens review (QA-C1b-1 to -4, and the two hints that did not fit their text), by the rules of the design spec:
//
//   1  an item whose options are blocks draws one cube size in every option (the block drawing and its tile are redesigned in a later
//      round, docs/design/c1-blocks.md; this is only the one-size rule);
//   2  the numerals of one item share one font size (the widest option's fit), so the right answer is never the largest;
//   3  the keypad keeps the Band C gap (12 points on a phone, 16 on a tablet) and the Band C key on a tablet (80);
//   4  the numbers and the question marks of a hundred chart are at least 12 points on every board;
//   5  hint 2 of the estimate line stands the frog in the middle, and hint 2 of a true-or-false card keeps its sentence.
//
//   flutter test --no-pub test/c1_qa_fixes_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/child/activity_shell.dart';
import 'package:nitznutz/content/models.dart';
import 'package:nitznutz/design/tokens.g.dart';
import 'package:nitznutz/play/hint_hand.dart';
import 'package:nitznutz/play/hints/hint_marks.dart';
import 'package:nitznutz/play/hints/tap_geometry.dart';
import 'package:nitznutz/play/hints/tap_plans.dart';
import 'package:nitznutz/play/lesson_controller.dart';
import 'package:nitznutz/play/number_entry.dart';
import 'package:nitznutz/play/number_line_session.dart';
import 'package:nitznutz/play/stage_pictures.dart';
import 'package:nitznutz/play/tap_answer_session.dart' show numeralFontOf;

import 'support/c1_screens.dart';
import 'support/fakes.dart';
import 'support/golden_comparator.dart';
import 'support/harness.dart';

const Map<String, ActivitySpec> _specs = <String, ActivitySpec>{
  'phone': ActivitySpec.phone,
  'phoneSE': ActivitySpec.phoneSE,
  'tabletL': ActivitySpec.tabletLandscape,
  'tabletP': ActivitySpec.tabletPortrait,
};

void main() {
  late PackContent content;
  late List<TapAnswerActivity> taps;

  setUpAll(() async {
    await loadAppFonts();
    useTolerantGoldens(0.03);
    content = await loadSourcePack();
    taps = bandCActivities(content).whereType<TapAnswerActivity>().toList();
  });

  test('the items with blocks on their tiles are the ones the review named', () {
    final List<String> ids = <String>[
      for (final TapAnswerActivity a in taps)
        if (TapGeometry.hasBlockTiles(a)) a.id,
    ];
    expect(ids, containsAll(<String>['c.numc02.18', 'c.numc02.19', 'c.numc02.20', 'c.numc03.25']));
  });

  group('1: the cube of every option of blocks', () {
    test('the unit of an item is the one that fits its widest and tallest option, on every board', () {
      for (final MapEntry<String, ActivitySpec> e in _specs.entries) {
        for (final TapAnswerActivity a in taps.where(TapGeometry.hasBlockTiles)) {
          final double unit = TapGeometry.blockUnitOf(a, e.value)!;
          expect(unit, greaterThan(0), reason: '${a.id} on ${e.key}');
          final Size box = TapGeometry.blockBoxOf(a, e.value);
          for (final ChoiceOption o in a.options) {
            final double own = BaseTenLayout.forBox(BaseTen.fromScene(o.picture!), box).unit;
            expect(own, greaterThanOrEqualTo(unit), reason: '${a.id} ${o.id} fits at the shared unit');
          }
        }
      }
    });

    test('a layout given a shared unit never draws bigger than the box lets it', () {
      const Size box = Size(150, 100);
      const BaseTen cubes = BaseTen(ones: 7);
      const BaseTen rods = BaseTen(tens: 7, ones: 3);
      expect(BaseTenLayout.forBox(cubes, box).unit, greaterThan(BaseTenLayout.forBox(rods, box).unit * 1.5));
      final double shared = BaseTenLayout.forBox(rods, box).unit;
      expect(BaseTenLayout.forBox(cubes, box, sharedUnit: shared).unit, shared);
      expect(BaseTenLayout.forBox(rods, box, sharedUnit: 99).unit, shared, reason: 'capped at the fit');
    });

    for (final (String name, Size size) in boards) {
      testWidgets(
        'on the $name board the pictures of every item of blocks are drawn with one cube size, and nothing overflows',
        (WidgetTester t) async {
          await t.runAsync(warmHintHands);
          await startOn(t, content, size);
          final List<String> problems = <String>[];
          await collectErrors((List<FlutterErrorDetails> sink) async {
            for (final TapAnswerActivity a in taps.where(TapGeometry.hasBlockTiles)) {
              await openOne(t, content, a);
              final List<double> units = <double>[];
              for (final ChoiceOption o in a.options) {
                final Finder tile = find.byKey(Key('tile-${o.id}'));
                final Finder pic = find.descendant(of: tile, matching: find.byType(BaseTenPicture));
                final BaseTenPicture p = t.widget<BaseTenPicture>(pic);
                units.add(BaseTenLayout.forBox(p.layoutOf, t.getSize(pic), sharedUnit: p.sharedUnit).unit);
              }
              expect(units.toSet().length, 1, reason: '${a.id} draws one cube size: $units');
              expect(
                units.first,
                TapGeometry.blockUnitOf(a, _specs[name]!),
                reason: '${a.id} the unit the geometry says',
              );
              problems.addAll(problemsOnScreen(t, sink).map((String p) => '${a.id}: $p'));
              await closeOne(t);
            }
          });
          expect(problems, isEmpty);
        },
      );

      testWidgets('on the $name board an item of blocks with rods and cubes only is drawn as the golden', (
        WidgetTester t,
      ) async {
        await startOn(t, content, size);
        await openOne(t, content, content.activities['c.numc03.25']!);
        await expectLater(find.byType(MaterialApp), matchesGoldenFile('goldens/c1c_block_options_$name.png'));
        await closeOne(t);
      });
    }
  });

  group('2: the numerals of one item share a font size', () {
    for (final (String name, Size size) in boards) {
      testWidgets('on the $name board every item of numeral tiles has one size, and none is scaled down', (
        WidgetTester t,
      ) async {
        await startOn(t, content, size);
        int items = 0;
        for (final TapAnswerActivity a in taps) {
          if (!a.optionsInTiles || a.numberAnswer != null) continue;
          if (a.options.where((ChoiceOption o) => o.numeral != null).length < 2) continue;
          await openOne(t, content, a);
          items++;
          final Set<double> sizes = <double>{};
          for (final ChoiceOption o in a.options) {
            if (o.numeral == null) continue;
            final Finder text = find.descendant(
              of: find.byKey(Key('tile-${o.id}')),
              matching: find.text('${o.numeral}'),
            );
            sizes.add(double.parse(t.widget<Text>(text).style!.fontSize!.toStringAsFixed(3)));
            final Finder fitted = find.ancestor(of: text, matching: find.byType(FittedBox)).first;
            expect(
              t.getSize(fitted).width,
              greaterThanOrEqualTo(t.getSize(text).width - 0.5),
              reason: '${a.id} ${o.numeral} is not scaled by the box',
            );
          }
          expect(sizes, hasLength(1), reason: '${a.id} sets its numerals at $sizes');
          await closeOne(t);
        }
        expect(items, greaterThan(10));
      });
    }

    test('the font is the 56 of the board when every numeral fits, and the widest one\'s fit when not', () {
      final TapAnswerActivity mixed = taps.firstWhere((TapAnswerActivity a) => a.id == 'c.mathc03.17');
      final double fitted = numeralFontOf(mixed, 56, 96);
      expect(fitted, lessThan(56));
      final TapAnswerActivity small = taps.firstWhere(
        (TapAnswerActivity a) =>
            a.optionsInTiles &&
            a.options.length >= 2 &&
            a.options.every((ChoiceOption o) => (o.numeral ?? 99) < 10),
      );
      expect(numeralFontOf(small, 56, 96), 56);
    });
  });

  group('3: the keypad', () {
    test('a gap of 12 on a phone and 16 on a tablet, keys of 56 and 80, two rows above the bottom band', () {
      for (final MapEntry<String, ActivitySpec> e in _specs.entries) {
        final ActivitySpec spec = e.value;
        final KeypadLayout k = KeypadLayout.of(spec);
        expect(k.key, spec.stageIsCard ? 80 : 56, reason: e.key);
        expect(k.gap, greaterThanOrEqualTo(spec.stageIsCard ? 16 : 12), reason: e.key);
        expect(k.rect(1).left - k.rect(0).right, k.gap);
        expect(k.rect(6).top - k.rect(0).bottom, k.gap);
        expect(
          k.width,
          lessThanOrEqualTo(spec.tilesWidth),
          reason: '${e.key} the row of keys is within the tiles',
        );
      }
    });

    for (final (String name, Size size) in boards) {
      testWidgets('on the $name board the drawn keys keep the gap and stand above the bottom band', (
        WidgetTester t,
      ) async {
        await startOn(t, content, size);
        final TapAnswerActivity a = taps.firstWhere((TapAnswerActivity x) => x.numberAnswer != null);
        await openOne(t, content, a);
        final bool tablet = size.shortestSide > 600;
        Rect key(String k) => t.getRect(
          find.descendant(of: find.byKey(Key('key-$k')), matching: find.byKey(const Key('answer-tile'))),
        );
        expect(key('2').left - key('1').right, greaterThanOrEqualTo(tablet ? 16 : 12));
        expect(key('6').top - key('1').bottom, greaterThanOrEqualTo(tablet ? 16 : 12));
        expect(key('1').width, tablet ? 80 : 56);
        final double slop = KeypadLayout.of(tablet ? ActivitySpec.tabletLandscape : ActivitySpec.phone).slop;
        expect(key('done').bottom + slop, lessThanOrEqualTo(size.height - TokenTouch.bottomNoHotspot));
        await closeOne(t);
      });
    }
  });

  group('4: the numbers of the hundred chart', () {
    test('never under 12 points on the small phone\'s stage, and a question mark as large as a number', () {
      expect(
        chartNumberSize(
          ChartLayout.forBox(ChartSpec.around(<int>{34}, <int>{44}), ActivitySpec.phoneSE.stage.size).cell,
          34,
        ),
        greaterThanOrEqualTo(12),
      );
      expect(chartNumberSize(19.2, 34), greaterThanOrEqualTo(12));
      expect(chartNumberSize(30, 100), lessThan(chartNumberSize(30, 99)));
    });

    for (final (String name, Size size) in boards) {
      testWidgets('on the $name board every number and question mark of a chart item is 12 points or more', (
        WidgetTester t,
      ) async {
        await startOn(t, content, size);
        int seen = 0;
        for (final TapAnswerActivity a in taps) {
          if (TapGeometry.stagePictureOf(a) != 'hundred_chart') continue;
          await openOne(t, content, a);
          for (final Element e in find.byWidgetPredicate((Widget w) {
            final Key? k = w.key;
            return k is ValueKey<String> &&
                (k.value.startsWith('chart-lit-') || k.value.startsWith('chart-blank-'));
          }).evaluate()) {
            expect(
              (e.widget as Text).style!.fontSize!,
              greaterThanOrEqualTo(12),
              reason: '${a.id} ${e.widget.key}',
            );
            seen++;
          }
          await closeOne(t);
        }
        expect(seen, greaterThan(8));
      });
    }
  });

  group('5: the hints that did not fit their text', () {
    testWidgets(
      'hint 2 of the estimate line stands the frog on the middle, 50, and hops it a tick towards the side of the number',
      (WidgetTester t) async {
        final LessonController c = LessonController(
          content: content,
          lesson: Lesson.mission(
            id: 'one',
            itemIds: <String>['c.numc06.17'],
            skillIds: <String>['NUM-C-06'],
            celebration: content.lessons['butterflies']!.celebration,
          ),
          profileId: 'p-1',
          clock: FixedClock(1793000000000),
          record: (_) async {},
        );
        final NumberLineActivity a = c.current as NumberLineActivity;
        expect(a.target, 64);
        final NumberLineSession s = NumberLineSession(c, a);
        const ActivitySpec spec = ActivitySpec.phone;
        await t.pumpWidget(
          MaterialApp(
            home: Directionality(
              textDirection: TextDirection.rtl,
              child: Scaffold(
                body: Builder(
                  builder: (BuildContext ctx) => SizedBox(
                    width: spec.stage.width,
                    height: spec.stage.height,
                    child: s.buildStage(ctx, spec.stage.size, spec),
                  ),
                ),
              ),
            ),
          ),
        );
        c.showHint();
        c.showHint();
        s.onHint();
        expect(s.markerAt, 50, reason: 'the hint says: the middle is fifty');
        await t.pump(const Duration(milliseconds: 900));
        expect(s.markerAt, 60, reason: 'and the number is on the side of the hundred');
        expect(s.trail, containsAll(<int>[50, 60]));
        expect(s.trail, isNot(contains(64)), reason: 'the tick of the answer is never lit');
        s.dispose();
        await t.pumpWidget(const SizedBox());
      },
    );

    test('hint 2 of a true-or-false card keeps its sentence: things over its numbers, no "?" card in the place of one', () {
      for (final String id in <String>['c.mathc02.16', 'c.mathc02.17', 'c.mathc02.18', 'c.mathc02.19']) {
        final TapAnswerActivity a = content.activities[id]! as TapAnswerActivity;
        for (final ActivitySpec spec in _specs.values) {
          final Size stage = spec.stageIsCard
              ? Size(spec.stage.width - 32, spec.stage.height - 32)
              : spec.stage.size;
          final HintPlan plan = tapHintPlan(a, TapGeometry(a, stage, spec), 2)!;
          final List<HintMark> all = <HintMark>[
            for (final HintFrame f in plan.frames) ...f.marks,
            ...plan.rest,
          ];
          expect(all.whereType<CardMark>(), isEmpty, reason: '$id: no card with a question mark');
          expect(all.whereType<BlockMark>(), isNotEmpty, reason: '$id shows the numbers as things');
        }
      }
    });

    test('the order card shows the six and then fifteen places of which only six are filled', () {
      final TapAnswerActivity a = content.activities['c.mathc02.16']! as TapAnswerActivity;
      const ActivitySpec spec = ActivitySpec.phone;
      final HintPlan plan = tapHintPlan(a, TapGeometry(a, spec.stage.size, spec), 2)!;
      expect(plan.frames, hasLength(2));
      final List<BlockMark> last = plan.rest.whereType<BlockMark>().toList();
      expect(last.where((BlockMark m) => !m.empty), hasLength(12), reason: 'six, and six of the fifteen');
      expect(last.where((BlockMark m) => m.empty), hasLength(9));
    });

    test('levels 1 and 3 of a card are the family\'s, as before', () {
      final TapAnswerActivity a = content.activities['c.mathc02.19']! as TapAnswerActivity;
      const ActivitySpec spec = ActivitySpec.phone;
      final TapGeometry g = TapGeometry(a, spec.stage.size, spec);
      expect(tapHintPlan(a, g, 1), isNotNull);
      expect(tapHintPlan(a, g, 3), isNotNull);
    });

    testWidgets('golden: the card and the estimate line at hint 2 on the phone', (WidgetTester t) async {
      await t.runAsync(warmHintHands);
      await startOn(t, content, const Size(852, 393));
      for (final (String name, String id) in <(String, String)>[
        ('estimate', 'c.numc06.17'),
        ('card', 'c.mathc02.16'),
      ]) {
        await openOne(t, content, content.activities[id]!);
        for (int level = 1; level <= 2; level++) {
          await t.tap(find.byKey(const Key('lesson-hint')), warnIfMissed: false);
          await waitSteps(t, 3500);
        }
        await expectLater(find.byType(MaterialApp), matchesGoldenFile('goldens/c1c_${name}_h2_phone.png'));
        await closeOne(t);
      }
    });
  });
}
