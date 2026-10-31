import '../content/models.dart';
import '../data/app_database.dart';
import '../engine/engine.dart';
import '../rewards/award.dart';
import 'placement.dart';
import 'todays_adventure.dart';
import 'world_state.dart' show missionItemIds;

/// Feeds Today's Adventure from what the app has (rule section 2): the pack's paths, the finished lessons, the child's
/// visits and the engine's due checks. This is the only place that turns a clock reading into a day number; the rule
/// itself reads nothing but its input.
TodaysAdventure todaysAdventureFor({
  required PackContent content,
  required Engine engine,
  required Iterable<Attempt> attempts,
  required Iterable<Session> sessions,
  required Map<String, int> finished,
  required DateTime now,
  required int band,
}) => todaysAdventure(
  adventureInput(
    content: content,
    engine: engine,
    attempts: attempts,
    sessions: sessions,
    finished: finished,
    now: now,
    band: band,
  ),
);

/// The rule's input for one child at [now]. A land is open when its path has a lesson in the installed pack.
AdventureInput adventureInput({
  required PackContent content,
  required Engine engine,
  required Iterable<Attempt> attempts,
  required Iterable<Session> sessions,
  required Map<String, int> finished,
  required DateTime now,
  required int band,
}) {
  final int today = Engine.dayKey(now);
  final Map<TrophyLand, List<PathLesson>> paths = <TrophyLand, List<PathLesson>>{
    for (final TrophyLand land in TrophyLand.values)
      land: <PathLesson>[
        for (final Lesson l in landPath(content, land.domain)) PathLesson(l.id, _levelOf(content, l, land)),
      ],
  };
  return AdventureInput(
    today: today,
    band: band,
    enabledLands: <TrophyLand>{
      for (final MapEntry<TrophyLand, List<PathLesson>> e in paths.entries)
        if (e.value.isNotEmpty) e.key,
    },
    paths: paths,
    finished: finished,
    visits: visitsFrom(content, attempts, sessions),
    due: <DueSkill>[
      for (final String id in engine.dueChecks(now))
        if (_dueSkill(content, engine, id, now, today) case final DueSkill d) d,
    ],
  );
}

/// A due check as the rule wants it, or null when its land is unknown or its mission would have nothing to ask.
DueSkill? _dueSkill(PackContent content, Engine engine, String skillId, DateTime now, int today) {
  final String? domain = content.skills[skillId]?.domain;
  final TrophyLand? land = domain == null ? null : TrophyLand.ofDomain(domain);
  if (land == null || missionItemIds(engine, skillId).isEmpty) return null;
  return DueSkill(
    skillId: skillId,
    land: land,
    dueAt: engine.nextCheckAt(skillId) ?? now,
    reviewedToday: engine.state.skills[skillId]?.lastReviewDay == today,
  );
}

final RegExp _skillBand = RegExp(r'^[A-Z]+-([ABC])-\d+$');

/// A lesson's level on its land: the highest band among its skills of that land's domain (`NUM-A-03` is A, level 0),
/// read from the skill id, which the pack's skill ids all follow.
int _levelOf(PackContent content, Lesson lesson, TrophyLand land) {
  int level = 0;
  for (final String id in lesson.skillIds) {
    if (content.skills[id]?.domain != land.domain) continue;
    final String? band = _skillBand.firstMatch(id)?.group(1);
    if (band != null && band.codeUnitAt(0) - 0x41 > level) level = band.codeUnitAt(0) - 0x41;
  }
  return level;
}

/// The child's attempts grouped into visits, oldest first (rule section 2.1). Attempts are grouped by session, answers
/// from another device by their remote session, and older answers with neither by runs of the same lesson. A visit that
/// is neither the warm-up, a revisit nor a lesson of the pack is left out, and so is one whose land is unknown.
List<Visit> visitsFrom(PackContent content, Iterable<Attempt> attempts, Iterable<Session> sessions) {
  final Map<int, Session> byId = <int, Session>{for (final Session s in sessions) s.id: s};
  final Map<String, Session> byRemote = <String, Session>{
    for (final Session s in sessions)
      if (s.remoteKey != null) s.remoteKey!: s,
  };
  // Answers inside a group in the order they were written.
  final Map<String, List<Attempt>> groups = <String, List<Attempt>>{};
  Attempt? before;
  int legacy = 0;
  for (final Attempt a in attempts.toList()..sort((Attempt x, Attempt y) => x.id.compareTo(y.id))) {
    final String key;
    if (a.sessionId != null) {
      key = 's${a.sessionId}';
    } else if (a.remoteSession != null) {
      key = 'r${a.remoteSession}';
    } else {
      final bool sameRun =
          before != null &&
          before.sessionId == null &&
          before.remoteSession == null &&
          before.lessonId == a.lessonId;
      if (!sameRun) legacy++;
      key = 'l$legacy';
    }
    (groups[key] ??= <Attempt>[]).add(a);
    before = a;
  }
  // Each visit with its first answer, which orders the visits: by its time, then by the smallest attempt id.
  final List<(Attempt, Visit)> visits = <(Attempt, Visit)>[];
  for (final List<Attempt> answers in groups.values) {
    final Attempt first = answers.first;
    final Session? session = first.sessionId != null
        ? byId[first.sessionId]
        : first.remoteSession != null
        ? byRemote[first.remoteSession]
        : null;
    final Visit? v = _visit(content, answers, session);
    if (v != null) visits.add((first, v));
  }
  visits.sort(((Attempt, Visit) a, (Attempt, Visit) b) {
    final int byTime = a.$1.at.compareTo(b.$1.at);
    return byTime != 0 ? byTime : a.$1.id.compareTo(b.$1.id);
  });
  return <Visit>[for (final (Attempt, Visit) e in visits) e.$2];
}

Visit? _visit(PackContent content, List<Attempt> answers, Session? session) {
  final Attempt first = answers.first;
  final Attempt last = answers.last;
  final VisitKind kind;
  final String id;
  final String? domain;
  if (first.lessonId == placementId) {
    kind = VisitKind.warmUp;
    id = first.lessonId;
    domain = content.skills[first.skillId]?.domain;
  } else if (first.lessonId.startsWith('mission-')) {
    kind = VisitKind.revisit;
    id = first.skillId;
    domain = content.skills[first.skillId]?.domain;
  } else if (content.lessons[first.lessonId] case final Lesson l) {
    kind = VisitKind.lesson;
    id = l.id;
    // The first skill decides, so `butterflies`, on both the numbers and the colours path, belongs to Counting Hills.
    domain = l.skillIds.isEmpty ? null : content.skills[l.skillIds.first]?.domain;
  } else {
    return null;
  }
  final TrophyLand? land = domain == null ? null : TrophyLand.ofDomain(domain);
  if (land == null) return null;
  return Visit(
    kind: kind,
    land: land,
    id: id,
    day: Engine.dayKey(last.at),
    end: switch (session?.endReason) {
      'finished' => VisitEnd.finished,
      'home' => VisitEnd.home,
      'limit' => VisitEnd.limit,
      _ => VisitEnd.open,
    },
    lastIncorrect: last.result == 'incorrect',
  );
}
