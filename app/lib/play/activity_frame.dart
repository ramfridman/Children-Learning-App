import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../child/activity_shell.dart';
import '../design/app_text.dart';
import '../design/board.dart';
import '../design/components.dart';
import '../design/course_text.dart';
import '../design/layout.dart';
import '../design/stage_spec.dart';
import '../design/tokens.g.dart';
import '../rewards/sticker_design.dart';
import '../strings/he.dart';
import 'math_run.dart';
import 'math_signs.dart';

/// The frame of a playable activity: the same positions as the boards (the [ActivitySpec] numbers),
/// with the real question in the bubble, the template's stage, its answer tiles, the progress trail,
/// and the child's own controls: home, the hint lamp, "show me", and the guide, who repeats the
/// question when touched.
class ActivityFrame extends StatelessWidget {
  const ActivityFrame({
    super.key,
    required this.bubbleText,
    required this.stage,
    required this.trailTotal,
    required this.trailDone,
    this.spec,
    required this.onHome,
    this.tiles,
    this.hands,
    this.onHint,
    this.hintGlow = false,
    this.onShowMe,
    this.onReplay,
    this.overlay,
    this.guide,
    this.mic,
    this.onConfirmYes,
    this.onConfirmAgain,
    this.bubbleTarget,
    this.bubbleMath,
    this.bubbleAboveTiles = false,
    this.showHelp = true,
    this.boardLayer,
    this.promptRing = false,
    this.idleHand,
  });

  /// The idle prompt's first step rings the place the question is said from (the speaker bubble, or the caption bubble) once, in the sky
  /// colour, and (B-29 D5) the hand of the idle prompt points into the stage: a layer over the stage that takes no touch, or null.
  final bool promptRing;
  final Widget Function(Size room)? idleHand;

  /// Something a template draws in the board's own points, outside its stage (the close-up card of a command): a `Positioned` for the
  /// board's stack. Drawn after the stage and the answer tiles, under the guide's hand and the controls.
  final Widget? boardLayer;

  /// The hint lamp and "show me" are drawn. Off for a probe of the placement game, which has no help at all (docs/languages/frame.md
  /// section 3.2): the two buttons are not there, not merely dimmed.
  final bool showHelp;

  /// The board numbers to lay out on, when the template's are not the board's own (see `TemplateSession.layoutFor`).
  final ActivitySpec? spec;

  /// What the guide says now.
  final String bubbleText;

  /// A target word on show with the line: it stands in a [TargetChip] on a row of its own under the line, never inside it
  /// (fonts.md section 6), in the teaching font of its [course].
  final ({String text, String course})? bubbleTarget;

  /// The number sentence of the question (the tokens of a row), shown in numbers under the line as one left-to-right run (`MathRun`); null
  /// when the question has none. Its room is taken off the line's, so the bubble keeps clear of the tiles all the same.
  final List<String>? bubbleMath;

  /// The bubble keeps clear of the tiles under it: its text shrinks to the room and, when it must, it stands higher. Always so when the
  /// frame has answer tiles (a hint's longer line must never lie over one, in any land); this switch is for a bubble over something
  /// else, and for the items of a language course.
  final bool bubbleAboveTiles;

  /// How far above the top of the drawn tiles the bubble ends, so that it keeps clear of a tile and of the shadow it casts (the tiles'
  /// box, with its 12 point tap margin, starts 12 higher).
  static const double tileClear = 16;

  /// Builds the stage for the room it has (its width and height, in board points).
  final Widget Function(Size room) stage;
  final Widget? tiles;

  /// The layer of the hint's pointing hand over the stage, drawn above the stage, the bubble, the guide and the answer tiles; null when there is none.
  final Widget Function(Size room)? hands;
  final int trailTotal;
  final int trailDone;
  final VoidCallback onHome;
  final VoidCallback? onHint;

  /// True when help is on offer (after a mistake): the lamp is washed with the hint colour.
  final bool hintGlow;
  final VoidCallback? onShowMe;
  final VoidCallback? onReplay;

  /// Drawn over everything (the celebration).
  final Widget? overlay;

  /// The character that teaches (a live character view), drawn where the board puts the guide. Touching it
  /// asks for the question again.
  final Widget? guide;

  /// The microphone button (a [MicButton] of the size of the board), or null when voice is off for this child.
  final Widget? mic;

  /// While the guide asks "did you say ...?": the tick (yes) and the "again" button next to the microphone.
  final VoidCallback? onConfirmYes;
  final VoidCallback? onConfirmAgain;

  /// The most the system's text size may scale the bubble's line: parents who share the phone may need larger text, and the board has the
  /// room for this much (the bubble stands higher or wider and the line shrinks to fit, never over a tile).
  static const double maxTextScale = 1.3;

  /// The text scaler the bubble of the lesson measures and draws with: the system's, up to [maxTextScale].
  static TextScaler bubbleScaler(BuildContext context) =>
      MediaQuery.textScalerOf(context).clamp(maxScaleFactor: maxTextScale);

  /// How tall the bubble of [text] at [font] is when it wraps inside [maxWidth] (its padding included), drawn with [scaler].
  static double bubbleHeight(
    String text,
    double font,
    double maxWidth, {
    TextScaler scaler = TextScaler.noScaling,
  }) {
    const EdgeInsets pad = EdgeInsets.symmetric(horizontal: 16, vertical: 8);
    final TextPainter p = TextPainter(
      text: TextSpan(
        text: text,
        style: AppText.fixed(size: font, weight: 500),
      ),
      textDirection: TextDirection.rtl,
      textScaler: scaler,
    )..layout(maxWidth: maxWidth - pad.horizontal);
    final double height = p.height + pad.vertical;
    p.dispose();
    return height;
  }

  /// The least room a phone's stage keeps beside a bubble that widens to the left (the same as the hint card's in `BlockLayout`).
  static const double minStageRoom = 150;

  /// The smallest the font ever goes, in points as drawn: the last resort when a line still does not fit its widest bubble at [fitBubble]'s
  /// own minimum. A line this long is a defect of the content (the audit of every land names it); the bubble still keeps clear of the tiles.
  static const double hardMinFont = 11;

  /// The largest font, down to [min] points as drawn (with [scaler], so a font of 14 / 1.3 is drawn at 14), at which [text] (and
  /// [reserve], the room of a chip under it) fits in [maxHeight] (the board's own limit when null), and the height of the bubble at that
  /// font. The font is the nominal one: the bubble draws it through [scaler].
  ///
  /// The board's limit is a wish, the [room] (the space between the trail and the tiles; [maxHeight] when null) is a wall: a line that is
  /// taller than the limit at [min] but fits the room stays as it is, at [min] and the board's width. A line that does not fit the room at
  /// [min] widens the bubble, [widest] at most (a width; the bubble grows to the side away from the guide), and only if the widest bubble
  /// is still too short does the font go on down to [hardMinFont]. The width is the board's own when [widest] is null (and then the font
  /// stops at [min]) or not wider. [ActivityFrame.build] gives the room it has.
  static ({double font, double height, double width}) fitBubble(
    String text,
    ActivitySpec s, {
    double min = 14,
    double reserve = 0,
    double? maxHeight,
    double? room,
    double? widest,
    TextScaler scaler = TextScaler.noScaling,
  }) {
    final double factor = scaler.scale(1);
    final double limit = maxHeight ?? s.bubbleMaxHeight;
    final double wall = room ?? limit;
    final double wide = math.max(s.bubbleMaxWidth, widest ?? 0);
    double heightAt(double size, double width) => bubbleHeight(text, size, width, scaler: scaler) + reserve;
    for (double size = s.bubbleFont; size * factor > min; size -= 1) {
      final double height = heightAt(size, s.bubbleMaxWidth);
      if (height <= limit) return (font: size, height: height, width: s.bubbleMaxWidth);
    }
    final double floor = min / factor;
    for (double width = s.bubbleMaxWidth; width <= wide; width += 4) {
      final double height = heightAt(floor, width);
      if (height <= wall) return (font: floor, height: height, width: width);
    }
    // Without a room to widen the caller only measures (the layout of a block item): the line stays at the floor.
    if (widest == null) {
      return (font: floor, height: heightAt(floor, s.bubbleMaxWidth), width: s.bubbleMaxWidth);
    }
    for (double size = floor - 1; size * factor >= hardMinFont; size -= 1) {
      final double height = heightAt(size, wide);
      if (height <= wall) return (font: size, height: height, width: wide);
    }
    final double last = hardMinFont / factor;
    return (font: last, height: heightAt(last, wide), width: wide);
  }

  @override
  Widget build(BuildContext context) {
    final BoardClass board = AppLayout.of(context).board;
    final ActivitySpec s = spec ?? ActivitySpec.of(board);
    final StageScope? look = StageScope.maybeOf(context);
    final SizeClass sizeClass = AppLayout.of(context).sizeClass;
    // With captions hidden (B-29 D2) the Hebrew words of the question are not drawn: a speaker stands in their place. A number sentence or a
    // target word of the question, and every numeral on a tile, still show.
    final bool wordless = look != null && !look.captionsShown && overlay == null && bubbleText.isNotEmpty;
    // The chip's word is a tenth larger than the Hebrew beside it (fonts.md section 6); its room is taken off the line's.
    final double chipSize = s.bubbleFont * 1.1;
    final TextScaler scaler = bubbleScaler(context);
    final ({String text, String course})? target = bubbleTarget;
    final List<String>? run = bubbleMath;
    // The number sentence has a row of its own under the line, and its room is added to the board's limit for the bubble: the line keeps the
    // room it has without one (the band's size on three lines), and the bubble stands higher by the run's row.
    final double mathRoom = run == null ? 0 : MathRun.reserveFor(scaler.scale(s.bubbleFont));
    // The bubble keeps clear of the tiles under it: its text shrinks to the room there is between the progress trail and the tiles
    // (never below the minimum), and a bubble that is still too tall (a long line with a chip) stands higher, not over the tiles.
    final double floorTop = s.trailTop + 36 + 4;
    final bool clear = (bubbleAboveTiles || target != null || tiles != null) && s.tilesTop > s.bubbleTop;
    final double ceiling = clear ? s.tilesTop - tileClear : double.infinity;
    // Where the bubble ends on its right (the guide's side), and how far to the left it may widen when its line does not fit at the
    // smallest size: a tablet to its stage's card, a phone to leave the stage the room of a hint's drawing.
    final double rightEdge = s.bubbleLeft != null
        ? s.bubbleLeft! + s.bubbleMaxWidth
        : board.size.width - (s.bubbleRight ?? 0);
    // A tall stage (the wheel, a close-up) holds its picture across its whole width, so a bubble never widens into it; a short one keeps 150.
    final double keep = !s.tailAtMouth && s.stage.height > 180 ? s.stage.width : minStageRoom;
    final double? widest = clear ? rightEdge - s.stage.left - (s.stageIsCard ? 0 : keep) : null;
    final ({double font, double height, double width}) fit = fitBubble(
      bubbleText,
      s,
      reserve: (target == null ? 0 : 6 + TargetChip.heightFor(chipSize)) + mathRoom,
      maxHeight: math.min(s.bubbleMaxHeight + mathRoom, ceiling - floorTop),
      room: ceiling - floorTop,
      widest: widest,
      scaler: scaler,
      // The caption keeps its stage's size down to two points under it, drawn; only then does the bubble widen (B-29 D1).
      // (A layout whose tail must meet the guide's mouth wherever the bubble stands, the blocks', keeps the old floor of 14.)
      min: look == null || s.tailAtMouth ? 14 : look.stage.captionFloor(sizeClass),
    );
    final double font = fit.font;
    final double bubbleTop = clear
        ? math.max(floorTop, math.min(s.bubbleTop, ceiling - fit.height))
        : s.bubbleTop;
    final Size room = s.stageIsCard ? Size(s.stage.width - 32, s.stage.height - 32) : s.stage.size;
    return Scaffold(
      body: BoardCanvas(
        background: TokenColors.cream,
        board: board,
        children: <Widget>[
          if (mic != null) Positioned(left: s.micLeft, top: s.micTop, child: mic!),
          if (mic != null && onConfirmYes != null && onConfirmAgain != null) ..._confirmButtons(board, s),
          _stage(s, room),
          // The bubble and the guide are drawn after the stage, so a hint's hand that reaches over the stage's edge goes under
          // them (the bubble first, so that the guide stands in front of its tail).
          // The celebration says its own line; the bubble stays quiet behind it.
          if (wordless)
            Positioned(
              right: s.bubbleLeft == null
                  ? s.bubbleRight
                  : board.size.width - (s.bubbleLeft! + s.bubbleMaxWidth),
              top: s.bubbleTop,
              child: Semantics(
                button: true,
                label: He.replaySemantics.text,
                child: GestureDetector(
                  key: const Key('lesson-speaker-bubble'),
                  behavior: HitTestBehavior.opaque,
                  onTap: onReplay,
                  child: SpeakerBubble(
                    size: look.stage.speaker(sizeClass),
                    ring: promptRing,
                    chip: target == null
                        ? null
                        : TargetChip(target.text, course: target.course, size: chipSize),
                    math: run == null
                        ? null
                        : MathRun(run, size: scaler.scale(s.bubbleFont), division: MathSigns.of(context)),
                    pointerAt: s.tailAtMouth ? (s.mouthY - s.bubbleTop).clamp(24.0, 200.0) : null,
                  ),
                ),
              ),
            )
          else if (overlay == null && bubbleText.isNotEmpty) ...<Widget>[
            if (promptRing)
              Positioned(
                left: s.bubbleLeft == null ? null : s.bubbleLeft! - (fit.width - s.bubbleMaxWidth) - 6,
                right: s.bubbleLeft == null ? (s.bubbleRight ?? 0) - 6 : null,
                top: bubbleTop - 6,
                width: fit.width + 12,
                height: fit.height + 12,
                child: IgnorePointer(
                  child: DecoratedBox(
                    key: const Key('bubble-ring'),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(TokenRadius.lg + 6),
                      border: Border.all(color: TokenColors.sky, width: 4),
                    ),
                  ),
                ),
              ),
            Positioned(
              // A bubble held by its left edge keeps its right edge (the guide's side) when it widens.
              left: s.bubbleLeft == null ? null : s.bubbleLeft! - (fit.width - s.bubbleMaxWidth),
              right: s.bubbleRight,
              top: bubbleTop,
              child: BoardBubble(
                key: const Key('lesson-bubble'),
                text: bubbleText,
                fontSize: font,
                // Measured and drawn with the same scaler (the system's, up to 1.3), so the room worked out for the line is the room it takes.
                textScaler: scaler,
                maxWidth: fit.width,
                chip: target == null ? null : TargetChip(target.text, course: target.course, size: chipSize),
                math: run == null
                    ? null
                    : MathRun(run, size: scaler.scale(s.bubbleFont), division: MathSigns.of(context)),
                // A bubble that stands off its board's place points at the guide's mouth: the tail meets it from the top.
                pointerAt: s.tailAtMouth
                    ? (s.mouthY - bubbleTop).clamp(24.0, math.max(24.0, fit.height - 24))
                    : null,
              ),
            ),
          ],
          Positioned(
            left: s.nitziLeft,
            top: s.nitziTop,
            width: s.nitziSize,
            height: s.nitziSize,
            child: Semantics(
              button: true,
              label: He.replaySemantics.text,
              child: GestureDetector(
                key: const Key('lesson-replay'),
                behavior: HitTestBehavior.opaque,
                onTap: onReplay,
                child: SizedBox(key: const Key('activity-nitzi'), child: guide),
              ),
            ),
          ),
          if (tiles != null)
            // The row starts the tile's slop above where the tiles are drawn.
            Positioned(left: s.tilesLeft, top: s.tilesTop - s.tileSlop, width: s.tilesWidth, child: tiles!),
          ?boardLayer,
          if (idleHand != null) _idleHandLayer(s, room),
          // The hand is drawn after the answer tiles (and the stage, the bubble and the guide), so it is never behind what it points at.
          if (hands != null) _handLayer(s, room),
          Positioned(
            left: s.trailLeft,
            top: s.trailTop,
            width: s.trailWidth,
            child: Center(
              child: ProgressTrail(total: trailTotal, done: trailDone),
            ),
          ),
          boardAt(
            right: s.homeRight,
            top: s.controlsTop,
            child: PebbleButton(
              key: const Key('activity-home'),
              semanticLabel: He.homeSemantics.text,
              onPressed: onHome,
              child: const BoardSvg('assets/art/ui/home_palm.svg', width: 32, height: 32),
            ),
          ),
          if (showHelp)
            boardAt(
              left: s.hintLeft,
              top: s.controlsTop,
              child: PebbleButton(
                key: const Key('lesson-hint'),
                semanticLabel: He.hintSemantics.text,
                fill: hintGlow ? TokenColors.skyTint : TokenColors.paper,
                lip: hintGlow ? TokenColors.hintHalo : TokenColors.cardLip,
                onPressed: onHint,
                child: const BoardSvg('assets/art/ui/hint.svg', width: 32, height: 32),
              ),
            ),
          if (showHelp)
            boardAt(
              left: s.eyeLeft,
              top: s.controlsTop,
              child: PebbleButton(
                key: const Key('lesson-show-me'),
                semanticLabel: He.showMeSemantics.text,
                onPressed: onShowMe,
                child: const BoardSvg('assets/art/ui/eye.svg', width: 32, height: 32),
              ),
            ),
          ?overlay,
        ],
      ),
    );
  }

  /// The tick and the "again" button of "did you say ...?", beside the microphone (below it on the tall tablet).
  List<Widget> _confirmButtons(BoardClass board, ActivitySpec s) {
    const double d = 56;
    final bool below = board == BoardClass.tabletPortrait;
    final double top = below ? s.micTop + s.micSize + 12 : s.micTop + (s.micSize - d) / 2;
    final double yesLeft = below ? s.micLeft : s.micLeft - 12 - d;
    final double againLeft = below ? s.micLeft + d + 12 : s.micLeft + s.micSize + 12;
    return <Widget>[
      Positioned(
        left: yesLeft,
        top: top,
        child: PebbleButton(
          key: const Key('confirm-yes'),
          size: d,
          semanticLabel: He.confirmYesSemantics.text,
          fill: TokenColors.sparkTint,
          lip: TokenColors.sparkDeep,
          onPressed: onConfirmYes,
          child: const Icon(Icons.check_rounded, color: TokenColors.ink, size: 32),
        ),
      ),
      Positioned(
        left: againLeft,
        top: top,
        child: PebbleButton(
          key: const Key('confirm-again'),
          size: d,
          semanticLabel: He.confirmAgainSemantics.text,
          onPressed: onConfirmAgain,
          child: const Icon(Icons.refresh_rounded, color: TokenColors.ink, size: 30),
        ),
      ),
    ];
  }

  /// The hint's hand: over the stage's room, above the bubble and the answer tiles. It takes no touch.
  Widget _handLayer(ActivitySpec s, Size room) {
    final double inset = s.stageIsCard ? 16 : 0;
    return Positioned(
      left: s.stage.left + inset,
      top: s.stage.top + inset,
      width: room.width,
      height: room.height,
      child: IgnorePointer(child: hands!(room)),
    );
  }

  /// The idle prompt's hand: over the stage, above everything the hint's hand is above. It takes no touch and never points at a tile.
  Widget _idleHandLayer(ActivitySpec s, Size room) {
    final double inset = s.stageIsCard ? 16 : 0;
    return Positioned(
      left: s.stage.left + inset,
      top: s.stage.top + inset,
      width: room.width,
      height: room.height,
      child: IgnorePointer(child: idleHand!(room)),
    );
  }

  Widget _stage(ActivitySpec s, Size room) {
    final Widget content = SizedBox(
      key: const Key('lesson-stage'),
      width: room.width,
      height: room.height,
      child: stage(room),
    );
    if (!s.stageIsCard) return Positioned.fromRect(rect: s.stage, child: content);
    return Positioned.fromRect(
      rect: s.stage,
      child: Container(
        padding: const EdgeInsets.all(16),
        // A board whose stage is not drawn (the tiles took its room) keeps the box, and its margin, for what a hint draws in it: no card.
        decoration: s.stageDrawn
            ? BoxDecoration(
                color: TokenColors.paper,
                borderRadius: BorderRadius.circular(TokenRadius.xl),
                boxShadow: clayShadows(TokenColors.cardLip, soft16: true),
              )
            : null,
        child: content,
      ),
    );
  }
}

/// The calm end of a lesson: the line that praises what the child did, a spark, and one way home.
class LessonCelebration extends StatelessWidget {
  const LessonCelebration({super.key, required this.text, required this.onDone, this.cameo, this.sticker});

  final String text;

  /// The key of a sticker the child has just earned; it pops in beside the character.
  final String? sticker;
  final VoidCallback onDone;

  /// The character who celebrates with the child (a live character view); a spark when there is none.
  final Widget? cameo;

  @override
  Widget build(BuildContext context) {
    final BoardClass board = AppLayout.of(context).board;
    final double w = math.min(board.size.width - 80, 520);
    return Positioned.fill(
      child: ColoredBox(
        key: const Key('lesson-celebration'),
        color: TokenColors.scrim,
        child: Center(
          child: Container(
            width: w,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: TokenColors.paper,
              borderRadius: BorderRadius.circular(TokenRadius.xl),
              boxShadow: clayShadows(TokenColors.cardLip, soft16: true),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    if (cameo != null)
                      SizedBox(key: const Key('lesson-cameo'), width: 112, height: 112, child: cameo)
                    else
                      const BoardSvg('assets/art/ui/spark.svg', width: 64, height: 64),
                    if (sticker != null) ...<Widget>[
                      const SizedBox(width: 16),
                      _StickerPop(stickerKey: sticker!),
                    ],
                  ],
                ),
                const SizedBox(height: 8),
                Text(text, textAlign: TextAlign.center, style: AppText.fixed(size: 26, weight: 600)),
                const SizedBox(height: 12),
                PebbleButton(
                  key: const Key('lesson-done'),
                  semanticLabel: He.lessonDoneSemantics.text,
                  size: 80,
                  fill: TokenColors.spark,
                  lip: TokenColors.sparkDeep,
                  onPressed: onDone,
                  child: const BoardSvg('assets/art/ui/home_palm.svg', width: 36, height: 36),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A new sticker pops in. With "reduce motion" it simply appears.
class _StickerPop extends StatelessWidget {
  const _StickerPop({required this.stickerKey});

  final String stickerKey;

  @override
  Widget build(BuildContext context) {
    final Widget art = Semantics(
      label: He.stickerNewSemantics.text,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          color: TokenColors.paper,
          boxShadow: softShadow,
        ),
        child: BoardSvg(stickerAsset(stickerKey), key: const Key('lesson-sticker'), width: 88, height: 88),
      ),
    );
    if (MediaQuery.disableAnimationsOf(context)) return art;
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.4, end: 1),
      duration: const Duration(milliseconds: 600),
      curve: Curves.elasticOut,
      builder: (BuildContext context, double v, Widget? child) => Transform.scale(scale: v, child: child),
      child: art,
    );
  }
}
