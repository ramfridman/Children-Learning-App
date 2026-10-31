// Golden screenshots of the seesaw of heavy and light (B-40, TA-11 MATH-A-04, `math.size.heavy`): level 2 (the seesaw held level by
// two blocks) and level 3 (the last step: the stone's end on the ground, the fingertip on the right tile) on the phone, level 3 on
// the small phone and on the landscape tablet. Taken the same way as `hint_tap_golden_test.dart`.
//
// Regenerate after a deliberate visual change:  flutter test --update-goldens test/hint_seesaw_golden_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/child/activity_shell.dart';
import 'package:nitznutz/content/models.dart';
import 'package:nitznutz/play/hint_hand.dart';
import 'package:nitznutz/play/hints/hint_marks.dart';
import 'package:nitznutz/play/hints/tap_geometry.dart';
import 'package:nitznutz/play/hints/tap_plans.dart';
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

void main() {
  late PackContent content;
  setUpAll(() async {
    await loadAppFonts();
    useTolerantGoldens(0.03);
    content = await loadStarter();
  });

  int waitFor(TapAnswerActivity a, ActivitySpec spec, Size stage, int level) {
    final HintPlan p = tapHintPlan(a, TapGeometry(a, stage, spec), level)!;
    return level == 2
        ? p.length.inMilliseconds + 500
        : p.length.inMilliseconds - p.frames.last.hold.inMilliseconds + 700;
  }

  for (final (String, Size, ActivitySpec, List<int>) device in <(String, Size, ActivitySpec, List<int>)>[
    ('phone', const Size(852, 393), ActivitySpec.phone, <int>[2, 3]),
    ('phone_se', const Size(667, 375), ActivitySpec.phoneSE, <int>[3]),
    ('tablet_landscape', const Size(1180, 820), ActivitySpec.tabletLandscape, <int>[3]),
  ]) {
    testWidgets('the seesaw of heavy and light, ${device.$1}', (WidgetTester tester) async {
      await tester.runAsync(warmHintHands);
      final AppRig rig = AppRig();
      await rig.seedFinishedSetup(name: 'נֹעָה');
      await rig.pump(tester, size: device.$2);
      await tester.tap(find.text('נֹעָה'));
      await tester.pumpAndSettle();
      final TapAnswerActivity a = content.activities['math.size.heavy']! as TapAnswerActivity;
      final NavigatorState nav = tester.state<NavigatorState>(find.byType(Navigator).first);
      final Lesson one = Lesson.mission(
        id: 'shot',
        itemIds: <String>[a.id],
        skillIds: a.skills.map((Skill s) => s.id).toList(),
        celebration: content.lessons['butterflies']!.celebration,
      );
      nav.push(
        MaterialPageRoute<void>(
          builder: (BuildContext c) => LessonScreen(profileId: 'p-1', mission: one),
        ),
      );
      await tester.pump(const Duration(milliseconds: 600));
      await _wait(tester, 2500);
      final Size stage = device.$3.stageIsCard
          ? Size(device.$3.stage.width - 32, device.$3.stage.height - 32)
          : device.$3.stage.size;
      final List<int> levels = device.$4;
      for (int level = 1; level <= levels.last; level++) {
        await tester.tap(find.byKey(const Key('lesson-hint')), warnIfMissed: false);
        await tester.pump(const Duration(milliseconds: 60));
        final bool shoot = levels.contains(level);
        await _wait(tester, shoot ? waitFor(a, device.$3, stage, level) : 5000);
        if (shoot) {
          await expectLater(
            find.byType(MaterialApp),
            matchesGoldenFile('goldens/hint_measure_heavy_l${level}_${device.$1}.png'),
          );
        }
      }
      nav.pop();
      await tester.pump(const Duration(milliseconds: 600));
    });
  }
}
