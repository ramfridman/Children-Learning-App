# QA record: the course screens (L-course: course home, starting a lesson, "we start here", the guards, Today's Adventure)

Date: 2026-11-06. Verified by: qa-engineer. Branch `languages-course-home`, worktree `D:\nitznutz-lang5`, head `4c49c37` (before this record).
Plan: `docs/milestones/L-course.md` (section 1 "done when", section 9 "built", parts 2 to 7). Frame: `docs/languages/frame.md` 1.2, 1.3, 1.4, 3.2, 3.5, 3.7.
All material is fixture packs (a few real Band A items of each course, real pictures); there is no real content pack yet.

**Verdict: PASS on every item asked for. No defect against the course screens (no QA-LC-n was needed).** The merge in
`app/lib/world/language_placement.dart` is correct. Two notes for the design pass (N-LC-1, N-LC-2) and one limit of what was checked
(section 6). The L4 fixes are verified in `docs/qa/l4-languages-verification.md` section 10 (two new L4 defects there, QA-L4-11 and QA-L4-12).

## 1. What ran

| Command | Result |
|---|---|
| `flutter analyze` (in `app/`) | No issues found |
| `dart format --output=none --set-exit-if-changed .` | 462 files, 0 changed |
| `dart run tool/pack_builder.dart schema --check` | "The JSON Schema files in ../content/schemas are up to date." |
| `flutter test` (whole suite, once, before my two new files; 19 min 34 s) | **+4073 passed, 0 failed, 3 skipped** (3 old: `mastery_reachable_test` 1, `qa_open_defects_test` 2). No golden was rewritten (`git status` clean) |
| `deno task check` (fmt, lint, check, test) | exit 0; **198 passed, 0 failed, 7 ignored** |
| My new `app/test/qa_l_course_test.dart` | **+29 passed, 0 failed, 0 skipped** |
| My new `app/test/qa_l4_reverify_test.dart` (L4 record section 10) | +28 passed, 2 skipped (open defects) |

The gateway, migrations and policies are untouched by this branch (the plan, section 3: no Deno change), so Deno and pgTAP could not be
affected; Deno was run anyway as asked, pgTAP was not (no migration changed).

## 2. The criteria of the plan (section 1), one by one

| # | Criterion | Verdict | Proof |
|---|---|---|---|
| 1 | The course home: host, path in the course's reading direction, what is next; first visit invites to placement; after it the path opens at the placed level; back to the doors or the map | **PASS** | (a) Measured on the four boards for English, Hebrew and Russian (`qa_l_course_test.dart`, 12 tests): the pebble and the way back are at least 64 pt; host, pebble, title and back are on the board; the title stands under the pebble; with stones 1 done, 2 placed, the next, and later ones, the stones run left to right in English and Russian and right to left in Hebrew; the next stone opens in the middle of the board; a stone's digit is left to right. (b) A model with no pack shows the host alone, no pebble; a model with no lesson shows no strip; no exception on any board. (c) A Hebrew title of 35 letters with niqqud (65 characters) stays on one line inside the board on all four boards. (d) Back: one language on goes to the map, several go to the doors (`door-eng`, `door-rus` again). (e) The developer's `course_path_test` (16), `course_home_test` (15) read and run green |
| 2 | Starting a lesson from the home on `LessonScreen` in the course's pack; celebration; back on the home with the path moved on | **PASS** | `course_visit_test` (9, green in the full run; I read the lesson test): lesson `eng.hello_1` on `LessonScreen(course: 'eng')`, three right answers, the course's own celebration, back on the home, `stone-1` is a star, the next title is the next lesson, the visit row is `lesson:eng.hello_1` ended `finished`, three attempts of pack `lang-eng`. A lesson left half way: the lesson stays next, no star, no debt. A second touch while a visit is on screen starts nothing. No tutor line after mistakes. A missing pack shows "not ready", never another course |
| 3 | Parent progress: "we start here: level N" per strand, mapped from the placement strands | **PASS** | `language_start_level_test` (11): the table of section 4 equals the strand codes of the three syllabi (read from the files), a strand has one level, English writing alone has none, beginner = level 1, a strand not stopped shows nothing, Hebrew's two strands and Russian's five are placed apart. `language_courses_provider_test` line 260: through the provider the page's strand reads "level 3". The page draws it (`language_pages.dart` `_fillN(strand.startLevel!)`, `languages_parent_test`) |
| 4 | The guards of the lands on course visits | **PASS** | See section 3 |
| 5 | A provider-level test of `languageCoursesProvider` on a real database | **PASS, with a note** | `language_courses_provider_test` (14): a `ProviderContainer` over the rig's real drift database (the real schema, in memory; not the encrypted file) and the fixture packs: courses in the doors' order, an engine for each holding only its own skills, the placement replayed into the staircase, the skills below the entry assumed and known at about 0.85, probes as evidence, a beginner stopped at once, a visit cut short assuming nothing, the questionnaire reaching the staircase, courses and children never mixing, the readers (home, progress, Today's Adventure) agreeing. The encryption of the database file is outside it (covered by the storage tests, not by this one) |
| 6 | Today's Adventure opens a language stop | **PASS** | `todays_adventure_course_test` (6): the bottle opens the home and the stop's lesson starts, the child ends on the home, the stop is played once, the placement visit goes first while due, rest hours show the rest scene instead, the revisit and replay kinds dispatch to the course's mission and lesson |
| 7 | Goldens on four boards, analyzer, format, whole suite, PLAN.md | **PASS** | Section 4. Analyzer, format and the suite are in section 1. PLAN.md: not read for this record (the orchestrator commits it) |

## 3. The guards (criterion 4)

| Guard | Verdict | Proof |
|---|---|---|
| Rest hours stop a course visit (placement visit, lesson), the doors and the home stay open | **PASS** | `course_guards_test`: at 22:00 the home opens with its invitation, the pebble shows the rest scene, no session and no attempt is written, back returns to the home, and again as often as the child asks; the same through the doors and for a lesson. With the lock off the visit starts. At noon it starts |
| The daily limit counts all time played today | **PASS** | `course_guards_test`: 50 minutes of a land lesson with a limit of 20: the course visit does not start |
| The daily limit passing during a course lesson ends it between activities | **PASS** (mine) | `qa_l_course_test`: limit 5 minutes, the clock advanced 6 minutes in the first activity: after the answer the guide says goodbye, the visit row ends `limit` (not `finished`), the child is on the home, no star |
| A language switched off while its home is open cannot be started | **PASS** | `course_guards_test`: after `setSwitches(... const LanguageSwitches())` the pebble starts nothing, writes nothing |
| The microphone: app voice AND the language's own voice, both off by default | **PASS** | `course_guards_test`: app voice on, language voice off: no mic; both on: mic. Mine: language voice on, app voice off: no mic; a language starts with `voice` false (`const LanguageSwitches().voice`, also with `on: true`). `LessonScreen._voiceAllowedIn` fails closed while the settings load |
| No tutor in a course | **PASS** | `course_visit_test`: no tutor line after three mistakes |
| One course per visit | **PASS** | the launch, the pack, the engine and the mission are the course's (`courseMission`, `startCourseVisit`); `language_courses_provider_test` mixes nothing across courses or children |

## 4. The goldens read (Read tool, each PNG opened)

All 11 `course_home_*`: `eng_invite` on the phone, the SE, tablet landscape and tablet portrait; `heb_path` on all four boards;
`eng_path_phone`, `eng_round_phone`, `rus_revisit_phone`. (The old `languages_course_home_phone.png` is deleted, with the placeholder it showed.)

Found: no overflow stripe, no cut text, nikud intact (the title "חֲרוּזִים" and the bubble); the pebble is in the middle of the board on every
board; the host is above the strip and the strip is under the host's feet; in English and Russian the done and placed stones are to the
left of the pebble and the later ones to the right; in Hebrew the done star is at the far right, then the placed star, the pebble, then 4
and 5 to its left (the trail dots on the start side of each stone follow the direction); digits are not mirrored; no red; no word of
result; the invitation bubble's tail points at the host's head on every board. The pictures keep their aspect ratio (parrot, hamster,
giraffe).

Looked at and fine but tight: on the phone the title pill's bottom is 9 pt from the board's edge (`course_home_eng_path_phone`,
`_eng_round_phone`); on the tablet portrait the strip runs over the island's rim (`heb_path_tabletPortrait`, stone 5 at the left edge of
the green, `eng_invite_tabletPortrait`, stone 4 at the right): both are the numbers the builder flagged for the design pass.

## 5. The merge in `app/lib/world/language_placement.dart`

`placementVisitFor` now returns null when `placementLessonFor` does. **Correct.** `placementLessonFor` returns null exactly when the flow is
not due (`game.complete`), and `PlacementGame.complete` is "every strand stopped", which is exactly "`game.next()` is null with nothing
done in the visit" (a strand is stopped when its `next` is null), so the two null conditions are the same and the extra guard
`game.next() == null` in `placementVisitFor` is redundant, not wrong. Tests (mine, `qa_l_course_test.dart`): a child who has not begun gets a
visit with the lesson id `placement-eng` whose one item is the game's `next()`, and asking twice moves nothing (`first()` does not advance
the staircase); a finished placement gives no visit and `placementLessonFor` of a flow over the same game is null; a visit cut after one
right answer gives a visit that starts at another probe (an answered probe is never asked twice) with the strand still running.

## 6. Notes (not defects) and what I could not check

- **N-LC-1.** The bell on the pebble when a check is due (`course-bell`, `Icons.notifications_rounded`, golden `course_home_rus_revisit_phone`)
  reads as a "notification" badge. The plan says no debt and no guilt; a bell is the usual "you have something waiting" mark. Neutral in
  itself, but the design-director and the curriculum-expert should confirm it is the cue they want (a star or a seedling would not read as owed).
- **N-LC-2.** The plan (D-3) says "the host stands at the start of the path"; the build puts the host in the middle above the strip (section 9
  of the plan says so). The invitation and the title are Hebrew in every course (draft line, voice to come with B-45).
- **Not checked:** the real phone and a child's hands; sound (the hello and invitation clips do not exist yet); a revisit played through the
  screen from a really due check (the plan defers it: it needs days of history); real packs (the screens ran on fixtures); the language
  database's encryption (outside the provider test); `PLAN.md` was not read.

## 7. Files

New: `app/test/qa_l_course_test.dart` (29 tests, all pass), this record. The L4 additions are in `docs/qa/l4-languages-verification.md`
section 10 and `app/test/qa_l4_reverify_test.dart`. No product file is touched.
