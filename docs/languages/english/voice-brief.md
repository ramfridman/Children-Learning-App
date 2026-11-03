# English course: voice brief (for the voice-and-sound-director)

From: english-language-teacher. Date: 2026-11-03. Status: draft brief; nothing voiced, no audition run.
Binding: `docs/languages/README.md` decision 6 (one teaching voice per language that speaks **natural Hebrew and the target language natively**; if no single voice is excellent in both, propose the best alternative with samples for the owner); `.claude/skills/pronunciation-spec/SKILL.md`; `CLAUDE.md` › Characters and money.

**Money and keys.** This brief makes no paid call and uses no ElevenLabs API or key. Claude never runs `voice_gen generate`, `audition` or `audition-batch run` and never reads `ELEVENLABS_API_KEY`. The voice-and-sound-director plans the auditions (free `plan` commands only); the owner runs and pays for every audition and generation in his own terminal and types the character count. Never imitate a real person's voice.

---

## 1. What the voice is for

Every English lesson has two kinds of speech:
1. **The Hebrew frame**: instructions, praise, hints and short Hebrew-English contrasts (for example a line saying that English is read from left to right; the wording is the hebrew-text-editor's). Standard Israeli Hebrew, warm, clear, the same teaching register as the app's other lessons.
2. **The English target**: words, chunks, sentences, songs and chants, stories, letter sounds, segmented words ("robot talk") and English classroom instructions ("Listen!", "Touch the cat."). **Native English, General American** (pending the owner's choice: syllabus §9 decision 1; if British is chosen, Southern Standard British throughout).

The child must hear the English **exactly** right: a wrong vowel in a model word teaches the wrong sound. The English target is the priority when a choice must be made.

## 2. Options to audition (the director's call; for the owner's decision)
- **A. One bilingual voice** (decision 6's first choice): one voice id that is natively Israeli in Hebrew **and** native General American in English. Test: the English lines must have none of the Israeli-accent features in §4.3, and the Hebrew must sound native (the hebrew-text-editor listens).
- **B. Two voices that sound like one teacher pair**: the Hebrew teaching voice (possibly an existing app voice) for the frame, and a native General American voice for every English target clip, presented as a friend who "speaks English". The split-clip design (§3) makes this easy, and `pronunciation-spec` §3 already prefers split clips.
- **C. A fallback for isolated sounds only** (§5): if no voice gives clean isolated phonemes after the pilot, use stretched whole words ("sssun"), or, as a separate owner decision, a recorded set by a hired native speaker (an original recording, not an imitation).
My recommendation: audition A and B side by side on the pilot set (§7); choose A only if its English passes every check in §4 and §5.

## 3. Clips: always split by language
- A line that mixes Hebrew and English is **two clips** played in sequence: the Hebrew frame, a short pause (about 250 ms), the English target. The English clip is reused wherever that word appears.
- English targets are generated with the model's language set to English; Hebrew frames with Hebrew.
- The text shown to the child (`shown`) never changes to fix a voice; respellings, stress marks or commas go in `say` (pronunciation-spec §1).

## 4. English: what correct sounds like

### 4.1 Register and pace
- Warm, clear, child-directed but natural: **no** baby talk, no sing-song exaggeration, no shouting.
- Target words and chunks: slightly slow (about 110-130 words a minute in sentences), every word fully formed, with natural stress and rhythm (weak words stay weak: "It's a /ə/ cat").
- A "slow" variant of each target word for hint level 1: about 70% speed, the vowel lengthened, nothing distorted.
- Stories and songs: natural storytelling pace; songs on a steady beat (the director chooses music; the words are mine).

### 4.2 The accent: General American
- Rhotic: r is pronounced after vowels (car /kɑɹ/, bird /bɝd/, her /hɝ/).
- Short o is /ɑ/ (hot, top, box, sock, on). Words that vary in General American (dog, frog, on) are accepted either way and are not used as short-o models.
- "ee" /i/, "oo" /u/ (moon), /ʊ/ (book), "oa" /oʊ/, "ai" /eɪ/: full diphthongs.
- Flapping of t between vowels (water, butter) is natural in sentences; isolated decoding words avoid it (no "kitten" in early lists).
- The /æ/ of cat, man, apple must be clearly /æ/ (front, open), not /ɛ/ and not a Hebrew /a/.

### 4.3 Traps for an Israeli-accented English voice (each one fails the check)
| Trap | Wrong | Right | Test words |
|---|---|---|---|
| /w/ → /v/ | "vindow", "vet" for wet | /w/ with rounded lips, no teeth on lip | wet, web, window, walk, swim, one, what |
| /θ/ /ð/ → t, s, d, z | "tree" for three, "dis" for this | tongue between the teeth | three, thank you, thumb, bath, this, that, the, brother |
| /ɪ/ = /i/ | ship = sheep, it = eat | lax short /ɪ/ vs long /i/ | ship/sheep, it/eat, sit/seat, fish |
| /æ/ → /ɛ/ or /a/ | "ket", "men" for man | /æ/ | cat, man, apple, hat, bag, black |
| /ʌ/ → /a/ or /o/ | "kap" for cup | /ʌ/ | cup, sun, up, bus, duck, mum (British) |
| uvular r | French-like r | General American /ɹ/ | red, rabbit, car, bird, three |
| full vowels in weak syllables | ba-NA-na with three /a/ | /bəˈnænə/ | banana, sister, elephant, a, the, to |
| /ŋ/ → /ŋɡ/ | "sing-g" | /sɪŋ/ | sing, ring, king, song, jumping |
| final clusters simplified | "nes", "han" | every consonant | nest, hand, milk, jump, desk, gift |
| /h/ dropped | "ello", "at" for hat | clear /h/ | hello, hat, hen, head, hands |
| stress | eleFANT, baNAna wrongly placed | ELephant, baNAna, TEACHer, WINdow, YELlow | the stress column of the spec |
| Hebrew dental t/d | (minor) | alveolar, aspirated /tʰ/ at word start | top, ten, tap |

### 4.4 Sounds that do not exist in Hebrew (the reason this course exists)
/w/, /θ/, /ð/, /ɪ/ (vs /i/), /æ/, /ɛ/ (vs /æ/), /ʌ/, /ʊ/, /ɝ/, /ɹ/, /ŋ/, /ə/, and the diphthongs /eɪ/ /oʊ/ /aɪ/ /aʊ/ /ɔɪ/ in their English quality. (Hebrew has five vowels with no length contrast and a uvular r; research [Laufer99].) These get the **minimal-pair clips** of §6 and the closest listening check.

## 5. Isolated sounds (the hardest part)

Letter sounds and robot talk need sounds **without an added vowel**: /m/, not "muh"; /t/, not "tuh". Text-to-speech voices often add a vowel or swallow a short sound. Plan them as a **pilot first** (pronunciation-spec §2).

### 5.1 How each kind of sound must be made
- **Continuants** (can be held): /s/ /z/ /f/ /v/ /θ/ /ð/ /ʃ/ /m/ /n/ /ŋ/ /l/ /ɹ/: held about 0.6-0.8 s, steady, no vowel at the end.
- **Stops** /p/ /t/ /k/ /b/ /d/ /ɡ/: a short, crisp burst; voiceless ones whispered with aspiration; voiced ones with the smallest possible vowel. Never "puh", "buh".
- **Affricates** /tʃ/ /dʒ/: short, no vowel after.
- **Glides** /w/ /j/ and /h/: very short, the lips rounded for /w/; /h/ is a breath. (These are the least clean in any voice; if they fail, use the stretched-word fallback.)
- **Short vowels** /æ/ /ɛ/ /ɪ/ /ɑ/ /ʌ/ /ʊ/: about 0.4 s, steady quality, no glide.
- **Long vowels and diphthongs** /i/ /u/ /eɪ/ /oʊ/ /aɪ/ /aʊ/ /ɔɪ/ /ɑɹ/ /ɔɹ/ /ɝ/: about 0.5 s, the full movement.
- **Fallback** for any sound that fails: the key word with the sound stretched at the start ("sssun", "mmmap") or, for stops, the key word said twice ("t… tent").

### 5.2 Robot talk (segmented words)
Each sound as in §5.1, separated by about 350 ms of silence (shorter, about 150 ms, for the "stretch and blend" version), then the whole word after about 600 ms. Example: /k/ · /æ/ · /t/ … "cat". The segments may be assembled from the isolated-sound clips (cheaper and consistent); the whole word is its own clip.

### 5.3 The sound list (draft spec rows; the full table goes to `docs/languages/english/pronunciation.csv` with the first content batch)

| Grapheme | Sound (GA, broad IPA) | Key word | Kind | Trap for a voice / a Hebrew-speaking child |
|---|---|---|---|---|
| s | /s/ | sun | continuant | added vowel "suh" |
| a | /æ/ | apple | short vowel | /ɛ/ or Hebrew /a/ |
| t | /t/ | tent | stop | "tuh"; dental t |
| p | /p/ | pan | stop | "puh"; no aspiration |
| i | /ɪ/ | igloo | short vowel | /i/ (as in Hebrew) |
| n | /n/ | net | continuant | "nuh" |
| m | /m/ | map | continuant | "muh" |
| d | /d/ | duck | stop | "duh" |
| g | /ɡ/ | goat | stop | "guh"; confusion with /dʒ/ |
| o | /ɑ/ | octopus | short vowel | Hebrew /o/ |
| c, k, ck | /k/ | cat, kite, sock | stop | "kuh" |
| e | /ɛ/ | egg | short vowel | /æ/ or /eɪ/ |
| u | /ʌ/ | up | short vowel | /a/ or /u/ |
| r | /ɹ/ | rabbit | continuant | uvular r; "ruh" |
| h | /h/ | hat | breath | dropped; "huh" |
| b | /b/ | ball | stop | "buh" |
| f | /f/ | fish | continuant | |
| l | /l/ | lion | continuant | dark l only at the end (bell) |
| j | /dʒ/ | jam | affricate | "juh" |
| v | /v/ | van | continuant | must differ from w |
| w | /w/ | web | glide | /v/ |
| x | /ks/ | box | (cluster, at the end) | /z/ or /s/ |
| y | /j/ | yo-yo | glide | read as a vowel |
| z | /z/ | zip | continuant | /s/ |
| qu | /kw/ | queen | cluster | /kv/ |
| sh | /ʃ/ | ship | continuant | /s/ |
| ch | /tʃ/ | chip | affricate | /ʃ/ |
| th | /θ/ | thumb | continuant | /t/ /s/ /f/ |
| th | /ð/ | this | continuant | /d/ /z/ |
| ng | /ŋ/ | ring | continuant | /ŋɡ/, /n/ |
| ee | /i/ | bee | long vowel | /ɪ/ |
| oo | /u/ | moon | long vowel | |
| oo | /ʊ/ | book | short vowel | /u/ |
| ai, ay, a_e | /eɪ/ | rain, day, cake | diphthong | flat /e/ |
| oa, ow, o_e | /oʊ/ | boat, snow, home | diphthong | flat /o/ |
| igh, i_e, y | /aɪ/ | night, bike, my | diphthong | |
| u_e | /ju/ | cube | glide + vowel | |
| ar | /ɑɹ/ | car | r-colored | silent r (British) |
| or | /ɔɹ/ | fork | r-colored | |
| er, ir, ur | /ɝ/ | her, bird, fur | r-colored | /eʁ/ |
| ou, ow | /aʊ/ | out, cow | diphthong | |
| oi, oy | /ɔɪ/ | coin, boy | diphthong | |
| (schwa) | /ə/ | the "a" in "a cat", the first syllable of "banana" | weak vowel | a full vowel |

Each row will get `id`, `shown`, `say`, `ipa`, `stress`, `accent: General American`, `traps`, `check`, `status: draft` in the CSV.

## 6. Minimal pairs (listening contrasts; both words voiced the same way, same pitch and length)
| Contrast | Pairs (pictured) | Listening only (not pictured) |
|---|---|---|
| /w/ vs /v/ | wet / vet · west / vest | |
| /θ/ vs /t/ | three / tree · thin / tin · thank / tank | |
| /ɪ/ vs /i/ | ship / sheep · sit / seat · it / eat | fill / feel |
| /æ/ vs /ɛ/ | man / men · pan / pen · bat / bet | |
| /æ/ /ɑ/ /ʌ/ | hat / hot / hut · cap / cup · cat / cut | |
| /ŋ/ vs /n/ | | sing / sin |
| short vs long (silent e) | cap / cape · kit / kite · hop / hope | |

Rule: only real, picturable words a child can know are answer pictures; a pair whose second word is hard to picture or not child-appropriate is listening-only ("same or different?").

## 7. The pilot (before any batch; the owner runs and pays)
A small audition set for options A and B (§2), to be planned by the director (character count printed by the free `plan` command, the owner's typed number):
- 12 isolated sounds: /s/ /m/ /t/ /p/ /æ/ /ɪ/ /ɑ/ /ʌ/ /w/ /v/ /θ/ /ð/.
- 1 robot-talk word: c-a-t.
- 6 minimal pairs: wet/vet, three/tree, ship/sheep, man/men, hat/hot/hut, sing/sin.
- 6 words with stress traps: banana, elephant, window, yellow, teacher, apple.
- 4 chunks: "Hello!", "What's this? It's a cat.", "Thank you.", "I like bananas."
- 3 Hebrew frame lines (from the hebrew-text-editor), to check the Hebrew of option A.
I listen-check every English clip against §4 and §5 and mark `heard-ok` or `heard-wrong` with the reason; the hebrew-text-editor checks the Hebrew; the owner decides.

## 8. The listening check (after every voicing)
For every English clip: the right sounds (§5.3), stress, no Israeli-accent trap (§4.3), no added vowel on letter sounds, weak forms weak, the same voice quality across the set, no clipping at the start or end (stops are easily cut). A lesson is not ready while any clip is `heard-wrong` or unheard (pronunciation-spec §4).

## 9. Open for the director and the owner
1. Option A or B (§2), after the pilot.
2. Whether the chosen model supports a phoneme or IPA input for single sounds; if yes, the director proposes how to use it in `say`.
3. The isolated-sound fallback (§2 C) if the pilot fails.
4. American or British (syllabus §9 decision 1): this brief assumes General American.
