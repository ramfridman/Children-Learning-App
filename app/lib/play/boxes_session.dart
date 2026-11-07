import 'package:flutter/material.dart';

import '../child/activity_shell.dart';
import '../content/models.dart';
import '../design/board.dart' show BoardClass;
import '../design/components.dart';
import '../design/layout.dart';
import '../design/token_types.dart' show Band;
import 'boxes_layer.dart';
import 'choice_row.dart' show rowDirectionOf, withLs01Zones;
import 'l5_art.dart';
import 'lesson_controller.dart';
import 'response_code.dart';
import 'template_session.dart';

/// LS03 in `boxes` mode (docs/milestones/L5.md section 5.3, layout docs/design/l5-templates.md section 3): the word is heard with its picture and the
/// child lays a counter for each unit it has; then, by the item's steps, colours the counters (the Russian scheme), marks the stressed vowel, or taps
/// the box of a sound. The boxes grow with the child's counters: no empty box is drawn, so the count is the child's own. Laying a counter plays only a
/// soft "tok", never the unit's clip (it would tell the child when to stop).
///
/// It is a free response. The answer is the whole item: a mistake of any step is written as it happens (a named one with its tag, a count off by two or
/// more as a retry with no tag and no evidence) and the right answer, with every step's value, is written when the last step is right
/// (`n=3.c=brb.s=1.w=2`, numbers and colour letters only, never a word). The first complete colouring is the colour step's answer; the chips that
/// went back to tan are stamped again as a retry, credited by the hint level the ladder has reached.
///
/// The hints are drawn by step (spec section 3.6): the word slowly and the picture lit; a card over the stage (claps for a syllable or a CV unit, the
/// mouth of each sound for a phoneme, the "can you sing it?" tests for the colours, the friend calling from far for the stress); then the friend's hand
/// does the step and the child does it after. Nothing is marked before level 3.
class BoxesSession extends TemplateSession {
  BoxesSession(super.controller, this.a, {this.band = Band.b}) {
    // The word is heard after the instruction, with its picture on the stage.
    later(Duration.zero, () => playClips?.call(<String>[a.wordClip], replace: false));
    _openStep();
  }

  final BoxesActivity a;
  final Band band;

  ActivitySpec? _spec;

  // ---- what the child has done ----

  int stepIx = 0;

  /// The counters laid, and the colour of each place (null: tan, not coloured yet).
  int laid = 0;
  final List<SchemeKind?> chips = <SchemeKind?>[];

  /// The stamp that is chosen (the colour step), the chip that is chosen, and the place of the stress sign (1 based from the course's start).
  SchemeKind? stampChosen;
  int? chipChosen;
  int? stressAt;

  /// The place the which step has tapped (1 based).
  int? whichAt;

  AnswerState state = AnswerState.idle;

  /// The rail wobbles once (a mistake), the places that wobble, and the places lit by a hint or by the right answer.
  bool wobble = false;
  final Set<int> notYet = <int>{};
  final Set<int> lights = <int>{};
  final Set<int> heard = <int>{};

  bool busy = false;
  bool demo = false;

  // ---- what a hint draws ----

  bool pictureLit = false;
  bool soundLit = false;

  /// The card over the stage: `claps`, `mouths`, `sing` or `call`, and the one of its entries that is lit.
  String? card;
  int? cardLit;

  /// The hand's fingertip (a point of the board), the place it points at (halo), and the stamp the friend holds.
  Offset? handTip;
  int run = 0;

  // ---- the item's steps ----

  BoxStep get step => a.steps[stepIx.clamp(0, a.steps.length - 1)];
  bool get allDone => stepIx >= a.steps.length;

  /// The colour a chip shows: the child's own in the colour step, the scheme's own where the scheme is given coloured, tan otherwise.
  SchemeKind? chipColour(int i) {
    if (i >= laid) return null;
    if (a.has(BoxStep.colour)) return stepIx >= a.steps.indexOf(BoxStep.colour) ? chips[i] : null;
    if (a.has(BoxStep.stress)) return SchemeKind.ofLetter(a.kindLetters[i]);
    return null;
  }

  /// An item with no count step opens with the scheme laid (the Elkonin card): the counters are in their places, tan.
  void _openStep() {
    if (!a.has(BoxStep.count)) {
      laid = a.count;
      chips
        ..clear()
        ..addAll(List<SchemeKind?>.filled(a.count, null));
    }
  }

  TextDirection get direction => rowDirectionOf(a.course, TextDirection.rtl);

  /// The most counters the rail takes: the band's places, and always one more than the word has.
  int get railPlaces => railPlacesFor(band, a.count);

  // ---- laying counters (the count step) ----

  void lay() {
    if (busy || demo || step != BoxStep.count || allDone || laid >= railPlaces) return;
    if (controller.guided && laid >= a.count) return;
    laid++;
    chips.add(null);
    _tok();
    notify();
  }

  void unlay() {
    if (busy || demo || step != BoxStep.count || laid == 0) return;
    laid--;
    chips.removeLast();
    notify();
  }

  void _tok() {
    final String? sound = a.tok;
    if (sound != null) playClips?.call(<String>[sound], replace: true);
  }

  /// "That's all": the count is the answer for this step.
  Future<void> done() async {
    if (busy || demo || step != BoxStep.count || allDone || laid == 0) return;
    if (controller.guided && laid != a.count) {
      _home();
      return;
    }
    if (laid == a.count) {
      busy = true;
      await _lightPlaces();
      if (disposed) return;
      busy = false;
      await _advance();
      return;
    }
    final String? tag = a.countTag(laid);
    // A count off by two or more with no name is a retry with no tag and no evidence (frame section 2.3). A probe has one answer, so it is written.
    if (tag == null && (laid - a.count).abs() >= 2 && a.purpose != 'probe') {
      await _retryWithoutEvidence();
      return;
    }
    await _wrong(tag ?? '', ResponseCode.boxes(n: laid));
  }

  /// The places light one after another with their unit's clip (a pending clip waits a fixed pause).
  Future<void> _lightPlaces() async {
    final int mine = run;
    for (int i = 0; i < a.units.length; i++) {
      if (disposed || mine != run) return;
      heard
        ..clear()
        ..add(i);
      notify();
      await sayAndWait(<String>[a.units[i].clip], replace: true, without: const Duration(milliseconds: 500));
    }
    heard.clear();
    if (!disposed) notify();
  }

  // ---- the colour step ----

  void tapStamp(SchemeKind kind) {
    if (busy || demo || step != BoxStep.colour || allDone) return;
    final int? chip = chipChosen;
    if (chip != null) {
      chipChosen = null;
      _stamp(chip, kind);
      return;
    }
    stampChosen = stampChosen == kind ? null : kind;
    notify();
  }

  void tapChip(int i) {
    if (busy || demo || allDone || i >= laid) return;
    switch (step) {
      case BoxStep.colour:
        final SchemeKind? kind = stampChosen;
        if (kind != null) {
          _stamp(i, kind);
        } else {
          chipChosen = chipChosen == i ? null : i;
          notify();
        }
      case BoxStep.stress:
        _tapStress(i + 1);
      case BoxStep.which:
        _tapWhich(i + 1);
      case BoxStep.count:
        unlay();
    }
  }

  void _stamp(int i, SchemeKind kind) {
    // At the top of the help only the right colour is taken (the child stamps what the friend showed).
    if (controller.guided && a.colours![i] != kind.letter) return;
    chips[i] = kind;
    notYet.remove(i);
    _tok();
    notify();
    if (chips.every((SchemeKind? c) => c != null)) _checkColours();
  }

  /// Every chip has a colour: the step checks itself. The first complete colouring is the answer.
  Future<void> _checkColours() async {
    final String want = a.colours!;
    final String got = chips.map((SchemeKind? c) => c!.letter).join();
    if (got == want) {
      await _advance();
      return;
    }
    // A vowel taken for a consonant or the reverse is the base of the scheme (rus B-12 comes before B-13); a hard consonant taken for a soft one or the
    // reverse comes after it. When one colouring has both, both are recorded and the line of the first is the one spoken.
    bool vowelMix = false;
    bool hardSoft = false;
    final Set<int> wrong = <int>{};
    for (int i = 0; i < want.length; i++) {
      if (got[i] == want[i]) continue;
      wrong.add(i);
      if (want[i] == 'r' || got[i] == 'r') {
        vowelMix = true;
      } else {
        hardSoft = true;
      }
    }
    final String? first = vowelMix
        ? a.classify['colour=vowel_cons']
        : (hardSoft ? a.classify['colour=hard_soft'] : null);
    final String? second = vowelMix && hardSoft ? a.classify['colour=hard_soft'] : null;
    notYet
      ..clear()
      ..addAll(wrong);
    await _wrong(
      first ?? '',
      ResponseCode.boxes(n: _hasCount ? a.count : null, colours: got),
      also: second ?? '',
    );
  }

  bool get _hasCount => a.has(BoxStep.count);

  // ---- the stress step ----

  void _tapStress(int place) {
    if (!a.units[place - 1].vowel || busy || demo) return;
    if (controller.guided && place != a.stress) return;
    stressAt = place;
    notify();
    if (place == a.stress) {
      _advance();
    } else {
      _wrong(a.classify['stress=$place'] ?? a.classify['stress=other'] ?? '', _code(stress: place));
    }
  }

  // ---- the which step ----

  void _tapWhich(int place) {
    if (busy || demo) return;
    if (controller.guided && place != a.which) return;
    whichAt = place;
    notify();
    if (place == a.which) {
      _advance();
    } else {
      _wrong(a.classify['which=$place'] ?? a.classify['which=other'] ?? '', _code(which: place));
    }
  }

  void replayWhich() {
    soundLit = true;
    notify();
    final String? clip = a.whichClip;
    if (clip != null) playClips?.call(<String>[clip], replace: true);
    later(const Duration(milliseconds: 600), () {
      soundLit = false;
      notify();
    });
  }

  void replayWord() => playClips?.call(<String>[a.wordClip], replace: true);

  // ---- the response ----

  /// The code of the steps so far with the values of the steps that are right, and the value being tried in [colours], [stress] or [which] for the step
  /// that is current.
  String _code({String? colours, int? stress, int? which}) {
    final int at = stepIx;
    return ResponseCode.boxes(
      n: _hasCount ? a.count : null,
      colours: colours ?? (a.has(BoxStep.colour) && at > a.steps.indexOf(BoxStep.colour) ? a.colours : null),
      stress: stress ?? (a.has(BoxStep.stress) && at > a.steps.indexOf(BoxStep.stress) ? a.stress : null),
      which: which,
    );
  }

  String get _fullCode => ResponseCode.boxes(
    n: _hasCount ? a.count : null,
    colours: a.has(BoxStep.colour) ? a.colours : null,
    stress: a.has(BoxStep.stress) ? a.stress : null,
    which: a.has(BoxStep.which) ? a.which : null,
  );

  // ---- going on, and going wrong ----

  Future<void> _advance() async {
    stepIx++;
    stampChosen = null;
    chipChosen = null;
    notify();
    if (!allDone) return;
    busy = true;
    final Outcome o = await controller.submitPlacement(right: true, response: _fullCode);
    if (disposed) return;
    state = o.settled ? AnswerState.selected : AnswerState.correct;
    notify();
    later(TemplateSession.praisePause, controller.next);
  }

  Future<void> _wrong(String tag, String code, {String also = ''}) async {
    busy = true;
    state = AnswerState.notYet;
    wobble = true;
    notify();
    final Outcome o = await controller.submitPlacement(right: false, tag: tag, response: code, alsoTag: also);
    if (disposed) return;
    if (o.settled) {
      // A probe of the placement game ends on its one answer, right or not, and shows nothing "not yet".
      state = AnswerState.selected;
      notify();
      later(TemplateSession.praisePause, controller.next);
      return;
    }
    later(TemplateSession.notYetPause, _afterWrong);
  }

  /// The mistake is over: the child goes on from what is right (the counters go home; a wrong chip goes back to tan; a wrong place is let go).
  void _afterWrong() {
    wobble = false;
    state = AnswerState.idle;
    busy = false;
    switch (step) {
      case BoxStep.count:
        _home();
      case BoxStep.colour:
        for (final int i in notYet) {
          chips[i] = null;
        }
        notYet.clear();
      case BoxStep.stress:
        stressAt = null;
      case BoxStep.which:
        whichAt = null;
    }
    notify();
  }

  Future<void> _retryWithoutEvidence() async {
    busy = true;
    state = AnswerState.notYet;
    wobble = true;
    notify();
    later(TemplateSession.notYetPause, () {
      busy = false;
      _afterWrong();
    });
  }

  /// The counters go home, with no sound.
  void _home() {
    laid = 0;
    chips.clear();
    notify();
  }

  // ---- hints ----

  @override
  void onReset() {
    run++;
    stepIx = 0;
    laid = 0;
    chips.clear();
    stampChosen = null;
    chipChosen = null;
    stressAt = null;
    whichAt = null;
    state = AnswerState.idle;
    wobble = false;
    busy = false;
    demo = false;
    _clearHint();
    notYet.clear();
    _openStep();
    notify();
  }

  void _clearHint() {
    pictureLit = false;
    soundLit = false;
    card = null;
    cardLit = null;
    handTip = null;
    lights.clear();
    heard.clear();
  }

  @override
  void onReplay() => replayWord();

  @override
  void onHint() {
    run++;
    _clearHint();
    final int level = controller.hintShown;
    if (allDone) return;
    switch (step) {
      case BoxStep.count:
        _countHint(level);
      case BoxStep.colour:
        _colourHint(level);
      case BoxStep.stress:
        _stressHint(level);
      case BoxStep.which:
        _whichHint(level);
    }
    notify();
  }

  bool _live(int mine) => !disposed && mine == run;

  Future<void> _playUnit(int i, int mine) async {
    if (!_live(mine)) return;
    await sayAndWait(<String>[a.units[i].clip], replace: true, without: const Duration(milliseconds: 700));
  }

  void _countHint(int level) {
    final int mine = run;
    switch (level) {
      case 1:
        pictureLit = true;
        playClips?.call(<String>[a.slow ?? a.wordClip], replace: false);
      case 2:
        card = a.unit == 'phoneme' ? 'mouths' : 'claps';
        _walkUnits(
          mine,
          then: () {
            card = null;
            cardLit = null;
          },
        );
      default:
        _friendLays(mine);
    }
  }

  /// Each unit's card lights in turn with its clip; then [then] runs.
  Future<void> _walkUnits(int mine, {required VoidCallback then}) async {
    for (int i = 0; i < a.units.length; i++) {
      if (!_live(mine)) return;
      cardLit = i;
      notify();
      await _playUnit(i, mine);
    }
    if (!_live(mine)) return;
    then();
    notify();
  }

  /// Level 3 of the count step: the hand takes a counter from the bowl to the next place as each unit plays, touches "that's all", and the counters go
  /// home for the child to do it after.
  Future<void> _friendLays(int mine) async {
    demo = true;
    laid = 0;
    chips.clear();
    notify();
    final BoxesGeometry l = BoxesGeometry.of(
      _boardOrPhone,
      _spec ?? ActivitySpec.phone,
      band,
      direction,
      railPlaces,
    );
    for (int i = 0; i < a.units.length; i++) {
      if (!_live(mine)) return;
      handTip = l.bowl.center;
      notify();
      await pause(const Duration(milliseconds: 500));
      if (!_live(mine)) return;
      handTip = l.place(i).center;
      laid = i + 1;
      chips.add(null);
      _tok();
      notify();
      await _playUnit(i, mine);
    }
    if (!_live(mine)) return;
    handTip = l.done.center;
    notify();
    await pause(const Duration(milliseconds: 700));
    if (!_live(mine)) return;
    handTip = null;
    demo = false;
    _home();
    controller.demoDone();
  }

  void _colourHint(int level) {
    final int mine = run;
    switch (level) {
      case 1:
        _lightChips(mine);
      case 2:
        card = 'sing';
        _lightChips(mine);
      default:
        _friendStamps(mine);
    }
  }

  /// Each chip lights in turn with its sound, left to right (in the course's direction): the child's own work, so nothing is named by it.
  Future<void> _lightChips(int mine) async {
    for (int i = 0; i < laid; i++) {
      if (!_live(mine)) return;
      lights
        ..clear()
        ..add(i);
      notify();
      await _playUnit(i, mine);
    }
    if (!_live(mine)) return;
    lights.clear();
    card = null;
    notify();
  }

  Future<void> _friendStamps(int mine) async {
    demo = true;
    notify();
    final BoxesGeometry l = BoxesGeometry.of(
      _boardOrPhone,
      _spec ?? ActivitySpec.phone,
      band,
      direction,
      railPlaces,
    );
    int first = -1;
    final String want = a.colours!;
    for (int i = 0; i < laid; i++) {
      if (chips[i] == null || chips[i]!.letter != want[i]) {
        first = i;
        break;
      }
    }
    if (first < 0) first = 0;
    final SchemeKind kind = SchemeKind.ofLetter(want[first])!;
    handTip = l.stamp(kind.index).center;
    notify();
    await pause(const Duration(milliseconds: 800));
    if (!_live(mine)) return;
    handTip = l.place(first).center;
    notify();
    await pause(const Duration(milliseconds: 700));
    if (!_live(mine)) return;
    chips[first] = kind;
    _tok();
    handTip = null;
    demo = false;
    notify();
    controller.demoDone();
  }

  void _stressHint(int level) {
    final int mine = run;
    switch (level) {
      case 1:
        playClips?.call(<String>[a.slow ?? a.wordClip], replace: false);
        _lightVowels(mine);
      case 2:
        card = 'call';
        playClips?.call(<String>[a.slow ?? a.wordClip], replace: false);
        later(const Duration(milliseconds: 2400), () {
          card = null;
          notify();
        });
      default:
        _friendStresses(mine);
    }
  }

  Future<void> _lightVowels(int mine) async {
    for (int i = 0; i < a.units.length; i++) {
      if (!a.units[i].vowel) continue;
      if (!_live(mine)) return;
      lights
        ..clear()
        ..add(i);
      notify();
      await _playUnit(i, mine);
    }
    if (!_live(mine)) return;
    lights.clear();
    notify();
  }

  Future<void> _friendStresses(int mine) async {
    demo = true;
    notify();
    final BoxesGeometry l = BoxesGeometry.of(
      _boardOrPhone,
      _spec ?? ActivitySpec.phone,
      band,
      direction,
      railPlaces,
    );
    handTip = l.place(a.stress! - 1).topCenter;
    notify();
    await pause(const Duration(milliseconds: 900));
    if (!_live(mine)) return;
    stressAt = a.stress;
    handTip = null;
    demo = false;
    notify();
    controller.demoDone();
  }

  void _whichHint(int level) {
    final int mine = run;
    switch (level) {
      case 1:
        soundLit = true;
        final String? clip = a.whichClip;
        if (clip != null) playClips?.call(<String>[clip], replace: false);
      case 2:
        _tokensInTurn(mine);
      default:
        _friendTaps(mine);
    }
  }

  /// The counters light one by one with their sounds in the course's direction, and the sound to find again after them.
  Future<void> _tokensInTurn(int mine) async {
    for (int i = 0; i < a.units.length; i++) {
      if (!_live(mine)) return;
      lights
        ..clear()
        ..add(i);
      notify();
      await _playUnit(i, mine);
    }
    if (!_live(mine)) return;
    lights.clear();
    soundLit = true;
    notify();
    final String? clip = a.whichClip;
    if (clip != null) {
      await sayAndWait(<String>[clip], replace: true, without: const Duration(milliseconds: 700));
    }
    if (!_live(mine)) return;
    soundLit = false;
    notify();
  }

  Future<void> _friendTaps(int mine) async {
    demo = true;
    notify();
    final BoxesGeometry l = BoxesGeometry.of(
      _boardOrPhone,
      _spec ?? ActivitySpec.phone,
      band,
      direction,
      railPlaces,
    );
    handTip = l.place(a.which! - 1).topCenter;
    notify();
    await pause(const Duration(milliseconds: 900));
    if (!_live(mine)) return;
    handTip = null;
    demo = false;
    notify();
    controller.demoDone();
  }

  // ---- layout ----

  BoardClass _boardOrPhone = BoardClass.phone;

  @override
  ActivitySpec layoutFor(ActivitySpec base) => _spec = withLs01Zones(base, band);

  @override
  Widget buildStage(BuildContext context, Size size, ActivitySpec spec) {
    _spec = spec;
    return Semantics(
      container: true,
      label: a.altText,
      child: const StagePanel(child: SizedBox.expand()),
    );
  }

  @override
  Widget? buildTiles(BuildContext context, ActivitySpec spec) => null;

  @override
  Widget? buildBoardLayer(BuildContext context, ActivitySpec spec) {
    _spec = spec;
    _boardOrPhone = AppLayout.of(context).board;
    return ListenableBuilder(
      listenable: this,
      builder: (BuildContext c, Widget? _) => BoxesLayer(session: this, spec: spec, board: _boardOrPhone),
    );
  }
}
