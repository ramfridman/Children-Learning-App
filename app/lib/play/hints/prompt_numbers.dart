// The numbers a question says in words, for the hints that must show them (B-40, Band B). A scene that has no group or row to read
// the numbers from ("ten is three and how many?") says them only in its question, so a plan reads the words as the activity
// has them. The words are written here in transliteration (one Latin letter for each Hebrew one, see [_letters]) so that no Hebrew
// string lives outside `strings/he.dart`; they are read, never shown.

/// One Latin letter for each Hebrew letter of the number words (final forms are the same letter as the plain one).
const Map<String, String> _letters = <String, String>{
  'a': '\u05D0',
  'b': '\u05D1',
  'd': '\u05D3',
  'v': '\u05D5',
  'x': '\u05D7',
  'y': '\u05D9',
  'k': '\u05DB',
  'l': '\u05DC',
  'm': '\u05DE',
  'n': '\u05E0',
  'e': '\u05E2',
  'p': '\u05E4',
  'r': '\u05E8',
  'S': '\u05E9',
  'T': '\u05EA',
  'h': '\u05D4',
  's': '\u05E1',
};

String _word(String latin) => latin.split('').map((String c) => _letters[c]!).join();

/// The words of the numbers 0 to 9 (all their forms), the word for ten, and the tens 20 to 90.
final Map<String, int> _units = <String, int>{
  _word('aps'): 0,
  _word('axT'): 1,
  _word('axd'): 1,
  _word('STym'): 2,
  _word('STyym'): 2,
  _word('Sny'): 2,
  _word('STy'): 2,
  _word('SlvS'): 3,
  _word('SlS'): 3,
  _word('SlvSh'): 3,
  _word('arbe'): 4,
  _word('arbeh'): 4,
  _word('xmS'): 5,
  _word('xmSh'): 5,
  _word('SS'): 6,
  _word('SSh'): 6,
  _word('Sbe'): 7,
  _word('Sbeh'): 7,
  _word('Smvnh'): 8,
  _word('TSe'): 9,
  _word('TSeh'): 9,
};

final Set<String> _ten = <String>{_word('eSr'), _word('eSrh')};

final Map<String, int> _tens = <String, int>{
  _word('eSrym'): 20,
  _word('SlvSym'): 30,
  _word('arbeym'): 40,
  _word('xmSym'): 50,
  _word('SSym'): 60,
  _word('Sbeym'): 70,
  _word('Smvnym'): 80,
  _word('TSeym'): 90,
};

/// The Hebrew letters (without marks) of a prompt, with the final letters turned into the plain ones, and the rest as breaks.
String _plainLetters(String s) {
  const Map<String, String> finals = <String, String>{
    '\u05DA': '\u05DB',
    '\u05DD': '\u05DE',
    '\u05DF': '\u05E0',
    '\u05E3': '\u05E4',
    '\u05E5': '\u05E6',
  };
  final StringBuffer out = StringBuffer();
  for (final int c in s.runes) {
    final String ch = String.fromCharCode(c);
    if (c >= 0x5D0 && c <= 0x5EA) {
      out.write(finals[ch] ?? ch);
    } else if (c < 0x591 || c > 0x5C7) {
      out.write(' '); // a mark is dropped, anything else that is not a letter is a break
    }
  }
  return out.toString();
}

/// The numbers a [prompt] says as words, in the order it says them: "ten is three and how many" gives 10, 3; "twenty and nine" gives
/// 29. A number word with the letter "and" in front ("and five") counts; a unit before "ten" is a teen (a unit and ten is 11 to 19).
List<int> numbersIn(String prompt) {
  final List<String> tokens = _plainLetters(prompt).split(' ').where((String t) => t.isNotEmpty).toList();
  final String vav = _word('v');
  String bare(String t) => t.length > 2 && t.startsWith(vav) ? t.substring(1) : t;
  final List<int> out = <int>[];
  for (int i = 0; i < tokens.length; i++) {
    final String t = bare(tokens[i]);
    final int? unit = _units[t];
    if (unit != null) {
      final bool teen = unit >= 1 && i + 1 < tokens.length && _ten.contains(tokens[i + 1]);
      out.add(teen ? 10 + unit : unit);
      if (teen) i++;
    } else if (_ten.contains(t)) {
      out.add(10);
    } else if (_tens.containsKey(t)) {
      int v = _tens[t]!;
      if (i + 1 < tokens.length && tokens[i + 1].startsWith(vav)) {
        final int? more = _units[bare(tokens[i + 1])];
        if (more != null && more > 0) {
          v += more;
          i++;
        }
      }
      out.add(v);
    }
  }
  return out;
}

/// True when [prompt] (without marks) has [word] (in the transliteration of this file) as one of its words.
bool promptHasWord(String prompt, String word) => _plainLetters(prompt).split(' ').contains(_word(word));
