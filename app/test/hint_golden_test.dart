// Golden screenshots of the hint ladder (B-40 part 1), level 2 and level 3, on a phone: the same lesson screen the child sees, with the
// lamp pressed once for each level. The level 3 pictures are taken at the end of the worked example, when the answer is marked.
// A few are also taken on the tablet.
//
// Regenerate after a deliberate visual change:  flutter test --update-goldens test/hint_golden_test.dart
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
  _Shot('count.apples.7', 2, 'count_l2_hands', waitMs: 600 * 7 + 400),
  _Shot('b.numb04.3', 2, 'count_l2_frames', waitMs: 600 * 13 + 400),
  _Shot('count.apples.7', 3, 'count_l3', waitMs: 300 + 800 * 4),
  _Shot('give.butterflies.4', 3, 'give_l3', waitMs: 300 + 800 * 2),
  _Shot('flash.dice.3', 3, 'flash_l3', waitMs: 1500),
  _Shot('x.shpa02.1', 3, 'trace_l3', waitMs: 1500),
  _Shot('give.butterflies.4', 1, 'give_l1', waitMs: 600),
  _Shot('give.butterflies.4', 2, 'give_l2', waitMs: 600 * 4 + 400),
  _Shot('b.numb13.13', 2, 'numberline_jump_l2', waitMs: 1500),
  _Shot('b.numb13.13', 3, 'numberline_jump_l3', waitMs: 9000),
  _Shot('x.mathb15.1', 2, 'clock_l2', waitMs: 600),
  _Shot('x.mathb15.1', 3, 'clock_l3', waitMs: 9000),
  _Shot('b.mathb09.5', 2, 'balance_l2', waitMs: 800),
  _Shot('b.mathb09.5', 3, 'balance_l3', waitMs: 3500),
  _Shot('b.numb11.1', 2, 'spot_l2', waitMs: 700 * 6),
  _Shot('b.numb11.1', 3, 'spot_l3', waitMs: 700 * 8),
  _Shot('b15.cola02.5', 3, 'spot_a_l3', waitMs: 1500),
  _Shot('x.mathb17.1', 2, 'shop_l2', waitMs: 800),
  _Shot('x.mathb17.1', 3, 'shop_l3', waitMs: 9000),
  _Shot('cs.robot.plan.2', 2, 'robot_l2', waitMs: 800),
  _Shot('cs.robot.plan.2', 3, 'robot_l3', waitMs: 9000),
  _Shot('log.sortdrag.colour', 2, 'sort_l2', waitMs: 3500),
  _Shot('log.sortdrag.colour', 3, 'sort_l3', waitMs: 4000),
  _Shot('log.copy.three', 2, 'pattern_l2', waitMs: 600),
  _Shot('log.copy.three', 3, 'pattern_l3', waitMs: 9000),
  _Shot('x.numa07.1', 2, 'match_l2', waitMs: 600),
  _Shot('x.numa07.1', 3, 'match_l3', waitMs: 4500),
  _Shot('shp.build.house', 2, 'builder_l2', waitMs: 600),
  _Shot('shp.build.house', 3, 'builder_l3', waitMs: 4500),
  _Shot('flash.dice.3', 2, 'flash_l2', waitMs: 700),
];

const List<_Shot> _tablet = <_Shot>[
  _Shot('count.apples.7', 2, 'count_l2_hands', waitMs: 600 * 7 + 400),
  _Shot('b.numb04.3', 2, 'count_l2_frames', waitMs: 600 * 13 + 400),
  _Shot('count.apples.7', 3, 'count_l3', waitMs: 300 + 800 * 4),
  _Shot('give.butterflies.4', 3, 'give_l3', waitMs: 300 + 800 * 2),
  _Shot('flash.dice.3', 3, 'flash_l3', waitMs: 1500),
  _Shot('x.shpa02.1', 3, 'trace_l3', waitMs: 1500),
  _Shot('b15.cola02.5', 3, 'spot_a_l3', waitMs: 1500),
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
    testWidgets('the hint ladder at level 2 and 3, ${device.$1}', (WidgetTester tester) async {
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
