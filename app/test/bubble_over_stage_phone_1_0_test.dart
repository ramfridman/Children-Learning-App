// B-29 (docs/design/b29-caption-overlap.md): on the phone board at text size 1.0 the speech bubble keeps clear of the scene, for the
// youngest look with captions on and the two older ones; the lines that still spill are counted.
import 'package:flutter/material.dart';

import 'support/bubble_audit.dart';

/// No line spills over the stage here: the count stays 0. The bubble keeps 4 points clear of every tile as drawn (`tiles: 0`, see `bubbleStageAuditTests`); it was 2 points over the lifted tile
/// of a sort or builder tray at the youngest look (56 phone, 29 small phone, then 146 and 74 with the pilot's sorts).
void main() => bubbleStageAuditTests(<StageAuditCase>[
  (board: 'phone', size: const Size(852, 393), scale: 1.0, look: auditLooks[0], spills: 0, tiles: 0),
  (board: 'phone', size: const Size(852, 393), scale: 1.0, look: auditLooks[1], spills: 0, tiles: 0),
  (board: 'phone', size: const Size(852, 393), scale: 1.0, look: auditLooks[2], spills: 0, tiles: 0),
]);
