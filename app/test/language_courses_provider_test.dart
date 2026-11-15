// `languageCoursesProvider` with a real database and the fixture packs (L-course, part 6): the line that joins the placement staircase, its
// replay from the child's answers, the skills it assumes, `Engine.assume` and the engine's own replay, for each child and each course,
// as Today's Adventure, the course home and the parent's progress read it.
import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/app/language_providers.dart';
import 'package:nitznutz/content/engine_adapter.dart';
import 'package:nitznutz/content/models.dart';
import 'package:nitznutz/data/app_database.dart';
import 'package:nitznutz/engine/engine.dart';
import 'package:nitznutz/engine/state.dart';
import 'package:nitznutz/parent/language_progress.dart';
import 'package:nitznutz/parent/language_settings.dart';
import 'package:nitznutz/strings/he.dart';
import 'package:nitznutz/world/adventure_adapter.dart';
import 'package:nitznutz/world/adventure_land.dart';
import 'package:nitznutz/world/course_path.dart';
import 'package:nitznutz/world/todays_adventure.dart';

import 'support/app_harness.dart';
import 'support/course_history.dart';
import 'support/course_packs.dart';
import 'support/starter.dart';

const String _other = 'child-lang-0002';
final DateTime _then = DateTime.utc(2026, 11, 3, 9);

/// The whole ladder of the English oral strand answered right, `(item, right)` one after another.
const List<(String, bool)> _ladder = <(String, bool)>[
  ('pr_hello_1', true),
  ('pr_hello_2', true),
  ('pr_col_1', true),
  ('pr_col_2', true),
  ('pr_ani_1', true),
  ('pr_ani_2', true),
  ('pr_body_1', true),
  ('pr_body_2', true),
];

class _Env {
  _Env(this.rig, this.container);

  final AppRig rig;
  final ProviderContainer container;

  AppDatabase get db => rig.db;

  Future<List<LanguageCourse>> courses([String child = courseKid]) =>
      container.read(languageCoursesProvider(child).future);

  Future<LanguageCourse> course(String course, [String child = courseKid]) async =>
      (await courses(child)).firstWhere((LanguageCourse c) => c.course == course);

  /// Reads everything again, as the screens do after a visit.
  void refresh() => container.invalidate(languageCoursesProvider);
}

Future<_Env> _env({List<String> installed = const <String>['eng', 'heb', 'rus']}) async {
  final AppRig rig = AppRig()..languagePacks = fixturePacks(installed);
  await rig.seedFinishedSetup(id: courseKid, ageBand: 0);
  await rig.db.addProfile(
    ProfilesCompanion.insert(
      id: _other,
      name: 'דנה',
      avatar: 'avatar-noa',
      addressForm: 'f',
      ageBand: 1,
      createdAt: DateTime.utc(2026, 10, 26),
    ),
  );
  final ProviderContainer container = ProviderContainer(overrides: rig.overrides);
  addTearDown(() async {
    container.dispose();
    await rig.db.close();
  });
  return _Env(rig, container);
}

/// The parent says the child knows a little of [course]: one answer that is not "no", so the course has a placement game (a beginner has none).
Future<void> _parentSaysSome(_Env e, String course) async {
  await e.db.putSetting(
    languagesSettingKey,
    const FamilyLanguages()
        .withSwitches(
          courseKid,
          course,
          LanguageSwitches(
            on: true,
            questionnaire: <String, String>{course == 'rus' ? 'letters' : 'knowsLetters': 'some'},
          ),
        )!
        .encode(),
  );
  e.container.invalidate(languagesProvider);
  e.refresh();
}

void main() {
  group('which courses', () {
    test('no pack installed: no course', () async {
      final _Env e = await _env(installed: const <String>[]);
      expect(await e.courses(), isEmpty);
    });

    test('the installed packs, each with its own engine, in the fixed order of the doors', () async {
      final _Env e = await _env(installed: const <String>['rus', 'eng']);
      final List<LanguageCourse> courses = await e.courses();
      expect(courses.map((LanguageCourse c) => c.course), <String>['eng', 'rus']);
      expect(courses[0].content.packId, 'lang-eng');
      expect(courses[0].engine.catalog.skills.keys.every((String id) => id.startsWith('ENG-')), isTrue);
      expect(courses[1].engine.catalog.skills.keys.every((String id) => id.startsWith('RUS-')), isTrue);
    });

    test('a child whose parent says they know something has an engine that knows nothing, a placement that has not begun, and nothing assumed', () async {
      final _Env e = await _env();
      await _parentSaysSome(e, 'eng');
      final LanguageCourse c = await e.course('eng');
      expect(c.assumed, isEmpty);
      expect(c.placement!.begun, isFalse);
      expect(c.placement!.complete, isFalse);
      expect(c.engine.state.skills, isEmpty);
    });

    test('a beginner (no answers, or only "no") has no placement game in any course: the course starts at lesson 1 (L7-2)', () async {
      final _Env e = await _env();
      for (final LanguageCourse c in await e.courses()) {
        expect(c.placement, isNull, reason: '${c.course} with no answers');
        expect(c.assumed, isEmpty);
      }
      await e.db.putSetting(
        languagesSettingKey,
        FamilyLanguages.fromJson(<String, Object?>{
          courseKid: <String, Object?>{
            'eng': <String, Object?>{
              'q': <String, Object?>{'understands': 'no', 'knowsLetters': 'no'},
            },
            'heb': <String, Object?>{
              'q': <String, Object?>{'knowsLetters': 'no'},
            },
            'rus': <String, Object?>{
              'q': <String, Object?>{'understands': 'no', 'letters': 'no', 'reads': 'no', 'home': 'none'},
            },
          },
        }).encode(),
      );
      e.container.invalidate(languagesProvider);
      e.refresh();
      for (final LanguageCourse c in await e.courses()) {
        expect(c.placement, isNull, reason: '${c.course} with every answer "no"');
      }
    });

    test('the parent can ask for the placement later: a beginner then has the game, not begun', () async {
      final _Env e = await _env();
      await e.db.putSetting(
        languagesSettingKey,
        const FamilyLanguages()
            .withSwitches(courseKid, 'eng', const LanguageSwitches(on: true, placementAsked: true))!
            .encode(),
      );
      final LanguageCourse c = await e.course('eng');
      expect(c.placement!.begun, isFalse);
      expect(c.placement!.complete, isFalse);
    });

    test(
      'a placement that was begun stays whatever the answers say now: what it found stays the child history',
      () async {
        final _Env e = await _env();
        await writePlacement(e.db, courseContent('eng'), _ladder, at: _then);
        final LanguageCourse c = await e.course('eng');
        expect(c.placement!.complete, isTrue);
        expect(c.assumed, isNotEmpty);
      },
    );
  });

  group('the placement joins the engine', () {
    test('the answers of the placement visit are replayed into the staircase, the skills below the entry are assumed, and the engine knows them at 0.85', () async {
      final _Env e = await _env();
      final PackContent eng = courseContent('eng');
      await writePlacement(e.db, eng, _ladder, at: _then);
      final LanguageCourse c = await e.course('eng');
      expect(c.placement!.complete, isTrue);
      expect(c.placement!.entryOf('o'), 2);
      expect(c.assumed, <String>{'ENG-A-01', 'ENG-A-03'});
      for (final String skill in c.assumed) {
        final SkillState s = c.engine.skill(skill);
        expect(s.assumed, isTrue, reason: skill);
        expect(
          s.p,
          closeTo(0.85, 0.2),
          reason: '$skill starts from the assumed prior and then the probes\' own evidence',
        );
      }
      expect(c.engine.skill('ENG-A-05').assumed, isFalse, reason: 'at the entry level: to be learned');
      expect(c.engine.skill('ENG-A-06').assumed, isFalse);
    });

    test('the probes are evidence like any answer: the engine replays them', () async {
      final _Env e = await _env();
      await writePlacement(e.db, courseContent('eng'), _ladder, at: _then);
      final LanguageCourse c = await e.course('eng');
      expect(c.engine.state.skills['ENG-A-01']!.started, isTrue);
      expect(c.engine.state.skills['ENG-A-05']!.started, isTrue);
    });

    test('a beginner who misses the first two probes places at the floor, assumes nothing and is not asked again', () async {
      final _Env e = await _env();
      await writePlacement(e.db, courseContent('eng'), const <(String, bool)>[
        ('pr_hello_1', false),
        ('pr_hello_2', false),
      ], at: _then);
      final LanguageCourse c = await e.course('eng');
      expect(c.placement!.complete, isTrue);
      expect(c.placement!.entryOf('o'), 0);
      expect(c.assumed, isEmpty);
    });

    test(
      'a visit cut short leaves a strand open: nothing is assumed from it, and the next visit goes on',
      () async {
        final _Env e = await _env();
        await writePlacement(e.db, courseContent('eng'), _ladder.take(3).toList(), at: _then);
        final LanguageCourse c = await e.course('eng');
        expect(c.placement!.begun, isTrue);
        expect(c.placement!.complete, isFalse);
        expect(c.assumed, isEmpty);
      },
    );

    test('the questionnaire of the parent reaches the staircase: it starts one level up, so two misses in a row do not end it at once', () async {
      final _Env e = await _env();
      const List<(String, bool)> twoMisses = <(String, bool)>[('pr_col_1', false), ('pr_hello_1', false)];
      await writePlacement(e.db, courseContent('eng'), twoMisses, at: _then);
      expect(
        (await e.course('eng')).placement!.complete,
        isTrue,
        reason: 'from the floor, two misses stop the strand',
      );
      await e.db.putSetting(
        languagesSettingKey,
        const FamilyLanguages()
            .withSwitches(
              courseKid,
              'eng',
              const LanguageSwitches(on: true, questionnaire: <String, String>{'knowsLetters': 'some'}),
            )!
            .encode(),
      );
      e.container.invalidate(languagesProvider);
      e.refresh();
      final LanguageCourse c = await e.course('eng');
      expect(
        c.placement!.complete,
        isFalse,
        reason: 'it started at level 1: the first miss only went down, the second was the first at the floor',
      );
      expect(c.placement!.results['o']!.asked, 2);
    });
  });

  group('courses and children never mix', () {
    test('another course\'s answers never reach this course\'s engine or placement', () async {
      final _Env e = await _env();
      await writePlacement(e.db, courseContent('rus'), const <(String, bool)>[
        ('pr_a_1', true),
        ('pr_a_2', true),
      ], at: _then);
      await writeAnswer(e.db, courseContent('rus'), 'a_cat', lessonId: 'rus.animals_1', at: _then);
      await _parentSaysSome(e, 'eng');
      final LanguageCourse eng = await e.course('eng');
      final LanguageCourse rus = await e.course('rus');
      expect(eng.engine.state.skills, isEmpty);
      expect(eng.placement!.begun, isFalse);
      expect(rus.placement!.begun, isTrue);
      expect(rus.engine.state.skills.keys.every((String id) => id.startsWith('RUS-')), isTrue);
    });

    test('another child\'s answers never reach this child', () async {
      final _Env e = await _env();
      await writePlacement(e.db, courseContent('eng'), _ladder, at: _then, profileId: _other);
      await _parentSaysSome(e, 'eng');
      expect((await e.course('eng')).placement!.begun, isFalse);
      final LanguageCourse theirs = await e.course('eng', _other);
      expect(theirs.placement!.complete, isTrue);
      expect(theirs.assumed, isNotEmpty);
    });

    test('an answer of the lands with the same shape is no part of a course', () async {
      final _Env e = await _env();
      await e.db.recordAttempt(
        AttemptsCompanion.insert(
          at: _then,
          profileId: courseKid,
          packId: 'starter',
          packVersion: '1.0.0',
          lessonId: const Value<String>('placement-eng'),
          activityId: 'eng.pr_hello_1',
          activityRevision: 1,
          template: 'tap_answer',
          templateVersion: '1.3',
          skillId: 'NUM-A-01',
          result: 'correct',
          attemptNo: 1,
          hintLevel: 0,
        ),
      );
      await _parentSaysSome(e, 'eng');
      expect((await e.course('eng')).placement!.begun, isFalse);
    });
  });

  group('what reads the courses', () {
    test('the home, the parent\'s progress and Today\'s Adventure all see the same placement', () async {
      final _Env e = await _env();
      await writePlacement(e.db, courseContent('eng'), _ladder, at: _then);
      await e.db.putSetting(
        languagesSettingKey,
        const FamilyLanguages().withSwitches(courseKid, 'eng', const LanguageSwitches(on: true))!.encode(),
      );
      e.refresh();

      final CourseHomeModel? home = await e.container.read(
        courseHomeProvider((childId: courseKid, course: 'eng')).future,
      );
      expect(home!.nextIndex, 4);
      expect(home.stones.take(4).every((PathStone s) => s.state == StoneState.placed), isTrue);
      expect(home.placementDue, isFalse);

      final LanguageProgress? progress = await e.container.read(
        languageProgressProvider((childId: courseKid, course: 'eng')).future,
      );
      expect(progress!.strands.single.name, He.langStrandEngLisSpk);
      expect(progress.strands.single.startLevel, 3, reason: 'we start here: level 3');

      final starter = await loadStarter();
      final TodaysAdventure stop = todaysAdventureFor(
        content: starter,
        engine: Engine(catalog: engineCatalog(starter)),
        attempts: const <Attempt>[],
        sessions: const <Session>[],
        finished: const <String, int>{},
        now: _then.add(const Duration(days: 1)),
        band: 0,
        languages: await e.courses(),
        enabledCourses: <String>{'eng'},
      );
      // The bottle may choose the lands; if it chooses the language, it is the same stop as the home's pebble (the visit that verifies what
      // placement took as known comes before the lesson the path opens at).
      if (stop.land is LanguageLand) {
        expect(stop, TodaysAdventure.checkVisit(const LanguageLand('eng'), 'ENG-A-01'));
      }
      final TodaysAdventure alone = (await e.container.read(
        courseHomeProvider((childId: courseKid, course: 'eng')).future,
      ))!.stop;
      // The day after the placement the course offers the visit that verifies what placement took as known, and the path opens at the placed
      // level after it (the home's next stone, above).
      expect(alone, TodaysAdventure.checkVisit(const LanguageLand('eng'), 'ENG-A-01'));
      expect(
        home.stones[home.nextIndex].lessonId,
        'eng.animals_1',
        reason: 'the path opens at the placed level',
      );
    });

    test('the progress and the home are null for a course whose pack is not installed', () async {
      final _Env e = await _env(installed: const <String>['eng']);
      expect(await e.container.read(courseHomeProvider((childId: courseKid, course: 'heb')).future), isNull);
      expect(
        await e.container.read(languageProgressProvider((childId: courseKid, course: 'heb')).future),
        isNull,
      );
    });

    test('more answers and a new read: the engine and the placement move on', () async {
      final _Env e = await _env();
      await _parentSaysSome(e, 'eng');
      expect((await e.course('eng')).placement!.begun, isFalse);
      await writePlacement(e.db, courseContent('eng'), _ladder, at: _then);
      expect(
        (await e.course('eng')).placement!.begun,
        isFalse,
        reason: 'the provider keeps its answer until it is invalidated',
      );
      e.refresh();
      expect((await e.course('eng')).placement!.complete, isTrue);
    });
  });
}
