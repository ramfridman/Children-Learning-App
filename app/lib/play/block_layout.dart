import 'dart:math' as math;

import 'package:flutter/painting.dart';

import '../child/activity_shell.dart';
import '../content/models.dart';
import '../design/token_types.dart' show Band;
import '../design/tokens.g.dart';
import 'activity_frame.dart' show ActivityFrame;
import 'hints/tap_geometry.dart';
import 'stage_pictures.dart';

// The two layouts of an item that has blocks (docs/design/c1-blocks.md section 5), as board numbers: the owner chose them on 2026-11-07 from
// mockups drawn at one pixel to a point. The cube of an item is never under 12 points (`BaseTenLayout.floorUnit`): the numbers here are what
// keeps it so, and `unitOf` is how a test and the pack check ask for the cube an item gets on a board.
//
//   Layout S, blocks on the stage and numerals on the tiles (how many, a lit rod, crossed rods, a comparison): the stage has all the
//   height between the top bar and the tile row, and the tile row stands as low as the bottom band lets it.
//   Layout T, blocks on the tiles and nothing on the stage (which one is 34?): the tiles take the stage's height, from under the guide's
//   bubble to the bottom line, as tall as their blocks need.
abstract final class BlockLayout {
  /// The tile row's bottom: the board's height less the band where no hotspot may be and the touch margin of Band C.
  static double bottomLine(ActivitySpec s) =>
      s.boardHeight - TokenTouch.bottomNoHotspot - TokenTouch.band[Band.c]!.hitSlop;

  /// The room between the stage and the numeral tiles under it, in Layout S.
  static const double stageGap = 12;

  /// Blocks on the stage with numerals on the tiles (Layout S).
  static bool onStage(TapAnswerActivity a) =>
      a.optionsInTiles && a.numberAnswer == null && TapGeometry.stagePictureOf(a) == 'base_ten';

  /// Blocks on the tiles and nothing of the question on the stage (Layout T).
  static bool onTiles(TapAnswerActivity a) =>
      a.optionsInTiles &&
      a.numberAnswer == null &&
      a.picture == null &&
      a.group == null &&
      a.row.isEmpty &&
      a.options.any((ChoiceOption o) => o.picture != null);

  /// Whether a picture of [a] has a rod (a ten): what the demonstration that a rod is ten cubes is for.
  static bool hasRods(TapAnswerActivity a) =>
      hasBlocks(a) &&
      <Map<String, Object?>?>[
        a.picture,
        a.picture2,
        for (final ChoiceOption o in a.options) o.picture,
      ].any((Map<String, Object?>? p) => p != null && BaseTen.fromScene(p).tens > 0);

  /// Whether [a] has blocks on its stage or on its tiles.
  static bool hasBlocks(TapAnswerActivity a) => onStage(a) || onTiles(a);

  /// The board [base] as [a] lays it out: S or T, or [base] itself for an item without blocks.
  static ActivitySpec of(TapAnswerActivity a, ActivitySpec base) => onStage(a)
      ? forStage(base)
      : onTiles(a)
      ? _tiles(a, base)
      : base;

  // Layout S. On a phone the stage grows to the top bar's height above it and to 12 above the tiles, which move down to the bottom line
  // (phone: stage 330 by 165 at y 88, tiles at 265; SE: 270 by 155 at y 80, tiles at 247). A tablet keeps its card.
  static ActivitySpec forStage(ActivitySpec base) {
    final double? top = base.blocksStageTop;
    if (top == null) return base;
    final double tiles = bottomLine(base) - 96;
    return base.withStageAndTiles(
      stage: Rect.fromLTWH(base.stage.left, top, base.stage.width, tiles - stageGap - top),
      tilesLeft: base.tilesLeft,
      tilesTop: tiles,
      tilesWidth: base.tilesWidth,
    );
  }

  // Layout T. The tiles are as tall as their blocks need (a cube of the item's size, ten of them, and the room round them), all alike;
  // on a phone they stand on the bottom line, on a tablet they are centred in the room of the card. The bubble stands at the old stage's
  // top line, and the tiles begin where it ends, with the frame's clearance; what a hint draws (a card of blocks) keeps the room left of
  // the bubble, over the tiles' top, and is not drawn on a card.
  static ActivitySpec _tiles(TapAnswerActivity a, ActivitySpec base) {
    final double bubbleTop = base.blocksBubbleTop ?? base.bubbleTop;
    final bool card = base.stageIsCard;
    final double bottom = bottomLine(base);
    final double? bubbleWidth = card ? null : _bubbleWidth(a.promptLine.caption, base);
    final ActivitySpec raised = base.withStageAndTiles(
      stage: base.stage,
      tilesLeft: base.tilesLeft,
      tilesTop: base.tilesTop,
      tilesWidth: base.tilesWidth,
      bubbleTop: bubbleTop,
      bubbleWidth: bubbleWidth,
    );
    final double top = card
        ? base.stage.top
        : bubbleTop + ActivityFrame.fitBubble(a.promptLine.caption, raised).height + ActivityFrame.tileClear;
    final double edge = BaseTenLayout.tileEdge;
    final List<BaseTen> pictures = <BaseTen>[
      for (final ChoiceOption o in a.options)
        if (o.picture != null) BaseTen.fromScene(o.picture!),
    ];
    final Size room = Size(TapGeometry.tileWidthOf(a, base) - 2 * edge, bottom - top - 2 * edge);
    final double unit = BaseTenLayout.commonUnit(<(BaseTen, Size)>[
      for (final BaseTen p in pictures) (p, room),
    ], maxUnit: BaseTenLayout.unitCap(tablet: card))!;
    final double tall = pictures.map((BaseTen p) => BaseTenLayout.roomOf(p).height).reduce(math.max);
    final double height = math.min(bottom - top, tall * unit + 2 * edge);
    final double tilesTop = card ? top + (bottom - top - height) / 2 : bottom - height;
    // On a tablet the tiles stand in the middle of the card's room and the box for a hint's card is all that is left above them, from under
    // the bubble.
    final double stageTop = card
        ? base.bubbleTop + ActivityFrame.fitBubble(a.promptLine.caption, raised).height + 12
        : bubbleTop;
    // What a hint draws keeps the room left of the bubble (a phone) or over the tiles (a tablet).
    final double stageWidth = card
        ? base.stage.width
        : math.min(
            base.stage.width,
            (bubbleWidth == null ? base.bubbleLeft! : base.blocksBubbleEdge! - bubbleWidth) -
                12 -
                base.stage.left,
          );
    return raised.withStageAndTiles(
      stage: Rect.fromLTWH(
        base.stage.left,
        stageTop,
        stageWidth,
        math.max(card ? 48 : 0, tilesTop - ActivityFrame.tileClear - stageTop),
      ),
      tilesLeft: base.tilesLeft,
      tilesTop: tilesTop,
      tilesWidth: base.tilesWidth,
      tileHeight: height,
      stageDrawn: false,
    );
  }

  /// The width a phone's bubble needs for [text] to fit two lines at the band's size (it stays the board's own when it already does),
  /// held by its right edge beside the guide, so it grows to the left, into the room the empty stage leaves. Null when the board's own
  /// width is enough, or when the room runs out before two lines fit (the item then has a taller bubble, and the check says so).
  static double? _bubbleWidth(String text, ActivitySpec base) {
    final double twoLines = ActivityFrame.bubbleHeight('x\nx', base.bubbleFont, 1000);
    bool fits(double width) => ActivityFrame.bubbleHeight(text, base.bubbleFont, width) <= twoLines + 1;
    if (fits(base.bubbleMaxWidth)) return null;
    final double widest = base.blocksBubbleEdge! - (base.stage.left + minHintRoom);
    for (double w = base.bubbleMaxWidth + 4; w <= widest; w += 4) {
      if (fits(w)) return w;
    }
    return widest;
  }

  /// The least room a hint's card keeps beside a widened bubble.
  static const double minHintRoom = 150;

  /// The side of one cube that item [a] is drawn with on the board [base], or null when it has no blocks: the largest that fits every
  /// picture of the item (the stage's, or the tiles') in its box, at most the board's cap. The stage and the tiles draw with this one.
  static double? unitOf(TapAnswerActivity a, ActivitySpec base) {
    if (!hasBlocks(a)) return null;
    final ActivitySpec s = of(a, base);
    if (onTiles(a)) return TapGeometry.blockUnitOf(a, s);
    final Size room = s.stageIsCard ? Size(s.stage.width - 32, s.stage.height - 32) : s.stage.size;
    final Size area = Size(room.width, TapGeometry.pictureHeightOf(a, room.height));
    final List<Rect> cells = TapGeometry.blockCells(a, area);
    final List<Map<String, Object?>> pictures = <Map<String, Object?>>[a.picture!, ?a.picture2];
    return BaseTenLayout.commonUnit(<(BaseTen, Size)>[
      for (int i = 0; i < pictures.length; i++) (BaseTen.fromScene(pictures[i]), cells[i].size),
    ], maxUnit: BaseTenLayout.unitCap(tablet: s.stageIsCard));
  }
}
