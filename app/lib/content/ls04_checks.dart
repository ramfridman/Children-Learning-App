import '../engine/course.dart';
import 'language_checks.dart' show Say;

// The content rules of LS04 blend slide (`blend_slide` 1.0, docs/milestones/L5.md section 5.5 and its decided stop-in-merge rule): the mode of each
// course, parts that join to the word, and a merge that never lets a stop sound alone. The same rules hold for the slide a hint borrows
// (`checkBlendWord`). Pure functions of the documents.

Map<String, Object?> _map(Object? v) => v is Map<String, Object?> ? v : const <String, Object?>{};

List<Map<String, Object?>> _maps(Object? v) => <Map<String, Object?>>[
  for (final Object? e in (v as List<Object?>? ?? const <Object?>[]))
    if (e is Map<String, Object?>) e,
];

bool isBlendSlide(Map<String, Object?> a) => a['template'] == 'blend_slide';

/// The mode each course slides in: English graphemes (continuous sounds stretched into the next, stops clipped), Russian merges (the consonant slides to
/// the vowel), Hebrew units (CV unit by CV unit, then whole).
const Map<String, String> blendModeOf = <String, String>{
  Course.eng: 'graphemes',
  Course.rus: 'merge',
  Course.heb: 'units',
};

/// The checks of a word to slide through, an activity's own or a hint's: [prefix] is the path of its scene. [mode] is the slide's mode.
void checkBlendWord(
  String file,
  String prefix, {
  required Map<String, Object?> word,
  required String mode,
  required Say say,
}) {
  final List<Map<String, Object?>> parts = _maps(word['parts']);
  final String text = (word['text'] as String?) ?? '';
  final String joined = <String>[for (final Map<String, Object?> p in parts) '${p['text']}'].join();
  if (joined != text) say(file, '$prefix.word.parts', 'join to "$joined", not to the word "$text"');
  if (parts.any((Map<String, Object?> p) => '${p['text']}'.isEmpty)) {
    say(file, '$prefix.word.parts', 'a part has no text');
  }
  if (mode == 'merge') {
    if (parts.length != 2) {
      say(
        file,
        '$prefix.word.parts',
        'a merge has two parts: the consonant that slides, and the vowel it slides to',
      );
    }
    // A stop never sounds alone in a merge, in any position: its tile moves in silence, so no clip of its own may be on it (rus `snd-k` is the syllable ka).
    for (final (int i, Map<String, Object?> p) in parts.indexed) {
      if (p['stretch'] == false && p['clip'] != null) {
        say(
          file,
          '$prefix.word.parts[$i].clip',
          'a stop (stretch: false) has no clip in a merge: said alone it comes out with a vowel after it, and the clip could leak',
        );
      }
    }
  }
  if (mode != 'merge' && parts.length < 2) {
    say(file, '$prefix.word.parts', 'a word to slide through has two parts or more');
  }
  if (mode == 'graphemes' && parts.any((Map<String, Object?> p) => p['stretch'] == null)) {
    say(file, '$prefix.word.parts', 'every part says whether it can be held (stretch)');
  }
}

/// The checks of one `blend_slide` activity.
void checkLs04Activity(
  String file,
  Map<String, Object?> a, {
  required bool language,
  required String course,
  required Say say,
}) {
  if (!isBlendSlide(a)) return;
  if (!language) {
    say(file, 'template', 'blend slide belongs to a language course, not to the lands');
    return;
  }
  final Map<String, Object?> scene = _map(a['scene']);
  final Map<String, Object?> answer = _map(a['answer']);
  final String mode = (scene['mode'] as String?) ?? '';
  if (blendModeOf[course] != mode) {
    say(file, 'scene.mode', 'the course $course slides in the mode ${blendModeOf[course]}, not $mode');
  }
  checkBlendWord(file, 'scene', word: _map(scene['word']), mode: mode, say: say);
  if (_map(scene['word'])['whole'] == null) {
    say(file, 'scene.word.whole', 'the clip of the whole word is what plays after the choice');
  }
  final List<Map<String, Object?>> options = _maps(answer['options']);
  if (options.length < 2 || options.length > 4) say(file, 'answer.options', 'a choice of 2 to 4');
  for (final (int i, Map<String, Object?> o) in options.indexed) {
    final bool sound = o['clip'] != null && o['sprite'] == null && o['text'] == null;
    if (mode == 'merge' && !sound) {
      say(
        file,
        'answer.options[$i]',
        'a merge is answered with sound buttons: the syllable heard, with nothing to read on the button',
      );
    }
    if (mode != 'merge' && o['sprite'] == null) {
      say(file, 'answer.options[$i]', 'is answered with the picture of the word');
    }
  }
  if (a['purpose'] == 'probe') say(file, 'purpose', 'a slide is practice of reading: never a probe');
}
