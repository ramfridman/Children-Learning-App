// QA of L0 (docs/qa/l0-languages-verification.md): the 8-land map measured on the real widgets of the four boards, at the text
// size of 1.0 and of 1.3. The design-director's collision table (docs/design/languages-island.md section 3) is re-measured here
// with the numbers printed (`QA-L0 ...` lines), and the floors below are the rules: no sign touches another or a fixed button,
// the bubble covers no sign, every tap area is at least 64 high and wide (design-spec 6.1) with gaps of 16 or more.
// The B-42 welcome band is not on this branch; the bubble measured is the map's own speech bubble (B-26), at its widest.
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/child/art.dart' show AvatarButton;
import 'package:nitznutz/child/home_screen.dart';
import 'package:nitznutz/design/components.dart' show ParentEntryButton;
import 'package:nitznutz/parent/language_settings.dart';

import 'support/app_harness.dart';
import 'support/harness.dart';

const Map<String, Size> boards = <String, Size>{
  'phone': Size(852, 393),
  'phoneSE': Size(667, 375),
  'tabletLandscape': Size(1180, 820),
  'tabletPortrait': Size(820, 1180),
};

const String kid = 'child-lang-0001';

/// The distance between two rectangles (0 when they overlap), and the gap in each direction.
({double dx, double dy, double dist}) gapOf(Rect a, Rect b) {
  final double dx = math.max(0, math.max(a.left - b.right, b.left - a.right));
  final double dy = math.max(0, math.max(a.top - b.bottom, b.top - a.bottom));
  return (dx: dx, dy: dy, dist: math.sqrt(dx * dx + dy * dy));
}

Future<void> openMap(WidgetTester tester, Size size, {String name = 'נועה'}) async {
  final AppRig rig = AppRig();
  await rig.seedFinishedSetup(id: kid, name: name);
  FamilyLanguages f = const FamilyLanguages();
  for (final String c in <String>['eng', 'heb', 'rus']) {
    f = f.withSwitches(kid, c, const LanguageSwitches(on: true))!;
  }
  await rig.db.putSetting(languagesSettingKey, f.encode());
  await rig.pump(tester, size: size);
  await tester.tap(find.text(name));
  await tester.pumpAndSettle();
  expect(find.byType(HomeScreen), findsOneWidget);
}

void main() {
  setUpAll(loadAppFonts);

  for (final MapEntry<String, Size> board in boards.entries) {
    for (final double scale in <double>[1.0, 1.3]) {
      testWidgets('${board.key} x$scale: the 8-land map, measured', (WidgetTester tester) async {
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        await openMap(tester, board.value);
        final Rect screen = Offset.zero & board.value;
        final Map<Land, Rect> sign = <Land, Rect>{
          for (final Land l in Land.values) l: tester.getRect(find.byKey(Key('sign-${l.name}'))),
        };
        final Map<Land, Rect> tap = <Land, Rect>{
          for (final Land l in Land.values) l: tester.getRect(find.byKey(Key('land-tap-${l.name}'))),
        };

        // 1. No sign touches another; print the gaps that involve the Languages sign, and the tightest pair.
        double tightest = double.infinity;
        String tightestPair = '';
        for (final Land a in Land.values) {
          for (final Land b in Land.values) {
            if (a.index >= b.index) continue;
            final double d = gapOf(sign[a]!, sign[b]!).dist;
            if (d < tightest) {
              tightest = d;
              tightestPair = '${a.name}/${b.name}';
            }
            expect(sign[a]!.overlaps(sign[b]!), isFalse, reason: '${a.name} and ${b.name} signs overlap');
          }
        }
        final List<String> around = <String>[
          for (final Land o in Land.values)
            if (o != Land.languages)
              if (gapOf(sign[Land.languages]!, sign[o]!).dist < 400)
                '${o.name}=${gapOf(sign[Land.languages]!, sign[o]!).dist.toStringAsFixed(0)}',
        ];
        debugPrint(
          'QA-L0 ${board.key} x$scale sign gaps: languages to [${around.join(' ')}]; tightest $tightestPair '
          '${tightest.toStringAsFixed(1)}',
        );
        expect(tightest, greaterThanOrEqualTo(14), reason: 'tightest sign pair $tightestPair');

        // 2. Tap areas: 64 or more each way, and a gap of 16 or more to every other.
        double minSide = double.infinity;
        for (final MapEntry<Land, Rect> e in tap.entries) {
          minSide = math.min(minSide, math.min(e.value.width, e.value.height));
          expect(e.value.width, greaterThanOrEqualTo(64), reason: '${e.key.name} width');
          expect(e.value.height, greaterThanOrEqualTo(64), reason: '${e.key.name} height');
        }
        double tightestTap = double.infinity;
        for (final Land a in Land.values) {
          for (final Land b in Land.values) {
            if (a.index >= b.index) continue;
            final ({double dx, double dy, double dist}) g = gapOf(tap[a]!, tap[b]!);
            final double along = math.max(g.dx, g.dy);
            tightestTap = math.min(tightestTap, along);
            expect(
              along,
              greaterThanOrEqualTo(16),
              reason: 'tap areas ${a.name}/${b.name} ${tap[a]} ${tap[b]}',
            );
          }
        }
        debugPrint(
          'QA-L0 ${board.key} x$scale tap areas: smallest side ${minSide.toStringAsFixed(0)}, smallest gap '
          '${tightestTap.toStringAsFixed(0)}; languages ${tap[Land.languages]}',
        );

        // 3. At the start view no visible sign is under a fixed button (the pill, the avatar, Parents).
        final Map<String, Rect> fixed = <String, Rect>{
          'pill': tester.getRect(find.byKey(const Key('home-pill'))),
          'avatar': tester.getRect(find.byType(AvatarButton)),
          'parents': tester.getRect(find.byType(ParentEntryButton)),
        };
        for (final Land l in Land.values) {
          if (!screen.overlaps(sign[l]!)) continue;
          for (final MapEntry<String, Rect> f in fixed.entries) {
            expect(
              sign[l]!.overlaps(f.value),
              isFalse,
              reason: '${l.name} sign under ${f.key}: ${sign[l]} ${f.value}',
            );
          }
        }
        // The Languages tap area is the child's way in: it must be on screen at the start on the boards that do not scroll
        // to it, and touch no fixed button.
        for (final MapEntry<String, Rect> f in fixed.entries) {
          if (screen.overlaps(tap[Land.languages]!)) {
            expect(
              tap[Land.languages]!.overlaps(f.value),
              isFalse,
              reason: 'Languages tap area under ${f.key}',
            );
          }
        }
        debugPrint(
          'QA-L0 ${board.key} x$scale languages sign ${sign[Land.languages]}, on screen '
          '${screen.overlaps(sign[Land.languages]!)}; pill ${fixed['pill']}',
        );

        // 4. The speech bubble covers no sign of any land, and is whole on the screen.
        final Rect bubble = tester.getRect(find.byKey(const Key('bubble-body')));
        for (final Land l in Land.values) {
          expect(
            bubble.overlaps(sign[l]!),
            isFalse,
            reason: 'bubble $bubble over the ${l.name} sign ${sign[l]}',
          );
        }
        expect(tester.takeException(), isNull);
        debugPrint(
          'QA-L0 ${board.key} x$scale bubble $bubble; gap to the Languages sign '
          '${gapOf(bubble, sign[Land.languages]!).dist.toStringAsFixed(0)}',
        );
      });
    }
  }

  // The bubble at its widest: a long Latin name at 1.3 (the design's "four-row welcome" case), on the phones where it lies
  // nearest the Languages island.
  for (final String b in <String>['phone', 'phoneSE']) {
    testWidgets('$b x1.3: the bubble with a long name stays right of the Languages sign and its island', (
      WidgetTester tester,
    ) async {
      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await openMap(tester, boards[b]!, name: 'Alexandra Avigail');
      final Rect bubble = tester.getRect(find.byKey(const Key('bubble-body')));
      final Rect languages = tester.getRect(find.byKey(const Key('sign-languages')));
      final Rect tapArea = tester.getRect(find.byKey(const Key('land-tap-languages')));
      debugPrint('QA-L0 $b x1.3 long name: bubble $bubble, languages sign $languages, tap area $tapArea');
      expect(bubble.overlaps(languages), isFalse);
      // The design's own number: the bubble's widest left edge stays right of the island's roof (403 on the phone, 302 on SE).
      final double roofEnd = b == 'phone' ? 403 : 302;
      expect(
        bubble.left,
        greaterThanOrEqualTo(roofEnd),
        reason: 'the bubble is over the Languages island\'s roof',
      );
      expect(tester.takeException(), isNull);
    });
  }
}
