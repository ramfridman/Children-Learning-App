# Security review: B-36 part I, the next content pack (starter 0.11.0, app 0.6.0+6)

Security-engineer, 2026-11-01. Branch `next-pack` at `4216286`, everything not yet on `main` (`git log origin/main..next-pack`,
21 commits; `git diff origin/main...next-pack`, 1,189 files). Read-only: no code was changed. While the repository is public, the
detail of open findings is kept in the git-ignored `docs/security/private/b36-review.md`; this file holds the public record only.

## Scope

In scope: the pack sources and generators (`tools/band_b36.py`, `pictures_b36.py`, `pictures_b38.py`, `hint_lines.py`, the changed
`author.py`, `band_b*.py`, `hebrew_voice_review.py`, `make_picture_sprites.py`, and `regen_content.py`), everything they put in
`content/starter` (1,118 activities, 183 lessons, 100 skills, 52 misconceptions, 238 pictures), `content/tutor-moves.json`,
`content/voices.json`, `content/lines/core.he.json`, the pack version and `minAppVersion`, the app's version (`pubspec.yaml`,
`lib/core/config.dart`), the new and changed hint code (`play/hints/tap_plans_c.dart`, `tap_plans.dart`, `tap_plans_b.dart`,
`tap_geometry.dart`, `spot_plans.dart`, `content/hint_ladder.dart`, `play/tap_answer_session.dart`, `match_pairs_session.dart`), the
string changes in `strings/he.dart`, and the secrets and hygiene of the branch. For comparison only (not changed on the branch): the
pack verifier, validator and installer (`content/pack_verify.dart`, `pack_validation.dart`, `pack_installer.dart`,
`content_repository.dart`, `capabilities.dart`), `tool/publish_lib.dart`, `tool/voice_gen_lib.dart`, and the gateway functions
`content-publish`, `sync-push` and `tutor-turn` with `_shared/db.ts`.

Not in scope: the signing itself (part J), the swap of the bundled pack (part K), the publish (part M), the voicing (B-45), iOS.

## Verified

- **No change to a security control.** The branch changes none of the pack verifier, validator, schemas, installer, zip reader,
  signature or key, the gateway (`supabase/` untouched), the migrations, `app/network_hosts.json`, `pubspec.lock`, any workflow or
  the hooks. `pubspec.yaml` changes only the version. No new package or tool.
- **Secrets.** gitleaks 8.28.0 with the repository rules over the 21 branch commits: no leak. Over the working tree: three hits,
  all in git-ignored files (the developer's local app config and two Flutter test-kernel caches under `app/build/`); none is
  tracked. No key, token, signing key, throw-away key, `.nnpack` or scratch path is in the diff; the bundled pack is still the
  signed 0.10.0. No new personal data: the names in the audition files were on `main` already (the family characters).
- **What the generators can put in a signed pack.** The generators read only repository files, use no network, no `eval`, no
  environment beyond `PYTHONIOENCODING`, and write only under `content/` and `docs/review/`. Every new or changed picture (45
  SVGs) holds only `svg`, `path`, `polygon`, `polyline`, `rect`, `circle` and `ellipse`; the only URL in any of the 238 pictures is
  the SVG namespace (no script, `href`, `use`, `image`, `style`, `url(` or `data:`).
- **Prompt path.** Every activity's question, goal and answer labels, and every misconception's parent text, fits the
  `content-publish` shape (length, no control, format or line-separator character once the display isolates are taken out), and
  every id, tag, skill, template and lesson id fits the `sync-push` and `content-publish` patterns (checked for all 1,118
  activities, 183 lessons and 52 misconceptions with a script). No pack string or tutor move holds markup, braces, a `{child}`
  placeholder, a URL or instruction-like text. The eight new tags fit `M-[A-Z]{2,5}-[A-Z0-9]{2,12}`.
- **Voice answers.** 19 new items answer by voice (`x.mathb17.12/13`, the new MATH-A-01/02, NUM-A-07, MATH-B-07/08/18, NUM-B-10/17,
  COL-B-01 items); all are `tap_answer` choices of numbers or of labels, held by the existing validator rule (B-24); no new `speech`
  (accepted-word) entry and no new matcher code. Hearing stays on the phone.
- **Pronunciation (`content/voices.json`).** The two entries respell only the word for "two" (pointed and plain) as `שתַּיִם`. Every
  token in the pack, the app strings and the review table that holds either form is a form of "two" (with a prefix ו, ב, ל, וּבִ);
  "twelve" (`שְׁתֵּים`) does not match; the result matches neither entry, so a second pass changes nothing. The map holds fixed text
  only, runs on the owner's PC only (`voice_gen`, `audition`; nothing at runtime, nothing on the gateway), and the cost gate counts the
  respelled text. Nothing about a child passes through it. The test that pins this ("content/voices.json respells the number
  two ...", `app/test/voice_gen_test.dart`) is **not committed**: it showed up uncommitted in the worktree during this review (not
  written by the security-engineer). It passes; it should be committed with the branch.
- **Hint code against malformed pack data.** Every number the new plans index with is bounded by the schemas (set counts 0 to 20,
  chart counts 0 to 8, numerals 0 to 100), and each plan returns the generic plan when what it needs is missing (`_plate` checks 1 to
  10, `_inTwos` an even count, `money` a chart of whole-shekel coins with no empty column, `_hiddenPart` a whole of at most 10 that
  the question names). The new `7000 ~/ n` in `count` is behind `n == 0 → generic`. `_sentence` now returns null to fall back to the
  family plan. No new crash path was found; `hint_second_way_test`, `stage_stacked_test`, `pack_installer_test` and `voice_gen_test`
  pass (99 tests).
- **`minAppVersion` 0.6.0.** The 0.5.0 build of `6dde72d` refuses a share between three bins; 0.11.0 has three such items, so the
  raise is right. Assessment of 0.10.0 below.

## Pack 0.10.0 claims `minAppVersion` 0.5.0 (the question for B-37)

- **On a device.** The app installs only the pack inside it (`ContentRepository.starter`), plus the dev flavour's sideload page. No
  app downloads a pack from the server, so publishing never puts a pack on a phone. Two different builds carry the version 0.5.0: the
  release of `6dde72d` (refuses three bins, bundles 0.9.0) and every `main` build since B-15 (accepts them, bundles 0.10.0). A
  `6dde72d` app that were given 0.10.0 refuses it before anything is written and keeps playing its own pack. The claim is wrong
  metadata, but no device meets it.
- **On the server.** `content-publish` takes 0.10.0 (967 items). It replaces the server's index: the tutor's rows are keyed by pack,
  version and item, so a phone whose app bundles another version gets no context and uses RuleTutor (fails safe). `sync-push` checks
  `pack_version` as a pattern only, so sync never stalls on a version.
- **Recommendation.** Publish 0.10.0 as it is if B-37 goes first; do not re-sign it to fix the field (a second 0.10.0 with other
  contents is refused on the phone as "installed already, with different contents" and on the server as `version_conflict`). Bump the
  app version whenever the validator starts to accept something new, so `minAppVersion` can tell the builds apart.

## Findings

| Id | Title | Severity | Status |
|---|---|---|---|
| SEC-B36-1 | `content-publish` refuses the 0.11.0 index (1,118 items, the gateway takes at most 1,000) | low | fixed (`e0355a7`, re-verified 2026-11-01; closes when CI's Deno suite passes) |
| SEC-B36-2 | Compiled Python files (`tools/__pycache__/*.pyc`) are tracked; the hygiene job does not refuse them | low | fixed (`3eb40c6`, re-verified 2026-11-01) |
| SEC-B36-3 | A newer pack this app cannot play replaces the playable one, with no way back on that app (not new on the branch) | low | fixed (`e0355a7`, re-verified 2026-11-01); the downgrade case is SEC-B36-4 |
| SEC-B36-4 | After an app downgrade, the first start has no lessons (the second start plays the bundled pack) | low | open |

None of them blocks signing (part J). SEC-B36-1 blocked the publish of 0.11.0 (part M); it is fixed on `b36-sec-fixes`.

## Re-review of the fixes (2026-11-01, branch `b36-sec-fixes`, commit `e0355a7`)

### SEC-B36-1: fixed

- `content-publish/handler.ts` now exports `MAX_PUBLISH_ITEMS` 2,000, `MAX_PUBLISH_MISCONCEPTIONS` 200 and
  `MAX_PUBLISH_CHARACTERS` 40, and the shape uses them. `maxBodyBytes` is still `MAX_PUBLISH_BYTES` (1 MiB), and the body is
  still read with that cap before anything else is done. Nothing else in the gateway changed: the publish secret, the shape
  rules and the parameterised inserts in `_shared/db.ts` are the same.
- `publish_lib.dart` `encodeBody` refuses an index over any count or over 1 MiB, with the numbers in the message, before
  `HttpClient` is created. It runs in `publish()` and in `pack_builder publish --dry-run`. The publish secret is still never
  printed (the existing test still passes).
- `publish_test.dart` reads `handler.ts` and pins the four Dart numbers to the gateway's, and checks that the shape and
  `maxBodyBytes` use the constants. It also shows that a refusal comes before any connection (`127.0.0.1:1`).
- The Deno tests add 1,118 items accepted, 2,001 refused with nothing stored, and 2,000 accepted.
- **The 1 MiB body cap is fine.** The publish is behind the publish secret and sent only from the owner's PC; 0.11.0 is
  about 700 KB; anything over the cap is refused on the PC with a plain message. The cap binds at about 1,670 items, before
  the item cap. Raise both together, with a Deno test, when a pack passes about 1,500 activities. Each item is one insert in
  one transaction, which is fine for the Edge Function at this size.
- Run here: `flutter test test/pack_installer_test.dart test/publish_test.dart` (48 passed). The Deno tests were not run (no
  Deno on this PC); the finding closes when CI's Deno suite passes on the branch.

### SEC-B36-2: fixed

The four files are untracked; the root `.gitignore` has `__pycache__/` and `*.pyc`; `tools/ci/hygiene.sh` refuses `*.pyc` and
`__pycache__/`. Proof: the new pattern, applied to the tree of `4216286`, refuses exactly the four files. `hygiene.sh` on the
fixed tree passes.

### SEC-B36-3: fixed

- A newer pack that this app cannot play, arriving while a playable version is installed, returns `keptPlayable`. Nothing is
  written, and the playable version stays on disk, in the list and in `load()`.
- A hidden pack still replaces a hidden one. A newer playable pack still replaces an older one.
- An older pack is let in only when three things hold: the installed row is hidden, the arriving pack is playable by this app,
  and the installed copy, read back from disk and proven again with this app's key and capabilities, is not playable. The
  arriving pack has already passed the signature and every hash before this rule is reached.
- The developer's 8 new tests pass. These cover the bundled pack being played after a forged newer one, and over a hidden one
  that an older build stored.

**Can the "older playable over hidden" exception be used for a rollback?** No useful one. I checked by reading the code and
with a scratch probe test (not committed):

- The older pack must be signed by the owner's key; a pack signed by another key is refused at the signature (probe P4).
- It must be playable by this app, and the pack it replaces must be one this app cannot play. The device goes from no lessons
  to the owner's older lessons, which is what it would have bundled anyway.
- Whether the installed copy can be played is decided by proving it again on disk, not by the stored flag. So once the app is
  updated and can play the newer pack, the older pack is refused again ("an older pack is still refused when the installed
  newer one is playable").
- When an app that can play the newer pack brings it again, it is newer, so it is installed (probe P2).
- Making the installed copy look unplayable needs write access to the app's private storage (probe P3: a changed manifest lets
  the older pack in). With that access an attacker can already delete the packs, and the changed copy would fail `load()`
  anyway. This adds nothing.
- Today the only ways in are the dev flavour's sideload page and an app downgrade. Any future download path would have to
  keep the same signature and newer-version rules.

### SEC-B36-4 (new, low): first start after an app downgrade

**Why low:** only after the owner reinstalls an older app over a newer one with the data kept, and it clears itself on the
second start. Detail is in the private record.

## Advisories checked (2026-11-01)

Locked versions: flutter_svg 2.3.2, vector_graphics 1.2.4, vector_graphics_compiler 1.3.2, xml 7.0.1, http 1.6.0, cryptography 2.9.0,
drift 2.35.3; Flutter 3.47.8.

- flutter/packages PR 11740 (merged 2026-05-28): a denial of service in `vector_graphics_compiler` on SVGs with circular or exponential
  `use` references. Read, not verified for 1.3.2; it does not apply to this pack (no picture has `use` or `href`, which
  `starter_pack_test` refuses).
- CVE-2026-27704 (pub client path traversal, Dart before 3.11.0 / Flutter before 3.41.0): the toolchain here is Flutter 3.47.8, so it
  is fixed.
- No advisory found for flutter_svg or xml in 2026 (web search; OSV.dev showed none for these versions on 2026-10-31, B-40 review).
