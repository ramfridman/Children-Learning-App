// The pictures of blocks on the four boards that the design note (docs/design/c1-blocks.md) mocked up: the lit rod, the crossed rods
// (the sentence said in the question), and two numbers to compare (the how-many and where-is items are in `golden_c1_test.dart` and
// `c1_qa_fixes_test.dart`).
// The worst case, 98 (nine rods and eight cubes), is not in the pack; its cube is computed here.
//
// Regenerate after a deliberate visual change:  flutter test --update-goldens test/c1_block_boards_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/child/activity_shell.dart';
import 'package:nitznutz/content/models.dart';
import 'package:nitznutz/play/block_layout.dart';
import 'package:nitznutz/play/stage_pictures.dart';

import 'support/c1_screens.dart';
import 'support/golden_comparator.dart';
import 'support/harness.dart';

const List<(String, String)> _items = <(String, String)>[
  ('lit_rod', 'c.numc03.24'),
  ('crossed_rods', 'c.mathc03.17'),
  ('compare', 'c.numc04.13'),
];

void main() {
  late PackContent content;
  setUpAll(() async {
    await loadAppFonts();
    useTolerantGoldens(0.03);
    content = await loadSourcePack();
  });

  for (final (String board, Size size) in boards) {
    testWidgets('the lit rod, the crossed rods and a comparison on the $board board', (WidgetTester t) async {
      await startOn(t, content, size);
      final List<String> problems = <String>[];
      await collectErrors((List<FlutterErrorDetails> sink) async {
        for (final (String name, String id) in _items) {
          await openOne(t, content, content.activities[id]!);
          await expectLater(
            find.byType(MaterialApp),
            matchesGoldenFile('goldens/c1_block_${name}_$board.png'),
          );
          problems.addAll(problemsOnScreen(t, sink).map((String p) => '$id: $p'));
          await closeOne(t);
        }
      });
      expect(problems, isEmpty);
    }, timeout: const Timeout(Duration(minutes: 5)));
  }

  for (final (String board, Size size) in boards.take(2)) {
    testWidgets(
      'on the $board board the tail of the bubble of every item of blocks meets the mouth of the guide (B-34, QA-C1c-3)',
      (WidgetTester t) async {
        await startOn(t, content, size);
        final List<TapAnswerActivity> withBlocks = <TapAnswerActivity>[
          for (final Activity a in bandCActivities(content))
            if (a is TapAnswerActivity && BlockLayout.hasBlocks(a)) a,
        ];
        expect(withBlocks.length, greaterThanOrEqualTo(15));
        expect(
          withBlocks.map((TapAnswerActivity a) => a.id),
          containsAll(<String>[
            'c.mathc03.15',
            'c.mathc03.16',
            'c.mathc03.17',
            'c.mathc03.18',
            'c.numc03.25',
          ]),
        );
        final List<String> off = <String>[];
        for (final TapAnswerActivity a in withBlocks) {
          await openOne(t, content, a);
          final Rect bubble = t.getRect(find.byKey(const Key('bubble-body')));
          final Rect guide = t.getRect(find.byKey(const Key('activity-nitzi')));
          // The tail is the small wedge on the bubble's end side; its centre is where it points. Nitzi's mouth is at 0.576 of the picture's
          // height (the svg's mouth at 295 of 512), wherever the bubble stands and however tall it is.
          final double tail = t.getRect(find.byKey(const Key('bubble-pointer'))).center.dy;
          final double mouth = guide.top + ActivitySpec.mouthShare * guide.height;
          if ((tail - mouth).abs() > 12) off.add('${a.id}: the tail at $tail, the mouth at $mouth');
          expect(
            guide.left - bubble.right,
            inInclusiveRange(0, 16),
            reason: '${a.id}: the tail reaches the guide',
          );
          // It does not lie over a tile, and the question keeps the band's size.
          expect(problemsOnScreen(t, <FlutterErrorDetails>[]), isEmpty, reason: a.id);
          await closeOne(t);
        }
        expect(off, isEmpty);
      },
      timeout: const Timeout(Duration(minutes: 5)),
    );
  }

  test('98, nine rods and eight cubes, fits the stage of the smallest phone with a cube over the floor', () {
    const BaseTen n = BaseTen(tens: 9, ones: 8);
    final Size stage = BlockLayout.forStage(ActivitySpec.phoneSE).stage.size;
    final Size box = Size(
      stage.width - 2 * BaseTenLayout.stageMargin,
      stage.height - 2 * BaseTenLayout.stageMargin,
    );
    final BaseTenLayout l = BaseTenLayout.forBox(n, box, standing: true, maxUnit: 22);
    expect(l.unit, greaterThanOrEqualTo(13.8));
    for (final Rect r in l.all) {
      expect(r.left, greaterThanOrEqualTo(0));
      expect(r.right, lessThanOrEqualTo(box.width));
      expect(r.bottom, lessThanOrEqualTo(box.height));
    }
  });
}
