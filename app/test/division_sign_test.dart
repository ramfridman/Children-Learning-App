// How a number sentence draws its signs (CLAUDE.md, Hebrew rules; M10 X2): `op::` is drawn ÷ unless a parent chose the colon in the
// parent area, and `op:x` is drawn × in every template (spot_error drew the letter x). The setting is kept on this device, with the
// other settings of the app.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/content/models.dart';
import 'package:nitznutz/play/lesson_screen.dart';
import 'package:nitznutz/play/math_signs.dart';

import 'rules_screen_test.dart' show openRules, tapKey;
import 'support/app_harness.dart';
import 'support/golden_comparator.dart';
import 'support/harness.dart';
import 'support/sample_pack.dart';

/// A pack with a division sentence to pick from (12 ÷ 3 = ?) and a multiplication sentence with a slip to find (6 × 3 = 9).
PackContent signsPack() {
  final SamplePack p = SamplePack();
  final Map<String, Object?> tap = Map<String, Object?>.of(p.docs[tapFile]! as Map<String, Object?>)
    ..['id'] = 'div.row'
    ..['templateVersion'] = '1.1';
  tap['scene'] = <String, Object?>{
    'background': 'asset:meadow',
    'optionsOnTiles': true,
    'row': <Object?>['n:12', 'op::', 'n:3', 'op:=', '?'],
  };
  tap['answer'] = <String, Object?>{
    'type': 'choice',
    'options': <Object?>[
      <String, Object?>{'id': 'o1', 'numeral': 4, 'label': 'four'},
      <String, Object?>{'id': 'o2', 'numeral': 9, 'label': 'nine'},
      <String, Object?>{'id': 'o3', 'numeral': 15, 'label': 'fifteen'},
    ],
    'correct': 'o1',
    'shuffle': false,
    'unsureAllowed': true,
  };
  final Map<String, Object?> spot = Map<String, Object?>.of(p.docs[tapFile]! as Map<String, Object?>)
    ..['id'] = 'times.spot'
    ..['template'] = 'spot_error'
    ..['templateVersion'] = '1.0';
  spot['scene'] = <String, Object?>{
    'background': 'asset:meadow',
    'cells': <Object?>['n:6', 'op:x', 'n:3', 'op:=', 'n:9'],
  };
  spot['answer'] = <String, Object?>{'type': 'spot', 'wrong': 4};
  p.addDocument('activity.div.row.json', 'activities', 'div.row', tap);
  p.addDocument('activity.times.spot.json', 'activities', 'times.spot', spot);
  return PackContent.fromPack(p.verified(pictures: true));
}

Future<void> _wait(WidgetTester t, int ms) async {
  for (int spent = 0; spent < ms; spent += 100) {
    await t.pump(const Duration(milliseconds: 100));
  }
  await t.pump(const Duration(milliseconds: 50));
}

/// Opens [activity] of the signs pack on the lesson screen, as a revisit mission is opened.
Future<void> _open(WidgetTester tester, PackContent content, String activity) async {
  final NavigatorState nav = tester.state<NavigatorState>(find.byType(Navigator).first);
  nav.push(
    MaterialPageRoute<void>(
      builder: (BuildContext c) => LessonScreen(
        profileId: 'p-1',
        mission: Lesson.mission(
          id: 'signs',
          itemIds: <String>[activity],
          skillIds: <String>['NUM-A-03'],
          celebration: content.lessons['butterflies']!.celebration,
        ),
      ),
    ),
  );
  await tester.pump(const Duration(milliseconds: 600));
  await _wait(tester, 900);
}

void main() {
  setUpAll(() async {
    await loadAppFonts();
    useTolerantGoldens(0.03);
  });

  group('the signs of a number sentence', () {
    test('the glyph of a sign', () {
      expect(signGlyph('+', DivisionSign.obelus), '+');
      expect(signGlyph('=', DivisionSign.obelus), '=');
      expect(signGlyph('-', DivisionSign.obelus), '−', reason: 'the minus sign, not the hyphen');
      expect(signGlyph('x', DivisionSign.obelus), '×', reason: 'the times sign, not the letter x');
      expect(signGlyph('x', DivisionSign.colon), '×');
      expect(signGlyph(':', DivisionSign.obelus), '÷');
      expect(signGlyph(':', DivisionSign.colon), ':');
      expect(signGlyph('<', DivisionSign.obelus), '<');
    });

    test('the setting is stored as a word, and anything else is the default ÷', () {
      expect(DivisionSign.fromStored(null), DivisionSign.obelus);
      expect(DivisionSign.fromStored('colon'), DivisionSign.colon);
      expect(DivisionSign.fromStored('obelus'), DivisionSign.obelus);
      expect(DivisionSign.fromStored('garbage'), DivisionSign.obelus);
      expect(DivisionSign.fromStored(DivisionSign.colon.stored), DivisionSign.colon);
    });
  });

  for (final (String, Size) device in <(String, Size)>[
    ('phone', const Size(852, 393)),
    ('tablet_landscape', const Size(1180, 820)),
  ]) {
    testWidgets('tap_answer draws ÷ for op:: and the colon when a parent chose it, ${device.$1}', (
      WidgetTester tester,
    ) async {
      final PackContent content = signsPack();
      final AppRig rig = AppRig(content: content);
      await rig.seedFinishedSetup(name: 'נֹעָה');
      await rig.pump(tester, size: device.$2);
      await tester.tap(find.text('נֹעָה'));
      await tester.pumpAndSettle();
      await _open(tester, content, 'div.row');
      expect(find.descendant(of: find.byKey(const Key('tap-row')), matching: find.text('÷')), findsOneWidget);
      expect(find.descendant(of: find.byKey(const Key('tap-row')), matching: find.text(':')), findsNothing);
      await expectLater(find.byType(MaterialApp), matchesGoldenFile('goldens/signs_divide_${device.$1}.png'));
    });

    testWidgets('tap_answer draws the colon for op:: when the parent chose it, ${device.$1}', (
      WidgetTester tester,
    ) async {
      final PackContent content = signsPack();
      final AppRig rig = AppRig(content: content);
      await rig.seedFinishedSetup(name: 'נֹעָה');
      await rig.db.putSetting('division_sign', 'colon');
      await rig.pump(tester, size: device.$2);
      await tester.tap(find.text('נֹעָה'));
      await tester.pumpAndSettle();
      await _open(tester, content, 'div.row');
      expect(find.descendant(of: find.byKey(const Key('tap-row')), matching: find.text(':')), findsOneWidget);
      expect(find.descendant(of: find.byKey(const Key('tap-row')), matching: find.text('÷')), findsNothing);
      await expectLater(find.byType(MaterialApp), matchesGoldenFile('goldens/signs_colon_${device.$1}.png'));
    });

    testWidgets('spot_error draws × for op:x, never the letter x, ${device.$1}', (WidgetTester tester) async {
      final PackContent content = signsPack();
      final AppRig rig = AppRig(content: content);
      await rig.seedFinishedSetup(name: 'נֹעָה');
      await rig.pump(tester, size: device.$2);
      await tester.tap(find.text('נֹעָה'));
      await tester.pumpAndSettle();
      await _open(tester, content, 'times.spot');
      expect(
        find.descendant(of: find.byKey(const Key('spot-stage')), matching: find.text('×')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: find.byKey(const Key('spot-stage')), matching: find.text('x')),
        findsNothing,
      );
      await expectLater(find.byType(MaterialApp), matchesGoldenFile('goldens/signs_times_${device.$1}.png'));
    });
  }

  group('the parent\'s choice', () {
    testWidgets('it starts on ÷, the choice is saved at once on this device, and the other chip clears', (
      WidgetTester tester,
    ) async {
      final AppRig rig = await openRules(tester);
      expect(await rig.db.setting('division_sign'), isNull);
      ChoiceChip chip(String key) => tester.widget<ChoiceChip>(find.byKey(Key(key)));
      await tester.scrollUntilVisible(
        find.byKey(const Key('division-colon')),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(chip('division-obelus').selected, isTrue);
      expect(chip('division-colon').selected, isFalse);
      await tapKey(tester, 'division-colon');
      expect(await rig.db.setting('division_sign'), 'colon');
      expect(chip('division-colon').selected, isTrue);
      expect(chip('division-obelus').selected, isFalse);
      await tapKey(tester, 'division-obelus');
      expect(await rig.db.setting('division_sign'), 'obelus');
    });
  });
}
