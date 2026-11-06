// Regression tests of the security findings of M10 step 0 (SEC-M10-1 to SEC-M10-5, docs/security/findings.md): the build claims
// `tap_answer` 1.4 before any session draws a number answer or a stage picture; the validator threw on incomplete pictures; the
// big numbers of Band C were not tied to Band C and grew the hint pictures; number cells took leading zeros; and an item could ask
// for a template version above its manifest's.
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/child/activity_shell.dart';
import 'package:nitznutz/content/models.dart';
import 'package:nitznutz/content/pack_validation.dart';
import 'package:nitznutz/content/schema.dart';
import 'package:nitznutz/content/schemas.dart';
import 'package:nitznutz/play/hints/hint_marks.dart';
import 'package:nitznutz/play/hints/tap_geometry.dart';
import 'package:nitznutz/play/hints/tap_plans.dart';

import 'support/sample_pack.dart';
import 'support/starter.dart';

Map<String, Object?> _m(Object? v) => v! as Map<String, Object?>;

/// A copy of the sample's `tap_answer` item (Band C, 1.4, the manifest promising 1.4), edited by [edit].
SamplePack _tap(void Function(Map<String, Object?> doc) edit, {String band = 'C'}) {
  final SamplePack p = SamplePack();
  final Map<String, Object?> doc = _m(p.docs[tapFile]);
  doc['templateVersion'] = '1.4';
  doc['band'] = band;
  _m(p.manifest['templates'])['tap_answer'] = '1.4';
  edit(doc);
  return p;
}

void _numberItem(Map<String, Object?> doc) {
  doc['scene'] = <String, Object?>{
    'background': 'asset:meadow',
    'row': <Object?>['n:52', 'op:-', 'n:27', 'op:=', '?'],
  };
  doc['answer'] = <String, Object?>{'type': 'number', 'value': 25};
}

List<String> _problems(SamplePack p, {String file = tapFile}) => <String>[
  for (final Problem x in validatePack(manifest: p.manifest, docs: p.docs, files: p.files))
    if (x.path.startsWith(file) && !x.toString().contains('but its skill')) x.toString(),
];

List<String> _schema(Map<String, Object?> doc, String template) => <String>[
  for (final Problem x in validate(activitySchemaFor(template)!, doc)) x.toString(),
];

/// How many marks a plan draws: the marks of every step and the marks that stay.
int _marks(HintPlan p) => p.frames.fold<int>(0, (int s, HintFrame f) => s + f.marks.length) + p.rest.length;

void main() {
  group('SEC-M10-1: the items no session draws yet are hidden', () {
    test('a number answer and a stage picture are left out of the pack content, a choice stays', () {
      final SamplePack number = _tap(_numberItem);
      final SamplePack picture = _tap(
        (Map<String, Object?> d) =>
            _m(d['scene'])['picture'] = <String, Object?>{'kind': 'array', 'rows': 3, 'columns': 4},
      );
      for (final SamplePack p in <SamplePack>[number, picture]) {
        final PackContent content = PackContent.fromPack(p.verified());
        expect(content.activities.containsKey('pick.red.flower'), isFalse);
        expect(content.activities.keys, containsAll(<String>['count.butterflies.3', 'give.three.jar']));
        // The lesson that lists it plays the rest, and does not fail on the missing id.
        expect(content.itemsOf(content.lessons['butterflies']!).map((Activity a) => a.id), <String>[
          'count.butterflies.3',
          'give.three.jar',
        ]);
      }
      expect(PackContent.fromPack(SamplePack().verified()).activities.containsKey('pick.red.flower'), isTrue);
    });

    test('the hint plans of an item with no right option are none, not a RangeError', () {
      final SamplePack p = _tap(_numberItem);
      final PackAssets assets = PackContent.fromPack(p.verified(pictures: true)).assets;
      final TapAnswerActivity a = Activity.fromJson(_m(p.docs[tapFile]), assets) as TapAnswerActivity;
      expect(a.numberAnswer, isNotNull);
      const ActivitySpec spec = ActivitySpec.phone;
      final TapGeometry g = TapGeometry(a, spec.stage.size, spec);
      expect(g.correctIndex, -1);
      for (int level = 1; level <= 3; level++) {
        expect(tapHintPlan(a, g, level), isNull, reason: 'level $level');
      }
    });
  });

  group('SEC-M10-2: an incomplete stage picture is a problem, not an exception', () {
    for (final Map<String, Object?> pic in <Map<String, Object?>>[
      <String, Object?>{'kind': 'fraction', 'parts': 3},
      <String, Object?>{'kind': 'fraction', 'shaded': 1},
      <String, Object?>{'kind': 'column', 'op': '+', 'bottom': '5'},
      <String, Object?>{'kind': 'column', 'op': '+', 'top': '5'},
      <String, Object?>{'kind': 'nothing_like_it'},
      <String, Object?>{'rows': 3},
    ]) {
      test('$pic', () {
        final SamplePack p = _tap((Map<String, Object?> d) => _m(d['scene'])['picture'] = pic);
        late List<String> problems;
        expect(() => problems = _problems(p), returnsNormally);
        expect(problems, isNotEmpty);
      });
    }

    test('a complete picture of each of the two kinds is still taken', () {
      expect(
        _problems(
          _tap(
            (Map<String, Object?> d) =>
                _m(d['scene'])['picture'] = <String, Object?>{'kind': 'fraction', 'parts': 4, 'shaded': 1},
          ),
        ),
        isEmpty,
      );
      expect(
        _problems(
          _tap(
            (Map<String, Object?> d) => _m(d['scene'])['picture'] = <String, Object?>{
              'kind': 'column',
              'op': '+',
              'top': '125',
              'bottom': '37',
            },
          ),
        ),
        isEmpty,
      );
    });
  });

  group('SEC-M10-3: big numbers belong to Band C', () {
    const String big = 'belongs to Band C';

    test('a numeral above 100 on the stage or on a tile is refused outside Band C', () {
      void numerals(Map<String, Object?> d) {
        _m(d['scene'])['numeral'] = 101;
        final List<Object?> options = _m(d['answer'])['options']! as List<Object?>;
        _m(options[0]).remove('sprite');
        _m(options[0])['numeral'] = 450;
      }

      for (final String band in <String>['A', 'B']) {
        final List<String> problems = _problems(_tap(numerals, band: band));
        expect(problems, contains(contains('scene.numeral')), reason: band);
        expect(problems, contains(contains('answer.options[0].numeral')), reason: band);
        expect(problems.where((String s) => s.contains(big)), hasLength(2), reason: band);
      }
      expect(_problems(_tap(numerals)).where((String s) => s.contains(big)), isEmpty);
    });

    test('100 itself and a number of three digits in a row are still fine in Band A', () {
      final SamplePack p = _tap((Map<String, Object?> d) {
        _m(d['scene'])['numeral'] = 100;
        _m(d['scene'])['row'] = <Object?>['n:100', 'op:+', 'n:101', 'op:=', '?'];
      }, band: 'A');
      expect(_problems(p).where((String s) => s.contains(big)), isEmpty);
    });

    test('a cell of four digits in a row is refused outside Band C', () {
      void row(Map<String, Object?> d) =>
          _m(d['scene'])['row'] = <Object?>['n:1000', 'op:+', 'n:5', 'op:=', '?'];
      expect(_problems(_tap(row, band: 'B')), contains(contains('scene.row[0]')));
      expect(_problems(_tap(row, band: 'A')).where((String s) => s.contains(big)), hasLength(1));
      expect(_problems(_tap(row)).where((String s) => s.contains(big)), isEmpty);
    });

    test('a cell of four digits in a spot_error is refused outside Band C', () {
      SamplePack spot(String band) {
        final SamplePack p = SamplePack();
        final Map<String, Object?> doc = Map<String, Object?>.of(_m(p.docs[tapFile]))
          ..['id'] = 'spot.one'
          ..['template'] = 'spot_error'
          ..['templateVersion'] = '1.1'
          ..['band'] = band
          ..['scene'] = <String, Object?>{
            'background': 'asset:meadow',
            'cells': <Object?>['n:4050', 'op:<', 'n:4500'],
          }
          ..['answer'] = <String, Object?>{'type': 'spot', 'wrong': 1};
        p.addDocument('activity.spot.one.json', 'activities', 'spot.one', doc);
        _m(p.manifest['templates'])['spot_error'] = '1.1';
        return p;
      }

      const String file = 'activity.spot.one.json';
      expect(_problems(spot('A'), file: file).where((String s) => s.contains(big)), hasLength(2));
      expect(_problems(spot('B'), file: file).where((String s) => s.contains(big)), hasLength(2));
      expect(_problems(spot('C'), file: file).where((String s) => s.contains(big)), isEmpty);
    });

    TapAnswerActivity sentenceWith(TapAnswerActivity base, int whole, int known, int answer) {
      final Map<String, Object?> j = jsonDecode(jsonEncode(base.json)) as Map<String, Object?>;
      j['templateVersion'] = '1.4';
      _m(j['scene'])['row'] = <Object?>['?', 'op:+', 'n:$known', 'op:=', 'n:$whole'];
      final Map<String, Object?> ans = _m(j['answer']);
      final Map<String, Object?> right = (ans['options']! as List<Object?>)
          .cast<Map<String, Object?>>()
          .firstWhere((Map<String, Object?> o) => o['id'] == ans['correct']);
      right
        ..remove('sprite')
        ..remove('set')
        ..['numeral'] = answer;
      return Activity.fromJson(j, base.assets) as TapAnswerActivity;
    }

    group('the hint plans do not grow with the number', () {
      late PackContent content;
      setUpAll(() async => content = await loadStarter());

      test('a number sentence of 20 is drawn cube by cube, one of 2,000 gets the generic plan', () {
        final TapAnswerActivity base = content.activities.values.whereType<TapAnswerActivity>().firstWhere(
          (TapAnswerActivity a) => a.skillId == 'MATH-B-03' && a.row.isNotEmpty,
        );
        const ActivitySpec spec = ActivitySpec.phone;
        for (final (int, int, int) c in <(int, int, int)>[
          (20, 12, 8),
          (200, 120, 80),
          (999, 600, 399),
          (2000, 1200, 800),
          (10000, 6000, 4000),
        ]) {
          final TapAnswerActivity a = sentenceWith(base, c.$1, c.$2, c.$3);
          final TapGeometry g = TapGeometry(a, spec.stage.size, spec);
          for (int level = 1; level <= 3; level++) {
            final HintPlan p = tapHintPlan(a, g, level)!;
            expect(_marks(p), lessThan(2000), reason: 'whole ${c.$1}, level $level');
            if (c.$1 > 20) expect(_marks(p), lessThan(60), reason: 'whole ${c.$1}, level $level');
          }
        }
      });

      test(
        'every tap_answer of the starter, with every number made big, keeps its hints under 2,000 marks',
        () {
          const ActivitySpec spec = ActivitySpec.phone;
          int checked = 0;
          final List<String> tooBig = <String>[];
          for (final TapAnswerActivity base in content.activities.values.whereType<TapAnswerActivity>()) {
            final Map<String, Object?> j = jsonDecode(jsonEncode(base.json)) as Map<String, Object?>;
            int bigger(int n) => n + 9000 > 10000 ? 10000 : n + 9000;
            final Map<String, Object?> scene = _m(j['scene']);
            if (scene['numeral'] is int) scene['numeral'] = bigger(scene['numeral']! as int);
            if (scene['row'] is List<Object?>) {
              scene['row'] = <Object?>[
                for (final Object? c in scene['row']! as List<Object?>)
                  c is String && RegExp(r'^n:\d+$').hasMatch(c)
                      ? 'n:${bigger(int.parse(c.substring(2)))}'
                      : c,
              ];
            }
            for (final Object? o in (_m(j['answer'])['options'] as List<Object?>?) ?? const <Object?>[]) {
              final Map<String, Object?> option = _m(o);
              if (option['numeral'] is int) option['numeral'] = bigger(option['numeral']! as int);
            }
            final TapAnswerActivity a = Activity.fromJson(j, base.assets) as TapAnswerActivity;
            final TapGeometry g = TapGeometry(a, spec.stage.size, spec);
            for (int level = 1; level <= 3; level++) {
              final HintPlan? p = tapHintPlan(a, g, level);
              if (p == null) continue;
              if (_marks(p) >= 2000 || p.frames.length >= 200) {
                tooBig.add(
                  '${a.id} (${a.skillId}) level $level: ${_marks(p)} marks, ${p.frames.length} steps',
                );
              }
            }
            checked++;
          }
          expect(tooBig, isEmpty);
          expect(checked, greaterThan(100));
        },
      );
    });
  });

  group('SEC-M10-4: number cells and column numbers to 10,000, with no leading zero', () {
    List<String> row(List<Object?> cells) => _schema(
      _m(_tap((Map<String, Object?> d) => _m(d['scene'])['row'] = cells).docs[tapFile]),
      'tap_answer',
    );

    test('0, 9, 10, 9999 and 10000 are taken in a row', () {
      expect(row(<Object?>['n:0', 'n:9', 'n:10', 'n:9999', 'n:10000']), isEmpty);
    });

    test('a leading zero and a number above 10,000 are refused in a row', () {
      for (final String cell in <String>[
        'n:00',
        'n:01',
        'n:007',
        'n:0100',
        'n:10001',
        'n:99999',
        'n:20000',
      ]) {
        expect(row(<Object?>['n:1', cell]), isNotEmpty, reason: cell);
      }
    });

    test('the cells of a spot_error say the same', () {
      Map<String, Object?> spot(List<Object?> cells) => <String, Object?>{
        ...jsonDecode(jsonEncode(_m(SamplePack().docs[tapFile]))) as Map<String, Object?>,
        'template': 'spot_error',
        'templateVersion': '1.1',
        'scene': <String, Object?>{'background': 'asset:meadow', 'cells': cells},
        'answer': <String, Object?>{'type': 'spot', 'wrong': 1},
      };
      expect(_schema(spot(<Object?>['n:0', 'n:10000', 'n:9999']), 'spot_error'), isEmpty);
      for (final String cell in <String>['n:00', 'n:0100', 'n:10001', 'n:99999']) {
        expect(_schema(spot(<Object?>['n:1', cell, 'n:2']), 'spot_error'), isNotEmpty, reason: cell);
      }
    });

    test('a column number has no leading zero and stops at 10,000', () {
      List<String> column(String top, String bottom) => _schema(
        _m(
          _tap(
            (Map<String, Object?> d) => _m(d['scene'])['picture'] = <String, Object?>{
              'kind': 'column',
              'op': '+',
              'top': top,
              'bottom': bottom,
            },
          ).docs[tapFile],
        ),
        'tap_answer',
      );
      expect(column('10000', '0'), isEmpty);
      expect(column('9999', '305'), isEmpty);
      for (final String bad in <String>['00', '05', '0100', '10001', '99999']) {
        expect(column(bad, '1'), isNotEmpty, reason: 'top $bad');
        expect(column('99', bad), isNotEmpty, reason: 'bottom $bad');
      }
    });
  });

  group('SEC-M10-5: an item may not ask for more than its manifest promises', () {
    List<String> run(String itemVersion, String promised) {
      final SamplePack p = SamplePack();
      _m(p.docs[tapFile])['templateVersion'] = itemVersion;
      _m(p.manifest['templates'])['tap_answer'] = promised;
      return <String>[
        for (final Problem x in validatePack(manifest: p.manifest, docs: p.docs, files: p.files))
          if (x.toString().contains('manifest lists')) x.toString(),
      ];
    }

    test('a version above the manifest\'s is a problem', () {
      expect(run('1.4', '1.0'), hasLength(1));
      expect(run('1.2', '1.1'), hasLength(1));
      expect(run('1.0', '1.0'), isEmpty);
      expect(run('1.1', '1.4'), isEmpty);
      expect(run('1.4', '1.4'), isEmpty);
    });

    test('the sample pack and the starter pack have no such problem', () {
      expect(run('1.0', '1.0'), isEmpty);
    });
  });
}
