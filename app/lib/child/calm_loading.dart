import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../design/tokens.g.dart';

/// What a child sees while the map or a lesson gets ready: the sea, and three pearls that rise and fall one after the
/// other. No words, nothing to wait for or press, and nothing that counts. With "reduce motion" on they stand still.
class CalmLoading extends StatefulWidget {
  const CalmLoading({super.key, this.background = TokenColors.worldSea1});

  final Color background;

  @override
  State<CalmLoading> createState() => _CalmLoadingState();
}

class _CalmLoadingState extends State<CalmLoading> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1500),
  );
  bool _moving = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final bool still = MediaQuery.disableAnimationsOf(context);
    if (still && _moving) {
      _c.stop();
      _moving = false;
    } else if (!still && !_moving) {
      _c.repeat();
      _moving = true;
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: ColoredBox(
      key: const Key('calm-loading'),
      color: widget.background,
      child: Center(
        child: AnimatedBuilder(
          animation: _c,
          builder: (BuildContext context, Widget? child) => Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              for (int i = 0; i < 3; i++) ...<Widget>[if (i > 0) const SizedBox(width: 22), _pearl(i)],
            ],
          ),
        ),
      ),
    ),
  );

  Widget _pearl(int i) {
    // Each pearl is a third of a turn behind the one before it.
    final double phase = (_c.value - i / 3) % 1.0;
    final double rise = _moving ? math.sin(phase * 2 * math.pi) : 0;
    return Transform.translate(
      offset: Offset(0, -14 * rise),
      child: Container(
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: i == 1 ? TokenColors.spark : TokenColors.paper,
          boxShadow: const <BoxShadow>[
            BoxShadow(color: Color(0x22000000), blurRadius: 8, offset: Offset(0, 3)),
          ],
        ),
      ),
    );
  }
}
