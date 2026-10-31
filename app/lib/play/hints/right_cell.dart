// What the cell that is wrong in a "spot the mistake" row should have been (B-40, level 3: the right one appears beside the
// mistake). The activities hold only the index of the wrong cell, so the right one is worked out from the rest of the row: a
// number sentence is solved, a row that counts on (1, 2, 3 or 10, 20, 30, or the towers 1 to 5) takes the step its neighbours show,
// and a row that repeats (a pattern, a program, or all alike but one) takes what the same place of the unit holds elsewhere. A row
// whose right cell cannot be known from the row alone (a rainbow, the steps of washing) gives null and the hint shows no card.
//
// Cells are written `asset:id`, `n:7`, `dir:up` or `op:+`; the answer is written the same way.

/// The cell that should stand at [wrong] in [cells], or null when the row does not tell.
String? rightCellOf(List<String> cells, int wrong) {
  if (wrong < 0 || wrong >= cells.length) return null;
  return _sentence(cells, wrong) ?? _counting(cells, wrong) ?? _repeating(cells, wrong);
}

/// A number sentence (`6 + 2 = 9` or `7 = 5 + 3`): the one number or sign that makes it true.
String? _sentence(List<String> cells, int wrong) {
  if (!cells.contains('op:=')) return null;
  final List<String> candidates = cells[wrong].startsWith('op:')
      ? <String>['op:+', 'op:-']
      : <String>[for (int x = 0; x <= 99; x++) 'n:$x'];
  final List<String> fits = <String>[
    for (final String c in candidates)
      if (_holds(<String>[...cells.sublist(0, wrong), c, ...cells.sublist(wrong + 1)])) c,
  ];
  return fits.length == 1 ? fits.single : null;
}

bool _holds(List<String> cells) {
  final int eq = cells.indexOf('op:=');
  final int? left = _value(cells.sublist(0, eq));
  final int? right = _value(cells.sublist(eq + 1));
  return left != null && left == right;
}

/// The value of one side of a sentence: a number, or a number, a sign and a number.
int? _value(List<String> side) {
  int? n(String c) => c.startsWith('n:') ? int.tryParse(c.substring(2)) : null;
  if (side.length == 1) return n(side[0]);
  if (side.length != 3) return null;
  final int? a = n(side[0]);
  final int? b = n(side[2]);
  if (a == null || b == null) return null;
  return switch (side[1]) {
    'op:+' => a + b,
    'op:-' => a - b,
    _ => null,
  };
}

/// A row that counts on or back by a fixed step (numbers, or pictures named by a number such as `tower_3`): the cell takes the
/// step its neighbours show, and the whole row must then run with that one step.
String? _counting(List<String> cells, int wrong) {
  if (cells.length < 3) return null;
  final RegExp ending = RegExp(r'^(.*?)(\d+)$');
  final List<RegExpMatch?> parts = <RegExpMatch?>[for (final String c in cells) ending.firstMatch(c)];
  if (parts.any((RegExpMatch? m) => m == null)) return null;
  final String prefix = parts.first!.group(1)!;
  if (parts.any((RegExpMatch? m) => m!.group(1) != prefix)) return null;
  final List<int> v = <int>[for (final RegExpMatch? m in parts) int.parse(m!.group(2)!)];
  final int n = v.length;
  final int step;
  if (wrong > 0 && wrong < n - 1) {
    final int span = v[wrong + 1] - v[wrong - 1];
    if (span.isOdd) return null;
    step = span ~/ 2;
  } else if (wrong == n - 1) {
    step = v[n - 2] - v[n - 3];
  } else {
    step = v[2] - v[1];
  }
  if (step == 0) return null;
  final int right = wrong == 0 ? v[1] - step : v[wrong - 1] + step;
  if (right < 0 || right == v[wrong]) return null;
  v[wrong] = right;
  for (int i = 1; i < n; i++) {
    if (v[i] - v[i - 1] != step) return null;
  }
  return '$prefix$right';
}

/// A row that repeats (or is all alike but one): the cell takes what the other cells at its place of the unit hold. The unit is
/// the shortest one, of at most half the row, that the rest of the row follows.
String? _repeating(List<String> cells, int wrong) {
  final int n = cells.length;
  for (int p = 1; p <= n ~/ 2; p++) {
    final Map<int, String> unit = <int, String>{};
    bool follows = true;
    for (int i = 0; i < n && follows; i++) {
      if (i == wrong) continue;
      follows = unit.putIfAbsent(i % p, () => cells[i]) == cells[i];
    }
    if (!follows) continue;
    final String? right = unit[wrong % p];
    return right == null || right == cells[wrong] ? null : right;
  }
  return null;
}
