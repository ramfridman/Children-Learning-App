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
| SEC-12 | Sync: a gateway and app format mismatch would mark a device's whole unsent backlog as refused | low | open (partly fixed in `2235ac2`) | 2026-10-29 |
| SEC-26 | Word-alert lists: validate a list's values and bounds when it is read, before lists can come from a pack | low | open (checks, bounds, step budget, background matching and the floor, checked first with a step budget of its own, are in on `alerts-tiers`; window rules can still be slow within the bounds) | 2026-10-30 |
| SEC-29 | Alert row hardening (database checks and grants, the parent text's tier) | low | fixed on `alerts-tiers`; closes when CI's pgTAP 09 passes | 2026-10-30 |
| SEC-32 | Kept words: a narrow race when "keep the words" is turned off; a weekly note's words could outlive 30 days on a phone | low | fixed on `alerts-tiers`; closes when CI's database integration test passes | 2026-10-30 |
| SEC-33 | Alerts screen: the kept words can be selected and copied to the system clipboard | low | fixed on `alerts-tiers` (the line with the words cannot be selected) | 2026-10-30 |
| SEC-31 | Alert pushes: routine alerts shared the daily push budget with acts; no collapse id on iOS | low | closed (`alerts-tiers`) | 2026-10-30 |
| SEC-27 | Alert pushes: the per-device limit was higher than PLAN said; no per-family push cap | low | closed (`alerts-tiers`) | 2026-10-30 |
| SEC-25 | One alert the gateway refused held up every later alert of that device, silently | medium | closed (`alerts-tiers`) | 2026-10-30 |
| SEC-9a | gitleaks hit in a local stash: a fake JWT-shaped test string, never pushed; no rotation needed | low | closed | 2026-10-28 |
| SEC-1 | Answer codes of six M9 templates were outside `sync-push`'s pattern, so a device's sync stopped for good | high | closed (`dd040cd`) | 2026-10-28 |

## Closed findings

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
