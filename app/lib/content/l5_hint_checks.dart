import 'language_checks.dart' show Say;
import 'ls04_checks.dart';
import 'ls05_checks.dart';

// The hints that borrow another template's screen as their picture (docs/milestones/L5.md section 5.9): `hints[].screen` opens the small wheel or strip
// of LS05, or the slide of LS04, inside the stage of the item. Only the text stem of LS01 borrows (a decoding item), and only at level 2 and 3:
// level 1 is "read it to me", which is the stem's own clip. Where the hint gives its own data they obey the rules of the template it borrows.

Map<String, Object?> _map(Object? v) => v is Map<String, Object?> ? v : const <String, Object?>{};

List<Map<String, Object?>> _maps(Object? v) => <Map<String, Object?>>[
  for (final Object? e in (v as List<Object?>? ?? const <Object?>[]))
    if (e is Map<String, Object?>) e,
];

void checkBorrowedHints(
  String file,
  Map<String, Object?> a, {
  required bool language,
  required String course,
  required Say say,
}) {
  final List<Map<String, Object?>> hints = _maps(a['hints']);
  for (final (int i, Map<String, Object?> h) in hints.indexed) {
    if (h['screen'] == null) continue;
    final String path = 'hints[$i].screen';
    final Map<String, Object?> show = _map(h['screen']);
    if (!language) {
      say(file, path, 'a hint that opens another template\'s screen belongs to a language course');
      continue;
    }
    final bool stem = a['template'] == 'tap_answer' && _map(a['scene'])['stem'] != null;
    if (!stem) {
      say(file, path, 'only the text stem of LS01 (a decoding item) borrows another template\'s screen');
    }
    if ((h['level'] as int? ?? 0) < 2) {
      say(file, path, 'level 1 is "read it to me": a borrowed screen is level 2 or 3');
    }
    final String template = '${show['template']}';
    if (template == 'change_part') {
      if (show['word'] != null || show['mode'] != null) {
        say(file, path, 'a wheel or strip has no word and no mode');
      }
      final Map<String, Object?>? frame = show['frame'] is Map<String, Object?> ? _map(show['frame']) : null;
      if (frame != null) {
        if (frame['slots'] != 1) {
          say(
            file,
            path,
            'the wheel or strip of a hint has one place that changes: the other stays as it is in the stem',
          );
        }
        if (course != 'heb' && show['parts'] == null) say(file, path, 'a strip needs its parts');
        checkChangeData(
          file,
          path,
          frame: frame,
          parts: _maps(show['parts']),
          results: _maps(show['results']),
          make: false,
          course: course,
          answerParts: const <String>[],
          say: say,
        );
      } else if (show['parts'] != null || show['results'] != null) {
        say(file, path, 'parts and results come with their frame');
      }
    } else {
      if (show['frame'] != null || show['parts'] != null || show['results'] != null) {
        say(file, path, 'a slide has a word, not a frame and parts');
      }
      final Object? word = show['word'];
      if (word is Map<String, Object?>) {
        final String mode = (show['mode'] as String?) ?? blendModeOf[course] ?? '';
        if (blendModeOf[course] != mode) {
          say(file, '$path.mode', 'the course $course slides in the mode ${blendModeOf[course]}');
        }
        checkBlendWord(file, path, word: word, mode: mode, say: say);
      }
    }
  }
}
