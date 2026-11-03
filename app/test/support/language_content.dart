// Fixture content for the language templates (L1): activities of a fixture course built as JSON, added to a fixture pack with
// everything the validator wants around them (manifest entries, voice lines, tags). Not real content: the words are only
// there to give the text, the sound and the tags something to be.

import 'dart:io';
import 'dart:typed_data';

import 'package:nitznutz/content/models.dart';
import 'package:nitznutz/content/pack_verify.dart' show VerifiedPack;

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
  // An option of a count has a value and no label (the schema of `count_tap`).
  'label': ?(value == null ? 'button $id' : null),
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
    templates[activity['template']! as String] = activity['templateVersion']! as String;
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

  /// The real pictures of the approved style (`content/languages/pictures`) that the pack shows instead of the fixture circle, by
  /// asset id: `ball_red` is the file `ball-red.svg`.
  final Set<String> realPictures = <String>{};

  /// Adds the pictures [ids] to the pack's assets, drawn from the approved pictures when the file exists (a name that is not a picture
  /// is drawn as the fixture circle). Run from the `app` folder, as `flutter test` does.
  void addPictures(Iterable<String> ids) {
    final List<Object?> assets = pack.manifest['assets']! as List<Object?>;
    final List<Object?> files = pack.manifest['files']! as List<Object?>;
    for (final String id in ids) {
      if (assets.any((Object? a) => (a! as Map<String, Object?>)['id'] == id)) continue;
      assets.add(<String, Object?>{'id': id, 'file': '$id.svg'});
      files.add(<String, Object?>{'name': '$id.svg', 'sha256': '8' * 64, 'size': 1});
      pack.files.add('$id.svg');
      if (File(pictureFile(id)).existsSync()) realPictures.add(id);
    }
  }

  static String pictureFile(String id) => '../content/languages/pictures/${id.replaceAll('_', '-')}.svg';

  PackContent get content {
    final VerifiedPack v = pack.verified(pictures: true);
    final Map<String, Uint8List> files = <String, Uint8List>{
      ...v.files,
      for (final String id in realPictures) '$id.svg': File(pictureFile(id)).readAsBytesSync(),
    };
    return PackContent.fromPack(
      VerifiedPack(
        manifestBytes: v.manifestBytes,
        signature: v.signature,
        manifestSha256: v.manifestSha256,
        manifest: v.manifest,
        docs: v.docs,
        files: files,
      ),
    );
  }
}

// ---- stories (LS08) ----

/// A page of a story: its picture (an asset id), the clips of its narration, what a screen reader says, and the things in it that
/// say their word.
Map<String, Object?> storyPage(
  String picture,
  List<String> clips, {
  String alt = 'עַמּוּד בַּסִּפּוּר',
  List<Map<String, Object?>> words = const <Map<String, Object?>>[],
}) => <String, Object?>{
  'picture': 'asset:$picture',
  'clips': clips,
  'alt': alt,
  if (words.isNotEmpty) 'words': words,
};

Map<String, Object?> hotWord(String clip, {double x = 0.1, double y = 0.1, double w = 0.3, double h = 0.3}) =>
    <String, Object?>{
      'at': <String, Object?>{'x': x, 'y': y, 'w': w, 'h': h},
      'clip': clip,
    };

/// A story of [course] (LS08). With [options] it is dialogic: it stops after the page [pauseAfter] and asks [question].
Map<String, Object?> storyJson({
  String course = 'eng',
  required String id,
  String? skill,
  required List<Map<String, Object?>> pages,
  int? pauseAfter,
  String? question,
  List<Map<String, Object?>>? options,
  String? correct,
}) {
  final bool dialogic = options != null;
  return <String, Object?>{
    ..._common(
      course,
      id,
      skill ?? '${course.toUpperCase()}-A-02',
      'story',
      '1.0',
      dialogic ? 'learn' : 'practice',
      'A',
      'story',
    ),
    ..._lines('$course.$id', promptText: 'בּוֹאוּ נִשְׁמַע סִפּוּר. אֶפְשָׁר לָגַעַת בַּתְּמוּנוֹת.'),
    'scene': <String, Object?>{'pages': pages},
    'answer': dialogic
        ? <String, Object?>{
            'type': 'choice',
            'mode': 'dialogic',
            'pauseAfter': pauseAfter,
            'question': line('vo:$course.$id.q', question ?? 'מִי זֶה?'),
            'options': options,
            'correct': correct,
            'shuffle': true,
            'unsureAllowed': true,
          }
        : <String, Object?>{'type': 'none', 'mode': 'listen'},
  };
}

// ---- listen and do (LS11) ----

/// A place in a picture, as shares of it.
Map<String, Object?> at(double x, double y, double w, double h) => <String, Object?>{
  'x': x,
  'y': y,
  'w': w,
  'h': h,
};

/// An option of a command that is a part of the picture (`hotspots`, or a place of `place`): no face, a place.
Map<String, Object?> partOption(String id, Map<String, Object?> where, {String? tag, String? label}) =>
    <String, Object?>{'id': id, 'label': label ?? 'part $id', 'at': where, 'misconception': ?tag};

/// An option that is a thing to drag: its picture and where it starts.
Map<String, Object?> thingOption(String id, String asset, Map<String, Object?> where, {String? tag}) =>
    <String, Object?>{'id': id, 'sprite': 'asset:$asset', 'label': asset, 'at': where, 'misconception': ?tag};

/// A command of [course] (LS11) in [mode]: `hotspots`, `buttons`, `drag`, `place` or `embodied`.
Map<String, Object?> listenDoJson({
  String course = 'eng',
  required String id,
  String? skill,
  required String mode,
  String picture = 'teddy',
  List<Map<String, Object?>>? options,
  String? correct,
  Map<String, Object?>? target,
  Map<String, Object?>? thing,
  String purpose = 'learn',
  String? representation,
}) {
  final bool embodied = mode == 'embodied';
  return <String, Object?>{
    ..._common(
      course,
      id,
      skill ?? '${course.toUpperCase()}-A-02',
      'listen_do',
      '1.0',
      embodied ? 'practice' : purpose,
      'A',
      representation ?? 'embodied',
    ),
    ..._lines('$course.$id', promptText: 'הַקְשִׁיבוּ, וְהַרְאוּ לְחָבֵר מַה לַּעֲשׂוֹת.'),
    'scene': <String, Object?>{'picture': 'asset:$picture', 'target': ?target, 'thing': ?thing},
    'answer': embodied
        ? <String, Object?>{'type': 'none', 'mode': 'embodied'}
        : <String, Object?>{
            'type': 'choice',
            'mode': mode,
            'options': options,
            'correct': correct,
            'shuffle': true,
            'unsureAllowed': true,
          },
  };
}

// ---- sing along (LS12) ----

/// A picture of a song: its asset id, a label for a screen reader and the clip of its word.
Map<String, Object?> songPicture(String asset, {String? clip}) => <String, Object?>{
  'picture': 'asset:$asset',
  'label': asset,
  'clip': ?clip,
};

/// A chant (`lines`) or a rhyme (`verse`, with `options`) of [course] (LS12).
Map<String, Object?> singJson({
  String course = 'eng',
  required String id,
  String? skill,
  required List<Map<String, Object?>> pictures,
  List<Map<String, Object?>>? lines,
  Map<String, Object?>? verse,
  List<Map<String, Object?>>? options,
  String? correct,
}) {
  final bool rhyme = options != null;
  return <String, Object?>{
    ..._common(
      course,
      id,
      skill ?? '${course.toUpperCase()}-A-02',
      'sing_along',
      '1.0',
      rhyme ? 'learn' : 'practice',
      'A',
      'story',
    ),
    ..._lines('$course.$id', promptText: 'בּוֹאוּ נְדַקְלֵם יַחַד, וְנַעֲשֶׂה אֶת הַתְּנוּעוֹת!'),
    'scene': <String, Object?>{'pictures': pictures, 'lines': ?lines, 'verse': ?verse},
    'answer': rhyme
        ? <String, Object?>{
            'type': 'choice',
            'mode': 'rhyme',
            'question': line('vo:$course.$id.q', 'אֵיזוֹ מִלָּה מַתְאִימָה לַסּוֹף?'),
            'options': options,
            'correct': correct,
            'shuffle': true,
            'unsureAllowed': true,
          }
        : <String, Object?>{'type': 'none', 'mode': 'chant'},
  };
}

// ---- puppet talk (LS10) ----

/// A turn of a puppet in [course] (LS10). `bubble`: [options] and the [correct] one. `personal`: the [topic], the cards in [options]
/// (none for a name), and the [pass] line.
Map<String, Object?> puppetJson({
  String course = 'eng',
  required String id,
  String? skill,
  required String mode,
  String picture = 'cat',
  Map<String, Object?>? key,
  List<Map<String, Object?>> options = const <Map<String, Object?>>[],
  String? correct,
  String? topic,
}) {
  final bool personal = mode == 'personal';
  return <String, Object?>{
    ..._common(
      course,
      id,
      skill ?? '${course.toUpperCase()}-A-02',
      'puppet_talk',
      '1.0',
      personal ? 'practice' : 'learn',
      'A',
      'story',
    ),
    ..._lines(
      '$course.$id',
      promptText: 'הַקְשִׁיבוּ לַבֻּבָּה, וְאָז גְּעוּ בַּבֻּעָה.',
      target: 'vo:$course.$id.puppet',
    ),
    'scene': <String, Object?>{'picture': 'asset:$picture', 'key': ?key},
    'answer': personal
        ? <String, Object?>{
            'type': 'none',
            'mode': 'personal',
            'topic': topic,
            'options': options,
            'pass': line('vo:$course.$id.pass', 'זֶה בְּסֵדֶר!'),
          }
        : <String, Object?>{
            'type': 'choice',
            'mode': 'bubble',
            'options': options,
            'correct': correct,
            'shuffle': true,
            'unsureAllowed': true,
          },
  };
}

// ---- the drum (LS03) ----

/// A drum item of [course] (LS03): the word [word] with its picture, [beats] parts, and the tags a count one more and one fewer map to.
Map<String, Object?> drumJson({
  String course = 'eng',
  required String id,
  String? skill,
  String picture = 'cat',
  required int beats,
  String? more,
  String? fewer,
  String purpose = 'learn',
  bool slow = true,
  bool drumSound = true,
}) => <String, Object?>{
  ..._common(
    course,
    id,
    skill ?? '${course.toUpperCase()}-A-02',
    'sound_boxes',
    '1.0',
    purpose,
    'A',
    'concrete',
  ),
  ..._lines('$course.$id', promptText: 'הַקְשִׁיבוּ לַמִּלָּה, וְתוֹפְפוּ פַּעַם אַחַת לְכׇל חֵלֶק.'),
  'scene': <String, Object?>{
    'picture': 'asset:$picture',
    'word': <String>['vo:$course.$id.word'],
    if (slow) 'slow': <String>['vo:$course.$id.slow'],
    if (drumSound) 'drum': 'vo:$course.drum',
  },
  'answer': <String, Object?>{
    'type': 'drum',
    'mode': 'drum',
    'beats': beats,
    'classifiers': <Object?>[
      if (more != null) <String, Object?>{'when': 'one_more', 'misconception': more},
      if (fewer != null) <String, Object?>{'when': 'one_fewer', 'misconception': fewer},
    ],
  },
};
