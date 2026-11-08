import 'package:flutter/material.dart';

import '../design/app_text.dart';
import 'math_signs.dart';

/// A number sentence as one left-to-right run, for the speech bubble under the question that says it (`prompt.math`, tap_answer 1.4; the
/// owner, 2026-11-07): "40 + 30 = ?". It is made of the tokens of a row (`n:40`, `op:+`, `op:=`, `?`), drawn in the type and the signs of the
/// equation rows (`signGlyph`: − for a minus, × and the parent's ÷ or : for a division), isolated from the right-to-left line above it, so
/// the maths is never mirrored. The line above says the sentence in Hebrew (and a screen reader reads that), so the run is no semantics.
class MathRun extends StatelessWidget {
  const MathRun(this.tokens, {super.key, required this.size, required this.division});

  final List<String> tokens;

  /// The font size of the run: the bubble's.
  final double size;
  final DivisionSign division;

  /// The text of the run: the numbers and signs with a space between each.
  static String textOf(List<String> tokens, DivisionSign division) => <String>[
    for (final String t in tokens)
      if (t == '?') '?' else if (t.startsWith('op:')) signGlyph(t.substring(3), division) else t.substring(2),
  ].join(' ');

  /// How tall the run is (its line is as tall as its font).
  static double heightFor(double size) => size;

  /// The room the run takes under the line in the bubble: the gap and the run.
  static double reserveFor(double size) => 6 + heightFor(size);

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: Directionality(
      textDirection: TextDirection.ltr,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          textOf(tokens, division),
          key: const Key('bubble-math'),
          textScaler: TextScaler.noScaling,
          maxLines: 1,
          softWrap: false,
          style: AppText.fixed(size: size, weight: 800, lineHeight: 1),
        ),
      ),
    ),
  );
}
