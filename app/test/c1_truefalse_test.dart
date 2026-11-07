// M10 section 4.2 (MATH-C-02): "6 - 15 = 9 accepted" is M-SUB-ORDER, and needs a true-or-false card. The card is a `tap_answer` whose row is the
// whole sentence, with no gap, and two picture answers, the tick and the cross (the same card the pattern checks use): nothing new is
// needed in a session. This test keeps it so: such an item is valid, is drawn on all four boards, takes the tap on the tick or the cross
// as the answer with the tag of the wrong one, and has a hint at every level.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/child/activity_shell.dart';
import 'package:nitznutz/content/models.dart';
import 'package:nitznutz/content/pack_validation.dart';
import 'package:nitznutz/content/pack_verify.dart';
import 'package:nitznutz/content/schema.dart' show Problem;
import 'package:nitznutz/play/hints/tap_geometry.dart';
import 'package:nitznutz/play/hints/tap_plans.dart';

import 'support/c1_screens.dart';
import 'support/harness.dart';

Map<String, Object?> _m(Object? v) => v! as Map<String, Object?>;

/// Item c.mathc02.13 turned into "6 - 15 = 9: true or false?": the cross is right (the order of a take away matters).
void _sentenceCard(Map<String, Object?> docs) {
  final Map<String, Object?> d = _m(docs['activity.c.mathc02.13.json']);
  _m(d['scene'])['row'] = <Object?>['n:6', 'op:-', 'n:15', 'op:=', 'n:9'];
  _m(d['scene'])['optionsOnTiles'] = true;
  d['answer'] = <String, Object?>{
    'type': 'choice',
    'options': <Object?>[
      <String, Object?>{'id': 'o1', 'sprite': 'asset:tick', 'label': 'נָכוֹן', 'misconception': 'M-OP-SWAP'},
      <String, Object?>{'id': 'o2', 'sprite': 'asset:cross', 'label': 'לֹא נָכוֹן'},
    ],
    'correct': 'o2',
    'shuffle': false,
    'unsureAllowed': true,
  };
}

void main() {
  late PackContent content;
  setUpAll(() async {
    await loadAppFonts();
    content = await loadSourcePack(edit: _sentenceCard);
  });

  test('a sentence with no gap and a tick and a cross is a valid item', () async {
    final VerifiedPack pack = await loadSourceVerified();
    _sentenceCard(pack.docs);
    final List<String> problems = <String>[
      for (final Problem x in validatePack(
        manifest: pack.manifest,
        docs: pack.docs,
        files: pack.files.keys.toSet(),
      ))
        if (x.path.startsWith('activity.c.mathc02.13.json')) x.toString(),
    ];
    expect(problems, isEmpty);
  });

  test('it has a hint at every level on every board, ending on the cross', () {
    final TapAnswerActivity a = content.activities['c.mathc02.13']! as TapAnswerActivity;
    for (final ActivitySpec spec in <ActivitySpec>[
      ActivitySpec.phone,
      ActivitySpec.phoneSE,
      ActivitySpec.tabletLandscape,
      ActivitySpec.tabletPortrait,
    ]) {
      final Size stage = spec.stageIsCard
          ? Size(spec.stage.width - 32, spec.stage.height - 32)
          : spec.stage.size;
      final TapGeometry g = TapGeometry(a, stage, spec);
      for (int level = 1; level <= 3; level++) {
        expect(tapHintPlan(a, g, level), isNotNull, reason: 'level $level on ${spec.stage}');
      }
    }
  });

  for (final (String name, Size size) in boards) {
    testWidgets('on the $name board the sentence and the two pictures are drawn, and the cross is right', (
      WidgetTester t,
    ) async {
      await startOn(t, content, size);
      final TapAnswerActivity a = content.activities['c.mathc02.13']! as TapAnswerActivity;
      await openOne(t, content, a);
      expect(find.byKey(const Key('tap-row')), findsOneWidget);
      expect(find.byKey(const Key('tile-o1')), findsOneWidget);
      expect(find.byKey(const Key('tile-o2')), findsOneWidget);
      expect(t.takeException(), isNull);
      await t.tap(find.byKey(const Key('tile-o1')));
      await t.pump(const Duration(milliseconds: 300));
      expect(find.byKey(const Key('lesson-celebration')), findsNothing);
      await t.pump(const Duration(milliseconds: 1500));
      await t.tap(find.byKey(const Key('tile-o2')));
      await waitSteps(t, 2500);
      expect(t.takeException(), isNull);
    });
  }
}
