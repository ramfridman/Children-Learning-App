import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../child/activity_shell.dart';
import '../content/ls05_checks.dart' show composeFrame, isWheelSign;
import '../content/models.dart';
import '../design/board.dart' show BoardClass;
import '../design/components.dart';
import '../design/layout.dart';
import '../design/token_types.dart' show Band;
import '../design/tokens.g.dart';
import '../engine/course.dart';
import '../strings/he.dart';
import 'choice_row.dart' show withLs01Zones;
import 'hints/hint_pictures.dart' show SkyRing;
import 'l5_art.dart';
import 'lesson_controller.dart';
import 'ls01_hand.dart';
import 'ls05_widgets.dart';
import 'response_code.dart';
import 'template_session.dart';

/// LS05 change one part (docs/milestones/L5.md section 5.4, layout docs/design/l5-templates.md section 4): a frame with one or two places that change.
/// The Hebrew course turns a wheel of letters and picks a sign from a row, and the unit they make stands in the hub; the Russian course slides along a
/// strip of vowels and the word in the frame's window changes. `explore` is the unscored teaching screen: every change plays what it makes, nothing is
/// written, and the child goes on when she has heard a few. `make` is scored: "make the one you hear", then "that's it".
///
/// A mistake of `make` is the tag of the first part she picked that is not in the answer (the validator holds that every such part has one); the wheel
/// stays where it is, so she goes on from there. A combination that makes no sound (a stop letter with no vowel) shakes the hub and plays nothing.
class ChangePartSession extends TemplateSession {
  ChangePartSession(super.controller, this.a, {this.band = Band.b}) {
    current = <String>[
      for (int s = 0; s < a.frame.slots; s++)
        (a
                .partsOf(s)
                .firstWhere(
                  (ChangePart p) => !a.answerParts.contains(p.id),
                  orElse: () => a.partsOf(s).first,
                ))
            .id,
    ];
    turn = _ringIndex.toDouble();
  }

  final ChangePartActivity a;
  final Band band;

  BoardClass board = BoardClass.phone;

  /// The part now in each place of the frame.
  late List<String> current;

  /// The wheel's position: the index of the ring part at the top, continuous (it takes the short way round).
  late double turn;

  AnswerState state = AnswerState.idle;
  bool hubShake = false;
  bool hubLit = false;
  bool wobble = false;
  bool busy = false;
  bool demo = false;
  int run = 0;

  /// A hint's card (the key word of the target) and the hand's fingertip.
  bool card = false;
  Offset? handTip;
  int? litRing;
  int? litTile;

  /// The distinct results heard in `explore`: a few, and she may go on.
  final Set<String> heard = <String>{};
  static const int heardEnough = 2;

  bool get wheel => a.course == Course.heb;

  /// The wheel's ring is a slot's parts: the first place; with one place the ring carries it, with two the signs stand in a row.
  List<ChangePart> get ringParts => a.partsOf(0);
  List<ChangePart> get signParts => a.frame.slots == 2 ? a.partsOf(1) : const <ChangePart>[];
  bool get ringIsSigns => ringParts.isNotEmpty && ringParts.every((ChangePart p) => isWheelSign(p.text));

  /// The strip's tiles: the parts of the one place, a pair to a pill (the order of the pairs, then the item's own).
  List<ChangePart> get stripParts {
    final List<ChangePart> parts = List<ChangePart>.of(a.partsOf(0));
    final List<int> idx = List<int>.generate(parts.length, (int i) => i);
    idx.sort((int x, int y) {
      final int px = vowelPairOf(parts[x].text);
      final int py = vowelPairOf(parts[y].text);
      return px != py ? px.compareTo(py) : x.compareTo(y);
    });
    return <ChangePart>[for (final int i in idx) parts[i]];
  }

  int get _ringIndex => math.max(0, ringParts.indexWhere((ChangePart p) => p.id == current[0]));
  int get currentTile => math.max(0, stripParts.indexWhere((ChangePart p) => p.id == current[0]));

  ChangeResult? get result => a.resultFor(current);

  /// What the hub and the window show: the result's own text (the editor's pointing), or what the parts make when nothing does.
  String get madeText =>
      result?.text ?? composeFrame(a.frame.text, <String>[for (final String id in current) a.part(id).text]);

  /// The window shows the vowel in the frame's place.
  String get windowText => a.part(current[0]).text;

  // ---- the child's moves ----

  void pick(int slot, String id) {
    if (busy || demo || state == AnswerState.correct) return;
    if (a.make && controller.guided && !a.answerParts.contains(id)) return;
    current[slot] = id;
    if (slot == 0 && wheel) _turnTo(ringParts.indexWhere((ChangePart p) => p.id == id));
    litRing = null;
    notify();
    _hear();
  }

  /// A tap on a bead of the ring or a tile of the strip.
  void pickRing(int i) => pick(0, ringParts[i].id);
  void pickSign(int j) => pick(1, signParts[j].id);
  void pickTile(int i) => pick(0, stripParts[i].id);

  /// The strip's slide: the tile the finger is over becomes current without a sound; the one she rests on, or lifts from, plays.
  int _slide = 0;
  void slide(int i) {
    if (busy || demo || state == AnswerState.correct) return;
    if (a.make && controller.guided && !a.answerParts.contains(stripParts[i].id)) return;
    if (current[0] == stripParts[i].id) return;
    current[0] = stripParts[i].id;
    final int mine = ++_slide;
    notify();
    // A fast slide does not stack clips: only the tile she stays on for a moment is heard.
    later(const Duration(milliseconds: 200), () {
      if (mine == _slide) _hear();
    });
  }

  void slideEnd() {
    _slide++;
    _hear();
  }

  /// A wheel with as many letters as the dial has places (7) or more is a loop: what turns past the panel comes back on the other side. A shorter one
  /// only shifts its letters (see `ringOffset`), so its `turn` stays between 0 and its last letter and the letter picked stands at the top.
  bool get _loops => ringParts.length >= WheelSpec.of(board).slots;

  void _turnTo(int index) {
    final int n = ringParts.length;
    if (n == 0) return;
    if (!_loops) {
      turn = index.toDouble();
      return;
    }
    // The short way round.
    double d = (index - turn) % n;
    if (d < 0) d += n;
    if (d > n / 2) d -= n;
    turn += d;
  }

  /// A drag along the dial turns it; on release it settles on the nearest bead and says it.
  void dragTurn(double delta) {
    if (busy || demo || state == AnswerState.correct) return;
    turn += delta;
    if (!_loops) turn = turn.clamp(0.0, ringParts.length - 1.0);
    notify();
  }

  void dragEnd() {
    final int n = ringParts.length;
    if (n == 0) return;
    final int index = _loops ? ((turn.round() % n) + n) % n : turn.round().clamp(0, n - 1);
    turn = _loops ? turn.roundToDouble() : index.toDouble();
    pick(0, ringParts[index].id);
  }

  void _hear() {
    final ChangeResult? r = result;
    heard.add(current.join('.'));
    if (r?.clip != null) {
      playClips?.call(<String>[r!.clip!], replace: true);
    } else {
      // A unit with no sound (no result at all, or a result written with no clip): the hub swings gently, and nothing is played.
      hubShake = true;
      later(const Duration(milliseconds: 300), () {
        hubShake = false;
        notify();
      });
    }
    notify();
  }

  void hubTapped() => _hear();

  void replayTarget() {
    final String? clip = a.target?.clip;
    if (clip != null) playClips?.call(<String>[clip], replace: true);
  }

  /// "That's it" in `make`: the parts she made are the answer.
  Future<void> thatsIt() async {
    if (!a.make || busy || demo || state == AnswerState.correct) return;
    final bool right = <int>[for (int s = 0; s < current.length; s++) s]
        .every((int s) => current[s] == a.answerParts[s]);
    String tag = '';
    if (!right) {
      for (final String id in current) {
        final ChangePart p = a.part(id);
        if (!a.answerParts.contains(id) && p.tag != null) {
          tag = p.tag!;
          break;
        }
      }
    }
    busy = true;
    final Outcome o = await controller.submitPlacement(
      right: right,
      tag: tag,
      response: ResponseCode.parts(current),
    );
    if (disposed) return;
    if (o.settled || o.correct) {
      state = o.settled ? AnswerState.selected : AnswerState.correct;
      hubLit = true;
      notify();
      replayResult();
      later(praise, controller.next);
    } else {
      state = AnswerState.notYet;
      wobble = true;
      notify();
      later(TemplateSession.notYetPause, () {
        state = AnswerState.idle;
        wobble = false;
        busy = false;
        notify();
      });
    }
  }

  void replayResult() {
    final String? clip = result?.clip;
    if (clip != null) playClips?.call(<String>[clip], replace: true);
  }

  /// `explore` has no answer: when she has heard a few results she goes on, and nothing is written.
  void goOn() {
    if (a.make || busy || heard.length < heardEnough) return;
    busy = true;
    controller.completePractice();
    later(praise, controller.next);
  }

  bool get canGoOn => !a.make && heard.length >= heardEnough;

  // ---- hints (make) ----

  @override
  void onReset() {
    run++;
    state = AnswerState.idle;
    wobble = false;
    busy = false;
    demo = false;
    hubLit = false;
    card = false;
    handTip = null;
    litRing = null;
    litTile = null;
    notify();
  }

  @override
  void onReplay() => replayTarget();

  @override
  void onHint() {
    run++;
    card = false;
    handTip = null;
    hubLit = false;
    litRing = null;
    litTile = null;
    if (!a.make) return;
    switch (controller.hintShown) {
      case 1:
        _targetThenResult(run);
      case 2:
        card = true;
        notify();
      default:
        _friendTurns(run);
    }
    notify();
  }

  bool _live(int mine) => !disposed && mine == run;

  /// Level 1: the target again, then what she has made now, the hub lit.
  Future<void> _targetThenResult(int mine) async {
    hubLit = true;
    notify();
    final String? t = a.target?.clip;
    if (t != null) await sayAndWait(<String>[t], replace: true, without: const Duration(milliseconds: 800));
    if (!_live(mine)) return;
    final String? r = result?.clip;
    if (r != null) await sayAndWait(<String>[r], replace: true, without: const Duration(milliseconds: 800));
    if (!_live(mine)) return;
    hubLit = false;
    notify();
  }

  /// Level 3: the friend turns the dial to the right letter and taps the right sign (or slides to the right tile), the result plays, then everything goes
  /// back and she makes it.
  Future<void> _friendTurns(int mine) async {
    demo = true;
    final List<String> start = List<String>.of(current);
    final double startTurn = turn;
    notify();
    for (int s = 0; s < a.frame.slots; s++) {
      if (!_live(mine)) return;
      final Offset tip = _partTip(s, a.answerParts[s]);
      handTip = tip;
      notify();
      await pause(const Duration(milliseconds: 900));
      if (!_live(mine)) return;
      current[s] = a.answerParts[s];
      if (s == 0 && wheel) _turnTo(ringParts.indexWhere((ChangePart p) => p.id == a.answerParts[0]));
      notify();
      await pause(const Duration(milliseconds: 500));
    }
    if (!_live(mine)) return;
    final String? r = result?.clip;
    if (r != null) await sayAndWait(<String>[r], replace: true, without: const Duration(milliseconds: 700));
    if (!_live(mine)) return;
    handTip = null;
    current = start;
    turn = startTurn;
    demo = false;
    notify();
    controller.demoDone();
  }

  /// The wheel on [b], with the dial raised where a row of four signs would not fit under the lowest letter beads (`WheelSpec.fitted`).
  WheelSpec wheelFor(BoardClass b) =>
      WheelSpec.of(b).fitted(signParts.length, bottom: b.size.height - _panelMargin + 1);

  /// The panel runs to the bottom band less 8 (board 24 + 8 points from the bottom).
  static const double _panelMargin = 24 + 8;

  /// Where the friend's fingertip goes for part [id] of place [slot], in board points.
  Offset _partTip(int slot, String id) {
    if (wheel) {
      final WheelSpec w = wheelFor(board);
      if (slot == 0) return Offset(w.centre.dx, w.centre.dy - w.ring - w.bead * 0.2);
      final int j = signParts.indexWhere((ChangePart p) => p.id == id);
      final int n = signParts.length;
      final double total = n * w.signBead + (n - 1) * w.signGap;
      return Offset(
        w.centre.dx - total / 2 + (n - 1 - j) * (w.signBead + w.signGap) + w.signBead / 2,
        w.signY + 6,
      );
    }
    final StripGeometry g = StripGeometry.of(
      board,
      a,
      stripParts.map((ChangePart p) => p.text).toList(),
      a.make,
    );
    final int i = stripParts.indexWhere((ChangePart p) => p.id == id);
    return Offset(g.tile(i).center.dx, g.tile(i).top + 6);
  }

  // ---- layout ----

  /// The board class a spec was made for (the specs are the boards' own, told apart by their height).
  static BoardClass boardOfSpec(ActivitySpec s) => s.boardHeight > 1000
      ? BoardClass.tabletPortrait
      : s.boardHeight > 500
      ? BoardClass.tabletLandscape
      : s.boardHeight < 380
      ? BoardClass.phoneSE
      : BoardClass.phone;

  /// Where the bubble must end on the wheel's board: above the dial's beads that stand under it and, in `make` on a phone, above the hint's key-word
  /// card. The activity frame shrinks the line's text to the room above this (it ends 4 points higher), so a line never lies on a bead or the card; the
  /// phone SE has room for 2 lines at the board's font and shrinks a third (QA-2, QA-3).
  double bubbleFloor(ActivitySpec base, BoardClass b) {
    final double left = base.bubbleLeft ?? b.size.width - base.bubbleRight! - base.bubbleMaxWidth;
    double floor = base.tilesTop;
    for (final Rect r in wheelFor(b).beadRects()) {
      if (r.right > left && r.left < left + base.bubbleMaxWidth && r.bottom > base.bubbleTop) {
        floor = math.min(floor, r.top);
      }
    }
    if (a.make) {
      final Rect? key = ChangePartLayer.keyCardOver(b);
      if (key != null) floor = math.min(floor, key.top);
    }
    return floor;
  }

  @override
  ActivitySpec layoutFor(ActivitySpec base) {
    if (!wheel) return withLs01Zones(base, band);
    // The wheel stands on the left of the board, from the stage's top to the bottom band: a tall stage with no card on a tablet.
    final BoardClass b = boardOfSpec(base);
    final bool tablet = base.stageIsCard;
    final Rect stage = tablet
        ? Rect.fromLTWH(194, base.stage.top, 792, base.boardHeight - 24 - 8 - base.stage.top)
        : Rect.fromLTWH(
            base.stage.left,
            base.stage.top,
            base.stage.width,
            base.boardHeight - 24 - 8 - base.stage.top,
          );
    return base.withStageAndTiles(
      stage: stage,
      tilesLeft: base.tilesLeft,
      tilesTop: bubbleFloor(base, b),
      tilesWidth: base.tilesWidth,
      card: false,
    );
  }

  @override
  Widget buildStage(BuildContext context, Size size, ActivitySpec spec) {
    return Semantics(
      container: true,
      label: a.altText,
      child: wheel ? const SizedBox.expand() : const StagePanel(child: SizedBox.expand()),
    );
  }

  @override
  Widget? buildTiles(BuildContext context, ActivitySpec spec) => null;

  @override
  Widget? buildBoardLayer(BuildContext context, ActivitySpec spec) {
    board = AppLayout.of(context).board;
    return ListenableBuilder(
      listenable: this,
      builder: (BuildContext c, Widget? _) => ChangePartLayer(session: this, spec: spec, board: board),
    );
  }
}

/// Where the strip's pieces stand on a board, in board points (Russian: always left to right).
///
/// In `explore` the strip may be so long (6 vowels fill the answer zone on a phone) that the "go on" check and the word's picture would stand over
/// its first and last tiles. Such a screen is [crowded]: the strip is centred in the answer zone and the check, the card and the picture stand in a
/// row in the stage zone instead, so that the strip never hides a vowel (docs/design/l5-templates.md section 4.3). The picture is dropped when
/// not even 48 points are left for it.
class StripGeometry {
  StripGeometry._(
    this.spec,
    this.cardSpec,
    this.card,
    this.rowLeft,
    this.rowY,
    this.control,
    this.picture,
    this.target,
    this.check,
    this.goOn,
    this.zoneA,
    this.texts,
    this.crowded,
  );

  factory StripGeometry.of(BoardClass board, ChangePartActivity a, List<String> texts, bool make) {
    final StripSpec s = StripSpec.of(board);
    final bool tablet = board == BoardClass.tabletLandscape || board == BoardClass.tabletPortrait;
    final Rect zoneA = switch (board) {
      BoardClass.phone => const Rect.fromLTWH(24, 252, 581, 117),
      BoardClass.phoneSE => const Rect.fromLTWH(24, 238, 484, 113),
      BoardClass.tabletLandscape => const Rect.fromLTWH(194, 554, 772, 242),
      BoardClass.tabletPortrait => const Rect.fromLTWH(24, 684, 772, 472),
    };
    final Rect stage = switch (board) {
      BoardClass.phone => const Rect.fromLTWH(24, 96, 377, 148),
      BoardClass.phoneSE => const Rect.fromLTWH(24, 86, 262, 144),
      BoardClass.tabletLandscape => const Rect.fromLTWH(304, 246, 552, 268),
      BoardClass.tabletPortrait => const Rect.fromLTWH(40, 388, 740, 268),
    };
    final double ctl = switch (board) {
      BoardClass.phone => 72,
      BoardClass.phoneSE => 56,
      _ => 96,
    };
    final double pic = switch (board) {
      BoardClass.phone => 88,
      BoardClass.phoneSE => 72,
      BoardClass.tabletLandscape => 140,
      BoardClass.tabletPortrait => 160,
    };
    final double rowY = switch (board) {
      BoardClass.phone => 264,
      BoardClass.phoneSE => 254,
      BoardClass.tabletLandscape => 566,
      BoardClass.tabletPortrait => 700,
    };
    final double total = VowelStrip.widthOf(texts, s);
    final double controlY = rowY + (s.tile - ctl) / 2;
    final Rect target = Rect.fromLTWH(zoneA.left + 8, controlY, ctl, ctl);
    final Rect check = Rect.fromLTWH(zoneA.right - 8 - ctl, controlY, ctl, ctl);
    final Rect picture = Rect.fromLTWH(
      zoneA.right - pic - 4,
      math.max(zoneA.top + 10, rowY + (s.tile - pic) / 2),
      pic,
      pic,
    );
    final bool pictured = a.results.any((ChangeResult r) => r.sprite != null);
    double left;
    if (make) {
      final double from = zoneA.left + ctl + 24;
      final double room = zoneA.width - 2 * (ctl + 24);
      left = from + (room - total) / 2;
    } else if (!tablet && pictured) {
      left = zoneA.left + (zoneA.width - pic - 24 - total) / 2;
    } else {
      left = zoneA.left + (zoneA.width - total) / 2;
    }
    final bool crowded =
        !make && (left < target.right + 16 || (pictured && left + total + 16 > picture.left));
    // The card is its cells and the 8 points of its border and padding round them.
    final int cells = a.frame.text.length;
    StripSpec cardSpec = s;
    double cardW = cells * s.cell + 16;
    double cardH = s.cell * 0.92 + 16;
    Rect card = Rect.fromLTWH(
      stage.left + (stage.width - cardW) / 2,
      stage.top + (stage.height - cardH) / 2,
      cardW,
      cardH,
    );
    Rect goOn = target;
    Rect pictureAt = picture;
    if (crowded) {
      left = zoneA.left + (zoneA.width - total) / 2;
      const double gap = 16;
      const double margin = 8;
      final double room = stage.width - 2 * margin;
      // The check and the card must both fit the stage; a long frame's cells shrink to what is left.
      final double cardRoom = room - ctl - gap;
      if (cardW > cardRoom) {
        cardSpec = s.withCell(math.max(48, (cardRoom - 16) / cells));
        cardW = cells * cardSpec.cell + 16;
        cardH = cardSpec.cell * 0.92 + 16;
      }
      double pw = pictured ? math.min(pic, room - ctl - cardW - 2 * gap) : 0;
      if (pw < 48) pw = 0;
      final double rowW = ctl + gap + cardW + (pw > 0 ? gap + pw : 0);
      final double x0 = stage.left + (stage.width - rowW) / 2;
      final double mid = stage.center.dy;
      goOn = Rect.fromLTWH(x0, mid - ctl / 2, ctl, ctl);
      card = Rect.fromLTWH(goOn.right + gap, mid - cardH / 2, cardW, cardH);
      pictureAt = pw > 0 ? Rect.fromLTWH(card.right + gap, mid - pw / 2, pw, pw) : Rect.zero;
    }
    return StripGeometry._(
      s,
      cardSpec,
      card,
      left,
      rowY,
      ctl,
      pictureAt,
      target,
      check,
      goOn,
      zoneA,
      texts,
      crowded,
    );
  }

  final StripSpec spec;

  /// The sizes of the frame card: the strip's, with the cells shrunk when a crowded screen needs the room.
  final StripSpec cardSpec;
  final Rect card;
  final double rowLeft;
  final double rowY;
  final double control;

  /// The word's picture (empty when a crowded screen has no room for it).
  final Rect picture;
  final Rect target;
  final Rect check;

  /// The "go on" check of `explore`: at the start of the answer zone, or in the stage zone when the screen is [crowded].
  final Rect goOn;
  final Rect zoneA;
  final List<String> texts;
  final bool crowded;

  bool get hasPicture => !picture.isEmpty;

  /// Tile [i] of the strip (the pairs' gaps are in it).
  Rect tile(int i) {
    double x = rowLeft;
    for (int k = 1; k <= i; k++) {
      final int p = vowelPairOf(texts[k - 1]);
      x += spec.tile + (p >= 0 && p == vowelPairOf(texts[k]) ? spec.inPair : spec.betweenPairs);
    }
    return Rect.fromLTWH(x, rowY, spec.tile, spec.tile);
  }
}

/// What LS05 draws on the board.
class ChangePartLayer extends StatelessWidget {
  const ChangePartLayer({super.key, required this.session, required this.spec, required this.board});

  final ChangePartSession session;
  final ActivitySpec spec;
  final BoardClass board;

  @override
  Widget build(BuildContext context) {
    final ChangePartSession s = session;
    return Positioned.fill(
      child: Stack(
        clipBehavior: Clip.none,
        children: <Widget>[
          if (s.wheel) ..._wheel(context, s) else ..._strip(s),
          ?ls01HandLayer(s.handTip, spec),
        ],
      ),
    );
  }

  List<Widget> _wheel(BuildContext context, ChangePartSession s) {
    final WheelSpec w = s.wheelFor(board);
    final double panelBottom = board.size.height - ChangePartSession._panelMargin;
    final List<ChangePart> ring = s.ringParts;
    final List<ChangePart> signs = s.signParts;
    final (Rect, Rect) controls = _controls(w, signs.length);
    // On the wide tablet the pebble stands beyond a long row of signs, and the panel runs 8 points past it.
    final double panelEnd = board == BoardClass.tabletLandscape
        ? math.max(w.centre.dx + w.panelSpan / 2, controls.$2.right + _pebbleRoom)
        : w.centre.dx + w.panelSpan / 2;
    final WheelSpec full = w.copyWith(
      panelHeight: panelBottom - (w.centre.dy - 4),
      panelWidth: 2 * (panelEnd - w.centre.dx),
    );
    return <Widget>[
      Positioned.fill(
        child: GestureDetector(
          key: const Key('wheel-dial'),
          behavior: HitTestBehavior.translucent,
          onHorizontalDragUpdate: (DragUpdateDetails d) =>
              s.dragTurn(-d.delta.dx / (full.ring * full.step * 3.14159 / 180)),
          onHorizontalDragEnd: (DragEndDetails _) => s.dragEnd(),
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(end: s.turn),
            duration: MediaQuery.disableAnimationsOf(context)
                ? Duration.zero
                : const Duration(milliseconds: 350),
            curve: Curves.easeOutBack,
            builder: (BuildContext c, double turn, Widget? _) => Wobble(
              on: s.wobble,
              child: WheelView(
                spec: full,
                ring: <String>[for (final ChangePart p in ring) p.text],
                ringIsSigns: s.ringIsSigns,
                turn: turn,
                hubText: s.madeText,
                hubLit: s.hubLit,
                hubShake: s.hubShake,
                onHub: s.hubTapped,
                onRing: s.pickRing,
                litRing: s.litRing,
                signs: <String>[for (final ChangePart p in signs) p.text],
                curSign: math.max(
                  0,
                  signs.indexWhere((ChangePart p) => p.id == (s.current.length > 1 ? s.current[1] : '')),
                ),
                onSign: s.pickSign,
                groups: signGroups(<String>[
                  for (final ChangePart p in signs) p.text,
                ], (int x, int y) => _sameSound(s, signs[x].id, signs[y].id)),
              ),
            ),
          ),
        ),
      ),
      ..._buttons(s, controls),
    ];
  }

  bool _sameSound(ChangePartSession s, String x, String y) {
    bool any = false;
    for (final ChangePart l in s.a.partsOf(0)) {
      final ChangeResult? rx = s.a.resultFor(<String>[l.id, x]);
      final ChangeResult? ry = s.a.resultFor(<String>[l.id, y]);
      if (rx?.clip != null && rx?.clip == ry?.clip) any = true;
      if ((rx?.clip ?? '') != (ry?.clip ?? '')) return false;
    }
    return any;
  }

  static const double _pebbleRoom = 8;

  /// The target and "that's it" pebbles: under the bubble on the phones, at the panel's ends on the tablets. On the wide tablet a row of four signs
  /// reaches the right end, so the pebble there stands 8 points beyond the row.
  (Rect, Rect) _controls(WheelSpec w, int signs) {
    final (Rect, Rect) c = _controlsAt();
    if (board != BoardClass.tabletLandscape || signs == 0) return c;
    final double right = math.max(c.$2.left, w.centre.dx + w.signRowReach(signs) + 8);
    return (c.$1, c.$2.shift(Offset(right - c.$2.left, 0)));
  }

  (Rect, Rect) _controlsAt() => switch (board) {
    BoardClass.phone => (const Rect.fromLTWH(429, 262, 72, 72), const Rect.fromLTWH(521, 262, 72, 72)),
    BoardClass.phoneSE => (const Rect.fromLTWH(352, 262, 64, 64), const Rect.fromLTWH(436, 262, 64, 64)),
    BoardClass.tabletLandscape => (
      const Rect.fromLTWH(272, 664, 96, 96),
      const Rect.fromLTWH(752, 664, 96, 96),
    ),
    BoardClass.tabletPortrait => (
      const Rect.fromLTWH(112, 1000, 96, 96),
      const Rect.fromLTWH(612, 1000, 96, 96),
    ),
  };

  List<Widget> _buttons(ChangePartSession s, (Rect, Rect) c) => <Widget>[
    if (s.a.make)
      Positioned.fromRect(
        rect: c.$1.inflate(12),
        child: PebbleButton(
          key: const Key('change-target'),
          semanticLabel: He.changeTargetSemantics.text,
          size: c.$1.width,
          fill: TokenColors.skyTint,
          lip: TokenColors.skyDeep,
          onPressed: s.replayTarget,
          child: Icon(Icons.volume_up_rounded, size: c.$1.width * 0.5, color: TokenColors.ink),
        ),
      ),
    Positioned.fromRect(
      rect: c.$2.inflate(12),
      child: PebbleButton(
        key: const Key('change-done'),
        semanticLabel: He.changeThatsItSemantics.text,
        size: c.$2.width,
        onPressed: s.a.make ? s.thatsIt : (s.canGoOn ? s.goOn : null),
        child: Icon(Icons.check_rounded, size: c.$2.width * 0.55, color: TokenColors.ink),
      ),
    ),
    if (s.card) ..._keyCard(s),
  ];

  /// The phones have no free corner: the card stands under the bubble, between its text and the make controls, and the layout keeps the bubble's text
  /// above it (`ChangePartSession.bubbleFloor`). A tablet has room beside the dial (null here).
  static Rect? keyCardOver(BoardClass board) => switch (board) {
    BoardClass.phone => const Rect.fromLTWH(421, 186, 174, 66),
    BoardClass.phoneSE => const Rect.fromLTWH(330, 184, 146, 68),
    _ => null,
  };

  static Rect _keyCardBeside(BoardClass board) => switch (board) {
    BoardClass.tabletLandscape => const Rect.fromLTWH(40, 330, 230, 200),
    _ => const Rect.fromLTWH(40, 376, 220, 92),
  };

  /// Level 2: the key word of the target unit with its picture, in a sky card at the stage's free corner.
  List<Widget> _keyCard(ChangePartSession s) {
    final ChangeResult? t = s.a.target;
    final Rect r = keyCardOver(board) ?? _keyCardBeside(board);
    return <Widget>[
      Positioned.fromRect(
        rect: r,
        child: IgnorePointer(
          child: SkyCard(
            key: const Key('change-key-card'),
            child: Center(
              child: t?.sprite != null
                  ? Padding(padding: const EdgeInsets.all(8), child: PackSvg(s.a.assets.svg(t!.sprite!)))
                  : const Icon(Icons.image_rounded, size: 48, color: TokenColors.skyDeep),
            ),
          ),
        ),
      ),
    ];
  }

  List<Widget> _strip(ChangePartSession s) {
    final List<ChangePart> parts = s.stripParts;
    final List<String> texts = <String>[for (final ChangePart p in parts) p.text];
    final StripGeometry g = StripGeometry.of(board, s.a, texts, s.a.make);
    final ChangeResult? r = s.result;
    // A teaching screen's picture stands at the end of the zone where "that's it" stands in make, so its go-on pebble takes the start side (or the stage's,
    // on a crowded screen).
    final (Rect, Rect) controls = (g.target, s.a.make ? g.check : g.goOn);
    return <Widget>[
      Positioned.fromRect(
        rect: g.card,
        child: FrameCard(
          course: s.a.course,
          frame: s.a.frame.text,
          window: s.windowText,
          spec: g.cardSpec,
          lit: s.hubLit,
          onTap: s.hubTapped,
        ),
      ),
      Positioned(
        left: g.rowLeft,
        top: g.rowY,
        child: VowelStrip(
          texts: texts,
          course: s.a.course,
          spec: g.spec,
          current: s.currentTile,
          onPick: s.pickTile,
          onSlide: s.slide,
          onSlideEnd: s.slideEnd,
          litTile: s.litTile,
        ),
      ),
      // A result that is a word with a picture (kot, kit): the picture stands at the end of the answer zone, and changes with the vowel.
      if (!s.a.make && r?.sprite != null && g.hasPicture)
        Positioned.fromRect(
          rect: g.picture,
          child: Container(
            key: const Key('strip-picture'),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: TokenColors.hairline, width: 3),
              boxShadow: clayShadows(TokenColors.cardLip, lipHeight: 4),
            ),
            child: PackSvg(s.a.assets.svg(r!.sprite!)),
          ),
        ),
      if (s.hubLit)
        Positioned.fromRect(
          rect: g.card.inflate(8),
          child: const IgnorePointer(child: SkyRing(round: false, radius: 30)),
        ),
      ..._buttons(s, controls),
    ];
  }
}
