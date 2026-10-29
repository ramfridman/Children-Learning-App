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
| SEC-9a | gitleaks hit in a local stash: a fake JWT-shaped test string, never pushed; no rotation needed | low | closed | 2026-10-28 |
| SEC-1 | Answer codes of six M9 templates were outside `sync-push`'s pattern, so a device's sync stopped for good | high | closed (`dd040cd`) | 2026-10-28 |

## Closed findings

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
