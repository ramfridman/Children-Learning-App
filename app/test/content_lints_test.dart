import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// QA lints over the starter sources (board B-15, spec `docs/knowledge/b15-content-spec.md` hand-off H-E). They read
/// `content/starter` directly, so they do not need the bundled signed pack: they run (and can fail) on the sources
/// the next pack is built from.
///
/// 1. The representation label of every activity follows the rule of spec section 2 (G2), and each skill file declares
///    the representations its activities really use.
/// 2. Every `spot_error` is an `error_spotting` check (G1).
/// 3. Section 5.3 of the curriculum: an item with 3 or more options carries two tagged wrong answers. The sources still
///    have items that fall short (the spec's classes M-CNT-CARD and E2, waiting for the owner); this test pins them so
///    that a new gap fails the build, and a gap that gets fixed has to be taken off the list.
const String _dir = '../content/starter';

Map<String, Map<String, Object?>> _load(String prefix) {
  final Map<String, Map<String, Object?>> out = <String, Map<String, Object?>>{};
  for (final File f in Directory(_dir).listSync().whereType<File>()) {
    if (!f.uri.pathSegments.last.startsWith(prefix) || !f.path.endsWith('.json')) continue;
    final Map<String, Object?> doc = jsonDecode(f.readAsStringSync(encoding: utf8)) as Map<String, Object?>;
    out[doc['id']! as String] = doc;
  }
  return out;
}

Map<String, Object?> _m(Object? o) => (o as Map<String, Object?>?) ?? const <String, Object?>{};
List<Object?> _l(Object? o) => (o as List<Object?>?) ?? const <Object?>[];

/// Spec section 2: the label a template and its content call for.
String _expectedRepresentation(Map<String, Object?> a) {
  final Map<String, Object?> scene = _m(a['scene']);
  final Map<String, Object?> answer = _m(a['answer']);
  switch (a['template']) {
    case 'count_tap' ||
        'give_n' ||
        'sort_drag' ||
        'build_pattern' ||
        'shape_builder' ||
        'shop_pay' ||
        'clock_set':
      return 'concrete';
    case 'balance':
      return answer['mode'] == 'balance' ? 'concrete' : 'pictorial';
    case 'robot_path':
      return answer['mode'] == 'direct' ? 'concrete' : 'symbolic';
    case 'number_line' || 'match_pairs' || 'flash':
      return 'pictorial';
    case 'trace':
      return 'embodied';
    case 'spot_error':
      return _l(scene['cells']).any((Object? c) => '$c'.startsWith('asset:')) ? 'pictorial' : 'symbolic';
    case 'tap_answer':
      if (scene['group'] != null || scene['group2'] != null || scene['chart'] != null) return 'pictorial';
      if (_l(answer['options']).any((Object? o) => _m(o)['sprite'] != null || _m(o)['set'] != null)) {
        return 'pictorial';
      }
      if (_l(scene['row']).any((Object? c) => '$c'.startsWith('asset:'))) return 'pictorial';
      return 'symbolic';
  }
  throw StateError('no label rule for template ${a['template']}');
}

/// Items spec section 2 lets keep `story` (a tale told in words) and the one skill whose day cards stay symbols.
const Set<String> _storySkills = <String>{'CS-A-01', 'LOG-A-08', 'MATH-A-05', 'NUM-A-14'};
const String _symbolCardSkill = 'MATH-B-14';

String _skill(Map<String, Object?> a) => _m(_l(a['skills']).first)['id']! as String;

/// Items with 3 or more options and fewer than two tagged wrong answers.
List<String> _tagGaps(Map<String, Map<String, Object?>> acts) {
  final List<String> gaps = <String>[];
  acts.forEach((String id, Map<String, Object?> a) {
    final Map<String, Object?> answer = _m(a['answer']);
    final List<Object?> options = _l(answer['options']);
    if (options.length < 3) return;
    final Object? c = answer['correct'];
    final Set<Object?> right = c is List ? c.toSet() : <Object?>{c};
    final int tagged = options
        .where((Object? o) => !right.contains(_m(o)['id']) && _m(o)['misconception'] != null)
        .length;
    if (tagged < 2) gaps.add(id);
  });
  gaps.sort();
  return gaps;
}

/// The items B-15 added whose gap is known and explained (spec section 3), by class:
/// M-CNT-CARD has no feedback line outside "give N" (hand-off for the curriculum-expert), E2 has no catalogue tag
/// (owner decision 5), the rest are rows the spec gives a single tag or none.
const Map<String, String> _knownNewGaps = <String, String>{
  'b.mathb03.15': 'M-CNT-CARD',
  'b.mathb03.16': 'M-CNT-CARD',
  'b.mathb06.9': 'M-CNT-CARD',
  'b.mathb06.10': 'M-CNT-CARD',
  'b15.matha01.1': 'M-CNT-CARD',
  'b15.matha01.2': 'M-CNT-CARD',
  'b15.matha02.1': 'M-CNT-CARD',
  'b15.matha02.2': 'M-CNT-CARD',
  'b15.numa14.1': 'M-CNT-CARD',
  'b15.numa14.2': 'M-CNT-CARD',
  'b.mathb10.7': 'E2',
  'b.mathb10.8': 'E2',
  'b15.loga09.1': 'E2',
  'b15.loga09.2': 'E2',
  'b15.shpa02.1': 'E2',
  'b15.shpa02.2': 'E2',
  'b.logb01.9': 'one tag only: the pattern has no second wrong place',
  'b.logb01.10': 'one tag only: the pattern has no second wrong place',
  'b15.numa13.1': 'spec: one tag (M-ORD-CARD)',
  'b15.numa13.2': 'spec: one tag (M-ORD-CARD)',
  'b15.numa02.3': 'count_tap: one tag (M-CNT-SKIP)',
};

void main() {
  final Map<String, Map<String, Object?>> acts = _load('activity.');
  final Map<String, Map<String, Object?>> skills = _load('skill.');

  test('the sources are the 967 activities and 100 skills of pack 0.10.0', () {
    expect(acts.length, 967);
    expect(skills.length, 100);
  });

  test('the representation label of every activity follows the rule of spec section 2', () {
    final List<String> wrong = <String>[];
    acts.forEach((String id, Map<String, Object?> a) {
      final String want = _expectedRepresentation(a);
      final String got = a['representation']! as String;
      if (got == want) return;
      final String skill = _skill(a);
      if (got == 'story' && _storySkills.contains(skill)) return;
      if (got == 'symbolic' && skill == _symbolCardSkill) return;
      wrong.add('$id (${a['template']}, $skill): labelled $got, the rule says $want');
    });
    expect(wrong, isEmpty, reason: wrong.join('\n'));
  });

  test('a skill file declares exactly the representations its activities use', () {
    final Map<String, Set<String>> used = <String, Set<String>>{};
    for (final Map<String, Object?> a in acts.values) {
      for (final Object? s in _l(a['skills'])) {
        used.putIfAbsent(_m(s)['id']! as String, () => <String>{}).add(a['representation']! as String);
      }
    }
    final List<String> wrong = <String>[
      for (final MapEntry<String, Map<String, Object?>> s in skills.entries)
        if (!_l(s.value['representations']).toSet().containsAll(used[s.key] ?? <String>{}) ||
            !(used[s.key] ?? <String>{}).containsAll(_l(s.value['representations'])))
          '${s.key}: declares ${_l(s.value['representations'])}, activities use ${used[s.key]}',
    ];
    expect(wrong, isEmpty, reason: wrong.join('\n'));
  });

  test('every spot_error is an error_spotting check', () {
    final List<String> wrong = <String>[
      for (final MapEntry<String, Map<String, Object?>> a in acts.entries)
        if (a.value['template'] == 'spot_error' && a.value['checkType'] != 'error_spotting')
          '${a.key}: ${a.value['checkType']}',
    ];
    expect(wrong, isEmpty, reason: wrong.join('\n'));
  });

  test('every activity names real skills and one of the five check types the pack uses', () {
    const Set<String> checks = <String>{'practice', 'transfer', 'reverse', 'predict', 'error_spotting'};
    final List<String> wrong = <String>[
      for (final MapEntry<String, Map<String, Object?>> a in acts.entries)
        if (!checks.contains(a.value['checkType']) ||
            _l(a.value['skills']).any((Object? s) => !skills.containsKey(_m(s)['id'])))
          '${a.key}: ${a.value['checkType']}',
    ];
    expect(wrong, isEmpty, reason: wrong.join('\n'));
  });

  group('section 5.3: two tagged wrong answers on an item with three or more options', () {
    final List<String> gaps = _tagGaps(acts);

    test('the 21 new items B-15 added with a gap are exactly the explained ones', () {
      final Set<String> newGaps = gaps.where(_knownNewGaps.containsKey).toSet();
      expect(
        newGaps,
        _knownNewGaps.keys.toSet(),
        reason: 'a gap on this list got fixed (take it off), or the item changed its id',
      );
      expect(_knownNewGaps.length, 21);
    });

    test('no other new item falls short: the old gaps are pinned at 310', () {
      final List<String> older = gaps.where((String id) => !_knownNewGaps.containsKey(id)).toList();
      expect(
        older.length,
        310,
        reason: 'a new gap, or an old one fixed: update the pin with the curriculum-expert',
      );
    });
  });
}
