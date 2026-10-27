// The words the matcher expects, written the way a recogniser spells them: without niqqud, final letters folded.
// Every list is plain data; `hebrew_text` of the plan grows here as the content grows.
import 'hebrew_text.dart';

/// A word that is accepted for an answer. A soft word is a near miss (תכלת for כחול): it can only lead to a confirm.
class AcceptWord {
  const AcceptWord(this.text, {this.soft = false});

  /// Normalised (see [normalizeHebrew]).
  final String text;
  final bool soft;
}

const List<String> _numberFeminine = <String>[
  'אפס', 'אחת', 'שתיים', 'שלוש', 'ארבע', 'חמש', 'שש', 'שבע', 'שמונה', 'תשע', 'עשר', //
];

const List<String> _numberMasculine = <String>[
  'אפס', 'אחד', 'שניים', 'שלושה', 'ארבעה', 'חמישה', 'שישה', 'שבעה', 'שמונה', 'תשעה', 'עשרה', //
];

// The forms that stand before a noun ("שלושת הפרפרים", "שני פרפרים").
const Map<int, List<String>> _numberConstruct = <int, List<String>>{
  2: <String>['שני', 'שתי', 'שנים', 'שתים'],
  3: <String>['שלושת'],
  4: <String>['ארבעת'],
  5: <String>['חמשת'],
  6: <String>['ששת'],
  7: <String>['שבעת'],
  8: <String>['שמונת'],
  9: <String>['תשעת'],
  10: <String>['עשרת'],
};

/// Every accepted spelling of the number [n] (0 to 20), both genders, the construct forms, and the digits.
List<AcceptWord> numberWords(int n) {
  final Set<String> out = <String>{'$n'};
  if (n >= 0 && n <= 10) {
    out
      ..add(normalizeHebrew(_numberFeminine[n]))
      ..add(normalizeHebrew(_numberMasculine[n]))
      ..addAll(_numberConstruct[n] ?? const <String>[]);
    if (n == 2) out.addAll(<String>['שתים', 'שנים']);
  } else if (n >= 11 && n <= 19) {
    final int u = n - 10;
    // Feminine: "אחת עשרה"; masculine: "אחד עשר"; people say both, and drop the gender of the ten.
    out
      ..add('${normalizeHebrew(_numberFeminine[u])} עשרה')
      ..add('${normalizeHebrew(_numberMasculine[u])} עשר')
      ..add('${normalizeHebrew(_numberFeminine[u])} עשר')
      ..add('${normalizeHebrew(_numberMasculine[u])} עשרה');
    if (u == 2) out.addAll(<String>['שתים עשרה', 'שנים עשר']);
  } else if (n == 20) {
    out.add('עשרים');
  }
  return <AcceptWord>[for (final String w in out) AcceptWord(normalizeHebrew(w))];
}

const Map<String, List<String>> _colours = <String, List<String>>{
  'red': <String>['אדום', 'אדומה', 'אדומים', 'אדומות'],
  'blue': <String>['כחול', 'כחולה', 'כחולים', 'כחולות'],
  'yellow': <String>['צהוב', 'צהובה', 'צהובים', 'צהובות'],
  'green': <String>['ירוק', 'ירוקה', 'ירוקים', 'ירוקות'],
  'orange': <String>['כתום', 'כתומה', 'כתומים', 'כתומות'],
  'purple': <String>['סגול', 'סגולה', 'סגולים', 'סגולות'],
  'pink': <String>['ורוד', 'ורודה', 'ורודים', 'ורודות'],
  'brown': <String>['חום', 'חומה', 'חומים', 'חומות'],
  'black': <String>['שחור', 'שחורה', 'שחורים', 'שחורות'],
  'white': <String>['לבן', 'לבנה', 'לבנים', 'לבנות'],
};

// Near misses: a recogniser or a child may give the neighbour; the neighbour never counts, it only asks "did you mean?".
const Map<String, List<String>> _colourSoft = <String, List<String>>{
  'blue': <String>['תכלת', 'כחלחל'],
  'purple': <String>['סגלגל'],
  'orange': <String>['כתמתם'],
};

/// The ids of the colours the lexicon knows.
Iterable<String> get colourIds => _colours.keys;

List<AcceptWord> colourWords(String id) {
  final List<String>? forms = _colours[id];
  if (forms == null) return const <AcceptWord>[];
  return <AcceptWord>[
    for (final String w in forms) AcceptWord(normalizeHebrew(w)),
    for (final String w in _colourSoft[id] ?? const <String>[]) AcceptWord(normalizeHebrew(w), soft: true),
  ];
}

/// What a child may say that is not an answer.
enum Intent { repeat, help, stop, yes, no }

const Map<Intent, List<String>> _intentPhrases = <Intent, List<String>>{
  Intent.repeat: <String>['עוד פעם', 'שוב', 'מה', 'עוד פעם בבקשה', 'אפשר שוב'],
  Intent.help: <String>[
    'לא יודע',
    'לא יודעת',
    'עזרה',
    'תעזור לי',
    'תעזרי לי',
    'עזור לי',
    'עזרי לי',
    'לא בטוח',
    'לא בטוחה',
    'אני לא יודע',
    'אני לא יודעת',
  ],
  Intent.stop: <String>['די', 'מספיק', 'עצור', 'תפסיק', 'תפסיקי', 'אני רוצה לעצור'],
  Intent.yes: <String>['כן', 'נכון', 'ברור', 'בטח', 'כן כן'],
  Intent.no: <String>['לא', 'לא נכון', 'טעות', 'לא לא'],
};

/// The normalised phrases of an intent.
List<String> intentPhrases(Intent i) => <String>[
  for (final String p in _intentPhrases[i]!) normalizeHebrew(p),
];
