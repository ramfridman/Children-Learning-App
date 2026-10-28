import 'dart:ui' show Color;

import '../strings/he.dart';
import 'award.dart';

/// A prize for the companion: a scarf in a colour set (M8, Q7). The character renderer draws it on every companion, so no
/// character needs its own art. A prize comes with a trophy of one tier (the first trophy of that tier, in any land).
class Outfit {
  const Outfit({
    required this.id,
    required this.tier,
    required this.name,
    required this.how,
    required this.main,
    required this.accent,
  });

  final String id;

  /// The tier of trophy that unlocks it.
  final TrophyTier tier;
  final Str name;
  final Str how;
  final Color main;
  final Color accent;
}

/// "No scarf", chosen on purpose. It is a value of its own so that the choice reaches the family's other phones too.
const String noOutfit = 'none';

const List<Outfit> outfits = <Outfit>[
  Outfit(
    id: 'honey',
    tier: TrophyTier.bronze,
    name: He.outfitHoney,
    how: He.outfitHowBronze,
    main: Color(0xFFF5B83D),
    accent: Color(0xFFE08A1B),
  ),
  Outfit(
    id: 'sky',
    tier: TrophyTier.silver,
    name: He.outfitSky,
    how: He.outfitHowSilver,
    main: Color(0xFF6BB8F0),
    accent: Color(0xFF2F7FE0),
  ),
  Outfit(
    id: 'rose',
    tier: TrophyTier.gold,
    name: He.outfitRose,
    how: He.outfitHowGold,
    main: Color(0xFFF07AB5),
    accent: Color(0xFFD03C86),
  ),
];

/// The outfit with this id, or null for none (also for "none" and for an id this app does not know).
Outfit? outfitById(String? id) {
  for (final Outfit o in outfits) {
    if (o.id == id) return o;
  }
  return null;
}

/// The outfits a child has, from the award keys they hold: one for each tier of trophy they have earned.
Set<String> unlockedOutfits(Iterable<String> awardKeys) {
  final Set<TrophyTier> tiers = <TrophyTier>{for (final String k in awardKeys) ?Awards.trophyOf(k)?.tier};
  return <String>{
    for (final Outfit o in outfits)
      if (tiers.contains(o.tier)) o.id,
  };
}
