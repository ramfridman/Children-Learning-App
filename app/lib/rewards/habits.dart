import '../engine/types.dart';
import 'reward_rules.dart';

/// The habit moments in a child's answers (M8, Q6): every "I'm not sure" or "show me", and every right answer that came
/// after a mistake on the same activity in the same visit. Only what the child did is looked at, never how fast or how long.
/// Deterministic, and the same answers always give the same moments, so every phone agrees.
List<HabitMoment> habitMoments(List<AttemptEvent> events) {
  final List<AttemptEvent> ordered = List<AttemptEvent>.of(events)
    ..sort((AttemptEvent a, AttemptEvent b) => a.at.compareTo(b.at));
  final List<HabitMoment> out = <HabitMoment>[];
  final Set<String> missed = <String>{};
  for (final AttemptEvent e in ordered) {
    final String where = '${e.sessionId}/${e.activityId}';
    switch (e.result) {
      case Result.unsure:
        out.add(HabitMoment(kind: HabitKind.askedForHelp, at: e.at));
      case Result.incorrect:
        missed.add(where);
      case Result.correct:
        if (missed.remove(where)) out.add(HabitMoment(kind: HabitKind.triedAgain, at: e.at));
    }
  }
  return out;
}
