import 'dart:math' as math;
import 'dart:ui';

import '../child/activity_shell.dart';
import '../design/board.dart';
import '../design/tokens.g.dart';
import 'host_places.dart';

/// Where a room's landmark stands on a board, and whether it is in the header.
typedef LandmarkPlace = ({Rect box, bool inHeader});

/// The landmark of a room is always on the screen, whole, in a place of its own: never under the stage's content, never over it or over a
/// touch target, on every board and for every layout of the stage (docs/design/m11-rooms.md section 3.4). That is where the stage reacts
/// when an item is solved, so a child must always be able to see it.
///
/// - A **phone** has no free corner at all (the stage, the bubble, the guide, the microphone and the tiles fill it), so the landmark stands
///   in the **header**, between the progress trail and the home button, as tall as the buttons (64 points, the small phone's 56). The
///   frame keeps the trail clear of it ([ActivitySpec.trailRoom]'s `endReserve`).
/// - A **tablet** has room, and the landmark is large (150 points on the landscape board, 118 on the portrait one): beside the stage's
///   card, standing on its bottom line, or else in the first free place down the board's end-side margin, and when the layout leaves none
///   (a card that is wide and tiles under it) a smaller one, down to 82 points. Only if none of these is free does it go to the header.
///
/// Whatever the board, the least size is [least]. The places depend only on the board and the layout of the item (never on the line in the
/// bubble or on whether a host is in front), so the landmark does not move while an item is on.
abstract final class LandmarkSlot {
  /// The least the landmark is, in board points: about a finger and a half, and the header's small phone size.
  static const double least = 56;

  /// The clear room around the landmark's box, to anything else on the board.
  static const double gap = 4;

  /// The header's slot keeps this far above the guide's box, whose picture has an empty margin at its top: only on the small phone does it matter.
  static const double guideGap = 1;

  /// A tablet's landmark keeps this far from the board's end (left) edge, and from the bottom, where no hotspot may be.
  static const double margin = 24;

  /// What the tablet's landmark is first tried at: the design's 150 and 118, and a smaller one if there is no room.
  static const double _tablet = 150;
  static const double _tabletPortrait = 118;
  static const List<double> _shrink = <double>[1, 0.85, 0.7, 0.55];
  static const double _tabletLeast = 80;

  /// How far a microphone's confirm buttons reach from it (a button, and the gap before it).
  static const double _micReach = 68;

  /// The place of the landmark on [board] for the item laid out as [s] (the board's own numbers, or a template's, see
  /// `TemplateSession.layoutFor`).
  static LandmarkPlace of(BoardClass board, ActivitySpec s) {
    final Rect header = headerBox(board, s);
    if (!board.isTablet) return (box: header, inHeader: true);
    final List<Rect> blocked = _blocked(board, s);
    final Rect usable = Rect.fromLTRB(
      margin,
      0,
      board.size.width,
      board.size.height - TokenTouch.bottomNoHotspot,
    );
    final double wanted = board == BoardClass.tabletLandscape ? _tablet : _tabletPortrait;
    for (final double k in _shrink) {
      final double size = (wanted * k).floorToDouble();
      if (size < _tabletLeast) break;
      for (final Rect r in _candidates(s, size, board.size)) {
        if (_inside(r, usable) && !blocked.any((Rect o) => o.inflate(gap).overlaps(r))) {
          return (box: r, inHeader: false);
        }
      }
    }
    return (box: header, inHeader: true);
  }

  /// The header's slot: at the end of the room the trail has, as tall as the header's buttons and level with them, and clear of the guide
  /// and the pair standing under it.
  static Rect headerBox(BoardClass board, ActivitySpec s) {
    final double size = board == BoardClass.phoneSE ? least : 64;
    final double right = s.trailRoom(board.size.width).right;
    final double top = math.min(s.controlsTop, _corner(board, s).top - guideGap - size);
    return Rect.fromLTWH(right - size, top, size, size);
  }

  /// How much of the trail's room the header's slot takes: its width and the trail's own clearance from it.
  static double reserve(Rect headerBox) => headerBox.width + ActivitySpec.trailClear;

  static bool _inside(Rect r, Rect area) =>
      r.left >= area.left && r.top >= area.top && r.right <= area.right && r.bottom <= area.bottom;

  /// The places tried for a landmark of [size], best first: beside the stage on its end side, standing on its bottom line; then down the end
  /// side's margin, the nearest to that line first.
  static Iterable<Rect> _candidates(ActivitySpec s, double size, Size board) sync* {
    final double line = s.stage.bottom + gap - size;
    yield Rect.fromLTWH(s.stage.left - 24 - size, line, size, size);
    final double first = s.controlsTop + 64 + 12 + gap;
    final List<double> rows = <double>[for (double y = first; y + size <= board.height; y += 8) y]
      ..sort((double a, double b) => (a - line).abs().compareTo((b - line).abs()));
    for (final double y in rows) {
      yield Rect.fromLTWH(margin, y, size, size);
    }
  }

  /// What a landmark on a tablet keeps clear of: the header (the buttons with their tap margins, and the trail), the bubble's column above
  /// the stage, the stage's card with its lip, the box of the tiles with their tap margins, the corner with the guide and the host pair, and
  /// the microphone with its confirm buttons. Where the bubble is, or a host, never decides it: the boxes are the widest they can be.
  static List<Rect> _blocked(BoardClass board, ActivitySpec s) {
    final double width = board.size.width;
    final double rightEdge = s.bubbleLeft == null
        ? width - (s.bubbleRight ?? 0)
        : s.bubbleLeft! + s.bubbleMaxWidth;
    return <Rect>[
      Rect.fromLTRB(0, 0, width, s.controlsTop + 64 + 12),
      Rect.fromLTRB(rightEdge - s.bubbleMaxWidth, s.trailTop, rightEdge, s.stage.top),
      s.stage.inflate(6),
      Rect.fromLTWH(s.tilesLeft, s.tilesTop - s.tileSlop, s.tilesWidth, s.tileHeight + 2 * s.tileSlop),
      _corner(board, s),
      Rect.fromLTWH(s.micLeft, s.micTop, s.micSize, s.micSize).inflate(_micReach),
    ];
  }

  /// The guide's box and the host pair's two boxes, together.
  static Rect _corner(BoardClass board, ActivitySpec s) {
    final HostPlaces p = HostPlaces.of(board);
    return Rect.fromLTWH(
      s.nitziLeft,
      s.nitziTop,
      s.nitziSize,
      s.nitziSize,
    ).expandToInclude(p.front).expandToInclude(p.back);
  }
}
