# Hebrew notes (the text editor's rules, decisions, generator bugs and questions)

Written by the hebrew-text-editor on 2026-10-28; updated on 2026-10-29 with the owner's answers to the questions of
section 5 (asked by the orchestrator, answered by the owner the same day). For the voice-and-sound-director, a future
editor, the app-developer and the main assistant. The table is `docs/review/hebrew-master.csv`; every decision below is a
rule in `tools/hebrew_voice_review.py` (`SUBS`, `MANUAL`, `TUTOR_SUBS`, `ROW_RULES`, `grammar()` steps 1 to 8,
`numbers_alone()`, `KTIV`, `KEEP_POINTED`, `VOICE_AUDIT_KEEP`, `VOICE_SUBS`, `PLACEHOLDERS`, `REVIEWED`, `PENDING`, `DOUBT`, `NOTE`, `OWNER_APPROVED`),
so a rerun gives the same table:

    PYTHONIOENCODING=utf-8 python tools/export-hebrew-review.py
    PYTHONIOENCODING=utf-8 python tools/hebrew_voice_review.py

Nothing in the pack, the generators or the app was changed. The corrected texts are only in the table (`ui_text`,
`voice_text`); section 4 says how to bring them into the sources.

## 1. What was reviewed, and how

| Group | Rows | Distinct texts | How |
|---|---|---|---|
| 1. App screens | 384 | 373 | every text read (the B-26 home, the B-28 name-limit and the word-alert texts came from `main` on 2026-10-30) |
| 2. Core voice lines | 27 | 27 | every text and voice text read |
| 3. Lesson content | 8,956 | about 2,400 | every distinct text read as a *template*: number words were folded into one slot (`N`), so 326 prompt, 374 hint, 235 correct-feedback and 57 other feedback shapes were read with one real example each; all 222 labels, 310 lesson texts, 200 skill texts, 88 parent texts and the 17 alt texts that differ from their prompt were read one by one. Number and noun agreement inside the folded slots was checked by a scan of every number word before a plural noun (no mismatch left). On 2026-10-29 every masculine number word in a spoken row was listed with its neighbours (293 contexts) for the owner's rule Q8. |
| 4. Tutor lines (hero-son) | 66 | 57 | every line read (gender forms f, m, n checked against the line) |
| 5. Alert word lists | 649 | 649 | spelling only; left `unchanged` (question 9, still open; the three-tier lists of `main`) |
| 6. Helper lexicon | 118 | 118 | spelling read (the 8 tens words `שלושים` … `מאה`, new in the export of 2026-10-29, read too) |

**Rows added after the master pass (2026-10-29).** `REVIEWED` covers whole groups, so a new row of group 1 to 4 or 6
would be marked `text-ready` unread. Such a row goes into `PENDING` (it stays `proposed` with its comment) until the
editor has read it and the owner has seen it; each run prints the rows that were not in the last table. After the
owner's B-26 answers (2026-10-29, merged with the voice branch on 2026-10-30) `PENDING` holds only the B-26 strings he
has not answered: `homeIsland`, `homeIslandMine` and their two screen-reader texts, `nitziHomeTreasures` and
`nitziHomeBottle`. Decided and out of `PENDING`: `nitziHomeWelcome(NoName)`, `nitziHomeBottleDone`, `homeBubble` and
`homeBubbleNoName` (`ROW_RULES`, `text-ready`), and `nitziHomeHi` (`OWNER_APPROVED`: he chose that exact line). Read and kept `text-ready`: the 8 lexicon words added with B-24 (`שלושים` to `תשעים`, `מאה`), spelt
as a recogniser writes them (`שישים`, `חמישים` with yod), so group 6 is now 118 rows.

**B-26 (2026-10-29).** Every line on the home screen is said by the friend the child chose (owner decision 4), so no
line names Nitzi and none has a first person with a gender: `nitziHomeHi` is `זֶה הַבַּיִת שֶׁלָּנוּ.` (the owner's choice, 2026-10-29;
first `זֶה הַבַּיִת שֶׁלִּי.`, was `אֲנִי נִיצִי. אֲנִי גָּרָה פֹּה.`). The bottle holds a revisit or the next lesson (decision 3), so `nitziHomeBottle` is `בַּבַּקְבּוּק
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
daily three-stop plan (owner, 2026-10-29). The welcome is `בְּרוּכִים הַבָּאִים` for every child (owner). The `nitziHome*` key names name the screen, not the speaker.

Voice texts: about 520 of the 1,975 distinct voice texts were read in full (all money, clock, ordinal and maths
lines, all core and tutor lines, a random sample of 120 and every line a rule changed), plus all distinct voice texts
machine-checked for Latin letters, digits, symbols, curly brackets, "!" and double spaces (none left). Every one of the
254 rows changed on 2026-10-29 was read in its screen and voice form.

Not reviewed: whether the Band B number slots read well for *every* value (only one example per template was read by eye),
and how any line sounds (that needs audio and the voice director).

## 2. Style rules for the screen text

1. **Who is addressed.** Children in the plural (`בּוֹאוּ`, `לְחַצְתֶּם`); instructions in the impersonal present
   (`נוֹגְעִים`, `סוֹפְרִים`, `עוֹצְרִים כְּשֶׁמַּגִּיעִים`) or the infinitive after "now your turn" (`עַכְשָׁו תּוֹרְכֶם — לִלְחֹץ עַל…`).
   Never a singular "you" (`לְפָנֶיךָ` in a title was removed). Tutor lines follow the profile form (f, m, n) and use the
   first person plural for "let us" (`בוא ננסה`, `בואי ננסה`, `בואו ננסה`; never `בוא נסה`). The home welcome is
   `בְּרוּכִים הַבָּאִים` for every child, whatever the address form (owner, B-26, 2026-10-29).
2. **Numbers (owner Q8, 2026-10-29).** A number that stands alone is feminine: a sum (`חָמֵשׁ פָּחוֹת שְׁתַּיִם שָׁוֶה שָׁלוֹשׁ`),
   an answer (`שָׁלוֹשׁ!`), a count, a numeral tile (`לִלְחֹץ עַל אַרְבַּע`), "what is left" (`הִכְנַסְנוּ שְׁתַּיִם, אָז נִשְׁאֲרוּ שָׁלוֹשׁ`),
   and "one more / one less / take one" in a sentence of numbers (`שְׁתֵּים עֶשְׂרֵה! עוֹד אַחַת.`, `קְחוּ אַחַת מִתּוֹךְ אַרְבַּע`).
   A number with its noun agrees with it (`שְׁלוֹשָׁה תַּפּוּחִים`, `שָׁלוֹשׁ צִפֳּרִים`); before a noun `שְׁתֵּי / שְׁנֵי`.
   **Never a masculine number without its noun**: where a story hint names the noun first, the noun is said again
   (`שְׁלוֹשָׁה תַּפּוּחִים וְעוֹד תַּפּוּחַ אֶחָד`, `שְׁנֵי דָּגִים וְעוֹד שְׁנֵי דָּגִים`), otherwise the number becomes feminine.
   Kept masculine (not a number but "one thing"): `כׇּל אֶחָד`, `אֶחָד אֶחָד`, `אֶחָד מֵהֶם`, `פִּסְפַּסְנוּ אֶחָד`,
   `לוֹקְחִים אֶחָד` (an apple just named), and the idiom "by one" where no other number is in the line (`בְּאֶחָד`,
   `אֶחָד יוֹתֵר, אֶחָד פָּחוֹת`; owner Q12, 2026-10-29). Rule: `numbers_alone()`, `numeric()`.
   Nouns checked for gender: `מַטְבֵּעַ, חָרוּז, פְּרִי, צַעַד` are masculine; `כַּף, קְעָרָה, נַעַל, צֶלַע, פַּעַם, אֶבֶן, צִפּוֹר,
   קֻפְסָה, אֶצְבַּע` feminine; **`גֶּרֶב` is feminine in this app** (owner Q5, 2026-10-29: `זוֹ גֶּרֶב`, `נַעַל וְגֶרֶב הוֹלְכוֹת`).
3. **Demonstratives and pronouns.** `זֶה` (m), `זוֹ` (f), `אֵלֶּה` (pl); the pressed thing takes `עָלָיו / עָלֶיהָ`; a feminine
   solid takes `שֶׁלָּהּ` (`הַפִּירָמִידָה`, `הַתֵּבָה`).
4. **Pointing (child texts have full nikud).** The pack's standard stays (owner Q1, 2026-10-29): full nikud on the
   defective spelling (ktiv chaser), the few plene forms unified (`מְאֹד`, `מְאֻחָר`, `הַטָּעֻיּוֹת`). `כׇּל` with a qamatz qatan
   everywhere (also `לְכׇל`, `בְּכׇל`); `הֲכִי`; `מְאֹד`; `תׇּכְנִית`; `מַה` + dagesh before a non-guttural (`מַה זֶּה`, `מַה לִּבְדֹּק`),
   `מָה` stays before א ה ח ע ר; `מֵ` before a guttural (`מֵאֶפֶס`, `מֵאַחַת`, `מֵהַ…`). The conjunctive vav: `וּ` before a shva or a
   labial-with-shva (`וּמְשֻׁלָּשִׁים`, `וּמַטְבֵּעַ`), `וַ` before a hataf patah (`וַחֲמִשָּׁה`), `וִי` before `יְ`, and **no dagesh** in the
   בגדכפת letter after it (`וְכָחֹל`, `וְתֵשַׁע`, `וְגֶרֶב`). A one-letter prefix with a shva: no dagesh in the next בגדכפת letter
   (`בְּבַרְוָז`, `לְכִוּוּן`), `בִּ / לִ` before a shva (`בִּשְׁנֵי`, `לִשְׁתֵּי`), `בַּ` before a hataf (`בַּחֲמִשָּׁה`). Article: `הָ` before ר
   and עֲ (`הָרוֹבּוֹט`, `הָעֲשָׂרוֹת`). Word forms: `מְצָאתֶם`, `נְתַתֶּם`, `נְחַתֶּם`, `חֲלָלִית`, `חִידָה`, `שְׂמָאלִי` (but `שְׂמֹאלָה`),
   `מִסְתַּכְּלִים`, `מְאֻחָר`, `הַטָּעֻיּוֹת`, `סִימַן הַשָּׁוֶה`.
5. **Words for ages 3 to 8.** Written-register words were replaced by spoken ones: `הַאִם` dropped from yes-no questions,
   `אַחֶרֶת` → `אִם לֹא`, `תּוֹךְ כְּדֵי` → `בִּזְמַן שֶׁ`, `מִקּוֹדְמוֹ` → `מֵהַמִּסְפָּר / מֵהַמִּגְדָּל שֶׁלְּפָנָיו`, `בִּלְבַד` → `רַק`,
   `אֵינוֹ` → `הוּא לֹא`, `הִבְחַנְתֶּם` → `שַׂמְתֶּם לֵב`, `חֲפָצִים` → `דְּבָרִים`, `זֶה מַה שֶּׁמָּתֵמָטִיקָאִים עוֹשִׂים` →
   `כָּכָה עוֹשִׂים חוֹקְרִים` (owner Q4, option A). The box-shaped solid (owner Q7, 2026-10-29): **Band A says `קֻפְסָה`** (`קֻבִּיָּה` only for a real cube);
   **Band B teaches `תֵּבָה`, bridged** (`כֵּן! זוֹ הַתֵּבָה — כְּמוֹ קֻפְסָה שֶׁל נַעֲלַיִם.`, `הַתֵּבָה דּוֹמָה לְקֻפְסָה שֶׁל נַעֲלַיִם.`).
6. **Wrong words fixed** (the text said something else than meant): `מְעַקְבִים` (not a word) → `עוֹקְבִים בָּאֶצְבַּע אַחֲרֵי`;
   `מַכְוִינִים שָׁעוֹן` → `מְכַוְּנִים`; `מַסְדִּירִים` (regulate) → `מְסַדְּרִים`; `סוֹדְרִים` → `מְסַדְּרִים`; `נַחֲזִיק אֶצְבָּעוֹת` (wish luck) →
   `נָרִים אֶצְבָּעוֹת`; `נִפְרֹד אֶת הָעֶשֶׂר` (say goodbye) → `נַפְרִיד`; `פִּתַּחְתֶּם חִידָה` (developed) → `פְּתַרְתֶּם`; `עִקַּבְתֶּם`
   (delayed) → `עֲקַבְתֶּם`; `עֵרַבְתֶּם` → `עִרְבַּבְתֶּם`; `נַחֲלֹק לְזוּגוֹת` → `נְחַלֵּק`; `בַּתּוֹר` (in the queue) → `לְפִי הַתּוֹר`;
   `שָׂחָה לְהֵרָחֵק` → `שָׂחָה מִשָּׁם`; `עֲצְרוּ כְּשֶׁהִגַּעְנוּ` → `עוֹצְרִים כְּשֶׁמַּגִּיעִים`.
7. **Agreement.** `הַמֹּאזְנַיִם` is plural (`אוֹמְרִים`), and scales are `מְאֻזָּנִים`, never `שָׁווֹת`; two sides are `שָׁוִים`.
   Two feminine nouns go `הוֹלְכוֹת יַחַד` (`קְעָרָה וְכַף`, `נַעַל וְגֶרֶב`), a mixed pair `הוֹלְכִים`.
8. **Adult texts** (parent area, skill titles, parent texts) have no nikud and use the infinitive for advice. A skill
   title written with nikud was unpointed. A sum inside an adult line is isolated left to right with U+2066 … U+2069 so
   `7 = 3 + 4` is not shown as `4 + 3 = 7` (M-EQ-OPER).
   A length limit says `תווים` (not `אותיות`: a name may hold a space or a hyphen) and states what is allowed, not what
   went wrong (`אפשר לכתוב עד 24 תווים.`, as `prizesBad`). Forbidden symbols are joined with `או`, never a hyphen-vav
   (`ו->` reads as an arrow); `<` and `>` mirror in RTL, which is harmless when both are named, so no isolates (B-28).
9. **Band rules in the words (B-13, 2026-10-29).** No speed language anywhere in the child's space (`הִסְתַּכְּלוּ מַהֵר!` →
   `הִסְתַּכְּלוּ טוֹב…`). Band A hears no right and left (`יָמִינָה`, `שְׂמֹאלָה`): the robot's sideways steps are said
   `לְכִוּוּן הַדֶּגֶל`, up and down stay (PLAN.md). Band A asks no "not" question (curriculum §8.3): `מָה לֹא שַׁיָּךְ?` →
   `מָה הִגִּיעַ לְכָאן בְּטָעוּת?`, `מָה לֹא מִתְגַּלְגֵּל?` → `מַה נִּשְׁאָר עוֹמֵד בַּמָּקוֹם?` (owner-approved 2026-10-29).
   Band B hears no right and left before SHP-B-12: the balance sides are named by where they are (`הַצַּד שֶׁלְּמַעְלָה`,
   draft). A misconception line names what the eye caught and ends in the strategy, without `לֹא` (owner Q2).

## 3. Rules for the voice text (what the voice director receives)

1. **Spelling.** Plain letters in full spelling (ktiv male) made from the nikud: holam and qubuts → ו, a hiriq in an open
   syllable or before a doubled letter → י (`ביקשתם`, `תיקנתם`, `שיעור`, `עיגול`, `לכיוון`), a consonant vav inside a word
   doubled (`שווה`, `הוורוד`, `מכוונים`), a doubled consonant yod doubled (`שייך`, `מציירים`, `קובייה`; not after ו or after a
   prefix: `מצוין`, `שיש`, `הים`), the dual `ַיִם` → `יים` (`נעליים`). No yod after a prefix מִ / a dropped nun (`מכאן`, `מתחת`,
   `הגיע`, `הנה`), or before a silent aleph (`ראשון`). Exceptions are in `KTIV` (`התוכנית`, `צהריים`, `המחוג`, `חיה`).
2. **Nikud kept** on every number word (gender) and on words a TTS can misread: `שֵׁנִי / הַשֵּׁנִי` (ordinal, not "two of"),
   `הַוִּי` (the tick), `נִסְפַּר`, `נְחַתֶּם`, `לְהֵרָאוֹת` (`KEEP_POINTED`). Proposed on 2026-10-29 (`VOICE_AUDIT_KEEP`,
   rows `proposed` with "V1", 100 rows, still waiting): `שָׂמִים`, `סָפַר`, `גְּדֵלִים`, `בַּתּוֹר`, `אִמְרוּ`, `נְגַלֶּה`, `אוֹפְּס`,
   `מֵדַלְיָה`, `אֵלֶּה`, `בַּשָּׁמַיִם`, and a beat in `אין כלום — זה אֶפֶס`; see `docs/agents/voice-pronunciation-audit.md`. No
   rare mark (U+05C7 qamatz qatan, U+05B3 hataf qamats) is ever sent to a voice.
3. **Punctuation.** `!` is never sent. A short opening cheer becomes a comma (`כֵּן, …`, `כִּמְעַט, …`); **a number said as the
   answer becomes a full stop** (`שָׁלוֹשׁ. חָמֵשׁ ועוד שָׁלוֹשׁ הם שְׁמוֹנֶה.`; with a comma it sounded like part of the sum);
   anything else a full stop. Every line ends with `.`, `?` or `…`. Colons and em dashes stay (a beat). The count-on hint
   has an ellipsis after the first number (`שָׁלוֹשׁ… וממשיכים: אַרְבַּע, …`): the voice holds the number it starts from.
4. **Said differently from the screen** (written in `changes`): `וְ… נַעֲשִׂים כָּתֹם` → `ועוד צבע… נעשים כתום`;
   `לחזור על: ימינה…` → `לחזור על הצעדים: ימינה…`; `בואו נאמר` → `בואו נגיד`.
5. **Variables (owner Q6, 2026-10-29).** None is ever sent. `{child}`: the line is **two clips**: a name clip per child
   (the parent-reviewed first name, made and cached on the device only; never a file in the repo or a bundled pack,
   SEC-5) played right before **one shared clip** `מה בבקבוק?` (`homeBubble`; `homeBubbleNoName` plays the shared clip
   alone). The `voice_text` of the row is the shared clip; the row says PER-NAME. No spoken line has a number variable.
6. **Maths and symbols.** No spoken line contains `=`, `×`, `÷` or digits; `=` is always written `שָׁוֶה`, `×` `כָּפוּל`.
   **`÷` is read `לְחַלֵּק לְ`** (owner Q10, 2026-10-29), with the prefix pointed by the number after it and the numbers
   feminine: `שֵׁשׁ לְחַלֵּק לִשְׁתַּיִם`, `שְׁמוֹנֶה לְחַלֵּק לְאַרְבַּע`, `עֶשֶׂר לְחַלֵּק לְחָמֵשׁ`, `תֵּשַׁע לְחַלֵּק לְשָׁלוֹשׁ`.
   No line uses it yet; when one comes, it goes through this rule (and the `:` setting is read the same way).

## 4. Bugs and changes for the main assistant and the app-developer (apply with the owner's OK)

The simplest way to bring the corrections in: for each row with `ui_text` ≠ `text`, replace the text in its source
(`content/units/*.json`, `app/lib/strings/he.dart`, `content/lines/core.he.json`, `content/tutor-lines/hero-son.json`), then
fix the templates below so a regeneration does not bring the old text back. Each row keeps its id in the table.
Rows that are `proposed` wait for the owner; bring in only `text-ready` (and later `owner-approved`) rows.

### 4.1 From the first pass (2026-10-28)

| # | Where | Rows (source › id) | Fix |
|---|---|---|---|
| G1 | replaced by D2 (owner Q3) | | |
| G2 | `tools/author.py:41` `NumWords.vav` | every `עֶשְׂרִים וְתֵּשַׁע` (`… וְתֵּשַׁע`) | drop the dagesh of a בגדכפת first letter after `וְ` (`וְתֵשַׁע`) |
| G3 | `tools/band_b.py:224` `'%s וְ%s'` | `activity.b.numb10.*` › `hints.2` | use `NumWords.vav(F[b])` (`וּשְׁבַע עֶשְׂרֵה`, `וּשְׁתַּיִם`) |
| G4 | `tools/author.py:279` `'נוֹגְעִים בְּ%s אֶחָד'` | `activity.count.ladybugs.3/6/10`, `activity.count.birds.10`, `activity.b.numb04.5/6` › `hints.0` | `אֶחָד / אַחַת` by the noun's gender, and no dagesh after `בְּ` (`בְּדָג`, `בְּתַפּוּחַ`) |
| G5 | `tools/author.py:768` `'%s וְ%s הוֹלְכִים יַחַד'` | `activity.log.pair.*` › `hints.2` | `הוֹלְכוֹת` when both nouns are feminine (now also `נַעַל וְגֶרֶב`); no dagesh after `וְ` |
| G6 | dropped: `OBJECTS['sock']` stays `'g': 'f'` (owner Q5) | | |
| G7 | replaced by D1 (owner Q2) | | |
| G8 | `tools/author.py:76` `M-ORD-CARD` | 7 rows | `אֵינוֹ` → `הוּא לֹא` |
| G9 | `tools/author.py:243, 258, 260, 264, 334, 387, 686, 690, 840, 845, 875` | hints and feedback | `נַחֲזִיק` → `נָרִים`; `תוֹךְ כְּדֵי` → `בִּזְמַן שֶׁ`; `עֲצְרוּ כְּשֶׁהִגַּעְנוּ` → `עוֹצְרִים כְּשֶׁמַּגִּיעִים`; `נָתַתֶּם` → `נְתַתֶּם`; `מָצָאתֶם` → `מְצָאתֶם`; drop `הַאִם`; `מִ%s` → `מֵ` before א/ע (`מֵאֶפֶס`); `נָחַתֶּם` → `נְחַתֶּם` |
| G10 | `tools/band_b.py:164, 173, 259, 293, 338, 358, 445–447, 457, 477, 534` | numbers and maths | `נִפְרֹד` → `נַפְרִיד`; `כַּמָּה חָסַר` → `חָסֵר`; `מִ%s` → `מֵ` before א; `מִקּוֹדְמוֹ ב%s` → `מֵהַמִּסְפָּר שֶׁלְּפָנָיו בְּ…` (with the prefix pointed); `וּזְוּגוֹת` → `וְזוּגוֹת`; `סִימָן הַ-שָׁוֶה … אוֹתוֹ דָּבָר` → `סִימַן הַשָּׁוֶה אוֹמֵר: בִּשְׁנֵי הַצְּדָדִים יֵשׁ אוֹתוֹ מִסְפָּר`; `אוֹמֵר הַמֹּאזְנַיִם` → `אוֹמְרִים`; `שָׁווֹת` → `שָׁוִים` (sides) / `מְאֻזָּנִים` (scales); `לְפָנֶיךָ` → `עוֹד עַד עֶשְׂרִים`; `בְּחַלְלִית` → `בַּחֲלָלִית`; `בשְׁתַּיִם`, `בעֶשֶׂר` → `בִּשְׁתַּיִם`, `בְּעֶשֶׂר` |
| G11 | `tools/band_b2.py:53–56, 101, 123, 157, 161, 171, 202, 240, 263–264, 277, 295` | colours, logic, shapes | `הַכִּי` → `הֲכִי`; `עֵרַבְתֶּם` → `עִרְבַּבְתֶּם`; M-SHP-CLOSED line (MANUAL in the script); `הַאִם`; `שֶׁלּוֹ` → `שֶׁלָּהּ` for a feminine solid; `מִקּוֹדְמוֹ`; `אַחֶרֶת` → `אִם לֹא`; `לְכָל` → `לְכׇל`; `צָרִיךְ שֶׁגַּם לֹא…` → `מְחַפְּשִׂים מַשֶּׁהוּ שֶׁהוּא לֹא…`; `פִּתַּחְתֶּם חִידָּה` → `פְּתַרְתֶּם חִידָה` |
| G12 | `tools/band_b3.py:72, 120, 139–140, 154–156, 175, 184, 200, 211, 214` | tracing, money, clock, charts | `מְעַקְבִים` → `עוֹקְבִים`; `מַסְתַּכְּלִים` → `מִסְתַּכְּלִים`; `הַ-וִי` → `הַוִּי` (one word, so the shop caption no longer breaks on the phone, design audit F14); `בְּ%s` must point the prefix by the next letter (`בִּשְׁנֵי`, `בַּחֲמִשָּׁה`, `בַּעֲשָׂרָה`) and `וְ%s` likewise (`וּשְׁנֵי`, `וַחֲמִשָּׁה`); `אֵיזֶה יֵשׁ הַכִּי…` → `מִמָּה יֵשׁ הֲכִי הַרְבֵּה / מְעַט?`; `מַכְוִינִים` → `מְכַוְּנִים`; `שֶׁעַל הַגּוּף` → `שֶׁיֵּשׁ עָלָיו`; `עִקַּבְתֶּם` → `עֲקַבְתֶּם` |
| G13 | Band A unit specs `content/units/{colours,counting-hills,math,logic,robots,shapes,…}.json` | the lines in the table | the hand-written texts (`מַסְדִּירִים`, `חֲבֵרִים צוּרוֹת`, `שָׂחָה לְהֵרָחֵק`, `אֵיזוֹ תְּמוּנָה הִיא…`, `מְמַיְּנִים לִשְׁלוֹשׁ`, `וְכָּחֹל`, `וְדַּף`, …): replace by `ui_text` |
| G14 | `content/tutor-lines/hero-son.json` | group 4 | full spelling of the future forms (`נספור`, `ניגע`, `ניתן`, `נגיד`), `בוא ננסה`, `רק` for `בלבד`; `ולעצור כשמגיעים לארבע` (Q8); the table has every line |
| A1 | app: `a11y.altText` | 750 activities | the alt text is the prompt (a question) instead of a description of the picture; not a language error, but a screen reader hears the question twice |
| A2 | app: maths inside Hebrew lines | M-EQ-OPER parent text, and any future line with a sum in digits | isolate digits-and-signs runs with U+2066 … U+2069 (or render maths in an LTR span) |

### 4.2 From the owner's answers and B-13 (2026-10-29), numbered for the app-developer

Each item says what the generator must produce; the exact words are in the table (`ui_text`) and in the script's
`ROW_RULES` builders, which can be copied. Items marked *(owner)* wait for the owner's pick or OK on the rows.

1. **D1, M-CNT-SIZE by cue (Q2).** `tools/author.py:74` and `:364–393`: replace the one `vo:fb.size` line by the cue's line:
   `more.big.*` (the picked set is big) `הֵם גְּדוֹלִים, אֲבָל כַּמָּה יֵשׁ? בּוֹאוּ נִסְפֹּר.`; `fewer.big.*` (the picked set is
   small) `הֵם קְטַנִּים, …`; `more.spread.*` `הֵם רְחוֹקִים זֶה מִזֶּה, …`; `same.*` (NUM-A-11) `בּוֹאוּ נַעֲשֶׂה זוּגוֹת: לְכֻלָּם יֵשׁ זוּג?`
   *(owner)*. Four vo ids instead of one (`vo:fb.size.big`, `.small`, `.spread`, `.pairs`). Remove the M-CNT-SIZE tag
   from NUM-A-07 (`tools/band_b3.py:79`, curriculum audit F4); until then its 7 rows have a counting line *(owner)*.
2. **D2, missing addend (Q3; replaces G1).** `tools/band_b.py:518–528` MATH-B-18: hint level 2 (today the shared
   `נִסְתַּכֵּל לְאַט…`) becomes per item `X כְּבָר יֵשׁ. מוֹסִיפִים אַחַת אַחַת עַד T, וְסוֹפְרִים כַּמָּה הוֹסַפְנוּ.` with its own vo id;
   `h3` becomes `X… וּמַמְשִׁיכִים: X+1, …, T. הֵרַמְנוּ K אֶצְבָּעוֹת. עַכְשָׁו תּוֹרְכֶם — לִלְחֹץ עַל K.` (`שְׁתֵּי אֶצְבָּעוֹת` for 2).
   The app must draw what the words say: dots for the model and one finger per count (`tap_answer` hint actions, audit F12).
3. **D3, the distractor 10 (Q3 note, content).** For the curriculum-expert and the generator: add to MATH-B-18 the
   choice "the two shown numbers added" (3 + 7 = 10), tagged M-PPW (catalogue name to confirm, audit F4), and keep the
   total (7) tagged M-EQ-OPER. A first-mistake line for 10 can be `חִבַּרְנוּ אֶת שְׁנֵיהֶם. הַשֶּׁבַע הוּא הַכֹּל — מָה חָסֵר?`
   (teaching view; editor review when it is added).
4. **D4, the give-N line (B-13, audit F1).** `vo:fb.card` (22 activities, text read from the pack by `tools/author.py:73`):
   `לָקַחְנוּ אֶת כֻּלָּם. בּוֹאוּ נִסְפֹּר וְנַעֲצֹר בַּמִּסְפָּר שֶׁצָּרִיךְ.` (owner-approved 2026-10-29; one clip).
5. **D5, `גֶּרֶב` feminine (Q5).** No generator change for the gender (`OBJECTS['sock']` is already `'f'`); G5 (`הוֹלְכוֹת`)
   now also covers `נַעַל וְגֶרֶב`; the pack's `כֵּן! זוֹ גֶּרֶב.` stays.
6. **D6, the box word (Q7).** Band A `content/units/shapes.json` (SHP-A-07, `shp.solid.*`, 14 rows): `קֻבִּיָּה` → `קֻפְסָה`
   (label, `כֵּן! זוֹ קֻפְסָה.`, `זוֹ קֻפְסָה. … לִלְחֹץ עָלֶיהָ.`). Band B `tools/band_b2.py:171`: for `solid_box` the correct
   text is `כֵּן! זוֹ הַתֵּבָה — כְּמוֹ קֻפְסָה שֶׁל נַעֲלַיִם.` and h3 `הַתֵּבָה דּוֹמָה לְקֻפְסָה שֶׁל נַעֲלַיִם. עַכְשָׁו תּוֹרְכֶם.`
   Voice answers (SHP-B-08, 09): the matcher accepts `קופסה` (and `קופסא`) as right for `תיבה`, and the recast says
   `נָכוֹן, תֵּבָה` (curriculum §8.1). The design-director draws a shoe-box cuboid and a separate cube (audit F9).
7. **D7, numbers alone are feminine (Q8).** Use `F[...]` for a number that is not followed by its noun, and say the noun
   again when a story hint named it: `tools/author.py:807–808` (Band A `math.add.*`), `:902–917` (`math.take.*`, the
   `num_g(...)` inside sums and the "in the basket" hint), `tools/band_b.py:249–253` (NUM-B-11 `עוֹד אַחַת`, `קְחוּ אַחַת`,
   `אַחַת פָּחוֹת`), `:282–283` (NUM-B-14 `num_for` in the sum and in `הִכְנַסְנוּ… נִשְׁאֲרוּ…`), MATH-B-01, 02 and 10 (the
   `h3` sums), `tools/band_b2.py:208, 289` (LOG-B-01 `סֵדֶר שֶׁל שְׁלוֹשָׁה דְּבָרִים`), `content/units/math.json:861` (title
   `עוֹד אַחַת, עוֹד שְׁתַּיִם`), `content/units/counting-hills.json` (`count.butterflies.*` correct `שָׁלוֹשׁ!`, and
   `give.butterflies.4` `אַרְבַּע! נְתַתֶּם בְּדִיּוּק אַרְבַּע.`), hero-son `give.butterflies.4` band C. 108 rows.
8. **D8, shop hints (Q11).** `tools/band_b3.py:136–139` MATH-B-17 `h3`: the coins of `sol`, biggest first, each as
   `מַטְבֵּעַ שֶׁל <value>` (`שֶׁקֶל`, `שְׁנֵי שְׁקָלִים`, `חֲמִשָּׁה שְׁקָלִים`, `עֲשָׂרָה שְׁקָלִים`), joined with `,` and `וּ` (a repeated
   coin `וְעוֹד מַטְבֵּעַ שֶׁל…`), then `— בְּיַחַד <price> שְׁקָלִים. עַכְשָׁו תּוֹרְכֶם.`; one coin: `מַטְבֵּעַ אֶחָד שֶׁל <value>.`
   Hint 2 stays. Also G12 `הַ-וִי` → `הַוִּי` in the prompt (`:138`).
9. **D9, speed language (B-13, design audit F3).** `tools/author.py:260` and the flash alt texts: `הִסְתַּכְּלוּ מַהֵר!` →
   `הִסְתַּכְּלוּ טוֹב…` (alt text `הִסְתַּכְּלוּ טוֹב.`). 24 rows.
10. **D10, Band A robot hints (B-13, audit F13).** `tools/author.py:612` for `cs.robot.direct.*` and `cs.robot.plan.*`
    (Band A only): group the steps; sideways steps `N צְעָדִים לְכִוּוּן הַדֶּגֶל`, up and down as they are, joined by
    `, וְאָז`; `צַעַד אֶחָד` for one (the script's `robot_landmarks()`). 12 rows. Band B keeps `יָמִינָה / שְׂמֹאלָה`.
11. **D11, Band A "not" questions (B-13, audit F13)** (owner-approved 2026-10-29): `content/units/robots.json:195, 211, 403, 419,
    579, 595` `מָה לֹא שַׁיָּךְ?` → `מָה הִגִּיעַ לְכָאן בְּטָעוּת?`; `content/units/shapes.json:684, 1383` `מָה לֹא מִתְגַּלְגֵּל?` →
    `מַה נִּשְׁאָר עוֹמֵד בַּמָּקוֹם?` (the alt texts too).
12. **D12, the balance sides (B-13, audit F8)** *(owner, design)*: `tools/band_b.py:492` and the MATH-B-13 `h3`:
    `הַצַּד הַיְמָנִי` → `הַצַּד שֶׁלְּמַעְלָה`, `הַצַּד הַשְּׂמָאלִי` → `הַצַּד שֶׁלְּמַטָּה`, only if the picture tilts.
13. **D13, core line (Q4, owner-approved option A)**: `content/lines/core.he.json` `core.encourage.checked` =
    `בְּדַקְתֶּם שׁוּב לִפְנֵי שֶׁעֲנִיתֶם. כָּכָה עוֹשִׂים חוֹקְרִים.`
14. **D14, B-26 strings** (`app/lib/strings/he.dart`, now on `main`): `nitziHomeHi` = `זֶה הַבַּיִת שֶׁלָּנוּ.`;
    `nitziHomeWelcome(NoName)` keep `בְּרוּכִים הַבָּאִים` for every child; `nitziHomeBottleDone` is shown only once the daily
    three-stop plan exists. Done on the merge of 2026-10-30: the `PENDING` entries for `nitziHomeWelcome(NoName)`, `nitziHomeHi`,
    `nitziHomeBottleDone`, `homeBubble` and `homeBubbleNoName` are gone (these rows are decided; `he.dart` already has
    `זֶה הַבַּיִת שֶׁלָּנוּ.`).
15. **D15, the name clip (Q6).** `voice_gen` (or the device) makes the name clip per child and plays it right before the
    shared `מה בבקבוק?` clip; the name clip is cached on the device only (SEC-5), never written to the repo or a pack.
    Security-engineer reviews.
16. **D16, `÷` (Q10).** Any future number-to-words normaliser (H3 (e) of the pronunciation audit) reads `a ÷ b` (and the
    `:` setting) as `a לְחַלֵּק לְb` with the rules of section 3.6.

## 5. Questions for the owner

Answered on 2026-10-29 (the owner's own answers; applied in the table):

1. **Nikud standard:** keep full nikud on the defective spelling; the few plene forms unified. *Applied.*
2. **M-CNT-SIZE:** lines chosen by the item's cue, positive, ending in the strategy. *Applied* (6 rows `text-ready`;
   the 3 NUM-A-11 "same?" rows and 7 NUM-A-07 rows have new drafts, `proposed`, see 13 below).
3. **Missing addend:** count on after a concrete model; the distractor 10 is a note (D3). *Applied* (14 rows).
4. **`core.encourage.checked`:** a shorter, simpler line; you chose option A, `כָּכָה עוֹשִׂים חוֹקְרִים`.
   *Owner-approved.*
5. **`גֶּרֶב`:** feminine. *Applied* (8 rows).
6. **The per-name line:** a name clip joined to the shared clip `מה בבקבוק?`. *Applied* (section 3.5, D15).
7. **Box word:** Band A `קֻפְסָה`, Band B `תֵּבָה` bridged, `קופסה` accepted by voice. *Applied* (D6).
8. **Numbers in sums:** feminine when alone, agreement when the noun is said, never masculine without its noun.
   *Applied* (108 rows; the exceptions are in section 2.2 and question 12).
10. **`÷` aloud:** `לְחַלֵּק לְ`. *Recorded* (section 3.6; no line uses it).
11. **Shop hints:** each coin by its value, then the total; hint 2 stays. *Applied* (9 rows).
B-26: `בְּרוּכִים הַבָּאִים` for every child; `זֶה הַבַּיִת שֶׁלָּנוּ.`; the bottle-done line only once the plan exists. *Applied*
as rules (`nitziHomeHi` is `owner-approved`; the others `text-ready`).

Answered later the same day (2026-10-29):

12. **"By one":** keep the masculine `אֶחָד` where no other number is in the line. *Applied as a rule* (section 2.2).
13. **Approved rows:** the give-N line (22 rows), the two Band A questions without "לֹא" (16 rows, with alt texts) and
    Q4 option A (1 row) are `owner-approved`: 39 rows; with `nitziHomeHi` (B-26, the line he chose) 40, the only ones so far (`OWNER_APPROVED` in the script).

Answered on 2026-10-30 (B-15; the owner's words: "1. I approve. 2. I approve. 3. Use the new one."):

17. **P3, P4, P5 (the sorting-rule lines)** `vo:fb.sort_shift.kind`, `.shape`, `.size`: `owner-approved` in Band A and Band B
    (21 rows). **Applied** (`OWNER_APPROVED`).
18. **Everything in `docs/knowledge/b15-hebrew.md` §7:** the 15 `*-b15` lesson titles and celebration lines (30 rows), the NUM-B-08
    prompt `אֵיזֶה מִסְפָּר חָסֵר?` with its alt texts (4), the NUM-B-18 odd line (2), the fish and star size hints (2), the
    LOG-A-02 hint (2) and the COL-A-05 correct lines `כֵּן! זוֹ בָּנָנָה יְרֻקָּה.` / `כֵּן! זֶה תַּפּוּחַ יָרֹק.` (2):
    `owner-approved`. **Applied.** Not covered, so unchanged: the correct lines of the fish and star items, the COL-A-05 tick
    hint, and the 9 `פַּרְפָּר` rows (§6.7).
19. **P1:** Band A spots with no hint 3 of their own use `כֻּלָּם דּוֹמִים, חוּץ מֵאֶחָד. עַכְשָׁו תּוֹרְכֶם — לִלְחֹץ עָלָיו.`
    (one shared clip, `vo:hint.spot_but_one.h3`) instead of `אֶחָד מֵהֶם לֹא מַתְאִים…`; 12 items; `owner-approved`. Band B keeps
    the old line. In `tools/author.py` (`SPOT_H3_A`, `k_spot`). One case to know: in `b15.loga01.6` the odd cell is a bird in a row of
    ducks (a feminine noun); the hint stays masculine (`אֶחָד`, `עָלָיו`) because it points at "one of the cells", as the old line did.
    The V1 prompts, the Q2 drafts and D12 stay `proposed`: the owner will decide them together with the voicing.

Still open:

9. **Alert word lists** (group 5): the spelling is right; whether the lists are complete needs someone who works with
   children. Left `unchanged` (your answer of 2026-10-29: leave it open).
15. **Drafts you have not seen yet** (rows `proposed`, in `docs/review/owner-sample.md`): the NUM-A-11 pairing line (3
   rows) and the NUM-A-07 counting line (7), and the balance sides (12, also needs the design-director).
16. **The 100 V1 rows** of the pronunciation audit (homographs kept pointed) still wait (audit question 1).

## 6. For the voice-and-sound-director

- **Update, 2026-10-30 (after the owner's B-15 answers):** the master table has 12,629 rows: 115 `owner-approved` (the 40 above plus 75: P1, P3 to P5, the 15 lessons and the §7 lines, see §5 items 17 to 19), 11,698 `text-ready`, 167 `proposed`, 649 `unchanged`. The numbers in the next bullet are of the earlier date.
- Status now (2026-10-30, after the merge with `main`): 40 rows `owner-approved` (the give-N line, the two Band A questions,
  `core.encourage.checked`, `nitziHomeHi`): these are ready for your direction. 9,383 rows are `text-ready` (final text,
  waiting for the owner's approval); 128 are
  `proposed` (100 V1 pronunciation rows, 10 Q2 drafts, 12 balance drafts, 6 B-26 strings in `PENDING`) and must not be voiced.
- Rows changed on 2026-10-29 that are spoken and `text-ready` need (re)voicing from `voice_text`: the sums and answers
  made feminine (Q8), the 6 size lines (now three different clips instead of one `vo:fb.size`), the 14 missing-addend
  hints (new per-item clips for hint 2), the 9 shop hints, the 12 robot hints, the 12 flash prompts, the bridged box lines,
  the sock lines and the per-name shared clip `מה בבקבוק?`.
- Number words carry nikud on purpose (gender and stress); do not strip it. `שֵׁנִי`, `הַוִּי`, `נְחַתֶּם` are pointed for the
  same reason.
- **The per-name line (Q6):** two clips, the name and `מה בבקבוק?`. Please direct the name clip as a call (a short rise, a
  small pause after it), so the join sounds like one sentence; never a name alone in any other line.
- **The new long lines:** the three-coin shop hints (up to 19 words, e.g. `מטבע של חֲמִשָּׁה שקלים, מטבע של שְׁנֵי שקלים ועוד
  מטבע של שְׁנֵי שקלים — ביחד תִּשְׁעָה שקלים. עכשיו תורכם.`) and the count-on hints (`שֵׁשׁ… וממשיכים: שֶׁבַע, שְׁמוֹנֶה,
  תֵּשַׁע, עֶשֶׂר. הרמנו אַרְבַּע אצבעות.`). If they come out rushed, ask and I change the punctuation, never the words.
- The long number lists (up to ten numbers: `אַחַת, שְׁתַּיִם, … עֶשֶׂר.`) and the robot step lists are the lines most likely to
  be rushed; the commas are the breaths. If you need a slower cadence, ask and I change the punctuation (`…` between
  numbers), never the words.
- A number answer at the start of a correct-feedback line is followed by a full stop on purpose (it is the answer, said
  alone, then the reason).
- The blank in the colour-mixing prompts is said as `ועוד צבע…`; the program lines as `לחזור על הצעדים:`.
- 767 activities share `כמעט, בואו ננסה שוב.` and 767 share `שאלה טובה, בואו נראה יחד.`; voice each once.

## 7. B-40: the hint lines follow the hint pictures (hebrew-text-editor, 2026-10-31)

**What was done.** The generators now write the Band A `tap_answer` hint lines from what the picture of the family shows
(`tools/hint_lines.py`, called by `activity()` in `tools/author.py`; the family and the fall-backs mirror
`app/lib/play/hints/tap_plans.dart`, so a line follows the picture even where the plan falls back to a generic card).
466 lines changed in 290 activity files (L1 36, L2 279, L3 151); every one is `proposed` in the master table (`PENDING`
in `tools/hebrew_voice_review.py`, comment "B-40") and the activity stays `"review": "needs-editor"`. Band B is untouched.

**The rules (for whoever adds a family or a picture).**
1. Level 1 never counts aloud (design spec F2). A sequence says where to look ("the number, and the empty place next to
   it"); the 13 old lines that counted `אַחַת, שְׁתַּיִם…` are gone. A line that only replays the question stays.
2. Level 2 says what the new picture is, in one short line shared by the whole family (one clip for 53 colour items).
   A number is said only where the picture counts it (hands, hops, numbered places, the path to N). The hands lines say
   `אֶצְבָּעוֹת` only where hands are drawn; the path, the empty frame, the brackets and the pairing lines have their own.
3. Level 3 may name the answer, because the plan (section 1, T2) lets the answer be the LAST step of the demonstration. What
   the plan does not allow is a line that opens with the bare answer (`זֶה כַּדּוּר אָדֹם`) while the hand has not moved.
   So: a bare answer (four words or fewer before `עַכְשָׁו`) gets one process clause in front (`הַצֶּבַע עוֹבֵר עַל כֻּלָּם,
   וְעוֹצֵר אֵצֶל הַמַּתְאִים.` for the swatch, the same for the outline, the model and the hand); a line that already is a
   process (it counts, reads the row, walks the story, compares) is kept; the owner-approved lines (matha04, loga02, the
   spot line) are untouched.
4. Compare: L1 (off the stage) says the two groups stand in two rows; L2 says the pairing lines and asks who is left
   without a pair; L3 pairs one to one, counts what is left and says where there is more (the old line gave both numbers).
5. The ordinal L3 starts from the flag and says the places up to the answer; zero keeps its line; the hops (CS-A-04) and
   the coins (MATH-A-06) count in time with the hand.

**Words chosen (please check, owner).** `הִנֵּה רַק הַצֶּבַע` / `רַק הַצּוּרָה, בְּלִי צֶבַע` (the attribute on its own);
`הַדּוּגְמָה` (the model); `מְחַפְּשִׂים זוּג לַתְּמוּנָה הַזֹּאת` (LOG-A-09); `הַמִּשְׁבְּצוֹת רֵיקוֹת` (the empty ten-frame);
`אֵיפֹה הַבַּרְוָז? …` (SHP-A-08: the picture draws a small duck, so the line says duck and not the ball of the question);
`נִרְאֶה מַה קּוֹרֶה כְּשֶׁדּוֹחֲפִים אֶת שְׁנֵיהֶם` / `…כְּשֶׁשָּׂמִים עוֹד אֶחָד מֵעַל כָּל אֶחָד` (SHP-A-07: watch what
happens, the result is not said). `כׇּל` is written with a qamats qatan, as everywhere in the pack.

**Not changed, and why.** MATH-A-04 heavy/light (2): the picture is still a question-mark card until the seesaw exists, so
the generic line stays. COL-A-05 tick/cross items (2): their L3 `כֵּן…` stays (the swatch tour over a tick and a cross
says nothing). `pick.red.flower` has one hint only. The other Band A templates (count, give, flash, sort, build, match,
shape builder, robot, spot the mistake, trace) keep their lines: they still agree with their pictures except as listed in
the report to the orchestrator.
