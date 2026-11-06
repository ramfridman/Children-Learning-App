import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../child/activity_shell.dart';
import '../content/models.dart';
import '../design/app_text.dart';
import '../design/components.dart';
import '../design/course_text.dart';
import '../design/layout.dart';
import '../design/tokens.g.dart';
import 'hints/hint_pictures.dart' show SkyRing;
import 'ls01_metrics.dart';
import 'option_faces.dart';
import 'template_session.dart';

// The tiles of the modes that L5-1 adds to LS01 (docs/design/languages-l5-ls01.md sections 3, 4 and 6): a face is a picture, a text at its
// reading size, a numeral or only a sound; a tile is the answer tile of the band with the states of the spec; a row is equal tiles in the
// course's direction, centred in the answer zone.

/// What a tile, a card, a cell or a sign shows. [id] is what the session answers with.
class Ls01Face {
  const Ls01Face({required this.id, this.text, this.svg, this.numeral, this.clip, this.label = ''});

  /// A face of a choice option.
  factory Ls01Face.option(ChoiceOption o, PackAssets assets, {bool stress = true}) => Ls01Face(
    id: o.id,
    text: o.text == null ? null : _stress(o.text!, stress),
    svg: o.sprite == null ? null : assets.svg(o.sprite!),
    numeral: o.numeral,
    clip: o.clip,
    label: o.label ?? '',
  );

  final String id;
  final String? text;

  /// The picture, as the text of its SVG.
  final String? svg;
  final int? numeral;
  final String? clip;
  final String label;

  /// A sound card: nothing to see on it, only a sound to hear.
  bool get soundOnly => clip != null && text == null && svg == null && numeral == null;

  static String _stress(String t, bool show) =>
      show ? t : String.fromCharCodes(t.runes.where((int r) => r != 0x0301));
}

/// How one tile looks now: the answer state of the tile, and the marks that are shapes as well as colours.
class Ls01Look {
  const Ls01Look({
    this.state = AnswerState.idle,
    this.lit = false,
    this.picked = false,
    this.dimmed = false,
    this.heard = false,
  });

  /// `selected` is chosen (lifted, ringed), `correct` the check, `notYet` the lilac border and the wobble.
  final AnswerState state;

  /// A hint looks here: a sky ring outside the tile.
  final bool lit;

  /// Tap-all: the card is picked (an ink dot at the end corner).
  final bool picked;

  /// The tile stays behind dimmed to 35% (a word in the cloze gap, the others when the answer is shown).
  final bool dimmed;

  /// A sound card that has been played shows its waves.
  final bool heard;
}

/// The size of a face's drawing: a picture inset 6, a text at its reading size, a speaker of 52.
class Ls01FaceView extends StatelessWidget {
  const Ls01FaceView({
    super.key,
    required this.face,
    required this.metrics,
    required this.kind,
    this.heard = true,
    this.size,
  });

  final Ls01Face face;
  final Ls01Metrics metrics;
  final FaceKind kind;
  final bool heard;

  /// A size of text other than the kind's reading size (the item now of a pair is a quarter larger).
  final double? size;

  @override
  Widget build(BuildContext context) {
    if (face.text != null) {
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: metrics.wordPad / 2),
        child: Center(
          // The last safety net (docs/design/languages-l5-ls01.md section 4.5): a text that is too wide for its tile is scaled to it. The
          // fit test refuses such a text before a pack is built, so this never shows.
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: CourseText(
              face.text!,
              key: const Key('face-text'),
              course: metrics.course,
              size: size ?? metrics.size(kind),
              bold: kind == FaceKind.letter,
              lineHeight: lineHeightFor(face.text!, hebrew: metrics.hebrew),
            ),
          ),
        ),
      );
    }
    if (face.svg != null) return Padding(padding: const EdgeInsets.all(6), child: PackSvg(face.svg!));
    if (face.numeral != null) {
      return Center(
        child: MathIsolate(
          child: Text(
            '${face.numeral}',
            style: AppText.fixed(size: metrics.size(FaceKind.letter), weight: 800, lineHeight: 1),
          ),
        ),
      );
    }
    return SoundFace(heard: heard);
  }
}

/// A row of equal answer tiles in the course's direction, centred in the answer zone: the tiles of a stem, a cloze, a tap-all, the tray of a
/// sort, the partners of a pair, the cells of a spot, the tiles of an order.
class Ls01Row extends StatelessWidget {
  const Ls01Row({
    super.key,
    required this.faces,
    required this.looks,
    required this.metrics,
    required this.direction,
    required this.kind,
    required this.zoneWidth,
    required this.onTap,
    this.decorate,
    this.intrinsic = false,
    this.plan,
  });

  /// The plan the row keeps whatever tiles are left in it (the tray of a sort, whose tiles leave one by one): the width of a tile and the gap
  /// are those of the whole set, so that nothing in the row changes size when one goes.
  final RowPlan? plan;

  /// Wraps tile [i] in something (a drag source), or null.
  final Widget Function(int index, Widget tile)? decorate;

  /// The row is only as wide as its tiles and is not centred in its zone (the caller places it, beside a pile for example).
  final bool intrinsic;

  final List<Ls01Face> faces;

  /// How each tile looks, in the order of [faces] (a missing one is idle).
  final List<Ls01Look> looks;
  final Ls01Metrics metrics;
  final TextDirection direction;

  /// `letter` for square tiles of one or two letters, `word` for the rest.
  final FaceKind kind;
  final double zoneWidth;
  final void Function(int index) onTap;

  /// The plan of the row: the widest text decides one width for all.
  static RowPlan planOf(List<Ls01Face> faces, Ls01Metrics metrics, FaceKind kind, double zoneWidth) =>
      metrics.row(
        <String>[
          for (final Ls01Face f in faces)
            if (f.text != null) f.text!,
        ],
        kind,
        zoneWidth,
        count: faces.length,
      );

  @override
  Widget build(BuildContext context) {
    final RowPlan plan = this.plan?.withCount(faces.length) ?? planOf(faces, metrics, kind, zoneWidth);
    final Widget row = Directionality(
      textDirection: direction,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          for (final (int i, Ls01Face f) in faces.indexed)
            Ls01Tile(
              face: f,
              look: i < looks.length ? looks[i] : const Ls01Look(),
              metrics: metrics,
              kind: kind,
              width: plan.tileWidth,
              gap: plan.gap,
              onTap: () => onTap(i),
              decorate: decorate == null ? null : (Widget tile) => decorate!(i, tile),
            ),
        ],
      ),
    );
    if (intrinsic) return row;
    return Center(
      child: plan.fits ? row : FittedBox(fit: BoxFit.scaleDown, child: row),
    );
  }
}

/// One answer tile of the band with its hit area (half the gap beside it, the band's slop above and below), its states and its face.
class Ls01Tile extends StatelessWidget {
  const Ls01Tile({
    super.key,
    required this.face,
    required this.look,
    required this.metrics,
    required this.kind,
    required this.width,
    required this.gap,
    required this.onTap,
    this.decorate,
  });

  /// Wraps the tile (not its lit ring or its dot) in a drag source.
  final Widget Function(Widget tile)? decorate;

  final Ls01Face face;
  final Ls01Look look;
  final Ls01Metrics metrics;
  final FaceKind kind;
  final double width;
  final double gap;
  final VoidCallback onTap;

  Widget _wrap(Widget tile) => decorate == null ? tile : decorate!(tile);

  @override
  Widget build(BuildContext context) {
    final bool still = MediaQuery.disableAnimationsOf(context);
    return Opacity(
      opacity: look.dimmed ? 0.35 : 1,
      child: Stack(
        clipBehavior: Clip.none,
        children: <Widget>[
          Wobble(
            active: look.state == AnswerState.notYet && !still,
            child: _wrap(
              AnswerTile(
                key: Key('tile-${face.id}'),
                semanticLabel: face.label,
                size: metrics.tileHeight,
                width: width,
                hitPadding: EdgeInsets.symmetric(horizontal: gap / 2, vertical: metrics.hitSlop),
                state: look.picked && look.state == AnswerState.idle ? AnswerState.selected : look.state,
                onPressed: onTap,
                child: Ls01FaceView(face: face, metrics: metrics, kind: kind, heard: look.heard),
              ),
            ),
          ),
          if (look.lit)
            Positioned(
              left: gap / 2 - 6,
              right: gap / 2 - 6,
              top: metrics.hitSlop - 6,
              bottom: metrics.hitSlop - 6,
              child: const IgnorePointer(
                child: SkyRing(key: Key('hint-tile-glow'), round: false, radius: TokenRadius.xl + 6),
              ),
            ),
          if (look.picked)
            PositionedDirectional(
              end: gap / 2 - 8,
              top: metrics.hitSlop - 10,
              child: const IgnorePointer(child: PickedDot()),
            ),
        ],
      ),
    );
  }
}

/// The dot of a picked card: 26 points of ink with a white rim, at the end corner (a shape as well as a colour).
class PickedDot extends StatelessWidget {
  const PickedDot({super.key});

  @override
  Widget build(BuildContext context) => Container(
    key: const Key('picked-dot'),
    width: 26,
    height: 26,
    decoration: BoxDecoration(
      color: TokenColors.ink,
      shape: BoxShape.circle,
      border: Border.all(color: TokenColors.paper, width: 3),
    ),
  );
}

/// Two small swings of 6 points when [active] turns on (the "not yet" of the spec, 360 ms), then rest. Nothing moves with reduce motion
/// (the caller passes `active: false`); the lilac border of the tile is the cue then.
class Wobble extends StatefulWidget {
  const Wobble({super.key, required this.active, required this.child});

  final bool active;
  final Widget child;

  @override
  State<Wobble> createState() => _WobbleState();
}

class _WobbleState extends State<Wobble> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: TokenMotion.dWobble);

  @override
  void initState() {
    super.initState();
    if (widget.active) _c.forward(from: 0);
  }

  @override
  void didUpdateWidget(Wobble old) {
    super.didUpdateWidget(old);
    if (widget.active && !old.active) _c.forward(from: 0);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _c,
    child: widget.child,
    builder: (BuildContext context, Widget? child) => Transform.translate(
      offset: Offset(math.sin(_c.value * 4 * math.pi) * 6 * (1 - _c.value), 0),
      child: child,
    ),
  );
}

/// Where the tiles of a row stand on the board (the tile itself, not its hit area), by the zone [spec] has and the [plan] of the row, for
/// a hint's hand and for the tests.
List<Rect> rowRects(ActivitySpec spec, RowPlan plan, TextDirection direction) {
  final double start = spec.tilesLeft + (spec.tilesWidth - plan.total) / 2;
  return <Rect>[
    for (int i = 0; i < plan.count; i++)
      Rect.fromLTWH(
        start + (direction == TextDirection.ltr ? i : plan.count - 1 - i) * plan.cell + plan.gap / 2,
        spec.tilesTop,
        plan.tileWidth,
        plan.tileHeight,
      ),
  ];
}

/// The stage of a mode, rebuilt when the session changes, in the course's direction: the stage's `start` and `end` (an aligned item, a speaker at
/// the corner of a bin) are the course's, not the Hebrew interface's.
class Ls01StageBuilder extends StatelessWidget {
  const Ls01StageBuilder({
    super.key,
    required this.direction,
    required this.listenable,
    required this.builder,
  });

  final TextDirection direction;
  final Listenable listenable;
  final Widget Function(BuildContext context, Widget? child) builder;

  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: direction,
    child: ListenableBuilder(listenable: listenable, builder: builder),
  );
}
