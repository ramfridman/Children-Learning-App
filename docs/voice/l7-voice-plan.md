# L7-9: the voice plan for the re-cut language courses

Voice-and-sound-director, 2026-11-15, FINAL numbers. Worktree `D:\nitznutz-teach-first`, branch `languages-teach-first`, after the `hebrew-sweep` merge. Nothing here was paid for. I ran only `plan-lang` and `verify-lang` (free, no network, no key). I did not commit.

## 1. Counts (free `plan-lang`, model `eleven_v4`, list price 0.08 USD per 1,000 characters)

Commands: `plan-lang eng --voice lang-en-female --puppet-voice lang-en-male`, `plan-lang rus --voice lang-ru-female --puppet-voice lang-ru-male`, `plan-lang heb --voice nitzi`, each with `--model eleven_v4 --price 0.08`. "Clips" = clips sent to a voice. Hebrew frame lines are always nitzi. `-slow` copies and cut words are made by ffmpeg: no characters. Identical texts are voiced once. The puppet voice speaks only its own lines (`puppetClips`).

| Course | Voice | New | Re-voice (changed) | Unchanged (free) | Characters |
|---|---|---|---|---|---|
| English | nitzi (Hebrew lines) | 16 | 1 | 116 | 196 |
| English | lang-en-female (words) | 2 | 2 | 138 (+2 same text) | 31 |
| English | lang-en-male (puppet Pip, 7 clips) | 0 | 0 | 7 | 0 |
| **English** | | **18** | **3** | 261 | **227** (0.02 USD) |
| Russian | nitzi | 116 | 9 | 54 | 936 |
| Russian | lang-ru-female | 1 | 7 | 209 | 63 |
| Russian | lang-ru-male (puppet Gosha, 11 clips) | 0 | 8 | 3 | 92 |
| **Russian** | | **117** | **24** | 266 | **1,091** (0.09 USD) |
| Hebrew | nitzi (frame and words) | 77 | 0 | 221 | 1,280 |
| **Hebrew** | | **77** | **0** | 221 | **1,280** (0.10 USD) |

**Grand total: 2,598 characters, about 0.21 USD.** New 212 clips, re-voice 27 clips. (2026-11-15: the puppet renamed Гоша, so `ch-menja-zovut` is re-voiced: Russian 1,072 became 1,091.) Cut words (Hebrew, 12) and slow copies (English, 5) cost nothing. `ffmpeg` is installed (WinGet link).

Decisions closed by this run:
- The Russian puppet question is settled: only Gosha's own 11 clips are male. The Meet words stay female.
- Hebrew `fb-soundalike` (blend items) now has a voice text, `שִׁמְעוּ עד הסוף.` (17 characters), and is in the Hebrew plan: **voice it now.** The blend word clip follows and finishes it (section 2).
- The nine `he-gl-its-*` and the other frame lines are in the plan. The editor's voice text stands; if the audition shows a wrong gender or stress, the editor points the text.


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
| **Puppet lines** (`ch_*`, English Pip, Russian Гоша) | puppet voice (male) | Friendly and a little lighter than the narrator; never a different language than the clip's text. | per the screen |
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
7. `Меня́ зову́т Го́ша.` in the male puppet voice.

These need `audition-batch run`, which is paid and which only the owner runs. The free count is `audition-batch plan` on a spec of those texts.

## 3. The owner's steps (PowerShell 5.1, no `&&`)

`<repo>` is this worktree (or the folder it is merged into).

1. Open PowerShell and go to the app folder: `cd <repo>\app`
2. Free: `ffmpeg -version`
3. Free plans (they must show 227, 1,091 and 1,280 characters, unless the editor changed a text since):
   - `dart run tool/voice_gen.dart plan-lang eng --voice lang-en-female --puppet-voice lang-en-male --model eleven_v4`
   - `dart run tool/voice_gen.dart plan-lang rus --voice lang-ru-female --puppet-voice lang-ru-male --model eleven_v4`
   - `dart run tool/voice_gen.dart plan-lang heb --voice nitzi --model eleven_v4`
   If a number is more than 10 percent higher, stop and send it to me.
4. Set the ElevenLabs key in this window only (never saved): `$env:ELEVENLABS_API_KEY = "<your key>"`
5. Audition first (paid, small, section 2). If the carrier needs a comma, tell me; the editor changes the three lines; redo step 3.
6. English, type **227**: `dart run tool/voice_gen.dart generate-lang eng --voice lang-en-female --puppet-voice lang-en-male --model eleven_v4 --pack-version 1.1.0`
7. Russian, type **1091**: `dart run tool/voice_gen.dart generate-lang rus --voice lang-ru-female --puppet-voice lang-ru-male --model eleven_v4 --pack-version 1.1.0`
8. Hebrew, type **1280**: `dart run tool/voice_gen.dart generate-lang heb --voice nitzi --model eleven_v4 --pack-version 1.1.0`
9. After each, free: the same command with `verify-lang` in place of `generate-lang`, and drop `--model` and `--pack-version` (verify-lang does not take them). It must list nothing missing. Then send me the `~\nitznutz-voice\lang-<course>` folder name for loudness and length checks.
10. Clear the key: `Remove-Item Env:ELEVENLABS_API_KEY`

`--pack-version` must be higher than the installed 1.0.0. The tool asks for the count; you type it; no flag skips that.

## 4. What blocks voicing

Nothing in the texts or the tool: no placeholder is refused, the puppet split is fixed, `fb-soundalike` is in the plan. What remains is the owner's: the audition, the key in his own window, typing the three counts. Audition first, because a changed carrier text changes the numbers.


## 5. After voicing (what I will check)

Right voice per clip (nitzi for the Hebrew lines, female for English and Russian words, male only for the puppet lines); the right gender in `זה`/`זו` and the numbers; no clipped first or last sound; no click; the carrier ends open; a model word falls and stops; loudness near -16 LUFS and within about 1.5 LU across lines, true peak at most -1 dBTP; each line within its pause budget; slow copies 0.8 times as fast and not distorted. I measure with `ffprobe`/`ffmpeg` and will say what I measured and what I only read.
