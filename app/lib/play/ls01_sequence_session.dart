import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../child/activity_shell.dart';
import '../content/models.dart';
import '../design/components.dart';
import '../design/course_text.dart';
import '../design/tokens.g.dart';
import 'ls01_metrics.dart';
import 'ls01_session.dart';
import 'ls01_tiles.dart';
import 'option_faces.dart';
import 'response_code.dart';
import 'template_session.dart';

/// The story line (LS01 f, `build_pattern` 1.1 with `answer.order`; docs/design/languages-l5-ls01.md section 7.10): a sequence of 2 to 4 pictures
/// (a story's pages) or tiles, in one row of places that already holds them in a shuffled order. A touch on a picture sets it in the first
/// place not yet set (it swaps with the picture there) and the next touch sets the next place; when one place is left it sets itself and the
/// order is checked. A touch on a set picture un-sets it and every place after it. A "not yet" wobbles the whole line and un-sets every place;
/// the pictures stay where they are. The line runs in the course's direction: the Hebrew course's story starts at the right, English and
/// Russian at the left (the lands' timelines keep their left-to-right rule; they never meet on one screen).
class Ls01SequenceSession extends Ls01Session {
  Ls01SequenceSession(super.controller, BuildPatternActivity super.activity, {super.band, super.stress})
    : story = activity,
      arrangement = List<int>.generate(activity.palette.length, (int i) => i);

  final BuildPatternActivity story;

  /// For each place the palette index of the picture standing in it now, and how many places (from the start) are set.
  final List<int> arrangement;
  int setCount = 0;
  bool busy = false;
  bool done = false;
  bool wobbling = false;

  /// The places that have turned correct, counted from the start, while the praise runs.
  int correctUpTo = 0;

  // A hint's marks: the picture lit now, the card of "first, then, at the end" and the bead of it that is lit.
  int? litPlace;
  bool cardShown = false;
  int? cardBead;

  int get n => story.palette.length;

  @override
  bool get wideZone => true;

  late final List<Ls01Face> faces = <Ls01Face>[
    for (final (int i, String f) in story.palette.indexed)
      f.startsWith('txt:')
          ? Ls01Face(id: 'q$i', text: f.substring(4), label: f.substring(4))
          : Ls01Face(id: 'q$i', svg: story.assets.svg(f), label: f),
  ];

  /// The aspect (width over height) a picture is drawn at: its own, from the viewBox of its drawing; a story page is 16:9, an object 1:1,
  /// a tile of text square.
  double aspectOf(int paletteIndex) {
    final Ls01Face f = faces[paletteIndex];
    if (f.svg == null) return 1;
    final RegExpMatch? m = RegExp(r'viewBox="\s*[-\d.]+[ ,]+[-\d.]+[ ,]+([\d.]+)[ ,]+([\d.]+)')
        .firstMatch(f.svg!);
    if (m == null) return 1;
    final double w = double.parse(m.group(1)!);
    final double h = double.parse(m.group(2)!);
    return h <= 0 ? 1 : (w / h).clamp(0.6, 2.0).toDouble();
  }

  double get _gap => zones.stageIsCard ? 24 : 16;

  /// The size of every place: the most the row allows, all alike, at the largest aspect of the pictures; no taller than the room above the
  /// bottom band lets the line be (docs/design/languages-l5-ls01.md section 7.10).
  Size placeSize(ActivitySpec s) {
    final double aspect = <double>[for (int i = 0; i < n; i++) aspectOf(i)].reduce(math.max);
    final double room = s.tilesWidth;
    final double w = (room - (n - 1) * _gap) / n;
    // The tallest a place may be: 120 on the tablets, and on the phones what the room between the stage and the bottom band leaves (88; 82 on the SE).
    final double maxH = s.stageIsCard ? 120 : (s.boardHeight < 380 ? 82 : 88);
    double h = w / aspect;
    double width = w;
    if (h > maxH) {
      h = maxH;
      width = h * aspect;
    }
    return Size(width, h);
  }

  @override
  ActivitySpec layoutFor(ActivitySpec base) {
    final ActivitySpec zone = super.layoutFor(base);
    if (zone.stageIsCard) return zone;
    // The line stands so that its beads end 2 above the bottom band (their centres at y 341 on the SE, 359 on the phone): a tall place (3
    // squares) lifts it, and the stage gives way. Under the top of the places lie their 12 of room, the 22 to the path and 11 to a bead's middle.
    final double beadCentre = zone.boardHeight < 380 ? 341 : 359;
    final double top = math.min(zone.tilesTop, beadCentre - (12 + 22 + 11) - placeSize(zone).height);
    return zone.withStageAndTiles(
      stage: Rect.fromLTWH(
        zone.stage.left,
        zone.stage.top,
        zone.stage.width,
        math.min(zone.stage.height, top - 12 - zone.stage.top),
      ),
      tilesLeft: zone.tilesLeft,
      tilesTop: top,
      tilesWidth: zone.tilesWidth,
    );
  }

  // ---- the child's moves ----

  /// A touch on place [j]: a picture not yet set is set in the next place (it swaps with the one there); a set one is un-set, with every place
  /// after it.
  void tapPlace(int j) {
    if (busy || done) return;
    handTip = null;
    if (j < setCount) {
      setCount = j;
      notify();
      return;
    }
    // After three tries only the right picture is taken for the next place.
    if (controller.guided && arrangement[j] != story.order[setCount]) return;
    final int t = arrangement[j];
    arrangement[j] = arrangement[setCount];
    arrangement[setCount] = t;
    setCount++;
    // When one place is left it sets itself.
    if (setCount == n - 1) setCount = n;
    notify();
    if (setCount == n) _check();
  }

  Future<void> _check() async {
    busy = true;
    final bool right = <bool>[for (int k = 0; k < n; k++) arrangement[k] == story.order[k]]
        .every((bool b) => b);
    final String code = ResponseCode.pattern(arrangement);
    await controller.submitPlacement(right: right, tag: right ? '' : (story.wrongTag ?? ''), response: code);
    if (disposed) return;
    if (right) {
      for (int k = 0; k < n; k++) {
        later(Duration(milliseconds: 320 * (k + 1)), () {
          correctUpTo = k + 1;
          notify();
        });
      }
      done = true;
      notify();
      later(praise + Duration(milliseconds: 320 * n), controller.next);
      return;
    }
    wobbling = true;
    notify();
    later(TemplateSession.notYetPause, () {
      wobbling = false;
      setCount = 0;
      busy = false;
      notify();
    });
  }

  // ---- hints ----

  @override
  void resetState() {
    for (int i = 0; i < n; i++) {
      arrangement[i] = i;
    }
    setCount = 0;
    busy = false;
    done = false;
    wobbling = false;
    correctUpTo = 0;
  }

  @override
  void clearHintMarks() {
    litPlace = null;
    cardShown = false;
    cardBead = null;
  }

  /// The place that holds the picture [paletteIndex] now.
  int placeOf(int paletteIndex) => arrangement.indexOf(paletteIndex);

  @override
  void playHint(int level) {
    switch (level) {
      case 1:
        // The story again, short: the places light one after the other, first to last, while the lines of the story play in its order. The
        // lit place is the k-th place of the line, not the picture that stands in it: no picture is lit before level 3 (spec section 8).
        for (int k = 0; k < n; k++) {
          step(900 * k, () {
            litPlace = k;
            if (story.clips.length == n) {
              playClips?.call(<String>[story.clips[story.order[k]]], replace: false);
            }
          });
        }
        step(900 * n, () => litPlace = null);
      case 2:
        // "First, then, at the end": beads on a path in the course's direction, each lighting in turn; the first place lights.
        cardShown = true;
        litPlace = 0;
        for (int k = 0; k < n; k++) {
          step(700 * k + 300, () => cardBead = k);
        }
      default:
        for (int k = 0; k < n; k++) {
          step(300 + 1300 * k, () => handTip = _rect(placeOf(story.order[k])).topCenter + const Offset(0, 6));
        }
        demoOver(300 + 1300 * n);
    }
  }

  // ---- drawing ----

  Rect _rect(int place) {
    final Size p = placeSize(zones);
    final double total = n * p.width + (n - 1) * _gap;
    final double start = zones.tilesLeft + (zones.tilesWidth - total) / 2;
    final int slot = rowDirection == TextDirection.ltr ? place : n - 1 - place;
    return Rect.fromLTWH(start + slot * (p.width + _gap), zones.tilesTop, p.width, p.height);
  }

  @override
  Widget buildStage(BuildContext context, Size size, ActivitySpec spec) {
    seen(spec);
    return Ls01StageBuilder(
      direction: rowDirection,
      listenable: this,
      builder: (BuildContext c, Widget? _) => Semantics(
        container: true,
        label: story.altText,
        child: Stack(
          key: const Key('sequence-stage'),
          clipBehavior: Clip.none,
          children: <Widget>[
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: SpeakerMark(
                key: const Key('story-again'),
                touch: spec.stageIsCard ? 80 : 64,
                onTap: controller.replayPrompt,
              ),
            ),
            if (cardShown) Center(child: _card()),
          ],
        ),
      ),
    );
  }

  /// The sky card of "first, then, at the end": three beads on a path, each lighting in turn, in the course's direction.
  Widget _card() => Container(
    key: const Key('sequence-card'),
    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
    decoration: BoxDecoration(
      color: TokenColors.skyTint,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: TokenColors.hintHalo, width: 3),
    ),
    child: Directionality(
      textDirection: rowDirection,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          for (int k = 0; k < math.min(n, 3); k++) ...<Widget>[
            if (k > 0) Container(width: 28, height: 4, color: TokenColors.skyDeep),
            Container(
              key: Key('card-bead-$k'),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: cardBead == k ? TokenColors.skyDeep : TokenColors.paper,
                shape: BoxShape.circle,
                border: Border.all(color: TokenColors.skyDeep, width: 3),
              ),
            ),
          ],
        ],
      ),
    ),
  );

  @override
  Widget? buildTiles(BuildContext context, ActivitySpec spec) {
    seen(spec);
    return ListenableBuilder(
      listenable: this,
      builder: (BuildContext c, Widget? _) {
        final Size p = placeSize(spec);
        final Ls01Metrics m = metrics;
        final bool still = MediaQuery.disableAnimationsOf(c);
        return SizedBox(
          height: p.height + 12 + 22 + 16 + 6,
          child: Align(
            alignment: Alignment.topCenter,
            child: SizedBox(
              width: n * p.width + (n - 1) * _gap,
              child: Directionality(
                textDirection: rowDirection,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: <Widget>[
                    // The path, 6 points of mist, with the part up to the last set place drawn in lilac, and a bead under each place.
                    Positioned(left: 0, right: 0, top: 12 + p.height + 22, child: _path(p, setCount)),
                    Wobble(
                      active: wobbling && !still,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Row(
                          children: <Widget>[
                            for (int j = 0; j < n; j++) ...<Widget>[
                              if (j > 0) SizedBox(width: _gap),
                              _place(j, p, m),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _path(Size p, int set) {
    final bool ltr = rowDirection == TextDirection.ltr;
    return SizedBox(
      height: 22,
      child: Stack(
        clipBehavior: Clip.none,
        children: <Widget>[
          Positioned(
            left: 0,
            right: 0,
            top: 8,
            child: Container(
              key: const Key('sequence-path'),
              height: 6,
              decoration: BoxDecoration(color: TokenColors.mist, borderRadius: BorderRadius.circular(3)),
            ),
          ),
          if (set > 0)
            PositionedDirectional(
              start: 0,
              top: 8,
              width: set * p.width + (set - 1) * _gap,
              child: Container(
                height: 6,
                decoration: BoxDecoration(
                  color: TokenColors.lilacDeep,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          // The start flag: a short ink pole with a pennant of sea, at the start end of the path.
          PositionedDirectional(
            start: 0,
            top: -18,
            child: SizedBox(
              key: const Key('sequence-flag'),
              width: 22,
              height: 26,
              child: Transform.flip(
                flipX: !ltr,
                child: CustomPaint(painter: _FlagPainter()),
              ),
            ),
          ),
          for (int j = 0; j < n; j++)
            PositionedDirectional(
              start: j * (p.width + _gap) + p.width / 2 - 8,
              top: 3,
              child: Container(
                key: Key('bead-$j'),
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: j < set ? TokenColors.lilacDeep : TokenColors.paper,
                  shape: BoxShape.circle,
                  border: Border.all(color: j < set ? TokenColors.lilacDeep : TokenColors.hairline, width: 3),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _place(int j, Size p, Ls01Metrics m) {
    final Ls01Face f = faces[arrangement[j]];
    final bool set = j < setCount;
    final bool right = j < correctUpTo;
    final Widget body = Container(
      key: Key('place-$j'),
      width: p.width,
      height: p.height,
      alignment: Alignment.center,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: right ? TokenColors.sparkTint : TokenColors.paper,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: right ? TokenColors.spark : (set ? TokenColors.lilacDeep : TokenColors.hairline),
          width: 4,
        ),
        boxShadow: clayShadows(TokenColors.cardLip, soft16: true),
      ),
      child: f.text != null
          ? FittedBox(
              fit: BoxFit.scaleDown,
              child: CourseText(
                f.text!,
                course: m.course,
                size: m.size(FaceKind.letter),
                bold: true,
                lineHeight: lineHeightFor(f.text!, hebrew: m.hebrew),
              ),
            )
          : PackSvg(f.svg!),
    );
    final Widget lit = Stack(
      clipBehavior: Clip.none,
      children: <Widget>[
        body,
        if (litPlace == j)
          const Positioned(
            left: -6,
            right: -6,
            top: -6,
            bottom: -6,
            child: IgnorePointer(
              child: DecoratedBox(
                key: Key('place-glow'),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.all(Radius.circular(24)),
                  border: Border.fromBorderSide(BorderSide(color: TokenColors.hintHalo, width: 4)),
                ),
              ),
            ),
          ),
      ],
    );
    return DragTarget<int>(
      onWillAcceptWithDetails: (DragTargetDetails<int> d) => !busy && !done && j == setCount,
      onAcceptWithDetails: (DragTargetDetails<int> d) => tapPlace(d.data),
      builder: (BuildContext c, List<int?> over, List<dynamic> rejected) => Semantics(
        button: true,
        label: f.label,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => tapPlace(j),
          child: set || busy || done
              ? lit
              : Draggable<int>(
                  key: Key('place-drag-$j'),
                  data: j,
                  feedback: SizedBox(
                    width: p.width,
                    height: p.height,
                    child: Opacity(opacity: 0.9, child: body),
                  ),
                  childWhenDragging: Opacity(opacity: 0.25, child: lit),
                  child: lit,
                ),
        ),
      ),
    );
  }
}

/// The start flag of the story line: a short pole of ink and a pennant of sea.
class _FlagPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawLine(
      Offset(3, size.height),
      Offset(3, 2),
      Paint()
        ..color = TokenColors.ink
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );
    final Path flag = Path()
      ..moveTo(4, 3)
      ..lineTo(size.width, 9)
      ..lineTo(4, 15)
      ..close();
    canvas.drawPath(flag, Paint()..color = TokenColors.sea);
  }

  @override
  bool shouldRepaint(_FlagPainter old) => false;
}
