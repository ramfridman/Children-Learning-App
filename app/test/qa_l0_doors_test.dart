// QA of L0 (docs/qa/l0-languages-verification.md): the door screen beyond what the builder's tests hold. Reduce motion (no
// cross-fade, no pulse, no idle pulse), the idle pulse after 10 s that runs once and is an animation (nothing counts down), the
// back pebble that always works while a door is opening, and the hello bubbles at the text size of 1.3 on the four boards: no two
// bubbles touch, no bubble covers the title, the companion or another door, every tap target is large.
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/child/companion_views.dart' show MapCompanion;
import 'package:nitznutz/child/home_screen.dart';
import 'package:nitznutz/child/languages_doors.dart';
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

/// The door screen. The test rig turns "reduce motion" on for every screen (the characters breathe for ever), so the builder's
/// door tests and goldens never see the pulses; [motion] turns it off again just before the Languages island is tapped.
Future<void> toDoors(WidgetTester tester, Size size, List<String> on, {bool motion = false}) async {
  final AppRig rig = AppRig()..installedLanguages = on;
  await rig.seedFinishedSetup(id: kid);
  FamilyLanguages f = const FamilyLanguages();
  for (final String c in on) {
    f = f.withSwitches(kid, c, const LanguageSwitches(on: true))!;
  }
  await rig.db.putSetting(languagesSettingKey, f.encode());
  await rig.pump(tester, size: size);
  await tester.tap(find.text('נועה'));
  await tester.pumpAndSettle();
  final Finder tap = find.byKey(const Key('land-tap-languages'));
  await tester.ensureVisible(tap);
  await tester.pumpAndSettle();
  if (motion) {
    tester.platformDispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures();
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
  }
  await tester.tap(tap);
  for (int i = 0; i < 30 && find.byType(LanguagesDoorsScreen).evaluate().isEmpty; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
  // The route has settled; the door screen's own idle animation keeps running, so this does not wait for it.
  await tester.pump(const Duration(milliseconds: 500));
  expect(find.byType(LanguagesDoorsScreen), findsOneWidget);
}

/// The largest scale any Transform of a door unit has at this moment (the pulse of its bubble).
double pulseOf(WidgetTester tester, String course) {
  double most = 1;
  for (final Element e
      in find.descendant(of: find.byKey(Key('door-$course')), matching: find.byType(Transform)).evaluate()) {
    most = math.max(most, (e.widget as Transform).transform.getMaxScaleOnAxis());
  }
  return most;
}

Rect bubbleOf(WidgetTester tester, String course) {
  final Finder word = find.descendant(of: find.byKey(Key('door-$course')), matching: find.byType(FittedBox));
  return tester.getRect(find.ancestor(of: word, matching: find.byType(Container)).first);
}

void main() {
  setUpAll(loadAppFonts);

  group('reduce motion', () {
    testWidgets('a tap opens the door art at once, with no cross-fade and no pulse', (
      WidgetTester tester,
    ) async {
      tester.platformDispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(
        disableAnimations: true,
      );
      addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
      await toDoors(tester, boards['phone']!, const <String>['eng', 'heb', 'rus']);
      final Finder fade = find.descendant(
        of: find.byKey(const Key('door-heb')),
        matching: find.byType(AnimatedCrossFade),
      );
      expect(tester.widget<AnimatedCrossFade>(fade).duration, Duration.zero);
      await tester.tap(find.byKey(const Key('door-heb')));
      await tester.pump();
      expect(
        tester.widget<AnimatedCrossFade>(fade).crossFadeState,
        CrossFadeState.showSecond,
        reason: 'at once',
      );
      for (int i = 0; i < 6; i++) {
        await tester.pump(const Duration(milliseconds: 40));
        expect(pulseOf(tester, 'heb'), closeTo(1, 0.0001), reason: 'no pulse at ${40 * (i + 1)} ms');
      }
      await tester.pump(const Duration(milliseconds: 700));
      await tester.pumpAndSettle();
      expect(find.byType(CourseHomeScreen), findsOneWidget, reason: 'it still opens, 600 ms after the tap');
    });

    testWidgets('the idle pulse never runs', (WidgetTester tester) async {
      tester.platformDispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(
        disableAnimations: true,
      );
      addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
      await toDoors(tester, boards['phone']!, const <String>['eng', 'heb', 'rus']);
      for (int ms = 0; ms < 14000; ms += 100) {
        await tester.pump(const Duration(milliseconds: 100));
        for (final String c in <String>['eng', 'heb', 'rus']) {
          expect(pulseOf(tester, c), closeTo(1, 0.0001), reason: '$c at ~$ms ms');
        }
      }
      expect(tester.hasRunningAnimations, isFalse);
    });
  });

  group('the idle pulse', () {
    testWidgets('after 10 s the bubbles pulse once, from the start (the right), and then nothing more', (
      WidgetTester tester,
    ) async {
      await toDoors(tester, boards['phone']!, const <String>['eng', 'heb', 'rus'], motion: true);
      // Quiet for the first 9.5 s (500 ms have passed already).
      for (int ms = 0; ms < 9000; ms += 100) {
        await tester.pump(const Duration(milliseconds: 100));
        for (final String c in <String>['eng', 'heb', 'rus']) {
          expect(pulseOf(tester, c), closeTo(1, 0.0001), reason: '$c before 10 s at ~${ms + 500} ms');
        }
      }
      final List<String> order = <String>[];
      final Map<String, double> peak = <String, double>{'eng': 1, 'heb': 1, 'rus': 1};
      for (int ms = 0; ms < 3000; ms += 20) {
        await tester.pump(const Duration(milliseconds: 20));
        for (final String c in <String>['eng', 'heb', 'rus']) {
          final double p = pulseOf(tester, c);
          if (p > 1.0001 && !order.contains(c)) order.add(c);
          peak[c] = math.max(peak[c]!, p);
        }
      }
      expect(order, <String>['eng', 'heb', 'rus'], reason: 'one after another from the start');
      for (final String c in <String>['eng', 'heb', 'rus']) {
        expect(peak[c], closeTo(1.06, 0.01), reason: c);
      }
      // Nothing more: no later pulse, however long the child waits (the friend still breathes, so animations never stop).
      for (int i = 0; i < 60; i++) {
        await tester.pump(const Duration(seconds: 1));
        for (final String c in <String>['eng', 'heb', 'rus']) {
          expect(pulseOf(tester, c), closeTo(1, 0.0001), reason: '$c at ${i + 1} s after the pulse');
        }
      }
      for (final String c in <String>['eng', 'heb', 'rus']) {
        expect(pulseOf(tester, c), closeTo(1, 0.0001), reason: c);
      }
    });

    testWidgets('a tap before 10 s ends it: no idle pulse follows the tap', (WidgetTester tester) async {
      await toDoors(tester, boards['phone']!, const <String>['eng', 'heb', 'rus'], motion: true);
      await tester.tap(find.byKey(const Key('door-rus')));
      for (int ms = 0; ms < 700; ms += 50) {
        await tester.pump(const Duration(milliseconds: 50));
      }
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(CourseHomeScreen), findsOneWidget);
      await tester.tap(find.byKey(const Key('course-back')));
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(LanguagesDoorsScreen), findsOneWidget, reason: 'back to the doors, as they were');
      expect(tester.takeException(), isNull);
    });
  });

  testWidgets(
    'with motion: the tap cross-fades the art in 200 ms, the bubble pulses once and a gold ring shows',
    (WidgetTester tester) async {
      await toDoors(tester, boards['phone']!, const <String>['eng', 'heb', 'rus'], motion: true);
      final Finder fade = find.descendant(
        of: find.byKey(const Key('door-heb')),
        matching: find.byType(AnimatedCrossFade),
      );
      expect(tester.widget<AnimatedCrossFade>(fade).duration, const Duration(milliseconds: 200));
      await tester.tap(find.byKey(const Key('door-heb')));
      double peak = 1;
      for (int ms = 0; ms < 240; ms += 10) {
        await tester.pump(const Duration(milliseconds: 10));
        peak = math.max(peak, pulseOf(tester, 'heb'));
      }
      expect(peak, closeTo(1.06, 0.01), reason: 'a pulse to 1.06 and back in 240 ms');
      expect(pulseOf(tester, 'heb'), closeTo(1, 0.01));
      expect(tester.widget<AnimatedCrossFade>(fade).crossFadeState, CrossFadeState.showSecond);
      final Iterable<Border?> rings = find
          .descendant(of: find.byKey(const Key('door-heb')), matching: find.byType(Container))
          .evaluate()
          .map((Element e) => ((e.widget as Container).decoration as BoxDecoration?)?.border as Border?)
          .where((Border? b) => b != null);
      expect(
        rings.any((Border? b) => b!.top.width == 4),
        isTrue,
        reason: 'the gold ring while the hello plays',
      );
      await tester.pump(const Duration(milliseconds: 700));
      await tester.pumpAndSettle();
      expect(find.byType(CourseHomeScreen), findsOneWidget);
    },
  );

  testWidgets(
    'the door screen draws no number and no counting word: three greetings, a title and nothing else',
    (WidgetTester tester) async {
      await toDoors(tester, boards['phone']!, const <String>['eng', 'heb', 'rus']);
      final List<String> texts = <String>[
        for (final Element e
            in find.descendant(of: find.byType(LanguagesDoorsScreen), matching: find.byType(Text)).evaluate())
          (e.widget as Text).data ?? (e.widget as Text).textSpan?.toPlainText() ?? '',
      ];
      expect(texts.toSet(), <String>{'אִי הַשָּׂפוֹת', 'Hello', 'שָׁלוֹם', 'Привет'});
      for (final String t in texts) {
        expect(RegExp(r'\d').hasMatch(t), isFalse, reason: t);
      }
    },
  );

  testWidgets(
    'the back pebble works while a door is opening (reduced motion, quick press): no course opens after it',
    (WidgetTester tester) async {
      await toDoors(tester, boards['phone']!, const <String>['eng', 'heb', 'rus']);
      await tester.tap(find.byKey(const Key('door-heb')));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(find.byKey(const Key('doors-back')));
      await tester.pump(const Duration(milliseconds: 100));
      for (int i = 0; i < 12; i++) {
        await tester.pump(const Duration(milliseconds: 200));
        debugPrint(
          'PROBE i=$i doors ${find.byType(LanguagesDoorsScreen).evaluate().length} course ${find.byType(CourseHomeScreen).evaluate().length}',
        );
      }
      expect(
        find.byType(CourseHomeScreen),
        findsNothing,
        reason: 'the child went back; no course opens behind them',
      );
      expect(find.byType(LanguagesDoorsScreen), findsNothing);
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  for (final MapEntry<String, Size> board in boards.entries) {
    for (final double scale in <double>[1.0, 1.3]) {
      testWidgets(
        '${board.key} x$scale: three doors, no two bubbles touch, nothing covers the title or the companion',
        (WidgetTester tester) async {
          tester.platformDispatcher.textScaleFactorTestValue = scale;
          addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
          await toDoors(tester, board.value, const <String>['eng', 'heb', 'rus']);
          final Rect screen = Offset.zero & board.value;
          final Map<String, Rect> bubble = <String, Rect>{
            for (final String c in <String>['eng', 'heb', 'rus']) c: bubbleOf(tester, c),
          };
          final Rect title = tester.getRect(find.byKey(const Key('doors-title')));
          final Rect back = tester.getRect(find.byKey(const Key('doors-back')));
          final Rect companion = tester.getRect(find.byType(MapCompanion));
          double tightest = double.infinity;
          for (final String a in bubble.keys) {
            expect(
              screen.contains(bubble[a]!.topLeft) && screen.contains(bubble[a]!.bottomRight),
              isTrue,
              reason: '$a $bubble',
            );
            expect(bubble[a]!.overlaps(title), isFalse, reason: '$a bubble over the title');
            expect(bubble[a]!.overlaps(back), isFalse, reason: '$a bubble over the back pebble');
            expect(bubble[a]!.overlaps(companion), isFalse, reason: '$a bubble over the companion');
            for (final String b in bubble.keys) {
              if (a.compareTo(b) >= 0) continue;
              final double gap = math.max(
                math.max(bubble[a]!.left - bubble[b]!.right, bubble[b]!.left - bubble[a]!.right),
                -1,
              );
              tightest = math.min(tightest, gap);
              expect(gap, greaterThan(0), reason: 'bubbles $a and $b touch');
            }
          }
          // Each door is a tap target far above the band's minimum; nobody overlaps a neighbour's door.
          final Map<String, Rect> door = <String, Rect>{
            for (final String c in <String>['eng', 'heb', 'rus'])
              c: tester.getRect(find.byKey(Key('door-$c'))),
          };
          for (final Rect d in door.values) {
            expect(
              d.width,
              greaterThanOrEqualTo(158),
              reason: 'the tap rectangle of design 4.2.1 is 178, 158, 244 or 224 wide',
            );
          }
          expect(
            door['eng']!.left - door['heb']!.right,
            greaterThanOrEqualTo(24),
            reason: 'gap between doors',
          );
          expect(
            door['heb']!.left - door['rus']!.right,
            greaterThanOrEqualTo(24),
            reason: 'gap between doors',
          );
          debugPrint('QA-L0 doors ${board.key} x$scale: door unit ${door['rus']}, companion $companion');
          expect(tester.takeException(), isNull);
          debugPrint(
            'QA-L0 doors ${board.key} x$scale: tightest bubble gap ${tightest.toStringAsFixed(1)}, '
            'bubbles ${bubble.map((String k, Rect v) => MapEntry<String, String>(k, v.toString()))}',
          );
        },
      );
    }
  }
}
