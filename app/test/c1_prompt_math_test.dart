// The number sentence in the speech bubble (owner, 2026-11-07): the four items of MATH-C-03 that say a sentence over rods ("אַרְבָּעִים וְעוֹד
// שְׁלוֹשִׁים. כַּמָּה זֶה?") also show it in numbers, "40 + 30 = ?", as an isolated left-to-right run with the signs of the equation rows. The
// run is a row of its own under the line; the bubble keeps clear of the answer tiles at every hint level on all four boards, at a larger
// system text size too, and its tail still meets the guide's mouth.
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/content/models.dart';
import 'package:nitznutz/child/activity_shell.dart';
import 'package:nitznutz/play/activity_frame.dart';
import 'package:nitznutz/play/math_run.dart';
import 'package:nitznutz/play/math_signs.dart';

import 'support/c1_screens.dart';
import 'support/harness.dart';

const Map<String, String> _runs = <String, String>{
  'c.mathc03.15': '40 + 30 = ?',
  'c.mathc03.16': '30 + 50 = ?',
  'c.mathc03.17': '70 − 40 = ?',
  'c.mathc03.18': '60 − 20 = ?',
};

void main() {
  late PackContent content;
  setUpAll(() async {
    await loadAppFonts();
    content = await loadSourcePack();
  });

  group('the run', () {
    test('is the tokens of a row with the signs of the equation rows', () {
      const List<String> sum = <String>['n:40', 'op:+', 'n:30', 'op:=', '?'];
      expect(MathRun.textOf(sum, DivisionSign.obelus), '40 + 30 = ?');
      expect(
        MathRun.textOf(<String>['n:70', 'op:-', 'n:40', 'op:=', '?'], DivisionSign.obelus),
        '70 − 40 = ?',
      );
      const List<String> share = <String>['n:12', 'op::', 'n:3', 'op:=', '?'];
      expect(
        MathRun.textOf(share, DivisionSign.obelus),
        '12 ÷ 3 = ?',
        reason: 'the division sign is ÷ by default',
      );
      expect(
        MathRun.textOf(share, DivisionSign.colon),
        '12 : 3 = ?',
        reason: 'and the colon when the parent chose it',
      );
      expect(MathRun.textOf(<String>['n:6', 'op:x', 'n:7'], DivisionSign.obelus), '6 × 7');
    });

    testWidgets(
      'is drawn left to right inside the right-to-left bubble, and the screen reader reads the Hebrew above it',
      (WidgetTester t) async {
        await t.pumpWidget(
          const Directionality(
            textDirection: TextDirection.rtl,
            child: MathRun(
              <String>['n:70', 'op:-', 'n:40', 'op:=', '?'],
              size: 26,
              division: DivisionSign.obelus,
            ),
          ),
        );
        final RenderParagraph p = t.renderObject<RenderParagraph>(find.byType(RichText));
        expect(p.textDirection, TextDirection.ltr);
        // The first number is at the left.
        expect(p.getBoxesForSelection(const TextSelection(baseOffset: 0, extentOffset: 2)).first.left, 0);
        expect(find.byType(ExcludeSemantics), findsWidgets);
      },
    );
  });

  group('the bubble measures what it draws', () {
    test('a larger text size makes the line taller, and the font shrinks to fit the same room, never under 14 points as drawn', () {
      const String line = 'אֵיפֹה הַמִּסְפָּר שְׁלוֹשִׁים וְאַרְבַּע?';
      const TextScaler big = TextScaler.linear(1.3);
      expect(
        ActivityFrame.bubbleHeight(line, 26, 190, scaler: big),
        greaterThan(ActivityFrame.bubbleHeight(line, 26, 190)),
      );
      final ({double font, double height, double width}) plain = ActivityFrame.fitBubble(
        line * 3,
        ActivitySpec.phone,
      );
      final ({double font, double height, double width}) scaled = ActivityFrame.fitBubble(
        line * 3,
        ActivitySpec.phone,
        scaler: big,
      );
      expect(scaled.font, lessThan(plain.font), reason: 'the line shrinks to the same room');
      expect(
        scaled.font * 1.3,
        greaterThanOrEqualTo(14 - 1e-9),
        reason: 'and is drawn at 14 points at least',
      );
      final ({double font, double height, double width}) tiny = ActivityFrame.fitBubble(
        line * 30,
        ActivitySpec.phone,
        scaler: big,
      );
      expect(tiny.font * 1.3, closeTo(14, 1e-9));
    });

    testWidgets('the system text size reaches the bubble up to 1.3 and no further', (WidgetTester t) async {
      late TextScaler seen;
      await t.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(2)),
          child: Builder(
            builder: (BuildContext context) {
              seen = ActivityFrame.bubbleScaler(context);
              return const SizedBox();
            },
          ),
        ),
      );
      expect(seen.scale(10), closeTo(13, 1e-9));
    });
  });

  group('in the bubble', () {
    for (final (String board, Size size) in boards) {
      // The bubble is measured with the scaler it is drawn with, the system's up to 1.3: a long prompt at a larger text size still fits.
      for (final double scale
          in board == 'phoneSE'
              ? <double>[1, 1.3]
              : board == 'phone'
              ? <double>[1, 1.15, 1.3]
              : <double>[1]) {
        testWidgets(
          'the run is on its own row, the bubble clears the tiles by 12 points or more at every hint level and the tail meets the mouth: $board, text x$scale',
          (WidgetTester t) async {
            t.platformDispatcher.textScaleFactorTestValue = scale;
            addTearDown(t.platformDispatcher.clearAllTestValues);
            await startOn(t, content, size);
            final List<String> problems = <String>[];
            // The four sentences over rods, and the where-is items (a long question over blocks on the tiles, no run).
            final Map<String, String?> items = <String, String?>{
              ..._runs,
              for (final String id in <String>['c.numc03.25', 'c.numc02.18', 'c.numc02.19', 'c.numc02.20'])
                id: null,
            };
            for (final MapEntry<String, String?> e in items.entries) {
              await openOne(t, content, content.activities[e.key]!);
              for (int level = 0; level <= 3; level++) {
                if (level > 0) {
                  await t.tap(find.byKey(const Key('lesson-hint')));
                  await waitSteps(t, level == 3 ? 1200 : 600);
                }
                final String at = '${e.key} level $level';
                final Finder run = find.byKey(const Key('bubble-math'));
                final Rect bubble = t.getRect(find.byKey(const Key('bubble-body')));
                if (e.value == null) {
                  expect(run, findsNothing, reason: at);
                } else if (run.evaluate().isEmpty) {
                  problems.add('$at: no run');
                  continue;
                } else {
                  expect(t.widget<Text>(run).data, e.value, reason: at);
                  final Rect line = t.getRect(
                    find
                        .descendant(of: find.byKey(const Key('bubble-body')), matching: find.byType(Text))
                        .first,
                  );
                  final Rect runBox = t.getRect(run);
                  if (runBox.top < line.bottom) problems.add('$at: the run is not under the line');
                  if (runBox.bottom > bubble.bottom) problems.add('$at: the run is outside the bubble');
                }
                // The drawn top of a tile is 12 points under its tap box.
                final double clear = t.getRect(find.byKey(const Key('tile-o1'))).top + 12 - bubble.bottom;
                if (clear < 12) problems.add('$at: the bubble ends $clear points over the tiles');
                final Rect guide = t.getRect(find.byKey(const Key('activity-nitzi')));
                final double mouth = guide.top + 0.576 * guide.height;
                final double tail = t.getRect(find.byKey(const Key('bubble-pointer'))).center.dy;
                if (board.startsWith('phone') && (tail - mouth).abs() > 12) {
                  problems.add('$at: the tail at $tail, the mouth at $mouth');
                }
              }
              await closeOne(t);
            }
            expect(problems, isEmpty);
          },
          timeout: const Timeout(Duration(minutes: 5)),
        );
      }
    }

    testWidgets('the run stays under a "not yet", and goes with the praise', (WidgetTester t) async {
      await startOn(t, content, const Size(852, 393));
      final TapAnswerActivity a = content.activities['c.mathc03.15']! as TapAnswerActivity;
      await openOne(t, content, a);
      final String wrong = a.options.firstWhere((ChoiceOption o) => o.id != a.correctId).id;
      await t.tap(find.byKey(Key('tile-$wrong')));
      await waitSteps(t, 300);
      expect(find.byKey(const Key('bubble-math')), findsOneWidget, reason: 'the question is still open');
      await waitSteps(t, 1500);
      await t.tap(find.byKey(Key('tile-${a.correctId}')));
      await waitSteps(t, 300);
      expect(
        find.byKey(const Key('bubble-math')),
        findsNothing,
        reason: 'the praise has the bubble to itself',
      );
      await waitSteps(t, 2500);
    });

    testWidgets('an item with no sentence has no run', (WidgetTester t) async {
      await startOn(t, content, const Size(852, 393));
      await openOne(t, content, content.activities['c.numc03.25']!);
      expect(find.byKey(const Key('bubble-math')), findsNothing);
      await closeOne(t);
    });
  });
}
