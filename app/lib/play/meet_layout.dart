import 'dart:math' as math;
import 'dart:ui' show Rect, Size;

/// Where the picture card and the strip of a Meet screen stand inside its stage (docs/design/l7-meet-find.md section 4.1), in the stage's own
/// points. The strip column is always kept, even empty on the first screen of a set, so that the card does not jump between the screens of
/// one set; it holds the words met earlier in the set, top to bottom in the order met. It is at the stage's left on every board and in every
/// course (it is a column: it has no reading direction). A wide picture (a story page, 16 to 9) has no strip on a phone, which would leave
/// it 119 points wide: the card takes the whole stage.
class MeetLayout {
  MeetLayout({
    required Size stage,
    required double aspect,
    required int earlier,
    required bool tablet,
    required bool lookA,
  }) : strip = _stripOf(stage, aspect, earlier, tablet, lookA),
       card = _cardOf(stage, aspect, tablet, lookA, wideOnPhone: !tablet && aspect > _wideAspect);

  /// A picture wider than this (16 to 9 is 1.78; the objects are square) is a story page.
  static const double _wideAspect = 1.4;

  /// The card's rim and the room round the picture inside it.
  static const double padding = 12;

  /// The most the card's side is (the picture 396 inside it).
  static const double cardMost = 420;

  /// The thumbnails of the words met earlier in the set, top to bottom: [] on a wide picture on a phone.
  final List<Rect> strip;

  /// The picture card.
  final Rect card;

  static double _column(bool tablet, bool lookA) => tablet ? 88 : (lookA ? 64 : 56);

  /// The gap between the strip column and the card: 16 on a tablet, 12 on a phone, 8 on the small phone (its stage is 264 wide).
  static double _gap(Size stage, bool tablet) => tablet ? 16 : (stage.width < 300 ? 8 : 12);

  static Rect _area(Size stage, bool tablet, bool lookA, {required bool wideOnPhone}) {
    if (wideOnPhone) return Rect.fromLTWH(0, 0, stage.width, stage.height);
    return Rect.fromLTRB(_column(tablet, lookA) + _gap(stage, tablet), 0, stage.width, stage.height);
  }

  static Rect _cardOf(Size stage, double aspect, bool tablet, bool lookA, {required bool wideOnPhone}) {
    final Rect area = _area(stage, tablet, lookA, wideOnPhone: wideOnPhone);
    final double innerH = math.max(
      0,
      math.min(math.min(stage.height, cardMost) - 2 * padding, (area.width - 2 * padding) / aspect),
    );
    return Rect.fromCenter(
      center: area.center,
      width: innerH * aspect + 2 * padding,
      height: innerH + 2 * padding,
    );
  }

  static List<Rect> _stripOf(Size stage, double aspect, int earlier, bool tablet, bool lookA) {
    if (earlier == 0 || (!tablet && aspect > _wideAspect)) return const <Rect>[];
    final double column = _column(tablet, lookA);
    final double gap = _gap(stage, tablet);
    final double side = math.min(column, (stage.height - gap * (earlier - 1)) / earlier);
    final double total = side * earlier + gap * (earlier - 1);
    final double top = (stage.height - total) / 2;
    return <Rect>[
      for (int i = 0; i < earlier; i++)
        Rect.fromLTWH((column - side) / 2, top + i * (side + gap), side, side),
    ];
  }
}
