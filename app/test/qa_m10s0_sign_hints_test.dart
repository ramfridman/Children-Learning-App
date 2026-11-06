// QA of M10 step 0: the right-cell hint of a spot_error sentence with × or ÷ (QA-M10S0-2). Step 0 lets `op:x` and `op::` into tap_answer
// and spot_error; `rightCellOf` solves them as it solves + and −, and a ÷ is exact only (a remainder is never the right cell).
import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/play/hints/right_cell.dart';

void main() {
  test('rightCellOf solves a × sentence: 6 × 3 = 9 should have 18 at the wrong cell', () {
    expect(rightCellOf(<String>['n:6', 'op:x', 'n:3', 'op:=', 'n:9'], 4), 'n:18');
  });

  test('rightCellOf solves a ÷ sentence: 12 ÷ 3 = 5 should have 4 at the wrong cell', () {
    expect(rightCellOf(<String>['n:12', 'op::', 'n:3', 'op:=', 'n:5'], 4), 'n:4');
  });

  test('rightCellOf finds a number in the middle and a sign of × and ÷', () {
    expect(rightCellOf(<String>['n:6', 'op:x', 'n:5', 'op:=', 'n:18'], 2), 'n:3');
    expect(rightCellOf(<String>['n:12', 'op::', 'n:5', 'op:=', 'n:4'], 2), 'n:3');
    expect(rightCellOf(<String>['n:12', 'op:x', 'n:3', 'op:=', 'n:4'], 1), 'op::');
    expect(rightCellOf(<String>['n:12', 'op:+', 'n:3', 'op:=', 'n:36'], 1), 'op:x');
    expect(rightCellOf(<String>['n:12', 'op:x', 'n:12', 'op:=', 'n:100'], 4), 'n:144');
  });

  test(
    'a ÷ is exact only: no remainder, no division by zero, and a sentence with two answers gives none',
    () {
      expect(rightCellOf(<String>['n:7', 'op::', 'n:2', 'op:=', 'n:4'], 4), isNull);
      expect(rightCellOf(<String>['n:7', 'op::', 'n:0', 'op:=', 'n:4'], 4), isNull);
      expect(
        rightCellOf(<String>['n:2', 'op:+', 'n:2', 'op:=', 'n:4'], 1),
        isNull,
        reason: '2 + 2 = 4 and 2 × 2 = 4: the sign is not told by the row',
      );
    },
  );
}
