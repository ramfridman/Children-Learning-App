// The sizes of base-ten blocks in units of one cube's side, and the room an item's blocks need (docs/design/c1-blocks.md sections 4 and 5).
// Plain Dart, no Flutter: the pack builder (a command-line tool) checks an item's blocks against these numbers, and `BaseTenLayout` in
// `play/stage_pictures.dart` draws with them, so the check and the drawing cannot drift apart.

/// The steps and limits of the blocks. A rod is one unit wide and ten tall (ten cubes that touch); rods stand [rodStep] - 1 apart; the
/// groups of blocks (thousands, hundreds, tens, ones) are [groupGap] apart; the ones stand in a frame two columns by [frameRows] rows,
/// filled from the bottom, the left column first, with [looseStep] - 1 between two cubes; rods that are taken away stand [crossGap] further
/// from those that are left.
abstract final class BlockGeometry {
  static const double flatStep = 2.4, thouStep = 3.2, groupGap = 1.2, looseStep = 1.3, crossGap = 0.6;
  static const double rodStep = 1.5;
  static const int frameRows = 5;

  /// The cube that no item may go under, in points, on the smallest phone, a phone and a tablet.
  static const double floorUnit = 12;

  /// The room kept round a picture that stands on the ground, on each side, in units (a lit rod's glow needs more).
  static double padOf({required bool lit}) => lit ? 0.4 : 0.15;

  /// How tall [rows] loose cubes are, one above the other, in units.
  static double stack(int rows) => rows + (rows - 1) * (looseStep - 1);

  /// How wide and how tall the blocks are, in units.
  static ({double width, double height}) extent({
    int thousands = 0,
    int hundreds = 0,
    int tens = 0,
    int ones = 0,
    int crossed = 0,
  }) {
    final double apart = crossed > 0 && crossed < tens ? crossGap : 0;
    final List<double> parts = <double>[
      if (thousands > 0) 10 + 3 + (thousands - 1) * thouStep,
      if (hundreds > 0) 10 + (hundreds - 1) * flatStep,
      if (tens > 0) 1 + (tens - 1) * rodStep + apart,
      if (ones > 0) ones <= frameRows ? 1 : 1 + looseStep,
    ];
    final double wide =
        parts.fold(0.0, (double s, double w) => s + w) + (parts.length > 1 ? parts.length - 1 : 0) * groupGap;
    final double tall = thousands > 0
        ? 13
        : (hundreds > 0 || tens > 0 ? 10 : (ones > 0 ? stack(ones < frameRows ? ones : frameRows) : 1));
    return (width: wide, height: tall);
  }

  // The smallest phone's boards (ActivitySpec.phoneSE; a test holds these to it): what a tile and a stage have across.
  static const double seTilesWidth = 480, seStageWidth = 270;

  /// The tile's border and the margin the blocks keep inside it, on each side, and the margin of a stage round its pictures.
  static const double tileEdge = 9, stageMargin = 6, pairGap = 16, tileGap = 24;

  /// The most room across, in units, that a picture of blocks may need so that its cube is [floorUnit] on the smallest phone: as an option
  /// on a tile when there are [options] of them (the tile is as wide as the row allows, 260 at most), or as one of two pictures of a
  /// comparison on the stage.
  static double mostAcross({int? options}) {
    final double width = options == null
        ? (seStageWidth - 2 * stageMargin - pairGap) / 2
        : (seTilesWidth / options - tileGap).clamp(0, 260) - 2 * tileEdge;
    return width / floorUnit;
  }
}

/// Item ids that break the limits of [blockLimits] and are waived until their content is changed (the curriculum's call): each of them is
/// still reported by a test as long as it does break them, so a fixed item must leave this list.
const Set<String> blockLimitWaivers = <String>{'c.numc04.16'};

/// What is wrong with the blocks of a tap-the-answer item (`scene.picture`, `scene.picture2`, `answer.options[].picture`), or nothing: the
/// limits that keep the cube at 12 points or more on the smallest phone (docs/design/c1-blocks.md section 5): at most three options with
/// blocks, and no option or picture of a comparison wider than the room it has across.
List<String> blockLimits(Map<String, Object?> scene, Map<String, Object?> answer) {
  final List<String> out = <String>[];
  double across(Object? picture) {
    if (picture is! Map<String, Object?>) return 0;
    int n(String k) => picture[k] is int ? picture[k]! as int : 0;
    final bool lit = n('litRods') > 0;
    return BlockGeometry.extent(
          thousands: n('thousands'),
          hundreds: n('hundreds'),
          tens: n('tens'),
          ones: n('ones'),
          crossed: n('crossedRods'),
        ).width +
        2 * BlockGeometry.padOf(lit: lit);
  }

  final List<Object?> options = (answer['options'] as List<Object?>?) ?? const <Object?>[];
  final List<Object?> pictures = <Object?>[
    for (final Object? o in options)
      if (o is Map<String, Object?> && o['picture'] != null) o['picture'],
  ];
  if (pictures.length > 3) {
    out.add('answer.options: blocks on more than three tiles leave a cube under 12 points');
  }
  if (pictures.isNotEmpty) {
    final double most = BlockGeometry.mostAcross(options: options.length);
    for (final (int i, Object? o) in options.indexed) {
      final double need = o is Map<String, Object?> ? across(o['picture']) : 0;
      if (need > most) {
        out.add(
          'answer.options[$i].picture: needs ${need.toStringAsFixed(1)} cubes across, '
          'more than the ${most.toStringAsFixed(1)} that a cube of 12 points leaves on the smallest phone',
        );
      }
    }
  }
  if (scene['picture2'] != null) {
    final double most = BlockGeometry.mostAcross();
    for (final String k in <String>['picture', 'picture2']) {
      final double need = across(scene[k]);
      if (need > most) {
        out.add(
          'scene.$k: needs ${need.toStringAsFixed(1)} cubes across, more than the '
          '${most.toStringAsFixed(1)} that two pictures side by side leave at 12 points on the smallest phone',
        );
      }
    }
  }
  return out;
}
