// The words that W1 (`metBeforeAsked` in `arc_checks.dart`) accepts without a Show teaching them: language data for the check of the pack, not text a
// child sees (the Hebrew-text rule of `test/source_rules_m1_test.dart` names this file, as it names the matcher's word lists).

/// W1 exceptions (M11-stage2 section 11.4), as data. A label is accepted without the Show teaching it when it is a yes or a no, a "not" before a word
/// that is known, or a counting word alone or before a known word: from one to ten for a skill whose prerequisites hold [w1CountingSkill] (NUM-A-02,
/// counting to ten), from one to five for one that holds only [w1CountingFiveSkill] (NUM-A-01). Two-year-olds understand "no" and "not" before a known
/// noun, and the bin shows a crossed picture; the counting words are taught in Counting Hills.
const Set<String> w1YesNo = <String>{'כן', 'לא'};
const String w1Not = 'לא';
const String w1CountingSkill = 'NUM-A-02';
const String w1CountingFiveSkill = 'NUM-A-01';

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
};

/// The counting words from one to ten, both genders.
const Set<String> w1CountingWords = <String>{
  ...w1CountingWordsToFive,
  'שש',
  'שישה',
  'שבע',
  'שבעה',
  'שמונה',
  'תשע',
  'תשעה',
  'עשר',
  'עשרה',
};

// ---- the two provisional rules (the lead's, 2026-11-16; the owner is to confirm them): each is one switch, and one named function ----

/// A label is accepted when every word of it is a word that a Show of the skill, or of an earlier skill, already teaches (a phrase made of known words:
/// "light blue" when "light" and "blue" are both taught). Provisional: set to false to ask the Show for every whole label again.
const bool w1AcceptKnownWords = true;

/// A label is accepted when it names the thing drawn on the card it labels: the card's picture is an everyday object ([w1NamesCardObject]), so its
/// label is that object's name and teaches nothing new ("apple" under an apple). Provisional: set to false to check these labels as the rest.
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
