// QA of milestone L1 (docs/qa/l1-languages-verification.md): proofs that the builder's tests do not give, written against the
// teachers' real Band A material and the plan's text. Everything here passes on the branch as built; the open defects are in
// qa_l1_open_defects_test.dart.
//
//   - the real word lists of the three Band A batches (their pronunciation tables) through the F5 script rules;
//   - the look-alike rule swept over every real word, both ways;
//   - the decodable rule on the real Russian syllables and the real Hebrew letters, against an independent oracle;
//   - the two-choice rule of frame section 2.3 on the shape of ENG-A-16 (6 thumbs items in balanced pairs, 6 three-choice);
//   - the caption policy as the lesson screen wires it (route and presentation band from the child's settings);
//   - the guide's bubble with a word in its chip, on the four boards, with the longest line.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/child/activity_shell.dart';
import 'package:nitznutz/content/models.dart';
import 'package:nitznutz/content/pack_validation.dart';
import 'package:nitznutz/content/schema.dart';
import 'package:nitznutz/content/scripts.dart';
import 'package:nitznutz/design/board.dart' show boardClassFor;
import 'package:nitznutz/design/token_types.dart' show Band;
import 'package:nitznutz/parent/language_settings.dart';
import 'package:nitznutz/play/activity_frame.dart';
import 'package:nitznutz/play/lesson_screen.dart';

import 'support/app_harness.dart';
import 'support/harness.dart';
import 'support/language_content.dart';
import 'support/language_screens.dart' show langKid;
import 'support/language_voice.dart';
import 'support/sample_pack.dart';
import 'support/voice_fixtures.dart';

const Map<String, Size> boards = <String, Size>{
  'phone': Size(852, 393),
  'phoneSE': Size(667, 375),
  'tabletLandscape': Size(1180, 820),
  'tabletPortrait': Size(820, 1180),
};

List<Problem> _run(SamplePack p) => validatePack(manifest: p.manifest, docs: p.docs, files: p.files);

String _cp(int r) => String.fromCharCode(r);

// ---- the teachers' tables ----

/// The rows of a teacher's pronunciation table: id and the text as the child sees it (the `shown` column).
List<({String id, String shown})> _table(String course) {
  final String dir = <String, String>{'eng': 'english', 'rus': 'russian', 'heb': 'hebrew'}[course]!;
  final List<String> lines = File('../docs/languages/$dir/pronunciation.csv').readAsLinesSync();
  final List<({String id, String shown})> out = <({String id, String shown})>[];
  for (final String l in lines.skip(1)) {
    final List<String> f = _csv(l);
    if (f.length > 1 && f[1].isNotEmpty) out.add((id: f[0], shown: f[1]));
  }
  return out;
}

List<String> _csv(String line) {
  final List<String> out = <String>[];
  final StringBuffer b = StringBuffer();
  bool quoted = false;
  for (int i = 0; i < line.length; i++) {
    final String c = line[i];
    if (quoted) {
      if (c == '"' && i + 1 < line.length && line[i + 1] == '"') {
        b.write('"');
        i++;
      } else if (c == '"') {
        quoted = false;
      } else {
        b.write(c);
      }
    } else if (c == '"') {
      quoted = true;
    } else if (c == ',') {
      out.add(b.toString());
      b.clear();
    } else {
      b.write(c);
    }
  }
  out.add(b.toString());
  return out;
}

/// Characters that mark a row of the table as something other than a tile's text: a sound in brackets, a placeholder, a verse with
/// its line break, a gap, a dash or a quotation (the story and rhyme faces of later milestones).
final RegExp _notATile = RegExp('[\\[\\]{}/${_cp(0x2026)}${_cp(0x2014)}"]');

// ---- fixtures ----

Map<String, Object?> _textItem(
  LangPack p,
  String id,
  List<String> words, {
  String? skill,
  String purpose = 'learn',
  Map<String, Object?> answer = const <String, Object?>{},
}) => tapJson(
  course: p.course,
  id: id,
  skill: skill,
  purpose: purpose,
  options: <Map<String, Object?>>[
    for (final (int i, String w) in words.indexed)
      textOption('o${i + 1}', w, tag: i == 0 ? null : p.tag(i.isOdd ? 'lis.sem' : 'lis.guess')),
  ],
  correct: 'o1',
  // An item of one-letter options says it is a letter item, and one of syllables or words that it is words.
  answer: <String, Object?>{
    'face': words.every((String w) => w.runes.length == 1) ? 'letter' : 'word',
    ...answer,
  },
);

void _skill(LangPack p, String id, Map<String, Object?> fields) {
  p.pack.addDocument('skill.$id.json', 'skills', id, <String, Object?>{
    ...p.pack.doc('skill.${p.skill}.json'),
    'id': id,
    'prerequisites': <Object?>[],
    ...fields,
  });
}

Matcher _refused(String path, String message) => predicate<List<Problem>>(
  (List<Problem> ps) => ps.any((Problem x) => x.path == path && x.message.contains(message)),
  'refuses "$path": $message',
);

void main() {
  setUpAll(loadAppFonts);

  group('the real word lists of the Band A batches through the F5 script rules', () {
    test('English: every word and phrase of the pronunciation table is clean English', () {
      final List<({String id, String shown})> rows = _table('eng');
      expect(rows.length, greaterThan(200));
      for (final ({String id, String shown}) r in rows) {
        expect(textProblems('eng', r.shown), isEmpty, reason: '${r.id} "${r.shown}"');
      }
    });

    test(
      'Russian: every word of the table is clean Russian, its stress marks after vowels and none after yo',
      () {
        final List<({String id, String shown})> rows = _table('rus')
            .where((({String id, String shown}) r) => !_notATile.hasMatch(r.shown))
            .toList();
        expect(rows.length, greaterThan(200));
        for (final ({String id, String shown}) r in rows) {
          expect(textProblems('rus', r.shown), isEmpty, reason: '${r.id} "${r.shown}"');
        }
      },
    );

    test('Russian: every word of the batch itself, stress marks included, passes', () {
      final String text = File('../docs/languages/russian/band-a-content.md').readAsStringSync();
      final RegExp run = RegExp('[${_cp(0x400)}-${_cp(0x4FF)}${_cp(0x301)}]+');
      int marked = 0, words = 0;
      for (final RegExpMatch m in run.allMatches(text)) {
        final String w = m.group(0)!;
        words++;
        if (w.contains(_cp(0x301))) marked++;
        expect(textProblems('rus', w), isEmpty, reason: '"$w" in the Russian batch');
      }
      expect(words, greaterThan(1000));
      expect(marked, greaterThan(100), reason: 'the batch marks the stress of its words, so the rule ran');
    });

    test('Hebrew: every word of the table is Hebrew letters and nikud, and pointed (Band A)', () {
      final List<({String id, String shown})> rows = _table('heb')
          .where((({String id, String shown}) r) => !_notATile.hasMatch(r.shown))
          .toList();
      expect(rows.length, greaterThan(200));
      for (final ({String id, String shown}) r in rows) {
        expect(textProblems('heb', r.shown), isEmpty, reason: '${r.id} "${r.shown}"');
        expect(unpointedHebrewWords(r.shown), isEmpty, reason: '${r.id} "${r.shown}"');
      }
    });

    test('what the tables hold that is not a tile (sounds, placeholders, verses, gaps) is only that', () {
      for (final String c in <String>['rus', 'heb']) {
        for (final ({String id, String shown}) r in _table(c).where((r) => _notATile.hasMatch(r.shown))) {
          // A bracket, a brace, a slash, an ellipsis, a dash or a quote is how the teacher marks a sound, a slot, a verse break,
          // a gap or speech; these rows are for the story and rhyme faces (LS08, LS04), not for an LS01 tile.
          expect(
            r.id,
            matches(
              RegExp(
                r'^(snd-|ch-|rh\d|heb-a-u-|heb-a-ok-|heb-a-try-|heb-a-why|heb-a-v\d-open|heb-a-s\d-p\d)',
              ),
            ),
            reason: '${r.id} "${r.shown}" is not a row of a known non-tile kind',
          );
        }
      }
    });

    test('a word of one course is refused by another: no list is clean in the wrong script', () {
      expect(textProblems('rus', 'cat'), isNotEmpty);
      expect(textProblems('heb', 'cat'), isNotEmpty);
      expect(textProblems('eng', 'кот'), isNotEmpty);
      expect(textProblems('heb', 'кот'), isNotEmpty);
      expect(textProblems('eng', 'כֶּלֶב'), isNotEmpty);
      expect(textProblems('rus', 'כֶּלֶב'), isNotEmpty);
    });
  });

  group('look-alike letters, swept over the real words, both ways', () {
    // The Latin letter and the Cyrillic one that is drawn the same, in lower case.
    const Map<String, int> twin = <String, int>{
      'a': 0x430,
      'e': 0x435,
      'o': 0x43E,
      'p': 0x440,
      'c': 0x441,
      'y': 0x443,
      'x': 0x445,
    };

    test('every English word with a look-alike letter is refused when that letter is swapped for its Cyrillic twin', () {
      int swaps = 0;
      for (final ({String id, String shown}) r in _table('eng')) {
        if (r.shown.contains(' ')) continue;
        for (int i = 0; i < r.shown.length; i++) {
          final int? cyr = twin[r.shown[i]];
          if (cyr == null) continue;
          final String bad = r.shown.replaceRange(i, i + 1, _cp(cyr));
          swaps++;
          final List<String> p = textProblems('eng', bad);
          expect(p, isNotEmpty, reason: '${r.id} "$bad" has a Cyrillic ${_cp(cyr)}');
          expect(p.join(' '), contains('looks like the Latin "${r.shown[i]}"'), reason: bad);
        }
      }
      expect(swaps, greaterThan(150));
    });

    test(
      'every Russian word with a look-alike letter is refused when that letter is swapped for its Latin twin',
      () {
        int swaps = 0;
        final Map<int, String> back = <int, String>{
          for (final MapEntry<String, int> e in twin.entries) e.value: e.key,
        };
        for (final ({String id, String shown}) r in _table(
          'rus',
        ).where((r) => !_notATile.hasMatch(r.shown))) {
          if (r.shown.contains(' ')) continue;
          final List<int> runes = r.shown.runes.toList();
          for (int i = 0; i < runes.length; i++) {
            final String? latin = back[runes[i]];
            if (latin == null) continue;
            final String bad = <int>[
              ...runes.sublist(0, i),
              latin.codeUnitAt(0),
              ...runes.sublist(i + 1),
            ].map(String.fromCharCode).join();
            swaps++;
            final List<String> p = textProblems('rus', bad);
            expect(p, isNotEmpty, reason: '${r.id} "$bad" has a Latin $latin');
            expect(p.join(' '), contains('looks like the Cyrillic "${_cp(runes[i])}"'), reason: bad);
          }
        }
        expect(swaps, greaterThan(100));
      },
    );
  });

  group('decodable words against an oracle, on the real material', () {
    test(
      'Russian syllables: with the letters м а л н о taught, exactly the syllables made of them are readable',
      () {
        final Set<int> taught = <int>{0x43C, 0x430, 0x43B, 0x43D, 0x43E};
        final List<({String id, String shown})> syl = _table('rus')
            .where((r) => r.id.startsWith('syl-'))
            .toList();
        expect(syl.length, greaterThan(10));
        int readable = 0, unreadable = 0;
        for (final ({String id, String shown}) s in syl) {
          final String plain = plainWord(s.shown);
          final bool oracle = plain.runes.every(taught.contains);
          final LangPack q = LangPack('rus');
          _skill(q, 'RUS-A-05', <String, Object?>{
            'letters': true,
            'graphemes': <Object?>[for (final int r in taught) _cp(r)],
          });
          q.add(_textItem(q, 'syl', <String>[s.shown, 'ан', 'ал'], skill: 'RUS-A-05'));
          final List<Problem> problems = _run(q.pack);
          if (oracle) {
            expect(problems, isEmpty, reason: '${s.id} "${s.shown}" is made of taught letters');
            readable++;
          } else {
            expect(
              problems,
              _refused('activity.rus.syl.json › answer.options[0].text', 'cannot be read yet at RUS-A-05'),
              reason: '${s.id} "${s.shown}" has a letter nobody taught',
            );
            unreadable++;
          }
        }
        expect(readable, greaterThan(2));
        expect(unreadable, greaterThan(2));
      },
    );

    test('Hebrew letters of HEB-A-10 are the letters taught; a numeral card is not a letter', () {
      final LangPack p = LangPack('heb');
      _skill(p, 'HEB-A-10', <String, Object?>{
        'letters': true,
        'graphemes': <Object?>[
          for (final int r in <int>[0x5D1, 0x5E8, 0x5EA, 0x5E9, 0x5DE, 0x5DC]) _cp(r),
        ],
      });
      p.add(_textItem(p, 'let', <String>[_cp(0x5D1), _cp(0x5E8), _cp(0x5EA)], skill: 'HEB-A-10'));
      expect(_run(p.pack), isEmpty);
      p.replace('let', _textItem(p, 'let', <String>[_cp(0x5D1), _cp(0x5E8), _cp(0x5E7)], skill: 'HEB-A-10'));
      expect(
        _run(p.pack),
        _refused('activity.heb.let.json › answer.options[2].text', 'cannot be read yet at HEB-A-10'),
      );
    });
  });

  group('the two-choice rule (frame 2.3) on the shape of ENG-A-16', () {
    // ENG-A-16 "Is it a ___?": six thumbs items of two choices (3 yes, 3 no; i05 and i06 are the balanced pair that is the
    // understanding check) and six three-choice items (g01 to g06, g06 a check). Exactly half of the 12 have two choices.
    LangPack eng16() {
      final LangPack p = LangPack();
      _skill(p, 'ENG-A-16', <String, Object?>{'binary': true});
      const List<String> w = <String>['cat', 'dog', 'duck', 'car', 'ball', 'kite'];
      void thumbs(String id, String pole, {String purpose = 'learn', String? pair}) {
        p.add(
          tapJson(
            id: id,
            skill: 'ENG-A-16',
            purpose: purpose,
            options: <Map<String, Object?>>[
              textOption('o1', pole == 'yes' ? 'yes' : 'no'),
              textOption('o2', pole == 'yes' ? 'no' : 'yes', tag: p.tag('lis.sem')),
            ],
            correct: 'o1',
            answer: <String, Object?>{'pole': pole, 'pairWith': ?pair},
          ),
        );
      }

      thumbs('t01', 'yes');
      thumbs('t02', 'no');
      thumbs('t03', 'yes');
      thumbs('t04', 'no');
      thumbs('t05', 'yes', purpose: 'check', pair: 'eng.t06');
      thumbs('t06', 'no', purpose: 'check', pair: 'eng.t05');
      for (int i = 0; i < 6; i++) {
        p.add(
          tapJson(
            id: 'g0${i + 1}',
            skill: 'ENG-A-16',
            purpose: i == 5 ? 'check' : 'learn',
            options: <Map<String, Object?>>[
              textOption('o1', w[i]),
              textOption('o2', w[(i + 1) % 6], tag: p.tag('lis.sem')),
              textOption('o3', w[(i + 2) % 6], tag: p.tag('lis.guess')),
            ],
            correct: 'o1',
          ),
        );
      }
      return p;
    }

    test('the batch as the teacher built it is valid', () {
      expect(_run(eng16().pack), isEmpty);
    });

    test('one more two-choice item tips it over half', () {
      final LangPack p = eng16();
      p.add(
        tapJson(
          id: 't07',
          skill: 'ENG-A-16',
          options: <Map<String, Object?>>[
            textOption('o1', 'yes'),
            textOption('o2', 'no', tag: p.tag('lis.sem')),
          ],
          correct: 'o1',
          answer: <String, Object?>{'pole': 'yes'},
        ),
      );
      p.add(
        tapJson(
          id: 't08',
          skill: 'ENG-A-16',
          options: <Map<String, Object?>>[
            textOption('o1', 'no'),
            textOption('o2', 'yes', tag: p.tag('lis.sem')),
          ],
          correct: 'o1',
          answer: <String, Object?>{'pole': 'no'},
        ),
      );
      expect(
        _run(p.pack),
        _refused('skill.ENG-A-16.json', '8 of its 14 scored items have two choices; at most half may'),
      );
    });

    test('three yes and two no is not balanced, the pair or not', () {
      final LangPack p = eng16();
      // Take away one "no" item and its place in the half: replace t04 by a three-choice item so only the balance is wrong.
      p.replace(
        't04',
        tapJson(
          id: 't04',
          skill: 'ENG-A-16',
          options: <Map<String, Object?>>[
            textOption('o1', 'cat'),
            textOption('o2', 'dog', tag: p.tag('lis.sem')),
            textOption('o3', 'duck', tag: p.tag('lis.guess')),
          ],
          correct: 'o1',
        ),
      );
      expect(_run(p.pack), _refused('skill.ENG-A-16.json', 'not balanced: 3 yes, 2 no'));
    });

    test('the pair must be served as a pair: an understanding check on one thumbs item alone is refused', () {
      final LangPack p = eng16();
      (p.activity('t05')['answer']! as Map<String, Object?>).remove('pairWith');
      expect(_run(p.pack), _refused('activity.eng.t05.json › answer.pairWith', 'never alone'));
    });

    test('a thumbs item that shows no side is refused, so the balance cannot be gamed by leaving it out', () {
      final LangPack p = eng16();
      (p.activity('t01')['answer']! as Map<String, Object?>).remove('pole');
      expect(_run(p.pack), _refused('activity.eng.t01.json › answer.pole', 'says which side it is'));
    });
  });

  group('the caption after the answer, as the lesson screen wires it', () {
    Set<String> refs(LangPack p) {
      final Set<String> out = <String>{};
      void scan(Object? n) {
        if (n is String && n.startsWith('vo:')) out.add(n);
        if (n is Map<String, Object?>) n.values.forEach(scan);
        if (n is List<Object?>) n.forEach(scan);
      }

      scan(p.pack.docs);
      return out;
    }

    LangPack revealed(String course) {
      final LangPack p = LangPack(course);
      p.add(
        tapJson(
          course: course,
          id: 'rev',
          options: <Map<String, Object?>>[
            pictureOption('o1', 'flower_red', reveal: 'ро${_cp(0x301)}за', clip: 'vo:$course.rev.a'),
            pictureOption('o2', 'flower_yellow', tag: p.tag('lis.sem'), clip: 'vo:$course.rev.b'),
            pictureOption('o3', 'butterfly', tag: p.tag('lis.guess'), clip: 'vo:$course.rev.c'),
          ],
          correct: 'o1',
        ),
      );
      return p;
    }

    /// Whether the word stands under the picture on the screen, for a child of [ageBand] with the course's [switches].
    Future<bool> shows(WidgetTester t, String course, int ageBand, LanguageSwitches switches) async {
      final LangPack p = revealed(course);
      final PackContent content = p.content;
      final AppRig rig = AppRig(
        content: content,
        characters: await languageVoiceSource(refs(p)),
        player: FakePlayer()..endsAfter = const Duration(milliseconds: 150),
      );
      await rig.seedFinishedSetup(name: 'נֹעָה', id: langKid, ageBand: ageBand);
      await rig.db.putSetting(
        languagesSettingKey,
        const FamilyLanguages().withSwitches(langKid, course, switches)!.encode(),
      );
      await rig.pump(t, size: boards['phone']!);
      await t.tap(find.text('נֹעָה'));
      await t.pumpAndSettle();
      final Activity a = content.activities['$course.rev']!;
      t
          .state<NavigatorState>(find.byType(Navigator).first)
          .push(
            MaterialPageRoute<void>(
              builder: (BuildContext c) => LessonScreen(
                profileId: langKid,
                mission: Lesson.mission(
                  id: 'shot',
                  itemIds: <String>[a.id],
                  skillIds: <String>[a.skillId],
                  celebration: const Spoken(vo: 'vo:x.celebrate', caption: 'x'),
                ),
              ),
            ),
          );
      await t.pump(const Duration(milliseconds: 600));
      for (int i = 0; i < 25; i++) {
        await t.pump(const Duration(milliseconds: 100));
      }
      final bool there = find.byKey(const Key('reveal-caption')).evaluate().isNotEmpty;
      await t.pumpWidget(const SizedBox());
      await t.pump(const Duration(seconds: 3));
      return there;
    }

    // One screen for each case: a screen that is built again in the same test leaves a second database open.
    for (final (String, String, int, LanguageSwitches, bool) c
        in <(String, String, int, LanguageSwitches, bool)>[
          (
            'Russian reader, age 3 to 4 (Band A presentation): no word',
            'rus',
            0,
            const LanguageSwitches(on: true, route: 'reader'),
            false,
          ),
          (
            'Russian reader, age 5 to 6 (Band B): the word',
            'rus',
            1,
            const LanguageSwitches(on: true, route: 'reader'),
            true,
          ),
          (
            'Russian reader, age 7 to 8 (Band C): the word',
            'rus',
            2,
            const LanguageSwitches(on: true, route: 'reader'),
            true,
          ),
          (
            'Russian reader, age 7 to 8, the parent set Band A presentation: no word',
            'rus',
            2,
            const LanguageSwitches(on: true, route: 'reader', band: 0),
            false,
          ),
          (
            'Russian, the new-learner route: no word',
            'rus',
            2,
            const LanguageSwitches(on: true, route: 'new'),
            false,
          ),
          (
            'Russian, the heritage route: no word',
            'rus',
            2,
            const LanguageSwitches(on: true, route: 'heritage'),
            false,
          ),
          ('Russian, no route chosen yet: no word', 'rus', 2, const LanguageSwitches(on: true), false),
          (
            'English, whatever the route: no word',
            'eng',
            2,
            const LanguageSwitches(on: true, route: 'reader'),
            false,
          ),
          ('English, Band B: no word', 'eng', 1, const LanguageSwitches(on: true), false),
        ]) {
      testWidgets(c.$1, (WidgetTester t) async {
        expect(await shows(t, c.$2, c.$3, c.$4), c.$5);
      });
    }
  });

  group('the guide\'s bubble with a word in its chip, on the four boards', () {
    // Every Hebrew frame line of the three Band A batches (their tables of lines), each with an English word in the chip.
    final Set<String> lines = <String>{};
    final RegExp pointed = RegExp('[${_cp(0x5B0)}-${_cp(0x5C7)}]');
    for (final String c in <String>['english', 'hebrew', 'russian']) {
      for (final String row in File('../docs/languages/$c/band-a-content.md').readAsLinesSync()) {
        if (!row.startsWith('|')) continue;
        final List<String> cells = row.split('|').map((String s) => s.trim()).toList();
        if (cells.length < 3) continue;
        for (final String part in cells[2].split(' / ')) {
          // A cell that lists several lines (the eight praise lines, separated by a middle dot) is not one line.
          if (pointed.hasMatch(part) &&
              !RegExp('[A-Za-z]').hasMatch(part) &&
              part.length > 3 &&
              !part.contains(' ${_cp(0xB7)} ')) {
            lines.add(part);
          }
        }
      }
    }
    final List<String> sorted = lines.toList()..sort();

    test('the Band A frame lines are found in the batches', () => expect(sorted.length, greaterThan(100)));

    for (final MapEntry<String, Size> b in boards.entries) {
      testWidgets('${b.key}: with a word in its chip every line keeps it in the bubble, above the tiles', (
        WidgetTester t,
      ) async {
        final ActivitySpec spec = ActivitySpec.of(boardClassFor(b.value));
        final List<String> bad = <String>[];
        for (final String line in sorted) {
          // A fresh screen for each line: a bubble that is reused animates from the size of the line before it.
          await t.pumpWidget(const SizedBox());
          await pumpScreen(
            t,
            ActivityFrame(
              bubbleText: line,
              bubbleTarget: (text: 'elephant', course: 'eng'),
              stage: (Size room) => const SizedBox.expand(),
              tiles: const SizedBox(height: 96),
              trailTotal: 3,
              trailDone: 1,
              onHome: () {},
            ),
            size: b.value,
            band: Band.a,
          );
          await t.pump(const Duration(seconds: 2));
          final Rect bubble = t.getRect(find.byKey(const Key('bubble-body')));
          final Rect chip = t.getRect(find.byKey(const Key('target-chip')));
          final bool inside =
              bubble.inflate(0.5).contains(chip.topLeft) && bubble.inflate(0.5).contains(chip.bottomRight);
          // The tightest lines (the nine-word prompts, on the phone SE) run 3 points under the tiles' top edge: the edge of the
          // chip's own border, nothing the child reads. More than 4 would hide the chip's word.
          if (t.takeException() != null ||
              !inside ||
              chip.bottom > spec.tilesTop + 4 ||
              bubble.bottom > spec.tilesTop + 12) {
            bad.add(
              'chip bottom ${chip.bottom.round()}, bubble bottom ${bubble.bottom.round()} of ${spec.tilesTop.round()}: $line',
            );
          }
        }
        expect(
          bad,
          isEmpty,
          reason: '${b.key}: ${bad.length} of ${sorted.length}: ${bad.take(6).join(' | ')}',
        );
      });
    }
  });
}
