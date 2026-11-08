import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../child/activity_shell.dart';
import '../content/models.dart';
import '../design/board.dart' show BoardClass;
import '../design/components.dart';
import '../design/layout.dart';
import '../design/token_types.dart' show Band;
import 'blend_layer.dart';
import 'borrowed_screens.dart';
import 'choice_row.dart' show withLs01Zones;
import 'choice_session.dart';
import '../design/tokens.g.dart';
import 'lesson_controller.dart';
import 'ls01_metrics.dart';
import 'ls01_tiles.dart';
import 'slide_geometry.dart';

/// LS04 blend slide (docs/milestones/L5.md section 5.5, layout docs/design/l5-templates.md section 5): a written word or syllable with a mark under each
/// part. The child slides a knob along a wire in the course's reading direction (English and Russian to the right, Hebrew to the left) and each part lights
/// and sounds as the knob passes; in Russian the consonant tile itself slides to the vowel (`merge`). The slide is practice and writes nothing. Then a
/// choice, the only thing scored: a picture (English, Hebrew) or a sound button (Russian).
///
/// In a scored item the whole word never plays before the choice (heard first, the choice would be a listening item and its reversed-word and
/// letter-name distractors would no longer show a reading error): it plays after any choice. A part with no clip lights in silence. In `merge` a stop
/// moves in silence and only the vowel sounds on meeting (the validator holds that no clip is on a stop).
///
/// The hints (spec section 5.4): level 1 the slide runs by itself, slowly, the parts only; level 2 the parts another way (each as a token, or the
/// borrowed screen the hint names); level 3 the friend slides, the whole plays and the friend's hand points to the answer, which keeps its halo.
class BlendSlideSession extends ChoiceSession {
  BlendSlideSession(
    LessonController controller,
    BlendSlideActivity activity, {
    this.band = Band.b,
    super.stress,
  }) : blend = activity,
       super(controller, activity, activity) {
    _opening();
  }

  final BlendSlideActivity blend;
  final Band band;

  ActivitySpec? _spec;
  BoardClass board = BoardClass.phone;
  SlideGeometry? _geo;
  MergeGeometry? _mergeGeo;

  // ---- the slide ----

  /// How far the knob is along the wire (0 at rest, 1 at the end of the word), and whether a finger is on it.
  double knobT = 0;
  bool dragging = false;
  bool _wrongStart = false;

  /// The knob gives two soft pulses at the first item (the affordance, not a hint).
  bool pulse = false;

  /// The part that sounds now and the parts the knob has passed.
  int? litPart;
  final Set<int> passed = <int>{};
  int _maxPassed = -1;

  /// The knob is sliding by itself (a tap on it, or a hint), and for how long each step takes.
  bool auto = false;
  int stepMs = 400;

  // ---- the merge ----

  /// How far the first tile has slid to the second (0 to 1), whether the held sound has been started, whether the tiles have met, and whether the
  /// two joined into one after the choice.
  double mergeT = 0;
  bool held = false;
  bool met = false;
  bool joined = false;

  // ---- what a hint draws ----

  /// The card over the stage: `tokens` (each part a token, lit in turn) or `borrowed` (the wheel or strip another template draws).
  String? card;
  int? cardLit;
  BorrowedPlan? plan;
  int borrowedStep = 0;
  Offset? handTip;
  int run = 0;

  bool get merge => blend.merge;
  TextDirection get direction => rowDirection;

  // ---- opening ----

  void _opening() {
    // The knob pulses twice at the first item of an activity, never again in it (the lesson screen makes a session for each item, so this is each item's).
    later(const Duration(milliseconds: 600), () {
      pulse = true;
      notify();
    });
    later(const Duration(milliseconds: 1800), () {
      pulse = false;
      notify();
    });
  }

  // ---- the geometry ----

  /// The page of the slide: the stage's room (a tablet's card inside its lip).
  Rect pageOf(ActivitySpec s) => s.stageIsCard ? s.stage.deflate(16) : s.stage;

  SlideGeometry geometry(ActivitySpec spec, BoardClass b) {
    final SlideGeometry? g = _geo;
    final Rect page = pageOf(spec);
    if (g != null && g.page == page && board == b) return g;
    board = b;
    return _geo = SlideGeometry.of(page: page, course: blend.course, word: blend.word, board: b, band: band);
  }

  MergeGeometry mergeGeometry(ActivitySpec spec, BoardClass b) {
    final MergeGeometry? g = _mergeGeo;
    final Rect page = pageOf(spec);
    if (g != null && g.page == page && board == b) return g;
    board = b;
    return _mergeGeo = MergeGeometry.of(page, b);
  }

  // ---- the knob (graphemes and units) ----

  /// A finger goes down at board point [p]: it must be on the knob, or the slide does not start from the wrong end (the knob gives two pulses).
  void slideStart(Offset p, SlideGeometry g) {
    if (busy || auto) return;
    final Offset knob = Offset(g.xAt(knobT), g.trackY);
    _wrongStart = (p - knob).distance > g.knob / 2 + 12;
    if (_wrongStart) {
      _pulseTwice();
      return;
    }
    dragging = true;
    notify();
  }

  void slideTo(double x, SlideGeometry g) {
    if (!dragging || _wrongStart) return;
    knobT = g.tAt(x);
    _enter(g.partAt(g.xAt(knobT)));
    notify();
  }

  void slideEnd() {
    if (!dragging) {
      _wrongStart = false;
      return;
    }
    dragging = false;
    knobT = 0;
    litPart = null;
    notify();
  }

  void _pulseTwice() {
    pulse = true;
    notify();
    later(const Duration(milliseconds: 1200), () {
      pulse = false;
      notify();
    });
  }

  /// The knob's centre entered part [p]: a part that is new sounds and lights; going back plays nothing.
  void _enter(int? p) {
    if (p == null || p == litPart) return;
    litPart = p;
    if (p > _maxPassed) {
      _maxPassed = p;
      passed.add(p);
      _sound(p);
    }
  }

  void _sound(int p) {
    final String? clip = blend.word.parts[p].clip;
    // A stretched part keeps sounding until the next one starts (the player cuts it in): a part with no clip lights in silence.
    if (clip != null) playClips?.call(<String>[clip], replace: true);
  }

  /// A tap on the knob slides it by itself, at a slow pace: each part for its clip's length (a fixed pause when it is pending).
  ///
  /// A hint that slides the knob is one run with what follows it (the whole, the hand): it passes its own run as [within] so that the slide does not end
  /// it; a tap starts a run of its own.
  Future<void> autoSlide({int pace = 700, int? within}) async {
    if (busy || auto || dragging) return;
    final SlideGeometry? g = _geo;
    if (g == null) return;
    final int mine = within ?? ++run;
    auto = true;
    passed.clear();
    _maxPassed = -1;
    notify();
    final int n = blend.word.parts.length;
    for (int i = 0; i < n; i++) {
      if (!_live(mine)) return;
      stepMs = 450;
      knobT = g.tOfPart(i);
      litPart = i;
      passed.add(i);
      _maxPassed = i;
      notify();
      final String? clip = blend.word.parts[i].clip;
      if (clip != null) {
        await sayAndWait(<String>[clip], replace: true, without: Duration(milliseconds: pace));
      } else {
        await pause(Duration(milliseconds: pace));
      }
    }
    if (!_live(mine)) return;
    await _wholeAfterParts(mine);
    if (!_live(mine)) return;
    await pause(const Duration(milliseconds: 300));
    if (!_live(mine)) return;
    stepMs = 400;
    knobT = 0;
    litPart = null;
    auto = false;
    notify();
  }

  /// In a teaching screen and at level 3 the whole follows the parts; at level 1 and in a scored slide it does not.
  bool wholeAfterParts = false;

  Future<void> _wholeAfterParts(int mine) async {
    if (!wholeAfterParts) return;
    final String? whole = blend.word.stretched ?? blend.word.whole;
    if (whole != null) {
      await sayAndWait(<String>[whole], replace: true, without: const Duration(milliseconds: 800));
    }
  }

  bool _live(int mine) => !disposed && mine == run;

  // ---- the merge ----

  void mergeStart() {
    if (busy || auto || met) return;
    dragging = true;
    _startHeld();
    notify();
  }

  void _startHeld() {
    if (held) return;
    held = true;
    final BlendPart first = blend.word.parts[0];
    // A stop moves in silence: it has no clip (the validator refuses one), so only a stretched consonant or a held vowel sounds while it moves.
    if (first.clip != null) playClips?.call(<String>[first.clip!], replace: true);
  }

  void mergeTo(double t) {
    if (!dragging) return;
    mergeT = t.clamp(0, 1);
    final MergeGeometry? g = _mergeGeo;
    if (!met && g != null && mergeT >= g.meetAt) {
      mergeT = 1;
      _meet();
    }
    notify();
  }

  void _meet() {
    met = true;
    final String? second = blend.word.parts[1].clip;
    if (second != null) playClips?.call(<String>[second], replace: true);
  }

  void mergeEnd() {
    if (!dragging) return;
    dragging = false;
    if (!met) {
      mergeT = 0;
      held = false;
    }
    notify();
  }

  /// A tap on the first tile slides it by itself.
  Future<void> autoMerge({int? within}) async {
    if (busy || auto || dragging || met) return;
    final int mine = within ?? ++run;
    auto = true;
    stepMs = 1100;
    _startHeld();
    mergeT = 1;
    notify();
    await pause(const Duration(milliseconds: 1100));
    if (!_live(mine)) return;
    _meet();
    auto = false;
    notify();
  }

  // ---- the choice ----

  @override
  void onChosen(ChoiceOption o) {
    // The whole word plays after the choice, never before it, whichever tile it was.
    final String? whole = blend.word.whole;
    if (whole != null) playClips?.call(<String>[whole], replace: false);
  }

  @override
  void onRight() {
    if (merge) joined = true;
    notify();
    super.onRight();
  }

  @override
  bool get showsSpeakers => false;

  // ---- hints ----

  @override
  void onReset() {
    super.onReset();
    run++;
    knobT = 0;
    dragging = false;
    auto = false;
    litPart = null;
    passed.clear();
    _maxPassed = -1;
    mergeT = 0;
    held = false;
    met = false;
    joined = false;
    _clearHint();
  }

  void _clearHint() {
    card = null;
    cardLit = null;
    plan = null;
    handTip = null;
    wholeAfterParts = false;
  }

  @override
  void onHint() {
    run++;
    auto = false;
    _clearHint();
    final int level = controller.hintShown;
    switch (level) {
      case 1:
        _slowSlide();
      case 2:
        _anotherWay(run);
      default:
        _friendSlides(run);
    }
    notify();
  }

  /// Level 1: the slide again, slowly, each part lit as it sounds (the parts only, never the whole).
  void _slowSlide() {
    // A word whose parts have no clip of their own yet lights in silence, and its stretched clip is the replay (docs/milestones/L5.md section 5.5).
    wholeAfterParts = blend.word.parts.every((BlendPart p) => p.clip == null) && blend.word.stretched != null;
    if (merge) {
      autoMergeSlow();
    } else {
      autoSlide(pace: 900);
    }
  }

  Future<void> autoMergeSlow() async {
    mergeT = 0;
    held = false;
    met = false;
    notify();
    await autoMerge();
  }

  /// Level 2: the parts another way: each as a token lit in turn with its sound, or the borrowed screen the hint names.
  Future<void> _anotherWay(int mine) async {
    final HintShow? show = controller.current.hints.length >= 2 ? controller.current.hints[1].show : null;
    final BorrowedPlan? p = show == null ? null : BorrowedPlan.forBlend(blend, show);
    if (p != null) {
      plan = p;
      card = 'borrowed';
      borrowedStep = 0;
      notify();
      await _walkBorrowed(mine);
      return;
    }
    card = 'tokens';
    notify();
    for (int i = 0; i < blend.word.parts.length; i++) {
      if (!_live(mine)) return;
      cardLit = i;
      notify();
      final String? clip = blend.word.parts[i].clip;
      if (clip != null) {
        await sayAndWait(<String>[clip], replace: true, without: const Duration(milliseconds: 700));
      } else {
        await pause(const Duration(milliseconds: 700));
      }
    }
    if (!_live(mine)) return;
    card = null;
    cardLit = null;
    notify();
  }

  Future<void> _walkBorrowed(int mine) async {
    final BorrowedPlan p = plan!;
    for (int i = 0; i < p.steps; i++) {
      if (!_live(mine)) return;
      borrowedStep = i;
      notify();
      await sayAndWait(<String>[?p.clipAt(i)], replace: true, without: const Duration(milliseconds: 900));
    }
    if (!_live(mine)) return;
    card = null;
    plan = null;
    notify();
  }

  /// Level 3: the friend slides, the whole plays and the friend's hand points to the answer, which keeps its halo.
  Future<void> _friendSlides(int mine) async {
    wholeAfterParts = true;
    if (merge) {
      joined = false;
      mergeT = 0;
      held = false;
      met = false;
      notify();
      await autoMerge(within: mine);
      if (!_live(mine)) return;
      final String? whole = blend.word.whole;
      if (whole != null) {
        await sayAndWait(<String>[whole], replace: true, without: const Duration(milliseconds: 800));
      }
    } else {
      await autoSlide(pace: 800, within: mine);
    }
    if (!_live(mine)) return;
    final int right = options.indexWhere((ChoiceOption o) => o.id == correctId);
    final List<Rect> rects = _tileRects();
    if (right >= 0 && right < rects.length) {
      handTip = rects[right].topCenter + const Offset(0, 6);
      notify();
      await pause(const Duration(milliseconds: 1200));
    }
    if (!_live(mine)) return;
    handTip = null;
    controller.demoDone();
    notify();
  }

  // ---- layout ----

  Ls01Metrics get metrics =>
      Ls01Metrics.of(band: band, spec: _spec ?? ActivitySpec.phone, course: blend.course);

  late final List<Ls01Face> faces = <Ls01Face>[
    for (final ChoiceOption o in options) Ls01Face.option(o, blend.assets),
  ];

  RowPlan get _plan =>
      metrics.row(<String>[], FaceKind.letter, (_spec ?? ActivitySpec.phone).tilesWidth, count: faces.length);

  List<Rect> _tileRects() => rowRects(_spec ?? ActivitySpec.phone, _plan, rowDirection);

  @override
  ActivitySpec layoutFor(ActivitySpec base) => _spec = withLs01Zones(base, band);

  @override
  Widget buildStage(BuildContext context, Size size, ActivitySpec spec) {
    _spec = spec;
    return Semantics(
      container: true,
      label: blend.altText,
      child: Container(
        key: const Key('slide-page'),
        decoration: BoxDecoration(
          color: TokenColors.paper,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: TokenColors.hairline, width: 3),
        ),
      ),
    );
  }

  @override
  Widget? buildTiles(BuildContext context, ActivitySpec spec) {
    _spec = spec;
    return ListenableBuilder(
      listenable: this,
      builder: (BuildContext c, Widget? _) => Ls01Row(
        key: const Key('ls01-row'),
        faces: faces,
        looks: <Ls01Look>[
          for (final (int i, ChoiceOption o) in options.indexed)
            Ls01Look(
              state: chosenId == o.id
                  ? chosenState
                  : (controller.answerShown && o.id == correctId ? AnswerState.selected : AnswerState.idle),
              lit: litTile == i,
              dimmed: controller.answerShown && o.id != correctId,
              heard: true,
            ),
        ],
        metrics: metrics,
        direction: rowDirection,
        kind: FaceKind.letter,
        zoneWidth: spec.tilesWidth,
        onTap: (int i) => choose(options[i].id),
      ),
    );
  }

  @override
  Widget? buildBoardLayer(BuildContext context, ActivitySpec spec) {
    _spec = spec;
    board = AppLayout.of(context).board;
    return ListenableBuilder(
      listenable: this,
      builder: (BuildContext c, Widget? _) => BlendLayer(session: this, spec: spec, board: board),
    );
  }

  /// The half of the knob's size a finger may be off its centre, and the room the wire gives it above and below.
  static double reach(double knob) => math.max(knob / 2 + 12, 44);
}
