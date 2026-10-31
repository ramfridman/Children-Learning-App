import 'package:flutter/painting.dart' show Rect;
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

  test('cropToInk and the pack viewBox check survive a double dot', () {
    expect(
      cropToInk('<svg viewBox="0 0 1.2.3 100"></svg>', const Rect.fromLTWH(0, 0, 1, 1)),
      contains('viewBox'),
    );
    expect(cropToInk('<svg viewBox="0 0 0 0"></svg>', const Rect.fromLTWH(0, 0, 1, 1)), contains('viewBox'));
  });
}
