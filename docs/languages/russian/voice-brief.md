# The Russian course: voice brief (and a font requirement)

*Owner: russian-language-teacher. For the voice-and-sound-director (the voice) and the design-director (the font, §8). Draft 2026-11-03. Plan only.*
*No paid call was made and none is proposed here to be run by Claude. Every audition and generation is the owner's, in his own terminal (`CLAUDE.md` › Characters and money). The pilot rows are in `docs/languages/russian/pronunciation.csv` (status `draft`).*

## 1. Who says what
- **Hebrew clips:** every instruction, praise and help line, in natural Israeli Hebrew, from the hebrew-text-editor's `voice_text`. Gender-neutral as in the rest of the app (`docs/PLAN.md` › Speaking to the child).
- **Russian clips:** everything the child is learning: sounds, syllables, words, phrases, sentences, rhymes and stories.
- **Split, never mixed:** a line like "where is the кот?" is two clips: the Hebrew instruction, then the Russian word (`pronunciation-spec` §3). A Hebrew clip never contains a Russian word and the other way round.
- **One voice or two** (owner's decision 6): best is one voice that is natively right in both; if no single voice is excellent in Russian, the **Russian clips win**: a native Russian voice for the Russian clips and the Hebrew teaching voice for the Hebrew clips, with matched warmth, pace and loudness, is better than one voice with an accent in Russian. The director proposes, with samples, and the owner chooses.
- No real person's voice is imitated. No cartoon-character voices.

## 2. The Russian the voice must speak
**Accent:** standard Russian literary pronunciation (the Moscow-based norm taught in Russian schools and used in national broadcasting): neutral, no regional colouring, no Israeli-Russian features (no uvular р, no Hebrew vowels, no Hebrew stress habits). A warm, clear teaching voice, slower than conversation but **natural**.

| Feature | What the voice must do | Examples (IPA in the CSV) |
|---|---|---|
| **Stress** | Every word on the right syllable, every time; stress moves between forms and the voice must follow the form | молоко́, рука́ / ру́ку, вода́ / во́ды, ры́ба, ёлка (ё always stressed) |
| **Vowel reduction** | Unstressed о and а as [ɐ] (just before the stress) or [ə] (elsewhere); unstressed е and я after a soft consonant as [ɪ]. **Never** a full [o] in an unstressed syllable in normal speech, even when speaking slowly | молоко́ [məlɐˈko], вода́ [vɐˈda], лиса́ [lʲɪˈsa], ма́ма [ˈmamə] |
| **Hard and soft consonants** | A clear difference: soft consonants palatalised, hard ones not; л hard is dark [ɫ] | лук [ɫuk] / люк [lʲuk], мы [mɨ] / ми [mʲi], сел [sʲeɫ] / съел [sjeɫ] |
| **ы** | A true [ɨ], never [i] or [uj] | мы, сыр, ры́ба |
| **Always hard: ж, ш, ц** | ши and жи sound [ʂɨ], [ʐɨ]; цы [t͡sɨ] | жира́ф [ʐɨˈraf], маши́на, цыплёнок |
| **Always soft: ч, щ** | ч is [tɕ]; щ is a long soft [ɕː], never [ʃtʃ] | мяч [mʲætɕ], щу́ка [ˈɕːukə] |
| **р** | A tongue-tip trill or tap [r], [rʲ]; never uvular | ры́ба [ˈrɨbə], рука́ [rʊˈka] |
| **Final devoicing** | Voiced consonants at the end of a word devoice | дуб [dup], хлеб [xlʲep], ёж [joʂ] |
| **Assimilation** | Voicing assimilates to the next consonant | ло́жка [ˈɫoʂkə], ска́зка [ˈskaskə] |
| **Set exceptions** | что [ʂto], его́ [jɪˈvo], со́лнце [ˈsont͡sə] (л silent), здра́вствуйте [ˈzdrastvʊjtʲe] (first в silent), пожа́луйста [pɐˈʐaɫəstə] | |
| **я, е, ё, ю at the start of a word or after a vowel** | Said with [j] | я́ма [ˈjamə], ёлка [ˈjoɫkə], ель [jelʲ] |
| **ъ** | A [j] after the consonant, which stays hard or nearly hard | съел [sjeɫ] |

**Pace by band:** Band A and B words with a short pause before and after; phrases at a calm pace with natural rhythm; Band C sentences and stories at a slow storytelling pace. No "baby talk", no sing-song distortion of vowels, no exaggerated stress that changes vowel quality.

## 3. Special clip types (the hard part for any text-to-speech voice)
1. **Isolated sounds** (Russian school notation [м], [м’]): the sound alone, **not the letter name** (м is "ммм", not "эм"). Continuants (м, н, л, р, с, з, ш, ж, ф, в, х, щ and all vowels) can be held for about a second. Stops (п, б, т, д, к, г) cannot be held: a short burst with **no vowel after it** (not "кэ", not "ка"). Soft sounds [м’] must not become the syllable ми. These are the most likely to fail: **pilot first** (CSV rows `snd-*`); where a clean isolated sound cannot be made, use the syllable or the whole word instead (`pronunciation-spec` §2), and the app shows the sound through the word.
2. **Stretched sounds inside a word** (интонацио́нное выделе́ние, for the sound scheme LS03 and the first-sound items of A-19): the word with one sound held longer, the rest natural: с-с-сом, со-о-ом, сом-м-м. One clip per sound position. If the voice cannot do it from text, record the word normally and let the app hold no sound (the scheme still works with the plain word).
3. **Syllables** (ма, мя, мы, ми, …): each said as a clear stressed syllable, full vowel. The **syllable slide** (LS04 `merge`) needs the consonant held then merged: "ммма". For stops only the syllable.
4. **The "as written" clip** (only for skill C-11 and the spelling checks C-21): the word read syllable by syllable as it is spelled (мо-ло-ко́), labelled `as-written` in the CSV. It is never the model for speaking and never used outside those skills.
5. **"Calling" a word** (B-17): the word as if calling from far away, the stressed vowel lengthened (ру-ка́-а!), without changing which syllable is stressed.
6. **Minimal pairs** (лук / люк, мы / ми, сел / съел, мал / мял): each word a separate clip, same pitch and loudness, so the only difference is the contrast.

## 4. Steering (with the voice-and-sound-director)
- The text sent to the voice is the `say` column; the child sees `shown`, which never changes to fix the voice.
- **Stress:** put U+0301 after the stressed vowel in `say`. Whether the chosen model honours it **is not known** (not verified in this session); the pilot rows test it. If it does not, the fallbacks are: a short carrier phrase that forces the right form; a different but equally good word; a respelling in `say` only. Homographs (за́мок / замо́к, му́ка / мука́) are avoided in the content.
- **ё:** always ё in `say` (it fixes both the vowel and the stress).
- The model's language setting is Russian for Russian clips, Hebrew for Hebrew clips.

## 5. Gender and the child
Core Russian lines never reveal the speaker's gender (no я был / я была́, no adjectives about the speaker). Lines addressed to the child avoid gendered forms: present tense and imperatives (смотри́, слу́шай) are neutral; past tense and short adjectives about the child (ты гото́в / гото́ва) are avoided; ты молоде́ц is neutral and may be used. The child's name never appears in Russian clips in this plan.

## 6. The listening check
Every Russian clip is checked against its CSV row before it reaches a child (`pronunciation-spec` §4): stress, vowel reduction, hard / soft, ы, the trap in the `traps` column. **I cannot hear audio myself**, so the check is done by a native-level Russian listener (the owner or a person he chooses) from my checklist, marking `heard-ok` or `heard-wrong` with what was wrong; I then fix the `say` and the row goes back to the director. A lesson is not ready while any clip is unheard or `heard-wrong`.

## 7. The pilot (for the owner to run, when he decides)
`pronunciation.csv` has 55 draft rows: 8 isolated sounds, 6 syllables, 4 minimal pairs (8 words), 3 stretched-sound clips, 1 calling clip, 26 words with the hard features of §2, 2 sentences and 1 as-written clip. They test exactly the risks above. The voice-and-sound-director turns them into an audition plan with the character count and cost; the owner runs it; the listener checks every clip; only then the voice is chosen.

## 8. Font requirement (for the design-director)
The Cyrillic font is approved in principle (owner's decision 1); the design-director chooses it, checks the licence and shows it to the owner. What the teaching needs:
1. **Complete Russian Cyrillic**: all 33 letters, capital and small, including Ёё (dots clear and separate at every size), Йй (the breve clear), Ыы, Ьь, Ъъ, Ээ, Щщ.
2. **Russian letter forms**, not Bulgarian or Serbian localised forms: д with its two feet (not a g-like д), л with the Russian shape, б with the Russian ascender. Check that the text is never rendered with a `bg` or `sr` language tag.
3. **Upright only. No italic or oblique anywhere** in Russian text: italic т looks like m, и like u, п like n, д like g, and would undo the letter teaching.
4. **а** in the reading text: the ordinary two-storey printed а that the child will meet in every Russian book (I believe Russian primers print this form; not verified in this session). The tracing model uses the same shape; the free-stroke check of LS02 memory mode also accepts a single-storey а, because children often write it that way.
5. **Look-alikes clearly different** at child sizes: б / в / 6, з / э / 3, ш / щ (щ's tail visible), ц's tail, и / й, ь / ъ / ы / б, е / ё, Н / И / П, Р (Cyrillic er) where a child also knows Latin.
6. **Readable for beginners**: large x-height, open counters, simple shapes without decorative terminals, generous letter spacing for single letters and syllables on tiles.
7. **The combining acute U+0301** placed correctly over every Cyrillic vowel, capital and small (for the stress skills and the stress-mark defaults of D15). Never over ё.
8. **Harmony with Heebo and Secular One**: similar weight and x-height on mixed screens. Candidates worth checking (not checked by me): Rubik (has Hebrew, Latin and Cyrillic), Noto Sans, and Andika (SIL, designed for literacy, has Cyrillic). All three are said to be under the OFL; the director confirms.
9. **Stroke data for tracing** (LS02, F6) drawn to match the chosen font's capital and small letters, with the order and direction of the Russian print copybooks (element by element: the sticks first, each top to bottom, then the lines across, left to right; teacher-checked 2026-11-05, decisions in `docs/languages/strokes.md` §5.2).
