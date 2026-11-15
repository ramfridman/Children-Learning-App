import 'dart:math' as math;
import 'dart:ui';

/// Where the tail of a lesson's bubble points: at the mouth of whoever is speaking (the companion, or the host in a host beat).
///
/// The small pointer on the bubble's end (right) edge reaches a mouth that is level with the bubble. A speaker who stands lower than the
/// bubble's bottom (the guide and the hosts on the landscape tablet, whose bubble stands above the stage's card) is out of its reach: the
/// pointer would point at empty space. Then the tail is a wedge from the bubble's bottom, at its end, to a tip that stops at the speaker's
/// face (docs/design/m11-rooms.md section 2.2: the tail always points at whoever is talking).
class BubbleTail {
  const BubbleTail._({this.pointerAt, this.tip});

  /// A pointer on the end edge, [at] points down from the bubble's top (null: the board's own place, 18 points up from the bottom).
  const BubbleTail.pointer(double? at) : this._(pointerAt: at);

  /// A wedge ending at [tip], from the bubble's top-right corner (the body is as wide as its line, and holds its right edge).
  const BubbleTail.wedge(Offset tip) : this._(tip: tip);

  final double? pointerAt;
  final Offset? tip;

  bool get isWedge => tip != null;

  /// How far under the bubble's bottom a mouth is before the pointer no longer reaches it.
  static const double reach = 32;

  /// How much of the speaker's width the wedge's tip stops short of its mouth, so that it ends at the face and not on it.
  static const double stopShort = 0.2;

  /// The least a wedge reaches out of the bubble's corner.
  static const double leastLength = 24;

  /// The tail of [bubble] (its box on the board) towards the speaker standing in [speaker], whose mouth is at [mouth].
  /// [pointerAt] is what the pointer would say (null for the board's own place); the wedge replaces it only when the mouth is out of reach, or
  /// always when [behind] is true (the speaker stands behind another figure: a pointer on the bubble's edge would point at that figure, so the
  /// wedge reaches past it to the speaker's mouth).
  static BubbleTail toward({
    required Rect bubble,
    required Rect speaker,
    required Offset mouth,
    required double? pointerAt,
    bool behind = false,
  }) {
    if (!behind && mouth.dy <= bubble.bottom + reach) return BubbleTail.pointer(pointerAt);
    final Offset corner = bubble.bottomRight;
    final Offset away = mouth - corner;
    final double length = math.max(leastLength, away.distance - stopShort * speaker.width);
    return BubbleTail.wedge(corner + away / away.distance * length - bubble.topRight);
  }
}
