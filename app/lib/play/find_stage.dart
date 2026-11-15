import 'dart:math' as math;
import 'dart:ui' show Rect, Size;

/// Where the pictures of a Find stand on the stage of a phone (docs/design/l7-meet-find.md section 6.4). A picture choice whose pictures
/// stand on the stage with no answer tiles used to draw them in a stage 128 high (66 to 95 points wide); it now has the whole start column,
/// so that two pictures are 166 points wide on the phone and 110 on the small phone, three about 100, and on the small phone, whose stage is
/// 264 wide, three pictures stand in two rows, two then one.
///
/// The gap between pictures is twice the look's hit slop: 32 for the youngest looks, 24 for the older ones when there are three. [first] is
/// where the first option stands: at the left for English and Russian, at the right for Hebrew.
class FindStage {
  const FindStage._();

  /// The room kept at the stage's two edges, in all.
  static const double edge = 13;

  /// The cells of [n] pictures, in the order of the options, inside [stage].
  static List<Rect> cells({
    required Size stage,
    required int n,
    required bool lookA,
    required bool firstAtRight,
  }) {
    final double gap = n == 3 && !lookA ? 24 : 32;
    final bool twoRows = n == 3 && stage.width < 300;
    final int top = twoRows ? 2 : n;
    final double side = math.max(
      0,
      twoRows
          ? math.min((stage.width - gap - edge) / 2, (stage.height - gap) / 2)
          : math.min((stage.width - gap * (n - 1) - edge) / n, stage.height),
    );
    final List<Rect> out = <Rect>[];
    final double rowsHeight = twoRows ? 2 * side + gap : side;
    final double y0 = (stage.height - rowsHeight) / 2;
    for (int i = 0; i < n; i++) {
      final int row = twoRows && i >= top ? 1 : 0;
      final int inRow = twoRows ? (row == 0 ? 2 : 1) : n;
      final int at = row == 0 ? i : i - top;
      final double total = inRow * side + (inRow - 1) * gap;
      final double x0 = (stage.width - total) / 2;
      final int slot = firstAtRight ? inRow - 1 - at : at;
      out.add(Rect.fromLTWH(x0 + slot * (side + gap), y0 + row * (side + gap), side, side));
    }
    return out;
  }
}
