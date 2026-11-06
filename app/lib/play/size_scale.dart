import 'dart:math' as math;
import 'dart:ui' show Rect, Size;

import '../content/models.dart';
import '../design/tokens.g.dart';
import 'hints/tap_plans.dart' show cropToInk, inkBoxOf;

// One scale for the pictures of an item that compares sizes (logic land: next in a row of big and small balls, small to big in
// order, towers that grow).
//
// A picture of a size family is drawn in one box in every size (the small ball is a small circle in the same square as the big
// one), so its size shows only if the row and the answer tiles draw that box the same size. They used to differ (the stage's
// cells are 45 points, a tile's picture 76), and a medium ball on a tile was as big as the big ball of the row.
//
// The box is cut to the ink of the biggest picture of the item (the same cut for every picture of the item, so they keep their
// proportions): the big ball fills its box, and a tower of 6 cubes its box from the floor to its top, instead of the empty margin
// that the sprites keep for the biggest ball and the tallest tower of the family.

/// The family of a picture of the pack, or null when it carries no size: `ball_size_s`, `ball_size_m` and `ball_size_l` are the
/// family `ball`, and `tower_1` to `tower_8` the family `tower`.
String? sizeFamilyOf(String ref) {
  final Match? m = _sized.firstMatch(ref) ?? _tower.firstMatch(ref);
  return m?.group(1);
}

final RegExp _sized = RegExp(r'^asset:(.+)_size_[sml]$');
final RegExp _tower = RegExp(r'^asset:(tower)_\d+$');

/// The side of the answer tiles of a size item on a stage of [stage] (the tablet's stage is wider than any phone's): 96, or 112 on a
/// tablet (the token `answerTablet` of the first band), and the picture inside a tile (4 point border, 2 point margin).
double tileSideOf(Size stage) => stage.width > 500 ? 112 : 96;
double tilePictureSideOf(Size stage) => tileSideOf(stage) - 2 * TokenBorder.thick - 4;

/// A tall picture (a tower) cannot be drawn in a square box and still show its cubes, so the answer tile of such an item is taller
/// than it is wide: [tallTileHeight] on a phone (and in a pattern to build), 136 on a tablet (its tile box is 160 high with 12 of tap margin each side).
const double tallTileHeight = 112;
double tallTileHeightOf(Size stage) => stage.width > 500 ? 136 : tallTileHeight;
double tallTilePictureHeightOf(Size stage) => tallTileHeightOf(stage) - 2 * TokenBorder.thick - 4;

/// How much bigger than its cell a round size picture is drawn: the sprites keep a margin round the biggest of the family, which a
/// neighbouring cell may overlap, so the biggest of them fills its cell.
const double sizeBleed = 1.1;

/// A picture whose width is under this share of its height is tall.
const double tallAspect = 0.95;

/// The width over the height of a pack picture, from its `viewBox` (1 where it has none).
double spriteAspect(String svg) {
  final Match? m = _viewBox.firstMatch(svg.length > 400 ? svg.substring(0, 400) : svg);
  if (m == null) return 1;
  final double w = double.parse(m.group(1)!);
  final double h = double.parse(m.group(2)!);
  return w > 0 && h > 0 ? w / h : 1;
}

final RegExp _viewBox = RegExp(r'viewBox="\s*[-\d.]+[ ,]+[-\d.]+[ ,]+([\d.]+)[ ,]+([\d.]+)\s*"');

/// How the size pictures of an item are drawn: all cut to one [part] of their box (as [inkBoxOf] gives parts), so that the biggest
/// of them fills it; [aspect] is the width over the height of that part, and the item is [tall] where it is under [tallAspect].
class SizeLook {
  SizeLook._(this.part, this.aspect, this._svgOf);

  final Rect part;
  final double aspect;
  final String Function(String ref) _svgOf;
  final Map<String, String> _cut = <String, String>{};

  bool get tall => aspect < tallAspect;

  /// The picture of [ref]: cut to [part] when it is of a size family, as the pack has it when not.
  String svg(String ref) =>
      sizeFamilyOf(ref) == null ? _svgOf(ref) : _cut.putIfAbsent(ref, () => cropToInk(_svgOf(ref), part));
}

/// The look of the size pictures among [refs] (drawn from [svgOf]), or null where there is no size item: no size family has two
/// pictures among them.
SizeLook? sizeLookOf(Iterable<String> refs, String Function(String ref) svgOf) {
  final Map<String, Set<String>> byFamily = <String, Set<String>>{};
  for (final String ref in refs) {
    final String? family = sizeFamilyOf(ref);
    if (family != null) byFamily.putIfAbsent(family, () => <String>{}).add(ref);
  }
  final List<String> sizes = <String>[
    for (final Set<String> family in byFamily.values)
      if (family.length > 1) ...family,
  ];
  if (sizes.isEmpty) return null;
  // The ink box is read from the plain shapes of a picture; a picture that moves its shapes with a `transform` (the balls, stars,
  // apples and fish) is drawn whole, and only gets a bleed, see [sizeBleed].
  if (sizes.any((String ref) => svgOf(ref).contains('transform='))) {
    return SizeLook._(const Rect.fromLTWH(0, 0, 1, 1), spriteAspect(svgOf(sizes.first)), svgOf);
  }
  Rect? ink;
  for (final String ref in sizes) {
    final Rect r = inkBoxOf(svgOf(ref));
    ink = ink == null ? r : ink.expandToInclude(r);
  }
  // A little room for the stroke of the outline (the ink box does not count it).
  final Rect part = Rect.fromLTRB(
    math.max(0, ink!.left - 0.03),
    math.max(0, ink.top - 0.02),
    math.min(1, ink.right + 0.03),
    math.min(1, ink.bottom + 0.02),
  );
  final double aspect = spriteAspect(svgOf(sizes.first)) * part.width / part.height;
  return SizeLook._(part, aspect, svgOf);
}

final Expando<List<SizeLook?>> _looks = Expando<List<SizeLook?>>('size looks');

/// The look of the size pictures of a tap-the-answer activity (its row and its answers), kept for the activity.
SizeLook? sizeLookOfTap(TapAnswerActivity a) => (_looks[a] ??= <SizeLook?>[
  sizeLookOf(<String>[
    for (final String r in a.row)
      if (r != '?') r,
    for (final ChoiceOption o in a.options) ?o.sprite,
  ], a.assets.svg),
]).first;

/// Whether [a] compares sizes: its row and its answers draw two pictures (or more) of one size family. A row of unlike things
/// (a star, an apple, a fish) is not one of these, and keeps the room its cells have.
bool comparesSizes(TapAnswerActivity a) => sizeLookOfTap(a) != null;
