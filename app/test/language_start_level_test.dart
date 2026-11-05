// "We start here: level N" on the parent's progress page (L-course, part 4): the placement strands of each course (`o`, `l`, `c`, `1` to `5`)
// mapped to the progress strands, per the frame and each syllabus, and the level read from what the staircase found.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/app/language_providers.dart' show languageCourseOf;
import 'package:nitznutz/data/app_database.dart';
import 'package:nitznutz/parent/language_progress.dart';
import 'package:nitznutz/parent/language_settings.dart';
import 'package:nitznutz/strings/he.dart';
import 'package:nitznutz/world/adventure_adapter.dart';
import 'package:nitznutz/world/language_placement.dart';
import 'package:nitznutz/world/placement.dart' show placementIdFor;

import 'support/course_history.dart';
import 'support/course_packs.dart';

final DateTime _then = DateTime.utc(2026, 11, 3, 9);

/// The progress of [course] for a child whose placement answers are [answers] (item, right).
LanguageProgress _progress(String course, List<(String, bool)> answers) {
  final pack = courseContent(course);
  final LanguageCourse c = languageCourseOf(
    pack,
    <Attempt>[
      for (final (int i, (String, bool) a) in answers.indexed)
        attemptRow(
          pack,
          a.$1,
          result: a.$2 ? 'correct' : 'incorrect',
          lessonId: placementIdFor(course),
          at: _then.add(Duration(minutes: i)),
          id: i + 1,
        ),
    ],
    const LanguageSwitches(on: true),
    0,
  );
  return buildLanguageProgress(
    content: pack,
    engine: c.engine,
    now: _then.add(const Duration(days: 1)),
    switches: const LanguageSwitches(on: true),
    ageBand: 0,
    placement: c.placement,
  );
}

int? _level(LanguageProgress p, Str name) =>
    p.strands.firstWhere((StrandProgress s) => s.name == name).startLevel;

void main() {
  group('the map from placement strands to progress strands', () {
    test('every code of one progress strand names the same placement strand, so a strand has one level', () {
      for (final MapEntry<String, List<(Str, Set<String>)>> course in languageStrands.entries) {
        final Map<String, String> map = placementStrandOfCode[course.key]!;
        for (final (Str name, Set<String> codes) in course.value) {
          final Set<String?> placed = <String?>{for (final String c in codes) map[c]};
          expect(placed.length, 1, reason: '${course.key} ${name.text}: $placed');
        }
      }
    });

    test('only English writing has no placement strand: no probe asks it, so it shows no level', () {
      final Set<String> unplaced = <String>{
        for (final MapEntry<String, List<(Str, Set<String>)>> course in languageStrands.entries)
          for (final (Str, Set<String>) s in course.value)
            for (final String code in s.$2)
              if (!placementStrandOfCode[course.key]!.containsKey(code)) '${course.key}.$code',
      };
      expect(unplaced, <String>{'eng.wr'});
    });

    test(
      'the placement strands are those of the syllabi: English o and l, Hebrew l and c, Russian 1 to 5',
      () {
        expect(<String>{...placementStrandOfCode['eng']!.values}, <String>{'o', 'l'});
        expect(<String>{...placementStrandOfCode['heb']!.values}, <String>{'l', 'c'});
        expect(<String>{...placementStrandOfCode['rus']!.values}, <String>{'1', '2', '3', '4', '5'});
        final String eng = File('../docs/languages/english/syllabus.md').readAsStringSync();
        final String heb = File('../docs/languages/hebrew/syllabus.md').readAsStringSync();
        final String rus = File('../docs/languages/russian/syllabus.md').readAsStringSync();
        expect(eng, contains('**O, oral**'));
        expect(eng, contains('**L, literacy**'));
        expect(heb, contains('**L** = oral language and phonological awareness, **C** = the code'));
        for (final String n in <String>[
          '1. Understanding',
          '2. Sounds',
          '3. Letters',
          '4. Reading',
          '5. Spelling',
        ]) {
          expect(rus, contains(n));
        }
      },
    );

    test('the fixture packs\' placement strands are all placed by the map', () {
      for (final String course in <String>['eng', 'heb', 'rus']) {
        final Set<String> mapped = <String>{...placementStrandOfCode[course]!.values};
        for (final s in courseContent(course).placement!.strands) {
          expect(mapped, contains(s.id), reason: '$course ${s.id}');
        }
      }
    });
  });

  group('the level on the page', () {
    test('no placement yet: no level on any strand', () {
      final LanguageProgress p = _progress('eng', const <(String, bool)>[]);
      expect(p.strands.every((StrandProgress s) => s.startLevel == null), isTrue);
    });

    test(
      'English: the whole oral ladder right places the child at level 3, "we start here" counted from 1',
      () {
        final LanguageProgress p = _progress('eng', const <(String, bool)>[
          ('pr_hello_1', true),
          ('pr_hello_2', true),
          ('pr_col_1', true),
          ('pr_col_2', true),
          ('pr_ani_1', true),
          ('pr_ani_2', true),
          ('pr_body_1', true),
          ('pr_body_2', true),
        ]);
        expect(_level(p, He.langStrandEngLisSpk), 3);
      },
    );

    test('a beginner who misses the first two probes starts at level 1', () {
      final LanguageProgress p = _progress('eng', const <(String, bool)>[
        ('pr_hello_1', false),
        ('pr_hello_2', false),
      ]);
      expect(_level(p, He.langStrandEngLisSpk), 1);
    });

    test('a strand that has not stopped shows nothing, and Hebrew\'s two strands are placed apart', () {
      final LanguageProgress p = _progress('heb', const <(String, bool)>[
        ('pr_w_1', true),
        ('pr_w_2', true),
        ('pr_r_1', true),
        ('pr_r_2', true),
        ('pr_l_1', true),
      ]);
      expect(_level(p, He.langStrandHebOral), 1, reason: 'the oral strand has topped out');
      expect(_level(p, He.langStrandHebCode), isNull, reason: 'the code strand has had one probe');
    });

    test('Russian: the strands are placed one by one', () {
      final LanguageProgress p = _progress('rus', const <(String, bool)>[
        ('pr_a_1', true),
        ('pr_a_2', true),
        ('pr_c_1', true),
        ('pr_c_2', true),
        ('pr_s_1', false),
        ('pr_s_2', false),
      ]);
      expect(_level(p, He.langStrandRusUnderstand), 1);
      expect(
        _level(p, He.langStrandRusSounds),
        1,
        reason: 'two misses at the floor stop that strand at once',
      );
    });
  });
}
