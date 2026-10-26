import 'package:flutter/material.dart';

import '../design/app_text.dart';
import '../design/board.dart';
import '../design/components.dart';
import '../design/layout.dart';
import '../design/tokens.g.dart';
import '../strings/he.dart';

/// Positions of one board of the activity frame, in the board's own coordinates (the `left`, `top`,
/// `right` of its CSS). Boards 13 (phone), 23 (tablet landscape) and 26 (tablet portrait) are the
/// design; the small phone has no board of its own, so its numbers are a composition of mine that
/// keeps every touch target at the board's size.
class _ActivitySpec {
  const _ActivitySpec({
    required this.homeRight,
    required this.controlsTop,
    required this.eyeLeft,
    required this.hintLeft,
    required this.trailLeft,
    required this.trailTop,
    required this.trailWidth,
    required this.nitziLeft,
    required this.nitziTop,
    required this.nitziSize,
    required this.micLeft,
    required this.micTop,
    required this.micSize,
    this.bubbleLeft,
    this.bubbleRight,
    required this.bubbleTop,
    required this.bubbleFont,
    required this.stage,
    required this.stageIsCard,
    required this.tilesLeft,
    required this.tilesTop,
    required this.tilesWidth,
    required this.tileFont,
  });

  final double homeRight;
  final double controlsTop;
  final double eyeLeft;
  final double hintLeft;
  final double trailLeft;
  final double trailTop;
  final double trailWidth;
  final double nitziLeft;
  final double nitziTop;
  final double nitziSize;
  final double micLeft;
  final double micTop;
  final double micSize;

  /// Phones place the bubble by its left edge, tablets by its right edge, as their boards do.
  final double? bubbleLeft;
  final double? bubbleRight;
  final double bubbleTop;
  final double bubbleFont;
  final Rect stage;

  /// Tablets show the stage on a white card (boards 23 and 26); the phone shows the scene directly.
  final bool stageIsCard;
  final double tilesLeft;
  final double tilesTop;
  final double tilesWidth;
  final double tileFont;

  // Board 13.
  static const _ActivitySpec phone = _ActivitySpec(
    homeRight: 59,
    controlsTop: 12,
    eyeLeft: 59,
    hintLeft: 147,
    trailLeft: 71,
    trailTop: 26,
    trailWidth: 546,
    nitziLeft: 617,
    nitziTop: 80,
    nitziSize: 176,
    micLeft: 661,
    micTop: 260,
    micSize: 88,
    bubbleLeft: 413,
    bubbleTop: 104,
    bubbleFont: 26,
    stage: Rect.fromLTWH(71, 96, 330, 128),
    stageIsCard: false,
    tilesLeft: 71,
    tilesTop: 244,
    tilesWidth: 534,
    tileFont: 56,
  );

  // No board: board 13 re-composed for 667 by 375 with the same sizes.
  static const _ActivitySpec phoneSE = _ActivitySpec(
    homeRight: 16,
    controlsTop: 8,
    eyeLeft: 16,
    hintLeft: 96,
    trailLeft: 16,
    trailTop: 22,
    trailWidth: 635,
    nitziLeft: 490,
    nitziTop: 66,
    nitziSize: 150,
    micLeft: 521,
    micTop: 226,
    micSize: 88,
    bubbleLeft: 300,
    bubbleTop: 92,
    bubbleFont: 22,
    stage: Rect.fromLTWH(16, 86, 270, 104),
    stageIsCard: false,
    tilesLeft: 16,
    tilesTop: 214,
    tilesWidth: 464,
    tileFont: 56,
  );

  // Board 23.
  static const _ActivitySpec tabletLandscape = _ActivitySpec(
    homeRight: 24,
    controlsTop: 24,
    eyeLeft: 24,
    hintLeft: 112,
    trailLeft: 0,
    trailTop: 38,
    trailWidth: 1180,
    nitziLeft: 896,
    nitziTop: 150,
    nitziSize: 260,
    micLeft: 978,
    micTop: 672,
    micSize: 96,
    bubbleRight: 224,
    bubbleTop: 112,
    bubbleFont: 28,
    stage: Rect.fromLTWH(288, 230, 584, 300),
    stageIsCard: true,
    tilesLeft: 288,
    tilesTop: 520,
    tilesWidth: 584,
    tileFont: 64,
  );

  // Board 26.
  static const _ActivitySpec tabletPortrait = _ActivitySpec(
    homeRight: 24,
    controlsTop: 32,
    eyeLeft: 24,
    hintLeft: 112,
    trailLeft: 0,
    trailTop: 46,
    trailWidth: 820,
    nitziLeft: 596,
    nitziTop: 112,
    nitziSize: 200,
    micLeft: 44,
    micTop: 172,
    micSize: 96,
    bubbleRight: 224,
    bubbleTop: 152,
    bubbleFont: 28,
    stage: Rect.fromLTWH(24, 372, 772, 300),
    stageIsCard: true,
    tilesLeft: 24,
    tilesTop: 662,
    tilesWidth: 772,
    tileFont: 64,
  );

  static _ActivitySpec of(BoardClass b) => switch (b) {
    BoardClass.phone => phone,
    BoardClass.phoneSE => phoneSE,
    BoardClass.tabletLandscape => tabletLandscape,
    BoardClass.tabletPortrait => tabletPortrait,
  };
}

/// The frame of an activity (boards 13, 23 and 26): the home button, the hint lamp and "show me" eye,
/// the progress trail, the guide with her question, the stage, the answer tiles and the microphone.
/// In M1 it is only a frame: nothing here is playable yet (the count-and-tap template arrives in M2)
/// and the microphone is a picture. The tool rail and the equation of the tablet boards belong to
/// the activity templates of M2.
class ActivityShell extends StatelessWidget {
  const ActivityShell({super.key, required this.onHome});

  final VoidCallback onHome;

  @override
  Widget build(BuildContext context) {
    final BoardClass board = AppLayout.of(context).board;
    final _ActivitySpec s = _ActivitySpec.of(board);
    return Scaffold(
      body: BoardCanvas(
        background: TokenColors.cream,
        board: board,
        children: <Widget>[
          // The question, drawn first so that the guide stands in front of its tail.
          Positioned(
            left: s.bubbleLeft,
            right: s.bubbleRight,
            top: s.bubbleTop,
            child: BoardBubble(
              text: He.activityQuestion.text,
              fontSize: s.bubbleFont,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
          ),
          Positioned(
            left: s.nitziLeft,
            top: s.nitziTop,
            width: s.nitziSize,
            height: s.nitziSize,
            child: const BoardSvg('assets/art/ui/nitzi.svg', key: Key('activity-nitzi')),
          ),
          Positioned(
            left: s.micLeft,
            top: s.micTop,
            child: MicButton(size: s.micSize, semanticLabel: He.micSemantics.text),
          ),
          _stage(s),
          // The answer tiles: the markup order is 2, 3, 4, which in a right-to-left row reads 4, 3, 2.
          Positioned(
            left: s.tilesLeft,
            top: s.tilesTop - 12,
            width: s.tilesWidth,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                for (final (int n, AnswerState st) in <(int, AnswerState)>[
                  (2, AnswerState.idle),
                  (3, AnswerState.selected),
                  (4, AnswerState.idle),
                ]) ...<Widget>[
                  AnswerTile(
                    semanticLabel: '$n',
                    state: st,
                    onPressed: () {},
                    child: Text('$n', style: AppText.fixed(size: s.tileFont, weight: 800, lineHeight: 1)),
                  ),
                ],
              ],
            ),
          ),
          Positioned(
            left: s.trailLeft,
            top: s.trailTop,
            width: s.trailWidth,
            child: const Center(child: ProgressTrail(total: 6, done: 2)),
          ),
          // Start corner: home. End corner: the child's own pacing controls, hint then "show me".
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
              semanticLabel: He.hintSemantics.text,
              onPressed: () {},
              child: const BoardSvg('assets/art/ui/hint.svg', width: 32, height: 32),
            ),
          ),
          boardAt(
            left: s.eyeLeft,
            top: s.controlsTop,
            child: PebbleButton(
              semanticLabel: He.showMeSemantics.text,
              onPressed: () {},
              child: const BoardSvg('assets/art/ui/eye.svg', width: 32, height: 32),
            ),
          ),
        ],
      ),
    );
  }

  Widget _stage(_ActivitySpec s) {
    const BoardSvg flowers = BoardSvg('assets/art/scenes/flowers.svg', key: Key('activity-stage'));
    if (!s.stageIsCard) {
      return Positioned.fromRect(rect: s.stage, child: flowers);
    }
    return Positioned.fromRect(
      rect: s.stage,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: TokenColors.paper,
          borderRadius: BorderRadius.circular(TokenRadius.xl),
          boxShadow: clayShadows(TokenColors.cardLip, soft16: true),
        ),
        child: flowers,
      ),
    );
  }
}
