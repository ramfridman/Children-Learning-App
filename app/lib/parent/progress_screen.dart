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

/// How one child is really learning, for the parent: this week, understanding by domain, the learning curve, what
/// helps, what to watch, and strengths. It shows play time, never speed, time per question or counts of mistakes, so
/// that nothing in it nudges a parent to push for speed.
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

  Widget _view(Progress p) {
    final List<String> domainIds = <String>[for (final DomainBlock d in p.domains) d.domain];
    final bool anyPoint = p.growth.any((WeekPoint w) => w.byDomain.values.any((double? v) => v != null));
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _card(He.progressWeek.text, <Widget>[
            Text(He.progressMinutesChart.text, style: AppText.parent(TokenType.parentSmall)),
            const SizedBox(height: 8),
            MinutesBars(data: p.minutesPerDay),
            const SizedBox(height: 8),
            Text(
              He.progressSessions.fill(<String, String>{'n': '${p.sessionsThisWeek}'}),
              style: AppText.parent(TokenType.parentBody),
            ),
            Text(
              He.progressAdventures.fill(<String, String>{'n': '${p.adventuresCompleted}'}),
              style: AppText.parent(TokenType.parentBody),
            ),
          ]),
          _card(He.progressUnderstanding.text, <Widget>[
            for (final DomainBlock d in p.domains) ...<Widget>[
              Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 4),
                child: Text(
                  domainLook(d.domain).name,
                  style: AppText.parent(TokenType.parentBody, color: domainLook(d.domain).color),
                ),
              ),
              for (final SkillRow s in d.skills)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Expanded(child: Text(s.title, style: AppText.parent(TokenType.parentSmall))),
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
          _card(He.progressGrowth.text, <Widget>[
            Text(He.progressGrowthHelp.text, style: AppText.parent(TokenType.parentSmall)),
            const SizedBox(height: 8),
            if (anyPoint)
              GrowthLines(
                weeks: <Map<String, double?>>[for (final WeekPoint w in p.growth) w.byDomain],
                domains: domainIds,
              )
            else
              Text(He.progressNoPoints.text, style: AppText.parent(TokenType.parentBody)),
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
