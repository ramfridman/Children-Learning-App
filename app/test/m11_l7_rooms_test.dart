// The L7 screens in their rooms (M11 merged with L7): the Meet screen and the Find of English lesson 1 play the same with the rooms on as with
// them off, the room's frame is there only when they are on, and "I said it" and a right tap move the lesson on in both.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/content/models.dart';
import 'package:nitznutz/design/components.dart';
import 'package:nitznutz/play/speaking_badge.dart';

import 'support/harness.dart';
import 'support/l7_rig.dart';

void main() {
  late PackContent eng;

  setUpAll(() async {
    await loadAppFonts();
    eng = await buildEnglish();
  });

  for (final bool rooms in <bool>[false, true]) {
    testWidgets('Meet then Find of English lesson 1 with the rooms ${rooms ? 'on' : 'off'}', (
      WidgetTester t,
    ) async {
      final L7Rig r = await openEnglishLesson(t, eng, rooms: rooms);
      await l7Wait(t, 5400);
      expect(
        find.byKey(const Key('say-picture')),
        findsOneWidget,
        reason: 'the Meet screen shows its picture',
      );
      expect(find.byType(ProgressTrail), findsOneWidget);
      await t.tap(find.byKey(const Key('say-done')));
      await l7Wait(t, 7000);
      await l7Wait(t, 5400);
      await t.tap(find.byKey(const Key('say-done')));
      await l7Wait(t, 2500);
      expect(find.byKey(const Key('option-o2')), findsOneWidget, reason: 'the Find shows its pictures');
      await t.tap(find.byKey(const Key('option-o2')));
      await l7Wait(t, 150);
      expect(find.byWidgetPredicate((Widget w) => w is SpeakingBadge && w.on), findsOneWidget);
      await l7Wait(t, 3200);
      await t.tap(find.byKey(const Key('option-o1')));
      await l7Wait(t, 3000);
      expect(t.takeException(), isNull);
      expect(r.said, isNotEmpty);
    });
  }
}
