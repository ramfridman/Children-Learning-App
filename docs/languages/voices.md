# Languages: voices and the pilot plan (English, Hebrew, Russian)

Owner of this file: voice-and-sound-director. Date: 2026-11-03. Status: **plan only**. Nothing was voiced, no audition was run, no ElevenLabs key or API was used, and nothing here costs money until the owner runs a command and types its character count himself (`CLAUDE.md` › Characters and money).

Inputs: `docs/languages/README.md` (decision 6), `decisions-2026-11-03.md` (decisions 1, 2, 5, 6, 16, 21), the three `voice-brief.md` files, `russian/pronunciation.csv`, `content/voices.json`, `app/tool/audition_lib.dart`, `app/tool/voice_text_lib.dart`.

Legend for claims: **[M]** measured here (the free plan command, a character count); **[R]** read on a public page (cited in section 10); **[G]** a guess or a hypothesis the pilot must test.

---

## 1. The question the pilot answers

Each language needs a teaching voice that says **natural Hebrew** (the instruction) and the **target language natively** (the thing taught), and that can say **isolated sounds and CV units cleanly**. Nobody can know from a web page whether a voice does that. The pilot is a cheap, ordered listening test:

1. isolated sounds and stretched sounds (the hardest, and the one the fallback of decision 2 is for);
2. CV units and syllables;
3. minimal pairs (each word its own clip);
4. whole words (stress traps) and short chunks;
5. a Hebrew instruction followed by a target-language word, **as separate clips** (the split-clip rule, section 4).

Two possible answers per language (the briefs call them A and B):
- **A. One voice** that passes both the Hebrew and the target-language checks.
- **B. Two voices that sound like one teacher pair**: a Hebrew teaching voice for the frame and a native voice for the target clips, matched in warmth, pace and loudness. The briefs already say the target language wins when a choice must be made.

---

## 2. The shortlists (3 to 4 voices per language, plus a control)

**What I could and could not find [R].** ElevenLabs' public pages do not publish a list of voices verified for Hebrew. The voice pages in the Library show "verified languages" per voice, but the Library is a script-driven page that a public fetch cannot read, and third-party listings did not show Hebrew for any ElevenLabs voice. So **no Hebrew-verified library voice can be named from public pages**. What is solid: ElevenLabs lists Hebrew, English and Russian for `eleven_v4`, `eleven_v4_turbo` and `eleven_v3` (not for Multilingual v2 or Flash v2.5), so a voice that is not Hebrew-native can still be asked to speak Hebrew, and its **own accent will show** (`docs/audio/voice-quality-diagnosis.md` P7). The shortlists below are therefore voices chosen for their *target-language* or *Hebrew* strength, and the pilot finds out the other half.

The new characters are written in `docs/languages/voices-candidates.json` (a proposal for `content/voices.json`; not merged). Every voice is an existing ElevenLabs library or default voice. None is a cloned or imitated real person, and none is named after one. I did not check that any name coincides with a public figure; the owner is the final check when he hears them (a voice that sounds like a famous person is dropped).

### English (General American, decision 5)
| Pilot name | What the public listing says [R] | Why it is here | Unknown [G] |
|---|---|---|---|
| `lang-en-jessica` | default voice, American, female, young, "playful, warm, expressive" | American accent for sure; warm | Hebrew will probably carry an American accent: fine for option B |
| `lang-en-sarah` | default voice, young woman, "confident and warm, reassuring", soft | calm and soft: good for a 3 to 8 teacher | accent in Hebrew; "news" register may be flat |
| `lang-en-matilda` | default voice, female, "friendly, pleasing alto" | warm, lower pitch, a gentler teacher | accent not stated: must be heard as General American |
| `lang-en-brian` | default voice, male, "resonant and comforting" | a male English teacher for the pair | accent not stated (I believe American): check by ear |
| control: `nitzi` | the app's Hebrew house voice (`Tbj9…`) | answers "does our Hebrew voice speak English?" (option A from the other side). Expected: Israeli accent in English (brief §4.3) | everything |

The voice ids of the four default voices come from a third-party list of ElevenLabs default voices, not from the owner's account. The owner confirms each in his Library (section 9, step 1). Default voices can be renamed, replaced or limited by plan, so a missing one is replaced by a Library search "American, female, calm/warm, narration", not by guessing an id.

### Russian (standard Moscow norm)
All four are labelled Russian on a third-party listing of ElevenLabs Library voices [R]; none has a voice id in this repo, so the owner copies them (empty `voiceId` in the candidates file).
| Pilot name | Listing [R] | Why it is here |
|---|---|---|
| `lang-ru-marina` | female, middle aged, "soft, clear, warm" | clear and warm: the closest to a kind teacher |
| `lang-ru-ekaterina` | female, young, Moscow, "soft, silky, tender" | the Moscow norm named on the listing |
| `lang-ru-maxim` | male, middle aged, Moscow, "calm, neutral" | the neutral, norm-like male voice |
| `lang-ru-ivan` ("Ivan Nazarov") | male, narrator, "soft, unhurried", **listed for Russian and English** | the one listing that names a second language: the best chance for a voice that is also good in English (a second use) |
| control: `nitzi` | Hebrew house voice | tests the briefs' worry: a Hebrew voice reading Russian (Israeli-Russian features: uvular р, unreduced о, no hard/soft contrast) |

Other Russian candidates to swap in if one fails: Kate ("calm, natural"), Irina ("soft, warm, gentle"), Rina ("soft, clear, comforting"), Felix ("calm, clear, friendly") [R].

### Hebrew course (a clear, warm teaching voice)
| Pilot name | What is known | Why it is here |
|---|---|---|
| `nitzi` (`Tbj9…`) | the app's flagship female narrator, chosen by the owner in the earlier audition | warm young woman, clear Israeli Hebrew (`docs/audio/voice-direction.md`) |
| `hero-son` (`ZiofZ…`) | the app's flagship male narrator | a male teacher; same register as the tutor |
| `climber-tzuri` (`8sZ9…`) | an existing male friend voice, "outdoorsy, upbeat, a bit breathy" | a third known Hebrew voice, to see whether the *CV and sound* quality differs between voices |
| optional fourth | none can be named from public pages | the owner may add any Library voice he finds with the language filter set to Hebrew (`--he nitzi,hero-son,climber-tzuri,lang-he-library` in the generator) |

Why only known voices: for Hebrew, the owner already proved these voices say Hebrew prose well. The new question is only whether they can say **a lone consonant, a CV unit and a shva word**, and a new unknown voice would add risk and a second variable. A better library voice is welcome but is not needed to learn the answer. A voice that works for letter sounds but is the wrong character for the friends is fine: the Languages lessons use their own teaching voice (decision 6).

---

## 3. Model and settings

- **Model: `eleven_v4`** for every pilot clip. Hebrew, English and Russian are all listed for it, it is the quality model, it accepts IPA written in slashes, and it is the model the round-1 diagnostic leaned toward [R]. `eleven_v4_turbo` (half the price, built for live speed) is run only on **8 comparison clips per language** in round 2 to see whether it is good enough for the later bulk run [R/G].
- **Language code per clip** (`he`, `en`, `ru`): always set to the language of the clip. The Hebrew frame is Hebrew, the target word is English or Russian. A voice that is not native in a language is steered most by this setting plus the text [G].
- **Settings, sent explicitly with every clip** (the rule of `voice_gen`): stability 0.5, similarity 0.75, speaker boost on = the same as the Hebrew round-1 diagnostic, so the Hebrew clips are comparable with it. Style and speed are not sent on v4 (the repo rule: v4 does not use them [R]).
- **One stability variant** only: stability 1.0 ("Robust") on four isolated sounds (s, m, t, æ) of the English round 2; if it helps there, the same variant is added for Russian and Hebrew sounds in a round 2b. Hypothesis [G]: a higher stability gives a steadier, more repeatable lone sound. If it does, the isolated-sound clips use it and the speech clips stay at 0.5.
- **Pauses.** v4 does not read break tags [R]. Pauses inside a clip come from `…`, a full stop or a split into several clips; the long pauses (about 250 ms between the Hebrew frame and the target, 300 to 350 ms between robot-talk sounds) are **silence added by the app between clips**, never typed into the text.
- **No exclamation marks, no audio tags** in the pilot (the app's rule). A word is sent with a full stop (`wet.`) because a bare word is the most likely to be mis-read as a letter or to hallucinate; two bare-word clips test that in round 2 (`wet`, `vet`).
- **Output** `mp3_44100_64`, as the rest of the app. If a stop or a fricative sounds dull at 64 kbps, the diagnostic's 128 kbps question applies (round 1 of the Hebrew diagnosis) and is not repeated here.
- **Pronunciation steering to be tested, not assumed:** (a) the sound written as a letter repeated (`ссс`, `mmmm`); (b) the sound in IPA in slashes (`/s/`); (c) the key word with the sound stretched (`sssun`); (d) in Russian, the stress mark U+0301 against no mark against IPA. Each form is its own clip, so the listener sees which form works for which sound.

---

## 4. The split-clip rule (all three languages)

1. **One clip, one language.** A Hebrew clip contains only Hebrew; an English clip only English; a Russian clip only Russian. A line like "איפה ה-cat?" is two clips: the Hebrew instruction, then the target word (`pronunciation-spec` §3; the three briefs).
2. **Each clip has its own `language_code`**, and the target clips are generated once and reused wherever the word appears.
3. **The gap is the app's, not the voice's:** about 250 ms between a Hebrew instruction and the target clip; 300 to 350 ms between robot-talk sounds, 150 ms for stretch-and-blend, 600 ms before the whole word (English brief §5.2); about 300 ms between Hebrew units.
4. **Same voice or matched pair.** Option A plays both clips in one voice. Option B needs the pair to match: loudness within 1.5 LU, similar words per minute, a similar age and warmth. The pilot's step 5 gives the listener the join to judge.
5. **Never fix a voice by changing the shown text.** `shown` stays; only `say` changes (the three pronunciation specs).
6. The child's first name never enters a language-course clip (nothing about a child goes to a vendor beyond the 2026-10-25 exception, which these lessons do not use).

---

## 5. The pilot, in two rounds

Both rounds follow the five-step order above; the clip id says the step (`en-sarah-01-…` is step 1). Each clip carries a `tests` note: **what the listener must hear**.

**Round 1 (screening), all candidates, a reduced set.** About 23 to 32 clips a voice: 6 isolated sounds in two or three forms, 2 CV units, 6 to 9 minimal-pair words, 3 to 9 whole words or a chunk, and 2 Hebrew frame clips (one long enough to judge the Hebrew accent). Purpose: drop the voices that fail a *fatal* check (section 7) and learn which text form works for the sounds.

**Round 2 (full, finalists), the finalists only (default 2 a language, regenerated with the generator).** The whole lists of the three briefs: every sound of the pilot, the CV and robot-talk clips, all minimal pairs, the six stress words and four chunks, the Hebrew frame set, the stability-1.0 variant (English), and 8 Turbo comparison clips.

| File | Voices | Clips | What it holds |
|---|---|---|---|
| `docs/languages/english/pilot.json` | 4 candidates + nitzi | 140 | 28 clips a voice |
| `docs/languages/russian/pilot.json` | 4 candidates + nitzi | 160 | 32 clips a voice |
| `docs/languages/hebrew/pilot.json` | 3 known voices | 63 | 21 clips a voice; IPA clips are in `pilot-ipa.json` (6 clips) |
| `…/pilot-round2.json` (each language) | 2 finalists (placeholders: the first two) | 150 / 142 / 106 (+6 IPA) | full set |

**Round 2 files are written for placeholder finalists.** After round 1 the director regenerates them for the real finalists: `python docs/languages/make_pilot_specs.py round2 --en lang-en-sarah,lang-en-matilda --ru lang-ru-marina,lang-ru-maxim --he nitzi,hero-son`. The generator (`docs/languages/make_pilot_specs.py`) makes no network call.

What each language tests that the others do not:
- **English:** the traps of brief §4.3 (w/v, th, ship/sheep, man/men, hat/hot/hut, sing/sin, weak vowels in banana and elephant), the 12 sounds of brief §7, robot talk c-a-t, the decision-2 fallback (`sssun`, `t... tent`) next to the isolated form.
- **Russian:** the rows of `pronunciation.csv` (sounds, stretched `с-с-сом`, syllables, minimal pairs, words with stress and reduction, sentences, calling, as-written), plus the question the brief left open: **does the voice honour U+0301?** (three words with no mark, one with IPA).
- **Hebrew:** מ שׁ ס ל פ alone (pointed as the Ministry writes them, and the letter repeated), 5 vowels with מ, stop-plus-vowel units, dagesh pairs (round 2), the pairs שָׁר/שָׂר, כֶּלֶב/חֶלֶב, גַּן/גַּם, סֵפֶר/סָפַר, shva and stress words, unit-by-unit words (`פִּי… צָה… פִּיצָה`), letter names (round 2). The brief's four open questions (pointed or not, lone letter as syllable or name, stress control, how to cut a held consonant) are answered by these clips.

All Hebrew in the clips is **draft wording for listening** (marked `needs-editor`); nothing in a pilot is shipped text. The Hebrew pairs and words are my choice from the Hebrew brief and must be confirmed by the hebrew-language-teacher and the hebrew-text-editor before round 2 (open item 3).

---

## 6. Fallback for decision 2 (when a clean isolated sound is not possible)

A sound passes only if the listener marks it `heard-ok` for the **same form** in the finalist voice. Per sound, in this order, the first form that passes is used and recorded in the `say` column of that language's pronunciation CSV:

1. **The sound in IPA or repeated letters** (`/s/`, `ссс`, `מממממ`): the plan's first choice.
2. **The key word with the sound stretched or doubled** (`sssun.`, `mmmap.`, `t... tent.`; Russian `с-с-сом`; Hebrew only for stretchable sounds). Both are in round 1 for six sounds and in round 2 for all twelve (English). The app plays the whole stretched word; no cutting.
3. **A stretched word cut to its sound** with `ffmpeg` (keep the first 0.6 to 0.8 s of a stretched clip, a 10 ms fade). Cheap, but the cut may carry the next vowel's colour: the listener must pass the *cut* clip, not the source.
4. **The unit or the word only.** The app shows the sound through the word or the syllable and plays no lone sound (Russian brief §3; Hebrew brief §5: stretchable sounds only inside words). Stops are always done this way: **no stop is ever voiced alone** in Hebrew; in English and Russian a stop is a short burst only if it passes, else a syllable or the word-twice form (`t… tent`).
5. **A recorded native-speaking adult**, about 120 short clips a language, no cloning, no imitation of anyone. This is a **separate paid decision for the owner** (decision 2) and I make no plan for it until round 2 shows that levels 1 to 4 fail for a whole class of sounds. Rough cost drivers for that later decision: a studio session or a freelance narrator per language, the owner's choice, plus editing; I do not quote it.

The pilot is built so this decision is a **table**, not a feeling: one row per sound, columns for the four forms, `heard-ok` or `heard-wrong`.

---

## 7. The listening-check workflow with the teachers

Nobody in the agent team can hear audio, so the check is a human ear guided by the teacher's written expectation. This is the same rule as `pronunciation-spec` §4 and the three briefs.

**Who does what**
1. **The language teacher** (english-, russian-, hebrew-language-teacher) owns the `check` column of the pronunciation table: what a correct clip sounds like and the trap it must avoid. The pilot's `tests` notes are copied from those columns. The teacher does not guess a clip is right.
2. **The listener** is the owner, or a native-level person he chooses: for English and Russian, someone who speaks the language natively; for Hebrew, the owner. The listener marks each clip `heard-ok` or `heard-wrong` with a reason in a few words. A clip that is not heard stays `unheard`; a lesson is not ready while one is `unheard` or `heard-wrong`.
3. **The hebrew-text-editor** checks the Hebrew frame clips of every pilot (words, stress, nikud, gender-neutral wording) on the transcript, and confirms the draft Hebrew test lines before round 2.
4. **The voice director** (me) prepares the listening sheet (`docs/languages/<language>/listening-sheet.md`, written after the owner gives the go-ahead for round 1, in the style of `docs/audio/audition/listening-sheet.md`), measures the files, and writes the report. I do not claim to have heard anything.

**Order of listening (about 10 to 15 minutes a voice in round 1)**
1. Start with the Hebrew frame clip (step 5): a voice that is not natural in Hebrew drops out of option A at once but may stay for option B.
2. Then step 1 to 4 in id order. The ids are sorted so that one voice's clips are together; listen to one voice at a time, then repeat the same clip across voices for comparison (minimal pairs especially).
3. Mark fatal failures first (below); stop listening to a voice after two fatal failures in the same step.

**Fatal failures (the voice is out for that language)**
- English: w said as v (wet/vet); th said as t or s; ship = sheep; man = men; a uvular r; a vowel added to an isolated stop (`tuh`).
- Russian: uvular р; ы said as и; unstressed о said as full о (молоко́ with three o); no hard/soft difference (лук/люк); the wrong stress on 3 of the 6 round-1 words.
- Hebrew: a pharyngeal ח or ע; a lone consonant read as its letter name; a lone stop with a vowel added that the brief forbids; stress on the wrong syllable in two of the three round-1 words; a cut or breath at the start of a CV unit.
- All: a different gender or age of voice than the label; a clipped start (stops are easily cut); a click at the start or end; a clip that says something else.

**Measured, when `ffmpeg` is available** (it was **not** on the PC used for this plan [M], so none of this is measured yet):
- Loudness per clip: `ffmpeg -i clip.mp3 -af ebur128=peak=true -f null -` (integrated LUFS and true peak). Target for speech clips about -16 LUFS and true peak at most -1 dBTP; the finalists' speech clips within 1.5 LU of each other. For clips shorter than 1 s (lone sounds) integrated LUFS is unreliable, so compare their peak and RMS (`astats`) instead.
- Length: `ffprobe -v error -show_entries format=duration -of csv=p=0 clip.mp3`. Held sounds should be about 0.6 to 0.8 s (English brief §5.1); a held consonant under 0.3 s or over 1.5 s is a miss.
- Leading and trailing silence: more than 150 ms of leading silence breaks the 250 ms join of the split-clip rule; the app trims or the director asks for a trim step.
- Pace of the Hebrew frame: words per minute from duration and word count; the matched pair (option B) must differ by less than about 15 percent.

**Decision flow**
- Round 1 listening → each language keeps its best 2 voices and, if the owner wants, 1 reserve.
- Round 2 (finalists, full set) → the teacher writes `heard-ok` / `heard-wrong` into the pronunciation CSV, the sound table of section 6 is filled, the director proposes A or B with the evidence, and the owner chooses (numbered decision in the report).
- Only then: the voice ids go into `content/voices.json` as the language's teaching voice(s), and the real voicing plan for the first content batch is written (with its own count and cost).

---

## 8. Counts and cost (free, nothing sent)

Counting rule: characters are Unicode code points, every nikud point counts (`voice_gen` counts `text.runes.length`). Rate: the list prices the docs use, **0.08 USD per 1,000 characters for `eleven_v4` and 0.04 for `eleven_v4_turbo`** (`docs/audio/voice-direction.md` §8; `content/voices.json › listPricePer1000Chars`). The owner's own plan may charge differently; the tool takes `--price`. The Creator plan includes 275,000 characters a month, so every figure here is far inside one month [R, from voice-direction §8].

**Hebrew was counted with the real tool [M]** (`audition-batch plan`, on a scratch copy of `voices.json` with a placeholder id, `--repo` pointing at it, nothing written to the repo): 63 clips, **417 characters**, 0.0334 USD; the 6 IPA clips: 24 characters, 0.0019 USD. **English and Russian were counted by the generator** (the same rule: code points of the exact text) because today's tool refuses their texts (hand-off H1); once H1 is merged, the same `plan` command must print the same numbers, and the owner types what the tool prints.

| Round | Language | Clips | Characters | Cost at list (USD) |
|---|---|---|---|---|
| 1 | English (4 voices + control) | 140 | 1,165 | 0.0932 |
| 1 | Russian (4 voices + control) | 160 | 1,015 | 0.0812 |
| 1 | Hebrew (3 voices), pilot.json + pilot-ipa.json | 69 | 441 (417 + 24) | 0.0353 |
| **1** | **Total** | **369** | **2,621** | **0.2097** |
| 2 | English (2 finalists + 8 Turbo clips) | 150 | 1,029 (970 v4 + 59 Turbo) | 0.0800 |
| 2 | Russian (2 finalists + 8 Turbo clips) | 142 | 945 (900 + 45) | 0.0738 |
| 2 | Hebrew (2 finalists + 8 Turbo clips) | 112 | 754 (696 + 58) | 0.0580 |
| **2** | **Total** | **404** | **2,728** | **0.2118** |
| | **Both rounds** | **773** | **5,349** | **0.4215** |

A second pass of round 1 after a text fix, for planning: at most the same again, 0.21 USD. A clip whose text and settings are unchanged is not made, or paid for, twice (the tool's hash). **Worst case for everything in this file, with every clip made twice: about 0.85 USD.**

The pilots are tiny because they are tests of *sounds*, not lessons. The cost of the real course (the 190 Hebrew words, hundreds of English and Russian words, stories) is counted later with each language's milestone plan, once the voices are chosen.

---

## 9. What the owner runs (not run by Claude)

The owner runs these himself in PowerShell; the interactive command shows the plan again and asks him to type the total. **None of the paid commands is run by any agent.** Steps 1 and 2 are not a spend. Run from `D:\nitznutz-fixname\app` (or the merged `app` folder).

**Step 1. Voices (free, in the browser).** In the ElevenLabs Library (or My Voices) for each candidate in `voices-candidates.json`: open the voice, check its listed languages (a voice that lists Hebrew or English *and* Russian is more promising), add it to My Voices, copy the voice id. Swap in a Kate, Irina or Rina for a Russian voice that is missing, and a Library search "American, female, calm" for a missing English default voice. Give the ids to the orchestrator: the developer merges them into `content/voices.json`. **Step 2** is the developer's hand-off H1 (section 10) merged.

**Step 3. Free plan for each file** (prints every clip and the total; sends nothing):

```powershell
cd D:\nitznutz-fixname\app
dart run tool/voice_gen.dart audition-batch plan ..\docs\languages\hebrew\pilot.json --price 0.08
dart run tool/voice_gen.dart audition-batch plan ..\docs\languages\english\pilot.json --price 0.08
dart run tool/voice_gen.dart audition-batch plan ..\docs\languages\russian\pilot.json --price 0.08
```

**Step 4. Round 1 (paid; he types the total each time).** Hebrew can run first and today (it needs no tool change except for its 6 IPA clips). Expected totals from this plan: Hebrew 417, English 1,165, Russian 1,015 (Hebrew IPA file 24). If the tool prints another number, he types **what the tool prints**, after reading it.

```powershell
dart run tool/voice_gen.dart audition-batch run ..\docs\languages\hebrew\pilot.json --out $HOME\auditions\lang-he-r1
dart run tool/voice_gen.dart audition-batch run ..\docs\languages\hebrew\pilot-ipa.json --out $HOME\auditions\lang-he-r1
dart run tool/voice_gen.dart audition-batch run ..\docs\languages\english\pilot.json --out $HOME\auditions\lang-en-r1
dart run tool/voice_gen.dart audition-batch run ..\docs\languages\russian\pilot.json --out $HOME\auditions\lang-ru-r1
```

Give `--out` for each: without it the folder is named after the file (`pilot`), and the three languages would share one folder. Cost of step 4: **0.21 USD** at list prices (2,621 characters).

**Step 5. Listening** (section 7), then the director regenerates the round 2 files for the finalists and the owner repeats steps 3 and 4 with `pilot-round2.json` (and `pilot-round2-ipa.json` for Hebrew), `--out ...-r2`. Cost: **about 0.21 USD** (2,728 characters). **Total of both rounds: about 0.42 USD** (5,349 characters).

---

## 10. Hand-offs and open decisions

**H1 (app-developer, through the orchestrator; blocks English, Russian and the Hebrew IPA clips).** `app/tool/audition_lib.dart` and `voice_text_lib.dart` today send every clip with `language_code: "he"` and refuse any non-Hebrew letter [M: running `plan` on the English file prints `unknown keys language`; the character rule is in `_refusal`]. Needed, with a test of each:
1. A clip (and `defaults`) key **`language`**: `he` (default), `en` or `ru`, passed to `ClipRequest.languageCode` (it is already part of the hash).
2. The pre-flight check by language: `en` allows Latin letters, space and `. , ? ' - …`; `ru` allows Cyrillic (U+0410 to U+044F and Ёё), U+0301, and the same punctuation; `he` as today. Digits, placeholders, markup and `!` stay refused. A Latin or Cyrillic letter in a `he` clip, and the reverse, is still refused (the split-clip rule is enforced by the tool).
3. `Allowance.ipa`: a clip that is only an IPA word `/…/` must be accepted (today `speakable` needs a Hebrew letter), and U+02B2 (ʲ) and U+0361 (tie bar) join the IPA letters for Russian.
4. The `plan` output shows the language of each clip. The default output folder includes the file's folder name (or `--out` is required), so three `pilot.json` do not share one folder.
5. Candidate characters (`docs/languages/voices-candidates.json`) merged into `content/voices.json`; underscore notes in that file are dropped.
Nothing else in the app changes. Later (not now): `voice_gen generate` and the packs need the same `language` support when the first real content is voiced.

**Waiting for others**
- **hebrew-text-editor:** confirm the draft Hebrew test lines (`he-listen`, `he-your-turn`, `he-long`, `he-nice`) and the Hebrew minimal pairs and words; nothing in the pilot is shipped text. No punctuation request yet.
- **hebrew-language-teacher:** confirm the pairs שָׁר/שָׂר, כֶּלֶב/חֶלֶב, גַּן/גַּם, סֵפֶר/סָפַר and the stress words are right for the course; the letter-name forms for round 2 (the open question in its brief).
- **english-language-teacher, russian-language-teacher:** read the pilot clips against their briefs (the generator took the English lists from brief §7 and §6, and the Russian ones from `pronunciation.csv`); name a native listener for each language through the owner.
- **design-director:** nothing for this plan.

**Decisions for the owner (numbered, with what he will hear)**
1. **Go for round 1 at 0.21 USD** (Hebrew 417, English 1,165, Russian 1,015 characters, plus 24 for Hebrew IPA), after H1 and the ids. You will hear about 370 very short clips, most under 2 seconds.
2. **Who listens** to the English and the Russian clips: a native-level person you trust (a friend or relative), because no agent can hear. The Hebrew you judge yourself.
3. **Whether to add a Hebrew library voice** as a fourth Hebrew candidate (a voice found with the Hebrew language filter). The pilot works without it.
4. **After round 2:** option A (one voice for Hebrew and the language) or B (two matched voices) per language, from the evidence.
5. **Later, only if the pilot fails:** the recorded-adult fallback (decision 2).

**Sources.** The pilot's facts about the model list and languages are from ElevenLabs' own docs, the voice names from third-party listings. Accents and Hebrew ability of every named voice are **not verified**; the pilot is how they are verified.

- ElevenLabs, Models overview (v4, v4 Turbo and v3 list Hebrew, English and Russian; Multilingual v2 and Flash v2.5 do not list Hebrew; `language_code`; no break tags on v4/v3; IPA in slashes on v4): https://elevenlabs.io/docs/overview/models and https://elevenlabs.io/docs/best-practices/prompting/controls
- ElevenLabs, Hebrew text to speech page (Hebrew among 90+ languages; no named Hebrew voices): https://elevenlabs.io/text-to-speech/hebrew
- JSON2Video listing of ElevenLabs voices tagged Russian (Marina, Ekaterina, Maxim, Ivan Nazarov, Kate, Irina, Rina, Felix; third-party): https://json2video.com/ai-voices/languages/russian/
- JSON2Video Hebrew (Israel) listing: Azure voices only, no ElevenLabs voice: https://json2video.com/ai-voices/languages/hebrew/israel/
- WaveSpeed, list of ElevenLabs default voice ids (Sarah, Jessica, Matilda, Brian; third-party, ids unverified against the owner's account): https://wavespeed.ai/docs/docs-api/elevenlabs/elevenlabs-voice-id
- ElevenLabs, Default voices (descriptions of Jessica, Sarah, Matilda, Alice; the page itself returned 403 to a fetch, so the descriptions came from search snippets): https://elevenlabs.io/docs/voices/default-voices
- This repo: `docs/audio/voice-direction.md` §8 (list prices, Creator plan), `docs/audio/voice-quality-diagnosis.md` (v4 facts, P7 accent), `app/tool/audition_lib.dart`, `app/tool/voice_text_lib.dart`.
