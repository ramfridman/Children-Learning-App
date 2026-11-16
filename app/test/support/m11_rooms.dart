// Helpers of the M11 room tests: a lesson of a land (from the starter pack) or of a language course (from the fixture packs) opened on the
// lesson screen with the rooms on, the way a child sees it.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/content/models.dart';
import 'package:nitznutz/engine/course.dart';
import 'package:nitznutz/play/block_layout.dart';
import 'package:nitznutz/play/lesson_screen.dart';
import 'package:nitznutz/rooms/room_spec.dart';

import 'app_harness.dart';
import 'course_packs.dart';
import 'l4_golden.dart' show voRefsOf, waitFor;
import 'language_voice.dart';
import 'starter.dart';

/// The rooms in the order of the spec, with the land of each (a course's is its course).
const List<RoomId> allRooms = RoomId.values;

/// The kid of the land tests (the rig's first child).
const String roomKid = 'p-1';

/// A short lesson of three plain "which one" items of the room [room], from the starter pack for a land and from the fixture pack for a
/// course (the first lesson's items), as a revisit mission, so every board shows the room with the same kind of item.
Future<(PackContent, Lesson)> roomLesson(RoomId room) async {
  final bool course = room == RoomId.eng || room == RoomId.heb || room == RoomId.rus;
  final PackContent pack = course ? courseContent(room.name) : await loadStarter();
  final List<TapAnswerActivity> picks = <TapAnswerActivity>[
    for (final Activity a in pack.activities.values)
      if (a is TapAnswerActivity &&
          a.numberAnswer == null &&
          !a.all &&
          a.ls01Mode == null &&
          a.purpose != 'probe' &&
          !BlockLayout.hasBlocks(a) &&
          (course ? a.isLanguage : pack.skills[a.skillId]?.domain == room.name))
        a,
  ];
  final List<TapAnswerActivity> three = picks.take(3).toList();
  return (
    pack,
    Lesson.mission(
      id: 'room-${room.name}',
      itemIds: <String>[for (final TapAnswerActivity a in three) a.id],
      skillIds: <String>[three.first.skillId],
      celebration: const Spoken(vo: 'vo:x.celebrate', caption: 'כָּל הַכָּבוֹד!'),
    ),
  );
}

/// The id of the right option of the item [index] of [lesson].
String rightOption(PackContent content, Lesson lesson, int index) =>
    (content.activities[lesson.itemIds[index]]! as TapAnswerActivity).correctId;

/// A wrong option of the item [index] of [lesson].
String wrongOption(PackContent content, Lesson lesson, int index) {
  final TapAnswerActivity a = content.activities[lesson.itemIds[index]]! as TapAnswerActivity;
  return a.options.firstWhere((ChoiceOption o) => o.id != a.correctId).id;
}

/// Opens [lesson] of [content] on the lesson screen with the rooms on, on a board of [size], and returns the rig. [wait] is how long the
/// first screen is given to load and settle.
Future<AppRig> openRoomLesson(
  WidgetTester tester,
  PackContent content,
  Lesson lesson,
  Size size, {
  bool reduceMotion = true,
  int wait = 800,
}) async {
  final bool course = Course.isLanguage(content.course);
  final AppRig rig = AppRig(
    content: content,
    rooms: true,
    characters: course ? await languageVoiceSource(voRefsOf(courseFixture(content.course))) : null,
  );
  await rig.seedFinishedSetup(name: 'נועה');
  // The map's characters breathe for ever, so the app is opened with reduce motion on, and motion is let in once the lesson is open.
  await rig.pump(tester, size: size);
  await tester.tap(find.text('נועה'));
  await tester.pumpAndSettle();
  if (!reduceMotion) {
    tester.platformDispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures();
    await tester.pump(const Duration(milliseconds: 100));
  }
  tester
      .state<NavigatorState>(find.byType(Navigator).first)
      .push(
        MaterialPageRoute<void>(
          builder: (BuildContext c) => LessonScreen(profileId: roomKid, mission: lesson),
        ),
      );
  await waitFor(tester, wait);
  return rig;
}
