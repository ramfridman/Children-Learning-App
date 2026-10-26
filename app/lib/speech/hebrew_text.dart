// Hebrew text helpers for the answer matcher. Pure Dart (no Flutter), so the CI validator and the simulator can use them.

/// Niqqud, cantillation marks and the other combining marks of the Hebrew block.
final RegExp _marks = RegExp('[֑-ׇ]');

const Map<String, String> _finals = <String, String>{'ך': 'כ', 'ם': 'מ', 'ן': 'נ', 'ף': 'פ', 'ץ': 'צ'};

/// Strips niqqud, folds the final letters, drops punctuation and quotes, turns the maqaf into a space and collapses
/// white space. Latin letters are lower-cased; digits stay.
String normalizeHebrew(String text) {
  final StringBuffer out = StringBuffer();
  final String bare = text.replaceAll(_marks, '').replaceAll('־', ' ');
  for (final int r in bare.runes) {
    final String ch = String.fromCharCode(r);
    if (_finals.containsKey(ch)) {
      out.write(_finals[ch]);
    } else if ((r >= 0x05D0 && r <= 0x05EA) || (r >= 0x30 && r <= 0x39) || (r >= 0x61 && r <= 0x7A)) {
      out.write(ch);
    } else if (r >= 0x41 && r <= 0x5A) {
      out.write(ch.toLowerCase());
    } else {
      out.write(' '); // punctuation, quotes, the geresh, anything else
    }
  }
  return out.toString().trim().replaceAll(RegExp(r'\s+'), ' ');
}

List<String> tokensOf(String normalized) => normalized.isEmpty ? const <String>[] : normalized.split(' ');

bool isDigits(String token) => RegExp(r'^[0-9]+$').hasMatch(token);

/// The one-letter prefixes (and, the, in, to, as, that, from).
const String prefixLetters = 'והבלכשמ';

/// A consonant skeleton that survives how children speak and how recognisers spell: vowel letters inside a word are
/// dropped, and the letters that are confused (כ ח ק; ת ט; ב ו; ש ס; ר ל; א ע ה) share a class. Used on normalised words.
String phoneticKey(String word) {
  final StringBuffer out = StringBuffer();
  final List<String> chars = word.split('');
  for (int i = 0; i < chars.length; i++) {
    final String c = chars[i];
    String? k;
    switch (c) {
      case ' ':
        k = ' ';
      case 'כ' || 'ח' || 'ק':
        k = 'k';
      case 'ת' || 'ט':
        k = 't';
      case 'ב' || 'ו':
        k = 'b';
      case 'ש' || 'ס':
        k = 's';
      case 'ר' || 'ל':
        k = 'l';
      case 'א' || 'ע' || 'ה':
        // A vowel letter: kept only at the start of a word.
        k = (i == 0 || chars[i - 1] == ' ') ? 'a' : null;
      case 'י':
        k = (i == 0 || chars[i - 1] == ' ') ? 'y' : null;
      case 'ד':
        k = 'd';
      case 'ג':
        k = 'g';
      case 'ז' || 'צ':
        k = 'z';
      case 'מ':
        k = 'm';
      case 'נ':
        k = 'n';
      case 'פ':
        k = 'f';
      default:
        k = c; // digits and Latin letters stay as they are
    }
    if (k == null) continue;
    out.write(k);
  }
  return out.toString();
}

int editDistance(String a, String b) {
  if (a == b) return 0;
  if (a.isEmpty) return b.length;
  if (b.isEmpty) return a.length;
  List<int> prev = List<int>.generate(b.length + 1, (int i) => i);
  for (int i = 1; i <= a.length; i++) {
    final List<int> cur = List<int>.filled(b.length + 1, 0)..[0] = i;
    for (int j = 1; j <= b.length; j++) {
      final int cost = a[i - 1] == b[j - 1] ? 0 : 1;
      cur[j] = <int>[prev[j] + 1, cur[j - 1] + 1, prev[j - 1] + cost].reduce((int x, int y) => x < y ? x : y);
    }
    prev = cur;
  }
  return prev[b.length];
}

/// How alike two normalised words or phrases sound, from 0 to 1 (1 for the same skeleton).
double similarity(String a, String b) {
  if (a == b) return 1;
  final String ka = phoneticKey(a);
  final String kb = phoneticKey(b);
  if (ka.isEmpty || kb.isEmpty) return 0;
  // The same sounds, spelled differently: almost sure, but a word spelled exactly as expected always beats it.
  if (ka == kb) return 0.95;
  final int longest = ka.length > kb.length ? ka.length : kb.length;
  return 1 - editDistance(ka, kb) / longest;
}
