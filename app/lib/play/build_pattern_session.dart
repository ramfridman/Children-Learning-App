import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../child/activity_shell.dart';
import '../content/hint_ladder.dart';
import '../content/models.dart';
import '../design/app_text.dart';
import '../design/components.dart';
import '../design/tokens.g.dart';
import 'hint_widgets.dart';
import 'hints/hint_marks.dart';
import 'hints/hint_pictures.dart' show hintScale;
import 'hints/hint_player.dart';
import 'hints/pointer_plans.dart';
import 'hints/tile_points.dart';
import 'lesson_controller.dart';
import 'response_code.dart';
import 'template_session.dart';

/// The build-a-pattern template (T05): the pattern to copy is shown above, empty places below, and the pictures to put in
/// them wait in the palette. A touch on a palette picture fills the next empty place, a drag puts it in a chosen place, and a
/// touch on a filled place empties it. When every place is filled the answer is checked. A wrong pattern empties the
/// places ("not yet"); after three tries only the right picture is taken: the guide first fills the places as a worked example,
/// then points at the first place and its picture.
///
/// A pattern is read from the left, whatever the language, so the rows are drawn left to right.
class BuildPatternSession extends TemplateSession {
  BuildPatternSession(super.controller, this.activity) : filled = List<String?>.filled(activity.slots, null);

  final BuildPatternActivity activity;

  /// What stands in each place now (an asset reference), or null.
  final List<String?> filled;

  /// The palette picture and the place that the help points at. A place alone is "where", a picture is "what": the picture is
  /// pointed at only at the end of the worked example.
  String? hintSprite;
  int? hintSlot;

  /// The cell of the model that the light is on (hint 1 walks along the model, hint 2 stays on the one above the next place).
  int? litModel;
  bool demoRunning = false;
  int _run = 0;

  /// The pointing hand and the brackets of the unit (B-40), and the stage's and the board's sizes they are placed by.
  late final HintPlayer _hint = HintPlayer(this);
  Size _size = Size.zero;
  ActivitySpec? _spec;

  AnswerState ring = AnswerState.idle;
  bool _busy = false;

  bool get _canDraw => _spec != null && !_size.isEmpty;

  /// The cell [i] of a row of [n] cells in the row whose top is [top] and whose height is [height]: the row fills the stage 8 in,
  /// each cell has 3 around it, and the rows are drawn left to right (a pattern is read from the left, whatever the language).
  static Rect cell(Size size, int n, int i, {required double top, required double height}) {
    final double w = (size.width - 16) / n;
    return Rect.fromLTWH(8 + i * w + 3, top + 3, w - 6, height - 6);
  }

  /// The cells of the model row (above), and of the row of places (below it, or alone when there is no model).
  static Rect modelCell(Size size, int n, int i) => cell(size, n, i, top: 8, height: (size.height - 16) / 2);

  static Rect slotCell(Size size, int slots, int i, {required bool hasModel}) {
    final double row = hasModel ? (size.height - 16) / 2 : size.height - 16;
    return cell(size, slots, i, top: hasModel ? 8 + row : 8, height: row);
  }

  /// The length of the unit that repeats in [row] (the smallest one that is repeated at least once), or null when none does.
  static int? unitLength(List<String> row) {
    for (int p = 1; p <= row.length ~/ 2; p++) {
      if (<int>[for (int i = p; i < row.length; i++) i].every((int i) => row[i] == row[i - p])) return p;
    }
    return null;
  }

  /// The fingertip place on the top edge of the palette picture [sprite].
  Offset _paletteTip(ActivitySpec spec, String sprite) {
    final int n = activity.palette.length;
    final double side = math.min(96, spec.tilesWidth / n - 16);
    return spec.tileTip(n, math.max(0, activity.palette.indexOf(sprite)), slot: side + 12, slop: 6);
  }

  int? get _firstEmpty {
    final int i = filled.indexOf(null);
    return i < 0 ? null : i;
  }

  /// A touch of the child ends the guide's demonstration at once, and the child's move is taken: the halo may show then.
  void _endDemo() {
    if (!demoRunning) return;
    _stopHint();
    for (int i = 0; i < filled.length; i++) {
      filled[i] = null;
    }
    demoRunning = false;
    controller.demoDone();
  }

  /// Puts [sprite] in place [at], or in the next empty place.
  Future<void> place(String sprite, {int? at}) async {
    _endDemo();
    if (_busy || ring == AnswerState.correct) return;
    final int? target = at ?? _firstEmpty;
    if (target == null) return;
    // With only the right picture left, another one is not taken; the help shows the right one.
    if (controller.guided && sprite != activity.sequence[target]) {
      if (controller.answerShown) _point(target);
      return;
    }
    filled[target] = sprite;
    hintSprite = null;
    hintSlot = null;
    litModel = null;
    notify();
    if (!filled.contains(null)) await _check();
  }

  void clear(int i) {
    _endDemo();
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
        if (controller.answerShown) _point(0);
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
    _stopHint();
    for (int i = 0; i < filled.length; i++) {
      filled[i] = null;
    }
    ring = AnswerState.idle;
    _busy = false;
    demoRunning = false;
    notify();
  }

  void _stopHint() {
    _run++;
    _hint.clear();
    hintSprite = null;
    hintSlot = null;
    litModel = null;
  }

  @override
  void onReplay() {
    _stopHint();
    notify();
  }

  @override
  void onHint() {
    if ((_busy && !controller.guided) || demoRunning) return;
    switch (hintPictureOf(activity)) {
      case HintPicture.walkTheRow:
        _walkRow();
      case HintPicture.modelCell:
        _lineUp();
      default:
        _workedExample();
    }
  }

  /// Hint 1: the light goes along the model and then the places, in a steady rhythm, and ends on the next empty place: where to
  /// build next, not what goes there.
  void _walkRow() {
    _stopHint();
    final int run = _run;
    final int? next = _firstEmpty;
    if (next == null) return;
    const int step = 450;
    int k = 0;
    for (int m = 0; m < activity.model.length; m++) {
      later(Duration(milliseconds: step * k++), () {
        if (run != _run) return;
        litModel = m;
        notify();
      });
    }
    for (int i = 0; i <= next; i++) {
      later(Duration(milliseconds: step * k++), () {
        if (run != _run) return;
        litModel = null;
        hintSlot = i;
        notify();
      });
    }
    notify();
  }

  /// Hint 2: with a model, the cell of the model above the next place is lit: one to one, copy what is above. Without a model the
  /// pictures of the palette are lit in turn, none of them chosen.
  void _lineUp() {
    _stopHint();
    final int run = _run;
    final int? next = _firstEmpty;
    if (next == null) return;
    hintSlot = next;
    if (activity.model.isNotEmpty) {
      litModel = math.min(next, activity.model.length - 1);
      _bracketUnit();
      notify();
      return;
    }
    for (int i = 0; i < activity.palette.length; i++) {
      later(Duration(milliseconds: 600 * i), () {
        if (run != _run) return;
        hintSprite = activity.palette[i];
        notify();
      });
    }
    later(Duration(milliseconds: 600 * activity.palette.length), () {
      if (run != _run) return;
      hintSprite = null;
      notify();
    });
    notify();
  }

  /// P7: an open bracket under each copy of the unit that repeats in the model, one after the other, left to right; they stay.
  void _bracketUnit() {
    final int? unit = unitLength(activity.model);
    if (unit == null || !_canDraw) return;
    final int n = activity.model.length;
    final double k = hintScale(_size);
    final List<BracketMark> brackets = <BracketMark>[
      for (int c = 0; (c + 1) * unit <= n; c++)
        BracketMark(
          Offset(modelCell(_size, n, c * unit).left + 2 * k, modelCell(_size, n, c * unit).bottom - 3 * k),
          Offset(
            modelCell(_size, n, (c + 1) * unit - 1).right - 2 * k,
            modelCell(_size, n, (c + 1) * unit - 1).bottom - 3 * k,
          ),
        ),
    ];
    _hint.play(
      HintPlan(<HintFrame>[
        for (int c = 0; c < brackets.length; c++)
          HintFrame(brackets.sublist(0, c + 1), hold: const Duration(milliseconds: 600)),
      ], rest: brackets),
    );
  }

  /// The worked example: the pointing hand reads the model and, for each place, takes the picture that goes there and puts it in;
  /// the guide fills the places one by one, then takes them out again and points at the first place and its picture. Then it is
  /// the child's turn.
  void _workedExample() {
    _stopHint();
    final int run = _run;
    demoRunning = true;
    for (int i = 0; i < filled.length; i++) {
      filled[i] = null;
    }
    const int step = 900; // the hand takes a picture (half) and puts it in its place (half)
    const int tail = 1200;
    final ActivitySpec? spec = _spec;
    if (spec != null && _canDraw) {
      final bool hasModel = activity.model.isNotEmpty;
      final int? unit = unitLength(activity.model);
      Offset from(int i) {
        // From the model cell that the place copies (a model can be shorter than the row: then the unit goes on), else from the
        // palette picture that goes there.
        final int? m = !hasModel ? null : (i < activity.model.length ? i : (unit == null ? null : i % unit));
        return m == null
            ? _paletteTip(spec, activity.sequence[i])
            : modelCell(_size, activity.model.length, m).center;
      }

      _hint.play(
        handTourPlan(<HandStop>[
          for (int i = 0; i < activity.slots; i++) ...<HandStop>[
            HandStop(from(i), step ~/ 2),
            HandStop(slotCell(_size, activity.slots, i, hasModel: hasModel).center, step ~/ 2),
          ],
        ], tailMs: tail),
      );
    }
    for (int i = 0; i < activity.slots; i++) {
      later(Duration(milliseconds: step ~/ 2 + 400 + step * i), () {
        if (run != _run) return;
        hintSlot = i;
        litModel = i < activity.model.length ? i : null;
        filled[i] = activity.sequence[i];
        notify();
      });
    }
    later(Duration(milliseconds: step * activity.slots + tail), () {
      if (run != _run) return;
      for (int i = 0; i < filled.length; i++) {
        filled[i] = null;
      }
      litModel = null;
      demoRunning = false;
      _point(0);
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
      builder: (BuildContext c, Widget? _) => _PatternStage(this, size),
    );
  }

  @override
  Widget? buildHands(BuildContext context, Size size, ActivitySpec spec) => _hint.hands(size, spec);

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
                      if (a.model.isNotEmpty) Expanded(child: _modelRow(a)),
                      Expanded(
                        // The places come after the model, so that the child reads the model first.
                        child: RowEntrance(
                          count: a.slots,
                          startAfter: RowEntrance.step * a.model.length,
                          builder: (BuildContext context, Widget Function(int, Widget) cell) => Row(
                            key: const Key('pattern-slots'),
                            children: <Widget>[
                              for (int i = 0; i < a.slots; i++) Expanded(child: cell(i, _slot(i))),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Positioned.fill(child: s._hint.body(size)),
          ],
        ),
      ),
    );
  }

  /// The pattern to copy. Its cells come one by one from the left; the light of the hints rests on one of them at a time.
  Widget _modelRow(BuildPatternActivity a) => RowEntrance(
    count: a.model.length,
    builder: (BuildContext context, Widget Function(int, Widget) cell) => Row(
      key: const Key('pattern-model'),
      children: <Widget>[
        for (final (int i, String m) in a.model.indexed)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(3),
              child: cell(
                i,
                DecoratedBox(
                  key: s.litModel == i ? const Key('model-lit') : null,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(TokenRadius.lg),
                    border: s.litModel == i ? Border.all(color: TokenColors.hintHalo, width: 5) : null,
                  ),
                  child: Padding(padding: const EdgeInsets.all(2), child: PackSvg(a.assets.svg(m))),
                ),
              ),
            ),
          ),
      ],
    ),
  );

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
