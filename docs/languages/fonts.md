# Languages: fonts (design-director, 2026-11-03)

**Status:** a proposal for the owner. Nothing is added to the app yet: no font file in `app/assets/fonts/`, no change to `pubspec.yaml`. That comes with the milestone, after the owner chooses an option in §1.

Asked for by: owner's decision 1 (`README.md`, 2026-11-03: "add the Russian fonts if needed, but make sure it looks good UI-wise", and a Latin teaching font if needed), decisions 8, 13, 23 and 24 (`decisions-2026-11-03.md`), and the teachers' requirements in `russian/voice-brief.md` §8, `hebrew/voice-brief.md` §6 and `english/templates.md` S4.

## 1. The choice in one page

| Role | Font | Licence | Where it is used |
|---|---|---|---|
| App interface, Hebrew course print letters, all Hebrew around lessons | **Heebo** (already in the app) | OFL 1.1, no reserved name | unchanged; Heebo **700** for single-letter tiles, Heebo 500 for pointed words (existing rule: pointed text below 24 pt at most 500) |
| Titles | **Secular One** (already in the app) | OFL 1.1 | unchanged; **not** for letters a child is learning (§2, point 5) |
| English and Russian lesson text: words, letter tiles, syllables, sentences | **Nitznutz Letters**: our renamed build of **Andika 7.000** (SIL), with one change: the Cyrillic small а uses Andika's own two-storey a | OFL 1.1, with the reserved names "Andika" and "SIL", so the changed build must carry another name (§4) | Medium (500) for words, Bold (700) for single-letter tiles |
| Hebrew script letters (כתב יד) | **No font.** Stroke paths drawn by us (§5) | ours | trace, match print to script, write from memory |

**One family for English and Russian, as preferred.** Andika is the font SIL designed for beginning readers. It has everything the English teacher asked for (single-storey a and g, I l 1 all different) and nearly everything the Russian teacher asked for. It fails one Russian point as published: its Cyrillic а is single-storey (`russian_candidates.png`, last row), while Russian primers print the two-storey а (I checked a 1959 primer page: "Сама мама мыла Рому" is set with the two-storey а). Andika has no switch for this. The single-storey form is drawn into the Cyrillic glyph, and its `ss01` changes only the Latin a. The fix is to point U+0430 at Andika's own two-storey Latin `a` glyph. That is one line in the font's character map, and it is allowed under the OFL if the result is renamed.

**Option A, if the owner prefers not to ship a changed font:** Andika as published for English, and **Roboto** for Russian. Roboto is OFL with no reserved name, has the two-storey а, places the stress mark on every vowel, and is the same design as Heebo's own Latin letters. It is good but less child-friendly: tighter openings in с е з э, and less space between letters (`russian_options_a_b.png`). **My recommendation is option B (Nitznutz Letters).** Needs the owner: `docs/languages/fonts/russian_options_a_b.png`.

## 2. Heebo audit for teaching Hebrew letters (hebrew-language-teacher's points, `hebrew/voice-brief.md` §6)

Rendered by Flutter's own text engine (the app's shaping, at 2 pixels per point), in tiles of 64 pt (phone, the smallest answer tile, band C) and 80 pt (tablet), letters at 40 and 52 pt, pointed words at the caption sizes 20, 22, 24 and 28 pt with line height 1.7. Sheets: `hebrew_audit_phone.png`, `hebrew_audit_tablet.png`, `hebrew_alphabet_heebo.png`.

| # | Point | Result | What I saw |
|---|---|---|---|
| 1 | ב/כ | **Pass** | ב's base sticks out to the right at every size, down to 20 pt in words |
| 1 | ד/ר | **Pass** | ד's corner projects to the right; ר is round |
| 1 | ה/ח/ת | **Pass** | ה's gap stays open at 20 pt (Heebo 500); ח closed; ת's foot clear |
| 1 | ו/ז/ן/י | **Pass** | ז has a clear head; ן goes well below the line; י is short |
| 1 | ס/ם | **Pass** | round against square |
| 1 | ע/צ, ג/נ, ט/מ | **Pass** | distinct at 40 pt and in words at 20 pt |
| 2 | Descenders ך ן ף ץ ק | **Pass** | all five clearly below the baseline (teal line in the sheet), set against כ ו פ צ ר |
| 3 | Dagesh in בּ כּ פּ and in מּ | **Pass** | visible at 20 pt; in מּ the dot sits in the bowl |
| 3 | Shin dot right, sin dot left | **Pass** | |
| 3 | Holam against the shin dot | **Pass, with a note** | שֹׁ correctly shows two dots. שֹׂ shows the sin dot and the holam as two dots touching side by side; traditional typesetting merges them into one. In מֹשֶׁה and חֹשֶׁךְ the holam of the first letter and the shin dot sit close together across the two letters. Every common font does this. The teacher decides whether such words wait until later. |
| 3 | וֹ against וּ | **Pass** | the dot above the vav against the dot beside it |
| 3 | Qamats against patah | **Pass** | |
| 3 | Segol, kubuts, tsere | **Pass** | three dots in a triangle, three on a slant, two side by side |
| 3 | Hataf patah, hataf segol, hataf qamats | **Pass** | |
| 3 | Qamats qatan (U+05C7) | **Fail** | The glyph exists and is placed correctly, but its stem is only 30/2048 em longer than the qamats (less than 1 pt at 52 pt), so the two look the same. If the course must show qamats qatan as a different sign, the fix is a renamed Heebo build with a clearly longer stem (OFL, no reserved name; the owner's OK). If the course treats it the way most primers do (the same sign, learned by word), nothing changes. **The hebrew-language-teacher decides.** |
| 3 | Meteg (U+05BD) | Not in Heebo | The course does not use it; noted for completeness |
| 4 | Close to the school print model (דפוס) | **Pass** | Plain strokes, even weight, no stylised ends. It matches the block-print letters on Israeli first-grade worksheets I looked at. Heebo 700 is heavy enough for tiles; 500 for pointed words. |
| 5 | Secular One for learning letters | **Fail (as expected)** | A display face with heavy wedge shapes and its own forms (`hebrew_alphabet_heebo.png`, fourth row). It stays for titles only. |

**Verdict: keep Heebo for print letters** (decision 24 holds), with the two notes above for the teacher. No Hebrew teaching font is needed.

## 3. Cyrillic and Latin: the candidates and why Andika

Checked on the font files themselves (fontTools and HarfBuzz) and in Flutter renders: `russian_candidates.png`, `latin_candidates.png`, `russian_options_a_b.png`.

| Need | Andika 7 (published) | **Nitznutz Letters** (Andika with the two-storey а) | Roboto | Golos Text | Noto Sans | Inter |
|---|---|---|---|---|---|---|
| R1 all 33 letters, Ёё and Йй clear | yes | yes | yes | yes | yes | yes |
| R2 Russian б д л by default | yes; Serbian forms only with an `sr`/`mk` tag | same | yes | yes | yes | yes |
| R4 two-storey а in reading text | **no** (single-storey, no switch) | **yes** | yes | yes | yes | yes |
| R5 look-alikes apart | good | good | fair | fair | fair | fair |
| R6 made for beginning readers | **yes** (SIL literacy font) | **yes** | no (UI face) | no (public signage) | no | no (UI face) |
| R7 U+0301 on every vowel | **yes**, best placed | **yes** | yes | **no** (misplaced on ы) | yes | **no** (misplaced everywhere) |
| E single-storey a and g | **yes** (default) | **yes** | no | no | no | a only, through `cv11`, which also changes the Cyrillic а |
| E I, l and 1 all different | **yes** | **yes** | no (I = l) | no | no | with `cv05` and `cv08` |
| Weights 500 and 700 | yes (Regular, Medium, SemiBold, Bold) | Medium and Bold | yes | yes | yes | yes |

### Russian requirements (`russian/voice-brief.md` §8) against Nitznutz Letters

| # | Point | Result |
|---|---|---|
| 1 | All 33 letters, both cases; Ёё dots clear, Йй breve, Ыы Ьь Ъъ Ээ Щщ | **Pass** (`russian_alphabet.png`) |
| 2 | Russian forms, never Bulgarian or Serbian | **Pass, with a rule.** Andika has no Bulgarian forms. Its Serbian forms switch on when the text is tagged `sr` or `mk`, and Flutter does pass the tag to the shaper: the sheet shows б г д п т tagged `ru` and then tagged `sr`, and б changes. Every Russian text widget must carry `Locale('ru')`. |
| 3 | Upright only | **Pass, with a rule.** We ship only the upright files. Flutter makes a fake slant if a style asks for italic, so a test must forbid `FontStyle.italic` on this family. |
| 4 | Two-storey а in reading text | **Pass** after the one change (fails in Andika as published) |
| 5 | Look-alikes at child sizes | **Pass, with content rules** (`confusables_russian_latin_phone.png`): ш/щ tail, ц tail, и/й, е/ё, Н/И/П and ь/ъ/ы are all clear in 64 pt tiles. б against 6 and з against 3 are close, as in every font, so a digit never sits among letter options. Cyrillic В Н Р С у against Latin B H P C y are identical by design, so one item never mixes Russian and English tiles. |
| 6 | Readable for beginners | **Pass**: open counters, wide letters, generous spacing |
| 7 | U+0301 over every vowel, both cases | **Pass**: placed over the middle of each vowel, including ы and Ы |
| 8 | Harmony with Heebo and Secular One | **Pass** at 1.1 times the Hebrew size (§6) |
| 9 | Stroke data for tracing | to draw in the milestone, matching these letter shapes (§5) |

### English S4 (`english/templates.md`)
Single-storey a and g by default: **pass**. Clear b d p q: **pass**; they are mirror shapes in every font, which is a teaching matter, not a font fault. I l 1 all different: **pass**, unlike Roboto and Golos. Four-line guide: Andika's measures are x-height 0.498 em, cap height 0.713 em, ascender 0.781 em and descender −0.239 em; the guide lines sit at those heights (`latin_alphabet.png`, bottom). **The app must never switch on `ss01`**: it brings back the double-storey a and g.

## 4. Licences

| Font | Licence | Copyright and reserved names | What it allows us |
|---|---|---|---|
| Heebo 3.100 | SIL OFL 1.1 (`app/assets/fonts/OFL-Heebo.txt`) | The Heebo Project Authors; no reserved name | bundle as is; changes allowed |
| Secular One 1.002 | SIL OFL 1.1 (`OFL-SecularOne.txt`) | already checked when it was added | as is |
| Andika 7.000 (2 June 2025) | SIL OFL 1.1 (`OFL.txt` in the release, checked) | © 2004-2025 SIL Global, **reserved names "Andika" and "SIL"** | Bundling it in an app is allowed, keeping the copyright and licence text. Any changed version, including a subset, must not use the names "Andika" or "SIL" (OFL condition 3; OFL-FAQ 2.6 says subsetting counts as a change). SIL's separate permission covers only TypeTuner builds, not ours. So our build is named **Nitznutz Letters** and keeps the OFL, the SIL copyright and a FONTLOG note: "derived from Andika 7.000; U+0430 mapped to the two-storey a; subset; renamed under OFL condition 3". |
| Roboto 3.015 (option A only) | SIL OFL 1.1 | The Roboto Project Authors; **no reserved name** | bundle, subset or pin the width axis freely |
| Golos Text, Noto Sans, Inter | SIL OFL 1.1, no reserved names | not chosen (§3) | |
| Gveret Levin (Hebrew handwriting) | OFL 1.1 according to its GitHub page and Fontsource (not checked in the font file) | not chosen | It is one adult's personal hand, not the school script model (§5) |

Sources: software.sil.org/andika (features page and FONTLOG), github.com/silnrsi/font-andika (release v7.000), openfontlicense.org (OFL-FAQ 1.10, 1.20, 2.6 to 2.8), github.com/google/fonts (`ofl/roboto`, `ofl/golostext`, `ofl/notosans`, `ofl/inter`, `ofl/andika` OFL.txt files).

Pinned sources for the milestone build (SHA-256):
- `Andika-7.000.zip` (10,127,314 bytes, github.com/silnrsi/font-andika/releases/download/v7.000/): `88ba6ea41ef4a8e5214b090df8fa2983be1babe4843efaa99cdb6078b0e2c070`
- `Andika-Medium.ttf`: `dccaf8662b5883ff9c3a2a9290ba1793bf93d8237a03e65b22c2eef1a626e164`
- `Andika-Bold.ttf`: `3ad43a77a29ea060528be69a9e0e81c9dbbe8dff894a26ae1818d3c472393319`

## 5. Hebrew script letters (כתב יד): stroke paths drawn by us, not a font

What I recommend (not drawn yet):
1. **One source per letter: a stroke file.** For each of the 22 script letters and 5 finals there is an ordered list of strokes in the trace template's 100 by 100 box. Each stroke is a smooth centre line (cubic segments) with its start point and direction, and the letter has its direction group (arch: ר ה ת ח ק ב; falling: י ו מ נ ן, as the teacher listed). Written to `content/` by a generator script, with the sources in a comment at the top, the way the coins were made. **Done 2026-11-05:** `tools/make_letter_strokes.py` with `tools/strokes_hebrew.py` (and the English and Russian sets), format and teacher checks in `docs/languages/strokes.md`.
2. **Drawn from real references, never traced.** School script charts and the Ministry's handwriting guidance on direction ("by each letter's accepted direction"), plus first-grade workbooks. I looked at the cursive table on the Wikipedia "Cursive Hebrew" page and Israeli print-and-script worksheets for this proposal. The teacher reviews every letter for shape, start and direction before anything ships.
3. **The same paths draw everything:** the static script letter (a round-capped ink stroke about 9% of the box wide, in `ink`), the H3 match between print and script, H4 tracing (copy, then memory), and the stroke-by-stroke animation. No script font is needed. One source means the letter a child traces is exactly the letter shown in the match.
4. **Print stroke paths** (B-24 to B-26) are made the same way for the 22 print letters and 5 finals, drawn as centre lines that sit inside Heebo 700's shapes, so the traced letter matches the tile letter. I propose the order (start at the top and on the right) and the teacher reviews it. The same applies to the 52 English and 66 Russian letters, drawn to sit inside Nitznutz Letters (english S8, russian point 9).
5. **A script display font is not recommended.** Gveret Levin, the only well-known open one, is a personal adult handwriting, not the school model. If one is ever wanted, it needs a licence check and the owner's OK.

## 6. Layout and use rules (for the design system)

- **Size beside Hebrew:** target text is set at **1.1 times** the Hebrew size it sits with (Heebo's Hebrew letters are 0.575 em tall, Andika's x-height is 0.498 em). For example, a 22 pt caption with a 24 pt target word (`mixed_line_harmony.png`).
- **Weights:** Medium 500 for words and syllables, Bold 700 for a single-letter tile. No Regular in the child space: it is too light beside Heebo 500.
- **Line height:** 1.3 when the text stands alone, 1.7 when it shares a line with pointed Hebrew.
- **Direction:** every English or Russian run is LTR and isolated (`Directionality` LTR, or U+2066…U+2069 inside a Hebrew line). Tiles and slots in an English or Russian item run left to right; Hebrew course tiles run right to left.
- **Prompts never print the target word.** The target is heard (a sound button on the stage), or it is the picture. When a prompt must show a word (for example at hint level 2), the word sits **in its own chip on its own line, with no punctuation beside it**. Inline, the bidi rules put the Hebrew question mark against the English word ("?sun", see the sheet), which reads wrong to a child.
- **One script per item:** never mix Cyrillic and Latin tiles in one item, and never put a digit among look-alike letters (б/6, з/3).
- **Centring a letter in its tile:** Andika's line metrics are tall (ascent 2500, descent 800 on 2048), so letters sit slightly low in a tile. Single-letter tiles centre the glyph optically: x-height letters on the middle of the x-height, ascender letters on the middle of the cap height. The app-developer gets exact numbers with the template spec.
- **Locale:** `Locale('ru')` on every Russian text and `Locale('en')` on English, never `sr`, `mk` or `bg`.

## 7. Sizes

| File | Size |
|---|---|
| Heebo-Variable.ttf (in the app now) | 122,012 bytes |
| SecularOne-Regular.ttf (in the app now) | 83,916 bytes |
| **Option B:** NitznutzLetters-Medium.ttf and -Bold.ttf, subset to Basic Latin, Latin-1, Russian Cyrillic, combining marks U+0300, U+0301, U+0306, U+0308, punctuation and the isolate controls | about **95 KB each, about 190 KB in all** (measured on a scratch build) |
| Option B without subsetting | 809,072 and 817,872 bytes |
| Option A: Andika Medium and Bold as published (no subset allowed without renaming) | 809,032 + 817,832 bytes (1.6 MB) |
| Option A: Roboto, width pinned to 100 and subset the same way | about 126 KB (Roboto variable as published: 488,584 bytes) |

## 8. What changes in the app later (the milestone, not now)

1. **Build tool** `tools/make_letters_font.py` (fontTools, a dev tool only): it reads the pinned Andika 7.000 files (SHA-256 above), maps U+0430 to `a`, subsets, renames to "Nitznutz Letters" in every name record, writes `app/assets/fonts/NitznutzLetters-Medium.ttf`, `-Bold.ttf`, `OFL-NitznutzLetters.txt` (SIL's OFL with the SIL copyright line) and a short FONTLOG. fontTools is a new dev tool, so it needs the owner's OK (it is not an app package).
2. **pubspec.yaml:** a family `NitznutzLetters` with the weights 500 and 700. **CLAUDE.md** and **design-spec §9.4**: the fonts rule becomes "Heebo and Secular One for the interface; Nitznutz Letters only for English and Russian lesson text". This is the owner's call (he approved a Cyrillic and a Latin teaching font in principle on 2026-11-03).
3. **Tokens:** `font.families.target`, plus `type.kid.target` (word and letter tile sizes per band: the Heebo caption size times 1.1 for words; letter tiles at the band's numeral size in Bold), regenerated into `tokens.g.dart`.
4. **`AppText.target(...)` and a `TargetText` widget** (app-developer): LTR isolate, the language locale, the letters family, upright only, never `ss01`.
5. **Tests:** the font file checks (33 Russian letters in both cases, U+0301, U+0430 drawn two-storey, Latin a single-storey, no "Andika" or "SIL" in the name table); no italic on the family; every Russian text widget tagged `ru`; goldens for English and Russian letter and word tiles on the phone, the SE and both tablet shapes.
6. **Hebrew:** no font change. Letter tiles use Heebo 700. The two notes in §2 (qamats qatan, holam next to the shin dot) go to the hebrew-language-teacher.
7. **Stroke paths** (§5) for Hebrew print and script, English and Russian, each with a contact sheet and the teacher's review.

## 9. The sheets (`docs/languages/fonts/`)
| File | What it shows |
|---|---|
| `hebrew_alphabet_heebo.png` | the 27 letters in Heebo 500, 700 and 800 and in Secular One; the vowel signs on mem |
| `hebrew_audit_phone.png`, `hebrew_audit_tablet.png` | the audit of §2 at phone and tablet sizes |
| `russian_alphabet.png` | Nitznutz Letters Medium and Bold, the lowercase compared with Roboto, Golos Text and Noto Sans, stress marks, the `ru` against `sr` tag, primer syllables |
| `russian_candidates.png` | the five candidates on the teacher's letters, look-alikes and stress marks, and three beside Heebo |
| `russian_options_a_b.png` | option A (Roboto) against option B (Nitznutz Letters) against Andika as published |
| `latin_alphabet.png` | Nitznutz Letters a to z and A to Z, Heebo's Latin, the `ss01` warning, the four-line guide |
| `latin_candidates.png` | Andika against Inter (with its teaching features), Golos Text and Roboto |
| `confusables_russian_latin_phone.png` | look-alike letters in 64 pt tiles, words at 22 and 28 pt, the identical shapes across the two scripts |
| `mixed_line_harmony.png` | one Hebrew line with an English or Russian word: weight and size choices, the "?sun" bidi problem and the chip that solves it |
| `lesson_phone_english_words.png`, `lesson_phone_russian_words.png`, `lesson_phone_english_letters.png`, `lesson_phone_hebrew_letters.png` | lesson-like screens on the reference phone (852 by 393): stage, Nitzi, a Hebrew prompt, answer tiles below the stage |
| `lesson_tablet_landscape_english_words.png` | the same English item on the tablet in landscape (1180 by 820) |

The sheets were rendered by a scratch Flutter golden test that is not committed, kept outside the repo. The Hebrew prompts on the lesson sheets are samples only (`needs-editor`), and so are the English and Russian words (for their teachers).
