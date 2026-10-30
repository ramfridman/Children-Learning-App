// What each option of a choice answers to, by voice. Pure Dart: the lesson and the pack validator use the same rule, so a
// pack can only promise a spoken answer that the lesson can hear.
import 'answer_matcher.dart';
import 'hebrew_text.dart';
import 'lexicon.dart';

/// One option of a choice as voice sees it: a number, or a label with the author's own words for it.
class SpokenOption {
  const SpokenOption(this.id, {this.number, this.label = '', this.speech = const <String>[]});

  final String id;
  final int? number;
  final String label;
  final List<String> speech;

  /// Every word of the label and of the author's list, normalised.
  List<String> get allWords => <String>[
    ...tokensOf(normalizeHebrew(label)),
    for (final String s in speech) ...tokensOf(normalizeHebrew(s)),
  ];
}

/// What each option answers to. A number by its number words; any other option by the author's `speech` words and the
/// words of its label that no other option has ("פרח אדום" and "פרח צהוב" are told apart by the colour, and in "שבת",
/// "יום ראשון", "יום שישי" the word "יום" tells nothing). A label word also answers to the everyday word a child knows for
/// it ([labelSynonyms]: "קופסה" for "תֵּבָה").
List<Expected> expectedFor(List<SpokenOption> options, {required String correctId}) {
  final List<Set<String>> words = <Set<String>>[
    for (final SpokenOption o in options)
      <String>{
        ...o.speech,
        for (final String w in tokensOf(normalizeHebrew(o.label))) ...<String>[w, ...labelSynonyms(w)],
      },
  ];
  final Map<String, int> owners = <String, int>{};
  for (final Set<String> w in words) {
    for (final String x in w) {
      owners[x] = (owners[x] ?? 0) + 1;
    }
  }
  return <Expected>[
    for (final (int i, SpokenOption o) in options.indexed)
      if (o.number != null)
        Expected.number(o.id, o.number!, correct: o.id == correctId, also: o.speech)
      else
        Expected.words(o.id, <String>[
          for (final String w in words[i])
            if (owners[w] == 1 || o.speech.contains(w)) w,
        ], correct: o.id == correctId),
  ];
}
