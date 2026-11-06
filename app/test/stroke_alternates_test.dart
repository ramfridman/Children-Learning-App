// The other right builds of a letter (QA-L52-1): the stroke data lists a few, the schema bounds them, and the check reads each as its own letter
// and as no other. The builds are in `content/languages/strokes/*.json`, made by `tools/strokes_alternates.py`.
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/content/schema.dart';
import 'package:nitznutz/content/schemas.dart';
import 'package:nitznutz/content/strokes.dart';
import 'package:nitznutz/play/stroke_check.dart';

import 'support/ls02_content.dart' show strokeSetDoc;
import 'support/stroke_hands.dart';

/// The pilot letters that have other builds, and how many (docs/languages/strokes.md section 5.4).
const Map<String, int> _expected = <String, int>{
  'latin.a': 2,
  'latin.d': 2,
  'latin.t': 1,
  'latin.n': 1,
  'latin.b': 1,
  'latin.p': 1,
  'cyrillic.a': 2,
  'cyrillic.a.cap': 1,
  'cyrillic.em.cap': 3,
  'cyrillic.em': 3,
  'hebrew-print.bet': 1,
  'hebrew-print.shin': 1,
};

Map<String, Object?> _copy(Map<String, Object?> doc) => jsonDecode(jsonEncode(doc))! as Map<String, Object?>;

Map<String, Object?> _form(Map<String, Object?> doc, String id) => (doc['forms']! as List<Object?>)
    .cast<Map<String, Object?>>()
    .firstWhere((Map<String, Object?> f) => f['id'] == id);

void main() {
  group('the builds in the data', () {
    test('are the ones listed, and every one is within the caps', () {
      final Map<String, int> found = <String, int>{};
      for (final StrokeSet set in strokeSets.values) {
        for (final StrokeForm f in set.forms.values) {
          if (f.alternates.isEmpty) continue;
          found[f.id] = f.alternates.length;
          expect(f.alternates.length, lessThanOrEqualTo(4), reason: f.id);
          for (final List<StrokeModel> build in f.alternates) {
            expect(build.length, inInclusiveRange(1, 6), reason: f.id);
            for (final StrokeModel s in build) {
              expect(s.points.length, inInclusiveRange(2, 60), reason: f.id);
              for (final Offset p in s.points) {
                expect(p.dx, inInclusiveRange(0, 100));
                expect(p.dy, inInclusiveRange(0, 100));
              }
            }
          }
        }
      }
      expect(found, _expected);
    });

    test('each is its own letter and is not counted for any other letter of the script', () {
      // The strokes alone can complete a smaller letter (the ball of an a is an o): what counts is the whole drawing read against the script.
      final List<String> confused = <String>[];
      for (final StrokeSet set in strokeSets.values) {
        for (final StrokeForm f in set.forms.values) {
          for (final (int i, List<StrokeModel> build) in f.alternates.indexed) {
            final List<List<Offset>> written = <List<Offset>>[for (final StrokeModel s in build) s.points];
            expect(
              countedForTarget(f, set.forms.values, written),
              isTrue,
              reason: '${f.id} build ${i + 1} is its own letter',
            );
            for (final StrokeForm other in set.forms.values) {
              if (other.id != f.id && countedForTarget(other, set.forms.values, written)) {
                confused.add('${f.id} build ${i + 1} is counted for ${other.id}');
              }
            }
          }
        }
      }
      expect(confused, isEmpty, reason: confused.join('; '));
    });

    test('are read by the check: a ball and a stick is an a, a stick and an arch an n, a zig-zag an M', () {
      for (final (String id, int build) in <(String, int)>[
        ('latin.a', 0),
        ('latin.a', 1),
        ('latin.d', 0),
        ('latin.n', 0),
        ('latin.b', 0),
        ('latin.p', 0),
        ('cyrillic.a', 0),
        ('cyrillic.em.cap', 0),
        ('hebrew-print.shin', 0),
      ]) {
        final StrokeForm f = strokeForm(id);
        final LetterChecker c = LetterChecker(f);
        for (final StrokeModel s in f.alternates[build]) {
          expect(c.check(s.points).right, isTrue, reason: '$id build ${build + 1}');
        }
        expect(c.complete, isTrue, reason: id);
        expect(c.matched, f.alternates[build].length, reason: id);
      }
    });

    test('a letter that starts on one build cannot finish on another', () {
      final StrokeForm a = strokeForm('latin.a');
      final LetterChecker c = LetterChecker(a);
      expect(c.check(a.alternates[0][0].points).right, isTrue, reason: 'the ball');
      // The model's single stroke (ball and stem in one) no longer fits: the child is on the build of a ball and a stick.
      expect(c.check(a.strokes.first.points).right, isFalse);
      expect(c.complete, isFalse);
      expect(c.next, 1, reason: 'the help points at the stick, the stroke of the build the child is on');
      expect(c.check(a.alternates[0][1].points).right, isTrue, reason: 'the stick');
      expect(c.complete, isTrue);
    });
  });

  group('the schema bounds the builds', () {
    Map<String, Object?> latin() => _copy(strokeSetDoc('latin'));

    test('the real sets pass', () {
      for (final String n in <String>['latin', 'cyrillic', 'hebrew-print', 'hebrew-script']) {
        expect(validate(strokesSchema, strokeSetDoc(n)), isEmpty, reason: n);
      }
    });

    test(
      'five builds, seven strokes in a build, a path, a point outside the box or an unknown key are refused',
      () {
        List<Object?> builds(Map<String, Object?> d) => _form(d, 'latin.a')['alternates']! as List<Object?>;
        Map<String, Object?> build0(Map<String, Object?> d) => builds(d).first! as Map<String, Object?>;
        Map<String, Object?> stroke0(Map<String, Object?> d) =>
            (build0(d)['strokes']! as List<Object?>).first! as Map<String, Object?>;

        Map<String, Object?> d = latin();
        builds(d).addAll(<Object?>[for (int i = 0; i < 3; i++) _copy(build0(d))]);
        expect(builds(d).length, 5);
        expect(validate(strokesSchema, d).map((Problem p) => p.path).join(), contains('alternates'));

        d = latin();
        build0(d)['strokes'] = <Object?>[for (int i = 0; i < 7; i++) _copy(stroke0(d))];
        expect(validate(strokesSchema, d), isNotEmpty);

        d = latin();
        stroke0(d)['d'] = 'M 5 5 L 90 90';
        expect(validate(strokesSchema, d), isNotEmpty, reason: 'a build is never drawn, so it has no path');

        d = latin();
        (stroke0(d)['points']! as List<Object?>)[0] = <Object?>[101, 3];
        expect(validate(strokesSchema, d), isNotEmpty);

        d = latin();
        stroke0(d)['points'] = <Object?>[
          for (int i = 0; i < 61; i++) <Object?>[i, i],
        ];
        expect(validate(strokesSchema, d), isNotEmpty);

        d = latin();
        build0(d)['how'] = '<script>';
        expect(validate(strokesSchema, d), isNotEmpty);

        d = latin();
        build0(d)['unknown'] = 1;
        expect(validate(strokesSchema, d), isNotEmpty);
      },
    );
  });
}
