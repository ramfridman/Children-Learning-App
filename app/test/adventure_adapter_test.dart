// Today's Adventure on the real starter pack (B-26 step 5): the adapter turns the pack, the child's answers and sessions
// and the engine into the rule's input; the stop the rule gives for a lesson is always the one the land's own pebble gives.
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/content/engine_adapter.dart';
import 'package:nitznutz/content/models.dart';
import 'package:nitznutz/data/app_database.dart';
import 'package:nitznutz/engine/engine.dart';
import 'package:nitznutz/engine/types.dart';
import 'package:nitznutz/rewards/award.dart';
import 'package:nitznutz/world/adventure_adapter.dart';
import 'package:nitznutz/world/next_lesson.dart';
import 'package:nitznutz/world/placement.dart';
import 'package:nitznutz/world/todays_adventure.dart';

import 'support/starter.dart';

const String kid = 'p-1';
final DateTime morning = DateTime.utc(2026, 11, 20, 9);

void main() {
  late PackContent content;
  late AppDatabase db;
  int step = 0;

  setUpAll(() async => content = await loadStarter());
  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    step = 0;
  });

  /// One answer of the child. [at] defaults to a minute after the last one.
  Future<void> answer(
    String lessonId, {
    String activity = 'x',
    String skill = 'NUM-A-03',
    String result = 'correct',
    int? session,
    String? remote,
    DateTime? at,
  }) => db.recordAttempt(
    AttemptsCompanion.insert(
      at: at ?? morning.add(Duration(minutes: step++)),
      profileId: kid,
      packId: 'starter',
      packVersion: '0.10.0',
      lessonId: Value<String>(lessonId),
      activityId: activity,
      activityRevision: 1,
      template: 'count_tap',
      templateVersion: '1.0',
      skillId: skill,
      result: result,
      attemptNo: 1,
      hintLevel: 0,
      sessionId: Value<int?>(session),
      remoteSession: Value<String?>(remote),
    ),
  );

  Future<List<Visit>> visits() async =>
      visitsFrom(content, await db.attemptsOf(kid), await db.sessionsOf(kid));

  Engine emptyEngine() => Engine(catalog: engineCatalog(content));

  group('the pack: lands, paths and levels', () {
    test('every land of the starter pack is open; a path is the land\'s own, in order', () {
      final AdventureInput a = adventureInput(
        content: content,
        engine: emptyEngine(),
        attempts: const <Attempt>[],
        sessions: const <Session>[],
        finished: const <String, int>{},
        now: morning,
        band: 1,
      );
      expect(a.enabledLands, TrophyLand.values.toSet());
      for (final TrophyLand land in TrophyLand.values) {
        expect(
          a.paths[land]!.map((PathLesson l) => l.id).toList(),
          landPath(content, land.domain).map((Lesson l) => l.id).toList(),
          reason: land.name,
        );
      }
      expect(a.today, Engine.dayKey(morning));
      expect(a.band, 1);
    });

    test('a level is the highest band among the lesson\'s skills of that land', () {
      final AdventureInput a = adventureInput(
        content: content,
        engine: emptyEngine(),
        attempts: const <Attempt>[],
        sessions: const <Session>[],
        finished: const <String, int>{},
        now: morning,
        band: 0,
      );
      int level(TrophyLand land, String id) => a.paths[land]!.firstWhere((PathLesson l) => l.id == id).level;
      expect(level(TrophyLand.counting, 'butterflies'), 0);
      expect(level(TrophyLand.counting, 'count-to-20'), 1);
      expect(level(TrophyLand.colors, 'mix-colours'), 1);
      expect(level(TrophyLand.market, 'add-one-more'), 0);
      expect(level(TrophyLand.market, 'join-more'), 1);
      // butterflies is on two paths; on the colours path only its colour skill counts, and that one is band A.
      expect(level(TrophyLand.colors, 'butterflies'), 0);
      for (final TrophyLand land in TrophyLand.values) {
        expect(
          a.paths[land]!.map((PathLesson l) => l.level),
          everyElement(inInclusiveRange(0, 2)),
          reason: land.name,
        );
      }
    });
  });

  group('visits from answers (rule section 2.1)', () {
    test('a session with no answer is no visit', () async {
      await db.startSession(kid, morning, plan: 'lesson:butterflies');
      expect(await visits(), isEmpty);
    });

    test(
      'a lesson visit: its land is the first skill\'s, its day the last answer\'s, its end the session\'s',
      () async {
        final int s = await db.startSession(kid, morning, plan: 'lesson:butterflies');
        await answer('butterflies', session: s);
        await answer('butterflies', session: s, result: 'incorrect', at: DateTime.utc(2026, 11, 21, 0, 30));
        await db.endSession(s, DateTime.utc(2026, 11, 21, 0, 31), 'home');
        final Visit v = (await visits()).single;
        expect(v.kind, VisitKind.lesson);
        // butterflies is on both the Numbers and the Colours path; its first skill is NUM-A-03.
        expect(v.land, TrophyLand.counting);
        expect(v.id, 'butterflies');
        expect(v.day, Engine.dayKey(DateTime.utc(2026, 11, 21)), reason: 'the day of the last answer');
        expect(v.end, VisitEnd.home);
        expect(v.lastIncorrect, isTrue);
      },
    );

    test('every end word of a session, and an open one', () async {
      final Map<String, VisitEnd> expected = <String, VisitEnd>{
        'finished': VisitEnd.finished,
        'home': VisitEnd.home,
        'limit': VisitEnd.limit,
        '': VisitEnd.open,
      };
      for (final String word in expected.keys) {
        final int s = await db.startSession(kid, morning, plan: 'lesson:butterflies');
        await answer('butterflies', session: s);
        if (word.isNotEmpty) await db.endSession(s, morning, word);
      }
      expect((await visits()).map((Visit v) => v.end), expected.values);
    });

    test('an unsure answer is never incorrect', () async {
      final int s = await db.startSession(kid, morning);
      await answer('butterflies', session: s, result: 'unsure');
      expect((await visits()).single.lastIncorrect, isFalse);
    });

    test(
      'a warm-up whose session plan says mission: is still a warm-up, in the land of its first answer',
      () async {
        final int s = await db.startSession(kid, morning, plan: 'mission:num-a-01');
        await answer(placementId, session: s, skill: 'SHP-A-01');
        final Visit v = (await visits()).single;
        expect(v.kind, VisitKind.warmUp);
        expect(v.land, TrophyLand.shapes);
      },
    );

    test('a revisit mission is a revisit: its id is the skill id, its land the skill\'s', () async {
      final int s = await db.startSession(kid, morning, plan: 'mission:col-a-01');
      await answer('mission-col-a-01', session: s, skill: 'COL-A-01');
      final Visit v = (await visits()).single;
      expect(v.kind, VisitKind.revisit);
      expect(v.id, 'COL-A-01');
      expect(v.land, TrophyLand.colors);
    });

    test('a lesson that is not in the pack, and one with no lesson at all, are left out', () async {
      final int s = await db.startSession(kid, morning);
      await answer('not-a-lesson', session: s);
      final int t = await db.startSession(kid, morning);
      await answer('', session: t);
      expect(await visits(), isEmpty);
    });

    test(
      'answers from another device are grouped by their remote session, ended by that session\'s row',
      () async {
        await answer('counting-words', remote: 'd2:7');
        await answer('counting-words', remote: 'd2:7');
        await answer('shape-friends', remote: 'd2:8');
        await db.addRemoteSession(
          SessionsCompanion.insert(
            profileId: kid,
            startedAt: morning,
            endReason: const Value<String>('finished'),
          ),
          eventId: 'e-1',
          remoteKey: 'd2:7',
          at: morning,
        );
        final List<Visit> got = await visits();
        expect(got.map((Visit v) => v.id), <String>['counting-words', 'shape-friends']);
        expect(got.map((Visit v) => v.land), <TrophyLand>[TrophyLand.counting, TrophyLand.shapes]);
        expect(got.map((Visit v) => v.end), <VisitEnd>[VisitEnd.finished, VisitEnd.open]);
      },
    );

    test('older answers with no session are one visit per run of the same lesson', () async {
      await answer('counting-words');
      await answer('counting-words');
      await answer('shape-friends', skill: 'SHP-A-01');
      await answer('counting-words');
      expect((await visits()).map((Visit v) => v.id), <String>[
        'counting-words',
        'shape-friends',
        'counting-words',
      ]);
    });

    test('visits are in the order of their first answer, not of their session numbers', () async {
      final int later = await db.startSession(kid, morning);
      final int earlier = await db.startSession(kid, morning);
      await answer('shape-friends', session: earlier, skill: 'SHP-A-01', at: DateTime.utc(2026, 11, 19, 9));
      await answer('counting-words', session: later, at: DateTime.utc(2026, 11, 20, 9));
      expect((await visits()).map((Visit v) => v.id), <String>['shape-friends', 'counting-words']);
    });
  });

  group('the engine: today and what is due', () {
    /// An invented child who answers every item of [skill] right, once a day for four days, so the skill has fresh
    /// mastery and a time when its check falls due.
    Engine perfectChild(String skill) {
      final Catalog catalog = engineCatalog(content);
      final Engine e = Engine(catalog: catalog);
      final List<ItemMeta> items = catalog.itemsFor(skill)
        ..sort((ItemMeta a, ItemMeta b) => a.id.compareTo(b.id));
      int n = 0;
      for (int day = 0; day < 4; day++) {
        for (final ItemMeta item in items) {
          e.apply(
            AttemptEvent(
              id: ++n,
              at: DateTime.utc(2026, 11, 2, 9).add(Duration(days: day, minutes: n)),
              activityId: item.id,
              result: Result.correct,
              sessionId: day + 1,
            ),
          );
        }
      }
      return e;
    }

    AdventureInput inputAt(Engine e, DateTime now) => adventureInput(
      content: content,
      engine: e,
      attempts: const <Attempt>[],
      sessions: const <Session>[],
      finished: const <String, int>{},
      now: now,
      band: 1,
    );

    test('a check that fell due is on the list with the engine\'s own time, and is the stop', () {
      final Engine e = perfectChild('NUM-A-01');
      final DateTime at = e.nextCheckAt('NUM-A-01')!;
      final DateTime now = at.add(const Duration(hours: 5));
      final AdventureInput a = inputAt(e, now);
      final DueSkill d = a.due.singleWhere((DueSkill x) => x.skillId == 'NUM-A-01');
      expect(d.dueAt, at);
      expect(d.land, TrophyLand.counting);
      expect(d.reviewedToday, isFalse);
      expect(a.today, Engine.dayKey(now), reason: 'the day comes from the clock reading given, nowhere else');
      expect(todaysAdventure(a), TodaysAdventure.revisit(TrophyLand.counting, 'NUM-A-01'));
    });

    test('QA: the day turns at UTC midnight (the engine\'s own day), and a local-time reading gives the same day', () {
      final Engine e = Engine(catalog: engineCatalog(content));
      int todayAt(DateTime now) => inputAt(e, now).today;
      final DateTime before = DateTime.utc(2026, 10, 30, 23, 59, 59);
      final DateTime after = DateTime.utc(2026, 10, 31);
      expect(todayAt(after), todayAt(before) + 1);
      // Israel local midnight (UTC+2 in winter, +3 in summer) is not a turn of the day: the engine's rule, accepted.
      expect(todayAt(DateTime.utc(2026, 10, 30, 22, 30)), todayAt(DateTime.utc(2026, 10, 30, 23, 0)));
      expect(todayAt(before.toLocal()), todayAt(before));
    });

    test('before the check is due nothing is due, and the clock decides it alone', () {
      final Engine e = perfectChild('NUM-A-01');
      final DateTime at = e.nextCheckAt('NUM-A-01')!;
      expect(inputAt(e, at.subtract(const Duration(minutes: 1))).due, isEmpty);
      expect(inputAt(e, at).due, hasLength(1));
    });

    test('a skill already reviewed on the day of now is marked reviewedToday', () {
      final Engine e = perfectChild('NUM-A-01');
      final DateTime at = e.nextCheckAt('NUM-A-01')!;
      // The engine counts one memory review a day: a first answer on that day marks the skill. Failing the check sets
      // needsRevisit, so the skill stays due after it.
      final ItemMeta item = e.catalog.itemsFor('NUM-A-01').first;
      final DateTime when = at.add(const Duration(days: 1));
      e.apply(AttemptEvent(id: 999, at: when, activityId: item.id, result: Result.incorrect, sessionId: 9));
      final DueSkill d = inputAt(
        e,
        when.add(const Duration(minutes: 5)),
      ).due.singleWhere((DueSkill x) => x.skillId == 'NUM-A-01');
      expect(d.reviewedToday, isTrue);
      final DueSkill nextDay = inputAt(
        e,
        when.add(const Duration(days: 1, minutes: 5)),
      ).due.singleWhere((DueSkill x) => x.skillId == 'NUM-A-01');
      expect(nextDay.reviewedToday, isFalse, reason: 'tomorrow it may be asked again');
    });
  });

  group('the whole chain on the real pack', () {
    test('a brand-new child is invited to the first lesson of Counting Hills', () {
      expect(
        todaysAdventureFor(
          content: content,
          engine: emptyEngine(),
          attempts: const <Attempt>[],
          sessions: const <Session>[],
          finished: const <String, int>{},
          now: morning,
          band: 0,
        ),
        TodaysAdventure.lesson(TrophyLand.counting, 'butterflies', AdventureReason.welcome),
      );
    });

    test(
      'the lesson stop is always the one the land\'s own pebble gives, and the lands take turns',
      () async {
        final Map<String, int> finished = <String, int>{};
        final List<TrophyLand> played = <TrophyLand>[];
        for (int i = 0; i < 40; i++) {
          final DateTime now = morning.add(Duration(days: i ~/ 4, minutes: i * 10));
          final TodaysAdventure stop = todaysAdventureFor(
            content: content,
            engine: emptyEngine(),
            attempts: await db.attemptsOf(kid),
            sessions: await db.sessionsOf(kid),
            finished: finished,
            now: now,
            band: 0,
          );
          expect(stop.kind, AdventureKind.lesson, reason: 'step $i: new learning is left in every land');
          expect(
            stop.lessonId,
            nextLessonId(content: content, domain: stop.land!.domain, finished: finished),
            reason: 'step $i: ${stop.land}',
          );
          // The child plays it to the end.
          final Lesson lesson = content.lessons[stop.lessonId]!;
          final int s = await db.startSession(kid, now, plan: 'lesson:${lesson.id}');
          await answer(
            lesson.id,
            session: s,
            skill: lesson.skillIds.first,
            activity: lesson.itemIds.first,
            at: now,
          );
          await db.endSession(s, now, 'finished');
          finished[lesson.id] = (finished[lesson.id] ?? 0) + 1;
          played.add(stop.land!);
        }
        // Never more than three lessons in a row in one land, and every land is visited within the 40.
        int run = 1;
        for (int i = 1; i < played.length; i++) {
          run = played[i] == played[i - 1] ? run + 1 : 1;
          expect(run, lessThanOrEqualTo(3), reason: 'step $i');
        }
        expect(played.toSet(), TrophyLand.values.toSet());
        expect(played.first, TrophyLand.counting);
      },
    );

    test('lessons the warm-up placed count as finished, as the pebble counts them', () async {
      final List<Lesson> path = landPath(content, 'numbers');
      final Lesson known = path[1];
      final int s = await db.startSession(kid, morning);
      await answer(placementId, session: s, activity: known.itemIds.first, skill: known.skillIds.first);
      final Map<String, int> finished = finishedLessons(content, await db.attemptsOf(kid), const <String>[]);
      expect(finished[known.id], 1);
      expect(finishedLessons(content, const <Attempt>[], const <String>['sticker:giving:2'])['giving'], 2);
    });
  });
}
