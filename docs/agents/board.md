# Team board

Open hand-offs between the agents (`docs/agents/README.md`). Only the orchestrator edits this file; agents return hand-offs in their reports. Statuses: `open`, `in progress`, `needs owner`, `done`.

## Open

| # | From | To | What | Where | Status | Since |
|---|---|---|---|---|---|---|
| B-1 | hebrew-text-editor | owner | Answer the 11 questions on the Hebrew (nikud standard, the M-CNT-SIZE line, missing-addend hints, `גֶּרֶב` gender, `תֵּבָה` or `קֻפְסָה`, sums about objects, coin names in shop hints, ÷ read aloud, the per-name line) and review the table (9,448 rows `text-ready`, 33 `proposed`, 23 `unchanged`). | `docs/agents/hebrew-notes.md` §5; `docs/review/hebrew-master.csv` | needs owner | 2026-10-28 |
| B-2 | hebrew-text-editor | curriculum-expert | Give a teaching view on questions 2, 3, 7, 8 and 11 before the owner decides (what the misconception line must say; count on or count all for a missing addend; the word a 3 to 6 year old knows; feminine sums as at gan or agreement with the noun; naming coins or amounts). | `docs/agents/hebrew-notes.md` §5 | open | 2026-10-28 |
| B-3 | hebrew-text-editor | app-developer | Bring the corrections into the sources: generator fixes G1 to G14 so a regeneration does not bring old texts back, A1 (alt text repeats the question), A2 (isolate digits and signs inside Hebrew lines). G1 to G14 wait for the owner's approval of the texts (plan step 6); A1 and A2 can go with his OK. | `docs/agents/hebrew-notes.md` §4 | needs owner | 2026-10-28 |
| B-4 | hebrew-text-editor | voice-and-sound-director | Design the voices, tones per kind of line, music and effects (`docs/audio/voice-direction.md`) and draft the per-line direction on `text-ready` rows; plan the voicing run with its character count and cost (no paid run). Another session started this on 2026-10-28 (`tools/voice_direction.py` appeared, uncommitted): review that work before dispatching it again. | `docs/agents/hebrew-notes.md` §6; `docs/review/hebrew-master.csv` | in progress | 2026-10-28 |
| B-5 | orchestrator | curriculum-expert | Audit pack 0.8.0 against `docs/curriculum.md`: coverage per land and band, sequence, tagged distractors, hint ladders, misconceptions reached, pictures that mislead; the next skills and templates in priority order for the family release (Band A of every land first). | `content/starter/`, `content/units/`, `tools/band_b*.py`, `docs/milestones/M9.md` §12 to §17 | open | 2026-10-28 |
| B-6 | orchestrator | qa-engineer | Baseline on `m9-content`: the full local suite, the coverage map against M9 §1 and §5, a visual audit of every template's goldens on a phone and both tablet shapes (trace and the shape builder are small on the phone's 330 by 128 stage). | `app/test/`, `app/test/goldens/` | open | 2026-10-28 |
| B-7 | orchestrator | security-engineer | Review `m9-content` against `main` (new templates, the raised pack limits, the publish index, the generators), check the lock files for new advisories, and check the public repository for personal data. | `git diff main...m9-content` | open | 2026-10-28 |
| B-8 | orchestrator | design-director | Audit the child screens and the templates on phone and tablet; list every placeholder picture by land with a plan to replace the most visible ones (drawn from real references) until the illustrator's art arrives. | `app/test/goldens/`, `tools/make_*_sprites.py`, `docs/art/art-brief.md` | open | 2026-10-28 |
| B-9 | orchestrator | infrastructure-engineer | The state of CI on `m9-content` and what a merge to `main` needs; the steps for the owner's Android release keystore (part 9e); tool and action versions due for an update. | `.github/workflows/`, `tools/ci/` | open | 2026-10-28 |
| B-10 | orchestrator | owner | Phone check of the `m9-content` build, then the OK to merge M9's parts to `main`; the illustrator (to-do P9). | `docs/milestones/M9.md` | needs owner | 2026-10-28 |

## Done

| # | What | Commit |
|---|---|---|
