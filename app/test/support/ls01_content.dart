// Fixture activities for the modes that L5-1 adds to LS01 (docs/design/languages-l5-ls01.md): a text stem, a cloze, a tap-all, a sort with
// text, picture or sound faces, pairs played one at a time, a spot row of text cells, order tiles and a story line. JSON of the activity
// files of a fixture language pack; not content: the words are only there to give the text, the sound and the tags something to be.

import 'language_content.dart';

/// An activity of one of the modes that L5-1 adds to LS01. [version] is the template's (1.4 for `tap_answer`, 1.1 for the others);
/// [credit] is the item's `creditByHintLevel` (a text stem with its clip lowers level 1 to 0.8).
Map<String, Object?> ls01Json({
  String course = 'eng',
  required String id,
  String? skill,
  required String template,
  required String version,
  required Map<String, Object?> scene,
  required Map<String, Object?> answer,
  String purpose = 'learn',
  String band = 'A',
  String representation = 'symbolic',
  String? target,
  String? show,
  String? promptText,
  List<num>? credit,
}) {
  final Map<String, Object?> doc = commonJson(
    course,
    id,
    skill ?? '${course.toUpperCase()}-A-02',
    template,
    version,
    purpose,
    band,
    representation,
  );
  doc.addAll(linesJson('$course.$id', target: target, show: show, promptText: promptText));
  doc['scene'] = scene;
  doc['answer'] = answer;
  if (credit != null) (doc['scoring']! as Map<String, Object?>)['creditByHintLevel'] = credit;
  return doc;
}

/// A text stem (LS01 d): [stem] on the stage, [clip] what "read it to me" plays, and the [options] to choose from.
Map<String, Object?> stemJson({
  String course = 'eng',
  required String id,
  String? skill,
  required String stem,
  String? clip,
  required List<Map<String, Object?>> options,
  required String correct,
  String purpose = 'learn',
  String band = 'A',
  Map<String, Object?> answer = const <String, Object?>{},
}) => ls01Json(
  course: course,
  id: id,
  skill: skill,
  template: 'tap_answer',
  version: '1.4',
  purpose: purpose,
  band: band,
  promptText: 'קִרְאוּ, וּגְעוּ בַּתְּמוּנָה.',
  credit: clip == null ? null : <num>[1, 0.8, 0.5, 0.25],
  scene: <String, Object?>{
    'stem': <String, Object?>{'text': stem, 'clip': ?clip},
  },
  answer: <String, Object?>{
    'type': 'choice',
    'options': options,
    'correct': correct,
    'shuffle': true,
    'unsureAllowed': true,
    ...answer,
  },
);

/// A cloze (LS01 e): [text] with its `_` gap, an optional [picture], and three word tiles.
Map<String, Object?> clozeJson({
  String course = 'eng',
  required String id,
  String? skill,
  required String text,
  String? picture,
  required List<Map<String, Object?>> options,
  required String correct,
  String band = 'A',
}) => ls01Json(
  course: course,
  id: id,
  skill: skill,
  template: 'tap_answer',
  version: '1.4',
  band: band,
  promptText: 'אֵיזוֹ מִלָּה חֲסֵרָה?',
  target: 'vo:$course.$id.sentence',
  scene: <String, Object?>{
    'cloze': <String, Object?>{'text': text, 'picture': ?(picture == null ? null : 'asset:$picture')},
  },
  answer: <String, Object?>{
    'type': 'choice',
    'options': options,
    'correct': correct,
    'shuffle': false,
    'unsureAllowed': true,
    // The word tiles of a cloze are words, whatever their length (the validator asks every item of short texts to say).
    'face': 'word',
  },
);

/// A tap-all (LS01): several right cards among [options]; the item checks itself when as many are picked as there are right ones.
Map<String, Object?> tapAllJson({
  String course = 'eng',
  required String id,
  String? skill,
  required List<Map<String, Object?>> options,
  required List<String> correct,
  String? face,
  String band = 'A',
  String? target,
}) => ls01Json(
  course: course,
  id: id,
  skill: skill,
  template: 'tap_answer',
  version: '1.4',
  band: band,
  promptText: 'גְּעוּ בְּכׇל הָאוֹתִיּוֹת הָאֵלֶּה.',
  target: target ?? 'vo:$course.$id.target',
  scene: <String, Object?>{},
  answer: <String, Object?>{
    'type': 'choice',
    'all': true,
    'options': options,
    'correct': correct,
    'shuffle': false,
    'unsureAllowed': true,
    'face': ?face,
  },
);

/// A face of a bin or a card of a sort: a text, a picture (`asset:` is added), or only a sound.
Map<String, Object?> sortFace(
  String id, {
  String? text,
  String? picture,
  String? clip,
  String? tag,
  String? bin,
}) => <String, Object?>{
  'id': id,
  'text': ?text,
  'sprite': ?(picture == null ? null : 'asset:$picture'),
  'clip': ?clip,
  'misconception': ?tag,
  'bin': ?bin,
};

/// A sort with text, picture or sound faces (LS01): [bins] (ids `b1`..) and [items] (ids `i1`..).
Map<String, Object?> sortJson({
  String course = 'eng',
  required String id,
  String? skill,
  required List<Map<String, Object?>> bins,
  required List<Map<String, Object?>> items,
  String? tag,
  String band = 'A',
}) => ls01Json(
  course: course,
  id: id,
  skill: skill,
  template: 'sort_drag',
  version: '1.1',
  band: band,
  promptText: 'לְאֵיזֶה סַל?',
  scene: <String, Object?>{
    'bins': <Object?>[
      for (final Map<String, Object?> b in bins) <String, Object?>{'label': 'bin ${b['id']}', ...b},
    ],
    'items': <Object?>[
      for (final Map<String, Object?> i in items) <String, Object?>{'label': 'card ${i['id']}', ...i},
    ],
  },
  answer: <String, Object?>{'type': 'sort', 'mode': 'sort', 'misconception': ?tag},
);

/// A face of a pair: a text, a picture, or only a sound (a sound card).
Map<String, Object?> pairFace(String id, {String? text, String? picture, String? clip, String? tag}) =>
    <String, Object?>{
      'id': id,
      'label': 'face $id',
      'text': ?text,
      'sprite': ?(picture == null ? null : 'asset:$picture'),
      'clip': ?clip,
      'misconception': ?tag,
    };

/// Pairs played one at a time (LS01): each left face goes with the right face of [pairs] (`l1` -> `r2`).
Map<String, Object?> pairsJson({
  String course = 'eng',
  required String id,
  String? skill,
  required List<Map<String, Object?>> left,
  required List<Map<String, Object?>> right,
  required Map<String, String> pairs,
  String? tag,
  String band = 'A',
}) => ls01Json(
  course: course,
  id: id,
  skill: skill,
  template: 'match_pairs',
  version: '1.1',
  band: band,
  promptText: 'חַבְּרוּ כׇּל אוֹת לַשֵּׁם שֶׁלָּהּ.',
  scene: <String, Object?>{'left': left, 'right': right},
  answer: <String, Object?>{
    'type': 'match',
    'pairs': <Object?>[
      for (final MapEntry<String, String> p in pairs.entries)
        <String, Object?>{'left': p.key, 'right': p.value},
    ],
    'misconception': ?tag,
  },
);

/// A row of text cells against a picture (LS01 spot): the cell [wrong] does not match the [model].
Map<String, Object?> spotJson({
  String course = 'eng',
  required String id,
  String? skill,
  required List<String> cells,
  required int wrong,
  String? model,
  String? modelClip,
  required String tag,
  String band = 'A',
}) => ls01Json(
  course: course,
  id: id,
  skill: skill,
  template: 'spot_error',
  version: '1.1',
  band: band,
  promptText: 'אֵיזוֹ אוֹת לֹא נְכוֹנָה?',
  scene: <String, Object?>{
    'cells': cells,
    if (model != null) 'model': <String, Object?>{'sprite': 'asset:$model', 'clip': ?modelClip},
  },
  answer: <String, Object?>{'type': 'spot', 'wrong': wrong, 'misconception': tag},
);

/// Order tiles (LS01): the row [model] is shown with a place to fill at its end, from the [palette] of tiles (`txt:` or `asset:` faces).
Map<String, Object?> orderJson({
  String course = 'eng',
  required String id,
  String? skill,
  required List<String> model,
  required List<String> palette,
  required List<String> sequence,
  required String tag,
  String band = 'A',
}) => ls01Json(
  course: course,
  id: id,
  skill: skill,
  template: 'build_pattern',
  version: '1.1',
  band: band,
  promptText: 'מָה בָּא אַחֲרֵי?',
  scene: <String, Object?>{'model': model, 'slots': sequence.length, 'palette': palette},
  answer: <String, Object?>{'type': 'build', 'sequence': sequence, 'misconception': tag},
);

/// A story line (LS01 f): the [palette] stands in a shuffled order and [order] is the index of each place's picture in the right order.
Map<String, Object?> sequenceJson({
  String course = 'eng',
  required String id,
  String? skill,
  required List<String> palette,
  required List<int> order,
  required String tag,
  String band = 'A',
}) => ls01Json(
  course: course,
  id: id,
  skill: skill,
  template: 'build_pattern',
  version: '1.1',
  band: band,
  promptText: 'מָה קָרָה קֹדֶם?',
  scene: <String, Object?>{'slots': palette.length, 'palette': palette},
  answer: <String, Object?>{'type': 'build', 'order': order, 'misconception': tag},
);
