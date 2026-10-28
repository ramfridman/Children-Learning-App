import '../data/app_database.dart';
import '../engine/engine.dart';
import '../engine/state.dart';
import '../engine/types.dart';
import 'time_rules.dart';

/// What the progress view needs to know about a skill and a misconception, in words a parent reads.
class SkillInfo {
  const SkillInfo({required this.title, required this.domain});

  /// "What the child can do", in plain Hebrew (the skill document's title).
  final String title;
  final String domain;
}

/// How a parent reads a skill's status (PLAN: understood, practising, needs a revisit, gap found).
enum ParentStatus { understood, practising, needsRevisit, gap, notStartedYet }

ParentStatus parentStatusOf(SkillStatus s) => switch (s) {
  SkillStatus.freshMastery || SkillStatus.durableMastery => ParentStatus.understood,
  SkillStatus.learning => ParentStatus.practising,
  SkillStatus.needsRevisit => ParentStatus.needsRevisit,
  SkillStatus.gap => ParentStatus.gap,
  SkillStatus.notStarted || SkillStatus.ready => ParentStatus.notStartedYet,
};

class SkillRow {
  const SkillRow({required this.id, required this.title, required this.status, required this.started});

  final String id;
  final String title;
  final ParentStatus status;
  final bool started;
}

class DomainBlock {
  const DomainBlock({required this.domain, required this.skills});

  final String domain;
  final List<SkillRow> skills;

  int get understood => skills.where((SkillRow s) => s.status == ParentStatus.understood).length;
}

/// One misunderstanding the engine found, with the plain sentence for the parent.
class MisconceptionRow {
  const MisconceptionRow({required this.id, required this.text, required this.resolved, this.homeActivity});

  final String id;
  final String text;
  final bool resolved;

  /// Something to do at home in about five minutes, when the pack has one for it (pack 0.3.0).
  final String? homeActivity;
}

/// One way of explaining that works for this child.
class HelpedRow {
  const HelpedRow({required this.representation, required this.successes, required this.tries});

  final Representation representation;
  final int successes;
  final int tries;
}

/// Understanding of a domain at the end of a week; null when the child had not started any skill of it yet.
class WeekPoint {
  const WeekPoint({required this.weekEnd, required this.byDomain});

  final DateTime weekEnd;
  final Map<String, double?> byDomain;
}

/// Habits shown as strengths over the last four weeks. Only counts above zero are shown.
class Habits {
  const Habits({required this.askedWhenUnsure, required this.usedHints, required this.keptTrying});

  final int askedWhenUnsure;
  final int usedHints;
  final int keptTrying;

  bool get any => askedWhenUnsure + usedHints + keptTrying > 0;
}

class Progress {
  const Progress({
    required this.minutesPerDay,
    required this.sessionsThisWeek,
    required this.adventuresCompleted,
    required this.domains,
    required this.misconceptions,
    required this.helped,
    required this.growth,
    required this.habits,
    required this.gaps,
  });

  /// The last seven days, oldest first (the last one is today).
  final List<({DateTime day, int minutes})> minutesPerDay;
  final int sessionsThisWeek;
  final int adventuresCompleted;
  final List<DomainBlock> domains;
  final List<MisconceptionRow> misconceptions;
  final List<HelpedRow> helped;

  /// Eight weeks, oldest first.
  final List<WeekPoint> growth;
  final Habits habits;

  /// Skills the engine found missing and has not seen repaired.
  final List<String> gaps;

  int get totalMinutes => minutesPerDay.fold(0, (int a, ({DateTime day, int minutes}) d) => a + d.minutes);

  /// True when the child has not played at all: the view then says so instead of drawing empty charts.
  bool get empty =>
      sessionsThisWeek == 0 && domains.every((DomainBlock d) => d.skills.every((SkillRow s) => !s.started));
}

/// Everything the view is built from. The engine state is never stored: it is the replay of the attempts.
class ProgressSource {
  const ProgressSource({
    required this.catalog,
    required this.skillInfo,
    required this.tagText,
    this.tagHome = const <String, String>{},
    required this.attempts,
    required this.sessions,
    required this.now,
  });

  final Catalog catalog;
  final Map<String, SkillInfo> skillInfo;
  final Map<String, String> tagText;

  /// The home activity of each misconception that has one, by tag.
  final Map<String, String> tagHome;
  final List<AttemptEvent> attempts;
  final List<Session> sessions;

  /// Local time now (the days are the parent's days).
  final DateTime now;
}

/// How far through a domain the child is at one moment, the same thing the status bars show: every skill of the domain
/// counts for 1 when understood, a half when practising or due for a revisit, a quarter when a gap was found, and
/// nothing when not started. The result is null while the child has not started any skill of the domain, so a line
/// begins when the domain does. (The engine's own estimate is not used here: it rises after a few right answers, long
/// before a skill counts as understood, and the two numbers on one screen would disagree.)
double? _domainUnderstanding(Engine engine, Iterable<String> skillIds, DateTime now) {
  final List<String> ids = skillIds.toList();
  if (!ids.any((String id) => engine.state.skills[id]?.started ?? false)) return null;
  double sum = 0;
  for (final String id in ids) {
    sum += switch (parentStatusOf(engine.statusOf(id, now))) {
      ParentStatus.understood => 1,
      ParentStatus.practising || ParentStatus.needsRevisit => 0.5,
      ParentStatus.gap => 0.25,
      ParentStatus.notStartedYet => 0,
    };
  }
  return sum / ids.length;
}

Engine _replayUntil(Catalog catalog, List<AttemptEvent> events, DateTime until) =>
    Engine(catalog: catalog)..replay(events.where((AttemptEvent e) => !e.at.isAfter(until)));

/// Builds the whole progress view of one child. Pure: the same source gives the same answer.
Progress buildProgress(ProgressSource src) {
  final DateTime now = src.now;
  final DateTime today = DateTime(now.year, now.month, now.day);
  final List<AttemptEvent> events = List<AttemptEvent>.of(src.attempts)
    ..sort((AttemptEvent a, AttemptEvent b) => a.at.compareTo(b.at));

  // This week, by day: play time from the sessions.
  final List<({DateTime day, int minutes})> days = <({DateTime day, int minutes})>[
    for (int i = 6; i >= 0; i--)
      (
        day: today.subtract(Duration(days: i)),
        minutes: playedMinutesToday(
          src.sessions,
          DateTime(today.year, today.month, today.day - i, 23, 59, 59),
        ),
      ),
  ];
  final DateTime weekAgo = today.subtract(const Duration(days: 6));
  final List<Session> week = src.sessions.where((Session s) => !s.startedAt.isBefore(weekAgo)).toList();

  // Now: what the engine concluded.
  final Engine engine = _replayUntil(src.catalog, events, now.toUtc());
  final DateTime nowUtc = now.toUtc();
  final Map<String, List<SkillRow>> byDomain = <String, List<SkillRow>>{};
  final List<String> ids = src.catalog.skills.keys.toList()..sort();
  for (final String id in ids) {
    final SkillInfo? info = src.skillInfo[id];
    if (info == null) continue;
    (byDomain[info.domain] ??= <SkillRow>[]).add(
      SkillRow(
        id: id,
        title: info.title,
        status: parentStatusOf(engine.statusOf(id, nowUtc)),
        started: engine.state.skills[id]?.started ?? false,
      ),
    );
  }

  // Misunderstandings that are active or resolved (a suspicion alone is not shown).
  final List<MisconceptionRow> tags = <MisconceptionRow>[
    for (final MapEntry<String, TagState> t in engine.state.tags.entries)
      if (t.value.status != TagStatus.suspected && src.tagText.containsKey(t.key))
        MisconceptionRow(
          id: t.key,
          text: src.tagText[t.key]!,
          resolved: t.value.status == TagStatus.resolved,
          homeActivity: src.tagHome[t.key],
        ),
  ]..sort((MisconceptionRow a, MisconceptionRow b) => a.id.compareTo(b.id));

  // What helped: the ways of explaining that worked at least 60 times in 100 over at least three tries.
  final Map<Representation, ({int tries, int successes})> reps =
      <Representation, ({int tries, int successes})>{};
  for (final MapEntry<String, RepStats> e in engine.state.representations.entries) {
    final Representation? r = representationOf(e.key.split('|').last);
    if (r == null) continue;
    final ({int tries, int successes}) old = reps[r] ?? (tries: 0, successes: 0);
    reps[r] = (tries: old.tries + e.value.tries, successes: old.successes + e.value.successes);
  }
  final List<HelpedRow> helped = <HelpedRow>[
    for (final MapEntry<Representation, ({int tries, int successes})> e in reps.entries)
      if (e.value.tries >= 3 && e.value.successes / e.value.tries >= 0.6)
        HelpedRow(representation: e.key, successes: e.value.successes, tries: e.value.tries),
  ]..sort((HelpedRow a, HelpedRow b) => (b.successes / b.tries).compareTo(a.successes / a.tries));

  // Growth: the understanding of each domain at the end of each of the last eight weeks, by replaying up to that date.
  final Map<String, List<String>> idsByDomain = <String, List<String>>{
    for (final MapEntry<String, List<SkillRow>> e in byDomain.entries)
      e.key: <String>[for (final SkillRow r in e.value) r.id],
  };
  final List<WeekPoint> growth = <WeekPoint>[
    for (int w = 7; w >= 0; w--)
      () {
        final DateTime end = DateTime(today.year, today.month, today.day - 7 * w, 23, 59, 59);
        final DateTime stop = w == 0 ? now : end;
        final Engine at = _replayUntil(src.catalog, events, stop.toUtc());
        return WeekPoint(
          weekEnd: stop,
          byDomain: <String, double?>{
            for (final MapEntry<String, List<String>> d in idsByDomain.entries)
              d.key: _domainUnderstanding(at, d.value, stop.toUtc()),
          },
        );
      }(),
  ];

  // Habits over the last four weeks, as strengths.
  final DateTime fourWeeks = nowUtc.subtract(const Duration(days: 28));
  int unsure = 0;
  int hints = 0;
  int kept = 0;
  for (final AttemptEvent e in events) {
    if (e.at.isBefore(fourWeeks)) continue;
    if (e.result == Result.unsure) unsure++;
    if (e.hintLevel > 0) hints++;
    if (e.result == Result.correct && e.attemptNo > 1) kept++;
  }

  return Progress(
    minutesPerDay: days,
    sessionsThisWeek: week.length,
    adventuresCompleted: week.where((Session s) => s.endReason == 'finished').length,
    domains: <DomainBlock>[
      for (final MapEntry<String, List<SkillRow>> e in byDomain.entries)
        DomainBlock(domain: e.key, skills: e.value),
    ],
    misconceptions: tags,
    helped: helped,
    growth: growth,
    habits: Habits(askedWhenUnsure: unsure, usedHints: hints, keptTrying: kept),
    gaps: <String>[for (final Gap g in engine.state.openGaps) g.skill],
  );
}
