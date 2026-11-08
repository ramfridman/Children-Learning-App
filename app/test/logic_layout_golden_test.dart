// Golden screenshots of the layouts of the logic land's sweep (2026-11-06), on the small phone and on the tablet:
//  - a size item (log.size.last): the row and the answer tiles draw the balls at one scale, so a medium ball on a tile is the size
//    of the row's medium ball; and one with a row of 6 (b15.loga06.1), in two lines on a taller stage on the phones;
//  - a row of 8 cells to spot the mistake in (b.logb02.2): two lines of cells that can be read, not one line of 12 point pictures;
//  - a sort into two bins (b.logb08.1): the sample picture of each bin large enough to read.
// The rules behind them are tested in logic_layout_test.dart.
//
// Regenerate after a deliberate visual change:  flutter test --update-goldens test/logic_layout_golden_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/content/models.dart';
import 'package:nitznutz/play/lesson_screen.dart';

import 'support/app_harness.dart';
import 'support/golden_comparator.dart';
import 'support/harness.dart';
import 'support/starter.dart';

Future<void> _wait(WidgetTester t, int ms) async {
  for (int spent = 0; spent < ms; spent += 100) {
    await t.pump(const Duration(milliseconds: 100));
  }
  await t.pump(const Duration(milliseconds: 50));
}

const List<(String, String)> _shots = <(String, String)>[
  ('log.size.last', 'size_row_and_tiles'),
  ('b15.loga06.1', 'size_row_of_6'),
  ('b.logb02.2', 'spot_8_cells'),
  ('b.logb08.1', 'bins'),
];

void main() {
  setUpAll(() async {
    await loadAppFonts();
    useTolerantGoldens(0.03);
  });

  for (final (String, Size) device in <(String, Size)>[
    ('phone_se', const Size(667, 375)),
    ('tablet_landscape', const Size(1180, 820)),
  ]) {
    testWidgets('the logic layouts, ${device.$1}', (WidgetTester tester) async {
      final AppRig rig = AppRig();
      await rig.seedFinishedSetup(name: 'נֹעָה');
      await rig.pump(tester, size: device.$2);
      await tester.tap(find.text('נֹעָה'));
      await tester.pumpAndSettle();
      final PackContent content = await loadStarter();
      for (final (String activity, String name) in _shots) {
        final NavigatorState nav = tester.state<NavigatorState>(find.byType(Navigator).first);
        final Lesson one = Lesson.mission(
          id: 'shot',
          itemIds: <String>[activity],
          skillIds: content.activities[activity]!.skills.map((Skill s) => s.id).toList(),
          celebration: content.lessons['butterflies']!.celebration,
        );
        nav.push(
          MaterialPageRoute<void>(
            builder: (BuildContext c) => LessonScreen(profileId: 'p-1', mission: one),
          ),
        );
        await tester.pump(const Duration(milliseconds: 600));
        await _wait(tester, 1500);
        await expectLater(
          find.byType(MaterialApp),
          matchesGoldenFile('goldens/logic_${name}_${device.$1}.png'),
        );
        nav.pop();
        await tester.pump(const Duration(milliseconds: 600));
      }
    });
  }
}
