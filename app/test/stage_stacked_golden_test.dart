// Golden screenshots of a stage with groups and a numeral or a row (B-36 part B, NUM-B-16): the two ten-frames of a teen with the
// numeral under them, and the two frames with the number sentence under them. Each on the phone, the small phone and both tablets,
// with no hint (level 0) and at the three hint levels, taken on the lesson screen the child sees, the lamp pressed once for each
// level. The bundled pack has no such activity yet, so both are made here from `b.numb16.3` and `b.numb16.2`.
//
// Regenerate after a deliberate visual change:  flutter test --update-goldens test/stage_stacked_golden_test.dart
import 'dart:convert';

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

Map<String, Object?> _frames(String sprite, int count, int seed) => <String, Object?>{
  'sprite': sprite,
  'count': count,
  'arrangement': 'ten_frame',
  'seed': seed,
  'scale': 1,
};

void main() {
  late PackContent content;
  setUpAll(() async {
    await loadAppFonts();
    useTolerantGoldens(0.03);
    content = await loadStarter();
    // The two activities of the next pack's shape, under ids of their own.
    for (final (String, String, void Function(Map<String, Object?>)) v
        in <(String, String, void Function(Map<String, Object?>))>[
          ('stack.frames', 'b.numb16.3', (Map<String, Object?> scene) => scene['numeral'] = 13),
          (
            'stack.sentence',
            'b.numb16.2',
            (Map<String, Object?> scene) {
              scene['group'] = _frames('asset:duck', 10, 3);
              scene['group2'] = _frames('asset:duck', 2, 8);
            },
          ),
        ]) {
      final Map<String, Object?> json =
          jsonDecode(jsonEncode(content.activities[v.$2]!.json)) as Map<String, Object?>;
      json['id'] = v.$1;
      v.$3(json['scene']! as Map<String, Object?>);
      content.activities[v.$1] = Activity.fromJson(json, content.assets);
    }
  });

  /// How long after the lamp the picture of [level] is taken (as in `hint_tap_b_golden_test.dart`).
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
    ('phone', const Size(852, 393), ActivitySpec.phone),
    ('phone_se', const Size(667, 375), ActivitySpec.phoneSE),
    ('tablet_landscape', const Size(1180, 820), ActivitySpec.tabletLandscape),
    ('tablet_portrait', const Size(820, 1180), ActivitySpec.tabletPortrait),
  ]) {
    testWidgets('groups and a numeral or a sentence on one stage, ${device.$1}', (WidgetTester tester) async {
      await tester.runAsync(warmHintHands);
      final AppRig rig = AppRig(content: content);
      await rig.seedFinishedSetup(name: 'נֹעָה');
      await rig.pump(tester, size: device.$2);
      await tester.tap(find.text('נֹעָה'));
      await tester.pumpAndSettle();
      for (final (String, String) f in <(String, String)>[
        ('frames', 'stack.frames'),
        ('sentence', 'stack.sentence'),
      ]) {
        final TapAnswerActivity a = content.activities[f.$2]! as TapAnswerActivity;
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
        await expectLater(
          find.byType(MaterialApp),
          matchesGoldenFile('goldens/stage_stacked_${f.$1}_l0_${device.$1}.png'),
        );
        for (int level = 1; level <= 3; level++) {
          await tester.tap(find.byKey(const Key('lesson-hint')), warnIfMissed: false);
          await tester.pump(const Duration(milliseconds: 60));
          await _wait(tester, waitFor(a, device.$3, stage, level));
          await expectLater(
            find.byType(MaterialApp),
            matchesGoldenFile('goldens/stage_stacked_${f.$1}_l${level}_${device.$1}.png'),
          );
        }
        nav.pop();
        await tester.pump(const Duration(milliseconds: 600));
      }
    });
  }
}
