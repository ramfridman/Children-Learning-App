import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../child/activity_shell.dart';
import '../content/hint_ladder.dart';
import '../content/models.dart';
import '../design/components.dart';
import '../design/tokens.g.dart';
import 'hints/hint_marks.dart';
import 'hints/hint_pictures.dart' show hintScale;
import 'hints/hint_player.dart';
import 'hints/pointer_plans.dart';
import 'hints/tile_points.dart';
import 'response_code.dart';
import 'template_session.dart';

/// The shape-builder template (T10). A picture made of shapes stands on the stage as silhouettes; the shapes wait in the tray
/// below. A shape is touched and then its place is touched, or it is dragged there. A shape that belongs there snaps in, turned
/// the way the picture needs it (the child never has to turn anything); one that does not is a gentle "not yet" and goes back.
/// After three wrong tries only the right place takes the shape: the guide first puts one piece in its place as a worked example,
/// and the place and the piece stay lit.
class ShapeBuilderSession extends TemplateSession {
  ShapeBuilderSession(super.controller, this.activity);

  final ShapeBuilderActivity activity;

  /// Which place is filled (slot id): the shape that is in it stays in the tray's count.
  final Set<String> filled = <String>{};

  /// The tray piece (index into [pieces]) that has been touched.
  int? selected;

  /// The place and the tray piece that the help points at, and the place that just said "not yet".
  String? hintSlot;
  int? hintPiece;
  String? notYetSlot;
  bool demoRunning = false;
  int _run = 0;

  AnswerState ring = AnswerState.idle;
  bool _busy = false;

  late final List<String> pieces = activity.pieces;

  /// The pointing hand and the ghost outline (B-40), and the stage's and the board's sizes they are placed by.
  late final HintPlayer _hint = HintPlayer(this);
  Size _size = Size.zero;
  ActivitySpec? _spec;

  bool get _canDraw => _spec != null && !_size.isEmpty;

  /// The box the picture of the stage is drawn in (centred, as high as the stage allows), and the place of a slot in it.
  Rect pictureBox(Size size) {
    final double w = math.min(size.width - 16, (size.height - 12) * activity.aspect);
    final double h = w / activity.aspect;
    return Rect.fromLTWH((size.width - w) / 2, (size.height - h) / 2, w, h);
  }

  Rect slotRect(Size size, ShapeSlot slot) {
    final Rect box = pictureBox(size);
    return Rect.fromLTWH(
      box.left + slot.x * box.width,
      box.top + slot.y * box.height,
      slot.w * box.width,
      slot.h * box.height,
    );
  }

  /// The outline that a slot's silhouette has, or null for a shape the ghost cannot draw.
  static GhostKind? ghostKindOf(String sprite) {
    if (sprite.contains('shape_circle')) return GhostKind.circle;
    if (sprite.contains('shape_square')) return GhostKind.square;
    if (sprite.contains('shape_triangle')) return GhostKind.triangle;
    if (sprite.contains('shape_rect')) return GhostKind.rect;
    return null;
  }

  /// Where the ghost floats beside the picture: at the stage's end side (the left) when there is room for it there, else at the
  /// other side, else null. It is as big as the room allows, up to 56 (times the board's scale).
  Rect? _ghostPlace(Size size) {
    final Rect box = pictureBox(size);
    final double k = hintScale(size);
    final double left = box.left - 8;
    final double right = size.width - box.right - 8;
    final double side = math.min(56 * k, math.max(left, right) - 8);
    if (side < 34) return null;
    final double x = left >= right ? 4 + (left - side) / 2 : box.right + 4 + (right - side) / 2;
    return Rect.fromLTWH(x, (size.height - side) / 2, side, side);
  }

  /// The tray pieces that have been used (the first of each shape that has been placed).
  final Set<int> usedPieces = <int>{};

  bool isUsed(int i) => usedPieces.contains(i);

  /// The place and piece the guide has put together for a moment; a touch of the child ends the demonstration at once.
  String? _demoSlot;
  int? _demoPiece;

  void _endDemo() {
    if (!demoRunning) return;
    _run++;
    _hint.clear();
    if (_demoSlot != null) filled.remove(_demoSlot);
    if (_demoPiece != null) usedPieces.remove(_demoPiece);
    _demoSlot = null;
    _demoPiece = null;
    demoRunning = false;
    controller.demoDone();
  }

  void select(int piece) {
    _endDemo();
    if (_busy || ring == AnswerState.correct || isUsed(piece)) return;
    selected = selected == piece ? null : piece;
    notify();
  }

  void tapSlot(String slotId) {
    final int? s = selected;
    if (s != null) drop(s, slotId);
  }

  Future<void> drop(int piece, String slotId) async {
    _endDemo();
    if (_busy || ring == AnswerState.correct || isUsed(piece) || filled.contains(slotId)) return;
    final ShapeSlot slot = activity.slots.firstWhere((ShapeSlot s) => s.id == slotId);
    if (pieces[piece] == slot.sprite) {
      _hint.clear();
      filled.add(slotId);
      usedPieces.add(piece);
      selected = null;
      hintSlot = null;
      hintPiece = null;
      notify();
      if (filled.length == activity.slots.length) await _done();
      return;
    }
    if (controller.guided) {
      if (controller.answerShown) _point(piece);
      return;
    }
    _busy = true;
    notYetSlot = slotId;
    notify();
    await controller.submitPlacement(
      right: false,
      tag: activity.wrongTag ?? '',
      response: ResponseCode.shapeMove(piece, slotId),
    );
    if (disposed) return;
    later(TemplateSession.notYetPause, () {
      notYetSlot = null;
      selected = null;
      _busy = false;
      if (controller.answerShown) _point(piece);
      notify();
    });
  }

  Future<void> _done() async {
    _busy = true;
    await controller.submitPlacement(right: true, response: ResponseCode.built);
    if (disposed) return;
    ring = AnswerState.correct;
    notify();
    later(TemplateSession.praisePause, controller.next);
  }

  /// The help shows the next place that is still empty and a piece that fits it.
  void _point(int fromPiece) {
    final ShapeSlot? open = activity.slots.where((ShapeSlot s) => !filled.contains(s.id)).firstOrNull;
    if (open == null) return;
    hintSlot = open.id;
    final int fit = <int>[for (int i = 0; i < pieces.length; i++) i]
        .firstWhere((int i) => !isUsed(i) && pieces[i] == open.sprite, orElse: () => fromPiece);
    hintPiece = fit;
    notify();
  }

  @override
  void onReset() {
    _hint.clear();
    _run++;
    _demoSlot = null;
    _demoPiece = null;
    filled.clear();
    usedPieces.clear();
    selected = null;
    hintSlot = null;
    hintPiece = null;
    notYetSlot = null;
    ring = AnswerState.idle;
    _busy = false;
    demoRunning = false;
    notify();
  }

  @override
  void onReplay() {
    _hint.clear();
    _run++;
    hintSlot = null;
    hintPiece = null;
    notify();
  }

  ShapeSlot? get _nextOpen => activity.slots.where((ShapeSlot s) => !filled.contains(s.id)).firstOrNull;

  @override
  void onHint() {
    if ((_busy && !controller.guided) || demoRunning) return;
    switch (hintPictureOf(activity)) {
      case HintPicture.eachFace:
        _lightEach();
      case HintPicture.nextOutline:
        _run++;
        _hint.clear();
        hintPiece = null;
        hintSlot = _nextOpen?.id;
        _liftGhost();
        notify();
      default:
        _putOne();
    }
  }

  /// Hint 1: the empty outlines are lit one after the other. No piece is chosen and none stays lit.
  void _lightEach() {
    _run++;
    final int run = _run;
    hintPiece = null;
    final List<ShapeSlot> open = <ShapeSlot>[
      for (final ShapeSlot s in activity.slots)
        if (!filled.contains(s.id)) s,
    ];
    for (int i = 0; i < open.length; i++) {
      later(Duration(milliseconds: 700 * i), () {
        if (run != _run) return;
        hintSlot = open[i].id;
        notify();
      });
    }
    later(Duration(milliseconds: 700 * open.length), () {
      if (run != _run) return;
      hintSlot = null;
      notify();
    });
    notify();
  }

  /// P9: the outline of the next empty place lifts off as a ghost, turns once and floats beside the picture, where the child can
  /// compare it with the pieces in the tray. It marks no piece and stays while the item is open.
  void _liftGhost() {
    final ShapeSlot? open = _nextOpen;
    final GhostKind? kind = open == null ? null : ghostKindOf(open.sprite);
    final Rect? place = _canDraw ? _ghostPlace(_size) : null;
    if (open == null || kind == null || place == null) return;
    final Rect from = slotRect(_size, open);
    _hint.play(
      HintPlan(
        <HintFrame>[
          HintFrame(<HintMark>[GhostMark(from, kind)], hold: const Duration(milliseconds: 700)),
        ],
        rest: <HintMark>[GhostMark(place, kind, turn: true)],
      ),
    );
  }

  /// The worked example: the pointing hand takes the piece that fits the next place from the tray and puts it there (the guide
  /// lights the place and the piece, puts the piece in, takes it out again and leaves both lit). Then it is the child's turn.
  void _putOne() {
    final ShapeSlot? open = _nextOpen;
    if (open == null) return;
    _run++;
    final int run = _run;
    demoRunning = true;
    selected = null;
    hintSlot = open.id;
    final int fit = <int>[for (int i = 0; i < pieces.length; i++) i]
        .firstWhere((int i) => !isUsed(i) && pieces[i] == open.sprite, orElse: () => 0);
    hintPiece = fit;
    const int taken = 850; // the hand is at the piece
    const int put = 1300; // and in the place
    const int over = 2800;
    final ActivitySpec? spec = _spec;
    if (spec != null && _canDraw) {
      final double side = math.max(44, math.min(84, spec.tilesWidth / math.max(1, pieces.length) - 8));
      _hint.play(
        handTourPlan(<HandStop>[
          HandStop(spec.tileTip(pieces.length, fit, slot: side + 8, slop: 4), taken),
          HandStop(slotRect(_size, open).center, over - taken),
        ]),
      );
    }
    later(const Duration(milliseconds: put), () {
      if (run != _run) return;
      filled.add(open.id);
      usedPieces.add(fit);
      _demoSlot = open.id;
      _demoPiece = fit;
      notify();
    });
    later(const Duration(milliseconds: over), () {
      if (run != _run) return;
      filled.remove(open.id);
      usedPieces.remove(fit);
      _demoSlot = null;
      _demoPiece = null;
      demoRunning = false;
      notify();
      controller.demoDone();
    });
    notify();
  }

  // ---- drawing ----

  @override
  Widget buildStage(BuildContext context, Size size, ActivitySpec spec) {
    _size = size;
    _spec = spec;
    return ListenableBuilder(
      listenable: this,
      builder: (BuildContext c, Widget? _) => _BuilderStage(this, size),
    );
  }

  @override
  Widget? buildHands(BuildContext context, Size size, ActivitySpec spec) => _hint.hands(size, spec);

  @override
  Widget? buildTiles(BuildContext context, ActivitySpec spec) => ListenableBuilder(
    listenable: this,
    builder: (BuildContext c, Widget? _) {
      final double side = math.max(44, math.min(84, spec.tilesWidth / math.max(1, pieces.length) - 8));
      return Row(
        key: const Key('shape-tray'),
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          for (final (int i, String p) in pieces.indexed)
            if (!isUsed(i))
              Draggable<int>(
                key: Key('piece-$i'),
                data: i,
                maxSimultaneousDrags: _busy ? 0 : 1,
                feedback: SizedBox(width: side, height: side, child: PackSvg(activity.assets.svg(p))),
                childWhenDragging: Opacity(opacity: 0.25, child: _tile(i, p, side)),
                child: _tile(i, p, side),
              )
            else
              SizedBox(width: side + 8, height: side),
        ],
      );
    },
  );

  Widget _tile(int i, String p, double side) => AnswerTile(
    semanticLabel: p,
    size: side,
    slop: 4,
    state: selected == i || hintPiece == i ? AnswerState.selected : AnswerState.idle,
    onPressed: () => select(i),
    child: Padding(padding: const EdgeInsets.all(6), child: PackSvg(activity.assets.svg(p))),
  );
}

class _BuilderStage extends StatelessWidget {
  const _BuilderStage(this.s, this.size);

  final ShapeBuilderSession s;
  final Size size;

  @override
  Widget build(BuildContext context) {
    final ShapeBuilderActivity a = s.activity;
    final Rect box = s.pictureBox(size);
    final double w = box.width;
    final double h = box.height;
    return Semantics(
      container: true,
      label: a.altText,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(TokenRadius.lg),
        child: Stack(
          key: const Key('builder-stage'),
          children: <Widget>[
            if (a.background != null)
              Positioned.fill(child: PackSvg(a.assets.svg(a.background!), fit: BoxFit.cover)),
            Positioned(
              left: box.left,
              top: box.top,
              width: w,
              height: h,
              // A picture is drawn as it is, left to right, whatever the language.
              child: Directionality(
                textDirection: TextDirection.ltr,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: <Widget>[for (final ShapeSlot slot in a.slots) _slot(slot, w, h)],
                ),
              ),
            ),
            Positioned.fill(child: s._hint.body(size)),
          ],
        ),
      ),
    );
  }

  /// How much of its square picture a shape fills (width, height as shares of the side), so that a touch or a drop only counts
  /// on the shape itself and not on the empty corners of its square, where another shape may stand.
  static (double, double) _visible(String sprite) {
    if (sprite.contains('shape_circle')) return (0.76, 0.76);
    if (sprite.contains('shape_square')) return (0.72, 0.72);
    if (sprite.contains('shape_triangle')) return (0.8, 0.72);
    if (sprite.contains('shape_rect')) return (0.88, 0.44);
    return (1, 1);
  }

  Widget _slot(ShapeSlot slot, double w, double h) {
    final ShapeBuilderActivity a = s.activity;
    final bool done = s.filled.contains(slot.id);
    final (double, double) vis = _visible(slot.sprite);
    final Widget shape = done
        ? PackSvg(a.assets.svg(slot.sprite))
        : ColorFiltered(
            colorFilter: const ColorFilter.mode(Color(0x33000000), BlendMode.srcIn),
            child: PackSvg(a.assets.svg(slot.sprite)),
          );
    return Positioned(
      left: slot.x * w,
      top: slot.y * h,
      width: slot.w * w,
      height: slot.h * h,
      // The picture and its place turn together, so the place is where the turned shape is.
      child: Transform.rotate(
        angle: slot.rot * math.pi / 180,
        child: Stack(
          children: <Widget>[
            Positioned.fill(child: IgnorePointer(child: shape)),
            Positioned.fill(
              child: FractionallySizedBox(
                widthFactor: vis.$1,
                heightFactor: vis.$2,
                child: DragTarget<int>(
                  onWillAcceptWithDetails: (DragTargetDetails<int> d) => !done,
                  onAcceptWithDetails: (DragTargetDetails<int> d) => s.drop(d.data, slot.id),
                  builder: (BuildContext context, List<int?> candidate, List<dynamic> rejected) {
                    final Color? ring = s.notYetSlot == slot.id
                        ? TokenColors.notYetRing
                        : (candidate.isNotEmpty || s.hintSlot == slot.id ? TokenColors.hintHalo : null);
                    return GestureDetector(
                      key: Key('slot-${slot.id}'),
                      behavior: HitTestBehavior.opaque,
                      onTap: () => s.tapSlot(slot.id),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: ring == null ? null : Border.all(color: ring, width: 4),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
