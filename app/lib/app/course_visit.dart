import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../content/models.dart';
import '../data/app_database.dart';
import '../parent/language_settings.dart';
import '../world/adventure_adapter.dart' show LanguageCourse;
import '../world/course_path.dart';
import '../world/todays_adventure.dart' show AdventureKind, AdventureReason, TodaysAdventure;
import '../world/language_placement.dart';
import 'language_providers.dart';
import 'lesson_launch.dart';
import 'state.dart';

/// Starts what the course home's pebble stands for (docs/milestones/L-course.md, D-5 and D-7): the next placement visit while the host is
/// inviting, otherwise the stop of the rule: a revisit mission of the course's own, or its lesson. Every visit is of this course alone: the
/// pack, the engine, the mission and the placement are the course's. The child's history is read afresh, so a visit goes on where the
/// last one ended. [stop] is the stop Today's Adventure chose, when the bottle sent the child here: it takes the place of the home's own
/// (the placement visit still goes first when it is due, as a land's warm-up does). How it went ([VisitOutcome]); `refused` also when there was nothing to start.
Future<VisitOutcome> startCourseVisit(
  BuildContext context,
  WidgetRef ref, {
  required String childId,
  required String course,
  required CourseHomeModel model,
  TodaysAdventure? stop,
}) async {
  final List<LanguageCourse> courses = await ref.read(languageCoursesProvider(childId).future);
  final LanguageCourse? own = courses.where((LanguageCourse c) => c.course == course).firstOrNull;
  if (own == null || !context.mounted) return VisitOutcome.refused;
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
  if (!context.mounted) return VisitOutcome.refused;
  if (placement != null) {
    return openVisit(
      context,
      ref,
      profileId: childId,
      ageBand: band,
      course: course,
      mission: placement.lesson,
      flow: placement.flow,
    );
  }
  final TodaysAdventure what = stop ?? model.stop;
  if (what.kind == AdventureKind.revisit) {
    final Lesson? mission = what.reason == AdventureReason.checkVisit
        ? courseCheckVisit(own, what.skillId!, band: band)
        : courseMission(own, what.skillId!);
    return mission == null
        ? VisitOutcome.refused
        : openVisit(context, ref, profileId: childId, ageBand: band, course: course, mission: mission);
  }
  final String? lessonId = what.lessonId;
  return lessonId == null
      ? VisitOutcome.refused
      : openVisit(context, ref, profileId: childId, ageBand: band, course: course, lessonId: lessonId);
}
