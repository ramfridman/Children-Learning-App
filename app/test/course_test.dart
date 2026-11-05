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
import 'package:nitznutz/engine/engine.dart';
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

  group('SEC-L0-1: evidence never crosses courses, even with an id in common', () {
    Catalog eng() => Catalog(
      skills: const <SkillNode>[SkillNode(id: 'ENG-A-01', course: Course.eng)],
      items: const <ItemMeta>[
        ItemMeta(id: 'count.butterflies.3', course: Course.eng, skills: <String, double>{'ENG-A-01': 1}),
      ],
    );

    test('an answer given in the lands is no evidence for a language item that has the same activity id', () {
      final Engine e = Engine(catalog: eng())
        ..replay(<AttemptEvent>[
          for (int i = 0; i < 6; i++)
            AttemptEvent(
              id: i + 1,
              at: DateTime.utc(2026, 11, 3, 10, i),
              activityId: 'count.butterflies.3',
              result: Result.correct,
              course: Course.core,
            ),
        ]);
      expect(e.state.skills['ENG-A-01']?.started ?? false, isFalse);
    });

    test(
      "its own course's answer is, and so is one that does not say its course (the simulator, a test)",
      () {
        for (final String? course in <String?>[Course.eng, null]) {
          final Engine e = Engine(catalog: eng())
            ..apply(
              AttemptEvent(
                at: DateTime.utc(2026, 11, 3),
                activityId: 'count.butterflies.3',
                result: Result.correct,
                course: course,
              ),
            );
          expect(e.state.skills['ENG-A-01']!.started, isTrue, reason: '$course');
        }
      },
    );

    test(
      'the rows of the database say their course through their pack: eventOf, for every reader of them',
      () {
        Attempt row(String pack) => Attempt(
          id: 1,
          at: DateTime.utc(2026, 11, 3),
          profileId: 'p-1',
          packId: pack,
          packVersion: '1.0.0',
          lessonId: '',
          activityId: 'count.butterflies.3',
          activityRevision: 1,
          template: 'count_tap',
          templateVersion: '1.0',
          skillId: 'NUM-A-03',
          result: 'correct',
          attemptNo: 1,
          hintLevel: 0,
          misconceptionTag: '',
          response: '',
          durationMs: 0,
          input: 'tap',
        );
        expect(eventOf(row('starter')).course, 'core');
        expect(eventOf(row('lang-rus')).course, 'rus');
        expect(eventOf(row('lang-xyz')).course, '', reason: 'a pack that names no course matches no item');
        // The core engine, which replays every row of the child, takes only the lands' rows.
        final Catalog core = Catalog(
          skills: const <SkillNode>[SkillNode(id: 'NUM-A-03')],
          items: const <ItemMeta>[
            ItemMeta(id: 'count.butterflies.3', skills: <String, double>{'NUM-A-03': 1}),
          ],
        );
        final Engine e = Engine(catalog: core)
          ..replay(<AttemptEvent>[eventOf(row('lang-eng')), eventOf(row('lang-xyz'))]);
        expect(e.state.skills, isEmpty);
        expect(
          (Engine(catalog: core)..replay(<AttemptEvent>[eventOf(row('starter'))])).state.skills.keys,
          <String>['NUM-A-03'],
        );
      },
    );

    test('an activity id says its course, and the pull guard looks at it', () {
      expect(Course.ofActivityId('eng.greet.i01'), 'eng');
      expect(Course.ofActivityId('rus.a'), 'rus');
      expect(Course.ofActivityId('count.butterflies.3'), 'core');
      expect(Course.ofActivityId('english.x'), 'core');
      expect(Course.ofAnswer(skillId: 'ENG-A-01', packId: 'lang-eng', activityId: 'eng.greet.i01'), 'eng');
      expect(
        Course.ofAnswer(skillId: 'ENG-A-01', packId: 'lang-eng', activityId: 'count.butterflies.3'),
        isNull,
      );
      expect(Course.ofAnswer(skillId: 'NUM-A-03', packId: 'starter', activityId: 'eng.greet.i01'), isNull);
      expect(
        Course.ofAnswer(skillId: 'NUM-A-03', packId: 'starter', activityId: 'count.butterflies.3'),
        'core',
      );
    });
  });

  group('the course of a lesson id in an answer (SEC-L4-4)', () {
    test('an answer filed under another course placement or lesson is refused; a lesson that names none says nothing', () {
      String? of(String lesson) => Course.ofAnswer(
        skillId: 'ENG-A-01',
        packId: 'lang-eng',
        activityId: 'eng.greet.i01',
        lessonId: lesson,
      );
      expect(of('placement-eng'), 'eng');
      expect(of('eng.greet'), 'eng');
      expect(of('placement-rus'), isNull);
      expect(of('rus.greet'), isNull);
      expect(of('mission:eng-a-01'), 'eng', reason: 'a revisit mission names no course');
      expect(of(''), 'eng');
      expect(Course.ofLessonId('placement'), isNull);
      expect(Course.ofLessonId('butterflies'), isNull);
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
