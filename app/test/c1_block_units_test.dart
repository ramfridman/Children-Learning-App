// The cube of every item that has blocks, on every board (docs/design/c1-blocks.md section 5.3): the side of one cube is computed from the
// two layouts (S: blocks on the stage; T: blocks on the tiles) and no item may go under 12 points on the phone SE, the phone or a tablet.
// Run with the real fonts, because the length of a question decides how tall the bubble is, and the bubble decides where the tiles start.
// The limits the pack validator holds an item to (`blockLimits`) are the same numbers, written down so that a pack that passes the
// validator keeps its cube over the floor; a test holds them to the boards.
import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/child/activity_shell.dart';
import 'package:nitznutz/content/block_geometry.dart';
import 'package:nitznutz/content/models.dart';
import 'package:nitznutz/design/tokens.g.dart';
import 'package:nitznutz/play/block_layout.dart';
import 'package:nitznutz/play/stage_pictures.dart';

import 'support/c1_screens.dart';
import 'support/harness.dart';

const Map<String, ActivitySpec> _boards = <String, ActivitySpec>{
  'phoneSE': ActivitySpec.phoneSE,
  'phone': ActivitySpec.phone,
  'tabletL': ActivitySpec.tabletLandscape,
  'tabletP': ActivitySpec.tabletPortrait,
};

/// Items whose cube is still under the floor on a phone, with the reason; an item is taken off this list when its content is changed, and a
/// test fails when a listed item is no longer under (so the list never keeps a fixed item).
///
/// The four number sentences with rods (`70 - 40 = ?`) keep a row of numbers under the picture on the stage; a stage 155 or 165 points
/// tall cannot hold ten cubes of 12 points and a row (the design note's mockup of the crossed rods has no row).
const Map<String, String> _knownUnder = <String, String>{
  'c.mathc03.15': 'a number sentence under the rods',
  'c.mathc03.16': 'a number sentence under the rods',
  'c.mathc03.17': 'a number sentence under the rods',
  'c.mathc03.18': 'a number sentence under the rods',
  'c.numc04.16': 'six rods beside five: two pictures side by side are too wide',
};

void main() {
  late List<TapAnswerActivity> items;
  setUpAll(() async {
    await loadAppFonts();
    final PackContent content = await loadSourcePack();
    items = <TapAnswerActivity>[
      for (final Activity a in bandCActivities(content))
        if (a is TapAnswerActivity && BlockLayout.hasBlocks(a)) a,
    ];
  });

  test('the geometry the validator uses is the boards', () {
    expect(BlockGeometry.seTilesWidth, ActivitySpec.phoneSE.tilesWidth);
    expect(BlockGeometry.seStageWidth, ActivitySpec.phoneSE.stage.width);
    expect(BlockGeometry.tileEdge, TokenBorder.thick + 5);
    expect(BlockGeometry.floorUnit, BaseTenLayout.floorUnit);
  });

  test('no block item is drawn with a cube under 12 points on any board', () {
    expect(items.length, greaterThanOrEqualTo(16));
    final List<String> under = <String>[];
    final Set<String> seenUnder = <String>{};
    final StringBuffer table = StringBuffer();
    for (final TapAnswerActivity a in items) {
      final StringBuffer row = StringBuffer('${a.id.padRight(14)} ${BlockLayout.onTiles(a) ? 'T' : 'S'}');
      for (final MapEntry<String, ActivitySpec> b in _boards.entries) {
        final double u = BlockLayout.unitOf(a, b.value)!;
        row.write('  ${b.key} ${u.toStringAsFixed(1).padLeft(4)}');
        if (u < BaseTenLayout.floorUnit) {
          seenUnder.add(a.id);
          if (!_knownUnder.containsKey(a.id)) under.add('${a.id} on ${b.key}: ${u.toStringAsFixed(2)}');
        }
      }
      table.writeln(row);
    }
    // ignore: avoid_print
    print(table);
    expect(under, isEmpty, reason: 'the cube of these items is under 12 points:\n${under.join('\n')}');
    expect(
      _knownUnder.keys.where((String id) => !seenUnder.contains(id)),
      isEmpty,
      reason: 'these items are no longer under 12 points: take them off the list',
    );
  });
}
