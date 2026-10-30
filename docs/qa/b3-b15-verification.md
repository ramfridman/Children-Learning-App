# QA: B-3 and B-15 (parts 1 and 2), branch content-b3-b15, tip 5761e72

QA engineer, 2026-10-30. One pass for the finished feature. Not committed. Nothing in `content/`, `tools/`, `app/lib` or the
bundled pack was changed; the only new file in the app is `app/test/content_lints_test.dart` (lints, section 5).

## Verdict

**Not ready to sign yet: 5 findings (2 major) first.** Everything that fails with the throw-away 0.10.0 pack is listed below;
nothing else fails. The red that the owner expects (bundled 0.9.0 against the band rule) is confirmed and is the only red
in the worktree.

## 1. What ran in the worktree (D:\nitznutz-content)

| Command | Result |
|---|---|
| `dart format --output=none --set-exit-if-changed .` (app) | 308 files, 0 changed |
| `flutter analyze` (app) | No issues found |
| `flutter test` (whole suite, once, 109 files) | 2,394 tests: 2,228 passed, 5 skipped, **161 failed in 36 files** |
| `python -I -X utf8 tools/test_generators.py` | 27 tests OK |
| `python -I -X utf8 tools/test_hebrew_sources.py` | 10 tests OK |
| `python tools/regen_content.py` twice | `git status` clean both times: byte-identical |
| `deno task check` | **not run: deno is not installed on this machine** (CI covers it) |

The 36 failing files are exactly the developer's count (161 tests in 36 files). The 50 that fail in `setUpAll` print
`PackRejected(content) ... band: is A, but its skill MATH-B-01 is in band B` (the 18 Band B story activities of the 0.9.0 pack);
the other 111 are widget and golden tests whose app cannot open a land because the bundled pack is refused (`land-play` not found).

## 2. The 36 files against a throw-away 0.10.0

Method: `local_build.dart` (library `buildPack`, `generateKeyFile`, the throw-away key in the scratchpad) built
`starter-0.10.0.nnpack` from the tip sources (4,438,810 bytes, version 0.10.0, 9 builder warnings, all "spoken number begins
the number of another option" on existing Band B items). Because the app takes one key for every pack, the Nitzi character
pack was re-signed with the same throw-away key. Both went into a **copy** of the repo in the scratchpad (`qa_root`); in the
copy the pack replaced `starter-0.9.0.nnpack`, the key file was replaced, and 4 version strings in 3 tests were changed from
0.9.0 to 0.10.0. The worktree, the bundled pack and `assets/pack_signing_public_key.txt` were not touched.

Result over the 36 files: **604 passed, 8 skipped, 12 failed**. 31 files are fully green, including `tutor_lesson`
(9), `warm_up_flow` (2), `character_pack` (26), `playthrough` (6), `template_sessions_playthrough` (8), `starter_pack`
(19, including "built from the sources"), `next_lesson`, `placement`, all goldens of home, land, lessons and the B-26 doors.
The 12 failures, 5 files, are **not** bundled-pack failures:

| Test | Cause | Finding |
|---|---|---|
| `qa_voice_answer_audit` "all 967 activities: the flag agrees" | `b.numb08.13` and `.14` ("אֵיזֶה מִסְפָּר חָסֵר?", numerals only) have `voiceAnswer: false`; the audit's own rule says true | QA-1 |
| `lesson_flow` x3 (phone, tablet landscape, portrait) | line 120 expects `שְׁלוֹשָׁה` in the correct line of `count.butterflies.3`; the caption is now `שָׁלוֹשׁ! סְפַרְתֶּם כׇּל אֶחָד פַּעַם אַחַת.` | QA-2 |
| `voice_in` x6 | `col.world.apple.red` now offers red, orange, pink (the tagged distractors replaced blue and purple) but the tests script `Scripted.says('כחול')`: 3 behaviour tests (no `confirm-yes`, `confirm-again`; unclear speech gets `core.listen.confirm`) and 3 goldens (`voice_mic_confirm_*`, 4.6 to 9.5 percent) | QA-2 |
| `unit_golden` "the new activities, phone" | the pattern question lost its "הַאִם" (`הַסֵּדֶר חוֹזֵר?`); golden `unit_logic_pattern_yes_no_phone` is stale | QA-2 |
| `publish` "index equals the shared vector" | `testvectors/publish-starter.json` still says 0.9.0, 767 items | QA-3 |

PNGs opened: `qa_root/app/test/failures/unit_logic_pattern_yes_no_phone_{master,test}Image.png` (text change only, layout fine),
`voice_mic_confirm_phone_{master,test}Image.png` (three round tiles, pink/orange/red render cleanly; the state differs
because the script says blue). The other goldens of the 36 files match.

## 3. The two test edits in `qa_voice_answer_audit_test.dart`: both right, one too broad

- `ורד` in `_sayable`: **right.** The pack spells pink `וָרֹד` (defective); `normalizeHebrew` keeps the letters, so the
  token is `ורד`. The list already holds both spellings of every other colour (`אדום אדם`). The matcher folds an inner vav
  (`phoneticKey`), so a child's "ורוד" hears the right option; the audit's "saying an option is heard as that option only"
  and "no two options sound alike" tests pass with it. The trigger is real: `col.world.apple.red` got a pink tagged distractor.
- `_echoSkills = {NUM-B-16, MATH-A-06}`: **right in effect, broad in form.** NUM-B-16: spec section 4 says `voiceAnswer`
  stays false (the answer is built from the numbers in the question); MATH-A-06: "3 coins, a coin for each apple, how many
  apples?" has the answer in the prompt, which the reviewed-echo test would otherwise refuse. It hides no defect today
  (every tap item of both skills is `false`). But it exempts the whole skill, so a future tap item of these skills
  that should speak would not be caught. Suggest an id list (`b15.matha06.1/.2`, `b.numb16.10/.11`) when the app-developer
  next touches the file. It also does not explain QA-1: NUM-B-08 is not in the set.

## 4. Mastery and the validator

- `flutter test --dart-define=QA_OPEN=true test/mastery_reachable_test.dart`: **"F2: 0 of 100 skills cannot reach fresh
  mastery"**; the reachable test passes. `graph.report()` has 76 lines: 75 "items in only one representation" plus
  "LOG-A-09 is not connected to any other skill"; its test stays skipped without QA_OPEN, and fails with it. As briefed, not filed.
- Sharing with three friends (`pack_validation.dart` `share && (bins < 2 || bins > 3 || items % bins != 0)`) **is tested**:
  group "sharing (B-15: three friends)" in `content_validation_test.dart` (valid 2/6, 3/6, 3/3; refused 3/5, 2/5, 3/4, 1/2,
  4/8). The session code (`SortDragSession`) deals with `bins[k % bins.length]`, so it is not tied to two. Skill-id band rule
  and the activity and lesson band rules: 7 tests in "skill ids and bands", passing.
- `content_validation` 96, `pack_builder` 17, `content_schema` 11, `spoken_options` 3: all passing.

## 5. Lints added (H-E), `app/test/content_lints_test.dart`, 7 tests, read `content/starter` directly

1. Representation label of every activity follows spec section 2 (exceptions: `story` on CS-A-01, LOG-A-08, MATH-A-05,
   NUM-A-14; `symbolic` on MATH-B-14). **Passes on all 967.**
2. Each skill file declares exactly the representations its activities use (G2). Passes on all 100.
3. Every `spot_error` is `error_spotting` (G1). Passes (71).
4. Every activity names real skills and one of the five check types in use. Passes.
5. Section 5.3 ratchet: items with 3+ options and fewer than two tagged wrong answers. **331 in the pack: 21 of the 200 new,
   310 older.** The test pins both: the 21 by id with the reason, the 310 as a count. A new gap fails; a fixed one must be
   taken off the list.
Mutation check (in the copy): changing one representation, one check type and one tag made tests 1, 2 and 3 fail as
intended. Format and analyze clean.

The 21 new items: M-CNT-CARD has no fitting line (10): MATH-A-01 x2, MATH-A-02 x2, MATH-B-03 x2, MATH-B-06 x2, NUM-A-14 x2.
E2 no catalogue tag (6): MATH-B-10 x2, LOG-A-09 x2, SHP-A-02 x2. One tag by the spec's own rule (5): NUM-A-13 x2 (M-ORD-CARD),
LOG-B-01 x2 (the pattern has no second wrong place), NUM-A-02 `b15.numa02.3` (count_tap). So "known: M-CNT-CARD, E2" explains 16;
the other 5 follow the spec's single-tag rows. Also measured: 84 items carry two distractors with the **same** tag (E1,
owner-chosen default), shown for the record, not linted.

## 6. Other checks

- All 200 new activities (and every activity) are in a lesson; the 15 new lessons are Band A, their items exist and are in
  Band A, `review: needs-editor`. Eleven of the 15 hold one to four items.
- `fb.sort_shift` lines: colour 29 (23 in Band A), `.shape` 12, `.kind` 7, `.size` 2; no Band B item uses the kind line.
- By land the 200 new are Colours and Robots 38, Logic 36, Shapes 29, Maths 42, Numbers 55. The addendum says 203 (Maths 44,
  Numbers 56): see QA-5.

## 7. Findings

| Id | Sev | Where | What | Owner |
|---|---|---|---|---|
| QA-1 | major | `tools/band_b.py:309` (`numpick3`, kind `pick` gives `voice` false); `b.numb08.13`, `.14` | The two "missing number in a row" items are not voiced; the B-24 rule (`qa_voice_answer_audit`) and NUM-B-11's identical items (voiced) say they should be. Fails with 0.10.0. Either `voice=True` there (then the pinned 310/657 become 312/655) or the curriculum-expert decides NUM-B-08 stays off and the audit gets an exception. **Content changes, so before signing.** | app-developer, curriculum-expert decides |
| QA-2 | major | `lesson_flow_test.dart:120`; `voice_in_test.dart` (lines 125, 141, 344); goldens `voice_mic_confirm_{phone,tablet_landscape,tablet_portrait}`, `unit_logic_pattern_yes_no_phone` | Stale tests and goldens after the content and text changes (section 2). Cannot be seen in the worktree, because those files fail earlier. Update the script to say `כתום` (or `ורוד`), the expectation to the new caption, regenerate the 4 goldens on purpose and review them. | app-developer (hebrew-text-editor to confirm `שָׁלוֹשׁ!` as the correct line of `count.butterflies.3`) |
| QA-3 | major (release) | `testvectors/publish-starter.json`; `publish_test.dart:19`; `state.dart:132` and `test/support/starter.dart:9` (pack file name); `starter_pack_test.dart:13,184,444`; `lesson_controller_test.dart:57`; `lesson_flow_test.dart:254` | Release steps the branch does not do: swap `starter-0.9.0.nnpack` for the signed 0.10.0 (names and version expectations), regenerate the vector with `NN_UPDATE_VECTORS=1`, run the Deno suite (`content_publish_test.ts` and the tutor tests read the vector). | app-developer + infrastructure-engineer |
| QA-4 | minor | spec section 3 | 21 new items below section 5.3, pinned in the lint (section 5). Needs the owner decisions 4 and 5 and an M-CNT-CARD line. | curriculum-expert |
| QA-5 | minor | commit 3ede21b | 200 built against 203 in the addendum (Maths 42 against 44, Numbers 55 against 56); no commit text says which three were dropped. mastery is 100/100, so no skill suffers. | curriculum-expert / app-developer to name them |
| QA-6 | minor | `qa_voice_answer_audit_test.dart` `_echoSkills` | Exempts whole skills (section 3). | app-developer |

## 8. Not checked

`deno task check` (no deno here); the real phone; sound and voice lines; the new pictures (ten-frame, train, tree, SHP-A-08,
CS-A-03 boards) and any layout of the 200 new activities, because a visual sweep of the new items needs the signed 0.10.0 pack (the next QA step after signing);
whether the `.kind` line's claim "it is the same colour" is true for each LOG-A-01 / LOG-A-03 sort item (a curriculum-expert
check of the sprites); the security review (validator, `קופסה` path, pack), which is the security-engineer's.

## 9. Before the owner signs 0.10.0

1. Settle QA-1 (it changes content); rebuild and re-run `test_generators`, `test_hebrew_sources`, regen twice.
2. Security review of the validator rule, the `קופסה` synonym path, and the pack.
3. Sign with the owner's key; then QA-3 steps and QA-2 test and golden updates; whole `flutter test` must be green, and
   `deno task check` on CI.
4. Re-run QA's lint file and the QA_OPEN mastery test on the final pack.
