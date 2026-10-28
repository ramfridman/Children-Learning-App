# Owner to-do list

Things only the owner can do, kept in one place so nothing is lost while work moves on. Tick them off here; Claude keeps this file current. Exact steps for each are in the file named in the last column.

Last updated: 2026-10-27 (phone test day done for M1 to M5; M6 live phase waiting).

## Decisions waiting

| # | What | Why it waits | Where |
|---|------|--------------|-------|
| ~~D1~~ | ~~Confirm M4 and M5~~ | Done 2026-10-27: both merged into `main`, CI green | `docs/milestones/M4.md`, `M5.md` |
| ~~D2~~ | ~~OK for the M5 plan and its packages~~ | Done 2026-10-26: approved, with adult recordings now and the children's accuracy left for a later phase | `docs/milestones/M5.md` |
| ~~D3~~ | ~~A number for Q9~~ | Done 2026-10-26: the daily cap stays at 0.50 USD per family (changeable in `config` without an update) | `docs/milestones/M6.md` |

M5 work, once approved, is stacked on the M4 branch (`m5-voice-in` starts from `m4-characters-voice`), so nothing is merged to `main` without D1.

## Checks to do on the phone (the Samsung plugged into the PC)

**Phone test day done on 2026-10-27** for M1 to M5 (T1 to T4 and T6; T5, frame times, was optional and not run). It found and fixed: the parent gate was too hard (now a small sum), the map bubble was far from the friend's mouth, a line could start playing after leaving a lesson, the mic was withdrawn after failed listens (now never), the mic stayed open after going to the background, and the map showed half loaded (now a loading scene). T7 (the AI helper) waits for the live phase (P7).

**One sitting, in order, with expected results and what to report: `docs/phone-test-day.md`** (about 2 hours). The table below is the same list in short.

Each one is a short list of steps with the expected result. Run them in this order, in one sitting if you can.

| # | Check | Time | Steps |
|---|-------|------|-------|
| ~~T1~~ (done 2026-10-27) | M1: install, wrong-PIN lock-outs, the database file is encrypted, PIN hashing time | 20 min | `docs/setup/android-device-checks.md` sections 1 to 4 |
| ~~T2~~ (done 2026-10-27) | M2: play the butterflies lesson; damaged packs are refused | 15 min | same file, section 6 |
| ~~T3~~ (done 2026-10-27) | M3: what the learning engine concluded about the child who played | 5 min | same file, section 7 |
| ~~T4~~ (done 2026-10-27) | M4: install the 8 family characters and 9 test voices, pick a friend on Friends' Beach, hear the tones with the mouth moving, celebrate, switch back | 20 min | same file, section 8 (one command builds and pushes the packs: `tools\make-m4-device-packs.ps1 -Push`) |
| T5 | M4, optional: frame times in profile mode on the Samsung | 5 min | same file, section 8E |
| T7 | M6: the AI helper on the phone (off by default, a made line on the second mistake, no network, kill switch, Band A without caption); after P7 | 15 min | same file, section 10 |
| ~~T6~~ (done 2026-10-27) | M5: model on the phone, voice switch, answer by voice, the repair steps, how long the model takes to load | 20 min | same file, section 9 |

## Things to look at and judge

| # | What | Where |
|---|------|-------|
| R1 | Hebrew review: every child-facing string (all marked `needs-editor`) and the 19 core voice lines | `app/lib/strings/he.dart`, `content/lines/core.he.json` |
| R2 | Look at the new screens against what you imagined: the map with the companion, Friends' Beach, the celebration card | goldens in `app/test/goldens/` (`companion_*.png`), or on the phone in T4 |
| R3 | Which friend would the children pick first? Is anything stiff, cut, too small or too slow to touch? | T4 |

## Tasks for the PC

| # | What | Where |
|---|------|-------|
| P1 | ~~Pack signing key~~ **Done 2026-10-28:** a new key was made and saved in 1Password. Keep it there and keep the PC copy (`%USERPROFILE%\nitznutz-secrets\pack-signing.key`). | `PROGRESS.md` (Open issues) |
| P2 | Screenshots of the spend limits in the Anthropic and ElevenLabs consoles | `docs/setup/` |
| P3 | **Real voices (M4 Phase H).** Choose a voice for each of the nine characters from short auditions, tell Claude the model id you pick in ElevenLabs, see the plan and the cost, type the exact character count back, and listen to every generated line. About an hour. Claude gives the numbered PowerShell steps when you say you are at the PC. | `docs/milestones/M4.md` Phase H |
| P4 | **Adult recordings for the M5 speech check** (about 15 minutes, you and your wife; any voice-recorder app; a normal room, phone held as a child would). Say each of these three times, once alone and once in a short phrase ("שלוש פרפרים"): the numbers 1 to 10, the colours אדום, כחול, צהוב, ירוק, and כן, לא, עוד פעם, לא יודע, עזרה. Save them as **16-bit WAV** files named `<speaker>_<word>_<n>.wav` (for example `ram_3_1.wav`) in one folder, and write `labels.csv` beside them with one line per file: `file,type,intended,options` (for example `ram_3_1.wav,number,3,2|3|4` or `dana_red_2.wav,colour,red,red|blue|yellow`). Then run `powershell -ExecutionPolicy Bypass -File tools\run-asr-eval.ps1 <folder>`; it prints how many accepted answers were right (the goal is 97%), how many were asked to confirm or repeat, the speed, and the misses. If you would rather not write the labels by hand, send me the folder and the list of what was said, and I will make them. | `docs/milestones/M5.md` Q6 and section 11 |
| P5 | **Put the speech model on the phone** (one command, 72 MB, phone plugged in): `tools\make-m5-model.ps1 -Push` | `docs/setup/android-device-checks.md` section 9 |
| P7 | **Live AI tutor (M6 Phase F).** Create the Anthropic key and the ElevenLabs key (each with its spend limit set first), send them with the hidden-prompt steps, set the ElevenLabs model id and the prices from the providers' pages, deploy, publish the starter pack, then run the pre-warm: it shows the number of lines and the cost and waits for you to type the number back. Then measure the speed, read the made lines in the SQL Editor, listen to them on the phone, and only then leave the helper on in the dev page. About an hour. | `docs/setup/supabase-deploy.md` section 8 |
| P6 | **Children's recordings** (later phase, same format and tool, with a parent present; the gate "97% for children" stays open until then) | `docs/milestones/M5.md` Q6 |
| P8 | **Make the repository private again** (GitHub, repository Settings, General, Danger Zone, Change visibility). It was made public on 2026-10-28 only so that CI could run when the free Actions minutes ran out. Do it once the full app is implemented, after either the billing is sorted or the CI runs on a self-hosted runner. Until then everything committed is readable by anyone. | `PROGRESS.md` (Open issues) |
| P9 | **Find and brief an illustrator.** The brief is `docs/art/art-brief.md` (what to make, style, file format, quantities, order, motion, acceptance list). Agree price, timeline and rights with the artist; ask for the three sample pieces first. | `docs/art/art-brief.md` |
