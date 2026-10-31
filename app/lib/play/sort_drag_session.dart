import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../child/activity_shell.dart';
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
import 'sprite_group.dart';
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

  List<SortItem> get tray => <SortItem>[
    for (final SortItem i in activity.items)
      if (!placed.containsKey(i.id)) i,
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

  /// The middle of the sample picture of a bin: the top 5/9 of what the border, the padding and the label leave.
  static Offset sampleCentre(Size size, int n, int i) {
    final Rect r = binRect(size, n, i);
    final double room = r.height - 6 - 12 - 17;
    return Offset(r.center.dx, r.top + 9 + room * 5 / 18);
  }

  /// Where the hand puts a picture into bin [i] of [n]: the lower middle, where the sorted pictures lie.
  static Offset dropPlace(Size size, int n, int i) {
    final Rect r = binRect(size, n, i);
    return Offset(r.center.dx, r.bottom - 24 * hintScale(size));
  }

  /// A tray picture's side, as the tray draws it, and the fingertip place on the top edge of the one at place [i] of [n].
  double _traySide(ActivitySpec spec) =>
      math.max(44, math.min(84, spec.tilesWidth / math.max(1, activity.items.length) - 10));

  Offset _trayTip(int n, int i) {
    final ActivitySpec spec = _spec!;
    return spec.tileTip(n, i, slot: _traySide(spec) + 8, slop: 4);
  }

  bool get _canDraw => _spec != null && !_size.isEmpty;

  void select(String itemId) {
    _endDemo();
    if (_busy || ring == AnswerState.correct) return;
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
    if (_busy || ring == AnswerState.correct || placed.containsKey(itemId)) return;
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
      tag: activity.wrongTag ?? '',
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
    await controller.submitPlacement(right: true, response: ResponseCode.sorted);
    if (disposed) return;
    ring = AnswerState.correct;
    notify();
    later(TemplateSession.praisePause, controller.next);
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
            HandStop(dropPlace(_size, bins, k % bins), _dealStep ~/ 2),
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
      final String svg = activity.assets.svg(tray.first.sprite);
      final int n = activity.bins.length;
      _hint.play(
        HintPlan(<HintFrame>[
          for (int i = 0; i < n; i++)
            HintFrame(<HintMark>[
              CopyMark(
                Rect.fromCenter(
                  center: sampleCentre(_size, n, i) - Offset(0, side * 0.2),
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
          HandStop(
            dropPlace(_size, activity.bins.length, activity.bins.indexWhere((SortBin b) => b.id == item.bin)),
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
        _lightBins(withItem: true);
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
      final double side = _traySide(spec);
      return Row(
        key: const Key('sort-tray'),
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          for (final SortItem i in left)
            Draggable<String>(
              key: Key('item-${i.id}'),
              data: i.id,
              maxSimultaneousDrags: _busy || demoRunning ? 0 : 1,
              feedback: SizedBox(
                width: side,
                height: side,
                child: Opacity(opacity: 0.9, child: PackSvg(activity.assets.svg(i.sprite))),
              ),
              childWhenDragging: Opacity(opacity: 0.25, child: _tile(i, side)),
              child: _tile(i, side),
            ),
        ],
      );
    },
  );

  Widget _tile(SortItem i, double side) => AnswerTile(
    semanticLabel: i.id,
    size: side,
    slop: 4,
    state: selected == i.id || hintItem == i.id ? AnswerState.selected : AnswerState.idle,
    onPressed: () => select(i.id),
    child: Padding(padding: const EdgeInsets.all(6), child: PackSvg(activity.assets.svg(i.sprite))),
  );
}

class _SortStage extends StatelessWidget {
  const _SortStage(this.s, this.size);

  final SortDragSession s;
  final Size size;

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
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Row(
                  children: <Widget>[
                    for (final SortBin b in a.bins)
                      Expanded(
                        child: Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: _bin(b)),
                      ),
                  ],
                ),
              ),
            ),
            Positioned.fill(child: s._hint.body(size)),
          ],
        ),
      ),
    );
  }

  Widget _bin(SortBin b) {
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
              padding: const EdgeInsets.all(6),
              child: Column(
                children: <Widget>[
                  Expanded(
                    flex: 5,
                    child: Row(
                      children: <Widget>[
                        Expanded(
                          child: SpriteGroup(
                            svg: a.assets.svg(b.sprite),
                            count: b.count,
                            arrangement: 'line',
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    b.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.fixed(size: 13, weight: 700),
                  ),
                  Expanded(
                    flex: 4,
                    child: Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 2,
                      runSpacing: 2,
                      children: <Widget>[
                        for (final SortItem i in inside)
                          SizedBox(width: 26, height: 26, child: PackSvg(a.assets.svg(i.sprite))),
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
