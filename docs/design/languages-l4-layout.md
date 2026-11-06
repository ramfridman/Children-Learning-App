# L4 layout fixes: body map, close-up card, question picture, drum (QA-L4-1, -2, -3, -8, -9)

Owner: design-director. Date: 2026-11-05. Status: **spec for the app-developer; the art and the body map's data are done.**
From `docs/qa/l4-languages-verification.md`. Board numbers are those of `app/lib/child/activity_shell.dart` (`ActivitySpec`) and
`app/lib/play/choice_row.dart` (`withTallStage`, `withSpeakerRoom`). Positions are in board points unless a section says "stage
points" (inside the stage) or "shares" (of a picture's side). Mockups, made from the app's own pictures by
`docs/design/languages-l4/make_l4_mockups.py`, are in `docs/design/languages-l4/`.

The floor everywhere is Band A's: a control is at least 64 pt, an answer tile 96 pt on the phones and 112 on the tablets
(`TokenTouch`, design-spec 6.1). The scene square of `listen_do` (its tall stage less 12) is **233 pt on the phone SE, 241 on the
phone, 534 on the tablet landscape and 752 on the tablet portrait**; the phone SE is the binding board.

## 1. What changes, in short

| QA | Fix | Who |
|---|---|---|
| L4-1 | The body map is redrawn (arms further out) and every touch area is at least 72 of the picture's 256 units (65.5 pt on the SE). An item whose three parts cannot be 64 pt apart on the body (two or more face parts) is shown as **three close-up cards** in the answer row instead. The nose has an area. | design (done), developer |
| L4-2 | A part with two places (ears, arms, hands, fingers) is a **list of rectangles**; either rectangle is the part. | design (the data, done), developer (`at` takes a list) |
| L4-3 | The level-2 close-up card **never sits on the scene**: a fixed slot beside the stage on the phones and the tablet landscape, and a band under a smaller scene on the tablet portrait. | developer |
| L4-8 | At a question, on the phones, **the stage keeps its height** (the SE's grows to 116) and each option's speaker sits **beside** its tile, not under it. The pictured page keeps its own aspect. The picture is 206 x 116 pt on the phone and 185 x 104 pt on the SE (was 61 and 53). | developer |
| L4-9 | The drum stage is laid out in fixed zones: the word's picture at the start corner, the drum next to it, the hands and dots in a band that stops before the check mark, and the check mark alone at the end corner. | developer |

## 2. The body map (QA-L4-1, QA-L4-2)

**Files** (made by `tools/make_language_people.py`):
- `content/languages/pictures/mika-body.svg`, redrawn: the same Mika as the approved sheet, arms 55 degrees out, so the hands
  and arms have their own places.
- `mika-body.hotspots.json`, version 2.
- New close-up cards `body-hair`, `body-teeth`, `body-arms`, `body-fingers` and `body-legs`, next to the existing `body-head`,
  `-eyes`, `-ears`, `-nose`, `-mouth`, `-hands`, `-feet`, `-tummy`.

**The data (version 2).**

```json
"parts": { "ears": [[0.1926, 0.1113, 0.2812, 0.2812], [0.5262, 0.1113, 0.2812, 0.2812]], "nose": [[0.3594, 0.1414, 0.2812, 0.2812]], ... },
"items": { "ENG-A-06 i01": {"parts": ["head", "tummy", "feet"], "show": "body"},
           "ENG-A-06 i03": {"parts": ["ears", "eyes", "nose"], "show": "cards", "cards": ["body-ears", "body-eyes", "body-nose"]}, ... }
```

- **Shares** are of the picture's side: x, y, w, h from the top left, like `at`. Every area is at least 0.2812 (72/256), so it is
  at least 65.5 pt on the SE, 67.8 on the phone and 150 or more on the tablets. The nose's share is 0.2812, so it passes the
  validator's 0.04 to 1.0.
- **Every part is a list** (QA-L4-2). Ears, arms, hands and fingers have two rectangles; a touch in either is the part. A ring is
  drawn on each rectangle.
- An area is where the child may touch for the part, padded round the drawn part. **Areas of parts that never meet in one item
  overlap** (the ear areas cover the eyes; the hair covers the head). **The three areas of an item shown on the body never
  overlap.** The generator checks that for every item and decides the `show` value from it.
- The aliases share one place: teeth = mouth (the picture grins), hands = fingers, tummy = belly.

**Which item uses what** (from the JSON; `ENG-A-06 i01` to `i08`, `rus.a03.01` to `.15`; `.12` is the doll of a dress-up scene, a
picture of its own):

| On the whole body (`show: body`), touch areas | As three close-up cards (`show: cards`), answer tiles |
|---|---|
| ENG i01 head, tummy, feet | ENG i02 eyes, ears, mouth |
| ENG i06 hands, feet, eyes | ENG i03 ears, eyes, nose |
| ENG i07 feet, hands, head | ENG i04 nose, mouth, ears |
| ENG i08 tummy, head, hands | ENG i05 mouth, nose, head |
| RUS 05 arms, legs, ears | RUS 01 nose, mouth, eyes |
| RUS 06 and 14 legs, arms, nose | RUS 02 mouth, nose, ears |
| RUS 07 and 15 belly, head, legs | RUS 03 eyes, ears, nose |
| RUS 10 hair, belly, arms | RUS 04 and 13 ears, eyes, arms |
| RUS 11 head, legs, belly | RUS 08 fingers, nose, hair |
| | RUS 09 teeth, eyes, ears |

Why cards: the whole face is about 80 pt wide on the SE, and three 64 pt areas that do not overlap cannot fit inside it. One face
part next to two body parts does fit (its area is padded over the face), so those items stay on the body.

**Cards mode (for the developer).**
- The stage shows `mika-body.svg` whole, with no touch areas, so the child still sees the friend.
- The three cards are the answer row, in the course's direction, one tile each: 96 pt on the phones, 112 on the tablets.
- A touch on a card answers. Its hint ladder is the item's own: level 2 lights the card, level 3 shows the answer as on any tile.
- Each card has its own ring on the part it names, so "ears" shows both ears lit.
- Mockups: `body_map_on_body.png` (four body items on the SE, the areas drawn with their sizes in points) and
  `body_map_as_cards_phone.png`.

**Out of reach of the app:** the floor test of the validator (`_at` 0.04) should read the new minimum (0.28 for a Band A body
item); that is the developer's.

## 3. The close-up card of level 2 (QA-L4-3)

The card shows what the command names, close up, and must never cover a place the child must touch. It now has a slot of its own,
**outside the scene**:

| Board | Card | Where (board points) | Why it is free |
|---|---|---|---|
| Phone | 96 x 96 | x 413, y 248 | under the guide's bubble (its bottom is at most 236), left of the guide (617) and the microphone (661), above the bottom band (369) |
| Phone SE | 96 x 96 | x 300, y 222 | under the bubble (at most 210), left of the guide (490) and the microphone (521), above the bottom band (351) |
| Tablet landscape | 130 x 130 | x 136, y 300 | left of the stage (288), under the lamp and the eye |
| Tablet portrait | 130 x 130 | the stage's end corner, 12 below the scene | the scene is 614 square (the tall stage less a band of 150 at its bottom), centred; the card sits in that band at the end corner (x 660 in English and Russian, x 30 in Hebrew; y 998) |

- The card's content is unchanged: the right option's sprite, or the crop of the picture at its area. The crop must keep the
  picture's aspect and fill the card with the picture's own background, never white; the white strip QA saw at the head's crop
  goes away.
- The card is not a target, and a touch on it does nothing, as now.
- Mockups: `closeup_card_phones.png`, `closeup_card_tablets.png` (the HEB-A-04.1 chair with its three places, the "on" place at the
  top right).

## 4. The picture a question is about (QA-L4-8)

This applies to the story pause, the puppet's bubble question and the rhyme gap: every question state with a picture above a row of
tiles that have speakers.

| Board | Stage at the question | The picture | The row |
|---|---|---|---|
| Phone | unchanged, x 71, y 96, 330 x 128 (no `withSpeakerRoom` shrink) | at its own aspect, height 116: a story page (16:9) 206 x 116, a square picture 116 x 116, centred | y 244; each option is a tile 96 + 6 + its speaker 64 on one pill; options 15 apart; three options take 528 (x 74 to 602), two take 347, centred |
| Phone SE | grows to x 16, y 86, 270 x 116 (bottom 202) | height 104: a page 185 x 104, a square 104 x 104 | y 220; tile 96 + 4 + speaker 64; options 8 apart; three take 508 (x 6 to 514, before the microphone at 521 and under the guide's foot at 216) |
| Tablets | unchanged | 256 or more, as now | unchanged (speaker under the tile) |

- **The speaker is on the tile's end side**: the right in English and Russian, the left in Hebrew. It is the same 64 pt speaker
  and plays the option's clip without answering.
- **Tile and speaker sit on one soft pill** (lilac `#ECE3FE`, radius 26) so the child sees which speaker is whose. The space
  between options is larger than the space between a tile and its own speaker.
- **The pictured page keeps its aspect.** `story-page-*` is no longer forced square: a 384 x 216 page in a square box was shrunk a
  second time. The words' touch boxes (`p.words[].at`) are shares of the page's width and height.
- With two options, or without speakers, the row is centred as today.
- Mockup: `question_phones.png` (English and Hebrew, phone and SE).

## 5. The drum (QA-L4-9)

All values are in stage points of the drum's tall stage: phone 330 x 253, SE 270 x 245, tablet landscape 584 x 546, tablet
portrait 772 x 764. They are for English and Russian; **Hebrew mirrors every x** (x becomes width − x − w). The word's picture
moves to the right, the start corner of a Hebrew line, which also answers note N4.

| Board | Word's picture | Drum (the whole disc is the target) | Hands row (level 2) | Dots row (9 at most) | Check mark ("that's all") |
|---|---|---|---|---|---|
| Phone | 8, 8, 96 | 159, 8, side 116 | y 132, 34 high | y 182, dot 18, gap 8 | 246, 169, 72 |
| Phone SE | 8, 8, 80 | 129, 8, side 100 | y 116, 30 high | y 158, dot 14, gap 4 | 186, 161, 72 |
| Tablet landscape | 12, 12, 150 | 253, 16, side 240 | y 280, 44 high | y 350, dot 32, gap 12 | 476, 438, 96 |
| Tablet portrait | 12, 12, 180 | 332, 16, side 300 | y 340, 50 high | y 420, dot 36, gap 12 | 664, 656, 96 |

- **The hands row and the dots row are centred in a band that stops before the check mark's column.** The band is x 8 to 234 on
  the phone, 8 to 174 on the SE, 12 to 464 and 12 to 652 on the tablets (mirrored in Hebrew). Nine dots fit in it on every board,
  so nothing ever reaches the check mark. The check mark is below the drum's square on every board, so the drum's tap area and
  the check mark never overlap.
- The drum itself can be `drum.svg` (the picture set's toy drum) inside the same disc target, as note N4 suggests.
- Mockups: `drum_phones.png` (English and Hebrew), `drum_tablets.png`.

## 6. What I looked at, and what I did not

- **Looked at:**
  - the cited goldens (`ls08_question_phone` and `_phoneSE`, `ls03_hands_*`, `ls03_drum_*`, `ls11_closeup_*`);
  - every mockup above, at full size;
  - the body map's areas over the picture for four items;
  - the new close-up cards at 200 px.
- **Not looked at:** anything on a real device, or the app after the developer's change. The goldens must be drawn again after
  it (the qa-engineer re-runs QA-L4-1, -2, -3, -8, -9).

## 7. Hand-offs

- **app-developer:**
  - `at` as a list of rectangles, and the hotspot JSON version 2 (sections 2 and 1);
  - the cards mode for `show: cards`;
  - the close-up slot (section 3);
  - the question layout on the phones (section 4);
  - the drum zones (section 5);
  - the validator floor for Band A body items;
  - drawing the goldens again.
- **curriculum-expert:** please confirm that the face items as three close-up cards (section 2) keep the representation "on the
  friend" well enough for ENG-A-06 and RUS-A-03. The friend stays on the stage, and each card is a close-up of the friend's own
  part.
- **qa-engineer:** once the developer is done, re-verify QA-L4-1, -2, -3, -8 and -9 on the four boards.
