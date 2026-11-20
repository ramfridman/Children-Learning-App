# M12 sound notes: the sound half of the plan

Written 2026-11-20 by the voice-and-sound-director. Docs only: nothing generated, nothing paid, no ElevenLabs key touched. The owner's words after playing with his 2-year-old: "not child friendly at all... sounds very robotic... no celebrations, nothing that makes the child excited".
Tags: **[M]** measured or read in code and files here, **[R]** read in a cited source, **[G]** my judgement. I cannot hear audio; every "how it sounds" is [G] until the owner listens.

## 1. The audit

### 1a. What makes a sound today (code of `D:\nitznutz-stage1`, commit fb39dc08)
- **The only audio code is the voice player** [M]: `app/lib/voice/voice_player.dart` (one `audioplayers` `AudioPlayer`, plays one pack clip from memory) driven by `voice_director.dart` (`say`, `sayNext`, `sayClips`, 250 ms gap between stitched clips, `companion.dart:138`).
- **No SFX, no music, no ambience, no haptic exists** [M]. Search of `app/lib` for `HapticFeedback`, `SystemSound`, sfx, music, loop: zero hits. No `.wav/.ogg/.mp3` outside voice packs. The design-spec sound palette (`docs/design-spec.md` §11: tok, bloop, 3-note chime, boing, twinkle, music per land, haptics) was never built. M11 item 6 ("a chime, a per-land instrument") was deferred.
- Even the design events `hopLanded`, `celebrateDone`, `pokeDone` have nobody listening for sound.

| Event | Sound today |
|---|---|
| Tap on anything, drag pick-up, drop, snap | **silent** |
| Count tap (1, 2, 3) | silent (a number word is a voice clip only if the lesson voices it) |
| Correct answer | a voice line only (`cheer` style); no chime, no stinger |
| Try again / not yet | a voice line only; silent otherwise |
| Hint | voice line only |
| Lesson end, sticker, medal | voice line (ceremony: "here is a ... for you"); no fanfare |
| Map, room entry, land change | silent; no ambience, no music, no home theme |
| Host greeting | a voice clip, in one of **four** voices (see 1d) |
| Scenery taps, characters poked | silent |
| Haptics | none |

### 1b. Why it sounds robotic: ranked causes [G, evidence [M]/[R]]
1. **The performance, not the pixels.** Every line is a short, isolated, neutral read.
   - Lessons use `stability 0.5, similarity 0.75`, speaker boost (`content/voices.json › settings`), no audio tags, no emotional direction per kind of line. Only celebrations use `cheer` (stability 0.1) [M].
   - `eleven_v4` takes no style or speed; `style 0.9` and every `speed` in `voice-direction.csv` do nothing on v4/Turbo [R: `docs/audio/voice-quality-diagnosis.md` §1, ElevenLabs v4 help page]. So a greeting, a question, a hint and a comfort line share one flat register.
   - Clip-by-clip: each clip starts from neutral intonation, a question can be two clips joined by a 250 ms gap, numbers and single words are voiced alone [M: diagnosis R3].
   - **hero-son is on `eleven_v4_turbo`**, the real-time model [M: voices.json `_modelNote`], and was not loudness-normalised, so it jumps in volume against Nitzi and the course voices [M: owner's note on his 2026-11-15 build].
2. **No human world around the voice.** A voice alone in a silent app is heard as "the computer talking". A real children's app wraps the voice in a touch sound for every touch, a stinger for every success, and music. With none of it the child gets no "I touched, it answered" and no "I did it" (this is the main reason the owner found no celebration) [G, supported by 2].
3. **Casting and audio chain.**
   - Nine characters use four voice ids: `Tbj9...` is Nitzi, Jili, Romi, Gali and the daughter; `6Ijsl...` is Tamir and Keshet; `8sZ9...` Tzuri; `ZiofZ...` hero-son [M: voices.json]. Different hosts sound like the same adult woman, so there is no "new friend" surprise.
   - Adult-narrator register for a 2-year-old: even pace (median 1.6 to 1.75 words/s [M]), no sing-song, no breath, no giggle.
   - Older clips and every live tutor clip are 22.05 kHz / 32 kbps (metallic) [M, diagnosis §1]; 2.1.0 remade Nitzi at 44.1 but the gateway format was still hard-coded to 22.05 at the time of the diagnosis [R, not re-checked].

(Ranking inside the voice: Turbo for the male narrator and flat settings > no per-line-type direction > isolation and gaps > sample rate. I have not heard any of this; the owner's audition in section 3a decides.)

### 1c. Delivery
- Latency: pack clips play from memory, so start latency is low [G]. But `sayNext` makes a line wait for the one playing, drops a line that waited over 6 s and gives way to the child's next move [M: PROGRESS.md 2026-10-28]. A toddler who taps fast hears gaps and silence, not overlap.
- No on-device fallback voice (a missing clip falls to the narrator's bank, then silence) [M: `voice_bank.dart` fallback]. Live tutor lines are 22 kHz.
- Clips can be cut by a stale-line rule; this is a design choice for 5-year-olds that a 2-year-old's random tapping triggers constantly.

### 1d. What a 2-year-old hears in a first lesson, second by second [G, from the code]
- 0 s: room opens. Silence (no music, no ambience).
- 1 to 4 s: the host says a greeting in an adult voice, nothing else moves in sound. She cannot read, so the text is nothing; she watches the host.
- 4 to 9 s: the question is said (maybe two clips with a gap). She taps something: **silence**. She taps again: silence. She does not know she did anything.
- If the tap is on a right answer: after the previous line ends, a cheer line ("kol ha-kavod", stability 0.1, possibly at a different volume), no chime. The picture reacts; the sound world does not.
- A wrong or random tap: a calm voice "not yet" line, no sound of her own touch.
- 20 to 60 s: the lesson ends; a ceremony voice line. Then silence. Her attention is gone before this because nothing rewarded each touch.

## 2. What good kids' apps do with sound (ages 2 to 5)
- Sesame Workshop's review of 50+ studies of preschool touchscreen use: children expect immediate feedback on touch; sound effects are an effective way to show input registered; encouraging audio and visual feedback after an incorrect answer [R: summary via search, see Sources; I did not open the original].
- Google's kids-app guidance: respond to an action with sound, visuals and text together, because under-5s cannot read and may not know sound is off; keep sounds essential; return the child quickly to play after a mistake [R].
- Practice I use as direction (no source found for the specific apps, [G]): a sound on every touch; many small variants so praise never repeats exactly; a short musical stinger, not a long speech, for success; call-and-response ("Where is the red flower? ... you found it!"); a calm mode and a parent volume. No franchise sounds, melodies or characters are copied; everything below is original.
- Gap: I found no peer-reviewed toddler sound-design study, and nothing on Toca Boca or Khan Academy Kids. The owner's own listening is the best test.

## 3. The plan

### 3a. Voice performance
Honest answer on Hebrew: ElevenLabs lists Hebrew only on v3, v3 conversational, v4 and v4 Turbo [R: diagnosis §1]. v4 is called their most emotive model [R]; I cannot promise a warm toddler-teacher voice without hearing it. It can be good enough for narration and "wow/oh no" reactions; it will likely stay a little polished. A human recording of the few key lines is the safe fallback.

What to change (all subject to the owner's audition):
| Item | Change |
|---|---|
| hero-son | Move from Turbo to `eleven_v4` (diagnosis open question; owner's 2026-11-15 item 4 on his fix listening sheet was exactly "is v4 clearly better"). Normalise loudness like the others. |
| Settings per line type | Do not rely on one setting. Greeting and question: stability about 0.4 to 0.5. Cheer: 0.25 to 0.35 (0.1 is erratic, diagnosis). Comfort ("not yet"): 0.5. List/counting: 0.6 for evenness. Final values come from the audition. |
| Direction by tags (v4/v3) | `[warmly]`, `[curious]`, `[excited]`, `[gently]`, `[giggles]`, `[whispers]` at most one or two per line; tags are "not yet perfect" on v4 and respond more at lower stability [R: ElevenLabs prompting page, search]. Audition decides if Hebrew obeys them. |
| Non-word sounds | A small "reaction bank" per narrator: giggle, "wow", "ooh", "oops", "hmm", "yay", "hop!". Short clips (3 to 8 chars). Heard as the human part of the app. |
| Cheers | 10 to 12 different short cheers per narrator, rotating without repeating the last two. Short: 1 to 3 words. |
| Sentence level | Voice a whole short exchange as one request where it helps (the prompt and the question in one clip), with whole-activity voicing only if the audition shows it wins (H6 in the diagnosis). |
| Hosts | Give each of the nine hosts its own voice or at least its own settings; at minimum separate Jili, Romi, Gali, the daughter from Nitzi. A child voice is not an option (no real-child imitation; a model child voice is a voice-design decision for the owner). |
| Breath and pace | Punctuation only (v4 ignores speed): shorter sentences, `...` for a beat. The text editor owns letters; I request punctuation only. |

**Audition the owner can run** (the paid commands are his; Claude runs only the free ones). I will write the spec `docs/audio/audition/m12-warm.json` (format `audition/v1`) with about 24 clips, about 1,300 characters:
- 6 lines x 2 voices (Nitzi, hero-son) on `eleven_v4`: greeting, question, right cheer, not-yet, number counted 1-2-3, ceremony; plain against tagged (`[warmly]`...) against lower stability.
- 6 reaction sounds (giggle, wow, oops...).
- Cost: **about 1,300 characters, about 0.10 USD on v4** [G: 0.08 USD per 1,000 chars, list]. The tool prints the real number; he types it.
- Free first: `dart run tool/voice_gen.dart plan --characters nitzi,hero-son`, `dart run tool/voice_gen.dart audition-batch plan docs/audio/audition/m12-warm.json`.
- Paid, his terminal only: `dart run tool/voice_gen.dart audition-batch run docs/audio/audition/m12-warm.json` (he types the count it shows).

**Alternatives if v4 Hebrew is still too flat:** (1) the owner or his wife records about 30 key lines (greeting, 6 cheers, comfort, goodbye, lesson-end, sticker) in their own voice; adult voices only, kept local in the app as assets, never uploaded, never cloned by a model; no recording of the children. A real warm adult voice for the highest-frequency lines is the strongest fix for "robotic", at the price of the owner's time. (2) A different ElevenLabs voice chosen by listening to the library's Hebrew voices, tested with the same audition spec. (3) Keep TTS for lesson content and use human lines for greeting/cheer/comfort. Need the owner's decision.

**Re-voicing cost** (an estimate; the free `plan` prints the real number): the full run of both narrators was about 12.40 USD on v4 before the Languages and the new lessons [R: diagnosis]; Nitzi's 4,305 ids plus hero-son on v4 is the order of 12 to 20 USD [G]. Cheers + reactions only: about 60 clips, under 600 characters, under 0.05 USD. Do the audition first; do not re-voice everything until he likes the result.

### 3b. Sound design: an original kit made in the repo
All sounds are synthesised by a script (`app/tool/sfx_gen.dart`, no new package: pure Dart writing 16-bit mono WAV, 22.05/44.1 kHz) from sine/triangle waves, an ADSR envelope and a little filtered noise, in pentatonic scales (a pentatonic never clashes, so random taps stay pleasant). Cost: 0 USD, no licence question, reproducible. WAVs are small (under 100 KB each, total about 1.5 MB). A licence-clean library (e.g. CC0) is an alternative; it needs the owner's OK for any new asset source. Music: a short loopable bed per land synthesised the same way (marimba, kalimba, celesta-like timbres from additive synthesis); if it sounds poor, the owner may pick CC0 music, or I design it for a musician.

Kit (original; none of it from any franchise):
| Name | Character | Length |
|---|---|---|
| `tap` | soft wooden "tok", 3 pitch variants | 60 ms |
| `pickup` | rising "bloop" | 120 ms |
| `drop` / `snap` | low soft "pop" / "click-pop" | 100 ms |
| `correct` x6 | 3-note rising pentatonic chime, 6 starting pitches, sparkle tail | 450 ms |
| `again` | two soft descending notes, round, no buzzer, no low rumble | 300 ms |
| `hint` | twinkle: 3 quick high notes | 350 ms |
| `count1..10` | one marimba note per count, rising in pitch | 150 ms each |
| `stinger.<land>` x9 | 1 to 1.5 s, the land's instrument (marimba, kalimba, celesta, woodblock...) | 1.2 s |
| `host.<id>` x9 | 0.5 s motif of the host, played on entry | 0.5 s |
| `lessonEnd` | 2.5 s: rising run, held major chord, soft sparkle | 2.5 s |
| `sticker` | glass bell plus tiny shimmer | 1 s |
| `medal` | brighter than sticker, 3 s, a gentle fanfare | 3 s |
| `home` theme | 4-bar loop, 100 bpm, quiet | 16 s loop |
| `lullaby` | 70 bpm wind-down | 20 s loop |
| `amb.<room>` x9 | very quiet loopable ambience (wind and birds, water, market murmur) built from filtered noise; optional | 20 s loop |
| mic open/close | "bloop-up"/"bloop-down" | 150 ms |

Mix rules (from design-spec §11, with exact values): voice about -16 LUFS integrated; music bed about -28 LUFS; SFX about -20 LUFS peak-matched to voice (never louder than voice); true peak at most -1 dBTP; music ducks 14 dB under voice (attack 120 ms, release 600 ms); ambience ducks fully under voice; **no effect starts within 150 ms of a voice onset**, but a touch sound is allowed instantly when no voice is speaking; effects under voice at -6 dB; start with a 30 ms fade-in and end with a short fade-out so there are no clicks; nothing sudden or loud. Parent controls: three sliders (music, effects, voice) plus one **Calm mode** switch (music off, ambience off, stingers shortened and quieter, same chimes). Haptics: light impact on pick-up and snap, a gentle "success" on correct and celebrate; none on "again"; follows system settings and a parent toggle (Flutter's built-in `HapticFeedback`, no new package).

Measuring the kit: `ffmpeg -i x.wav -af ebur128=peak=true -f null -` (ffmpeg may not be installed on this machine; install per `owner-voicing-runbook.md`). I report measured loudness; I do not claim to hear it.

### 3c. Where each sound fires (event -> sound), with limits
| Event | Sound | Haptic |
|---|---|---|
| Any tap on an interactive thing | `tap` (varied pitch, from a short pool) | light |
| Tap on scenery/host | small character sound; host giggle clip (from the reaction bank) | light |
| Pick up | `pickup` | light |
| Drop in place / snap | `snap` | medium-light |
| Drop in the wrong place | `drop` (soft), item floats back | none |
| Count tap on item n | `count n` (rising note), then the voice may say the number | light |
| Correct | `correct` (variant, never the same twice in a row), then a short cheer line after 150 ms | success |
| Try again / unclear speech | `again` (kind, 300 ms) then the voice says the "not yet" line in a curious tone. Never "wrong". | none |
| Hint | `hint` twinkle, then the hint line | none |
| Room entry | `host.<id>` motif plus the host's greeting; music crossfades to the land's bed | none |
| Land/map | home theme at -28 LUFS; ambience of the room under it | none |
| Lesson end | `lessonEnd` (celebrate L), then the ceremony line | success |
| Sticker / medal | `sticker` / `medal`, then the line | success |
| Mic open/close | bloop-up/down; music off while listening | none |

Limits: at most one voice at a time; at most 2 effects overlapping; touch sounds throttled to one per 80 ms and a maximum of 6 in 2 s (a toddler's mash makes a pleasant scatter, not a roar); the same `correct` pitch never twice in a row; the cheer line is voiced at most every second correct answer (the chime does the rest) so praise does not repeat; no sound at all for time passing.

What "celebration" sounds like, three sizes:
- **S: every right answer** (under 1 s): `correct` chime (3 notes up) plus a 1 to 2 word cheer ("Hooray!", "Yes!") in one of the 10 to 12 rotating cheers, plus the host's small motion and a light success haptic.
- **M: a set done or a sticker** (about 2 s): `sticker` bell, a rising run, the host's giggle or "wow" clip, then a short line naming the thing.
- **L: lesson end or a milestone** (3 to 4 s): `lessonEnd` or `medal`, the land's instrument playing its theme, then the ceremony line; the home theme fades back in softly. Bright, never shouting; ends soft.

### 3d. Order of work, in small shippable steps
| # | Step | Who | Cost |
|---|---|---|---|
| 1 | `sfx_gen.dart` + the first kit: `tap`, `correct` x6, `again`, `hint`, `pickup`, `snap`, `lessonEnd`, `sticker` (about 12 files). Loudness measured. | me (spec and values), app-developer builds the tool | 0 |
| 2 | `SfxPlayer` (separate low-latency `audioplayers` players, pool of 4), the event table in section 3c wired to `hopLanded`, `celebrateDone`, `pokeDone`, taps, correct/again; ducking and 150 ms rule; haptics; parent sliders and Calm mode. Tests with a fake player. | app-developer, then qa-engineer | 0 |
| 3 | Owner listens on his phone with his daughter. Decide by ear. | owner | his time |
| 4 | Voice audition (3a), about 1,300 characters, about 0.10 USD. | owner runs it, I write the spec and check lengths and loudness | about 0.10 USD |
| 5 | If good: cheers and reactions bank for both narrators, about 60 clips, under 600 characters, under 0.05 USD; hero-son to v4 with normalisation. | owner pays, I give directions in `voice-direction.csv` | under 0.5 USD for the cheers; a full re-voice later is 12 to 20 USD [G], only after he has chosen the voice |
| 6 | Land stingers and host motifs (9 + 9), home theme, per-room ambience; music crossfade. | me and app-developer | 0 |
| 7 | Separate host voices (new ids) per the owner's picks. | owner chooses voices by audition | an audition about 0.1 USD |
| 8 | Optional human recordings of about 30 key lines. | owner/family | their time |
| 9 | QA pass: every event has a sound or is deliberately silent; no click; loudness within 1.5 LU; the test that every `vo` id has a clip. | qa-engineer | 0 |

Hand-offs to the design-director: the timing of `hopLanded`/`celebrateDone`/`pokeDone` and a short list of reaction animations that go with the giggle and "wow" clips (so a sound never plays with a still picture).

## 4. Risks and the child-safety check
- **No guilt, no pressure** [M rule, CLAUDE.md]: no timer ticks, countdowns, streak sounds, "you lost" sounds, siren-like or buzzer sounds. `again` is soft and round. An unclear answer is never "wrong". Celebrations do not rank (no "better than", no "streak of 5").
- **Overstimulation**: a 2-year-old plus 6 touch sounds a second can be too much; throttles above; Calm mode; the volume stays within the device's media volume; music is quiet; nothing sudden: fade-in 30 ms, soft ends, true peak at most -1 dBTP.
- **Sound spam and fatigue**: variants and the cheer rotation. If the same chime is heard 30 times it still must not annoy: short, soft, six pitches.
- **Privacy**: no child audio is stored or sent; the mic opens only on tap and only when a parent turned voice on; the child's first name may go inside a voiced line to ElevenLabs (owner's 2026-10-25 decision) and nothing else. A family recording (3a alternative) is adult audio, stays on the phone, and is not uploaded.
- **Voices**: no model cloning of a real person; a family recording is a recording, not a model.
- **Risk that v4 Hebrew stays flat**: then the human-recording route (3a). I will not claim it solved until the owner has listened.
- **Money**: Claude never runs a paid command; the owner types the character count.

## 5. Questions only the owner can answer
1. Listen to the audition (3a) and choose: v4 with tags, or record the key lines himself or his family.
2. Move hero-son to `eleven_v4` (about twice the price)?
3. Do the hosts get their own voices (nine voices, with an audition) or only separate settings?
4. Music and ambience: made in the repo (free, simple timbres) or a licence-clean library (his OK)?
5. Calm mode: on by default for under 3 years old?

## Sources
- Sesame Workshop review of preschool touchscreen best practice, via search summary (touch feedback, sound as input confirmation): https://core.ac.uk/download/56379301.pdf and https://screenwiseapp.com/media/sound-touch-app (I did not open these; the summary came from the search tool).
- Google, "Designing engaging apps" (kids' apps: sound plus visuals, under-5s cannot read, essential sounds only): https://developers.google.com/building-for-kids/designing-engaging-apps
- ElevenLabs v3 prompting (stability presets Creative/Natural/Robust, audio tags): https://elevenlabs.io/docs/best-practices/prompting and https://elevenlabs.io/blog/v3-audiotags
- Repo: `docs/audio/voice-quality-diagnosis.md` (v4 takes no style/speed, Hebrew model list, prices), `content/voices.json`, `app/lib/voice/*`, `docs/design-spec.md` §11, `docs/milestones/M11.md` item 6.
