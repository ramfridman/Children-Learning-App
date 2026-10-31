import 'package:flutter/painting.dart';

import '../../child/activity_shell.dart';

// Where a template's answer tiles stand, in the stage's own points ((0, 0) is the stage's top left corner), so that the pointing
// hand's fingertip can end on the top edge of a tile (design spec 2.1) and a line can reach a card below the stage. The tiles are
// laid out by the sessions (a centred row of tiles with a tap margin all round); these numbers are the same ones.

extension TilePoints on ActivitySpec {
  /// The stage's own top left corner on the board: a tablet's stage is a card, and the stage inside it is 16 in.
  Offset get stageOrigin {
    final double inset = stageIsCard ? 16 : 0;
    return Offset(stage.left + inset, stage.top + inset);
  }

  /// A point of the tiles' box in the stage's own points. The box starts 12 above the tiles' top and [x] is from its left edge.
  Offset fromTiles(double x, double y) => Offset(tilesLeft + x, tilesTop - 12 + y) - stageOrigin;

  /// The places of a centred row of [n] tiles, each [slot] wide (the tile and its tap margins), as the distances of their middles
  /// from the left edge of the tiles' box. A right-to-left row (the language's) puts the first tile at the right.
  List<double> rowCentres(int n, double slot, {bool rtl = true}) {
    final double start = (tilesWidth - n * slot) / 2;
    return <double>[
      for (int i = 0; i < n; i++) rtl ? tilesWidth - start - (i + 0.5) * slot : start + (i + 0.5) * slot,
    ];
  }

  /// The fingertip place on the top edge of tile [i] of a row of [n] tiles of [slot] width whose tap margin is [slop]: the tile's
  /// top is [slop] under the box's top.
  Offset tileTip(int n, int i, {required double slot, required double slop, bool rtl = true}) =>
      fromTiles(rowCentres(n, slot, rtl: rtl)[i], slop);
}
