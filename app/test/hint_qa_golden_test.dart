// Golden screenshots of the hint pictures on the two boards the other hint goldens do not cover (QA, B-40): the small phone (667 by 375)
// and the portrait tablet (820 by 1180). A few activities of the families that crowd the stage most (a path of numbers, ten-frames, a
// row with a gap, a hand to the last tile), each at the level that is hardest to fit. Taken the same way as `hint_tap_golden_test.dart`.
//
// Regenerate after a deliberate visual change:  flutter test --update-goldens test/hint_qa_golden_test.dart
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

/// One picture: the activity and the level.
class _Shot {
  const _Shot(this.name, this.activity, this.levels);

  final String name;
  final String activity;
  final List<int> levels;
}

const Map<String, List<_Shot>> _shots = <String, List<_Shot>>{
  'phone_se': <_Shot>[
    _Shot('count', 'numeral.bugs.5', <int>[1, 2, 3]),
    _Shot('sequence', 'next.after.4', <int>[2, 3]),
    _Shot('teens', 'b.numb08.1', <int>[2, 3]),
    _Shot('pattern', 'log.next.colours', <int>[2, 3]),
    _Shot('colour', 'col.name.red.ball', <int>[3]),
  ],
  'tablet_portrait': <_Shot>[
    _Shot('count', 'numeral.bugs.5', <int>[3]),
    _Shot('teens', 'b.numb08.1', <int>[2]),
    _Shot('pattern', 'log.next.colours', <int>[2]),
    _Shot('colour', 'col.name.red.ball', <int>[3]),
    _Shot('ordinal', 'ordinal.second.of4', <int>[3]),
  ],
};

void main() {
  late PackContent content;
  setUpAll(() async {
    await loadAppFonts();
    useTolerantGoldens(0.03);
    content = await loadStarter();
  });

  int waitFor(TapAnswerActivity a, ActivitySpec spec, Size stage, int level) {
    final HintPlan p = tapHintPlan(a, TapGeometry(a, stage, spec), level)!;
    final List<HintFrame> frames = p.frames;
    switch (level) {
      case 1:
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
    ('phone_se', const Size(667, 375), ActivitySpec.phoneSE),
    ('tablet_portrait', const Size(820, 1180), ActivitySpec.tabletPortrait),
  ]) {
    testWidgets('the tap_answer hints, ${device.$1}', (WidgetTester tester) async {
      await tester.runAsync(warmHintHands);
      final AppRig rig = AppRig();
      await rig.seedFinishedSetup(name: 'נֹעָה');
      await rig.pump(tester, size: device.$2);
      await tester.tap(find.text('נֹעָה'));
      await tester.pumpAndSettle();
      for (final _Shot f in _shots[device.$1]!) {
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
        for (int level = 1; level <= f.levels.last; level++) {
          await tester.tap(find.byKey(const Key('lesson-hint')), warnIfMissed: false);
          await tester.pump(const Duration(milliseconds: 60));
          final bool shoot = f.levels.contains(level);
          await _wait(tester, shoot ? waitFor(a, device.$3, stage, level) : 5000);
          if (shoot) {
            await expectLater(
              find.byType(MaterialApp),
              matchesGoldenFile('goldens/hint_qa_${f.name}_l${level}_${device.$1}.png'),
            );
          }
        }
        nav.pop();
        await tester.pump(const Duration(milliseconds: 600));
      }
    });
  }
}
