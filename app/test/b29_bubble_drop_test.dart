// B-29 (docs/design/b29-caption-overlap.md): the caption bubble stays out of the phone's stage, so a drop or a tap on any part of a target
// (a bin, a coin) lands on the target and never on the bubble, at the start and at every hint, on the phone and the small phone.
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/content/models.dart';

import 'support/bubble_audit.dart';
import 'support/c1_screens.dart';
import 'support/harness.dart';

void main() {
  late PackContent content;
  setUpAll(() async {
    await loadAppFonts();
    content = await loadSourcePack();
  });

  /// Whether a touch at [at] reaches [target] (or something inside it) before anything else that is not inside it.
  bool reaches(WidgetTester t, Finder target, Offset at) {
    final RenderObject root = t.renderObject(target);
    final HitTestResult hit = t.hitTestOnBinding(at);
    bool inside(RenderObject o) {
      for (RenderObject? p = o; p != null; p = p.parent) {
        if (identical(p, root)) return true;
      }
      return false;
    }

    for (final HitTestEntry e in hit.path) {
      final HitTestTarget x = e.target;
      if (x is RenderObject && inside(x)) return true;
    }
    return false;
  }

  /// The points of a target's rectangle: its middle, the middle of each edge and each corner, three points in from the edge.
  List<Offset> pointsOf(Rect r) {
    final Rect q = r.deflate(3);
    return <Offset>[
      q.center,
      q.centerLeft,
      q.centerRight,
      q.topCenter,
      q.bottomCenter,
      q.topLeft,
      q.topRight,
      q.bottomLeft,
      q.bottomRight,
    ];
  }

  const List<({String board, Size size})> boards = <({String board, Size size})>[
    (board: 'phone', size: Size(852, 393)),
    (board: 'phoneSE', size: Size(667, 375)),
  ];

  for (final ({String board, Size size}) b in boards) {
    for (final AuditLook look in auditLooks) {
      testWidgets(
        'share the stars: a drop on any part of a bin lands on the bin, with the bubble open, ${b.board}, ${look.name}',
        (WidgetTester t) async {
          await startOn(t, content, b.size, look: look);
          await openQuickly(t, content, content.activities['math.share.stars']!);
          for (int level = 0; level <= 3; level++) {
            if (level > 0) {
              await t.tap(find.byKey(const Key('lesson-hint')), warnIfMissed: false);
              await waitSteps(t, 300);
            }
            expect(bubbleOverStage(t), isEmpty, reason: 'level $level');
            final Finder bins = find.byWidgetPredicate(
              (Widget w) =>
                  w.key is ValueKey<String> && (w.key! as ValueKey<String>).value.startsWith('bin-'),
            );
            expect(bins, findsWidgets);
            for (final Element e in bins.evaluate()) {
              final Finder bin = find.byWidget(e.widget);
              for (final Offset p in pointsOf(t.getRect(bin))) {
                expect(reaches(t, bin, p), isTrue, reason: 'level $level, a drop at $p on ${e.widget.key}');
              }
            }
          }
          await closeOne(t);
        },
        timeout: const Timeout(Duration(minutes: 3)),
      );

      testWidgets(
        'pay the price: a tap on any coin lands on the coin, with the bubble open, ${b.board}, ${look.name}',
        (WidgetTester t) async {
          await startOn(t, content, b.size, look: look);
          await openQuickly(t, content, content.activities['x.mathb17.1']!);
          for (int level = 0; level <= 3; level++) {
            if (level > 0) {
              await t.tap(find.byKey(const Key('lesson-hint')), warnIfMissed: false);
              await waitSteps(t, 300);
            }
            expect(bubbleOverStage(t), isEmpty, reason: 'level $level');
            final Finder coins = find.byWidgetPredicate(
              (Widget w) =>
                  w.key is ValueKey<String> && (w.key! as ValueKey<String>).value.startsWith('coin-'),
            );
            expect(coins, findsWidgets);
            for (final Element e in coins.evaluate()) {
              final Finder coin = find.byWidget(e.widget);
              expect(
                reaches(t, coin, t.getRect(coin).center),
                isTrue,
                reason: 'level $level, ${e.widget.key}',
              );
            }
          }
          await closeOne(t);
        },
        timeout: const Timeout(Duration(minutes: 3)),
      );
    }
  }
}
