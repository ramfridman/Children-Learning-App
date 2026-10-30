# Hebrew validation of the child-safety documents

Written by the hebrew-text-editor on 2026-10-29, for the owner, the child-psychology adviser, the app-developer and the
voice-and-sound-director. Read-only review of the four files in this folder (`alert-word-lists-proposed.md`,
`alert-wording-drafts.md`, `alert-test-list.md`, `alert-word-lists-review.md`); none of them was changed. Nothing here was
voiced.

**Status: `final-draft`** (updated the same day with the owner's answers, section 7). The clean parent and tutor texts
(section 5) and the list corrections (section 2) are final as Hebrew. Every string stays `review: needs-editor` in the
app until the owner approves it there. The counsellor and lawyer points in section 7 are still open. Section 8 is the
list for the app-developer.

**What I checked:**
- **Lists:** spelling as the recogniser writes it: no nikud, full spelling (ktiv male), the yod/vav variants, gender
  forms and the one-letter prefixes.
- **Swearing and the body:** the swear and slang spellings, and the child-body vocabulary.
- **Parent alerts:** grammar, register and tone (calm, not diagnostic, no blame, written for a worried parent).
- **Tutor lines TL-1 to TL-6:** gender, nikud, readiness for a voice, one caring line pointing to a trusted adult, no
  promise of secrecy, no question.
- **Help names and numbers:** how the helpline and service names and numbers are written.
- **The psychologist's checklist:** the six points of `alert-wording-drafts.md` section 4.

**What I did not check:**
- whether the lists are complete (that needs a gan or school counsellor);
- the law (that needs a lawyer);
- how anything sounds (no audio).

Status values in the tables:
- **fix**: a language error; the corrected form is the one to use.
- **add**: a missing form the matcher needs.
- **suggest**: better wording; the meaning is unchanged.
- **owner**: needs the owner's decision.
- **counsellor**: needs a counsellor or social worker.
- **ok**: checked and right.

## 1. Rules that apply everywhere (please adopt them before the lists are coded)

| # | Rule | Why |
|---|---|---|
| R-1 | **Never attach a prefix letter to `{child}`.** Write `עם {child}`, `על {child}`, `אל {child}`, never `ב{child}` or `ל{child}`. | B-26 showed that names can be in Latin letters; `בDana` breaks, and a prefix before a name in Hebrew letters is also hard to read. The drafts have `פוגע ב{child}` (2.1). |
| R-2 | **No gender slashes and no `[ה]` in the parent texts** where a neutral wording exists: `במשחק של {child} נשמעו המילים` instead of `{child} אמר[ה]`. | The neutral profile has no gender. The neutral wording is also honest about the recogniser ("were heard", not "said"). |
| R-3 | **Address parents in the plural or with the infinitive**, never with a singular `שלך` mixed with a plural `התייעצתם`. | The drafts mix `ההגדרות שלך`, `ההחלטה היא שלך` with `התייעצתם`, `ראו`. The app's adult texts use the infinitive for advice (hebrew-notes.md §2.8). |
| R-4 | **Acronyms take gershayim (U+05F4), quotations take ASCII `"`:** `ער״ן`, `שפ״ח`, `עו״ס`, `צ׳אט` (geresh U+05F3). Quotes in the app are `"..."`; the app has no `«»`. | With ASCII `"` inside `ער"ן` and quotation marks around a sentence, a Dart string and a screen reader both break. In the recogniser lists the geresh is a space (`normalizeHebrew`), so list both `צ אט` and `צאט`. |
| R-5 | **Phone numbers are screen-only**, isolated left to right with U+2066 … U+2069 (`⁦050-2270118⁩`) and tappable. They never go into a voiced line. | In a right-to-left line `050-2270118` can be shown as `2270118-050`. This is the same rule as hebrew-notes.md A2. |
| R-6 | **Full spelling as the Academy writes it, plus the common one:** `אימא` and `אמא`; `הכול` and `הכל`; `ייקח` and `יקח`; `היכה` and `הכה`. The proposed yod/vav collapse handles `עליי`/`עלי`, but **not** a missing letter (`הכל`/`הכול`, `אמא`/`אימא`). | The recogniser may write either form. |
| R-7 | **Gender forms of the child's own verbs** (`חוטף/חוטפת`, `מקבל/מקבלת`, `אוכל/אוכלת`) and **feminine third person futures** (`תכה`, `תרביץ`, `תהרוג`, `תפגע`) belong in every verb set. | The child may be a girl; the person spoken about may be a woman. |
| R-8 | **Prefix tolerance also for the ADULT set** (`ה`, `מ`, `ל`, `ו`, `ש`): `גננת` and `הגננת`, `מהגננת`, `לגננת`. | Set A mixes `דוד` (no article) with `הגננת` (article); a child says both. |

## 2. Findings on the word lists (`alert-word-lists-proposed.md`)

| Entry | Issue | Corrected form | Status |
|---|---|---|---|
| Set V-1 | `הכה`, `הכו` are written in defective spelling; the recogniser often writes the full spelling. | Add `היכה היכתה` (`היכו` is already there). | add |
| Set V-1 | `בעט` is also `ב+עט` (with a pen). | Keep; the ME window makes a false alarm unlikely. | ok |
| Set V-2 | `נישק` family lacks the plural. | Add `נישקו מנשקים מנשקות`. | add |
| Set V-2 | `הכניס יד` family | Add `הכניסו`, `שם לי אצבע`. | add |
| Set A | `אמא` only | Add `אימא` (Academy full spelling) and the R-8 prefixes. | add |
| Set A | `השמרטף השמרטפית הבייביסיטר` | Spelling right. Also `הבייביסיטרית`. After the yod rule `בייביסיטר` becomes `ביביסיטר`, so load both. | add |
| Set B | Child words `פיפי בולבול ציצי טוסיק ישבן` | Spelled right and in use at gan. `ציצים` is adult slang more than a child word; keep it anyway. | ok / counsellor |
| Set B | Missing: the words body-safety programmes in Israel use | Add `מקום מוצנע`, `מקומות מוצנעים`, `איברים מוצנעים`, and the phrase `המקום שבגד הים מכסה` / `מתחת לבגד הים`. | add / counsellor |
| Set B | Family words for a girl's genitals (`פושי`, `פיפינה`, and others) | Exist in some homes; I cannot say which are common. Ask the counsellor; do not guess. | counsellor |
| Set B | `תחת` bare correctly left out (it means "under") | `בתחת`, `לתחת` only, as written. | ok |
| S-01 to S-03, S-05 to S-07 | Spelling | Right. `תזדייני` and `מזדיינת` collapse to one yod under the yod rule; list one form. | ok |
| S-04 | `מזוין` | Right; `מזויין` collapses to it. | ok |
| S-08 | Joined and split spellings | Add the common fused forms `כוס אמאשך`, `כוסאמאשך`. **`כוסית` (sexist slang) stays out for now**: it is not in the draft, and adding it is the owner's call (open question 1). | add (fused forms); `כוסית` out |
| S-09 | **`זיבי` is not the usual word.** The Arabic-origin slang is `זובי`, which adults also use to mean "nothing at all" (`קיבלתי זובי`), so it would fire on harmless sentences. | **Drop S-09 for now.** `זיבי` is a misspelling, and `זובי` is too noisy to add without the owner's yes (open question 1). | fix (drop) |
| S-10 | `חרבן` is itself vulgar slang ("shit" as a verb), not a plain word for "to defecate" (that is `לעשות קקי` / `לעשות צרכים`). Full spelling `חירבן`. | Add `חירבן מחרבן`; correct the note. | fix |
| S-11 | `בייץ` is not a usual spelling. | `ביץ`, `ביטש` (and `ביץ'` becomes `ביץ` after the geresh rule). Add `אס הול` split. | fix |
| S-11 | `שיט` is left out (it means boating) | Agree, but note that `שיט!` is a very common mild exclamation in Israeli Hebrew, so the gap is real. | ok / owner |
| S-12 | `עירום`/`ערום` | Both are right (full and defective). `ערום` also means "cunning"; inside the phrases that is harmless. | ok |
| S-13 | `מפגר` family | Add `מפגרות`. | add |
| S-15 | `חארות חראות` | Very rare forms. Never add `חרות` (it means "freedom"). Low value; keep only if cheap. | suggest |
| W-04 | The child's own verbs are masculine only | Add `חוטפת`, `אוכלת`, `מקבלת` (R-7). | add |
| W-08 | `מושך לי בשיער` | Add `מושכת`, `משך`, `משכה`, `מושכים`. | add |
| W-13 | **`אישק` is the wrong future** (archaic qal). The future of `נישק` is `אנשק`. | `אנשק`, `לנשק`. | fix |
| W-17 | Futures are masculine only | Add `תהרוג תרצח תחתוך תפגע תכאיב תכה תרביץ תשבור` (R-7). | add |
| W-18, W-09 | `מאמא` | Add `מאימא` (R-6). | add |
| W-20 | `לבית ספר` | Add `לבית הספר`, `בבית הספר`. | add |
| W-22 | `הציקו הציקה` | Add `הציק`. | add |
| W-24 | `קיללו קיללה` | Add `קילל`. | add |
| W-35, W-36 | `הכל` only | Add `הכול` forms: `מהכול`, `שהכול ייגמר`, `בהכול` (R-6). | add |
| W-36 | **`כולם [יהיו/יהיה] יותר טוב בלעדיי` is not grammatical** with `יהיה`. | `לכולם יהיה יותר טוב בלעדיי`; `כולם יהיו יותר שמחים בלעדיי`. | fix |
| W-36 | `מעמסה`, `נטל`, `מוטב` (W-32) are adult words a child of 3 to 8 will not say. | Harmless to keep; they cost nothing. | ok |
| W-42 | `בוואטסאפ` only | Add `בווטסאפ`, `בוואצאפ`, `בווצאפ`; after the vav rule these are `בואטסאפ`, `בוטסאפ`, `בואצאפ`, `בוצאפ`. | add |
| W-42, UNKNOWN | `בצאט` | Also `בצ אט` (geresh becomes a space, R-4). | add |
| W-45 | `יקח` | Add `ייקח` (R-6). | add |
| W-47 | The child's request in the singular only | Add `אל תספרו`, `אל תגידו`. | add |
| Idiom guard (§3.5) | `מת על`, `מתה על`, `מת מצחוק` and the others | Right and complete for the common idioms; add `מתתי מצחוק`, `מתה מצחוק`. | add |
| §5 (left out) | Hebrew is right throughout. | — | ok |
| W-01 to W-48 (the rest) | Spelling and gender of the listed variants | Right. | ok |

**Test list (`alert-test-list.md`):** the Hebrew of all the input strings is right as recogniser output.
- `שלוש פרפרים` (D1, an existing test) is ungrammatical (`שלושה פרפרים`). Keep it, because a child says it like that.
- Add the forms above as tests: `אנשק`, `תרביץ`, `הכול`, `אימא`, `בווצאפ`, `ייקח`. `זובי` is a none-case, since S-09 is dropped.
- `מַרְבִּיצִים לִי` (E1.1) and `חָרָא` (C19) are correctly pointed.

**Review file (`alert-word-lists-review.md`):**
- **Names:**
  - `פקיד סעד` is the old title; today's term is `עובד סוציאלי לפי חוק הנוער` (short form `עו״ס לחוק הנוער`).
  - The ministry is `משרד הרווחה והביטחון החברתי`.
  - `ער״ן` and `שפ״ח` take gershayim (R-4).
- **Section 4.1** (how children say it) is right Hebrew. `מישהו נגע לי` is a realistic child form; standard Hebrew is `נגע בי`, and both belong in W-11.

## 3. Findings on the parent texts (`alert-wording-drafts.md` §2)

| Entry | Issue | Corrected form | Status |
|---|---|---|---|
| 2.1 title | Clear and calm. With a recogniser that is often wrong, "heard" is more honest than "said". | `נשמע משהו שחשוב לשים אליו לב` | suggest |
| 2.1 first line | `{child} אמר[ה] משהו שנשמע כמו דאגה` is awkward ("sounded like worry"), gendered, and says the child certainly said it. | `במשחק של {child} נשמעו המילים: "{words}"` | fix |
| 2.1 words not kept | Uses a singular `שלך` (R-3) and the gender slash. | `המילים עצמן לא נשמרו, לפי ההגדרות שבחרתם.` | fix |
| 2.1 disclaimer | `וייתכן שהיא טעתה` and `ואינה מאבחנת דבר` are correct but stiff. | `וייתכן שהיא שמעה לא נכון. היא לא יודעת מה קרה, והיא לא מאבחנת דבר.` | suggest |
| 2.1 open question | `"למה התכוונת?"` can sound like doubt to a child who has just told. | `"רוצה לספר לי עוד?"`; keep `"מה רצית לספר לי?"` | counsellor |
| 2.1 what to say | `אני מאמין לך` assumes a father. | `"טוב שסיפרת לי. אני מאמין לך. זו לא אשמתך." (אפשר גם "מאמינה")` | fix |
| 2.1 secrecy | `כדי שתהיה בטוח` is masculine and sounds like a promise of an outcome. | `"אעשה מה שצריך כדי לשמור עליך."` | fix |
| 2.1 confrontation | `פוגע ב{child}` breaks R-1; `איתו` is unclear. | `אם החשש הוא מאדם מסוים, לא להתעמת איתו לפני שהתייעצתם.` | fix |
| 2.1 line 118 | The name of the ministry | `118 – מוקד המידע והסיוע של משרד הרווחה והביטחון החברתי`. The WhatsApp number per R-5. | fix |
| 2.1 line 1201 | `ער"ן` with an ASCII quote mark | `1201 – ער״ן, עזרה ראשונה נפשית, אנונימית, בטלפון ובצ׳אט, גם להורים.` No hours (not verified). | fix |
| 2.1 line 100 / 101 | Not in the verified set; 101 is unverified in the psychologist's own table. | **Removed** (owner, 2026-10-29: print only 118, 1201 and 105). | fix |
| 2.1 duty to report | `118 יכול להסביר אם וכיצד` puts a number as the subject, in written register. | `במוקד 118 אפשר לברר אם היא חלה במקרה שלכם.` The legal claim needs a lawyer. | fix / lawyer |
| 2.1 last line | `שלך` (R-3); `אינה` is formal. | `האפליקציה לא מדווחת לאף גורם. ההחלטה מה לעשות היא שלכם.` | fix |
| 2.2 PHYS | `לבדוק אם יש סימנים על הגוף` sounds like examining the child; the draft mixes infinitive and imperative. | `כדאי לשים לב אם יש סימנים על הגוף, ואם יש, לפנות לרופא הילדים. אם מדובר במבוגר שאחראי על {child}, להתייעץ לפני כל פנייה אליו.` | fix |
| 2.2 SEX | `להקשיב בלי להיבהל` asks for an inner state; the name of the service. | `להקשיב בלי להראות בהלה, ולא לחקור לבד.` and `מרכז הגנה לילדים ולנוער (בית לין)`. | fix |
| 2.2 SEX hospitals | `המרכזים האקוטיים` is the source's term. | Kept as the source says; a counsellor may prefer a plainer name. | counsellor |
| 2.2 SELF | Gendered `התכוון[ה]`, `אותו[ה]`; only a female `יועצת`; the imperatives mix with infinitives. | Clean text in §5. | fix |
| 2.2 SELF, 101 | Not verified | `בסכנה מיידית: חדר מיון.` (no number; owner, 2026-10-29) | fix |
| 2.2 NEGL | `איתו[ה]`; `לא צריך` sounds like a judgement of the parent. | `כדאי לדאוג מיד שמבוגר יהיה שם. ילדים בגיל הזה לא אמורים להישאר לבד בבית.` | fix |
| 2.2 NEGL-emergency | `וב-101` is ungrammatical; gendered `אמר[ה]`. | Clean text in §5. | fix |
| 2.2 ONLINE | `ניתן להתקשר מכל טלפון` is not in any source. | Removed; `לדווח למוקד 105 של המטה הלאומי להגנה על ילדים ברשת.` No hours (caveat). | fix |
| 2.2 SECRET | `ולא תהיה בצרות` is masculine. | `ומי שמספר לא נכנס לצרות.` | fix |
| 2.3 T2 | `{child} אמר[ה]`; `גיל צעיר`; the female `היועצת`; the slash `רופא/ת`. | Clean text in §5. | fix |
| 2.4 repeated | `בכמה הזדמנויות` is formal; `למעלה` depends on the layout. | `נשמעו כמה פעמים דברים דומים ... הצעדים ומספרי הסיוע מופיעים בהמשך.` | suggest |
| 2.5 swearing | `{n} פעמים` is wrong for n = 1; `איך נגיב` puts the app among the parents; the gendered verb. | Two forms, `{n} פעמים` and `פעם אחת`; `איך המבוגרים יגיבו`. Use `נשמעו` (hedged), as the draft suggests. | fix |
| 2.5 exposure | Gendered `שמע[ה] או ראה[ה]`. | `ייתכן שזה משהו שנשמע או נראה בבית, אצל חברים או במסך.` | fix |
| 2.6 settings | **`רשת ביטחון` contradicts the review's own rule** that the app must not present itself as protection (review §3.4). `לא תתפוס כל דבר` understates it. | `ההתראות הן עוד דרך לשים לב, ולא תחליף להשגחה ולשיחה עם הילדים. ... ולכן היא תחמיץ הרבה.` | fix |
| 2.7 card | `המקומות שהבגד מכסה` (any clothes cover almost everything); `שנגע בו` is unclear. | `המקומות שבגד הים מכסה` (the usual Israeli body-safety phrase); `ולא מבקש מאיתנו לגעת בגוף שלו`. | fix |
| 2.7 card, doctor rule | "Nobody touches them except a doctor" leaves out a parent washing a 3-year-old. | Ask the counsellor for the age-right wording. | counsellor |
| he.dart today | `alertSwearTitle`, `alertSwearDo`, `alertDisclosureTitle`, `alertDisclosureDo` | Correct Hebrew; the verdicts of the draft stand. | ok |

## 4. Findings on the tutor lines (`alert-wording-drafts.md` §3.2)

The owner agreed on 2026-10-29: one neutral form for all six lines.

**One neutral form instead of boy and girl forms.** The friend's own gender changes from friend to friend
(`אני עוזר` / `אני עוזרת`), and the child may have the neutral profile. The drafts use two gendered forms, so the
friend's gender would need a third axis. Every line below therefore has **no gendered word for the friend or the
child**:
- `שָׁמַעְתִּי` (the first person past is the same for every gender), with no `אותך`;
- the impersonal present the app already uses for instructions (`מְסַפְּרִים`, `סוֹמְכִים`);
- `טוֹב לְסַפֵּר` instead of `טוב שסיפרת` (`סִפַּרְתָּ` and `סִפַּרְתְּ` are said differently);
- `בּוֹאוּ` (the plural address of the app).

So one clip serves every friend and every profile, which also costs less to voice.

| Entry | Issue | Corrected form (screen, full nikud) | Voice text | Status |
|---|---|---|---|---|
| TL-1 (5 to 8) | Gendered `אותך`, `ספר/ספרי`, `שאתה/שאת סומך/ת`; `והוא יעזור` promises an outcome. | `שָׁמַעְתִּי. זֶה חָשׁוּב, וְטוֹב לְסַפֵּר. עַכְשָׁו מְסַפְּרִים גַּם לִמְבֻגָּר שֶׁסּוֹמְכִים עָלָיו — הוּא יָכוֹל לַעֲזֹר.` | `שמעתי. זה חשוב, וטוב לְסַפֵּר. עכשיו מְסַפְּרִים גם למבוגר שסומכים עליו — הוא יכול לעזור.` | fix |
| TL-2 (3 to 4) | Gendered; `מבוגר` is less of a gan word than `מישהו גדול`. | `שָׁמַעְתִּי. טוֹב לְסַפֵּר. מְסַפְּרִים לְמִישֶׁהוּ גָּדוֹל שֶׁאוֹהֲבִים, וְהוּא יָכוֹל לַעֲזֹר.` | `שמעתי. טוב לְסַפֵּר. מְסַפְּרִים למישהו גדול שאוהבים, והוא יכול לעזור.` | fix |
| TL-3 (death, self-harm) | The friend's gender (`אני רק עוזר/ת`); `כבד` is adult slang; gendered `לך/לכי`, `ספר/ספרי`, `אמרת`. | `זֶה נִשְׁמָע קָשֶׁה. פֹּה רַק מְשַׂחֲקִים וְלוֹמְדִים, אֲבָל מְבֻגָּר קָרוֹב יָכוֹל לַעֲזֹר בֶּאֱמֶת. הוֹלְכִים אֵלָיו עַכְשָׁו וּמְסַפְּרִים לוֹ.` | `זה נשמע קשה. פה רק משחקים ולומדים, אבל מבוגר קרוב יכול לעזור באמת. הולכים אליו עכשיו ומְסַפְּרִים לו.` | fix / counsellor |
| TL-4 (mild) | Gendered `שאתה/שאת סומך/ת`. | `זֶה לֹא נָעִים. אֶפְשָׁר לְסַפֵּר עַל זֶה לִמְבֻגָּר שֶׁסּוֹמְכִים עָלָיו.` | `זה לא נעים. אפשר לְסַפֵּר על זה למבוגר שסומכים עליו.` | fix |
| TL-5 (asks the tutor to keep a secret) | The friend's gender (`אני לא יכול/ה`). | `סוֹד שֶׁמַּפְחִיד אוֹ כּוֹאֵב לֹא שׁוֹמְרִים. מְסַפְּרִים לִמְבֻגָּר שֶׁסּוֹמְכִים עָלָיו, וְהוּא יָכוֹל לַעֲזֹר.` | `סוד שמפחיד או כואב לא שומרים. מְסַפְּרִים למבוגר שסומכים עליו, והוא יכול לעזור.` | fix |
| TL-6 (swearing) | **A misheard word would be "corrected"**: the child is told off for a word they may not have said (the recogniser is weakest on young children). `בוא/בואי` is gendered. | `בּוֹאוּ נַחְזֹר לַמִּשְׂחָק.` Nothing is said about the word (owner, 2026-10-29). | `בואו נחזור למשחק.` | fix |
| PLAN line (341) | `שֶׁאַתָּה סוֹמֵךְ עָלָיו` is masculine only. | Replace with TL-1. | fix |

**Checks on all six lines:**
- One caring sentence, then a pointer to a trusted adult.
- No question.
- No promise of secrecy, and no promise that the adult will fix it (`יָכוֹל לַעֲזֹר`).
- No number and no abbreviation.
- No `!`, which a voice would shout.
- Every line is at most 24 words.

The voice texts keep the nikud only on `לְסַפֵּר` and `מְסַפְּרִים`. Unpointed, these read as "to the book" and "numbers", a real risk in an app full of numbers (pronunciation audit, rule 4). For the voice director: slow, warm, lower in pitch, a pause after `שָׁמַעְתִּי` (wording drafts §3.3.6).

## 5. Clean versions (`final-draft`; `review: needs-editor` in the app until the owner approves the strings)

### 5.1 Parent messages (screen only, no nikud)

**T1. Title:** `נשמע משהו שחשוב לשים אליו לב`

> במשחק של {child} נשמעו המילים: "{words}"
> *(words not kept:)* המילים עצמן לא נשמרו, לפי ההגדרות שבחרתם.
>
> האפליקציה לא תמיד מבינה ילדים נכון. ייתכן שזה היה משחק או סיפור, וייתכן שהיא שמעה לא נכון. היא לא יודעת מה קרה, והיא לא מאבחנת דבר.
>
> **מה כדאי לעשות עכשיו**
> • למצוא זמן רגוע ומקום פרטי, ולשוחח עם {child} בלי ללחוץ.
> • להקשיב. אפשר לשאול שאלה פתוחה אחת, כמו "רוצה לספר לי עוד?" או "מה רצית לספר לי?". לא לחקור ולא להציע תשובות.
> • לומר: "טוב שסיפרת לי. אני מאמין לך. זו לא אשמתך." (אפשר גם "מאמינה").
> • לא להבטיח לשמור סוד. אפשר לומר: "אעשה מה שצריך כדי לשמור עליך."
> • אם החשש הוא מאדם מסוים, לא להתעמת איתו לפני שהתייעצתם.
>
> **אפשר להתייעץ עוד היום, גם בלי להגיש תלונה**
> • 118 – מוקד המידע והסיוע של משרד הרווחה והביטחון החברתי: חינם, 24 שעות ביממה, בעברית, בערבית, באמהרית וברוסית. אפשר גם לכתוב בוואטסאפ: ⁦050-2270118⁩.
> • 1201 – ער״ן, עזרה ראשונה נפשית, אנונימית, בטלפון ובצ׳אט, גם להורים.
>
> במקרים רבים של פגיעה בילדים חלה בישראל חובת דיווח למשטרה או לעובד סוציאלי לפי חוק הנוער. במוקד 118 אפשר לברר אם היא חלה במקרה שלכם. *[a lawyer confirms this sentence]*
>
> האפליקציה לא מדווחת לאף גורם. ההחלטה מה לעשות היא שלכם.

**Add-ons (under the T1 text):**
- **PHYS:** `אם נשמע שמישהו מרביץ: כדאי לשים לב אם יש סימנים על הגוף, ואם יש, לפנות לרופא הילדים. אם מדובר במבוגר שאחראי על {child}, להתייעץ לפני כל פנייה אליו.`
- **SEX:** `אם נשמע משהו על נגיעה או על צילום: להקשיב בלי להראות בהלה, ולא לחקור לבד. כדאי להתייעץ מיד עם מוקד 118 או עם מרכז הגנה לילדים ולנוער (בית לין); אפשר להתייעץ גם בלי למסור שם. אם יש חשש לפגיעה בימים האחרונים, המרכזים האקוטיים בבתי החולים פתוחים 24 שעות ביממה.`
- **SELF:** `ילדים צעירים לא תמיד מבינים מה זה מוות, ולפעמים אומרים דברים כאלה מתוך כעס. ובכל זאת, חשוב להתייחס לזה ברצינות: להישאר קרובים, גם ברגעים קשים, ולשאול בשקט מה עובר על {child}. בימים הקרובים כדאי להתייעץ עם יועצת הגן או בית הספר, עם פסיכולוג או עם רופא הילדים. אפשר לפנות גם לער״ן, 1201. בסכנה מיידית: חדר מיון.`
- **NEGL:** `אם {child} לבד עכשיו, כדאי לדאוג מיד שמבוגר יהיה שם. ילדים בגיל הזה לא אמורים להישאר לבד בבית.`
- **NEGL-emergency:** `אם נשמע שמישהו נפל ולא זז: להתקשר מיד הביתה או לאדם שנמצא עם {child}, ואם צריך, לקרוא לעזרה רפואית. ייתכן שזה משחק, אבל כדאי לבדוק עכשיו.`
- **ONLINE:** `אם מישהו פנה אל {child} בטלפון, במשחק או ברשת: לשמור צילומי מסך ולא למחוק, לא להגיב לפונה, ולדווח למוקד 105 של המטה הלאומי להגנה על ילדים ברשת.` *[hours not printed: not verified]*
- **SECRET:** `ילדים שביקשו מהם לשמור סוד על משהו שמפחיד או כואב צריכים לשמוע שמותר לספר: "הפתעה אפשר לשמור בסוד. סוד שמפחיד או כואב תמיד מספרים, ומי שמספר לא נכנס לצרות."`

**T2. Title:** `נשמע משהו שאולי כדאי לבדוק`

> במשחק של {child} נשמעו המילים: "{words}"
>
> זה יכול להיות משחק, סיפור או משהו שנאמר בלי כוונה. ייתכן גם שהאפליקציה שמעה לא נכון. אין צורך להיבהל.
>
> בזמן רגוע, ובלי ללחוץ, אפשר לשאול: "איך היה היום? יש משהו שבא לך לספר לי?"
>
> אם זה חוזר, או אם משהו בהתנהגות של {child} השתנה (שינה, אכילה, פחד מאדם מסוים, חזרה להתנהגות של גיל צעיר יותר), כדאי להתייעץ עם היועצת בגן או בבית הספר, עם רופא הילדים או עם מוקד 118.

**Repeated (C-1). Title:** `נשמעו כמה דברים שכדאי לשים אליהם לב`

> בשבוע האחרון נשמעו כמה פעמים דברים דומים: "{words}". כל אחד מהם לבד אולי לא מדאיג, אבל יחד כדאי לשוחח עם {child}. הצעדים ומספרי הסיוע מופיעים בהמשך.

**T3 swearing. Title:** `מילים לא הולמות השבוע`

> השבוע נשמעו במשחק של {child} מילים לא הולמות, {n} פעמים. *(n = 1: `נשמעה במשחק של {child} מילה לא הולמת, פעם אחת.`)*
> ילדים בגיל הזה חוזרים על מילים ששמעו בבית, ברחוב או במסך, ולפעמים בודקים איך המבוגרים יגיבו. אין צורך להתרגש: אפשר להגיב בשקט, להסביר בקצרה שאת המילה הזאת לא אומרים, ולהציע מילה אחרת. ייתכן גם שהאפליקציה שמעה לא נכון.
> ההתראה לא מוצגת בצד של הילדים.

**T3 exposure. Title:** `נשמעה מילה מעולם המבוגרים`

> במשחק של {child} נשמעה מילה שקשורה לתכנים למבוגרים. ייתכן שזה משהו שנשמע או נראה בבית, אצל חברים או במסך, וייתכן שהאפליקציה שמעה לא נכון. כדאי לשוחח בנחת, בלי לנזוף, ולבדוק אילו תכנים זמינים במכשירים בבית. אם זה קרה ברשת, אפשר לפנות למוקד 105.

**Settings text:**

> ההתראות הן עוד דרך לשים לב, ולא תחליף להשגחה ולשיחה עם הילדים. האפליקציה מקשיבה רק כשהילדים לוחצים על המיקרופון, והיא לא תמיד מבינה ילדים צעירים, ולכן היא תחמיץ הרבה. היא לא מאבחנת ולא מדווחת לאף גורם.

**Parent card. Title:** `שיחה על סודות ועל המקומות הפרטיים` *(counsellor reviews the content)*

> • הפתעה, כמו מתנה ליום הולדת, אפשר לשמור בסוד. סוד שמפחיד או כואב תמיד מספרים.
> • המקומות שבגד הים מכסה הם פרטיים. אף אחד לא נוגע בהם ולא מבקש מאיתנו לגעת בגוף שלו, חוץ מרופא, כשאמא או אבא איתנו. *[counsellor: wording for a parent who washes a young child]*
> • תמיד אפשר לספר לאמא, לאבא או למבוגר אחר שסומכים עליו, ומי שמספר לא נכנס לצרות.
> • כדאי לשאול מדי פעם שאלה פתוחה: "מה היה הכי כיף היום? ומה היה לא נעים?"

### 5.2 Tutor lines (child space; full nikud on screen, voice text for the voice director)

| ID | Screen (full nikud) | Voice text |
|---|---|---|
| TL-1 | שָׁמַעְתִּי. זֶה חָשׁוּב, וְטוֹב לְסַפֵּר. עַכְשָׁו מְסַפְּרִים גַּם לִמְבֻגָּר שֶׁסּוֹמְכִים עָלָיו — הוּא יָכוֹל לַעֲזֹר. | שמעתי. זה חשוב, וטוב לְסַפֵּר. עכשיו מְסַפְּרִים גם למבוגר שסומכים עליו — הוא יכול לעזור. |
| TL-2 | שָׁמַעְתִּי. טוֹב לְסַפֵּר. מְסַפְּרִים לְמִישֶׁהוּ גָּדוֹל שֶׁאוֹהֲבִים, וְהוּא יָכוֹל לַעֲזֹר. | שמעתי. טוב לְסַפֵּר. מְסַפְּרִים למישהו גדול שאוהבים, והוא יכול לעזור. |
| TL-3 | זֶה נִשְׁמָע קָשֶׁה. פֹּה רַק מְשַׂחֲקִים וְלוֹמְדִים, אֲבָל מְבֻגָּר קָרוֹב יָכוֹל לַעֲזֹר בֶּאֱמֶת. הוֹלְכִים אֵלָיו עַכְשָׁו וּמְסַפְּרִים לוֹ. | זה נשמע קשה. פה רק משחקים ולומדים, אבל מבוגר קרוב יכול לעזור באמת. הולכים אליו עכשיו ומְסַפְּרִים לו. |
| TL-4 | זֶה לֹא נָעִים. אֶפְשָׁר לְסַפֵּר עַל זֶה לִמְבֻגָּר שֶׁסּוֹמְכִים עָלָיו. | זה לא נעים. אפשר לְסַפֵּר על זה למבוגר שסומכים עליו. |
| TL-5 | סוֹד שֶׁמַּפְחִיד אוֹ כּוֹאֵב לֹא שׁוֹמְרִים. מְסַפְּרִים לִמְבֻגָּר שֶׁסּוֹמְכִים עָלָיו, וְהוּא יָכוֹל לַעֲזֹר. | סוד שמפחיד או כואב לא שומרים. מְסַפְּרִים למבוגר שסומכים עליו, והוא יכול לעזור. |
| TL-6 | בּוֹאוּ נַחְזֹר לַמִּשְׂחָק. | בואו נחזור למשחק. |

## 6. The psychologist's six points (`alert-wording-drafts.md` §4)

1. **Grammar, gender, number and quotation marks:** done.
   - Every `[ה]`, `אתה/את`, `סומך/סומכת` and `אוהב/אוהבת` is removed by neutral wording (§3, §4).
   - The one exception left, `אני מאמין לך`, is a phrase the parent says; its feminine form is given beside it.
   - Quotation marks are `"..."`; `«»` is not used in the app (R-4).
2. **The companion's gender in TL-3 and TL-5:** solved by wording with no first-person present (§4), so no form depends on the friend.
3. **Voice-readiness:**
   - TL-1 to TL-6 have nikud, no number, no abbreviation and no `!`.
   - The numbers 118, 1201, 105 and the WhatsApp number of 118 appear only in the parent texts, which are screen only (R-5).
4. **Names:**
   - `ער״ן` with gershayim (U+05F4), glossed once as `ער״ן, עזרה ראשונה נפשית`.
   - `בית לין` in two words, glossed as `מרכז הגנה לילדים ולנוער (בית לין)`.
   - `משרד הרווחה והביטחון החברתי` (today's full name).
   - `המטה הלאומי להגנה על ילדים ברשת`, with `מוקד 105` before it.
5. **Open questions for the parent:** `"מה רצית לספר לי?"` is fine. `"למה התכוונת?"` can sound like doubt; I propose `"רוצה לספר לי עוד?"` instead. The counsellor decides.
6. **Nothing diagnoses, blames or promises:**
   - Fixed: `רשת ביטחון` (an implied promise of protection), `והוא יעזור` → `יָכוֹל לַעֲזֹר`, and `כדי שתהיה בטוח` → `כדי לשמור עליך`.
   - TL-6, as drafted, could blame a child for a word the recogniser misheard; it now says nothing about the word.
   - What remains states only what was heard and what may help.

## 7. The owner's answers (2026-10-29) and what is still open

Answered:
1. **Numbers:** print only the three verified numbers, 118, 1201 and 105 (105 without hours). **100 and 101 are not
   printed.** The SELF and emergency add-ons therefore say `חדר מיון` and `לקרוא לעזרה רפואית` without a number.
2. **The WhatsApp number of 118** (`050-2270118`) is kept.
3. **TL-6:** nothing is said about the word: `בּוֹאוּ נַחְזֹר לַמִּשְׂחָק.`
4. **The tutor lines:** one neutral form for all six (section 4).

Still open:
1. **`זובי` and `כוסית`.** Both are left out of the lists for now. `זובי` also means "nothing" in adult talk, so it would
   fire on harmless sentences. `כוסית` was never in the draft, and adding a swear class is the owner's call. S-09 (`זיבי`,
   a misspelling) is dropped.
2. **The family words for the body.** Do your children use words for their private parts that are not in set B (for a
   girl especially: `פושי`, `פיפינה` and others vary from home to home)? Only you can say. Nothing was guessed, and set B
   holds only the words in section 2.
3. **For the counsellor, through the owner:** the open question to a child (section 6, point 5), the "doctor" sentence
   of the parent card, the wording of TL-3, and the hospital service name.
4. **For a lawyer:** the duty-to-report sentence.

## 8. For the app-developer (implement after the owner approves the strings)

1. **Tutor lines.** Add TL-1 to TL-6 exactly as in section 5.2: one form each, with no gender variants and no
   companion-gender branch. Each line is pre-recorded and chosen on the device by tier and subcategory (wording drafts
   §3.3). The voice is made from the voice-text column (voicing is the owner's paid step). Replace the PLAN.md line 341
   text with TL-1.
2. **Parent texts.** Add the strings of section 5.1 to `app/lib/strings/he.dart` as adult strings (no nikud):
   - T1 with its seven add-ons, T2, repeated, the two T3 texts, the settings text and the parent card;
   - `{child}` never has a prefix letter attached (R-1);
   - give the swearing digest two forms, `{n}` and one (`פעם אחת`);
   - mark the new strings `review: needs-editor` and run `tools/export-hebrew-review.py`.
3. **Numbers.** Only 118, 1201 and 105, and the WhatsApp number of 118:
   - screen only, never in a voiced line;
   - isolated left to right with U+2066 … U+2069;
   - tappable (`tel:` and the WhatsApp link through the allowed hosts, a security-engineer check);
   - no hours shown for 105 or 1201;
   - no 100 and no 101.
4. **Typography.** Write `ער״ן` with U+05F4 and `צ׳אט` with U+05F3. Quotes are ASCII `"…"`, never `«»`.
5. **Word lists.** Apply section 2 to the data file:
   - **fix:** `אנשק` for `אישק`; `ביץ` and `ביטש` for `בייץ`; `לכולם יהיה יותר טוב בלעדיי`; the `חרבן` note and
     `חירבן` / `מחרבן`;
   - **drop:** S-09 entirely;
   - **add:** the R-6 spellings (`אימא`, `הכול`, `ייקח`, `היכה`), the R-7 gender forms (`תרביץ`, `תהרוג`, `חוטפת`,
     `מקבלת`, …), the ADULT prefixes (R-8), the `וואצאפ` variants, `צ אט` and `צאט`, the body-safety words `מוצנע` and
     `בגד הים`, and the fused `כוס אמאשך`;
   - **do not add:** `זובי` or `כוסית`.
6. **Tests.** Add test cases for the new forms (`אנשק`, `תרביץ`, `הכול`, `אימא`, `בווצאפ`, `ייקח`, `כוס אמאשך`). Add
   none-cases for `זובי` and `קיבלתי זובי`, since the entry was dropped.
7. **Reviews.** The qa-engineer verifies; the security-engineer reviews the list-file path and the links.
