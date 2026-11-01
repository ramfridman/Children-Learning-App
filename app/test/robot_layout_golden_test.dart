// Golden screenshots of the robot boards with four rows (B-38): a tall stage, the arrows as a block of 2 by 2 beside it, the plan's steps
// under the grid; on the phone and on the small phone. The hint pictures (level 1 glow, level 2 footprints, level 3 the hand on the
// arrows) are taken on the same boards.
//
// Regenerate after a deliberate visual change:  flutter test --update-goldens test/robot_layout_golden_test.dart
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

/// One picture: the activity, the level the lamp is pressed up to (0 for none), how long the last level plays before the picture
/// is taken, and the name.
class _Shot {
  const _Shot(this.activity, this.level, this.name, {this.waitMs = 800});

  final String activity;
  final int level;
  final String name;
  final int waitMs;
}

const List<_Shot> _shots = <_Shot>[
  _Shot('b.csb01.1', 0, 'plan_4x4'),
  _Shot('b.csb01.5', 0, 'plan_5x4'),
  _Shot('b.csb01.4', 0, 'direct_4x4'),
  _Shot('b15.csa03.2', 0, 'direct_3x4'),
  _Shot('cs.robot.plan.3', 0, 'plan_4x3'),
  _Shot('cs.robot.direct.1', 0, 'direct_3x2'),
  _Shot('b.csb01.5', 1, 'plan_5x4_l1', waitMs: 600),
  _Shot('b.csb01.5', 2, 'plan_5x4_l2', waitMs: 900),
  _Shot('b.csb01.5', 3, 'plan_5x4_l3', waitMs: 600 * 3 + 300),
  _Shot('b15.csa03.2', 3, 'direct_3x4_l3', waitMs: 600 * 4 + 300),
  _Shot('b.csb01.7', 3, 'plan_5x4_l3_right', waitMs: 540),
  _Shot('b.csb01.8', 3, 'direct_4x4_l3_down', waitMs: 540),
];

void main() {
  setUpAll(() async {
    await loadAppFonts();
    useTolerantGoldens(0.03);
  });

  for (final (String, Size) device in <(String, Size)>[
    ('phone', const Size(852, 393)),
    ('phone_se', const Size(667, 375)),
  ]) {
    testWidgets('the robot boards, ${device.$1}', (WidgetTester tester) async {
      await tester.runAsync(warmHintHands);
      final AppRig rig = AppRig();
      await rig.seedFinishedSetup(name: 'נֹעָה');
      await rig.pump(tester, size: device.$2);
      await tester.tap(find.text('נֹעָה'));
      await tester.pumpAndSettle();
      final PackContent content = await loadStarter();
      for (final _Shot shot in _shots) {
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
          await _wait(tester, level < shot.level ? 6000 : shot.waitMs);
        }
        await expectLater(
          find.byType(MaterialApp),
          matchesGoldenFile('goldens/robot_${shot.name}_${device.$1}.png'),
        );
        nav.pop();
        await tester.pump(const Duration(milliseconds: 600));
      }
    });
  }
}
