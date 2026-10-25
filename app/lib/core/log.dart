import 'package:flutter/foundation.dart';

/// The only place in the app allowed to print. Everything is scrubbed first, so a token, key,
/// email address or code can not reach a log even by mistake.
abstract final class Log {
  static final List<(RegExp, String)> _rules = <(RegExp, String)>[
    (RegExp(r'Bearer\s+\S+', caseSensitive: false), 'Bearer [redacted]'),
    (RegExp(r'eyJ[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\.[A-Za-z0-9_-]*'), '[jwt]'),
    (RegExp(r'sb_(publishable|secret)_[A-Za-z0-9_-]+'), '[key]'),
    (RegExp(r'[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}'), '[email]'),
    (RegExp(r'(?<![A-Za-z0-9_-])[A-Za-z0-9_-]{40,}(?![A-Za-z0-9_-])'), '[secret]'),
    (RegExp(r'(?<!\d)\d{6}(?!\d)'), '[code]'),
  ];

  /// Returns [text] with anything secret-looking replaced.
  static String scrub(String text) {
    String out = text;
    for (final (RegExp pattern, String replacement) in _rules) {
      out = out.replaceAll(pattern, replacement);
    }
    return out;
  }

  /// Debug builds only; release builds print nothing.
  static void d(String text) {
    if (kDebugMode) debugPrint(scrub(text));
  }
}
