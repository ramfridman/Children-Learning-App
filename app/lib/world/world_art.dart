import 'package:flutter/material.dart';

import '../design/board.dart';
import '../design/tokens.g.dart';
import 'world_state.dart';

/// One object of the world, drawn for its stage: a pale pencil sketch, full colour, or full colour with fruit and a
/// golden star. With a bell flag when a check is due, and a dry leaf beside it ("a leaf that needs watering"). The
/// drawing is one picture per object; the stages are made here, so a new drawing needs no extra art.
class WorldObjectView extends StatelessWidget {
  const WorldObjectView({super.key, required this.object, this.size = 96});

  final WorldObject object;
  final double size;

  /// The sketch: the same drawing, washed out towards white (not grey, which looks switched off): "not grown yet".
  static const ColorFilter _sketch = ColorFilter.mode(Color(0xB3FFFFFF), BlendMode.srcATop);

  @override
  Widget build(BuildContext context) {
    final Widget picture = BoardSvg('assets/art/world/${object.objectId}.svg', width: size, height: size);
    return SizedBox(
      width: size * 1.2,
      height: size * 1.25,
      child: Stack(
        alignment: Alignment.bottomCenter,
        clipBehavior: Clip.none,
        children: <Widget>[
          Positioned(
            bottom: 0,
            child: object.stage == GrowthStage.sketch
                ? ColorFiltered(colorFilter: _sketch, child: picture)
                : picture,
          ),
          if (object.stage == GrowthStage.fruit) ...<Widget>[
            Positioned(
              top: 0,
              child: BoardSvg(
                'assets/art/world/star_gold.svg',
                key: Key('star-${object.skillId}'),
                width: size * 0.34,
              ),
            ),
            Positioned(
              left: size * 0.12,
              bottom: size * 0.18,
              child: BoardSvg('assets/art/world/fruit.svg', width: size * 0.2),
            ),
            Positioned(
              right: size * 0.14,
              bottom: size * 0.3,
              child: BoardSvg('assets/art/world/fruit.svg', width: size * 0.2),
            ),
          ],
          if (object.bell) ...<Widget>[
            Positioned(
              left: 0,
              top: size * 0.05,
              child: BoardSvg(
                'assets/art/world/leaf_dry.svg',
                key: Key('leaf-${object.skillId}'),
                width: size * 0.28,
              ),
            ),
            Positioned(
              right: 0,
              top: 0,
              child: BoardSvg(
                'assets/art/world/bell_flag.svg',
                key: Key('bell-${object.skillId}'),
                width: size * 0.34,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// The colours of a land's island, by its domain.
({Color sea, Color grass, Color sand}) islandColours(String domain) => switch (domain) {
  'colors' => (
    sea: TokenColors.worldSea1,
    grass: TokenColors.domainColorsTint,
    sand: TokenColors.worldWoodLight,
  ),
  'shapes' => (
    sea: TokenColors.worldSea1,
    grass: TokenColors.domainShapesTint,
    sand: TokenColors.worldWoodLight,
  ),
  'logic' => (
    sea: TokenColors.worldSea1,
    grass: TokenColors.domainLogicTint,
    sand: TokenColors.worldWoodLight,
  ),
  'cs' => (sea: TokenColors.worldSea1, grass: TokenColors.domainCsTint, sand: TokenColors.worldWoodLight),
  'math' => (sea: TokenColors.worldSea1, grass: TokenColors.domainMathTint, sand: TokenColors.worldWoodLight),
  _ => (sea: TokenColors.worldSea1, grass: TokenColors.domainNumbersTint, sand: TokenColors.worldWoodLight),
};
