# B-45 voicing plan (the whole app, one run)

Written by the voice-and-sound-director on 2026-11-02. **Nothing was generated, sent or paid.** Every number below comes
from the free `voice_gen plan` / `audition-batch plan` run on branch `b45-voicing-plan` today (measured), except where a
line says *read* or *guess*. The number the tool prints on the day is the one you type.

## 0. The short version

| | Clips | Characters | USD (Turbo, list) |
|---|---|---|---|
| Batch 0, pilot (28 test clips) | 28 | 1,036 | 0.041 |
| Batch 1, Nitzi, every line | 4,166 | 179,315 | 7.17 |
| Batch 2, hero-son, every line | 4,166 | 179,315 | 7.17 |
| Batch 3, seven friends, own lines only (57 each) | 399 | 10,332 | 0.41 |
| **All four** | **8,759** | **369,998** | **14.80** |

**Update, 2026-11-02 evening: the 148 lines of `docs/review/b45-new-lines-2.tsv` are in the run** (the owner said yes): the 48
B-42 daily-welcome lines (`vo:welcome.*`, each friend says them in his or her own voice, `ownLines` is 57) and the 100
map-card lines (`vo:core.skill.<id>`, narrators only). They have their direction row (`docs/audio/voice-direction.csv`,
`docs/audio/b45-direction-checked.tsv`, 148 `directed`, no open ask). Measured with the free `voice_gen plan` on 2026-11-02
(the tool shows the 148 only once the editor has recorded them `owner-approved`; I counted them by marking them so in a
throw-away edit of the master table and put the file back unchanged): **4,166 lines and 179,315 characters per narrator**
(7.17 USD each), **57 lines and 1,476 characters per friend** (0.059 USD each, 0.41 USD for the seven), **all nine voices
368,962 characters, 14.76 USD**, plus the pilot 1,036 characters (0.041 USD) = 369,998 characters, 14.80 USD. The 148 lines
add 16,186 characters (0.65 USD) to the 352,776 characters of the plan before them: 3,592 a narrator (welcome 1,286, map cards
2,306) and 1,286 a friend (the welcome). Each narrator is now **18 voice packs** (two new small ones: `part-welcome` 48 lines and
`part-skill` 100 lines); a friend is still one pack (57 lines).

(Older note, kept for the history: updated on 2026-11-02 for the 27 new core lines of the merge: 25 B-39 bottle lines, `core.rest.goodbye`,
`core.home.bubble`, 951 characters a voice. The two fixed MATH-B-01 `h3` lines are inside the old count. The free `plan`
prints 3,991 lines and 174,772 characters per narrator today, because it hides the 27 lines still waiting for the
editor's approval step; the 4,018 / 175,723 of that day are inside the 4,166 / 179,315 of the update above.)

Add 5 percent (about 0.74 USD) for a fix batch after listening. Model `eleven_v4_turbo` (0.04 USD per 1,000 characters,
`content/voices.json`); on `eleven_v4` every USD figure doubles, but you did not choose it.

**What blocks the run today (section 5 has the details):**
1. The 148 lines of the update above are `text-ready`: they have their direction row and no open ask, so they wait only for the
   hebrew-text-editor's approval step (the owner's conditional rule, section 8 decision 1). `generate` refuses until they are
   `owner-approved`, and so does it for the two held `b.mathb01.15.h3` and `.16.h3` lines. The free `plan` today still prints
   4,018 lines and 175,723 characters per narrator and 9 lines per friend, because it hides the 148 until then.
2. The tone-by-end-of-id and the friend-scope changes (P2, P3) are in the tool: the plan prints the right counts (section 2).
3. Your decisions in section 8.

Batch 0 needs none of these. You can run it any time.

---

## 1. What gets voiced, and why

The texts of pack 0.11.0 are final. The tool counts one line per `vo:` id, from the pack documents and
`content/lines/core.he.json`, with the `voice_text` of the master table. 4,166 lines per narrator (4,018 of the pack and the first core lines, plus the 148 of the update in section 0, which wait for approval):

| Group | Lines | Characters |
|---|---|---|
| Questions (`.prompt`) | 1,118 | 37,063 |
| Correct answers (`.correct`) | 1,118 | 29,220 |
| Hint 1 and 2 (`.h1`, `.h2`, shared `vo:hint.`) | 301 | 12,803 |
| Hint 3 (`.h3`, the worked steps) | 1,105 | 84,695 |
| Shared "not yet" lines (`vo:fb.`) | 89 | 4,640 |
| End-of-lesson celebrations (`vo:celebrate.`) | 183 | 5,083 |
| The 54 core lines (`vo:core.`; 27 of them new, waiting for approval) | 54 | 1,642 |
| Other (a few short ones) | 50 | 577 |
| The 48 daily-welcome lines (`vo:welcome.`, B-42) | 48 | 1,286 |
| The 100 map-card lines (`vo:core.skill.<id>`, what a picture on the land map is) | 100 | 2,306 |
| **Total per narrator** | **4,166** | **179,315** |

(The tone table in section 2 sums the same lines by tone. The group table is for reading.)

**Who says what (the owner's decision Q5, kept):**
- **Nitzi** and **hero-son** each say all 4,166 lines. A friend with a girl's voice borrows Nitzi in the lessons, a friend
  with a boy's voice borrows hero-son (`app/lib/app/companion.dart`).
- **Each friend** says only the 57 lines at the edges of play (`ownLines`), in his or her own voice: the 48 welcome lines
  (`vo:welcome.*`, B-42; the owner's decision 2 of that plan, accepted with the cost of all nine voices) and the 9 core lines `core.greeting.hello`,
  `core.greeting.start`, `core.celebrate.well`, `core.placement.done`, `core.goodbye.next`, `core.ceremony.bronze`,
  `.silver`, `.gold`, `.medal`. The nine are 190 characters, the welcome 1,286: 1,476 characters a friend (0.059 USD). A child never hears two voices take turns inside one
  activity. (`core.rest.goodbye`, the 25 `core.adventure.*` and `core.home.bubble` are narrator lines, not friend lines; the friend still says `core.goodbye.next`. A friend borrows the narrator for them.)

**Old lines are voiced again, and that is already inside the counts above.** Each narrator has 282 lines that have an old
clip. Every one is voiced again, because the model settings, the 44.1 kHz format, the respelling of "two" and some texts
changed: the plan says "changed 282, unchanged 0". The old clips are not reused and not paid twice. Why: the whole app
must sound like one voice with one tone, not a mix of the old and the new.

**Not in this run, or joining it (state of 2026-11-02):**
- **B-39 bottle lines are now in** (25 `core.adventure.*` lines, plus `core.rest.goodbye` and `core.home.bubble`; 27 lines,
  951 characters a voice). They wait only for the editor's approval step. The per-name `homeBubble` clips are not in this run.
- **B-42 welcome lines (48 lines, plan `docs/milestones/B42.md` on branch `b42-welcome-plan`) are in this run** (the owner said
  yes on 2026-11-02), together with the 100 map-card lines. The name clip that plays before a greeting is **not** in this run: it
  is a separate later step through the gateway, made from the parent-checked spelling at a parent's tap, and it is never Claude's
  (no real name in any file; the pilot uses a made-up name only).
- **The live helper (hero-son tutor lines)** is now prepared on branch `live-helper-voice-format`: the gateway sends the same
  format and settings as the pack (65 of the 66 lines, 4,544 characters). The owner runs the prewarm in the same session as
  batch 2; the deploy steps are in that branch's `docs/setup/supabase-deploy.md` section 8. Not counted above (4,544
  characters would add 0.18 USD at the Turbo list price).
- **Voice packs are split per narrator** into a core pack and band packs (work on branch `b45-voice-pack-split`), because
  the app caps a pack at 64 MiB and 8,002 entries. This answers decision 6 (one narrator is about 240 MB, *guess*; 4,166
  entries fit the entry cap but not the size cap). It does not change the cost.
- **Music and effects** (B-46) are separate.

---

## 2. The direction (tone per kind of line)

On every v4 model only **stability** and **similarity** reach the voice (style and speed are dropped by the tool), so
"tone" is stability, plus the punctuation of the text that the editor already set. All values are the ones you approved in
round 3 (2026-11-01); similarity is 0.8 everywhere. They are now in `content/voices.json` (`styles`, `styleRules`).

| Kind of line | Stability | Lines | Characters | What it should sound like |
|---|---|---|---|---|
| Question, "not yet", listening (`.prompt`, `vo:fb.`, `core.listen/stuck/breathe`, the try-again `core.encourage`, `core.home.bubble`, `core.skill.`) | 0.60 | 1,321 | 44,399 | calm, curious and kind; a question rises softly; "not yet" is never disappointed; the 100 map cards (`vo:core.skill.`) are a calm naming, short, ending down softly |
| Hint 1 and 2 | 0.65 | 299 | 12,645 | short, slow, soft, an invitation; no sigh |
| Hint 3 and worked steps (`.h3`) | 0.70 | 1,107 | 84,853 | the slowest and steadiest; counts and steps even; a small beat at a dash; ends warm |
| Correct, praise, greeting, goodbye, core praise, `core.adventure.*`, `core.rest.goodbye`, `welcome.*` | 0.50 | 1,249 | 32,203 | glad, never a shout; the welcome greetings are warm and start at once on "shalom" (they play after a short name clip), the topics a light preview, level, not a question |
| Celebration (`vo:celebrate.`, `core.celebrate.`) | 0.35 | 184 | 5,092 | bright but short and even (0.1 was wobbly) |
| Ceremony (`core.ceremony.`) | 0.45 | 4 | 88 | proud and warm |
| Thinking (`core.thinking.`) | 0.55 | 2 | 35 | a thinking hum, then a light line |

The 4,166 lines add up (1,321 + 299 + 1,107 + 1,249 + 184 + 4 + 2); the free `plan --list` showed exactly these counts on 2026-11-02.
Pace comes only from punctuation. No line needs more now; the editor's punctuation is final. The old per-line table
`docs/audio/voice-direction.csv` is **superseded** for style and speed (those columns do nothing on v4); its
`pronunciation` and `listen_for` columns still help the listening.

**The 148 lines of the update (2026-11-02).** *Welcome (48)*: default 0.50, no new rule, because the name clip, the greeting
and the topic must sit at one level so the seam does not show (greeting 0.50, name clip 0.50, topic 0.50, closing line 0.50).
Every greeting starts `שלום,`; the comma is a light beat of about 200 ms. Reading the texts I found nothing to change: the
lines are "we" or genderless, no `!`, no number to mis-gender, no name. The pointed words (`נְגַלֶּה`, `נְפָרֵק`, `נְחַלֵּק`,
`לִשְׁתֵּי`, `שְׁנֵי`, `אֶחָד` and the five land words `נֵצֵא`, `יַעַר`, `מְעָרַת`, `נְמַל`, `כְּפַר`) are right and stay. *Map cards
(100)*: a new `styleRules` entry (`vo:core.skill.` in `ask`) makes them 0.60, the level of the prompts: they are the same kind of
sentence ("מוצאים את אותו צבע."), 100 short clips that should sound alike, calm and not teacherly. One line in
`content/voices.json`, free to undo before batch 1 (decision 9). No text needs a change; no ask for the editor.

The bottle lines (`core.adventure.*`, 25) are an invitation: they fall to the default 0.50 on purpose (warm, even,
ends level, no shout); `core.rest.goodbye` is a goodbye at 0.50, soft; `core.home.bubble` ("what is in the bottle?") is a
question and has its own `ask` rule (0.60). The pointed land words `יַעַר`, `מְעָרַת`, `נְמַל`, `כְּפַר` are correct
(ya-AR, me-a-RAT, ne-MAL, k'FAR) and stay as written; `מה בבקבוק?` stays in plain letters (no change asked; it is the
first item to listen for in the fix batch).

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
| 0 | Pilot: `audition-batch`, `docs/audio/b45/pilot.json` | 28 | 1,036 | 0.0414 |
| 1 | `generate nitzi` | 4,166 | 179,315 | 7.1726 |
| 2 | `generate hero-son` | 4,166 | 179,315 | 7.1726 |
| 3 | `generate` for each friend, own 57 lines | 7 x 57 = 399 | 7 x 1,476 = 10,332 | 0.4133 |

- **Why this order:** the pilot is small and settles the last open sounds (the number two at the start of a sentence and
  in hero-son's voice; the word "equals"; the five new hint clips) before 14 USD is spent. Nitzi first, because she says
  the most. Hero-son second, so what you learn from Nitzi's check is applied before his run. Friends last, they are tiny.
- **Pilot contents** (28 clips, 14 Nitzi and 14 hero-son, real pack lines, final settings): N/H41 the number two as the first
  word; 42 two at the start of a question and again after "ve-OD"; 43 and 44 the same sentence with `שווה` plain, then pointed;
  45 two inside a counted list; 46 to 50 the five new hint clips (`hint.plate.h2`, `hint.glyph.h2`, `hint.in_twos.h2`,
  `hint.coin_values.h2`, `hint.hidden_part.h2`); **51 to 54 the B-42 welcome seam** (new, from `docs/milestones/B42.md`
  section 6): 51 a made-up name alone (`דָּנִי,`, not one of your children's: tell me if it is, and I change it), 52
  `welcome.hello.1`, 53 `welcome.topic.counting.glance`, 54 `welcome.close`, all at 0.50. You hear whether the name and the
  greeting sound like one voice and one sentence, and how long a whole welcome is. The name clip in the pilot is **only a test
  of the sound**: the real name clip (one per child and speaking voice, from the spelling a parent checked) is a separate later
  step through the gateway; it is never made by Claude, never in a repo file, and never in this run. 162 more characters than the
  old pilot (`דָּנִי,` 14 for the two voices, the three lines 74 each). Each clip says in its `tests` field what to hear.
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

It must end with `Clips to make: 28 of 28`, `Characters of text in total: 1036`, `0.0414 USD`. Stop and tell Claude
if not. Then (key set) the paid run, and **type 1036**:

```powershell
dart run tool/voice_gen.dart audition-batch run ../docs/audio/b45/pilot.json
```

Clips land in `$env:USERPROFILE\nitznutz-voice\auditions\pilot` (`N41-...mp3` to `H54-...mp3`, each with a `.json` that says what
was sent).

### 4.4 Batch 1, Nitzi (after the blockers of section 5 are done)

```powershell
dart run tool/voice_gen.dart plan --characters nitzi
```

Must show `Lines per voice: 4166` and `characters to send for this voice 179315`, no "cannot be voiced yet" list. Check the
tones once: `dart run tool/voice_gen.dart plan --characters nitzi --list` and look at a `core.celebrate.well` line (stability
0.35) and a `.h3` line (0.7). Then the paid run, and **type 179315** (or whatever the plan printed):

```powershell
dart run tool/voice_gen.dart generate nitzi --pack-version 2.0.0
```

Lands in `$env:USERPROFILE\nitznutz-voice\nitzi\` (`vo.<id>.mp3` and `cue.<id>.json` per line) and the signed voice packs in
the same folder: **18 packs for a narrator, not one** (section 7 lists them): `voice-nitzi-2.0.0.nnpack` for the shared lines
and `voice-nitzi-part-num-b-1-2.0.0.nnpack` and so on for each land and band. The packs are signed at the end with your signing
key (the tool reads the key file before it asks for the count, so a missing key stops it before anything is spent). The
`plan` and the start of the run list the packs, so you see them before you type the count. If it stops half way, run it
again and type the new, smaller number. If a pack comes out over 40 MiB, the run ends with an error that names it, **all
the clips are kept, and nothing needs paying for again**: run the free
`dart run tool/voice_gen.dart pack nitzi --pack-version 2.0.0 --max-lines <the number the error suggests>` and the packs are
made again from the saved clips.

### 4.5 Batch 2, hero-son

```powershell
dart run tool/voice_gen.dart plan --characters hero-son
dart run tool/voice_gen.dart generate hero-son --pack-version 2.0.0
```

Type the number the second command prints (179315 if nothing changed).

### 4.6 Batch 3, the friends (own lines; needs the friend-scope change of section 5)

```powershell
dart run tool/voice_gen.dart plan --characters alien-jili,climber-tzuri,compass-romi,friend-daughter,inventor-gali,tower-tamir,weaver-keshet
```

Must show 57 lines and 1476 characters for each. Then, one run each, typing 1476 each time:

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
| P1 | **Texts approved.** 2,818 lines (104,062 characters a voice) come from rows still `text-ready`; the tool voices only `owner-approved`, `voice-ready` or `voiced`, and `generate` refuses while any line waits. Your signature of 0.11.0 is the approval (decision 1; answered conditionally on 2026-11-02: 6,552 rows approved, 2 lines per narrator still wait: the two held `h3` lines of `b.mathb01.15`/`.16`); after it, the hebrew-text-editor records the spoken rows of the signed pack as `owner-approved` (6,720 spoken rows now `text-ready`). | owner, then hebrew-text-editor | measured |
| P2 | **Tone by the end of an id.** `styleOf` in `app/tool/voice_gen_lib.dart` matches the START of an id only. The rules in `voices.json` that begin with `*` (`*.h3`, `*.h1`, `*.h2`, `*.prompt`) must match the END. Without it, about 2,430 lines (every question, hint 1 to 3; 130,000 of the 174,772 characters) go out at 0.5 instead of 0.60 to 0.70. Change: in `styleOf`, `p.startsWith('*') ? voId.endsWith(p.substring(1)) : voId.startsWith(p)`, with a test. After it, `plan --list` must show stability 0.35 x184, 0.45 x4, 0.5 x1,175, 0.55 x2, 0.6 x1,220, 0.65 x299, 0.7 x1,107. | app-developer | read in code |
| P3 | **A friend's own lines only.** `plan` and `generate` give every character all lines (today every friend would cost 6.99 USD, 48.9 USD for seven). Add to `content/voices.json` `"narrators": ["nitzi","hero-son"]` and `"ownLines": ["vo:core.greeting.hello","vo:core.greeting.start","vo:core.celebrate.well","vo:core.placement.done","vo:core.goodbye.next","vo:core.ceremony.bronze","vo:core.ceremony.silver","vo:core.ceremony.gold","vo:core.ceremony.medal"]`; a character not in `narrators` plans and sends only `ownLines`. The app already falls back to the narrator for any other line. | app-developer | read in code |
| P4 | **The QA test** "every `vo` id has a recording in every shipped voice pack" must allow a friend pack to hold only its 9 own lines (the narrator pack covers the rest). | qa-engineer | read |
| P5 | **ffmpeg** to measure loudness (decision 5). | owner | not installed (measured) |
| P6 | **Pack size**: see decision 6. Done: several packs per narrator, each under 40 MiB (section 7). | app-developer | done |

Batch 0 needs none of these. Batch 1 and 2 need P1 and P2 (and P6 answered). Batch 3 needs P1 and P3.

---

## 6. What you listen for after each batch

Copy a few files to your phone (`.mp3` only; nothing about the children is in them). Listen once on the phone speaker and once
on headphones. Answer like round 3: `ok`, or the clip and what you heard.

**After batch 0 (the pilot), 28 clips:**
- `N41`, `H41`: "shTA-yim. kach sof-RIM." The stress on TA, a clean "sh-t", no gap, no extra syllable. Hero-son too.
- `N42`, `H42`: both twos on TA; the question rises at the end.
- `N43` against `N44` (and `H43` against `H44`): plain `שווה` or pointed `שָׁוֶה`. Say which is "sha-VE". This settles decision 3.
- `N45`, `H45`: two inside a list, even and calm.
- `N46` to `N50` and `H46` to `H50`: the five new hints. Soft, level, nothing counted aloud; `hint.hidden_part.h2` keeps its
  level to the end and the dash is a beat; `hint.coin_values.h2` reads "sha-VE".
- `N51` to `N54` and `H51` to `H54` (the welcome seam, made-up name `דָּנִי,`): play 51 then 52 with a gap of about 400 ms, then
  300 and 500 (the app will use about 500 ms for Band A, 350 for Band B, 300 for Band C). Does it sound like one voice saying
  one sentence, "da-NI, sha-LOM, EI-ze kef lir-OT et-KHEM"? No click, no long silence at the start of 52, the greeting not louder
  or higher than the name, a soft end. 53 is a light preview ("ha-YOM nir-E ka-MA yesh be-ma-BAT e-KHAD"), level, no rise; 54 is
  warm, short, an invitation. Then 51, 52, 53, 54 in a row: about 8 seconds; is it too long or too even for a 3 year old? If the seam
  sounds stitched, say so: the fallback is the name on screen only (B-42 decision 1), with no new voicing of the 48 lines.

**After batch 1 (Nitzi) and again after batch 2 (hero-son), about 35 clips (I choose them by id):**

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
| `welcome.hello.1`, `.hello.2`, `.hello.3`, `.hello.first` | warm and glad, starts at once on "shalom", no shout, a soft end; the same level as the topic after it |
| `welcome.topic.counting.count`, `.shapes.names` (the shortest), `.robots.steps`, `.market.measure` (the longest and a list) | a light preview, level, ends down; the colon in `robots.steps` a small beat; the list in `market.measure` even, no item swallowed |
| `welcome.topic.market.share`, `.market.equal` | `שווה` "sha-VE" and `שווים` "sha-VIM" (the "equals" check, with the pilot's 43 and 44); `שְׁנֵי` "shnei" |
| `welcome.land.shapes`, `.land.logic`, `.land.robots`, `.land.market` | the land word whole and as pointed: ya-AR, me-a-RAT, ne-MAL, k'FAR |
| `welcome.close` | warm, short, a soft end, an invitation and not a command |
| `core.skill.col_a_01`, `.num_a_05`, `.log_b_08` ("אם… אז…"), `.math_b_14` ("יום ראשון, יום שני…") | a calm naming at 0.60, short; each "…" is a short level beat, not a hum and not trailing off; "sheni" |
| `core.skill.shp_b_01`, `.shp_b_08`, `.num_b_13`, `.math_a_04` | the rare words said right: מרובע, מחומש, משושה, גליל, חרוט, פירמידה, ציר ("tsir"), כבד "ka-VED"; "mash-VIM" (compare) |
| `core.skill.num_b_11`, `.math_a_03` | the pointed `אֶחָד` "e-KHAD", the colon a small beat |

**After batch 3:** `tower-tamir`, `climber-tzuri` and one of the Nitzi-voice friends: the greeting and the medal. A male
friend sounds male; Keshet sounds female (decision 4); nothing sounds like a shout. For each of the seven also one welcome
greeting (`welcome.hello.1`) and the closing line: the friend's own colour, the same warmth as the narrator's.

---

## 7. After the run: my check, and the new pack version

**My check (status `voiced` to `checked`).** For each voice folder I compare, with `ffprobe` and `ffmpeg ebur128`:
1. the clip count equals the line count (4,166, or 57) and every `vo` id has its file and its cue file;
2. each clip's length against its characters (a clip far too short or too long is a clipped word or a run-on);
3. loudness about -16 LUFS, true peak at most -1 dBTP, even across lines;
4. no click or long silence at the start (50 ms) or end (150 ms);
5. the ledger `<voice>.voiced.jsonl` shows the stability and text each clip was sent with (for example a `.h3` clip at 0.7);
6. the text sent: the number two as D in 420 lines, no stray tag, no `!` that was not in the voice text.
This needs **ffmpeg, which is not installed on this PC** (decision 5). Without it I can check only counts, sizes and the
ledger, and I will say so. I do not claim to have heard anything: your listening in section 6 is the listening.

**New pack version.**
- The tool builds and signs the voice packs itself at the end of its `generate` run (`voice-<id>-2.0.0.nnpack` for the
  shared lines and `voice-<id>-part-<land>-<band>-2.0.0.nnpack` for the rest, in the voice folder, signed with the
  pack-signing key in `nitznutz-secrets`). Version **2.0.0** for every pack of all nine voices (the old ones are 1.2.0 and
  1.3.1), `minAppVersion` 0.6.0. The infrastructure-engineer publishes them (all the packs of a voice on the same day); the app
  reads every installed pack of a character as one voice.
- **Why several packs, and how they are shared (decision 6, answered by the code).** The app refuses a pack over 64 MiB or
  8,002 files and reads a pack whole into memory, and one narrator is about 4,000 lines (8,000 files) and 100 to 240 MB. So
  each narrator is 18 packs, each under **40 MiB and 3,000 files** (at 60 KiB a clip they are 3 to 26 MiB). The share is a fixed
  function of the voice id (`voiceGroupOf` in `app/tool/voice_packs_lib.dart`): the shared lines (`core.`, `fb.`, `hint.`,
  `celebrate.`) in `voice-<id>`, every other line by its **land** (number, maths, logic, colours, shapes, computer-science) and its
  **band** (the A or B in the skill id), because a child plays one band at a time and a land is the natural unit when a band is
  too big. A group over 450 lines is cut between skills (`num-b-1`, `num-b-2`). The 48 `welcome.*` lines and the 100 `core.skill.*` lines are two small groups of their own (`part-welcome`, `part-skill`), so the shared pack stays one pack. A friend's 57 lines stay one pack.
  Counts per narrator (4,166 lines; the free `plan` of 2026-11-02): core 422; col-a 213, col-b 144; cs-a 114, cs-b 54; log-a 298,
  log-b 189; math-a 220, math-b 605 (two packs); num-a 636 (two); num-b 656 (two); shp-a 275, shp-b 192; skill 100; welcome 48.
- **On the phone** the app does not hold a narrator's 18 packs at once: the shared pack stays in memory and at most two part packs
  (the last used), each at most 40 MiB, so about 75 MiB of clips at the 60 KiB estimate and at most 120 MiB. That counts the clip
  bytes only, not the decoded cue tracks, the objects around them, or the temporary copy while a pack is verified. A lesson loads its
  own part when it opens. Only packs of the same version as the shared pack are heard, so all packs of a voice must be published at one version.
- **If a pack is too big after the run** (the clips are longer than the 60 KiB guess): the build fails with the pack's name, the
  clips and the paid-for hashes are kept, and `pack <character> --max-lines <n>` (free, no key but the signing key, no network)
  makes the packs again with fewer lines in each. Re-packing the same clips with the same key gives the same bytes.
- **Order with pack 0.11.0:** the voice packs hold clips for the `vo` ids of 0.11.0 with the texts as signed. Changed lines
  (texts that changed since 0.10.0) would play new words over old captions on a phone that has the old content pack, and
  new lines would be silent. So **publish content 0.11.0 and voice 2.0.0 on the same day**, voice packs after the content pack
  is live and verified. Nothing of the voicing needs the signed pack to *start*, only the owner's approval of the texts (P1);
  but the voice packs must not go out before 0.11.0 does.
- If any text changes after the voicing (it should not), `plan` finds the changed lines and the next run says only those
  (the ledger hashes text, voice, model, settings and format).
- The B-42 welcome lines are in this run (pack `part-welcome` of each narrator, and inside each friend's pack). Only the name clip
  is later (a separate step, never Claude's); it needs no pack version of its own.

---

## 8. Decisions for you (short, with my recommendation)

1. **Does signing pack 0.11.0 count as your approval of every spoken text in it?** Then the editor marks the 6,720
   spoken `text-ready` rows `owner-approved` after the signing, and 3,991 lines can be voiced. If no: only the 1,173 lines
   already approved (70,710 characters a voice) can be voiced, and 2,818 lines would have no new clip. *Recommend: yes.*
   **Answered 2026-11-02 (recorded by the hebrew-text-editor).** The owner, in chat: "If they are already checked by the text
   agent and the voice agent its fine by me". So the approval is conditional: a spoken row is `owner-approved` only if the editor
   checked it (`text-ready`, not flagged) and the voice director has a direction row for exactly its voice text in
   `docs/audio/voice-direction.csv` with no open ask. Result, first pass: 6,091 of the 6,720 spoken rows `owner-approved`, 629 held
   (547 with no direction row, 14 with an open ask, 68 outside the pack). **Second pass (2026-11-02, after the voice director's
   check, `docs/audio/b45-direction-checked.tsv`, `voice-direction.md` section 14): 6,552 of the 6,720 spoken rows are
   `owner-approved`** (6,530 pack rows and 22 core rows in the B-45 list; all 27 core lines are approved), hash-locked in `docs/review/b45-approved-rows.tsv` (6,552 lines, no header):
   the 6,091 plus 447 `directed` and 14 `ask-withdrawn` rows. 168 are held, each with its reason in `docs/review/b45-held-rows.tsv`:
   **2** wording held (`b.mathb01.15.h3` and `.16.h3`: the worked example counts to the total and asks for the addend; the
   editor's proposed fix is in `docs/agents/hebrew-notes.md` section 18, and it changes pack 0.11.0, so the orchestrator
   decides), **98** map-card `childLine` rows (no `vo:` id, never voiced, left out of the voicing approval), **66** live-helper
   rows and **2** per-name strings (not in this run). The free `voice_gen plan` now plans **3,989 of 3,991 lines per narrator
   (174,559 characters; first pass 3,546, before that 1,173)** and all 9 lines of each friend (190 characters); the 2 lines still
   waiting are the two held `h3` lines, so `generate` still refuses until they are approved or changed. Whether a script-made
   direction table plus the director's reading of the 561 rows is the check the owner meant is for him to say.
2. **One run per narrator (recommended)** or a tool change that lets a run take only part of the lines. The pilot is the safe
   small step already; Ctrl+C is the emergency stop. *Recommend: one run each, no tool change.*
3. **The word "equals" (`שווה`, 120 lines, 5,636 characters):** after the pilot, say "N44 better" or "N43 is fine". If the
   pointed one is better I add the pronunciation entry before batch 1 (no cost). *Recommend: decide from the pilot.*
4. **Keshet (a girl) still shares Tamir's male voice id (`6Ijsl5024dyMrE00loVE`)**, as I checked in `content/voices.json` and
   `companion.dart` today; B-42 decision 4 did not change it. Now it matters more: she would say her 57 own lines, the 48 welcome
   greetings among them, in a man's voice, while her lessons (Nitzi) sound female. The words are fine (all "we" or genderless), only
   the voice does not match her. *Recommend:* give her Nitzi's voice id until you choose a female voice (a one-line
   `voices.json` change, 1,476 characters, 0.059 USD). The other friends: Jili, Romi, the daughter's friend and Gali share Nitzi's
   id, so their welcome sounds like Nitzi's; Tamir shares it with Keshet; Tzuri has his own male voice (`8sZ9Z3Jy28CGLLCmKEHn`).
   All seven suit the welcome (it is genderless and short); the cost of saying it in the same voice five times is the price you
   accepted in B-42 decision 2.
5. **Install ffmpeg** (free: `winget install Gyan.FFmpeg` in PowerShell) so I can measure loudness. *Recommend: yes, before batch 1.*
6. **Voice pack size.** At 44.1 kHz and 64 kbps the old average clip (30 KB at 32 kbps) becomes about 60 KB, so one narrator's
   pack is roughly **240 MB** (*guess*; the old pack of 318 clips was 9.9 MB, measured). Ask the infrastructure-engineer
   whether a pack of that size can be downloaded and stored as it is, or must be split by land or band, **before** batch 1.
   *Recommend: ask first; it does not change the cost.*
   **Answered 2026-11-02 (app-developer, with the infrastructure-engineer's limits):** it cannot be one pack (the app refuses over
   64 MiB or 8,002 files and reads a pack whole into memory, and `ZipLimits` is a memory guard that stays). Each narrator is 18
   packs of at most 40 MiB (16 at that time, 18 with the welcome and map-card groups) and 3,000 files, shared by land and band; section 7 has the list and the free `pack` command that makes
   them again from the saved clips if one is too big. P6 is done in the tool.
7. **ElevenLabs allowance.** The plan's Creator tier lists 275,000 "v4 characters" a month (`docs/PLAN.md`); this run is
   369,998 characters (14.80 USD). I have not checked whether Turbo counts at the same rate or half. Look at your usage page. If it would
   pass the allowance, run Nitzi this month and hero-son after the month turns. *Recommend: check the usage page before batch 1.*
8. **The live helper lines (66 rows, gateway)** are prepared on branch `live-helper-voice-format` (same format and settings as the pack; 65 of 66 lines,
   4,544 characters); you run the prewarm in the same session as batch 2 (steps in that branch's `docs/setup/supabase-deploy.md`
   section 8). *Recommend: yes, same session.*
9. **Map-card lines at 0.60 (new, 2026-11-02).** The 100 `core.skill.*` lines are set like the prompts (calm, even), not at
   the default 0.50. If you hear them in the batch-1 check as too flat, I move them to 0.50 (one line in `voices.json`) and only
   those clips are made again (100 lines, 2,306 characters, 0.09 USD per narrator). *Recommend: 0.60.*

---

## 9. What waits for others

- **app-developer:** P2 and P3 (small, with tests); later the gateway format and settings for the live helper.
- **hebrew-text-editor:** after your signature, record the spoken rows of the signed pack as `owner-approved` (P1). Nothing to
  change in any text or punctuation: I asked for no punctuation change.
- **qa-engineer:** P4.
- **infrastructure-engineer:** pack size (decision 6) and publishing voice 2.0.0 with content 0.11.0.
- **security-engineer:** nothing new. Only the first-name exception is allowed to go to ElevenLabs; the B-45 lines contain no
  child's name (the per-name `homeBubble` clips and the B-42 name clips are a later step). The only name in the pilot is a
  made-up one (`דָּנִי,`), and I ask you to confirm it is not a name of one of your children.
- **hebrew-text-editor:** record the 148 rows of the update (`welcome.*`, `core.skill.*`) as `owner-approved` by the owner's
  conditional rule: they have their direction row and no open ask. No text change and no punctuation change asked.
- **curriculum-expert:** nothing; the welcome topic table and the map-card lines are already theirs and the editor's.
