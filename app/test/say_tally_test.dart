// The pure part of the PC evaluation of a language's say-it: labels, speakers and age bands, and the counting per band for the
// release gate. Fake readings; no recogniser.
//
// The last group is local: with NITZNUTZ_MODELS set to a folder that holds `asr-eng`, `asr-rus` and `asr-heb` (the folders
// `tools/make-asr-models.ps1` fills), it checks the pinned sizes and SHA-256 of `model_spec.dart` against the real files. It is
// skipped everywhere else (CI has no models).
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/speech/model_spec.dart';
import 'package:nitznutz/speech/release_gate.dart';
import 'package:nitznutz/speech/say_tally.dart';
import 'package:nitznutz/speech/word_matcher.dart';

const String labelsCsv = '''
# a comment
file,said,forms,foils
dana_cat_1.wav,cat,cat|a cat,cut|hat
dana_cat_2.wav,cut,cat|a cat,cut|hat
dana_noise_1.wav,,cat|a cat,cut|hat
ben_cat_1.wav,cat,cat|a cat,cut|hat
''';

void main() {
  group('labels and speakers', () {
    test('a label has the word said, the forms and the foils; the speaker is the start of the file name', () {
      final List<SayLabel> l = parseSayLabels(labelsCsv);
      expect(l.length, 4);
      expect(l.first.said, 'cat');
      expect(l.first.forms, <String>['cat', 'a cat']);
      expect(l.first.foils, <String>['cut', 'hat']);
      expect(l.first.speaker, 'dana');
      expect(l[2].said, isEmpty);
    });

    test('a line with the wrong number of columns is refused, with the line', () {
      expect(() => parseSayLabels('a.wav,cat,cat'), throwsA(isA<FormatException>()));
    });

    test('ages become the bands of the gate; a speaker that is not listed is an adult', () {
      expect(
        <String>[
          bandOfAge(3),
          bandOfAge(4),
          bandOfAge(5),
          bandOfAge(6),
          bandOfAge(7),
          bandOfAge(8),
          bandOfAge(35),
        ],
        <String>['A', 'A', 'B', 'B', 'C', 'C', 'adult'],
      );
      final Map<String, String> s = parseSpeakers('speaker,age\ndana,5\nben,7\n');
      expect(s, <String, String>{'dana': 'B', 'ben': 'C'});
      expect(() => parseSpeakers('dana,five'), throwsA(isA<FormatException>()));
    });
  });

  group('counting', () {
    test(
      'a correct reading is the word said being a form of the target; a foil or nothing said is a negative',
      () {
        final SayTally t = SayTally(course: 'eng', bands: parseSpeakers('dana,5\nben,7'));
        final List<SayLabel> l = parseSayLabels(labelsCsv);
        expect(t.add(l[0], <String>['CAT']), SayResult.confident);
        expect(t.add(l[1], <String>['cut']), SayResult.unsure);
        expect(t.add(l[2], <String>['']), SayResult.silence);
        expect(t.add(l[3], <String>['kitten']), SayResult.unsure);
        expect(t.byBand['B']!.correctReadings, 1);
        expect(t.byBand['B']!.correctConfident, 1);
        expect(t.byBand['B']!.negativeReadings, 2);
        expect(t.byBand['B']!.negativeConfident, 0);
        expect(<int>[t.byBand['C']!.correctReadings, t.byBand['C']!.correctConfident], <int>[1, 0]);
        expect(t.unsureCorrect, 1);
        expect(t.confidentFoils, isEmpty);
      },
    );

    test('a foil read as the target is counted and named', () {
      final SayTally t = SayTally(course: 'eng');
      final SayLabel foil = parseSayLabels(labelsCsv)[1];
      // The recogniser misread a clear "cut" as "cat": the one error the gate is about.
      expect(t.add(foil, <String>['cat']), SayResult.confident);
      expect(t.confidentFoils, <String>['dana_cat_2.wav']);
      expect(t.total.negativeConfident, 1);
    });

    test('Russian: yo and ye are one letter, and a stress mark is no letter', () {
      final SayTally t = SayTally(course: 'rus');
      final SayLabel l = parseSayLabels('a_yozh_1.wav,еж,ёж,уж').single;
      expect(l.isCorrectReading('rus'), isTrue);
      expect(t.add(l, <String>['еж']), SayResult.confident);
    });

    test('the totals feed the gate', () {
      final SayTally t = SayTally(course: 'eng');
      for (final SayLabel l in parseSayLabels(labelsCsv)) {
        t.add(l, <String>[l.said]);
      }
      expect(releaseGate(t.total).verdict, GateVerdict.notEnough);
    });
  });

  group('local: the pinned files are the real ones', () {
    final String? root = Platform.environment['NITZNUTZ_MODELS'];
    for (final (String folder, SpeechModelSpec spec) in <(String, SpeechModelSpec)>[
      ('asr-heb', SpeechModels.hebrew),
      ('asr-eng', SpeechModels.english),
      ('asr-rus', SpeechModels.russian),
    ]) {
      test('${spec.id} in $folder matches its sizes and SHA-256', () {
        final Directory dir = Directory('$root${Platform.pathSeparator}$folder');
        if (!dir.existsSync()) markTestSkipped('$folder is not there');
        expect(spec.verifySync(dir), isEmpty);
      }, skip: root == null ? 'NITZNUTZ_MODELS is not set (no models in CI)' : null);
    }
  });
}
