// F4 of docs/languages/frame.md: the course id (`core`, `eng`, `heb`, `rus`) on skills, items, tags, packs, progress and
// placement. Everything that exists today is `core` and must not change; a language pack is one signed pack per course.
import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/content/engine_adapter.dart';
import 'package:nitznutz/content/models.dart';
import 'package:nitznutz/content/pack_validation.dart';
import 'package:nitznutz/content/schema.dart';
import 'package:nitznutz/content/schemas.dart';
import 'package:nitznutz/data/app_database.dart';
import 'package:nitznutz/engine/course.dart';
import 'package:nitznutz/engine/types.dart';
import 'package:nitznutz/parent/progress.dart';
import 'package:nitznutz/world/placement.dart';

import 'engine/course_fixtures.dart';
import 'support/sample_pack.dart';
import 'support/starter.dart';

List<Problem> _run(SamplePack p) => validatePack(manifest: p.manifest, docs: p.docs, files: p.files);

Map<String, Object?> _skillDoc(String id, String course) => <String, Object?>{
  'schema': 'skill/v1',
  'id': id,
  'course': course,
  'domain': 'languages',
  'band': 'B',
  'title': <Object?>[
    <String, Object?>{'t': 'he', 'v': 'x'},
  ],
  'prerequisites': <Object?>[],
  'representations': <Object?>['concrete'],
  'misconceptions': <Object?>[],
  'retention': <String, Object?>{'targetRetention': 0.9, 'initialStabilityDays': 1},
};

void main() {
  group('the course ids', () {
    test('there are four, and three of them are languages in a fixed order', () {
      expect(Course.all, <String>['core', 'eng', 'heb', 'rus']);
      expect(Course.languages, <String>['eng', 'heb', 'rus']);
      expect(Course.isLanguage('core'), isFalse);
      expect(Course.isKnown('fra'), isFalse);
    });

    test('a pack id, a skill id and a tag each say their course', () {
      expect(Course.ofPackId('starter'), 'core');
      expect(Course.ofPackId('char-nitzi'), 'core');
      expect(Course.ofPackId('lang-eng'), 'eng');
      expect(Course.ofPackId('lang-rus'), 'rus');
      expect(Course.ofPackId('lang-fra'), isNull);
      expect(Course.packIdOf('heb'), 'lang-heb');
      expect(Course.packIdOf('core'), isNull);
      expect(Course.ofSkillId('NUM-A-03'), 'core');
      expect(Course.ofSkillId('ENG-B-19.G1'), 'eng');
      expect(Course.ofSkillId('HEB-B-14.S1'), 'heb');
      expect(Course.ofSkillId('RUS-B-24.G10'), 'rus');
      expect(Course.ofTag('M-CNT-DOUBLE'), 'core');
      expect(Course.ofTag('eng.ph.dir'), 'eng');
      expect(Course.skillPrefixOf('rus'), 'RUS');
    });

    test('a dotted skill id names its roll-up and keeps the band letter', () {
      expect(SkillIds.parentOf('HEB-B-14.S1'), 'HEB-B-14');
      expect(SkillIds.parentOf('HEB-B-14'), isNull);
      expect(SkillIds.isSub('RUS-B-24.G10'), isTrue);
      expect(SkillIds.levelOf('ENG-A-01'), 0);
      expect(SkillIds.levelOf('ENG-B-19.G2'), 1);
      expect(SkillIds.levelOf('RUS-C-08'), 2);
      expect(SkillIds.levelOf('weird'), -1);
    });

    test(
      'a skill\'s family ignores the group, so the representation statistics are shared by its groups',
      () {
        expect(const SkillNode(id: 'HEB-B-14.S1').family, 'HEB-B');
        expect(const SkillNode(id: 'HEB-B-14').family, 'HEB-B');
      },
    );
  });

  group('the engine\'s data', () {
    test('everything is core unless it says otherwise', () {
      expect(const SkillNode(id: 'NUM-A-01').course, 'core');
      expect(const ItemMeta(id: 'a', skills: <String, double>{'NUM-A-01': 1}).course, 'core');
      expect(const TagInfo(id: 'M-X').course, 'core');
    });

    test('a catalogue can be cut to one course: its skills, items and tags and nothing else', () {
      final Catalog all = allCourses();
      expect(all.courses, <String>{'core', 'eng', 'heb', 'rus'});
      for (final String c in Course.all) {
        final Catalog one = all.forCourse(c);
        expect(one.courses, <String>{c});
        expect(one.skills.length, 3);
        expect(one.items.length, 9);
        expect(one.tags.length, 1);
        expect(one.items.values.every((ItemMeta i) => i.course == c), isTrue);
      }
    });
  });

  group('the starter pack stays as it was', () {
    late PackContent starter;
    setUpAll(() async => starter = await loadStarter());

    test('it is core, without a course on its manifest or in any document', () {
      expect(starter.course, 'core');
      expect(starter.skills.values.every((SkillDoc s) => s.course == 'core'), isTrue);
      expect(starter.activities.values.every((Activity a) => a.course == 'core'), isTrue);
      expect(starter.tags.values.every((TagDoc t) => t.course == 'core'), isTrue);
      expect(starter.lessons.values.every((Lesson l) => l.course == 'core'), isTrue);
      expect(engineCatalog(starter).courses, <String>{'core'});
    });

    test('the AI tutor is allowed where the author allowed it, as before', () {
      expect(starter.activities.values.any((Activity a) => a.llmAllowed), isTrue);
    });
  });

  group('a language pack', () {
    for (final String course in Course.languages) {
      test('$course: the fixture pack is valid and everything in it is of the course', () {
        final SamplePack p = SamplePack.language(course);
        expect(_run(p), isEmpty);
        final PackContent content = PackContent.fromPack(p.verified());
        expect(content.course, course);
        expect(content.packId, 'lang-$course');
        expect(content.skills.keys.every((String id) => id.startsWith('${course.toUpperCase()}-')), isTrue);
        final Catalog catalog = engineCatalog(content);
        expect(catalog.courses, <String>{course});
        expect(catalog.skills.values.every((SkillNode s) => s.course == course), isTrue);
        expect(catalog.items.values.every((ItemMeta i) => i.course == course), isTrue);
        expect(catalog.tags.values.every((TagInfo t) => t.course == course), isTrue);
      });
    }

    test('the activities of a language course never allow the AI tutor, whatever the file says', () {
      final SamplePack p = SamplePack.language('eng');
      for (final MapEntry<String, Object?> d in p.docs.entries) {
        if (d.key.startsWith('activity.')) {
          ((d.value! as Map<String, Object?>)['tutor']! as Map<String, Object?>)['llmAllowed'] = true;
        }
      }
      final PackContent content = PackContent.fromPack(p.verified());
      expect(content.activities.values.every((Activity a) => !a.llmAllowed), isTrue);
    });

    test('a pack that names no course has none on its manifest', () {
      expect(SamplePack().manifest.containsKey('course'), isFalse);
      expect(SamplePack.language('rus').manifest['course'], 'rus');
    });

    test('the schemas take the course, the dotted skill ids and the language tag ids', () {
      expect(validate(skillSchema, _skillDoc('HEB-B-14.S1', 'heb')), isEmpty);
      expect(validate(skillSchema, _skillDoc('RUS-B-24.G10', 'rus')), isEmpty);
      expect(validate(skillSchema, _skillDoc('RUS-B-24.G10', 'fra')), isNotEmpty);
      expect(validate(skillSchema, _skillDoc('RUS-B-24.G1000', 'rus')), isNotEmpty);
      final Map<String, Object?> tag = <String, Object?>{
        'schema': 'misconception/v1',
        'id': 'eng.ph.dir',
        'course': 'eng',
        'skills': <Object?>['ENG-A-01'],
        'parentText': 'x',
        'repairActivities': <Object?>[],
        'preferredRepresentations': <Object?>[],
      };
      expect(validate(misconceptionSchema, tag), isEmpty);
      tag['id'] = 'eng.ph.Dir';
      expect(validate(misconceptionSchema, tag), isNotEmpty);
    });
  });

  group('progress keeps the courses apart', () {
    test('a language course is a block of its own, even though every language has the one domain', () {
      final Catalog catalog = allCourses();
      final Map<String, SkillInfo> info = <String, SkillInfo>{
        for (final SkillNode s in catalog.skills.values)
          s.id: SkillInfo(
            title: 'x',
            domain: s.course == Course.core ? 'numbers' : languagesDomain,
            course: s.course,
          ),
      };
      final Progress p = buildProgress(
        ProgressSource(
          catalog: catalog,
          skillInfo: info,
          tagText: const <String, String>{},
          attempts: const <AttemptEvent>[],
          sessions: const <Session>[],
          now: DateTime(2026, 11, 20, 12),
        ),
      );
      expect(<String>[for (final DomainBlock b in p.domains) b.key]..sort(), <String>[
        'eng',
        'heb',
        'numbers',
        'rus',
      ]);
      for (final DomainBlock b in p.domains) {
        expect(b.skills.length, 3, reason: b.key);
        expect(b.skills.every((SkillRow s) => Course.ofSkillId(s.id) == b.course), isTrue, reason: b.key);
      }
    });
  });

  group('placement ids', () {
    test('the lands keep `placement`; a language course has an id of its own', () {
      expect(placementId, 'placement');
      expect(placementIdFor('core'), 'placement');
      expect(placementIdFor('eng'), 'placement-eng');
      expect(courseOfPlacementId('placement'), 'core');
      expect(courseOfPlacementId('placement-rus'), 'rus');
      expect(courseOfPlacementId('placement-fra'), isNull);
      expect(courseOfPlacementId('butterflies'), isNull);
    });

    test('a revisit mission of a language skill is of that course', () {
      final Lesson m = Lesson.mission(
        id: 'mission-eng-a-01',
        itemIds: const <String>['x'],
        skillIds: const <String>['ENG-A-01'],
        celebration: const Spoken(vo: 'vo:a', caption: 'x'),
      );
      expect(m.course, 'eng');
    });
  });
}
