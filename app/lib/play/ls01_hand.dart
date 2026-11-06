import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../child/activity_shell.dart';
import 'hint_hand.dart';
import 'hints/hint_pictures.dart' show Appear, SkyRing;

// The pointing hand of the third hint level of the LS01 modes (docs/design/languages-l5-ls01.md section 8, B-40's grammar: "watch me, then
// you"), drawn in board points over the whole board and taking no touch. It comes down from above, as the hand of B-40 does, and its
// fingertip rests on the top edge of what it points at.

/// The layer of the hand: [tip] is where its fingertip stands (a point of the board), or null when there is no hand. Use as a session's
/// `buildBoardLayer`; it is a `Positioned.fill` of the board's stack, or null.
///
/// [flight] is a card the hint sends on its way, drawn at [flightRect] and gliding to each new rectangle it is given (in 600 ms; at once with
/// reduce-motion). It takes no touch either.
Widget? ls01HandLayer(Offset? tip, ActivitySpec spec, {Widget? flight, Rect? flightRect}) {
  final bool flying = flight != null && flightRect != null;
  if (tip == null && !flying) return null;
  return Positioned.fill(
    child: IgnorePointer(
      child: Stack(
        clipBehavior: Clip.none,
        children: <Widget>[
          if (flying) _Flight(rect: flightRect, child: flight),
          if (tip != null) _Hand(tip: tip, tablet: spec.stageIsCard),
        ],
      ),
    ),
  );
}

/// A card in flight: it stands at [rect] and glides when the rectangle changes.
class _Flight extends StatelessWidget {
  const _Flight({required this.rect, required this.child});

  final Rect rect;
  final Widget child;

  @override
  Widget build(BuildContext context) => AnimatedPositioned(
    duration: MediaQuery.disableAnimationsOf(context) ? Duration.zero : const Duration(milliseconds: 600),
    curve: Curves.easeInOut,
    left: rect.left,
    top: rect.top,
    width: rect.width,
    height: rect.height,
    child: child,
  );
}

class _Hand extends StatelessWidget {
  const _Hand({required this.tip, required this.tablet});

  final Offset tip;
  final bool tablet;

  @override
  Widget build(BuildContext context) {
    final bool still = MediaQuery.disableAnimationsOf(context);
    final double h = tablet ? 96 : 72;
    final double w = PointingHand.widthAt(h);
    final Offset art = PointingHand.tipAt(h);
    return AnimatedPositioned(
      key: const ValueKey<String>('ls01-hand'),
      duration: still ? Duration.zero : const Duration(milliseconds: 450),
      curve: Curves.easeInOut,
      left: tip.dx - art.dx,
      top: tip.dy - art.dy,
      child: Appear(
        child: SizedBox(
          key: const Key('hint-p12'),
          width: w,
          height: h,
          child: PointingHand(height: h),
        ),
      ),
    );
  }
}

/// Where the fingertip of a hint rests on [tile], a tile of the answer zone, so that the hand stays out of the stage: the hand hangs above its
/// fingertip, and over a tile's top edge it would reach up into the stage and cover its lowest line (a cloze sentence, the foot of a bin). The
/// tip goes down into the tile as far as the hand needs, and no further than a quarter of the tile below its middle.
Offset ls01TipBelowStage(ActivitySpec zones, Rect tile) {
  final double handHeight = zones.stageIsCard ? 96 : 72;
  final double reach = PointingHand.tipAt(handHeight).dy;
  final double y = math.max(tile.top + 6, zones.stage.bottom + reach + 2);
  return Offset(tile.center.dx, math.min(y, tile.center.dy + tile.height * 0.25));
}

/// A sky ring over a rectangle of the board (a hint that looks at the sign of a bin, a gap, a place); it takes no touch.
class Ls01Ring extends StatelessWidget {
  const Ls01Ring({super.key, required this.radius});

  final double radius;

  @override
  Widget build(BuildContext context) => IgnorePointer(child: SkyRing(round: false, radius: radius));
}
