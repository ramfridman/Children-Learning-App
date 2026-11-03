// B-42 work item 6 (design-director): the daily welcome in the friend's bubble on the four boards, at text scale 1.0 and
// 1.3. Every welcome sentence (each greeting after the name, each topic and land line, the closing line) must fit the
// bubble (210 wide on the phone, 190 on the SE; on a tablet up to 245, held in its band between two signs), stay whole
// on the screen, keep its tail at the friend's mouth (B-34), cover no land's sign and leave the Today's Adventure pill
// uncovered (the closing line points at it). Goldens of the worst cases, and of the pill's glow
// (docs/milestones/B42.md sections 2.3 and 8, row 6).
//
// Regenerate after a deliberate visual change:  flutter test --update-goldens test/welcome_bubble_test.dart
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/child/home_screen.dart';
import 'package:nitznutz/child/welcome_shown.dart';
import 'package:nitznutz/design/components.dart';

import 'support/app_harness.dart';
import 'support/golden_comparator.dart';
import 'support/harness.dart';

typedef Board = ({String name, Size size, double maxWidth});

const List<Board> boards = <Board>[
  (name: 'phone', size: Size(852, 393), maxWidth: 210),
  (name: 'phone_se', size: Size(667, 375), maxWidth: 190),
  (name: 'tablet_landscape', size: Size(1180, 820), maxWidth: 245),
  (name: 'tablet_portrait', size: Size(820, 1180), maxWidth: 245),
];

/// The 24 letters the server allows, so the name line is shortened by the sign's rule.
const String longestName = 'אבגדהוזחטיכלמנסעפצקרשתאב';

late Map<String, String> lines;

/// The child on the map with the welcome running (text only: the rig has no voice pack), held on its first sentence.
Future<ValueNotifier<WelcomeShown?>> welcomeOn(WidgetTester tester, Board b, {String name = 'נועה'}) async {
  final AppRig rig = AppRig(welcome: true);
  await rig.seedFinishedSetup(name: name);
  await rig.pump(tester, size: b.size);
  await tester.tap(find.text(name));
  for (int i = 0; i < 20; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
  final HomeScreen home = tester.widget<HomeScreen>(find.byType(HomeScreen));
  expect(home.welcome, isNotNull, reason: 'the welcome is on');
  return home.welcome! as ValueNotifier<WelcomeShown?>;
}

/// Shows [id] in the bubble (with the name first when [withName]) and lets one frame be drawn. Fake time does not move,
/// so the welcome stays on this sentence.
Future<void> show(
  WidgetTester tester,
  ValueNotifier<WelcomeShown?> welcome,
  String id, {
  bool withName = false,
}) async {
  welcome.value = WelcomeShown(text: lines[id]!, withName: withName);
  await tester.pump();
}

/// Lets the welcome run out, so no timer of it is left when the test ends.
Future<void> finish(WidgetTester tester) => tester.pump(const Duration(seconds: 20));

Rect bodyRect(WidgetTester tester) => tester.getRect(find.byKey(const Key('bubble-body')));

/// The centre of the bubble's small tail (a square turned 45 degrees about its centre), where it points from.
Offset tailOf(WidgetTester tester) =>
    tester.getRect(find.descendant(of: find.byType(BoardBubble), matching: find.byType(Transform))).center;

/// Every land's sign on the screen.
Map<String, Rect> signsOf(WidgetTester tester) => <String, Rect>{
  for (final Element e
      in find
          .byWidgetPredicate(
            (Widget w) => w.key is ValueKey<String> && (w.key! as ValueKey<String>).value.startsWith('sign-'),
          )
          .evaluate())
    (e.widget.key! as ValueKey<String>).value: tester.getRect(find.byKey(e.widget.key!)),
};

void main() {
  setUpAll(() async {
    await loadAppFonts();
    useTolerantGoldens(0.03);
    final Map<String, Object?> root =
        jsonDecode(File('assets/lines/welcome.json').readAsStringSync()) as Map<String, Object?>;
    lines = <String, String>{
      for (final MapEntry<String, Object?> e in (root['lines']! as Map<String, Object?>).entries)
        e.key: e.value! as String,
    };
  });

  group('every sentence fits', () {
    for (final Board b in boards) {
      for (final String name in <String>['נועה', longestName]) {
        testWidgets('${b.name}, ${name == longestName ? 'the longest name' : 'a short name'}', (
          WidgetTester tester,
        ) async {
          final ValueNotifier<WelcomeShown?> welcome = await welcomeOn(tester, b, name: name);
          // The map's own bubble first: where its tail points, the welcome's tail must point too.
          welcome.value = null;
          await tester.pump();
          final Offset mouth = tailOf(tester);
          final Rect own = bodyRect(tester);
          final Rect pill = tester.getRect(find.byKey(const Key('home-pill')));
          final List<String> problems = <String>[];
          for (final double scale in <double>[1.0, 1.3]) {
            tester.platformDispatcher.textScaleFactorTestValue = scale;
            await tester.pump();
            final Map<String, Rect> signs = signsOf(tester);
            for (final String id in lines.keys) {
              final List<FlutterErrorDetails> errors = <FlutterErrorDetails>[];
              final void Function(FlutterErrorDetails)? before = FlutterError.onError;
              FlutterError.onError = errors.add;
              try {
                await show(tester, welcome, id, withName: id.startsWith('vo:welcome.hello.'));
              } finally {
                FlutterError.onError = before;
              }
              final String at = '$scale $id';
              for (final FlutterErrorDetails e in errors) {
                problems.add('$at: ${e.exception}');
              }
              final Rect r = bodyRect(tester);
              final RenderParagraph para = tester.renderObject<RenderParagraph>(
                find.descendant(of: find.byKey(const Key('bubble-body')), matching: find.byType(RichText)),
              );
              if (r.width > b.maxWidth + 0.01) problems.add('$at: ${r.width} wide');
              if (para.didExceedMaxLines) problems.add('$at: cut');
              if (r.left < 0 || r.right > b.size.width || r.top < 0 || r.bottom > b.size.height) {
                problems.add('$at: off the screen $r');
              }
              final Offset tail = tailOf(tester);
              if ((tail - mouth).distance > 0.5 || (r.right - own.right).abs() > 0.5) {
                problems.add('$at: the tail left the mouth ($tail, not $mouth)');
              }
              if (tail.dy < r.top || tail.dy > r.bottom - 18) {
                problems.add('$at: the tail is off the bubble\'s straight edge ($tail in $r)');
              }
              if (r.overlaps(pill)) problems.add('$at: covers the pill');
              if (lines[id]!.contains('?')) problems.add('$at: a question mark');
              for (final MapEntry<String, Rect> sign in signs.entries) {
                if (r.overlaps(sign.value)) problems.add('$at: covers ${sign.key}');
              }
            }
          }
          tester.platformDispatcher.clearTextScaleFactorTestValue();
          await finish(tester);
          expect(problems, isEmpty, reason: problems.join('\n'));
        });
      }
    }
  });

  group('goldens', () {
    for (final Board b in boards) {
      for (final double scale in <double>[1.0, 1.3]) {
        final String s = scale == 1.0 ? '' : '_1.3';
        testWidgets('${b.name} x$scale: the name and the first-day greeting', (WidgetTester tester) async {
          final ValueNotifier<WelcomeShown?> welcome = await welcomeOn(tester, b);
          tester.platformDispatcher.textScaleFactorTestValue = scale;
          addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
          await show(tester, welcome, 'vo:welcome.hello.first', withName: true);
          await expectLater(
            find.byType(MaterialApp),
            matchesGoldenFile('goldens/welcome_hello_${b.name}$s.png'),
          );
          await finish(tester);
        });

        testWidgets('${b.name} x$scale: the longest topic', (WidgetTester tester) async {
          final ValueNotifier<WelcomeShown?> welcome = await welcomeOn(tester, b);
          tester.platformDispatcher.textScaleFactorTestValue = scale;
          addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
          await show(tester, welcome, 'vo:welcome.topic.market.measure');
          await expectLater(
            find.byType(MaterialApp),
            matchesGoldenFile('goldens/welcome_topic_${b.name}$s.png'),
          );
          await finish(tester);
        });
      }

      testWidgets('${b.name}: no glow when the system asks for less motion', (WidgetTester tester) async {
        final ValueNotifier<WelcomeShown?> welcome = await welcomeOn(tester, b);
        final HomeScreen home = tester.widget<HomeScreen>(find.byType(HomeScreen));
        List<BoxShadow> shadows() =>
            (tester.widget<Container>(find.byKey(const Key('home-pill'))).decoration! as BoxDecoration)
                .boxShadow!;
        final int plain = shadows().length;
        await show(tester, welcome, 'vo:welcome.close');
        (home.pillGlow! as ValueNotifier<bool>).value = true;
        await tester.pump();
        expect(shadows(), hasLength(plain), reason: 'the rig asks for reduced motion');
        await finish(tester);
      });

      testWidgets('${b.name}: the closing line and the pill\'s glow', (WidgetTester tester) async {
        final ValueNotifier<WelcomeShown?> welcome = await welcomeOn(tester, b);
        final HomeScreen home = tester.widget<HomeScreen>(find.byType(HomeScreen));
        // The glow is shown only when the system does not ask for less motion: let the map move for this one frame.
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue();
        await show(tester, welcome, 'vo:welcome.close');
        (home.pillGlow! as ValueNotifier<bool>).value = true;
        await tester.pump();
        await expectLater(find.byType(MaterialApp), matchesGoldenFile('goldens/welcome_close_${b.name}.png'));
        await finish(tester);
      });
    }
  });
}
