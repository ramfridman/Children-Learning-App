import 'package:flutter/material.dart';

import '../design/board.dart';
import '../rewards/award.dart';
import '../strings/he.dart';
import 'home_screen.dart' show Land;

/// The name of a tier's trophy in the child's words.
Str trophyName(TrophyTier tier) => switch (tier) {
  TrophyTier.bronze => He.trophyBronze,
  TrophyTier.silver => He.trophySilver,
  TrophyTier.gold => He.trophyGold,
};

/// The land a trophy belongs to, as the map knows it.
Land landOf(TrophyLand land) => Land.values.byName(land.name);

/// A pale lilac silhouette of a drawing, for something not earned yet: calm, never a reproach.
class Silhouette extends StatelessWidget {
  const Silhouette({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Opacity(
    opacity: 0.55,
    child: ColorFiltered(
      colorFilter: const ColorFilter.matrix(<double>[
        0, 0, 0, 0, 215, //
        0, 0, 0, 0, 208, //
        0, 0, 0, 0, 236, //
        0, 0, 0, 1, 0, //
      ]),
      child: child,
    ),
  );
}

/// A trophy: the cup of its tier with its land's glyph on the white disc of the bowl. A trophy not earned yet is the pale
/// dashed cup of the design (the gold one with a pale star), with the glyph faint on it.
class TrophyCup extends StatelessWidget {
  const TrophyCup({super.key, required this.land, required this.tier, this.height = 96, this.locked = false});

  final TrophyLand land;
  final TrophyTier tier;
  final double height;
  final bool locked;

  @override
  Widget build(BuildContext context) {
    final double width = height * 120 / 140;
    final String file = locked
        ? (tier == TrophyTier.gold ? 'trophy_locked_gold' : 'trophy_locked')
        : 'trophy_${tier.name}';
    // The disc is centred at (60, 52) of the 120 by 140 drawing and the glyph is 22 of its units wide.
    final double glyph = height * 22 / 140;
    final Widget emblem = BoardSvg(
      'assets/art/trophies/emblem_${land.name}.svg',
      width: glyph,
      height: glyph,
    );
    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        clipBehavior: Clip.none,
        children: <Widget>[
          BoardSvg('assets/art/trophies/$file.svg', width: width, height: height),
          Positioned(
            left: width * (60 - 11) / 120,
            top: height * (52 - 11) / 140,
            child: locked
                ? Opacity(
                    opacity: 0.55,
                    child: ColorFiltered(
                      colorFilter: const ColorFilter.mode(Color(0xFFDCD3EC), BlendMode.srcIn),
                      child: emblem,
                    ),
                  )
                : emblem,
          ),
        ],
      ),
    );
  }
}

/// A habit medal. [locked] draws it as a silhouette.
class MedalArt extends StatelessWidget {
  const MedalArt({super.key, required this.id, this.height = 88, this.locked = false});

  final String id;
  final double height;
  final bool locked;

  @override
  Widget build(BuildContext context) {
    // A medal not earned yet is the design's pale dashed one.
    return BoardSvg(
      locked ? 'assets/art/medals/medal_locked.svg' : 'assets/art/medals/medal_$id.svg',
      width: height * 100 / 122,
      height: height,
    );
  }
}

/// What a medal is called and what earns it.
({Str name, Str how}) medalWords(String id) => switch (id) {
  'brave-asker' => (name: He.medalBraveAsker, how: He.medalBraveAskerHow),
  'try-again' => (name: He.medalTryAgain, how: He.medalTryAgainHow),
  'explainer' => (name: He.medalExplainer, how: He.medalExplainerHow),
  _ => (name: He.medalBugFixer, how: He.medalBugFixerHow),
};
