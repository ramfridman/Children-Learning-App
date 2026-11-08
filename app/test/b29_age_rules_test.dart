// B-29 steps 5b, 6 and 7: the pure rules of the age settings. The stage a birth year suggests, the look a letter gives, the captions by
// school stage, the September card and the "add the age" card, and a gate's minimum age in months. No widget here.
import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/engine/age.dart';

ChildAge _age({int band = 1, SchoolStage? stage, BirthMonth? birth, DateTime? now}) =>
    childAge(band: band, stage: stage, birth: birth, now: now ?? DateTime(2026, 11, 8));

void main() {
  group('suggestedStage: the Israeli cohort is the calendar year of birth', () {
    test('born 2021, in November 2026, is in gan hova', () {
      expect(suggestedStage(2021, DateTime(2026, 11, 8)), SchoolStage.gan5);
    });

    test('the school year changes on 1 September, not before', () {
      expect(suggestedStage(2021, DateTime(2026, 8, 31)), SchoolStage.gan4);
      expect(suggestedStage(2021, DateTime(2026, 9, 1)), SchoolStage.gan5);
      expect(suggestedStage(2021, DateTime(2027, 8, 31)), SchoolStage.gan5);
      expect(suggestedStage(2021, DateTime(2027, 9, 1)), SchoolStage.grade1);
    });

    test('a very young cohort is gan 3 and an old one stays grade 3', () {
      expect(suggestedStage(2025, DateTime(2026, 11, 8)), SchoolStage.gan3);
      expect(suggestedStage(2024, DateTime(2026, 11, 8)), SchoolStage.gan3);
      expect(suggestedStage(2017, DateTime(2026, 11, 8)), SchoolStage.grade3);
      expect(suggestedStage(2010, DateTime(2026, 11, 8)), SchoolStage.grade3);
    });

    test('each cohort year gives the next stage in order', () {
      final List<SchoolStage> got = <SchoolStage>[
        for (int y = 2023; y >= 2018; y--) suggestedStage(y, DateTime(2026, 11, 8)),
      ];
      expect(got, SchoolStage.values);
    });
  });

  group('schoolYearOf', () {
    test('the school year starts on 1 September', () {
      expect(schoolYearOf(DateTime(2026, 8, 31)), 2025);
      expect(schoolYearOf(DateTime(2026, 9, 1)), 2026);
      expect(schoolYearOf(DateTime(2027, 1, 15)), 2026);
      expect(schoolYearOf(DateTime(2026, 12, 31)), 2026);
    });
  });

  group('effectiveStage: the look a child sees', () {
    final BirthMonth p1 = const BirthMonth(2023, 6); // 3;5 in November 2026
    final BirthMonth p3 = const BirthMonth(2021, 3); // 5;8
    final BirthMonth p4 = const BirthMonth(2019, 5); // 7;6

    test('with no letter, the look follows the age', () {
      expect(effectiveStage(_age(birth: p1)), PresentationStage.p1);
      expect(effectiveStage(_age(birth: p3)), PresentationStage.p3);
      expect(effectiveStage(_age(birth: p4)), PresentationStage.p4);
    });

    test('with no month and year it is the middle of the band', () {
      expect(effectiveStage(_age(band: 0)), PresentationStage.p2);
      expect(effectiveStage(_age(band: 1)), PresentationStage.p3);
      expect(effectiveStage(_age(band: 2)), PresentationStage.p4);
    });

    test('a letter clamps the stage into its band: A is P1 or P2, B is P3, C is P4', () {
      expect(effectiveStage(_age(birth: p3), lookBand: 0), PresentationStage.p2);
      expect(effectiveStage(_age(birth: p4), lookBand: 0), PresentationStage.p2);
      expect(
        effectiveStage(_age(birth: p1), lookBand: 0),
        PresentationStage.p1,
        reason: 'a younger look never ages a 3;2 child',
      );
      expect(effectiveStage(_age(birth: p1), lookBand: 1), PresentationStage.p3);
      expect(effectiveStage(_age(birth: p3), lookBand: 2), PresentationStage.p4);
    });

    test('a course\'s own choice wins over the look letter, inside that course', () {
      expect(effectiveStage(_age(birth: p3), lookBand: 2, courseBand: 0), PresentationStage.p2);
      expect(effectiveStage(_age(birth: p3), lookBand: 0, courseBand: 2), PresentationStage.p4);
      expect(effectiveStage(_age(birth: p3), courseBand: 1), PresentationStage.p3);
    });

    test('a birthday never moves the look until the age is read again, and the look is a pure function of what it is given', () {
      final ChildAge a = _age(birth: p3);
      expect(effectiveStage(a), effectiveStage(a));
      expect(a.months, 68);
    });
  });

  group('captions: by school stage unless the parent chose', () {
    test('gan 3 and gan 4 hide, gan 5 to grade 3 show', () {
      expect(
        <bool>[for (final SchoolStage s in SchoolStage.values) captionsShownFor(s, CaptionSetting.auto)],
        <bool>[false, false, true, true, true, true],
      );
    });

    test('show and hide win over the stage', () {
      for (final SchoolStage s in SchoolStage.values) {
        expect(captionsShownFor(s, CaptionSetting.on), isTrue);
        expect(captionsShownFor(s, CaptionSetting.off), isFalse);
      }
    });

    test('the setting is read from its word, and anything else is "by stage"', () {
      expect(CaptionSetting.fromWord('on'), CaptionSetting.on);
      expect(CaptionSetting.fromWord('off'), CaptionSetting.off);
      expect(CaptionSetting.fromWord('auto'), CaptionSetting.auto);
      for (final String? bad in <String?>[null, '', 'ON', 'yes', 'on ']) {
        expect(CaptionSetting.fromWord(bad), CaptionSetting.auto, reason: '$bad');
      }
    });
  });

  group('the September card', () {
    test('31 August: no card; 1 September: the card', () {
      expect(
        septemberCardDue(stage: SchoolStage.gan5, confirmedYear: 2025, now: DateTime(2026, 8, 31)),
        isFalse,
      );
      expect(
        septemberCardDue(stage: SchoolStage.gan5, confirmedYear: 2025, now: DateTime(2026, 9, 1)),
        isTrue,
      );
      expect(
        septemberCardDue(stage: SchoolStage.gan5, confirmedYear: 2025, now: DateTime(2027, 5, 1)),
        isTrue,
      );
    });

    test('grade 3 never gets one', () {
      expect(
        septemberCardDue(stage: SchoolStage.grade3, confirmedYear: 2020, now: DateTime(2026, 10, 1)),
        isFalse,
      );
    });

    test('an answered card is gone until the next September', () {
      expect(
        septemberCardDue(stage: SchoolStage.gan5, confirmedYear: 2026, now: DateTime(2026, 9, 2)),
        isFalse,
      );
      expect(
        septemberCardDue(stage: SchoolStage.gan5, confirmedYear: 2026, now: DateTime(2027, 8, 31)),
        isFalse,
      );
      expect(
        septemberCardDue(stage: SchoolStage.gan5, confirmedYear: 2026, now: DateTime(2027, 9, 1)),
        isTrue,
      );
    });

    test(
      'a stage with no year recorded (confirmed before this) asks once, in the first school year it is seen',
      () {
        expect(
          septemberCardDue(stage: SchoolStage.gan4, confirmedYear: null, now: DateTime(2026, 11, 8)),
          isFalse,
        );
      },
    );

    test('a child with no confirmed stage gets the other card, not this one', () {
      expect(septemberCardDue(stage: null, confirmedYear: null, now: DateTime(2026, 11, 8)), isFalse);
    });
  });

  group('the "add the age" card', () {
    test('shown for a child with no confirmed stage', () {
      expect(addAgeCardDue(stage: null, hiddenYear: null, now: DateTime(2026, 11, 8)), isTrue);
      expect(addAgeCardDue(stage: SchoolStage.gan5, hiddenYear: null, now: DateTime(2026, 11, 8)), isFalse);
    });

    test('"not now" hides it on this device until the next 1 September', () {
      expect(addAgeCardDue(stage: null, hiddenYear: 2026, now: DateTime(2026, 11, 8)), isFalse);
      expect(addAgeCardDue(stage: null, hiddenYear: 2026, now: DateTime(2027, 8, 31)), isFalse);
      expect(addAgeCardDue(stage: null, hiddenYear: 2026, now: DateTime(2027, 9, 1)), isTrue);
    });
  });

  group('a gate\'s minimum age', () {
    test('reads the age in months when the month and year are known', () {
      final ChildAge fiveOh = _age(band: 0, birth: const BirthMonth(2021, 11)); // 60 months: 5;0
      final ChildAge fourEleven = _age(band: 0, birth: const BirthMonth(2021, 12)); // 59 months
      expect(oldEnough(fiveOh, minYears: 5), isTrue);
      expect(oldEnough(fourEleven, minYears: 5), isFalse);
    });

    test('with no month and year it falls back to the band\'s age (3, 5, 7), as it did', () {
      expect(oldEnough(_age(band: 0), minYears: 5), isFalse);
      expect(oldEnough(_age(band: 1), minYears: 5), isTrue);
      expect(oldEnough(_age(band: 1), minYears: 7), isFalse);
      expect(oldEnough(_age(band: 2), minYears: 7), isTrue);
    });

    test('a known birth month beats the band: a Band B child of 4;11 is not yet 5', () {
      expect(oldEnough(_age(band: 1, birth: const BirthMonth(2021, 12)), minYears: 5), isFalse);
    });
  });
}
