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
// it the places and draw its layer over their stage. The solids' motions (push and roll, stack, turn round, stamp in the sand) are in
// `show_solids.dart`; a step key with no row at all leaves the plain drag of the worked example.

/// The sides of one picture in its own 100 by 100 units, from `outlines.json` (`tools/make_show_art.py`).
class ShowOutline {
  const ShowOutline(this.sides, {this.gap});

  /// Each side as a polyline, in order (start at the top, clockwise).
  final List<List<Offset>> sides;

  /// The middle of the opening of an open figure, where the gap ring goes; null for a closed one.
  final Offset? gap;
}

/// What a solid has that the turn-round motion points at, in its picture's 100 by 100 units (`outlines.json`, kind `solid`): the point of a cone,
/// the top and the base of a cylinder as ellipses (centre x, centre y, radius x, radius y), the face of a box as a polygon.
class ShowSolid {
  const ShowSolid({this.point, this.top, this.base, this.face});

  final Offset? point;
  final List<double>? top;
  final List<double>? base;
  final List<Offset>? face;
}

/// The pictures a Show draws: the outlines, the host's pointer, the ant, the arrows, the sand tray and its prints, as the files hold them.
class ShowArt {
  const ShowArt({
    required this.outlines,
    required this.solids,
    required this.hand,
    required this.antA,
    required this.antB,
    required this.turnBack,
    required this.turnFront,
    required this.rotateCw,
    required this.rotateCcw,
    required this.sandTray,
    required this.prints,
  });

  final Map<String, ShowOutline> outlines;
  final Map<String, ShowSolid> solids;
  final String hand;
  final String antA;
  final String antB;

  /// The orbit arrow round a solid (the back half under it, the front half with the head over it), and the turn arrows of a piece.
  final String turnBack;
  final String turnFront;
  final String rotateCw;
  final String rotateCcw;

  /// The sand tray, and the print each kind of face leaves in it (`circle`, `rect`, `square`, `triangle`).
  final String sandTray;
  final Map<String, String> prints;

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
    const List<String> kinds = <String>['circle', 'rect', 'square', 'triangle'];
    final List<String> files = await Future.wait(<Future<String>>[
      b.loadString('assets/art/show/outlines.json'),
      b.loadString('assets/art/hosts/kubi_hand.svg'),
      for (final String f in <String>[
        'ant_a',
        'ant_b',
        'turn_back',
        'turn_front',
        'rotate_cw',
        'rotate_ccw',
        'sand_tray',
      ])
        b.loadString('assets/art/show/$f.svg'),
      for (final String k in kinds) b.loadString('assets/art/show/sand_print_$k.svg'),
    ]);
    return ShowArt(
      outlines: parseOutlines(files[0]),
      solids: parseSolids(files[0]),
      hand: files[1],
      antA: paint(files[2]),
      antB: paint(files[3]),
      turnBack: paint(files[4]),
      turnFront: paint(files[5]),
      rotateCw: paint(files[6]),
      rotateCcw: paint(files[7]),
      sandTray: files[8],
      prints: <String, String>{for (final (int i, String k) in kinds.indexed) k: files[9 + i]},
    );
  }

  static String _key(String asset) => asset.startsWith('asset:') ? asset.substring(6) : asset;

  /// The outline of the picture [asset] (`asset:shape_triangle_red`), or null for a picture the Show has no outline of.
  ShowOutline? of(String asset) => outlines[_key(asset)];

  /// What the solid [asset] has that a turn points at (a cone's point, a cylinder's circles, a box's face), or null for a picture that is no solid
  /// the files know (a ball has nothing to point at).
  ShowSolid? solidOf(String asset) => solids[_key(asset)];
}

/// Reads `outlines.json`: a picture is a polygon (`poly`), an open figure (`open`), a dome (`dome`), an ellipse or a line; a solid has no sides
/// here (see [parseSolids]).
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

/// Reads the solids of `outlines.json`: the point, the ellipses and the face of each.
Map<String, ShowSolid> parseSolids(String json) {
  final Map<String, Object?> doc = jsonDecode(json) as Map<String, Object?>;
  final Map<String, Object?> pictures = doc['pictures']! as Map<String, Object?>;
  Offset pt(Object? p) {
    final List<Object?> v = p! as List<Object?>;
    return Offset((v[0]! as num).toDouble(), (v[1]! as num).toDouble());
  }

  List<double>? ellipse(Object? o) =>
      o == null ? null : <double>[for (final Object? n in o as List<Object?>) (n! as num).toDouble()];
  return <String, ShowSolid>{
    for (final MapEntry<String, Object?> e in pictures.entries)
      if ((e.value! as Map<String, Object?>)['kind'] == 'solid')
        e.key: ShowSolid(
          point: (e.value! as Map<String, Object?>)['point'] == null
              ? null
              : pt((e.value! as Map<String, Object?>)['point']),
          top: ellipse((e.value! as Map<String, Object?>)['top']),
          base: ellipse((e.value! as Map<String, Object?>)['base']),
          face: (e.value! as Map<String, Object?>)['face'] == null
              ? null
              : <Offset>[
                  for (final Object? q in (e.value! as Map<String, Object?>)['face']! as List<Object?>) pt(q),
                ],
        ),
  };
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

  /// How the lifted thing is held (the solids' motions): turned by [spotTurn] radians (about its middle, or about its base for a sway), pressed
  /// flat by [spotSquash] (1 = as it is, about its base).
  double spotTurn = 0;
  bool turnAboutBase = false;
  double spotSquash = 1;

  /// The short speed lines behind a rolling ball (from, to), and how visible they are (1 to 0).
  final List<(Offset, Offset)> speed = <(Offset, Offset)>[];
  double speedAlpha = 0;

  /// The orbit arrow round a solid: its box, how visible its dotted back half is, and how far its front half has swept (0 to 1).
  Rect? orbitBox;
  double orbitBack = 0;
  double orbitSweep = 0;

  /// The sand tray (how far it has risen, 0 to 1), the print a face has left in it, and the sand grains of a press (position, progress 0 to 1).
  Rect? tray;
  double trayRise = 0;
  String? printSvg;
  Rect? printBox;
  double printAlpha = 0;
  final List<(Offset, double)> grains = <(Offset, double)>[];

  /// The ring of a press: where, and how far it has grown (0 to 1, fading as it grows).
  Offset? pressAt;
  double pressT = 0;

  /// The arrow that turns a piece in the shape builder: its box and the way it turns (clockwise or not).
  Rect? rotateBox;
  bool rotateClockwise = true;

  bool get active => spot != null || tip != null || veil > 0 || tray != null || lit.isNotEmpty;

  void clearMarks() {
    lit.clear();
    drawing = <Offset>[];
    badges.clear();
    gap = null;
    sticks.clear();
    tip = null;
    ant = null;
    speed.clear();
    speedAlpha = 0;
    orbitBox = null;
    orbitBack = 0;
    orbitSweep = 0;
    grains.clear();
    pressAt = null;
    rotateBox = null;
  }

  /// The tray and its print stay through the drop (they fade with the veil), so they are not part of [clearMarks].
  void clear() {
    clearMarks();
    spot = null;
    spotSvg = null;
    from = null;
    veil = 0;
    lift = 1;
    spotTurn = 0;
    turnAboutBase = false;
    spotSquash = 1;
    tray = null;
    trayRise = 0;
    printSvg = null;
    printBox = null;
    printAlpha = 0;
  }
}

/// The choreography of one Show step on a [session]'s stage: it moves the pointer, the ant and the marks of [marks] in time, through the
/// session's own timers (a session that is gone stops it).
class ShowDirector {
  ShowDirector(this.session, this.style, this.marks);

  final TemplateSession session;
  final ShowStyle style;
  final ShowMarks marks;

  /// The step keys this director draws along the sides of an outline; the solids' own (see [solidMotions]) are in `show_solids.dart`; any other
  /// leaves the worked example's plain drag.
  static const Set<String> motions = <String>{'trace', 'count', 'walk', 'sticks'};

  /// The step keys of the solids: a ball pushed and rolled, a block stacked, a solid turned round, a solid stamped in the sand.
  static const Set<String> solidMotions = <String>{'push', 'stack', 'turn', 'stamp'};

  int _ms(int fast, int slow) => style.slow ? slow : fast;

  /// The side of the square a lifted thing is held in: the stage's height less 20 on a phone, 36 on a tablet.
  static double spotSide(Size stage) => stage.height - (stage.height > 200 ? 36 : 20);

  /// The thing flies from its tile to the spot (450 ms, 350 for the older looks) and the veil comes over the bins.
  Future<void> lift({required Rect from, required Rect spot, required String svg}) async {
    marks
      ..spotTurn = 0
      ..spotSquash = 1
      ..turnAboutBase = false
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

  /// The thing goes to its bin [to], the marks go, and the veil lifts. The pointer drags it there; with [carried] it is already there (a ball that
  /// rolled in) and only the veil lifts. With [squash] it settles on landing (0.94, 120 ms). A sand tray and its print fade with the veil.
  Future<void> dropTo(Rect to, {bool carried = false, bool squash = false}) async {
    final Rect? from = marks.spot;
    if (from == null) return;
    marks.clearMarks();
    final double trayFrom = marks.trayRise;
    final double printFrom = marks.printAlpha;
    void fade(double t) {
      marks
        ..veil = 1 - t
        ..trayRise = trayFrom * (1 - t)
        ..printAlpha = printFrom * (1 - t);
    }

    if (!style.still) {
      await session.animate(Duration(milliseconds: carried ? 200 : _ms(450, 600)), (double t) {
        fade(t);
        if (!carried) {
          final double k = Curves.easeInOutCubic.transform(t);
          marks.spot = Rect.lerp(from, to, k);
          marks.tip = marks.spot!.center + Offset(0, marks.spot!.height / 2);
          marks.tipAngle = 0;
        }
        session.notify();
      });
      if (squash) {
        marks.tip = null;
        await session.animate(const Duration(milliseconds: 120), (double t) {
          marks.spotSquash = 1 - 0.06 * math.sin(math.pi * t);
          session.notify();
        });
      }
    }
    marks.clear();
    session.notify();
  }

  /// The pointer's angle at [tip] on a thing centred at [centre]: the leg points away from the middle of the thing, so it never lies across it,
  /// within the range of the design (-120 to +45 degrees, 0 = straight down). Where "away" is outside the range (the tip is above the middle, or
  /// at its upper left) the nearest end of the range round the circle is taken, not the nearest on the number line: a tip at the top of a shape
  /// gets the leg that reaches in from the host's side (-120), not the one that would lie across the shape (+45).
  ///
  /// A tip with little room above it ([above] under 60 points: a hole at the stage's top) holds the leg level (-90, in from the host's side) at the
  /// most, so that the leg is not cut off by the stage's top edge and only its nails show.
  static double angleAway(Offset tip, Offset centre, {double above = double.infinity}) {
    final double a = _away(tip, centre);
    return above < 60 && a < -math.pi / 2 ? -math.pi / 2 : a;
  }

  static double _away(Offset tip, Offset centre) {
    final Offset d = tip - centre;
    if (d.distanceSquared < 1) return 0;
    const double low = -120 * math.pi / 180;
    const double high = 45 * math.pi / 180;
    final double a = math.atan2(-d.dx, d.dy);
    if (a >= low && a <= high) return a;
    double gap(double to) {
      final double diff = (a - to).abs() % (2 * math.pi);
      return diff > math.pi ? 2 * math.pi - diff : diff;
    }

    return gap(low) <= gap(high) ? low : high;
  }

  /// Draws the motion of [step] on [outline], mapped into [box] (the picture's square on the stage). The pointer keeps clear of [around] (the middle
  /// of what the whole picture is: a builder's piece is one part of a house, and the leg must not lie across the house); it is the box's middle
  /// when null. Returns false when this director has no row for the step's key (nothing was drawn).
  Future<bool> motion(ShowStep step, ShowOutline outline, Rect box, {Offset? around}) async {
    final String? key = step.motion;
    if (key == null || !motions.contains(key)) return false;
    Offset map(Offset u) => box.topLeft + Offset(u.dx / 100 * box.width, u.dy / 100 * box.height);
    final List<List<Offset>> sides = <List<Offset>>[
      for (final List<Offset> side in outline.sides) <Offset>[for (final Offset p in side) map(p)],
    ];
    final Offset centre = around ?? box.center;
    final double k = marks.scale;
    final bool walk = key == 'walk';
    final bool open = outline.gap != null;
    final double speed = (style.slow ? 70 : 100) * k;
    for (final (int i, List<Offset> side) in sides.indexed) {
      final double length = pathLength(side);
      // A side takes 600 ms (900 for the youngest looks), but a step with many sides (a hexagon counted) is held to 4.2 seconds, so that three
      // such steps and the host's lines still fit the 25 seconds of a full Show (the least a side takes is 350 ms).
      final int dwell = key == 'count' ? _ms(300, 400) : 250;
      final int fitted = math.max(350, 4200 ~/ sides.length - dwell);
      final int ms = key == 'sticks'
          ? 200
          : walk
          ? math.max(300, (length / speed * 1000).round())
          : math.min(_ms(600, 900), fitted);
      if (style.still) {
        await session.pause(const Duration(milliseconds: 600));
      } else if (key != 'sticks') {
        // The tip goes to the start of the first side from below, then along every side at an even pace.
        marks.drawing = <Offset>[side.first];
        _place(walk, side.first, centre, side.first, side[1]);
        session.notify();
        await session.animate(Duration(milliseconds: ms), (double t) {
          final List<Offset> upto = upTo(side, t);
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
        ..tipAngle = angleAway(at, centre, above: at.dy)
        ..ant = null;
    }
  }

  /// The length of the polyline [side].
  static double pathLength(List<Offset> side) {
    double l = 0;
    for (int i = 1; i < side.length; i++) {
      l += (side[i] - side[i - 1]).distance;
    }
    return l;
  }

  /// The part of [side] up to [t] (0 to 1) of its length, ending at the exact point.
  static List<Offset> upTo(List<Offset> side, double t) {
    final double want = pathLength(side) * t;
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

/// The Show's layer over a stage: the veil, the sand tray and its print, the lifted thing with its orbit arrow, the marks, the ant and the host's
/// pointer. It draws only while a Show acts.
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
    final Rect? orbit = marks.orbitBox;
    final Rect? rotate = marks.rotateBox;
    return IgnorePointer(
      child: Stack(
        clipBehavior: Clip.none,
        children: <Widget>[
          if (marks.veil > 0)
            Positioned.fill(
              child: ColoredBox(color: TokenColors.paper.withValues(alpha: 0.5 * marks.veil)),
            ),
          if (marks.tray != null && marks.trayRise > 0)
            Positioned.fromRect(
              rect: marks.tray!.shift(Offset(0, 16 * k * (1 - marks.trayRise))),
              child: Opacity(opacity: marks.trayRise, child: PackSvg(style.art.sandTray)),
            ),
          if (marks.printSvg != null && marks.printBox != null && marks.printAlpha > 0)
            Positioned.fromRect(
              rect: marks.printBox!,
              child: Opacity(opacity: marks.printAlpha, child: PackSvg(marks.printSvg!)),
            ),
          if (orbit != null && marks.orbitBack > 0)
            Positioned.fromRect(
              rect: orbit,
              child: Opacity(opacity: 0.7 * marks.orbitBack, child: PackSvg(style.art.turnBack)),
            ),
          if (at != null && marks.spotSvg != null)
            Positioned.fromRect(
              rect: at,
              // Turned about its middle (a ball rolling, a piece turning) or about its base (a solid swaying); pressed flat about its base.
              child: Transform.rotate(
                angle: marks.spotTurn,
                alignment: marks.turnAboutBase ? Alignment.bottomCenter : Alignment.center,
                child: Transform.scale(
                  scaleY: marks.spotSquash,
                  alignment: Alignment.bottomCenter,
                  child: PackSvg(marks.spotSvg!),
                ),
              ),
            ),
          if (orbit != null && marks.orbitSweep > 0)
            // The front half of the arrow sweeps: it is shown from the end side to as far as it has gone (the files are drawn left to right).
            Positioned.fromRect(
              rect: orbit,
              child: ClipRect(clipper: _SweepClip(marks.orbitSweep), child: PackSvg(style.art.turnFront)),
            ),
          if (rotate != null)
            Positioned.fromRect(
              rect: rotate,
              child: PackSvg(marks.rotateClockwise ? style.art.rotateCw : style.art.rotateCcw),
            ),
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

/// Shows the left [fraction] of the box: the sweep of the orbit arrow, whose picture runs from its tail to its head left to right.
class _SweepClip extends CustomClipper<Rect> {
  _SweepClip(this.fraction);

  final double fraction;

  @override
  Rect getClip(Size size) => Rect.fromLTWH(0, 0, size.width * fraction, size.height);

  @override
  bool shouldReclip(covariant _SweepClip old) => old.fraction != fraction;
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
    // The speed lines behind a rolling ball, the grains of a press, the ring of a press.
    if (marks.speedAlpha > 0) {
      for (final (Offset from, Offset to) in marks.speed) {
        canvas.drawLine(
          from,
          to,
          Paint()
            ..color = style.deep.withValues(alpha: marks.speedAlpha)
            ..strokeWidth = 2.5 * k
            ..strokeCap = StrokeCap.round,
        );
      }
    }
    for (final (Offset from, double t) in marks.grains) {
      final double out = 10 * k * t;
      for (final int dir in <int>[-1, 0, 1]) {
        canvas.drawCircle(
          from + Offset(dir * out, -out * (dir == 0 ? 1.2 : 0.6)),
          1.8 * k,
          Paint()..color = const Color(0xFFC9A36A).withValues(alpha: 1 - t),
        );
      }
    }
    final Offset? press = marks.pressAt;
    if (press != null && marks.pressT < 1) {
      canvas.drawCircle(
        press,
        ((8 + 6 * marks.pressT) * k),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5 * k
          ..color = style.deep.withValues(alpha: 1 - marks.pressT),
      );
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
