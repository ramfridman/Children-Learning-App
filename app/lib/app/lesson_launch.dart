import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../content/models.dart';
import '../engine/course.dart';
import '../play/lesson_controller.dart' show ItemFlow;
import '../play/lesson_screen.dart';

// The one way a visit starts on the lesson screen (docs/milestones/L-course.md, D-8): a lesson of the starter pack, a revisit mission, the
// placement game of a course, or a lesson of a language course. The course home uses it; the map's own `_openLesson` follows.

/// Opens one visit on the lesson screen and returns when the child leaves it: true when they played it to its end (the celebration was
/// shown). [course] says which pack the lesson is in; [flow] is an adaptive visit (the placement game). The caller checks that its own
/// [context] is still mounted after the await.
Future<bool> openVisit(
  BuildContext context,
  WidgetRef ref, {
  required String profileId,
  String course = Course.core,
  String? lessonId,
  Lesson? mission,
  ItemFlow? flow,
}) async {
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
  return finished ?? false;
}
