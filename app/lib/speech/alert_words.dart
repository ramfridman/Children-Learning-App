import 'hebrew_text.dart';

/// The on-device word lists behind two alerts (PLAN: Alerts in v1). No model is involved: the recogniser's text of a
/// spoken answer is looked at once, on the phone, and only the category (and, if the parent allows it, the words) is
/// kept.
///
/// **Review needed.** These are a small, conservative first draft written by Claude, `review: needs-editor`: an editor
/// and, for the second list, someone who works with children must read, correct and extend them before the app reaches a
/// child for real. A word that is also an everyday word (a cup, "under") is left out on purpose: a false alert is a
/// small cost, a missed one is not, but an alert on every glass of water would teach the parent to ignore alerts.
enum WordAlert { inappropriate, disclosure }

/// Single words (as the recogniser writes them, without niqqud) that are swearing.
const List<String> inappropriateWords = <String>[
  'חרא',
  'זין',
  'מזדיין',
  'מזדיינת',
  'תזדיין',
  'זונה',
  'שרמוטה',
  'מניאק',
];

/// Phrases a child might say when something is wrong at home or with them. Each is a run of words.
const List<String> disclosurePhrases = <String>[
  'מכים אותי',
  'מכה אותי',
  'מרביצים לי',
  'מרביץ לי',
  'מרביצה לי',
  'נגעו בי',
  'נוגעים בי',
  'מאיימים עלי',
  'מאיים עלי',
  'מפחידים אותי',
  'פוחד לחזור הביתה',
  'פוחדת לחזור הביתה',
  'אני לבד בבית',
  'אני רוצה למות',
  'לא רוצה לחיות',
];

/// True if the tokens contain the phrase's tokens one after the other.
bool _hasRun(List<String> tokens, List<String> phrase) {
  for (int i = 0; i + phrase.length <= tokens.length; i++) {
    bool all = true;
    for (int j = 0; j < phrase.length && all; j++) {
      all = tokens[i + j] == phrase[j];
    }
    if (all) return true;
  }
  return false;
}

/// What, if anything, the recogniser's [texts] (all its hypotheses for one answer) set off. A worrying disclosure wins
/// over swearing.
WordAlert? checkWords(Iterable<String> texts) {
  final Set<String> swear = <String>{for (final String w in inappropriateWords) normalizeHebrew(w)};
  final List<List<String>> phrases = <List<String>>[
    for (final String p in disclosurePhrases) tokensOf(normalizeHebrew(p)),
  ];
  bool swore = false;
  for (final String text in texts) {
    final List<String> tokens = tokensOf(normalizeHebrew(text));
    for (final List<String> p in phrases) {
      if (_hasRun(tokens, p)) return WordAlert.disclosure;
    }
    if (tokens.any(swear.contains)) swore = true;
  }
  return swore ? WordAlert.inappropriate : null;
}
