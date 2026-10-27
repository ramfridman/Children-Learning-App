// What a child has earned, kept (M8): the service reads a real history through the real engine, gives each award once,
// presents only the highest trophy for history that already existed, and never takes anything away.
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/data/app_database.dart';
import 'package:nitznutz/engine/types.dart';
import 'package:nitznutz/rewards/award.dart';
import 'package:nitznutz/rewards/reward_service.dart';

import 'engine/fixtures.dart';

const String child = 'p-1';

/// Four skills of the numbers domain (a land with trophies), each with the items the engine needs to reach lasting
/// understanding: two representations, an open check, and a spare item for the delayed check.
Catalog fourSkills() {
  final Catalog c = smallCatalog();
  return Catalog(
    skills: c.skills.values,
    items: <ItemMeta>[
      ...c.items.values,
      for (final String l in <String>['A', 'B', 'C', 'D'])
        ItemMeta(
          id: '$l.4',
          skills: <String, double>{'SK-$l-01': 1},
          representation: Representation.story,
          variantGroup: '$l-g4',
          optionCount: 3,
        ),
    ],
    tags: c.tags.values,
  );
}

const Map<String, String> domains = <String, String>{
  'SK-A-01': 'numbers',
  'SK-B-01': 'numbers',
  'SK-C-01': 'numbers',
  'SK-D-01': 'numbers',
};

/// Writes the answers that bring skill [l] to lasting understanding, starting at [start]. Returns the day it ends.
Future<DateTime> understand(AppDatabase db, String l, DateTime start) async {
  DateTime at = start;
  Future<void> right(String item) async {
    await db.recordAttempt(
      AttemptsCompanion.insert(
        at: at,
        profileId: child,
        packId: 'starter',
        packVersion: '0.2.0',
        activityId: item,
        activityRevision: 1,
        template: 'count_tap',
        templateVersion: '1.0',
        skillId: 'SK-$l-01',
        result: 'correct',
        attemptNo: 1,
        hintLevel: 0,
      ),
    );
    at = at.add(const Duration(seconds: 40));
  }

  for (final String i in <String>['$l.1', '$l.2', '$l.1', '$l.2']) {
    await right(i);
  }
  at = at.add(const Duration(days: 1));
  await right('$l.3');
  await right('$l.1');
  at = at.add(const Duration(days: 8));
  await right('$l.4');
  return at;
}

Future<void> finishLesson(AppDatabase db, DateTime at, {String lesson = 'butterflies'}) async {
  final int id = await db.startSession(child, at, plan: 'lesson:$lesson');
  await db.endSession(id, at.add(const Duration(minutes: 5)), 'finished');
}

void main() {
  late AppDatabase db;
  late RewardService service;
  DateTime now = DateTime.utc(2026, 12, 1, 12);

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    now = DateTime.utc(2026, 12, 1, 12);
    service = RewardService(
      db: db,
      catalog: fourSkills(),
      domains: domains,
      nowMs: () => now.millisecondsSinceEpoch,
    );
  });

  Future<Map<String, Reward>> held() async => <String, Reward>{
    for (final Reward r in await db.rewardsOf(child)) r.awardKey: r,
  };

  test('nothing earned, nothing given; and asking again changes nothing', () async {
    expect(await service.evaluate(child), isEmpty);
    expect(await service.evaluate(child), isEmpty);
    expect(await db.rewardsOf(child), isEmpty);
  });

  test(
    'a finished lesson gives a sticker that waits to be revealed; a lesson left early gives none',
    () async {
      await service.evaluate(child); // the first look at this child (nothing yet)
      await finishLesson(db, day0);
      final int home = await db.startSession(
        child,
        day0.add(const Duration(hours: 1)),
        plan: 'lesson:butterflies',
      );
      await db.endSession(home, day0.add(const Duration(hours: 1, minutes: 2)), 'home');
      final List<Reward> fresh = await service.evaluate(child);
      expect(fresh.map((Reward r) => r.awardKey), <String>['sticker:butterflies:1']);
      expect(fresh.single.seenAt, isNull);
      expect(await service.evaluate(child), isEmpty, reason: 'given once');
      await finishLesson(db, day0.add(const Duration(days: 1)));
      expect((await service.evaluate(child)).single.awardKey, 'sticker:butterflies:2');
    },
  );

  test('lasting understanding gives a golden star at once; trophies wait for their ceremony; fresh mastery gives none', () async {
    await service.evaluate(child);
    DateTime t = await understand(db, 'A', day0);
    List<Reward> fresh = await service.evaluate(child);
    expect(fresh.map((Reward r) => r.awardKey), <String>['star:SK-A-01']);
    expect(fresh.single.seenAt, isNotNull, reason: 'a star shows on the map and needs no ceremony');
    t = await understand(db, 'B', t);
    fresh = await service.evaluate(child);
    expect(fresh.map((Reward r) => r.awardKey).toSet(), <String>{
      'star:SK-B-01',
      'trophy:counting:bronze',
      'trophy:counting:silver',
    });
    expect(
      fresh.where((Reward r) => r.kind == 'trophy').every((Reward r) => r.seenAt == null),
      isTrue,
      reason: 'trophies wait for the ceremony',
    );
    await understand(db, 'C', t);
    await understand(db, 'D', t);
    fresh = await service.evaluate(child);
    expect(fresh.map((Reward r) => r.awardKey).toSet(), contains('trophy:counting:gold'));
  });

  test('only fresh mastery (no delayed check yet) gives no star and no trophy', () async {
    await service.evaluate(child);
    DateTime at = day0;
    for (final String i in <String>['A.1', 'A.2', 'A.1', 'A.2']) {
      await db.recordAttempt(
        AttemptsCompanion.insert(
          at: at,
          profileId: child,
          packId: 'starter',
          packVersion: '0.2.0',
          activityId: i,
          activityRevision: 1,
          template: 'count_tap',
          templateVersion: '1.0',
          skillId: 'SK-A-01',
          result: 'correct',
          attemptNo: 1,
          hintLevel: 0,
        ),
      );
      at = at.add(const Duration(seconds: 40));
    }
    expect(await service.evaluate(child), isEmpty);
  });

  test(
    'history from before rewards existed is given quietly, and only the highest trophy is presented',
    () async {
      DateTime t = await understand(db, 'A', day0);
      t = await understand(db, 'B', t);
      await finishLesson(db, day0);
      final List<Reward> fresh = await service.evaluate(child);
      final Map<String, Reward> all = await held();
      expect(all.keys.toSet(), <String>{
        'sticker:butterflies:1',
        'star:SK-A-01',
        'star:SK-B-01',
        'trophy:counting:bronze',
        'trophy:counting:silver',
      });
      expect(fresh.length, all.length);
      final Set<String> waiting = <String>{
        for (final Reward r in all.values)
          if (r.seenAt == null) r.awardKey,
      };
      expect(waiting, <String>{'trophy:counting:silver'}, reason: 'one ceremony, for the highest tier');
      expect(await service.evaluate(child), isEmpty);
      // After that, things are presented as they are earned.
      await finishLesson(db, day0.add(const Duration(days: 30)));
      expect((await service.evaluate(child)).single.seenAt, isNull);
    },
  );

  test('nothing is ever taken away: a reset of the history, a failed later check, or the same history in another order', () async {
    await service.evaluate(child);
    final DateTime t = await understand(db, 'A', day0);
    await understand(db, 'B', t);
    await finishLesson(db, day0);
    await service.evaluate(child);
    final Set<String> before = (await held()).keys.toSet();
    expect(before, isNotEmpty);

    // A later check on skill A is failed: the skill needs a revisit, and the star stays.
    await db.recordAttempt(
      AttemptsCompanion.insert(
        at: day0.add(const Duration(days: 100)),
        profileId: child,
        packId: 'starter',
        packVersion: '0.2.0',
        activityId: 'A.2',
        activityRevision: 1,
        template: 'count_tap',
        templateVersion: '1.0',
        skillId: 'SK-A-01',
        result: 'incorrect',
        attemptNo: 1,
        hintLevel: 0,
      ),
    );
    await service.evaluate(child);
    expect((await held()).keys.toSet(), containsAll(before));

    // The engine's whole picture is lost (every answer and visit removed here): the awards stay.
    await db.customStatement('DELETE FROM attempts');
    await db.customStatement('DELETE FROM sessions');
    expect(await service.due(child), isEmpty);
    await service.evaluate(child);
    expect((await held()).keys.toSet(), containsAll(before));
  });

  test('the preview writes nothing', () async {
    await understand(db, 'A', day0);
    final List<AwardDue> due = await service.due(child);
    expect(due.map((AwardDue a) => a.key), contains('star:SK-A-01'));
    expect(await db.rewardsOf(child), isEmpty);
  });

  test('awards go with the child when the child is removed, and only then', () async {
    await db.addProfile(
      ProfilesCompanion.insert(
        id: child,
        name: 'נועה',
        avatar: 'avatar-noa',
        addressForm: 'f',
        ageBand: 1,
        createdAt: now,
      ),
    );
    await service.evaluate(child);
    await understand(db, 'A', day0);
    await service.evaluate(child);
    expect(await db.rewardsOf(child), isNotEmpty);
    await db.deleteChildData(child);
    expect(await db.rewardsOf(child), isEmpty);
  });

  test('picking the one trophy to present: the highest tier, then the latest', () {
    final DateTime a = DateTime.utc(2026, 1, 1);
    final DateTime b = DateTime.utc(2026, 2, 1);
    expect(
      RewardService.pickCeremony(<({String key, DateTime at})>[
        (key: 'trophy:counting:silver', at: b),
        (key: 'trophy:colors:gold', at: a),
        (key: 'trophy:counting:bronze', at: b),
      ]),
      'trophy:colors:gold',
    );
    expect(
      RewardService.pickCeremony(<({String key, DateTime at})>[
        (key: 'trophy:counting:silver', at: a),
        (key: 'trophy:colors:silver', at: b),
      ]),
      'trophy:colors:silver',
    );
    expect(RewardService.pickCeremony(const <({String key, DateTime at})>[]), isNull);
  });
}
