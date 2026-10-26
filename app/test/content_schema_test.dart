import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/content/schema.dart';
import 'package:nitznutz/content/schemas.dart';

import 'support/sample_pack.dart';

List<String> _paths(List<Problem> ps) => <String>[for (final Problem p in ps) p.toString()];

void main() {
  group('schema language', () {
    test('a string must match its whole pattern, not just contain it', () {
      const SString s = SString(pattern: r'a|b');
      expect(validate(s, 'a'), isEmpty);
      expect(validate(s, 'ab'), isNotEmpty);
      expect(validate(s, 'xa'), isNotEmpty);
    });

    test('strings reject control characters, wrong length and wrong type', () {
      const SString s = SString(minLength: 2, maxLength: 4);
      expect(validate(s, 'ab'), isEmpty);
      expect(_paths(validate(s, 'a')), <String>['length 1 is outside 2 to 4']);
      expect(_paths(validate(s, 'abcde')), <String>['length 5 is outside 2 to 4']);
      expect(_paths(validate(s, 'a\nb')), <String>['contains a control character']);
      expect(_paths(validate(s, 'a\u0000b')), <String>['contains a control character']);
      expect(_paths(validate(s, 3)), <String>['expected a string, found an integer']);
      expect(_paths(validate(s, null)), <String>['expected a string, found null']);
    });

    test('an integer field refuses 1.0, strings and out-of-range values', () {
      const SInt i = SInt(min: 1, max: 3);
      expect(validate(i, 2), isEmpty);
      expect(validate(i, 4), isNotEmpty);
      expect(validate(i, 0), isNotEmpty);
      expect(_paths(validate(i, 1.5)), <String>['expected an integer, found a number']);
      expect(_paths(validate(i, '2')), <String>['expected an integer, found a string']);
      expect(_paths(validate(i, true)), <String>['expected an integer, found a boolean']);
    });

    test('a number field takes whole numbers too, and refuses NaN and out of range', () {
      const SNum n = SNum(min: 0, max: 1);
      expect(validate(n, 1), isEmpty);
      expect(validate(n, 0.25), isEmpty);
      expect(validate(n, 1.5), isNotEmpty);
      expect(validate(n, double.nan), isNotEmpty);
    });

    test('enum and const', () {
      expect(validate(const SEnum(<String>['a', 'b']), 'a'), isEmpty);
      expect(_paths(validate(const SEnum(<String>['a', 'b']), 'c')), <String>['must be one of a, b']);
      expect(validate(const SConst('x'), 'x'), isEmpty);
      expect(_paths(validate(const SConst('x'), 'y')), <String>['must be "x"']);
    });

    test('arrays check their length, their elements and the unique key', () {
      const SArray a = SArray(
        SObject(<String, SField>{'id': SField(SString())}),
        minItems: 1,
        maxItems: 2,
        uniqueKey: 'id',
      );
      expect(
        validate(a, <Object?>[
          <String, Object?>{'id': 'a'},
        ]),
        isEmpty,
      );
      expect(_paths(validate(a, <Object?>[])), <String>['0 items is outside 1 to 2']);
      expect(
        _paths(
          validate(a, <Object?>[
            <String, Object?>{'id': 'a'},
            <String, Object?>{'id': 'a'},
          ]),
        ),
        <String>['[1].id: is used twice'],
      );
      expect(_paths(validate(a, <Object?>[3])), <String>['[0]: expected an object, found an integer']);
    });

    test('an object refuses unknown fields, reports missing ones and lets optional ones go', () {
      const SObject o = SObject(<String, SField>{
        'a': SField(SInt(min: 0, max: 9)),
        'b': SField(SInt(min: 0, max: 9), required: false),
      });
      expect(validate(o, <String, Object?>{'a': 1}), isEmpty);
      expect(validate(o, <String, Object?>{'a': 1, 'b': 2}), isEmpty);
      expect(_paths(validate(o, <String, Object?>{'b': 2})), <String>['missing "a"']);
      expect(_paths(validate(o, <String, Object?>{'a': 1, 'c': 3})), <String>['unknown field "c"']);
      expect(_paths(validate(o, <Object?>[])), <String>['expected an object, found a list']);
    });

    test('problems name the exact path of nested values', () {
      const SObject o = SObject(<String, SField>{
        'list': SField(SArray(SObject(<String, SField>{'n': SField(SInt(min: 0, max: 1))}))),
      });
      final List<Problem> ps = validate(o, <String, Object?>{
        'list': <Object?>[
          <String, Object?>{'n': 0},
          <String, Object?>{'n': 5},
        ],
      });
      expect(ps, hasLength(1));
      expect(ps.single.path, 'list[1].n');
    });
  });

  group('JSON Schema export', () {
    test('every object closes its fields and lists the required ones', () {
      void walk(Object? node) {
        if (node is Map<String, Object?>) {
          if (node['type'] == 'object' && node.containsKey('properties')) {
            expect(node['additionalProperties'], false);
            final Map<String, Object?> props = node['properties']! as Map<String, Object?>;
            for (final Object? r in node['required']! as List<Object?>) {
              expect(props.containsKey(r), isTrue);
            }
          }
          node.values.forEach(walk);
        } else if (node is List<Object?>) {
          node.forEach(walk);
        }
      }

      for (final MapEntry<String, Schema> e in allSchemas.entries) {
        final Map<String, Object?> js = toJsonSchema(e.value, id: 'nitznutz/${e.key}');
        expect(js[r'$id'], 'nitznutz/${e.key}');
        walk(js);
      }
    });

    test('there is a schema for every template the app can play', () {
      for (final String t in supportedTemplates.keys) {
        expect(activitySchemaFor(t), isNotNull, reason: t);
        expect(allSchemas.containsKey('activity.$t'), isTrue, reason: t);
      }
      expect(activitySchemaFor('drag_sort'), isNull);
    });

    test('the sample pack passes the schemas it is built from', () {
      final SamplePack p = SamplePack();
      expect(validate(manifestSchema, p.manifest), isEmpty);
      expect(validate(activitySchemaFor('count_tap')!, p.doc(countFile)), isEmpty);
      expect(validate(activitySchemaFor('tap_answer')!, p.doc(tapFile)), isEmpty);
      expect(validate(activitySchemaFor('give_n')!, p.doc(giveFile)), isEmpty);
      expect(validate(lessonSchema, p.doc(lessonFile)), isEmpty);
      expect(validate(skillSchema, p.doc(skillFile)), isEmpty);
      expect(validate(misconceptionSchema, p.doc(tagFile)), isEmpty);
    });
  });
}
