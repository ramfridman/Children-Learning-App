import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../content/models.dart';
import '../data/app_database.dart';
import '../parent/language_settings.dart';
import '../world/adventure_adapter.dart' show LanguageCourse;
import '../world/course_path.dart';
import '../world/language_placement.dart';
import '../world/todays_adventure.dart' show AdventureKind;
import 'language_providers.dart';
import 'lesson_launch.dart';
import 'state.dart';

/// Starts what the course home's pebble stands for (docs/milestones/L-course.md, D-5 and D-7): the next placement visit while the host is
/// inviting, otherwise the stop of the rule: a revisit mission of the course's own, or its lesson. Every visit is of this course alone: the
/// pack, the engine, the mission and the placement are the course's. The child's history is read afresh, so a visit goes on where the
/// last one ended. True when the child played the visit to its end; false when nothing was started or they left.
Future<bool> startCourseVisit(
  BuildContext context,
  WidgetRef ref, {
  required String childId,
  required String course,
  required CourseHomeModel model,
}) async {
  final List<LanguageCourse> courses = await ref.read(languageCoursesProvider(childId).future);
  final LanguageCourse? own = courses.where((LanguageCourse c) => c.course == course).firstOrNull;
  if (own == null || !context.mounted) return false;
  final AppDatabase db = await ref.read(databaseProvider.future);
  final Profile? child = (await db.allProfiles()).where((Profile p) => p.id == childId).firstOrNull;
  final LanguageSwitches switches = (await ref.read(languagesProvider.future)).of(childId, course);
  final int band = child?.ageBand ?? 1;
  final ({Lesson lesson, PlacementFlow flow})? placement = model.placementDue
      ? placementVisitFor(
          own.content,
          await db.attemptsOf(childId),
          answers: switches.questionnaire,
          presentationBand: switches.presentationBand(band),
        )
      : null;
  if (!context.mounted) return false;
  if (placement != null) {
    return openVisit(
      context,
      ref,
      profileId: childId,
      course: course,
      mission: placement.lesson,
      flow: placement.flow,
    );
  }
  if (model.stop.kind == AdventureKind.revisit) {
    final Lesson? mission = courseMission(own, model.stop.skillId!);
    return mission == null
        ? false
        : openVisit(context, ref, profileId: childId, course: course, mission: mission);
  }
  final String? lessonId = model.stop.lessonId;
  return lessonId == null
      ? false
      : openVisit(context, ref, profileId: childId, course: course, lessonId: lessonId);
}
