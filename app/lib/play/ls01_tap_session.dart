import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../child/activity_shell.dart';
import '../content/models.dart';
import '../design/components.dart';
import '../design/course_text.dart';
import '../design/token_types.dart';
import '../design/tokens.g.dart';
import 'choice_row.dart';
import 'choice_session.dart';
import 'hints/hint_pictures.dart' show SkyRing;
import 'lesson_controller.dart';
import 'ls01_hand.dart';
import 'ls01_metrics.dart';
import 'ls01_sentence.dart';
import 'ls01_tiles.dart';
import 'option_faces.dart';
import 'template_session.dart';

/// The three modes that `tap_answer` 1.4 adds to the tap of L1 (docs/design/languages-l5-ls01.md sections 7.7 to 7.9):
///
/// **stem** (LS01 d): a written word, unit or letter on a white page of the stage, and pictures, sounds or words to choose from. "Read it to me"
/// is hint level 1: the stem's clip, a bar walking under its words, and the credit of the item lowers to what the item says (0.8).
///
/// **cloze** (LS01 e): a sentence with a gap and a picture beside it; three word tiles. A tap puts the word in the gap, where it is checked at
/// once; a "not yet" sends it back.
///
/// **tap-all**: several right cards in one row; a tap picks, a second tap un-picks, and the item checks itself once as many cards are picked
/// as there are right ones (no "done" button: it gives away how many, not which). The wrong cards picked wobble and un-pick, the right ones
/// stay. Cards that do not fit the answer zone stand at the end side of the stage.
///
/// The answer goes to the controller by option id (a set of ids for tap-all), so the tags, the hint ladder and the credit are its.
class Ls01TapSession extends ChoiceSession {
  Ls01TapSession(LessonController controller, TapAnswerActivity activity, {this.band = Band.b, super.stress})
    : tap = activity,
      super(controller, activity, activity);

  final TapAnswerActivity tap;

  /// The presentation band of the course, not the content's band letter (docs/design/languages-l5-ls01.md section 3).
  final Band band;

  Ls01TapMode get mode => tap.ls01Mode!;

  ActivitySpec? _spec;

  // ---- state of the screen ----

  /// Tap-all: the cards picked, in the order picked, and the wrong ones among them while their "not yet" shows.
  final List<String> picked = <String>[];
  final Set<String> notYetPicks = <String>{};
  bool _checked = false;

  /// Cloze: the word tile whose word stands in the gap now.
  String? gapId;

  /// A hint's marks: the bar under a word, the lit page or gap, the stem's pieces, the target made big, the card the target glides over.
  int? litWord;
  bool stemLit = false;
  bool gapLit = false;
  bool splitStem = false;
  int? splitLit;
  bool pictureFull = false;
  bool targetBig = false;
  int? ghostAt;
  final Set<int> ghostSettled = <int>{};
  final Set<int> litSet = <int>{};

  /// Where the hand's fingertip is, a point of the board; null when there is no hand.
  Offset? handTip;
  int _run = 0;

  @override
  ActivitySpec layoutFor(ActivitySpec base) => _spec = withLs01Zones(base, band);

  Ls01Metrics get metrics =>
      Ls01Metrics.of(band: band, spec: _spec ?? ActivitySpec.phone, course: tap.course);

  FaceKind get _kind => tap.letterFace ? FaceKind.letter : FaceKind.word;

  late final List<Ls01Face> faces = <Ls01Face>[
    for (final ChoiceOption o in options) Ls01Face.option(o, tap.assets, stress: stress),
  ];

  Set<String> get _right => tap.correctIds.toSet();

  // ---- answering ----

  @override
  Future<void> choose(String id) async {
    if (mode == Ls01TapMode.tapAll) return _toggle(id);
    return super.choose(id);
  }

  @override
  void onChosen(ChoiceOption o) {
    if (mode == Ls01TapMode.cloze) {
      gapId = o.id;
      notify();
    }
  }

  @override
  void onWrong() {
    if (mode != Ls01TapMode.cloze) return;
    // The word wobbles in the gap and flies back: the gap is empty again.
    later(TemplateSession.notYetPause, () {
      gapId = null;
      notify();
    });
  }

  Future<void> _toggle(String id) async {
    if (busy || chosenState == AnswerState.correct) return;
    final bool right = _right.contains(id);
    if (controller.guided && !right) return;
    handTip = null;
    if (picked.remove(id)) {
      notify();
      return;
    }
    picked.add(id);
    final ChoiceOption o = options.firstWhere((ChoiceOption o) => o.id == id);
    if (o.clip != null && o.text == null) playClips?.call(<String>[o.clip!], replace: true);
    notify();
    if (picked.length == _right.length) await _check();
  }

  /// As many cards are picked as there are right ones: the item checks itself.
  Future<void> _check() async {
    busy = true;
    _checked = true;
    final Outcome out = await controller.chooseSet(List<String>.of(picked));
    if (disposed) return;
    if (out.settled) {
      chosenState = AnswerState.selected;
      notify();
      later(TemplateSession.praisePause, controller.next);
    } else if (out.correct) {
      chosenState = AnswerState.correct;
      notify();
      later(TemplateSession.praisePause, controller.next);
    } else {
      notYetPicks
        ..clear()
        ..addAll(picked.where((String id) => !_right.contains(id)));
      notify();
      later(TemplateSession.notYetPause, () {
        picked.removeWhere(notYetPicks.contains);
        notYetPicks.clear();
        busy = false;
        _checked = false;
        notify();
      });
    }
  }

  // ---- hints and replay ----

  @override
  void onReset() {
    super.onReset();
    _run++;
    picked.clear();
    notYetPicks.clear();
    _checked = false;
    gapId = null;
    _clearHint();
  }

  void _clearHint() {
    litWord = null;
    stemLit = false;
    gapLit = false;
    splitStem = false;
    splitLit = null;
    pictureFull = false;
    targetBig = false;
    ghostAt = null;
    ghostSettled.clear();
    litSet.clear();
    handTip = null;
  }

  /// The replay button says the question again and the tiles pulse; the stem is not read to the child unasked ("read it to me" is a hint).
  @override
  void onReplay() => pulseTiles();

  @override
  void onHint() {
    _run++;
    _clearHint();
    final int level = controller.hintShown;
    switch (mode) {
      case Ls01TapMode.stem:
        _stemHint(level);
      case Ls01TapMode.cloze:
        _clozeHint(level);
      case Ls01TapMode.tapAll:
        _tapAllHint(level);
    }
    notify();
  }

  int get _stemWords => sentencePieces(tap.stem!.text).length;

  void _stemHint(int level) {
    final int run = _run;
    switch (level) {
      case 1:
        stemLit = true;
        final String? clip = tap.stem!.clip;
        if (clip != null) {
          _walkBars(_stemWords);
          playClips?.call(<String>[clip], replace: false);
        } else {
          // A letter on the stage with sound buttons to choose: the buttons say their sounds again, one after the other.
          _replayOptions(run);
        }
      case 2:
        // The stem in pieces, each lit in turn with its sound (the borrowed screens of LS04 and LS05 take this place when they are built).
        splitStem = true;
        stemLit = true;
        final int pieces = _pieces(tap.stem!.text).length;
        for (int i = 0; i < pieces; i++) {
          later(Duration(milliseconds: 700 * i), () {
            if (run != _run) return;
            splitLit = i;
            notify();
          });
        }
        final String? clip = tap.stem!.clip;
        if (clip != null) playClips?.call(<String>[clip], replace: false);
      default:
        _demonstrate(<int>[_rightIndex()]);
    }
  }

  void _clozeHint(int level) {
    final int run = _run;
    switch (level) {
      case 1:
        // The sentence is read with a short pause at the gap, and the gap lights.
        gapLit = true;
        _walkBars(sentencePieces(tap.cloze!.text).length);
      case 2:
        // The picture grows to fill the stage, and the sentence comes back after a moment.
        pictureFull = true;
        later(const Duration(milliseconds: 2600), () {
          if (run != _run) return;
          pictureFull = false;
          notify();
        });
      default:
        gapLit = true;
        _demonstrate(<int>[_rightIndex()], toGap: true);
    }
  }

  void _tapAllHint(int level) {
    final int run = _run;
    switch (level) {
      case 1:
        targetBig = true;
      case 2:
        // The target glides over each card in turn and settles only on the right ones: the look-alikes are left uncovered.
        targetBig = true;
        for (int i = 0; i < options.length; i++) {
          later(Duration(milliseconds: 650 * i), () {
            if (run != _run) return;
            ghostAt = i;
            if (_right.contains(options[i].id)) ghostSettled.add(i);
            notify();
          });
        }
        later(Duration(milliseconds: 650 * options.length + 1200), () {
          if (run != _run) return;
          ghostAt = null;
          ghostSettled.clear();
          notify();
        });
      default:
        final int first = options.indexWhere((ChoiceOption o) => _right.contains(o.id));
        _demonstrate(<int>[first], pick: true);
    }
  }

  /// Level 3, "watch me": the hand goes to the right tile (and then to the gap of a cloze), a tap-all's first right card is picked for the
  /// child, and the answer carries its halo only after that (`demoDone`).
  void _demonstrate(List<int> tiles, {bool toGap = false, bool pick = false}) {
    final int run = _run;
    final List<Rect> rects = _tileRects();
    later(const Duration(milliseconds: 300), () {
      if (run != _run) return;
      handTip = rects[tiles.first].topCenter + const Offset(0, 6);
      notify();
    });
    int at = 1400;
    if (toGap) {
      later(Duration(milliseconds: at), () {
        if (run != _run) return;
        final Rect? gap = _gapRect();
        if (gap != null) handTip = gap.topCenter + const Offset(0, 6);
        notify();
      });
      at += 1300;
    }
    if (pick) {
      later(Duration(milliseconds: at), () {
        if (run != _run) return;
        final String id = options[tiles.first].id;
        if (!picked.contains(id)) picked.add(id);
        notify();
      });
      at += 600;
    }
    later(Duration(milliseconds: at), () {
      if (run != _run) return;
      handTip = null;
      controller.demoDone();
      notify();
    });
  }

  int _rightIndex() => options.indexWhere((ChoiceOption o) => o.id == correctId);

  void _walkBars(int words, {int step = 600}) {
    final int run = _run;
    for (int i = 0; i < words; i++) {
      later(Duration(milliseconds: step * i), () {
        if (run != _run) return;
        litWord = i;
        notify();
      });
    }
    later(Duration(milliseconds: step * words), () {
      if (run != _run) return;
      litWord = null;
      notify();
    });
  }

  Future<void> _replayOptions(int run) async {
    for (final (int i, ChoiceOption o) in options.indexed) {
      if (run != _run || disposed) return;
      litSet
        ..clear()
        ..add(i);
      notify();
      await sayAndWait(<String>[?o.clip]);
    }
    if (run != _run || disposed) return;
    litSet.clear();
    notify();
  }

  /// The pieces a stem falls into at hint level 2: its letters (a word's letters, a unit's letter and sign stay one piece with it).
  static List<String> _pieces(String text) {
    final List<String> out = <String>[];
    for (final int r in text.runes) {
      final String c = String.fromCharCode(r);
      final bool mark = (r >= 0x0300 && r <= 0x036F) || (r >= 0x05B0 && r <= 0x05C7);
      if (mark && out.isNotEmpty) {
        out[out.length - 1] += c;
      } else if (c != ' ') {
        out.add(c);
      }
    }
    return out;
  }

  // ---- geometry ----

  /// How many cards stand in the answer zone: all of them, or as many as fit (a tap-all of more than a phone's row has).
  int get _inA {
    if (mode != Ls01TapMode.tapAll) return faces.length;
    final double zone = (_spec ?? ActivitySpec.phone).tilesWidth;
    for (int k = faces.length; k > 1; k--) {
      if (Ls01Row.planOf(faces.sublist(0, k), metrics, _kind, zone).fits) return k;
    }
    return 1;
  }

  RowPlan _plan(int count) => metrics.row(
    <String>[
      for (final Ls01Face f in faces)
        if (f.text != null) f.text!,
    ],
    _kind,
    (_spec ?? ActivitySpec.phone).tilesWidth,
    count: count,
  );

  /// Where the stage's own origin is on the board.
  Offset get _stageOrigin {
    final ActivitySpec s = _spec ?? ActivitySpec.phone;
    return s.stage.topLeft + Offset(s.stageIsCard ? 16 : 0, s.stageIsCard ? 16 : 0);
  }

  Size get _stageRoom {
    final ActivitySpec s = _spec ?? ActivitySpec.phone;
    return s.stageIsCard ? Size(s.stage.width - 32, s.stage.height - 32) : s.stage.size;
  }

  /// Where the cards of the answer zone stand on the board, then where the ones that went to the stage stand.
  List<Rect> _tileRects() {
    final ActivitySpec s = _spec ?? ActivitySpec.phone;
    final int inA = _inA;
    final RowPlan inZone = _plan(inA);
    final List<Rect> rects = rowRects(s, inZone, rowDirection);
    final int rest = faces.length - inA;
    if (rest > 0) {
      final RowPlan overflow = _plan(rest);
      final Size room = _stageRoom;
      final double width = overflow.total;
      final double left = rowDirection == TextDirection.ltr ? room.width - width : 0;
      for (int k = 0; k < rest; k++) {
        final int slot = rowDirection == TextDirection.ltr ? k : rest - 1 - k;
        rects.add(
          Rect.fromLTWH(
            _stageOrigin.dx + left + slot * overflow.cell + overflow.gap / 2,
            _stageOrigin.dy + (room.height - overflow.tileHeight) / 2,
            overflow.tileWidth,
            overflow.tileHeight,
          ),
        );
      }
    }
    return rects;
  }

  Rect? _gapRect() {
    final ActivitySpec s = _spec ?? ActivitySpec.phone;
    final Size room = _stageRoom;
    // The gap stands in the sentence's column; its exact place is the sentence's own, so the hand points at the middle of the column.
    final double picture = _pictureSide(s);
    final double left = tap.cloze!.picture == null
        ? 0
        : (rowDirection == TextDirection.ltr ? picture + 20 : 0);
    return Rect.fromLTWH(
      _stageOrigin.dx + left,
      _stageOrigin.dy + room.height / 2 - 20,
      room.width - picture - 20,
      40,
    );
  }

  double _pictureSide(ActivitySpec s) {
    if (tap.cloze?.picture == null) return 0;
    if (s.stageIsCard) return 200;
    return s.boardHeight < 380 ? 64 : 88;
  }

  // ---- drawing ----

  @override
  Widget buildStage(BuildContext context, Size size, ActivitySpec spec) {
    _spec = spec;
    return Ls01StageBuilder(
      direction: rowDirection,
      listenable: this,
      builder: (BuildContext c, Widget? _) => Semantics(
        container: true,
        label: tap.altText,
        child: switch (mode) {
          Ls01TapMode.stem => _stemStage(size),
          Ls01TapMode.cloze => _clozeStage(size),
          Ls01TapMode.tapAll => _tapAllStage(size),
        },
      ),
    );
  }

  Widget _page({required Widget child, required Size size, bool lit = false}) => Stack(
    clipBehavior: Clip.none,
    children: <Widget>[
      Container(
        key: const Key('stem-page'),
        width: size.width,
        height: size.height,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: TokenColors.paper,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: TokenColors.hairline, width: 3),
        ),
        child: child,
      ),
      if (lit)
        const Positioned.fill(
          child: IgnorePointer(child: SkyRing(key: Key('stem-glow'), round: false, radius: 24)),
        ),
    ],
  );

  Widget _stemStage(Size size) {
    final String text = tap.stem!.text;
    final bool oneWord = sentencePieces(text).length == 1;
    final Ls01Metrics m = metrics;
    return _page(
      size: size,
      lit: stemLit,
      child: splitStem
          ? Row(
              mainAxisSize: MainAxisSize.min,
              textDirection: rowDirection,
              children: <Widget>[
                for (final (int i, String piece) in _pieces(text).indexed)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: DecoratedBox(
                      key: Key('stem-piece-$i'),
                      decoration: BoxDecoration(
                        color: splitLit == i ? TokenColors.skyTint : null,
                        borderRadius: BorderRadius.circular(12),
                        border: splitLit == i ? Border.all(color: TokenColors.skyDeep, width: 3) : null,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: CourseText(
                          piece,
                          course: tap.course,
                          size: m.size(oneWord ? FaceKind.stem : FaceKind.line),
                          lineHeight: lineHeightFor(piece, hebrew: m.hebrew),
                        ),
                      ),
                    ),
                  ),
              ],
            )
          : Ls01Sentence(
              key: const Key('stem-text'),
              text: text,
              metrics: m,
              kind: oneWord ? FaceKind.stem : FaceKind.line,
              direction: rowDirection,
              litWord: litWord,
            ),
    );
  }

  Widget _clozeStage(Size size) {
    final ActivitySpec s = _spec ?? ActivitySpec.phone;
    final Ls01Metrics m = metrics;
    final double side = _pictureSide(s);
    final String? picture = tap.cloze!.picture;
    final double widest = options
        .map((ChoiceOption o) => o.text == null ? 0.0 : m.textWidth(o.text!, FaceKind.line))
        .fold(0, math.max);
    final ChoiceOption? inGap = gapId == null ? null : options.firstWhere((ChoiceOption o) => o.id == gapId);
    final bool right = inGap != null && chosenState == AnswerState.correct;
    final Widget gap = GapBox(
      width: widest + 16,
      height: m.size(FaceKind.line) * lineHeightFor('x', hebrew: m.hebrew) + 4,
      right: right,
      lit: gapLit,
      child: inGap == null
          ? null
          : CourseText(
              inGap.text!,
              course: tap.course,
              size: m.size(FaceKind.line),
              lineHeight: lineHeightFor(inGap.text!, hebrew: m.hebrew),
            ),
    );
    final Widget sentence = Ls01Sentence(
      key: const Key('cloze-text'),
      text: tap.cloze!.text,
      metrics: m,
      kind: FaceKind.line,
      direction: rowDirection,
      litWord: litWord,
      gap: gap,
    );
    final Widget art = picture == null
        ? const SizedBox.shrink()
        : Container(
            key: const Key('cloze-picture'),
            width: side,
            height: side,
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: TokenColors.paper,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: TokenColors.hairline, width: 3),
            ),
            child: PackSvg(tap.assets.svg(picture)),
          );
    if (pictureFull && picture != null) {
      final double big = math.min(size.width, size.height) - 8;
      return Center(
        child: Stack(
          clipBehavior: Clip.none,
          children: <Widget>[
            Container(
              key: const Key('cloze-picture-full'),
              width: big,
              height: big,
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: TokenColors.paper,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: TokenColors.hairline, width: 3),
              ),
              child: PackSvg(tap.assets.svg(picture)),
            ),
            const Positioned.fill(child: IgnorePointer(child: SkyRing(round: false, radius: 20))),
          ],
        ),
      );
    }
    return Row(
      textDirection: rowDirection,
      children: <Widget>[
        if (picture != null) ...<Widget>[art, SizedBox(width: s.stageIsCard ? 20 : 32)],
        Expanded(
          child: Align(alignment: AlignmentDirectional.centerStart, child: sentence),
        ),
      ],
    );
  }

  Widget _tapAllStage(Size size) {
    final int inA = _inA;
    final Ls01Metrics m = metrics;
    final bool ltr = rowDirection == TextDirection.ltr;
    final Ls01Face target = faces[options.indexWhere((ChoiceOption o) => _right.contains(o.id))];
    final Widget speaker = Align(
      alignment: ltr ? Alignment.centerLeft : Alignment.centerRight,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        textDirection: rowDirection,
        children: <Widget>[
          SpeakerMark(
            key: const Key('target-sound'),
            touch: 64,
            onTap: () => playClips?.call(<String>[?tap.promptLine.target, ?tap.stem?.clip], replace: true),
          ),
          if (targetBig)
            Container(
              key: const Key('target-big'),
              margin: const EdgeInsetsDirectional.only(start: 8),
              width: m.tileHeight,
              height: m.tileHeight,
              decoration: BoxDecoration(
                color: TokenColors.skyTint,
                borderRadius: BorderRadius.circular(TokenRadius.xl),
                border: Border.all(color: TokenColors.hintHalo, width: 4),
              ),
              child: Ls01FaceView(face: target, metrics: m, kind: _kind),
            ),
        ],
      ),
    );
    final Widget rest = faces.length <= inA
        ? const SizedBox.shrink()
        : Align(
            alignment: ltr ? Alignment.centerRight : Alignment.centerLeft,
            child: SizedBox(
              width: _plan(faces.length - inA).total,
              child: Ls01Row(
                key: const Key('overflow-row'),
                faces: faces.sublist(inA),
                looks: _looks().sublist(inA),
                metrics: m,
                direction: rowDirection,
                kind: _kind,
                zoneWidth: _plan(faces.length - inA).total,
                onTap: (int i) => choose(options[inA + i].id),
              ),
            ),
          );
    return Stack(
      clipBehavior: Clip.none,
      children: <Widget>[
        Positioned.fill(child: speaker),
        Positioned.fill(child: rest),
        if (ghostAt != null) _ghost(ghostAt!, target, m),
        for (final int i in ghostSettled)
          if (i != ghostAt) _ghost(i, target, m),
      ],
    );
  }

  /// The target glides over card [i] (hint level 2): a small copy of it, ringed, above the tile.
  Widget _ghost(int i, Ls01Face target, Ls01Metrics m) {
    final Rect r = _tileRects()[i];
    final Offset o = _stageOrigin;
    final double side = m.tileHeight * 0.62;
    return Positioned(
      left: r.center.dx - o.dx - side / 2,
      top: r.top - o.dy - side * 0.6,
      width: side,
      height: side,
      child: IgnorePointer(
        child: DecoratedBox(
          key: Key('ghost-$i'),
          decoration: BoxDecoration(
            color: TokenColors.skyTint,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: TokenColors.skyDeep, width: 3),
          ),
          child: Ls01FaceView(face: target, metrics: m, kind: FaceKind.kept),
        ),
      ),
    );
  }

  List<Ls01Look> _looks() => <Ls01Look>[
    for (final (int i, ChoiceOption o) in options.indexed)
      Ls01Look(
        state: _stateOf(o),
        lit: litSet.contains(i),
        picked: mode == Ls01TapMode.tapAll && picked.contains(o.id),
        dimmed:
            (mode == Ls01TapMode.cloze && gapId == o.id) ||
            (controller.answerShown && !_right.contains(o.id)),
        heard: true,
      ),
  ];

  AnswerState _stateOf(ChoiceOption o) {
    if (mode == Ls01TapMode.tapAll) {
      if (notYetPicks.contains(o.id)) return AnswerState.notYet;
      if (chosenState == AnswerState.correct && _right.contains(o.id)) return AnswerState.correct;
      if (controller.answerShown && _right.contains(o.id)) return AnswerState.selected;
      return AnswerState.idle;
    }
    if (chosenId == o.id) return chosenState;
    if (controller.answerShown && o.id == correctId) return AnswerState.selected;
    return AnswerState.idle;
  }

  @override
  Widget? buildTiles(BuildContext context, ActivitySpec spec) {
    _spec = spec;
    return ListenableBuilder(
      listenable: this,
      builder: (BuildContext c, Widget? _) {
        final int inA = _inA;
        return Ls01Row(
          key: const Key('ls01-row'),
          faces: faces.sublist(0, inA),
          looks: _looks().sublist(0, inA),
          metrics: metrics,
          direction: rowDirection,
          kind: _kind,
          zoneWidth: spec.tilesWidth,
          onTap: (int i) => choose(options[i].id),
        );
      },
    );
  }

  @override
  Widget? buildBoardLayer(BuildContext context, ActivitySpec spec) => ListenableBuilder(
    listenable: this,
    builder: (BuildContext c, Widget? _) => ls01HandLayer(handTip, spec) ?? const SizedBox.shrink(),
  );

  /// True once the tap-all has been checked and is right.
  bool get solvedAll => _checked && chosenState == AnswerState.correct;
}
