import 'package:flutter/material.dart';

import 'app_text.dart';
import 'board.dart';
import 'layout.dart';
import 'token_types.dart';
import 'tokens.g.dart';

// Every number in this file is taken from the CSS of the design boards (05, 10, 13, 22, 23): sizes,
// radii, the clay lip under a button, shadows and font sizes.

/// Visual state of an answer tile. Nothing is ever "wrong": the miss state is "not yet" (design
/// spec 6.4), shown with a lilac ring and a wobble, never a cross.
enum AnswerState { idle, selected, correct, notYet }

/// The shadows of a button with a clay lip: the lip itself (a hard shadow straight down) and a soft
/// one, as in `box-shadow: 0 6px 0 <lip>, 0 2px 6px rgba(43,35,80,0.10)` on the boards.
List<BoxShadow> clayShadows(Color lip, {double lipHeight = 6, bool soft16 = false}) => <BoxShadow>[
  BoxShadow(color: lip, offset: Offset(0, lipHeight)),
  if (soft16)
    const BoxShadow(color: Color.fromRGBO(43, 35, 80, 0.14), blurRadius: 16, offset: Offset(0, 6))
  else
    const BoxShadow(color: Color.fromRGBO(43, 35, 80, 0.10), blurRadius: 6, offset: Offset(0, 2)),
];

/// The soft shadow under captions and bubbles: `0 6px 16px rgba(43,35,80,0.14)`.
const List<BoxShadow> softShadow = <BoxShadow>[
  BoxShadow(color: Color.fromRGBO(43, 35, 80, 0.14), blurRadius: 16, offset: Offset(0, 6)),
];

/// A round pebble button with a clay lip (board 05). The tap area is [slop] larger than what is
/// drawn on every side; the widget's drawn disc sits exactly where its parent puts it.
class PebbleButton extends StatefulWidget {
  const PebbleButton({
    super.key,
    required this.child,
    required this.semanticLabel,
    this.onPressed,
    this.size = 64,
    this.fill = TokenColors.paper,
    this.lip = TokenColors.cardLip,
    this.slop = 12,
  });

  final Widget child;
  final String semanticLabel;
  final VoidCallback? onPressed;
  final double size;
  final Color fill;
  final Color lip;
  final double slop;

  @override
  State<PebbleButton> createState() => _PebbleButtonState();
}

class _PebbleButtonState extends State<PebbleButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final bool live = widget.onPressed != null;
    final double lip = _down ? TokenComponent.clayLipPressed : TokenComponent.clayLip;
    return Semantics(
      button: true,
      enabled: live,
      label: widget.semanticLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        // Without a handler there are no gesture handlers either, so it is not announced as tappable.
        onTapDown: live ? (_) => setState(() => _down = true) : null,
        onTapUp: live ? (_) => setState(() => _down = false) : null,
        onTapCancel: live ? () => setState(() => _down = false) : null,
        onTap: widget.onPressed,
        child: Padding(
          padding: EdgeInsets.all(widget.slop),
          child: Transform.translate(
            offset: Offset(0, TokenComponent.clayLip - lip),
            child: Container(
              key: const Key('pebble-disc'),
              width: widget.size,
              height: widget.size,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: widget.fill,
                shape: BoxShape.circle,
                boxShadow: clayShadows(widget.lip, lipHeight: lip),
              ),
              child: ExcludeSemantics(child: widget.child),
            ),
          ),
        ),
      ),
    );
  }
}

/// Places a widget that has a tap margin ([slop]) so that its drawn part lands on the board's own
/// coordinates: each given edge moves out by the margin.
Positioned boardAt({
  double? left,
  double? right,
  double? top,
  double? bottom,
  double slop = 12,
  required Widget child,
}) => Positioned(
  left: left == null ? null : left - slop,
  right: right == null ? null : right - slop,
  top: top == null ? null : top - slop,
  bottom: bottom == null ? null : bottom - slop,
  child: child,
);

/// A speech bubble (board 10, 13): white, radius 24, a soft shadow and a small rotated tail on the
/// right edge, towards the speaker. [fontSize] and [padding] differ per board.
class BoardBubble extends StatelessWidget {
  const BoardBubble({
    super.key,
    required this.text,
    this.fontSize = 26,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  });

  final String text;
  final double fontSize;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) => Stack(
    clipBehavior: Clip.none,
    children: <Widget>[
      Positioned(
        right: -10,
        bottom: 18,
        child: Transform.rotate(
          angle: 0.785398,
          child: Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(color: TokenColors.paper, borderRadius: BorderRadius.circular(4)),
          ),
        ),
      ),
      Container(
        key: const Key('bubble-body'),
        padding: padding,
        decoration: BoxDecoration(
          color: TokenColors.paper,
          borderRadius: BorderRadius.circular(TokenRadius.lg),
          boxShadow: softShadow,
        ),
        child: Text(text, style: AppText.fixed(size: fontSize, weight: 500), softWrap: false),
      ),
    ],
  );
}

/// An answer tile (board 05, 13, 23): [size] square, radius 28, a 4 px border, a clay lip and a soft
/// shadow. The selected tile lifts 6 px and gets an ink outline. Numerals are drawn left to right.
class AnswerTile extends StatelessWidget {
  const AnswerTile({
    super.key,
    required this.child,
    required this.semanticLabel,
    this.state = AnswerState.idle,
    this.onPressed,
    this.size = 96,
    this.slop = 12,
  });

  /// A row of tiles uses no gap: the tap margins of neighbours add up to the board's 24 point gap.
  final Widget child;
  final String semanticLabel;
  final AnswerState state;
  final VoidCallback? onPressed;
  final double size;
  final double slop;

  @override
  Widget build(BuildContext context) {
    final bool selected = state == AnswerState.selected;
    final Widget tile = Container(
      key: const Key('answer-tile'),
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: state == AnswerState.correct ? TokenColors.sparkTint : TokenColors.paper,
        borderRadius: BorderRadius.circular(TokenRadius.xl),
        border: Border.all(color: answerBorderColor(state), width: TokenBorder.thick),
        boxShadow: clayShadows(TokenColors.cardLip, soft16: true),
      ),
      child: MathIsolate(child: ExcludeSemantics(child: child)),
    );
    return Semantics(
      button: true,
      selected: selected,
      label: semanticLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onPressed,
        child: Padding(
          padding: EdgeInsets.all(slop),
          child: Transform.translate(
            offset: Offset(0, selected ? -6 : 0),
            child: Stack(
              clipBehavior: Clip.none,
              children: <Widget>[
                if (selected)
                  // CSS outline: 4 px wide, 3 px away from the border box.
                  Positioned(
                    left: -7,
                    top: -7,
                    right: -7,
                    bottom: -7,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(TokenRadius.xl + 7),
                        border: Border.all(color: TokenColors.selectedRing, width: 4),
                      ),
                    ),
                  ),
                tile,
                if (state == AnswerState.correct)
                  Positioned(
                    right: -6,
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

/// The ring colour of each answer state; the tile and the tests both read it from here.
Color answerBorderColor(AnswerState state) => switch (state) {
  AnswerState.idle => TokenColors.hairline,
  AnswerState.selected => TokenColors.hairline,
  AnswerState.correct => TokenColors.correctGlow,
  AnswerState.notYet => TokenColors.notYetRing,
};

/// The progress trail (board 13): a white pill, 36 high, 20 px sockets 8 apart. Done sockets hold a
/// spark on a pale yellow disc, the next one is ringed, the rest are empty wells. It fills from the
/// start side (the right in Hebrew).
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
        borderRadius: BorderRadius.circular(36),
        boxShadow: const <BoxShadow>[
          BoxShadow(color: Color.fromRGBO(43, 35, 80, 0.10), blurRadius: 6, offset: Offset(0, 2)),
        ],
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
  Widget build(BuildContext context) => Container(
    width: TokenComponent.trailSocket,
    height: TokenComponent.trailSocket,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: done
          ? TokenColors.sparkTint
          : current
          ? TokenColors.paper
          : TokenColors.mist,
      border: current ? Border.all(color: TokenColors.ink, width: 2) : null,
    ),
    child: done ? const BoardSvg('assets/art/ui/spark.svg', width: 20, height: 20) : null,
  );
}

/// The microphone button (board 13): a sea-coloured disc with a clay lip and two small ears on top.
/// In M1 it is only a picture; the microphone opens in M5, and only if a parent turned voice on.
class MicButton extends StatelessWidget {
  const MicButton({super.key, required this.size, required this.semanticLabel});

  final double size;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    final double k = size / 88;
    Widget ear({required bool right}) => Positioned(
      top: -19 * k,
      right: right ? 14 * k : null,
      left: right ? null : 14 * k,
      child: Transform.rotate(
        angle: (right ? 14 : -14) * 0.0174533,
        child: Container(
          width: 17 * k,
          height: 33 * k,
          // The ear is an ellipse (CSS border-radius 50% on a 17 by 33 box).
          decoration: BoxDecoration(
            color: TokenColors.sea,
            borderRadius: BorderRadius.all(Radius.elliptical(8.5 * k, 16.5 * k)),
          ),
        ),
      ),
    );
    return Semantics(
      label: semanticLabel,
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          clipBehavior: Clip.none,
          children: <Widget>[
            ear(right: true),
            ear(right: false),
            Container(
              width: size,
              height: size,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: TokenColors.sea,
                shape: BoxShape.circle,
                boxShadow: clayShadows(TokenColors.seaDeep, soft16: true),
              ),
              child: BoardSvg('assets/art/ui/mic.svg', width: 36 * k, height: 36 * k),
            ),
          ],
        ),
      ),
    );
  }
}

/// The small, visibly adult "Parents" button of the child space (board 10): 44 high, grey, radius 12.
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
        constraints: const BoxConstraints(minWidth: 56),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(color: TokenColors.parentGrey, borderRadius: BorderRadius.circular(12)),
        child: ExcludeSemantics(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const BoardSvg('assets/art/ui/lock.svg', width: 18, height: 18),
              const SizedBox(width: 4),
              Text(label, style: AppText.fixed(size: 13, weight: 700, lineHeight: 1.45, color: Colors.white)),
            ],
          ),
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
              border: quiet ? Border.all(color: TokenColors.night, width: TokenBorder.thin) : null,
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

/// The band a profile belongs to, from the age in years (3 and 4: A, 5 and 6: B, 7 and 8: C).
Band bandForAge(int age) => age <= 4 ? Band.a : (age <= 6 ? Band.b : Band.c);
