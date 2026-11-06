import 'package:flutter/material.dart';

import '../child/activity_shell.dart';
import 'hint_hand.dart';
import 'hints/hint_pictures.dart' show Appear, SkyRing;

// The pointing hand of the third hint level of the LS01 modes (docs/design/languages-l5-ls01.md section 8, B-40's grammar: "watch me, then
// you"), drawn in board points over the whole board and taking no touch. It comes down from above, as the hand of B-40 does, and its
// fingertip rests on the top edge of what it points at.

/// The layer of the hand: [tip] is where its fingertip stands (a point of the board), or null when there is no hand. Use as a session's
/// `buildBoardLayer`; it is a `Positioned.fill` of the board's stack, or null.
Widget? ls01HandLayer(Offset? tip, ActivitySpec spec) {
  if (tip == null) return null;
  return Positioned.fill(
    child: IgnorePointer(
      child: Stack(
        clipBehavior: Clip.none,
        children: <Widget>[_Hand(tip: tip, tablet: spec.stageIsCard)],
      ),
    ),
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

/// A sky ring over a rectangle of the board (a hint that looks at the sign of a bin, a gap, a place); it takes no touch.
class Ls01Ring extends StatelessWidget {
  const Ls01Ring({super.key, required this.radius});

  final double radius;

  @override
  Widget build(BuildContext context) => IgnorePointer(child: SkyRing(round: false, radius: radius));
}
