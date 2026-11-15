import 'dart:ui';

import '../child/activity_shell.dart';
import '../design/board.dart';

/// Where the host and the companion stand in a host beat (docs/design/m11-rooms.md section 2.2), in board points. The host stands in front,
/// where the guide stands; the companion half a step behind it, on the outer side, smaller. Both stand on one ground line.
class HostPlaces {
  const HostPlaces({required this.front, required this.back, required this.bubbleMaxWidth, this.bubbleRight});

  /// The host's box (the square the picture is drawn in) and the companion's box in the back place.
  final Rect front;
  final Rect back;

  /// The bubble in a host beat: its widest, and (on the boards that place the bubble by its right edge) the distance from the board's right edge.
  final double bubbleMaxWidth;
  final double? bubbleRight;

  static const HostPlaces phone = HostPlaces(
    front: Rect.fromLTWH(597, 88, 168, 168),
    back: Rect.fromLTWH(697, 158, 96, 96),
    bubbleMaxWidth: 178,
  );
  static const HostPlaces phoneSE = HostPlaces(
    front: Rect.fromLTWH(478, 74, 144, 144),
    back: Rect.fromLTWH(565, 128, 86, 86),
    bubbleMaxWidth: 170,
  );
  static const HostPlaces tabletLandscape = HostPlaces(
    front: Rect.fromLTWH(872, 150, 260, 260),
    back: Rect.fromLTWH(1004, 250, 152, 152),
    bubbleMaxWidth: 600,
    bubbleRight: 248,
  );
  static const HostPlaces tabletPortrait = HostPlaces(
    front: Rect.fromLTWH(572, 128, 184, 184),
    back: Rect.fromLTWH(680, 190, 116, 116),
    bubbleMaxWidth: 410,
    bubbleRight: 254,
  );

  static HostPlaces of(BoardClass b) => switch (b) {
    BoardClass.phone => phone,
    BoardClass.phoneSE => phoneSE,
    BoardClass.tabletLandscape => tabletLandscape,
    BoardClass.tabletPortrait => tabletPortrait,
  };
}

extension HostBeatSpec on ActivitySpec {
  /// The same board for a host beat: the bubble is narrower (and on a tablet stands a little further from the corner) so that the pair fits the
  /// corner. Nothing else of the frame moves. A phone's bubble keeps its left edge and a tablet's its top and font, so only the width and the
  /// right edge change.
  ActivitySpec forHostBeat(HostPlaces p) => ActivitySpec(
    boardHeight: boardHeight,
    bubbleMaxWidth: p.bubbleMaxWidth,
    bubbleMaxHeight: bubbleMaxHeight,
    homeRight: homeRight,
    controlsTop: controlsTop,
    eyeLeft: eyeLeft,
    hintLeft: hintLeft,
    trailLeft: trailLeft,
    trailTop: trailTop,
    trailWidth: trailWidth,
    nitziLeft: nitziLeft,
    nitziTop: nitziTop,
    nitziSize: nitziSize,
    micLeft: micLeft,
    micTop: micTop,
    micSize: micSize,
    bubbleLeft: bubbleLeft,
    bubbleRight: bubbleLeft == null ? (p.bubbleRight ?? bubbleRight) : bubbleRight,
    bubbleTop: bubbleTop,
    bubbleFont: bubbleFont,
    stage: stage,
    stageIsCard: stageIsCard,
    tilesLeft: tilesLeft,
    tilesTop: tilesTop,
    tilesWidth: tilesWidth,
    tileFont: tileFont,
    tileHeight: tileHeight,
    tileSize: tileSize,
    tileSlop: tileSlop,
    stageDrawn: stageDrawn,
    blocksStageTop: blocksStageTop,
    blocksBubbleTop: blocksBubbleTop,
    blocksBubbleEdge: blocksBubbleEdge,
    blocksBubbleRight: blocksBubbleRight,
    tailAtMouth: tailAtMouth,
  );
}
