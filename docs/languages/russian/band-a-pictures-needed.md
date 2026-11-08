# The Russian course, Band A: pictures and sounds still wanted

Owner: russian-language-teacher (the list); design-director (the drawings), voice-and-sound-director (the sounds). Date: 2026-11-07, written by the app-developer from what the recipes found.

The ten-frames 5 to 10, the doll with its tap areas and face cards and the redrawn `mika-gift` exist (batch 5); the rooms of RUS-A-13 and the story maps of RUS-A-16 exist (batch 6, below). Still wanted:

| Needed | For | What |
|---|---|---|
| the clips `sfx-cat`, `sfx-dog`, `sfx-cow`, `sfx-horse`, `sfx-pig`, `sfx-goat`, `sfx-duck`, `sfx-rooster`, `sfx-mouse`, `sfx-wolf` in `pronunciation.csv` | RUS-A-05 items 23 to 32 (which animal makes this sound) | not in the packs until the table has the clips |
| the friend holding or pointing at the thing | RUS-A-13 07 to 10 (yes or no) | the item shows the thing alone |
| same and different icons (or the friend nodding and shaking the head, `mika-yes`, `mika-no`, as now) | RUS-A-19 06 to 11, RUS-A-20 07 to 16 | the nod and the shake stand in |

## Drawn 2026-11-07 (design-director, batch 6)

In `content/languages/pictures` (generator `tools/make_language_pictures_band_a.py`, sheet `docs/design/languages/pictures_batch6a.png`):

- **RUS-A-13 01 to 05:** one square room per item (the listen_do scene is a square; the 384 x 216 `scene-room` background stays as it was), the three things of the item drawn into it, each with a touch area of at least 72 of 256 units and no two overlapping. Parts are named by the option's picture id.

| Picture | Item | On the shelf (or peg) | By the window | On the rug / floor |
  |---|---|---|---|---|
| `scene-room-ball` | 01 | doll | balloon | **ball** |
| `scene-room-cat` | 02 | porridge | **cat** (on the sill) | dog |
| `scene-room-mouse` | 03 | teddy | (empty) | cat on the rug, **mouse** on the floor under the window |
| `scene-room-hat` | 04 | jacket (on a coat peg) | **hat-warm** (on the sill) | scarf (lying folded) |
| `scene-room-apple` | 05 | milk | **apple** (on the sill) | pear |

- **RUS-A-13 06:** `scene-garden-family`, papa, **mama** and babushka of the approved family standing in a garden (parts `father`, `mother`, `grandmother`).
- **Wired (app-developer, 2026-11-07):** RUS-A-13 items 01 to 06 are LS11 hotspots on these six pictures (01 to 05 ask with f19, 06 with f01 because the garden is not a room), each praise ending with the "Вот …!" clip; the touch areas are the ones in the `.hotspots.json` files, unchanged.
- **RUS-A-16 01 and 04:** `st1-p1.hotspots.json` (`sobaka`, the dog; `mjach`, the ball) and `st2-p1.hotspots.json` (`jozhik`, the hedgehog), at least 96 of the 384 x 216 units. The recipe finds them by the word's clip (`w-sobaka` → `sobaka`), so the words of 01 and 04 are in the pack at the next `python tools/lang_pack.py rus`.
