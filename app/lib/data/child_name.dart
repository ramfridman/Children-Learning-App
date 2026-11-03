/// The one rule for a child's first name (board B-28), shared with the gateway through `testvectors/child-name.json`.
///
/// `child-put` takes a nickname of 1 to 24 UTF-16 code units (its pattern has no `u` flag), so the app counts the same
/// way, with [String.length], never in graphemes: a letter with nikud is two units, an emoji is two. The app also
/// refuses more characters than the server does today ([safeChildName]): the C1 controls, the invisible format
/// characters, a lone surrogate and a stack of combining marks, which can turn a name around on screen, hide a name or
/// differ between the phone and the server, and never belong in one.
library;

/// The longest first name, in UTF-16 code units.
const int childNameMaxLength = 24;

/// What is wrong with a name the parent typed, if anything.
enum ChildNameProblem { ok, empty, tooLong, badChars }

/// The most combining marks in a row a name may hold. Hebrew nikud is made of them: a shin with a dagesh, a shin dot and
/// a vowel has three, so a pointed name passes; a stack of four or more is a way to smear a letter over the lines around it.
const int childNameMaxMarks = 3;

/// C0 and C1 controls with DEL, the format characters (Cf: zero-width characters and joiners, the soft hyphen, the byte
/// order mark, the direction marks U+200E, U+200F and U+061C, embeddings, overrides and isolates, and the tag characters
/// U+E0000 to U+E007F), the private-use characters, the line and paragraph separators, and the angle brackets.
final RegExp _refused = RegExp(r'[\p{Cc}\p{Cf}\p{Co}\p{Zl}\p{Zp}<>]', unicode: true);

/// Characters that draw nothing but are letters or symbols to Unicode (the braille blank, the Hangul fillers), and the
/// grapheme joiner U+034F, a combining mark that draws nothing.
const Set<int> _fillers = <int>{0x2800, 0x115F, 0x1160, 0x3164, 0xFFA0, 0x034F};

/// A noncharacter: U+FDD0 to U+FDEF, and the last two code points of every plane (U+FFFE, U+FFFF, U+1FFFE, ...).
bool _isNoncharacter(int rune) => (rune >= 0xFDD0 && rune <= 0xFDEF) || (rune & 0xFFFE) == 0xFFFE;

final RegExp _mark = RegExp(r'\p{M}', unicode: true);
final RegExp _space = RegExp(r'\p{Z}', unicode: true);

/// The one cleaning of a first name, for the form, the server, the family's list and the home island (board B-32): [raw]
/// without what no name holds, then trimmed. What goes: the characters of [_refused], the invisible fillers, a lone
/// surrogate half (the server would store U+FFFD for it), a noncharacter, a combining mark with no character before it
/// (at the start of the name or after a space), and every combining mark after the [childNameMaxMarks]-th in a row. A name with no visible character (only spaces, marks or nothing) comes back empty. A name that is already clean
/// comes back unchanged, so `safeChildName(name) == name` is the test that a typed name is clean.
String safeChildName(String raw) {
  final StringBuffer out = StringBuffer();
  int marks = 0;
  bool visible = false;
  // True while the character before is one a mark can sit on: not a space, not the start.
  bool hasBase = false;
  for (final int rune in raw.runes) {
    if (_isRefused(rune)) continue;
    final String char = String.fromCharCode(rune);
    if (_mark.hasMatch(char)) {
      if (!hasBase || ++marks > childNameMaxMarks) continue;
    } else {
      marks = 0;
      hasBase = !_space.hasMatch(char);
      if (hasBase) visible = true;
    }
    out.write(char);
  }
  return visible ? out.toString().trim() : '';
}

// A surrogate that String.runes could not pair is a lone half.
bool _isRefused(int rune) =>
    (rune >= 0xD800 && rune <= 0xDFFF) ||
    _fillers.contains(rune) ||
    _isNoncharacter(rune) ||
    _refused.hasMatch(String.fromCharCode(rune));

final RegExp _anySpace = RegExp(r'\s');
final RegExp _spaceRun = RegExp(' {2,}');

/// A name as it is shown, for names saved before the rule existed (the stored name is not changed): white space becomes
/// a plain space, [safeChildName] cleans, the spaces are collapsed. Empty when nothing visible is left.
String displayChildName(String stored) =>
    safeChildName(stored.replaceAll(_anySpace, ' ')).replaceAll(_spaceRun, ' ').trim();

/// Checks a name as it will be saved: trimmed first.
ChildNameProblem validateChildName(String raw) {
  final String name = raw.trim();
  if (name.isEmpty) return ChildNameProblem.empty;
  if (safeChildName(name) != name) return ChildNameProblem.badChars;
  if (name.length > childNameMaxLength) return ChildNameProblem.tooLong;
  return ChildNameProblem.ok;
}

/// The nickname that goes to the server for a name saved on this phone, which before B-28 could be 40 long or hold
/// characters the app now refuses: those characters dropped ([safeChildName]), cut to [childNameMaxLength] units without
/// splitting a surrogate pair, trimmed again. Empty when nothing is left.
String fitChildNameForServer(String raw) => cutToUtf16Units(safeChildName(raw), childNameMaxLength).trim();

/// The first [max] UTF-16 units of [text], one fewer when the cut would fall inside a surrogate pair.
String cutToUtf16Units(String text, int max) {
  if (text.length <= max) return text;
  int end = max;
  if (end > 0 && _isHighSurrogate(text.codeUnitAt(end - 1))) end--;
  return text.substring(0, end);
}

bool _isHighSurrogate(int unit) => unit >= 0xD800 && unit <= 0xDBFF;

// ---- how a name is said (B-42) ----

/// The longest spelling of how a name is said, in UTF-16 units (the same limit as the nickname).
const int spokenNameMaxLength = 24;

// Hebrew letters; their nikud (never U+05B3 hataf qamats or U+05C7 qamats qatan: the voice is never sent them); a space, a
// hyphen (ASCII or maqaf) and a geresh (ASCII apostrophe or U+05F3).
const String _letter = '\u05D0-\u05EA';
const String _nikud = '\u05B0-\u05B2\u05B4-\u05BC\u05C1\u05C2';
const String _joiner = " '\u05BE\u05F3-";

/// The one rule for how a name is said, the same as the gateway's `NAME_SPOKEN` and the database check
/// (`testvectors/name-spoken.json` holds all three to the same answers): a mark only on a letter, at most three in a row,
/// no leading, trailing or double space, at least one letter. It counts UTF-16 units, as the server does.
final RegExp _spokenName = RegExp(
  '^(?=.*[$_letter])(?! )(?!.* \$)(?!.* {2})(?:[$_letter][$_nikud]{0,3}|[$_joiner])+\$',
);

/// Whether [value] is a spelling the gateway will voice, exactly as it stands (no trimming).
bool isSpokenName(String value) =>
    value.isNotEmpty && value.length <= spokenNameMaxLength && _spokenName.hasMatch(value);

/// What is wrong with a spelling a parent typed, if anything. Nothing typed is [ok]: the parent has no spelling to give
/// (the field is cleared).
enum SpokenNameProblem { ok, tooLong, badChars }

/// Checks a spelling as it will be saved: trimmed first. An empty one is fine (it clears the spelling).
SpokenNameProblem validateSpokenName(String raw) {
  final String value = raw.trim();
  if (value.isEmpty) return SpokenNameProblem.ok;
  if (value.length > spokenNameMaxLength) return SpokenNameProblem.tooLong;
  return isSpokenName(value) ? SpokenNameProblem.ok : SpokenNameProblem.badChars;
}
