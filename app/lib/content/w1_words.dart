// The words that W1 (`metBeforeAsked` in `arc_checks.dart`) accepts without a Show teaching them: language data for the check of the pack, not text a
// child sees (the Hebrew-text rule of `test/source_rules_m1_test.dart` names this file, as it names the matcher's word lists).

/// W1 exceptions (M11-stage2 section 11.4), as data. A label is accepted without the Show teaching it when it is a yes or a no, a "not" before a word
/// that is known, or a counting word alone or before a known word. Each counting skill sets the range of the number words that are accepted
/// ([w1CountingRanges]): one to five for NUM-A-01, to ten for NUM-A-02, to twenty for NUM-B-01, to thirty for NUM-B-02, to a hundred for NUM-C-01 (the owner
/// approved this on 2026-11-16: a child who counts to that number knows its word). Two-year-olds understand "no" and "not" before a known noun, and the
/// bin shows a crossed picture; the counting words are taught in Counting Hills.
const Set<String> w1YesNo = <String>{'כן', 'לא'};
const String w1Not = 'לא';

/// The counting words from one to five, both genders.
const Set<String> w1CountingWordsToFive = <String>{
  'אחד',
  'אחת',
  'שניים',
  'שתיים',
  'שנים',
  'שתים',
  'שני',
  'שתי',
  'שלוש',
  'שלושה',
  'ארבע',
  'ארבעה',
  'חמש',
  'חמישה',
  'חמשה',
};

/// The counting words from one to ten, both genders.
const Set<String> w1CountingWords = <String>{
  ...w1CountingWordsToFive,
  'שש',
  'שישה',
  'ששה',
  'שבע',
  'שבעה',
  'שמונה',
  'תשע',
  'תשעה',
  'עשר',
  'עשרה',
};

/// The words of eleven to nineteen are a unit word and "ten" ("שלושה עשר"), so each is in [w1CountingWords]; twenty is one more.
const Set<String> w1CountingWordsToTwenty = <String>{...w1CountingWords, 'עשרים'};

/// The tens, and "hundred".
const Set<String> w1CountingTens = <String>{
  'עשרים',
  'שלושים',
  'ארבעים',
  'חמישים',
  'שישים',
  'שבעים',
  'ששים',
  'חמשים',
  'שמונים',
  'תשעים',
  'מאה',
};

/// A skill that counts to a number, and the counting words a skill that holds it as a prerequisite (or is it) is given: the widest one wins.
const List<({String skill, Set<String> words})> w1CountingRanges = <({String skill, Set<String> words})>[
  (skill: 'NUM-C-01', words: <String>{...w1CountingWords, ...w1CountingTens}),
  (skill: 'NUM-B-02', words: <String>{...w1CountingWordsToTwenty, 'שלושים'}),
  (skill: 'NUM-B-01', words: w1CountingWordsToTwenty),
  (skill: 'NUM-A-02', words: w1CountingWords),
  (skill: 'NUM-A-01', words: w1CountingWordsToFive),
];

/// The counting words a skill is given, from the skills it holds ([known], itself included), or none.
Set<String> w1CountingWordsOf(Set<String> known) {
  for (final ({String skill, Set<String> words}) r in w1CountingRanges) {
    if (known.contains(r.skill)) return r.words;
  }
  return const <String>{};
}

/// Sequences: words that come as a set (the days of the week, the steps of a thing done in order, the parts of a day, the seasons). A Show that teaches
/// one member of a sequence teaches the set: a child who has met "Sunday" and "Monday" in order has met "Tuesday", and a card that says "first" has the
/// others "next" and "last" beside it (the owner approved this on 2026-11-16).
const List<Set<String>> w1Sequences = <Set<String>>[
  <String>{'ראשון', 'שני', 'שלישי', 'רביעי', 'חמישי', 'שישי', 'ששי', 'שבת', 'יום'},
  <String>{
    'ראשון',
    'ראשונה',
    'שני',
    'שנייה',
    'שלישי',
    'שלישית',
    'רביעי',
    'רביעית',
    'אחרון',
    'אחרונה',
    'אחר',
    'כך',
    'אחרי',
    'לפני',
    'קודם',
    'בסוף',
    'בהתחלה',
    'ואז',
    'לבסוף',
    'תחילה',
    'אחר-כך',
  },
  <String>{'בוקר', 'צהריים', 'אחר', 'הצהריים', 'ערב', 'לילה'},
  <String>{'קיץ', 'חורף', 'אביב', 'סתיו'},
];

/// Whether [w] is one of the counting [words], or one of them with the "and" of a longer number before it ("twenty and three").
bool w1IsCounting(Set<String> words, String w) =>
    words.contains(w) || (w.startsWith(w1And) && words.contains(w.substring(1)));

const String w1And = 'ו';

/// The set of words that the words [taught] open: all of every sequence in which one of them stands.
Set<String> w1SequenceWords(Set<String> taught) => <String>{
  for (final Set<String> seq in w1Sequences)
    if (taught.any(seq.contains)) ...seq,
};

// ---- the two rules the owner confirmed (2026-11-16): each is one switch, and one named function ----

/// A label is accepted when every word of it is a word that a Show of the skill, or of an earlier skill, already teaches (a phrase made of known words:
/// "light blue" when "light" and "blue" are both taught). Set to false to ask the Show for every whole label again.
const bool w1AcceptKnownWords = true;

/// A label is accepted when it names the thing drawn on the card it labels: the card's picture is an everyday object ([w1NamesCardObject]), so its
/// label is that object's name and teaches nothing new ("apple" under an apple), and inside a longer label that object's name counts as a known word
/// ("three apples" under apples: one word of the label is the object). Set to false to check these labels as the rest.
const bool w1AcceptCardObjectName = true;

/// The parts of a picture's name that make it more than an object: a colour or a shade, a shape, a size, a number, a day, a mark or a stage of a thing.
/// A picture with one of them in its name (`ball_red`, `shade_blue_2`, `shape_circle`) is what its label teaches, not an everyday object.
const Set<String> w1NotAnObject = <String>{
  'red',
  'orange',
  'yellow',
  'green',
  'blue',
  'purple',
  'pink',
  'brown',
  'black',
  'white',
  'grey',
  'gray',
  'light',
  'dark',
  'shade',
  'shape',
  'circle',
  'square',
  'rect',
  'triangle',
  'oval',
  'trapezoid',
  'pentagon',
  'hexagon',
  'solid',
  'size',
  'big',
  'small',
  'tall',
  'short',
  'long',
  'day',
  'time',
  'tower',
  'strip',
  'step',
  'pos',
  'tick',
  'cross',
  'dot',
  'dice',
  'coin',
};

/// Whether the card picture [sprite] (`asset:apple`) is an everyday object, whose label only names it ([w1AcceptCardObjectName]).
bool w1NamesCardObject(String? sprite) {
  if (sprite == null || !sprite.startsWith('asset:')) return false;
  final List<String> parts = sprite.substring('asset:'.length).split('_');
  return !parts.any((String p) => w1NotAnObject.contains(p) || int.tryParse(p) != null);
}
