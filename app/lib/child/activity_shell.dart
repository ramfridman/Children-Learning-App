import 'package:flutter/material.dart';

import '../design/components.dart';
import '../design/layout.dart';
import '../design/tokens.g.dart';
import '../strings/he.dart';
import 'art.dart';

/// The frame of an activity (boards 13 and 23): top controls, progress trail, stage, caption, answer
/// tiles, the guide and the microphone. In M1 it is only a frame: nothing here is playable yet
/// (the count-and-tap template arrives in M2), and the microphone is a picture.
class ActivityShell extends StatelessWidget {
  const ActivityShell({super.key, required this.onHome});

  final VoidCallback onHome;

  @override
  Widget build(BuildContext context) {
    final AppLayout layout = AppLayout.of(context);
    final double margin = layout.tokens.contentMargin;
    final bool tall = layout.isTabletPortrait;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: margin),
          child: Column(
            children: <Widget>[
              SizedBox(height: layout.tokens.topBarControlTop),
              _TopControls(onHome: onHome),
              Expanded(child: tall ? const _TallBody() : const _WideBody()),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopControls extends StatelessWidget {
  const _TopControls({required this.onHome});

  final VoidCallback onHome;

  @override
  // Board 13: Home at the start corner (right in Hebrew); the progress trail, then the hint lamp and the
  // "show me" eye together at the end corner, which is where a child's own pacing controls live.
  Widget build(BuildContext context) => Row(
    children: <Widget>[
      PebbleButton(
        semanticLabel: He.homeSemantics.text,
        icon: const Icon(Icons.beach_access_rounded, color: TokenColors.seaDeep, size: 36),
        onPressed: onHome,
      ),
      const Spacer(),
      const ProgressTrail(total: 6, done: 2),
      const SizedBox(width: 12),
      PebbleButton(
        semanticLabel: He.hintSemantics.text,
        icon: const Icon(Icons.lightbulb_rounded, color: TokenColors.skyDeep, size: 36),
        onPressed: () {},
      ),
      PebbleButton(
        semanticLabel: He.showMeSemantics.text,
        icon: const Icon(Icons.visibility_rounded, color: TokenColors.ink, size: 36),
        onPressed: () {},
      ),
    ],
  );
}

/// Phones and tablets in landscape: the stage and the tiles at the end side, the guide at the start.
class _WideBody extends StatelessWidget {
  const _WideBody();

  @override
  Widget build(BuildContext context) {
    final AppLayout layout = AppLayout.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SizedBox(width: layout.tokens.guideRailWidth, child: const _GuideRail()),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                // The question sits next to the guide (start side) and the stage at the end side, as on board 13.
                const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    _Question(),
                    SizedBox(width: 24),
                    Expanded(child: _Stage()),
                  ],
                ),
                const Spacer(),
                const _Tiles(),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Tablet in portrait: the guide strip on top, the stage below it, the tiles at the bottom.
class _TallBody extends StatelessWidget {
  const _TallBody();

  @override
  Widget build(BuildContext context) => const Column(
    children: <Widget>[
      SizedBox(height: 16),
      SizedBox(height: 220, child: _GuideRail(horizontal: true)),
      SizedBox(height: 16),
      Expanded(child: _Stage()),
      SizedBox(height: 24),
      _Tiles(),
      SizedBox(height: 48),
    ],
  );
}

class _Question extends StatelessWidget {
  const _Question();

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 8),
    child: SpeechBubble(text: He.activityQuestion.text, maxWidth: 360),
  );
}

class _GuideRail extends StatelessWidget {
  const _GuideRail({this.horizontal = false});

  final bool horizontal;

  @override
  Widget build(BuildContext context) {
    final AppLayout layout = AppLayout.of(context);
    final double h = layout.isTablet ? 300 : 190;
    final Widget nitzi = NitziArt(pose: 'talk', height: horizontal ? 200 : h);
    final Widget mic = Container(
      width: layout.isTablet ? 104 : 88,
      height: layout.isTablet ? 104 : 88,
      decoration: const BoxDecoration(
        color: TokenColors.sea,
        shape: BoxShape.circle,
        boxShadow: <BoxShadow>[BoxShadow(color: TokenColors.seaDeep, offset: Offset(0, 6))],
      ),
      child: Semantics(
        label: He.micSemantics.text,
        child: const ExcludeSemantics(child: Icon(Icons.mic_rounded, color: Colors.white, size: 44)),
      ),
    );
    return horizontal
        ? Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[nitzi, const SizedBox(width: 24), mic],
          )
        : Column(mainAxisAlignment: MainAxisAlignment.center, children: <Widget>[nitzi, mic]);
  }
}

class _Stage extends StatelessWidget {
  const _Stage();

  @override
  Widget build(BuildContext context) {
    final AppLayout layout = AppLayout.of(context);
    return Container(
      height: layout.isTablet ? 340 : (layout.sizeClass == SizeClass.phoneSE ? 104 : 118),
      constraints: BoxConstraints(maxWidth: layout.isTablet ? 640 : 330),
      decoration: BoxDecoration(
        color: TokenColors.worldGrass,
        borderRadius: BorderRadius.circular(TokenRadius.xl),
      ),
      child: const Stack(
        children: <Widget>[
          PositionedDirectional(start: 36, top: 24, child: _Flower(TokenColors.domainColorsFill)),
          PositionedDirectional(start: 110, top: 14, child: _Flower(TokenColors.domainLogicFill)),
          PositionedDirectional(start: 190, top: 28, child: _Flower(TokenColors.domainColorsFill)),
        ],
      ),
    );
  }
}

class _Flower extends StatelessWidget {
  const _Flower(this.color);

  final Color color;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        child: const Center(child: CircleAvatar(radius: 8, backgroundColor: TokenColors.spark)),
      ),
      Container(width: 6, height: 52, color: TokenColors.worldGrassShade),
    ],
  );
}

class _Tiles extends StatelessWidget {
  const _Tiles();

  @override
  Widget build(BuildContext context) {
    final AppLayout layout = AppLayout.of(context);
    return Padding(
      padding: EdgeInsetsDirectional.only(end: layout.isTablet ? 160 : 120),
      child: Align(
        alignment: AlignmentDirectional.centerEnd,
        // The numbers are laid out left to right, as maths always is.
        child: MathIsolate(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              for (final (int n, AnswerState s) in <(int, AnswerState)>[
                (4, AnswerState.idle),
                (3, AnswerState.selected),
                (2, AnswerState.idle),
              ]) ...<Widget>[
                AnswerTile(
                  semanticLabel: '$n',
                  state: s,
                  onPressed: () {},
                  child: Text('$n', style: kidNumeral(layout)),
                ),
                if (n != 2) SizedBox(width: layout.answerGap),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
