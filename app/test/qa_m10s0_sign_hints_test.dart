// QA of M10 step 0: the right-cell hint of a spot_error sentence with × or ÷ (QA-M10S0-2). Step 0 lets `op:x` and `op::` into tap_answer
// and spot_error; the hint pictures of both were written for + and − only. No pack uses × or ÷ yet, so nothing a child sees is wrong today;
// these tests are the proof for the batch that first puts a × or ÷ sentence in front of a child (M10 section 10, step 3). They are
// skipped until then, with the ids; remove the `skip` when the fix is in.
import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/play/hints/right_cell.dart';

void main() {
  const String reasonRight =
      'QA-M10S0-2: the level 3 hint of a spot_error row with × or ÷ has no right-cell card (rightCellOf solves + and − only)';

  test('rightCellOf solves a × sentence: 6 × 3 = 9 should have 18 at the wrong cell', () {
    expect(rightCellOf(<String>['n:6', 'op:x', 'n:3', 'op:=', 'n:9'], 4), 'n:18', reason: reasonRight);
  }, skip: reasonRight);

  test('rightCellOf solves a ÷ sentence: 12 ÷ 3 = 5 should have 4 at the wrong cell', () {
    expect(rightCellOf(<String>['n:12', 'op::', 'n:3', 'op:=', 'n:5'], 4), 'n:4', reason: reasonRight);
  }, skip: reasonRight);
}
