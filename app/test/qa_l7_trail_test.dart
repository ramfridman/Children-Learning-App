// QA-L7-2 (2026-11-15): the progress trail must never run under the "hint" or "show me" buttons. The trail is centred in a strip made for 7 or
// 8 sockets; since L7 re-cut the courses, 15 English and 38 Russian lessons have 10 to 12 (a Meet set is one socket), and on the phone the
// pill's start end is hidden behind the lamp (see goldens/l7_find_layout_3_phone.png).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/content/models.dart';
import 'package:nitznutz/design/components.dart' show ProgressTrail;

import 'support/golden_comparator.dart';
import 'support/harness.dart';
import 'support/l7_rig.dart';

const Map<String, Size> boards = <String, Size>{
  'phone': Size(852, 393),
  'phoneSE': Size(667, 375),
  'tabletLandscape': Size(1180, 820),
  'tabletPortrait': Size(820, 1180),
};

void main() {
  late PackContent eng;

  setUpAll(() async {
    await loadAppFonts();
    useTolerantGoldens(0.03);
    eng = await buildEnglish();
  });

  for (final MapEntry<String, Size> b in boards.entries) {
    testWidgets(
      '${b.key}: a 12-socket trail (eng.act-2, a scored item) does not touch the hint or show-me buttons',
      (WidgetTester t) async {
        await openEnglishLesson(t, eng, lesson: 'eng.act-2', size: b.value);
        await l7Wait(t, 600);
        final Rect trail = t.getRect(find.byType(ProgressTrail));
        for (final String key in <String>['lesson-hint', 'lesson-show-me']) {
          final Rect button = t.getRect(find.byKey(Key(key)));
          expect(
            trail.overlaps(button),
            isFalse,
            reason: '${b.key}: the trail $trail runs under $key $button',
          );
        }
      },
    );
  }
}
