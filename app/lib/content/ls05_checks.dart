import '../engine/course.dart';
import 'language_checks.dart' show Say;

// The content rules of LS05 change one part (`change_part` 1.0, docs/milestones/L5.md section 5.4 and its "Changed 2026-11-07" line): what stands in
// the places of the frame, what every combination makes, the limits of the wheel and the strip, and what a `make` item must hold so that a right
// sound is never scored as wrong. The same rules hold for the wheel or strip that a hint borrows (`checkChangeData`). Pure functions of the documents.

Map<String, Object?> _map(Object? v) => v is Map<String, Object?> ? v : const <String, Object?>{};

List<Map<String, Object?>> _maps(Object? v) => <Map<String, Object?>>[
  for (final Object? e in (v as List<Object?>? ?? const <Object?>[]))
    if (e is Map<String, Object?>) e,
];

bool isChangePart(Map<String, Object?> a) => a['template'] == 'change_part';

/// The most parts of an `explore` screen: the Hebrew wheel holds 7 letters and 4 signs (the half dial shows 7 and the phone SE's row 4, so an item is the
/// same on every board), a strip 6; a `make` item holds 4 in all.
const int wheelMostLetters = 7;
const int wheelMostSigns = 4;
const int stripMostParts = 6;
const int makeMostParts = 4;

/// The vowel signs a wheel bead may carry: shva, hiriq, tsere, segol, patah, qamats, holam, kubutz (the dagesh is a letter's, never a bead).
bool isVowelSign(int r) => (r >= 0x05B0 && r <= 0x05BB) && r != 0x05BA;

bool _isMark(int r) =>
    (r >= 0x05B0 && r <= 0x05BD) || r == 0x05BF || r == 0x05C1 || r == 0x05C2 || r == 0x05C7;

bool _isLetter(int r) => r >= 0x05D0 && r <= 0x05EA;

/// A letter bead of the Hebrew wheel: one letter with at most its dagesh or shin dot.
bool isWheelLetter(String t) {
  final List<int> runes = t.runes.toList();
  return runes.isNotEmpty &&
      _isLetter(runes.first) &&
      runes.skip(1).every((int r) => r == 0x05BC || r == 0x05C1 || r == 0x05C2);
}

/// A sign bead: no sign (the empty text) or one vowel sign.
bool isWheelSign(String t) => t.isEmpty || (t.runes.length == 1 && isVowelSign(t.runes.first));

/// A text as its letters with their marks sorted: two spellings of one unit that put the marks in another order are the same unit.
String _canon(String t) {
  final List<String> clusters = <String>[];
  for (final int r in t.runes) {
    if (_isMark(r) && clusters.isNotEmpty) {
      clusters[clusters.length - 1] += String.fromCharCode(r);
    } else {
      clusters.add(String.fromCharCode(r));
    }
  }
  return <String>[
    for (final String c in clusters)
      String.fromCharCodes(<int>[c.runes.first, ...c.runes.skip(1).toList()..sort()]),
  ].join();
}

/// The text that the frame [text] shows with the part texts [parts] put in its places, one for each `_`.
String composeFrame(String text, List<String> parts) {
  int i = 0;
  return text.replaceAllMapped(RegExp('_'), (Match _) => i < parts.length ? parts[i++] : '');
}

/// The checks of the data of an LS05 screen, whether it is an activity's own or a hint's: [prefix] is the path of its scene. [make] adds what a
/// scored item needs. Parts are `{id, slot, text, tag?}`, results `{parts, text, clip?, sprite?}`.
void checkChangeData(
  String file,
  String prefix, {
  required Map<String, Object?> frame,
  required List<Map<String, Object?>> parts,
  required List<Map<String, Object?>> results,
  required bool make,
  required String course,
  required List<String> answerParts,
  required Say say,
}) {
  final String text = (frame['text'] as String?) ?? '';
  final int slots = (frame['slots'] as int?) ?? 1;
  if ('_'.allMatches(text).length != slots) {
    say(
      file,
      '$prefix.frame.text',
      'has ${'_'.allMatches(text).length} gaps (_) for ${slots == 1 ? 'one place' : 'two places'} that change',
    );
  }
  final Map<String, Map<String, Object?>> byId = <String, Map<String, Object?>>{
    for (final Map<String, Object?> p in parts) '${p['id']}': p,
  };
  for (final (int i, Map<String, Object?> p) in parts.indexed) {
    final int slot = (p['slot'] as int?) ?? 0;
    final String t = (p['text'] as String?) ?? '';
    if (slot >= slots) say(file, '$prefix.parts[$i].slot', 'is place $slot but the frame has $slots');
    if (course == Course.heb) {
      if (!(isWheelLetter(t) || isWheelSign(t))) {
        say(
          file,
          '$prefix.parts[$i].text',
          '"$t" is neither a letter (with its dagesh or shin dot) nor one vowel sign: a wheel bead is one of them',
        );
      }
    } else if (t.isEmpty || t.runes.length > 2) {
      say(file, '$prefix.parts[$i].text', 'is a vowel or a letter of one or two characters');
    }
    if (!make && p['tag'] != null) {
      say(file, '$prefix.parts[$i].tag', 'a teaching screen has no distractor: nothing in it is wrong');
    }
  }
  for (int s = 0; s < slots; s++) {
    if (!parts.any((Map<String, Object?> p) => p['slot'] == s)) {
      say(file, '$prefix.parts', 'place $s has no part');
    }
  }

  // The most parts: a wheel holds 7 letters and 4 signs, a strip 6, a make item 4 in all.
  final int inLast = parts.where((Map<String, Object?> p) => p['slot'] == slots - 1).length;
  if (make) {
    if (parts.length > makeMostParts) {
      say(file, '$prefix.parts', 'a make item offers at most $makeMostParts parts, not ${parts.length}');
    }
  } else if (course == Course.heb) {
    final int signs = slots == 2 ? inLast : 0;
    final int letters = parts.length - signs;
    if (slots == 2 && signs > wheelMostSigns) {
      say(file, '$prefix.parts', 'a wheel holds at most $wheelMostSigns signs, not $signs');
    }
    if (letters > wheelMostLetters) {
      say(file, '$prefix.parts', 'a wheel holds at most $wheelMostLetters letters, not $letters');
    }
  } else if (parts.length > stripMostParts) {
    say(file, '$prefix.parts', 'a strip holds at most $stripMostParts parts, not ${parts.length}');
  }

  // From S3 on the shva takes the place of "no sign": the two sound the same, and a make item holding both could not tell a right sound from a wrong one.
  if (course == Course.heb && slots == 2) {
    final Set<String> signs = <String>{
      for (final Map<String, Object?> p in parts)
        if (p['slot'] == 1) '${p['text']}',
    };
    if (signs.contains('') && signs.contains(String.fromCharCode(0x05B0))) {
      say(file, '$prefix.parts', 'a wheel has "no sign" or the shva, never both: they sound the same');
    }
  }

  // Every result: parts that exist, one for each place and in its place; made of the frame; a combination once.
  final Set<String> seen = <String>{};
  for (final (int i, Map<String, Object?> r) in results.indexed) {
    final List<String> ids = <String>[
      for (final Object? id in (r['parts'] as List<Object?>? ?? const <Object?>[])) '$id',
    ];
    final String path = '$prefix.results[$i]';
    if (ids.length != slots) {
      say(file, '$path.parts', 'names ${ids.length} parts for $slots places');
      continue;
    }
    bool ok = true;
    for (final (int s, String id) in ids.indexed) {
      if (byId[id] == null) {
        say(file, '$path.parts', 'there is no part "$id"');
        ok = false;
      } else if (byId[id]!['slot'] != s) {
        say(file, '$path.parts', '"$id" is not a part of place $s');
        ok = false;
      }
    }
    if (!ok) continue;
    if (!seen.add(ids.join('.'))) say(file, path, 'the combination ${ids.join(' + ')} is given twice');
    final String made = composeFrame(text, <String>[for (final String id in ids) '${byId[id]!['text']}']);
    if (_canon(made) != _canon('${r['text']}')) {
      say(file, '$path.text', 'is "${r['text']}" but the parts make "$made"');
    }
    if (make && r['clip'] == null) {
      say(
        file,
        '$path.clip',
        'every result a make item can reach has a clip (a result with no sound is for a teaching screen)',
      );
    }
  }

  if (!make) return;

  // What a make item holds: the answer is one part for each place; every part that is not in it is a distractor with its tag; every combination the
  // child can reach is a result with a clip; and no two parts of a place give the same result, so a right sound is never scored as wrong.
  if (answerParts.length != slots) {
    say(file, 'answer.parts', 'is ${answerParts.length} parts for $slots places');
    return;
  }
  for (final (int s, String id) in answerParts.indexed) {
    if (byId[id]?['slot'] != s) say(file, 'answer.parts', '"$id" is not a part of place $s');
  }
  for (final (int i, Map<String, Object?> p) in parts.indexed) {
    if (!answerParts.contains(p['id']) && p['tag'] == null) {
      say(
        file,
        '$prefix.parts[$i].tag',
        'a part that is not in the answer is a distractor: it names the mistake it shows',
      );
    }
  }
  final List<List<String>> combos = <List<String>>[<String>[]];
  for (int s = 0; s < slots; s++) {
    final List<List<String>> next = <List<String>>[];
    for (final List<String> c in combos) {
      for (final Map<String, Object?> p in parts) {
        if (p['slot'] == s) next.add(<String>[...c, '${p['id']}']);
      }
    }
    combos
      ..clear()
      ..addAll(next);
  }
  Map<String, Object?>? resultOf(List<String> ids) {
    for (final Map<String, Object?> r in results) {
      if ((r['parts'] as List<Object?>?)?.join('.') == ids.join('.')) return r;
    }
    return null;
  }

  for (final List<String> c in combos) {
    final Map<String, Object?>? r = resultOf(c);
    if (r == null) {
      say(file, '$prefix.results', 'the child can make ${c.join(' + ')} but it has no result and no sound');
    }
  }
  for (int s = 0; s < slots; s++) {
    final List<Map<String, Object?>> inSlot = <Map<String, Object?>>[
      for (final Map<String, Object?> p in parts)
        if (p['slot'] == s) p,
    ];
    final Map<String, String> sound = <String, String>{};
    for (final Map<String, Object?> p in inSlot) {
      final List<String> ids = <String>[...answerParts]..[s] = '${p['id']}';
      final Map<String, Object?>? r = resultOf(ids);
      if (r == null) continue;
      final String key = '${r['clip']}';
      final String? twin = sound[key];
      if (twin != null) {
        say(
          file,
          '$prefix.parts',
          '"${p['id']}" and "$twin" give the same result with the other part of the answer: a right sound would be scored as wrong',
        );
      } else {
        sound[key] = '${p['id']}';
      }
    }
  }
}

/// The checks of one `change_part` activity.
void checkLs05Activity(
  String file,
  Map<String, Object?> a, {
  required bool language,
  required String course,
  required Say say,
}) {
  if (!isChangePart(a)) return;
  if (!language) {
    say(file, 'template', 'change one part belongs to a language course, not to the lands');
    return;
  }
  final Map<String, Object?> scene = _map(a['scene']);
  final Map<String, Object?> answer = _map(a['answer']);
  final bool make = scene['mode'] == 'make';
  checkChangeData(
    file,
    'scene',
    frame: _map(scene['frame']),
    parts: _maps(scene['parts']),
    results: _maps(scene['results']),
    make: make,
    course: course,
    answerParts: <String>[
      for (final Object? p in (answer['parts'] as List<Object?>? ?? const <Object?>[])) '$p',
    ],
    say: say,
  );
  if (!make && answer['parts'] != null) say(file, 'answer.parts', 'a teaching screen has no right answer');
  if (make && answer['parts'] == null) {
    say(file, 'answer.parts', 'a make item names the parts that make what is heard');
  }
  if (a['purpose'] == 'check' || a['purpose'] == 'probe') {
    say(file, 'purpose', 'change one part is a free response: never a probe and never a check');
  }
}
