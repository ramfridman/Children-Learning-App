import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../child/activity_shell.dart';
import '../design/app_text.dart';
import '../design/board.dart';
import '../design/components.dart';
import '../design/layout.dart';
import '../design/tokens.g.dart';
import '../rewards/sticker_design.dart';
import '../strings/he.dart';

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
  });

  /// What the guide says now.
  final String bubbleText;

  /// Builds the stage for the room it has (its width and height, in board points).
  final Widget Function(Size room) stage;
  final Widget? tiles;

  /// The layer of the hint's pointing hand over the stage, drawn above the bubble and the guide; null when there is none.
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

  /// The largest font, down to [min], at which [text] fits the room the bubble has.
  static double fitFont(String text, ActivitySpec s, {double min = 14}) {
    const EdgeInsets pad = EdgeInsets.symmetric(horizontal: 16, vertical: 8);
    for (double size = s.bubbleFont; size > min; size -= 1) {
      final TextPainter tp = TextPainter(
        text: TextSpan(
          text: text,
          style: AppText.fixed(size: size, weight: 500),
        ),
        textDirection: TextDirection.rtl,
      )..layout(maxWidth: s.bubbleMaxWidth - pad.horizontal);
      if (tp.height + pad.vertical <= s.bubbleMaxHeight) return size;
    }
    return min;
  }

  @override
  Widget build(BuildContext context) {
    final BoardClass board = AppLayout.of(context).board;
    final ActivitySpec s = ActivitySpec.of(board);
    final double font = fitFont(bubbleText, s);
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
          if (overlay == null && bubbleText.isNotEmpty)
            Positioned(
              left: s.bubbleLeft,
              right: s.bubbleRight,
              top: s.bubbleTop,
              child: BoardBubble(
                key: const Key('lesson-bubble'),
                text: bubbleText,
                fontSize: font,
                maxWidth: s.bubbleMaxWidth,
              ),
            ),
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
          if (hands != null) _handLayer(s, room),
          if (tiles != null)
            Positioned(left: s.tilesLeft, top: s.tilesTop - 12, width: s.tilesWidth, child: tiles!),
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

  /// The hint's hand: over the stage's room, above the bubble. It takes no touch.
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
        decoration: BoxDecoration(
          color: TokenColors.paper,
          borderRadius: BorderRadius.circular(TokenRadius.xl),
          boxShadow: clayShadows(TokenColors.cardLip, soft16: true),
        ),
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
