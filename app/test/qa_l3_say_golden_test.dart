// Goldens of the LS09 say-it screen on the four boards (QA of milestone L3, docs/qa/l3-languages-verification.md): the echo start with
// "I said it", the microphone ready, and the kind "together" state after an unsure listen. Fixture course and fake clips, not content.
//
// Regenerate after a deliberate visual change:  flutter test --update-goldens test/qa_l3_say_golden_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_speech.dart';
import 'support/golden_comparator.dart';
import 'support/harness.dart';
import 'support/qa_l3_say.dart';

const Map<String, Size> boards = <String, Size>{
  'phone': Size(852, 393),
  'phoneSE': Size(667, 375),
  'tabletLandscape': Size(1180, 820),
  'tabletPortrait': Size(820, 1180),
};

Future<void> _shot(WidgetTester t, String name, String board) async {
  await qaWait(t, 600);
  await expectLater(find.byType(MaterialApp), matchesGoldenFile('goldens/qa_l3_say_${name}_$board.png'));
}

void main() {
  setUpAll(() async {
    await loadAppFonts();
    useTolerantGoldens(0.03);
  });

  for (final MapEntry<String, Size> b in boards.entries) {
    group(b.key, () {
      testWidgets('echo: the picture and "I said it", no microphone', (WidgetTester t) async {
        await qaOpenSay(t, voice: false, size: b.value);
        await _shot(t, 'echo', b.key);
      });

      testWidgets('microphone ready: the mic and "I said it" side by side', (WidgetTester t) async {
        await qaOpenSay(t, voice: true, size: b.value);
        await _shot(t, 'mic', b.key);
      });

      testWidgets('after an unsure listen: the picture is lit, one more try is offered', (
        WidgetTester t,
      ) async {
        await qaOpenSay(t, voice: true, size: b.value, script: <Scripted>[Scripted.says('hat')]);
        await t.tap(find.byKey(const Key('lesson-mic')));
        await qaWait(t, 1500);
        await _shot(t, 'together', b.key);
      });
    });
  }
}
