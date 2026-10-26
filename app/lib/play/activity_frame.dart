import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../child/activity_shell.dart';
import '../design/app_text.dart';
import '../design/board.dart';
import '../design/components.dart';
import '../design/layout.dart';
import '../design/tokens.g.dart';
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
    this.onHint,
    this.hintGlow = false,
    this.onShowMe,
    this.onReplay,
    this.overlay,
    this.guide,
  });

  /// What the guide says now.
  final String bubbleText;

  /// Builds the stage for the room it has (its width and height, in board points).
  final Widget Function(Size room) stage;
  final Widget? tiles;
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
          // The celebration says its own line; the bubble stays quiet behind it.
          if (overlay == null)
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
          Positioned(
            left: s.micLeft,
            top: s.micTop,
            child: MicButton(size: s.micSize, semanticLabel: He.micSemantics.text),
          ),
          _stage(s, room),
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
  const LessonCelebration({super.key, required this.text, required this.onDone, this.cameo});

  final String text;
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
                if (cameo != null)
                  SizedBox(key: const Key('lesson-cameo'), width: 112, height: 112, child: cameo)
                else
                  const BoardSvg('assets/art/ui/spark.svg', width: 64, height: 64),
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
