import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../child/activity_shell.dart';
import '../content/hint_ladder.dart';
import '../content/models.dart';
import '../design/components.dart';
import '../design/tokens.g.dart';
import '../strings/he.dart';
import 'hint_widgets.dart';
import 'hints/hint_player.dart';
import 'hints/pointer_plans.dart';
import 'lesson_controller.dart';
import 'template_session.dart';

/// Where the pile and the flower stand inside the stage of a give-N scene.
class GiveLayout {
  GiveLayout(Size size, GiveNActivity a) {
    final double h = size.height;
    final double flowerH = h * 0.86;
    final double flowerW = flowerH * 0.8;
    flower = Rect.fromLTWH(size.width - flowerW - 10, (h - flowerH) / 2, flowerW, flowerH);
    tray = Rect.fromLTRB(10, 8, flower.left - 14, h - 8);
    objectSize = math.min(60, math.max(36, h * 0.34));
    // The pile: a grid, the same every time.
    final int n = a.sourceCount;
    final int cols = math.max(1, math.sqrt(n * tray.width / tray.height).ceil());
    final int rows = (n / cols).ceil();
    final double cw = tray.width / cols;
    final double ch = tray.height / rows;
    pileSize = math.min(objectSize, math.min(cw, ch) - 4);
    pile = <Offset>[
      for (int i = 0; i < n; i++)
        Offset(tray.left + (i % cols + 0.5) * cw, tray.top + (i ~/ cols + 0.5) * ch),
    ];
    // The places on the flower where given objects sit.
    // They sit on the petals; a little wider than the flower so that they stay big enough to count.
    final int slotCols = n > 4 ? 3 : 2;
    final int slotRows = (n / slotCols).ceil();
    final double spread = flower.width * 1.25;
    final double sw = spread / slotCols;
    final double sh = flower.height * 0.8 / slotRows;
    slotSize = math.min(objectSize * 0.85, math.min(sw, sh * 1.15));
    slots = <Offset>[
      for (int i = 0; i < n; i++)
        Offset(
          flower.center.dx - spread / 2 + (i % slotCols + 0.5) * sw,
          flower.top + flower.height * 0.1 + (i ~/ slotCols + 0.5) * sh,
        ),
    ];
  }

  late final Rect flower;
  late final Rect tray;
  late final double objectSize;
  late final double pileSize;
  late final List<Offset> pile;
  late final double slotSize;
  late final List<Offset> slots;
}

/// The give-N template (understanding check U4): "give the flower four butterflies". Drag, or touch a
/// butterfly and then the flower. Taking all of them is evidence of M-CNT-CARD.
class GiveNSession extends TemplateSession {
  GiveNSession(super.controller, this.activity);

  final GiveNActivity activity;

  /// The objects on the flower, in the order they were given.
  final List<int> placed = <int>[];

  /// The pile object that has been touched and waits for the flower.
  int? selected;

  /// The object being dragged and where the finger is (in stage points).
  int? dragging;
  Offset? dragAt;

  AnswerState ringState = AnswerState.idle;
  bool _busy = false;
  bool demoRunning = false;

  /// How many the counting aid of hint 2 shows (hands up to ten, ten-frames above), and whether hint 1 shows the goal: the
  /// flower is lit and the card beside the button says the number the flower is to get.
  int fingers = 0;
  bool goal = false;
  int? wiggling;

  Size _stage = Size.zero;

  /// The pointing hand of the worked example (level 3).
  late final HintPlayer _hint = HintPlayer(this);

  void _place(int i) {
    if (placed.contains(i) || demoRunning) return;
    placed.add(i);
    selected = null;
    goal = false;
    notify();
  }

  void _giveBack() {
    if (placed.isEmpty || demoRunning) return;
    placed.removeLast();
    notify();
  }

  int? _pileAt(GiveLayout l, Offset p) {
    for (int i = 0; i < activity.sourceCount; i++) {
      if (placed.contains(i)) continue;
      final double half = math.max(l.pileSize, 48) / 2;
      if ((p - l.pile[i]).dx.abs() <= half && (p - l.pile[i]).dy.abs() <= half) return i;
    }
    return null;
  }

  void _tapAt(Offset p) {
    if (_busy || demoRunning || ringState == AnswerState.correct) return;
    final GiveLayout l = GiveLayout(_stage, activity);
    final int? hit = _pileAt(l, p);
    if (hit != null) {
      selected = selected == hit ? null : hit;
      notify();
    } else if (l.flower.contains(p)) {
      if (selected != null) {
        _place(selected!);
      } else {
        _giveBack();
      }
    } else if (selected != null) {
      selected = null;
      notify();
    }
  }

  void _panStart(Offset p) {
    if (_busy || demoRunning || ringState == AnswerState.correct) return;
    final int? hit = _pileAt(GiveLayout(_stage, activity), p);
    if (hit == null) return;
    dragging = hit;
    dragAt = p;
    selected = null;
    notify();
  }

  void _panUpdate(Offset p) {
    if (dragging == null) return;
    dragAt = p;
    notify();
  }

  void _panEnd() {
    final int? d = dragging;
    final Offset? at = dragAt;
    if (d == null || at == null) return;
    dragging = null;
    dragAt = null;
    if (GiveLayout(_stage, activity).flower.contains(at)) {
      _place(d);
    } else {
      notify();
    }
  }

  Future<void> submit() async {
    if (_busy || placed.isEmpty || demoRunning || ringState == AnswerState.correct) return;
    _busy = true;
    final Outcome o = await controller.giveN(placed.length);
    if (disposed) return;
    if (o.correct) {
      ringState = AnswerState.correct;
      notify();
      later(TemplateSession.praisePause, controller.next);
    } else {
      ringState = AnswerState.notYet;
      notify();
      later(TemplateSession.notYetPause, () {
        ringState = AnswerState.idle;
        placed.clear();
        _busy = false;
        if (controller.guided) _workedExample();
        notify();
      });
    }
  }

  @override
  void onReset() {
    placed.clear();
    selected = null;
    dragging = null;
    dragAt = null;
    ringState = AnswerState.idle;
    _busy = false;
    demoRunning = false;
    fingers = 0;
    goal = false;
    wiggling = null;
    _hint.clear();
    notify();
  }

  @override
  void onReplay() => _wiggleAll();

  @override
  void onHint() {
    switch (hintPictureOf(activity)) {
      case HintPicture.countingAid:
        _showAid();
      case HintPicture.demonstration:
        _workedExample();
      default:
        _showGoal();
    }
  }

  /// Hint 1: the flower is lit, and the card says the number it is to get (the question again, as a numeral and its dots).
  void _showGoal() {
    goal = true;
    notify();
  }

  void _wiggleAll() {
    for (int i = 0; i < activity.sourceCount; i++) {
      later(Duration(milliseconds: 300 * i), () {
        wiggling = i;
        notify();
      });
    }
    later(Duration(milliseconds: 300 * activity.sourceCount), () {
      wiggling = null;
      notify();
    });
  }

  /// Hint 2: the same number counted another way: one more finger (or counter) each second.
  void _showAid() {
    goal = false;
    fingers = 0;
    for (int i = 1; i <= activity.n; i++) {
      later(Duration(milliseconds: 600 * i), () {
        fingers = i;
        notify();
      });
    }
    later(Duration(milliseconds: 600 * activity.n + 2400), () {
      fingers = 0;
      notify();
    });
  }

  /// The guide gives the right number one by one, then puts them back for the child's turn.
  void _workedExample() {
    if (demoRunning) return;
    placed.clear();
    selected = null;
    demoRunning = true;
    if (!_stage.isEmpty) {
      // The hand takes each one from the pile and puts it on the flower, with its badge, as the guide gives it.
      final GiveLayout l = GiveLayout(_stage, activity);
      _hint.play(pointerGivePlan(l.pile.take(activity.n).toList(), l.slots.take(activity.n).toList()));
    }
    for (int i = 0; i < activity.n; i++) {
      later(Duration(milliseconds: 300 + CountDemo.stepMs * i), () {
        placed.add(i);
        notify();
      });
    }
    later(Duration(milliseconds: 300 + CountDemo.stepMs * activity.n + 1400), () {
      placed.clear();
      demoRunning = false;
      notify();
      controller.demoDone();
    });
    notify();
  }

  @override
  Widget buildStage(BuildContext context, Size size, ActivitySpec spec) {
    _stage = size;
    return ListenableBuilder(
      listenable: this,
      builder: (BuildContext c, Widget? _) => _GiveStage(this, size),
    );
  }

  @override
  Widget? buildHands(BuildContext context, Size size, ActivitySpec spec) => _hint.hands(size, spec);

  @override
  Widget? buildTiles(BuildContext context, ActivitySpec spec) => ListenableBuilder(
    listenable: this,
    builder: (BuildContext c, Widget? _) => Directionality(
      textDirection: TextDirection.ltr,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: <Widget>[
          // The answer area has room beside the button: the goal card (hint 1) or the counting aid (hint 2) opens there, its
          // top under the stage, and the button stays where it is.
          if (goal || fingers > 0)
            Positioned(
              top: AnswerAreaCard.place(spec).top,
              left: 0,
              // The card's end is 16 from the button's edge (the button's tile is 96 wide with a 12 tap margin on each side).
              right: spec.tilesWidth / 2 + 60 + 16,
              height: AnswerAreaCard.place(spec).height,
              child: IgnorePointer(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: goal
                      ? FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerRight,
                          child: GoalCard(n: activity.n),
                        )
                      : CountingAid(n: activity.n, shown: fingers, scale: AnswerAreaCard.scaleOf(spec)),
                ),
              ),
            ),
          Opacity(
            opacity: placed.isEmpty ? 0.4 : 1,
            child: AnswerTile(
              key: const Key('give-done'),
              semanticLabel: He.giveDoneSemantics.text,
              state: ringState == AnswerState.correct ? AnswerState.correct : AnswerState.idle,
              onPressed: placed.isEmpty ? null : submit,
              child: const SizedBox(width: 56, height: 56, child: CustomPaint(painter: _CheckPainter())),
            ),
          ),
        ],
      ),
    ),
  );
}

/// The pause between the steps of a worked example.
abstract final class CountDemo {
  static const int stepMs = 800;
}

class _CheckPainter extends CustomPainter {
  const _CheckPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final Paint p = Paint()
      ..color = TokenColors.ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 9
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(
      Path()
        ..moveTo(size.width * 0.12, size.height * 0.54)
        ..lineTo(size.width * 0.40, size.height * 0.80)
        ..lineTo(size.width * 0.88, size.height * 0.22),
      p,
    );
  }

  @override
  bool shouldRepaint(_CheckPainter old) => false;
}

class _GiveStage extends StatelessWidget {
  const _GiveStage(this.s, this.size);

  final GiveNSession s;
  final Size size;

  @override
  Widget build(BuildContext context) {
    final GiveNActivity a = s.activity;
    final GiveLayout l = GiveLayout(size, a);
    final Color? ring = switch (s.ringState) {
      AnswerState.correct => TokenColors.correctGlow,
      AnswerState.notYet => TokenColors.notYetRing,
      _ => s.goal ? TokenColors.hintHalo : null,
    };
    return Semantics(
      container: true,
      label: a.altText,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapUp: (TapUpDetails d) => s._tapAt(d.localPosition),
        onPanStart: (DragStartDetails d) => s._panStart(d.localPosition),
        onPanUpdate: (DragUpdateDetails d) => s._panUpdate(d.localPosition),
        onPanEnd: (DragEndDetails d) => s._panEnd(),
        onPanCancel: s._panEnd,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(TokenRadius.lg),
          child: Stack(
            key: const Key('give-stage'),
            clipBehavior: Clip.none,
            children: <Widget>[
              if (a.background != null)
                Positioned.fill(child: PackSvg(a.assets.svg(a.background!), fit: BoxFit.cover)),
              // The pile: a soft tray the butterflies are taken from.
              Positioned.fromRect(
                rect: l.tray,
                child: DecoratedBox(
                  key: const Key('give-tray'),
                  decoration: BoxDecoration(
                    color: TokenColors.skyTint.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(TokenRadius.lg),
                    border: Border.all(color: TokenColors.hintHalo, width: 3),
                  ),
                ),
              ),
              Positioned.fromRect(
                rect: l.flower.inflate(4),
                child: DecoratedBox(
                  key: const Key('give-flower-ring'),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(TokenRadius.lg),
                    color: ring?.withValues(alpha: 0.2),
                    border: ring == null ? null : Border.all(color: ring, width: 5),
                  ),
                ),
              ),
              Positioned.fromRect(
                rect: l.flower,
                child: PackSvg(a.assets.svg(a.targetSprite), key: const Key('give-flower')),
              ),
              for (int i = 0; i < a.sourceCount; i++) _butterfly(a, l, i),
              Positioned.fill(child: s._hint.body(size)),
              Positioned(
                left: l.flower.left,
                top: l.flower.bottom - 30,
                width: l.flower.width,
                child: s.placed.isEmpty
                    ? const SizedBox.shrink()
                    : Center(
                        child: Container(
                          key: const Key('give-counter'),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                          decoration: BoxDecoration(
                            color: TokenColors.paper,
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: softShadow,
                          ),
                          child: Directionality(
                            textDirection: TextDirection.ltr,
                            child: Text(
                              '${s.placed.length}',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: TokenColors.ink,
                                height: 1,
                              ),
                            ),
                          ),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _butterfly(GiveNActivity a, GiveLayout l, int i) {
    final int slot = s.placed.indexOf(i);
    final bool onFlower = slot >= 0;
    final bool dragged = s.dragging == i && s.dragAt != null;
    final Offset c = dragged ? s.dragAt! : (onFlower ? l.slots[slot] : l.pile[i]);
    final double size = onFlower ? l.slotSize : l.pileSize;
    final bool picked = s.selected == i;
    final bool wiggle = s.wiggling == i;
    return AnimatedPositioned(
      key: Key('give-butterfly-$i'),
      duration: dragged ? Duration.zero : const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      left: c.dx - size / 2 - (picked ? 4 : 0),
      top: c.dy - size / 2 - (picked ? 4 : 0),
      width: size + (picked ? 8 : 0),
      height: size + (picked ? 8 : 0),
      child: IgnorePointer(
        child: AnimatedScale(
          scale: wiggle ? 1.3 : (dragged ? 1.2 : 1),
          duration: const Duration(milliseconds: 200),
          child: DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: picked ? TokenColors.sparkTint : null,
              border: picked ? Border.all(color: TokenColors.selectedRing, width: 3) : null,
            ),
            child: PackSvg(a.assets.svg(a.sourceSprite)),
          ),
        ),
      ),
    );
  }
}
