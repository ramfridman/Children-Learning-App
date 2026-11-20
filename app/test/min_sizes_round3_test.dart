// The root-cause fixes of the third minimum-sizes round (docs/agents/dev-report-2026-11-20.md): a picture is cut to its ink and its box is as long as
// its ink needs, the objects of a count have a cell of 64 where the room allows, the hint chip is 32 with a numeral of 20, and the guess tiles of a Show
// stand over the box of the template's tiles.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/content/models.dart';
import 'package:nitznutz/play/count_tap_session.dart';
import 'package:nitznutz/play/hints/hint_pictures.dart';
import 'package:nitznutz/play/ink_fit.dart';

import 'support/c1_screens.dart';

const String _ball = '<svg viewBox="0 0 100 100"><circle cx="50" cy="50" r="36" fill="#c33"/></svg>';
const String _flat =
    '<svg viewBox="0 0 100 100"><rect x="10" y="40" width="80" height="20" fill="#963"/></svg>';
const String _stick =
    '<svg viewBox="0 0 100 100"><rect x="45" y="5" width="10" height="90" fill="#963"/></svg>';

void main() {
  group('InkFit', () {
    test('a round picture is cut to its ink and keeps a square box', () {
      final InkFit f = InkFit.of(_ball);
      final Size box = f.boxFor(48, target: 42, maxW: 200, maxH: 100);
      expect(box, const Size(48, 48));
      expect(f.inkOf(48, 48), greaterThan(42));
    });

    test('a flat picture gets a wider box, a thin one a taller box, until the ink is seen', () {
      final InkFit flat = InkFit.of(_flat);
      final Size wide = flat.boxFor(48, target: 42, maxW: 200, maxH: 100);
      expect(wide.width, greaterThan(48));
      expect(wide.height, 48);
      expect(flat.inkOf(wide.width, wide.width / flat.aspect), greaterThanOrEqualTo(42));
      final InkFit stick = InkFit.of(_stick);
      final Size tall = stick.boxFor(48, target: 42, maxW: 200, maxH: 100);
      expect(tall.height, greaterThan(48));
      expect(tall.width, 48);
    });

    test('the box never passes the room it is given', () {
      final Size box = InkFit.of(_stick).boxFor(48, target: 60, maxW: 60, maxH: 70);
      expect(box.height, 70);
    });
  });

  group('the chip of a hint', () {
    for (final (Size board, double side, double font) in <(Size, double, double)>[
      (const Size(852, 393), 32, 20),
      (const Size(667, 375), 32, 20),
      (const Size(1180, 820), 40, 24),
    ]) {
      testWidgets('is $side across with a numeral of $font on a ${board.width.toInt()} board', (
        WidgetTester t,
      ) async {
        await t.pumpWidget(
          MaterialApp(
            home: MediaQuery(
              data: MediaQueryData(size: board),
              child: const Center(child: HintBadge(n: 3)),
            ),
          ),
        );
        expect(t.getSize(find.byKey(const Key('hint-badge'))).width, side);
        expect(t.widget<Text>(find.text('3')).style!.fontSize, font);
      });
    }
  });

  group('the objects of a count', () {
    late PackContent pack;
    setUpAll(() async => pack = await loadSourcePack());

    test('ten in a line have a touch square of 64 on the phone stage that a picture stage gives', () {
      final CountTapActivity a = pack.activities['b15.numa02.3']! as CountTapActivity;
      expect(a.count, 10);
      final CountLayout l = CountLayout(const Size(377, 253), a);
      expect(l.touch, greaterThanOrEqualTo(64));
      expect(l.objectSize, greaterThanOrEqualTo(0.84 * 64));
      // the objects run left to right, row after row, in the order of the line
      for (int i = 1; i < 4; i++) {
        expect(l.centers[i].dx, greaterThan(l.centers[i - 1].dx));
      }
    });

    test('no two touch squares overlap', () {
      final CountTapActivity a = pack.activities['b15.numa02.3']! as CountTapActivity;
      final CountLayout l = CountLayout(const Size(377, 253), a);
      for (int i = 0; i < l.centers.length; i++) {
        for (int j = i + 1; j < l.centers.length; j++) {
          final Offset d = l.centers[i] - l.centers[j];
          expect(d.dx.abs() >= l.touch - 0.01 || d.dy.abs() >= l.touch - 0.01, isTrue);
        }
      }
    });
  });
}
