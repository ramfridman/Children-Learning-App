# QA: CI speed-up stage 2 (the every-byte test in 6 parts)

Verified by the qa-engineer on 2026-10-29, in the worktree `.claude/worktrees/agent-a1ee3ad9a5ced8560` (based on `ci-faster-stage1`), on the uncommitted change to `app/test/starter_pack_test.dart` and `.github/workflows/ci.yml`. Nothing was committed, pushed or switched; no CI was started; only test code was touched for the mutation checks and every mutation was reverted (final md5 of both files equal to the start: test `8852f745...`, ci.yml `f2626c43...`; `git diff` hash equal; `git status` shows only the two modified files).

Verdict: **pass**. No defect found. Three observations (O-1 to O-3) below.

## 1. The diff, assertion by assertion

| Old assertion | Now | Weakened? |
|---|---|---|
| `_refusedFlipsOfEvery`: `accepted` is empty | unchanged line | no |
| `_refusedFlipsOfEvery`: every worker's copy, with every byte put back, is the genuine pack | unchanged line | no |
| `_flipEach`: flip with `^= 0x01`, `verifyPack`, `PackRejected` counts as refused, byte put back in `finally` | only the loop header became `for (final int i in _offsets(first, stride, bytes.length))`; same offsets | no |
| every-31st-byte test: `_refusedFlipsOfEvery(31)` equals `(length + 30) ~/ 31` | untouched; `first` defaults to 0, worker slices `0 + w*31`, stride `workers*31` as before | no |
| every-byte test: full = `CI=true` or `NN_EXHAUSTIVE=1`, otherwise every 97th byte; expects `length` (full) or `(length + 96) ~/ 97` | with shard `0/1` the same offsets and the same numbers (`_countOf(0,1,len)` = len; `_countOf(0,97,len)` = `(len+96) ~/ 97`); sampled mode ignores the shard but still validates it | no |
| test name and 60-minute timeout (CI selects by name) | unchanged | no |
| the repaired-checksum tests (files hash, manifest, signature) and the rest of the file | not in the diff | no |

Added: `_offsets`, `_countOf`, `_flipShard`, `_workerSlices`, the `flip shard` print (full mode only) and two tests. The workflow diff is only: `part: [1..6]`, `timeout-minutes: 25`, comments.

## 2. Runs (real, on the PC, 16 logical processors)

| # | Command | Result |
|---|---|---|
| 2 | `flutter test test/starter_pack_test.dart --name "^(?!every single byte of the real starter pack, changed in turn)"` (the file shards' form) | **+18, All tests passed**, 63 s; the every-byte test not among them (16 old + the 2 new) |
| 3 | `--plain-name` of new test 1 (parts take every offset once) | +1 passed |
| 3 | `--plain-name` of new test 2 (`NN_FLIP_SHARD` parsing) | +1 passed |
| 4 | `CI=true NN_FLIP_SHARD=3/6`, `--plain-name` of the every-byte test | printed `flip shard 3/6: 584268 of 3505610 offsets refused`; expected (3505610 - 3 + 5) ~/ 6 = 584268; **passed** in 3 min 6 s |
| 5 | `NN_FLIP_SHARD` = `6/6`, `abc`, `/6`, `5/6/7`, each with `CI=true` and without (sampled mode) | all 8 **fail** the test (`[E]`, "is not <index>/<total> ..."), exit 1, "Some tests failed"; none skipped. (`/6` first got rewritten by Git Bash to a path; re-run with `MSYS2_ENV_CONV_EXCL=NN_FLIP_SHARD`, the literal `/6` fails in both modes too.) |
| 8 | `flutter analyze --fatal-infos` | No issues found |
| 8 | `dart format --output=none --set-exit-if-changed lib test` | 261 files, 0 changed |

Test 1 covers lengths 1, 5, 12, 97, 100, 1009 and the real pack (3505610), totals 1 to 7, workers 1, 3, 4, 16 and this machine's: the counts add to the length; each part's real offsets all satisfy `i % total == index`, number `_countOf`, and all parts together hit each offset exactly once. Test 2 covers unset, empty, `0/1`, `5/6` and 16 bad forms (including `6/6`, `0/0`, `-1/6`, spaces, a trailing newline, `1.0/6`, nine-digit overflow).

## 3. Mutation checks (each reverted; each makes a test fail)

| Mutation | What failed |
|---|---|
| M1a `_offsets` stops one early (`i < length - 1`) | new test 1: `Expected <1>, Actual <0>`. End to end, `CI=true 1/6`: printed 584268, `Expected <584269>` (the dropped last offset 3505609 belongs to part 1). In sampled mode alone this mutation is invisible (3505609 is not a multiple of 97): it is caught by test 1 and by the full-mode part, as it should be |
| M1b `_flipEach` skips its first offset (`.skip(1)`) | every-byte test, sampled mode: `Expected <36141>, Actual <36125>` |
| M2 `_workerSlices` ignores `first` (`first: w * step`) | new test 1: part offsets not `i % total == index`. End to end, `CI=true 4/6`: printed 584269, `Expected <584268>` |
| M3 `_countOf` is `length ~/ step` | new test 1: sum of counts is not the length; every-byte test, sampled: `Expected <36140>, Actual <36141>` |

## 4. `tools/ci/assert-tests-ran.py` on the real JSON report of the 3/6 run

| Case | Exit | Output |
|---|---|---|
| `--passed <name> --printed "flip shard 3/6:"` | 0 | `passed: ...` and `printed: flip shard 3/6: 584268 of 3505610 offsets refused` |
| wrong shard (`--printed "flip shard 2/6:"`, and `3/1:`) | 1 | `no test printed: flip shard 2/6:` |
| missing test (the file-shard report, where the every-byte test is excluded) | 1 | `did not run and pass: ...` and `no test printed` |
| report file missing | 1 | "the tests did not run" |

## 5. The workflow

- `actionlint` 1.7.12 on `.github/workflows/ci.yml`: no findings, exit 0.
- YAML read: matrix `part: [1..6]`, `fail-fast: false`, `timeout-minutes: 25`; `bash -n` on all four `run:` blocks of the job passes.
- `NN_FLIP_SHARD: ${{ strategy.job-index }}/${{ strategy.job-total }}` gives `0/6` to `5/6`; the check step uses the same two values, so the part that runs and the line demanded cannot drift. Because the total comes from `job-total`, shortening or lengthening the matrix still gives complete coverage (each part takes `i % total`).
- Can a part be skipped yet counted green? Reasoned, not run on GitHub: the job `app` runs `if: always()`, needs all three jobs, and fails unless every `needs.*.result` is exactly `success`; a failed, cancelled, skipped or timed-out leg makes the matrix job's result non-success, so `app` goes red. A part whose test ignores the switch fails the `--printed` check or the count. A part where `CI` is not `true` runs the sampled mode, prints nothing, and fails the `--printed` check. A renamed test finds nothing (`flutter test` exit 79) and `--passed` fails. The new tests' names do not start with the every-byte prefix, so they run in the file shards (they were in the +18).
- The `jq` expression of the `app` job could not be run here (`jq` is not installed on this PC); it is unchanged from stage 1.

## 6. Observations (no defect)

- O-1 `NN_FLIP_SHARD=05/6` is accepted as 5/6 (leading zeros). Harmless: the printed line and the count use the parsed numbers.
- O-2 If a GitHub run is cancelled by a newer push, `app` (`always()`) still finishes, red. Only superseded runs; on `main` runs are not cancelled (concurrency rule).
- O-3 `docs/setup/ci-faster.md` sections 3 and 6 still describe stage 2 as pending; the infrastructure-engineer should flip them to "done" when the change is committed.

## 7. Not checked

- A real GitHub run: the 4-core runner time per part (estimate 412 to 512 s plus about 1 min setup; measured here 186 s on 16 cores for one part), the 25-minute limit with real margin, `strategy.job-index` mapping to `0..5` on GitHub, the `app` job's handling of a cancelled or skipped leg, and the job summaries.
- `jq` on the `app` job; the other five CI jobs; the whole `flutter test` suite (only `starter_pack_test.dart`, as asked) .
- The six parts were not all run: parts 3/6 (pass) and, with mutations, 1/6 and 4/6 (the latter two expected to fail). By the proof in test 1 and the count formula the six together are every offset once; that is a proof by arithmetic plus one real part, not six real runs.
- Security review of the change (not part of this task).

## Second verification (2026-10-29, after the fixes for SEC-14 and SEC-15)

Verified by the qa-engineer on the uncommitted worktree (HEAD 5c4a9c5), `.github/workflows/ci.yml`, `tools/ci/exact-name-regex.py` (new), `tools/ci/assert-tests-ran.py` (`--only`, `--none-start-with`) and `app/test/starter_pack_test.dart` (`_expectPartsFit`). Nothing committed, pushed or switched; no CI started. Verdict: **pass**, no defect. The PC has no `python3` on its PATH (only `python` 3.11); the commands were run with `python3` as a shell function for `C:\Python311\python.exe -I`, as the workflow does on Linux.

Diff read in full: ci.yml (shard job gets `EVERY_BYTE_TEST` and the exact filter; check step gets `--none-start-with`; pack job gets `NN_EXHAUSTIVE: "1"`, `--only`, `--printed` always, `timeout-minutes: 25`, 6 parts; `python3 -I` everywhere), the two scripts, and the test file (the new `_expectPartsFit`, called before the run and covered by the `NN_FLIP_SHARD` unit test). No existing assertion was weakened.

| # | What | Result |
|---|---|---|
| 1 | `python3 -I tools/ci/exact-name-regex.py "<full name>" "<prefix>" test` (from `app/`) | exit 0, stderr: prefix and name each occur once in `test/starter_pack_test.dart`; stdout `^(?!every single byte ... changed in turn, is refused \(all bytes with NN_EXHAUSTIVE=1 or in CI\)$)` |
| 2 | `flutter test --concurrency=4 --name "<that pattern>" --file-reporter json:... test/starter_pack_test.dart` (the file-shard form; `CI`, `NN_EXHAUSTIVE`, `NN_FLIP_SHARD` unset) | **+18, All tests passed** (about 60 s); every-byte test not run |
| 2 | `assert-tests-ran.py <json> --files <list> --none-start-with "<prefix>"` | exit 0: `1 suites loaded, 1 expected`, `no test starts with: <prefix>` |
| 3 (SEC-15) | `NN_FLIP_SHARD=0/1`, `CI` and `NN_EXHAUSTIVE` unset, `--plain-name "<full name>"`, then `assert-tests-ran.py --passed N --only N --printed "flip shard 0/1:"` | test passed in 13 s (sampled mode); `--passed` ok, `--only` ok, `--printed` **exit 1**: `no test printed: flip shard 0/1:` |
| 3 (SEC-14) | temporary `app/test/zz_probe_test.dart` with a test named `<prefix>, but a second test that must not hide` | `exact-name-regex.py ... test` **exit 1**: `the prefix occurs 2 times under test (must be once)`. With the source check bypassed (pattern made without the folder), the probe file ran (+1) and `assert-tests-ran.py --none-start-with` **exit 1**: `1 test(s) start with ...: [...second test...]`. Probe deleted; `git status` shows only the five files of the change plus this record, no `zz_probe_test.dart` |
| 3 | edge cases of `exact-name-regex.py` | `a.b(c)\|d$` escaped to `a\.b\(c\)\|d\$`; newline in name, name not starting with the prefix, empty name, missing folder: exit 1; wrong argument count: exit 2. `assert-tests-ran.py`: missing report exit 1, empty `--none-start-with` exit 2, missing `--files` list: traceback and exit 1 (fails closed) |
| 4 | `actionlint` 1.7.12 on `.github/workflows/ci.yml` | no findings, exit 0 |

Not rerun this time (done and recorded in the first verification above, unchanged by the fixes): `flutter analyze`, `dart format`, the two new unit tests, the 3/6 full-mode part and the mutation checks. The first run's observation O-3 (stage 2 described as pending in `docs/setup/ci-faster.md`) was fixed by the infrastructure-engineer's doc update, which I did not re-read line by line. Still not checked: a real GitHub run (4-core time per part, the 25-minute margin, `strategy.job-index` as 0 to 5, the `app` job on a cancelled leg), the whole `flutter test` suite, and `jq` in the `app` job.
