// A child's history in a fixture course, for the tests of the course screens: answers, visits and awards as the rows the app writes,
// either as plain objects (for the pure functions) or written into a real database (for the providers and the screens).
import 'package:drift/drift.dart' show Value;
import 'package:nitznutz/content/models.dart';
import 'package:nitznutz/data/app_database.dart';
import 'package:nitznutz/rewards/award.dart';
import 'package:nitznutz/world/placement.dart' show placementIdFor;

/// The child of the tests, with an id of the shape the family's account gives.
const String courseKid = 'child-lang-0001';

/// An answer row of [pack]'s activity [activityId] (its short id, without the course) as the replay reads it. Not in a database.
Attempt attemptRow(
  PackContent pack,
  String activityId, {
  String result = 'correct',
  String? lessonId,
  required DateTime at,
  int id = 1,
  int? sessionId,
  String profileId = courseKid,
}) {
  final Activity a = pack.activities['${pack.course}.$activityId'] ?? pack.activities[activityId]!;
  return Attempt(
    id: id,
    at: at,
    profileId: profileId,
    packId: pack.packId,
    packVersion: pack.packVersion,
    lessonId: lessonId ?? 'some-lesson',
    activityId: a.id,
    activityRevision: 1,
    template: 'tap_answer',
    templateVersion: '1.3',
    skillId: a.skillId,
    result: result,
    attemptNo: 1,
    hintLevel: 0,
    misconceptionTag: '',
    response: result == 'correct' ? 'o1' : 'o2',
    durationMs: 100,
    sessionId: sessionId,
    input: 'tap',
  );
}

/// A finished (or otherwise ended) visit row.
Session sessionRow(
  int id,
  String plan, {
  required DateTime at,
  String reason = 'finished',
  String profileId = courseKid,
}) => Session(
  id: id,
  profileId: profileId,
  startedAt: at,
  endedAt: at.add(const Duration(minutes: 4)),
  plan: plan,
  endReason: reason,
);

/// Writes one answer into the database (the same row the lesson screen writes).
Future<void> writeAnswer(
  AppDatabase db,
  PackContent pack,
  String activityId, {
  String result = 'correct',
  String? lessonId,
  required DateTime at,
  int? sessionId,
  String profileId = courseKid,
}) {
  final Activity a = pack.activities['${pack.course}.$activityId'] ?? pack.activities[activityId]!;
  return db.recordAttempt(
    AttemptsCompanion.insert(
      at: at,
      profileId: profileId,
      packId: pack.packId,
      packVersion: pack.packVersion,
      lessonId: Value<String>(lessonId ?? 'some-lesson'),
      activityId: a.id,
      activityRevision: 1,
      template: 'tap_answer',
      templateVersion: '1.3',
      skillId: a.skillId,
      result: result,
      attemptNo: 1,
      hintLevel: 0,
      misconceptionTag: const Value<String>(''),
      response: Value<String>(result == 'correct' ? 'o1' : 'o2'),
      durationMs: const Value<int>(100),
      sessionId: Value<int?>(sessionId),
    ),
  );
}

/// A lesson played to its end in a database: its visit, all its items right, the sticker the child was given.
Future<void> writeFinishedLesson(
  AppDatabase db,
  PackContent pack,
  String lessonId, {
  required DateTime at,
  int n = 1,
  String profileId = courseKid,
}) async {
  final int visit = await db.startSession(profileId, at, plan: 'lesson:$lessonId');
  final Lesson lesson = pack.lessons[lessonId]!;
  for (final (int i, String item) in lesson.itemIds.indexed) {
    await writeAnswer(
      db,
      pack,
      item,
      lessonId: lessonId,
      at: at.add(Duration(seconds: 10 * (i + 1))),
      sessionId: visit,
      profileId: profileId,
    );
  }
  final DateTime end = at.add(const Duration(minutes: 3));
  await db.endSession(visit, end, 'finished');
  await db.addReward(
    RewardsCompanion.insert(
      profileId: profileId,
      awardKey: Awards.sticker(lessonId, n),
      kind: 'sticker',
      at: end,
      seenAt: Value<DateTime?>(end),
    ),
  );
}

/// The placement visit of [pack] answered: each `(item, right)` of [answers] is written under the course's placement lesson.
Future<void> writePlacement(
  AppDatabase db,
  PackContent pack,
  List<(String, bool)> answers, {
  required DateTime at,
  String profileId = courseKid,
}) async {
  final int visit = await db.startSession(profileId, at, plan: 'mission:placement');
  for (final (int i, (String, bool) a) in answers.indexed) {
    await writeAnswer(
      db,
      pack,
      a.$1,
      result: a.$2 ? 'correct' : 'incorrect',
      lessonId: placementIdFor(pack.course),
      at: at.add(Duration(seconds: 10 * (i + 1))),
      sessionId: visit,
      profileId: profileId,
    );
  }
  await db.endSession(visit, at.add(const Duration(minutes: 2)), 'finished');
}
