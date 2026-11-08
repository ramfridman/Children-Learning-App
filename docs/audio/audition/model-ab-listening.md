# Listening sheet: Turbo against v4 (model A/B)

Written by the voice-and-sound-director on 2026-11-08. Spec: `docs/audio/audition/model-ab.json`. Nothing was sent or paid;
the plan below is free. Claude never runs the paid step.

| | |
|---|---|
| Clips | 44: 11 lines, each by nitzi and hero-son, each on `eleven_v4_turbo` and on `eleven_v4` |
| Characters | **1,836** (918 on each model) |
| Cost at list price | **0.1102 USD** (Turbo 0.0367 + v4 0.0734) |
| Settings | the usual (stability 0.5, similarity 0.75); the celebration uses the cheer style (0.1 / 0.8). Same text and settings for both models; only the model differs |

The number you type is the one the tool prints. If it differs from 1836, stop and tell Claude.

## A. Make the clips (Windows PowerShell 5.1)

1. Open a separate PowerShell window (not the one where Claude Code runs).
2. Go to the app folder of the checkout that has this branch (`D:\nitznutz-hebrew-sweep` until it is merged), and let the window show Hebrew:

   ```powershell
   cd D:\nitznutz-hebrew-sweep\app
   [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
   ```

3. The free plan (no key needed):

   ```powershell
   dart run tool/voice_gen.dart audition-batch plan ../docs/audio/audition/model-ab.json
   ```

   It must end with `Clips to make: 44 of 44`, `Characters of text in total: 1836` and `Estimated cost ... 0.1102 USD`.
   Stop if you see "refuses" or "FAILED".

4. The key, typed into a hidden prompt (it stays in this window only):

   ```powershell
   $s = Read-Host -AsSecureString 'ElevenLabs key'
   $env:ELEVENLABS_API_KEY = [System.Net.NetworkCredential]::new('', $s).Password
   Remove-Variable s
   ```

5. The paid run:

   ```powershell
   dart run tool/voice_gen.dart audition-batch run ../docs/audio/audition/model-ab.json
   ```

   It prints the plan again and asks you to type the number of characters: type `1836` and press Enter. Anything else stops it
   with nothing sent. If it stops halfway, repeat the same command: finished clips are not made or paid for again.

6. Close the window, or clear the key: `Remove-Item Env:\ELEVENLABS_API_KEY`.

## B. Where the files are, and how to play them side by side

They land in `C:\Users\ramfr\nitznutz-voice\auditions\model-ab`, each as `<id>.mp3` with `<id>.json` beside it.
The names sort in pairs, one voice at a time:

```
01-hero-turbo.mp3   01-hero-v4.mp3   01-nitzi-turbo.mp3   01-nitzi-v4.mp3
02-hero-turbo.mp3   ...
```

```powershell
explorer C:\Users\ramfr\nitznutz-voice\auditions\model-ab
```

Sort by name and play the two files of a pair one after the other (Media Player, or select both and press Enter), with the
same volume. Listen to **nitzi** first (all 11 pairs), then hero-son. Use the same headphones or speaker you use for the app.
Do not look at which is which after the first pass; the file name tells you, so cover the name column if you can.

## C. What to compare (score each pair: A = Turbo better, B = v4 better, = no difference)

| # | Line | Listen for |
|---|---|---|
| 01 | prompt with numbers | the number words in the right gender; an even rhythm; a clear pause at the comma and at the full stop; no stress on the last number |
| 02 | hint with a dash | `—` is a short beat, not a stop; `ננסה` is "nenase" |
| 03 | `שמעתי… נכון?` | the ellipsis is a soft beat; the question rises gently |
| 04 | praise | warm and short, not flat; `סִפְרָה` is "sifra" (a digit) |
| 05 | celebration (cheer) | bright and short, never shouting; no distortion at stability 0.1 |
| 06 | the name Pip | `לְפִיפּ` is "lepip" with a p, not "lefif"; the instruction verbs `הַקְשִׁיבוּ`, `וְגִרְרוּ` are the commands |
| 07 | maths: `שווה` | "shave"; the colon is a small pause; `בִּשְׁנֵי` clear |
| 08 | maths: `כָּפוּל`, `שָׁוֶה` | "kafúl" and "shavé"; the sum reads as one sentence. (A draft line for this test; no app line says it yet.) |
| 09 | long Band C hint | calm pace over three sentences; pauses between them; `גָּדֵל` "gadel"; `תורכם` "torkhem" (this word is in 786 lines) |
| 10 | risky words | `נֹאמַר` "nomar" (not "ne'emar"); `וְנִמְחָא` "venimcha" |
| 11 | risky word | `סְפָרוֹת` "sfarot" (digits), not "sifrut" |

Across all pairs mark: **naturalness** (does it sound like a kind person talking to a child, or like a reader?), **stress**
(on the right syllable, no odd stress on a number), **pronunciation of the risky words** (01, 04, 06, 09, 10, 11), **pacing at the
dash and the ellipsis** (02, 03), **clean start and end** (no click, no clipped word), and **the same voice** (does v4 still sound
like nitzi / hero-son, or like a different person?).

A parent-facing line is not in the set: no parent line is voiced in the app.

## D. Score sheet (write it in the chat, or tell Claude the pairs)

```
01 nitzi: A / B / =   hero: A / B / =
02 ...
Overall: Turbo / v4 / no difference worth double the price
Reasons (a few words):
```

How to decide: v4 costs twice (the full Hebrew run is 14.96 USD on Turbo against 29.93 USD on v4, `release-voicing-plan.md` section 1.5).
If v4 is clearly better on the risky words (06, 09, 10, 11) or on naturalness in most pairs, the 15 USD extra is worth it. If most
pairs are "=" or Turbo wins on the voice's identity, keep Turbo.
