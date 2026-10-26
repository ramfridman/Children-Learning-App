import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/speech/answer_matcher.dart';
import 'package:nitznutz/speech/hebrew_text.dart';
import 'package:nitznutz/speech/lexicon.dart';

const AnswerMatcher matcher = AnswerMatcher();

/// Options for the numbers [values]; [right] is the correct one.
List<Expected> numbers(List<int> values, int right) => <Expected>[
  for (final int v in values) Expected.number('o$v', v, correct: v == right),
];

MatchResult heard(String text, List<Expected> options, {double confidence = 0.9}) =>
    matcher.decide(<Hypothesis>[Hypothesis(text, confidence)], options);

void main() {
  group('normalising', () {
    test('strips niqqud and cantillation, folds final letters, drops punctuation', () {
      expect(normalizeHebrew('שָׁלוֹשׁ!'), 'שלוש');
      expect(normalizeHebrew('  שְׁלוֹשָׁה,   פְּרָפָרִים. '), 'שלושה פרפרימ');
      expect(normalizeHebrew('סוף ךםןףץ'), 'סופ כמנפצ');
      expect(normalizeHebrew('אחד-עשר'), 'אחד עשר');
      expect(normalizeHebrew('3 Butterflies'), '3 butterflies');
      expect(normalizeHebrew('...'), '');
    });

    test('words that sound alike share a key; words that do not, do not', () {
      expect(phoneticKey('שלוש'), phoneticKey('שלוס'));
      expect(phoneticKey('שלוש'), phoneticKey('שלושה'));
      expect(phoneticKey('שבע'), phoneticKey('שבעה'));
      expect(phoneticKey('שתיים'), phoneticKey('שתים'));
      expect(phoneticKey('שבע'), isNot(phoneticKey('שש')));
      expect(similarity('שלוש', 'שלוש'), 1);
      expect(similarity('שלוש', 'שלוס'), lessThan(1));
      expect(similarity('שלוש', 'שלוס'), greaterThan(0.9));
    });
  });

  group('the numbers 1 to 10 in every form', () {
    final List<int> all = <int>[for (int i = 1; i <= 10; i++) i];

    test('different numbers never sound alike enough to be taken for each other', () {
      for (final int a in all) {
        for (final int b in all) {
          if (a >= b) continue;
          for (final AcceptWord x in numberWords(a)) {
            for (final AcceptWord y in numberWords(b)) {
              if (isDigits(x.text) || isDigits(y.text)) continue;
              expect(
                similarity(x.text, y.text),
                lessThan(0.75),
                reason: '$a "${x.text}" and $b "${y.text}" sound too alike',
              );
            }
          }
        }
      }
    });

    for (final int n in all) {
      test('every spelling of $n is accepted, with and without niqqud, prefixes and a noun', () {
        final List<Expected> options = numbers(<int>{math.max(1, n - 1), n, math.min(10, n + 1)}.toList(), n);
        for (final AcceptWord w in numberWords(n)) {
          for (final String said in <String>[w.text, '${w.text} פרפרים', 'ו${w.text}', 'ה${w.text} של']) {
            final MatchResult r = heard(said, options);
            expect(r.decision, Decision.accept, reason: '"$said" for $n: $r');
            expect(r.optionId, 'o$n', reason: '"$said"');
          }
        }
      });
    }

    test('a spoken digit is exact', () {
      final List<Expected> options = numbers(<int>[2, 3, 4], 3);
      expect(heard('3', options).optionId, 'o3');
      expect(heard('3', options).decision, Decision.accept);
      expect(heard('5', options).decision, Decision.retry);
    });

    test('child pronunciations are accepted', () {
      final List<Expected> options = numbers(<int>[2, 3, 4], 3);
      for (final String said in <String>['שלוס', 'שלוש', 'שלושה', 'סלוש']) {
        expect(heard(said, options).decision, Decision.accept, reason: said);
      }
    });

    test('the numbers 11 to 20 are accepted as pairs of words', () {
      final List<Expected> options = <Expected>[
        Expected.number('a', 12, correct: false),
        Expected.number('b', 13, correct: true),
        Expected.number('c', 20, correct: false),
      ];
      expect(heard('שלושה עשר', options).optionId, 'b');
      expect(heard('שלוש עשרה', options).decision, Decision.accept);
      expect(heard('עשרים', options).decision, Decision.confirm); // 20 is a wrong option here
      expect(heard('עשרים', options).optionId, 'c');
    });
  });

  group('wrong answers are never taken on a spoken word alone', () {
    test('a clear wrong answer asks "did you say...?" first', () {
      final List<Expected> options = numbers(<int>[2, 3, 4], 3);
      final MatchResult r = heard('ארבע', options, confidence: 0.99);
      expect(r.decision, Decision.confirm);
      expect(r.why, Why.wrongNeedsConfirm);
      expect(r.optionId, 'o4');
    });

    test('whatever is said, an accepted answer is always the right one', () {
      final math.Random random = math.Random(5);
      const String letters = 'אבגדהוזחטיכלמנסעפצקרשת';
      final List<Expected> options = numbers(<int>[1, 2, 3, 4, 5], 3);
      int acceptedRight = 0;
      for (int i = 0; i < 20000; i++) {
        final String said = <String>[
          for (int w = 0; w < 1 + random.nextInt(3); w++)
            String.fromCharCodes(<int>[
              for (int c = 0; c < 1 + random.nextInt(7); c++)
                letters.codeUnitAt(random.nextInt(letters.length)),
            ]),
        ].join(' ');
        final MatchResult r = heard(said, options, confidence: random.nextDouble());
        if (r.decision == Decision.accept && r.intent == null) {
          expect(r.optionId, 'o3', reason: '"$said" was accepted as $r');
          acceptedRight++;
        }
      }
      // Nonsense is almost never taken for the right answer either.
      expect(acceptedRight, lessThan(200), reason: '$acceptedRight of 20000 nonsense strings were accepted');
    });
  });

  group('unclear speech is never an answer', () {
    final List<Expected> options = numbers(<int>[2, 3, 4], 3);

    test('silence, empty text and punctuation are "no speech"', () {
      for (final String said in <String>['', '   ', '...', '!?']) {
        expect(heard(said, options).decision, Decision.noSpeech, reason: '"$said"');
      }
      expect(matcher.decide(const <Hypothesis>[], options).decision, Decision.noSpeech);
    });

    test('words that are not answers ask again', () {
      for (final String said in <String>['פרפר', 'אני רוצה גלידה', 'בננה', 'מה השעה']) {
        expect(heard(said, options).decision, anyOf(Decision.retry, Decision.confirm), reason: said);
        expect(heard(said, options).decision, isNot(Decision.accept), reason: said);
      }
    });

    test(
      'a low confidence turns a perfect word into a "did you say...?", and a very low one into "ask again"',
      () {
        expect(heard('שלוש', options, confidence: 0.35).decision, Decision.confirm);
        expect(heard('שלוש', options, confidence: 0.1).decision, Decision.retry);
        expect(heard('שלוש', options, confidence: 0.9).decision, Decision.accept);
      },
    );

    test('"not three" is not "three"', () {
      expect(heard('לא שלוש', options).decision, Decision.retry);
      expect(heard('לא שלוש', options).why, Why.negated);
    });

    test('a close call between two answers is checked, not guessed', () {
      final List<Expected> close = <Expected>[
        Expected.words('a', <String>['שלוש'], correct: true),
        Expected.words('b', <String>['שלוס'], correct: false),
      ];
      // Two options that sound the same cannot be told apart by ear: the app asks.
      expect(heard('שלוש', close).decision, Decision.confirm);
      expect(heard('שלוש', close).why, Why.closeCall);
      final MatchResult r = heard('שלוש', <Expected>[
        Expected.words('a', <String>['שלושה'], correct: true),
        Expected.words('b', <String>['שלוסה'], correct: true),
      ]);
      expect(r.decision, Decision.confirm);
      expect(r.why, Why.closeCall);
    });

    test('the next best reading is used when the first is garbage', () {
      final MatchResult r = matcher.decide(const <Hypothesis>[
        Hypothesis('גלגלים', 0.9),
        Hypothesis('שלוש', 0.8),
      ], options);
      expect(r.decision, Decision.accept);
      expect(r.optionId, 'o3');
    });
  });

  group('colours', () {
    final List<Expected> colours = <Expected>[
      Expected.colour('red', 'red', correct: false),
      Expected.colour('blue', 'blue', correct: true),
      Expected.colour('yellow', 'yellow', correct: false),
    ];

    test('every gender and number form is accepted', () {
      for (final String said in <String>[
        'כחול',
        'כחולה',
        'כחולים',
        'כחולות',
        'הכחול',
        'וכחול',
        'כחול בהיר',
      ]) {
        final MatchResult r = heard(said, colours);
        expect(r.decision, Decision.accept, reason: said);
        expect(r.optionId, 'blue', reason: said);
      }
    });

    test('a near miss only asks "did you mean...?"', () {
      final MatchResult r = heard('תכלת', colours, confidence: 1);
      expect(r.decision, Decision.confirm);
      expect(r.why, Why.softMatch);
      expect(r.optionId, 'blue');
    });

    test('a wrong colour is confirmed, not counted', () {
      final MatchResult r = heard('אדום', colours);
      expect(r.decision, Decision.confirm);
      expect(r.optionId, 'red');
    });
  });

  group('what a child may say instead of an answer', () {
    final List<Expected> options = numbers(<int>[2, 3, 4], 3);

    test('again, help and stop are heard as intents', () {
      expect(heard('עוד פעם', options).intent, Intent.repeat);
      expect(heard('שוב', options).intent, Intent.repeat);
      expect(heard('לא יודע', options).intent, Intent.help);
      expect(heard('אני לא יודעת', options).intent, Intent.help);
      expect(heard('עזרה', options).intent, Intent.help);
      expect(heard('די', options).intent, Intent.stop);
      expect(heard('עזרה', options).decision, Decision.accept);
    });

    test('an answer that sounds like an intent is still an answer when it is spelled as the answer', () {
      // "שוב" (again) and "שבע" (seven) share their sounds; the spelling decides.
      final List<Expected> sevens = numbers(<int>[6, 7, 8], 7);
      expect(heard('שבע', sevens).intent, isNull);
      expect(heard('שבע', sevens).optionId, 'o7');
      expect(heard('שוב', sevens).intent, Intent.repeat);
    });

    test('"yes" and "no" answer "did you say...?"', () {
      expect(matcher.confirmation(const <Hypothesis>[Hypothesis('כן', 0.9)]), Intent.yes);
      expect(matcher.confirmation(const <Hypothesis>[Hypothesis('נכון', 0.9)]), Intent.yes);
      expect(matcher.confirmation(const <Hypothesis>[Hypothesis('כן כן', 0.9)]), Intent.yes);
      expect(matcher.confirmation(const <Hypothesis>[Hypothesis('לא', 0.9)]), Intent.no);
      expect(matcher.confirmation(const <Hypothesis>[Hypothesis('לא נכון', 0.9)]), Intent.no);
      expect(matcher.confirmation(const <Hypothesis>[Hypothesis('שלוש', 0.9)]), isNull);
      expect(matcher.confirmation(const <Hypothesis>[Hypothesis('כן', 0.2)]), isNull);
      expect(matcher.confirmation(const <Hypothesis>[]), isNull);
    });
  });

  test('authors can give an option its own words', () {
    final List<Expected> options = <Expected>[
      Expected.words('flower', <String>['פֶּרַח', 'פרחים'], correct: true),
      Expected.words('tree', <String>['עֵץ'], correct: false),
    ];
    expect(heard('הפרח', options).optionId, 'flower');
    expect(heard('הפרח', options).decision, Decision.accept);
    expect(heard('עץ', options).decision, Decision.confirm);
  });
}
