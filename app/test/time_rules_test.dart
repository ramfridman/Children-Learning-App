// The parent's time rules: defaults by band, the clamping of damaged values, rest hours that wrap midnight, the weekly
// schedule, the daily limit, and how a day's play time is counted from sessions.
import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/data/app_database.dart';
import 'package:nitznutz/parent/parent_rules.dart';
import 'package:nitznutz/parent/time_rules.dart';

Session session(DateTime from, DateTime? to, {String reason = ''}) => Session(
  id: 1,
  profileId: 'p-1',
  startedAt: from,
  endedAt: to,
  plan: 'lesson:butterflies',
  endReason: reason,
);

TimeVerdict at(
  DateTime now, {
  ParentRules rules = const ParentRules(),
  int minutes = 0,
  int band = 1,
  String child = 'p-1',
}) => judgeTime(now: now, rules: rules, profileId: child, ageBand: band, minutesToday: minutes);

void main() {
  // 2026-10-28 is a Wednesday (weekday 3).
  final DateTime noon = DateTime(2026, 10, 28, 12);

  group('the rules themselves', () {
    test('defaults: 20, 30 and 40 minutes by band, rest hours 19:30 to 06:30, locked when done', () {
      const ParentRules r = ParentRules();
      expect(r.limitFor('x', 0), 20);
      expect(r.limitFor('x', 1), 30);
      expect(r.limitFor('x', 2), 40);
      expect(r.restOn, isTrue);
      expect(r.restStartMinute, 19 * 60 + 30);
      expect(r.restEndMinute, 6 * 60 + 30);
      expect(r.lockWhenDone, isTrue);
    });

    test('a limit chosen for one child wins over the band, and survives encode and decode', () {
      final ParentRules r = const ParentRules().copyWith(limitByChild: <String, int>{'p-1': 15});
      final ParentRules back = ParentRules.decode(r.encode());
      expect(back.limitFor('p-1', 2), 15);
      expect(back.limitFor('p-2', 2), 40);
    });

    test('damaged or absurd values are clamped, and unreadable text gives the defaults', () {
      final ParentRules r = ParentRules.fromJson(<String, Object?>{
        'limitByBand': <String, Object?>{'A': 0, 'B': 9999, 'C': 'forty'},
        'restStartMinute': -5,
        'restEndMinute': 99999,
        'schedule': <String, Object?>{
          '3': <Object?>[
            <Object?>[600, 700],
            <Object?>[1, 2, 3],
            'x',
          ],
          '9': <Object?>[
            <Object?>[0, 10],
          ],
        },
        'lockWhenDone': 'yes',
      });
      expect(r.limitFor('x', 0), ParentRules.minLimit);
      expect(r.limitFor('x', 1), ParentRules.maxLimit);
      expect(r.limitFor('x', 2), 40);
      expect(r.restStartMinute, 0);
      expect(r.restEndMinute, 1439);
      expect(r.schedule.keys, <int>[3], reason: 'weekday 9 does not exist');
      expect(r.schedule[3], <List<int>>[
        <int>[600, 700],
      ], reason: 'only well formed windows stay');
      expect(r.lockWhenDone, isTrue);
      expect(ParentRules.decode('{not json').limitFor('x', 1), 30);
      expect(ParentRules.decode(null).limitFor('x', 1), 30);
      expect(ParentRules.decode('[1,2]').limitFor('x', 1), 30);
    });
  });

  group('may the child start?', () {
    test('at noon with no play yet: yes', () {
      final TimeVerdict v = at(noon);
      expect(v.reason, RestReason.none);
      expect(v.mayStart, isTrue);
    });

    test('rest hours wrap midnight: 23:00 and 05:00 rest, 07:00 and 19:29 do not, 19:30 does', () {
      expect(at(DateTime(2026, 10, 28, 23)).reason, RestReason.restHours);
      expect(at(DateTime(2026, 10, 29, 5)).reason, RestReason.restHours);
      expect(at(DateTime(2026, 10, 28, 7)).reason, RestReason.none);
      expect(at(DateTime(2026, 10, 28, 19, 29)).reason, RestReason.none);
      expect(at(DateTime(2026, 10, 28, 19, 30)).reason, RestReason.restHours);
      expect(at(DateTime(2026, 10, 28, 6, 30)).reason, RestReason.none);
    });

    test('rest hours that do not wrap, and rest hours turned off', () {
      final ParentRules day = const ParentRules().copyWith(restStartMinute: 13 * 60, restEndMinute: 15 * 60);
      expect(at(DateTime(2026, 10, 28, 14), rules: day).reason, RestReason.restHours);
      expect(at(DateTime(2026, 10, 28, 16), rules: day).reason, RestReason.none);
      final ParentRules off = const ParentRules().copyWith(restOn: false);
      expect(at(DateTime(2026, 10, 28, 23), rules: off).reason, RestReason.none);
    });

    test(
      'the weekly schedule: outside its windows on a day with windows is rest; days without windows are open',
      () {
        final ParentRules r = const ParentRules().copyWith(
          schedule: <int, List<List<int>>>{
            3: <List<int>>[
              <int>[16 * 60, 18 * 60],
            ],
          },
        );
        expect(at(DateTime(2026, 10, 28, 17), rules: r).reason, RestReason.none);
        expect(at(DateTime(2026, 10, 28, 12), rules: r).reason, RestReason.schedule);
        expect(
          at(DateTime(2026, 10, 29, 12), rules: r).reason,
          RestReason.none,
          reason: 'Thursday has no windows',
        );
      },
    );

    test('the daily limit: below it open, at it resting', () {
      expect(at(noon, minutes: 29).reason, RestReason.none);
      expect(at(noon, minutes: 30).reason, RestReason.limit);
      expect(at(noon, minutes: 19, band: 0).reason, RestReason.none);
      expect(at(noon, minutes: 20, band: 0).reason, RestReason.limit);
      expect(at(noon, minutes: 39, band: 2).reason, RestReason.none);
    });

    test('rest hours come before the schedule, and the schedule before the limit', () {
      final ParentRules r = const ParentRules().copyWith(
        schedule: <int, List<List<int>>>{
          3: <List<int>>[
            <int>[16 * 60, 18 * 60],
          ],
        },
      );
      expect(at(DateTime(2026, 10, 28, 21), rules: r, minutes: 99).reason, RestReason.restHours);
      expect(at(DateTime(2026, 10, 28, 12), rules: r, minutes: 99).reason, RestReason.schedule);
      expect(at(DateTime(2026, 10, 28, 17), rules: r, minutes: 99).reason, RestReason.limit);
    });

    test('when the parent does not lock, time being up only suggests rest', () {
      final ParentRules r = const ParentRules().copyWith(lockWhenDone: false);
      final TimeVerdict v = at(noon, rules: r, minutes: 60);
      expect(v.resting, isTrue);
      expect(v.locked, isFalse);
      expect(v.mayStart, isTrue);
      expect(at(noon, minutes: 60).mayStart, isFalse);
    });
  });

  group('counting a day of play', () {
    test('finished sessions add up; an open one counts up to now', () {
      final DateTime now = DateTime(2026, 10, 28, 12);
      final int m = playedMinutesToday(<Session>[
        session(DateTime(2026, 10, 28, 8), DateTime(2026, 10, 28, 8, 10)),
        session(DateTime(2026, 10, 28, 9), DateTime(2026, 10, 28, 9, 5)),
        session(DateTime(2026, 10, 28, 11, 50), null),
      ], now);
      expect(m, 10 + 5 + 10);
    });

    test('yesterday does not count, and a session over midnight counts only its part of today', () {
      final DateTime now = DateTime(2026, 10, 28, 12);
      expect(
        playedMinutesToday(<Session>[
          session(DateTime(2026, 10, 27, 10), DateTime(2026, 10, 27, 10, 30)),
        ], now),
        0,
      );
      expect(
        playedMinutesToday(<Session>[
          session(DateTime(2026, 10, 27, 23, 50), DateTime(2026, 10, 28, 0, 20)),
        ], now),
        20,
      );
    });

    test('one session counts for at most 90 minutes: a phone left on the map does not use up the day', () {
      final DateTime now = DateTime(2026, 10, 28, 18);
      expect(playedMinutesToday(<Session>[session(DateTime(2026, 10, 28, 8), null)], now), 90);
      expect(
        playedMinutesToday(<Session>[session(DateTime(2026, 10, 28, 8), null)], now, longestSession: 30),
        30,
      );
    });

    test('a session that ends before it starts counts for nothing', () {
      final DateTime now = DateTime(2026, 10, 28, 12);
      expect(
        playedMinutesToday(<Session>[session(DateTime(2026, 10, 28, 9), DateTime(2026, 10, 28, 8))], now),
        0,
      );
    });
  });
}
