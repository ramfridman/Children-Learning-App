import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/content/models.dart';
import 'package:nitznutz/play/sort_drag_session.dart';

import 'support/c1_screens.dart';
import 'support/golden_comparator.dart';
import 'support/harness.dart';

/// The pattern strips of LOG-A-04 (`strip_*`, a viewBox of 120 by 48) in a sort, on the board of docs/design/m11/min-sizes.md section 3: on a
/// phone a deck of wide tiles (one card at a time) and two shelves, each showing its newest card at full size and the earlier ones as a pile
/// with a count badge; on a tablet all the cards in a grid and two bins side by side. A card is never drawn smaller than the table says, and
/// a strip reads the way it is drawn in a right-to-left screen.
const String _id = 'log.pat.yes.animals';

/// Per board: the tray's tile, the card in the tray, the card in a bin, the bin's label size and its sample picture's side.
typedef _Sizes = ({Size tile, Size tray, Size bin, double label, double sample});

const Map<String, _Sizes> _sizes = <String, _Sizes>{
  'phone': (tile: Size(184, 88), tray: Size(176, 70.4), bin: Size(190, 76), label: 18, sample: 44),
  'phoneSE': (tile: Size(196, 86), tray: Size(188, 75.2), bin: Size(170, 68), label: 18, sample: 40),
  'tabletL': (tile: Size(300, 112), tray: Size(250, 100), bin: Size(300, 120), label: 24, sample: 48),
  'tabletP': (tile: Size(340, 128), tray: Size(300, 120), bin: Size(280, 112), label: 24, sample: 48),
};

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
  });

  for (final (String, Size) b in boards) {
    testWidgets(
      '${b.$1}: the strips are drawn at the table of the board, a pile counts the rest, never mirrored',
      (WidgetTester t) async {
        final _Sizes want = _sizes[b.$1] ?? _sizes['phone']!;
        final bool deck = b.$1.startsWith('phone');
        final SortDragActivity a = content.activities[_id]! as SortDragActivity;
        await startOn(t, content, b.$2);
        await openOne(t, content, a);
        expect(find.byKey(const Key('sort-tray')), findsOneWidget);
        // the tray: a deck (the top card only) on a phone, every card on a tablet
        final Iterable<SortItem> tray = a.items.where(
          (SortItem i) => find.byKey(Key('item-${i.id}')).evaluate().isNotEmpty,
        );
        expect(tray.length, deck ? 1 : a.items.length);
        for (final SortItem i in tray) {
          final Rect tile = t.getRect(
            find.descendant(
              of: find.byKey(Key('item-${i.id}')),
              matching: find.byKey(const Key('answer-tile')),
            ),
          );
          expect(tile.size, _near(want.tile), reason: 'the wide tile');
          expect(
            t.getSize(find.byKey(Key('tray-card-${i.id}'))),
            _near(want.tray),
            reason: 'the card in the tray',
          );
        }
        await _shot('sortstrip_${b.$1}_tray');
        // every card that belongs in the first bin goes in: they pile in it, the newest at full size, with a count
        final SortBin first = a.bins.first;
        final List<SortItem> mine = a.items.where((SortItem i) => i.bin == first.id).toList();
        expect(mine.length, greaterThanOrEqualTo(2));
        for (final SortItem i in mine) {
          final Finder card = find.byKey(Key('item-${i.id}'));
          // on a phone the card comes to the top of the deck once the others have gone: sort the cards of the other bin too
          while (card.evaluate().isEmpty) {
            final SortItem other = a.items.firstWhere(
              (SortItem x) => x.bin != first.id && find.byKey(Key('item-${x.id}')).evaluate().isNotEmpty,
            );
            await _sort(t, other);
          }
          await _sort(t, i);
        }
        final Finder inBin = find.byWidgetPredicate(
          (Widget w) =>
              w.key is ValueKey<String> && (w.key! as ValueKey<String>).value.startsWith('bin-card-'),
        );
        final List<Rect> cards = <Rect>[
          for (final Element e in inBin.evaluate()) t.getRect(find.byWidget(e.widget)),
        ];
        expect(cards, isNotEmpty);
        for (final Rect r in cards) {
          expect(
            r.size,
            _near(want.bin),
            reason: 'every card in a bin is the same size: a pile, not a shrink',
          );
          expect(r.width / r.height, closeTo(2.5, 0.01));
        }
        final Finder count = find.byKey(Key('bin-count-${first.id}'));
        final bool piled = mine.length > (b.$1 == 'tabletP' ? 2 : 1);
        expect(count, piled ? findsOneWidget : findsNothing, reason: 'the badge shows when cards are piled');
        if (piled) {
          expect(find.byKey(Key('bin-pile-${first.id}')), findsOneWidget);
          expect(find.descendant(of: count, matching: find.text('${mine.length}')), findsOneWidget);
          expect(t.getSize(count).width, greaterThanOrEqualTo(b.$1.startsWith('tablet') ? 40 : 30));
        }
        // the strip reads as drawn (left to right) in the right-to-left screen
        for (final Element e in inBin.evaluate()) {
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
        }
        // the label and the sample picture of a bin
        final Text label = t.widget<Text>(find.byKey(Key('bin-label-${first.id}')));
        expect(label.style!.fontSize! * (label.textScaler?.scale(1) ?? 1), greaterThanOrEqualTo(want.label));
        expect(label.style!.fontWeight, FontWeight.w500);
        expect(label.style!.height, 1.7);
        expect(
          t.getSize(find.byKey(const Key('bin-sample')).first).shortestSide,
          greaterThanOrEqualTo(want.sample - 0.5),
        );
        await _shot('sortstrip_${b.$1}_sorted');
        await closeOne(t);
      },
    );
  }
}

Matcher _near(Size s) => predicate<Size>(
  (Size x) => (x.width - s.width).abs() < 1 && (x.height - s.height).abs() < 1,
  'a size of about ${s.width} by ${s.height}',
);

/// Drags [i] into its own bin.
Future<void> _sort(WidgetTester t, SortItem i) async {
  final Offset from = t.getCenter(find.byKey(Key('item-${i.id}')));
  await t.dragFrom(from, t.getCenter(find.byKey(Key('bin-${i.bin}'))) - from);
  await t.pump(const Duration(milliseconds: 400));
}

Future<void> _shot(String name) =>
    expectLater(find.byType(MaterialApp), matchesGoldenFile('goldens/$name.png'));
