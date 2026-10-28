import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../child/activity_shell.dart';
import '../content/models.dart';
import '../design/app_text.dart';
import '../design/components.dart';
import '../design/tokens.g.dart';
import 'lesson_controller.dart';
import 'response_code.dart';
import 'template_session.dart';

/// The build-a-pattern template (T05): the pattern to copy is shown above, empty places below, and the pictures to put in
/// them wait in the palette. A touch on a palette picture fills the next empty place, a drag puts it in a chosen place, and a
/// touch on a filled place empties it. When every place is filled the answer is checked. A wrong pattern empties the
/// places ("not yet"); after three tries only the right picture is taken, and the help points at it.
///
/// A pattern is read from the left, whatever the language, so the rows are drawn left to right.
class BuildPatternSession extends TemplateSession {
  BuildPatternSession(super.controller, this.activity) : filled = List<String?>.filled(activity.slots, null);

  final BuildPatternActivity activity;

  /// What stands in each place now (an asset reference), or null.
  final List<String?> filled;

  /// The palette picture and the place that the help points at.
  String? hintSprite;
  int? hintSlot;

  AnswerState ring = AnswerState.idle;
  bool _busy = false;

  int? get _firstEmpty {
    final int i = filled.indexOf(null);
    return i < 0 ? null : i;
  }

  /// Puts [sprite] in place [at], or in the next empty place.
  Future<void> place(String sprite, {int? at}) async {
    if (_busy || ring == AnswerState.correct) return;
    final int? target = at ?? _firstEmpty;
    if (target == null) return;
    // With only the right picture left, another one is not taken; the help shows the right one.
    if (controller.guided && sprite != activity.sequence[target]) {
      _point(target);
      return;
    }
    filled[target] = sprite;
    hintSprite = null;
    hintSlot = null;
    notify();
    if (!filled.contains(null)) await _check();
  }

  void clear(int i) {
    if (_busy || ring == AnswerState.correct || filled[i] == null) return;
    filled[i] = null;
    notify();
  }

  Future<void> _check() async {
    _busy = true;
    final bool right = <int>[for (int i = 0; i < filled.length; i++) i]
        .every((int i) => filled[i] == activity.sequence[i]);
    final Outcome o = await controller.submitPlacement(
      right: right,
      tag: right ? '' : (activity.wrongTag ?? ''),
      response: ResponseCode.pattern(<int?>[
        for (final String? f in filled) f == null ? null : activity.palette.indexOf(f),
      ]),
    );
    if (disposed) return;
    if (o.correct) {
      ring = AnswerState.correct;
      notify();
      later(TemplateSession.praisePause, controller.next);
    } else {
      ring = AnswerState.notYet;
      notify();
      later(TemplateSession.notYetPause, () {
        ring = AnswerState.idle;
        for (int i = 0; i < filled.length; i++) {
          filled[i] = null;
        }
        _busy = false;
        if (controller.guided) _point(0);
        notify();
      });
    }
  }

  void _point(int slot) {
    hintSlot = slot;
    hintSprite = activity.sequence[slot];
    notify();
  }

  @override
  void onReset() {
    for (int i = 0; i < filled.length; i++) {
      filled[i] = null;
    }
    hintSprite = null;
    hintSlot = null;
    ring = AnswerState.idle;
    _busy = false;
    notify();
  }

  @override
  void onReplay() {
    hintSprite = null;
    hintSlot = null;
    notify();
  }

  @override
  void onHint() {
    final int? next = _firstEmpty;
    if (next != null && !_busy) _point(next);
  }

  // ---- drawing ----

  @override
  Widget buildStage(BuildContext context, Size size, ActivitySpec spec) =>
      ListenableBuilder(listenable: this, builder: (BuildContext c, Widget? _) => _PatternStage(this, size));

  @override
  Widget? buildTiles(BuildContext context, ActivitySpec spec) => ListenableBuilder(
    listenable: this,
    builder: (BuildContext c, Widget? _) {
      final double side = math.min(96, spec.tilesWidth / activity.palette.length - 16);
      return Row(
        key: const Key('pattern-palette'),
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          for (final (int i, String p) in activity.palette.indexed)
            Draggable<String>(
              key: Key('palette-$i'),
              data: p,
              maxSimultaneousDrags: _busy ? 0 : 1,
              feedback: SizedBox(width: side, height: side, child: PackSvg(activity.assets.svg(p))),
              childWhenDragging: Opacity(opacity: 0.3, child: _tile(p, side)),
              child: _tile(p, side),
            ),
        ],
      );
    },
  );

  Widget _tile(String p, double side) => AnswerTile(
    semanticLabel: p,
    size: side,
    slop: 6,
    state: hintSprite == p ? AnswerState.selected : AnswerState.idle,
    onPressed: () => place(p),
    child: Padding(padding: const EdgeInsets.all(8), child: PackSvg(activity.assets.svg(p))),
  );
}

class _PatternStage extends StatelessWidget {
  const _PatternStage(this.s, this.size);

  final BuildPatternSession s;
  final Size size;

  @override
  Widget build(BuildContext context) {
    final BuildPatternActivity a = s.activity;
    return Semantics(
      container: true,
      label: a.altText,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(TokenRadius.lg),
        child: Stack(
          key: const Key('pattern-stage'),
          children: <Widget>[
            if (a.background != null)
              Positioned.fill(child: PackSvg(a.assets.svg(a.background!), fit: BoxFit.cover)),
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Directionality(
                  textDirection: TextDirection.ltr,
                  child: Column(
                    children: <Widget>[
                      if (a.model.isNotEmpty)
                        Expanded(
                          child: Row(
                            key: const Key('pattern-model'),
                            children: <Widget>[
                              for (final String m in a.model)
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.all(3),
                                    child: PackSvg(a.assets.svg(m)),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      Expanded(
                        child: Row(
                          key: const Key('pattern-slots'),
                          children: <Widget>[for (int i = 0; i < a.slots; i++) Expanded(child: _slot(i))],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _slot(int i) {
    final BuildPatternActivity a = s.activity;
    final String? picture = s.filled[i];
    return DragTarget<String>(
      onWillAcceptWithDetails: (DragTargetDetails<String> d) => true,
      onAcceptWithDetails: (DragTargetDetails<String> d) => s.place(d.data, at: i),
      builder: (BuildContext context, List<String?> candidate, List<dynamic> rejected) {
        final Color? ring = s.ring == AnswerState.notYet
            ? TokenColors.notYetRing
            : (s.ring == AnswerState.correct
                  ? TokenColors.correctGlow
                  : (candidate.isNotEmpty || s.hintSlot == i ? TokenColors.hintHalo : null));
        return GestureDetector(
          key: Key('slot-$i'),
          behavior: HitTestBehavior.opaque,
          onTap: () => s.clear(i),
          child: Padding(
            padding: const EdgeInsets.all(3),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: TokenColors.paper.withValues(alpha: picture == null ? 0.7 : 0.95),
                borderRadius: BorderRadius.circular(TokenRadius.lg),
                border: Border.all(color: ring ?? TokenColors.hairline, width: ring == null ? 3 : 5),
              ),
              child: picture == null
                  ? Center(child: Text('?', style: AppText.fixed(size: 26, weight: 800, lineHeight: 1)))
                  : Padding(padding: const EdgeInsets.all(4), child: PackSvg(a.assets.svg(picture))),
            ),
          ),
        );
      },
    );
  }
}
