// The invariants of docs/languages/frame.md section 1.5: courses never mix. Each one is tested twice: on the documents of a
// small fixture course (not real content) by the pack validator, which refuses a pack that breaks it, and on the engine's
// catalogue by `courseProblems`, which is what a merged catalogue of several packs is held to.
import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/content/pack_validation.dart';
import 'package:nitznutz/content/schema.dart';
import 'package:nitznutz/engine/course.dart';
import 'package:nitznutz/engine/course_rules.dart';
import 'package:nitznutz/engine/types.dart';

import 'engine/course_fixtures.dart';
import 'support/sample_pack.dart';

const String _count = 'activity.count.butterflies.3.json';
const String _lesson = 'lesson.butterflies.json';
const String _skill1 = 'skill.ENG-A-01.json';
const String _skill2 = 'skill.ENG-A-02.json';
const String _tag1 = 'misconception.eng.cnt.double.json';

List<Problem> _run(SamplePack p) => validatePack(manifest: p.manifest, docs: p.docs, files: p.files);

Map<String, Object?> _m(Object? o) => o! as Map<String, Object?>;
List<Object?> _l(Object? o) => o! as List<Object?>;

/// Adds a file to the pack, to the manifest and to the list of its kind, as the builder would.
void _add(SamplePack p, String name, String list, String id, Map<String, Object?> doc) {
  p.docs[name] = doc;
  p.files.add(name);
  _l(p.manifest['files']).add(<String, Object?>{'name': name, 'sha256': '9' * 64, 'size': 1});
  _l(_m(p.manifest['entries'])[list]).add(id);
}

/// Another skill like `ENG-A-01`, with the given id, course and prerequisites.
void _addSkill(
  SamplePack p,
  String id, {
  List<Object?> prerequisites = const <Object?>[],
  String? course,
  String? domain,
}) {
  final Map<String, Object?> doc = Map<String, Object?>.of(p.doc(_skill1));
  doc['id'] = id;
  doc['prerequisites'] = prerequisites;
  if (course != null) doc['course'] = course;
  if (domain != null) doc['domain'] = domain;
  _add(p, 'skill.$id.json', 'skills', id, doc);
}

void _addTag(SamplePack p, String id, {List<Object?>? skills}) {
  final Map<String, Object?> doc = Map<String, Object?>.of(p.doc(_tag1));
  doc['id'] = id;
  if (skills != null) doc['skills'] = skills;
  _add(p, 'misconception.$id.json', 'misconceptions', id, doc);
}

Map<String, Object?> _need(String skill) => <String, Object?>{'skill': skill, 'weight': 1};

class Broken {
  const Broken(this.name, this.mutate, this.path, this.message);

  final String name;
  final void Function(SamplePack p) mutate;
  final String path;
  final String message;
}

final List<Broken> _eng = <Broken>[
  Broken(
    'the pack is not named lang-<course>',
    (SamplePack p) => p.manifest['id'] = 'english-course',
    'manifest.json › id',
    'must be named "lang-eng"',
  ),
  Broken(
    'a pack id that begins with lang- but names no language',
    (SamplePack p) => p.manifest['id'] = 'lang-fra',
    'manifest.json › id',
    'names no language course',
  ),
  Broken(
    'a document of another course in the pack',
    (SamplePack p) => p.doc(_count)['course'] = 'rus',
    'activity.count.butterflies.3.json › course',
    'a pack holds one course',
  ),
  Broken(
    'a lesson of another course in the pack',
    (SamplePack p) => p.doc(_lesson)['course'] = 'heb',
    'lesson.butterflies.json › course',
    'a pack holds one course',
  ),
  Broken(
    'a skill of another course in the pack',
    (SamplePack p) => _addSkill(p, 'RUS-A-01'),
    'skill.RUS-A-01.json › id',
    'is not a skill of the course eng',
  ),
  Broken(
    'a skill file that says another course than its pack',
    (SamplePack p) => p.doc(_skill2)['course'] = 'core',
    'skill.ENG-A-02.json › course',
    'a pack holds one course',
  ),
  Broken(
    '1: a prerequisite on a skill of another language',
    (SamplePack p) => p.doc(_skill2)['prerequisites'] = <Object?>[_need('RUS-A-01')],
    'skill.ENG-A-02.json › prerequisites[0].skill',
    'no prerequisite across courses',
  ),
  Broken(
    '1: a prerequisite on a skill of core',
    (SamplePack p) => p.doc(_skill2)['prerequisites'] = <Object?>[_need('NUM-A-03')],
    'skill.ENG-A-02.json › prerequisites[0].skill',
    'no prerequisite across courses',
  ),
  Broken(
    '1: a prerequisite on a skill that is not in the pack',
    (SamplePack p) => p.doc(_skill2)['prerequisites'] = <Object?>[_need('ENG-A-09')],
    'skill.ENG-A-02.json › prerequisites[0].skill',
    'is not in this pack',
  ),
  Broken(
    '2: an item that gives evidence for a skill of another course',
    (SamplePack p) => _l(p.doc(_count)['skills'])[0] = <String, Object?>{'id': 'HEB-A-01', 'weight': 1},
    'activity.count.butterflies.3.json › skills[0].id',
    'evidence never crosses courses',
  ),
  Broken(
    '2: an item that gives evidence for a skill of core',
    (SamplePack p) => _l(p.doc(_count)['skills']).add(<String, Object?>{'id': 'NUM-A-03', 'weight': 0.5}),
    'activity.count.butterflies.3.json › skills[1].id',
    'evidence never crosses courses',
  ),
  Broken(
    '2: a misconception that traces back to a skill of another course',
    (SamplePack p) => p.doc(_tag1)['skills'] = <Object?>['RUS-A-01'],
    'misconception.eng.cnt.double.json › skills[0]',
    'is not a skill of the course eng',
  ),
  Broken(
    '2: a misconception tag of another course',
    (SamplePack p) => _addTag(p, 'rus.cnt.new'),
    'misconception.rus.cnt.new.json › id',
    'is not a misconception tag of the course eng',
  ),
  Broken(
    '2: a misconception tag in the form of core',
    (SamplePack p) => _addTag(p, 'M-CNT-NEW'),
    'misconception.M-CNT-NEW.json › id',
    'is not a misconception tag of the course eng',
  ),
  Broken(
    '2: an item or feedback that names a tag the pack does not have (a tag of another course)',
    (SamplePack p) => p.doc(_count)['contradicts'] = 'rus.cnt.double',
    'activity.count.butterflies.3.json › contradicts',
    'not in the misconception catalogue of this pack',
  ),
  Broken(
    '2: a repair activity that is not in the pack',
    (SamplePack p) => p.doc(_tag1)['repairActivities'] = <Object?>['rus.activity.x'],
    'misconception.eng.cnt.double.json › repairActivities[0]',
    'there is no activity',
  ),
  Broken(
    '5: a lesson that mixes courses (a skill of another course)',
    (SamplePack p) => _l(p.doc(_lesson)['skills']).add('RUS-A-01'),
    'lesson.butterflies.json › skills[1]',
    'is not a skill of the course eng',
  ),
  Broken(
    'a language skill outside the domain languages',
    (SamplePack p) => p.doc(_skill1)['domain'] = 'numbers',
    'skill.ENG-A-01.json › domain',
    'must be languages in the language course eng',
  ),
  Broken(
    'a language activity outside the domain languages',
    (SamplePack p) => p.doc(_count)['domain'] = 'colors',
    'activity.count.butterflies.3.json › domain',
    'must be languages in the language course eng',
  ),
  Broken(
    'a skill id with the capitals of another course',
    (SamplePack p) => _addSkill(p, 'HEB-A-01'),
    'skill.HEB-A-01.json › id',
    'must be ENG-<BAND>-<NN>',
  ),
  Broken(
    'the AI tutor allowed in a language activity',
    (SamplePack p) => _m(p.doc(_count)['tutor'])['llmAllowed'] = true,
    'activity.count.butterflies.3.json › tutor.llmAllowed',
    'the AI tutor is off in language lessons',
  ),
  Broken(
    'a group without its roll-up skill',
    (SamplePack p) => _addSkill(p, 'ENG-A-05.G1'),
    'skill.ENG-A-05.G1.json › id',
    'ENG-A-05, which is not in this pack',
  ),
  Broken(
    'a group that needs its own roll-up',
    (SamplePack p) {
      _addSkill(p, 'ENG-A-01.G1', prerequisites: <Object?>[_need('ENG-A-01')]);
    },
    'skill.ENG-A-01.G1.json › prerequisites[0].skill',
    'cannot need its own roll-up',
  ),
  Broken(
    'a roll-up that has prerequisites of its own',
    (SamplePack p) {
      _addSkill(p, 'ENG-A-02.G1');
      p.doc(_skill2)['prerequisites'] = <Object?>[_need('ENG-A-01')];
    },
    'skill.ENG-A-02.json › prerequisites',
    'a roll-up has none of its own',
  ),
  Broken(
    'an item that names a roll-up instead of one of its groups',
    (SamplePack p) {
      _addSkill(p, 'ENG-A-01.G1');
    },
    'activity.count.butterflies.3.json › skills[0].id',
    'is a roll-up with no estimate of its own',
  ),
];

void main() {
  group('the fixture course is valid, so each case below fails for its one reason', () {
    for (final String c in Course.languages) {
      test(c, () => expect(_run(SamplePack.language(c)), isEmpty));
    }

    test('groups with a roll-up are valid, and a skill may need a roll-up (it means all its groups)', () {
      final SamplePack p = SamplePack.language('eng');
      _addSkill(p, 'ENG-A-01.G1');
      _addSkill(p, 'ENG-A-01.G2');
      p.doc(_skill1)['prerequisites'] = <Object?>[];
      _l(p.doc(_count)['skills'])[0] = <String, Object?>{'id': 'ENG-A-01.G1', 'weight': 1};
      p.doc('activity.pick.red.flower.json')['skills'] = <Object?>[
        <String, Object?>{'id': 'ENG-A-01.G2', 'weight': 1},
      ];
      p.doc('activity.give.three.jar.json')['skills'] = <Object?>[
        <String, Object?>{'id': 'ENG-A-01.G2', 'weight': 1},
      ];
      p.doc(_lesson)['skills'] = <Object?>['ENG-A-01.G1', 'ENG-A-01.G2'];
      p.doc(_skill2)['prerequisites'] = <Object?>[_need('ENG-A-01')];
      expect(_run(p), isEmpty);
    });
  });

  group('a broken language pack is refused with the right path and reason', () {
    for (final Broken b in _eng) {
      test(b.name, () {
        final SamplePack p = SamplePack.language('eng');
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

  group('core stays core', () {
    test('a pack with a language\'s id must say so', () {
      final SamplePack p = SamplePack()..manifest['id'] = 'lang-eng';
      expect(
        _run(p).where((Problem x) => x.message.contains('the pack says it is core')),
        isNotEmpty,
        reason: _run(p).join('\n'),
      );
    });

    test('a core pack cannot hold a language skill, domain or tag', () {
      final SamplePack p = SamplePack();
      p.doc(skillFile)['domain'] = 'languages';
      expect(
        _run(
          p,
        ).where((Problem x) => x.path == 'skill.NUM-A-03.json › domain' && x.message.contains('not to core')),
        isNotEmpty,
      );
      final SamplePack q = SamplePack();
      _add(q, 'misconception.eng.cnt.x.json', 'misconceptions', 'eng.cnt.x', <String, Object?>{
        ...q.doc(tagFile),
        'id': 'eng.cnt.x',
      });
      expect(
        _run(q).where(
          (Problem x) =>
              x.path == 'misconception.eng.cnt.x.json › id' &&
              x.message.contains('not a misconception tag of the course core'),
        ),
        isNotEmpty,
      );
    });

    test('a core pack with a document that says another course is refused too', () {
      final SamplePack p = SamplePack();
      p.doc(countFile)['course'] = 'eng';
      expect(_run(p).where((Problem x) => x.message.contains('a pack holds one course')), isNotEmpty);
    });
  });

  group('the catalogue the engine holds', () {
    test('four courses, each one clean, merge into one catalogue with no problem', () {
      for (final String c in Course.all) {
        expect(courseProblems(miniCatalog(c)), isEmpty, reason: c);
      }
      expect(courseProblems(allCourses()), isEmpty);
      expect(allCourses().skills.length, 12);
    });

    Catalog engWith({
      List<SkillNode> skills = const <SkillNode>[],
      List<ItemMeta> items = const <ItemMeta>[],
      List<TagInfo> tags = const <TagInfo>[],
    }) {
      final ({List<SkillNode> skills, List<ItemMeta> items, List<TagInfo> tags}) e = miniCourse('eng');
      return Catalog(
        skills: <SkillNode>[...e.skills, ...skills],
        items: <ItemMeta>[...e.items, ...items],
        tags: <TagInfo>[...e.tags, ...tags],
      );
    }

    void refuses(Catalog c, String text) {
      final List<String> ps = courseProblems(c);
      expect(ps.where((String p) => p.contains(text)), isNotEmpty, reason: 'wanted "$text", got $ps');
    }

    test('1: no prerequisite across courses, nor between a course and core', () {
      refuses(
        engWith(
          skills: <SkillNode>[
            const SkillNode(id: 'ENG-C-01', course: 'eng', prerequisites: <String, double>{'RUS-A-01': 1}),
            const SkillNode(id: 'RUS-A-01', course: 'rus'),
          ],
        ),
        'no prerequisite across courses',
      );
      refuses(
        engWith(
          skills: <SkillNode>[
            const SkillNode(id: 'ENG-C-01', course: 'eng', prerequisites: <String, double>{'SK-A-01': 1}),
            const SkillNode(id: 'SK-A-01'),
          ],
        ),
        'no prerequisite across courses',
      );
      refuses(
        engWith(
          skills: <SkillNode>[
            const SkillNode(id: 'SK-C-01', prerequisites: <String, double>{'ENG-A-01': 1}),
          ],
        ),
        'no prerequisite across courses',
      );
    });

    test('the id prefix and the course of a skill must agree', () {
      refuses(
        engWith(
          skills: <SkillNode>[const SkillNode(id: 'RUS-A-09', course: 'eng')],
        ),
        'its id belongs to rus',
      );
      refuses(engWith(skills: <SkillNode>[const SkillNode(id: 'ENG-A-09')]), 'its id belongs to eng');
      refuses(
        engWith(
          skills: <SkillNode>[const SkillNode(id: 'X-A-09', course: 'fra')],
        ),
        'unknown course fra',
      );
    });

    test(
      '2 and 3: an item\'s skills, tags and contradicts are all in its own course; evidence never crosses',
      () {
        refuses(
          engWith(
            skills: <SkillNode>[const SkillNode(id: 'RUS-A-01', course: 'rus')],
            items: <ItemMeta>[
              const ItemMeta(id: 'x.1', course: 'eng', skills: <String, double>{'RUS-A-01': 1}),
            ],
          ),
          'evidence never crosses courses',
        );
        refuses(
          engWith(
            items: <ItemMeta>[
              const ItemMeta(
                id: 'x.2',
                course: 'eng',
                skills: <String, double>{'ENG-A-01': 1},
                tags: <String>{'rus.ph.dir'},
              ),
            ],
          ),
          'names the misconception rus.ph.dir',
        );
        refuses(
          engWith(
            items: <ItemMeta>[
              const ItemMeta(
                id: 'x.3',
                course: 'eng',
                skills: <String, double>{'ENG-A-01': 1},
                contradicts: 'M-DIR',
              ),
            ],
          ),
          'names the misconception M-DIR',
        );
      },
    );

    test('2: a misconception traces back and is repaired inside its own course', () {
      refuses(
        engWith(
          skills: <SkillNode>[const SkillNode(id: 'HEB-A-01', course: 'heb')],
          tags: <TagInfo>[
            const TagInfo(id: 'eng.ph.x', course: 'eng', skills: <String>['HEB-A-01']),
          ],
        ),
        'traces back to HEB-A-01',
      );
      refuses(
        engWith(
          items: <ItemMeta>[
            const ItemMeta(id: 'h.1', course: 'heb', skills: <String, double>{'HEB-A-01': 1}),
          ],
          skills: <SkillNode>[const SkillNode(id: 'HEB-A-01', course: 'heb')],
          tags: <TagInfo>[
            const TagInfo(id: 'eng.ph.y', course: 'eng', repairActivities: <String>['h.1']),
          ],
        ),
        'a repair never mixes courses',
      );
      refuses(
        engWith(
          tags: <TagInfo>[const TagInfo(id: 'rus.ph.z', course: 'eng')],
        ),
        'its id belongs to rus',
      );
    });

    test('an item cannot name a roll-up', () {
      refuses(
        engWith(
          skills: <SkillNode>[
            const SkillNode(id: 'ENG-B-19', course: 'eng'),
            const SkillNode(id: 'ENG-B-19.G1', course: 'eng'),
          ],
          items: <ItemMeta>[
            const ItemMeta(id: 'r.1', course: 'eng', skills: <String, double>{'ENG-B-19': 1}),
          ],
        ),
        'a roll-up with no estimate of its own',
      );
    });

    test('merging refuses an id that two packs both have, and a mix of courses', () {
      expect(
        () => mergeCatalogs(<Catalog>[miniCatalog('eng'), miniCatalog('eng')]),
        throwsA(
          isA<StateError>().having((StateError e) => e.message, 'message', contains('more than one pack')),
        ),
      );
      final Catalog mixed = engWith(
        skills: <SkillNode>[
          const SkillNode(id: 'ENG-C-01', course: 'eng', prerequisites: <String, double>{'SK-A-01': 1}),
        ],
      );
      expect(
        () => mergeCatalogs(<Catalog>[mixed, miniCatalog('core')]),
        throwsA(isA<StateError>().having((StateError e) => e.message, 'message', contains('courses mix'))),
      );
    });
  });
}
