import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../child/activity_shell.dart';
import '../content/models.dart';
import '../content/scripts.dart' show isSingleLetter;
import '../design/components.dart';
import '../design/course_text.dart';
import '../design/tokens.g.dart';
import 'hints/hint_pictures.dart' show SkyRing;
import 'ls01_chips.dart';
import 'ls01_hand.dart';
import 'ls01_metrics.dart';
import 'ls01_session.dart';
import 'ls01_tiles.dart';
import 'option_faces.dart';
import 'response_code.dart';
import 'template_session.dart';

/// Sort with text, picture or sound faces (LS01, `sort_drag` 1.1; docs/design/languages-l5-ls01.md section 7.2 and 7.3).
///
/// The bins (2 or 3) stand on the stage, each with a sign (a letter, a pointed unit, a word, a picture or a sound) and, under it, the cards
/// already put there as small kept chips. The cards wait in the answer zone, as many as fit, and the rest in a pile at the row's end. A card
/// is dragged to a bin, or touched and then the bin touched. A sound card plays when it is touched, and shows its waves once it has been
/// heard. The item is checked when the last card is in a bin: the cards in a wrong bin wobble and fly back, the right ones stay.
class Ls01SortSession extends Ls01Session {
  Ls01SortSession(super.controller, SortDragActivity super.activity, {super.band, super.stress})
    : sort = activity;

  final SortDragActivity sort;

  /// Where each card is now: the item id to the bin id. A card that is not here is in the tray.
  final Map<String, String> placed = <String, String>{};

  /// The card that was touched and waits for a bin, and the sound cards that have been heard.
  String? selected;
  final Set<String> heard = <String>{};

  /// The cards in a wrong bin while their "not yet" shows.
  final Set<String> wobbling = <String>{};
  bool busy = false;
  bool done = false;

  // A hint's marks: the sign lit now, the card copy gliding over the signs, the card the hand put in its bin, the signs in their other form.
  int? litBin;
  String? ghostItem;
  int? ghostBin;
  String? demoItem;
  String? haloBin;
  bool altSigns = false;

  /// The card a hint has lifted from the tray and is sending to its bin (it stands dimmed in the tray while its copy flies).
  String? liftedItem;

  late final List<Ls01Face> faces = <Ls01Face>[
    for (final SortItem i in sort.items)
      Ls01Face(
        id: i.id,
        text: i.text == null ? null : _stress(i.text!),
        svg: i.sprite == null ? null : sort.assets.svg(i.sprite!),
        clip: i.clip,
        label: i.label,
      ),
  ];

  String _stress(String t) => stress ? t : String.fromCharCodes(t.runes.where((int r) => r != 0x0301));

  Ls01Face faceOf(String itemId) => faces[sort.items.indexWhere((SortItem i) => i.id == itemId)];

  FaceKind get _kind => sort.items.every((SortItem i) => i.text != null && isSingleLetter(i.text!))
      ? FaceKind.letter
      : FaceKind.word;

  List<SortItem> get tray => <SortItem>[
    for (final SortItem i in sort.items)
      if (!placed.containsKey(i.id)) i,
  ];

  List<SortItem> chipsOf(String bin) => <SortItem>[
    for (final MapEntry<String, String> e in placed.entries)
      if (e.value == bin) sort.items.firstWhere((SortItem i) => i.id == e.key),
  ];

  // ---- the child's moves ----

  /// A touch on a card of the tray: it is chosen (a sound card is played, and shows its waves from then on). A second touch on a card that
  /// can be seen puts it down; on a sound card it plays it again.
  void select(String itemId) {
    if (busy || done) return;
    handTip = null;
    final SortItem item = sort.items.firstWhere((SortItem i) => i.id == itemId);
    final bool sound = faceOf(itemId).soundOnly;
    if (item.clip != null && (sound || item.text == null)) {
      playClips?.call(<String>[item.clip!], replace: true);
      heard.add(itemId);
    }
    selected = selected == itemId && !sound ? null : itemId;
    notify();
  }

  /// A touch on a bin: the chosen card goes in. A touch on the speaker of a bin plays its sign and drops nothing.
  void tapBin(String binId) {
    final String? s = selected;
    if (s != null) drop(s, binId);
  }

  void playSign(SortBin bin) {
    if (bin.clip != null) playClips?.call(<String>[bin.clip!], replace: true);
  }

  void drop(String itemId, String binId) {
    if (busy || done || placed.containsKey(itemId)) return;
    final SortItem item = sort.items.firstWhere((SortItem i) => i.id == itemId);
    // After three tries only the right bin takes a card.
    if (controller.guided && item.bin != binId) return;
    handTip = null;
    placed[itemId] = binId;
    selected = null;
    notify();
    if (placed.length == sort.items.length) _check();
  }

  /// A kept chip is touched: it goes back to the tray (the child may change their mind), and a sound chip is heard. When a card is chosen and
  /// waits for a bin, the touch is on the bin that chip stands in, and the card goes in.
  void takeBack(String itemId) {
    if (busy || done) return;
    final String? chosen = selected;
    if (chosen != null) {
      drop(chosen, placed[itemId]!);
      return;
    }
    final SortItem item = sort.items.firstWhere((SortItem i) => i.id == itemId);
    if (item.clip != null && faceOf(itemId).soundOnly) playClips?.call(<String>[item.clip!], replace: true);
    placed.remove(itemId);
    notify();
  }

  Future<void> _check() async {
    busy = true;
    final List<SortItem> wrong = <SortItem>[
      for (final SortItem i in sort.items)
        if (placed[i.id] != i.bin) i,
    ];
    if (wrong.isEmpty) {
      await controller.submitPlacement(right: true, response: ResponseCode.sorted);
      if (disposed) return;
      done = true;
      notify();
      later(TemplateSession.praisePause, controller.next);
      return;
    }
    final String tag =
        wrong.map((SortItem i) => i.misconception).firstWhere((String? t) => t != null, orElse: () => null) ??
        sort.wrongTag ??
        '';
    await controller.submitPlacement(
      right: false,
      tag: tag,
      response: ResponseCode.sortCheck(<(String, List<int>)>[
        for (final SortBin b in sort.bins)
          (
            b.id,
            <int>[
              for (final (int k, SortItem i) in sort.items.indexed)
                if (placed[i.id] == b.id) k,
            ],
          ),
      ]),
    );
    if (disposed) return;
    wobbling
      ..clear()
      ..addAll(wrong.map((SortItem i) => i.id));
    notify();
    later(TemplateSession.notYetPause, () {
      for (final String w in wobbling) {
        placed.remove(w);
      }
      wobbling.clear();
      busy = false;
      notify();
    });
  }

  // ---- hints ----

  @override
  void resetState() {
    placed.clear();
    selected = null;
    wobbling.clear();
    busy = false;
    done = false;
  }

  @override
  void clearHintMarks() {
    litBin = null;
    ghostItem = null;
    ghostBin = null;
    demoItem = null;
    haloBin = null;
    altSigns = false;
    liftedItem = null;
  }

  @override
  void playHint(int level) {
    final int n = sort.bins.length;
    switch (level) {
      case 1:
        // The signs light one after the other, each sounding if it has a sound; no card is lit.
        for (int i = 0; i < n; i++) {
          step(800 * i, () {
            litBin = i;
            final String? clip = sort.bins[i].clip;
            if (clip != null) playClips?.call(<String>[clip], replace: false);
          });
        }
        step(800 * n, () => litBin = null);
      case 2:
        // Each sign in its other form (a picture beside it); and the next card is carried past the signs, none of them chosen.
        altSigns = sort.bins.any((SortBin b) => b.alt != null);
        if (tray.isNotEmpty) {
          final String next = tray.first.id;
          for (int i = 0; i < n; i++) {
            step(700 * i + 200, () {
              ghostItem = next;
              ghostBin = i;
            });
          }
          step(700 * n + 200, () {
            ghostItem = null;
            ghostBin = null;
          });
        }
      default:
        _demonstrate();
    }
  }

  /// "Watch me": the hand touches the next card in the tray, and the card then goes to its bin by itself and stays there a moment, the bin lit.
  /// The hand does not go up to the bins: held over them it would hide the sign (docs/design/languages-l5-ls01.md section 7.2).
  void _demonstrate() {
    if (tray.isEmpty) return demoOver(300);
    final SortItem item = tray.first;
    final int bin = sort.bins.indexWhere((SortBin b) => b.id == item.bin);
    final Rect from = _trayRect(0);
    step(200, () => handTip = ls01TipBelowStage(zones, from));
    step(1300, () {
      handTip = null;
      liftedItem = item.id;
      flightChild = _flyingCard(item.id);
      flightRect = from;
    });
    step(1400, () => flightRect = _chipRect(bin, item.id));
    step(2200, () {
      flightChild = null;
      flightRect = null;
      liftedItem = null;
      demoItem = item.id;
      haloBin = sort.bins[bin].id;
    });
    step(3600, () => demoItem = null);
    demoOver(3800);
  }

  /// The copy of a card that flies from the tray to its bin: the card's own look.
  Widget _flyingCard(String itemId) => DecoratedBox(
    key: const Key('sort-flight'),
    decoration: BoxDecoration(
      color: TokenColors.paper,
      borderRadius: BorderRadius.circular(TokenRadius.xl),
      border: Border.all(color: TokenColors.selectedRing, width: 4),
    ),
    child: Ls01FaceView(face: faceOf(itemId), metrics: metrics, kind: _kind),
  );

  // ---- geometry ----

  static const double _pile = 56;

  /// How many cards of the tray stand in the answer zone: as many as fit with the pile (when some wait), at least one.
  RowPlan get _plan => metrics.row(
    <String>[
      for (final Ls01Face f in faces)
        if (f.text != null) f.text!,
    ],
    _kind,
    zones.tilesWidth,
  );

  int get _shown {
    final int n = tray.length;
    final RowPlan p = _plan;
    for (int k = n; k > 1; k--) {
      if (k * p.cell + (k < n ? _pile : 0) <= zones.tilesWidth + 0.01) return k;
    }
    return math.min(1, n);
  }

  Rect _trayRect(int slot) {
    final RowPlan p = _plan;
    final int k = _shown;
    final double total = k * p.cell + (tray.length > k ? _pile : 0);
    final double start = zones.tilesLeft + (zones.tilesWidth - total) / 2;
    final double x = rowDirection == TextDirection.ltr
        ? start + slot * p.cell + p.gap / 2
        : start + total - (slot + 1) * p.cell + p.gap / 2;
    return Rect.fromLTWH(x, zones.tilesTop, p.tileWidth, p.tileHeight);
  }

  BinGeometry get _geo => BinGeometry(
    room: stageRoom,
    tablet: zones.stageIsCard,
    bins: sort.bins.length,
    bigSpeakers: BinGeometry.bigSpeakersFor(
      bandA: BinGeometry.isBandA(presentation: band, skillId: sort.skillId),
      cardTexts: <String?>[for (final SortItem i in sort.items) i.text],
    ),
  );

  /// Where bin [i] stands on the board.
  Rect _binRect(int i) {
    final int n = sort.bins.length;
    final int slot = rowDirection == TextDirection.ltr ? i : n - 1 - i;
    return _geo.binRect(slot).shift(stageOrigin);
  }

  /// The cards in bin [binId] as kept chips: the ones put there, and the one a hint's demonstration has just put there.
  List<SortItem> _chipItems(String binId) => <SortItem>[
    ...chipsOf(binId),
    if (demoItem != null && haloBin == binId) sort.items.firstWhere((SortItem i) => i.id == demoItem),
  ];

  List<double> _chipWidths(List<SortItem> items) => <double>[
    for (final SortItem i in items) keptChipWidth(metrics, faceOf(i.id).text, square: _geo.chipMax),
  ];

  ChipPlan _chipPlan(List<SortItem> items, {required bool speaker}) {
    final Size room = _geo.chipRoomFor(speaker: speaker);
    return ChipPlan.of(_chipWidths(items), width: room.width, height: room.height, maxHeight: _geo.chipMax);
  }

  /// Where the card [itemId] will stand in its bin [bin] once it is there (after the chips already there), on the board.
  Rect _chipRect(int bin, String itemId) {
    final BinGeometry g = _geo;
    final List<SortItem> items = <SortItem>[
      ...chipsOf(sort.bins[bin].id),
      sort.items.firstWhere((SortItem i) => i.id == itemId),
    ];
    final ChipPlan plan = _chipPlan(items, speaker: sort.bins[bin].clip != null);
    final double w = _chipWidths(items).last;
    final Offset off = plan.offsets.last;
    final Rect b = _binRect(bin);
    final double left = b.left + BinGeometry.chrome;
    final double top = b.top + BinGeometry.chrome + g.signHeight + BinGeometry.between;
    final double x = rowDirection == TextDirection.ltr ? left + off.dx : left + g.chipRoom.width - off.dx - w;
    return Rect.fromLTWH(x, top + off.dy, w, plan.height);
  }

  // ---- drawing ----

  @override
  Widget buildStage(BuildContext context, Size size, ActivitySpec spec) {
    seen(spec);
    return Ls01StageBuilder(
      direction: rowDirection,
      listenable: this,
      builder: (BuildContext c, Widget? _) => Semantics(
        container: true,
        label: sort.altText,
        child: Stack(
          key: const Key('sort-stage'),
          clipBehavior: Clip.none,
          children: <Widget>[
            Padding(
              padding: EdgeInsets.symmetric(horizontal: _geo.padX, vertical: _geo.padY),
              child: Row(
                textDirection: rowDirection,
                children: <Widget>[
                  for (final (int i, SortBin b) in sort.bins.indexed) ...<Widget>[
                    if (i > 0) SizedBox(width: _geo.gap),
                    Expanded(child: _bin(i, b)),
                  ],
                ],
              ),
            ),
            if (ghostItem != null && ghostBin != null) _ghost(),
          ],
        ),
      ),
    );
  }

  Widget _ghost() {
    final Rect r = _binRect(ghostBin!);
    final double side = math.min(metrics.tileHeight * 0.55, _geo.chipRoom.height);
    // It glides in the chips' room under the sign, so that it never covers a sign.
    return Positioned(
      left: r.center.dx - stageOrigin.dx - side / 2,
      top: r.top - stageOrigin.dy + BinGeometry.chrome + _geo.signHeight + BinGeometry.between,
      width: side,
      height: side,
      child: IgnorePointer(
        child: DecoratedBox(
          key: const Key('sort-ghost'),
          decoration: BoxDecoration(
            color: TokenColors.skyTint,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: TokenColors.skyDeep, width: 3),
          ),
          child: Ls01FaceView(face: faceOf(ghostItem!), metrics: metrics, kind: FaceKind.kept),
        ),
      ),
    );
  }

  Widget _bin(int index, SortBin b) {
    final BinGeometry g = _geo;
    final Ls01Metrics m = metrics;
    final List<SortItem> chips = _chipItems(b.id);
    final ChipPlan plan = _chipPlan(chips, speaker: b.clip != null);
    final List<double> widths = _chipWidths(chips);
    return DragTarget<String>(
      onWillAcceptWithDetails: (DragTargetDetails<String> d) => !busy && !done,
      onAcceptWithDetails: (DragTargetDetails<String> d) => drop(d.data, b.id),
      builder: (BuildContext c, List<String?> over, List<dynamic> rejected) => GestureDetector(
        key: Key('bin-${b.id}'),
        behavior: HitTestBehavior.opaque,
        onTap: () => tapBin(b.id),
        child: Semantics(
          button: true,
          label: b.label,
          child: Stack(
            clipBehavior: Clip.none,
            children: <Widget>[
              Container(
                padding: const EdgeInsets.all(BinGeometry.chrome - 4),
                decoration: BoxDecoration(
                  color: over.isNotEmpty ? TokenColors.skyTint : TokenColors.paper.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: TokenColors.hairline, width: 4),
                ),
                child: Column(
                  children: <Widget>[
                    // The sign, and its speaker in a place of its own at the end of the same row (or, in a narrow bin, in the end corner
                    // under it): it is never on a chip.
                    Row(
                      textDirection: rowDirection,
                      children: <Widget>[
                        Expanded(child: _sign(b, g.signHeight, m)),
                        if (b.clip != null && !g.cornerSpeaker) ...<Widget>[
                          const SizedBox(width: 4),
                          SpeakerMark(
                            key: Key('bin-speaker-${b.id}'),
                            touch: g.speakerTouch,
                            onTap: () => playSign(b),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: BinGeometry.between),
                    Expanded(
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: <Widget>[
                          for (final (int k, SortItem i) in chips.indexed)
                            PositionedDirectional(
                              start: plan.offsets[k].dx,
                              top: plan.offsets[k].dy,
                              width: widths[k],
                              height: plan.height,
                              child: _chip(c, i, plan.height, m),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (b.clip != null && g.cornerSpeaker)
                PositionedDirectional(
                  end: BinGeometry.chrome + BinGeometry.cornerMargin,
                  bottom: BinGeometry.chrome + BinGeometry.cornerMargin,
                  width: g.speakerTouch,
                  height: g.speakerTouch,
                  child: SpeakerMark(
                    key: Key('bin-speaker-${b.id}'),
                    touch: g.speakerTouch,
                    onTap: () => playSign(b),
                  ),
                ),
              if (litBin == index || haloBin == b.id)
                const Positioned.fill(
                  child: IgnorePointer(child: SkyRing(key: Key('bin-glow'), round: false, radius: 28)),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// The sign: a white pill with the clay lip, the letter or word at its reading size, a picture, or a sound button.
  Widget _sign(SortBin b, double height, Ls01Metrics m) {
    final Widget face;
    // A bin with a picture shows the picture and no text, whatever else the pack holds for it: a child who cannot read has the sign, and the
    // bin says its word on a touch (docs/languages/band-a-build.md 7.6).
    if (b.sprite != null) {
      face = Padding(padding: const EdgeInsets.all(4), child: PackSvg(sort.assets.svg(b.sprite!)));
    } else if (b.text != null) {
      final bool letter = isSingleLetter(b.text!);
      face = FittedBox(
        fit: BoxFit.scaleDown,
        child: CourseText(
          b.text!,
          course: m.course,
          size: m.size(letter ? FaceKind.letter : FaceKind.word),
          bold: letter,
          lineHeight: lineHeightFor(b.text!, hebrew: m.hebrew),
        ),
      );
    } else {
      face = const Icon(Icons.volume_up_rounded, size: 36, color: TokenColors.ink);
    }
    return Container(
      key: Key('sign-${b.id}'),
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: TokenColors.paper,
        borderRadius: BorderRadius.circular(height / 2),
        boxShadow: clayShadows(TokenColors.cardLip, soft16: true),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        textDirection: rowDirection,
        children: <Widget>[
          Flexible(child: face),
          if (altSigns && b.alt != null)
            Padding(
              padding: const EdgeInsetsDirectional.only(start: 6),
              child: SizedBox(
                width: height - 12,
                height: height - 12,
                child: PackSvg(sort.assets.svg(b.alt!)),
              ),
            ),
        ],
      ),
    );
  }

  /// A card already sorted: a small mist chip at the kept size, with its picture or its speaker. It is [height] tall, as the bin's room allows.
  Widget _chip(BuildContext context, SortItem i, double height, Ls01Metrics m) {
    final Ls01Face f = faceOf(i.id);
    final Widget inner = f.text != null
        // A bigger system text scale would grow the word out of its chip: the chip holds it at the kept size and no larger.
        ? FittedBox(
            fit: BoxFit.scaleDown,
            child: CourseText(
              f.text!,
              course: m.course,
              size: m.size(FaceKind.kept),
              lineHeight: math.min(lineHeightFor(f.text!, hebrew: m.hebrew), height / m.size(FaceKind.kept)),
            ),
          )
        : (f.svg != null
              ? PackSvg(f.svg!, width: height - 10, height: height - 10)
              : const Icon(Icons.volume_up_rounded, size: 26, color: TokenColors.ink));
    return Wobble(
      active: wobbling.contains(i.id) && !MediaQuery.disableAnimationsOf(context),
      child: GestureDetector(
        key: Key('chip-${i.id}'),
        behavior: HitTestBehavior.opaque,
        onTap: () => takeBack(i.id),
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: TokenColors.mist,
            borderRadius: BorderRadius.circular(14),
            border: wobbling.contains(i.id) ? Border.all(color: TokenColors.notYetRing, width: 3) : null,
          ),
          child: inner,
        ),
      ),
    );
  }

  @override
  Widget? buildTiles(BuildContext context, ActivitySpec spec) {
    seen(spec);
    return ListenableBuilder(
      listenable: this,
      builder: (BuildContext c, Widget? _) {
        final List<SortItem> left = tray;
        final int shown = _shown;
        final RowPlan p = _plan;
        final List<SortItem> visible = left.take(shown).toList();
        final Ls01Metrics m = metrics;
        return Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            textDirection: rowDirection,
            children: <Widget>[
              Ls01Row(
                key: const Key('sort-tray'),
                faces: <Ls01Face>[for (final SortItem i in visible) faceOf(i.id)],
                looks: <Ls01Look>[
                  for (final SortItem i in visible)
                    Ls01Look(
                      state: selected == i.id ? AnswerState.selected : AnswerState.idle,
                      heard: heard.contains(i.id),
                    ),
                ],
                metrics: m,
                direction: rowDirection,
                kind: _kind,
                zoneWidth: spec.tilesWidth,
                plan: p,
                intrinsic: true,
                onTap: (int k) => select(visible[k].id),
                decorate: (int k, Widget tile) => Draggable<String>(
                  key: Key('card-${visible[k].id}'),
                  data: visible[k].id,
                  maxSimultaneousDrags: busy || done ? 0 : 1,
                  onDragStarted: () => select(visible[k].id),
                  feedback: SizedBox(
                    width: p.tileWidth,
                    height: p.tileHeight,
                    child: Opacity(
                      opacity: 0.9,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: TokenColors.paper,
                          borderRadius: BorderRadius.circular(TokenRadius.xl),
                          border: Border.all(color: TokenColors.selectedRing, width: 4),
                        ),
                        child: Ls01FaceView(face: faceOf(visible[k].id), metrics: m, kind: _kind),
                      ),
                    ),
                  ),
                  childWhenDragging: Opacity(opacity: 0.25, child: tile),
                  child: liftedItem == visible[k].id ? Opacity(opacity: 0.25, child: tile) : tile,
                ),
              ),
              if (left.length > visible.length)
                SizedBox(
                  key: const Key('sort-pile'),
                  width: _pile,
                  height: p.tileHeight,
                  child: const _Pile(),
                ),
            ],
          ),
        );
      },
    );
  }
}

/// The pile of cards still waiting, at the end of the row: two card edges, not a target.
class _Pile extends StatelessWidget {
  const _Pile();

  @override
  Widget build(BuildContext context) => Center(
    child: SizedBox(
      width: 36,
      height: 52,
      child: Stack(
        children: <Widget>[
          for (final double off in <double>[0, 6])
            Positioned(
              left: off,
              top: off,
              right: 6 - off,
              bottom: 6 - off,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: TokenColors.paper,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: TokenColors.hairline, width: 3),
                ),
              ),
            ),
        ],
      ),
    ),
  );
}
