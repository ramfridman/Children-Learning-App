// The content rules of the modes that L5-1 adds to LS01 (docs/milestones/L5.md section 5.1, docs/design/languages-l5-ls01.md): text faces in
// sort, match, spot and order; sound cards in a sort; tap-all; a text stem; a cloze; a sequence (the story line). They run for every
// activity of a pack after the schema and the template's own checks. In a pack of the lands they only refuse: none of these modes is
// there. Pure functions of the documents; they know no font, so what a text needs in room is the fit test's (test/text_fit_test.dart).

typedef Ls01Say = void Function(String file, String path, String message);
typedef Ls01Check = void Function(String file, String path, Object? ref);

Map<String, Object?> _map(Object? v) => v is Map<String, Object?> ? v : const <String, Object?>{};

List<Map<String, Object?>> _maps(Object? v) => <Map<String, Object?>>[
  for (final Object? e in (v as List<Object?>? ?? const <Object?>[]))
    if (e is Map<String, Object?>) e,
];

/// An option with no clip, in an item whose options play their own sound (LS01 b): the look-alike tile of a letter not yet taught. It shows no
/// speaker and plays nothing, so the child hears no untaught letter by accident (frame section 5.3). It is allowed only as a distractor with a tag
/// of the family SHAPE, and the feedback then has a line for that tag, which never points at a sound that is not there. Items whose options never
/// sound are unchanged.
void _clipless(
  String file,
  Map<String, Object?> a,
  Map<String, Object?> answer,
  Ls01Say say,
  String? Function(String tag)? familyOf,
) {
  final List<Map<String, Object?>> options = _maps(answer['options']);
  if (answer['type'] == 'none' || !options.any((Map<String, Object?> o) => o['clip'] != null)) return;
  final Object? correct = answer['correct'];
  final List<Object?> right = correct is List<Object?> ? correct : <Object?>[correct];
  final List<Map<String, Object?>> rules = _maps(_map(a['feedback'])['incorrect']);
  for (final (int i, Map<String, Object?> o) in options.indexed) {
    if (o['clip'] != null) continue;
    final String path = 'answer.options[$i]';
    final Object? tag = o['misconception'];
    if (right.contains(o['id'])) {
      say(
        file,
        '$path.clip',
        'the right option has no sound: an item whose options play their sounds gives every right option its clip',
      );
    } else if (tag is! String || familyOf?.call(tag) != 'SHAPE') {
      say(
        file,
        '$path.clip',
        'has no sound while its neighbours have: only a look-alike tile (a tag of the family SHAPE) goes without',
      );
    } else if (!rules.any((Map<String, Object?> r) => r['when'] == 'misconception:$tag')) {
      say(
        file,
        'feedback.incorrect',
        'needs a line for $tag: the tile has no sound, so the default line must not say "that is ..."',
      );
    }
  }
}

/// The most cards of a tap-all, whatever the board: the phone SE holds 4 in the answer zone and 1 beside the target's speaker
/// (docs/design/languages-l5-ls01.md section 7.7, corrected 2026-11-06).
const int tapAllMaxCards = 5;

/// The most places of a scored story line, by the band of the item: 3 in Band A (HEB-A-13), 4 in Bands B and C (a page of 16:9 is
/// 105 by 59 points on the phone SE with four of them, and a fifth would be 80 by 45; section 7.10).
int sequenceMaxPlaces(Object? band) => band == 'A' ? 3 : 4;

/// The most pairs of a pairs item played one at a time (the partners are a tap row): 3 in Band A, 4 in Bands B and C.
int pairsMax(Object? band) => band == 'A' ? 3 : 4;

/// The most text cells of a spot item (section 7.5): 3 in Band A, 4 after.
int spotCellsMax(Object? band) => band == 'A' ? 3 : 4;

/// The most cards of a sort (the tray shows as many as fit and the rest wait in a pile; section 7.2).
const int sortMaxCards = 6;

/// How the item looks to a child, as one string: the same string is a face that cannot be told from another.
String faceLook({Object? sprite, Object? text, Object? clip, Object? numeral, Object? coin}) {
  final bool faceless = sprite == null && text == null && numeral == null && coin == null;
  return '$sprite|$text|$numeral|$coin${faceless ? '|$clip' : ''}';
}

/// Checks the L5-1 modes of the activity [a] (a document of [file]). [language] is false in a pack of the lands.
void checkLs01(
  String file,
  Map<String, Object?> a, {
  required bool language,
  required Ls01Say say,
  required Ls01Check checkAsset,
  required Ls01Check checkVo,
  required Ls01Check checkTag,
  String? Function(String tag)? familyOf,
}) {
  final Map<String, Object?> scene = _map(a['scene']);
  final Map<String, Object?> answer = _map(a['answer']);
  if (!language) {
    _refuseInLands(file, a, scene, answer, say);
    return;
  }
  switch (a['template']) {
    case 'tap_answer':
      _tap(file, a, scene, answer, say, checkAsset, checkVo, familyOf);
    case 'sort_drag':
      _sort(file, a, scene, answer, say, checkAsset, checkVo, checkTag);
    case 'match_pairs':
      _pairs(file, a, scene, answer, say, checkAsset, checkTag);
    case 'spot_error':
      _spot(file, a, scene, answer, say, checkAsset, checkVo);
    case 'build_pattern':
      _pattern(file, a, scene, answer, say, checkVo);
  }
}

// ---- the lands ----

void _refuseInLands(
  String file,
  Map<String, Object?> a,
  Map<String, Object?> scene,
  Map<String, Object?> answer,
  Ls01Say say,
) {
  const String why = 'belongs to a language course, not to the lands';
  switch (a['template']) {
    case 'tap_answer':
      for (final String k in <String>['stem', 'cloze']) {
        if (scene.containsKey(k)) say(file, 'scene.$k', why);
      }
      if (answer.containsKey('all')) say(file, 'answer.all', why);
      if (answer['correct'] is List<Object?>) say(file, 'answer.correct', 'a list of right options $why');
      // Five choices belong to Band C of the lands (pack_validation.dart); anywhere else more than four are a language course's.
      if (_maps(answer['options']).length > 4 && a['band'] != 'C') {
        say(file, 'answer.options', 'more than four options $why');
      }
    case 'sort_drag':
      for (final (String list, List<Map<String, Object?>> faces) in <(String, List<Map<String, Object?>>)>[
        ('bins', _maps(scene['bins'])),
        ('items', _maps(scene['items'])),
      ]) {
        for (final (int i, Map<String, Object?> f) in faces.indexed) {
          for (final String k in <String>['text', 'clip', 'misconception', 'alt']) {
            if (f.containsKey(k)) say(file, 'scene.$list[$i].$k', why);
          }
          if (f['sprite'] == null) say(file, 'scene.$list[$i].sprite', 'is missing: a picture');
        }
      }
    case 'match_pairs':
      for (final String side in <String>['left', 'right']) {
        for (final (int i, Map<String, Object?> f) in _maps(scene[side]).indexed) {
          for (final String k in <String>['text', 'clip', 'misconception', 'alt']) {
            if (f.containsKey(k)) say(file, 'scene.$side[$i].$k', why);
          }
        }
      }
    case 'spot_error':
      if (scene.containsKey('model')) say(file, 'scene.model', why);
      for (final (int i, Object? c) in ((scene['cells'] as List<Object?>?) ?? const <Object?>[]).indexed) {
        if (c is String && c.startsWith('txt:')) say(file, 'scene.cells[$i]', 'a text cell $why');
      }
    case 'build_pattern':
      if (answer.containsKey('order')) say(file, 'answer.order', 'a story line $why');
      if (scene.containsKey('clips')) say(file, 'scene.clips', 'the lines of a story line $why');
      for (final String k in <String>['model', 'palette']) {
        for (final (int i, Object? c) in ((scene[k] as List<Object?>?) ?? const <Object?>[]).indexed) {
          if (c is String && c.startsWith('txt:')) say(file, 'scene.$k[$i]', 'a text tile $why');
        }
      }
  }
}

// ---- tap_answer: stem, cloze, tap-all ----

void _tap(
  String file,
  Map<String, Object?> a,
  Map<String, Object?> scene,
  Map<String, Object?> answer,
  Ls01Say say,
  Ls01Check checkAsset,
  Ls01Check checkVo,
  String? Function(String tag)? familyOf,
) {
  _clipless(file, a, answer, say, familyOf);
  final bool stem = scene.containsKey('stem');
  final bool cloze = scene.containsKey('cloze');
  final bool all = answer['all'] == true;
  final Object? correct = answer['correct'];
  final List<Map<String, Object?>> options = _maps(answer['options']);
  if ((stem ? 1 : 0) + (cloze ? 1 : 0) + (all ? 1 : 0) > 1) {
    say(file, 'scene', 'a text stem, a cloze and a tap-all are three modes: an item is one of them');
  }
  if (all != (correct is List<Object?>)) {
    say(
      file,
      'answer.correct',
      all
          ? 'a tap-all lists its right options'
          : 'a list of right options is a tap-all: say `"all": true`, or name the one right option',
    );
  }
  if (options.length > 4 && !all) {
    say(file, 'answer.options', '${options.length} options: only a tap-all has more than four');
  }
  if (stem) {
    final Map<String, Object?> s = _map(scene['stem']);
    checkVo(file, 'scene.stem.clip', s['clip']);
    // "Read it to me" is hint level 1 and lowers the credit to 0.8 (L5 section 5.1).
    final List<Object?> credit =
        _map(a['scoring'])['creditByHintLevel'] as List<Object?>? ?? const <Object?>[];
    if (s['clip'] != null && credit.length > 1 && (credit[1] as num) != 0.8) {
      say(
        file,
        'scoring.creditByHintLevel',
        'a stem has "read it to me" as its first hint, which lowers the credit to 0.8 (found ${credit[1]})',
      );
    }
  }
  if (cloze) {
    final Map<String, Object?> c = _map(scene['cloze']);
    final String text = (c['text'] as String?) ?? '';
    final int gaps = '_'.allMatches(text).length;
    if (gaps != 1) {
      say(file, 'scene.cloze.text', 'has $gaps gaps (`_`): a cloze has one gap');
    } else if (text.trim() == '_') {
      say(file, 'scene.cloze.text', 'is only the gap: the sentence has other words');
    }
    checkAsset(file, 'scene.cloze.picture', c['picture']);
    if (options.length != 3) {
      say(file, 'answer.options', 'a cloze has 3 word tiles (found ${options.length})');
    }
    for (final (int i, Map<String, Object?> o) in options.indexed) {
      if (o['text'] == null || o['sprite'] != null) {
        say(file, 'answer.options[$i]', 'a word tile of a cloze is a text');
      }
    }
  }
  if (all) {
    final List<Object?> right = correct is List<Object?> ? correct : const <Object?>[];
    if (options.length > tapAllMaxCards) {
      say(file, 'answer.options', 'a tap-all has at most $tapAllMaxCards cards (found ${options.length})');
    }
    // With one right card the item would check itself at the first tap: that is a plain choice, not a tap-all (curriculum section 11.1, answer 2).
    if (right.length < 2) {
      say(file, 'answer.correct', 'a tap-all has at least two right cards (found ${right.length})');
    }
    if (options.length - right.length < 2) {
      say(file, 'answer.options', 'a tap-all has at least two wrong cards, each with its tag');
    }
    // Cards that look the same (three t's among other letters) are one answer or the other, never both.
    final Map<String, bool> sides = <String, bool>{};
    for (final (int i, Map<String, Object?> o) in options.indexed) {
      final String look = faceLook(
        sprite: o['sprite'],
        text: o['text'],
        clip: o['clip'],
        numeral: o['numeral'],
      );
      final bool isRight = right.contains(o['id']);
      final bool? seen = sides[look];
      if (seen != null && seen != isRight) {
        say(
          file,
          'answer.options[$i]',
          'looks like a card on the other side (right and wrong): a child could not tell them',
        );
      }
      sides[look] = isRight;
    }
  }
}

// ---- sort ----

/// A sign or a card of a language course: exactly one of a picture or a text, or only a sound; a clip may go with either.
void _faceKind(String file, String path, Map<String, Object?> f, Ls01Say say) {
  final int faces = <String>['sprite', 'text'].where(f.containsKey).length;
  if (faces > 1 || (faces == 0 && !f.containsKey('clip'))) {
    say(file, path, 'must be exactly one of a picture or a text, or only a clip (a sound)');
  }
}

void _sort(
  String file,
  Map<String, Object?> a,
  Map<String, Object?> scene,
  Map<String, Object?> answer,
  Ls01Say say,
  Ls01Check checkAsset,
  Ls01Check checkVo,
  Ls01Check checkTag,
) {
  if (answer['mode'] == 'share') {
    say(
      file,
      'answer.mode',
      'sharing between friends is a land\'s sort; a language sort sorts cards into bins',
    );
    return;
  }
  final List<Map<String, Object?>> bins = _maps(scene['bins']);
  final List<Map<String, Object?>> items = _maps(scene['items']);
  if (items.length > sortMaxCards) {
    say(file, 'scene.items', 'a sort has at most $sortMaxCards cards (found ${items.length})');
  }
  for (final (int i, Map<String, Object?> b) in bins.indexed) {
    _faceKind(file, 'scene.bins[$i]', b, say);
    checkVo(file, 'scene.bins[$i].clip', b['clip']);
    checkAsset(file, 'scene.bins[$i].alt', b['alt']);
    if (!items.any((Map<String, Object?> it) => it['bin'] == b['id'])) {
      say(file, 'scene.bins[$i]', 'has no card that belongs in it');
    }
  }
  final Map<String, String?> binOfLook = <String, String?>{};
  final Set<String> binLooks = <String>{};
  for (final (int i, Map<String, Object?> b) in bins.indexed) {
    if (!binLooks.add(faceLook(sprite: b['sprite'], text: b['text'], clip: b['clip']))) {
      say(file, 'scene.bins[$i]', 'looks like another bin');
    }
  }
  for (final (int i, Map<String, Object?> it) in items.indexed) {
    final String path = 'scene.items[$i]';
    _faceKind(file, path, it, say);
    checkVo(file, '$path.clip', it['clip']);
    checkTag(file, '$path.misconception', it['misconception']);
    // Every wrong bin is a mistake with a tag: the card's own, or the item's.
    if (it['misconception'] == null && answer['misconception'] == null) {
      say(
        file,
        '$path.misconception',
        'a card carries the misconception that putting it in a wrong bin shows',
      );
    }
    final String look = faceLook(sprite: it['sprite'], text: it['text'], clip: it['clip']);
    final String? bin = it['bin'] as String?;
    if (binOfLook.containsKey(look) && binOfLook[look] != bin) {
      say(file, path, 'looks like a card that belongs in another bin: a child could not tell them');
    }
    binOfLook[look] = bin;
  }
}

// ---- pairs ----

void _pairs(
  String file,
  Map<String, Object?> a,
  Map<String, Object?> scene,
  Map<String, Object?> answer,
  Ls01Say say,
  Ls01Check checkAsset,
  Ls01Check checkTag,
) {
  final List<Map<String, Object?>> left = _maps(scene['left']);
  final List<Map<String, Object?>> right = _maps(scene['right']);
  final int most = pairsMax(a['band']);
  if (left.length > most) {
    say(
      file,
      'scene.left',
      '${left.length} pairs: played one at a time, an item has at most $most in this band',
    );
  }
  for (final (String side, List<Map<String, Object?>> faces) in <(String, List<Map<String, Object?>>)>[
    ('left', left),
    ('right', right),
  ]) {
    final Set<String> looks = <String>{};
    for (final (int i, Map<String, Object?> f) in faces.indexed) {
      checkAsset(file, 'scene.$side[$i].alt', f['alt']);
      if (!looks.add(
        faceLook(
          sprite: f['sprite'],
          text: f['text'],
          clip: f['clip'],
          numeral: f['numeral'],
          coin: f['coin'],
        ),
      )) {
        say(file, 'scene.$side[$i]', 'looks like another face of its row');
      }
    }
  }
  // Choosing a wrong partner is a mistake with a tag: the partner's own, or the item's.
  for (final (int i, Map<String, Object?> f) in right.indexed) {
    if (f['misconception'] == null && answer['misconception'] == null) {
      say(
        file,
        'scene.right[$i].misconception',
        'a partner carries the misconception that choosing it by mistake shows',
      );
    }
  }
}

// ---- spot ----

void _spot(
  String file,
  Map<String, Object?> a,
  Map<String, Object?> scene,
  Map<String, Object?> answer,
  Ls01Say say,
  Ls01Check checkAsset,
  Ls01Check checkVo,
) {
  final List<Object?> cells = (scene['cells'] as List<Object?>?) ?? const <Object?>[];
  final bool text = cells.any((Object? c) => c is String && c.startsWith('txt:'));
  if (text && cells.length > spotCellsMax(a['band'])) {
    say(file, 'scene.cells', '${cells.length} text cells: at most ${spotCellsMax(a['band'])} in this band');
  }
  if (text && !cells.every((Object? c) => c is String && c.startsWith('txt:'))) {
    say(file, 'scene.cells', 'a row of letters, units or words is all text: it mixes in a picture or a sign');
  }
  final Map<String, Object?> model = _map(scene['model']);
  checkAsset(file, 'scene.model.sprite', model['sprite']);
  checkVo(file, 'scene.model.clip', model['clip']);
  // The model's own spelling is the row with its one wrong cell put right: hint levels 2 and 3 set the two against each other.
  final List<Object?> spelling = (model['spelling'] as List<Object?>?) ?? const <Object?>[];
  if (spelling.isNotEmpty) {
    final int wrong = (answer['wrong'] as int?) ?? -1;
    if (spelling.length != cells.length) {
      say(
        file,
        'scene.model.spelling',
        'has ${spelling.length} cells for a row of ${cells.length}: cell for cell',
      );
    } else {
      for (int i = 0; i < cells.length; i++) {
        if ((spelling[i] == cells[i]) == (i == wrong)) {
          say(
            file,
            'scene.model.spelling[$i]',
            i == wrong
                ? 'is the wrong cell as it stands: the spelling puts it right'
                : 'differs from the row, which is right here',
          );
        }
      }
    }
  }
  if (answer['misconception'] == null) {
    say(file, 'answer.misconception', 'a cell touched by mistake shows a misconception: name its tag');
  }
}

// ---- order tiles and the story line ----

void _pattern(
  String file,
  Map<String, Object?> a,
  Map<String, Object?> scene,
  Map<String, Object?> answer,
  Ls01Say say,
  Ls01Check checkVo,
) {
  if (answer['misconception'] == null) {
    say(file, 'answer.misconception', 'a tile put in a wrong place shows a misconception: name its tag');
  }
  final Object? order = answer['order'];
  if (order is! List<Object?>) return;
  final List<Object?> palette = (scene['palette'] as List<Object?>?) ?? const <Object?>[];
  final int n = palette.length;
  final List<Object?> clips = (scene['clips'] as List<Object?>?) ?? const <Object?>[];
  if (clips.isNotEmpty && clips.length != n) {
    say(
      file,
      'scene.clips',
      'has ${clips.length} lines for $n pictures: one line for each, in the order of the palette',
    );
  }
  for (final (int i, Object? c) in clips.indexed) {
    checkVo(file, 'scene.clips[$i]', c);
  }
  if (scene['slots'] != n) say(file, 'scene.slots', 'a story line has as many places as pictures ($n)');
  if (((scene['model'] as List<Object?>?) ?? const <Object?>[]).isNotEmpty) {
    say(file, 'scene.model', 'a story line has no model: the pictures are the line');
  }
  if (n > sequenceMaxPlaces(a['band'])) {
    say(
      file,
      'scene.palette',
      '$n places: a scored story line has at most ${sequenceMaxPlaces(a['band'])} in this band',
    );
  }
  final List<int> sorted = <int>[for (final Object? o in order) o! as int]..sort();
  if (sorted.length != n ||
      !<int>[for (int i = 0; i < n; i++) i]
          .asMap()
          .entries
          .every((MapEntry<int, int> e) => sorted[e.key] == e.value)) {
    say(file, 'answer.order', 'must name every picture once (0 to ${n - 1}), so that the order is complete');
  } else if (<int>[for (final Object? o in order) o! as int]
      .asMap()
      .entries
      .every((MapEntry<int, int> e) => e.key == e.value)) {
    say(file, 'answer.order', 'is the order the pictures already stand in: the line starts shuffled');
  }
  if (palette.toSet().length != n) say(file, 'scene.palette', 'has two pictures that are the same');
}
