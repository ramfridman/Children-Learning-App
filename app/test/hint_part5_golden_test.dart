// Golden screenshots of B-40 part 5, the last three templates, on a phone: the shop (x.mathb17.6: pay 8 shekels with 3 + 2 + 1
// coins), the balance (a hidden lean, a lean that shows, and weighing) and spot the mistake in Band B (level 2 by family). The same
// lesson screen the child sees, with the lamp pressed once for each level; the level 3 pictures are taken at a telling moment of the
// demonstration. A few are also taken on the tablet.
//
// Regenerate after a deliberate visual change:  flutter test --update-goldens test/hint_part5_golden_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/content/models.dart';
import 'package:nitznutz/play/hint_hand.dart';
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

/// How long each level before the last one plays.
const int gapMs = 6000;

/// One picture: the activity, the level the lamp is pressed up to, how long the last level plays before the picture is taken, and
/// the name.
class _Shot {
  const _Shot(this.activity, this.level, this.name, {this.waitMs = 1500});

  final String activity;
  final int level;
  final String name;
  final int waitMs;
}

const List<_Shot> _phone = <_Shot>[
  // The shop: the places for the eight shekels, the biggest coin, the hand taking the coins one by one and ending on the button.
  _Shot('x.mathb17.6', 1, 'shop_l1', waitMs: 800),
  _Shot('x.mathb17.6', 2, 'shop_l2', waitMs: 1200),
  _Shot('x.mathb17.6', 3, 'shop_l3', waitMs: 900 + 700),
  _Shot('x.mathb17.6', 3, 'shop_l3_pay', waitMs: 900 * 3 + 700),
  // The balance, a hidden lean (5 + 4 against 3 + 2): the peg, the towers on one floor, the hand from the lower pan to the arrow.
  _Shot('b.mathb09.5', 1, 'balance_l1', waitMs: 500),
  _Shot('b.mathb09.5', 2, 'balance_l2', waitMs: 800),
  _Shot('b.mathb09.5', 3, 'balance_l3', waitMs: 1700 + 800 + 600),
  // A lean that shows (a stone against a feather): the towers and the dotted line through the pivot.
  _Shot('b.mathb13.5', 2, 'balance_shown_l2', waitMs: 800),
  // Weighing: the missing cubes as empty places, the hand pressing plus while the cubes go on.
  _Shot('b.mathb13.7', 1, 'balance_weigh_l1', waitMs: 500),
  _Shot('b.mathb13.7', 2, 'balance_weigh_l2', waitMs: 800),
  _Shot('b.mathb13.7', 3, 'balance_weigh_l3', waitMs: 700 * 2 + 600),
  // Spot the mistake, level 2 by family.
  _Shot('b.numb11.1', 2, 'spot_numbers_l2', waitMs: 700 * 6),
  _Shot('b.mathb03.9', 2, 'spot_sentence_l2', waitMs: 700 * 7),
  _Shot('b.logb02.1', 2, 'spot_pattern_l2', waitMs: 700 * 10),
  _Shot('b.csb04.1', 2, 'spot_program_l2', waitMs: 700 * 8),
  _Shot('b.logb11.4', 2, 'spot_seriation_l2', waitMs: 700 * 7),
  _Shot('b.colb06.5', 2, 'spot_rainbow_l2', waitMs: 700 * 8),
  _Shot('b.colb04.6', 2, 'spot_sort_l2', waitMs: 700 + 350),
];

const List<_Shot> _tablet = <_Shot>[
  _Shot('x.mathb17.6', 3, 'shop_l3', waitMs: 900 + 700),
  _Shot('b.mathb09.5', 2, 'balance_l2', waitMs: 800),
  _Shot('b.mathb13.7', 3, 'balance_weigh_l3', waitMs: 700 * 2 + 600),
  _Shot('b.numb11.1', 2, 'spot_numbers_l2', waitMs: 700 * 6),
  _Shot('b.mathb03.9', 2, 'spot_sentence_l2', waitMs: 700 * 7),
];

void main() {
  setUpAll(() async {
    await loadAppFonts();
    useTolerantGoldens(0.03);
  });

  for (final (String, Size, List<_Shot>) device in <(String, Size, List<_Shot>)>[
    ('phone', const Size(852, 393), _phone),
    ('tablet_landscape', const Size(1180, 820), _tablet),
  ]) {
    testWidgets('the hint ladder of the shop, the balance and spot the mistake, ${device.$1}', (
      WidgetTester tester,
    ) async {
      // The hands are art files; they come from the asset bundle, which needs the real clock.
      await tester.runAsync(warmHintHands);
      final AppRig rig = AppRig();
      await rig.seedFinishedSetup(name: 'נֹעָה');
      await rig.pump(tester, size: device.$2);
      await tester.tap(find.text('נֹעָה'));
      await tester.pumpAndSettle();
      final PackContent content = await loadStarter();
      for (final _Shot shot in device.$3) {
        final NavigatorState nav = tester.state<NavigatorState>(find.byType(Navigator).first);
        final Lesson one = Lesson.mission(
          id: 'shot',
          itemIds: <String>[shot.activity],
          skillIds: content.activities[shot.activity]!.skills.map((Skill s) => s.id).toList(),
          celebration: content.lessons['butterflies']!.celebration,
        );
        nav.push(
          MaterialPageRoute<void>(
            builder: (BuildContext c) => LessonScreen(profileId: 'p-1', mission: one),
          ),
        );
        await tester.pump(const Duration(milliseconds: 600));
        await _wait(tester, 2500);
        for (int level = 1; level <= shot.level; level++) {
          await tester.tap(find.byKey(const Key('lesson-hint')), warnIfMissed: false);
          await tester.pump(const Duration(milliseconds: 60));
          await _wait(tester, level < shot.level ? gapMs : shot.waitMs);
        }
        await expectLater(
          find.byType(MaterialApp),
          matchesGoldenFile('goldens/hint_${shot.name}_${device.$1}.png'),
        );
        nav.pop();
        await tester.pump(const Duration(milliseconds: 600));
      }
    });
  }
}
