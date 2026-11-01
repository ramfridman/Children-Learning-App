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
| SEC-B36-1 | `content-publish` refuses the 0.11.0 index (1,118 items, the gateway takes at most 1,000) | low | open |
| SEC-B36-2 | Compiled Python files (`tools/__pycache__/*.pyc`) are tracked; the hygiene job does not refuse them | low | open |
| SEC-B36-3 | A newer pack this app cannot play replaces the playable one, with no way back on that app (not new on the branch) | low | open |

None of them blocks signing (part J). SEC-B36-1 blocks the publish of 0.11.0 (part M) and will turn the Deno vector test red in
part K. SEC-B36-2 should be fixed before the PR to `main` (part L).

## Advisories checked (2026-11-01)

Locked versions: flutter_svg 2.3.2, vector_graphics 1.2.4, vector_graphics_compiler 1.3.2, xml 7.0.1, http 1.6.0, cryptography 2.9.0,
drift 2.35.3; Flutter 3.47.8.

- flutter/packages PR 11740 (merged 2026-05-28): a denial of service in `vector_graphics_compiler` on SVGs with circular or exponential
  `use` references. Read, not verified for 1.3.2; it does not apply to this pack (no picture has `use` or `href`, which
  `starter_pack_test` refuses).
- CVE-2026-27704 (pub client path traversal, Dart before 3.11.0 / Flutter before 3.41.0): the toolchain here is Flutter 3.47.8, so it
  is fixed.
- No advisory found for flutter_svg or xml in 2026 (web search; OSV.dev showed none for these versions on 2026-10-31, B-40 review).
