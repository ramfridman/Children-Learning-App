import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../child/rest_scene.dart';
import '../content/models.dart';
import '../engine/course.dart';
import '../parent/time_rules.dart';
import '../play/lesson_controller.dart' show ItemFlow;
import '../play/lesson_screen.dart';
import 'language_providers.dart';
import 'rules_providers.dart';

// The one way a visit starts on the lesson screen (docs/milestones/L-course.md, D-8): a lesson of the starter pack, a revisit mission, the
// placement game of a course, or a lesson of a language course. The map's lands and the course home both use it, so the guards of a visit
// are in one place and cannot drift.

/// How a visit went.
enum VisitOutcome {
  /// The child played it to its end (the celebration was shown).
  played,

  /// The child left before the end.
  left,

  /// Time was up (rest hours, the schedule or the daily limit, with the lock on): the rest scene was shown instead, and no visit began.
  rest,

  /// The visit was not allowed to begin: the language is off for this child, or its pack is not installed. Nothing was shown or written.
  refused,
}

/// Opens one visit on the lesson screen, after the guards, and returns when the child leaves it. [course] says which pack the lesson is
/// in; [flow] is an adaptive visit (the placement game). The guards, in order:
/// 1. a language course must be on for this child and installed (`languagesAvailableProvider`): a language the parent switched off while
///    a screen was still open cannot be started;
/// 2. the parent's time rules, asked afresh (rest hours, schedule, daily limit): when time is up the child sees the rest scene.
/// The caller checks that its own [context] is still mounted after the await.
Future<VisitOutcome> openVisit(
  BuildContext context,
  WidgetRef ref, {
  required String profileId,
  required int ageBand,
  String course = Course.core,
  String? lessonId,
  Lesson? mission,
  ItemFlow? flow,
}) async {
  if (course != Course.core && !ref.read(languagesAvailableProvider(profileId)).contains(course)) {
    return VisitOutcome.refused;
  }
  final ({String id, int band}) child = (id: profileId, band: ageBand);
  ref.invalidate(timeVerdictProvider(child));
  final TimeVerdict verdict = await ref.read(timeVerdictProvider(child).future);
  if (!context.mounted) return VisitOutcome.refused;
  if (verdict.locked) {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (BuildContext c) => RestScene(onBack: () => Navigator.of(c).pop())),
    );
    return VisitOutcome.rest;
  }
  final bool? finished = await Navigator.of(context).push<bool>(
    MaterialPageRoute<bool>(
      builder: (BuildContext c) => LessonScreen(
        profileId: profileId,
        course: course,
        lessonId: lessonId ?? 'butterflies',
        mission: mission,
        flow: flow,
      ),
    ),
  );
  return finished == true ? VisitOutcome.played : VisitOutcome.left;
}
