// Text helpers of the per-word matcher for the language courses. Pure Dart. The recogniser's text is compared with the words of
// an item, never shown, logged or stored.
import '../engine/course.dart';
import 'hebrew_text.dart';

/// A word or phrase in the plain form both the item's words and the recogniser's text are brought to before they are compared.
///
/// - `eng`: lower case, letters a to z only (an apostrophe is dropped, so "don't" and "DON'T" are "dont"), anything else is a space.
/// - `rus`: lower case, yo (U+0451) is ye (U+0435), stress marks (U+0300, U+0301) are dropped, letters U+0430 to U+044F only
///   (short i included), anything else is a space.
/// - `heb` (and the lands): the existing Hebrew normaliser (no niqqud, final letters folded).
String normalizeWords(String course, String text) {
  switch (course) {
    case Course.eng:
      return _tidy(
        text.toLowerCase().replaceAll(RegExp('[\'\u2019\u02bc]'), '').replaceAll(RegExp('[^a-z]+'), ' '),
      );
    case Course.rus:
      return _tidy(
        text
            .toLowerCase()
            .replaceAll('\u0451', '\u0435')
            .replaceAll(RegExp('[\u0300\u0301]'), '')
            .replaceAll(RegExp('[^\u0430-\u044f]+'), ' '),
      );
    default:
      return normalizeHebrew(text);
  }
}

String _tidy(String s) => s.trim().replaceAll(RegExp(r'\s+'), ' ');

List<String> wordsOf(String normalized) => normalized.isEmpty ? const <String>[] : normalized.split(' ');

/// How alike two plain words are, from 0 to 1: one minus the edit distance over the length of the longer. Equal words are 1.
double wordSimilarity(String a, String b) {
  if (a.isEmpty || b.isEmpty) return 0;
  if (a == b) return 1;
  List<int> prev = List<int>.generate(b.length + 1, (int j) => j);
  for (int i = 1; i <= a.length; i++) {
    final List<int> cur = List<int>.filled(b.length + 1, 0)..[0] = i;
    for (int j = 1; j <= b.length; j++) {
      final int sub = prev[j - 1] + (a.codeUnitAt(i - 1) == b.codeUnitAt(j - 1) ? 0 : 1);
      final int del = prev[j] + 1;
      final int ins = cur[j - 1] + 1;
      cur[j] = sub < del ? (sub < ins ? sub : ins) : (del < ins ? del : ins);
    }
    prev = cur;
  }
  final int longer = a.length > b.length ? a.length : b.length;
  return 1 - prev[b.length] / longer;
}
