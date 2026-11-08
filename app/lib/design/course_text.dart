import 'package:flutter/material.dart';

import '../content/scripts.dart' show stripDirectionControls;
import '../engine/course.dart';
import 'app_text.dart';
import 'target_text.dart';
import 'tokens.g.dart';

// Text and direction in a language course (docs/languages/frame.md section 2.1, F1; docs/languages/fonts.md section 6).
// Text in a course is an isolated run in its course's direction, and the rows of tiles, slots and sound buttons follow the
// course's reading direction, not the screen's. English and Russian read left to right, Hebrew right to left.

/// The direction a course reads in. A language course has its own; every land follows the screen (right to left).
TextDirection directionOfCourse(String course) => switch (course) {
  Course.eng || Course.rus => TextDirection.ltr,
  _ => TextDirection.rtl,
};

/// The direction a row of tiles, a stage of pictures or a hint's geometry runs in for an activity of [course], or null for a land,
/// which follows the screen as it always has.
TextDirection? courseRowDirection(String course) =>
    Course.isLanguage(course) ? directionOfCourse(course) : null;

/// The language of the teaching font a course's text is set in, or null for Hebrew (and the lands), which keep Heebo.
TargetLanguage? targetLanguageOf(String course) => switch (course) {
  Course.eng => TargetLanguage.english,
  Course.rus => TargetLanguage.russian,
  _ => null,
};

/// Wraps [run] in the Unicode left-to-right isolate (code points 0x2066 to 0x2069), for a target word that has to stand
/// inside a line of another direction where a chip cannot be used (a screen reader's label, a parent's text). A child's
/// prompt never uses it: a target word there goes in a [TargetChip]. Direction controls inside [run] are taken out, so that the run
/// cannot close the isolate early or reach out of it.
String isolateLtr(String run) =>
    '${String.fromCharCode(0x2066)}${stripDirectionControls(run)}${String.fromCharCode(0x2069)}';

/// Says that the Hebrew course text below is set in the display face (Secular One), for the one activity whose `font` asks for it. It is
/// a scope and not a parameter so that every face of the activity (tiles, signs, cards, stones) follows it with no change of its own.
class DisplayFontScope extends InheritedWidget {
  const DisplayFontScope({super.key, required this.display, required super.child});

  final bool display;

  /// Whether the course text under [context] is set in the display face.
  static bool of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<DisplayFontScope>()?.display ?? false;

  @override
  bool updateShouldNotify(DisplayFontScope old) => display != old.display;
}

/// A word, a letter or a phrase of a course's own language: English and Russian through [TargetText] (the teaching font, a
/// language tag, left to right), Hebrew in Heebo at the nikud line height, right to left.
class CourseText extends StatelessWidget {
  const CourseText(
    this.text, {
    super.key,
    required this.course,
    required this.size,
    this.bold = false,
    this.color = TokenColors.ink,
    this.textAlign,
    this.maxLines,
    this.lineHeight,
  });

  final String text;
  final String course;
  final double size;
  final bool bold;
  final Color color;
  final TextAlign? textAlign;
  final int? maxLines;

  /// The line height, when it is not the script's own (1.7 for pointed Hebrew, 1.3 for English and Russian): a single letter with no marks
  /// has none to keep apart and is set at 1.2 (LS01).
  final double? lineHeight;

  @override
  Widget build(BuildContext context) {
    final TargetLanguage? language = targetLanguageOf(course);
    if (language != null) {
      return TargetText(
        text,
        language: language,
        size: size,
        bold: bold,
        color: color,
        textAlign: textAlign,
        maxLines: maxLines,
        lineHeight: lineHeight ?? 1.3,
      );
    }
    // Secular One has one weight (400): a bold request would only be a smeared copy of it.
    final bool display = DisplayFontScope.of(context);
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Text(
        text,
        locale: const Locale('he'),
        textDirection: TextDirection.rtl,
        textAlign: textAlign,
        maxLines: maxLines,
        style: AppText.fixed(
          size: size,
          weight: display ? 400 : (bold ? 700 : 500),
          display: display,
          color: color,
          lineHeight: lineHeight ?? 1.7,
        ),
      ),
    );
  }
}

/// A target word on show, in a chip of its own on its own line with nothing beside it: no punctuation, no Hebrew word. Inline,
/// the bidirectional rules put a Hebrew question mark against the English word ("?sun"), which reads wrong to a child
/// (fonts.md section 6). A prompt that must show a word shows it here.
class TargetChip extends StatelessWidget {
  const TargetChip(this.text, {super.key, required this.course, required this.size});

  final String text;
  final String course;

  /// The size of the word; the chip is as tall as one line of it plus its padding.
  final double size;

  /// How tall a chip for a word of [size] is: one line at the stand-alone line height, the padding and the border.
  static double heightFor(double size) => size * 1.3 + 4 + 2 * TokenBorder.thin;

  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    label: text,
    child: ExcludeSemantics(
      child: Container(
        key: const Key('target-chip'),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
        decoration: BoxDecoration(
          color: TokenColors.paper,
          borderRadius: BorderRadius.circular(TokenRadius.lg),
          border: Border.all(color: TokenColors.hairline, width: TokenBorder.thin),
        ),
        child: CourseText(text, course: course, size: size, maxLines: 1),
      ),
    ),
  );
}
