# B-26 step 2: design review of the renders (design-director, 2026-10-29)

Looked at (worktree `D:\nitznutz-b26`, `app/test/goldens/`), each new PNG beside its HEAD version (`git show HEAD:...`),
with 1.5x to 2x crops of the sign, the pill and the tablet bubble: `home_sign_{noa,alexandra,avigail_alexandra}_phone`
and `_phone_se`; `home_phone`, `home_phone_se`, `home_tablet_landscape`, `home_tablet_portrait`, `home_phone_end`,
`home_phone_se_end`, `home_tablet_portrait_top`; also `companion_home_hero_phone` (changed too). Not looked at: the sign
on tablets and at text scale 1.3 (no golden; judged from `fitHomeSign` and the tests), the real phone.

## 1. The sign: right on both phones

| Golden | Text, size | Sign (screen x) | Clear of Counting sign | Clear of the "+" disc |
|---|---|---|---|---|
| noa, phone | whole, 18 | 568..712, centred under the island | 131 | 40 |
| alexandra, phone | whole, 18 | 538..727, held at the box's right edge | 101 | 25 |
| avigail_alexandra, phone | `אביגיל…`, 18 | 555..727 (spec said about 170: 172) | 118 | 25 |
| noa, SE | whole, 18 | 448..592 | 102 | 29 |
| alexandra, SE | whole, 17 | 415..597 | 69 | 24 |
| avigail_alexandra, SE | `אביגיל…`, 18 | 422..597 | 76 | 24 |

- Same height, border, weight and baseline as the other land signs; held-right signs still look centred (8 off on the
  phone). The "…" stands at the left end, after the name, as RTL needs; three clean dots on the baseline.
- Nikud of `הָאִי שֶׁל` (kamatz, hiriq, shin dot, segol) is whole and clear at 2x; nothing cut at top or bottom.
- The "+" disc sits above and to the right of the sign's end, 24 to 25 clear horizontally; they read as two objects.
- **Text scale 1.3, Alexandra whole at 15 and Avigail-Alexandra shortened at 17: accept.** The rule's order is right
  (the whole name before a bigger size: a pre-reader knows their name by its whole shape), each child sees only their
  own sign, and the regrown 17 sits closer to the neighbouring signs (18 at 1.3) than 15 would. No change.

## 2. The pill without dots: still a clear call to action
Orange capsule, clay lip, the bottle on a white disc: it still says "press me", and the text now sits on the pill's
centre line (phone: text 47, pill 12..84). The dots looked like a pager; the pill is calmer without them. Keep the
height (72 / 64 / 88). One optical fix: the text side is tighter than the icon side (phone 12 vs 16, SE 8 vs 16).
- **Fix (minor, app-developer):** `pillPadLeft` phone 12 -> 16 and both tablets 12 -> 20 (equal to `pillPadRight`),
  phoneSE 8 -> 12 (its pill is the tightest board). Phone pill grows 235 -> 239 inside its 270 frame at scale 1.0; it
  adds 4 to QA-19's overflow at 1.3, so land it with the QA-19 fix.

## 3. The longer bubble on tablets: fix, do not leave
- Landscape: the body runs 717..1000 (was 790..1000) and hides the two smallest of the five Counting stairs (they end at
  748). The staircase is Counting Hills' own picture of 1..5; on the first screen it shows three steps.
- Portrait: the body runs 333..620, y 955..1005 (was 405..620); its lower-left corner comes within about 5 of the Counting
  sign's corner (338, 997) and covers Counting's beach rim; 8 below the bridge.
- Measured at 24: `נֹעָה,` 36; `בַּבַּקְבּוּק יֵשׁ הַרְפַּתְקָה!` 213 (the old `הַבַּקְבּוּק הִגִּיעַ!` was 136).
  A break after the comma gives a 245 body (left 755, 7 from the stairs: no gain); a balanced break leaves a 157 body
  but doubles the height (90) and the bubble, anchored at the mouth, grows up over the whole palm crown (y 472..511).
- **Fix A (hebrew-text-editor):** a map line whose fixed part (after `{child}, `) is at most 140 at Heebo 500, 24
  (about 9 to 10 letters and one space, like the old line), true for a revisit, the bottle kept. The full sentence
  already lives in the home (`nitziHomeBottle`). With Noa it gives a body of about 210: left 790 landscape (42 clear
  of the stairs), 410 portrait (20 past Counting's beach, 72 from its sign).
- **Fix B (app-developer, with A):** tablets only, `BoardBubble(maxWidth: 210)` (the body, padding included) and, when
  the one-line text is wider, a line break after `{child},` so the fixed part stays whole on line 2 (never three lines).
  Bottom anchor unchanged: a long name's two-line bubble (90 high) grows upward over the home island's own palm crown,
  never over another land. Phones unchanged (one line over open sea: phone 425..640, SE 308..512).
- If the editor keeps the current wording: tablet `bubbleFont` 24 -> 22 plus Fix B with the break always after the
  comma (line 2 195, body 227, left 773 landscape, 393 portrait, 83 high, crown covered). Second best.
- Golden to update: `home_tablet_landscape`, `home_tablet_portrait` (and a long-name tablet bubble golden, QA).

## 4. Other things seen
- **Step 2 vs plan (app-developer, orchestrator):** decision 1 and step 2 list the Hall and sticker pebbles and the
  dead book as removed; every map render still has them, and the book's `onPressed` is `() {}`. Keep the two pebbles
  until the home screen exists (step 4: it is their only door) and say so in B26.md; remove the book now. The
  Parents button stays where it is (nothing moves into the gap).
- `home_tablet_landscape` at HEAD had no pebbles (stale under the 3 % tolerance); the new one is the true map. There
  the pebbles sit on the cloud at x 1045..1135, y 105..150, which peeks between them. Goes away in step 4; no action.
- SE (pre-existing): the scene's sparkle at about (410, 104) is half hidden by the bubble's top edge and looks like a
  glitch. Mine: move it in the SE scene art to the open sea left of the bubble (x about 280) in the art pass.
- `companion_home_hero_phone`: HEAD drew a dark red box where the companion stands; now nothing is drawn there.
  Not a step-2 design change, but QA should confirm that the empty spot is what that test means to show.
