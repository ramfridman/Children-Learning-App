# A faster CI without losing any check

Infrastructure Agent, 2026-10-29 (the owner's request: "make the CI much faster while keeping it efficient and secure,
without compromising on quality"). Every number marked **measured** comes from the GitHub logs of runs 40824493092
(51b7666), 40802257767 (b8af058) and 40795649171 (2235ac2), read with `gh run view --log` and the job API; nothing was
run on GitHub for this note. Numbers marked **estimate** say what they are based on.

## 1. The short answer

- The `app` job is slow because of **one test**: "every single byte of the real starter pack, changed in turn, is
  refused" in `app/test/starter_pack_test.dart`. It took **2,471 to 3,072 s** (41 to 51 min, measured). The other
  82 test files and the other 16 tests of that file were all finished **296 to 406 s** into the test step (measured).
  For the last 41 to 51 minutes of every run, only that one test is running.
- That test is already spread over all 4 cores of one runner. The only way to make it fast without testing less is
  to spread its bytes over **several runners at once**. Everything else (caching, ordering, splitting the other
  files) saves minutes, not tens of minutes.
- Applied in two stages: the `app` job split into parts that run side by side, with the job `app` kept under its old
  name as a final check that every part passed (**stage 1**, about 7 to 9 min faster), and the every-byte test split
  over **6 parts** by its `NN_FLIP_SHARD` switch (**stage 2**, section 6), which brings a push from **49 to 63 min down
  to about 9 to 10 min** (estimate until the first GitHub run). Neither stage drops a single check.
- Ideas that would skip or postpone checks (docs-only pushes, the every-byte test nightly) are in section 4's second
  table, apart
  from the speed-ups, and need the security-engineer's review and the owner's OK. They are **not** applied.

## 2. Where the time goes (measured)

### The jobs

| Run | Commit | app job | Test step | Other 82 files done at | Every-byte test | Build | database | others |
|---|---|---|---|---|---|---|---|---|
| 40824493092 | 51b7666 | 60 min 21 s | 3,455 s | +406 s | 3,072 s | 110 s | 2 min 52 s | 6 to 19 s each |
| 40802257767 | b8af058 | 48 min 50 s | 2,770 s | +296 s | 2,471 s | 91 s | 2 min 28 s | 6 to 20 s each |
| 40795649171 | 2235ac2 | 62 min 59 s | 3,432 s | +399 s | 3,048 s | 251 s (Gradle cache miss) | 1 min 45 s | 7 to 23 s each |

The steps of the app job before the tests (set up, checkout, Java, Flutter from the cache, `pub get`, format,
analyze) took 41 to 65 s; `pub get` 1 to 2 s (the pub cache is already restored); Flutter 17 to 26 s. In
40795649171 the Gradle cache missed (the Java step restored nothing and its post step spent 53 s saving): the build
took 251 s instead of 91 to 110 s.

### The top 15 files (run 40824493092)

From the job summary of `tools/ci/test-timings.py` (first start to last end of a file; files run four at a time, so
the times overlap and are stretched by sharing the cores):

| # | File | Minutes | Note |
|---|---|---|---|
| 1 | `starter_pack_test.dart` | 55.6 | every-byte test 51.2 min, every-31st-byte test 3.5 min, checksums-repaired test 0.8 min |
| 2 | `pack_installer_test.dart` | 2.0 | the acceptance test alone 1.8 min |
| 3 | `app_flow_test.dart` | 1.7 | |
| 4 | `playthrough_test.dart` | 1.1 | three screen sizes, 0.3 to 0.5 min each |
| 5 | `golden_screens_test.dart` | 1.1 | |
| 6 | `unit_golden_test.dart` | 1.0 | phone and tablet, 0.5 min each |
| 7 | `voice_in_test.dart` | 1.0 | |
| 8 | `alerts_flow_test.dart` | 0.8 | of it 13 s loading |
| 9 | `tutor_lesson_test.dart` | 0.7 | |
| 10 | `lesson_golden_test.dart` | 0.7 | of it 13 s loading |
| 11 | `companion_everywhere_test.dart` | 0.7 | |
| 12 | `rules_screen_test.dart` | 0.6 | |
| 13 | `push_test.dart` | 0.6 | |
| 14 | `lesson_flow_test.dart` | 0.6 | |
| 15 | `zip_store_test.dart` | 0.6 | |

The other 68 files take under half a minute each. 1,054 tests passed and 4 were skipped (83 files).

### How parallel the run is

- **Runner:** `ubuntu-24.04` on a public repository has **4 vCPUs and 16 GB** (GitHub's documentation; the logs do
  not print it, so the new jobs print `nproc`). On a private repository the same label has **2 vCPUs and 8 GB**.
- **Files:** `flutter test --concurrency="$(nproc)"` runs 4 files at once.
- **The every-byte test:** one worker isolate per processor (`Platform.numberOfProcessors`, so 4), each taking every
  4th offset. The measured rate is 3,505,610 changed packs in 2,471 to 3,072 s, **0.70 to 0.88 ms per changed pack**
  with 4 workers (about 2.8 to 3.5 ms per pack in each worker). On the PC, 4 workers gave 2.7 times one worker
  (B-12): isolates help, but 4 vCPUs are not 4 times one.
- **The shape of the 57 minutes:** for the first 5 to 7 minutes, 4 files plus the pack test's 4 isolates share 4
  vCPUs (oversubscribed); then for 41 to 51 minutes the pack test's 4 isolates run alone. Inside one file the tests
  run one after the other, so the every-31st-byte test (167 to 209 s) and the checksums-repaired test (40 to 51 s)
  also sit on the critical path, before and after the every-byte test, and the APK build (91 to 251 s) comes after
  all of it.
- **The cost grows with the square of the pack size** (ci-m9.md): a changed byte is found by the CRC of its file, after
  the CRCs of all files before it. A pack twice as big makes this test about four times as long; on one runner it
  would pass its own 60-minute timeout. Splitting it over runners is also what keeps CI working as the pack grows.

## 3. The design (in `.github/workflows/ci.yml`)

```
secrets, hygiene, osv, database, gateway        unchanged, in parallel as before
app-static      format, analyze, debug APK      ~3 to 5.5 min
app-tests       2 shards of the 83 test files   ~4 to 5 min each   (every test but the every-byte one)
app-pack-bytes  the every-byte test             6 parts (stage 2), ~8 to 9.5 min each (estimate), job limit 25 min
app             "app (Flutter analyze, tests, Android debug build)": green only if all three parts succeeded
```

How the split keeps every check:

- **Every file runs exactly once.** `tools/ci/test-shard.py` lists every `*_test.dart` under `app/test` (the same files
  `flutter test` finds by itself) and gives each to one shard, longest first to the lightest shard. It computes the
  split for all shards in every shard and refuses to print anything unless together they hold every file once, none
  twice, and no shard is empty. A new test file is always run (it gets a default weight). The shard number and the
  number of shards come from `strategy.job-index` and `strategy.job-total`, so the split always matches the jobs that
  really exist; adding a shard is adding a number to the matrix and nothing else. The weights only balance the
  shards (now 801 and 801 weighted seconds, 42 and 41 files).
- **Every file was really loaded.** `tools/ci/assert-tests-ran.py --files` reads the JSON report and fails the shard if
  a file of its list was never loaded as a suite.
- **The every-byte test runs, in its own job, and nowhere else; no other test can hide behind its name** (SEC-14).
  The full name is written once per job as `EVERY_BYTE_TEST` (with `EVERY_BYTE_PREFIX`, its first words, in
  `app-tests`). `tools/ci/exact-name-regex.py` escapes it and anchors it at both ends, so the file shards pass
  `--name '^(?!every single byte of the real starter pack, changed in turn, is refused \(all bytes with NN_EXHAUSTIVE=1 or in CI\)$)'`:
  every test but the one with exactly that full name. The same script fails the shard unless the prefix and the full
  name each occur exactly once in all of `app/test` (a copy with the same name in another file would otherwise be
  left out by the shards and never loaded by the pack job). After the tests, `assert-tests-ran.py --none-start-with`
  fails a shard if a test that ran there starts with the prefix (a second test named "every single byte of the real
  starter pack, changed in turn, with ..." runs, and turns the shard red until it is renamed). The pack job passes
  `--plain-name` with the full name; `--passed` fails it unless that exact test ran and passed (not skipped), and
  `--only` unless it was the only test that ran. If someone renames the test, the pack job finds nothing and fails
  (`flutter test` exits 79 on "No tests ran", checked on the PC), and the source check fails the shards. All three
  failures were proved on the PC with temporary probe files (section 7).
- **The old name stays green only when everything is green.** The final job `app` keeps the old id and name, runs
  with `if: always()` (a skipped job would count as passed for a required check) and fails unless every part's result
  is `success`. A future branch ruleset requires the same six names as today.
- `fail-fast: false` in both matrices: one failing shard does not cancel the others, so a push shows all its failures.
- The test jobs no longer install Java (only the build needs it).

**Stage 1 (committed first, replaced by stage 2):** `app-pack-bytes` had one part with `NN_FLIP_SHARD=0/1`: every
byte, alone on its runner, from the start, without the every-31st-byte test, the other files and the build in front of
or behind it. Estimate then: about 42 to 52 min for the whole push instead of 49 to 63.

**Stage 2 (in place):** the matrix is `part: [1, 2, 3, 4, 5, 6]` and the job's `timeout-minutes` 25. Part k
(`strategy.job-index` k - 1) runs the test with `NN_FLIP_SHARD=<k - 1>/6` and `NN_EXHAUSTIVE=1`, and changes the
offsets `i` with `i % 6 == k - 1`; together the six parts change every offset exactly once, each spread over the
whole pack, so they cost the same. `NN_EXHAUSTIVE=1` is set in the step itself, so the every-byte mode no longer
depends on the runner's `CI=true` (SEC-15). The check step requires the line `flip shard <k - 1>/6:` for every part
count, 1 included: the test prints it only in the every-byte mode, so a part that sampled (every 97th byte) or a test
without the switch (every byte in every part, six times the cost) fails instead of passing.

Time per part, **measured on the 16-core PC** (16 worker isolates): one part 189 s (the app-developer's run),
part 4 of 6 (`3/6`) 3 min 6 s (the qa-engineer's), part 6 of 6 (`5/6`) 3 min 12 s (the infrastructure-engineer's).
**On CI it is still an estimate** until the first run of this file: 2,471 to 3,072 s / 6 = 412 to 512 s per part on 4
vCPUs, plus about 1 min of setup: **8 to 9.5 min per part, about 9 to 10 min for the whole push** (the static job, the
file shards and the database job are shorter), against the job limit of 25 min. The first run's job summaries give
the real figure; a part past 25 min is a red job, never a green one.

**Also changed:** the concurrency group. A newer push to a branch still cancels the older run there; on `main` every
commit now gets its own run and its own verdict. Before, a docs commit cancelled the merge's run on `main`
(40830498040 for 51b7666 was cancelled by ec5c69d). This adds runs on `main` only; drop it if minutes matter more.

## 4. The ideas, with numbers

Pure speed-ups first: the same checks on every push, nothing moved.

| Idea | Time saved per push (basis) | Coverage change | Needs security / owner | Risk |
|---|---|---|---|---|
| **A. The APK build, format and analyze in their own job, beside the tests** (applied) | 1.5 to 4.2 min wall (measured build 91 to 251 s, now off the critical path) | none | no | low; one more job's setup (about 1 min of runner time) |
| **B. The every-byte test in its own job** (stage 1, applied) | about 7 to 9 min wall (measured: 167 to 209 s every-31st-byte test, 40 to 51 s checksums test, 41 to 65 s setup, the build; no longer in front of or behind it) | none: the same test, all bytes, every push | no | low; with one part the job ran 42 to 52 min (estimate), under the test's own 60-min timeout; stage 2 splits it |
| **C. The every-byte test split over 6 runners** (stage 2, applied) | another 33 to 42 min wall: the push goes to about 9 to 10 min (estimate: measured test time / 6 + 1 min; one part 3 to 3.2 min on the 16-core PC, measured) | none: every byte, every push; the parts' union is checked by count in each part | security-engineer reviews the partition (it is a pack test); qa-engineer verifies | low; a part that ignored the switch fails its check |
| C'. Same with 8 parts | another 1.5 to 2 min (estimate) | none | as C | 17 jobs per run against the Free plan's 20 at once: a second run at the same time waits |
| **D. The other 83 files over 2 shards** (applied) | none on the wall today (the pack test is longer); keeps them at about 4 to 5 min instead of 6 to 7 so they never become the critical path after C | none: every file once, checked | no | low |
| E. Caches | pub: already cached (`pub get` 1 to 2 s, measured); Flutter SDK: cached (17 to 26 s); Gradle downloads: cached (a miss cost 141 s plus 53 s to save, measured in 40795649171); test jobs skip Java now (0 to 20 s each). `build_runner` is not run in CI (generated files are committed): nothing to cache. | none | no | low |
| E'. Caching `app/build`, `.dart_tool` or Gradle task outputs between runs | maybe 30 to 60 s of the build (not measured) | none in theory | no | **not done**: a stale output can hide a real failure |
| F. Concurrency: cancel superseded pushes | already on (per branch) | none | no | none |
| G. Larger runners (8 or 16 cores) | the every-byte test roughly 2 to 3 times faster per runner (estimate) | none | owner (money) | **not possible**: GitHub offers them only to organisations on the Team or Enterprise plan |
| H. Flutter's own `--total-shards`/`--shard-index` | worse than D | none | no | **not used**: it splits the tests inside each file, so every shard compiles and loads all 83 files, and it cannot split one long test |
| I. The every-byte test with plain `dart test` (or AOT, `-c exe`) instead of `flutter test` | on the PC, 241 against 342 µs per pack at 16 workers (B-12): maybe 1.4 times faster (not measured on CI) | none if the test is the same | app-developer moves the test out of `flutter_test` (`pack_verify.dart` and `zip_store.dart` do not import Flutter); qa-engineer verifies | medium; a second test runner to keep in step |

Ideas that change what runs on a push (**not applied; each needs the security-engineer's review and the owner's OK**).
Each also contradicts `docs/PLAN.md` line 985 ("Automated tests (run in CI on every push)"), which would change with it.

| Idea | Time saved | Coverage change on each push | Needs | Risk |
|---|---|---|---|---|
| **J. Docs-only pushes skip `database`, `gateway` and the app parts** (a small job decides from `git diff --name-only` between `github.event.before` and the commit, no new action; a new branch, a force push or `workflow_dispatch` runs everything; the job `app` reports "skipped by the docs rule" as a pass only in that case) | the whole run for 16 of the last 60 commits on `main` (27%, measured); after C that is about 10 min and 70 to 85 runner-minutes per docs push | a commit that changes only `docs/**` and the top-level `*.md` gets no app, database or gateway verdict. No test reads `docs/` today (checked: no test opens a file there; `deno fmt` and `deno lint` cover only `supabase/functions/` and `tools/`), so the verdict would be the same; but that stays true only while nobody adds such a test | security-engineer, owner | medium: the rule itself must be right; a mistake would let code through unchecked |
| K. The every-byte test nightly and when pack code changes (`app/assets/packs/**`, `content/starter/**`, `app/lib/content/{zip_store,pack_verify,pack_installer}.dart`, `app/tool/pack_builder*.dart`, the test file, `pubspec.lock`, `ci.yml`), plus before each merge and release | after C, about 4 to 5 min more (the push is then as long as the file shards); about 50 to 60 runner-minutes per push | every push keeps the every-31st-byte sample (113,085 of 3,505,610 bytes, 3.2%) and the structural tests; the full sweep only when the pack, its reader or the SDK changes, and at night | security-engineer, owner | medium: a change outside the list that weakens the reader is found only at night. Only worth it if the repository goes private (section 5) |
| L. The every-31st-byte test skipped where the every-byte test runs in full | 2.8 to 3.5 min of one file shard (not on the wall after C); about 12 core-minutes | none in what is checked (its offsets are a subset of every byte on the same push), but a test would skip itself on CI | qa-engineer, security-engineer | low; little gain, **not recommended** |

What must **never** be skipped on any push: `secrets` (a secret can arrive in any file, a doc included, and it scans the
whole history), `hygiene` (a forbidden file can be added anywhere) and `osv` (new advisories appear without any change
in the repository; it costs 6 to 8 s). Also never: format and analyze on any change to `app/`, and the full app,
database and gateway checks on every merge to `main`.

Not worth doing: the `ubuntu-24.04-arm` runner (the same 4 vCPUs; not checked whether `flutter-action` has a Linux
arm64 Flutter build), a bigger job timeout (it hides the problem), and batching docs commits is a habit, not a CI
change (the orchestrator can push docs commits together with the next code commit).

## 5. Cost

Public repository (today): standard runners are free. Billing rounds every job up to a whole minute, so each extra
job costs about one minute of setup and rounding.

| Design | Wall time per push | Runner minutes per push (estimate) |
|---|---|---|
| Before the split | 49 to 63 min (measured) | 55 to 71 |
| Stage 1 (replaced) | about 42 to 52 min | 60 to 77 |
| Stage 2, 6 parts (in place) | about 9 to 10 min (estimate until the first run) | 66 to 84 (about 15 to 20% more than before the split, for about 6 times faster) |

If the repository goes private again: the runners have **2 vCPUs** (half of today), Linux costs $0.006 a minute, and
the Free plan includes $12 a month (about 2,000 minutes). The old single job would then **fail** every push (the
every-byte test on 2 vCPUs is about 80 to 100 min, over its own 60-minute timeout and the job's 75). Stage 2 with 6
parts would take about 15 to 18 min per push and about 120 to 140 runner-minutes ($0.72 to $0.84), so about 14 to 16
pushes a month fit into the free amount. More parts keep the wall time down but not the minutes (the work stays the
same). For a private repository the honest choices are paying, or idea K (owner and security-engineer).

## 6. Stage 2: the test change (in place; app-developer, qa-engineer verified, security-engineer reviewed)

In `app/test/starter_pack_test.dart`, only the every-byte test and its helpers:

1. `NN_FLIP_SHARD` (`<index>/<total>`) is read; absent or empty is `0/1`. Anything else that is not two whole numbers
   (at most 9 digits) with `total >= 1` and `0 <= index < total` **fails** the test (never skips it), and so does a
   `total` larger than the number of bytes in the pack (a part with no byte to change).
2. In full mode (`NN_EXHAUSTIVE=1`, which the CI step sets, or `CI=true`) the test changes the offsets
   `index, index + total, index + 2 x total, ...`: `_refusedFlipsOfEvery` takes a first offset, and worker `w` takes
   `first + w x step` with stride `workers x step` (with `first = index`, `step = total`). The sampled local mode
   (every 97th byte) is unchanged.
3. It expects exactly `(bytes.length - index + total - 1) ~/ total` refusals (with `0/1` that is `bytes.length`, the
   old assertion). Over all parts these add up to `bytes.length`: every offset once. A unit test checks the partition
   with the real helpers (lengths 1 to 1,009 and the real pack, 1 to 7 parts, 1 to 16 workers).
4. It prints one line `flip shard <index>/<total>: <tried> of <bytes.length> offsets refused`, in full mode only. The
   CI check requires `flip shard <index>/<total>:` with the job's own numbers, for every part count.
5. The test's name (the CI jobs select it by name) and its 60-minute timeout are kept.

In `ci.yml`, job `app-pack-bytes`: `part: [1, 2, 3, 4, 5, 6]`, `timeout-minutes: 25`, `NN_EXHAUSTIVE: "1"` on the
test step. To change the number of parts, change the matrix list and nothing else (the switch is built from
`strategy.job-index` and `strategy.job-total`); keep the parts' estimated time under the 25-minute limit.

## 7. How this was checked, and what was not

- **Checked on the PC:** `tools/ci/test-shard.py` on the real `app/test`: 83 files, 42 and 41 per shard, none twice,
  the union is all 83; refuses a shard number out of range, an empty shard (200 shards) and a missing folder.
  `flutter test test/starter_pack_test.dart` with the file shards' `--name` exclusion: 16 tests passed in 64 s, the
  every-byte test not among them; `assert-tests-ran.py` passed `--files` and `--passed` for the every-31st-byte test
  and failed (exit 1) for the excluded every-byte test. A `--plain-name` that matches nothing: `flutter test` exits 79
  ("No tests ran") and the check fails too.
- **Stage 2 and SEC-14/15, on the PC (2026-10-29):** the file-shard form of `starter_pack_test.dart` with the exact
  filter: +18, all passed, the every-byte test not among them, `--files` and `--none-start-with` pass. A temporary
  probe test named "every single byte of the real starter pack, changed in turn, with the CRCs repaired": under the
  old prefix filter it ran nowhere and the old check passed (exit 0); under the exact filter it ran and
  `--none-start-with` failed (exit 1); the source check failed with it present (exit 1). A second test with exactly
  the full name in another file: the source check failed (exit 1); a longer name containing it: `--only` failed the
  pack check (exit 1). `NN_FLIP_SHARD=0/1` with `CI` and `NN_EXHAUSTIVE` unset: the test passed in sampled mode and
  printed no `flip shard` line; the new pack check failed (exit 1), the old one-part check (`--passed` only) passed.
  `NN_EXHAUSTIVE=1 NN_FLIP_SHARD=5/6` with `CI` unset: `flip shard 5/6: 584268 of 3505610 offsets refused`, passed
  in 3 min 12 s, the check passed (and failed for `4/6`). `NN_FLIP_SHARD=0/999999999`: the test failed ("more parts
  than the 3505610 bytes"). `actionlint` 1.7.12: no findings.
- **The workflow (stage 1):** `actionlint` was not installed on this PC then. Instead a PyYAML
  check against `origin/main`'s `ci.yml`: the same triggers; `permissions: contents: read` only, none per job; no
  `pull_request_target`; no `secrets.` in any expression; the five other jobs byte-for-byte unchanged; the six job ids
  and names kept; no new action (every `uses:` is one already in the file, pinned by a 40-character SHA); every job
  has a timeout; every `needs` exists; the aggregate runs `always()`; `bash -n` on every `run:` block; every command
  of the old app job (`pub get --enforce-lockfile`, format, `analyze --fatal-infos`, `flutter test`, the timing
  summary, the arm64 debug build) is in one of the parts. All passed. Read twice by hand.
- **Not checked:** a real run on GitHub (the first push of this change is the proof; its job summaries show the times
  per part, so the CI time per part is an estimate until then); all six parts run one after the other on the PC (parts
  `3/6` and `5/6` were run; the others follow from the partition test); the private-repository numbers (scaled from
  the measured ones by the number of vCPUs).
