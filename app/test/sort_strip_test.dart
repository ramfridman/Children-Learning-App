import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/content/models.dart';
import 'package:nitznutz/play/sort_drag_session.dart';

import 'support/c1_screens.dart';
import 'support/golden_comparator.dart';
import 'support/harness.dart';

/// The pattern strips of LOG-A-04 (`strip_*`, a viewBox of 120 by 48) in a sort: a wide tile in the tray (84 tall, as wide as the row allows up to 200), a
/// card 2.5 times its height wide in a bin (two side by side in a phone's bin), never mirrored in a right-to-left screen.
const String _id = 'log.pat.yes.animals';

void main() {
  late PackContent content;
  setUpAll(() async {
    await loadAppFonts();
    useTolerantGoldens(0.03);
    content = await loadSourcePack();
  });

  test('a picture whose viewBox is not square is wide; a square one is not', () {
    expect(SortDragSession.viewBoxAspect('<svg viewBox="0 0 120 48" width="120">'), closeTo(2.5, 1e-9));
    expect(SortDragSession.viewBoxAspect('<svg viewBox="0 0 100 100">'), 1);
    expect(SortDragSession.viewBoxAspect('<svg width="10">'), isNull);
    final Rect bin = SortDragSession.binRect(const Size(340, 128), 2, 0);
    final BinBands strips = SortDragSession.binBands(bin, 4, wide: true);
    final BinBands squares = SortDragSession.binBands(bin, 4);
    expect(strips.itemWidth, strips.itemSide * 2.5);
    expect(squares.itemWidth, squares.itemSide);
    expect(
      strips.items,
      greaterThanOrEqualTo(squares.items),
      reason: 'fewer fit in a line, so the band is as tall or taller',
    );
  });

  for (final (String, Size) b in boards) {
    testWidgets('${b.$1}: the strips are wide tiles 84 tall, and wide cards in the bins, not mirrored', (
      WidgetTester t,
    ) async {
      final SortDragActivity a = content.activities[_id]! as SortDragActivity;
      await startOn(t, content, b.$2);
      await openOne(t, content, a);
      final Finder tray = find.byKey(const Key('sort-tray'));
      expect(tray, findsOneWidget);
      final double trayWidth = t.getSize(tray).width;
      for (final SortItem i in a.items) {
        final Rect tile = t.getRect(
          find.descendant(
            of: find.byKey(Key('item-${i.id}')),
            matching: find.byKey(const Key('answer-tile')),
          ),
        );
        expect(tile.height, 84, reason: 'the touch target keeps its height');
        expect(tile.width, inInclusiveRange(84, 200));
        expect(
          tile.width,
          closeTo((trayWidth / a.items.length - 10).clamp(84.0, 200.0), 1.5),
          reason: 'tilesWidth / n - 10, clamped',
        );
        expect(tile.width, greaterThan(tile.height), reason: 'wide, so that the animals can be told apart');
      }
      await _shot('sortstrip_${b.$1}_tray');
      // two cards sorted: each lies in its bin 2.5 times its height wide, and the strip reads as drawn (left to right) in the right-to-left screen
      for (final SortItem i in a.items.take(2)) {
        await t.dragFrom(
          t.getCenter(find.byKey(Key('item-${i.id}'))),
          t.getCenter(find.byKey(Key('bin-${i.bin}'))) - t.getCenter(find.byKey(Key('item-${i.id}'))),
        );
        await t.pump(const Duration(milliseconds: 400));
      }
      final Finder inBins = find.descendant(
        of: find.byKey(const Key('sort-stage')),
        matching: find.byWidgetPredicate(
          (Widget w) =>
              w is SizedBox &&
              w.height != null &&
              w.width != null &&
              w.width! > w.height! &&
              w.width! == w.height! * SortDragSession.wideItem &&
              w.height! <= 26,
        ),
      );
      expect(
        inBins.evaluate().length,
        greaterThanOrEqualTo(2),
        reason: 'a wide card in a bin for each card sorted',
      );
      for (final Element e in inBins.evaluate()) {
        final Iterable<SvgPicture> pictures = find
            .descendant(of: find.byWidget(e.widget), matching: find.byType(SvgPicture))
            .evaluate()
            .map((Element x) => x.widget as SvgPicture);
        expect(pictures, isNotEmpty);
        expect(
          pictures.every((SvgPicture p) => !p.matchTextDirection),
          isTrue,
          reason: 'a pattern reads the way it is drawn',
        );
        final Rect r = t.getRect(find.byWidget(e.widget));
        expect(r.width / r.height, closeTo(2.5, 0.01));
      }
      await _shot('sortstrip_${b.$1}_sorted');
      await closeOne(t);
    });
  }
}

Future<void> _shot(String name) =>
    expectLater(find.byType(MaterialApp), matchesGoldenFile('goldens/$name.png'));
