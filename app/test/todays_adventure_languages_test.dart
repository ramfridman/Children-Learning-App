// Today's Adventure with the languages (docs/languages/frame.md section 3.7): each language the parent turned on is a land for
// the rule of docs/curriculum/todays-adventure-rule.md; one that is off is not a land. The rule is the same pure function; here
// it is given lands that are languages, and the adapter is given a language pack.
import 'dart:math' as math;

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/child/adventure_line.dart';
import 'package:nitznutz/content/engine_adapter.dart';
import 'package:nitznutz/content/models.dart';
import 'package:nitznutz/data/app_database.dart';
import 'package:nitznutz/engine/course.dart';
import 'package:nitznutz/engine/engine.dart';
import 'package:nitznutz/engine/types.dart';
import 'package:nitznutz/rewards/award.dart';
import 'package:nitznutz/strings/he.dart';
import 'package:nitznutz/world/adventure_adapter.dart';
import 'package:nitznutz/world/adventure_land.dart';
import 'package:nitznutz/world/todays_adventure.dart';

import 'support/sample_pack.dart';
import 'support/starter.dart';

const int today = 20400;
const LanguageLand eng = LanguageLand('eng');
const LanguageLand heb = LanguageLand('heb');
const LanguageLand rus = LanguageLand('rus');

final Map<AdventureLand, List<PathLesson>> paths = <AdventureLand, List<PathLesson>>{
  TrophyLand.counting: const <PathLesson>[PathLesson('n1', 0), PathLesson('n2', 0)],
  eng: const <PathLesson>[PathLesson('e1', 0), PathLesson('e2', 0), PathLesson('e3', 0), PathLesson('e4', 1)],
  heb: const <PathLesson>[PathLesson('h1', 0), PathLesson('h2', 1)],
  rus: const <PathLesson>[PathLesson('r1', 0)],
};

Visit lessonVisit(AdventureLand land, String id, {int day = today, VisitEnd end = VisitEnd.finished}) =>
    Visit(kind: VisitKind.lesson, land: land, id: id, day: day, end: end);

AdventureInput input({
  Set<AdventureLand>? enabled,
  Map<String, int> finished = const <String, int>{},
  List<Visit> visits = const <Visit>[],
  List<DueSkill> due = const <DueSkill>[],
}) => AdventureInput(
  today: today,
  band: 1,
  enabledLands: enabled ?? paths.keys.toSet(),
  paths: paths,
  finished: finished,
  visits: visits,
  due: due,
);

void main() {
  group('a language is a land of the map for the rule', () {
    test('the lands have a fixed order: the lands of the map, then the doors in their order', () {
      expect(<int>[for (final TrophyLand l in TrophyLand.values) l.order], <int>[0, 1, 2, 3, 4, 5]);
      expect(<int>[eng.order, heb.order, rus.order], <int>[100, 101, 102]);
      expect(eng, const LanguageLand('eng'));
      expect(eng.hashCode, const LanguageLand('eng').hashCode);
      expect(eng, isNot(heb));
      expect(<Object>{eng, heb}.length, 2);
      expect(<Object>{eng, LanguageLand(Course.eng)}.length, 1);
      expect(<String>[eng.key, TrophyLand.counting.key], <String>['eng', 'counting']);
      expect(eng.domain, Course.languagesDomain);
    });

    test('the only land that is on is a language: the bottle opens its first lesson, and welcomes', () {
      final TodaysAdventure a = todaysAdventure(input(enabled: <AdventureLand>{eng}));
      expect(a, TodaysAdventure.lesson(eng, 'e1', AdventureReason.welcome));
    });

    test(
      'a language that is off is not a land: its lessons are not offered and its due checks not opened',
      () {
        final TodaysAdventure a = todaysAdventure(
          input(
            enabled: <AdventureLand>{TrophyLand.counting},
            due: <DueSkill>[DueSkill(skillId: 'ENG-A-01', land: eng, dueAt: DateTime.utc(2026, 11, 1))],
          ),
        );
        expect(a.land, TrophyLand.counting);
        expect(a.kind, AdventureKind.lesson);
        expect(todaysAdventure(input(enabled: <AdventureLand>{})), const TodaysAdventure.none());
      },
    );

    test('a due language check is a call for help, once a day, like any land\'s', () {
      final DueSkill d = DueSkill(skillId: 'RUS-A-01', land: rus, dueAt: DateTime.utc(2026, 11, 1));
      expect(todaysAdventure(input(due: <DueSkill>[d])), TodaysAdventure.revisit(rus, 'RUS-A-01'));
      // After a revisit today, two lessons come before the next one.
      final List<Visit> afterRevisit = <Visit>[
        const Visit(kind: VisitKind.revisit, land: rus, id: 'RUS-A-01', day: today),
      ];
      final TodaysAdventure next = todaysAdventure(
        input(
          visits: afterRevisit,
          due: <DueSkill>[DueSkill(skillId: 'ENG-A-02', land: eng, dueAt: DateTime.utc(2026, 11, 2))],
        ),
      );
      expect(next.kind, AdventureKind.lesson, reason: 'a revisit is not offered twice in a row');
    });

    test(
      'a language stays for three lessons, then the bottle moves on to the land not played for longest',
      () {
        final List<Visit> three = <Visit>[
          lessonVisit(eng, 'e1', day: today - 1),
          lessonVisit(eng, 'e2'),
          lessonVisit(eng, 'e3'),
        ];
        final Map<String, int> finished = <String, int>{'e1': 1, 'e2': 1, 'e3': 1};
        final TodaysAdventure a = todaysAdventure(input(visits: three, finished: finished));
        expect(a.land, isNot(eng), reason: 'the run of three in one land is over');
        expect(a.kind, AdventureKind.lesson);
        final TodaysAdventure two = todaysAdventure(
          input(visits: three.take(2).toList(), finished: <String, int>{'e1': 1, 'e2': 1}),
        );
        expect(two, TodaysAdventure.lesson(eng, 'e3', AdventureReason.sameLand));
      },
    );

    test(
      'ties end on the fixed order, so the languages come after the lands and in the order of the doors',
      () {
        expect(todaysAdventure(input()).land, TrophyLand.counting);
        expect(todaysAdventure(input(enabled: <AdventureLand>{rus, heb, eng})).land, eng);
        expect(todaysAdventure(input(enabled: <AdventureLand>{rus, heb})).land, heb);
      },
    );

    test('shuffling the lands, the due list and the finished map changes nothing', () {
      final math.Random random = math.Random(11);
      final AdventureInput base = input(
        finished: <String, int>{'n1': 1, 'e1': 1},
        visits: <Visit>[
          lessonVisit(TrophyLand.counting, 'n1', day: today - 1),
          lessonVisit(eng, 'e1'),
        ],
        due: <DueSkill>[
          DueSkill(skillId: 'HEB-A-01', land: heb, dueAt: DateTime.utc(2026, 11, 3)),
          DueSkill(skillId: 'ENG-A-01', land: eng, dueAt: DateTime.utc(2026, 11, 3)),
        ],
      );
      final TodaysAdventure want = todaysAdventure(base);
      for (int i = 0; i < 20; i++) {
        final AdventureInput shuffled = AdventureInput(
          today: base.today,
          band: base.band,
          enabledLands: (base.enabledLands.toList()..shuffle(random)).toSet(),
          paths: base.paths,
          finished: base.finished,
          visits: base.visits,
          due: base.due.toList()..shuffle(random),
        );
        expect(todaysAdventure(shuffled), want);
      }
    });

    test('a stop in a language has one line for each language, whatever the reason, with no variable', () {
      final AdventureLine? e = adventureLine(TodaysAdventure.lesson(eng, 'e1', AdventureReason.welcome));
      expect(e!.text, He.adventureLangEnglish.text);
      expect(adventureLine(TodaysAdventure.revisit(rus, 'RUS-A-01'))!.text, He.adventureLangRussian.text);
      expect(adventureLine(TodaysAdventure.replay(heb, 'h1'))!.text, He.adventureLangHebrew.text);
      expect(adventureLine(TodaysAdventure.lesson(eng, 'e2', AdventureReason.sameLand))!.text, e.text);
      expect(e.text.contains('{'), isFalse);
      expect(e.voice, 'vo:core.adventure.lang.eng');
      expect(
        adventureLine(TodaysAdventure.lesson(TrophyLand.counting, 'n1', AdventureReason.welcome)),
        isNotNull,
      );
    });
  });

  group('the adapter, with a language pack', () {
    late PackContent starter;
    late PackContent english;
    late AppDatabase db;
    final DateTime morning = DateTime.utc(2026, 11, 20, 9);
    int step = 0;

    setUpAll(() async {
      starter = await loadStarter();
      final SamplePack p = SamplePack.language('eng');
      // One activity is a transfer check, so that the skill can reach fresh mastery.
      p.doc('activity.eng.pick.red.flower.json')['checkType'] = 'transfer';
      english = PackContent.fromPack(p.verified());
    });
    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      step = 0;
    });

    Engine emptyEnglish() => Engine(catalog: engineCatalog(english));

    Future<void> answer(String pack, String lessonId, String skill, {String activity = 'x'}) =>
        db.recordAttempt(
          AttemptsCompanion.insert(
            at: morning.add(Duration(minutes: step++)),
            profileId: 'p-1',
            packId: pack,
            packVersion: '1.0.0',
            lessonId: Value<String>(lessonId),
            activityId: activity,
            activityRevision: 1,
            template: 'count_tap',
            templateVersion: '1.0',
            skillId: skill,
            result: 'correct',
            attemptNo: 1,
            hintLevel: 0,
          ),
        );

    AdventureInput build({
      Iterable<LanguageCourse>? languages,
      Set<String> enabled = const <String>{'eng'},
      Engine? engine,
      List<Attempt> attempts = const <Attempt>[],
      DateTime? now,
    }) => adventureInput(
      content: starter,
      engine: engine ?? Engine(catalog: engineCatalog(starter)),
      attempts: attempts,
      sessions: const <Session>[],
      finished: const <String, int>{},
      now: now ?? morning,
      band: 1,
      languages: languages ?? <LanguageCourse>[LanguageCourse(content: english, engine: emptyEnglish())],
      enabledCourses: enabled,
    );

    test('a language pack that is installed and turned on is a land with its own path', () {
      final AdventureInput a = build();
      expect(a.enabledLands, contains(eng));
      expect(a.enabledLands.length, TrophyLand.values.length + 1);
      expect(a.paths[eng]!.map((PathLesson l) => l.id), <String>['eng.butterflies']);
      expect(a.paths[eng]!.single.level, 0);
    });

    test('turned off, or not installed, it is not a land at all', () {
      expect(build(enabled: const <String>{}).enabledLands, isNot(contains(eng)));
      expect(build(enabled: const <String>{'heb'}).enabledLands, isNot(contains(eng)));
      expect(build(languages: const <LanguageCourse>[]).enabledLands, isNot(contains(eng)));
      expect(build(enabled: const <String>{}).enabledLands, TrophyLand.values.toSet());
    });

    test('a visit belongs to the course of the pack that its answers name', () async {
      expect(starter.lessons.containsKey('butterflies'), isTrue);
      expect(english.lessons.containsKey('eng.butterflies'), isTrue);
      await answer('starter', 'butterflies', 'NUM-A-03');
      await answer('lang-eng', 'eng.butterflies', 'ENG-A-01');
      final List<Visit> visits = visitsFrom(
        starter,
        await db.attemptsOf('p-1'),
        const <Session>[],
        languages: <PackContent>[english],
      );
      expect(visits.map((Visit v) => v.land), <AdventureLand>[TrophyLand.counting, eng]);
      expect(visits.map((Visit v) => v.kind), everyElement(VisitKind.lesson));
    });

    test('the visits of a language that is off are left out, as if it had never been played', () async {
      await answer('lang-eng', 'eng.butterflies', 'ENG-A-01');
      await answer('lang-eng', 'placement-eng', 'ENG-A-01');
      expect(visitsFrom(starter, await db.attemptsOf('p-1'), const <Session>[]), isEmpty);
    });

    test('a language\'s placement and revisit visits are of its land', () async {
      await answer('lang-eng', 'placement-eng', 'ENG-A-01');
      await answer('lang-eng', 'mission-eng-a-01', 'ENG-A-01');
      final List<Visit> visits = visitsFrom(
        starter,
        await db.attemptsOf('p-1'),
        const <Session>[],
        languages: <PackContent>[english],
      );
      expect(visits.map((Visit v) => (v.kind, v.land)), <(VisitKind, AdventureLand)>[
        (VisitKind.warmUp, eng),
        (VisitKind.revisit, eng),
      ]);
    });

    test('the due checks of a language come from its own engine, in its own land', () {
      final Engine e = emptyEnglish();
      // Four answers on two days, one of them a transfer check: fresh mastery of ENG-A-01.
      final List<(String, int)> story = <(String, int)>[
        ('eng.count.butterflies.3', 0),
        ('eng.give.three.jar', 0),
        ('eng.count.butterflies.3', 0),
        ('eng.pick.red.flower', 1),
        ('eng.give.three.jar', 1),
      ];
      for (final (String item, int day) in story) {
        e.apply(
          AttemptEvent(
            at: morning.add(Duration(days: day, minutes: step++)),
            activityId: item,
            result: Result.correct,
          ),
        );
      }
      expect(e.state.skills['ENG-A-01']!.freshAt, isNotNull);
      final DateTime later = morning.add(const Duration(days: 60));
      final AdventureInput a = build(
        languages: <LanguageCourse>[LanguageCourse(content: english, engine: e)],
        now: later,
      );
      expect(a.due.map((DueSkill d) => (d.skillId, d.land)), <(String, AdventureLand)>[('ENG-A-01', eng)]);
      expect(todaysAdventure(a), TodaysAdventure.revisit(eng, 'ENG-A-01'));
      // Turned off, the same child has nothing due.
      expect(
        build(
          languages: <LanguageCourse>[LanguageCourse(content: english, engine: e)],
          now: later,
          enabled: const <String>{},
        ).due,
        isEmpty,
      );
    });
  });
}
