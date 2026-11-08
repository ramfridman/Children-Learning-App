# English Band A: pictures still needed

Owner: english-language-teacher. Date: 2026-11-07. For the design-director.

**The pack needs no new picture.** Every item that is in `content/languages/eng/units` uses a picture of `content/languages/pictures` (100 pictures; `tools/lang_pack.py eng` checks each one). The names are those of `docs/languages/pictures.md` §4 (for example `pip-arrive` for the content's `pic.greet-arrive-pip`, `act-sit` for `pic.act-sitdown`, `fam-mother` for `pic.fam-mom`, `fam-all` for `pic.fam-pip`, `tea` for `pic.cup-hot`, `present` for `pic.box`, `mika-icecream` for `pic.scene-mika-icecream`).

The items that wait for a template recipe (the `waiting` lists of the units, and `content/languages/eng/waiting/`) need these when their recipe is written:

| Needed | For | What |
|---|---|---|
| `duckling-lit`, `ball-lit` | ENG-A-04 i06, i07 (T02 `count_tap`: `litSprite` is required) | the single duck of the duck sets and the single ball of the ball sets, each with the soft gold glow of a touched object |
| tap areas (`at`) on `dog-big` and `ball-pair` | ENG-A-10 i01 to i04 (big and small: two places in one picture) | the big dog and the small dog, the big ball and the small ball, each one area of at least 64 pt |
| tap areas on `story-bounce-2` to `-5` | ENG-A-15 s01 (a word said when its picture is touched) | the cat, the duck, the frog, the dog and the ball on their pages |

Answers to `pictures.md` §6 for the English teacher: Pip is the budgerigar host (yes); the family is Mika's, and Pip's own family is the one budgerigar picture `pip-family` for the personal turn (yes: no English line says whose family it is); the sad faces with a soft frown and no tear are right (the word "sad" does not need a tear).

## Drawn (design-director, 2026-11-07)

All three rows are done, in `content/languages/pictures` (generator `tools/make_language_pictures_band_a.py`, sheet `docs/design/languages/pictures_batch5c.png`):

- `duckling-lit.svg`, `ball-lit.svg`: the same drawing in the same place as `duckling` and `ball`, with a soft gold glow behind (as `content/starter/*_lit.svg`), so swapping the sprite on a touch moves nothing.
- `dog-big.hotspots.json`, `ball-pair.hotspots.json`: two areas each, `big` and `small`, at least 72 of 256 units (65.5 pt on the phone SE), not overlapping. **`dog-big` no longer has the gold glow behind the big dog**: in a hotspot item that asks for the small dog it would point at the wrong one.
- `story-bounce-2.hotspots.json` to `-5`: `cat` and `ball` (2), `duck` and `ball` (3), `frog` and `ball` (4), `dog` and `ball` (5), shares of the page's width and height, at least 96 of the 384 x 216 units (64.5 pt on the SE's tall stage), not overlapping. On page 5 the ball now flies just in front of the dog's nose (it was inside the dog's outline, so the two could not have separate areas).

## Update 2026-11-07 (app-developer): what the recipes found

The design-director's batch 5 answered the three rows above (`duckling-lit`, `ball-lit`, the tap areas of `dog-big`, `ball-pair` and the bounce story). The recipes now use them. Still wanted:

| Needed | For | What |
|---|---|---|
| a drawn box that **opens** (`present-open`) | ENG-A-16 g01 to g06 (the guessing game: "the box stays closed until the child taps, then it opens") | the closed `present` is all the story pages show now |
| Pip holding the object (a composite of `pip-holds` with a thing) | ENG-A-11 i07 to i10 | the bubble turns show the object alone |
| the friend in a playground | ENG-A-02 buttons use `mika-body` | optional |
| `<picture>-lit.svg` for the counted things (`duckling` and `ball` exist; `apple`, `duck`, `car` for Russian) | T02 counts | the generator makes a gold-glow copy of the thing when none is drawn |
