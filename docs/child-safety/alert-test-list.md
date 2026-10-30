# Test list for the alert word lists (for the app-developer and the qa-engineer)

**Status:** DRAFT, written with `alert-word-lists-proposed.md` (tiers T1, T2, T3 and rules C-1 to C-5). Input strings are Hebrew as the recogniser would write them (no niqqud, unless a test is about niqqud). "Expected" is the tier the matcher must return for that input. The ages are the child's age when a rule depends on it.

Every row is meant to become one `test(...)` or one table-driven case. Group A to D are string cases for `checkWords`-style matching; E to G are behaviour cases for the alert layer.

Note on the API: today `checkWords` returns only `WordAlert.inappropriate` or `WordAlert.disclosure`. The proposed lists need it to return a tier, a subcategory and the matched hypothesis (see the review, R1 and R4). The expected values below use `T1`, `T2`, `T3` and `none`.

---

## A. Must match T1 (tier "act")

| # | Input | Rule | Note |
|---|---|---|---|
| A1 | `מכים אותי` | W-01 | |
| A2 | `הם מרביצים לי` | W-01 | extra word before |
| A3 | `שמרביצים לי בגן` | W-01 | `ש` prefix |
| A4 | `אותי הם מכים` | W-01 | reversed order |
| A5 | `מרביצים לי ממש חזק` | W-01 | filler after |
| A6 | `אבא מרביץ לי` | W-02 | |
| A7 | `אמא הרביצה לי` | W-02 | |
| A8 | `הגננת מכה אותי` | W-02 | |
| A9 | `המורה סטרה לי` | W-02 | |
| A10 | `דוד בועט בי` | W-02 | |
| A11 | `אבא שלי מרביץ לי כל יום` | W-02 | |
| A12 | `נגע לי בפיפי` | W-11 | |
| A13 | `המורה נגעה בי בפיפי` | W-11 | |
| A14 | `הוא שם לי יד בתחת` | W-11 | `שם יד` split by one filler |
| A15 | `נגעו לי בציצי` | W-11 | |
| A16 | `נוגע בבולבול שלי` | W-11 | `שלי` instead of ME |
| A17 | `דוד ביקש ממני להוריד את התחתונים` | W-13 | with ADULT |
| A18 | `איש צילם אותי בלי בגדים` | W-15 | |
| A19 | `אנסו אותי` | W-48 | |
| A20 | `פוחד לחזור הביתה` | W-19 | legacy |
| A21 | `אני מפחדת ללכת הביתה` | W-19 | `מפחדת`, `ללכת` |
| A22 | `אם אספר הוא יכה אותי` | W-45 | |
| A23 | `מתעללים בי` | W-23 | |
| A24 | `אני לבד בבית` (age 4) | W-25 | T1 at 3 to 5 |
| A25 | `השאירו אותי לבד בבית` (age 5) | W-25 | |
| A26 | `אמא על הרצפה ולא זזה` | W-28 | emergency wording |
| A27 | `אני רוצה למות` | W-30 | legacy |
| A28 | `רוצה למות` | W-30 | without `אני` |
| A29 | `אני כל כך רוצה למות` | W-30 | two fillers allowed in SELF block |
| A30 | `אני לא רוצה לחיות יותר` | W-31 | |
| A31 | `לא רוצה לחיות` | W-31 | legacy, at the end of the answer |
| A32 | `נמאס לי לחיות` | W-31 | |
| A33 | `הלוואי שלא נולדתי` | W-32 | |
| A34 | `אני רוצה להרוג את עצמי` | W-33 | |
| A35 | `אני אקפוץ מהחלון` | W-33 | |
| A36 | `איש זר בטלפון ביקש ממני תמונה` | W-39 | unknown adult + request |
| A37 | `אבא מרביץ לאמא בבית` | W-10 | `בבית` raises T2 to T1 |
| A38 | `אבא אמר שיהרוג אותי` | W-17 | ADULT + kill verb |
| A39 | `חרא אני רוצה למות` | C-4 | phrase wins over swear (existing test, keep) |
| A40 | `אמא נתנה לי מכות` | W-04 | ADULT raises it to T1 |
| A41 | `אבא נתן לי סטירה` | W-04 | ADULT |
| A42 | `אותי מכים בבית` | W-01 | order + extra |

## B. Must match T2 (tier "check context")

| # | Input | Rule | Note |
|---|---|---|---|
| B1 | `הוא מרביץ לי` | W-03 | the commonest sibling case |
| B2 | `הרביץ לי` | W-03 | |
| B3 | `אחי הרביץ לי היום` | W-03 | sibling is not in ADULT |
| B4 | `היא הכתה אותי` | W-03 | |
| B5 | `הוא מכה אותי` | W-03 | **changes an existing test** (was a disclosure) |
| B6 | `הוא דוחף אותי כל הזמן` | W-08 | |
| B7 | `הוא צובט אותי` | W-08 | |
| B8 | `אני פוחד מהמורה` | W-18 | |
| B9 | `אני פוחדת ממנו` | W-18 | |
| B10 | `מאיימים עלי` | W-16 | legacy |
| B11 | `מאיים עליי` | W-16 | doubled yod |
| B12 | `מפחידים אותי` | W-21 | legacy, demoted |
| B13 | `מציקים לי בגן` | W-22 | |
| B14 | `קוראים לי שמות` | W-24 | |
| B15 | `עשו לי חרם` | W-24 | |
| B16 | `אבא מרביץ לאמא` | W-10 | no home marker |
| B17 | `הוא אמר שיפגע בי` | W-17 | no ADULT |
| B18 | `אסור לי לספר לאמא` | W-43 | |
| B19 | `ביקשו ממני לא לספר` | W-44 | |
| B20 | `בא לי למות` | W-34 | no idiom after |
| B21 | `אני רוצה להיעלם` | W-35 | |
| B22 | `אני שונא את עצמי` (age 7) | W-36 | |
| B23 | `אני פוגע בעצמי` (age 6) | W-37 | T3 at ages 3 to 5 |
| B24 | `הוא הראה לי את הפיפי שלו` | W-12 | peer doctor play |
| B25 | `לא אכלתי מאתמול` | W-26 | |
| B26 | `אבא שיכור` | W-27 | |
| B27 | `ראיתי סרטון של אנשים בלי בגדים` | W-41 | |
| B28 | `אני לבד בבית` (age 7) | W-25 | T2 at 6 to 8 |
| B29 | `יש לי חבורות מאבא` | W-09 | |
| B30 | `הוא הוריד לי את המכנסיים` (age 6) | W-14 | not at ages 3 to 4 |
| B31 | `מקללים אותי בקבוצה בוואטסאפ` (age 8) | W-42 | |
| B32 | `אבא ישן כל היום` | W-27 | |
| B33 | `זרקו אותי מהבית` | W-29 | |
| B34 | `משחק סודי עם דוד` | W-46 | |
| B35 | `פוחד ללכת לגן` | W-20 | |
| B36 | `גבר זר כתב לי` | W-38 | |
| B37 | `אני לא רוצה לחיות איתו` | W-31 note | person follows: T2, not T1 |

## C. Must match T3 (tier "note", digest only)

| # | Input | Rule | Note |
|---|---|---|---|
| C1 | `חרא` | S-01 | existing |
| C2 | `חרא!` | S-01 | punctuation (existing) |
| C3 | `אכלת חרא` | S-01 | |
| C4 | `זין` | S-02 | when the activity does not expect a letter name |
| C5 | `לך תזדיין` | S-03 | existing |
| C6 | `בן זונה` | S-05 | |
| C7 | `זונה` | S-05 | |
| C8 | `שרמוטה` | S-06 | |
| C9 | `מניאק` | S-07 | existing |
| C10 | `כוס אמק` | S-08 | |
| C11 | `כוסאמק` | S-08 | joined spelling |
| C12 | `FUCK` | S-11 | Latin, upper case, lowered by the normaliser |
| C13 | `פאק יו` | S-11 | |
| C14 | `סקס` | S-12 | shown with the *exposure* wording |
| C15 | `פורנו` | S-12 | |
| C16 | `מפגר` | S-13 | |
| C17 | `ערבוש` | S-14 | |
| C18 | `אל תספר לאמא` | W-47 | digest only |
| C19 | `חָרָא` (with niqqud) | S-01 | niqqud stripped |

## D. Must NOT match (none)

### D1. Lesson answers and everyday words (existing tests, keep)
`ארבע`, `כוס מים`, `מתחת לעץ`, `שלוש פרפרים`, `אדום`, `הפרפר נחת עלי`, and an empty list.

### D2. Letters that look like a swear or a sound-alike

| # | Input | Expected | Note |
|---|---|---|---|
| D2.1 | `קר` | none | `phoneticKey` equals that of `חרא`; proves there is no phonetic matching |
| D2.2 | `כל` | none | same |
| D2.3 | `קל` | none | same |
| D2.4 | `חרב` | none | |
| D2.5 | `חרוץ` | none | |
| D2.6 | `אחרי הצהריים` | none | |
| D2.7 | `חורף` | none | |
| D2.8 | `זינוק` | none | |
| D2.9 | `כלי זיין` | none | weapons |
| D2.10 | `שיט בסירה` | none | boating (Hebrew spelling `שיט`) |
| D2.11 | `תחת העץ` | none | `תחת` = under |
| D2.12 | `כוס חלב` | none | |
| D2.13 | answer `זין`, current activity expects the letter name ז | none | context suppression (review R7) |
| D2.14 | answer `זין`, activity expects a number | T3 | proves the suppression is activity-specific |

### D3. Hitting, touching, hurt, in play, sport and care

| # | Input | Expected | Note |
|---|---|---|---|
| D3.1 | `הוא הרביץ בעיטה לכדור` | none | `הרביץ` for a kick; no ME |
| D3.2 | `אני מרביץ גול` | none | |
| D3.3 | `אני מכה בתוף` | none | |
| D3.4 | `מכים בתוף` | none | |
| D3.5 | `יש לי מכה ברגל` | none | `מכה` as a noun |
| D3.6 | `נפלתי ויש לי חבורה` | none | no named person (W-09 needs one) |
| D3.7 | `הכדור פגע בי` | none | |
| D3.8 | `הכדור נחת עלי` | none | |
| D3.9 | `הוא נגע בי בתופסת` | none | tag game; no body word |
| D3.10 | `תפסיק לגעת בי` | none | |
| D3.11 | `אל תיגע בי` | none | |
| D3.12 | `נגע לי בכתף` | none | `כתף` is not in BODY |
| D3.13 | `נגעתי בעץ` | none | |
| D3.14 | `אמא מנגבת לי את הפיפי` | none | care; not a TOUCH verb |
| D3.15 | `אמא שמה לי קרם בתחת` | none | care; `שמה קרם`, not `שמה יד` |
| D3.16 | `הלכתי לעשות פיפי` | none | |
| D3.17 | `כואב לי בפיפי` | none | medical; deliberately out |
| D3.18 | `אני צריך קקי` | none | |
| D3.19 | `אמא הורידה לי את המכנסיים` (age 3) | none | W-14 off at 3 to 4 |
| D3.20 | `אני הרבצתי לו` | none | the child as hitter |
| D3.21 | `אני מרביץ לאחי` | none | |
| D3.22 | `אני אהרוג אותך` | none | tantrum |
| D3.23 | `הזאב מרביץ לחזיר` | none | story, no ME |

### D4. Alone, fear, death words

| # | Input | Expected | Note |
|---|---|---|---|
| D4.1 | `אני לבד בחדר` | none | |
| D4.2 | `אני משחק לבד` | none | |
| D4.3 | `אני לבד בגינה` | none | |
| D4.4 | `אני לבד` | none | |
| D4.5 | `אין אף אחד בכיתה` | none | |
| D4.6 | `אני מת מצחוק` | none | idiom |
| D4.7 | `אני מתה על זה` | none | idiom |
| D4.8 | `אני מת לאכול` | none | idiom |
| D4.9 | `אני מתה מפחד` | none | idiom |
| D4.10 | `בא לי למות מבושה` | none | idiom guard |
| D4.11 | `אני רוצה למות מצחוק` | none | idiom guard |
| D4.12 | `הדוב מת בסיפור` | none | |
| D4.13 | `אני לא רוצה לחיות בעיר` | none | place follows |
| D4.14 | `אני רוצה לחיות בבית גדול` | none | |
| D4.15 | `אני פוחד מהחושך` | none | |
| D4.16 | `אני פוחדת מכלבים` | none | |
| D4.17 | `זה מפחיד אותי` | none | singular, not an entry |
| D4.18 | `הסרט מפחיד` | none | |
| D4.19 | `אני לא פוחד` | none | |
| D4.20 | `אמא תהרוג אותי` | none | idiom for "I'm in trouble" |
| D4.21 | `אבא יהרוג אותי אם אשבור את הכוס` | none | idiom; no reporting verb |
| D4.22 | `אני רעב` | none | |
| D4.23 | `אין לי תפוחים` | none | word problem |

### D5. Secrets, strangers and negation

| # | Input | Expected | Note |
|---|---|---|---|
| D5.1 | `יש לי סוד` | none | |
| D5.2 | `זה סוד` | none | |
| D5.3 | `אסור לי לספר לאמא על המתנה` | none | surprise guard |
| D5.4 | `זו הפתעה ליום הולדת ואסור לספר` | none | surprise guard |
| D5.5 | `אם אספר אמא תכעס` | none | not a harm verb |
| D5.6 | `ילד מהמשחק כתב לי` | none | `ילד` is not in UNKNOWN |
| D5.7 | `המורה ביקשה ממני תמונה` | none | known adult, not a body request |
| D5.8 | `אבא מדבר בטלפון` | none | |
| D5.9 | `לא מרביצים לי` | none | negation just before the verb |
| D5.10 | `אף אחד לא מרביץ לי` | none | |
| D5.11 | `אבא לא מכה אותי` | none | |
| D5.12 | `הוא לא הרביץ לי` | none | |
| D5.13 | `לא רוצים להרביץ לי` | none | |

---

## E. Structure and behaviour tests

### E1. Normalisation and spelling
| # | Case | Expected |
|---|---|---|
| E1.1 | `מַרְבִּיצִים לִי` (with niqqud) | T1 |
| E1.2 | `אני רוצה למות!!!` | T1 |
| E1.3 | `מאיימים עליי` and `מאיימים עלי` | both T2 |
| E1.4 | `FUCK` and `fuck` | both T3 |
| E1.5 | a loan word with geresh written with and without it (`צ'אט`, `צאט`) in W-42 | both match |
| E1.6 | final-letter forms (`מרביצים` with final mem) | match |

### E2. Gap, order, prefix, negation
| # | Case | Expected |
|---|---|---|
| E2.1 | `אני ממש רוצה למות` | T1 (one filler) |
| E2.2 | `אותי הוא מכה` | T2 (reversed, singular) |
| E2.3 | `שהוא מרביץ לי` | T2 (`ש` prefix) |
| E2.4 | `וכולם מרביצים לי` | T1 (`ו` prefix) |
| E2.5 | a window of 4 between verb and ME in a 3-token window rule | none (window respected) |
| E2.6 | negation two tokens before the verb (`לא ממש מרביצים לי`) | none |

### E3. Hypotheses
| # | `texts` | Expected |
|---|---|---|
| E3.1 | `['ארבע', 'מרביצים לי']` | T1 (T1 uses any hypothesis) |
| E3.2 | `['שבע', 'אני רוצה למות']` | T1 |
| E3.3 | `['חרא']` | T3 |
| E3.4 | `['שבע', 'חרא']` (swear only in the second) | none (T2 and T3 need the top hypothesis or two hypotheses) |
| E3.5 | `['חרא', 'חרא']` | T3 |
| E3.6 | `['שבע', 'הוא מרביץ לי']` (T2 only in the second) | none |
| E3.7 | the stored `words` for E3.1 | `מרביצים לי` (the matching hypothesis), not `ארבע` |

### E4. Escalation, cool-down, digest
| # | Case | Expected |
|---|---|---|
| E4.1 | five answers with `חרא` within 2 minutes | one digest entry with count 5; no push |
| E4.2 | `חרא` then `מרביצים לי` within 1 minute | T1 alert; the swear counted in the digest |
| E4.3 | `מכים אותי` four times within 5 minutes | one T1 alert, count 4, one push |
| E4.4 | `מכים אותי`, then 40 minutes of nothing, then `מכים אותי` | two T1 alerts |
| E4.5 | two different subcategories at T1 (`מכים אותי`, `אני רוצה למות`) within 3 minutes | two alerts |
| E4.6 | two T2 hits on days 1 and 3 (rule C-1) | one T1 "repeated" alert |
| E4.7 | two T2 hits on days 1 and 9 | two T2 alerts, no escalation |
| E4.8 | `אסור לי לספר` and `הוא מרביץ לי` within 24 hours (rule C-2) | T1 |
| E4.9 | `חרא` thirty times in a day | one digest line, count 30 |

### E5. Age rules (proposed table, section 6)
| # | Case | Expected |
|---|---|---|
| E5.1 | `חרא`, age 3 | counted, no digest line unless the parent turned it on |
| E5.2 | `אני לבד בבית`, ages 4 and 7 | T1 and T2 |
| E5.3 | `אני פוגע בעצמי`, ages 4 and 6 | T3 and T2 |
| E5.4 | `אני רוצה למות`, ages 3, 5 and 8 | T1 each |
| E5.5 | `הוריד לי את המכנסיים`, ages 3 and 6 | none and T2 |

### E6. Mapping to the app's alert layer
| # | Case | Expected |
|---|---|---|
| E6.1 | tier T1 | `AlertCategory.disclosure`, severity important |
| E6.2 | tier T2 | a new "check" category, severity attention |
| E6.3 | tier T3 | `AlertCategory.inappropriateWords` (or a digest row), severity info, never pushed |
| E6.4 | `keepWords` false | category kept, `words` empty (existing behaviour) |
| E6.5 | list version | stored with every alert |

### E7. Robustness
| # | Case | Expected |
|---|---|---|
| E7.1 | empty list of texts, or empty strings | none |
| E7.2 | a 1,000-token answer | no match, under 10 ms |
| E7.3 | a text that is only punctuation | none |
| E7.4 | the same phrase in 5 hypotheses | one alert, not five |

## F. Changes to the existing tests in `app/test/alerts_test.dart`
- `checkWords(['הוא מכה אותי'])` expected `WordAlert.disclosure` becomes **T2** (rule W-03).
- `checkWords(['אני רוצה למות חרא'])` stays a disclosure (T1) (rule C-4).
- The swear tests `חרא!` and `לך תזדיין` stay, now as T3.
- `checkWords(['ארבע', 'מניאק'])` ("any hypothesis counts") **changes**: a T3 word that is only in the second hypothesis no longer counts (rule R4). Replace it with `['מניאק', 'ארבע']` (top hypothesis) expecting T3, and keep one case showing that a T1 phrase in a lower hypothesis still counts (E3.1).
- The everyday list stays and grows with section D.

## G. Counts (for the hand-off)
Section A: 42 cases. B: 37. C: 19. D: 80 (73 numbered plus the 7 existing everyday cases in D1). E: 42. Total about 220 cases. Add real-recording cases when the owner decides on test recordings (review, open question Q7).
