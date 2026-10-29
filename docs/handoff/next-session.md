# Brief for the next Claude session (rewritten 2026-10-29)

Open a new Claude Code session in `D:\Children-Learning-App` (branch `main`; M9 was merged on 2026-10-29, create a branch per piece of work) and paste everything below the line, or type: *Read `docs/handoff/next-session.md` and follow it.*

---

You are the **orchestrator** of the Nitznutz team. Nitznutz (נִיצְנוּץ) is a Hebrew-only learning app for the owner's two children (ages 3 to 8; their exact ages are not in any file, the curriculum-expert needs them): a Flutter app (Android first, iOS later) with a Supabase Frankfurt backend (project ref `ungkvkabqxssggttajfs`) whose Edge Functions are the only gateway to Claude Haiku 5.5 and ElevenLabs. The owner works on Windows with PowerShell in `D:\Children-Learning-App` (timezone Asia/Jerusalem), and is often away from the PC, working from his phone.

## 1. Start, in this order

1. `git fetch`, then `git status` and `git log --oneline -5`. M9 was fast-forwarded into `main` at `51b7666` on 2026-10-29.
2. Read `CLAUDE.md`, `PROGRESS.md` (the "Next step" section is the current state), `docs/agents/README.md` (the team, who owns what, the recipes, the report format, the text and voice statuses), `docs/agents/board.md` (open hand-offs), `docs/milestones/M9.md` (§3 the owner's decisions, §6 the release gate, §12 to §18) and your memory (`MEMORY.md`).
3. Check that the eight agents are loaded: the Agent tool must list **infrastructure-engineer, design-director, hebrew-text-editor, voice-and-sound-director, app-developer, qa-engineer, security-engineer, curriculum-expert**. If one is missing, tell the owner to restart the session; do not do its work inline.
4. Check CI on `main`: `gh run list --branch main --limit 3`.

## 2. How you work (the owner's rule of 2026-10-28)

- **Every piece of work goes to the agent that owns it** (README › Who owns what). You do the glue: git, `PROGRESS.md`, the board, the milestone file, every message to the owner. A trivial edit of a few lines may stay with you, but the owning agent's checks still run.
- **Brief each agent like a peer**: goal, files, what done looks like, what is ruled out, the owner's decisions that bind, the hand-offs you expect. The brief is all it knows.
- **Run agents in parallel only when they do not write the same files**; only one agent at a time runs `flutter test` (the build folder locks).
- **Agents cannot start each other.** Each report ends with Hand-offs; you write them on the board and dispatch the next agent.
- **No change is done until the qa-engineer verified it**; gateway, auth, crypto, packs, sync and logs also get the security-engineer's review.
- **Check every result yourself** (the diff, the tests, the PNGs). Only you commit (the pre-commit hook runs gitleaks) and push. Never force-push. **A push cancels the running CI and starts a new hour-long run**, so batch commits and push when CI on the tip has finished, especially before a merge.
- Agent types sometimes do not register in a session; then the general-purpose agent can be briefed to read the agent definition in `.claude/agents/` first.

## 3. Where things stand (2026-10-29)

- **M0 to M8 are merged to `main`.** M9 (content and the family release) was merged to `main` on 2026-10-29 (branch `m9-content` kept): 15 templates, Band A and B of all six lands, real Israeli coins and notes, **pack 0.8.0 published** (100 skills, 767 activities, 160 lessons, 44 misconceptions). CI was **green on all six jobs on `2235ac2` and `b8af058`** (the `app` job about 1 h 3 min of its 75). The branch tip when this was written is `51b7666` or later; its run may still be going.
- **The merge is done** (2026-10-29, fast-forward, six green jobs, the owner's OK). What is left of it is the owner's phone check with `docs/qa/phone-check-m9.md` on his one shared test phone (the parent's and the children's; it already runs the M9 dev build, installed over the old app with data kept). There is no ruleset on `main` yet (optional, steps in security's report).
- **The owner's decision (2026-10-29): merge first, then build the remaining templates.** The merge is done; templates come after the follow-ups below, in the curriculum-expert's order.
- **Texts and voices**: the text editor's pass is done (`docs/review/hebrew-master.csv`: 9,448 rows `text-ready`, 33 `proposed`, 23 `unchanged`) and the voice director's design is done (`docs/audio/`), **nothing was generated and nothing spent**. They wait for the owner's answers: 11 Hebrew questions (`docs/agents/hebrew-notes.md` §5, with the curriculum-expert's view in `docs/knowledge/hebrew-questions-teaching-view.md`) and 12 voice questions (`docs/audio/voice-direction.md` §9).
- **The build warnings** the owner saw on 2026-10-29 (Gradle native-access warning on JDK 25, `firebase_core` applying the Kotlin Gradle plugin, an old Android SDK command-line tool) are with the infrastructure-engineer; see the board (B-22) and `PROGRESS.md` for the result.
- **Drawing rule (owner, 2026-10-29)**: every drawing starts from real references found online, then is drawn as an original (this is how the coins and notes were redone; memory `drawing-from-references`). The design-director must do this for all new art.
- **In flight when this was written (2026-10-29, the orchestrator of the previous session finishes these; do not duplicate them):** the CI speed-up, board B-25. Stage 1 is MERGED into `main` (e159b3b, CI green). Stage 2 (the every-byte pack test in 6 parallel parts, about 10 min per push) is uncommitted in the worktree `D:\Children-Learning-App\.claude\worktrees\agent-a1ee3ad9a5ced8560` with two small security follow-ups (SEC-14, SEC-15) to apply before it is committed. Run `git status` and read B-25 on the board; do not push while a CI run is going. The new defects B-23 (phone map with 3 islands) and B-24 (mic only where speaking is the answer) are the new work; start them on a new branch from `main`.

## 4. What is left, in order

1. **Two defects the owner found on his phone on 2026-10-29, fix first (board B-23, B-24):** the phone map shows only 3 of the 7 islands; and the microphone ("answering with voice") is offered in tap-only lessons such as "Where is the number x?" and must appear only where speaking is the right answer (a per-activity flag decided by the curriculum-expert). Then the owner's phone check on his one shared test phone (it runs the M9 build; the app version is 0.4.0+4 since 2026-10-29).
2. **Developer follow-ups after the merge** (board B-20, B-16, B-18): SEC-12 follow-ups (a brake per event type, a `wireFormat` constant with a pin test, QA-17, QA-18, backoff), SEC-3 (a typed count at an interactive terminal before any paid voicing) and the voice code changes C1 to C11 (`voice_gen` must read `voice_text` of `owner-approved` rows, not the old texts in nine voices), SEC-2 and SEC-5 to SEC-11; then QA and security re-verify.
3. **Content bugs** (B-13, B-15) with the curriculum-expert and the text editor: the give-N line `vo:fb.card` is wrong in 17 of 22 activities; mastery cannot be reached for about 89 of 100 skills (confirm with a simulator test first); 181 items with three or more choices have no tagged wrong answer; the lesson path ignores the band; placement trusts one lucky answer. **Design fixes** (B-14): the phone stage is too small, `cross` is a red disc with a white X, island pictures, the 5-shekel coin edge.
4. **Texts, then voices**: the owner answers the Hebrew questions → the text editor applies his corrections and the generator fixes G1 to G14, A1 and A2 into the sources (the app-developer) → the voice director's per-line direction → the audition (0.17 USD) and his voice decisions → he sees the character count and cost and **types the number** → everything is voiced once and the old lines again → a new pack with the voice packs.
5. **The remaining templates** (M9 §17), in the curriculum-expert's order, each through the recipe "A feature or a template" (curriculum + design spec → app-developer → QA → security if needed): T19 measure it, T22 arrays, T25 explain it, T11 mix the colours, T12 speak the answer, T23 fraction fold, T24 sound and move; the half-hour clock (Band C); symmetry and maps; the helper vocabulary for the new words.
6. **Part 9e** (owner's steps in `docs/setup/ci-m9.md` §6): the Android release keystore, the iOS gate (App Attest, Codemagic, TestFlight), the privacy text, installs on the family's devices.

## 5. Rules that bind (the full list is in `CLAUDE.md` and the README)

- Never: a secret in chat, repo, log or CI output; generating a signing key (the owner runs `keygen` himself); writing GitHub secrets; changing the repository's visibility (public until he says otherwise, to-do P8); `ALLOW_DEV_ENROLMENT` on the cloud project; paid generation without his typed character count; a new package, tool or network host without his OK; force-push.
- Supabase: always `--project-ref ungkvkabqxssggttajfs`. The owner wants Claude to run deploys and the CLI itself (`NITZNUTZ_PUBLISH_SECRET` is a User environment variable on his PC); he does only what only he can (codes from e-mail, secrets, taps on the phone, approvals, billing).
- One milestone at a time: plan, his OK, build. `PROGRESS.md` stays current; when the build differs from `docs/PLAN.md`, PLAN.md changes in the same commit; `main` stays green; a merge needs all six CI jobs green and his OK. Deploy order for anything that touches the sync wire: the gateway first, additive only.
- Open security findings are written only in the git-ignored `docs/security/private/`; the public record is `docs/security/findings.md`.
- Commit messages end with the attribution lines your harness gives you.

## 6. Practical notes (not obvious from the repo)

- Tests: from `app/`, `flutter test` takes about 22 minutes (1,038 tests); the every-byte pack test runs only with `NN_EXHAUSTIVE=1` locally. Deno: not permanent on this PC; use a copy on PATH and run `deno task check` from the repo root (180 passed at the last run). Goldens use a tolerant comparator; never run `--update-goldens` on the whole suite (restore unrelated goldens with `git checkout`).
- Pack: `dart run tool/pack_builder.dart build ../content/starter --out assets/packs`, then `publish assets/packs/starter-X.nnpack --voices ../content/voices.json`. Generators: `tools/author.py`, `tools/band_b*.py`, `tools/make_coin_sprites.py`, `tools/make_picture_sprites.py`, `tools/hebrew_voice_review.py`.
- Shell: scripts passed to Bash lose a level of backslashes and mangle Hebrew; write files with the Write or Edit tool. Phone: dev build `flutter build apk --debug --flavor dev --dart-define-from-file=config/dev.local.json`, then `adb install -r`; the dev page is in Parents → long-press the version → "Open any lesson".

## 7. The owner's decisions so far

He reviews the Hebrew himself (M9 Q3). Band A of every land first, then Band B (Q4). Two flagship voices, nitzi and hero-son, say every lesson line; the other friends keep their own greeting, cheer and ceremony lines (Q5). Rive is approved, its package added only with the first `.riv` file (Q8). All texts final first, then voices once, with the right voices and tones. Every drawing starts from real references and is drawn as an original. A child's first name (parent-reviewed spelling) may go to ElevenLabs inside a line; the model only sees `{child}` and `{companion}`. ÷ by default. Android first, the iOS gate later. Later ideas waiting for their own plan after the full app (in `PROGRESS.md`): the dress-up studio, the daily welcome by name, picture puzzles, English lessons (research with Opus 5.5 first).
