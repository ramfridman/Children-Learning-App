import 'dart:ui';

/// The shape of a socket of the progress trail (docs/design/m11-rooms.md section 3.3): each room has its own, so the nine rooms are told
/// apart by shape, not by colour. Every path is drawn in a 20 by 20 box (the socket's size).
enum TrailShape {
  circle,
  stair,
  drop,
  tree,
  puzzle,
  nut,
  orange,
  porthole,
  arch,
  square;

  /// The socket's outline in a 20 by 20 box. The nut, the porthole and the window are drawn with the even-odd rule, so their holes show.
  Path get path {
    final Path p = Path();
    switch (this) {
      case circle:
        p.addOval(Rect.fromCircle(center: const Offset(10, 10), radius: 9));
      case stair:
        _polygon(p, const <Offset>[
          Offset(2, 18),
          Offset(2, 3),
          Offset(8, 3),
          Offset(8, 8),
          Offset(13, 8),
          Offset(13, 13),
          Offset(18, 13),
          Offset(18, 18),
        ]);
      case drop:
        p
          ..moveTo(10, 1.5)
          ..cubicTo(14, 7.5, 17, 10.5, 17, 13.5)
          ..arcToPoint(const Offset(3, 13.5), radius: const Radius.circular(7))
          ..cubicTo(3, 10.5, 6, 7.5, 10, 1.5)
          ..close();
      case tree:
        _polygon(p, const <Offset>[
          Offset(10, 1),
          Offset(18, 14.5),
          Offset(12, 14.5),
          Offset(12, 19),
          Offset(8, 19),
          Offset(8, 14.5),
          Offset(2, 14.5),
        ]);
      case puzzle:
        p
          ..moveTo(2.5, 6)
          ..lineTo(7, 6)
          ..cubicTo(6.2, 2.2, 13.8, 2.2, 13, 6)
          ..lineTo(17.5, 6)
          ..lineTo(17.5, 9.8)
          ..cubicTo(13.7, 9, 13.7, 16.2, 17.5, 15.4)
          ..lineTo(17.5, 18.5)
          ..lineTo(2.5, 18.5)
          ..close();
      case nut:
        p.fillType = PathFillType.evenOdd;
        _polygon(p, const <Offset>[
          Offset(5.5, 2.2),
          Offset(14.5, 2.2),
          Offset(19, 10),
          Offset(14.5, 17.8),
          Offset(5.5, 17.8),
          Offset(1, 10),
        ]);
        p.addOval(Rect.fromCircle(center: const Offset(10, 10), radius: 3.4));
      case orange:
        p
          ..addOval(Rect.fromCircle(center: const Offset(10, 12.2), radius: 7.6))
          ..moveTo(10, 4.8)
          ..cubicTo(11, 1.6, 15.5, 1, 17, 2.2)
          ..cubicTo(15.6, 5, 12.5, 5.8, 10, 4.8)
          ..close();
      case porthole:
        p.fillType = PathFillType.evenOdd;
        p
          ..addOval(Rect.fromCircle(center: const Offset(10, 10), radius: 9))
          ..addOval(Rect.fromCircle(center: const Offset(10, 10), radius: 5.5));
      case arch:
        p
          ..moveTo(3.5, 18.5)
          ..lineTo(3.5, 9)
          ..arcToPoint(const Offset(16.5, 9), radius: const Radius.circular(6.5))
          ..lineTo(16.5, 18.5)
          ..close();
      case square:
        p.fillType = PathFillType.evenOdd;
        p.addRRect(RRect.fromRectAndRadius(const Rect.fromLTRB(2, 2, 18, 18), const Radius.circular(2)));
        for (final Rect pane in const <Rect>[
          Rect.fromLTRB(5, 5, 9, 9),
          Rect.fromLTRB(11, 5, 15, 9),
          Rect.fromLTRB(5, 11, 9, 15),
          Rect.fromLTRB(11, 11, 15, 15),
        ]) {
          p.addRect(pane);
        }
    }
    return p;
  }

  static void _polygon(Path p, List<Offset> points) {
    p.addPolygon(points, true);
  }
}
