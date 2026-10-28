import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/reward_providers.dart';
import '../app/world_providers.dart';
import '../content/models.dart';
import '../data/app_database.dart' show Reward;
import '../design/app_text.dart';
import '../design/board.dart';
import '../design/components.dart';
import '../design/tokens.g.dart';
import '../rewards/award.dart';
import '../rewards/reward_rules.dart';
import '../strings/he.dart';
import 'play_button.dart';
import 'trophy_art.dart' show landOf;
import '../world/world_art.dart';
import '../world/world_state.dart';

/// One land close up: its island with an object for each skill, growing as the child understands, and a way into the
/// lesson. A bell flag on an object means a check is due ("someone is calling for help"); tapping it opens a short
/// mission of three to five items, made on the spot. Nothing here is locked, timed or counted against the child.
class LandScreen extends ConsumerWidget {
  const LandScreen({super.key, required this.childId, required this.land, this.onPlay, this.onMission});

  final String childId;
  final TrophyLand land;

  /// Opens the land's lesson (null when the land has none).
  final VoidCallback? onPlay;

  /// Opens a revisit mission for one skill.
  final void Function(Lesson mission)? onMission;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final WorldView? view = ref.watch(worldProvider(childId)).value;
    final List<WorldObject> objects = view?.lands[land] ?? const <WorldObject>[];
    // The island decorations the child has earned (10, 20 and 30 skills understood for good) stand on every island.
    final Set<String> given = <String>{
      for (final Reward r in ref.watch(rewardsProvider(childId)).value ?? const <Reward>[]) r.awardKey,
    };
    final ({Color sea, Color grass, Color sand}) colours = islandColours(land.domain);
    return Scaffold(
      backgroundColor: colours.sea,
      body: SafeArea(
        child: Stack(
          children: <Widget>[
            Positioned.fill(child: CustomPaint(painter: _IslandPainter(colours))),
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 56, 24, 96),
                child: Center(
                  child: SingleChildScrollView(
                    child: Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.end,
                      spacing: 8,
                      runSpacing: 8,
                      children: <Widget>[
                        for (final WorldObject o in objects)
                          Semantics(
                            label: o.bell ? '${o.title}. ${He.bellSemantics.text}' : o.title,
                            button: o.bell,
                            child: GestureDetector(
                              key: Key('object-${o.skillId}'),
                              behavior: HitTestBehavior.opaque,
                              onTap: o.bell && view != null && onMission != null
                                  ? () {
                                      final Lesson? mission = view.missionFor(o.skillId);
                                      if (mission != null) onMission!(mission);
                                    }
                                  : null,
                              child: ExcludeSemantics(child: WorldObjectView(object: o)),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            PositionedDirectional(
              start: 16,
              top: 8,
              child: PebbleButton(
                key: const Key('land-back'),
                semanticLabel: He.landBackSemantics.text,
                size: 48,
                fill: TokenColors.spark,
                lip: TokenColors.sparkDeep,
                onPressed: () => Navigator.of(context).pop(),
                child: const BoardSvg('assets/art/ui/home_palm.svg', width: 24, height: 24),
              ),
            ),
            for (final int steps in decorationSteps)
              if (given.contains(Awards.decoration(steps)))
                switch (steps) {
                  10 => PositionedDirectional(
                    start: 24,
                    bottom: 14,
                    child: BoardSvg(
                      'assets/art/decorations/deco_10.svg',
                      key: const Key('island-deco-10'),
                      width: 56,
                      height: 56,
                    ),
                  ),
                  20 => PositionedDirectional(
                    end: 24,
                    top: 64,
                    child: BoardSvg(
                      'assets/art/decorations/deco_20.svg',
                      key: const Key('island-deco-20'),
                      width: 56,
                      height: 56,
                    ),
                  ),
                  _ => PositionedDirectional(
                    end: 24,
                    bottom: 14,
                    child: BoardSvg(
                      'assets/art/decorations/deco_30.svg',
                      key: const Key('island-deco-30'),
                      width: 56,
                      height: 56,
                    ),
                  ),
                },
            // The land's name.
            Positioned(
              top: 12,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  key: const Key('land-title'),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
                  decoration: BoxDecoration(
                    color: TokenColors.paper,
                    borderRadius: BorderRadius.circular(999),
                    boxShadow: softShadow,
                  ),
                  child: Text(landOf(land).label.text, style: AppText.fixed(size: 24, weight: 700)),
                ),
              ),
            ),
            // What the drawings mean: practising, knowing, remembering.
            PositionedDirectional(
              start: 16,
              bottom: 12,
              child: Semantics(
                label: He.legendSemantics.text,
                child: ExcludeSemantics(child: _Legend(key: const Key('land-legend'))),
              ),
            ),
            if (onPlay != null)
              Positioned(
                left: 0,
                right: 0,
                bottom: 12,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      PlayPebble(
                        key: const Key('land-play'),
                        semanticLabel: He.landPlaySemantics.text,
                        size: 72,
                        onPressed: onPlay,
                      ),
                      Text(He.landPlayLabel.text, style: AppText.fixed(size: 18, weight: 700)),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Three small pictures that say what the drawings on the island mean, left to right in reading order: a faded one is still
/// being practised, a coloured one is known, a coloured one with fruit and a golden star is remembered.
class _Legend extends StatelessWidget {
  const _Legend({super.key});

  WorldObject _sample(GrowthStage stage) =>
      WorldObject(skillId: 'legend', title: '', objectId: 'stair', stage: stage, bell: false);

  Widget _item(GrowthStage stage, String label) => Column(
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      SizedBox(
        width: 56,
        height: 60,
        child: FittedBox(child: WorldObjectView(object: _sample(stage), size: 48)),
      ),
      Text(label, style: AppText.fixed(size: 13, weight: 700)),
    ],
  );

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: TokenColors.paper.withValues(alpha: 0.92),
      borderRadius: BorderRadius.circular(TokenRadius.xl),
      boxShadow: softShadow,
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        _item(GrowthStage.sketch, He.legendSketch.text),
        const SizedBox(width: 6),
        _item(GrowthStage.colour, He.legendColour.text),
        const SizedBox(width: 6),
        _item(GrowthStage.fruit, He.legendStar.text),
      ],
    ),
  );
}

class _IslandPainter extends CustomPainter {
  const _IslandPainter(this.colours);

  final ({Color sea, Color grass, Color sand}) colours;

  @override
  void paint(Canvas canvas, Size size) {
    final Rect sand = Rect.fromCenter(
      center: Offset(size.width / 2, size.height * 0.58),
      width: size.width * 0.92,
      height: size.height * 0.78,
    );
    canvas.drawOval(sand, Paint()..color = colours.sand);
    canvas.drawOval(sand.deflate(14), Paint()..color = colours.grass);
  }

  @override
  bool shouldRepaint(_IslandPainter old) => old.colours != colours;
}
