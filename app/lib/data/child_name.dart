/// The one rule for a child's first name (board B-28), shared with the gateway through `testvectors/child-name.json`.
///
/// `child-put` takes a nickname of 1 to 24 UTF-16 code units (its pattern has no `u` flag), so the app counts the same
/// way, with [String.length], never in graphemes: a letter with nikud is two units, an emoji is two. The app also
/// refuses more characters than the server does today: the C1 controls and the invisible direction marks, which can
/// turn a name around on screen and never belong in one.
library;

/// The longest first name, in UTF-16 code units.
const int childNameMaxLength = 24;

/// What is wrong with a name the parent typed, if anything.
enum ChildNameProblem { ok, empty, tooLong, badChars }

/// C0 and C1 controls with DEL, the direction marks, embeddings, overrides and isolates, and the angle brackets.
final RegExp _refused = RegExp(r'[\u0000-\u001f\u007f-\u009f\u200e\u200f\u202a-\u202e\u2066-\u2069<>]');

/// Checks a name as it will be saved: trimmed first.
ChildNameProblem validateChildName(String raw) {
  final String name = raw.trim();
  if (name.isEmpty) return ChildNameProblem.empty;
  if (_refused.hasMatch(name)) return ChildNameProblem.badChars;
  if (name.length > childNameMaxLength) return ChildNameProblem.tooLong;
  return ChildNameProblem.ok;
}

/// The nickname that goes to the server for a name saved on this phone, which before B-28 could be 40 long or hold
/// characters the app now refuses: those characters dropped, trimmed, cut to [childNameMaxLength] units without
/// splitting a surrogate pair, trimmed again. Empty when nothing is left.
String fitChildNameForServer(String raw) =>
    cutToUtf16Units(raw.replaceAll(_refused, '').trim(), childNameMaxLength).trim();

/// The first [max] UTF-16 units of [text], one fewer when the cut would fall inside a surrogate pair.
String cutToUtf16Units(String text, int max) {
  if (text.length <= max) return text;
  int end = max;
  if (end > 0 && _isHighSurrogate(text.codeUnitAt(end - 1))) end--;
  return text.substring(0, end);
}

bool _isHighSurrogate(int unit) => unit >= 0xD800 && unit <= 0xDBFF;
