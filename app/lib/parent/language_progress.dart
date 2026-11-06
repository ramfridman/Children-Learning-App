import '../content/engine_adapter.dart';
import '../content/models.dart';
import '../engine/course.dart';
import '../engine/engine.dart';
import '../engine/gates.dart';
import '../engine/state.dart';
import '../strings/he.dart';
import '../world/language_placement.dart' show PlacementStatus;
import 'language_settings.dart';

// The parent's progress in one language (docs/design/languages-island.md section 6.3): the skills of the course by strand and
// by status, the gates, the speaking skills, and what to notice. Pure: a pack, the child's engine on that course and the parent's
// switches go in, plain values come out. Nothing here compares languages, children or days, counts a streak or says "you
// have not practised".

/// How many skills of a strand are in each state. A skill that is not started yet is [notStarted].
class StrandProgress {
  const StrandProgress({
    required this.name,
    required this.learning,
    required this.understood,
    required this.remembered,
    required this.revisit,
    required this.notStarted,
    this.startLevel,
  });

  final Str name;
  final int learning;
  final int understood;
  final int remembered;
  final int revisit;
  final int notStarted;

  /// "We start here: level N" after the placement; null while there is no placement result for the strand.
  final int? startLevel;

  int get total => learning + understood + remembered + revisit + notStarted;
  bool get begun => total > notStarted;
}

enum GateState { open, notYet, closedByParent }

class GateView {
  const GateView({required this.name, required this.state});

  final Str name;
  final GateState state;
}

class SpeakingView {
  const SpeakingView({required this.title, required this.said});

  final String title;

  /// `said` (the parent confirmed it); false is "practised". Only "practised" exists until the weekly confirmation is built.
  final bool said;
}

class NoticeView {
  const NoticeView({required this.text, required this.resolved});

  final String text;
  final bool resolved;
}

class LanguageProgress {
  const LanguageProgress({
    required this.course,
    required this.strands,
    required this.gates,
    required this.speaking,
    required this.notices,
  });

  final String course;
  final List<StrandProgress> strands;
  final List<GateView> gates;
  final List<SpeakingView> speaking;
  final List<NoticeView> notices;
}

/// The strands of each course, in the order the page shows them, each with the strand codes of the skills it holds. The
/// codes are the lowercase strand codes of the three syllabi (frame §4.1); a code the table lacks would fall under "more
/// topics", so a test reads the syllabus tables and checks every code is here. Russian numbers (`num`) are words heard and
/// said, so they sit with listening and speaking.
const Map<String, List<(Str, Set<String>)>> languageStrands = <String, List<(Str, Set<String>)>>{
  Course.eng: <(Str, Set<String>)>[
    (He.langStrandEngLisSpk, <String>{'lis', 'spk'}),
    (He.langStrandEngPhon, <String>{'pa', 'ph'}),
    (He.langStrandEngRead, <String>{'rd'}),
    (He.langStrandEngWrite, <String>{'wr'}),
  ],
  Course.heb: <(Str, Set<String>)>[
    (He.langStrandHebOral, <String>{'ol', 'pa'}),
    (He.langStrandHebCode, <String>{'pk', 'dec', 'wr'}),
  ],
  Course.rus: <(Str, Set<String>)>[
    (He.langStrandRusUnderstand, <String>{'lis', 'spk', 'voc', 'grm', 'num'}),
    (He.langStrandRusSounds, <String>{'pho'}),
    (He.langStrandRusLetters, <String>{'let'}),
    (He.langStrandRusRead, <String>{'rea'}),
    (He.langStrandRusWrite, <String>{'wri'}),
  ],
};

/// Which placement strand places each progress strand code (docs/milestones/L-course.md section 4; the placement strands are those of the
/// syllabi, frame section 3.2). English: `o` oral, `l` literacy (letter sounds, reading; no probe asks writing, so writing has no level).
/// Hebrew: `l` oral language and sounds, `c` the code (letters, reading, writing). Russian: `1` understanding, `2` sounds, `3` letters,
/// `4` reading, `5` spelling. All the codes of one progress strand name the same placement strand (a test holds it).
const Map<String, Map<String, String>> placementStrandOfCode = <String, Map<String, String>>{
  Course.eng: <String, String>{'lis': 'o', 'spk': 'o', 'pa': 'l', 'ph': 'l', 'rd': 'l'},
  Course.heb: <String, String>{'ol': 'l', 'pa': 'l', 'pk': 'c', 'dec': 'c', 'wr': 'c'},
  Course.rus: <String, String>{
    'lis': '1',
    'spk': '1',
    'voc': '1',
    'grm': '1',
    'num': '1',
    'pho': '2',
    'let': '3',
    'rea': '4',
    'wri': '5',
  },
};

/// "We start here" for a progress strand of [course]: the level its placement strand found, counted from 1, or null while that strand has
/// not stopped, was not offered, or no placement strand places this progress strand.
int? startLevelOf(String course, Set<String> codes, PlacementStatus? placement) {
  if (placement == null) return null;
  final Map<String, String> map = placementStrandOfCode[course] ?? const <String, String>{};
  for (final String code in codes) {
    final String? strand = map[code];
    final int? entry = strand == null ? null : placement.entryOf(strand);
    if (entry != null) return entry + 1;
  }
  return null;
}

/// The strand codes that are speaking skills (shown only as "practised" or "said", never as a score).
const Set<String> _speakingStrands = <String>{'spk'};

/// The parent's view of one course. [engine] is the child's engine on [content]'s catalogue.
LanguageProgress buildLanguageProgress({
  required PackContent content,
  required Engine engine,
  required DateTime now,
  required LanguageSwitches switches,
  required int ageBand,
  PlacementStatus? placement,
}) {
  // The skills that carry evidence: a roll-up has none of its own, its groups are the skills.
  final List<SkillDoc> skills = <SkillDoc>[
    for (final SkillDoc s in content.skills.values)
      if (!engine.catalog.isRollUp(s.id)) s,
  ]..sort((SkillDoc a, SkillDoc b) => a.id.compareTo(b.id));

  StrandProgress count(Str name, Iterable<SkillDoc> of, {int? startLevel}) {
    int learning = 0, understood = 0, remembered = 0, revisit = 0, notStarted = 0;
    for (final SkillDoc s in of) {
      switch (engine.statusOf(s.id, now)) {
        case SkillStatus.learning || SkillStatus.gap:
          learning++;
        // A trace node that was practised is finished: it is never mastered, so "practised" is as far as it goes (E-1).
        case SkillStatus.freshMastery || SkillStatus.practised:
          understood++;
        case SkillStatus.durableMastery:
          remembered++;
        case SkillStatus.needsRevisit:
          revisit++;
        case SkillStatus.notStarted || SkillStatus.ready:
          notStarted++;
      }
    }
    return StrandProgress(
      name: name,
      learning: learning,
      understood: understood,
      remembered: remembered,
      revisit: revisit,
      notStarted: notStarted,
      startLevel: startLevel,
    );
  }

  final List<(Str, Set<String>)> table = languageStrands[content.course] ?? const <(Str, Set<String>)>[];
  final Set<String> known = <String>{for (final (Str, Set<String>) t in table) ...t.$2};
  final List<StrandProgress> strands = <StrandProgress>[
    for (final (Str name, Set<String> codes) in table)
      if (skills.any((SkillDoc s) => codes.contains(s.strand)))
        count(
          name,
          skills.where((SkillDoc s) => codes.contains(s.strand)),
          startLevel: startLevelOf(content.course, codes, placement),
        ),
  ];
  // Skills with no strand, or one the table does not know, stay together rather than vanish.
  final List<SkillDoc> rest = skills.where((SkillDoc s) => !known.contains(s.strand)).toList();
  if (rest.isNotEmpty) strands.add(count(He.langStrandAll, rest));

  // The gates: open, not yet, or held closed by the parent's switch.
  final GateInput input = GateInput(
    mastery: masteryLevels(engine),
    ageBand: ageBand,
    presentationBand: switches.presentationBand(ageBand),
    switchesOn: switches.gateSwitchesOn,
    route: switches.route,
  );
  final List<GateView> gates = <GateView>[
    for (final CourseGate g in courseGates(
      content,
    )..sort((CourseGate a, CourseGate b) => a.id.compareTo(b.id)))
      GateView(
        name: switch (g.course) {
          Course.eng => He.areaLangGateEng,
          Course.rus => He.areaLangGateRus,
          _ => He.areaLangGates,
        },
        state: switch (gateResult(g, input)) {
          GateResult(open: true) => GateState.open,
          GateResult(reasons: final List<GateReason> r) when r.contains(GateReason.parentHolds) =>
            GateState.closedByParent,
          _ => GateState.notYet,
        },
      ),
  ];

  final List<SpeakingView> speaking = <SpeakingView>[
    for (final SkillDoc s in skills)
      if (_speakingStrands.contains(s.strand) && (engine.state.skills[s.id]?.started ?? false))
        SpeakingView(title: s.title, said: false),
  ];

  final List<NoticeView> notices = <NoticeView>[
    for (final MapEntry<String, TagState> t in engine.state.tags.entries)
      if (t.value.status != TagStatus.suspected && content.tags[t.key] != null)
        NoticeView(text: content.tags[t.key]!.parentText, resolved: t.value.status == TagStatus.resolved),
  ];
  return LanguageProgress(
    course: content.course,
    strands: strands,
    gates: gates,
    speaking: speaking,
    notices: notices,
  );
}

/// A language's engine from its pack and the child's answers in it, for the progress page (the same replay Today's Adventure
/// uses; nothing is stored).
Engine languageEngine(PackContent content) => Engine(catalog: engineCatalog(content));
