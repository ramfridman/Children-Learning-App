import 'package:flutter/material.dart';

import 'app_text.dart';
import 'tokens.g.dart';

/// The two looks of the app: the warm child space and the calm adult parent area.
abstract final class AppTheme {
  static ThemeData child() =>
      _theme(background: TokenColors.cream, primary: TokenColors.sunset, onPrimary: TokenColors.ink);

  static ThemeData parent() =>
      _theme(background: TokenColors.parentBg, primary: TokenColors.night, onPrimary: Colors.white);

  static ThemeData _theme({required Color background, required Color primary, required Color onPrimary}) {
    final ColorScheme scheme = ColorScheme.light(
      primary: primary,
      onPrimary: onPrimary,
      secondary: TokenColors.sea,
      onSecondary: Colors.white,
      surface: TokenColors.paper,
      onSurface: TokenColors.ink,
      error: TokenColors.domainNumbersDeep,
      onError: Colors.white,
      outline: TokenColors.hairline,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: background,
      fontFamily: TokenFonts.text,
      splashFactory: NoSplash.splashFactory,
      textTheme: TextTheme(
        bodyLarge: AppText.parent(TokenType.parentBody),
        bodyMedium: AppText.parent(TokenType.parentBody),
        bodySmall: AppText.parent(TokenType.parentSmall),
        titleLarge: AppText.parent(TokenType.parentH2),
        titleMedium: AppText.parent(TokenType.parentH3),
        headlineSmall: AppText.parent(TokenType.parentH1),
        labelLarge: AppText.parent(TokenType.parentButton),
      ),
    );
  }
}
