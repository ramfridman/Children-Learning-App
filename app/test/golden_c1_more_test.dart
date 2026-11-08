// Golden screenshots of the pieces that came after the first C1 screens (2026-11-07, round 2): the ten-frame target of give-N, the number
// line placed by estimate (ticks of ten), the true-or-false card of MATH-C-02, the middle of two marks (NUM-C-06), and a lit rod.
//
// Regenerate after a deliberate visual change:  flutter test --update-goldens test/golden_c1_more_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/content/models.dart';
import 'package:nitznutz/play/hint_hand.dart';

import 'support/c1_screens.dart';
import 'support/golden_comparator.dart';
import 'support/harness.dart';

Map<String, Object?> _m(Object? v) => v! as Map<String, Object?>;

void _edit(Map<String, Object?> docs) {
  final Map<String, Object?> give = _m(docs['activity.b.numb05.1.json']);
  give['templateVersion'] = '1.1';
  _m(give['scene'])['frame'] = true;
  final Map<String, Object?> line = _m(docs['activity.c.numc06.1.json']);
  line['templateVersion'] = '1.1';
  line['scene'] = <String, Object?>{
    'background': 'asset:meadow',
    'from': 0,
    'to': 100,
    'tickStep': 10,
    'markerSprite': 'asset:frog',
    'labels': <Object?>[0, 100],
  };
  line['answer'] = <String, Object?>{
    'type': 'line',
    'mode': 'place',
    'target': 70,
    'tolerance': 8,
    'misconception': 'M-PV-FACE',
    'mirrorMisconception': 'M-NL-DIR',
  };
  final Map<String, Object?> card = _m(docs['activity.c.mathc02.13.json']);
  _m(card['scene'])['row'] = <Object?>['n:6', 'op:-', 'n:15', 'op:=', 'n:9'];
  _m(card['scene'])['optionsOnTiles'] = true;
  card['answer'] = <String, Object?>{
    'type': 'choice',
    'options': <Object?>[
      <String, Object?>{'id': 'o1', 'sprite': 'asset:tick', 'label': 'נָכוֹן', 'misconception': 'M-OP-SWAP'},
      <String, Object?>{'id': 'o2', 'sprite': 'asset:cross', 'label': 'לֹא נָכוֹן'},
    ],
    'correct': 'o2',
    'shuffle': false,
    'unsureAllowed': true,
  };
  final Map<String, Object?> rod = _m(docs['activity.c.numc03.18.json']);
  _m(_m(rod['scene'])['picture'])['litRods'] = 1;
}

void main() {
  late PackContent content;
  setUpAll(() async {
    await loadAppFonts();
    useTolerantGoldens(0.03);
    content = await loadSourcePack(edit: _edit);
  });

  for (final (String board, Size size) in boards) {
    testWidgets('the round 2 screens of batch C1 on the $board board', (WidgetTester t) async {
      await t.runAsync(warmHintHands);
      await startOn(t, content, size);
      for (final (String name, String id) in <(String, String)>[
        ('give_frame', 'b.numb05.1'),
        ('estimate_line', 'c.numc06.1'),
        ('true_false', 'c.mathc02.13'),
        ('lit_rod', 'c.numc03.18'),
        ('middle', 'c.numc06.14'),
      ]) {
        await openOne(t, content, content.activities[id]!);
        await expectLater(find.byType(MaterialApp), matchesGoldenFile('goldens/c1b_${name}_$board.png'));
        if (board == 'phone' && name == 'middle') {
          for (int level = 1; level <= 3; level++) {
            await t.tap(find.byKey(const Key('lesson-hint')), warnIfMissed: false);
            await waitSteps(t, level == 3 ? 5500 : 3500);
            await expectLater(
              find.byType(MaterialApp),
              matchesGoldenFile('goldens/c1b_${name}_l${level}_$board.png'),
            );
          }
        }
        await closeOne(t);
      }
    });
  }
}
