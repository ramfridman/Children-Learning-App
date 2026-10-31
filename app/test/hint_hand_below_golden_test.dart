// Golden screenshots of the pointing hand that comes from below (B-40): level 3 of the shop (x.mathb17.6: pay 8 shekels with 5 + 2 + 1)
// and of sort and drag (log.sortdrag.colour), on the phone, the small phone and both tablets. The hand's body lies under its fingertip,
// so it never covers the running total, the gold places or a bin's label. The same lesson screen the child sees, with the lamp
// pressed once for each level; the level 3 pictures are taken at a telling moment of the demonstration.
//
// Regenerate after a deliberate visual change:  flutter test --update-goldens test/hint_hand_below_golden_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/content/models.dart';
import 'package:nitznutz/design/board.dart';
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

/// One picture: the activity, how long level 3 plays before the picture is taken, and the name.
class _Shot {
  const _Shot(this.activity, this.name, this.waitMs);

  final String activity;
  final String name;
  final int waitMs;
}

/// The shop: the hand on the second coin, with 7 shekels on the counter (the total is shown), and on the pay button.
const List<_Shot> _shop = <_Shot>[
  _Shot('x.mathb17.6', 'shop_l3', 900 + 700),
  _Shot('x.mathb17.6', 'shop_l3_pay', 900 * 3 + 700),
];

/// Sort and drag: the hand has put the picture in its bin.
const List<_Shot> _sort = <_Shot>[_Shot('log.sortdrag.colour', 'sort_l3', 2000)];

void main() {
  setUpAll(() async {
    await loadAppFonts();
    useTolerantGoldens(0.03);
  });

  for (final (String, Size, List<_Shot>) device in <(String, Size, List<_Shot>)>[
    ('phone', BoardClass.phone.size, <_Shot>[..._shop, ..._sort]),
    ('phone_se', BoardClass.phoneSE.size, <_Shot>[..._shop, ..._sort]),
    ('tablet_landscape', BoardClass.tabletLandscape.size, <_Shot>[..._shop, ..._sort]),
    ('tablet_portrait', BoardClass.tabletPortrait.size, <_Shot>[..._shop, ..._sort]),
  ]) {
    testWidgets('the hand from below, level 3 of the shop and of sort and drag, ${device.$1}', (
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
        for (int level = 1; level <= 3; level++) {
          await tester.tap(find.byKey(const Key('lesson-hint')), warnIfMissed: false);
          await tester.pump(const Duration(milliseconds: 60));
          await _wait(tester, level < 3 ? gapMs : shot.waitMs);
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
