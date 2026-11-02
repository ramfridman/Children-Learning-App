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
   rows `proposed` with "V1", 100 rows, still waiting): `שָׂמִים`, `סָפַר`, `גְּדֵלִים`, `בַּתּוֹר`, `אִמְרוּ`, `נְגַלֶּה`, `אוּפְּס`,
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

## 11. B-38 wording for the next pack (2026-11-01, `proposed` / `needs-editor`)

Sources: `content/units/shapes.json` (the two cat items, the b15.shpa07.2 h3, the shared M-SPACE-WORD line), `tools/band_b2.py` (the
box bridge, the new `b.shpb08.10`, the solids' own SQRECT line). Rows: `PENDING` in `tools/hebrew_voice_review.py` (B38).
- **Cat items:** the prompt names the place (`אֵיפֹה הֶחָתוּל? בְּתוֹךְ הַסַּל.`); the labels are the plain place words; h3 = look at
  the basket, then why (`הוּא מִסָּבִיב לֶחָתוּל` / `הוּא סָגוּר, וְהֶחָתוּל יוֹשֵׁב לְמַעְלָה`), the answer last.
- **`fb.space_word`** has no object: `הַמִּלָּה אוֹמֶרֶת לָנוּ אֵיפֹה זֶה נִמְצָא.` (`זֶה` fits a ball, a cat and a box). It is one clip for
  eight items; voice it again if the old one was made.
- **Box and cube:** Band B `תֵּבָה` / `קֻבִּיָּה`; Band A `קֻפְסָה`, and `קֻבִּיָּה` only for a real cube. The faces of a solid are
  `צְדָדִים` (Band A `צַד שָׁטוּחַ`), the sides of a flat shape stay `צְלָעוֹת`.
- **SQRECT for solids:** the shared line (`בְּרִבּוּעַ כׇּל הַצְּלָעוֹת שָׁווֹת…`) speaks of flat shapes and does not tell a cube from a
  box, so the two cube-and-box items have their own line (`tag_lines`, `vo:fb.sqrect.solids`).

## 12. B-40: the hint lines follow the hint pictures (hebrew-text-editor, 2026-10-31)

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

## 13. B-40 part 4: the hint lines of Band B and of the other templates (hebrew-text-editor, 2026-10-31)

**What was done.** `tools/hint_lines.py` now also reads Band B `tap_answer` (one function for each plan of
`app/lib/play/hints/tap_plans_b.dart`, `B_FAMILIES`) and the number line, clock, match, sort, build a pattern, shape builder, robot
and spot-the-mistake templates (`retext_other`), with the same guards and fall-backs as the app (a plan that falls back to the
generic card, or to the Band A family plan, keeps the lines it has). 676 lines changed in 383 activity files (L1 46, L2 357, L3 273);
every one is `proposed` in the master table (`PENDING` / `is_b40_text`), the activity stays `needs-editor`. The grammar rules found
nothing to correct in them (`ui_text` equals `text`); 97 older Band B rows whose table corrections (the dagesh after the vav and the
like) are now in the source text were replaced, so the pinned count of corrected rows in `test_hebrew_sources.py` went from 1302 to 1205.

**Lines changed, by family.**

| Family | Level 1 | Level 2 | Level 3 | Items |
| --- | --- | --- | --- | --- |
| The number path: NUM-B-01, 02, 03, 11 | the number and the empty place (`vo:hint.gap.h1`, as in Band A; no counting) | the path of ten, the number marked, the empty place beside it | one hop from the number given, forward or back, the answer last (NUM-B-02: nineteen to twenty is one square) | 9 + 9 + 8 + 12 |
| NUM-B-17 (skip counting) | stays | the hops between the numbers said | the numbers said, one more hop, the answer last | 5 of 6 |
| NUM-B-08 (a teen) | stays | ten squares full, the ones on the second board | build: a full board, the ones, together | 14 |
| MATH-B-02 (no picture), 06 | stays | cubes or empty squares: what is there, what is missing | count the empty places (from one) | 4, 10 |
| MATH-B-03, 07, 08, 18, NUM-B-16 with a row | stays | cubes over each number (over the whole: cubes and empty places) | the cubes of each number, the answer last | 10, 8, 14, 9, 4 |
| NUM-B-10, MATH-B-16 | stays | a bar of cubes for each number or coin, from one line | the count of each bar, the longer or shorter one last | 10, 2 |
| NUM-B-18 | stays | pair lines, who is left without a pair | the old line stays (it follows the picture) | 10 |
| MATH-B-10, 19 | stays | a count beside each column | the running total (plates) or the counts (chart), then the question | 8, 11 |
| MATH-B-14 (the week) | stays | the seven days, the day of the question marked | the walk along the week, the answer last | 11 |
| MATH-B-15 (read the clock) | stays | the dotted line to the rim, 12 marked | count the hours round the dial | 10 |
| SHP-B-01, 02, 03, 04 | stays | the sides lit one by one (SHP-B-03: a stick for each side) | the hand along the corners (B-01 counts; B-04 says closed, open or curved) | 8, 10, 6, 8 |
| SHP-B-08, 09 | stays | the lines of the solid; the print under each solid | the lines go over the options; the solids are pressed in sand | 8, 2 |
| COL-B-01, 02 | stays | two paints, an arrow, an empty circle; the shades in a row with an arrow | the mix, last; light to dark | 9, 12 |
| LOG-B-06, 09 | stays | links between neighbours; the first clue fades one | the walk and the compare; the second clue fades another | 6, 8 |
| COL-A-05 (4 items) | stays | an empty paint spot: "which colour fits this?" | stays | 4 |
| number_line | stays | one dotted hop, the number one | the frog counts its hops and lands (a line put on by touch: a running number) | 25 |
| clock_set | the short hand (the old level 2 line, moved up) | the card and the numeral on the dial have the same ring | the plus is pressed hour by hour, the hours said | 8 |
| match_pairs | stays | dots under the numeral or the coin; the print under the solid | stays | 7 + 6 + 4 |
| sort (not share), build a pattern with a model, shape builder, robot | stays | a picture passes each group; the picture above the empty place is lit (and a line marks the repeat); the shadow floats beside the picture; the first arrow and the footprint "1" | stays | 25 + 11 + 7 + 22 |
| spot the mistake (Band A, the shared line) | stays | stays | the hand stops on the odd one and the right picture appears above it | 9 of 12 |

**Rules added.**
1. A level 3 line keeps each item's own ending ("now your turn — click on seven"), so the process comes first and the answer is the
   last number or word before the ending.
2. A line that counts cubes writes the number in agreement with the noun (`שְׁתֵּי קֻבִּיּוֹת`, `קֻבִּיָּה אַחַת`, `אֵין קֻבִּיּוֹת`);
   a bare number is feminine.
3. The conjunctive vav comes from `F.vav` (`וְכָחֹל`, no dagesh); `לְ` before a number word is pointed by `lamed()` (`לִשְׁמוֹנֶה`).
4. A line is never longer than 24 words (the longest is 22).

**Decisions for the owner (all rows `proposed`, comment "B-40").**
1. **MATH-B-18 (9 items).** The owner's Q3 (2026-10-29) asked for "count on from the first number, one finger per count". The picture
   in the app counts the empty places from one (badges 1, 2, 3...) and draws no fingers, so the new line says that. Two teachings,
   one picture: either the line stays as it is now, or the picture changes to the count-on (the app-developer and the curriculum-expert).
   Likewise NUM-B-16 with a row (4 items): "ten, and one more, two" became "ten cubes are there, count the empty places".
2. **MATH-B-08 above ten (8 items, e.g. 8 + 5).** The old line made a ten ("eight and two are ten, three more, thirteen"). The picture is
   two groups of cubes, not a ten, so the new line is `שְׁמוֹנֶה קֻבִּיּוֹת וְעוֹד חָמֵשׁ קֻבִּיּוֹת. בַּכֹּל — שְׁלֹשׁ עֶשְׂרֵה.` The make-ten
   strategy is gone from level 3 until a picture of a ten exists.
3. **The owner-approved P1 line** `vo:hint.spot_but_one.h3` ("all alike except one") is replaced by `vo:hint.spot_right.h3` in the 9
   Band A spots where the app draws the right picture above the mistake; it stays in the other 3. Spots that have their own third hint
   (the order of washing, the counting, the patterns) are not changed.
4. **New words:** `לוּחַ` (a ten-frame: `לוּחַ אֶחָד מָלֵא, עֶשֶׂר מִשְׁבְּצוֹת`), `הַפְּלוּס` (the plus tile of the clock), `קַו מְנֻקָּד` (the
   dotted arc and the dotted line to the rim), `מַקְלוֹת` (the sticks of SHP-B-03), `הַצֵּל` (the ghost outline of the shape builder),
   `הָרוֹבּוֹט הַשָּׁקוּף` (the ghost robot), `דּוֹהָה` (a shape fades, LOG-B-09).

**For the app-developer and the curriculum-expert (found while reading the plans).**
- `numbersIn` (`hints/prompt_numbers.dart`) reads "שֵׁשׁ, שְׁמוֹנֶה, עֶשֶׂר" as 6 and 18 (a comma is a break, the tokens are neighbours), so
  `b.numb17.12` gets no number path and plays the generic card; its lines were left as they are.
- MATH-B-10 "how many plates?" (2 items, `reverse`): the picture shows the running total of the things (2, 4, 6), not the number of
  plates. The line says it ("when we reached six, there were three plates"), but the picture does not show the plates counted.
- The sphere of SHP-B-08 is drawn as a circle (its outline on paper); its line says "lines of the solid".
- Not done, because the picture is not built or the plan is the Band A family plan: shop_pay, balance, COL-B-03, MATH-B-01, NUM-B-14,
  NUM-B-16 with groups, MATH-B-02 with groups, LOG-B-01 and 04, trace.

## 14. B-36 part F: the text pass over the next pack and the app (hebrew-text-editor, 2026-11-01)

**What was read.** Every `proposed` row of `docs/review/hebrew-master.csv` on branch `next-pack`: 3,147 rows, 997 distinct texts. They are
the 1,142 B-40 hint lines, the part B/C/E lines (`vo:fb.card.*`, the 8 new tags, `vo:fb.shp_name.solids`, the 8 misconception files,
the LOG-A-09 labels), the 150 part D items with their 8 `-1-b36` lessons, the B-38 cube and cat lines, the 9 `vo:hint.spot_but_one.h3`
rows that went back to proposed, the B-39 bottle lines and the B-32 refusal message. Each text was read as the child sees it (grammar,
nikud, gender and number, plural address, length, the word a 3 to 8 year old knows), with the item next to it where the line depends on the picture
or on the answer (`ditems` view: prompt, options, correct line, every wrong-answer line, the three hints).

**Result.** 2,928 rows are `text-ready`; 219 stay `proposed` because only the owner can answer them: 171 V1 rows (decision 8), 12 balance
rows (D12), 10 Q2 drafts, and 26 B-40 hint rows with a real teaching question (section 14.3). 185 rows (94 distinct texts) were reworded in
the SOURCES; the table keeps the draft and the reason in the `changes` column (`PART_F_LIST` and `PART_F_RX` in `tools/hebrew_voice_review.py`).
Another 60 older rows that were `text-ready` already changed with them (the shade lines of COL-B-02 and COL-B-03, the M-SEQ-SCRIPT line of the six `cs.wrong` items, the number-line line `כׇּל הַקְּפִיצוֹת שָׁווֹת`, the B-32 refusal message): 245 rows in all have a new text.
Owner-approved rows: 115 before, 115 after, none changed.

### 14.1 What was wrong, by kind (the drafts of the app-developer and the curriculum-expert)

| Kind | Examples | Fix (source) |
|---|---|---|
| Gender | `שְׁלוֹשָׁה צְפַרְדְּעִים גְּדוֹלִים` (a frog is feminine); `שְׁתֵּי עִקּוּלִים` (עִקּוּל is masculine) | `counting-hills.json`, `band_b36.py` |
| Words that are not Hebrew, or the wrong word | `עוֹשִׂים שֶׁהֵם יַחְזְרוּ`; `הָעֶתֶק` / `בֶּעָתֶק` (not "the copy"); `מִלַּכֶּלֶב`; `קַו שֶׁכָּבוּי` ("turned off"); `חֲסֵרוֹת` with no noun | `logic.json`, `math.json`, `band_b36.py` |
| Sense: the line did not fit the item | "you copied the order" after putting a routine, a story, towers or days in order (12 items: now `סִדַּרְתֶּם`); the old M-CNT-SIZE line ("more is not always bigger") on the NUM-A-11 balance; the mirrored 3 and 7 answered with the line about two digits swapped; `הֵם שׁוֹנִים` with no "different in what" | `correct_text`, `tag_lines` |
| Nikud | `מִעֶשֶׂר` → `מֵעֶשֶׂר`, `מִשֵׁשׁ` → `מִשֵּׁשׁ`, `הַחָתוּל` → `הֶחָתוּל`, `הֶחוּם` → `הַחוּם`, (`אוּפְּס` → `אוֹפְּס` was a mistake, undone in section 15), `בַּסַּךְ הַכֹּל` → `בְּסַךְ הַכֹּל`, `כֹּל` → `כׇּל` | `author.py from_()` (gutturals take מֵ; the dagesh after מִ), `SUBS` |
| Register / vocabulary | `שִׁגְרָה`, `גְּרָף`, `נֶעֱרָמִים`, `כָּמוֹהוּ`, `אֶלְכְּסוֹן`, `בְּיוֹתֵר` | `אֶפְשָׁר לַעֲרֹם`, `שַׁיָּךְ`, `הֲכִי גָּבוֹהַּ`, a slide a child knows |
| Templates | the default level 3 of a number line that starts at ten said "start from ten and count from one to fourteen" | `author.py k_numline`: "start from ten and count: eleven, twelve…" |
| Level 3 opens with the answer | the 16 flash lines began `אֵלֶּה שְׁלוֹשָׁה תַּפּוּחִים.` | `author.py k_flash`: `סוֹפְרִים אֶת כֻּלָּם.` first |
| One word for one thing | the ten-frame was `לוּחַ` (my B-40 draft, 23 rows) and `מִסְגֶּרֶת` (older lines, NUM-A-14, MATH-B-08) | `מִסְגֶּרֶת` everywhere (`hint_lines.py` TEEN templates); `לוּחַ` is gone |
| The sides of a scale | `עַל קַעֲרָה אַחַת` (a bowl) in 4 balance items; `חֲסֵרוֹת` | `בְּצַד אֶחָד … בַּצַּד הַשֵּׁנִי`, as every other balance line says |

### 14.2 The two lines of the curriculum-expert (b36 section 10), and what was found next to them

- COL-B-02 `.9` to `.12` (the middle shade): the shared M-SER-ENDS line said "not the smallest and not the biggest". They and `b.colb02.13`/`.14`
  say `מְחַפְּשִׂים אֶת הָאֶמְצַע: לֹא הֲכִי בָּהִיר וְלֹא הֲכִי כֵּהֶה.` (`SHADE_ENDS`, one clip).
- COL-B-03 green, red and purple (and the same three colours in COL-B-02): the shared M-COL-SHADE line said "light blue and dark blue are both blue".
  They say `בָּהִיר אוֹ כֵּהֶה, זֶה אוֹתוֹ צֶבַע. בּוֹאוּ נִבְדֹּק שׁוּב.` (`SHADE_SAME`); the blue items keep the old line.
- **Found next to it:** in `b.colb02.1` to `.8` ("which is the darkest / lightest?") a child who picked the middle shade heard "we look for the middle". They now
  hear `זֶה הָאֶמְצַע. בּוֹאוּ נַשְׁוֶה אֶת כֻּלָּם: בָּהִיר, אֶמְצָעִי, כֵּהֶה.` (`SHADE_END_PICK`).

### 14.3 Left for the owner (still `proposed`), besides V1, Q2 and D12

1. **MATH-B-18, level 3 (9 items):** the B-40 line counts the empty places from one (what the picture draws); the owner's Q3 asked for count on with fingers.
2. **Spot the mistake, level 3 (9 Band A items):** the B-40 line `vo:hint.spot_right.h3` replaces the owner-approved P1 line where the app draws the right picture above the mistake.
3. **MATH-B-08 above ten, level 3 (8 items):** two groups and the sum; the make-ten strategy is gone until a picture of a ten exists.

### 14.4 Not text, for others

- **curriculum-expert:** `x.numb07.21` and `.22` tag the mirrored 3 and 7 `M-NUM-REV` ("swaps two digits"); the tag that fits is `M-NUM-WRITE`. The line is fixed (own `tag_lines`), the tag is not.
  Older lines worth a second look (all `text-ready`, I did not touch them): `יֵשׁ הַרְבֵּה בְּסַךְ הַכֹּל, וְחֵלֶק מֵהֶם כְּבָר רָאִינוּ` (M-PART-MISS, 40 rows) and the NUM-A-11 "same?" correct line `כֵּן, צָדַקְתֶּם!` after a child's "לֹא".
- **voice director:** V1 is 171 rows now (was 126): the new rows use the same 10 words (`בַּתּוֹר` 51, `גְּדֵלִים` 43, `אֵלֶּה` 37, `שָׂמִים` 19, `סָפַר` 13, and 5 single words) and the beat before `זֶה אֶפֶס`.
  Number words keep their nikud also after `מִ` (`מִשֵּׁשׁ`, `מִשֶּׁבַע`): `is_number_token` strips the dagesh of the dropped nun. The five B-39 lines stay PER-LAND.
- **app-developer:** nothing to fold in; the sources are already corrected (`content/units`, `tools/`, `he.dart` › `setupNameBadChars`). The two tool pins moved with a comment
  (`test_hebrew_sources.py`: corrected-and-done rows 1189 → 1159, proposed-and-corrected rows 75 → 39).
- **qa-engineer:** the label `אֵיפֹה הַבַּרְוָז?` of the cat items is right: the hint card draws a small duck (`tap_plans.dart _position`), not the cat.


## 15. The research pass on the V1 words (hebrew-text-editor, 2026-11-01; the owner said some pronunciations and translations in the B-36 sheet were wrong)

Method: every word of the V1 list looked up in Pealim (forms, nikud, transliteration), Milog (Hebrew-Hebrew meaning and nikud), Hebrew and English Wiktionary
(stress, readings); the results are in the D1 table of `docs/review/b36-owner-sample.md` with a link for each word. What it changed:

| Finding | Fix |
|---|---|
| **`אוֹפְּס` is wrong; the pointing is `אוּפְּס`** ("ups"; Milog, Hebrew Wiktionary). I had changed `אוּפְּס` to `אוֹפְּס` in B-36 part F ("as in core.listen.mixed"); the helper line had `אוֹפְּס` since M5. The competing readings of plain אופס are `אוֹפֵס` (o-FES, "is running out") and `אֻפַּס` (u-PAS, "was reset") | `he.dart` listenMixed, `core.he.json` core.listen.mixed, `tools/band_b36.py` (the robot item `b.csb04.7`, regenerated), the rule in `hebrew_voice_review.py` now maps `אוֹפְּס` to `אוּפְּס`; the part F entry for this line is removed. The clips of 2026-10-28 (`core.listen.mixed`) were sent as `אוֹפְּס` and need voicing again. Not touched (they are audition inputs the director may have used): `docs/audio/audition/round2.json` H1-mixed-*, six lines with `אוֹפְּס` |
| `צָדַקְתֶּם` → `צְדַקְתֶּם` (3 rows, `tools/author.py`); `עָבַרְתֶּם` → `עֲבַרְתֶּם` (3 rows, `band_b.py`, `band_b36.py`) | Pa'al 2nd person plural past: shva, and a hataf-patach after ע (Pealim). The 6 rows are `proposed` again (`PENDING`). I scanned every 2nd person plural past in the table (the `-תֶּם` forms); no other form is off |
| Glosses and stress | `VOICE_AUDIT_KEEP` has the corrected reasons (stress in capitals, the real competing word). `שָׂמִים` is the plural present of שָׂם ("put", the impersonal instruction); `גְּדֵלִים` has a real competitor, `גְּדָלִים` ("sizes", Pealim lists both); `בַּתּוֹר` against `בְּתוֹר` ("as"); `אֵלֶּה` against `אֵלָה` / `אַלָּה`; `נְגַלֶּה` against `נִגְלֶה` / `נִגָּלֶה`; `בַּשָּׁמַיִם` against `בְּשָׂמִים`; `מֵדַלְיָה` is me-DAL-ya (Wiktionary) |
| Left as it is | plain `ספרנו` (130 rows, `סָפַרְנוּ`; the other reading, `סִפְרֵנוּ` "our book", does not fit "אוּלַי ___ אֶחָד פַּעֲמַיִם?"); `הַוִּי` (Milog: וִי); the number words |
| Suggested, not done | `אִמְרוּ לִי` → `תַּגִּידוּ לִי` (Pealim: the spoken imperative of לוֹמַר is from לְהַגִּיד; the audit's Q5); `אֵלֶּה מַה שֶּׁחָסֵר` (10 rows) and `לְכִוּוּן הַחֵץ` → `בְּכִוּוּן הַחֵץ` (28 rows) wait for the owner's word |

Checks: `regen_content.py` twice, byte-identical; `test_hebrew_sources` (10) and `test_generators` (58) pass. Not run: the Flutter tests (`app/test/voice_text_test.dart` has the fixture text `אוּפְּס` now; it is a fake core file, it pins nothing of the real text).

## 16. The owner's answer to the B-36 sheet (recorded by the hebrew-text-editor, 2026-11-01)

The owner's words: "All proposed looks good." (after the corrected sheet `docs/review/b36-owner-sample.md`). Recorded as follows.

| Question | Answer | Where it is now |
|---|---|---|
| D1 V1 words kept pointed in the voice text | yes | `VOICE_AUDIT_KEEP`, unchanged except the next line |
| D1 "say!" | **`תַּגִּידוּ לִי`** (my recommendation, not `אִמְרוּ לִי`) | `content/lines/core.he.json` `core.listen.say` (voice text plain: `תגידו`); `אִמְרוּ` left `VOICE_AUDIT_KEEP` (V1 is 170 rows now) |
| D2 Q2 a, b, c | yes, yes, yes | `tools/author.py` `SIZE_BY_CUE` (`pairs` for the 3 NUM-A-11 "same?" items, vo:fb.size.pairs; `count` for the 7 NUM-A-07 matches, vo:fb.size.count, set in `band_b3.py`); c was in already |
| D3 balance sides (12 rows) | yes (true only if the beam tilts; the design-director still confirms) | `tools/band_b.py` (MATH-B-13 balance items) |
| D4 `הוּא לֹא` (11 rows) | yes | `tools/author.py` `TAG_FEEDBACK['M-ORD-CARD']` |
| D5 `אִם לֹא` (6 prompts) | yes; the shape rules also carry the copula `הַצּוּרָה הִיא עִגּוּל` the table had corrected | `tools/band_b2.py` (LOG-B-08); the `HELD` list of `tools/test_hebrew_sources.py` is empty |
| F1 | A (the line matches the picture) | the B-40 line stays |
| F2 | yes (`vo:hint.spot_right.h3` in the 9 spots) | unchanged |
| F3 | yes | unchanged |
| F4 | keep `אֶל` | `he.dart` `adventureWelcome` unchanged |
| F5 | keep `לִלְחֹץ עַל` | unchanged |
| F6 | ok (`לִלְחֹץ עָלָיו` after a number stays) | unchanged |
| S1 to S88 | OK | |
| The rule of part 5 | every row the pass read | 3,233 rows `owner-approved` |

**How the approval is kept.** `docs/review/b36-approved-rows.tsv` lists (source, id, hash of the text, screen text and voice text) of the 3,233 rows
the pass covered: the 3,147 that were `proposed` and the older rows whose text changed with them (the rows not `text-ready`, `owner-approved` or
`unchanged` with the same text and screen text in the table before B-36, plus every row still `proposed`). `tools/hebrew_voice_review.py`
(`b36_approved`) sets `owner-approved` for a row whose hash is in the list; a row whose text or voice text changes later is not in it any more, and goes
back to the editor's own status (`text-ready` or `proposed`). The list is data made once by the editor from the table and read by the script;
the editor never adds a row to it without the owner's word. The `PENDING`, `DOUBT` and Q2/Q3 `PR` entries, the B-40 `pending()` branches and the D1 rules for
`אִמְרוּ` were removed, because their questions are answered.

**Counts.** Master table, 14,434 rows: `owner-approved` 115 before, 3,348 after (115 + 3,233); `proposed` 225 before, 0 after; `text-ready` 13,445 before, 10,437 after;
`unchanged` 649. The 10,437 `text-ready` rows are older rows (M-era, B-13 to B-15) that were never part of this sheet: the pass did not touch them
and the owner did not approve them; they are not `proposed`.

**What stays marked `needs-editor` in the code, and why.** (1) `app/lib/strings/he.dart`: `Str.review` is one getter, `'needs-editor'`, for all
strings; `source_rules_m1_test.dart` pins that it is there and that `'approved'` is not in the file. The repo records an app string's approval only in the master
table (as for `nitziHomeHi` on 2026-10-29), so the bottle lines (B-39) and the refusal message (B-32) are `owner-approved` there. (2) Every pack document has
`"review": "needs-editor"` (1,454 files, written by `tools/author.py`); `starter_pack_test.dart` pins that none is `approved`. (3) The `status` column of the exported
`hebrew-review.csv` says `needs-editor` for every row (it is the raw export). Changing (1) or (2) to a per-string or per-document `approved` marker is a code and
test decision for the app-developer and the owner, not a text decision.

**Also fixed.** `docs/audio/audition/round2.json`: the six `H1-mixed-*` inputs had `אוֹפְּס`; now `אוּפְּס`.

## 17. QA-B36-6: the second hint line of ten second-way items (hebrew-text-editor, 2026-11-01)

QA found that the level 2 line of `b36.numa06.1/.2`, `x.numb07.21/.22`, `b.numb17.13`, `x.mathb17.12/.13`, `b.mathb18.10/.11` and `b.shpb08.10` was the generic
`נִסְתַּכֵּל לְאַט עַל כֻּלָּם, אֶחָד אֶחָד.` over a picture that is new (`app/lib/play/hints/tap_plans_c.dart`, and `tap_plans.dart` for the cube).
Cause: `tools/hint_lines.py` had no class for the new plans (`tap_class` gave `card`, or None, and `retext_b` gave None), so the generator kept the generic line.

**Fixed in the source (`tools/hint_lines.py`), no pack content was written by hand.** New classes, each read the way the Dart plan reads the item:

| Item(s) | Class | Line (shared, one clip) | Voice id |
|---|---|---|---|
| NUM-A-06 with a pile and plates | `plate` | `הָאֶצְבָּעוֹת מַרְאוֹת כַּמָּה צָרִיךְ לָתֵת.` | `vo:hint.plate.h2` |
| NUM-B-07 with drawn numerals (`glyph_N`) | `glyph` | `הִנֵּה הַמִּסְפָּר כָּתוּב נָכוֹן. נִסְתַּכֵּל עָלָיו טוֹב.` | `vo:hint.glyph.h2` |
| MATH-B-17 with a chart of whole-shekel coins | `coin_values` | `לְיַד כׇּל מַטְבֵּעַ כָּתוּב כַּמָּה הוּא שָׁוֶה.` | `vo:hint.coin_values.h2` |
| NUM-B-17 with a pile and no numbers in the question (`_skip`) | `INTWOS_H2` | `כׇּל זוּג בְּטַבַּעַת, וְסוֹפְרִים זוּג אַחַר זוּג.` | `vo:hint.in_twos.h2` |
| MATH-B-18 with a pile and a stone (`_hidden`; a row stays with `_sentence`) | `HIDDEN_H2` | `הַמִּסְגֶּרֶת הִיא הַכֹּל. הַמִּשְׁבְּצוֹת הַמְּלֵאוֹת הֵן מַה שֶּׁרוֹאִים, וְהָרֵיקוֹת — מַה שֶּׁמֻּסְתָּר.` | `vo:hint.hidden_part.h2` |
| SHP-B-08, the cube | `ghost_solid` (level 3 stays `walk`: the item's own sides line) | the existing `vo:hint.solid_outline.h2` | no new clip |

Rules kept: level 2 says what the picture is and never counts aloud where the picture does not; the question has said the numbers, so no line says one;
plural or impersonal; no gender guessed. The NUM-A-06 line says "fingers", so `test_a_line_that_says_fingers_has_hands_on_the_screen` accepts the class `plate`
(the plate plan draws fingers); no pinned count changed. Only these ten files of `content/starter` changed; regeneration is byte-identical on the second run.

Rows: the nine that were `owner-approved` (their hash is no longer in `b36-approved-rows.tsv`) and `b.shpb08.10` (was `text-ready`) are `text-ready` with the comment
`new text (QA-B36-6): waits for the owner` (`QA6_SOURCES` in `tools/hebrew_voice_review.py`; the draft is in `changes`). Master table: `owner-approved` 3,348 to 3,339,
`text-ready` 10,437 to 10,446. The owner's sheet is `docs/review/b36-qa6-owner-sample.md`.

**The owner's answer (2026-11-02, recorded by the hebrew-text-editor).** In chat, verbatim: "Yes, 1–6 OK" (the six families of the sheet; he did not ask for a new line for
`b.numb17.12`, which stays as it is). The ten rows are `owner-approved`. How it is kept: `docs/review/b36-approved-rows.tsv` has the ten `hints.1.caption.0.v` rows with the hash of
their text, screen text and voice text as approved (nine old entries, whose hash no longer matched the new line, got the new hash; `b.shpb08.10` is a new entry; the list has
3,234 rows now, in the order of the master table). `tools/hebrew_voice_review.py` gives these rows the comment `QA6_APPROVED_COMMENT` (the other rows of the list keep
`B36_APPROVED_COMMENT`); if one of the ten lines changes later its hash is not in the list and the row goes back to `text-ready` with the QA-B36-6 comment. Pack, generators
(`tools/hint_lines.py`) and the voice ids are unchanged by the approval; the pack documents stay `"review": "needs-editor"` (§16). Counts, master table (14,434 rows): `owner-approved`
3,339 to 3,349, `text-ready` 10,446 to 10,436, `unchanged` 649. Next for the voice director: the five new clips (`vo:hint.plate.h2`, `vo:hint.glyph.h2`, `vo:hint.in_twos.h2`,
`vo:hint.coin_values.h2`, `vo:hint.hidden_part.h2`); `vo:hint.solid_outline.h2` exists.

**The `בשְׁתַּיִם` and `וְשְׁתַּיִם` rows the security reviewer saw are not errors in the pack.** They are in the `text` column of `hebrew-master.csv`, which keeps the ORIGINAL draft
on purpose (`export-hebrew-review.py` writes the original of a `text-ready` row from the last master table: "the master table's `text` ... depend on it"). The pack and the `ui_text`
column already say `בִּשְׁתַּיִם` (`b.numb17.4/.5/.6`, whose line is now `כׇּל מִסְפָּר גָּדוֹל מֵהַמִּסְפָּר שֶׁלְּפָנָיו בִּשְׁתַּיִם`) and `וּשְׁתַּיִם` (`b.mathb09.7`); the corrections
are the `SUBS` rule of `hebrew_voice_review.py` and the `changes` column says so. The voice text is plain and right. Nothing to fix at the source.

### 17.1 `b.mathb01.15` and `.16`: the third hint line fixed and approved (hebrew-text-editor, 2026-11-02, next-pack)

The voice director found that the third hint (`hints.2`, voice ids `vo:b.mathb01.15.h3` and `.16.h3`) of the two "how many did we add?" items counted everything up to the
total (`שָׁלוֹשׁ וְעוֹד שְׁתַּיִם: אַחַת, שְׁתַּיִם, שָׁלוֹשׁ, אַרְבַּע, חָמֵשׁ. …`), so the last number the child heard was the wrong answer `M-PART-MISS`. I proposed a line that counts
only the added ones (§18.1 on branch `b45-voicing-plan`, commit 78f0887). **The owner read the two texts in chat on 2026-11-02 and said "Fix them"**; the two texts are owner-approved as written.

**Source.** One argument of the `numpick3` call in `tools/band_b.py` (the loop over `('apple', 3, 5), ('fish', 4, 7)`, MATH-B-01):
`h3='%s כְּבָר יֵשׁ. סוֹפְרִים רַק אֶת אֵלֶּה שֶׁהוֹסַפְנוּ: %s. עַכְשָׁו תּוֹרְכֶם — לִלְחֹץ עַל %s.' % (qty(x, OBJECTS[obj]), count_words(r), F[r])`. Regenerated twice, byte-identical.
Changed under `content/`: `starter/activity.b.mathb01.15.json`, `starter/activity.b.mathb01.16.json` and the unit spec `units/band-b-math.json` (the two `h3` values); nothing else.

| Row | Screen text (= `ui_text`) | Voice text |
|---|---|---|
| `activity.b.mathb01.15.json` › `hints.2.caption.0.v` | `שְׁלוֹשָׁה תַּפּוּחִים כְּבָר יֵשׁ. סוֹפְרִים רַק אֶת אֵלֶּה שֶׁהוֹסַפְנוּ: אַחַת, שְׁתַּיִם. עַכְשָׁו תּוֹרְכֶם — לִלְחֹץ עַל שְׁתַּיִם.` | `שְׁלוֹשָׁה תפוחים כבר יש. סופרים רק את אֵלֶּה שהוספנו: אַחַת, שְׁתַּיִם. עכשיו תורכם — ללחוץ על שְׁתַּיִם.` |
| `activity.b.mathb01.16.json` › `hints.2.caption.0.v` | `אַרְבָּעָה דָּגִים כְּבָר יֵשׁ. סוֹפְרִים רַק אֶת אֵלֶּה שֶׁהוֹסַפְנוּ: אַחַת, שְׁתַּיִם, שָׁלוֹשׁ. עַכְשָׁו תּוֹרְכֶם — לִלְחֹץ עַל שָׁלוֹשׁ.` | `אַרְבָּעָה דגים כבר יש. סופרים רק את אֵלֶּה שהוספנו: אַחַת, שְׁתַּיִם, שָׁלוֹשׁ. עכשיו תורכם — ללחוץ על שָׁלוֹשׁ.` |

The voice texts differ from the plain ones in §18.1 in two places, both by rules that already exist and that I checked: `אֵלֶּה` keeps its nikud (V1 audit of 2026-10-29: plain `אלה` can be read `אֵלָה` or `אַלָּה`), and the
counted number word before a noun (`שְׁלוֹשָׁה`) keeps its nikud (number words carry gender).

**Approval, hash-locked as B-36.** The two rows are in `docs/review/b36-approved-rows.tsv` (3,236 rows now) with the hash of the text, screen text and voice text above. `tools/hebrew_voice_review.py` gives them the comment
`H3_COUNT_ADDED_COMMENT` (the owner's words "Fix them"); if either line changes later its hash is not in the list and the row goes back to `text-ready`. Master table (14,434 rows): `owner-approved` 3,349 to **3,351**, `text-ready`
10,434 (the two rows were `proposed` for a moment as new text), `unchanged` 649. The pack documents stay `"review": "needs-editor"`.

**The hint picture does not match the new line (for the app-developer, not changed here).** `MATH-B-01` is in the `add` family (`app/lib/content/hint_ladder.dart`), and `_Plans.add` (`app/lib/play/hints/tap_plans.dart`, line ~1190) has a
count-on picture only when the stage has a second group (`a.group2 != null`). These two items have one group (3 apples, 4 fish) and no second one, so level 3 takes the take-away branch: the hand card shows 3 (4), the hand presses the last
apple (fish) as if one were taken away, and the result badge shows 2 (3). Measured with a test probe on the phone stage: frames `CardMark`, `CardMark + HandMark`, `BadgeMark(2) + HandMark` (`.15`); `BadgeMark(3)` at the end (`.16`). The line now says
"3 apples are already here; we count only the ones we added: one, two". The picture should be: the group of three raised as the hand (it "hugs" into its number, as `docs/curriculum/b40-visual-hint-ladder.md` TA-5 says for MATH-B-01), then
the hand lights two new places beside it, counting 1, 2 (`asksMore` of the existing branch counts that way), ending on the badge 2. The picture was wrong before this fix too (a take-away over an add question).
