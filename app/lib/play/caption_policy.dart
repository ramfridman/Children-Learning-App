import '../engine/course.dart';
import '../parent/language_settings.dart' show StressMarks;

// When the target word appears under its picture after the answer (docs/languages/frame.md, LS01 g), and whether it carries its
// stress marks. Pure rules of the course, the child's route and the presentation band; the parent's switches come in as values.

/// Whether the word appears under the right picture once the answer to a listening item is accepted. Only the Russian reader
/// route, with Band B or C presentation: a reader of Russian sees the spelling of a new word at no cost (orthographic
/// facilitation), and the item stays a listening item because the word is shown after the answer, never before. Never under Band A
/// presentation, never for another route or course, and not when the parent turned it off ([parentOff]).
bool captionAfterAnswer({
  required String course,
  required String? route,
  required int presentationBand,
  bool parentOff = false,
}) => !parentOff && course == Course.rus && route == 'reader' && presentationBand >= 1;

/// Whether Russian text shows its stress marks: the parent's choice, or by route (a new learner sees them, a heritage speaker or a
/// reader does not; a route not known yet counts as a new learner).
bool showsStress({required StressMarks setting, required String? route}) => switch (setting) {
  StressMarks.on => true,
  StressMarks.off => false,
  StressMarks.route => route == null || route == 'new',
};

/// [text] with its stress marks (U+0301) taken off unless they are to show.
String withStress(String text, {required bool show}) =>
    show ? text : String.fromCharCodes(text.runes.where((int r) => r != 0x0301));
