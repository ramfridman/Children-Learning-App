import 'schemas.dart' show coinValues;

/// The kinds of the coins of a way to pay [price] (agorot) from a purse of [kinds] (one entry for each coin, in the purse's order) with the fewest coins,
/// the biggest first; empty when the purse cannot pay it exactly. The host lays this way coin by coin in the lead of a Together item, and the number of its
/// coins is what the host can lead (arc_checks.dart V3).
List<String> fewestCoinWay(int price, List<String> kinds) {
  final Map<int, List<int>> best = <int, List<int>>{0: <int>[]};
  for (final (int i, String kind) in kinds.indexed) {
    final int value = coinValues[kind]!;
    for (final MapEntry<int, List<int>> e in List<MapEntry<int, List<int>>>.of(best.entries)) {
      final int sum = e.key + value;
      if (sum > price) continue;
      final List<int>? old = best[sum];
      if (old == null || old.length > e.value.length + 1) best[sum] = <int>[...e.value, i];
    }
  }
  final List<String> way = <String>[for (final int i in best[price] ?? const <int>[]) kinds[i]];
  way.sort((String a, String b) => coinValues[b]!.compareTo(coinValues[a]!));
  return way;
}
