import '../data/app_database.dart';
import '../engine/course.dart';
import '../engine/engine.dart';
import '../engine/gates.dart';
import '../engine/state.dart';
import '../engine/types.dart';
import '../play/response_code.dart';
import 'models.dart';

/// Turns the documents of a pack into what the learning engine reads.
Catalog engineCatalog(PackContent content) {
  Representation rep(String s) => representationOf(s) ?? Representation.concrete;
  return Catalog(
    skills: <SkillNode>[
      for (final SkillDoc s in content.skills.values)
        SkillNode(
          id: s.id,
          course: s.course,
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
          bundle: s.bundle,
          setCoverage: s.setCoverage,
          soundRight: s.soundRight == 'accepts' ? SoundRightPolicy.accepts : SoundRightPolicy.teaches,
          letters: s.letters,
          speaking: s.strand == 'spk',
          writing: s.writing,
        ),
    ],
    items: <ItemMeta>[
      for (final Activity a in content.activities.values)
        // What is no evidence is not an item of the engine: a teach screen; a step of a course that is never scored (a chant, a story only
        // heard, a personal turn, a movement); and a say step of a skill that is not a speaking one (a spoken answer counts for a speaking
        // skill alone). Counted as items, their words would be groups of a set that no answer can ever cover, and a visit could pick one.
        if (!a.teachScreen && !_writesNoAnswer(a) && !_saysForNothing(a, content))
          ItemMeta(
            id: a.id,
            course: a.course,
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
            writingMode: a is LetterWriteActivity ? writingModeOf(a) : null,
            cue: a is LetterWriteActivity ? a.cue : null,
            // A trace with the start dot only marks its letter as practised: an LS02 trace of a letter, or a stroke of the pre-writing
            // trace (T04, HEB-A-14), whose paths are the four strokes of the pre-writing skill (rule E-1).
            startGuide: switch (a) {
              LetterWriteActivity() => a.startGuide,
              TraceActivity() => !a.fullGuide,
              _ => false,
            },
            practiceOnly: a is LetterWriteActivity && a.practiceOnly,
            pairWith: a.pairWith,
            speech: a is SayItActivity,
          ),
    ],
    tags: <TagInfo>[
      for (final TagDoc t in content.tags.values)
        TagInfo(
          id: t.id,
          course: t.course,
          skills: t.skills,
          repairActivities: t.repairActivities,
          preferredRepresentations: <Representation>[
            for (final String r in t.preferredRepresentations) rep(r),
          ],
        ),
    ],
  );
}

/// A step of a course that is never scored (a chant, a story only heard, a personal turn, a movement) writes no answer. The intro of a
/// letter (LS02) is left to the writing rules, which already know it.
bool _writesNoAnswer(Activity a) => a.isLanguage && a.unscored && a is! LetterWriteActivity;

/// A say step (LS09) of a skill that is not a speaking one: its answers are ignored by the engine, whatever they are.
bool _saysForNothing(Activity a, PackContent content) =>
    a is SayItActivity && content.skills[a.skillId]?.strand != 'spk';

/// How the engine reads the mode of an LS02 item: a trace is practice, a copy a hinted answer, a memory answer a full one. An intro is
/// never answered, so it has no mode.
WritingMode? writingModeOf(LetterWriteActivity a) => switch (a.mode) {
  LetterMode.intro => null,
  LetterMode.trace => WritingMode.trace,
  LetterMode.copy => WritingMode.copy,
  LetterMode.memory => WritingMode.memory,
};

/// The gates of a pack as the engine reads them (docs/languages/frame.md section 3.3.6).
List<CourseGate> courseGates(PackContent content) => <CourseGate>[
  for (final GateDoc g in content.gates.values)
    CourseGate(
      id: g.id,
      course: g.course,
      requires: g.requires,
      requireAtLeast: <SkillQuota>[
        for (final q in g.requireAtLeast) SkillQuota(skills: q.skills, count: q.count),
      ],
      holds: g.holds,
      minAge: g.minAge,
      neverUnderBand: g.neverUnderBand,
      durableBelowBand: g.durableBelowBand,
      switchName: g.switchName,
      switchEffect: switch (g.switchEffect) {
        'closes' => SwitchEffect.closes,
        'opens' => SwitchEffect.opens,
        _ => null,
      },
      routeBypass: g.routeBypass,
    ),
];

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
  // The course of the pack the answer was given in; a `lang-` id that names no course matches no item at all.
  course: Course.ofPackId(row.packId) ?? '',
  // A heard word of a say-it activity (written only for a confident result); a spoken choice answer is a plain answer.
  viaSpeech: row.template == 'say_it' && row.input == 'voice',
  // The second tag of one move (see [AttemptEvent.secondary]).
  secondary: row.result == 'incorrect' && ResponseCode.isAlso(row.response),
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
