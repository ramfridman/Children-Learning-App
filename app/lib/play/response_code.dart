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
/// | tap_answer (tap-all, L5-1) | the cards picked, in order, `0.2.5` | the same |
/// | sort_drag (a language sort, L5-1) | `sorted` | the cards of each bin when the last is sorted, `b1=02-b2=13` |
/// | robot_path (direct) | `reached` | (no wrong move: a bump is not a mistake) |
/// | robot_path (plan) | the first letter of each step, `uurd` | the same |
/// | shape_builder | `built` | the tray piece's index and the place, `p3-s1` |
/// | match_pairs | the pairs as top and bottom index, in the order joined, `t0-b2.t1-b0` | the one pair, `t0-b1` |
/// | number_line, spot_error, balance (weigh) | the number, `7` | the number |
/// | balance (compare) | `left`, `same` or `right` | the same |
/// | shop_pay | the total paid in agorot, `350` | the total |
/// | clock_set | the time set, `3.00` or `3.30` | the time |
/// | trace | `trace` | `direction` (the right path from the other end) or `off` |
/// | trace 2.0 (LS02, write a letter) | `ok` when the letter or the word is written; a trace keeps `trace` | an error it named: the stroke and what, `s2.dir` (`start`, `dir`, `lines`, `mirror`, `partner`), in a word the box first, `b2.s1.start`; a miss it cannot name writes nothing |
/// | sound_boxes 1.1 (LS03 boxes) | the steps' right values, `n=3.c=brb.s=1.w=2` (the count, the colours as `r` vowel `b` hard `g` soft, the place of the stress, the place of the sound; only the steps the item has) | the same up to the step that was wrong, with the wrong value in its place, `n=4`, `n=3.c=bbb`, `n=3.s=2` |
/// | change_part (LS05, make) | the parts that made it, `p1.p4` (one id for each place) | the parts the child made |
/// | say_it | `said` (the child was heard, speech evidence) or `picture` (the scored tap on the picture) | (none: nothing is wrong) |
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

  /// LS02: the letter or the word was written (copy and memory).
  static const String written = 'ok';
  static const String tracedBackwards = 'direction';
  static const String tracedOff = 'off';

  /// say_it: the per-word matcher heard the child (the only speech result that is written; an unsure one writes nothing).
  static const String said = 'said';

  /// say_it: the tap on the picture that ends the activity, when the author scored it.
  static const String picture = 'picture';

  /// Said by the helper for a move whose code does not fit its pattern (a long program, a clock time).
  static const String move = 'move';

  static String count(int n) => 'n=$n';

  /// LS03 boxes: the count, the colours, the place of the stress and the place of the sound, each only when the step has one: `n=3.c=brb.s=1.w=2`.
  /// Numbers and three colour letters, never a word.
  static String boxes({int? n, String? colours, int? stress, int? which}) => <String>[
    if (n != null) 'n=$n',
    if (colours != null) 'c=$colours',
    if (stress != null) 's=$stress',
    if (which != null) 'w=$which',
  ].join('.');

  /// LS05: the ids of the parts the child made, one for each place of the frame: `p1.p4`.
  static String parts(Iterable<String> ids) => ids.join('.');

  /// LS02: the [stroke]th stroke (from 1) of the letter was an error that was named: `s2.dir`. Numbers and a short word, never a point.
  static String strokeFault(int stroke, String what) => 's$stroke.$what';

  /// LS02: the same in the [box]th letter (from 1) of a word: `b2.s1.start`.
  static String boxStroke(int box, int stroke, String what) => 'b$box.s$stroke.$what';

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

  /// A tap-all: the index of each card picked, in the order picked (`0.2.5`).
  static String picks(Iterable<int> indexes) => indexes.join('.');

  /// A sort checked when its last card is put in a bin: for each bin the indexes of its cards, digits run together (`b1=02-b2=13`).
  static String sortCheck(Iterable<(String, List<int>)> bins) =>
      <String>[for (final (String bin, List<int> cards) in bins) '$bin=${cards.join()}'].join('-');

  /// The time a clock was set to.
  static String clock(int hour, {required bool half}) => '$hour.${half ? '30' : '00'}';

  /// True when [code] may be synced.
  static bool fits(String code) => _response.hasMatch(code);

  /// What is sent to the helper as the option of a mistake: the code itself when it fits the helper's pattern, else [move].
  static String tutorOption(String code) => _tutorOption.hasMatch(code) ? code : move;
}
