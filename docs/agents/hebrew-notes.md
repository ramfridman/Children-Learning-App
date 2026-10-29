# Hebrew notes (the text editor's rules, decisions, generator bugs and questions)

Written by the hebrew-text-editor on 2026-10-28 for the voice-and-sound-director, a future editor and the main assistant.
The table is `docs/review/hebrew-master.csv`; every decision below is a rule in `tools/hebrew_voice_review.py`
(`SUBS`, `MANUAL`, `TUTOR_SUBS`, `grammar()` steps 1 to 7, `KTIV`, `KEEP_POINTED`, `VOICE_SUBS`, `PLACEHOLDERS`,
`REVIEWED`, `PENDING`, `DOUBT`, `NOTE`), so a rerun gives the same table:

    PYTHONIOENCODING=utf-8 python tools/hebrew_voice_review.py

Nothing in the pack, the generators or the app was changed. The corrected texts are only in the table (`ui_text`,
`voice_text`); section 4 says how to bring them into the sources.

## 1. What was reviewed, and how

| Group | Rows | Distinct texts | How |
|---|---|---|---|
| 1. App screens | 322 | 311 | every text read |
| 2. Core voice lines | 27 | 27 | every text and voice text read |
| 3. Lesson content | 8,956 | about 2,400 | every distinct text read as a *template*: number words were folded into one slot (`N`), so 326 prompt, 374 hint, 235 correct-feedback and 57 other feedback shapes were read with one real example each; all 222 labels, 310 lesson texts, 200 skill texts, 88 parent texts and the 17 alt texts that differ from their prompt were read one by one. Number and noun agreement inside the folded slots was checked by a scan of every number word before a plural noun (no mismatch left). |
| 4. Tutor lines (hero-son) | 66 | 57 | every line read (gender forms f, m, n checked against the line) |
| 5. Alert word lists | 23 | 23 | spelling only; left `unchanged` (see question 9) |
| 6. Helper lexicon | 118 | 118 | spelling read (110 in the pass; the 8 words of B-24, the tens `שלושים` to `תשעים` and `מאה`, on 2026-10-29) |

**Rows added after the master pass (2026-10-29).** `REVIEWED` covers whole groups, so a new row of group 1 to 4 or 6
would be marked `text-ready` unread. Such a row goes into `PENDING` (it stays `proposed` with its comment) until the
editor has read it and the owner has seen it; each run prints the rows that were not in the last table. Now in
`PENDING`: the 10 B-26 strings (`homeIsland*`, `nitziHome*`, see `docs/agents/b26-hebrew.md`) and `homeBubble` (its
B-26 replacement). Read and kept `text-ready`: the 8 lexicon words added with B-24 (`שלושים` to `תשעים`, `מאה`), spelt
as a recogniser writes them (`שישים`, `חמישים` with yod), so group 6 is now 118 rows.

**B-26 (2026-10-29).** Every line on the home screen is said by the friend the child chose (owner decision 4), so no
line names Nitzi and none has a first person with a gender: `nitziHomeHi` is `זֶה הַבַּיִת שֶׁלִּי.` (was `אֲנִי נִיצִי.
אֲנִי גָּרָה פֹּה.`). The bottle holds a revisit or the next lesson (decision 3), so `nitziHomeBottle` is `בַּבַּקְבּוּק
יֵשׁ הַרְפַּתְקָה. בּוֹאוּ נִפְתַּח אוֹתוֹ.` (was "brought a new adventure"), and the map bubble `homeBubble`
(`{child}, הַבַּקְבּוּק הִגִּיעַ!`) became `{child}, בַּבַּקְבּוּק יֵשׁ הַרְפַּתְקָה!` in B-26 step 2. That line was too wide
for the tablet map (its fixed part 207 at Heebo 500, 24, measured with the app's text engine; the bubble then covers
the Counting stairs in landscape and touches the Counting sign in portrait: `docs/design/b26-step2-review.md` §3, QA-25,
QA-26), so the map bubble is now **`{child}, מַה בַּבַּקְבּוּק?`** (fixed part 123; limit 140; voice text `מה בבקבוק?`,
the name said before it as in Q6). It is true for a revisit and for a new lesson, has no verb (no gender guessed, fits
a boy or girl friend), no time and no pressure; Nitzi's home answers the question with the full sentence
(`nitziHomeBottle`). Weighed and not taken: `הִנֵּה הַבַּקְבּוּק!` (127; correct, but only points), `הַבַּקְבּוּק כָּאן!`
(125; sounds like "it has just arrived", the claim we removed), `מַה יֵּשׁ בַּבַּקְבּוּק?` (156, too wide), `הַבַּקְבּוּק
מְחַכֶּה!` (147, too wide and a little pressing), `בּוֹאוּ לַבַּקְבּוּק!` (131; a plural verb right after one child's name
reads like a slip). `מַה` keeps patah: the next letter carries a dagesh (rule 4). `nitziHomeBottleDone` waits for the
daily three-stop plan. The `nitziHome*` key names name the screen, not the speaker.

Voice texts: about 520 of the 1,975 distinct voice texts were read in full (all money, clock, ordinal and maths
lines, all core and tutor lines, a random sample of 120 and every line a rule changed), plus all
1,975 machine-checked for Latin letters, digits, symbols, curly brackets, "!" and double spaces (none left).

Not reviewed: whether the Band B number slots read well for *every* value (only one example per template was read by eye),
and how any line sounds (that needs audio and the voice director).

## 2. Style rules for the screen text

1. **Who is addressed.** Children in the plural (`בּוֹאוּ`, `לְחַצְתֶּם`); instructions in the impersonal present
   (`נוֹגְעִים`, `סוֹפְרִים`, `עוֹצְרִים כְּשֶׁמַּגִּיעִים`) or the infinitive after "now your turn" (`עַכְשָׁו תּוֹרְכֶם — לִלְחֹץ עַל…`).
   Never a singular "you" (`לְפָנֶיךָ` in a title was removed). Tutor lines follow the profile form (f, m, n) and use the
   first person plural for "let us" (`בוא ננסה`, `בואי ננסה`, `בואו ננסה`; never `בוא נסה`).
2. **Numbers.** A bare number, a numeral tile and counting are feminine (`אַחַת, שְׁתַּיִם`, `לִלְחֹץ עַל אַרְבַּע`). A number
   with a noun agrees with it (`שְׁלוֹשָׁה תַּפּוּחִים`, `שָׁלוֹשׁ צִפֳּרִים`); before a noun `שְׁתֵּי / שְׁנֵי`. A sum that speaks
   about masculine objects may stay masculine (`חֲמִשָּׁה פָּחוֹת שְׁנַיִם` after "five apples"); see question 8.
   Nouns checked for gender: `מַטְבֵּעַ, חָרוּז, גֶּרֶב, פְּרִי` are masculine; `כַּף, קְעָרָה, נַעַל, צֶלַע, פַּעַם, אֶבֶן, צִפּוֹר` feminine.
3. **Demonstratives and pronouns.** `זֶה` (m), `זוֹ` (f), `אֵלֶּה` (pl); the pressed thing takes `עָלָיו / עָלֶיהָ`; a feminine
   solid takes `שֶׁלָּהּ` (`הַפִּירָמִידָה`, `הַתֵּבָה`).
4. **Pointing (child texts have full nikud).** `כׇּל` with a qamatz qatan everywhere (also `לְכׇל`, `בְּכׇל`); `הֲכִי`; `מְאֹד`;
   `תׇּכְנִית`; `מַה` + dagesh before a non-guttural (`מַה זֶּה`, `מַה לִּבְדֹּק`), `מָה` stays before א ה ח ע ר; `מֵ` before a guttural
   (`מֵאֶפֶס`, `מֵאַחַת`, `מֵהַ…`). The conjunctive vav: `וּ` before a shva or a labial-with-shva (`וּמְשֻׁלָּשִׁים`), `וַ` before a hataf
   patah (`וַחֲמִשָּׁה`), `וִי` before `יְ`, and **no dagesh** in the בגדכפת letter after it (`וְכָחֹל`, `וְתֵשַׁע`). A one-letter prefix
   with a shva: no dagesh in the next בגדכפת letter (`בְּבַרְוָז`, `בְּדָג`), `בִּ / לִ` before a shva (`בִּשְׁנֵי`, `לִשְׁתֵּי`), `בַּ` before a
   hataf (`בַּחֲמִשָּׁה`, `בַּהֲגִינוּת`). Article: `הָ` before ר and עֲ (`הָרוֹבּוֹט`, `הָעֲשָׂרוֹת`). Word forms: `מְצָאתֶם`, `נְתַתֶּם`,
   `נְחַתֶּם`, `חֲלָלִית`, `חִידָה`, `שְׂמָאלִי` (but `שְׂמֹאלָה`), `מִסְתַּכְּלִים`, `מְאֻחָר`, `הַטָּעֻיּוֹת`, `סִימַן הַשָּׁוֶה`.
5. **Words for ages 3 to 8.** Written-register words were replaced by spoken ones: `הַאִם` dropped from yes-no questions,
   `אַחֶרֶת` → `אִם לֹא`, `תּוֹךְ כְּדֵי` → `בִּזְמַן שֶׁ`, `מִקּוֹדְמוֹ` → `מֵהַמִּסְפָּר / מֵהַמִּגְדָּל שֶׁלְּפָנָיו`, `בִּלְבַד` → `רַק`,
   `אֵינוֹ` → `הוּא לֹא`, `הִבְחַנְתֶּם` → `שַׂמְתֶּם לֵב`, `חֲפָצִים` → `דְּבָרִים`.
6. **Wrong words fixed** (the text said something else than meant): `מְעַקְבִים` (not a word) → `עוֹקְבִים בָּאֶצְבַּע אַחֲרֵי`;
   `מַכְוִינִים שָׁעוֹן` → `מְכַוְּנִים`; `מַסְדִּירִים` (regulate) → `מְסַדְּרִים`; `סוֹדְרִים` → `מְסַדְּרִים`; `נַחֲזִיק אֶצְבָּעוֹת` (wish luck) →
   `נָרִים אֶצְבָּעוֹת`; `נִפְרֹד אֶת הָעֶשֶׂר` (say goodbye) → `נַפְרִיד`; `פִּתַּחְתֶּם חִידָה` (developed) → `פְּתַרְתֶּם`; `עִקַּבְתֶּם`
   (delayed) → `עֲקַבְתֶּם`; `עֵרַבְתֶּם` → `עִרְבַּבְתֶּם`; `נַחֲלֹק לְזוּגוֹת` → `נְחַלֵּק`; `בַּתּוֹר` (in the queue) → `לְפִי הַתּוֹר`;
   `שָׂחָה לְהֵרָחֵק` → `שָׂחָה מִשָּׁם`; `עֲצְרוּ כְּשֶׁהִגַּעְנוּ` → `עוֹצְרִים כְּשֶׁמַּגִּיעִים`.
7. **Agreement.** `הַמֹּאזְנַיִם` is plural (`אוֹמְרִים`), and scales are `מְאֻזָּנִים`, never `שָׁווֹת`; two sides are `שָׁוִים`.
   Two feminine nouns go `הוֹלְכוֹת יַחַד` (`קְעָרָה וְכַף`), a mixed pair `הוֹלְכִים`.
8. **Adult texts** (parent area, skill titles, parent texts) have no nikud and use the infinitive for advice. A skill
   title written with nikud was unpointed. A sum inside an adult line is isolated left to right with U+2066 … U+2069 so
   `7 = 3 + 4` is not shown as `4 + 3 = 7` (M-EQ-OPER).
   A length limit says `תווים` (not `אותיות`: a name may hold a space or a hyphen) and states what is allowed, not what
   went wrong (`אפשר לכתוב עד 24 תווים.`, as `prizesBad`). Forbidden symbols are joined with `או`, never a hyphen-vav
   (`ו->` reads as an arrow); `<` and `>` mirror in RTL, which is harmless when both are named, so no isolates (B-28).

## 3. Rules for the voice text (what the voice director receives)

1. **Spelling.** Plain letters in full spelling (ktiv male) made from the nikud: holam and qubuts → ו, a hiriq in an open
   syllable or before a doubled letter → י (`ביקשתם`, `תיקנתם`, `שיעור`, `עיגול`), a consonant vav inside a word doubled
   (`שווה`, `הוורוד`, `מכוונים`), a doubled consonant yod doubled (`שייך`, `מציירים`, `קובייה`; not after ו or after a prefix:
   `מצוין`, `שיש`, `הים`), the dual `ַיִם` → `יים`. No yod after a prefix מִ / a dropped nun (`מכאן`, `מתחת`, `הגיע`, `הנה`), or
   before a silent aleph (`ראשון`). Exceptions are in `KTIV` (`התוכנית`, `צהריים`, `המחוג`, `חיה`).
2. **Nikud kept** on every number word (gender) and on words a TTS can misread: `שֵׁנִי / הַשֵּׁנִי` (ordinal, not "two of"),
   `הַוִּי` (the tick), `נִסְפַּר`, `נְחַתֶּם`, `לְהֵרָאוֹת` (`KEEP_POINTED`).
3. **Punctuation.** `!` is never sent. A short opening cheer becomes a comma (`כֵּן, …`, `כִּמְעַט, …`); **a number said as the
   answer becomes a full stop** (`שָׁלוֹשׁ. חֲמִשָּׁה ועוד שְׁלוֹשָׁה הם שְׁמוֹנֶה.`; with a comma it sounded like part of the sum);
   anything else a full stop. Every line ends with `.`, `?` or `…`. Colons and em dashes stay (a beat).
4. **Said differently from the screen** (written in `changes`): `וְ… נַעֲשִׂים כָּתֹם` → `ועוד צבע… נעשים כתום`;
   `לחזור על: ימינה…` → `לחזור על הצעדים: ימינה…`; `בואו נאמר` → `בואו נגיד`.
5. **Variables.** None is ever sent. `{child}`: the voice text is the line without the name and the row says PER-NAME
   (question 6). No spoken line has a number variable.
6. **Maths and symbols.** No spoken line contains `=`, `×`, `÷` or digits; `=` is always written `שָׁוֶה`. No line needs `÷`
   read aloud yet (question 10).

## 4. Bugs for the main assistant (content and generators; apply with the owner's OK)

The simplest way to bring the corrections in: for each row with `ui_text` ≠ `text`, replace the text in its source
(`content/units/*.json`, `app/lib/strings/he.dart`, `content/lines/core.he.json`, `content/tutor-lines/hero-son.json`), then
fix the templates below so a regeneration does not bring the old text back. Each row keeps its id in the table.

| # | Where | Rows (source › id) | Fix |
|---|---|---|---|
| G1 | `tools/band_b.py:518` (missing addend hint) | `activity.b.mathb18.1`–`.7` › `hints.2` | The hint counts 1..total and names the answer; count on instead: `'%s, וּמַמְשִׁיכִים לִסְפֹּר עַד %s: %s. סָפַרְנוּ %s — לִלְחֹץ עַל %s.' % (F[x], F[total], ', '.join(F[i] for i in range(x+1, total+1)), F[total-x], F[total-x])` (owner question 3) |
| G2 | `tools/author.py:41` `NumWords.vav` | every `עֶשְׂרִים וְתֵּשַׁע` (`… וְתֵּשַׁע`) | drop the dagesh of a בגדכפת first letter after `וְ` (`וְתֵשַׁע`) |
| G3 | `tools/band_b.py:224` `'%s וְ%s'` | `activity.b.numb10.*` › `hints.2` | use `NumWords.vav(F[b])` (`וּשְׁבַע עֶשְׂרֵה`, `וּשְׁתַּיִם`) |
| G4 | `tools/author.py:279` `'נוֹגְעִים בְּ%s אֶחָד'` | `activity.count.ladybugs.3/6/10`, `activity.count.birds.10`, `activity.b.numb04.5/6` › `hints.0` | `אֶחָד / אַחַת` by the noun's gender, and no dagesh after `בְּ` (`בְּדָג`, `בְּתַפּוּחַ`) |
| G5 | `tools/author.py:754` `'%s וְ%s הוֹלְכִים יַחַד'` | `activity.log.pair.*` › `hints.2` | `הוֹלְכוֹת` when both nouns are feminine; no dagesh after `וְ` |
| G6 | `tools/band_b.py:27` `OBJECTS['sock']` `'g': 'f'` | `activity.log.pair.sock`, `.shoe` | `'g': 'm'` (`זֶה גֶּרֶב`) if the owner agrees (question 5) |
| G7 | `tools/author.py:74` `M-CNT-SIZE` | 16 rows › `feedback.incorrect.0` | `'מַה שֶּׁתּוֹפֵס יוֹתֵר מָקוֹם לֹא תָּמִיד יֵשׁ בּוֹ יוֹתֵר. בּוֹאוּ נַשְׁוֶה אֶחָד אֶחָד.'` (question 2) |
| G8 | `tools/author.py:76` `M-ORD-CARD` | 7 rows | `אֵינוֹ` → `הוּא לֹא` |
| G9 | `tools/author.py:243, 258, 260, 264, 334, 387, 686, 690, 840, 845, 875` | hints and feedback | `נַחֲזִיק` → `נָרִים`; `תוֹךְ כְּדֵי` → `בִּזְמַן שֶׁ`; `עֲצְרוּ כְּשֶׁהִגַּעְנוּ` → `עוֹצְרִים כְּשֶׁמַּגִּיעִים`; `נָתַתֶּם` → `נְתַתֶּם`; `מָצָאתֶם` → `מְצָאתֶם`; drop `הַאִם`; `מִ%s` → `מֵ` before א/ע (`מֵאֶפֶס`); `נָחַתֶּם` → `נְחַתֶּם` |
| G10 | `tools/band_b.py:164, 173, 259, 293, 338, 358, 445–447, 477, 534` | numbers and maths | `נִפְרֹד` → `נַפְרִיד`; `כַּמָּה חָסַר` → `חָסֵר`; `מִ%s` → `מֵ` before א; `מִקּוֹדְמוֹ ב%s` → `מֵהַמִּסְפָּר שֶׁלְּפָנָיו בְּ…` (with the prefix pointed); `וּזְוּגוֹת` → `וְזוּגוֹת`; `סִימָן הַ-שָׁוֶה … אוֹתוֹ דָּבָר` → `סִימַן הַשָּׁוֶה אוֹמֵר: בִּשְׁנֵי הַצְּדָדִים יֵשׁ אוֹתוֹ מִסְפָּר`; `אוֹמֵר הַמֹּאזְנַיִם` → `אוֹמְרִים`; `שָׁווֹת` → `שָׁוִים` (sides) / `מְאֻזָּנִים` (scales); `לְפָנֶיךָ` → `עוֹד עַד עֶשְׂרִים`; `בְּחַלְלִית` → `בַּחֲלָלִית`; `בשְׁתַּיִם`, `בעֶשֶׂר` → `בִּשְׁתַּיִם`, `בְּעֶשֶׂר` |
| G11 | `tools/band_b2.py:53–56, 101, 123, 157, 161, 171, 202, 240, 263–264, 277, 295` | colours, logic, shapes | `הַכִּי` → `הֲכִי`; `עֵרַבְתֶּם` → `עִרְבַּבְתֶּם`; M-SHP-CLOSED line (MANUAL in the script); `הַאִם`; `שֶׁלּוֹ` → `שֶׁלָּהּ` for a feminine solid; `מִקּוֹדְמוֹ`; `אַחֶרֶת` → `אִם לֹא`; `לְכָל` → `לְכׇל`; `צָרִיךְ שֶׁגַּם לֹא…` → `מְחַפְּשִׂים מַשֶּׁהוּ שֶׁהוּא לֹא…`; `פִּתַּחְתֶּם חִידָּה` → `פְּתַרְתֶּם חִידָה` |
| G12 | `tools/band_b3.py:72, 120, 139–140, 154–156, 175, 184, 200, 211, 214` | tracing, money, clock, charts | `מְעַקְבִים` → `עוֹקְבִים`; `מַסְתַּכְּלִים` → `מִסְתַּכְּלִים`; `הַ-וִי` → `הַוִּי`; `בְּ%s` must point the prefix by the next letter (`בִּשְׁנֵי`, `בַּחֲמִשָּׁה`, `בַּעֲשָׂרָה`) and `וְ%s` likewise (`וּשְׁנֵי`, `וַחֲמִשָּׁה`); `אֵיזֶה יֵשׁ הַכִּי…` → `מִמָּה יֵשׁ הֲכִי הַרְבֵּה / מְעַט?`; `מַכְוִינִים` → `מְכַוְּנִים`; `שֶׁעַל הַגּוּף` → `שֶׁיֵּשׁ עָלָיו`; `עִקַּבְתֶּם` → `עֲקַבְתֶּם` |
| G13 | Band A unit specs `content/units/{colours,counting-hills,math,logic,robots,shapes,…}.json` | the lines in the table | the hand-written texts (`מַסְדִּירִים`, `חֲבֵרִים צוּרוֹת`, `שָׂחָה לְהֵרָחֵק`, `אֵיזוֹ תְּמוּנָה הִיא…`, `מְמַיְּנִים לִשְׁלוֹשׁ`, `וְכָּחֹל`, `וְדַּף`, …): replace by `ui_text` |
| G14 | `content/tutor-lines/hero-son.json` | group 4 | full spelling of the future forms (`נספור`, `ניגע`, `ניתן`, `נגיד`), `בוא ננסה`, `רק` for `בלבד`; the table has every line |
| A1 | app: `a11y.altText` | 750 activities | the alt text is the prompt (a question) instead of a description of the picture; not a language error, but a screen reader hears the question twice |
| A2 | app: maths inside Hebrew lines | M-EQ-OPER parent text, and any future line with a sum in digits | isolate digits-and-signs runs with U+2066 … U+2069 (or render maths in an LTR span) |

## 5. Questions for the owner

1. **Mixed nikud standard.** The pack points in full ktiv chaser with nikud (`מְאֻחָר`, `כׇּל`); I unified the few plene forms
   (`מְאוֹד`, `מְאוּחָר`, `הַטָּעוּיוֹת`). OK to keep this standard everywhere?
2. **M-CNT-SIZE line** (16 rows, `feedback.incorrect.0`): the old line said "more does not always mean bigger"; the misconception is
   the reverse. Proposed: `מַה שֶּׁתּוֹפֵס יוֹתֵר מָקוֹם לֹא תָּמִיד יֵשׁ בּוֹ יוֹתֵר. בּוֹאוּ נַשְׁוֶה אֶחָד אֶחָד.` Agree?
3. **Missing-addend hints** (`activity.b.mathb18.1`–`.7` › `hints.2`): count on from the first number (G1)? The rows stay `proposed`.
4. **`core.encourage.checked`**: keep `זֶה מַה שֶּׁמָּתֵמָטִיקָאִים עוֹשִׂים` or a shorter word for a three-year-old?
5. **גֶּרֶב** masculine (standard) or feminine (common speech)? 8 rows in `activity.log.pair.*` wait.
6. **The per-name line** `homeBubble` (`{child}, מַה בַּבַּקְבּוּק?` since B-26; was `{child}, הַבַּקְבּוּק הִגִּיעַ!`): one clip
   per child with the name inside, or a name clip joined to `מה בבקבוק?`? (Your decision of 2026-10-25 allows the first
   name; how it is joined is yours and the voice director's.)
7. **`תֵּבָה`** for the box-shaped solid (school word) or `קֻפְסָה` (everyday)? Left as `תֵּבָה`.
8. **Sums about objects.** Hints say `חֲמִשָּׁה פָּחוֹת שְׁנַיִם` after "five apples" (masculine) but the tiles and the counting are
   feminine. Keep (grammatical, follows the noun) or make every spoken sum feminine as at gan (`חָמֵשׁ פָּחוֹת שְׁתַּיִם`)?
9. **Alert word lists** (group 5): the spelling is right; whether the lists are complete needs someone who works with
   children. Left `unchanged`.
10. **÷ read aloud.** No spoken line uses ÷ yet. When it comes: `לְחַלֵּק לְ` or `חֲלָקִי`? (Rule: ask before writing it.)
11. **Coin names in the shop hints** (`אֶפְשָׁר לְשַׁלֵּם בִּשְׁנֵי שְׁקָלִים וַחֲמִשָּׁה שְׁקָלִים`): this names amounts, not coins. Say the
    coins (`בְּמַטְבֵּעַ שֶׁל שְׁנֵי שְׁקָלִים וּבְמַטְבֵּעַ שֶׁל חֲמִשָּׁה`) at the cost of longer lines? Left as is.

## 6. For the voice-and-sound-director

- Take only rows with status `text-ready` (9,448 now) and the `voice_text` column; 33 rows are `proposed` and wait for the owner.
- Number words carry nikud on purpose (gender and stress); do not strip it. `שֵׁנִי`, `הַוִּי`, `נְחַתֶּם` are pointed for the same reason.
- The long number lists (up to ten numbers: `אַחַת, שְׁתַּיִם, … עֶשֶׂר.`) and the robot step lists (`ימינה, ימינה, למעלה…`) are
  the lines most likely to be rushed; the commas are the breaths. If you need a slower cadence, ask and I change the
  punctuation (`…` between numbers, as in `אַחַת… שְׁתַּיִם…`), never the words.
- A number answer at the start of a correct-feedback line is followed by a full stop on purpose (it is the answer, said
  alone, then the reason).
- The blank in the colour-mixing prompts is said as `ועוד צבע…`; the program lines as `לחזור על הצעדים:`.
- 767 activities share `כמעט, בואו ננסה שוב.` and 767 share `שאלה טובה, בואו נראה יחד.`; voice each once.
- `homeBubble` is a PER-NAME line (question 6).
