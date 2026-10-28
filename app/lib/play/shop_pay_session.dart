import 'package:flutter/material.dart';

import '../child/activity_shell.dart';
import '../content/models.dart';
import '../content/schemas.dart' show coinSprites, coinValues;
import '../design/app_text.dart';
import '../design/components.dart';
import '../design/tokens.g.dart';
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
/// three shekels) the mistake carries the counting misconception, M-MONEY-COUNT. After three mistakes the help lights the coins of
/// a way to pay (the fewest coins), and only paying exactly is taken.
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
  AnswerState ring = AnswerState.idle;
  bool _busy = false;

  int get total =>
      onCounter.fold(0, (int sum, String id) => sum + purse.firstWhere((PurseCoin c) => c.id == id).value);

  void toggle(String id) {
    if (_busy || ring == AnswerState.correct) return;
    if (onCounter.contains(id)) {
      onCounter.remove(id);
    } else {
      onCounter.add(id);
    }
    hinted = <String>{};
    notify();
  }

  Future<void> pay() async {
    if (_busy || ring == AnswerState.correct || onCounter.isEmpty) return;
    final bool right = total == activity.price;
    if (controller.guided && !right) {
      _showWay();
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
      if (controller.guided) _showWay();
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

  @override
  void onReset() {
    onCounter.clear();
    hinted = <String>{};
    ring = AnswerState.idle;
    _busy = false;
    notify();
  }

  @override
  void onReplay() {
    hinted = <String>{};
    notify();
  }

  @override
  void onHint() {
    if (!_busy) _showWay();
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
    this.small = false,
  });

  final String kind;
  final String svg;
  final VoidCallback? onTap;
  final bool hinted;
  final bool small;

  /// The drawn size (the half shekel is the biggest of the silver coins, as in a purse; a note is wide).
  static const Map<String, double> _size = <String, double>{
    'a10': 34,
    'h50': 52,
    's1': 44,
    's2': 50,
    's5': 54,
    's10': 52,
    'n20': 74,
    'n50': 74,
  };
  static const Map<String, String> _text = <String, String>{
    'a10': '10',
    'h50': '½',
    's1': '1',
    's2': '2',
    's5': '5',
    's10': '10',
    'n20': '20',
    'n50': '50',
  };

  @override
  Widget build(BuildContext context) {
    final double k = small ? 0.8 : 1;
    final double w = _size[kind]! * k;
    final bool note = kind.startsWith('n');
    final double h = note ? w * 0.55 : w;
    return Semantics(
      button: onTap != null,
      label: _text[kind],
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.all(3),
          child: Container(
            width: w,
            height: h,
            decoration: hinted
                ? BoxDecoration(
                    shape: note ? BoxShape.rectangle : BoxShape.circle,
                    border: Border.all(color: TokenColors.hintHalo, width: 4),
                  )
                : null,
            child: Stack(
              alignment: Alignment.center,
              children: <Widget>[
                PackSvg(svg),
                Text(
                  kind == 'a10' ? '10' : _text[kind]!,
                  style: AppText.fixed(size: h * (kind == 'a10' ? 0.34 : 0.46), weight: 800, lineHeight: 1),
                ),
              ],
            ),
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

  @override
  Widget build(BuildContext context) {
    final ShopPayActivity a = s.activity;
    final int shekels = a.price ~/ 100;
    final int agorot = a.price % 100;
    final String price = agorot == 0
        ? '₪$shekels'
        : (shekels == 0 ? '$agorot אג׳' : '₪$shekels.${agorot.toString().padLeft(2, '0')}');
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
                      ),
                    ),
                    Container(
                      key: const Key('price'),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                      decoration: BoxDecoration(
                        color: TokenColors.paper,
                        borderRadius: BorderRadius.circular(TokenRadius.lg),
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
                          : (s.ring == AnswerState.notYet ? TokenColors.notYetRing : TokenColors.hairline),
                      width: 4,
                    ),
                  ),
                  padding: const EdgeInsets.all(4),
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: <Widget>[
                      for (final String id in s.onCounter)
                        CoinFace(
                          key: Key('on-$id'),
                          kind: s.purse.firstWhere((PurseCoin c) => c.id == id).kind,
                          svg: a.assets.svg(
                            'asset:${coinSprites[s.purse.firstWhere((PurseCoin c) => c.id == id).kind]}',
                          ),
                          small: true,
                          onTap: () => s.toggle(id),
                        ),
                    ],
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
