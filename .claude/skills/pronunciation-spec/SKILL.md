---
name: pronunciation-spec
description: How to write and check the pronunciation spec of a spoken line, word, letter sound or syllable in Nitznutz (Hebrew, English, Russian) so the ElevenLabs voice says it exactly right - IPA, stress, the accent, the traps for Hebrew-speaking children, how to steer the voice without changing the shown text, and the listening check after voicing. Use for every new spoken item in a language lesson, and when a voiced clip sounds wrong.
---

# Pronunciation spec

A language lesson that teaches a wrong sound is worse than none. Every spoken item gets a spec before it is voiced, and every clip is checked against its spec after voicing. The teacher agent says what is correct; the voice-and-sound-director chooses the voice and settings to get it; the owner runs and pays for any generation (Claude never runs a paid voice command: `CLAUDE.md` › Characters and money).

## 1. The spec (one row per item)
Keep it in the language's table (`docs/languages/<language>/pronunciation.csv`), with these columns:
- `id`: the line id.
- `shown`: the text exactly as the child sees it.
- `say`: the text sent to the voice, if it must differ (a respelling, a stress mark, a pause). The shown text never changes to fix a voice.
- `ipa`: broad IPA of the intended pronunciation.
- `stress`: the stressed syllable(s), written out.
- `accent`: the accent the voice must use (for example General American or Southern British for English, standard Moscow pronunciation for Russian, standard Israeli Hebrew).
- `traps`: what a voice or a Hebrew-speaking child gets wrong here.
- `check`: what the listener must hear.
- `status`: `draft` → `checked` (by the teacher) → `voiced` → `heard-ok` or `heard-wrong`.

## 2. Language notes
- **Hebrew**: the stress (מלרע or מלעיל) of every word; dagesh changes (ב/בּ, כ/כּ, פ/פּ); shva na and nach; קָמָץ קָטָן; ח and ע as spoken in standard Israeli Hebrew. Nikud and the `voice_text` are the hebrew-text-editor's (`docs/agents/hebrew-notes.md`). Never let a model add nikud at runtime.
- **English**, the traps for Hebrew speakers: /w/ vs /v/, /θ/ /ð/, /ɪ/ vs /iː/, /æ/ vs /ɛ/ vs /ʌ/, /h/ dropped or overdone, final clusters (-sts, -lds), the schwa in weak syllables, word stress. For letter sounds, a clean sound with no added vowel (/m/, not "muh").
- **Russian**: mark stress in the spec with U+0301 (мáма) and confirm ё; vowel reduction (о → [ɐ]/[ə] unstressed, е/я → [ɪ]); hard vs soft consonant pairs; final devoicing (хлеб [xlʲep]); ы; щ; stress that moves between forms (рукá, рýку).
- **Isolated sounds and syllables** are hard for any text-to-speech voice: plan them as short pilot clips, listen to each one, and prefer a whole word with the sound in it when a clean isolated sound cannot be made.

## 3. Steering the voice (with the voice-and-sound-director)
- The model's language setting matches the language of the line, and the voice is a native-sounding voice for that language. Never imitate a real person's voice.
- Mixed-language lines (Hebrew instruction around an English or Russian word) are better split into separate clips, each in its own language voice, than spoken in one clip.
- To fix a stress or a sound, change `say` (a respelling, the stress mark, a hyphen or comma for a pause). Never change `shown`.

## 4. The listening check
After every voicing, the teacher listens to every clip of its language (or the owner does, from the teacher's list), marks `heard-ok` or `heard-wrong` with what was wrong, and a `heard-wrong` clip goes back to step 3. A lesson is not ready while any clip is `heard-wrong` or unheard.
