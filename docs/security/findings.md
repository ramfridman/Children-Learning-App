# Security findings: public record

While the repository is public, open findings of medium severity or higher, and the detail of every open finding, are kept only in `docs/security/private/` (git-ignored). This file lists closed findings and low-risk open ones: id, title, severity, status. A finding's full text is added here once it is fixed and its proof has been run again.

| Id | Title | Severity | Status | Since |
|---|---|---|---|---|
| SEC-6 | Pack reader: cap the manifest size before the signature check; header room for 8,002 entries | low | open | 2026-10-28 |
| SEC-7 | A pack is proven three times per app start, on the UI isolate | low | open | 2026-10-28 |
| SEC-8 | A deployed Edge Function differs from `main` (branch deploy not recorded) | low | open | 2026-10-28 |
| SEC-9 | Secret scanning: add rules for the pack-signing key file and the publish secret | low | open | 2026-10-28 |
| SEC-10 | Voice tool: validate the voice id and output format before building the request URL | low | open | 2026-10-28 |
| SEC-11 | Tutor-moves upload script: run the pinned CLI from the repository root | low | open | 2026-10-28 |
| SEC-12 | Sync: a gateway and app format mismatch would mark a device's whole unsent backlog as refused | low | closed (`b20-sync-fixes`: the brake per kind of event and the reset per wire format; proof tests green in QA's full run, `79660b2`) | 2026-10-29 |
| SEC-B20-1 | Sync: 80 or more bad rows of one kind at the head of the queue stopped that kind's sync for good | medium | closed (`83820df`: times re-timed at the boundary, a probe of the newest row before a kind is given up; tests green, `79660b2`) | 2026-11-03 |
| SEC-B20-2 | Alerts: an alert raised under a phone clock before 2017 was refused, kept aside and then pruned | medium | closed (`83820df`, `18e6259`: sent with the server's time, restamped before pruning; tests green, `79660b2`) | 2026-11-03 |
| SEC-B20-3 | Sync: a stall of one kind of event holds the push of every kind for the wait | low | closed (`83820df`; test green, `79660b2`) | 2026-11-03 |
| SEC-B20-4 | Sync: the call budget of a stalled round is per kind (up to about 246 calls), PLAN says about 80 | info | closed (`83820df`: one budget per round, at most 88 calls; test green, `79660b2`) | 2026-11-03 |
| SEC-B20-5 | Sync: the stall setting is not range-checked when read (not reachable from outside) | info | closed (`83820df`; test green, `79660b2`) | 2026-11-03 |
| SEC-B20-6 | Sync: the wire-format pin test can be satisfied without raising the number | info | open | 2026-11-03 |
| SEC-B20-7 | Gateway client: `bad_request` is recognised whatever the HTTP status | info | closed (`83820df`: only with 400; test green, `79660b2`) | 2026-11-03 |
| SEC-B20-8 | Alerts: with a phone clock that stays wrong, an undelivered alert is restamped every round and does not age out | low | closed (`18e6259`: restamped only when the clock is right; test green, `79660b2`); the owner's choice on the words of a restamped alert (kept, up to about 60 days, or cleared) is still open | 2026-11-03 |
| SEC-B20-9 | Sync: the first push of an app start with a still-wrong clock is timed at the server's floor, not shifted | info | open | 2026-11-03 |
| SEC-26 | Word-alert lists: validate a list's values and bounds when it is read, before lists can come from a pack | low | open (checks, bounds, step budget, background matching and the floor, checked first with a step budget of its own, are in on `alerts-tiers`; window rules can still be slow within the bounds) | 2026-10-30 |
| SEC-29 | Alert row hardening (database checks and grants, the parent text's tier) | low | fixed on `alerts-tiers`; closes when CI's pgTAP 09 passes | 2026-10-30 |
| SEC-32 | Kept words: a narrow race when "keep the words" is turned off; a weekly note's words could outlive 30 days on a phone | low | fixed on `alerts-tiers`; closes when CI's database integration test passes | 2026-10-30 |
| SEC-33 | Alerts screen: the kept words can be selected and copied to the system clipboard | low | fixed on `alerts-tiers` (the line with the words cannot be selected) | 2026-10-30 |
| SEC-34 | B-40 hint SVG readers threw on valid SVG numbers (`1.2.3`, a lone `.`) in a signed pack sprite, breaking the activity screen | low | fixed on `b40-visual-hints` (`tryParse`, whole-box fallback; character-pack viewBox reported as a problem) | 2026-10-31 |
| SEC-35 | B-40 `inkBoxOf`/`outlineOf` were quadratic on an unclosed SVG tag (100 KB took 20 s, in `build`) | low | fixed on `b40-visual-hints` (linear tag reader, 64 KB cap, 8 KB tag cap, cache) | 2026-10-31 |
| SEC-B28-2 | The app's stricter name set was incomplete; a name of only invisible characters was valid | low | fixed on `b32-name-safety` (`safeChildName`; 15 app-only vectors) | 2026-10-30 |
| SEC-B28-3 | Names that arrive by sync and old local names were not checked | low | open, partly fixed on `b32-name-safety` (pulled names and the home island are cleaned; old local names still show raw in the picker and parent screens, repair skipped) | 2026-10-30 |
| SEC-B28-4 | Answers of a child the server does not have were refused and lost (a failed `child-put` too) | low | fixed on `b32-name-safety` (held until the first good `child-put`); see SEC-B32-2 | 2026-10-30 |
| SEC-B28-5, -7 | Bounded resend on error; placeholder substitution order | info | closed (re-checked 2026-11-01: unchanged, `Str.fill` is one pass) | 2026-10-30 |
| SEC-B32-1 | Child name: a few invisible or unrenderable characters still pass the app (grapheme joiner, private use, noncharacters, leading marks) | low | open | 2026-11-01 |
| SEC-B32-2 | Sync hold: the held set is read once per round, so a child created during a long round can have rows refused | low | open | 2026-11-01 |
| SEC-31 | Alert pushes: routine alerts shared the daily push budget with acts; no collapse id on iOS | low | closed (`alerts-tiers`) | 2026-10-30 |
| SEC-27 | Alert pushes: the per-device limit was higher than PLAN said; no per-family push cap | low | closed (`alerts-tiers`) | 2026-10-30 |
| SEC-25 | One alert the gateway refused held up every later alert of that device, silently | medium | closed (`alerts-tiers`) | 2026-10-30 |
| SEC-L0-1 | Course isolation: an answer counts by its activity id alone, and activity ids are not kept apart between courses | low | closed (`a399488`: course-prefixed ids, the course on every replayed answer, the activity id in the pull guard; proof re-run) | 2026-11-03 |
| SEC-L0-2 | A gate document of a language pack may omit its course and is then read as `core` | info | closed (`a399488`; proof re-run) | 2026-11-03 |
| SEC-L0-3 | `settings-put` bounds the family's settings in characters, the table in bytes | low | fixed (`a399488`: 10,000 UTF-8 bytes at the gateway; Deno test green); closes when a pgTAP case stores the largest document the gateway takes | 2026-11-03 |
| SEC-L0-4 | `content-publish` and `tutor-prewarm` do not refuse language-course skills under a core pack id (`tutor-turn` does) | info | closed (`a399488`: `content-publish` refuses them under any pack id; proof re-run) | 2026-11-03 |
| SEC-L0-5 | A child deleted mid-round can have its settings put back once by a parent phone that synced just before | info | open | 2026-11-03 |
| SEC-L1-1 | Lesson lines are outside the validator's new language-field rules | low | open | 2026-11-03 |
| SEC-L1-2 | Hebrew frame lines: the script check is narrower than the language rule | low | open | 2026-11-03 |
| SEC-L1-3 | Voice answers on a language item are not yet tied to that language's own switch (not reachable today) | info | closed (`d82b337`: the mic also needs the language's own voice switch, closed while the settings load; QA's full run green, `218f63d`; and on `languages-l3` the validator refuses `voiceAnswer` in a language pack, and a language's speech exists only in `say_it` under that language's own switch, reviewed 2026-11-06) | 2026-11-03 |
| SEC-L1-4 | The tutor hold keeps the previous line's language extras (not reachable) | info | open | 2026-11-03 |
| SEC-L1-5 | Hebrew target text does not bound its nikud | info | open | 2026-11-03 |
| SEC-L1-6 | `isolateLtr` does not neutralise controls inside its run (not used yet) | info | open | 2026-11-03 |
| SEC-L1-7 | A language pack's clip ids are bound to the pack by naming only (for L2) | info | open | 2026-11-03 |
| SEC-L3-1 | Speech-evidence cap: spoken answers given after a hint are not counted against the cap, and item-level statistics take spoken answers for any skill | low | fixed on `languages-l3`: a spoken answer counts only without a hint, outside a probe, for a speaking skill and under the cap; one that counts for no skill changes nothing (`ls09_validation_test.dart`); closes when the security-engineer has run the proof again | 2026-11-06 |
| SEC-L3-2 | A say-it listen is not stopped when the app leaves the foreground (bounded at 6 s; nothing is kept) | low | fixed on `languages-l3`: the say step stops on any lifecycle state but resumed, and what it heard is not applied (`qa_l3_open_defects_test.dart`) | 2026-11-06 |
| SEC-L3-3 | The English and Russian speech models (Apache-2.0) need their licence notice in the app's credits before they are distributed | info | fixed on `languages-l3`: credit lines for both models and the full Apache-2.0 text in the parent area (`app_flow_test.dart`); the strings are `needs-editor` | 2026-11-06 |
| SEC-L3-4 | Say-it switch details: only the language's own voice switch is needed (owner to confirm); a course recogniser is not freed when its switch turns off | info | item 2 fixed on `languages-l3` (the recogniser is made again when the last child's voice switch for the language turns off); item 1 decided by the owner on 2026-11-06: the language's own voice switch alone is enough (L3.md D-5) | 2026-11-06 |
| SEC-L4-1 | "Show me" on a step that is never scored (a personal turn, a story only heard, a chant, the embodied step) wrote an `unsure` attempt that was synced and counted by the engine; no answer content | medium | closed (`acdecdf`: such a step offers no lamp or eye and writes nothing; QA's full run green, `218f63d`) | 2026-11-04 |
| SEC-L4-2 | The parent's switch for personal questions fails open while the family's language settings are not loaded (not reachable today) | low | closed (`acdecdf`: no personal turn until the family's settings are read; QA's full run green, `218f63d`) | 2026-11-04 |
| SEC-L4-3 | Placement replay counts a probe answered twice (two devices, or a re-sent row), so one probe can move a strand up | low | closed (`acdecdf`: the staircase and the replay count a probe once; proof re-run) | 2026-11-04 |
| SEC-L4-4 | Hardening: the course of a lesson id is not part of the pull guard; a personal turn may carry `contradicts`; the placement flow assumes a probe is due | info | closed (`acdecdf`: `Course.ofLessonId` in the pull guard, proof re-run; `contradicts` refused on unscored steps; a complete placement has no visit) | 2026-11-04 |
| SEC-LC-1 | The microphone is decided once per lesson: a language's voice switch turned off mid-lesson takes effect at the next lesson | info | open | 2026-11-05 |
| SEC-LC-2 | The answer path of the lesson controller does not itself refuse an unscored step (not reachable; defence in depth) | info | open | 2026-11-05 |
| SEC-L5-1 | Stroke sets: the `d` path is checked by its characters only, not by its grammar or the range of its numbers | low | fixed on `languages-l5-2b`: `strokePathFault` in `checkStrokeSet` holds the grammar (M first, M and L two numbers, C six, each number `-?\d+(\.\d+)?` from 0 to 100), `_addD` stops at the first bad token (tryParse, an index check), the `strokesSchema` comment says what the schema does not (`ls02_validation_test.dart` "the bounds of a stroke", `ls02_whole_letter_session_test.dart` paints a bad path without an exception); closes when the security-engineer has run the proof again | 2026-11-06 |
| SEC-M10-1 | The app says it plays `tap_answer` 1.4, but no session draws a number answer or a stage picture yet | low | closed (`PackContent.fromPack` hides every item with a number answer or a stage picture until a session draws it, `itemsOf` leaves a hidden id out, `tapHintPlan` gives no plan when there is no right option; proof `sec_m10s0_test.dart`) | 2026-11-06 |
| SEC-M10-2 | The validator throws instead of refusing some incomplete stage pictures | low | closed (null-guarded reads in `_stagePictureOf`; proof `sec_m10s0_test.dart`) | 2026-11-06 |
| SEC-M10-3 | The 1.4 number range is not tied to Band C, and some hint plans grow with the size of the number | low | closed (numerals above 100 and `n:` cells of four digits or more only in Band C, in the validator; the hint plans fall back to the generic plan above 20 units, and a test holds every starter item with big numbers under 2,000 marks; proof `sec_m10s0_test.dart`) | 2026-11-06 |
| SEC-M10-4 | Number cells and column numbers take 10,001 to 99,999 and leading zeros | info | closed (the patterns take 0 to 10,000 with no leading zero; proof `sec_m10s0_test.dart`) | 2026-11-06 |
| SEC-M10-5 | An activity's `templateVersion` is not checked against the manifest's template version | info | closed (validator rule; proof `sec_m10s0_test.dart`) | 2026-11-06 |
| SEC-B29-1 | School stage: a `child-put` with another band and no stage keeps the stored stage, so the server can hold and send a stage that disagrees with the band | low | fixed (`b29-profile`: the upsert keeps a stored stage only while its band is the saved band, a table check ties stage to band, the app clears a stage of another band on pull; proofs `sync_test.ts`, `11_school_stage.test.sql`, `profile_sync_test.dart`) | 2026-11-06 |
| SEC-B29-2 | iOS local data: no backup-excluded data folder yet, and secure-storage items are not `ThisDeviceOnly` (not reachable: no iOS build can open the database today) | low | Dart part fixed (`b29-profile`: every item is `first_unlock_this_device`, not synchronizable; proof `secure_store_test.dart`); the Swift part (exclude the iOS database folder from backup) gates any iOS build and waits for the iOS platform channel | 2026-11-06 |
| SEC-B29-3 | The birth-month source rule scans 7 of the `lib/` folders and misses some names (`childAgeProvider`, `ageInMonths`, `assumedMonths`) | low | fixed (`b29-profile`: an allowlist over all of `lib/`, and only `show SchoolStage` imports of `engine/age.dart` outside it; proof `profile_sync_test.dart`) | 2026-11-06 |
| SEC-B29-4 | Rolling back `settings-put` or `child-put` while the B-29 app is in use stops its settings sync and the save of a child with a stage | info | open (a deploy note: roll back the app first) | 2026-11-06 |
| SEC-BA-1 | Language pack generator: a unit file's gate id was used as a file name unchecked, so `x/../../<path>` (either separator) wrote a JSON file of the author's choosing outside the pack folder, for example over `.claude/settings.json` or a test vector | medium (an authoring file on a public repo writes anywhere the person who runs the generator can write; not high: someone must run `tools/lang_pack.py`, and the output is always `*.json`) | closed (`33eccbdc`: `_raw` holds a gate id to the gate schema's id and the course's prefix with `fullmatch`; `outputs` refuses any file name that is not a plain name; `refuse_outside` refuses, before any folder or file is made, a path whose real folder is not `content/languages/<course>/pack` (the voice plan the one other file); the other id checks of the generator moved from `match` with `$` to `fullmatch`; proof `tools/test_sec_lang_pack.py`, run again 2026-11-07 on `41ab2f61`) | 2026-11-07 |
| SEC-BA-2 | Teach screens: the validator refuses a teach screen only among the items of the lesson that names it, not among another lesson's items | low | closed (`33eccbdc`: the validator refuses a teach screen among any lesson's items, and `itemsOf` drops one whatever a pack says; proof `sec_band_a_test.dart`, run again 2026-11-07 on `41ab2f61`) | 2026-11-07 |
| SEC-BA-3 | Own-name items: the validator does not prove the house character's name always gives a face, so a pack can make a lesson throw when it opens | low | closed (`33eccbdc`: the rules live in `own_name_docs.dart`, the validator runs them with no name and refuses an item that gives no options from the house name; `OwnName.apply` never throws, and the controller passes over an item still to make; proof `own_name_test.dart` "an item that cannot be made", run again 2026-11-07 on `41ab2f61`) | 2026-11-07 |
| SEC-BA-4 | Bundled language packs: an error other than `PackRejected` while installing or reading one course takes every language course out | low | closed (`33eccbdc`: `_proven` and `_installBundled` catch any error per course and log only the course and the error's type; proof `bundled_language_packs_test.dart` (two SEC-BA-4 tests), run again 2026-11-07 on `41ab2f61`) | 2026-11-07 |
| SEC-BA-5 | Misconception skills: the pack schema takes 60, `content-publish` takes 10, so the English and Russian packs (15) cannot be published as they are | low | closed (by design: language packs ship in the app and are never published; `content-publish` refuses a language pack id and a language skill, and the caps stay; proof `content_publish_test.ts`, green in CI's gateway job on `41ab2f61`, not run locally: no Deno here) | 2026-11-07 |
| SEC-BA-6 | Own-name source test is a short deny list; the row test checks some of the record's fields | info | closed (`33eccbdc`: a closed list of the imports and exports of both own-name files and of their importers, and every field of the attempt row and of what the tutor is told checked for Hebrew letters; proof `own_name_test.dart`, run again 2026-11-07 on `41ab2f61`) | 2026-11-07 |
| SEC-BA-7 | A look-alike tag on an own-name answer narrows the first letter of the child's name to two letters in the synced row (the server already holds the name) | info | open (accept; no action) | 2026-11-07 |
| SEC-BA-8 | Hearing sets: `itemsFor` gives a heritage speaker every screen of a `hear` set without checking that each is a hearing screen, so only the validator keeps a teach screen from a heritage speaker | info | open | 2026-11-07 |
| SEC-9a | gitleaks hit in a local stash: a fake JWT-shaped test string, never pushed; no rotation needed | low | closed | 2026-10-28 |
| SEC-1 | Answer codes of six M9 templates were outside `sync-push`'s pattern, so a device's sync stopped for good | high | closed (`dd040cd`) | 2026-10-28 |

## Closed findings

### SEC-L0-1: an answer counted by its activity id alone, and activity ids were not kept apart between courses (low, closed 2026-11-03)

**What it was.** The engine read an answer only through its activity id (`Engine.apply`), and `eventOf` dropped the answer's
pack and skill. The core engine replayed every answer of a child, from any pack, and nothing stopped a language pack from
reusing a core activity id (the test fixture did). The pull guard checked the skill, the pack, the tag and the course, but
not the activity id. If two packs shared an item id, answers to one became evidence for the other course's skills: frame §1.5
invariant 3, broken with no attacker. The impact was a child's learning state and the parent's progress view; nothing was
exposed. No language pack had been installed anywhere.

**The fix (`a399488`).** (1) Activity and lesson ids of a language pack must begin with `<course>.`, and a core pack's ids
never do (validator). (2) `eventOf` gives each answer the course of its pack, and `Engine.apply` ignores an answer whose
course is not its item's, so every engine replays only its own course. (3) `Course.ofActivityId` is part of `Course.ofAnswer`,
and the pull guard drops a pulled answer whose activity id names another course. The language engines also replay only their
own pack's rows.

**Proof re-run by the security-engineer, 2026-11-03** (plain Dart against the branch). The pull guard drops a `core` answer
with an `eng.` activity id, and the reverse. An English engine ignores six answers marked `core` (or a `lang-` id that names
no course) for an item with the same id, and still takes an English one. The validator refuses an English pack with an
unprefixed activity id, and a core pack with an `eng.` one. The two sample packs share no activity or lesson file. The
Flutter regression tests in `a399488` run in the QA pass.

### SEC-L0-2: a language pack's gate could omit its course and was then read as `core` (info, closed 2026-11-03)

A gate without `course` was taken in a language pack and then labelled `core`. Fixed in `a399488`: a gate of a language pack
must carry its course, like every other document. Proof re-run 2026-11-03: a gate without its course is refused, and one with
its course is taken.

### SEC-L0-4: `content-publish` stored language-course skills under a core pack id (info, closed 2026-11-03)

Only the pack id was refused, so an item or misconception with an `ENG-`, `HEB-` or `RUS-` skill could be published under
another name and pre-warmed. `tutor-turn` would never have served such a line. Fixed in `a399488`: those skills are refused
in items and misconceptions under any pack id, so `tutor-prewarm` cannot find any. Proof re-run 2026-11-03: the publish now
gets a 400 (it got a 200 before). `deno task check`: 198 passed.

### SEC-25: one alert the gateway refused held up every later alert of that device (medium, closed 2026-10-30)

**What it was.** The phone sent its unsent alerts oldest first and stopped the whole round at the first failure, marking
nothing. An alert that `alert-create` would never take was therefore sent and refused in every round, and no alert after
it, a disclosure with its push included, ever reached the parents; nothing told them. Three things could make such an
alert: kept words holding a character the speech model can write but the gateway refuses (`%`, `:`, a dash, a curly
quote and more: 118 characters of the model's vocabulary), a `concern` alert reaching a gateway that did not know the
category yet (deploy order), and list values that did not fit `detail` or `key`. No attacker was needed.

**The fix (branch `alerts-tiers`).** (1) The words are cleaned once, when the alert is made (`wireWords`: every character
outside the gateway's pattern becomes a space, cut to 200); `detail` and `key` are built only from characters the gateway
takes. (2) Each alert is marked as it is answered; a `bad_request` is retried once without the words (the alert arrives,
the words are lost: the private side), and if refused again the alert is kept aside and sent once more by the next app
version; any other failure stops the round as before. (3) `alert-create`'s shape is in `testvectors/wire-patterns.json`,
the gateway is held equal to it by a Deno test, and the app's fake server refuses what the real one would. (4) Deploy
order: migration, then functions, then the app.

**Proof re-run by the security-engineer, 2026-10-30.** The original two proof tests (a refused alert with `50%` in its
words, and a `concern` sent to a gateway without it, each followed by a disclosure) now pass: the disclosure arrives in
the first round. The developer's `alert_safety_test.dart` (every Basic Multilingual Plane character and every character
of the model's `tokens.txt` through `wireWords`) and the sync tests: 301 passed. `deno test`: 186 passed, 0 failed, 7
ignored (database-stack tests). The fix reaches a phone when a build with it is installed.

### SEC-27: alert pushes had no per-family cap (low, closed 2026-10-30)

A device could make the parents' phones ring for every new alert, up to 300 an hour, where PLAN said 20 a day. Fixed on
`alerts-tiers`: at most 20 pushes a day per family (the alerts after that are saved and shown without a push), an Android
collapse key, and PLAN states the same numbers. Deno test re-run 2026-10-30: passes. Follow-up in SEC-31.

### SEC-1: answer codes outside the server's pattern stopped a device's sync for good (high, closed 2026-10-29)

**What it was.** `sync-push` takes `attempt.response` only within `^[A-Za-z0-9=._-]{0,40}$` and refuses the whole call for
one field that does not fit. Six M9 templates wrote codes outside it: the clock (`3:30`), the shape builder
(`asset:shape_x>s1`), sort and share (`i1>b2`, `b1=3,b2=3`), the robot (`up,up,right,...`, which could also pass 40
characters), the pattern (asset names joined by `,`) and match pairs (`a=x,b=y`). The device sent its oldest 40 unsent rows,
was refused, marked nothing, and sent the same 40 again in every round: from the first such answer on, no answer, visit or
reward of that device reached the server, the family's other devices or the weekly backup, and nothing told the parent. The
same codes made `tutor-turn` refuse the helper's call after a mistake in those templates (it fell back to RuleTutor, which is
safe). No attacker was needed; any child playing those activities on a synced M9 build triggered it.

**The fix (`dd040cd`).** (1) Every template writes a short code of ids and numbers, built in one place
(`app/lib/play/response_code.dart`): `o2`, `n=4`, `i1-b2`, `b1=3.b2=1`, palette indexes `0101`, step initials `uurd`,
`p3-s1`, `t0-b2.t1-b0`, `3.30`, plain numbers, `left`/`same`/`right` and fixed words. (2) At the sync boundary any code
that does not fit the server's pattern is sent empty, so an answer written by an older build still syncs (its result and tag
count). (3) The helper is told the code only when it fits `tutor-turn`'s pattern, otherwise the fixed word `move`. (4) A
batch refused as `bad_request` is sent again one event at a time; an event refused on its own is marked
(`synced_at` = 1970-01-01 UTC) and never holds up the rows after it; any other failure leaves every row for the next round.
(5) `testvectors/wire-patterns.json` holds the server's patterns; the Deno tests assert the gateway equals it and push every
example through the real `sync-push`, the Dart tests assert the app equals it and play every activity of the starter pack and
every wrong move against it.

**Proof re-run by the security-engineer, 2026-10-29.** Every `attempt.response` write site in `app/lib` (30) was read
against the pack schema's bounds: every code fits by those bounds, and the sync filter (2) and the helper filter (3) make it
hold for any future template too. `deno task check`: 179 passed, 0 failed, 7 ignored (database-stack tests), including the
new `sync-push` contract test (every template's longest code is accepted; `3:30`, `i1>b2`, `b1=3,b2=3`, `up,up,right`,
`asset:shape_x>s1`, `a=x,b=y`, `ball_red,ball_blue` are each refused). A separate plain-Dart check of
`response_code.dart` (21 worst-case codes at the schema maximums accepted, their helper options accepted, 8 old or hostile
codes filtered): passed. The Flutter tests of the fix were run by the app-developer, not by the security-engineer. The fix
reaches a phone when a build with `dd040cd` is installed; the live gateway needs no deploy. The follow-up risk found during
this check, a format mismatch between a deployed gateway and an installed app, is tracked as SEC-12.

## Reviews

- **B-7, `m9-content` against `main` (2026-10-28).** Scope: pack validation and installer, the new templates' parsing, the publish path, the voice tool, the public repository, the lock files. Dependencies: OSV.dev, 198 locked versions, no known vulnerability (2026-10-28); no package, lock file or workflow changed on the branch; actions pinned by SHA. Open findings above low are held privately.
- **SEC-1 verification and the `app` job's CI change (2026-10-29).** SEC-1 closed (above). The `ci.yml` change (45-minute
  timeout, all cores for the tests, a JSON test report in the runner's temp folder summarised into the job summary, the
  Gradle cache) is approved: triggers stay `push` and `workflow_dispatch` (no pull-request trigger), `permissions:
  contents: read`, no secret in the job, no new action, every action still pinned by SHA, no `${{ }}` expression in the new
  shell lines, and the summary copies only file paths, test names and times.
- **B-12, the faster pack reader and the every-byte test (`5e8fab6`, 2026-10-29): approved, no finding.** Read in full:
  the `zip_store.dart` diff, the new `starter_pack_test.dart` flip workers, `zip_store_test.dart`, the oracle
  `test/support/zip_store_reference.dart`, `pack_verify.dart` (unchanged). The checks and their order are unchanged (zip,
  signature, manifest schema, sizes and SHA-256, then parsing); the canonical re-write is still a full byte-for-byte
  comparison; the re-write takes only entries whose name passed the same rules and whose CRC equals the CRC just computed
  from their data, so it produces the bytes the old writer did; the limits are untouched. The oracle is the code of
  `e6971fb` (compared mechanically: only comments, names and the shared `ZipEntry`/`ZipException`/`ZipLimits` differ).
  The flip workers cover every offset exactly once, restore each byte in a `finally`, count every refusal and prove the
  restored pack is genuine; a timeout can only fail the test. A separate plain-Dart check against the `e6971fb` reader
  taken from git (no Flutter) is recorded in the private review. No package, lock file or action changed; the Dart SDK
  3.13.7 is past the one 2026 SDK advisory found (CVE-2026-27704, pub client, fixed in 3.11.0).
- **`2235ac2`, the SEC-12 fix and what came with it (2026-10-29): safe to merge, SEC-12 stays open.** Verified by
  reading: no path in the new push loop repeats a batch within a round or marks a batch the server refused as a whole;
  the once-per-version resend touches only rows the server never stored and cannot be triggered from outside; the
  `duration_ms` clamp and the lower-case `lesson_id` change nothing any reader depends on; the 40-character lesson-id
  bound fits every pack ever committed (19 pack files from 0.1.0 to 0.8.0, longest lesson id 24) and changes no signed
  byte; `testvectors/wire-patterns.json` now describes every key, value and range of `sync-push` and the Deno test holds
  the gateway to it; the three fixed-up-checksum tests on the real pack prove the hashes and the signature. Two changes
  are still required before SEC-12 closes (sent to the app-developer). One new finding above low is held privately.
  `deno task check`: 180 passed, 0 failed, 7 ignored. No package, lock file or workflow changed. The Flutter tests of the
  commit were not run by the security-engineer.
- **The CI split, stages 1 and 2 (board B-25, 2026-10-29): approved; two low findings fixed.** The `app` job is split into a
  format/analyze/build part, two test-file shards and the every-byte pack test in six parts, with a final job still named
  `app (Flutter analyze, tests, Android debug build)` that is green only if every part succeeded (a failed, skipped or
  cancelled part makes it red). Permissions stay `contents: read`, no pull-request trigger, no secret, no new action, every
  action pinned by SHA. Everything that ran on every push still runs on every push: every test file once, every test, every
  byte of the signed pack once. SEC-14 (the shard filter excluded by test-name prefix, so a second test with that prefix
  would have run nowhere) is fixed by an exact, escaped name plus two checks that fail the run; SEC-15 (the exhaustive mode
  relied on the runner's `CI=true`) is fixed by setting it in the job and always requiring the `flip shard` line. Skipping
  the app jobs on docs-only pushes, or running the every-byte test only at night, were considered and are not applied.
- **SEC-16, GitHub settings (2026-10-29): closed by the owner, with one setting reverted.** `main` has an active ruleset with no bypass (no deletion, no force
  push, linear history, and the six CI check names required). The setting "require actions pinned to a full commit SHA" was tried and
  turned off again: it also checks the actions that `flutter-action` calls inside itself (`actions/cache` by tag) and broke every app job. Our own workflow files stay pinned by SHA. Read back with the GitHub API.
- **The child-name limit (board B-28, 2026-10-30): approved, nothing blocks; four low findings go to follow-ups.** The gateway `child-put` is unchanged
  (nickname 1 to 24 UTF-16 units, no control characters, no angle brackets). The app now counts the same way, refuses more than the server
  (C1 controls, direction marks), sends names saved earlier cut to fit, and keeps a phone's whole name when the server holds its cut copy.
  No code path logs the name, and it reaches no prompt or vendor today. Low: SEC-B28-1 (the server accepts bidi, zero-width, tag
  characters, lone surrogates and mark floods inside the 24 units), SEC-B28-2 (the app's stricter set is incomplete; a name of only
  invisible characters is valid), SEC-B28-3 (names that arrive by sync and old local names are not checked), SEC-B28-4 (answers of a child the
  server does not have are marked sent and lost; older than B-28, and a failed `child-put` causes it too). Info: SEC-B28-5 to 9
  (bounded resend on error, no abuse path in the pull rule, placeholder substitution order, clean logging, deploy order). Follow-ups are
  board B-32 and B-33. Detail is in the git-ignored `docs/security/private/B-28-name-limit-review.md`.
- **Child-name safety and the sync guard (board B-32, 2026-11-01): approved, nothing blocks.** Gateway and migrations unchanged; the
  Deno vector test passes (5 of 5). Every name the app accepts is accepted by `child-put`, and a newly typed name is stored exactly as the
  phone shows it (no side normalises; nikud with up to three marks a letter passes). Held rows are never lost, duplicated (event ids are
  stable) or sent for another child; a deleted child's rows are deleted; a pulled child is never held; a child device holds nothing;
  held alerts still go after 30 days. Nothing new is logged. SEC-B28-2 and -4 fixed, -3 partly; new low SEC-B32-1 and -2.
- **Word-alert tiers, branch `alerts-tiers` (2026-10-30).** Scope: the new `concern` category and the quiet tiers, the
  on-device matcher and its list interface, alert creation and counting, the gateway's count update, the migration and
  its pgTAP test, sync of alerts, the parent texts. Verified by reading: the count update stays inside the caller's
  family, changes only the count of a word alert of the same category and only upward, and never sends a second push;
  the two quiet categories never push and the push still carries no content; no grant, RLS or schema exposure changed;
  `detail` and `words` are held to fixed character sets at the gateway (no control or direction characters); nothing
  about a child's words goes to any vendor or into a log. Dependencies: no package or lock file changed; OSV.dev showed
  no advisory for the gateway's database driver (2026-10-30). Three low findings are listed above (SEC-26, SEC-27,
  SEC-29); two findings above low (SEC-25, SEC-28) are held privately. The Deno and database tests were not run by the
  security-engineer (no local Deno or database stack); the branch's alert and sync Flutter tests were (280 passed).
- **Word-alert tiers, the fixes (2026-10-30).** SEC-25 and SEC-27 are closed (above). SEC-29 is fixed and closes when
  CI runs the new pgTAP test 09 (no local database here). SEC-26 stays open: the list checks are in, but window rules
  can still be slow within the new bounds. Two findings above low are held privately: one is fixed and waits for the
  same pgTAP run, and one is new, brought by the fixes. Two new low ones are listed above (SEC-31, SEC-32). Re-run: `deno fmt --check`, `deno lint`, `deno test` 186 passed, 0 failed, 7 ignored; Flutter
  alert, safety and sync tests 301 passed; the original SEC-25 proofs pass.
- **Word-alert tiers, third round (2026-10-30).** Numbering: the voice-tool review had already used SEC-17 to SEC-22,
  so the word-alert findings are SEC-25 to SEC-33 (earlier drafts called them SEC-17 to SEC-24). SEC-31 is closed (a
  separate daily push budget for acts, and an iOS collapse id; Deno test re-run). SEC-32 is fixed and closes with CI's
  database integration test. SEC-26 stays open (a source's rows can still spend the step budget before the app's own
  floor rows are checked). New low: SEC-33. One finding above low is still held privately: the server side of it is
  fixed and the phone side needs one more change. Re-run: `deno test` 188 passed, 0 failed, 7 ignored; Flutter alert,
  safety and sync tests 307 passed.
- **B-20 sync robustness, `b20-sync-fixes` (`a924828`, `145519e`; 2026-11-03): safe to merge, two findings above low
  held privately.** Verified by reading: the format brake is now judged per kind of event (R1) and the rows refused alone
  before a verdict wait without holding up the rows after them (QA-18); every round ends and never repeats a row; only a
  `bad_request` can mark a row; the reset of refused rows is keyed to a wire-format number pinned to a digest of
  `testvectors/wire-patterns.json` (digest recomputed independently: equal), cannot be triggered from outside and resends
  only rows the server never stored; the stall wait is at most an hour, a clock moved either way ends it, and pulls,
  alerts and settings still run. SEC-12 is fixed on the branch and closes when its proof tests are re-run. Gateway,
  migrations, packages, lock files and workflows unchanged; `flutter analyze` clean; OSV.dev: no advisory for drift
  2.35.3, sqlite3 3.8.0, crypto 3.0.8, uuid 4.6.0 (2026-11-03). Not run by the security-engineer: `flutter test`.
  New: SEC-B20-3 (low) and SEC-B20-4 to -7 (info) above.
- **B-20 fixes re-checked, `83820df` (2026-11-03).** The two findings above low held privately are fixed by reading: times
  outside the server's range are re-timed at the boundary (never dropped; the phone keeps its own value), a kind is given
  up only after a probe of its newest row, and an alert timed under a wrong clock goes with the server's time. Checked
  that the re-timing cannot collide with event ids (no time in an id) or change any device's order (local id order),
  that the probe marks rows only on the same evidence as before, and that the restamp can touch no real alert. SEC-B20-3,
  -4, -5 and -7 are fixed by reading. New: SEC-B20-8 (low) and SEC-B20-9 (info). Everything fixed here closes when its
  tests run green; `flutter test` was not run by the security-engineer; `flutter analyze` clean; gateway, packages and
  workflows unchanged.
- **B-20 closed (2026-11-03).** QA's full suite on `b20-sync-fixes` (`79660b2`, 3,060 passed, 0 failed) ran every proof
  test the security review named: SEC-12 and SEC-B20-1, -2, -3, -4, -5, -7 and -8 are closed. Still open: SEC-B20-6 and
  -9 (info), and the owner's choice on the words of a restamped alert.
- **L0 Languages engine core, `languages-foundation` (`ef20f79..f5bb4dc`, merged at `eecc7e6`; 2026-11-03): safe to merge,
  no finding above low.** Verified by reading: the four checks are unchanged on every changed function; `tutor-turn` refuses
  a `lang-` pack before the config, caps, cache or model, and an item with an `ENG-`, `HEB-` or `RUS-` skill before the caps
  and model, in `turn` and `prefetch` alike; the app never asks for a tutor line outside `core`; `content-publish` refuses
  `lang-` packs, so `tutor-prewarm` finds none; language packs go through the same signature, hash, zip-limit and validator
  path as the starter pack; the widened wire patterns are anchored, ASCII-only and bounded; the language settings are ids,
  enums and booleans only, parent-only, and deleted with the child on the server and the phone; the wider size limit adds no
  room for free text. The wire-format number is 2 and both pinned digests were recomputed independently (equal), so B-20's
  reset fires once. New: SEC-L0-1 and SEC-L0-3 (low), SEC-L0-2, -4 and -5 (info), above. `deno task check`: 197 passed,
  0 failed, 7 ignored; `flutter analyze` clean; gitleaks clean over the range; OSV.dev: no advisory for postgres 3.4.9,
  jose 6.2.13, @noble/curves 2.0.1, @peculiar/x509 2.2.0, supabase CLI 2.122.0 (2026-11-03); no package, lock file or
  workflow changed. Not run by the security-engineer: `flutter test`, pgTAP.
- **L0 fixes re-checked, `a399488` (2026-11-03).** SEC-L0-1, -2 and -4 are closed: the proofs were re-run against the new
  code and pass (above). SEC-L0-3 is fixed at the gateway (`MAX_RULES_BYTES`, 10,000 UTF-8 bytes of the parsed document).
  Re-measured with `checkRules`: the largest document with 3-byte characters (9,902 bytes) is taken, and the emoji one
  (11,702 bytes) gets a 400. It closes when a pgTAP case proves that the largest document the gateway takes fits the table's
  12,288 bytes of `jsonb` (no local database here). SEC-L0-5 stays open (info). Also read: `language_providers.dart` replays
  only the pack's own rows into each language engine; a damaged language pack is left out without touching the others; packs
  are loaded only through the verifying installer and never bundled. `deno task check`: 198 passed, 0 failed, 7 ignored;
  `flutter analyze` clean. Not run by the security-engineer: `flutter test` (the QA pass follows).
- **L3 Languages recognisers, the matcher and LS09 say-it, `languages-l3` (`bb53e0e`; 2026-11-06): safe to merge after the two
  low findings, nothing above low.** Verified by reading:
  - The microphone opens only on the child's tap of the say step, under the language's own voice switch, with at most one more
    try. The OS permission is asked only on the parent page.
  - No audio, transcript or partial result is stored, logged, synced or sent. Only an enum outcome and a `said` attempt are kept.
  - The installer writes a temporary file, checks size and SHA-256, then renames it. It has no network fetcher.
  - Every pinned model file matches Hugging Face at its pinned revision, and `bpe.vocab` was rebuilt byte for byte.
  - The model load is hash-checked in an isolate.
  - Hotwords come only from signed content. Three layers (schema, script purity, `hotwordList`) keep `/ : # @` and line breaks
    out, so a pack cannot inject into the sherpa configuration.
  - The Russian model is Apache-2.0: the pinned files are byte-identical to `alphacep/vosk-model-small-streaming-ru`, whose card
    says Apache-2.0.
  - The new gitleaks allowlist hides exactly the two public `tokens.txt` hashes.
  - The source-rule changes tighten the microphone rule.

  New: SEC-L3-1 and SEC-L3-2 (low; the proof of -1 was run in pure Dart) and SEC-L3-3 and -4 (info), above. SEC-L1-3 is closed.
  Also checked: `flutter analyze` clean; no package, lock file, host, workflow or gateway change.

  Not run by the security-engineer: `flutter test`.
- **L1 Languages text, direction and LS01, `languages-l1` (`1967b1a`; 2026-11-03): safe to merge, no finding above low.**
  Verified by reading and by a proof script run against the branch:
  - The bundled starter pack still verifies (signature, hashes, schemas and the whole validator), and its bytes are not in
    the diff.
  - Every new clip reference is a bounded `vo:` id, checked against the pack and looked up only as a key in a verified voice
    bank. No path, file or network read hangs on it.
  - Target text is deny-by-default: direction controls, invisible characters, NFD forms, digits and look-alike letters of
    other scripts are all refused.
  - The validator runs again on every load, and `TargetText` keeps its own paragraph and direction.
  - Nothing new reaches the microphone or the network.
  - Model text can reach only the bubble, never a tile, caption or chip, and the tutor stays off for language items.

  New: SEC-L1-1 and SEC-L1-2 (low), SEC-L1-3 to SEC-L1-7 (info), above. Also checked:
  - gitleaks clean over `origin/main..HEAD`;
  - `flutter analyze` clean for tracked code;
  - OSV.dev: no advisory for flutter_svg 2.3.2, vector_graphics 1.2.4, crypto 3.0.8 or cryptography 2.9.0 (2026-11-03);
  - no package, lock file, host, workflow or gateway change.

  Not run by the security-engineer: `flutter test` (the qa-engineer's pass).
- **L4 Languages, the Band A templates, `languages-l4` (`117769e`; 2026-11-04): one finding above low is held privately and
  must be fixed before merge.** Scope: the six templates (LS08, LS11, LS12, LS10, LS03 drum, LS13), the shared choice base,
  `completePractice`, `untilQuiet`, the new schemas and validator rules, and the placement replay into `Engine.assume`.
  Verified by reading:
  - A personal turn's card, "I said it" and pass write nothing, log nothing and reach no vendor or tutor.
  - The microphone stays closed: no new template can be voice-answered.
  - The validator refuses a scored, voiced or tagged personal turn, and a probe that is voiced, personal, unscored, of
    another course or of a story, command, song or talk template.
  - Every new picture and clip field is a pack-manifest key, never a path.
  - Hit areas and counts are bounded by the schema.
  - Answers of another lesson or course cannot move a placement.
  - A probe looks the same for a right and a wrong answer.
  - There is no timer, streak or red.
  - Rules 2 and 5 hold: the gateway is unchanged, and the tutor is off in every language item.

  New: SEC-L4-2 and SEC-L4-3 (low, proof of -3 run in pure Dart) and SEC-L4-4 (info), above. Also checked:
  - gitleaks clean over `origin/main..HEAD`;
  - `flutter analyze` clean;
  - OSV.dev: no advisory for crypto 3.0.8, cryptography 2.9.0, drift 2.35.3, flutter_riverpod 3.4.3,
    flutter_secure_storage 11.2.0, flutter_svg 2.3.2, http 1.6.0, vector_graphics 1.2.4 or xml 7.0.1 (2026-11-04);
  - no package, lock file, host, workflow or gateway change.

  Not run by the security-engineer: `flutter test`.
- **L4 fixes and the course screens, `languages-course-home` (`4c49c37`; 2026-11-05): safe to merge, nothing new above info.**
  L4 fixes (`acdecdf`):
  - SEC-L4-3 and SEC-L4-4 are closed; their proofs were re-run in pure Dart.
  - SEC-L4-2 is fixed by reading and closes with QA's Flutter run of its test.
  - The one L4 finding above low held privately is fixed by reading (an unscored step now offers no lamp or eye and writes
    nothing). It is listed here once QA's run of its proof tests passes.
  - SEC-L1-3 is fixed by the per-language mic switch.

  Course screens (`7d60d57` to `6543cdf`), verified by reading:
  - `openVisit` is the one way a child's visit starts. It refuses a language that is off or not installed (fails closed
    while loading) and asks the time rules afresh (rest scene, no lesson). The lands now use it too.
  - The microphone needs the language's own voice switch, and the tutor is never asked.
  - Each visit, path, mission, placement and Today's Adventure stop is built from one course's pack and engine only.
  - The parent's "we start here" level comes from that course's placement and is never shown to the child.
  - The course home writes nothing.
  - `Course.ofLessonId` names a course only for `placement-<language>` and `<language>.` ids (proof run).

  New: SEC-LC-1 and SEC-LC-2 (info), above. Also checked: `flutter analyze` clean; no package, lock file, host, workflow or
  gateway change, so the OSV result of 2026-11-04 stands.

  Not run by the security-engineer: `flutter test`.
- **SEC-L4-1, L4 personal turns (closed 2026-11-06).** Before the fix, the lesson screen hid the hint lamp and "show me" only
  for placement probes, and `LessonController.unsure()` wrote a `result: unsure` attempt for any activity. On a personal turn
  (and on a story only heard, a chant or the embodied step), a touch of the eye therefore wrote an attempt row with the item's id,
  skill, hint level and time. The row was synced to the server and the family's devices, and the engine counted it as weak evidence
  that could start a repair. It held nothing of what the child would have picked.

  The fix (`acdecdf`): `Activity.unscored`, and `noHelp` now covers unscored steps. `showHint` and `unsure` return early, and the
  frame draws neither button. The proofs are `ls10_personal_safety_test.dart` (no eye or lamp before a card or during the
  switched-off wait, no attempt row) and `unscored_steps_test.dart` (the four unscored kinds write nothing). Both are green in
  QA's full run (4,073 passed, 0 failed, `218f63d`). SEC-L4-2 and SEC-L1-3 closed in the same run.
- **L5-2b LS02 write a letter, `languages-l5-2b` (`12fb249a`; 2026-11-06): a light review. Safe to merge, one low finding.**
  Verified by reading:
  - Stroke sets are a signed-pack document, read only after the signature, the hashes, the schema and the cross-file rules.
  - Every number is bounded: whole-unit points in the box, 2 to 60 a stroke, 6 strokes a form, 80 forms a set, 4 sets a pack.
  - Unknown fields are refused at every level.
  - A set that is not `teacher-checked`, a set of another course and any set in a pack of the lands are refused.
  - The free-stroke check is linear in the child's stroke. Its work on the model side is bounded by the schema (at most 6 forms
    of 6 strokes of 60 points), so a hostile set cannot make it unbounded.
  - `trace` 2.0 has its own closed schema and belongs to a language course only.
  - An older app refuses a pack that lists stroke sets at its manifest check. It does not store such a pack hidden, so it fails
    closed.
  - The child's drawn points stay in the session's memory. They are never stored, logged, synced or sent.
  - The answer codes are short codes (`ok`, `s2.dir`, `b2.s1.start`). They fit the sync pattern, and the tutor gets `move` in
    their place.
  - The engine changes are pure and use only what the device has, and nothing new leaves the device.

  New: SEC-L5-1 (low), above. Also checked: no package, lock-file, host, workflow or gateway change, so the OSV result of
  2026-11-04 stands.

  Not run by the security-engineer: `flutter test` and gitleaks (not installed here). A grep of the diff found no secret-shaped
  string.
- **M10 step 0, `m10-step0` (PR 41, `f8a99ff4` against `origin/main`; 2026-11-06): a light review. Nothing above low; fix
  SEC-M10-1 to -3 before this build goes on the phones.** In scope: the device setting `division_sign`, the `tap_answer` 1.4 and
  `spot_error` 1.1 schemas, the validator's rules for them, size caps, hiding from older apps, and how today's sessions handle the
  new shapes. Not in scope: the warm-up staircase and the path gate as teaching logic.
  - No change to the gateway, auth, crypto, logs, sync, the database, network hosts, packages, lock files, Android or iOS
    config, or CI (checked in the diff). gitleaks ran over the branch's 4 commits and found nothing. No dependency changed, so
    the advisory check was not run again.
  - `division_sign` is kept in the local settings table like `warm_up`. It is set only from the rules screen in the parent
    area, any stored value other than `colon` reads as ÷, sync never reads the key, and nothing logs it.
  - The schema is strict: patterns match the whole value, unknown fields are refused, and every list and number has a cap (row
    11 cells, cells 9, options 5, hundred-chart lists 100, marks 5, expected answers 8, rules 5, numbers up to 10,000). Each
    picture kind's fields are checked both ways (what the kind needs, and nothing that belongs to another kind). Number and
    choice answers are mutually exclusive, both ways.
  - An app that plays only 1.3 hides a 1.4 pack before reading it (the manifest's template version). If an item is mislabelled,
    the old app's schema refuses the new shapes, so it fails closed. The validator also makes an item that uses a 1.4 or 1.1
    feature declare that version.
  - New findings: SEC-M10-1 to -3 (low) and SEC-M10-4 and -5 (info), in the table above. Their detail and proofs go to the
    orchestrator and stay out of the public file until they are fixed.
- **Languages Band A QA fixes, `languages-band-a` (`41ab2f61..7c72dc56`, and `43997579`, which changes only
  `band-a-build.md`; 2026-11-08): no new finding; SEC-BA-8 stays open (the fix has not landed, and its proof still fails).** In
  scope: the check visit (`engine/check_visit.dart`, `CheckTrail`, `world/check_visits.dart`, the course home and Today's
  Adventure), the catalogue that leaves out steps that are never scored, `ItemMeta.speech` and `pairWith`, the validator
  changes in `language_checks.dart` (the two-choice half) and `ls02_checks.dart` (T04 strokes), the generator rules
  (`_no_chips`, `check_reverse`, `check_bin_sign`, `inLesson`) and the layout changes. Not in scope: the pictures and the
  goldens.
  - `CheckTrail` lives in `SkillState`, which is never written down: the engine rebuilds it from the attempt rows each time
    (replay), and `world_state` and `engine_adapter` only read it. Nothing new is stored, synced, logged or sent to the tutor.
    A visit is the attempt's existing `sessionId`. `Visit.check` is read from the lesson id of the rows.
  - The wire: a check visit is a mission lesson with the id `mission-<skill>-check`. The longest skill id the schema allows
    (14 characters) gives 28 characters, inside `sync-push`'s `^[a-z0-9._-]{0,40}$`, and `wireLessonId` drops anything
    else. No new answer, response code, row field, host, package, lock file or workflow.
  - Bounds: a check visit holds at most 5, 8 or 12 items by band, and a balanced pair is taken whole or not at all.
    `pairHalves` holds only catalogue items. An item that is not in the catalogue is ignored by `Engine.apply`, so an old row of
    a step that is now left out changes nothing.
  - A heritage speaker: the check visit takes only catalogue items, so it never gives a teach or hearing screen; a mission has
    no `teach` set. Own-name items are still made on the phone. Say steps still open the microphone only on a tap. The layout
    changes add no input path and no log line.
  - The validator changes lower no security bound: probes leave both sides of the two-choice count, and the T04 strokes are
    held to the practice-only rules of the trace items. The generator's new rules only refuse; `inLesson` is read by the
    generator only and is not written to a pack document. `FILE_NAME` and `refuse_outside` still hold
    (`test_sec_lang_pack.py`).
  - CI: the `secrets` job still fails on the `2df98c60` false positive; there is no `.gitleaksignore` entry yet.
- **Languages Band A re-check, `languages-band-a` (`33eccbdc` and `41ab2f61`; 2026-11-07): SEC-BA-1 to -6 closed (proofs run
  again; SEC-BA-5's in CI), one new info finding (SEC-BA-8).** In scope: the fixes, and the third step: `readerAs`, the teach
  set `mode`, `answer.hear`, `say.order` and `say.pictureFirst` in schema and validator, `served_route.dart`, how the lesson
  screen resolves the route, the hearing and picture-first paths of `SayItSession` and the controller, and the generator's route
  code. Not in scope: the pictures and the Russian texts as teaching.
  - The route is resolved on the phone from what it already had: the parent's route (`languagesProvider`) and, for a reader
    only, the skills the placement assumed (`languageCoursesProvider`, from the local attempts). No new field is stored, synced,
    logged or sent; the served route is not in an attempt row.
  - A heritage speaker: a `teach` set may name only `new`, a `hear` set only `heritage`, and each set holds only screens of its
    kind (validator, which the phone runs on every pack it installs); `itemsFor` shows a heritage speaker only `hear` sets;
    `itemsOf`, the engine adapter and the placement (tap and drum probes only) never give a teach or hearing screen. SEC-BA-8 is
    the one gap in the second layer.
  - A hearing screen is a teach screen, so it gets no say step and no microphone; `hearDone` and `showWord` write nothing. A
    picture-first step only changes the opening line and when the word is played: the microphone still opens only on a tap
    (`SayStepController.tap`), and the quiet fallback turns it back to echo. No new input path, log line, host, package or
    response code; the generator's new ids are built from checked ids and still pass `FILE_NAME` and `refuse_outside`.
  - Not a finding, for the app-developer: `say.pictureFirst.vo` is not passed to `checkVo`, so a missing clip would only be
    silent.
  - CI: the `secrets` job fails on every run of this branch on one `generic-api-key` hit in `tools/hebrew_voice_review.py`
    line 984 of commit `2df98c60` (branch `logic-sweep`). Checked: the line is a pack file name and a JSON path, not a secret;
    no rotation. It needs a `.gitleaksignore` entry (infrastructure-engineer).
- **Languages Band A, `languages-band-a` (`ff6d7578` against `origin/main`; 2026-11-07): one medium finding (SEC-BA-1, in the
  generator tools, held privately), four low and two info, in the table above. Nothing in the app reaches a vendor.** In scope:
  the bundled language packs (`bundled_packs.dart`, `ContentRepository.languagePacks`, `languagePacksProvider`,
  `pack_builder build-language`), HEB-A-11 own name (`name_options.dart` and its wiring, `answer.type: name`), the schema
  changes (misconception skills cap, `target2`, `font`, story 1.1 `zones` and `follow`, `cutClips`, `answer.teach` and lesson
  `teach`), the response codes, and `tools/lang_pack.py` with `lang_recipes*.py` and `lang_routes.py`. Not in scope: the
  pictures, the unit texts as teaching, and the generated pack files one by one (checked through the validator and tests).
  - Bundled packs: installed only through the verifying installer; the asset name picks only course and version (the regex
    takes `eng`, `heb` or `rus` and a three-part version), and the read-back checks the pack's own course; the installer refuses
    a downgrade, so a damaged newer copy is never replaced by the older bundle; nothing is installed for a family with no
    language on. No language pack is bundled yet (the owner signs them).
  - Own name: the options are made on the device; a row holds only the option id (`o1` to `o3`) and a pack tag; release builds
    log nothing and no log line prints an option; the tutor gets ids only, and every language item has `llmAllowed: false`
    (validator); the validator refuses `voiceAnswer` on the item; there is no TTS package; the tile's label is read only by the
    phone's own screen reader.
  - Teach screens: the route filter and the schema both keep a heritage speaker from a teach set; the engine never sees a
    teach screen; a teach screen opens no microphone and writes nothing. SEC-BA-2 is the gap.
  - Response codes: every new answer is an option id inside `sync-push`'s pattern (schema `o[0-9]{1,2}`).
  - Advisories: CVE-2026-27704 / GHSA-q739-79rh-vmvp (pub client path traversal; NVD, published 2026-02-25, updated
    2026-03-12) is fixed in Flutter 3.41.0, and the local toolchain is 3.47.8. No package, lock file, workflow or host changed
    on the branch. No secret-shaped string in the branch diff (a local grep; gitleaks is not installed locally, CI runs it).
- **B-29 steps 3 and 4, `b29-profile` (`e27f6824` against `origin/m10-step0`; 2026-11-06): safe to deploy in the order
  migration, then `child-put`, `sync-pull` and `settings-put`, then the app. Nothing above low.** In scope: the migration, the
  three changed functions and the shared store, the device-only birth month and year, `engine/age.dart`, the sync field and
  fingerprint, `FamilyLooks`, the fake server, the canary and source-rule tests, iOS backup, and old and new app compatibility.
  Not in scope: the warm-up and presentation stages as teaching or design logic.
  - The four checks: all three functions are `device` specs (`child-put` and `settings-put` parent only, `sync-pull` parent and
    child). The shared `makeHandler` is unchanged and runs token, signature, nonce and time, device, family and role before the
    shape and the work. The shape refuses every key it does not name, so no birth key can be sent (Deno test over
    `refused_keys_of_child_put`). Error answers carry only the code.
  - The database: the migration adds a nullable `text` column with a check on the six words. `create or replace` keeps the
    owner and the grants (PostgreSQL keeps a replaced function's ACL). `security definer` and `search_path = pg_catalog, app`
    are written exactly as before, and the body is the 2026-11-03 body plus one `looks` statement. No grant was added. Default
    privileges still revoke everything from `public`, `anon`, `authenticated` and `service_role`. pgTAP 05 (`execute`) and 11
    (column privileges, RLS on) cover this.
  - Birth data: it is only in `profile_births` in the encrypted database, and it is read only in `engine/age.dart`,
    `data/tables.dart`, `data/app_database.dart` and `app/age_providers.dart` (nothing consumes it yet). `BirthMonth.toString`
    hides it. Release builds print nothing. There is no crash reporter, and Android backup and transfer exclude every domain.
    The canary test is sound for the sync functions (every request and answer of three rounds, numbers, dates and keys); see
    SEC-B29-3 for the source rule.
  - `looks`: at most 6 children, ids in the `child-put` pattern, the letter exactly `A`, `B` or `C`. The 10,000-byte bound is
    unchanged. A stale parent phone could put a deleted child's letter back, which is SEC-L0-5 (info), now also for `looks`.
  - Compatibility: an old app ignores `school_stage` and `looks`, and a save from it without a stage keeps the stored stage
    (but see SEC-B29-1). An old-app parent phone that saves the settings drops `looks` (last write wins; not a security issue).
  - New findings: SEC-B29-1 to -3 (low) and SEC-B29-4 (info), in the table above. Their detail goes to the orchestrator.
  - Advisories (OSV.dev, 2026-11-06): none for drift 2.35.3, sqlite3 3.8.0, flutter_secure_storage 11.2.0 or
    flutter_secure_storage_darwin 0.4.3. No lock file, workflow or host changed.
  - Run by the security-engineer: `flutter test` on `profile_sync_test`, `birthday_changes_nothing_test`,
    `profile_births_test` and `look_settings_test` (42 passed). CI run 42245546284 on `origin/b29-profile`: the gateway
    (Deno tests), database (pgTAP), gitleaks (full history) and OSV jobs passed; the app test shards were still running.
- **B-40 visual hints (2026-10-31).** Reviewed: the A7 validator rule (fails closed, cannot throw), the hint readers of pack text and SVG, the 13 hand SVGs (no script, href, image, style or URL), no new package or host, gitleaks clean over the branch. Two low findings, SEC-34 and SEC-35, fixed on the branch with proof tests (`hint_svg_hostile_test.dart`). OSV.dev: no advisory for flutter_svg 2.3.0, vector_graphics 1.2.4, vector_graphics_compiler 1.3.2, xml 7.0.1.
