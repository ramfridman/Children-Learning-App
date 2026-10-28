# Phone check for M9 (`m9-content`, pack 0.8.0): board item B-10

One sitting with the PC and the Samsung. It takes about 60 to 90 minutes. Each step says what to tap, what you should see, and what to tell us if you see something else. If a step fails, write down its number and what you saw (a photo of the screen is enough), then go on to the next step. Nothing here can damage the phone or the project. Written by the QA agent on 2026-10-28, from QA's baseline (`docs/qa/m9-baseline.md`).

**What to look for everywhere:** anything too small for a child's finger, cut off, overlapping, upside down or mirrored. Maths, number lines, clocks and robot arrows must never be mirrored. Watch for a "wrong" feeling (a cross, a harsh sound, red text), a step with no way forward, or a sound that is cut off.

**Ages.** Use one child profile in **Band B (5 to 6)**. Most of the new lessons are Band B.

## 0. Before you start (10 minutes)

| # | Do this | You should see | If not, tell us |
|---|---|---|---|
| 0.1 | In PowerShell: `cd D:\Children-Learning-App`, then `git fetch`, then `git checkout m9-content`, then `git pull` | the branch name `m9-content` | the last lines it printed |
| 0.2 | Plug in the phone and run `$env:Path += ";$env:LOCALAPPDATA\Android\Sdk\platform-tools"`, then `adb devices` | one line that ends in `device` | `unauthorized`, or no line at all |
| 0.3 | `cd app`, then `flutter pub get`, then `flutter run --flavor dev --dart-define-from-file=config/dev.local.json -d <the phone's id>` (the steps in `docs/setup/android-device-checks.md` section 3) | "Nitznutz Dev" opens on the phone | the last 20 lines of the output |
| 0.4 | Parents (PIN) > dev harness: look at the list of installed packs | `starter 0.8.0` is the active starter pack | the version you see |

Leave PowerShell open: it shows the app's log, and we may ask for it.

## 1. The main flows (20 minutes)

| # | Do this | You should see | If not, tell us |
|---|---|---|---|
| 1.1 | Pick the child. The map opens. | six islands, each with a play button and a label; the companion stands on the map | an island with no label or no play button |
| 1.2 | Tap each island once, then go back (the palm button, top right) | each island opens and closes; nothing freezes | which island did not open |
| 1.3 | On Counting Hills, tap the play button | a lesson opens; the question is spoken and written in a bubble; the progress dots are at the top | silence, or a bubble with no nikud |
| 1.4 | Answer one question wrongly on purpose | a gentle "not yet" (no cross, no harsh sound); the guide says what to look at | anything that feels like "wrong" |
| 1.5 | Answer the same question wrongly two more times | the help goes up each time; after the third mistake the help shows the way and only the right answer is taken | a dead end, or the same help said three times |
| 1.6 | Tap the lamp (help) and the eye ("show me") on a new question | the lamp gives the next help; the eye is welcomed (never "wrong") | what was said |
| 1.7 | **Answer a question right, and tap the eye at once, while the praise is still being said** | today: the praise is cut off and the "I'm not sure" line is said (known defect **QA-5**) | whether it happened (this confirms QA-5 on the phone) |
| 1.8 | Tap the guide (the character) | the question is said again | silence |
| 1.9 | Play a lesson to the end | the celebration card with the character, perhaps a sticker, and a gold home button | no card, or a card that cannot be closed |
| 1.10 | Press home in the middle of a lesson, while the guide is talking | the voice stops at once and the map comes back | a voice that keeps talking |
| 1.11 | Turn the phone round (the other landscape side) during a lesson | the lesson stays where it was; nothing is mirrored; nothing jumps | anything that moved or restarted |

## 2. The new templates

**How to reach them.** Today the island's play button always opens the next unfinished lesson of that island's path, and the new lessons are far along it: number lines are lessons 35 to 37 of Counting Hills, tracing is 44 to 47, the coins, the shop, the chart and the clock are lessons 33 to 40 of Market Village, tracing shapes is 23 and 24 of Shape Forest. There is no shortcut on the phone yet. QA has asked the developer for a dev-page button "open a lesson" (dev flavour only). **When that button exists**, use it for each step below. Until then, do part 2 only for the lessons you reach by playing.

For every template, also check: the help after three mistakes shows the way; nothing is too small to touch; the screen looks right (nothing cut off, nothing over the edge).

| # | Lesson (id) | Do this | You should see | If not, tell us |
|---|---|---|---|---|
| 2.1 | Number line, place (`frog-line-10`) | Read the question ("the frog wants to stand on three"). Tap 5, then 7, then 3 | today **the frog is not on the screen** (known defect **QA-6**); a tap on a number is the answer; 7 gets its own "read the line from the left" line; 3 is right | whether you see the frog; whether a tap ever lands on the number next to the one you meant |
| 2.2 | Number line to 20 (`frog-line-20`) | Tap each number from 0 to 20 in turn with a fingertip, slowly, then a little faster | the tick you touch is the one that lights | how often the neighbouring number was taken (the ticks are only about 14 points apart, **QA-9**) |
| 2.3 | Frog jumps (`frog-jumps`) | Watch the frog, then tap where it lands | the frog hops; the line reads 0 on the left | a mirrored line |
| 2.4 | Balance, which side is heavier (`equals-balance`) | Look at the pans before you answer | today the pictures on the pans are tiny (**QA-7**) and the beam is level before the answer (**QA-8**) | whether you can count what is on each pan; whether a child would answer "the same" because the beam looks level |
| 2.5 | Balance, add blocks (`balance-it`) | Tap plus until the scale is level; also tap minus once | each plus adds a block, minus takes one away; level is right | a block that does not appear |
| 2.6 | Spot the mistake (`count-order`, `find-the-slip`) | Tap a cell that is right, then the mistake | a gentle "not yet", then praise | a cell that is hard to hit |
| 2.7 | Match numbers and sets (`match-numbers-sets`) | Tap a numeral, then a set; make one wrong pair, then all the right ones | today **one apple is drawn big and the sets of two and three are tiny** (**QA-3**); a right pair keeps a number and a colour | whether a child can count the small apples |
| 2.8 | Match coins (`know-the-coins`) | Match each coin to its number | coins look like real Israeli coins; a right pair keeps its colour | a coin that does not look real |
| 2.9 | Shop and pay (`pay-exactly`, 2nd question: five shekels) | Put **every** coin of the purse on the counter | today some coins disappear below the counter (**QA-4**) | how many coins you can still see on the counter |
| 2.10 | Shop and pay | Take a coin back from the counter by tapping it; then pay exactly | it goes back to the purse; exact payment is right | a coin that cannot be taken back |
| 2.11 | Read the chart (`read-the-chart`) | Look at the columns before answering | the pictures in each column can be told apart | whether the apples and the red balls look the same (**QA-12**); whether a child expects the answer under its column |
| 2.12 | Set the clock (`set-the-clock`) | First tap the tick **without moving anything** | today this is recorded as "reads the long hand as the hour" (**QA-11**); then use plus or drag the short hand to 3 and tick | whether the short hand follows your finger; whether you can tell the two hands apart at twelve |
| 2.13 | Trace a numeral (`trace-numbers-0-4`) | Trace the 1 with a finger from the green dot, at a normal speed; then once from the bottom up | from the dot: right; from the bottom: the "start at the dot" line | **how many tries a right trace needs** (QA-2 says the touch is read a little off towards the top left; the box is only about 122 points) |
| 2.14 | Trace a numeral with two strokes (`trace-numbers-0-4`, the 4) | Trace the first stroke right, then make the second stroke wrong | today the first, right stroke is wiped too (**QA-13**) | whether that would upset a child |
| 2.15 | Write from the dot (`write-from-the-dot-0-4`) | Write the 1 from the dot with no dotted guide | right when written from the dot; after three tries the whole path is shown and a dot walks along it | whether a 5-year-old would know what to draw |
| 2.16 | Trace shapes (`trace-the-shapes`) | Trace the circle and the square | right when the finger follows the line | how many tries it takes |
| 2.17 | Build with shapes (`build-with-shapes`, the rocket) | Put the fins in place by touch, then by dragging | the shape snaps in; a wrong place is a "not yet" | whether you can hit the fins and the door (about 15 points wide on the phone, **QA-9**) |

## 3. What to send back

1. The step numbers that failed, each with a photo or one line on what you saw.
2. Your honest view for 2.2, 2.4, 2.7, 2.13 and 2.17: too small, fine, or good.
3. If anything crashed: `adb logcat -d -s flutter > crash.txt` in PowerShell, and send `crash.txt`.

QA re-runs the failing tests after each fix and updates `docs/qa/m9-baseline.md`.
