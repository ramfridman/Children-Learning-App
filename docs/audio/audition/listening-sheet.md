# Listening sheet: the diagnostic audition, rounds 1 and 2

Written by the voice-and-sound-director on 2026-10-29. The clips are in `round1.json` and `round2.json` next to this
file. Each spec gives every clip's exact text, model, settings and format, and the question the clip answers (`tests`).
The plan prints all of this again before anything is sent.

| Round | Clips | Characters (my count) | Cost at list prices | When |
|---|---|---|---|---|
| 1 | 34 (32 Nitzi, 2 hero-son) | **1,852**: eleven_v4_turbo 759, eleven_v4 1,093 | **0.1178 USD** | now |
| 2 | 59 (36 of them the editor's H1 A/B) | **2,774**, all on the model round 1 picks | **0.2219 USD** on eleven_v4 (0.1110 on Turbo) | after I have read your round-1 scores and updated `round2.json` |

The number you type is the total that the tool prints, not mine. If they differ, stop and tell Claude.

---

## A. Make the clips yourself (Windows PowerShell)

Claude never runs these commands. Claude will tell you when these files are on `main` in `D:\Children-Learning-App`.
Until then the commands below do not work there.

1. **Open a separate PowerShell window.** Start menu, type `PowerShell`, open **Windows PowerShell**. Do not use the
   window or terminal where Claude Code runs: the key must never be in a process that Claude can read.
2. Go to the app folder, and let the window show Hebrew:

   ```powershell
   cd D:\Children-Learning-App\app
   [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
   ```

3. **The free plan** (it sends nothing and needs no key):

   ```powershell
   dart run tool/voice_gen.dart audition-batch plan ../docs/audio/audition/round1.json
   ```

   It lists all 34 clips and ends with:

   ```
   Clips to make: 34 of 34
   Characters by model: eleven_v4_turbo 759, eleven_v4 1093
   Characters of text in total: 1852
   Estimated cost at list prices: 0.1178 USD (your ElevenLabs plan may differ)
   ```

   Stop here and tell Claude if you see any of these: "The pre-flight check refuses", "FAILED", or a different total.
   If it says packages are missing, run `flutter pub get` once (free) and repeat this step. The console may show the
   Hebrew with its letters in reverse order. The exact text of every clip is in the spec, and after the run it is also
   in the `.json` file next to each clip.

4. **The key, typed into a hidden prompt.** It shows `*` while you paste. It stays only in this window's memory, never in
   a file or in the command history:

   ```powershell
   $s = Read-Host -AsSecureString 'ElevenLabs key'
   $env:ELEVENLABS_API_KEY = [System.Net.NetworkCredential]::new('', $s).Password
   Remove-Variable s
   ```

5. **The paid run:**

   ```powershell
   dart run tool/voice_gen.dart audition-batch run ../docs/audio/audition/round1.json
   ```

   It prints the same plan, then asks: *"To spend them on this audition, type the number of characters shown above
   (anything else stops):"*. Type the number from the line "Characters of text in total" (1852 if nothing changed) and
   press Enter. Anything else stops the run, and nothing is sent.

   As it works it prints `made ...` for each clip. At the end it prints `Made 34 clips in
   C:\Users\<you>\nitznutz-voice\auditions\round1`. If the run stops halfway (for example, the network drops), repeat
   step 5. Clips already made are skipped and not paid for again. The new total is smaller: type that new number.

6. **Close the key and the window:**

   ```powershell
   Remove-Item Env:ELEVENLABS_API_KEY
   exit
   ```

7. **Old clips for comparison.** This is free and needs no key, so any PowerShell window will do. It copies five of
   today's Nitzi clips next to the new ones:

   ```powershell
   $dst = "$env:USERPROFILE\nitznutz-voice\auditions\round1-old"
   New-Item -ItemType Directory -Force $dst | Out-Null
   foreach ($n in 'pick.red.flower.prompt','count.butterflies.3.prompt','count.butterflies.3.h3','core.celebrate.well','core.encourage.check') {
     Copy-Item "$env:USERPROFILE\nitznutz-voice\nitzi\vo.$n.mp3" "$dst\old-$n.mp3"
   }
   explorer "$env:USERPROFILE\nitznutz-voice\auditions"
   ```

8. **To the phone.** Copy the `round1` and `round1-old` folders (only the `.mp3` files are needed).
   - Android: connect a USB cable, choose "File transfer" on the phone, and drag the folders into `Music`.
   - iPhone: upload the folders to OneDrive or iCloud Drive and play them from the Files app.

   The clips hold only these test sentences. There is nothing about the children in them. Delete the phone copy once
   you have scored the clips.

**Round 2.** Do the same steps with `round2.json`, but only after Claude says it has been updated from your round-1
scores. The folder will be `auditions\round2`. The plan should show 59 clips and the total Claude gives you then
(2,774 if the model stays eleven_v4).

---

## B. How to listen and score

- Listen to each clip twice: once on the **phone speaker** and once on **headphones**. Play pairs back to back (the same
  line number with `p` / `v` / `x`, or with `-turbo` / `-v4`). Listen once without reading, then once with the "Listen
  for" column.
- Score from **1 to 5** in each column. 1 = wrong or unpleasant, 3 = acceptable, 5 = how a warm Israeli kindergarten
  teacher would say it.
  - **W**: the right words and vowels
  - **S**: the stress on the right syllable
  - **R**: natural rhythm, not rushed, not read syllable by syllable
  - **Wa**: warmth (kind, glad, never a shout or a scold)
  - **NR**: not robotic (no metallic, "underwater" or flat sound)
- **Notes**: one or two words on what you heard ("kal", "shouts", "metal", "letters", "too slow").
- Then send Claude the filled tables (pasted text or a photo).

Spelled sounds: capitals mark the stressed syllable. "ch" is the sound of כ without a dagesh (as in "Bach").

---

## C. Round 1 (34 clips)

Today's clips came from **p**: the full pointing as sent on 2026-10-28. **v**: the editor's plene `voice_text`.
**x**, **m**, **s**, **i**: one change only (`!`, the other hum, the word pointed, the word in IPA).

| Clip | Listen for | W | S | R | Wa | NR | Notes |
|---|---|---|---|---|---|---|---|
| L1p-turbo | "ha-a-DOM" (red), not "ha-a-DAM" (person); then `old-pick.red.flower.prompt`: is the new one clearer? | | | | | | |
| L1p-v4 | the same, on v4 | | | | | | |
| L1v-turbo | "ha-a-DOM"; plain text | | | | | | |
| L1v-v4 | the same, on v4 | | | | | | |
| L2p-turbo | "nis-POR" (not "ne-sa-PER"), "be-CHOL" (not "be-chal"); speech, not syllables; then `old-count.butterflies.3.prompt` | | | | | | |
| L2p-v4 | the same, on v4 | | | | | | |
| L2v-turbo | does it flow like speech? | | | | | | |
| L2v-v4 | the same, on v4 | | | | | | |
| L2v-v4-128 | headphones: are sh, s and ts fuller than in L2v-v4? (If you cannot tell, write "same") | | | | | | |
| L3p-turbo | "a-CHAT, sh-TA-yim, sha-LOSH": calm or rushed? Then `old-count.butterflies.3.h3` | | | | | | |
| L3v-turbo | a calm count; a small beat at the dash | | | | | | |
| L3v-v4 | the same, on v4 | | | | | | |
| L4p-turbo | "KOL ha-ka-VOD", not "kal"; glad, not shouting; then `old-core.celebrate.well` (made at stability 0.1) | | | | | | |
| L4v-turbo | with a full stop: glad, or flat? | | | | | | |
| L4v-v4 | the same, on v4 | | | | | | |
| L4x-turbo | with one `!`: glad, or shouting? | | | | | | |
| L4x-v4 | the same, on v4 | | | | | | |
| L5p-turbo | a hum, or the letters "ha-mem"? "niv-DOK", not "niv-DAK"; then `old-core.encourage.check` | | | | | | |
| L5v-turbo | a thinking "hmmm", then "niv-DOK" | | | | | | |
| L5v-v4 | the same, on v4 | | | | | | |
| L5m-turbo | the other hum, "mmmm": more like thinking? | | | | | | |
| L5m-v4 | the same, on v4 | | | | | | |
| L6v-turbo | "sha-VE" (equals), not "SHA-ve"; the numbers clear | | | | | | |
| L6v-v4 | the same, on v4 | | | | | | |
| L6s-turbo | "sha-VE" with the word pointed: better than L6v? | | | | | | |
| L6s-v4 | the same, on v4 | | | | | | |
| L6i-turbo | the word in IPA: "sha-VE", or spelled-out letters? | | | | | | |
| L6i-v4 | the same, on v4: clean, with no seam and no foreign accent? | | | | | | |
| L7v-turbo | **hero-son**: "nis-POR", "be-CHOL"; a natural male voice? | | | | | | |
| L7v-v4 | the same, on v4 | | | | | | |
| L8v-turbo | prompt and question in one clip: does the question at the end rise naturally? | | | | | | |
| L8v-v4 | the same, on v4 | | | | | | |
| L10a-v4 | five lines in one take: one warm flow, or does each line restart? Compare its start with L8v-v4 | | | | | | |
| L10b-v4 | the "not yet" lines in one take: kind and curious, never a scold; glad at the end | | | | | | |

**What round 1 decides** (I write the decisions; you only score): the **model** (each `-turbo` against `-v4`), the
**text form** (`p` against `v`), the **format** (L2v-v4-128, and the old clips), the **cheer punctuation** (L4v
against L4x), the **hum** (L5v against L5m), **"equals"** (L6v, L6s, L6i), and **one request per activity** (L8, L10)
against line by line.

---

## D. Round 2 (59 clips)

On the model that round 1 picks, Nitzi's voice unless the row says otherwise.

| Clip | Listen for | W | S | R | Wa | NR | Notes |
|---|---|---|---|---|---|---|---|
| S1-cheer-010 | "kol ha-kavod!" at stability 0.1: bright and even, or wobbly? | | | | | | |
| S1-cheer-050 | the same at 0.5 | | | | | | |
| S1-cheer-080 | the same at 0.8: flat? | | | | | | |
| S2-bronze-010 | "BRON-za" (stress first); glad, not shouting; 0.1 | | | | | | |
| S2-bronze-050 | the same at 0.5 | | | | | | |
| S2-bronze-080 | the same at 0.8 | | | | | | |
| S3-L2v-010 | a lesson line at 0.1: a person telling, or erratic? | | | | | | |
| S3-L2v-050 | at 0.5; also a retake of L2v-v4: equally good? | | | | | | |
| S3-L2v-080 | at 0.8: flat? | | | | | | |
| C-gold-010 | the gold cup at 0.1 (today's cheer): glad, not shouting | | | | | | |
| C-gold-050 | the same at 0.5 | | | | | | |
| C-silver-010 | the silver cup at 0.1 | | | | | | |
| C-silver-050 | the same at 0.5 | | | | | | |
| C-medal-010 | "me-DAL-ya"; at 0.1 | | | | | | |
| C-medal-050 | the same at 0.5 | | | | | | |
| C-medal-tzuri-010 | **Tzuri's voice**: native Hebrew? "me-DAL-ya"; at 0.1 | | | | | | |
| C-medal-tzuri-050 | the same at 0.5 | | | | | | |
| C-medal-tamir-010 | **Tamir's voice** (also Keshet's): native Hebrew? at 0.1 | | | | | | |
| C-medal-tamir-050 | the same at 0.5 | | | | | | |
| T1-plain | "kim'AT, bo'u ne-na-SE shuv": kind and curious | | | | | | |
| T1-gently | the same with a `[gently]` tag: softer? Is the word "gently" ever said aloud? | | | | | | |
| T2-plain | "she-e-LA to-VA...": warm | | | | | | |
| T2-warmly | the same with a `[warmly]` tag: warmer? Is the tag said aloud? | | | | | | |
| H1-mixed-a-nitzi | as sent today: "ha-oz-NA-yim", not "az-NA-yim"; a shout on the `!`? | | | | | | |
| H1-mixed-b-nitzi | the editor's text: light and kind (the fault is the helper's ears) | | | | | | |
| H1-mixed-c-nitzi | with a beat after "oops": funny, or too long? | | | | | | |
| H1-butterflies-a-nitzi | as sent today: "KOL", not "kal"; shouting? | | | | | | |
| H1-butterflies-b-nitzi | the editor's text (a comma): glad enough? | | | | | | |
| H1-butterflies-c-nitzi | with one `!`: glad, or shouting? | | | | | | |
| H1-stars-a-nitzi | as sent today: "be-ko-CHAV" with a hard k? | | | | | | |
| H1-stars-b-nitzi | the editor's text: "be-cho-CHAV" (soft) | | | | | | |
| H1-stars-c-nitzi | with no points at all: the same as b, or smoother? | | | | | | |
| H1-birds-a-nitzi | as sent today: ten numbers, rushed and flat? | | | | | | |
| H1-birds-b-nitzi | the editor's text (commas): calm? | | | | | | |
| H1-birds-c-nitzi | with `…` between the numbers: calmer, or too slow? | | | | | | |
| H1-bugs-a-nitzi | as sent today ("ha-IM"): does the question rise? Formal? | | | | | | |
| H1-bugs-b-nitzi | without "ha-IM": still clearly a question? | | | | | | |
| H1-bugs-c-nitzi | plain text with "ha-IM": does the wording or the pointing make the difference? | | | | | | |
| H1-medal-a-nitzi | as sent today: "me-DAL-ya"; shouting? | | | | | | |
| H1-medal-b-nitzi | the editor's text: "me-DAL-ya"; glad | | | | | | |
| H1-medal-c-nitzi | no points: the same stress? | | | | | | |
| H1-mixed-a-hero | **hero-son**, the same six lines and three forms: as for Nitzi above | | | | | | |
| H1-mixed-b-hero | | | | | | | |
| H1-mixed-c-hero | | | | | | | |
| H1-butterflies-a-hero | | | | | | | |
| H1-butterflies-b-hero | | | | | | | |
| H1-butterflies-c-hero | | | | | | | |
| H1-stars-a-hero | | | | | | | |
| H1-stars-b-hero | | | | | | | |
| H1-stars-c-hero | | | | | | | |
| H1-birds-a-hero | | | | | | | |
| H1-birds-b-hero | | | | | | | |
| H1-birds-c-hero | | | | | | | |
| H1-bugs-a-hero | | | | | | | |
| H1-bugs-b-hero | | | | | | | |
| H1-bugs-c-hero | | | | | | | |
| H1-medal-a-hero | | | | | | | |
| H1-medal-b-hero | | | | | | | |
| H1-medal-c-hero | | | | | | | |

**What round 2 decides:**
- the **stability** of the cheer, the ceremony and the lesson lines (`content/voices.json`);
- whether **audio tags** are used;
- whether the two **friends' voices** sound native;
- for each H1 line, which **text form** wins (my note to the editor).
