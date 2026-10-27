import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/progress_provider.dart';
import '../data/app_database.dart';
import '../design/app_text.dart';
import '../design/components.dart';
import '../design/tokens.g.dart';
import '../engine/types.dart';
import '../strings/he.dart';
import 'progress.dart';
import 'progress_charts.dart';

/// How one child is really learning, for the parent: big numbers first, then each domain as one coloured bar with its
/// skills, the week, the learning curve, what helps, what to watch, and strengths. It shows play time, never speed,
/// time per question or counts of mistakes, so that nothing in it nudges a parent to push for speed.
class ProgressScreen extends ConsumerWidget {
  const ProgressScreen({super.key, required this.profile, required this.onClose});

  final Profile profile;
  final VoidCallback onClose;

  Widget _card(String title, List<Widget> children) => Container(
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
        Text(title, style: AppText.parent(TokenType.parentH2)),
        const SizedBox(height: 8),
        ...children,
      ],
    ),
  );

  String _status(ParentStatus s) => switch (s) {
    ParentStatus.understood => He.statusUnderstood.text,
    ParentStatus.practising => He.statusPractising.text,
    ParentStatus.needsRevisit => He.statusRevisit.text,
    ParentStatus.gap => He.statusGap.text,
    ParentStatus.notStartedYet => He.statusNotStarted.text,
  };

  Color _statusColor(ParentStatus s) => switch (s) {
    ParentStatus.understood => TokenColors.domainShapesDeep,
    ParentStatus.practising => TokenColors.night,
    ParentStatus.needsRevisit => TokenColors.domainMathDeep,
    ParentStatus.gap => TokenColors.domainNumbersDeep,
    ParentStatus.notStartedYet => TokenColors.inkSoft,
  };

  /// The colour of a status as a dot or a segment (the quiet grey for a skill not started).
  Color _dot(ParentStatus s) => s == ParentStatus.notStartedYet ? TokenColors.hairline : _statusColor(s);

  String _how(Representation r) => switch (r) {
    Representation.concrete => He.repConcrete.text,
    Representation.pictorial => He.repPictorial.text,
    Representation.story => He.repStory.text,
    Representation.embodied => He.repEmbodied.text,
    Representation.symbolic => He.repSymbolic.text,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<Progress> progress = ref.watch(progressProvider(profile.id));
    return Scaffold(
      backgroundColor: TokenColors.parentBg,
      appBar: AppBar(
        backgroundColor: TokenColors.night,
        foregroundColor: Colors.white,
        title: Text(
          He.progressTitle.fill(<String, String>{'child': profile.name}),
          style: AppText.parent(TokenType.parentH2, color: Colors.white),
        ),
        leading: IconButton(icon: const Icon(Icons.arrow_forward_rounded), onPressed: onClose),
      ),
      body: progress.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (Object e, StackTrace s) =>
            Center(child: Text(He.setupError.text, style: AppText.parent(TokenType.parentBody))),
        data: (Progress p) => p.empty ? _emptyView() : _view(p),
      ),
    );
  }

  Widget _emptyView() => Padding(
    padding: const EdgeInsets.all(24),
    child: Center(
      child: Text(
        He.progressEmpty.text,
        key: const Key('progress-empty'),
        textAlign: TextAlign.center,
        style: AppText.parent(TokenType.parentBody),
      ),
    ),
  );

  /// A big number with a small label under it.
  Widget _tile(String value, String label, {Key? key}) => Expanded(
    child: Container(
      key: key,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: TokenColors.paper,
        borderRadius: BorderRadius.circular(TokenRadius.md),
        border: Border.all(color: TokenColors.hairline, width: TokenBorder.thin),
      ),
      child: Column(
        children: <Widget>[
          Text(
            value,
            style: AppText.parent(TokenType.parentH2).copyWith(fontSize: 30, color: TokenColors.night),
          ),
          const SizedBox(height: 4),
          Text(label, textAlign: TextAlign.center, style: AppText.parent(TokenType.parentSmall)),
        ],
      ),
    ),
  );

  /// One bar for a domain, split into its skills' statuses, so the parent sees at once how much is understood.
  Widget _segments(DomainBlock d) {
    final Map<ParentStatus, int> count = <ParentStatus, int>{
      for (final ParentStatus st in ParentStatus.values)
        st: d.skills.where((SkillRow s) => s.status == st).length,
    };
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        height: 16,
        child: Row(
          children: <Widget>[
            for (final ParentStatus st in ParentStatus.values)
              if (count[st]! > 0)
                Expanded(
                  flex: count[st]!,
                  child: Container(color: _dot(st)),
                ),
          ],
        ),
      ),
    );
  }

  Widget _legend() => Wrap(
    spacing: 14,
    runSpacing: 4,
    children: <Widget>[
      for (final ParentStatus st in ParentStatus.values)
        Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(color: _dot(st), shape: BoxShape.circle),
            ),
            const SizedBox(width: 5),
            Text(_status(st), style: AppText.parent(TokenType.parentSmall)),
          ],
        ),
    ],
  );

  Widget _view(Progress p) {
    final List<String> domainIds = <String>[for (final DomainBlock d in p.domains) d.domain];
    final List<Map<String, double?>> weeks = <Map<String, double?>>[
      for (final WeekPoint w in p.growth) w.byDomain,
    ];
    // A curve needs at least three weeks with something in them; before that a lonely dot says nothing.
    final int weeksWithData = weeks
        .where((Map<String, double?> w) => w.values.any((double? v) => v != null))
        .length;
    final int skillTotal = p.domains.fold(0, (int a, DomainBlock d) => a + d.skills.length);
    final int skillUnderstood = p.domains.fold(0, (int a, DomainBlock d) => a + d.understood);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              _tile('${p.totalMinutes}', He.progressTileMinutes.text, key: const Key('tile-minutes')),
              const SizedBox(width: 10),
              _tile(
                '${p.adventuresCompleted}',
                He.progressTileAdventures.text,
                key: const Key('tile-adventures'),
              ),
              const SizedBox(width: 10),
              _tile(
                '$skillUnderstood/$skillTotal',
                He.progressTileUnderstood.text,
                key: const Key('tile-understood'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _card(He.progressUnderstanding.text, <Widget>[
            _legend(),
            for (final DomainBlock d in p.domains) ...<Widget>[
              const SizedBox(height: 16),
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      domainLook(d.domain).name,
                      style: AppText.parent(TokenType.parentH2, color: domainLook(d.domain).color),
                    ),
                  ),
                  Text(
                    He.progressDomainCount.fill(<String, String>{
                      'a': '${d.understood}',
                      'b': '${d.skills.length}',
                    }),
                    style: AppText.parent(TokenType.parentSmall),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              _segments(d),
              const SizedBox(height: 6),
              for (final SkillRow s in d.skills)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Padding(
                        padding: const EdgeInsets.only(top: 6, left: 8),
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(color: _dot(s.status), shape: BoxShape.circle),
                        ),
                      ),
                      Expanded(child: Text(s.title, style: AppText.parent(TokenType.parentBody))),
                      const SizedBox(width: 12),
                      Text(
                        _status(s.status),
                        key: Key('status-${s.id}'),
                        style: AppText.parent(TokenType.parentSmall, color: _statusColor(s.status)),
                      ),
                    ],
                  ),
                ),
            ],
          ]),
          _card(He.progressWeek.text, <Widget>[
            Text(He.progressMinutesChart.text, style: AppText.parent(TokenType.parentSmall)),
            const SizedBox(height: 8),
            MinutesBars(data: p.minutesPerDay),
            const SizedBox(height: 8),
            Text(
              He.progressSessions.fill(<String, String>{'n': '${p.sessionsThisWeek}'}),
              style: AppText.parent(TokenType.parentBody),
            ),
          ]),
          _card(He.progressGrowth.text, <Widget>[
            if (weeksWithData >= 3) ...<Widget>[
              Text(He.progressGrowthHelp.text, style: AppText.parent(TokenType.parentSmall)),
              const SizedBox(height: 8),
              GrowthLines(weeks: weeks, domains: domainIds),
            ] else ...<Widget>[
              Text(
                He.progressCurveSoon.text,
                key: const Key('curve-soon'),
                style: AppText.parent(TokenType.parentBody),
              ),
              const SizedBox(height: 10),
              for (final String d in domainIds)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          domainLook(d).name,
                          style: AppText.parent(TokenType.parentBody, color: domainLook(d).color),
                        ),
                      ),
                      Text(
                        GrowthLines.latest(weeks, d) == null
                            ? He.progressNotYetPlayed.text
                            : '${GrowthLines.latest(weeks, d)}%',
                        key: Key('now-$d'),
                        style: AppText.parent(TokenType.parentH2, color: domainLook(d).color),
                      ),
                    ],
                  ),
                ),
            ],
          ]),
          if (p.helped.isNotEmpty)
            _card(He.progressHelped.text, <Widget>[
              for (final HelpedRow h in p.helped)
                Text(
                  He.progressHelpedLine.fill(<String, String>{
                    'how': _how(h.representation),
                    'a': '${h.successes}',
                    'b': '${h.tries}',
                  }),
                  style: AppText.parent(TokenType.parentBody),
                ),
            ]),
          _card(He.progressMisconceptions.text, <Widget>[
            if (p.misconceptions.isEmpty)
              Text(He.progressNothingToWatch.text, style: AppText.parent(TokenType.parentBody))
            else
              for (final MisconceptionRow m in p.misconceptions)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Text(
                    m.resolved ? '${m.text} (${He.progressResolved.text})' : m.text,
                    style: AppText.parent(TokenType.parentBody),
                  ),
                ),
          ]),
          if (p.habits.any)
            _card(He.progressHabits.text, <Widget>[
              if (p.habits.askedWhenUnsure > 0)
                Text(
                  He.habitAsked.fill(<String, String>{'n': '${p.habits.askedWhenUnsure}'}),
                  style: AppText.parent(TokenType.parentBody),
                ),
              if (p.habits.usedHints > 0)
                Text(
                  He.habitHints.fill(<String, String>{'n': '${p.habits.usedHints}'}),
                  style: AppText.parent(TokenType.parentBody),
                ),
              if (p.habits.keptTrying > 0)
                Text(
                  He.habitKept.fill(<String, String>{'n': '${p.habits.keptTrying}'}),
                  style: AppText.parent(TokenType.parentBody),
                ),
            ]),
          const SizedBox(height: 8),
          ParentButton(label: He.pinOk.text, onPressed: onClose),
        ],
      ),
    );
  }
}
