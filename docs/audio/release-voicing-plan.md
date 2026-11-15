# Release voicing plan (2026-11-08)

Written by the voice-and-sound-director on 2026-11-08, for the owner's request of the same day: a working app to try with
children, after a full Hebrew text sweep, with every voice generated (Hebrew, and the English and Russian course clips).

**Status: a plan. Nothing was generated, sent or paid. No ElevenLabs key was read or used.** Everything below was counted
with free commands (`voice_gen plan`, `voice_gen audition-batch plan`) and with `tools/voicing_inventory.py` (reads files
only). The owner runs every paid command himself in his own PowerShell window and types the number himself (CLAUDE.md).

How sure each statement is: **[M]** measured here by a free command or a script, **[R]** read in the repo or a cited page,
**[G]** my judgement. I cannot hear audio, so nothing here claims that a word sounds right; it says what to listen for.

The counts move while the hebrew-text-editor works in the same tree (the master table changed under my hands twice while
I wrote this). Re-run `python tools/voicing_inventory.py` and `voice_gen plan` before the owner types anything. The
number the tool prints at the gate is the one that counts, not the ones here.

Files of this step:

| File | What |
|---|---|
| `docs/audio/release-voicing-plan.md` | this plan |
| `docs/audio/release-pronunciation-fixes.csv` | 81 rows for the hebrew-text-editor and the generator (id, text, problem, fix, who, status) |
| `docs/audio/audition/round5-sweep-probe.json` | the Hebrew sweep probe: 37 clips, 1,421 characters, 0.0568 USD (spec for `audition-batch`) |
| `tools/voicing_inventory.py` | free counter of the whole release, for every status |
| `tools/hebrew_voice_review.py` | `VOICE_SWEEP_KEEP` (23 starter words) and 14 more `COURSE_KEEP` words, and one `VOICE_SUBS` guard |

---

## 0. The short answer

| | |
|---|---|
| **Lines to voice, Hebrew** [M] | 4,278 voice ids (starter 0.11.0 and the 27 core lines), about **187,000 characters for each narrator** (nitzi, hero-son): **374,000 characters, 14.96 USD** at the Turbo list price in `content/voices.json` (29.93 USD on `eleven_v4`) |
| **Lines in the three language packs** [M] | `plan-lang` with the owner's voices: English 3,446 characters, Russian 3,741, Hebrew 3,973: **11,160 characters, 0.90 USD on v4** (63 English "slow" copies are made by ffmpeg for free; `!` is sent as `.`; the puppets' 20 lines wait for a second-voice option) |
| **Voices of the courses** | The owner chose them on 2026-11-08: English female `qSeXEcewz7tA0Q0qk9fH` and male `Aa6nEBJJMKJwJkCx8VU2`, Russian female `ymDCYd8puC7gYjxIamPt` and male `XuEV9VY3VUASYgJVNBh0` (`content/voices.json`). Female: the main target voice; male: the puppet's own lines; the Hebrew instructions: nitzi (`voices.md` section 11) |
| **Pilots** [M] | The L2 pilots were **never run** (no `en-pilot`, `ru-pilot` folder). With the owner's voices there is **one round**: English 970 characters, Russian 900, Hebrew course 417 + 24, plus the Hebrew probes 1,421 + 1,756: **5,488 characters, 0.35 USD**. The voice-picking round 2 is dropped |
| **Total, everything** | about **396,000 characters**, about **24 USD** with nitzi on v4 and hero-son on Turbo (section 1.6); in five owner sittings (section 4) |
| **Already voiced** | 318 clips each for nitzi and hero-son, 54 for each of the seven friends, and 66 tutor lines. None can be reused (section 1.4): they were made from the old fully pointed captions, with the old settings, and no ledger records them |
| **Blocked today** [M] | `voice_gen generate` refuses the whole run while any line is not approved: **4,151 of 4,278 ids are not** (4,045 `text-ready`, 106 `proposed`; only 127 are `owner-approved`). Two ids carry two or three different texts (`vo:fb.num_rev`, `vo:fb.size`). Section 2 |
| **Tool gaps** [R] | The generator voices every line for every character, has no subset for the friends, no per-land lines, no language-pack path, and does not voice a repeated text once. Five requests for the app-developer, section 5 |
| **Top pronunciation risks** | `תורכם` (786 lines), `המממ`, `ספרות`/`ספרה`/`ספרנו`/`ספרתם`, `נאמר`/`ונמחא`, the course's plural imperatives (`געו`, `הקשיבו`, `גררו`), the name `פיפ`, English `!` and "slow" copies. (Russian `{puppet}` is gone: `ch-menja-zovut` says `Меня́ зову́т Са́ша.`, 2026-11-08.) Section 3 |

---

## 1. The inventory

### 1.1 Hebrew: what the two narrators say [M]

Source: `content/starter` (activity and lesson files, the `vo:` ids), `content/lines/core.he.json`, and the `voice_text` column
of `docs/review/hebrew-master.csv`. `voice_gen` counts one clip for each voice id and sends the voice text of that id.

| Part | Voice ids | Characters for each narrator |
|---|---|---|
| Lesson lines (prompt, hints 1 to 3, feedback, the question lines, `vo:b…`, `vo:c…`, `vo:x…`) | 4,049 | 180,713 |
| End-of-lesson celebration (`vo:celebrate.*`, said in the `cheer` style) | 200 | 5,522 |
| Core lines (`vo:core.*`: greeting, encouragement, listening, goodbye, ceremony) | 27 | 706 |
| **Total** | **4,276 (4,278 with the two collisions)** | **about 187,000** |
| Of these, distinct texts | 2,815 | 135,307 |

- **By status:** 127 ids `owner-approved` (6,587 characters), 106 `proposed` (4,844), 4,045 `text-ready` (175,584). Only the
  first group is voiceable today (`voiceableStatuses` in `voice_text_lib.dart`).
- **The C1 demo line** (`vo:demo…`, 1 id, 27 characters) is in the lesson count; the Band C lines (`vo:c…`, 671 ids,
  43,402 characters) are in it too, as `text-ready`.
- **Repeated texts.** 4,276 ids carry only 2,815 distinct texts: 27 percent of the characters (about 51,700) are the same
  sentence under another id (the hints and corrections of sibling activities). `voice_gen` sends one request per id.
  Voiced once per text, a narrator would cost about 135,300 characters (5.41 USD at Turbo instead of 7.48). Request F1 in
  section 5; the owner may decide to pay the 4 USD instead.
- **Pre-flight.** I built a spec of all 4,278 ids (`from: voice_text`) and ran `audition-batch plan` on it: the pre-flight
  check refuses **none** of them (187,045 characters, 0 refusals). The only characters outside Hebrew letters and points
  are `. , ? : — …` and the four `{land}` lines (below). Longest voice text: 144 characters.
- **What `plan` shows today** (127 ids): `new 126, changed 1` for each of the nine characters, 6,587 characters each, 59,283
  in all, 2.37 USD. That is the figure for the approved rows only, and it multiplies the narrators' set by nine: the tool
  has no "friends' own lines" subset (F2).

### 1.2 Hebrew: lines outside the starter pack

| Lines | Count | Characters (per narrator) | In `voice_gen`? | Note |
|---|---|---|---|---|
| The bottle's lines with a land name: welcome, call for help, same land, other land, for each of 6 lands (`vo:core.adventure.<reason>.<land>`) | 24 | 866 | **no** | the land names are voiced pointed: `גבעות הספירה`, `מפרץ הצבעים`, `יַעַר הצורות`, `מְעָרַת החידות`, `נְמַל הרובוטים`, `כְּפַר השוק` (`hebrew_voice_review.py`, `PER_LAND`) |
| The play-again line, the three language-stop lines, the doors line, the empty bottle (`מה בבקבוק?`) | 6 | 143 | **no** | `languagesDoorsHello` and the three `adventureLang…` are `owner-approved`; the rest `text-ready` |
| **UI total** | **30** | **1,009** | | 2,018 characters for the two narrators, 0.08 USD. The generator reads only the starter pack and `core.he.json`, so a request F3 adds them |
| `homeBubble` (`{child}, מה בבקבוק?`) | 1 per child | about 20 | no (gateway) | the name goes to ElevenLabs inside the line (the owner's decision of 2026-10-25); made on the device, never a repo file. **Not in this plan** |
| hero-son's reviewed tutor lines (gateway, `tutor-prewarm`) | 66 (52 distinct) | about 2,247 | no | voiced already (22.05 kHz, 32 kbps). The gateway still asks for `mp3_22050_32` (`supabase/functions/_shared/elevenlabs.ts:49`). **Leave them until the gateway format is fixed** (F5); then 0.09 USD |
| Each friend's own lines (greeting, start, celebrate-well, placement-done, goodbye, bronze, silver, gold, medal) | 9 | 194 | by the whole-set tool only | seven friends: 1,358 characters, 0.05 USD. A friend that has no recording of its own plays the narrator's (`VoiceBank.withFallback`, `companion.dart:78`), **so the friends can wait until after the children's trial** |

### 1.3 The three language packs [M]

`content/languages/<course>/voice-plan.json`, made by `tools/lang_pack.py`. Each course is its own pack with its own voice.
A line is **one Hebrew clip then one or two target-language clips** (frame §1.3, F3).

| Course | Hebrew frame lines | Characters | Target clips | Characters | Notes |
|---|---|---|---|---|---|
| English | 117 (`vo:eng.he_…`) | 1,605 | 212 (`vo:eng.en_…`) | 2,082 (1,700 for 147 distinct texts) | 63 of the 212 are `-slow` copies of another clip; 68 carry `!`; `review`: all 117 `text-ready` (the editor read the last 5 on 2026-11-08) |
| Russian | 64 | 1,165 | 232 | 2,460 | every word has its stress mark; 38 carry `!`; `ch-menja-zovut` now says `Меня́ зову́т Са́ша.` (no placeholder); all 64 frame lines `text-ready` (the last 15 read on 2026-11-08) |
| Hebrew | 93 (13 have no voice line) | 2,489 | 130 | 1,417 (the pointed `shown`; `say` is empty for 99) | 12 more clips are **cut** from the page clips by word times and are not voiced; all 106 frame lines `text-ready` (the last 25 read on 2026-11-08) |
| **Total** | **274** | **5,259** | **574** | **5,959** | **11,218 as listed; about 10,800 once the English duplicates are voiced once** |

The `pronunciation.csv` of each language has every row `draft` (222, 269 and 279 rows): the `say` forms wait for the pilots.

There is **no generator for these clips yet** (`voice_gen` does not read `voice-plan.json`; `audition-batch` can voice a spec
of clips, but it makes loose files, not a signed pack with cues). Request F4.

### 1.4 What is already voiced, and what is reused [M]

`C:\Users\ramfr\nitznutz-voice\<id>` holds the clips of 2026-10-28 (and the 1.3.1 packs): nitzi 318, hero-son 318, the seven
friends 54 each. All their ids are still in the pack today (318 of 318 and 54 of 54). They are **not reusable**:

1. They were made from the old fully pointed captions in defective spelling, with the old settings and some at 22.05 kHz
   (`docs/audio/voice-quality-diagnosis.md`, section 1). The owner's rule of 2026-10-30 is to voice them again with the new
   texts and tones.
2. There is no ledger file (`<id>.voiced.jsonl`) next to the folders, so `clipState` calls every one of them `changed`: the
   run says them again. Cost: inside the totals above (12,391 characters each for nitzi and hero-son, 1,878 for each friend).
3. `voice_gen` puts **every file in the work folder into the pack**. Old clips of ids that no longer exist would ride along.
   All 318 ids still exist, but rename the old folders before the run all the same (section 4, step 3).

Unchanged and reusable: **none** in the Hebrew set. The 66 tutor lines are the only clips whose text is unchanged; they stay as
they are.

### 1.5 Price [R]

- `content/voices.json`: `"modelId": "eleven_v4_turbo"`, `"listPricePer1000Chars": {"eleven_v4": 0.08, "eleven_v4_turbo": 0.04}`.
  Source: `docs/PLAN.md` (the costs table, line 1202): "Creator: 275,000 v4 characters a month. API rates: v4 $0.08 and v4 Turbo
  $0.04 per 1,000 characters", the same list price as in every earlier plan (`docs/audio/voice-direction.md` section 8, the
  B-45 plan). `voice_gen plan` prints the cost from this file; `--price` overrides.
- **Which model the owner chose after the Hebrew auditions is not written in any repo file I could find** (the rounds 1, 3
  and 4 clips are in `~\nitznutz-voice\auditions`; their scores are not). `voices.json` still says Turbo, so every figure
  here is Turbo, with the v4 figure beside it. **Decision 2** below.
- **Included characters.** The owner's Creator subscription (read 2026-11-08): 363,000 a month, 1,186 used, resetting 2026-12-05 15:42 (PLAN.md's 275,000 is out of date). The Hebrew run alone is 374,000
  characters. Whether the plan counts one credit for a Turbo character or half is a fact on his usage page, not in the repo
  [G]; if it is one, the run needs two months of included characters or paid overage. The list-price USD figures stay the
  comparison.

### 1.6 The model A/B (the owner's listening, 2026-11-08) [R: the owner's scores]

`docs/audio/audition/model-ab.json`: 11 lines, nitzi and hero-son, each on Turbo and on v4 (44 clips, 1,836 characters, 0.1102 USD).
Scores: **nitzi: v4 better on 01 (numbers), 09 (long Band C hint) and 11 (digits); the same on the other eight. hero-son: v4 better on 07
(`שווה`); the same on the other ten. Turbo was never better.** Both models misread three words in both or one voice: `עשר` after a
prefix in "גָּדֵל בְּעֶשֶׂר" (09, hero), `נֹאמַר` in "נֹאמַר את הסדר בקול" (10, both voices) and `עשרות` in "עם עשרות ויחידות" (11, hero).

The three words, with the lines they touch [M] (distinct voice texts in the master table on 2026-11-08):

| Word | Forms in the voice text | Lines | Screen text | Candidate fixes (probe `model-ab-fix.json`) |
|---|---|---|---|---|
| `בְּעֶשֶׂר` (ב + ten) | `בְּעֶשֶׂר` 8 tokens | **3 lines** (also in the 8 tokens: Band B/C "גדול מהמספר שלפניו בְּעֶשֶׂר", "המספר גָּדֵל בְּעֶשֶׂר"); the bare ten `עֶשֶׂר` is 338 tokens in 266 lines and was not reported | `בְּעֶשֶׂר` | **voice-only:** 09a plain `בעשר`; 09b a comma before it (`גָּדֵל, בְּעֶשֶׂר`). **Reword (editor and owner):** 09c "וכל פעם מוסיפים עֶשֶׂר" |
| `נֹאמַר` | 40 tokens | **1 distinct line** (the chant "נֹאמַר את הסדר בקול, וְנִמְחָא כפיים עם כל אֶחָד", under 40 voice ids) | `נֹאמַר` | **voice-only:** 10a `נגיד` (the 2026-10-29 rule already turns "בואו נאמר" into "בואו נגיד"); 10b `נגיד יחד` |
| `עשרות` | `עשרות` 267, `העשרות` 109, `בעשרות` 59, `לעשרות` 4 | **116 lines** (115 voice ids in the earlier snapshot); the misread was in the form "עם עשרות" | `עֲשָׂרוֹת` | **voice-only:** 11a `עֲשָׂרוֹת` pointed; 11b both words pointed (`עֲשָׂרוֹת וִיחִידוֹת`). **Reword:** 11c "במספר יש עשרות ויחידות, ויש רק…" |

If the probe shows a voice-only variant is heard-ok, the change is one line in `tools/hebrew_voice_review.py` (a `VOICE_SUBS` entry for 10a,
or `VOICE_SWEEP_KEEP` for 11a/11b with `עֲשָׂרוֹת`; 09a/09b need a `VOICE_SUBS` pattern for `גָּדֵל בְּעֶשֶׂר`), and the screen text does not change.
I have **not** applied any of them before the probe: a fix I have not heard can make a line worse. Only the owner's ear can pass them.

**Model options** (list price from the plan tool: 187,045 characters for each narrator on a spec of all 4,278 ids, 7.48 USD on Turbo, 14.96 USD on v4):

| Option | nitzi | hero-son | Total, both narrators | The A/B says |
|---|---|---|---|---|
| All Turbo | Turbo 7.48 | Turbo 7.48 | **14.96 USD** | gives up v4's gain on nitzi (3 of 11 pairs) and on hero (1 of 11) |
| **Per voice: nitzi v4, hero-son Turbo** | v4 14.96 | Turbo 7.48 | **22.44 USD** | takes the gain where it was heard most; hero-son loses one pair of eleven |
| All v4 | v4 14.96 | v4 14.96 | **29.93 USD** | takes every gain; 7.5 USD more than the per-voice option for one hero pair |

Grand total of the release (section 4) with each option: **about 16 USD** (all Turbo), **about 23.5 USD** (per voice), **about 31.5 USD** (all v4).
The language packs and pilots stay on v4 in all three (about 1.4 USD). **My recommendation [G]: the per-voice option**, unless the probe
(`model-ab-fix.json`) shows hero-son's v4 clearly better on the three fixed words, in which case all v4 is worth the 7.5 USD.
**`voice_gen` cannot do this today:** the model is one value for all voices (`modelId` in `voices.json`; `VoiceProfile.fromConfig` takes a
`model` only for an audition). A per-voice `modelId` under `voices.nitzi` is a few lines for the app-developer (request F6 below). Until
then, run `generate nitzi` with `modelId` set to `eleven_v4`, then set it back to `eleven_v4_turbo` for hero-son (the owner edits one line of
`content/voices.json` between the two runs; the plan tool prints the cost of the model it will use).

---

## 2. What must happen before any Hebrew batch (free)

1. **The sweep ends and the texts are approved.** `generate` refuses while a single line is not `owner-approved`,
   `voice-ready` or `voiced`. Today: 4,045 `text-ready`, 106 `proposed`. The orchestrator needs one command that sets the
   rows the owner approved to `owner-approved` (the owner's act, not mine, and not the editor's). I do not touch the status
   column.
2. **Two ids with several texts** (fixed by the editor in the table of 2026-11-08: `tools/voicing_inventory.py` now says "blocked until fixed: none"; keep checking). They were: `vo:fb.num_rev` (2 texts) and `vo:fb.size` (3 texts). Each text needs its own
   id (the content author) or the texts become one. Until then the tool says "its rows have N different voice texts" and
   stops the run.
3. **Apply `docs/audio/release-pronunciation-fixes.csv`** (section 3) and run `PYTHONIOENCODING=utf-8 python tools/hebrew_voice_review.py`
   once, after the editor's last change, so that `VOICE_SWEEP_KEEP` reaches the `voice_text` column. A row whose voice text
   changes after the owner approved it must be approved again (the tool keeps the owner's status, so the orchestrator checks
   `git diff` on the voice_text column of the `owner-approved` rows).
4. **Run the sweep probe** (section 4, step 1) and let its results settle the four "open" rows of the CSV.
5. `dart run tool/voice_gen.dart plan --characters nitzi,hero-son` must end with **no** "cannot be voiced yet" list and print the
   figure to be typed. Then and only then the paid run.

---

## 3. Pronunciation review

### 3.1 How I looked [M]

I took the `voice_text` of every spoken row (10,408 rows, 63,721 word tokens, 1,385 distinct words), and:

1. listed the plain (unpointed) words that have two or more pointed forms in the screen text (68 words, 300 lines of output), and
2. checked 70 plain words that I know to be homographs (`ספר`, `שמים`, `בתור`, `לבן`, `קרא`, …) against the corpus, and
3. read the whole list of 1,385 words by eye, and
4. did the same for the 274 Hebrew frame lines of the three courses.

I cannot hear a voice. Every "risk" below is a plain spelling that a Hebrew reader would also stumble on without
context; whether ElevenLabs reads it right is exactly what the probe tests. I did not keep a word pointed that the
probe may show to be fine, except where the **meaning or the gender** changes (a wrong reading is an error, not a
taste).

### 3.2 Already right [M]

- No digit, no Latin letter and no symbol (`=`, `×`, `÷`, `+`) is in any voice text: the numbers are words and the signs are
  spoken as words (`שווה` for `=`, `ועוד`, `פלוס`, `מינוס`). No `כפול` or `חלקי` is in the starter's voice texts yet (Band C lines
  `vo:c…` use `שווה`; a `×` or `÷` line would need `כָּפוּל` and `חֶלְקֵי`/`חלקי`, and the probe has none yet: add one when the
  first appears).
- Number words keep their points (`אֶחָד`, `אַחַת`, `שְׁתַּיִם`, `שְׁתֵּי`, `שְׁנֵי`, `עֶשְׂרֵה`, `עֲשָׂרָה`…; 137 pointed words in all, nearly
  all of them number words), so the gender of a count is fixed in the text.
- No name of a child, of Nitzi, Mika or Pip is in a starter voice text. `{child}` is left out and voiced per child; `{land}` is
  voiced per land (30 UI clips).
- Every "!" was softened to "." or ","; the pre-flight refuses a "!" in a pack line.

### 3.3 What changed in the tools (done by me)

`tools/hebrew_voice_review.py`, tested: `python tools/test_hebrew_sources.py` (12 tests, OK) and a run of `eleven()` over six
sample lines.

1. **`VOICE_SWEEP_KEEP`** (new, 23 words, each with its reason and its token count): `סְפָרוֹת סִפְרָה סִפְרַת וְסִפְרַת סָפַרְנוּ סְפַרְתֶּם
   וּסְפַרְתֶּם נֹאמַר וְנִמְחָא נְחַלֵּק נַחֲלֹק מְשַׁנֶּה מַרְאָה נַעֲשֶׂה נַעֲשָׂה גָּדֵל גֹּדֶל וְגָדַל שֶׁקֶל וְשֶׁקֶל`, and the feminine
   `שׁוֹנָה דּוֹמָה עוֹלָה`. It adds them to `KEEP_POINTED`. It does **not** set the row to `proposed` (unlike the 2026-10-29 audit),
   and a line note in the `changes` column says `voice-sweep 2026-11-08: kept the nikud of …`.
2. **A guard in `VOICE_SUBS`**: `בואו נֹאמַר` still becomes `בואו נגיד` (the 2026-10-29 rule), because `נֹאמַר` is now kept
   pointed and the old rule matched only the plain `נאמר`.
3. **`COURSE_KEEP`** (language courses only, 14 words): `הַקְשִׁיבוּ גְּעוּ וּגְעוּ וְגִרְרוּ וְהַרְאוּ וְעִזְרוּ מִצְאוּ וּמִצְאוּ שִׁמְעוּ חַבְּרוּ תּוֹפְפוּ נִמְחָא שָׁרָה לְפִיפּ`.
   These are the plural imperatives that read the same as a past tense without points, and the name of Pip. The tool has
   no run that writes `course.json`, so the **48 course lines** these words are in are listed with their new voice text in
   the CSV for the editor to apply (status `to-apply`).
4. **`voices.json` `pronunciation`: unchanged (`{}`).** `respelled()` replaces substrings anywhere in a text, so a short Hebrew
   word would also hit longer words that contain it. Every Hebrew case is better solved with a token-exact keep. The
   English and Russian clips need no respelling before the pilots.

### 3.4 The table for the hebrew-text-editor

All rows with id, text, problem and fix are in **`docs/audio/release-pronunciation-fixes.csv`** (81 rows, and 6 the editor added on 2026-11-08, status `text-ready`). The shape:

| Group (status) | Rows | What the editor does |
|---|---|---|
| `tool-done` | 19 | nothing; read them. They are the words above, with an example line, the problem and the count of plain rows |
| `to-apply` | 48 | the 48 course frame lines: replace `voice` with the "fix" column (a pointed instruction verb; `לְפִיפּ`) |
| `open` | 5 | decided by the probe: `המממ` (the fix, if it fails, is `רגע…`), `תורכם`, `אחר`, `ננסה`, the dash |
| `blocker` | 3 | the two multi-text ids (done) and Russian `{puppet}` (done 2026-11-08: the name Са́ша is in the text; status `text-ready`) |
| `spec` / `pilot` | 6 | for the generator and the pilots, not for the editor |

### 3.5 The words at risk, ranked by how many lines they touch

| Word (plain) | Lines / tokens | Risk | What decides it |
|---|---|---|---|
| `תורכם` | 786 / 1,150 | read as "Turkam" or with a wrong vowel (an unusual plain spelling of `תּוֹרְכֶם`) | probe P01, P02: if wrong, keep it pointed (one entry in `KEEP_POINTED`) |
| `ננסה` | / 1,244 | first vowel ("nenase") | probe P03 |
| `אחר` | / 236 | "acher" (other) instead of "achar" (after), in `צעד אחר צעד`, `אחר כך` | probe P04 |
| `ספרנו` | 153 | "sifrenu" (our book) | **kept pointed** |
| `ספרתם` / `ספרת` / `ספרה` / `ספרות` | 65 / 22 / 55 / 71 | "sifrut" (literature) for the digits; "safra" for a digit | **kept pointed** |
| `נאמר` | 63 | "ne'emar" (was said) | **kept pointed** (`נֹאמַר`) |
| `ונמחא` | 40 | a rare verb | **kept pointed** |
| `המממ` | 108 / 4 lines | spelled out or read as a word | probe P05; fallback `רגע…` |
| `—` (em dash) | 736 | a long stop instead of a beat | probe P01 against P02 (comma) |
| `נחלק`, `משנה`, `מראה`, `נעשה`, `גדל` | 10, 6, 4, 4, 5 | meaning changes with the vowels | **kept pointed** |
| `שונה`, `דומה`, `עולה` (feminine) | 1, 8, 2 | masculine reading of a feminine word | **kept pointed** |
| `שווה` | 298 | "shave" (equals); a misread would change the maths sentence | probe P13, P14 |
| `סופרים` | 184 | "soprim" (they count) against "sofrim" (writers) | probe P25; the context should decide |
| `נשווה`, `השווה` | 11, 2 | "nashve" / "hashave" | probe P14 |
| Course imperatives `הקשיבו`, `געו`, `וגררו`, … | 30, 23, 2, … | the past tense or a mooing | **kept pointed** (COURSE_KEEP) |
| `לפיפ` | 3 | final פ read "f" | **kept pointed** (`לְפִיפּ`) |
| The land names | 30 UI clips | `יַעַר`, `מְעָרַת`, `נְמַל`, `כְּפַר` read wrongly if plain | already pointed in the voice text; probe P23 |

Not at risk but worth a line each in the listening check: an ellipsis (305 lines) is a soft beat, never a stop; a colon (895)
a small pause; a question mark (1,568) a gentle rise; the count lists read at an even rhythm with no stress on the last
number; a two-sentence line [G] (many prompts) has a visible pause between the sentences.

### 3.6 English and Russian clips

- **English** (`docs/languages/english/pronunciation.csv`, 222 draft rows). `say` is the word with a full stop (`baby.`): the pilot
  said a bare word is the likeliest to be spelled out. **68 clips carry `!`** (`Hello!`, `Bye!`, `Wow!`, `Yum!`, the chants): the
  pack pre-flight refuses a `!` and v4 shouts it. The generator sends `.` for `!` and keeps the screen text. **63 clips are
  `-slow` copies** with the same text: they would sound the same on v4 (no speed setting), so they are made from the normal
  clip with `ffmpeg -filter:a atempo=0.80` (a free step; the English teacher listens to three before the rest). Check by ear:
  `th`, `w`/`v`, `ship`/`sheep`, a vowel added to a lone stop (`tuh`), `Pip` (a short i, the p released), American `r`, the
  weak vowels in `banana` and `elephant`, `That's OK.` read as "okay".
- **Russian** (269 draft rows). Every multi-syllable word carries U+0301 and `ё` is written (wherever the word has it: `ёжик`, `зелёный`, `пёс`). The open
  question is whether the voice honours U+0301: the Russian pilot has the same word with the mark, without it and in IPA.
  Fatal if heard: uvular р, `ы` as `и`, an unstressed `о` said as a full `о` (`молоко́` with three o), no hard/soft difference
  (`лук`/`люк`), a wrong stress on 3 of 6 words (`docs/languages/voices.md` section 7). `Меня́ зову́т Са́ша.` (`ch-menja-zovut`)
  carries the puppet's name, a fixed character, so no placeholder reaches the pre-flight (2026-11-08).
- **Hebrew course** (279 draft rows). 99 of 130 target clips have no `say`, so the fully pointed `shown` is sent (704 points
  in 1,758 characters). Whether a pointed or a plain text is better is open question 1 of the Hebrew brief; the Hebrew pilot
  has both. Isolated sounds: **no stop is ever voiced alone** (`voices.md` §6); a stretchable sound goes inside a word.

---

## 4. The owner's paid runs, in order

Every command is Windows PowerShell 5.1 (no `&&`). Open **a separate PowerShell window**, not the one where Claude Code runs.
`<REPO>` is the folder of the checkout that has this branch merged (`D:\nitznutz-hebrew-sweep` until it is merged, then your main
checkout); a paid run refuses any other repository.

**Once per window, before the first paid step** (the same two steps as `docs/audio/audition/listening-sheet.md`, section A):

```powershell
cd <REPO>\app
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$s = Read-Host -AsSecureString 'ElevenLabs key'
$env:ELEVENLABS_API_KEY = [System.Net.NetworkCredential]::new('', $s).Password
Remove-Variable s
```

For every step: run its `plan` first (free, no key needed), compare the total with the table, and **type the number the
tool prints at its gate**, never one from this page. If the numbers differ, stop and tell Claude.

### Step 0, free, before any paid step

```powershell
cd <REPO>\app
python ..\tools\voicing_inventory.py
dart run tool/voice_gen.dart plan --characters nitzi,hero-son
```

The second command must end without a "cannot be voiced yet" list before step 3 (section 2).

### Step 1, the probes and the pilots (one sitting, 5,488 characters, 0.35 USD)

Do this first, in this order. It can start today, before the sweep ends: it needs no approved row. The English and Russian voices are the owner's own
(`lang-en-female`, `lang-en-male`, `lang-ru-female`, `lang-ru-male` in `content/voices.json`, chosen 2026-11-08), so there is **no voice-picking round**: one
pilot per language, with the full content, for his two voices (`docs/languages/voices.md` section 11). The pilot is the isolated-sound test (D2) and the teachers'
listening check.

| # | Plan (free) | Run (paid) | Clips | Characters | USD (list) | You type |
|---|---|---|---|---|---|---|
| 1a | `dart run tool/voice_gen.dart audition-batch plan ../docs/audio/audition/round5-sweep-probe.json` | `dart run tool/voice_gen.dart audition-batch run ../docs/audio/audition/round5-sweep-probe.json` | 37 | 1,421 | 0.0568 (Turbo) | `1421` |
| 1b | `… plan ../docs/audio/audition/model-ab-fix.json` | `… run ../docs/audio/audition/model-ab-fix.json` | 32 | 1,756 | 0.1054 (both models) | `1756` |
| 1c | `… plan ../docs/languages/english/pilot.json` | `… run ../docs/languages/english/pilot.json` | 142 | 970 | 0.0776 (v4) | `970` |
| 1d | `… plan ../docs/languages/russian/pilot.json` | `… run ../docs/languages/russian/pilot.json` | 134 | 900 | 0.0720 (v4) | `900` |
| 1e | `… plan ../docs/languages/hebrew/pilot.json` | `… run ../docs/languages/hebrew/pilot.json` | 63 | 417 | 0.0334 (v4) | `417` |
| 1f | `… plan ../docs/languages/hebrew/pilot-ipa.json` | `… run ../docs/languages/hebrew/pilot-ipa.json` | 6 | 24 | 0.0019 (v4) | `24` |
| | **Total** | | **414** | **5,488** | **0.3471** | |

(`…` is `dart run tool/voice_gen.dart audition-batch`. 1a and 1b settle the Hebrew words and are the same two probes as before; if 1b was already run, leave it out:
the pilots alone are 2,311 characters, 0.1849 USD.) The files land in `C:\Users\ramfr\nitznutz-voice\auditions\<name>`, with the language in front for a non-Hebrew spec
(`en-pilot`, `ru-pilot`). If a run stops, repeat the same command: a clip whose `.json` has the same hash is not made or paid for again. The free plans
of 1c and 1d name no missing voice: the four ids are in `voices.json`.

**What the English and Russian pilots hold** (142 and 134 clips, two voices each): every isolated sound (English 12, as IPA, stretched, written long, and the
four most important at stability 1.0), the CV units, robot talk, the minimal pairs (wet/vet, three/tree, ship/sheep, man/men, hat/hot/hut, sing/sin;
Russian лук/люк and the hard/soft pairs), the stress words (banana, elephant; Russian молоко́, with and without U+0301, and one in IPA), the chunks, and the Hebrew
frame clips said by the native voice (to judge whether it could carry the Hebrew too).

**Then listen** (I write the listening sheet for each language when the files exist): the owner for Hebrew, a native-level listener for English and Russian, the
teachers' `check` column as the expectation (`docs/languages/voices.md` section 7). Outputs: the probes' heard-ok / heard-wrong per clip, the form of each isolated
sound (D2), whether the native voice also says Hebrew well enough (option A) or nitzi keeps the frame (option B, the default), and pointed or plain for the Hebrew
course. The editor then applies the `open` rows.

### Step 2, dropped

The voice-picking round 2 for English and Russian is no longer needed (the owner chose the voices). The files `english/pilot-round2.json` and
`russian/pilot-round2.json` are deleted. An optional second Hebrew round (`python docs\languages\make_pilot_specs.py round2 --he nitzi,hero-son`; 730 + 24 characters, 0.06 USD) remains for the Hebrew course.

### Step 3, the Hebrew narrators (the big step: about 187,000 characters each)

Needs section 2 done. First move the old folders away, so that no old clip rides into the pack:

```powershell
cd C:\Users\ramfr\nitznutz-voice
Rename-Item nitzi nitzi-old-2026-10-28
Rename-Item hero-son hero-son-old-2026-10-28
cd <REPO>\app
dart run tool/voice_gen.dart plan --characters nitzi,hero-son
dart run tool/voice_gen.dart generate nitzi --pack-version 2.0.0
dart run tool/voice_gen.dart generate hero-son --pack-version 2.0.0
```

| Run | Lines | Characters (about; the tool prints the exact one) | USD at Turbo | USD on v4 |
|---|---|---|---|---|
| `generate nitzi` | 4,278 | 187,000 | 7.48 | 14.96 |
| `generate hero-son` | 4,278 | 187,000 | 7.48 | 14.96 |
| both | | 374,000 | **14.96** | **29.93** |
| both, once per text (request F1) | 2,815 each | 135,300 each | 10.8 | 21.6 |

Each `generate` plans again, prints the plan and asks for the number. If it stops (network, rate limit), run the same command:
it keeps what it made (the ledger) and says only the rest. The time is not measured [G]: plan an hour or more for each
narrator and do not close the window. The result is `voice-nitzi-2.0.0.nnpack` and `voice-hero-son-2.0.0.nnpack` in
`C:\Users\ramfr\nitznutz-voice\<id>`, signed with the owner's pack key (his own step, as for starter 0.11.0).

**Then the listening check (section 6) before the packs go to the phone.** I can describe it and measure lengths; the owner
listens.

### Step 4, the UI lines and the friends (after requests F2 and F3, 3,376 characters, 0.14 USD)

Not needed for the first children's trial: the bottle's lines are text-only if no clip is found
(`adventure_line.dart`: "the line is then only written") and the friends play the narrator's clips. When F2 and F3 are built:

```powershell
dart run tool/voice_gen.dart plan --characters nitzi,hero-son --lines ui
dart run tool/voice_gen.dart generate nitzi --lines ui --pack-version 2.0.1
dart run tool/voice_gen.dart generate hero-son --lines ui --pack-version 2.0.1
dart run tool/voice_gen.dart plan --characters alien-jili,climber-tzuri,compass-romi,friend-daughter,inventor-gali,tower-tamir,weaver-keshet --lines own
```

(the `--lines` option does not exist today; the names are a proposal for the app-developer; the owner types what the plan prints).

### Step 5, the language packs (11,160 characters, 0.90 USD on v4)

Free plans with the owner's voices (`plan-lang`; the Hebrew frame lines are said by nitzi; `!` is sent as `.`; the 63 English `-slow` clips are made from the normal
clips by ffmpeg, free; the cut words of the Hebrew pack are cut from their page clip):

| Course | Command | Characters | USD (v4 list) | Needs |
|---|---|---|---|---|
| English | `dart run tool/voice_gen.dart plan-lang eng --voice lang-en-female --frame-voice nitzi --model eleven_v4` | 3,446 (3,405 sent: 2 clips share a text) | 0.28 | ffmpeg |
| Russian | `dart run tool/voice_gen.dart plan-lang rus --voice lang-ru-female --frame-voice nitzi --model eleven_v4` | 3,755 | 0.30 | ffmpeg not needed; the plan has no refusal now (`vo:rus.ch_menja_zovut` says `Меня́ зову́т Са́ша.`) |
| Hebrew | `dart run tool/voice_gen.dart plan-lang heb --voice nitzi --model eleven_v4` | 4,011 | 0.32 | ffmpeg (12 cut words) |
| **Total** | | **11,212** | **0.90** | |

The paid command for each is the same with `generate-lang` and `--pack-version 1.0.0` (the tool prints its plan and asks for the number):

```powershell
dart run tool/voice_gen.dart generate-lang eng --voice lang-en-female --frame-voice nitzi --model eleven_v4 --pack-version 1.0.0
dart run tool/voice_gen.dart generate-lang rus --voice lang-ru-female --frame-voice nitzi --model eleven_v4 --pack-version 1.0.0
dart run tool/voice_gen.dart generate-lang heb --voice nitzi --model eleven_v4 --pack-version 1.0.0
```

Before the paid runs: (1) the pilot has passed and the `say` forms are final; (2) `winget install Gyan.FFmpeg`, then a new PowerShell window; (3) the Russian
puppet line has its own text for Саша (`Меня́ зову́т Са́ша.`; done 2026-11-08); (4) the 5, 15 and 25 frame lines that were `needs-editor` in the three courses
are now `text-ready` (read by the editor on 2026-11-08) and wait for the owner's approval. **The puppets (request F7):** `generate-lang` has one `--voice`; the 20 puppet lines (English 9, Russian 11, 337 characters) are said by the female voice
until a `--puppet-voice` exists. The count and the cost do not change.

### Step 6, later and optional

The 66 tutor lines in the new format (0.09 USD, after F5), the per-child name clips (gateway), and the music/effects work (no
paid step).

### Order at a glance

| Step | What | Characters | USD (list) | Needs |
|---|---|---|---|---|
| 1 | probes and the three pilots | 5,488 | 0.35 | nothing (can start today) |
| 2 | (dropped) | | | |
| 3 | nitzi (v4), hero-son (Turbo) | about 376,000 | 22.4 (section 1.6) | approvals, fixes, probes |
| 4 | UI lines + friends | 3,376 | 0.14 | `--lines` options |
| 5 | language packs | 11,160 | 0.90 | step 1 listened, ffmpeg |
| | **total** | **about 396,000** | **about 24** | |

---

## 4a. The batched schedule (owner's decisions of 2026-11-08: nitzi on `eleven_v4`, hero-son on Turbo; whole groups, so a stop is coherent)

**Why batches.** The monthly character allowance is smaller than the whole run (361,814 credits left until 5 December, read from the owner's subscription, against about 376,000 characters for the two
narrators and about 399,000 with everything). So the run is cut into **groups**, each a whole unit that a child meets together, and the
groups are voiced in the order of the children's first tests. If the allowance ends, every group that was started is finished; the rest waits
for the reset. A group is never split.

### 4a.1 The groups [M]

`python tools/voicing_groups.py` writes `docs/audio/voicing-groups.json` (the manifest: group name, voice ids, characters) and prints the
table. A group is the core lines, the end-of-lesson celebrations, or **one land and one band** (the six lands are the skill domains:
numbers, colors, shapes, logic, cs, math). A line that several groups use sits in the **earliest** group, so it is already voiced when a later
group needs it. Characters are for **one narrator** (the same set is said by nitzi and by hero-son). Snapshot of 2026-11-08 evening; the
editor is still changing texts, so re-run the script (and `plan`) before typing a number.

| Group | Ids | Characters | Tier |
|---|---|---|---|
| `core` (greeting, encouragement, listening, goodbye, ceremony) | 27 | 709 | 1 |
| `celebrate` (the end of every lesson, cheer style) | 200 | 5,678 | 1 |
| `numbers-A` | 661 | 27,644 | 1 |
| `colors-A`, `shapes-A`, `logic-A`, `cs-A`, `math-A` | 1002 | 32,156 | 1 |
| **Tier 1, one narrator** | **1890** | **66,187** | |
| `numbers-B` | 762 | 36,814 | 2 |
| `colors-B`, `shapes-B`, `logic-B`, `cs-B` | 492 | 17,696 | 2 |
| `math-B` | 609 | 31,151 | 2 |
| **Tier 2, one narrator** | **1863** | **85,661** | |
| `numbers-C`, `math-C` | 528 | 36,623 | 3 |
| **All, one narrator** | **4281** | **188,471** | |

Outside the narrators' manifest (separate counts, section 1): the pilots and probes (5,488 characters: the sweep probe 1,421, the fix probe 1,756, the English pilot 970, the Russian 900, the Hebrew-course 417 and its IPA 24), the three language packs (eng 3,446, rus 3,741, heb 3,973 = 11,160 as `plan-lang` counts them), the 30 UI lines (1,009 per narrator) and the friends' own nine
lines (194 each, 1,358 for seven). The model-ab clips (1,836 characters) are already spent. The counts come from my script and follow the paid
tool's rule (code points of `voice_text`); the tool's own `plan --groups` figure is the one to type.

### 4a.2 What a child hears while only some groups are voiced [R]

- A line with no recording is **silence**: `VoiceDirector.say` says "a null id or a line with no recording is silence"
  (`app/lib/voice/voice_director.dart:99`), and the lesson screen shows the caption text, which stands alone (a rule of M10 and B-40: the
  hint ladder is also drawn). The mouth stays closed and nothing breaks.
- A friend's lines fall back to **the narrator of the same voice gender** (`VoiceBank.withFallback`, `companion.dart:77`): nitzi for
  a girl-voiced friend, hero-son for a boy-voiced one. A narrator **never** falls back to the other narrator.
- The bottle's lines are "only written" until their clips exist (`adventure_line.dart`).
- So a test with partly voiced groups is **acceptable** for the children's first tests: a lesson of a voiced land and band is fully voiced
  (its prompt, hints, feedback and celebration are in the same or an earlier group); a lesson of an unvoiced group is silent but complete on
  screen. It is not a good test of a lesson's *feel* for an unvoiced group, and the owner should tell the children's helper which lands are voiced.
- One more thing to expect: each batch makes a new voice pack of **everything made so far** (`voice_gen` puts every file of the work folder
  into the pack), so each batch needs a **higher `--pack-version`**; an installed pack of the same version is not replaced.

### 4a.3 The allowance, and does v4 cost more per character than Turbo?

**The owner's subscription (read 2026-11-08, read-only):** tier Creator, **1,186 used of 363,000**, so **361,814 left**, resetting **2026-12-05 15:42** (local).
Month 1 is everything before that moment; month 2 starts with the reset. I keep a **reserve of 18,000** for lines that must be voiced
again after listening, so the month-1 budget is **343,814**.

**The credit rate of v4 is still not written anywhere in the repo or on the pages I found.** `PLAN.md` says "275,000 v4 characters a month" (old
figure; the real limit is 363,000). Third-party write-ups say Flash/Turbo are 0.5 credit a character; none gives v4 or v4 Turbo
([ElevenLabs help](https://help.elevenlabs.io/hc/en-us/articles/35869113958801-How-much-does-it-cost-to-generate-using-Eleven-v3),
[ElevenLabs API pricing](https://elevenlabs.io/pricing/api)). So I show **two cases**:

- **Case A, every model 1 credit a character** (worst case).
- **Case B, Turbo 0.5, v4 1** (hero-son's characters count half, nitzi's and everything else full).

**The 1,186 already used is a clue [G].** The only paid run in this billing period that I know of is `model-ab`: 918 characters on Turbo and 918 on
v4. Case A would have charged 1,836 and case B 1,377; the meter says 1,186 (and it cannot be less than what `model-ab` used, so it is at most
1,186 for those 1,836 characters). So **neither case is exact; the real rates are lower than case A**. One reading that fits within about 1 percent:
v4 about 0.8 and Turbo 0.5 (734 + 459 = 1,193) [G]. Under that reading nitzi's batches are cheaper than in case B. I plan with A and B because they are
the safe pair; the first batch will say which is true.

**After batch 1 (6,000 characters) the usage number tells which case is true.** The owner re-runs the same read-only subscription check
before and after batch 1 and subtracts. Batch 1 is nitzi on v4 (about 6,387 characters), so the difference is v4's rate; batch 2 is hero-son on
Turbo (the same text), so its difference is Turbo's rate. Rate = credits used / characters the tool printed.

### 4a.4 The batches, case A (every model 1 credit a character) [M]

`N` is nitzi (v4), `H` is hero-son (Turbo). Same order as before (the order of the children's first tests; both narrators for each tier).
Month 1 budget 343,814 credits (361,814 left now, 18,000 reserve). Pack versions: one counter for each narrator, starting at 2.0.1, +1 for each batch of that narrator.

| Batch | Voice | Groups | Characters | Credits (case A) | Running total in its month | Month |
|---|---|---|---|---|---|---|
| 0 |  | probes and pilots (step 1) | 5,488 | 5,488 | 5,488 | 1 |
| 1 | N | core,celebrate | 6,387 | 6,387 | 11,875 | 1 |
| 2 | H | core,celebrate | 6,387 | 6,387 | 18,262 | 1 |
| 3 | N | numbers-A | 27,644 | 27,644 | 45,906 | 1 |
| 4 | N | colors-A,shapes-A,logic-A,cs-A,math-A | 32,156 | 32,156 | 78,062 | 1 |
| 5 | H | numbers-A | 27,644 | 27,644 | 105,706 | 1 |
| 6 | H | colors-A,shapes-A,logic-A,cs-A,math-A | 32,156 | 32,156 | 137,862 | 1 |
| 7 |  | languages eng, rus, heb (`generate-lang`) | 11,160 | 11,160 | 149,022 | 1 |
| 8 | N and H | UI lines (`--lines ui`) | 2,018 | 2,018 | 151,040 | 1 |
| 9 | N | numbers-B | 36,814 | 36,814 | 187,854 | 1 |
| 10 | N | colors-B,shapes-B,logic-B,cs-B | 17,696 | 17,696 | 205,550 | 1 |
| 11 | N | math-B | 31,151 | 31,151 | 236,701 | 1 |
| 12 | H | colors-B,shapes-B,logic-B,cs-B | 17,696 | 17,696 | 254,397 | 1 |
| 13 | H | numbers-B | 36,814 | 36,814 | 291,211 | 1 |
| 14 | H | math-B | 31,151 | 31,151 | 322,362 | 1 |
| 15 | N | numbers-C,math-C | 36,623 | 36,623 | 36,623 | 2 |
| 16 | H | numbers-C,math-C | 36,623 | 36,623 | 73,246 | 2 |
| 17 |  | friends: their own 9 lines (F2) | 1,358 | 1,358 | 74,604 | 2 |

**Case A: month 1 uses 322,362 credits** (the batches marked 1), **month 2 (from 5 December) uses 74,604**. Month 1 ends after the last batch above marked 1; the next
batch would not fit whole, so it waits for the reset. The whole release is 396,966 characters, more than the 361,814 left, so in case A
**it does not fit in month 1**.

### 4a.5 The batches, case B (Turbo 0.5 credit, v4 1)

| Batch | Voice | Groups | Characters | Credits (case B) | Running total in its month | Month |
|---|---|---|---|---|---|---|
| 0 |  | probes and pilots (step 1) | 5,488 | 5,488 | 5,488 | 1 |
| 1 | N | core,celebrate | 6,387 | 6,387 | 11,875 | 1 |
| 2 | H | core,celebrate | 6,387 | 3,194 | 15,068 | 1 |
| 3 | N | numbers-A | 27,644 | 27,644 | 42,712 | 1 |
| 4 | N | colors-A,shapes-A,logic-A,cs-A,math-A | 32,156 | 32,156 | 74,868 | 1 |
| 5 | H | numbers-A | 27,644 | 13,822 | 88,690 | 1 |
| 6 | H | colors-A,shapes-A,logic-A,cs-A,math-A | 32,156 | 16,078 | 104,768 | 1 |
| 7 |  | languages eng, rus, heb (`generate-lang`) | 11,160 | 11,160 | 115,928 | 1 |
| 8 | N and H | UI lines (`--lines ui`) | 2,018 | 1,514 | 117,442 | 1 |
| 9 | N | numbers-B | 36,814 | 36,814 | 154,256 | 1 |
| 10 | N | colors-B,shapes-B,logic-B,cs-B | 17,696 | 17,696 | 171,952 | 1 |
| 11 | N | math-B | 31,151 | 31,151 | 203,103 | 1 |
| 12 | H | colors-B,shapes-B,logic-B,cs-B | 17,696 | 8,848 | 211,951 | 1 |
| 13 | H | numbers-B | 36,814 | 18,407 | 230,358 | 1 |
| 14 | H | math-B | 31,151 | 15,576 | 245,934 | 1 |
| 15 | N | numbers-C,math-C | 36,623 | 36,623 | 282,556 | 1 |
| 16 | H | numbers-C,math-C | 36,623 | 18,312 | 300,868 | 1 |
| 17 |  | friends: their own 9 lines (F2) | 1,358 | 1,358 | 302,226 | 1 |

**Case B: month 1 uses 302,226 credits** of the 343,814 budget (plus the 18,000 reserve it is 320,226 of the 361,814 left). **The whole release fits in month 1 under case B**,
with 41,588 credits to spare after the 18,000 reserve.

Under the reading that the 1,186 suggests (v4 about 0.8, Turbo 0.5) nitzi's 188,000 characters cost about 150,000 instead of 188,000, so the whole release
fits in month 1 with even more room, and the order of the batches does not change.

**What to do in either case:** run the batches in the table's order; before each one read the remaining credits; if the next batch's printed
"characters to send" (times its rate) is more than what is left minus the reserve, stop and continue after the reset. Because every batch is whole groups,
nothing is left half done. If case B is true, the batches marked 2 in case A simply move into month 1.

### 4a.6 The owner's commands for a batch

These use options that **do not exist yet** (`--groups`, see the requests in section 5: G1 to G3); until the app-developer adds them
the tool voices all lines in one run (section 4, step 3). The first two lines are the window setup of section 4.

```powershell
cd <REPO>\app
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
# the key, once per window: the hidden prompt of section 4

# batch 1, as the model: nitzi on eleven_v4 (per-voice model, F6)
dart run tool/voice_gen.dart plan --characters nitzi --groups core,celebrate
dart run tool/voice_gen.dart generate nitzi --groups core,celebrate --pack-version 2.0.1
```

`plan` is free; `generate` prints the same plan and asks for the number: type **the "characters to send for this voice" that it prints**
(6345 if nothing changed; the tool's number wins). For the other batches change the character, the `--groups` list and the pack version
as in the table, for example:

```powershell
dart run tool/voice_gen.dart plan --characters hero-son --groups numbers-A
dart run tool/voice_gen.dart generate hero-son --groups numbers-A --pack-version 2.0.2
```

If the owner prefers one command for several batches and the allowance as a cap, request G2 gives `--budget <characters>`; it takes the
groups in the manifest order and stops **before** the first group that would not fit whole.

### 4a.7 How to check that a batch is complete, and what happens if a run stops

- **A stop loses nothing.** Each clip is written (sound and mouth cues) and then recorded in the ledger
  `C:\Users\ramfr\nitznutz-voice\<character>.voiced.jsonl`. Run the **same command again**: the clips already made are `unchanged`, are not
  sent and **not paid**, and the plan shows only the rest as "characters to send" (the number to type is then smaller) [R, `voice_gen_lib.dart`:
  `clipState`, `ClipLedger`]. A clip that was half sent is not recorded and is made again.
- **Free check 1, the tool says so.** After the batch, `dart run tool/voice_gen.dart plan --characters nitzi --groups <the batch's groups>`
  must show `new 0, changed 0` and "Lines still to say: 0". Anything else is a clip that is missing.
- **Free check 2, the files** (counts of the narrator's folder after the batches so far; the old folders were renamed in step 3):

  ```powershell
  $d = 'C:\Users\ramfr\nitznutz-voice\nitzi'
  (Get-ChildItem $d -Filter 'vo.*.mp3').Count
  (Get-ChildItem $d -Filter 'cue.*.json').Count
  Get-ChildItem $d -Filter 'vo.*.mp3' | Where-Object Length -lt 2000
  ```

  The two counts must be equal, and equal to the ids so far for that narrator: **227** after batch 1, **1,890** after batch 6 (tier 1),
  **3,753** after tier 2, **4,281** at the end. The last command lists clips under 2 KB (empty or cut): there must be none.
- **Free check 3, loudness and length, once ffmpeg is installed** (`winget install Gyan.FFmpeg`) [G, not yet run here]:

  ```powershell
  Get-ChildItem $d -Filter 'vo.*.mp3' | ForEach-Object {
    $i = & ffmpeg -hide_banner -nostats -i $_.FullName -af ebur128=peak=true -f null - 2>&1 | Select-String '^\s+I:' | Select-Object -Last 1
    "$($_.Name),$($i.ToString().Trim())"
  } | Out-File "$d\loudness.csv" -Encoding utf8
  ```

  Voices should sit near -16 LUFS within about 2 LU, and no clip should be much louder than the rest. I read the CSV and flag outliers.
- **Listening:** the sample of section 6, in each batch's first groups: 20 lines per tier-1 batch; the first batch of each narrator is
  listened to in full for the core and celebration lines before the next batch starts, so a wrong voice or tone is found at 6,345 characters, not at 187,000.
- **Install only the newest pack** of each narrator on the phone; it holds everything made so far.

---

## 5. Requests for the app-developer (code I do not change)

| # | Request | Why |
|---|---|---|
| F1 | `voice_gen`: say each distinct `voice_text` once per character and copy the file for every other id with the same text. Keep the ledger by id. | saves 51,700 characters per narrator (about 4 USD at Turbo, 8 on v4); optional, the owner may prefer to pay |
| F2 | `voice_gen`: a subset option (`--lines own`) that voices only the 9 own lines of a friend (`core.greeting.hello`, `.start`, `core.celebrate.well`, `core.placement.done`, `core.goodbye.next`, `core.ceremony.*`) | without it each friend costs the whole set (187,000 characters, 7.48 USD) |
| F3 | `voice_gen`: read the UI lines (30 clips, per land) from a source file, for example `content/lines/ui.he.json` with their `vo:core.adventure.*` ids and the land names in the text | they are not in `core.he.json` today |
| F4 | `voice_gen` (or `lang_voice_gen`): read `content/languages/<course>/voice-plan.json`; `language_code` per clip (`he`, `en`, `ru`); `!` to `.`; voice the distinct texts once; make `-slow` by `ffmpeg atempo=0.80`; write the page clips with alignment so the 12 `cutClips` can be cut; refuse a placeholder; the same gate and ledger; build `voice-lang-<course>-<ver>.nnpack` | there is no path at all today |
| G1 | `voice_gen plan` and `generate`: `--groups a,b` (names from `docs/audio/voicing-groups.json`, made by `tools/voicing_groups.py`; `--check` for CI). Only the groups' ids are planned, sent and checked for approval (a line outside the groups does not block the run). The pack holds every clip of the work folder. | batches of whole groups |
| G2 | `--budget <characters>` (optional): take the listed groups in manifest order and stop **before** the first group whose characters to send would exceed the budget; print what is included and what waits; never split a group | the owner stops at the monthly allowance without splitting a group |
| G3 | a free `verify --characters nitzi --groups …`: every id has a sound, a cue and a ledger hash; none is under 2 KB; exit 1 if not (the PowerShell counts of section 4a.7 are the stop-gap) | proof that a batch is complete |
| F6 | `voice_gen`: read an optional `modelId` under `voices.<character>` in `content/voices.json` (a few lines in `VoiceProfile.fromConfig`), and print the model in the plan | the per-voice model option (nitzi v4, hero-son Turbo) |
| F5 | gateway `elevenlabs.ts`: `output_format` `mp3_44100_64` (H1 of the diagnosis) | the tutor lines are 22.05 kHz / 32 kbps and dull the ש, ס and צ |

The qa-engineer's test (every `vo` id of the release has a recording in every shipped voice pack) will fail for the 30 UI lines
and the friends' lessons until F2 and F3 exist, unless the test accepts the narrator fallback for a friend.

---

## 6. The listening check for the Hebrew batch

I cannot listen; I give the owner a short list, in this order, and I measure what I can. **`ffmpeg` and `ffprobe` are not on this
PC [M]** (`which` finds neither), so loudness (target -16 LUFS for a voice, true peak at most -1 dBTP) and lengths cannot be measured
until the owner installs one (`winget install Gyan.FFmpeg`). Until then the check is by ear, and by MP3 frame headers (size and
duration), as in the diagnosis.

1. **Sample, not all.** For each narrator listen to: all 27 core lines, the 9 own lines, 20 celebrations (cheer style), the 30 most
   frequent prompts (a prompt that repeats 786 times must be perfect: `עכשיו תורכם`), every line that holds a kept word of section
   3.3 (about 120), and 60 lines chosen at random across Band A, B and C.
2. **Per clip:** the right voice and the right gender; no clipped word or syllable; no click at the start or the end; no
   breath or noise at the end; the number words read in the right gender and with an even rhythm; the stress of a count list;
   `ספרות` heard as digits; no odd stress on the last word; a question rises gently; a celebration is bright and short, never
   shouting; "not yet" lines are kind, never a scold.
3. **Across clips:** the same loudness for the same kind of line (within about 2 LU); the cheer clips not louder than the usual
   voice by more than 3 dB; the two narrators do not differ in pace by more than 15 percent.
4. **Length and pause budget:** a hint of 14 words is about 8 to 9 s (the measured rate is 1.63 words/s for nitzi and 1.75 for
   hero-son, `voice-quality-diagnosis.md` §1); a line over 10 s is flagged to the editor for a split.
5. A word that sounds wrong goes to the CSV with its line id; the fix is a punctuation change or a kept point (mine and the
   editor's), then that one line is voiced again (a ledger run costs only the changed lines).

---

## 7. Decisions for the owner

1. **Approve the texts.** The sweep ends when the editor says so; then the owner approves the rows (4,151 now), including the
   106 `proposed`. Until then no Hebrew batch can start. (The probe and the pilots can.)
2. **Which model for the Hebrew narrators. DECIDED (2026-11-08): nitzi on `eleven_v4`, hero-son on Turbo** (22.44 USD for the two; needs F6).
   Allowance known: 361,814 left until 2026-12-05 (section 4a.3). Still open: the credit rate of v4 and Turbo, which the first batch will show.
3. **Pay for repeated texts or have the app-developer remove them (F1).** 4 USD at Turbo. Not a quality question.
4. **Languages: DECIDED by the owner's choice of voices (2026-11-08):** one pilot round per language for his two voices (step 1), no voice-picking round 2.
5. **Friends: after the trial?** The children hear the narrator for every friend's lessons today; the friends' own nine lines can wait
   (0.05 USD). The voice for each friend is still the shared one (five characters share Nitzi's voice id, Keshet shares Tamir's);
   the questions 1 to 3 of `voice-direction.md` §12 are still open.
6. **Install ffmpeg** (free) so that I can measure loudness and length of the batch.

## 8. What I did not do

- No paid command, no use of the ElevenLabs key, no audition run, no voice-pool or gateway call.
- I did not change `content/voices.json`, the master table, any course file, the pronunciation CSVs or any app code.
- I did not listen to anything; every "sounds" statement is a hypothesis for the probe.
- The Hebrew audition conclusions of the owner (model, final settings, the "two = D" choice) are not in a repo file I found, so I
  kept `voices.json` as the truth.
- I did not check the ElevenLabs credit rule for Turbo (one or half a credit a character); it is a fact on the owner's usage page.

## 9. Sources

- `docs/PLAN.md` (costs, line 1202; the Voices section), `content/voices.json` (price, model, settings, styles).
- `app/tool/voice_gen.dart` and `voice_gen_lib.dart`, `voice_text_lib.dart`, `audition_lib.dart` (the gate, the ledger, the pre-flight).
- `docs/audio/voice-direction.md` (§1 to §8, the cast and the earlier plan), `docs/audio/voice-quality-diagnosis.md` (§1, formats and rate),
  `docs/audio/audition/listening-sheet.md` (the owner's steps).
- `docs/languages/voices.md` (the pilot design, shortlists, fatal failures), `docs/languages/{english,russian,hebrew}/voice-brief.md`,
  `pronunciation.csv`, `pilot.json`, `pilot-round2.json`, `content/languages/*/voice-plan.json`.
- `docs/agents/voice-pronunciation-audit.md` (the 2026-10-29 audit that this sweep extends).
