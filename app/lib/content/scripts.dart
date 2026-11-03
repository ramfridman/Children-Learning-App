import '../engine/course.dart';

// The scripts of the language courses and the rules for the text a pack shows in one (docs/languages/frame.md section 2.1, F5):
// English is Latin only, Russian is Cyrillic with yo (U+0451) and a stress mark (U+0301) only after a vowel, Hebrew is Hebrew letters and
// nikud. A letter of another script that looks like one of the course's own is named, because that is the mistake an author
// makes without seeing it. Pure functions of a string: they read the text, never the pack.
//
// This file holds no Hebrew, Russian or accented text: every character it names is a code point.

/// The text of a tile or a word on show, checked for the course it is in: one sentence for each thing wrong, empty when clean.
/// Digits are refused (the number words are words, and a digit among look-alike letters is a trap) except in Hebrew, whose
/// letter-and-numeral cards (HEB-A-10) show numerals and a few shapes; anything that changes the direction of a run is refused (the
/// app isolates the run itself). A mark needs a letter before it, at most three sit on one letter (the rule of a child's name,
/// B-32, which Hebrew nikud meets), and a text of marks alone shows nothing. A phrase (a text with a space) may also use the
/// ellipsis, the dash, the slash and the double quote; a single word may not. [bareMarks] allows a text that is a mark on its own,
/// for the graphemes of a skill (a vowel sign is taught by itself).
List<String> textProblems(String course, String text, {bool bareMarks = false}) {
  final List<String> out = <String>[];
  if (text != text.trim() || text.contains('  ')) {
    out.add('has a space at an end or two spaces in a row');
  }
  final List<int> runes = text.runes.toList();
  final Set<String> said = <String>{};
  void say(String message) {
    if (said.add(message)) out.add(message);
  }

  final Set<int> punctuation = text.contains(' ') ? _phrasePunctuation : _allowedPunctuation;
  int marks = 0;
  bool baseBefore = false;
  bool visible = false;
  for (int i = 0; i < runes.length; i++) {
    final int r = runes[i];
    if (punctuation.contains(r)) {
      marks = 0;
      baseBefore = false;
      continue;
    }
    if (_markPattern.hasMatch(String.fromCharCode(r))) {
      if (!bareMarks && !baseBefore) {
        say('has the mark ${_name(r)} with no letter before it');
      } else if (!bareMarks && ++marks > _maxMarks) {
        say('has more than $_maxMarks marks on one letter');
      }
    } else {
      marks = 0;
      baseBefore = true;
      visible = true;
    }
    if (_isDirectionControl(r)) {
      say('has the direction control ${_name(r)}: the app isolates the run, the text must not');
    } else if (r < 0x20 || r == 0x7F || (r >= 0x80 && r < 0xA0)) {
      say('has the control character ${_name(r)}');
    } else if (r >= 0x30 && r <= 0x39) {
      if (course != Course.heb) {
        say('has the digit ${String.fromCharCode(r)}: a number in a tile is written as a word');
      }
    } else if (course == Course.heb && _hebrewCardSymbols.contains(r)) {
      continue;
    } else if (r == _diaeresis) {
      say('has a separate diaeresis (${_name(r)}): write the letter yo (U+0451) as one letter');
    } else if (r == _stress) {
      if (course != Course.rus) {
        say('has a stress mark (${_name(r)}), which only a Russian text may carry');
      } else if (i == 0 || !_russianVowels.contains(runes[i - 1])) {
        say('has a stress mark (${_name(r)}) that is not after a vowel');
      } else if (runes[i - 1] == _yoLower || runes[i - 1] == _yoUpper) {
        say('has a stress mark after yo (U+0451), which is always stressed already');
      }
    } else {
      final String? own = _foreignLetter(course, r);
      if (own != null) say(own);
    }
  }
  if (!bareMarks && !visible && text.isNotEmpty) {
    say('shows nothing: it has no letter, only marks, spaces or punctuation');
  }
  return out;
}

/// What is wrong with a line of Hebrew that a child reads (a caption or a title): a direction control or an invisible
/// character (a reversed or hidden word), and a letter of another script, other than the plain Latin and Cyrillic that the
/// pack validator already names (accented Latin, Greek, fullwidth and mathematical letters, and the rest of Cyrillic).
List<String> hebrewLineProblems(String text) {
  final List<String> out = <String>[];
  final Set<String> said = <String>{};
  for (final int r in text.runes) {
    final String? message = _isDirectionControl(r)
        ? 'contains the direction or invisible character ${_name(r)}'
        : _isOtherScriptLetter(r)
        ? 'contains a letter of another script (${_name(r)}): a Hebrew line holds no word of another language'
        : null;
    if (message != null && said.add(message)) out.add(message);
  }
  return out;
}

/// [run] without any direction control, so that a run put between isolates cannot close them early or reach out of them.
String stripDirectionControls(String run) =>
    String.fromCharCodes(run.runes.where((int r) => !_isDirectionControl(r)));

/// Whether [text] is one letter, or a digraph, or a vowel sign on one letter: at most two letters, the combining marks (a stress mark,
/// nikud) not counted. Such a text could be a letter tile, so an item whose options all are this must say what it is (`answer.face`).
bool isSingleLetter(String text) {
  int letters = 0;
  for (final int r in text.runes) {
    final bool mark = (r >= 0x0300 && r <= 0x036F) || _isHebrewPoint(r);
    if (!mark) letters++;
  }
  return letters <= 2;
}

/// The words of [text]: runs of letters and combining marks, cut at spaces and punctuation.
List<String> wordsOf(String text) {
  final List<String> out = <String>[];
  final StringBuffer word = StringBuffer();
  for (final int r in text.runes) {
    if (_phrasePunctuation.contains(r)) {
      if (word.isNotEmpty) out.add(word.toString());
      word.clear();
    } else {
      word.writeCharCode(r);
    }
  }
  if (word.isNotEmpty) out.add(word.toString());
  return out;
}

/// A word as the decodable check reads it: lower case, with the stress mark taken off (a mark does not make a different letter)
/// and the Hebrew marks of each letter in their canonical order (a vowel, the dagesh, a dot: the order a keyboard or a tool
/// may change, which is no other grapheme).
String plainWord(String word) {
  final List<int> runes = <int>[
    for (final int r in word.toLowerCase().runes)
      if (r != _stress) r,
  ];
  final List<int> out = <int>[];
  for (int i = 0; i < runes.length;) {
    if (!_isHebrewPoint(runes[i])) {
      out.add(runes[i++]);
      continue;
    }
    int end = i;
    while (end < runes.length && _isHebrewPoint(runes[end])) {
      end++;
    }
    // A stable sort by canonical combining class (Unicode canonical ordering).
    final List<MapEntry<int, int>> keyed = <MapEntry<int, int>>[
      for (final (int k, int r) in runes.sublist(i, end).indexed)
        MapEntry<int, int>(_markClass(r) * 1000 + k, r),
    ]..sort((MapEntry<int, int> p, MapEntry<int, int> q) => p.key.compareTo(q.key));
    out.addAll(keyed.map((MapEntry<int, int> e) => e.value));
    i = end;
  }
  return String.fromCharCodes(out);
}

/// Whether [word] can be written with the [taught] graphemes alone: a grapheme is a letter, a digraph ("sh") or a vowel sign,
/// at most three code points, and the word may be cut into taught graphemes in any way that works (so "shop" reads with "sh"
/// even when "s" and "h" alone are not taught yet). Word and graphemes are compared in their plain form ([plainWord]).
bool decodes(String word, Set<String> taught) {
  final Set<String> known = <String>{for (final String g in taught) plainWord(g)};
  final List<String> chars = <String>[for (final int r in plainWord(word).runes) String.fromCharCode(r)];
  final List<bool> reaches = List<bool>.filled(chars.length + 1, false)..[0] = true;
  for (int from = 0; from < chars.length; from++) {
    if (!reaches[from]) continue;
    for (int len = 1; len <= 3 && from + len <= chars.length; len++) {
      if (known.contains(chars.sublist(from, from + len).join())) reaches[from + len] = true;
    }
  }
  return reaches[chars.length];
}

// ---- Hebrew ----

/// The Hebrew words of [text] of two letters or more that carry no nikud. The house rule for child text in Bands A and B is
/// that every such word is pointed.
List<String> unpointedHebrewWords(String text) {
  final List<String> out = <String>[];
  final StringBuffer word = StringBuffer();
  int letters = 0;
  bool pointed = false;
  void end() {
    if (letters >= 2 && !pointed) out.add(word.toString());
    word.clear();
    letters = 0;
    pointed = false;
  }

  for (final int r in text.runes) {
    if (_isHebrewLetter(r)) {
      word.writeCharCode(r);
      letters++;
    } else if ((_isHebrewPoint(r) || r == _maqaf) && letters > 0) {
      word.writeCharCode(r);
      pointed = true;
    } else if (r == _geresh || r == _gershayim) {
      if (letters > 0) word.writeCharCode(r);
    } else {
      end();
    }
  }
  end();
  return out;
}

// ---- the code points ----

const int _stress = 0x0301;
const int _diaeresis = 0x0308;
const int _yoLower = 0x0451;
const int _yoUpper = 0x0401;
const int _geresh = 0x05F3;
const int _gershayim = 0x05F4;
const int _maqaf = 0x05BE;

/// The most marks that may stand on one letter: a shin with a dagesh, a dot and a vowel has three.
const int _maxMarks = 3;

final RegExp _markPattern = RegExp(r'\p{M}', unicode: true);

/// The marks that may stand in a word or between words of a tile: a space, an apostrophe (plain or curly), a hyphen, and the full
/// stop, comma, colon, exclamation and question marks.
const Set<int> _allowedPunctuation = <int>{0x20, 0x27, 0x2019, 0x2D, 0x2E, 0x2C, 0x3A, 0x21, 0x3F};

/// What a phrase (a text of more than one word) may also use: the ellipsis, the em dash, the slash and the double quote.
final Set<int> _phrasePunctuation = <int>{..._allowedPunctuation, 0x2026, 0x2014, 0x2F, 0x22};

/// What the Hebrew letter-and-numeral cards show besides letters and digits (HEB-A-10): a filled and an empty circle, a filled and
/// an empty triangle, a sun, a star, a heart and a flower.
const Set<int> _hebrewCardSymbols = <int>{0x25CF, 0x25CB, 0x25B2, 0x25B3, 0x2600, 0x2B50, 0x2665, 0x273F};

/// The Russian vowel letters, both cases, yo (U+0451) apart (it takes no mark).
final Set<int> _russianVowels = <int>{
  for (final int r in <int>[0x430, 0x435, 0x438, 0x43E, 0x443, 0x44B, 0x44D, 0x44E, 0x44F]) ...<int>[
    r,
    r - 0x20,
  ],
  _yoLower,
  _yoUpper,
};

bool _isDirectionControl(int r) =>
    r == 0xAD ||
    (r >= 0x2060 && r <= 0x2064) ||
    r == 0x200E ||
    r == 0x200F ||
    r == 0x061C ||
    (r >= 0x202A && r <= 0x202E) ||
    (r >= 0x2066 && r <= 0x2069) ||
    (r >= 0x200B && r <= 0x200D) ||
    r == 0xFEFF;

bool _isHebrewLetter(int r) => r >= 0x05D0 && r <= 0x05EA;

/// The Hebrew points: the vowel signs, the dagesh, the rafe, the shin and sin dots and the upper and lower dots (not the
/// maqaf, the paseq and the other punctuation between U+05B0 and U+05C7).
bool _isHebrewPoint(int r) =>
    (r >= 0x05B0 && r <= 0x05BD) ||
    r == 0x05BF ||
    r == 0x05C1 ||
    r == 0x05C2 ||
    r == 0x05C4 ||
    r == 0x05C5 ||
    r == 0x05C7;

/// The canonical combining class of a Hebrew point (Unicode), which gives the order of the marks on a letter.
int _markClass(int r) => switch (r) {
  0x05B0 => 10,
  0x05B1 => 11,
  0x05B2 => 12,
  0x05B3 => 13,
  0x05B4 => 14,
  0x05B5 => 15,
  0x05B6 => 16,
  0x05B7 => 17,
  0x05B8 || 0x05C7 => 18,
  0x05B9 || 0x05BA => 19,
  0x05BB => 20,
  0x05BC => 21,
  0x05BD => 22,
  0x05BF => 23,
  0x05C1 => 24,
  0x05C2 => 25,
  0x05C5 => 220,
  _ => 230,
};

/// A letter of a script that no Hebrew line holds, other than the plain Latin (A to z) and Cyrillic (U+0400 to U+052F) that the
/// validator names already: accented and extended Latin, fullwidth Latin, Greek, the rest of Cyrillic, and the mathematical
/// alphanumerics (which draw Latin letters).
bool _isOtherScriptLetter(int r) =>
    (r >= 0xC0 && r <= 0x24F && r != 0xD7 && r != 0xF7) ||
    (r >= 0x1E00 && r <= 0x1EFF) ||
    (r >= 0xFF21 && r <= 0xFF3A) ||
    (r >= 0xFF41 && r <= 0xFF5A) ||
    (r >= 0x370 && r <= 0x3FF) ||
    (r >= 0x1C80 && r <= 0x1C8F) ||
    (r >= 0x2DE0 && r <= 0x2DFF) ||
    (r >= 0xA640 && r <= 0xA69F) ||
    (r >= 0x1D400 && r <= 0x1D7FF);

bool _isLatinLetter(int r) => (r >= 0x41 && r <= 0x5A) || (r >= 0x61 && r <= 0x7A);

bool _isRussianLetter(int r) => (r >= 0x410 && r <= 0x44F) || r == _yoUpper || r == _yoLower;

bool _isCyrillic(int r) => r >= 0x400 && r <= 0x52F;

bool _isLatinAny(int r) => (r >= 0xC0 && r <= 0x24F) || (r >= 0x1E00 && r <= 0x1EFF) || _isLatinLetter(r);

String _name(int r) => 'U+${r.toRadixString(16).toUpperCase().padLeft(4, '0')}';

String _scriptName(int r) {
  if (_isCyrillic(r)) return 'Cyrillic';
  if (_isLatinAny(r)) return 'Latin';
  if (_isHebrewLetter(r) || _isHebrewPoint(r)) return 'Hebrew';
  if (r >= 0x370 && r <= 0x3FF) return 'Greek';
  if (r >= 0x600 && r <= 0x6FF) return 'Arabic';
  return 'other';
}

/// What is wrong with the letter [r] in a text of [course], or null when it belongs there.
String? _foreignLetter(String course, int r) {
  final bool own = switch (course) {
    Course.eng => _isLatinLetter(r),
    Course.rus => _isRussianLetter(r),
    Course.heb => _isHebrewLetter(r) || _isHebrewPoint(r) || r == _geresh || r == _gershayim || r == _maqaf,
    _ => false,
  };
  if (own) return null;
  final String? twin = _lookAlike(course, r);
  final String ch = String.fromCharCode(r);
  final String shown = '${_scriptName(r)} letter "$ch" (${_name(r)})';
  if (twin != null) {
    return 'has the $shown, which looks like the ${course == Course.rus ? 'Cyrillic' : 'Latin'} "$twin": '
        'a text is all one script';
  }
  return switch (course) {
    Course.eng => 'has the $shown: English is written with the letters a to z',
    Course.rus => 'has the $shown: Russian is written with the Cyrillic letters of its alphabet',
    Course.heb => 'has the $shown: Hebrew is written with Hebrew letters and nikud',
    _ => 'has the $shown, which no language course writes',
  };
}

/// The letter of the course's own script that [r] (a letter of the other script) looks like, or null.
String? _lookAlike(String course, int r) {
  if (course == Course.eng) {
    final int? latin = _cyrillicToLatin[r];
    return latin == null ? null : String.fromCharCode(latin);
  }
  if (course == Course.rus) {
    for (final MapEntry<int, int> e in _cyrillicToLatin.entries) {
      if (e.value == r) return String.fromCharCode(e.key);
    }
  }
  return null;
}

/// Cyrillic letters that look the same as a Latin letter in the teaching font (Cyrillic code point, Latin code point).
const Map<int, int> _cyrillicToLatin = <int, int>{
  0x430: 0x61, // looks like a
  0x435: 0x65, // looks like e
  0x43E: 0x6F, // looks like o
  0x440: 0x70, // looks like p
  0x441: 0x63, // looks like c
  0x443: 0x79, // looks like y
  0x445: 0x78, // looks like x
  0x456: 0x69, // looks like i
  0x458: 0x6A, // looks like j
  0x455: 0x73, // looks like s
  0x410: 0x41, // looks like A
  0x412: 0x42, // looks like B
  0x415: 0x45, // looks like E
  0x41A: 0x4B, // looks like K
  0x41C: 0x4D, // looks like M
  0x41D: 0x48, // looks like H
  0x41E: 0x4F, // looks like O
  0x420: 0x50, // looks like P
  0x421: 0x43, // looks like C
  0x422: 0x54, // looks like T
  0x425: 0x58, // looks like X
  0x423: 0x59, // looks like Y
  0x406: 0x49, // looks like I
  0x408: 0x4A, // looks like J
  0x405: 0x53, // looks like S
};
