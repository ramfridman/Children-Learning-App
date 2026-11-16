// The content rules of the lesson arc of the lands (M11 Stage 2, docs/milestones/M11-stage2.md sections 2, 4.4, 5 and 7.2): a Show before the
// first scored item, the lead of a Together item, the cap on picking, a second tag on every move that can show one, a hint 2 that does not
// repeat the question's own representation, and a lesson pool that holds the rungs the fade rule needs. They run over a pack of the lands after
// the schemas and the single-file rules. A language course has no arc (the rules do not run for it), and a domain whose lessons are not in
// parts yet (a land that is still to be re-cut) is not asked for them: [arcDomains] says which are.
//
// Pure functions of the documents. The rules V1 to V7 and the warning W1 are the spec's names.

import 'dart:math' as math;

import '../strings/niqqud.dart';
import 'hint_ladder.dart';
import 'pay_way.dart';
import 'w1_words.dart';

typedef ArcSay = void Function(String file, String path, String message);

Map<String, Object?> _map(Object? v) => v is Map<String, Object?> ? v : const <String, Object?>{};

List<Map<String, Object?>> _maps(Object? v) => <Map<String, Object?>>[
  for (final Object? e in (v as List<Object?>? ?? const <Object?>[]))
    if (e is Map<String, Object?>) e,
];

List<Object?> _list(Object? v) => v as List<Object?>? ?? const <Object?>[];

List<String> _strings(Object? v) => <String>[
  for (final Object? e in (v as List<Object?>? ?? const <Object?>[]))
    if (e is String) e,
];

/// The domains whose lessons are played in parts. A land is added when its re-cut and its Shows are done (2.4a Shape Forest; 2.4b to 2.4e the
/// others): from then on every rule below holds for all of its lessons and skills.
///
/// All six lands are in since 2026-11-16: `numbers` (Counting Hills), `math` (Market), `colors` (Colour Bay), `logic` (Riddle Grotto) and `cs` (Robot Harbour) joined
/// Shape Forest once V1 to V7 were clean for them (W1 is a warning: see [metBeforeAsked]).
const Set<String> arcDomains = <String>{'shapes', 'numbers', 'math', 'colors', 'logic', 'cs'};

/// The lands where W1 (a word asked before a Show teaches it) refuses a pack: Shape Forest only. For the other five it is a warning that the tests count
/// (the pin falls, never rises) until the owner confirms the two provisional rules of `w1_words.dart`; then they join this set.
const Set<String> w1Domains = <String>{'shapes'};

/// Every land that has a room (the six).
const Set<String> allArcDomains = <String>{'shapes', 'numbers', 'math', 'colors', 'logic', 'cs'};

/// The lessons of the arc domains that stay a flat list for now, each with what it waits for: a lesson whose Show waits says so itself (`partsWait`,
/// written by the arc build from the Show it could not build), so no hand list is kept. V1 asks of a lesson of an arc domain either `parts` or this.
Map<String, String> lessonsWaiting(Map<String, Map<String, Object?>> lessons) => <String, String>{
  for (final MapEntry<String, Map<String, Object?>> l in lessons.entries)
    if (l.value['parts'] == null && l.value['partsWait'] is String) l.key: l.value['partsWait']! as String,
};

/// Skills that wait for a template that does not exist yet (M11-stage2 section 4.4): their picking is not counted against the caps, and each
/// names what it waits for.
const Map<String, String> pickCapExempt = <String, String>{
  'NUM-A-11': 'Stage 3.1 (two ten-frames as rows)',
  'NUM-A-12': 'Stage 3.1 (two ten-frames as rows)',
  'NUM-A-13': 'Stage 3.2 (order cards)',
  'NUM-A-14': 'Stage 3.1',
  'MATH-A-01': 'Stage 3.1',
  'MATH-A-02': 'Stage 3.1',
  'MATH-B-07': 'Stage 3.1',
  'COL-B-01': 'Stage 3.4 (mix the colours)',
  'SHP-A-08': 'step 2.2c (a drag in listen_do)',
  'LOG-B-02': 'step 2.2c (build_pattern with a model longer than its places)',
  'CS-B-04': 'step 2.2c (robot_path with given steps)',
};

/// The skills where picking is the act (M11 criterion 6): they may be up to 80% picks.
const Set<String> recognitionSkills = <String>{
  'NUM-A-05',
  'NUM-A-08',
  'NUM-A-10',
  'NUM-B-06',
  'NUM-B-08',
  'COL-A-01',
  'SHP-A-02',
  'LOG-A-02',
  'LOG-B-06',
  'LOG-B-09',
  'MATH-B-16',
};

/// Skills with symbols (rung 2 is wanted in every lesson pool, V7).
bool skillHasSymbols(String skill) => RegExp(r'^(NUM|MATH)-[BC]-').hasMatch(skill);

/// Items whose second tag cannot be an honest one (a false diagnosis is worse than none, the maths check of 2026-11-06), by activity id: what
/// each waits for is in M11-stage2 section 11.2 item 2. A fixed gap must be taken off the list (arc_checks_test.dart pins the list to the
/// failing set of the starter sources).
const Map<String, String> tagWaivers = <String, String>{
  'b.shpb03.1': 'a thin triangle shows no catalogued error: no tag is honest',
  'b.shpb03.3': 'a thin triangle shows no catalogued error: no tag is honest',
  'b.shpb03.5': 'a thin triangle shows no catalogued error: no tag is honest',
  // The other five lands (M11-stage2 section 11.5, content/units/pending/stage2-recuts.json `waivers`): taps that stay with no second honest tag.
  'b.colb03.6':
      'light red asked; no shade of a hue near red exists; the plain purple shows no catalogued error',
  'b.mathb10.4': "equal groups, how many in all: one group's size or a wrong group count has no catalogue tag (a proposal: M-GRP-ONE)",
  'b.mathb10.5': 'as b.mathb10.4',
  'b.mathb10.6': 'as b.mathb10.4',
  'b.mathb10.8': 'as b.mathb10.4 (how many plates)',
  'col.world.banana.ripe':
      'the colour of a ripe banana: green (unripe) shows world knowledge, not a catalogued colour error',
  'col.world.grass': 'the colour of grass: red shows no catalogued error',
  'col.world.sun': 'the colour of the sun: green shows no catalogued error',
  'math.graph.apples': 'a picture graph of equal icons: the shorter column has no honest tag (bigger icons would teach a misleading graph)',
  'math.graph.fish': 'as math.graph.apples',
  'math.graph.stars': 'as math.graph.apples',
  'math.graph.stars2': 'as math.graph.apples',
  'pick.red.flower': 'a hand-made butterflies item: the yellow flower shows no catalogued error',
  // The closing pass (M11-stage2 section 11.5, the same data file): a number or an object asked in a form with no honest second tag.
  'b.numb08.2': "a numeral found among the labelled ticks of a line: the reversal it would show is not on the line (13 and 31 are not on one line from 10 to 20), so the line item checks recognition and the skill's taps carry M-NUM-REV",
  'b.numb08.5': "a numeral found among the labelled ticks of a line: the reversal it would show is not on the line (13 and 31 are not on one line from 10 to 20), so the line item checks recognition and the skill's taps carry M-NUM-REV",
  'b.numb08.7': "a numeral found among the labelled ticks of a line: the reversal it would show is not on the line (13 and 31 are not on one line from 10 to 20), so the line item checks recognition and the skill's taps carry M-NUM-REV",
  'c.numb06.1': "a numeral found among the labelled ticks of a line: the reversal it would show is not on the line (6 and 9 are a turn, not a reversal the line classifiers read), so the line item checks recognition and the skill's taps carry M-NUM-REV",
  'c.numb06.3': "a numeral found among the labelled ticks of a line: the reversal it would show is not on the line (6 and 9 are a turn, not a reversal the line classifiers read), so the line item checks recognition and the skill's taps carry M-NUM-REV",
  'c.numb06.5': "a numeral found among the labelled ticks of a line: the reversal it would show is not on the line (6 and 9 are a turn, not a reversal the line classifiers read), so the line item checks recognition and the skill's taps carry M-NUM-REV",
  'b.numb10.9': 'the symbolic form of NUM-B-10 (two numerals, which is bigger), kept so the core skill has two representations; picking the smaller shows no catalogued error',
  'b.numb10.10': 'the symbolic form of NUM-B-10 (two numerals, which is bigger), kept so the core skill has two representations; picking the smaller shows no catalogued error',
  'c.mathc01.32': "a weighing ends level by construction (the child adds blocks until the scale is level), so a wrong move cannot be told apart: the item carries the idea of \"the same as\" as a concrete rung, and the skill's diagnosis is in its typed and tap items (third pass decision, M11-stage2 §11.7)",
  'c.mathc01.33': "a weighing ends level by construction (the child adds blocks until the scale is level), so a wrong move cannot be told apart: the item carries the idea of \"the same as\" as a concrete rung, and the skill's diagnosis is in its typed and tap items (third pass decision, M11-stage2 §11.7)",
  'c.mathc02.11': "a weighing ends level by construction (the child adds blocks until the scale is level), so a wrong move cannot be told apart: the item carries the idea of \"the same as\" as a concrete rung, and the skill's diagnosis is in its typed and tap items (third pass decision, M11-stage2 §11.7)",
  'c.mathc02.12': "a weighing ends level by construction (the child adds blocks until the scale is level), so a wrong move cannot be told apart: the item carries the idea of \"the same as\" as a concrete rung, and the skill's diagnosis is in its typed and tap items (third pass decision, M11-stage2 §11.7)",
  'c.mathc02.4': "a weighing ends level by construction (the child adds blocks until the scale is level), so a wrong move cannot be told apart: the item carries the idea of \"the same as\" as a concrete rung, and the skill's diagnosis is in its typed and tap items (third pass decision, M11-stage2 §11.7)",
  'c.mathc02.5': "a weighing ends level by construction (the child adds blocks until the scale is level), so a wrong move cannot be told apart: the item carries the idea of \"the same as\" as a concrete rung, and the skill's diagnosis is in its typed and tap items (third pass decision, M11-stage2 §11.7)",
};

/// Skills whose hands-on items have no honest tag to record beyond the one they carry (M11-stage2 section 11.2 item 3).
const Set<String> noSecondTagSkills = <String>{
  'SHP-A-05',
  'SHP-A-07',
  'SHP-A-10',
  'SHP-B-05',
  'SHP-B-06',
  'SHP-B-08',
};

/// A skill whose pool in a lesson lacks a rung because the skill has no such form (V7, M11-stage2 section 11.2 item 4), as `lesson:skill`, and why.
const Map<String, String> rungWaivers = <String, String>{
  'build-with-shapes:SHP-A-06': 'a shape builder is always concrete: no pictorial form',
  'one-shadow:SHP-B-05': 'a shape builder is always concrete: no pictorial form',
  'shapes-make-shapes:SHP-B-06': 'a shape builder is always concrete: no pictorial form',
  'shape-friends:SHP-A-01': 'its items are shape builders, always concrete: no pictorial form',
  'shape-friends-again-1-b15:SHP-A-01': 'its items are shape builders, always concrete: no pictorial form',
  'shape-friends:SHP-A-02':
      'the naming items are pictures to tap; the hands-on form of A-02 is its two tracing lessons',
  'shape-friends-again:SHP-A-02':
      'the naming items are pictures to tap; the hands-on form of A-02 is its two tracing lessons',
  'shape-friends-again-1-b15:SHP-A-02':
      'the naming items are pictures to tap; the hands-on form of A-02 is its two tracing lessons',
  'trace-the-shapes:SHP-A-02': 'a tracing lesson takes its pictorial item from the skills taps',
  'draw-the-shapes:SHP-A-02': 'a tracing lesson takes its pictorial item from the skills taps',
};

/// The templates in which the child makes the answer with its hands (their items have a rung 0, and a second tag to record).
const Set<String> handsOnTemplates = <String>{
  'sort_drag',
  'shape_builder',
  'give_n',
  'build_pattern',
  'balance',
  'number_line',
  'shop_pay',
  'robot_path',
  'count_tap',
  'clock_set',
  'trace',
};

/// The templates that have a Show player, and (but for the clock, which has nothing to lead) a lead player: the host does the first steps of the item
/// itself (M11-stage2 section 2.1).
const Set<String> leadTemplates = <String>{
  'sort_drag',
  'shape_builder',
  'trace',
  'number_line',
  'give_n',
  'count_tap',
  'build_pattern',
  'balance',
  'shop_pay',
  'robot_path',
  'clock_set',
};

/// The move words of the steps of a Show on each template that has no side or place of its own to check (see `ShowStep`): a step carries one of
/// them (a pattern's step carries both of its pair).
const Map<String, List<String>> showMoveWords = <String, List<String>>{
  'number_line': <String>['hop', 'point', 'place'],
  'give_n': <String>['move'],
  'count_tap': <String>['touch'],
  'build_pattern': <String>['cell', 'piece'],
  'balance': <String>['block', 'put'],
  'shop_pay': <String>['coin'],
  'robot_path': <String>['arrow'],
  'clock_set': <String>['to'],
};

/// The most host lines of a Show.
const int showMaxLines = 3;

/// The rung of an item by its representation (M11-stage2 section 5): objects moved and the body are 0, pictures and stories 1, symbols 2.
int rungOfRepresentation(String? representation) => switch (representation) {
  'concrete' || 'embodied' => 0,
  'pictorial' || 'story' => 1,
  _ => 2,
};

/// Whether an activity is a pick (M11 criterion 6): a tap on one of the choices, a match, a spot-the-mistake, a flash. A keypad answer is not.
bool isPickOnly(Map<String, Object?> a) => switch (a['template']) {
  'tap_answer' => _map(a['answer'])['type'] != 'number',
  'match_pairs' || 'spot_error' || 'flash' => true,
  _ => false,
};

/// What a Show's template draws at hint level 1 and 2 as a representation (M11-stage2 section 5.5, the R-codes): the picture a hint draws is
/// another way to see the question, or only a light on its parts. Null: a light, no representation of its own. The rule V5 reads it.
_Rep? _hintRepresentation(HintPicture p) => switch (p) {
  HintPicture.nextPicture ||
  HintPicture.nextOutline ||
  HintPicture.modelCell ||
  HintPicture.towers => _Rep.pictorial,
  HintPicture.firstRound ||
  HintPicture.firstHop ||
  HintPicture.firstArrow ||
  HintPicture.firstCoin => _Rep.concrete,
  HintPicture.goalCard || HintPicture.numeralOnDial => _Rep.symbolic,
  HintPicture.countingAid => _Rep.embodied,
  _ => null,
};

enum _Rep { concrete, pictorial, embodied, symbolic }

/// What the hint 2 of a family draws (M11-stage2 section 11.4): the family is the `<family>` of the hint's clip, `vo:hint.<family>.h2`. A family with no
/// row (and the generic ones, `pick`, `sort`, `spot`, `match`, `sb`) is a light on the parts: no representation of its own, so V5 checks nothing.
const Map<String, String> hintFamilyRepresentation = <String, String>{
  'shp_sides': 'embodied',
  'shp_closed': 'embodied',
  'shp_line': 'embodied',
  'shp_world': 'embodied',
  'shp_sorter': 'embodied',
  'shp_equal': 'concrete',
  'shp_face': 'concrete',
  'shp_roll': 'concrete',
  'shp_solid_roll': 'concrete',
  'shp_square_turn': 'concrete',
  'shp_triangle': 'pictorial',
  'shp_square_rect': 'pictorial',
  'shp_solid_name': 'pictorial',
  'shp_shadow': 'pictorial',
  'shp_twice': 'pictorial',
};

/// Items whose hint 2 draws the question's own representation by the family table above: a hands-on sort (concrete) whose hint 2 is the push, the turn, the
/// stamp or the sticks (concrete too). Found by V5 when it was keyed by family (M11-stage2 section 11.4); the curriculum-expert decides whether the hint or
/// the item changes. A fixed one must come off the list (arc_checks_test.dart pins the list to the failing set).
const Map<String, String> hintTwoWaivers = <String, String>{
  'shp.any.small.square': 'a concrete sort whose hint 2 family is concrete too (curriculum-expert to decide)',
  'b15.shpa03.1': 'a concrete sort whose hint 2 family is concrete too (curriculum-expert to decide)',
  'b15.shpa03.2': 'a concrete sort whose hint 2 family is concrete too (curriculum-expert to decide)',
  'shp.any.tilt': 'a concrete sort whose hint 2 family is concrete too (curriculum-expert to decide)',
  'shp.solid.stacks.blue':
      'a concrete sort whose hint 2 family is concrete too (curriculum-expert to decide)',
  'shp.solid.which2': 'a concrete sort whose hint 2 family is concrete too (curriculum-expert to decide)',
  'b15.shpa07.2': 'a concrete sort whose hint 2 family is concrete too (curriculum-expert to decide)',
  'shp.solid.real': 'a concrete sort whose hint 2 family is concrete too (curriculum-expert to decide)',
  'shp.solid.rolls.blue': 'a concrete sort whose hint 2 family is concrete too (curriculum-expert to decide)',
  'x.shpb09.2': 'a concrete sort whose hint 2 family is concrete too (curriculum-expert to decide)',
  'x.shpb09.3': 'a concrete sort whose hint 2 family is concrete too (curriculum-expert to decide)',
  'x.shpb09.6': 'a concrete sort whose hint 2 family is concrete too (curriculum-expert to decide)',
  'b.shpb08.6': 'a concrete sort whose hint 2 family is concrete too (curriculum-expert to decide)',
  'b.shpb08.2': 'a concrete sort whose hint 2 family is concrete too (curriculum-expert to decide)',
  'b.shpb03.2': 'a concrete sort whose hint 2 family is concrete too (curriculum-expert to decide)',
  'b.shpb03.4': 'a concrete sort whose hint 2 family is concrete too (curriculum-expert to decide)',
  'b.shpb03.6': 'a concrete sort whose hint 2 family is concrete too (curriculum-expert to decide)',
};

/// The family of a hint's clip (`vo:hint.shp_sides.h2` is `shp_sides`), or null.
String? hintFamilyOf(Object? vo) {
  final RegExpMatch? m = RegExp(r'^vo:hint\.([a-z0-9_]+)\.h[0-9]$').firstMatch(vo is String ? vo : '');
  return m?.group(1);
}

/// The tags a move of the child can record in [a]: the activity's own and those of its cards, pieces and classifiers.
Set<String> recordableTags(Map<String, Object?> a) {
  final Map<String, Object?> answer = _map(a['answer']);
  final Set<String> out = <String>{};
  void take(Object? t) {
    if (t is String && t.isNotEmpty) out.add(t);
  }

  answer.forEach((String k, Object? v) {
    if (k == 'misconception' || k.endsWith('Misconception') || k.endsWith('Tag')) take(v);
  });
  for (final String list in <String>['classifiers', 'pieceTags', 'options']) {
    for (final Map<String, Object?> e in _maps(answer[list])) {
      take(e['misconception']);
    }
  }
  for (final Map<String, Object?> i in _maps(_map(a['scene'])['items'])) {
    take(i['misconception']);
  }
  return out;
}

/// The tags of the wrong options of a tap (the right one never has one).
List<String?> _distractorTags(Map<String, Object?> a) {
  final Map<String, Object?> answer = _map(a['answer']);
  return <String?>[
    for (final Map<String, Object?> o in _maps(answer['options']))
      if (o['id'] != answer['correct']) o['misconception'] as String?,
  ];
}

/// The rules of one Show (a document with `purpose: show`) and of the `show` block (V2): the schema has bounded its shape already.
void checkShowActivity(String file, Map<String, Object?> a, ArcSay say) {
  final Map<String, Object?>? show = a['show'] is Map<String, Object?>
      ? a['show']! as Map<String, Object?>
      : null;
  final bool isShow = a['purpose'] == 'show';
  if (!isShow && show != null) say(file, 'show', 'only a Show (purpose "show") has a show block');
  if (!isShow) return;
  if (show == null) {
    say(file, 'show', 'a Show has its lines and steps in a show block');
    return;
  }
  if (_maps(a['hints']).isNotEmpty) {
    say(file, 'hints', 'a Show has no hints: the host does the example and the child needs no help');
  }
  final String? template = a['template'] as String?;
  if (!leadTemplates.contains(template)) {
    say(
      file,
      'template',
      'a Show plays on a hands-on template that has a lead player (sort_drag, shape_builder or trace), not on $template',
    );
    return;
  }
  final List<Map<String, Object?>> lines = _maps(show['lines']);
  if (lines.length > showMaxLines) say(file, 'show.lines', 'a Show has at most $showMaxLines host lines');
  final Set<String> roles = <String>{for (final Map<String, Object?> l in lines) l['role']! as String};
  for (final String need in <String>['key', 'handover']) {
    if (!roles.contains(need)) say(file, 'show.lines', 'needs a line with the role "$need"');
  }
  final List<Map<String, Object?>> steps = _maps(show['steps']);
  final int children = steps.where((Map<String, Object?> s) => s['by'] == 'child').length;
  if (children != 1 || steps.isEmpty || steps.last['by'] != 'child') {
    say(
      file,
      'show.steps',
      'the host stops before the last step and the child makes it: exactly one child step, and it is the last',
    );
  }
  if (steps.where((Map<String, Object?> s) => s['say'] == 'key').length > 1) {
    say(file, 'show.steps', 'the key line is said at one step only');
  }
  final Map<String, Object?> scene = _map(a['scene']);
  if (template == 'sort_drag') {
    final Map<String, String?> binOf = <String, String?>{
      for (final Map<String, Object?> i in _maps(scene['items'])) i['id']! as String: i['bin'] as String?,
    };
    final Set<String> seen = <String>{};
    for (final (int i, Map<String, Object?> s) in steps.indexed) {
      final Object? item = s['item'];
      if (item is! String || !binOf.containsKey(item)) {
        say(file, 'show.steps[$i].item', 'must be a card of the scene');
      } else {
        if (!seen.add(item)) say(file, 'show.steps[$i].item', 'a card is moved once');
        if (s['bin'] != binOf[item]) say(file, 'show.steps[$i].bin', 'a Show puts a card in its own bin');
      }
    }
    if (seen.length != binOf.length) {
      say(
        file,
        'show.steps',
        'the steps move every card of the scene, so that the child\'s step finishes the sort',
      );
    }
  } else if (template == 'trace') {
    // A tracing Show draws the sides of its path in order; the host draws all but the last, which the child traces.
    final int sides = traceSideCount(_list(scene['strokes']));
    for (final (int i, Map<String, Object?> s) in steps.indexed) {
      if (s['segment'] != i + 1) {
        say(
          file,
          'show.steps[$i].segment',
          'the steps are the sides of the path in order, from 1 (found ${s['segment']})',
        );
      }
    }
    if (steps.length != sides) {
      say(
        file,
        'show.steps',
        'the steps are every side of the path, so that the child\'s step finishes the tracing ($sides sides, ${steps.length} steps)',
      );
    }
  } else if (showMoveWords.containsKey(template)) {
    final List<String> words = showMoveWords[template]!;
    for (final (int i, Map<String, Object?> s) in steps.indexed) {
      final bool ok = template == 'build_pattern'
          ? words.every(s.containsKey)
          : words.any((String w) => s.containsKey(w));
      if (!ok) {
        say(file, 'show.steps[$i]', 'a step of a $template Show carries its move word (${words.join(', ')})');
      }
    }
    if (template == 'build_pattern') {
      final int slots = (scene['slots'] as int?) ?? 0;
      final Set<int> laid = <int>{for (final Map<String, Object?> s in steps) ?(s['cell'] as int?)};
      final Set<int> given = <int>{
        for (final Map<String, Object?> g in _maps(scene['given'])) g['cell']! as int,
      };
      for (final (int i, Map<String, Object?> s) in steps.indexed) {
        if (((s['cell'] as int?) ?? 0) >= slots) {
          say(file, 'show.steps[$i].cell', 'must be a place of the row');
        }
      }
      if (laid.union(given).length != slots) {
        say(file, 'show.steps', 'the given cells and the steps fill every place of the row');
      }
    }
    if (template == 'number_line' && steps.last['place'] == null && steps.last['hop'] == null) {
      say(file, 'show.steps', 'the child\'s step on a line is a hop or a place');
    }
  } else {
    final Map<String, String> spriteOf = <String, String>{
      for (final Map<String, Object?> s in _maps(scene['slots'])) s['id']! as String: s['sprite']! as String,
    };
    final Set<String> seen = <String>{};
    for (final (int i, Map<String, Object?> s) in steps.indexed) {
      final Object? slot = s['slot'];
      if (slot is! String || !spriteOf.containsKey(slot)) {
        say(file, 'show.steps[$i].slot', 'must be a place of the picture');
      } else if (!seen.add(slot)) {
        say(file, 'show.steps[$i].slot', 'a place is filled once');
      }
      final Object? piece = s['piece'];
      final bool inTray =
          piece is String && (spriteOf.values.contains(piece) || _strings(scene['decoys']).contains(piece));
      if (!inTray) say(file, 'show.steps[$i].piece', 'must be a piece of the tray');
    }
    if (seen.length != spriteOf.length) {
      say(file, 'show.steps', 'the steps fill every place, so that the child\'s step finishes the picture');
    }
  }
}

/// The steps an item gives the host to lead (sort: its cards, shape builder: its places, trace: the sides of its path); null for a template with
/// no lead player.
int? leadableSteps(Map<String, Object?> a) {
  final Map<String, Object?> scene = _map(a['scene']);
  final Map<String, Object?> answer = _map(a['answer']);
  final int? steps = switch (a['template']) {
    'sort_drag' => _maps(scene['items']).length,
    'shape_builder' => _maps(scene['slots']).length,
    'trace' => traceSideCount(_list(scene['strokes'])),
    // the hops of a jump (a place on a line has none)
    'number_line' => answer['mode'] == 'jump' ? _list(scene['hops']).length : null,
    // the objects the child adds, the touches, the blocks of a weighing (a comparison has none), the arrows of the way
    'give_n' => answer['n'] as int?,
    'count_tap' => _map(scene['objects'])['count'] as int?,
    'balance' => answer['mode'] == 'balance' ? int.tryParse('${answer['result']}') : null,
    'robot_path' => _list(answer['solution']).length,
    // the places of a pattern that the child fills: not the given ones that are right
    'build_pattern' => () {
      final Map<int, Object?> given = <int, Object?>{
        for (final Map<String, Object?> g in _maps(scene['given'])) g['cell']! as int: g['face'],
      };
      final List<Object?> row = _list(answer['sequence']);
      return <int>[
        for (int i = 0; i < row.length; i++)
          if (given[i] != row[i]) i,
      ].length;
    }(),
    'shop_pay' => fewestCoinWay(_map(a['scene'])['price'] as int, <String>[
      for (final Map<String, Object?> p in _maps(scene['purse']))
        for (int i = 0; i < (p['count']! as int); i++) p['kind']! as String,
    ]).length,
    _ => null,
  };
  // One step cannot be led and still leave the child one.
  return steps == null || steps < 2 ? null : steps;
}

/// How many sides the host draws one at a time on a tracing: for each stroke, its parts corner to corner when it has few points (a polygon: 8 at the
/// most), else four parts of equal length (a circle in quarters). The app's `traceSides` makes the same parts from the same rule.
int traceSideCount(List<Object?> strokes) {
  int n = 0;
  for (final Object? s in strokes) {
    final int points = _list(s).length;
    n += points <= maxCornerPoints ? points - 1 : quarterSides;
  }
  return n;
}

/// The most points of a stroke that are still read as corners; a stroke with more is a curve, drawn in [quarterSides] parts.
const int maxCornerPoints = 8;
const int quarterSides = 4;

/// The rules that look at lessons and skills together (V1, V3 to V7). [activities], [lessons] and [skills] are the valid documents of a pack of
/// the lands, by id.
void checkArc({
  required Map<String, Map<String, Object?>> activities,
  required Map<String, Map<String, Object?>> lessons,
  required Map<String, Map<String, Object?>> skills,
  required ArcSay say,
  Map<String, String> tagWaived = tagWaivers,
  Set<String> domains = arcDomains,
}) {
  // A pack made before the arc (no lesson in parts) is checked as it always was: the arc rules are for the packs that have it.
  if (!lessons.values.any((Map<String, Object?> l) => l['parts'] != null)) return;
  bool inArc(Map<String, Object?> lesson) =>
      _strings(lesson['skills']).any((String s) => domains.contains(skills[s]?['domain']));
  final List<String> arcLessons = <String>[
    for (final MapEntry<String, Map<String, Object?>> l in lessons.entries)
      if (inArc(l.value)) l.key,
  ];
  final Map<String, List<String>> showsOf = <String, List<String>>{};
  final Map<String, List<String>> showsOfTemplate = <String, List<String>>{};
  for (final MapEntry<String, Map<String, Object?>> e in activities.entries) {
    if (e.value['purpose'] != 'show') continue;
    final String skill = _map(_maps(e.value['skills']).first)['id']! as String;
    showsOf.putIfAbsent(skill, () => <String>[]).add(e.key);
    showsOfTemplate.putIfAbsent('$skill ${e.value['template']}', () => <String>[]).add(e.key);
  }

  // ---- V1, V3: the lessons ----
  final Set<String> skillsInParts = <String>{};
  for (final String id in arcLessons) {
    final Map<String, Object?> l = lessons[id]!;
    final String file = 'lesson.$id.json';
    final Map<String, Object?>? parts = l['parts'] is Map<String, Object?>
        ? l['parts']! as Map<String, Object?>
        : null;
    if (parts == null) {
      if (l['partsWait'] is! String) {
        say(
          file,
          'parts',
          'a lesson of a land in a room is in parts (V1): a Show first, then Together, Alone and Use; or it says what its Show waits for (partsWait)',
        );
      }
      continue;
    }
    final List<String> own = _strings(l['skills']);
    skillsInParts.addAll(own);
    final List<String> items = _strings(l['items']);
    void showOf(String path, Object? ref) {
      final Map<String, Object?>? a = ref is String ? activities[ref] : null;
      if (a == null || a['purpose'] != 'show') {
        say(file, path, '"$ref" is not a Show (an activity with purpose "show")');
      } else if (!own.contains(_map(_maps(a['skills']).first)['id'])) {
        say(file, path, '"$ref" is the Show of another skill than the lesson\'s');
      }
      if (items.contains(ref)) {
        say(file, path, 'a Show is never among the lesson\'s items: it is played from its part');
      }
    }

    showOf('parts.show', parts['show']);
    // QA-2: a visit is planned from the Alone pool; with none, the planner has nothing to serve and the lesson would be played flat, with no Show.
    if (_strings(parts['alone']).isEmpty) {
      say(
        file,
        'parts.alone',
        'a lesson in parts has at least one Alone item (the visit is planned from the Alone pool; with none the lesson plays flat with no Show)',
      );
    }
    final Object? second = parts['secondShow'];
    if (second is Map<String, Object?>) {
      showOf('parts.secondShow.id', second['id']);
      if (second['id'] == parts['show']) {
        say(file, 'parts.secondShow.id', 'the second Show is another skill\'s');
      }
      if (!items.contains(second['before'])) {
        say(file, 'parts.secondShow.before', '"${second['before']}" is not an item of the lesson');
      }
    }
    for (final String part in <String>['alone', 'use']) {
      for (final (int i, String item) in _strings(parts[part]).indexed) {
        if (!items.contains(item)) {
          say(
            file,
            'parts.$part[$i]',
            '"$item" must also be one of the lesson\'s items (a reader without the parts plays them)',
          );
        }
        if (!own.contains(
          activities[item]?['skills'] is List<Object?>
              ? _map(_maps(activities[item]!['skills']).first)['id']
              : null,
        )) {
          say(file, 'parts.$part[$i]', '"$item" is not an item of the lesson\'s skills');
        }
      }
    }
    for (final (int i, String item) in _strings(parts['recall']).indexed) {
      if (!activities.containsKey(item)) say(file, 'parts.recall[$i]', 'there is no activity "$item"');
    }
    for (final (int i, Map<String, Object?> t) in _maps(parts['together']).indexed) {
      final String path = 'parts.together[$i]';
      final Map<String, Object?>? a = activities[t['id']];
      if (a == null || !items.contains(t['id'])) {
        say(file, '$path.id', '"${t['id']}" is not an item of the lesson');
        continue;
      }
      if (!own.contains(_map(_maps(a['skills']).first)['id'])) {
        say(file, '$path.id', '"${t['id']}" is not an item of the lesson\'s skills');
      }
      final int lead = t['lead']! as int;
      final int? steps = leadableSteps(a);
      if (steps == null) {
        if (lead != 0) {
          say(
            file,
            '$path.lead',
            '${a['template']} has no steps for the host to lead: the lead is 0 and the host only says its line',
          );
        }
      } else if (lead < 1 || lead >= steps) {
        say(file, '$path.lead', 'the host leads at least 1 and fewer than all $steps steps (found $lead)');
      }
    }
  }

  // ---- V2 (across files): a skill in parts has one Show for each template it is shown on, and at least one ----
  for (final String s in skillsInParts) {
    final List<String> all = showsOf[s] ?? const <String>[];
    if (all.isEmpty) say('skill.$s.json', '', 'a skill in a lesson in parts has a Show (V2), found none');
    for (final MapEntry<String, List<String>> e in showsOfTemplate.entries) {
      if (e.key.startsWith('$s ') && e.value.length > 1) {
        say(
          'skill.$s.json',
          '',
          'a skill has one Show for each template (V2), found ${e.value.length} on ${e.key.substring(s.length + 1)}',
        );
      }
    }
  }

  _pickCaps(activities, skills, say, arcLessons, lessons, domains);
  _tags(activities, lessons, arcLessons, skills, say, tagWaived);
  _hintTwo(activities, lessons, arcLessons, say);
  _rungs(activities, lessons, arcLessons, say);
}

/// The activities of the skills of the arc domains that are items (not Shows), by their first skill.
Map<String, List<Map<String, Object?>>> _bySkill(
  Map<String, Map<String, Object?>> activities,
  Iterable<String> skillIds,
) {
  final Set<String> want = skillIds.toSet();
  final Map<String, List<Map<String, Object?>>> out = <String, List<Map<String, Object?>>>{};
  for (final Map<String, Object?> a in activities.values) {
    if (a['purpose'] == 'show') continue;
    final String s = _map(_maps(a['skills']).first)['id']! as String;
    if (want.contains(s)) out.putIfAbsent(s, () => <Map<String, Object?>>[]).add(a);
  }
  return out;
}

/// V4: a skill is over its pick cap (60% in A and B, 70% in C, 80% for the recognition skills), or a land and band is over 50% without the
/// exempt skills.
void _pickCaps(
  Map<String, Map<String, Object?>> activities,
  Map<String, Map<String, Object?>> skills,
  ArcSay say,
  List<String> arcLessons,
  Map<String, Map<String, Object?>> lessons,
  Set<String> domains,
) {
  final Set<String> domainSkills = <String>{
    for (final MapEntry<String, Map<String, Object?>> s in skills.entries)
      if (domains.contains(s.value['domain'])) s.key,
  };
  final Map<String, List<Map<String, Object?>>> by = _bySkill(activities, domainSkills);
  final Map<String, (int, int)> landBand = <String, (int, int)>{};
  for (final MapEntry<String, List<Map<String, Object?>>> e in by.entries) {
    if (pickCapExempt.containsKey(e.key)) continue;
    final int picks = e.value.where(isPickOnly).length;
    final String band = skills[e.key]!['band']! as String;
    final double cap = recognitionSkills.contains(e.key) ? 0.8 : (band == 'C' ? 0.7 : 0.6);
    if (picks > cap * e.value.length + 1e-9) {
      say(
        'skill.${e.key}.json',
        '',
        'V4: $picks of ${e.value.length} items are picks, over the ${(cap * 100).round()}% cap of the skill',
      );
    }
    final String key = '${skills[e.key]!['domain']} $band';
    final (int, int) now = landBand[key] ?? (0, 0);
    landBand[key] = (now.$1 + picks, now.$2 + e.value.length);
  }
  for (final MapEntry<String, (int, int)> e in landBand.entries) {
    if (e.value.$1 > 0.5 * e.value.$2 + 1e-9) {
      say(
        '',
        '',
        'V4: ${e.key}: ${e.value.$1} of ${e.value.$2} items are picks, over 50% (the exempt skills left out)',
      );
    }
  }
}

/// V6 (with the corrections of M11-stage2 section 11.2): a hands-on item of a skill in parts can record at least two tags, a three-option tap
/// has two tagged distractors, a two-option tap has its distractor tagged. [tagWaivers] and [noSecondTagSkills] name what cannot.
void _tags(
  Map<String, Map<String, Object?>> activities,
  Map<String, Map<String, Object?>> lessons,
  List<String> arcLessons,
  Map<String, Map<String, Object?>> skills,
  ArcSay say,
  Map<String, String> waived,
) {
  final Set<String> own = <String>{
    for (final String id in arcLessons)
      if (lessons[id]!['parts'] != null) ..._strings(lessons[id]!['skills']),
  };
  for (final MapEntry<String, Map<String, Object?>> e in activities.entries) {
    final Map<String, Object?> a = e.value;
    if (a['purpose'] == 'show') continue;
    final String skill = _map(_maps(a['skills']).first)['id']! as String;
    if (!own.contains(skill) || waived.containsKey(e.key)) continue;
    final String file = 'activity.${e.key}.json';
    final int listed = _strings(skills[skill]?['misconceptions']).length;
    if (a['template'] == 'tap_answer' && isPickOnly(a)) {
      // The wrong options of the tap: one for a two-option tap, two or more for three options or more. Each must carry a tag; two distractors that
      // carry the same tag are two tagged distractors (M11-stage2 section 11.1).
      final List<String?> wrong = _distractorTags(a);
      final int tagged = wrong.whereType<String>().length;
      if (noSecondTagSkills.contains(skill) || listed == 0) continue;
      if (wrong.length == 1 && wrong.single == null) {
        say(file, 'answer.options', 'V6: a two-option tap tags its distractor');
      } else if (wrong.length >= 2 && tagged < 2) {
        say(
          file,
          'answer.options',
          'V6: a tap of three options or more has two tagged distractors (found $tagged)',
        );
      }
    } else if (handsOnTemplates.contains(a['template']) && a['template'] != 'trace') {
      // A hands-on item can record as many tags as its skill lists, up to two: a skill with one tag (SHP-B-09) needs one.
      if (noSecondTagSkills.contains(skill) || listed == 0) continue;
      final int n = recordableTags(a).length;
      final int need = math.min(2, listed);
      if (n < need) say(file, 'answer', 'V6: a hands-on item can record $need tags (found $n)');
    }
  }
}

/// V5: hint 2 does not draw the question's own representation, nor what hint 1 draws.
void _hintTwo(
  Map<String, Map<String, Object?>> activities,
  Map<String, Map<String, Object?>> lessons,
  List<String> arcLessons,
  ArcSay say,
) {
  final Set<String> ids = <String>{
    for (final String id in arcLessons)
      if (lessons[id]!['parts'] != null) ..._strings(lessons[id]!['items']),
  };
  for (final String id in ids) {
    final Map<String, Object?>? a = activities[id];
    if (a == null || _maps(a['hints']).length < 2 || hintTwoWaivers.containsKey(id)) continue;
    final HintLadder? ladder = HintLadder.of(
      a['template']! as String,
      share: a['template'] == 'sort_drag' && _map(a['answer'])['mode'] == 'share',
    );
    // The family of hint 2 says what it draws; a family with no row is a light, or (for a template whose families are not listed) the ladder's own.
    final String? family = hintFamilyOf(_maps(a['hints'])[1]['vo']);
    final String? named = family == null ? null : hintFamilyRepresentation[family];
    final _Rep? two = named != null
        ? _Rep.values.byName(named)
        : (family != null || ladder == null ? null : _hintRepresentation(ladder.at(2)));
    final _Rep? one = ladder == null ? null : _hintRepresentation(ladder.at(1));
    if (two == null) continue;
    if (two.name == a['representation']) {
      say(
        'activity.$id.json',
        'hints[1]',
        'V5: hint 2 draws ${two.name}, the question\'s own representation',
      );
    }
    if (one == two) say('activity.$id.json', 'hints[1]', 'V5: hint 2 draws what hint 1 draws');
  }
}

/// V7 (corrected, M11-stage2 sections 11.2 item 4 and 11.5): the pool of a lesson holds a rung-0 and a rung-1 item for each of its skills, and a rung-2
/// item where the skill has symbols; a rung that the skill has no item of anywhere in the pack is not asked for (a shape builder is always concrete: it has
/// no pictorial form), so no list of waivers is kept for it; [rungWaivers] names what is left.
void _rungs(
  Map<String, Map<String, Object?>> activities,
  Map<String, Map<String, Object?>> lessons,
  List<String> arcLessons,
  ArcSay say,
) {
  // the rungs each skill has an item of, anywhere in the pack
  final Map<String, Set<int>> existing = <String, Set<int>>{};
  for (final Map<String, Object?> a in activities.values) {
    if (a['purpose'] == 'show') continue;
    existing
        .putIfAbsent(_map(_maps(a['skills']).first)['id']! as String, () => <int>{})
        .add(rungOfRepresentation(a['representation'] as String?));
  }
  for (final String id in arcLessons) {
    final Map<String, Object?> l = lessons[id]!;
    final Map<String, Object?>? parts = l['parts'] as Map<String, Object?>?;
    if (parts == null) continue;
    final Set<String> pool = <String>{
      ..._strings(parts['alone']),
      ..._strings(parts['use']),
      for (final Map<String, Object?> t in _maps(parts['together'])) t['id']! as String,
    };
    for (final String skill in _strings(l['skills'])) {
      if (rungWaivers.containsKey('$id:$skill')) continue;
      final Set<int> rungs = <int>{
        for (final String item in pool)
          if (activities[item] != null && _map(_maps(activities[item]!['skills']).first)['id'] == skill)
            rungOfRepresentation(activities[item]!['representation'] as String?),
      };
      if (rungs.isEmpty) continue;
      for (final int need in <int>[0, 1, if (skillHasSymbols(skill)) 2]) {
        if (!rungs.contains(need) && (existing[skill] ?? const <int>{}).contains(need)) {
          say('lesson.$id.json', 'parts', 'V7: the pool of $skill has no rung-$need item');
        }
      }
    }
  }
}

/// W1 (a warning): a scored item of a skill in parts asks for a word its Show (or an earlier skill's Show) does not teach: it is asked before it is
/// met. What an item asks for is the label of its right option (every option of a number tap, which is weighed whole) and every bin of a sort; the label
/// of a wrong option is never asked for, and offering a non-example before it is taught is the first-attempt diagnosis (M-SHP-CLOSED, M-SHP-PROTO).
/// [activities] and [skills] are the valid documents; the result lists one message per item and word.
List<String> metBeforeAsked({
  required Map<String, Map<String, Object?>> activities,
  required Map<String, Map<String, Object?>> lessons,
  required Map<String, Map<String, Object?>> skills,
  Set<String> domains = w1Domains,
}) {
  String plain(String w) => withoutNiqqud(w).trim();
  final Map<String, Set<String>> taught = <String, Set<String>>{};
  for (final Map<String, Object?> a in activities.values) {
    if (a['purpose'] != 'show') continue;
    taught
        .putIfAbsent(_map(_maps(a['skills']).first)['id']! as String, () => <String>{})
        .addAll(_strings(_map(a['show'])['teaches']).map(plain));
  }
  Set<String> closure(String skill, Set<String> seen) {
    if (!seen.add(skill)) return seen;
    for (final Map<String, Object?> p in _maps(skills[skill]?['prerequisites'])) {
      closure(p['skill']! as String, seen);
    }
    return seen;
  }

  final Set<String> own = <String>{
    for (final Map<String, Object?> l in lessons.values)
      if (l['parts'] != null)
        for (final String s in _strings(l['skills']))
          if (domains.contains(skills[s]?['domain'])) s,
  };
  final List<String> out = <String>[];
  for (final MapEntry<String, Map<String, Object?>> e in activities.entries) {
    final Map<String, Object?> a = e.value;
    if (a['purpose'] == 'show') continue;
    final String skill = _map(_maps(a['skills']).first)['id']! as String;
    if (!own.contains(skill)) continue;
    final Set<String> skillsKnown = closure(skill, <String>{});
    final Set<String> ok = <String>{for (final String s in skillsKnown) ...?taught[s]};
    final Set<String> knownWords = <String>{for (final String t in ok) ...t.split(RegExp(r'\s+'))};
    // Counting words: one to ten when the skill's prerequisites hold counting to ten, one to five when they hold counting to five only.
    final Set<String> countWords = skillsKnown.contains(w1CountingSkill)
        ? w1CountingWords
        : (skillsKnown.contains(w1CountingFiveSkill) ? w1CountingWordsToFive : const <String>{});
    bool accepted(String label, {String? sprite}) {
      if (ok.contains(label) || w1YesNo.contains(label)) return true;
      final List<String> words = label.split(RegExp(r'\s+'));
      if (words.length > 1 && words.first == w1Not && accepted(words.skip(1).join(' '))) return true;
      if (countWords.contains(words.first) && (words.length == 1 || accepted(words.skip(1).join(' ')))) {
        return true;
      }
      if (w1AcceptKnownWords && words.every(knownWords.contains)) return true;
      return w1AcceptCardObjectName && w1NamesCardObject(sprite);
    }

    final Map<String, Object?> answer = _map(a['answer']);
    final List<Map<String, Object?>> options = _maps(answer['options']);
    final Object? correct = answer['correct'];
    final bool numberTap =
        options.isNotEmpty && options.every((Map<String, Object?> o) => o['numeral'] != null);
    // What the item asks for, with the picture each label stands under (a card's own picture is what a label that only names it is read against).
    final Map<String, String?> labels = <String, String?>{
      for (final Map<String, Object?> o in options)
        if (o['label'] is String &&
            (numberTap || (correct is List ? correct.contains(o['id']) : o['id'] == correct)))
          plain(o['label']! as String): o['sprite'] as String?,
      if (a['template'] == 'sort_drag')
        for (final Map<String, Object?> b in _maps(_map(a['scene'])['bins']))
          if (b['label'] is String) plain(b['label']! as String): b['sprite'] as String?,
    };
    for (final MapEntry<String, String?> w in labels.entries.where(
      (MapEntry<String, String?> l) => !accepted(l.key, sprite: l.value),
    )) {
      out.add(
        'W1: ${e.key} labels an option "${w.key}" that the Show of $skill (and of its earlier skills) does not teach',
      );
    }
  }
  return out;
}
