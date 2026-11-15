# L7-9: the voice plan for the re-cut language courses

Voice-and-sound-director, 2026-11-15. Worktree `D:\nitznutz-teach-first`, branch `languages-teach-first` (tip 9f2bb25a). Nothing here was paid for. I ran only `plan-lang` and `verify-lang` (free, no network, no key). I did not commit.

**Read this first: the numbers below are for this branch as it stands, and the branch is behind the voicing branch.** The tool that voices a language course (`plan-lang`, `generate-lang`, `verify-lang`, file `app/tool/lang_voice_lib.dart`) and the four course voices in `content/voices.json` (`lang-en-female`, `lang-en-male`, `lang-ru-female`, `lang-ru-male`) exist only on branch `hebrew-sweep` (worktree `D:\nitznutz-hebrew-sweep`, tip 54c730ff, not merged to main). To count, I ran that tool from the sweep worktree on a scratch copy (sweep `voices.json` + this branch's `content/languages`), against the owner's real work folders `~\nitznutz-voice\lang-<course>` (read only). The 2026-11-08 voicing (what the owner paid for) was made from the sweep's texts, so every line where this branch's text differs from the sweep's counts as "changed", even when this branch is the one that lost the sweep's nikud. See section 4, blocker 1.

## 1. Counts (free plan, model `eleven_v4`, list price 0.08 USD per 1,000 characters)

Commands used: `plan-lang <course> --voice <v> [--puppet-voice <p>] --model eleven_v4 --repo <scratch> --price 0.08 --list`. "Lines" = clips sent to the voice. The Hebrew frame lines are always nitzi. A `-slow` copy is made by ffmpeg and costs nothing. Identical texts are voiced once.

### 1.1 As the branch stands today ("provisional": upper bound, see the note above)

| Course | Voice | New | Re-voice (changed) | Unchanged (free) | Characters |
|---|---|---|---|---|---|
| English | nitzi (Hebrew lines) | 16 | 23 | 94 | 833 |
| English | lang-en-female (target) | 2 | 0 | 136 | 11 |
| English | lang-en-male (puppet Pip) | 0 | 2 | 9 | 25 |
| **English** | | **18** | **25** | 239 | **869** (0.07 USD) |
| Russian (option A, the tool's default with `--puppet-voice`) | nitzi | 116 | 29 | 34 | 1,502 |
| Russian A | lang-ru-female | 1 | 0 | 172 | 3 |
| Russian A | lang-ru-male (puppet) | 0 | 45 | 10 | 471 |
| **Russian A** | | **117** | **74** | 216 | **1,976** (0.16 USD) |
| Russian (option B, no `--puppet-voice`) | nitzi | 116 | 29 | 34 | 1,502 |
| Russian B | lang-ru-female | 1 | 11 | 216 | 153 |
| **Russian B** | | **117** | **40** | 250 | **1,655** (0.13 USD) |
| Hebrew | nitzi (frame and words) | 64 | 25 | 196 | 1,999 |
| **Hebrew** | | **64** | **25** | 196 | **1,999** (0.16 USD) |

Cut words (Hebrew, 12) and slow copies (English, 4 of 67) are made with ffmpeg from clips: no characters. `ffmpeg` is installed on this machine (WinGet link found).

**Grand total, provisional:** option A **4,844 characters (0.39 USD)**; option B **4,523 characters (0.36 USD)**.

### 1.2 What it should be after the merge (my comparison, to be confirmed by `plan-lang`)

I compared every text of this branch's three `voice-plan.json` with what the ledger says was voiced, ignoring nikud-only differences (the sweep added nikud that this branch lacks). Result: English 22 of the 23 "changed" nitzi lines, Hebrew 10 of 25 and Russian 18 of 29 are nikud-only, so they stop being re-voice lines once the sweep is merged in.

| Course | New clips | Chars (new) | Really changed clips | Chars (changed) | Text total |
|---|---|---|---|---|---|
| English | 22 | 194 | 1 (`he-gl-clap`, new wording) | 17 | **211** |
| Russian | 117 | 870 | 12 | 149 | **1,019** |
| Hebrew | 64 | 1,109 | 15 | 504 | **1,613** |
| **Total** | 203 | 2,173 | 28 | 670 | **2,843** |

Add to that only the clips whose voice changes (the puppet question, section 4, blocker 2): English 2 clips, 25 characters (`en-isit-cat`, `en-isit-duck` become Pip's); Russian option A about 450 characters more, option B about 0. So after the merge I expect roughly **2,870 characters (about 0.23 USD)** with option B or C, **about 3,300 (0.26 USD)** with option A. This is a calculation, not a tool output. The tool's number replaces it.

## 2. Direction per line family

Settings stay as `content/voices.json`: stability 0.5, similarity 0.75, speaker boost on, no style and no speed (v4 ignores both). I do not propose new numbers: a changed setting makes every hash change and re-voices everything. Gaps below are my proposals for the app-developer (guessed from the design, not measured on a phone).

| Family (lines) | Voice | How it should sound | Gap to the next clip (proposal) |
|---|---|---|---|
| **Meet opener** `he-meet-open` / `f44` / `meet-open` ("בואו נלמד מילים חדשות.") | nitzi | Warm, unhurried, a smile in the voice; about 1.6 s. Falls gently at the end. It starts the set, so it is the quietest start in the lesson. | 500 ms before the first word's picture speaks |
| **Meet model word** (`en_*`, `w_*`, `heb_a_w_*`) | course voice | One word, slow and clear, a full stop at the end so it falls and stops clean; no trailing breath. **Said twice by the screen, not twice in the text** (the app plays the same clip before and after the meaning; doubling the text would double the cost and change the stress). The English and Russian `-slow` copy (0.8 speed) is for the "again, slowly" hint only; it is never the first hearing. | 350 ms after the word before the gloss; 350 ms before the second hearing |
| **Carrier "בעברית:"** (`he-hint-hebrew`, `f42`) | nitzi | Short and light, level, leans forward into the gloss; the colon makes it hold. | 200 ms |
| **Gloss** (`he-gl-*`, `gl-*`, 116 Russian new) | nitzi | One calm word or short phrase, fully pointed so the voice cannot read פֶּה as פֹּה. Lower energy than the word. The meaning, said once. Phrases (`זה כדור.`, `בָּא לִי חָלָב`) are said as a statement, not an announcement. | 400 ms, then the screen's next step |
| **Whole-phrase glosses** `he-gl-its-*` (9), `he-gl-isit-*` (2), Russian `gl-bali-*` (3) | nitzi | A complete short sentence: a falling statement for `זה …`, a gentle rise only on `?`. The pronoun follows the noun (`זו מכונית`). Check gender by ear: `זה` with masculine, `זו` with feminine. | 400 ms |
| **Carrier "וְאֵיפֹה"** (`he-fb-where`, `f43`, heb `fb-where`) | nitzi | It is half a question: it must hang open and the target clip finishes it. It must not fall as if it ended. | 150 ms, as short as the player allows, so the two clips sound like one question |
| **Instruction lines** (`he-ins-*`, `f01`-`f40`, `i_*`) | nitzi | The plain narrator: even, kind, never a scold; the question rises only on its last word. | 300 ms |
| **Feedback** ("שמעתי:", "הקשיבו שוב", "המממ… בואו נבדוק") | nitzi | Curious, never disappointed. "המממ" is a short thought, not a sigh. | 250 ms |
| **Hebrew blend items** (`fb-blend-last` "שמעו מההתחלה.", `fb-soundalike`; then the whole word) | nitzi, then the word clip | The praise or hint is one short line that ends **open and level**, and the whole word clip follows and finishes it. The word is the last sound the child hears, always, and it is not followed by anything. The word clip falls and stops. | 200 ms between the line and the word; nothing after the word |
| **Puppet lines** (`ch_*`, English Pip, Russian Саша) | puppet voice (male) | Friendly and a little lighter than the narrator; never a different language than the clip's text. | per the screen |
| **Verses and chants** (`v*_play`, `heb_a_v*_full`, `en_ch_*`) | nitzi / course voice | A rhythm, not a speech: even pace, small breath at each comma, the rhyme word lands on the beat. | none inside the clip |

### The comma variant for "וְאֵיפֹה"

The voice text today is `ואיפה` (5 characters), plain, no point. A bare unpointed word can be read as a falling statement. Listen for three things: it does not fall at the end; it does not stretch the last vowel; `אֵיפֹה` and not `אִם פֹּה`. If the voice drops, use `ואיפה,` (6 characters, a comma keeps the line open). If it still drops, `ואיפה…` and last the pointed `וְאֵיפֹה` (8 characters). Each is 3 clips (eng, rus, heb), so the three variants cost 3 x (5+6+8) = 57 characters. A changed text in one course must be the same in the other two (one wording per job): the editor changes the three together.

### What the owner should audition first (about 12 short clips)

1. `ואיפה` against `ואיפה,` against `וְאֵיפֹה` (the carrier above).
2. `בעברית:` and `בְּעִבְרִית:` (the editor's text is `בעברית:`; check the voice does not read it as "ב-עברית" with a pause).
3. `בואו נלמד מילים חדשות.` (the opener: warmth and pace).
4. One English phrase gloss, `זה סֵפֶר.`, and one feminine, `זו מכונית.` (gender and the plain-versus-pointed mix: `זו מכונית` is plain in the voice text).
5. One Russian gloss with a short word pair: `אִמָּא` and `בָּא לִי חָלָב`.
6. One Hebrew word clip, `ארבעה תופים` (the number in its construct form and gender), and `שְׁנֵי תֻּפִּים`.
7. `Меня́ зову́т Са́ша.` in the male puppet voice.

These need `audition-batch run`, which is paid and which only the owner runs. The free count is `audition-batch plan` on a spec of those texts.

## 3. The owner's steps (PowerShell 5.1, no `&&`)

Do not start before section 4 blockers 1 and 2 are cleared. The paid commands work only in the repo that holds the tool and the re-cut content, so they wait until the voicing branch and this branch are merged (the orchestrator does that and tells you the folder). Below, `<repo>` is that folder.

1. Open PowerShell. Go to the app folder: `cd <repo>\app`
2. Free check that ffmpeg is found: `ffmpeg -version`
3. Free plans (the count the paid step will ask for; keep the three numbers):
   - `dart run tool/voice_gen.dart plan-lang eng --voice lang-en-female --puppet-voice lang-en-male --model eleven_v4`
   - `dart run tool/voice_gen.dart plan-lang rus --voice lang-ru-female --model eleven_v4` (option B; add `--puppet-voice lang-ru-male` only if you choose option A)
   - `dart run tool/voice_gen.dart plan-lang heb --voice nitzi --model eleven_v4`
   Compare each "Characters of text in total" with section 1.2. If one is more than 10 percent higher, stop and send it to me: it means a text came out wrong again.
4. Free sanity check of the first batch: `dart run tool/voice_gen.dart verify-lang eng --voice lang-en-female --puppet-voice lang-en-male --model eleven_v4` (it lists what is not voiced yet; it must list exactly the lines of the plan).
5. Set the key in this PowerShell window only (it is never saved and never shown): `$env:ELEVENLABS_API_KEY = "<your key>"`
6. Audition first (paid, small, see section 2); listen; if the carrier needs a comma, tell me so the editor changes the three lines, and run steps 3 and 4 again.
7. English (type the count the tool prints; expected about 211 to 236 after the merge, 869 before it):
   `dart run tool/voice_gen.dart generate-lang eng --voice lang-en-female --puppet-voice lang-en-male --model eleven_v4 --pack-version 1.1.0`
8. Russian (type the count the tool prints; expected about 1,019 with option B, 1,470 with A):
   `dart run tool/voice_gen.dart generate-lang rus --voice lang-ru-female --model eleven_v4 --pack-version 1.1.0`
9. Hebrew (type the count the tool prints; expected about 1,613):
   `dart run tool/voice_gen.dart generate-lang heb --voice nitzi --model eleven_v4 --pack-version 1.1.0`
10. After each: free check, the same `verify-lang` command as step 4 for that course. It must say that every clip is made from what the plan says now. Then send me the `~\nitznutz-voice\lang-<course>` folder name so I can measure loudness and length with `ffprobe` and `ffmpeg` and write the listening sheet.
11. Clear the key from the window: `Remove-Item Env:ELEVENLABS_API_KEY`

`--pack-version` must be higher than the installed 1.0.0: an installed pack with the same version is not replaced (release-voicing-plan.md). The tool shows its own plan and asks for the character count; you type it on the keyboard. No flag skips that.

## 4. What blocks voicing

1. **The two branches have diverged on the same texts.** This branch's `voice-plan.json` files are generated from an authoring state that lacks the sweep's voice-text edits (b5a1581a and later): pointed one-word glosses, `הַקְשִׁיבוּ`, `מְחִיאַת`, and others. Counted as is, English shows 23 "changed" nitzi lines of which 22 are only nikud that the sweep had added and this branch dropped, which would re-voice (and for some words un-point) lines the owner already paid for. Merge `hebrew-sweep` into `languages-teach-first`, regenerate with `python tools/lang_pack.py all`, run `--check`, then repeat the three free plans. **I cannot give final numbers before then.** Owner: orchestrator.
2. **Russian puppet set grew from 11 to 55 clips.** In the re-cut pack the Meet and puppet items made 44 more clips (`w_mama`, `w_ryba`, the sounds `syl_*`, `sf_*`, `sy_*`, the rhyme gaps `rh*_gap`, `ch_vot_*`, `ch_eto_*_q`) the `prompt.target` of a `puppet_talk` item. The tool says "a clip that is also a puppet prompt belongs to the puppet", so with `--puppet-voice` the Meet words of Russian (`w_mama`, `w_nos`, `w_sok`...) turn male while the others stay female, and the same word would sound different on two screens. English gains only 2 (`en_isit_cat`, `en_isit_duck`, fine). Options:
   - **A**, as the tool does: 45 Russian clips change to the male voice (471 characters).
   - **B**, no `--puppet-voice` for Russian: everything in the female voice, the 11 old Sasha clips go to her (153 characters). Sasha is no longer a distinct voice.
   - **C (my recommendation)**: only the `ch_*` question and answer lines are Sasha's, all word, sound and rhyme clips are the course voice. It needs a small tool change (`--puppet-prefix ch_`, app-developer). I have not made it. Until then, choose B.
3. **`vo:rus.ch_menja_zovut` is refused** by the tool: this branch's text is `Меня́ зову́т {puppet}.` and a placeholder is never sent. The sweep's text is `Меня́ зову́т Са́ша.` (fixed 2026-11-08). It goes away with the merge in blocker 1. If it does not, the Russian run sends nothing until it is fixed.
4. **No missing clip rows.** I checked every `vo:` id in every pack activity file against the three plans: nothing is referenced and missing, nothing is in a plan and unreferenced (eng 351, heb 297, rus 407 clips). No English beat-strip hole was found. The English `he-ins-strip` ("כמה תופים?") is in the plan and voiced by nitzi.
5. **13 Hebrew frame lines have no voice text** (`fb-sem`, `fb-soundalike`, `ok-1` to `ok-8`, `show`, `try-1`, `try-2`) and are not voiced. They did not have one before either (the earlier plan skipped them too); I assume that is deliberate (bubble only). If any should speak, the text editor gives it a `voice_text`. Heb `fb-soundalike` is used by the blend items (`blend_first`): confirm with the editor that the blend feedback should stay silent there.
6. **The `he-gl-its-*` voice texts are plain** (`זה תפוח.`, `זו ביצה.`) while section 15 of the editor's notes says a short phrase said alone is fully pointed (only `סֵפֶר` and `בַּרְוָז` carry nikud, "the pronoun follows the noun"). The editor wrote it so on purpose, so I do not change it. If the audition shows a wrong stress or a wrong gender, ask the editor to point the voice text: a text-editor request, not mine.
7. **The key.** `generate-lang` needs `ELEVENLABS_API_KEY` in the owner's own window. I never set or read it.

## 5. After voicing (what I will check)

Right voice per clip (nitzi for the Hebrew lines, female for English and Russian words, male only for the puppet lines); the right gender in `זה`/`זו` and the numbers; no clipped first or last sound; no click; the carrier ends open; a model word falls and stops; loudness near -16 LUFS and within about 1.5 LU across lines, true peak at most -1 dBTP; each line within its pause budget; slow copies 0.8 times as fast and not distorted. I measure with `ffprobe`/`ffmpeg` and will say what I measured and what I only read.
