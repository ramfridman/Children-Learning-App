import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../child/activity_shell.dart';
import '../content/hint_ladder.dart';
import '../content/models.dart';
import '../content/schemas.dart' show coinSprites, coinValues;
import '../design/app_text.dart';
import '../design/components.dart';
import '../design/tokens.g.dart';
import '../strings/he.dart';
import 'hints/hint_marks.dart';
import 'hints/hint_pictures.dart' show hintScale;
import 'hints/hint_player.dart';
import 'hints/pointer_plans.dart';
import 'hints/tile_points.dart';
import 'sprite_group.dart';
import 'template_session.dart';

/// One coin or note of the purse.
class PurseCoin {
  const PurseCoin(this.id, this.kind);

  final String id;
  final String kind;
  int get value => coinValues[kind]!;
}

/// The shop template (T17): a price, and a purse of coins and notes. The child touches coins to put them on the counter (a touch on
/// a coin on the counter takes it back) and presses pay. The total on the counter is not shown: adding it up is the task.
///
/// Exactly the price is right. Anything else is a "not yet"; if the number of coins equals the price in shekels (three coins for
/// three shekels) the mistake carries the counting misconception, M-MONEY-COUNT. After three mistakes the guide puts the coins of a
/// way to pay (the fewest coins) on the counter one by one, takes them back and leaves them lit, and only paying exactly is taken.
class ShopPaySession extends TemplateSession {
  ShopPaySession(super.controller, this.activity) {
    int n = 0;
    for (final PurseItem p in activity.purse) {
      for (int k = 0; k < p.count; k++) {
        purse.add(PurseCoin('c${n++}', p.kind));
      }
    }
  }

  final ShopPayActivity activity;
  final List<PurseCoin> purse = <PurseCoin>[];
  final List<String> onCounter = <String>[];
  Set<String> hinted = <String>{};

  /// Hint 1 lights the price and the counter; the running total is shown only while the guide pays (the worked example).
  bool lightPrice = false;
  bool demoRunning = false;
  int? demoTotal;
  int _run = 0;
  AnswerState ring = AnswerState.idle;
  bool _busy = false;

  /// The places for the coins (one for each shekel of the price), the pointing hand, and the places of the stage and the tiles they
  /// are drawn by (see [HintPlayer]).
  late final HintPlayer _hint = HintPlayer(this);
  Size _size = Size.zero;
  ActivitySpec _spec = ActivitySpec.phone;

  /// The counter shows its places, not the coins on it, while a hint draws them.
  bool get placesShown => _hint.marks.any((HintMark m) => m is PlaceMark);

  /// How many shekels the price is: the number of places. Nothing is drawn for a price with agorot.
  int get _shekels => activity.price % 100 == 0 ? activity.price ~/ 100 : 0;

  int get total =>
      onCounter.fold(0, (int sum, String id) => sum + purse.firstWhere((PurseCoin c) => c.id == id).value);

  String kindOf(String id) => purse.firstWhere((PurseCoin c) => c.id == id).kind;

  /// A touch of the child ends the guide's demonstration at once (the coins come back) and the child's move is taken.
  void _endDemo() {
    if (!demoRunning) return;
    _run++;
    _hint.clear();
    onCounter.clear();
    demoTotal = null;
    demoRunning = false;
    controller.demoDone();
  }

  void toggle(String id) {
    _endDemo();
    _hint.clear();
    if (_busy || ring == AnswerState.correct) return;
    if (onCounter.contains(id)) {
      onCounter.remove(id);
    } else {
      onCounter.add(id);
    }
    hinted = <String>{};
    lightPrice = false;
    notify();
  }

  Future<void> pay() async {
    _endDemo();
    _hint.clear();
    if (_busy || ring == AnswerState.correct || onCounter.isEmpty) return;
    final bool right = total == activity.price;
    if (controller.guided && !right) {
      if (controller.answerShown) _showWay();
      return;
    }
    _busy = true;
    String tag = '';
    if (!right) {
      final bool countedCoins = onCounter.length * 100 == activity.price;
      tag = (countedCoins && activity.countTag != null) ? activity.countTag! : (activity.wrongTag ?? '');
    }
    await controller.submitPlacement(right: right, tag: tag, response: '$total');
    if (disposed) return;
    if (right) {
      ring = AnswerState.correct;
      notify();
      later(TemplateSession.praisePause, controller.next);
      return;
    }
    ring = AnswerState.notYet;
    notify();
    later(TemplateSession.notYetPause, () {
      onCounter.clear();
      ring = AnswerState.idle;
      _busy = false;
      if (controller.answerShown) _showWay();
      notify();
    });
  }

  /// The coins of a way to pay with the fewest coins.
  Set<String> solution() {
    final Map<int, List<String>> best = <int, List<String>>{0: <String>[]};
    for (final PurseCoin c in purse) {
      for (final MapEntry<int, List<String>> e in List<MapEntry<int, List<String>>>.of(best.entries)) {
        final int sum = e.key + c.value;
        if (sum > activity.price) continue;
        final List<String>? old = best[sum];
        if (old == null || old.length > e.value.length + 1) best[sum] = <String>[...e.value, c.id];
      }
    }
    return (best[activity.price] ?? <String>[]).toSet();
  }

  void _showWay() {
    hinted = solution();
    notify();
  }

  /// The coins of the way, the biggest first.
  List<PurseCoin> _wayCoins() {
    final Set<String> ids = solution();
    return <PurseCoin>[
      for (final PurseCoin c in purse)
        if (ids.contains(c.id)) c,
    ]..sort((PurseCoin a, PurseCoin b) => b.value.compareTo(a.value));
  }

  @override
  void onReset() {
    _run++;
    _hint.clear();
    onCounter.clear();
    hinted = <String>{};
    lightPrice = false;
    demoRunning = false;
    demoTotal = null;
    ring = AnswerState.idle;
    _busy = false;
    notify();
  }

  @override
  void onReplay() {
    _run++;
    _hint.clear();
    hinted = <String>{};
    lightPrice = false;
    notify();
  }

  @override
  void onHint() {
    if (_busy || demoRunning) return;
    switch (hintPictureOf(activity)) {
      case HintPicture.priceAndCounter:
        hinted = <String>{};
        lightPrice = true;
        _hint.play(HintPlan(const <HintFrame>[], rest: _places(total ~/ 100)));
        notify();
      case HintPicture.firstCoin:
        _putFirstCoin();
      default:
        _workedExample();
    }
  }

  // ---- the places of the counter and the coins of the purse, as they are drawn ----

  /// The counter's box in the stage (the same numbers the stage draws with).
  static Rect counterOf(Size size) =>
      Rect.fromLTWH(size.width - 10 - size.width * 0.54, 8, size.width * 0.54, size.height - 16);

  /// The places for [n] coins on a counter, in rows of five from the left (never mirrored), the first row at the top; a place is a
  /// circle of at most 30 on a phone.
  static List<Rect> placesOf(Size size, int n) {
    final Rect inner = counterOf(size).deflate(10);
    final int rows = (n + 4) ~/ 5;
    final double d = math.max(
      0,
      math.min(math.min(inner.width / 5 - 4, inner.height / math.max(1, rows) - 4), 30 * hintScale(size)),
    );
    final double left = inner.center.dx - (math.min(n, 5) * (d + 4) - 4) / 2;
    return <Rect>[
      for (int i = 0; i < n; i++)
        Rect.fromLTWH(left + (i % 5) * (d + 4), inner.top + (i ~/ 5) * (d + 4), d, d),
    ];
  }

  /// A place for each shekel of the price, the first [filled] of them gold.
  List<HintMark> _places(int filled) {
    final List<Rect> at = placesOf(_size, _shekels);
    return <HintMark>[for (int i = 0; i < at.length; i++) PlaceMark(at[i], filled: i < filled)];
  }

  /// The fingertip place on coin [i] of a purse that holds [kinds], and on the pay button: 4 and 8 inside their bottom edges. The
  /// hand comes from below, so that its body never covers the counter's total, its places or the price.
  Offset _coinTip(List<String> kinds, int i) {
    final Rect face = PurseLayout(kinds, _spec.tilesWidth).faces[i];
    return _spec.fromTiles(face.center.dx, face.bottom - 4);
  }

  Offset _payTip(List<String> kinds) {
    final Rect pay = PurseLayout(kinds, _spec.tilesWidth).pay;
    return _spec.fromTiles(pay.center.dx, pay.bottom - 8);
  }

  /// The kinds of the coins that are in the purse now (not on the counter), in the order of the purse.
  List<String> get _purseKinds => <String>[
    for (final PurseCoin c in purse)
      if (!onCounter.contains(c.id)) c.kind,
  ];

  /// Hint 2: the guide puts the biggest coin of a way to pay on the counter and stops; its places turn gold, the rest stay empty.
  /// When one coin pays everything that coin would be the answer, so then the guide leaves the purse as it is and only the empty
  /// places stay.
  void _putFirstCoin() {
    hinted = <String>{};
    lightPrice = true;
    final List<PurseCoin> way = _wayCoins();
    final int before = total ~/ 100;
    if (way.length > 1 && !onCounter.contains(way.first.id)) onCounter.add(way.first.id);
    _hint.play(
      HintPlan(<HintFrame>[
        HintFrame(_places(before), hold: const Duration(milliseconds: 600)),
      ], rest: _places(total ~/ 100)),
    );
    notify();
  }

  /// The worked example: the pointing hand takes the coins of a way to pay from the purse one by one (the biggest first) and each
  /// fills its places on the counter, with the running total; the hand ends on the pay button. Then the coins come back and stay
  /// lit, and it is the child's turn.
  void _workedExample() {
    _run++;
    final int run = _run;
    final List<PurseCoin> way = _wayCoins();
    demoRunning = true;
    lightPrice = true;
    onCounter.clear();
    hinted = <String>{};
    demoTotal = 0;
    final List<PurseCoin> inPurse = List<PurseCoin>.of(purse);
    List<String> kinds() => <String>[for (final PurseCoin c in inPurse) c.kind];
    final List<HandStop> stops = <HandStop>[];
    int sum = 0;
    for (int k = 0; k < way.length; k++) {
      final Offset tip = _coinTip(kinds(), inPurse.indexWhere((PurseCoin c) => c.id == way[k].id));
      stops.add(HandStop(tip, 600, marks: _places(sum ~/ 100), from: HandFrom.below));
      sum += way[k].value;
      final int running = sum;
      stops.add(HandStop(tip, 300, marks: _places(running ~/ 100), from: HandFrom.below));
      later(Duration(milliseconds: 900 * k + 600), () {
        if (run != _run) return;
        onCounter.add(way[k].id);
        demoTotal = running;
        notify();
      });
      inPurse.removeWhere((PurseCoin c) => c.id == way[k].id);
    }
    // The hand ends on the pay button, with every place paid.
    stops.add(HandStop(_payTip(kinds()), 1400, marks: _places(sum ~/ 100), from: HandFrom.below));
    _hint.play(
      handTourPlan(stops),
      onEnd: () {
        onCounter.clear();
        demoTotal = null;
        demoRunning = false;
        hinted = solution();
        notify();
        controller.demoDone();
      },
    );
    notify();
  }

  // ---- drawing ----

  @override
  Widget buildStage(BuildContext context, Size size, ActivitySpec spec) {
    _size = size;
    _spec = spec;
    return Stack(
      fit: StackFit.expand,
      clipBehavior: Clip.none,
      children: <Widget>[
        ListenableBuilder(listenable: this, builder: (BuildContext c, Widget? _) => _Counter(this, size)),
        _hint.body(size),
      ],
    );
  }

  /// The pointing hand over the stage. The pay button ends the row of tiles, and the row moves as coins leave the purse.
  @override
  Widget? buildHands(BuildContext context, Size size, ActivitySpec spec) => ListenableBuilder(
    listenable: this,
    builder: (BuildContext c, Widget? _) => _hint.hands(
      size,
      spec,
      rowEnd: spec.fromTiles(PurseLayout(_purseKinds, spec.tilesWidth).rowEnd, 0).dx,
    ),
  );

  @override
  Widget? buildTiles(BuildContext context, ActivitySpec spec) => ListenableBuilder(
    listenable: this,
    builder: (BuildContext c, Widget? _) => Directionality(
      textDirection: TextDirection.ltr,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Flexible(
            child: Wrap(
              key: const Key('purse'),
              alignment: WrapAlignment.center,
              spacing: 4,
              runSpacing: 4,
              children: <Widget>[
                for (final PurseCoin c in purse)
                  if (!onCounter.contains(c.id))
                    CoinFace(
                      key: Key('coin-${c.id}'),
                      kind: c.kind,
                      svg: activity.assets.svg('asset:${coinSprites[c.kind]}'),
                      hinted: hinted.contains(c.id),
                      onTap: () => toggle(c.id),
                    ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          AnswerTile(
            key: const Key('pay'),
            semanticLabel: 'pay',
            size: 72,
            state: ring == AnswerState.notYet
                ? AnswerState.notYet
                : (ring == AnswerState.correct ? AnswerState.correct : AnswerState.idle),
            onPressed: pay,
            child: const Icon(Icons.check_rounded, size: 44, color: TokenColors.ink),
          ),
        ],
      ),
    ),
  );
}

/// Where the coins of the purse and the pay button stand in the box of the tiles, in the box's own points (its top left is (0, 0)):
/// the same numbers the row of tiles is laid out with (a [Wrap] of the coins with 4 between them, 12, and the pay tile with its tap
/// margin, the whole row centred), so that the pointing hand can end on a coin or on the button.
class PurseLayout {
  PurseLayout(List<String> kinds, double boxWidth) {
    const double slot = payTile + 2 * payMargin;
    final double limit = boxWidth - payGap - slot;
    final List<List<int>> runs = <List<int>>[<int>[]];
    final List<double> widths = <double>[0];
    final List<double> heights = <double>[0];
    final List<Size> cells = <Size>[
      for (final String k in kinds) CoinFace.faceOf(k) + const Offset(2 * CoinFace.pad, 2 * CoinFace.pad),
    ];
    for (int i = 0; i < cells.length; i++) {
      if (runs.last.isNotEmpty && widths.last + spacing + cells[i].width > limit + 1e-10) {
        runs.add(<int>[]);
        widths.add(0);
        heights.add(0);
      }
      widths[widths.length - 1] += (runs.last.isEmpty ? 0 : spacing) + cells[i].width;
      heights[heights.length - 1] = math.max(heights.last, cells[i].height);
      runs.last.add(i);
    }
    final double wrapW = widths.fold(0.0, math.max);
    final double wrapH = kinds.isEmpty
        ? 0
        : heights.fold(0.0, (double a, double b) => a + b) + spacing * (runs.length - 1);
    final double start = (boxWidth - (wrapW + payGap + slot)) / 2;
    final double rowH = math.max(wrapH, slot);
    double top = (rowH - wrapH) / 2;
    faces = List<Rect>.filled(kinds.length, Rect.zero);
    for (int r = 0; r < runs.length; r++) {
      double x = start + (wrapW - widths[r]) / 2;
      for (final int i in runs[r]) {
        faces[i] = Rect.fromLTWH(
          x + CoinFace.pad,
          top + CoinFace.pad,
          cells[i].width - 2 * CoinFace.pad,
          cells[i].height - 2 * CoinFace.pad,
        );
        x += cells[i].width + spacing;
      }
      top += heights[r] + spacing;
    }
    final double slotLeft = start + wrapW + payGap;
    pay = Rect.fromLTWH(slotLeft + payMargin, (rowH - payTile) / 2, payTile, payTile);
    rowEnd = slotLeft + slot;
  }

  static const double payTile = 72;
  static const double payMargin = 12;
  static const double payGap = 12;
  static const double spacing = 4;

  /// The picture of each coin, in the order of the purse.
  late final List<Rect> faces;

  /// The pay button (without its tap margin), and the right edge of its slot, which is the end of the row.
  late final Rect pay;
  late final double rowEnd;
}

/// A coin or a note, with its value written on it.
class CoinFace extends StatelessWidget {
  const CoinFace({
    super.key,
    required this.kind,
    required this.svg,
    this.onTap,
    this.hinted = false,
    this.scale = 1,
  });

  final String kind;
  final String svg;
  final VoidCallback? onTap;
  final bool hinted;

  /// The same for every coin of a row, so that the coins keep their real sizes to each other.
  final double scale;

  static const double pad = 3;

  /// The real size of each, in millimetres (the width of a note; coins are round): the half shekel is the biggest coin and the shekel the
  /// smallest, as in a purse.
  static const Map<String, double> _mm = <String, double>{
    'a10': 22,
    'h50': 26,
    's1': 18,
    's2': 21.6,
    's5': 24,
    's10': 23,
    'n20': 129,
    'n50': 136,
    'n100': 143,
    'n200': 150,
  };

  static final Map<String, String> _label = <String, String>{
    'a10': He.coinA10Semantics.text,
    'h50': He.coinH50Semantics.text,
    's1': He.coinS1Semantics.text,
    's2': He.coinS2Semantics.text,
    's5': He.coinS5Semantics.text,
    's10': He.coinS10Semantics.text,
    'n20': He.noteN20Semantics.text,
    'n50': He.noteN50Semantics.text,
    'n100': He.noteN100Semantics.text,
    'n200': He.noteN200Semantics.text,
  };

  /// The picture's own size (a note is 71 mm high, a coin is round), without the room around it.
  static Size faceOf(String kind, {double scale = 1}) {
    final bool note = kind.startsWith('n');
    final double w = _mm[kind]! * (note ? 0.62 : 2.4) * scale;
    return Size(w, note ? w * 71 / _mm[kind]! : w);
  }

  /// The largest scale, at most [most], at which [kinds] fit in [room] in rows (as a [Wrap] without spacing lays them out).
  static double fitScale(List<String> kinds, Size room, {double most = 0.8}) {
    double k = most;
    while (k > 0.25 && _rowsHeight(kinds, room.width, k) > room.height) {
      k -= 0.05;
    }
    return k;
  }

  static double _rowsHeight(List<String> kinds, double width, double k) {
    double rowWidth = 0;
    double rowHeight = 0;
    double total = 0;
    for (final String kind in kinds) {
      final Size f = faceOf(kind, scale: k);
      final double cw = f.width + 2 * pad;
      final double ch = f.height + 2 * pad;
      // Half a point to spare, so that rounding never puts a coin on a row the count here did not expect.
      if (rowWidth > 0 && rowWidth + cw > width - 0.5) {
        total += rowHeight;
        rowWidth = 0;
        rowHeight = 0;
      }
      rowWidth += cw;
      rowHeight = math.max(rowHeight, ch);
    }
    return total + rowHeight;
  }

  @override
  Widget build(BuildContext context) {
    final bool note = kind.startsWith('n');
    final Size face = faceOf(kind, scale: scale);
    return Semantics(
      button: onTap != null,
      label: _label[kind],
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.all(pad),
          child: Container(
            width: face.width,
            height: face.height,
            decoration: hinted
                ? BoxDecoration(
                    shape: note ? BoxShape.rectangle : BoxShape.circle,
                    borderRadius: note ? BorderRadius.circular(8) : null,
                    border: Border.all(color: TokenColors.hintHalo, width: 4),
                  )
                : null,
            child: PackSvg(svg),
          ),
        ),
      ),
    );
  }
}

class _Counter extends StatelessWidget {
  const _Counter(this.s, this.size);

  final ShopPaySession s;
  final Size size;

  /// An amount in agorot, written the way a price is: whole shekels, shekels and agorot, or agorot.
  static String _money(int value) {
    final int shekels = value ~/ 100;
    final int agorot = value % 100;
    return agorot == 0
        ? '₪$shekels'
        : (shekels == 0 ? '$agorot ${He.agorot.text}' : '₪$shekels.${agorot.toString().padLeft(2, '0')}');
  }

  @override
  Widget build(BuildContext context) {
    final ShopPayActivity a = s.activity;
    final String price = _money(a.price);
    return Semantics(
      container: true,
      label: a.altText,
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(TokenRadius.lg),
          child: Stack(
            key: const Key('shop-stage'),
            children: <Widget>[
              if (a.background != null)
                Positioned.fill(child: PackSvg(a.assets.svg(a.background!), fit: BoxFit.cover)),
              Positioned(
                left: 10,
                top: 8,
                width: size.width * 0.38,
                height: size.height - 16,
                child: Column(
                  children: <Widget>[
                    Expanded(
                      child: SpriteGroup(
                        svg: a.assets.svg(a.itemSprite),
                        count: a.itemCount,
                        arrangement: 'line',
                        scale: 1.6,
                      ),
                    ),
                    Container(
                      key: const Key('price'),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                      decoration: BoxDecoration(
                        color: TokenColors.paper,
                        borderRadius: BorderRadius.circular(TokenRadius.lg),
                        border: s.lightPrice ? Border.all(color: TokenColors.hintHalo, width: 4) : null,
                      ),
                      child: Text(price, style: AppText.fixed(size: 24, weight: 800, lineHeight: 1.2)),
                    ),
                  ],
                ),
              ),
              Positioned(
                right: 10,
                top: 8,
                width: size.width * 0.54,
                height: size.height - 16,
                child: Container(
                  key: const Key('counter'),
                  decoration: BoxDecoration(
                    color: TokenColors.worldWoodLight.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(TokenRadius.lg),
                    border: Border.all(
                      color: s.ring == AnswerState.correct
                          ? TokenColors.correctGlow
                          : (s.ring == AnswerState.notYet
                                ? TokenColors.notYetRing
                                : (s.lightPrice ? TokenColors.hintHalo : TokenColors.hairline)),
                      width: 4,
                    ),
                  ),
                  padding: const EdgeInsets.all(4),
                  // However many coins are paid, all of them stay on the counter where they can be taken back (QA-4): the
                  // coins get smaller together when another row would not fit.
                  child: LayoutBuilder(
                    builder: (BuildContext c, BoxConstraints room) {
                      // While a hint draws the places of the price, the coins on the counter are those places.
                      final List<String> shown = s.placesShown ? const <String>[] : s.onCounter;
                      final List<String> kinds = <String>[for (final String id in shown) s.kindOf(id)];
                      final double k = CoinFace.fitScale(kinds, room.biggest);
                      return Wrap(
                        alignment: WrapAlignment.center,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: <Widget>[
                          for (final String id in shown)
                            CoinFace(
                              key: Key('on-$id'),
                              kind: s.kindOf(id),
                              svg: a.assets.svg('asset:${coinSprites[s.kindOf(id)]}'),
                              scale: k,
                              onTap: () => s.toggle(id),
                            ),
                        ],
                      );
                    },
                  ),
                ),
              ),
              // While the guide pays (the worked example) the running total is shown, so the child sees the amount grow.
              if (s.demoTotal != null && s.demoTotal! > 0)
                Positioned(
                  right: 18,
                  bottom: 12,
                  child: Container(
                    key: const Key('running-total'),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                    decoration: BoxDecoration(
                      color: TokenColors.paper,
                      borderRadius: BorderRadius.circular(TokenRadius.lg),
                      border: Border.all(color: TokenColors.hintHalo, width: 3),
                    ),
                    child: Text(
                      _money(s.demoTotal!),
                      style: AppText.fixed(size: 22, weight: 800, lineHeight: 1.2),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
