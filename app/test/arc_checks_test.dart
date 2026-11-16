import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/content/arc_checks.dart';

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
    expect(failing, tagWaivers.keys.toSet());
  });

  test('V1: a lesson of a land in a room without parts is refused, unless it is named as waiting', () {
    final Map<String, Map<String, Object?>> l = <String, Map<String, Object?>>{
      for (final MapEntry<String, Map<String, Object?>> e in lessons.entries) e.key: _copy(e.value),
    };
    l['any-shape']!.remove('parts');
    expect(run(l: l).single, contains('V1'));
    expect(arcLessonsWaiting.keys, containsAll(<String>['where-is-it', 'where-is-it-again']));
    for (final String id in arcLessonsWaiting.keys) {
      expect(lessons[id]!['parts'], isNull, reason: id);
    }
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

  test('V2: a skill in a lesson in parts has exactly one Show', () {
    final Map<String, Map<String, Object?>> a = <String, Map<String, Object?>>{
      for (final MapEntry<String, Map<String, Object?>> e in activities.entries) e.key: e.value,
    }..remove('show.shp-a-03');
    expect(run(a: a).join('\n'), contains('exactly one Show'));
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
    // a sort of the ladder draws a picture at hint 2 (the next card goes past the bins): a pictorial question repeats it
    a['shp.any.tilt'] = _copy(activities['shp.any.tilt']!)..['representation'] = 'pictorial';
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
}

extension on Matcher {
  Matcher or(Matcher other) => anyOf(this, other);
}
