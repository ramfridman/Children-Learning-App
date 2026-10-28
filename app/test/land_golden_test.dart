// Golden screenshots of the real islands with the real pack: the Counting Hills (15 skills) and the Colours island (1).
//
// Regenerate after a deliberate visual change:  flutter test --update-goldens test/land_golden_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/app_harness.dart';
import 'support/golden_comparator.dart';
import 'support/harness.dart';

Future<void> _loaded(WidgetTester tester) async {
  for (int i = 0; i < 6; i++) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 40)));
    await tester.pump();
  }
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() async {
    await loadAppFonts();
    useTolerantGoldens(0.03);
  });

  for (final (String, Size) device in <(String, Size)>[
    ('phone', const Size(852, 393)),
    ('tablet_landscape', const Size(1180, 820)),
  ]) {
    for (final String land in <String>['counting', 'colors']) {
      testWidgets('the $land island, ${device.$1}', (WidgetTester tester) async {
        final AppRig rig = AppRig();
        await rig.seedFinishedSetup();
        await rig.pump(tester, size: device.$2);
        await tester.tap(find.text('נועה'));
        await _loaded(tester);
        await tester.tap(find.byKey(Key('land-tap-$land')));
        await _loaded(tester);
        // every skill of the land has its drawing on the island
        expect(
          find.byWidgetPredicate((Widget w) => w.key.toString().startsWith("[<'object-")).evaluate().length,
          land == 'counting' ? 28 : 12,
        );
        await expectLater(
          find.byType(MaterialApp),
          matchesGoldenFile('goldens/island_${land}_${device.$1}.png'),
        );
      });
    }
  }
}
