// The word lists of the parent's alerts, against the test list of the child-safety review
// (docs/child-safety/alert-test-list.md): what must be an act (tier 1), a check (2) or a note (3), what must set off
// nothing, and how ages, hypotheses, prefixes, idioms and fillers change it. Row numbers are the list's.
import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/speech/alert_lists.dart';
import 'package:nitznutz/speech/alert_words.dart';
import 'package:nitznutz/speech/hebrew_text.dart';

/// The age band of an age (A 3–4, B 5–6, C 7–8); rows without an age are read for band B.
int band(int age) => age <= 4 ? 0 : (age <= 6 ? 1 : 2);

void expectTier(String text, int? tier, {String? rule, int age = 5, Set<String> answers = const <String>{}}) {
  final WordMatch? m = checkWords(<String>[text], ageBand: band(age), answerWords: answers);
  expect(m?.tier, tier, reason: '"$text" at age $age (matched ${m?.rule})');
  if (rule != null) expect(m!.rule, rule, reason: text);
}

void main() {
  group('A. an act (tier 1)', () {
    const List<(String, String)> rows = <(String, String)>[
      ('מכים אותי', 'W-01'), // A1
      ('הם מרביצים לי', 'W-01'), // A2
      ('שמרביצים לי בגן', 'W-01'), // A3: the prefix ש
      ('אותי הם מכים', 'W-01'), // A4: the other order
      ('מרביצים לי ממש חזק', 'W-01'), // A5
      ('אבא מרביץ לי', 'W-02'), // A6
      ('אמא הרביצה לי', 'W-02'), // A7
      ('הגננת מכה אותי', 'W-02'), // A8
      ('המורה סטרה לי', 'W-02'), // A9
      ('דוד בועט בי', 'W-02'), // A10
      ('אבא שלי מרביץ לי כל יום', 'W-02'), // A11
      ('נגע לי בפיפי', 'W-11'), // A12
      ('המורה נגעה בי בפיפי', 'W-11'), // A13
      ('הוא שם לי יד בתחת', 'W-11'), // A14: `שם יד` with one filler
      ('נגעו לי בציצי', 'W-11'), // A15
      ('נוגע בבולבול שלי', 'W-11'), // A16: `שלי` for "me"
      ('דוד ביקש ממני להוריד את התחתונים', 'W-13'), // A17
      ('איש צילם אותי בלי בגדים', 'W-15'), // A18
      ('אנסו אותי', 'W-48'), // A19
      ('פוחד לחזור הביתה', 'W-19'), // A20
      ('אני מפחדת ללכת הביתה', 'W-19'), // A21
      ('אם אספר הוא יכה אותי', 'W-45'), // A22
      ('מתעללים בי', 'W-23'), // A23
      ('אמא על הרצפה ולא זזה', 'W-28'), // A26
      ('אני רוצה למות', 'W-30'), // A27
      ('רוצה למות', 'W-30'), // A28
      ('אני כל כך רוצה למות', 'W-30'), // A29: two fillers in the self-harm block
      ('אני לא רוצה לחיות יותר', 'W-31'), // A30
      ('לא רוצה לחיות', 'W-31'), // A31
      ('נמאס לי לחיות', 'W-31'), // A32
      ('הלוואי שלא נולדתי', 'W-32'), // A33
      ('אני רוצה להרוג את עצמי', 'W-33'), // A34
      ('אני אקפוץ מהחלון', 'W-33'), // A35
      ('איש זר בטלפון ביקש ממני תמונה', 'W-39'), // A36
      ('אבא מרביץ לאמא בבית', 'W-10'), // A37: `בבית` makes it an act
      ('אבא אמר שיהרוג אותי', 'W-17'), // A38
      ('חרא אני רוצה למות', 'W-30'), // A39: the phrase wins over the swear (C-4)
      ('אמא נתנה לי מכות', 'W-04'), // A40
      ('אבא נתן לי סטירה', 'W-04'), // A41
      ('אותי מכים בבית', 'W-01'), // A42
    ];
    for (final (String text, String rule) in rows) {
      test(text, () => expectTier(text, 1, rule: rule));
    }
    test('A24, A25: alone at home at ages 4 and 5', () {
      expectTier('אני לבד בבית', 1, rule: 'W-25', age: 4);
      expectTier('השאירו אותי לבד בבית', 1, rule: 'W-25', age: 5);
    });
  });

  group('B. a check (tier 2)', () {
    const List<(String, String, int)> rows = <(String, String, int)>[
      ('הוא מרביץ לי', 'W-03', 5), // B1: the commonest sibling case
      ('הרביץ לי', 'W-03', 5), // B2
      ('אחי הרביץ לי היום', 'W-03', 5), // B3: a sibling is not an adult
      ('היא הכתה אותי', 'W-03', 5), // B4
      ('הוא מכה אותי', 'W-03', 5), // B5: was a disclosure before
      ('הוא דוחף אותי כל הזמן', 'W-08', 5), // B6
      ('הוא צובט אותי', 'W-08', 5), // B7
      ('אני פוחד מהמורה', 'W-18', 5), // B8
      ('אני פוחדת ממנו', 'W-18', 5), // B9
      ('מאיימים עלי', 'W-16', 5), // B10
      ('מאיים עליי', 'W-16', 5), // B11: the doubled yod
      ('מפחידים אותי', 'W-21', 5), // B12
      ('מציקים לי בגן', 'W-22', 5), // B13
      ('קוראים לי שמות', 'W-24', 5), // B14
      ('עשו לי חרם', 'W-24', 5), // B15
      ('אבא מרביץ לאמא', 'W-10', 5), // B16: no home marker
      ('הוא אמר שיפגע בי', 'W-17', 5), // B17
      ('אסור לי לספר לאמא', 'W-43', 5), // B18
      ('ביקשו ממני לא לספר', 'W-44', 5), // B19
      ('בא לי למות', 'W-34', 5), // B20
      ('אני רוצה להיעלם', 'W-35', 5), // B21
      ('אני שונא את עצמי', 'W-36', 7), // B22
      ('אני פוגע בעצמי', 'W-37', 6), // B23
      ('הוא הראה לי את הפיפי שלו', 'W-12', 5), // B24
      ('לא אכלתי מאתמול', 'W-26', 5), // B25
      ('אבא שיכור', 'W-27', 5), // B26
      ('ראיתי סרטון של אנשים בלי בגדים', 'W-41', 5), // B27
      ('אני לבד בבית', 'W-25', 7), // B28
      ('יש לי חבורות מאבא', 'W-09', 5), // B29
      ('הוא הוריד לי את המכנסיים', 'W-14', 6), // B30
      ('מקללים אותי בקבוצה בוואטסאפ', 'W-42', 8), // B31: W-24 matches too; the more specific row wins (QA-38)
      ('אבא ישן כל היום', 'W-27', 5), // B32
      ('זרקו אותי מהבית', 'W-29', 5), // B33
      ('משחק סודי עם דוד', 'W-46', 5), // B34
      ('פוחד ללכת לגן', 'W-20', 5), // B35
      ('פוחד ללכת לבית ספר', 'W-20', 5), // school, not home: `לבית` is followed by `ספר`
      ('גבר זר כתב לי', 'W-38', 5), // B36
      ('אני לא רוצה לחיות איתו', 'W-31', 5), // B37: a person follows
    ];
    for (final (String text, String rule, int age) in rows) {
      test(text, () => expectTier(text, 2, rule: rule, age: age));
    }
  });

  group('C. a note (tier 3)', () {
    const List<(String, String)> rows = <(String, String)>[
      ('חרא', 'S-01'), // C1
      ('חרא!', 'S-01'), // C2
      ('אכלת חרא', 'S-01'), // C3
      ('זין', 'S-02'), // C4
      ('לך תזדיין', 'S-03'), // C5
      ('בן זונה', 'S-05'), // C6
      ('זונה', 'S-05'), // C7
      ('שרמוטה', 'S-06'), // C8
      ('מניאק', 'S-07'), // C9
      ('כוס אמק', 'S-08'), // C10
      ('כוסאמק', 'S-08'), // C11
      ('FUCK', 'S-11'), // C12
      ('פאק יו', 'S-11'), // C13
      ('סקס', 'S-12'), // C14
      ('פורנו', 'S-12'), // C15
      ('מפגר', 'S-13'), // C16
      ('ערבוש', 'S-14'), // C17
      ('אל תספר לאמא', 'W-47'), // C18
      ('חָרָא', 'S-01'), // C19: niqqud is dropped
      ('כוס אמאשך', 'S-08'), // hebrew-validation: the fused form
      ('ביטש', 'S-11'), // hebrew-validation: the corrected spelling
      ('מחרבן', 'S-10'), // hebrew-validation: added
    ];
    for (final (String text, String rule) in rows) {
      test(text, () => expectTier(text, 3, rule: rule));
    }
    test('swearing is a swear, the adult world is an exposure', () {
      expect(checkWords(<String>['חרא'])!.sub, 'SWEAR');
      expect(checkWords(<String>['פורנו'])!.sub, 'EXPOSE');
    });
  });

  group('D. nothing', () {
    const List<String> d1 = <String>['ארבע', 'כוס מים', 'מתחת לעץ', 'שלוש פרפרים', 'אדום', 'הפרפר נחת עלי'];
    const List<String> d2 = <String>[
      'קר', 'כל', 'קל', // D2.1–3: the phonetic key of `חרא`; there is no phonetic matching
      'חרב', 'חרוץ', 'אחרי הצהריים', 'חורף', 'זינוק', 'כלי זיין', 'שיט בסירה', 'תחת העץ', 'כוס חלב', //
      'זובי', 'קיבלתי זובי', 'זיבי', // S-09 is dropped, and `זובי` was never added
      'כוסית', // left out (owner)
    ];
    const List<String> d3 = <String>[
      'הוא הרביץ בעיטה לכדור', 'אני מרביץ גול', 'אני מכה בתוף', 'מכים בתוף', 'יש לי מכה ברגל', //
      'נפלתי ויש לי חבורה', 'הכדור פגע בי', 'הכדור נחת עלי', 'הוא נגע בי בתופסת', 'תפסיק לגעת בי', //
      'אל תיגע בי', 'נגע לי בכתף', 'נגעתי בעץ', 'אמא מנגבת לי את הפיפי', 'אמא שמה לי קרם בתחת', //
      'הלכתי לעשות פיפי',
      'כואב לי בפיפי',
      'אני צריך קקי',
      'אני הרבצתי לו',
      'אני מרביץ לאחי',
      'אני אהרוג אותך', //
      'הזאב מרביץ לחזיר', 'קושרת לי את השיער', 'זה שורף לי',
    ];
    const List<String> d4 = <String>[
      'אני לבד בחדר', 'אני משחק לבד', 'אני לבד בגינה', 'אני לבד', 'אין אף אחד בכיתה', 'אני מת מצחוק', //
      'אני מתה על זה', 'אני מת לאכול', 'אני מתה מפחד', 'בא לי למות מבושה', 'אני רוצה למות מצחוק', //
      'הדוב מת בסיפור', 'אני לא רוצה לחיות בעיר', 'אני רוצה לחיות בבית גדול', 'אני פוחד מהחושך', //
      'אני פוחדת מכלבים', 'זה מפחיד אותי', 'הסרט מפחיד', 'אני לא פוחד', 'אמא תהרוג אותי', //
      'אבא יהרוג אותי אם אשבור את הכוס', 'אני רעב', 'אין לי תפוחים', 'מתתי מצחוק', 'אני לא רוצה למות', //
      'אני לא לבד בבית', 'זה לא שווה כלום',
    ];
    const List<String> d5 = <String>[
      'יש לי סוד', 'זה סוד', 'אסור לי לספר לאמא על המתנה', 'זו הפתעה ליום הולדת ואסור לספר', //
      'אם אספר אמא תכעס',
      'ילד מהמשחק כתב לי',
      'המורה ביקשה ממני תמונה',
      'אבא מדבר בטלפון',
      'לא מרביצים לי', //
      'אף אחד לא מרביץ לי', 'אבא לא מכה אותי', 'הוא לא הרביץ לי', 'לא רוצים להרביץ לי',
    ];
    for (final String text in <String>[...d1, ...d2, ...d3, ...d4, ...d5]) {
      test(text, () => expectTier(text, null));
    }
    test('D3.19: undressing is care at age 3', () => expectTier('אמא הורידה לי את המכנסיים', null, age: 3));
    test('an empty answer, empty strings and punctuation set off nothing (E7.1, E7.3)', () {
      expect(checkWords(const <String>[]), isNull);
      expect(checkWords(const <String>['', ' ']), isNull);
      expect(checkWords(const <String>['?!... ,']), isNull);
    });
  });

  group('D2.13–14: the letter ז is not a swear where the activity expects it', () {
    test('an answer of the activity on screen is skipped', () {
      expectTier('זין', null, answers: <String>{'זין'});
      expectTier('זין', 3, answers: <String>{'שבע'});
    });
    test('a phrase is still a phrase', () {
      expectTier('זין אני רוצה למות', 1, answers: <String>{'זין'});
    });
  });

  group('E1. spelling', () {
    test('niqqud, punctuation, the doubled yod, upper case and final letters', () {
      expectTier('מַרְבִּיצִים לִי', 1); // E1.1
      expectTier('אני רוצה למות!!!', 1); // E1.2
      expectTier('מאיימים עליי', 2); // E1.3
      expectTier('מאיימים עלי', 2);
      expectTier('FUCK', 3); // E1.4
      expectTier('fuck', 3);
      expectTier('מרביצים לי', 1); // E1.6: the final mem
    });
    test("E1.5: a loan word with and without its geresh (צ'אט, צאט)", () {
      expectTier("מקללים אותי בצ'אט", 2, age: 8);
      expectTier('מקללים אותי בצאט', 2, age: 8);
      expectTier("כותבים עלי בצ'אט", 2, rule: 'W-42', age: 8);
      expectTier('כותבים עלי בצאט', 2, rule: 'W-42', age: 8);
    });
    test('the forms the editor added (hebrew-validation.md, section 8.6)', () {
      expectTier('ביקש ממני לנשק אותו בפיפי', 2, rule: 'W-13'); // אנשק / לנשק
      expectTier('אבא ביקש שאנשק את הבולבול', 1, rule: 'W-13');
      expectTier('אבא אמר שתרביץ לי', 2, rule: 'W-17'); // a feminine future
      expectTier('אני רוצה שהכול ייגמר', 2, rule: 'W-35'); // הכול
      expectTier('אני פוחד מאימא', 2, rule: 'W-18'); // אימא
      expectTier('כותבים עלי בווצאפ', 2, rule: 'W-42', age: 8); // the WhatsApp spellings
      expectTier('אם אגיד הוא ייקח אותי', 1, rule: 'W-45'); // ייקח
      expectTier('כוס אמאשך', 3, rule: 'S-08');
      expectTier('היא היכתה אותי', 2, rule: 'W-03'); // full spelling
      expectTier('הגננת היכתה אותי', 1, rule: 'W-02');
    });
  });

  group('E2. gaps, order, prefixes and negation', () {
    test('one filler, the other order, the prefixes ש and ו', () {
      expectTier('אני ממש רוצה למות', 1); // E2.1
      expectTier('אותי הוא מכה', 2); // E2.2
      expectTier('שהוא מרביץ לי', 2); // E2.3
      expectTier('וכולם מרביצים לי', 1); // E2.4
      expectTier('כשמרביצים לי אני בוכה', 1);
    });
    test('E2.5: the window is three tokens from the verb, and no more', () {
      expectTier('מרביצים כל הזמן לי', 1);
      expectTier('מרביצים היום ממש כל הזמן לי', null);
    });
    test('E2.6: a negation one or two tokens before the verb', () {
      expectTier('לא ממש מרביצים לי', null);
      expectTier('לא מרביצים לי', null);
    });
  });

  group('E3. hypotheses', () {
    test('an act counts in any hypothesis; a check or a note needs the best one or two', () {
      expect(checkWords(<String>['ארבע', 'מרביצים לי'])?.tier, 1); // E3.1
      expect(checkWords(<String>['שבע', 'אני רוצה למות'])?.tier, 1); // E3.2
      expect(checkWords(<String>['חרא'])?.tier, 3); // E3.3
      expect(checkWords(<String>['שבע', 'חרא']), isNull); // E3.4
      expect(checkWords(<String>['חרא', 'חרא'])?.tier, 3); // E3.5
      expect(checkWords(<String>['שבע', 'הוא מרביץ לי']), isNull); // E3.6
      expect(checkWords(<String>['שבע', 'הוא מרביץ לי', 'הוא מרביץ לי'])?.tier, 2);
      expect(checkWords(<String>['מניאק', 'ארבע'])?.tier, 3, reason: 'the best hypothesis');
    });
    test('E3.7: the text kept is the hypothesis that matched', () {
      expect(checkWords(<String>['ארבע', 'מרביצים לי'])!.text, 'מרביצים לי');
      expect(checkWords(<String>['חרא', 'חרה'])!.text, 'חרא');
    });
    test('E7.4: the same phrase in five hypotheses is one match', () {
      final WordMatch m = checkWords(List<String>.filled(5, 'מכים אותי'))!;
      expect(m.tier, 1);
      expect(m.text, 'מכים אותי');
    });
  });

  group('E5. ages', () {
    test('alone at home: an act up to band B, a check in band C', () {
      expectTier('אני לבד בבית', 1, age: 4); // E5.2
      expectTier('אני לבד בבית', 1, age: 6); // band B is ages 5 to 6: the stronger tier
      expectTier('אני לבד בבית', 2, age: 7);
    });
    test('hurting oneself: a note at 4, a check at 6', () {
      expectTier('אני פוגע בעצמי', 3, age: 4); // E5.3
      expectTier('אני פוגע בעצמי', 2, age: 6);
    });
    test('wanting to die is an act at every age', () {
      for (final int age in <int>[3, 5, 8]) {
        expectTier('אני רוצה למות', 1, age: age); // E5.4
      }
    });
    test('being undressed: off at 3, a check at 6', () {
      expectTier('הוריד לי את המכנסיים', null, age: 3); // E5.5
      expectTier('הוריד לי את המכנסיים', 2, age: 6);
    });
    test('worthlessness from band B, online bullying in band C only', () {
      expectTier('אני שונא את עצמי', null, age: 4);
      expectTier('אני שונא את עצמי', 2, age: 5);
      expectTier('צוחקים עלי בקבוצה', null, age: 6);
      expectTier('צוחקים עלי בקבוצה', 2, rule: 'W-42', age: 7);
    });
    test('swearing is a note at every age (owner, 2026-10-29)', () {
      for (final int age in <int>[3, 5, 8]) {
        expectTier('חרא', 3, age: age); // E5.1
      }
    });
  });

  group('combination rules', () {
    test('C-2: a secret and a harm in the same answer are an act about the harm', () {
      final WordMatch m = checkWords(<String>['הוא מרביץ לי ואסור לי לספר לאמא'])!;
      expect(m.tier, 1);
      expect(m.sub, 'PHYS');
      expect(m.secret, isTrue);
      expect(checkWords(<String>['הוא מרביץ לי'])!.secret, isFalse);
    });
    test('C-4: a phrase wins, and the swear in the same answer is passed on', () {
      final WordMatch m = checkWords(<String>['חרא אני רוצה למות'])!;
      expect(m.sub, 'SELF');
      expect(m.swear?.rule, 'S-01');
      expect(checkWords(<String>['חרא'])!.swear, isNull, reason: 'the swear is the match itself');
    });
    test('C-5: said to happen often', () {
      expect(checkWords(<String>['מרביצים לי כל יום'])!.often, isTrue);
      expect(checkWords(<String>['מרביצים לי'])!.often, isFalse);
      expect(
        checkWords(<String>['אני רוצה למות כל יום'])!.often,
        isFalse,
        reason: 'only harm, fear and touch',
      );
    });
  });

  group('the lists', () {
    test('carry a version, and every match says which', () {
      expect(AlertLists.bundled.listVersion, bundledAlertLists['listVersion']);
      expect(checkWords(<String>['מכים אותי'])!.listVersion, AlertLists.bundled.listVersion);
    });
    test('another source of the same shape replaces them', () {
      final AlertLists other = AlertLists.fromJson(<String, Object?>{
        ...bundledAlertLists,
        'listVersion': '2026-11-01.2',
        'rules': const <Object?>[],
        'words': const <Object?>[
          <String, Object?>{
            'id': 'X-01',
            'sub': 'SWEAR',
            'forms': <String>['בננה'],
          },
        ],
      });
      expect(checkWords(<String>['חרא'], lists: other), isNull);
      expect(checkWords(<String>['בננה'], lists: other)!.listVersion, '2026-11-01.2');
    });
    test('a set that does not exist is refused when the lists are read', () {
      expect(
        () => AlertLists.fromJson(<String, Object?>{
          ...bundledAlertLists,
          'rules': const <Object?>[
            <String, Object?>{
              'id': 'X',
              'sub': 'PHYS',
              'tier': 1,
              'seq': <String>['@NOPE'],
            },
          ],
        }),
        throwsFormatException,
      );
    });
    test('no swear word is matched by sound: the lists never use the phonetic key', () {
      expect(phoneticKey('חרא'), phoneticKey('קר'), reason: 'why it must not be used');
      for (final String w in <String>['קר', 'כל', 'קל', 'חרה', 'חראא']) {
        expect(checkWords(<String>[w]), isNull, reason: w);
      }
    });
    test('E7.2: a 1,000-token answer is checked in well under the budget', () {
      final String long = List<String>.generate(1000, (int i) => i.isEven ? 'פרפר' : 'אדום').join(' ');
      checkWords(<String>[long]); // warm up the compiled lists
      final Stopwatch w = Stopwatch()..start();
      expect(checkWords(<String>[long]), isNull);
      w.stop();
      // ignore: avoid_print
      print('1,000 tokens: ${w.elapsedMicroseconds} µs');
      expect(
        w.elapsedMilliseconds,
        lessThan(50),
        reason: 'the list asks for 10 ms on a phone; a test machine is slower',
      );
    });
  });
}
