# The Hebrew course: voice brief (for the voice-and-sound-director) and letter-shape requirement (for the design-director)

Owner: hebrew-language-teacher. Status: **draft** (2026-11-03). Nothing was voiced or auditioned.
**No paid step is in this brief.** Claude never runs `voice_gen generate`, `audition` or `audition-batch run`, never calls api.elevenlabs.io and never reads or sets `ELEVENLABS_API_KEY` (CLAUDE.md). Every audition and generation is run and paid for by the owner, after he sees the character count.
Skills: `syllabus.md`. Evidence: `docs/research/hebrew-course-2026-11-03.md`. Method: `.claude/skills/pronunciation-spec/SKILL.md`.

**All Hebrew below is a draft, `"review": "needs-editor"`.** Letter and vowel names, nikud and stress are for the hebrew-text-editor to confirm. Where the editor and I disagree, we both write our reasons and the orchestrator asks the owner.

## 1. What the teaching voice must do

1. **Speak standard Israeli Hebrew**, warm and clear, a little slower than conversation, as a kind gan teacher (curriculum §8.5).
   - ח is [χ], the same as כ without a dagesh. ע is a light glottal stop or nothing, the same as א. ר is the Israeli [ʁ].
   - This is how children around them speak. It is also why the Ministry lists ח/כ and א/ה/ע as homophones (R §7).
   - The voice must not use a pharyngeal ח or ע: it would teach a contrast that the child's spelling cannot rely on.
2. **Say a CV unit as one clean syllable**, with level pitch (not a question), about the length of a stressed syllable, and no trailing vowel or breath: בָּ = [ba], מִי = [mi], שׁוּ = [ʃu].
3. **Say a stretchable consonant alone** with no vowel added (*not* "mə"), held about 0.6–0.8 s: מ [mːː], נ [nːː], ל [lːː], ר [ʁːː], שׁ [ʃːː], ס/שׂ [sːː], ז [zːː], ו/ב [vːː], פ/ף [fːː], ח/כ/ך [χːː].
   - The Ministry writes such a sound as the letter with a shva (חְ, שְׁ). It is the sound, not the name.
4. **Never say a stop consonant alone.** בּ גּ דּ ט/ת כּ/ק פּ צ, and the silent א ע, are heard only inside a CV unit or a word (בָּ, גִּי, דּוֹ…). A stop "alone" is always a stop plus a vowel, and that would teach the wrong sound.
5. **Read a word unit by unit, then whole.** For each word the course needs two clips:
   - **units:** each CV unit (or closed unit, יַלְ) said as in point 2, about 300 ms of silence between units;
   - **whole:** the word at a natural pace with its correct stress.
   The units clip never stretches a vowel unnaturally.
6. **Use the correct stress of every word** (§4). Most Hebrew words stress the last syllable (מִלְּרַע), and many common ones the one before it (מִלְעֵיל: יֶלֶד, סֵפֶר, אַבָּא).
7. **Say a shva as modern Hebrew does,** per word, from the editor's spec. At the start of a word it is mostly silent (גְּלִידָה [gliˈda], שְׂמִיכָה [smiˈχa]). It is [e] where modern speech has it, for example after the prefixes and in some starting letters. The editor's `voice_text` and IPA decide each word; the voice follows them.
8. **Letter names and letter sounds are different clips,** and a line never mixes them without a pause.
   - Example: "זוֹ גִּימֶל. הִיא אוֹמֶרֶת גְּ… כְּמוֹ בְּגִיר" is a teaching line, and the sound inside it is a CV unit (גִּי), not a bare stop.
   - The wording is the editor's. This line is only a shape.

## 2. The letters: names, sounds and how each is voiced (draft for the spec table)

Columns follow the `pronunciation-spec` skill. `say` is left empty here: it is filled only after a pilot clip shows a need. The `accent` is standard Israeli Hebrew for every row, and the `status` is `draft`. The rows become `docs/languages/hebrew/pronunciation.csv` at the milestone.

| Letter | Name (draft) | Name stress | Sound (IPA) | Alone? | Trap |
|---|---|---|---|---|---|
| א | אָלֶף | Á-lef (מלעיל) | ∅ / [ʔ] — carries the vowel | never: only אָ, אִ… | TTS says the name; a child thinks א is "a" |
| בּ | בֵּית | one syllable | [b] | no: בָּ | — |
| ב | וֵית (the name used for the soft ב; editor to confirm) | one syllable | [v] | yes, stretched | the same as ו in sound (homophone) |
| ג | גִּימֶל | GÍ-mel (מלעיל) | [g] | no: גָּ | name-sound mix (גִּי) |
| ד | דָּלֶת | DÁ-let (מלעיל) | [d] | no: דָּ | — |
| ה | הֵא | one syllable | [h]; silent at the end | weak; prefer הָ | a final ה is silent |
| ו | וָו (editor: וָו or וָיו) | one syllable | [v]; part of וֹ [o] and וּ [u] | yes, stretched | consonant vs vowel letter |
| ז | זַיִן | ZÁ-yin (מלעיל) | [z] | yes, stretched | — |
| ח | חֵית | one syllable | [χ] | yes, stretched | not pharyngeal |
| ט | טֵית | one syllable | [t] | no: טָ | homophone of ת |
| י | יוֹד (editor: יוֹד or the spoken "יוּד") | one syllable | [j]; part of ִי [i] and ֵי [e] | no: יָ | consonant vs vowel letter |
| כּ | כַּף | one syllable | [k] | no: כָּ | homophone of ק |
| כ ך | כַף; כַף סוֹפִית | one syllable; so-FIT | [χ] | yes, stretched | homophone of ח |
| ל | לָמֶד | LÁ-med (מלעיל) | [l] | yes, stretched | — |
| מ ם | מֵם; מֵם סוֹפִית | one syllable; so-FIT | [m] | yes, stretched | — |
| נ ן | נוּן; נוּן סוֹפִית | one syllable; so-FIT | [n] | yes, stretched | — |
| ס | סָמֶךְ | SÁ-mech (מלעיל) | [s] | yes, stretched | homophone of שׂ |
| ע | עַיִן | Á-yin (מלעיל) | ∅ / [ʔ] — carries the vowel | never | not pharyngeal |
| פּ | פֵּא | one syllable | [p] | no: פָּ | — |
| פ ף | פֵא; פֵא סוֹפִית | one syllable; so-FIT | [f] | yes, stretched | TTS may say [p] in a lone syllable |
| צ ץ | צָדִי; צָדִי סוֹפִית | TSÁ-di (מלעיל); so-FIT | [ts] | no: צָ | — |
| ק | קוֹף (editor: קוֹף or the spoken "קוּף") | one syllable | [k] | no: קָ | homophone of כּ |
| ר | רֵישׁ | one syllable | [ʁ] | yes, stretched | — |
| שׁ | שִׁין | one syllable | [ʃ] | yes, stretched | — |
| שׂ | שִׂין | one syllable | [s] | yes, stretched | TTS may say [ʃ] for an unpointed ש |
| ת | תָּו | one syllable | [t] | no: תָּ | homophone of ט |

**An open question for the editor (and maybe the owner):** the names יוֹד/יוּד, קוֹף/קוּף and וָו/וָיו. The normative and the spoken forms differ, and children hear the spoken forms in the gan. My preference is the form Israeli school materials use, once the editor confirms which form that is.

## 3. The vowel signs

| Sign(s) | Name (draft) | Sound | CV pilot | Notes |
|---|---|---|---|---|
| ָ ַ | קָמַץ, פַּתָּח | [a] | מָ, בָּ | one sound, two signs. Qamats qatan (כׇּל) is [o] and is not taught as a sign; the editor marks it in text (U+05C7 is never sent to a voice, `hebrew-notes.md` §3.2) |
| ִ ִי | חִירִיק (חָסֵר, מָלֵא) | [i] | מִ, לִי | — |
| ֹ וֹ | חוֹלָם (חָסֵר, מָלֵא) | [o] | מֹ, לוֹ | the holam dot vs the shin dot (שׁוֹ / שֹׁ) |
| וּ ֻ | שׁוּרוּק, קֻבּוּץ | [u] | מוּ, דֻּ | וּ vs וֹ: the dot's place |
| ֵ ֵי ֶ | צֵירֵי, סֶגּוֹל | [e] | מֵ, לֵי, מֶ | — |
| ְ | שְׁוָא | ∅ or [e], per word (§1.7) | יַלְ (silent), גְּלִי (start) | the hardest for a voice and for a child |
| ֲ ֱ ֳ | חֲטַף פַּתָּח, חֲטַף סֶגּוֹל, חֲטַף קָמַץ | [a], [e], [o] | חֲ, אֱ | U+05B3 is never sent to a voice |

Children learn the sounds first and the names later. The names are for the parent text and for Band C talk.

## 4. Stress of the course's words

The stress of every word in the syllabus lists (`syllabus.md` §3) goes into the spec table. A first list of מִלְעֵיל words, to confirm:
- יֶלֶד, לֶחֶם, גֶּשֶׁם, שֶׁמֶשׁ, דֶּלֶת, סֵפֶר, כֶּלֶב, מֶלֶךְ, מֶלַח, אֶצְבַּע, טַבַּעַת;
- אַבָּא, אִמָּא, סָבָא, סַבְתָּא, דֻּבִּי, פִּיצָה;
- עֵינַיִם, אוֹפַנַּיִם, מִשְׁקָפַיִם.

The rest are, as far as I know, מִלְּרַע (שַׁבָּת, אַתָּה, תָּמָר, שָׁלוֹם, גָּדוֹל, כַּדּוּר, חָתוּל, עוּגָה, טֶלֶפוֹן, צְפַרְדֵּעַ, כִּסֵּא…).

**לָמָּה** is said LÁ-ma in speech and la-MÁ normatively: an editor decision.

TTS voices often put the stress wrong in a word that stands alone. Each single-word clip must be checked for stress, and fixed through `say` (a stress mark or a respelling), never through the shown text.

## 5. The pilot (for the voice-and-sound-director to plan; the owner runs and pays)

Isolated sounds and CV units are hard for any TTS voice (`pronunciation-spec` §2). Before any batch, about 30 short clips should show whether the chosen voice can do this course:
- **5 vowels with מ:** מָ מִ מוֹ מוּ מֵ.
- **4 stops in a CV unit:** בָּ, תָּ, קוּ, פִּי.
- **5 continuants alone:** מְ, שְׁ, ס, ל, פ (f). Pass if there is no added vowel.
- **3 dagesh pairs:** בָּ / בָ (start of a clip), כָּ / כָ, פָּ / פָ.
- **2 shva words:** גְּלִידָה, יַלְדָּה.
- **5 letter names:** גִּימֶל, וָו, יוֹד, קוֹף, צָדִי (in the editor's chosen forms).
- **2 unit-by-unit words:** פִּי… צָה… פִּיצָה; כַּ… דּוּר… כַּדּוּר.
- **4 stress checks:** יֶלֶד, סֵפֶר, שַׁבָּת, חָתוּל.

What the voice director must find out (I do not assume it):
- whether the model reads pointed input better than unpointed;
- whether a lone pointed letter (מָ) is read as a syllable or as a letter name;
- whether any phonetic or stress control exists for Hebrew;
- what the cleanest way is to cut a held consonant.

**If the pilot fails** for isolated sounds or CV units, the owner's decision 4 applies. Either record about 120 short clips with a native-speaking adult (no voice cloning, no imitation of anyone), or teach stretchable sounds only inside words. Wrong sounds are never shipped.

**The listening check:** I cannot hear audio. For every clip I write what must be heard (the `check` column). The owner, or a native-speaking listener he chooses, listens from my list and marks `heard-ok` or `heard-wrong`. A lesson is not ready while any clip is unheard or `heard-wrong`.

**Rough size, for planning only** (the voice director computes the real count and cost; this is not a quote):
- **CV units:** about 27 letter forms × 5 vowels, minus impossible ones: about 120 short clips.
- **Letter names:** about 30.
- **Words:** the about 190 syllabus words × 2 clips (units and whole): about 380.
- **Lines:** stories, rhymes and instructions are counted later with the activity plan.

## 6. For the design-director: letter shapes for teaching

**The question:** are Heebo's letterforms right for teaching young children to read and write Hebrew print, and what is needed for script (כתב יד)? CLAUDE.md allows only Heebo and Secular One. A teaching font needs the owner's OK (the agent file and decision 1 of `docs/languages/README.md`).

**What I need the audit to show** (pictures at the course's reading sizes on a phone and a tablet, full nikud, line height 1.7):
1. **Confusable letters clearly different** at a glance, side by side and inside words:
   - ב/כ: the base of ב sticks out to the right, and that must be visible;
   - ד/ר: the corner;
   - ה/ח/ת: the gap in ה, which must not close at small sizes; ח is closed; ת has a foot;
   - ו/ז/ן/י: the head of ז; the length of ן below the line; י is short;
   - ס/ם: round versus square corners;
   - ע/צ, ג/נ, ט/מ.
2. **Descenders clearly below the line:** ך ן ף ץ ק.
3. **Nikud that a child can read:**
   - the dagesh visible inside בּ כּ פּ and inside the bowl of מּ;
   - the shin and sin dots on the right and the left;
   - holam on a letter versus the shin dot (שֹׁ, שׁוֹ), and וֹ versus וּ;
   - qamats versus patah;
   - segol versus kubuts versus tsere;
   - the hatafs, and the qamats qatan glyph (U+05C7).
4. **Print letterforms close to the school print model** (*דפוס*) of Israeli early-reader books: plain strokes, no stylised terminals, an even weight that is heavy enough.
5. **Secular One** is a display face, for titles. It should not be used for letters a child is learning, unless the audit shows it is as clear.

**If Heebo passes,** the course uses Heebo for print. **If it fails** on any point above, propose one open-licensed (OFL) teaching font, with the licence checked, shown beside Heebo, for the owner to approve.

**Script letters** (C-25–C-27):
- The course needs a **set of stroke paths** for the 22 script letters and 5 finals, drawn from real references (school script charts; `docs/agents/README.md`: drawings start from real references).
- Each letter needs its start point, stroke order and direction, as the Ministry asks: "by each letter's accepted direction", taught in direction groups (arch: ר ה ת ח ק ב; falling: י ו מ נ ן).
- The same paths draw the faces in H3 (match print ↔ script) and drive H4 (write a letter).
- A script **display font** is optional. If one is wanted, it too needs a licence check and the owner's OK.

**Print stroke paths** (B-24–B-26) are needed for the 22 letters and 5 finals as well. There is no single official print stroke order. The design-director proposes one (start at the top and on the right; the usual direction of Israeli teaching), and I review it letter by letter for teaching sense.

**What I will check in the pictures:** every confusable pair at the smallest tile size, every nikud case listed above, and that no letter or stroke is mirrored.
