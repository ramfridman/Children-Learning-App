# The Hebrew course, Band A: pictures still to draw

Owner: hebrew-language-teacher (the list); design-director (the drawings). Date: 2026-11-07. Every other picture Band A names is already in `content/languages/pictures`.

Only skill HEB-A-05 (one and many, `band-a-content.md` A-05) is waiting for pictures. Its items are written in `content/languages/heb/units/pending/a05-one-and-many.json` and move into the pack once these files exist. Each set is the same drawing as the singular picture, shown 3 to 5 times, in one group with no counting layout. The ids follow the library's `set-balls-<n>` files.

| Picture id | What it shows | Singular drawing | Used in |
|---|---|---|---|
| `set-cats` | many cats (חֲתוּלִים) | `cat.svg` | A-05.1 (right) |
| `set-dogs` | many dogs (כְּלָבִים) | `dog.svg` | A-05.1 (the SEM distractor) |
| `set-dolls` | many dolls (בֻּבּוֹת) | `doll.svg` | A-05.3 (right), A-05.2 (SEM) |
| `set-teddies` | many teddy bears (דֻּבִּים) | `teddy.svg` | A-05.3 (SEM) |
| `set-cakes` | many cakes (עוּגוֹת) | `cake.svg` | A-05.4 (right) |
| `set-pizzas` | many round pizzas (פִּיצוֹת) | `pizza.svg` | A-05.4 (SEM) |
| `set-horses` | many horses (סוּסִים) | `horse.svg` | A-05.5 (right) |
| `set-donkeys` | many donkeys (חֲמוֹרִים) | `donkey.svg` | A-05.5 (SEM) |
| `set-boats` | many small boats (סִירוֹת) | `boat.svg` | A-05.6 (right) |
| `set-planes` | many planes (מְטוֹסִים) | `plane.svg` | A-05.6 (SEM) |
| `set-eggs` | many eggs (בֵּיצִים) | `egg.svg` | A-05.8 check (right) |
| `set-apples` | many apples (תַּפּוּחִים) | `apple.svg` | A-05.8 check (SEM) |

A-05.2 (many balls) uses the existing `set-balls-4.svg`.

## Drawn (design-director, 2026-11-07)

All twelve are done, in `content/languages/pictures` (generator `tools/make_language_pictures_band_a.py`, sheet `docs/design/languages/pictures_batch5a.png`): each set is the singular picture's own drawing, all copies the same size, in one loose group of a back row and a front row that overlap a little (no row, grid or dice layout). Counts: `set-cats` 4, `set-dogs` 3, `set-dolls` 4, `set-teddies` 3, `set-cakes` 3, `set-pizzas` 3, `set-horses` 3, `set-donkeys` 3, `set-boats` 4, `set-planes` 3, `set-eggs` 5, `set-apples` 5, so "many" is never tied to one number.

Also for this course: the HEB-A-10 marks ● ○ ▲ △ (`text:●` and so on in `units/08-letters-or-not.json`) **are not in Heebo** (nor in Secular One): the font has no glyph for U+25CF, U+25CB, U+25B2 or U+25B3, so the app would draw them in a fallback system font that differs per phone. They are drawn as shape cards for the app-developer to use instead: `shape-dot`, `shape-ring`, `shape-triangle`, `shape-triangle-open` (ink, the weight of a bold letter, centred; sheet `pictures_batch5c.png`).

## Update 2026-11-07 (app-developer)

All the sets of HEB-A-05 exist now (batch 5); the skill is in the pack. Still wanted:

| Needed | For | What |
|---|---|---|
| a heart and a flower as pictures (`shape-heart`, `shape-flower`: ink, the weight of `shape-dot`, centred, 256 by 256) | HEB-A-10 t05 (♥) and s06 (✿) | Heebo has neither (Secular One has no flower), so the cards are stand-ins for now: t05 uses `shape-triangle` and s06 uses `star`; the star of s02 is the picture `star`. When the two files are in `content/languages/pictures`, change the two cards in `units/08-letters-or-not.json` to `{"pic": "shape-heart"}` and `{"pic": "shape-flower"}` (and their `wrong` keys), then `python tools/lang_pack.py heb` |
| a check of the touch areas of `chair`, `box`, `table` and `bed` (on, under, by, in) | HEB-A-04 | measured by the app-developer in `scenes.areas.json`; refine them |
| the two frames of the A-02 actions as a stage | HEB-A-02 09 to 18 | the item shows the second frame only |
