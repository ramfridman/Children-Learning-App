import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../design/board.dart';
import '../design/layout.dart';
import '../design/stage_spec.dart';
import '../strings/he.dart';
import 'host_places.dart';

/// The friend's corner with the host in it (docs/design/m11-rooms.md sections 2.2 and 2.5). With [present] false the companion stands alone
/// in its own place, as the guide always has; with it true the host stands in front, where the speaker stands, and the companion steps back
/// half a step on the outer side, smaller. Changing [present] moves them: the host walks in from the start edge with two small hops, or steps
/// out again while the companion grows back to the front. With "reduce motion" the pair is simply in its new places and the host fades in
/// (120 ms).
///
/// It draws both, host over companion, on one ground line. Only the companion takes a touch (it says the question again).
class HostPair extends StatefulWidget {
  const HostPair({
    super.key,
    required this.present,
    required this.alone,
    required this.host,
    required this.companion,
    this.onReplay,
  });

  final bool present;

  /// The companion's own place when it stands alone (the board's guide box).
  final Rect alone;
  final Widget host;
  final Widget companion;
  final VoidCallback? onReplay;

  @override
  State<HostPair> createState() => _HostPairState();
}

class _HostPairState extends State<HostPair> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this);
  bool _reduced = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduced = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final int ms = StageScope.maybeOf(context)?.stage.token.transitionMs ?? 350;
    _c.duration = _reduced ? const Duration(milliseconds: 120) : Duration(milliseconds: ms);
    // The first build starts the move that brings the host in.
    if (!_c.isAnimating && _c.value == 0 && widget.present) _go();
  }

  @override
  void didUpdateWidget(HostPair old) {
    super.didUpdateWidget(old);
    if (widget.present != old.present) _go();
  }

  void _go() {
    if (widget.present) {
      _c.forward();
    } else {
      _c.reverse();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final BoardClass board = AppLayout.of(context).board;
    final HostPlaces places = HostPlaces.of(board);
    return AnimatedBuilder(
      animation: _c,
      builder: (BuildContext context, Widget? _) {
        // The move overshoots a little at its end (the band's own overshoot is the token's; the curve here is the shared "springy" one).
        final double v = _reduced
            ? (widget.present ? 1 : 0)
            : _c.status == AnimationStatus.reverse
            ? 1 - Curves.easeOutBack.transform(1 - _c.value)
            : Curves.easeOutBack.transform(_c.value);
        final Rect companion = Rect.lerp(widget.alone, places.back, v)!;
        final double t = _c.value;
        final double hop = _reduced || t <= 0 || t >= 1 ? 0 : -12 * math.sin(t * 4 * math.pi).abs();
        final Rect host = places.front.shift(
          Offset(_reduced ? 0 : (1 - v) * (board.size.width - places.front.left), hop),
        );
        return Stack(
          clipBehavior: Clip.none,
          children: <Widget>[
            Positioned.fromRect(
              rect: companion,
              child: Semantics(
                button: true,
                label: He.replaySemantics.text,
                child: GestureDetector(
                  key: const Key('lesson-replay'),
                  behavior: HitTestBehavior.opaque,
                  onTap: widget.onReplay,
                  child: SizedBox(key: const Key('activity-nitzi'), child: widget.companion),
                ),
              ),
            ),
            if (_c.value > 0)
              Positioned.fromRect(
                rect: host,
                child: IgnorePointer(
                  child: Opacity(
                    opacity: _reduced ? _c.value : (_c.value * 3).clamp(0.0, 1.0),
                    child: SizedBox(key: const Key('room-host'), child: widget.host),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
