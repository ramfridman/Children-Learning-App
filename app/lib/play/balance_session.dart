import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../child/activity_shell.dart';
import '../content/hint_ladder.dart';
import '../content/models.dart';
import '../design/components.dart';
import '../design/tokens.g.dart';
import 'sprite_group.dart';
import 'template_session.dart';

/// The balance template (T08). A scale with two pans. In `compare` mode the child says which pan is heavier, or that they are the
/// same: the three tiles are drawn left to right (left pan, same, right pan). In `balance` mode the right pan is lighter and
/// the child adds blocks to it one at a time; when the scale is level the task is done. A block can be taken off again.
///
/// When the task is to weigh, the beam leans as the weights say; when a sum is being compared (`hideTilt`) it stays level
/// until the child has answered, because the lean would give the answer away. The hints before the worked example never let it
/// lean; the worked example does, slowly, and then marks the tile.
class BalanceSession extends TemplateSession {
  BalanceSession(super.controller, this.activity);

  final BalanceActivity activity;

  /// Blocks the child has put on the right pan (balance mode).
  int added = 0;

  /// The tile that was chosen last, in compare mode.
  String? chosen;
  AnswerState ring = AnswerState.idle;
  bool revealed = false;
  bool _busy = false;

  /// The pan the light of hint 1 is on (`left` or `right`), and whether hint 2 lights both with a level line across the beam.
  String? litPan;
  bool levelLine = false;
  bool demoRunning = false;
  int _run = 0;

  int get leftWeight => BalanceActivity.weightOf(activity.left);
  int get rightWeight => BalanceActivity.weightOf(activity.right) + added;

  /// How far the beam leans, in radians (negative: the left pan is lower). Clamped at about 18 degrees, so that a heavy pan
  /// never looks like it falls off.
  double get lean {
    if (activity.hideTilt && !revealed && ring != AnswerState.correct) return 0;
    return ((rightWeight - leftWeight) * 0.07).clamp(-0.32, 0.32);
  }

  /// A touch of the child ends the guide's demonstration at once and the child's move is taken.
  void _endDemo() {
    if (!demoRunning) return;
    _run++;
    demoRunning = false;
    if (activity.weigh) added = 0;
    controller.demoDone();
  }

  Future<void> choose(String which) async {
    _endDemo();
    if (_busy || ring == AnswerState.correct || activity.weigh) return;
    if (controller.guided && which != activity.result) {
      if (controller.answerShown) {
        chosen = activity.result;
        revealed = true;
      }
      notify();
      return;
    }
    _busy = true;
    chosen = which;
    final bool right = which == activity.result;
    await controller.submitPlacement(
      right: right,
      tag: right ? '' : (activity.wrongTag ?? ''),
      response: which,
    );
    if (disposed) return;
    if (right) {
      ring = AnswerState.correct;
      revealed = true;
      notify();
      later(TemplateSession.praisePause, controller.next);
      return;
    }
    ring = AnswerState.notYet;
    notify();
    later(TemplateSession.notYetPause, () {
      ring = AnswerState.idle;
      chosen = null;
      _busy = false;
      if (controller.answerShown) {
        revealed = true;
        chosen = activity.result;
      }
      notify();
    });
  }

  Future<void> addBlock() async {
    _endDemo();
    if (_busy || ring == AnswerState.correct || !activity.weigh) return;
    added++;
    notify();
    final int need = int.parse(activity.result);
    if (added == need) {
      _busy = true;
      await controller.submitPlacement(right: true, response: '$added');
      if (disposed) return;
      ring = AnswerState.correct;
      notify();
      later(TemplateSession.praisePause, controller.next);
    }
  }

  void removeBlock() {
    _endDemo();
    if (_busy || ring == AnswerState.correct || added == 0) return;
    added--;
    notify();
  }

  @override
  void onReset() {
    _run++;
    added = 0;
    chosen = null;
    revealed = false;
    litPan = null;
    levelLine = false;
    demoRunning = false;
    ring = AnswerState.idle;
    _busy = false;
    notify();
  }

  @override
  void onReplay() {
    _run++;
    litPan = null;
    levelLine = false;
    notify();
  }

  @override
  void onHint() {
    if (demoRunning) return;
    switch (hintPictureOf(activity)) {
      case HintPicture.eachPan:
        _lightPans();
      case HintPicture.levelLine:
        _run++;
        litPan = 'both';
        levelLine = true;
        notify();
      default:
        _workedExample();
    }
  }

  /// Hint 1: the light goes to the left pan, then to the right one, and rests on none. The beam does not move.
  void _lightPans() {
    _run++;
    final int run = _run;
    levelLine = false;
    litPan = 'left';
    later(const Duration(milliseconds: 900), () {
      if (run != _run) return;
      litPan = 'right';
      notify();
    });
    later(const Duration(milliseconds: 1800), () {
      if (run != _run) return;
      litPan = null;
      notify();
    });
    notify();
  }

  /// The worked example. Comparing: the beam is let go and leans slowly, and then the tile of the side that is lower is marked.
  /// Weighing: the blocks go on the right pan one by one and come off again.
  void _workedExample() {
    _run++;
    final int run = _run;
    demoRunning = true;
    litPan = null;
    levelLine = false;
    if (activity.weigh) {
      final int need = int.parse(activity.result);
      added = 0;
      for (int k = 1; k <= need; k++) {
        later(Duration(milliseconds: 700 * k), () {
          if (run != _run) return;
          added = k;
          notify();
        });
      }
      later(Duration(milliseconds: 700 * need + 1400), () {
        if (run != _run) return;
        added = 0;
        demoRunning = false;
        notify();
        controller.demoDone();
      });
    } else {
      later(const Duration(milliseconds: 400), () {
        if (run != _run) return;
        revealed = true;
        notify();
      });
      later(const Duration(milliseconds: 2400), () {
        if (run != _run) return;
        chosen = activity.result;
        demoRunning = false;
        notify();
        controller.demoDone();
      });
    }
    notify();
  }

  // ---- drawing ----

  @override
  Widget buildStage(BuildContext context, Size size, ActivitySpec spec) =>
      ListenableBuilder(listenable: this, builder: (BuildContext c, Widget? _) => _ScaleStage(this, size));

  @override
  Widget? buildTiles(BuildContext context, ActivitySpec spec) => ListenableBuilder(
    listenable: this,
    builder: (BuildContext c, Widget? _) => Directionality(
      textDirection: TextDirection.ltr,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: activity.weigh
            ? <Widget>[
                AnswerTile(
                  key: const Key('balance-minus'),
                  semanticLabel: 'minus',
                  size: 72,
                  onPressed: removeBlock,
                  child: const Icon(Icons.remove_rounded, size: 40, color: TokenColors.ink),
                ),
                AnswerTile(
                  key: const Key('balance-plus'),
                  semanticLabel: 'plus',
                  size: 72,
                  onPressed: addBlock,
                  child: const Icon(Icons.add_rounded, size: 44, color: TokenColors.ink),
                ),
              ]
            : <Widget>[
                for (final (String, IconData) t in <(String, IconData)>[
                  ('left', Icons.arrow_back_rounded),
                  ('same', Icons.drag_handle_rounded),
                  ('right', Icons.arrow_forward_rounded),
                ])
                  AnswerTile(
                    key: Key('balance-${t.$1}'),
                    semanticLabel: t.$1,
                    size: 80,
                    state: chosen == t.$1
                        ? (ring == AnswerState.notYet
                              ? AnswerState.notYet
                              : (ring == AnswerState.correct ? AnswerState.correct : AnswerState.selected))
                        : AnswerState.idle,
                    onPressed: () => choose(t.$1),
                    child: Icon(t.$2, size: 44, color: TokenColors.ink),
                  ),
              ],
      ),
    ),
  );
}

class _ScaleStage extends StatelessWidget {
  const _ScaleStage(this.s, this.size);

  final BalanceSession s;
  final Size size;

  @override
  Widget build(BuildContext context) {
    final BalanceActivity a = s.activity;
    final double cx = size.width / 2;
    final double half = math.min(size.width * 0.36, 130);
    final double beamY = size.height * 0.3;
    final double panW = half * 0.78;
    final double panH = size.height * 0.4;
    return Semantics(
      container: true,
      label: a.altText,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(TokenRadius.lg),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: TweenAnimationBuilder<double>(
            key: const Key('scale-stage'),
            tween: Tween<double>(end: s.lean),
            duration: Duration(milliseconds: s.demoRunning ? 1200 : 600),
            curve: Curves.easeInOut,
            builder: (BuildContext context, double lean, Widget? _) {
              final double angle = lean;
              final Offset rightEnd = Offset(cx + half * math.cos(angle), beamY + half * math.sin(angle));
              final Offset leftEnd = Offset(cx - half * math.cos(angle), beamY - half * math.sin(angle));
              return Stack(
                children: <Widget>[
                  if (a.background != null)
                    Positioned.fill(child: PackSvg(a.assets.svg(a.background!), fit: BoxFit.cover)),
                  // the stand
                  Positioned(
                    left: cx - 5,
                    top: beamY,
                    width: 10,
                    height: size.height - beamY - 6,
                    child: const DecoratedBox(decoration: BoxDecoration(color: TokenColors.worldWoodLight)),
                  ),
                  Positioned(
                    left: cx - 30,
                    top: size.height - 12,
                    width: 60,
                    height: 8,
                    child: const DecoratedBox(decoration: BoxDecoration(color: TokenColors.worldWoodLight)),
                  ),
                  // the beam
                  Positioned(
                    left: cx - half,
                    top: beamY - 4,
                    width: half * 2,
                    height: 8,
                    child: Transform.rotate(
                      angle: angle,
                      child: const DecoratedBox(
                        decoration: BoxDecoration(
                          color: TokenColors.ink,
                          borderRadius: BorderRadius.all(Radius.circular(4)),
                        ),
                      ),
                    ),
                  ),
                  if (s.levelLine)
                    Positioned(
                      key: const Key('level-line'),
                      left: cx - half - 14,
                      width: half * 2 + 28,
                      top: beamY - 1.5,
                      height: 3,
                      child: const DecoratedBox(decoration: BoxDecoration(color: TokenColors.hintHalo)),
                    ),
                  _pan(
                    leftEnd,
                    panW,
                    panH,
                    a.left,
                    <PanGroup>[],
                    0,
                    s.litPan == 'left' || s.litPan == 'both',
                  ),
                  _pan(
                    rightEnd,
                    panW,
                    panH,
                    a.right,
                    <PanGroup>[],
                    s.added,
                    s.litPan == 'right' || s.litPan == 'both',
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  /// A pan hanging from the end of the beam: a plate, and what lies on it.
  Widget _pan(
    Offset end,
    double w,
    double h,
    List<PanGroup> groups,
    List<PanGroup> unused,
    int blocks,
    bool lit,
  ) {
    final BalanceActivity a = s.activity;
    final List<Widget> piles = <Widget>[
      for (final PanGroup g in groups)
        Expanded(
          child: SpriteGroup(svg: a.assets.svg(g.sprite), count: g.count, arrangement: 'line'),
        ),
      if (blocks > 0 && a.blockSprite != null)
        Expanded(
          child: SpriteGroup(
            key: const Key('scale-blocks'),
            svg: a.assets.svg(a.blockSprite!),
            count: math.min(blocks, 12),
            arrangement: 'line',
          ),
        ),
    ];
    return Positioned(
      left: end.dx - w / 2,
      top: end.dy + 6,
      width: w,
      height: h,
      child: DecoratedBox(
        key: lit ? const Key('pan-lit') : null,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(TokenRadius.lg),
          border: lit ? Border.all(color: TokenColors.hintHalo, width: 4) : null,
        ),
        child: Column(
          children: <Widget>[
            Expanded(child: Row(children: piles)),
            Container(
              height: 8,
              decoration: BoxDecoration(
                color: TokenColors.worldWoodLight,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
