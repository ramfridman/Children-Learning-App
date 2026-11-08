import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../child/activity_shell.dart';
import '../content/hint_ladder.dart';
import '../content/models.dart';
import '../design/app_text.dart';
import '../design/board.dart' show BoardClass;
import '../engine/course.dart' show Course;
import '../design/components.dart';
import '../design/course_text.dart';
import '../design/layout.dart';
import '../design/tokens.g.dart';
import '../speech/answer_matcher.dart';
import '../strings/he.dart';
import 'hint_widgets.dart';
import 'hints/hint_player.dart';
import 'hints/pointer_plans.dart';
import 'choice_row.dart' show withTallStage;
import 'lesson_controller.dart';
import 'listen_do_session.dart' show ListenDoSession;
import 'option_faces.dart';
import 'template_session.dart';

/// Where the objects of a count-and-tap scene stand inside the stage, in the stage's own points.
/// The same seed always gives the same places.
class CountLayout {
  CountLayout(Size size, CountTapActivity a) {
    final double h = size.height;
    if (Course.isLanguage(a.course) && countsInPlace(a)) {
      _language(size, a);
      return;
    }
    final double flowerH = h * 0.86;
    final double flowerW = flowerH * 0.8;
    flower = Rect.fromLTWH(size.width - flowerW - 10, (h - flowerH) / 2, flowerW, flowerH);
    objectSize = math.min(60, math.max(36, h * 0.34));
    touch = math.max(objectSize, 48);
    final Rect region = Rect.fromLTRB(10, 8, flower.left - 8, h - 8);
    centers = a.arrangement == 'line' ? _line(region, a.count) : _scatter(region, a.count, a.seed);
  }

  /// A count whose target is the blank picture: nothing is there to fly to, so the objects are counted where they stand.
  static bool countsInPlace(CountTapActivity a) => a.targetSprite.split(':').last == 'blank';

  /// A language course counts in place (nothing flies to a flower, whose sprite is blank): the objects have the stage but a strip at
  /// its end for the counter, in one row or in two to four, whichever makes them largest, each in a cell of its own (QA-BA-6:
  /// Band A, a child control is at least 64 points, and the phone's 128-point stage made them 48). The counter stands at the bottom
  /// of the strip.
  void _language(Size size, CountTapActivity a) {
    const double strip = 56;
    // The strip ends 10 above the stage's bottom, so the counter (40 high, 34 above the strip's bottom) stays inside the stage.
    flower = Rect.fromLTWH(size.width - strip - 4, 0, strip, size.height - 10);
    final Rect region = Rect.fromLTRB(8, 6, flower.left - 4, size.height - 6);
    final int n = math.max(1, a.count);
    int rows = 1;
    double cell = 0;
    for (int r = 1; r <= math.min(4, n); r++) {
      final double c = math.min(region.width / (n / r).ceil(), region.height / r);
      if (c > cell + 0.5) {
        cell = c;
        rows = r;
      }
    }
    objectSize = math.min(96, cell * 0.84);
    // The touch square is the object's cell, at most 96: two touch squares never overlap (a touch on a neighbour would start the count
    // again). On the phone's 128-point stage a cell is 64 or more up to four objects; five to ten need the tall stage while they are
    // counted (docs/design/languages-band-a-qa.md section 3).
    touch = math.min(cell, 96);
    final int cols = (n / rows).ceil();
    final double top = region.center.dy - rows * cell / 2;
    centers = <Offset>[
      for (int i = 0; i < n; i++)
        Offset(
          // Each row is centred on its own (a last row of fewer stands in the middle), and the objects run left to right (a count
          // is read in order, and numbers never mirror).
          region.center.dx + ((i % cols) - (math.min(cols, n - (i ~/ cols) * cols) - 1) / 2) * cell,
          top + (i ~/ cols + 0.5) * cell,
        ),
    ];
  }

  late final Rect flower;
  late final double objectSize;

  /// The square each object is touched in.
  late final double touch;
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
///
/// In a language course (docs/languages/frame.md section 2.2) the counting taps are practice and never scored: each tap plays the
/// next number word, a touch on an object already counted lights it and starts the count again (a counting error is maths, not
/// language, so it is no evidence and carries no tag), and the one scored step is "how many?", answered on sound buttons that
/// each play a number word.
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

  /// The pointing hand of the worked example (level 3), and the stage's size it is placed by.
  late final HintPlayer _hint = HintPlayer(this);
  Size _size = Size.zero;

  bool get flies => activity.onTap == 'fly_to_target';

  /// Five or more objects counted in place in a course: on a phone they have the tall stage while they are counted, so that each has a cell
  /// of 58 points or more (Band A: a child control is at least 64, the SE's ten objects 58); at the question the stage is the usual one
  /// again, to leave the room to the answers (docs/design/languages-band-a-qa.md section 3).
  bool get _tallWhileCounting =>
      activity.isLanguage && CountLayout.countsInPlace(activity) && activity.count >= 5;

  @override
  ActivitySpec layoutFor(ActivitySpec base) =>
      _tallWhileCounting && !answering && !base.stageIsCard ? withTallStage(base) : base;
  int get counter => counted.length;

  void tapObject(int i) {
    if (answering || _recounting || (demoRunning && !_demoStep)) return;
    seen.clear();
    if (counted.contains(i) && activity.isLanguage) {
      _countAgain(i);
      return;
    }
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
    if (activity.isLanguage && counted.length <= activity.clips.length) {
      playClips?.call(<String>[activity.clips[counted.length - 1]], replace: true);
    }
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

  /// In a course: the object that was counted twice is lighting, and the count is about to start again.
  bool _recounting = false;

  void _countAgain(int i) {
    _recounting = true;
    wiggling = i;
    notify();
    later(const Duration(milliseconds: 500), () {
      _recounting = false;
      wiggling = null;
      counted.clear();
      arrived.clear();
      notify();
    });
  }

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
    final ChoiceOption chosen = activity.options.firstWhere((ChoiceOption o) => o.id == id);
    if (chosen.clip != null && !byVoice) playClips?.call(<String>[chosen.clip!], replace: true);
    final Outcome o = await controller.chooseOption(
      id,
      traceTag: touchedTwice && !activity.isLanguage ? activity.traceTags['same_object_tapped_twice'] : null,
      byVoice: byVoice,
    );
    if (disposed) return;
    if (o.correct) {
      chosenState = AnswerState.correct;
      notify();
      later(praise, controller.next);
    } else {
      chosenState = AnswerState.notYet;
      notify();
      later(TemplateSession.notYetPause, () {
        chosenId = null;
        chosenState = AnswerState.idle;
        _busy = false;
        if (controller.guided) {
          _workedExample();
        } else if (!activity.isLanguage) {
          // In a course the count was practice and is done: the scored step stays on offer, with the hint.
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
    _hint.clear();
    notify();
  }

  @override
  void onReplay() => _lightEach(dots: false);

  @override
  void onHint() {
    // Sound buttons play again, one after the other, after the hint's own line.
    if (activity.isLanguage && answering) {
      playClips?.call(<String>[
        for (final ChoiceOption o in activity.options)
          if (o.clip != null) o.clip!,
      ], replace: false);
    }
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
    if (!_size.isEmpty) {
      // The hand reaches each object as it is counted, and a badge stays on it where it stays on the stage.
      final CountLayout l = CountLayout(_size, activity);
      _hint.play(
        pointerCountPlan(
          l.centers,
          badges: !flies,
          badgeAt: (int i) => l.centers[i] + Offset(l.objectSize * 0.4, -l.objectSize * 0.4),
          tailMs: 650,
        ),
      );
    }
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
  Widget buildStage(BuildContext context, Size size, ActivitySpec spec) {
    _size = size;
    return ListenableBuilder(
      listenable: this,
      builder: (BuildContext c, Widget? _) => _CountStage(this, size),
    );
  }

  @override
  Widget? buildHands(BuildContext context, Size size, ActivitySpec spec) => _hint.hands(size, spec);

  @override
  Widget? buildTiles(BuildContext context, ActivitySpec spec) => ListenableBuilder(
    listenable: this,
    builder: (BuildContext c, Widget? _) => Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: <Widget>[
        IgnorePointer(
          ignoring: !answering,
          child: AnimatedOpacity(
            opacity: answering ? 1 : 0,
            duration: const Duration(milliseconds: 300),
            // The row follows the course's reading direction, as in every language item (F1).
            child: Directionality(
              textDirection: courseRowDirection(activity.course) ?? Directionality.of(c),
              child: TileRow(
                children: <Widget>[
                  for (final ChoiceOption o in activity.options)
                    Opacity(
                      opacity: controller.answerShown && o.id != activity.correctId ? 0.35 : 1,
                      child: AnswerTile(
                        key: Key('tile-${o.id}'),
                        // A sound button names nothing: the number word is the answer, and it is heard.
                        semanticLabel: o.soundOnly ? He.optionSoundSemantics.text : '${o.value}',
                        state: chosenId == o.id
                            ? chosenState
                            : ((controller.answerShown && o.id == activity.correctId) || voiceLit == o.id
                                  ? AnswerState.selected
                                  : AnswerState.idle),
                        onPressed: () => choose(o.id),
                        child: o.soundOnly
                            ? const SoundFace()
                            : Column(
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
        ),
        // While the objects are being counted the answer area is free: hint 2 opens its card there, beside the scene. (Under the tall stage
        // the stage has taken it: the card stands in the close-up slot, see [buildBoardLayer].)
        if (fingers > 0 && !answering && !(_tallWhileCounting && !spec.stageIsCard))
          AnswerAreaCard(
            spec: spec,
            child: CountingAid(n: activity.count, shown: fingers, scale: AnswerAreaCard.scaleOf(spec)),
          ),
      ],
    ),
  );

  /// Hint 2's counting card under the tall stage (a phone, five or more objects): in the slot outside the stage that a close-up card of
  /// a listen-and-do has, so that it never covers an object.
  @override
  Widget? buildBoardLayer(BuildContext context, ActivitySpec spec) {
    if (!_tallWhileCounting || spec.stageIsCard) return null;
    final BoardClass board = AppLayout.of(context).board;
    return Positioned.fill(
      child: IgnorePointer(
        child: ListenableBuilder(
          listenable: this,
          builder: (BuildContext c, Widget? _) {
            if (fingers <= 0 || answering) return const SizedBox();
            final ({double x, double y, double side}) slot = ListenDoSession.closeUpSlot(board, false);
            return Stack(
              children: <Widget>[
                Positioned(
                  left: slot.x,
                  top: slot.y,
                  width: slot.side,
                  height: slot.side,
                  child: CountingAid(n: activity.count, shown: fingers, scale: 0.8),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
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
    final double touch = layout.touch;
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
            Positioned.fill(child: s._hint.body(size)),
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
