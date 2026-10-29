# Voice pronunciation audit, the text side (2026-10-29)

Written by the hebrew-text-editor after the owner's report of 2026-10-29: "some of the pronouncing of the words is
not correct and sounds very robotic". He has not given example words yet; none are guessed here. The sound side
(settings, voices, styles) is the voice-and-sound-director's, in `docs/audio/voice-quality-diagnosis.md`. Nothing was
voiced and nothing was spent.

## 1. The main finding: the corrected voice texts were never used

| What the owner hears | Where its text came from | Proof |
|---|---|---|
| Lesson and core lines, **nitzi and hero-son: 318 lines each**; the other seven friends: 54 each (not 54 for all nine, as `PROGRESS.md` says) | `app/tool/voice_gen.dart` reads the pack caption `caption[0].v` and `content/lines/core.he.json` `text`: **full nikud, every `!`, and the original wording** (`voice_gen_lib.dart:43-67`, sent at `:401`) | `C:\Users\ramfr\nitznutz-voice\<id>\vo.*.mp3` (made 2026-10-28 12:00 to 15:00); the 318 ids map to texts that are all still in `content/starter` and `core.he.json` |
| The 66 reviewed hero-son tutor lines | `content/tutor-lines/hero-son.json` `say` (plain, the **uncorrected** forms: `נספר`, `נגע`, `נתן`, `בוא נסה`) given nikud on the server by the lexicon (`supabase/functions/_shared/tutor_core.ts:420-424`, `verdict.vocalised`) | the lexicon `he-child.v1.json` says "Written with niqqud by Claude; every entry awaits an editor"; prefixes get a fixed table (`hebrew.ts:31-52`) |
| The `cheer` lines (17 `celebrate.*`, `core.celebrate.*`, `core.ceremony.*`) | as above, said with stability 0.1 and style 0.9 (`content/voices.json`) | sound side; see the director's file |

So the `voice_text` column of `docs/review/hebrew-master.csv` (partial nikud, no `!`, corrected words) has **not
reached a single clip**. Of the 318 lesson and core lines, 43 have a wording or pointing correction in the table, 101
were sent with `!`, 31 with a qamatz qatan (`כׇּל`), 6 with a hataf qamats (`צִפֳּרִים`), and all 318 fully pointed.
Of the 66 tutor lines, 49 were voiced from the uncorrected text. Most of what the owner calls "not correct" is very
likely here; how much is the voice itself is the director's question.

## 2. Sources (looked up 2026-10-29)

1. ElevenLabs docs, *Models* (https://elevenlabs.io/docs/overview/models, no date shown): Eleven v4 and v4 Turbo list
   Hebrew (`he`); v4 Turbo has audio tags. Nothing on nikud.
2. ElevenLabs docs, *Controls* (https://elevenlabs.io/docs/best-practices/prompting/controls, no date shown): "Eleven
   v4 and Eleven v3 do not support SSML break tags"; dashes give short pauses and are "less consistent"; ellipses add
   pauses and weight; text normalisation is on by default but smaller models may misread numbers; IPA in slashes
   (`/…/`) for `eleven_v4`; pronunciation dictionaries use phoneme or alias tags.
3. ElevenLabs docs, *Eleven v4 prompting* (https://elevenlabs.io/docs/best-practices/prompting/eleven-v4): "Ellipses
   add pauses and weight", "Capitalization increases emphasis" (no capitals in Hebrew), no SSML breaks; for IPA,
   "generate more than once and choose the best". It does not mention v4 Turbo.
4. ElevenLabs blog, *Introducing Eleven v4* (https://elevenlabs.io/blog/eleven-v4-turbo-in-elevenagents, 2026-09-28,
   updated 2026-10-12): v4 Turbo, 90+ languages, about 100 ms; Hebrew not named; nothing on punctuation.
5. Kolani, Melichov, Calev, Alper, *Phonikud: Hebrew Grapheme-to-Phoneme Conversion for Real-Time TTS*, arXiv
   2506.12311 (June 2025): stress and the vocal shva stay underspecified **even with nikud**; Hebrew stress is mostly
   final (milra), sometimes penultimate (mil'el). (Abstract and project pages read; the full paper was not.)
6. shaharsha, *ElevenLabs TTS skill* (https://openclawdir.com/skills/elevenlabs-tts-2z68ji, undated, third party):
   "Use nikud selectively - only on words where pronunciation is ambiguous." "Full nikud on every word can degrade
   quality." Loanwords and foreign names are often wrong.
7. *Hebrew Nikud reference* skill (https://claudemarket.ai/skills/shaharsha/hebrew-nikud, undated, third party): wrong
   nikud is worse than none, because the voice reads the mistake literally.

**Not verified:** no official ElevenLabs text on Hebrew nikud exists that I could find; whether IPA in slashes works on
`eleven_v4_turbo` (the docs name `eleven_v4`); whether v4 Turbo reads U+05C7 (qamatz qatan) as "o"; how stability 0.1
affects Hebrew. Sources 6 and 7 are practitioners, not ElevenLabs. Every claim below about sound is a **risk to
listen for**, not a measurement.

## 3. Rules: where nikud helps and where it hurts

1. **Full nikud hurts** (sources 6, 7): every mark is read literally, so each pointing mistake becomes a wrong sound,
   and rare marks may be unknown to the model. Our partial-nikud voice text stays the standard: plain full spelling,
   nikud only where the plain word has two readings. **A/B check first** (hand-off H1).
2. **Rare marks.** `כׇּל` (U+05C7) read as plain qamats gives "kal ha-kavod"; `הָאָזְנַיִם` (a qamatz qatan written as a
   plain qamats) gives "aznayim"; `צִפֳּרִים` (hataf qamats) may give "tzipa-rim". The voice text writes `כל`,
   `האוזניים`, `ציפורים`: no rare mark ever goes to the voice.
3. **Dagesh and begadkefat.** A wrong dagesh changes the sound only in ב כ פ: `בְּכּוֹכָב` gives "be-kochav", not
   "be-chochav" (`count.stars.8.h1`). Fixed in the voice text (plain `בכוכב`).
4. **Homographs** keep their nikud: number words (gender: `שְׁנֵי` / `שֵׁנִי`, `שֶׁבַע`, `שֵׁשׁ`), and from this audit
   `שָׂמִים`, `סָפַר`, `גְּדֵלִים`, `בַּתּוֹר`, `אִמְרוּ`, `נְגַלֶּה`, `אֵלֶּה`, `בַּשָּׁמַיִם` (table, V1).
5. **Stress is not in nikud** (source 5). Loanwords are mil'el: `מֵדַלְיָה` me-DAL-ya, `בְּרוֹנְזָה` BRON-za, `רוֹבּוֹט`
   RO-bot, `פִּירָמִידָה` pi-ra-MI-da, `בָּנָנָה` ba-NA-na, `פִּיצָה` PI-tza; `שְׁמוֹנֶה` and `שָׁלוֹשׁ` are final. A wrong
   stress is fixed only by respelling in `content/voices.json` › `pronunciation` (applied by `respelled()`), never in
   the screen text.
6. **Punctuation** (sources 2, 3): `!` shouts (never sent); `…` is the reliable pause on v4; `—` is a short, less
   reliable beat; a colon is often not a pause. A question must end with `?` and should not open with a long clause.
7. **Variables.** `{child}` is never sent; a name is voiced inside a short sentence, never alone (a one-word clip is the
   least stable); the parent hears it once before it is cached (owner question 4).
8. **Numbers** always as pointed words (no digits, no symbols); gender from the noun, bare and counting numbers
   feminine; a number said as the answer ends with a full stop.

## 4. Risk table: the lines voiced today

Status: **TR** = the correction is already `text-ready` in the table (only re-voicing from `voice_text` is missing);
**V1** = new in this audit, `proposed` in the table; **AB** = proposal in this file only, until an A/B listen.

| Ids (voiced) | Sent to the voice | Risk heard | Proposed spoken text | St |
|---|---|---|---|---|
| `celebrate.butterflies`, `.counting_words`, `.giving`, `.more_or_less`, `.numbers_and_things`, `.who_is_first`, `core.celebrate.well`, `core.encourage.fixed` (31 lines with `כׇּל`) | `כׇּל הַכָּבוֹד!` | "kal ha-kavod", shouted, cheer style | `כל הכבוד, ספרתם לאט ובדקתם כל פרפר.` | TR |
| `core.listen.mixed` | `אוֹפְּס, הָאָזְנַיִם … הִתְבַּלְבְּלוּ!` | "aznayim"; `!` | `אוֹפְּס, האוזניים שלי התבלבלו. אפשר להגיד שוב?` | V1 |
| `core.encourage.check`, `core.thinking.think`, `fb.double`, `fb.seq` | `הַמְּמ…` | "ham-m", letters | `המממ… בואו נבדוק.`; A/B with `ממממ…` | TR / AB |
| `celebrate.count_to_ten`, `celebrate.glance_small` | `וַאוּ!` | "va-u" in two syllables | `וואו, ספרתם עד עֶשֶׂר.` | TR |
| `count.stars.8.h1` (`.apples.7.h1`, `.fish.9.h1` have the same slip in ת and ד, no sound change) | `נוֹגְעִים בְּכּוֹכָב אֶחָד` | "be-kochav" | `נוגעים בכוכב אֶחָד, ואומרים מספר אֶחָד.` | TR |
| `count.ladybugs.6.h1`, `count.birds.10.h1` | `בְּחִפּוּשִׁית אֶחָד`, `בְּצִפּוֹר אֶחָד` | wrong gender, heard as a mistake | `נוגעים בחיפושית אַחַת, ואומרים מספר אֶחָד.` | TR |
| `give.apples.3.h3`, `.fish.4.h3`, `.ladybugs.2.h3`, `.stars.5.h3` | `עֲצְרוּ כְּשֶׁהִגַּעְנוּ אֶל` | "atzru", wrong tense | `אַחַת, … חָמֵשׁ. עוצרים כשמגיעים אל חָמֵשׁ. עכשיו תורכם.` | TR |
| `give.apples/fish/ladybugs/stars.*.correct` (4), `celebrate.numbers_and_things`, `pick.numeral.*.correct` (4) | `נָתַתֶּם`, `מָצָאתֶם` | "natatem", "matzatem" | `שָׁלוֹשׁ. נתתם בדיוק כמה שביקשתי.` | TR |
| `flash.*.h2` (8) | `נַחֲזִיק אֶצְבָּעוֹת` | a wrong word (wish luck) | `נרים אצבעות ונספור: אַחַת, שְׁתַּיִם.` | TR |
| `give.*.h1` (4) | `סוֹפְרִים תוֹךְ כְּדֵי` | adult register | `סופרים בזמן שלוקחים.` | TR |
| `same.apples.4v5.prompt`, `same.bugs.3v3.prompt` | `הַאִם יֵשׁ …?` | formal, read as written Hebrew | `יש אותו מספר בִּשְׁנֵי הצדדים?` (listen: rising pitch) | TR |
| `fb.ord`, `fb.size` | `אֵינוֹ`; "more is not always bigger" | formal; says the reverse | `המקום בַּתּוֹר הוא לא כמה יש.`; `fb.size` waits for owner Q2 | TR / V1 |
| `celebrate.nothing_there` | `יָפֶה מְאֹד! אֵין כְּלוּם זֶה אֶפֶס.` | run-on, rule not heard | `יפה מאוד, אין כלום — זה אֶפֶס.` | V1 |
| `ordinal.*` (20), `fb.ord` | `בַּתּוֹר` (sent pointed) | fine as sent; plain `בתור` would read "betor" | keeps `בַּתּוֹר` | V1 |
| `flash.*.h3`, `show.*.correct`, `.h3` | `אֵלֶּה` | fine as sent; plain `אלה` may read "ela" | keeps `אֵלֶּה` | V1 |
| `core.listen.say` | `אִמְרוּ לִי` | fine as sent; plain `אמרו` reads "amru" (they said) | `בבקשה, אִמְרוּ לי.` (or `תגידו לי`, Q5) | V1 |
| `core.thinking.together` | `נְגַלֶּה!` | `!`; plain `נגלה` may read "nigla" | `בואו נְגַלֶּה יחד.` | V1 |
| `core.ceremony.medal`, `.bronze` | `מֵדַלְיָה`, `בְּרוֹנְזָה`, `!`, cheer style | loanword stress; shouted | `הנה מֵדַלְיָה בשבילכם.`; stress by `pronunciation` if wrong | V1 / AB |
| `core.encourage.checked` | `מָּתֵמָטִיקָאִים` | long word for age 3 | waits for owner Q4 (old) | proposed |
| `count.birds.10.h3`, `.fish.9.h3`, `.stars.8.h3`, `.apples.7.h3`, `next.after.6/8.h3` (7 lines, 7 to 10 numbers, up to 25 words) | `אַחַת, שְׁתַּיִם, … עֶשֶׂר. … כַּמָּה: עֶשֶׂר! …` | the most "robotic": a fast flat list, then an instruction | A: as now (commas). B: `אַחַת… שְׁתַּיִם… שָׁלוֹשׁ…` (the pack already does this in `give.butterflies.4.h2`) | AB |
| every voiced line (318) | full nikud | "full nikud can degrade quality" (source 6) | the `voice_text` of the table | TR, H1 |
| hero-son tutor, 49 of 66 | `נספר`, `נגע`, `נתן`, `נאמר`, `בוא נסה` | wrong verb forms ("nispar", "naga") | `נספור`, `ניגע`, `ניתן`, `נגיד`, `בוא ננסה` (group 4 `voice_text`) | TR |
| hero-son tutor: "ניתן **לפרח**", "נעבור **לפרפר** הבא" (5 lines) | the server table gives `לְ` / `בְּ` always | "le-ferach" where Hebrew says "la-perach" (the flower on screen) | point the article: `לַפֶּרַח`, `לַפַּרְפַּר` (H3) | AB |

## 5. Pattern classes in the rest of the table (1,975 distinct voice texts, 6,303 spoken rows)

| Class | Count | Risk | What to do |
|---|---|---|---|
| Number words with nikud inside plain text | 1,036 texts | low; this is the design (gender) | keep; check in the A/B that mixed pointing is read smoothly |
| Counting lists of 6 or more | 61 texts | robotic, rushed | after the A/B (section 4), one rule in `soften()` for lists after `סופרים / נספור … :` |
| Em dash `—` | 339 | a weak, unreliable beat (source 2) | keep; where the beat matters (`עכשיו תורכם — ללחוץ`) a colon or `…` if the A/B shows no pause |
| Questions | 398 | a yes-no question without `האם` lives on its `?` | listen for falling pitch; if flat, put the question first and short (`יש אותו מספר? בואו נבדוק.`) |
| `ועוד` / `פחות` / `שווה` sums | 271 / 73 | `שווה` plain is fine ("shave"); fast sums blur | listen; a comma before `שווה` if they blur |
| `כפול` / `÷` | 0 / 0 | none yet | `÷` still waits for owner Q10 (notes) |
| Loanwords (`רובוט` 9, `פירמידה` 4, `בננה` 4, `פיצה` 1, `ברונזה`, `מדליה`) | 20 | final stress where Hebrew says mil'el | listen; respell in `voices.json` › `pronunciation` (H2) |
| Homographs kept pointed (V1) | 51 texts, 100 rows | the plain form reads as another word | in the table, `proposed` |
| Instruction infinitive `ללחוץ על` | 300 texts | sounds like a manual; an adult says `תלחצו על` | only a question for the owner (Q5); the screen and the voice must not drift apart |
| `{child}` (`homeBubble`) | 1 | a name read wrongly | owner Q4 |

## 6. What the text agent gives the sound agent per line (proposal; no column added yet)

The director's `docs/audio/voice-direction.csv` already holds style, speed, pace and pause notes. These six columns
are the text side's input to it, filled once per distinct `voice_text`:

| Column | Values | Example (`count.stars.8.h3`) |
|---|---|---|
| `intent` | `greet`, `praise`, `encourage`, `hint`, `model-count`, `ask`, `instruct`, `answer` | `model-count` |
| `intonation` | `statement`, `yes-no`, `wh-question`, `list`, `soft-cheer` | `list` then `statement` |
| `emphasis` | 1 or 2 words, exactly as in `voice_text` | `שְׁמוֹנֶה` (the last number) |
| `pauses` | the beats, by the word before them: `after:<word>` | `after:שְׁמוֹנֶה. after:כמה:` |
| `stress` | a word with its stressed syllable, only when not final or a loanword | `מֵדַלְיָה=me-DAL-ya` |
| `name_slot` | `none`, `child-first`, `companion` | `none` |

## 7. What the owner should listen for, and what to ask him

**Listen for:** (1) `כל הכבוד` said "kal"; (2) `האוזניים` said "aznayim" (`core.listen.mixed`, the mic repair); (3) the
hum in `המממ… בואו נבדוק` said as letters; (4) `נוגעים בכוכב` said "be-kochav", and "בחיפושית אחד" (male "one");
(5) "עצרו כשהגענו" in the give-me lessons; (6) "נתתם", "מצאתם" with "na-", "ma-"; (7) "נחזיק אצבעות"; (8) the
ten-number lists (birds, fish, stars); (9) `וַאוּ` in two syllables; (10) the trophy and medal lines (stress, shouting);
(11) whether the yes-no questions rise at the end; (12) the helper (hero-son) saying "nispar", "naga", "le-ferach".

**Ask him, for every line he means:** (a) which land and lesson (the island and the lesson title on the card);
(b) which character spoke (nitzi, hero-son, or a friend's own greeting or cheer); (c) when (the question, a hint after
a mistake, the "correct" line, the end of the lesson, the helper's bubble, a trophy); (d) the word as he heard it and as
it should be (or the caption on screen); (e) wrong *word or vowel*, wrong *stress*, wrong *gender*, too *fast or flat*,
or *shouting*. Two or three examples per kind are enough; with (a) to (c) every clip can be found by its id.

## 8. Hand-offs

- **H1, to voice-and-sound-director:** an A/B listen before any re-voicing: 6 lines (`core.listen.mixed`,
  `celebrate.butterflies`, `count.stars.8.h1`, `count.birds.10.h3`, `same.bugs.3v3.prompt`, `core.ceremony.medal`) in
  three texts each (as sent, full nikud; the table's `voice_text`; `voice_text` with `…` in the list), in nitzi and
  hero-son: about 36 clips, about 1,800 characters (the count needs the owner's typed number). Also A/B the hum
  (`המממ` / `ממממ`) and the cheer style on the 4 ceremony lines. Done when the director writes which text form wins.
- **H2, to voice-and-sound-director:** fill `content/voices.json` › `pronunciation` (respelling, or IPA if it works on
  v4 Turbo) only for words the A/B or the owner shows wrong; I give the respelling of any Hebrew word on request.
- **H3, to app-developer:** (a) `voice_gen` reads the text to voice from the table's `voice_text` (rows `voice-ready`),
  or from a new `vt` field the pack carries, never from the caption; (b) a check that refuses to send `!`, digits,
  Latin letters, `{…}`, U+05C7 or U+05B3, and warns on more than one pointed non-number word in three; (c) tutor lines
  from the 66 reviewed rows are voiced from their group-4 `voice_text`; (d) `vocalisePrefix` in
  `supabase/functions/_shared/hebrew.ts:31` points `וּ` before ב מ פ and a shva, `מֵ` before gutturals, and `לַ` / `בַּ`
  / `כַּ` when the article is swallowed (needs the lexicon to know the definite form); (e) a shared number-to-words
  normaliser (`author.py` `F`, `M`, `NumWords`) for any future `{n}` line. Done when a dry-run plan lists, per line,
  the exact text it will send and it equals `voice_text`. QA verifies; security reviews (d) (gateway).
- **H4, to hebrew-text-editor (me, next):** review the 570 words of `he-child.v1.json` (nikud written by a model, never
  reviewed) and the 5 article cases above.
- **To the orchestrator:** `PROGRESS.md` says 54 lines are voiced; nitzi and hero-son have 318 each.

## 9. Questions for the owner (with my recommendation)

1. **The 100 V1 rows** (homographs kept pointed, a beat in the zero line): agree? *Yes; each fixes a word a voice can
   read as another word.*
2. **Re-voice the 318 + 54 + 66 lines from `voice_text`** once the texts are approved, instead of fixing clip by clip?
   *Yes; it is your plan of 2026-10-28, and the old clips were made from the uncorrected text.*
3. **Counting lists:** commas (quicker) or `…` (slower, like counting on fingers)? *Decide after the A/B (H1).*
4. **The child's name:** voice it inside a short line (`{child}, הבקבוק הגיע.`), let the parent hear it once and type
   a pointed or respelled form if it is wrong? *Yes; never a name alone.*
5. **Spoken instructions:** keep `ללחוץ על …` (as on screen) or say `תלחצו על …` (warmer, spoken), and `תגידו לי` for
   `אמרו לי`? *Keep the screen wording for now; decide after you hear the A/B.*
6. Still open from `hebrew-notes.md`: Q2 (`fb.size`), Q4 (`מתמטיקאים`), Q10 (`÷` read aloud).

## 10. Not checked

No audio was heard or measured. The exact vocalised text the gateway sent for the 66 tutor lines was not seen (it is
on the server); the risk in section 4 is read from the code. The 318 ids were matched to today's pack texts; a text
changed between the voicing (2026-10-28) and today would not show.
