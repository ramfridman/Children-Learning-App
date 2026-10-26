import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/design/board.dart';
import 'package:nitznutz/design/components.dart';
import 'package:nitznutz/design/layout.dart';
import 'package:nitznutz/design/token_types.dart';

import 'support/harness.dart';

void main() {
  setUpAll(loadAppFonts);

  group('size classes', () {
    test('the reference devices of the boards map to the right class', () {
      expect(sizeClassFor(const Size(852, 393)), SizeClass.phone);
      expect(sizeClassFor(const Size(667, 375)), SizeClass.phoneSE);
      expect(sizeClassFor(const Size(1180, 820)), SizeClass.tablet);
      expect(sizeClassFor(const Size(820, 1180)), SizeClass.tablet);
    });

    test('a tablet window in split screen follows the window, not the device', () {
      expect(sizeClassFor(const Size(590, 820)), SizeClass.phone);
    });

    testWidgets('layout numbers come from the tokens', (WidgetTester tester) async {
      late AppLayout layout;
      await pumpScreen(
        tester,
        Builder(
          builder: (BuildContext c) {
            layout = AppLayout.of(c);
            return const SizedBox();
          },
        ),
        band: Band.a,
      );
      expect(layout.sizeClass, SizeClass.phone);
      expect(layout.tokens.topBarHeight, 88);
      expect(layout.answerSize, 96);
      expect(layout.answerGap, 24);
      expect(layout.pebbleSize, 64);
    });
  });

  group('right to left and maths', () {
    testWidgets('the screen is right to left and the start side is the right', (WidgetTester tester) async {
      await pumpScreen(
        tester,
        const Row(
          children: <Widget>[
            SizedBox(key: Key('first'), width: 10, height: 10),
            SizedBox(width: 10),
          ],
        ),
      );
      final Offset first = tester.getTopLeft(find.byKey(const Key('first')));
      expect(first.dx, greaterThan(800));
    });

    testWidgets('a number line inside MathIsolate runs 0 to 10 from left to right', (
      WidgetTester tester,
    ) async {
      await pumpScreen(
        tester,
        const MathIsolate(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text('0', key: Key('n0')),
              Text('5', key: Key('n5')),
              Text('10', key: Key('n10')),
            ],
          ),
        ),
      );
      expect(
        tester.getTopLeft(find.byKey(const Key('n0'))).dx,
        lessThan(tester.getTopLeft(find.byKey(const Key('n5'))).dx),
      );
      expect(
        tester.getTopLeft(find.byKey(const Key('n5'))).dx,
        lessThan(tester.getTopLeft(find.byKey(const Key('n10'))).dx),
      );
    });

    testWidgets('without the isolate the same row would be mirrored', (WidgetTester tester) async {
      await pumpScreen(
        tester,
        const Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text('0', key: Key('n0')),
            Text('5', key: Key('n5')),
          ],
        ),
      );
      expect(
        tester.getTopLeft(find.byKey(const Key('n0'))).dx,
        greaterThan(tester.getTopLeft(find.byKey(const Key('n5'))).dx),
      );
    });

    testWidgets('an answer tile draws its numeral left to right', (WidgetTester tester) async {
      late TextDirection direction;
      await pumpScreen(
        tester,
        AnswerTile(
          semanticLabel: 'three',
          child: Builder(
            builder: (BuildContext c) {
              direction = Directionality.of(c);
              return const Text('3');
            },
          ),
        ),
      );
      expect(direction, TextDirection.ltr);
    });
  });

  group('components', () {
    testWidgets('a pebble button draws a 64 point disc and its tap area is larger than that', (
      WidgetTester tester,
    ) async {
      int taps = 0;
      await pumpScreen(
        tester,
        Center(
          child: PebbleButton(
            semanticLabel: 'hint',
            onPressed: () => taps++,
            child: const Icon(Icons.lightbulb),
          ),
        ),
        band: Band.a,
      );
      final Rect disc = tester.getRect(find.byKey(const Key('pebble-disc')));
      expect(disc.size, const Size(64, 64));
      // 8 points outside the drawn disc is still the button (the hit slop is 12).
      await tester.tapAt(disc.topLeft + const Offset(-8, 32));
      expect(taps, 1);
      await tester.tapAt(disc.topLeft + const Offset(-20, 32));
      expect(taps, 1, reason: 'beyond the slop is not the button');
    });

    testWidgets('a pebble button without a handler is not tappable and says so', (WidgetTester tester) async {
      await pumpScreen(
        tester,
        const Center(
          child: PebbleButton(semanticLabel: 'x', child: Icon(Icons.close)),
        ),
      );
      final SemanticsHandle handle = tester.ensureSemantics();
      expect(
        tester.getSemantics(find.bySemanticsLabel('x')),
        matchesSemantics(label: 'x', isButton: true, hasEnabledState: true, isEnabled: false),
      );
      handle.dispose();
    });

    testWidgets('answer tiles: each state has its own ring, and there is never a cross', (
      WidgetTester tester,
    ) async {
      await pumpScreen(
        tester,
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            for (final AnswerState s in AnswerState.values)
              AnswerTile(semanticLabel: s.name, state: s, child: const Text('3')),
          ],
        ),
      );
      // Idle and selected share the board's pale border; the selected tile is told apart by its outline.
      expect(<Color>{for (final AnswerState s in AnswerState.values) answerBorderColor(s)}.length, 3);
      expect(find.byIcon(Icons.close), findsNothing);
      expect(find.byIcon(Icons.close_rounded), findsNothing);
      expect(find.byIcon(Icons.check_rounded), findsOneWidget);
    });

    testWidgets('the progress trail fills from the start side (the right in Hebrew)', (
      WidgetTester tester,
    ) async {
      await pumpScreen(tester, const Center(child: ProgressTrail(total: 6, done: 2)));
      final Finder sparks = find.byType(BoardSvg);
      expect(sparks, findsNWidgets(2));
      final double sparkX = tester.getCenter(sparks.first).dx;
      final double trailMid = tester.getCenter(find.byType(ProgressTrail)).dx;
      expect(sparkX, greaterThan(trailMid));
    });

    testWidgets('the bubble uses the 1.7 line height of pointed text', (WidgetTester tester) async {
      await pumpScreen(tester, const Center(child: BoardBubble(text: 'כַּמָּה פְּרָחִים יֵשׁ?')));
      final Text text = tester.widget<Text>(find.byType(Text));
      expect(text.style!.height, greaterThanOrEqualTo(1.7));
      expect(text.style!.fontFamily, 'Heebo');
      expect(text.style!.letterSpacing, 0);
    });

    testWidgets('the parent entry button is 44 tall and says what it is', (WidgetTester tester) async {
      await pumpScreen(
        tester,
        Center(
          child: ParentEntryButton(label: 'הורים', onPressed: () {}),
        ),
      );
      expect(tester.getSize(find.byType(ParentEntryButton)).height, 44);
      expect(find.bySemanticsLabel('הורים'), findsOneWidget);
    });
  });
}
