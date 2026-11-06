import '../engine/course.dart';
import 'language_checks.dart' show Say;

// The content rules of LS02, write a letter (docs/milestones/L5.md section 5.2, docs/languages/writing-mastery.md section 8): the
// stroke set a form comes from, the four modes, the cues, the classifiers, the structure of a trace node and of a writing node, and the
// pacing of new letters over the visits (E-2). Pure functions of the documents, run after the schemas for every pack of a language
// course; in a pack of the lands they only refuse (`trace` 2.0 belongs to a language course).

Map<String, Object?> _map(Object? v) => v is Map<String, Object?> ? v : const <String, Object?>{};

List<Map<String, Object?>> _maps(Object? v) => <Map<String, Object?>>[
  for (final Object? e in (v as List<Object?>? ?? const <Object?>[]))
    if (e is Map<String, Object?>) e,
];

/// The most new letters one visit may bring (E-2 inside a group, frame section 4.6 P6): two in the Hebrew course, three in the others.
int newLettersPerVisit(String course) => course == Course.heb ? 2 : 3;

/// The most new skills one visit may start (`EngineParams.maxNewSkillsPerSession`); a bundle counts as one.
const int newSkillsPerVisit = 2;

/// The stroke sets a course writes in, by band: print letters at band B and below, script letters at band C (Hebrew, D23).
Set<String> strokeSetsFor(String course, String band) => switch (course) {
  Course.eng => const <String>{'latin'},
  Course.rus => const <String>{'cyrillic'},
  Course.heb =>
    band == 'C' ? const <String>{'hebrew-print', 'hebrew-script'} : const <String>{'hebrew-print'},
  _ => const <String>{},
};

bool isLetterWrite(Map<String, Object?> a) =>
    a['template'] == 'trace' && ((a['templateVersion'] as String?) ?? '').startsWith('2.');

/// What the validator needs to know about a tag of the catalogue.
typedef TagFacts = ({String? family, String? kind});

/// The checks of one LS02 activity. [strokeSets] are the stroke documents of the pack by set name; [skills] the skill documents.
void checkLs02Activity(
  String file,
  Map<String, Object?> a, {
  required bool language,
  required String course,
  required Map<String, Map<String, Object?>> strokeSets,
  required Map<String, Map<String, Object?>> skills,
  required Map<String, TagFacts> tags,
  required Say say,
}) {
  if (!isLetterWrite(a)) return;
  if (!language) {
    say(file, 'template', 'write a letter belongs to a language course, not to the lands');
    return;
  }
  final Map<String, Object?> scene = _map(a['scene']);
  final Map<String, Object?> answer = _map(a['answer']);
  final String mode = scene['mode']! as String;
  final String canvas = scene['canvas']! as String;
  final List<String> forms = <String>[for (final Object? f in scene['forms']! as List<Object?>) f! as String];
  final bool intro = mode == 'intro';
  final bool word = canvas == 'word';
  final bool probeOrCheck = a['purpose'] == 'probe' || a['purpose'] == 'check';
  final List<Map<String, Object?>> named = _maps(a['skills']);

  // One skill, and the right kind of skill for the canvas (writing-mastery section 8 rule 1).
  if (named.length != 1) {
    say(file, 'skills', 'an LS02 item names exactly one skill, so that its evidence has one class');
  }
  final Map<String, Object?>? skill = named.isEmpty ? null : skills[named.first['id']];
  if (skill != null) {
    final Object? rule = skill['writing'];
    if (!word && rule == null) {
      say(file, 'skills', 'a letter canvas needs a skill with a "writing" field (memory or practised)');
    }
    if (word && rule == null && !const <String>{'wr', 'wri'}.contains(skill['strand'])) {
      say(file, 'skills', 'a word canvas needs a writing skill (a "writing" field, or the strand wr or wri)');
    }
    if (intro && rule != 'practised') {
      say(
        file,
        'skills',
        'an intro names the trace node of its group (writing: practised): it carries the first trace of the group',
      );
    }
    if (mode == 'trace' && rule == 'memory') {
      say(
        file,
        'scene.mode',
        'a writing node holds no trace item: tracing lives in the trace node, and is level 3 of the ladder here',
      );
    }
    if ((mode == 'copy' || mode == 'memory') && rule == 'practised') {
      say(
        file,
        'scene.mode',
        'a trace node holds only intro and trace items: copy and memory belong to the writing node',
      );
    }
  }
  if (a['representation'] != 'embodied') {
    say(file, 'representation', 'writing is embodied (docs/languages/frame.md section 3.3.1)');
  }

  // The canvas and its forms.
  if (!word && forms.length != 1) say(file, 'scene.forms', 'a letter canvas has one form');
  if (word && forms.length < 2) say(file, 'scene.forms', 'a word canvas has two to six boxes');
  if (!word && a['variantGroup'] != forms.first) {
    say(
      file,
      'variantGroup',
      'is the form id of the letter ("${forms.first}"): each letter is a group for set coverage',
    );
  }
  if (word && intro) say(file, 'scene.canvas', 'an intro shows one letter');
  if (scene['source'] == 'own_name') {
    if (!word) say(file, 'scene.source', 'the letters of the own name are a word canvas');
    if (course != Course.heb) {
      say(file, 'scene.source', 'the own name is written in the Hebrew course (heb B-27)');
    }
    if (mode != 'trace' || probeOrCheck) {
      say(file, 'scene.source', 'an own-name item is a trace, never a probe or a check');
    }
  }
  final Set<String> allowed = strokeSetsFor(course, a['band']! as String);
  for (final (int i, String f) in forms.indexed) {
    final String set = f.substring(0, f.indexOf('.'));
    if (!allowed.contains(set)) {
      say(
        file,
        'scene.forms[$i]',
        '"$f" is of the stroke set $set, which the course $course does not write in at band ${a['band']}',
      );
      continue;
    }
    final Map<String, Object?>? doc = strokeSets[set];
    if (doc == null) {
      say(file, 'scene.forms[$i]', 'the stroke set $set is not in this pack');
    } else if (!_hasForm(doc, f)) {
      say(file, 'scene.forms[$i]', '"$f" is not a form of the stroke set $set');
    }
  }

  // The modes.
  void only(String key, String mode0, {bool needed = true}) {
    final bool here = scene.containsKey(key);
    if (mode == mode0 && needed && !here) say(file, 'scene.$key', 'a $mode0 item needs "$key"');
    if (mode != mode0 && here) say(file, 'scene.$key', '"$key" belongs to the $mode0 mode');
  }

  only('guide', 'trace');
  only('model', 'copy');
  only('cue', 'memory');
  only('intro', 'intro');
  if (scene.containsKey('practice') && !(word && !intro)) {
    say(file, 'scene.practice', '"practice" is allowed only on a word canvas');
  }
  if (scene['practice'] == true && probeOrCheck) {
    say(file, 'purpose', 'a practice-only item is never a probe or a check');
  }
  if (intro) {
    if (a['purpose'] != 'practice') say(file, 'purpose', 'an intro is never scored: it is practice');
    if (answer['type'] != 'none') {
      say(file, 'answer.type', 'an intro has no answer to give: the type is "none"');
    }
    if (answer.containsKey('classify')) {
      say(file, 'answer.classify', 'an intro scores nothing, so it classifies nothing');
    }
    if (a.containsKey('contradicts')) say(file, 'contradicts', 'an intro is never a repair item');
    if (_maps(a['hints']).isNotEmpty) {
      say(file, 'hints', 'an intro offers no help: nothing in it can be wrong');
    }
  } else {
    if (answer['type'] != 'trace') say(file, 'answer.type', 'is "trace" for every mode but the intro');
    if (!answer.containsKey('classify')) {
      say(file, 'answer.classify', 'needs the classifiers (an empty object when no error can be named)');
    }
    if (_maps(a['hints']).length != 3) {
      say(file, 'hints', 'the ladder has three levels (start dot, drawn once, trace mode)');
    }
  }
  if ((mode == 'trace' || mode == 'copy') && probeOrCheck) {
    say(
      file,
      'purpose',
      'a trace or a copy item is never a probe or a check: tracing is practice and a copy has the model in view',
    );
  }
  if (mode == 'memory') {
    final Map<String, Object?> prompt = _map(a['prompt']);
    if (prompt['target'] == null) {
      say(file, 'prompt.target', 'a memory item plays its cue clip: the sound or the name of the letter');
    }
  }

  // The classifiers: only errors the free-stroke check can name, and only of the family STROKE or SHAPE (or a homophone as a partner).
  final Map<String, Object?> classify = _map(answer['classify']);
  void tagOf(String path, Object? tag, {bool partner = false}) {
    if (tag is! String) return;
    final TagFacts? t = tags[tag];
    if (t == null) return; // `checkTag` says it is not in the catalogue
    final bool ok = t.family == 'STROKE' || t.family == 'SHAPE' || (partner && t.kind == 'on_the_way');
    if (!ok) {
      say(
        file,
        path,
        '$tag is of the family ${t.family}: a stroke error maps to a STROKE or SHAPE tag${partner ? ' (or a homophone, on the way)' : ''}',
      );
    }
  }

  for (final String k in const <String>['start', 'direction', 'lines', 'mirror']) {
    tagOf('answer.classify.$k', classify[k]);
  }
  final Map<String, Object?> partners = _map(classify['partners']);
  for (final MapEntry<String, Object?> p in partners.entries) {
    tagOf('answer.classify.partners.${p.key}', p.value, partner: true);
    if (forms.contains(p.key)) {
      say(file, 'answer.classify.partners.${p.key}', 'is the target itself, not a look-alike');
    }
    final String set = p.key.substring(0, p.key.indexOf('.'));
    if (!allowed.contains(set)) {
      say(
        file,
        'answer.classify.partners.${p.key}',
        'is of the stroke set $set, which the course does not write in here',
      );
    } else if (strokeSets[set] != null && !_hasForm(strokeSets[set]!, p.key)) {
      say(file, 'answer.classify.partners.${p.key}', 'is not a form of the stroke set $set');
    }
  }
}

bool _hasForm(Map<String, Object?> set, String id) =>
    _maps(set['forms']).any((Map<String, Object?> f) => f['id'] == id);

/// The checks of a stroke set document, beyond its schema: a set marked `needs-teacher` is refused in a language pack, it belongs to the
/// course's script, and every form is named by the set it is in.
void checkStrokeSet(String file, Map<String, Object?> doc, {required String course, required Say say}) {
  if (doc['review'] != 'teacher-checked') {
    say(
      file,
      'review',
      'the stroke set is not teacher-checked: a language pack takes no stroke set that still needs its teacher',
    );
  }
  if (!(doc['courses']! as List<Object?>).contains(course)) {
    say(file, 'courses', 'is not a stroke set of the course $course');
  }
  final String set = doc['set']! as String;
  for (final (int i, Map<String, Object?> f) in _maps(doc['forms']).indexed) {
    final String id = f['id']! as String;
    if (!id.startsWith('$set.')) say(file, 'forms[$i].id', '"$id" is not named by its set "$set"');
  }
  if (doc['count'] != _maps(doc['forms']).length) say(file, 'count', 'is not the number of forms');
  // The bounds are the schema's; the rules a number cannot say: the 'dot' kind is a tap, two points one unit apart, and the drawing
  // path of a stroke (`d`) is a path the model drawing can read.
  for (final (int i, Map<String, Object?> f) in _maps(doc['forms']).indexed) {
    for (final (int k, Map<String, Object?> s) in _maps(f['strokes']).indexed) {
      if (s['kind'] == 'dot' && (s['points']! as List<Object?>).length != 2) {
        say(file, 'forms[$i].strokes[$k]', 'a dot has two points');
      }
      final String? fault = strokePathFault(s['d']! as String);
      if (fault != null) say(file, 'forms[$i].strokes[$k].d', fault);
    }
    for (final (int b, Map<String, Object?> build) in _maps(f['alternates']).indexed) {
      for (final (int k, Map<String, Object?> s) in _maps(build['strokes']).indexed) {
        if (s['kind'] == 'dot' && (s['points']! as List<Object?>).length != 2) {
          say(file, 'forms[$i].alternates[$b].strokes[$k]', 'a dot has two points');
        }
      }
    }
  }
}

final RegExp _pathNumber = RegExp(r'^-?\d+(\.\d+)?$');

/// What is wrong with the drawing path [d] of a stroke, or null when it is right: it starts with M, each command is one letter and its
/// numbers (M and L two, C six) with single spaces between, and each number is written as `-?\d+(\.\d+)?` and lies from 0 to 100.
/// The app draws the path with the same grammar, so a path that passes here can not make it read past the end or parse a bad number.
String? strokePathFault(String d) {
  final List<String> t = d.split(' ');
  if (t.first != 'M') return 'a stroke path starts with M';
  int i = 0;
  while (i < t.length) {
    final int count = switch (t[i]) {
      'M' || 'L' => 2,
      'C' => 6,
      _ => -1,
    };
    if (count < 0) return 'a stroke path has only M, L and C commands, not "${t[i]}"';
    if (i + count >= t.length) return 'the command ${t[i]} needs $count numbers';
    for (int k = 1; k <= count; k++) {
      final String n = t[i + k];
      if (!_pathNumber.hasMatch(n)) return 'a stroke path has "$n" where a number is wanted';
      final double v = double.parse(n);
      if (v < 0 || v > 100) return 'a stroke path number is from 0 to 100, not $n';
    }
    i += count + 1;
  }
  return null;
}

/// The structure rules of the writing skills and of the pacing over the visits. [activities], [lessons], [skills] and [gates] are the valid
/// documents of the pack by id.
void checkLs02Pack({
  required String course,
  required Map<String, Map<String, Object?>> activities,
  required Map<String, Map<String, Object?>> lessons,
  required Map<String, Map<String, Object?>> skills,
  required Map<String, Map<String, Object?>> gates,
  required Say say,
}) {
  // The items of each skill (its first skill, as the engine files them), only the LS02 ones.
  final Map<String, List<Map<String, Object?>>> byNode = <String, List<Map<String, Object?>>>{};
  activities.forEach((String id, Map<String, Object?> a) {
    if (!isLetterWrite(a)) return;
    final List<Map<String, Object?>> named = _maps(a['skills']);
    if (named.isNotEmpty) (byNode[named.first['id']! as String] ??= <Map<String, Object?>>[]).add(a);
  });
  _cues(activities, say);
  final Set<String> required = <String>{
    for (final Map<String, Object?> g in gates.values)
      for (final Object? r in (g['requires'] as List<Object?>?) ?? const <Object?>[]) r! as String,
  };

  skills.forEach((String id, Map<String, Object?> s) {
    final Object? rule = s['writing'];
    if (rule == null) return;
    final String file = 'skill.$id.json';
    final List<Map<String, Object?>> items = byNode[id] ?? const <Map<String, Object?>>[];
    bool letterItem(Map<String, Object?> a) => _map(a['scene'])['canvas'] == 'letter';
    String modeOf(Map<String, Object?> a) => _map(a['scene'])['mode']! as String;
    String formOf(Map<String, Object?> a) => (_map(a['scene'])['forms']! as List<Object?>).first! as String;

    if (rule == 'practised') {
      // A trace node (E-1): practice only, never checked, never probed, never in a gate, never mastered.
      if (s.containsKey('masteryRequires')) {
        say(file, 'masteryRequires', 'a trace node is practised, not mastered: it asks for no mastery');
      }
      if (required.contains(id) || required.contains(SkillIds.parentOf(id))) {
        say(
          file,
          'writing',
          'a trace node is in the "requires" of a gate: it never blocks, so no gate may wait for it',
        );
      }
      for (final Map<String, Object?> a in items) {
        final String at = 'activity.${a['id']}.json';
        if (a['purpose'] == 'probe' || a['purpose'] == 'check') {
          say(
            at,
            'purpose',
            'a trace node has no check and no probe: how well a child traces says nothing about what it knows',
          );
        }
        if (a['checkType'] != 'practice') say(at, 'checkType', 'a trace node has no check');
      }
      // Every letter has a start-dot trace, or the node could never be practised.
      final Set<String> letters = <String>{
        for (final Map<String, Object?> a in items.where(letterItem)) formOf(a),
      };
      final Set<String> withStart = <String>{
        for (final Map<String, Object?> a in items.where(letterItem))
          if (modeOf(a) == 'trace' && _map(a['scene'])['guide'] == 'start') formOf(a),
      };
      for (final String f in letters.difference(withStart)) {
        say(
          file,
          'writing',
          'the letter $f has no trace with the start dot only: the node could not be practised without it',
        );
      }
      if (items.isEmpty) say(file, 'writing', 'a trace node has no LS02 item');
    } else {
      // A writing node (E-1): copy and memory, mastered by memory successes on two days with both cues.
      if (s['setCoverage'] != true) {
        say(
          file,
          'setCoverage',
          'a writing node covers its letters: every letter is written once from memory',
        );
      }
      if (s.containsKey('bundle')) {
        say(
          file,
          'bundle',
          'a writing node is never in a bundle: the slow motor part may not hold the letters back',
        );
      }
      if (_map(s['masteryRequires']).containsKey('representations')) {
        say(
          file,
          'masteryRequires.representations',
          'is not read for a writing node: the two cues replace the representations',
        );
      }
      final List<Map<String, Object?>> memory = <Map<String, Object?>>[
        for (final Map<String, Object?> a in items)
          if (modeOf(a) == 'memory' && a['purpose'] != 'probe') a,
      ];
      for (final String cue in const <String>['sound', 'name']) {
        if (!memory.any((Map<String, Object?> a) => _map(a['scene'])['cue'] == cue)) {
          say(file, 'writing', 'has no memory item cued by the $cue: fresh mastery needs both cues');
        }
      }
      final Set<String> letters = <String>{
        for (final Map<String, Object?> a in items.where(letterItem)) formOf(a),
      };
      final Set<String> remembered = <String>{
        for (final Map<String, Object?> a in memory.where(letterItem)) formOf(a),
      };
      for (final String f in letters.difference(remembered)) {
        say(
          file,
          'writing',
          'the letter $f has no memory item: each letter must be written once from memory',
        );
      }
      for (final Map<String, Object?> a in items) {
        final String at = 'activity.${a['id']}.json';
        if ((a['purpose'] == 'check' || a['purpose'] == 'probe') && modeOf(a) != 'memory') {
          say(at, 'purpose', 'every check and probe of a writing node is a memory item');
        }
      }
      // It needs its trace node and the knowledge of its letters (a memory cue asks for a sound or a name).
      final List<String> needs = <String>[
        for (final Map<String, Object?> p in _maps(s['prerequisites'])) p['skill']! as String,
      ];
      bool traceNode(String n) => skills[n]?['writing'] == 'practised';
      final bool hasTrace = needs.any(
        (String n) =>
            traceNode(n) || skills.keys.any((String k) => SkillIds.parentOf(k) == n && traceNode(k)),
      );
      final bool hasFacet = needs.any(
        (String n) =>
            skills.containsKey(n) &&
            skills[n]!['writing'] == null &&
            !(skills[n]!['strand'] == 'wr' || skills[n]!['strand'] == 'wri'),
      );
      if (!hasTrace) say(file, 'prerequisites', 'a writing node needs the trace node of its group');
      if (!hasFacet) {
        say(
          file,
          'prerequisites',
          'a writing node needs the knowledge skill of its letters (a memory cue is a sound or a name)',
        );
      }
    }
  });

  _pacing(course, activities, lessons, skills, say);
}

/// The cue of a memory item is the sound or the name of its letter as the letter's intro says them (writing-mastery section 3.4, section 8
/// rule 5): a letter whose name is its sound (the Russian vowels a, u, o) has one memory cue, the sound, and never a `name` item, because that would repeat
/// the same clip. Checked for the letters that have an intro in the pack.
void _cues(Map<String, Map<String, Object?>> activities, Say say) {
  final Map<String, Map<String, Object?>> intros = <String, Map<String, Object?>>{};
  activities.forEach((String id, Map<String, Object?> a) {
    if (isLetterWrite(a) && _map(a['scene'])['mode'] == 'intro') {
      intros[(_map(a['scene'])['forms']! as List<Object?>).first! as String] = _map(
        _map(a['scene'])['intro'],
      );
    }
  });
  activities.forEach((String id, Map<String, Object?> a) {
    if (!isLetterWrite(a) || _map(a['scene'])['mode'] != 'memory') return;
    final String file = 'activity.$id.json';
    final List<Object?> forms = _map(a['scene'])['forms']! as List<Object?>;
    final Map<String, Object?>? intro = forms.length == 1 ? intros[forms.first] : null;
    final Object? target = _map(a['prompt'])['target'];
    if (intro == null || target == null) return;
    final String? cue = _map(a['scene'])['cue'] as String?;
    if (cue == null) return; // the missing cue is the activity's own rule
    if (cue == 'name' && intro['name'] == intro['sound']) {
      say(
        file,
        'scene.cue',
        'the name of ${forms.first} is its sound (one clip): it has a sound cue only, a name cue would repeat the clip',
      );
    } else if (target != intro[cue]) {
      say(file, 'prompt.target', 'is not the $cue the intro of ${forms.first} says ("${intro[cue]}")');
    }
  });
}

/// E-2 inside a group: a visit introduces at most [newLettersPerVisit] letters, starts at most [newSkillsPerVisit] new skills with the
/// bundle of its letters counted as one, and serves a letter only in or after the visit that introduced it. Lessons with no `sequence`
/// have no known place, so they are held only to the first two rules.
void _pacing(
  String course,
  Map<String, Map<String, Object?>> activities,
  Map<String, Map<String, Object?>> lessons,
  Map<String, Map<String, Object?>> skills,
  Say say,
) {
  final int cap = newLettersPerVisit(course);
  final List<MapEntry<String, Map<String, Object?>>> order = lessons.entries.toList()
    ..sort((MapEntry<String, Map<String, Object?>> x, MapEntry<String, Map<String, Object?>> y) {
      final int c = ((x.value['sequence'] as int?) ?? 1 << 30).compareTo(
        (y.value['sequence'] as int?) ?? 1 << 30,
      );
      return c != 0 ? c : x.key.compareTo(y.key);
    });
  String unitOf(String skill) => (skills[skill]?['bundle'] as String?) ?? skill;

  final Set<String> seenUnits = <String>{};
  final Map<String, int> introducedAt = <String, int>{}; // form id -> the lesson's index in [order]
  for (final (int at, MapEntry<String, Map<String, Object?>> l) in order.indexed) {
    final String file = 'lesson.${l.key}.json';
    final List<String> items = <String>[
      for (final Object? i in l.value['items']! as List<Object?>) i! as String,
    ];
    final List<Map<String, Object?>> intros = <Map<String, Object?>>[
      for (final String i in items)
        if (activities[i] != null &&
            isLetterWrite(activities[i]!) &&
            _map(activities[i]!['scene'])['mode'] == 'intro')
          activities[i]!,
    ];
    if (intros.length > cap) {
      say(
        file,
        'items',
        'introduces ${intros.length} letters: at most $cap a visit in the $course course (E-2, so that a visit stays one bundle step)',
      );
    }
    // New skills: those not met in an earlier visit, a bundle counted once, plus the bundle of the letters introduced here.
    final Set<String> units = <String>{};
    for (final Object? s in l.value['skills']! as List<Object?>) {
      final String unit = unitOf(s! as String);
      if (!seenUnits.contains(unit)) units.add(unit);
    }
    for (final Map<String, Object?> a in intros) {
      final String skill = _maps(a['skills']).first['id']! as String;
      units.add(unitOf(skill));
    }
    if (units.length > newSkillsPerVisit) {
      say(
        file,
        'skills',
        'starts ${units.length} new skills ($units): at most $newSkillsPerVisit a visit, the bundle of a letter group counting as one',
      );
    }
    seenUnits.addAll(units);
    for (final Map<String, Object?> a in intros) {
      final String form = (_map(a['scene'])['forms']! as List<Object?>).first! as String;
      introducedAt.putIfAbsent(form, () => at);
    }
  }
  // An item of a letter comes only in or after the visit of its introduction (lessons with a place on the path only).
  for (final (int at, MapEntry<String, Map<String, Object?>> l) in order.indexed) {
    if (l.value['sequence'] == null) continue;
    final String file = 'lesson.${l.key}.json';
    for (final (int i, Object? id) in (l.value['items']! as List<Object?>).indexed) {
      final Map<String, Object?>? a = activities[id];
      if (a == null || !isLetterWrite(a) || _map(a['scene'])['mode'] == 'intro') continue;
      for (final Object? f in _map(a['scene'])['forms']! as List<Object?>) {
        final int? first = introducedAt[f];
        if (first != null && first > at) {
          say(file, 'items[$i]', 'writes $f before the visit that introduces it');
        }
      }
    }
  }
}
