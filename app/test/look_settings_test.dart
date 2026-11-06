// B-29 step 4: the look a parent chose for a child travels with the family's rules as one letter (A, B or C), like a language's
// level. Read from a document it is checked again: a damaged or hand-edited value is dropped, never turned into something else.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/parent/look_settings.dart';

void main() {
  final Map<String, Object?> v =
      jsonDecode(File('../testvectors/profile-sync.json').readAsStringSync()) as Map<String, Object?>;

  test(
    'the app and the gateway agree on the letters and on how many children (testvectors/profile-sync.json)',
    () {
      expect(lookLetters, v['look_letters']);
      expect(maxLookChildren, v['max_look_children']);
    },
  );

  test('every example the gateway takes is read and written again unchanged', () {
    for (final Object? example in v['look_examples']! as List<Object?>) {
      final FamilyLooks looks = FamilyLooks.fromJson(example);
      expect(looks.toJson(), example);
      expect(FamilyLooks.decode(looks.encode()).toJson(), example);
    }
  });

  test('everything the gateway refuses is read as no look at all, or with the bad child left out', () {
    for (final Object? refused in v['look_refused']! as List<Object?>) {
      final FamilyLooks looks = FamilyLooks.fromJson(refused);
      // Whatever is left is something the gateway would take.
      final Map<String, Object?> json = looks.toJson();
      expect(json.length, lessThanOrEqualTo(maxLookChildren));
      for (final MapEntry<String, Object?> e in json.entries) {
        expect(RegExp(r'^[A-Za-z0-9-]{8,64}$').hasMatch(e.key), isTrue);
        expect(lookLetters, contains(e.value));
      }
    }
    expect(FamilyLooks.fromJson(<String, Object?>{'child-aaaa-0001': 'D'}).isEmpty, isTrue);
    expect(FamilyLooks.fromJson(<String, Object?>{'child-aaaa-0001': 1}).isEmpty, isTrue);
    expect(FamilyLooks.fromJson(<String, Object?>{'short': 'A'}).isEmpty, isTrue);
    expect(FamilyLooks.fromJson('A').isEmpty, isTrue);
    expect(FamilyLooks.decode('not json').isEmpty, isTrue);
    expect(FamilyLooks.decode(null).isEmpty, isTrue);
  });

  test('a look is a band: A, B and C are 0, 1 and 2, and a child with none has no override', () {
    final FamilyLooks looks = FamilyLooks.fromJson(<String, Object?>{
      'child-aaaa-0001': 'A',
      'child-aaaa-0002': 'C',
    });
    expect(looks.bandOf('child-aaaa-0001'), 0);
    expect(looks.bandOf('child-aaaa-0002'), 2);
    expect(looks.bandOf('child-aaaa-0003'), isNull);
  });

  test('setting, replacing and clearing a look', () {
    FamilyLooks looks = const FamilyLooks();
    looks = looks.withBand('child-aaaa-0001', 1)!;
    expect(looks.bandOf('child-aaaa-0001'), 1);
    looks = looks.withBand('child-aaaa-0001', 2)!;
    expect(looks.bandOf('child-aaaa-0001'), 2);
    looks = looks.withBand('child-aaaa-0001', null)!;
    expect(
      looks.isEmpty,
      isTrue,
      reason: 'no look is no key: a family that never sets one syncs what it did before',
    );
  });

  test('a seventh child, a bad id and a band outside 0 to 2 are refused', () {
    FamilyLooks looks = const FamilyLooks();
    for (int i = 1; i <= maxLookChildren; i++) {
      looks = looks.withBand('child-aaaa-000$i', i % 3)!;
    }
    expect(looks.withBand('child-aaaa-0007', 1), isNull);
    expect(looks.withBand('child-aaaa-0001', 2), isNotNull, reason: 'a child who has one may change it');
    expect(const FamilyLooks().withBand('x', 1), isNull);
    expect(const FamilyLooks().withBand('child-aaaa-0001', 3), isNull);
    expect(const FamilyLooks().withBand('child-aaaa-0001', -1), isNull);
  });

  test('a child who is removed takes the look with them', () {
    final FamilyLooks looks = FamilyLooks.fromJson(<String, Object?>{
      'child-aaaa-0001': 'A',
      'child-aaaa-0002': 'B',
    });
    final FamilyLooks left = looks.without('child-aaaa-0001');
    expect(left.bandOf('child-aaaa-0001'), isNull);
    expect(left.bandOf('child-aaaa-0002'), 1);
  });

  test(
    'the document is in the same order whoever wrote it, so the fingerprint of the rules does not flicker',
    () {
      final FamilyLooks a = FamilyLooks.fromJson(<String, Object?>{
        'child-bbbb-0002': 'B',
        'child-aaaa-0001': 'A',
      });
      final FamilyLooks b = FamilyLooks.fromJson(<String, Object?>{
        'child-aaaa-0001': 'A',
        'child-bbbb-0002': 'B',
      });
      expect(jsonEncode(a.toJson()), jsonEncode(b.toJson()));
      expect(a.encode(), b.encode());
    },
  );
}
