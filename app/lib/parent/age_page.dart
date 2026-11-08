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
import '../engine/age.dart';
import '../strings/he.dart';
import 'age_fields.dart';
import 'age_settings.dart';

// The child's own "age and school stage" page and the summary card that opens it (B-29, docs/design/b29-steps5-6.md sections 2 and 3.1).
// Nothing here changes what a child sees until the next session starts: the look is read once when a session begins.

/// The summary card: the school stage and the month and year in words, and one button that opens the page. No edit controls here: the
/// pickers are long, and on a phone they would push the next card three screens down.
class AgeSummaryCard extends ConsumerWidget {
  const AgeSummaryCard({super.key, required this.profile, required this.onChange});

  final Profile profile;
  final VoidCallback onChange;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final BirthMonth? birth = ref.watch(birthOfProvider(profile.id)).value;
    final SchoolStage stage = profile.stage;
    return Container(
      key: const Key('age-card'),
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
          Text(He.ageCardTitle.text, style: AppText.parent(TokenType.parentH2)),
          const SizedBox(height: 8),
          _Row(title: He.ageStageRow.text, value: profile.confirmedStage == null ? '—' : stageName(stage)),
          const Divider(height: 24, color: TokenColors.hairline),
          _Row(
            title: He.ageBirthTitle.text,
            value: birth == null ? He.ageBirthNone.text : '${He.months[birth.month - 1].text} ${birth.year}',
          ),
          const SizedBox(height: 12),
          ParentButton(
            key: const Key('age-change'),
            label: He.ageChange.text,
            quiet: true,
            onPressed: onChange,
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
      Text(title, style: AppText.parent(TokenType.parentH3)),
      Text(value, style: AppText.parent(TokenType.parentBody)),
    ],
  );
}

/// The month and year kept for a child on this device, read for a parent's page.
final FutureProviderFamily<BirthMonth?, String> birthOfProvider = FutureProvider.autoDispose
    .family<BirthMonth?, String>((Ref ref, String childId) async {
      final AppDatabase db = await ref.watch(databaseProvider.future);
      return db.birthOf(childId);
    });

/// The page: [AgeFields] with Save and Cancel, and the note that a change starts at the next session.
class AgePage extends ConsumerStatefulWidget {
  const AgePage({super.key, required this.profile, required this.onClose});

  final Profile profile;
  final VoidCallback onClose;

  @override
  ConsumerState<AgePage> createState() => _AgePageState();
}

class _AgePageState extends ConsumerState<AgePage> {
  AgeValue? _value;
  bool _saving = false;

  DateTime get _now => DateTime.fromMillisecondsSinceEpoch(ref.read(clockProvider).nowMs());

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    final AppDatabase db = await ref.read(databaseProvider.future);
    final BirthMonth? birth = await db.birthOf(widget.profile.id);
    if (!mounted) return;
    setState(
      () => _value = AgeValue(
        year: birth?.year,
        month: birth?.month,
        stage: widget.profile.stage,
        // A confirmed stage stays unless the parent taps another; one that only stands in for the band is suggested over.
        stageChosen: widget.profile.confirmedStage != null,
      ),
    );
  }

  Future<void> _save() async {
    final AgeValue? v = _value;
    final SchoolStage? stage = v?.stage;
    if (v == null || stage == null || v.birthHalf || _saving) return;
    setState(() => _saving = true);
    final AppDatabase db = await ref.read(databaseProvider.future);
    final DateTime now = _now;
    await db.confirmStage(widget.profile.id, stage, now);
    await db.setBirth(widget.profile.id, v.birthAt(now));
    await ref.read(appStateProvider.notifier).reload();
    ref
      ..invalidate(birthOfProvider(widget.profile.id))
      ..invalidate(lookNowProvider(widget.profile.id))
      ..invalidate(childAgeProvider(widget.profile.id));
    unawaited(ref.read(syncRunnerProvider).now(force: true));
    if (mounted) widget.onClose();
  }

  @override
  Widget build(BuildContext context) {
    final AgeValue? v = _value;
    final bool canSave = v != null && v.stage != null && !v.birthHalf && !_saving;
    return Scaffold(
      backgroundColor: TokenColors.parentBg,
      appBar: AppBar(
        backgroundColor: TokenColors.night,
        foregroundColor: Colors.white,
        title: Text(
          He.agePageTitle.fill(<String, String>{'child': displayChildName(widget.profile.name)}),
          style: AppText.parent(TokenType.parentH2, color: Colors.white),
        ),
        leading: IconButton(icon: const Icon(Icons.arrow_forward_rounded), onPressed: widget.onClose),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              ParentButton(
                key: const Key('age-cancel'),
                label: He.confirmNo.text,
                quiet: true,
                onPressed: widget.onClose,
              ),
              const SizedBox(width: 12),
              ParentButton(
                key: const Key('age-save'),
                label: He.setupSave.text,
                onPressed: canSave ? _save : null,
              ),
            ],
          ),
        ),
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: v == null
              ? const SizedBox.shrink()
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      AgeFields(
                        value: v,
                        now: _now,
                        suggestFromYear: widget.profile.confirmedStage == null,
                        currentStage: widget.profile.confirmedStage,
                        storedBand: widget.profile.ageBand,
                        onChanged: (AgeValue next) => setState(() => _value = next),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        He.ageChangeNote.text,
                        key: const Key('age-change-note'),
                        style: AppText.parent(TokenType.parentSmall, color: TokenColors.inkSoft),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}
