# CI on `m9-content`: why the `app` job runs out of time, what changed, and what a merge needs

Infrastructure Agent, 2026-10-28 (board item B-9). Every number below comes from the GitHub logs of the runs named, read
with `gh run view`; nothing was built or tested on the PC for this note.

## 1. The short answer

- The `app` job is not slow in general. 77 of its 78 test files (985 tests, none failing) finish within **8 minutes** of
  the test step starting. The rest of the 30 minutes goes to **one file**, `app/test/starter_pack_test.dart`, and
  inside it to the two byte-flip tests over the real pack.
- On CI the test "every single byte of the real starter pack, changed in turn, is refused" flips **all 3,505,610
  bytes** of pack 0.8.0 (it switches to all bytes when `CI=true`, which GitHub always sets). Every flip copies the
  pack and checks it again, so the cost grows with the **square** of the pack size: it took 27 minutes for pack 0.5.1
  (0.9 MB) and would take **about 7 to 10 hours** for pack 0.8.0 (3.5 MB). A GitHub-hosted job may run at most 6 hours.
- **No change to the workflow alone can make this job green while that test runs in full on every push.** The
  workflow changes below are applied and will be needed in any case, but the test itself needs a decision by the
  owner and the security-engineer (section 4). Nothing in any test was changed.

## 2. Where the 30 minutes go (run 40760468617, commit 8370409, pack 0.8.0)

The app job ran from 20:08:05 to 20:38:22 (30 min 17 s) and was cancelled by its `timeout-minutes: 30`.

| Step | Time |
|---|---|
| Set up, checkout, Java, Flutter (SDK from the cache) | 34 s |
| `flutter pub get --enforce-lockfile` | 1 s |
| Format | 2 s |
| Analyze | 15 s |
| **Test** | **1,761 s (29 min 21 s), cancelled** |
| Build the dev APK | skipped (not reached) |

Inside the test step (seconds after it started):

| When | What |
|---|---|
| 0 to 472 s | 77 files finish, 985 tests pass. The slowest files: `pack_installer_test` 53 s, `app_flow_test` 43 s, `golden_screens_test` 36 s, `playthrough_test` 31 s, `voice_in_test` 29 s, `tutor_lesson_test` 18 s; the others are under 15 s each. |
| 146 s | The first four tests of `starter_pack_test.dart` pass. |
| 146 to 1,345 s | "one changed byte anywhere ... (every 31st byte here)": 113,084 flips in about 1,199 s, about **10.6 ms per flip**. |
| 1,345 to 1,761 s | "every single byte ...": running alone (one core of four busy) until the job is cancelled, about 1 percent of its 3,505,610 flips done. |

Only two test files ever ran at once: `package:test` 0.6.18 (the version Flutter 3.47.8 uses) runs half as many files
as there are cores (`math.max(1, Platform.numberOfProcessors ~/ 2)` in `test_core/lib/src/runner/configuration/values.dart`),
and the runner has 4 cores. A local run on this PC (16 logical cores) already runs 8 files at once.

How the time grew with the pack (app job only):

| Run | Commit | Pack | Pack size | Test step | Result |
|---|---|---|---|---|---|
| 40691265791 | ef9e974 | 0.4.0 | 281,348 B | 264 s | green, the last green app job; the build took 235 s |
| 40714441272 | ed61d79 | 0.5.1 | 893,119 B | 1,724 s | all tests passed (the every-byte test took 1,638 s, 1.83 ms per flip); the job hit 30 min during the build |
| 40760468617 | 8370409 | 0.8.0 | 3,505,610 B | over 1,761 s | cancelled at 30 min |

From the two measured costs per flip (1.83 ms at 0.9 MB, 10.6 ms at 3.5 MB), the full every-byte test on pack 0.8.0
needs 3,505,610 x 7.2 to 10.6 ms, **about 7 to 10 hours** on one core. After run 40697841520 (13:35, failed at the
format step) every run on `m9-content` was cancelled, either by a newer push (the `cancel-in-progress` group) or by
the 30-minute limit; none finished.

Two side observations:

- The test sets `timeout: Timeout(Duration(minutes: 10))`, but in run 40714441272 it ran 27 minutes and passed, so the
  10 minutes do not cap it in practice (hand-off to the qa-engineer, low priority).
- The "about 14 minutes" measured on the PC is most likely the sampled mode: without `NN_EXHAUSTIVE=1` the every-byte
  test flips every 97th byte (36,141 flips). With `NN_EXHAUSTIVE=1` and pack 0.8.0 a local run should also take hours.
  Not measured here (no tests in this wave).

### Why each flip costs so much, and what the test really proves

From `app/lib/content/zip_store.dart` and `pack_verify.dart`: each flip makes a fresh 3.5 MB copy and calls
`verifyPack`, which calls `readStoredZip`. That reader computes the CRC-32 of every file in a plain Dart loop and, for
a pack that passes the field checks, writes the zip again (two more CRC-32 passes over every file) and compares it byte
for byte. A valid pack is therefore CRC-checked three times on every verification, on CI and on the phone.

Every single flipped byte is refused **inside `readStoredZip`**, before the signature is looked at:

| Region of pack 0.8.0 | Bytes | Share | Refused by |
|---|---|---|---|
| File data (1,290 files, of them `manifest.json` 324,837 B and `manifest.sig` 64 B) | 3,346,048 | 95.45% | CRC-32 of that file (CRC-32 detects every change confined to 32 consecutive bits, so every one-byte change) |
| Local file headers | 69,450 | 1.98% | the field checks, or the byte-for-byte canonical re-write |
| Central directory | 90,090 | 2.57% | the same |
| End record | 22 | 0.00% | the same |

So the every-byte test proves the container's integrity checks exhaustively; the Ed25519 signature and the SHA-256
hashes are proven by the other tests (`a signature from any other key is refused`, `pack_verify_test.dart`).

## 3. What I changed (`.github/workflows/ci.yml`, `tools/ci/test-timings.py`)

| Change | Why | Gain |
|---|---|---|
| `app` job `timeout-minutes` 30 to 45 | The job without the full every-byte test needs about 27 min today (1 min setup, about 22 min test critical path through the every-31st-byte test, about 4 min build). 30 left no margin. | Room for the job once the test question is settled |
| `flutter test --concurrency="$(nproc)"` | Use all 4 cores instead of 2; the suite already runs 8 files at once on the PC, so this is not a new condition for the tests | The 77 other files finish in about half the time (estimate); the critical path is still the starter pack file |
| `--file-reporter json:$RUNNER_TEMP/flutter-test.json` and a step "Where the test time went (job summary)" (`python3 tools/ci/test-timings.py`, standard library only, never fails the job, runs `if: always()`) | The next slowdown is read from the job summary (slowest files, slowest tests, any test still running when the report ends) instead of parsing 1 MB of log | Diagnosis |
| `actions/setup-java` with `cache: gradle` (the same pinned action, its own cache input; the default key patterns match `app/android/**`) | The Gradle wrapper and dependencies were downloaded on every run | Some of the 233 s Gradle time (not measured yet) |

Not changed: the six job ids and names, triggers, permissions (`contents: read`), the concurrency group, every other
job, and every test.

Ruled out:

- **Shards inside the job** (`--total-shards` / `--shard-index`, or several `flutter test` processes): the runner has 4
  cores and `--concurrency` already uses them; the critical path is one test in one isolate, which no shard splits.
- **A matrix of app jobs**: renames the job (`app (1)` and so on); the brief keeps exactly six jobs.
- **`timeout-minutes: 360`**: the full test needs 7 to 10 hours, so it would still fail, after 6 hours per push.
- **Building in parallel with the tests**: it would save about 4 minutes of a 7-to-10-hour problem, and needs a
  second work tree and background processes. Worth it only if the job is still close to its limit after section 4.
- **Running the tests with `CI` unset** (the test then samples): that weakens the CI coverage, which the brief forbids.

### How this was validated

- `actionlint` is not installed on this PC (installing it needs the owner's OK). Instead, a PyYAML parse with
  structural checks against `origin/main`'s `ci.yml`: six jobs with the same ids and names, the same triggers,
  `permissions: contents: read`, the same concurrency group, every `uses:` pinned to a 40-character SHA, only known
  step keys; the folded `run:` line printed as the runner will see it. All passed.
- `bash -n` on the new test command line; `python -m py_compile` on the script; the script run on a made-up report
  (with a cut-off last line and an unfinished test) and on a missing file: both exit 0 with the expected text.
- **A real run is the only proof.** The first push after these changes will still be cancelled (now at 45 minutes) as
  long as the every-byte test runs in full; its job summary will show the timing table.

## 4. Proposal for the every-byte test (for the owner and the security-engineer; NOT applied)

| Option | Who | Coverage kept | Coverage dropped | CI time (pack 0.8.0) |
|---|---|---|---|---|
| **A. Same test, cheaper flips.** A1 a faster CRC-32 (indexed loop, slice-by-8 table); A2 compute each file's CRC once in the reader's canonical check (today three passes); A3 the test flips a byte in place and flips it back instead of copying 3.5 MB; A4 the test spreads its byte range over isolates (4 on CI). | app-developer, measured by qa-engineer | All of it | Nothing | Estimate (not measured): the every-byte test 7 to 10 h down to roughly 20 to 40 min; the every-31st-byte test 20 min down to 1 to 2 min. Still grows with the square of the pack. A2 also cuts the phone's install-time check by about two thirds of its CRC work. |
| **B. Every structural byte, per push.** Flip every byte of the headers, directory and end record (159,562 bytes) in turn, keep the every-31st-byte sample over the file data (about 107,900 data bytes really flipped), and add a direct CRC-32 test (known vectors, single-bit changes). | app-developer, decided by the security-engineer | 100% of the bytes where the zip rules decide; the data bytes by CRC-32's guarantee plus the sample | The brute-force run over the remaining 3,238,000 data bytes (92.4% of the pack) | About 30 to 50 min today, 2 to 5 min after A |
| **C. Keep the full test, move it off the per-push path.** A separate workflow (not one of the six jobs): by hand, weekly, and on any push that changes `app/assets/packs/**`, `zip_store.dart` or `pack_verify.dart`; a matrix of byte ranges (the test would read `NN_BYTE_RANGE`). A release-gate and merge item the orchestrator checks. | infrastructure-engineer (workflow), app-developer (range switch); the owner OKs a new workflow | All of it, but not on every push | Blocking on every push | After A: about 8 jobs of 5 min; without A: about 8 jobs of 1 to 1.5 h |
| D. Only the bytes that changed since the last proven pack | | | | Not recommended: a rebuilt pack moves every offset, so almost every byte "changed". |

**Recommendation:** A in every case, then B on every push and C before each pack publish, each merge to `main` and the
release. The owner and the security-engineer decide B and C.

## 5. What a merge of `m9-content` into `main` needs

Read with `gh` on 2026-10-28:

- **Checks.** No run on `m9-content` has been green since run 40691265791 (ef9e974, 12:51). The last pushed commit,
  8370409, was cancelled at 30 min. Three local commits (3102362, c8ab73d, 9767a0a) are not pushed yet and have never
  run in CI. The merge needs all six jobs green on the branch's last commit, and then on `main` after the merge.
- **Branch protection.** `main` has **no** branch protection and no rulesets (`GET .../branches/main/protection` gives
  404 "Branch not protected", `GET .../rulesets` gives `[]`). Nothing on GitHub enforces the six checks today; the rule
  is kept by hand. Since the repository is public, protection is now available on the free plan (owner's decision,
  below). Careful: "require status checks" refuses a directly pushed merge commit, because a new commit has no checks
  yet. Then the merge commit is pushed to a branch first and `main` is fast-forwarded to it after it is green.
- **The way in.** `origin/main` is 0 commits ahead of `origin/m9-content` (39 behind), so the merge has no conflicts.
  M6, M7, M8 and the voice fix went in as `--no-ff` merge commits.
- **Pull requests.** None open. **Dependabot has never opened a pull request** (`.github/dependabot.yml` is on `main`
  with weekly updates for actions, npm and pub). All actions and npm packages are at their latest releases (below),
  which explains no PR for those, but not for pub. Its status page (Insights, Dependency graph, Dependabot) is only
  readable in the browser. Dependabot alerts and security updates are switched off for the repository
  (`automated-security-fixes: enabled false`; the alerts API says "disabled"). OSV in CI covers the lock files.
- **Secrets.** One repository secret exists, `BACKUP_DATABASE_URL` (name only seen, 2026-10-27).
- **The weekly backup.** `backup.yml` runs on a schedule (`17 3 * * 0`, Sundays 03:17 UTC) from `main`. Its only run so
  far (40586463016, 2026-10-27) was green; the first scheduled run is **Sunday 2026-11-01**. `fetch-trust-roots.yml`
  last ran green on 2026-10-26.

## 6. The Android release keystore (part 9e): the owner's steps

Today every release build is signed with the debug key (`app/android/app/build.gradle.kts`, `buildTypes.release`). The
owner makes the keystore himself, on this PC; Claude never sees the file or its password. Do these at the PC with
1Password open, in any PowerShell window. Nothing here goes into the repository or the chat, except the fingerprint
in step 5 (public).

1. **Make the password.** In 1Password, new item, type Password, title `Nitznutz Android release keystore`. Generate
   a password of 32 characters, **letters and digits only** (a `\`, `=`, `:` or `#` would break the properties file
   in step 7). Save the item.

2. **Find `keytool`** (it comes with Android Studio):
   ```powershell
   $kt = "C:\Program Files\Android\Android Studio1\jbr\bin\keytool.exe"
   if (-not (Test-Path $kt)) { $kt = "C:\Program Files\Android\Android Studio\jbr\bin\keytool.exe" }
   Test-Path $kt
   ```
   You should see `True`.

3. **Choose the place, outside the repository:**
   ```powershell
   New-Item -ItemType Directory -Force "$env:USERPROFILE\nitznutz-secrets" | Out-Null
   $ks = "$env:USERPROFILE\nitznutz-secrets\nitznutz-release.jks"
   Test-Path $ks
   ```
   You should see `False`. If it says `True`, stop and tell Claude: a keystore is already there and must never be
   overwritten.

4. **Make the key.** The password is asked for twice; paste it from 1Password (nothing shows while you paste). Passwords
   typed at a prompt are not saved in the PowerShell history.
   ```powershell
   & $kt -genkeypair -v -keystore $ks -storetype PKCS12 -alias nitznutz -keyalg RSA -keysize 4096 -validity 10000 -dname "CN=Nitznutz, O=Nitznutz, C=IL"
   ```
   You should see (the wording may differ a little) `Generating 4,096 bit RSA key pair and self-signed certificate
   (SHA384withRSA) with a validity of 10,000 days for: CN=Nitznutz, O=Nitznutz, C=IL` and then `[Storing C:\Users\ramfr\nitznutz-secrets\nitznutz-release.jks]`.
   (In this format the key's password is the keystore's password; keytool does not ask for a second one.)

5. **Read its fingerprint** (public; the server needs it). It asks for the password once:
   ```powershell
   & $kt -list -v -keystore $ks -alias nitznutz | Select-String "SHA256:"
   ```
   You should see one line, `SHA256: ` followed by 32 pairs of hex digits separated by colons. Copy that line into the
   1Password item as a field `SHA-256 fingerprint`.

6. **Back it up twice.** In the 1Password item: Edit, add a File, choose `C:\Users\ramfr\nitznutz-secrets\nitznutz-release.jks`,
   and add a text field `alias` = `nitznutz`. Save; the item now shows the file. Then copy the same `.jks` file to a USB
   stick you keep at home (the password stays only in 1Password). **If this key is lost, the installed family app
   cannot be updated any more; it must be removed, and its data on the phone with it.**

7. **The signing file Gradle will read** (outside the repository):
   ```powershell
   $props = "$env:USERPROFILE\nitznutz-secrets\release-signing.properties"
   notepad $props
   ```
   Notepad asks whether to create the file: Yes. Type these four lines, paste the password after both `=` signs that
   end empty, save, close:
   ```
   storeFile=C:/Users/ramfr/nitznutz-secrets/nitznutz-release.jks
   keyAlias=nitznutz
   storePassword=
   keyPassword=
   ```
   (Forward slashes on purpose.) Then let only your user read it:
   ```powershell
   icacls $props /inheritance:r /grant:r "${env:USERNAME}:F"
   ```
   You should see `processed file: C:\Users\ramfr\nitznutz-secrets\release-signing.properties` and
   `Successfully processed 1 files; Failed processing 0 files`.

8. **Tell Gradle where the file is** (only the path, not a secret):
   ```powershell
   Add-Content -Encoding ascii "$env:USERPROFILE\.gradle\gradle.properties" "nitznutz.releaseSigning=C:/Users/ramfr/nitznutz-secrets/release-signing.properties"
   Select-String -Path "$env:USERPROFILE\.gradle\gradle.properties" -Pattern "nitznutz.releaseSigning"
   ```
   You should see that line once.

9. **Tell Claude "keystore done"**, with the `SHA256:` line from step 5. Never the password, never the file.

What Claude does next (a later wave, briefed by the orchestrator):

- In `app/android/app/build.gradle.kts`: a `release` signing config read from the file named by the Gradle property
  `nitznutz.releaseSigning`. A `prod` release build without it **fails with a clear message** instead of silently
  using the debug key; the `dev` flavour stays on the debug key (the dev tools need it). PLAN.md, the "Build detail
  (M0), Android app" bullet (line 697), gets one sentence on this; the key table row "Android upload keystore"
  (line 928) already says "password manager plus an offline backup" and stays.
- Build `flutter build apk --release --flavor prod` and check with `apksigner verify --print-certs` (Android build tools
  36.0.0) that the certificate's SHA-256 equals the one from step 5.
- Add `{"package_name": "app.nitznutz.nitznutz", "cert_sha256": ["<the fingerprint, lower case, no colons>"]}` to the
  `android_allowed_apps` row on the live project (next to the dev entry, `docs/setup/supabase-deploy.md` step 7).
  Without it the server refuses every enrolment of the family build (`supabase/functions/_shared/enrol.ts` fails closed).
- Never install a release-signed `app.nitznutz.nitznutz` over a debug-signed one: Android refuses the update, and
  removing the app first deletes its local data and enrolment.

## 7. Versions due for an update

| Item | Pinned | Latest | Due? |
|---|---|---|---|
| actions/checkout | v7.0.1 | v7.0.1 (2026-07-20) | no (the SHA matches the tag) |
| actions/setup-java | v6.1.0 | v6.1.0 (2026-10-14) | no |
| actions/setup-node | v7.1.0 | v7.1.0 (2026-10-08) | no |
| actions/upload-artifact (backup) | v7.0.2 | v7.0.2 (2026-10-07) | no |
| subosito/flutter-action | v2.23.0 | v2.23.0 (2026-03-25) | no |
| denoland/setup-deno | v2.0.5 | v2.0.5 (2026-07-03) | no |
| gitleaks (`tools/ci/tool-versions.env`, CI and the pre-commit hook) | 8.28.0 | 8.30.1 (2026-03-21) | **yes**: new version and both checksums (Linux for CI, Windows for the hook) from the release's checksum file; the security-engineer reviews |
| osv-scanner | 2.7.0 | 2.7.0 (2026-10-12) | no |
| Deno (`ci.yml` twice, local dev) | 2.9.6 | 2.9.8 (2026-10-21) | **yes**, a patch release; bump all places together and run `deno task check` |
| Supabase CLI (npm) | 2.122.0 | 2.122.0 (2026-10-23) | no |
| Flutter | 3.47.8 | 3.47.8 (newest stable tag) | no |
| Pub packages | `pubspec.lock` | 21 newer versions outside the current constraints, among them `sherpa_onnx` 2.0.0 to 2.0.1 (a direct, exactly pinned package) | the app-developer looks at them, the security-engineer checks the advisories; OSV finds none open today |
