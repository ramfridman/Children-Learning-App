// Goldens of LS13 on the four boards, on the lesson screen with the companion, the bubble and the trail: a probe of the placement game
// in play (no lamp and no "show me"; the trail is as long as a visit can be), and the same probe after a wrong answer (the one warm line,
// the tile only chosen, nothing "not yet"). Fixture course, fake clips and the approved pictures; the Hebrew lines are samples (needs-editor).
//
// Regenerate after a deliberate visual change:  flutter test --update-goldens test/golden_ls13_placement_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/world/language_placement.dart';

import 'support/golden_comparator.dart';
import 'support/harness.dart';
import 'support/l4_golden.dart';
import 'support/language_content.dart';

LangPack _pack() {
  final LangPack p = LangPack()..addPictures(<String>['cat', 'dog', 'duck']);
  final List<List<String>> levels = <List<String>>[
    for (int l = 0; l < 3; l++) <String>['p_${l}_1', 'p_${l}_2', 'p_${l}_3', 'p_${l}_4'],
  ];
  for (final List<String> l in levels) {
    l.forEach(p.addProbe);
  }
  p.addPlacement(placementJson('eng', <Map<String, Object?>>[strandJson('o', 'eng', levels)]));
  return p;
}

PlacementFlow _flow(LangPack p) => PlacementFlow(placementGameOf(p.content)!, p.content.placement!);

void main() {
  setUpAll(() async {
    await loadAppFonts();
    useTolerantGoldens(0.03);
  });

  for (final MapEntry<String, Size> b in boards.entries) {
    group(b.key, () {
      testWidgets('a probe in play: no lamp, no "show me"', (WidgetTester t) async {
        final LangPack p = _pack();
        await openLesson(t, p, 'p_0_1', b.value, flow: _flow(p));
        expect(find.byKey(const Key('lesson-hint')), findsNothing);
        expect(find.byKey(const Key('lesson-show-me')), findsNothing);
        await shot(t, 'ls13_probe', b.key);
      });

      testWidgets('after a wrong answer: the one warm line, nothing "not yet"', (WidgetTester t) async {
        final LangPack p = _pack();
        await openLesson(t, p, 'p_0_1', b.value, flow: _flow(p));
        await t.tap(
          find.byKey(const Key('option-o2')).evaluate().isEmpty
              ? find.byKey(const Key('tile-o2'))
              : find.byKey(const Key('option-o2')),
        );
        await shot(t, 'ls13_thanks', b.key, wait: 300);
      });
    });
  }
}
