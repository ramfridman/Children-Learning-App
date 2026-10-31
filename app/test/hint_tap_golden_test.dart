// Golden screenshots of the hint pictures of the Band A families of tap_answer (B-40 part 2): each family at level 1, level 2 and
// level 3, on a phone (the same lesson screen the child sees, the lamp pressed once for each level), and one tablet picture each
// for the three biggest families. The level 1 picture is taken in the middle of the glow, level 2 when the new picture has come to
// rest, level 3 on the last step of the demonstration, the fingertip on the right tile.
//
// Regenerate after a deliberate visual change:  flutter test --update-goldens test/hint_tap_golden_test.dart
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

/// One family: the activity, and the name of its pictures.
class _Family {
  const _Family(this.name, this.activity, {this.tablet = const <int>[]});

  final String name;
  final String activity;

  /// The levels that are also taken on the tablet.
  final List<int> tablet;
}

const List<_Family> _families = <_Family>[
  _Family('shapes', 'shp.name.triangle', tablet: <int>[2]),
  _Family('colour', 'col.name.red.ball', tablet: <int>[3]),
  _Family('colour_model', 'col.match.red'),
  _Family('compare', 'more.apples.2v4'),
  _Family('count', 'numeral.bugs.5'),
  _Family('sequence', 'next.after.4'),
  _Family('pattern', 'log.next.colours', tablet: <int>[2]),
  _Family('time', 'log.story.plant.mid'),
  _Family('same', 'log.same.cat'),
  _Family('add', 'math.add.stars'),
  _Family('numerals', 'show.birds.4'),
  _Family('measure', 'math.size.long'),
  _Family('position', 'shp.where.above'),
  _Family('ordinal', 'ordinal.second.of4'),
  _Family('zero', 'zero.basket'),
];

void main() {
  late PackContent content;
  setUpAll(() async {
    await loadAppFonts();
    useTolerantGoldens(0.03);
    content = await loadStarter();
  });

  /// How long after the lamp the picture of [level] is taken.
  int waitFor(TapAnswerActivity a, ActivitySpec spec, Size stage, int level) {
    final HintPlan p = tapHintPlan(a, TapGeometry(a, stage, spec), level)!;
    final List<HintFrame> frames = p.frames;
    switch (level) {
      case 1:
        // In the middle of the glow: half the steps are done, and the next one is half way.
        final int done = frames.length ~/ 2;
        return frames.take(done).fold(0, (int s, HintFrame f) => s + f.hold.inMilliseconds) +
            frames[done].hold.inMilliseconds ~/ 2;
      case 2:
        return p.length.inMilliseconds + 500;
      default:
        return p.length.inMilliseconds - frames.last.hold.inMilliseconds + 700;
    }
  }

  for (final (String, Size, ActivitySpec) device in <(String, Size, ActivitySpec)>[
    ('phone', const Size(852, 393), ActivitySpec.phone),
    ('tablet_landscape', const Size(1180, 820), ActivitySpec.tabletLandscape),
  ]) {
    testWidgets('the tap_answer family hints, ${device.$1}', (WidgetTester tester) async {
      await tester.runAsync(warmHintHands);
      final AppRig rig = AppRig();
      await rig.seedFinishedSetup(name: 'נֹעָה');
      await rig.pump(tester, size: device.$2);
      await tester.tap(find.text('נֹעָה'));
      await tester.pumpAndSettle();
      for (final _Family f in _families) {
        final List<int> levels = device.$1 == 'phone' ? <int>[1, 2, 3] : f.tablet;
        if (levels.isEmpty) continue;
        final TapAnswerActivity a = content.activities[f.activity]! as TapAnswerActivity;
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
        for (int level = 1; level <= levels.last; level++) {
          await tester.tap(find.byKey(const Key('lesson-hint')), warnIfMissed: false);
          await tester.pump(const Duration(milliseconds: 60));
          final bool shoot = levels.contains(level);
          await _wait(tester, shoot ? waitFor(a, device.$3, stage, level) : 5000);
          if (shoot) {
            await expectLater(
              find.byType(MaterialApp),
              matchesGoldenFile('goldens/hint_tap_${f.name}_l${level}_${device.$1}.png'),
            );
          }
        }
        nav.pop();
        await tester.pump(const Duration(milliseconds: 600));
      }
    });
  }
}
