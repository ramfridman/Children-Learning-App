# B-29 steps 5 and 6: the parent's age settings and presentation by stage

Owner: design-director. Date: 2026-11-08. Status: **spec for the app-developer** (steps 5 to 9), parent texts for the
hebrew-text-editor. Plan: `docs/milestones/B29.md` (approved 2026-11-06; birth month and year synced to the family's server,
owner 2026-11-08). Research: `docs/research/age-fit-design.md` (§5.4 the six defects, §5.1 the stages). Code read on
`b29-steps5-9`: `app/lib/parent/child_form.dart`, `parent_area.dart`, `language_pages.dart`, `look_settings.dart`,
`app/lib/engine/age.dart`, `presentation.dart`, `app/lib/data/profile_age.dart`, `app/lib/app/age_providers.dart`,
`app/lib/child/activity_shell.dart`, `app/lib/play/activity_frame.dart`, `lesson_controller.dart`, `app/lib/child/home_screen.dart`,
`design/tokens.json`.

Mockups: `docs/design/b29/*.png`, made by `docs/design/b29/make_b29_mockups.py` (headless Chrome, Heebo from
`app/assets/fonts`, the app's own SVGs and stage pictures cut from the goldens). Red dashed lines and English labels are for the
team, never in the app.

## 0. In one page

- **Step 5, the parent area.** The age chips (3 to 8) go. In their place one shared widget, **AgeFields**: the month and year of
  birth (optional; two grids of chips) and the **school stage** (required; six chips in two rows, gan and school). The year
  suggests the stage; the parent confirms it. The same widget is the form's section and the child's own "age and school stage"
  page. The child's settings page gets two cards: **age and school stage** (a summary and "change") and **screens** (the look:
  by age or one of three age groups, a letter like the language level; and the question captions: by school stage, show, hide,
  kept on this device). The parent area's top shows a **September card** per child ("moving up to grade 1?") and, for a child
  made before B-29, an **"add the age" card**. Nothing changes for the child until the parent confirms, and then only from the
  next session.
- **Step 6, presentation by stage.** One table of numbers per stage P1 to P4 (§6.2): choice cap, tile, gap and hit area,
  numeral and caption size, idle ladder, motion and celebrations, items per activity, session length, hint pace. The six
  defects of `age-fit-design.md` §5.4 are fixed by it: the caption keeps its stage size, captions follow the reading setting
  (a speaker bubble when hidden), phone hit areas reach 2 cm for the youngest, the home signs follow §9.4, idle prompts speak
  and point, and the oldest get older pacing.
- **Goldens:** 4 stages × 4 boards for the activity screen and for the home map (32), the idle prompt (2), and 6 parent pages.
- **The build list** for steps 5 to 9 is §7, with the owner's 2026-11-08 change (birth month and year synced) folded in.

## 1. Step 5: where things live

| Place | What is new | Mockup |
|---|---|---|
| Child form (`child_form.dart`, setup and "add a child") | AgeFields replaces the "גיל" chips, between the name and the avatar | `b29/p5_form_phone.png`, `p5_form_phoneSE.png`, `p5_form_tabletPortrait.png` |
| Child's settings page (`ChildSettingsScreen`, `language_pages.dart`) | Two cards at the top: "גיל ושלב לימודים" (summary + "שינוי") and "התאמת המסכים" (the look, the captions); the Languages and time cards follow as today | `b29/p5_settings_phone.png`, `p5_settings_tabletLandscape.png` |
| Age page (new, pushed from "שינוי") | AgeFields with "שמירה" and "ביטול", and the note that the change starts at the next session | `b29/p5_age_page_phone.png` |
| Parent area home (`parent_area.dart`) | The September card and the "add the age" card, above the alerts card; the child row's "שפות" button becomes "הגדרות" (it opens the whole settings page now) | `b29/p5_area_cards_phone.png` |

The parent's visual language is unchanged: Heebo, no nikud, cream background `color.core.parentBg`, white cards (radius
`radius.md` 16, border `border.thin` 2 in `color.core.hairline`, padding `space.4` 16, gap 16), `night` app bar, `type.parent.*`.
Phones are landscape (852 × 393 and 667 × 375), so every parent page scrolls; the form keeps its 520 column, the settings and age
pages their 640 column, centred on tablets.

## 2. Step 5: AgeFields (one widget, two places)

### 2.1 Month and year of birth (optional)

- A label "חודש ושנת לידה" (`parent.h3`) with "(לא חובה)" in `parent.small` beside it, and one help line under it (`parent.small`,
  `inkSoft`): saved for the family so a new device knows it, never shared (§5 texts).
- **Year:** a grid of **4 columns** (`space.2` 8 gap), 8 chips: `now.year − 9` to `now.year − 2`, in reading order (the earliest at
  the start, the right). Digits are LTR inside the chip.
- **Month:** a grid of **4 columns**, 3 rows (the quarters): ינואר to אפריל, מאי to אוגוסט, ספטמבר to דצמבר, in reading order.
- Why grids and not a wrap: a wrap broke the years 6 + 2 and the months into ragged rows on the phone (first render); four equal
  columns read as a calendar and every cell is at least 113 pt wide on the phone SE.
- A small quiet button "ניקוי" (36 high) under the months, only while something is chosen. A month without a year (or the
  reverse) is not saved: the form says so under Save ("כדי לשמור חודש ושנה צריך לבחור את שניהם", needs-editor).
- No month needs disabling: the latest year is `now.year − 2`, so no choice is in the future; `BirthMonth.tryCreate` stays the check.

### 2.2 School stage (required)

- A label "שלב הלימודים השנה" and a help line (it sets where each island starts; then the child moves by what they know).
- A grid of **3 columns**, 2 rows: the three gan years in the first row, grades 1 to 3 in the second. Labels in §5.
- **Suggested from the year** (the Israeli cohort is the calendar birth year; `age-fit-teaching.md` §3): with
  `schoolYearStart = now.month >= 9 ? now.year : now.year − 1` and `k = schoolYearStart − birthYear − 3`, the stage is
  `SchoolStage.values[k.clamp(0, 5)]`. Born 2021, today November 2026: k = 2, gan hova.
  - **In the form**, the suggestion selects the chip until the parent taps a stage chip; from then on the parent's choice stays
    even if the year changes. A sea-tint note (`color.core.seaTint`, radius 12, an info glyph in `sea`) says what was suggested
    and that it can be changed (a child who stays a second year in gan hova).
  - **On the age page**, the suggestion never moves the confirmed stage. If the year suggests another stage, the note says
    "לפי שנת הלידה: {suggested}. כרגע: {current}." and the parent decides.
- The form's Save stays disabled until a stage is chosen; the line under the buttons says why (needs-editor).
- Saving a stage whose band is **lower** than the child's stored band (a child who has played) shows one line in the note before
  Save: the screens will look younger, the lessons and progress do not change (needs-editor). It is not a dialog.

### 2.3 Chips (all of the parent area's new chips)

- 40 high (as `ChoiceChip` in today's parent goldens), radius `radius.xs` 8, border 1.5 `ink`, label `type.parent.button` size 15
  weight 700. Selected: fill `brand.sea`, white label, **and a check glyph** at the start (never colour alone, §9.2).
- At text scale 1.3 a label may wrap to two lines inside its cell (min height 40, the cell grows; no clipping, no ellipsis). The
  longest, "גן טרום־טרום חובה", wraps on the phone SE.
- Semantics: "שנת לידה 2021, נבחרה", "שלב הלימודים: גן חובה, נבחר"; the grids are a radio group each.

## 3. Step 5: the child's settings page

### 3.1 Card "גיל ושלב לימודים"

Two rows (title `parent.h3`, value `parent.body`): the school stage, and the month and year ("מרץ 2021", or "לא הוזנו"); then one
quiet button "שינוי" that pushes the age page. Values only, no edit controls on this page: the pickers are long, and on a 393-pt
phone they would push the screens card three screens down (first render, `p5_settings_phone.png` before this change).

### 3.2 Card "התאמת המסכים"

**The look** ("המראה במסכים"): the same pattern as a language's "התאמה לגיל" row (`_BandRow`), so the parent meets one control in
two places. Chips: "לפי הגיל" (default), "גילאי 3 עד 4", "גילאי 5 עד 6", "גילאי 7 עד 8" (the existing `langBandA/B/C` texts). A status
line under the chips in `parent.small` weight 700: "עכשיו: מראה של גילאי {range}", the range of the stage the child sees now.
Saved at once in `FamilyLooks` (letter A, B or C, key `looks`, synced; built in step 4) and synced with `syncRunner.now(force: true)`.

**The captions** ("כתוביות לשאלות"): chips "לפי שלב הלימודים" (default), "להציג", "להסתיר", a help line (Nitzi always reads the
question; numbers and the child's name always show; this setting is kept on this device only), and a status line "עכשיו: מוצגות
(גן חובה)" or "עכשיו: מוסתרות (גן טרום חובה)". Saved at once in the device's settings under `reading_<childId>`
(`auto`, `on`, `off`). It does not sync (owner, ask c).

The default by school stage: **gan3 and gan4 hide**, **gan hova to grade 3 show**. A child with no confirmed stage uses the middle of
its band (A hides, B and C show). This matches research open question 3 (hidden up to about 4;11) in school-stage terms.

Nikud stays full for every stage. Partial nikud for grade 3 is not built (no text rule or content for it exists); it is a later
item, not a chip now.

### 3.3 Which look a child sees (one rule, for lands and courses)

```
PresentationStage effectiveStage(ChildAge age, {int? lookBand, int? courseBand}) {
  final int? band = courseBand ?? lookBand;          // a course's own choice wins inside that course
  if (band == null) return age.presentation;          // by age (or the middle of the band without a birth month)
  return switch (band) {
    0 => age.presentation == PresentationStage.p1 ? PresentationStage.p1 : PresentationStage.p2,
    1 => PresentationStage.p3,
    _ => PresentationStage.p4,
  };
}
```

A letter clamps the stage into its band (A is P1 or P2, B is P3, C is P4), so "גילאי 3 עד 4" never makes a 3;2-year-old's screens
older. The course's **content** band (letters under Band A, the literacy strand) stays as today: the course choice, else the band
from the school stage. The look letter changes only the look. This is a small clarification of B29.md §3.3 ("one look per
child, whatever the subject"); I flag it for the orchestrator, not the owner.

## 4. Step 5: the parent area's cards

### 4.1 The September card (one per child)

- **When:** from 1 September of school year Y (local date), for a child with a confirmed stage below grade 3 whose stage was last
  confirmed for a school year before Y. The device keeps `stage_year_<childId>` = the school year of the last confirmation
  (form save, the age page's save, the card's answer). When a pull brings a different stage, the device sets it to the current
  school year (someone confirmed on another device).
- **Look:** a white card with a 2 pt `sea` border, a calendar glyph (`night`, a `spark` dot), title "שנת לימודים חדשה", the
  question "{child} עולה ל{next}?", one help line, and three buttons: "כן, {next}" (filled), "להשאיר ב{current}" (quiet), "שלב
  אחר" (quiet, opens the age page). On the phone the three buttons wrap to two rows only at text scale 1.3.
- **Never anywhere else:** no badge on the child space, no notification, no change until the parent answers. "להשאיר" also sets
  `stage_year`. The card stays until answered.
- A second device: if the parent chose "להשאיר" on the phone, the tablet asks once more (nothing synced says a year). I recommend
  accepting that (§8, O3).

### 4.2 The "add the age" card (children made before B-29)

For a profile with no confirmed stage: title "התאמה לגיל: {child}", one body line, "להוספה" (opens the age page, the stage
pre-selected from the band's middle until the parent taps one) and "לא עכשיו" (hides the card on this device until the next
1 September).

## 5. Step 5: parent texts (adult, no nikud; every one `"review": "needs-editor"`)

The parent area says "הילד" (generic masculine), as today (`docs/agents/hebrew-notes.md` §8). Per the owner's 2026-11-08 change,
no text says the month and year stay on this phone; they are saved for the family and never shared. Only the captions setting
says "this device".

| Key (proposed) | Draft |
|---|---|
| `ageBirthTitle` | חודש ושנת לידה |
| `ageBirthOptional` | (לא חובה) |
| `ageBirthHelp` | נשמר בחשבון המשפחה כדי שמכשיר חדש יכיר אותו, ולא נמסר לאף אחד. בעזרתו המסכים מתאימים לגיל. |
| `ageBirthYear` / `ageBirthMonth` | שנה / חודש |
| `months[12]` | ינואר … דצמבר |
| `ageBirthClear` | ניקוי |
| `ageBirthBoth` | כדי לשמור חודש ושנה צריך לבחור את שניהם |
| `ageBirthNone` | לא הוזנו |
| `ageStageTitle` | שלב הלימודים השנה |
| `ageStageHelp` | קובע מאיפה מתחילים בכל אי. משם הילד מתקדם לפי מה שהוא יודע. |
| `stageGan3` … `stageGrade3` | גן טרום־טרום חובה · גן טרום חובה · גן חובה · כיתה א׳ · כיתה ב׳ · כיתה ג׳ ומעלה |
| `ageStageSuggested` | לפי שנת הלידה הצענו {stage}. אפשר לשנות, למשל אם הילד נשאר שנה נוספת בגן חובה. |
| `ageStageDiffers` | לפי שנת הלידה: {suggested}. כרגע: {current}. |
| `ageStageNeeded` | כדי לשמור צריך לבחור את שלב הלימודים |
| `ageStageYounger` | המסכים יותאמו לגיל צעיר יותר. השיעורים וההתקדמות לא משתנים. |
| `ageChangeNote` | השינוי יחול מהפעם הבאה שהילד ישחק. השיעורים שכבר נלמדו וההתקדמות נשארים. |
| `agePageTitle` | גיל ושלב לימודים: {child} |
| `ageCardTitle` | גיל ושלב לימודים |
| `ageStageRow` | שלב הלימודים |
| `ageChange` | שינוי |
| `screensTitle` | התאמת המסכים |
| `lookTitle` | המראה במסכים |
| `lookHelp` | ברירת המחדל לפי הגיל. אפשר לבחור מראה של קבוצת גיל אחרת: כמה תשובות יש על המסך, גודל הכתב ואורך החגיגות. השיעורים עצמם לא משתנים. |
| `lookAuto` | לפי הגיל |
| `lookNow` | עכשיו: מראה של {range} |
| `captionsTitle` | כתוביות לשאלות |
| `captionsHelp` | ניצי תמיד מקריאה את השאלה. מספרים ושם הילד מופיעים תמיד. ההגדרה הזאת נשמרת רק במכשיר הזה. |
| `captionsAuto` / `captionsOn` / `captionsOff` | לפי שלב הלימודים / להציג / להסתיר |
| `captionsNowOn` / `captionsNowOff` | עכשיו: מוצגות ({stage}) / עכשיו: מוסתרות ({stage}) |
| `septTitle` | שנת לימודים חדשה |
| `septQuestion` | {child} עולה ל{next}? |
| `septHelp` | השיעורים שכבר נלמדו נשארים. השינוי יחול מהפעם הבאה שהילד ישחק. |
| `septYes` / `septKeep` / `septOther` | כן, {next} / להשאיר ב{current} / שלב אחר |
| `addAgeTitle` | התאמה לגיל: {child} |
| `addAgeBody` | אפשר להוסיף חודש ושנת לידה ולאשר את שלב הלימודים, כדי שהמסכים יתאימו לגיל. לא חובה. |
| `addAgeYes` / `addAgeLater` | להוספה / לא עכשיו |
| `areaChildSettings` | הגדרות |

For the editor: the prefix "ל" before a stage name ("לכיתה א׳", "לגן חובה") and "ב" in "להשאיר ב…" need a form per stage (or a
rewording without the prefix); "גן טרום־טרום חובה" may want a plainer name for parents ("גן גיל 3"?).

## 6. Step 6: presentation by stage

### 6.1 What is read, and when

- The stage is `effectiveStage(...)` (§3.3), read **once at the start of a session** (`childAgeProvider`), so nothing changes under
  a child mid-activity. A stage change (a birthday month, a confirmed stage, a new look letter) shows at the next session start.
- **Captions** come from the reading setting (§3.2), not from the stage.
- **Never in the child space:** an age, a band, a stage name or a "little ones" mode. The profile picker always uses P1 sizes
  (anyone may tap it). The parent area does not change by stage.

### 6.2 The stage table (the numbers)

Proposed as a new token group `stage` in `design/tokens.json` (§6.6), generated into `tokens.g.dart`. Sizes in points; per board
where it matters (phone = phone and phone SE unless named).

| | P1 (to 3;5) | P2 (3;6 to 4;11) | P3 (5;0 to 6;5) | P4 (6;6 and up) |
|---|---|---|---|---|
| Answer choices shown, at most (UI cap) | 3 | 3 | 4 | 5 (keypad allowed) |
| Answer tile, drawn, phone / tablet | 96 / 112 | 96 / 112 | 88 / 104 | 80 / 96 |
| Gap between tiles, phone / tablet | 32 / 32 | 32 / 32 | 24 / 24 | 20 / 16 |
| Hit slop each side, phone / tablet | 16 / 16 | 16 / 16 | 12 / 12 | 10 / 8 |
| Hit area, phone (≈ mm) | 128 (20 mm) | 128 (20 mm) | 112 (17.5 mm) | 100 (15.6 mm) |
| Tile numeral, phone / tablet (`type.kid.numeral`) | A 56 / 72 | A 56 / 72 | B 48 / 64 | C 40 / 56 |
| Caption size: phone / phone SE / tablet (when shown) | 26 / 24 / 32 | 26 / 24 / 32 | 24 / 22 / 30 | 22 / 20 / 28 |
| Caption floor before the bubble widens | size − 2 | size − 2 | size − 2 | size − 2 |
| Speaker bubble (captions hidden), phone / tablet | 64 / 72 | 64 / 72 | 64 / 72 | 64 / 72 |
| Steps in one instruction (content) | 1 | 1 | 2 | 3 |
| Items per activity | 3 to 4 | 3 to 5 | 5 to 8 | 8 to 12 |
| Session length, minutes (default; the parent's limits still apply) | 6 | 8 | 12 | 15 |
| Idle: first prompt / second / offer / soft pause, s | 8 / 15 / 30 / 120 | 8 / 15 / 30 / 120 | 12 / 25 / 45 / 120 | 20 / 40 / 60 / 120 |
| Hint pace: the first mistake shows | level 2 | level 1 (level 2 on a two-choice item) | as P2 | as P2 |
| Attempts before the worked example | 2 | as authored (2 on two-choice) | as P2 | as P2 |
| Transition, ms / overshoot (`motion.*ByBand`) | 450 / 1.12 | 450 / 1.12 | 350 / 1.08 | 280 / 1.04 |
| Tier-1 celebration, ms | 800 | 800 | 700 | 500 |
| Tier-2 celebration, ms; skip | 3000; after 1.5 s | 3000; after 1.5 s | 2500; after 1.5 s | 2000; a tap skips at once |
| Things moving at once | 1 | 1 | 1 | 2 |
| Home land signs, phone / tablet (Heebo 500) | 18 / 18 (fit 18 → 15) | as P1 | 20 / 22 (fit 20 → 17) | as P3 |
| Home "+" pebble, drawn | 64 | 64 | 56 | 56 |

Checks done on the numbers (mockups `b29/p6_stages_*.png`):
- **Room:** 3 × 96 + 2 × 32 = 352 fits the phone's 534 and the SE's 480; 5 × 80 + 4 × 20 = 480 fills the SE exactly (P4 is the
  binding case); tablets have 584 and 772.
- **The bottom band:** the lowest hit edge is 356 on the phone (P1: 244 + 96 + 16; the band starts at 369), 326 on the SE (351),
  682 on the tablet landscape and 824 on the portrait.
- **The stage:** a hit area never reaches into the stage: its top is clipped at the stage's bottom edge (tablet landscape P1 is the
  tightest: 538 against the card's 536 lip).
- Session minutes, items per activity and the P1 hint pace are content pacing: the **curriculum-expert confirms** them before the
  build (§7 hand-offs). The P1 and P2 split of today's Band A values (6 vs 8 minutes, 3 to 4 vs 3 to 5 items) is my proposal.

### 6.3 The six defects of `age-fit-design.md` §5.4

**D1. The bubble shrinks text to 14 pt.** Today `ActivityFrame.fitBubble(min: 14)` starts at the board's font (26, 22, 28, 28)
and goes down to 14, then widens, then to 11 (`hardMinFont`).
Fix: the start is the stage's caption size for the board (§6.2), the floor is that size − 2 (drawn points, with the text scale, as
today), then the bubble widens as built in 130351dc (keeping 150 pt of stage on phones), and only then the last resort. Every
line that needs the last resort at any stage is a **content defect**: the existing audit of every activity on four boards at text
1.0 and 1.3 runs once per stage and writes the list for the hebrew-text-editor (shorten, or split into two bubbles). The build is
not blocked by that list.

**D2. Band A sees the full caption.** Today `bubbleText` shows for every band; only the live tutor's line is hidden for Band A
(`lesson_controller.dart:398`).
Fix: when the reading setting hides captions, the Hebrew words are not drawn. In their place a **speaker bubble** (white pebble,
64 phone / 72 tablet, `cardLip` lip, an ink speaker glyph, a tail to Nitzi's mouth) at the end of the bubble's place by the mouth
(`b29/p6_stages_phone.png` P1 and P2). A tap replays the line, like a tap on Nitzi. The number sentence (`bubbleMath`), the
target-language chip of a course and every numeral on tiles still show. The tutor rule at line 398 reads the same setting instead
of the band.

**D3. Phone answer tiles are about 15 mm.** Fix: §6.2's tile, gap and slop through the shared answer row (`play/choice_row.dart`
and `ActivitySpec.tileHeight`/`tileFont`), so P1 and P2 hit areas are 128 pt (2 cm) on phones. The cap (§6.4) keeps P1 and P2 at
3 choices, which is what makes the 32 gap fit. Templates with their own rows (sort bins, the keypad, coins, blocks) keep their
sizes in this step; the developer lists them with their sizes, and I take that list as a follow-up.

**D4. Home map labels.** Fix: the sign text goes to **Heebo 500** at every stage (§9.4: pointed text below 24 pt is at most 500).
P1 and P2 keep 18 → 15 (the sign is decoration there; the name is voiced on touch). P3 and P4 get 20 → 17 on phones and 22 → 19 on
tablets, with B-26's shortening of the home island's name. The "+" pebble is drawn at 64 (P1, P2) or 56 (P3, P4) instead of 48,
its hit area at least 72; if 64 does not fit beside the companion on the phone SE, 56 for all and say so.

**D5. Idle prompts that only pulse.** There is no idle ladder in `app/lib/play` today.
Fix, by stage (timings in §6.2; every timer restarts on any touch; nothing is a countdown and nothing is shown as time):
1. **First prompt:** Nitzi says the question again (the item's own line, no new voice line), the speaker bubble or the caption
   bubble rings once in `color.brand.sky`, and in P1 to P3 **the B-40 pointing hand points into the stage**, tip at the stage's
   centre, coming up from below over the grass (`b29/p6_idle_phone.png`). **It never points at a tile or at the answer.** P4: the
   line again, no hand.
2. **Second:** the same, with the hand in P4 too, and Nitzi's "talk" pose.
3. **The offer:** the existing spec line "רוצים רמז, או לחשוב עוד קצת?" with the "I'm not sure" pebble glowing; "think more" sits
   Nitzi down beside the child (design-spec §6.3). The line needs the editor and, later, a voice (text only now).
4. **Soft pause** at 120 s, as specified.
Never a glow or pulse alone at any step (Hiniker 2015). Reduce-motion: no ring, the hand appears without travel.

**D6. The oldest get the youngest's pacing.** Fix: §6.2's motion, celebration and density rows from P3 and P4: less bounce, shorter
celebrations, a P4 tap skips the tier-2 at once, two moving things allowed, up to 5 choices, longer idle times. Tone (no
diminutives, more humour) is the voice-and-sound-director's and the editor's, as a later item, not in this build.

### 6.4 The choice cap (a safety net; content is still written per stage)

When an item has more options than the stage's cap, the UI shows: the correct option(s), then options with a misconception tag in
authored order, then the rest in authored order, up to the cap, and lays them out in their **authored relative order** (so a
number row stays ascending). The cap counts answer options only, never the objects on the stage (counting may show more).
`optionCount` after the cap is what the two-choice retry rule reads. A content test lists every activity over the cap per stage,
for the curriculum-expert.

### 6.5 What never changes with the stage

Voice first and unlimited replay; no timers, countdowns or streaks; a tap alternative to every drag; touch-down feedback within 50
ms; the holdover and palm filters; colour never alone; nikud at line height 1.7; Heebo and Secular One; home in the top corner;
nothing in the bottom 24 pt band; the hint ladder with "I'm not sure"; reduce-motion; nothing above 3 Hz; process praise; one
world and cast. Mastery, the path and finished lessons never read the stage.

### 6.6 Tokens to add (`design/tokens.json`, then `dart run tool/gen_tokens.dart`)

```json
"stage": {
  "$note": "Presentation stages P1-P4 (B-29, docs/design/b29-steps5-6.md 6.2). Sizes phone/tablet; captions phone/phoneSE/tablet.",
  "P1": {"maxChoices": 3, "tile": {"phone": 96, "tablet": 112}, "gap": {"phone": 32, "tablet": 32}, "hitSlop": {"phone": 16, "tablet": 16},
         "numeral": "A", "caption": {"phone": 26, "phoneSE": 24, "tablet": 32}, "captionFloorDrop": 2, "speakerBubble": {"phone": 64, "tablet": 72},
         "idleS": [8, 15, 30, 120], "transition": 450, "overshoot": 1.12, "tier1": 800, "tier2": 3000, "tier2SkipAfter": 1500, "focal": 1,
         "sign": {"phone": [18, 15], "tablet": [18, 15]}, "plusPebble": 64},
  "P2": {"maxChoices": 3, "tile": {"phone": 96, "tablet": 112}, "gap": {"phone": 32, "tablet": 32}, "hitSlop": {"phone": 16, "tablet": 16},
         "numeral": "A", "caption": {"phone": 26, "phoneSE": 24, "tablet": 32}, "captionFloorDrop": 2, "speakerBubble": {"phone": 64, "tablet": 72},
         "idleS": [8, 15, 30, 120], "transition": 450, "overshoot": 1.12, "tier1": 800, "tier2": 3000, "tier2SkipAfter": 1500, "focal": 1,
         "sign": {"phone": [18, 15], "tablet": [18, 15]}, "plusPebble": 64},
  "P3": {"maxChoices": 4, "tile": {"phone": 88, "tablet": 104}, "gap": {"phone": 24, "tablet": 24}, "hitSlop": {"phone": 12, "tablet": 12},
         "numeral": "B", "caption": {"phone": 24, "phoneSE": 22, "tablet": 30}, "captionFloorDrop": 2, "speakerBubble": {"phone": 64, "tablet": 72},
         "idleS": [12, 25, 45, 120], "transition": 350, "overshoot": 1.08, "tier1": 700, "tier2": 2500, "tier2SkipAfter": 1500, "focal": 1,
         "sign": {"phone": [20, 17], "tablet": [22, 19]}, "plusPebble": 56},
  "P4": {"maxChoices": 5, "tile": {"phone": 80, "tablet": 96}, "gap": {"phone": 20, "tablet": 16}, "hitSlop": {"phone": 10, "tablet": 8},
         "numeral": "C", "caption": {"phone": 22, "phoneSE": 20, "tablet": 28}, "captionFloorDrop": 2, "speakerBubble": {"phone": 64, "tablet": 72},
         "idleS": [20, 40, 60, 120], "transition": 280, "overshoot": 1.04, "tier1": 500, "tier2": 2000, "tier2SkipAfter": 0, "focal": 2,
         "sign": {"phone": [20, 17], "tablet": [22, 19]}, "plusPebble": 56}
}
```

Pacing values that belong to the engine (items per activity, session minutes, hint pace) go in `EngineParams` per stage, not in the
tokens. Captions are a reading setting, not a token.

### 6.7 Goldens plan

| Set | Screens | Count | Notes |
|---|---|---|---|
| Activity by stage | one counting `tap_answer` item **authored with 5 options**, so the cap shows (3, 3, 4, 5), at P1 to P4 × phone, phoneSE, tabletLandscape, tabletPortrait; captions at the stage's default (hidden for P1 and P2, shown for P3 and P4) | 16 | `stage_<p>_activity_<board>.png`; the mockups `b29/p6_stages_*.png` are the target |
| Home map by stage | the home map, a named home island, at P1 to P4 × 4 boards | 16 | signs at 500, the "+" pebble |
| Idle prompt | the first prompt at P2 and P4 on the phone (the hand drawn at its rest, no animation) | 2 | `b29/p6_idle_phone.png` |
| Captions crossed | P1 with captions shown and P4 with captions hidden, phone | 2 | the floor and the speaker bubble at the other extremes |
| Parent | the form on phone, phoneSE and tabletPortrait; the settings page on phone; the age page on phone; the area cards on phone | 6 | at text 1.0; plus the form on phoneSE at 1.3 |
| Text audit | every activity of every land, per stage, at text 1.0 and 1.3 | no goldens | writes the list of lines below the floor (D1) |

Run one file at a time; `git checkout` any unrelated golden the run rewrites.

## 7. Build list for the app-developer (steps 5 to 9)

Order: 5a (server, needs the owner's deploy OK) before the app parts that sync the birth month. Each step: the analyzer, format and
tests after every change; QA once when steps 5 to 8 are done (step 9).

### Step 5a: the birth month and year sync (owner, 2026-11-08)

1. **Database** (infrastructure-engineer, security-engineer review): additive columns on `app.child_profile` beside `school_stage`:
   `birth_year smallint null`, `birth_month smallint null`, with checks: both null or both set; month 1 to 12; year between 2010
   and 2100 (the device checks the real range). Next migration number; no grant to `anon` or `authenticated`.
2. **Functions:** `child-put` takes an optional `birth: {"year": int, "month": int}`; absent keeps the stored value, `null` clears
   it, anything else is refused (unknown keys refused, as for `school_stage`). `sync-pull` returns `birth` per child. Test vectors in
   `testvectors/profile-sync.json`. Deploy needs the owner's OK; order database, functions, then the app.
3. **App:** `ProfileBirths` is written from a pull and sent in `child-put` (the sync fingerprint includes it); a pulled value is
   checked with `BirthMonth.tryCreate`; deleting a child deletes it on both sides (already true for the row).
4. **Tests change:** the canary was "a birth month never appears in any outgoing request, log or sync payload". It becomes: **never
   in any log line (the app's `Log`, the functions' logs), never in `tutor-turn` or any other function's request except `child-put`,
   never in a vendor payload (Anthropic, ElevenLabs), never in an export**; allowed only in `child-put`'s body and `sync-pull`'s
   response. `BirthMonth.toString` stays redacted. The age in months stays computed on the device and is never stored or sent.
5. PLAN.md, CLAUDE.md and B29.md already carry the owner's wording (`d95db27a`).

### Step 5b: the parent area

1. `AgeFields` widget (`app/lib/parent/age_fields.dart`): §2, values in and out (birth month or null, stage or null, "chosen by
   the parent" flag); the suggestion rule as a pure function with tests (`suggestedStage(birthYear, now)`), including the
   1 September edge and the clamps.
2. `child_form.dart`: replace the age chips; save `school_stage` (and the band from it, `SchoolStage.band`), the birth row if both
   parts are set, and `stage_year_<id>`. Save disabled without a stage. `bandForAge` is then unused by the form.
3. Age page (`age_page.dart`): AgeFields + Save/Cancel; on Save write the stage (child-put), the birth row, `stage_year`; the
   "younger" note (§2.2).
4. `ChildSettingsScreen`: the two cards of §3 at the top; the look writes `FamilyLooks` and syncs; the captions write
   `reading_<id>` on the device. The parent area's child row button: "הגדרות" (`areaChildSettings`), opening this page.
5. Parent area home: the September card and the add-the-age card (§4), with tests for the date rule (31 August no card, 1 September
   card, grade 3 never, answered card gone, a pulled change sets `stage_year`).
6. The texts of §5 in `strings/he.dart`, each marked needs-editor; the editor's version replaces them before the merge.
7. Goldens: the six parent ones of §6.7.

### Step 6: presentation by stage

1. `StageSpec` (from the new `stage` tokens) and `effectiveStage` (§3.3), read once per session start; `PresentationSpec` gains the
   stage (items per activity, session minutes from `EngineParams` per stage, `maxChoices`).
2. D1: `fitBubble` start and floor from the stage and board; the audit per stage writes the defect list.
3. D2: the captions setting (`reading_<id>`, default by school stage); the speaker bubble; `lesson_controller.dart:398` reads it.
4. D3: tile, gap, slop and numeral from `StageSpec` in the shared answer row; hit areas clipped at the stage; the list of
   templates with their own rows and sizes, for me.
5. The choice cap (§6.4) with tests (the correct always kept, tagged next, order kept, `optionCount` after the cap).
6. D4: home signs at weight 500, sizes per stage; the "+" pebble.
7. D5: the idle ladder in the lesson screen (timers reset by any touch, paused while a line plays or the parent area is open), the
   hand from the B-40 hand layer pointing at the stage centre, never a tile; tests that the hand's target is inside the stage rect.
8. D6: motion durations, overshoot, tier-1 and tier-2 lengths and the P4 skip from `StageSpec`; one focal motion in P1 to P3.
9. Hint pace: P1's first mistake shows level 2 and the worked example after 2 attempts; P2 to P4 as today. Tests per stage.
10. The profile picker at P1 sizes whatever the children's stages.
11. Goldens of §6.7 (activity 16, home 16, idle 2, captions crossed 2).

### Step 7: the languages

1. `engine/gates.dart`: a gate's minimum age reads the age in months when a birth month is known (Russian letters at 5;0 = 60
   months, the English oral gate likewise), else `bracketMinAge` from the band as today. The result never leaves the device.
2. The course's presentation **band** (content rules) stays: the course choice, else the school stage's band. The course's **look**
   is `effectiveStage(age, lookBand, courseBand: the course choice)` (§3.3), so caps, items, session length (English's own
   minutes per band stay), idle and hint pace follow the stage inside the course.
3. A language start never reads age: the questionnaire and the LS13 staircase only (unchanged; a guard test in step 9).
4. The Hebrew frame's captions read the captions setting (§3.2); target-language text keeps the course rules (frame §3.1).

### Step 8: Today's Adventure

`world/todays_adventure.dart` picks `_paramsByBand[profile.stage.band]` (`ProfileAge.stage`: the confirmed stage, else the middle of
the band) instead of the stored band. The rows stay equal; a test that the row follows the school stage and that nothing else in
the rule reads age.

### Step 9: QA guard tests (qa-engineer)

1. A birthday never changes finished lessons, mastery or the path (exists: `test/birthday_changes_nothing_test.dart`; extend to a
   stage boundary month and to a look letter change).
2. A stage or look change applies only at the next session start, never mid-activity.
3. The birth month and year: in `child-put` and `sync-pull` only; never in a log, `tutor-turn`, any vendor payload or an export
   (the changed canary, step 5a.4).
4. The path does not depend on age once a land has been played; a language start never depends on age.
5. The cap, the hit areas inside the board and outside the bottom band, the idle hand never on a tile, on all four boards and four
   stages; the parent pages at text 1.3; then the phone check by the owner (§8).

### Hand-offs from this spec

- **hebrew-text-editor:** the §5 texts and the stage-name prefixes; the idle offer line; later, the per-stage D1 defect list.
- **curriculum-expert:** confirm §6.2's items per activity, session minutes and P1's hint pace; the order the cap keeps options
  (§6.4); instruction steps per stage in content; the over-cap list.
- **voice-and-sound-director:** the idle ladder's timing against the voice lines (a prompt never talks over a line), the tier-1 and
  tier-2 lengths per stage, and later the P4 tone.
- **security-engineer:** step 5a (columns, `child-put`, `sync-pull`, the changed canary).
- **qa-engineer:** step 9 once steps 5 to 8 are built.

## 8. For the owner (recommendation first)

- **O1. A "growing up" moment when the look changes:** none (a silent change at the next session), or a short Nitzi scene with no
  reward? Recommendation: silent for now; a scene can come with the real art.
- **O2. A 3-year-old on a phone:** the phone works (at most 3 big choices, 2 cm hit areas); add one line in the screens card,
  shown only on a phone for a P1 child, suggesting the tablet? Recommendation: yes, one calm line.
- **O3. The September card on a second device:** if you keep a child's stage on the phone, the tablet asks once more. Accept, or add
  a synced "school year" beside the stage? Recommendation: accept.
- **O4. The step-in over two weeks and the quiet step-back** from the research (§6 of `age-fit-design.md`): not in this build; the
  whole new look starts at the next session. Recommendation: accept, and revisit after the children have used it.
- To look at: `docs/design/b29/p5_form_phone.png`, `p5_settings_phone.png`, `p5_area_cards_phone.png`, `p6_stages_phone.png`,
  `p6_idle_phone.png`.

## 9. What I looked at, and what I did not

Looked at every PNG in `docs/design/b29/` after the last render: the form on phone, phone SE and tablet portrait; the settings page
on phone and tablet landscape; the age page on phone; the area cards on phone; the four stage sheets (phone, phone SE, tablet
landscape, tablet portrait, each P1 to P4); the idle prompt on phone; and a close crop of the tablet landscape P3 caption (nikud at
30 pt clean, nothing clipped). First renders I changed: the year and month rows wrapped raggedly (now grids); the settings page
had the pickers inline (now a summary and a page); the idle hand first pointed down at a tile and then covered a flower (now up
from the grass between the flowers); the first stage art carried a count badge (now the badge-free `lesson_1_red_flower` stage).
Not done: no app code, no goldens rendered (the mockups are HTML, not Flutter, so line breaks and chip widths can differ a little),
no text scale 1.3 render of the parent pages, no real phone (the owner can). No real-world object was drawn, so no references were
needed; every picture is the app's existing art.
