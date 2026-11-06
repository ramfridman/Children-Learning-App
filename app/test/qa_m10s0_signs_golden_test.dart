// QA of M10 step 0, the signs (2026-11-06): the developer's goldens cover the phone (852 x 393) and the tablet in landscape. These add the
// small phone (667 x 375) and the tablet in portrait for ÷, : and ×, check that maths reads left to right on every size, and draw the
// parent's division chips at text scale 1.3 (phone, small phone, tablet in portrait). Each PNG is opened by the QA agent (docs/qa).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/content/models.dart';
import 'package:nitznutz/parent/rules_screen.dart';
import 'package:nitznutz/play/lesson_screen.dart';
import 'package:nitznutz/strings/he.dart';

import 'division_sign_test.dart' show signsPack;
import 'support/app_harness.dart';
import 'support/golden_comparator.dart';
import 'support/harness.dart';

const Size _phoneSE = Size(667, 375);
const Size _tabletP = Size(820, 1180);

Future<void> _wait(WidgetTester t, int ms) async {
  for (int spent = 0; spent < ms; spent += 100) {
    await t.pump(const Duration(milliseconds: 100));
  }
  await t.pump(const Duration(milliseconds: 50));
}

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

/// The x of the centre of the text [t] inside [scope].
double _x(WidgetTester tester, Finder scope, String t) =>
    tester.getCenter(find.descendant(of: scope, matching: find.text(t))).dx;

void main() {
  setUpAll(() async {
    await loadAppFonts();
    useTolerantGoldens(0.03);
  });

  for (final (String, Size) device in <(String, Size)>[
    ('phone_se', _phoneSE),
    ('tablet_portrait', _tabletP),
  ]) {
    for (final String sign in <String>['divide', 'colon']) {
      testWidgets('$sign in a sum on tap_answer, ${device.$1}: left to right, nothing clipped', (
        WidgetTester tester,
      ) async {
        final PackContent content = signsPack();
        final AppRig rig = AppRig(content: content);
        await rig.seedFinishedSetup(name: 'נֹעָה');
        if (sign == 'colon') await rig.db.putSetting('division_sign', 'colon');
        await rig.pump(tester, size: device.$2);
        await tester.tap(find.text('נֹעָה'));
        await tester.pumpAndSettle();
        await _open(tester, content, 'div.row');
        final Finder row = find.byKey(const Key('tap-row'));
        final String glyph = sign == 'divide' ? '÷' : ':';
        // Maths is LTR: 12 at the left, then the sign, then 3, then =, then the "?" (the sum is not mirrored).
        expect(
          _x(tester, row, '12'),
          lessThan(_x(tester, row, glyph)),
          reason: '$sign: 12 is left of the sign',
        );
        expect(
          _x(tester, row, glyph),
          lessThan(_x(tester, row, '3')),
          reason: '$sign: the sign is left of 3',
        );
        expect(_x(tester, row, '3'), lessThan(_x(tester, row, '=')));
        expect(_x(tester, row, '='), lessThan(_x(tester, row, '?')));
        // Everything of the row stays on the screen.
        final Rect box = tester.getRect(row);
        expect(box.left, greaterThanOrEqualTo(0));
        expect(box.right, lessThanOrEqualTo(device.$2.width));
        expect(tester.takeException(), isNull);
        await expectLater(
          find.byType(MaterialApp),
          matchesGoldenFile('goldens/qa_m10s0_signs_${sign}_${device.$1}.png'),
        );
      });
    }

    testWidgets('× in spot_error, ${device.$1}: left to right, the letter x is never drawn', (
      WidgetTester tester,
    ) async {
      final PackContent content = signsPack();
      final AppRig rig = AppRig(content: content);
      await rig.seedFinishedSetup(name: 'נֹעָה');
      await rig.pump(tester, size: device.$2);
      await tester.tap(find.text('נֹעָה'));
      await tester.pumpAndSettle();
      await _open(tester, content, 'times.spot');
      final Finder stage = find.byKey(const Key('spot-stage'));
      expect(find.descendant(of: stage, matching: find.text('×')), findsOneWidget);
      expect(find.descendant(of: stage, matching: find.text('x')), findsNothing);
      expect(_x(tester, stage, '6'), lessThan(_x(tester, stage, '×')));
      expect(_x(tester, stage, '×'), lessThan(_x(tester, stage, '3')));
      expect(_x(tester, stage, '3'), lessThan(_x(tester, stage, '=')));
      expect(_x(tester, stage, '='), lessThan(_x(tester, stage, '9')));
      expect(tester.takeException(), isNull);
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/qa_m10s0_signs_times_${device.$1}.png'),
      );
    });
  }

  for (final (String, Size, double) c in <(String, Size, double)>[
    ('phone', const Size(852, 393), 1.3),
    ('phone_se', _phoneSE, 1.3),
    ('tablet_portrait', _tabletP, 1.3),
    ('phone_se_x1', _phoneSE, 1.0),
  ]) {
    testWidgets('the parent\'s division chips on the rules screen, ${c.$1}, text scale ${c.$3}', (
      WidgetTester tester,
    ) async {
      final AppRig rig = AppRig();
      await rig.seedFinishedSetup();
      tester.platformDispatcher.textScaleFactorTestValue = c.$3;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await rig.pump(tester, size: c.$2);
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
      final Finder open = find.byKey(const Key('open-time-rules'));
      await tester.scrollUntilVisible(open, 200, scrollable: find.byType(Scrollable).first);
      await tester.tap(open);
      await tester.pumpAndSettle();
      expect(find.byType(RulesScreen), findsOneWidget);
      final Finder colon = find.byKey(const Key('division-colon'));
      await tester.scrollUntilVisible(colon, 200, scrollable: find.byType(Scrollable).first);
      // Bring the card's heading to the top of the view, so that the picture shows the heading, the help text and the chips together.
      final double top = tester.getTopLeft(find.text(He.divisionHeading.text)).dy;
      await tester.drag(find.byType(Scrollable).first, Offset(0, 70 - top));
      await tester.pumpAndSettle();
      expect(find.text(He.divisionHeading.text), findsOneWidget);
      expect(find.text(He.divisionHelp.text), findsOneWidget);
      // The chips are LTR: ÷ first (left), then : (right); both are at least 40 high, and neither is cut by the screen.
      final Rect a = tester.getRect(find.byKey(const Key('division-obelus')));
      final Rect b = tester.getRect(colon);
      expect(a.center.dx, lessThan(b.center.dx), reason: 'the ÷ chip is the left one');
      expect(a.height, greaterThanOrEqualTo(40));
      expect(b.height, greaterThanOrEqualTo(40));
      expect(a.left, greaterThanOrEqualTo(0));
      expect(b.right, lessThanOrEqualTo(c.$2.width));
      // The help text is read in full (not cut by an ellipsis): it is laid out within the card, with no more than the card's width.
      final RenderBox help = tester.renderObject<RenderBox>(find.text(He.divisionHelp.text));
      expect(help.size.width, lessThanOrEqualTo(c.$2.width));
      expect(tester.takeException(), isNull);
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/qa_m10s0_division_chips_${c.$1}.png'),
      );
    });
  }
}
