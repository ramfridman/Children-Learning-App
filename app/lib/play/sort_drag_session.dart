import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../child/activity_shell.dart';
import '../content/arc_checks.dart' show hintFamilyOf;
import '../content/hint_ladder.dart';
import '../content/models.dart';
import '../design/app_text.dart';
import '../design/components.dart';
import '../design/tokens.g.dart';
import 'hints/hint_marks.dart';
import 'hints/hint_pictures.dart' show hintScale;
import 'hints/hint_player.dart';
import 'hints/pointer_plans.dart';
import 'hints/tile_points.dart';
import 'activity_frame.dart' show ActivityFrame;
import 'choice_row.dart' show withStageAtLeast;
import 'lesson_arc.dart' show ArcPart, ArcStep;
import 'show_solids.dart';
import 'show_stage.dart';
import 'size_scale.dart';
import 'sprite_group.dart';
import 'response_code.dart';
import 'template_session.dart';

/// The heights of the parts of a bin's inside, and the side of a picture that lies in it (see [SortDragSession.binBands]).
typedef BinBands = ({double sample, double label, double items, double itemSide, double itemWidth});

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
  (Size, double)? _labelKey;

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

  /// Where bin [i] of [n] stands in a stage of [size]: they fill it 8 in, side by side, the first at the right (the language's way).
  static Rect binRect(Size size, int n, int i) {
    final double w = (size.width - 16) / n;
    return Rect.fromLTWH(size.width - 8 - (i + 1) * w + 4, 8, w - 8, size.height - 16);
  }

  /// The room a bin leaves inside its border (3) and its margin ([_binMargin]), top to bottom: the label, the sample picture of its
  /// rule, and the pictures that lie in it (the label stands first, clear of the hand that reaches down to the tray). The pictures take what [most] of them need (one line of them, two where they are
  /// many) and the sample the rest, so it is as large as the bin lets it be: a picture of at least `TokenComponent.stagePictureMin`
  /// on a phone, though a small phone's bin leaves it a little less. The label and the pictures are smaller where the bin is low.
  ///
  /// The label's strip grows with the size its text is drawn at ([scale], the system's text size up to 1.3, see [labelScale]): the strip is
  /// 17 points for a text of 13, which is a strip of 1.3 times its font, and it keeps that proportion, so a larger text is never cut at its
  /// top (QA-1). The sample gives up what the strip takes.
  static BinBands binBands(Rect bin, int most, {double scale = 1, bool wide = false}) {
    final double inner = bin.height - 6 - 2 * _binMargin;
    final bool low = inner < 90;
    double itemSide = low ? 22 : 26;
    final double label = (low ? 15 : 17) * scale;
    // A wide picture (a pattern strip, 120 by 48) lies in the bin [wideItem] times its height wide, so that two stand side by side in a phone's bin.
    double itemWidth = wide ? itemSide * wideItem : itemSide;
    int perLine = math.max(1, ((bin.width - 6 - 2 * _binMargin + 2) / (itemWidth + 2)).floor());
    int lines = math.min(3, math.max(1, (most / perLine).ceil()));
    if (wide && lines * (itemSide + 2) > inner - label) {
      // The wider cards take more lines than the room under the label has (a small phone at a large text size): they are drawn smaller (not under
      // 16 high) rather than spilling out of the bin.
      itemSide = math.max(16, (inner - label) / lines - 2);
      itemWidth = itemSide * wideItem;
      perLine = math.max(1, ((bin.width - 6 - 2 * _binMargin + 2) / (itemWidth + 2)).floor());
      lines = math.min(3, math.max(1, (most / perLine).ceil()));
    }
    final double items = lines * (itemSide + 2);
    return (
      sample: math.max(0, inner - label - items),
      label: label,
      items: items,
      itemSide: itemSide,
      itemWidth: itemWidth,
    );
  }

  static const double _binMargin = 4;

  /// How many times its height a wide picture is drawn wide where it lies sorted in a bin.
  static const double wideItem = 2.5;

  /// The most pictures any bin takes: those that belong in it, or an equal share of them where any bin takes any picture.
  int get mostPerBin => activity.share
      ? (activity.items.length / math.max(1, activity.bins.length)).ceil()
      : activity.bins.fold(
          1,
          (int m, SortBin b) => math.max(m, activity.items.where((SortItem i) => i.bin == b.id).length),
        );

  /// The size the labels of the bins are drawn at, as a multiple of their own size: the system's text size (at most [ActivityFrame.maxTextScale]),
  /// less where the longest of [labels] would not fit one line of a bin, but never under 1 (the label's own size, which every bin of every board
  /// holds). One scale for all the bins of a stage, so that the strips stand level.
  static double labelScale(List<String> labels, Size stage, {required TextScaler system}) {
    final double wanted = system.scale(1).clamp(1.0, ActivityFrame.maxTextScale);
    if (wanted <= 1) return 1;
    final Rect bin = binRect(stage, labels.length, 0);
    final double width = bin.width - 6 - 2 * _binMargin;
    final double font = binBands(bin, 1).label - 4;
    double scale = wanted;
    for (; scale > 1; scale -= 0.05) {
      if (labels.every((String l) => _labelWidth(l, font, scale) <= width)) return scale;
    }
    return 1;
  }

  static double _labelWidth(String label, double font, double scale) {
    final TextPainter p = TextPainter(
      text: TextSpan(text: label, style: _labelStyle(font)),
      textDirection: TextDirection.rtl,
      textScaler: TextScaler.linear(scale),
      maxLines: 1,
    )..layout();
    final double width = p.width;
    p.dispose();
    return width;
  }

  static TextStyle _labelStyle(double font) => AppText.fixed(size: font, weight: 700);

  /// The middle of the sample picture of bin [i] of [n] (a bin that takes [most] pictures), with the labels drawn at [scale].
  static Offset sampleCentre(Size size, int n, int i, {int most = 1, double scale = 1, bool wide = false}) {
    final Rect r = binRect(size, n, i);
    final BinBands band = binBands(r, most, scale: scale, wide: wide);
    return Offset(r.center.dx, r.top + 3 + _binMargin + band.label + band.sample / 2);
  }

  /// Where the hand puts a picture into bin [i] of [n]: the foot of the bin, in the band where the sorted pictures lie. The hand's
  /// body lies under its fingertip and its finger reaches a little over it (about a quarter of the hand's height), so the tip is as
  /// low as the band lets it be.
  static Offset dropPlace(Size size, int n, int i) {
    final Rect r = binRect(size, n, i);
    return Offset(r.center.dx, r.bottom - 3 - _binMargin - 4);
  }

  /// The stop of the hand at the drop place of bin [i] of [n]. The hand comes from below, so that its body lies under the fingertip
  /// and never covers the bin's label, which stands above the place.
  HandStop _dropStop(int n, int i, int ms) => HandStop(dropPlace(_size, n, i), ms, from: HandFrom.below);

  /// A tray picture's side, as the tray draws it, and the fingertip place on the top edge of the one at place [i] of [n].
  double _traySide(ActivitySpec spec) =>
      math.max(44, math.min(84, spec.tilesWidth / math.max(1, activity.items.length) - 10));

  /// The cards are wide pictures (a pattern strip, whose viewBox is not square): the tile stays 84 tall (the touch target does not change) and is
  /// wider, so that the animals of a strip can be told apart; and in a bin a card is drawn [SortDragSession.wideItem] times its height wide.
  late final bool wide = activity.items.any((SortItem i) {
    final double? aspect = i.sprite == null ? null : viewBoxAspect(activity.assets.svg(i.sprite!));
    return aspect != null && aspect > 1.3;
  });

  /// The tray tile's height and width: the square side, or for wide pictures 84 tall and `tilesWidth / n - 10` wide, between 84 and 200.
  double _trayHeight(ActivitySpec spec) => wide ? 84 : _traySide(spec);
  double _trayWidth(ActivitySpec spec) =>
      wide ? (spec.tilesWidth / math.max(1, activity.items.length) - 10).clamp(84.0, 200.0) : _traySide(spec);

  /// The width over the height of a picture's `viewBox`, or null when it has none.
  static double? viewBoxAspect(String svg) {
    final RegExpMatch? m = RegExp(r'viewBox="\s*[-\d.]+[ ,]+[-\d.]+[ ,]+([\d.]+)[ ,]+([\d.]+)')
        .firstMatch(svg);
    if (m == null) return null;
    final double w = double.parse(m.group(1)!), h = double.parse(m.group(2)!);
    return h == 0 ? null : w / h;
  }

  Offset _trayTip(int n, int i) {
    final ActivitySpec spec = _spec!;
    return spec.tileTip(n, i, slot: _trayWidth(spec) + 8, slop: 4);
  }

  /// How much of its room the sample picture of each bin takes (see [sampleBoxSharesOf]): the small sample of a size rule is drawn larger
  /// than its sprite's own third, so that it is not a dot beside the big one.
  late final List<double> sampleBoxShares = sampleBoxSharesOf(<double>[
    for (final SortBin b in activity.bins) sizeShareOf(activity.assets.svg(b.sprite!)),
  ]);

  bool get _canDraw => _spec != null && !_size.isEmpty;

  /// A small phone's stage is as tall as a phone's, so that the sample picture of a bin is at least what its label and the pictures
  /// that lie in the bin leave on a phone (see [binBands]); the tray stands lower by what it takes.
  @override
  ActivitySpec layoutFor(ActivitySpec base) =>
      withStageAtLeast(base, ActivitySpec.phone.stage.height, tilesBox: _trayHeight(base) + 8);

  /// The tray's tiles have a tap margin of 4 and the row starts `tileSlop` above the tiles' place, so the drawn tiles stand 12 or 8 above it.
  @override
  double tilesRise(ActivitySpec spec) => spec.tileSlop - 4;

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
    final List<SortItem> left = tray;
    final String bin = _binOf(item);
    hintItem = item.id;
    notify();
    if (_canDraw && !stillHost) {
      _hint.play(
        handTourPlan(<HandStop>[
          HandStop(_trayTip(left.length, left.indexWhere((SortItem i) => i.id == item.id)), taken + rest),
          _dropStop(activity.bins.length, activity.bins.indexWhere((SortBin b) => b.id == bin), over - taken),
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
    final List<SortItem> left = tray;
    final Offset tile = _trayTip(left.length, left.indexWhere((SortItem i) => i.id == item.id));
    final double side = ShowDirector.spotSide(_size);
    showMarks.scale = hintScale(_size);
    final Rect spot = Rect.fromCenter(center: _size.center(Offset.zero), width: side, height: side);
    final int bins = activity.bins.length;
    final int binAt = activity.bins.indexWhere((SortBin b) => b.id == item.bin);
    final Rect into = Rect.fromCenter(center: binRect(_size, bins, binAt).center, width: 40, height: 40);
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
        onto: Rect.fromCenter(
          center: sampleCentre(_size, bins, binAt, most: mostPerBin, scale: _labelScale, wide: wide),
          width: 40,
          height: 40,
        ),
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
    final Offset tile = _trayTip(left.length, 0);
    final double side = ShowDirector.spotSide(_size);
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
            HandStop(_trayTip(all.length - k, 0), _dealStep ~/ 2),
            _dropStop(bins, k % bins, _dealStep ~/ 2),
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
                  center:
                      sampleCentre(_size, n, i, most: mostPerBin, scale: _labelScale, wide: wide) -
                      Offset(0, side * 0.2),
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
          HandStop(_trayTip(left.length, 0), taken),
          _dropStop(
            activity.bins.length,
            activity.bins.indexWhere((SortBin b) => b.id == item.bin),
            over - taken,
          ),
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
    final TextScaler system = ActivityFrame.bubbleScaler(context);
    final (Size, double) key = (size, system.scale(1));
    if (_labelKey != key) {
      _labelKey = key;
      _labelScale = labelScale(
        <String>[for (final SortBin b in activity.bins) b.label],
        size,
        system: system,
      );
    }
    return ListenableBuilder(
      listenable: this,
      builder: (BuildContext c, Widget? _) => _SortStage(this, size),
    );
  }

  @override
  Widget? buildHands(BuildContext context, Size size, ActivitySpec spec) => _hint.hands(size, spec);

  @override
  Widget? buildTiles(BuildContext context, ActivitySpec spec) => ListenableBuilder(
    listenable: this,
    builder: (BuildContext c, Widget? _) {
      final List<SortItem> left = tray;
      final double side = _trayHeight(spec);
      final double across = _trayWidth(spec);
      return Row(
        key: const Key('sort-tray'),
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          for (final SortItem i in left)
            Draggable<String>(
              key: Key('item-${i.id}'),
              data: i.id,
              maxSimultaneousDrags: _busy || demoRunning || hosting ? 0 : 1,
              feedback: SizedBox(
                width: across,
                height: side,
                child: Opacity(opacity: 0.9, child: PackSvg(activity.assets.svg(i.sprite!))),
              ),
              childWhenDragging: Opacity(opacity: 0.25, child: _tile(i, side, across)),
              child: _tile(i, side, across),
            ),
        ],
      );
    },
  );

  Widget _tile(SortItem i, double side, double across) => AnswerTile(
    semanticLabel: i.id,
    size: side,
    width: wide ? across : null,
    slop: 4,
    state: selected == i.id || hintItem == i.id ? AnswerState.selected : AnswerState.idle,
    onPressed: () => select(i.id),
    child: Padding(padding: EdgeInsets.all(wide ? 3 : 6), child: PackSvg(activity.assets.svg(i.sprite!))),
  );
}

/// The largest a bin's sample picture is drawn (a tablet's bin has room for more; the answer tile's side is the measure).
const double _sampleMax = 96;

class _SortStage extends StatelessWidget {
  const _SortStage(this.s, this.size);

  final SortDragSession s;
  final Size size;

  @override
  Widget build(BuildContext context) {
    final SortDragActivity a = s.activity;
    final BinBands band = SortDragSession.binBands(
      SortDragSession.binRect(size, a.bins.length, 0),
      s.mostPerBin,
      scale: s._labelScale,
      wide: s.wide,
    );
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
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Row(
                  children: <Widget>[
                    for (final (int i, SortBin b) in a.bins.indexed)
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: _bin(b, band, s.sampleBoxShares[i]),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            if (s.showStyle != null)
              Positioned.fill(
                child: ShowLayer(marks: s.showMarks, style: s.showStyle!),
              ),
            Positioned.fill(child: s._hint.body(size)),
          ],
        ),
      ),
    );
  }

  Widget _bin(SortBin b, BinBands band, double boxShare) {
    final SortDragActivity a = s.activity;
    final List<SortItem> inside = <SortItem>[
      for (final SortItem i in a.items)
        if (s.placed[i.id] == b.id) i,
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
              color: TokenColors.paper.withValues(alpha: 0.88),
              borderRadius: BorderRadius.circular(TokenRadius.lg),
              border: Border.all(color: ring ?? TokenColors.hairline, width: ring == null ? 3 : 5),
            ),
            child: Padding(
              padding: const EdgeInsets.all(SortDragSession._binMargin),
              child: Column(
                children: <Widget>[
                  SizedBox(
                    key: Key('bin-strip-${b.id}'),
                    height: band.label,
                    child: Text(
                      b.label,
                      key: Key('bin-label-${b.id}'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textScaler: TextScaler.linear(s._labelScale),
                      style: SortDragSession._labelStyle(band.label / s._labelScale - 4),
                    ),
                  ),
                  SizedBox(
                    height: band.sample,
                    width: double.infinity,
                    // The rule's picture fills its band (one of it as large as the band, a few of them in a line, each no larger than
                    // its place), so the picture is read at a glance.
                    child: b.count == 1
                        ? Center(
                            child: SizedBox.square(
                              key: const Key('bin-sample'),
                              dimension: math.min(band.sample, _sampleMax) * boxShare,
                              child: PackSvg(a.assets.svg(b.sprite!)),
                            ),
                          )
                        : b.sprite == 'asset:stick_long'
                        // Sticks that count the sides of a shape stand side by side as a tally, "this many sides"; a flat dash each, in a row,
                        // read as a ruler, and a row laid out as the shape would match it instead of counting it (docs/design/m11-rooms.md 13.2).
                        ? Center(
                            child: CustomPaint(
                              key: const Key('bin-tally'),
                              size: _TallyPainter.sizeOf(b.count, band.sample, size),
                              painter: _TallyPainter(b.count, _TallyPainter.stickWidthOf(size)),
                            ),
                          )
                        : SpriteGroup(
                            svg: a.assets.svg(b.sprite!),
                            count: b.count,
                            arrangement: 'line',
                            lineSlots: b.count,
                          ),
                  ),
                  SizedBox(
                    height: band.items,
                    child: Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 2,
                      runSpacing: 2,
                      children: <Widget>[
                        for (final SortItem i in inside)
                          SizedBox(
                            width: band.itemWidth,
                            height: band.itemSide,
                            child: PackSvg(a.assets.svg(i.sprite!)),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// A tally of [count] sticks standing side by side: the wood of `stick_long` (an ink edge, a grain line, a light end), each as wide as the stage
/// makes it (7 on a phone, 6 on a small one, 9 on a tablet), as tall as its band lets it be (at most 62% of a bin's body), with a gap of 0.7 of a
/// stick's width.
class _TallyPainter extends CustomPainter {
  const _TallyPainter(this.count, this.stickWidth);

  final int count;
  final double stickWidth;

  static double stickWidthOf(Size stage) => stage.width > 500 ? 9 : (stage.width < 300 ? 6 : 7);

  /// The box a tally of [count] sticks takes in a band of height [band] on [stage].
  static Size sizeOf(int count, double band, Size stage) {
    final double w = stickWidthOf(stage);
    return Size(count * w + (count - 1) * 0.7 * w, math.min(band, 0.62 * (stage.height - 16)));
  }

  @override
  void paint(Canvas canvas, Size size) {
    final double w = stickWidth;
    for (int i = 0; i < count; i++) {
      final double x = i * 1.7 * w;
      final RRect stick = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, 0, w, size.height),
        Radius.circular(w * 0.4),
      );
      canvas
        ..drawRRect(stick, Paint()..color = const Color(0xFFC98F52))
        ..drawLine(
          Offset(x + w * 0.3, size.height * 0.15),
          Offset(x + w * 0.3, size.height * 0.85),
          Paint()
            ..color = const Color(0xFF9E6A35)
            ..strokeWidth = 1.2
            ..strokeCap = StrokeCap.round,
        )
        ..drawRRect(
          stick,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.6
            ..color = TokenColors.ink,
        )
        ..drawOval(Rect.fromLTWH(x + 1, 1, w - 2, w * 0.55), Paint()..color = const Color(0xFFF2D7A6));
    }
  }

  @override
  bool shouldRepaint(covariant _TallyPainter old) => old.count != count || old.stickWidth != stickWidth;
}
