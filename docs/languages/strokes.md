# Languages: the letter stroke data (F6) and the Hebrew pre-writing scenes (A-14)

Owner: design-director. Date: 2026-11-05. Status: **drawn and checked by script; every set is `needs-teacher`** (§5). For the three language teachers, the app-developer (LS02, §4), the curriculum-expert and the qa-engineer.

Asked for by: frame.md §2.1 F6 and §2.3 LS02 (trace, copy, memory), §5.3 (every letter taught whole: "watch it drawn and trace it"), fonts.md §5 (our own stroke paths in the trace box, from school charts), hebrew/band-a-content.md HEB-A-14 (the nine stroke scenes waited for this), and the owner on 2026-11-04 (build the parts not yet built).

## 1. What there is

| Set | Forms | Strokes | Font it sits in | File | Sheet |
|---|---|---|---|---|---|
| `latin` (English) | 52: a to z and A to Z, print | 81 (2 dots) | Nitznutz Letters Bold | `content/languages/strokes/latin.json` | `docs/design/languages/strokes_latin.png` |
| `cyrillic` (Russian) | 66: 33 capitals and 33 small, print only (D13) | 148 (4 dots, 8 short marks) | Nitznutz Letters Bold | `content/languages/strokes/cyrillic.json` | `docs/design/languages/strokes_cyrillic.png` |
| `hebrew-print` | 27: 22 letters and 5 finals | 47 (4 short marks) | Heebo 700 | `content/languages/strokes/hebrew-print.json` | `docs/design/languages/strokes_hebrew-print.png` |
| `hebrew-script` | 27: 22 letters and 5 finals, by direction group | 30 (1 short mark) | none: these paths are the script letters | `content/languages/strokes/hebrew-script.json` | `docs/design/languages/strokes_hebrew-script.png` |
| A-14 scenes | 9 items, 10 pictures, 7 movers | 11 | | `content/languages/strokes/prewriting-heb-a14.json`, `content/languages/pictures/stroke-*.svg`, `mover-*.svg` | `docs/design/languages/strokes_scenes_a14.png` |

Generators: `tools/make_letter_strokes.py` (the format, the checks, the sheets, the font fit), with the paths and their references in `tools/strokes_latin.py`, `tools/strokes_cyrillic.py` and `tools/strokes_hebrew.py`; `tools/make_stroke_scenes.py` for A-14. Test: `python tools/test_letter_strokes.py` (regenerates every set and compares it with the files; counts; the trace format). Deterministic, standard library only; Chrome for the sheets and `--fit`.

## 2. The format (`nitznutz.strokes/1`)

It extends the existing `trace` activity (T04, `app/lib/play/trace_session.dart`): a stroke there is a list of whole points in a 100 × 100 box, y down, read from its first point to its last. Every stroke here carries exactly that list, so a form drops into `scene.strokes` unchanged; the rest is added.

**The file** (one per set): `schema`, `set`, `courses`, `review` (`needs-teacher`), `reviewer`, `box` (100), `ink` (9: the ink width in box units), `em` and `baseline` (how the font sits in the box), `guides` (the lines, as y in the box), `solidGuides`, `inset` (half a stem: how far a centre line sits inside its guide line), `direction` (ltr or rtl, of the course), `font` (family, weight, file; print sets only), `generator`, `count`, `forms`. The script set adds `groups`.

**A form:** `id` (`latin.a`, `latin.a.cap`, `cyrillic.yo.cap`, `hebrew-print.kaf-final`), `char`, `name`, `case` (latin, cyrillic) or `final` (hebrew), `group` (the formation family or direction group; hebrew-script also `groupProposed`), `sits` (its upper and lower guide line; `null` where a letter is not on one, like t's top), `strokes` in the order they are written.

**A stroke:**

| Field | What it is |
|---|---|
| `kind` | `line` (traced and checked as today); `dot` (the i, j, ё dots: a tap; two points one unit apart); `short` (a real stroke under the trace minimum of 25 units: Hebrew א's arm, ה's leg, ז's head, ץ's arm and י in script, the breve of й, the bars of Ю ю э, the leg of я and the left foot of Д д; checked by start and direction only) |
| `points` | the polyline: whole box units, 2 to 60 points (the trace schema's own limits), corners kept exactly |
| `start`, `end` | its first and last point (the green start dot; the direction check) |
| `moves` | the way it goes, in words: `down`, `up`, `left`, `right`, `down-left` … for a straight run, `cw` or `ccw` (as seen on the screen) for a curve, in order (B's second stroke: `right, cw, left, right, cw, left`). For the arrow, the voice ("down, then round") and the free-stroke check (§4) |
| `d` | the same stroke as a smooth path (M, L, C in box units), for drawing the model letter, the copy-mode model and the "watch it drawn" animation |
| `retrace` | true when the model goes back over its own line (n m h r b p u: down, then up the same stem; a and d and g and q: the bowl, then up the stem and down; B В в З з: back to the stem at the middle) |
| `loop` | true when the model crosses itself (Hebrew script ע and ץ) |
| `startOk` | why the start rule does not apply (e: the model starts on its bar; d: magic c at 2 o'clock; script ח ת: the arch from the foot; script ש: like an e) |

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
6. **In the font** (`--fit`, print sets): the letter is drawn in its font on a canvas the way the app draws a tile; each stroke must lie at least 90% inside the ink, and the strokes together must reach at least 90% of the ink (so no part of the letter is missing). Lowest results now: latin K 0.90 inside, M 0.93 covered; cyrillic М 0.93; hebrew-print ף 0.98 inside, פ 0.96 covered.

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

## 5. What each teacher checks (all three sets are `needs-teacher`)

### 5.1 english-language-teacher (`strokes_latin.png`)
- The round letters c a d g o q start at "2 o'clock" and go anticlockwise (syllabus §3.1). **Capital O starts at 12 o'clock** (the HWT habit for capitals); C and G start at 2 o'clock. Keep, or start O at 2 o'clock too?
- a d g q: one stroke, bowl first, then up the stem and back down (retrace), as in "magic c, up, down". Or the bowl and the stem as two strokes?
- r n m h b p: one stroke, down, then back up the stem and over (retrace). k: the stem, then one stroke in and out.
- e starts on its bar in the middle (left to right), then goes round anticlockwise.
- f: the hook first (from its tip, over and down), then the bar left to right. t: the stem with its foot, then the bar.
- i and j: the line, then the dot.
- y: two strokes (the short arm, then the long one down to the tail). u: down, round, up and down the stem.
- Capitals: down first, then the lines across, left to right; E has 4 strokes; B D P R start their bowl at the top of the stem; T is across, then down (HWT) rather than down first (Zaner-Bloser); Y is two strokes; N is one stem and then the diagonal and up; M is one stem, then diagonal, up, down.

### 5.2 russian-language-teacher (`strokes_cyrillic.png`)
- The order "stick first, then the lines across" (Г Е Ё Б Н П Т Ц Ш Щ). Т is across, then down, as in English: or the stem first?
- Д д: the left leg, then the top and the right side in one stroke, then the base with the right foot, then the left foot (a short mark). Four strokes are a lot for a child; is a simpler order wanted?
- И Й и й: one stroke (down, up the diagonal, down). Or the two sticks first and the diagonal last?
- Ж ж: left half, stick, right half (each half one stroke: in to the stick and out). Or the stick first?
- Б: stick, top bar, then the bowl from the middle of the stick. Я я: the stick first, then the bowl from its top round to the middle, then the leg. Ю ю: stick, bar (short), then О from the top. Ф ф: stick first, then the oval from the top.
- З з, В в: one stroke that comes back to the middle (retrace). Э э: the arc from the top left round to the bottom left, then the bar left to right.
- а is the two-storey а of the reading text (fonts.md): the hook and stem first, then the bowl from the stem; б starts at the tip of its flag.
- Ё ё and Й й: the dots and the breve are their own strokes, after the letter (frame F6). The breve goes left to right.
- Ч: the left part down and round to the right, then the right stick. Ц Щ: the left stick runs on into the base and the tail.

### 5.3 hebrew-language-teacher (`strokes_hebrew-print.png`, `strokes_hebrew-script.png`, `strokes_scenes_a14.png`)
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
| A-14.9 | the door: down, across, down | `stroke-door` (then `stroke-door-done`) | none | |
