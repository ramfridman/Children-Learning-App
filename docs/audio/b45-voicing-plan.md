# B-45 voicing plan (the whole app, one run)

Written by the voice-and-sound-director on 2026-11-02. **Nothing was generated, sent or paid.** Every number below comes
from the free `voice_gen plan` / `audition-batch plan` run on branch `b45-voicing-plan` today (measured), except where a
line says *read* or *guess*. The number the tool prints on the day is the one you type.

## 0. The short version

| | Clips | Characters | USD (Turbo, list) |
|---|---|---|---|
| Batch 0, pilot (20 test clips) | 20 | 874 | 0.035 |
| Batch 1, Nitzi, every line | 3,991 | 174,772 | 6.99 |
| Batch 2, hero-son, every line | 3,991 | 174,772 | 6.99 |
| Batch 3, seven friends, own lines only | 63 | 1,330 | 0.05 |
| **All four** | **8,065** | **351,748** | **14.07** |

Add 5 percent (about 0.70 USD) for a fix batch after listening. Model `eleven_v4_turbo` (0.04 USD per 1,000 characters,
`content/voices.json`); on `eleven_v4` every USD figure doubles, but you did not choose it.

**What blocks the run today (section 5 has the details):**
1. 2,818 of the 3,991 lines are still `text-ready`, not `owner-approved`. `generate` refuses until all are approved.
2. `voice_gen` cannot yet pick a tone by the end of an id (`.h3`, `.prompt`), and cannot yet say "own lines only" for a friend.
   Two small code changes for the app-developer (section 5).
3. Your decisions in section 8.

Batch 0 needs none of these. You can run it any time.

---

## 1. What gets voiced, and why

The texts of pack 0.11.0 are final. The tool counts one line per `vo:` id, from the pack documents and
`content/lines/core.he.json`, with the `voice_text` of the master table. 3,991 lines per narrator:

| Group | Lines | Characters |
|---|---|---|
| Questions (`.prompt`) | 1,118 | 37,063 |
| Correct answers (`.correct`) | 1,118 | 29,220 |
| Hint 1 and 2 (`.h1`, `.h2`, shared `vo:hint.`) | 301 | 12,803 |
| Hint 3 (`.h3`, the worked steps) | 1,105 | 84,695 |
| Shared "not yet" lines (`vo:fb.`) | 89 | 4,640 |
| End-of-lesson celebrations (`vo:celebrate.`) | 183 | 5,083 |
| The 27 core lines (`vo:core.`) | 27 | 691 |
| Other (a few short ones) | 50 | 577 |
| **Total per narrator** | **3,991** | **174,772** |

(The tone table in section 2 sums the same lines by tone. The group table is for reading.)

**Who says what (the owner's decision Q5, kept):**
- **Nitzi** and **hero-son** each say all 3,991 lines. A friend with a girl's voice borrows Nitzi in the lessons, a friend
  with a boy's voice borrows hero-son (`app/lib/app/companion.dart`).
- **Each friend** says only the 9 lines at the edges of play, in his or her own voice: `core.greeting.hello`,
  `core.greeting.start`, `core.celebrate.well`, `core.placement.done`, `core.goodbye.next`, `core.ceremony.bronze`,
  `.silver`, `.gold`, `.medal`. That is 190 characters a friend. A child never hears two voices take turns inside one
  activity. (`core.rest.goodbye` does not exist yet.)

**Old lines are voiced again, and that is already inside the counts above.** Each narrator has 282 lines that have an old
clip. Every one is voiced again, because the model settings, the 44.1 kHz format, the respelling of "two" and some texts
changed: the plan says "changed 282, unchanged 0". The old clips are not reused and not paid twice. Why: the whole app
must sound like one voice with one tone, not a mix of the old and the new.

**Not in this run:**
- **B-42 daily-welcome lines**: their own batch later, new lines only, so no line is voiced twice (B36 decision 11).
- **The live helper (hero-son tutor lines, 66 rows)** go through the gateway at play time, not through `voice_gen`.
  The gateway still asks for the old 22 kHz format and sends no voice settings (`supabase/functions/_shared/elevenlabs.ts`
  line 49), so they would sound different from the pack. That needs an app-developer change first, then a separate paid
  step you run (prewarm). Not counted here.
- **Music and effects** (B-46) are separate.

---

## 2. The direction (tone per kind of line)

On every v4 model only **stability** and **similarity** reach the voice (style and speed are dropped by the tool), so
"tone" is stability, plus the punctuation of the text that the editor already set. All values are the ones you approved in
round 3 (2026-11-01); similarity is 0.8 everywhere. They are now in `content/voices.json` (`styles`, `styleRules`).

| Kind of line | Stability | Lines | Characters | What it should sound like |
|---|---|---|---|---|
| Question, "not yet", listening (`.prompt`, `vo:fb.`, `core.listen/stuck/breathe`, the try-again `core.encourage`) | 0.60 | 1,220 | 42,083 | calm, curious and kind; a question rises softly; "not yet" is never disappointed |
| Hint 1 and 2 | 0.65 | 299 | 12,645 | short, slow, soft, an invitation; no sigh |
| Hint 3 and worked steps (`.h3`) | 0.70 | 1,107 | 84,853 | the slowest and steadiest; counts and steps even; a small beat at a dash; ends warm |
| Correct, praise, greeting, goodbye, core praise | 0.50 | 1,175 | 29,976 | glad, never a shout |
| Celebration (`vo:celebrate.`, `core.celebrate.`) | 0.35 | 184 | 5,092 | bright but short and even (0.1 was wobbly) |
| Ceremony (`core.ceremony.`) | 0.45 | 4 | 88 | proud and warm |
| Thinking (`core.thinking.`) | 0.55 | 2 | 35 | a thinking hum, then a light line |

The 3,991 lines add up (1,220 + 299 + 1,107 + 1,175 + 184 + 4 + 2).
Pace comes only from punctuation. No line needs more now; the editor's punctuation is final. The old per-line table
`docs/audio/voice-direction.csv` is **superseded** for style and speed (those columns do nothing on v4); its
`pronunciation` and `listen_for` columns still help the listening.

Pronunciation entries now live: `שְׁתַּיִם` and `שתיים` become `שתַּיִם` (choice D). It reaches 420 lines (34,114 characters
per narrator), 356 of them with the word at the start or after a full stop. **Open:** 120 lines (5,636 characters) say
`שווה` in plain letters. See decision 3 and the pilot.

---

## 3. The batches, with exact counts

All counts printed by `dart run tool/voice_gen.dart plan ...` today (with the 2,818 waiting lines counted as if approved,
which is how the tool will count after the editor's step; today's real plan shows only 1,173 lines because it hides the
rest).

| Batch | What | Clips | Characters | USD |
|---|---|---|---|---|
| 0 | Pilot: `audition-batch`, `docs/audio/b45/pilot.json` | 20 | 874 | 0.0350 |
| 1 | `generate nitzi` | 3,991 | 174,772 | 6.9909 |
| 2 | `generate hero-son` | 3,991 | 174,772 | 6.9909 |
| 3 | `generate` for each friend, own 9 lines | 7 x 9 = 63 | 7 x 190 = 1,330 | 0.0532 |

- **Why this order:** the pilot is small and settles the last open sounds (the number two at the start of a sentence and
  in hero-son's voice; the word "equals"; the five new hint clips) before 14 USD is spent. Nitzi first, because she says
  the most. Hero-son second, so what you learn from Nitzi's check is applied before his run. Friends last, they are tiny.
- **Pilot contents** (20 clips, 10 Nitzi and 10 hero-son, real pack lines, final settings): N/H41 the number two as the first
  word; 42 two at the start of a question and again after "ve-OD"; 43 and 44 the same sentence with `שווה` plain, then pointed;
  45 two inside a counted list; 46 to 50 the five new hint clips (`hint.plate.h2`, `hint.glyph.h2`, `hint.in_twos.h2`,
  `hint.coin_values.h2`, `hint.hidden_part.h2`). Each clip says in its `tests` field what to hear.
- **The five new hint clips** are also inside batch 1 and 2 (they are lines of the pack). The pilot only lets you hear them first.
- **A big batch can be stopped.** Every clip is saved as it is made. If the first clips sound wrong, press Ctrl+C: the
  money spent so far is only for the clips made. A rerun types a smaller total (clips already made are skipped).
- **Time:** not measured; ElevenLabs speed for 4,000 clips is unknown to me. Leave the window open and the PC awake.
- **Disk:** `D:` has 410 GB free. Each narrator's folder will be a few hundred MB (*guess*, see decision 6).

---

## 4. The commands you type (Windows PowerShell 5.1, a separate window, not the one where Claude Code runs)

Until this branch is merged, `cd` into the worktree `D:\nitznutz-b45\app`. After the merge use `D:\Children-Learning-App\app`.
The window shows Hebrew in reverse order sometimes; that is only the display.

### 4.0 Once, before batch 1 (free, nothing is deleted)

Put the old work folders aside, so the new run starts clean and no stale old clip (for example a friend's 28 old lesson
lines in Nitzi's old voice) goes into a new voice pack:

```powershell
$v = "$env:USERPROFILE\nitznutz-voice"
New-Item -ItemType Directory -Force "$v\old-before-b45" | Out-Null
foreach ($c in 'nitzi','hero-son','alien-jili','climber-tzuri','compass-romi','friend-daughter','inventor-gali','tower-tamir','weaver-keshet') {
  if (Test-Path "$v\$c") { Move-Item "$v\$c" "$v\old-before-b45\$c" }
  if (Test-Path "$v\$c.voiced.jsonl") { Move-Item "$v\$c.voiced.jsonl" "$v\old-before-b45\" }
}
```

### 4.1 Every window: folder, display, and the free plan

```powershell
cd D:\nitznutz-b45\app
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
```

### 4.2 The key (hidden prompt, stays in this window only). Do it once in each window that runs a paid step

```powershell
$s = Read-Host -AsSecureString 'ElevenLabs key'
$env:ELEVENLABS_API_KEY = [System.Net.NetworkCredential]::new('', $s).Password
Remove-Variable s
```

### 4.3 Batch 0, the pilot

```powershell
dart run tool/voice_gen.dart audition-batch plan ../docs/audio/b45/pilot.json
```

It must end with `Clips to make: 20 of 20`, `Characters of text in total: 874`, `0.0350 USD`. Stop and tell Claude
if not. Then (key set) the paid run, and **type 874**:

```powershell
dart run tool/voice_gen.dart audition-batch run ../docs/audio/b45/pilot.json
```

Clips land in `$env:USERPROFILE\nitznutz-voice\auditions\pilot` (`N41-...mp3` to `H50-...mp3`, each with a `.json` that says what
was sent).

### 4.4 Batch 1, Nitzi (after the blockers of section 5 are done)

```powershell
dart run tool/voice_gen.dart plan --characters nitzi
```

Must show `Lines per voice: 3991` and `characters to send for this voice 174772`, no "cannot be voiced yet" list. Check the
tones once: `dart run tool/voice_gen.dart plan --characters nitzi --list` and look at a `core.celebrate.well` line (stability
0.35) and a `.h3` line (0.7). Then the paid run, and **type 174772** (or whatever the plan printed):

```powershell
dart run tool/voice_gen.dart generate nitzi --pack-version 2.0.0
```

Lands in `$env:USERPROFILE\nitznutz-voice\nitzi\` (`vo.<id>.mp3` and `cue.<id>.json` per line, `pack.json`) and the signed
pack `voice-nitzi-2.0.0.nnpack` in the same folder. The pack is signed at the end with your signing key (the tool reads
the key file before it asks for the count, so a missing key stops it before anything is spent). If it stops half way, run it
again and type the new, smaller number.

### 4.5 Batch 2, hero-son

```powershell
dart run tool/voice_gen.dart plan --characters hero-son
dart run tool/voice_gen.dart generate hero-son --pack-version 2.0.0
```

Type the number the second command prints (174772 if nothing changed).

### 4.6 Batch 3, the friends (own lines; needs the friend-scope change of section 5)

```powershell
dart run tool/voice_gen.dart plan --characters alien-jili,climber-tzuri,compass-romi,friend-daughter,inventor-gali,tower-tamir,weaver-keshet
```

Must show 9 lines and 190 characters for each. Then, one run each, typing 190 each time:

```powershell
dart run tool/voice_gen.dart generate alien-jili --pack-version 2.0.0
dart run tool/voice_gen.dart generate climber-tzuri --pack-version 2.0.0
dart run tool/voice_gen.dart generate compass-romi --pack-version 2.0.0
dart run tool/voice_gen.dart generate friend-daughter --pack-version 2.0.0
dart run tool/voice_gen.dart generate inventor-gali --pack-version 2.0.0
dart run tool/voice_gen.dart generate tower-tamir --pack-version 2.0.0
dart run tool/voice_gen.dart generate weaver-keshet --pack-version 2.0.0
```

(Keshet: see decision 4 first.)

### 4.7 Close the key, always

```powershell
Remove-Item Env:ELEVENLABS_API_KEY
exit
```

---

## 5. Blockers to clear before batch 1 (not before batch 0)

| # | What | Who | Why |
|---|---|---|---|
| P1 | **Texts approved.** 2,818 lines (104,062 characters a voice) come from rows still `text-ready`; the tool voices only `owner-approved`, `voice-ready` or `voiced`, and `generate` refuses while any line waits. Your signature of 0.11.0 is the approval (decision 1; answered conditionally on 2026-11-02: 6,091 rows approved, 445 lines per narrator still wait); after it, the hebrew-text-editor records the spoken rows of the signed pack as `owner-approved` (6,720 spoken rows now `text-ready`). | owner, then hebrew-text-editor | measured |
| P2 | **Tone by the end of an id.** `styleOf` in `app/tool/voice_gen_lib.dart` matches the START of an id only. The rules in `voices.json` that begin with `*` (`*.h3`, `*.h1`, `*.h2`, `*.prompt`) must match the END. Without it, about 2,430 lines (every question, hint 1 to 3; 130,000 of the 174,772 characters) go out at 0.5 instead of 0.60 to 0.70. Change: in `styleOf`, `p.startsWith('*') ? voId.endsWith(p.substring(1)) : voId.startsWith(p)`, with a test. After it, `plan --list` must show stability 0.35 x184, 0.45 x4, 0.5 x1,175, 0.55 x2, 0.6 x1,220, 0.65 x299, 0.7 x1,107. | app-developer | read in code |
| P3 | **A friend's own lines only.** `plan` and `generate` give every character all lines (today every friend would cost 6.99 USD, 48.9 USD for seven). Add to `content/voices.json` `"narrators": ["nitzi","hero-son"]` and `"ownLines": ["vo:core.greeting.hello","vo:core.greeting.start","vo:core.celebrate.well","vo:core.placement.done","vo:core.goodbye.next","vo:core.ceremony.bronze","vo:core.ceremony.silver","vo:core.ceremony.gold","vo:core.ceremony.medal"]`; a character not in `narrators` plans and sends only `ownLines`. The app already falls back to the narrator for any other line. | app-developer | read in code |
| P4 | **The QA test** "every `vo` id has a recording in every shipped voice pack" must allow a friend pack to hold only its 9 own lines (the narrator pack covers the rest). | qa-engineer | read |
| P5 | **ffmpeg** to measure loudness (decision 5). | owner | not installed (measured) |
| P6 | **Pack size**: see decision 6. | infrastructure-engineer | guess |

Batch 0 needs none of these. Batch 1 and 2 need P1 and P2 (and P6 answered). Batch 3 needs P1 and P3.

---

## 6. What you listen for after each batch

Copy a few files to your phone (`.mp3` only; nothing about the children is in them). Listen once on the phone speaker and once
on headphones. Answer like round 3: `ok`, or the clip and what you heard.

**After batch 0 (the pilot), 20 clips:**
- `N41`, `H41`: "shTA-yim. kach sof-RIM." The stress on TA, a clean "sh-t", no gap, no extra syllable. Hero-son too.
- `N42`, `H42`: both twos on TA; the question rises at the end.
- `N43` against `N44` (and `H43` against `H44`): plain `שווה` or pointed `שָׁוֶה`. Say which is "sha-VE". This settles decision 3.
- `N45`, `H45`: two inside a list, even and calm.
- `N46` to `N50` and `H46` to `H50`: the five new hints. Soft, level, nothing counted aloud; `hint.hidden_part.h2` keeps its
  level to the end and the dash is a beat; `hint.coin_values.h2` reads "sha-VE".

**After batch 1 (Nitzi) and again after batch 2 (hero-son), about 25 clips (I choose them by id):**

| Clip id | Listen for |
|---|---|
| `core.greeting.hello`, `core.greeting.start` | warm start, quiet, no click |
| `core.celebrate.well`, `celebrate.growing_towers` | glad and short at 0.35, "g'de-LIM", no wobble |
| `core.ceremony.medal`, `core.ceremony.gold` | proud, "me-DAL-ya" |
| `core.thinking.think` | a hum, not letters |
| `core.listen.mixed`, `fb.ord`, `core.encourage.mistake` | kind and curious, never a scold; the question rises |
| `ordinal.first.prompt`, `.h1`, `.h2`, `.h3` | the ladder gets steadier and slower |
| `b.numb03.8.correct`, `b.mathb09.6.prompt` | the number two (D), at the start |
| `b.mathb01.1.correct` | two in the middle, "equals" |
| `b.logb04.10.h3` | two in a counted list |
| `b.numb05.12.correct` | sixteen, feminine "shesh es-RE" |
| `b.shpb08.10.prompt`, `fb.sqrect.solids` | "ku-BI-ya", "tei-VA", "mal-BEN" |
| `math.time.noon.h3` | "ba-sha-MA-yim" |
| `b.numb14.8.h3` (the longest, 153 characters) | steady to the last word, not rushed |
| `math.size.light.prompt` (the shortest) | not clipped, no click |
| the five `hint.*.h2` | as in the pilot |

**After batch 3:** `tower-tamir`, `climber-tzuri` and one of the Nitzi-voice friends: the greeting and the medal. A male
friend sounds male; Keshet sounds female (decision 4); nothing sounds like a shout.

---

## 7. After the run: my check, and the new pack version

**My check (status `voiced` to `checked`).** For each voice folder I compare, with `ffprobe` and `ffmpeg ebur128`:
1. the clip count equals the line count (3,991, or 9) and every `vo` id has its file and its cue file;
2. each clip's length against its characters (a clip far too short or too long is a clipped word or a run-on);
3. loudness about -16 LUFS, true peak at most -1 dBTP, even across lines;
4. no click or long silence at the start (50 ms) or end (150 ms);
5. the ledger `<voice>.voiced.jsonl` shows the stability and text each clip was sent with (for example a `.h3` clip at 0.7);
6. the text sent: the number two as D in 420 lines, no stray tag, no `!` that was not in the voice text.
This needs **ffmpeg, which is not installed on this PC** (decision 5). Without it I can check only counts, sizes and the
ledger, and I will say so. I do not claim to have heard anything: your listening in section 6 is the listening.

**New pack version.**
- The tool builds and signs each voice pack itself at the end of its `generate` run (`voice-<id>-2.0.0.nnpack`, in the
  voice folder, signed with the pack-signing key in `nitznutz-secrets`). Version **2.0.0** for all nine (the old ones are
  1.2.0 and 1.3.1). The infrastructure-engineer publishes them; the app-developer's pack list picks them up.
- **Order with pack 0.11.0:** the voice packs hold clips for the `vo` ids of 0.11.0 with the texts as signed. Changed lines
  (texts that changed since 0.10.0) would play new words over old captions on a phone that has the old content pack, and
  new lines would be silent. So **publish content 0.11.0 and voice 2.0.0 on the same day**, voice packs after the content pack
  is live and verified. Nothing of the voicing needs the signed pack to *start*, only the owner's approval of the texts (P1);
  but the voice packs must not go out before 0.11.0 does.
- If any text changes after the voicing (it should not), `plan` finds the changed lines and the next run says only those
  (the ledger hashes text, voice, model, settings and format).
- B-42 welcome lines: later, own batch, new voice pack version 2.1.0.

---

## 8. Decisions for you (short, with my recommendation)

1. **Does signing pack 0.11.0 count as your approval of every spoken text in it?** Then the editor marks the 6,720
   spoken `text-ready` rows `owner-approved` after the signing, and 3,991 lines can be voiced. If no: only the 1,173 lines
   already approved (70,710 characters a voice) can be voiced, and 2,818 lines would have no new clip. *Recommend: yes.*
   **Answered 2026-11-02 (recorded by the hebrew-text-editor).** The owner, in chat: "If they are already checked by the text
   agent and the voice agent its fine by me". So the approval is conditional: a spoken row is `owner-approved` only if the editor
   checked it (`text-ready`, not flagged) and the voice director has a direction row for exactly its voice text in
   `docs/audio/voice-direction.csv` with no open ask. Result: **6,091 of the 6,720 spoken rows are `owner-approved`** (6,070 pack
   rows, 21 core rows), hash-locked in `docs/review/b45-approved-rows.tsv`; 629 are held, each with its reason in
   `docs/review/b45-held-rows.tsv` (547 have no direction row because their text is newer than the table of 2026-10-28, 14 carry
   an open ask, 68 are outside the pack: 66 live-helper rows and 2 per-name strings). The free `voice_gen plan` now plans **3,546
   of 3,991 lines per narrator (153,615 characters, was 1,173 lines)** and all 9 lines of each friend; 445 lines per narrator still
   wait, so `generate` still refuses. To release them the voice director must give the 547 rows a direction row and answer the 14
   asks (details: `docs/agents/hebrew-notes.md` section 18; `tools/voice_direction.py` reads only `text-ready` rows, so it must also
   read `owner-approved` before it is rerun). The director's table is per text, made by a script, and nobody has listened; whether
   that is the check the owner meant is for him to say.
2. **One run per narrator (recommended)** or a tool change that lets a run take only part of the lines. The pilot is the safe
   small step already; Ctrl+C is the emergency stop. *Recommend: one run each, no tool change.*
3. **The word "equals" (`שווה`, 120 lines, 5,636 characters):** after the pilot, say "N44 better" or "N43 is fine". If the
   pointed one is better I add the pronunciation entry before batch 1 (no cost). *Recommend: decide from the pilot.*
4. **Keshet (a girl) shares Tamir's male voice.** *Recommend:* give her Nitzi's voice id until you choose a female voice (a
   one-line `voices.json` change, 190 characters, 0.0076 USD). Her own lines then sound female like her lessons. The other four friends who
   share Nitzi's voice (Jili, Romi, the daughter's friend, Gali) stay as they are.
5. **Install ffmpeg** (free: `winget install Gyan.FFmpeg` in PowerShell) so I can measure loudness. *Recommend: yes, before batch 1.*
6. **Voice pack size.** At 44.1 kHz and 64 kbps the old average clip (30 KB at 32 kbps) becomes about 60 KB, so one narrator's
   pack is roughly **240 MB** (*guess*; the old pack of 318 clips was 9.9 MB, measured). Ask the infrastructure-engineer
   whether a pack of that size can be downloaded and stored as it is, or must be split by land or band, **before** batch 1.
   *Recommend: ask first; it does not change the cost.*
7. **ElevenLabs allowance.** The plan's Creator tier lists 275,000 "v4 characters" a month (`docs/PLAN.md`); this run is
   351,748 characters. I have not checked whether Turbo counts at the same rate or half. Look at your usage page. If it would
   pass the allowance, run Nitzi this month and hero-son after the month turns. *Recommend: check the usage page before batch 1.*
8. **The live helper lines (66 rows, gateway)** stay as they are for now and get their own step after an app-developer change
   (format and voice settings). *Recommend: yes, later.*

---

## 9. What waits for others

- **app-developer:** P2 and P3 (small, with tests); later the gateway format and settings for the live helper.
- **hebrew-text-editor:** after your signature, record the spoken rows of the signed pack as `owner-approved` (P1). Nothing to
  change in any text or punctuation: I asked for no punctuation change.
- **qa-engineer:** P4.
- **infrastructure-engineer:** pack size (decision 6) and publishing voice 2.0.0 with content 0.11.0.
- **security-engineer:** nothing new. Only the first-name exception is allowed to go to ElevenLabs; the B-45 lines contain no
  child's name (the per-name `homeBubble` clips are a later step).
