import 'package:flutter/material.dart';

import '../design/app_text.dart';
import '../design/board.dart';
import '../design/components.dart';
import '../design/tokens.g.dart';
import '../strings/he.dart';
import 'home_island_name.dart';

/// The child's home (B-26, "Nitzi's home"), opened from the home island's sign and Today's Adventure on the map.
///
/// STEP-4 PLACEHOLDER: B-26 step 3 wires the way in and out, so this shows only the island's title and the way back to
/// the map. Step 4 replaces the body with the close-up scene (the bottle, the friend at the door, the book and the
/// lighthouse; docs/design/nitzi-home.md). Nothing here pretends to be more than that: no button that does nothing.
class HomeIslandScreen extends StatelessWidget {
  const HomeIslandScreen({super.key, required this.island});

  /// The island's words: the title (the whole name) and what a screen reader says.
  final HomeIslandName island;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: TokenColors.worldSea1,
    body: SafeArea(
      child: Stack(
        children: <Widget>[
          // The title may take two lines: its frame words are joined, so a break only falls before the name.
          Positioned(
            top: 12,
            left: 88,
            right: 88,
            child: Center(
              child: Semantics(
                header: true,
                label: island.semantics,
                child: ExcludeSemantics(
                  child: Container(
                    key: const Key('home-island-title'),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
                    decoration: BoxDecoration(
                      color: TokenColors.paper,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: softShadow,
                    ),
                    child: Text(
                      island.title,
                      textAlign: TextAlign.center,
                      style: AppText.fixed(size: 24, weight: 700),
                    ),
                  ),
                ),
              ),
            ),
          ),
          PositionedDirectional(
            start: 16,
            top: 8,
            child: PebbleButton(
              key: const Key('home-island-back'),
              semanticLabel: He.landBackSemantics.text,
              size: 48,
              fill: TokenColors.spark,
              lip: TokenColors.sparkDeep,
              onPressed: () => Navigator.of(context).pop(),
              child: const BoardSvg('assets/art/ui/home_palm.svg', width: 24, height: 24),
            ),
          ),
        ],
      ),
    ),
  );
}
