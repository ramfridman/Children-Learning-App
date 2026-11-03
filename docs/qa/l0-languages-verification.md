# QA record: milestone L0, the Languages category shell

Date: 2026-11-03. Verified by: qa-engineer. Branch `languages-foundation`, worktree `D:\nitznutz-langbuild`, head `f5d348a`
(before this record). Plan: `docs/milestones/L0.md` (section 1 "done when", section 9 the screens). Design: `docs/design/languages-island.md`.
Texts: `docs/languages/island-texts.md`. Security records: `docs/security/findings.md`, `docs/security/private/L0-languages-review.md`.

**Verdict: PASS for the engine core and the screens, with four minor defects (QA-L0-1 to QA-L0-4, each with a failing test that
is skipped until the fix) and two notes for later milestones.** Nothing blocks the merge of L0 itself. One release note: see
"Release notes" (a new child gets the island, and every door opens an empty placeholder).

## 1. What ran

| Command | Result |
|---|---|
| `flutter analyze` (in `app/`) | No issues found |
| `dart format --output=none --set-exit-if-changed .` | 397 files, 0 changed |
| `flutter test` (whole suite, once, before my test files were added) | **+3366 passed, 0 failed, 3 skipped** (18 min). The three skips are old: two open-defect proofs behind `QA_OPEN` from earlier milestones and one Windows-only voice-tool test |
| My four new files together: `qa_l0_doors_test`, `qa_l0_map_geometry_test`, `qa_l0_rules_test`, `qa_l0_open_defects_test` | **+30 passed, 0 failed, 8 skipped** (the 8 are the open-defect proofs) |
| The same open-defect file with `--dart-define=QA_OPEN=true` | **8 of 8 fail**, as they must until the fixes |
| `deno fmt --check`, `deno lint`, `deno check --frozen supabase/functions/ tools/gen-testvector.ts`, `deno test` (Deno 2.9.6 from the scratchpad copy) | fmt 108 files ok, lint 106 files ok, check ok, **198 passed, 0 failed, 7 ignored** (the 7 need a database) |
| pgTAP, from CI: run 41656301221 on `f5d348a`, all jobs green (`gh run view ... --log`) | `database (Supabase local + pgTAP)`: Files=10, **Tests=220, Result: PASS**; `07_prizes_ribbons` ok and `10_language_settings` ok. pgTAP was not run here (no Docker) |

The full run is of the branch as built. The four QA files were added after it; they are new files and change no product file,
so the sum is 3366 + 30 passed and 3 + 8 skipped. I did not run the full suite a second time.

## 2. Acceptance criteria of L0 section 1

| # | Criterion | Verdict | Proof (tests that ran green) |
|---|---|---|---|
| 1 | F4, the course id on skills, items, tags, placement, progress, packs, the synced answer; core unchanged; one signed pack per course | PASS | `course_test.dart` (schemas, dotted ids, language tag ids, progress blocks per course, placement ids per course, a mission's course), `course_pack_test.dart` (a core pack's manifest has no `course`, so its bytes are as they were; `lang-<course>` built, installed and loaded; two courses side by side; a newer version replaces the old; a name that is no language refused), the starter-pack byte tests in CI (6 parts green) |
| 2 | Validator invariants of frame 1.5 on a small fixture course | PASS | `course_invariants_test.dart`: 27 broken-pack cases, each with its path and reason (pack id `lang-<course>`, a document of another course, a skill, a prerequisite, an evidence line, a misconception, a tag, `contradicts`, a repair activity, a lesson, a gate, domain, id prefix, roll-up rules, AI tutor off), plus the merged catalogue (`courseProblems`, `mergeCatalogs`) |
| 3 | F9 engine additions as pure functions | PASS | `engine/language_engine_test.dart` groups: presentation band vs content level (3.1), sub-skills and roll-ups (3.3.2), letter bundles (3.3.3), set coverage (3.3.4), the sound-right outcome (3.3.5), course gates (3.3.6), one course per visit (3.5); `todays_adventure_languages_test.dart` (a language is a land; a course that is off is not) |
| 4 | Per-child, per-language settings: stored, synced, ids and enums only, re-checked on the server, deleted with the child (device and server, migration, pgTAP) | PASS | `language_settings_test.dart` (defaults, only differences stored, order, switches of one course refused on another, 6 children, damaged documents dropped, the shared vectors `testvectors/language-settings.json`, delete with the child), `sync_engine_test.dart` (a family that never touches a language syncs the document it did before; the document travels; a stale phone takes the server's), Deno `settings-put` tests, migration `20261103120000` read against the old `app.delete_child` (identical but for the one added statement), pgTAP `10_language_settings` ok in CI |
| 5 | `tutor-turn` refuses language items; the app never asks | PASS | Deno `tutor_turn_test.ts` (`lang-eng`, `lang-heb`, `lang-rus`, `lang-xyz`; items whose skills start `ENG-`, `HEB-`, `RUS-` under another pack id; model, voice, cache and family caps untouched; the lands still get a line), `language_tutor_test.dart` (`llmAllowed` false outside core, no question and no prefetch, a `course_not_allowed` answer is no fault). Also `content-publish` refuses a `lang-` pack and any `ENG-`/`HEB-`/`RUS-` skill under any pack id (Deno `content_publish_test.ts`, SEC-L0-4) |
| 6 | Sync of the course id is additive; the wire patterns widen; a mismatch is dropped | PASS | `wire_format_test.dart`, `sync_engine_test.dart` ("an answer whose skill, pack, tag and course do not say the same course is not taken in": 10 forged events incl. the two activity-id ones, 1 good taken; the pure rule field by field; an older phone's answer with no course), Deno `sync_test.ts` |
| 7 | Analyzer, format, whole Flutter suite and Deno suite green; PLAN.md updated | PASS | section 1 above; `docs/PLAN.md` carries L0 in Controls (line 513), Courses (671), the language additions (681), the course on the wire (787) and "Not in a language course" (809) |

## 3. The screens (L0 section 9) and the checks you asked for

| Item | Verdict | Evidence |
|---|---|---|
| **Courses never mix**: validator invariants | PASS | table in section 2, row 2 |
| **SEC-L0-1 regression**: replay of a mismatched activity id | PASS | `course_test.dart` "SEC-L0-1" group: a core answer with a language activity id is no evidence (6 answers, no skill started); the course's own answer, and one with no course, is; `eventOf` gives each row its pack's course (`lang-xyz` matches no item); the core engine replays only its own rows; the English engine ignores core rows with the same id |
| **SEC-L0-1 regression**: pull of a mismatched activity id | PASS | `sync_engine_test.dart` events `a` and `b` (activity id of one course, every other field of the other) are dropped, only the agreeing event is applied; `Course.ofAnswer` read field by field |
| SEC-L0-2, -4 | PASS | gate without its course refused (`course_content_test.dart`); `content-publish` 400 for a language skill (Deno) |
| SEC-L0-3 | PASS, can close | `MAX_RULES_BYTES` 10,000 at the gateway (Deno); the pgTAP case that stores the 9,902 byte document is in `10_language_settings.test.sql` and CI passed it |
| **Nothing changes when every language is off** | PASS | `git diff 075bfc9~1 HEAD -- app/test/goldens`: of the 7-land goldens only `parent_area_tablet_portrait.png` changed (the new "Languages" button of the child's row, looked at below); every `home_*` 7-land golden is byte for byte what it was; the 7-land map keeps its scroll key `home-map`; every sign is there and there is no `sign-languages` or `land-tap-languages` (`languages_map_test.dart` on 4 boards); the family's rules document has no `languages` key (`sync_engine_test.dart`); a child with no language gets the 7-land map even when a sibling has all three (`qa_l0_rules_test.dart`) |
| **The 8-land map on all four boards at 1.0 and 1.3** | PASS | `qa_l0_map_geometry_test.dart` (4 boards x 2 text scales, plus 2 long-name cases on the phones), numbers in section 4; renders at 1.3 with a long name read for the four boards |
| Tap areas at least 64, gaps of 16 or more | PASS | all 8 tap areas are 160 high and 196 to 240 wide on every board; smallest gap 16 (landscape: robots/market), 26 (SE), 40 (phone), 60 (portrait), at both text scales |
| B-42 welcome band | NOT ON THIS BRANCH | no commit, no `welcome` band in `home_screen.dart`. What I measured is the map's own speech bubble (B-26), at its widest (a 17 letter Latin name at 1.3). Re-measure when B-42 is merged into this line |
| **The doors**: order, one language opens directly, no locked door | PASS | `languages_map_test.dart` (4 boards: English at the right, then Hebrew, then Russian, however the settings were made; two doors in the same order; a language that is off has no door at all; one language on opens the course at once and back returns to the map; a door opens a course home that lists nothing and back returns to the doors as they were); the goldens |
| Hello fonts and locales | PASS | English and Russian are `TargetText` in `NitznutzLetters`, `Locale('en')` and `Locale('ru')`, no stress mark; Hebrew is Heebo, RTL, line height 1.7; the hello words are excluded from semantics, the label is the language's name |
| **Reduce motion** | PASS (new test; the builder's tests never saw it) | the test rig turns reduce motion on for every screen, so the builder's door tests and goldens never ran a pulse. `qa_l0_doors_test.dart` runs both: with reduce motion the cross-fade is `Duration.zero`, the open art shows at once, no bubble ever scales, the idle pulse never starts, and the course still opens 600 ms after the tap; with motion the cross-fade is 200 ms, the bubble pulses to 1.06 and back in 240 ms, the gold ring (4 wide) shows, the idle pulse comes once after 10 s, from the start (English, Hebrew, Russian), peaks at 1.06, and never again in the next 60 s; a tap before 10 s ends it |
| Nothing on the door screen counts | PASS | the only texts are the title and the three greetings, no digit (`qa_l0_doors_test.dart`) |
| **Parent pages**: switches, questionnaire | PASS | `languages_parent_test.dart` (the card per child, state in words, the row opens the page, per-course switches, Hebrew's voice line without the download sentence, every switch saved, band back to age, the page's title, the progress page) and the goldens |
| Progress by strand, with the strand-mapping fix `f5d348a` | PASS | `language_strands_test.dart` reads the skill tables of the three syllabi and checks every strand code has a named strand (English `lis spk pa ph rd wr`, Hebrew `ol pa pk dec wr`, Russian `lis spk voc grm num pho let rea wri`); Hebrew `pa` with oral, `pk` and `wr` with code; Russian `lis spk voc grm num` with listening and speaking; a code is in one strand only |
| No streaks or comparison words | PASS | new `qa_l0_rules_test.dart`: the 100 Languages strings of `he.dart` hold no streak, "you did not practise", ranking, score or timer word (the editor's sentence "אין השוואה לשפה אחרת או לילד אחר" names comparison to deny it and is allowed); the sources of the Languages screens name no streak, ranking, sibling, `compare`, countdown or timer. The progress golden has a legend in colour and words, a words line under every bar, speaking as "practised" or "said" with "this is not a score", and no per-language time chart |
| **The setup question**: all three pre-ticked | PASS | `languages_parent_test.dart` "the setup question": all three ticked with one line each; unticking one leaves it without a door. Read `child_form.dart`: `_languages` starts as all three |
| **Fonts**: Nitznutz Letters only through `TargetText`, licences bundled | PASS | `source_rules_m1_test.dart`: three families only; the family is named in `design/target_text.dart` only; no other file uses `targetFontFamily`; both TTFs, `OFL-NitznutzLetters.txt` and `FONTLOG-NitznutzLetters.txt` are bundled. I also read the OFL file (copyright and Reserved Font Names kept, licence intact, "renamed under condition 3") and searched the two TTFs for "Andika" and "SIL" in ASCII and UTF-16: none |
| **The tutor**: `tutor-turn` and `content-publish` refuse language items | PASS | row 5 of section 2 |
| **Settings** sync and are deleted with the child | PASS | row 4 of section 2 |
| No new package, no new host, no secret | PASS | `pubspec.yaml` gains one asset folder; `pubspec.lock`, `network_hosts.json` and `.github` are untouched; CI green on osv and gitleaks |
| Mic and recording | PASS | the voice switch only stores the choice: after turning it on the fake recogniser has no `prepare`, no `listen`, no permission request (`qa_l0_rules_test.dart`); the Languages sources import no network, audio or speech package |

## 4. The collision numbers, re-measured on the real widgets

Design table (`docs/design/languages-island.md` section 3) against what `qa_l0_map_geometry_test.dart` measured on the app's own
home screen (the numbers are in the test output lines `QA-L0 ...`). Gaps are between sign boxes. Every real number is at or above
the design's.

| Board | Design 1.0 / 1.3 | Measured 1.0 / 1.3 | Other measures |
|---|---|---|---|
| phone | 123 / 75 (Counting and Languages) | **128 / 83** | Languages to home 145 / 119. Bubble (name "נועה") left edge 481 / 441, to the Languages sign 78 / 51. Long Latin name at 1.3: bubble 430..640, the design's widest left edge 418 and roof end 403: clear by 12 and 27 |
| phone SE | 34 / 19 | **42 / 30** | Languages to home 117 / 81. Bubble 364 / 326; long name at 1.3: left edge 372, design 313, roof 302 |
| tablet landscape | 100 / 67 (Market and Languages) | **107 / 83** | Robot Harbour and Market 93 / 67 (the design said 35 at 1.3 for these; the real gap is larger). Languages sign right edge 1144 / 1156 of 1180; the avatar is above it |
| tablet portrait | 200+ | **256 / 228** to home, 219 / 210 to Counting; tightest pair (logic, robots) 177 / 146 | Pill bottom 124; Robot Harbour's sign 52 clear at 1.0 (about 46 at 1.3) |

Tap areas: all eight are 160 high; widths 196 (Languages on landscape, to the screen edge, the edge rule) to 240; the smallest
gap between two is 16 on landscape, 26 on SE, 40 on phone and 60 on portrait, at 1.0 and 1.3. No visible sign is under the pill,
the avatar or the Parents button; no speech bubble covers any sign.

## 5. Goldens and pictures looked at (every PNG opened with the Read tool)

`home_phone_lang`, `home_phone_lang_end`, `home_phoneSE_lang`, `home_tabletLandscape_lang`, `home_tabletPortrait_lang`,
`home_tablet_portrait` (the 7-land one, for comparison), `languages_doors_phone`, `languages_doors_phoneSE`,
`languages_doors_tabletLandscape`, `languages_doors_tabletPortrait`, `languages_doors_phone_two`,
`languages_doors_tabletPortrait_two`, `languages_doors_phone_opening_heb`, `languages_course_home_phone`,
`parent_languages_list_phone`, `parent_languages_list_tabletPortrait`, `parent_language_page_eng_phone`,
`parent_language_page_rus_tabletPortrait`, `parent_language_questionnaire_rus`, `parent_language_progress_eng_tabletPortrait`,
`parent_area_tablet_portrait`. And my own renders (not committed; made with a throwaway test that writes to the scratchpad) of the
8-land map at text scale 1.3 with a long name on all four boards, and of the SE at 1.0, in
`C:\Users\ramfr\AppData\Local\Temp\claude\D--nitznutz-content\4a388da1-7f7b-422e-8f53-18c381ca669b\scratchpad\qa-shots\`.

What I looked for and found fine: no overflow stripe, nothing clipped, nikud whole on every child text (title chip, signs, bubble),
no mirrored element, the three door bubbles never touch (smallest gap between bubbles 38 on SE at 1.3), a tap target far above the
band's minimum, a colour AND a shape (window) per door, Heebo for Hebrew and the teaching font for Hello and Привет, the parent
pages in the parent style with 56 high switch rows and a state in words, the progress bars each with a words line under them,
and the Languages button in the child's row of the parent area. The phone strip has Counting Hills as the half island with its whole
sign pinned 12 inside the edge, as designed.

## 6. Defects

Each has a failing test in `app/test/qa_l0_open_defects_test.dart`, skipped in a normal run so the suite stays green. Run:
`flutter test --no-pub --dart-define=QA_OPEN=true test/qa_l0_open_defects_test.dart`. The owner of the fix removes `skip: _open`
from its test when it is fixed.

| Id | Severity | Title | Where | Owner of the fix |
|---|---|---|---|---|
| QA-L0-1 | minor now, major when a course has lessons | A back press while a door is opening is followed by the course opening | `child/languages_doors.dart` `_open` | app-developer |
| QA-L0-2 | minor | A door's tap area is a column as high as the whole board, so the friend in the corner, the grass and the sea open a door | `child/languages_doors.dart` `_DoorUnit` | app-developer, with the design-director for the hit area |
| QA-L0-3 | minor | The budgerigar's tail is cut off by the bottom edge of `door_eng.svg` and `door_eng_open.svg` | `tools/make_languages_art.py` `host_eng`, `door_svg` | design-director |
| QA-L0-4 | minor | For a child with a language on, the first frame of the map is the 7-land scene | `app/app.dart` `_map`, `app/language_providers.dart` | app-developer |

**QA-L0-1.** Steps: open the door screen with three languages on, tap a door, press the back pebble within about 500 ms.
Expected (design 4.4): "the back pebble always works", the child is on the map. Actual: `_open` waits 600 ms and then calls
`onOpenCourse` if the state is still `mounted`; a popping route keeps its state mounted until the transition ends, so the course opens
on top. With reduced motion the window is a press 300 to 600 ms after the tap; with motion on (pop about 500 ms or more) a press
at 100 ms is enough. Proof: `QA-L0-1 (reduced motion, 450 ms after the tap)` and `(with motion, 100 ms after the tap)`. Suggested fix: check
`ModalRoute.of(context)?.isCurrent` (or a `_left` flag set by the back pebble) before `onOpenCourse`.

**QA-L0-2.** The `Stack` of a door unit has only positioned children, so it takes the biggest size: the unit is as high as the
board (phone 184 x 393, landscape 264 x 820, portrait 240 x 1180; measured `door unit Rect` in the test output). On the portrait
tablet the whole friend lies under the Russian door's column, and on the landscape tablet its right 38 points do. Design 4.2: the
whole unit (bubble, door, host) is one tap target. Proof: three tests: a tap on the friend (portrait tablet), on the grass below the
doors (landscape tablet) and on the sea above the doors (phone) must open no door. Suggested fix: size the unit to the area from the
bubble's top to the door's bottom.

**QA-L0-3.** The host's 512 canvas has the tail down to y 486 and the door places it with its base at 300 of a 300 high viewBox, so
the tail reaches y 304.3 and is cut by a straight edge (visible in `languages_doors_phone.png` at the bottom right of the blue
door, and in all four doors goldens). Proof: `QA-L0-3` renders both SVGs and finds 42 blue tail pixels in the last three rows.
Suggested fix: raise the host so its feet and tail end inside the viewBox, or lengthen the viewBox; the door art for Hebrew and
Russian is not cut.

**QA-L0-4.** Proof: `QA-L0-4` records the scene of every frame after the child is picked: `[7-land, 8-land, 8-land, ...]`.
One frame of the wrong scene (a different picture and scroll key) is drawn before the settings are read. Suggested fix: wait for
`languagesProvider` where the map already waits for the friend and the guide (`CalmLoading`).

### Notes and observations (no test; not defects of L0 as planned)

- **QA-L0-5 (info).** `LanguagesNotifier.setSwitches` returns false for a seventh child (the rules document has room for six),
  and neither the Languages card (`language_pages.dart` `_save`) nor the setup form (`child_form.dart` `_save`) looks at the answer:
  the switch simply stays off, with no message. The owner's family has two children, and PLAN.md records the limit. Owner:
  app-developer, only if a bigger family is ever expected.
- **QA-L0-6 (info, text against behaviour).** `areaLangVoiceHelp` says that turning voice on "downloads the recognition model of
  {lang} to the device". In L0 the switch only stores the choice (the download is L3, as L0 section 9 says), so the sentence is
  not true yet. No course exists, so no parent can see the effect. Owner: hebrew-text-editor and app-developer, to be settled at
  L3 (or hold the sentence until then).
- **Tutor rate counter.** `tutor-turn` takes the per-device request-rate counter (60 a minute) before it refuses a language
  pack. The family caps, the config, the cache, the model and the voice are untouched (the Deno test asserts it). PLAN.md says
  "before any cap is taken": it means the family's caps. No change needed; recorded so nobody reads it as a leak.
- **Rest hours.** The door screen and the course placeholder do not go through the time verdict (`_openLesson` does, for the
  lands). With no content in L0 this is harmless. ENG-1, HEB-1 and RUS-1 must open their first lesson through the same verdict.
- **Portrait tablet, start view.** Robot Harbour's island passes under the "today's adventure" pill (its crane and robot are
  hidden; its sign stays 52 clear below the pill). The design says so in section 1.2 and the owner approved the previews; it is
  recorded because a child sees a half-hidden island at the start. Owner of any change: design-director.
- **Test rig and reduce motion.** `AppRig.pump` turns reduce motion on by default, so no existing golden shows a pulse, a ring or a
  cross-fade. My `qa_l0_doors_test.dart` shows how to turn it off for one screen.

### Release notes (for the orchestrator and the owner)

- **A new child gets the island from this build on.** Child setup pre-ticks all three languages (Q-F1), and a ticked language is "on"
  even when no language pack is installed. Every door then opens the placeholder course home: a host and a back pebble, nothing to
  play. It is as the milestone plans (section 9), and the child can always go back, but it is a dead end for a child. Existing
  children are unchanged until a parent turns a language on. Recommendation: do not put an L0 build in the children's hands until
  the first course lesson exists (ENG-1), or show the island only for a language whose pack is installed.
- **Deploy order** stays as the plan says: migration, then the four functions, then the app. L0 deploys nothing.

## 7. Not checked

The real phone and tablet (no device was connected, so no screencap and no logcat); sound (no hello clip and no companion line
exist yet); a child's hands; the on-device speed of the 8-land map; pgTAP on this machine (CI ran it); B-42's welcome band (not on
this branch); the Languages cards on the parent's rules page with every child in a real family (the golden uses one child);
`docs/phone-test-day.md` was not touched: it has no L0 step yet, and a phone script for the doors can be written when the owner asks.

## 8. Files added by this QA pass

`app/test/qa_l0_map_geometry_test.dart` (the 8-land map measured on four boards at 1.0 and 1.3, 10 tests),
`app/test/qa_l0_doors_test.dart` (reduce motion, the idle pulse, the back pebble, the bubbles on four boards at 1.0 and 1.3,
no counting words; 15 tests), `app/test/qa_l0_rules_test.dart` (no streak or guilt words, no network or recorder, the voice switch,
a sibling's languages; 5 tests), `app/test/qa_l0_open_defects_test.dart` (8 skipped proofs of QA-L0-1 to QA-L0-4), and this record.
