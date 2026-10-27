import '../data/app_database.dart';
import 'parent_rules.dart';

/// Why it is time to rest.
enum RestReason { none, restHours, schedule, limit }

/// The answer to "may this child start playing now?" It is advice for the child's space, never a count the child sees.
class TimeVerdict {
  const TimeVerdict(this.reason, {required this.locked});

  final RestReason reason;

  /// Time is up and the parent chose that no new activity is offered.
  final bool locked;

  bool get resting => reason != RestReason.none;

  /// New activities may start. When time is up and not locked, the guide only suggests resting.
  bool get mayStart => !locked;
}

/// The sessions' play time today, in minutes, from the sessions of one child. A session that is still open counts up to
/// [now]. One session counts for at most [longestSession] minutes (a phone left on the map must not use up the day).
int playedMinutesToday(List<Session> sessions, DateTime now, {int longestSession = 90}) {
  final DateTime dayStart = DateTime(now.year, now.month, now.day);
  final DateTime dayEnd = dayStart.add(const Duration(days: 1));
  int seconds = 0;
  for (final Session s in sessions) {
    final DateTime end = s.endedAt ?? now;
    final DateTime from = s.startedAt.isBefore(dayStart) ? dayStart : s.startedAt;
    final DateTime to = end.isAfter(dayEnd) ? dayEnd : end;
    if (!to.isAfter(from)) continue;
    final int span = to.difference(from).inSeconds;
    seconds += span > longestSession * 60 ? longestSession * 60 : span;
  }
  return seconds ~/ 60;
}

bool _inWindow(int minute, int start, int end) =>
    start <= end ? minute >= start && minute < end : minute >= start || minute < end;

/// May this child start playing at [now]? Rest hours come first, then the weekly schedule, then the daily limit.
TimeVerdict judgeTime({
  required DateTime now,
  required ParentRules rules,
  required String profileId,
  required int ageBand,
  required int minutesToday,
}) {
  final int minute = now.hour * 60 + now.minute;
  RestReason reason = RestReason.none;
  if (rules.restOn &&
      rules.restStartMinute != rules.restEndMinute &&
      _inWindow(minute, rules.restStartMinute, rules.restEndMinute)) {
    reason = RestReason.restHours;
  } else {
    final List<List<int>>? windows = rules.schedule[now.weekday];
    if (windows != null &&
        windows.isNotEmpty &&
        !windows.any((List<int> w) => _inWindow(minute, w[0], w[1]))) {
      reason = RestReason.schedule;
    } else if (minutesToday >= rules.limitFor(profileId, ageBand)) {
      reason = RestReason.limit;
    }
  }
  return TimeVerdict(reason, locked: reason != RestReason.none && rules.lockWhenDone);
}
