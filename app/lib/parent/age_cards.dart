import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show FutureProviderFamily;

import '../app/age_providers.dart';
import '../app/look_providers.dart';
import '../app/providers.dart' show clockProvider;
import '../app/state.dart';
import '../app/sync_providers.dart';
import '../data/app_database.dart';
import '../data/child_name.dart';
import '../data/profile_age.dart';
import '../design/app_text.dart';
import '../design/components.dart';
import '../design/tokens.g.dart';
import '../engine/age.dart' show SchoolStage, addAgeCardDue, septemberCardDue;
import '../strings/he.dart';
import 'age_fields.dart' show stageName;
import 'age_page.dart';
import 'age_settings.dart';

// The two cards at the top of the parent area (B-29, docs/design/b29-steps5-6.md section 4): the September card, which asks once each school
// year whether a child moves up, and the "add the age" card for a child made before the age was asked. Nothing changes for a child until the
// parent answers, and then only from the next session. Never in the child's space: no badge, no notification.

/// Which of the two cards a child has on [now].
typedef AgeCards = ({bool september, bool addAge});

final FutureProviderFamily<AgeCards, String> ageCardsProvider = FutureProvider.autoDispose
    .family<AgeCards, String>((Ref ref, String childId) async {
      final AppDatabase db = await ref.watch(databaseProvider.future);
      final DateTime now = DateTime.fromMillisecondsSinceEpoch(ref.read(clockProvider).nowMs());
      final Profile? p = (await db.allProfiles()).where((Profile x) => x.id == childId).firstOrNull;
      final SchoolStage? stage = p?.confirmedStage;
      return (
        september: septemberCardDue(stage: stage, confirmedYear: await db.stageYearOf(childId), now: now),
        addAge:
            p != null &&
            addAgeCardDue(stage: stage, hiddenYear: await db.ageCardHiddenYear(childId), now: now),
      );
    });

BoxDecoration _cardBox({bool strong = false}) => BoxDecoration(
  color: TokenColors.paper,
  borderRadius: BorderRadius.circular(TokenRadius.md),
  border: Border.all(
    color: strong ? TokenColors.sea : TokenColors.hairline,
    width: strong ? TokenBorder.thin : TokenBorder.thin,
  ),
);

/// The cards of every child in [profiles] that has one, in the order of the children.
class AgeCardsColumn extends ConsumerWidget {
  const AgeCardsColumn({super.key, required this.profiles});

  final List<Profile> profiles;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: <Widget>[
      for (final Profile p in profiles) ...<Widget>[
        if (ref.watch(ageCardsProvider(p.id)).value?.september ?? false) SeptemberCard(profile: p),
        if (ref.watch(ageCardsProvider(p.id)).value?.addAge ?? false) AddAgeCard(profile: p),
      ],
    ],
  );
}

class SeptemberCard extends ConsumerWidget {
  const SeptemberCard({super.key, required this.profile});

  final Profile profile;

  Future<void> _answer(WidgetRef ref, {required bool moveUp}) async {
    final AppDatabase db = await ref.read(databaseProvider.future);
    final DateTime now = DateTime.fromMillisecondsSinceEpoch(ref.read(clockProvider).nowMs());
    final SchoolStage stage = profile.stage;
    if (moveUp) {
      await db.confirmStage(profile.id, stage.next, now);
    } else {
      // "Stay" is an answer too: the card does not come back until the next 1 September.
      await db.markStageConfirmed(profile.id, now);
    }
    await ref.read(appStateProvider.notifier).reload();
    ref
      ..invalidate(ageCardsProvider(profile.id))
      ..invalidate(lookNowProvider(profile.id))
      ..invalidate(childAgeProvider(profile.id));
    unawaited(ref.read(syncRunnerProvider).now(force: true));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final SchoolStage stage = profile.stage;
    final String next = stage.next.index == stage.index ? '' : stageName(stage.next);
    return Container(
      key: Key('september-card-${profile.id}'),
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: _cardBox(strong: true),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Icon(Icons.calendar_month_rounded, color: TokenColors.night),
              const SizedBox(width: 8),
              Expanded(child: Text(He.septTitle.text, style: AppText.parent(TokenType.parentH2))),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            He.septQuestion.fill(<String, String>{
              'child': displayChildName(profile.name),
              'next': He.stageNamesTo[stage.next.index].text,
            }),
            style: AppText.parent(TokenType.parentBody),
          ),
          Text(He.septHelp.text, style: AppText.parent(TokenType.parentSmall, color: TokenColors.inkSoft)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              IntrinsicWidth(
                child: ParentButton(
                  key: Key('sept-yes-${profile.id}'),
                  label: He.septYes.fill(<String, String>{'next': next}),
                  onPressed: () => _answer(ref, moveUp: true),
                ),
              ),
              IntrinsicWidth(
                child: ParentButton(
                  key: Key('sept-keep-${profile.id}'),
                  label: He.septKeep.fill(<String, String>{'current': He.stageNamesIn[stage.index].text}),
                  quiet: true,
                  onPressed: () => _answer(ref, moveUp: false),
                ),
              ),
              IntrinsicWidth(
                child: ParentButton(
                  key: Key('sept-other-${profile.id}'),
                  label: He.septOther.text,
                  quiet: true,
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (BuildContext c) => AgePage(
                        profile: profile,
                        onClose: () {
                          Navigator.pop(c);
                          ref.invalidate(ageCardsProvider(profile.id));
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class AddAgeCard extends ConsumerWidget {
  const AddAgeCard({super.key, required this.profile});

  final Profile profile;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Container(
    key: Key('add-age-card-${profile.id}'),
    margin: const EdgeInsets.only(bottom: 16),
    padding: const EdgeInsets.all(16),
    decoration: _cardBox(),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          He.addAgeTitle.fill(<String, String>{'child': displayChildName(profile.name)}),
          style: AppText.parent(TokenType.parentH2),
        ),
        const SizedBox(height: 8),
        Text(He.addAgeBody.text, style: AppText.parent(TokenType.parentBody)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            IntrinsicWidth(
              child: ParentButton(
                key: Key('add-age-yes-${profile.id}'),
                label: He.addAgeYes.text,
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (BuildContext c) => AgePage(
                      profile: profile,
                      onClose: () {
                        Navigator.pop(c);
                        ref.invalidate(ageCardsProvider(profile.id));
                      },
                    ),
                  ),
                ),
              ),
            ),
            IntrinsicWidth(
              child: ParentButton(
                key: Key('add-age-later-${profile.id}'),
                label: He.addAgeLater.text,
                quiet: true,
                onPressed: () async {
                  final AppDatabase db = await ref.read(databaseProvider.future);
                  await db.hideAgeCard(
                    profile.id,
                    DateTime.fromMillisecondsSinceEpoch(ref.read(clockProvider).nowMs()),
                  );
                  ref.invalidate(ageCardsProvider(profile.id));
                },
              ),
            ),
          ],
        ),
      ],
    ),
  );
}
