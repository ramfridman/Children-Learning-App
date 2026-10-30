import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../child/activity_shell.dart';
import '../content/hint_ladder.dart';
import '../content/models.dart';
import '../design/app_text.dart';
import '../design/components.dart';
import '../design/layout.dart';
import '../design/tokens.g.dart';
import '../speech/answer_matcher.dart';
import '../strings/he.dart';
import 'hint_widgets.dart';
import 'lesson_controller.dart';
import 'template_session.dart';

/// Where the objects of a count-and-tap scene stand inside the stage, in the stage's own points.
/// The same seed always gives the same places.
class CountLayout {
  CountLayout(Size size, CountTapActivity a) {
    final double h = size.height;
    final double flowerH = h * 0.86;
    final double flowerW = flowerH * 0.8;
    flower = Rect.fromLTWH(size.width - flowerW - 10, (h - flowerH) / 2, flowerW, flowerH);
    objectSize = math.min(60, math.max(36, h * 0.34));
    final Rect region = Rect.fromLTRB(10, 8, flower.left - 8, h - 8);
    centers = a.arrangement == 'line' ? _line(region, a.count) : _scatter(region, a.count, a.seed);
  }

  late final Rect flower;
  late final double objectSize;
  late final List<Offset> centers;

  Offset get flowerCentre => flower.center;

  List<Offset> _line(Rect r, int n) {
    final double step = math.min(r.width / n, objectSize * 1.5);
    final double start = r.center.dx - step * (n - 1) / 2;
    return <Offset>[for (int i = 0; i < n; i++) Offset(start + step * i, r.center.dy + r.height * 0.1)];
  }

  List<Offset> _scatter(Rect r, int n, int seed) {
    // One object in each of n cells of a grid, picked in a seeded order and moved a little inside its cell.
    final math.Random rnd = math.Random(seed);
    final int cols = math.max(1, (math.sqrt(n * r.width / r.height)).ceil());
    final int rows = (n / cols).ceil();
    final List<int> cells = List<int>.generate(cols * rows, (int i) => i)..shuffle(rnd);
    final double cw = r.width / cols;
    final double ch = r.height / rows;
    final double jx = math.max(0, (cw - objectSize) / 2) * 0.7;
    final double jy = math.max(0, (ch - objectSize) / 2) * 0.7;
    return <Offset>[
      for (int i = 0; i < n; i++)
        Offset(
          r.left + (cells[i] % cols + 0.5) * cw + (rnd.nextDouble() * 2 - 1) * jx,
          r.top + (cells[i] ~/ cols + 0.5) * ch + (rnd.nextDouble() * 2 - 1) * jy,
        ),
    ];
  }
}

/// The count-and-tap template (T02): touch each object once, it flies to the flower (or lights up where
/// it is) and a counter keeps the number; then "how many?" with the answer tiles. Touching the same
/// object twice is kept as evidence of M-CNT-DOUBLE with the answer.
class CountTapSession extends TemplateSession {
  CountTapSession(super.controller, this.activity);

  final CountTapActivity activity;

  /// Objects that have been counted this round.
  final Set<int> counted = <int>{};

  /// Counted objects whose flight to the flower has ended (they are no longer on the stage).
  final Set<int> arrived = <int>{};

  /// True once the same object was touched twice in this round.
  bool touchedTwice = false;

  /// True when every object has been counted and the answer tiles are on offer.
  bool answering = false;

  String? chosenId;
  AnswerState chosenState = AnswerState.idle;
  bool _busy = false;

  /// An object that is wiggling to be noticed, the objects the light of hint 1 has been to (a dot stays on each until the next
  /// touch), and how many the counting aid of hint 2 shows (hands up to ten, ten-frames above).
  int? wiggling;
  final Set<int> seen = <int>{};
  int fingers = 0;
  bool demoRunning = false;

  bool get flies => activity.onTap == 'fly_to_target';
  int get counter => counted.length;

  void tapObject(int i) {
    if (answering || (demoRunning && !_demoStep)) return;
    seen.clear();
    if (counted.contains(i)) {
      // Counting the same one again.
      touchedTwice = true;
      wiggling = i;
      later(const Duration(milliseconds: 500), () {
        wiggling = null;
        notify();
      });
      notify();
      return;
    }
    counted.add(i);
    if (flies) {
      later(const Duration(milliseconds: 600), () {
        arrived.add(i);
        notify();
      });
    }
    if (counted.length == activity.count) {
      if (!demoRunning) _finishCounting();
    }
    notify();
  }

  bool _demoStep = false;

  void _finishCounting() {
    answering = true;
    controller.askAnswer(activity.answerPrompt);
  }

  @override
  bool get listensNow => answering && !_busy && chosenState != AnswerState.correct;

  @override
  String get voiceAnswerType => 'number';

  @override
  List<Expected> voiceExpected() => <Expected>[
    for (final ChoiceOption o in activity.options)
      Expected.number(o.id, o.value!, correct: o.id == activity.correctId, also: o.speech),
  ];

  @override
  Future<void> chooseByVoice(String optionId) => choose(optionId, byVoice: true);

  Future<void> choose(String id, {bool byVoice = false}) async {
    if (!answering || _busy || chosenState == AnswerState.correct) return;
    if (controller.guided && id != activity.correctId) return;
    _busy = true;
    chosenId = id;
    final Outcome o = await controller.chooseOption(
      id,
      traceTag: touchedTwice ? activity.traceTags['same_object_tapped_twice'] : null,
      byVoice: byVoice,
    );
    if (disposed) return;
    if (o.correct) {
      chosenState = AnswerState.correct;
      notify();
      later(TemplateSession.praisePause, controller.next);
    } else {
      chosenState = AnswerState.notYet;
      notify();
      later(TemplateSession.notYetPause, () {
        chosenId = null;
        chosenState = AnswerState.idle;
        _busy = false;
        if (controller.guided) {
          _workedExample();
        } else {
          controller.restartCount();
        }
        notify();
      });
    }
  }

  @override
  void onReset() {
    counted.clear();
    arrived.clear();
    touchedTwice = false;
    answering = false;
    chosenId = null;
    chosenState = AnswerState.idle;
    _busy = false;
    wiggling = null;
    seen.clear();
    fingers = 0;
    demoRunning = false;
    notify();
  }

  @override
  void onReplay() => _lightEach(dots: false);

  @override
  void onHint() {
    switch (hintPictureOf(activity)) {
      case HintPicture.countingAid:
        _showAid();
      case HintPicture.demonstration:
        _workedExample();
      default:
        _lightEach();
    }
  }

  /// Hint 1: the objects are lit one after the other, and a dot stays on each one visited. Nothing is said or counted.
  void _lightEach({bool dots = true}) {
    if (answering) return;
    seen.clear();
    for (int i = 0; i < activity.count; i++) {
      later(Duration(milliseconds: 450 * i), () {
        wiggling = i;
        if (dots) seen.add(i);
        notify();
      });
    }
    later(Duration(milliseconds: 450 * activity.count), () {
      wiggling = null;
      notify();
    });
  }

  /// Hint 2: the same number counted another way: one more finger (or counter) for each second.
  void _showAid() {
    fingers = 0;
    for (int i = 1; i <= activity.count; i++) {
      later(Duration(milliseconds: 600 * i), () {
        fingers = i;
        notify();
      });
    }
    later(Duration(milliseconds: 600 * activity.count + 2400), () {
      fingers = 0;
      notify();
    });
  }

  /// The guide counts every object aloud (here, in turn) and then hands the move back.
  void _workedExample() {
    if (demoRunning) return;
    counted.clear();
    arrived.clear();
    answering = false;
    demoRunning = true;
    for (int i = 0; i < activity.count; i++) {
      later(Duration(milliseconds: 300 + demoStepMs * i), () {
        _demoStep = true;
        tapObject(i);
        _demoStep = false;
      });
    }
    later(Duration(milliseconds: 300 + demoStepMs * activity.count + 200), () {
      demoRunning = false;
      answering = true;
      notify();
      controller.demoDone();
    });
    notify();
  }

  static const int demoStepMs = 800;

  // ---- drawing ----

  @override
  Widget buildStage(BuildContext context, Size size, ActivitySpec spec) =>
      ListenableBuilder(listenable: this, builder: (BuildContext c, Widget? _) => _CountStage(this, size));

  @override
  Widget? buildTiles(BuildContext context, ActivitySpec spec) => ListenableBuilder(
    listenable: this,
    builder: (BuildContext c, Widget? _) => Stack(
      alignment: Alignment.center,
      children: <Widget>[
        IgnorePointer(
          ignoring: !answering,
          child: AnimatedOpacity(
            opacity: answering ? 1 : 0,
            duration: const Duration(milliseconds: 300),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                for (final ChoiceOption o in activity.options)
                  Opacity(
                    opacity: controller.answerShown && o.id != activity.correctId ? 0.35 : 1,
                    child: AnswerTile(
                      key: Key('tile-${o.id}'),
                      semanticLabel: '${o.value}',
                      state: chosenId == o.id
                          ? chosenState
                          : ((controller.answerShown && o.id == activity.correctId) || voiceLit == o.id
                                ? AnswerState.selected
                                : AnswerState.idle),
                      onPressed: () => choose(o.id),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Text(
                            '${o.value}',
                            style: AppText.fixed(size: spec.tileFont, weight: 800, lineHeight: 1),
                          ),
                          const SizedBox(height: 4),
                          FittedBox(fit: BoxFit.scaleDown, child: Dots(o.value!)),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        // While the objects are being counted the answer area is free: hint 2 opens its card there, beside the scene.
        if (fingers > 0 && !answering)
          IgnorePointer(
            child: SizedBox(
              height: 112,
              child: CountingAid(n: activity.count, shown: fingers),
            ),
          ),
      ],
    ),
  );
}

/// A row of small dots, one for each thing, as the second way of showing a number (R2).
class Dots extends StatelessWidget {
  const Dots(this.count, {super.key});

  final int count;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      for (int i = 0; i < count; i++)
        Container(
          width: 8,
          height: 8,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: const BoxDecoration(color: TokenColors.inkSoft, shape: BoxShape.circle),
        ),
    ],
  );
}

class _CountStage extends StatelessWidget {
  const _CountStage(this.s, this.size);

  final CountTapSession s;
  final Size size;

  @override
  Widget build(BuildContext context) {
    final CountTapActivity a = s.activity;
    final CountLayout layout = CountLayout(size, a);
    final double touch = math.max(layout.objectSize, 48);
    final Offset target = layout.flowerCentre;
    return Semantics(
      container: true,
      label: a.altText,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(TokenRadius.lg),
        child: Stack(
          key: const Key('count-stage'),
          clipBehavior: Clip.none,
          children: <Widget>[
            if (a.background != null)
              Positioned.fill(child: PackSvg(a.assets.svg(a.background!), fit: BoxFit.cover)),
            Positioned.fromRect(
              rect: layout.flower,
              child: PackSvg(a.assets.svg(a.targetSprite), key: const Key('count-flower')),
            ),
            for (int i = 0; i < a.count; i++) _object(a, layout, touch, target, i),
            if (s.counter > 0)
              Positioned(
                left: layout.flower.center.dx - 26,
                top: layout.flower.bottom - 34,
                child: Semantics(
                  label: '${He.counterSemantics.text} ${s.counter}',
                  child: Container(
                    key: const Key('counter'),
                    width: 52,
                    height: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: TokenColors.paper,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: softShadow,
                    ),
                    child: MathIsolate(
                      child: Text('${s.counter}', style: AppText.fixed(size: 28, weight: 800, lineHeight: 1)),
                    ),
                  ),
                ),
              ),
            if (s.fingers > 0 && s.answering)
              Positioned(
                left: 8,
                bottom: 6,
                child: IgnorePointer(
                  child: SizedBox(
                    height: size.height - 12,
                    child: CountingAid(n: a.count, shown: s.fingers),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _object(CountTapActivity a, CountLayout layout, double touch, Offset target, int i) {
    final bool done = s.counted.contains(i);
    final bool gone = s.flies && done;
    final bool away = s.arrived.contains(i);
    final Offset c = gone ? target : layout.centers[i];
    final bool lit = done && !s.flies;
    final bool wiggle = s.wiggling == i;
    return AnimatedPositioned(
      key: Key('butterfly-$i'),
      duration: const Duration(milliseconds: 550),
      curve: Curves.easeInOut,
      left: c.dx - touch / 2,
      top: c.dy - touch / 2,
      width: touch,
      height: touch,
      child: IgnorePointer(
        ignoring: away,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => s.tapObject(i),
          child: AnimatedScale(
            scale: gone ? 0.3 : (wiggle ? 1.3 : 1),
            duration: Duration(milliseconds: gone ? 550 : 250),
            child: AnimatedOpacity(
              opacity: gone ? 0 : 1,
              duration: const Duration(milliseconds: 550),
              child: AnimatedRotation(
                turns: wiggle ? 0.04 : 0,
                duration: const Duration(milliseconds: 250),
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: <Widget>[
                    PackSvg(
                      a.assets.svg(lit ? a.litSprite : a.sprite),
                      width: layout.objectSize * (lit ? 1.15 : 1),
                      height: layout.objectSize * (lit ? 1.15 : 1),
                    ),
                    if (s.seen.contains(i))
                      const Positioned(top: 2, right: 2, child: SeenDot(key: Key('seen-dot'))),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
