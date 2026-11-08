import 'dart:convert';
import 'dart:math' as math;

import '../data/child_name.dart' show displayChildName;
import '../strings/he.dart';

// The own-name items of Hebrew Band A (HEB-A-11, `tap_answer` 1.5, `answer.type` `name`): the options are made on the device, when a
// lesson opens, from the first name of the child who plays it. A pack holds only the rules and a closed list of names (never a name), so
// there is nothing to send. What this file does with a name is to put it on a tile: it is never logged, written, stored, sent, shown to a
// tutor or voiced, and an answer is recorded as the id of the option (`o1`), as for any other tap. Decision 25 of 2026-11-03.
// This file works on the documents (plain maps) and imports nothing of the app's content or screens, so the pack validator and the pack tools
// (plain Dart, no Flutter) can run the same rules; `play/name_options.dart` makes an activity of the result.

/// The name of the house character, the fallback of the last resort (docs/languages/hebrew/band-a-content.md, A-11: the companion's name
/// stands in, ניצי by default). It is in the closed list, so an item always has a face to draw.
String get houseName => He.houseCharacterName;

final RegExp _marks = RegExp(r'\p{M}', unicode: true);

/// A letter of the Hebrew alphabet (alef to tav, final forms included).
bool _isHebrewLetter(int rune) => rune >= 0x05D0 && rune <= 0x05EA;

/// The first name as it is printed on a tile: the profile's name cleaned as it is everywhere ([displayChildName]), its first word, with no
/// nikud (the other names carry none, so a pointed name would be a cue they lack), and only if what is left is two to eight Hebrew
/// letters. A name in another script, a nickname with a mark inside it or a single letter gives null: the item then uses the companion's.
String? printName(String? raw) {
  if (raw == null) return null;
  final String shown = displayChildName(raw);
  if (shown.isEmpty) return null;
  final String word = shown.split(RegExp(r'[ \-]')).first.replaceAll(_marks, '');
  return word.runes.length >= 2 && word.runes.length <= 8 && word.runes.every(_isHebrewLetter) ? word : null;
}

/// Makes the options of an own-name item. [childName] is the profile's first name as the parent typed it, [companionName]
/// the name of the child's companion; both may be null. A name that cannot be used (see [printName]) is passed over for the next:
/// the child's, the companion's, the house character's. [random] chooses among the names of the closed list that fit the rule.
class OwnNameDocs {
  OwnNameDocs({this.childName, this.companionName, math.Random? random}) : _random = random ?? math.Random();

  final String? childName;
  final String? companionName;
  final math.Random _random;

  /// A copy of the document [source] of an own-name item with its options made (the child's name, the companion's, then the house name's),
  /// or null when none of the three gives the options its rules need. The validator runs this with no name at all, to prove that the house
  /// name always works. Throws on a document that is not shaped like an own-name item.
  Map<String, Object?>? madeDoc(Map<String, Object?> source) {
    final Map<String, Object?> doc = jsonDecode(jsonEncode(source)) as Map<String, Object?>;
    final Map<String, Object?> answer = doc['answer']! as Map<String, Object?>;
    final String unit = answer['unit']! as String;
    for (final String? candidate in <String?>[printName(childName), printName(companionName), houseName]) {
      if (candidate == null) continue;
      final Map<String, ({String text, String? tag})>? made = unit == 'letter'
          ? _letters(candidate, answer)
          : _names(candidate, answer);
      if (made == null) continue;
      for (final Map<String, Object?> o
          in (answer['options']! as List<Object?>).cast<Map<String, Object?>>()) {
        final ({String text, String? tag}) m = made[o['source']]!;
        o
          ..remove('source')
          ..['text'] = m.text
          ..['label'] = m.text;
        if (m.tag != null) o['misconception'] = m.tag;
      }
      answer
        ..['type'] = 'choice'
        ..['face'] = unit == 'letter' ? 'letter' : 'word'
        ..remove('names')
        ..remove('pairs')
        ..remove('unit');
      return doc;
    }
    return null;
  }

  /// The three names of a choice of names: the child's own, a name of the closed list with its first letter (NAME-FIRST), and one with as
  /// many letters and another first letter (NAME-LENGTH). Null when there is no name to take for NAME-FIRST.
  Map<String, ({String text, String? tag})>? _names(String own, Map<String, Object?> answer) {
    final List<String> list = <String>[
      for (final Object? n in answer['names']! as List<Object?>)
        if (n != own) n! as String,
    ];
    final List<({String a, String b, String tag})> pairs = _pairs(answer);
    final String firstLetter = own[0];
    // NAME-FIRST: the same first letter, another length when there is one (so that the first letter is all it shares). When no name of the
    // list starts so, the name of the look-alike letter, and then the tag is that pair's.
    final List<String> sameFirst = <String>[
      for (final String n in list)
        if (n[0] == firstLetter) n,
    ];
    String? first;
    String? firstTag;
    if (sameFirst.isNotEmpty) {
      final List<String> otherLength = <String>[
        for (final String n in sameFirst)
          if (n.length != own.length) n,
      ];
      first = _pick(otherLength.isEmpty ? sameFirst : otherLength);
    } else {
      final ({String letter, String tag})? partner = _partner(pairs, firstLetter);
      final List<String> alike = partner == null
          ? const <String>[]
          : <String>[
              for (final String n in list)
                if (n[0] == partner.letter) n,
            ];
      if (alike.isEmpty) return null;
      first = _pick(alike);
      firstTag = partner!.tag;
    }
    // NAME-LENGTH: as many letters, another first letter; the nearest length when the name is longer than any in the list.
    final List<String> others = <String>[
      for (final String n in list)
        if (n != first && n[0] != firstLetter) n,
    ];
    if (others.isEmpty) return null;
    final int near = others.map((String n) => (n.length - own.length).abs()).reduce(math.min);
    final String length = _pick(<String>[
      for (final String n in others)
        if ((n.length - own.length).abs() == near) n,
    ]);
    return <String, ({String text, String? tag})>{
      'own': (text: own, tag: null),
      'first': (text: first, tag: firstTag),
      'length': (text: length, tag: null),
    };
  }

  /// The three letters of a row: the first letter of the name, its look-alike (the tag is the pair's) and its last letter. Null when the
  /// name has no look-alike for its first letter, or its last letter is its first or its look-alike (then the row would repeat a letter).
  Map<String, ({String text, String? tag})>? _letters(String own, Map<String, Object?> answer) {
    final String first = own[0];
    final String last = own[own.length - 1];
    final ({String letter, String tag})? partner = _partner(_pairs(answer), first);
    if (partner == null || last == first || last == partner.letter) return null;
    return <String, ({String text, String? tag})>{
      'first': (text: first, tag: null),
      'lookalike': (text: partner.letter, tag: partner.tag),
      'last': (text: last, tag: null),
    };
  }

  String _pick(List<String> from) => from[_random.nextInt(from.length)];

  static List<({String a, String b, String tag})> _pairs(Map<String, Object?> answer) {
    final List<({String a, String b, String tag})> out = <({String a, String b, String tag})>[];
    for (final Object? raw in (answer['pairs'] as List<Object?>? ?? const <Object?>[])) {
      final Map<String, Object?> p = raw! as Map<String, Object?>;
      out.add((a: p['a']! as String, b: p['b']! as String, tag: p['misconception']! as String));
    }
    return out;
  }

  /// The look-alike of [letter] and the tag of the pair, or null. A pair works both ways.
  static ({String letter, String tag})? _partner(
    List<({String a, String b, String tag})> pairs,
    String letter,
  ) {
    for (final ({String a, String b, String tag}) p in pairs) {
      if (p.a == letter) return (letter: p.b, tag: p.tag);
      if (p.b == letter) return (letter: p.a, tag: p.tag);
    }
    return null;
  }
}
