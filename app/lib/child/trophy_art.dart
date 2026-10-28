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

/// A trophy: the cup of its tier with its land's emblem on the bowl. [locked] draws it as a silhouette.
class TrophyCup extends StatelessWidget {
  const TrophyCup({super.key, required this.land, required this.tier, this.height = 96, this.locked = false});

  final TrophyLand land;
  final TrophyTier tier;
  final double height;
  final bool locked;

  @override
  Widget build(BuildContext context) {
    final double width = height * 100 / 110;
    final Widget cup = SizedBox(
      width: width,
      height: height,
      child: Stack(
        alignment: Alignment.topCenter,
        children: <Widget>[
          BoardSvg('assets/art/trophies/trophy_${tier.name}.svg', width: width, height: height),
          Positioned(
            top: height * 0.17,
            child: BoardSvg(
              'assets/art/trophies/emblem_${land.name}.svg',
              width: height * 0.30,
              height: height * 0.30,
            ),
          ),
        ],
      ),
    );
    return locked ? Silhouette(child: cup) : cup;
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
    final Widget medal = BoardSvg('assets/art/medals/medal_$id.svg', width: height * 0.8, height: height);
    return locked ? Silhouette(child: medal) : medal;
  }
}

/// What a medal is called and what earns it.
({Str name, Str how}) medalWords(String id) => switch (id) {
  'brave-asker' => (name: He.medalBraveAsker, how: He.medalBraveAskerHow),
  'try-again' => (name: He.medalTryAgain, how: He.medalTryAgainHow),
  'explainer' => (name: He.medalExplainer, how: He.medalExplainerHow),
  _ => (name: He.medalBugFixer, how: He.medalBugFixerHow),
};
