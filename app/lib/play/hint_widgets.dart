import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../child/activity_shell.dart';
import '../design/app_text.dart';
import '../design/tokens.g.dart';
import 'count_tap_session.dart' show Dots;
import 'hint_hand.dart';
import 'hints/hint_pictures.dart' show hintScale;

// The small pictures that hints and row entrances draw (B-40). They never take a touch (callers wrap them in IgnorePointer where
// they lie over something that can be touched), they are drawn left to right whatever the language (they are maths), and none
// of them is red.

/// The sky card that holds a hint's second picture (design spec 2.3: radius 18, `skyTint`, a `hintHalo` ring 3 wide).
class HintCard extends StatelessWidget {
  const HintCard({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: TokenColors.skyTint,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: TokenColors.hintHalo, width: 3),
    ),
    child: Directionality(textDirection: TextDirection.ltr, child: child),
  );
}

/// A number counted another way: up to ten as two hands (a full hand of five, then the rest on the other hand), above ten as one or
/// two ten-frames. [shown] is how many are counted so far (0 to [n]); a template raises it one at a time, in time with its objects.
/// [scale] is the board's hint scale (1 on a phone, up to 1.4 on a tablet): the hands are 84 high at 1, a frame's cell 26.
class CountingAid extends StatelessWidget {
  const CountingAid({super.key, required this.n, required this.shown, this.scale = 1});

  final int n;
  final int shown;
  final double scale;

  /// Two hands up to this number, ten-frames above it.
  static const int handsUpTo = 10;

  /// How high a card holding the hands of [scale] is: the hands, the card's padding and its ring.
  static double cardHeight(double scale) => 84 * scale + 26;

  @override
  Widget build(BuildContext context) => HintCard(
    child: FittedBox(
      fit: BoxFit.scaleDown,
      child: n <= handsUpTo
          ? CountingHands(raised: shown, height: 84 * scale)
          : TenFrames(total: n, filled: shown, cell: TenFrames.baseCell * scale),
    ),
  );
}

/// Where a hint's second picture opens in the free answer area (count, give, flash and trace have no tiles to show while the
/// hint is on): its top 14 under the stage, centred, as high as the hands of this board need. Put it in the Stack of the tiles box;
/// a phone's card is 110 high, a tablet's 143 (the hands 84 and 118).
class AnswerAreaCard extends StatelessWidget {
  const AnswerAreaCard({super.key, required this.spec, required this.child});

  final ActivitySpec spec;
  final Widget child;

  /// The board's hint scale (see `hintScale`): the size of the stage the hint is on, without the card around it.
  static double scaleOf(ActivitySpec spec) =>
      hintScale(spec.stageIsCard ? Size(spec.stage.width - 32, spec.stage.height - 32) : spec.stage.size);

  /// The card's size and top, from the board's numbers.
  static ({double top, double height}) place(ActivitySpec spec) {
    // The tiles box starts 12 above the tiles' top (the tiles' tap margin).
    return (
      top: spec.stage.bottom + 14 - (spec.tilesTop - 12),
      height: CountingAid.cardHeight(scaleOf(spec)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ({double top, double height}) at = place(spec);
    return Positioned(
      top: at.top,
      left: 0,
      right: 0,
      height: at.height,
      child: IgnorePointer(child: Center(child: child)),
    );
  }
}

/// Two hands, each with five fingers. The first hand fills first, then the second: "five, and some more". A finger that is up is
/// `spark`, one that is folded is a short stub. At most ten fingers.
class CountingHands extends StatelessWidget {
  const CountingHands({super.key, required this.raised, this.height = 84});

  final int raised;
  final double height;

  @override
  Widget build(BuildContext context) => Row(
    key: const Key('fingers-hint'),
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.end,
    children: <Widget>[
      HintHand(
        key: const Key('hand-first'),
        side: HandSide.left,
        fingers: math.min(raised, 5),
        height: height,
      ),
      SizedBox(width: height / 8.4),
      HintHand(
        key: const Key('hand-second'),
        side: HandSide.right,
        fingers: math.max(0, math.min(raised - 5, 5)),
        height: height,
      ),
    ],
  );
}

/// One or two ten-frames (2 rows of 5): the counters fill the top row from the left, then the bottom row, then the second
/// frame. A number above ten is a full frame and the rest.
class TenFrames extends StatelessWidget {
  const TenFrames({super.key, required this.total, required this.filled, this.cell = baseCell});

  /// How many counters the number has, and how many are on the frames now.
  final int total;
  final int filled;

  /// A cell's side on a phone; [cell] is the one drawn.
  static const double baseCell = 26;
  final double cell;

  @override
  Widget build(BuildContext context) {
    final int frames = (math.min(total, 20) / 10).ceil();
    return Row(
      key: const Key('ten-frames'),
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        for (int f = 0; f < frames; f++) ...<Widget>[
          if (f > 0) const SizedBox(width: 16),
          _Frame(from: f * 10, filled: filled, total: math.min(total, 20), cell: cell),
        ],
      ],
    );
  }
}

class _Frame extends StatelessWidget {
  const _Frame({required this.from, required this.filled, required this.total, required this.cell});

  /// The number of the counters of earlier frames.
  final int from;
  final int filled;
  final int total;
  final double cell;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(2),
    decoration: BoxDecoration(
      border: Border.all(color: TokenColors.ink, width: 2.5),
      color: TokenColors.paper,
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        for (int row = 0; row < 2; row++)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[for (int col = 0; col < 5; col++) _slot(from + row * 5 + col)],
          ),
      ],
    ),
  );

  Widget _slot(int index) {
    final bool used = index < filled && index < total;
    return Container(
      width: cell,
      height: cell,
      decoration: BoxDecoration(border: Border.all(color: TokenColors.hairline, width: 1.5)),
      alignment: Alignment.center,
      child: used
          ? Container(
              key: const Key('frame-counter'),
              width: cell * 0.72,
              height: cell * 0.72,
              decoration: BoxDecoration(
                color: TokenColors.spark,
                shape: BoxShape.circle,
                border: Border.all(color: TokenColors.ink, width: 1.5),
              ),
            )
          : null,
    );
  }
}

/// The goal of a give-N task, as the number and its dots (the question again, not an answer).
class GoalCard extends StatelessWidget {
  const GoalCard({super.key, required this.n});

  final int n;

  @override
  Widget build(BuildContext context) => HintCard(
    child: Column(
      key: const Key('goal-card'),
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text('$n', style: AppText.fixed(size: 40, weight: 800, lineHeight: 1)),
        const SizedBox(height: 6),
        Dots(n),
      ],
    ),
  );
}

/// A row of [count] round dots, [size] across, in `skyDeep`: a number shown as that many (under a numeral). Read left to right.
class DotRow extends StatelessWidget {
  const DotRow({super.key, required this.count, this.size = 12});

  final int count;
  final double size;

  @override
  Widget build(BuildContext context) => Row(
    key: const Key('dot-row'),
    mainAxisSize: MainAxisSize.min,
    textDirection: TextDirection.ltr,
    children: <Widget>[
      for (int i = 0; i < count; i++)
        Container(
          width: size,
          height: size,
          margin: EdgeInsets.symmetric(horizontal: size * 0.25),
          decoration: const BoxDecoration(color: TokenColors.skyDeep, shape: BoxShape.circle),
        ),
    ],
  );
}

/// A small sky dot: this one has been looked at.
class SeenDot extends StatelessWidget {
  const SeenDot({super.key, this.radius = 4});

  final double radius;

  @override
  Widget build(BuildContext context) => Container(
    width: radius * 2,
    height: radius * 2,
    decoration: const BoxDecoration(color: TokenColors.skyDeep, shape: BoxShape.circle),
  );
}

/// A row whose cells appear one by one from the left, about 120 ms each, the gap (the last cell) last (B-40, A8). The first cell
/// is where counting starts: Israeli children tend to count from the right, so the start is shown. With "reduce motion" every cell is
/// there at once and a small sky dot sits under the first one. The row is always left to right; the caller draws the row itself
/// (inside a left-to-right [Directionality]) and wraps each cell with the `cell` function it is given.
class RowEntrance extends StatefulWidget {
  const RowEntrance({super.key, required this.count, required this.builder, this.startAfter = Duration.zero});

  /// The number of cells.
  final int count;

  /// The delay before the first cell (a second row may wait for the first one).
  final Duration startAfter;

  /// Builds the row. `cell(i, child)` returns the cell [i] (from 0, the leftmost) as it should be drawn now.
  final Widget Function(BuildContext context, Widget Function(int index, Widget child) cell) builder;

  /// One cell's time on stage.
  static const Duration step = Duration(milliseconds: 120);

  @override
  State<RowEntrance> createState() => _RowEntranceState();
}

class _RowEntranceState extends State<RowEntrance> with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  bool _started = false;

  Duration get _total => widget.startAfter + RowEntrance.step * (widget.count + 1);

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: _total);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (!MediaQuery.disableAnimationsOf(context)) _c.forward();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Widget _cell(bool still, int index, Widget child) {
    final double from = (widget.startAfter + RowEntrance.step * index).inMilliseconds / _total.inMilliseconds;
    final double to =
        (widget.startAfter + RowEntrance.step * (index + 1)).inMilliseconds / _total.inMilliseconds;
    final Widget shown = still && index == 0
        ? Stack(
            clipBehavior: Clip.none,
            fit: StackFit.passthrough,
            children: <Widget>[
              child,
              const Positioned(
                left: 0,
                right: 0,
                bottom: -8,
                child: Center(child: SeenDot(key: Key('row-start-dot'))),
              ),
            ],
          )
        : child;
    if (still) return shown;
    return FadeTransition(
      opacity: CurvedAnimation(
        parent: _c,
        curve: Interval(from, math.min(1, to + 0.05), curve: Curves.easeOut),
      ),
      child: shown,
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool still = MediaQuery.disableAnimationsOf(context);
    return widget.builder(context, (int index, Widget child) => _cell(still, index, child));
  }
}
