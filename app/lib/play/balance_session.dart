import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../child/activity_shell.dart';
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
/// until the child has answered, because the lean would give the answer away.
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

  int get leftWeight => BalanceActivity.weightOf(activity.left);
  int get rightWeight => BalanceActivity.weightOf(activity.right) + added;

  /// How far the beam leans, in turns of the beam (negative: the left pan is lower). Clamped so that a heavy pan never looks
  /// like it falls off.
  double get lean {
    if (activity.hideTilt && !revealed && ring != AnswerState.correct) return 0;
    return ((rightWeight - leftWeight) * 0.07).clamp(-0.32, 0.32);
  }

  Future<void> choose(String which) async {
    if (_busy || ring == AnswerState.correct || activity.weigh) return;
    if (controller.guided && which != activity.result) {
      chosen = activity.result;
      revealed = true;
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
      if (controller.guided) {
        revealed = true;
        chosen = activity.result;
      }
      notify();
    });
  }

  Future<void> addBlock() async {
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
    if (_busy || ring == AnswerState.correct || added == 0) return;
    added--;
    notify();
  }

  @override
  void onReset() {
    added = 0;
    chosen = null;
    revealed = false;
    ring = AnswerState.idle;
    _busy = false;
    notify();
  }

  @override
  void onReplay() {}

  @override
  void onHint() {
    // The help lets the beam lean, so the child can see which side is lower.
    revealed = true;
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
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeInOut,
            builder: (BuildContext context, double lean, Widget? _) {
              final double angle = lean * 2 * math.pi;
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
                  _pan(leftEnd, panW, panH, a.left, <PanGroup>[], 0),
                  _pan(rightEnd, panW, panH, a.right, <PanGroup>[], s.added),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  /// A pan hanging from the end of the beam: a plate, and what lies on it.
  Widget _pan(Offset end, double w, double h, List<PanGroup> groups, List<PanGroup> unused, int blocks) {
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
    );
  }
}
