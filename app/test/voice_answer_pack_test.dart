// Board B-24: the starter pack offers a spoken answer exactly where docs/knowledge/voice-answer-by-activity.md says
// (curriculum-expert, approved by the owner on 2026-10-29), and nowhere else.
import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/content/models.dart';
import 'package:nitznutz/content/pack_validation.dart';
import 'package:nitznutz/content/schema.dart';

import 'support/starter.dart';

/// The spoken tap_answer activities per skill, from the table of the decision.
const Map<String, int> _spokenTapsBySkill = <String, int>{
  // a number
  'MATH-A-01': 6,
  'MATH-A-02': 6,
  'MATH-B-01': 12,
  'MATH-B-02': 10,
  'MATH-B-03': 8,
  'MATH-B-06': 8,
  'MATH-B-07': 6,
  'MATH-B-08': 12,
  'MATH-B-10': 6,
  'MATH-B-15': 10,
  'MATH-B-18': 7,
  'MATH-B-19': 5,
  'NUM-A-01': 6,
  'NUM-A-02': 7,
  'NUM-A-14': 6, 'NUM-B-01': 9, 'NUM-B-02': 9, 'NUM-B-03': 8, 'NUM-B-10': 10, 'NUM-B-11': 12, 'NUM-B-14': 8,
  'NUM-B-16': 9, 'NUM-B-17': 6, 'SHP-B-02': 8,
  // a colour, a shape, the next in a named sequence
  'COL-A-05': 4, 'COL-B-01': 9, 'SHP-A-04': 1, 'SHP-A-05': 3, 'SHP-B-03': 3, 'MATH-A-05': 2, 'MATH-B-14': 11,
};

void main() {
  late PackContent pack;
  setUpAll(() async => pack = await loadStarter());

  Iterable<Activity> spoken() => pack.activities.values.where((Activity a) => a.voiceAnswer);

  test('267 of the 767 activities are answered by voice, and 500 are not', () {
    expect(pack.activities.length, 767);
    expect(spoken().length, 267);
  });

  test('by template: tap_answer 227 of 521, every count_tap and flash, and no other template', () {
    final Map<String, (int, int)> byTemplate = <String, (int, int)>{};
    for (final Activity a in pack.activities.values) {
      final (int, int) n = byTemplate[a.template] ?? (0, 0);
      byTemplate[a.template] = a.voiceAnswer ? (n.$1 + 1, n.$2) : (n.$1, n.$2 + 1);
    }
    expect(byTemplate.remove('tap_answer'), (227, 294));
    expect(byTemplate.remove('count_tap'), (28, 0));
    expect(byTemplate.remove('flash'), (12, 0));
    expect(byTemplate.length, 12, reason: 'the other twelve templates');
    for (final MapEntry<String, (int, int)> t in byTemplate.entries) {
      expect(t.value.$1, 0, reason: '${t.key} is answered by hand');
    }
    expect(byTemplate.values.fold<int>(0, (int s, (int, int) n) => s + n.$2), 206);
  });

  test('the spoken tap_answer activities per skill are the ones of the table', () {
    final Map<String, int> bySkill = <String, int>{};
    for (final Activity a in spoken().where((Activity a) => a.template == 'tap_answer')) {
      bySkill[a.skillId] = (bySkill[a.skillId] ?? 0) + 1;
    }
    expect(bySkill, _spokenTapsBySkill);
  });

  test('"where is the number…?" and reading a numeral are tapped, never said', () {
    for (final Activity a in pack.activities.values) {
      if (a.skillId == 'NUM-A-08' || a.skillId == 'NUM-B-08') expect(a.voiceAnswer, isFalse, reason: a.id);
    }
  });

  test('the five hand-written activities carry the flag the decision gives them', () {
    for (final (String, bool) h in <(String, bool)>[
      ('count.butterflies.3', true),
      ('count.butterflies.4', true),
      ('count.butterflies.5', true),
      ('give.butterflies.4', false),
      ('pick.red.flower', false),
    ]) {
      expect(pack.activities[h.$1]!.voiceAnswer, h.$2, reason: h.$1);
      expect(pack.activities[h.$1]!.json.containsKey('voiceAnswer'), isTrue, reason: h.$1);
    }
  });

  test('every activity says whether it is spoken (the validator demands it of the starter pack)', () {
    for (final Activity a in pack.activities.values) {
      expect(a.json['voiceAnswer'], isA<bool>(), reason: a.id);
    }
  });

  test('the builder warns about exactly the eight numbers that start another option\'s number', () {
    final List<Problem> warnings = packWarnings(
      docs: <String, Object?>{
        for (final Activity a in pack.activities.values) 'activity.${a.id}.json': a.json,
      },
    );
    expect(
      <String>{for (final Problem p in warnings) p.path.split(' ').first},
      <String>{
        for (final String id in <String>[
          'b.mathb03.7',
          'b.mathb15.4',
          'b.mathb15.7',
          'b.mathb15.8',
          'b.numb02.2',
          'b.numb02.3',
          'b.numb02.6',
          'b.numb10.10',
        ])
          'activity.$id.json',
      },
    );
    expect(warnings.length, 8);
  });
}
