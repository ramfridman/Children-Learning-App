import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/language_providers.dart';
import '../app/sync_providers.dart';
import '../child/languages_doors.dart' show languageName;
import '../data/app_database.dart' show Profile;
import '../data/child_name.dart';
import '../design/app_text.dart';
import '../design/components.dart';
import '../design/tokens.g.dart';
import '../engine/course.dart';
import '../strings/he.dart';
import 'language_progress.dart';
import 'language_settings.dart';
import 'rules_screen.dart';

// The parent's pages for the languages (docs/design/languages-island.md section 6): the "Languages" card of a child, a page for
// each language with the switches of docs/languages/frame.md section 1.4, the home-language questionnaire, and the progress in a
// language. Adult UI, no niqqud, the parent's visual language as today. Every change is saved at once and travels with the
// family's rules.

Widget _card(String title, List<Widget> children, {Key? key}) => Container(
  key: key,
  margin: const EdgeInsets.only(bottom: 16),
  padding: const EdgeInsets.all(16),
  decoration: BoxDecoration(
    color: TokenColors.paper,
    borderRadius: BorderRadius.circular(TokenRadius.md),
    border: Border.all(color: TokenColors.hairline, width: TokenBorder.thin),
  ),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
      if (title.isNotEmpty) ...<Widget>[
        Text(title, style: AppText.parent(TokenType.parentH2)),
        const SizedBox(height: 8),
      ],
      ...children,
    ],
  ),
);

Widget _page(BuildContext context, String title, VoidCallback onClose, List<Widget> children) => Scaffold(
  backgroundColor: TokenColors.parentBg,
  appBar: AppBar(
    backgroundColor: TokenColors.night,
    foregroundColor: Colors.white,
    title: Text(title, style: AppText.parent(TokenType.parentH2, color: Colors.white)),
    leading: IconButton(icon: const Icon(Icons.arrow_forward_rounded), onPressed: onClose),
  ),
  body: Align(
    alignment: Alignment.topCenter,
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 640),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
      ),
    ),
  ),
);

/// A row with a title and a line of words under it (a state said in words, not only by the colour of the switch), and a
/// switch at the start, 52 by 32, in a row 56 high.
class _SwitchRow extends StatelessWidget {
  const _SwitchRow({
    super.key,
    required this.title,
    required this.help,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String help;
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(minHeight: 56),
    child: Row(
      children: <Widget>[
        Switch(value: value, onChanged: onChanged),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(title, style: AppText.fixed(size: 16, weight: 700, lineHeight: 1.5)),
              Text(help, style: AppText.parent(TokenType.parentSmall, color: TokenColors.inkSoft)),
            ],
          ),
        ),
      ],
    ),
  );
}

String _fill(Str s, Map<String, String> values) => s.fill(values);

Str _progressButton(String course) => switch (course) {
  Course.eng => He.areaLangProgressEng,
  Course.heb => He.areaLangProgressHeb,
  _ => He.areaLangProgressRus,
};

/// The rules and settings of one child: the Languages card (a row for each language, in the order of the doors) and the time
/// rules.
class ChildSettingsScreen extends ConsumerWidget {
  const ChildSettingsScreen({super.key, required this.profile, required this.onClose});

  final Profile profile;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final FamilyLanguages languages = ref.watch(languagesProvider).value ?? const FamilyLanguages();
    return _page(
      context,
      _fill(He.childSettingsTitle, <String, String>{'child': displayChildName(profile.name)}),
      onClose,
      <Widget>[
        _card(He.areaLanguages.text, <Widget>[
          Text(He.areaLanguagesHelp.text, style: AppText.parent(TokenType.parentSmall)),
          const SizedBox(height: 8),
          for (final String course in Course.languages) ...<Widget>[
            const Divider(height: 1, color: TokenColors.hairline),
            _LanguageRow(profile: profile, course: course, on: languages.of(profile.id, course).on),
          ],
        ]),
        _card(He.timeTitle.text, <Widget>[
          ParentButton(
            key: const Key('open-time-rules'),
            label: He.areaTimeOpen.text,
            quiet: true,
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (BuildContext c) => RulesScreen(onClose: () => Navigator.pop(c)),
              ),
            ),
          ),
        ]),
      ],
    );
  }
}

Future<void> _save(WidgetRef ref, String childId, String course, LanguageSwitches next) async {
  await ref.read(languagesProvider.notifier).setSwitches(childId, course, next);
  unawaited(ref.read(syncRunnerProvider).now(force: true));
}

class _LanguageRow extends ConsumerWidget {
  const _LanguageRow({required this.profile, required this.course, required this.on});

  final Profile profile;
  final String course;
  final bool on;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String name = languageName(course).text;
    final LanguageSwitches now =
        ref.watch(languagesProvider).value?.of(profile.id, course) ?? const LanguageSwitches();
    return InkWell(
      key: Key('language-row-$course'),
      onTap: () => _openPage(context),
      child: Semantics(
        label: _fill(He.areaLangRowSemantics, <String, String>{'lang': name}),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 56),
          child: Row(
            children: <Widget>[
              Semantics(
                label: _fill(He.areaLangSwitchSemantics, <String, String>{'lang': name}),
                child: Switch(
                  key: Key('language-switch-$course'),
                  value: on,
                  onChanged: (bool v) async {
                    await _save(ref, profile.id, course, now.copyWith(on: v));
                    // Turning Russian on for the first time asks the home-language questions.
                    if (v && course == Course.rus && now.questionnaire.isEmpty && context.mounted) {
                      await Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (BuildContext c) => QuestionnairePage(profile: profile, course: course),
                        ),
                      );
                    }
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(name, style: AppText.parent(TokenType.parentH3)),
                    Text(
                      on ? He.areaLangStateOn.text : He.areaLangStateOff.text,
                      style: AppText.parent(TokenType.parentSmall, color: TokenColors.inkSoft),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_left_rounded, color: TokenColors.inkSoft),
            ],
          ),
        ),
      ),
    );
  }

  void _openPage(BuildContext context) => Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (BuildContext c) => LanguagePage(profile: profile, course: course),
    ),
  );
}

/// One language's page: whether it is on, the lesson settings of its course, the questionnaire, and the way to its progress.
class LanguagePage extends ConsumerWidget {
  const LanguagePage({super.key, required this.profile, required this.course});

  final Profile profile;
  final String course;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String name = languageName(course).text;
    final LanguageSwitches s =
        ref.watch(languagesProvider).value?.of(profile.id, course) ?? const LanguageSwitches();
    void set(LanguageSwitches next) => unawaited(_save(ref, profile.id, course, next));
    final Map<String, String> byLang = <String, String>{'lang': name};
    return _page(context, '$name · ${displayChildName(profile.name)}', () => Navigator.pop(context), <Widget>[
      _card(name, <Widget>[
        _SwitchRow(
          key: const Key('page-on'),
          title: He.areaLangSwitch.text,
          help: s.on ? _fill(He.areaLangSwitchOnHelp, byLang) : He.areaLangSwitchOffHelp.text,
          value: s.on,
          onChanged: (bool v) => set(s.copyWith(on: v)),
        ),
      ]),
      _card(He.areaLangLessons.text, <Widget>[
        _SwitchRow(
          key: const Key('page-voice'),
          title: He.areaVoice.text,
          help: course == Course.heb ? He.areaLangVoiceHelpHeb.text : _fill(He.areaLangVoiceHelp, byLang),
          value: s.voice,
          onChanged: (bool v) => set(s.copyWith(voice: v)),
        ),
        const Divider(height: 1, color: TokenColors.hairline),
        _SwitchRow(
          key: const Key('page-personal'),
          title: He.areaLangPersonal.text,
          help: He.areaLangPersonalHelp.text,
          value: s.personal,
          onChanged: (bool v) => set(s.copyWith(personal: v)),
        ),
        if (course == Course.eng) ...<Widget>[
          const Divider(height: 1, color: TokenColors.hairline),
          _SwitchRow(
            key: const Key('page-oral-only'),
            title: He.areaLangOralOnly.text,
            help: He.areaLangOralOnlyHelp.text,
            value: s.oralOnly,
            onChanged: (bool v) => set(s.copyWith(oralOnly: v)),
          ),
        ],
        if (course == Course.rus) ...<Widget>[
          const Divider(height: 1, color: TokenColors.hairline),
          _SwitchRow(
            key: const Key('page-letters5'),
            title: He.areaLangLetters.text,
            help: s.lettersBefore5 ? He.areaLangLettersOn.text : He.areaLangLettersOff.text,
            value: s.lettersBefore5,
            onChanged: (bool v) => set(s.copyWith(lettersBefore5: v)),
          ),
          const Divider(height: 1, color: TokenColors.hairline),
          _StressRow(switches: s, onChanged: set),
        ],
        if (course == Course.heb) ...<Widget>[
          const Divider(height: 1, color: TokenColors.hairline),
          _SwitchRow(
            key: const Key('page-read-check'),
            title: He.areaLangReadCheck.text,
            help: He.areaLangReadCheckHelp.text,
            value: s.readCheck,
            onChanged: (bool v) => set(s.copyWith(readCheck: v)),
          ),
        ],
        const Divider(height: 1, color: TokenColors.hairline),
        _BandRow(switches: s, ageBand: profile.ageBand, onChanged: set),
      ]),
      if (course == Course.rus)
        _card(He.areaLangQuestTitle.text, <Widget>[
          Text(He.areaLangQuestHelp.text, style: AppText.parent(TokenType.parentSmall)),
          const SizedBox(height: 8),
          ParentButton(
            key: const Key('open-questionnaire'),
            label: He.areaLangQuestButton.text,
            quiet: true,
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (BuildContext c) => QuestionnairePage(profile: profile, course: course),
              ),
            ),
          ),
        ]),
      _card('', <Widget>[
        ParentButton(
          key: const Key('open-language-progress'),
          label: _progressButton(course).text,
          quiet: true,
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (BuildContext c) => LanguageProgressPage(profile: profile, course: course),
            ),
          ),
        ),
      ]),
    ]);
  }
}

/// Russian stress marks on screen: the route's default, always, or never.
class _StressRow extends StatelessWidget {
  const _StressRow({required this.switches, required this.onChanged});

  final LanguageSwitches switches;
  final ValueChanged<LanguageSwitches> onChanged;

  @override
  Widget build(BuildContext context) {
    final String route = switch (switches.route) {
      'heritage' => He.routeHeritage.text,
      'reader' => He.routeReader.text,
      _ => He.routeNew.text,
    };
    final String default_ = switches.route == 'heritage' || switches.route == 'reader'
        ? He.stressDefaultOther.text
        : He.stressDefaultNew.text;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(He.areaLangStress.text, style: AppText.fixed(size: 16, weight: 700, lineHeight: 1.5)),
          Text(
            _fill(He.areaLangStressHelp, <String, String>{'route': route, 'default': default_}),
            style: AppText.parent(TokenType.parentSmall, color: TokenColors.inkSoft),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: <Widget>[
              for (final (StressMarks m, Str label) in <(StressMarks, Str)>[
                (StressMarks.route, He.areaLangStressRoute),
                (StressMarks.on, He.areaLangStressOn),
                (StressMarks.off, He.areaLangStressOff),
              ])
                ChoiceChip(
                  key: Key('stress-${m.name}'),
                  label: Text(label.text),
                  selected: switches.stress == m,
                  onSelected: (_) => onChanged(switches.copyWith(stress: m)),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(He.langRoute.text, style: AppText.parent(TokenType.parentSmall)),
          Wrap(
            spacing: 8,
            children: <Widget>[
              for (final (String r, Str label) in <(String, Str)>[
                ('new', He.routeNew),
                ('heritage', He.routeHeritage),
                ('reader', He.routeReader),
              ])
                ChoiceChip(
                  key: Key('route-$r'),
                  label: Text(label.text),
                  selected: switches.route == r,
                  onSelected: (bool on) =>
                      onChanged(on ? switches.copyWith(route: r) : switches.copyWith(clearRoute: true)),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// The presentation band of this course: the child's age, or the parent's choice (frame invariant 7).
class _BandRow extends StatelessWidget {
  const _BandRow({required this.switches, required this.ageBand, required this.onChanged});

  final LanguageSwitches switches;
  final int ageBand;
  final ValueChanged<LanguageSwitches> onChanged;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(He.langBand.text, style: AppText.fixed(size: 16, weight: 700, lineHeight: 1.5)),
        Text(He.langBandHelp.text, style: AppText.parent(TokenType.parentSmall, color: TokenColors.inkSoft)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: <Widget>[
            ChoiceChip(
              key: const Key('band-age'),
              label: Text(He.langBandAge.text),
              selected: switches.band == null,
              onSelected: (_) => onChanged(switches.copyWith(clearBand: true)),
            ),
            for (final (int b, Str label) in <(int, Str)>[
              (0, He.langBandA),
              (1, He.langBandB),
              (2, He.langBandC),
            ])
              ChoiceChip(
                key: Key('band-$b'),
                label: Text(label.text),
                selected: switches.band == b,
                onSelected: (_) => onChanged(switches.copyWith(band: b)),
              ),
          ],
        ),
      ],
    ),
  );
}

/// The home-language questionnaire (Russian) and the one question of English: enums only, answered by a tap, saved at once. An
/// answer sets where a placement staircase starts, never where it ends.
class QuestionnairePage extends ConsumerWidget {
  const QuestionnairePage({super.key, required this.profile, required this.course});

  final Profile profile;
  final String course;

  static const Map<String, Str> _questions = <String, Str>{
    'knowsLetters': He.qKnowsLetters,
    'home': He.qHome,
    'understands': He.qUnderstands,
    'speaks': He.qSpeaks,
    'letters': He.qLetters,
    'reads': He.qReads,
  };
  static const Map<String, Str> _answers = <String, Str>{
    'no': He.aNo,
    'some': He.aSome,
    'most': He.aMost,
    'none': He.aNone,
    'oneParent': He.aOneParent,
    'bothParents': He.aBothParents,
    'grandparentsOthers': He.aGrandparentsOthers,
    'words': He.aWords,
    'sentences': He.aSentences,
    'syllables': He.aSyllables,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final LanguageSwitches s =
        ref.watch(languagesProvider).value?.of(profile.id, course) ?? const LanguageSwitches();
    final Map<String, List<String>> asks = languageQuestionnaire[course] ?? const <String, List<String>>{};
    return _page(context, He.areaLangQuestTitle.text, () => Navigator.pop(context), <Widget>[
      _card('', <Widget>[
        Text(He.areaLangQuestHelp.text, style: AppText.parent(TokenType.parentSmall)),
        for (final MapEntry<String, List<String>> q in asks.entries) ...<Widget>[
          const SizedBox(height: 16),
          Text(_questions[q.key]!.text, style: AppText.parent(TokenType.parentH3)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: <Widget>[
              for (final String a in q.value)
                ChoiceChip(
                  key: Key('answer-${q.key}-$a'),
                  label: Text(_answers[a]!.text),
                  selected: s.questionnaire[q.key] == a,
                  onSelected: (_) => unawaited(
                    _save(
                      ref,
                      profile.id,
                      course,
                      s.copyWith(questionnaire: <String, String>{...s.questionnaire, q.key: a}),
                    ),
                  ),
                ),
            ],
          ),
        ],
        const SizedBox(height: 16),
        ParentButton(label: He.langQuestionnaireDone.text, onPressed: () => Navigator.pop(context)),
      ]),
    ]);
  }
}

/// The progress in one language (section 6.3): the strands with a bar and a line of words, the gates, speaking as "practised" or
/// "said", and what to notice. Never a streak, a day count, a "you have not practised", or a language, child or day beside
/// another.
class LanguageProgressPage extends ConsumerWidget {
  const LanguageProgressPage({super.key, required this.profile, required this.course});

  final Profile profile;
  final String course;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final LanguageProgress? p = ref
        .watch(languageProgressProvider((childId: profile.id, course: course)))
        .value;
    final bool waiting = ref.watch(languageProgressProvider((childId: profile.id, course: course))).isLoading;
    return _page(
      context,
      '${_progressButton(course).text} · ${displayChildName(profile.name)}',
      () => Navigator.pop(context),
      <Widget>[
        if (p == null && !waiting)
          _card(languageName(course).text, <Widget>[
            Text(
              He.langProgressNoCourse.text,
              key: const Key('progress-no-course'),
              style: AppText.parent(TokenType.parentBody),
            ),
          ])
        else if (p != null) ...<Widget>[
          _card(languageName(course).text, <Widget>[
            Text(He.areaLangProgressIntro.text, style: AppText.parent(TokenType.parentSmall)),
            const SizedBox(height: 8),
            const _Legend(),
            for (final StrandProgress s in p.strands) _StrandRow(strand: s),
          ], key: const Key('progress-strands')),
          if (p.gates.isNotEmpty)
            _card(He.areaLangGates.text, <Widget>[
              for (final GateView g in p.gates) _GateRow(gate: g),
            ], key: const Key('progress-gates')),
          if (p.speaking.isNotEmpty)
            _card(He.areaLangSpeaking.text, <Widget>[
              Text(He.areaLangSpeakingHelp.text, style: AppText.parent(TokenType.parentSmall)),
              for (final SpeakingView v in p.speaking)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: <Widget>[
                      Expanded(child: Text(v.title, style: AppText.parent(TokenType.parentBody))),
                      _Chip(
                        text: v.said ? He.areaLangSaid.text : He.areaLangPractised.text,
                        color: v.said ? TokenColors.skyTint : TokenColors.hairline,
                      ),
                    ],
                  ),
                ),
            ], key: const Key('progress-speaking')),
          _card(He.progressMisconceptions.text, <Widget>[
            if (p.notices.isEmpty)
              Text(He.progressNothingToWatch.text, style: AppText.parent(TokenType.parentSmall))
            else
              for (final NoticeView n in p.notices)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Expanded(child: Text(n.text, style: AppText.parent(TokenType.parentSmall))),
                      const SizedBox(width: 8),
                      _Chip(
                        text: n.resolved ? He.progressResolved.text : He.areaLangNoticeFound.text,
                        color: TokenColors.hairline,
                      ),
                    ],
                  ),
                ),
          ], key: const Key('progress-notices')),
        ],
      ],
    );
  }
}

/// A status in words and in colour: practising lilac, understood sky, understood and remembered gold, worth a revisit sunset.
const Color _learningColour = TokenColors.lilac;
const Color _understoodColour = TokenColors.sky;
const Color _rememberedColour = TokenColors.gold;
const Color _revisitColour = TokenColors.sunset;

class _Legend extends StatelessWidget {
  const _Legend();

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 16,
    runSpacing: 4,
    children: <Widget>[
      for (final (Color c, Str t) in <(Color, Str)>[
        (_learningColour, He.statusPractising),
        (_understoodColour, He.statusUnderstood),
        (_rememberedColour, He.statusRemembered),
        (_revisitColour, He.statusRevisit),
      ])
        Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(color: c, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            Text(t.text, style: AppText.parent(TokenType.parentSmall)),
          ],
        ),
    ],
  );
}

class _StrandRow extends StatelessWidget {
  const _StrandRow({required this.strand});

  final StrandProgress strand;

  /// The line of words with the counts, so the bar is never the only cue; a count of 0 is left out.
  String get _counts {
    final List<String> parts = <String>[
      if (strand.learning > 0) '${He.statusPractising.text} ${strand.learning}',
      if (strand.understood > 0) '${He.statusUnderstood.text} ${strand.understood}',
      if (strand.remembered > 0) '${He.statusRemembered.text} ${strand.remembered}',
      if (strand.revisit > 0) '${He.statusRevisit.text} ${strand.revisit}',
    ];
    return parts.isEmpty ? He.progressNotYetPlayed.text : parts.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final int total = strand.total == 0 ? 1 : strand.total;
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.only(top: 12),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: TokenColors.hairline)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(child: Text(strand.name.text, style: AppText.parent(TokenType.parentH3))),
              if (strand.startLevel != null)
                Text(
                  _fillN(strand.startLevel!),
                  style: AppText.parent(TokenType.parentSmall, color: TokenColors.inkSoft),
                ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: SizedBox(
              height: 10,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  for (final (int n, Color c) in <(int, Color)>[
                    (strand.learning, _learningColour),
                    (strand.understood, _understoodColour),
                    (strand.remembered, _rememberedColour),
                    (strand.revisit, _revisitColour),
                    (strand.notStarted, TokenColors.hairline),
                  ])
                    if (n > 0)
                      Expanded(
                        flex: n * 1000 ~/ total,
                        child: ColoredBox(color: c),
                      ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(_counts, style: AppText.parent(TokenType.parentSmall, color: TokenColors.inkSoft)),
        ],
      ),
    );
  }

  static String _fillN(int n) => He.areaLangStrandStart.fill(<String, String>{'n': '$n'});
}

class _GateRow extends StatelessWidget {
  const _GateRow({required this.gate});

  final GateView gate;

  @override
  Widget build(BuildContext context) {
    final (String chip, String text, Color colour) = switch (gate.state) {
      GateState.open => (He.areaLangGateChipOpen.text, He.areaLangGateOpen.text, TokenColors.skyTint),
      GateState.closedByParent => (
        He.areaLangGateChipClosed.text,
        He.areaLangGateByParent.text,
        TokenColors.hairline,
      ),
      GateState.notYet => (He.areaLangGateChipNotYet.text, He.areaLangGateClosed.text, TokenColors.hairline),
    };
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(gate.name.text, style: AppText.parent(TokenType.parentH3)),
                Text(text, style: AppText.parent(TokenType.parentSmall, color: TokenColors.inkSoft)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _Chip(text: chip, color: colour),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
    decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(999)),
    child: Text(text, style: AppText.parent(TokenType.parentSmall)),
  );
}
