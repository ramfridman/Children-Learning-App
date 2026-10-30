# Proposed alert word lists for Nitznutz (draft v2, for editor and counsellor review)

**Status:** DRAFT, `review: needs-editor` for every Hebrew string. Written by an AI (Claude) acting as a child-psychology and child-protection adviser. It is not a clinician's work. Read `alert-word-lists-review.md` first: it explains why the lists look like this, what they cannot do, and what a human must confirm. Test phrases are in `alert-test-list.md`; parent and tutor wording is in `alert-wording-drafts.md`.

**What changed against today's lists** (`app/lib/speech/alert_words.dart`): today there are 8 swear words and 15 phrases, all one tier. This draft has **16 word entries** (about 70 token forms) and **48 phrase entries**, each with a **tier**, a **subcategory**, a false-positive risk and the reason, plus 5 combination rules and a list of what was left out on purpose.

## 1. How to read the tables

### Spelling rules (as the recogniser writes)
- No niqqud. Write in full spelling (ktiv male), as the ivrit.ai model is expected to: `מרביצים`, `אותי`, `עליי` or `עלי`.
- The code's `normalizeHebrew` already folds final letters (`ך`→`כ`, `ם`→`מ`, ...), drops punctuation and geresh, and keeps Latin letters in lower case. Entries can be written with normal final letters; they are normalised at load time.
- **Proposed extra normalisation, applied to both the text and the entries:** collapse a doubled yod or vav (`עליי`→`עלי`, `וואטסאפ`→`ואטסאפ`). This removes the biggest ktiv male / chaser spelling split without any fuzzy matching.
- **Prefix tolerance.** A verb token also matches with one of the prefixes `ש`, `ו`, `כש`, `וש` in front (`שמרביצים`, `וקורא`). A body-part token also matches with `ב`, `ל`, `ה`, `ש`, `מ`, `כ`, `וב`, `של` (`בפיפי`, `לפיפי`, `שבפיפי`).
- **No phonetic or edit-distance matching for any token of 5 letters or fewer.** In this repo `phoneticKey('חרא')` is `kl`, which is also the key of `כל` (all), `קל` (light) and `קר` (cold). See the review, finding F9.

### Pattern notation
| Symbol | Meaning |
|---|---|
| `[a/b/c]` | exactly one token from the set |
| `(a/b)` | optional token |
| `±3` | the listed parts may appear in any order within a window of 3 tokens (4, 5 where stated) |
| `ME` | `אותי / לי / בי / עלי` (after the yod rule) |
| `HIT*` | the hitting verbs of set V-1 below |
| `ADULT` | the nouns of set A below |
| `BODY` | the nouns of set B below |
| `TOUCH` | the verbs of set V-2 below |
| `NOT-NEAR` | if one of these tokens is within the window, the entry does not fire |

A fixed phrase (no `±`) is a run of consecutive tokens with at most **one** filler token allowed between two of its tokens (`אני ממש רוצה למות` still matches `אני רוצה למות`).

### Tiers
| Tier | Name | What the app does (recommendation) |
|---|---|---|
| **T1** | Act | Alert category *disclosure*, severity *important*, push with no content (as PLAN says today). |
| **T2** | Check context | A new, softer in-app alert (*attention*), no push. Becomes T1 by rule C-1 if repeated. |
| **T3** | Note | Not an alert. Counted in a daily or weekly digest for the parent. Never pushed. |

**FP risk** is my estimate of how often the entry fires on something harmless: L low, M medium, H high. It is a judgement, not a measurement.

### Set V-1: hitting verbs (`HIT*`)
`מכה מכים מכות הכה הכתה הכו היכו` / `מרביץ מרביצה מרביצים מרביצות הרביץ הרביצה הרביצו` / `סוטר סוטרת סוטרים סטר סטרה סטרו` / `בועט בועטת בועטים בעט בעטה בעטו`

*Plural or impersonal subject* = `מכים מרביצים מרביצות הכו הרביצו היכו סוטרים סטרו בועטים בעטו`. *Singular* = the rest.

### Set V-2: touching verbs (`TOUCH`)
`נגע נוגע נגעה נוגעת נגעו נוגעים נוגעות` / `ליטף מלטף ליטפה מלטפת ליטפו מלטפים` / `תפס תופס תפסה תופסת תפסו תופסים` / `נישק מנשק נישקה מנשקת` / `שם יד` / `שמה יד` / `שמו יד` / `שמים יד` / `שם אצבע` / `הכניס יד` / `הכניסה יד` / `הכניס אצבע`

### Set A: adults (`ADULT`)
`אבא אמא סבא סבתא דוד דודה מבוגר איש גבר אישה הגננת הגנן המורה הסייעת המטפלת המטפל השמרטף השמרטפית הבייביסיטר המדריך המדריכה המאמן המאמנת הנהג השכן השכנה` and the pairs `החבר של אמא`, `החבר של אבא`, `החברה של אבא`, `בן הזוג של אמא`, `בעלה של אמא`, `אבא שלי`, `אמא שלי`. Siblings and `ילד` are **not** in the set on purpose (they are the commonest harmless trigger, see review F6).

### Set B: body words (`BODY`)
`פיפי בולבול ציצי ציצים טוסיק ישבן איבר איברי מין מקום פרטי מקומות פרטיים חלק פרטי חלקים פרטיים` plus `בתחת`, `לתחת` (never bare `תחת`, which means "under").
**Unverified child vocabulary.** I did not find an authoritative Hebrew source for the words 3 to 8 year olds use. These come from general knowledge and must be corrected by the editor and a kindergarten counsellor. Not in the set: `ציפור` (a bird) and `שפן` (a rabbit), even though some families use them as child words.

---

## 2. List 1: inappropriate words (swearing and exposure words)

Default tier T3 (digest). Single token unless shown. The existing 8 words stay, with the notes below.

| ID | Class | Token forms (normalised, no niqqud) | Tier | FP risk | Why / notes |
|---|---|---|---|---|---|
| S-01 | vulgar | `חרא` | T3 | L | Existing. Most common child-heard swear. Exact token only. |
| S-02 | vulgar-sexual | `זין` | T3 | **H in a literacy lesson** | Existing. **`זין` is also the name of the letter ז.** Skip this entry when the current activity expects a letter name or a letter value (Band C letter values include ז = 7). Also `כלי זיין` (weapons) must not fire. See review R7. |
| S-03 | vulgar-sexual | `זיינתי זיינו זיינה מזיין מזיינת לזיין מזדיין מזדיינת תזדיין תזדייני הזדיין להזדיין יזדיין` and the phrase `לך תזדיין` | T3 | L | Existing `מזדיין מזדיינת תזדיין` plus the verb family. Bare `זיין` is **not** an entry (weapons, letter name). |
| S-04 | vulgar-sexual | `מזוין מזוינת מזוינים` | T3 | M | Adult-speech "lousy"; derived from the same root. Optional: the owner may drop it. |
| S-05 | insult | `זונה זונות` and the phrases `בן זונה`, `בני זונות`, `בת זונה`, `יא זונה` | T3 | L | Existing `זונה` plus phrase forms. |
| S-06 | insult | `שרמוטה שרמוטות` and `בן שרמוטה` | T3 | L | Existing. |
| S-07 | insult | `מניאק מניאקים מניאקית` | T3 | L | Existing, plus plural and feminine. |
| S-08 | vulgar-sexual | `כוסאמק כוסעמק כוסאמא` and the phrases `כוס אמק`, `כוס עמק`, `כוס אמא שלך`, `כוס אמא שלו`, `כוס אמא שלה`, `כוס אחותך` | T3 | L | Very common adult swear; **`כוס` alone stays out** (a cup, already in the test file). |
| S-09 | vulgar | `זיבי` | T3 | L | Vulgar slang for the male organ. Editor to confirm the spelling. |
| S-10 | vulgar | `תחרבן תחרבני מחורבן מחורבנת חרבן` and `לך תחרבן` | T3 | M | Mild vulgar. `חרבן` is also a plain word for "to defecate", so keep at T3 and let the editor decide. |
| S-11 | english | Latin `fuck fucking fuk shit bitch bastard asshole` and Hebrew spellings `פאק פאקינג בייץ ביץ אסהול` and the phrase `פאק יו` | T3 | L | Children hear English swearing on screens. The normaliser keeps Latin letters, so Latin forms can match if the recogniser emits them. **Hebrew `שיט` is not an entry** (it means boating). Note: `normalizeHebrew` turns a geresh into a space, so a loan word written with one (`צ'אט`) becomes two tokens; give both spellings in the data file. |
| S-12 | sexual exposure | `סקס פורנו פורנוגרפיה` and the phrases `תמונות עירום`, `סרטון עירום`, `סרטוני עירום`, `אתר פורנו` | T3, shown with the *exposure* wording | M | A 6 to 8 year old who says these may have seen adult material. A calm talk matters more than a reprimand. |
| S-13 | slur | `מפגר מפגרת מפגרים` | T3 | M | Offensive insult used at school. |
| S-14 | slur | `ערבוש ערבושים כושי כושים` | T3 | L | Racial slurs repeated from home or screens. Politically sensitive: owner decides (open question Q9). |
| S-15 | vulgar | `חארות חראות` | T3 | L | Plural forms of S-01 (editor to check spelling). |
| S-16 | insult-mild | `שמוק שמוקים` | T3 | M | Yiddish-origin "jerk". Optional. |

*Note on S-11:* I could not verify how the ivrit.ai model writes English swear words. Test with a few recordings before relying on S-11.

**Counting (for the hand-off):** 16 word rows (S-01 to S-16).

---

## 3. List 2: worrying phrases

Subcategory codes: **PHYS** physical harm, **SEX** sexual harm, **FEAR** fear or threat (including bullying), **NEGL** neglect or alone, **SELF** self-harm or death wish, **ONLINE** online or stranger, **SECRET** secrecy.

### 3.1 Physical harm (PHYS)

| ID | Pattern | Variants (ready to use) | Tier | FP | Why |
|---|---|---|---|---|---|
| W-01 | `HIT*` (plural or impersonal) + `ME`, ±3, any order | `מכים אותי`, `מרביצים לי`, `הרביצו לי`, `הכו אותי`, `סטרו לי`, `אותי הם מכים`, `שמרביצים לי`, `מרביצים לי בגן`, `מרביצים לי כל יום` | T1 | M | "They hit me" is how children name a hitter they cannot or will not name. It is the legacy `מכים אותי` / `מרביצים לי` widened. Also fires for peers in kindergarten: a parent should know. |
| W-02 | `HIT*` (any form) + `ME` + `ADULT`, ±3 | `אבא מרביץ לי`, `אמא הרביצה לי`, `אמא סטרה לי`, `הגננת מכה אותי`, `המורה הרביצה לי`, `הדוד בועט בי`, `אבא שלי מרביץ לי כל יום` | T1 | L | A named adult hitting the child is the clearest physical-harm statement. |
| W-03 | `HIT*` (singular) + `ME`, no ADULT, ±3 | `הוא מרביץ לי`, `היא מרביצה לי`, `הרביץ לי`, `הכה אותי`, `היא הכתה אותי`, `אחי הרביץ לי`, `מכה אותי`, `בועט בי` | **T2** | **H** | Legacy `מכה אותי`, `מרביץ לי`, `מרביצה לי` were an alert. With two siblings on one tablet this is the commonest harmless trigger. Keep as "check", not "important". |
| W-04 | give/get blows | `[נותנים/נתנו/נותן/נתן/נותנת/נתנה] לי [מכות/מכה/סטירה/סטירות/בעיטות/אגרוף/אגרופים]`; `[חטפתי/אכלתי/קיבלתי/חוטף/אוכל/מקבל] [מכות/סטירה/סטירות/בעיטות]` | T2; T1 if plural subject (`נותנים`, `נתנו`) or `ADULT` ±3 | M | Colloquial Hebrew for being beaten (`אכלתי מכות`). |
| W-05 | choking | `[חונק/חונקת/חונקים/חנק/חנקה/חנקו] ME`; `שם לי יד על הצוואר` | T2; T1 if plural or `ADULT` | M | Strangulation is a recognised high-risk form of harm. Wrestling play gives false alarms. |
| W-06 | burning, tying | `[שורף/שורפת/שורפים/שרף/שרפה/שרפו/קושר/קושרת/קושרים/קשר/קשרה/קשרו] ME` | T2; T1 if plural or `ADULT` | M | Rare in play, serious if real. Pirate games give some false alarms. |
| W-07 | locking in, shutting out | `[נועל/נועלים/נעל/נעלו/סוגר/סוגרים/סגר/סגרו/משאירים/השאירו] ME [בחדר/בארון/בשירותים/במרפסת/במחסן/בחושך/בחוץ]`, ±3 | T2; T1 if plural or `ADULT` | M | A known form of harmful punishment. Hide-and-seek gives false alarms. |
| W-08 | pushing, pinching, biting, hair, throwing | `[דוחף/דוחפת/דוחפים/דחף/דחפה/דחפו/צובט/צובטת/צובטים/צבט/צבטה/צבטו/נושך/נושכת/נושכים/נשך/נשכה/נשכו] ME`; `מושך לי בשיער`; `זורק עלי [דברים/צלחת/כיסא/נעל]` | T2; T1 only with `ADULT` | **H** | Everyday peer conflict at 3 to 8. Worth a "check" only. |
| W-09 | visible marks | `[יש לי/יש לי הרבה] [חבורות/חבורה/כחולים/סימנים/שריטות]` with `[מאבא/מאמא/ממנו/ממנה/מהם/מהמכות/מזה ש]`, ±4 | T2 | M | A child naming a person as the source of marks. Without the person, nothing fires (children fall all day). |
| W-10 | violence the child sees (`PHYS`, witness) | `[אבא/אמא/הוא/היא/בן הזוג של אמא/החבר של אמא] [מרביץ/מרביצה/מכה/הכה/הכתה/הרביץ/הרביצה/חונק/בועט/דוחף] [לאמא/לאבא/את אמא/את אבא/לסבתא/לאחותי/לאחי]` | T2; T1 if `בבית`, `אצלנו`, `אצלנו בבית` or `כל יום` ±4 | **M-H** | Seeing a carer hit another carer is harm to the child. Doll and puppet play with a family gives false alarms, but play is also how young children tell. |

### 3.2 Sexual harm (SEX)

| ID | Pattern | Variants (ready to use) | Tier | FP | Why |
|---|---|---|---|---|---|
| W-11 | `TOUCH` + (`ME` or `שלי`) + `BODY`, ±4 | `נגע לי בפיפי`, `נגעו לי בציצי`, `נוגע בבולבול שלי`, `שם לי יד בתחת`, `המורה נגעה בי בפיפי`, `דוד שם יד בפיפי`, `נישק לי בפיפי`, `ליטף לי את הפיפי`, `נגע לי במקום הפרטי` | T1 | L-M | Replaces legacy `נגעו בי` / `נוגעים בי`. Bare "touched me" is **not** an entry: it is the commonest sibling complaint ("he touched me!"). With a body word it is specific. At 3 to 6, same-age exploration happens; a parent should still know. |
| W-12 | showing the body | `[הראה/הראתה/הראו/מראה/מראים/הוציא/הוציאה] (לי) (את) BODY (שלו/שלה)` | T2; T1 with `ADULT` ±4 | M | Peer "doctor play" is developmentally common at 3 to 6, so T2. An adult doing it is not. |
| W-13 | asked to touch or undress | `[ביקש/ביקשה/מבקש/מבקשת/ביקשו] (ממני) (ש)[אגע/אלטף/אתפוס/אישק/אראה/אוריד/אתפשט/לגעת/ללטף/להוריד/להראות/להתפשט]` with `BODY` or `[תחתונים/בגדים/מכנסיים]` ±4 | T1 with `ADULT`; T2 otherwise | L | Being asked to touch or show is a classic form of abuse and of grooming. |
| W-14 | being undressed | `[הוריד/הורידה/הורידו/מוריד/מורידה/מורידים] לי (את) [התחתונים/המכנסיים/המכנסים/הבגדים/החולצה/בגד הים]` | T2, **ages 5 to 8 only** | H | Routine care for 3 to 4 year olds (dressing, toilet, change). Do not fire at ages 3 to 4. |
| W-15 | photographed undressed | `[צילם/צילמה/צילמו/מצלם/מצלמת/מצלמים] (אותי) [בלי בגדים/עירום/ערום/עירומה/ערומה/בתחתונים/במקלחת/בשירותים/כשאני מתקלח/כשאני מתקלחת]` | T1 | L | Rare as play, serious if real. |
| W-48 | rape word | `[אנס/אנסו/אונס/אונסים/מנסה לאנוס/מנסים לאנוס] ME`; `אנסו אותי`; `לאנוס אותי` | T1 | L | A young child rarely uses the word; if used, treat as important. |

### 3.3 Fear and threat, bullying (FEAR)

| ID | Pattern | Variants | Tier | FP | Why |
|---|---|---|---|---|---|
| W-16 | threats | `[מאיימים/מאיים/מאיימת/איימו/איים/איימה] [עלי/על אמא/על אחי/על אחותי]` | T2; T1 with `ADULT` ±3 | M | Legacy `מאיים עלי` / `מאיימים עלי`. |
| W-17 | threat reported | `[אמר/אמרה/אמרו/אומר/אומרת/אומרים/איים] (ש)[יהרוג/יהרגו/ירצח/ירצחו/יחתוך/יחתכו/ישחט/יפגע/יפגעו/יכאיב/יכאיבו/יכה/יכו/ירביץ/ירביצו/ישבור] ME`, ±4 | T2; T1 if `ADULT` and a kill/cut verb | H | **Bare `אבא יהרוג אותי` / `אמא תהרוג אותי` is an everyday Hebrew idiom ("I'm in big trouble") and is deliberately not matched.** Only a reported threat counts. |
| W-18 | afraid of a named person | `[פוחד/פוחדת/מפחד/מפחדת] [ממנו/ממנה/מהם/מהן/מאבא/מאמא/מסבא/מסבתא/מדוד/מהדוד/מהדודה/מהגננת/מהמורה/מהסייעת/מהמטפלת/מהמטפל/מהשכן/מהשכנה/מהמדריך/מהמאמן/מהחבר של אמא/מהחבר של אבא/מבן הזוג של אמא]` | T2 | M | Children rarely say "I'm abused"; they say who they fear. Bare `אני פוחד` (dark, dogs, thunder) is **not** an entry. |
| W-19 | afraid to go home | `[פוחד/פוחדת/מפחד/מפחדת] [לחזור/ללכת/להיות/לישון/להישאר] [הביתה/בבית/לבית]` | T1 | M | Legacy `פוחד לחזור הביתה` / `פוחדת לחזור הביתה`, now with `מפחד`, more verbs and the other gender. |
| W-20 | afraid of gan or school | `[פוחד/פוחדת/מפחד/מפחדת] [לחזור/ללכת/להיות] [לגן/בגן/לבית ספר/בבית ספר/לכיתה/בכיתה/לצהרון/בצהרון]` | T2 | M | Bullying or a harmful adult in the setting. Also a sign of ordinary school anxiety. |
| W-21 | "they scare me" | `[מפחידים/הפחידו/מפחידות] אותי` | T2 | **H** | Legacy `מפחידים אותי`. Demoted: monsters and films. Singular `זה מפחיד אותי` is **not** an entry. |
| W-22 | harassment | `[מציקים/מציק/מציקה/הציקו/הציקה] ME` | T2 | M | Bullying. |
| W-23 | abuse word | `[מתעללים/מתעלל/מתעללת/התעללו/התעלל/התעללה] בי` | T1 | M | A child may say it for tickling or teasing, but the word itself is a serious one. |
| W-24 | name-calling, exclusion | `[קוראים/קראו/קורא/קראה] לי שמות`; `[מקללים/קיללו/מקלל/קיללה] אותי`; `[עושים/עשו/עושה/עשתה] לי חרם`; `חרם עליי` | T2 | M | Peer bullying, mostly ages 6 to 8. |

### 3.4 Neglect and being alone (NEGL)

| ID | Pattern | Variants | Tier | FP | Why |
|---|---|---|---|---|---|
| W-25 | alone at home | `[אני/אנחנו/אני ואחי/אני ואחותי] לבד [בבית/בדירה]`; `אין אף אחד בבית`; `אף אחד לא בבית`; `[נשארתי/נשאר/נשארת/נשארים] לבד [בבית/בלילה/בערב]`; `[השאירו/משאירים/השאיר/השאירה/עזבו/עוזבים] אותי לבד (בבית)` | **T1 at ages 3 to 5; T2 at 6 to 8** | M | Legacy `אני לבד בבית`. A very young child alone is an immediate safety issue and a legal one (Israeli law treats leaving a child up to 6 unsupervised as an offence, per a Knesset summary; see review). At 7 to 8 it can be a normal short stay. |
| W-26 | hunger | `לא אכלתי [כל היום/מאתמול/כלום/מהבוקר]`; `[לא נתנו/לא נותנים/לא נתן/לא נתנה] לי [אוכל/לאכול/לשתות/מים]`; `אין לנו אוכל בבית`; `אין אוכל בבית` | T2 | M | Bare `אני רעב` and bare `אין אוכל` (play kitchens, word problems) are **not** entries. |
| W-27 | carer impaired | `[אמא/אבא] [שיכור/שיכורה/שתוי/שתויה/מסטול/מסטולה]`; `[אמא/אבא] [ישן/ישנה] כל היום`; `[אמא/אבא] [ישן/ישנה] ולא [קם/קמה]` | T2 | M-H | Alcohol or drugs, or a carer too ill to care. Children also describe a parent's afternoon nap. |
| W-28 | possible emergency | `[אמא/אבא/סבא/סבתא/אחי/אחותי/הוא/היא] [נפל/נפלה/שוכב/שוכבת/על הרצפה]` with `[ולא] [זז/זזה/קם/קמה/מתעורר/מתעוררת/נושם/נושמת/עונה/מגיב/מגיבה]`, ±4; `[אמא/אבא] לא [נושם/נושמת/מתעורר/מתעוררת]` | T1, with the *emergency* wording (101) | M-H | A child alone with an unwell adult. High cost of a miss, so T1 despite play false alarms. |
| W-29 | put out | `[זרקו/זורקים/זרק/זרקה/הוציאו/מוציאים/הוציא/הוציאה/העיפו/מעיפים] אותי מהבית`; `ישנתי [בחוץ/ברחוב/במכונית/במדרגות]` | T2 | M | Being locked out or thrown out. |

### 3.5 Self-harm and death wishes (SELF)

For this block allow up to **two** filler tokens inside a phrase (`אני כל כך רוצה למות`), because children pad this sentence ("really", "so much") and a miss costs more than a false alarm.

Idiom guard for the whole block: `מת מצחוק`, `מתה מצחוק`, `מת מרעב`, `מת מפחד`, `מת על`, `מתה על`, `מת לאכול`, `בא לי למות מבושה` and the like never fire. Apply `NOT-NEAR = [מצחוק/מבושה/מהבושה/מרעב/מעייפות/מפחד/מצער/מקור/מחום]` within 2 tokens after the phrase.

| ID | Pattern | Variants | Tier | FP | Why |
|---|---|---|---|---|---|
| W-30 | wants to die | `(אני) רוצה למות`; `רוצה למות`; `(אני) ממש רוצה למות` | T1 | M | Legacy `אני רוצה למות`; `אני` now optional because children and the recogniser drop it. See the review: a young child's meaning is unclear, so it is taken seriously. |
| W-31 | does not want to live | `(אני) לא רוצה לחיות (יותר/עוד/כבר/בכלל)`; `נמאס לי לחיות`; `נמאס לי מהחיים`; `(אני) לא רוצה להיות בחיים`; `לא רוצה להיות בחיים` | T1 | L | Legacy `לא רוצה לחיות`. **Guard: `לא רוצה לחיות בעיר / בבית הזה / בישראל / איתו` (a place or person follows) does not fire as T1.** `לא רוצה לחיות איתו/איתה/עם` is T2. |
| W-32 | wish not to exist | `הלוואי שהייתי מת`; `הלוואי שהייתי מתה`; `הלוואי שאמות`; `הלוואי שלא נולדתי`; `הלוואי ולא נולדתי`; `מוטב שאמות`; `עדיף שאמות`; `עדיף שלא נולדתי` | T1 | L | Passive death wish. |
| W-33 | suicide, self-killing | `(אני) [רוצה/הולך/הולכת] [להתאבד/להרוג את עצמי/לפגוע בעצמי/לחתוך את עצמי/לעשות לעצמי משהו]`; `[אתאבד/אהרוג את עצמי/אפגע בעצמי/אחתוך את עצמי]`; `אקפוץ [מהחלון/מהגג/מהמרפסת/מהקומה]`; `התאבדות`; `להתאבד` | T1 | L | Active ideation words. |
| W-34 | "I want to die" as slang | `בא לי למות` (without an idiom word after) | T2 | H | Common colloquial exaggeration (embarrassment, boredom); still worth a "check" if no idiom follows. |
| W-35 | wants to vanish | `(אני) [רוצה/רוצים] [להיעלם/להעלם/לברוח מהכל/לישון ולא להתעורר/שהכל ייגמר/שהכל יגמר/לא להיות כאן/לא להיות יותר/להיעלם מהעולם]` | T2 | M | Indirect form of the same feeling. |
| W-36 | worthlessness, burden | `(אני) [שונא/שונאת] את עצמי`; `(אני) לא שווה כלום`; `כולם [יהיו/יהיה] יותר טוב בלעדיי`; `אני [מעמסה/נטל] על כולם`; `אני [אשם/אשמה] בהכל` | T2 | M | More typical at 6 to 8. A single mention is a "check". |
| W-37 | hurting oneself | `(אני) [פוגע/פוגעת/חותך/חותכת/שורט/שורטת/נושך/נושכת/מכה/מרביץ/מרביצה] [את עצמי/בעצמי/לעצמי]`; `דופק לעצמי את הראש בקיר` | T2 (**T3 at ages 3 to 5**) | H | Head-banging and hitting oneself are common in tantrums of 3 to 5 year olds. Over 6 it is a signal. |

### 3.6 Online and strangers (ONLINE)

`UNKNOWN` = `[איש/גבר/אדם/בחור/אישה]` together with `[זר/זרה/שאני לא מכיר/שאני לא מכירה/לא מוכר/לא מוכרת/מהאינטרנט/מהמשחק/מהטלפון/בטלפון/בצאט/ברשת/במשחק]` (±3). `CONTACT` = `[כתב/כתבה/כותב/דיבר/דיברה/מדבר/התקשר/התקשרה/שלח/שלחה/שולח/ביקש/ביקשה/מבקש/מבקשת/אמר/אמרה]`.

| ID | Pattern | Variants | Tier | FP | Why |
|---|---|---|---|---|---|
| W-38 | contact from an unknown adult | `UNKNOWN` + `CONTACT`, ±4 | T2 | H | `איש בטלפון ביקש ממני`, `גבר זר כתב לי`. Game chat with real friends is the false alarm. `ילד` is deliberately not in the set. |
| W-39 | unknown adult asks for something | W-38 **and** `[תמונה/תמונות/סרטון/סרטונים/להיפגש/ניפגש/כתובת/מספר טלפון/לצלם/להתפשט/להוריד/להראות/לא לספר/סוד]` ±5 | T1 | L-M | Photo, meeting, address or secrecy asked by an unknown adult is the grooming pattern. |
| W-40 | asked for a photo of the body | `[ביקש/ביקשה/מבקש/מבקשת/ביקשו] (ממני) (ש)[אשלח/לשלוח/אצלם/לצלם] [תמונה/תמונות/סרטון]` with `[בלי בגדים/של הגוף/של הפיפי/עירום/ערום]` ±5 | T1 | L | Direct solicitation. |
| W-41 | shown adult material | `[ראיתי/רואה/ראינו/הראו לי/הראה לי/שלחו לי/שלח לי] [סרטון/סרט/תמונות/תמונה] [של] [אנשים/גברים/נשים] [בלי בגדים/ערומים/עירומים/עירום/ערום/עושים סקס]` | T2 | M | Exposure to sexual content, at home, on screens or via classmates. |
| W-42 | online bullying | `[מקללים/קיללו/מעליבים/צוחקים/כותבים/כתבו/שלחו] [עלי/אותי/לי] [בקבוצה/בוואטסאפ/בצאט/ברשת/בטיקטוק/במשחק]`, ±4 | T2 | M | Mostly ages 7 to 8 (class chat groups). |

### 3.7 Secrecy (SECRET)

Guard for the whole block: if `[מתנה/הפתעה/יום הולדת/יומולדת/מסיבה/הפתעות]` is within 5 tokens, nothing fires (surprises are good secrets).

| ID | Pattern | Variants | Tier | FP | Why |
|---|---|---|---|---|---|
| W-43 | forbidden to tell | `[אסור לי/אמר שאסור/אמרה שאסור/אמרו שאסור] [לספר/להגיד/לדבר] [לאמא/לאבא/להורים/לאף אחד/לגננת/למורה]` | T2 | M | Secrecy is both a tool of abusers and a child's own wish to hide something. |
| W-44 | told not to tell | `[ביקש/ביקשה/אמר/אמרה/ביקשו/אמרו] [ממני/לי] (ש)[לא/אל] [לספר/להגיד/לדבר/אספר/אגיד/אדבר]` | T2 | M | Same. |
| W-45 | threat for telling | `[אם אספר/אם אגיד/אם אגלה]` + `[יכה/ירביץ/יפגע/יהרוג/יכאיב/יעשה לי משהו/יעשה לי רע/יחתוך/ישבור/יקח אותי/יזרוק אותי]`, ±4 | T1 | L | A coercion statement. `אם אספר אמא תכעס` is ordinary and not an entry. |
| W-46 | secret game with an adult | `[משחק/משחקים] [סודי/סודיים/סוד/של סוד/מיוחד שאסור לספר]` with `ADULT` ±4 | T2 | M | A common grooming device. |
| W-47 | asks the tutor to keep a secret | `[אל תספר/אל תספרי/אל תגיד/אל תגידי/שלא תספר/שלא תספרי/שלא תגיד/שלא תגידי] [לאמא/לאבא/להורים/לאף אחד]` | T3; T2 if combined (C-2) | M | Usually harmless ("I broke the cup"). Its main use is to make the tutor **never promise secrecy** (see wording drafts). |

**Counting:** 48 phrase entries (W-01 to W-48). Base tier T1: 15 rows (W-01, 02, 11, 15, 19, 23, 28, 30, 31, 32, 33, 39, 40, 45, 48). Age-dependent: 1 (W-25). T2: 31 rows, several of which become T1 under a stated condition (adult named, plural subject, repeat). T3: 1 row (W-47).

---

## 4. Combination and escalation rules

| ID | Rule | Result |
|---|---|---|
| C-1 | Any two T2 hits for the same child within 7 days (across answers, any subcategory) | One T1 alert "repeated", showing the dates, not the words unless the parent keeps words. |
| C-2 | A SECRET hit (W-43 to W-47) together with any PHYS, SEX or FEAR hit in the same answer or within 24 hours | T1. |
| C-3 | W-38 with a request (W-39) in one answer | T1 (already built into W-39). |
| C-4 | A T3 swear and a T1 or T2 phrase in one answer | The phrase wins (as today: a disclosure wins). Count the swear in the digest. |
| C-5 | An intensity word (`כל יום`, `כל הזמן`, `שוב ושוב`, `הרבה פעמים`, `חזק`, `עד שיוצא דם`) in the same answer as a PHYS, FEAR or SEX hit | Do not change the tier. Add "said it happens often" to the parent text. |

---

## 5. Words and phrases deliberately NOT included

| Word or phrase | Why it is out |
|---|---|
| `כוס` alone | A cup. Already an existing test. |
| `תחת` alone | "Under" (`תחת העץ`). Only `בתחת` / `לתחת` with a touch verb count. |
| `זיין` alone | Weapons (`כלי זיין`) and a letter-name spelling. Only the verb family counts. |
| `שיט` (Hebrew spelling) | Boating. The Latin `shit` is in. |
| `ציפור`, `שפן` as body words | A bird, a rabbit. Cannot be separated from the animal. |
| `פיפי`, `קקי`, `ישבן`, `בולבול` as swear words | Normal toilet and body words at 3 to 6. They count only inside W-11 to W-13. |
| `אידיוט`, `טיפש`, `טמבל`, `מטומטם`, `דביל`, `שתוק`, `סתום` | Ordinary playground insults. Alerting on them would flood the parent. |
| `אני שונא אותך`, `אני אהרוג אותך`, `תמות` | Tantrum language aimed at others. Not a disclosure. |
| `אבא ואמא רבים`, `אבא צועק`, `צועקים עליי` | Shouting and arguments are common; a single report says too little. |
| `אמא תהרוג אותי`, `אבא יהרוג אותי` | Idiom for being in trouble. Only a reported threat (W-17) counts. |
| `נגע בי`, `אל תיגע בי`, `הוא נגע בי` | Playground complaint, "tag" games. Needs a body word (W-11). |
| `פגע בי`, `הכדור פגע בי` | Includes balls and hurt feelings. |
| `זה מפחיד אותי`, `אני פוחד` | Films, dark, dogs. |
| `אני לבד`, `אני לבד בחדר`, `אני משחק לבד` | Playing alone. Only `לבד` + `בבית` or `בדירה` counts. |
| `כואב לי בפיפי`, `כואב לי הבטן` | Urinary infections, constipation and tummy aches are common and medical. A parent knows. |
| `אני רעב`, `אין אוכל` | Everyday, and play kitchens or word problems. |
| `יש לי סוד`, `זה סוד` | Children love secrets. Only the forbidden-to-tell shapes count. |
| `לא רוצה לחזור הביתה`, `לא רוצה ללכת לגן` | Very common after fun or at drop-off; too noisy. Only the "afraid" forms count (W-19, W-20). |
| `אני בורח מהבית`, `אני עוזב את הבית` | Common tantrum threat of 4 to 8 year olds. The owner may want it as T3. |
| `הומו`, `לסבית`, `יהודי`, `ערבי`, `מוות`, `מת` | Neutral or identity words; not the app's business to flag. |
| `אני הרבצתי`, `אני מרביץ`, `הרבצתי לו` | A child as hitter. Out of scope for a disclosure alert (a different question for the owner, Q8). |
| `אין לי חברים`, `אף אחד לא משחק איתי` | Real, but too common to alert on from a few words. |
| `סבא/סבתא מת` | Grief is normal; not an alert. |

---

## 6. Age rules (summary table)

| Rule | Ages 3 to 4 | Ages 5 to 6 | Ages 7 to 8 |
|---|---|---|---|
| T3 swear words (S-list) | Counted only; digest off by default | Weekly digest | Weekly digest, words shown if kept |
| W-14 being undressed | Off | On, T2 | On, T2 |
| W-25 alone at home | T1 | T1 | T2 |
| W-37 hurting oneself | T3 | T2 | T2 |
| W-12 peer showing body | T2 | T2 | T2 (T1 if one is clearly much older, not detectable) |
| Self-harm block W-30 to W-33 | T1 | T1 | T1 |
| W-36 worthlessness | Off | T2 | T2 |
| W-42 online bullying | Off | Off | T2 |

---

## 7. Maintenance

- Move both lists out of the Dart source into a versioned, signed data file in the existing pack mechanism (security-engineer to review) so a counsellor's corrections do not need an app release. The file carries `version`, `reviewed_by`, `reviewed_on`, and the list version is stored on every alert for audit.
- Every change to a list needs: the editor's spelling check, the counsellor's content check, and the test list in `alert-test-list.md` passing.
- Re-review every 6 months, and whenever the recogniser model changes.
