import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../design/tokens.g.dart';
import '../rewards/outfits.dart';
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
    this.outfit,
  });

  final Character character;
  final CharacterState state;

  /// The prize the character wears (M8): a scarf in a colour set, drawn on any character, or null for none.
  final Outfit? outfit;

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
    final Outfit? outfit = widget.outfit;
    final Widget picture = AnimatedSwitcher(
      duration: const Duration(milliseconds: 140),
      child: KeyedSubtree(
        key: ValueKey<CharacterState>(widget.state),
        child: outfit == null
            ? _picture(image)
            : Stack(
                fit: StackFit.expand,
                children: <Widget>[
                  _picture(image),
                  IgnorePointer(
                    child: CustomPaint(
                      key: Key('outfit-${outfit.id}'),
                      painter: ScarfPainter(outfit: outfit, canvas: widget.character.canvas),
                    ),
                  ),
                ],
              ),
      ),
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

/// A scarf at the character's neck, in the prize's colours. It is placed by the shares of the picture (the neck sits about
/// two fifths down, in the middle), so it fits any companion, and replaced by real art for a character that has some.
class ScarfPainter extends CustomPainter {
  const ScarfPainter({required this.outfit, required this.canvas});

  final Outfit outfit;

  /// The character's own canvas, so the scarf follows the picture that is drawn with `BoxFit.contain`.
  final Size canvas;

  @override
  void paint(Canvas c, Size size) {
    final FittedSizes fitted = applyBoxFit(BoxFit.contain, canvas, size);
    final Size pic = fitted.destination;
    final Offset origin = Offset((size.width - pic.width) / 2, (size.height - pic.height) / 2);
    final double u = pic.width;
    final Offset neck = origin + Offset(pic.width * 0.5, pic.height * 0.43);
    final Paint main = Paint()..color = outfit.main;
    final Paint accent = Paint()..color = outfit.accent;
    final Paint ink = Paint()
      ..color = TokenColors.ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = u * 0.008;
    final RRect band = RRect.fromRectAndRadius(
      Rect.fromCenter(center: neck, width: u * 0.30, height: u * 0.07),
      Radius.circular(u * 0.035),
    );
    final Path tail = Path()
      ..moveTo(neck.dx + u * 0.08, neck.dy + u * 0.02)
      ..quadraticBezierTo(neck.dx + u * 0.20, neck.dy + u * 0.10, neck.dx + u * 0.15, neck.dy + u * 0.22)
      ..lineTo(neck.dx + u * 0.05, neck.dy + u * 0.18)
      ..quadraticBezierTo(neck.dx + u * 0.10, neck.dy + u * 0.10, neck.dx + u * 0.03, neck.dy + u * 0.04)
      ..close();
    c.drawPath(tail, accent);
    c.drawPath(tail, ink);
    c.drawRRect(band, main);
    c.drawRRect(band, ink);
    c.drawLine(
      neck + Offset(-u * 0.05, -u * 0.03),
      neck + Offset(-u * 0.05, u * 0.03),
      Paint()
        ..color = outfit.accent
        ..strokeWidth = u * 0.012,
    );
  }

  @override
  bool shouldRepaint(ScarfPainter old) => old.outfit != outfit || old.canvas != canvas;
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
