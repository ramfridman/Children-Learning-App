import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/reward_providers.dart';
import '../app/ribbon_providers.dart';
import '../app/state.dart';
import '../app/sync_providers.dart';
import '../app/world_providers.dart';
import '../data/app_database.dart';
import '../design/app_text.dart';
import '../design/components.dart';
import '../design/tokens.g.dart';
import '../rewards/award.dart';
import '../rewards/names.dart';
import '../rewards/reward_rules.dart';
import '../rewards/ribbons.dart';
import '../strings/he.dart';

/// The parents' promises (M8, F1): for each child, every trophy of every land, with a field for words such as "we go for ice
/// cream". The words are kept in the family's settings, so every phone has them; they show beside that child's trophy in the
/// Hall and in the alert the parents get when it is earned. Nothing here is ever sent to a vendor or put in a push.
class PrizesScreen extends ConsumerStatefulWidget {
  const PrizesScreen({super.key, required this.onClose});

  final VoidCallback onClose;

  @override
  ConsumerState<PrizesScreen> createState() => _PrizesScreenState();
}

class _PrizesScreenState extends ConsumerState<PrizesScreen> {
  Promises? _promises;
  final Map<String, String> _errors = <String, String>{};

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    final AppDatabase db = await ref.read(databaseProvider.future);
    final Promises p = decodeRibbons(await db.setting(ribbonsKey));
    if (mounted) setState(() => _promises = p);
  }

  Future<void> _save(String childId, String trophyKey, String text) async {
    final Promises? have = _promises;
    if (have == null) return;
    final String id = '$childId/$trophyKey';
    if ((have[childId]?[trophyKey] ?? '') == text.trim()) {
      setState(() => _errors.remove(id));
      return;
    }
    final Promises? next = withPromise(have, childId, trophyKey, text);
    if (next == null) {
      setState(
        () => _errors[id] = checkPromise(text) == PromiseCheck.ok ? He.prizesTooMany.text : He.prizesBad.text,
      );
      return;
    }
    final AppDatabase db = await ref.read(databaseProvider.future);
    await db.putSetting(ribbonsKey, encodeRibbons(next));
    ref.invalidate(ribbonsProvider(childId));
    if (mounted) {
      setState(() {
        _promises = next;
        _errors.remove(id);
      });
    }
    unawaited(ref.read(syncRunnerProvider).now(force: true));
  }

  @override
  Widget build(BuildContext context) {
    final List<Profile> children = ref.watch(appStateProvider).value?.profiles ?? const <Profile>[];
    return Scaffold(
      backgroundColor: TokenColors.parentBg,
      appBar: AppBar(
        backgroundColor: TokenColors.night,
        foregroundColor: Colors.white,
        title: Text(He.prizesTitle.text, style: AppText.parent(TokenType.parentH2, color: Colors.white)),
        leading: IconButton(icon: const Icon(Icons.arrow_forward_rounded), onPressed: widget.onClose),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(He.prizesHelp.text, style: AppText.parent(TokenType.parentSmall)),
            const SizedBox(height: 12),
            if (children.isEmpty)
              Text(
                He.prizesNoChildren.text,
                key: const Key('prizes-none'),
                style: AppText.parent(TokenType.parentBody),
              ),
            if (_promises == null)
              const LinearProgressIndicator()
            else
              for (final Profile p in children)
                _ChildPrizes(
                  key: Key('prizes-${p.id}'),
                  child: p,
                  promises: _promises![p.id] ?? const <String, String>{},
                  errors: _errors,
                  onSave: (String key, String text) => _save(p.id, key, text),
                ),
            const SizedBox(height: 8),
            ParentButton(label: He.pinOk.text, onPressed: widget.onClose),
          ],
        ),
      ),
    );
  }
}

class _ChildPrizes extends ConsumerWidget {
  const _ChildPrizes({
    super.key,
    required this.child,
    required this.promises,
    required this.errors,
    required this.onSave,
  });

  final Profile child;
  final Map<String, String> promises;
  final Map<String, String> errors;
  final void Function(String trophyKey, String text) onSave;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Set<String> earned = <String>{
      for (final Reward r in ref.watch(rewardsProvider(child.id)).value ?? const <Reward>[])
        if (r.kind == AwardKind.trophy.name) r.awardKey,
    };
    final WorldView? world = ref.watch(worldProvider(child.id)).value;
    int skillsIn(TrophyLand land) => world?.lands[land]?.length ?? 0;
    return Container(
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
          Text(child.name, style: AppText.parent(TokenType.parentH2)),
          for (final TrophyLand land in TrophyLand.values) ...<Widget>[
            const SizedBox(height: 12),
            Text(landNamePlain(land), style: AppText.parent(TokenType.parentBody)),
            if (skillsIn(land) < minSkillsForLandTrophy)
              Text(
                He.prizesNotYet.text,
                style: AppText.parent(TokenType.parentSmall, color: TokenColors.inkSoft),
              ),
            for (final TrophyTier tier in TrophyTier.values)
              _PromiseRow(
                childId: child.id,
                trophyKey: Awards.trophy(land, tier),
                tier: tier,
                saved: promises[Awards.trophy(land, tier)] ?? '',
                earned: earned.contains(Awards.trophy(land, tier)),
                error: errors['${child.id}/${Awards.trophy(land, tier)}'],
                onSave: onSave,
              ),
          ],
        ],
      ),
    );
  }
}

/// One trophy and the field for its promise. It is saved when the field is left or the keyboard's "done" is pressed.
class _PromiseRow extends StatefulWidget {
  const _PromiseRow({
    required this.childId,
    required this.trophyKey,
    required this.tier,
    required this.saved,
    required this.earned,
    required this.error,
    required this.onSave,
  });

  final String childId;
  final String trophyKey;
  final TrophyTier tier;
  final String saved;
  final bool earned;
  final String? error;
  final void Function(String trophyKey, String text) onSave;

  @override
  State<_PromiseRow> createState() => _PromiseRowState();
}

class _PromiseRowState extends State<_PromiseRow> {
  late final TextEditingController _text = TextEditingController(text: widget.saved);

  @override
  void didUpdateWidget(_PromiseRow old) {
    super.didUpdateWidget(old);
    // Words that came from another phone replace what is shown, unless this field is being typed in.
    if (widget.saved != old.saved && widget.saved != _text.text.trim() && !FocusScope.of(context).hasFocus) {
      _text.text = widget.saved;
    }
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 6),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SizedBox(
          width: 96,
          child: Padding(
            padding: const EdgeInsets.only(top: 14),
            child: Row(
              children: <Widget>[
                if (widget.earned)
                  const Padding(
                    padding: EdgeInsetsDirectional.only(end: 4),
                    child: Icon(Icons.check_circle_rounded, size: 18, color: TokenColors.domainShapesDeep),
                  ),
                Flexible(
                  child: Text(tierNamePlain(widget.tier), style: AppText.parent(TokenType.parentSmall)),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: Focus(
            onFocusChange: (bool focused) {
              if (!focused) widget.onSave(widget.trophyKey, _text.text);
            },
            child: TextField(
              key: Key('promise-${widget.childId}-${widget.trophyKey}'),
              controller: _text,
              maxLength: maxPromiseLength,
              textInputAction: TextInputAction.done,
              onSubmitted: (String t) => widget.onSave(widget.trophyKey, t),
              decoration: InputDecoration(
                hintText: He.prizesHint.text,
                errorText: widget.error,
                counterText: '',
                isDense: true,
              ),
            ),
          ),
        ),
      ],
    ),
  );
}
