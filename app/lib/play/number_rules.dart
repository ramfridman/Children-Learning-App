import '../content/models.dart';

// What a wrong number typed on the keypad shows (M10, X3): the misconception tag of a number the author expects, or of the kind of
// mistake it is by one of the item's rules (`smaller_from_larger`, `forgot_the_ten`, `added_instead`, `off_by_ten`, `face_value`). The
// rules read the number sentence of the item's row (`n:9 op:+ n:6 op:= ?`); an item with no row has only the rules that need no sentence.
// A number that no expected value and no rule names is wrong with no tag: the tutor and the engine then see an unnamed mistake.

/// The tag of the wrong number [n] in [a], or the empty string when nothing names it. Never throws, for any [n].
String numberTag(TapAnswerActivity a, int n) {
  final NumberAnswer? answer = a.numberAnswer;
  if (answer == null || n == answer.value) return '';
  final String? expected = answer.expected[n];
  if (expected != null) return expected;
  final _Sentence? s = _Sentence.of(a.row);
  for (final MapEntry<String, String> rule in answer.rules.entries) {
    if (_applies(rule.key, n, answer.value, s)) return rule.value;
  }
  return '';
}

/// A number sentence of an item's row: the numbers it gives, the sign, and whether the unknown is the result (`9 + 6 = ?`) or a part.
class _Sentence {
  const _Sentence(this.given, this.sign, this.unknownIsResult);

  final List<int> given;
  final String sign;
  final bool unknownIsResult;

  static _Sentence? of(List<String> row) {
    final int eq = row.indexOf('op:=');
    if (eq < 0) return null;
    final List<String> left = row.sublist(0, eq);
    final List<String> right = row.sublist(eq + 1);
    final bool exprLeft = left.length == 3;
    final List<String> expr = exprLeft ? left : right;
    final List<String> single = exprLeft ? right : left;
    if (expr.length != 3 || single.length != 1 || !(expr[1] == 'op:+' || expr[1] == 'op:-')) return null;
    final List<int> given = <int>[
      for (final String c in <String>[expr[0], expr[2], single.first])
        if (c.startsWith('n:')) ?int.tryParse(c.substring(2)),
    ];
    return _Sentence(given, expr[1].substring(3), single.first == '?');
  }
}

bool _applies(String rule, int n, int value, _Sentence? s) {
  switch (rule) {
    case 'off_by_ten':
      return (n - value).abs() == 10;
    case 'face_value':
      // A digit read at its face: 50 typed as 5, or the digits of 30 + 4 added up to 7.
      if (value >= 10 && value % 10 == 0 && n == value ~/ 10) return true;
      return s != null &&
          s.sign == '+' &&
          s.unknownIsResult &&
          n == s.given.fold(0, (int t, int g) => t + _digitSum(g));
    case 'added_instead':
      // The other operation done on the two numbers the sentence gives: a sum for a take away, the difference for an addition.
      if (s == null || s.given.length != 2) return false;
      return n == (s.sign == '-' ? s.given[0] + s.given[1] : (s.given[0] - s.given[1]).abs());
    case 'smaller_from_larger':
      // Each place the smaller digit from the larger one, whichever is on top: 15 - 7 as 12.
      if (s == null || s.sign != '-' || !s.unknownIsResult || s.given.length != 2) return false;
      return n == _columnwiseDifference(s.given[0], s.given[1]);
    case 'forgot_the_ten':
      // The ten that was carried (or borrowed) is left out: 9 + 6 as 5, 15 - 7 as 18.
      if (s == null || !s.unknownIsResult || s.given.length != 2) return false;
      final int x = s.given[0];
      final int y = s.given[1];
      if (s.sign == '+') return x % 10 + y % 10 >= 10 && n == value - 10;
      return x % 10 < y % 10 && n == value + 10;
    default:
      return false;
  }
}

int _digitSum(int n) {
  int sum = 0;
  for (int rest = n.abs(); rest > 0; rest ~/= 10) {
    sum += rest % 10;
  }
  return sum;
}

/// The two numbers taken place by place with the smaller digit from the larger one.
int _columnwiseDifference(int x, int y) {
  int out = 0;
  int place = 1;
  for (int a = x.abs(), b = y.abs(); a > 0 || b > 0; a ~/= 10, b ~/= 10, place *= 10) {
    out += ((a % 10) - (b % 10)).abs() * place;
  }
  return out;
}
