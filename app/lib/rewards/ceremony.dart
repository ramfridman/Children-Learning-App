import '../data/app_database.dart';
import 'award.dart';
import 'outfits.dart';
import 'reward_service.dart';

/// The setting that switches ceremonies off (`off`); on by default.
const String ceremoniesSettingKey = 'ceremonies';

/// The one award that gets a ceremony now, among those waiting (M8, Q8): a trophy before a medal, the highest tier of the
/// trophies and of those the one earned last. The others keep waiting, glowing softly in the Hall, and are never lost.
Reward? nextCeremony(List<Reward> unseen) {
  final String? trophy = RewardService.pickCeremony(<({String key, DateTime at})>[
    for (final Reward r in unseen)
      if (r.kind == AwardKind.trophy.name) (key: r.awardKey, at: r.at),
  ]);
  if (trophy != null) return unseen.firstWhere((Reward r) => r.awardKey == trophy);
  final List<Reward> medals = <Reward>[
    for (final Reward r in unseen)
      if (r.kind == AwardKind.medal.name) r,
  ];
  return medals.isEmpty ? null : medals.first;
}

/// What to celebrate now for one child, or null: nothing is waiting, or a parent switched ceremonies off (then everything
/// waits in the Hall with a soft glow). The prize is the one that comes with the first trophy of a tier, shown on a card.
Future<({Reward reward, Outfit? prize})?> nextCeremonyFor(AppDatabase db, String childId) async {
  if (await db.setting(ceremoniesSettingKey) == 'off') return null;
  final List<Reward> all = await db.rewardsOf(childId);
  final Reward? next = nextCeremony(<Reward>[
    for (final Reward r in all)
      if (r.seenAt == null) r,
  ]);
  if (next == null) return null;
  final TrophyTier? tier = Awards.trophyOf(next.awardKey)?.tier;
  final bool firstOfTier =
      tier != null &&
      !all.any(
        (Reward r) => r.id != next.id && r.seenAt != null && Awards.trophyOf(r.awardKey)?.tier == tier,
      );
  return (reward: next, prize: firstOfTier ? outfits.where((Outfit o) => o.tier == tier).firstOrNull : null);
}
