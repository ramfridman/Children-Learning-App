import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show AssetBundle, rootBundle;

import '../content/models.dart' show ShowStep;
import '../design/tokens.g.dart';
import 'template_session.dart';

// The host's hand in a Show (M11 Stage 2, docs/design/m11-rooms.md section 13): the thing the host demonstrates is lifted from its tile into the
// middle of the stage and held up big under a veil, the host's pointer (its own limb) glides along its sides, the sides it has shown stay lit (a
// white core with an edge in the room's deep colour), numbers pop on the sides it counts, an ant walks the outline, sticks lie on the sides. After
// the motion the pointer drags the thing into its bin. This file is the art, the geometry and the choreography; the sessions of the templates give
// it the places and draw its layer over their stage. Motions that have no row here yet (push, stack, turn, stamp) leave the plain drag of the
// worked example.

/// The sides of one picture in its own 100 by 100 units, from `outlines.json` (`tools/make_show_art.py`).
class ShowOutline {
  const ShowOutline(this.sides, {this.gap});

  /// Each side as a polyline, in order (start at the top, clockwise).
  final List<List<Offset>> sides;

  /// The middle of the opening of an open figure, where the gap ring goes; null for a closed one.
  final Offset? gap;
}

/// The pictures a Show draws: the outlines, the host's pointer and the ant, as the files hold them.
class ShowArt {
  const ShowArt({required this.outlines, required this.hand, required this.antA, required this.antB});

  final Map<String, ShowOutline> outlines;
  final String hand;
  final String antA;
  final String antB;

  /// The files carry Shape Forest's deep (#1E7F4C); another room's deep replaces it.
  static const String shapesDeep = '#1E7F4C';

  static Future<ShowArt> load({AssetBundle? bundle, Color? deep}) async {
    final AssetBundle b = bundle ?? rootBundle;
    String paint(String svg) => deep == null
        ? svg
        : svg.replaceAll(
            shapesDeep,
            '#${(deep.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}',
          );
    final (String json, String hand, String a, String bb) = await (
      b.loadString('assets/art/show/outlines.json'),
      b.loadString('assets/art/hosts/kubi_hand.svg'),
      b.loadString('assets/art/show/ant_a.svg'),
      b.loadString('assets/art/show/ant_b.svg'),
    ).wait;
    return ShowArt(outlines: parseOutlines(json), hand: hand, antA: paint(a), antB: paint(bb));
  }

  /// The outline of the picture [asset] (`asset:shape_triangle_red`), or null for a picture the Show has no outline of.
  ShowOutline? of(String asset) => outlines[asset.startsWith('asset:') ? asset.substring(6) : asset];
}

/// Reads `outlines.json`: a picture is a polygon (`poly`), an open figure (`open`), a dome (`dome`), an ellipse or a line; a solid has no outline
/// here (its motions are not built yet).
Map<String, ShowOutline> parseOutlines(String json) {
  final Map<String, Object?> doc = jsonDecode(json) as Map<String, Object?>;
  final Map<String, Object?> pictures = doc['pictures']! as Map<String, Object?>;
  final Map<String, ShowOutline> out = <String, ShowOutline>{};
  Offset pt(Object? p) {
    final List<Object?> v = p! as List<Object?>;
    return Offset((v[0]! as num).toDouble(), (v[1]! as num).toDouble());
  }

  for (final MapEntry<String, Object?> e in pictures.entries) {
    final Map<String, Object?> p = e.value! as Map<String, Object?>;
    switch (p['kind']) {
      case 'poly':
        final List<Offset> v = <Offset>[for (final Object? q in p['pts']! as List<Object?>) pt(q)];
        out[e.key] = ShowOutline(<List<Offset>>[
          for (int i = 0; i < v.length; i++) <Offset>[v[i], v[(i + 1) % v.length]],
        ]);
      case 'open':
        final List<Offset> v = <Offset>[for (final Object? q in p['pts']! as List<Object?>) pt(q)];
        out[e.key] = ShowOutline(<List<Offset>>[
          for (int i = 0; i < v.length - 1; i++) <Offset>[v[i], v[i + 1]],
        ], gap: (v.last + v.first) / 2);
      case 'dome':
        final List<Offset> q = <Offset>[for (final Object? o in p['q']! as List<Object?>) pt(o)];
        out[e.key] = ShowOutline(<List<Offset>>[
          <Offset>[for (int i = 0; i <= 24; i++) _quad(q[0], q[1], q[2], i / 24)],
          <Offset>[q[2], q[0]],
        ]);
      case 'ellipse':
        final List<Object?> v = p['e']! as List<Object?>;
        final double cx = (v[0]! as num).toDouble(), cy = (v[1]! as num).toDouble();
        final double rx = (v[2]! as num).toDouble(), ry = (v[3]! as num).toDouble();
        out[e.key] = ShowOutline(<List<Offset>>[
          <Offset>[
            for (int i = 0; i <= 48; i++)
              Offset(cx + rx * math.sin(i / 48 * 2 * math.pi), cy - ry * math.cos(i / 48 * 2 * math.pi)),
          ],
        ]);
      case 'line':
        final List<Offset>? path = parsePath(p['d']! as String);
        if (path != null) out[e.key] = ShowOutline(<List<Offset>>[path]);
    }
  }
  return out;
}

Offset _quad(Offset a, Offset c, Offset b, double t) =>
    a * ((1 - t) * (1 - t)) + c * (2 * (1 - t) * t) + b * (t * t);

Offset _cubic(Offset a, Offset c1, Offset c2, Offset b, double t) {
  final double u = 1 - t;
  return a * (u * u * u) + c1 * (3 * u * u * t) + c2 * (3 * u * t * t) + b * (t * t * t);
}

/// A path of absolute `M`, `L`, `C` and `S` commands as a polyline (the pictures' lines use no other); null when it has any other command.
List<Offset>? parsePath(String d) {
  final List<String> tokens = RegExp(r'[A-Za-z]|-?\d+(?:\.\d+)?')
      .allMatches(d)
      .map((RegExpMatch m) => m[0]!)
      .toList();
  final List<Offset> out = <Offset>[];
  Offset at = Offset.zero;
  Offset? lastControl;
  int i = 0;
  String? cmd;
  double next() => double.parse(tokens[i++]);
  while (i < tokens.length) {
    if (RegExp('[A-Za-z]').hasMatch(tokens[i])) cmd = tokens[i++];
    switch (cmd) {
      case 'M' || 'L':
        at = Offset(next(), next());
        out.add(at);
        lastControl = null;
      case 'C':
        final Offset c1 = Offset(next(), next());
        final Offset c2 = Offset(next(), next());
        final Offset b = Offset(next(), next());
        for (int k = 1; k <= 16; k++) {
          out.add(_cubic(at, c1, c2, b, k / 16));
        }
        at = b;
        lastControl = c2;
      case 'S':
        final Offset c1 = lastControl == null ? at : at * 2 - lastControl;
        final Offset c2 = Offset(next(), next());
        final Offset b = Offset(next(), next());
        for (int k = 1; k <= 16; k++) {
          out.add(_cubic(at, c1, c2, b, k / 16));
        }
        at = b;
        lastControl = c2;
      default:
        return null;
    }
  }
  return out.length < 2 ? null : out;
}

/// How a Show is drawn for this host and this child: the art, the room's colours, the pace of the look (P1 and P2 are slower) and whether
/// movement is reduced (each step then appears in place, one after the other).
class ShowStyle {
  const ShowStyle({
    required this.art,
    required this.deep,
    required this.lip,
    this.slow = false,
    this.still = false,
  });

  final ShowArt art;
  final Color deep;
  final Color lip;
  final bool slow;
  final bool still;
}

/// What the Show has drawn on the stage now (see [ShowLayer]); the session changes it and notifies.
class ShowMarks {
  /// The thing lifted into the middle of the stage, its picture, where it flew from and how far it has flown (0 to 1).
  Rect? spot;
  String? spotSvg;
  Rect? from;
  double lift = 1;

  /// The veil over the bins, 0 to 1.
  double veil = 0;

  /// The sizes of the marks are those of a phone (a stage 128 high) times this (`hintScale` of the stage).
  double scale = 1;

  /// The sides shown and lit (stage coordinates), the side being drawn, the numbers, the gap ring, the sticks.
  final List<List<Offset>> lit = <List<Offset>>[];
  List<Offset> drawing = <Offset>[];
  final List<(Offset, int)> badges = <(Offset, int)>[];
  Offset? gap;
  final List<List<Offset>> sticks = <List<Offset>>[];

  /// The pointer's tip and its angle (0 = the leg hangs straight down; clockwise is positive), the ant and its heading.
  Offset? tip;
  double tipAngle = 0;
  Offset? ant;
  double antHeading = 0;
  bool antStep = false;

  bool get active => spot != null || tip != null || veil > 0;

  void clearMarks() {
    lit.clear();
    drawing = <Offset>[];
    badges.clear();
    gap = null;
    sticks.clear();
    tip = null;
    ant = null;
  }

  void clear() {
    clearMarks();
    spot = null;
    spotSvg = null;
    from = null;
    veil = 0;
    lift = 1;
  }
}

/// The choreography of one Show step on a [session]'s stage: it moves the pointer, the ant and the marks of [marks] in time, through the
/// session's own timers (a session that is gone stops it).
class ShowDirector {
  ShowDirector(this.session, this.style, this.marks);

  final TemplateSession session;
  final ShowStyle style;
  final ShowMarks marks;

  /// The step keys this director draws; any other leaves the worked example's plain drag.
  static const Set<String> motions = <String>{'trace', 'count', 'walk', 'sticks'};

  int _ms(int fast, int slow) => style.slow ? slow : fast;

  /// The side of the square a lifted thing is held in: the stage's height less 20 on a phone, 36 on a tablet.
  static double spotSide(Size stage) => stage.height - (stage.height > 200 ? 36 : 20);

  /// The thing flies from its tile to the spot (450 ms, 350 for the older looks) and the veil comes over the bins.
  Future<void> lift({required Rect from, required Rect spot, required String svg}) async {
    marks
      ..from = from
      ..spot = spot
      ..spotSvg = svg
      ..lift = style.still ? 1 : 0
      ..veil = style.still ? 1 : 0;
    session.notify();
    if (style.still) return;
    await session.animate(Duration(milliseconds: _ms(350, 450)), (double t) {
      marks
        ..lift = Curves.easeOutCubic.transform(t)
        ..veil = t;
      session.notify();
    });
  }

  /// The pointer drags the thing from the spot to [to] (the bin it goes in), the marks go, and the veil lifts.
  Future<void> dropTo(Rect to) async {
    final Rect? from = marks.spot;
    if (from == null) return;
    marks.clearMarks();
    if (!style.still) {
      await session.animate(Duration(milliseconds: _ms(450, 600)), (double t) {
        final double k = Curves.easeInOutCubic.transform(t);
        marks
          ..spot = Rect.lerp(from, to, k)
          ..veil = 1 - t;
        marks.tip = marks.spot!.center + Offset(0, marks.spot!.height / 2);
        marks.tipAngle = 0;
        session.notify();
      });
    }
    marks.clear();
    session.notify();
  }

  /// The pointer's angle at [tip] on a thing centred at [centre]: the leg points away from the middle of the thing, so it never lies across
  /// it, within the range of the design (-120 to +45 degrees, 0 = straight down).
  static double angleAway(Offset tip, Offset centre) {
    final Offset d = tip - centre;
    if (d.distanceSquared < 1) return 0;
    final double a = math.atan2(-d.dx, d.dy);
    return a.clamp(-120 * math.pi / 180, 45 * math.pi / 180);
  }

  /// Draws the motion of [step] on [outline], mapped into [box] (the picture's square on the stage). Returns false when this director has no row
  /// for the step's key (nothing was drawn).
  Future<bool> motion(ShowStep step, ShowOutline outline, Rect box) async {
    final String? key = step.motion;
    if (key == null || !motions.contains(key)) return false;
    Offset map(Offset u) => box.topLeft + Offset(u.dx / 100 * box.width, u.dy / 100 * box.height);
    final List<List<Offset>> sides = <List<Offset>>[
      for (final List<Offset> side in outline.sides) <Offset>[for (final Offset p in side) map(p)],
    ];
    final Offset centre = box.center;
    final double k = marks.scale;
    final bool walk = key == 'walk';
    final bool open = outline.gap != null;
    final double speed = (style.slow ? 70 : 100) * k;
    for (final (int i, List<Offset> side) in sides.indexed) {
      final double length = _length(side);
      final int ms = key == 'sticks'
          ? 200
          : walk
          ? math.max(300, (length / speed * 1000).round())
          : _ms(600, 900);
      if (style.still) {
        await session.pause(const Duration(milliseconds: 600));
      } else if (key != 'sticks') {
        // The tip goes to the start of the first side from below, then along every side at an even pace.
        marks.drawing = <Offset>[side.first];
        _place(walk, side.first, centre, side.first, side[1]);
        session.notify();
        await session.animate(Duration(milliseconds: ms), (double t) {
          final List<Offset> upto = _upTo(side, t);
          marks.drawing = upto;
          _place(walk, upto.last, centre, upto.length > 1 ? upto[upto.length - 2] : side.first, upto.last);
          if (walk) marks.antStep = (t * ms / 200).floor().isEven;
          session.notify();
        });
      } else {
        await session.pause(Duration(milliseconds: 350));
      }
      if (key == 'sticks') {
        marks.sticks.add(side);
      } else {
        marks.lit.add(side);
        marks.drawing = <Offset>[];
      }
      if (key == 'count') {
        final Offset mid = side[side.length ~/ 2];
        final Offset away = mid - centre;
        final Offset dir = away.distance < 1 ? const Offset(0, 1) : away / away.distance;
        marks.badges.add((mid + dir * (14 * k), i + 1));
        session.notify();
        await session.pause(Duration(milliseconds: _ms(300, 400)));
      } else {
        session.notify();
        await session.pause(const Duration(milliseconds: 250));
      }
    }
    if (open) {
      marks.gap = map(outline.gap!);
      session.notify();
      await session.pause(const Duration(milliseconds: 700));
    }
    marks
      ..tip = null
      ..ant = null;
    session.notify();
    return true;
  }

  void _place(bool walk, Offset at, Offset centre, Offset before, Offset now) {
    if (walk) {
      marks
        ..ant = at
        ..antHeading = math.atan2(now.dx - before.dx, -(now.dy - before.dy))
        ..tip = null;
    } else {
      marks
        ..tip = at
        ..tipAngle = angleAway(at, centre)
        ..ant = null;
    }
  }

  static double _length(List<Offset> side) {
    double l = 0;
    for (int i = 1; i < side.length; i++) {
      l += (side[i] - side[i - 1]).distance;
    }
    return l;
  }

  /// The part of [side] up to [t] (0 to 1) of its length, ending at the exact point.
  static List<Offset> _upTo(List<Offset> side, double t) {
    final double want = _length(side) * t;
    final List<Offset> out = <Offset>[side.first];
    double done = 0;
    for (int i = 1; i < side.length; i++) {
      final double seg = (side[i] - side[i - 1]).distance;
      if (done + seg >= want) {
        final double f = seg == 0 ? 0 : (want - done) / seg;
        out.add(side[i - 1] + (side[i] - side[i - 1]) * f);
        return out;
      }
      out.add(side[i]);
      done += seg;
    }
    return out;
  }
}

/// The Show's layer over a stage: the veil, the lifted thing, the marks, the ant and the host's pointer. It draws only while a Show acts.
class ShowLayer extends StatelessWidget {
  const ShowLayer({super.key, required this.marks, required this.style});

  final ShowMarks marks;
  final ShowStyle style;

  @override
  Widget build(BuildContext context) {
    if (!marks.active) return const SizedBox.shrink();
    final double k = marks.scale;
    final Rect? spot = marks.spot;
    final Rect? at = spot == null
        ? null
        : marks.from == null
        ? spot
        : Rect.lerp(marks.from, spot, marks.lift);
    final double handWidth = 34 * k;
    final double handScale = handWidth / 64;
    return IgnorePointer(
      child: Stack(
        clipBehavior: Clip.none,
        children: <Widget>[
          if (marks.veil > 0)
            Positioned.fill(
              child: ColoredBox(color: TokenColors.paper.withValues(alpha: 0.5 * marks.veil)),
            ),
          if (at != null && marks.spotSvg != null)
            Positioned.fromRect(rect: at, child: PackSvg(marks.spotSvg!)),
          Positioned.fill(child: CustomPaint(painter: _MarksPainter(marks, style))),
          if (marks.ant != null)
            Positioned(
              left: marks.ant!.dx - 13 * k,
              top: marks.ant!.dy - 13 * k,
              width: 26 * k,
              height: 26 * k,
              child: Transform.rotate(
                angle: marks.antHeading,
                child: PackSvg(marks.antStep ? style.art.antA : style.art.antB),
              ),
            ),
          if (marks.tip != null)
            Positioned(
              left: marks.tip!.dx - 32 * handScale,
              top: marks.tip!.dy - 3 * handScale,
              width: handWidth,
              height: 300 * handScale,
              child: Transform.rotate(
                angle: marks.tipAngle,
                alignment: Alignment(0, -1 + 2 * (3 / 300)),
                child: PackSvg(style.art.hand),
              ),
            ),
        ],
      ),
    );
  }
}

class _MarksPainter extends CustomPainter {
  _MarksPainter(this.marks, this.style);

  final ShowMarks marks;
  final ShowStyle style;

  @override
  void paint(Canvas canvas, Size size) {
    final double k = marks.scale;
    void line(
      List<Offset> pts, {
      required double edge,
      required double core,
      Color? edgeColour,
      Color? coreColour,
    }) {
      if (pts.length < 2) return;
      final Path path = Path()..moveTo(pts.first.dx, pts.first.dy);
      for (final Offset p in pts.skip(1)) {
        path.lineTo(p.dx, p.dy);
      }
      final Paint base = Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;
      canvas.drawPath(
        path,
        base
          ..strokeWidth = edge
          ..color = edgeColour ?? style.deep,
      );
      canvas.drawPath(
        path,
        base
          ..strokeWidth = core
          ..color = coreColour ?? TokenColors.paper,
      );
    }

    for (final List<Offset> side in marks.lit) {
      line(side, edge: 7 * k, core: 3.4 * k);
    }
    line(marks.drawing, edge: 7 * k, core: 3.4 * k);
    for (final List<Offset> stick in marks.sticks) {
      line(
        stick,
        edge: 6 * k + 3,
        core: 6 * k,
        edgeColour: TokenColors.ink,
        coreColour: const Color(0xFFC98F52),
      );
    }
    for (final (Offset at, int n) in marks.badges) {
      canvas
        ..drawCircle(at + Offset(0, 2 * k), 11 * k, Paint()..color = style.lip)
        ..drawCircle(at, 11 * k, Paint()..color = TokenColors.paper)
        ..drawCircle(
          at,
          11 * k,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.5 * k
            ..color = style.deep,
        );
      final TextPainter text = TextPainter(
        text: TextSpan(
          text: '$n',
          style: TextStyle(
            fontFamily: 'Heebo',
            fontWeight: FontWeight.w800,
            fontSize: 14 * k,
            color: TokenColors.ink,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      text.paint(canvas, at - Offset(text.width / 2, text.height / 2));
    }
    final Offset? gap = marks.gap;
    if (gap != null) {
      canvas
        ..drawCircle(gap, 9 * k, Paint()..color = TokenColors.paper.withValues(alpha: 0.55))
        ..drawCircle(
          gap,
          9 * k,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.5 * k
            ..color = style.deep,
        );
    }
  }

  @override
  bool shouldRepaint(covariant _MarksPainter old) => true;
}
