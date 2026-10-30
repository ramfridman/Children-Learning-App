# Alert wording drafts: parent messages and tutor lines

**Status:** DRAFT. Every Hebrew string here is `review: needs-editor` and must be validated by the hebrew-text-editor (grammar, gender, number, nikud, voice-readiness) and read by a counsellor before it reaches a user. Written by an AI acting as a child-psychology adviser; not a clinician. The voice versions of the tutor lines belong to the voice-and-sound-director, and **voicing is the owner's step, not Claude's** (CLAUDE.md hard rule). No Hebrew here has niqqud; the editor adds it.

Conventions: `{child}` is the first name; `{words}` is the kept text; `{n}` a count; `[ה]` marks a feminine ending (`אמר[ה]` is `אמר` for a boy, `אמרה` for a girl). A gender-form mechanism already exists in the app; use it instead of slashes.

Related files: `alert-word-lists-review.md` (why), `alert-word-lists-proposed.md` (lists and tiers), `alert-test-list.md` (tests).

---

## 1. What exists today, and a verdict

From `app/lib/strings/he.dart`:

| Key | Text | Verdict |
|---|---|---|
| `alertSwearTitle` | `נאמרו מילים לא הולמות` | Keep the idea. Change to the digest wording in 2.5. |
| `alertSwearDo` | `אפשר לשוחח על כך בנחת. ההתראה לא מוצגת בצד של הילדים.` | Good tone; add one line on why children do it. |
| `alertDisclosureTitle` | `נאמר משהו שעשוי להדאיג` | Fine for T2. For T1 use a clearer title (2.1). |
| `alertDisclosureDo` | `כדאי לשוחח בנחת ובפרטיות, בלי ללחוץ.` | Too thin for the most serious alert: no what-to-say, no mention that the recogniser may be wrong, no help numbers, no "do not interrogate". |

The tutor line in PLAN.md (line 341) and `docs/curriculum.md` section 11.6:
`זֶה חָשׁוּב. כְּדַאי לְסַפֵּר לְמִישֶׁהוּ גָּדוֹל שֶׁאַתָּה סוֹמֵךְ עָלָיו.`
I found no use of this line in `app/lib`; it appears to exist only in the documents. The owner or app-developer should confirm.

---

## 2. Parent-facing messages

### 2.1 T1 alert (important). One template plus an add-on per subcategory

**Title:** `נאמר משהו שחשוב לשים אליו לב`

**Body (always):**

> {child} אמר[ה] משהו שנשמע כמו דאגה: «{words}»
> *(if the parent turned off "keep the words":)* {child} אמר[ה] משהו שנשמע כמו דאגה. המילים לא נשמרו, לפי ההגדרות שלך.
>
> האפליקציה לא תמיד מבינה ילדים נכון. ייתכן שזה היה משחק או סיפור, וייתכן שהיא טעתה. היא לא יודעת מה קרה, ואינה מאבחנת דבר.
>
> **מה כדאי לעשות עכשיו**
> • למצוא זמן רגוע ומקום פרטי, ולשוחח עם {child} בלי ללחוץ.
> • להקשיב. אפשר לשאול שאלה פתוחה אחת, כמו «למה התכוונת?» או «מה רצית לספר לי?». לא לחקור ולא להציע תשובות.
> • לומר: «טוב שסיפרת לי. אני מאמין לך. זו לא אשמתך.»
> • לא להבטיח לשמור סוד. אפשר לומר: «אעשה מה שצריך כדי שתהיה בטוח.»
> • אם יש חשש שמישהו פוגע ב{child}, לא להתעמת איתו לפני שהתייעצתם.
>
> **אפשר להתייעץ עוד היום, גם בלי להגיש תלונה**
> • 118: מוקד המידע והסיוע של משרד הרווחה. חינם, 24 שעות ביממה, בעברית, בערבית, באמהרית וברוסית. אפשר גם הודעה בוואטסאפ ל-050-2270118.
> • 1201: ער"ן, עזרה ראשונה נפשית אנונימית בטלפון ובצ'אט, גם להורים.
> • 100 משטרה, 101 מגן דוד אדום: בסכנה מיידית.
>
> בהרבה מקרים של פגיעה בילד חלה בישראל חובת דיווח למשטרה או לעובד סוציאלי לפי חוק הנוער. 118 יכול להסביר אם וכיצד זה חל אצלכם.
>
> האפליקציה אינה מדווחת לאף גורם. ההחלטה מה לעשות היא שלך.

Why these choices (sources in the review): the Ministry of Education counselling-service leaflet and the Haruv "טוב שסיפרת" kit both say: listen without alarm, do not interrogate or flood with questions, say plainly the child is not to blame, believe the child, and consult professionals; Haruv adds that interrogating at home can damage a later professional interview. The Ministry of Health page says the duty to report exists on a "reasonable ground" and goes to a youth-law social worker or the police.

### 2.2 Add-ons by subcategory (shown under the template)

**PHYS (someone hits the child):**
> אם נאמר שמישהו מרביץ: כדאי לבדוק אם יש סימנים על הגוף ולהראות לרופא/ת הילדים. אם מדובר במבוגר שאחראי על {child}, התייעצו לפני כל פנייה אליו.

**SEX (touching, undressing, photos):**
> אם נאמר משהו על נגיעה או על צילום: להקשיב בלי להיבהל ולא לחקור בעצמכם. התייעצו מיד עם 118 או עם מרכז הגנה «בית לין»; אפשר להתייעץ גם בלי למסור שם. אם יש חשש לפגיעה שהייתה בימים האחרונים, המרכזים האקוטיים בבתי החולים פועלים 24 שעות ביממה.

**SELF (death wish, self-harm):**
> ילדים קטנים לא תמיד מבינים מה זה מוות, ולפעמים אומרים זאת בכעס. ובכל זאת, מתייחסים לזה ברצינות. הישארו קרובים, שאלו בשקט למה {child} התכוון[ה], ואל תשאירו אותו[ה] לבד כשקשה. בימים הקרובים כדאי להתייעץ עם יועצת, פסיכולוג/ית או רופא/ת ילדים. בסכנה מיידית: 101 או חדר מיון. ער"ן 1201 זמינה גם לכם.

**NEGL (alone, hunger, impaired carer):**
> אם {child} לבד עכשיו, כדאי לוודא מיד שמבוגר נמצא איתו[ה]. ילד בגיל הזה לא צריך להישאר לבד בבית.

**NEGL-emergency (W-28):**
> אם {child} אמר[ה] שמישהו נפל ולא זז, התקשרו מיד לבית או לאדם הקרוב, וב-101 אם צריך. ייתכן שזה משחק; בדקו עכשיו.

**ONLINE (stranger, photos, adult material):**
> אם מישהו פנה אל {child} בטלפון, במשחק או ברשת: לשמור צילומי מסך ולא למחוק, לא להגיב לפונה, ולדווח למוקד 105 (המטה הלאומי להגנה על ילדים ברשת; ניתן להתקשר מכל טלפון).

**SECRET (told not to tell):**
> ילד שביקשו ממנו לשמור סוד על דבר שמפחיד או כואב צריך לשמוע שמותר לספר: «הפתעות אפשר לשמור. סוד שמפחיד או כואב תמיד מספרים, ולא תהיה בצרות».

### 2.3 T2 alert (attention)

**Title:** `נאמר משהו שאולי כדאי לבדוק`

> {child} אמר[ה]: «{words}»
>
> זה יכול להיות משחק, סיפור, או משהו שנאמר בלי כוונה. ייתכן גם שהאפליקציה שמעה לא נכון. אין צורך להיבהל.
>
> בזמן רגוע, ובלי ללחוץ, אפשר לשאול: «איך היה היום? יש משהו שבא לך לספר לי?»
>
> אם זה חוזר, או אם משהו בהתנהגות של {child} השתנה (שינה, אכילה, פחד מאדם מסוים, חזרה להתנהגות של גיל צעיר), כדאי להתייעץ עם היועצת, עם רופא/ת הילדים או עם 118.

### 2.4 "Repeated" alert (rule C-1, two T2 hits in 7 days)

**Title:** `נאמרו כמה דברים שכדאי לשים אליהם לב`

> בשבוע האחרון נאמרו בכמה הזדמנויות דברים דומים: «{words}». כל אחד מהם לבדו אולי לא מדאיג, אבל יחד כדאי לשוחח עם {child}. ראו את הצעדים ואת מספרי הסיוע למעלה.

(Then reuse the T1 block "what to do now" and the numbers.)

### 2.5 T3 digest (swearing and exposure words)

**Swearing, title:** `מילים לא הולמות השבוע`

> {child} אמר[ה] השבוע {n} פעמים מילה שלא מקובלת. ילדים בגיל הזה חוזרים על מילים ששמעו, בבית, ברחוב או במסך, ולפעמים בודקים איך נגיב. אין צורך להתרגש: אפשר להגיב בשקט, להסביר איזו מילה אפשר ואיזו לא, ולהציע מילה אחרת.
> ההתראה לא מוצגת בצד של הילדים.

Note for the editor: with a recogniser that is wrong more often with young children, say "נשמעה" rather than "נאמרה" if the editor prefers a hedged tone.

**Exposure words (`סקס`, `פורנו`, ...), title:** `נאמרה מילה מעולם המבוגרים`

> {child} אמר[ה] מילה שקשורה לתכנים למבוגרים. ייתכן ששמע[ה] או ראה[ה] משהו בבית, אצל חברים או במסך. כדאי לשוחח בנחת על מה שראה[ה], ולבדוק אילו תכנים זמינים במכשירים. אם זה קרה ברשת, אפשר לפנות ל-105.

### 2.6 Settings and consent text (what the app may claim)

The app should say what it is and is not, once, where the parent turns alerts on:

> ההתראות הן רשת ביטחון נוספת, לא תחליף להשגחה ולשיחה עם הילד. האפליקציה מקשיבה רק כשהילד לוחץ על המיקרופון, ולא תמיד מבינה ילדים קטנים, ולכן היא לא תתפוס כל דבר. היא אינה מאבחנת ואינה מדווחת לאף גורם.

**The app must not claim:** that it detects abuse, protects the child, monitors the child, replaces a counsellor, reports to the authorities, or that "no alert" means "all is well".

### 2.7 A permanent parent card (not an alert)

A short card in the parent area, such as "שיחה על סודות ועל המקומות הפרטיים" (general body-safety guidance, to be reviewed by a counsellor):

> • הפתעה (מתנה ליום הולדת) אפשר לשמור בסוד. סוד שמפחיד או כואב תמיד מספרים.
> • המקומות שהבגד מכסה הם פרטיים. אף אחד לא נוגע בהם, ואף אחד לא מבקש שנגע בו, חוץ מרופא כשאמא או אבא איתנו.
> • אפשר תמיד לספר לאמא, לאבא או למבוגר אחר שאנחנו סומכים עליו, ואף פעם לא נהיה בצרות כי סיפרנו.
> • כדאי לשאול מדי פעם שאלה פתוחה: «מה היה הכי כיף היום? ומה היה לא נעים?»

---

## 3. What the tutor says

### 3.1 Judgement on the existing line

Keep the **design** of the PLAN line: one caring sentence, no exploring, a trusted adult, then back to a calm place. Change the **text**:

| Point | Existing | Problem | Proposal |
|---|---|---|---|
| Gender | `שֶׁאַתָּה סוֹמֵךְ עָלָיו` | Masculine only; a girl hears the wrong gender | Two forms from the profile |
| Receipt | none | The child is not told they were heard | Open with `שמעתי אותך` |
| Praise | none | A child who tells needs to hear it was right | Add `טוב שסיפרת` |
| Weight | `כדאי` | A suggestion, easy to ignore | A plain, gentle instruction |
| Help | none | Child may think telling changes nothing | Add `והוא יעזור` |
| After | "returns to play" | An instant jump back can feel like being brushed off | Offer a calm pause (see 3.3) |

### 3.2 Draft lines (T1)

Without niqqud; the editor adds it, the voice director sets pace and tone.

| ID | When | Boy | Girl |
|---|---|---|---|
| TL-1 | Default, ages 5 to 8 | `שמעתי אותך. זה חשוב, וטוב שסיפרת. ספר עכשיו למבוגר שאתה סומך עליו, והוא יעזור.` | `שמעתי אותך. זה חשוב, וטוב שסיפרת. ספרי עכשיו למבוגר שאת סומכת עליו, והוא יעזור.` |
| TL-2 | Ages 3 to 4 | `שמעתי. טוב שסיפרת. תספר למבוגר שאתה אוהב, והוא יעזור לך.` | `שמעתי. טוב שסיפרת. תספרי למבוגר שאת אוהבת, והוא יעזור לך.` |
| TL-3 | Death or self-harm words (W-30 to W-33) | `זה נשמע כבד. אני רק עוזר במשחקים ובלמידה, אבל מבוגר שאוהב אותך יכול לעזור באמת. לך אליו עכשיו וספר לו מה אמרת לי.` | `זה נשמע כבד. אני רק עוזרת במשחקים ובלמידה, אבל מבוגר שאוהב אותך יכול לעזור באמת. לכי אליו עכשיו וספרי לו מה אמרת לי.` |
| TL-4 | T2 hit, fear, bullying (mild) | `זה לא נעים. אפשר לספר על זה למבוגר שאתה סומך עליו.` | `זה לא נעים. אפשר לספר על זה למבוגר שאת סומכת עליו.` |
| TL-5 | The child asks the tutor to keep a secret (W-47) | `אני לא יכול לשמור סוד על משהו שמפחיד או כואב. מבוגר שאתה סומך עליו יכול לעזור.` | `אני לא יכולה לשמור סוד על משהו שמפחיד או כואב. מבוגר שאת סומכת עליו יכול לעזור.` |
| TL-6 | Swearing (T3) | `זו לא מילה שאומרים כאן. בוא נחזור לשחק.` | `זו לא מילה שאומרים כאן. בואי נחזור לשחק.` |

(The tutor speaks as the companion character; the pronoun of the companion — `אני עוזר` or `אני עוזרת` — follows the character, not the child. Editor to fix.)

### 3.3 Rules for the tutor (behaviour, not wording)

1. **One line, then stop.** Never ask a question, never repeat the child's words back, never ask "who?" or "where?". Questions can contaminate a later professional interview (Haruv; Ministry of Education), and the project's own rule already says the tutor asks no personal questions.
2. **Never promise secrecy, and never say "I will tell your parents".** Both would be untrue or frightening. TL-5 is the honest answer.
3. **Never say** "don't worry", "it's nothing", "you are in trouble", "are you telling the truth".
4. **Be pre-recorded and chosen on the device** by the matcher. No model improvises here.
5. **After the line:** do not rush back into a lesson. Suggestion for the design-director: a calm pause screen with the character sitting quietly and two big buttons (continue playing / stop), no sound effects, no stars, no timer. The child chooses.
6. **Voice:** slow, warm, lower in pitch, no jingle, no celebration sound, music ducked. (voice-and-sound-director.)
7. **No difference in the child's space between a true and a false alarm:** the child must never be told they were "reported" or "flagged", and the app never scolds (PLAN).

### 3.4 When a child asks "are you a person?" or "will you tell my mum?"

The project already says the tutor says it is a computer helper. For "will you tell?" use TL-5. Do not answer "yes, I will" or "no, never".

---

## 4. What the hebrew-text-editor must validate

1. Every Hebrew line in sections 2 and 3: grammar, gender and number (the `[ה]` forms, `אתה/את`, `סומך/סומכת`, `אוהב/אוהבת`), punctuation of quotes `«»` against the app's style, readability for a worried parent.
2. The companion's own gender in TL-3 and TL-5.
3. Voice-readiness of TL-1 to TL-6 (nikud, numbers, no abbreviations). The numbers `118`, `1201`, `105`, `100`, `101` and the phone number must be written so they can be read on the screen only (no voice).
4. The word `ער"ן` (quote mark inside) and how `ער"ן`, `בית לין` and `משרד הרווחה` are written.
5. Whether `«למה התכוונת?»` and `«מה רצית לספר לי?»` suit a worried parent, or the counsellor prefers other open questions.
6. That no line diagnoses, blames or promises anything.
