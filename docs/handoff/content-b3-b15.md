# Handoff: content and engine session (B-3, B-15, content parts of B-13)

Written 2026-10-30 by the orchestrator when the owner asked to restart with his new Claude configuration. Read
`CLAUDE.md`, `PROGRESS.md`, `docs/agents/README.md` and `docs/agents/board.md` first, then this file.

## Where

- Worktree `D:\nitznutz-content`, branch `content-b3-b15`, cut from `voice-quality-diagnosis` (abe04a0, which holds
  the Hebrew developer list D1–D16 not yet on `main`). Local only: **nothing pushed**.
- Do not touch the other worktrees (`D:\nitznutz-b26` = B-26 PR 4, `D:\nitznutz-alerts`, `D:\nitznutz-voicefix`) or the
  main checkout.
- `tools/bin/gitleaks.exe` was copied from the main checkout (ignored by Git) so the pre-commit hook runs here.

## Commits on the branch

| Commit | What |
|---|---|
| 24717b7 | **B-3 done (QA pending).** 1,300 of the 1,304 text-ready and owner-approved rows come out of the generators exactly as `ui_text`; all 56 proposed rows keep their text; two regenerations are byte-identical. New `tools/regen_content.py` (regenerates in a fixed order) and `tools/test_hebrew_sources.py` (10 tests, green). D6: `labelSynonyms` accepts spoken קופסה/קופסא for תֵּבָה (`app/lib/speech/spoken_options.dart`, test `app/test/spoken_options_test.dart`). New vo ids `vo:fb.size.big/.small/.spread`, `vo:b.mathb18.1.h2`–`.7.h2`. PLAN.md bullet added. Full suite: 1,268 passed, 10 skipped, 1 failed: `starter_pack_test` "built from the sources" (expected: the bundled signed 0.9.0 pack no longer matches; goes with the owner-signed 0.10.0). |
| c4f4dcc | **B-15 measurement and spec.** `app/test/mastery_reachable_test.dart`: 91 of 100 skills cannot reach fresh mastery (89 have no understanding check; NUM-A-04 and MATH-B-03 need a second check type; 11 of 12 core skills have one representation); `graph.report()` has 97 lines. Target tests skipped unless `--dart-define=QA_OPEN=true`. Spec `docs/knowledge/b15-content-spec.md`: 211 new activities (197 checks, 14 second representations), 175 representation relabels, 74 check relabels, 150 items get tags (94 strict §5.3, 42 E1 same-tag, 57 E2), NUM-B-16 / MATH-B-07 / MATH-B-06 / D3 in §4, generator changes G1–G5, hand-offs H-A to H-F. |
| (this commit) | `docs/knowledge/b15-hebrew.md` (hebrew-text-editor): 62 final strings, 9 reused lines, 13 extra strings (X1–X6), 4 `proposed` (P1 Band A spot hint 3; P2–P4 fb.sort_shift without "לֹא"); and this file. |

## Uncommitted in the worktree (work in progress, stopped mid-way)

- `app/lib/content/pack_validation.dart` (+43) and `app/test/content_validation_test.dart` (+70): the app-developer's
  start on the **skill-id band rule** (every skill id matches `<DOMAIN>-<BAND>-<NN>` and its band letter equals the
  skill's `band`; the validator refuses a pack that breaks it). Not reviewed, not run. Review, finish, test, or discard.
- Nothing else: the generator part of B-15 (G1–G5) had not started (the agent was writing its tests).

## Remaining steps, in order

1. **Curriculum addendum** (curriculum-expert, edit only the spec): append "## Addendum after the Hebrew pass" deciding
   the editor's questions: H11b answer key (the pack teaches tap, soap, towel; the spec says rinse); H21 (a ball also
   leaves a round mark in sand); items the spec asks for that already exist (COL-B-01 reverse `b.colb01.7–9`, SHP-A-06
   train and tree, COL-B-03 purple `b.colb03.7`, LOG-B-09 `b.logb09.6`) → relabel instead, with new totals; X1/X1c
   prefer a masculine noun (chicks/ducks) over frogs to avoid three feminine size clips; fb.sort_shift for Band B by rule
   (Band A keeps today's line until the owner decides P2–P4); the OBJECTS nouns to add.
2. **app-developer, B-15 part 1** (tests first): G1–G5 (per-item `check`/`rep`, spot_error → `error_spotting`, label
   rule per template, any primary skill for count_tap/number line/balance/sort/spot, per-item feedback override,
   MATH-B-10 chart scene, new items appended so existing ids keep their numbers), the relabels, the tagged distractors,
   the NUM-A-07 M-CNT-SIZE tag per the spec, the skill-id band validator rule (finish the WIP above).
3. **app-developer, B-15 part 2:** the 211 new activities (less the addendum's relabels) and the §4 fixes with the
   Hebrew from `b15-hebrew.md` exactly; P1–P4 stay out (Band A keeps today's lines). Editor notes: Band A `solid_box`
   says קֻפְסָה (NAMES says תֵּבָה); NUM-B-03 falling rows use X4b; every P/X line its own vo id; new files
   `review: needs-editor`. Then `tools/regen_content.py`, pack version 0.10.0, and a LOCAL build signed with a
   throw-away key made through the library (`generateKeyFile`) in the session scratchpad, never `pack_builder keygen`
   (it replaces `assets/pack_signing_public_key.txt`), never the owner's key, never publish, do not replace the bundled
   0.9.0 pack. Then `mastery_reachable_test.dart` with `QA_OPEN=true`: target all 100 reachable and `graph.report()`
   empty; if so remove the skips.
4. **qa-engineer, one pass** over B-3 and B-15 together (the 4 held logb08 alt-text rows are expected; add the §5.3 and
   label-rule lints from the spec's H-E). **security-engineer**: the validator rule, the new accepted-word path
   (קופסה), the pack.
5. **Regenerate the review tables** (`tools/export-hebrew-review.py`, then `tools/hebrew_voice_review.py`), check the
   statuses survive (the 39 owner-approved rows), PLAN.md "Build detail (board B-15)" bullet, analyze, format, full
   tests (about 22 min locally; CI about 10 min, a push cancels a running CI so batch pushes). Then push the branch
   (no PR/merge without the owner). Merge order the owner expects: PR 4 (B-26), alerts, the voice branch, then this
   one; after each merge rebase and regenerate `docs/review/*` instead of hand-resolving. Known conflict: `homeBubble`
   in `app/lib/strings/he.dart` with B-26.
6. Board and PROGRESS (orchestrator only), then the report to the owner.

## Board hand-offs to file when the work lands

- app-developer: `tap_answer` hint actions must draw what hints 2 say (D2 dots and fingers; audit F12) and a stage
  numeral row under the groups (NUM-B-16 "two frames plus the numeral").
- design-director: ten-frame outline with empty cells, train and tree layouts, SHP-A-08 pictures, CS-A-03 board shapes,
  shoe-box cuboid vs cube (F9).
- infrastructure-engineer: CI does not run `tools/test_hebrew_sources.py` yet.
- voice-and-sound-director: re-voice the changed lines after the owner's approval (incl. 3 core lines, `homeBubble`).
- engine proposal (curriculum): a passed check on a two-option item should not count alone (§4.1).
- hebrew-text-editor: G9/G10 say `מֵ` before א but the table keeps `מִאַרְבַּע` (`activity.b.numb13.14`); the
  generator follows the table (`FROM_TSERE` in `author.py`).

## Decisions only the owner can make (collect into one batch for the report)

1. The V1 pronunciation prompts (34 of the 56 proposed rows also change `ui_text`): unblocks `b.logb08.1–4` alt text,
   G8 (`אֵינוֹ` → `הוּא לֹא`, 7 ordinal rows), `שְׂמָאלִי` (numb13), `כׇּל` (numb11), `וִידַעְתֶּם`.
2. The NUM-A-11 pairing line and NUM-A-07 counting line (Q2 drafts); D12 balance sides (with the design-director).
3. P1 (Band A spot hint 3 `כֻּלָּם דּוֹמִים, חוּץ מֵאֶחָד…`) and P2–P4 (fb.sort_shift without "לֹא", by rule).
4. §5.3 for single-misconception skills (E1, 42 items): two distractors with the same tag (recommended) or two-option.
5. E2 (57 items): new catalogue tags in B-5 (an "added instead" tag such as M-OP-SWAP, M-MUL-ADD, pairs, days, times
   of day) or accept them untagged; and the catalogue name mismatch (M-LOG-NOT/M-NOT, M-PART-MISS/M-PPW, M-NUM-WRITE,
   M-SHP-FACE) as part of B-5.
6. Voice on or off for SHP-B-08/09 (now `voiceAnswer: false`, so the קופסה matcher is not reachable yet).
7. Release: pack 0.10.0 signed with his key and published together with the next app version.
