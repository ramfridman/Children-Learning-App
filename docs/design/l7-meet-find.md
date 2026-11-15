# L7-4: the Meet screen and the Find wrong tap, design spec

Owner: design-director. Date: 2026-11-12. Status: **spec for the app-developer** (step L7-4 (c) and (d) of `docs/milestones/L7.md`, approved by the owner on 2026-11-12). Three points need the curriculum-expert's yes before they are built as written (section 11); each has a fallback that can be built now.

Built on: `docs/milestones/L7.md` §2, §3 and the L7-4 row; `docs/languages/band-a-build.md` §2.6 (teach screens, routes, the hearing screen) and §7.2 (D1, no target text in Band A); `docs/languages/frame.md` §2.3 (LS09), §3.1, §3.3.6; `docs/languages/fonts.md` §6; `docs/design/languages-l5-ls01.md` (zones, states, sizes); `docs/design/b29-steps5-6.md` §3 (the three looks, captions); `docs/design/b40-visual-hints.md` (the hint grammar); `design/tokens.json`; the code in `app/lib/play/` (`say_it_session.dart`, `tap_answer_session.dart`, `choice_session.dart`, `lesson_controller.dart`, `activity_frame.dart`, `idle_ladder.dart`, `option_faces.dart`); the goldens `qa_l3_say_*`, `pilot_*_first_*` and `lesson_mistake_double_phone.png`.

Mockups (`docs/design/l7/make_l7_mockups.py`: each board at its real size in points with the app's pictures and fonts, shown at half size by headless Chrome; red labels and dashed zones are for the team only; every Hebrew line and word on them is a sample):

| File | What it shows |
|---|---|
| `docs/design/l7/meet_phones.png` | Meet on the phone (English, look A, word 2 of 2, the child's turn, captions hidden) and the phone SE (Russian, look B, word 3 of 3, the Hebrew meaning in the bubble) |
| `docs/design/l7/meet_tablets.png` | the Hebrew course's Meet page on the tablet landscape (story 1 page 1, the bush ringed, the explanation) and Meet on the tablet portrait (English, look C, letters open, "let's say it together" with the word's chip, the picture speaking) |
| `docs/design/l7/find_wrong_tap.png` | Find on the phone, 2 choices: asked, wrong tap (the picture speaks), settle and "and where is …?", right; 3 choices, wrong tap; the SE, 2 choices, wrong tap |

---

## 1. The spec in one page

1. **One rule for every picture in a language lesson: a picture says its own word when it is touched**, and while it speaks it shows the **speaking state** (a sound badge at its top start corner and one soft breath). Meet, the Meet strip and Find all use it, so a child learns one thing: touch a picture to hear its name.
2. **The Meet screen is one big picture and nothing to choose.** No lamp, no "show me", no answers, no right or wrong. The beats are voice-paced: the word, the Hebrew meaning (English and Russian) or one explaining sentence (Hebrew), the word again, "let's say it together" and the word, then the child's turn.
3. **The way on is the "I said it" tile, or the microphone**, and both arrive only at "let's say it together". After the tap (or the child is heard) the screen closes by itself. **Touching the picture replays the word and never moves on.**
4. **A Meet set (2 or 3 words) is one moment**: the frame does not change between its screens, each met word steps into a small **strip** at the side (and still says its word when touched), the next picture grows in its place, the set takes **one socket** of the progress trail, and there is no praise between words.
5. **The written word**: never in look A (ages 3 to 4). In looks B and C only when the child's letters gate in that course is open (L7-8), as a chip under the bubble's line from the third beat on. **The Hebrew meaning is heard**, and shown as the bubble's caption only when captions are on (look B and C by default); it is never on the picture and never stays after its beat.
6. **Find, wrong tap**: the tapped picture speaks its word (no wobble, no red, nothing taken away), then settles with a lilac ring that fades, then the guide asks "and where is …?" with the target. The question is then that line (the replay button says it). Two and three choices behave alike; the ladder after it is the existing one.
7. **The phones get bigger pictures**: the Meet picture is 260 points on the phone (today's teach picture is about 105), and a Find's pictures stand on a stage that takes the phone's whole left column (166 points for 2 choices, where the pilot goldens show 66 to 95).

---

## 2. The speaking state (shared by Meet and Find)

| | Picture card (Meet) | Strip thumbnail | Stage picture (Find) |
|---|---|---|---|
| Badge | disc 40 (phones) / 48 (tablets), `skyTint` fill, `hairline` 2 rim, `e1` shadow, the ink speaker with its waves (`Icons.volume_up_rounded`, 24 / 28) | disc 28, icon 18 | disc 40 / 48 |
| Where | centred on the card's **top start corner** (top right; it is interface chrome, so it follows the interface, in every course), 10 inside the corner so it overlaps it | the same corner | at the picture's top start, on the circle's edge |
| With it | the picture breathes once, scale 1.00 to 1.03 to 1.00 over the word (at most 600 ms) | nothing else | the chosen ring (5 pt `selectedRing`, `mist` wash), lifted 6, the breath 1.04 |
| Timing | the badge fades in 120 ms as the word starts and out 220 ms after it ends | | |
| Reduce motion | the badge only, no breath | | the badge and the ring, no breath, no lift |

- It is **not a button** (no hit area of its own); it is the same disc as `SpeakerMark`, so the child already knows it means sound. The **check badge** of a right answer stays at the top **end** corner, so the two never meet.
- **Which beat counts as "the word"**: the badge should follow the word's clip (the line's target clip). If the voice director cannot tell the app when the target clip of a line starts, the badge shows for the whole line that carries the word (M1, M3, M4), never for the meaning line (M2, H2).
- A clip that is still pending (not voiced yet) shows the badge for the existing pending pause.

---

## 3. The Meet screen (English and Russian)

### 3.1 The beats

Every line waits for the one before it to end (`untilQuiet`), then a **breath of 400 ms** (looks A), 300 (B) or 250 (C) before the next. Nothing is timed for the child.

| Beat | Voice (texts: hebrew-text-editor) | Bubble (captions on: looks B, C) | Picture | Guide (`CharacterState`) | The child's controls |
|---|---|---|---|---|---|
| **M0 opener**, first screen of a set only | the course's Meet opener (English: the new clip of L7 §5; Russian: the teacher's line) | its caption | the card grows in (section 7) | `wave`, then `talk` | none |
| **M1 hear** | the Meet carrier (proposal: f41 "הַקְשִׁיבוּ:"), then the word | the carrier's caption | **speaking** on the word | `talk` | none |
| **M2 meaning** | "בְּעִבְרִית:" and the Hebrew word (`gloss`) | "בְּעִבְרִית: שָׁלוֹם." | rests | `talk` | none |
| **M3 again** | the word | the M1 caption again (not voiced again); the **chip** appears here when shown (3.2) | **speaking** | `talk` | none |
| **M4 together** | f03 "בּוֹאוּ נֹאמַר יַחַד" and the word | f03's caption, the chip | **speaking** on the word | `talk` | "I said it" and the microphone (if on) **fade in** as the line starts |
| **M5 your turn** | 3.2 s after M4 ends (`SayItSession.listenPause`), the word once more, unless the child has acted | f03 kept | rests; a touch **replays** the word | `listen` | "I said it", the microphone |
| **M6 close** | heard by the microphone: the existing `heard` line (it names the word); unsure: the existing `together` line; "I said it": **no line** | the line, or nothing new | the rim goes `spark` 4 for 400 ms, then the hand-over (section 7) | `encourage` | gone |

- **Heard 4 to 5 times** on one screen (M1, M3, M4, M5, and the close when heard), plus every touch. The Hebrew meaning **exactly once** (L7 §6 criterion 2): the replay button and a touch on the picture never say M2.
- **The Hebrew course and the heritage child**: section 5 and `band-a-build.md` §2.6.1 R3 (a hearing screen stays as built).

### 3.2 The written word, by look

| | Look A (P1, P2; 3 to 4) | Look B (P3; 5 to 6) | Look C (P4; 7 to 8) |
|---|---|---|---|
| Letters gate of the course closed for this child (L7-8) | no text | no text | no text |
| Gate open (by level at any age, by age, or "letters together with words") | **no text** (the look is for non-readers; a 3-year-old reader is shown look B or C by the parent's choice) | the chip from M3 | the chip from M3 |

- **The chip** is the frame's `TargetChip` under the bubble's line (Nitznutz Letters 500 at 1.1 times the bubble's size, `Locale('ru')` for Russian, stress marks by the parent's setting, `showsStress`), never on the picture: the picture stays a picture, and the word stays a thing heard first. It shows from M3, after the child has heard the word and its meaning, so it never turns the screen into a reading test.
- **With captions hidden** (the speaker bubble), the chip still shows under the speaker when the rule says so (the frame already does this).
- **D1 (`band-a-build.md` §7.2) forbids any target text on a Band A skill.** Most Meet screens are Band A skills, so as D1 stands the chip shows only on Meet screens of Band B and C skills. I recommend amending D1 for the Meet screen only: a child whose letters gate is open is by definition decoding that script (orthographic facilitation, the reason D1 gives, then applies). **Needs the curriculum-expert (section 11, C1).** Build: one pure function `meetShowsWord({look, lettersOpen, skillBand, course, captionsShown})`, with the D1 rule now and the amendment as one changed line.

### 3.3 The Hebrew meaning

- **Voice**, said once at M2, by the Hebrew voice of the course.
- **On screen**, only as the bubble's caption, under the existing captions setting (hidden by default at gan3 and gan4). It is a caption like every other: it never gets a chip, never sits on the picture, and is replaced at M3. Keeping it up would invite the child to wait for the translation; the picture is the meaning.

### 3.4 How the screen says "this is not a question"

1. **One picture, large, and nothing to choose**: no tiles, no lamp, no "show me" (the screen is unscored, `noHelp` already hides them).
2. **The guide presents**: `talk` while the beats play, `listen` only at the child's turn.
3. **Nothing can be wrong**: no "not yet" state exists on this screen; a touch at any time does something kind (section 3.5).
4. **No praise between words** (a word was not "solved"); one warm line at the end of the set is the Find's opener, not a reward.
5. The routine repeats in the same order every time, so by the second lesson the child knows the shape.

### 3.5 Touches

| Touch | During M0 to M4 | From M5 |
|---|---|---|
| The picture | a squish (`pressScale` 0.94, 120 ms), **no sound** (the beats are not cut, and M2 is never lost) | the word again (`replace`), speaking state; the idle count starts over; **never moves on, writes nothing** |
| A strip thumbnail | squish | its own word, its own speaking badge |
| The bubble or speaker bubble (replay) | nothing | the word (the existing `onReplay`) |
| "I said it" | (shown from M4) a tap during M4 lets the word finish, then M6 | M6 |
| The microphone | (shown from M4) the existing say step | the existing say step; heard or unsure leads to M6 |

### 3.6 Idle (the existing ladder, B-29 D5)

- **First and second prompt**: the guide says the M4 line again ("let's say it together" and the word) and the "I said it" tile breathes once (scale 1.06, 600 ms; reduce motion: its rim goes `sky` 4 for 600 ms). **No hand**: a hand pointing at the picture would teach "touch the picture to go on".
- **Offer**: skipped (there is no "not sure" on an unscored screen). **Soft pause**: as today.

---

## 4. Layout

### 4.1 The Meet board (a new variant, `withMeetStage(base, look, wide:)` next to `withTallStage` in `choice_row.dart`)

All values are board points. The frame's pieces (controls, trail, bubble, guide, microphone) do not move.

| Board | Stage S (x, y, w, h) | Strip column (end side, left) | Picture area | Picture card | "I said it" box (x, y, w) |
|---|---|---|---|---|---|
| **Phone** 852 x 393 | 24, 96, 377, 260 | x 24, 64 wide (look A) or 56 (B, C), gap 12 | x 100 to 401 (A) | **260 square** | 413, 256, 192: under the bubble, beside the microphone |
| **Phone SE** 667 x 375 | 24, 86, 264, 256 | x 24, 64 / 56, gap 8 | x 96 to 288 (A) | **192** (A), **200** (B, C) | 300, 238, 208 |
| **Tablet landscape** 1180 x 820 | the white card 288, 230, 584, 300 (as today), 16 inside | x 304, 88, gap 16 | x 408 to 856, 268 high | **268 square** (448 x 262 wide) | the answer zone 194, 566, 772, the tile centred |
| **Tablet portrait** 820 x 1180 | the white card 24, 372, 772, **420** (120 taller than other templates: it holds one picture and nothing else), 16 inside | x 40, 88, gap 16 | x 144 to 780, 388 high | **388 square** (636 x 358 wide) | 24, 816, 772, the tile centred |

- **The picture card**: `paper`, radius `xl` 28, a 2 pt `cardLip` rim, the clay lip 6 and `e2`, 12 inside; the picture in its own aspect (`BoxFit.contain`), never stretched or cropped. Square side = min(area width, S height, 420). A wide picture (16:9, the Hebrew story pages, 384 x 216): width = min(area width, (S height − 24) x 16/9 + 24).
- **The strip column is always kept**, even empty on the first screen, so the card does not jump between the screens of a set. It holds the words met **earlier in this set** (1 or 2; a set never has more than 3), top to bottom in the order met, centred in S, gap 12. Thumbnail: `paper`, radius `md` 16, `hairline` 2, lip 4, the picture 6 inside.
- **A wide picture on a phone has no strip** (it would leave a 119-point picture on the SE): the card takes the whole S width (phone 377 x 223, SE 264 x 160). The set still reads as one moment through the frame and the single trail socket.
- **"I said it"**: `AnswerTile`, width **184** on the phones and **200** on the tablets, the look's tile height (P1, P2 96 / 112; P3 88 / 104; P4 80 / 96). Face: the glyph `Icons.record_voice_over_rounded` (32 / 36, `ink`) at the start, gap 8, then "אָמַרְתִּי" in Heebo 600 at 28 / 32. The glyph tells a child who cannot read what the tile is about. The same face is used on every LS09 step (say_it), so it is one tile everywhere. On the phone its hit area (slop 16 in look A) runs from 240 to 368, clear of the bottom band at 369 and of the microphone at x 661; on the SE from 222 to 350.
- **Why the tile moves under the bubble on the phones**: the picture takes the stage column from top to bottom, and the bubble, the guide, the microphone and "I said it" become one "talking corner" on the start side. On the tablets the answer zone has the room, as today.
- **The bubble** keeps clear of the tile by the frame's own rule (`tilesTop` of this board): on the phone it may grow down to about 240, which holds the longest gloss line (two lines at 26) with a chip.

### 4.2 What changes per look

| | Look A | Look B | Look C |
|---|---|---|---|
| Strip thumbnail, phones / tablets | 64 / 88 | 56 / 88 | 56 / 88 |
| "I said it" height, phones / tablets | 96 / 112 | 88 / 104 | 80 / 96 |
| Breath between beats | 400 ms | 300 | 250 |
| Card arrival and hand-over (`stage.P*.transition`) | 450 ms, overshoot 1.12 | 350, 1.08 | 280, 1.04 |
| Idle prompts (`idleS`) | 8, 15 s | 12, 25 | 20, 40 |
| Bubble | the speaker bubble by default (captions hidden at gan3, gan4) | captions | captions |
| The written word | never | 3.2 | 3.2 |

---

## 5. The Hebrew course's Meet page

The same screen, the same board and the same way on, so a child who learns two courses meets one routine.

| Beat | Voice | Bubble | Picture |
|---|---|---|---|
| H0 opener (first of a set) | the Hebrew teacher's line | its caption | grows in |
| **H1 hear** | the carrier and the word | the carrier | **speaking** on the word; the focus ring appears |
| **H2 explain** | one short sentence that explains the word (Biemiller and Boote 2006), at most about 8 words, ideally holding the word itself | the sentence (captions on) | rests, the ring stays |
| **H3 together** | f03 and the word | f03; the chip by 3.2 | **speaking**; "I said it" and the microphone fade in |
| H4 your turn, H5 close | as M5, M6 | | |

- **The word is heard twice as a word** (H1, H3), as the plan asks, plus inside the sentence. H3 is the plan's second hearing, carried by "let's say it together" so the way on is the same tile as in the other courses. **Needs the curriculum-expert and the Hebrew teacher (C2)**; fallback: H3 is the word alone, there is no tile, and the page goes on by itself 1.5 s after H3 (a touch on the picture replays the word, as on a hearing screen).
- **The story picture** is a story page (384 x 216) or an object picture (256 x 256); the card takes either aspect (4.1).
- **The focus ring** (a story page only, optional): the part the word names, `focus: [x, y, w, h]` in fractions of the picture, drawn as a 4 pt `spark` rounded rectangle (radius 18) on the picture, from H1 to the close; it fades in 220 ms (reduce motion: appears). No scrim and no dimming of the rest of the scene: the story stays whole. `spark`, not `sky`: sky is the hint colour, and here nothing is a hint. Without `focus` no ring (the word names the whole picture). Example in `meet_tablets.png`: שִׂיחַ on story 1 page 1, `focus` 0.67, 0.50, 0.32, 0.38.
- **The written word** is Hebrew course text (`CourseText`, Heebo 500, nikud, line height 1.7) in the chip, by the rule of 3.2 with the Hebrew letters gate (`heb.letters`, L7-8), and only when captions are shown.

---

## 6. Find: the wrong tap

### 6.1 For which items

Every scored picture choice of a language course whose options are pictures on the stage (the `tap` recipe): Find, Recall and later checks alike, so a picture always says its word (L7 §6 criterion 5). Text tiles keep their speakers (LS01 §7.1); sound buttons are unchanged.

### 6.2 The timeline (2 and 3 choices)

| Step | When | What the child sees | What the child hears | Touches |
|---|---|---|---|---|
| 1 Touch | touch-down, within 50 ms | the picture is chosen: lifted 6, a 5 pt `selectedRing` ring, `mist` wash (not lilac yet: the app does not judge before it has spoken) | | |
| 2 **Speaking** | from the start of the tapped word to its end + 150 ms (at most 1.5 s) | the speaking badge, one breath | **the tapped picture's own word** | not taken (the child's own word is never cut) |
| 3 Settle | 600 ms | the ring and wash turn `notYetRing` (lilac, 22% wash) and fade to nothing; the picture drops back. **No wobble.** Every picture stays where it was; none is dimmed or removed | | taken from here |
| 4 **Ask** | right after the word | the bubble: the "and where is …?" line (captions on), or the speaker bubble; guide `talk`, then `listen` | "וְאֵיפֹה …?" and the **target** | taken; a right tap cuts the line |
| 5 The question again | | the tiles at rest | the replay button now says the step 4 line (`askedLine`) | |

- **The first wrong tap of an item** uses the "and where is" carrier (one new line, L7-7). **A later wrong tap** says the tapped word (step 2), then the line of the hint level the existing ladder reaches (its line names the target, as the teachers wrote them).
- **Two choices**: the second wrong tap leads, after step 2, to the existing level 3 (guided: the hand, the halo on the answer after it, only the right picture taken). **Three choices**: the second wrong tap brings level 2, the third level 3, as today.
- **No hint picture with the first wrong tap** of a language picture choice: "and where is …?" is the first help, and a level 1 or 2 picture at the same moment would split a 3-year-old's attention between three things. This is an exception to B-40 A6 ("the first mistake already shows the second help" for two choices). **Needs the curriculum-expert (C3)**; fallback: the existing ladder with the first wrong tap, drawn after step 4 (never during step 2).
- **A right tap** says its word with the speaking badge, then the existing correct state (gold ring and wash, the check at the top end, the praise). On a right first tap nothing else changes.
- Nothing here says "no", "wrong" or "try again", and nothing is taken from the child. In the introduction visit nothing is written either (L7-3); the screen looks the same in every visit, so the child never meets a "test" look.

### 6.3 Colour, shape and sound

The not-yet cue is the voice (the tapped word, then "and where is"), the lift dropping back, and the lilac fading: never colour alone, and no motion that reads as a shake. Under reduce motion: the badge, the ring and the lilac fade only. With the sound off (the parent's choice), the lilac fade and the drop are the cue, as the reduce-motion not-yet is today.

### 6.4 The Find stage on the phones (a layout constant change)

A picture choice with no answer tiles today draws its pictures in the phone's stage of 330 x 128 (the pilot goldens: 66 to 95 points), and the answer zone under it is empty. Give such an item the whole start column: **phone x 24 to 401, y 96 to 349; SE x 24 to 288, y 86 to 331** (`withTallStage` with the L5 left edge of 24).

| | Picture side | Gap (twice the look's hit slop) |
|---|---|---|
| Phone, 2 choices | **166** (was about 95) | 32 |
| Phone, 3 choices | 100 to 105 | 32 (A) / 24 (B, C) |
| SE, 2 choices | **110** | 32 |
| SE, 3 choices | **two rows, 2 then 1**, about 106 (one row would be 62) | 32 |
| Tablets | unchanged (the card) | |

The row keeps the course's direction (English and Russian: first at the left; Hebrew: first at the right). The two rows of the SE: the first two options in the top row in that direction, the third centred under them (`TapGeometry.rowLinesOf` already lays out two lines).

---

## 7. Motion (agreed timings go to the voice-and-sound-director)

| Moment | Motion | Duration and easing | Reduce motion |
|---|---|---|---|
| The first card of a set arrives | scale 0.92 to 1 and fade in | `transition` of the look, `springOut` | fade 120 ms |
| **Hand-over** to the next word | the card shrinks into its strip slot (it becomes the thumbnail), then the next card grows in at the card's place | the look's `transition` each, `standard`, then `springOut` | the thumbnail appears, the card cross-fades 120 ms |
| Between two Meet screens of one set | **no screen transition**: the frame, the bubble, the guide and the trail stay; only the card moves | | |
| The last close of a set, then Find | the lesson's normal activity transition | as today | as today |
| Speaking | the badge and one breath (section 2) | | the badge |
| "I said it" and the microphone arrive (M4) | fade in and rise 8 | 220 ms (`base`), `standard` | fade 120 ms |
| Close (M6) | the card's rim `spark` 4 for 400 ms; the guide `encourage` | | the rim only |
| Focus ring (Hebrew) | fade in | 220 ms | appears |
| Find settle | the lilac fade, the drop | 600 ms | the lilac fade |

No sound sting on a Meet close (the voice-and-sound-director decides whether a soft one belongs at the end of a set); nothing flashes faster than 3 Hz.

---

## 8. Direction and fonts

- The interface is right to left: the strip at the end side (left), the badge at the top start (right), the glyph at the start of "I said it", the bubble and the guide as today.
- The strip is a column, top to bottom: it has no reading direction, so it is the same in every course.
- English and Russian words are left-to-right isolated runs in the chip (`TargetText`, Nitznutz Letters), never inline with Hebrew; Hebrew words of the Hebrew course are `CourseText`. No picture is mirrored. A Find row follows its course's direction (F1).
- Fonts: Heebo (interface, Hebrew), Nitznutz Letters (English and Russian lesson text, approved in `fonts.md`); Secular One is not used here. Every pointed line keeps line height 1.7.

---

## 9. What is reused and what is new

| Reused as is | Changed | New |
|---|---|---|
| `SayItSession` echo, the say step and microphone states, `listenPause`, `untilQuiet`, the `heard` and `together` lines | the teach screen (`answer.teach`, not `hear`): a picture tap replays instead of going on; "I said it" and the microphone come at M4; M6 closes by itself | the beats M0 to M4 / H0 to H3 (a line sequence per screen) |
| `TargetChip` in the bubble, `showsStress`, captions and the speaker bubble | the "I said it" face gets its glyph (every LS09 step) | `withMeetStage` (4.1) |
| `AnswerTile`, `SpeakerMark`'s disc as the badge, `CharacterState` poses | the trail counts a run of Meet screens of one set as **one** socket | the speaking badge widget (`SpeakingBadge`) and state |
| the idle ladder | the idle prompt on Meet: no hand, the tile breathes | the strip of met words |
| the hint ladder, the guided state, `askedLine` | the picture options of a language choice: the speaking state, then lilac fade, no wobble | the "and where is" step (first wrong tap) |
| the hearing screen (heritage), unchanged | the phones' Find stage (6.4) | the Hebrew focus ring |

---

## 10. For the app-developer (what is not obvious)

1. **The data a Meet screen needs** (from the generator, L7-4 (c)): the word clip; `gloss` (clip and caption, English and Russian) or `explain` (clip and caption, Hebrew); whether it is the **first of its set** (it plays the opener) and the ids of the **earlier words of its set** (for the strip, with their pictures and clips); optional `focus` (Hebrew story page). A set is a run of consecutive teach screens with the same `before`.
2. **The picture tap has two meanings in LS09 now**: on a Meet (teach) screen it replays; on a say step of the Use part it still goes on and may be a scored listening answer. Keep them apart by `answer.teach`, and do not let a Meet picture call `sayItDone`.
3. **M2 must never be replayed**: the replay button, the idle prompt and a picture touch say the word or the M4 line, never the meaning. A test counts the gloss clip once per screen (L7 §6 criterion 2).
4. **No cut beats**: during M0 to M4 touches give the squish only; nothing replaces a playing line. From M5 on a touch replaces (`replace: true`).
5. **The close** after "I said it" says nothing and waits only for the rim (400 ms) and the hand-over; after the microphone it waits for the `heard` or `together` line (`untilQuiet`).
6. **One socket per set**: `trailLength` and the current socket count a set of Meet screens as one step, filled at the last close.
7. **Find**: hold taps while the tapped word plays (step 2), then take them; set `askedLine` to the "and where is" line so the replay button asks it; draw no wobble on a language picture choice; the tapped clip and the line are queued, never mixed (the line waits for the word).
8. **Layout values** are in section 4.1 and 6.4; no token changes are needed (every size is an existing token or a component constant: card radius `xl`, thumbnail radius `md`, badge on the `SpeakerMark` disc).

---

## 11. Hand-offs and open points

- **curriculum-expert**: **C1** amend D1 so a Meet screen may show its word's chip to a child whose letters gate is open (3.2); **C2** the Hebrew Meet page's third beat is "let's say it together" and the word (5); **C3** no hint picture with the first wrong tap of a language picture choice, "and where is …?" being the first help (6.2). Each has a fallback in the text.
- **hebrew-text-editor** (L7-7): the Meet opener per course, the M1 carrier (proposal f41), "בְּעִבְרִית:" as a carrier before the gloss, "וְאֵיפֹה …?" (a carrier followed by the target clip, so it must read well before an English, Russian or Hebrew word), and the Hebrew explanation sentences (at most about 8 words, on one bubble line or two at 26 points on the phone). Every line on the mockups is a sample.
- **voice-and-sound-director**: the breaths between beats (400 / 300 / 250 ms), whether the voice director can report the start and end of a line's target clip (for the badge), no sting on a Meet close, the order "tapped word, then and where is" with no gap longer than 300 ms.
- **app-developer**: sections 4, 6.4 and 10; goldens in section 12.
- **qa-engineer**: after the build, section 12 and L7 §6 criteria 2 and 5.

**Needs the owner's eye** (when the developer's goldens exist): the Meet layout on the phone (the big picture on the left, the strip, "I said it" under the bubble) and the Find stage with larger pictures. Until then: `docs/design/l7/meet_phones.png`, `meet_tablets.png`, `find_wrong_tap.png`.

**Later, not in L7**: whether the Use part's say steps should also close by "I said it" rather than by a picture tap, so that a picture tap means "hear it" everywhere in a language lesson. It changes how a scored LS09 listening answer is given, so it is the curriculum-expert's call first.

---

## 12. Goldens to add

Each on the four boards unless said (phone, phoneSE, tabletLandscape, tabletPortrait), in a new `app/test/golden_l7_meet_find_test.dart`:

1. `l7_meet_eng_m5_lookA`: word 2 of 2, the strip with one thumbnail, the speaker bubble, "I said it" with its glyph, the microphone on.
2. `l7_meet_eng_first_m1_lookA` (phone, phoneSE): the first screen of a set, the strip column empty and kept, the speaking badge.
3. `l7_meet_rus_m2_lookB` (phone, phoneSE, tabletPortrait): the meaning in the bubble, two thumbnails, no chip, no tile.
4. `l7_meet_eng_m4_lookC_letters` (phone, tabletPortrait): the chip under f03, the badge.
5. `l7_meet_heb_page_h2`: a story page with its focus ring and the sentence; the phones without a strip (wide picture).
6. `l7_find_wrong_speaking_2`: the tapped picture speaking on the tall phone stage.
7. `l7_find_wrong_ask_2` (phone, phoneSE): the lilac settle and the "and where is" bubble.
8. `l7_find_wrong_speaking_3` (phone, phoneSE: two rows on the SE).
9. `l7_find_right_2` (phone): gold, the badge at top start and the check at top end together.
10. One text-scale 1.3 run of 1 and 3 on the phone SE (the bubble and the tile clear).

Behaviour tests (developer, then QA): the beat order and the single gloss; a picture touch during M0 to M4 is silent and from M5 replays and never advances; "I said it" and the microphone appear at M4 and close the screen; one trail socket per set; the chip table of 3.2 (`meetShowsWord`); the Find order "tapped word, then and where is and the target", taps held during the tapped word, the replay asking the new line, no wobble.

---

## 13. What I looked at, and what I did not

Looked at: the mockups above at full size (each board rendered alone in my scratchpad, then the half-size sheets): the picture card, strip, tile and bubble on all four boards, nothing overlapping the microphone, the bottom band or the bubble; the bubble lines wrap inside the bubble. The goldens `qa_l3_say_echo_phone`, `_tabletLandscape`, `qa_l3_say_mic_phoneSE`, `qa_l3_say_together_tabletPortrait`, `pilot_eng_first_phone`, `pilot_eng_first_tabletLandscape`, `pilot_rus_first_tabletLandscape`, `pilot_heb_first_phone`, `lesson_mistake_double_phone`; story 1's five pages (to pick the focus example).

Not looked at: the screens in the running app (nothing is built yet, and no Flutter run or test was made while the developer is testing in this worktree); the real phone (the owner can); motion (the mockups are still frames); the mockup's frame pieces are the measured `ActivitySpec` places, so a bubble that grows with a long line on a device may sit a few points differently than drawn. No new picture or character was drawn; every picture on the mockups is an existing one.
