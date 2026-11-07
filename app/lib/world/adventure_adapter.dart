import '../content/models.dart';
import '../data/app_database.dart';
import '../engine/course.dart';
import '../engine/engine.dart';
import '../rewards/award.dart';
import 'adventure_land.dart';
import 'check_visits.dart';
import 'language_placement.dart' show PlacementStatus, placedLanguageLessons;
import 'path_gate.dart';
import 'placement.dart';
import 'todays_adventure.dart';
import 'world_state.dart' show missionItemIds;

/// A language course the child may play (docs/languages/frame.md section 3.7): its installed pack, and the child's engine on it
/// (an engine built on that course's catalogue, so its due checks are the course's own).
class LanguageCourse {
  const LanguageCourse({
    required this.content,
    required this.engine,
    this.assumed = const <String>{},
    this.placement,
  });

  final PackContent content;
  final Engine engine;

  /// The skills the child's placement took as known (those below each strand's entry point). A lesson whose skills are all in it counts
  /// as passed on the path ([placedLanguageLessons]).
  final Set<String> assumed;

  /// Where the placement stands, or null when the pack has no placement game.
  final PlacementStatus? placement;

  String get course => content.course;
}

/// Feeds Today's Adventure from what the app has (rule section 2): the pack's paths, the finished lessons, the child's
/// visits and the engine's due checks. This is the only place that turns a clock reading into a day number; the rule
/// itself reads nothing but its input.
///
/// [languages] are the language packs that are installed and [enabledCourses] the courses the parent turned on for this
/// child: each language that is both is a land of its own (docs/languages/frame.md section 3.7). One that is off is not a
/// land, and its lessons, visits and due checks are left out as if it were not there.
TodaysAdventure todaysAdventureFor({
  required PackContent content,
  required Engine engine,
  required Iterable<Attempt> attempts,
  required Iterable<Session> sessions,
  required Map<String, int> finished,
  required DateTime now,
  required int band,
  Iterable<LanguageCourse> languages = const <LanguageCourse>[],
  Set<String> enabledCourses = const <String>{},
}) => todaysAdventure(
  adventureInput(
    content: content,
    engine: engine,
    attempts: attempts,
    sessions: sessions,
    finished: finished,
    now: now,
    band: band,
    languages: languages,
    enabledCourses: enabledCourses,
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
  Iterable<LanguageCourse> languages = const <LanguageCourse>[],
  Set<String> enabledCourses = const <String>{},
}) {
  final int today = Engine.dayKey(now);
  final List<LanguageCourse> playable = <LanguageCourse>[
    for (final LanguageCourse l in languages)
      if (Course.isLanguage(l.course) && enabledCourses.contains(l.course)) l,
  ];
  final Map<AdventureLand, List<PathLesson>> paths = <AdventureLand, List<PathLesson>>{
    for (final TrophyLand land in TrophyLand.values)
      land: _pathOf(content, land.domain, lockedLessons(content, land.domain, engine.isUnlocked)),
    for (final LanguageCourse c in playable)
      LanguageLand(c.course): <PathLesson>[
        for (final Lesson l in landPath(c.content, Course.languagesDomain))
          PathLesson(l.id, lessonLevel(c.content, l, Course.languagesDomain)),
      ],
  };
  final Map<String, int> seen = withPlaced(finished, playable);
  final List<Visit> visits = visitsFrom(
    content,
    attempts,
    sessions,
    languages: playable.map((LanguageCourse c) => c.content),
  );
  return AdventureInput(
    today: today,
    band: band,
    enabledLands: <AdventureLand>{
      for (final MapEntry<AdventureLand, List<PathLesson>> e in paths.entries)
        if (e.value.isNotEmpty) e.key,
    },
    paths: paths,
    finished: seen,
    visits: visits,
    due: <DueSkill>[
      for (final String id in engine.dueChecks(now))
        if (_dueSkill(content, engine, id, now, today) case final DueSkill d) d,
      for (final LanguageCourse c in playable)
        for (final String id in c.engine.dueChecks(now))
          if (_dueSkill(c.content, c.engine, id, now, today, land: LanguageLand(c.course))
              case final DueSkill d)
            d,
      // A course's check visit takes the revisit's slot after every revisit of a fresh skill (owner's OK 2026-11-07).
      for (final LanguageCourse c in playable)
        if (_checkVisit(c, seen, visits, now, band) case final DueSkill d) d,
    ],
  );
}

/// The course's check visit of today as the rule's due skill, or null.
DueSkill? _checkVisit(
  LanguageCourse c,
  Map<String, int> seen,
  Iterable<Visit> visits,
  DateTime now,
  int band,
) => checkVisitDue(
  content: c.content,
  engine: c.engine,
  assumed: c.assumed,
  seen: seen,
  visits: visits,
  now: now,
  band: band,
);

/// A land's path for the rule: its lessons in order, each with its level, and the ones the path gate holds back marked [locked].
List<PathLesson> _pathOf(PackContent content, String domain, Set<String> locked) => <PathLesson>[
  for (final Lesson l in landPath(content, domain))
    PathLesson(l.id, lessonLevel(content, l, domain), locked: locked.contains(l.id)),
];

/// [finished] with the lessons that each course's placement showed the child already knows counted once, as a land's warm-up does
/// ([placedLanguageLessons]): the path opens at the placed level, and the bottle and the course home agree on it.
Map<String, int> withPlaced(Map<String, int> finished, Iterable<LanguageCourse> courses) {
  final Map<String, int> out = <String, int>{...finished};
  for (final LanguageCourse c in courses) {
    for (final String id in placedLanguageLessons(c.content, c.assumed)) {
      if ((out[id] ?? 0) == 0) out[id] = 1;
    }
  }
  return out;
}

/// What the course home offers next: Today's Adventure run on this course alone (docs/languages/frame.md sections 3.5 and 3.7), so
/// the rule is the bottle's and the two can never disagree. A visit is one course: only this course's lessons, due checks and visits
/// are read. [attempts], [sessions] and [finished] are the child's (other courses' are left out here).
TodaysAdventure courseStopFor({
  required LanguageCourse course,
  required Iterable<Attempt> attempts,
  required Iterable<Session> sessions,
  required Map<String, int> finished,
  required DateTime now,
  required int band,
}) {
  final int today = Engine.dayKey(now);
  final LanguageLand land = LanguageLand(course.course);
  final List<PathLesson> path = <PathLesson>[
    for (final Lesson l in landPath(course.content, Course.languagesDomain))
      PathLesson(l.id, lessonLevel(course.content, l, Course.languagesDomain)),
  ];
  if (path.isEmpty) return const TodaysAdventure.none();
  final Map<String, int> seen = withPlaced(finished, <LanguageCourse>[course]);
  final List<Visit> visits = <Visit>[
    for (final Visit v in visitsFrom(null, attempts, sessions, languages: <PackContent>[course.content]))
      if (v.land == land) v,
  ];
  return todaysAdventure(
    AdventureInput(
      today: today,
      band: band,
      enabledLands: <AdventureLand>{land},
      paths: <AdventureLand, List<PathLesson>>{land: path},
      finished: seen,
      visits: visits,
      due: <DueSkill>[
        for (final String id in course.engine.dueChecks(now))
          if (_dueSkill(course.content, course.engine, id, now, today, land: land) case final DueSkill d) d,
        if (_checkVisit(course, seen, visits, now, band) case final DueSkill d) d,
      ],
    ),
  );
}

/// A due check as the rule wants it, or null when its land is unknown or its mission would have nothing to ask. A language
/// skill's land is its course, given as [land]; a land's skill finds its land by its domain.
DueSkill? _dueSkill(
  PackContent content,
  Engine engine,
  String skillId,
  DateTime now,
  int today, {
  AdventureLand? land,
}) {
  final String? domain = content.skills[skillId]?.domain;
  final AdventureLand? place = land ?? (domain == null ? null : TrophyLand.ofDomain(domain));
  if (place == null || content.skills[skillId] == null || missionItemIds(engine, skillId).isEmpty) {
    return null;
  }
  return DueSkill(
    skillId: skillId,
    land: place,
    dueAt: engine.nextCheckAt(skillId) ?? now,
    reviewedToday: engine.state.skills[skillId]?.lastReviewDay == today,
  );
}

/// The child's attempts grouped into visits, oldest first (rule section 2.1). Attempts are grouped by session, answers
/// from another device by their remote session, and older answers with neither by runs of the same lesson. A visit that
/// is neither the warm-up, a revisit nor a lesson of the pack is left out, and so is one whose land is unknown.
List<Visit> visitsFrom(
  PackContent? content,
  Iterable<Attempt> attempts,
  Iterable<Session> sessions, {
  Iterable<PackContent> languages = const <PackContent>[],
}) {
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
          before.packId == a.packId &&
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
    final Visit? v = _visit(content, languages, answers, session);
    if (v != null) visits.add((first, v));
  }
  visits.sort(((Attempt, Visit) a, (Attempt, Visit) b) {
    final int byTime = a.$1.at.compareTo(b.$1.at);
    return byTime != 0 ? byTime : a.$1.id.compareTo(b.$1.id);
  });
  return <Visit>[for (final (Attempt, Visit) e in visits) e.$2];
}

Visit? _visit(
  PackContent? content,
  Iterable<PackContent> languages,
  List<Attempt> answers,
  Session? session,
) {
  final Attempt first = answers.first;
  final Attempt last = answers.last;
  final VisitKind kind;
  final String id;
  final AdventureLand? land;
  // A visit belongs to one course: a language's answers carry the id of its pack, and its skills their course in the id.
  final PackContent? language = languages.where((PackContent p) => p.packId == first.packId).firstOrNull;
  AdventureLand? ofSkill(String skillId) {
    final String course = Course.ofSkillId(skillId);
    if (course != Course.core) {
      return languages.any((PackContent p) => p.course == course) ? LanguageLand(course) : null;
    }
    final String? domain = content?.skills[skillId]?.domain;
    return domain == null ? null : TrophyLand.ofDomain(domain);
  }

  final String? placementCourse = courseOfPlacementId(first.lessonId);
  if (placementCourse != null) {
    kind = VisitKind.warmUp;
    id = first.lessonId;
    land = ofSkill(first.skillId);
  } else if (first.lessonId.startsWith('mission-')) {
    kind = VisitKind.revisit;
    id = first.skillId;
    land = ofSkill(first.skillId);
  } else if (Course.ofPackId(first.packId) != Course.core && language == null) {
    return null; // a language that is not a land (turned off, or not installed) is left out whole
  } else if (language != null && language.lessons[first.lessonId] != null) {
    kind = VisitKind.lesson;
    id = first.lessonId;
    land = LanguageLand(language.course);
  } else if (content?.lessons[first.lessonId] case final Lesson l) {
    kind = VisitKind.lesson;
    id = l.id;
    // The first skill decides, so `butterflies`, on both the numbers and the colours path, belongs to Counting Hills.
    land = l.skillIds.isEmpty ? null : ofSkill(l.skillIds.first);
  } else {
    return null;
  }
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
    check: kind == VisitKind.revisit && isCheckVisitId(first.lessonId),
  );
}
