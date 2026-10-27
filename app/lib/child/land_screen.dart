import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/world_providers.dart';
import '../content/models.dart';
import '../design/board.dart';
import '../design/components.dart';
import '../design/tokens.g.dart';
import '../rewards/award.dart';
import '../strings/he.dart';
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
            if (onPlay != null)
              Positioned(
                left: 0,
                right: 0,
                bottom: 12,
                child: Center(
                  child: PebbleButton(
                    key: const Key('land-play'),
                    semanticLabel: He.landPlaySemantics.text,
                    size: 80,
                    fill: TokenColors.spark,
                    lip: TokenColors.sparkDeep,
                    onPressed: onPlay,
                    child: const BoardSvg('assets/art/ui/spark.svg', width: 40, height: 40),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
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
