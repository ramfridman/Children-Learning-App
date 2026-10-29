import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/content/pack_validation.dart';
import 'package:nitznutz/content/schema.dart';

import 'support/sample_pack.dart';

typedef Mutate = void Function(SamplePack p);

Map<String, Object?> _m(Object? o) => o! as Map<String, Object?>;
List<Object?> _l(Object? o) => o! as List<Object?>;

List<Problem> _run(SamplePack p) => validatePack(manifest: p.manifest, docs: p.docs, files: p.files);

/// Adds a file to the pack and to the manifest, as the builder would.
void _addFile(SamplePack p, String name, {Object? doc}) {
  p.files.add(name);
  _l(p.manifest['files']).add(<String, Object?>{'name': name, 'sha256': '9' * 64, 'size': 1});
  if (doc != null) p.docs[name] = doc;
}

class Broken {
  const Broken(this.name, this.mutate, this.path, this.message);

  final String name;
  final Mutate mutate;

  /// The exact path the problem must carry.
  final String path;

  /// Text the message must contain.
  final String message;
}

const String _c = countFile;
const String _t = tapFile;
const String _g = giveFile;

// Each case breaks one thing in an otherwise valid pack.
final List<Broken> _cases = <Broken>[
  // ---- manifest ----
  Broken(
    'manifest: unknown field',
    (SamplePack p) => p.manifest['evil'] = 1,
    'manifest.json',
    'unknown field "evil"',
  ),
  Broken(
    'manifest: id with a space and capitals',
    (SamplePack p) => p.manifest['id'] = 'Bad ID',
    'manifest.json › id',
    'does not match the pattern',
  ),
  Broken(
    'manifest: version without three parts',
    (SamplePack p) => p.manifest['version'] = '1.0',
    'manifest.json › version',
    'does not match the pattern',
  ),
  Broken(
    'manifest: the same file name twice',
    (SamplePack p) =>
        _l(p.manifest['files']).insert(1, Map<String, Object?>.of(_m(_l(p.manifest['files'])[0]))),
    'manifest.json › files[1].name',
    'is used twice',
  ),
  Broken(
    'manifest: a file name that climbs out of the folder',
    (SamplePack p) => _m(_l(p.manifest['files'])[0])['name'] = '../evil.json',
    'manifest.json › files[0].name',
    'does not match the pattern',
  ),
  Broken(
    'manifest: a file name with a slash',
    (SamplePack p) => _m(_l(p.manifest['files'])[0])['name'] = 'sub/dir.json',
    'manifest.json › files[0].name',
    'does not match the pattern',
  ),
  Broken(
    'manifest: a hash that is not 64 hex digits',
    (SamplePack p) => _m(_l(p.manifest['files'])[0])['sha256'] = 'XYZ',
    'manifest.json › files[0].sha256',
    'does not match the pattern',
  ),
  Broken(
    'manifest: a negative size',
    (SamplePack p) => _m(_l(p.manifest['files'])[0])['size'] = -1,
    'manifest.json › files[0].size',
    'is outside',
  ),
  Broken(
    'manifest: more than 8,000 files',
    (SamplePack p) => p.manifest['files'] = <Object?>[
      for (int i = 0; i < 8001; i++) <String, Object?>{'name': 'f$i.bin', 'sha256': '1' * 64, 'size': 1},
    ],
    'manifest.json › files',
    '8001 items is outside 1 to 8000',
  ),
  Broken(
    'manifest: no files',
    (SamplePack p) => p.manifest['files'] = <Object?>[],
    'manifest.json › files',
    '0 items',
  ),
  Broken(
    'manifest: asset id with capitals',
    (SamplePack p) => _m(_l(p.manifest['assets'])[0])['id'] = 'Butterfly',
    'manifest.json › assets[0].id',
    'does not match the pattern',
  ),
  Broken(
    'manifest: a template name of the wrong shape',
    (SamplePack p) => _m(p.manifest['templates'])['Drag Sort'] = '1.0',
    'manifest.json › templates',
    'the key "Drag Sort" does not match the pattern',
  ),
  // ---- the pack against its manifest ----
  Broken(
    'pack: a listed file is missing',
    (SamplePack p) => p.files.remove(skill2File),
    'manifest.json › files',
    '"skill.NUM-A-04.json" is listed but missing from the pack',
  ),
  Broken(
    'pack: a file the manifest does not list',
    (SamplePack p) => p.files.add('extra.json'),
    'extra.json',
    'is in the pack but not in the manifest',
  ),
  Broken(
    'pack: an asset points at a file that is not listed',
    (SamplePack p) => _m(_l(p.manifest['assets'])[0])['file'] = 'ghost.svg',
    'manifest.json › assets',
    '"ghost.svg" is not in the file list',
  ),
  Broken(
    'pack: a file nothing uses',
    (SamplePack p) => _addFile(p, 'orphan.svg'),
    'orphan.svg',
    'is not used by any asset or voice line',
  ),
  Broken(
    'pack: a voice line both recorded and pending',
    (SamplePack p) => _l(p.manifest['voPending']).add('vo:prompt.count.butterflies.3'),
    'manifest.json › voPending',
    'both recorded and pending',
  ),
  Broken(
    'pack: a JSON file listed as an asset',
    (SamplePack p) => _m(_l(p.manifest['assets'])[0])['file'] = skillFile,
    skillFile,
    'is a JSON file but is listed as an asset',
  ),
  Broken(
    'pack: an activity the manifest does not declare',
    (SamplePack p) => _l(_m(p.manifest['entries'])['activities']).removeLast(),
    'manifest.json › entries.activities',
    '"give.three.jar" is in the pack but not declared',
  ),
  Broken(
    'pack: an activity declared but with no file',
    (SamplePack p) => _l(_m(p.manifest['entries'])['activities']).add('ghost.one'),
    'manifest.json › entries.activities',
    '"ghost.one" is declared but there is no such file',
  ),
  Broken(
    'pack: the manifest does not promise a template an activity uses',
    (SamplePack p) => _m(p.manifest['templates']).remove('give_n'),
    'manifest.json › templates',
    'does not list "give_n"',
  ),
  Broken(
    'pack: a JSON file that is not an object',
    (SamplePack p) => p.docs[skill2File] = <Object?>[],
    skill2File,
    'is not a JSON object',
  ),
  Broken(
    'pack: a JSON file of an unknown kind',
    (SamplePack p) => _addFile(p, 'poem.x.json', doc: <String, Object?>{}),
    'poem.x.json',
    'unknown kind "poem"',
  ),
  Broken(
    'pack: a JSON file with no id in its name',
    (SamplePack p) => _addFile(p, 'poem.json', doc: <String, Object?>{}),
    'poem.json',
    'is not <kind>.<id>.json',
  ),
  // ---- activities ----
  Broken('activity: unknown field', (SamplePack p) => p.doc(_c)['extra'] = 1, _c, 'unknown field "extra"'),
  Broken('activity: missing prompt', (SamplePack p) => p.doc(_c).remove('prompt'), _c, 'missing "prompt"'),
  Broken(
    'activity: a template this app cannot play',
    (SamplePack p) => p.doc(_c)['template'] = 'drag_sort',
    '$_c › template',
    'is not a template this version of the app can play',
  ),
  Broken(
    'activity: id differs from the file name',
    (SamplePack p) => p.doc(_c)['id'] = 'count.butterflies.4',
    '$_c › id',
    'must equal "count.butterflies.3"',
  ),
  Broken(
    'activity: the correct option does not exist',
    (SamplePack p) => _m(p.doc(_c)['answer'])['correct'] = 'o9',
    '$_c › answer.correct',
    'is not the id of any option',
  ),
  Broken(
    'activity: the correct option carries a misconception',
    (SamplePack p) => _m(_l(_m(p.doc(_c)['answer'])['options'])[1])['misconception'] = 'M-CNT-DOUBLE',
    '$_c › answer.options[1].misconception',
    'the correct option cannot carry a misconception',
  ),
  Broken(
    'count_tap: the correct number is not the number of objects',
    (SamplePack p) => _m(_m(p.doc(_c)['scene'])['objects'])['count'] = 4,
    '$_c › answer.correct',
    'must show the number of objects (4)',
  ),
  Broken(
    'count_tap: two options show the same number',
    (SamplePack p) => _m(_l(_m(p.doc(_c)['answer'])['options'])[0])['value'] = 3,
    '$_c › answer.options',
    'two options show the same number',
  ),
  Broken(
    'count_tap: more objects than the screen takes',
    (SamplePack p) => _m(_m(p.doc(_c)['scene'])['objects'])['count'] = 21,
    '$_c › scene.objects.count',
    'is outside 1 to 20',
  ),
  Broken(
    'activity: a tag that is not in the catalogue (option)',
    (SamplePack p) => _m(_l(_m(p.doc(_c)['answer'])['options'])[2])['misconception'] = 'M-CNT-NOPE',
    '$_c › answer.options[2].misconception',
    'not in the misconception catalogue',
  ),
  Broken(
    'activity: a tag that is not in the catalogue (feedback rule)',
    (SamplePack p) => _m(_l(_m(p.doc(_c)['feedback'])['incorrect'])[1])['when'] = 'misconception:M-CNT-NOPE',
    '$_c › feedback.incorrect[1].when',
    'not in the misconception catalogue',
  ),
  Broken(
    'count_tap: a tag that is not in the catalogue (trace classifier)',
    (SamplePack p) => _m(_l(p.doc(_c)['traceClassifiers'])[0])['misconception'] = 'M-CNT-NOPE',
    '$_c › traceClassifiers[0].misconception',
    'not in the misconception catalogue',
  ),
  Broken(
    'activity: contradicts a tag that is not in the catalogue',
    (SamplePack p) => p.doc(_c)['contradicts'] = 'M-CNT-NOPE',
    '$_c › contradicts',
    'not in the misconception catalogue',
  ),
  Broken(
    'skill: a mastery requirement out of range',
    (SamplePack p) => p.doc(skillFile)['masteryRequires'] = <String, Object?>{'successes': 99},
    '$skillFile › masteryRequires.successes',
    'is outside 1 to 20',
  ),
  Broken(
    'skill: an unknown mastery requirement',
    (SamplePack p) => p.doc(skillFile)['masteryRequires'] = <String, Object?>{'speed': 1},
    '$skillFile › masteryRequires',
    'unknown field "speed"',
  ),
  Broken(
    'activity: no default feedback rule',
    (SamplePack p) => _l(_m(p.doc(_c)['feedback'])['incorrect']).removeAt(0),
    '$_c › feedback.incorrect',
    'needs a rule with "when": "default"',
  ),
  Broken(
    'activity: hints out of order',
    (SamplePack p) {
      _m(_l(p.doc(_c)['hints'])[0])['level'] = 3;
      _m(_l(p.doc(_c)['hints'])[2])['level'] = 1;
    },
    '$_c › hints[0].level',
    'numbered 1, 2, 3 in order',
  ),
  Broken(
    'tap_answer: an option that is a picture and a numeral at once',
    (SamplePack p) => _m(_l(_m(p.doc(_t)['answer'])['options'])[0])['numeral'] = 3,
    '$_t › answer.options[0]',
    'exactly one of a sprite, a numeral or a set',
  ),
  Broken(
    'tap_answer: two options that look the same',
    (SamplePack p) {
      final List<Object?> o = _l(_m(p.doc(_t)['answer'])['options']);
      _m(o[1])['sprite'] = _m(o[0])['sprite'];
    },
    '$_t › answer.options',
    'two options look the same',
  ),
  Broken(
    'tap_answer: a group whose picture is not in the pack',
    (SamplePack p) => _m(p.doc(_t)['scene'])['group'] = <String, Object?>{'sprite': 'asset:nope', 'count': 3},
    '$_t › scene.group.sprite',
    'is not in the manifest assets',
  ),
  Broken(
    'activity: the second hint helps in the same way as the first',
    (SamplePack p) => _m(_l(p.doc(_c)['hints'])[1])['action'] = 'replay_prompt_slow',
    '$_c › hints[1].action',
    'different way than level 1',
  ),
  Broken(
    'activity: a question that is too long to hold in mind',
    (SamplePack p) =>
        _m(_l(_m(p.doc(_c)['prompt'])['caption'])[0])['v'] = List<String>.filled(15, 'בָּאוּ').join(' '),
    '$_c › prompt.caption',
    'is at most 14 words',
  ),
  Broken(
    'count_tap: no wrong answer names a misconception',
    (SamplePack p) {
      for (final Object? o in _l(_m(p.doc(_c)['answer'])['options'])) {
        _m(o).remove('misconception');
      }
    },
    '$_c › answer.options',
    'must name the misconception',
  ),
  Broken(
    'activity: a caption with a greater-than sign',
    (SamplePack p) => _m(_l(_m(p.doc(_c)['prompt'])['caption'])[0])['v'] = 'בָּא > בָּא',
    '$_c › prompt.caption[0].v',
    'turn over in right-to-left text',
  ),
  Broken(
    'activity: credit grows with more hints',
    (SamplePack p) => _m(p.doc(_c)['scoring'])['creditByHintLevel'] = <Object?>[1, 0.5, 0.75, 0],
    '$_c › scoring.creditByHintLevel',
    'must not grow',
  ),
  Broken(
    'activity: a sprite that is not in the manifest',
    (SamplePack p) => _m(_m(p.doc(_c)['scene'])['objects'])['sprite'] = 'asset:nope',
    '$_c › scene.objects.sprite',
    'is not in the manifest assets',
  ),
  Broken(
    'activity: a voice line that is neither recorded nor pending',
    (SamplePack p) => _m(p.doc(_c)['prompt'])['vo'] = 'vo:nope',
    '$_c › prompt.vo',
    'neither recorded nor listed in voPending',
  ),
  Broken(
    'count_tap: the "how many" line is not known',
    (SamplePack p) => _m(p.doc(_c)['answerPrompt'])['vo'] = 'vo:nope',
    '$_c › answerPrompt.vo',
    'neither recorded nor listed in voPending',
  ),
  Broken(
    'activity: a skill that is not in the pack',
    (SamplePack p) => _m(_l(p.doc(_c)['skills'])[0])['id'] = 'NUM-A-09',
    '$_c › skills[0].id',
    'the skill NUM-A-09 is not in this pack',
  ),
  Broken(
    'activity: an option id of the wrong shape',
    (SamplePack p) => _m(_l(_m(p.doc(_c)['answer'])['options'])[0])['id'] = 'x1',
    '$_c › answer.options[0].id',
    'does not match the pattern',
  ),
  Broken(
    'activity: five options',
    (SamplePack p) => _l(_m(p.doc(_c)['answer'])['options'])
      ..add(<String, Object?>{'id': 'o4', 'value': 5})
      ..add(<String, Object?>{'id': 'o5', 'value': 6}),
    '$_c › answer.options',
    '5 items is outside 2 to 4',
  ),
  Broken(
    'activity: two captions',
    (SamplePack p) => _l(_m(p.doc(_c)['prompt'])['caption']).add(<String, Object?>{'t': 'he', 'v': 'עוֹד'}),
    '$_c › prompt.caption',
    '2 items is outside 1 to 1',
  ),
  Broken(
    'activity: a caption in another language',
    (SamplePack p) => _m(_l(_m(p.doc(_c)['prompt'])['caption'])[0])['t'] = 'en',
    '$_c › prompt.caption[0].t',
    'must be "he"',
  ),
  Broken(
    'activity: a string that is far too long',
    (SamplePack p) => _m(p.doc(_c)['tutor'])['goal'] = 'x' * 201,
    '$_c › tutor.goal',
    'length 201',
  ),
  Broken(
    'activity: a control character in a caption',
    (SamplePack p) => _m(_l(_m(p.doc(_c)['prompt'])['caption'])[0])['v'] = 'סְפֹר\u0007',
    '$_c › prompt.caption[0].v',
    'contains a control character',
  ),
  Broken(
    'activity: Latin letters in a caption',
    (SamplePack p) => _m(_l(_m(p.doc(_c)['prompt'])['caption'])[0])['v'] = 'Count the butterflies',
    '$_c › prompt.caption[0].v',
    'contains Latin letters',
  ),
  Broken(
    'activity: a caption with no Hebrew',
    (SamplePack p) => _m(_l(_m(p.doc(_c)['prompt'])['caption'])[0])['v'] = '3',
    '$_c › prompt.caption[0].v',
    'contains no Hebrew',
  ),
  Broken(
    'activity: a Band A word without niqqud',
    (SamplePack p) => _m(_l(_m(p.doc(_c)['prompt'])['caption'])[0])['v'] = 'סְפֹר פרפרים',
    '$_c › prompt.caption[0].v',
    'the word "פרפרים" has no niqqud',
  ),
  Broken(
    'activity: a hint caption without niqqud',
    (SamplePack p) => _m(_l(p.doc(_c)['hints'])[0])['caption'] = <Object?>[
      <String, Object?>{'t': 'he', 'v': 'נקשיב שוב'},
    ],
    '$_c › hints[0].caption[0].v',
    'has no niqqud',
  ),
  Broken(
    'tap_answer: a background that is not in the manifest',
    (SamplePack p) => _m(p.doc(_t)['scene'])['background'] = 'asset:nope',
    '$_t › scene.background',
    'is not in the manifest assets',
  ),
  Broken(
    'tap_answer: an option sprite that is not in the manifest',
    (SamplePack p) => _m(_l(_m(p.doc(_t)['answer'])['options'])[1])['sprite'] = 'asset:nope',
    '$_t › answer.options[1].sprite',
    'is not in the manifest assets',
  ),
  Broken(
    'give_n: more to give than the jar holds',
    (SamplePack p) => _m(p.doc(_g)['answer'])['n'] = 7,
    '$_g › answer.n',
    'cannot be more than the 6 objects in the jar',
  ),
  Broken(
    'give_n: n out of range',
    (SamplePack p) => _m(p.doc(_g)['answer'])['n'] = 21,
    '$_g › answer.n',
    'is outside 1 to 20',
  ),
  Broken(
    'give_n: a classifier tag that is not in the catalogue',
    (SamplePack p) => _m(_l(_m(p.doc(_g)['answer'])['classifiers'])[0])['misconception'] = 'M-CNT-NOPE',
    '$_g › answer.classifiers[0].misconception',
    'not in the misconception catalogue',
  ),
  Broken(
    'give_n: a source sprite that is not in the manifest',
    (SamplePack p) => _m(_m(p.doc(_g)['scene'])['source'])['sprite'] = 'asset:nope',
    '$_g › scene.source.sprite',
    'is not in the manifest assets',
  ),
  // ---- lessons, skills, misconceptions ----
  Broken(
    'lesson: an item with no activity',
    (SamplePack p) => _l(p.doc(lessonFile)['items'])[1] = 'ghost',
    '$lessonFile › items[1]',
    'there is no activity "ghost" in this pack',
  ),
  Broken(
    'lesson: id differs from the file name',
    (SamplePack p) => p.doc(lessonFile)['id'] = 'other',
    '$lessonFile › id',
    'must equal "butterflies"',
  ),
  Broken(
    'lesson: celebration line not known',
    (SamplePack p) => _m(p.doc(lessonFile)['celebration'])['vo'] = 'vo:nope',
    '$lessonFile › celebration.vo',
    'neither recorded nor listed in voPending',
  ),
  Broken(
    'lesson: thirteen items',
    (SamplePack p) =>
        p.doc(lessonFile)['items'] = <Object?>[for (int i = 0; i < 13; i++) 'count.butterflies.3'],
    '$lessonFile › items',
    '13 items is outside 1 to 12',
  ),
  Broken(
    'lesson: a skill that is not in the pack',
    (SamplePack p) => _l(p.doc(lessonFile)['skills'])[0] = 'NUM-A-09',
    '$lessonFile › skills[0]',
    'the skill NUM-A-09 is not in this pack',
  ),
  Broken(
    'lesson: a title without niqqud',
    (SamplePack p) => _m(_l(p.doc(lessonFile)['title'])[0])['v'] = 'פרפרים',
    '$lessonFile › title[0].v',
    'has no niqqud',
  ),
  Broken(
    'skill: needs itself',
    (SamplePack p) => p.doc(skill2File)['prerequisites'] = <Object?>[
      <String, Object?>{'skill': 'NUM-A-04', 'weight': 1},
    ],
    '$skill2File › prerequisites[0].skill',
    'a skill cannot need itself',
  ),
  Broken(
    'skill: a tag that is not in the catalogue',
    (SamplePack p) => p.doc(skillFile)['misconceptions'] = <Object?>['M-CNT-NOPE'],
    '$skillFile › misconceptions[0]',
    'not in the misconception catalogue',
  ),
  Broken(
    'misconception: a repair activity that does not exist',
    (SamplePack p) => p.doc(tagFile)['repairActivities'] = <Object?>['ghost'],
    '$tagFile › repairActivities[0]',
    'there is no activity "ghost"',
  ),
  Broken(
    'misconception: a skill that is not in the pack',
    (SamplePack p) => p.doc(tagFile)['skills'] = <Object?>['NUM-A-09'],
    '$tagFile › skills[0]',
    'the skill NUM-A-09 is not in this pack',
  ),
];

final RegExp _niqqudChars = RegExp(r'[ְ-ׇ]');

void _stripNiqqud(Object? node) {
  if (node is Map<String, Object?>) {
    node.updateAll((String k, Object? v) {
      if (k == 'v' && v is String) return v.replaceAll(_niqqudChars, '');
      _stripNiqqud(v);
      return v;
    });
  } else if (node is List<Object?>) {
    node.forEach(_stripNiqqud);
  }
}

/// Every place in a document: a list of keys and indexes from the root.
Iterable<List<Object>> _allPaths(Object? node, [List<Object> prefix = const <Object>[]]) sync* {
  if (node is Map<String, Object?>) {
    for (final MapEntry<String, Object?> e in node.entries) {
      yield <Object>[...prefix, e.key];
      yield* _allPaths(e.value, <Object>[...prefix, e.key]);
    }
  } else if (node is List<Object?>) {
    for (final (int i, Object? e) in node.indexed) {
      yield <Object>[...prefix, i];
      yield* _allPaths(e, <Object>[...prefix, i]);
    }
  }
}

Object? _at(Object? root, List<Object> path) {
  Object? cur = root;
  for (final Object k in path) {
    cur = k is int ? (cur! as List<Object?>)[k] : (cur! as Map<String, Object?>)[k];
  }
  return cur;
}

void _put(Object root, List<Object> path, Object? value, {required bool remove}) {
  final Object? parent = _at(root, path.sublist(0, path.length - 1));
  final Object last = path.last;
  if (parent is List<Object?>) {
    if (remove) {
      parent.removeAt(last as int);
    } else {
      parent[last as int] = value;
    }
  } else if (parent is Map<String, Object?>) {
    if (remove) {
      parent.remove(last);
    } else {
      parent[last as String] = value;
    }
  }
}

void main() {
  test('the sample pack is valid', () {
    expect(_run(SamplePack()), isEmpty);
  });

  test('there are at least thirty broken files in the table', () {
    expect(_cases.length, greaterThanOrEqualTo(30));
  });

  group('a broken pack is refused with the right path and reason', () {
    for (final Broken b in _cases) {
      test(b.name, () {
        final SamplePack p = SamplePack();
        b.mutate(p);
        final List<Problem> ps = _run(p);
        expect(ps, isNotEmpty, reason: 'nothing was refused');
        expect(
          ps.where((Problem x) => x.path == b.path && x.message.contains(b.message)),
          isNotEmpty,
          reason: 'wanted "${b.path}: ${b.message}", got:\n${ps.join('\n')}',
        );
      });
    }
  });

  group('Hebrew house rules', () {
    test('Band C text is not pointed, and that is fine', () {
      final SamplePack p = SamplePack();
      final Map<String, Object?> a = p.doc(_c);
      a['band'] = 'C';
      _stripNiqqud(a);
      expect(_run(p), isEmpty);
    });

    test('the same unpointed text in Band A is refused', () {
      final SamplePack p = SamplePack();
      _stripNiqqud(p.doc(_c));
      final List<Problem> ps = _run(p);
      expect(ps.where((Problem x) => x.message.contains('no niqqud')), isNotEmpty);
    });

    test('a one-letter word needs no niqqud', () {
      final SamplePack p = SamplePack();
      _m(_l(_m(p.doc(_c)['prompt'])['caption'])[0])['v'] = 'סְפֹר אֶת ה';
      expect(_run(p), isEmpty);
    });
  });

  // SEC-12: every answer carries its lesson id, and sync-push takes at most 40 characters.
  test('a lesson id longer than sync-push takes is refused, and one of 40 characters is valid', () {
    List<Problem> withLessonId(String id) {
      final SamplePack p = SamplePack();
      final String file = 'lesson.$id.json';
      p.docs[file] = _m(p.docs.remove(lessonFile))..['id'] = id;
      p.files
        ..remove(lessonFile)
        ..add(file);
      p.manifestList('files').firstWhere((Map<String, Object?> f) => f['name'] == lessonFile)['name'] = file;
      _m(p.manifest['entries'])['lessons'] = <Object?>[id];
      return _run(p);
    }

    expect(withLessonId('l' * 40), isEmpty);
    // The manifest's list of lessons is checked first, and the lesson file itself has the same bound.
    expect(withLessonId('l' * 41).map((Problem x) => x.toString()), <String>[
      'manifest.json › entries.lessons[0]: length 41 is outside 3 to 40',
    ]);
  });

  test('a pack with a voice recording and no pending lines is valid', () {
    final SamplePack p = SamplePack();
    expect(_run(p), isEmpty);
    expect(_l(p.manifest['vo']), isNotEmpty);
  });

  test('wrong types and missing parts anywhere never make the validator throw', () {
    final SamplePack probe = SamplePack();
    final List<Object?> junk = <Object?>[null, 'x', 7, 1.5, true, <Object?>[], <String, Object?>{}];
    int tried = 0;
    // Each document and the manifest: every place gets every kind of wrong value, and is removed.
    final Map<String, Object> roots = <String, Object>{
      'manifest': probe.manifest,
      for (final MapEntry<String, Object?> e in probe.docs.entries) e.key: e.value!,
    };
    for (final MapEntry<String, Object> root in roots.entries) {
      for (final List<Object> path in _allPaths(root.value)) {
        for (final Object? value in <Object?>[...junk, #remove]) {
          final SamplePack p = SamplePack();
          final Object target = root.key == 'manifest' ? p.manifest : p.docs[root.key]!;
          _put(target, path, value, remove: value == #remove);
          expect(() => _run(p), returnsNormally, reason: '${root.key} › ${path.join('.')} = $value');
          tried++;
        }
      }
    }
    expect(tried, greaterThan(1000));
  });
}
