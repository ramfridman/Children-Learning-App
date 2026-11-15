// B-29 step 7: the languages. A letter gate's minimum age reads the age in months when a birth month is known; the look of a course follows
// the stage; a course's start never reads age (L7-8: the age test changes meaning: a course's start never reads age, a letter gate does).
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/app/language_providers.dart' show languageCourseOf;
import 'package:nitznutz/data/app_database.dart' show Attempt, Session;
import 'package:nitznutz/engine/age.dart';
import 'package:nitznutz/engine/course.dart';
import 'package:nitznutz/engine/gates.dart';
import 'package:nitznutz/engine/presentation.dart';
import 'package:nitznutz/engine/engine.dart';
import 'package:nitznutz/engine/session_builder.dart';
import 'package:nitznutz/parent/language_settings.dart';
import 'package:nitznutz/world/adventure_adapter.dart' show LanguageCourse;
import 'package:nitznutz/world/course_path.dart';

import 'engine/fixtures.dart';
import 'support/course_packs.dart';

void main() {
  const CourseGate letters = CourseGate(
    id: 'rus.letters',
    course: Course.rus,
    requires: <String>{},
    holds: <String>{'RUS-B-18'},
    minAge: 5,
    routeBypass: <String>{'heritage', 'reader'},
  );

  GateInput input({int ageBand = 1, int? ageMonths, String? route}) => GateInput(
    mastery: const <String, MasteryLevel>{},
    ageBand: ageBand,
    ageMonths: ageMonths,
    route: route,
  );

  group('a gate\'s minimum age', () {
    test('with no age in months it reads the band, as before', () {
      expect(gateResult(letters, input(ageBand: 0)).reasons, <GateReason>[GateReason.tooYoung]);
      expect(gateResult(letters, input(ageBand: 1)).open, isTrue);
      expect(gateResult(letters, input(ageBand: 2)).open, isTrue);
    });

    test('with the age in months, "not before 5" opens at 5;0, not at the start of Band B', () {
      expect(gateResult(letters, input(ageBand: 1, ageMonths: 59)).reasons, <GateReason>[
        GateReason.tooYoung,
      ]);
      expect(gateResult(letters, input(ageBand: 1, ageMonths: 60)).open, isTrue);
    });

    test('and it opens at 5;0 for a child still in Band A (gan 4 turning five)', () {
      expect(gateResult(letters, input(ageBand: 0, ageMonths: 59)).open, isFalse);
      expect(gateResult(letters, input(ageBand: 0, ageMonths: 60)).open, isTrue);
    });

    test('a route the age does not apply to is still let through', () {
      expect(gateResult(letters, input(ageBand: 0, ageMonths: 40, route: 'heritage')).open, isTrue);
    });

    test('the same months give the same answer whatever the band (the months decide)', () {
      for (final int band in <int>[0, 1, 2]) {
        expect(gateResult(letters, input(ageBand: band, ageMonths: 70)).open, isTrue);
        expect(gateResult(letters, input(ageBand: band, ageMonths: 50)).open, isFalse);
      }
    });
  });

  group('a course start never reads age (a letter gate does, above)', () {
    CourseHomeModel home(String course, LanguageSwitches s, int ageBand, {int? months}) => buildCourseHome(
      course: languageCourseOf(courseContent(course), const <Attempt>[], s, ageBand, ageMonths: months),
      attempts: const <Attempt>[],
      sessions: const <Session>[],
      rewardKeys: const <String>[],
      now: DateTime.utc(2026, 11, 14, 9),
      band: ageBand,
    );

    test('a beginner opens lesson 1 with no probe whatever the age, in all three courses', () {
      for (final String course in <String>[Course.eng, Course.heb, Course.rus]) {
        final CourseHomeModel base = home(course, const LanguageSwitches(on: true), 0, months: 36);
        expect(base.placementDue, isFalse, reason: course);
        for (final (int band, int? months) in <(int, int?)>[
          (0, 59),
          (1, null),
          (1, 72),
          (2, 96),
          (2, null),
        ]) {
          final CourseHomeModel m = home(course, const LanguageSwitches(on: true), band, months: months);
          expect(m.placementDue, base.placementDue, reason: '$course $band $months');
          expect(m.nextIndex, base.nextIndex, reason: '$course $band $months');
          expect(m.stop.lessonId, base.stop.lessonId, reason: '$course $band $months');
        }
      }
    });

    test('a child whose parent says they know something gets the same placement game at 3 and at 8', () {
      const LanguageSwitches some = LanguageSwitches(
        on: true,
        questionnaire: <String, String>{'knowsLetters': 'some'},
      );
      final LanguageCourse young = languageCourseOf(
        courseContent('eng'),
        const <Attempt>[],
        some,
        0,
        ageMonths: 36,
      );
      final LanguageCourse old = languageCourseOf(
        courseContent('eng'),
        const <Attempt>[],
        some,
        2,
        ageMonths: 100,
      );
      expect(young.placement!.results.keys, old.placement!.results.keys);
      expect(young.placement!.complete, old.placement!.complete);
    });
  });

  group('the look of a course follows the stage; the content band stays', () {
    ChildAge age({int band = 1, BirthMonth? birth}) =>
        childAge(band: band, birth: birth, now: DateTime(2026, 11, 8));

    test('the presentation spec of a stage is the stage\'s caps, items and minutes', () {
      expect(presentationSpecForStage(0).maxChoices, 3);
      expect(presentationSpecForStage(1).maxChoices, 3);
      expect(presentationSpecForStage(2).maxChoices, 4);
      expect(presentationSpecForStage(3).maxChoices, 5);
      expect(presentationSpecForStage(0).sessionMinutes, 6);
      expect(presentationSpecForStage(1).sessionMinutes, 8);
      expect(presentationSpecForStage(2).sessionMinutes, 12);
      expect(presentationSpecForStage(3).sessionMinutes, 15);
      expect(<int>[for (int i = 0; i < 4; i++) presentationSpecForStage(i).itemsMin], <int>[3, 3, 5, 8]);
      expect(<int>[for (int i = 0; i < 4; i++) presentationSpecForStage(i).itemsMax], <int>[4, 5, 8, 12]);
    });

    test('English keeps its own minutes by band inside a course whatever the stage', () {
      expect(presentationSpecForStage(1, course: Course.eng, band: 0).sessionMinutes, 7);
      expect(presentationSpecForStage(2, course: Course.eng, band: 1).sessionMinutes, 11);
    });

    test('a course look band, else the look letter, else the age', () {
      final ChildAge a = age(birth: const BirthMonth(2021, 3)); // P3
      expect(effectiveStage(a, courseBand: 0), PresentationStage.p2);
      expect(effectiveStage(a, lookBand: 2), PresentationStage.p4);
      expect(effectiveStage(a, lookBand: 2, courseBand: 1), PresentationStage.p3);
    });

    test('the content band of a course is not the look: it is the course choice, else the band of the school stage', () {
      final ChildAge a = age(band: 0, birth: const BirthMonth(2019, 3)); // 7;8 on Band A content
      expect(a.presentation, PresentationStage.p4, reason: 'a 7-year-old on Band A content gets the P4 look');
      expect(presentationBandFor(ageBand: a.band), 0, reason: 'and the content band stays A');
    });
  });

  group('the length of a visit follows the stage', () {
    final SessionBuilder b = SessionBuilder(
      engine: Engine(catalog: smallCatalog()),
      random: math.Random(1),
    );

    test('a stage sets the minutes, the seconds an item takes still follow the content band', () {
      // Band B content (45 s an item): P1 6 min, P2 8, P3 12, P4 15.
      expect(<int>[for (int s = 0; s < 4; s++) b.totalItems(1, stage: s)], <int>[8, 11, 16, 20]);
    });

    test('with no stage the band decides, as before', () {
      expect(b.totalItems(0), 14);
      expect(b.totalItems(1), 16);
      expect(b.totalItems(2), 18);
    });

    test('English keeps the middle of its own range by content band whatever the stage', () {
      expect(b.totalItems(2, course: Course.eng, stage: 0), b.totalItems(2, course: Course.eng, stage: 3));
    });
  });
}
