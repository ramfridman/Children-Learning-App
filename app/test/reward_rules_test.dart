// The reward rules (M8): which awards are due for a history of lasting understanding and finished lessons. Pure, so
// every property of PLAN's "healthy by design" is proved here without a phone: trophies come only from lasting
// understanding, nothing about speed or time can enter, and more history never takes an award away.
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/rewards/award.dart';
import 'package:nitznutz/rewards/reward_rules.dart';

final DateTime day = DateTime.utc(2026, 11, 1, 9);

SkillFact skill(String id, String domain, {int? durableDay}) => SkillFact(
  id: id,
  domain: domain,
  durableAt: durableDay == null ? null : day.add(Duration(days: durableDay)),
);

Set<String> keys(List<AwardDue> due) => <String>{for (final AwardDue a in due) a.key};

void main() {
  group('how many skills each tier needs', () {
    test('bronze the first two, silver half (never fewer than bronze), gold all', () {
      expect(<int>[for (final TrophyTier t in TrophyTier.values) skillsNeeded(t, 3)], <int>[2, 2, 3]);
      expect(<int>[for (final TrophyTier t in TrophyTier.values) skillsNeeded(t, 4)], <int>[2, 2, 4]);
      expect(<int>[for (final TrophyTier t in TrophyTier.values) skillsNeeded(t, 13)], <int>[2, 7, 13]);
      expect(<int>[for (final TrophyTier t in TrophyTier.values) skillsNeeded(t, 1)], <int>[1, 1, 1]);
    });
  });

  group('stickers', () {
    test('one for each finished lesson, numbered in the order they were finished', () {
      final List<AwardDue> due = dueAwards(
        skills: const <SkillFact>[],
        lessons: <FinishedLesson>[
          FinishedLesson(lessonId: 'butterflies', at: day.add(const Duration(days: 2))),
          FinishedLesson(lessonId: 'butterflies', at: day),
          FinishedLesson(lessonId: 'flowers', at: day.add(const Duration(days: 1))),
        ],
      );
      expect(keys(due), <String>{'sticker:butterflies:1', 'sticker:butterflies:2', 'sticker:flowers:1'});
      expect(
        due.firstWhere((AwardDue a) => a.key == 'sticker:butterflies:1').at,
        day,
        reason: 'the first one is the earlier finish',
      );
    });
  });

  group('golden stars', () {
    test('a star for each skill that reached lasting understanding, and for no other', () {
      final List<AwardDue> due = dueAwards(
        skills: <SkillFact>[skill('NUM-A-01', 'numbers', durableDay: 3), skill('NUM-A-02', 'numbers')],
        lessons: const <FinishedLesson>[],
      );
      expect(keys(due), <String>{'star:NUM-A-01'});
      expect(due.single.at, day.add(const Duration(days: 3)));
    });
  });

  group('land trophies', () {
    final List<String> ids = <String>['NUM-A-01', 'NUM-A-02', 'NUM-A-03', 'NUM-A-04'];

    List<SkillFact> land(List<int?> durableDays) => <SkillFact>[
      for (int i = 0; i < durableDays.length; i++) skill(ids[i], 'numbers', durableDay: durableDays[i]),
    ];

    Set<String> trophies(List<AwardDue> due) => <String>{
      for (final AwardDue a in due)
        if (a.kind == AwardKind.trophy) a.key,
    };

    test('a land with fewer than 3 skills has no trophies, however much is understood', () {
      final List<AwardDue> due = dueAwards(
        skills: <SkillFact>[
          skill('NUM-A-01', 'numbers', durableDay: 1),
          skill('NUM-A-02', 'numbers', durableDay: 2),
        ],
        lessons: const <FinishedLesson>[],
      );
      expect(trophies(due), isEmpty);
      expect(keys(due), <String>{'star:NUM-A-01', 'star:NUM-A-02'});
    });

    test('bronze and silver at two of four skills, gold at all four, each at the moment the last needed skill was understood', () {
      expect(
        trophies(dueAwards(skills: land(<int?>[1, null, null, null]), lessons: const <FinishedLesson>[])),
        isEmpty,
      );
      final List<AwardDue> two = dueAwards(
        skills: land(<int?>[5, 2, null, null]),
        lessons: const <FinishedLesson>[],
      );
      expect(trophies(two), <String>{'trophy:counting:bronze', 'trophy:counting:silver'});
      expect(
        two.firstWhere((AwardDue a) => a.key == 'trophy:counting:bronze').at,
        day.add(const Duration(days: 5)),
        reason: 'the second skill to be understood, not the second in the list',
      );
      final List<AwardDue> all = dueAwards(
        skills: land(<int?>[5, 2, 9, 7]),
        lessons: const <FinishedLesson>[],
      );
      expect(trophies(all), contains('trophy:counting:gold'));
      expect(
        all.firstWhere((AwardDue a) => a.key == 'trophy:counting:gold').at,
        day.add(const Duration(days: 9)),
      );
    });

    test('lasting understanding of another land does not count', () {
      final List<AwardDue> due = dueAwards(
        skills: <SkillFact>[
          skill('NUM-A-01', 'numbers'),
          skill('NUM-A-02', 'numbers'),
          skill('NUM-A-03', 'numbers'),
          skill('COL-A-01', 'colors', durableDay: 1),
          skill('COL-A-02', 'colors', durableDay: 1),
        ],
        lessons: const <FinishedLesson>[],
      );
      expect(trophies(due), isEmpty);
    });

    test('a smaller minimum (the dev demo land) lets a small land earn trophies', () {
      final List<AwardDue> due = dueAwards(
        skills: <SkillFact>[skill('NUM-A-01', 'numbers', durableDay: 1)],
        lessons: const <FinishedLesson>[],
        minSkillsPerLand: 1,
      );
      expect(trophies(due), <String>{
        'trophy:counting:bronze',
        'trophy:counting:silver',
        'trophy:counting:gold',
      });
    });
  });

  group('properties over random histories', () {
    // Each history: up to 6 lands' worth of skills, some of them durable on some day, and some finished lessons.
    test('300 random histories', () {
      for (int seed = 0; seed < 300; seed++) {
        final math.Random rnd = math.Random(seed);
        final List<String> domains = <String>['numbers', 'colors', 'shapes', 'logic', 'cs', 'math'];
        final List<SkillFact> skills = <SkillFact>[
          for (int i = 0; i < 1 + rnd.nextInt(30); i++)
            skill(
              'SKL-A-${i.toString().padLeft(2, '0')}',
              domains[rnd.nextInt(domains.length)],
              durableDay: rnd.nextBool() ? rnd.nextInt(60) : null,
            ),
        ];
        final List<FinishedLesson> lessons = <FinishedLesson>[
          for (int i = 0; i < rnd.nextInt(12); i++)
            FinishedLesson(
              lessonId: 'l${rnd.nextInt(3)}',
              at: day.add(Duration(hours: rnd.nextInt(2000))),
            ),
        ];
        final List<AwardDue> due = dueAwards(skills: skills, lessons: lessons);

        // No trophy or star without lasting understanding behind it.
        for (final AwardDue a in due) {
          if (a.kind == AwardKind.star) {
            expect(skills.firstWhere((SkillFact s) => s.id == Awards.starOf(a.key)).durableAt, isNotNull);
          }
          if (a.kind == AwardKind.trophy) {
            final ({TrophyLand land, TrophyTier tier}) t = Awards.trophyOf(a.key)!;
            final List<SkillFact> inLand = skills.where((SkillFact s) => s.domain == t.land.domain).toList();
            final int lasting = inLand.where((SkillFact s) => s.durableAt != null).length;
            expect(inLand.length, greaterThanOrEqualTo(minSkillsForLandTrophy));
            expect(lasting, greaterThanOrEqualTo(skillsNeeded(t.tier, inLand.length)));
          }
        }

        // A trophy is due exactly when the tier's number of skills reached lasting understanding.
        for (final TrophyLand land in TrophyLand.values) {
          final List<SkillFact> inLand = skills.where((SkillFact s) => s.domain == land.domain).toList();
          final int lasting = inLand.where((SkillFact s) => s.durableAt != null).length;
          for (final TrophyTier tier in TrophyTier.values) {
            final bool expected =
                inLand.length >= minSkillsForLandTrophy && lasting >= skillsNeeded(tier, inLand.length);
            expect(keys(due).contains(Awards.trophy(land, tier)), expected, reason: '$land $tier');
          }
        }

        // More history never takes an award away: understand one more skill and every award is still due.
        final List<SkillFact> more = <SkillFact>[
          for (final SkillFact s in skills) s.durableAt == null ? skill(s.id, s.domain, durableDay: 70) : s,
        ];
        expect(keys(dueAwards(skills: more, lessons: lessons)).containsAll(keys(due)), isTrue);

        // The same facts always give the same awards, whatever order they come in.
        expect(
          keys(dueAwards(skills: skills.reversed.toList(), lessons: lessons.reversed.toList())),
          keys(due),
        );
      }
    });
  });

  group('healthy by design', () {
    test('the rules know nothing about speed, time played, number of tries, chance, streaks or timers', () {
      for (final String file in <String>[
        'lib/rewards/reward_rules.dart',
        'lib/rewards/award.dart',
        'lib/rewards/reward_service.dart',
      ]) {
        final String text = File(file).readAsStringSync();
        final String code = text
            .split('\n')
            .where((String l) => !l.trimLeft().startsWith('///') && !l.trimLeft().startsWith('//'))
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
