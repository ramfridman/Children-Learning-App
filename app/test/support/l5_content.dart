// Fixture activities for the wave 2 templates (L5-3 to L5-5): LS03 `boxes`, LS05 change one part, LS04 blend slide, and a text stem whose hints borrow
// another template's screen. JSON of the activity files of a fixture language pack; not content: the words are only there to give the text, the sound
// and the tags something to be. Every clip is pending (the fixture pack lists them), as in the app today.

import 'language_content.dart';

/// An LS03 `boxes` activity (`sound_boxes` 1.1): [kinds] are the unit kinds in place order (`vowel`, `hard`, `soft`, `cv`, `c`), [steps] the item's steps,
/// and the answer's values for each step it has. [classify] maps a mistake (`count=1`, `colour=hard_soft`, ...) to a tag.
Map<String, Object?> boxesJson({
  String course = 'eng',
  required String id,
  String? skill,
  String purpose = 'learn',
  String band = 'A',
  String picture = 'sun',
  String unit = 'phoneme',
  required List<String> kinds,
  required List<String> steps,
  String? colours,
  int? stress,
  int? which,
  Map<String, String> classify = const <String, String>{},
  bool tok = true,
  bool slow = true,
  List<String?>? mouths,
}) {
  final Map<String, Object?> doc = commonJson(
    course,
    id,
    skill ?? '${course.toUpperCase()}-A-02',
    'sound_boxes',
    '1.1',
    purpose,
    band,
    'concrete',
  );
  doc.addAll(linesJson('$course.$id', promptText: 'הַקְשִׁיבוּ לַמִּלָּה, וְשִׂימוּ עִגּוּל לְכָל צְלִיל.'));
  doc['scene'] = <String, Object?>{
    'mode': 'boxes',
    'unit': unit,
    'word': <String, Object?>{
      'sprite': 'asset:$picture',
      'clip': 'vo:$course.$id.word',
      if (slow) 'slow': 'vo:$course.$id.slow',
      'units': <Object?>[
        for (final (int i, String k) in kinds.indexed)
          <String, Object?>{
            'clip': 'vo:$course.$id.u$i',
            'kind': k,
            if (mouths != null && mouths[i] != null) 'mouth': 'asset:${mouths[i]}',
          },
      ],
    },
    'steps': steps,
    if (tok) 'tok': 'vo:$course.tok',
  };
  doc['answer'] = <String, Object?>{
    'type': 'boxes',
    'count': kinds.length,
    'colours': ?colours,
    'stress': ?stress,
    'which': ?which,
    if (classify.isNotEmpty) 'classify': classify,
  };
  return doc;
}

/// One part of an LS05 item: its id, the place it stands in (0 or 1), its text and, for a distractor of `make`, the tag.
typedef PartSpec = ({String id, int slot, String text, String? tag});

PartSpec part(String id, int slot, String text, {String? tag}) => (id: id, slot: slot, text: text, tag: tag);

/// What a combination makes: the part id for each place, the text, its clip and the picture of a word that has one.
typedef ResultSpec = ({List<String> parts, String text, String? clip, String? sprite});

ResultSpec made(List<String> parts, String text, {String? clip, String? sprite}) =>
    (parts: parts, text: text, clip: clip, sprite: sprite);

/// An LS05 `change_part` activity. [frame] is the fixed text with a `_` for each place that changes. [answer] is the part id for each place of a `make`.
Map<String, Object?> changeJson({
  String course = 'heb',
  required String id,
  String? skill,
  String mode = 'make',
  String purpose = 'learn',
  String band = 'A',
  required String frame,
  required List<PartSpec> parts,
  required List<ResultSpec> results,
  List<String> answer = const <String>[],
  String? targetClip,
}) {
  final bool make = mode == 'make';
  final Map<String, Object?> doc = commonJson(
    course,
    id,
    skill ?? '${course.toUpperCase()}-A-02',
    'change_part',
    '1.0',
    make ? purpose : 'practice',
    band,
    'concrete',
  );
  doc.addAll(
    linesJson('$course.$id', target: make ? targetClip : null, promptText: 'סוֹבְבוּ עַד שֶׁתִּשְׁמְעוּ.'),
  );
  if (!make) doc['hints'] = <Object?>[];
  doc['scene'] = <String, Object?>{
    'mode': mode,
    'frame': <String, Object?>{'text': frame, 'slots': '_'.allMatches(frame).length},
    'parts': <Object?>[
      for (final PartSpec p in parts)
        <String, Object?>{'id': p.id, 'slot': p.slot, 'text': p.text, if (p.tag != null) 'tag': p.tag},
    ],
    'results': <Object?>[
      for (final ResultSpec r in results)
        <String, Object?>{
          'parts': r.parts,
          'text': r.text,
          if (r.clip != null) 'clip': r.clip,
          if (r.sprite != null) 'sprite': 'asset:${r.sprite}',
        },
    ],
  };
  doc['answer'] = make
      ? <String, Object?>{'type': 'parts', 'parts': answer}
      : <String, Object?>{'type': 'none'};
  return doc;
}

/// An option of an LS04 choice: a picture, or (merge) only a sound.
Map<String, Object?> slideOption(String id, {String? picture, String? clip, String? tag}) =>
    <String, Object?>{
      'id': id,
      if (picture != null) 'sprite': 'asset:$picture',
      'clip': ?clip,
      'label': picture ?? 'sound $id',
      'misconception': ?tag,
    };

/// An LS04 `blend_slide` activity: [parts] are `(text, clip, stretch)`, [whole] the clip of the whole word.
Map<String, Object?> blendJson({
  String course = 'eng',
  required String id,
  String? skill,
  String purpose = 'learn',
  String band = 'A',
  String? mode,
  required String text,
  required List<({String text, String? clip, bool stretch})> parts,
  String? whole,
  String? stretched,
  required List<Map<String, Object?>> options,
  required String correct,
}) {
  final Map<String, Object?> doc = commonJson(
    course,
    id,
    skill ?? '${course.toUpperCase()}-A-02',
    'blend_slide',
    '1.0',
    purpose,
    band,
    'symbolic',
  );
  doc.addAll(linesJson('$course.$id', promptText: 'הַחְלִיקוּ לְפִי הַחֵץ.'));
  doc['scene'] = <String, Object?>{
    'mode': mode ?? (course == 'rus' ? 'merge' : (course == 'heb' ? 'units' : 'graphemes')),
    'word': <String, Object?>{
      'text': text,
      'parts': <Object?>[
        for (final ({String text, String? clip, bool stretch}) p in parts)
          <String, Object?>{'text': p.text, if (p.clip != null) 'clip': p.clip, 'stretch': p.stretch},
      ],
      'whole': ?whole,
      'stretched': ?stretched,
    },
  };
  doc['answer'] = <String, Object?>{
    'type': 'choice',
    'options': options,
    'correct': correct,
    'shuffle': true,
    'unsureAllowed': true,
  };
  return doc;
}

({String text, String? clip, bool stretch}) bpart(String text, {String? clip, bool stretch = true}) =>
    (text: text, clip: clip, stretch: stretch);

/// Adds a borrowed screen to hint [level] of [activity]: `{ template: ..., ...data }`.
void borrow(Map<String, Object?> activity, int level, Map<String, Object?> screen) {
  final List<Object?> hints = activity['hints']! as List<Object?>;
  (hints[level - 1]! as Map<String, Object?>)['screen'] = screen;
}
