import 'dart:math' as math;

import 'tokens.g.dart';

/// How the progress trail is drawn in the room it has between the header's buttons (QA-L7-2): at the board's size when the sockets fit, then
/// with the gaps tightened, then with smaller sockets (never under [floorSocket], 60% of the board's 20), and only then as a window of the
/// sockets around the current one, the sockets at a clipped end faded.
class TrailLayout {
  const TrailLayout._({
    required this.total,
    required this.socket,
    required this.gap,
    required this.padding,
    required this.first,
    required this.count,
  });

  /// The board's own padding at each end of the pill, and the least the pill is squeezed to.
  static const double normalPadding = 12;
  static const double tightPadding = 8;

  /// The least gap between two sockets, and the smallest socket that still shows a spark and a ring well.
  static const double tightGap = 4;
  static const double floorSocket = 12;

  /// How many sockets the trail has, which of them the window starts at, and how many it shows.
  final int total;
  final int first;
  final int count;
  final double socket;
  final double gap;
  final double padding;

  bool get moreBefore => first > 0;
  bool get moreAfter => first + count < total;

  /// The pill's width: the sockets shown, the gaps between them and the padding at both ends.
  double get width => 2 * padding + count * socket + math.max(0, count - 1) * gap;

  /// The sockets shown, as indexes of the trail.
  Iterable<int> get shown => Iterable<int>.generate(count, (int i) => first + i);

  /// Is socket [i] the faded one at a clipped end of a window?
  bool faded(int i) => (i == first && moreBefore) || (i == first + count - 1 && moreAfter);

  /// The layout of [total] sockets, [done] of them full, in [maxWidth] (null: all the room it wants).
  factory TrailLayout.fit({required int total, required int done, double? maxWidth}) {
    const double socket = TokenComponent.trailSocket;
    TrailLayout whole(double socket, double gap, double padding) =>
        TrailLayout._(total: total, first: 0, count: total, socket: socket, gap: gap, padding: padding);

    final TrailLayout normal = whole(socket, TokenComponent.trailGap, normalPadding);
    if (maxWidth == null || normal.width <= maxWidth) return normal;
    if (total > 1) {
      final double gap = (maxWidth - 2 * normalPadding - total * socket) / (total - 1);
      if (gap >= tightGap) return whole(socket, gap, normalPadding);
    }
    final double smaller = math.min(
      socket,
      (maxWidth - 2 * tightPadding - math.max(0, total - 1) * tightGap) / total,
    );
    if (smaller >= floorSocket) return whole(smaller, tightGap, tightPadding);
    // A window: as many floor-size sockets as fit (at least three, so that the current one has a neighbour on each side and is never
    // the faded one), centred on the current socket, or on the last one when the lesson is over.
    final int count = math.min(
      total,
      math.max(3, ((maxWidth - 2 * tightPadding + tightGap) / (floorSocket + tightGap)).floor()),
    );
    final int current = math.min(done, total - 1);
    final int first = (current - count ~/ 2).clamp(0, total - count);
    return TrailLayout._(
      total: total,
      first: first,
      count: count,
      socket: floorSocket,
      gap: tightGap,
      padding: tightPadding,
    );
  }
}
