# The Languages island: the final Hebrew texts (F8)

Author: hebrew-text-editor, 2026-11-03. For the app-developer (the strings of `docs/design/languages-island.md` §7, the parent pages of its §6, and the bottle's lines for a language stop), the voice-and-sound-director (the spoken lines) and the owner (the questions at the end). Source of the drafts: the design-director's spec `docs/design/languages-island.md` on the branch `languages-foundation` (worktree `D:\nitznutz-langbuild`); its previews `docs/design/languages/parent_*.png` were read for the parent texts (the texts exist only in those pictures and in §6 of the spec). Nothing was voiced or paid, and no code was changed.

**Status of every text below: `text-ready`** (grammar, vocabulary, nikud and voice text are final; the owner has not approved them). The rule of CLAUDE.md stays: in the app's sources each new string keeps `"review": "needs-editor"` until the owner approves it. **The bottle's lines in §4 are proposals** and are marked so: they wait for the owner's pick.

Rules applied (`docs/agents/hebrew-notes.md` §2, §3 and §9.1): child text (shown to a child or read by a voice) has full nikud; adult text (parent area, screen-reader labels) has none; every spoken line is plural or "let us", with no gender in the voice's lines and no pronoun for the friend; the voice text has partial nikud, no "!" and no variables; a question has at most 14 words and any other line at most 24; no time word, no count of days, no "come back", no comparison between languages or between children.

## 1. Child text on the island and the doors

| Key (suggested) | Where | Was (the design-director's draft) | Final (shown) | Voice text | Voiced? | Notes |
|---|---|---|---|---|---|---|
| `landLanguages` | map sign, door-screen chip (`nikud: true`) | אִי הַשָּׂפוֹת | **אִי הַשָּׂפוֹת** | `אִי הַשָּׂפוֹת` (only if a line ever says it, see §4) | no (a sign) | Kept. Checked: `אִי` is the construct of `אִי` (island); `שָׂפוֹת` is the plural of `שָׂפָה` with the sin dot, holam-vav and the dagesh of the article (`הַשָּׂפוֹת`); the same pattern as `גִּבְעוֹת הַסְּפִירָה`, `מִפְרַץ הַצְּבָעִים`. `שָׂפָה` ("language") is a gan word; the other sense (a lip) has the dual `שְׂפָתַיִם`, so there is no clash. A voice would read the plain `אי` as "ai" or "ee", so the voice text keeps the nikud (new in `COURSE_KEEP` of the review tool) |
| `landLanguagesSemantics` | screen reader | אי השפות | **אי השפות** | | no | Plain, as the other `land*Semantics` |
| `helloHeb` | the Hebrew door's bubble (`nikud: true`, Heebo 700, RTL) | שָׁלוֹם | **שָׁלוֹם** | `שָׁלוֹם` (a single word: stays fully pointed, as every single-word clip of the course, `hebrew-notes.md` §9.4, until the pilot decides) | yes, by the Hebrew course voice | Kept. Checked: shin dot, qamats, holam-vav, final mem; stress on the last syllable. `helloEng` and `helloRus` are the teachers' (Hello, Привет) |
| `languagesDoorsHello` | the companion's line on arrival at the door screen (voiced once; no text on screen) | (to be written) | **בּוֹאוּ נִפְתַּח דֶּלֶת. מִי אוֹמֵר לָנוּ שָׁלוֹם?** | `בואו נפתח דלת. מי אומר לנו שלום?` | yes, B-45 batch, the friend's voice | 8 words, two short sentences. "We" and "let us": no gender, no name, no number (there may be three doors or two, so "a door", never "one of the three"), nothing the child did. It is true to what happens: a tap opens a door and the host says hello. The question is a wondering, not a test; it asks for no answer and nothing personal. `דֶּלֶת` is stressed on the first syllable (`hebrew-notes.md` §8.4). **If you prefer no question:** `בּוֹאוּ נִפְתַּח דֶּלֶת.` (voice `בואו נפתח דלת.`) |

## 2. The names of the languages

| Key | Where | Was | Final (adult / screen reader: no nikud) | Pointed form (for a child line or a voice, if ever needed) |
|---|---|---|---|---|
| `langEnglish` | door label (screen reader), parent rows, page titles | אנגלית | **אנגלית** | אַנְגְּלִית |
| `langHebrew` | same | עברית | **עברית** | עִבְרִית |
| `langRussian` | same | רוסית | **רוסית** | רוּסִית |

All three are feminine (they agree with the noun `שָׂפָה`: `פעילה`, `כבויה`). The order of the doors and of the rows is the design's (English, Hebrew, Russian, alphabetical in Hebrew). The names are never joined to a prefix letter at run time: where a sentence needs "in English", "in Hebrew", "in Russian" it has three fixed strings (§3: `התקדמות באנגלית` …), so no `ב` is ever added to a name by code.

Optional (not in the spec): the door's screen-reader label `הדלת של {lang}` ("the door of English") says more than the bare name. The bare name is acceptable; the label is a suggestion.

## 3. Parent texts (adult, no nikud)

The texts are in the order of the pages. "Was" is what the design-director drew, read from the previews (a text that exists only in the spec's prose is marked "none"); a row whose "Final" is the same as "Was" was checked and kept. `{lang}` is one of the three names of §2, `{child}` the child's name; **no text here uses a verb about the child that needs a gender**, so `{child}` is only in titles.

### 3.1 The rules page: the "Languages" card

| Key | Was | Final | Why |
|---|---|---|---|
| `areaLanguages` (card title) | שפות | **שפות** | |
| `areaLanguagesHelp` | כל שפה שפועלת מקבלת דלת משלה באי השפות. כיבוי מסתיר את הדלת ושומר את כל ההתקדמות. | **כל שפה פעילה מקבלת דלת משלה באי השפות. כשמכבים שפה, הדלת נעלמת וכל מה שנלמד נשמר.** | `פועלת` means "works"; the language is "active" (`פעילה`) or "off" (`כבויה`), a pair a parent reads at once. "Hides the door and keeps all the progress" is a noun sentence; the new one says what a parent will see |
| `areaLangStateOn` | פועלת · יש לה דלת באי השפות | **פעילה · יש לה דלת באי השפות** | as above |
| `areaLangStateOff` | כבויה · אין לה דלת. כל מה שנלמד נשמר | **כבויה · אין לה דלת, וכל מה שנלמד נשמר** | one clause, so the line reads as one thought and ends like the other state line |
| `areaLangRowSemantics` (new, the chevron and the row) | (none) | **הגדרות השפה: {lang}** | a screen-reader label for the row that opens the language's page |
| `areaLangSwitchSemantics` (new) | (none) | **הפעלת {lang}** | the switch's label |

### 3.2 A language's page

The title of the page is `{lang} · {child}` (as drawn; no change).

| Key | Was | Final | Why |
|---|---|---|---|
| card title | רוסית (the language's name) | **`{lang}`** | |
| `areaLangSwitch` | השפה פועלת | **השפה פעילה** | as in 3.1 |
| `areaLangSwitchOnHelp` | הדלת של רוסית מופיעה באי השפות | **הדלת של {lang} מופיעה באי השפות.** | a full stop |
| `areaLangSwitchOffHelp` (new: the drawn page shows only the "on" state) | (none) | **אין דלת באי השפות. כל מה שנלמד נשמר.** | the same facts as 3.1 |
| `areaLangLessons` (card title) | הגדרות השיעורים | **הגדרות השיעורים** | |
| voice answers, title | תשובות בקול | **תשובות בקול** | the app's own `areaVoice` |
| `areaLangVoiceHelp` | המיקרופון נפתח רק בלחיצה של הילד. שום קול לא נשמר ולא נשלח. ההפעלה מורידה את מודל הזיהוי של רוסית | **המיקרופון נפתח רק כשהילד לוחץ עליו. שום קול לא נשמר ולא נשלח. כשמפעילים, מודל הזיהוי של {lang} יורד למכשיר.** | the first sentence has the words of the app's `areaVoiceHelp`; "ההפעלה מורידה" had no object a parent could picture and no full stop. **For Hebrew** leave out the third sentence unless the Hebrew recogniser also has to be downloaded (it is in the app today; the app-developer knows) |
| personal questions, title | שאלות אישיות בשיעור | **שאלות אישיות בשיעור** | |
| `areaLangPersonalHelp` | שם, גיל, מה אוהבים, משפחה. התשובה לא נשמרת | **בשיעור יש שאלות קצרות על שם, גיל, משפחה ומה אוהבים. אפשר לדלג על כל שאלה, והתשובה לא נשמרת.** | the draft was a list with no sentence; the new text says that the child may skip (frame §5.2: there is always a "pass") and that nothing is kept |
| English: `areaLangOralOnly`, title (the preview shows the Russian page only) | (none; the spec says "oral only") | **הקשבה ודיבור בלבד** | |
| `areaLangOralOnlyHelp` | (none) | **כשמפעילים, הילד לומד אנגלית רק בשמיעה ובדיבור, בלי אותיות וקריאה. כשהאפשרות כבויה, האותיות נפתחות כשהילד מוכן.** | the two states, in words (frame §1.4: default off, D6) |
| Russian: `areaLangLetters`, title | אותיות לפני גיל 5 | **אותיות לפני גיל 5** | |
| `areaLangLettersOff` | כבוי: עד גיל 5 רק שומעים ומדברים | **כבוי: עד גיל 5 רק שומעים ומדברים** | kept |
| `areaLangLettersOn` (new) | (none) | **מופעל: אפשר להתחיל באותיות גם לפני גיל 5** | the other state, in the app's word `מופעל` (`areaVoiceHelp`, `prizesHelp`) |
| Russian: `areaLangStress`, title | סימני הטעמה על המסך | **סימני הטעמה על המסך** | kept |
| `areaLangStressHelp` | לפי המסלול: לומדים חדשים · מופעל | **סימן קטן שמראה על איזו אות ההטעמה במילה. בשיעורים על הטעמה הוא מופיע תמיד. ברירת המחדל במסלול של {route}: {default}.** | the draft did not say what the mark is or what "המסלול" refers to. Route names and defaults: `routeNew` = **לומדים חדשים** (default: **מופיע גם על מילים חדשות בקריאה**); `routeHeritage` = **רוסית בבית** and `routeReader` = **קוראים** (default for both: **לא מופיע מחוץ לשיעורי ההטעמה**). The route names are for the Russian teacher and the owner to confirm (question 3) |
| Hebrew: `areaLangReadCheck`, title | (none; the spec says "parent check of reading aloud") | **בדיקת הקראה להורים** | |
| `areaLangReadCheckHelp` | (none) | **קריאה בקול היא תרגול, בלי ציון. הבדיקה מיועדת להורים, ואינה משפיעה על ההתקדמות.** | D22: reading aloud is unscored. How the check works is not written in the sources, so the text says only what is certain (question 4) |
| Russian: `areaLangQuestTitle` | שאלון שפת הבית | **שאלון שפת הבית** | |
| `areaLangQuestHelp` | שלוש שאלות קצרות עוזרות לבחור מאיפה להתחיל. אפשר לשנות בכל זמן. | **התשובות קובעות רק מאיפה מתחילים. אפשר לשנות אותן בכל זמן.** (no number: the Russian questionnaire has five questions, English one; changed at L0, he.dart 94e805b) | "to change" what? |
| `areaLangQuestButton` | לשאלון | **לשאלון** | |
| progress buttons | התקדמות ברוסית | **התקדמות באנגלית** · **התקדמות בעברית** · **התקדמות ברוסית** | three fixed strings (no prefix letter added by code). The same three are the page titles with ` · {child}` |

### 3.3 Progress in a language

| Key | Was | Final | Why |
|---|---|---|---|
| card title | אנגלית | **`{lang}`** | |
| `areaLangProgressIntro` | מה נֹעָה לומדת עכשיו, מה כבר הבינה ומה כדאי לחזור אליו. בלי השוואה לשפה אחרת או לילד אחר. | **כאן רואים מה נמצא בתרגול, מה כבר מובן ומה כדאי לחזור אליו. אין השוואה לשפה אחרת או לילד אחר.** | **the draft carried the child's name with a feminine verb** (`לומדת`, `הבינה`) and would be wrong for a boy; the parent area never guesses a gender. `כדאי לחזור אליו` ("worth coming back to") is kept |
| legend, 1 | לומדים עכשיו | **בתרגול** | the app's own `statusPractising` (the parent sees one set of words on all progress pages) |
| legend, 2 | הבינו | **מובן** | the app's `statusUnderstood`; `הבינו` ("they understood") had no clear subject |
| legend, 3 | הבינו וזוכרים | **מובן וזכור** | the same pair of words as the child's map (`יוֹדְעִים וְגַם זוֹכְרִים`); new string `statusRemembered` |
| legend, 4 | כדאי לחזור | **כדאי לחזור** | the app's `statusRevisit` |
| strand names, English | הקשבה ודיבור · צלילים ואותיות · קריאה · כתיבה | **הקשבה ודיבור · צלילים ואותיות · קריאה · כתיבה** | kept. The Russian and Hebrew strand names come from their teachers |
| `areaLangStrandStart` | מתחילים כאן: רמה 2 | **מתחילים כאן: רמה {n}** | kept |
| the count line | לומדים עכשיו 3 · הבינו 4 · הבינו וזוכרים 2 · כדאי לחזור 1 | **בתרגול {a} · מובן {b} · מובן וזכור {c} · כדאי לחזור {d}** (a count of 0 is left out) | the legend's words, so one set of words; "עוד לא התחילו" (the app's `progressNotYetPlayed`) when all four are 0 |
| gates, title | שערים | **שערים** | |
| gate, English | שער הדיבור | **שער הקריאה** | the gate decides when letters and reading open; "the speaking gate" made a parent think it was about speaking |
| gate, Russian (new) | (none) | **שער האותיות** | |
| gate chip, open | פתוח | **פתוח** | |
| `areaLangGateOpen` | נפתח: אפשר להתחיל לקרוא | **הילד מכיר מספיק מילים בשמיעה, ואפשר להתחיל באותיות.** | says why, and what it allows |
| gate chip, not yet | עוד לא (the spec) | **עוד לא** | |
| `areaLangGateClosed` (new) | (none) | **קודם מקשיבים ומדברים. כשהילד יכיר מספיק מילים בשמיעה, השער ייפתח.** | calm; no date, no count, no "behind" |
| gate chip, closed by the parent (English "oral only" on) | (none) | **סגור** | |
| `areaLangGateByParent` (new) | (none) | **בחרתם הקשבה ודיבור בלבד.** | |
| speaking, title | דיבור | **דיבור** | |
| `areaLangSpeakingHelp` | דיבור מוצג כ"תרגלו" או "אמרו". זה לא ציון. | **דיבור מוצג רק כ"תורגל" או "נאמר". זה לא ציון.** | the chips `תרגלו` and `אמרו` read as orders ("practise!", "say!") when unpointed; `תורגל` and `נאמר` say what happened, with no subject |
| speaking chips | תרגלו · אמרו | **תורגל** · **נאמר** | |
| notice card, title | מה כדאי לשים לב אליו | **מה כדאי לשים לב אליו** | the app's `progressMisconceptions` |
| notice row, state | נמצא בשבוע שעבר · תוקן | **נמצא {when} · נפתר** | the app's `progressResolved` is `נפתר` |
| co-play card, title | לשחק יחד | **לשחק יחד** | |
| co-play button | כרטיסי משחק להורה ולילד | **כרטיסי משחק להורה ולילד** | kept |

## 4. The bottle's lines for a language stop (proposals)

**What exists.** `docs/curriculum/todays-adventure-rule.md` §8 gives five reasons (`welcome`, `callForHelp`, `sameLand`, `otherLand`, `playAgain`), and their lines are in `app/lib/strings/he.dart` as `adventureWelcome` … `adventurePlayAgain` with their `…Semantics` (`hebrew-notes.md` §7), voiced once for each of the six lands (`PER-LAND` in the review tool). **There is no `core.adventure.*` in `content/lines/core.he.json`** (on `main` or anywhere): the lines are `he.dart` strings, so these proposals use the same key pattern, `adventureLang…`.

**The problem.** The five lines name a land through `{land}`. With `{land}` = `אִי הַשָּׂפוֹת` they would work as they are (`בּוֹאוּ נַמְשִׁיךְ בַּהַרְפַּתְקָה שֶׁל אִי הַשָּׂפוֹת.`), but the stop is one language, and a child who has three doors should hear which one the bottle opens. And `מַשֶּׁהוּ שֶׁל אִי הַשָּׂפוֹת צָרִיךְ עֶזְרָה` does not fit: no language "needs help". So: **one line per language**, the same line for every reason (a new lesson, a revisit, a replay), because the line says only what the child will do, never "again", "new" or "help".

| Key (proposal) | Shown (`nikud: true`) | Voice text | Screen-reader label | Words |
|---|---|---|---|---|
| `adventureLangEnglish` | **בּוֹאוּ נְשַׂחֵק בְּאַנְגְּלִית.** | `בואו נְשַׂחֵק באנגלית.` | הבקבוק: לשחק באנגלית | 3 |
| `adventureLangRussian` | **בּוֹאוּ נְשַׂחֵק בְּרוּסִית.** | `בואו נְשַׂחֵק ברוסית.` | הבקבוק: לשחק ברוסית | 3 |
| `adventureLangHebrew` | **בּוֹאוּ נְשַׂחֵק בְּמִלִּים.** | `בואו נְשַׂחֵק במילים.` | הבקבוק: לשחק במילים בעברית | 3 |

- **Style of §7 of the notes:** "we" and "let us"; no child name, no friend name, no first or second person singular, no time word, no count; no `היום`, `עוד לא`, `כבר`, `שוב`, `{n}`. Plural, so any friend's voice can say it. Three fixed lines: **no `{land}`, no variable, three clips** (the voice keeps `נְשַׂחֵק` pointed, because the sin dot is read `sh` without it).
- **Hebrew is "with words", not "in Hebrew".** The whole app speaks Hebrew, so "let us play in Hebrew" is odd to a child who hears nothing else; the Hebrew course is words, rhymes, letters and stories, and "with words" fits every band of it. The label for a screen reader names the language (`בעברית`) so that a parent who hears it knows which door opens. If you prefer the same pattern for all three (`בּוֹאוּ נְשַׂחֵק בְּעִבְרִית.`), it is one word in one row.
- **Not used:** `בּוֹאוּ נִפְתַּח אֶת הַדֶּלֶת שֶׁל אַנְגְּלִית.` (it names the door, but the bottle may open the course directly, with no door screen; and it would then say something that does not happen).
- **For the developer:** the five existing lines stay for the six lands. A language stop uses its own line whatever the reason. If a stop on the island has no course (cannot happen when a language is on), nothing is said.
- **For the voice director:** three short clips for the friend's voice, 3 words each (about 60 characters in all); a gentle invitation, not a cheer.

## 5. Before and after, in one list

| # | Text | Before | After |
|---|---|---|---|
| 1 | `he-ins-how-many` (English course) | כמה יש? הקשיבו לכפתורים, וגעו במספר הנכון. (unpointed) | כַּמָּה יֵשׁ? הַקְשִׁיבוּ לַכַּפְתּוֹרִים, וּגְעוּ בַּמִּסְפָּר הַנָּכוֹן. |
| 2 | Russian F40 | כמה ספרנו? הקשיבו, וגעו במספר. | the same line as 1 |
| 3 | Russian `parentText` M-RUS-YESNO | בשאלות של כן ולא, או של "אותו דבר" ו"לא אותו דבר", אם הילד עונה כל פעם אותה תשובה, כנראה שהשאלה עדיין לא ברורה לו עד הסוף. זה נורמלי בהתחלה. | אם הילד עונה כל פעם אותה תשובה בשאלות של כן ולא, או בשאלות של אותו דבר או לא, כנראה שהשאלה עדיין לא ברורה לו עד הסוף. זה נורמלי בהתחלה. |
| 4 | Russian `parentText` M-RUS-NUMWORD | מילת המספר ברוסית, או אולי הכמות עצמה, עדיין חדשה לילד, ולכן מספרים קרובים (три ו־четыре) מתחלפים לפעמים. זה רגיל בגיל הזה. | כשהילד מתבלבל בין מספרים סמוכים (три ו־четыре), ייתכן שמילת המספר ברוסית עדיין חדשה לו, או שהכמות עצמה עדיין חדשה לו. זה רגיל בגיל הזה. |
| 5 | `i-odd-animals` | (draft) מָה הִגִּיעַ בְּטָעוּת לַקֻּפְסָה שֶׁל בַּעֲלֵי הַחַיִּים? | unchanged; voice text added |
| 6 | `i-odd-food` | (draft) מָה הִגִּיעַ בְּטָעוּת לַקֻּפְסָה שֶׁל הָאֹכֶל? | unchanged; voice text keeps `הָאֹכֶל` |
| 7 | `i-odd-clothes` | (draft) מָה הִגִּיעַ בְּטָעוּת לַקֻּפְסָה שֶׁל הַבְּגָדִים? | unchanged; voice text added |
| 8 | the island and the three hellos, the three names | אִי הַשָּׂפוֹת · שָׁלוֹם · אנגלית, עברית, רוסית | unchanged (checked) |
| 9 | `languagesDoorsHello` | (to be written) | בּוֹאוּ נִפְתַּח דֶּלֶת. מִי אוֹמֵר לָנוּ שָׁלוֹם? |
| 10 | parent texts (§3) | the previews and §6 of the spec | 52 rows: 20 changed in wording, 12 new (the other state of a switch, a label, a gate state: things the previews did not show), 20 kept as drawn |
| 11 | the bottle's lines for a language stop (§4) | none | 3 proposals |

## 6. Questions for the owner (numbered)

1. **The door line.** `בּוֹאוּ נִפְתַּח דֶּלֶת. מִי אוֹמֵר לָנוּ שָׁלוֹם?` or only `בּוֹאוּ נִפְתַּח דֶּלֶת.` (§1)? I recommend the two sentences.
2. **The bottle's Hebrew line (§4, proposal).** "בואו נשחק במילים" for the Hebrew course, or "בואו נשחק בעברית" like the other two? I recommend "with words".
3. **The three route names** in the Russian stress-mark setting: `לומדים חדשים`, `רוסית בבית`, `קוראים` (§3.2). If your own words are different, it is one row. The Russian teacher should confirm them (they are the words of the three routes of the Russian syllabus §7.1).
4. **The Hebrew "parent check of reading aloud"** (§3.2): the sources do not say how it works, so the help text says only that it is practice, without a mark, and for the parent. If you tell me what the parent does in it, I write the line.
5. **Status words (§3.3).** I used the app's own `בתרגול`, `מובן`, `כדאי לחזור` and a new `מובן וזכור`, instead of the design's `לומדים עכשיו`, `הבינו`, `הבינו וזוכרים`. OK?

## 7. For the other agents

- **app-developer:** the keys above are suggestions (the existing ones in `he.dart` are `areaVoice`, `progressMisconceptions`, `progressResolved`, `progressNotYetPlayed`, `statusPractising`, `statusUnderstood`, `statusRevisit`: reuse them). Child text (§1 and §4) has `nikud: true` and a line height of 1.7; adult text has none. `{lang}`, `{child}`, `{n}`, `{a}` to `{d}`, `{route}`, `{default}` and `{when}` are filled by `Str.fill`; none is ever sent to a voice. The three bottle lines are fixed strings with no placeholder. The three "התקדמות ב…" strings are three keys. A Russian or Latin word inside a parent text is an isolated left-to-right run (as in the Russian parent texts). The master table (`tools/hebrew_voice_review.py`) needs `languagesDoorsHello`, `adventureLangEnglish`, `adventureLangRussian` and `adventureLangHebrew` in `VOICED_UI` once they are in `he.dart`.
- **voice-and-sound-director:** spoken lines: `languagesDoorsHello` (one clip, the friend's voice), the three `adventureLang…` clips (the friend's voice) and `שָׁלוֹם` (the Hebrew course voice; `Hello` and `Привет` are the teachers'). All are plural or "let us"; none has a variable; none needs a name. Please listen to `נְשַׂחֵק` and to `דֶּלֶת` in the pilot.
- **english-language-teacher, russian-language-teacher:** the only Hebrew that touches you is the parent text of §3 (the names of the strands of your courses, and the route names of §6, question 3).
- **curriculum-expert:** `frame.md` §1.1 and §1.2 still say that the island's name and the Hebrew hello "need the editor"; both are now final (this file). The English "oral only" and the Russian letters switch have the texts of §3.2.
- **design-director:** the parent previews carry the wording of the drawn text; the changed words are in §3. Three help lines are now three sentences (`areaLangVoiceHelp`, `areaLangPersonalHelp`, `areaLangStressHelp`) and `areaLangGateClosed` is two; please check the card heights on the phone. The progress intro is shorter than the drawn one.
