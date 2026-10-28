# Brief for the next Claude session (written 2026-10-28)

Open a new Claude Code session in `D:\Children-Learning-App` (branch `m9-content`) and paste everything below the line, or type: *Read `docs/handoff/next-session.md` and follow it.*

---

You are the **orchestrator** of the Nitznutz team. Nitznutz (נִיצְנוּץ) is a Hebrew-only learning app for the owner's two children (ages 3 to 8): a Flutter app (Android first, iOS later) with a Supabase Frankfurt backend whose Edge Functions are the only gateway to Claude Haiku 5.5 and ElevenLabs. The owner works on Windows with PowerShell in `D:\Children-Learning-App` (timezone Asia/Jerusalem), and is often away from the PC, working from his phone.

## 1. Start, in this order

1. `git fetch`, then `git status`. You should be on `m9-content`.
2. Read `CLAUDE.md`, `PROGRESS.md`, `docs/agents/README.md` (the team: roster, who owns what, the recipes, the hand-off and report format, the text and voice statuses), `docs/agents/board.md` (open hand-offs B-1 to B-10), `docs/milestones/M9.md` (§1 "done when", §3 the owner's decisions, §6 the release gate, §12 to §17 what is built) and your memory.
3. Check that the eight agents are loaded: the Agent tool's list of agent types must show **infrastructure-engineer, design-director, hebrew-text-editor, voice-and-sound-director, app-developer, qa-engineer, security-engineer, curriculum-expert**. If one is missing, tell the owner to restart the session. Do not do its work inline instead.

## 2. How you work from now on (the owner's rule of 2026-10-28)

- **Every piece of work goes to the agent that owns it** (README › Who owns what). You do the glue: git, `PROGRESS.md`, the board, the milestone file, and every message to the owner. A trivial edit of a few lines may stay with you, but the owning agent's checks still run.
- **Brief each agent like a peer**: the goal, the files, what done looks like, what is already ruled out, the owner's decisions that bind, the hand-offs you expect. The brief is all it knows.
- **Run agents in parallel only when they do not write the same files**, and let only one agent at a time run `flutter test` (the build folder locks).
- **Agents cannot start each other.** Each report ends with a Hand-offs list; you write the items on the board and dispatch the next agent. That is how QA "invokes" the design-director or the app-developer to fix something, and how the curriculum-expert's syllabus changes reach the right agents (through you, and the owner first).
- **No change is done until the qa-engineer has verified it**; changes to the gateway, auth, crypto, packs, sync or logs also get the security-engineer's review.
- **Check every result yourself** (the diff, the tests, the PNGs) before you commit or report it. Only you commit (the pre-commit hook runs gitleaks) and push. Never force-push or rewrite history.
- **Spend with care**: every agent run is a full Opus run. Brief narrowly; a whole-team pass only when it pays (like the kickoff below).

## 3. Where things stand (2026-10-28)

- **M0 to M8 are merged to `main`.** M9 (content and the family release) is approved and built on `m9-content`, **not merged**: the content pipeline and validator lint, the headless playthrough, placement and the warm-up game, the next-lesson path, Band A of all six lands, Band B, more activities per skill, and 15 templates (`count_tap`, `give_n`, `tap_answer` 1.2 with the chart, `flash`, `sort_drag`, `build_pattern`, `robot_path`, `shape_builder`, `number_line`, `balance`, `spot_error`, `match_pairs`, `shop_pay`, `clock_set`, `trace`). **Pack 0.8.0 is published**: 100 skills, 767 activities, 160 lessons, 44 misconceptions.
- **The text editor's first full pass is done but not committed**: `docs/review/hebrew-master.csv` (9,504 rows: 9,448 `text-ready`, 33 `proposed`, 23 `unchanged`), `docs/review/hebrew-elevenlabs-review.md` and `.csv`, `tools/hebrew_voice_review.py`, and `docs/agents/hebrew-notes.md` (the style rules, the generator fixes G1 to G14 and the app issues A1 and A2, 11 questions for the owner, notes for the voice director).
- **The team was set up in the previous session**: six new agents, the two content agents updated, `docs/agents/README.md` rewritten as the team charter, `docs/agents/board.md`, a "The team" section in `CLAUDE.md`, a line in `docs/PLAN.md` › Who builds it, and `docs/security/private/` git-ignored. If `git status` shows any of these uncommitted, commit them as their own commit first.
- **No voices for the new lessons yet**, on purpose: all texts final first, then everything is voiced once, and the old lines are voiced again with the new voices and tones.
- **Not built yet** (M9 §17): T19 measure it, T22 arrays, T25 explain it, T11 mix the colours, T12 speak the answer, T23 fraction fold, T24 sound and move; the skills that wait for them (measuring, ten-frame flash and estimating, half hours, symmetry and maps, several Logic and CS skills); the AI helper's vocabulary for the new words; real art (the illustrator, to-do P9); part 9e (the Android release keystore, the iOS gate, the privacy text, the installs on the family's devices).
- **Waiting on the owner**: the Hebrew review and the 11 questions (B-1), the phone check of the `m9-content` build and his OK to merge (B-10), the illustrator (P9), and later the typed character count for the voicing.

## 4. Your first job

1. **Commit what is waiting.** Look at `git diff --stat` and check that only the review files and the review script changed, then commit the text editor's pass ("Hebrew text editor: first full pass over the master table"). A voice-director session was also working in this checkout at the end of 2026-10-28 (`tools/voice_direction.py`, maybe `docs/audio/`): check with `mcp__ccd_session_mgmt__list_sessions` that no session is still writing, read that work, and commit it as its own commit (it is B-4's start). Push `m9-content`.
2. **Team kickoff (one wave, in parallel).** Dispatch the board items, each with a bounded brief (at most about 15 findings, ranked, each with the agent that owns the fix; each writes only to its own folder):
   - **curriculum-expert**: B-5 (audit of pack 0.8.0 and the priority list of the next skills and templates) together with B-2 (a teaching view on the Hebrew questions 2, 3, 7, 8 and 11). Writes to `docs/knowledge/`.
   - **qa-engineer**: B-6 (the full local suite, the coverage map against M9 §1 and §5, a visual audit of every template on a phone and both tablet shapes). The only agent that runs `flutter test` in this wave. Writes to `docs/qa/`.
   - **security-engineer**: B-7 (review of `m9-content` against `main`, advisories for the lock files, personal data in the public repo). Open findings only in `docs/security/private/`.
   - **design-director**: B-8 (audit of the child screens and templates from the existing goldens, without regenerating them; the placeholder inventory and a replacement plan from real references). Writes to `docs/design/`.
   - **infrastructure-engineer**: B-9 (CI on `m9-content` through `gh`, what a merge needs, the owner's release-keystore steps, versions due). No builds or tests in this wave.
   - **voice-and-sound-director**: B-4 (`docs/audio/voice-direction.md`: voices, tones per kind of line, music and effects; per-line direction drafted on `text-ready` rows; the voicing plan with its character count and cost from `voice_gen plan`, never `generate`). If step 1 found this already done, brief it only to finish what is missing.
3. **Merge the results** into one backlog: every item on the board with its owner agent and severity, and a new section **M9 §18 "Team kickoff: findings and the plan for the rest of M9"** with a proposed order. Commit it.
4. **Report to the owner** in a short message: the blockers, the top items, and the decisions only he can make (the 11 Hebrew questions with the curriculum-expert's teaching view next to each, the merge, the art). Ask which to start, and wait for his OK before building a new part (CLAUDE.md: plan, OK, build).
5. **Then work through the recipes** (README › How work flows): blockers first (QA and security defects), then his pick. Likely order: his Hebrew answers → the text editor applies them → the voice director's direction → auditions and his typed count → the voicing → the app-developer brings the corrected texts and G1 to G14 into the sources → a new pack with the new voice packs; in between, the remaining templates in the curriculum-expert's order, placeholder art upgrades, and part 9e. After each piece: QA verifies, you commit and push, the infrastructure-engineer confirms CI is green, you update `PROGRESS.md` and the board, and you report to the owner in the form **Done / Proof / Security / Plan drift / Needs you / Next**.

## 5. Rules that bind (the full list is in `CLAUDE.md` and the README)

- Never: a secret in the chat, the repo, a log or CI output; generating a signing key (the owner runs `keygen` himself); writing GitHub secrets; changing the repository's visibility (public until he says otherwise, to-do P8); `ALLOW_DEV_ENROLMENT` on the cloud project; paid generation without his typed character count; a new package, tool or network host without his OK; force-push.
- Supabase: always `--project-ref ungkvkabqxssggttajfs`. The owner wants Claude to run deploys and the CLI itself; he does only what only he can (codes from e-mail, secrets, taps on the phone, approvals, billing).
- One milestone at a time: plan, his OK, build; `PROGRESS.md` stays current; when the build differs from PLAN.md, PLAN.md changes in the same commit; `main` stays green; a merge needs all six CI jobs green and his OK.
- Commit messages end with the attribution lines your harness gives you.

## 6. The owner's decisions so far

He reviews the Hebrew himself (M9 Q3). Band A of every land first, then Band B in the order the children need it (Q4). Two flagship voices, nitzi and hero-son, say every lesson line; the other friends keep their own greeting, cheer and ceremony lines (Q5). Rive is approved, its package added only with the first `.riv` file (Q8). All texts final first, then voices once. Every drawing starts from real references and is drawn as an original. A child's first name (parent-reviewed spelling) may go to ElevenLabs inside a line; the model only sees `{child}` and `{companion}`. ÷ by default. Android first, the iOS gate later (part 9e). Later ideas waiting for their own plan after the full app (in `PROGRESS.md`): the dress-up studio, the daily welcome by name, picture puzzles, English lessons.
