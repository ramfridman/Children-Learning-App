// Habit medals and island decorations (M8b): which habits count, that a medal needs enough of them, that nothing about speed
// or time can earn one, and that the service gives them once and quietly for history that already existed.
import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/data/app_database.dart';
import 'package:nitznutz/engine/types.dart';
import 'package:nitznutz/rewards/award.dart';
import 'package:nitznutz/rewards/ceremony.dart';
import 'package:nitznutz/rewards/habits.dart';
import 'package:nitznutz/rewards/outfits.dart';
import 'package:nitznutz/rewards/reward_rules.dart';
import 'package:nitznutz/rewards/reward_service.dart';

import 'engine/fixtures.dart';
import 'reward_service_test.dart' show child, domains, fourSkills;

AttemptEvent event(int minute, String activity, Result result, {int? session = 1}) => AttemptEvent(
  at: day0.add(Duration(minutes: minute)),
  activityId: activity,
  result: result,
  sessionId: session,
);

HabitMoment moment(HabitKind kind, int day) => HabitMoment(
  kind: kind,
  at: day0.add(Duration(days: day)),
);

Set<String> keys(List<AwardDue> due) => <String>{for (final AwardDue a in due) a.key};

Future<void> record(AppDatabase db, DateTime at, String item, String result, {int? session}) =>
    db.recordAttempt(
      AttemptsCompanion.insert(
        at: at,
        profileId: child,
        packId: 'starter',
        packVersion: '0.2.0',
        activityId: item,
        activityRevision: 1,
        template: 'count_tap',
        templateVersion: '1.0',
        skillId: 'SK-A-01',
        result: result,
        attemptNo: 1,
        hintLevel: 0,
        sessionId: Value<int?>(session),
      ),
    );

void main() {
  group('the habit moments in the answers', () {
    test('every "I\'m not sure" or "show me" is a moment of asking for help', () {
      final List<HabitMoment> m = habitMoments(<AttemptEvent>[
        event(1, 'a', Result.unsure),
        event(2, 'a', Result.unsure),
        event(3, 'b', Result.correct),
      ]);
      expect(m.map((HabitMoment h) => h.kind), <HabitKind>[HabitKind.askedForHelp, HabitKind.askedForHelp]);
    });

    test('a right answer after a mistake on the same activity in the same visit is trying again, once', () {
      final List<HabitMoment> m = habitMoments(<AttemptEvent>[
        event(1, 'a', Result.incorrect),
        event(2, 'a', Result.incorrect),
        event(3, 'a', Result.correct),
        event(4, 'a', Result.correct),
      ]);
      expect(m.map((HabitMoment h) => h.kind), <HabitKind>[HabitKind.triedAgain]);
    });

    test(
      'a right answer with no mistake before it, or after a mistake in another visit, is nothing special',
      () {
        expect(habitMoments(<AttemptEvent>[event(1, 'a', Result.correct)]), isEmpty);
        expect(
          habitMoments(<AttemptEvent>[
            event(1, 'a', Result.incorrect, session: 1),
            event(2, 'a', Result.correct, session: 2),
          ]),
          isEmpty,
        );
        expect(
          habitMoments(<AttemptEvent>[event(1, 'a', Result.incorrect), event(2, 'b', Result.correct)]),
          isEmpty,
          reason: 'another activity',
        );
      },
    );

    test('the same answers in another order of arrival give the same moments', () {
      final List<AttemptEvent> a = <AttemptEvent>[
        event(1, 'a', Result.incorrect),
        event(2, 'a', Result.correct),
        event(3, 'b', Result.unsure),
      ];
      expect(
        habitMoments(a.reversed.toList()).map((HabitMoment h) => (h.kind, h.at)).toList(),
        habitMoments(a).map((HabitMoment h) => (h.kind, h.at)).toList(),
      );
    });
  });

  group('medals and decorations are due', () {
    test('a medal needs enough moments of its habit and is dated at the last one needed', () {
      final List<HabitMoment> four = <HabitMoment>[
        for (int i = 0; i < 4; i++) moment(HabitKind.askedForHelp, i),
      ];
      expect(
        keys(dueAwards(skills: const <SkillFact>[], lessons: const <FinishedLesson>[], habits: four)),
        isEmpty,
      );
      final List<AwardDue> due = dueAwards(
        skills: const <SkillFact>[],
        lessons: const <FinishedLesson>[],
        habits: <HabitMoment>[...four, moment(HabitKind.askedForHelp, 9)],
      );
      expect(keys(due), <String>{'medal:brave-asker'});
      expect(due.single.at, day0.add(const Duration(days: 9)));
    });

    test('the other habit does not count towards a medal', () {
      final List<HabitMoment> tries = <HabitMoment>[
        for (int i = 0; i < 3; i++) moment(HabitKind.triedAgain, i),
      ];
      expect(
        keys(dueAwards(skills: const <SkillFact>[], lessons: const <FinishedLesson>[], habits: tries)),
        <String>{'medal:try-again'},
      );
    });

    test('the medals with no activities yet are never due', () {
      final List<HabitMoment> lots = <HabitMoment>[
        for (int i = 0; i < 99; i++) moment(HabitKind.askedForHelp, i),
        for (int i = 0; i < 99; i++) moment(HabitKind.triedAgain, i),
      ];
      final Set<String> k = keys(
        dueAwards(skills: const <SkillFact>[], lessons: const <FinishedLesson>[], habits: lots),
      );
      expect(k, <String>{'medal:brave-asker', 'medal:try-again'});
      expect(medalDefs.where((MedalDef m) => m.habit == null).map((MedalDef m) => m.id), <String>[
        'explainer',
        'bug-fixer',
      ]);
    });

    test(
      'a decoration comes with 10, 20 and 30 skills understood for good, dated at the one that made it so',
      () {
        List<SkillFact> lasting(int n) => <SkillFact>[
          for (int i = 0; i < n; i++)
            SkillFact(
              id: 'SK-A-${i.toString().padLeft(2, '0')}',
              domain: 'numbers',
              durableAt: day0.add(Duration(days: i)),
            ),
        ];
        Set<String> decos(int n) =>
            keys(dueAwards(skills: lasting(n), lessons: const <FinishedLesson>[]))
                .where((String k) => k.startsWith('deco:'))
                .toSet();
        expect(decos(9), isEmpty);
        expect(decos(10), <String>{'deco:10'});
        expect(decos(25), <String>{'deco:10', 'deco:20'});
        expect(decos(30), <String>{'deco:10', 'deco:20', 'deco:30'});
        final AwardDue tenth = dueAwards(
          skills: lasting(12),
          lessons: const <FinishedLesson>[],
        ).firstWhere((AwardDue a) => a.key == 'deco:10');
        expect(tenth.at, day0.add(const Duration(days: 9)));
      },
    );

    test('award keys of medals and decorations read back, and fit the server\'s pattern', () {
      expect(Awards.medalOf('medal:brave-asker'), 'brave-asker');
      expect(Awards.decorationOf('deco:20'), 20);
      expect(Awards.kindOf('medal:try-again'), AwardKind.medal);
      expect(Awards.kindOf('deco:10'), AwardKind.decoration);
      final RegExp server = RegExp(r'^(medal:[a-z0-9-]{2,30}|deco:[0-9]{1,3})$');
      for (final MedalDef m in medalDefs) {
        expect(server.hasMatch(Awards.medal(m.id)), isTrue, reason: m.id);
      }
      for (final int n in decorationSteps) {
        expect(server.hasMatch(Awards.decoration(n)), isTrue);
      }
    });
  });

  group('the ceremony queue', () {
    Reward r(int id, String key, String kind, {int day = 0}) => Reward(
      id: id,
      profileId: child,
      awardKey: key,
      kind: kind,
      at: day0.add(Duration(days: day)),
      seenAt: null,
      eventId: null,
      syncedAt: null,
    );

    test('a trophy before a medal; of several trophies the highest tier, then the latest', () {
      expect(nextCeremony(const <Reward>[]), isNull);
      final Reward medal = r(1, 'medal:brave-asker', 'medal');
      expect(nextCeremony(<Reward>[medal]), medal);
      final Reward bronze = r(2, 'trophy:counting:bronze', 'trophy');
      final Reward silver = r(3, 'trophy:counting:silver', 'trophy', day: 1);
      final Reward silver2 = r(4, 'trophy:colors:silver', 'trophy', day: 2);
      expect(nextCeremony(<Reward>[medal, bronze]), bronze);
      expect(nextCeremony(<Reward>[bronze, silver, medal]), silver);
      expect(nextCeremony(<Reward>[silver, silver2, bronze]), silver2);
    });

    test('stickers, stars and decorations never get a ceremony', () {
      expect(
        nextCeremony(<Reward>[
          r(1, 'sticker:butterflies:1', 'sticker'),
          r(2, 'star:NUM-A-01', 'star'),
          r(3, 'deco:10', 'decoration'),
        ]),
        isNull,
      );
    });
  });

  group('prizes for the companion', () {
    test('a prize comes with the first trophy of its tier, in any land', () {
      expect(unlockedOutfits(const <String>[]), isEmpty);
      expect(unlockedOutfits(<String>['trophy:counting:bronze']), <String>{'honey'});
      expect(unlockedOutfits(<String>['trophy:colors:silver', 'trophy:counting:bronze']), <String>{
        'honey',
        'sky',
      });
      expect(unlockedOutfits(<String>['star:NUM-A-01', 'sticker:a:1', 'medal:try-again']), isEmpty);
      expect(unlockedOutfits(<String>['trophy:shapes:gold']), <String>{'rose'});
    });

    test('"none" and an unknown id mean no scarf', () {
      expect(outfitById(noOutfit), isNull);
      expect(outfitById('zzz'), isNull);
      expect(outfitById(null), isNull);
      expect(outfitById('sky')!.id, 'sky');
    });
  });

  group('the service gives medals and decorations', () {
    late AppDatabase db;
    late RewardService service;
    final DateTime now = DateTime.utc(2026, 12, 1, 12);

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      service = RewardService(
        db: db,
        catalog: fourSkills(),
        domains: domains,
        nowMs: () => now.millisecondsSinceEpoch,
      );
    });

    Future<void> ask(int times, {required int from}) async {
      for (int i = 0; i < times; i++) {
        await record(db, day0.add(Duration(minutes: from + i)), 'A.1', 'unsure', session: 1);
      }
    }

    test('five asks give the medal, waiting for its ceremony, once', () async {
      await service.evaluate(child); // the first look
      await ask(4, from: 0);
      expect(await service.evaluate(child), isEmpty);
      await ask(1, from: 10);
      final List<Reward> fresh = await service.evaluate(child);
      expect(fresh.map((Reward r) => r.awardKey), <String>['medal:brave-asker']);
      expect(fresh.single.seenAt, isNull);
      expect(await service.evaluate(child), isEmpty, reason: 'given once');
    });

    test('three right answers after a mistake give the other medal', () async {
      await service.evaluate(child);
      for (int i = 0; i < 3; i++) {
        await record(db, day0.add(Duration(minutes: i * 10)), 'A.${i + 1}', 'incorrect', session: 1);
        await record(db, day0.add(Duration(minutes: i * 10 + 1)), 'A.${i + 1}', 'correct', session: 1);
      }
      expect((await service.evaluate(child)).map((Reward r) => r.awardKey), <String>['medal:try-again']);
    });

    test('history that already existed gives its medal quietly', () async {
      await ask(5, from: 0);
      final List<Reward> fresh = await service.evaluate(child);
      expect(fresh.single.awardKey, 'medal:brave-asker');
      expect(
        fresh.single.seenAt,
        isNotNull,
        reason: 'no ceremony for old history, only for the highest trophy',
      );
    });
  });

  group('healthy by design', () {
    test('the habit and ceremony code knows nothing about speed, time played, chance or timers', () {
      for (final String file in <String>[
        'lib/rewards/habits.dart',
        'lib/rewards/ceremony.dart',
        'lib/rewards/outfits.dart',
      ]) {
        final String code = File(file)
            .readAsStringSync()
            .split('\n')
            .where((String l) => !l.trimLeft().startsWith('//'))
            .join('\n');
        for (final String word in <String>[
          'duration',
          'minutes',
          'speed',
          'Random',
          'random',
          'streak',
          'timer',
          'Timer',
          'hintLevel',
          'attemptNo',
        ]) {
          expect(code.contains(word), isFalse, reason: '$file mentions $word');
        }
      }
    });
  });
}
