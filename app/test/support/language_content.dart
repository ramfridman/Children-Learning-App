// Fixture content for the language templates (L1): activities of a fixture course built as JSON, added to a fixture pack with
// everything the validator wants around them (manifest entries, voice lines, tags). Not real content: the words are only
// there to give the text, the sound and the tags something to be.

import 'package:nitznutz/content/models.dart';

import 'sample_pack.dart';

List<Object?> he(String text) => <Object?>[
  <String, Object?>{'t': 'he', 'v': text},
];

Map<String, Object?> line(String vo, String text, {String? target, String? show}) => <String, Object?>{
  'vo': vo,
  'caption': he(text),
  'target': ?target,
  'show': ?show,
};

// ---- options ----

Map<String, Object?> textOption(String id, String text, {String? tag, String? clip, String? label}) =>
    <String, Object?>{'id': id, 'text': text, 'label': label ?? text, 'clip': ?clip, 'misconception': ?tag};

Map<String, Object?> soundOption(String id, String clip, {String? tag, int? value}) => <String, Object?>{
  'id': id,
  'clip': clip,
  'label': 'button $id',
  'value': ?value,
  'misconception': ?tag,
};

Map<String, Object?> pictureOption(String id, String asset, {String? tag, String? clip, String? reveal}) =>
    <String, Object?>{
      'id': id,
      'sprite': 'asset:$asset',
      'label': asset,
      'clip': ?clip,
      'reveal': ?reveal,
      'misconception': ?tag,
    };

// ---- activities ----

const String _he1 = 'הַקְשִׁיבוּ, וּגְעוּ בַּתְּמוּנָה.';

Map<String, Object?> _lines(String id, {String? target, String? show, String? promptText}) =>
    <String, Object?>{
      'prompt': <String, Object?>{
        ...line('vo:$id.prompt', promptText ?? _he1, target: target, show: show),
        'replayButton': true,
      },
      'feedback': <String, Object?>{
        'correct': line('vo:$id.right', 'נָכוֹן!'),
        'incorrect': <Object?>[
          <String, Object?>{'when': 'default', ...line('vo:$id.again', 'בּוֹאוּ נַקְשִׁיב שׁוּב.')},
        ],
        'unsure': line('vo:$id.unsure', 'בּוֹאוּ נְנַסֶּה יַחַד.'),
      },
      'hints': <Object?>[
        <String, Object?>{
          'level': 1,
          'action': 'replay_prompt_slow',
          ...line('vo:$id.h1', 'הַקְשִׁיבוּ שׁוּב, לְאַט.'),
        },
        <String, Object?>{
          'level': 2,
          'action': 'highlight_objects_sequentially',
          ...line('vo:$id.h2', 'בּוֹאוּ נִסְתַּכֵּל בַּתְּמוּנוֹת.'),
        },
        <String, Object?>{
          'level': 3,
          'action': 'worked_example',
          ...line('vo:$id.h3', 'הִסְתַּכְּלוּ אֵיךְ עוֹשִׂים.'),
        },
      ],
    };

Map<String, Object?> _common(
  String course,
  String id,
  String skill,
  String template,
  String version,
  String purpose,
  String band,
  String representation,
) => <String, Object?>{
  'schema': 'activity/v1',
  'id': '$course.$id',
  'revision': 1,
  'template': template,
  'templateVersion': version,
  'course': course,
  'domain': 'languages',
  'band': band,
  'skills': <Object?>[
    <String, Object?>{'id': skill, 'weight': 1},
  ],
  'purpose': purpose,
  'checkType': 'practice',
  'representation': representation,
  'variantGroup': id.replaceAll('_', '-'),
  'difficulty': <String, Object?>{'authored': 0.2},
  'scoring': <String, Object?>{
    'maxAttempts': 3,
    'creditByHintLevel': <Object?>[1, 0.75, 0.5, 0.25],
  },
  'tutor': <String, Object?>{'llmAllowed': false, 'goal': 'listen and choose', 'mustNotRevealBeforeHint': 2},
  'a11y': <String, Object?>{'altText': 'שָׁלוֹשׁ תְּמוּנוֹת'},
};

/// A `tap_answer` 1.3 activity of [course]: its id is `<course>.<id>`, the skill the second skill of the fixture pack unless
/// [skill] says one. [target] and [show] go on the prompt line (the second clip, and the word in the chip).
Map<String, Object?> tapJson({
  String course = 'eng',
  required String id,
  String? skill,
  String purpose = 'learn',
  String band = 'A',
  String representation = 'pictorial',
  required List<Map<String, Object?>> options,
  required String correct,
  Map<String, Object?> scene = const <String, Object?>{},
  Map<String, Object?> answer = const <String, Object?>{},
  String? target,
  String? show,
  String? promptText,
}) => <String, Object?>{
  ..._common(
    course,
    id,
    skill ?? '${course.toUpperCase()}-A-02',
    'tap_answer',
    '1.3',
    purpose,
    band,
    representation,
  ),
  ..._lines('$course.$id', target: target, show: show, promptText: promptText),
  'scene': scene,
  'answer': <String, Object?>{
    'type': 'choice',
    'options': options,
    'correct': correct,
    'shuffle': true,
    'unsureAllowed': true,
    ...answer,
  },
};

/// A `count_tap` 1.1 activity of [course]: [count] objects, one number clip for each tap in [clips], then "how many?" on [options].
Map<String, Object?> countJson({
  String course = 'eng',
  required String id,
  String? skill,
  required int count,
  required List<String> clips,
  required List<Map<String, Object?>> options,
  required String correct,
  List<Object?> traceClassifiers = const <Object?>[],
  String? answerTarget,
}) => <String, Object?>{
  ..._common(
    course,
    id,
    skill ?? '${course.toUpperCase()}-A-02',
    'count_tap',
    '1.1',
    'learn',
    'A',
    'concrete',
  ),
  ..._lines('$course.$id'),
  'scene': <String, Object?>{
    'objects': <String, Object?>{
      'sprite': 'asset:butterfly',
      'litSprite': 'asset:butterfly_lit',
      'count': count,
      'arrangement': 'line',
      'onTap': 'glow',
      'seed': 3,
      'clips': clips,
    },
    'target': <String, Object?>{'sprite': 'asset:jar'},
  },
  'answer': <String, Object?>{
    'type': 'choice',
    'options': options,
    'correct': correct,
    'shuffle': true,
    'unsureAllowed': true,
  },
  'answerPrompt': line('vo:$course.$id.howmany', 'כַּמָּה יֵשׁ?', target: answerTarget),
  'traceClassifiers': traceClassifiers,
};

// ---- the pack ----

/// The fixture pack of a language course with room for activities of its second skill: `ENG-A-02` and the tags
/// `eng.lis.sem`, `eng.lis.guess` and `eng.lis.numword` (diagnostic), `eng.spk.accent` (accent) and `eng.lis.early` (on the way).
class LangPack {
  LangPack([this.course = 'eng']) : pack = SamplePack.language(course) {
    for (final (String, String) t in <(String, String)>[
      ('lis.sem', 'diagnostic'),
      ('lis.guess', 'diagnostic'),
      ('lis.numword', 'diagnostic'),
      ('spk.accent', 'accent'),
      ('lis.early', 'on_the_way'),
    ]) {
      addTag(t.$1, t.$2);
    }
  }

  final String course;
  final SamplePack pack;

  String tag(String slug) => '$course.$slug';

  String get skill => '${course.toUpperCase()}-A-02';

  void addTag(String slug, String kind) {
    final String id = tag(slug);
    pack.addDocument('misconception.$id.json', 'misconceptions', id, <String, Object?>{
      'schema': 'misconception/v1',
      'id': id,
      'course': course,
      'kind': kind,
      'skills': <Object?>[skill],
      'parentText': 'The child is still learning this word.',
      'repairActivities': <Object?>[],
      'preferredRepresentations': <Object?>['pictorial'],
    });
  }

  /// Adds an activity to the pack, with its file, its manifest entries and the voice lines it names (all pending).
  void add(Map<String, Object?> activity) {
    final String id = activity['id']! as String;
    pack.addDocument('activity.$id.json', 'activities', id, activity);
    final Map<String, Object?> templates = pack.manifest['templates']! as Map<String, Object?>;
    templates[activity['template']! as String] = activity['template'] == 'count_tap' ? '1.1' : '1.3';
    final List<Object?> pending = pack.manifest['voPending']! as List<Object?>;
    void scan(Object? node) {
      if (node is String && node.startsWith('vo:') && !pending.contains(node)) pending.add(node);
      if (node is Map<String, Object?>) node.values.forEach(scan);
      if (node is List<Object?>) node.forEach(scan);
    }

    scan(activity);
  }

  /// Replaces the activity [id] (its short id) with [activity].
  void replace(String id, Map<String, Object?> activity) {
    pack.docs['activity.$course.$id.json'] = activity;
  }

  Map<String, Object?> activity(String id) => pack.doc('activity.$course.$id.json');

  PackContent get content => PackContent.fromPack(pack.verified(pictures: true));
}
