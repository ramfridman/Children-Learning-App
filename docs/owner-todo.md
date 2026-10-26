# Owner to-do list

Things only the owner can do, kept in one place so nothing is lost while work moves on. Tick them off here; Claude keeps this file current. Exact steps for each are in the file named in the last column.

Last updated: 2026-10-26.

## Decisions waiting

| # | What | Why it waits | Where |
|---|------|--------------|-------|
| D1 | **Confirm M4** (characters and voice out), so Claude can merge `m4-characters-voice` into `main` | CI is green; the owner was away from the PC and could not look at the report | `docs/milestones/M4.md` section 11 |
| D2 | **OK for the M5 plan** (voice in) and its two new packages | The plan is written, no code yet | `docs/milestones/M5.md` |

M5 work, once approved, is stacked on the M4 branch (`m5-voice-in` starts from `m4-characters-voice`), so nothing is merged to `main` without D1.

## Checks to do on the phone (the Samsung plugged into the PC)

Each one is a short list of steps with the expected result. Run them in this order, in one sitting if you can.

| # | Check | Time | Steps |
|---|-------|------|-------|
| T1 | M1: install, wrong-PIN lock-outs, the database file is encrypted, PIN hashing time | 20 min | `docs/setup/android-device-checks.md` sections 1 to 4 |
| T2 | M2: play the butterflies lesson; damaged packs are refused | 15 min | same file, section 6 |
| T3 | M3: what the learning engine concluded about the child who played | 5 min | same file, section 7 |
| T4 | M4: install the 8 family characters and 9 test voices, pick a friend on Friends' Beach, hear the tones with the mouth moving, celebrate, switch back | 20 min | same file, section 8 (one command builds and pushes the packs: `tools\make-m4-device-packs.ps1 -Push`) |
| T5 | M4, optional: frame times in profile mode on the Samsung | 5 min | same file, section 8E |

## Things to look at and judge

| # | What | Where |
|---|------|-------|
| R1 | Hebrew review: every child-facing string (all marked `needs-editor`) and the 19 core voice lines | `app/lib/strings/he.dart`, `content/lines/core.he.json` |
| R2 | Look at the new screens against what you imagined: the map with the companion, Friends' Beach, the celebration card | goldens in `app/test/goldens/` (`companion_*.png`), or on the phone in T4 |
| R3 | Which friend would the children pick first? Is anything stiff, cut, too small or too slow to touch? | T4 |

## Tasks for the PC

| # | What | Where |
|---|------|-------|
| P1 | **Save the pack signing key in 1Password.** It exists only on this PC at `%USERPROFILE%\nitznutz-secrets\pack-signing.key`. Do not delete it. | `PROGRESS.md` (Open issues) |
| P2 | Screenshots of the spend limits in the Anthropic and ElevenLabs consoles | `docs/setup/` |
| P3 | **Real voices (M4 Phase H).** Choose a voice for each of the nine characters from short auditions, tell Claude the model id you pick in ElevenLabs, see the plan and the cost, type the exact character count back, and listen to every generated line. About an hour. Claude gives the numbered PowerShell steps when you say you are at the PC. | `docs/milestones/M4.md` Phase H |
| P4 | Record a few words from your own children for the speech check of M5 (only if you agree to it in the M5 plan, question Q6) | `docs/milestones/M5.md` |
