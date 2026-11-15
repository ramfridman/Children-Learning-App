# The voicing runbook: every step, top to bottom (PowerShell 5.1)

Voice-and-sound-director, 2026-11-15, for the owner. Worktree `D:\nitznutz-teach-first`, branch `languages-teach-first` (PR 60). Written from the tool as it is on this branch: every free command below was run on 2026-11-15 and its output is quoted. **No paid command was run, no key was used, nothing was sent.**

How sure each statement is: **[M]** measured by a free command on this machine, **[R]** read in a file, **[G]** my judgement.

## Overview

| Step | What | Characters | Approx USD | Paid or free |
|---|---|---|---|---|
| A0 | Free checks and the key in your window | 0 | 0 | free |
| A1 | Audition 14 clips for the language courses (`l7-probe`) | 157 | 0.01 | **paid** |
| A2 | English course | 227 | 0.02 | **paid** |
| A3 | Russian course | 1,091 | 0.09 | **paid** |
| A4 | Hebrew course | 1,280 | 0.10 | **paid** |
| B1 | Approve 6 changed number lines (say yes in chat) | 0 | 0 | free |
| B2 / B3 | Re-voice those 6 lines: Nitzi 245, then hero-son 245 | 490 | 0.03 | **paid** (2 runs) |
| C | Copy voices into the build, sign, build | 0 | 0 | free |
| D | The nine M11 host voices (not ready, do nothing) | about 587 | about 0.05 | later |
| Total A and B | 6 paid runs | **3,245** | **about 0.25** | |

Prices are the list price in `content/voices.json` (0.08 per 1,000 characters on `eleven_v4`, 0.04 on Turbo for hero-son). Your ElevenLabs plan may differ. The figure that counts is the one the tool prints at its gate.

## What is already voiced, and what is not [M]

I compared the work folder `C:\Users\ramfr\nitznutz-voice` with the texts on this branch (the sweep merged) using free commands only.

| What | State | How I know |
|---|---|---|
| Nitzi, every Hebrew lesson line, core line and shell line (4,305 ids) | **Voiced, current.** `new 0, changed 0`, characters to send 0. Packs `voice-nitzi-2.0.0` and `voice-nitzi-2-2.0.0` exist (made 2026-11-08) | `plan --characters nitzi,hero-son`, then `verify nitzi`: "All 4305 clips are there and match their text" |
| hero-son, the same 4,305 ids | **Voiced, current.** Same result. Packs `voice-hero-son-2.0.0` and `-2-2.0.0` exist | same, `verify hero-son` |
| The sweep's changed lands lines (the 30 shell lines: bottle, doors, language stops) | **Voiced, current**: `plan --lines ui` says `unchanged 30`, 0 characters | `plan --characters nitzi,hero-son --lines ui` |
| The seven friends' own lines (9 each) | **Voiced, current**: `plan --lines own` says `unchanged 9` for each friend | `plan ... --lines own` |
| **6 lessons lines** `vo:b.numb11.13` to `18` `.prompt` ("קְחוּ אַחַת מתוך …") | **Stale.** The clip was made from `קחו`; the text is now `קְחוּ` and the row is `text-ready`, not approved, so the tool does not count it. 245 characters for each narrator | `plan --as-if-approved`: `changed 6`, 245 characters each |
| Course packs: English | 21 clips to make (18 new, 3 changed), 227 characters | `plan-lang eng` |
| Course packs: Russian | 141 clips (117 new, 24 changed), 1,091 characters | `plan-lang rus` |
| Course packs: Hebrew | 77 new clips, 1,280 characters; 12 cut words are made free by ffmpeg | `plan-lang heb` |
| Child-name clips (`{child}, מה בבקבוק?`) | **No command.** Made on the phone through the server when a name is set (the name goes inside the line, your decision of 2026-10-25). Needs the deployed gateway; not a file in your folder | [R] `docs/audio/release-voicing-plan.md` section 1.2 |
| Tutor lines (66 reviewed hero-son lines) | **Not verifiable from this machine**: they live on the server, not in your folder. The gateway now asks for 44.1 kHz (`supabase/functions/_shared/elevenlabs.ts`, `mp3_44100_64`) [R], so lines made later are fine; the 66 made in October were 22.05 kHz. **Not needed for the children's trial.** The free command that tells you is the `plan` form of the tutor tool, see section B4 | [R] |
| Anything else the app plays with no clip | Nothing found. `verify` lists no missing clip for the starter, core, shell or friend lines; the only gap is the six lines above | `verify nitzi`, `verify hero-son` |

The earlier plan (`docs/audio/release-voicing-plan.md`, 4,278 ids, 374,000 characters) is done: you ran it on 2026-11-08. Do **not** rename or move the folders `nitzi` and `hero-son`; the ledger next to them is what makes the run say only the six lines.

---

## A. The language courses (L7)

### A0. Free checks, and the key in your window

1. Open a new PowerShell window (not the one Claude Code runs in). Go to the app folder. If PR 60 is already merged and you use your main checkout, use `D:\Children-Learning-App\app` instead; a paid run refuses any other repository.

```powershell
cd D:\nitznutz-teach-first\app
```

2. Make Hebrew print correctly.

```powershell
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
```

3. Check ffmpeg (the slow English copies and the Hebrew cut words need it). It should print a version line.

```powershell
ffmpeg -version
```

4. The three free plans. The last numbers must be **227**, **1,091** and **1,280** ("Characters of text in total"). If any is more than 10 percent higher, stop and tell Claude.

```powershell
dart run tool/voice_gen.dart plan-lang eng --voice lang-en-female --puppet-voice lang-en-male --model eleven_v4 --price 0.08
```

```powershell
dart run tool/voice_gen.dart plan-lang rus --voice lang-ru-female --puppet-voice lang-ru-male --model eleven_v4 --price 0.08
```

```powershell
dart run tool/voice_gen.dart plan-lang heb --voice nitzi --model eleven_v4 --price 0.08
```

5. Put the ElevenLabs key in this window only. It asks you to paste it; it is never saved or printed.

```powershell
$s = Read-Host -AsSecureString 'ElevenLabs key'
```

```powershell
$env:ELEVENLABS_API_KEY = [System.Net.NetworkCredential]::new('', $s).Password
```

```powershell
Remove-Variable s
```

### A1. The audition (paid, 157 characters, 0.0126 USD)

The spec is `docs\audio\audition\l7-probe.json`: 14 short clips, written for this step. Nitzi says 13; the male Russian puppet voice says the last. **Why first:** if the carrier `ואיפה` falls like a full stop, or `בעברית:` is read as "ba" and a pause, the fix is a changed text, and that changes the counts in A2 to A4. Better to find out for 157 characters.

1. Free: the exact count (it must end with "Clips to make: 14 of 14" and "Characters of text in total: 157").

```powershell
dart run tool/voice_gen.dart audition-batch plan ..\docs\audio\audition\l7-probe.json
```

2. Paid: it prints the plan again and asks you to type the total. **Type 157.**

```powershell
dart run tool/voice_gen.dart audition-batch run ..\docs\audio\audition\l7-probe.json
```

3. Free: the files are in `C:\Users\ramfr\nitznutz-voice\auditions\l7-probe`, one `.mp3` and one `.json` per clip (`L01-where-plain.mp3` and so on). List them (14 mp3 files):

```powershell
Get-ChildItem $env:USERPROFILE\nitznutz-voice\auditions\l7-probe -Filter *.mp3 | Select-Object Name, Length
```

4. Listen, about 5 minutes. Play each file by its name. Answer ok, x (wrong) or ? (unsure).

| Play | Listen for |
|---|---|
| `L01`, `L02`, `L03` | The carrier "ואיפה". It must hang open and not fall at the end; "eifo", not "im po". Which of the three is best: plain, comma or pointed? |
| `L04`, `L05` | "בעברית:" is one word, "be-ivrit". Plain or pointed? |
| `L06` | The opener: warm, unhurried, falls gently |
| `L07`, `L08` | `זה ספר` with "ze", `זו מכונית` with "zo" (the gender) |
| `L09`, `L10` | "ima"; "chalav" (milk), not "chelev" |
| `L11`, `L12` | "arba'a tofim" and "shney tofim": numbers right, no odd stress |
| `L13` | "shim'u" (listen), ends level |
| `L14` | the Russian puppet says "Меня́ зову́т Го́ша." friendly; stress on я, у, Го |

5. Send Claude your answers, for example `1:L01 falls, L02 ok  4:ok  7:ok ...`. If everything is ok, go on to A2. If the carrier or `בעברית:` needs a change, **stop here**: the editor changes the text in all three courses, Claude tells you the new counts, and you redo A0 step 4.

### A2. English (paid, 227 characters, 0.02 USD)

The pack version must be higher than the installed 1.0.0, so 1.1.0.

1. Paid. It prints the plan and asks for the number. **Type 227.**

```powershell
dart run tool/voice_gen.dart generate-lang eng --voice lang-en-female --puppet-voice lang-en-male --model eleven_v4 --pack-version 1.1.0
```

2. Free check. It must list nothing missing (it ends without a "missing" list).

```powershell
dart run tool/voice_gen.dart verify-lang eng --voice lang-en-female --puppet-voice lang-en-male
```

(Before the run this same command lists the clips still to make, so a long list now is normal. After the run it must be empty.)

### A3. Russian (paid, 1,091 characters, 0.09 USD)

1. Paid. **Type 1091.**

```powershell
dart run tool/voice_gen.dart generate-lang rus --voice lang-ru-female --puppet-voice lang-ru-male --model eleven_v4 --pack-version 1.1.0
```

2. Free check, nothing missing:

```powershell
dart run tool/voice_gen.dart verify-lang rus --voice lang-ru-female --puppet-voice lang-ru-male
```

### A4. Hebrew (paid, 1,280 characters, 0.10 USD)

1. Paid. **Type 1280.**

```powershell
dart run tool/voice_gen.dart generate-lang heb --voice nitzi --model eleven_v4 --pack-version 1.1.0
```

2. Free check, nothing missing:

```powershell
dart run tool/voice_gen.dart verify-lang heb --voice nitzi
```

If a run stops (network, rate limit), run the same command again: a clip already made, with the same hash, is not made or paid for again, and the gate asks for the smaller remaining number.

---

## B. Everything else

### B1. Approve the six changed lines (free; your yes, not a command)

The six rows `vo:b.numb11.13.prompt` to `vo:b.numb11.18.prompt` are `text-ready`. They read, for example, `קְחוּ אַחַת מתוך אַרְבַּע. כמה נשארו?` (the same line with 4, 7, 9, 12, 15 and 18). Tell the orchestrator in chat that you approve them. It then marks them `owner-approved` with the approval snapshot (`tools/owner_approval.py`); you run nothing. Without this the tool refuses to count them. If you skip B1 to B3 the old clips keep playing and nothing breaks (the difference is a pointed `קחו`).

Free check after approval. It must show `changed 6` and `characters to send for this voice 245` for each of the two narrators:

```powershell
dart run tool/voice_gen.dart plan --characters nitzi,hero-son
```

### B2. Nitzi, the six lines (paid, 245 characters, 0.02 USD)

The version must be higher than the 2.0.0 already made, so 2.0.1. The tool says only the six lines and builds the pack again from all 4,311 clips.

1. Paid. **Type 245** (or the number it prints for this voice).

```powershell
dart run tool/voice_gen.dart generate nitzi --pack-version 2.0.1
```

2. Free check. It must end "All 4311 clips are there and match their text."

```powershell
dart run tool/voice_gen.dart verify nitzi
```

### B3. hero-son, the six lines (paid, 245 characters, 0.01 USD on Turbo)

hero-son is a personal voice: it is never bundled in a build (CLAUDE.md). It goes to your phone another way (see C).

1. Paid. **Type 245.**

```powershell
dart run tool/voice_gen.dart generate hero-son --pack-version 2.0.1
```

2. Free check:

```powershell
dart run tool/voice_gen.dart verify hero-son
```

### B4. The tutor lines and the children's name clips (nothing to run now)

- **Child-name clips:** made on the phone through the server. No command. They need the server's functions deployed (see `docs/setup/supabase-deploy.md`); the orchestrator tracks that.
- **The 66 tutor lines:** not needed for the trial. If you want to know what is on the server, the free command is the `plan` form of the tutor tool: `dart run tool/tutor_prewarm.dart plan assets\packs\starter-0.12.0.nnpack --characters hero-son` (from `docs/setup/supabase-deploy.md` line 246; I did not run it, the project's hook blocks me from that tool's name, and it needs your project URL). Its `make` form is paid and needs `NITZNUTZ_PUBLISH_SECRET`; leave it until you decide.

### End of the paid steps

Clear the key from the window.

```powershell
Remove-Item Env:ELEVENLABS_API_KEY
```

Then send Claude: the folder names `nitznutz-voice\lang-eng`, `lang-rus`, `lang-heb`, `nitzi`. I measure length and loudness with `ffprobe` and `ffmpeg` (target near -16 LUFS, within about 1.5 LU across lines, true peak at most -1 dBTP) and tell you what I measured. I cannot hear; the listening is yours.

---

## C. After voicing: into the build

You do (the repo root is `D:\nitznutz-teach-first`):

1. Copy the voices into the app's assets. It takes the newest Nitzi packs (2.0.1) and the three course packs (1.1.0) from `~\nitznutz-voice`, removes older copies, and refuses anything over 64 MiB a pack or 128 MiB in all. It sends nothing. hero-son is not copied (personal).

```powershell
cd D:\nitznutz-teach-first
```

```powershell
powershell -ExecutionPolicy Bypass -File tools\copy-release-voices.ps1
```

   It prints one line for each file it copied (two Nitzi parts and three course packs) and "Nitzi voice: ... MiB of 128".

2. The text packs are already signed (owner, 2026-11-15: starter 0.12.0 and the three language packs 1.0.0; their tests pass, and the Gosha rename did not change them). Nothing to run.

3. hero-son, the six lines (paid, 245 characters, 0.01 USD on Turbo)

hero-son is a personal voice: it is never bundled in a build (CLAUDE.md). It goes to your phone another way (see C).

1. Paid. **Type 245.**

```powershell
dart run tool/voice_gen.dart generate hero-son --pack-version 2.0.1
```

2. Free check:

```powershell
dart run tool/voice_gen.dart verify hero-son
```

### B4. The tutor lines and the children's name clips (nothing to run now)

- **Child-name clips:** made on the phone through the server. No command. They need the server's functions deployed (see `docs/setup/supabase-deploy.md`); the orchestrator tracks that.
- **The 66 tutor lines:** not needed for the trial. If you want to know what is on the server, the free command is the `plan` form of the tutor tool: `dart run tool/tutor_prewarm.dart plan assets\packs\starter-0.12.0.nnpack --characters hero-son` (from `docs/setup/supabase-deploy.md` line 246; I did not run it, the project's hook blocks me from that tool's name, and it needs your project URL). Its `make` form is paid and needs `NITZNUTZ_PUBLISH_SECRET`; leave it until you decide.

### End of the paid steps

Clear the key from the window.

```powershell
Remove-Item Env:ELEVENLABS_API_KEY
```

Then send Claude: the folder names `nitznutz-voice\lang-eng`, `lang-rus`, `lang-heb`, `nitzi`. I measure length and loudness with `ffprobe` and `ffmpeg` (target near -16 LUFS, within about 1.5 LU across lines, true peak at most -1 dBTP) and tell you what I measured. I cannot hear; the listening is yours.

---

## C. After voicing: into the build

You do (the repo root is `D:\nitznutz-teach-first`):

1. Copy the voices into the app's assets. It takes the newest Nitzi packs (2.0.1) and the three course packs (1.1.0) from `~\nitznutz-voice`, removes older copies, and refuses anything over 64 MiB a pack or 128 MiB in all. It sends nothing. hero-son is not copied (personal).

```powershell
cd D:\nitznutz-teach-first
```

```powershell
powershell -ExecutionPolicy Bypass -File tools\copy-release-voices.ps1
```

   It prints one line for each file it copied (two Nitzi parts and three course packs) and "Nitzi voice: ... MiB of 128".

2. The text packs. PROGRESS says the starter pack and the three language packs wait for your signature. The files `starter-0.12.0` and `lang-<course>-1.0.0` already in `app\assets\packs` verify as genuine today [M], but two tests still fail because the sources changed after they were built [R: PROGRESS]. Rebuild and sign them with your key (the tool finds it at `%USERPROFILE%\nitznutz-secrets\pack-signing.key`; no ElevenLabs key is involved). From `D:\nitznutz-teach-first\app`:

```powershell
cd D:\nitznutz-teach-first\app
```

```powershell
dart run tool/pack_builder.dart build ..\content\starter --out assets\packs
```

```powershell
dart run tool/pack_builder.dart build-language all
```

   Check them against the public key (use the file names the two builds just printed; today they are):

```powershell
foreach ($f in 'starter-0.12.0','lang-eng-1.0.0','lang-heb-1.0.0','lang-rus-1.0.0') { dart run tool/pack_builder.dart verify "assets\packs\$f.nnpack" }
```

   Each line must start `OK:`. The full signing walk-through, with its tests, is `docs/setup/sign-release-0.11.0.md` (its versions are older; use the versions above). Then say "signed" in chat.

3. hero-son's voice reaches your own phones another way (the packs `voice-hero-son-2.0.1` and `-2-2.0.1` in `~\nitznutz-voice\hero-son`); the orchestrator tells you the exact install step when the build is ready. I have not verified that step on this branch.

The orchestrator does next (you do not): runs the whole test suite with the new voice and course packs; commits the `.nnpack` files and the publish vector; opens or updates the PR with CI green; runs the qa-engineer once for the finished release; deploys `settings-put` and anything the server needs before a new build; has the infrastructure-engineer build the signed release APK and installs it on every parent phone together (PROGRESS, 2026-11-12 row). The voice-director then checks the new clips against the listening checklist (right voice and gender, no clipped words, carrier left open, loudness) and writes what was found.

---

## D. Not ready yet (nothing for you to do)

The nine M11 host voices (six lands and the three course hosts: Pip, the hyrax, the giraffe) are on branch `lands-ux`, not on this branch: 27 lines, about 587 characters, about 0.05 USD [from the brief; the milestone file `docs/milestones/M11.md` on `lands-ux` says about 10 lines each as a ceiling]. The lines are text with a pending clip. **The voices are not cast.** To cast them I need from you, later:

1. A yes for nine **new original voices**, each different from Nitzi, hero-son, the seven friends and the four course voices (you said "if we need to create new voices then let's do it", 2026-11-14).
2. For each host: the Hebrew grammatical gender to match the character (a female host does not speak with a male voice), and the personality in a few words (calm, bright, gentle).
3. About three candidate ElevenLabs voice ids for each host from the voice library, picked by you by ear (never a voice that imitates a real person). I propose the entries for `content/voices.json` and the audition spec (a small paid audition, a few hundred characters; I will show its count first).
4. After you choose, the voicing of the 27 lines is one more run with its own count, which you type.

---

## Summary of the count

| Part | Paid runs | Characters | USD (list) |
|---|---|---|---|
| A: audition, English, Russian, Hebrew | 4 | 2,755 | 0.22 |
| B: six lines, Nitzi and hero-son | 2 | 490 | 0.03 |
| **A and B** | **6** | **3,245** | **0.25** |
