import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/companion.dart';
import '../app/providers.dart';
import '../app/reward_providers.dart';
import '../app/ribbon_providers.dart';
import '../app/state.dart';
import '../app/world_providers.dart';
import '../characters/character.dart';
import '../characters/character_view.dart';
import '../data/app_database.dart';
import '../design/app_text.dart';
import '../design/board.dart';
import '../design/components.dart';
import '../design/tokens.g.dart';
import '../rewards/award.dart';
import '../rewards/outfits.dart';
import '../rewards/reward_rules.dart';
import '../strings/he.dart';
import '../world/world_state.dart';
import 'ceremony_screen.dart';
import 'trophy_art.dart';

enum HallTab { trophies, medals, friend }

/// The Trophy Hall (PLAN: Awards, prizes & the Trophy Hall; M8 D1): shelves by land with the three trophies of each, a
/// pale silhouette for one not earned yet that says how it is earned, the golden stars of each land, the habit medals, the
/// island decorations and the prizes for the companion. Nothing is padlocked and nothing is timed.
class TrophyHall extends ConsumerStatefulWidget {
  const TrophyHall({super.key, required this.childId, this.initialTab = HallTab.trophies});

  final String childId;
  final HallTab initialTab;

  @override
  ConsumerState<TrophyHall> createState() => _TrophyHallState();
}

class _TrophyHallState extends ConsumerState<TrophyHall> {
  late HallTab _tab = widget.initialTab;
  String? _selected;

  Future<void> _markSeen(Reward r) async {
    if (r.seenAt != null) return;
    final AppDatabase db = await ref.read(databaseProvider.future);
    await db.markRewardsSeen(<int>[
      r.id,
    ], DateTime.fromMillisecondsSinceEpoch(ref.read(clockProvider).nowMs(), isUtc: true));
    if (mounted) ref.invalidate(rewardsProvider(widget.childId));
  }

  void _select(String key, Reward? earned) {
    setState(() => _selected = key);
    if (earned != null) unawaited(_markSeen(earned));
  }

  Future<void> _replay(String key) =>
      Navigator.of(context)
          .push(MaterialPageRoute<void>(builder: (BuildContext c) => CeremonyScreen(awardKey: key)));

  @override
  Widget build(BuildContext context) {
    final List<Reward> given = ref.watch(rewardsProvider(widget.childId)).value ?? const <Reward>[];
    final Map<String, Reward> byKey = <String, Reward>{for (final Reward r in given) r.awardKey: r};
    final WorldView? world = ref.watch(worldProvider(widget.childId)).value;
    return Scaffold(
      backgroundColor: TokenColors.cream,
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Row(
                children: <Widget>[
                  PebbleButton(
                    key: const Key('hall-back'),
                    semanticLabel: He.landBackSemantics.text,
                    size: 48,
                    fill: TokenColors.spark,
                    lip: TokenColors.sparkDeep,
                    onPressed: () => Navigator.of(context).pop(),
                    child: const BoardSvg('assets/art/ui/home_palm.svg', width: 24, height: 24),
                  ),
                  const SizedBox(width: 8),
                  Text(He.hallTitle.text, style: AppText.fixed(size: 28, weight: 700)),
                  const Spacer(),
                  _TabPill(
                    key: const Key('hall-tab-trophies'),
                    label: He.hallTabTrophies.text,
                    on: _tab == HallTab.trophies,
                    onTap: () => setState(() => _tab = HallTab.trophies),
                  ),
                  const SizedBox(width: 8),
                  _TabPill(
                    key: const Key('hall-tab-medals'),
                    label: He.hallTabMedals.text,
                    on: _tab == HallTab.medals,
                    onTap: () => setState(() => _tab = HallTab.medals),
                  ),
                  const SizedBox(width: 8),
                  _TabPill(
                    key: const Key('hall-tab-friend'),
                    label: He.hallTabFriend.text,
                    on: _tab == HallTab.friend,
                    onTap: () => setState(() => _tab = HallTab.friend),
                  ),
                ],
              ),
            ),
            Expanded(
              child: switch (_tab) {
                HallTab.trophies => _Trophies(
                  childId: widget.childId,
                  byKey: byKey,
                  world: world,
                  selected: _selected,
                  onSelect: _select,
                  onReplay: _replay,
                ),
                HallTab.medals => _Medals(byKey: byKey, given: given, onReplay: _replay, onSeen: _markSeen),
                HallTab.friend => _Friend(given: given),
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _TabPill extends StatelessWidget {
  const _TabPill({super.key, required this.label, required this.on, required this.onTap});

  final String label;
  final bool on;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: on,
    label: label,
    child: GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: ExcludeSemantics(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          decoration: BoxDecoration(
            color: on ? TokenColors.ink : TokenColors.paper,
            borderRadius: BorderRadius.circular(999),
            boxShadow: clayShadows(on ? TokenColors.ink : TokenColors.cardLip),
          ),
          child: Text(
            label,
            style: AppText.fixed(
              size: 20,
              weight: 700,
            ).copyWith(color: on ? TokenColors.paper : TokenColors.ink),
          ),
        ),
      ),
    ),
  );
}

/// The three trophies of every land, shelf by shelf, and the card for the one chosen.
class _Trophies extends StatelessWidget {
  const _Trophies({
    required this.childId,
    required this.byKey,
    required this.world,
    required this.selected,
    required this.onSelect,
    required this.onReplay,
  });

  final String childId;
  final Map<String, Reward> byKey;
  final WorldView? world;
  final String? selected;
  final void Function(String key, Reward? earned) onSelect;
  final Future<void> Function(String key) onReplay;

  @override
  Widget build(BuildContext context) {
    final List<Widget> shelves = <Widget>[
      for (final TrophyLand land in TrophyLand.values)
        _Shelf(
          land: land,
          objects: world?.lands[land] ?? const <WorldObject>[],
          byKey: byKey,
          selected: selected,
          onSelect: onSelect,
        ),
    ];
    final Widget? card = selected == null
        ? null
        : _DetailCard(
            childId: childId,
            keyName: selected!,
            earned: byKey[selected!],
            objects: world?.lands[Awards.trophyOf(selected!)?.land] ?? const <WorldObject>[],
            onReplay: onReplay,
          );
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (card != null)
          SizedBox(
            width: 300,
            child: Padding(padding: const EdgeInsets.all(12), child: card),
          ),
        Expanded(
          child: ListView(padding: const EdgeInsets.fromLTRB(12, 4, 12, 24), children: shelves),
        ),
      ],
    );
  }
}

class _Shelf extends StatelessWidget {
  const _Shelf({
    required this.land,
    required this.objects,
    required this.byKey,
    required this.selected,
    required this.onSelect,
  });

  final TrophyLand land;
  final List<WorldObject> objects;
  final Map<String, Reward> byKey;
  final String? selected;
  final void Function(String key, Reward? earned) onSelect;

  @override
  Widget build(BuildContext context) {
    final int stars = objects.where((WorldObject o) => o.star).length;
    // The land's name and its golden stars stand at the start of the shelf, its three trophies along it (bronze first).
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: <Widget>[
          SizedBox(
            width: 112,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  landOf(land).label.text,
                  textAlign: TextAlign.center,
                  style: AppText.fixed(size: 16, weight: 700),
                ),
                if (objects.isNotEmpty)
                  Container(
                    key: Key('shelf-stars-${land.name}'),
                    margin: const EdgeInsets.only(top: 2),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
                    decoration: BoxDecoration(
                      color: TokenColors.paper,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Text('$stars/${objects.length}', style: AppText.fixed(size: 14, weight: 700)),
                        const SizedBox(width: 3),
                        const BoardSvg('assets/art/world/star_gold.svg', width: 14, height: 14),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.only(top: 2),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Color(0xFFD6A96A), width: 8)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  for (final TrophyTier tier in TrophyTier.values)
                    _Slot(
                      land: land,
                      tier: tier,
                      earned: byKey[Awards.trophy(land, tier)],
                      chosen: selected == Awards.trophy(land, tier),
                      onSelect: onSelect,
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Slot extends StatelessWidget {
  const _Slot({
    required this.land,
    required this.tier,
    required this.earned,
    required this.chosen,
    required this.onSelect,
  });

  final TrophyLand land;
  final TrophyTier tier;
  final Reward? earned;
  final bool chosen;
  final void Function(String key, Reward? earned) onSelect;

  @override
  Widget build(BuildContext context) {
    final String key = Awards.trophy(land, tier);
    final bool waiting = earned != null && earned!.seenAt == null;
    return Semantics(
      button: true,
      label: earned == null
          ? '${trophyName(tier).text}. ${He.trophyLockedSemantics.text}'
          : '${trophyName(tier).text}${waiting ? '. ${He.trophyNewSemantics.text}' : ''}',
      child: GestureDetector(
        key: Key('slot-$key'),
        behavior: HitTestBehavior.opaque,
        onTap: () => onSelect(key, earned),
        child: ExcludeSemantics(
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(TokenRadius.xl),
              border: chosen ? Border.all(color: TokenColors.spark, width: 4) : null,
              // A trophy still waiting for its ceremony glows softly.
              boxShadow: waiting
                  ? const <BoxShadow>[BoxShadow(color: Color(0x88FFD45C), blurRadius: 22, spreadRadius: 4)]
                  : null,
            ),
            child: TrophyCup(land: land, tier: tier, height: 60, locked: earned == null),
          ),
        ),
      ),
    );
  }
}

class _DetailCard extends ConsumerWidget {
  const _DetailCard({
    required this.childId,
    required this.keyName,
    required this.earned,
    required this.objects,
    required this.onReplay,
  });

  final String childId;
  final String keyName;
  final Reward? earned;
  final List<WorldObject> objects;
  final Future<void> Function(String key) onReplay;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ({TrophyLand land, TrophyTier tier})? t = Awards.trophyOf(keyName);
    if (t == null) return const SizedBox.shrink();
    final int n = objects.length;
    final bool real = n >= minSkillsForLandTrophy;
    final int need = real ? skillsNeeded(t.tier, n) : 0;
    final int lasting = objects.where((WorldObject o) => o.star).length;
    final String? promise = ref.watch(ribbonsProvider(childId)).value?[keyName];
    return Container(
      key: const Key('hall-card'),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: TokenColors.paper,
        borderRadius: BorderRadius.circular(TokenRadius.xl),
        boxShadow: clayShadows(TokenColors.cardLip, soft16: true),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(child: Text(trophyName(t.tier).text, style: AppText.fixed(size: 22, weight: 700))),
              TrophyCup(land: t.land, tier: t.tier, height: 44, locked: earned == null),
            ],
          ),
          const SizedBox(height: 6),
          if (real)
            Row(
              key: const Key('hall-dots'),
              children: <Widget>[
                for (int i = 0; i < need; i++)
                  Container(
                    width: 14,
                    height: 14,
                    margin: const EdgeInsetsDirectional.only(end: 4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: i < lasting ? TokenColors.spark : const Color(0xFFEDE6F7),
                    ),
                  ),
              ],
            ),
          const SizedBox(height: 6),
          Text(
            real ? He.trophyHow.fill(<String, String>{'n': '$need'}) : He.trophyComing.text,
            key: const Key('hall-how'),
            style: AppText.fixed(size: 18, weight: 500),
          ),
          if (promise != null) ...<Widget>[
            const SizedBox(height: 8),
            Container(
              key: const Key('hall-promise'),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFFCE1F0),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const Icon(Icons.card_giftcard, size: 18, color: Color(0xFFE04F9E)),
                  const SizedBox(width: 6),
                  Flexible(child: Text(promise, style: AppText.fixed(size: 16, weight: 600))),
                ],
              ),
            ),
          ],
          if (earned != null) ...<Widget>[
            const SizedBox(height: 10),
            Center(
              child: PebbleButton(
                key: const Key('hall-replay'),
                semanticLabel: He.trophyReplaySemantics.text,
                size: 52,
                fill: TokenColors.spark,
                lip: TokenColors.sparkDeep,
                onPressed: () => onReplay(keyName),
                child: const BoardSvg('assets/art/ui/spark.svg', width: 28, height: 28),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// The habit medals and the island decorations.
class _Medals extends StatelessWidget {
  const _Medals({required this.byKey, required this.given, required this.onReplay, required this.onSeen});

  final Map<String, Reward> byKey;
  final List<Reward> given;
  final Future<void> Function(String key) onReplay;
  final Future<void> Function(Reward r) onSeen;

  @override
  Widget build(BuildContext context) {
    final int lasting = given.where((Reward r) => r.kind == AwardKind.star.name).length;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 16,
          runSpacing: 16,
          children: <Widget>[
            for (final MedalDef m in medalDefs)
              _MedalTile(
                def: m,
                earned: byKey[Awards.medal(m.id)],
                onTap: (Reward? r) {
                  if (r == null) return;
                  unawaited(onSeen(r));
                  unawaited(onReplay(r.awardKey));
                },
              ),
          ],
        ),
        const SizedBox(height: 20),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 24,
          runSpacing: 12,
          children: <Widget>[
            for (final int n in decorationSteps)
              _DecorationTile(steps: n, have: byKey.containsKey(Awards.decoration(n)), lasting: lasting),
          ],
        ),
      ],
    );
  }
}

class _MedalTile extends StatelessWidget {
  const _MedalTile({required this.def, required this.earned, required this.onTap});

  final MedalDef def;
  final Reward? earned;
  final void Function(Reward? earned) onTap;

  @override
  Widget build(BuildContext context) {
    final ({Str name, Str how}) words = medalWords(def.id);
    final bool waiting = earned != null && earned!.seenAt == null;
    return Semantics(
      button: earned != null,
      label: earned == null ? '${words.name.text}. ${He.medalLockedSemantics.text}' : words.name.text,
      child: GestureDetector(
        key: Key('medal-${def.id}'),
        onTap: () => onTap(earned),
        child: ExcludeSemantics(
          child: Container(
            width: 190,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: TokenColors.paper,
              borderRadius: BorderRadius.circular(TokenRadius.xl),
              boxShadow: waiting
                  ? const <BoxShadow>[BoxShadow(color: Color(0x88FFD45C), blurRadius: 22, spreadRadius: 4)]
                  : clayShadows(TokenColors.cardLip),
            ),
            child: Column(
              children: <Widget>[
                MedalArt(id: def.id, height: 76, locked: earned == null),
                const SizedBox(height: 4),
                Text(
                  words.name.text,
                  style: AppText.fixed(size: 18, weight: 700),
                  textAlign: TextAlign.center,
                ),
                Text(
                  words.how.text,
                  style: AppText.fixed(size: 14, weight: 500),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DecorationTile extends StatelessWidget {
  const _DecorationTile({required this.steps, required this.have, required this.lasting});

  final int steps;
  final bool have;
  final int lasting;

  @override
  Widget build(BuildContext context) {
    final Str name = switch (steps) {
      10 => He.decorationLantern,
      20 => He.decorationFlag,
      _ => He.decorationFountain,
    };
    final Widget art = BoardSvg('assets/art/decorations/deco_$steps.svg', width: 64, height: 64);
    return Column(
      key: Key('deco-$steps'),
      children: <Widget>[
        have ? art : Silhouette(child: art),
        Text(name.text, style: AppText.fixed(size: 16, weight: 600)),
        Text('${lasting.clamp(0, steps)}/$steps', style: AppText.fixed(size: 14, weight: 500)),
      ],
    );
  }
}

/// The prizes for the companion: the colour sets earned with trophies, and the choice of what it wears.
class _Friend extends ConsumerWidget {
  const _Friend({required this.given});

  final List<Reward> given;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Set<String> unlocked = unlockedOutfits(given.map((Reward r) => r.awardKey));
    final String? chosen = ref.watch(outfitProvider).value;
    final Character? friend = ref.watch(characterForRoleProvider(CharacterRole.mapCompanion)).value;
    return Row(
      children: <Widget>[
        Expanded(
          child: Center(
            child: SizedBox(
              width: 200,
              height: 240,
              child: friend == null
                  ? const SizedBox.shrink()
                  : CharacterView(
                      key: const Key('hall-friend'),
                      character: friend,
                      state: CharacterState.idle,
                      outfit: outfitById(chosen),
                    ),
            ),
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: <Widget>[
              _OutfitRow(
                id: noOutfit,
                name: He.outfitNone,
                how: null,
                colour: null,
                chosen: chosen == noOutfit || chosen == null,
                locked: false,
              ),
              for (final Outfit o in outfits)
                _OutfitRow(
                  id: o.id,
                  name: o.name,
                  how: o.how,
                  colour: o.main,
                  chosen: chosen == o.id,
                  locked: !unlocked.contains(o.id),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _OutfitRow extends ConsumerWidget {
  const _OutfitRow({
    required this.id,
    required this.name,
    required this.how,
    required this.colour,
    required this.chosen,
    required this.locked,
  });

  final String id;
  final Str name;
  final Str? how;
  final Color? colour;
  final bool chosen;
  final bool locked;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Semantics(
      button: !locked,
      selected: chosen,
      label: locked ? '${name.text}. ${how?.text ?? ''}' : '${He.outfitWearSemantics.text} ${name.text}',
      child: GestureDetector(
        key: Key('outfit-$id'),
        behavior: HitTestBehavior.opaque,
        onTap: locked ? null : () => unawaited(ref.read(outfitProvider.notifier).choose(id)),
        child: ExcludeSemantics(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: TokenColors.paper,
              borderRadius: BorderRadius.circular(TokenRadius.xl),
              border: chosen ? Border.all(color: TokenColors.spark, width: 4) : null,
              boxShadow: clayShadows(TokenColors.cardLip),
            ),
            child: Row(
              children: <Widget>[
                locked
                    ? const Silhouette(child: Icon(Icons.circle, size: 36, color: Colors.black))
                    : Icon(Icons.circle, size: 36, color: colour ?? const Color(0xFFEDE6F7)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(name.text, style: AppText.fixed(size: 18, weight: 700)),
                      if (locked && how != null) Text(how!.text, style: AppText.fixed(size: 14, weight: 500)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
