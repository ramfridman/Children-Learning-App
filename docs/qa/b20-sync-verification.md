# QA verification: B-20 (sync robustness)

2026-11-03, qa-engineer. Worktree `D:\nitznutz-b20`, branch `b20-sync-fixes` (cut from `origin/main`), head `18e6259` when verified. Follow-up of QA-17 and QA-18 (SEC-12) and of the security review `docs/security/private/B-20-sync-review.md`.

**Verdict: PASS. No defect found (no `QA-B20-n` filed).** Every proof test the security-engineer named runs green, QA-17 and QA-18 no longer skip, and seven new QA tests close the edges the developer's tests left open. Two info findings of the security review stay open by design (SEC-B20-6, SEC-B20-9).

## What ran

| Command (in `app/`) | Result |
|---|---|
| `flutter analyze` | No issues found |
| `dart format --output=none --set-exit-if-changed .` | 364 files, 0 changed |
| `flutter test` (whole suite, once, before my new file) | **3060 passed, 0 failed, 3 skipped** (about 17 minutes) |
| `flutter test test/qa_b20_sync_test.dart` (my new file) | 7 passed, 0 failed |

The known failure `starter_pack_test` did not fail here: all 20 of its tests passed (the worktree holds the signed pack). The three skips are old and unrelated: `graph.report() is empty on the starter pack` (`mastery_reachable_test.dart`), `QA-13 trace, two strokes` and `QA-14 the child space has no English screen-reader labels` (`qa_open_defects_test.dart`, still `_open`). Deno and pgTAP were not run: the branch changes nothing under `supabase/` or `testvectors/` (`git diff --stat`, and the review says the same).

## The acceptance, item by item

| Item | Proof (test, file) | Verdict |
|---|---|---|
| QA-17 (a gateway that does not know one key of the answers holds the answers back, never marks them refused) | `qa_open_defects_test.dart` "the sync brake QA-17 ..." (no `skip:`) | PASS |
| QA-18 (a full batch of rows refused one by one never stops the answers after them) | `qa_open_defects_test.dart` "QA-18 a full batch ..." (no `skip:`), and the 2010-clock form "answers timed before 2017 ... are re-timed and sent" | PASS |
| Bad rows set aside, later rows still sync | `sync_engine_test.dart` "is sent once more on its own, then never again ...", "QA-18 a whole batch of bad rows is set aside ...", "QA-18 a visit and an award that are bad on their own ..." | PASS |
| Per-kind "format understood" rule (R1) | "R1 the brake is held per kind ..." and "R1 and the other way ..." | PASS |
| A probe of the newest row before a kind is given up | "QA-18 a round gives up on a kind when even its newest row is refused ... bounded number of calls" (2 x 5 + 2 calls), "SEC-B20-1 a good answer behind more bad rows ... is sent" (2 x 5 + 1), "SEC-B20-1 more bad rows ... never stop the good answer for good" | PASS |
| SEC-12: a server that refuses every event does not know the format: nothing marked, the round gives up | "a server that refuses every event of a batch does not know the format of this app ..." | PASS |
| R2: `wireFormat`, not the engine version, is the reset key; events keep `engine` 1; the pin | "R2 the engine version ... never what resets the markers ..."; `wire_format_test.dart` "the wire format number follows testvectors/wire-patterns.json: change the file, raise the number" | PASS |
| Backoff in a stall, per kind | "the wait after a stalled round: no sync-push call until it is over; it doubles up to an hour" (5, 10, 20, 40, 60, 60 minutes, a minute early and on time), "SEC-B20-3 ... only the kind that stalled waits", "a stalled round does not stop the family from coming in, and a clock that went back ..." | PASS |
| Out-of-range client times re-timed at the boundary, never dropped | "SEC-B20-1 answers timed before 2017 are re-timed ...", "... keeps its place by the phone's offset ...", "... a visit whose end is held ... never ends before it starts", and my exact-edge test (below) | PASS |
| Alerts before 2017 sent with the server's time; restamped only once the clock is right | `alert_safety_test.dart` group "SEC-B20-2" (6 tests: the floor equals the gateway's, clock right while offline, clock still wrong at send, kept-aside alert re-timed, SEC-B20-8 stays wrong 31 days, a sent or right-timed alert is untouched) | PASS |

### The proof tests for the security-engineer's closing list

All of them ran in the full suite and passed: SEC-12 (the "refuses every event" test, the R1 pair, the R2 pin) so **SEC-12 can close**; SEC-B20-1 (5 tests), SEC-B20-2 (alert group, 4 tests) and SEC-B20-3, -4, -5, -7, -8 (one test each: `sync_engine_test.dart` for -3, -4, -5, -7; `alert_safety_test.dart` for -8). **SEC-B20-1, -2, -3, -4, -5, -7, -8 can close.** Still open and not mine to close: SEC-B20-6 (the pin can be satisfied without raising the number; code review is the control) and SEC-B20-9 (the first push after a launch with a still-wrong clock goes at the floor, not shifted; the data is kept, only less exact).

## Tests added (`app/test/qa_b20_sync_test.dart`, 7 tests, all green)

1. The exact edges of the range with a right clock (whole seconds, because the database keeps seconds): one second before the floor goes as the floor, the floor and one second after it are untouched, one second before the server's time is untouched, the server's time is untouched, one second after it goes as the server's time. No row refused.
2. A re-timed row whose answer was lost goes again under another offset and another server time: the server holds it once, with the time of the first send (the event id has no time in it).
3. A new wire format ends a wait at once: after a stall and a round inside the wait (no `sync-push` call), the reset of the format key makes the first round of the new build send the row, and `sync_stall` is empty.
4. During the wait after a stall the device's alerts still go (`pushedAlerts` 1, no `sync-push`).
5. A stalled kind does not hold the others in the same round: a visit goes while six answers wait (`sync_stall` is `1,<time>,attempt`); after the wait they all go and the setting is cleared.
6. A `sync_stall` in the two-part form written by the first B-20 commit (`3,<time>`) is not a stall and costs the child nothing.
7. The `sync_stall` setting has only counts, a time and kind names: no id or text of a row.

## Not found, noted

- An alert **kept aside** as refused (second refusal under a clock that the gateway client never learnt the skew for) is restamped by `tidyAlerts` once the clock is right, but stays marked `refusedBySync`, so it reaches the parents only at the next wire-format bump. With the real gateway client the skew is learnt from the first `clock_skew` answer and the second call carries the right time, so this needs a server that refuses the time and a client that never learns it; I could not make it happen with the real client and did not file it. Info only.
- The dev's own question about the words of a restamped alert (clear them or keep them up to about 60 days) is still the owner's choice (SEC-B20-8 note); the tests hold the current behaviour (words kept).
- The probe changes the local order of a few answers of one stretch on the family's other devices (security review, info): no test proves a harm, none was asked for.

## Not checked

The real phone and the real gateway. No live call was made. Deno and pgTAP did not run (no change there). Flaky tests: none seen; the whole suite passed in one run.
