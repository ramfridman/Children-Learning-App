import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../design/board.dart' show BoardClass;
import '../design/components.dart';
import '../design/course_text.dart';
import '../design/tokens.g.dart';
import '../strings/he.dart';
import 'hints/hint_pictures.dart' show SkyRing;
import 'l5_art.dart';
import 'ls01_metrics.dart' show lineHeightFor;

// The two screens of LS05 change one part (docs/design/l5-templates.md section 4), as widgets that draw in the points of their own box: the Hebrew wheel
// (a half dial of letters, the unit made in the hub, a row of signs) and the Russian strip (the frame card with its window, and the strip of vowels).
// The full template puts them on the board; a hint puts the small wheel and the compact strip inside the stage of the item that borrows them (L5 5.9).

/// The numbers of one wheel: the dial's centre and ring, its beads, the hub and the row of signs. [slots] is how many beads the half dial shows at once.
class WheelSpec {
  const WheelSpec({
    required this.centre,
    required this.ring,
    required this.bead,
    required this.font,
    required this.step,
    required this.hub,
    required this.unitFont,
    required this.signBead,
    required this.signY,
    required this.signGap,
    this.panelHeight = 20,
    this.panelWidth,
  });

  final Offset centre;
  final double ring;
  final double bead;
  final double font;

  /// The angle between two beads, in degrees.
  final double step;
  final Size hub;
  final double unitFont;
  final double signBead;
  final double signY;
  final double signGap;
  final double panelHeight;
  final double? panelWidth;

  int get slots => (180 ~/ step) + 1;

  /// The wheel of the full template on [board] (board points).
  static WheelSpec of(BoardClass board) => switch (board) {
    BoardClass.phone => const WheelSpec(
      centre: Offset(212, 270),
      ring: 136,
      bead: 60,
      font: 48,
      step: 30,
      hub: Size(100, 84),
      unitFont: 46,
      signBead: 56,
      signY: 284,
      signGap: 16,
      panelHeight: 99,
    ),
    BoardClass.phoneSE => const WheelSpec(
      centre: Offset(190, 270),
      ring: 120,
      bead: 56,
      font: 48,
      step: 30,
      hub: Size(80, 80),
      unitFont: 42,
      signBead: 56,
      signY: 288,
      signGap: 8,
      panelHeight: 81,
    ),
    BoardClass.tabletLandscape => const WheelSpec(
      centre: Offset(560, 600),
      ring: 250,
      bead: 88,
      font: 64,
      step: 30,
      hub: Size(240, 150),
      unitFont: 72,
      signBead: 88,
      signY: 624,
      signGap: 24,
      panelHeight: 196,
    ),
    BoardClass.tabletPortrait => const WheelSpec(
      centre: Offset(410, 830),
      ring: 300,
      bead: 96,
      font: 64,
      step: 30,
      hub: Size(280, 170),
      unitFont: 80,
      signBead: 96,
      signY: 860,
      signGap: 24,
      panelHeight: 326,
    ),
  };

  /// The small wheel of a hint (L5 5.9): it carries only the part that changes, and the unit made stands beside it. [centre] is in the box of the card.
  static WheelSpec mini(BoardClass board, Offset centre) => switch (board) {
    BoardClass.phone => WheelSpec(
      centre: centre,
      ring: 70,
      bead: 48,
      font: 34,
      step: 45,
      hub: const Size(72, 64),
      unitFont: 40,
      signBead: 40,
      signY: 0,
      signGap: 8,
      panelHeight: 12,
      panelWidth: 190,
    ),
    BoardClass.phoneSE => WheelSpec(
      centre: centre,
      ring: 54,
      bead: 40,
      font: 30,
      step: 50,
      hub: const Size(64, 56),
      unitFont: 36,
      signBead: 36,
      signY: 0,
      signGap: 8,
      panelHeight: 12,
      panelWidth: 150,
    ),
    _ => WheelSpec(
      centre: centre,
      ring: 140,
      bead: 76,
      font: 52,
      step: 45,
      hub: const Size(120, 100),
      unitFont: 64,
      signBead: 64,
      signY: 0,
      signGap: 12,
      panelHeight: 16,
      panelWidth: 380,
    ),
  };
}

/// The ring offsets of the beads: a wheel with as many parts as slots (or more) is a loop, so what turns past the panel comes back on the other
/// side; a shorter one simply shifts its parts. [turn] is the part at the top, fractional while the dial turns.
double ringOffset(int k, double turn, int n, int slots) {
  if (n >= slots) {
    final double half = n / 2;
    double d = (k - turn + half) % n;
    if (d < 0) d += n;
    return d - half;
  }
  return k - turn;
}

/// The signs of a wheel whose results have one sound (patah and qamats) share one pale pill, "two signs, one sound": the groups, as runs of the row.
List<List<int>> signGroups(List<String> signs, bool Function(int a, int b) sameSound) {
  final List<List<int>> out = <List<int>>[];
  for (int i = 0; i < signs.length; i++) {
    if (out.isNotEmpty && sameSound(out.last.last, i)) {
      out.last.add(i);
    } else {
      out.add(<int>[i]);
    }
  }
  return out;
}

/// Where the unit made stands in relation to the dial.
enum HubSide { middle, left, right }

/// The Hebrew wheel: a half dial of beads on a panel, the pointer on the part at the top, the unit made in the hub and a row of sign beads.
class WheelView extends StatelessWidget {
  const WheelView({
    super.key,
    required this.spec,
    required this.ring,
    required this.ringIsSigns,
    required this.turn,
    required this.hubText,
    required this.onRing,
    this.signs = const <String>[],
    this.curSign = 0,
    this.onSign,
    this.groups = const <List<int>>[],
    this.hubLit = false,
    this.hubShake = false,
    this.hubSound = true,
    this.onHub,
    this.litRing,
    this.hubSide = HubSide.middle,
    this.showPanel = true,
  });

  final WheelSpec spec;

  /// What the ring carries: letters (text) or signs (drawn as shapes), and the one at the top (fractional while turning).
  final List<String> ring;
  final bool ringIsSigns;
  final double turn;
  final String hubText;
  final void Function(int index) onRing;
  final List<String> signs;
  final int curSign;
  final void Function(int index)? onSign;
  final List<List<int>> groups;
  final bool hubLit;
  final bool hubShake;
  final bool hubSound;
  final VoidCallback? onHub;

  /// A bead the friend's hand is on.
  final int? litRing;

  /// Where the unit made stands: in the middle of the dial, or beside it (the small wheel of a hint).
  final HubSide hubSide;
  final bool showPanel;

  @override
  Widget build(BuildContext context) {
    final WheelSpec w = spec;
    final double radius = w.ring + w.bead / 2 + 8;
    final int n = ring.length;
    final int at = turn.round() % math.max(1, n);
    final bool beside = hubSide != HubSide.middle;
    final double hubLeft = switch (hubSide) {
      HubSide.middle => w.centre.dx - w.hub.width / 2,
      HubSide.left => w.centre.dx - radius - 12 - w.hub.width,
      HubSide.right => w.centre.dx + radius + 12,
    };
    final double hubTop = beside ? w.centre.dy - w.hub.height - 4 : w.centre.dy - w.hub.height - 2;
    return Stack(
      clipBehavior: Clip.none,
      children: <Widget>[
        Positioned.fill(
          child: IgnorePointer(child: CustomPaint(painter: _DialPainter(w, radius, showPanel))),
        ),
        // The dashed line from the part at the top down to the hub: "this letter and this sign make this".
        if (!beside)
          Positioned(
            left: w.centre.dx - 2,
            top: w.centre.dy - w.ring + w.bead / 2 + 8,
            width: 4,
            height: math.max(0, w.ring - w.bead / 2 - w.hub.height - 22),
            child: const DashedRRect(radius: 2, width: 4, dash: 6, gap: 5),
          ),
        for (int k = 0; k < n; k++) ..._bead(k, at),
        // The pointer: a ring on the part at the top and an ink triangle over it.
        Positioned(
          left: w.centre.dx - (w.bead + 14) / 2,
          top: w.centre.dy - w.ring - w.bead / 2 - 7,
          width: w.bead + 14,
          height: w.bead + 14,
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: TokenColors.lilacDeep, width: 5),
              ),
            ),
          ),
        ),
        Positioned(
          left: w.centre.dx - 13,
          top: w.centre.dy - w.ring - w.bead / 2 - 24,
          child: const IgnorePointer(
            child: SizedBox(width: 26, height: 16, child: CustomPaint(painter: _PointerPainter())),
          ),
        ),
        // The unit made.
        Positioned(
          left: hubLeft,
          top: hubTop,
          width: w.hub.width,
          height: w.hub.height,
          child: _Hub(
            key: const Key('wheel-hub'),
            text: hubText,
            font: w.unitFont,
            lit: hubLit,
            shake: hubShake,
            onTap: onHub,
          ),
        ),
        if (signs.isNotEmpty) ..._signRow(),
      ],
    );
  }

  Iterable<Widget> _bead(int k, int at) sync* {
    final WheelSpec w = spec;
    final double off = ringOffset(k, turn, ring.length, w.slots);
    // The next part in reading order stands towards the end side of the course (the left): the dial turns the way a Hebrew row reads.
    final double angle = 90 + off * w.step;
    if (angle < -0.5 || angle > 180.5) return;
    final double rad = angle * math.pi / 180;
    final double x = w.centre.dx + w.ring * math.cos(rad) - w.bead / 2;
    final double y = w.centre.dy - w.ring * math.sin(rad) - w.bead / 2;
    final bool current = k == at;
    yield Positioned(
      left: x,
      top: y,
      width: w.bead,
      height: w.bead,
      child: _Bead(
        key: Key('wheel-bead-$k'),
        label: ringIsSigns ? He.wheelSignSemantics.text : He.wheelLetterSemantics.text,
        current: current,
        lit: litRing == k,
        onTap: () => onRing(k),
        child: ringIsSigns
            ? SignShape(ring[k], size: w.bead)
            : CourseText(ring[k], course: 'heb', size: w.font, bold: true, lineHeight: 1.0),
      ),
    );
  }

  Iterable<Widget> _signRow() sync* {
    final WheelSpec w = spec;
    final int n = signs.length;
    final double total = n * w.signBead + (n - 1) * w.signGap;
    final double left = w.centre.dx - total / 2;
    // The first sign is at the course's start: at the right in the Hebrew course.
    double xOf(int j) => left + (n - 1 - j) * (w.signBead + w.signGap);
    for (final List<int> g in groups) {
      if (g.length < 2) continue;
      final double a = xOf(g.last) - 6;
      final double b = xOf(g.first) + w.signBead + 6;
      yield Positioned(
        left: a,
        top: w.signY - 10,
        width: b - a,
        height: w.signBead + 20,
        child: DecoratedBox(
          key: Key('sign-pill-${g.first}'),
          decoration: BoxDecoration(color: const Color(0xB3FFFFFF), borderRadius: BorderRadius.circular(26)),
        ),
      );
    }
    for (int j = 0; j < n; j++) {
      yield Positioned(
        left: xOf(j) - w.signGap / 2,
        top: w.signY - 10,
        width: w.signBead + w.signGap,
        height: w.signBead + 20,
        child: Center(
          child: SizedBox(
            width: w.signBead,
            height: w.signBead,
            child: _Bead(
              key: Key('wheel-sign-$j'),
              label: He.wheelSignSemantics.text,
              current: j == curSign,
              lit: false,
              onTap: () => onSign?.call(j),
              hitInflate: EdgeInsets.symmetric(horizontal: w.signGap / 2, vertical: 10),
              child: SignShape(signs[j], size: w.signBead),
            ),
          ),
        ),
      );
    }
  }
}

/// The ink pointer over the part at the top of the dial: a small triangle pointing down.
class _PointerPainter extends CustomPainter {
  const _PointerPainter();

  @override
  void paint(Canvas canvas, Size size) => canvas.drawPath(
    Path()
      ..moveTo(2, 2)
      ..lineTo(size.width - 2, 2)
      ..lineTo(size.width / 2, size.height - 2)
      ..close(),
    Paint()..color = TokenColors.ink,
  );

  @override
  bool shouldRepaint(_PointerPainter old) => false;
}

class _DialPainter extends CustomPainter {
  const _DialPainter(this.w, this.radius, this.showPanel);

  final WheelSpec w;
  final double radius;
  final bool showPanel;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset c = w.centre;
    final Rect disc = Rect.fromCircle(center: c, radius: radius);
    canvas.save();
    canvas.clipRect(Rect.fromLTRB(c.dx - radius - 6, c.dy - radius - 6, c.dx + radius + 6, c.dy + 6));
    // The cream band where the beads run, the white inside it, the hairline round it.
    canvas.drawCircle(c, radius, Paint()..color = const Color(0xFFFFF9EF));
    canvas.drawCircle(c, radius - w.bead / 2 - 12, Paint()..color = Colors.white);
    canvas.drawCircle(
      c,
      radius - 2,
      Paint()
        ..color = TokenColors.hairline
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4,
    );
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: w.ring),
      math.pi,
      math.pi,
      false,
      Paint()
        ..color = TokenColors.mist
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
    canvas.restore();
    if (showPanel) {
      final double pw = w.panelWidth ?? (2 * radius + 28);
      final RRect panel = RRect.fromRectAndRadius(
        Rect.fromLTWH(c.dx - pw / 2, c.dy - 4, pw, w.panelHeight),
        const Radius.circular(16),
      );
      canvas.drawRRect(panel.shift(const Offset(0, 6)), Paint()..color = TokenColors.cardLip);
      canvas.drawRRect(panel, Paint()..color = TokenColors.mist);
    }
    // Nothing is drawn for the lower half of the disc: it is behind the panel.
    if (disc.isEmpty) return;
  }

  @override
  bool shouldRepaint(_DialPainter old) => old.w != w || old.radius != radius || old.showPanel != showPanel;
}

/// A bead of the dial or the row: a white disc, ringed in ink when it is the current one, lit sky when a hint's hand is on it.
class _Bead extends StatelessWidget {
  const _Bead({
    super.key,
    required this.child,
    required this.current,
    required this.lit,
    required this.onTap,
    required this.label,
    this.hitInflate = const EdgeInsets.all(6),
  });

  final Widget child;
  final bool current;
  final bool lit;
  final VoidCallback onTap;
  final String label;
  final EdgeInsets hitInflate;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: label,
    child: Stack(
      clipBehavior: Clip.none,
      children: <Widget>[
        Positioned(
          left: -hitInflate.left,
          top: -hitInflate.top,
          right: -hitInflate.right,
          bottom: -hitInflate.bottom,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onTap,
            child: const SizedBox.expand(),
          ),
        ),
        Positioned.fill(
          child: IgnorePointer(
            child: Container(
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                border: Border.all(
                  color: current ? TokenColors.ink : TokenColors.hairline,
                  width: current ? 4 : 3,
                ),
                boxShadow: clayShadows(TokenColors.cardLip, lipHeight: current ? 6 : 4),
              ),
              child: ClipOval(child: child),
            ),
          ),
        ),
        if (lit) const Positioned.fill(child: IgnorePointer(child: SkyRing(radius: 14))),
      ],
    ),
  );
}

/// The unit made, at the stem size; a touch plays it. A unit with no sound swings gently twice (a lilac border with reduce-motion).
class _Hub extends StatefulWidget {
  const _Hub({
    super.key,
    required this.text,
    required this.font,
    required this.lit,
    required this.shake,
    required this.onTap,
  });

  final String text;
  final double font;
  final bool lit;
  final bool shake;
  final VoidCallback? onTap;

  @override
  State<_Hub> createState() => _HubState();
}

class _HubState extends State<_Hub> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 300),
  );

  @override
  void didUpdateWidget(_Hub old) {
    super.didUpdateWidget(old);
    if (widget.shake && !old.shake && !MediaQuery.disableAnimationsOf(context)) _c.forward(from: 0);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool still = MediaQuery.disableAnimationsOf(context);
    return Semantics(
      button: true,
      label: He.wheelHubSemantics.text,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: Stack(
          clipBehavior: Clip.none,
          children: <Widget>[
            if (widget.lit)
              Positioned(
                left: -8,
                top: -8,
                right: -8,
                bottom: -8,
                child: const IgnorePointer(child: SkyRing(round: false, radius: 26)),
              ),
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _c,
                builder: (BuildContext context, Widget? child) => Transform.rotate(
                  angle: math.sin(_c.value * math.pi * 4) * 3 * math.pi / 180 * (1 - _c.value),
                  child: child,
                ),
                child: Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: TokenColors.lilacDeep, width: 4),
                    boxShadow: clayShadows(TokenColors.cardLip, lipHeight: 4),
                  ),
                  child: widget.text.isEmpty
                      ? const SizedBox.shrink()
                      : CourseText(
                          widget.text,
                          course: 'heb',
                          size: widget.font,
                          lineHeight: lineHeightFor(widget.text, hebrew: true),
                        ),
                ),
              ),
            ),
            if (widget.shake && still)
              Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: TokenColors.notYetRing, width: 4),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ---- the strip ----

/// The pairs of the Russian vowels, as code points (a hard vowel and its soft one, so the pairs read as pairs on the strip): the sound-scheme pairs
/// of the school, a-ya, o-yo, u-yu, y-i, e-ye.
const List<List<int>> _vowelPairs = <List<int>>[
  <int>[0x0430, 0x044F],
  <int>[0x043E, 0x0451],
  <int>[0x0443, 0x044E],
  <int>[0x044B, 0x0438],
  <int>[0x044D, 0x0435],
];

/// The pair a Cyrillic vowel is in, or -1.
int vowelPairOf(String v) {
  if (v.runes.length != 1) return -1;
  final int r = v.runes.first;
  for (int i = 0; i < _vowelPairs.length; i++) {
    if (_vowelPairs[i].contains(r)) return i;
  }
  return -1;
}

/// What the strip's tiles are laid out as: the sizes of a board.
class StripSpec {
  const StripSpec({
    required this.cell,
    required this.font,
    required this.tile,
    required this.inPair,
    required this.betweenPairs,
  });

  final double cell;
  final double font;
  final double tile;
  final double inPair;
  final double betweenPairs;

  static StripSpec of(BoardClass board) => switch (board) {
    BoardClass.phone => const StripSpec(cell: 88, font: 48, tile: 88, inPair: 4, betweenPairs: 16),
    BoardClass.phoneSE => const StripSpec(cell: 80, font: 48, tile: 72, inPair: 4, betweenPairs: 12),
    BoardClass.tabletLandscape => const StripSpec(
      cell: 120,
      font: 64,
      tile: 104,
      inPair: 6,
      betweenPairs: 24,
    ),
    BoardClass.tabletPortrait => const StripSpec(cell: 128, font: 64, tile: 104, inPair: 6, betweenPairs: 24),
  };

  /// The compact strip of a hint: tiles 48 (84 on a tablet), cells 52 (96), letters 36 (56).
  static StripSpec compact(BoardClass board) => switch (board) {
    BoardClass.tabletLandscape ||
    BoardClass.tabletPortrait => const StripSpec(cell: 96, font: 56, tile: 84, inPair: 4, betweenPairs: 12),
    BoardClass.phoneSE => const StripSpec(cell: 44, font: 30, tile: 40, inPair: 3, betweenPairs: 8),
    _ => const StripSpec(cell: 52, font: 36, tile: 48, inPair: 4, betweenPairs: 10),
  };
}

/// The frame card of the strip: the letters of the frame in cells, and the window, a framed cell that shows the current vowel. A touch plays it.
class FrameCard extends StatelessWidget {
  const FrameCard({
    super.key,
    required this.course,
    required this.frame,
    required this.window,
    required this.spec,
    this.lit = false,
    this.onTap,
  });

  final String course;

  /// The frame's text, with `_` where the window is.
  final String frame;
  final String window;
  final StripSpec spec;
  final bool lit;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: He.stripWindowSemantics.text,
    child: GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: <Widget>[
          if (lit)
            const Positioned(
              left: -8,
              top: -8,
              right: -8,
              bottom: -8,
              child: IgnorePointer(child: SkyRing(round: false, radius: 30)),
            ),
          Container(
            key: const Key('frame-card'),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: TokenColors.ink, width: 4),
              boxShadow: clayShadows(TokenColors.cardLip, lipHeight: 4),
            ),
            child: Directionality(
              textDirection: TextDirection.ltr,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  for (final String ch in frame.characters)
                    SizedBox(
                      width: spec.cell,
                      height: spec.cell * 0.92,
                      child: ch == '_'
                          ? Container(
                              key: const Key('frame-window'),
                              margin: const EdgeInsets.all(3),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF4EFFF),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: TokenColors.lilacDeep, width: 5),
                              ),
                              child: CourseText(window, course: course, size: spec.font, bold: true),
                            )
                          : Center(
                              child: CourseText(ch, course: course, size: spec.font, bold: true),
                            ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

/// A tile of the strip: a vowel, lifted and ringed when it is the current one. The tap and the slide are the strip's (`VowelStrip`).
class StripTile extends StatelessWidget {
  const StripTile({
    super.key,
    required this.text,
    required this.course,
    required this.spec,
    required this.current,
    this.lit = false,
  });

  final String text;
  final String course;
  final StripSpec spec;
  final bool current;
  final bool lit;

  @override
  Widget build(BuildContext context) => Stack(
    clipBehavior: Clip.none,
    children: <Widget>[
      Positioned(
        left: 0,
        top: current ? -5 : 0,
        width: spec.tile,
        height: spec.tile,
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: current ? TokenColors.lilacDeep : TokenColors.hairline,
              width: current ? 5 : 3,
            ),
            boxShadow: clayShadows(TokenColors.cardLip, lipHeight: current ? 6 : 4),
          ),
          child: CourseText(text, course: course, size: spec.font, bold: true),
        ),
      ),
      if (lit)
        Positioned(
          left: -6,
          top: -6,
          width: spec.tile + 12,
          height: spec.tile + 12,
          child: const IgnorePointer(child: SkyRing(round: false, radius: 26)),
        ),
    ],
  );
}

/// The strip: the vowel parts in pair order on pale pills, left to right always. A tap on a tile makes it current; a finger slid along the strip makes
/// each tile current as it passes. [onPick] is a tap, [onSlide] each tile the finger passes, [onSlideEnd] the tile it rests on or lifts from.
class VowelStrip extends StatelessWidget {
  const VowelStrip({
    super.key,
    required this.texts,
    required this.course,
    required this.spec,
    required this.current,
    required this.onPick,
    this.onSlide,
    this.onSlideEnd,
    this.litTile,
  });

  /// The text of each tile, in the order laid out (pair order).
  final List<String> texts;
  final String course;
  final StripSpec spec;
  final int current;
  final void Function(int index) onPick;
  final void Function(int index)? onSlide;
  final VoidCallback? onSlideEnd;
  final int? litTile;

  /// The width of the whole row for [texts].
  static double widthOf(List<String> texts, StripSpec s) {
    double w = 0;
    for (int i = 0; i < texts.length; i++) {
      if (i > 0) w += _samePair(texts, i) ? s.inPair : s.betweenPairs;
      w += s.tile;
    }
    return w;
  }

  static bool _samePair(List<String> texts, int i) {
    final int a = vowelPairOf(texts[i - 1]);
    return a >= 0 && a == vowelPairOf(texts[i]);
  }

  /// The tile under [x], a point along the row from its start.
  int _tileAt(double x) {
    double at = 0;
    for (int i = 0; i < texts.length; i++) {
      at += (i > 0 ? (_samePair(texts, i) ? spec.inPair : spec.betweenPairs) : 0) + spec.tile;
      if (x <= at + 4) return i;
    }
    return texts.length - 1;
  }

  @override
  Widget build(BuildContext context) {
    final double width = widthOf(texts, spec);
    final List<Widget> kids = <Widget>[];
    double x = 0;
    int pairStart = 0;
    for (int i = 0; i < texts.length; i++) {
      if (i > 0) x += _samePair(texts, i) ? spec.inPair : spec.betweenPairs;
      if (i > 0 && !_samePair(texts, i)) pairStart = i;
      kids.add(
        Positioned(
          left: x,
          top: 0,
          width: spec.tile,
          height: spec.tile,
          child: Semantics(
            button: true,
            label: He.stripTileSemantics.text,
            child: GestureDetector(
              key: Key('strip-tile-$i'),
              behavior: HitTestBehavior.opaque,
              onTap: () => onPick(i),
              child: StripTile(
                text: texts[i],
                course: course,
                spec: spec,
                current: i == current,
                lit: litTile == i,
              ),
            ),
          ),
        ),
      );
      x += spec.tile;
      // A pale pill behind a pair, drawn under its tiles.
      final bool endsPair = i == texts.length - 1 || !_samePair(texts, i + 1);
      if (endsPair && i > pairStart) {
        final double pill = (i - pairStart + 1) * spec.tile + (i - pairStart) * spec.inPair;
        kids.insert(
          0,
          Positioned(
            left: x - pill - 6,
            top: -6,
            width: pill + 12,
            height: spec.tile + 12,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: TokenColors.mist.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(28),
              ),
            ),
          ),
        );
      }
    }
    return SizedBox(
      width: width,
      height: spec.tile,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onHorizontalDragUpdate: onSlide == null
            ? null
            : (DragUpdateDetails d) => onSlide!(_tileAt(d.localPosition.dx)),
        onHorizontalDragEnd: onSlideEnd == null ? null : (DragEndDetails _) => onSlideEnd!(),
        child: Stack(clipBehavior: Clip.none, children: kids),
      ),
    );
  }
}
