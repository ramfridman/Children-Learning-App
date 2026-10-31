import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../child/activity_shell.dart';
import '../content/hint_ladder.dart';
import '../content/models.dart';
import '../design/components.dart';
import '../design/tokens.g.dart';
import 'hints/hint_marks.dart';
import 'hints/tap_plans.dart' show inkedSvg;
import 'hints/hint_player.dart';
import 'hints/pointer_plans.dart';
import 'hints/tile_points.dart';
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
  /// that a taller tower is always the heavier one. Three rows keep the cubes big enough to count on a phone, inside the pan.
  static const int _column = 3;

  /// The towers of cubes (and, to weigh, the empty places that are still to fill), and the dotted line that makes the lean or the
  /// level visible: across the tops of the towers when the pans are level (a hidden lean), through the pivot when the beam leans.
  /// The towers stand in the pans, on the floor the pictures stand on.
  List<HintMark> _towerMarks() {
    final _ScaleBox g = _ScaleBox(_size);
    final double angle = lean;
    final List<Offset> ends = <Offset>[g.leftEnd(angle), g.rightEnd(angle)];
    final List<int> weights = <int>[leftWeight, rightWeight];
    final int most = math.max(weights[0], weights[1]);
    final int cols = math.max(1, (most + _column - 1) ~/ _column);
    final int rows = math.max(1, (most + cols - 1) ~/ cols);
    final double gap = 2 * g.u;
    final double side = math.min(16 * g.u, math.min(g.loadH / rows, g.loadW / cols) - gap);
    final double pitch = side + gap;
    final double width = cols * pitch - gap;
    Rect cube(Offset end, int i) => Rect.fromLTWH(
      end.dx - width / 2 + (i % cols) * pitch,
      g.floor(end) - ((i ~/ cols) + 1) * pitch + gap,
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
      final double top =
          g.floor(ends[0]) - (math.min(weights[0], weights[1]) + cols - 1) ~/ cols * pitch - gap / 2;
      marks.add(
        LineMark(
          Offset(ends[0].dx - width / 2 - 6 * g.u, top),
          Offset(ends[1].dx + width / 2 + 6 * g.u, top),
        ),
      );
    } else {
      marks.add(
        LineMark(Offset(g.cx - g.half - 14 * g.u, g.beamY), Offset(g.cx + g.half + 14 * g.u, g.beamY)),
      );
    }
    return marks;
  }

  /// The fingertip place on pan [p] (0 left, 1 right) when the beam is at [angle]: the middle of what lies on it.
  Offset _panTip(double angle, int p) {
    final _ScaleBox g = _ScaleBox(_size);
    final Offset end = p == 0 ? g.leftEnd(angle) : g.rightEnd(angle);
    return Offset(end.dx, g.floor(end) - g.loadH * 0.4);
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
              LineMark(
                Offset(g.cx - g.half - 14 * g.u, g.beamY - 16 * g.u),
                Offset(g.cx + g.half + 14 * g.u, g.beamY - 16 * g.u),
              ),
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
    // What lies on each pan, in order, and one size for every picture of both pans (the most a pan will hold), so that a thing is
    // as big on one pan as on the other: the size of a picture never says how heavy it is.
    final List<String> left = _things(a.left, 0);
    final List<String> right = _things(a.right, s.added);
    final int most = math.max(
      left.length,
      _things(a.right, 0).length + (a.weigh ? int.tryParse(a.result) ?? 0 : 0),
    );
    final double cell = g.cellFor(math.max(most, right.length));
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
              final Offset leftEnd = g.leftEnd(angle);
              final Offset rightEnd = g.rightEnd(angle);
              return Stack(
                clipBehavior: Clip.none,
                children: <Widget>[
                  if (a.background != null)
                    Positioned.fill(child: PackSvg(a.assets.svg(a.background!), fit: BoxFit.cover)),
                  // The stand, the beam, the strings and the inside of the pans, behind what lies on them.
                  Positioned.fill(child: CustomPaint(painter: _ScalePainter(g, angle, front: false))),
                  if (s.pegShown) _peg(g, out: s.revealed, still: MediaQuery.disableAnimationsOf(context)),
                  if (s.litPan == 'left') _halo(g, leftEnd),
                  if (s.litPan == 'right') _halo(g, rightEnd),
                  // While a hint draws the towers, the pans show their plates only.
                  if (!s.towers) ...<Widget>[
                    ..._load(g, leftEnd, left, cell),
                    ..._load(g, rightEnd, right, cell, added: s.added),
                  ],
                  // The front of each pan, over the feet of what lies in it.
                  Positioned.fill(child: CustomPaint(painter: _ScalePainter(g, angle, front: true))),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  /// The pictures on a pan, one for each thing, in the order of its groups, and then the blocks the child has added.
  List<String> _things(List<PanGroup> groups, int added) => <String>[
    for (final PanGroup g in groups)
      for (int i = 0; i < g.count; i++) g.sprite,
    if (s.activity.blockSprite != null)
      for (int i = 0; i < math.min(added, 12); i++) s.activity.blockSprite!,
  ];

  /// What lies on the pan that hangs from [end]: a heap of pictures, each [cell] across, in rows from the floor up, each row
  /// centred (left to right, as the stage is drawn). A picture is cut to its ink, so that it stands on the floor of the pan and
  /// fills its place; the last [added] are the blocks the child put on (`scale-blocks`).
  List<Widget> _load(_ScaleBox g, Offset end, List<String> names, double cell, {int added = 0}) {
    if (names.isEmpty) return const <Widget>[];
    final int cols = math.max(1, (g.loadW / cell + 0.001).floor());
    final List<Widget> out = <Widget>[];
    final List<Widget> blocks = <Widget>[];
    final int first = names.length - math.min(added, names.length);
    for (int i = 0; i < names.length; i++) {
      final int row = i ~/ cols;
      final int inRow = math.min(cols, names.length - row * cols);
      final double x = end.dx - inRow * cell / 2 + (i % cols) * cell;
      final double bottom = g.floor(end) - row * cell;
      final (String svg, double aspect) = inkedSvg(s.activity.assets.svg(names[i]));
      final double side = cell * 0.9;
      final double w = aspect >= 1 ? side : side * aspect;
      final double h = aspect >= 1 ? side / aspect : side;
      final Widget pic = Positioned(
        left: x + (cell - w) / 2,
        top: bottom - h,
        width: w,
        height: h,
        child: PackSvg(svg, fit: BoxFit.fill),
      );
      (i >= first ? blocks : out).add(pic);
    }
    if (blocks.isNotEmpty) {
      out.add(
        Positioned.fill(
          child: Stack(key: const Key('scale-blocks'), clipBehavior: Clip.none, children: blocks),
        ),
      );
    }
    return out;
  }

  /// The light of hint 1 on a pan: a sky ring round the pan and what lies on it.
  Widget _halo(_ScaleBox g, Offset end) {
    final Rect r = Rect.fromLTRB(
      end.dx - g.rimHalf - 5 * g.u,
      g.floor(end) - g.loadH - 4 * g.u,
      end.dx + g.rimHalf + 5 * g.u,
      g.rimY(end) + g.bowl + 5 * g.u,
    );
    return Positioned.fromRect(
      rect: r,
      child: DecoratedBox(
        key: const Key('pan-lit'),
        decoration: BoxDecoration(
          color: TokenColors.skyTint.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(TokenRadius.lg),
          border: Border.all(color: TokenColors.hintHalo, width: 4),
        ),
      ),
    );
  }

  /// The peg that holds a beam whose lean is hidden: a short pin through the upright under the beam. It slides out (and fades) when
  /// the beam is let go; with "reduce motion" it is simply gone.
  Widget _peg(_ScaleBox g, {required bool out, required bool still}) {
    final Duration d = still ? Duration.zero : const Duration(milliseconds: 400);
    return Positioned(
      key: const Key('scale-peg'),
      left: g.cx - 15 * g.u,
      top: g.beamY + 14 * g.u,
      width: 30 * g.u,
      height: 9 * g.u,
      child: AnimatedSlide(
        offset: out ? const Offset(1.6, 0) : Offset.zero,
        duration: d,
        child: AnimatedOpacity(
          opacity: out ? 0 : 1,
          duration: d,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: TokenColors.sunset,
              borderRadius: BorderRadius.circular(4.5 * g.u),
              border: Border.all(color: TokenColors.sunsetDeep, width: 2),
            ),
          ),
        ),
      ),
    );
  }
}

/// The scale itself, drawn in code after the classroom pan balance (a broad foot, an upright, a round pivot cap on the middle of
/// the beam, a hook at each end of the beam and two strings from each hook to the rim of an open pan). [front] false draws the
/// stand, the beam, the strings and the inside of the pans; [front] true only the front of each pan, which goes over the feet of
/// what lies in it. The pans hang straight down from the hooks whatever the lean.
class _ScalePainter extends CustomPainter {
  _ScalePainter(this.g, this.angle, {required this.front});

  final _ScaleBox g;
  final double angle;
  final bool front;

  @override
  void paint(Canvas canvas, Size size) {
    final double u = g.u;
    final List<Offset> ends = <Offset>[g.leftEnd(angle), g.rightEnd(angle)];
    if (front) {
      for (final Offset end in ends) {
        _panFront(canvas, end);
      }
      return;
    }
    final Paint wood = Paint()..color = TokenColors.worldWood;
    final Paint woodLight = Paint()..color = TokenColors.worldWoodLight;
    final Paint woodDeep = Paint()..color = TokenColors.teachBrown;
    // The shadow on the grass, the foot and the upright.
    canvas.drawOval(
      Rect.fromCenter(center: Offset(g.cx, g.ground - 1 * u), width: 96 * u, height: 7 * u),
      Paint()..color = TokenColors.worldShadow,
    );
    final Path foot = Path()
      ..moveTo(g.cx - 40 * u, g.ground - 3 * u)
      ..lineTo(g.cx - 26 * u, g.ground - 15 * u)
      ..lineTo(g.cx + 26 * u, g.ground - 15 * u)
      ..lineTo(g.cx + 40 * u, g.ground - 3 * u)
      ..close();
    canvas.drawPath(foot, wood);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(g.cx - 43 * u, g.ground - 6 * u, g.cx + 43 * u, g.ground),
        Radius.circular(3 * u),
      ),
      woodDeep,
    );
    final Path upright = Path()
      ..moveTo(g.cx - 7 * u, g.ground - 15 * u)
      ..lineTo(g.cx - 4.5 * u, g.beamY)
      ..lineTo(g.cx + 4.5 * u, g.beamY)
      ..lineTo(g.cx + 7 * u, g.ground - 15 * u)
      ..close();
    canvas.drawPath(upright, wood);
    canvas.drawRect(Rect.fromLTRB(g.cx - 4 * u, g.beamY, g.cx - 1.5 * u, g.ground - 15 * u), woodLight);
    // The strings, from each hook to the two sides of its pan's rim, and the inside of each pan.
    final Paint string = Paint()
      ..color = TokenColors.inkSoft
      ..strokeWidth = 1.6 * u
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    for (final Offset end in ends) {
      final Offset hook = end + Offset(0, 5 * u);
      final double rim = g.rimY(end);
      canvas.drawLine(hook, Offset(end.dx - g.rimHalf + 3 * u, rim), string);
      canvas.drawLine(hook, Offset(end.dx + g.rimHalf - 3 * u, rim), string);
      canvas.drawOval(
        Rect.fromCenter(center: Offset(end.dx, rim), width: 2 * g.rimHalf, height: 9 * u),
        Paint()..color = TokenColors.seaDeep,
      );
    }
    // The hooks: a ring under each end of the beam, hanging straight down.
    final Paint ring = Paint()
      ..color = TokenColors.ink
      ..strokeWidth = 2 * u
      ..style = PaintingStyle.stroke;
    for (final Offset end in ends) {
      canvas.drawCircle(end + Offset(0, 4 * u), 3.2 * u, ring);
    }
    // The beam, turned about the pivot.
    canvas.save();
    canvas.translate(g.cx, g.beamY);
    canvas.rotate(angle);
    final double len = g.half + 9 * u;
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTRB(-len, -4.5 * u, len, 4.5 * u), Radius.circular(4.5 * u)),
      wood,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(-len + 3.5 * u, -3.2 * u, len - 3.5 * u, -0.8 * u),
        Radius.circular(1.2 * u),
      ),
      woodLight,
    );
    for (final double x in <double>[-g.half, g.half]) {
      canvas.drawCircle(Offset(x, 0), 2 * u, woodDeep);
    }
    canvas.restore();
    // The pivot cap and its pin: it does not turn.
    canvas.drawCircle(Offset(g.cx, g.beamY), 8.5 * u, Paint()..color = TokenColors.spark);
    canvas.drawCircle(
      Offset(g.cx, g.beamY),
      8.5 * u,
      Paint()
        ..color = TokenColors.sparkDeep
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2 * u,
    );
    canvas.drawCircle(Offset(g.cx, g.beamY), 2.6 * u, Paint()..color = TokenColors.ink);
  }

  /// The front of a pan: a shallow bowl under the rim, with a light edge along the front of the rim.
  void _panFront(Canvas canvas, Offset end) {
    final double u = g.u;
    final double rim = g.rimY(end);
    final double r = g.rimHalf;
    final double ry = 4.5 * u;
    final double b = g.bowl;
    final Rect rimBox = Rect.fromCenter(center: Offset(end.dx, rim), width: 2 * r, height: 2 * ry);
    final Path bowl = Path()
      ..moveTo(end.dx + r, rim)
      ..arcTo(rimBox, 0, math.pi, false)
      ..cubicTo(
        end.dx - r + 3 * u,
        rim + b * 0.8,
        end.dx - r * 0.6 - 6 * u,
        rim + b,
        end.dx - r * 0.6,
        rim + b,
      )
      ..lineTo(end.dx + r * 0.6, rim + b)
      ..cubicTo(end.dx + r * 0.6 + 6 * u, rim + b, end.dx + r - 3 * u, rim + b * 0.8, end.dx + r, rim)
      ..close();
    canvas.drawPath(bowl, Paint()..color = TokenColors.sea);
    canvas.drawArc(
      rimBox,
      0.2,
      math.pi - 0.4,
      false,
      Paint()
        ..color = TokenColors.seaTint
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6 * u
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_ScalePainter old) => old.angle != angle || old.g.size != g.size || old.front != front;
}

/// The places of the scale in a stage of [size]: the same numbers the stage draws with, so that the hint can stand cubes in the
/// pans and point at a pan. The scale is drawn for the phone's stage (330 by 128) and grows evenly with a bigger one, its foot on
/// the stage's floor: the beam is short enough that a pan leaning 18 degrees stays inside the stage, and the strings long enough
/// that three rows of cubes fit between the floor of a pan and its hook.
class _ScaleBox {
  _ScaleBox(this.size)
    : u = math.min(size.width / 330, size.height / 128),
      cx = size.width / 2,
      ground = size.height - 2;

  final Size size;

  /// One point of the phone's drawing on this stage.
  final double u;
  final double cx;

  /// Where the foot stands.
  final double ground;

  /// The height of the pivot.
  double get beamY => ground - 92 * u;

  /// Half the beam's length, from the pivot to a hook.
  double get half => 92 * u;

  /// How far below its hook a pan's rim hangs, how deep the bowl is under its rim, and half the rim's width.
  double get drop => 53 * u;
  double get bowl => 8 * u;
  double get rimHalf => 56 * u;

  /// The room on a pan for what lies on it: as wide as the rim, less a little, and as high as the strings leave free.
  double get loadW => 104 * u;
  double get loadH => 43 * u;

  /// The ends of the beam (its hooks) when it leans by [angle] radians (positive: the right end is lower).
  Offset rightEnd(double angle) => Offset(cx + half * math.cos(angle), beamY + half * math.sin(angle));
  Offset leftEnd(double angle) => Offset(cx - half * math.cos(angle), beamY - half * math.sin(angle));

  /// The rim of the pan that hangs from [end], and the floor of the pan, where what lies on it stands.
  double rimY(Offset end) => end.dy + drop;
  double floor(Offset end) => rimY(end) + 2 * u;

  /// The place of one picture when [n] of them lie on a pan: as many rows as make the pictures biggest, at most 40 across.
  double cellFor(int n) {
    double best = 0;
    for (int rows = 1; rows <= math.max(1, n); rows++) {
      final int cols = (n + rows - 1) ~/ rows;
      best = math.max(best, math.min(loadW / cols, loadH / rows));
    }
    return math.min(best, 40 * u);
  }
}
