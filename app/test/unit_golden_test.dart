// Golden screenshots of the new Counting Hills activities (tap_answer 1.1 with numerals, sets and groups; the flash),
// on a phone and on a tablet, in right to left with the real fonts.
//
// Regenerate after a deliberate visual change:  flutter test --update-goldens test/unit_golden_test.dart
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

/// (activity, name of the picture, milliseconds to wait before it is taken)
const List<(String, String, int)> _shots = <(String, String, int)>[
  ('next.after.2', 'next_number', 900),
  ('flash.dice.3', 'flash_dice', 2000),
  ('flash.dice.3', 'flash_covered', 3800),
  ('numeral.stars.3', 'set_to_numeral', 900),
  ('show.birds.4', 'numeral_to_set', 900),
  ('same.apples.4v5', 'same_or_not', 900),
  ('more.big.apples', 'more_big_things', 900),
  ('ordinal.third.of4', 'ordinal', 900),
  ('zero.nest', 'zero', 900),
  ('count.apples.7', 'count_seven', 900),
  ('col.find.red.balloon', 'colour_find', 900),
  ('col.sort.red', 'colour_sort', 900),
  ('col.world.banana', 'colour_banana', 900),
  ('log.next.colours', 'logic_next', 900),
  ('log.sort.colour', 'logic_sort', 900),
  ('log.size.middle', 'logic_size', 900),
  ('log.pat.no.mixed', 'logic_pattern_yes_no', 900),
];

void main() {
  setUpAll(() async {
    await loadAppFonts();
    useTolerantGoldens(0.03);
  });

  for (final (String, Size) device in <(String, Size)>[
    ('phone', const Size(852, 393)),
    ('tablet_landscape', const Size(1180, 820)),
  ]) {
    testWidgets('the new activities, ${device.$1}', (WidgetTester tester) async {
      final AppRig rig = AppRig();
      await rig.seedFinishedSetup(name: 'נֹעָה');
      await rig.pump(tester, size: device.$2);
      await tester.tap(find.text('נֹעָה'));
      await tester.pumpAndSettle();
      final PackContent content = await loadStarter();
      for (final (String, String, int) shot in _shots) {
        final NavigatorState nav = tester.state<NavigatorState>(find.byType(Navigator).first);
        final Lesson one = Lesson.mission(
          id: 'shot',
          itemIds: <String>[shot.$1],
          skillIds: content.activities[shot.$1]!.skills.map((Skill s) => s.id).toList(),
          celebration: content.lessons['butterflies']!.celebration,
        );
        nav.push(
          MaterialPageRoute<void>(
            builder: (BuildContext c) => LessonScreen(profileId: 'p-1', mission: one),
          ),
        );
        await tester.pump(const Duration(milliseconds: 600));
        await _wait(tester, shot.$3);
        await expectLater(
          find.byType(MaterialApp),
          matchesGoldenFile('goldens/unit_${shot.$2}_${device.$1}.png'),
        );
        nav.pop();
        await tester.pump(const Duration(milliseconds: 600));
      }
    });
  }
}
