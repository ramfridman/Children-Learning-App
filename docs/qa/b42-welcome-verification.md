# QA verification: B-42 (the daily welcome and the name path)

2026-11-03, qa-engineer. Worktree `D:\nitznutz-b42build`, branch `b42-daily-welcome`, code as of `0a44ef8` (the two later commits, `b926ed1` and `6e3de7d`, change only `docs/security/findings.md` and `tools/check_tutor_lines.mjs`). Spec: `docs/milestones/B42.md` section 8 row 7 (my list), row 4 (the developer's tests) and the composer cases under the work table.

**Verdict: PASS. No defect found (no `QA-B42-n` filed).** Every row of row 7 and row 4 is proved by a test that ran green; 21 new QA tests close the gaps the developer's tests left; all 24 new goldens were opened and look right. Not proved here: sound itself, pgTAP, the real phone.

## What ran

| Command | Result |
|---|---|
| `flutter analyze` (`app/`) | No issues found |
| `dart format --output=none --set-exit-if-changed .` (`app/`) | 403 files, 0 changed |
| `flutter test` (`app/`, the whole suite, once, with `qa_b42_welcome_test.dart` in it) | **3351 passed, 1 failed, 4 skipped** (about 20 minutes) |
| `flutter test test/qa_b42_welcome_flow_test.dart` (written after the full run, so run alone) | 4 passed, 0 failed |
| `deno fmt --check`, `deno lint`, `deno check --frozen supabase/functions/ tools/gen-testvector.ts` (Deno 2.9.6 from the scratchpad) | all clean (115, 113 files) |
| `deno test --frozen --allow-read=testvectors,supabase,content --allow-net=127.0.0.1:54322 --allow-env` | **223 passed, 0 failed, 7 ignored** (run twice, at `0a44ef8` and at `6e3de7d`) |
| pgTAP (`supabase/tests/database/10_name_spoken.test.sql`) | not run here (needs a database); CI runs it |

The one failure is the known one: `starter_pack_test.dart` "the pack was built from the sources in content/starter and nothing else" (the sources hold `activity.b.colb01.10` and `.11`, `colb02.13` and `.14` and more that the signed pack does not yet; it waits for the owner's signed pack). The four skips are `QA-13`, `QA-14` and `QA-17` / `QA-18` in `qa_open_defects_test.dart`: QA-17 and QA-18 skip on this branch only because it does not contain B-20 (`b20-sync-fixes`), which unskips them; they run green on that branch (`docs/qa/b20-sync-verification.md`).

## Row 7: the acceptance, item by item

| Row 7 item | Proof | Verdict |
|---|---|---|
| Every reason | `qa_b42_welcome_test.dart` "every reason the app can give has a row in this test" (it fails when a reason is added to `AdventureReason`), "only the first day has its own greeting; every other reason turns with the day, on every day of three", "every reason with a stop ends with the topic or land line and the closing line; `nothing` has neither". Developer: `welcome_lines_test.dart` cases 1 to 9 (welcome, sameLand, callForHelp, otherLand, playAgain, nothing). | PASS |
| The warm-up case | `welcome_lines_test.dart` case 5; mine: "the warm-up decides the land line for a lesson only; a revisit and a replay keep their topic when it is due", "the warm-up is asked about the land of the stop, and only for a lesson". In the real app (`qa_b42_welcome_flow_test.dart`): a Band A child on the first day hears the topic of NUM-A-01, a Band B child with the warm-up due hears the land line, the same rule the Play button uses | PASS |
| An unmapped skill | case 7; mine: a skill of no row, a lesson with no skill of the land, a lesson with no id, a revisit of a skill no row names, and SHP-A-07 (listed in the land-line list) for a lesson, a revisit and a replay: all say the land line | PASS |
| `nothing` | case 8; mine: `[name, hello]` with a name and `[hello]` without, and no warm-up asked | PASS |
| The rotation over three days | `welcome_lines_test.dart` "three days in a row give the three greetings"; mine: a whole year (366 days), each of the three greetings 121 or 122 times, never the first-day line after day one. In the app: the next day brings the next greeting (`welcome_flow_test.dart`) | PASS |
| No name clip | case 3; every flow test of `welcome_flow_test.dart` but one runs with no name clip (the sentence still shows the name in its caption, and the welcome is whole), and the one with a clip (`name_spoken_flow_test.dart`, "with the clip made, the welcome says the name first and then the greeting") plays it once | PASS |
| A missing fixed clip | `welcome_flow_test.dart` "a missing clip makes the whole welcome text: nothing is played, every sentence is shown"; `welcome_hold_test.dart` "a recording that cannot start leaves the sentence in the plain hold" | PASS |
| Sound off | `welcome_flow_test.dart` "with the sound off the welcome is text" (the provider; see Noted) | PASS |
| Once a day across child switches and restarts | `welcome_flow_test.dart` "the same day, the map is the ordinary map: after a restart, and after a change of child and back", "each child has a day of their own"; mine: a change of child in the middle of the welcome (the first child's day is already written, the second child gets their own welcome, back to the first: nothing) | PASS |
| Skip on any tap | developer: friend, land; mine: the open sea (a tap at the screen's corner), the parents button, the pill (the bottle opens), a change of child, and the app leaving the front (`AppLifecycleState.paused`): each stops it at once, none brings it back, and the day stays used | PASS |
| No streak or day words in any welcome line | `welcome_lines_test.dart` word list on the screen text; mine: a longer list (days, weeks, yesterday, tomorrow, streak, again, still, no, missed, forgot, came back, points, stars, seconds, minutes ...) over **the screen text and the voice text of all 48 lines** (the `voice_text` column of `hebrew-master.csv`, which is what is heard), no digit or `!` or `?` or bracket in a voice text, no question word first and no question mark, no second person singular (no line guesses a gender) | PASS |
| Row 4: the tests it names | purity (no clock, random, I/O: `welcome_lines_test.dart`), no `{child}` (same file), only `hello.*` and `core.home.bubble` follow a name clip (`welcome_lines_test.dart`, `name_path_test.dart` "a topic, a land line, the closing line and a lesson line are refused before anything is said"), every skill of the pack resolves (`welcome_table_test.dart`, 100 of 100), at most once per child per day, never during a ceremony (`welcome_flow_test.dart` "a ceremony is never talked over") or the rest scene ("in the rest hours there is no welcome, and the day is not used up"; mine: and once the time is over it comes the next time the map is shown), never while another screen is on top (`_mapInFront`, read in `_giveWelcome` at three points; the ceremony test proves the guard) | PASS |

### The name path's tests

| Rule | Proof | Verdict |
|---|---|---|
| Only `hello.*` and `core.home.bubble` follow a name clip | `name_path_test.dart` (`sayWithName` throws `ArgumentError` for a topic, land, closing and lesson line before anything is said, and says nothing, not even the name); `welcome_lines_test.dart` ("only a greeting follows the name clip, which is first and once", over every welcome the composer can make) | PASS |
| The clip is kept only on a matching spelling hash | `name_spoken_flow_test.dart` "when the server voiced an older spelling, the clip is not kept as the new one (SEC-B42-3)"; `name_path_test.dart` (the key is a hash of the spelling; a changed spelling, a new friend and the child's deletion delete the clip; one clip a child; the hash equals the shared vectors in `testvectors/name-spoken.json`; a made clip without a valid 16-hex hash is refused) | PASS |
| The name button is hidden on child devices | `name_spoken_flow_test.dart` "a child device has no "how the name is said" button (O1)" and "a parent device has it" | PASS |
| Never synced, not stored on the server by this path | `name_path_test.dart` "the table that holds the clips is not a table the sync engine reads or writes" (nothing of the clip or its hash in anything sent) | PASS |

## The goldens (all 24 opened with the Read tool, on 2026-11-03)

`app/test/goldens/welcome_{hello,topic}_{phone,phone_1.3,phone_se,phone_se_1.3,tablet_landscape,tablet_landscape_1.3,tablet_portrait,tablet_portrait_1.3}.png` (16), `welcome_close_{phone,phone_se,tablet_landscape,tablet_portrait}.png` (4), `name_spoken_{phone,phone_1.3,tablet_portrait,tablet_portrait_1.3}.png` (4). They are the checked-in goldens; the full run compared the app's render with each of them and none differed (no golden was regenerated).

What I looked for and found: no overflow stripe, no clipped or cut text, nikud whole on every line (line height 1.7 holds at 1.3), the child's name on its own line first ("נועה,") and the sentence under it; the bubble never reaches the pill (the phone's 4-row first-day greeting at 1.3 is about 20 points clear) and covers no land's sign (tablet landscape at 1.3: bubble 245 wide between Market Village and the home sign; tablet portrait: clear of the Counting Hills sign); the tail points at the friend's mouth on all four boards (it moves up its edge when the bubble stands lower on the tablets); the pill's glow is a gold rim and a pale cream light under the clay lip, only on the closing line; nothing in any bubble looks like a question, a button or a score; the parent screen is plain, Heebo, the field with its counter and note, two buttons about 44 points tall, the small print under them whole on the phone and both tablet shapes, no stretched or mirrored picture. One look that first seemed wrong (the last line of the SE first-day greeting looked lighter in the viewer) I measured: the darkest pixel of that line is the same as the lines above it (35 of 255), so it is the viewer, not the golden.

## Tests added (21, all green)

`app/test/qa_b42_welcome_test.dart` (17): the composer reason by reason (8 tests), the word lists on what is seen and what is heard and the question and gender checks (5), and the "any tap" rule on the real map (4: open sea, parents button, pill, change of child with the other child's welcome).

`app/test/qa_b42_welcome_flow_test.dart` (4): the app leaving the front stops the welcome for good; a welcome that waits (the rest hours) comes the next time the map is shown once the time is over; Band A hears the topic and a Band B child with the warm-up due hears the land; the pause between two clips is about 500 ms for Band A and 300 ms for Band C (measured in fake time, bounds 450 to 560 and 250 to 360).

The "word list" tests found nothing in the 48 lines. Two entries of my first list were wrong (the preposition `אל`, as in "נֵצֵא אֶל גִּבְעוֹת", and the object marker `את`) and I took them out; no line was changed.

## Noted, not defects

- **"Sound off in the app's settings, or the parent turned voice off"** (B42.md 2.4): the app has no sound switch, and the parent's "voice" switch is the child's microphone input, so it does not affect the welcome. `welcomeSpokenProvider` is always true and the test overrides it; the build record says so (section 12). The rule is proved at the provider, not through a setting a parent can reach. Needs a decision only when a sound switch is built.
- **No test puts a land on top before the welcome starts**: the welcome begins at the first frame of the map, so a test cannot get ahead of it. The guard (`_mapInFront`, three checks) is read and the ceremony test exercises it; the rest-hours test shows a welcome that waits and then comes.
- **The 2.2 gaps for the band are in the app, the name clip's gap is not measured** (the player is a fake); the seam between the name clip and the greeting is the pilot's job (B42.md section 6).
- **Merge order**: `qa_open_defects_test.dart` skips QA-17 and QA-18 here only because this branch lacks B-20; merge B-20 first or together.

## Not checked

How anything sounds (no audio was heard or measured), the real phone, pgTAP (CI), a live `name-voice` call (none is allowed). No test was weakened or deleted.
