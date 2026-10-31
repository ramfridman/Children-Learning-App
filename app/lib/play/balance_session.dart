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
import 'sprite_group.dart';
import 'template_session.dart';

/// The balance template (T08). A scale with two pans. In `compare` mode the child says which pan is heavier, or that they are the
/// same: the three tiles are drawn left to right (left pan, same, right pan). In `balance` mode the right pan is lighter and
/// the child adds blocks to it one at a time; when the scale is level the task is done. A block can be taken off again.
///
/// When the task is to weigh, the beam leans as the weights say; when a sum is being compared (`hideTilt`) it stays level
/// until the child has answered, because the lean would give the answer away. The hints before the worked example never let it
/// lean (a small peg holds it); the worked example takes the peg out and lets it lean, slowly, with the pointing hand going from the
/// lower pan to the tile, and then marks the tile.
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

  /// The pan the light of hint 1 is on (`left` or `right`).
  String? litPan;

  /// Hint 2 draws what is on each pan as a tower of cubes, so the pans show their plates only; the towers and the level line are
  /// the hint's marks.
  bool towers = false;

  /// A small peg holds a beam whose lean is hidden, from the first hint on, and slides out when the beam is let go.
  bool pegShown = false;
  bool demoRunning = false;
  int _run = 0;

  /// The pointing hand, the towers and the line, and the places of the stage they are drawn by (see [HintPlayer]).
  late final HintPlayer _hint = HintPlayer(this);
  Size _size = Size.zero;
  ActivitySpec _spec = ActivitySpec.phone;

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
    _hint.clear();
    demoRunning = false;
    if (activity.weigh) added = 0;
    controller.demoDone();
  }

  /// A move of the child takes the hint's picture off the stage: the pans show what is on them again.
  void _clearHint() {
    _hint.clear();
    towers = false;
  }

  Future<void> choose(String which) async {
    _endDemo();
    _clearHint();
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
    _clearHint();
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
    _clearHint();
    if (_busy || ring == AnswerState.correct || added == 0) return;
    added--;
    notify();
  }

  @override
  void onReset() {
    _run++;
    _clearHint();
    added = 0;
    chosen = null;
    revealed = false;
    litPan = null;
    pegShown = false;
    demoRunning = false;
    ring = AnswerState.idle;
    _busy = false;
    notify();
  }

  @override
  void onReplay() {
    _run++;
    _clearHint();
    litPan = null;
    notify();
  }

  @override
  void onHint() {
    if (demoRunning) return;
    if (activity.hideTilt && !activity.weigh) pegShown = true;
    switch (hintPictureOf(activity)) {
      case HintPicture.eachPan:
        _lightPans();
      case HintPicture.towers:
        _showTowers();
      default:
        _workedExample();
    }
  }

  /// Hint 1: the light goes to the left pan, then to the right one, and rests on none. The beam does not move.
  void _lightPans() {
    _run++;
    final int run = _run;
    _clearHint();
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

  /// Hint 2: what is on each pan is drawn again as a tower of cubes, one cube for each unit of weight; the pans' own things give
  /// way to the towers. The beam does not move, and no side is marked.
  void _showTowers() {
    _run++;
    litPan = null;
    towers = true;
    _hint.play(HintPlan(const <HintFrame>[], rest: _towerMarks()));
    notify();
  }

  // ---- the places of the stage, as it draws them ----

  /// How many cubes a column of a tower holds at most: the towers of both pans have as many columns as the heavier one needs, so
  /// that a taller tower is always the heavier one.
  static const int _column = 5;

  /// The towers of cubes (and, to weigh, the empty places that are still to fill), and the dotted line that makes the lean or the
  /// level visible: across the tops of the towers when the pans are level (a hidden lean), through the pivot when the beam leans.
  List<HintMark> _towerMarks() {
    final _ScaleBox g = _ScaleBox(_size);
    final double k = hintScale(_size);
    final double angle = lean;
    final List<Offset> ends = <Offset>[g.leftEnd(angle), g.rightEnd(angle)];
    final List<int> weights = <int>[leftWeight, rightWeight];
    final int most = math.max(weights[0], weights[1]);
    final int cols = math.max(1, (most + _column - 1) ~/ _column);
    final int rows = math.max(1, (most + cols - 1) ~/ cols);
    final double side = math.min(10 * k, (g.panH - 12) / rows);
    final double pitch = side + 1.5;
    final double width = cols * pitch - 1.5;
    Rect cube(Offset end, int i) => Rect.fromLTWH(
      end.dx - width / 2 + (i % cols) * pitch,
      g.plateTop(end) - ((i ~/ cols) + 1) * pitch + 1.5,
      side,
      side,
    );
    final List<HintMark> marks = <HintMark>[];
    for (int p = 0; p < 2; p++) {
      for (int i = 0; i < weights[p]; i++) {
        marks.add(BlockMark(cube(ends[p], i)));
      }
    }
    if (activity.weigh) {
      // The cubes that the lighter pan still needs, as empty places.
      for (int i = weights[1]; i < weights[0]; i++) {
        marks.add(BlockMark(cube(ends[1], i), empty: true));
      }
    }
    if (activity.hideTilt && !activity.weigh) {
      // The pans are level, so the towers stand on one floor: the line runs across the top of the shorter one to the taller.
      final double top = g.plateTop(ends[0]) - (math.min(weights[0], weights[1]) + cols - 1) ~/ cols * pitch;
      marks.add(LineMark(Offset(ends[0].dx - width / 2 - 6, top), Offset(ends[1].dx + width / 2 + 6, top)));
    } else {
      marks.add(LineMark(Offset(g.cx - g.half - 14, g.beamY), Offset(g.cx + g.half + 14, g.beamY)));
    }
    return marks;
  }

  /// The fingertip place on pan [p] (0 left, 1 right) when the beam is at [angle]: its middle.
  Offset _panTip(double angle, int p) {
    final _ScaleBox g = _ScaleBox(_size);
    final Offset end = p == 0 ? g.leftEnd(angle) : g.rightEnd(angle);
    return Offset(end.dx, end.dy + 6 + g.panH / 2);
  }

  /// The worked example. Comparing: the peg slides out and the beam is let go and leans slowly, the pointing hand goes to the pan
  /// that is lower (to both when they are level) and then to the tile that points the same way, and then the tile is marked.
  /// Weighing: the hand presses the plus tile and the blocks go on the right pan one by one until the scale is level, and come
  /// off again.
  void _workedExample() {
    _run++;
    final int run = _run;
    _clearHint();
    demoRunning = true;
    litPan = null;
    if (activity.weigh) {
      final int need = int.parse(activity.result);
      added = 0;
      final Offset plus = _spec.tileTip(2, 1, slot: 96, slop: 12, rtl: false);
      final _ScaleBox g = _ScaleBox(_size);
      for (int k = 1; k <= need; k++) {
        later(Duration(milliseconds: 700 * (k - 1) + 450), () {
          if (run != _run) return;
          added = k;
          notify();
        });
      }
      _hint.play(
        handTourPlan(<HandStop>[
          for (int k = 0; k < need; k++) HandStop(plus, 700),
          // The beam is level, and a dotted line over it, as long as it, says so.
          HandStop(
            plus,
            1400,
            marks: <HintMark>[
              LineMark(Offset(g.cx - g.half - 14, g.beamY - 14), Offset(g.cx + g.half + 14, g.beamY - 14)),
            ],
          ),
        ]),
        onEnd: () {
          added = 0;
          demoRunning = false;
          notify();
          controller.demoDone();
        },
      );
    } else {
      later(const Duration(milliseconds: 400), () {
        if (run != _run) return;
        revealed = true;
        notify();
      });
      final double angle = ((rightWeight - leftWeight) * 0.07).clamp(-0.32, 0.32);
      final int tile = const <String, int>{'left': 0, 'same': 1, 'right': 2}[activity.result]!;
      // The beam takes 1.2 s to tip; the hand comes when it has, then points at the lower pan (at both when they are level), and
      // then at the tile that points the same way.
      final int wait = angle == 0 ? 500 : (activity.hideTilt ? 1700 : 300);
      final HintPlan tour = handTourPlan(<HandStop>[
        if (angle == 0) ...<HandStop>[HandStop(_panTip(angle, 0), 700), HandStop(_panTip(angle, 1), 700)] else
          HandStop(_panTip(angle, angle < 0 ? 0 : 1), 800),
        HandStop(_spec.tileTip(3, tile, slot: 104, slop: 12, rtl: false), 1100),
      ]);
      _hint.play(
        HintPlan(<HintFrame>[
          HintFrame(const <HintMark>[], hold: Duration(milliseconds: wait)),
          ...tour.frames,
        ]),
        onEnd: () {
          chosen = activity.result;
          demoRunning = false;
          notify();
          controller.demoDone();
        },
      );
    }
    notify();
  }

  // ---- drawing ----

  @override
  Widget buildStage(BuildContext context, Size size, ActivitySpec spec) {
    _size = size;
    _spec = spec;
    return Stack(
      fit: StackFit.expand,
      clipBehavior: Clip.none,
      children: <Widget>[
        ListenableBuilder(listenable: this, builder: (BuildContext c, Widget? _) => _ScaleStage(this, size)),
        _hint.body(size),
      ],
    );
  }

  @override
  Widget? buildHands(BuildContext context, Size size, ActivitySpec spec) => _hint.hands(size, spec);

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
    final _ScaleBox g = _ScaleBox(size);
    final double cx = g.cx;
    final double half = g.half;
    final double beamY = g.beamY;
    final double panW = g.panW;
    final double panH = g.panH;
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
              final Offset rightEnd = g.rightEnd(angle);
              final Offset leftEnd = g.leftEnd(angle);
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
                  if (s.pegShown)
                    _peg(cx, beamY, out: s.revealed, still: MediaQuery.disableAnimationsOf(context)),
                  _pan(leftEnd, panW, panH, a.left, <PanGroup>[], 0, s.litPan == 'left'),
                  _pan(rightEnd, panW, panH, a.right, <PanGroup>[], s.added, s.litPan == 'right'),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  /// The peg that holds a beam whose lean is hidden: a short pin through the stand under the beam. It slides out (and fades) when
  /// the beam is let go; with "reduce motion" it is simply gone.
  Widget _peg(double cx, double beamY, {required bool out, required bool still}) {
    final Duration d = still ? Duration.zero : const Duration(milliseconds: 400);
    return Positioned(
      key: const Key('scale-peg'),
      left: cx - 14,
      top: beamY + 10,
      width: 28,
      height: 9,
      child: AnimatedSlide(
        offset: out ? const Offset(1.6, 0) : Offset.zero,
        duration: d,
        child: AnimatedOpacity(
          opacity: out ? 0 : 1,
          duration: d,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: TokenColors.worldWood,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: TokenColors.ink, width: 2),
            ),
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
    // While a hint draws the towers, the pan shows its plate only.
    final List<Widget> piles = s.towers
        ? const <Widget>[]
        : <Widget>[
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

/// The places of the scale in a stage of [size]: the same numbers the stage draws with, so that the hint can stand cubes on the
/// plates and point at a pan.
class _ScaleBox {
  _ScaleBox(Size size)
    : cx = size.width / 2,
      half = math.min(size.width * 0.36, 130),
      beamY = size.height * 0.3,
      panH = size.height * 0.4;

  final double cx;

  /// Half the beam's length, and the height of its pivot.
  final double half;
  final double beamY;

  /// The height of a pan; its width is a little less than the beam's half.
  final double panH;

  double get panW => half * 0.78;

  /// The ends of the beam when it leans by [angle] radians (positive: the right end is lower).
  Offset rightEnd(double angle) => Offset(cx + half * math.cos(angle), beamY + half * math.sin(angle));
  Offset leftEnd(double angle) => Offset(cx - half * math.cos(angle), beamY - half * math.sin(angle));

  /// The top of the plate of the pan that hangs from [end]: what lies on the pan stands on it.
  double plateTop(Offset end) => end.dy + 6 + panH - 8;
}
