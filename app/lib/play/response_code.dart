/// What a template writes in `attempt.response`: a short fixed code made of ids and numbers, never a picture name and never
/// text. The code is synced (`sync-push`) and, after a mistake, told to the helper (`tutor-turn`), so it must fit both servers.
///
/// The codes, one place for all of them (an id is the activity's own: an option `o2`, an item `i1`, a bin `b2`, a place `s1`):
///
/// | Template | Right | Wrong |
/// |---|---|---|
/// | count_tap, tap_answer, flash | the option id, `o2` | the option id, `o3` |
/// | give_n | `n=4` (how many were given) | `n=6` |
/// | sort_drag (sort) | `sorted` | the item and the bin it was put in, `i1-b2` |
/// | sort_drag (share) | `sorted` | how many each friend got, `b1=3.b2=1` |
/// | build_pattern | the palette index of each place, `0101` | the same, `0110` |
/// | robot_path (direct) | `reached` | (no wrong move: a bump is not a mistake) |
/// | robot_path (plan) | the first letter of each step, `uurd` | the same |
/// | shape_builder | `built` | the tray piece's index and the place, `p3-s1` |
/// | match_pairs | the pairs as top and bottom index, in the order joined, `t0-b2.t1-b0` | the one pair, `t0-b1` |
/// | number_line, spot_error, balance (weigh) | the number, `7` | the number |
/// | balance (compare) | `left`, `same` or `right` | the same |
/// | shop_pay | the total paid in agorot, `350` | the total |
/// | clock_set | the time set, `3.00` or `3.30` | the time |
/// | trace | `trace` | `direction` (the right path from the other end) or `off` |
/// | "I'm not sure" | (empty) | |
///
/// [responsePattern] is the server's own pattern (`supabase/functions/sync-push/handler.ts`, kept equal through
/// `testvectors/wire-patterns.json`); `response_contract_test.dart` plays every activity of the starter pack and every wrong
/// move against it.
library;

/// The pattern `sync-push` takes for `attempt.response`.
const String responsePattern = r'^[A-Za-z0-9=._-]{0,40}$';

/// The pattern `tutor-turn` takes for `attempts[].option`.
const String tutorOptionPattern = r'^[a-z0-9=-]{1,16}$';

final RegExp _response = RegExp(responsePattern);
final RegExp _tutorOption = RegExp(tutorOptionPattern);

/// The codes of [responsePattern], built in one place so that every template writes the same shape.
abstract final class ResponseCode {
  static const String sorted = 'sorted';
  static const String built = 'built';
  static const String reached = 'reached';
  static const String traced = 'trace';
  static const String tracedBackwards = 'direction';
  static const String tracedOff = 'off';

  /// Said by the helper for a move whose code does not fit its pattern (a long program, a clock time).
  static const String move = 'move';

  static String count(int n) => 'n=$n';

  /// An item of a sort put into [bin].
  static String sortMove(String item, String bin) => '$item-$bin';

  /// A share: how many each bin got, in the order of the bins.
  static String share(Iterable<(String, int)> counts) =>
      <String>[for (final (String bin, int n) in counts) '$bin=$n'].join('.');

  /// A pattern: for each place the index of its picture in the palette (`-` for an empty place).
  static String pattern(Iterable<int?> paletteIndexes) =>
      <String>[for (final int? i in paletteIndexes) i == null || i < 0 ? '-' : '$i'].join();

  /// A robot program: the first letter of each step (up, down, left, right).
  static String program(Iterable<String> steps) => <String>[for (final String s in steps) s[0]].join();

  /// A shape put in the wrong place: the tray piece's index and the place.
  static String shapeMove(int piece, String slot) => 'p$piece-$slot';

  /// A pair of faces, as their index in the top row and in the bottom row.
  static String pair(int top, int bottom) => 't$top-b$bottom';

  static String pairs(Iterable<(int, int)> joined) =>
      <String>[for (final (int top, int bottom) in joined) pair(top, bottom)].join('.');

  /// The time a clock was set to.
  static String clock(int hour, {required bool half}) => '$hour.${half ? '30' : '00'}';

  /// True when [code] may be synced.
  static bool fits(String code) => _response.hasMatch(code);

  /// What is sent to the helper as the option of a mistake: the code itself when it fits the helper's pattern, else [move].
  static String tutorOption(String code) => _tutorOption.hasMatch(code) ? code : move;
}
