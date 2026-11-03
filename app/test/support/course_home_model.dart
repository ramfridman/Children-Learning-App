// A course home model of a fixture course from a few facts, for the screens' tests and goldens: which stones are done and placed, and
// what the pebble would start.
import 'package:nitznutz/content/models.dart';
import 'package:nitznutz/engine/course.dart';
import 'package:nitznutz/world/adventure_land.dart';
import 'package:nitznutz/world/course_path.dart';
import 'package:nitznutz/world/placement.dart' show landPath;
import 'package:nitznutz/world/todays_adventure.dart';

import 'course_packs.dart';

/// A model of [course] with the given 0-based stones done and placed; the next stone is the first of the rest.
CourseHomeModel modelOf(
  String course, {
  Set<int> done = const <int>{},
  Set<int> placed = const <int>{},
  bool placementDue = false,
  bool revisit = false,
  bool noStop = false,
}) {
  final PackContent c = courseContent(course);
  final List<Lesson> path = landPath(c, Course.languagesDomain);
  final List<PathStone> stones = <PathStone>[
    for (final (int i, Lesson l) in path.indexed)
      PathStone(
        lessonId: l.id,
        title: l.title,
        number: i + 1,
        state: done.contains(i)
            ? StoneState.done
            : placed.contains(i)
            ? StoneState.placed
            : StoneState.later,
      ),
  ];
  final int next = stones.indexWhere((PathStone s) => s.state == StoneState.later);
  final LanguageLand land = LanguageLand(course);
  return CourseHomeModel(
    course: course,
    stones: stones,
    nextIndex: next < 0 ? 0 : next,
    stop: noStop
        ? const TodaysAdventure.none()
        : revisit
        ? TodaysAdventure.revisit(land, c.skills.keys.first)
        : TodaysAdventure.lesson(land, stones[next < 0 ? 0 : next].lessonId, AdventureReason.sameLand),
    placementDue: placementDue,
  );
}
