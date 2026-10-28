# Voice and sound direction

Written by the voice-and-sound-director on 2026-10-28. Status: **a design and a plan; nothing was generated, sent or
paid.** The owner listens and decides; the main assistant changes code only with his OK.

Files:

| File | What |
|---|---|
| `docs/audio/voice-direction.md` | this design (voices, tones, music, effects, silence, the plan and the cost) |
| `docs/audio/voice-direction.csv` | one row per distinct voiced text (1,862 rows), with its direction |
| `docs/audio/audition.csv` | the 163 clips of the proposed audition, with the exact text and settings |
| `content/voices.proposed.json` | the proposed voices, styles, style rules and pronunciation (not used by any tool) |
| `tools/voice_direction.py` | makes both CSV files from `docs/review/hebrew-master.csv` and prints the plan |

    PYTHONIOENCODING=utf-8 python tools/voice_direction.py            # rewrite both CSVs, print the plan
    PYTHONIOENCODING=utf-8 python tools/voice_direction.py --sample 220   # also print a sample to read

How sure each statement is: **[M]** measured here, **[R]** read in the repo or a cited source, **[G]** my judgement
(a guess until a person has listened). I cannot hear; nothing below claims that something *sounds* right.

---

## 1. What exists today (the starting point)

### 1.1 Voices
- **[R]** `content/voices.json` has nine characters but only **four distinct voice ids**: `Tbj9…` is shared by Nitzi,
  Jili, Romi, the daughter's friend and Gali (five characters, one voice); `6Ijsl…` by Tamir and Keshet; Tzuri and
  hero-son have their own.
- **[R] Gender conflict.** `app/lib/app/companion.dart` sends Keshet's lesson lines to **Nitzi** (female) and Tamir's to
  **hero-son** (male), yet both have the same voice `6Ijsl…`. Whatever that voice is, one of the two friends switches
  gender between her own lines and the lesson lines. Keshet is grammatically feminine, Tamir masculine
  (`design/family-pack/*/pack.json`), so Keshet needs a voice of her own (owner question 1).
- **[R]** Jili is a masculine noun (`grammaticalGender: masculine`, "a jelly") with the girl's voice and borrows Nitzi.
  This is consistent as long as no line names the speaker's gender (none does today: `core.he.json` note).
- **[R]** Styles: one, `cheer` (stability 0.1, similarity 0.8, style 0.9, speaker boost), used for
  `vo:core.celebrate.`, `vo:celebrate.`, `vo:core.ceremony.`. No default `settings`, no `pronunciation`.

### 1.2 The generator (`app/tool/voice_gen.dart`, `voice_gen_lib.dart`)
- **[M]** `dart run tool/voice_gen.dart plan --price 0.04` (free, offline; it only reads files) prints today:
  9 voices, 2,831 lines per voice, 24,465 lines to say, **1,359,619 characters, 54.38 USD**. That is *not* the plan the
  owner chose: it voices every line for every friend.
- **[R]** It reads the **pointed screen captions** of `content/starter` (with "!"), not the `voice_text` of the master
  table. It voices **per `vo:` id**, so a text shared by many ids is said many times (2,792 ids for 1,784 distinct
  texts). Style rules match a **prefix** only. `respelled()` replaces **substrings** (an entry for `חסר` would also hit
  `שחסר`). It **reuses** any audio file already in the work folder by id, even if the text changed.
- **[R] Mouth cues need nikud.** `cuesFromAlignment` opens the mouth only on a letter followed by a vowel point. The
  `voice_text` is mostly unpointed (only number words keep points), so the cue file would be empty and the app would
  fall back to the fixed 140 ms flap (`voice_director.dart:205`): the mouth moves through pauses and does not follow the
  words. Change C6 in section 6 fixes this.
- **[M]** Work folders `%USERPROFILE%\nitznutz-voice\<id>`: Nitzi and hero-son 318 clips each, the other seven 54 each
  (1,014 in all). **Each friend's folder holds 28 lesson lines** (the M4 butterflies set). Because the friend's bank is
  asked before the narrator's (`VoiceBank.withFallback`), those 28 lines would still play in the friend's voice with
  the old texts inside lessons that are otherwise narrated by Nitzi or hero-son. They must be moved away before the
  friends' packs are rebuilt.
- **[M]** The existing clips are in two formats: 22,050 Hz / 56 kbps (older) and 44,100 Hz / 64 kbps (newer, M8).
  A full re-voice puts them all on 44.1 kHz.

### 1.3 Measured speech rate (from the existing files, by reading MP3 frame headers)
**[M]** Median over the 318 clips (silence at the start and end included), at the default speed 1.0:

| Voice | letters / s | words / s | 10th to 90th percentile (words / s) |
|---|---|---|---|
| nitzi | 6.1 | 1.63 | 1.29 to 2.03 |
| hero-son | 6.5 | 1.75 | 1.34 to 2.23 |
| tower-tamir | 6.3 | 1.60 | 1.32 to 2.01 |

About 100 words a minute, which is already on the slow side of adult speech **[R]** (the popular figure for ages 3 to 8
is about 120 wpm; Haake et al. 2014 found slowed speech, about 3.4 syllables/s, helped preschoolers' off-line
comprehension but hurt on-line processing, so "slower" is not always better). The longest clip today is
`count.birds.10.h3` (a count to ten): **15.8 s** for 21 words. `tools/voice_direction.py` uses 1.65 words/s to estimate
lengths; these are estimates, not measurements.

### 1.4 Other findings
- **[R]** `vo:core.rest.goodbye` is asked for by `app/lib/play/lesson_controller.dart:475` but there is no such line in
  `content/lines/core.he.json` (there is `core.goodbye.next`): that moment is silent today.
- **[R]** The 100 skill `childLine` texts are marked `spoken: yes` in the master table but have no `vo:` id; the app
  only shows them on the map card. They are left out of the plan.
- **[R]** The live helper's audio (`supabase/functions/_shared/elevenlabs.ts`) is made at `mp3_22050_32` with **no voice
  settings**, in the companion's own voice id. Next to 44.1 kHz pack lines it will sound duller and at a different
  loudness, and for a friend that borrows a narrator it is a different voice in the middle of a lesson (question 12).
- **[R]** No sound effects, music, ambient sound, haptics or volume sliders exist in the app yet (no audio asset, no
  `HapticFeedback`, one `AudioPlayer` for the voice). `audioplayers` 6.8.1 is already a dependency and supports several
  players and a low-latency mode, so the sound plan below needs **no new package**.

### 1.5 What the research says about the model
- **[R]** `eleven_v4_turbo` lists Hebrew (`he`) among its 90+ languages (ElevenLabs models page).
- **[R]** API voice settings: `stability` (default 0.5; lower = more range, less steady), `similarity_boost` (0.75),
  `style` (0; raises expressiveness and instability), `use_speaker_boost` (true), `speed` (1.0; the playground range is
  0.7 to 1.2). Request fields that help us: `seed` (more repeatable, "determinism is not guaranteed"),
  `previous_text`/`next_text`, `pronunciation_dictionary_locators` (up to 3), `apply_text_normalization`.
- **[R, conflicting]** A secondary source (eesel.ai) says v4 and v4 Turbo have **no style and speed controls** and no
  SSML; ElevenLabs' own pages do not say which settings v4 Turbo honours. Audition set C measures it (if speed 0.8 and
  1.2 give the same length, speed is ignored and pacing must come from punctuation alone).
- **[R]** v4 has inline **audio tags** (`[softly]`, `[pause]`, `[excited]`, ...), also on Turbo; tags are guidance, not
  guarantees, and they cost characters. **[G]** I do not use them in the plan: they would appear in the alignment that
  drives the mouth, a vague tag can be voiced as a sound, and punctuation already carries our pauses. They can be tried
  later on a handful of hero lines.
- **[R]** Hebrew TTS practice (community guides, Phonikud paper): point only ambiguous words; a wrong point is read
  literally; stress is the weak spot. This matches the text editor's partial-nikud choice.

---

## 2. The voices

### 2.1 The rule for gender
1. A character's own voice has the gender of the character's Hebrew grammar (a female character never speaks with a
   male voice). Exception by the owner's choice only: Jili (a masculine noun, a girl's voice; question 2).
2. A friend's **narrator** is the narrator of the same voice gender (Nitzi for a female voice, hero-son for a male
   voice); `narratorFor()` already does this by id. So the voice never changes gender inside a lesson.
3. No line refers to the speaker's gender (keeps every line usable by both narrators). The tutor lines address the
   **child** in the profile's form (f, m, n); that is the listener's gender, not the speaker's.
4. Original voices only, from the ElevenLabs library or Voice Design; never a clone of a real person
   (CLAUDE.md). No child actor's voice: the "young" library voices are adults; a real child's voice would need consent
   and is not needed.

### 2.2 The cast

| Character | Gender | Voice id today | Narrator | Says | The voice it should be [G] | Why |
|---|---|---|---|---|---|---|
| **nitzi** | f | `Tbj9…` | herself | every lesson line, her own lines | warm young woman, mid pitch, a smile in the voice, very clear Israeli Hebrew, unhurried; a kind gan teacher or big sister | the house voice for ~6,000 lines: clarity and warmth over character; must stay pleasant on the 700th "כמעט" |
| **hero-son** | m | `Ziof…` | himself | every lesson line, the live helper, his own lines | warm young man, light baritone, playful energy held in, very clear | the son's hero "the Leaper": energy, but a teacher's diction; low enough to differ clearly from Nitzi |
| alien-jili | masc. noun, girl's voice | `Tbj9…` (= Nitzi) | nitzi | own lines | bubbly and bright, a little higher and quicker than Nitzi | a jelly alien: fun; today it is literally Nitzi's voice |
| climber-tzuri | m | `8sZ9…` | hero-son | own lines | outdoorsy young man, upbeat, a bit breathy, a friendly coach | climbing energy without shouting |
| compass-romi | f | `Tbj9…` (= Nitzi) | nitzi | own lines | light, curious, younger-sister colour (adult voice) | "younger sister" in the pack |
| friend-daughter | f | `Tbj9…` (= Nitzi) | nitzi | own lines | soft and dreamy, a little slower, the gentlest of the cast | a starlight fox-dragon |
| inventor-gali | f | `Tbj9…` (= Nitzi) | nitzi | own lines | crisp and clever, mid-low pitch, an "aha" sparkle | an inventor |
| tower-tamir | m | `6Ijsl…` | hero-son | own lines | deep, slow, gentle giant | a tower: big and safe |
| weaver-keshet | f | `6Ijsl…` (= Tamir) | nitzi | own lines | warm older-sister woman, melodic, mid-low pitch | "older sister"; **needs a female voice of her own** |

The proposal keeps today's ids where they fit and asks the owner to pick new ones for the five friends who share
Nitzi's id and for Keshet (questions 1 to 3). Their own lines cost little (section 8), so distinct voices are cheap.

### 2.3 Which lines are a friend's "own"
**[G]** A friend's own voice is heard only at the **edges** of play, never in the middle of a lesson, so a child never
hears two voices take turns inside one activity:

- own voice: `core.greeting.hello`, `core.greeting.start`, `core.celebrate.well`, `core.placement.done`,
  `core.goodbye.next` (and the missing `core.rest.goodbye`), `core.ceremony.bronze/silver/gold/medal`: **9 lines,
  186 characters a voice**;
- narrator voice: everything said during a lesson, including the core encouragement, thinking and listening lines
  (`core.encourage.*`, `core.thinking.*`, `core.listen.*`, `core.stuck.*`, `core.breathe.*`) and the end-of-lesson
  celebration (`vo:celebrate.*`).

The friend's face and mouth are always on screen (the narrator only lends the sound). Alternatives with costs are in
question 4.

### 2.4 Band reads
The design spec asks for two reads of every Nitzi line (Band A slow, B/C natural). **[G]** One read per line is enough:
every activity belongs to one band, so its lines get the band's speed (A −0.03, B 0, C +0.03 on the style's speed);
lines shared across bands get −0.02. This halves the cost (question 8).

### 2.5 The per-name line
`homeBubble` (`{child}, הבקבוק הגיע.`) is still `proposed`. **[G]** One full clip per child per narrator ("<name>,
הבקבוק הגיע.") gives natural prosody; a name clip joined to a shared clip leaves an audible seam and a pitch jump. The
cost is trivial (about 20 characters a clip). The first name goes to ElevenLabs inside the line only (owner's decision
of 2026-10-25); nothing else about the child. Question 7.

### 2.6 The live helper
hero-son's 66 reviewed tutor lines (52 distinct) are made through the gateway (`tutor-prewarm`), not `voice_gen`.
They should use the `tutor` style and `mp3_44100_64` like the pack lines, and, for a friend that borrows a narrator,
the narrator's voice id (question 12). 2,247 characters, 0.09 USD to remake.

---

## 3. Tone and rhythm per kind of line

All lines: **warm, calm, clear; never shouting, never rushed, never babyish, never a scold.** "Not yet" is curious and
kind. A celebration is bright and short. Nothing sudden: a quiet start, a soft end.

The numbers are in `content/voices.proposed.json › styles` (model `eleven_v4_turbo`, `mp3_44100_64`, `language_code
he`, a fixed `seed`). **[G]** They are starting points for the audition, chosen from the API's documented behaviour
(stability lower = livelier but less steady; style above 0 amplifies and can wobble; similarity 0.8 to stay on the
chosen voice; speaker boost on).

| Kind | Style | Stab. | Sim. | Style | Speed (B) | Pause budget [G] | Pacing and energy |
|---|---|---|---|---|---|---|---|
| question / instruction / answer prompt | `ask` | 0.60 | 0.80 | 0.10 | 0.93 | 8 s (3 s answer prompt) | clear, the key word lightly stressed; a question ends with a soft rise, curious, not testing |
| hint 1, hint 2 | `hint` | 0.65 | 0.80 | 0.05 | 0.90 | 6 s / 8 s | a little slower than the question, pointing with the voice; no sigh |
| hint 3 (worked example) | `model` | 0.70 | 0.80 | 0.00 | 0.90 | 12 s | slow and even; "עכשיו תורכם" bright and inviting |
| number list, robot steps, colour or routine list | `list` | 0.75 | 0.80 | 0.00 | 0.90 | 16 s | every item whole, same pitch, an even breath at every comma (250 to 350 ms), the last item lands |
| correct | `warm` | 0.50 | 0.80 | 0.25 | 0.95 | 6 s | glad, not loud; a number answer alone, then a beat (about 400 ms), then the reason |
| not yet | `gentle` | 0.60 | 0.80 | 0.10 | 0.92 | 6.5 s | curious and kind; no falling "sad" pitch on כמעט; never disappointed |
| "I'm not sure" | `warm` | 0.50 | 0.80 | 0.25 | 0.95 | 3.5 s | welcoming, as if asking is good news |
| encouragement (core) | `warm` | as above | | | | 5 s | sincere praise of effort, never sugary |
| celebration, cheer | `cheer` | 0.35 | 0.80 | 0.45 | 1.00 | 4.5 s / 2.5 s | bright, a smile, short; peak held under −1 dBTP; today's `cheer` (0.1 / 0.9) is kept as `cheer_current` for the A/B |
| ceremony | `ceremony` | 0.45 | 0.80 | 0.35 | 0.92 | 3 s | proud and warm, a gift handed over, a little slower |
| greeting | `greet` | 0.45 | 0.80 | 0.30 | 0.97 | 3 s | friendly, the character's own colour |
| thinking (`המממ…`) | `think` | 0.55 | 0.80 | 0.20 | 0.90 | 3 s | the hum must be a hum, then a light thoughtful line; the ellipsis is a 500 ms thinking pause |
| listening repair | `gentle` | 0.60 | 0.80 | 0.10 | 0.92 | 5.5 s | soft; the fault is the helper's ears, never the child's speech |
| calm, goodbye | `calm` | 0.70 | 0.80 | 0.05 | 0.88 | 4.5 to 5 s | slow, soft, a quiet ending; no "come back" pressure |
| helper (tutor) | `tutor` | 0.60 | 0.80 | 0.10 | 0.95 | 7 s | the same sound and loudness as the lesson lines around it |

Default `settings` (any line no rule covers): stability 0.55, similarity 0.8, style 0.15, boost on, speed 0.95.

**Pauses come from punctuation only** (v4 has no SSML break; the text editor's punctuation is the tool): `,` a light
breath (200 to 350 ms), `.` a real pause (about 450 ms), `—` a held beat (about 300 ms), `:` a small lift and a beat,
`…` a thinking pause (about 500 ms). These lengths are what to listen for, not settings. Between two clips the app adds
250 ms (`VoiceDirector` gap). **[G]** Each clip should start within 50 ms of the first sound and end within 150 ms
after the last (trim with 10 ms fades; change C8).

---

## 4. Direction per line (`docs/audio/voice-direction.csv`)

One row per **distinct `voice_text`** of the 6,274 spoken `text-ready` rows (the 33 `proposed` rows wait; the 100 skill
`childLine` rows are not voiced by the app): **1,862 rows** (1,784 lesson lines for the narrators, 26 core lines, 52
tutor lines). Columns: `line_key` (source › id of the first row), `rows_sharing`, `vo_ids` (how many `vo:` ids say
it), `first_vo`, `kind`, `band`, `scope` (narrator / own / tutor), `voices`, `style`, `speed`, `pace` (band, speed,
estimated length against the budget, `OVER` when longer), `pause_notes`, `listen_for`, `pronunciation` (proposed
entries), `note_for_text_editor`, `chars`, `voice_text` (copied, never changed).

Kinds found: 461 correct, 424 hint 3, 361 questions, 138 celebrations, 128 lists, 128 instructions, 46 not-yet,
44 + 44 hints 1 and 2, 10 answer prompts, and the core and tutor kinds. The most shared lines:
`שאלה טובה, בואו נראה יחד.` and `כמעט, בואו ננסה שוב.` (767 rows each), `בואו נקשיב שוב לשאלה.` (625),
`נסתכל לאט על כולם, אֶחָד אֶחָד.` (434): each is voiced once per voice.

**How it was checked.** The rules were run, then a seeded sample of 220 rows (`--sample 220`) was read line by line
against its direction. What the reading changed in the rules:
- lists were only found for numbers and robot steps; colour, animal and routine lists (`בונים את הקשת: אדום, כתום,
  …`, `כן, דג, ציפור, דג, ציפור…`) are now found too (any line with four or more commas between one- or two-word items);
- Band A came out too slow (0.83 for a worked example); the Band A offset is now −0.03 and the list and model speed 0.90;
- `core.placement.done` is encouragement, not a cheer;
- the first budgets flagged 247 lines; after reading them most were ordinary two-sentence questions, so the budgets were
  widened (49 lines are still over, all listed with `OVER`);
- `בתור` was first a doubtful entry; every voiced line with it is about a queue (ordinals), so `בַּתּוֹר` is right;
- new notes for the text editor: a correct line that starts `לא,`, the comma inside `N, ועוד M:`, and the counts that
  end on a different number than the one to press (section 10).

**Pronunciation.** 228 rows carry a proposed entry, from 23 words (`content/voices.proposed.json › pronunciation`
lists the 15 that need it most): `חום / החום` (the colour), `חסר / החסר`, `שווה / שווים / שוות` (the = sign is
`שָׁוֶה`), `מספר`, `המחוג`, `ברונזה`, `מדליה`, `וואו`, `המממ`, the solids and polygons, `המאזניים`, `נבט`, `בתור`. Each
keeps the letters and adds points; the text editor confirms the pointing, and set B of the audition shows which ones
ElevenLabs needs at all. All numbers in spoken lines are words with points (gender and stress kept), and no line has a
digit or a symbol (the editor's check).

---

## 5. Music, effects, silence and haptics

### 5.1 What exists and what is missing
**[R]** Exists: the voice (one player, mouth cues, the waiting rules of `VoiceDirector`). Missing: every effect, the
music, ambient sound, haptics, the parent sliders (music, effects, voice) and the calm mode. Design spec section 11
defines the palette and the mix; this plan makes it concrete. Plan only: no audio file is made here.

### 5.2 Earcons (the same sound for the same event, everywhere)
**[G]** Timbres from the spec's instruments (ukulele, marimba, glockenspiel, kalimba). Energy kept between 400 Hz and
4 kHz (phone speakers have little below 200 Hz), at least 5 ms attack (no click), a soft tail, short.

| Event | Sound | Length | Level (vs. voice) | Notes |
|---|---|---|---|---|
| tap | wooden "tok", 3 variants ±50 cents | 40 to 60 ms | −10 dB | on touch-down, within one frame |
| pick-up / drop | rising "bloop" / soft "pat" | 120 ms | −10 dB | drop outside a zone: the float home is silent |
| snap | "click-pop" | 80 ms | −8 dB | with a light haptic |
| **correct** | 3-note rising pentatonic chime (glockenspiel), 6 transpositions in the music's key | 450 to 600 ms with tail | −6 dB | the line "correct" waits 150 ms after it, never the reverse |
| **not yet** | a very soft muted low marimba "bum", one note, no falling interval | 200 ms | −14 dB | never a buzzer, never a descending minor third; no haptic (question 6: or silence) |
| hint lamp / hint | twinkle, 3 to 4 high soft notes | 400 ms | −10 dB | the lamp glowing has no sound of its own |
| "I'm not sure" tapped | soft chime (the spec's) | 300 ms | −10 dB | celebrates asking |
| **discovery** (the "another way" flip, a new land) | glissando up, harp or celesta, synced to the 700 ms flip | 700 ms | −8 dB | an unlock, never a failure |
| spark to the trail | glass bell, constant pitch (small random variants) | 300 ms | −12 dB | not a rising scale: a rising pitch per item feels like a count-down |
| **coin on the counter** (shop) | one soft metallic "tink" per coin; a soft paper "fff" for a note | 120 ms | −12 dB | never a cash-register "ka-ching" (no sounds that sell) |
| **tracing** | a quiet chalk texture that follows the finger's speed, stops when the finger lifts; a small chime when the shape is done | continuous | −20 dB | off the path: the texture just fades, no error sound |
| mic open / close | "bloop-up" / "bloop-down" | 150 ms | −8 dB | music fully off while listening |
| Tier 2 (end of activity, sticker) | a 2 s phrase of the main theme (ukulele strum, glockenspiel) | 2 s | −6 dB, ducked under the line | |
| Tier 3 (skill mastered) | a 5 to 7 s musical sting, tap to skip after 1.5 s | 5 to 7 s | −6 dB | rare by design |
| ceremony | a soft brush roll (1 s) into a chime, then the voice line | 2 s | −8 dB | the voice never starts over the roll |
| scenery taps | small character sounds (splash, chirp) | < 500 ms | −12 dB | off during instructions |

### 5.3 Music and ambient
- **Main theme** 4 bars at 100 bpm; **land variants** (marimba, kalimba and strings, woodblocks and pizzicato, celesta
  and harp, soft mallets, oud and accordion) as seamless 30 to 60 s loops; during an activity the music drops to a bed
  (or off, a parent option).
- **Lullaby variant** for the wind-down: 70 bpm, celesta and soft strings, 2 s cross-fade from the bed, then it fades to
  silence over about 30 s on the rest screen.
- **Ambient** (waves, birds) on the map only, at about −36 LUFS, paused while any line is spoken.
- **Silence is part of the design**: no music under a question in Band A **[G]** (the bed comes back after the child's
  first move), no sound while the child thinks, nothing that hurries.
- **[G] Format:** short effects as WAV (low-latency player); music as AAC/M4A with the loop cross-faded inside the file
  (MP3 and AAC add encoder gaps; to test on the phone). Delivered in a signed audio pack like the voices.
- **Source:** commissioned score (the spec's recommendation) or a library with an app licence; original only, never
  "in the style of" a named artist (question 9).

### 5.4 The mix (design spec section 11, made concrete)
- Voice **−16 LUFS integrated** per clip (normalised at generation, change C8), true peak **≤ −1 dBTP**; music bed about
  **−28 LUFS**; effects peak at least 6 dB under the voice. **[R]** AES TD1004 recommends −16 LUFS as the maximum and
  −20 as the minimum target for mobile playback; ITU BS.2434 lists −16 LUFS with −1 dBTP for short-form content.
- **The voice ducks the music by 14 dB** (attack 120 ms, release 600 ms) and the ambient fully. The duck starts when a
  line is queued, so the first syllable is never masked.
- **No effect starts within 150 ms of a voice onset**; an effect under a voice plays at −6 dB.
- **The game ducks itself when the mic opens** (music off, no effects but the mic bloops).
- **Three parent sliders** (music, effects, voice) multiply the device media volume, which is always respected.
- **Calm mode**: no music, effects only for correct, discovery and the mic, no Tier 3.
- Implementation **[G]**: a small `SoundDirector` beside `VoiceDirector` with three channels on `audioplayers`
  (`PlayerMode.lowLatency` for effects, one music player with volume ramps for the duck); `VoiceDirector.speaking` and
  the mic state drive the duck and the 150 ms rule. No new package.

### 5.5 Haptics
Light impact on pick-up and snap, a success haptic on correct, none on "not yet" (never a punishment), never continuous,
a parent toggle, system settings respected. Synced to the Rive events `hopLanded`, `celebrateDone`, `pokeDone` when
Rive arrives; until then on the same code events as the earcons. Flutter's built-in `HapticFeedback` is enough.

---

## 6. Changes needed before voicing (for the main assistant, with the owner's OK)

The current `voice_gen` would voice the wrong texts in the wrong voices. In this order:

| # | Change | Why |
|---|---|---|
| C1 | Read the **`voice_text`** of each `vo:` id (for example a generated `content/lines/voice-text.he.json`, `vo:` id → voice text, made from the master table once the owner approved it) instead of the pointed caption | today it would voice the old pointed texts with "!" |
| C2 | A **scope**: narrators (nitzi, hero-son) say every line; a friend says only its own lines (section 2.3); move the 28 old lesson lines out of each friend's work folder | the owner's Q5 decision; old friend lines would shadow the narrator |
| C3 | Voice **once per distinct text** and let several `vo:` ids point at the same file in the pack | 112,228 → 76,822 characters a narrator (−32%) |
| C4 | Per-line **style and speed** from `docs/audio/voice-direction.csv` (or `*.suffix` patterns in `styleRules`), the default `settings`, and the `seed` | prefix rules cannot tell a hint from a prompt |
| C5 | Pronunciation matched on **whole words** | substring replacement corrupts other words |
| C6 | **Mouth cues without nikud**: take the word timings of the sent text and, word by word, the points of the matching `ui_text` word (fallback: open on each letter group, closed at spaces and punctuation) | otherwise the mouth flaps at a fixed rhythm |
| C7 | Store a **hash of the sent text and settings** in each cue file and say a line again when it changed (or a `--fresh` flag) | the reuse rule would keep old audio for a corrected text |
| C8 | **Loudness and trim** after each clip: two-pass `ffmpeg loudnorm` to −16 LUFS / −1 dBTP, lead silence ≤ 50 ms, tail ≤ 150 ms, 10 ms fades; a report of LUFS, peak and length per clip | even loudness; needs ffmpeg on the PC (question 10) |
| C9 | Add the missing `core.rest.goodbye` line (text editor) or point the app at `core.goodbye.next` | silent today |
| C10 | Gateway: `mp3_44100_64`, the `tutor` style, and the narrator's voice id for a friend that borrows one | same sound as the pack lines |
| C11 | `audition --voice <id>` to try a library voice without editing `voices.json` | needed for audition set A |

Then a free **mock run** (`voice_gen mock`) to check the packs, the shared files and the cues before any paid run.

---

## 7. The audition (the owner listens first)

`docs/audio/audition.csv` lists every clip with its text, style and settings: **163 clips, 4,309 characters, about
0.17 USD** at 0.04 USD per 1,000. Nothing runs until the owner says yes to that number.

- **Set A, voice choice (3,621 characters).** For each narrator, the 12 lines below × 3 voices (today's voice and two
  candidates the owner picks from the ElevenLabs voice library, filtered to Hebrew; listening to library previews is
  free). For each friend, 3 own lines × 3 voices.
  1. `שלום, בואו נשחק.` (greeting) 2. `יש שְׁלוֹשָׁה דגים. אֶחָד שחה משם. כמה נשארו?` (Band A question)
  3. `איפה הפרח החום?` (the colour word) 4. `בואו נקשיב שוב לשאלה.` (hint, 625 rows)
  5. `אַחַת, שְׁתַּיִם, … המספר האחרון אומר כמה: חָמֵשׁ. עכשיו תורכם — ללחוץ על חָמֵשׁ.` (count list)
  6. `הצעדים הם: למעלה, למעלה, ימינה, ימינה, למעלה. עכשיו תורכם.` (robot steps)
  7. `חָמֵשׁ. תֵּשַׁע פחות אַרְבַּע שווה חָמֵשׁ.` (number answer, `שווה`) 8. `כמעט, בואו ננסה שוב.` (not yet, 767 rows)
  9. `שאלה טובה, בואו נראה יחד.` (unsure, 767 rows) 10. `המממ… בואו נספור לאט, מספר אחרי מספר.` (the hum, 60 rows)
  11. `וואו, ספרתם עד עֶשֶׂר.` (celebration) 12. `הנה גביע ברונזה בשבילכם.` (ceremony, a loan word)
- **Set B, style and words (604 characters)**, in the chosen narrator voices: `cheer` against `cheer_current` on 3
  cheers; 6 lines with the pronunciation entries applied, to compare with the same lines in set A (the `המחוג` line
  has no twin in set A).
- **Set C, does the model honour the settings? (84 characters)**: one hint line at speed 0.8 and 1.2 and style 0 and
  0.9. I measure the four lengths from the files (no listening needed); equal lengths mean the setting is ignored.

What the owner listens for: section 9, plus "which voice would I want to hear a thousand times".

**Commands** (Windows PowerShell; needs C11 for the candidate rows; the `current` rows work today):

1. Pick the candidate voices in the ElevenLabs voice library and type their ids into the `voice_id` column of
   `docs/audio/audition.csv` (rows `cand2`, `cand3`, and `chosen` after set A).
2. Set `ELEVENLABS_API_KEY` in this PowerShell window the way you did for the M8 run (never printed or saved).
3. Run:

        cd D:\Children-Learning-App\app
        New-Item -ItemType Directory -Force "$env:USERPROFILE\nitznutz-audition" | Out-Null
        $rows = Import-Csv ..\docs\audio\audition.csv -Encoding UTF8 | Where-Object { $_.voice_id -ne '' -and $_.set -eq 'A' }
        foreach ($r in $rows) { dart run tool/voice_gen.dart audition $r.character $r.text --voice $r.voice_id --settings $r.settings --out "$env:USERPROFILE\nitznutz-audition\$($r.clip)-$($r.character)-$($r.candidate).mp3" }

4. Listen, choose, fill `chosen` ids, then run the same loop with `$_.set -eq 'B'` and `'C'`.

---

## 8. The voicing plan and the cost (never run)

Price: `eleven_v4_turbo` **0.04 USD per 1,000 characters** (docs/PLAN.md; eesel.ai gives the same list price). The
Creator plan includes **275,000 characters a month**. Counts from `tools/voice_direction.py` on the 1,862 distinct
`text-ready` texts (characters as Unicode code points, as `voice_gen` counts them; number-word points included).

| Part | Lines | Characters | USD |
|---|---|---|---|
| (a) nitzi: every lesson line + all 26 core lines | 1,810 | 77,461 | 3.10 |
| (a) hero-son: the same | 1,810 | 77,461 | 3.10 |
| **(a) both narrators** | | **154,922** | **6.20** |
| (b) each friend's own lines, 9 lines (recommended, section 2.3) | 7 × 9 | 7 × 186 = **1,302** | **0.05** |
| (b, alternative) each friend: all 26 core lines | 7 × 26 | 4,473 | 0.18 |
| (b, alternative) each friend: 26 core lines + 138 lesson celebrations | 7 × 164 | 30,324 | 1.21 |
| (t) hero-son tutor lines (gateway, remake with the new style) | 52 | 2,247 | 0.09 |
| audition (section 7) | 163 clips | 4,309 | 0.17 |
| pilot (counting lessons and the most shared lines, both narrators) | 2 × 45 | 4,212 | 0.17 |
| **Recommended total: (a) + (b) + (t) + audition** | | **162,780** | **6.51** |

- Pronunciation entries, if adopted, add 577 characters a narrator (+1,154, +0.05 USD).
- The 33 `proposed` rows add about 1,119 characters a narrator (+0.09 USD for both) once the owner approves them.
- **(c) Lines already voiced that will be voiced again** (all inside (a) and (b), not extra): nitzi 316 and hero-son 316
  lines (12,464 characters each), each friend 25 core lines (606 characters each; under the recommended own set only
  9 of them stay); in all 29,170 characters, 1.17 USD. 2 old clips per narrator and 1 per friend have no `text-ready`
  line (`core.encourage.checked`, still proposed); the 28 lesson clips in each friend's folder are dropped, not
  re-voiced.
- For comparison: `voice_gen plan` today says 1,359,619 characters and 54.38 USD (all nine voices, every `vo:` id, the
  old texts); voicing per id instead of per text would be 225,734 characters (9.03 USD) for the two narrators.
- The whole recommended run is **about 0.6 of one Creator month**.

**Order:** (1) C1 to C11 and a mock run (free); (2) the audition (0.17 USD, his OK) and the owner's choices merged into
`content/voices.json`; (3) a **pilot**: the counting lessons and the most shared lines for both narrators (4,212
characters), installed on the phone, listened to, and measured (C8 report); (4) nitzi in full, then hero-son;
(5) the seven friends' own lines; (6) the tutor lines through the gateway; (7) the new texts and the voice packs go into
a new pack version together (voice packs `2.0.0`).

**Commands for the paid runs** (after C1 to C11; `N` is the number `plan` prints, **typed by the owner**, never by an
agent):

    cd D:\Children-Learning-App\app
    dart run tool/voice_gen.dart plan --characters nitzi,hero-son --price 0.04
    dart run tool/voice_gen.dart generate nitzi --confirm-chars <N for nitzi> --pack-version 2.0.0
    dart run tool/voice_gen.dart generate hero-son --confirm-chars <N for hero-son> --pack-version 2.0.0
    dart run tool/voice_gen.dart plan --characters alien-jili,climber-tzuri,compass-romi,friend-daughter,inventor-gali,tower-tamir,weaver-keshet --price 0.04
    dart run tool/voice_gen.dart generate <friend> --confirm-chars <N for that friend> --pack-version 2.0.0

If the changes are made as described, `plan` should print about 77,461 for each narrator (78,038 with the pronunciation
entries) and about 186 for each friend; the number `plan` prints is the one that counts.

---

## 9. Listening checklist (every batch)

1. The right voice and the right gender for the character; the friend's own lines only at the edges of play.
2. No clipped first or last syllable; no click at the start or end; lead silence ≤ 50 ms, tail ≤ 150 ms.
3. Loudness even across lines: −16 LUFS ±1, true peak ≤ −1 dBTP (C8 report; ffmpeg `ebur128`).
4. Numbers in the right gender, as pointed; `שֵׁנִי` is the ordinal; no odd stress on a number; `שווה` is `שָׁוֶה`.
5. Every list item said whole and evenly; nothing rushed at the end of a long count.
6. Questions end with a soft rise; "not yet" never sounds disappointed; celebrations never shout.
7. The hum `המממ` is a hum, not letters; `וואו` is "wow".
8. Loan words and rare words: `ברונזה`, `מדליה`, `המחוג`, the solids.
9. The line fits its pause budget (`pace` column); the measured length is within 25% of the estimate.
10. The mouth follows the words (C6), and closes in the pauses.

---

## 10. Requests for the hebrew-text-editor (punctuation first; letters only by the editor's decision)

| # | Rows | Request |
|---|---|---|
| T1 | `activity.b.mathb06.1`–`.8` › `hints.2` (8 rows) | drop the comma in `N, ועוד M:` so the sum is one phrase, as in `mathb01`/`mathb02` (`שֵׁשׁ ועוד שָׁלוֹשׁ:`) |
| T2 | `activity.b.numb18.2`, `activity.b.shpb04.2`, `activity.log.pat.no.mixed` › `feedback.correct` | `לא,` → `לא.` (the answer alone, then the reason, as for number answers); `לא,` at the start of a correct line can sound like a not-yet |
| T3 | `activity.b.mathb02.7`–`.10`, `activity.b.mathb06.1`–`.8` › `hints.2` (12 rows) | heard aloud, the count ends on the total but the child is asked to press the addend: the same problem as G1 (`mathb18`), but these rows are `text-ready`. Wording question for the editor and the owner |
| T4 | `core.listen.again` | about 7 s; a full stop instead of the dash would give a real breath: `לא שמעתי טוב. אפשר להגיד שוב, או ללחוץ על התשובה.` |
| T5 | `activity.x.mathb19.7` › `feedback.incorrect.0` | about 9 s for a not-yet; shorter wording if possible |
| T6 | 26 long count lists (`LONG LIST` in the CSV) | no change now; only if the pilot shows them rushed: `…` between the numbers (as offered in hebrew-notes.md section 6) |
| T7 | the 23 pronunciation words (`pronunciation` column) | confirm the pointing of each proposed entry |
| T8 | `המממ` (core lines and 60 rows) | if the audition reads it as letters, the editor chooses another spelling |
| T9 | 100 skill `childLine` rows | marked `spoken: yes`, but the app has no `vo:` id for them and never says them; `spoken: no`, or a voiced map card (owner) |
| T10 | `activity.col.world.banana.ripe`, `activity.col.world.sun` | the answer `כן, זה כדור צהוב.` names a ball after a question about a banana or the sun; if the tiles are balls it is right, but to the ear it sounds off |
| T11 | `vo:core.rest.goodbye` | the app asks for it and no line exists (C9) |

---

## 11. What I did not check

- **I did not listen to anything.** Every statement about how a line will sound is a guess until the owner hears it.
- Loudness and silence of the existing clips: ffmpeg is not installed, so only lengths (from MP3 headers) were measured.
- Which voice settings `eleven_v4_turbo` really honours (style, speed): conflicting sources; set C answers it.
- Whether ElevenLabs needs any of the pronunciation entries; whether `seed` makes takes repeatable for Hebrew.
- The genders of the voice ids (the voice library was not called); Keshet's conflict follows from the code either way.
- The band speeds and pause budgets against real children; Band B slots were read with one example each (the editor's
  note), and of the 1,862 rows I read about 260 (the sample, the over-budget lines and the editor notes).
- The music, effects and haptics are a plan; nothing was designed in sound yet.

## 12. Owner questions

See the report; the same list with audio descriptions, kept here for the record:

1. Keshet shares Tamir's voice: give her a warm, melodic female voice of her own (recommended), or move her lesson
   lines to hero-son (a girl with a man's voice in lessons; not recommended).
2. Jili (a masculine word, a girl's voice): keep the bubbly girl's voice and Nitzi as narrator (recommended), or a
   boy's voice and hero-son.
3. Five friends share Nitzi's voice: pick their own voices in the audition (their own lines cost 0.05 USD for all
   seven), or keep them sounding exactly like Nitzi.
4. A friend's own voice: only at the edges (greeting, cheer, ceremony, goodbye; recommended, 0.05 USD), all 26 core
   lines (0.18 USD; the friend's voice would cut in mid-lesson for encouragement and listening lines), or also the
   lesson celebrations (1.21 USD; the friend's voice for the end-of-lesson cheer).
5. Cheer: today's very lively setting (stability 0.1, style 0.9: big swings, may wobble or overshoot) or the steadier
   proposal (0.35 / 0.45: bright but even). Decide after set B.
6. "Not yet" sound: a very soft single low marimba note (recommended), the spec's "boing" (comic), or silence with
   only the wobble.
7. The per-name line: one natural clip per child per narrator (recommended) or a name clip joined to a shared clip
   (a small seam and pitch jump).
8. Band reads: one read per line at the band's speed (recommended) or two reads of every line (double cost).
9. Music: commissioned (warm acoustic, as the spec), a licensed library, or no music for now (voice and earcons only).
10. Install ffmpeg on the PC (free, `winget install Gyan.FFmpeg`) for loudness measurement and normalisation.
11. The pronunciation entries: adopt the ones set B shows are needed.
12. The live helper: speak in the narrator's voice for friends that borrow one (no voice switch mid-lesson;
    recommended), or in the friend's own voice.

## 13. Sources

- ElevenLabs, models overview (Hebrew in the v4 family): https://elevenlabs.io/docs/overview/models
- ElevenLabs, text to speech with timestamps (request fields, voice settings): https://elevenlabs.io/docs/api-reference/text-to-speech/convert-with-timestamps
- ElevenLabs, playground text to speech (speed 0.7 to 1.2; stability, similarity, style): https://elevenlabs.io/docs/product-guides/playground/text-to-speech
- ElevenLabs, audio tags for v4 (also on Turbo): https://elevenlabs.io/blog/elevenlabs-audio-tags-list
- ElevenLabs, prompting v3 (stability presets and tags): https://elevenlabs.io/docs/best-practices/prompting
- eesel.ai, "Eleven v4 erklärt" (v4 settings, no SSML, price 0.04 USD per 1,000 for Turbo): https://www.eesel.ai/de/blog/eleven-v4-erklaert
- Phonikud (Hebrew G2P and stress, compares ElevenLabs): https://phonikud.github.io/
- Haake et al. 2014, "The slower the better?" (slowed speech and preschool comprehension): https://lup.lub.lu.se/search/files/2053614/4279978.pdf
- Hearing Health Matters, "Can children understand fast speech?" (popular figure ~120 wpm): https://hearinghealthmatters.org/hearing-and-kids/2013/can-children-understand-fast-speech/
- AES TD1004.1.15-10, loudness for streaming and network file playback (−16 to −20 LUFS for mobile): https://www.production-expert.com/home-page/2015/11/17/aes-release-recommendations-for-loudness-of-audio-streaming-and-network-file-playback
- ITU-R BS.2434 (−16 LUFS, −1 dBTP for short-form content): https://www.itu.int/dms_pub/itu-r/opb/rep/R-REP-BS.2434-2018-PDF-E.pdf
- Repo: `docs/design-spec.md` sections 5.4, 10 and 11; `docs/PLAN.md` (ElevenLabs prices); `docs/milestones/M9.md` Q5.
