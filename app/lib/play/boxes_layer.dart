import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../child/activity_shell.dart';
import '../content/models.dart';
import '../design/board.dart' show BoardClass, BoardSvg;
import '../design/components.dart';
import '../design/token_types.dart' show Band;
import '../design/tokens.g.dart';
import '../strings/he.dart';
import 'boxes_session.dart';
import 'hints/hint_pictures.dart' show Appear, SkyRing;
import 'l5_art.dart';
import 'ls01_hand.dart';
import 'template_session.dart' show PackSvg;

// What LS03 `boxes` draws on the board, in board points (docs/design/l5-templates.md sections 2.2, 3.1 and 3.6): the stage's picture, bowl and "that's all", the
// stamps and the sound to find, the rail of places in the answer zone, the cards of the hints and the friend's hand. Drawn for a course that reads left to right
// and mirrored inside its zone for one that reads right to left.

/// How many places the rail has: Band A 5, Band B 6, Band C 7, and always one more than the word has units, so that "one more" can be laid.
int railPlacesFor(Band band, int count) => math.max(switch (band) {
  Band.a => 5,
  Band.b => 6,
  Band.c => 7,
}, count + 1);

/// Where everything stands on one board, one band and one course direction.
class BoxesGeometry {
  BoxesGeometry._({
    required this.board,
    required this.sMap,
    required this.aMap,
    required this.s,
    required this.zoneS,
    required this.zoneA,
    required this.places,
    required this.placeW,
    required this.placeH,
    required this.gap,
    required this.railX,
    required this.railY,
    required this.token,
  });

  factory BoxesGeometry.of(BoardClass board, ActivitySpec spec, Band band, TextDirection dir, int places) {
    final bool mirror = dir == TextDirection.rtl;
    final Rect zoneS = spec.stageIsCard ? spec.stage.deflate(16) : spec.stage;
    final Rect zoneA = Rect.fromLTWH(spec.tilesLeft, spec.tilesTop - 12, spec.tilesWidth, 120);
    // The nominal place of the band, and then the largest that fits the answer zone with this many places.
    final ({double w, double h, double gap, double token}) nominal = switch (board) {
      BoardClass.phone => switch (band) {
        Band.a => (w: 88, h: 96, gap: 12, token: 72),
        Band.b => (w: 80, h: 88, gap: 12, token: 64),
        Band.c => (w: 72, h: 80, gap: 8, token: 52),
      },
      BoardClass.phoneSE => switch (band) {
        Band.a => (w: 88, h: 96, gap: 8, token: 72),
        Band.b => (w: 72, h: 88, gap: 8, token: 56),
        Band.c => (w: 64, h: 80, gap: 6, token: 52),
      },
      BoardClass.tabletLandscape => (w: 104, h: 104, gap: 16, token: 88),
      BoardClass.tabletPortrait => (w: 112, h: 112, gap: 16, token: 96),
    };
    double w = nominal.w;
    double h = nominal.h;
    double token = nominal.token;
    final double room = spec.tilesWidth;
    if (places * w + (places - 1) * nominal.gap > room) {
      w = ((room - (places - 1) * nominal.gap) / places).floorToDouble();
      h = math.min(h, w + 8);
      token = math.min(token, w - 16);
    }
    final double total = places * w + (places - 1) * nominal.gap;
    final double y = switch (board) {
      BoardClass.tabletLandscape => 566,
      BoardClass.tabletPortrait => 700,
      _ => spec.tilesTop,
    };
    return BoxesGeometry._(
      board: board,
      sMap: ZoneMap(zoneS, mirror: mirror),
      aMap: ZoneMap(zoneA, mirror: mirror),
      s: BoxesStagePlaces.of(board),
      zoneS: zoneS,
      zoneA: zoneA,
      places: places,
      placeW: w,
      placeH: h,
      gap: nominal.gap,
      railX: zoneA.left + (zoneA.width - total) / 2,
      railY: y,
      token: token,
    );
  }

  final BoardClass board;
  final ZoneMap sMap;
  final ZoneMap aMap;
  final BoxesStagePlaces s;
  final Rect zoneS;
  final Rect zoneA;
  final int places;
  final double placeW;
  final double placeH;
  final double gap;
  final double railX;
  final double railY;
  final double token;

  bool get tablet => board == BoardClass.tabletLandscape || board == BoardClass.tabletPortrait;

  Rect picture({bool small = false}) =>
      sMap.at(small && s.pictureSmall != null ? s.pictureSmall! : s.picture);
  Rect get bowl => sMap.at(s.bowl);
  Rect get done => sMap.at(s.done);
  Rect get sound => sMap.at(s.done);
  Rect stamp(int i) =>
      sMap.at(Rect.fromLTWH(s.stampX + i * (s.stampSize + s.stampGap), s.stampY, s.stampSize, s.stampSize));

  /// Place [i] of the rail, counted from the course's start.
  Rect place(int i) => aMap.at(Rect.fromLTWH(railX + i * (placeW + gap), railY, placeW, placeH));

  /// The whole rail, behind its places.
  Rect get rail {
    final Rect a = place(0);
    final Rect b = place(places - 1);
    return Rect.fromLTRB(
      math.min(a.left, b.left) - 8,
      a.top - 8,
      math.max(a.right, b.right) + 8,
      a.bottom + 8,
    );
  }

  /// A place and the room around it that still counts as touching it: half the gap beside it, 12 above and below.
  Rect hit(int i) {
    final Rect r = place(i);
    return Rect.fromLTRB(r.left - gap / 2, r.top - 12, r.right + gap / 2, r.bottom + 12);
  }
}

class BoxesStagePlaces {
  const BoxesStagePlaces({
    required this.picture,
    this.pictureSmall,
    required this.bowl,
    required this.done,
    required this.stampX,
    required this.stampY,
    required this.stampSize,
    required this.stampGap,
  });

  final Rect picture;
  final Rect? pictureSmall;
  final Rect bowl;
  final Rect done;
  final double stampX;
  final double stampY;
  final double stampSize;
  final double stampGap;

  static BoxesStagePlaces of(BoardClass b) => switch (b) {
    BoardClass.phone => const BoxesStagePlaces(
      picture: Rect.fromLTWH(30, 110, 120, 120),
      bowl: Rect.fromLTWH(211, 122, 96, 96),
      done: Rect.fromLTWH(323, 134, 72, 72),
      stampX: 171,
      stampY: 138,
      stampSize: 64,
      stampGap: 16,
    ),
    BoardClass.phoneSE => const BoxesStagePlaces(
      picture: Rect.fromLTWH(30, 114, 88, 88),
      pictureSmall: Rect.fromLTWH(30, 130, 56, 56),
      bowl: Rect.fromLTWH(126, 118, 80, 80),
      done: Rect.fromLTWH(216, 126, 64, 64),
      stampX: 96,
      stampY: 130,
      stampSize: 56,
      stampGap: 8,
    ),
    BoardClass.tabletLandscape => const BoxesStagePlaces(
      picture: Rect.fromLTWH(304, 280, 200, 200),
      bowl: Rect.fromLTWH(596, 310, 140, 140),
      done: Rect.fromLTWH(760, 332, 96, 96),
      stampX: 544,
      stampY: 336,
      stampSize: 88,
      stampGap: 24,
    ),
    BoardClass.tabletPortrait => const BoxesStagePlaces(
      picture: Rect.fromLTWH(40, 412, 220, 220),
      bowl: Rect.fromLTWH(492, 442, 160, 160),
      done: Rect.fromLTWH(684, 450, 96, 96),
      stampX: 428,
      stampY: 474,
      stampSize: 96,
      stampGap: 32,
    ),
  };
}

/// The layer of the boxes template: everything the child touches, in board points.
class BoxesLayer extends StatelessWidget {
  const BoxesLayer({super.key, required this.session, required this.spec, required this.board});

  final BoxesSession session;
  final ActivitySpec spec;
  final BoardClass board;

  @override
  Widget build(BuildContext context) {
    final BoxesSession s = session;
    final BoxesActivity a = s.a;
    final BoxesGeometry g = BoxesGeometry.of(board, spec, s.band, s.direction, s.railPlaces);
    final bool colouring = s.step == BoxStep.colour && !s.allDone;
    final bool counting = s.step == BoxStep.count && !s.allDone;
    final bool finding = s.step == BoxStep.which && !s.allDone;
    final bool rtl = s.direction == TextDirection.rtl;
    final Rect pic = g.picture(small: colouring && g.board == BoardClass.phoneSE);
    return Positioned.fill(
      child: Stack(
        clipBehavior: Clip.none,
        children: <Widget>[
          // The picture of the word, always on the stage: a touch says the word again.
          Positioned.fromRect(
            rect: pic,
            child: _PictureCard(
              key: const Key('box-picture'),
              svg: a.assets.svg(a.picture),
              lit: s.pictureLit,
              rtl: rtl,
              onTap: s.replayWord,
            ),
          ),
          if (counting) ...<Widget>[
            Positioned.fromRect(
              rect: g.bowl,
              child: _Bowl(session: s),
            ),
            // The disc is the spec's size; the touch reaches 12 points beyond it.
            Positioned.fromRect(
              rect: g.done.inflate(12),
              child: PebbleButton(
                key: const Key('box-done'),
                semanticLabel: He.drumDoneSemantics.text,
                size: g.done.width,
                onPressed: s.laid == 0 ? null : s.done,
                child: const Icon(Icons.check_rounded, size: 40, color: TokenColors.ink),
              ),
            ),
          ],
          if (colouring)
            for (final SchemeKind k in SchemeKind.values)
              Positioned.fromRect(
                rect: g.stamp(k.index),
                child: _Stamp(session: s, kind: k, size: g.stamp(k.index).width),
              ),
          if (finding)
            Positioned.fromRect(
              rect: g.sound.inflate(12),
              child: _SoundPebble(session: s, lit: s.soundLit),
            ),
          // The rail: the groove, a place for each counter laid and the dashed one for the next.
          Positioned.fromRect(
            rect: g.rail,
            child: DragTarget<int>(
              onAcceptWithDetails: (DragTargetDetails<int> _) => s.lay(),
              builder: (BuildContext c, List<int?> hovering, List<dynamic> rejected) => DecoratedBox(
                key: const Key('box-rail'),
                decoration: BoxDecoration(
                  color: hovering.isEmpty ? TokenColors.mist : TokenColors.mist.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
            ),
          ),
          if (counting && s.laid < s.railPlaces)
            Positioned.fromRect(
              rect: g.place(s.laid),
              child: GestureDetector(
                key: const Key('box-next'),
                behavior: HitTestBehavior.opaque,
                onTap: s.lay,
                child: const DashedRRect(fill: Color(0x80FFFFFF)),
              ),
            ),
          for (int i = 0; i < s.laid; i++) _place(g, s, i),
          if (s.stressAt != null) _stress(g, s),
          if (s.card != null)
            Positioned.fromRect(
              rect: g.zoneS.deflate(4),
              child: _HintCard(session: s, geometry: g),
            ),
          ?ls01HandLayer(s.handTip, spec),
        ],
      ),
    );
  }

  Widget _place(BoxesGeometry g, BoxesSession s, int i) {
    final BoxesActivity a = s.a;
    final SchemeKind? colour = s.chipColour(i);
    final bool stressing = s.step == BoxStep.stress && !s.allDone;
    final bool raised = stressing && a.units[i].vowel;
    final bool dim = stressing && !a.units[i].vowel;
    final bool lit = s.lights.contains(i) || s.heard.contains(i);
    final bool right = s.state == AnswerState.correct;
    final bool chosen = s.chipChosen == i || (s.step == BoxStep.which && s.whichAt == i + 1);
    final bool bad =
        s.notYet.contains(i) ||
        (s.state == AnswerState.notYet && s.step == BoxStep.which && s.whichAt == i + 1);
    final Rect r = g.place(i);
    final Rect hit = g.hit(i);
    final Widget token = colour == null
        ? CounterDisc(size: g.token, lifted: raised)
        : SchemeChip(colour, size: g.token, lifted: raised, dim: dim);
    final bool wobbling =
        s.wobble &&
        (s.step != BoxStep.colour || s.notYet.contains(i)) &&
        (s.step != BoxStep.which || s.whichAt == i + 1 || s.step == BoxStep.count);
    return Positioned.fromRect(
      rect: hit,
      child: Semantics(
        button: true,
        label: He.boxPlaceSemantics.text,
        child: GestureDetector(
          key: Key('box-place-$i'),
          behavior: HitTestBehavior.opaque,
          onTap: () => s.tapChip(i),
          child: Wobble(
            on: wobbling,
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: <Widget>[
                Positioned.fromRect(
                  rect: r.shift(-hit.topLeft),
                  child: Container(
                    decoration: BoxDecoration(
                      color: right ? TokenColors.sparkTint : Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: bad
                            ? TokenColors.notYetRing
                            : chosen
                            ? TokenColors.selectedRing
                            : right
                            ? TokenColors.correctGlow
                            : TokenColors.hairline,
                        width: bad || chosen || right ? 4 : 4,
                      ),
                      boxShadow: clayShadows(TokenColors.cardLip, lipHeight: 4),
                    ),
                  ),
                ),
                Positioned(
                  left: r.center.dx - hit.left - g.token / 2,
                  top: r.center.dy - hit.top - g.token / 2 - (raised ? 5 : 0),
                  width: g.token,
                  height: g.token,
                  // A counter that is laid comes in with a small grow and fade (a fade in place with reduce-motion).
                  child: Appear(
                    scaleFrom: 0.5,
                    child: Opacity(opacity: dim ? 0.4 : 1, child: token),
                  ),
                ),
                if (lit)
                  Positioned.fromRect(
                    rect: r.shift(-hit.topLeft).inflate(6),
                    child: const IgnorePointer(child: SkyRing(round: false, radius: 26)),
                  ),
                if (right && i == s.laid - 1)
                  Positioned(
                    left: r.right - hit.left - 22,
                    top: r.top - hit.top - 10,
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: const BoxDecoration(color: TokenColors.correctGlow, shape: BoxShape.circle),
                      child: const Icon(Icons.check_rounded, size: 20, color: TokenColors.ink),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _stress(BoxesGeometry g, BoxesSession s) {
    final Rect r = g.place(s.stressAt! - 1);
    return Positioned(
      left: r.center.dx - 12,
      top: r.top - 26,
      child: const IgnorePointer(child: StressSign(key: Key('box-stress'), height: 22)),
    );
  }
}

/// The word's picture on a white card with a speaker badge at its end corner; a touch says the word again.
class _PictureCard extends StatelessWidget {
  const _PictureCard({
    super.key,
    required this.svg,
    required this.lit,
    required this.rtl,
    required this.onTap,
  });

  final String svg;
  final bool lit;
  final bool rtl;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: He.replaySemantics.text,
    child: GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: <Widget>[
          Positioned.fill(
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: TokenColors.paper,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: TokenColors.hairline, width: 3),
                boxShadow: clayShadows(TokenColors.cardLip, lipHeight: 5),
              ),
              child: PackSvg(svg),
            ),
          ),
          if (lit) const Positioned.fill(child: IgnorePointer(child: SkyRing(round: false, radius: 22))),
          Positioned(
            right: rtl ? null : -6,
            left: rtl ? -6 : null,
            bottom: -6,
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: TokenColors.skyTint,
                shape: BoxShape.circle,
                border: Border.all(color: TokenColors.hairline, width: 2),
              ),
              child: const Icon(Icons.volume_up_rounded, size: 18, color: TokenColors.ink),
            ),
          ),
        ],
      ),
    ),
  );
}

/// The bowl of counters: a tap sends one to the next place, a drag takes one out and a drop on the rail lands it.
class _Bowl extends StatelessWidget {
  const _Bowl({required this.session});

  final BoxesSession session;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (BuildContext c, BoxConstraints box) => Semantics(
      button: true,
      label: He.boxBowlSemantics.text,
      child: Draggable<int>(
        data: 0,
        maxSimultaneousDrags: 1,
        feedback: Transform.translate(
          offset: Offset(-box.maxWidth * 0.3, -box.maxWidth * 0.3),
          child: CounterDisc(size: box.maxWidth * 0.5),
        ),
        childWhenDragging: BowlArt(size: box.maxWidth),
        child: GestureDetector(
          key: const Key('box-bowl'),
          behavior: HitTestBehavior.opaque,
          onTap: session.lay,
          child: BowlArt(size: box.maxWidth),
        ),
      ),
    ),
  );
}

/// A stamp of the colour step: tap it, then tap chips; or tap a chip, then a stamp.
class _Stamp extends StatelessWidget {
  const _Stamp({required this.session, required this.kind, required this.size});

  final BoxesSession session;
  final SchemeKind kind;
  final double size;

  @override
  Widget build(BuildContext context) {
    final bool chosen = session.stampChosen == kind;
    return Semantics(
      button: true,
      label: switch (kind) {
        SchemeKind.vowel => He.boxStampVowelSemantics.text,
        SchemeKind.hard => He.boxStampHardSemantics.text,
        SchemeKind.soft => He.boxStampSoftSemantics.text,
      },
      child: GestureDetector(
        key: Key('stamp-${kind.letter}'),
        behavior: HitTestBehavior.opaque,
        onTap: () => session.tapStamp(kind),
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: <Widget>[
            if (chosen)
              Positioned(
                left: -5,
                top: -11,
                width: size + 10,
                height: size + 10,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: TokenColors.selectedRing, width: 4),
                  ),
                ),
              ),
            Positioned(
              left: 0,
              top: chosen ? -6 : 0,
              child: SchemeChip(kind, size: size, lifted: chosen),
            ),
          ],
        ),
      ),
    );
  }
}

/// The sound to find (the which step): a touch plays it again.
class _SoundPebble extends StatelessWidget {
  const _SoundPebble({required this.session, required this.lit});

  final BoxesSession session;
  final bool lit;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (BuildContext c, BoxConstraints box) {
      // The box is the disc and the 12 points of touch round it.
      final double disc = box.maxWidth - 24;
      return Stack(
        clipBehavior: Clip.none,
        children: <Widget>[
          if (lit)
            Positioned(
              left: 4,
              top: 4,
              width: disc + 16,
              height: disc + 16,
              child: const IgnorePointer(child: SkyRing(key: Key('box-sound-glow'))),
            ),
          PebbleButton(
            key: const Key('box-sound'),
            semanticLabel: He.boxSoundSemantics.text,
            size: disc,
            fill: TokenColors.skyTint,
            lip: TokenColors.skyDeep,
            onPressed: session.replayWhich,
            child: Icon(Icons.volume_up_rounded, size: disc * 0.5, color: TokenColors.ink),
          ),
        ],
      );
    },
  );
}

/// The card of a hint over the stage: a card for each unit (claps or the mouth of a sound), the three tests of the colours, or the friend calling from
/// far. It stands over the stage only while it plays.
class _HintCard extends StatelessWidget {
  const _HintCard({required this.session, required this.geometry});

  final BoxesSession session;
  final BoxesGeometry geometry;

  @override
  Widget build(BuildContext context) {
    final BoxesSession s = session;
    final Widget body = switch (s.card) {
      'claps' || 'mouths' => _units(s),
      'sing' => _tests(),
      _ => _call(),
    };
    return IgnorePointer(
      child: SkyCard(
        key: Key('box-card-${s.card}'),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Center(child: body),
        ),
      ),
    );
  }

  Widget _units(BoxesSession s) {
    final int n = s.a.units.length;
    final double w = geometry.zoneS.width - 32;
    final double side = math.min(math.min(110, (w - (n - 1) * 8) / n), geometry.zoneS.height - 40);
    return Row(
      mainAxisSize: MainAxisSize.min,
      textDirection: s.direction,
      children: <Widget>[
        for (int i = 0; i < n; i++)
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: Container(
              key: Key('box-unit-card-$i'),
              width: side,
              height: side,
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: TokenColors.paper,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: s.cardLit == i ? TokenColors.skyDeep : TokenColors.hairline,
                  width: s.cardLit == i ? 4 : 2,
                ),
              ),
              child: s.card == 'claps'
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const <Widget>[
                        Expanded(child: BoardSvg('assets/art/hints/hand_left_5.svg')),
                        Expanded(child: BoardSvg('assets/art/hints/hand_right_5.svg')),
                      ],
                    )
                  : (s.a.units[i].mouth != null
                        ? PackSvg(s.a.assets.svg(s.a.units[i].mouth!))
                        : Center(child: CounterDisc(size: side * 0.6))),
            ),
          ),
      ],
    );
  }

  /// "Can you sing it?": a sound you can sing is a note, a hard one stops the air (the block), a soft one smiles. The tests, drawn the same for every item.
  Widget _tests() => Row(
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      for (final (SchemeKind k, _Mouth m) in <(SchemeKind, _Mouth)>[
        (SchemeKind.vowel, _Mouth.open),
        (SchemeKind.hard, _Mouth.closed),
        (SchemeKind.soft, _Mouth.smile),
      ])
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              SizedBox(width: 56, height: 40, child: CustomPaint(painter: _MouthPainter(m))),
              const SizedBox(height: 4),
              SchemeChip(k, size: 44),
            ],
          ),
        ),
    ],
  );

  Widget _call() => Row(
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      const BoardSvg('assets/art/ui/nitzi_sit.svg', width: 84, height: 84),
      const SizedBox(width: 12),
      Icon(Icons.campaign_rounded, size: 64, color: TokenColors.skyDeep),
    ],
  );
}

enum _Mouth { open, closed, smile }

class _MouthPainter extends CustomPainter {
  const _MouthPainter(this.mouth);

  final _Mouth mouth;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint ink = Paint()
      ..color = TokenColors.ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    final Offset c = size.center(Offset.zero);
    switch (mouth) {
      case _Mouth.open:
        canvas.drawOval(Rect.fromCenter(center: c, width: 34, height: 28), ink);
      case _Mouth.closed:
        canvas.drawLine(c.translate(-18, 0), c.translate(18, 0), ink);
      case _Mouth.smile:
        canvas.drawArc(
          Rect.fromCenter(center: c.translate(0, -4), width: 44, height: 28),
          0.3,
          2.5,
          false,
          ink,
        );
    }
  }

  @override
  bool shouldRepaint(_MouthPainter old) => old.mouth != mouth;
}
