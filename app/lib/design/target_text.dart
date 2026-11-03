import 'package:flutter/widgets.dart';

import 'tokens.g.dart';

/// The family of the English and Russian lesson text: "Nitznutz Letters", our renamed build of Andika (OFL), with a two-storey
/// Cyrillic a (owner, 2026-11-03; docs/languages/fonts.md). It is used only through [TargetText] and [targetStyle]: a test
/// reads the source and refuses the name anywhere else, so the interface stays in Heebo and Secular One.
const String targetFontFamily = 'NitznutzLetters';

/// The languages whose text is set in the teaching font. A language tag is part of the text: Russian must be tagged `ru` so
/// that the shapes of Cyrillic letters are the Russian ones (never `sr`, `mk` or `bg`).
enum TargetLanguage {
  english('en'),
  russian('ru');

  const TargetLanguage(this.tag);

  final String tag;

  Locale get locale => Locale(tag);
}

/// The style of target-language text: Medium (500) for words and syllables, Bold (700) for a single-letter tile, upright
/// only (the family has no italic and none is ever asked for), no letter spacing, and no font features (the stylistic set that
/// would give the one-storey Cyrillic a is not in the file, and none is switched on here).
TextStyle targetStyle({
  required double size,
  bool bold = false,
  double lineHeight = 1.3,
  Color color = TokenColors.ink,
}) => TextStyle(
  fontFamily: targetFontFamily,
  fontSize: size,
  height: lineHeight,
  fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
  fontStyle: FontStyle.normal,
  letterSpacing: 0,
  leadingDistribution: TextLeadingDistribution.even,
  color: color,
);

/// A word, a phrase or a letter of the language being taught: an isolated left-to-right run in the language's own locale, in
/// the teaching font, whatever the direction of the screen around it (docs/languages/fonts.md section 6).
class TargetText extends StatelessWidget {
  const TargetText(
    this.text, {
    super.key,
    required this.language,
    required this.size,
    this.bold = false,
    this.lineHeight = 1.3,
    this.color = TokenColors.ink,
    this.textAlign,
    this.maxLines,
  });

  final String text;
  final TargetLanguage language;
  final double size;
  final bool bold;
  final double lineHeight;
  final Color color;
  final TextAlign? textAlign;
  final int? maxLines;

  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: TextDirection.ltr,
    child: Text(
      text,
      locale: language.locale,
      textDirection: TextDirection.ltr,
      textAlign: textAlign,
      maxLines: maxLines,
      style: targetStyle(size: size, bold: bold, lineHeight: lineHeight, color: color),
    ),
  );
}
