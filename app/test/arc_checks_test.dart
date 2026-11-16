import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/content/arc_checks.dart';
import 'package:nitznutz/content/w1_words.dart';

/// The rules V1 to V7 and the warning W1 of the lesson arc (M11 Stage 2, docs/milestones/M11-stage2.md section 7.2, with the corrections of section
/// 11.2), over the starter sources and over changed copies of them. By ids and structure: no Hebrew text is pinned.
const String _dir = '../content/starter';

Map<String, Map<String, Object?>> _load(String prefix) {
  final Map<String, Map<String, Object?>> out = <String, Map<String, Object?>>{};
  for (final File f in Directory(_dir).listSync().whereType<File>()) {
    final String name = f.uri.pathSegments.last;
    if (!name.startsWith(prefix) || !name.endsWith('.json')) continue;
    final Map<String, Object?> doc = jsonDecode(f.readAsStringSync(encoding: utf8)) as Map<String, Object?>;
    out[doc['id']! as String] = doc;
  }
  return out;
}

Map<String, Object?> _m(Object? o) => o! as Map<String, Object?>;
List<Object?> _l(Object? o) => o! as List<Object?>;

Map<String, Object?> _copy(Map<String, Object?> d) => _m(jsonDecode(jsonEncode(d)));

void main() {
  late Map<String, Map<String, Object?>> activities;
  late Map<String, Map<String, Object?>> lessons;
  late Map<String, Map<String, Object?>> skills;

  setUpAll(() {
    activities = _load('activity.');
    lessons = _load('lesson.');
    skills = _load('skill.');
  });

  List<String> run({
    Map<String, Map<String, Object?>>? a,
    Map<String, Map<String, Object?>>? l,
    Map<String, String> tagWaived = tagWaivers,
  }) {
    final List<String> out = <String>[];
    checkArc(
      activities: a ?? activities,
      lessons: l ?? lessons,
      skills: skills,
      say: (String file, String path, String message) => out.add('$file $path $message'),
      tagWaived: tagWaived,
    );
    return out;
  }

  test('the starter sources of Shape Forest pass every rule', () {
    expect(run(), isEmpty);
    for (final MapEntry<String, Map<String, Object?>> e in activities.entries) {
      final List<String> shows = <String>[];
      checkShowActivity(
        'activity.${e.key}.json',
        e.value,
        (String f, String p, String m) => shows.add('$f $p $m'),
      );
      expect(shows, isEmpty, reason: e.key);
    }
  });

  test('the waived taps are exactly the failing ones: a fixed gap must come off the list', () {
    final Set<String> failing = <String>{
      for (final String p in run(tagWaived: const <String, String>{}))
        if (RegExp(r'activity\.(.+)\.json ').firstMatch(p) case final RegExpMatch m) m.group(1)!,
    };
    // the lands that are under the rules: the waivers are exactly the failing items
    final Set<String> inShapes = <String>{
      for (final String id in tagWaivers.keys)
        if (id.startsWith('b.shpb') || id.startsWith('shp')) id,
    };
    expect(failing, inShapes);
    // the lands that are not yet: each waiver of theirs (M11-stage2 section 11.5) is a tap that fails the rule without it
    final Set<String> failingEverywhere = <String>{};
    final List<String> found = <String>[];
    checkArc(
      activities: activities,
      lessons: lessons,
      skills: skills,
      say: (String file, String path, String message) => found.add('$file $path $message'),
      tagWaived: const <String, String>{},
      domains: allArcDomains,
    );
    for (final String p in found) {
      if (RegExp(r'activity\.(.+)\.json ').firstMatch(p) case final RegExpMatch m) {
        failingEverywhere.add(m.group(1)!);
      }
    }
    expect(
      failingEverywhere.containsAll(tagWaivers.keys),
      isTrue,
      reason: 'a waived tap that no longer fails comes off the list',
    );
  });

  test('V5: the waived hint 2s are exactly those whose family draws the own question representation', () {
    for (final String id in hintTwoWaivers.keys) {
      final String? family = hintFamilyOf(_m(_l(activities[id]!['hints'])[1])['vo']);
      expect(
        hintFamilyRepresentation[family],
        activities[id]!['representation'],
        reason: '$id is fixed: take it off hintTwoWaivers',
      );
    }
    // and every other item of the arc passes (the starter sources pass every rule)
    expect(run(), isEmpty);
  });

  test('V6 (QA round): a hands-on item needs as many tags as its skill lists, up to two; a tap tags its distractors, counted not distinct', () {
    final String id = activities.entries
        .firstWhere(
          (MapEntry<String, Map<String, Object?>> e) =>
              e.value['template'] == 'tap_answer' &&
              (_m(_l(e.value['skills']).first)['id']! as String).startsWith('SHP-') &&
              _l(_m(e.value['answer'])['options']).length == 3 &&
              !noSecondTagSkills.contains(_m(_l(e.value['skills']).first)['id']) &&
              _l(skills[_m(_l(e.value['skills']).first)['id']]?['misconceptions']).isNotEmpty &&
              !tagWaivers.containsKey(e.key),
        )
        .key;
    final Map<String, Object?> tap = _copy(activities[id]!);
    final List<Object?> options = _l(_m(tap['answer'])['options']);
    // three options, two distractors that carry the same tag: two tagged distractors
    final List<Map<String, Object?>> wrong = <Map<String, Object?>>[
      for (final Object? o in options)
        if (_m(o)['id'] != _m(tap['answer'])['correct']) _m(o),
    ];
    expect(wrong.length, greaterThanOrEqualTo(2));
    for (final Map<String, Object?> o in wrong) {
      o['misconception'] = 'M-SHP-SQRECT';
    }
    final Map<String, Map<String, Object?>> a = <String, Map<String, Object?>>{
      for (final MapEntry<String, Map<String, Object?>> e in activities.entries) e.key: e.value,
    };
    a[id] = tap;
    expect(
      run(a: a).where((String m) => m.contains('activity.$id.json')),
      isEmpty,
      reason: 'the same tag twice is two tagged distractors',
    );
    // one tagged distractor of three options is refused
    wrong.last.remove('misconception');
    expect(run(a: a).where((String m) => m.contains('activity.$id.json')), isNotEmpty);
  });

  test(
    'V1: a lesson of a land in a room without parts is refused, unless it says what its Show waits for',
    () {
      final Map<String, Map<String, Object?>> l = <String, Map<String, Object?>>{
        for (final MapEntry<String, Map<String, Object?>> e in lessons.entries) e.key: _copy(e.value),
      };
      l['any-shape']!.remove('parts');
      expect(run(l: l).single, contains('V1'));
      l['any-shape']!['partsWait'] = 'its Show waits for a drawing';
      expect(run(l: l), isEmpty);
      // the lessons of SHP-A-08 wait by themselves (written by the arc build from the Show it could not build), no hand list names them
      expect(lessonsWaiting(lessons).keys, containsAll(<String>['where-is-it', 'where-is-it-again']));
      for (final String id in lessonsWaiting(lessons).keys) {
        expect(lessons[id]!['parts'], isNull, reason: id);
      }
    },
  );

  test('V1 (QA-2): a lesson in parts with an empty Alone pool is refused, because the planner has nothing to serve', () {
    final Map<String, Map<String, Object?>> l = <String, Map<String, Object?>>{
      for (final MapEntry<String, Map<String, Object?>> e in lessons.entries) e.key: _copy(e.value),
    };
    _m(l['any-shape']!['parts'])['alone'] = <Object?>[];
    final List<String> found = run(l: l)
        .where((String m) => m.contains('lesson.any-shape.json') && m.contains('parts.alone'))
        .toList();
    expect(found, hasLength(1));
    expect(found.single, contains('at least one Alone item'));
  });

  test('V1: the Show of a lesson is a Show of one of its skills, and never one of its items', () {
    final Map<String, Map<String, Object?>> l = <String, Map<String, Object?>>{
      for (final MapEntry<String, Map<String, Object?>> e in lessons.entries) e.key: _copy(e.value),
    };
    _m(l['any-shape']!['parts'])['show'] = 'show.shp-b-01';
    expect(run(l: l).join('\n'), contains('another skill'));
    _m(l['any-shape']!['parts'])['show'] = 'shp.any.tilt';
    expect(run(l: l).join('\n'), contains('not a Show'));
  });

  test('V2: a Show has at most three lines, one child step that comes last, no hints, and a hands-on template with a lead player', () {
    final Map<String, Object?> show = _copy(activities['show.shp-a-03']!);
    List<String> check(Map<String, Object?> d) {
      final List<String> out = <String>[];
      checkShowActivity('x', d, (String f, String p, String m) => out.add(m));
      return out;
    }

    expect(check(show), isEmpty);
    final Map<String, Object?> two = _copy(show);
    _m(_l(_m(two['show'])['steps']).first)['by'] = 'child';
    expect(check(two).join(), contains('exactly one child step'));
    final Map<String, Object?> noKey = _copy(show);
    _l(_m(noKey['show'])['lines']).removeWhere((Object? x) => _m(x)['role'] == 'key');
    expect(check(noKey).join(), contains('"key"'));
    final Map<String, Object?> hints = _copy(show)..['hints'] = <Object?>[<String, Object?>{}];
    expect(check(hints).join(), contains('no hints'));
    final Map<String, Object?> tap = _copy(show)..['template'] = 'tap_answer';
    expect(check(tap).join(), contains('lead player'));
    final Map<String, Object?> wrongBin = _copy(show);
    _m(_l(_m(wrongBin['show'])['steps']).first)['bin'] = 'b9';
    expect(check(wrongBin).join(), contains('its own bin'));
  });

  test('V2: a skill in a lesson in parts has a Show, and one for each template at most', () {
    final Map<String, Map<String, Object?>> a = <String, Map<String, Object?>>{
      for (final MapEntry<String, Map<String, Object?>> e in activities.entries) e.key: e.value,
    }..remove('show.shp-a-03');
    expect(run(a: a).join('\n'), contains('has a Show (V2), found none'));
  });

  test(
    'V3: the host leads at least one and fewer than all the steps of a hands-on item, and nothing of a tap',
    () {
      final Map<String, Map<String, Object?>> l = <String, Map<String, Object?>>{
        for (final MapEntry<String, Map<String, Object?>> e in lessons.entries) e.key: _copy(e.value),
      };
      final Map<String, Object?> together = _m(_l(_m(l['any-shape']!['parts'])['together']).first);
      together['lead'] = 0;
      expect(run(l: l).join('\n'), contains('V3').or(contains('at least 1')));
      together['lead'] = 99;
      expect(run(l: l).join('\n'), contains('at least 1'));
      for (final Map<String, Object?> lesson in lessons.values) {
        final Object? parts = lesson['parts'];
        if (parts == null) continue;
        for (final Object? t in _l(_m(parts)['together'] ?? <Object?>[])) {
          final int? steps = leadableSteps(activities[_m(t)['id']]!);
          expect(
            steps == null ? _m(t)['lead'] == 0 : (_m(t)['lead']! as int) < steps,
            isTrue,
            reason: '${_m(t)['id']}',
          );
        }
      }
    },
  );

  test('V4: the pick caps hold per skill and per land and band, with the exempt skills named', () {
    expect(pickCapExempt.keys.toSet(), <String>{
      'NUM-A-11',
      'NUM-A-12',
      'NUM-A-13',
      'NUM-A-14',
      'MATH-A-01',
      'MATH-A-02',
      'MATH-B-07',
      'COL-B-01',
      'SHP-A-08',
      'LOG-B-02',
      'CS-B-04',
    });
    expect(recognitionSkills, hasLength(11));
    // turning every item of a skill into a pick breaks the cap
    final Map<String, Map<String, Object?>> a = <String, Map<String, Object?>>{
      for (final MapEntry<String, Map<String, Object?>> e in activities.entries) e.key: e.value,
    };
    for (final MapEntry<String, Map<String, Object?>> e in activities.entries) {
      if (e.value['purpose'] == 'show' || _m(_l(e.value['skills']).first)['id'] != 'SHP-B-05') continue;
      a[e.key] = _copy(e.value)
        ..['template'] = 'spot_error'
        ..['answer'] = <String, Object?>{};
    }
    expect(run(a: a).join('\n'), contains('V4'));
  });

  test('V5: hint 2 draws another representation than the question\'s own', () {
    final Map<String, Map<String, Object?>> a = <String, Map<String, Object?>>{
      for (final MapEntry<String, Map<String, Object?>> e in activities.entries) e.key: e.value,
    };
    // hint 2 of b.shpb01.1 is the family shp_sides (the finger traces the sides: embodied): an embodied question repeats it
    expect(hintFamilyOf(_m(_l(activities['b.shpb01.1']!['hints'])[1])['vo']), 'shp_sides');
    a['b.shpb01.1'] = _copy(activities['b.shpb01.1']!)..['representation'] = 'embodied';
    expect(run(a: a).join('\n'), contains('V5'));
  });

  test('V6: a hands-on item that can record one tag only is refused, with the skills that have no honest second tag named', () {
    final Map<String, Map<String, Object?>> a = <String, Map<String, Object?>>{
      for (final MapEntry<String, Map<String, Object?>> e in activities.entries) e.key: e.value,
    };
    final Map<String, Object?> sort = _copy(activities['shp.any.tilt']!);
    for (final Object? i in _l(_m(sort['scene'])['items'])) {
      _m(i).remove('misconception');
    }
    a['shp.any.tilt'] = sort;
    expect(run(a: a).join('\n'), contains('V6'));
    expect(noSecondTagSkills, containsAll(<String>['SHP-A-05', 'SHP-B-05', 'SHP-B-06']));
    expect(recordableTags(activities['shp.match.square']!).length, greaterThanOrEqualTo(2));
  });

  test('V7: the pool of a lesson holds a rung 0 and a rung 1 item for each skill, the waivers named', () {
    final Map<String, Map<String, Object?>> l = <String, Map<String, Object?>>{
      for (final MapEntry<String, Map<String, Object?>> e in lessons.entries) e.key: _copy(e.value),
    };
    _m(l['polygon-detectives-more']!['parts'])['alone'] = <Object?>[
      _l(_m(l['polygon-detectives-more']!['parts'])['alone']).first,
    ];
    _m(l['polygon-detectives-more']!['parts'])['use'] = <Object?>[];
    _m(l['polygon-detectives-more']!['parts'])['together'] = <Object?>[];
    expect(run(l: l).join('\n'), contains('V7'));
    expect(rungOfRepresentation('concrete'), 0);
    expect(rungOfRepresentation('story'), 1);
    expect(rungOfRepresentation('symbolic'), 2);
    expect(skillHasSymbols('NUM-B-09'), isTrue);
    expect(skillHasSymbols('SHP-B-01'), isFalse);
  });

  test('a pack with no lesson in parts is checked as it always was', () {
    final Map<String, Map<String, Object?>> l = <String, Map<String, Object?>>{
      for (final MapEntry<String, Map<String, Object?>> e in lessons.entries)
        e.key: _copy(e.value)..remove('parts'),
    };
    expect(run(l: l), isEmpty);
  });

  test('W1: the starter sources give no warning, with the exceptions of the named data (yes and no, not-X, the counting words, the right option only)', () {
    expect(metBeforeAsked(activities: activities, lessons: lessons, skills: skills), isEmpty);
    // what the exceptions are: data, not code
    expect(w1YesNo, containsAll(<String>['כן', 'לא']));
    expect(w1CountingWords, containsAll(<String>['חמש', 'חמישה', 'עשר']));
    expect(w1CountingSkill, 'NUM-A-02');
  });

  test('W1: the label of a wrong option is not asked for, the label of the right one is', () {
    final Map<String, Map<String, Object?>> a = <String, Map<String, Object?>>{
      for (final MapEntry<String, Map<String, Object?>> e in activities.entries) e.key: e.value,
    };
    final String id = activities.entries
        .firstWhere(
          (MapEntry<String, Map<String, Object?>> e) =>
              e.value['template'] == 'tap_answer' &&
              (_m(_l(e.value['skills']).first)['id']! as String).startsWith('SHP-') &&
              _l(_m(e.value['answer'])['options']).any((Object? o) => _m(o)['label'] is String),
        )
        .key;
    final Map<String, Object?> tap = _copy(activities[id]!);
    final Map<String, Object?> answer = _m(tap['answer']);
    final List<Map<String, Object?>> options = <Map<String, Object?>>[
      for (final Object? o in _l(answer['options'])) _m(o),
    ];
    a[id] = tap;
    final Map<String, Object?> right = options.firstWhere(
      (Map<String, Object?> o) => o['id'] == answer['correct'],
    );
    final Map<String, Object?> other = options.firstWhere(
      (Map<String, Object?> o) => o['id'] != answer['correct'],
    );
    other['label'] = 'מילה שלא נלמדה';
    expect(
      metBeforeAsked(activities: a, lessons: lessons, skills: skills).where((String w) => w.contains(id)),
      isEmpty,
    );
    right['label'] = 'מילה שלא נלמדה';
    expect(
      metBeforeAsked(activities: a, lessons: lessons, skills: skills).where((String w) => w.contains(id)),
      isNotEmpty,
    );
  });

  test('W1: a label the Show has not taught is a warning, not a refusal', () {
    final Map<String, Map<String, Object?>> a = <String, Map<String, Object?>>{
      for (final MapEntry<String, Map<String, Object?>> e in activities.entries) e.key: e.value,
    };
    final Map<String, Object?> show = _copy(a['show.shp-b-01']!);
    _m(show['show'])['teaches'] = <Object?>[];
    a['show.shp-b-01'] = show;
    final List<String> warnings = metBeforeAsked(activities: a, lessons: lessons, skills: skills);
    expect(warnings.where((String w) => w.contains('SHP-B-01')), isNotEmpty);
    expect(warnings, everyElement(startsWith('W1:')));
  });

  test('the five lands under the rules: what is left before they join arcDomains (the pinned count falls to 0, then the switch is one line)', () {
    final List<String> found = <String>[];
    checkArc(
      activities: activities,
      lessons: lessons,
      skills: skills,
      say: (String file, String path, String message) => found.add('$file $path $message'),
      domains: allArcDomains,
    );
    for (final MapEntry<String, Map<String, Object?>> e in activities.entries) {
      checkShowActivity(
        'activity.${e.key}.json',
        e.value,
        (String file, String path, String message) => found.add('$file $path $message'),
      );
    }
    found.addAll(
      metBeforeAsked(activities: activities, lessons: lessons, skills: skills, domains: allArcDomains),
    );
    final Map<String, int> byRule = <String, int>{};
    for (final String f in found) {
      final String rule = <String>[
        'V1',
        'V2',
        'V3',
        'V4',
        'V5',
        'V6',
        'V7',
        'W1',
      ].firstWhere((String r) => f.contains('$r:'), orElse: () => 'other');
      byRule[rule] = (byRule[rule] ?? 0) + 1;
    }
    // ignore: avoid_print
    print('FIVE LANDS ${byRule.entries.map((MapEntry<String, int> e) => '${e.key}=${e.value}').join(' ')}');
    // ignore: avoid_print
    print(found.take(400).join('\n'));
    // 2026-11-16: V4 2 (LOG-A-04 is all picks until its strips are drawn; Riddle Grotto A is over 50%), V6 124 (taps that stay with one tagged distractor, hands-on
    // items with one honest tag: curriculum-expert), V7 2 (NUM-B-14 and NUM-B-09 pools), W1 381 (number words and shade words no Show teaches: curriculum-expert).
    // V1, V2, V3 and V5 are clean. When this is empty the five lands join `arcDomains`.
    expect(byRule, <String, int>{'V4': 2, 'V6': 124, 'V7': 2, 'W1': 381});
  });
}

extension on Matcher {
  Matcher or(Matcher other) => anyOf(this, other);
}
