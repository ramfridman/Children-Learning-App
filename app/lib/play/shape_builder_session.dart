import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../child/activity_shell.dart';
import '../content/models.dart';
import '../design/components.dart';
import '../design/tokens.g.dart';
import 'template_session.dart';

/// The shape-builder template (T10). A picture made of shapes stands on the stage as silhouettes; the shapes wait in the tray
/// below. A shape is touched and then its place is touched, or it is dragged there. A shape that belongs there snaps in, turned
/// the way the picture needs it (the child never has to turn anything); one that does not is a gentle "not yet" and goes back.
/// After three wrong tries only the right place takes the shape, and the help points at it.
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

  AnswerState ring = AnswerState.idle;
  bool _busy = false;

  late final List<String> pieces = activity.pieces;

  /// The tray pieces that have been used (the first of each shape that has been placed).
  final Set<int> usedPieces = <int>{};

  bool isUsed(int i) => usedPieces.contains(i);

  void select(int piece) {
    if (_busy || ring == AnswerState.correct || isUsed(piece)) return;
    selected = selected == piece ? null : piece;
    notify();
  }

  void tapSlot(String slotId) {
    final int? s = selected;
    if (s != null) drop(s, slotId);
  }

  Future<void> drop(int piece, String slotId) async {
    if (_busy || ring == AnswerState.correct || isUsed(piece) || filled.contains(slotId)) return;
    final ShapeSlot slot = activity.slots.firstWhere((ShapeSlot s) => s.id == slotId);
    if (pieces[piece] == slot.sprite) {
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
      _point(piece);
      return;
    }
    _busy = true;
    notYetSlot = slotId;
    notify();
    await controller.submitPlacement(
      right: false,
      tag: activity.wrongTag ?? '',
      response: '${pieces[piece]}>$slotId',
    );
    if (disposed) return;
    later(TemplateSession.notYetPause, () {
      notYetSlot = null;
      selected = null;
      _busy = false;
      if (controller.guided) _point(piece);
      notify();
    });
  }

  Future<void> _done() async {
    _busy = true;
    await controller.submitPlacement(right: true, response: 'built');
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
    filled.clear();
    usedPieces.clear();
    selected = null;
    hintSlot = null;
    hintPiece = null;
    notYetSlot = null;
    ring = AnswerState.idle;
    _busy = false;
    notify();
  }

  @override
  void onReplay() {
    hintSlot = null;
    hintPiece = null;
    notify();
  }

  @override
  void onHint() {
    if (_busy && !controller.guided) return;
    _point(selected ?? 0);
  }

  // ---- drawing ----

  @override
  Widget buildStage(BuildContext context, Size size, ActivitySpec spec) =>
      ListenableBuilder(listenable: this, builder: (BuildContext c, Widget? _) => _BuilderStage(this, size));

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
    final double maxW = size.width - 16;
    final double maxH = size.height - 12;
    final double w = math.min(maxW, maxH * a.aspect);
    final double h = w / a.aspect;
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
              left: (size.width - w) / 2,
              top: (size.height - h) / 2,
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
