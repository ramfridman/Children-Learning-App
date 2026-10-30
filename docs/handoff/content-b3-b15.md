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
8. P2 to P4 for Band A is now **high priority**: today's `fb.sort_shift` says "we look for the same colour" in LOG-A-03,
   the LOG-A-01 spots and the SHP-A-02 spots, where the rule is kind or shape (curriculum-expert recommends P3 and P4).
9. P1: keeping Band A spots on today's `k_spot` h3 contradicts the spec's H-A.
10. The 9 existing rows with `פַּרְפָּר` (singular, wrong qamatz): `activity.count.butterflies.3`, `.4`, `.5` and the
    `lesson.butterflies` celebration (ids in `b15-hebrew.md` §6.7); screen nikud only, no re-voicing.
11. V1 for LOG-B-08 (`הִיא` after the noun, `אִם לֹא` instead of `אַחֶרֶת`); the two new prompts follow his choice.

## Update 2026-10-30 (second session): step 1 done, part 1 built, part 2 not started

The owner wound this session down after B-15 part 1; one orchestrator session ("Implementation status review") takes over.

- **Step 1 done:** the curriculum-expert's `## Addendum after the Hebrew pass` (A1 to A6) at the end of
  `docs/knowledge/b15-content-spec.md`. New targets: **203 new activities** (189 checks, 14 second representations),
  **32 relabels** to a check, 85 check-label changes. The hebrew-text-editor's `## 6. After the curriculum addendum` in
  `docs/knowledge/b15-hebrew.md` has the final text for every string the addendum changed (X1a to X1c dropped).
- **Part 1** (app-developer: the skill-id band validator rule, G1 to G5, the A5 `rule` field mechanism, relabels, tagged
  distractors): see the part 1 commit message for counts and what was verified.
- **Known red on this branch (by design, do not weaken the rule):** the band rule refuses the bundled owner-signed
  `starter-0.9.0` pack (18 Band B story activities, `b.mathb01.1–12` and `b.mathb02.1–6`, were marked Band A by a
  `pick_spec` bug, now fixed in the sources). `lib/app/state.dart` checks the bundled pack with `verifyPack`, so about
  20 test files that load it fail in setUpAll (`starter_pack_test`, `playthrough_test`, `template_sessions_playthrough_test`,
  `voice_answer_pack_test`, …). The rule can only merge together with the owner-signed 0.10.0 pack.
- `tools/test_hebrew_sources.py` fails `test_done_rows_have_ui_text` (292 position-keyed rows: 159 tag lines shifted,
  133 option labels re-keyed; no text changed) until the review tables are regenerated (step 5).
- Part 1 open points for the curriculum-expert: M-CNT-CARD has no fitting line outside give-N (`vo:fb.card` is the give-N
  line), so it stays untagged in MATH-A-01/02, MATH-B-01/03/06/07/08/10 until part 2 adds a `tag_lines` line per context;
  confirm the values chosen for COL-A-01/02/03/05, LOG-A-01, SHP-A-01/02 (in `content/units/*.json`); SHP-A-05
  `sign.shape` and `window.shape` as reverse checks too? Tags: 140 of 193 (target 150; MATH-B-10 6, NUM-A-08 3 and
  SHP-A-02 1 held for lack of a fitting line). Mastery with `QA_OPEN=true`: 84 of 100 unreachable (was 91).
- Part 2 also: add `SORT_SHIFT_BY_RULE['shape' / 'kind']` in `tools/author.py` with the editor's text and set
  `rule: shape` on COL-B-04 items 2 and 4, LOG-B-08 items 3 and 4 and the new items; add H30 through `tag_lines`;
  NUM-B-16's pictures, hints and check (its §4 option values and tags are in).

### Brief for B-15 part 2 (app-developer; not started)

Read the spec §1 to §6 **and** the addendum A1 to A6 (the addendum replaces the §1 rows it names), and
`b15-hebrew.md` §1 to §6 (§6 wins over earlier sections). Build the 203 new activities, appended after each skill's
existing items so existing ids keep their numbers, with the Hebrew exactly as written; new files `review: needs-editor`;
every new P/X/H line its own vo id. P1 to P4 stay out of Band A (Band A keeps today's lines). Then
`tools/regen_content.py` (twice, byte-identical), pack version 0.10.0, a LOCAL build signed with a throw-away key made
through the library (`generateKeyFile`) in the session scratchpad (never `pack_builder keygen`, never the owner's key,
never publish, do not replace the bundled 0.9.0 pack), and `mastery_reachable_test.dart` with `QA_OPEN=true`: target all
100 reachable and `graph.report()` empty, then remove the skips. Points from the Hebrew re-check:

1. **LOG-B-08 rectangle rule:** a square is also a rectangle, so that item's pool must hold **no squares**; today's
   pool has two squares and no `shape_rect_*` (use `shape_rect_*` sprites; the curriculum-expert confirms the pool).
2. **CS-A-01 hands (A1):** answer `step_towel`; the prompt is the editor's new one without `מִיָּד`
   (`רוֹחֲצִים יָדַיִם. מָה עוֹשִׂים אַחֲרֵי הַסַּבּוֹן?`); teeth (H11a) keeps `מִיָּד`. The tap picture should read as
   "opening the tap" (design-director).
3. **SHP-B-09 (A2):** two two-option items, {solid_cylinder, solid_box} and {solid_cone, solid_box}, both with H21.
4. **CS-A-03:** write the solutions up first (up×3 then right; up×3 then left×2), so "towards the flag" is a straight line.
5. **LOG-B-09:** use the reviewed h3 `מְחַפְּשִׂים מַשֶּׁהוּ שֶׁהוּא…`, not the generator's old `צָרִיךְ שֶׁגַּם…`; the red and
   orange squares of the second item must look clearly different (design-director).
6. **fb.sort_shift (A5):** `vo:fb.sort_shift.shape` (P4's text) and `.kind` (P3's text) in Band B only, fired only when
   the child sorted by the wrong attribute (`.shape` when the child sorted by colour); Band A and Band B colour items
   keep today's line.
7. **Butterfly:** the singular is `פַּרְפַּר` (A6 copied a slip with qamatz); use §6.5's forms for chick, butterfly,
   frog and shoe. Never merge Band B's `תֵּבָה` into a Band A unit (`solid_box` says `קֻפְסָה` in Band A).
8. LOG-B-08's two new prompts follow the owner's V1 choice; until then, build them in the form the existing four use.
9. Check that `bowl` and `cloud` have a `def` entry in `logic.json` for LOG-A-09.

After part 2: one QA pass over B-3 and B-15 (plus the §5.3 and label-rule lints of H-E), the security review (the
validator rule, the קופסה accepted-word path, the pack), regenerate `docs/review/*` (`tools/export-hebrew-review.py`,
then `tools/hebrew_voice_review.py`), the PLAN.md bullet, analyze, format, full tests, then push the branch (no PR or
merge without the owner).
