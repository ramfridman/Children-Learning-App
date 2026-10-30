# Voice quality diagnosis: wrong pronunciation and a robotic delivery

Written on 2026-10-29 by the voice-and-sound-director, after the owner said that in the lessons on his phone "some of
the pronouncing of the words is not correct and sounds very robotic". **This is a diagnosis. Nothing was generated or
sent, and nothing was paid for.** The owner has not given example words yet, so none are guessed here. The
hebrew-text-editor is working on the text side in parallel (`docs/agents/voice-pronunciation-audit.md`). Section 4 lists
what I need from that work.

How sure each statement is: **[M]** measured here (files, headers, counts), **[R]** read in the repo or in a cited
source, **[G]** my judgement. I cannot hear audio, so every statement about how something sounds is [G] until the owner
listens.

**Update, later on 2026-10-29.** The voice tool was rebuilt and reviewed by QA and security. In `voice_gen` (packs and
auditions) it now does the following [R, from the header of `app/tool/voice_gen.dart`]:
- it reads `voice_text`, never the caption;
- it sends explicit settings, with no style or speed to v4;
- it makes 44.1 kHz only;
- it records a hash per clip;
- it checks every text against a pre-flight allowlist.

So H3, H4 and H5 are done for `voice_gen`, and so is H1 for the packs. The gateway still asks for `mp3_22050_32`.

The paid commands (`generate`, `audition-batch run`, `audition`) run only in an interactive terminal: they print the
plan and the owner types the count. `--confirm-chars` is gone. An audition clip has at most 300 characters.

The two rounds below are written as specs:
- `docs/audio/audition/round1.json`: 34 clips, 1,852 characters, 0.1178 USD;
- `docs/audio/audition/round2.json`: 59 clips with the editor's H1, 2,774 characters, 0.2219 USD on v4.

The owner's steps and score sheet are in `docs/audio/audition/listening-sheet.md`. Section 3 is corrected to match
them, and so are my 2026-10-28 notes in `voice-direction.md` (its "Corrections of 2026-10-29").

---

## 1. What is sent to ElevenLabs today

| Path | Code | Text sent | Model | Voice settings | Output format |
|---|---|---|---|---|---|
| Lesson and core lines (`voice_gen generate`) | `app/tool/voice_gen_lib.dart` (`linesOfContent`, `coreLines`, `ElevenLabsSynthesizer`) | the **first screen caption** (`caption[0].v`) of each `vo:` id, or `core.he.json › text`: **fully pointed, in defective spelling (ktiv haser)**, with `!`, `—` and `…`; no digits, no SSML, no `{child}`; `respelled()` does nothing because `pronunciation` is `{}` | `eleven_v4_turbo` (`content/voices.json`) | **none**. `settings` is `{}`, so the voice's stored settings in the owner's ElevenLabs account are used (not known here) | `outputFormat` `mp3_44100_64` from M8 on. The code's default is `mp3_22050_32` |
| Celebrations and ceremony (`vo:core.celebrate.`, `vo:celebrate.`, `vo:core.ceremony.`) | `styleOf` → `cheer` | as above | same | stability **0.1**, similarity 0.8, style **0.9**, speaker boost | as above |
| Tutor lines, prewarmed and live (66 reviewed hero-son lines) | `supabase/functions/_shared/tutor_core.ts:420`, `elevenlabs.ts` | `verdict.vocalised`: the approved plain line, **pointed word by word** by the tutor lexicon (`he-child.v1.json`: "Written with niqqud by Claude; every entry awaits an editor") and a prefix table that its own comment calls "a simple table, not Hebrew grammar" (`hebrew.ts:27`) | `config.elevenlabs_model_id` (`eleven_v4_turbo`, M6.md) | **none** (only `text`, `model_id`, `language_code: "he"`) | **hard-coded `mp3_22050_32`** |

All paths send `language_code: "he"`. Neither path uses `seed`, `previous_text`/`next_text`, a pronunciation dictionary,
IPA or audio tags.

**What exists on the PC [M]** (`C:\Users\ramfr\nitznutz-voice\<id>`, read from the MP3 frame headers):

- Nitzi and hero-son have 318 clips each. 270 of them are 44.1 kHz / 64 kbps. **48 are 22.05 kHz / 32 kbps**: all 26 core
  lines (greeting, encouragement, thinking, listening, goodbye) and the butterflies, give-four and red-flower lessons.
- Each of the seven friends has 54 clips: **48 at 22.05 kHz / 32 kbps** and 6 at 44.1 kHz / 64 kbps (the ceremony lines
  and the celebration).
- Every tutor clip is 22.05 kHz / 32 kbps (that format is fixed in the code).
- Speech rate: the median is 1.63 words/s for Nitzi and 1.75 for hero-son. Celebration clips in the `cheer` style have
  the same median (1.62 and 1.75). No clip is fast.

**What is in those texts [M]** (the 318 narrator clips, from the current captions; nothing in them changed after voicing):

- **123 of the 318** contain a word in defective spelling whose bare letters spell a different word. The most common:
  - `נִסְפֹּר` (44 times; without points it reads נספר, "nesaper/nispar")
  - `לִלְחֹץ` (47; reads ללחץ)
  - `לִסְפֹּר` (13; reads לספר, "lesaper", "to tell")
  - `נִבְדֹּק` (4; reads נבדק, "nivdak")
  - `הָאָדֹם` (3; reads האדם, "ha-adam", "the person")
  - `נַחְשֹׁב` (2; reads נחשב)

  18 of the 123 are core, feedback or hint lines, which are the most often repeated.
- **31** use the rare QAMATS QATAN sign (U+05C7) in `כׇּל`, `בְּכׇל` and `לְכׇל` (32 marks in all).
- **43** have pointing that the editor has since corrected in `hebrew-master.csv` (for example `מְצָאתֶם`, `נְתַתֶּם`,
  `מַה`, a missing or extra dagesh).
- 101 contain `!` and 54 contain `—`.
- `שווה` and `כפול` are in none of the voiced lines. `שווה` is in 72 of the new `voice_text` lines, and `כפול` is in
  none yet.

**The model [R].** ElevenLabs lists Hebrew for `eleven_v4`, `eleven_v4_turbo`, `eleven_v3` and
`eleven_v3_conversational`, but **not** for `eleven_multilingual_v2` or `eleven_flash_v2_5`. ElevenLabs describes
`eleven_v4` as "our highest-quality model, ideal for content creation, audiobooks, character voiceovers", and
`eleven_v4_turbo` as "purpose-built for real-time use cases like conversational agents". It also says v4 "is the
better choice for most users". Every pack line is pre-rendered, so Turbo's latency gives us nothing.

**The settings [R].** In v4, "Both variants use two voice settings: Stability and Similarity. Style and Speed sliders
are not available in Eleven v4, and SSML is not supported." So in practice the `cheer` style is "stability 0.1". The
API accepted `style 0.9`, since the celebration clips exist [M], but the docs say v4 does not use it. Lower stability
means "more expressive delivery" with less consistency. For v3, ElevenLabs warns that the lowest setting is "prone to
hallucinations".

**Line length [R+M].** Our lines are short, about 10 to 120 characters, and most clips are 2 to 4 s. ElevenLabs' v3
prompting guide says: "Very short prompts are more likely to cause inconsistent outputs... experiment with prompts
greater than 250 characters." A question is also often split into separate clips (`prompt`, then `how_many`) that the
app joins with a 250 ms gap, so the intonation starts again on every clip.

---

## 2. Likely causes, ranked, and how to confirm each cheaply

### (a) Wrong pronunciation

| # | Cause | Evidence | Cheap check |
|---|---|---|---|
| P1 | **Defective spelling with full nikud.** If the model leans on the letters more than on the points (modern Hebrew text "rarely contains diacritics", Roth et al. 2024), it says the other word: "nesaper" for נִסְפֹּר, "ha-adam" for הָאָדֹם, "nivdak", "lesaper" | [M] 123 of 318 clips; [R] paper; [G] the mechanism | Owner, free, today: play `vo.pick.red.flower.prompt.mp3`, `vo.count.butterflies.3.prompt.mp3` and `vo.core.encourage.check.mp3` from `C:\Users\ramfr\nitznutz-voice\nitzi\` and listen for "ha-adam", "nesaper", "nivdak". Audition pairs L1, L2, L5 |
| P2 | **Points read literally where speech differs.** `כָּל` with a plain qamats (tutor lexicon) can come out "kal". The rare `כׇּל` (U+05C7) is barely seen in training text [G] | [M] 32 clips; [R] tutor lexicon | L4p against L4x; L7p against L7v |
| P3 | **Pointing errors in the old captions**, said exactly as written | [M] 43 clips have corrections waiting in the master table | The editor lists those 43; the owner listens to 5 of them |
| P4 | **Stress is not written** in nikud. The model guesses: `שווה` (sha-VE), `שְׁתַּיִם`, `עֶשֶׂר`, loan words (`ברונזה`, `מדליה`), the children's names | [R] Phonikud (2025/2026): existing systems ignore "underspecified phonetic features such as stress" | L6 in three forms: plain, `שָׁוֶה`, IPA `/ʃaˈve/` (v4 only) |
| P5 | **Tutor pointing is unreviewed and partly mechanical.** My Python approximation of the gateway's lookup on the 66 lines gives `בְּכָּל`, `לְפַּרְפָּר` and `לְפֶּרַח`: a dagesh kept after a shva prefix, and qamats `כָּל` | [R] code; [M] approximation only (I did not run the real Deno validator) | L7 (hero-son): the vocalised form against the plain approved text |
| P6 | **Ambiguous unpointed words in the new `voice_text`**: `מספר`, `חום`, `ספר` and the 23 entries proposed in `voice-direction.md` | [R] | Set B of the earlier audition (`audition.csv`) |
| P7 | **The voice itself.** A library voice that is not native Hebrew carries its own accent. ElevenLabs: "Some languages are processed more fluently than others" | [R]; [G] the four voice ids are not identified here | The owner tells me the voice names and languages (free, in his account); Set A of the earlier audition |
| P8 | Not pronunciation, but heard as "wrong": **50 new math lines mix number genders** (`תִּשְׁעָה פחות חֲמִשָּׁה שווה אַרְבַּע`). None of them is voiced yet | [M] scan of `voice_text` | Editor and curriculum-expert decide (section 4) |

### (b) Robotic delivery

| # | Cause | Evidence | Cheap check |
|---|---|---|---|
| R1 | **Low-bitrate audio.** The core lines, the first lessons and every tutor clip are 22.05 kHz / 32 kbps MP3. That format dulls ש/ס/צ and gives a metallic, "underwater" sound [G: a common codec artefact; no source cited] | [M] 48 of 54 clips per character, plus all tutor audio | Owner, free: on headphones, play `vo.core.greeting.hello.mp3` (32 kbps) and then `vo.next.after.1.prompt.mp3` (64 kbps). Audition: L4p and L5p remade at 44.1 kHz against the old clips of the same text |
| R2 | **The Turbo model** is built for real time. `eleven_v4` is built for produced content | [R] ElevenLabs docs | Round 1 model pairs |
| R3 | **Very short, isolated clips.** Every clip starts from a neutral intonation; one question is split into two clips | [R] the v3 guide's 250-character advice; [M] clip lengths | L8 (prompt and question in one clip) and L10 (a whole activity in one request) |
| R4 | **Settings.** Lesson lines use unknown stored settings. A high stored stability tends to be flat [G], and the cheer's 0.1 is the most erratic. Style 0.9 and our planned speeds are ignored on v4 | [R] | Owner: read the voices' stored settings in his account (free). Round 2: stability 0.1, 0.5 and 0.8 |
| R5 | **Full pointing pushes a read-aloud cadence.** Pointed text is mostly children's books, poetry and liturgy, so the model may read syllable by syllable [G] | [M] all voiced texts are fully pointed | Round 1: pointed against plene on the same model and voice |
| R6 | **Punctuation.** Today: 101 `!` and 54 `—`. The new `voice_text` turns almost every `!` into `.`, which risks the opposite (a flat "כל הכבוד.") | [M] | L4p, L4v (`.`) and L4x (`!`) |
| R7 | **No emotion direction.** v4 accepts audio tags (`[warm]`, `[gently]`); we use none | [R] v4 page: tags "not yet perfect" | Round 2: two tagged clips |
| R8 | Speed is unlikely to be the cause: about 100 words a minute is already slow | [M] | none needed |

**My ranking [G]:**
- Pronunciation: P1 > P3 > P2 > P4 > P5 > P7.
- Robotic: R1 > R3 > R2 > R5 > R4 > R6.

Round 1 below is built to split these causes.

---

## 3. A plan to fix it without wasting money

**Order (the owner's decision):**
1. The texts are final first: the editor's plene `voice_text`, with points only where the audition shows they are needed.
2. One diagnostic audition, in two short rounds.
3. The choices go into `content/voices.json` and the code changes in section 4 are made.
4. A pilot on the phone.
5. Every line is voiced once.
6. The old lines, all 318 per narrator and 54 per friend, are voiced again. No old clip is kept: they are all affected
   by P1 to P3 and most by R1.

**Diagnostic audition, round 1.** The voice is the narrator the owner names as worst, or Nitzi if he does not say.
L7 uses hero-son. Every clip gets explicit settings (stability 0.5, similarity 0.75, speaker boost), so nothing depends
on the stored settings. The format is `mp3_44100_64` unless a row says otherwise.

| Clip | Text (exact) | Turbo | v4 | Tests |
|---|---|---|---|---|
| L1p / L1v | `אֵיפֹה הַפֶּרַח הָאָדֹם?` / `איפה הפרח האדום?` | both | both | P1 |
| L2p / L2v | the `count.butterflies.3` prompt: today's pointed caption / its `voice_text` | both | both; L2v also at `mp3_44100_128` | P1, P2, R5, R1 |
| L3p / L3v | the `count.butterflies.3` hint 3: today's caption / `voice_text` | both | L3v | R5, list pacing |
| L4p / L4v / L4x | `כׇּל הַכָּבוֹד!` / `כל הכבוד.` / `כל הכבוד!` | all three | L4x | P2, R6 |
| L5p / L5v | `הַמְּמ… בּוֹאוּ נִבְדֹּק.` / `המממ… בואו נבדוק.` | both | L5v | P1, the hum |
| L6v / L6s / L6i | `שֶׁבַע. שָׁלוֹשׁ ועוד אַרְבַּע שווה שֶׁבַע.` with `שווה` / `שָׁוֶה` / `/ʃaˈve/` | L6v, L6s, L6i | all three | P4; does Turbo read IPA? |
| L7v (L7p waits) | the approved plain line `בואו נספור לאט, נוגעים בכל פרפר פעם אחת.` in hero-son's voice. L7p, the gateway's exact `vocalised` string, is not in the spec: I have only my approximation, and a guess must not be auditioned as the real thing (hand-off H9) | L7v | L7v | P5, and R2 for the male voice |
| L8v | prompt and question in one clip: `פרפרים באו לגינה. בואו נספור אותם. נוגעים בכל פרפר פעם אַחַת. כמה פרפרים יש על הפרח?` | yes | yes | R3 |
| L10a / L10b | the 10 `voice_text` lines of `activity.count.butterflies.3`, one per line, in **two** requests. All ten make 433 characters with the line breaks, over the tool's 300-character limit for a clip. L10a has the prompt, the answer prompt and hints 1 to 3 (262 characters, over the 250 of the v3 advice). L10b has the three "not yet" lines, the "good question" line and the correct line (170 characters) | | both | R3 |

**What changed when round 1 was written as a spec** (`docs/audio/audition/round1.json`, 34 clips):
- L6 uses `activity.b.mathb03.1`, whose numbers all agree. The `mathb01.1` sentence above mixed genders (P8), which
  would blur the stress test.
- L4v and the second hum `ממממ…` (L5m, the editor's A/B) were added on both models.
- L10 was split, as above.
- L7p is left out, as above.

Round 1 comes to **1,852 characters**: Turbo 759, v4 1,093. At list prices (Turbo 0.04 USD and v4 0.08 USD per 1,000
characters) that is **0.1178 USD**.

**Round 2** (`round2.json`, 59 clips) runs after the owner has scored round 1, on the model that won. The spec says
`eleven_v4`, and I change it before the run if Turbo wins. It has:
- stability 0.1, 0.5 and 0.8 on `כל הכבוד!`, on the bronze cup (the editor's `voice_text`, with a full stop) and on
  L2v (9 clips);
- the editor's cheer A/B on the gold, silver and medal lines at 0.1 and 0.5 (6 clips);
- the medal line in the voices of Tzuri and of Tamir and Keshet, at 0.1 and 0.5, because these two voice ids have
  never been heard in an audition (P7; 4 clips);
- `[gently]` and `[warmly]` on the "not yet" and "good question" lines, each with an untagged twin (4 clips);
- the editor's **H1**: six lines × three text forms × Nitzi and hero-son (36 clips, 2,168 characters).
  - Form a is the caption as sent; form b is the `voice_text`.
  - Form c changes one thing that only the ear can settle: a `…` after "oops", one `!` after "kol ha-kavod", no
    points at all on the stars hint and on the medal line, the list counted with `…`, and the plain question with
    `האם` kept.

Round 2 comes to **2,774 characters, 0.2219 USD** on v4 (0.1110 USD on Turbo).

**Both rounds together: 4,626 characters, at most 0.34 USD.** These are my counts in Unicode code points.
Pointed text counts every point, so L2p is 96 characters and L2v is 61. The number the owner types is the one the
gated tool prints, never mine. Then the earlier voice-choice audition (set A of `audition.csv`) runs on the winning
model and text form; its cost doubles if v4 wins.

**What the owner listens for, per clip, on the phone speaker and on headphones** (marked ok / not ok, with one word
on what he heard):
1. Each word is the right word ("ha-adom", not "ha-adam"; "nispor", not "nesaper"; "kol", not "kal").
2. The stress falls on the right syllable (sha-VE, sh-TA-yim).
3. It sounds human, not robotic: no metallic or "underwater" sound, no syllable-by-syllable reading.
4. The rise and fall of the voice fits the kind of line: a soft rise on a question, glad on a cheer, kind on a "not yet".
5. The number words have the right gender.
6. Across retakes: is the same line equally good (stability)?

After each round I measure, without listening: the length of each clip against its pair, and loudness and true peak
once ffmpeg is installed. I note whether Turbo and v4 differ in length and pauses.

**How round 1 decides things:**
- If the plene forms win on both models, P1 and R5 are confirmed, and plene `voice_text` (the editor's direction) is
  the fix.
- If v4 wins over Turbo on the same text, the packs move to `eleven_v4`. The full two-narrator run then costs about
  12.40 USD instead of 6.20 USD.
- If L8 or L10 wins over single clips, the generator learns to voice a whole activity in one request and cut it apart
  by the timestamps it already receives (H6).
- If the 32 kbps clips sound worse than their remakes, R1 is confirmed. It is fixed anyway by H1.

**Direction the text editor must supply for each line (in `voice_text` and the review table):**
1. Plene spelling, with no full pointing ever.
2. Points only on a word that is ambiguous, or that the audition shows the voice gets wrong.
3. A `stress` note for each risky word (for example `שווה: sha-VE`).
4. The number gender, checked.
5. Punctuation by my rules: one `!` allowed in celebrations and greetings; `.` for a statement; `…` for a thinking
   pause; `—` only for a held beat.
6. The kind of line (for the style).
7. A whole-word respelling or IPA entry for every word the audition flags.

---

## 4. Hand-offs and what the owner must supply

**To the app-developer** (later, from this spec; changes to the gateway also go to security review):
- **H1.** Change the default output format in `ElevenLabsSynthesizer` and the hard-coded `mp3_22050_32` in
  `elevenlabs.ts` to `content/voices.json › outputFormat`, or to the format chosen in round 1. Done when no new clip
  is 22.05 kHz.
- **H2.** Use a model per purpose: packs and prewarmed or reviewed tutor lines on the model the audition chose
  (likely `eleven_v4`); live, freshly made tutor lines stay on `eleven_v4_turbo` (the 3-second budget). In practice
  this splits `elevenlabs_model_id` into a prewarm model and a live model.
- **H3.** Send explicit `voice_settings` on every request, from `voices.json`: a default, plus a style chosen by the
  line's kind. Do not send `style` or `speed` to v4. The gateway sends them too.
- **H4.** C7 from `voice-direction.md`: store a hash of the sent text, model and settings for each clip, so that a
  changed line is voiced again. Today `_made` reuses any file with the same id.
- **H5. Done (2026-10-29).** It was: a gated `audition-batch` command. It is now `audition-batch plan|run <spec.json>`
  (format `audition/v1`, in `app/tool/audition_lib.dart`). `run`, like `generate` and the one-text `audition`, runs
  only in an interactive terminal and asks the owner to type the count. `--confirm-chars` was removed.
- **H9.** To make L7p possible: print, without sending anything, the exact `vocalised` string that the gateway's
  validator gives for the reviewed hero-son line `בואו נספור לאט, נוגעים בכל פרפר פעם אחת.`. A Deno test run or the
  prewarm cache would do. I add L7p to round 2 with that string.
- **H10.** For the voice-choice audition (set A): a way to audition a library voice id that is not yet in
  `content/voices.json`. For example, an optional `"voice"` key on a clip, checked like a voice id (C11 of
  `voice-direction.md`).
- **H6.** Optional, if L8 or L10 wins: voice a whole activity or several lines in one request and split it by the
  alignment. `previous_text`/`next_text` are another option, but whether v4 accepts them is unverified.
- **H7.** The mouth cues (C6) must handle unpointed text and an IPA `/…/` word (treat it as one open group).
  `respelled()` must match whole words (C5).
- **H8.** Tutor: after L7, send ElevenLabs the plain approved text, or a reviewed per-line respelling. Keep the
  lexicon's pointing only for the Band B/C caption, and only once the editor has reviewed the lexicon.

**Where the two documents agree and differ.** The editor's audit (section 4 of their file) independently finds the
same main cause: no corrected `voice_text` has reached a single clip. Their risk table already names the 43 corrected
lines, the qamats qatan, the hum, `וַאוּ` and the tutor's verb forms and prefixes. We differ on one point. The editor
says `!` is never sent; I want one `!` allowed on a cheer or a greeting, because a full stop may make it flat. L4v
against L4x decides it.

**To the hebrew-text-editor** (in `docs/agents/voice-pronunciation-audit.md`, not edited by me):
- the 43 voiced lines whose pointing has since been corrected (my method: the current caption matches the master
  `text`, and `ui_text` differs);
- the list of defective-spelling words above, and confirmation that `voice_text` is plene for all of them;
- the punctuation rule for cheers (`!`);
- the `stress` notes;
- the gender question in P8, together with the curriculum-expert.

**To the qa-engineer:** a test that every pack clip and every tutor clip is 44.1 kHz, and that no voiced text is fully
pointed (for example, at most one pointed word in three).

**What the owner must supply:**
1. The example words, and for each the lesson or screen, and the character (Nitzi, hero-son or a friend).
2. Whether "robotic" is everywhere, or mostly in the greeting, encouragement and listening lines, the butterflies
   lessons and the helper. Those are the 32 kbps clips, so this answer is a free test of R1.
3. Phone speaker or headphones.
4. The names of the four voices in his ElevenLabs account (`Tbj9…`, `Ziof…`, `8sZ9…`, `6Ijsl…`), their language or
   accent, and their stored stability and similarity.
5. Install ffmpeg (`winget install Gyan.FFmpeg`).
6. Run the two rounds himself and type each count when the gated tool prints it
   (`docs/audio/audition/listening-sheet.md`, section A). Then fill in the score sheet.

---

## 5. Open questions for the owner (with my recommendation)

1. **Model for the packs:**
   - `eleven_v4`: produced quality, about twice the price (about 12.40 USD for both narrators in full);
   - or `eleven_v4_turbo`: today's, built for live speed.

   *Recommendation:* decide after round 1; I expect v4.
2. **Text form sent to the voice:**
   - plene, unpointed, with a point only where needed (sounds like everyday speech);
   - or today's full pointing.

   *Recommendation:* plene. It is also about 35% cheaper.
3. **The cheer:**
   - stability 0.1 (big, unpredictable swings);
   - or about 0.4 to 0.5 (bright but even).

   *Recommendation:* decide after round 2; I expect 0.4 to 0.5.
4. **Audio quality:**
   - `mp3_44100_64` (packs about half the size);
   - or `mp3_44100_128` (fuller sibilants).

   *Recommendation:* 64 unless he hears a difference on L2v.
5. **Voicing per activity in one request** (one intonation arc, more natural; needs H6) or line by line.
   *Recommendation:* only if L10 is clearly better.
6. **The helper:**
   - it speaks the plain approved line (natural);
   - or the lexicon's pointed form (the pointing is unreviewed).

   *Recommendation:* plain.

**Corrections to my own design of 2026-10-28:**
- The `speed` column in `voice-direction.csv`, the style values (0.05 to 0.45) and the band speed offsets do nothing
  on v4. Pacing comes only from punctuation, sentence structure and, at most, a tag.
- The note that the old clips were "22,050 Hz / 56 kbps" is wrong: they are 32 kbps [M]. The first frame of each file
  is an information frame at 56 kbps; every audio frame after it is 32 kbps, which I re-measured frame by frame on four of the 22.05 kHz files.

Both corrections are now in `voice-direction.md` (section "Corrections of 2026-10-29", and in place), together with the
new paid-command gate. The stabilities there wait for round 2.

## 6. What I could not verify

- I have listened to nothing, and I have not seen the owner's words.
- Which voices the four ids are, and their stored settings.
- Whether ElevenLabs bills nikud marks as characters.
- Whether v4 uses `seed`, `previous_text` and `next_text`; whether Turbo reads IPA; whether stability on v4 is
  continuous or stepped like v3's.
- The exact tutor `vocalised` strings: only my approximation (the real Deno validator was not run).
- Loudness and true peak, because ffmpeg is not installed.
- Third-party prices (0.08 and 0.04 USD per 1,000 characters) against the owner's own plan.

## 7. Sources

- ElevenLabs, Models overview (Hebrew in v4, v4 Turbo and v3; not in Multilingual v2 or Flash v2.5), no date: https://elevenlabs.io/docs/overview/models
- ElevenLabs Help Center, "What is Eleven v4?" (only Stability and Similarity; no Style, Speed or SSML; v4 compared with v4 Turbo), no date: https://elevenlabs.io/docs/help-center/product/core-capabilities/text-to-speech/what-is-eleven-v4
- ElevenLabs docs (German), Eleven v4 ("v4 is the better choice for most users"; "some languages are processed more fluently than others"), no date: https://elevenlabs.io/docs/de/overview/capabilities/text-to-speech/eleven-v4
- ElevenLabs, Eleven v4 product page (v4 for produced content, Turbo for real time; tags), launched late September 2026: https://elevenlabs.io/v4
- ElevenLabs, Best practices: prompting (v4 tags; IPA in `/…/` for `eleven_v4`; phoneme tags only on `eleven_flash_v2`; "very short prompts" advice for v3), no date: https://elevenlabs.io/docs/best-practices/prompting and https://elevenlabs.io/docs/best-practices/prompting/controls
- ElevenLabs API, Create speech (voice settings and their defaults, `seed`, `previous_text`, the dictionary limit of 3, `apply_language_text_normalization` for Japanese only, the output formats): https://elevenlabs.io/docs/api-reference/text-to-speech/convert
- eesel.ai, "Eleven v4 pricing in 2026" (v4 0.08 USD and Turbo 0.04 USD per 1,000 characters; third-party): https://www.eesel.ai/blog/eleven-v4-pricing
- Kolani, Melichov, Calev, Alper, "Phonikud: Overcoming Phonetic Underspecification for Hebrew Text-To-Speech", arXiv 2506.12311 (v1 2025-06-14, v4 2026-07-02): https://arxiv.org/abs/2506.12311
- Roth, Turetzky, Adi, "A Language Modeling Approach to Diacritic-Free Hebrew TTS", arXiv 2407.12206 (2024-07-16): https://arxiv.org/html/2407.12206v1
- D. Rosehill, Hebrew TTS Providers (Multilingual v2 "unintelligible Hebrew", v3 "Good"; snapshot of 2025-03-22): https://github.com/danielrosehill/Hebrew-TTS-Providers
