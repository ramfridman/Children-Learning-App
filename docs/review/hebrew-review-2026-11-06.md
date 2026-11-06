# Hebrew review of 2026-11-06 (hebrew-text-editor)

The owner asked on 2026-11-06 for the Hebrew review now (voices later). Nothing was voiced and no money was spent. The editor
changes no status that belongs to the owner: every row below is `text-ready` (the editor is done, the owner has not approved)
or stays `proposed` / `owner-approved` as the owner left it. The rules behind the wording are in `docs/agents/hebrew-notes.md`
(section 11 is new).

## 1. How a correction stays (the B-3 rule)

A correction is made in the **source**, never in a generated file. The chain is:

| Text | Source to edit | Generated from it (never edit by hand) |
|---|---|---|
| Interface strings | `app/lib/strings/he.dart` | (none; the master table reads it) |
| Band A units (counting-hills, math, colours, shapes, logic, robots) | `content/units/<unit>.json` | `content/starter/*.json` (by `tools/author.py`) |
| Band B units | `tools/band_b.py`, `band_b2.py`, `band_b3.py` | `content/units/band-b-*.json`, then `content/starter/*.json` |
| The shared feedback lines per misconception tag | `TAG_FB` and `SIZE_BY_CUE` in `tools/author.py` | the starter feedback of every activity |
| Core lines, helper lines | `content/lines/core.he.json`, `content/tutor-lines/hero-son.json` | (none) |
| The master table (`ui_text`, `voice_text`, `changes`, `status`) | `tools/hebrew_voice_review.py` (`SUBS`, `MANUAL`, `ROW_RULES`, `REVIEWED`, `PENDING`) from `docs/review/hebrew-review.csv` | `docs/review/hebrew-master.csv`, `hebrew-elevenlabs-review.*` |
| `docs/review/hebrew-review.csv` and `.md` | `python tools/export-hebrew-review.py` (reads the pack sources) | not edited by hand |

Order used today: edit the sources, `python tools/regen_content.py`, `python tools/export-hebrew-review.py`,
`python tools/hebrew_voice_review.py`, `python -I tools/test_hebrew_sources.py`. The rule for a done row is that its source text
is the row's `ui_text`; the regeneration test proves that no old text comes back. The 38 rows changed today are recorded in the
script (`ROW_RULES`, "Editor's second pass, 2026-11-06") so the table's `changes` and `comment` columns say what and why.

**One consequence for the orchestrator.** `app/test/starter_pack_test.dart` › "the pack was built from the sources in
content/starter and nothing else" compares the signed bundled pack (`app/assets/packs/starter-0.10.0.nnpack`) with
`content/starter`. 24 files of `content/starter` changed today, so that one test fails until the pack is rebuilt and signed again
by the owner (a new pack version). It is the only failure of the Flutter suite caused by this work (section 6). Merge this branch
only together with a pack rebuild, or into the branch that will carry the next pack (B-36, `next-pack`).

## 2. What was checked

| Area | Rows read | Distinct texts | How | Changed |
|---|---|---|---|---|
| 1. Interface strings (`he.dart`) | 532 (88 child texts with nikud, 444 adult texts) | 532 | every string read in full, then the machine checks (3). 20 strings are new since the last table (Languages screens L1 to L4) and were read for the first time | 6 strings |
| 2a. Counting and Market (domains numbers and math) | 6,345 | 1,778 | every distinct text read as a template (numbers and object nouns folded: 2,219 templates in all, all read by hand), plus the machine checks on every row | 2 texts (14 rows) |
| 2b. Colours | 1,335 | 323 | same | 4 texts (7 rows) + 1 lesson title |
| 2c. Shapes | 1,524 | 285 | same | 0 |
| 2d. Logic | 1,573 | 400 | same | 3 texts (4 lesson rows) |
| 2e. Robots (domain cs) | 516 | 135 | same | 6 correct lines |
| 2f. Parent texts and home activities (adult, no nikud); the 187 adult skill titles | 88 + 187 (these are inside the domain counts above, except the 88) | all | read for plain Hebrew and the generic "הילד" | 0 |
| 2g. Core voice lines, helper (tutor) lines, helper lexicon | 27 + 66 + 122 | 215 | read in full | 0 |
| 3. Languages (Hebrew lines of the English, Hebrew and Russian courses, `island-texts.md`) | 1,466 pointed segments in `docs/languages/**` | n/a | not re-read line by line: they were edited on 2026-11-03 and 2026-11-04 (hebrew-notes §8 to §10) and only English strokes text changed since. Checked again by machine (3) and with `tools/check_hebrew_course_words.py` (156 words of S1 to S8, none needs a later step; hygiene of 4,738 words in six files: the 22 notes are the grammar remarks with a bare suffix). The 51 `he-*` lines of the English course (`english/band-a-content.md` §2) were read again by eye | 0 |
| 4. Alert word lists | 649 | 649 | not touched (group 5: spelling only, the owner's open question 9) | 0 |

(Row counts of 2a to 2f are of `docs/review/hebrew-master.csv`, group 3: 11,381 rows, which are the 1,286 documents of the pack:
967 activities, 175 lessons, 100 skills, 44 misconceptions.)

**Machine checks (3)** run on every pointed text of the table and of the language files (script kept in the session scratchpad,
rules listed here so the next editor can rerun them): canonical (NFC) mark order; a pointed word with no nikud; a singular
imperative to a child; written-register words (`האם`, `אחרת` as "otherwise", `כאשר`, `בלבד`, `אינו`, `עליכם`, `ניתן`);
a dagesh in a בגדכפת letter after `וְ`; `וְ` before a shva; `בְּ / לְ / כְּ` before a shva; `מָה` / `מַה` against the next letter; `כָּל`
instead of `כׇּל`; a shin without its dot; a final letter inside a word; double spaces; questions over 14 words and other lines over
24; a repeated word; number-word gender against the gender of the next plural noun (21 feminine and 27 masculine plural nouns);
symbols and digits in voice texts. The scan found no singular imperative in a child text (the helper's `בוא / בואי / נסה / נסי` lines are the gendered forms on purpose), no number and noun mismatch and no voice text with Latin
letters, digits, `!` or a rare mark (the four lines with `{land}` are the known per-land lines). Everything it flagged and
that was real is in section 3; the rest were false positives (`דּוֹמָה לְ`, `שָׂמָה`, `בּוֹאוּ`).

Not checked: how any line sounds (needs the voice director and audio); whether the Band B number slots read well for every value
(a template was read with one example, the number and noun scan covers the rest); the 135 V1 voice texts (the owner's question).

## 3. Every change (38 rows, 21 distinct texts)

| # | Where (source, id) | Before | After | Why |
|---|---|---|---|---|
| 1 | `he.dart` › `restGoodbye` | …וְנִשְׁחַק שׁוּב אַחַר כָּךְ | …וְנִשְׂחַק שׁוּב אַחַר כָּךְ | the verb "to play" has the **sin** dot (`שִׂחֵק`, `מִשְׂחָק`, as in `נְשַׂחֵק`); with a shin dot `נִשְׁחַק` means "we will be worn down" |
| 2 | `he.dart` › `trophyLockedSemantics` | גביע שעוד לא הרווחנו | גביע שעוד לא זכינו בו | `הרווחנו` is "we profited" (money); a trophy is won: `זכינו בו` |
| 3 | `he.dart` › `medalLockedSemantics` | מדליה שעוד לא הרווחנו | מדליה שעוד לא זכינו בה | same |
| 4, 5 | `he.dart` › `medalExplainerHow`, `medalBugFixerHow` | אֶפְשָׁר יִהְיֶה לְהַרְוִיחַ אוֹתָהּ בְּקָרוֹב | בְּקָרוֹב אֶפְשָׁר יִהְיֶה לִזְכּוֹת בָּהּ | same (a calque of "earn"); the time word first, the sentence reads in one breath |
| 6 | `he.dart` › `courseStoneDoneSemantics` | שיעור שהיה | שיעור שכבר סיימנו | "a lesson that was" is not clear to a screen reader or a parent |
| 7 | `robots.json` › `cs.wrong.wash` › `feedback.correct` | כֵּן! מִבְרֶשֶׁת לֹא צְרִיכָה לִרְחִיצַת יָדַיִם. | כֵּן! לִרְחִיצַת יָדַיִם לֹא צְרִיכָה מִבְרֶשֶׁת. | `צָרִיךְ` means **needs**: the old line said that the brush needs nothing. Turned round like its own hint (`לִרְחִיצַת יָדַיִם צְרִיכִים בָּרֶז…`). 6 items (7 to 12) |
| 8 | `cs.wrong.wash2` | …מִשְׁחָה לֹא צְרִיכָה לִרְחִיצַת יָדַיִם. | כֵּן! לִרְחִיצַת יָדַיִם לֹא צְרִיכָה מִשְׁחָה. | same |
| 9 | `cs.wrong.wash3` | …כּוֹס מַיִם לֹא צְרִיכָה לִרְחִיצַת יָדַיִם. | כֵּן! לִרְחִיצַת יָדַיִם לֹא צְרִיכָה כּוֹס מַיִם. | same |
| 10 | `cs.wrong.teeth` | …סַבּוֹן לֹא צָרִיךְ לְצִחְצוּחַ שִׁנַּיִם. | כֵּן! לְצִחְצוּחַ שִׁנַּיִם לֹא צָרִיךְ סַבּוֹן. | same |
| 11 | `cs.wrong.teeth2` | …מַגֶּבֶת לֹא צְרִיכָה לְצִחְצוּחַ שִׁנַּיִם. | כֵּן! לְצִחְצוּחַ שִׁנַּיִם לֹא צְרִיכָה מַגֶּבֶת. | same |
| 12 | `cs.wrong.teeth3` | …בָּרֶז לֹא צָרִיךְ לְצִחְצוּחַ שִׁנַּיִם בַּתְּמוּנָה. | כֵּן! לְצִחְצוּחַ שִׁנַּיִם בַּתְּמוּנָה לֹא צָרִיךְ בָּרֶז. | same |
| 13 | `colours.json` › `col.world.sun` › `prompt` and `altText` | אֵיזֶה צֶבַע הַשֶּׁמֶשׁ? | מַה צֶּבַע הַשֶּׁמֶשׁ? | "אֵיזֶה צֶבַע הַשֶּׁמֶשׁ" has no verb and no `יֵשׁ`; `מַה צֶּבַע …` is the natural question (dagesh after `מַה`, notes §2.4) |
| 14 | `col.world.grass` | אֵיזֶה צֶבַע הָעֵשֶׂב? | מַה צֶּבַע הָעֵשֶׂב? | same |
| 15 | `col.world.banana.ripe` | אֵיזֶה צֶבַע בָּנָנָה בְּשֵׁלָה? | מַה צֶּבַע בָּנָנָה בְּשֵׁלָה? | same |
| 16 | `col.world.banana` › `hints.2` | זֹאת בָּנָנָה. הִיא יְרֻקָּה… | זוֹ בָּנָנָה. הִיא יְרֻקָּה… | `זֹאת` is written Hebrew; the pack says `זוֹ` everywhere else |
| 17 | `logic.json` › `same-and-different` › title | זֶהֶה וְשׁוֹנֶה | זֵהֶה וְשׁוֹנֶה | the word is `זֵהֶה` (tsere; Hebrew Wiktionary, the Academy); the pack had two pointings (`הַזֵּהֶה` was right) |
| 18 | `same-and-different-again` › title | עוֹד זֶהֶה וְשׁוֹנֶה | עוֹד זֵהֶה וְשׁוֹנֶה | same |
| 19, 20 | both lessons › `celebration` | …מְצָאתֶם מִי זֶהֶה וּמִי שׁוֹנֶה. | …מְצָאתֶם מִי זֵהֶה וּמִי שׁוֹנֶה. | same |
| 21 | `band_b3.py` › `x.mathb19.7/8/9` › `prompt`, `altText` (6 rows) | כַּמָּה יוֹתֵר בָּעַמּוּד הַגָּבוֹהַּ מֵאֲשֶׁר בָּעַמּוּד הַנָּמוּךְ? | בָּעַמּוּד הַגָּבוֹהַּ יֵשׁ יוֹתֵר. כַּמָּה יוֹתֵר? | `מֵאֲשֶׁר` is written Hebrew and the sentence is long for a 6-year-old; two short spoken sentences, the same meaning |
| 22 | `band_b3.py` › tag `M-MONEY-SIZE` › `x.mathb16.1` to `.8` (8 rows) | לֹא הַגֹּדֶל אוֹמֵר כַּמָּה הַמַּטְבֵּעַ שָׁוֶה, אֶלָּא הַמִּסְפָּר שֶׁעָלָיו. בּוֹאוּ נִסְתַּכֵּל. | הַמַּטְבֵּעַ גָּדוֹל אוֹ קָטָן, אֲבָל כַּמָּה הוּא שָׁוֶה? בּוֹאוּ נִסְתַּכֵּל עַל הַמִּסְפָּר שֶׁעָלָיו. | `אֶלָּא` is written Hebrew; and a misconception line names what the eye caught and ends in the strategy **without** `לֹא` (owner Q2, 2026-10-29) |
| 23 | `band_b2.py` › lesson `mix-colours-more` › title | מַה חָסֵר בַּתַּעֲרוֹבֶת | מָה חָסֵר בַּתַּעֲרוֹבֶת | `מָה` before a guttural (ח) keeps the qamats (notes §2.4) |

Voice texts follow by rule (`זו בננה…`, `מה צבע השמש?`, `לרחיצת ידיים לא צריכה מברשת.` and so on); none needed a hand-made voice text.

### Statuses signed in this pass (editor read them, now `text-ready`, waiting for the owner)

| Rows | What | Before |
|---|---|---|
| 20 | the `he.dart` strings of the Languages screens (L1 to L4): `optionSoundSemantics`, `sayDone`, `storyNextSemantics`, `storyEndSemantics`, `listenDoneSemantics`, `personalSaidSemantics`, `personalPassSemantics`, `drumSemantics`, `drumDoneSemantics`, `courseInvite`, `courseVisitSemantics`, `courseNextSemantics`, `courseStoneDoneSemantics` (changed, #6), `courseStoneNextSemantics`, `courseStoneLaterSemantics`, `coursePathSemantics`, `areaVoiceCreditEng`, `areaVoiceCreditRus`, `areaVoiceLicence`, `areaVoiceLicenceClose` | new rows, marked `text-ready` by the group rule without a read |
| 26 | `PENDING` emptied: the B-26 island and home lines (6), the B-39 bottle and land lines with their screen-reader labels (16), the B-15 part 2 rows: the fish and star correct line and the tick hint (4) | `proposed`, "not yet read" |
| 1 | `setupNameBadChars`: the committed master row was shifted by a hand edit (status ` private-use and format characters`, a text in the `correction` column); repaired, the script now gives it `text-ready` | broken row |

Master table now: 12,777 rows: `text-ready` 11,852, `owner-approved` 119, `proposed` 157, `unchanged` 649.
`proposed` is 135 V1 voice-text rows (the pronunciation audit, owner question 3), 12 balance-side drafts (B-13 F8) and 10 Q2 drafts
(NUM-A-07 and NUM-A-11): all three groups wait for the owner, not for the editor.

## 4. Read and kept (so the next pass does not reopen them)

`מַחֲוָג` (clock hand) as the pack spells it; `גְּדֵלִים` (growing) and `נְדַמְיֵן`; `הָאַחֶרֶת` (the other, an adjective, not the
register word); `מְעֻלֶּה`, `וַאוּ`, `מִפְרַץ`, `בְּהַגִּינוּת`, `גָּוֶן` (Band B, ages 6 to 8); `שְׁלֹשׁ עֶשְׂרֵה`, `שְׁתֵּים עֶשְׂרֵה` (feminine
construct before 10); `מַטְבְּעוֹת` with a masculine number (`שְׁלוֹשָׁה מַטְבְּעוֹת`); `הַצַּעַד הַלֹּא נָכוֹן` (Band B, a robot
debugging step, `לֹא` is allowed there); the generic `כִּמְעַט! בּוֹאוּ נְנַסֶּה שׁוּב.` (967 rows, the owner has read it); the adult texts'
generic "הילד" (owner question 5 of hebrew-notes §9.5, still open).

## 5. Questions for the owner (numbered)

1. **Nikud of `זֵהֶה` in an approved title.** The B-15 lesson title `זֶהֶה אוֹ שׁוֹנֶה?` (`lesson.same-and-different-again-1-b15.json`,
   `title.0.v`, owner-approved on 2026-10-30) still has the segol. Its own celebration line and the other two lessons now say
   `זֵהֶה`. May I change it to `זֵהֶה אוֹ שׁוֹנֶה?` (a nikud correction only; the row would then need your OK again)? I did not touch it.
2. **`לֹא` in four more misconception lines (extends your Q2 rule of 2026-10-29).** Proposals, all of the form "what the eye caught,
   then the strategy":
   - `גָּדוֹל לֹא תָּמִיד כָּבֵד. בּוֹאוּ נִשְׁקֹל וְנִרְאֶה.` (12 rows, `band_b.py:492`) → `הוּא גָּדוֹל, אֲבָל כַּמָּה הוּא שׁוֹקֵל? בּוֹאוּ נִשְׁקֹל וְנִרְאֶה.`
   - `מְחַפְּשִׂים אֶת אוֹתוֹ צֶבַע, לֹא אוֹתוֹ דָּבָר.` (29 rows) → `מְחַפְּשִׂים אֶת אוֹתוֹ צֶבַע, גַּם אִם הַדָּבָר שׁוֹנֶה.`
   - `יוֹתֵר לֹא תָּמִיד אוֹמֵר גָּדוֹל יוֹתֵר. בּוֹאוּ נַשְׁוֶה אֶחָד אֶחָד.` (4 rows of the chart item `x.mathb19.1`..`.4`; the sentence is hard to
     follow for a child) → `הַצִּיּוּר גָּדוֹל, אֲבָל כַּמָּה יֵשׁ? בּוֹאוּ נַשְׁוֶה אֶחָד אֶחָד.` This line is the shared `vo:fb.size` of `author.py`; its
     counting-line drafts are already waiting for you (Q2 drafts), so I changed nothing.
   - `הַמָּקוֹם בַּתּוֹר אֵינוֹ כַּמָּה יֵשׁ.` (9 rows, still `אֵינוֹ` in the source because they are V1 rows) → the table's `הַמָּקוֹם בַּתּוֹר לֹא אוֹמֵר כַּמָּה יֵשׁ.`
     is better than the table's current `הוּא לֹא כַּמָּה יֵשׁ`; if you approve the V1 rows I will use it.
   Say "yes" to any of them and the sources are changed in the same way as today.
3. **The 135 V1 rows** (kept nikud in the voice text, pronunciation audit): unchanged, still your question 1 of the audit. They also
   hold three screen texts that the table has already improved but the source does not have yet (`אֵינוֹ`, 7 `M-ORD-CARD` rows).
4. **`כִּמְעַט!` after any second wrong answer** (967 rows): it is warm and the owner has read it, but a far-off answer is not
   "almost". A neutral `בּוֹאוּ נְנַסֶּה שׁוּב.` is the alternative. Keep or change? (Low priority.)
5. **Pack rebuild.** The corrected texts are in `content/starter` but not in the signed pack. Whenever you build the next pack
   version they go in; until then `starter_pack_test` › "the pack was built from the sources" is red on this branch.

## 6. Verification run

| Command | Result |
|---|---|
| `python tools/regen_content.py` | ran; 36 files of `content/` changed (units and starter), all explained by section 3 |
| `python tools/export-hebrew-review.py`, `python tools/hebrew_voice_review.py` | 12,777 rows; the "new since the last table" list is exactly the 20 strings and the changed rows |
| `python -I tools/test_hebrew_sources.py` | 10 tests OK (done rows equal their source; proposed rows keep their text; a second regeneration gives the same bytes). The row-count pin is now 12,777 |
| `python -I tools/check_hebrew_course_words.py` (+ `--text` on six language files) | 156 words, 0 need a later step; 22 hygiene notes, all grammar remarks |
| `dart format --output=none --set-exit-if-changed lib test tool` (after `flutter pub get`) | 482 files, 0 changed |
| `flutter analyze` | No issues found |
| `flutter test` (the content, strings and voice text tests: `content_*`, `course_*`, `starter_pack`, `voice_text`, `word_alert_text`, `rest_rules`, `qa_l_course`, `source_rules_m1`, `home_island_name`, `target_text`) | 313 passed, 1 failed: "the pack was built from the sources in content/starter and nothing else" (expected, section 1) |
| `flutter test` (full suite, 208 test files) | 4,273 passed, 6 skipped, **2 failed**. (1) `hall_ceremony_test` › "the Trophy Hall medals": the golden `hall_medals_phone.png` showed the old text of `medalExplainerHow`; the new text is shorter and now fits on one line (looked at both PNGs: nothing clipped). The golden was regenerated for that test; `--update-goldens` also rewrote four ceremony goldens by sub-pixel noise, which were reverted, so only `app/test/goldens/hall_medals_phone.png` changed; the test passes. (2) `starter_pack_test` › "the pack was built from the sources" (expected, section 1) |
