import 'dart:math' as math;

import 'package:flutter/gestures.dart' show DragStartBehavior;
import 'package:flutter/material.dart';

import '../content/models.dart';
import '../child/activity_shell.dart';
import '../design/board.dart' show BoardClass;
import '../design/components.dart';
import '../design/course_text.dart';
import '../design/tokens.g.dart';
import '../strings/he.dart';
import 'blend_slide_session.dart';
import 'borrowed_screens.dart';
import 'hints/hint_pictures.dart' show SkyRing;
import 'l5_art.dart';
import 'ls01_hand.dart';
import 'slide_geometry.dart';

// What LS04 draws on the board: the knob on a wire under the word (English and Hebrew), the consonant tile that slides to the vowel (Russian), the card of
// a hint and the friend's hand (docs/design/l5-templates.md section 5).

/// The two tiles of a merge on the stage: the first slides to the second along a dashed track, and they meet within 12 points.
class MergeGeometry {
  MergeGeometry._(this.page, this.tile, this.track, this.first, this.second, this.font);

  factory MergeGeometry.of(Rect page, BoardClass b) {
    final double tile = switch (b) {
      BoardClass.phone => 88,
      BoardClass.phoneSE => 80,
      BoardClass.tabletLandscape => 120,
      BoardClass.tabletPortrait => 128,
    };
    final double track = switch (b) {
      BoardClass.phone => 150,
      BoardClass.phoneSE => 86,
      BoardClass.tabletLandscape => 220,
      BoardClass.tabletPortrait => 300,
    };
    final double total = 2 * tile + track;
    final double left = page.center.dx - total / 2;
    final double top = page.center.dy - tile / 2 - 6;
    return MergeGeometry._(
      page,
      tile,
      track,
      Rect.fromLTWH(left, top, tile, tile),
      Rect.fromLTWH(left + tile + track, top, tile, tile),
      switch (b) {
        BoardClass.tabletLandscape || BoardClass.tabletPortrait => 64,
        _ => 48,
      },
    );
  }

  final Rect page;
  final double tile;
  final double track;

  /// The first tile at rest, and the second.
  final Rect first;
  final Rect second;
  final double font;

  /// The first tile's box at progress [t] (0 at rest, 1 touching the second).
  Rect firstAt(double t) => first.shift(Offset(t.clamp(0, 1) * track, 0));

  /// The progress at which the tiles meet: within 12 points of touching.
  double get meetAt => 1 - 12 / track;

  /// The progress of a finger at board x [x] holding the first tile by its middle.
  double tOf(double x) => ((x - first.center.dx) / track).clamp(0, 1);
}

class BlendLayer extends StatelessWidget {
  const BlendLayer({super.key, required this.session, required this.spec, required this.board});

  final BlendSlideSession session;
  final ActivitySpec spec;
  final BoardClass board;

  @override
  Widget build(BuildContext context) {
    final BlendSlideSession s = session;
    final Rect page = s.pageOf(spec);
    return Positioned.fill(
      child: Stack(
        clipBehavior: Clip.none,
        children: <Widget>[
          if (s.merge)
            ..._merge(s, s.mergeGeometry(spec, board))
          else
            ..._slide(context, s, s.geometry(spec, board)),
          if (s.card != null)
            Positioned.fromRect(
              rect: page.deflate(4),
              child: IgnorePointer(
                child: _HintCard(session: s, board: board),
              ),
            ),
          ?ls01HandLayer(s.handTip, spec),
        ],
      ),
    );
  }

  // ---- graphemes and units ----

  List<Widget> _slide(BuildContext context, BlendSlideSession s, SlideGeometry g) {
    final Rect zone = Rect.fromLTRB(
      math.min(g.xs, g.arrowX) - g.knob / 2 - 12,
      g.trackY - BlendSlideSession.reach(g.knob) - 12,
      math.max(g.xs, g.arrowX) + g.knob / 2 + 12,
      g.trackY + BlendSlideSession.reach(g.knob) + 12,
    );
    return <Widget>[
      SlideArt(
        geo: g,
        word: s.blend.word,
        knobT: s.knobT,
        instant: s.dragging,
        stepMs: s.auto ? s.stepMs : 400,
        litPart: s.litPart,
        passed: s.passed,
        pulse: s.pulse,
        hideWord: false,
      ),
      // The finger: it must start on the knob, and only its movement along the wire counts.
      Positioned.fromRect(
        rect: zone,
        child: GestureDetector(
          key: const Key('slide-zone'),
          behavior: HitTestBehavior.translucent,
          dragStartBehavior: DragStartBehavior.down,
          onPanStart: (DragStartDetails d) => s.slideStart(d.localPosition + zone.topLeft, g),
          onPanUpdate: (DragUpdateDetails d) => s.slideTo(d.localPosition.dx + zone.left, g),
          onPanEnd: (DragEndDetails _) => s.slideEnd(),
          onPanCancel: s.slideEnd,
          onTapUp: (TapUpDetails d) {
            final Offset p = d.localPosition + zone.topLeft;
            if ((p - Offset(g.xAt(s.knobT), g.trackY)).distance <= g.knob / 2 + 12) s.autoSlide();
          },
          child: const SizedBox.expand(),
        ),
      ),
    ];
  }

  // ---- merge ----

  List<Widget> _merge(BlendSlideSession s, MergeGeometry g) {
    final BlendWord w = s.blend.word;
    final Rect first = g.firstAt(s.mergeT);
    final bool stop = !w.parts[0].stretch;
    final Rect zone = Rect.fromLTRB(
      g.first.left - 12,
      g.first.top - 12,
      g.second.right + 12,
      g.first.bottom + 40,
    );
    final bool joined = s.joined;
    return <Widget>[
      if (!joined) ...<Widget>[
        // The track between the two tiles, dashed, with its arrow.
        Positioned(
          left: g.first.right + 8,
          top: g.first.center.dy - 3,
          width: g.track - 16,
          height: 6,
          child: const DashedRRect(radius: 3, width: 6, dash: 12, gap: 8),
        ),
        Positioned(
          left: g.second.left - 22,
          top: g.first.center.dy - 9,
          child: const ArrowHead(size: 18, towardsRight: true, color: TokenColors.lilacDeep),
        ),
        Positioned.fromRect(
          rect: g.second,
          child: _MergeTile(text: w.parts[1].text, size: g.font, key: const Key('merge-second')),
        ),
        // The stretch line under the held tile shows the held sound; a stop has none ("this sound cannot be held").
        if (!stop && s.held)
          Positioned(
            left: g.first.left,
            top: g.first.bottom + 14,
            width: first.right - g.first.left,
            height: 10,
            child: DecoratedBox(
              key: const Key('merge-stretch'),
              decoration: BoxDecoration(color: TokenColors.sea, borderRadius: BorderRadius.circular(5)),
            ),
          ),
        // The grip under the first tile: "this is what you move".
        AnimatedPositioned(
          duration: s.dragging ? Duration.zero : Duration(milliseconds: s.auto ? s.stepMs : 300),
          left: first.left,
          top: first.top,
          width: first.width,
          height: first.height,
          child: _MergeTile(
            text: w.parts[0].text,
            size: g.font,
            key: const Key('merge-first'),
            grip: true,
            moving: s.dragging || s.auto,
          ),
        ),
        Positioned.fromRect(
          rect: zone,
          child: GestureDetector(
            key: const Key('merge-zone'),
            behavior: HitTestBehavior.translucent,
            dragStartBehavior: DragStartBehavior.down,
            onPanStart: (DragStartDetails d) {
              if (s.met) return;
              if (g.firstAt(s.mergeT).inflate(12).contains(d.localPosition + zone.topLeft)) s.mergeStart();
            },
            onPanUpdate: (DragUpdateDetails d) => s.mergeTo(g.tOf(d.localPosition.dx + zone.left)),
            onPanEnd: (DragEndDetails _) => s.mergeEnd(),
            onPanCancel: s.mergeEnd,
            onTapUp: (TapUpDetails d) {
              if (g.firstAt(s.mergeT).inflate(12).contains(d.localPosition + zone.topLeft)) s.autoMerge();
            },
            child: const SizedBox.expand(),
          ),
        ),
      ] else
        // After the choice the two tiles are one.
        Positioned.fromRect(
          rect: Rect.fromLTWH(
            g.first.left + (g.track + g.tile * 2 - g.tile * 2.2) / 2,
            g.first.top,
            g.tile * 2.2,
            g.tile,
          ),
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0.6, end: 1),
            duration: const Duration(milliseconds: 280),
            builder: (BuildContext c, double v, Widget? child) => Transform.scale(scale: v, child: child),
            child: Container(
              key: const Key('merge-joined'),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: TokenColors.sparkTint,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: TokenColors.correctGlow, width: 5),
                boxShadow: clayShadows(TokenColors.sparkDeep, lipHeight: 5),
              ),
              child: CourseText(w.text, course: s.blend.course, size: g.font * 1.2, bold: true),
            ),
          ),
        ),
    ];
  }
}

/// A tile of the merge: a letter or syllable on a white tile with a clay lip; the first carries the sea grip under it.
class _MergeTile extends StatelessWidget {
  const _MergeTile({
    super.key,
    required this.text,
    required this.size,
    this.grip = false,
    this.moving = false,
  });

  final String text;
  final double size;
  final bool grip;
  final bool moving;

  @override
  Widget build(BuildContext context) => Stack(
    clipBehavior: Clip.none,
    children: <Widget>[
      Positioned.fill(
        child: Semantics(
          label: grip ? He.mergeTileSemantics.text : null,
          child: Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: grip ? TokenColors.ink : TokenColors.hairline, width: grip ? 4 : 3),
              boxShadow: clayShadows(TokenColors.cardLip, lipHeight: 5),
            ),
            child: CourseText(text, course: 'rus', size: size, bold: true, lineHeight: 1.2),
          ),
        ),
      ),
      if (grip)
        Positioned(
          left: 14,
          right: 14,
          bottom: -12,
          height: 12,
          child: DecoratedBox(
            decoration: BoxDecoration(color: TokenColors.sea, borderRadius: BorderRadius.circular(6)),
          ),
        ),
    ],
  );
}

/// The picture of the slide with no gesture on it (the layer adds them, and a hint's demonstration draws it alone): the word, a column behind the part that
/// sounds, a mark under each part threaded on the wire, the arrow, and the knob.
class SlideArt extends StatelessWidget {
  const SlideArt({
    super.key,
    required this.geo,
    required this.word,
    required this.knobT,
    required this.litPart,
    required this.passed,
    this.instant = false,
    this.stepMs = 400,
    this.pulse = false,
    this.hideWord = false,
    this.joinedBar = false,
  });

  final SlideGeometry geo;
  final BlendWord word;
  final double knobT;
  final int? litPart;
  final Set<int> passed;
  final bool instant;
  final int stepMs;
  final bool pulse;

  /// The word's own text is not drawn (the host draws it).
  final bool hideWord;

  /// The bars have joined into one under the word (the demonstration's last step).
  final bool joinedBar;

  @override
  Widget build(BuildContext context) {
    final SlideGeometry g = geo;
    final bool still = MediaQuery.disableAnimationsOf(context);
    final double wire = g.knob > 60 ? 10 : 8;
    final double left = math.min(g.xs, g.arrowX);
    final double right = math.max(g.xs, g.arrowX);
    final double knobX = g.xAt(knobT);
    return Stack(
      clipBehavior: Clip.none,
      children: <Widget>[
        // The sounding column: behind the part and its mark.
        for (int i = 0; i < word.parts.length; i++)
          if (litPart == i)
            Positioned(
              left: g.spans[i].left - 2,
              top: g.origin.dy,
              width: g.spans[i].width + 4,
              height: g.trackY - g.origin.dy + 14,
              child: DecoratedBox(
                key: Key('slide-column-$i'),
                decoration: BoxDecoration(
                  color: TokenColors.skyTint,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
        if (!hideWord)
          Positioned.fill(
            child: IgnorePointer(child: CustomPaint(painter: _WordPainter(g.painter, g.origin))),
          ),
        // The wire and its arrow.
        Positioned(
          left: left,
          top: g.trackY - wire / 2,
          width: right - left,
          height: wire,
          child: DecoratedBox(
            decoration: BoxDecoration(color: TokenColors.mist, borderRadius: BorderRadius.circular(wire / 2)),
          ),
        ),
        Positioned(
          left: g.rtl ? g.arrowX - 18 : g.arrowX - 4,
          top: g.trackY - 9,
          child: ArrowHead(size: 18, towardsRight: !g.rtl),
        ),
        // A mark under each part: a dot under one letter, a bar under a digraph or a unit.
        for (final (int i, BlendPart p) in word.parts.indexed) _mark(g, i, p),
        if (joinedBar)
          Positioned(
            left: g.spans.map((Rect r) => r.left).reduce(math.min) + 6,
            top: g.trackY - 7,
            width:
                g.spans.map((Rect r) => r.right).reduce(math.max) -
                g.spans.map((Rect r) => r.left).reduce(math.min) -
                12,
            height: 14,
            child: DecoratedBox(
              key: const Key('slide-joined-bar'),
              decoration: BoxDecoration(color: TokenColors.skyDeep, borderRadius: BorderRadius.circular(7)),
            ),
          ),
        // The knob.
        AnimatedPositioned(
          duration: instant || still ? Duration.zero : Duration(milliseconds: stepMs),
          curve: Curves.easeInOut,
          left: knobX - g.knob / 2,
          top: g.trackY - g.knob / 2,
          width: g.knob,
          height: g.knob,
          child: Semantics(
            button: true,
            label: He.slideKnobSemantics.text,
            child: Stack(
              clipBehavior: Clip.none,
              children: <Widget>[
                Positioned.fill(
                  child: Container(
                    key: const Key('slide-knob'),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: TokenColors.sea,
                      boxShadow: clayShadows(TokenColors.seaDeep, lipHeight: 5),
                    ),
                    child: ChevronMark(size: g.knob * 0.6, towardsRight: !g.rtl),
                  ),
                ),
                if (pulse)
                  const Positioned.fill(
                    child: IgnorePointer(child: SkyRing(key: Key('slide-pulse'))),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _mark(SlideGeometry g, int i, BlendPart p) {
    final Offset c = g.markAt(i);
    final bool bar = p.text.runes.length > 1;
    final bool lit = litPart == i;
    final bool done = passed.contains(i) || lit;
    final double w = bar ? math.max(14, g.spans[i].width - 12) : (lit ? 20 : 16);
    final double h = bar ? 14 : (lit ? 20 : 16);
    return Positioned(
      left: c.dx - w / 2,
      top: c.dy - h / 2,
      width: w,
      height: h,
      child: DecoratedBox(
        key: Key('slide-mark-$i'),
        decoration: BoxDecoration(
          color: done ? TokenColors.skyDeep : TokenColors.inkSoft,
          borderRadius: BorderRadius.circular(bar ? 7 : h / 2),
          border: Border.all(color: Colors.white, width: bar ? 0 : 2),
        ),
      ),
    );
  }
}

class _WordPainter extends CustomPainter {
  const _WordPainter(this.painter, this.origin);

  final TextPainter painter;
  final Offset origin;

  @override
  void paint(Canvas canvas, Size size) => painter.paint(canvas, origin);

  @override
  bool shouldRepaint(_WordPainter old) => old.painter != painter || old.origin != origin;
}

/// The card of a hint over the stage: each part as a token lit in turn, or the borrowed screen the hint names.
class _HintCard extends StatelessWidget {
  const _HintCard({required this.session, required this.board});

  final BlendSlideSession session;
  final BoardClass board;

  @override
  Widget build(BuildContext context) {
    final BlendSlideSession s = session;
    final BlendWord w = s.blend.word;
    final Widget body = s.card == 'borrowed' && s.plan != null
        ? BorrowedPanel(
            plan: s.plan!,
            step: s.borrowedStep,
            board: board,
            course: s.blend.course,
            assets: s.blend.assets,
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            textDirection: s.direction,
            children: <Widget>[
              for (final (int i, BlendPart p) in w.parts.indexed)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Container(
                    key: Key('slide-token-$i'),
                    width: 72,
                    height: 72,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: TokenColors.paper,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: s.cardLit == i ? TokenColors.skyDeep : TokenColors.hairline,
                        width: s.cardLit == i ? 5 : 3,
                      ),
                    ),
                    child: CourseText(p.text, course: s.blend.course, size: 34, bold: true, lineHeight: 1.2),
                  ),
                ),
            ],
          );
    return SkyCard(
      key: Key('slide-card-${s.card}'),
      child: Center(child: body),
    );
  }
}
