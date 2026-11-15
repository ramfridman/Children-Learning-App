import 'dart:convert';

// What the parent's guessing and frustration alerts need from an answer that is no evidence (SEC-L7-1). The answer to an item that asks a word the
// child has just met on a Meet screen writes no `attempt` row (docs/milestones/L7.md step L7-3): it must not count as a right or a wrong answer in the
// child's progress. But the child's pace and their taps are still what the alerts watch ("six answers in a row under 1.5 s", "three wrong and gone",
// "eight answers in half a minute"), and a beginner in their first visit is the child most likely to be upset. So the answer leaves a note: the time, the
// result, how long the child took, the visit and the item's id, nothing else. The notes stay on this phone: they are never synced, never sent, not
// read by the engine, the progress or the placement, and only `behaviourAlerts` reads them. They are a few at a time: the newest [behaviourNotesKept].

/// One answer that was no evidence, as the alerts see it.
class BehaviourNote {
  const BehaviourNote({
    required this.at,
    required this.activityId,
    required this.result,
    required this.durationMs,
    required this.sessionId,
  });

  /// When the answer was given.
  final DateTime at;

  /// The item (a content id, as in an alert's detail).
  final String activityId;

  /// `correct`, `incorrect` or `unsure`.
  final String result;
  final int durationMs;

  /// The visit the answer was given in (the `session` row), the same as an `attempt` has.
  final int sessionId;

  List<Object> toJson() => <Object>[at.millisecondsSinceEpoch, activityId, result, durationMs, sessionId];

  static BehaviourNote? fromJson(Object? json) {
    if (json is! List<Object?> || json.length != 5) return null;
    final Object? ms = json[0];
    final Object? activity = json[1];
    final Object? result = json[2];
    final Object? duration = json[3];
    final Object? session = json[4];
    if (ms is! int || activity is! String || result is! String || duration is! int || session is! int) {
      return null;
    }
    return BehaviourNote(
      at: DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true),
      activityId: activity,
      result: result,
      durationMs: duration,
      sessionId: session,
    );
  }
}

/// How many notes of a child the phone keeps: the longest run the alerts look at is eight answers, a visit has a few more.
const int behaviourNotesKept = 60;

/// The setting that holds a child's notes as one string; [AppDatabase.deleteChildData] removes it with the child. A setting of this phone only:
/// no sync reads it.
String behaviourNotesKey(String profileId) => 'behaviour_notes_$profileId';

String encodeBehaviourNotes(List<BehaviourNote> notes) =>
    jsonEncode(<Object>[for (final BehaviourNote n in notes) n.toJson()]);

/// The notes in [raw] (a damaged setting gives none), oldest first.
List<BehaviourNote> decodeBehaviourNotes(String? raw) {
  if (raw == null || raw.isEmpty) return const <BehaviourNote>[];
  try {
    final Object? list = jsonDecode(raw);
    if (list is! List<Object?>) return const <BehaviourNote>[];
    return <BehaviourNote>[
      for (final Object? e in list)
        if (BehaviourNote.fromJson(e) case final BehaviourNote n) n,
    ];
  } on FormatException {
    return const <BehaviourNote>[];
  }
}

/// [notes] with [added] at the end, and no more than [behaviourNotesKept] of them (the oldest go).
List<BehaviourNote> withNote(List<BehaviourNote> notes, BehaviourNote added) {
  final List<BehaviourNote> all = <BehaviourNote>[...notes, added];
  return all.length <= behaviourNotesKept ? all : all.sublist(all.length - behaviourNotesKept);
}
