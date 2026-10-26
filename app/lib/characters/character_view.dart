import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../design/tokens.g.dart';
import 'character.dart';

/// Draws a character in one of its states and moves it a little, with nothing but transforms and opacity on
/// cached pictures (no layout and no decoding per frame), so it stays cheap on a slow phone.
///
/// What moves: a slow breath and sway; a hop with a little squash and a burst of sparks when it celebrates; a head
/// tilt when it thinks; a lean towards the child when it listens; a pop when it first appears. With "reduce
/// motion" on in the system, none of that moves: the picture only cross-fades between states.
class CharacterView extends StatefulWidget {
  const CharacterView({
    super.key,
    required this.character,
    this.state = CharacterState.idle,
    this.mouthOpen = false,
    this.semanticLabel,
  });

  final Character character;
  final CharacterState state;

  /// While [state] is talk: the mouth open or closed (the lip-sync decides).
  final bool mouthOpen;
  final String? semanticLabel;

  @override
  State<CharacterView> createState() => _CharacterViewState();
}

class _CharacterViewState extends State<CharacterView> with TickerProviderStateMixin {
  late final AnimationController _breath = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3400),
  );
  late final AnimationController _hop = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );
  bool _reduced = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final bool reduced = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (reduced != _reduced || !_breath.isAnimating && !reduced) {
      _reduced = reduced;
      if (reduced) {
        _breath.stop();
      } else {
        _breath.repeat();
      }
    }
  }

  @override
  void didUpdateWidget(CharacterView old) {
    super.didUpdateWidget(old);
    if (widget.state == CharacterState.celebrate && old.state != CharacterState.celebrate && !_reduced) {
      _hop.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _breath.dispose();
    _hop.dispose();
    super.dispose();
  }

  Widget _picture(CharacterImage img) {
    if (img.svg != null) {
      return SvgPicture.string(img.svg!, fit: BoxFit.contain, excludeFromSemantics: true);
    }
    final Uint8List bytes = img.png!;
    return Image.memory(
      bytes,
      fit: BoxFit.contain,
      gaplessPlayback: true,
      filterQuality: FilterQuality.medium,
      excludeFromSemantics: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final CharacterImage image = widget.character.imageFor(widget.state, mouthOpen: widget.mouthOpen);
    final bool tilted = widget.state == CharacterState.think && !_reduced;
    final bool leaning = widget.state == CharacterState.listen && !_reduced;
    // The picture changes without a fade while the mouth flaps, and with a short one when the state changes.
    final Widget picture = AnimatedSwitcher(
      duration: const Duration(milliseconds: 140),
      child: KeyedSubtree(key: ValueKey<CharacterState>(widget.state), child: _picture(image)),
    );
    final Widget moving = AnimatedRotation(
      turns: tilted ? 0.012 : 0,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOut,
      child: AnimatedSlide(
        offset: leaning ? const Offset(0, 0.015) : Offset.zero,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOut,
        child: AnimatedScale(
          scale: leaning ? 1.03 : 1,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOut,
          child: picture,
        ),
      ),
    );
    final Widget body = _reduced
        ? moving
        : AnimatedBuilder(
            animation: Listenable.merge(<Listenable>[_breath, _hop]),
            child: moving,
            builder: (BuildContext context, Widget? child) {
              final double b = math.sin(_breath.value * 2 * math.pi);
              final double h = _hop.isAnimating || _hop.value > 0 && _hop.value < 1 ? _hop.value : 0;
              final double lift = h == 0 ? 0 : -math.sin(math.pi * h) * 0.10;
              final double squash = h == 0 ? 0 : -math.sin(2 * math.pi * h) * 0.05;
              return Transform(
                alignment: Alignment.bottomCenter,
                transform: Matrix4.identity()
                  ..translateByDouble(0.0, 0.0, 0.0, 1.0)
                  ..rotateZ(b * 0.012)
                  ..scaleByDouble(1.0 - squash * 0.5 + b * 0.01, 1.0 + squash + b * 0.025, 1.0, 1.0),
                child: FractionalTranslation(translation: Offset(0, lift), child: child),
              );
            },
          );
    return Semantics(
      label: widget.semanticLabel ?? widget.character.nameHe.replaceAll('{name}', '').trim(),
      image: true,
      child: RepaintBoundary(
        child: Stack(
          fit: StackFit.expand,
          clipBehavior: Clip.none,
          children: <Widget>[
            body,
            if (!_reduced)
              AnimatedBuilder(
                animation: _hop,
                builder: (BuildContext context, Widget? _) => _hop.value == 0 || _hop.value == 1
                    ? const SizedBox.shrink()
                    : _Sparks(progress: _hop.value),
              ),
          ],
        ),
      ),
    );
  }
}

/// A short burst of small stars from the character, as it celebrates.
class _Sparks extends StatelessWidget {
  const _Sparks({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) => IgnorePointer(child: CustomPaint(painter: _SparkPainter(progress)));
}

class _SparkPainter extends CustomPainter {
  _SparkPainter(this.t);

  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint p = Paint()..color = TokenColors.spark.withValues(alpha: (1 - t).clamp(0.0, 1.0));
    final Offset c = Offset(size.width * 0.5, size.height * 0.35);
    for (int i = 0; i < 7; i++) {
      final double a = -math.pi * (0.1 + 0.8 * i / 6);
      final double r = size.shortestSide * (0.18 + 0.32 * t);
      final Offset o = c + Offset(math.cos(a), math.sin(a)) * r;
      final double s = size.shortestSide * 0.035 * (1 - 0.5 * t);
      final Path star = Path()
        ..moveTo(o.dx, o.dy - s * 2)
        ..quadraticBezierTo(o.dx + s * 0.4, o.dy - s * 0.4, o.dx + s * 2, o.dy)
        ..quadraticBezierTo(o.dx + s * 0.4, o.dy + s * 0.4, o.dx, o.dy + s * 2)
        ..quadraticBezierTo(o.dx - s * 0.4, o.dy + s * 0.4, o.dx - s * 2, o.dy)
        ..quadraticBezierTo(o.dx - s * 0.4, o.dy - s * 0.4, o.dx, o.dy - s * 2);
      canvas.drawPath(star, p);
    }
  }

  @override
  bool shouldRepaint(_SparkPainter old) => old.t != t;
}
