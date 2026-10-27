import '../data/app_database.dart';
import '../speech/alert_words.dart';
import 'parent_rules.dart';
import 'time_rules.dart';

/// What the parent is told about (PLAN: Alerts). Detection runs on the device; only the alert itself ever syncs.
enum AlertCategory {
  pastLimit,
  restHours,
  gateAttempts,
  guessing,
  frustration,
  inappropriateWords,
  disclosure,
  absence,
}

enum AlertSeverity { info, attention, important }

AlertSeverity severityOf(AlertCategory c) => switch (c) {
  AlertCategory.pastLimit || AlertCategory.restHours || AlertCategory.absence => AlertSeverity.info,
  AlertCategory.gateAttempts ||
  AlertCategory.guessing ||
  AlertCategory.frustration ||
  AlertCategory.inappropriateWords => AlertSeverity.attention,
  AlertCategory.disclosure => AlertSeverity.important,
};

/// An alert found but not yet saved. [key] is what makes one alert the same alert next time (one per day, per session,
/// per event), so scanning again never repeats it.
class AlertDraft {
  const AlertDraft({
    required this.category,
    required this.at,
    required this.key,
    this.profileId,
    this.count = 0,
    this.detail = '',
    this.words = '',
  });

  final AlertCategory category;
  final DateTime at;
  final String key;
  final String? profileId;

  /// A number that belongs to the alert (minutes, attempts), or 0.
  final int count;

  /// Fixed words only (an activity id). Never free text.
  final String detail;

  /// The child's words, only when the parent allows keeping them; empty otherwise.
  final String words;

  AlertSeverity get severity => severityOf(category);
}

/// What the scanner reads: one child's sessions and answers, with the age band and id.
class ChildHistory {
  const ChildHistory({
    required this.profileId,
    required this.ageBand,
    required this.sessions,
    required this.attempts,
  });

  final String profileId;
  final int ageBand;
  final List<Session> sessions;
  final List<Attempt> attempts;
}

String _day(DateTime d) => '${d.year}-${d.month}-${d.day}';

bool _inRest(DateTime t, ParentRules r) {
  if (!r.restOn || r.restStartMinute == r.restEndMinute) return false;
  final int m = t.hour * 60 + t.minute;
  return r.restStartMinute <= r.restEndMinute
      ? m >= r.restStartMinute && m < r.restEndMinute
      : m >= r.restStartMinute || m < r.restEndMinute;
}

/// Played past the limit (by more than 5 minutes) or during rest hours, on any of the last seven days.
List<AlertDraft> timeAlerts(DateTime now, ParentRules rules, ChildHistory child) {
  final List<AlertDraft> out = <AlertDraft>[];
  final DateTime today = DateTime(now.year, now.month, now.day);
  final int limit = rules.limitFor(child.profileId, child.ageBand);
  for (int i = 0; i < 7; i++) {
    final DateTime dayStart = today.subtract(Duration(days: i));
    final DateTime dayEnd = DateTime(dayStart.year, dayStart.month, dayStart.day, 23, 59, 59);
    final int minutes = playedMinutesToday(child.sessions, dayEnd.isAfter(now) ? now : dayEnd);
    if (minutes > limit + 5) {
      out.add(
        AlertDraft(
          category: AlertCategory.pastLimit,
          at: dayEnd.isAfter(now) ? now : dayEnd,
          key: 'limit:${child.profileId}:${_day(dayStart)}',
          profileId: child.profileId,
          count: minutes - limit,
        ),
      );
    }
  }
  // Rest hours: a session that began or ended inside them (on a day when rest hours are on).
  final Set<String> seen = <String>{};
  for (final Session s in child.sessions) {
    final DateTime start = s.startedAt.toLocal();
    if (start.isBefore(today.subtract(const Duration(days: 6)))) continue;
    final DateTime end = (s.endedAt ?? now).toLocal();
    if ((_inRest(start, rules) || _inRest(end, rules)) && seen.add(_day(start))) {
      out.add(
        AlertDraft(
          category: AlertCategory.restHours,
          at: start,
          key: 'rest:${child.profileId}:${_day(start)}',
          profileId: child.profileId,
          count: end.difference(start).inMinutes,
        ),
      );
    }
  }
  return out;
}

/// Trying to get into the parent area: the pin and gate services record `gate_alert` and `pin_alert` after three wrong
/// answers in a row. One alert for each such event.
List<AlertDraft> gateAlerts(List<LocalEvent> events) => <AlertDraft>[
  for (final LocalEvent e in events)
    if (e.kind == 'gate_alert' || e.kind == 'pin_alert')
      AlertDraft(
        category: AlertCategory.gateAttempts,
        at: e.at,
        key: 'gate:${e.id}',
        count: int.tryParse(RegExp(r'n=(\d+)').firstMatch(e.detail)?.group(1) ?? '') ?? 3,
      ),
];

/// Guessing or frustration inside one session.
///
/// - Guessing: six answers in a row, each in under one and a half seconds, and four or more of them wrong.
/// - Frustration: three wrong answers in a row and the child left (the session ended "home") within a minute of the
///   last one, or eight answers in half a minute (rapid tapping).
List<AlertDraft> behaviourAlerts(ChildHistory child) {
  final List<AlertDraft> out = <AlertDraft>[];
  final Map<int, List<Attempt>> bySession = <int, List<Attempt>>{};
  for (final Attempt a in child.attempts) {
    if (a.sessionId != null) (bySession[a.sessionId!] ??= <Attempt>[]).add(a);
  }
  final Map<int, Session> sessions = <int, Session>{for (final Session s in child.sessions) s.id: s};
  for (final MapEntry<int, List<Attempt>> e in bySession.entries) {
    final List<Attempt> a = List<Attempt>.of(e.value)..sort((Attempt x, Attempt y) => x.at.compareTo(y.at));
    // Guessing.
    bool guessing = false;
    for (int i = 0; i + 6 <= a.length && !guessing; i++) {
      final List<Attempt> run = a.sublist(i, i + 6);
      guessing =
          run.every((Attempt x) => x.durationMs > 0 && x.durationMs < 1500) &&
          run.where((Attempt x) => x.result == 'incorrect').length >= 4;
    }
    if (guessing) {
      out.add(
        AlertDraft(
          category: AlertCategory.guessing,
          at: a.last.at,
          key: 'guess:${e.key}',
          profileId: child.profileId,
          detail: a.last.activityId,
        ),
      );
    }
    // Frustration: wrong three in a row, then gone.
    bool upset = false;
    int wrongRun = 0;
    for (final Attempt x in a) {
      wrongRun = x.result == 'incorrect' ? wrongRun + 1 : 0;
    }
    final Session? s = sessions[e.key];
    if (wrongRun >= 3 && s != null && s.endReason == 'home' && s.endedAt != null) {
      upset = s.endedAt!.difference(a.last.at).inSeconds.abs() <= 60;
    }
    // Rapid tapping: eight answers inside half a minute.
    for (int i = 0; i + 8 <= a.length && !upset; i++) {
      upset = a[i + 7].at.difference(a[i].at).inSeconds <= 30;
    }
    if (upset) {
      out.add(
        AlertDraft(
          category: AlertCategory.frustration,
          at: a.last.at,
          key: 'upset:${e.key}',
          profileId: child.profileId,
          detail: a.last.activityId,
        ),
      );
    }
  }
  return out;
}

/// A long absence (no play for seven days after a child had played at least three times) or a sudden drop (this week's
/// play under a quarter of last week's, when last week was an hour or more). One alert a week, never sent to the child.
List<AlertDraft> absenceAlerts(DateTime now, ChildHistory child) {
  if (child.sessions.length < 3) return const <AlertDraft>[];
  final DateTime today = DateTime(now.year, now.month, now.day);
  final String week = '${today.year}-${(today.difference(DateTime(today.year)).inDays ~/ 7)}';
  DateTime last = child.sessions.first.startedAt;
  for (final Session s in child.sessions) {
    if (s.startedAt.isAfter(last)) last = s.startedAt;
  }
  if (now.difference(last).inDays >= 7) {
    return <AlertDraft>[
      AlertDraft(
        category: AlertCategory.absence,
        at: now,
        key: 'absence:${child.profileId}:$week',
        profileId: child.profileId,
        count: now.difference(last).inDays,
      ),
    ];
  }
  int minutesIn(DateTime from, DateTime to) {
    int total = 0;
    for (DateTime d = from; d.isBefore(to); d = d.add(const Duration(days: 1))) {
      total += playedMinutesToday(child.sessions, DateTime(d.year, d.month, d.day, 23, 59, 59));
    }
    return total;
  }

  final int thisWeek = minutesIn(today.subtract(const Duration(days: 6)), today.add(const Duration(days: 1)));
  final int before = minutesIn(
    today.subtract(const Duration(days: 13)),
    today.subtract(const Duration(days: 6)),
  );
  if (before >= 60 && thisWeek * 4 < before) {
    return <AlertDraft>[
      AlertDraft(
        category: AlertCategory.absence,
        at: now,
        key: 'drop:${child.profileId}:$week',
        profileId: child.profileId,
        count: thisWeek,
        detail: 'drop',
      ),
    ];
  }
  return const <AlertDraft>[];
}

/// A spoken answer's words set off an alert, or none. [keepWords] is the parent's choice; the words are kept only
/// when it is on.
AlertDraft? wordAlert({
  required DateTime at,
  required String profileId,
  required List<String> texts,
  required bool keepWords,
  required String key,
}) {
  final WordAlert? w = checkWords(texts);
  if (w == null) return null;
  return AlertDraft(
    category: w == WordAlert.disclosure ? AlertCategory.disclosure : AlertCategory.inappropriateWords,
    at: at,
    key: key,
    profileId: profileId,
    words: keepWords ? texts.first : '',
  );
}

/// Everything the scanner finds from the stored history.
List<AlertDraft> scanHistory({
  required DateTime now,
  required ParentRules rules,
  required List<ChildHistory> children,
  required List<LocalEvent> events,
}) => <AlertDraft>[
  ...gateAlerts(events),
  for (final ChildHistory c in children) ...<AlertDraft>[
    ...timeAlerts(now, rules, c),
    ...behaviourAlerts(c),
    ...absenceAlerts(now, c),
  ],
];
