// B-42 work item 6 (design-director): the parent area's "how the name is said" screen, as the parent sees it: on the
// phone and the portrait tablet (the parent side's goldens), at text scale 1.0 and 1.3, with a spelling written and a
// note under the field. Nothing may be cut or run off the side; the two buttons stay on one row.
//
// Regenerate after a deliberate visual change:  flutter test --update-goldens test/name_spoken_golden_test.dart
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/parent/name_spoken_screen.dart';
import 'package:nitznutz/strings/he.dart';

import 'support/app_harness.dart';
import 'support/golden_comparator.dart';
import 'support/harness.dart';

Future<void> openSpelling(WidgetTester tester, Size size) async {
  final AppRig rig = AppRig();
  await rig.seedFinishedSetup();
  await rig.pump(tester, size: size);
  await tester.tap(find.text('נועה'));
  await tester.pumpAndSettle();
  await tester.tap(find.text(He.homeParents.text));
  await tester.pumpAndSettle();
  await tapDigits(tester, '${rig.gateQuestion.answer}');
  await tester.tap(find.text(He.pinOk.text));
  await tester.pumpAndSettle();
  await tapDigits(tester, testPin);
  await tester.tap(find.text(He.pinOk.text));
  await tester.pumpAndSettle();
  final Finder button = find.byKey(const Key('name-spoken-p-1'));
  await tester.ensureVisible(button);
  await tester.pumpAndSettle();
  await tester.tap(button);
  await tester.pumpAndSettle();
  expect(find.byType(NameSpokenScreen), findsOneWidget);
}

void main() {
  setUpAll(() async {
    await loadAppFonts();
    useTolerantGoldens(0.03);
  });

  for (final (String n, Size size) in <(String, Size)>[
    ('phone', Size(852, 393)),
    ('tablet_portrait', Size(820, 1180)),
  ]) {
    for (final double scale in <double>[1.0, 1.3]) {
      testWidgets('$n x$scale', (WidgetTester tester) async {
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        await openSpelling(tester, size);
        await tester.enterText(find.byKey(const Key('name-spoken-field')), 'נֹעָה');
        await tester.pump();
        await tester.tap(find.byKey(const Key('name-spoken-save')));
        await tester.pumpAndSettle();
        // The field loses the cursor, as after the parent's own tap elsewhere, so the golden has no blink.
        FocusManager.instance.primaryFocus?.unfocus();
        await tester.pumpAndSettle();

        // Every paragraph whole, the two buttons side by side, nothing past the screen's edges.
        for (final RenderParagraph p in tester.renderObjectList<RenderParagraph>(find.byType(RichText))) {
          expect(p.didExceedMaxLines, isFalse, reason: 'cut: ${p.text.toPlainText()}');
        }
        final Rect listen = tester.getRect(find.byKey(const Key('name-spoken-listen')));
        final Rect save = tester.getRect(find.byKey(const Key('name-spoken-save')));
        expect((listen.center.dy - save.center.dy).abs(), lessThan(1), reason: 'one row');
        expect(listen.left, greaterThan(save.right), reason: 'right to left: listen first, at the right');
        for (final Rect r in <Rect>[listen, save]) {
          expect(r.left >= 0 && r.right <= size.width, isTrue, reason: '$r');
        }
        await expectLater(
          find.byType(MaterialApp),
          matchesGoldenFile('goldens/name_spoken_$n${scale == 1.0 ? '' : '_1.3'}.png'),
        );
      });
    }
  }
}
