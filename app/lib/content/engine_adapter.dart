import '../data/app_database.dart';
import '../engine/engine.dart';
import '../engine/state.dart';
import '../engine/types.dart';
import 'models.dart';

/// Turns the documents of a pack into what the learning engine reads.
Catalog engineCatalog(PackContent content) {
  Representation rep(String s) => representationOf(s) ?? Representation.concrete;
  return Catalog(
    skills: <SkillNode>[
      for (final SkillDoc s in content.skills.values)
        SkillNode(
          id: s.id,
          prerequisites: s.prerequisites,
          core: s.core,
          representations: <Representation>{for (final String r in s.representations) rep(r)},
          tags: s.misconceptions.toSet(),
          initialStabilityDays: s.initialStabilityDays,
          targetRetention: s.targetRetention,
          needSuccesses: s.masteryRequires['successes'] as int?,
          needDays: s.masteryRequires['days'] as int?,
          needRepresentations: s.masteryRequires['representations'] as int?,
          needChecks: s.masteryRequires['checks'] as int?,
        ),
    ],
    items: <ItemMeta>[
      for (final Activity a in content.activities.values)
        ItemMeta(
          id: a.id,
          skills: <String, double>{for (final Skill s in a.skills) s.id: s.weight},
          purpose: purposeOf(a.purpose),
          checkType: checkTypeOf(a.checkType),
          representation: rep(a.representation),
          variantGroup: a.variantGroup,
          difficulty: a.difficulty,
          optionCount: a.optionCount,
          tags: a.engineTags,
          contradicts: a.contradicts,
          revision: a.revision,
        ),
    ],
    tags: <TagInfo>[
      for (final TagDoc t in content.tags.values)
        TagInfo(
          id: t.id,
          skills: t.skills,
          repairActivities: t.repairActivities,
          preferredRepresentations: <Representation>[
            for (final String r in t.preferredRepresentations) rep(r),
          ],
        ),
    ],
  );
}

/// One row of the `attempt` table as the engine reads it.
AttemptEvent eventOf(Attempt row) => AttemptEvent(
  id: row.id,
  at: row.at.toUtc(),
  activityId: row.activityId,
  result: resultOf(row.result),
  hintLevel: row.hintLevel,
  tag: row.misconceptionTag,
  sessionId: row.sessionId,
  attemptNo: row.attemptNo,
);

/// What the engine concluded about one child, as plain text for the developer page.
String engineSummary(Engine engine, DateTime now) {
  final StringBuffer b = StringBuffer();
  final List<String> ids = engine.catalog.skills.keys.toList()..sort();
  for (final String id in ids) {
    final SkillState? s = engine.state.skills[id];
    final String status = engine.statusOf(id, now).name;
    b.writeln(
      s == null || !s.started
          ? '$id: $status'
          : '$id: $status  p=${s.p.toStringAsFixed(2)}  answers=${s.n} (right ${s.nCorrect}, not sure ${s.nUnsure})  independent successes=${s.successes}',
    );
  }
  for (final MapEntry<String, TagState> t in engine.state.tags.entries) {
    b.writeln('misconception ${t.key}: ${t.value.status.name}  score=${t.value.score.toStringAsFixed(2)}');
  }
  for (final Gap g in engine.state.gaps) {
    b.writeln(
      'gap: ${g.skill} (found from ${g.origin} in ${g.probes} probes)${g.repaired ? ', repaired' : ''}',
    );
  }
  final List<String> due = engine.dueChecks(now);
  if (due.isNotEmpty) b.writeln('checks due: ${due.join(', ')}');
  if (engine.state.tags.isEmpty && engine.state.gaps.isEmpty && due.isEmpty) {
    b.writeln('no misconceptions, gaps or checks due');
  }
  return b.toString().trimRight();
}
