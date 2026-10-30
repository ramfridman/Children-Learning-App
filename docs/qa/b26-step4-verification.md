# QA verification: B-26 step 4 (the child's home, `HomeIslandScreen`)

2026-10-30, qa-engineer. Worktree `D:\nitznutz-b26`, branch `b26-nitzi-home`, step 4 uncommitted on top of `9c71110`.
Design: `docs/design/nitzi-home.md` sections 2, 3, 3.1 and 5; the design-director's review `docs/design/b26-step4-review.md`.
Not part of step 4 and not touched: `docs/agents/board.md`, `docs/child-safety/`, `.claude/`. No git write, no paid voice
command.

**The tree changed during this check.** At 00:16 to 00:17 the design-director changed `tools/make_nitzi_home.py`,
`app/assets/art/home/bottle_big.svg` and the four `app/assets/art/scenes/nitzi_home_*.svg` (and `nitzi-home.md`).
Results are marked **[before art]** (the tree as the developer delivered it) or **[after art]**.

**Final verdict (2026-10-30): B-26 step 4 may be committed.** Analyzer and format clean; the whole suite with QA's file
**2029 passed, 8 skipped, 0 failed**; only the expected goldens changed (16 modified, 6 new); every mutation of the new
code is caught except one equivalent mutant (W2); QA-32 closed; D-1 not reproduced. Open, not blocking: QA-33 (a polish
nit at the wedge's joint), QA-28 (tolerance), QA-19 (older). See "Final pass (done)" at the end.

**Verdict (first pass).** The code of step 4 does what the plan and the design say, on four boards at text scale 1.0 and 1.3, and
every mutation tried is caught. Two things must happen before the commit, both already planned: the app-developer
regenerates the `home_island_*` goldens after the art change and D-4 (two of them now fail, 4.95 % and 4.39 %), and
then the whole suite runs green once more. D-1 (the title after a text-scale change) does **not** reproduce. No new
defect in the step-4 code. One older stale golden (QA-32) and the golden tolerance (QA-28) are follow-ups.

## What ran

| Command (in `app/` unless said) | Result |
|---|---|
| `flutter analyze` | No issues found [before and after art] |
| `dart format --output=none --set-exit-if-changed .` | 0 changed (288 files; 289 with QA's file) |
| `flutter test` (whole suite, as delivered) [before art] | **1930 passed, 8 skipped, 0 failed** (11 min 44 s), the developer's count |
| `git status` / `git diff --stat` on `app/test/goldens/` | **15 modified + 6 new, nothing else** (below) |
| `python tools/export-hebrew-review.py`, then `python tools/hebrew_voice_review.py` (repo root) | 9,522 rows, master text-ready 9,455, proposed 44, unchanged 23; the five tables byte-identical to the delivered ones; against HEAD only the `nitziHomeHi` row (`זֶה הַבַּיִת שֶׁלָּנוּ.`) in three tables; the two voice tables unchanged (the line is not spoken) |
| `flutter test test/qa_b26_step4_test.dart` (QA's file, 68 tests) | [before art] the first 54 tests: 53 passed, 1 failed (QA's own timing bug in the back-during-push test, fixed); the motion-on (4) and D-1 (9) groups added and run [after art]; in the final full run all 68 pass |
| 5 product mutations, each against `home_island_screen_test`, `home_island_flow_test`, `home_sign_test` and QA's file [after art] | all caught (below). A first two rounds were discarded: other agents' test runs locked `build/native_assets/.../sqlite3mc.dll` and made runs fail for no reason; the third round retried on the lock and names the first failing test |
| D-1 reproduction [after art] | not reproduced (below) |
| `flutter test` (whole suite with QA's file; run last) [after art] | **1996 passed, 8 skipped, 2 failed** (14 min 10 s): the 2 failures are `home_island_tablet_portrait.png` (4.95 %) and `home_island_long_name_1.3_tablet_portrait.png` (4.39 %), stale after the art change on purpose; 1930 + 68 = 1998 |

## Checks

1. **Goldens: only the expected ones.** Modified (15): `companion_home_hero_phone`, `home_phone`, `home_phone_end`,
   `home_phone_se`, `home_phone_se_end`, `home_tablet_landscape`, `home_tablet_portrait`, `home_tablet_portrait_top`,
   `home_long_name_tablet_landscape`, `home_long_name_tablet_portrait`, `home_sign_alexandra_phone`,
   `home_sign_alexandra_phone_se`, `home_sign_avigail_alexandra_phone`, `home_sign_avigail_alexandra_phone_se`,
   `home_sign_noa_phone_se`. New (6): `home_island_phone`, `_phone_se`, `_tablet_landscape`, `_tablet_portrait`,
   `home_island_long_name_1.3_phone_se`, `_tablet_portrait`. No other PNG is modified or untracked;
   `companion_lesson_hero_phone.png` and `companion_celebration_phone.png` equal HEAD. Against HEAD, by pixel
   region: the map goldens differ only where the two pebbles and their labels were (phone 665..792 x 86..166, SE
   523..650, tablets 1028..1155 / 668..795); the SE ones also by the moved sparkle (273..286 and 408..418); the four
   `home_sign_*alexandra*` only in the bubble (the island's name in it since step 3; they were stale and passed under
   the 3 % tolerance, QA-28: QA's step-3 diff looked only at changed files and missed them); `home_sign_noa_phone_se`
   only the sparkle. The hero golden keeps the family character's square. Looked at all 21 [before art].
2. **The home on four boards, text scale 1.0 and 1.3, five names, in the real app** (`qa_b26_step4_test.dart` group
   "every door"; `נועה`, 24 x ש, 25 letters, blank, `Alexandra Massimiliano`; 40 cases): in by the sign; no error and no
   overflowing flex in the home; the title is `island.title` (24 guard; 25 letters show 23 and `…`); the title, the
   back pebble, the four objects and the bubble lie on the board; the bubble is the welcome with the isolated name or
   `nitziHomeWelcomeNoName`; **the book opens the stickers, the lighthouse the Hall, the bottle a Counting Hills lesson
   (never a land screen), each back to the home; the friend says `זֶה הַבַּיִת שֶׁלָּנוּ.` and opens nothing; back is the
   map; Nitzi never in `openableLands`**. The developer's geometry against sections 3 and 3.1 (rects, gaps, labels,
   the bottom-24 band, title cards) was read against the design's tables (identical numbers) and its tests run; the
   four §3.1 worst-case cards at 1.3 measured again in D-1 below (phone 19 pt, 1 line, 646.6 x 48.0; SE 15, 2 lines,
   452.2 x 72.0; landscape 27, 1 line, 915.8 x 66.0; portrait 18, 2 lines, 550.6 x 86.0): the design's table.
3. **Renders looked at** [after art], real app: portrait `נועה` 1.0, landscape `Alexandra Massimiliano` 1.3, SE 25
   letters 1.3, phone blank 1.0. The bubbles stay clear of the bottle; the moved bushes and palm leave the portrait
   bubble clear. In the landscape welcome the Latin double name wraps between its parts; glyph boxes confirm the
   reading order on line 2 (`Massimiliano` at the right, `!` then `בְּרוּכִים` to its left).
4. **Rapid taps and back** (phone): with reduce motion and with real 300 ms transitions, a double tap 60 or 80 ms apart
   on the bottle, the book or the lighthouse opens one screen; the sign then the pill opens one home; back tapped while
   the home is still sliding in is ignored by the transition (the home stays; nothing reaches the avatar under that
   corner, no child switch); the system back from a door is the home, then the map.
5. **Bottle and warm-up.** With the warm-up due (age band 1, warm-up on), the bottle opens the Counting Hills warm-up
   (a mission lesson) first, exactly as the map's way in; leaving it returns to the home and starts nothing else. The
   bottle and the pill say the same (`homeDaily`), as screen-reader label and as the bottle's caption.
6. **Something waits in the Hall, all four boards.** The map sign glows and wears the trophy badge on its start
   (right) corner over the top border, on screen, clear of the "+"; the tap area's and the sign's label are
   `<island>, גביע חדש מחכה`; in the home the lantern shows the trophy and its halo. The sticker on the book: the
   developer's test (latest sticker) passes.
7. **Screen reader.** Order back, title, bottle, friend, book, lighthouse (the developer's test). The friend's node is
   a button with a tap action and the label `נִיצִי` (from the character view; it would be the chosen friend's name), so
   it is not unlabelled. The back pebble and the title use the same palm-island picture (D-9, kept on purpose): their
   labels differ (`חזרה למפה`, the island's name as a header).
8. **Reduce motion.** The bottle stands still with reduce motion (the developer's test); the friend's arrival wave is
   a picture held 1.6 s by a controller (no timer, settles).
9. **QA-19 on the phone map at 1.3** (pebbles gone): the pill still overflows **9.8 pt** (the same as before); the
   picker's cards still overflow 2.4 pt at 1.3 on the SE and the tablets. Open, older.
10. **D-1 (design-director, unconfirmed): not reproduced.** Three ways: (a) 8 real-app tests, 24 x ש, home opened at
    1.0 then 1.3 and at 1.3 then 1.0, on each board: the title's size and line count are what `fitIslandTitle` gives
    for the new scale, the paragraph is painted at the new scale, and the name sits on one line (never broken between
    its letters); (b) one test that starts eight app instances in a row, raising the scale after each home opened:
    the same; (c) a copy of the design-director's own `review_render_test.dart` run in full (32 tests, the scale raised
    after the home opened): the DBG lines give exactly the §3.1 table on all four boards, the name on one line. QA's
    regression tests stay in `qa_b26_step4_test.dart` (group "D-1"). If the design-director saw it with an earlier
    build of the screen, it is gone now. **Note:** that copy wrote its PNGs into the design-director's
    `scratchpad\b26review\png2` (the output path in the copied file was not changed); the 32 PNGs there were
    overwritten at 00:41 with renders of the current tree [after art]. The review is written; QA tells the orchestrator.
11. **Mutations** [after art]:

    | Mutation | Caught by (first failing test) |
    |---|---|
    | N1 the book's door removed (`onStickers` not passed) | `home_island_flow_test` (the book opens the stickers), QA (phone x1.3 noa) |
    | N2 the title painted at its base size, not the fitted one | `home_island_screen_test` (geometry phone x1.3 wide_24) |
    | N3 the return path broken (`_openStickers` with `pushReplacement`) | `home_island_flow_test`, QA |
    | N4 the SE lighthouse back at the old rect (24, 84, 112 x 240) | `home_island_screen_test` (geometry phoneSE x1.0 noa) |
    | N5 the sign's glow and badge removed | `home_island_flow_test`, QA (something waits, phone) |

    (In N2 and N4 the flow test's first failure was the stale portrait golden, which fails without a mutation too.)

## Defects and follow-ups

| id | severity | owner | what | proof | done when |
|---|---|---|---|---|---|
| (planned) | blocker for the commit only | app-developer | After the art change, `home_island_tablet_portrait.png` (4.95 %) and `home_island_long_name_1.3_tablet_portrait.png` (4.39 %) fail; the other `home_island_*` are stale under 3 %. Regenerate all 6 by name after D-4, then the whole suite. | final full run | the whole suite is green |
| QA-32 | minor (test honesty) | app-developer | `companion_lesson_hero_phone.png` (2026-10-26, M4) still shows the lesson's mic button, which B-24 removed from that activity; a fresh render differs 2.22 % (region 661..748 x 241..353, the mic). It passes under the 3 % tolerance and will fail on the next small change of that screen. Not caused by B-26. Refresh it **by its exact name**: `flutter test --update-goldens test/companion_everywhere_test.dart --plain-name "pictures with a family character the lesson"` (the shorter `"the lesson"` also matches five other tests and rewrites `companion_celebration_phone.png`), then check the diff is only the mic. | QA render compared with the committed PNG | the golden equals the current render |
| QA-28 | minor (test honesty), open | infrastructure-engineer (comparator), qa-engineer | More evidence: stale bubble regions since step 3 (0.3 to 0.6 %), the lesson hero 2.22 %, the removed pebbles 1.2 % all pass at 3 %. Not closed by lowering the tolerance blindly: the 3 % covers Windows against Linux text rendering on CI. Proposal: CI prints each golden's diff percentage once; then a per-file tolerance just above it (the home goldens likely under 1 %). | this record | the tolerance per golden is measured and set |
| QA-19 | major (older), open | design-director, app-developer | unchanged: the phone pill overflows 9.8 pt at 1.3; the picker cards 2.4 pt | QA-19 tests | as filed |

## Not checked

The real phone and tablet, sound, a child's hands, a screen reader on a device, iOS; `deno task check` (nothing under
`supabase/`). The goldens after the art change are the developer's to regenerate.

## Final pass, part 1 (paused 2026-10-30 at the orchestrator's request)

The developer added the wedge tail (`BoardBubble.tailTip`, `bubbleWedgeTail`, `_WedgeTailPainter`; the home's
`tailTip` from the friend's rect), regenerated the 6 `home_island_*` goldens and refreshed
`companion_lesson_hero_phone.png`. The design-director then asked to move the tip and add an ink outline, so the final
pass stopped here; QA stopped its own full run when the pause came (another full run in the same worktree was going on
at the same time, by another agent: the `sqlite3mc.dll` lock again). Proven so far, none of it depending on the tail:

1. `flutter analyze`: no issues; `dart format --set-exit-if-changed .`: 289 files, 0 changed (on the tree with the
   first wedge).
2. **Golden set:** `git status` shows **16 modified** (the 15 map goldens of the first pass + `companion_lesson_hero_phone`)
   and **6 new** (`home_island_*`), nothing else. The 15 map goldens are byte-identical to the ones checked in the first
   pass; only the lesson hero and the 6 `home_island_*` differ from then.
3. **QA-32 closed.** The refreshed `companion_lesson_hero_phone.png` differs from HEAD only in the old mic button's
   region (661..748 x 241..353): the family character (the dark red square) and the question bubble are as before. It is
   **byte-identical** to the render QA made with the exact `--plain-name "pictures with a family character the lesson"`
   command in the first pass, so for this golden the named run and the whole-file run draw the same picture. The rule
   the orchestrator now records stands as a precaution: a golden with a fixture character is regenerated by running
   its whole test file, because `companion_home_hero_phone` (QA-27) does draw differently when its test runs alone.
4. **Map and lesson bubbles keep the old tail.** With `tailTip` null `BoardBubble` builds exactly HEAD's tail (right
   -10, bottom 18, the 22-point square turned 45°), first in the stack as before; the map passes no `tailTip` (the map
   goldens are byte-identical to the first pass); the refreshed lesson golden shows the small tail on the bubble's right
   edge.
5. **Everything else of the first pass stands** (flows of all doors on four boards at 1.0 and 1.3, rapid taps, back
   during a push, warm-up, glow, semantics, D-1 not reproduced, mutations N1 to N5): the tail is drawn under an
   `IgnorePointer`, inside a bubble already under one, and the doors' rects did not change.
6. The 6 `home_island_*` goldens of the first wedge were looked at; they will be regenerated again, so they are not
   judged here.

## Final pass (done, 2026-10-30, after the tip move and the outline)

The developer moved the tip to `companion.topLeft + (0.74 w, 0.47 h)`, added one outline (1.5, ink at alpha 0x33)
around body and wedge (`bubbleOutline`, a `Path.combine` union, only with `tailTip`), and regenerated the 6
`home_island_*` goldens. Nobody else ran tests in the worktree during this pass.

| Command (in `app/`) | Result |
|---|---|
| `flutter analyze` | No issues found |
| `dart format --output=none --set-exit-if-changed .` | 289 files, 0 changed |
| `git status` on `app/test/goldens/` | **16 modified, 6 new**, nothing else; the 15 map goldens byte-identical to the first pass; `companion_lesson_hero_phone.png` byte-identical to QA's render (QA-32 closed) |
| `flutter test test/qa_b26_step4_test.dart --plain-name "wedge tail"` (26 new tests) | 26 passed |
| 5 mutations of the tail (W1 to W5), each against `home_island_screen_test`, `home_island_flow_test`, `home_sign_test`, `board_geometry_test`, `golden_screens_test`, `companion_everywhere_test` and QA's file; files restored, SHA-256 checked, golden set unchanged after | below |
| `flutter test` (whole suite with QA's file; run last) | **2029 passed, 8 skipped, 0 failed** (13 min 29 s): the developer's 2003 + QA's 26 wedge tests; the golden set unchanged after (16 modified, 6 new) |

1. **The 6 `home_island_*` goldens** looked at (with a 3x and an 8x crop of the phone's wedge): one white wedge from
   the bubble's lower start corner to beside the friend's mouth on every board, a single faint outline around body
   and wedge (no line across the joint), the tip above the friend's cheek and clear of the bottle; the long-name 1.3
   cases keep a short wedge (portrait: about 26 below the three-line bubble).
2. **Tip and outline** (`qa_b26_step4_test.dart` group "the wedge tail", 4 boards x 1.0 and 1.3 x `נֹעָה`, 24 x ש,
   `Alexandra Massimiliano`, `HomeIslandScreen` pumped directly): the wedge holds a point 2 inside its rounded end at
   the design's tip and not one 3 beyond it (phone (498.4, 235.2), SE (401.68, 234.04), landscape (777.6, 492.8),
   portrait (477.6, 492.8)); the painted outline (`bubble-outline`) holds the same point and excludes the one beyond;
   the painter works in the body's size; the tip is at least 25 below the bubble (the least: portrait at 1.3 with a long
   name, 25.8; landscape 29.8) and inside the friend's tap area. The wedge covers no point of the bottle, book or
   lighthouse rect (checked on a 2-point grid; on the phones its bounding box touches the bottle's, the shape does not;
   the developer measures 6.0 at the SE at 1.3).
3. **Touches go through.** A hit test at the tip and in the middle of the wedge finds none of the bubble's render
   objects (body, wedge, outline); a tap at the tip greets (the friend's `זֶה הַבַּיִת שֶׁלָּנוּ.`) and none of the three
   doors fires (their callbacks fail the test).
4. **Map and lesson unchanged.** In the real app the map's bubble has `tailTip` null, no `bubble-tail` and no
   `bubble-outline`; the map goldens are byte-identical to the first pass; the lesson golden keeps the small right tail.
5. **Text scale 2.0, portrait tablet, 24 x ש**: no error, the outline is finite. The welcome there takes four lines and
   its bottom (636) passes the tip (492.8): the wedge then lies under the body and does not show, but the bubble covers
   the friend's head (it ignores touches, so the friend still greets). Outside the tested 1.0/1.3; a note for the
   design-director.
6. **Mutations:**

   | Mutation | Caught by |
   |---|---|
   | W1 the tip at 0.80 w instead of 0.74 w | `home_island_screen_test` (the wedge tail ends beside the friend's mouth), QA (wedge group) |
   | W2 the wedge's and the outline's own `IgnorePointer` removed | **none: an equivalent mutant**, the home's whole bubble is already under an `IgnorePointer` and the painters' boxes lie inside the body; the inner ones are a second guard |
   | W3 the `tailTip`-null tail moved (right -20, bottom 30) | `home_island_screen_test` (the map's bubble keeps its small tail on the right edge); **no golden caught it** (QA-28) |
   | W4 the home bubble's outer `IgnorePointer` removed | `home_island_screen_test` (a touch on the bubble reaches the friend) |
   | W5 the outline drawn around the body only | `home_island_screen_test`, QA (wedge group) |

7. **A polish nit (QA-33, minor, design-director):** at 8x the body's soft shadow, painted after the wedge, lies as a
   light grey band across the wedge right under the body (about 2 to 3 points, phone 560..600 x 165..170). At 1x it
   reads as a faint fold. If unwanted: paint the wedge's union with the body's shadow once, or clip the body shadow
   out of the wedge. Not blocking.
