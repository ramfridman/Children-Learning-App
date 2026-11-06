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

## 7. B-39: what the bottle says when it is tapped (2026-10-31, hebrew-text-editor; all `proposed`)

The intents are in `docs/curriculum/todays-adventure-rule.md` section 8. Five lines in `app/lib/strings/he.dart`, one per
reason (`nothing` has no line), each with a screen-reader label. All are "we" and "let us" lines: no child name, no friend
name, no first person singular or second person singular (the friends differ in gender), no time word, nothing the child
did or did not do.

| Reason | `he.dart` id | Screen | Voice text (`{land}` = the land's voice name) | Screen-reader label (`...Semantics`) |
|---|---|---|---|---|
| welcome | `adventureWelcome` | `בּוֹאוּ נֵצֵא לְהַרְפַּתְקָה אֶל {land}.` | `בואו נֵצֵא להרפתקה אל {land}.` | `הבקבוק: הרפתקה אל {land}` |
| callForHelp | `adventureCallForHelp` | `מַשֶּׁהוּ שֶׁל {land} צָרִיךְ עֶזְרָה. בּוֹאוּ נַעֲזֹר.` | `משהו של {land} צריך עזרה. בואו נעזור.` | `הבקבוק: משהו של {land} צריך עזרה` |
| sameLand | `adventureSameLand` | `בּוֹאוּ נַמְשִׁיךְ בַּהַרְפַּתְקָה שֶׁל {land}.` | `בואו נמשיך בהרפתקה של {land}.` | `הבקבוק: להמשיך בהרפתקה של {land}` |
| otherLand | `adventureOtherLand` | `בּוֹאוּ נְבַקֵּר אֶת {land}.` | `בואו נְבַקֵּר את {land}.` | `הבקבוק: לבקר את {land}` |
| playAgain | `adventurePlayAgain` | `בּוֹאוּ נְשַׂחֵק שׁוּב מִשְׂחָק שֶׁאֲנַחְנוּ מַכִּירִים.` | `בואו נשחק שוב משחק שאנחנו מכירים.` | `הבקבוק: לשחק שוב משחק שאנחנו מכירים` |

**How `{land}` is filled.** The screen line gets the land's own pointed name (`He.landCounting` .. `He.landMarket`, as the map
sign shows it) by `Str.fill({'land': ...})`. The screen-reader label gets the plain name from six new strings
`landCountingSemantics`, `landColorsSemantics`, `landShapesSemantics`, `landLogicSemantics`, `landRobotsSemantics`,
`landMarketSemantics` (no nikud is ever added or removed at runtime). The voice line is voiced once for each land.
Voice names: `גבעות הספירה`, `מפרץ הצבעים`, `יַעַר הצורות`, `מְעָרַת החידות`, `נְמַל הרובוטים`, `כְּפַר השוק` (the four pointed words
are the ones a voice can misread; the voice director confirms them). `{land}` is not a person's name, so it is not dropped
like `{child}`.

**Why no prefix letter before `{land}`.** The names are constructs of different gender and first letter, so `לְ` / `בְּ` / `מִ`
would need a different pointing for each (`לְגִבְעוֹת`, `לְמִפְרַץ`, `לְיַעַר`, but `לִמְעָרַת`, `לִנְמַל`, `לִכְפַר`). A separate word
keeps the name exactly as authored: `אֶל`, `אֶת` (the name is definite through its second noun, so `אֶת` is right) and `שֶׁל`
(the same pattern as `הָאִי שֶׁל {child}`). In `מַשֶּׁהוּ שֶׁל {land} צָרִיךְ` the subject is `מַשֶּׁהוּ` (masculine singular), so
no verb or adjective agrees with a land of another gender or number (`גִּבְעוֹת` is feminine plural).

**callForHelp** speaks of the land's object ("something of the Counting Hills needs help"), never of the child, and
asks for no answer; it is the map's own framing. It is generic (no per-land object such as the bridge board): a line per
land would be six more texts and needs the object names from the design.

**Open for the owner.** (1) `אֶל` is a little more formal than the spoken `לְ`; it is the price of a safe single `{land}`.
If he prefers `בּוֹאוּ נֵלֵךְ לְ…`, six pointed "to"-forms of the land names are needed (`לְגִבְעוֹת הַסְּפִירָה`, `לְמִפְרַץ הַצְּבָעִים`,
`לְיַעַר הַצּוּרוֹת`, `לִמְעָרַת הַחִידוֹת`, `לִנְמַל הָרוֹבּוֹטִים`, `לִכְפַר הַשּׁוּק`). (2) `adventurePlayAgain` names no land by design
(the intent has none); the rule's replay has a land, so a variant with `{land}` is possible. (3) Whether the bottle's
screen-reader label should say the stop before the tap (it is computed when the home is built; the tap can pick another stop
if a check fell due meanwhile, rule section 6).
Wording guard for QA: none of the ten strings contains `היום`, `עוד לא`, `כבר`, `שוב` as "again after a pause", a count or `{n}`;
`שוב` in `adventurePlayAgain` is "play a known game once more", which the intent asks for.

## 8. The Hebrew course (Languages category): the editor's pass, 2026-11-03

Scope: the hebrew-language-teacher's drafts in `docs/languages/hebrew/syllabus.md` (§3 word lists S1 to S12, the examples in §2 and §6), `docs/languages/hebrew/voice-brief.md` (§1 to §5: letter names, vowel names, stress, pilot clips), the one Hebrew line of `docs/languages/russian/syllabus.md` §8, and the Hebrew in `docs/research/hebrew-course-2026-11-03.md`. The owner approved the course on 2026-11-03 (`docs/languages/decisions-2026-11-03.md`). Nothing was voiced or paid. The corrected text is **edited in those files directly**; the status of every item is `text-ready` (waiting for the owner) unless 8.7 says otherwise.

### 8.1 What was checked, and how

| What | Count | How |
|---|---|---|
| Decodable words, S1 to S8 | 143 words (after the changes; 138 before) and 13 CV units | every word read for nikud, stress, spelling and fit for a child, then **machine-checked** by `tools/check_hebrew_course_words.py` (new): for each word it finds the first step whose letters and signs are enough to read it; none needs a later step than its own; every word is in canonical (NFC) order; no final form in the middle of a word, no ש without a dot |
| S9 (long words, prefixes, endings, "same tune"), S10 (frequent words), S12 (unpointed and full spelling) | 19 + 17 + 17 words | read by hand, one by one (the script lists them); S11 is not written yet |
| Letter names | 22 letters, 27 forms with the 5 finals (26 rows in the voice brief) | spelling, nikud, stress, how a child decodes the pointed name, the Academy and reference works (8.3) |
| Vowel signs | 9 names and 3 hataf names | spelling and stress |
| Examples in the syllabus §2, §4, §5, §6 and in the research file | about 60 | one by one (syllabification, prepositions, agreement, vav before ב, dagesh) |
| Pilot clip texts in the voice brief §5 | about 30 | read; the voice director's own pilot files (`pilot*.json`) were only looked at, see 8.7 |

Re-run: `python -I tools/check_hebrew_course_words.py` (the default path is the syllabus). Its rules are in its docstring (the same as the syllabus §3: ב כ פ with a dagesh are S1/S4/S6, without it S7; שׂ ך ף S7; a final ָה S1 and a final ֶה S6; a shva on the first letter or a hataf S8; a silent shva S3; a patah gnuva S7; a silent א inside a word S7). It reports `כִּסֵּא` (S7) as readable from S6, which is deliberate: the word shows the final silent א after e.

**The pointing standard of the course** is the app's (§2.4): the Academy's spelling for pointed text. Holam is a vav when the Academy writes one (שָׁלוֹם, גָּדוֹל, אוֹר) and a bare holam when it does not (וָרֹד, רֹאשׁ, זֹאת, לֹא); hiriq has a yod in a long, open syllable (שִׁירָה, פִּיל, תִּירָס) and none in a closed or doubled one (מִדְבָּר, אִמָּא, כִּנּוֹר, בִּנְיָן); u is וּ or ֻ as the word has it (סוּס, שֻׁלְחָן, קֻפְסָה). The course teaches both forms of each vowel, so no word needs "correcting" to one spelling. No word needs a qamats qatan (U+05C7).

### 8.2 Every change

| # | File | Was | Now | Why |
|---|---|---|---|---|
| 1 | syllabus S6 | `טִיל` | `טִיל` (kept) | REVERTED by the owner (2026-11-03): "This is not correct. Leave the טיל word." `טִיל` stays in S6. Do not remove everyday words such as טִיל from children's word lists for being war-related unless the owner asks. |
| 2 | syllabus S7 | `שַׂמְלָה` | `שִׂמְלָה` | the word is `שִׂמְלָה` (hiriq), stress on the last syllable (Wiktionary: sim-LA); the patah form is Biblical |
| 3 | syllabus S9 | `חַיְּכָן` | `שַׂחְקָן` | `חַיְּכָן` is rare and has a yod with dagesh and shva, a trap for a child decoding; `שַׂחְקָן` (player, actor) is the same pattern (קַטְלָן), common and positive, and uses S5 to S7 letters. The line "מִי שֶׁמְּשַׂחֵק הוּא שַׂחְקָן" works like "מִי שֶׁרוֹקֵד הוּא רַקְדָן" |
| 4 | syllabus S3 | 4 words | 8 words: added `תַּרְמִיל`, `סַנְדָּל`, `בִּנְיָן`, `לַיְלָה` | settles the "only 4 picturable words" question (8.3). Checked: only S1 and S2 letters, a and i, a silent shva |
| 5 | syllabus S8 to S6 | `אַרְיֵה` in S8 | in S6 | it needs only the e signs and a silent shva; no hataf and no initial shva |
| 6 | syllabus S8 | (no hataf-segol word) | `אֱמֶת` added | the step teaches ֲ ֱ ֳ but had no ֱ word; `אֱמֶת` [ˈemet], known from `בֶּאֱמֶת`; a decoding word, no picture |
| 7 | syllabus §2 | `חֻל–צָה` | `חֻלְ–צָה` | the silent shva is written in a syllable split, as in `יַלְ–דָּה` |
| 8 | syllabus S7 | "silent א at the end (כִּסֵּא) and inside (רֹאשׁ)" | the final one is "the same as the final א of S1"; only the inside one is new | the syllabus's own note says a final silent א is read from S1 |
| 9 | syllabus S12 | "helping nikud set by the editor" | `שולחן`, `חתול` need none; `ציפּור`, `כּיסא`, `תפּוח` carry the dot | the rule is in 8.5 |
| 10 | voice brief §2 | `יוֹד`, `קוֹף` | `יוּד`, `קוּף` | 8.3 |
| 11 | voice brief §2 | ב: `וֵית`; כ ך: `כַף`; פ ף: `פֵא` | ב: `בֵּית` (one name); כ ך: `כַּף`, `כַּף סוֹפִית`; פ ף: `פֵּא`, `פֵּא סוֹפִית` | one letter has one name; a name without its dagesh (`כַף`, `פֵא`) is not how it is said or written; `וֵית` starts with the letter ו and would teach the wrong letter |
| 12 | voice brief §3 | `קָמַץ` (twice) | `קָמָץ` | `קָמַץ` with patah is the verb "he clenched"; the sign is `קָמָץ` (Wiktionary: ka-MATS) |
| 13 | voice brief §1.8 | "זוֹ גִּימֶל. הִיא אוֹמֶרֶת גְּ… כְּמוֹ בְּגִיר" | "זוֹ גִּימֶל. הִיא אוֹמֶרֶת גָּ, כְּמוֹ בַּמִּלָּה גָּמָל." | the draft said a bare stop (the brief itself forbids it) and `כְּמוֹ בְּגִיר` means "like in chalk" |
| 14 | voice brief §4 | a short stress guess | the full stress list (8.4) | `צְפַרְדֵּעַ` was listed as last-syllable and is stressed on `דֵּ`; the patah gnuva words, `לַיְלָה`, `בַּיִת`, `בַּבַּיִת`, `אֵיפֹה` were missing; `לָמָּה` decided |
| 15 | voice brief §5 | pilot names `יוֹד`, `קוֹף` | `יוּד`, `קוּף` | follows 10 |
| 16 | research | `ִפּי/צָה` (twice), `שִ`, `ילְ–דָּה` | `פִּי/צָה`, `שִׁ`, `יַלְ–דָּה` | a stray hiriq before the letter; a shin without its dot; a missing patah |
| 17 | russian syllabus §8 | `נַגִּיד יַחַד` | `בּוֹאוּ נֹאמַר יַחַד.` | 8.8 |

### 8.3 The teacher's open questions, settled

1. **`יוֹד` or `יוּד`: `יוּד`.** Both are right (the Hebrew Mihlol writes `יוֹד/יוּד`; English Wikipedia lists /jud/ and /jod/). A child decodes the pointed name she sees on screen, and the voice says it, so the written and the spoken name must be the same; the form children say is `יוּד`. I could not find a source that counts which is commoner, so this rests on the teacher's note and mine. **Needs the owner's ear (8.7, question 1).**
2. **`קוֹף` or `קוּף`: `קוּף`.** Both are right (`קוֹף/קוּף` in the Hebrew Mihlol). The decisive reason is the course itself: `קוֹף` is the word "monkey" in S7, a picture word. A child who learnt the letter as קוֹף and then sees the written word קוֹף must not hear one thing for two. `קוּף` for the letter keeps them apart. The parent area may write either; unpointed it is `קוף` in both.
3. **`וָו` or `וָיו`: `וָו`.** It is the Academy's name and the way it is said ([vav]). `וָיו` is the traditional name, and a child who decodes it reads `va-yo`. `וָו` decodes to exactly [vav] with the consonant ו that S4 teaches. In the parent area the unpointed `וו` can look like two letters, so the parent text writes `ו (וָו)` once.
4. **The stress of `לָמָּה`: la-MÁ (last syllable).** The Hebrew Wiktionary gives la-MA; that is how Israeli children say it. The teacher's "LÁ-ma in speech" is not right, and there is no spoken exception. Same in a question ("לָמָּה?") and in a sentence.
5. **S3 (silent shva) with only 4 words: keep it as its own short step, with 8 words.** Four more words use only S1 and S2 letters: `תַּרְמִיל`, `סַנְדָּל`, `בִּנְיָן`, `לַיְלָה`. The step is not merged into S4: S4 already brings four letters and a new vowel, and a silent shva needs a calm step of its own. It then comes back in S5 to S8 words (`שֻׁלְחָן`, `אֶצְבַּע`, `שִׂמְלָה`, `סַבְתָּא`, `קֻפְסָה`, `צְפַרְדֵּעַ`), which the activities use as review. Not used: `אַדְמָה` (the word is `אֲדָמָה`, with a hataf, three syllables).

Two more choices the teacher left open: the names are the same for the hard and the soft sound (one `בֵּית`, one `כַּף`, one `פֵּא`; the sound is taught by the dot, not by a second name), and the final forms are "the name + `סוֹפִית`" (`כַּף סוֹפִית`, `מֵם סוֹפִית`, `נוּן סוֹפִית`, `פֵּא סוֹפִית`, `צָדִי סוֹפִית`).

### 8.4 For the voice director: stress, shva, and what is sent

The full stress list is in `voice-brief.md` §4. In short: **all words are stressed on the last syllable except** the segolate-like nouns (`יֶלֶד`, `לֶחֶם`, `גֶּשֶׁם`, `שֶׁמֶשׁ`, `דֶּלֶת`, `סֵפֶר`, `כֶּלֶב`, `מֶלֶךְ`, `מֶלַח`, `אֶצְבַּע`, `אֱמֶת`, `טַבַּעַת`), `אַבָּא`, `אִמָּא`, `סָבָא`, `סַבְתָּא`, `דֻּבִּי`, `בֻּבָּה`, `פִּיצָה`, `לַיְלָה`, `בַּיִת`, `אֵיפֹה`, the patah gnuva words (on the vowel before it), the dual (`עֵינַיִם`, `אוֹפַנַּיִם`, `מִשְׁקָפַיִם`) and a prefix + such a word (`הַכֶּלֶב`, `בַּבַּיִת`). `אֵיפֹה` is said [ˈejfo], the accepted spoken form (the Academy's standard is [eˈfo]; Wiktionary lists both). `טַבַּעַת` is [taˈbaʔat] (Wiktionary).

**Shva in the words of S8 and S9** (the spoken form; the shva is never a full vowel):

| Word | Said | Note |
|---|---|---|
| גְּלִידָה, שְׂמִיכָה, סְפָרִים, כְּלָבִים, פְּרָחִים, בְּרָכָה, צְפַרְדֵּעַ, סְפָרָיו | [gliˈda], [smiˈχa], [sfaˈrim], [klaˈvim], [praˈχim], [braˈχa], [tsfarˈdeʔa], [sfaˈrav] | the first shva is silent: two consonants in a row |
| יְלָדִים, יְלָדוֹת | [jelaˈdim], [jelaˈdot] | the shva after י is said [e] |
| וְהֶחָתוּל | [vehexaˈtul] | the shva of the prefix וְ is said [e] |
| תַּרְנְגוֹל | [tarneˈgol] | the first shva is silent (it closes the syllable), the second is said [e]: a good S9 trap |
| עַגְבָנִיָּה | [agvaniˈja] | the ב has no dot and is [v] even after a silent shva, because the word follows the pattern קַטְלָן (Wiktionary). This matches the S7 rule "no dot, soft" |
| מִשְׁקָפַיִם | [miʃkaˈfajim] | the shva under שׁ is silent |
| חֲמוֹר, אֲנִי, עֲנָנִים, חֲתוּלָה, אֱמֶת, אֳנִיָּה | [χaˈmor], [aˈni], [ʔanaˈnim], [χatuˈla], [ˈemet], [oniˈja] | a hataf sounds like its full vowel |

**What is sent to the voice.** Single-word and CV clips are sent **pointed** in the pilot (the pilot decides whether the model reads pointed input better; until it answers, the editor does not strip the nikud). The marks U+05C7 and U+05B3 are never sent: `אֳנִיָּה` goes as **`אונייה`** (full spelling, the Academy's form); nothing else in the lists needs it. The letter names are sent pointed (`יוּד`, `קוּף`, `וָו`, `גִּימֶל`, `צָדִי`, `זַיִן`). `מָה` and `לָמָּה` keep their forms; `מַה` + dagesh before a non-guttural is the rule for the sentences of S10 and S11 (`מַה זֶּה?`).

### 8.5 Helping nikud (`ניקוד עזר`) for S12

Rule: in a full-spelling word (ktiv male), help only where the unpointed letters allow a **wrong sound the child has met**: the dot that makes **ב, כ or פ hard** ([b], [k], [p]; also when it is a dagesh chazak), and the **dot of שׂ**. A shin needs no dot (it is the default), and no vowel sign is added (the full spelling carries the vowels). So `שולחן` and `חתול` need nothing; `ציפּור` (the פ is [p]), `כּיסא` (the כ is [k]) and `תפּוח` (the פ is [p]) carry the dot. Kept short on purpose: the aim is to take the help away, step by step.

### 8.6 Hebrew shape cues for the re-teach (syllabus §5), `text-ready` as words

Said by the voice and shown, one short passage per pair. Letters are feminine (`אוֹת`), so `זוֹ` and `הִיא`; no left or right; no preposition is put on a letter name (it would change the dot).

| Tag | Cue (to be re-read against the design-director's letters) |
|---|---|
| M-HEB-SHAPE-BK | זוֹ בֵּית — יֵשׁ לָהּ פִּנּוֹת וְרֶגֶל קְטַנָּה. וְזוֹ כַּף — הִיא עֲגֻלָּה. |
| M-HEB-SHAPE-DR | זוֹ דָּלֶת — יֵשׁ לָהּ פִּנָּה. וְזוֹ רֵישׁ — הִיא עֲגֻלָּה. כַּף סוֹפִית יוֹרֶדֶת מִתַּחַת לַשּׁוּרָה. |
| M-HEB-SHAPE-HXT | זוֹ הֵא — יֵשׁ לָהּ חוֹר קָטָן. זוֹ חֵית — הִיא סְגוּרָה לְמַעְלָה. וְזוֹ תָּו — יֵשׁ לָהּ רֶגֶל קְטַנָּה. |
| M-HEB-SHAPE-VZN | זוֹ זַיִן — יֵשׁ לָהּ כּוֹבַע. וְזוֹ וָו — הִיא קַו יָשָׁר. נוּן סוֹפִית יוֹרֶדֶת מִתַּחַת לַשּׁוּרָה. וְיוּד — הִיא קְטַנָּה. (waits for the owner's answer on `זַיִן`, 8.7) |
| M-HEB-SHAPE-SM | זוֹ סָמֶךְ — הִיא עֲגֻלָּה. וְזוֹ מֵם סוֹפִית — יֵשׁ לָהּ פִּנּוֹת, וְהִיא רַק בְּסוֹף מִלָּה. |
| M-HEB-MIRROR | הַפֶּתַח שֶׁל הָאוֹת פּוֹנֶה לְאָן שֶׁהַקְּרִיאָה נִמְשֶׁכֶת. |
| M-HEB-NAMESOUND | הַשֵּׁם הוּא גִּימֶל, וְהַצְּלִיל הוּא גָּ. |

Not written: cues for ע/צ, ג/נ and ט/מ. A verbal description of a letter that does not match the drawn letter would teach the wrong shape; their re-teach stays "trace both" until the letterforms are fixed.

### 8.7 For the owner, and for the other agents

**For the owner (numbered):**
1. **Letter names `יוּד` and `קוּף`** (and `וָו`, and one name for the hard and the soft ב כ פ). I chose the spoken forms for the reasons in 8.3. You are the native listener: if your children say `יוֹד` or `קוֹף` at gan, tell me; it is a small change (`voice-brief.md` §2 rows י and ק, §5 pilot).
2. **The name of ז, `זַיִן`.** It is the Academy's name and what every gan says, but it is also a slang word that older children know. Options: (a) keep `זַיִן` (my recommendation: the name is standard, and a gan child expects it); (b) teach ז by its sound and a picture and say the name only in the parent text. Rows: voice brief §2 (ז), 8.6 (M-HEB-SHAPE-VZN).
3. **Confirm the changed and added words:** `תַּרְמִיל`, `סַנְדָּל`, `בִּנְיָן`, `לַיְלָה` (S3), `אֱמֶת` (S8), `שַׂחְקָן` (instead of `חַיְּכָן`). `טִיל` was dropped on child-safety grounds; if you want other words of war or fear kept out of the lists, say so.

**For the hebrew-language-teacher:**
- Words for decoding only, not for a picture choice: `נָם` (literary, from lullabies), `מַר` (bitter, rare in speech), `שָׁמַר`, `סוֹד`, `כִּי`, `לוֹ`, `הִיא`, `הוּא`, `זֵר` and `עֵט` (low frequency; kept because the schools teach them), `תָּמָר` (a name; as a picture a girl or a date, to be decided in the picture list), `שָׁר` (picture: someone singing; its pair is `שָׂר`, minister, an adult word). `קוּם` is a command to one boy; if it ever goes in a sentence to the children it is `קוּמוּ`.
- The research file line 248 still lists `חַיְּכָן`; I changed only the typos of the research record (item 16).
- The paragraph of the Russian syllabus around the Hebrew line (§8) still says the recogniser is Hebrew only; the owner's decision 1 of 2026-11-03 changed that. It is the Russian teacher's text, not changed here.

**For the voice-and-sound-director** (the untracked `docs/languages/hebrew/pilot*.json`, not edited by me): the letter-name clips must be `יוּד` and `קוּף` (they have `יוֹד`, `קוֹף`); the pair `כֶּלֶב / חֶלֶב` is a test of sounds only (`חֶלֶב` means "fat"; the milk of S7 is `חָלָב`); `אמרו` should be pointed `אִמְרוּ` (as in `VOICE_AUDIT_KEEP`; unpointed it can be read `אָמְרוּ`, "they said"); `נשחק בהן` is a little formal, `נשחק במילים` is plainer.

**For the design-director:** the shape cues in 8.6 need the letterforms before they are final.

### 8.8 The Russian course's Hebrew line

The draft `נַגִּיד יַחַד` is correct Hebrew (`נַגִּיד`: first person plural of `הִגִּיד`; `יַחַד`: together), but as two words without an opener it reads like the idiom `נגיד` ("let us say, for instance"), and the app's invitations all begin with `בּוֹאוּ`. Final: **`בּוֹאוּ נֹאמַר יַחַד.`** on screen (the same form as `feedback.incorrect.0.caption.0.v`), voice text **`בואו נגיד יחד.`** (rule 3.4 of this file: `בואו נאמר` becomes `בואו נגיד`). Plural, no gender, no question. Status `text-ready`. Note for the voice director: unpointed `נגיד` can be read as the noun `נָגִיד` (a governor); the sentence makes the verb clear, and the existing lines with `נגיד` already work that way.

## 9. The three Band A batches (English, Hebrew, Russian): the editor's pass, 2026-11-03

Scope: the Hebrew in `docs/languages/english/band-a-content.md` §2 (51 frame lines, 68 glosses), `docs/languages/hebrew/band-a-content.md` with `pronunciation.csv` (218 `needs-editor` rows, the 3 parent co-play cards, the 52 names, and the B-12 example in `syllabus.md`), and `docs/languages/russian/band-a-content.md` §2 and §3 (F01 to F39, 13 tags with a `parentText` and a `homeActivity`), the two letter-name lines of the Russian `syllabus.md` §3.1 and its §8 `שמעתי:`. The owner approved the three courses in principle on 2026-11-03. All items are now `text-ready`, waiting for the owner. Edited in those files directly (the tables carry the final Hebrew, the voice text and, for the lines I changed, the reason). Nothing was voiced or paid. Two owner notes were applied: the app is for any child at any level, and an ordinary word is never removed as unsuitable (טִיל stays; no word was removed from any list).

### 9.1 The rule for all three courses: how the teaching voice speaks to the child, and the voice's own gender

**Decision (hebrew-text-editor, for the owner's OK).**
1. **The recorded course voice does not follow the child's address form.** Every Hebrew line a course voice says is plural or neutral, whatever the profile says: the plural imperative (`גְּעוּ`, `הַקְשִׁיבוּ`), "let's" (`בּוֹאוּ נִסְפֹּר`), the impersonal present (`הוֹלְכִים עִם הָאֶצְבַּע`), the infinitive, and the past plural for praise (`מְצָאתֶם`, `שְׁמַעְתֶּם טוֹב`). The possessive is plural too (`הַשֵּׁם שֶׁלָּכֶם`). One clip per line, not three.
2. **The voice has no gender in its lines.** No present or adjective in the first person that has a gender (`אֲנִי קוֹרֵאת`, `אֲנִי שָׂמֵחַ`). A first-person past verb is allowed because its form is the same for a man and a woman (`שָׁמַעְתִּי`, `אָמַרְתִּי`, `סִיַּמְתִּי`), and so is "let's" (`נֹאמַר`). So any voice can say any line, and the voice director can change or add a voice without any change of the text.
3. **A character is spoken of in the third person only when its gender is fixed in the course.** Nitzi is "she" (`הִיא שָׂמָה קֶמַח`), Kubi the tortoise is "he", the cat of story 1 is "she" (`הַחֲתוּלָה`). For the characters whose gender the art has not fixed (Pip, Mika, the Russian "friend", the English "friend") a line uses the name or `הֶחָבֵר` (the app's word for the companion) and **no pronoun and no verb or adjective about them**: `וְהַרְאוּ לְמִיקָה מַה לַּעֲשׂוֹת` (was "ומיקה יעשה את זה", a masculine verb for Mika), `הַקְשִׁיבוּ לַשְּׁאֵלָה` (was "החבר שואל"), `מִישֶׁהוּ בָּא, אוֹ הוֹלֵךְ?` (was "החבר בא, או הולך?"), `הַקְשִׁיבוּ לַבַּקָּשָׁה, וּתְנוּ לֶחָבֵר אֶת מַה שֶּׁמְּבַקְשִׁים` (was "מה שהוא מבקש"). A gloss or a word card names a word in its dictionary form and says nothing about a person.

**Why.** (a) PLAN.md › Speaking to the child: recorded voice is gender-neutral, and core lines never reveal the speaker's gender; curriculum §9.3 says the same for the praise lines. (b) The only thing in the app that follows the address form is the AI tutor, and it is off in language lessons (`frame.md` §1.6), so nothing in a course has a per-profile form to choose. (c) A per-profile form would need three recordings of every line in every course, for no teaching gain. (d) The three courses then say the same words the same way (`הַקְשִׁיבוּ, וּגְעוּ בַּתְּמוּנָה.` is one line in English and Russian). **What the owner gives up:** a child who plays alone is still addressed as "אתם", like everywhere else in the app.

**Changed because of it:** `frame.md` §1.3 said the address form "follows the child's profile in the Hebrew frame, as everywhere"; it now says the recorded frame is neutral and the profile form belongs to the tutor (one sentence; the curriculum-expert to confirm). The Hebrew course voice's own gender is therefore not decided in the text: the one line that said `אֲנִי קוֹרֵאת` (`i-follow`) became `הַקְשִׁיבוּ לְכׇל מִלָּה, וּגְעוּ בָּהּ.`

Not covered by the rule: parent texts (adult, no nikud) say "הילד", as the rest of the parent area does.

### 9.2 What was checked, and the counts

| Course | Checked | Changed in wording | Nikud, voice text, status | Text-ready |
|---|---|---|---|---|
| English | 51 frame lines, 68 glosses | 11 lines changed in meaning or register (the list under the table in `english/band-a-content.md` §2: the friend and Mika lines, the two buttons, drum, strip, ball-first, personal, show-me, beats, say-together), 2 glosses (clap, feet); `he-fb-check` and 3 glosses differ only in spelling | all 51 lines and 68 glosses pointed in full and given a voice text | 119 |
| Hebrew | 218 rows (60 new words, 12 syllable clips, 9 rhyme ends, labels, 67 instruction and feedback rows, 16 verse rows, 41 story rows), 3 parent cards, 52 names, B-12 | 20 rows (table 9.3) and 2 of the 3 parent cards; B-12 `סוּ + ס → סוּס` checked and unchanged | 129 `say` cells filled (every sentence row; words, syllables and rhyme ends stay pointed); the unit clip of `אֳנִיָּה` is sent as `אוֹ… נִי… יָה` | 218 rows, the 3 cards, the 52 names, B-12 |
| Russian | 39 frame lines (F03 was already final), 13 tags (26 texts), 2 letter-name lines, `שמעתי:` | 4 lines (F17, F19, F20, F39) in meaning, F06 and F07 in form; 16 of the 26 parent texts rewritten (a subject added, passives and "school form" replaced) | all 39 lines pointed and given a voice text; the adult texts have no nikud | 39 + 26 + 2 + 1 |

Checks run: `python -I tools/check_hebrew_course_words.py` (156 decodable words of S1 to S8, none needs a later step; the S9 to S12 lists are unchanged) and its new mode `--text FILE...` (hygiene of any file: canonical order, no final letter inside a word, no non-final at the end except a hard pe, a dot on every shin of a pointed word): 4,438 Hebrew words in the five files, one note, which is the teacher's suffix `־ִים` in a grammar remark. The CSV `say` column has no U+05B3 or U+05C7, no digit, no Latin letter, no "!" and no quote. `tools/test_hebrew_sources.py` passes (10 tests), and a rerun of `tools/hebrew_voice_review.py` leaves the app's master table as it was (the one difference it shows, `setupNameBadChars`, is older than this pass and was reverted).

### 9.3 Every change to the Hebrew course (the other rows only got `text-ready`; their `say` cells are new)

| Row | Was | Now | Why |
|---|---|---|---|
| `i-rhyme` | אֵיזוֹ מִלָּה נִגְמֶרֶת כָּמוֹהָ? | אֵיזוֹ מִלָּה נִגְמֶרֶת אוֹתוֹ דָּבָר? | `כָּמוֹהָ` is literary; the hint lines already say "אותו דבר" |
| `i-odd` | מִי לֹא שַׁיָּךְ? | מָה הִגִּיעַ לְכָאן בְּטָעוּת? | **the teacher's question 3.** Band A asks no "not" question (curriculum §8.3). The same game has had this line since 2026-10-29 (owner-approved, 2.9 above), so one game has one wording |
| `i-follow` | גְּעוּ בְּכׇל מִלָּה כְּשֶׁאֲנִי קוֹרֵאת. | הַקְשִׁיבוּ לְכׇל מִלָּה, וּגְעוּ בָּהּ. | **question 2.** The gender of the voice (9.1); also it is the voice that reads one word and waits |
| `i-strip` | כַּמָּה תּוֹפִים? | כַּמָּה תֻּפִּים? | the plural of תֹּף |
| `ok-2` | כֵּן, זֶה זֶה! | כֵּן, זֶהוּ זֶה! | "זה זה" is not a phrase, "זהו זה" is |
| `ok-8` | וְזֶה נָכוֹן! | כׇּל הַכָּבוֹד! | it repeated `ok-1` and read like a continuation |
| `why` | כִּי שְׁנֵיהֶם… | כִּי אֵלֶּה… | "שניהם" is masculine; two feminine words (פִּיצָה, פִּתָּה) need "שתיהן" |
| `d-sem` | זֶה דּוֹמֶה, אֲבָל זֶה לֹא זֶה. בּוֹאוּ נִשְׁמַע שׁוּב. | זֶה דּוֹמֶה. בּוֹאוּ נִשְׁמַע שׁוּב. | a misconception line names what the eye caught and ends in the strategy, **without `לֹא`** (owner Q2, 2.9). Same for the next five |
| `d-sem-rhyme` | זֶה מַתְאִים, אֲבָל לֹא נִגְמָר אוֹתוֹ דָּבָר. | זֶה מַתְאִים. בּוֹאוּ נַקְשִׁיב לַסּוֹף. | rule above |
| `d-allit` | זֶה מַתְחִיל אוֹתוֹ דָּבָר, אֲבָל נִגְמָר אַחֶרֶת. | זֶה מַתְחִיל אוֹתוֹ דָּבָר. בּוֹאוּ נַקְשִׁיב לַסּוֹף. | rule above; `אַחֶרֶת` is written register |
| `d-cat-theme` | הֵם הוֹלְכִים יַחַד, אֲבָל הֵם לֹא מֵאוֹתוֹ סוּג. | הֵם הוֹלְכִים יַחַד. בּוֹאוּ נִבְדֹּק מֵאֵיזֶה סוּג הֵם. | rule above |
| `d-print-picture` | קוֹרְאִים אֶת הַמִּלִּים, לֹא אֶת הַצִּיּוּר. | זוֹ תְּמוּנָה. קוֹרְאִים אֶת הַמִּלִּים. | rule above |
| `d-cat-atypical` | גַּם הוּא חַי: הוּא זָז וְאוֹכֵל. | גַּם זֶה חַי: זֶה זָז וְאוֹכֵל. | the card can be נְמָלָה (feminine) |
| `d-role-swap` | מִי זָז? | עַל מַה מְדַבְּרִים? | the picture items are static, so "who moved?" has no answer; "what are we talking about?" + the thing's word clip points at the subject of the sentence (to be heard in the pilot) |
| `d-letters` | אוֹתִיּוֹת הֵן מַה שֶּׁקּוֹרְאִים. | בָּאוֹתִיּוֹת קוֹרְאִים וְכוֹתְבִים. | letters are not "what is read" (words are); same pattern as `בָּזֶה סוֹפְרִים` |
| `m-boet` | בּוֹעֵט זֶה נוֹתֵן מַכָּה בָּרֶגֶל. בּוֹעֲטִים בְּכַדּוּר. | בּוֹעֲטִים בְּכַדּוּר בָּרֶגֶל, וְהוּא עָף רָחוֹק. | "נותן מכה" is a blow (a hurt), not a kick; the example says it |
| `m-mechapeset`, `m-meurbevet`, `m-soche` | X זֶה מְנַסָּה / מְסוֹבֶבֶת / זָז | X זֶה לְנַסּוֹת / לְסוֹבֵב / לָזוּז | the head word is feminine (or masculine) and the definition did not agree with it; the infinitive agrees with every head word |
| `m-tanur` | מְאוֹד | מְאֹד | the app's pointing |

Parent cards: story 1 "בקשו מהילד לספר את הסיפור עם הכדור שלו" ("with his ball", whose?) became "אפשר גם לבקש מהילד להמציא סיפור משלו על כדור"; story 3 had a fragment ("בגינה או באמבטיה: מה עף ברוח?") and now says "אפשר לשחק". Story 2 is unchanged.

Read and kept, and why: `bin-one` is `אֶחָד` (one thing: a label for a bin of masculine and feminine singulars, so a feminine `אַחַת` would be wrong for half the cards; the "one thing" case of 2.2). `d-cat-theme` and `d-cat-look` keep `הֵם`, the plural default for a pair of unspecified gender. `i-name` and `d-name-length` use `שֶׁלָּכֶם` for one child (plural address, 9.1). `d-blend-last` `מֵהַהַתְחָלָה` is correct and spoken ("מההתחלה"). `בַּעֲלֵי חַיִּים` (the teacher's reason is right: חיות is wild animals for many children). The verses rhyme in speech (all pairs are stressed on the last syllable, except בַּיִת / זַיִת, which both fall on the first). All 60 new words have the nikud and the stress that the Academy and Wiktionary give (`אֶפְרוֹחַ`, `שִׂיחַ`, `בּוֹרֵחַ` are patah-gnuva words, stress before it). The 52 names: ordinary Israeli first names of both genders and the 9 cast names, in the usual spelling, no nikud (the child sees them without; A-11); `קשת` is also a picture word but only appears as a name option. The child's own name is never in the list and never voiced.

**English course, wording that is not only nikud.** `he-ins-who-doing` is now "the picture of the action" (the pictures show one friend, and "the friend who is doing it" needs a participle with a gender); `he-ins-make-do` (Mika, 9.1); the two buttons are named in the line (`בַּכַּפְתּוֹר "סִיַּמְתִּי"`, `"אָמַרְתִּי"`); `he-ins-strip` is the Hebrew course's `כַּמָּה תֻּפִּים?`; `he-q-ball-first` says `בַּהַתְחָלָה` instead of the number word `ראשון`; `he-ins-personal` says first that the child may answer with a picture or aloud and then that skipping is fine; `he-hint-showme` is `הִסְתַּכְּלוּ אֵיךְ עוֹשִׂים` (the draft was a future form used as an order); `he-hint-beats` is `נִמְחָא כַּפַּיִם`; `he-fb-together` is the same line as the Hebrew and Russian courses (`בּוֹאוּ נֹאמַר יַחַד.`, 8.8). Glosses: the dictionary form for adjectives and nouns (`שָׂמֵחַ`, `עָצוּב`, `תִּינוֹק` do not follow the character shown), the feminine counting numbers, the dual for `אוֹפַנַּיִם`, `רַגְלַיִם` for feet (the word children use; the draft's `כפות רגליים` is the soles), `תֹּף` (not `תּוּף`), and for "clap" the noun `מְחִיאַת כַּפַּיִם`, because I could not confirm the plural imperative of מחא in a dictionary (Hebrew Wiktionary lists only `מְחָא`). `נִמְחָא` (we will clap) follows the paradigm of the listed `יִמְחָא`; the risk is low.

**Russian course.** F01 is the English `he-ins-listen-tap` and F03 the English `he-fb-together`. F06 uses `לְהַגִּיד` (spoken) and `מַה זֶּה` (the dagesh). F07 to F13 call the friend `הֶחָבֵר`. F19 had lost its object. F29 to F31 use `שָׁלוֹשׁ` / `שְׁתֵּי` / `אַחַת` with the feminine `מְחִיאוֹת`. F33 is `מַתְחִילוֹת` (מילים is feminine). The parent texts: a subject was added where "מכירים כבר את הנושא" had none; "זו צורת בית הספר" is "זו הצורה המנומסת"; the `да` text no longer says the answer "shows" something about the child; `кто` is for people and animals (not only animals). The letter-name lines are `קוֹרְאִים לָהּ` + the name and `וְהִיא אוֹמֶרֶת` + the sound (`אוֹת` is feminine; the same pattern as the Hebrew course's `הִיא אוֹמֶרֶת גָּ`). `שָׁמַעְתִּי:` is the same line in the three courses.

### 9.4 For the voice director: the voice text

The Hebrew course's `say` column and the `Voice text` columns of the English and Russian tables were made by the new `course_voice_text()` in `tools/hebrew_voice_review.py` (the app's rules of section 3, plus the following; nothing in the app's table changes):
- **A word with the sin dot keeps its nikud** (`שִׂימוּ`, `הִיא שָׂמָה`, `מְחַפֶּשֶׂת`, `שׂוֹחֶה`, `לַעֲשׂוֹת`): an unpointed ש is read [ʃ]. `וְאִמְרוּ` and `לֶחָבֵר` (plain "לחבר" is also "to connect") keep theirs; so do number words, `אֵלֶּה` and `בַּשָּׁמַיִם`, as before.
- **A carrier line ends with a colon and no full stop** (`בּוֹאוּ נִמְצָא:`, `שָׁמַעְתִּי:`, `בּוֹאוּ נַקְשִׁיב שׁוּב:`, `שִׁמְעוּ אֵיפֹה:`, `קוֹרְאִים לָהּ:`), because the next clip is the word. `זֶה` (`he-fb-thats`) is sent as `זה:`. Please test in the pilot that the voice does not fall on the colon; if it does, `…` is the alternative.
- A quoted button label loses its quotes and gets a beat: `געו בכפתור — סיימתי.` A maqaf becomes a space (`תיק תק`). New spellings in `KTIV`: `לקרוא`, `למצוא`, `כפיים`, and the hand `ביד` (not `בייד`).
- **Said differently from the screen:** `נֹאמַר` is `נגיד` (as in 8.8); `הַמְּמ…` is `המממ…`; every "!" is a comma after a one- or two-word cheer and a full stop otherwise.
- **Single words, syllables and rhyme ends stay fully pointed** (the pilot decides). `אֳנִיָּה` as a word is `אונייה`; its unit clip is `אוֹ… נִי… יָה`. The other unit clips with a hataf on the first syllable keep the teacher's `say` (a plain patah).
- **Names:** `פִּיפּ` (Pip) ends in a hard pe. `מִיקָה` is pointed with a final qamats-he, which a voice stresses on the last syllable (mi-KA); the English name is stressed on the first (MI-ka). The director should listen to this one in the pilot and, if needed, choose a spelling or a pointing before voicing.
- **Same words in the three courses** (`הַקְשִׁיבוּ, וּגְעוּ בַּתְּמוּנָה.`, `בּוֹאוּ נֹאמַר יַחַד.`, `שָׁמַעְתִּי:`, `הַקְשִׁיבוּ שׁוּב.`): if the courses share a voice they can share a clip; if each course has its own voice they cannot. That is the director's plan; the text does not depend on it.
- Counts (characters as sent): English 1,163 (51 lines) + 460 (68 glosses); Russian 938 (39 lines); Hebrew Band A 3,937 as sent (5,400 when every sentence was sent pointed). The tables in the three files give the details; the director makes the plan and the cost.

### 9.5 For the owner (numbered)

1. **The address rule (9.1) for all three courses:** recorded lines speak to the children in the plural whatever the profile says, and no line gives the voice a gender. Is that right for the language courses too? (My recommendation: yes. It is what the rest of the app does.)
2. **"מִי לֹא שַׁיָּךְ?" does not stay.** The odd-one-out question is `מָה הִגִּיעַ לְכָאן בְּטָעוּת?`, the line you already approved for the same game in the maths lands (2026-10-29). Row: `heb-a-i-odd`. OK?
3. **Pip, Mika and the "friend" have no gender in the Hebrew lines** (no pronoun, no verb about them). If the design-director fixes a gender for Mika or Pip, tell me: a few lines would then sound more natural (`וּמִיקָה תַּעֲשֶׂה אֶת זֶה`). I recommend leaving them neutral, because a rename or a redraw is expected. Rows: `he-ins-make-do`, `he-ins-who-doing`, Russian F17, F20, F39.
4. **The 52 names** of A-11 (43 ordinary first names and the 9 cast names): please look at the list once (`hebrew/band-a-content.md`, A-11) and say if a name should go or a name from your family should be added. A name is shown without nikud and never voiced.
5. **Parent texts say "הילד"** (generic masculine), as the rest of the parent area does. If you prefer "הילד או הילדה" or "הילדים", it is one replacement in the three files.
6. **Small choices you may overrule:** `רַגְלַיִם` for "feet", the noun `מְחִיאַת כַּפַּיִם` for "clap", the dictionary (masculine) form of "happy / sad / baby", `בֻּעָה` for a bubble (the course's spelling) and `אֲגוּדָל` for a thumb.

### 9.6 For the other agents

- **voice-and-sound-director:** 9.4. The pilot should include `מִיקָה` / `פִּיפּ`, a colon carrier (`שָׁמַעְתִּי:` + a word clip) and `עַל מַה מְדַבְּרִים?` + a word clip.
- **curriculum-expert:** `frame.md` §1.3 was changed by one sentence (9.1); please confirm. The Hebrew syllabus B-12 example `סוּ + ס → סוּס` is `text-ready`: סוּס is an S5 picture word, the unit סוּ is a stretchable consonant with u, and a final ס can be said alone. The odd-one-out line of A-03 changed, and the `לֹא` diagnostics (A-02, A-03, A-05 to A-07, A-10, A-12) are reworded; the tags and the items are unchanged.
- **design-director:** Mika and Pip are not gendered by any line (9.5, 3); the thumbs in A-16 are `אֲגוּדָל`; the bubble is `בֻּעָה`.
- **app-developer:** the A-11 closed list of names (52) is final; the two buttons are labelled `סִיַּמְתִּי` and `אָמַרְתִּי`; the pass button is `לדלג`; the parent texts of the 13 tags are final (adult, no nikud). Bring the lines into the sources following the tables; I check the result there.
- **qa-engineer:** no code was changed except `tools/hebrew_voice_review.py` (a new function `course_voice_text`, four KTIV words, `SIN_KEEP`; the app's master table is unchanged) and `tools/check_hebrew_course_words.py` (a new `--text` mode; its default mode is as before).

## 10. The last Languages drafts made final: the editor's second pass, 2026-11-03

Scope: the `needs-editor` drafts that the three Band A batches and the design-director's Languages island left open, and the bottle's lines for a language stop. The address rule of 9.1 applied to every line (plural to every child, no gender in the voice's lines, no pronoun for the friend). All items are `text-ready`, waiting for the owner; the bottle's lines are **proposals**. Nothing was voiced or paid; no code was changed except two words in `tools/hebrew_voice_review.py` (`COURSE_KEEP`). The full texts, with the Hebrew before and after, are in `docs/languages/island-texts.md` (the new file for the developer); the other texts are edited in their own files.

| Text | Decision | Where |
|---|---|---|
| `he-ins-how-many` (English) and Russian F40 | one line for both courses: `כַּמָּה יֵשׁ? הַקְשִׁיבוּ לַכַּפְתּוֹרִים, וּגְעוּ בַּמִּסְפָּר הַנָּכוֹן.` (7 words). The Russian teacher's `כמה ספרנו?` was not kept: unpointed `ספרנו` reads as "our book", and the question is "how many", not "how many did we count" (the counting is practice). One clip can serve both courses | `english/band-a-content.md` §2, `russian/band-a-content.md` §2 |
| `i-odd-animals`, `-food`, `-clothes` | the drafts are right and stay (`לַקֻּפְסָה שֶׁל …`, 7 words, the pattern of `i-odd`). Voice texts added; the alternative `לַמָּקוֹם שֶׁל …` (the wording of `i-sort-cat`) is written next to each row for a bin that is not drawn as a box; the design-director's spec draws a box, so it is not needed | `hebrew/band-a-content.md` §3, `hebrew/pronunciation.csv` |
| M-RUS-YESNO and M-RUS-NUMWORD parent texts | rewritten as one condition and two calm sentences; no quoted phrase with a vav inside; `סמוכים` (adjacent) for три and четыре, because they are neighbours in value, not necessarily close in sound | `russian/band-a-content.md` §3 |
| The island's name, the three names, `שָׁלוֹם` | `אִי הַשָּׂפוֹת`, `אנגלית`, `עברית`, `רוסית`, `שָׁלוֹם` checked and kept | `island-texts.md` §1, §2 |
| The companion's door line | `בּוֹאוּ נִפְתַּח דֶּלֶת. מִי אוֹמֵר לָנוּ שָׁלוֹם?`: "a door", never a number of doors (two or three may be on); a wondering that is true to what the tap does; no name | `island-texts.md` §1 |
| The parent pages | 52 rows; the draft had the child's name with a feminine verb in the progress intro (`נֹעָה לומדת … הבינה`): now gender-free. `פועלת` → `פעילה`; the status words are the app's (`בתרגול`, `מובן`, `כדאי לחזור`) plus `מובן וזכור`; the chips `תרגלו / אמרו` (orders when unpointed) → `תורגל / נאמר`; the English gate `שער הדיבור` → `שער הקריאה` (it decides when letters open). Texts the previews did not show (the other state of a switch, the Russian gate) were written | `island-texts.md` §3 |
| The bottle for a language stop (proposals) | no `core.adventure.*` exists in `core.he.json`: the lines are `adventure*` in `he.dart` (section 7 above). One fixed line per language, the same for every reason, no `{land}`: `בּוֹאוּ נְשַׂחֵק בְּאַנְגְּלִית.`, `… בְּרוּסִית.`, `… בְּמִלִּים.` (Hebrew is "with words": the whole app is Hebrew). The five existing lines would also work with `{land}` = `אִי הַשָּׂפוֹת`, except `callForHelp` (no language "needs help") | `island-texts.md` §4 |

**Voice rules added** (`COURSE_KEEP`, courses only; the app's table is unchanged): `הָאֹכֶל` keeps its nikud in the voice text (plain `האוכל` is read with the stress on the last syllable: "the one who eats"), so `he-ins-give` of the English course changed from `את האוכל` to `את הָאֹכֶל` (3 characters more), and `אִי` (plain `אי` is read "ai" or "ee").

**Counts.** Voice-text characters: English 52 lines 1,207 (+44; with the 68 glosses 1,667); Russian 40 lines 979 (+41); Hebrew Band A 4,035 (was 4,093: the three rows were counted pointed before they had a voice text). Checks: `tools/check_hebrew_course_words.py --text` on the four files (3,505 Hebrew words; the one note is the teacher's suffix in a grammar remark), `tools/test_hebrew_sources.py` (10 tests, OK).

**Not decided here (the owner, `island-texts.md` §6):** the door line with or without the question, the Hebrew bottle line, the three route names of the Russian stress setting, how the Hebrew "parent check of reading aloud" works (the help text says only what is certain), and the status words of the parent progress page.

## 11. The editor's full pass of 2026-11-06 (owner: "the Hebrew review now, voices later")

Scope and counts, the 38 changed rows with before and after, the 5 questions for the owner and the verification are in
`docs/review/hebrew-review-2026-11-06.md`. The sources were changed directly (`he.dart`, `content/units/{colours,logic,robots}.json`,
`tools/band_b2.py`, `tools/band_b3.py`), the pack regenerated with `tools/regen_content.py`, and each change is recorded in
`ROW_RULES` of `tools/hebrew_voice_review.py` ("Editor's second pass, 2026-11-06"). Everything is `text-ready`, waiting for the owner.

**Rules learned in this pass** (add to sections 2 and 3 when the rules are next folded together):

1. **`צָרִיךְ` is "needs", not "is needed".** `מִבְרֶשֶׁת לֹא צְרִיכָה לִרְחִיצַת יָדַיִם` says the brush needs nothing. Put the purpose first and
   the thing after, as the hints do: `לִרְחִיצַת יָדַיִם לֹא צְרִיכָה מִבְרֶשֶׁת` (the verb agrees with the thing: `צָרִיךְ סַבּוֹן`, `צְרִיכָה מַגֶּבֶת`).
2. **A question about a colour or a property of a thing needs a verb or `מַה`**: `מַה צֶּבַע הַשֶּׁמֶשׁ?`, not `אֵיזֶה צֶבַע הַשֶּׁמֶשׁ?`
   (the dagesh follows `מַה`; `מָה` stays before א ה ח ע ר, as in the lesson title `מָה חָסֵר בַּתַּעֲרוֹבֶת`).
3. **Sin or shin by the root.** `שׂחק` (play) is a sin everywhere: `לְשַׂחֵק`, `מִשְׂחָק`, `נִשְׂחַק`. A shin dot on it means "worn down". The
   scan lists every sin-dot word of the table (30 words) and every shin-dot word of a sin root; run it when a verb of play is added.
4. **Prizes are won, not earned**: `לִזְכּוֹת בָּהּ`, `שֶׁעוֹד לֹא זָכִינוּ בּוֹ`. `לְהַרְוִיחַ` is for money.
5. **`זֵהֶה`** (tsere) is the one pointing for "identical" (`הַזֵּהֶה`, `זֵהָה`, `זֵהִים`).
6. **Written words stay out of the pack**: `מֵאֲשֶׁר` (use two short sentences), `אֶלָּא`, `זֹאת` (use `זוֹ`). The register list of the scan: `האם`,
   `אחרת` (as "otherwise"), `כאשר`, `בלבד`, `אינו`, `אולם`, `עליכם`, `ניתן`, `מאשר`, `אלא`, `זאת`.
7. **A misconception line has no `לֹא`** (Q2) in all bands: what the eye caught, then the strategy (`הַמַּטְבֵּעַ גָּדוֹל אוֹ קָטָן, אֲבָל כַּמָּה הוּא שָׁוֶה?`).
   Four lines in the pack still break this rule and wait for the owner (review log, question 2).

**For the app-developer.** Nothing to bring in: the sources hold the corrected text and `tools/test_hebrew_sources.py` passes (pin: 12,777 rows).
`content/starter` changed in 24 files, so `starter_pack_test` › "the pack was built from the sources" stays red until the owner builds the
next pack version. **For the voice director.** The 21 changed texts need no direction; the spoken ones are re-voiced from `voice_text`.

**Update, 2026-11-06 (the owner's answers, in chat).** Rule 7 now holds in the pack: the four `לֹא` misconception lines are reworded (`M-MEAS-BIG`, `M-SORT-SHIFT` colour line, the chart `M-CNT-SIZE` line with its own clip `vo:fb.size.chart`, `M-ORD-CARD`); the B-15 title is `זֵהֶה אוֹ שׁוֹנֶה?` (owner-approved in chat). **No line says `כִּמְעַט`** (owner: do not mislead a child who is not close): the default wrong-answer line is `בּוֹאוּ נְנַסֶּה שׁוּב.` (id `vo:fb.almost` kept) and `core.encourage.almost` is `עוֹד לֹא — בּוֹאוּ נְנַסֶּה שׁוּב.`. Add `כִּמְעַט` and `כמעט` to the register scan as "only when the app knows the answer was close". Details: `docs/review/hebrew-review-2026-11-06.md` section 7.

## 12. The editor's read of the 59 maths-check rows, 2026-11-06

Scope: the 59 rows that the Maths and CS teachers' fixes left `proposed` (`docs/knowledge/maths/check-2026-11-06-fixes.md` section 8.8), read for grammar,
nikud, the plural address rule (9.1), the owner's decision that a square is a rectangle, and clarity at ages 3 to 8. All are `text-ready`, waiting for the owner;
`MATHS_CHECK_ROWS` in `tools/hebrew_voice_review.py` is empty. Sources changed: `tools/band_b2.py`, `content/units/logic.json`; the pack and the tables regenerated.

**Read and kept (57 rows).** The new numbers in reviewed templates (`b.numb05.8` with `תִּשְׁעָה עָשָׂר דָּגִים` and the bare `תְּשַׁע עֶשְׂרֵה`; `b.numb10.*` with bare
feminine numbers and `וְשֵׁשׁ` / `וּשְׁמוֹנֶה`; `b.mathb08.13` and `.14`, where the finger count in the hint is true: 7 to 11 is five, 9 to 12 is four, with `חָמֵשׁ` and
`אַרְבַּע אֶצְבָּעוֹת`; `b.mathb07.6`; the robot hints of `b.csb01.6` and `cs.robot.plan.6`), the MATH-B-09 caption `חָבֵר כָּתַב תַּרְגִּיל, וְהַתְּשׁוּבָה לֹא נְכוֹנָה. אֵיפֹה הַטָּעוּת?`
(MATH-B-03's reviewed caption; it reads right with the answer written first, because the correct line and the hint say `שֶׁבַע שָׁוֶה שָׁלוֹשׁ וְעוֹד אַרְבַּע`) and the
shared M-SHP-SQRECT line `בְּרִבּוּעַ כׇּל הַצְּלָעוֹת שָׁווֹת. בַּמַּלְבֵּן הַזֶּה יֵשׁ צְלָעוֹת אֲרֻכּוֹת וּקְצָרוֹת.` (13 rows). The W3 lines never say that a rectangle has long and
short sides in general, and never that a square is not a rectangle: `הַזֶּה` points at the picture the child touched. No row addresses one child.

**Changed (2 texts, 4 rows).**

| Row | Was | Now | Why |
|---|---|---|---|
| `b.shpb03.7` › wrong tap (`vo:fb.sqrect.square_is_rect`) | גַּם רִבּוּעַ הוּא מַלְבֵּן: מַלְבֵּן שֶׁכׇּל הַצְּלָעוֹת שֶׁלּוֹ שָׁווֹת. בּוֹאוּ נִסְפֹּר אֶת הַצְּלָעוֹת בְּכׇל צוּרָה. | רִבּוּעַ הוּא גַּם מַלְבֵּן: מַלְבֵּן מְיֻחָד, שֶׁכׇּל הַצְּלָעוֹת שֶׁלּוֹ שָׁווֹת. בּוֹאוּ נִסְפֹּר אֶת הַצְּלָעוֹת בְּכׇל צוּרָה. | "a square is also a rectangle" is the natural order; `מְיֻחָד` is the owner's "special rectangle" in a word a child knows |
| `b.shpb03.2/.4/.6` › hint 3 | בַּמַּלְבֵּן הַזֶּה שְׁתֵּי צְלָעוֹת אֲרֻכּוֹת וּשְׁתֵּי צְלָעוֹת קְצָרוֹת. | בַּמַּלְבֵּן הַזֶּה **יֵשׁ** שְׁתֵּי צְלָעוֹת אֲרֻכּוֹת וּשְׁתֵּי צְלָעוֹת קְצָרוֹת. | a verbless sentence with `הַזֶּה` reads like a label; the correct line already has `יֵשׁ` |

**LOG-A-01 has its own feedback line.** M-COL-ONEATTR says `יֵשׁ שְׁנֵי דְּבָרִים לִבְדֹּק: מַה זֶּה, וְאֵיזֶה צֶבַע.` That is right for COL-A (find the red ball), but in LOG-A-01 colour does not
matter (a green apple is "the same thing"), so the line sent the child to a check that can make a right answer look wrong. The 7 items whose lure has the colour of the
picture (`log.same.star`, `.duck`, `.apple`, `.bird`, `.balloon`, `b15.loga01.3`, `.4`) now say the owner-approved kind line `זֶה אוֹתוֹ צֶבַע, אֲבָל מְחַפְּשִׂים אֶת אוֹתוֹ הַדָּבָר. בּוֹאוּ נִבְדֹּק.`
(`vo:fb.sort_shift.kind`, one clip, no new text). `log.same.cat` offers a brown dog for a grey cat, so "same colour" would be false there; it says the new
`זֶה דּוֹמֶה, אֲבָל מְחַפְּשִׂים אֶת אוֹתוֹ הַדָּבָר. בּוֹאוּ נִבְדֹּק.` (`vo:fb.same_similar`, the wording of the approved size line). Done with `tag_lines` in `content/units/logic.json`.
Open for the maths teacher: the dog is not a same-colour lure, so M-COL-ONEATTR on it is not honest; an untagged dog or a grey animal would be.

**Square and rectangle, wording rule.** Say "this rectangle" for the picture shown, and "a square is also a rectangle" only where the item teaches it (SHP-B-03 spot, Band B).
Never "a rectangle has long and short sides" as a general claim, and never `רִבּוּעַ וּמַלְבֵּן` or `רִבּוּעַ אוֹ מַלְבֵּן` as a title (two kinds). The proposal for the SHP-B-03
lesson title and celebration is in the review report for the owner (not applied).

**Pins.** `tools/test_hebrew_sources.py`: done-and-changed rows 1,290 (was 1,296: six LOG-A-01 rows whose corrected text is now the text the pack gives). Rows 12,751 and proposed 55 are unchanged.
