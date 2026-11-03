import '../engine/course.dart';

// The scripts of the language courses and the rules for the text a pack shows in one (docs/languages/frame.md section 2.1, F5):
// English is Latin only, Russian is Cyrillic with ё and a stress mark (U+0301) only after a vowel, Hebrew is Hebrew letters and
// nikud. A letter of another script that looks like one of the course's own is named, because that is the mistake an author
// makes without seeing it. Pure functions of a string: they read the text, never the pack.
//
// This file holds no Hebrew, Russian or accented text: every character it names is a code point.

/// The text of a tile or a word on show, checked for the course it is in: one sentence for each thing wrong, empty when clean.
/// Digits are refused (the number words are words, and a digit among look-alike letters is a trap), and so is anything that
/// changes the direction of a run: the app isolates the run itself.
List<String> textProblems(String course, String text) {
  final List<String> out = <String>[];
  if (text != text.trim() || text.contains('  ')) {
    out.add('has a space at an end or two spaces in a row');
  }
  final List<int> runes = text.runes.toList();
  final Set<String> said = <String>{};
  void say(String message) {
    if (said.add(message)) out.add(message);
  }

  for (int i = 0; i < runes.length; i++) {
    final int r = runes[i];
    if (_allowedPunctuation.contains(r)) continue;
    if (_isDirectionControl(r)) {
      say('has the direction control ${_name(r)}: the app isolates the run, the text must not');
    } else if (r < 0x20 || r == 0x7F || (r >= 0x80 && r < 0xA0)) {
      say('has the control character ${_name(r)}');
    } else if (r >= 0x30 && r <= 0x39) {
      say('has the digit ${String.fromCharCode(r)}: a number in a tile is written as a word');
    } else if (r == _diaeresis) {
      say('has a separate diaeresis (${_name(r)}): write ё as one letter');
    } else if (r == _stress) {
      if (course != Course.rus) {
        say('has a stress mark (${_name(r)}), which only a Russian text may carry');
      } else if (i == 0 || !_russianVowels.contains(runes[i - 1])) {
        say('has a stress mark (${_name(r)}) that is not after a vowel');
      } else if (runes[i - 1] == _yoLower || runes[i - 1] == _yoUpper) {
        say('has a stress mark after ё, which is always stressed already');
      }
    } else {
      final String? own = _foreignLetter(course, r);
      if (own != null) say(own);
    }
  }
  return out;
}

/// The words of [text]: runs of letters and combining marks, cut at spaces and punctuation.
List<String> wordsOf(String text) {
  final List<String> out = <String>[];
  final StringBuffer word = StringBuffer();
  for (final int r in text.runes) {
    if (_allowedPunctuation.contains(r)) {
      if (word.isNotEmpty) out.add(word.toString());
      word.clear();
    } else {
      word.writeCharCode(r);
    }
  }
  if (word.isNotEmpty) out.add(word.toString());
  return out;
}

/// A word as the decodable check reads it: lower case, with the stress mark taken off (a mark does not make a different letter).
String plainWord(String word) =>
    String.fromCharCodes(word.toLowerCase().runes.where((int r) => r != _stress));

/// Whether [word] can be written with the [taught] graphemes alone: a grapheme is a letter, a digraph ("sh") or a vowel sign,
/// at most three code points, and the word may be cut into taught graphemes in any way that works (so "shop" reads with "sh"
/// even when "s" and "h" alone are not taught yet).
bool decodes(String word, Set<String> taught) {
  final List<String> chars = <String>[for (final int r in plainWord(word).runes) String.fromCharCode(r)];
  final List<bool> reaches = List<bool>.filled(chars.length + 1, false)..[0] = true;
  for (int from = 0; from < chars.length; from++) {
    if (!reaches[from]) continue;
    for (int len = 1; len <= 3 && from + len <= chars.length; len++) {
      if (taught.contains(chars.sublist(from, from + len).join())) reaches[from + len] = true;
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
    } else if (_isHebrewPoint(r) && letters > 0) {
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

/// The marks that may stand between words of a tile: a space, an apostrophe, a hyphen, and the full stop, comma, colon,
/// exclamation and question marks.
const Set<int> _allowedPunctuation = <int>{0x20, 0x27, 0x2D, 0x2E, 0x2C, 0x3A, 0x21, 0x3F};

/// The Russian vowel letters, both cases, ё apart (it takes no mark).
final Set<int> _russianVowels = <int>{
  for (final int r in <int>[0x430, 0x435, 0x438, 0x43E, 0x443, 0x44B, 0x44D, 0x44E, 0x44F]) ...<int>[
    r,
    r - 0x20,
  ],
  _yoLower,
  _yoUpper,
};

bool _isDirectionControl(int r) =>
    r == 0x200E ||
    r == 0x200F ||
    r == 0x061C ||
    (r >= 0x202A && r <= 0x202E) ||
    (r >= 0x2066 && r <= 0x2069) ||
    (r >= 0x200B && r <= 0x200D) ||
    r == 0xFEFF;

bool _isHebrewLetter(int r) => r >= 0x05D0 && r <= 0x05EA;

bool _isHebrewPoint(int r) => r >= 0x05B0 && r <= 0x05C7;

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
    Course.heb => _isHebrewLetter(r) || _isHebrewPoint(r) || r == _geresh || r == _gershayim,
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
    Course.rus => 'has the $shown: Russian is written with Cyrillic letters (А to я and ё)',
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
  0x430: 0x61, // а a
  0x435: 0x65, // е e
  0x43E: 0x6F, // о o
  0x440: 0x70, // р p
  0x441: 0x63, // с c
  0x443: 0x79, // у y
  0x445: 0x78, // х x
  0x456: 0x69, // і i
  0x458: 0x6A, // ј j
  0x455: 0x73, // ѕ s
  0x410: 0x41, // А A
  0x412: 0x42, // В B
  0x415: 0x45, // Е E
  0x41A: 0x4B, // К K
  0x41C: 0x4D, // М M
  0x41D: 0x48, // Н H
  0x41E: 0x4F, // О O
  0x420: 0x50, // Р P
  0x421: 0x43, // С C
  0x422: 0x54, // Т T
  0x425: 0x58, // Х X
  0x423: 0x59, // У Y
  0x406: 0x49, // І I
  0x408: 0x4A, // Ј J
  0x405: 0x53, // Ѕ S
};
