# Listening sheet: the diagnostic audition, rounds 1, 2 and 3

Written by the voice-and-sound-director on 2026-10-29. The clips are in `round1.json` and `round2.json` next to this
file. Each spec gives every clip's exact text, model, settings and format, and the question the clip answers (`tests`).
The plan prints all of this again before anything is sent.

| Round | Clips | Characters (my count) | Cost at list prices | When |
|---|---|---|---|---|
| 1 | 34 (32 Nitzi, 2 hero-son) | **1,852**: eleven_v4_turbo 759, eleven_v4 1,093 | **0.1178 USD** | now |
| 2 | 59 (36 of them the editor's H1 A/B) | **2,774**, all on the model round 1 picks | **0.2219 USD** on eleven_v4 (0.1110 on Turbo) | after I have read your round-1 scores and updated `round2.json` |
| **3** | **40** (31 Nitzi, 7 hero-son, 1 Tzuri, 1 Tamir; 4 of the Nitzi clips repeat on eleven_v4) | **1,423**: eleven_v4_turbo 1,246, eleven_v4 177 | **0.0640 USD** | **now: this is the round to run (B-45). Rounds 1 and 2 were never run; round 3 replaces them as the check before the full voicing. Go to section E.** |

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

---

## E. Round 3 (40 clips): the check before the full voicing (B-45)

Written by the voice-and-sound-director on 2026-11-01. Spec: `round3.json` next to this file. Every text is owner-approved.
Every word the corrected sheet touched is here, in a real line of the pack, said the way the pack will send it. Nothing is
generated yet. The free plan says **40 clips, 1,423 characters, 0.0640 USD** at list prices.

**Who says what.** `N` = Nitzi (female, the flagship narrator; 27 clips on `eleven_v4_turbo` and 4 repeats on `eleven_v4`).
`H` = hero-son (male, the flagship narrator; 7 clips). `F1` = Climber Tzuri and `F2` = Tower Tamir, each saying the medal
line in his **own** voice (friends keep their own cheers and ceremonies). A friend's **lesson** lines are said by the
narrator of the same gender, so `H01` (a question) is also how Tzuri and Tamir ask a lesson line, and a girl friend would
borrow Nitzi (`N05`). Listen to `F1`, then `H01`: one man or two people?

**How the tone is set.** On every v4 model only stability and similarity are sent (the tool drops style and speed), so the
tone here is stability alone: ask 0.60, hint 1 and 2 0.65, hint 3 0.70, calm try-again 0.60, praise and bottle 0.50,
thinking 0.55, celebration 0.35, ceremony 0.45. The two clips at **0.10** (`N22`, `N24`) are today's cheer, kept to compare.
Similarity is 0.8 for all. Today's `content/voices.json` has 0.5 for everything except the cheer; your scores decide the
numbers I then put there.

### E1. Steps (Windows PowerShell 5.1; Claude never runs these)

Until round 3 is merged to `main`, use the worktree `D:\nitznutz-next` below. After the merge, use `D:\Children-Learning-App`.

1. **Open a separate PowerShell window** (Start menu, `PowerShell`, **Windows PowerShell**), not the terminal where Claude
   Code runs.
2. **Go to the app folder and let the window show Hebrew:**

   ```powershell
   cd D:\nitznutz-next\app
   [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
   ```

3. **The free plan** (sends nothing, needs no key):

   ```powershell
   dart run tool/voice_gen.dart audition-batch plan ../docs/audio/audition/round3.json
   ```

   It must end with `Clips to make: 40 of 40`, `Characters of text in total: 1423` and `Estimated cost ... 0.0640 USD`.
   Stop and tell Claude if the total differs or you see "FAILED" or "The pre-flight check refuses". (Hebrew may show in
   reverse order in the console; that is only the display.)
4. **The key, typed into a hidden prompt** (it stays only in this window):

   ```powershell
   $s = Read-Host -AsSecureString 'ElevenLabs key'
   $env:ELEVENLABS_API_KEY = [System.Net.NetworkCredential]::new('', $s).Password
   Remove-Variable s
   ```

5. **The paid run:**

   ```powershell
   dart run tool/voice_gen.dart audition-batch run ../docs/audio/audition/round3.json
   ```

   It prints the same plan and asks you to type the number of characters. **Type 1423 and press Enter** (the number printed
   as "Characters of text in total"). Anything else stops it and sends nothing. If it stops halfway, repeat this step:
   clips already made are skipped and not paid for again; type the new, smaller total.
6. **Close the key:**

   ```powershell
   Remove-Item Env:ELEVENLABS_API_KEY
   exit
   ```

7. **Where the files are, and how to play them.** Any PowerShell window; free:

   ```powershell
   explorer "$env:USERPROFILE\nitznutz-voice\auditions\round3"
   ```

   Forty `.mp3` files (`N01-oops.mp3` ...), each with a `.json` beside it (what was sent). Double-click one to play it on
   the PC. Play them in name order: F, H, then N.
8. **To the phone.** Copy only the `.mp3` files of the `round3` folder. Android: USB cable, "File transfer", drag into
   `Music`. iPhone: upload to OneDrive or iCloud Drive and play from Files. The clips hold only these test sentences,
   nothing about the children. Delete the phone copy after you answer.

### E2. How to answer from the phone

Listen to each clip **twice** (once on the phone speaker, once on headphones). Then reply to Claude in one message, one
line per clip:

`N05 ok` or `N05 W3 S5 R4 Wa5 NR4 "the question does not rise"`

- `ok` = right words, right stress, warm and natural. Anything else: scores 1 to 5 as in section B (W words, S stress,
  R rhythm, Wa warmth, NR not robotic) and two or three words about what you heard.
- For pairs, say which is better: `N21 over N22`, `N18 over N17`, `N01 v4 better`.
- A photo of the table below also works.
- A **wrong word or wrong stress** is the most important answer: write the word as you heard it ("sounded like nig-LE").

### E3. What to listen for in each clip

| Clip | Says | Listen for | W | S | R | Wa | NR | Notes |
|---|---|---|---|---|---|---|---|---|
| N01-oops | אוּפְּס, האוזניים שלי התבלבלו. אפשר להגיד שוב? | "UPS" (not "ofs"); "ha-oz-NA-yim"; a calm, curious tone; the question rises | | | | | | |
| N02-say | בבקשה, תגידו לי. | "ta-gi-DU li" (not "im-RU li"); a warm invitation | | | | | | |
| N03-discover | בואו נְגַלֶּה יחד. | "ne-ga-LE" (we will find out), not "nig-LE"; thinking, curious | | | | | | |
| N04-put | שָׂמִים כל צורה עם אותה צורה. | "sa-MIM" (we put); a clear instruction, not a scold | | | | | | |
| N05-queue | מי ראשון בַּתּוֹר? | "ba-TOR" (in the queue), not "be-TOR"; the pitch rises: a question | | | | | | |
| N06-hint1 | בואו נקשיב שוב לשאלה. | hint 1: short, slow, soft; an invitation, no sigh | | | | | | |
| N07-hint2 | נספור בַּתּוֹר מההתחלה: ראשון. | hint 2: calm; "ba-TOR"; "ri-SHON" clear | | | | | | |
| N08-hint3 | מתחילים מהדגל: ראשון. זה הראשון בַּתּוֹר. עכשיו תורכם — ללחוץ עליו. | hint 3: the slowest and steadiest; a short beat at the dash; ends warm | | | | | | |
| N09-sky | בצהריים השמש גבוהה בַּשָּׁמַיִם. עכשיו תורכם — ללחוץ על הצהריים. | "ba-sha-MA-yim" (stress MA); "ba-tza-ha-RA-yim"; a beat at the dash | | | | | | |
| N10-praise | כן, אֵלֶּה חֲמִשָּׁה כוכבים. | "E-le" (these), not "e-LA"; "cha-mi-SHA"; glad, not shouting | | | | | | |
| N11-right | צדקתם, שם יש יותר אפרוחים. | "tz'dak-TEM" (you were right), not "tza-dak-TEM"; short, glad | | | | | | |
| N12-tryagain | המקום בַּתּוֹר הוא לא כמה יש. בואו נספור מההתחלה. | a calm "try again": curious and kind, never a scold | | | | | | |
| N13-box | כן, זו התיבה — ארוכה, כמו קופסה של נעליים. | "tei-VA" and "kuf-SA", two different words; a beat at the dash | | | | | | |
| N14-cube-q | איפה הקובייה? | "ku-BI-ya" (cube), stress BI; a short question that rises | | | | | | |
| N15-cube-vs-box | בקובייה כל הצדדים ריבועים, ולתיבה יש צדדים ארוכים כמו מלבן. | "ba-ku-BI-ya", "ve-la-tei-VA", "mal-BEN"; calm, not a lecture | | | | | | |
| N16-teen | כן, שֵׁשׁ עֶשְׂרֵה ציפורים. | "shesh es-RE" (sixteen, feminine); a clear, steady number | | | | | | |
| N17-equals-plain | כן, שֵׁשׁ ועוד שְׁתַּיִם שווה שְׁמוֹנֶה. | "=" from the plain word: "sha-VE" or "SHA-ve"? numbers clear | | | | | | |
| N18-equals-pointed | the same with שָׁוֶה pointed | "sha-VE"; better than N17? If yes I add the pronunciation entry | | | | | | |
| N19-times | שְׁתַּיִם כָּפוּל שָׁלוֹשׁ שָׁוֶה שֵׁשׁ. | "ka-FUL" (times); a clean sum (a test sentence: the pack has no × line yet) | | | | | | |
| N20-cheer-count | כל הכבוד, עברתם את העשרות. | "a-va-r'TEM" (you passed); "KOL ha-ka-VOD"; glad and short at 0.35 | | | | | | |
| N21-cheer-towers-035 | כל הכבוד, המגדלים גְּדֵלִים. | "g'de-LIM" (they grow), not "g'da-LIM"; bright but even | | | | | | |
| N22-cheer-towers-010 | the same at stability 0.1 (today's cheer) | wobbly or shouted next to N21? | | | | | | |
| N23-medal-045 | הנה מֵדַלְיָה בשבילכם. | "me-DAL-ya" (stress DAL); proud and warm | | | | | | |
| N24-medal-010 | the same at 0.1 (today's ceremony) | compare with N23 | | | | | | |
| N25-bottle-land | בואו נֵצֵא להרפתקה אל גִּבְעוֹת הַסְּפִירָה. | the pointed land name flows inside the sentence; an inviting "we" | | | | | | |
| N26-bottle-land-plain | the same with the name unpointed | same as N25, or a different reading? | | | | | | |
| N27-bottle-robots | בואו נְבַקֵּר את נְמַל הָרוֹבּוֹטִים. | "ne-MAL ha-ro-bo-TIM"; stress on "bo" in robot | | | | | | |
| N01-oops-v4 | as N01 | model A/B: clearer or warmer than turbo? | | | | | | |
| N08-hint3-v4 | as N08 | the same A/B | | | | | | |
| N18-equals-pointed-v4 | as N18 | the same A/B | | | | | | |
| N23-medal-045-v4 | as N23 | the same A/B | | | | | | |
| H01-queue | מי ראשון בַּתּוֹר? | hero-son: "ba-TOR"; a natural male voice; a real question. Also Tzuri's and Tamir's lesson voice | | | | | | |
| H02-sky | as N09 | hero-son hint 3: "ba-sha-MA-yim"; calm and steady | | | | | | |
| H03-praise | as N10 | hero-son: "E-le"; glad, not shouting | | | | | | |
| H04-cube-vs-box | as N15 | hero-son "try again" with "ku-BI-ya" and "tei-VA" | | | | | | |
| H06-equals-pointed | as N18 | hero-son: "sha-VE" | | | | | | |
| H07-oops | as N01 | hero-son: "UPS"; kind, not annoyed | | | | | | |
| H08-cheer-towers | as N21 | hero-son celebration at 0.35: "g'de-LIM" | | | | | | |
| F1-tzuri-own-medal | as N23 | Tzuri's OWN voice: native Hebrew, friendly; compare with H01 (his borrowed lesson voice): one man or two? | | | | | | |
| F2-tamir-own-medal | as N23 | Tamir's OWN voice: deep, slow, gentle; compare with H01 | | | | | | |

**What round 3 decides.** (1) Each corrected word: said right, or I add a respelling to `content/voices.json` ›
`pronunciation` (`שווה` is the likely one) or ask the text editor for a punctuation change. (2) The stability per kind of
line (the numbers above). (3) `eleven_v4_turbo` or `eleven_v4` for the full run (v4 costs twice per character). (4) Whether
Tzuri and Tamir sound like the same people as the borrowed hero-son. (5) Whether land names go to the voice pointed or
plain. Only after your OK is the full voicing planned, for the number you type.
