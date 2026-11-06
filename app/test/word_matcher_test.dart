import 'dart:io';
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/speech/word_matcher.dart';

const WordMatcher matcher = WordMatcher();

SayResult english(
  List<String> heard,
  List<String> forms,
  List<String> foils, {
  List<String> keys = const <String>[],
}) => matcher.decide(heard, WordTarget(course: 'eng', forms: forms, foils: foils, keyWords: keys)).result;

SayResult russian(List<String> heard, List<String> forms, List<String> foils) =>
    matcher.decide(heard, WordTarget(course: 'rus', forms: forms, foils: foils)).result;

/// An independent oracle for 5-letter words: whether [a] is [b] or one edit away (similarity 0.8 or more).
bool withinOneEdit(String a, String b) {
  if ((a.length - b.length).abs() > 1) return false;
  if (a == b) return true;
  if (a.length == b.length) {
    int diff = 0;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) diff++;
    }
    return diff == 1;
  }
  final String longer = a.length > b.length ? a : b;
  final String shorter = a.length > b.length ? b : a;
  for (int i = 0; i < longer.length; i++) {
    if (longer.substring(0, i) + longer.substring(i + 1) == shorter) return true;
  }
  return false;
}

void main() {
  group('English: the target against its foils', () {
    const List<String> cat = <String>['cat', 'a cat'];
    const List<String> foils = <String>['cut', 'hat'];

    test('the word, the word in a phrase, and a listed variant are confident', () {
      expect(english(<String>['cat'], cat, foils), SayResult.confident);
      expect(english(<String>['A CAT'], cat, foils), SayResult.confident);
      expect(english(<String>['the cat sat'], cat, foils), SayResult.confident);
    });

    test('a foil said clearly, or a word that is only near, is unsure and never anything else', () {
      expect(english(<String>['cut'], cat, foils), SayResult.unsure);
      expect(english(<String>['hat'], cat, foils), SayResult.unsure);
      expect(english(<String>['cot'], cat, foils), SayResult.unsure);
      expect(english(<String>['xyz'], cat, foils), SayResult.unsure);
    });

    test('the target and a foil together cannot be told apart: unsure', () {
      expect(english(<String>['cat cut'], cat, foils), SayResult.unsure);
    });

    test('nothing recognised is silence, including text with no letters', () {
      expect(english(<String>[], cat, foils), SayResult.silence);
      expect(english(<String>['', '   '], cat, foils), SayResult.silence);
      expect(english(<String>['... 123'], cat, foils), SayResult.silence);
    });

    test('a minimal pair: wet said is confident for wet, vet said is not', () {
      expect(english(<String>['wet'], <String>['wet'], <String>['vet']), SayResult.confident);
      expect(english(<String>['vet'], <String>['wet'], <String>['vet']), SayResult.unsure);
    });

    test('an apostrophe changes nothing, and a foil that is a form of the target is not a foil', () {
      expect(english(<String>["DON'T"], <String>['dont'], <String>['do']), SayResult.confident);
      expect(english(<String>['cat'], <String>['cat'], <String>['cat', 'dog']), SayResult.confident);
    });

    test('a chunk is confident only when every key word is, each clear of the foils', () {
      const List<String> chunk = <String>["I'm happy"];
      const List<String> other = <String>['sad', 'fine'];
      expect(english(<String>["i'm happy"], chunk, other, keys: <String>['happy']), SayResult.confident);
      expect(english(<String>['i am happy'], chunk, other, keys: <String>['happy']), SayResult.confident);
      expect(english(<String>['im sad'], chunk, other, keys: <String>['happy']), SayResult.unsure);
      expect(english(<String>['happy sad'], chunk, other, keys: <String>['happy']), SayResult.unsure);
      expect(
        english(<String>['I am happy and fine'], chunk, <String>['sad'], keys: <String>['happy', 'fine']),
        SayResult.confident,
      );
      expect(
        english(<String>['I am happy'], chunk, <String>['sad'], keys: <String>['happy', 'fine']),
        SayResult.unsure,
      );
    });

    test('the second reading counts too: the best of the two decides', () {
      expect(english(<String>['kat', 'cat'], cat, foils), SayResult.confident);
    });
  });

  group('Russian: ё is е, stress and case do not matter, the minimal pairs hold', () {
    test('ё read as е, a stress mark on the item, capital letters', () {
      expect(russian(<String>['ЕЖ'], <String>['ёж'], const <String>[]), SayResult.confident);
      expect(russian(<String>['мама'], <String>['ма́ма'], <String>['папа']), SayResult.confident);
    });

    test('лук and люк: each said clearly is confident for itself and unsure for the other', () {
      const String luk = 'лук';
      const String lyuk = 'люк';
      expect(russian(<String>[luk], <String>[luk], <String>[lyuk]), SayResult.confident);
      expect(russian(<String>[lyuk], <String>[luk], <String>[lyuk]), SayResult.unsure);
      expect(russian(<String>[lyuk], <String>[lyuk], <String>[luk]), SayResult.confident);
    });

    test('a listed variant (мячик for мяч) is the target too', () {
      const String myach = 'мяч';
      const String myachik = 'мячик';
      expect(russian(<String>[myachik], <String>[myach, myachik], const <String>[]), SayResult.confident);
    });

    test('Latin letters in the reading of a Russian item are not words', () {
      expect(russian(<String>['cat'], <String>['кот'], const <String>[]), SayResult.silence);
    });
  });

  group('Hebrew keeps the Hebrew text rules', () {
    test('the word without niqqud is confident; its minimal pair is not', () {
      final WordTarget t = WordTarget(course: 'heb', forms: <String>['כֶּלֶב'], foils: <String>['חָלָב']);
      expect(matcher.decide(<String>['כלב'], t).result, SayResult.confident);
      expect(matcher.decide(<String>['חלב'], t).result, SayResult.unsure);
    });
  });

  group('the false-confident property', () {
    test('20,000 random strings: confident only when a word is within one edit of the target and clear of its foils', () {
      final math.Random rnd = math.Random(5);
      const List<String> forms = <String>['apple'];
      const List<String> foils = <String>['ample', 'maple'];
      int confidentCount = 0;
      for (int n = 0; n < 20000; n++) {
        final String text = <String>[
          for (int w = 0; w < 1 + rnd.nextInt(4); w++)
            String.fromCharCodes(<int>[
              for (int i = 0; i < 1 + rnd.nextInt(8); i++)
                97 + (rnd.nextInt(6) == 0 ? rnd.nextInt(26) : 'aplem'.codeUnitAt(rnd.nextInt(5)) - 97),
            ]),
        ].join(' ');
        final SayResult r = english(<String>[text], forms, foils);
        if (r == SayResult.confident) {
          confidentCount++;
          final List<String> tokens = text.split(' ');
          expect(tokens.any((String t) => withinOneEdit(t, 'apple')), isTrue, reason: text);
          // A foil said as it is can never be beaten by the target: no confident text holds one.
          expect(tokens.contains('ample') || tokens.contains('maple'), isFalse, reason: text);
        }
      }
      expect(confidentCount, greaterThan(0), reason: 'the property is not vacuous');
    });

    test('300 random sequences of foils, other words and noise are never confident for the target', () {
      final math.Random rnd = math.Random(11);
      const List<String> pool = <String>[
        'ample',
        'maple',
        'pear',
        'um',
        'the',
        'red',
        'amply',
        'ape',
        'pale',
      ];
      for (int n = 0; n < 300; n++) {
        final String text = <String>[
          for (int i = 0; i < 1 + rnd.nextInt(6); i++) pool[rnd.nextInt(pool.length)],
        ].join(' ');
        expect(
          english(<String>[text], <String>['apple'], <String>['ample', 'maple']),
          isNot(SayResult.confident),
          reason: text,
        );
      }
    });

    test('silence and noise are never confident whatever the item', () {
      for (final String noise in <String>['', ' ', 'mm', 'uh', 'shh', 'k', 'ssss']) {
        expect(
          english(<String>[noise], <String>['yes'], <String>['no', 'go']),
          isNot(SayResult.confident),
          reason: noise,
        );
      }
    });
  });

  group('the quiet fallback', () {
    test('three turns at least; more than 60% unsure switches the rest of the visit to echo', () {
      final QuietFallback q = QuietFallback();
      q.record(SayResult.unsure);
      q.record(SayResult.unsure);
      expect(q.echoOnly, isFalse, reason: 'two turns say too little');
      q.record(SayResult.unsure);
      expect(q.echoOnly, isTrue);
    });

    test(
      'a child who is heard in half the turns keeps the microphone; silence is not a failure of the model',
      () {
        final QuietFallback q = QuietFallback();
        for (final SayResult r in <SayResult>[
          SayResult.confident,
          SayResult.unsure,
          SayResult.silence,
          SayResult.silence,
          SayResult.confident,
          SayResult.unsure,
        ]) {
          q.record(r);
        }
        expect(q.echoOnly, isFalse);
      },
    );
  });

  test(
    'the matcher\'s source has no wrong or correct vocabulary: only confident, unsure and silence exist',
    () {
      final String src = File('lib/speech/word_matcher.dart').readAsStringSync();
      final String code = src.split('\n').where((String l) => !l.trimLeft().startsWith('//')).join('\n');
      expect(SayResult.values.map((SayResult v) => v.name).toList(), <String>[
        'confident',
        'unsure',
        'silence',
      ]);
      expect(
        RegExp(
          r'\b(wrong|incorrect|correct|mistake|error|fail)\w*',
          caseSensitive: false,
        ).hasMatch(code.replaceAll(RegExp(r'///.*'), '')),
        isFalse,
      );
    },
  );
}
