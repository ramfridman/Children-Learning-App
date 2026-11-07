import 'dart:math' as math;

import 'package:flutter/painting.dart';

import 'ls01_metrics.dart';

// The bins of a sort and the kept chips in them (docs/design/languages-l5-ls01.md section 7.2). A card dropped in a bin stays there as a small
// chip, and every chip must stay in view and under a finger: the chips stand in rows from the start side, each row as tall as the room
// allows; only when even the smallest chip cannot have its own row do the rows overlap a little, so that none is ever lost.

/// Where the bins of a stage are and how much room each gives its sign, its speaker and its chips. One source for the session that draws
/// them and the fit check that tests them.
class BinGeometry {
  const BinGeometry({required this.room, required this.tablet, required this.bins});

  /// The room the stage gives the bins, how many bins, and whether the board is a tablet's (the stage is then a card).
  final Size room;
  final bool tablet;
  final int bins;

  /// The border (4) and the padding (2) of a bin, on each side.
  static const double chrome = 6;

  /// The room between the sign and the chips.
  static const double between = 2;

  double get padX => tablet ? 0 : 6;
  double get padY => tablet ? 0 : 2;
  double get gap => tablet ? 16 : 8;
  double get binWidth => (room.width - 2 * padX - (bins - 1) * gap) / bins;
  double get binHeight => room.height - 2 * padY;

  /// The sign is a pill this tall; a bin with a sound has a speaker at the end of the sign's row, in a box this wide (the disc is 44).
  double get signHeight => tablet ? 84 : 58;
  double get speakerTouch => tablet ? 56 : 52;
  double get speakerRoom => speakerTouch + 4;

  /// The widest a sign can be: the bin's inner width less the padding of the pill, and less the speaker when the bin has one.
  double signLimit({required bool speaker}) => binWidth - 2 * chrome - 12 - (speaker ? speakerRoom : 0);

  /// The room the chips of one bin have, under the sign, and how tall one chip is at most.
  Size get chipRoom => Size(binWidth - 2 * chrome, binHeight - 2 * chrome - signHeight - between);
  double get chipMax => tablet ? 56 : 44;

  /// Where bin [slot] stands (counted from the left of the room), as a rectangle in the room's own coordinates.
  Rect binRect(int slot) => Rect.fromLTWH(padX + slot * (binWidth + gap), padY, binWidth, binHeight);
}

/// How wide a kept chip is: its text at the kept size and 6 either side (never narrower than the smallest chip), or a square for a picture or
/// a sound.
double keptChipWidth(Ls01Metrics m, String? text, {required double square}) =>
    text == null ? square : math.max(ChipPlan.minHeight, m.textWidth(text, FaceKind.kept) + 12);

/// Where the chips of one bin stand: an offset from the start side of the chips' room and from its top, and how tall each is.
class ChipPlan {
  const ChipPlan({required this.offsets, required this.height, required this.overlaps});

  /// The smallest a chip is drawn: its text at the kept size on one line.
  static const double minHeight = 28;
  static const double gap = 3;

  final List<Offset> offsets;
  final double height;

  /// The rows are closer than a chip is tall (there was no room for a row each): the later chip covers the lower part of the one above.
  final bool overlaps;

  /// Rows from the start side: a chip goes in the first row with room, never split. A row is as tall as the room allows (at most
  /// [maxHeight], at least [minHeight]); more rows than that room holds overlap, each only as much as it must.
  static ChipPlan of(
    List<double> widths, {
    required double width,
    required double height,
    required double maxHeight,
  }) {
    if (widths.isEmpty) return const ChipPlan(offsets: <Offset>[], height: 0, overlaps: false);
    final List<int> rowOf = <int>[];
    final List<double> xOf = <double>[];
    double used = 0;
    int row = 0;
    for (final double raw in widths) {
      final double w = math.min(raw, width);
      if (used > 0 && used + gap + w > width + 0.01) {
        row++;
        used = 0;
      }
      rowOf.add(row);
      xOf.add(used > 0 ? used + gap : 0);
      used = (used > 0 ? used + gap : 0) + w;
    }
    final int rows = row + 1;
    final double fair = (height - (rows - 1) * gap) / rows;
    final bool overlaps = fair < minHeight;
    final double chip = overlaps ? minHeight : math.min(maxHeight, fair);
    final double step = overlaps ? (rows > 1 ? (height - chip) / (rows - 1) : 0) : chip + gap;
    return ChipPlan(
      offsets: <Offset>[for (int i = 0; i < widths.length; i++) Offset(xOf[i], rowOf[i] * step)],
      height: chip,
      overlaps: overlaps,
    );
  }
}
