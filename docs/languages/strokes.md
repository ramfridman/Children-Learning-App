# Languages: the letter stroke data (F6) and the Hebrew pre-writing scenes (A-14)

Owner: design-director. Date: 2026-11-05. Status: **drawn and checked by script; `latin` is `teacher-checked` (english-language-teacher, 2026-11-05, §5.1); `hebrew-print`, `hebrew-script` and the A-14 scenes are `teacher-checked` (hebrew-language-teacher, 2026-11-05, §5.3); `cyrillic` is `teacher-checked` (russian-language-teacher, 2026-11-05, §5.2)** (§5). For the three language teachers, the app-developer (LS02, §4), the curriculum-expert and the qa-engineer.

Asked for by: frame.md §2.1 F6 and §2.3 LS02 (trace, copy, memory), §5.3 (every letter taught whole: "watch it drawn and trace it"), fonts.md §5 (our own stroke paths in the trace box, from school charts), hebrew/band-a-content.md HEB-A-14 (the nine stroke scenes waited for this), and the owner on 2026-11-04 (build the parts not yet built).

## 1. What there is

| Set | Forms | Strokes | Font it sits in | File | Sheet |
|---|---|---|---|---|---|
| `latin` (English) | 52: a to z and A to Z, print | 81 (2 dots) | Nitznutz Letters Bold | `content/languages/strokes/latin.json` | `docs/design/languages/strokes_latin.png` |
| `cyrillic` (Russian) | 66: 33 capitals and 33 small, print only (D13) | 187 (4 dots, 14 short marks) | Nitznutz Letters Bold | `content/languages/strokes/cyrillic.json` | `docs/design/languages/strokes_cyrillic.png` |
| `hebrew-print` | 27: 22 letters and 5 finals | 47 (4 short marks) | Heebo 700 | `content/languages/strokes/hebrew-print.json` | `docs/design/languages/strokes_hebrew-print.png` |
| `hebrew-script` | 27: 22 letters and 5 finals, by direction group | 32 (1 short mark) | none: these paths are the script letters | `content/languages/strokes/hebrew-script.json` | `docs/design/languages/strokes_hebrew-script.png` |
| A-14 scenes | 9 items, 10 pictures, 7 movers | 11 | | `content/languages/strokes/prewriting-heb-a14.json`, `content/languages/pictures/stroke-*.svg`, `mover-*.svg` | `docs/design/languages/strokes_scenes_a14.png` |

Generators: `tools/make_letter_strokes.py` (the format, the checks, the sheets, the font fit), with the paths and their references in `tools/strokes_latin.py`, `tools/strokes_cyrillic.py` and `tools/strokes_hebrew.py`; `tools/make_stroke_scenes.py` for A-14. Test: `python tools/test_letter_strokes.py` (regenerates every set and compares it with the files; counts; the trace format). Deterministic, standard library only; Chrome for the sheets and `--fit`.

## 2. The format (`nitznutz.strokes/1`)

It extends the existing `trace` activity (T04, `app/lib/play/trace_session.dart`): a stroke there is a list of whole points in a 100 × 100 box, y down, read from its first point to its last. Every stroke here carries exactly that list, so a form drops into `scene.strokes` unchanged; the rest is added.

**The file** (one per set): `schema`, `set`, `courses`, `review` (`needs-teacher`), `reviewer`, `box` (100), `ink` (9: the ink width in box units), `em` and `baseline` (how the font sits in the box), `guides` (the lines, as y in the box), `solidGuides`, `inset` (half a stem: how far a centre line sits inside its guide line), `direction` (ltr or rtl, of the course), `font` (family, weight, file; print sets only), `generator`, `count`, `forms`. The script set adds `groups`.

**A form:** `id` (`latin.a`, `latin.a.cap`, `cyrillic.yo.cap`, `hebrew-print.kaf-final`), `char`, `name`, `case` (latin, cyrillic) or `final` (hebrew), `group` (the formation family or direction group; hebrew-script also `groupProposed`), `sits` (its upper and lower guide line; `null` where a letter is not on one, like t's top), `strokes` in the order they are written.

**A stroke:**

| Field | What it is |
|---|---|
| `kind` | `line` (traced and checked as today); `dot` (the i, j, ё dots: a tap; two points one unit apart); `short` (a real stroke under the trace minimum of 25 units: Hebrew א's arm, ה's leg, ז's head, ץ's arm and י in script, the breve of Й й, the bars of Ю ю э, the top bars of Д д Л л, the flag of Ъ ъ, the leg of я and the left foot of Д д; checked by start and direction only) |
| `points` | the polyline: whole box units, 2 to 60 points (the trace schema's own limits), corners kept exactly |
| `start`, `end` | its first and last point (the green start dot; the direction check) |
| `moves` | the way it goes, in words: `down`, `up`, `left`, `right`, `down-left` … for a straight run, `cw` or `ccw` (as seen on the screen) for a curve, in order (B's second stroke: `right, cw, left, right, cw, left`). For the arrow, the voice ("down, then round") and the free-stroke check (§4) |
| `d` | the same stroke as a smooth path (M, L, C in box units), for drawing the model letter, the copy-mode model and the "watch it drawn" animation |
| `retrace` | true when the model goes back over its own line (n m h r b p u: down, then up the same stem; a and d and g and q: the bowl, then up the stem and down; B: back to the stem at the middle; the Cyrillic set has none, its bowls and arcs are strokes of their own) |
| `loop` | true when the model crosses itself (Hebrew script ע and ץ) |
| `startOk` | why the start rule does not apply (e: the model starts on its bar; d: magic c at 2 o'clock; script ט: from its inner curl; script ש: like an e) |

**The box.** Each set fixes where its letters sit, so every letter of a set is the same size and on the same lines:

| Set | em (box units per font em) | Lines (y in the box) |
|---|---|---|
| latin | 84, baseline 72 | ascender 6.4, cap 11.6, x 30, base 72, descender 93: the four lines of S8 |
| cyrillic | 76, baseline 76 | cap 21.4, x 38, base 76, descender 95 (the space above the cap line holds Ё's dots and Й's breve) |
| hebrew-print, hebrew-script | 92, baseline 76 | ascender (ל) 7, **top line 21.4** (letters hang from it), base 76, **basement 94.7** (ק ך ן ף ץ) |

The paths are written in font units (1000 to the em, y up from the baseline), so they can be read against the font's own measures; the generator moves them into the box and centres each letter on the box's middle.

## 3. How every form is checked

By script, on every run (`check_form` in `tools/make_letter_strokes.py`, and the test):
1. **Inside the box**: every centre line keeps 4 units from the edge, so the 9-unit ink never leaves it.
2. **Long enough to trace**: a `line` is at least 25 units (the validator's minimum); anything shorter must say `dot` or `short`.
3. **The start**: every stroke starts at its top (within a quarter of its height), the rule of all three school models; Hebrew script arch letters start on the left. Exceptions carry `startOk`.
4. **No crossing back unless the model does**: a stroke that crosses itself must say `loop`; one that runs back over itself (for 3 units or more) must say `retrace`; and a stroke marked either must really do it.
5. **On its lines**: the top and bottom of the letter's body are at its guide lines (within the inset and 4.5 units).
6. **In the font** (`--fit`, print sets): the letter is drawn in its font on a canvas the way the app draws a tile; each stroke must lie at least 90% inside the ink, and the strokes together must reach at least 90% of the ink (so no part of the letter is missing). Lowest results now: latin K 0.90 inside, M 0.93 covered; cyrillic М 0.93 inside, 0.94 covered; hebrew-print ף 0.98 inside, פ 0.96 covered.

The sheets show every form at 150 px: the guide lines, the faint font letter under it (print), each stroke in its own colour, a numbered dot where it starts and arrows the way it goes. I looked at all four sheets and at the large views of the letters that needed fixing (a, d, g, r, u, K, M; а, у, я, к, ж, Ж, Д, б).

## 4. For the app-developer (LS02)

1. **Schema**: `trace` allows 1 to 3 strokes; letters need up to 6 (Ё: 4 strokes and 2 dots; Д: 4). LS02's letter mode takes a form id (`stroke: "latin.a"`) and reads the stroke file of its course's pack, instead of points in the activity.
2. **Dots and short marks**: `dot` is a tap near its point (no path); `short` is checked by start and direction only (the validator's 25-unit minimum does not apply). Neither is scored as "off the path".
3. **Retrace**: a stroke with `retrace` covers its stem twice; the coverage check is unchanged, but the "traced from the wrong end" test must compare the start only, because such a stroke ends near where it began (b, h).
4. **Guide lines**: draw `guides` (solid for `solidGuides`, dashed otherwise) under the path, in the box.
5. **Drawing**: the model letter, copy mode's model and the "watch it drawn" animation use `d` with the ink width (9 units, round caps); the trace guide stays the dotted `points`.
6. **The free-stroke check** (copy, memory) compares the child's strokes in order with `points`, `start` and the first move; the tolerances are the qa-engineer's to tune.
7. **A-14 scenes** (`prewriting-heb-a14.json`): `scenePoints` drop into `scene.strokes` as they are. Two things are new: the trace box must draw `scene.background` (the picture, at the inner square's full size, under the dotted path; today `TraceSession` paints a white square), and a `mover` sprite (22 box units square) sits on the start dot, follows the finger and walks the path at hint 2, turning by its `orient`: `none`; `face` (drawn facing left, mirrored when the stroke ends to the right of its start); `tangent` (drawn head up, turned with the path); `tangent-upright` (turned with the path, mirrored instead of upside down). The door has no mover and shows `stroke-door-done` when its three strokes are done.
Golden to add: the trace box with a scene, a mover and a letter with guide lines, on the phone (the stage is 330 × 128, so the box is about 122 points) and both tablets.

## 5. What each teacher checks (all are checked: `latin`, `cyrillic`, hebrew-print, hebrew-script and A-14)

### 5.1 english-language-teacher (`strokes_latin.png`): **teacher-checked, 2026-11-05**

**The model.** The set follows **Handwriting Without Tears** (Learning Without Tears), a widely used early-years print model in US kindergartens and first grades, which fits the course's General American (D5): the Magic c letters (a d g q start with c), "big line down, up and over" (r n m h b p), the Frog Jump capitals (F E D P B R N M: big line down, frog jump back to the starting corner, finish the letter) and the Center Starters (C O Q G S A I T J: start at the top centre). Where the set departs from HWT it says so below, with the reason. Sources: the Learning Without Tears capital groups as given on the Davie County Schools HWT page (sites.google.com/davie.k12.nc.us/dcshwt); the HWT lowercase chart cited in `tools/strokes_latin.py`; Oak National Academy's KS1 handwriting lessons (thenational.academy, "Formation of c, a, d, o, g and q": these letters "start just below the x-height line" and go anticlockwise; "Capital letters C, G, O, Q, M, N, W and V"); Zaner-Bloser manuscript as summarised in school charts. **Evidence is thin in one place:** I could not open the official LWT chart PDFs (refused or binary only), so HWT's exact wording for capital T and Y is not confirmed; those two decisions rest on the reasons given.

**Decisions on the open questions:**
1. **O starts at 2 o'clock, like C, G and Q** (changed: O and Q started at 12 o'clock). HWT starts all four capitals at the top centre and Oak starts O at the line but C just below it, so the models do not give one answer; the syllabus does (§3.1, §5: the round letters start at "2 o'clock", anticlockwise). One start for every round letter, small and capital, is one cue to learn, and it is the cue that matters most for this course: from 2 o'clock the first move is up and to the left, so a child with the Hebrew clockwise habit (M-ENG-STROKE-CW) goes wrong on the first move and the direction check sees it at once; from 12 o'clock both ways start almost the same. Q's tail is unchanged.
2. **a d g q: one stroke, kept** (the bowl, then up the stem and back down, `retrace`). HWT ("magic c, up like a helicopter, back down") and Zaner-Bloser ("circle back, push up, pull down") write them without a lift. Two strokes would teach a gap between the bowl and the stem, the commonest fault in these letters.
3. **T: down first, then across** (changed: it was across, then down). HWT lists T among the Center Starters, which begin at the top centre: the down stroke does, the across stroke does not. Zaner-Bloser also pulls down first and slides across after. It matches the small t (stem, then bar) and the set's own capital rule (down first, then the lines across, as E F H I).
4. **Stroke counts, kept:** **E 4** (HWT Frog Jump: big line down, then the lines across the top, the middle and the bottom, each left to right); **N 2** (big line down, frog jump, then slide down and up in one stroke); **M 2** (big line down, frog jump, then slide down to the middle, up and down in one stroke); **Y 2** (the left arm to the middle, then the right arm on down the stem without a lift; HWT's exact Y not confirmed). Oak starts M and N on the base line (a pre-cursive habit); this set keeps HWT's top start, as for every other letter.

**The other items, checked and kept:** r n m h b p down, then back up the stem and over; k the stem, then in and out in one stroke; e from its bar; f the hook from its tip, then the bar; t the stem with its foot, then the bar; i j the line, then the dot; y two strokes; u down, round, up and back down; capitals start at the top; B D P R start their bowl at the top of the stem (Frog Jump). I looked at the regenerated sheet: every form starts where it should, goes the right way and sits on its lines. `--fit` after the change: lowest inside K 0.90, Q 0.91, R 0.91, a 0.93; lowest covered Q, M, W 0.93.

*The questions as the design-director asked them:*
- The round letters c a d g o q start at "2 o'clock" and go anticlockwise (syllabus §3.1). **Capital O starts at 12 o'clock** (the HWT habit for capitals); C and G start at 2 o'clock. Keep, or start O at 2 o'clock too?
- a d g q: one stroke, bowl first, then up the stem and back down (retrace), as in "magic c, up, down". Or the bowl and the stem as two strokes?
- r n m h b p: one stroke, down, then back up the stem and over (retrace). k: the stem, then one stroke in and out.
- e starts on its bar in the middle (left to right), then goes round anticlockwise.
- f: the hook first (from its tip, over and down), then the bar left to right. t: the stem with its foot, then the bar.
- i and j: the line, then the dot.
- y: two strokes (the short arm, then the long one down to the tail). u: down, round, up and down the stem.
- Capitals: down first, then the lines across, left to right; E has 4 strokes; B D P R start their bowl at the top of the stem; T is across, then down (HWT) rather than down first (Zaner-Bloser); Y is two strokes; N is one stem and then the diagonal and up; M is one stem, then diagonal, up, down.

### 5.2 russian-language-teacher (`strokes_cyrillic.png`): **teacher-checked, 2026-11-05**

**The model.** Russian pre-school print copybooks (прописи печатных букв, used before the cursive прописи of grade 1) write a print letter **element by element (по элементам)**, lifting the pen at every corner: **the sticks first, each from the top down; then the lines across, each from left to right; then the small parts (feet, tails, the flag of Ъ, the marks of Ё Й)**. A bowl or a half oval is its own element, drawn from where it leaves the stick. The set now follows that model; where the design-director's draft turned a corner without lifting (П Л Д Ц Ш Щ, the English way), it is now split as the Russian books do. Sources (full notes at the top of `tools/strokes_cyrillic.py`):
- **Copybook 1**: an unnamed published print copybook reproduced on deti-i-mama.ru ("Печатные буквы прописи для дошкольников", 2022-01-09): one capital a page, every element numbered with an arrow, 31 capitals (all but Ё and Ь). The main source.
- **Copybook 2**: "Печатные буквы" (reproduced on deti-i-mama.ru; pages for Г Ж К Л Н П С Х Ц Э), numbered arrows. It agrees with copybook 1 on every letter shown, except К's upper arm (copybook 2 draws it up from the middle).
- **Т. П. Воронина**, "Прописи для дошкольников. Пишем печатные буквы" (Феникс, ISBN 978-5-222-41554-2), her method note on proza.ru (2022-03-08): the parts of a print letter go top to bottom and left to right, one element at a time, as the physiology of a young hand needs; М written in one go, climbing up and down, is her example of the wrong way.

**Evidence is thin in three places.** (1) The copybooks number **capitals only**; the small letters with the capital's shape follow their capital, and а б е (own shapes) are kept as drawn. (2) Copybook 1 is the **only** numbered source I could read for Т И Й У Ф Ч Ъ Ю Я; the publisher is not named on the page. (3) Where copybook 1 departs from the general rule (И's diagonal goes up; Ъ's flag goes right to left; Ю's О goes clockwise), I say below what I chose and why.

**Decisions on the open questions:**
1. **Т: the stem first, then across** (changed). Copybook 1: 1 the stick, 2 the bar left to right. It is the Russian rule "палочка first" and matches Г Е (stick, then bars). т the same.
2. **Д д: 5 strokes, by the model, not fewer** (changed). The model writes Д in elements (copybook 1: the two sides top down, the base left to right, then each foot down: 5). Our font's Д has a top bar too, so: 1 the left leg (down), 2 the right side (down), 3 the top bar (left to right, a short mark), 4 the base left to right running on into the right foot, 5 the left foot (a short mark). The base and the right foot stay one stroke (a corner turned, still left to right and down) because the line check needs a traced line to reach the descender. A simpler order would teach a Д the Russian books do not show; the short marks are checked by start and direction only, so they cost the child little.
3. **И Й и й: the two sticks first, then the diagonal** (changed, 3 strokes, then the breve). Copybook 1: 1 the left stick, 2 the right stick, 3 the diagonal **from the foot of the left stick up to the top of the right one**. This is the one up-stroke in the set and it carries `startOk`; it keeps И apart from a mirrored N and is what the book shows. If the qa-engineer finds children start it from the top, the alternative (top right down to bottom left) is one line in the generator.
4. **Ж ж: the stick first, then four arms** (changed, 5 strokes). Both copybooks agree: 1 the stick, 2 the upper left arm in to the stick, 3 the lower left arm out from the stick, 4 the upper right arm in, 5 the lower right arm out. Every stroke goes down. К к follow the same pattern (copybook 1): the stick, the upper arm in, the lower arm out (changed from one stroke in and out).
5. **Б: kept** (stick, top bar, the bowl from the middle of the stick; copybook 1 exactly). **Я я: the bowl first, then the stick, then the leg** (changed: the stick was first). Copybook 1: 1 the bowl from the top of the stick round to the middle, 2 the stick, 3 the leg; it is also left to right (the bowl stands left of the stick). **Ю ю: kept** (stick, the short bar, then О from the top, anticlockwise like О). Copybook 1 draws Ю's О clockwise; I keep О's own direction, so the child learns one О. **Ф ф: the stick, then the two halves from the top** (changed): 2 the left half anticlockwise, 3 the right half clockwise, each from the top of the oval to its bottom (copybook 1).
6. **З з, В в: two strokes, no retrace** (changed). Copybook 1: В is 1 the stick, 2 the upper bowl, 3 the lower bowl; З is 1 the upper arc from its top left round to the middle, 2 the lower arc from the middle round to the bottom left. З's first stroke now starts a little nearer its tip (140°), so the start rule holds without an exception. The Cyrillic set has no `retrace` stroke now (р too, below). **Э э: kept** (the arc, then the bar left to right; both copybooks).
7. **The breve goes left to right: kept.** Copybook 1 numbers Й's mark last (4), drawn left to right. The dots of Ё ё: left, then right, after the letter (kept).

**The other items:**
- **М м: 4 strokes** (changed from 2): the left stick, the right stick, then the left diagonal down to the middle, then the right diagonal down to the middle (copybook 1; Воронина names the one-go М as wrong). The right diagonal starts a little inside the stick (x 740), so it lies in the ink (fit 0.93).
- **П п, Л л, Ц ц, Ш ш, Щ щ: the sticks first, then the line across** (changed). П: left stick, right stick, the top bar (both copybooks). Л: the hooked left leg, the right stick, the short top bar. Ц: both sticks, then the base running on into the tail (the books lift for the tail; kept as one for the line check, as Д). Ш: three sticks, then the base. Щ: three sticks, then the base and tail.
- **Ч ч: the right stick first, then the left part** down and round to it (changed; copybook 1).
- **У у: the long arm first** (top right down to the tail), then the short arm (changed; copybook 1).
- **Ъ ъ: the stick, the bowl, then the flag** (changed: the flag and stick were one stroke). Copybook 1 draws the flag last; its arrow goes from the stick to the left, but I draw the flag **left to right** (from its tip in to the stick), the rule for every line across in both books and in Воронина. Ы Ь: kept (stick, bowl; Ы then its right stick).
- **р: the stick, then the bowl from the top of the stick** (changed from one retrace stroke), like Р (copybook 1: stick, bowl).
- **А Г Е Ё Н О Р С Х: kept**, each as copybook 1 shows (Х: top left down first, then top right down; both copybooks). **а** (the two-storey а of the reading text: the hook and stem, then the bowl), **б** (from the tip of its flag) and **е** (from its bar): own shapes, no Russian numbered source found; kept as drawn.

**After the change:** 66 forms, 187 strokes (169 lines, 14 short marks, 4 dots), at most 6 a letter (Ё); every form passes the checks; `--fit`: lowest inside М 0.93, Б 0.94, Ч 0.95; lowest covered М 0.94, ё 0.95. I looked at the regenerated sheet and the large views of В Д Ж З И Ф Я р: every stroke starts where the model starts, goes its way and sits on its lines.

*The questions as the design-director asked them:*
- The order "stick first, then the lines across" (Г Е Ё Б Н П Т Ц Ш Щ). Т is across, then down, as in English: or the stem first?
- Д д: the left leg, then the top and the right side in one stroke, then the base with the right foot, then the left foot (a short mark). Four strokes are a lot for a child; is a simpler order wanted?
- И Й и й: one stroke (down, up the diagonal, down). Or the two sticks first and the diagonal last?
- Ж ж: left half, stick, right half (each half one stroke: in to the stick and out). Or the stick first?
- Б: stick, top bar, then the bowl from the middle of the stick. Я я: the stick first, then the bowl from its top round to the middle, then the leg. Ю ю: stick, bar (short), then О from the top. Ф ф: stick first, then the oval from the top.
- З з, В в: one stroke that comes back to the middle (retrace). Э э: the arc from the top left round to the bottom left, then the bar left to right.
- а is the two-storey а of the reading text (fonts.md): the hook and stem first, then the bowl from the stem; б starts at the tip of its flag.
- Ё ё and Й й: the dots and the breve are their own strokes, after the letter (frame F6). The breve goes left to right.
- Ч: the left part down and round to the right, then the right stick. Ц Щ: the left stick runs on into the base and the tail.

### 5.3 hebrew-language-teacher (`strokes_hebrew-print.png`, `strokes_hebrew-script.png`, `strokes_scenes_a14.png`): **teacher-checked, 2026-11-05** (all three)

**Sources** (the full list with quotes is in `tools/strokes_hebrew.py`). **Print:** the three charts the design-director used (gan-li ruler, the "עט לכתוב" poster, the "ראשית כתיבה" workbook); Shlomit Oltchik's print-letter lessons (shlomitoltchik.com, "לימוד אותיות הדפוס": "from the far to the near and from the ceiling to the floor", ר is the base letter, "walk backwards along the ceiling and go down in the lift"); walla! school, grade 1 "כתיבת האות ח" (the top first, left to right, then the two sides top to bottom). **Script:** the direction-group method of Haya Kushnir, occupational therapist ("נהנים לכתוב"; "נעים לכתוב - ראשית לימוד הכתב"), the method many Israeli first grades use: five groups with a picture word, נופל (an apple falls), קשת (a rainbow), כד (a jug's handle), אריה (a roaring lion), טיול (a hike in the hills); its workbook "פשוט לכתוב, part 2, קבוצת קשת" (Ditchi and Yehezkel, occupational therapists, Ohel Sarah, 2020), which prints the arch group as exactly ר ח ה ב ת ק, says "all of us start like a rainbow from the sky and reach the ground", draws ר's start dot at the top left, and says how ת ק ב ה are written; teachers' Wordwall activities (ס צ in כד; ל ע in אריה); et-lilmod ("most script letters are written from top to bottom, final forms included, except ש and ט"); Kushnir's gkushnir.com ("a letter ends as far as possible on its left side"). **Evidence is thin in two places:** I found no Ministry of Education document with letter-formation arrows for print or script (the Ministry's pages I found are about assessment and dictation), and, like the design-director, no numbered-arrow script chart; and the members of כד, אריה and טיול beyond ס צ ל ע were not found. Those parts rest on the reasons given, and say how sure I am.

**Print: kept as drawn** (no path changed; regenerated for the status). All five questions agree with the sources:
- **א** diagonal, then the right arm, then the left leg: Oltchik's cue "I climb onto the beam and Dad holds me from below" is the same order (the beam, what stands on it, what holds it from below). Fairly sure.
- **ט** the hook first, over and down the right side and round the base, then the left side down: Oltchik, "start the tet from the peacock's beak". Sure.
- **מ** the nose and top over to the right, down, the short base, then the left leg: kept, from the three charts and the set's top-start rule. Oltchik alone starts her (triangle-shaped) מ at the bottom left; one source against three, and a bottom start would be the only one in the print set. Fairly sure.
- **צ ץ** the long arm first: Oltchik, "start the tsadi from the bird's head, down through the body to its stand, then the wing from top to bottom"; ץ "the left line from top to bottom, then the wing, the short diagonal on the right". Sure.
- The general rules (top lines left to right, bases right to left, right side before left, a detached part after the main shape, ס clockwise from its top left) are confirmed by Oltchik and walla. ד stays two strokes (Oltchik draws it in one, "along the ceiling, back a little, and down": the same order, without a retrace for the trace check).

**Script: every form checked; four changed, groups rebuilt.**
- **ח and ת start at the top, not at the foot (changed).** The school method writes every arch letter "from the sky": ת "starts with the arch, then lifts the pencil and adds a line falling from the sky and a small line lying on the ground" (פשוט לכתוב), and ח "like ר, then the left line from top to bottom" (Oltchik, and the group rule). Both are now two strokes: the arch from the top left, as ר; then the left leg down (ת's ending in its foot to the left). Many adults write ח from the foot in one stroke, but that is a later habit, not the school's. Sure for ת, fairly sure for ח.
- **מ from the right: down, up, down (kept).** It is in the falling group (נופל) in every source, and its cue is "pick an apple, climb back up the tree, pick another": fall, climb, fall. Fairly sure.
- **ס clockwise from its top left, like print ס (changed).** Print ס is clockwise in every source; the school puts script ס in the כד group with צ, whose curves are the jug handle's (ɔ, clockwise); and a clockwise ס ends on its left, as Kushnir's rule asks. The anticlockwise habit belongs to the numerals and to English. Fairly sure.
- **ם clockwise from its top left (changed)**, for the same reasons (the same movement as print ם and as ס; it ended on the right before). Less sure: no source names ם.
- **ט starts at the tip of its inner curl and goes clockwise (changed):** down the right, round the base, up to end at the top left (`startOk`). et-lilmod names ט and ש as the two script letters that do not start at the top; it is the print ט's start (the beak) and direction; and it ends on the left. Medium: no source draws script ט with arrows.
- **ש** starts in the middle like an e (kept; et-lilmod's other exception). Fairly sure.
- **Kept as drawn** (shape, start and direction checked on the new sheet and at 380 px): א (the c-curve from the top, then the stick, right before left), ב (one stroke: the arch and at once the base, "without lifting"), ג ד ז (ג sweeps out along the line, ז ends at it, ד is the small 3), ה ק (the arch, then the leg; ק's leg down into the basement, as פשוט לכתוב), ו י ן נ (falling), כ ך פ ף, ל ע (the loops), צ ץ, ר.
- **Groups (changed):** the school's own five groups replace the proposal. **arch** (קשת) is exactly ר ה ת ח ק ב, the school's list; **כ ך פ are not in it**: they move the same way, but the school does not group them with the arch, and they share the jug-handle curve of ס and צ. **falling** (נופל) י ו מ נ ן. **jug** (כד): ס צ (named by the sources) and, proposed, כ ך פ ם ד, every one a curve clockwise from the top left. **lion** (אריה): ל ע (named) and, proposed, ף ץ (the loops). **hike** (טיול, "a hike in the hills", up and down): no member found; proposed א ג ז ט ש, the letters that change direction. `groupProposed` is false only for the letters the sources name (6 + 5 + 2 + 2 = 15 of 27). The three earlier names (round, wave, loop) are gone. The syllabus (C-26) should name the five groups; that is a proposal for the orchestrator.

**A-14:**
- **The arch from the left foot, up and over, down to the right: kept.** It is the school's arch: ר starts at the top left and "rolls like a rainbow to the ground", and the קשת group's picture is a rainbow rising on the left. Sure. `band-a-content.md` A-14.3 still says "from the right foot" and needs the same change.
- **The circle clockwise from the top (changed).** Every round Hebrew movement in both models goes clockwise (print ס; script ס ם and the jug curves; the arch itself), and A-14 prepares the Hebrew letters. The maths numerals (0 6 8 9) keep their own anticlockwise path: that is the numerals' model, and the two are taught in different lands; the curriculum-expert should know they now differ. Fairly sure. (`band-a-content.md` A-14.4 still says counter-clockwise.)
- **A left-to-right "across" item: yes, add one** (a proposal: a tenth item, a new picture from the design-director, e.g. walking along a shelf or a ceiling line). Half the print letters start with a top line drawn left to right (ר ב ד ה ו ז ח כ נ פ ק ת), the other half of the bases right to left; A-14 now practises only the second. Not added here (it needs a picture and a content change).
- **The door follows print ח (changed):** across the top left to right, then the right side down, then the left side down, each its own stroke (walla's ח: the top first, then the two sides; the right side before the left). Three separate strokes, not ח's turned corner, because at 3 to 4 the item checks the three basic strokes. On the sheet the door's start numbers 1 and 3 sit on the same corner, so only 2 and 3 show; in the app only the current stroke's dot is drawn.

**Checks:** `python tools/test_letter_strokes.py` passes (6 tests); `--fit` for hebrew-print: lowest inside ף 0.98, lowest covered פ and א 0.96 (unchanged). I looked at the three regenerated sheets and at the changed script forms at 380 px.

*The questions as the design-director asked them:*
**Print** follows three Israeli charts that agree (sources in `tools/strokes_hebrew.py`): every stroke starts at the top; **a line along the top goes left to right** (ב ד ה ו ז ח כ ך נ ן פ ף ק ר ת); a down stroke goes down; **a base goes right to left** (כ נ פ ע צ ש ט ת's foot), except ב, whose base sticks out to the right and goes left to right; a corner is turned without lifting (ב כ נ ר: across, then down); a detached part is its own stroke after the main shape (ה ק's leg, the hooks of פ ף, the left side of ח ט ם); ס is one stroke clockwise from its top-left; ש is right side and base, then the left side, then the middle. Please check: the order of א (diagonal, right arm, left leg), ט (the top hook first, over and down the right side and round the base, then the left side down), מ (the nose and top over to the right, down, the short base; then the left leg), צ ץ (the long arm first).
**Script** has no school chart with numbered arrows that I could find online; the shapes come from the Commons handwriting set, the yo-yoo chart and the "עיצוב בחינוך" sheet. Please check **every form** for shape, start and direction. In particular:
- Your two groups are kept: **arch** ר ה ת ח ק ב, **falling** י ו מ נ ן. I put כ ך פ in the arch group too (they move the same way), and proposed three more: **round** (anticlockwise, like a c: א's right part, ט ס ם ש), **wave** (two bowls, like a 3: ג ז ד צ), **loop** (ל ע ף ץ).
- ח and ת start at their foot (bottom left) and go up and over; the other arch letters start at the top left. Is that how the school teaches them?
- מ is written from the right: down, up, down (falling). Or from the left, like an N?
- ס starts at the top and goes anticlockwise (like the numeral 0 in the app); print ס goes clockwise. Should the script ס follow print?
- ש starts in the middle like an e; ג and ז are told apart by the bottom (ג sweeps out to the right along the line, ז ends at the line).
**A-14** (the pre-writing strokes): F6 answers the open question on the arch and the circle like this, and the data is set that way (one line each in `tools/make_stroke_scenes.py` to change):
- **The arch from the LEFT foot, up and over, down to the right** (clockwise). The brief's first guess was from the right. Both Hebrew models start their arch movement on the left: every top line in print is drawn left to right, and every arch letter in script starts on the left. **Changed from the brief; the teacher decides.**
- **The circle anticlockwise from the top**, as the brief and the app's numerals 0, 6, 8 and 9. Print ס is drawn clockwise, so the evidence is split; kept as the brief.
- **Across from right to left**, as the brief: it matches the bases of print (כ נ פ צ ש). The top lines of print go the other way, so an across stroke **left to right** is the other half of print; a second across item may be worth adding.
- The door: down (right side), across right to left, down (left side), as the brief. Print ח, which is the same shape, starts with its top **left to right**, then the right side, then the left side; should the door follow ח?

## 6. The A-14 scenes

Each item (`prewriting-heb-a14.json`): the picture under the trace box, the mover, its `orient`, the guide mode (`full` for .1 to .4, `start` for .5 to .9) and the strokes. Pictures in the approved style, reusing the set's car, boat, rabbit, ball and fish; new drawings: the cloud, the tulip and the daisy, the house, the road, the jetty, the hill, the fence, the pond, the stone, the door wall and the finished door, the raindrop and the ladybird (references in the generator). The path's band is kept clear and pale, so the dotted guide and the green start dot read on it; I looked at every scene at 200 px and at 122 px (the phone's trace box).

| Item | Stroke | Picture | Mover | Orient |
|---|---|---|---|---|
| A-14.1 | down | `stroke-rain-tulip` | `mover-raindrop` | none |
| A-14.2 | across, right to left | `stroke-road-house` | `mover-car` | face |
| A-14.3 | arch | `stroke-hill` | `mover-rabbit` | face |
| A-14.4 | circle | `stroke-pond` | `mover-ladybird` | tangent |
| A-14.5 | down, start dot | `stroke-rain-daisy` | `mover-raindrop` | none |
| A-14.6 | across, start dot | `stroke-jetty` | `mover-boat` | face |
| A-14.7 | arch, start dot | `stroke-fence` | `mover-ball` | none |
| A-14.8 | circle, start dot | `stroke-stone` | `mover-fish` | tangent-upright |
| A-14.9 | the door: across left to right, down (right side), down (left side) | `stroke-door` (then `stroke-door-done`) | none | |
