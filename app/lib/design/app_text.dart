import 'package:flutter/painting.dart';

import 'token_types.dart';
import 'tokens.g.dart';

/// Text styles built from the tokens. The only two families are Heebo and Secular One, with the
/// niqqud rules of the design spec (9.4): no letter spacing, a line height of at least 1.7 on
/// pointed text, and real weights (Heebo is a variable font, so the weight axis is set exactly).
abstract final class AppText {
  static TextStyle _base({
    required String family,
    required int weight,
    required double size,
    required double lineHeight,
    required Color color,
  }) {
    final bool heebo = family == TokenFonts.text;
    return TextStyle(
      fontFamily: family,
      fontSize: size,
      height: lineHeight,
      fontWeight: FontWeight.values[(weight ~/ 100) - 1],
      fontVariations: heebo ? <FontVariation>[FontVariation('wght', weight.toDouble())] : null,
      letterSpacing: 0,
      leadingDistribution: TextLeadingDistribution.even,
      color: color,
    );
  }

  static String _family(String token) => token == 'display' ? TokenFonts.display : TokenFonts.text;

  /// A child-space style at the phone or the tablet size.
  static TextStyle kid(TypeToken t, {required bool tablet, Color color = TokenColors.ink}) => _base(
    family: _family(t.family),
    weight: t.weight,
    size: tablet ? t.tabletSize : t.phoneSize,
    lineHeight: t.lineHeight,
    color: color,
  );

  /// A parent-area style (one size everywhere, adult UI, no niqqud).
  static TextStyle parent(ParentTypeToken t, {Color color = TokenColors.ink}) =>
      _base(family: TokenFonts.text, weight: t.weight, size: t.size, lineHeight: t.lineHeight, color: color);
}
