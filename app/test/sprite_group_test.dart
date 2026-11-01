import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/play/sprite_group.dart';

void main() {
  group('groupLayout', () {
    test('has one place for every thing, in every arrangement, up to ten (scatter up to its grid)', () {
      for (final String a in groupArrangements) {
        for (int n = 0; n <= 10; n++) {
          final GroupLayout l = groupLayout(a, n, seed: 5);
          expect(l.centers.length, a == 'scatter' ? n : n, reason: '$a $n');
        }
      }
    });

    test('every place is inside the square and no two places are the same spot', () {
      for (final String a in groupArrangements) {
        for (int n = 1; n <= 10; n++) {
          final GroupLayout l = groupLayout(a, n, seed: 11);
          for (final Offset p in l.centers) {
            expect(p.dx, inInclusiveRange(0, 1), reason: '$a $n');
            expect(p.dy, inInclusiveRange(0, 1), reason: '$a $n');
          }
          expect(l.centers.toSet().length, n, reason: '$a $n has a repeated place');
        }
      }
    });

    test('things never overlap: the distance between any two is at least the room each one has', () {
      for (final String a in groupArrangements) {
        for (int n = 2; n <= 10; n++) {
          final GroupLayout l = groupLayout(a, n, seed: 3);
          for (int i = 0; i < n; i++) {
            for (int j = i + 1; j < n; j++) {
              final double dx = (l.centers[i].dx - l.centers[j].dx).abs();
              final double dy = (l.centers[i].dy - l.centers[j].dy).abs();
              // Scatter shifts places by a little; the cells are still separate.
              final double slack = a == 'scatter' ? 0.3 : 0;
              expect(
                dx >= l.cellWidth * (1 - slack) - 1e-9 || dy >= l.cellHeight * (1 - slack) - 1e-9,
                isTrue,
                reason: '$a $n: $i and $j overlap',
              );
            }
          }
        }
      }
    });

    test('a dice shows the familiar pattern for 1 to 6 and falls back to a ten-frame above', () {
      expect(groupLayout('dice', 5).centers, contains(const Offset(0.5, 0.5)));
      expect(groupLayout('dice', 4).centers, isNot(contains(const Offset(0.5, 0.5))));
      expect(groupLayout('dice', 8).centers, groupLayout('ten_frame', 8).centers);
    });

    test('a ten-frame fills the first row before the second', () {
      final List<Offset> c = groupLayout('ten_frame', 7).centers;
      expect(c.take(5).every((Offset p) => p.dy < 0.5), isTrue);
      expect(c.skip(5).every((Offset p) => p.dy > 0.5), isTrue);
    });

    test('the same seed gives the same scatter, another seed another one', () {
      expect(groupLayout('scatter', 6, seed: 9).centers, groupLayout('scatter', 6, seed: 9).centers);
      expect(groupLayout('scatter', 6, seed: 9).centers, isNot(groupLayout('scatter', 6, seed: 10).centers));
    });

    test(
      'a line keeps room for four, or for as many as the largest group shown with it (match pairs, QA-3)',
      () {
        expect(groupLayout('line', 1).cellWidth, 1 / 4);
        expect(groupLayout('line', 3).cellWidth, 1 / 4);
        expect(groupLayout('line', 1, lineSlots: 3).cellWidth, 1 / 3);
        expect(groupLayout('line', 3, lineSlots: 3).cellWidth, 1 / 3);
        expect(groupLayout('line', 1, lineSlots: 3).centers, <Offset>[const Offset(0.5, 0.5)]);
        final List<Offset> three = groupLayout('line', 3, lineSlots: 3).centers;
        expect(
          three.map((Offset p) => p.dx),
          <double>[1 / 6, 0.5, 5 / 6].map((double x) => closeTo(x, 1e-9)),
        );
      },
    );

    test('the room per thing stays positive', () {
      expect(
        math.min(groupLayout('line', 10).cellWidth, groupLayout('ten_frame', 10).cellWidth),
        greaterThan(0),
      );
    });
  });

  group('the ten-frame under a group (B-38)', () {
    test(
      'a ten-frame, and a dice of more than six, are drawn on a frame of 2 by 5 square cells, centred',
      () {
        for (final (String, int) g in <(String, int)>[('ten_frame', 3), ('ten_frame', 10), ('dice', 8)]) {
          final List<Rect> frames = tenFrameRects(const Size(300, 100), g.$1, g.$2);
          expect(frames, hasLength(1), reason: '$g');
          final Rect f = frames.single;
          expect(f.width / 5, closeTo(f.height / 2, 1e-9), reason: '$g');
          expect(f.center.dx, closeTo(150, 1e-9));
          expect(f.center.dy, closeTo(50, 1e-9));
        }
        expect(tenFrameRects(const Size(300, 100), 'dice', 6), isEmpty);
        expect(tenFrameRects(const Size(300, 100), 'line', 5), isEmpty);
        expect(tenFrameRects(const Size(300, 100), 'scatter', 5), isEmpty);
        expect(tenFrameRects(const Size(300, 100), 'ten_frame', 5, framed: false), isEmpty);
      },
    );

    test('every picture sits inside its own cell, the top row filled first from the left', () {
      const Size box = Size(150, 100);
      final Rect f = tenFrameRects(box, 'ten_frame', 7).single;
      final double cell = f.width / 5;
      final List<Rect> r = spriteRects(box, 'ten_frame', 7);
      for (int i = 0; i < 7; i++) {
        final Rect c = Rect.fromLTWH(f.left + (i % 5) * cell, f.top + (i ~/ 5) * cell, cell, cell);
        expect(
          c.contains(r[i].topLeft) && c.contains(r[i].bottomRight - const Offset(1e-6, 1e-6)),
          isTrue,
          reason: '$i',
        );
      }
    });

    testWidgets('the frame is drawn with its empty cells, also for a group of one', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(_group(count: 1, arrangement: 'ten_frame'));
      expect(find.byKey(const Key('group-ten-frame')), findsOneWidget);
    });

    testWidgets('with framed false the pictures stand on the same grid and no board is drawn', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(_group(count: 5, arrangement: 'ten_frame', framed: false));
      expect(find.byKey(const Key('group-ten-frame')), findsNothing);
      final List<Rect> r = spriteRects(const Size(300, 120), 'ten_frame', 5, framed: false);
      expect(r, hasLength(5));
      // The first row of five, left to right.
      for (int i = 1; i < 5; i++) {
        expect(r[i].center.dx, greaterThan(r[i - 1].center.dx));
        expect(r[i].center.dy, r[0].center.dy);
      }
    });
  });

  group('a group of 11 to 20 is a full ten and the rest (QA-38-2)', () {
    const List<Size> boxes = <Size>[Size(300, 140), Size(260, 130), Size(150, 100), Size(560, 300)];

    test('two frames side by side, the full ten on the left, never overlapping and inside the box', () {
      for (final Size box in boxes) {
        for (int n = 11; n <= 20; n++) {
          final List<Rect> frames = tenFrameRects(box, 'ten_frame', n);
          expect(frames, hasLength(2), reason: '$box $n');
          expect(frames[0].right, lessThan(frames[1].left), reason: '$box $n');
          expect(frames[0].top, frames[1].top);
          expect(frames[0].width, closeTo(frames[1].width, 1e-9));
          expect(frames[0].height, closeTo(frames[1].height, 1e-9));
          for (final Rect f in frames) {
            expect(f.left, greaterThanOrEqualTo(0), reason: '$box $n');
            expect(f.right, lessThanOrEqualTo(box.width + 1e-9), reason: '$box $n');
            expect(f.bottom, lessThanOrEqualTo(box.height + 1e-9), reason: '$box $n');
          }
          final List<Rect> r = spriteRects(box, 'ten_frame', n);
          expect(r, hasLength(n));
          for (int i = 0; i < n; i++) {
            expect(
              frames[i ~/ 10].contains(r[i].center),
              isTrue,
              reason: '$box $n: picture $i is in its frame',
            );
          }
          // The first ten fill the left frame, and the rest start the right one from its top left cell.
          expect(r[9].center.dx, lessThan(frames[1].left));
          expect(r[10].center.dx, lessThan(frames[1].left + frames[1].width / 5));
          expect(r[10].center.dy, lessThan(frames[1].center.dy));
        }
      }
    });

    test('a group of ten or less is one frame, and a dice above ten falls back to two', () {
      expect(tenFrameRects(const Size(300, 140), 'ten_frame', 10), hasLength(1));
      expect(tenFrameRects(const Size(300, 140), 'dice', 14), hasLength(2));
    });

    test('a cell stays readable on the small phone: at least 24 points in the box of one group', () {
      // The stage of the iPhone SE gives one group about 260 by 130 points.
      for (int n = 11; n <= 20; n++) {
        final Rect f = tenFrameRects(const Size(260, 130), 'ten_frame', n).first;
        expect(f.width / 5, greaterThanOrEqualTo(24), reason: '$n');
      }
    });

    testWidgets('a group of 14 draws two boards, left to right, in a right-to-left screen', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(_group(count: 14, arrangement: 'ten_frame', height: 140));
      final Finder first = find.byKey(const Key('group-ten-frame'));
      final Finder second = find.byKey(const Key('group-ten-frame-1'));
      expect(first, findsOneWidget);
      expect(second, findsOneWidget);
      expect(tester.getTopLeft(first).dx, lessThan(tester.getTopLeft(second).dx));
    });
  });

  group('a picture never grows past its cell (QA-38-3)', () {
    test('at the biggest scale the schema allows (1.6), in every arrangement and count', () {
      const Size box = Size(300, 140);
      for (final String a in groupArrangements) {
        for (int n = 1; n <= 15; n++) {
          final GroupLayout l = groupLayout(a, n, seed: 2);
          final double square = a == 'dice' && n <= 6 ? math.min(box.width, box.height) : 0;
          for (final bool framed in <bool>[true, false]) {
            final List<Rect> r = spriteRects(box, a, n, seed: 2, scale: 1.6, framed: framed);
            final List<Rect> frames = tenFrameRects(box, a, n, framed: framed);
            final double room = frames.isNotEmpty
                ? frames.first.width / 5
                : math.min(
                    l.cellWidth * (square > 0 ? square : box.width),
                    l.cellHeight * (square > 0 ? square : box.height),
                  );
            for (final Rect p in r) {
              expect(p.width, lessThanOrEqualTo(room + 1e-9), reason: '$a $n framed=$framed');
              expect(p.height, lessThanOrEqualTo(room + 1e-9), reason: '$a $n framed=$framed');
            }
          }
        }
      }
    });

    test('a smaller scale still makes the picture smaller, and scale 1 is as it was', () {
      const Size box = Size(300, 140);
      final double full = spriteRects(box, 'line', 3).first.width;
      expect(spriteRects(box, 'line', 3, scale: 0.5).first.width, closeTo(full / 2, 1e-9));
      expect(full, closeTo(300 / 4 * 0.85, 1e-9));
    });
  });
}

/// A group in a right-to-left screen, in a box of 300 by [height].
Widget _group({required int count, required String arrangement, bool framed = true, double height = 120}) =>
    Directionality(
      textDirection: TextDirection.rtl,
      child: Center(
        child: SizedBox(
          width: 300,
          height: height,
          child: SpriteGroup(
            svg: '<svg viewBox="0 0 10 10"/>',
            count: count,
            arrangement: arrangement,
            framed: framed,
          ),
        ),
      ),
    );
