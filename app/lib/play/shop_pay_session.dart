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

  int get total =>
      onCounter.fold(0, (int sum, String id) => sum + purse.firstWhere((PurseCoin c) => c.id == id).value);

  String kindOf(String id) => purse.firstWhere((PurseCoin c) => c.id == id).kind;

  /// A touch of the child ends the guide's demonstration at once (the coins come back) and the child's move is taken.
  void _endDemo() {
    if (!demoRunning) return;
    _run++;
    onCounter.clear();
    demoTotal = null;
    demoRunning = false;
    controller.demoDone();
  }

  void toggle(String id) {
    _endDemo();
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
        notify();
      case HintPicture.firstCoin:
        _putFirstCoin();
      default:
        _workedExample();
    }
  }

  /// Hint 2: the guide puts the biggest coin of a way to pay on the counter and stops. When one coin pays everything that coin
  /// would be the answer, so then the guide leaves the purse as it is and the price and counter stay lit.
  void _putFirstCoin() {
    hinted = <String>{};
    lightPrice = true;
    final List<PurseCoin> way = _wayCoins();
    if (way.length > 1 && !onCounter.contains(way.first.id)) onCounter.add(way.first.id);
    notify();
  }

  /// The worked example: the coins of a way to pay go on the counter one by one, with the running total, then come back; they stay
  /// lit. Then it is the child's turn.
  void _workedExample() {
    _run++;
    final int run = _run;
    final List<PurseCoin> way = _wayCoins();
    demoRunning = true;
    lightPrice = true;
    onCounter.clear();
    hinted = <String>{};
    demoTotal = 0;
    int sum = 0;
    for (int k = 0; k < way.length; k++) {
      sum += way[k].value;
      final int running = sum;
      later(Duration(milliseconds: 600 + 900 * k), () {
        if (run != _run) return;
        onCounter.add(way[k].id);
        demoTotal = running;
        notify();
      });
    }
    later(Duration(milliseconds: 600 + 900 * way.length + 1200), () {
      if (run != _run) return;
      onCounter.clear();
      demoTotal = null;
      demoRunning = false;
      hinted = solution();
      notify();
      controller.demoDone();
    });
    notify();
  }

  // ---- drawing ----

  @override
  Widget buildStage(BuildContext context, Size size, ActivitySpec spec) =>
      ListenableBuilder(listenable: this, builder: (BuildContext c, Widget? _) => _Counter(this, size));

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

  static const double _pad = 3;

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
      final double cw = f.width + 2 * _pad;
      final double ch = f.height + 2 * _pad;
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
          padding: const EdgeInsets.all(_pad),
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
                      final List<String> kinds = <String>[for (final String id in s.onCounter) s.kindOf(id)];
                      final double k = CoinFace.fitScale(kinds, room.biggest);
                      return Wrap(
                        alignment: WrapAlignment.center,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: <Widget>[
                          for (final String id in s.onCounter)
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
