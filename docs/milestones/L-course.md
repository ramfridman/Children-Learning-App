# L-course: the course screens (the course home, starting a lesson, "we start here", the guards, Today's Adventure)

**Status:** the owner approved the whole Languages frame and its milestone order on 2026-11-03 (`docs/languages/frame.md` section 8), and on 2026-11-04 asked to "work on the parts that aren't built yet". That approval covers this plan: the course screens are the part of the frame (sections 1.2 to 1.4 and 3) that L0 (section 9, "the course home is a placeholder") and L4 (section 7, "the course screens that start a placement visit or a lesson") left for later. Branch `languages-course-home`, cut from `languages-l4` (117769e). QA of L4 runs in another worktree; its fixes are merged into this branch later, so no L4 template file is edited here (the one change to the lesson screen is listed in section 6).

This plan follows `docs/languages/frame.md` (1.2 choosing a language, 1.3 the voices inside a course, 1.4 parent progress, 3.2 placement, 3.5 session shape, 3.7 Today's Adventure), `docs/milestones/L0.md` (sections 9 and 11), `docs/milestones/L4.md` (sections 7 and 9) and the approved island and doors (`docs/design/languages-island.md`). Where the build differs from PLAN.md, PLAN.md is updated in the same commit.

## 1. Goal and "done when"

A child who opens a language door finds the course's own home: the host, the path of the course's lessons, and one big button for what comes next. The first time, the host invites the child to a "visit" (the placement game); afterwards the path opens at the placed level. The button starts a lesson on the lesson screen, in that course, and after the celebration the child is back on the course home. A parent sees "we start here: level N" per strand. Every guard the lands have applies to a course lesson. Today's Adventure can open a language stop, and the course's next lesson starts.

There is no real content pack yet. Everything is built and proved on **fixture packs** made of a few real Band A items of each course (`docs/languages/*/band-a-content.md`) with the approved pictures of `content/languages/pictures`; the real packs will make the same screens work with no change.

Acceptance criteria, reported one by one at the end:

1. **The course home** replaces the placeholder (`CourseHomeScreen`). It shows the host, the course's path of lessons (in the course's reading direction, nothing mirrored that must not be) and what is next. First visit, or no placement yet: the host invites the child to the placement game (LS13, `placementIdFor(course)`); a parent's questionnaire answer sets where the staircase starts. After placement the path opens at the placed level. Revisits and the session shape follow frame section 3.5. One course per visit. Back returns to the doors, or to the map when only one language is on.
2. **Starting a lesson** from the course home on `LessonScreen` with the language flow L4 built (the course's pack, the placement flow, a revisit mission). The celebration shows, then the child is back on the course home with the path moved on.
3. **Parent progress:** "we start here: level N" for each strand, mapped from the placement strands (`o`, `l`, `c`, `1` to `5`) to the progress strands, per the frame and each syllabus.
4. **The guards of the lands, applied to course lessons:** the rest-hours check (time rules) before any course visit starts; a language that was turned off or whose pack is gone cannot be started; the microphone only when the parent turned voice on for that language; no tutor. The doors and the course home stay open during rest hours, as the lands' map and island do; the lesson, the placement visit and a revisit do not start.
5. **A provider-level test** of `languageCoursesProvider` with a real database and the fixture packs (the line that joins the staircase, the replay, `assumedSkills` and `Engine.assume` was not tested as one).
6. **Today's Adventure** opens a language stop: the course home opens and the stop's own visit starts (the placement first when it is due, as a land's warm-up goes first).
7. Goldens on the four boards (phone, phone SE, tablet landscape, tablet portrait) for the course home, looked at as pictures. Analyzer clean, format clean, the whole Flutter suite green; PLAN.md updated.

## 2. The decisions this plan makes (none needs a new answer from the owner)

| # | Decision | Why |
|---|---|---|
| D-1 | One `CourseHomeScreen(childId, course)` for the three languages, built from a pure model (`CourseHomeModel`) so that the same view draws a golden from fixed values. | The three courses differ in the host, the script and the direction, not in the screen. |
| D-2 | The **path** is the lessons of the course's pack in path order (`landPath(content, 'languages')`, the order a land's pebble and Today's Adventure already use). A stone is `done` (finished at least once), `placed` (every skill of the lesson is below the child's entry point, so the placement made it known), `next` or `later`. Nothing is locked, grey or counted against the child, and a stone is not a button: the one big pebble starts what is next, as in a land. | Frame 1.2 (no lock, no scarcity); the land pattern (play pebble); the warm-up of a land does the same for `placedLessons`. |
| D-3 | The strip of stones runs in the **course's reading direction**: Hebrew from the right, English and Russian from the left (a `Directionality` of the course round the strip, so a horizontal list starts on the right side). A stone's number is a digit (digits never mirror); a lesson title is an isolated Hebrew run. The host stands at the start of the path. The rest of the screen (back pebble) keeps the app's right-to-left layout. | "In that course's reading direction for any labels, with nothing mirrored that must not be". |
| D-4 | **What is next** is decided by the rule of Today's Adventure (frame 3.7) run on this course alone: its lessons, its due checks and its own visits (`courseStopFor`). So a revisit comes first once a day, then new lessons, then the lesson played fewest times, and a lesson left after an error rests until the next day. | One rule in one place: the bottle and the course home can never disagree (the land's pebble and the bottle already share `nextOnPath`). |
| D-5 | **Placement.** The course has a placement game when its pack has a placement document. The home invites to it (the host's bubble, and the pebble starts it) while the game has a strand that has not stopped: the strands run across the first visits, at most about 8 probes each (frame 3.2). A visit is a mission lesson with the placement id and the staircase as its flow (`placementLessonFor`, `PlacementFlow`). It is never forced: a child who goes back and comes again is invited again, and nothing says what was found. | Frame 1.2 ("the first activity") and 3.2. |
| D-6 | **After placement** the skills below each strand's entry point are assumed (L4). The lessons whose skills are all assumed show as `placed`, and the path's next stone is the first lesson that is neither finished nor placed (`placedLanguageLessons`, the course version of `placedLessons`). The adventure rule gets the same set, so the bottle and the pebble agree. | "After placement: the path opens at the placed level." |
| D-7 | **Session shape (frame 3.5).** A visit is one course: the lesson, the placement visit and the revisit mission each serve only the course's own items (the mission is built from the course's engine, its celebration is the course's own lesson line). The warm-up (chant and retrieval), the delight segment and the repair are the lessons' own content (the teachers' fixed lessons and L4's templates); an engine-planned visit (`SessionBuilder`) is not used by the lands either, and stays deferred. The visit ends on its own celebration, with no "one more?". | The app plays authored lessons and revisit missions; the builder is the simulator's. |
| D-8 | **One launch function** for every visit (`openVisit`, `app/lesson_launch.dart`): it asks the time rules first (rest hours, schedule, daily limit), shows the rest scene instead when time is up, checks that the language is still on and installed, and only then opens `LessonScreen`. The map's own `_openLesson` uses the same function, so the lands and the courses cannot drift. | QA's L0 record: the doors bypass rest hours. |
| D-9 | `LessonScreen` gets one optional `course` (default `core`): a language lesson reads the course's pack (`languagePacksProvider`), not the starter pack. Nothing else of the lesson screen changes, except that the microphone also needs the language's own voice switch. | The only edit outside the new files; the L4 templates are untouched. |
| D-10 | **Today's Adventure.** A stop in a language opens the course home with the stop (`CourseHomeScreen.start`), and the screen plays that stop at once through the same function as the pebble: the placement visit first when it is due, then the lesson, the replay or the revisit. The route stack is the bottle's, so Back returns to the child's home. | Frame 3.7; a land's stop plays its warm-up first. |
| D-11 | **"We start here: level N"** (`StrandProgress.startLevel`) is `entry + 1` of the placement strand that places the progress strand (table in section 4). A strand that has not stopped shows nothing. | Frame 1.4. |

## 3. Work split (one commit each)

| Part | What | Where |
|---|---|---|
| 1 | This plan | `docs/milestones/L-course.md` |
| 2 | The course home: path, placement invitation, what is next; the fixture packs; goldens | `child/course_home.dart`, `world/course_path.dart`, `world/adventure_adapter.dart`, `world/language_placement.dart`, `app/language_providers.dart`, `test/support/course_packs.dart` |
| 3 | Starting a lesson, a placement visit and a revisit from the home, back to the home | `play/lesson_screen.dart` (`course`), `app/lesson_launch.dart`, `child/course_home.dart` |
| 4 | Parent progress: "we start here" | `parent/language_progress.dart`, `app/language_providers.dart` |
| 5 | The guards on course visits | `app/lesson_launch.dart`, `play/lesson_screen.dart` |
| 6 | The provider-level test of `languageCoursesProvider` | `test/language_courses_provider_test.dart` |
| 7 | Today's Adventure opens a language stop | `app/app.dart` |

After every part: `flutter analyze`, `dart format --set-exit-if-changed .`, the affected tests, the new goldens looked at. At the end: the whole `flutter test` once. The gateway is not touched (no Deno change, no migration): placement answers and course answers are the rows L4 already writes and syncs.

## 4. The map from placement strands to progress strands (D-11)

The placement strands are the staircases of the placement document (frame 3.2); the progress strands are the lists of skills the parent page shows (`languageStrands`, the skills' `strand` field).

| Course | Placement strand | Progress strands that show its level | Source |
|---|---|---|---|
| eng | `o` oral (listening, then chunks) | listening and speaking (`lis`, `spk`) | English syllabus 6.3: O levels run A-01 to B-10 |
| eng | `l` literacy (offered on the questionnaire and Band B or C) | sounds and letters (`pa`, `ph`) and reading (`rd`); not writing: no probe asks it | English syllabus 6.3: L levels run letter sounds, CVC reading, digraph words, a sentence |
| heb | `l` oral language and phonological awareness | oral language and sounds (`ol`, `pa`) | Hebrew syllabus 9: the L strand |
| heb | `c` the code | letters, reading and writing (`pk`, `dec`, `wr`): the page has one strand for the code, and the C strand is that strand | Hebrew syllabus 9: the C strand |
| rus | `1` understanding | understanding (`lis`, `spk`, `voc`, `grm`, `num`) | Russian syllabus 7.3 |
| rus | `2` sounds | sounds (`pho`) | |
| rus | `3` letters | letters (`let`) | |
| rus | `4` reading | reading (`rea`) | |
| rus | `5` spelling | writing (`wri`) | |

A progress strand that no placement strand places (English writing) shows no level. The level shown to a parent is `entry + 1` (the staircase's floor is level 1). A test reads the three syllabi's strand codes and checks the table covers every placement strand.

## 5. Security and child-safety items (for the qa-engineer; the security-engineer reads the guards)

1. **Rule 2, ids and enums only.** Nothing new is stored or sent: a course visit writes the attempts and the visit L4 and the lands already write (`lesson:<id>`, `mission:<skill>`, answers of the placement lesson id). The course home reads, and writes nothing.
2. **Rule 5, the tutor.** No tutor line is ever asked in a course visit (L0: `llmAllowed` is false for a language item, the controller never calls the tutor for one). Proved again by a visit from the home.
3. **Child safety.** The microphone opens only on a tap and only when a parent turned voice on **for that language** (the global switch alone is not enough in a course). No timer, countdown, streak or guilt is anywhere in the new screen (the source rule over the child files covers it); an unfinished lesson is never shown as a debt; no result of the placement is shown. The rest hours stop a visit before it starts, and the daily limit ends it between activities, exactly as in a land.
4. **One course per visit.** The mission, the stop and the lesson of a course are built from that course's pack and engine only; the launch function refuses a course that is off or not installed.
5. **The doors.** Opening a door never starts a visit and never plays a clip; rest hours are checked where play starts.

## 6. What changes outside the new files

- `play/lesson_screen.dart`: the `course` parameter and the language voice switch (D-9). The six L4 templates and `ChoiceSession` are not touched.
- `app/app.dart`: the map's `_openLesson` uses `openVisit`; the doors and the bottle open `CourseHomeScreen`.
- `child/languages_doors.dart`: the placeholder `CourseHomeScreen` is removed (the screen moves to `child/course_home.dart`).
- `world/adventure_adapter.dart`: `LanguageCourse` also carries the skills the placement assumed and the state of the placement; `visitsFrom` may be given no starter pack (a course alone).
- `parent/language_progress.dart`: the table of section 4.

## 7. What is deferred, and why

- **Real content packs** (ENG-1, HEB-1, RUS-1): the screens are proved on fixtures.
- **An engine-planned visit** (frame 3.5 with `SessionBuilder`: warm-up, repair, focus, revisit checks and delight chosen by the engine): the app plays authored lessons and missions today (D-7).
- **The path's own art** (the design-director's stones, a trail drawn for each host): the stones are drawn from tokens and flagged for the design pass.
- **The hello clip and the host's invitation clip** (no recordings yet): the invitation is a bubble with a draft line; the voice comes in the B-45 batch.
- **Moving the placed level by one** (frame 1.4: "the parent may move it one level"): a later control; the page shows the level only.
- **Stones that start a replay** (a tap on a finished stone): the pebble and the bottle replay the lesson played fewest times.

## 8. Report format

Per part: file and line, the tests and their results, the goldens (with their hashes), the commit hash, the `needs-editor` strings, and what is deferred.

## 9. Built

### Part 2: the course home (`child/course_home.dart`)
- **The screen.** `CourseHomeScreen(childId, course)` replaces the L0 placeholder (the old golden `languages_course_home_phone.png` is removed). It is a consumer over `courseHomeProvider` and draws `CourseHomeView`, which takes a `CourseHomeModel` and an optional `onPlay`, so the goldens draw it from fixed values. The board is the door screen's (island of the Languages colours, back pebble at the start corner); the host stands in the middle, the strip of stones runs along the lower part, and the next stone is the big pebble standing under the host's feet, with the lesson's title under it. The numbers (`_HomeSpec`) are mine, for the design-director's pass.
- **The path.** A horizontal list under a `Directionality` of the course (`Course.readsRightToLeft`): Hebrew starts at the right, English and Russian at the left; it opens with the next stone in the middle and is padded so the first and the last can stand there. A stone is a star (done), a hollow star (placed) or its number (a digit, always left to right). Stones are not buttons.
- **The model** (`world/course_path.dart`, pure): the stones, the next index, the stop (`courseStopFor`, `world/adventure_adapter.dart`: Today's Adventure on this course alone, this course's visits only) and whether the placement is due. `LanguageCourse` now carries the skills the placement assumed and a `PlacementStatus`; `languageCourseOf` builds it (`app/language_providers.dart`, the old `_engineOf`).
- **Placement helpers** (`world/language_placement.dart`): `placementGameFor` (the game with the child's answers replayed), `PlacementStatus`, `placedLanguageLessons`.
- **No way to start yet.** The pebble is drawn only when `onPlay` is given (part 3); without it the next stone is a big stone with its number.
- **Files:** `app/lib/child/course_home.dart`, `app/lib/world/course_path.dart`, `app/lib/world/adventure_adapter.dart`, `app/lib/world/language_placement.dart`, `app/lib/app/language_providers.dart`, `app/lib/engine/course.dart`, `app/lib/strings/he.dart`.
- **Tests:** `test/course_packs_test.dart` (the three fixture packs pass the validator), `test/course_path_test.dart` (16: the path, finished lessons, placement, the rule), `test/course_home_test.dart` (15: the view, the direction of each course, the app's doors and map), `test/golden_course_home_test.dart` (11 goldens: the invitation on the four boards, the Hebrew path on the four boards, and English, Russian with a check due, and a path gone round on the phone). Fixtures: `test/support/course_packs.dart` (a few real Band A items of each course, real pictures), `course_history.dart`, `course_home_model.dart`.
- **Strings (all `needs-editor`):** `courseInvite` ("בּוֹאוּ נֵצֵא לְבִקּוּר קָטָן!"), and the screen-reader labels `courseVisitSemantics`, `courseNextSemantics`, `courseStoneDoneSemantics`, `courseStoneNextSemantics`, `courseStoneLaterSemantics`, `coursePathSemantics`.

### Part 3: starting a visit from the home
- **The pebble** (`child/course_home.dart`, `CourseHomeScreen` is now stateful) calls `startCourseVisit` (`app/course_visit.dart`, which the child folder cannot hold: it reads the parent's switches): the next placement visit while the host invites (`placementVisitFor`, the game with the child's answers replayed, so a visit goes on where the last ended), otherwise the stop of the rule: a revisit mission built by `courseMission` (the course's own items from the child's engine on the course, ended by the celebration line of a lesson of the course that teaches the skill) or the lesson. One touch at a time: a second touch while a visit is on screen starts nothing.
- **`openVisit`** (`app/lesson_launch.dart`) is the one place that pushes `LessonScreen`; **`LessonScreen.course`** (default `core`) makes a language visit read that course's pack from `languagePacksProvider`; a course whose pack is missing shows "the lesson is not ready", never another course's content. The L4 templates are untouched.
- **After the visit** the screen invalidates the rewards, the courses and its own model: a finished lesson becomes a star, the pebble moves to the next stone (the stones' scroll animates, or jumps with reduced motion). A lesson left half way writes a visit that ends `home` and no debt shows: the lesson is simply still next. The map's own `_openLesson` is not changed yet (part 5).
- **Tests:** `test/course_visit_test.dart` (9: the placement visit from the invitation and its continuation, a lesson played to its celebration with its attempts and visit rows, a lesson left half way, a double touch, no tutor line after three mistakes, a missing pack, the mission, the next placement visit). Support: `test/support/course_flow.dart`.
- **Deferred:** a revisit visit played through the screen (a due check needs days of history; the mission and the stop are tested apart); the ceremony of a trophy or medal that a course visit earns waits in the Hall (the map looks at awards when it opens).

### Part 4: "we start here: level N" (`parent/language_progress.dart`)
- `placementStrandOfCode` is the table of section 4 (code to placement strand); `startLevelOf` reads the level of a progress strand from the child's `PlacementStatus` (`entry + 1`; null while the strand has not stopped, was not offered, or no placement strand places it). `buildLanguageProgress` takes the status (`placement:`), and `languageProgressProvider` passes the course's. The page already showed the line when a level was given (L0 section 9).
- **Tests:** `test/language_start_level_test.dart` (11: the table is consistent and equals the strands of the syllabi, which are read; English writing alone has no level; levels from fixture placements in each course).

### Part 5: the guards
- **`openVisit`** (`app/lesson_launch.dart`) now returns a `VisitOutcome` (`played`, `left`, `rest`, `refused`) and does, before any lesson screen: (1) a language course must be on for the child and installed (`languagesAvailableProvider`), else `refused` and nothing is shown or written; (2) the time verdict is asked afresh (`timeVerdictProvider`): when it is locked the rest scene shows and no visit begins. The map's `_openLesson` (`app/app.dart`) uses it too, so a land and a course cannot drift; its follow-ups (refresh, ceremony, the friends' offer) are as they were.
- **The microphone:** `LessonScreen` makes the voice only when the app's voice is on and, for a lesson of a language pack, that language's own `voice` switch is on (`_voiceAllowedIn`); the course's switches are read before the lesson opens.
- **Already in place and proved again:** the daily limit ends a visit between two activities (`LessonScreen._timeIsUp`, for any pack); no tutor in a course (part 3); personal turns follow their switch (L4); one course per visit (the launch, the pack and the mission are the course's).
- **Tests:** `test/course_guards_test.dart` (8: rest hours for the placement visit, the lesson and through the doors, the lock off, noon, the daily limit counting land time, a language switched off while its home is open, the mic with the language's voice off and on). `rest_rules_test.dart`, `warm_up_flow_test.dart` and the lesson flow tests pass unchanged through the refactor.
