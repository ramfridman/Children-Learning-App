import '../engine/course.dart';
import 'scripts.dart';

// The content rules of a language pack (docs/languages/frame.md section 2.1, F5, and the two-choice rule of section 2.3). They
// run after the schemas and the course invariants, only for a pack of a language course, and read the documents of the pack as
// the validator holds them: script purity, look-alike letters, decodable words, tagged distractors, the limits on two-choice
// items, and the catalogue of tags. Each message names the file and the path through `say`.

typedef Say = void Function(String file, String path, String message);

List<Map<String, Object?>> _maps(Object? v) => <Map<String, Object?>>[
  for (final Object? e in (v as List<Object?>? ?? const <Object?>[]))
    if (e is Map<String, Object?>) e,
];

Map<String, Object?> _map(Object? v) => v is Map<String, Object?> ? v : const <String, Object?>{};

/// Every skill below the given ones (their prerequisites, and theirs), where a prerequisite on a roll-up means all its groups.
Set<String> skillsBelow(Iterable<String> from, Map<String, Map<String, Object?>> skills) {
  final Set<String> out = <String>{};
  List<String> groupsOf(String id) => <String>[
    for (final String k in skills.keys)
      if (SkillIds.parentOf(k) == id) k,
  ];
  final List<String> stack = <String>[
    for (final String id in from) ...(groupsOf(id).isEmpty ? <String>[id] : groupsOf(id)),
  ];
  while (stack.isNotEmpty) {
    final String id = stack.removeLast();
    final List<String> needs = <String>[
      for (final Map<String, Object?> p in _maps(skills[id]?['prerequisites'])) p['skill']! as String,
    ];
    for (final String need in needs) {
      final List<String> groups = groupsOf(need);
      for (final String n in groups.isEmpty ? <String>[need] : groups) {
        if (out.add(n)) stack.add(n);
      }
    }
  }
  return out;
}

/// Checks the language content of a pack of [course]: [activities], [skills] and [tags] are the valid documents by id.
void checkLanguageContent({
  required String course,
  required Map<String, Map<String, Object?>> activities,
  required Map<String, Map<String, Object?>> lessons,
  required Map<String, Map<String, Object?>> skills,
  required Map<String, Map<String, Object?>> tags,
  required Say say,
}) {
  _tagCatalogue(tags, say);
  // A lesson's celebration is a spoken line like any other: its word on show is held to the same rules.
  lessons.forEach((String id, Map<String, Object?> l) {
    for (final ({String path, String text, bool shown}) t in _targetTexts(l)) {
      _text(course, 'lesson.$id.json', t.path, t.text, say, alone: t.shown);
    }
  });
  for (final String s in skills.keys) {
    final Map<String, Object?> doc = skills[s]!;
    for (final String key in <String>['graphemes', 'tricky']) {
      for (final (int i, Object? g) in ((doc[key] as List<Object?>?) ?? const <Object?>[]).indexed) {
        if (g is String) _text(course, 'skill.$s.json', '$key[$i]', g, say, bareMarks: key == 'graphemes');
      }
    }
  }
  final Map<String, ({Set<String> graphemes, Set<String> tricky})> taughtCache =
      <String, ({Set<String> graphemes, Set<String> tricky})>{};
  activities.forEach((String id, Map<String, Object?> a) {
    final String file = 'activity.$id.json';
    final List<({String path, String text, bool shown})> texts = _targetTexts(a);
    for (final ({String path, String text, bool shown}) t in texts) {
      _text(
        course,
        file,
        t.path,
        t.text,
        say,
        alone: t.shown,
        pointed: course == Course.heb && a['band'] != 'C',
      );
    }
    _distractors(file, a, tags, say);
    _classifiers(file, a, tags, say);
    _face(file, a, say);
    _countInCourse(file, a, say);
    _decodable(file, a, texts, skills, taughtCache, say);
    _pairs(file, id, a, activities, skills, say);
  });
  _twoChoiceLimits(activities, skills, say);
}

// ---- the tags of the catalogue ----

/// Every tag of the course is defined once: it has a kind, and no slug (the last part of its id) stands under two strands.
void _tagCatalogue(Map<String, Map<String, Object?>> tags, Say say) {
  final Map<String, String> bySlug = <String, String>{};
  for (final MapEntry<String, Map<String, Object?>> e in tags.entries) {
    final String file = 'misconception.${e.key}.json';
    if (e.value['kind'] == null) {
      say(
        file,
        'kind',
        'needs a kind (diagnostic, on_the_way, accent or practice): the catalogue gives every tag one',
      );
    }
    final String slug = e.key.split('.').last;
    final String? first = bySlug[slug];
    if (first != null) {
      say(
        file,
        'id',
        'is the same tag as $first (the slug "$slug" is defined twice in the course): a tag is defined once',
      );
    } else {
      bySlug[slug] = e.key;
    }
  }
}

// ---- text ----

/// Every piece of target-language text of an activity: the text and the revealed word of each option, and the word on show of
/// every spoken line ([shown]: it stands alone in a chip).
List<({String path, String text, bool shown})> _targetTexts(Map<String, Object?> a) {
  final List<({String path, String text, bool shown})> out = <({String path, String text, bool shown})>[];
  for (final (int i, Map<String, Object?> o) in _maps(_map(a['answer'])['options']).indexed) {
    for (final String key in <String>['text', 'reveal']) {
      final Object? t = o[key];
      if (t is String) out.add((path: 'answer.options[$i].$key', text: t, shown: false));
    }
  }
  // The words of a say-it item are target-language text too.
  final Map<String, Object?> speak = _map(a['say']);
  for (final String key in <String>['forms', 'foils', 'keyWords']) {
    for (final (int i, Object? w) in ((speak[key] as List<Object?>?) ?? const <Object?>[]).indexed) {
      if (w is String) out.add((path: 'say.$key[$i]', text: w, shown: false));
    }
  }
  void walk(Object? node, String path) {
    if (node is Map<String, Object?>) {
      node.forEach((String k, Object? v) {
        final String here = path.isEmpty ? k : '$path.$k';
        if (k == 'show' && v is String) {
          out.add((path: here, text: v, shown: true));
        } else {
          walk(v, here);
        }
      });
    } else if (node is List<Object?>) {
      for (final (int i, Object? e) in node.indexed) {
        walk(e, '$path[$i]');
      }
    }
  }

  walk(a, '');
  return out;
}

/// The script rules for one text: purity, look-alikes, and for Hebrew in Bands A and B the nikud. A word on show ([alone]) has
/// no punctuation beside it.
void _text(
  String course,
  String file,
  String path,
  String text,
  Say say, {
  bool alone = false,
  bool pointed = false,
  bool bareMarks = false,
}) {
  for (final String p in textProblems(course, text, bareMarks: bareMarks)) {
    say(file, path, '"$text" $p');
  }
  if (alone && RegExp(r'[.,:!?]').hasMatch(text)) {
    say(
      file,
      path,
      '"$text" has punctuation: a word on show stands alone in its chip, with nothing beside it',
    );
  }
  if (pointed) {
    for (final String w in unpointedHebrewWords(text)) {
      say(file, path, 'the word "$w" has no niqqud (Bands A and B are fully pointed)');
    }
  }
}

/// A skill that is letter work offers only words made of the graphemes taught by it and the skills below it, or its tricky
/// words (frame F5, the decodable check).
void _decodable(
  String file,
  Map<String, Object?> a,
  List<({String path, String text, bool shown})> texts,
  Map<String, Map<String, Object?>> skills,
  Map<String, ({Set<String> graphemes, Set<String> tricky})> cache,
  Say say,
) {
  final List<Map<String, Object?>> named = _maps(a['skills']);
  if (named.isEmpty || texts.isEmpty) return;
  final String skill = named.first['id']! as String;
  if (skills[skill]?['letters'] != true) return;
  final ({Set<String> graphemes, Set<String> tricky}) taught = cache.putIfAbsent(skill, () {
    final Set<String> graphemes = <String>{};
    final Set<String> tricky = <String>{};
    for (final String s in <String>{
      skill,
      ...skillsBelow(<String>[skill], skills),
    }) {
      for (final Object? g in (skills[s]?['graphemes'] as List<Object?>?) ?? const <Object?>[]) {
        graphemes.add(plainWord(g! as String));
      }
      for (final Object? w in (skills[s]?['tricky'] as List<Object?>?) ?? const <Object?>[]) {
        tricky.add(plainWord(w! as String));
      }
    }
    return (graphemes: graphemes, tricky: tricky);
  });
  if (taught.graphemes.isEmpty) {
    say(
      'skill.$skill.json',
      'letters',
      'is letter work but no skill up to it teaches a grapheme (graphemes)',
    );
    return;
  }
  for (final ({String path, String text, bool shown}) t in texts) {
    for (final String word in wordsOf(t.text)) {
      if (taught.tricky.contains(plainWord(word)) || decodes(word, taught.graphemes)) continue;
      final String missing = <String>{
        for (final int r in plainWord(word).runes)
          if (!taught.graphemes.any((String g) => g.contains(String.fromCharCode(r)))) String.fromCharCode(r),
      }.join(', ');
      say(
        file,
        t.path,
        'the word "$word" cannot be read yet at $skill: '
        '${missing.isEmpty ? 'its letters are taught, but not in this order' : 'no skill up to it teaches $missing'}',
      );
    }
  }
}

// ---- distractors ----

/// Every distractor is tagged with the misconception it shows, and never with an accent tag. A 3-choice item thereby has two
/// tagged distractors and a 2-choice item one (frame section 2.3).
void _distractors(String file, Map<String, Object?> a, Map<String, Map<String, Object?>> tags, Say say) {
  final Map<String, Object?> answer = _map(a['answer']);
  // A step that is not scored has no right answer, so no distractor: a personal turn's cards are none of them wrong.
  if (answer['type'] == 'none') return;
  for (final (int i, Map<String, Object?> o) in _maps(answer['options']).indexed) {
    if (o['id'] == answer['correct']) continue;
    final Object? tag = o['misconception'];
    final String path = 'answer.options[$i].misconception';
    if (tag is! String) {
      say(file, path, 'a distractor carries the misconception it shows (every distractor is tagged)');
    } else if (tags[tag]?['kind'] == 'accent') {
      say(
        file,
        path,
        '$tag is an accent tag: a difference of accent is never marked, so it is never on a distractor',
      );
    }
  }
}

/// The tag a classifier of a free response (the drum) maps a count to is never an accent tag: a difference of accent is never marked.
void _classifiers(String file, Map<String, Object?> a, Map<String, Map<String, Object?>> tags, Say say) {
  for (final (int i, Map<String, Object?> c) in _maps(_map(a['answer'])['classifiers']).indexed) {
    final Object? tag = c['misconception'];
    if (tag is String && tags[tag]?['kind'] == 'accent') {
      say(
        file,
        'answer.classifiers[$i].misconception',
        '$tag is an accent tag: a difference of accent is never marked, so it is never on a classifier',
      );
    }
  }
}

// ---- the face of text tiles ----

/// The face of the text tiles is the item's to say, never the text's: an item whose options are all one or two letters (a letter, a
/// digraph, `on`, a short own name) must name its `answer.face`, `letter` or `word`, so that no author gets it wrong by accident; a
/// letter item holds nothing longer than that.
void _face(String file, Map<String, Object?> a, Say say) {
  final Map<String, Object?> answer = _map(a['answer']);
  final List<String> texts = <String>[
    for (final Map<String, Object?> o in _maps(answer['options']))
      if (o['text'] is String) o['text']! as String,
  ];
  if (texts.isEmpty) return;
  final Object? face = answer['face'];
  if (face == null && texts.every(isSingleLetter)) {
    say(
      file,
      'answer.face',
      'every option is one or two letters: say whether the tiles are `letter` (square, large, bold) or `word`',
    );
  }
  if (face == 'letter') {
    for (final (int i, Map<String, Object?> o) in _maps(answer['options']).indexed) {
      final Object? t = o['text'];
      if (t is String && !isSingleLetter(t)) {
        say(
          file,
          'answer.options[$i].text',
          '"$t" is longer than a letter or a digraph: a letter item holds letters only',
        );
      }
    }
  }
}

// ---- count and tap in a course ----

/// Count-and-tap in a course (docs/languages/frame.md section 2.2): the counting taps are practice and never scored, so each plays
/// a number word and none carries a tag (a counting error is maths, not language, and a course may not use a core tag); the one
/// scored step, "how many?", is answered on sound buttons that each play a number word.
void _countInCourse(String file, Map<String, Object?> a, Say say) {
  if (a['template'] != 'count_tap') return;
  final Map<String, Object?> objects = _map(_map(a['scene'])['objects']);
  final List<Object?> clips = (objects['clips'] as List<Object?>?) ?? const <Object?>[];
  if (clips.isEmpty) {
    say(file, 'scene.objects.clips', 'a count in a course says a number word for each tap: list its clips');
  } else if (clips.length != objects['count']) {
    say(
      file,
      'scene.objects.clips',
      'has ${clips.length} clips for ${objects['count']} objects: one number word for each tap',
    );
  }
  if (_maps(a['traceClassifiers']).isNotEmpty) {
    say(
      file,
      'traceClassifiers',
      'a counting error is maths, not language: the counting taps are practice and carry no tag in a course',
    );
  }
  for (final (int i, Map<String, Object?> o) in _maps(_map(a['answer'])['options']).indexed) {
    if (o['clip'] == null) {
      say(
        file,
        'answer.options[$i].clip',
        'the scored step of a count in a course is on sound buttons: every option needs its clip',
      );
    }
  }
}

// ---- two-choice items ----

const Map<String, String> _opposite = <String, String>{
  'yes': 'no',
  'no': 'yes',
  'same': 'different',
  'different': 'same',
};

/// How many choices the item has: only an answer that is a choice is scored, so a personal turn's cards or a story's pictures do not
/// count (`type` is `none` for them).
int _choices(Map<String, Object?> a) {
  final Map<String, Object?> answer = _map(a['answer']);
  return answer['type'] == 'none' ? 0 : _maps(answer['options']).length;
}

String _skillOf(Map<String, Object?> a) {
  final List<Map<String, Object?>> s = _maps(a['skills']);
  return s.isEmpty ? '' : s.first['id']! as String;
}

/// A check with two choices is never alone: it is half of a balanced pair in a binary skill. A pair names each other and
/// answers the opposite sides.
void _pairs(
  String file,
  String id,
  Map<String, Object?> a,
  Map<String, Map<String, Object?>> activities,
  Map<String, Map<String, Object?>> skills,
  Say say,
) {
  final Map<String, Object?> answer = _map(a['answer']);
  final Object? pairWith = answer['pairWith'];
  final Map<String, Object?>? partner = pairWith is String ? activities[pairWith] : null;
  if (pairWith is String) {
    if (partner == null) {
      say(file, 'answer.pairWith', 'there is no activity "$pairWith" in this pack');
    } else {
      if (_map(partner['answer'])['pairWith'] != id) {
        say(file, 'answer.pairWith', '$pairWith does not name this item back: a pair names each other');
      }
      if (_skillOf(partner) != _skillOf(a)) say(file, 'answer.pairWith', '$pairWith is of another skill');
      final Object? mine = answer['pole'];
      if (mine is! String || _map(partner['answer'])['pole'] != _opposite[mine]) {
        say(file, 'answer.pole', 'a pair answers the two sides: yes and no, or same and different');
      }
    }
  }
  if (a['purpose'] != 'check' || _choices(a) != 2) return;
  if (skills[_skillOf(a)]?['binary'] != true) {
    say(
      file,
      'purpose',
      'a check with two choices must be a balanced pair in a binary skill; ${_skillOf(a)} is not binary',
    );
  } else if (pairWith is! String) {
    say(
      file,
      'answer.pairWith',
      'a check with two choices is never alone: pair it with the item of the other answer',
    );
  } else if (partner != null && (partner['purpose'] != 'check' || _choices(partner) != 2)) {
    say(file, 'answer.pairWith', '$pairWith must be a check with two choices as well');
  }
}

/// The limits on the two-choice items of a skill (frame section 2.3): at most half of its scored items; the skill has items with
/// three choices too, or is binary by nature with its answers balanced.
void _twoChoiceLimits(
  Map<String, Map<String, Object?>> activities,
  Map<String, Map<String, Object?>> skills,
  Say say,
) {
  final Map<String, List<MapEntry<String, Map<String, Object?>>>> bySkill =
      <String, List<MapEntry<String, Map<String, Object?>>>>{};
  for (final MapEntry<String, Map<String, Object?>> e in activities.entries) {
    if (_choices(e.value) < 2) continue;
    (bySkill[_skillOf(e.value)] ??= <MapEntry<String, Map<String, Object?>>>[]).add(e);
  }
  bySkill.forEach((String skill, List<MapEntry<String, Map<String, Object?>>> items) {
    final String file = 'skill.$skill.json';
    final List<MapEntry<String, Map<String, Object?>>> two = <MapEntry<String, Map<String, Object?>>>[
      for (final MapEntry<String, Map<String, Object?>> e in items)
        if (_choices(e.value) == 2) e,
    ];
    if (two.isEmpty) return;
    if (two.length * 2 > items.length) {
      say(
        file,
        '',
        '${two.length} of its ${items.length} scored items have two choices; at most half may (two-choice items are half of the evidence at most)',
      );
    }
    final bool binary = skills[skill]?['binary'] == true;
    if (!binary) {
      if (two.length == items.length) {
        say(file, '', 'has only items with two choices and is not binary: it also needs items with three');
      }
      return;
    }
    final Map<String, int> poles = <String, int>{};
    for (final MapEntry<String, Map<String, Object?>> e in two) {
      final Object? pole = _map(e.value['answer'])['pole'];
      if (pole is! String) {
        say(
          'activity.${e.key}.json',
          'answer.pole',
          'an item of a binary skill says which side it is (yes, no, same or different)',
        );
      } else {
        poles[pole] = (poles[pole] ?? 0) + 1;
      }
    }
    for (final MapEntry<String, String> pair in <String, String>{'yes': 'no', 'same': 'different'}.entries) {
      if ((poles[pair.key] ?? 0) != (poles[pair.value] ?? 0)) {
        say(
          file,
          '',
          'is binary but its two-choice items are not balanced: ${poles[pair.key] ?? 0} ${pair.key}, '
              '${poles[pair.value] ?? 0} ${pair.value}',
        );
      }
    }
  });
}
