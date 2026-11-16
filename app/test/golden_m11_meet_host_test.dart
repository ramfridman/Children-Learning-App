// Goldens of the Meet screen with its course host (docs/design/m11-rooms.md section 6): in the three language rooms the course host (Pip,
// Alfi the hyrax, Gosha the giraffe) stands in front and introduces the word, the companion stands behind it listening, and the screen is the
// L7 Meet on the room's backdrop. Each shot is the screen at "let's say it together": the host's line in the bubble, "I said it" and the
// microphone arrived. Phone, small phone and tablet landscape for each course, and the tall tablet for English.
//
// Regenerate after a deliberate visual change:  flutter test --update-goldens test/golden_m11_meet_host_test.dart
// Run this file alone, and `git checkout` any golden of another file that a run rewrote.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/content/models.dart';
import 'package:nitznutz/strings/he.dart' show HostHe;

import 'support/fake_speech.dart';
import 'support/golden_comparator.dart';
import 'support/harness.dart';
import 'support/l7_rig.dart';

typedef _Course = ({String course, String lesson, String host, bool story});

const _Course _eng = (course: 'eng', lesson: 'eng.greet-1', host: 'host_eng', story: false);
const _Course _rus = (course: 'rus', lesson: 'rus.family-1', host: 'host_rus', story: false);
const _Course _heb = (course: 'heb', lesson: 'heb.words-1', host: 'host_heb', story: true);

const Map<String, Size> _boards = <String, Size>{
  'phone': Size(852, 393),
  'phoneSE': Size(667, 375),
  'tabletLandscape': Size(1180, 820),
  'tabletPortrait': Size(820, 1180),
};

/// The Hebrew lesson opens on a story: its pages are turned, and the first Meet page follows.
Future<void> _passStory(WidgetTester t) async {
  // The host's greeting comes first (it ends by itself after its pause).
  for (int i = 0; i < 100 && find.byKey(const Key('story-turn')).evaluate().isEmpty; i++) {
    await t.pump(const Duration(milliseconds: 100));
  }
  await l7Wait(t, 600);
  for (int i = 0; i < 5; i++) {
    await t.tap(find.byKey(const Key('story-turn')));
    await l7Wait(t, 300);
  }
  await l7Wait(t, 2500);
}

/// Waits (at most 15 s) until the host's "together" line is in the bubble, then a little more for the controls that come with it.
Future<void> _untilTogether(WidgetTester t, String host) async {
  final String line = HostHe.togethers[host]!.text;
  for (int i = 0; i < 150 && find.text(line).evaluate().isEmpty; i++) {
    await t.pump(const Duration(milliseconds: 100));
  }
  expect(find.text(line), findsOneWidget, reason: 'the host says: $line');
  await l7Wait(t, 500);
}

void main() {
  late Map<String, PackContent> packs;

  setUpAll(() async {
    await loadAppFonts();
    useTolerantGoldens(0.03);
    packs = <String, PackContent>{
      for (final String c in <String>['eng', 'rus', 'heb']) c: await buildCourse(c),
    };
  });

  for (final (_Course c, List<String> boards) in <(_Course, List<String>)>[
    (_eng, <String>['phone', 'phoneSE', 'tabletLandscape', 'tabletPortrait']),
    (_rus, <String>['phone', 'phoneSE', 'tabletLandscape']),
    (_heb, <String>['phone', 'phoneSE', 'tabletLandscape']),
  ]) {
    for (final String board in boards) {
      testWidgets('Meet with the ${c.host} in front, at "together" (${c.course}, $board)', (
        WidgetTester t,
      ) async {
        await openCourseLesson(
          t,
          c.course,
          packs[c.course]!,
          lesson: c.lesson,
          size: _boards[board]!,
          band: 1,
          voice: true,
          rooms: true,
          pastOpener: false,
        );
        if (c.story) await _passStory(t);
        await _untilTogether(t, c.host);
        await expectLater(
          find.byType(MaterialApp),
          matchesGoldenFile('goldens/m11_meet_host_${c.course}_${board}_together.png'),
        );
      });
    }
  }

  testWidgets(
    'Meet, the microphone heard the child: the companion says its line from the back place (eng, phone)',
    (WidgetTester t) async {
      await openCourseLesson(
        t,
        'eng',
        packs['eng']!,
        lesson: 'eng.greet-1',
        band: 1,
        voice: true,
        rooms: true,
        pastOpener: false,
        script: <Scripted>[Scripted.says('hello')],
      );
      await _untilTogether(t, 'host_eng');
      await t.tap(find.byKey(const Key('lesson-mic')));
      for (int i = 0; i < 40 && find.text(HostHe.togethers['host_eng']!.text).evaluate().isNotEmpty; i++) {
        await t.pump(const Duration(milliseconds: 100));
      }
      await l7Wait(t, 150);
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/m11_meet_host_eng_phone_heard.png'),
      );
    },
  );
}
