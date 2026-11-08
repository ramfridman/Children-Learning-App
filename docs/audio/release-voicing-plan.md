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
| **Lines in the three language packs** [M] | Hebrew frame lines 274 (5,259 characters), target clips 574 (5,959 characters; 5,577 if the 63 English "slow" copies are made by ffmpeg and the duplicates are voiced once). About **10,800 characters, 0.43 USD** (0.87 on v4) |
| **Pilots** [M] | The L2 voice pilots were **never run** (no `en-pilot`, `ru-pilot` or `he-pilot` folder under `~\nitznutz-voice\auditions`; the `voice-plan` is dated 2026-11-03). Round 1 of the three languages and the Hebrew probe: **4,042 characters, 0.27 USD**. Round 2 of English and Russian: about 1,974 characters, 0.15 USD |
| **Total, everything** | about **394,000 characters**, about **16 USD at Turbo, 31.5 USD on v4**, in five owner sittings (section 4) |
| **Already voiced** | 318 clips each for nitzi and hero-son, 54 for each of the seven friends, and 66 tutor lines. None can be reused (section 1.4): they were made from the old fully pointed captions, with the old settings, and no ledger records them |
| **Blocked today** [M] | `voice_gen generate` refuses the whole run while any line is not approved: **4,151 of 4,278 ids are not** (4,045 `text-ready`, 106 `proposed`; only 127 are `owner-approved`). Two ids carry two or three different texts (`vo:fb.num_rev`, `vo:fb.size`). Section 2 |
| **Tool gaps** [R] | The generator voices every line for every character, has no subset for the friends, no per-land lines, no language-pack path, and does not voice a repeated text once. Five requests for the app-developer, section 5 |
| **Top pronunciation risks** | `תורכם` (786 lines), `המממ`, `ספרות`/`ספרה`/`ספרנו`/`ספרתם`, `נאמר`/`ונמחא`, the course's plural imperatives (`געו`, `הקשיבו`, `גררו`), the name `פיפ`, English `!` and "slow" copies, Russian `{puppet}`. Section 3 |

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
| English | 117 (`vo:eng.he_…`) | 1,605 | 212 (`vo:eng.en_…`) | 2,082 (1,700 for 147 distinct texts) | 63 of the 212 are `-slow` copies of another clip; 68 carry `!`; `review`: 112 `text-ready`, 5 `needs-editor` |
| Russian | 64 | 1,165 | 232 | 2,460 | every word has its stress mark; 38 carry `!`; `{puppet}` in `ch-menja-zovut`; 15 frame lines `needs-editor` |
| Hebrew | 93 (13 have no voice line) | 2,489 | 130 | 1,417 (the pointed `shown`; `say` is empty for 99) | 12 more clips are **cut** from the page clips by word times and are not voiced; 25 frame lines `needs-editor` |
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
- **Included characters.** The Creator plan includes 275,000 characters a month [R, PLAN.md]. The Hebrew run alone is 374,000
  characters. Whether the plan counts one credit for a Turbo character or half is a fact on his usage page, not in the repo
  [G]; if it is one, the run needs two months of included characters or paid overage. The list-price USD figures stay the
  comparison.

---

## 2. What must happen before any Hebrew batch (free)

1. **The sweep ends and the texts are approved.** `generate` refuses while a single line is not `owner-approved`,
   `voice-ready` or `voiced`. Today: 4,045 `text-ready`, 106 `proposed`. The orchestrator needs one command that sets the
   rows the owner approved to `owner-approved` (the owner's act, not mine, and not the editor's). I do not touch the status
   column.
2. **Two ids with several texts** must be fixed: `vo:fb.num_rev` (2 texts) and `vo:fb.size` (3 texts). Each text needs its own
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

All rows with id, text, problem and fix are in **`docs/audio/release-pronunciation-fixes.csv`** (81 rows). The shape:

| Group (status) | Rows | What the editor does |
|---|---|---|
| `tool-done` | 19 | nothing; read them. They are the words above, with an example line, the problem and the count of plain rows |
| `to-apply` | 48 | the 48 course frame lines: replace `voice` with the "fix" column (a pointed instruction verb; `לְפִיפּ`) |
| `open` | 5 | decided by the probe: `המממ` (the fix, if it fails, is `רגע…`), `תורכם`, `אחר`, `ננסה`, the dash |
| `blocker` | 3 | the two multi-text ids and Russian `{puppet}` |
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
  (`лук`/`люк`), a wrong stress on 3 of 6 words (`docs/languages/voices.md` section 7). `Меня́ зову́т {puppet}.` has a
  placeholder, which the pre-flight refuses: one clip per puppet name.
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

### Step 1, the sweep probe and the round-1 pilots (one sitting, 4,042 characters, 0.27 USD)

Do this first, in this order. It can start today, before the sweep ends: it needs no approved row. It answers the four open
pronunciation questions, and it picks the voices for English and Russian.

| # | Plan (free) | Run (paid) | Clips | Characters | USD (list) | You type |
|---|---|---|---|---|---|---|
| 1a | `dart run tool/voice_gen.dart audition-batch plan ../docs/audio/audition/round5-sweep-probe.json` | `dart run tool/voice_gen.dart audition-batch run ../docs/audio/audition/round5-sweep-probe.json` | 37 | 1,421 | 0.0568 (Turbo) | `1421` |
| 1b | `… plan ../docs/languages/english/pilot.json` | `… run ../docs/languages/english/pilot.json` | 140 | 1,165 | 0.0932 (v4) | `1165` |
| 1c | `… plan ../docs/languages/russian/pilot.json` | `… run ../docs/languages/russian/pilot.json` | 160 | 1,015 | 0.0812 (v4) | `1015` |
| 1d | `… plan ../docs/languages/hebrew/pilot.json` | `… run ../docs/languages/hebrew/pilot.json` | 63 | 417 | 0.0334 (v4) | `417` |
| 1e | `… plan ../docs/languages/hebrew/pilot-ipa.json` | `… run ../docs/languages/hebrew/pilot-ipa.json` | 6 | 24 | 0.0019 (v4) | `24` |

(`…` is `dart run tool/voice_gen.dart audition-batch`.) The files land in `C:\Users\ramfr\nitznutz-voice\auditions\<name>`, with
the language in front for a non-Hebrew spec (`en-pilot`, `ru-pilot`). If a run stops, repeat the same command: a clip whose
`.json` has the same hash is not made or paid for again.

**Before 1b and 1c, the owner fills voice ids** (free): `content/voices.json` › `voices` › `lang-ru-marina`, `lang-ru-ekaterina`,
`lang-ru-maxim`, `lang-ru-ivan` have an empty `voiceId` (copy the id from the Voice Library after adding the voice to My
Voices), and the four English candidates have ids that come from a third-party list and are **not checked against his account**
(`idStatus: from-third-party-list-unverified`). `audition-batch plan` names every voice that is still missing and `run` sends
nothing until it is filled. If a library voice is gone, replace it by a search (American, female, calm and warm, narration;
Russian, Moscow norm), not by guessing an id.

**Then listen** (I write the listening sheet for each language when the files exist): the owner for Hebrew, a native-level
listener for English and Russian, the teachers' `check` column as the expectation (`docs/languages/voices.md` §7). Outputs: the
probe's heard-ok / heard-wrong per clip, one English and one Russian finalist pair (or one voice), the form of each isolated
sound (D2), and pointed or plain for the Hebrew course. The editor then applies the `open` rows.

### Step 2, round 2 for English and Russian (finalists, about 1,974 characters, 0.15 USD; Hebrew optional)

After step 1, I regenerate the round-2 specs for the finalists:

```powershell
cd <REPO>
python docs\languages\make_pilot_specs.py round2 --en lang-en-sarah,lang-en-matilda --ru lang-ru-marina,lang-ru-maxim --he nitzi,hero-son
cd app
dart run tool/voice_gen.dart audition-batch plan ../docs/languages/english/pilot-round2.json
dart run tool/voice_gen.dart audition-batch run  ../docs/languages/english/pilot-round2.json
dart run tool/voice_gen.dart audition-batch plan ../docs/languages/russian/pilot-round2.json
dart run tool/voice_gen.dart audition-batch run  ../docs/languages/russian/pilot-round2.json
```

(the finalist names above are the placeholders in the files today; they change after step 1). With the placeholders the plan
says English 1,029 characters (0.0800 USD) and Russian 945 (0.0738 USD). The Hebrew round 2 (730 + 24 characters, 0.0580 USD) is
optional: the Hebrew voices are known, only the isolated sounds are new. **To shorten the road to the children's trial, the owner may skip step 2 and
voice the language packs with the round-1 finalists**; I would still run it for the 12 isolated sounds of English (decision 2 of
the Languages frame). That choice is **decision 4** below.

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

### Step 5, the language packs (after F4, about 10,800 characters, 0.43 USD at Turbo, 0.87 on v4)

| Pack | Hebrew frame | Target | Total (as listed) | After dedupe and `slow` by ffmpeg |
|---|---|---|---|---|
| English | 1,605 | 2,082 | 3,687 | 3,305 |
| Russian | 1,165 | 2,460 | 3,625 | 3,625 |
| Hebrew | 2,489 | 1,417 | 3,906 | 3,906 |
| **Total** | 5,259 | 5,959 | **11,218** | **10,836** |

One command for each course and each voice, with the same gate (`generate-lang`, a proposal for F4). The two-voice case (a Hebrew
teaching voice and a native voice) is two runs of the same lines split by language. The count and cost do not depend on it.

### Step 6, later and optional

The 66 tutor lines in the new format (0.09 USD, after F5), the per-child name clips (gateway), and the music/effects work (no
paid step).

### Order at a glance

| Step | What | Characters | USD (Turbo / v4) | Needs |
|---|---|---|---|---|
| 1 | probe + 3 round-1 pilots | 4,042 | 0.27 | nothing (can start today) |
| 2 | round 2 en + ru | about 1,974 | 0.15 | step 1 listened |
| 3 | nitzi, hero-son | about 374,000 | 14.96 / 29.93 | approvals, fixes, probe |
| 4 | UI lines + friends | 3,376 | 0.14 | F2, F3 |
| 5 | language packs | about 10,800 | 0.43 / 0.87 | steps 1 to 2, F4 |
| | **total** | **about 394,000** | **about 16 / 31.5** | |

---

## 5. Requests for the app-developer (code I do not change)

| # | Request | Why |
|---|---|---|
| F1 | `voice_gen`: say each distinct `voice_text` once per character and copy the file for every other id with the same text. Keep the ledger by id. | saves 51,700 characters per narrator (about 4 USD at Turbo, 8 on v4); optional, the owner may prefer to pay |
| F2 | `voice_gen`: a subset option (`--lines own`) that voices only the 9 own lines of a friend (`core.greeting.hello`, `.start`, `core.celebrate.well`, `core.placement.done`, `core.goodbye.next`, `core.ceremony.*`) | without it each friend costs the whole set (187,000 characters, 7.48 USD) |
| F3 | `voice_gen`: read the UI lines (30 clips, per land) from a source file, for example `content/lines/ui.he.json` with their `vo:core.adventure.*` ids and the land names in the text | they are not in `core.he.json` today |
| F4 | `voice_gen` (or `lang_voice_gen`): read `content/languages/<course>/voice-plan.json`; `language_code` per clip (`he`, `en`, `ru`); `!` to `.`; voice the distinct texts once; make `-slow` by `ffmpeg atempo=0.80`; write the page clips with alignment so the 12 `cutClips` can be cut; refuse a placeholder; the same gate and ledger; build `voice-lang-<course>-<ver>.nnpack` | there is no path at all today |
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
2. **Which model for the Hebrew narrators.** `eleven_v4_turbo`, as `voices.json` says: 14.96 USD, half the price, built for speed. Or
   `eleven_v4`: 29.93 USD, "the quality model" [R]. What did you decide in the Hebrew auditions (rounds 1, 3 and 4)? It is not written
   in the repo. If you cannot recall, run step 1a on both models (the probe takes a `model` per clip) and listen once.
3. **Pay for repeated texts or have the app-developer remove them (F1).** 4 USD at Turbo. Not a quality question.
4. **Languages: one round or two.** Round 1 only (faster, 0.27 USD) or round 1 and round 2 (0.42 USD in all, one more listening sitting). I
   recommend round 2 for English and Russian because the isolated-sound test (D2) is in it.
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
