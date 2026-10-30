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

  /// Words heard in a spoken answer, tier 3: swearing or a word of the adult world, counted in one note a week per
  /// child. Never pushed.
  inappropriateWords,

  /// Words heard in a spoken answer, tier 1: a clear worrying statement, or rules C-1 and C-2. The only push.
  disclosure,

  /// Words heard in a spoken answer, tier 2: worth a check (siblings, films, play). In the app only.
  concern,
  absence,

  /// A trophy with a promise on it was earned (M8). The alert holds only the trophy's key.
  ribbonEarned,
}

enum AlertSeverity { info, attention, important }

AlertSeverity severityOf(AlertCategory c) => switch (c) {
  AlertCategory.pastLimit ||
  AlertCategory.restHours ||
  AlertCategory.absence ||
  AlertCategory.ribbonEarned ||
  AlertCategory.inappropriateWords => AlertSeverity.info,
  AlertCategory.gateAttempts ||
  AlertCategory.guessing ||
  AlertCategory.frustration ||
  AlertCategory.concern => AlertSeverity.attention,
  AlertCategory.disclosure => AlertSeverity.important,
};

/// The three word-alert categories, by tier.
const Map<int, AlertCategory> wordCategory = <int, AlertCategory>{
  1: AlertCategory.disclosure,
  2: AlertCategory.concern,
  3: AlertCategory.inappropriateWords,
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

// ---- word alerts ----

/// What a word alert says about itself in its fixed [AlertDraft.detail]: `tier:sub:rule:listVersion`, then the flags
/// `often` (rule C-5), `secret` (C-2) and `repeat` (C-1). Fixed characters only, never the child's words.
class WordDetail {
  const WordDetail({
    required this.tier,
    required this.sub,
    required this.rule,
    required this.listVersion,
    this.flags = const <String>{},
  });

  /// Null for an alert that is not a word alert, or one saved before the tiers (its detail is empty).
  static WordDetail? parse(String detail) {
    final List<String> p = detail.split(':');
    final int? tier = int.tryParse(p.first);
    if (p.length < 4 || tier == null || tier < 1 || tier > 3) return null;
    return WordDetail(tier: tier, sub: p[1], rule: p[2], listVersion: p[3], flags: p.sublist(4).toSet());
  }

  final int tier;
  final String sub;
  final String rule;
  final String listVersion;
  final Set<String> flags;

  /// Only characters `alert-create` takes, whatever the lists held (SEC-25); at most 80.
  String encode() {
    final String d = <Object>[
      tier,
      sub,
      rule,
      listVersion,
      ...flags,
    ].map((Object x) => _wire('$x')).join(':');
    return d.length <= 80 ? d : d.substring(0, 80);
  }
}

/// A value of a detail or a key: only `[A-Za-z0-9._=-]`, at most 64 characters.
String _wire(String s) {
  final String w = s.replaceAll(_notWireField, '');
  return w.length <= 64 ? w : w.substring(0, 64);
}

final RegExp _notWireField = RegExp(r'[^A-Za-z0-9._=-]');

/// The longest words `alert-create` takes.
const int maxWireWords = 200;

final RegExp _notWireWords = RegExp('[^\u0590-\u05FFA-Za-z0-9 .,?!\'"-]');
final RegExp _spaces = RegExp(' {2,}');

/// The child's words as `alert-create` takes them (SEC-25): every character outside its pattern (`%`, `:`, an emoji, a
/// direction mark, a control character) becomes a space, spaces are collapsed, the ends trimmed, and the whole cut to
/// [maxWireWords]. Done once, when the alert is made, so what the phone shows is what the family gets.
String wireWords(String text) {
  final String w = text.replaceAll(_notWireWords, ' ').replaceAll(_spaces, ' ').trim();
  return w.length <= maxWireWords ? w : w.substring(0, maxWireWords).trimRight();
}

/// The key of a child's weekly note of one kind.
String noteKey(String profileId, String sub, DateTime now) =>
    'note:${_wire(profileId)}:${_wire(sub)}:${weekOf(now)}';

/// One alert per child and subcategory in this time, counted; a stronger tier starts a new one.
const Duration wordEpisode = Duration(minutes: 30);

/// Rule C-1: a second check within this time is an act.
const Duration repeatWindow = Duration(days: 7);

/// Rule C-2: a secret and a harm within this time are an act.
const Duration secretWindow = Duration(hours: 24);

const Set<String> _harm = <String>{'PHYS', 'SEX', 'FEAR'};

/// What to save for one spoken answer.
sealed class WordStep {
  const WordStep();
}

/// A new alert.
class AddAlert extends WordStep {
  const AddAlert(this.draft);

  final AlertDraft draft;
}

/// The same alert again: its count goes up by one, and it is sent to the family again (without a push). A weekly note
/// also takes [at], the time it was last heard (rule C-2 looks back from it), and [words], the words of that hearing,
/// so no word stays longer than 30 days after it was heard (SEC-32).
class CountAgain extends WordStep {
  const CountAgain(this.alert, {this.at, this.words});

  final Alert alert;
  final DateTime? at;
  final String? words;
}

/// The Sunday the week of [t] starts on, as the key of the weekly note.
String weekOf(DateTime t) {
  final DateTime d = DateTime(t.year, t.month, t.day - t.weekday % 7);
  String two(int v) => v.toString().padLeft(2, '0');
  return '${d.year}-${two(d.month)}-${two(d.day)}';
}

/// What [match] adds to a child's alerts, given the child's alerts of the last week ([recent]):
///
/// - Tier 3: one note per child, kind and week, counted ("{n} פעמים"): swearing (SWEAR), adult words (EXPOSE), asking
///   the helper to keep a secret (SECRET, W-47) and hitting oneself in band A (SELF, W-37).
/// - Tiers 1 and 2: one alert per child and subcategory for [wordEpisode], counted; a stronger tier starts a new one.
/// - C-2: a secret now and a harm in the last [secretWindow] (or the other way round, the secret also a note) is tier 1.
/// - C-1: a new check when the child had another check in the last [repeatWindow] is tier 1, once a week.
/// - C-4: a swear in the same answer as a phrase is counted in the note as well.
///
/// The words kept are the hypothesis that matched, cleaned for the gateway ([wireWords]), and only when [keepWords]
/// is on.
List<WordStep> planWordAlert({
  required DateTime now,
  required String profileId,
  required WordMatch match,
  required bool keepWords,
  required List<Alert> recent,
}) {
  final List<(Alert, WordDetail)> mine = <(Alert, WordDetail)>[
    for (final Alert a in recent)
      if (a.profileId == profileId)
        if (WordDetail.parse(a.detail) case final WordDetail d) (a, d),
  ];
  bool since(Alert a, Duration d) => !a.at.isBefore(now.subtract(d));
  int tier = match.tier;
  final Set<String> flags = <String>{if (match.often) 'often', if (match.secret) 'secret'};
  final List<WordStep> steps = <WordStep>[];
  final bool harmNow = _harm.contains(match.sub);
  if ((harmNow || match.sub == 'SECRET') && !flags.contains('secret')) {
    final bool paired = mine.any(
      ((Alert, WordDetail) x) =>
          since(x.$1, secretWindow) &&
          (harmNow ? x.$2.sub == 'SECRET' : x.$2.tier < 3 && _harm.contains(x.$2.sub)),
    );
    if (paired) {
      tier = 1;
      flags.add('secret');
    }
  }

  if (tier == 3) return <WordStep>[_note(now, profileId, match, keepWords, mine)];

  final (Alert, WordDetail)? open = mine
      .where(
        ((Alert, WordDetail) x) => x.$2.tier <= tier && x.$2.sub == match.sub && since(x.$1, wordEpisode),
      )
      .firstOrNull;
  if (open != null) {
    steps.add(CountAgain(open.$1));
  } else {
    if (tier == 2 &&
        mine.any(((Alert, WordDetail) x) => x.$2.tier == 2 && since(x.$1, repeatWindow)) &&
        !mine.any(((Alert, WordDetail) x) => x.$2.flags.contains('repeat') && since(x.$1, repeatWindow))) {
      tier = 1;
      flags.add('repeat');
    }
    steps.add(
      AddAlert(
        AlertDraft(
          category: wordCategory[tier]!,
          at: now,
          key: 'words:${_wire(profileId)}:${now.millisecondsSinceEpoch}',
          profileId: profileId,
          count: 1,
          detail: WordDetail(
            tier: tier,
            sub: match.sub,
            rule: match.rule,
            listVersion: match.listVersion,
            flags: flags,
          ).encode(),
          words: keepWords ? wireWords(match.text) : '',
        ),
      ),
    );
  }
  if (match.swear case final WordMatch swear) steps.add(_note(now, profileId, swear, keepWords, mine));
  return steps;
}

/// The week's note of one kind for one child: counted again if there is one, otherwise started.
WordStep _note(DateTime now, String profileId, WordMatch m, bool keepWords, List<(Alert, WordDetail)> mine) {
  final String key = noteKey(profileId, m.sub, now);
  final Alert? have = mine.where(((Alert, WordDetail) x) => x.$1.dedupeKey == key).firstOrNull?.$1;
  if (have != null) return CountAgain(have, at: now, words: keepWords ? wireWords(m.text) : '');
  return AddAlert(
    AlertDraft(
      category: AlertCategory.inappropriateWords,
      at: now,
      key: key,
      profileId: profileId,
      count: 1,
      detail: WordDetail(tier: 3, sub: m.sub, rule: m.rule, listVersion: m.listVersion).encode(),
      words: keepWords ? wireWords(m.text) : '',
    ),
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
