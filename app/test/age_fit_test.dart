// B-29 step 4: the age service. The school stage sets the band (synced); the month and year of birth, kept on the device, give the
// age in months and the presentation stage P1 to P4 (never synced); a band-only profile gets the middle of its band.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/engine/age.dart';

void main() {
  group('the school stage', () {
    test('the six words and their bands are the ones in testvectors/profile-sync.json (the gateway has the same)', () {
      final Map<String, Object?> v =
          jsonDecode(File('../testvectors/profile-sync.json').readAsStringSync()) as Map<String, Object?>;
      expect(<String>[for (final SchoolStage s in SchoolStage.values) s.wire], v['school_stages']);
      final Map<String, Object?> bands = v['band_of_stage']! as Map<String, Object?>;
      for (final SchoolStage s in SchoolStage.values) {
        expect(s.band, bands[s.wire], reason: s.wire);
      }
    });

    test('gan 3 and 4 are Band A, gan 5 and grade 1 Band B, grades 2 and 3 Band C', () {
      expect(<int>[for (final SchoolStage s in SchoolStage.values) s.band], <int>[0, 0, 1, 1, 2, 2]);
    });

    test('a word is read only when it is exactly one of the six', () {
      for (final SchoolStage s in SchoolStage.values) {
        expect(SchoolStage.fromWire(s.wire), s);
      }
      for (final Object? bad in <Object?>[
        null,
        '',
        'grade4',
        'Gan3',
        ' gan3',
        'grade 1',
        1,
        <String>['gan3'],
        '2020-05',
      ]) {
        expect(SchoolStage.fromWire(bad), isNull, reason: '$bad');
      }
    });

    test('the next stage is the one after; a child at grade 3 stays at grade 3', () {
      expect(SchoolStage.gan3.next, SchoolStage.gan4);
      expect(SchoolStage.gan5.next, SchoolStage.grade1);
      expect(SchoolStage.grade2.next, SchoolStage.grade3);
      expect(SchoolStage.grade3.next, SchoolStage.grade3, reason: 'older than grade 3 stays grade 3, Band C');
    });

    test('a band-only profile gets the middle stage of its band', () {
      expect(SchoolStage.middleOfBand(0), SchoolStage.gan4);
      expect(SchoolStage.middleOfBand(1), SchoolStage.gan5);
      expect(SchoolStage.middleOfBand(2), SchoolStage.grade2);
      for (int b = 0; b < 3; b++) {
        expect(SchoolStage.middleOfBand(b).band, b);
      }
      expect(SchoolStage.middleOfBand(-1).band, 0);
      expect(SchoolStage.middleOfBand(7).band, 2);
    });
  });

  group('the month and year of birth', () {
    final DateTime now = DateTime(2026, 11, 6);

    test('a month from 1 to 12 and a year in the past, up to the age of nine, are valid', () {
      expect(BirthMonth.tryCreate(2021, 5, now: now), const BirthMonth(2021, 5));
      expect(BirthMonth.tryCreate(2026, 11, now: now), const BirthMonth(2026, 11), reason: 'born this month');
      expect(
        BirthMonth.tryCreate(2016, 12, now: now),
        const BirthMonth(2016, 12),
        reason: '9;11, the oldest',
      );
    });

    test('a month outside 1 to 12, a month in the future and a child of ten are refused', () {
      for (final (int, int) bad in <(int, int)>[
        (2021, 0),
        (2021, 13),
        (2021, -1),
        (2026, 12),
        (2027, 1),
        (2016, 11),
        (1999, 5),
        (20210, 5),
      ]) {
        expect(BirthMonth.tryCreate(bad.$1, bad.$2, now: now), isNull, reason: '$bad');
      }
    });

    test('the age in months counts whole calendar months, with no day', () {
      expect(ageInMonths(const BirthMonth(2021, 5), DateTime(2026, 11, 6)), 66);
      expect(ageInMonths(const BirthMonth(2021, 5), DateTime(2026, 11, 30)), 66);
      expect(ageInMonths(const BirthMonth(2021, 5), DateTime(2026, 12, 1)), 67);
      expect(ageInMonths(const BirthMonth(2026, 11), DateTime(2026, 11, 6)), 0);
    });
  });

  group('the presentation stage from the age in months', () {
    test('P1 up to 3;5, P2 3;6 to 4;11, P3 5;0 to 6;5, P4 6;6 and up', () {
      PresentationStage at(int years, int months) => PresentationStage.forAgeInMonths(years * 12 + months);
      expect(at(0, 0), PresentationStage.p1);
      expect(at(2, 11), PresentationStage.p1);
      expect(at(3, 5), PresentationStage.p1);
      expect(at(3, 6), PresentationStage.p2);
      expect(at(4, 11), PresentationStage.p2);
      expect(at(5, 0), PresentationStage.p3);
      expect(at(6, 5), PresentationStage.p3);
      expect(at(6, 6), PresentationStage.p4);
      expect(at(8, 11), PresentationStage.p4);
      expect(at(12, 0), PresentationStage.p4);
    });

    test('a number below zero is the youngest, not an error', () {
      expect(PresentationStage.forAgeInMonths(-5), PresentationStage.p1);
    });
  });

  group('everything a child is known by, from the band, the stage and the month of birth', () {
    final DateTime now = DateTime(2026, 11, 6);

    test('a band-only profile gets the middle of its band: A 4;0, B 6;0, C 7;6', () {
      final ChildAge a = childAge(band: 0, now: now);
      final ChildAge b = childAge(band: 1, now: now);
      final ChildAge c = childAge(band: 2, now: now);
      expect(
        <int?>[a.months, b.months, c.months],
        <int?>[null, null, null],
        reason: 'no birth month is known',
      );
      expect(<int>[a.assumedMonths, b.assumedMonths, c.assumedMonths], <int>[48, 72, 90]);
      expect(
        <PresentationStage>[a.presentation, b.presentation, c.presentation],
        <PresentationStage>[PresentationStage.p2, PresentationStage.p3, PresentationStage.p4],
      );
      expect(
        <SchoolStage>[a.stage, b.stage, c.stage],
        <SchoolStage>[SchoolStage.gan4, SchoolStage.gan5, SchoolStage.grade2],
      );
      expect(<bool>[a.stageConfirmed, b.stageConfirmed, c.stageConfirmed], <bool>[false, false, false]);
    });

    test('a confirmed school stage sets the band, whatever the band the row still says', () {
      final ChildAge age = childAge(band: 0, stage: SchoolStage.grade2, now: now);
      expect(age.stage, SchoolStage.grade2);
      expect(age.band, 2);
      expect(age.stageConfirmed, isTrue);
    });

    test(
      'the month and year give the age in months and the look; the band does not follow the age in months',
      () {
        // A child of 4;0 in grade 2 (a young child at a high stage): the look follows the age, the band the stage.
        final ChildAge age = childAge(
          band: 2,
          stage: SchoolStage.grade2,
          birth: const BirthMonth(2022, 11),
          now: now,
        );
        expect(age.months, 48);
        expect(age.presentation, PresentationStage.p2);
        expect(age.band, 2);
        // And a 7-year-old on Band A content gets the P4 look.
        final ChildAge older = childAge(
          band: 0,
          stage: SchoolStage.gan4,
          birth: const BirthMonth(2019, 3),
          now: now,
        );
        expect(older.band, 0);
        expect(older.presentation, PresentationStage.p4);
      },
    );

    test('the band is the stage\'s band for all six stages, with or without a month of birth', () {
      for (final SchoolStage s in SchoolStage.values) {
        expect(childAge(band: s.band, stage: s, now: now).band, s.band);
        expect(childAge(band: s.band, stage: s, birth: const BirthMonth(2021, 1), now: now).band, s.band);
      }
    });

    test('a month later the look can change, and the band and the school stage never do', () {
      const BirthMonth born = BirthMonth(2020, 5);
      final ChildAge before = childAge(
        band: 1,
        stage: SchoolStage.gan5,
        birth: born,
        now: DateTime(2026, 10, 31),
      );
      final ChildAge after = childAge(
        band: 1,
        stage: SchoolStage.gan5,
        birth: born,
        now: DateTime(2026, 11, 1),
      );
      expect(before.months, 77);
      expect(before.presentation, PresentationStage.p3);
      expect(after.months, 78);
      expect(after.presentation, PresentationStage.p4);
      expect(after.band, before.band);
      expect(after.stage, before.stage);
    });
  });
}
