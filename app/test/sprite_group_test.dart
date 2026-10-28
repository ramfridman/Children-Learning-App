import 'dart:math' as math;

import 'package:flutter/painting.dart';
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

    test('the room per thing stays positive', () {
      expect(
        math.min(groupLayout('line', 10).cellWidth, groupLayout('ten_frame', 10).cellWidth),
        greaterThan(0),
      );
    });
  });
}
