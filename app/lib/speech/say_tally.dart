// The pure part of the PC evaluation of a language's say-it (`tool/say_eval.dart`, `tools/run-asr-eval.ps1`): the labels of the
// recordings, the speakers and their age bands, and the counting of confident and unsure readings per band for the release gate.
// No audio and no recogniser here: the tool hands this the text that the recogniser read.
import 'release_gate.dart';
import 'word_matcher.dart';
import 'word_text.dart';

/// One recording of the evaluation set: what was said, and what the activity on screen asked for.
class SayLabel {
  const SayLabel({required this.file, required this.said, required this.forms, required this.foils});

  final String file;

  /// The word actually said; empty when nothing on the screen was said (silence, room noise, a sibling, the guide's voice played
  /// back through the phone).
  final String said;

  /// The target and its listed forms.
  final List<String> forms;

  /// The other options of the screen.
  final List<String> foils;

  /// The speaker: the part of the file name before the first underscore (`dana_cat_1.wav` is `dana`), or `all`.
  String get speaker => file.contains('_') ? file.split('_').first : 'all';

  WordTarget targetOf(String course) => WordTarget(course: course, forms: forms, foils: foils);

  /// A reading that should come out confident: the word said is the target or one of its forms.
  bool isCorrectReading(String course) =>
      said.isNotEmpty &&
      forms.map((String f) => normalizeWords(course, f)).contains(normalizeWords(course, said));
}

/// `labels.csv`: `file,said,forms,foils`, with the forms and the foils separated by `|` (`dana_cat_1.wav,cat,cat|a cat,cut|hat`).
/// Lines that are empty or start with `#`, and the header, are skipped.
List<SayLabel> parseSayLabels(String csv) {
  final List<SayLabel> out = <SayLabel>[];
  for (final String raw in csv.split('\n')) {
    final String line = raw.replaceAll('\r', '').replaceAll('﻿', '').trim();
    if (line.isEmpty || line.startsWith('#') || line.startsWith('file,')) continue;
    final List<String> p = line.split(',');
    if (p.length != 4) throw FormatException('labels.csv: expected file,said,forms,foils in "$line"');
    out.add(SayLabel(file: p[0].trim(), said: p[1].trim(), forms: _words(p[2]), foils: _words(p[3])));
  }
  return out;
}

List<String> _words(String s) => <String>[
  for (final String w in s.split('|'))
    if (w.trim().isNotEmpty) w.trim(),
];

/// The age band of a child: A 3 to 4, B 5 to 6, C 7 to 8 (the bands of the release gate). Older people are `adult`.
String bandOfAge(int age) => age <= 4 ? 'A' : (age <= 6 ? 'B' : (age <= 8 ? 'C' : 'adult'));

/// `speakers.csv`: `speaker,age`. A speaker that is not listed is an adult.
Map<String, String> parseSpeakers(String csv) {
  final Map<String, String> out = <String, String>{};
  for (final String raw in csv.split('\n')) {
    final String line = raw.replaceAll('\r', '').replaceAll('﻿', '').trim();
    if (line.isEmpty || line.startsWith('#') || line.startsWith('speaker,')) continue;
    final List<String> p = line.split(',');
    final int? age = p.length == 2 ? int.tryParse(p[1].trim()) : null;
    if (age == null) throw FormatException('speakers.csv: expected speaker,age in "$line"');
    out[p[0].trim()] = bandOfAge(age);
  }
  return out;
}

/// Counts the readings of a set of recordings, per age band, for one way of deciding.
class SayTally {
  SayTally({required this.course, this.matcher = const WordMatcher(), this.bands = const <String, String>{}});

  final String course;
  final WordMatcher matcher;

  /// Speaker to band.
  final Map<String, String> bands;
  final Map<String, GateCounts> byBand = <String, GateCounts>{};
  int unsureCorrect = 0;

  /// The foil readings that came out confident, for the developer to look at (the file names only).
  final List<String> confidentFoils = <String>[];

  String bandOf(SayLabel l) => bands[l.speaker] ?? 'adult';

  /// Adds one recording: what the recogniser read for it (the texts of its readings, empty when it heard nothing).
  SayResult add(SayLabel l, List<String> readings) {
    final SayResult r = matcher.decide(readings, l.targetOf(course)).result;
    final bool confident = r == SayResult.confident;
    final bool correct = l.isCorrectReading(course);
    final GateCounts before = byBand[bandOf(l)] ?? const GateCounts();
    byBand[bandOf(l)] =
        before +
        (correct
            ? GateCounts(correctReadings: 1, correctConfident: confident ? 1 : 0)
            : GateCounts(negativeReadings: 1, negativeConfident: confident ? 1 : 0));
    if (correct && !confident) unsureCorrect++;
    if (!correct && confident) confidentFoils.add(l.file);
    return r;
  }

  GateCounts get total => byBand.values.fold(const GateCounts(), (GateCounts a, GateCounts b) => a + b);
}
