import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../content/models.dart' show ShowStep;
import 'show_stage.dart';

// The host's hand with the solids and the shape builder's pieces (M11 Stage 2, docs/design/m11-rooms.md section 13.3): a ball is pushed and rolls to
// its bin, a block is pushed and stacked on the bin's sample, a solid is turned round (the orbit arrow) and pointed at where it differs, a solid
// is pressed into a tray of sand and leaves its print, and a piece of a picture turns to its place under the turn arrow. The pictures are the
// design-director's (`app/assets/art/show/`); this is the choreography, on the same layer as the trace and the ant (`show_stage.dart`).

/// How the session finishes a Show step after its motion: the thing goes to [to] (the pointer drags it there), or it has already gone ([carried]: a
/// ball that rolled in), and it settles with a squash on landing ([squash]).
typedef SolidEnd = ({Rect to, bool carried, bool squash});

/// A thing that rolls: a ball or a sphere.
bool rollsLike(String sprite) => sprite.contains('ball') || sprite.contains('sphere');

/// The print a solid leaves in sand, as the kind of the face it presses (circle: a cylinder, a cone, a can, a hat; rect: a box, a gift box; square: a
/// dice, a pyramid's base; triangle: a pyramid on its side), or null for a picture that leaves no mark in sand (the motion then falls back to the plain drag).
String? printKindOf(String sprite, {String? detail}) {
  final String id = sprite.startsWith('asset:') ? sprite.substring(6) : sprite;
  if (id.contains('gift') || id.contains('solid_box')) return 'rect';
  // a pyramid stands on its square base, or lies on its side (the step's detail) and then prints its triangle
  if (id.contains('pyramid')) return detail == 'side' ? 'triangle' : 'square';
  if (id.contains('dice')) return 'square';
  final bool round =
      id.contains('cylinder') || id.contains('cone') || id.contains('party_hat') || id == 'can';
  return round ? 'circle' : null;
}

extension SolidMotions on ShowDirector {
  int _pace(int fast, int slow) => style.slow ? slow : fast;

  /// Does [step]'s motion for [sprite] (a thing of the lifted spot) and says how the session finishes the step; null when there is no row for it (a
  /// stamp of a picture that leaves no print): the session then does the plain drag. [into] is the small box in the bin the thing goes to, [onto] the one at
  /// the bin's sample picture, [stage] the stage's size.
  Future<SolidEnd?> solid(
    ShowStep step, {
    required String sprite,
    required Rect spot,
    required Rect into,
    required Rect onto,
    required Size stage,
  }) async => switch (step.motion) {
    'push' => _push(sprite, spot, into),
    'stack' => _stack(spot, onto),
    'turn' => _turn(sprite, spot, into),
    'stamp' =>
      printKindOf(sprite, detail: step.detail) == null
          ? null
          : _stamp(sprite, spot, into, stage, step.detail),
    _ => null,
  };

  /// The pointer glides to [tip] from below and holds the leg at [angle] (350 ms, 450 for the youngest looks).
  Future<void> _glideTo(Offset tip, double angle) async {
    final Offset start = tip + Offset(0, 50 * marks.scale);
    marks
      ..tip = start
      ..tipAngle = angle;
    session.notify();
    await session.animate(Duration(milliseconds: _pace(350, 450)), (double t) {
      marks.tip = Offset.lerp(start, tip, Curves.easeOutCubic.transform(t));
      session.notify();
    });
  }

  /// A press: the pointer goes [shift] further for 120 ms and a ring grows and fades round the touch (300 ms).
  Future<void> _press(Offset at, Offset shift) async {
    final Offset? from = marks.tip;
    marks.pressAt = at;
    await session.animate(const Duration(milliseconds: 300), (double t) {
      marks.pressT = t;
      if (from != null) marks.tip = from + shift * math.sin(math.pi * math.min(1, t / 0.4));
      session.notify();
    });
    marks
      ..pressAt = null
      ..pressT = 0
      ..tip = from;
  }

  Future<SolidEnd> _push(String sprite, Rect spot, Rect into) async {
    final bool ball = rollsLike(sprite);
    final double k = marks.scale;
    if (style.still) {
      marks.spot = ball ? into : spot;
      session.notify();
      await session.pause(const Duration(milliseconds: 600));
      return (to: into, carried: ball, squash: false);
    }
    // The pointer stands behind the thing at its end side (the left) and presses toward the start side, where the first bin is.
    final Offset behind = Offset(spot.left + spot.width * 0.1, spot.center.dy + spot.height * 0.2);
    await _glideTo(behind, 45 * math.pi / 180);
    await _press(behind, Offset(5 * k, 0));
    if (!ball) {
      // A block shifts 3 points and back with a wobble (two cycles of 3 degrees, 360 ms) and stays.
      await session.animate(const Duration(milliseconds: 360), (double t) {
        marks
          ..spotTurn = math.sin(t * 4 * math.pi) * 3 * math.pi / 180
          ..spot = spot.shift(Offset(3 * k * math.sin(math.pi * t), 0));
        session.notify();
      });
      marks
        ..spotTurn = 0
        ..spot = spot
        ..tip = null;
      session.notify();
      return (to: into, carried: false, squash: false);
    }
    marks.tip = null;
    // The ball rolls to its bin on a low arc, turning as far as it goes (the angle is the distance over the radius), three short speed lines
    // behind it fading as it goes (700 ms, ease-out).
    final double distance = (into.center - spot.center).distance;
    final double sign = into.center.dx >= spot.center.dx ? 1 : -1;
    final double radius = spot.width * 0.38;
    await session.animate(const Duration(milliseconds: 700), (double t) {
      final double e = Curves.easeOut.transform(t);
      final Offset c = Offset.lerp(spot.center, into.center, e)! - Offset(0, 10 * k * math.sin(math.pi * e));
      final double w = spot.width + (into.width - spot.width) * e;
      marks
        ..spot = Rect.fromCenter(center: c, width: w, height: w)
        ..spotTurn = sign * distance * e / radius;
      marks.speed.clear();
      for (int i = 0; i < 3; i++) {
        final Offset back = c - Offset(sign * (w * 0.5 + 4 * k), (i - 1) * 7 * k);
        marks.speed.add((back, back - Offset(sign * 12 * k, 0)));
      }
      marks.speedAlpha = (1 - t).clamp(0.0, 1.0);
      session.notify();
    });
    marks.speed.clear();
    return (to: into, carried: true, squash: false);
  }

  Future<SolidEnd> _stack(Rect spot, Rect onto) async {
    if (!style.still) await _glideTo(Offset(spot.center.dx, spot.bottom - 6 * marks.scale), 0);
    return (to: onto, carried: false, squash: true);
  }

  Future<SolidEnd> _turn(String sprite, Rect spot, Rect into) async {
    final double w = spot.width * 1.28;
    final Rect box = Rect.fromCenter(center: spot.center, width: w, height: w * 44 / 120);
    final ShowSolid? solid = style.art.solidOf(sprite);
    Offset map(Offset u) => spot.topLeft + Offset(u.dx / 100 * spot.width, u.dy / 100 * spot.height);
    marks.orbitBox = box;
    if (style.still) {
      marks
        ..orbitBack = 1
        ..orbitSweep = 1;
      session.notify();
    } else {
      await session.animate(const Duration(milliseconds: 200), (double t) {
        marks.orbitBack = t;
        session.notify();
      });
      // The front half sweeps twice round the waist while the thing sways about its base (4 degrees, 900 ms).
      marks.turnAboutBase = true;
      for (int round = 0; round < 2; round++) {
        await session.animate(const Duration(milliseconds: 900), (double t) {
          marks
            ..orbitSweep = Curves.easeInOut.transform(t)
            ..spotTurn = round == 0 ? math.sin(t * 2 * math.pi) * 4 * math.pi / 180 : 0;
          session.notify();
        });
      }
      marks
        ..spotTurn = 0
        ..turnAboutBase = false;
    }
    // Then what the solid has: a cone's one point, a cylinder's top circle and the front of its base, a box's face.
    if (solid != null) {
      final List<double>? top = solid.top;
      final List<double>? base = solid.base;
      if (solid.point != null) {
        marks.gap = map(solid.point!);
        session.notify();
        await session.pause(const Duration(milliseconds: 700));
      } else if (top != null) {
        await drawPath(
          <Offset>[for (final Offset p in _ellipse(top, 0, 2 * math.pi)) map(p)],
          ms: 600,
          around: spot.center,
        );
        if (base != null) {
          await drawPath(
            <Offset>[for (final Offset p in _ellipse(base, math.pi, 0)) map(p)],
            ms: 400,
            around: spot.center,
          );
        }
      } else if (solid.face != null) {
        final List<Offset> face = <Offset>[...solid.face!, solid.face!.first];
        await drawPath(<Offset>[for (final Offset p in face) map(p)], ms: 700, around: spot.center);
      }
    }
    marks.tip = null;
    session.notify();
    return (to: into, carried: false, squash: false);
  }

  /// The points of the ellipse [e] (centre x, centre y, radius x, radius y) from angle [from] to [to] (0 at the right, a quarter turn at the bottom).
  List<Offset> _ellipse(List<double> e, double from, double to) => <Offset>[
    for (int i = 0; i <= 36; i++)
      Offset(
        e[0] + e[2] * math.cos(from + (to - from) * i / 36),
        e[1] + e[3] * math.sin(from + (to - from) * i / 36),
      ),
  ];

  /// The pointer draws [path] (stage points) in [ms], the line staying lit behind it; the leg keeps clear of [around]. With reduced movement the
  /// line is there at once.
  Future<void> drawPath(List<Offset> path, {required int ms, required Offset around}) async {
    if (path.length < 2) return;
    if (!style.still) {
      await session.animate(Duration(milliseconds: ms), (double t) {
        final List<Offset> upto = ShowDirector.upTo(path, t);
        marks
          ..drawing = upto
          ..tip = upto.last
          ..tipAngle = ShowDirector.angleAway(upto.last, around, above: upto.last.dy);
        session.notify();
      });
    }
    marks
      ..lit.add(path)
      ..drawing = <Offset>[]
      ..tip = null;
    session.notify();
  }

  Future<SolidEnd> _stamp(String sprite, Rect spot, Rect into, Size stage, String? detail) async {
    final String kind = printKindOf(sprite, detail: detail)!;
    final double k = marks.scale;
    final double side = spot.width;
    // The tray stands in the lower part of the stage, the print is in its middle, the solid hovers over it (half the lifted size).
    final double trayWidth = math.min(1.7 * side, stage.width * 0.62);
    final double trayHeight = trayWidth * 0.6;
    final Rect tray = Rect.fromCenter(
      center: Offset(stage.width / 2, stage.height - trayHeight / 2 - 4 * k),
      width: trayWidth,
      height: trayHeight,
    );
    final Rect printBox = Rect.fromCenter(
      center: tray.center + Offset(0, 0.04 * trayHeight),
      width: 0.42 * side,
      height: 0.42 * side,
    );
    final double size = 0.5 * side;
    final Rect hover = Rect.fromCenter(
      center: Offset(tray.center.dx, printBox.center.dy - size / 2 - 8 * k),
      width: size,
      height: size,
    );
    final Rect aside = Rect.fromCenter(
      center: Offset(tray.left + size / 2 + 12 * k, tray.center.dy - 4 * k),
      width: size,
      height: size,
    );
    final ShowOutline? outline = style.art.of('shape_$kind');
    List<Offset> printPath() => <Offset>[
      if (outline != null)
        for (final List<Offset> side in outline.sides)
          for (final Offset p in side)
            printBox.topLeft + Offset(p.dx / 100 * printBox.width, p.dy / 100 * printBox.height),
    ];
    marks
      ..tray = tray
      ..printSvg = style.art.prints[kind]
      ..printBox = printBox;

    if (style.still) {
      marks
        ..trayRise = 1
        ..printAlpha = 1
        ..spot = aside;
      if (outline != null) marks.lit.add(printPath());
      session.notify();
      await session.pause(const Duration(milliseconds: 800));
      return (to: into, carried: false, squash: false);
    }

    Future<void> moveSpot(Rect to, int ms, Curve curve) {
      final Rect from = marks.spot!;
      return session.animate(Duration(milliseconds: ms), (double t) {
        marks
          ..spot = Rect.lerp(from, to, curve.transform(t))
          ..tip = marks.spot!.bottomCenter - Offset(0, 4 * k)
          ..tipAngle = 0;
        session.notify();
      });
    }

    await session.animate(const Duration(milliseconds: 450), (double t) {
      marks.trayRise = t;
      session.notify();
    });
    await moveSpot(hover, 450, Curves.easeInOutCubic);
    // The press: down 10 points and a little more into the sand, flattened a little, three grains puffing out (300 ms).
    final Rect pressed = hover.shift(Offset(0, 18 * k));
    await moveSpot(pressed, 300, Curves.easeIn);
    final Offset puff = printBox.center + Offset(0, printBox.height * 0.45);
    marks
      ..spotSquash = 0.96
      ..grains.add((puff, 0));
    session.notify();
    await session.pause(const Duration(milliseconds: 120));
    // It lifts 24 points and goes aside while the print fades in; the grains settle.
    marks.spotSquash = 1;
    await Future.wait(<Future<void>>[
      moveSpot(pressed.shift(Offset(0, -24 * k)), 350, Curves.easeOut),
      session.animate(const Duration(milliseconds: 150), (double t) {
        marks.printAlpha = t;
        session.notify();
      }),
      session.animate(const Duration(milliseconds: 300), (double t) {
        marks.grains
          ..clear()
          ..add((puff, t));
        session.notify();
      }),
    ]);
    marks.grains.clear();
    await moveSpot(aside, 350, Curves.easeInOut);
    marks.tip = null;
    // The print is traced.
    if (outline != null) {
      await drawPath(printPath(), ms: 600, around: printBox.center);
    }
    await session.pause(const Duration(milliseconds: 300));
    return (to: into, carried: false, squash: false);
  }

  /// A piece of a picture turns to the angle of its place under the turn arrow: the piece [svg] stands in [place] (turned 0), the arrow comes
  /// (150 ms) and the piece turns [degrees] (600 ms); with reduced movement it is there turned. The caller fills the place afterwards, which
  /// takes the piece and the arrow away ([ShowMarks.clear]).
  Future<void> turnPiece({required Rect place, required String svg, required double degrees}) async {
    final double side = math.max(place.width, place.height) * 1.3;
    marks
      ..spot = place
      ..spotSvg = svg
      ..from = null
      ..lift = 1
      ..rotateBox = Rect.fromCenter(center: place.center, width: side, height: side)
      ..rotateClockwise = degrees > 0
      ..spotTurn = style.still ? degrees * math.pi / 180 : 0;
    session.notify();
    if (style.still) {
      await session.pause(const Duration(milliseconds: 120));
      return;
    }
    await session.pause(const Duration(milliseconds: 150));
    await session.animate(const Duration(milliseconds: 600), (double t) {
      marks.spotTurn = Curves.easeInOut.transform(t) * degrees * math.pi / 180;
      session.notify();
    });
  }
}
