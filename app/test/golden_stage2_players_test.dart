// M11 Stage 2, the roll-out to the other five lands (docs/milestones/M11-stage2.md section 11.6): one Show for each player that is new, on the real lesson
// screen of the phone board, in its room, for a child new to the skill, with the host at work (its hand, the marks it has left). The pictures are named
// stage2_<player>_show_phone; a second one of each player is taken at the child's turn, when the host has stopped.
//
// Regenerate after a deliberate visual change:  flutter test --update-goldens test/golden_stage2_players_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/content/models.dart';
import 'package:nitznutz/engine/age.dart';
import 'package:nitznutz/parent/age_settings.dart';
import 'package:nitznutz/play/lesson_screen.dart';
import 'package:nitznutz/play/show_stage.dart';

import 'support/app_harness.dart';
import 'support/bubble_audit.dart' show AuditLook;
import 'support/golden_comparator.dart';
import 'support/harness.dart';
import 'support/l4_golden.dart' show waitFor;
import 'support/starter.dart';
import 'support/voice_fixtures.dart';

const AuditLook _p4 = (name: 'P4', school: SchoolStage.grade2, birth: BirthMonth(2019, 5), captions: null);
const Size _phone = Size(852, 393);

Future<void> _shot(String name) =>
    expectLater(find.byType(MaterialApp), matchesGoldenFile('goldens/$name.png'));

/// Opens [lessonId] on the lesson screen in its room, for a child new to every skill, and gives the host's lines a clip that ends by itself.
Future<void> _open(WidgetTester t, PackContent content, String lessonId, {bool still = false}) async {
  // the host's art is read off the main thread (as in the Shape Forest goldens): real time is let pass for it before the screen opens
  await t.runAsync(() => ShowArt.load());
  final AppRig rig = AppRig(
    content: content,
    rooms: true,
    player: FakePlayer()..endsAfter = const Duration(milliseconds: 1200),
  );
  await rig.seedFinishedSetup(name: 'נֹעָה', ageBand: _p4.school.band);
  await rig.db.confirmStage('p-1', _p4.school, DateTime(2026, 10, 26));
  await rig.db.setBirth('p-1', _p4.birth);
  await rig.pump(t, size: _phone, reduceMotion: still);
  await t.tap(find.text('נֹעָה'));
  await t.pump(const Duration(milliseconds: 500));
  t
      .state<NavigatorState>(find.byType(Navigator).first)
      .push(
        MaterialPageRoute<void>(
          builder: (BuildContext c) => LessonScreen(profileId: 'p-1', lessonId: lessonId),
        ),
      );
  for (int i = 0; i < 60 && (i < 3 || find.byType(RichText).evaluate().isEmpty); i++) {
    await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 150)));
    await t.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  late PackContent content;
  setUpAll(() async {
    await loadAppFonts();
    useTolerantGoldens(0.03);
    content = await loadSourcePack();
  });

  // (player, lesson, the milliseconds after the opening at which the host has made its first moves, and at which it has stopped)
  for (final (String, String, int, int) p in <(String, String, int, int)>[
    ('numline', 'count-to-20', 10800, 24000),
    ('give', 'giving', 10500, 22000),
    ('counttap', 'butterflies', 10200, 22000),
    ('pattern', 'light-and-dark', 11000, 22000),
    ('balance', 'missing-part', 10500, 24000),
    ('shop', 'pay-exactly', 10300, 22000),
    ('robot', 'robot-plans', 11000, 24000),
    ('clock', 'set-the-clock', 10500, 22000),
  ]) {
    testWidgets('${p.$1}: the Show on the phone, the host at work and then stopped', (WidgetTester t) async {
      await _open(t, content, p.$2);
      expect(content.lessons[p.$2]!.parts, isNotNull);
      await waitFor(t, p.$3);
      await _shot('stage2_${p.$1}_show_phone');
      await waitFor(t, p.$4 - p.$3);
      await _shot('stage2_${p.$1}_turn_phone');
    });
  }

  // Reduced movement: no hand travels, each step is in its place after its pause (one player: the line).
  testWidgets('numline with reduced movement: the steps are in place, with their arcs', (
    WidgetTester t,
  ) async {
    await _open(t, content, 'count-to-20', still: true);
    await waitFor(t, 9000);
    await _shot('stage2_numline_show_still_phone');
  });
}
