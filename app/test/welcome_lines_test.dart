// B-42 part (b): the composer of the daily welcome (`welcomeLines`), a pure function. The nine cases of
// docs/milestones/B42.md section 8, the day rotation, the rules about the name clip, and that the function reads nothing
// but its arguments.
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/content/models.dart';
import 'package:nitznutz/rewards/award.dart';
import 'package:nitznutz/world/todays_adventure.dart';
import 'package:nitznutz/world/welcome_adapter.dart';
import 'package:nitznutz/world/welcome_lines.dart';
import 'package:nitznutz/world/welcome_table.dart';

import 'support/starter.dart';

const String _name = welcomeNameClip;

late WelcomeTable table;

/// A warm-up that must not be asked about (a revisit or a replay has none).
bool _notAsked(TrophyLand land) => throw StateError('the warm-up is asked only for a lesson');

bool _noWarmUp(TrophyLand land) => false;

/// The lessons of the cases and their first skill of the land.
const Map<String, String> _firstSkill = <String, String>{
  'numbers-first': 'NUM-A-01',
  'glance': 'NUM-A-05',
  'colors-next': 'COL-B-01',
  'position': 'SHP-A-08',
  'solids': 'SHP-A-07',
  'future': 'NUM-Z-99',
};

String? _skillOf(String lessonId, TrophyLand land) => _firstSkill[lessonId];

List<String> _lines(
  TodaysAdventure stop, {
  int today = 0,
  bool name = true,
  bool Function(TrophyLand) warmUp = _noWarmUp,
  String? Function(String, TrophyLand) skillOf = _skillOf,
}) => welcomeLines(
  stop: stop,
  today: today,
  hasNameClip: name,
  warmUpDue: warmUp,
  skillOfLesson: skillOf,
  table: table,
);

void main() {
  setUpAll(() {
    table = WelcomeTable.parse(File('assets/lines/welcome.json').readAsStringSync());
  });

  group('the nine cases of B42.md section 8', () {
    test('1. a new child: the first-day greeting, whatever the day', () {
      const TodaysAdventure stop = TodaysAdventure.lesson(
        TrophyLand.counting,
        'numbers-first',
        AdventureReason.welcome,
      );
      for (final int day in <int>[0, 1, 2, 20400]) {
        expect(_lines(stop, today: day), <String>[
          _name,
          'vo:welcome.hello.first',
          'vo:welcome.topic.counting.count',
          'vo:welcome.close',
        ]);
      }
    });

    test('2. the next lesson of the same land, day mod 3 = 0, with a name', () {
      const TodaysAdventure stop = TodaysAdventure.lesson(
        TrophyLand.counting,
        'glance',
        AdventureReason.sameLand,
      );
      expect(_lines(stop, today: 20400), <String>[
        _name,
        'vo:welcome.hello.1',
        'vo:welcome.topic.counting.glance',
        'vo:welcome.close',
      ]);
    });

    test('3. the same stop, day mod 3 = 1, no name clip: the same welcome without it', () {
      const TodaysAdventure stop = TodaysAdventure.lesson(
        TrophyLand.counting,
        'glance',
        AdventureReason.sameLand,
      );
      expect(_lines(stop, today: 20401, name: false), <String>[
        'vo:welcome.hello.2',
        'vo:welcome.topic.counting.glance',
        'vo:welcome.close',
      ]);
    });

    test('4. a call for help names the topic of the skill; the warm-up is not asked', () {
      expect(
        _lines(
          const TodaysAdventure.revisit(TrophyLand.market, 'MATH-B-09'),
          today: 20402,
          warmUp: _notAsked,
        ),
        <String>[_name, 'vo:welcome.hello.3', 'vo:welcome.topic.market.equal', 'vo:welcome.close'],
      );
    });

    test('5. a lesson whose warm-up is due says the land: the warm-up decides where to start', () {
      const TodaysAdventure stop = TodaysAdventure.lesson(
        TrophyLand.colors,
        'colors-next',
        AdventureReason.otherLand,
      );
      expect(_lines(stop, today: 20400, warmUp: (TrophyLand l) => l == TrophyLand.colors), <String>[
        _name,
        'vo:welcome.hello.1',
        'vo:welcome.land.colors',
        'vo:welcome.close',
      ]);
      expect(
        _lines(stop, today: 20400)[2],
        'vo:welcome.topic.colors.mix',
        reason: 'with no warm-up due, the topic of COL-B-01',
      );
    });

    test('6. a game played again says the topic of its skill; the warm-up is not asked', () {
      expect(
        _lines(const TodaysAdventure.replay(TrophyLand.shapes, 'position'), today: 20401, warmUp: _notAsked),
        <String>[_name, 'vo:welcome.hello.2', 'vo:welcome.topic.shapes.position', 'vo:welcome.close'],
      );
    });

    test('7. a skill with no topic row (in the land line list, or in no row at all) gets its land line', () {
      for (final String lesson in <String>['solids', 'future']) {
        expect(
          _lines(
            TodaysAdventure.lesson(
              lesson == 'solids' ? TrophyLand.shapes : TrophyLand.counting,
              lesson,
              AdventureReason.sameLand,
            ),
            today: 20400,
            name: false,
          ),
          <String>[
            'vo:welcome.hello.1',
            lesson == 'solids' ? 'vo:welcome.land.shapes' : 'vo:welcome.land.counting',
            'vo:welcome.close',
          ],
          reason: lesson,
        );
      }
    });

    test('8. nothing to play: the name and the greeting only', () {
      expect(_lines(const TodaysAdventure.none(), today: 20402), <String>[_name, 'vo:welcome.hello.3']);
      expect(_lines(const TodaysAdventure.none(), today: 20402, name: false), <String>['vo:welcome.hello.3']);
    });

    test('9. the lesson on two paths says the topic of its first skill of the land of the stop', () async {
      final PackContent content = await loadStarter();
      String? skillOf(String lessonId, TrophyLand land) => firstSkillInLand(content, lessonId, land);
      final String? numbers = skillOf('butterflies', TrophyLand.counting);
      final String? colours = skillOf('butterflies', TrophyLand.colors);
      expect(numbers, startsWith('NUM-'));
      expect(colours, startsWith('COL-'));
      expect(
        _lines(
          const TodaysAdventure.lesson(TrophyLand.counting, 'butterflies', AdventureReason.sameLand),
          name: false,
          skillOf: skillOf,
        )[1],
        table.topicOf(numbers!) ?? table.landLine(TrophyLand.counting),
      );
      expect(
        _lines(
          const TodaysAdventure.lesson(TrophyLand.colors, 'butterflies', AdventureReason.sameLand),
          name: false,
          skillOf: skillOf,
        )[1],
        table.topicOf(colours!) ?? table.landLine(TrophyLand.colors),
      );
    });
  });

  group('the greeting turns with the day, and the function is deterministic', () {
    const TodaysAdventure stop = TodaysAdventure.lesson(
      TrophyLand.counting,
      'glance',
      AdventureReason.sameLand,
    );

    test('three days in a row give the three greetings, then they come round again', () {
      final List<String> greetings = <String>[
        for (int day = 20400; day < 20406; day++) _lines(stop, today: day, name: false).first,
      ];
      expect(greetings, <String>[...welcomeHellos, ...welcomeHellos]);
    });

    test('the same arguments give the same lines, and the list cannot be changed', () {
      final math.Random random = math.Random(42);
      for (int i = 0; i < 200; i++) {
        final TrophyLand land = TrophyLand.values[random.nextInt(TrophyLand.values.length)];
        final TodaysAdventure s = TodaysAdventure.lesson(land, 'glance', AdventureReason.otherLand);
        final int day = 20000 + random.nextInt(2000);
        final bool name = random.nextBool();
        final bool due = random.nextBool();
        final List<String> a = _lines(s, today: day, name: name, warmUp: (TrophyLand _) => due);
        final List<String> b = _lines(s, today: day, name: name, warmUp: (TrophyLand _) => due);
        expect(a, b);
        expect(() => a.add('x'), throwsUnsupportedError);
      }
    });

    test('the file reads no clock, no random source, nothing from the device', () {
      for (final String name in <String>['welcome_lines.dart', 'welcome_table.dart']) {
        final String text = File('lib/world/$name').readAsStringSync();
        for (final String banned in <String>['DateTime', 'Random', 'dart:io', 'Platform', 'Stopwatch']) {
          expect(text.contains(banned), isFalse, reason: '$name mentions $banned');
        }
        expect(
          RegExp(
            r'''^\s*import\s+['"]([^'"]+)['"]''',
            multiLine: true,
          ).allMatches(text).map((RegExpMatch m) => m[1]!),
          everyElement(anyOf(startsWith('../rewards/award'), startsWith('dart:convert'), endsWith('.dart'))),
          reason: name,
        );
      }
    });
  });

  group('what the welcome may say', () {
    /// Every welcome the composer can make: each land and kind of stop, every day of three, with and without a name, the
    /// warm-up due and not, each skill of the table as the stop's skill.
    Iterable<List<String>> everyWelcome() sync* {
      final List<String> skills = <String>[
        'NUM-A-01',
        'MATH-B-09',
        'SHP-A-07',
        'NUM-Z-99',
        for (final TrophyLand l in TrophyLand.values) 'x-${l.name}',
      ];
      for (final TrophyLand land in TrophyLand.values) {
        for (final int day in <int>[20400, 20401, 20402]) {
          for (final bool name in <bool>[true, false]) {
            for (final bool due in <bool>[true, false]) {
              for (final String skill in skills) {
                for (final AdventureReason reason in AdventureReason.values) {
                  if (reason == AdventureReason.nothing) continue;
                  yield _lines(
                    TodaysAdventure.lesson(land, 'any', reason),
                    today: day,
                    name: name,
                    warmUp: (TrophyLand _) => due,
                    skillOf: (String _, TrophyLand _) => skill,
                  );
                }
                yield _lines(TodaysAdventure.revisit(land, skill), today: day, name: name, warmUp: _notAsked);
                yield _lines(
                  TodaysAdventure.replay(land, 'any'),
                  today: day,
                  name: name,
                  warmUp: _notAsked,
                  skillOf: (String _, TrophyLand _) => skill,
                );
              }
            }
          }
          yield _lines(const TodaysAdventure.none(), today: day, name: day.isEven);
        }
      }
    }

    test('only a greeting follows the name clip, which is first and once', () {
      int seen = 0;
      for (final List<String> welcome in everyWelcome()) {
        final int at = welcome.indexOf(welcomeNameClip);
        if (at < 0) continue;
        seen++;
        expect(at, 0, reason: '$welcome');
        expect(welcome.where((String l) => l == welcomeNameClip), hasLength(1), reason: '$welcome');
        expect(welcome[1], anyOf(welcomeHelloFirst, isIn(welcomeHellos)), reason: '$welcome');
        expect(mayFollowNameClip(welcome[1]), isTrue);
        for (int i = 2; i < welcome.length; i++) {
          expect(mayFollowNameClip(welcome[i]), isFalse, reason: '${welcome[i]} follows no name');
        }
      }
      expect(seen, greaterThan(100));
    });

    test('the map bubble\'s shared clip may follow a name clip; no topic, land or closing line may', () {
      expect(mayFollowNameClip(homeBubbleVoice), isTrue);
      expect(homeBubbleVoice, 'vo:core.home.bubble');
      for (final String id in table.lineIds) {
        final bool greeting = id.startsWith('vo:welcome.hello.');
        expect(mayFollowNameClip(id), greeting, reason: id);
      }
      expect(mayFollowNameClip('vo:core.greeting.hello'), isFalse);
    });

    test(
      'a welcome is a greeting, then (with a stop) one middle line and the closing line; every id is a line',
      () {
        for (final List<String> welcome in everyWelcome()) {
          final List<String> ids = welcome.where((String l) => l != welcomeNameClip).toList();
          expect(ids.length, anyOf(1, 3), reason: '$welcome');
          for (final String id in ids) {
            expect(table.lineIds, contains(id));
          }
          if (ids.length == 3) {
            expect(ids.last, welcomeClose);
            expect(ids[1], anyOf(startsWith('vo:welcome.topic.'), startsWith('vo:welcome.land.')));
          }
        }
      },
    );

    test('no line of the welcome has a placeholder, so none can say the child\'s name', () {
      for (final String id in table.lineIds) {
        expect(table.text(id), isNot(matches(RegExp('[{}]'))), reason: id);
        expect(table.text(id), isNotEmpty, reason: id);
      }
    });

    test('no line counts days, visits or streaks, or misses the child', () {
      // The unpointed words that would say "again today", "you were away" or "so many days", checked on every line.
      final RegExp points = RegExp(r'[\u0591-\u05C7]');
      const List<String> banned = <String>[
        'רצף',
        'התגעגע',
        'חסרת',
        'אתמול',
        'מחר',
        'ימים',
        'שבוע',
        'פספס',
        'נעלמ',
        'שוב היום',
      ];
      for (final String id in table.lineIds) {
        final String plain = table.text(id).replaceAll(points, '');
        for (final String word in banned) {
          expect(plain, isNot(contains(word)), reason: '$id: $word');
        }
      }
    });
  });

  group('the table', () {
    test('a topic line goes with the skills the table names, and a land line with its land', () {
      expect(table.topicOf('NUM-A-05'), 'vo:welcome.topic.counting.glance');
      expect(table.topicOf('SHP-A-07'), isNull, reason: 'it is in the land line list');
      expect(table.places('SHP-A-07'), isTrue);
      expect(table.places('NUM-Z-99'), isFalse);
      expect(table.landOf('MATH-B-09'), TrophyLand.market);
      expect(table.landLine(TrophyLand.robots), 'vo:welcome.land.robots');
    });

    test('a broken document is refused', () {
      expect(() => WelcomeTable.parse('{"schema":"x"}'), throwsFormatException);
      expect(() => WelcomeTable.parse('[]'), throwsFormatException);
    });
  });
}
