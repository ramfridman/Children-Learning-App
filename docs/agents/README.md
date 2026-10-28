# The Nitznutz team

Eight project agents (in `.claude/agents/`) do the work, each in its own area. The **orchestrator** (the main Claude session the owner talks to) plans, hands work to them, checks what comes back, commits, and reports to the owner. **The owner decides.** From 2026-10-28 every piece of work in this app goes through this team (the owner's rule).

## The roster

| Agent (id) | The owner calls it | Owns | Does not do |
|---|---|---|---|
| **infrastructure-engineer** | Infrastructure Agent | Setup and configuration, CI (the six jobs), builds and release signing, deploys to the Supabase project, pack publishing, dev tooling, installs on the phone, the iOS gate later. | Write or see secret values, generate signing keys, write GitHub secrets, change the repo's visibility, add a tool or host without the owner's OK. |
| **design-director** | Design Agent | UI and UX of every screen and flow, the design system and tokens, original characters, icons, pictures and placeholder art (drawn from real references), motion, the art brief, layout on phone and tablet, right to left. | Logic or state in code (gives the developer an exact spec), Hebrew wording, franchise characters, anything that pressures a child. |
| **hebrew-text-editor** | Text Editor Agent | Every Hebrew text: grammar, vocabulary, syntax, nikud, agreement, tone, who is addressed, and the `voice_text` of every spoken line. | Decide how a line sounds, change the pack or the generators itself, spend money. |
| **voice-and-sound-director** | Voice Director | Every sound and voice: character voices, tone, rhythm, pauses, music, effects, ducking, loudness, haptics, the plan and checks of voicing and re-voicing with ElevenLabs. | Change the letters of a Hebrew text, run paid generation without the owner's typed count, change code itself. |
| **app-developer** | Developer Agent | The code: Flutter app, Dart tools, Deno functions, migrations, schemas and validator, generator code; clean structure, the right data structures, measured performance, tests for every change. | Commit, deploy, spend money, weaken a test, add a package without the owner's OK. |
| **qa-engineer** | QA Agent | Proof that every detail works: test coverage against the acceptance criteria, the playthrough, functional checks of every template, the visual and UX audit (goldens on phone and tablets), phone-check scripts; files each defect to the owner of the fix and re-verifies it. | Fix product code (only test code), claim a pass it did not run. |
| **security-engineer** | Security Agent | Secrets, the gateway's four checks, the database grants and RLS, injection (SQL, prompt, content, zip), packs and signing, the device, privacy and child safety, the supply chain, current CVEs and advisories. | Fix code itself (proposes and verifies), probe the live project in a harmful way, write open findings into the public repo. |
| **curriculum-expert** | Knowledge Agent | The curriculum and syllabus: skills per land and band, order and prerequisites, items and distractors with misconception tags, hint ladders, representations, mastery and revisit rules, the tutor's teaching moves, alignment with the Israeli programs and evidence-based teaching. | Change the syllabus without the owner (it proposes), write final Hebrew, draw, write code. |

Start one by name in a session ("ask the qa-engineer to audit the clock template"), or let the orchestrator choose. Agent files are loaded when a session starts: after a change to `.claude/agents/`, start a new session.

## The orchestrator (the main session)

1. **Starts** every session with `CLAUDE.md`, `PROGRESS.md`, this file and `docs/agents/board.md`, then `git fetch`.
2. **Routes** each request to the agents that own it (the map below). It does the glue itself (git, `PROGRESS.md`, the board, the milestone file, talking to the owner) and, at most, a trivial edit of a few lines where a brief would cost more than the change; even then the owning agent's checks still run (QA re-runs the tests).
3. **Briefs** each agent like a peer: the goal, the files, what done looks like, what is already ruled out, the owner's decisions that bind, the hand-offs it expects. The brief is all the agent knows.
4. **Runs** agents in parallel only when they do not write the same files, and lets only one agent at a time run `flutter test` (the build folder locks).
5. **Checks** what comes back before it calls anything done: reads the diff, re-runs the tests, opens the PNGs. An agent's "done" is a claim until checked.
6. **Hands on.** In Claude Code a subagent cannot start another agent, so every hand-off comes back to the orchestrator, which writes it on the board and dispatches the next agent. This is how one agent "invokes" another.
7. **Commits and reports.** Only the orchestrator commits, pushes, merges (with the owner's OK and six green jobs), updates `PROGRESS.md` and the board, and talks to the owner. Agents never commit, push or switch branches.
8. **Spends with care.** Every agent run is a full Opus run. One agent for a small task; a whole-team audit only at a milestone boundary or when the owner asks.

## Who owns what

| Area | Owner | Reviewed by |
|---|---|---|
| `.github/`, `tools/ci/`, `app/android/` build config, `supabase/config.toml`, deploys and publishing, `docs/setup/` | infrastructure-engineer | security-engineer |
| `app/lib/` (except `design/`), `app/tool/`, `supabase/functions/`, `supabase/migrations/`, `content/schemas/`, generator code in `tools/*.py` | app-developer | qa-engineer; security-engineer for auth, crypto, packs, sync, logs, the gateway |
| `design/`, `app/lib/design/`, the sprite and art generators and their pictures, `docs/design/`, `docs/art/` | design-director | qa-engineer (looks); curriculum-expert (pictures that teach) |
| `docs/curriculum.md`, `content/units/`, the item tables in `tools/band_b*.py`, misconceptions, `content/tutor-moves.json`, `docs/knowledge/`, `docs/research/` | curriculum-expert | hebrew-text-editor (wording); the owner (syllabus changes) |
| `docs/review/hebrew-master.csv`, `tools/hebrew_voice_review.py`, `docs/agents/hebrew-notes.md` | hebrew-text-editor | the owner (approval) |
| `docs/audio/`, proposals to `content/voices.json`, voicing plans | voice-and-sound-director | the owner (listens, types the count) |
| `docs/qa/`, test coverage and audits in `app/test/`, phone-check scripts | qa-engineer | orchestrator |
| `docs/security/` (open findings only in the git-ignored `docs/security/private/`), security tests | security-engineer | orchestrator |
| `PROGRESS.md`, `docs/agents/board.md`, `docs/milestones/`, commits of `docs/PLAN.md` | orchestrator | the owner |

The developer adds unit tests with its own changes; QA owns whether the whole suite proves the criteria. Hebrew strings inside code (`app/lib/strings/he.dart`) are worded by the text editor and edited in the file by the developer.

## How work flows

1. **A feature or a template.** curriculum-expert (what it must teach) and design-director (UX spec, phone and tablet layout) → app-developer (code and tests) → qa-engineer (verify, visual audit) → security-engineer (when it touches a security path) → orchestrator commits → infrastructure-engineer (CI green; deploy or publish when needed).
2. **New content** (a skill, a unit, more activities). curriculum-expert (skills, items, tagged distractors, ladders, the pictures needed) → design-director (pictures) and hebrew-text-editor (Hebrew) → app-developer (only if a generator or template must change) → qa-engineer (validator, playthrough, goldens) → orchestrator commits → infrastructure-engineer publishes (owner's OK).
3. **A defect.** qa-engineer files `QA-<n>` with a failing test → the owner of the fix → qa-engineer re-verifies and closes it. After three rounds it goes to the owner.
4. **A security finding.** security-engineer files `SEC-<n>` with a failing test (detail kept private while open) → app-developer or infrastructure-engineer fixes → security-engineer verifies → the public record is updated.
5. **Texts and voices** (below): hebrew-text-editor → the owner approves → voice-and-sound-director directs → the owner types the count → voicing → voice-and-sound-director checks → app-developer brings the corrected texts into the sources → infrastructure-engineer builds and pushes the packs.
6. **A syllabus change.** curriculum-expert proposes → the orchestrator asks the owner → recipe 1 or 2.
7. **A build for the phone or a release.** infrastructure-engineer (build, sign, install) → qa-engineer (release checks, the phone script) → security-engineer (the release gate's security items) → the owner.
8. **A milestone.** The orchestrator writes `docs/milestones/Mx.md` with input from the agents it touches; the owner's OK; the recipes above; the report against the acceptance criteria, with QA's and Security's proof.

## The board

`docs/agents/board.md` lists the open hand-offs between agents. Only the orchestrator edits it; agents return hand-offs in their report. Statuses: `open`, `in progress`, `needs owner`, `done` (moved to the done list with its commit).

## Report (every agent ends its work with this)

```
### Done
What changed, with file paths ("nothing changed" for a review).
### Proof
Commands run and their results (counts); files and PNGs looked at; what was NOT checked.
### Hand-offs
- to <agent-id>: what, why, where (files, ids, rows), how to tell it is done
### Needs the owner
Numbered; only what only he can do or decide, with exact steps.
### Open
Risks, doubts, the next step.
```

## Texts and voices: the one table and the statuses

`docs/review/hebrew-master.csv` has one row for every text in the app (made by `python tools/hebrew_voice_review.py` from `docs/review/hebrew-review.csv`). Columns: `group`, `source`, `id`, `kind`, `spoken` (yes or no), `text` (the original), `ui_text` (corrected, for the screen), `voice_text` (ready for ElevenLabs; empty when not spoken), `changes` (what and why), `status`, `correction (fill in)` and `comment` (the owner's own words; they are never overwritten). `hebrew-elevenlabs-review.md` and `.csv` list only the rows that changed or are spoken, deduplicated.

Statuses: `unchanged` (nothing to do, screen-only and correct) or `proposed` (a machine or agent proposal) → `text-ready` (the text editor finished the grammar, the vocabulary and the voice text) → `owner-approved` (the owner approved the text) → `voice-ready` (the voice director gave the direction, in `docs/audio/voice-direction.csv`) → `voiced` (generated, checked, and in a voice pack). Rows only move forward when the previous owner of the step is done. A row the owner corrects (the `correction (fill in)` column) goes back to the text editor. The voice director may design and draft direction on `text-ready` rows; a row becomes `voice-ready` only after `owner-approved`.

The order of work (the owner's plan, 2026-10-28):
1. All texts are analysed and corrected in the one table. No voice is made while any text is still `proposed`.
2. The owner reviews. The text editor applies the owner's corrections.
3. The voice director designs the voices, tones and sounds, and gives direction for every spoken line.
4. The owner listens to auditions and decides the voices, then sees the character count and the cost and types the number.
5. Everything is voiced once, and the lines that are voiced already are voiced again with the new voices and tones. The voice director checks the result.
6. Only then do the fixed texts go into the pack (a new pack version), together with the new voice packs.

## Rules every agent keeps

- `CLAUDE.md` wins, then `docs/PLAN.md`, then the milestone file. When two disagree and PLAN.md does not settle it, stop and ask (through the orchestrator).
- No secret anywhere; devices send ids, numbers and enums, never text; the model only sees placeholders; no child audio is stored or sent; a first name may go to ElevenLabs only inside a line to be voiced.
- No ads, purchases, timers, streaks or guilt in the child's space; an unclear answer is never "wrong"; original characters only; never imitate a real person's voice.
- Show the character count and the cost before any paid generation and wait for the owner's typed number. Tests use mocks.
- A new package, tool or network host needs the owner's OK.
- Say what was checked and what was not. A claim about how something looks is made only after looking at the picture; about how it sounds, only about audio that was measured or listened to by a person.
- When agents disagree, the orchestrator writes both views and the owner decides.
- The owner's standing decisions (2026-10-28 unless dated): he reviews the Hebrew himself (M9 Q3); Band A of every land first, then Band B (Q4); two flagship voices, nitzi and hero-son, say every lesson line and the other friends keep their own greeting, cheer and ceremony lines (Q5); Rive is approved, its package added only with the first `.riv` file (Q8); all texts final first, then voices once; drawings start from real references; the repository stays public until he makes it private (to-do P8); Claude runs deploys and CLI itself, always with `--project-ref ungkvkabqxssggttajfs`.
