import 'dart:math' as math;

import 'package:flutter/painting.dart';

import '../content/scripts.dart' show isSingleLetter;
import 'ls01_metrics.dart';

// The bins of a sort and the kept chips in them (docs/design/languages-l5-ls01.md section 7.2). A card dropped in a bin stays there as a small
// chip, and every chip must stay in view and under a finger: the chips stand in rows from the start side, each row as tall as the room
// allows; only when even the smallest chip cannot have its own row do the rows overlap a little, so that none is ever lost.

/// Where the bins of a stage are and how much room each gives its sign, its speaker and its chips. One source for the session that draws
/// them and the fit check that tests them.
class BinGeometry {
  const BinGeometry({required this.room, required this.tablet, required this.bins, this.bigSpeakers = false});

  /// The speakers are 64 points wherever a bin is: Band A, where a child control is never less, and the cards are pictures or single letters
  /// (see [bigSpeakersFor]).
  final bool bigSpeakers;

  /// Whether a sort's bins have 64 speakers in every bin: it is Band A's and none of its cards is a word (a Band A card is a picture or a
  /// letter; a word is wider than the room a corner speaker leaves the chips).
  static bool bigSpeakersFor({required bool bandA, required Iterable<String?> cardTexts}) =>
      bandA && cardTexts.every((String? t) => t == null || isSingleLetter(t));

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
  /// The speaker is a child control: 64, the Band A floor (QA-BA-6, design-spec 6.1), in every bin of Band A and wherever a bin is at least
  /// 150 wide (the tablets, and the phone's two bins of 178), where it stands at the end of the sign's row, the phone's pill then as tall as
  /// it so that the row keeps the pill's height. In a narrower bin (the phone SE's two of 121, or three bins) beside a 64 the sign would have
  /// 29 points: in Band A the speaker leaves the sign's row and stands in the end corner under it, [cornerMargin] from the bin's inner
  /// edges, and the sign has the whole row (docs/design/languages-band-a-qa.md section 4.2). Bands B and C keep 52 beside the sign there: a
  /// text chip would not fit the room a corner speaker leaves (the cards of Band A are pictures and single letters).
  bool get _roomy => tablet || binWidth >= 150;
  bool get cornerSpeaker => bigSpeakers && !_roomy;
  double get signHeight => tablet ? 84 : (_roomy ? 64 : 58);
  double get speakerTouch => (_roomy || bigSpeakers) ? 64 : 52;
  double get speakerRoom => speakerTouch + 4;

  /// How far a corner speaker stands from the bin's inner edges (the end and the bottom).
  static const double cornerMargin = 6;

  /// The end side of the chips' room that a corner speaker keeps free, as wide as the speaker and its margin.
  double get cornerRoom => speakerTouch + cornerMargin;

  /// The widest a sign can be: the bin's inner width less the padding of the pill, and less the speaker when the bin has one beside the
  /// sign (a corner speaker is under it).
  double signLimit({required bool speaker}) =>
      binWidth - 2 * chrome - 12 - (speaker && !cornerSpeaker ? speakerRoom : 0);

  /// The room the chips of one bin have, under the sign, and how tall one chip is at most.
  Size get chipRoom => Size(binWidth - 2 * chrome, binHeight - 2 * chrome - signHeight - between);

  /// The room the chips of a bin have when the bin [speaker]s: a corner speaker keeps the end side of the room free, so a chip never stands
  /// under it.
  Size chipRoomFor({required bool speaker}) =>
      speaker && cornerSpeaker ? Size(chipRoom.width - cornerRoom, chipRoom.height) : chipRoom;
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
