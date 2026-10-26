import 'package:flutter/material.dart';

import 'app_text.dart';
import 'layout.dart';
import 'token_types.dart';
import 'tokens.g.dart';

/// Visual state of an answer tile. Nothing is ever "wrong": the miss state is "not yet" (design
/// spec 6.4), shown with a lilac ring and a wobble, never a cross.
enum AnswerState { idle, selected, correct, notYet }

/// A round pebble button with a clay lip (board 05). The tap area is larger than what is drawn.
class PebbleButton extends StatefulWidget {
  const PebbleButton({
    super.key,
    required this.icon,
    required this.semanticLabel,
    this.onPressed,
    this.fill = TokenColors.paper,
    this.lip = TokenColors.cardLip,
    this.size,
  });

  final Widget icon;
  final String semanticLabel;
  final VoidCallback? onPressed;
  final Color fill;
  final Color lip;

  /// Diameter; defaults to the pebble size of the profile's age band.
  final double? size;

  @override
  State<PebbleButton> createState() => _PebbleButtonState();
}

class _PebbleButtonState extends State<PebbleButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final AppLayout layout = AppLayout.of(context);
    final double size = widget.size ?? layout.pebbleSize;
    final double lip = _down ? TokenComponent.clayLipPressed : TokenComponent.clayLip;
    final double slop = layout.touch.hitSlop;
    final double height = size + TokenComponent.clayLip;
    return Semantics(
      button: true,
      enabled: widget.onPressed != null,
      label: widget.semanticLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        // Without a handler there are no gesture handlers either, so it is not announced as tappable.
        onTapDown: widget.onPressed == null ? null : (_) => setState(() => _down = true),
        onTapUp: widget.onPressed == null ? null : (_) => setState(() => _down = false),
        onTapCancel: widget.onPressed == null ? null : () => setState(() => _down = false),
        onTap: widget.onPressed,
        child: Padding(
          padding: EdgeInsets.all(slop),
          child: SizedBox(
            width: size,
            height: height,
            child: Stack(
              children: <Widget>[
                Positioned(
                  left: 0,
                  top: TokenComponent.clayLip,
                  child: _Disc(size: size, color: widget.lip),
                ),
                AnimatedPositioned(
                  duration: TokenMotion.dTouchDown,
                  left: 0,
                  top: TokenComponent.clayLip - lip,
                  child: _Disc(
                    size: size,
                    color: widget.fill,
                    child: ExcludeSemantics(child: widget.icon),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Disc extends StatelessWidget {
  const _Disc({required this.size, required this.color, this.child});

  final double size;
  final Color color;
  final Widget? child;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    alignment: Alignment.center,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    child: child,
  );
}

/// The caption pill: paper, radius 24, text at the band's size with the 1.7 line height of pointed text.
class CaptionPill extends StatelessWidget {
  const CaptionPill({super.key, required this.text, this.maxWidth, this.color = TokenColors.paper});

  final String text;
  final double? maxWidth;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final AppLayout layout = AppLayout.of(context);
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth ?? double.infinity),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(TokenRadius.lg),
          boxShadow: _e1,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: TokenComponent.captionPaddingX,
            vertical: TokenComponent.captionPaddingY,
          ),
          child: Text(text, style: AppText.kid(TokenType.caption[layout.band]!, tablet: layout.isTablet)),
        ),
      ),
    );
  }
}

/// A speech bubble: a caption pill with a small tail on the start side (towards the speaker).
class SpeechBubble extends StatelessWidget {
  const SpeechBubble({super.key, required this.text, this.maxWidth});

  final String text;
  final double? maxWidth;

  @override
  Widget build(BuildContext context) => Stack(
    clipBehavior: Clip.none,
    children: <Widget>[
      PositionedDirectional(
        start: -6,
        top: 18,
        child: Transform.rotate(
          angle: 0.785398,
          child: Container(width: 20, height: 20, color: TokenColors.paper),
        ),
      ),
      CaptionPill(text: text, maxWidth: maxWidth),
    ],
  );
}

/// An answer tile (board 05, 13): paper, thick border, clay lip, soft shadow. The content is drawn
/// left to right, because it holds a numeral or a small equation.
class AnswerTile extends StatelessWidget {
  const AnswerTile({
    super.key,
    required this.child,
    required this.semanticLabel,
    this.state = AnswerState.idle,
    this.onPressed,
  });

  final Widget child;
  final String semanticLabel;
  final AnswerState state;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final AppLayout layout = AppLayout.of(context);
    final double size = layout.answerSize;
    final Color border = answerBorderColor(state);
    final Color wash = state == AnswerState.correct ? TokenColors.sparkTint : TokenColors.paper;
    return Semantics(
      button: true,
      selected: state == AnswerState.selected,
      label: semanticLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onPressed,
        child: Padding(
          padding: EdgeInsets.all(layout.touch.hitSlop),
          child: SizedBox(
            width: size,
            height: size + TokenComponent.clayLip,
            child: Stack(
              clipBehavior: Clip.none,
              children: <Widget>[
                Positioned.fill(
                  top: TokenComponent.clayLip,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: TokenColors.cardLip,
                      borderRadius: BorderRadius.circular(TokenRadius.xl),
                    ),
                  ),
                ),
                Positioned(
                  left: 0,
                  top: 0,
                  width: size,
                  height: size,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: wash,
                      borderRadius: BorderRadius.circular(TokenRadius.xl),
                      border: Border.all(color: border, width: TokenBorder.thick),
                      boxShadow: _e2,
                    ),
                    child: Center(
                      child: MathIsolate(child: ExcludeSemantics(child: child)),
                    ),
                  ),
                ),
                if (state == AnswerState.correct)
                  PositionedDirectional(
                    end: -6,
                    top: -6,
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: const BoxDecoration(color: TokenColors.spark, shape: BoxShape.circle),
                      child: const Icon(Icons.check_rounded, size: 20, color: TokenColors.ink),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The progress trail: sockets that fill from the start side (right in Hebrew). [done] sockets are
/// filled with a spark, the next one is ringed, the rest are empty wells.
class ProgressTrail extends StatelessWidget {
  const ProgressTrail({super.key, required this.total, required this.done});

  final int total;
  final int done;

  @override
  Widget build(BuildContext context) => Semantics(
    label: '$done / $total',
    child: Container(
      height: TokenComponent.trailHeight,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: TokenColors.paper,
        borderRadius: BorderRadius.circular(TokenRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          for (int i = 0; i < total; i++) ...<Widget>[
            if (i > 0) const SizedBox(width: TokenComponent.trailGap),
            _Socket(done: i < done, current: i == done),
          ],
        ],
      ),
    ),
  );
}

class _Socket extends StatelessWidget {
  const _Socket({required this.done, required this.current});

  final bool done;
  final bool current;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: TokenComponent.trailSocket,
    height: TokenComponent.trailSocket,
    child: done
        ? const DecoratedBox(
            decoration: BoxDecoration(color: TokenColors.sparkTint, shape: BoxShape.circle),
            child: Icon(Icons.auto_awesome, size: 16, color: TokenColors.spark),
          )
        : DecoratedBox(
            decoration: BoxDecoration(
              color: TokenColors.mist,
              shape: BoxShape.circle,
              border: current ? Border.all(color: TokenColors.ink, width: TokenBorder.thin) : null,
            ),
          ),
  );
}

/// The small, visibly adult "Parents" button shown in the child space. It only opens the gate.
class ParentEntryButton extends StatelessWidget {
  const ParentEntryButton({super.key, required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: label,
    child: GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onPressed,
      child: Container(
        height: TokenComponent.parentButtonHeight,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: TokenColors.parentGrey,
          borderRadius: BorderRadius.circular(TokenRadius.sm),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ExcludeSemantics(
              child: Text(label, style: AppText.parent(TokenType.parentButton, color: Colors.white)),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.lock_rounded, size: 18, color: Colors.white),
          ],
        ),
      ),
    ),
  );
}

/// An adult-looking filled button for the parent area (height 44, radius 12).
class ParentButton extends StatelessWidget {
  const ParentButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.destructive = false,
    this.quiet = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool destructive;
  final bool quiet;

  @override
  Widget build(BuildContext context) {
    final Color fill = quiet
        ? TokenColors.paper
        : destructive
        ? TokenColors.domainNumbersDeep
        : TokenColors.night;
    final Color text = quiet ? TokenColors.night : Colors.white;
    return Semantics(
      button: true,
      enabled: onPressed != null,
      label: label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onPressed,
        child: Opacity(
          opacity: onPressed == null ? 0.45 : 1,
          child: Container(
            height: TokenComponent.parentButtonHeight,
            constraints: const BoxConstraints(minWidth: 88),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: fill,
              borderRadius: BorderRadius.circular(TokenRadius.sm),
              border: quiet ? Border.all(color: TokenColors.hairline, width: TokenBorder.thin) : null,
            ),
            child: ExcludeSemantics(
              child: Text(label, style: AppText.parent(TokenType.parentButton, color: text)),
            ),
          ),
        ),
      ),
    );
  }
}

const List<BoxShadow> _e1 = <BoxShadow>[
  BoxShadow(color: Color.fromRGBO(43, 35, 80, 0.10), blurRadius: 6, offset: Offset(0, 2)),
];
const List<BoxShadow> _e2 = <BoxShadow>[
  BoxShadow(color: Color.fromRGBO(43, 35, 80, 0.14), blurRadius: 16, offset: Offset(0, 6)),
];

/// The ring colour of each answer state; the tile and the tests both read it from here.
Color answerBorderColor(AnswerState state) => switch (state) {
  AnswerState.idle => TokenColors.cardLip,
  AnswerState.selected => TokenColors.selectedRing,
  AnswerState.correct => TokenColors.correctGlow,
  AnswerState.notYet => TokenColors.notYetRing,
};

/// Kept here so a band-specific style is one call for screens.
TextStyle kidCaption(AppLayout layout) =>
    AppText.kid(TokenType.caption[layout.band]!, tablet: layout.isTablet);

TextStyle kidNumeral(AppLayout layout) =>
    AppText.kid(TokenType.numeral[layout.band]!, tablet: layout.isTablet);

/// The band a profile belongs to, from the age in years (3 and 4: A, 5 and 6: B, 7 and 8: C).
Band bandForAge(int age) => age <= 4 ? Band.a : (age <= 6 ? Band.b : Band.c);
