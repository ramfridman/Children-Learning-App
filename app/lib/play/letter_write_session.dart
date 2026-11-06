import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../child/activity_shell.dart';
import '../content/hint_ladder.dart';
import '../content/models.dart';
import '../content/strokes.dart';
import '../design/components.dart';
import '../design/tokens.g.dart';
import 'choice_row.dart' show withTallStage;
import 'hints/hint_marks.dart';
import 'hints/hint_pictures.dart';
import 'response_code.dart';
import 'stroke_check.dart';
import 'stroke_geometry.dart';
import 'template_session.dart';

/// LS02 write a letter (docs/milestones/L5.md section 5.2, docs/languages/writing-mastery.md): the worked example of a letter (`intro`),
/// then trace it, copy it and write it from memory, in a box of 100 by 100 units on the lines of the script, or a word letter by letter.
///
/// Feedback comes only at the end of a stroke, never during it. `trace` keeps the path check of T04; `copy` and `memory` use the free-stroke
/// check ([LetterChecker]), which reads the start, the direction, the lines, the mirror and the look-alike of a stroke and does not score the
/// order. An error it names writes a row with the course's tag; any other miss writes nothing and only moves the help one step (a retry
/// with no tag and no evidence, writing-mastery section 3.1). A stroke that misses fades softly and its start dot returns: never red.
///
/// Help: level 1 the start dot and the arrow of the stroke the child is on, level 2 that stroke drawn slowly once, level 3 trace mode for
/// this item with the whole dotted path (the same in all three courses). The child's points live only in this session.
class LetterWriteSession extends TemplateSession {
  LetterWriteSession(super.controller, this.activity)
    : set = controller.content.strokeSets[StrokeSet.setOf(activity.forms.first)]!,
      rtl = controller.content.strokeSets[StrokeSet.setOf(activity.forms.first)]!.rtl {
    final List<StrokeForm> partners = <StrokeForm>[
      for (final String id in activity.partners.keys)
        if (set.forms[id] != null) set.forms[id]!,
    ];
    boxes = <LetterBox>[
      for (final String id in activity.forms)
        LetterBox(
          set.forms[id]!,
          LetterChecker(set.forms[id]!, partners: activity.word ? const <StrokeForm>[] : partners),
        ),
    ];
    _begin();
  }

  final LetterWriteActivity activity;
  final StrokeSet set;

  /// The script is written from the right (Hebrew): a word's first letter is at the right, and a model stands on the right of its box.
  final bool rtl;
  late final List<LetterBox> boxes;

  /// The letter being written (a word canvas goes through its boxes in the course's direction).
  int active = 0;
  List<Offset> current = <Offset>[];
  List<Offset> fading = <Offset>[];
  AnswerState ring = AnswerState.idle;
  bool _busy = false;

  /// The demonstration dot, and the part of the model stroke it has drawn so far.
  Offset? demo;
  List<Offset> demoTrail = <Offset>[];
  int _demoId = 0;

  /// The pointing hand rests on the start dot for a moment (level 1, and the start of level 3), never riding the path over the letter.
  bool _handShown = false;

  /// Copy with the model hidden: the model is covered until the child asks to see it again.
  bool _modelCovered = false;
  int _coverId = 0;

  /// The worked example: 0 listen, 1 watch the dot walk, 2 trace once.
  int introStep = 0;
  String? introLit;

  /// How many misses that wrote nothing a probe has had.
  int _silentMisses = 0;

  LetterMode get mode => activity.mode;
  bool get intro => mode == LetterMode.intro;
  LetterBox get box => boxes[active];

  /// Trace mode: the item is a trace, an intro's own trace, or the help is at its top (level 3 is trace mode for this item).
  bool get traceMode => mode == LetterMode.trace || intro || controller.hintShown >= 3;

  /// The whole dotted path of the strokes still to write (a full-guide trace, the intro and level 3).
  bool get fullGuide =>
      (mode == LetterMode.trace && activity.fullGuide) || intro || controller.hintShown >= 3;

  /// The start dot of the stroke the child is on shows from the first help on, and always in a trace with the start dot only.
  bool get startDotShown =>
      fullGuide || mode == LetterMode.trace || controller.hintShown >= 1 || demo != null;

  /// Copy's model: shown beside the box, or covered after a moment.
  bool get hasModel => mode == LetterMode.copy;
  bool get modelShown => hasModel && !_modelCovered;

  // ---- the start of the item ----

  static const Duration _modelStays = Duration(milliseconds: 3600);

  void _begin() {
    if (mode == LetterMode.copy && activity.modelHidden) {
      later(_modelStays, () {
        _modelCovered = true;
        notify();
      });
    }
    if (intro) _playIntro();
  }

  void _playIntro() {
    final LetterIntro i = activity.intro!;
    // The sound with its key word and picture, then the name as a separate fact, then the dot walks the path, then the child's one trace.
    later(const Duration(milliseconds: 900), () => _say(<String>[i.sound, ?i.keyword], lit: 'sound'));
    later(const Duration(milliseconds: 3600), () => _say(<String>[i.name], lit: 'name'));
    later(const Duration(milliseconds: 5600), () {
      introLit = null;
      introStep = 1;
      _walk(allStrokes: true, msPerPoint: 55);
    });
    later(const Duration(milliseconds: 5600 + 3200), () {
      introStep = 2;
      notify();
    });
  }

  /// Plays clips of the worked example (a tap on a speaker cuts in) and lights its speaker for a moment.
  void _say(List<String> clips, {required String lit}) {
    introLit = lit;
    playClips?.call(clips, replace: true);
    notify();
    later(const Duration(milliseconds: 1500), () {
      if (introLit == lit) {
        introLit = null;
        notify();
      }
    });
  }

  /// The speaker of the sound (with its key word) or of the name, tapped by the child.
  void hear(String which) {
    final LetterIntro i = activity.intro!;
    _say(which == 'name' ? <String>[i.name] : <String>[i.sound, ?i.keyword], lit: which);
  }

  /// The model was covered and the child asks to see it again: that is level 1 of the help (writing-mastery section 7.1).
  void peek() {
    if (!hasModel || !_modelCovered || _busy) return;
    if (controller.hintShown < 1) controller.showHint();
    _modelCovered = false;
    final int id = ++_coverId;
    notify();
    later(_modelStays, () {
      if (_coverId != id) return;
      _modelCovered = true;
      notify();
    });
  }

  // ---- the child's strokes ----

  bool get _canDraw => !_busy && ring != AnswerState.correct && !(intro && introStep < 2);

  void begin(Offset p) {
    if (!_canDraw) return;
    fading = <Offset>[];
    current = <Offset>[p];
    notify();
  }

  void extend(Offset p) {
    if (!_canDraw || current.isEmpty) return;
    current.add(p);
    notify();
  }

  /// A tap: a dot is a tap near its point.
  Future<void> tap(Offset p) async {
    if (!_canDraw) return;
    current = <Offset>[p, p + const Offset(0.4, 0.4)];
    await end();
  }

  Future<void> end() async {
    if (!_canDraw || current.length < 2) {
      current = <Offset>[];
      notify();
      return;
    }
    final List<Offset> drawn = current;
    current = <Offset>[];
    _stopDemo();
    final LetterChecker c = box.checker;
    final StrokeVerdict v = traceMode ? c.traceCheck(drawn, traceTolerance) : c.check(drawn);
    if (v.right) {
      box.ink.add(drawn);
      if (c.complete) {
        await _boxDone();
      } else {
        notify();
      }
      return;
    }
    await _miss(v, drawn);
  }

  /// How far from the dotted path a finger may be when it traces, in box units.
  static const double traceTolerance = 9;

  Future<void> _boxDone() async {
    if (active < boxes.length - 1) {
      active++;
      _silentMisses = 0;
      notify();
      return;
    }
    _busy = true;
    if (intro) {
      ring = AnswerState.correct;
      controller.completePractice();
      notify();
      later(TemplateSession.praisePause, controller.next);
      return;
    }
    await controller.submitPlacement(right: true, response: ResponseCode.written);
    if (disposed) return;
    ring = AnswerState.correct;
    notify();
    // After a success the model replays once, in its order: it is not a hint, it comes after the answer.
    final int ms = _replayModel();
    later(
      Duration(milliseconds: math.max(TemplateSession.praisePause.inMilliseconds, ms + 700)),
      controller.next,
    );
  }

  /// The tag of the error [v] names, or null when it names none that counts: a miss with no tag in the item, and a look-alike the course
  /// counts as "on the way" (a homophone: the child wrote a real letter for the sound), write nothing.
  String? _tagOf(StrokeVerdict v) {
    final String? tag = switch (v.fault) {
      StrokeFault.start => activity.classify['start'],
      StrokeFault.direction => activity.classify['direction'],
      StrokeFault.lines => activity.classify['lines'],
      StrokeFault.mirror => activity.classify['mirror'],
      StrokeFault.partner => activity.partners[v.partner],
      null => null,
    };
    if (tag == null) return null;
    if (v.fault == StrokeFault.partner && controller.content.tags[tag]?.kind == 'on_the_way') return null;
    return tag;
  }

  String _code(StrokeVerdict v) {
    final String what = switch (v.fault) {
      StrokeFault.start => 'start',
      StrokeFault.direction => 'dir',
      StrokeFault.lines => 'lines',
      StrokeFault.mirror => 'mirror',
      StrokeFault.partner => 'partner',
      null => 'miss',
    };
    final int stroke = box.checker.matched + 1;
    return activity.word
        ? ResponseCode.boxStroke(active + 1, stroke, what)
        : ResponseCode.strokeFault(stroke, what);
  }

  Future<void> _miss(StrokeVerdict v, List<Offset> drawn) async {
    fading = drawn;
    if (intro) {
      // Nothing in the worked example is wrong: the stroke fades and the start dot is there again.
      notify();
      later(const Duration(milliseconds: 700), () {
        fading = <Offset>[];
        notify();
      });
      return;
    }
    if (controller.guided) {
      // The help is at its top: a wrong stroke is not counted again; the way is shown once more instead.
      _walk();
      return;
    }
    final String? tag = _tagOf(v);
    // Tracing is practice with the path in view: every miss is a row, as T04 writes it. Copy and memory write a row for an error they
    // can name and tag; any other miss writes nothing, and the help is moved one step as if the child had asked.
    if (mode == LetterMode.trace || tag != null) {
      _busy = true;
      final String response = mode == LetterMode.trace
          ? (v.fault == StrokeFault.start ? ResponseCode.tracedBackwards : ResponseCode.tracedOff)
          : _code(v);
      await controller.submitPlacement(right: false, tag: tag ?? '', response: response);
      if (disposed) return;
      ring = AnswerState.notYet;
      notify();
      later(TemplateSession.notYetPause, () {
        fading = <Offset>[];
        ring = AnswerState.idle;
        _busy = false;
        notify();
      });
      return;
    }
    _silentMisses++;
    if (controller.current.purpose == 'probe') {
      // A probe has no help: a second miss that cannot be named ends the item with no row, and nothing is held against the child.
      later(const Duration(milliseconds: 700), () {
        fading = <Offset>[];
        notify();
        if (_silentMisses >= 2) {
          _busy = true;
          controller.completePractice();
          later(TemplateSession.praisePause, controller.next);
        }
      });
      notify();
      return;
    }
    controller.showHint();
    later(const Duration(milliseconds: 700), () {
      fading = <Offset>[];
      notify();
    });
    notify();
  }

  // ---- the help ----

  void _stopDemo() {
    _demoId++;
    demo = null;
    demoTrail = <Offset>[];
    _handShown = false;
  }

  /// A dot walks along the stroke that is next (all the strokes still to write with [allStrokes]), leaving a trail of the stroke it has
  /// drawn. [fraction] is how much of the stroke it walks, [msPerPoint] how slowly.
  void _walk({double fraction = 1, int msPerPoint = 70, bool allStrokes = false, bool trail = false}) {
    _stopDemo();
    final int id = _demoId;
    final List<int> order = <int>[
      for (int i = 0; i < box.form.strokes.length; i++)
        if (!box.checker.done[i] && box.form.strokes[i].kind != StrokeKind.dot) i,
    ];
    if (order.isEmpty) return;
    // The hand rests on the start dot while the dot waits there, then goes: it never rides the path over the letter.
    _handShown = true;
    notify();
    int at = 14;
    for (final int k in allStrokes ? order : <int>[order.first]) {
      final List<Offset> path = resampleStroke(box.form.strokes[k].points, 24);
      final int shown = math.max(2, (path.length * fraction).round());
      later(Duration(milliseconds: msPerPoint * at), () {
        if (_demoId != id) return;
        _handShown = false;
        demoTrail = <Offset>[];
        notify();
      });
      for (int i = 0; i < shown; i++) {
        later(Duration(milliseconds: msPerPoint * (++at)), () {
          if (_demoId != id) return;
          demo = path[i];
          if (trail || allStrokes) demoTrail = <Offset>[...demoTrail, path[i]];
          notify();
        });
      }
      at += 6; // a short rest between strokes
    }
    later(Duration(milliseconds: msPerPoint * (at + 6)), () {
      if (_demoId != id) return;
      demo = null;
      demoTrail = <Offset>[];
      notify();
      if (allStrokes) controller.demoDone();
    });
    notify();
  }

  /// Drawn slowly once, then the box clears of the demonstration (level 2).
  int _replayModel() {
    _stopDemo();
    final int id = _demoId;
    int at = 0;
    const int step = 45;
    for (final StrokeModel m in box.form.strokes) {
      if (m.kind == StrokeKind.dot) continue;
      final List<Offset> path = resampleStroke(m.points, 20);
      for (final Offset p in path) {
        later(Duration(milliseconds: step * (++at)), () {
          if (_demoId != id) return;
          demo = p;
          demoTrail = <Offset>[...demoTrail, p];
          notify();
        });
      }
      at += 4;
    }
    later(Duration(milliseconds: step * (at + 4)), () {
      if (_demoId != id) return;
      demo = null;
      demoTrail = <Offset>[];
      notify();
    });
    return step * (at + 4);
  }

  @override
  void onReset() {
    for (final LetterBox b in boxes) {
      b.ink.clear();
      b.checker.reset();
    }
    active = 0;
    current = <Offset>[];
    fading = <Offset>[];
    ring = AnswerState.idle;
    _busy = false;
    _stopDemo();
    notify();
  }

  @override
  void onReplay() {}

  @override
  void onHint() {
    if (_busy && ring == AnswerState.correct) return;
    _busy = false;
    switch (hintPictureOf(activity)) {
      case HintPicture.firstStroke:
        // Level 1: where to start and which way: the start dot, the first of the stroke, and the hand resting on the dot.
        _walk(fraction: 0.3);
      case HintPicture.wholeStroke:
        // Level 2: the stroke drawn slowly once; then the box is clear of it.
        _walk(msPerPoint: 110, trail: true);
      default:
        // Level 3: trace mode for this item: the whole dotted path, and the dot walks it once before the child's turn.
        _walk(allStrokes: true);
    }
  }

  // ---- geometry: where the boxes are on the stage ----

  /// Where everything stands on a stage of [size]: the writing box, the model box (copy), the slots of a word, the column of an intro.
  LetterLayout layout(Size size) {
    final bool tablet = size.shortestSide > 420;
    final double gap = tablet ? 20 : 12;
    if (intro) {
      // A phone's stage is narrow: the picture and the two speakers take the least that holds them (84 to 150), the letter the rest.
      final double colWidth = tablet ? size.width * 0.4 : (size.width * 0.34).clamp(84, 150).toDouble();
      final double side = math.min(size.height - 6, size.width - colWidth - gap);
      final double left = rtl ? size.width - side : 0;
      final Rect boxRect = Rect.fromLTWH(left, (size.height - side) / 2, side, side);
      final double colW = size.width - side - gap;
      final Rect info = Rect.fromLTWH(rtl ? 0 : side + gap, boxRect.top, math.max(0, colW), side);
      return LetterLayout(box: boxRect, info: info);
    }
    if (activity.word) {
      final double slotsH = tablet ? 84 : 52;
      final int n = boxes.length;
      final double slot = math.min(slotsH - 8, (size.width - gap * (n - 1)) / n);
      final double rowW = slot * n + gap * (n - 1);
      final double startX = (size.width - rowW) / 2;
      final List<Rect> slots = <Rect>[
        for (int i = 0; i < n; i++)
          Rect.fromLTWH(
            rtl ? startX + rowW - slot * (i + 1) - gap * i : startX + (slot + gap) * i,
            4,
            slot,
            slot,
          ),
      ];
      final double side = math.min(size.width, size.height - slotsH - gap);
      return LetterLayout(
        box: Rect.fromLTWH((size.width - side) / 2, slotsH + gap, side, side),
        slots: slots,
      );
    }
    if (hasModel) {
      // Two equal squares on a tablet; on a phone the model is the smaller (a copy is made at any size) so that the box the child writes in
      // keeps the room: three fifths of the width at least.
      final double room = size.width - gap;
      final double side = math.min(tablet ? room / 2 : room * 0.62, size.height - 6);
      final double model = math.min(room - side, side);
      final double rowW = side + model + gap;
      final double startX = (size.width - rowW) / 2;
      // The model stands where reading begins: on the left in English and Russian, on the right in Hebrew; the child's box is beside it.
      final Rect lead = Rect.fromLTWH(
        rtl ? startX + side + gap : startX,
        (size.height - model) / 2,
        model,
        model,
      );
      final Rect other = Rect.fromLTWH(
        rtl ? startX : startX + model + gap,
        (size.height - side) / 2,
        side,
        side,
      );
      return LetterLayout(box: other, model: lead);
    }
    final double side = math.min(size.width, size.height) - 6;
    return LetterLayout(box: Rect.fromLTWH((size.width - side) / 2, (size.height - side) / 2, side, side));
  }

  /// Where the next stroke starts, in stage points, for the hand and the start dot.
  Offset? startPoint(Size size) {
    final int? i = box.checker.next;
    if (i == null) return null;
    final Rect r = layout(size).box;
    final Offset p = box.form.strokes[i].start;
    return r.topLeft + p / 100 * r.width;
  }

  // ---- drawing ----

  @override
  ActivitySpec layoutFor(ActivitySpec base) => withTallStage(base);

  @override
  Widget buildHands(BuildContext context, Size size, ActivitySpec spec) => ListenableBuilder(
    listenable: this,
    builder: (BuildContext c, Widget? _) {
      final Offset? tip = _handShown ? startPoint(size) : null;
      if (tip == null) return const SizedBox();
      final int? i = box.checker.next;
      // From the guide's side above the dot where the stroke starts high (most letters), and from below where it starts low, so that the
      // hand never lies over the letter it points at.
      final bool low = i != null && box.form.strokes[i].start.dy > 55;
      return HintOverlay(
        marks: <HintMark>[HandMark(tip, from: low ? HandFrom.below : HandFrom.guide)],
        size: size,
        clearOf: handClearOf(spec),
        layer: HintLayer.hands,
      );
    },
  );

  @override
  Widget buildStage(BuildContext context, Size size, ActivitySpec spec) => ListenableBuilder(
    listenable: this,
    builder: (BuildContext c, Widget? _) {
      final LetterLayout l = layout(size);
      Offset toBox(Offset local) => (local - l.box.topLeft) / l.box.width * 100;
      return Semantics(
        container: true,
        label: activity.altText,
        child: SizedBox(
          key: const Key('letter-stage'),
          width: size.width,
          height: size.height,
          child: Stack(
            clipBehavior: Clip.none,
            children: <Widget>[
              Positioned.fill(
                child: GestureDetector(
                  key: const Key('trace-touch'),
                  behavior: HitTestBehavior.opaque,
                  onPanStart: (DragStartDetails d) {
                    if (l.box.inflate(10).contains(d.localPosition)) begin(toBox(d.localPosition));
                  },
                  onPanUpdate: (DragUpdateDetails d) => extend(toBox(d.localPosition)),
                  onPanEnd: (DragEndDetails d) => end(),
                  onTapUp: (TapUpDetails d) {
                    if (l.box.inflate(10).contains(d.localPosition)) tap(toBox(d.localPosition));
                  },
                  child: CustomPaint(painter: _StagePainter(this, l), size: size),
                ),
              ),
              if (hasModel && activity.modelHidden && _modelCovered && l.model != null)
                Positioned.fromRect(
                  rect: l.model!,
                  child: Semantics(
                    button: true,
                    label: activity.altText,
                    child: GestureDetector(
                      key: const Key('peek'),
                      behavior: HitTestBehavior.opaque,
                      onTap: peek,
                      child: const Center(
                        child: Icon(Icons.visibility_rounded, size: 40, color: TokenColors.inkSoft),
                      ),
                    ),
                  ),
                ),
              if (intro && l.info != null) _introColumn(l.info!),
            ],
          ),
        ),
      );
    },
  );

  Widget _introColumn(Rect r) {
    final LetterIntro i = activity.intro!;
    final String? picture = i.picture;
    // Two speakers side by side fit the column, however narrow the phone makes it.
    final double touch = math.min(64, r.width / 2);
    Widget speaker(String which, Key key) => GestureDetector(
      key: key,
      behavior: HitTestBehavior.opaque,
      onTap: () => hear(which),
      child: SizedBox(
        width: touch,
        height: touch,
        child: Center(
          child: Container(
            width: touch * 0.82,
            height: touch * 0.82,
            decoration: BoxDecoration(
              color: introLit == which ? TokenColors.sparkTint : TokenColors.skyTint,
              shape: BoxShape.circle,
              border: Border.all(
                color: introLit == which ? TokenColors.correctGlow : TokenColors.hairline,
                width: TokenBorder.thin,
              ),
            ),
            child: Icon(Icons.volume_up_rounded, size: touch * 0.48, color: TokenColors.ink),
          ),
        ),
      ),
    );
    return Positioned.fromRect(
      rect: r,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          if (picture != null)
            Flexible(
              child: AnimatedContainer(
                key: const Key('intro-picture'),
                duration: const Duration(milliseconds: 250),
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(TokenRadius.md),
                  border: Border.all(
                    color: introLit == 'sound' ? TokenColors.correctGlow : TokenColors.hairline,
                    width: TokenBorder.thin,
                  ),
                ),
                child: PackSvg(
                  activity.assets.svg(picture),
                  height: math.min(r.shortestSide > 200 ? 190 : 110, r.height * 0.5),
                ),
              ),
            ),
          const SizedBox(height: 6),
          Row(
            mainAxisSize: MainAxisSize.min,
            textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
            children: <Widget>[
              speaker('sound', const Key('intro-sound')),
              speaker('name', const Key('intro-name')),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget? buildTiles(BuildContext context, ActivitySpec spec) => null;
}

/// One letter box: the letter, what checks the child's strokes of it, and the strokes it was written with.
class LetterBox {
  LetterBox(this.form, this.checker);

  final StrokeForm form;
  final LetterChecker checker;
  final List<List<Offset>> ink = <List<Offset>>[];
}

/// Where everything stands on a stage, in the stage's points.
class LetterLayout {
  const LetterLayout({required this.box, this.model, this.slots = const <Rect>[], this.info});

  /// The box the child writes in.
  final Rect box;

  /// Copy: the box that holds the model.
  final Rect? model;

  /// A word: the row of small boxes, one for each letter, the first where the course starts reading.
  final List<Rect> slots;

  /// An intro: the room for the key-word picture and the two speakers.
  final Rect? info;
}

/// The model letter, drawn from the smooth paths of its strokes in a box: [k] points to a unit.
Path _letterPath(StrokeForm form, double k, {Offset origin = Offset.zero}) {
  final Path path = Path();
  for (final StrokeModel m in form.strokes) {
    _addD(path, m.d, k, origin);
  }
  return path;
}

/// Adds an SVG-like path (M, L and C in box units) scaled by [k].
void _addD(Path path, String d, double k, Offset origin) {
  final List<String> t = d.split(' ');
  int i = 0;
  Offset pt() {
    final Offset o = Offset(double.parse(t[i]) * k, double.parse(t[i + 1]) * k) + origin;
    i += 2;
    return o;
  }

  while (i < t.length) {
    switch (t[i++]) {
      case 'M':
        final Offset p = pt();
        path.moveTo(p.dx, p.dy);
      case 'L':
        final Offset p = pt();
        path.lineTo(p.dx, p.dy);
      case 'C':
        final Offset a = pt();
        final Offset b = pt();
        final Offset e = pt();
        path.cubicTo(a.dx, a.dy, b.dx, b.dy, e.dx, e.dy);
    }
  }
}

class _StagePainter extends CustomPainter {
  _StagePainter(this.s, this.l) : super(repaint: s);

  final LetterWriteSession s;
  final LetterLayout l;

  static const double _round = 20;

  @override
  void paint(Canvas canvas, Size size) {
    final StrokeSet set = s.set;
    // The slots of a word, with the letters written so far.
    for (final (int i, Rect r) in l.slots.indexed) {
      _card(canvas, r, i == s.active ? TokenColors.hintHalo : TokenColors.hairline, radius: 12);
      final LetterBox b = s.boxes[i];
      if (i < s.active || b.checker.complete) {
        _ink(
          canvas,
          _letterPath(b.form, r.width / 100, origin: r.topLeft),
          set.ink * r.width / 100 * 0.8,
          TokenColors.ink,
        );
      }
    }
    if (l.model != null) {
      _card(canvas, l.model!, TokenColors.hairline);
      _guides(canvas, l.model!, set);
      if (s.modelShown) {
        _ink(
          canvas,
          _letterPath(s.box.form, l.model!.width / 100, origin: l.model!.topLeft),
          set.ink * l.model!.width / 100,
          TokenColors.ink.withValues(alpha: 0.9),
        );
      }
    }
    // The writing box: the ring says nothing but "not yet" (soft lilac) and "right" (gold): never red.
    final Color ringColor = switch (s.ring) {
      AnswerState.correct => TokenColors.correctGlow,
      AnswerState.notYet => TokenColors.notYetRing,
      _ => TokenColors.hairline,
    };
    _card(canvas, l.box, ringColor);
    _guides(canvas, l.box, set);
    final double k = l.box.width / 100;
    Offset px(Offset p) => l.box.topLeft + p * k;
    final LetterBox b = s.box;
    // The big letter of the worked example, and the faint letter under a trace with the whole path.
    if (s.intro && s.introStep < 2) {
      _ink(
        canvas,
        _letterPath(b.form, k, origin: l.box.topLeft),
        set.ink * k,
        TokenColors.ink.withValues(alpha: 0.9),
      );
    } else if (s.fullGuide) {
      _ink(
        canvas,
        _letterPath(b.form, k, origin: l.box.topLeft),
        set.ink * k,
        TokenColors.ink.withValues(alpha: 0.14),
      );
    }
    final Paint dot = Paint()..color = TokenColors.ink.withValues(alpha: 0.4);
    final int? next = b.checker.next;
    for (final (int i, StrokeModel m) in b.form.strokes.indexed) {
      final bool done = b.checker.done[i];
      if (s.fullGuide && !done && m.kind == StrokeKind.line) {
        for (final Offset p in resampleStroke(m.points, math.max(6, (strokeLength(m.points) / 5).round()))) {
          canvas.drawCircle(px(p), 2.3 * k, dot);
        }
      }
    }
    // The start dot and the first of the way: a ring, so that the letter beneath it stays in view.
    if (next != null && (s.intro ? s.introStep == 2 : s.startDotShown)) {
      final StrokeModel m = b.form.strokes[next];
      final Paint ringPaint = Paint()
        ..color = TokenColors.correctGlow
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.6 * k;
      canvas.drawCircle(px(m.start), 4.6 * k, ringPaint);
      canvas.drawCircle(px(m.start), 1.6 * k, Paint()..color = TokenColors.correctGlow);
      if (!s.fullGuide && m.kind != StrokeKind.dot) {
        for (final Offset p in resampleStroke(m.points, 12).take(4).skip(1)) {
          canvas.drawCircle(px(p), 2.1 * k, dot);
        }
      }
    }
    // What the child has written.
    for (final List<Offset> stroke in b.ink) {
      _line(canvas, stroke.map(px).toList(), TokenColors.ink, set.ink * k * 0.5);
    }
    if (s.fading.length > 1) {
      _line(canvas, s.fading.map(px).toList(), TokenColors.notYetRing, set.ink * k * 0.5);
    }
    if (s.current.length > 1) _line(canvas, s.current.map(px).toList(), TokenColors.ink, set.ink * k * 0.5);
    // The demonstration: what the dot has drawn, and the dot.
    if (s.demoTrail.length > 1) {
      _line(canvas, s.demoTrail.map(px).toList(), TokenColors.hintHalo, set.ink * k * 0.5);
    }
    if (s.demo != null) canvas.drawCircle(px(s.demo!), 5 * k, Paint()..color = TokenColors.hintHalo);
  }

  void _card(Canvas canvas, Rect r, Color border, {double radius = _round}) {
    final RRect rr = RRect.fromRectAndRadius(r, Radius.circular(radius));
    canvas.drawRRect(rr, Paint()..color = Colors.white.withValues(alpha: 0.9));
    canvas.drawRRect(
      rr,
      Paint()
        ..color = border
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4,
    );
  }

  /// The lines of the script in a box: solid ones for the base (and the top of Hebrew), dashed for the rest.
  void _guides(Canvas canvas, Rect r, StrokeSet set) {
    final double k = r.width / 100;
    for (final MapEntry<String, double> g in set.guides.entries) {
      final double y = r.top + g.value * k;
      final Paint paint = Paint()
        ..color = TokenColors.cardLip
        ..strokeWidth = set.solidGuides.contains(g.key) ? 2 : 1.4;
      final double from = r.left + 8, to = r.right - 8;
      if (set.solidGuides.contains(g.key)) {
        canvas.drawLine(Offset(from, y), Offset(to, y), paint);
      } else {
        for (double x = from; x < to; x += 12) {
          canvas.drawLine(Offset(x, y), Offset(math.min(x + 6, to), y), paint);
        }
      }
    }
  }

  void _ink(Canvas canvas, Path path, double width, Color color) {
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = width
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  void _line(Canvas canvas, List<Offset> pts, Color color, double width) {
    final Path path = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (final Offset p in pts.skip(1)) {
      path.lineTo(p.dx, p.dy);
    }
    _ink(canvas, path, width, color);
  }

  @override
  bool shouldRepaint(_StagePainter old) => true;
}
