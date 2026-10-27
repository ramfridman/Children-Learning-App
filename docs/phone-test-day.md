# Phone test day: one sitting, in order

Everything built so far that only a real phone can check, in the order that makes each step safe for the next. About 2 hours with the PC and the Samsung together. Each step says what to do, what you should see, and **what to tell me if it does not happen**. You do not need to understand the code: if a step fails, stop, write down the step number and what you saw (a photo of the screen is enough), and send it. Nothing here can damage the phone or the project.

Related lists: `docs/owner-todo.md` (everything waiting on you) and `docs/setup/android-device-checks.md` (the detailed steps this runbook points to).

## Before you start (10 minutes)

| What | How | You should see |
|---|---|---|
| The PC has the latest work | `git fetch`, then `git checkout m5-voice-in`, then `git pull` (it contains M4 and M5) | the branch name `m5-voice-in` |
| The phone is seen | USB cable, USB debugging on, `adb devices` (see device checks section 2) | the phone's id and `device` |
| The dev app is installed | device checks section 3 (build and install) | the app opens on the phone |
| Your PIN and one child exist | normal first-run setup | the child picker with one child |

If the build fails, send me the last 20 lines of the output. That is the most useful single thing.

## Part 1: the foundations (M1 to M3, 40 minutes)

Follow device checks sections 4, 6 and 7 (the parent phone, the lesson and damaged packs, what the engine concluded). In short:

| # | Step | Expected | If not, tell me |
|---|---|---|---|
| 1.1 | Sign in, enrol the phone as a parent device, run **Signed ping** | `ping: {ok: true, role: parent ...}` | the exact line it printed |
| 1.2 | Enter a wrong PIN five times in the parent area | a lock-out with a countdown, a calm screen, no crash | what the screen showed |
| 1.3 | Play the whole butterflies lesson by touch (device checks section 6A) | five steps, a praise card, a gold home button; no cross, no harsh sound anywhere | anything hard to touch, too small or confusing |
| 1.4 | Push the damaged packs and install them (section 6B) | every file is `REFUSED at <step>`, only the real starter pack is listed | which file was accepted (this one is serious) |
| 1.5 | Dev page: **Show what the engine knows about each child** (section 7) | the counting skills as `learning`, nothing about gaps unless you repeated the same mistake twice | a number that looks wrong for what you did |

## Part 2: characters and voices (M4, 30 minutes)

Follow device checks section 8. In short:

| # | Step | Expected | If not, tell me |
|---|---|---|---|
| 2.1 | Run `powershell -ExecutionPolicy Bypass -File tools\make-m4-device-packs.ps1 -Push`, then on the phone Parents > dev harness > **Install .nnpack files from the incoming folder** | 17 lines, each `installed ...` | any line that says `REFUSED` or an error |
| 2.2 | On the map, tap the small plus next to the character | Friends' Beach with nine friends, the current one in a gold frame | how many you see; which look wrong |
| 2.3 | Touch each friend | it waves and a tone plays (each a different pitch); no speech yet, these are test tones | a friend that does not move or stay silent |
| 2.4 | Choose one, go home, tap the counting hills | that friend is on the map where Nitzi stood, and is the guide in the lesson; a tone plays with each line and the mouth opens and closes | the friend's name; whether the mouth follows the tone |
| 2.5 | Leave the lesson in the middle of a tone | the sound stops at once | whether it kept playing |
| 2.6 | Finish a lesson for the first time | the friend celebrates on the card; then Friends' Beach opens once | whether it opened every time |
| 2.7 | Which friend would the children pick first? Does anything look stiff, cut off, too small or too slow? | (opinion) | your honest first reaction |

## Part 3: answering by voice (M5, 40 minutes)

Follow device checks section 9. In short:

| # | Step | Expected | If not, tell me |
|---|---|---|---|
| 3.1 | Run `powershell -ExecutionPolicy Bypass -File tools\make-m5-model.ps1 -Push` | four lines ending `ok`, then `Pushed` | any line that says it does not match |
| 3.2 | Parents > "Voice answers" > the switch; allow the microphone when Android asks | the switch stays on, no note under it | the note that appears; whether Android asked at all |
| 3.3 | Pick the child, tap the counting hills, find the teal microphone at the guide's feet | it is there, with small ears | whether it is missing (and the switch state) |
| 3.4 | **Time the first tap of the mic after opening the app.** Count seconds until the ears go up. | under about 3 seconds; the screen may pause once | the number of seconds, and whether the whole screen froze |
| 3.5 | Say "אדום" and stop | the mic shows a tick; the red flower is accepted | what happened, and what the guide said |
| 3.6 | In the counting steps say the number out loud ("שלוש", "שלושה", "שלוש פרפרים") | accepted; the tick; the lesson moves on | the number you said and the result |
| 3.7 | Say a wrong number ("ארבע") | "I heard… right?", the card glows, a tick and an "again" button; nothing counted yet | whether anything was counted before you tapped |
| 3.8 | Say nonsense twice (or stay silent twice) | first: "my ears got mixed up, say it again"; second: the cards light one by one and the mic fades; no "wrong" anywhere | whether any cross or harsh sound appeared (a serious bug) |
| 3.9 | Say "עוד פעם", "לא יודע", "די" | the question again; the welcome and the next hint; back to the map | which one did not work |
| 3.10 | While the mic is listening, press home | the mic closes (the Android microphone dot disappears) | whether the dot stayed |
| 3.11 | Turn the switch off in the parent area | the mic is gone from the lesson immediately | whether it stayed |
| 3.12 | Time from the end of your word to the tick | about 1 second | your honest feel: quick, slow, very slow |

## After the test day (10 minutes)

1. Send me a short message with: the step numbers that failed (if any), the two timing numbers (3.4 and 3.12), and your free-form remarks.
2. If everything passed, say **"M4 and M5 confirmed"** (or confirm one at a time). I will then merge them into `main` in order, with all CI jobs green, and tick them off in `docs/owner-todo.md`.
3. If something failed, I fix it on the branch before anything is merged.

## Not part of this day

- The adult speech recordings and the accuracy number: `docs/owner-todo.md` P4 (needs the PC, about 15 minutes, can be a different day).
- Real ElevenLabs voices: P3 (an hour at the PC; the test tones in Part 2 are free).
- Saving the pack signing key in 1Password: P1 (five minutes, do it first if you are at the PC anyway).
