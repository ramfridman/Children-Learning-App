// QA, B-42 (docs/milestones/B42.md section 8 row 7). Gaps the developer's own tests leave open, each one a line of the
// acceptance: every reason of Today's Adventure by name (and a new reason must get a row here), the warm-up asked only for
// a lesson, an unmapped skill and a lesson with no skill, no day, streak, absence or guilt word in what the child sees AND
// in what the child hears (the voice_text of the master table, which is what ElevenLabs reads), and the "any tap" rule on the
// real map (the pill, the parents button, the open sea, a change of child), with the day kept in every case.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/data/app_database.dart';
import 'package:nitznutz/rewards/award.dart';
import 'package:nitznutz/strings/he.dart';
import 'package:nitznutz/world/todays_adventure.dart';
import 'package:nitznutz/world/welcome_lines.dart';
import 'package:nitznutz/world/welcome_table.dart';

import '../tool/voice_text_lib.dart' show MasterRow, coreSource, masterKey, readMaster;
import 'support/app_harness.dart';
import 'support/harness.dart';

late WelcomeTable table;

bool _noWarmUp(TrophyLand land) => false;

List<String> _lines(
  TodaysAdventure stop, {
  int today = 20400,
  bool name = true,
  bool Function(TrophyLand) warmUp = _noWarmUp,
  String? Function(String, TrophyLand) skillOf = _skill,
}) => welcomeLines(
  stop: stop,
  today: today,
  hasNameClip: name,
  warmUpDue: warmUp,
  skillOfLesson: skillOf,
  table: table,
);

String? _skill(String lessonId, TrophyLand land) => 'NUM-A-05';

/// The words of a line, without points or punctuation.
List<String> _words(String text) => text
    .replaceAll(RegExp(r'[֑-ׇ]'), '')
    .split(RegExp(r'[^א-ת0-9A-Za-z]+'))
    .where((String w) => w.isNotEmpty)
    .toList();

/// Words that count days, visits, absence or streaks, or say "again", "still", "no", "missed", "forgot": none of them
/// may be in a welcome line (B42.md 2.6, CLAUDE.md child safety: no streaks, no guilt). "היום" is the plan of the visit and is
/// allowed; "חסר" is the topic "what is missing" (market.missing) and is allowed.
const Set<String> _banned = <String>{
  'יום',
  'ימים',
  'יומיים',
  'שבוע',
  'שבועות',
  'חודש',
  'אתמול',
  'מחר',
  'שלשום',
  'רצף',
  'שוב',
  'עוד',
  'כבר',
  'פעם',
  'פעמים',
  'לא',
  'אין',
  'התגעגענו',
  'התגעגעתי',
  'געגועים',
  'חיכינו',
  'חיכיתי',
  'פספסנו',
  'פספסת',
  'שכחת',
  'נעלם',
  'נעלמו',
  'חזרת',
  'חזרנו',
  'סוף',
  'נקודות',
  'כוכבים',
  'ניקוד',
  'הצלחת',
  'טעית',
  'נכון',
  'בזמן',
  'מהר',
  'שניות',
  'דקות',
};

/// A welcome line's id without `vo:`, the id of the row in the master table.
String _fileId(String voId) => voId.substring('vo:'.length);

Future<void> _start(WidgetTester tester) async {
  for (int i = 0; i < 20; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

String _bubble(WidgetTester tester) => tester
    .widget<Text>(find.descendant(of: find.byKey(const Key('bubble-body')), matching: find.byType(Text)))
    .data!
    .replaceAll(RegExp(r'[\u2066-\u2069\u200E\u200F]'), '');

bool _isOwn(WidgetTester tester) => _bubble(tester).endsWith(He.homeBubbleNoName.text);

Future<AppRig> _toMap(WidgetTester tester, AppRig rig, String name) async {
  await rig.pump(tester, reduceMotion: true);
  await tester.tap(find.text(name));
  await tester.pump();
  return rig;
}

void main() {
  setUpAll(() async {
    await loadAppFonts();
    table = WelcomeTable.parse(File('assets/lines/welcome.json').readAsStringSync());
  });

  group('the composer, reason by reason (B42.md 2.2 and section 8 row 7)', () {
    // One stop for each reason Today's Adventure can give. A reason added later must be added here (the last test).
    final Map<AdventureReason, TodaysAdventure> stops = <AdventureReason, TodaysAdventure>{
      AdventureReason.welcome: const TodaysAdventure.lesson(
        TrophyLand.counting,
        'l',
        AdventureReason.welcome,
      ),
      AdventureReason.sameLand: const TodaysAdventure.lesson(
        TrophyLand.counting,
        'l',
        AdventureReason.sameLand,
      ),
      AdventureReason.otherLand: const TodaysAdventure.lesson(
        TrophyLand.counting,
        'l',
        AdventureReason.otherLand,
      ),
      AdventureReason.callForHelp: const TodaysAdventure.revisit(TrophyLand.counting, 'NUM-A-05'),
      AdventureReason.playAgain: const TodaysAdventure.replay(TrophyLand.counting, 'l'),
      AdventureReason.nothing: const TodaysAdventure.none(),
    };

    test('every reason the app can give has a row in this test', () {
      expect(stops.keys.toSet(), AdventureReason.values.toSet());
      for (final MapEntry<AdventureReason, TodaysAdventure> e in stops.entries) {
        expect(e.value.reason, e.key, reason: 'the stop of ${e.key} has another reason');
      }
    });

    test(
      'only the first day has its own greeting; every other reason turns with the day, on every day of three',
      () {
        for (final MapEntry<AdventureReason, TodaysAdventure> e in stops.entries) {
          for (int day = 20400; day < 20403; day++) {
            final List<String> lines = _lines(e.value, today: day, name: false);
            final String want = e.key == AdventureReason.welcome ? welcomeHelloFirst : welcomeHellos[day % 3];
            expect(lines.first, want, reason: '${e.key} on day $day');
          }
        }
      },
    );

    test(
      'every reason with a stop ends with the topic or land line and the closing line; "nothing" has neither',
      () {
        for (final MapEntry<AdventureReason, TodaysAdventure> e in stops.entries) {
          final List<String> lines = _lines(e.value, name: true);
          if (e.key == AdventureReason.nothing) {
            expect(lines, <String>[welcomeNameClip, welcomeHellos[20400 % 3]]);
          } else {
            expect(lines, hasLength(4), reason: '${e.key}: $lines');
            expect(lines[2], 'vo:welcome.topic.counting.glance');
            expect(lines.last, welcomeClose);
          }
        }
      },
    );

    test('the warm-up decides the land line for a lesson only; a revisit and a replay keep their topic when it is due', () {
      bool due(TrophyLand _) => true;
      expect(_lines(stops[AdventureReason.sameLand]!, warmUp: due)[2], 'vo:welcome.land.counting');
      expect(_lines(stops[AdventureReason.welcome]!, warmUp: due)[2], 'vo:welcome.land.counting');
      expect(_lines(stops[AdventureReason.otherLand]!, warmUp: due)[2], 'vo:welcome.land.counting');
      expect(_lines(stops[AdventureReason.callForHelp]!, warmUp: due)[2], 'vo:welcome.topic.counting.glance');
      expect(_lines(stops[AdventureReason.playAgain]!, warmUp: due)[2], 'vo:welcome.topic.counting.glance');
    });

    test('the warm-up is asked about the land of the stop, and only for a lesson', () {
      final List<TrophyLand> asked = <TrophyLand>[];
      bool due(TrophyLand l) {
        asked.add(l);
        return false;
      }

      _lines(const TodaysAdventure.lesson(TrophyLand.colors, 'l', AdventureReason.otherLand), warmUp: due);
      expect(asked, <TrophyLand>[TrophyLand.colors]);
      asked.clear();
      _lines(stops[AdventureReason.callForHelp]!, warmUp: due);
      _lines(stops[AdventureReason.playAgain]!, warmUp: due);
      _lines(stops[AdventureReason.nothing]!, warmUp: due);
      expect(asked, isEmpty);
    });

    test(
      'an unmapped skill, a lesson with no skill of the land and a lesson with no id all say the land line',
      () {
        expect(
          _lines(stops[AdventureReason.sameLand]!, skillOf: (String _, TrophyLand _) => 'NUM-Z-99')[2],
          'vo:welcome.land.counting',
          reason: 'a skill of no row',
        );
        expect(
          _lines(stops[AdventureReason.sameLand]!, skillOf: (String _, TrophyLand _) => null)[2],
          'vo:welcome.land.counting',
          reason: 'a lesson with no skill of this land',
        );
        expect(
          _lines(const TodaysAdventure.lesson(TrophyLand.logic, null, AdventureReason.sameLand))[2],
          'vo:welcome.land.logic',
          reason: 'no lesson id',
        );
        expect(
          _lines(const TodaysAdventure.revisit(TrophyLand.market, 'MATH-Z-99'))[2],
          'vo:welcome.land.market',
          reason: 'a revisit of a skill no row names',
        );
      },
    );

    test('a skill the table sends to its land line (SHP-A-07) says the land line for a lesson, a revisit and a replay', () {
      String? solids(String _, TrophyLand _) => 'SHP-A-07';
      expect(
        _lines(
          const TodaysAdventure.lesson(TrophyLand.shapes, 'l', AdventureReason.sameLand),
          skillOf: solids,
        )[2],
        'vo:welcome.land.shapes',
      );
      expect(
        _lines(const TodaysAdventure.revisit(TrophyLand.shapes, 'SHP-A-07'))[2],
        'vo:welcome.land.shapes',
      );
      expect(
        _lines(const TodaysAdventure.replay(TrophyLand.shapes, 'l'), skillOf: solids)[2],
        'vo:welcome.land.shapes',
      );
    });

    test('the greeting turns with the day over a whole year, three each, and never the first-day line after day one', () {
      final Map<String, int> seen = <String, int>{};
      for (int day = 20000; day < 20366; day++) {
        final String g = _lines(stops[AdventureReason.sameLand]!, today: day, name: false).first;
        seen[g] = (seen[g] ?? 0) + 1;
      }
      expect(seen.keys.toSet(), welcomeHellos.toSet());
      expect(seen.values.every((int n) => n >= 121 && n <= 122), isTrue, reason: '$seen');
    });
  });

  group('no day, streak, absence or guilt word in the welcome, seen or heard', () {
    late Map<String, MasterRow> master;

    setUpAll(() {
      master = readMaster(File('../docs/review/hebrew-master.csv').readAsStringSync());
    });

    test(
      'the master table has a voice text for every welcome line, and the lines are the 48 of the table',
      () {
        expect(table.lineIds, hasLength(48));
        for (final String id in table.lineIds) {
          final MasterRow? row = master[masterKey(coreSource, _fileId(id))];
          expect(row, isNotNull, reason: '$id has no row in the master table');
          expect(row!.voiceText.trim(), isNotEmpty, reason: id);
        }
      },
    );

    test('what the child sees: no banned word in any of the 48 lines', () {
      final List<String> hits = <String>[];
      for (final String id in table.lineIds) {
        for (final String w in _words(table.text(id))) {
          if (_banned.contains(w)) hits.add('$id sees "$w"');
        }
      }
      expect(hits, isEmpty, reason: hits.join('\n'));
    });

    test('what the child hears (voice_text): no banned word, no digit, no "!" or "?", no placeholder', () {
      final List<String> hits = <String>[];
      for (final String id in table.lineIds) {
        final String spoken = master[masterKey(coreSource, _fileId(id))]!.voiceText;
        for (final String w in _words(spoken)) {
          if (_banned.contains(w)) hits.add('$id hears "$w"');
        }
        if (RegExp(r'[0-9!?{}\[\]<>]').hasMatch(spoken)) {
          hits.add('$id: a digit, !, ?, bracket or brace in "$spoken"');
        }
      }
      expect(hits, isEmpty, reason: hits.join('\n'));
    });

    test('no welcome line asks the child anything: no question mark on the screen, none heard, no question word first', () {
      const Set<String> questionFirst = <String>{'מה', 'מי', 'איפה', 'למה', 'איך', 'כמה', 'האם', 'מתי'};
      for (final String id in table.lineIds) {
        final String shown = table.text(id);
        expect(shown, isNot(contains('?')), reason: id);
        final List<String> w = _words(shown);
        expect(questionFirst.contains(w.first), isFalse, reason: '$id starts like a question: $shown');
      }
    });

    test('every greeting is genderless and in the plural or first person: no second person singular', () {
      // B42.md 2.6: "we" or "let\'s" in every line, so no line can guess the child\'s gender. The unpointed singular "you"
      // forms and the greeting words that take a gender are not allowed.
      const Set<String> singular = <String>{
        'אתה',
        'שלך',
        'שלךָ',
        'ילד',
        'ילדה',
        'חבר',
        'חברה',
        'גיבור',
        'גיבורה',
      };
      for (final String id in table.lineIds) {
        for (final String w in _words(table.text(id))) {
          expect(singular.contains(w), isFalse, reason: '$id: "$w" guesses a gender');
        }
      }
    });
  });

  group('any tap stops the welcome, and the day stays used (B42.md 2.4)', () {
    testWidgets('a tap on the open sea', (WidgetTester tester) async {
      final AppRig rig = AppRig(welcome: true);
      await rig.seedFinishedSetup();
      await _toMap(tester, rig, 'נועה');
      await _start(tester);
      expect(_isOwn(tester), isFalse, reason: 'the welcome is on');
      await tester.tapAt(const Offset(3, 3));
      await tester.pump();
      expect(_isOwn(tester), isTrue, reason: 'one tap anywhere and the bubble is its own again');
      await tester.pump(const Duration(seconds: 12));
      expect(_isOwn(tester), isTrue, reason: 'it does not come back');
      expect(await rig.db.welcomeDayOf('p-1'), isNotNull);
    });

    testWidgets('a tap on the parents button stops it, and the parent gate comes', (
      WidgetTester tester,
    ) async {
      final AppRig rig = AppRig(welcome: true);
      await rig.seedFinishedSetup();
      await _toMap(tester, rig, 'נועה');
      await _start(tester);
      expect(_isOwn(tester), isFalse);
      await tester.tap(find.text('הורים'));
      await tester.pump();
      expect(_isOwn(tester), isTrue);
      expect(await rig.db.welcomeDayOf('p-1'), isNotNull);
    });

    testWidgets('a tap on the pill stops it and the bottle opens as it always does', (
      WidgetTester tester,
    ) async {
      final AppRig rig = AppRig(welcome: true);
      await rig.seedFinishedSetup();
      await _toMap(tester, rig, 'נועה');
      await _start(tester);
      expect(_isOwn(tester), isFalse);
      await tester.tap(find.byKey(const Key('home-pill')));
      await tester.pump();
      expect(_isOwn(tester), isTrue, reason: 'the tap stopped it; the bottle opens as it always does');
      await tester.pump(const Duration(milliseconds: 600));
      expect(await rig.db.welcomeDayOf('p-1'), isNotNull, reason: 'the day stays used');
    });

    testWidgets(
      'a change of child in the middle: the first child\'s day stays used and the other child gets their own welcome',
      (WidgetTester tester) async {
        final AppRig rig = AppRig(welcome: true);
        await rig.seedFinishedSetup();
        await rig.db.addProfile(
          ProfilesCompanion.insert(
            id: 'p-2',
            name: 'דני',
            avatar: 'avatar-noa',
            addressForm: 'm',
            ageBand: 1,
            createdAt: DateTime.utc(2026, 10, 27),
          ),
        );
        await _toMap(tester, rig, 'נועה');
        await _start(tester);
        expect(_isOwn(tester), isFalse, reason: 'p-1 is being welcomed');
        await tester.tap(find.bySemanticsLabel(He.switchChildSemantics.text));
        await tester.pumpAndSettle();
        expect(
          await rig.db.welcomeDayOf('p-1'),
          isNotNull,
          reason: 'the day of the first child was written when it began',
        );
        expect(await rig.db.welcomeDayOf('p-2'), isNull);
        await tester.tap(find.text('דני'));
        await tester.pump();
        await _start(tester);
        expect(_isOwn(tester), isFalse, reason: 'the other child has not had theirs');
        expect(_bubble(tester), startsWith('דני,'));
        expect(await rig.db.welcomeDayOf('p-2'), isNotNull);
        // And back to the first child: nothing again today.
        await tester.tap(find.bySemanticsLabel(He.switchChildSemantics.text));
        await tester.pumpAndSettle();
        await tester.tap(find.text('נועה'));
        await tester.pump();
        await _start(tester);
        expect(_isOwn(tester), isTrue);
      },
    );
  });
}
