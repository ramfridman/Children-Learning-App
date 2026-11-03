// B-42 part (d): how a child's name is said. The app, the gateway and the database take the same spellings
// (testvectors/name-spoken.json); this side proves what the app's rule takes and refuses.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/data/child_name.dart';

class Vector {
  Vector(Map<String, Object?> json)
    : name = json['name']! as String,
      value = json['value']! as String,
      units = json['units']! as int;

  final String name;
  final String value;
  final int units;
}

void main() {
  final Map<String, Object?> doc =
      jsonDecode(File('../testvectors/name-spoken.json').readAsStringSync()) as Map<String, Object?>;
  List<Vector> vectors(String key) => <Vector>[
    for (final Object? v in doc[key]! as List<Object?>) Vector(v! as Map<String, Object?>),
  ];
  final List<Vector> accept = vectors('accept');
  final List<Vector> reject = vectors('reject');

  test('the limit is the shared one', () {
    expect(spokenNameMaxLength, doc['max_utf16_units']);
  });

  test('every vector is as long as it says, in UTF-16 units (the app counts them as the server does)', () {
    for (final Vector v in <Vector>[...accept, ...reject]) {
      expect(v.value.length, v.units, reason: v.name);
    }
  });

  test('the app takes every accepted spelling and refuses every rejected one', () {
    expect(accept.length, greaterThanOrEqualTo(10));
    expect(reject.length, greaterThanOrEqualTo(25));
    for (final Vector v in accept) {
      expect(isSpokenName(v.value), isTrue, reason: 'takes ${v.name}');
      expect(validateSpokenName(v.value), SpokenNameProblem.ok, reason: v.name);
    }
    for (final Vector v in reject) {
      expect(isSpokenName(v.value), isFalse, reason: 'refuses ${v.name}');
    }
  });

  test('the form trims first, says what is wrong, and an empty field is fine (it clears the spelling)', () {
    expect(validateSpokenName(''), SpokenNameProblem.ok);
    expect(validateSpokenName('   '), SpokenNameProblem.ok);
    expect(validateSpokenName('  נועה  '), SpokenNameProblem.ok, reason: 'trimmed before it is checked');
    expect(validateSpokenName('Noa'), SpokenNameProblem.badChars);
    expect(validateSpokenName('נועה!'), SpokenNameProblem.badChars);
    expect(validateSpokenName('א' * 25), SpokenNameProblem.tooLong);
    expect(validateSpokenName('א' * 24), SpokenNameProblem.ok);
    expect(isSpokenName('  נועה'), isFalse, reason: 'the strict check does not trim');
  });

  test('the app\'s rule and the shared pattern give the same answer to every vector', () {
    final RegExp shared = RegExp(doc['server_pattern']! as String);
    for (final Vector v in <Vector>[...accept, ...reject]) {
      expect(
        isSpokenName(v.value),
        v.value.length <= spokenNameMaxLength && shared.hasMatch(v.value),
        reason: v.name,
      );
    }
  });
}
