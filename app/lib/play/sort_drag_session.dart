import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../child/activity_shell.dart';
import '../content/arc_checks.dart' show hintFamilyOf;
import '../content/hint_ladder.dart';
import '../content/models.dart';
import '../design/components.dart';
import '../design/tokens.g.dart';
import 'hints/hint_marks.dart';
import 'hints/hint_pictures.dart' show hintScale;
import 'hints/hint_player.dart';
import 'hints/pointer_plans.dart';
import 'hints/tile_points.dart';
import 'activity_frame.dart' show ActivityFrame;
import 'lesson_arc.dart' show ArcPart, ArcStep;
import 'show_solids.dart';
import 'show_stage.dart';
import 'size_scale.dart';
import 'sort_board.dart';
import 'response_code.dart';
import 'template_session.dart';

/// The sort-and-drag template (T03). Pictures wait below the stage; the bins stand on the stage. A picture is dragged into
/// a bin, or touched and then the bin is touched (the same move, for a hand that does not drag yet). A wrong bin is a gentle
/// "not yet" and the picture stays in the tray; after three of them only the right bin takes it, and the guide first sorts one
/// picture as a worked example, which leaves the picture and its bin lit.
///
/// In share mode (two or three friends, a number of pictures that divides evenly) any bin takes any picture, and the check is
/// that all end up with the same number: a child who shares unequally gets a "not yet" with M-SHARE-UNEQ and starts dealing
/// again.
///
/// A wrong drop records the tag of the picture itself when it has one (a thing that is not a triangle shows what it is mistaken for), else the
/// activity's. The host's part (M11 Stage 2): a Show (`purpose: show`) is acted by the host, which sorts every picture but the last, and the child
/// sorts the last one, with nothing written and a wrong bin only a "let's look again"; a Together item has the host sort its first pictures
/// ([ArcStep.lead]) before the child sorts the rest.
class SortDragSession extends TemplateSession {
  SortDragSession(super.controller, this.activity);

  final SortDragActivity activity;

  /// Where each picture is now: item id to bin id. A picture that is not here is still in the tray.
  final Map<String, String> placed = <String, String>{};

  /// The picture that has been touched and waits for a bin.
  String? selected;

  /// The picture and the bin that the help points at, and the bin that just said "not yet".
  String? hintItem;
  String? hintBin;
  String? notYetBin;

  /// The bin or plate that the light of hint 1 and 2 is on now. It goes through all of them and rests on none.
  String? litBin;
  int _run = 0;

  AnswerState ring = AnswerState.idle;
  bool _busy = false;
  bool demoRunning = false;

  /// The pointing hand and the picture that glides past the bins (B-40), and the stage's and the board's sizes they are placed by.
  late final HintPlayer _hint = HintPlayer(this);
  Size _size = Size.zero;
  ActivitySpec? _spec;

  /// The size the bins' labels are drawn at (see [labelScale]), worked out when the stage is built, for the stage's size and the text size.
  double _labelScale = 1;

  /// The picture the host holds up in the middle of the stage in a Show (it has left its tile and is not in a bin yet).
  String? _lifted;

  List<SortItem> get tray => <SortItem>[
    for (final SortItem i in activity.items)
      if (!placed.containsKey(i.id) && i.id != _lifted) i,
  ];

  int countIn(String bin) => placed.values.where((String b) => b == bin).length;

  /// The picture the guide has put in a bin while it demonstrates a sort, and whether a deal stops after the first round.
  String? _demoItem;
  bool _dealFirstOnly = false;

  /// A touch of the child ends the guide's demonstration at once, and the child's move is taken. What the guide had dealt for
  /// the child to go on from (the first round) stays; what it had put in a bin as an example goes back.
  void _endDemo() {
    _hint.clear();
    if (!demoRunning) return;
    _run++;
    if (_demoItem != null) {
      placed.remove(_demoItem);
      _demoItem = null;
    } else if (!_dealFirstOnly) {
      placed.clear();
    }
    demoRunning = false;
    controller.demoDone();
  }

  /// The most pictures any bin takes: those that belong in it, or an equal share of them where any bin takes any picture.
  int get mostPerBin => activity.share
      ? (activity.items.length / math.max(1, activity.bins.length)).ceil()
      : activity.bins.fold(
          1,
          (int m, SortBin b) => math.max(m, activity.items.where((SortItem i) => i.bin == b.id).length),
        );

  /// The cards are wide pictures (a pattern strip, whose viewBox is not square): the board draws them 2.5 wide for 1 high, as large as a board
  /// lets a strip's animals be told apart (see [SortBoard]).
  late final bool wide = activity.items.any((SortItem i) {
    final double? aspect = i.sprite == null ? null : viewBoxAspect(activity.assets.svg(i.sprite!));
    return aspect != null && aspect > 1.3;
  });

  /// What a bin's sample picture is, for the board's room: one picture, a few of them, or a tally of sticks.
  List<BinMark> get _marks => <BinMark>[
    for (final SortBin b in activity.bins)
      (count: b.count, tally: b.count > 1 && b.sprite == 'asset:stick_long'),
  ];

  /// The bins show a size rule's samples (a big and a small one): the small one is a third of its box, so the box is drawn larger.
  late final bool _bigMark = sampleBoxShares.any((double s) => s < 1);

  List<String> get _labels => <String>[for (final SortBin b in activity.bins) b.label];

  /// The board of this stage (shelves or bins and their wells), worked out when the stage is built, for its size and the text size.
  SortBoard? _board;
  (SortKind, Size, double)? _boardKey;

  SortBoard _boardFor(SortKind kind, Size size, double scale) => SortBoard(
    kind: kind,
    stage: size,
    labels: _labels,
    marks: _marks,
    wide: wide,
    share: activity.share,
    bigMark: _bigMark,
    scale: scale,
  );

  /// The tray of the board: a deck on a phone, the cards in a grid on a tablet.
  SortTray _trayOf(ActivitySpec spec, SortKind kind) => SortTray.of(
    kind: kind,
    wide: wide,
    count: activity.items.length,
    width: spec.tilesWidth,
    look: spec.tileSize,
  );

  /// The deck's order: the card the host or the hint holds first, else the tray's own.
  List<SortItem> _deckOrder(List<SortItem> left) {
    final int at = left.indexWhere((SortItem i) => i.id == hintItem);
    if (at <= 0) return left;
    return <SortItem>[left[at], ...left.sublist(0, at), ...left.sublist(at + 1)];
  }

  /// The fingertip place on the top edge of the tray's tile that holds [item] (on a phone, the top of the deck: where the card [item] is).
  Offset _trayTip(SortItem item) => _tipAt(tray.length, tray.indexWhere((SortItem i) => i.id == item.id));

  /// The same for the tile at place [i] of a tray of [count] cards.
  Offset _tipAt(int count, int i) {
    final ActivitySpec spec = _spec!;
    final Offset tip = _trayOf(spec, SortKind.of(spec)).tip(count, math.max(0, i), spec.tilesWidth);
    return spec.fromTiles(tip.dx, tip.dy);
  }

  /// The stop of the hand at the drop place of bin [i]. The hand comes from below, so that its body lies under the fingertip.
  HandStop _dropStop(int i, int ms) => HandStop(_board!.dropPlace(i), ms, from: HandFrom.below);

  /// How much of its room the sample picture of each bin takes (see [sampleBoxSharesOf]): the small sample of a size rule is drawn larger
  /// than its sprite's own third, so that it is not a dot beside the big one.
  late final List<double> sampleBoxShares = sampleBoxSharesOf(<double>[
    for (final SortBin b in activity.bins) sizeShareOf(activity.assets.svg(b.sprite!)),
  ]);

  /// The side of the square the host holds a card up in: the stage's, but on a phone's tall stage no more than 150, so that the card held up leaves the shelves
  /// in view and has a way to roll to its shelf.
  double get _spotSide =>
      math.min(ShowDirector.spotSide(_size), _board?.tablet ?? false ? double.infinity : 150);

  bool get _canDraw => _spec != null && !_size.isEmpty && _board != null;

  /// The stage and the tray of each board (docs/design/m11/min-sizes.md 3.3). A phone: the stage is the whole start column, 377 by 260 (the
  /// smallest: 264 by 256), and the tray is a deck under the bubble with its tile's foot at the line where no hotspot stands. A tablet: the stage is
  /// the wide card (848 wide, 24 from the board's edge) and the tray is under it: the card is as tall as the tray leaves room for.
  @override
  ActivitySpec layoutFor(ActivitySpec base) {
    final SortKind kind = SortKind.of(base);
    final SortTray tray = _trayOf(base, kind);
    switch (kind) {
      case SortKind.phone:
      case SortKind.phoneSE:
        final bool se = kind == SortKind.phoneSE;
        final double foot = base.boardHeight - (se ? 39 : 35);
        return base.withStageAndTiles(
          stage: se ? const Rect.fromLTWH(24, 86, 264, 256) : const Rect.fromLTWH(24, 96, 377, 260),
          tilesLeft: se ? 302 : 413,
          tilesTop: foot - tray.tile.height + base.tileSlop - 4,
          tilesWidth: se ? 204 : 192,
        );
      case SortKind.tabletL:
      case SortKind.tabletP:
        final bool land = kind == SortKind.tabletL;
        const double left = 24;
        final double width = land ? 848 : 772;
        // The card: a strip's tray is two rows of wide tiles; a square's is one row (two from six or seven), so the card takes what is left.
        final bool oneRow = !wide && tray.rowsFor(activity.items.length, width) == 1;
        final double height = wide
            ? (land ? 270 : 420)
            : (land ? (oneRow ? 400 : 300) : (oneRow ? 520 : 420));
        return base.withStageAndTiles(
          stage: Rect.fromLTWH(left, base.stage.top, width, height),
          tilesLeft: left,
          tilesTop: base.stage.top + height + 24 + base.tileSlop - 4,
          tilesWidth: width,
        );
    }
  }

  /// The tray's tiles have a tap margin of 4 and the row starts `tileSlop` above the tiles' place, so the drawn tiles stand 12 or 8 above it.
  @override
  double tilesRise(ActivitySpec spec) => spec.tileSlop - 4;

  /// The width over the height of a picture's `viewBox`, or null when it has none.
  static double? viewBoxAspect(String svg) {
    final RegExpMatch? m = RegExp(r'viewBox="\s*[-\d.]+[ ,]+[-\d.]+[ ,]+([\d.]+)[ ,]+([\d.]+)')
        .firstMatch(svg);
    if (m == null) return null;
    final double w = double.parse(m.group(1)!), h = double.parse(m.group(2)!);
    return h == 0 ? null : w / h;
  }

  void select(String itemId) {
    _endDemo();
    if (_busy || hosting || ring == AnswerState.correct) return;
    selected = selected == itemId ? null : itemId;
    notify();
  }

  /// A touch on a bin: the touched picture goes in.
  void tapBin(String binId) {
    final String? s = selected;
    if (s != null) drop(s, binId);
  }

  Future<void> drop(String itemId, String binId) async {
    _endDemo();
    if (_busy || hosting || ring == AnswerState.correct || placed.containsKey(itemId)) return;
    final SortItem item = activity.items.firstWhere((SortItem i) => i.id == itemId);
    if (activity.share) {
      placed[itemId] = binId;
      selected = null;
      notify();
      if (placed.length == activity.items.length) await _checkShare();
      return;
    }
    if (item.bin == binId) {
      placed[itemId] = binId;
      selected = null;
      hintItem = null;
      hintBin = null;
      notify();
      if (placed.length == activity.items.length) await _done();
      return;
    }
    // The wrong bin of a Show: nothing is written and nothing is counted; the host looks again and points.
    if (activity.isShow) {
      _lookAgain(item, binId);
      return;
    }
    // The wrong bin. With only the right bin left (after three tries) it is simply not taken.
    if (controller.guided) {
      if (controller.answerShown) _pointAt(item);
      return;
    }
    _busy = true;
    notYetBin = binId;
    notify();
    await controller.submitPlacement(
      right: false,
      tag: item.misconception ?? activity.wrongTag ?? '',
      response: ResponseCode.sortMove(itemId, binId),
    );
    if (disposed) return;
    later(TemplateSession.notYetPause, () {
      notYetBin = null;
      selected = null;
      _busy = false;
      if (controller.answerShown) _pointAt(item);
      notify();
    });
  }

  Future<void> _done() async {
    _busy = true;
    if (activity.isShow) {
      // The child made the last step of the Show: the host's key line is said again as the praise, and nothing is written.
      controller.completePractice();
      ring = AnswerState.correct;
      notify();
      later(praise, controller.next);
      return;
    }
    await controller.submitPlacement(right: true, response: ResponseCode.sorted);
    if (disposed) return;
    ring = AnswerState.correct;
    notify();
    later(praise, controller.next);
  }

  Future<void> _checkShare() async {
    _busy = true;
    final bool equal = activity.bins.map((SortBin b) => countIn(b.id)).toSet().length == 1;
    if (equal) {
      await _done();
      return;
    }
    await controller.submitPlacement(
      right: false,
      tag: activity.wrongTag ?? '',
      response: ResponseCode.share(<(String, int)>[
        for (final SortBin b in activity.bins) (b.id, countIn(b.id)),
      ]),
    );
    if (disposed) return;
    ring = AnswerState.notYet;
    notify();
    later(TemplateSession.notYetPause, () {
      ring = AnswerState.idle;
      placed.clear();
      _busy = false;
      if (controller.guided) _dealDemo();
      notify();
    });
  }

  /// A Show, and the child's step went in the wrong bin: the host says "let's look again" and its hand points at the bin. Nothing is written,
  /// nothing is counted, and the child may try as often as it likes.
  void _lookAgain(SortItem item, String binId) {
    _busy = true;
    notYetBin = binId;
    controller.speak(activity.feedback.forIncorrect(null));
    _pointAt(item);
    later(TemplateSession.notYetPause, () {
      notYetBin = null;
      selected = null;
      _busy = false;
      notify();
    });
  }

  // ---- the host's part (a Show, the lead of a Together item) ----

  SortItem _itemOf(ShowStep step) => activity.items.firstWhere((SortItem i) => i.id == step.item);

  /// The bin the host puts [item] in: its own, or in a share the next plate in turn (a deal: the first card to the first friend, the second to the
  /// second, and round again).
  String _binOf(SortItem item) =>
      item.bin ?? activity.bins[activity.items.indexOf(item) % activity.bins.length].id;

  /// The host's hand takes [item] from the tray and puts it in its bin: the same path as the worked example of a hint, at the pace of the
  /// look ([fast]: a reminder). A step with a motion of its own (a finger along the sides, a count) rests on the picture first, as long as the
  /// motion would take; what it looks like is the design's (the hand's own motions are drawn by the design-director).
  Future<void> _hostMove(SortItem item, {required bool fast, bool rests = false}) async {
    // With reduced movement no hand travels: the card is in its bin after its pause. (The pace is the same for every look: a full Show of a sort is
    // 19 seconds or so, and the youngest looks have 25.)
    final int taken = fast ? 300 : 850;
    final int put = fast ? 550 : 1250;
    final int over = fast ? 900 : 2200;
    final int rest = rests && !fast ? 600 : 0;
    final String bin = _binOf(item);
    hintItem = item.id;
    notify();
    if (_canDraw && !stillHost) {
      _hint.play(
        handTourPlan(<HandStop>[
          HandStop(_trayTip(item), taken + rest),
          _dropStop(activity.bins.indexWhere((SortBin b) => b.id == bin), over - taken),
        ]),
      );
    }
    await pause(Duration(milliseconds: put + rest));
    placed[item.id] = bin;
    hintItem = null;
    notify();
    await pause(Duration(milliseconds: over - put));
  }

  /// A step of a Show with a motion of the host's hand (a finger along the sides, a count, an ant, sticks, a push, a stack, a turn, a stamp): the
  /// picture is lifted to the middle of the stage, shown, and dragged into its bin. Anything the director has no row for, a reminder and a stage with
  /// no art for the hand is the plain drag of [_hostMove].
  Future<void> _hostShow(ShowStep step, {required bool fast}) async {
    final ShowStyle? style = showStyle;
    final SortItem item = _itemOf(step);
    final ShowOutline? outline = item.sprite == null ? null : style?.art.of(item.sprite!);
    final bool solid = ShowDirector.solidMotions.contains(step.motion);
    final bool outlined = ShowDirector.motions.contains(step.motion) && outline != null;
    if (style == null || fast || !_canDraw || !(solid || outlined)) {
      return _hostMove(item, fast: fast, rests: step.motion != null);
    }
    final ShowDirector director = ShowDirector(this, style, showMarks);
    final Offset tile = _trayTip(item);
    final double side = _spotSide;
    showMarks.scale = hintScale(_size);
    final Rect spot = Rect.fromCenter(center: _size.center(Offset.zero), width: side, height: side);
    final int binAt = activity.bins.indexWhere((SortBin b) => b.id == item.bin);
    final Rect into = Rect.fromCenter(center: _board!.dropPlace(binAt), width: 40, height: 40);
    _lifted = item.id;
    hintItem = null;
    notify();
    await director.lift(
      from: Rect.fromCenter(center: tile + const Offset(0, 36), width: 44, height: 44),
      spot: spot,
      svg: activity.assets.svg(item.sprite!),
    );
    SolidEnd? end;
    if (solid) {
      end = await director.solid(
        step,
        sprite: item.sprite!,
        spot: spot,
        into: into,
        onto: Rect.fromCenter(center: _board!.sampleCentre(binAt), width: 40, height: 40),
        stage: _size,
      );
    } else {
      await director.motion(step, outline!, spot);
    }
    await director.dropTo(end?.to ?? into, carried: end?.carried ?? false, squash: end?.squash ?? false);
    placed[item.id] = item.bin!;
    _lifted = null;
    notify();
  }

  /// What hint 2 of a sort draws by the family of its line (`vo:hint.<family>.h2`, M11-stage2 section 11.4): the sticks lifting off the sides, the print
  /// in the sand, the push, the turn, the same motions of the host's hand as the Show's, done on the next picture of the tray. The picture comes back to
  /// the tray afterwards and goes to no bin: a hint shows how to look, never where to put it.
  static const Map<String, ShowStep> _familyMotions = <String, ShowStep>{
    'shp_equal': ShowStep(byHost: true, motion: 'sticks', detail: 'sides'),
    'shp_face': ShowStep(byHost: true, motion: 'stamp', detail: 'face'),
    'shp_roll': ShowStep(byHost: true, motion: 'push'),
    'shp_solid_roll': ShowStep(byHost: true, motion: 'push'),
    'shp_square_turn': ShowStep(byHost: true, motion: 'turn', detail: 'upright'),
  };

  /// Draws the picture of hint 2's family on the next picture of the tray; false when the host's art does not draw it here (a room with no hand art, a
  /// picture with no outline), and the hint then lights the bins.
  Future<bool> _familyHint() async {
    final ShowStyle? style = showStyle;
    final ShowStep? step =
        _familyMotions[hintFamilyOf(activity.hints.length > 1 ? activity.hints[1].say.vo : null)];
    final List<SortItem> left = tray;
    if (style == null || step == null || left.isEmpty || !_canDraw || hosting) return false;
    final SortItem item = left.first;
    final bool solid = ShowDirector.solidMotions.contains(step.motion);
    final ShowOutline? outline = item.sprite == null ? null : style.art.of(item.sprite!);
    if (!solid && outline == null) return false;
    if (solid && step.motion == 'stamp' && printKindOf(item.sprite!, detail: step.detail) == null) {
      return false;
    }
    hosting = true;
    final ShowDirector director = ShowDirector(this, style, showMarks);
    final Offset tile = _trayTip(item);
    final double side = _spotSide;
    showMarks.scale = hintScale(_size);
    final Rect spot = Rect.fromCenter(center: _size.center(Offset.zero), width: side, height: side);
    // the thing goes nowhere in particular: along the middle of the stage, not into a bin
    final Rect nowhere = Rect.fromCenter(
      center: _size.center(Offset.zero) + Offset(side * 0.45, 0),
      width: 40,
      height: 40,
    );
    _lifted = item.id;
    notify();
    await director.lift(
      from: Rect.fromCenter(center: tile + const Offset(0, 36), width: 44, height: 44),
      spot: spot,
      svg: activity.assets.svg(item.sprite!),
    );
    if (solid) {
      await director.solid(
        step,
        sprite: item.sprite!,
        spot: spot,
        into: nowhere,
        onto: nowhere,
        stage: _size,
      );
    } else {
      await director.motion(step, outline!, spot);
    }
    showMarks.clear();
    _lifted = null;
    hosting = false;
    notify();
    return true;
  }

  /// What the host does on this screen, if anything: a Show (it sorts every picture but the child's), or the lead of a Together item.
  @override
  void startHost() {
    final ArcStep? step = controller.step;
    if (step == null || hosting) return;
    if (activity.isShow) {
      unawaited(
        playShow(activity.show!, move: (ShowStep s, {required bool fast}) => _hostShow(s, fast: fast)),
      );
    } else if (step.part == ArcPart.together && controller.leading && step.lead > 0) {
      unawaited(
        playLead(<Future<void> Function()>[
          for (final SortItem i in activity.items.take(step.lead)) () => _hostMove(i, fast: false),
        ]),
      );
    }
  }

  /// A touch on a reminder skips what the host still has to do: its pictures go in their bins at once, and the child's step is left.
  @override
  void onScreenTouch() {
    if (!activity.isShow) return;
    skipHost(() {
      _hint.clear();
      showMarks.clear();
      _lifted = null;
      hintItem = null;
      for (final ShowStep s in activity.show!.hostSteps) {
        placed[_itemOf(s).id] = s.bin!;
      }
    });
  }

  /// The help shows the bin of the next picture in the tray.
  void _pointAt(SortItem item) {
    hintItem = item.id;
    hintBin = item.bin;
    notify();
  }

  /// How long the hand takes for one picture of a deal: half at the tray, half at the plate.
  static const int _dealStep = 900;

  /// The guide deals the pictures between the friends, one for each in turn. With [firstRoundOnly] it stops after one round and
  /// the pictures stay where they are, for the child to go on; otherwise the pointing hand takes each one from the tray to its
  /// plate, the guide deals them all and puts them back for the child's turn.
  void _dealDemo({bool firstRoundOnly = false}) {
    if (demoRunning) return;
    demoRunning = true;
    _dealFirstOnly = firstRoundOnly;
    _run++;
    final int run = _run;
    placed.clear();
    final List<SortItem> all = activity.items;
    final int count = firstRoundOnly ? math.min(all.length, activity.bins.length) : all.length;
    final int bins = activity.bins.length;
    const int tail = 1400;
    if (!firstRoundOnly && _canDraw) {
      _hint.play(
        handTourPlan(<HandStop>[
          for (int k = 0; k < count; k++) ...<HandStop>[
            HandStop(_tipAt(all.length - k, 0), _dealStep ~/ 2),
            _dropStop(k % bins, _dealStep ~/ 2),
          ],
        ], tailMs: tail),
      );
    }
    final int first = firstRoundOnly ? 300 : _dealStep ~/ 2 + 400;
    final int step = firstRoundOnly ? TemplateSession.demoStep.inMilliseconds : _dealStep;
    for (int k = 0; k < count; k++) {
      later(Duration(milliseconds: first + step * k), () {
        if (run != _run) return;
        placed[all[k].id] = activity.bins[k % bins].id;
        notify();
      });
    }
    later(Duration(milliseconds: firstRoundOnly ? first + step * count : step * count + tail), () {
      if (run != _run) return;
      if (!firstRoundOnly) placed.clear();
      demoRunning = false;
      notify();
      if (!firstRoundOnly) controller.demoDone();
    });
    notify();
  }

  /// Hint 1 and 2: the light goes to each bin in turn, and rests on none. With [withItem] the next picture of the tray is lit too:
  /// "look at this one, and at each place".
  void _lightBins({required bool withItem}) {
    _run++;
    final int run = _run;
    hintBin = null;
    hintItem = withItem && tray.isNotEmpty ? tray.first.id : null;
    const int step = 700;
    if (withItem && tray.isNotEmpty && _canDraw) {
      // P9: a copy of the next picture glides past the sample of each bin, and stops at none (the bins are compared, none is chosen).
      final double side = 34 * hintScale(_size);
      final String svg = activity.assets.svg(tray.first.sprite!);
      final int n = activity.bins.length;
      _hint.play(
        HintPlan(<HintFrame>[
          for (int i = 0; i < n; i++)
            HintFrame(<HintMark>[
              CopyMark(
                Rect.fromCenter(
                  center: _board!.sampleCentre(i) - Offset(0, side * 0.2),
                  width: side,
                  height: side,
                ),
                svg,
              ),
            ], hold: const Duration(milliseconds: step)),
        ]),
      );
    }
    for (int i = 0; i < activity.bins.length; i++) {
      later(Duration(milliseconds: step * i), () {
        if (run != _run) return;
        litBin = activity.bins[i].id;
        notify();
      });
    }
    later(Duration(milliseconds: step * activity.bins.length), () {
      if (run != _run) return;
      litBin = null;
      notify();
    });
    notify();
  }

  /// The worked example: the pointing hand takes the next picture from the tray, puts it in its bin, the guide takes it out again
  /// and leaves the picture and its bin lit. Then it is the child's turn.
  void _sortOne() {
    final List<SortItem> left = tray;
    if (demoRunning || left.isEmpty) return;
    _run++;
    litBin = null;
    final SortItem item = left.first;
    demoRunning = true;
    _demoItem = item.id;
    final int run = _run;
    hintItem = item.id;
    hintBin = null;
    const int taken = 850; // the hand is at the picture
    const int put = 1250; // and in the bin
    const int over = 3000;
    if (_canDraw) {
      _hint.play(
        handTourPlan(<HandStop>[
          HandStop(_trayTip(item), taken),
          _dropStop(activity.bins.indexWhere((SortBin b) => b.id == item.bin), over - taken),
        ]),
      );
    }
    later(const Duration(milliseconds: put), () {
      if (run != _run) return;
      placed[item.id] = item.bin!;
      notify();
    });
    later(const Duration(milliseconds: over), () {
      if (run != _run) return;
      placed.remove(item.id);
      _demoItem = null;
      hintBin = item.bin;
      demoRunning = false;
      notify();
      controller.demoDone();
    });
    notify();
  }

  @override
  void onReset() {
    _hint.clear();
    _demoItem = null;
    placed.clear();
    // The pictures the host sorted in the lead of a Together item stay sorted.
    final int lead = controller.step?.part == ArcPart.together && !controller.leading
        ? controller.step!.lead
        : 0;
    for (final SortItem i in activity.items.take(lead)) {
      placed[i.id] = _binOf(i);
    }
    selected = null;
    hintItem = null;
    hintBin = null;
    litBin = null;
    _run++;
    notYetBin = null;
    ring = AnswerState.idle;
    _busy = false;
    demoRunning = false;
    notify();
  }

  @override
  void onReplay() {
    _hint.clear();
    hintBin = null;
    litBin = null;
    _run++;
    notify();
  }

  @override
  void onHint() {
    if (_busy && !controller.guided) return;
    switch (hintPictureOf(activity, share: activity.share)) {
      case HintPicture.eachPlace:
        _lightBins(withItem: false);
      case HintPicture.nextPicture:
        // the picture of hint 2's family when the host's art draws it (sticks, print, push, turn), else the light of the bins
        unawaited(
          _familyHint().then((bool drawn) {
            if (!drawn && !disposed) _lightBins(withItem: true);
          }),
        );
      case HintPicture.firstRound:
        _dealDemo(firstRoundOnly: true);
      default:
        activity.share ? _dealDemo() : _sortOne();
    }
  }

  // ---- drawing ----

  @override
  Widget buildStage(BuildContext context, Size size, ActivitySpec spec) {
    _size = size;
    _spec = spec;
    final SortKind kind = SortKind.of(spec);
    final TextScaler system = ActivityFrame.bubbleScaler(context);
    final (SortKind, Size, double) key = (kind, size, system.scale(1));
    if (_boardKey != key) {
      _boardKey = key;
      _labelScale = SortBoard.scaleFor(
        kind: kind,
        stage: size,
        labels: _labels,
        marks: _marks,
        wide: wide,
        wanted: system.scale(1),
        bigMark: _bigMark,
      );
      _board = _boardFor(kind, size, _labelScale);
    }
    return ListenableBuilder(
      listenable: this,
      builder: (BuildContext c, Widget? _) => _SortStage(this, _board!),
    );
  }

  @override
  Widget? buildHands(BuildContext context, Size size, ActivitySpec spec) => _hint.hands(size, spec);

  @override
  Widget? buildTiles(BuildContext context, ActivitySpec spec) => ListenableBuilder(
    listenable: this,
    builder: (BuildContext c, Widget? _) {
      final SortTray plan = _trayOf(spec, SortKind.of(spec));
      final List<SortItem> left = tray;
      if (left.isEmpty) return const SizedBox(key: Key('sort-tray'));
      if (plan.deck) return _deck(plan, _deckOrder(left));
      return Wrap(
        key: const Key('sort-tray'),
        alignment: WrapAlignment.center,
        spacing: plan.spacing,
        runSpacing: plan.runSpacing,
        children: <Widget>[for (final SortItem i in left) _draggable(i, plan)],
      );
    },
  );

  /// A phone's tray: the top card as a wide answer tile, and under it the edges of the cards that wait (at most two), so that the child sorts one
  /// card at a time.
  Widget _deck(SortTray plan, List<SortItem> order) {
    final int edges = math.min(2, order.length - 1);
    return SizedBox(
      key: const Key('sort-tray'),
      height: plan.tile.height + 8 + SortTray.deckEdges,
      child: Stack(
        clipBehavior: Clip.none,
        children: <Widget>[
          for (int e = edges; e >= 1; e--)
            Positioned(
              left: 0,
              right: 0,
              top: 4.0 + 6 * e,
              height: plan.tile.height,
              child: Center(
                child: Opacity(
                  opacity: e == 1 ? 0.9 : 0.7,
                  child: Container(
                    width: plan.tile.width - 8.0 * e,
                    decoration: BoxDecoration(
                      color: TokenColors.paper,
                      borderRadius: BorderRadius.circular(TokenRadius.xl),
                      border: Border.all(color: TokenColors.cardLip, width: 2.5),
                    ),
                  ),
                ),
              ),
            ),
          Positioned(left: 0, right: 0, top: 0, child: Center(child: _draggable(order.first, plan))),
        ],
      ),
    );
  }

  /// A card of the tray that is dragged (or touched, and then the bin). Its copy under the finger is the card's size, a little lifted.
  Widget _draggable(SortItem i, SortTray plan) => Draggable<String>(
    key: Key('item-${i.id}'),
    data: i.id,
    maxSimultaneousDrags: _busy || demoRunning || hosting ? 0 : 1,
    dragAnchorStrategy: (Draggable<Object> d, BuildContext c, Offset position) =>
        Offset(plan.card.width / 2, plan.card.height / 2),
    feedback: Transform.translate(
      offset: const Offset(0, -6),
      child: Transform.scale(
        scale: 1.04,
        child: SizedBox(
          width: plan.card.width,
          height: plan.card.height,
          child: Opacity(opacity: 0.9, child: PackSvg(activity.assets.svg(i.sprite!))),
        ),
      ),
    ),
    childWhenDragging: Opacity(opacity: 0.25, child: _tile(i, plan)),
    child: _tile(i, plan),
  );

  Widget _tile(SortItem i, SortTray plan) => AnswerTile(
    semanticLabel: i.id,
    size: plan.tile.height,
    width: plan.tile.width,
    slop: 4,
    state: selected == i.id || hintItem == i.id ? AnswerState.selected : AnswerState.idle,
    onPressed: () => select(i.id),
    child: SizedBox(
      key: Key('tray-card-${i.id}'),
      width: plan.card.width,
      height: plan.card.height,
      child: PackSvg(activity.assets.svg(i.sprite!)),
    ),
  );
}

class _SortStage extends StatelessWidget {
  const _SortStage(this.s, this.board);

  final SortDragSession s;
  final SortBoard board;

  @override
  Widget build(BuildContext context) {
    final SortDragActivity a = s.activity;
    return Semantics(
      container: true,
      label: a.altText,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(TokenRadius.lg),
        child: Stack(
          key: const Key('sort-stage'),
          children: <Widget>[
            if (a.background != null)
              Positioned.fill(child: PackSvg(a.assets.svg(a.background!), fit: BoxFit.cover)),
            for (final (int i, SortBin b) in a.bins.indexed)
              Positioned.fromRect(rect: board.bins[i], child: _bin(i, b)),
            if (s.showStyle != null)
              Positioned.fill(
                child: ShowLayer(marks: s.showMarks, style: s.showStyle!),
              ),
            Positioned.fill(child: s._hint.body(board.stage)),
          ],
        ),
      ),
    );
  }

  Widget _bin(int index, SortBin b) {
    final SortDragActivity a = s.activity;
    // The cards in the order they went in: the newest is last, and it is the one a shelf shows at full size.
    final List<({String id, String svg})> inside = <({String id, String svg})>[
      for (final MapEntry<String, String> e in s.placed.entries)
        if (e.value == b.id)
          (id: e.key, svg: a.assets.svg(a.items.firstWhere((SortItem i) => i.id == e.key).sprite!)),
    ];
    return DragTarget<String>(
      onWillAcceptWithDetails: (DragTargetDetails<String> d) => true,
      onAcceptWithDetails: (DragTargetDetails<String> d) => s.drop(d.data, b.id),
      builder: (BuildContext context, List<String?> candidate, List<dynamic> rejected) {
        final bool over = candidate.isNotEmpty;
        final Color? ring = s.notYetBin == b.id
            ? TokenColors.notYetRing
            : (over || s.hintBin == b.id || s.litBin == b.id ? TokenColors.hintHalo : null);
        return GestureDetector(
          key: Key('bin-${b.id}'),
          behavior: HitTestBehavior.opaque,
          onTap: () => s.tapBin(b.id),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: TokenColors.paper.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(TokenRadius.md),
              border: Border.all(color: ring ?? TokenColors.hairline, width: ring == null ? 3 : 5),
            ),
            child: SortBinBody(
              board: board,
              index: index,
              binId: b.id,
              cards: inside,
              mark: sortMark(
                board: board,
                index: index,
                svg: a.assets.svg(b.sprite!),
                tally: b.count > 1 && b.sprite == 'asset:stick_long',
                share: s.sampleBoxShares[index],
              ),
            ),
          ),
        );
      },
    );
  }
}
