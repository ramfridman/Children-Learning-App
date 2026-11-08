import 'package:flutter/painting.dart' show Offset, Rect;
import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/play/hints/tap_plans.dart';
import 'package:nitznutz/play/hints/sprite_outline.dart';
import 'package:nitznutz/play/hints/prompt_numbers.dart';

void main() {
  // SVG number grammar allows "1.2.3" (two numbers 1.2 and .3); the parsers must not throw on it.
  test('inkBoxOf survives viewBox with a double dot', () {
    expect(
      () => inkBoxOf('<svg viewBox="0 0 1.2.3 100"><rect x="1" y="1" width="2" height="2"/></svg>'),
      returnsNormally,
    );
  });
  test('inkBoxOf survives polygon points with a double dot', () {
    expect(
      () => inkBoxOf('<svg viewBox="0 0 100 100"><polygon points="1.2.3,4 5,6"/></svg>'),
      returnsNormally,
    );
  });
  test('inkBoxOf survives a lone dot in translate/scale', () {
    expect(
      () => inkBoxOf(
        '<svg viewBox="0 0 100 100"><g transform="translate(. 1) scale(1) translate(0 0)"><rect x="1"/></g></svg>',
      ),
      returnsNormally,
    );
  });
  test('inkBoxOf zero viewBox gives finite rect', () {
    final r = inkBoxOf('<svg viewBox="0 0 0 0"><rect x="1" y="1" width="2" height="2"/></svg>');
    expect(r.left.isFinite && r.right.isFinite && r.top.isFinite && r.bottom.isFinite, isTrue, reason: '$r');
  });
  test('outlineOf survives a curve with a double dot', () {
    expect(
      () => outlineOf('<svg viewBox="0 0 100 100"><path d="M 1.2.3 4 Q 5 6 7 8 Z"/></svg>'),
      returnsNormally,
    );
  });
  test('outlineOf polygon with trailing dot', () {
    expect(() => outlineOf('<svg><polygon points="5. 6. 7 8"/></svg>'), returnsNormally);
  });
  test('large inputs finish quickly', () {
    final big = '<polygon ${'a' * 200000}';
    final sw = Stopwatch()..start();
    outlineOf(big * 5);
    inkBoxOf('<svg viewBox="0 0 100 100">${big * 5}');
    numbersIn('${'א' * 200000}${' ' * 200000}');
    expect(sw.elapsedMilliseconds, lessThan(5000), reason: '${sw.elapsedMilliseconds} ms');
  });

  test('an unclosed tag run is skipped fast, however it is cut', () {
    for (final String svg in <String>[
      '<svg viewBox="0 0 100 100">${'<path ' * 20000}',
      '<svg viewBox="0 0 100 100">${'<path ' * 10000}',
      '<svg viewBox="0 0 100 100">${'<rect ' * 10000}',
      '<polygon ' * 7000,
    ]) {
      final Stopwatch sw = Stopwatch()..start();
      final Rect ink = inkBoxOf(svg);
      final SpriteOutline? outline = outlineOf(svg);
      sw.stop();
      expect(
        sw.elapsedMilliseconds,
        lessThan(200),
        reason: '${svg.length} chars: ${sw.elapsedMilliseconds} ms',
      );
      expect(ink, const Rect.fromLTWH(0, 0, 1, 1));
      expect(outline, isNull);
    }
  });

  test('a picture over the size cap is not read', () {
    final String big =
        '<svg viewBox="0 0 100 100"><rect x="10" y="10" width="20" height="20"/>${' ' * 70000}</svg>';
    expect(inkBoxOf(big), const Rect.fromLTWH(0, 0, 1, 1));
    expect(outlineOf(big), isNull);
  });

  test('a normal picture is still read', () {
    const String svg = '<svg viewBox="0 0 100 100"><rect x="10" y="20" width="30" height="40"/></svg>';
    expect(inkBoxOf(svg), const Rect.fromLTRB(0.1, 0.2, 0.4, 0.6));
    expect(outlineOf(svg)!.sides, 4);
  });

  group('outlineOf reads a path of straight sides', () {
    String svg(String d) => '<svg viewBox="0 0 100 100"><path d="$d"/><path d="M5 5 Q9 9 12 3"/></svg>';

    test('a triangle (M L H Z) has three corners and comes back to the first', () {
      final SpriteOutline o = outlineOf(svg('M50 12 L90 84 H10 Z'))!;
      expect(o.closed, isTrue);
      expect(o.sides, 3);
      expect(o.points, <Offset>[const Offset(0.5, 0.12), const Offset(0.9, 0.84), const Offset(0.1, 0.84)]);
    });

    test('a rounded square is read at the four corners where its straight sides would meet', () {
      final SpriteOutline o = outlineOf(
        svg(
          'M14 18 C14 15.5 15.5 14 18 14 H82 C84.5 14 86 15.5 86 18 V82 C86 84.5 84.5 86 82 86 '
          'H18 C15.5 86 14 84.5 14 82 Z',
        ),
      )!;
      expect(o.sides, 4);
      final List<Offset> want = <Offset>[
        const Offset(0.14, 0.14),
        const Offset(0.86, 0.14),
        const Offset(0.86, 0.86),
        const Offset(0.14, 0.86),
      ];
      for (int i = 0; i < 4; i++) {
        expect((o.points[i] - want[i]).distance, lessThan(1e-9), reason: 'corner $i: ${o.points[i]}');
      }
    });

    test('a path that does not close has one side fewer than corners', () {
      final SpriteOutline o = outlineOf(svg('M12 84 L50 14 L88 84 L24 84'))!;
      expect(o.closed, isFalse);
      expect(o.sides, 3);
    });

    test('only the first path is the outline: a circle drawn with a highlight stroke has no corners', () {
      expect(outlineOf(svg('M12 50 A38 38 0 1 1 88 50 A38 38 0 1 1 12 50 Z')), isNull);
    });

    test(
      'a relative or unknown command, two curves in a row, a second subpath or a stray number give null',
      () {
        for (final String d in <String>[
          'm 10 10 l 5 5 z',
          'M10 10 L20 10 S30 30 10 20 Z',
          'M10 10 C10 5 15 0 20 0 C25 0 30 5 30 10 Z',
          'M10 10 L20 10 L20 20 Z M40 40 L50 40 L50 50 Z',
          'M10 10 L20 10 30 L20 20 Z',
          'L10 10 L20 20 Z',
          'M10 10 Z',
        ]) {
          expect(outlineOf(svg(d)), isNull, reason: d);
        }
      },
    );
  });

  test('cropToInk and the pack viewBox check survive a double dot', () {
    expect(
      cropToInk('<svg viewBox="0 0 1.2.3 100"></svg>', const Rect.fromLTWH(0, 0, 1, 1)),
      contains('viewBox'),
    );
    expect(cropToInk('<svg viewBox="0 0 0 0"></svg>', const Rect.fromLTWH(0, 0, 1, 1)), contains('viewBox'));
  });
}
