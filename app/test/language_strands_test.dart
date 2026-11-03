// The parent's progress page groups skills by strand. A strand code the table does not know falls under "more topics", so
// every code the three syllabi use must be in the table (the lowercase codes of frame §4.1).
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/engine/course.dart';
import 'package:nitznutz/parent/language_progress.dart';
import 'package:nitznutz/strings/he.dart';

/// The strand codes in the skill tables of one syllabus: the second cell of every `| ENG-A-01 | LIS | ...` row, with a
/// two-part strand (`GRM/NUM`) giving both parts. Lowercase, as the pack's `strand` field has them.
Set<String> syllabusStrands(String course, String prefix) {
  final List<String> lines = File('../docs/languages/$course/syllabus.md').readAsLinesSync();
  final RegExp row = RegExp(r'^\| ' + prefix + r'-[A-C]-\d+\S* \| ([A-Z]+(?:/[A-Z]+)*) \|');
  return <String>{
    for (final String l in lines)
      if (row.firstMatch(l) case final RegExpMatch m) ...m.group(1)!.toLowerCase().split('/'),
  };
}

Set<String> tableCodes(String course) => <String>{
  for (final (Str, Set<String>) s in languageStrands[course]!) ...s.$2,
};

void main() {
  group('every strand code of a syllabus has a named strand', () {
    const Map<String, String> prefixes = <String, String>{
      Course.eng: 'ENG',
      Course.heb: 'HEB',
      Course.rus: 'RUS',
    };
    const Map<String, String> folders = <String, String>{
      Course.eng: 'english',
      Course.heb: 'hebrew',
      Course.rus: 'russian',
    };
    for (final String course in <String>[Course.eng, Course.heb, Course.rus]) {
      test(course, () {
        final Set<String> used = syllabusStrands(folders[course]!, prefixes[course]!);
        expect(used, isNotEmpty, reason: 'the syllabus table was found');
        expect(
          used.difference(tableCodes(course)),
          isEmpty,
          reason: 'a code with no strand would land under "more topics"',
        );
      });
    }

    test('the codes the frame lists (§4.1) are the ones read from the syllabi', () {
      expect(syllabusStrands('english', 'ENG'), <String>{'lis', 'spk', 'pa', 'ph', 'rd', 'wr'});
      expect(syllabusStrands('hebrew', 'HEB'), <String>{'ol', 'pa', 'pk', 'dec', 'wr'});
      expect(syllabusStrands('russian', 'RUS'), <String>{
        'lis',
        'spk',
        'voc',
        'grm',
        'num',
        'pho',
        'let',
        'rea',
        'wri',
      });
    });
  });

  group('the table', () {
    test('a code belongs to one strand only', () {
      for (final String course in languageStrands.keys) {
        final List<String> all = <String>[
          for (final (Str, Set<String>) s in languageStrands[course]!) ...s.$2,
        ];
        expect(all.toSet().length, all.length, reason: course);
      }
    });

    test('Hebrew oral language and sounds are one strand; letters, reading and writing the other', () {
      final Map<String, Str> byCode = <String, Str>{
        for (final (Str, Set<String>) s in languageStrands[Course.heb]!)
          for (final String c in s.$2) c: s.$1,
      };
      expect(byCode['ol'], He.langStrandHebOral);
      expect(byCode['pa'], He.langStrandHebOral);
      for (final String c in <String>['pk', 'dec', 'wr']) {
        expect(byCode[c], He.langStrandHebCode, reason: c);
      }
    });

    test('Russian listening, speaking, words, grammar and numbers are one strand', () {
      final Map<String, Str> byCode = <String, Str>{
        for (final (Str, Set<String>) s in languageStrands[Course.rus]!)
          for (final String c in s.$2) c: s.$1,
      };
      for (final String c in <String>['lis', 'spk', 'voc', 'grm', 'num']) {
        expect(byCode[c], He.langStrandRusUnderstand, reason: c);
      }
    });
  });
}
