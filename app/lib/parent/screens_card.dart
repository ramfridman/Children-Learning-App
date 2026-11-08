import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/look_providers.dart';
import '../app/state.dart';
import '../app/sync_providers.dart';
import '../data/app_database.dart';
import '../design/app_text.dart';
import '../design/layout.dart' show SizeClass, sizeClassFor;
import '../design/tokens.g.dart';
import '../engine/age.dart';
import '../strings/he.dart';
import 'age_fields.dart';
import 'age_settings.dart';
import 'look_settings.dart';

// The "adapt the screens" card of a child's settings page (B-29, docs/design/b29-steps5-6.md section 3.2): the look (by age, or one of the three
// age groups, a letter like a language's level, saved at once and synced) and the question captions (by school stage, show, hide; kept on
// this device). Both take effect at the child's next session: a session reads them once, when it starts.

/// The range of ages a look letter names.
Str lookRangeOf(int band) => const <Str>[He.langBandA, He.langBandB, He.langBandC][band.clamp(0, 2)];

class ScreensCard extends ConsumerWidget {
  const ScreensCard({super.key, required this.profile});

  final Profile profile;

  Future<void> _setLook(WidgetRef ref, int? band) async {
    final AppDatabase db = await ref.read(databaseProvider.future);
    final FamilyLooks next =
        FamilyLooks.decode(await db.setting(looksSettingKey)).withBand(profile.id, band) ??
        const FamilyLooks();
    await db.putSetting(looksSettingKey, next.encode());
    ref
      ..invalidate(lookNowProvider(profile.id))
      ..invalidate(familyLooksProvider);
    unawaited(ref.read(syncRunnerProvider).now(force: true));
  }

  Future<void> _setCaptions(WidgetRef ref, CaptionSetting value) async {
    final AppDatabase db = await ref.read(databaseProvider.future);
    await db.setCaptionSetting(profile.id, value);
    ref
      ..invalidate(lookNowProvider(profile.id))
      ..invalidate(captionSettingProvider(profile.id));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final LookNow? now = ref.watch(lookNowProvider(profile.id)).value;
    final int? chosenLook = (ref.watch(familyLooksProvider).value ?? const FamilyLooks()).bandOf(profile.id);
    final CaptionSetting caption = ref.watch(captionSettingProvider(profile.id)).value ?? CaptionSetting.auto;
    final bool phone = sizeClassFor(MediaQuery.sizeOf(context)) != SizeClass.tablet;
    return Container(
      key: const Key('screens-card'),
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
          Text(He.screensTitle.text, style: AppText.parent(TokenType.parentH2)),
          const SizedBox(height: 8),
          Text(He.lookTitle.text, style: AppText.parent(TokenType.parentH3)),
          Text(He.lookHelp.text, style: AppText.parent(TokenType.parentSmall, color: TokenColors.inkSoft)),
          const SizedBox(height: 8),
          ChipGrid(
            columns: 2,
            cells: <ChipCell>[
              ChipCell(
                key: const Key('look-auto'),
                label: He.lookAuto.text,
                selected: chosenLook == null,
                onTap: () => _setLook(ref, null),
              ),
              for (int b = 0; b < 3; b++)
                ChipCell(
                  key: Key('look-$b'),
                  label: lookRangeOf(b).text,
                  selected: chosenLook == b,
                  onTap: () => _setLook(ref, b),
                ),
            ],
          ),
          if (now != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                He.lookNow.fill(<String, String>{'range': _rangeOfStage(now.stage).text}),
                key: const Key('look-now'),
                style: AppText.fixed(size: 13, weight: 700, lineHeight: 1.45),
              ),
            ),
          // A child of three on a phone: the phone works, a tablet is easier. One calm line, never a warning (owner point O2).
          if (now != null && phone && now.stage == PresentationStage.p1)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                He.lookTablet.text,
                key: const Key('look-tablet'),
                style: AppText.parent(TokenType.parentSmall, color: TokenColors.inkSoft),
              ),
            ),
          const Divider(height: 32, color: TokenColors.hairline),
          Text(He.captionsTitle.text, style: AppText.parent(TokenType.parentH3)),
          Text(
            He.captionsHelp.text,
            style: AppText.parent(TokenType.parentSmall, color: TokenColors.inkSoft),
          ),
          const SizedBox(height: 8),
          ChipGrid(
            columns: 3,
            cells: <ChipCell>[
              for (final (CaptionSetting c, Str label) in <(CaptionSetting, Str)>[
                (CaptionSetting.auto, He.captionsAuto),
                (CaptionSetting.on, He.captionsOn),
                (CaptionSetting.off, He.captionsOff),
              ])
                ChipCell(
                  key: Key('captions-${c.word}'),
                  label: label.text,
                  selected: caption == c,
                  onTap: () => _setCaptions(ref, c),
                ),
            ],
          ),
          if (now != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                (now.captionsShown ? He.captionsNowOn : He.captionsNowOff).fill(<String, String>{
                  'stage': stageName(now.schoolStage),
                }),
                key: const Key('captions-now'),
                style: AppText.fixed(size: 13, weight: 700, lineHeight: 1.45),
              ),
            ),
        ],
      ),
    );
  }

  /// The range of the look a stage is: P1 and P2 are the youngest group, P3 the middle one, P4 the oldest.
  static Str _rangeOfStage(PresentationStage s) => lookRangeOf(switch (s) {
    PresentationStage.p1 || PresentationStage.p2 => 0,
    PresentationStage.p3 => 1,
    PresentationStage.p4 => 2,
  });
}
