import '../engine/course.dart';
import 'language_checks.dart' show Say;

// The content rules of LS03 in `boxes` mode (`sound_boxes` 1.1, docs/milestones/L5.md section 5.3 and its "Decided 2026-11-07" lines): how many
// units a word may have for the room a rail has, the order and the shape of the steps, the colours of the Russian scheme, the stress step, and the
// keys of `classify`. Pure functions of the documents, run after the schemas; in a pack of the lands they only refuse.

Map<String, Object?> _map(Object? v) => v is Map<String, Object?> ? v : const <String, Object?>{};

List<Map<String, Object?>> _maps(Object? v) => <Map<String, Object?>>[
  for (final Object? e in (v as List<Object?>? ?? const <Object?>[]))
    if (e is Map<String, Object?>) e,
];

bool isBoxes(Map<String, Object?> a) =>
    a['template'] == 'sound_boxes' && ((a['templateVersion'] as String?) ?? '').startsWith('1.1');

/// The most units a word of a band may have: the rail's places less one (Band A 5 places, Band B 6, Band C 7), so that "one more" can always be laid
/// (docs/design/l5-templates.md section 2.2).
const Map<String, int> boxesMostUnits = <String, int>{'A': 4, 'B': 5, 'C': 6};

/// The steps in the only order they come in: count, colour, stress, which.
const List<String> boxSteps = <String>['count', 'colour', 'stress', 'which'];

/// The kinds a unit may have in each course: English phonemes are a consonant or a vowel, Hebrew units a CV unit or a bare consonant, Russian
/// sounds a vowel, a hard consonant or a soft one.
const Map<String, Set<String>> boxUnitKinds = <String, Set<String>>{
  Course.eng: <String>{'c', 'vowel'},
  Course.heb: <String>{'cv', 'c'},
  Course.rus: <String>{'vowel', 'hard', 'soft'},
};

final RegExp _classifyKey = RegExp(
  r'^(?:count=(?:[0-9]|more|fewer)|colour=(?:vowel_cons|hard_soft)|stress=(?:[1-6]|other)|which=(?:[1-6]|other))$',
);

/// The checks of one `boxes` activity. [skills] are the skill documents of the pack.
void checkLs03Activity(
  String file,
  Map<String, Object?> a, {
  required bool language,
  required String course,
  required Map<String, Map<String, Object?>> skills,
  required Say say,
}) {
  if (!isBoxes(a)) return;
  if (!language) {
    say(file, 'template', 'sound boxes belong to a language course, not to the lands');
    return;
  }
  final Map<String, Object?> scene = _map(a['scene']);
  final Map<String, Object?> answer = _map(a['answer']);
  final Map<String, Object?> word = _map(scene['word']);
  final List<Map<String, Object?>> units = _maps(word['units']);
  final List<String> steps = <String>[
    for (final Object? s in (scene['steps'] as List<Object?>? ?? const <Object?>[])) '$s',
  ];
  final int count = (answer['count'] as int?) ?? 0;
  final String band = (a['band'] as String?) ?? 'B';

  // The steps come once each, in the order of the item's story.
  final List<int> at = <int>[for (final String s in steps) boxSteps.indexOf(s)];
  for (int i = 1; i < at.length; i++) {
    if (at[i] <= at[i - 1]) {
      say(file, 'scene.steps', 'the steps come once each, in the order count, colour, stress, which');
      break;
    }
  }

  // The units are the units: as many as the count, so that a counter stands for each, and never more than the rail can take.
  if (units.length != count) {
    say(
      file,
      'answer.count',
      'is $count but the word has ${units.length} units: one counter stands for each unit',
    );
  }
  final int most = boxesMostUnits[band] ?? 5;
  if (count > most) {
    say(
      file,
      'answer.count',
      'is $count: a band $band rail leaves room for $most units and one more (a longer word is a band ${band == 'A' ? 'B' : 'C'} item)',
    );
  }
  final Set<String> kinds = boxUnitKinds[course] ?? const <String>{};
  for (final (int i, Map<String, Object?> u) in units.indexed) {
    if (!kinds.contains(u['kind'])) {
      say(
        file,
        'scene.word.units[$i].kind',
        '"${u['kind']}" is not a kind of unit in the course $course (${kinds.join(', ')})',
      );
    }
  }
  if (course == Course.heb && scene['unit'] == 'phoneme') {
    say(
      file,
      'scene.unit',
      'the Hebrew course counts syllables and CV units, never single sounds, at this stage',
    );
  }

  // What each step needs in the answer, and nothing more.
  void needs(String step, String key) {
    final bool listed = steps.contains(step);
    final bool given = answer[key] != null;
    if (listed && !given) say(file, 'answer.$key', 'the $step step needs it');
    if (!listed && given) say(file, 'answer.$key', 'is given but the item has no $step step');
  }

  needs('colour', 'colours');
  needs('stress', 'stress');
  needs('which', 'which');
  final int? which = answer['which'] as int?;
  if (which != null && (which < 1 || which > count)) {
    say(file, 'answer.which', 'is not a place of the word (1 to $count)');
  }

  // The colours are the Russian scheme's: only there, as many as the units, and the unit kinds are what they should be.
  final String? colours = answer['colours'] as String?;
  if (colours != null) {
    if (course != Course.rus) {
      say(file, 'answer.colours', 'the colours of the scheme are the Russian course\'s');
    }
    if (colours.length != count) {
      say(file, 'answer.colours', 'has ${colours.length} colours for $count units');
    }
    if (course == Course.rus && colours.length == units.length) {
      for (final (int i, Map<String, Object?> u) in units.indexed) {
        final String want = switch (u['kind']) {
          'vowel' => 'r',
          'soft' => 'g',
          _ => 'b',
        };
        if (colours[i] != want) {
          say(
            file,
            'answer.colours',
            'unit ${i + 1} is ${u['kind']}, so its colour is $want, not ${colours[i]}',
          );
        }
      }
    }
  }
  if (steps.contains('colour') && course != Course.rus) {
    say(file, 'scene.steps', 'the colour step is the Russian course\'s');
  }

  // The stress step: a skill flagged for it, a vowel to mark, and only after the colour step or on a scheme given coloured, so that no raised chip is
  // where the child first learns which sounds are vowels.
  if (steps.contains('stress')) {
    final String? skillId = _maps(a['skills']).isEmpty ? null : _maps(a['skills']).first['id'] as String?;
    if (course != Course.rus) say(file, 'scene.steps', 'the stress step is the Russian course\'s');
    if (skills[skillId]?['stress'] != true) {
      say(file, 'skills', 'a stress step belongs to a skill flagged "stress" (rus B-17, C-10, C-21)');
    }
    final int? stress = answer['stress'] as int?;
    if (stress != null) {
      if (stress < 1 || stress > units.length) {
        say(file, 'answer.stress', 'is not a place of the word (1 to ${units.length})');
      } else if (units[stress - 1]['kind'] != 'vowel') {
        say(file, 'answer.stress', 'place $stress is not a vowel: the stress sits on a vowel');
      }
    }
    if (!steps.contains('colour') && steps.contains('count')) {
      say(
        file,
        'scene.steps',
        'the stress step comes after the colour step, or on a scheme given coloured (no count step before it)',
      );
    }
    if (units.where((Map<String, Object?> u) => u['kind'] == 'vowel').length < 2) {
      say(
        file,
        'scene.word.units',
        'a word of one vowel has nothing to choose: a stress step needs at least two vowels',
      );
    }
    if (a['purpose'] == 'check') say(file, 'purpose', 'a stress step is a two-choice item, never a check');
  }

  // A free response is evidence of what the child can do with the word, never the check of a skill alone; a probe has one answer, so it counts only.
  if (a['purpose'] == 'check') {
    say(file, 'purpose', 'a boxes item is never a check: its answer is free, with no distractors');
  }
  if (a['purpose'] == 'probe' && !(steps.length == 1 && steps.first == 'count')) {
    say(file, 'purpose', 'a probe has one answer: only a count step can be one');
  }

  // The keys of `classify` name a mistake of a step the item has, and never the right answer.
  final Map<String, Object?> classify = _map(answer['classify']);
  for (final String k in classify.keys) {
    if (!_classifyKey.hasMatch(k)) {
      say(file, 'answer.classify', '"$k" names no mistake of a step');
      continue;
    }
    final String step = k.split('=').first;
    final String what = k.split('=').last;
    if (!steps.contains(step)) {
      say(file, 'answer.classify', '"$k" is a mistake of the $step step, which the item does not have');
    }
    if (what == '${answer['count']}' && step == 'count') {
      say(file, 'answer.classify', '"$k" is the right count');
    }
    if (what == '${answer['which']}' && step == 'which') {
      say(file, 'answer.classify', '"$k" is the right place');
    }
    if (what == '${answer['stress']}' && step == 'stress') {
      say(file, 'answer.classify', '"$k" is the right place');
    }
  }
}
