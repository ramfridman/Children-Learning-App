// B-29 (docs/design/b29-caption-overlap.md): on the phoneSE board at text size 1.0 the speech bubble keeps clear of the scene, for the
// youngest look with captions on and the two older ones; the lines that still spill are counted.
import 'package:flutter/material.dart';

import 'support/bubble_audit.dart';

/// No line spills over the stage here: the count stays 0. The bubble over a tile at the youngest look is the 2 points of the tiles' hit area
/// (see `bubbleStageAuditTests`).
void main() => bubbleStageAuditTests(<StageAuditCase>[
  (board: 'phoneSE', size: const Size(667, 375), scale: 1.0, look: auditLooks[0], spills: 0, tiles: 29),
  (board: 'phoneSE', size: const Size(667, 375), scale: 1.0, look: auditLooks[1], spills: 0, tiles: 0),
  (board: 'phoneSE', size: const Size(667, 375), scale: 1.0, look: auditLooks[2], spills: 0, tiles: 0),
]);
