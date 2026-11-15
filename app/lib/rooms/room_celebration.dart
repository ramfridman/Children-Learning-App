import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../design/app_text.dart';
import '../design/board.dart';
import '../design/components.dart';
import '../design/layout.dart';
import '../design/tokens.g.dart';
import '../strings/he.dart';
import 'moments.dart';
import 'room_backdrop.dart';
import 'room_spec.dart';

/// The card of the calm end of a lesson in a room (docs/design/m11-rooms.md section 4): the room's window at the top of the card (its backdrop,
/// its landmark gaining one new piece, the host and the companion celebrating side by side and the sticker if one was earned), then the
/// host's cheer, the companion's praise line (only when it adds words the cheer does not say) and one way home.
///
/// A lesson that ends because it is time to rest has no new piece, no cheer and calm characters ([ended] false): nothing was finished.
class RoomCelebrationCard extends StatelessWidget {
  const RoomCelebrationCard({
    super.key,
    required this.room,
    required this.host,
    required this.companion,
    required this.praise,
    required this.onDone,
    this.cheer,
    this.sticker,
    this.finished = true,
  });

  final RoomSpec room;

  /// The host and the companion, in their celebrate poses (calm ones when the lesson was not finished).
  final Widget host;
  final Widget companion;

  /// The host's cheer, shown first (null: none), and the companion's praise line under it.
  final String praise;
  final String? cheer;
  final Widget? sticker;
  final VoidCallback onDone;

  /// The landmark gains its piece only when the lesson was finished.
  final bool finished;

  @override
  Widget build(BuildContext context) {
    final BoardClass board = AppLayout.of(context).board;
    final bool tablet = board.isTablet;
    final double w = tablet ? 640 : math.min(board.size.width - 80, 520);
    final double windowH = tablet
        ? 220
        : board == BoardClass.phoneSE
        ? 124
        : 140;
    final Size window = Size(w - 24, windowH);
    final double k = tablet ? 220 / 140 : 1;
    return Container(
      width: w,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: TokenColors.paper,
        borderRadius: BorderRadius.circular(TokenRadius.xl),
        border: Border.all(color: room.rim, width: 4),
        boxShadow: clayShadows(room.lip, soft16: true),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          SizedBox(
            key: const Key('room-celebration-window'),
            width: window.width,
            height: window.height,
            child: _window(window, k, tablet),
          ),
          const SizedBox(height: 12),
          // The host's cheer comes first; the companion's praise follows it, unless it only says the same words again.
          if (cheer != null)
            Text(
              cheer!,
              key: const Key('room-celebration-cheer'),
              textAlign: TextAlign.center,
              style: AppText.fixed(size: tablet ? 32 : 26, weight: 600),
            ),
          if (cheer == null || !cheerRepeatsPraise(praise, cheer!))
            Text(
              praise,
              key: const Key('room-celebration-praise'),
              textAlign: TextAlign.center,
              style: cheer == null
                  ? AppText.fixed(size: tablet ? 32 : 26, weight: 600)
                  : AppText.fixed(size: tablet ? 24 : 20, weight: 500),
            ),
          const SizedBox(height: 10),
          PebbleButton(
            key: const Key('lesson-done'),
            semanticLabel: He.lessonDoneSemantics.text,
            size: tablet ? 88 : 72,
            fill: TokenColors.spark,
            lip: TokenColors.sparkDeep,
            onPressed: onDone,
            child: const BoardSvg('assets/art/ui/home_palm.svg', width: 36, height: 36),
          ),
        ],
      ),
    );
  }

  Widget _window(Size window, double k, bool tablet) {
    final double landmark = (room.isCourse ? window.height * 0.66 : 104 * k).roundToDouble();
    final Offset at = room.isCourse ? Offset(20 * k, 6) : Offset(16 * k, window.height - landmark - 4 * k);
    final double hostSize = 150 * k;
    final double companionSize = 132 * k;
    final double mid = window.width / 2;
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Stack(
        clipBehavior: Clip.none,
        children: <Widget>[
          Positioned.fill(
            child: RoomBackdrop(room: room, size: window, radius: 20, landmark: false),
          ),
          Positioned(
            left: at.dx,
            top: at.dy,
            width: landmark,
            height: landmark,
            child: _Landmark(room: room, withPiece: finished),
          ),
          Positioned(
            left: mid - hostSize,
            top: window.height - hostSize,
            width: hostSize,
            height: hostSize,
            child: SizedBox(key: const Key('room-celebration-host'), child: host),
          ),
          Positioned(
            left: mid - 10 * k,
            top: window.height - companionSize,
            width: companionSize,
            height: companionSize,
            child: SizedBox(key: const Key('lesson-cameo'), child: companion),
          ),
          if (sticker != null) Positioned(right: 8, top: 8, child: sticker!),
        ],
      ),
    );
  }
}

/// The room's landmark with a soft glow, and its new piece drawn over it in the same box: the piece comes in after a beat (it fills with a
/// small squash), and with "reduce motion" it is simply there.
class _Landmark extends StatefulWidget {
  const _Landmark({required this.room, required this.withPiece});

  final RoomSpec room;
  final bool withPiece;

  @override
  State<_Landmark> createState() => _LandmarkState();
}

class _LandmarkState extends State<_Landmark> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) {
      _c.value = 1;
    } else {
      _c.forward();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: Stack(
      clipBehavior: Clip.none,
      fit: StackFit.expand,
      children: <Widget>[
        Transform.scale(
          scale: 1.4,
          child: const DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: <Color>[Color(0xF2FFF1C4), Color(0x00FFF1C4)],
                stops: <double>[0.2, 0.68],
              ),
            ),
          ),
        ),
        SvgPicture.asset(widget.room.art('landmark'), fit: BoxFit.fill, excludeFromSemantics: true),
        if (widget.withPiece)
          AnimatedBuilder(
            animation: _c,
            builder: (BuildContext context, Widget? child) {
              final double draw = ((_c.value - 0.33) / 0.34).clamp(0.0, 1.0);
              final double squash = ((_c.value - 0.67) / 0.33).clamp(0.0, 1.0);
              return Opacity(
                opacity: draw,
                child: Transform.scale(
                  scale: 1 + 0.1 * math.sin(math.pi * squash),
                  alignment: Alignment.bottomCenter,
                  child: child,
                ),
              );
            },
            child: SvgPicture.asset(
              widget.room.art('piece'),
              key: const Key('room-celebration-piece'),
              fit: BoxFit.fill,
              excludeFromSemantics: true,
            ),
          ),
      ],
    ),
  );
}
