# QA record: milestone L3, recognisers, the per-word matcher and LS09 say-it

Date: 2026-11-06. Verified by: qa-engineer. Branch `languages-l3`, worktree `D:\nitznutz-lang6`, head `f1d7de3` (the security review,
documents only) over the built code `bb53e0e`. Plan: `docs/milestones/L3.md` (section 1 "done when", section 4 the release gate,
section 7 spike, section 9 built and deferred). Frame: `docs/languages/frame.md` 2.3 LS09 and 5.1.

**Verdict: criteria 1 to 6 PASS as written, with five defects: three major (QA-L3-1, QA-L3-2, QA-L3-3) and two minor (QA-L3-4,
QA-L3-5). QA-L3-1 is the one that matters for the release: the gate exists as a function and a PC tool, but nothing in the app asks
it, so "a language that has not passed runs in echo mode" is not true of the build. No child can reach the microphone path today
(no model host, so a model gets onto a phone only by cable and a parent's switch), so L3 can merge; QA-L3-1 and QA-L3-2 must be fixed
before the first English or Russian model is pushed to a child's phone.** QA-L3-2 is the same finding as SEC-L3-2, and the second
half of QA-L3-3 is the same as the second half of SEC-L3-1 (the security-engineer found them reading, I proved them by running).

## 1. What ran

| Command | Result |
|---|---|
| `flutter analyze` (in `app/`) | No issues found (also after my files were added) |
| `dart format --output=none --set-exit-if-changed .` | 434 files, 0 changed (after my files) |
| `dart run tool/pack_builder.dart schema --check` | "The JSON Schema files in ../content/schemas are up to date." (the three failures of the developer's first run are fixed) |
| `flutter test`, the whole suite, once, in one run, on `bb53e0e` (before my files; `f1d7de3` changes only `docs/security/findings.md`) | **+3761 passed, 0 failed, 6 skipped** (17 min 51 s). The 6 skips: 3 are the local real-model tests (below, they run with `NITZNUTZ_MODELS`), 3 are the old ones (two open-defect proofs behind `QA_OPEN`, one Windows-only voice-tool test). This is the 3758 + 3 the developer's report implies |
| Real models: `NITZNUTZ_MODELS=<scratchpad>\asr-models flutter test test/say_tally_test.dart` | **+10 passed, 0 skipped**: the pinned sizes and SHA-256 of the Hebrew, English and Russian files in `model_spec.dart` match the files on this PC (`verifySync` empty for all three) |
| Real library and model, `tools\run-asr-eval.ps1 <340 Speech Commands clips> -Course eng -Sweep` (the cached sherpa-onnx 2.0.0 x64 libraries and `out\asr-eng`, no network, no recording of anyone) | English 20M, biased, 133 to 137 of 160 correct readings heard (83.1% to 85.6%, see QA-L3-5), **0 of 180 readings that should not be confident were confident** (upper bound 1.7%), the language verdict `notEnough` (adults only). Every row of the sweep (boost 3 to 16, accept 0.6 to 1.0) has 0 false-confident. This matches L3.md section 9 |
| My new files: `qa_l3_language_test.dart`, `qa_l3_open_defects_test.dart`, `qa_l3_say_golden_test.dart` | **+34 passed, 0 failed, 6 skipped** (the 6 skips are the defect proofs below) |
| `qa_l3_open_defects_test.dart` with `--dart-define=QA_OPEN=true` | **6 of 6 fail**, each for the reason in section 5, as they must until the fixes |
| Python (`python -I -m unittest discover -s tools -p "test_*.py"`: `test_generators.py`, `test_hebrew_sources.py`) | 38 tests OK |
| Deno, pgTAP | not run: L3 touches no `supabase/`, no `.github`, no gateway (`git diff --stat ad4280c..HEAD -- supabase .github app/pubspec.yaml app/pubspec.lock app/network_hosts.json` is empty) |

The suite was run once on the finished code, as asked. My three files were added afterwards and change no product file, so the whole
suite plus my files is 3761 + 34 passed and 6 + 6 skipped; I did not run the 3,800 tests a second time.

## 2. Acceptance criteria of L3 section 1

| # | Criterion | Verdict | Proof |
|---|---|---|---|
| 1 | The spike answers with numbers (confidence available?, open vs hotwords vs keyword spotting, threshold curve, load and memory, the choice and licence per language) | PASS (the numbers are the developer's; I re-ran the English one) | Section 7 of L3.md has every number asked for. The 0 of 180 false-confident and the sweep table were reproduced (section 1). The Russian model's hash pins match the files; the licence is the owner's/security's to confirm (SEC-L3-3) |
| 2 | F7: one pinned spec per course; hash before load; temp-then-rename installer, mismatch deletes; load only with the language's switch, off the main isolate; no host in `lib/` | PASS | `speech_models_test.dart` (18), my installer cases (section 3.4), `ls09_rules_test.dart` "models are loaded only when asked to prepare, in an isolate". The real files match the pins (section 1). `network_hosts.json`, `pubspec.yaml`, `pubspec.lock` unchanged |
| 3 | The per-word matcher: three outcomes, no "wrong"; accept and margin per language; quiet fallback; the false-confident gate | PASS | Section 3.1 |
| 4 | LS09 `say_it` 1.0: schema, model, validator rules, session, wiring; mic only on a tap and only with the language's switch; at most one more try; the picture goes on; speech evidence only for `spk`, at most half | PASS with QA-L3-3 and QA-L3-4 | Sections 3.2, 3.3 |
| 5 | The release gate function with its test; `say_eval.dart` and `run-asr-eval.ps1` | PASS as a function; **not enforced by the app (QA-L3-1)**; tool headline wrong in sweep mode (QA-L3-5) | Section 3.5 |
| 6 | Analyzer, format, whole suite, source rules for the mic and the vocabulary, PLAN.md | PASS | Section 1; `docs/PLAN.md` gains the L3 paragraph |

## 3. The items you asked about, one by one

### 3.1 The matcher has no "wrong" outcome: PASS

- The type is `confident`, `unsure`, `silence` (`qa_l3_language_test.dart` pins the three names; `ls09_rules_test.dart` fails on the
  vocabulary of a wrong answer in the matcher, the step and the session).
- By running, on the real lesson screen (`ls09_say_it_test.dart` and my cases): unsure and silence write **nothing** (no attempt
  row, no misconception, the lamp not lit as for a mistake, the line is the same kind "together" line and the word again); confident
  writes **one** row: `say_it`, `correct`, input `voice`, response `said`, tag empty, hint level 0. A second try that is good writes
  that one row only; two unsure results write none and the picture still goes on.
- New by me: two readings that disagree (target then a foil, and the reverse) are unsure (the target is not clear of the foil); a
  garbage reading beside the right one does not spoil it; Hebrew with niqqud in the reading is confident, a foil is unsure, nothing is
  silence.
- The code's decision is relative (accept and margin), so a word one edit from a four-letter target that the teacher did not list as
  a foil is confident (the property test says so). That is by design; the guard is the foil list, which is the curriculum's job.

### 3.2 The microphone: PASS on tap, per-child and per-course switch, model, failure and fallback; FAIL on gate and background

- **Only on a tap.** Counters of the fake recogniser stay `prepares 0, listens 0` for 4 s with the mic shown; a tap listens once;
  `ls09_rules_test.dart` finds one place that opens it. The OS permission is asked in the parent area only (`hasPermission(request:
  false)` in the lesson).
- **Both switches.** The step uses the language's switch and a model on the phone (`sayItAvailableProvider`). My cases: another
  child's switch on opens nothing; Russian on opens nothing in an English lesson; switch off with the model there is echo with
  nothing loaded; switch on with no model is echo (existing). **The "app's" Hebrew switch (`voice_enabled`, "answers by voice") is not
  consulted by a language step**; L3.md D-5 says the language's own switch is the switch and the security review lists the same point
  as SEC-L3-4 ("owner to confirm"). I did not file it: it is the plan as written. If you meant both must be on, say so.
- **Echo.** "I said it" opens the picture; an unscored item writes nothing; before it the picture is not a button. A recogniser that
  fails takes the mic away quietly (no message); the next item offers it again. A language item has no `voiceAnswer` (SEC-L3-1/L1-3).
- **At most one more try, never required.** After two listens the mic is not tappable; the picture goes on after any result; the
  celebration is reached. Quiet fallback: three unsure turns make the fourth item echo with no message (silence is not counted).
- **Gate (QA-L3-1) and background (QA-L3-2)**: section 5.

### 3.3 Speech evidence: PASS for the cap and the strand; a leak in the side channels (QA-L3-3)

`Engine._speechCounts` refuses a speech event for a skill that is not `spk`, a non-success, and any success that would pass half
(the first success can never be speech). Tested by the developer (three cases) and by me through the database: a scored heard item
writes `said/voice` then `picture/tap`, and `eventOf` makes the first `viaSpeech` and the second a plain answer. **But** `apply()
` goes on after `_updateSkill` refuses the event: `_updateGaps` counts a refused spoken success toward repairing a gap, and
`repStats` counts it as a try and a success. Say-it is meant for vocabulary skills (frame: "every new word"), which are not `spk`, so
every heard word there lands in those two places. Proof in section 5.

### 3.4 The model installer: PASS

The developer's tests cover a wrong hash, an oversize stream, a dropped connection, no host, a good install, and a stale `.part`.
New by me (`qa_l3_language_test.dart`):
- a host that ends early and cleanly (2,999 of 3,000 bytes): rejected, nothing under the real name or a `.part` name;
- same size, one byte flipped: rejected, nothing left; then a good install on the same folder succeeds;
- the first file right, the second wrong: the second leaves nothing, the first stays (it is the verified one), `verifySync` names the
  second, `looksInstalled` is false;
- a wrong first file under its real name is deleted even when there is no host;
- **a model whose sizes are right but one byte is not**: `modelInstalled()` is true (it checks sizes only) and `SherpaEngine.prepare()`
  throws before any native code and the engine is not ready: it is never loaded.

### 3.5 The release gate: the function PASSES; the enforcement is missing

- `languageVerdict` needs A, B and C present and each passing: A+B alone, A+C, B+C and an empty map are `notEnough`; adults alone,
  however good, never pass; one band that fails fails the language; 6 of 100 confident foils fails at once; exactly half of the
  correct readings confident fails ("most"). The developer's `release_gate_test.dart` has 10 more. All run (new cases mine).
- The gate is stricter than the sentence in section 4 (at most 5%): it uses the 95% upper bound, so 3 confident foils in 100 is
  `notEnough`, not a pass. That is the safe side and D-2 says why; noted, not a defect.
- A thin adult band (fewer than 60 foil readings) makes the language `notEnough` even when A, B and C pass, although the code comment
  says adults "may fail it, but only children can pass it". Conservative; the doc comment and the code disagree a little (note N2).
- **Nothing in `app/lib` outside `release_gate.dart` calls it** (`grep` for `languageVerdict`, `releaseGate`, `GateVerdict`): QA-L3-1.

### 3.6 No new package or network host: PASS

`git diff --stat ad4280c..HEAD` shows no change to `pubspec.yaml`, `pubspec.lock`, `app/network_hosts.json`, `supabase/`, `.github/`.
`grep` of the speech and play files finds no URL, no `dart:io` HTTP, no `print`/`Log`. The only non-code change of this kind is the
`.gitleaks.toml` allowlist, whose two values are exactly the pinned `tokens.txt` hashes of the English and Russian models in
`model_spec.dart`. The installer has no network code (`speech_models_test` source rule).

## 4. The say-it goldens: none existed; I made twelve and opened all of them

`golden_*` had no LS09 picture. I added `qa_l3_say_golden_test.dart` (fixture course, fake clips): three states on four boards. No
other golden was rewritten (`git status` shows only the new files). Opened with the Read tool:

| PNG | What I looked at | Result |
|---|---|---|
| `qa_l3_say_echo_phone.png`, `_echo_tabletPortrait.png` | the picture, the word chip "cat", the "I said it" tile, no mic | no overflow stripe, no clipped nikud (the tile text "אָמַרְתִּי" and the bubble are whole), the chip is its own LTR run, no overlap |
| `qa_l3_say_mic_phone.png`, `_mic_phoneSE.png`, `_mic_tabletLandscape.png`, `_mic_tabletPortrait.png` | the mic button beside the "I said it" tile | both ways on are on screen and apart; mic about 96 points, the tile 168 wide; the phone stage is not crowded; on the tablets the mic sits in the corner the other templates use (far from the tile on the landscape tablet, top left on the portrait one: the shared layout, not new) |
| `qa_l3_say_together_phone.png`, `_together_phoneSE.png`, `_together_tabletLandscape.png` | after an unsure listen | the kind line "בּוֹאוּ נֹאמַר יַחַד." (two lines on the phone, whole), the picture lit with the yellow border, the mic still offered for the one more try, "I said it" gone (the picture is the way on), no red, no cross, no "wrong" cue |
| the rest (`_echo_phoneSE`, `_echo_tabletLandscape`, `_together_tabletPortrait`) | same states | same |

Not judged: the picture is the fixture's orange disc, not art; the Hebrew strings are the fixtures (the real say-it lines are
`text-ready` and the "I said it" string is `needs-editor`). The word chip disappears in the "together" state because the line has no
`show` text; the voice still models the word. The empty lower third of the portrait tablet is the shared frame.

## 5. Defects

| Id | Severity | Title | Owner of the fix | Failing proof (skipped until the fix; `--dart-define=QA_OPEN=true`) |
|---|---|---|---|---|
| QA-L3-1 | major | The release gate is not enforced: a language that has not passed still uses the microphone | app-developer (with the orchestrator: the owner decides when a language is marked passed) | `qa_l3_open_defects_test.dart` "QA-L3-1" |
| QA-L3-2 | major | A say-it listen keeps the microphone open when the app goes to the background (same as SEC-L3-2) | app-developer | "QA-L3-2" |
| QA-L3-3 | major | A spoken success the cap or the strand refuses still repairs gaps and counts in the representation statistics (second half of SEC-L3-1) | app-developer, with curriculum-expert for the intent | "QA-L3-3" (two tests) |
| QA-L3-4 | minor | The lamp (hint) button is on screen in a say-it step and does nothing | app-developer or design-director | "QA-L3-4" |
| QA-L3-5 | minor | `say_eval.dart --sweep` reports the headline result and the csv at boost 3, labelled as the model's own boost 8 | app-developer (tool) | "QA-L3-5" (source guard, plus the run below) |

**QA-L3-1.** Where: `app/lib/app/voice_input.dart` `sayItAvailableProvider` and `lesson_screen.dart` `_makeSayStep`. Steps: voice switch on
for English for a child, the English model in the app folder, open a say-it lesson. Expected (L3.md section 4, section 8 item 3,
the brief): "until a language passes, its say-it runs in echo mode"; no language has passed (the gate needs A, B and C, and none has been
read). Actual: the microphone is offered. The provider checks the switch and the model's sizes only. Fix shape: a per-course
"released" value in the registry (false for all three) that the provider also requires, and a test override for the existing mic tests
(the developer's 15 say-it tests run the mic path and will need it). My test uses the default, so it passes without an override.

**QA-L3-2.** Where: `lesson_screen.dart` `didChangeAppLifecycleState` calls `_voice?.hush()` (the old voice path) and stops the guide,
but never `_sayStep?.stop()`. Steps: tap the mic, press home or pull the shade while it listens. Expected: the microphone is closed.
Actual: `micOpen` stays true until the listen ends by itself (at most 6 s: 5 s without speech, 1.5 to 2 s of quiet after speech, 6 s
cap). Nothing is kept or sent, and Android stops giving a background app audio, so this is bounded, but "the mic opens only on tap"
includes closing it when the child leaves. Fix: stop the step on `paused`, `inactive` and `hidden`.

**QA-L3-3.** Where: `engine/engine.dart` `apply()`. `_speechCounts` says "a spoken answer that does not count changes nothing at all"
and `_updateSkill` returns early, but `apply` then runs `_updateGaps` (counts `repairSuccesses` for any correct answer with hint level
at most 1) and `r.tries++; r.successes++` on `repStats`. Proof: with a speaking skill at its cap, ten more spoken successes take a
gap's `repairSuccesses` to 2 (it should stay 0 and the gap stays open); with a non-speaking skill one spoken success makes
`repStats` `[1, 1]` (it should be `[0, 0]`). Fix: skip the rest of `apply()` for a refused spoken answer (return `bool` from the
skill update). The security-engineer's other half of SEC-L3-1 (a spoken answer after a hint is not counted against the cap) cannot
happen in the app today: a say-it item has no hints, so the hint level is 0; the validator does not forbid hints on a say-it item.

**QA-L3-4.** Where: `lesson_screen.dart` `onHint: controller.showHint`, `lesson_controller.dart` `showHint` returns when `hints` is
empty, and say-it items have no hints. The lamp is on screen (the existing test even asserts it is there) and a tap does nothing. The
replay button and "show me" (wired to `replayPrompt`) do work. Fix: wire the lamp to `replayPrompt` for a say-it item (as "show me"
is) or hide it.

**QA-L3-5.** Where: `app/tool/say_eval.dart`, `tallyOf(boosts.first, own)`. With `--sweep` the boosts are 3, 5, 8, 12, 16 and the
first is 3. Evidence (the run of section 1): header "mode: biased (boost 8.0)", headline "heard 133 of 160 (83.1%)", sweep row `8.0 0.75`
"85.6%" and `3.0 0.75` "83.1%". The 85.6% is what L3.md section 9 reports. Without `--sweep` the headline is at the model's own boost, so
the owner's first look at a sweep would be at the wrong boost. Fix: take the model's own boost (add `spec.hotwordBoost` to the list
and use it for the headline and the csv).

## 6. Notes (not defects)

- **N1 (first tap).** The first tap pays the model load (0.7 to 1.6 s on this PC; more on the Samsung) and the mic shows "listening"
  while `prepare()` runs, so a child who answers at once may be cut off and get "let's say it together". Harmless by design, and the
  phone check below measures it. If it shows, prepare the engine when the item appears (loading is not listening).
- **N2 (adult band).** See 3.5: the doc comment on `languageVerdict` and the code differ on a thin adult band.
- **N3 (QA-L0-6).** `areaLangVoiceHelp` still says the model "comes down to the device" when the switch is turned on. L3 builds no
  download (no host), so a parent who turns the switch on gets nothing until the cable push. The text is still not true; the
  hebrew-text-editor and the infrastructure-engineer's R2 step own it.
- **N4 (SEC-L3-4).** A course recogniser is not freed when its switch is turned off (it is freed with the provider). Not tested here.
- **N5 (Russian).** There is no Russian single-word recording anywhere, so Russian accuracy, the accept 0.8 and the margin are
  unmeasured; the language ships in echo mode by the same gate, once QA-L3-1 is fixed.
- **N6 (hint at the top).** Not applicable: a say-it step has no wrong move.

## 7. Not checked

The real phone: model load time and memory on the Samsung, how the recogniser does with a 3 to 8 year old's voice, the real voice
clips, the noise of a room, the iOS build. The gate cannot pass on what I ran (adults only, one language). The paid voice tool was
not touched.

## 8. Phone check for the owner (after QA-L3-1 and QA-L3-2 are fixed, with the English model pushed by `tools\make-asr-models.ps1 -Course eng -Push`)

1. Parent area, the English page: turn **Voice answers** on. Android asks you (not the child) for the microphone: allow. Expect the
   switch stays on. Report: any message that says the voice is being downloaded (N3).
2. Child space, open an English lesson with a say-it step. Expect: the word is said, a pause, then said again; the picture is not yet
   a button; a mic and an "I said it" tile are on screen; **nothing listens** (no mic icon in the status bar). Report if the status
   bar shows the microphone before you tap.
3. Tap the mic and say the word at once, then once more after waiting a second. Expect: the status-bar mic icon only while the ring
   moves; then "I heard" and the word, or the kind "let's say it together". Report the delay between the tap and the ring (N1) and
   whether a word said at once is lost.
4. Say a different word. Expect the kind line, never a red mark; the mic is offered once more; after a second miss it fades and the
   picture goes on.
5. While the ring moves press home. Expect the status-bar mic icon to go out at once (QA-L3-2).
6. Turn the Voice answers switch off in the parent area, come back: the step is echo (no mic), "I said it" works.
7. Run `adb shell dumpsys meminfo app.nitznutz.nitznutz.dev` before the first tap, during a listen and after, and report the three
   totals (the PC numbers in L3.md 7.4 are lower bounds).
8. With the gate rule in (QA-L3-1) a language that has not passed shows no mic at all: report any English lesson that still does.

## 9. Files

`app/test/qa_l3_language_test.dart` (22 passing tests), `app/test/qa_l3_open_defects_test.dart` (6 skipped proofs),
`app/test/qa_l3_say_golden_test.dart` and its 12 PNGs `app/test/goldens/qa_l3_say_*.png`, `app/test/support/qa_l3_say.dart` (the
shared lesson rig), this record. Product code, the plan and the board are untouched.
