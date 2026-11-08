# B-29 D1 follow-up: the caption bubble covers the phone's scene

Design note (design-director, 2026-11-08), branch `b29-steps5-9` at 6dd9754e. Read only; no code or golden changed.

## What happens

On the phone boards the scene (the stage, 330 x 128 at x 71 to 401 on `phone`, 270 x 104 at x 16 to 286 on `phoneSE`) and the bubble
(190 / 176 wide, right edge 603 / 476) stand side by side. D1 now keeps the caption at the stage's size down to 2 points under it
(P3: 24 to 22 on the phone, 22 to 20 on phone_se), and only then widens the bubble to the left, "keeping 150 pt of stage on phones"
(`ActivityFrame.minStageRoom`, from my own spec, b29-steps5-6.md section 6.3 D1). The 150 was meant for a hint card at the stage's left
edge; the scenes are laid out across the whole stage, so the widened bubble lies over up to 180 of its 330 points.

Measured on every `hint_*`, `unit_*` and `stage_p*` golden on phone and phone_se (284 files, a pixel scan of the bubble's edges, then
every file over the stage looked at):

- 64 of 284 have the bubble over the stage: 56 hint goldens (45 of them hint level 3), 4 unit goldens, 4 stage goldens.
- 29 cover more than 15 % of the stage, the worst a third of it (`hint_qa_count_l3_phone_se`, `hint_count_l3_phone`).
- 19 hide what the child has to count, compare or read (list A), 13 hide part of the scene (list B), 32 lie over sky only.

Level 3 is the step that walks the child through the answer, so it is exactly where the scene matters most. Captions are shown by
default from gan hova (P3, P4), and for P1/P2 when a parent turns them on.

### A. Hides what the child needs (19)

| Golden | What is hidden |
|---|---|
| `hint_qa_count_l3_phone_se` | 3 of the 5 ladybugs and their count badges (only 1 and 3 show) |
| `hint_tap_count_l3_phone` | the same: 3 of 5 ladybugs |
| `hint_count_l3_phone` | apples 6 and 7, their badges, and the basket; the line says "the last number says how many: seven" |
| `hint_tap_add_l3_phone` | the two stars that are added ("three stars and two more") |
| `hint_tapb_sentence_part_l3_phone`, `_l2_phone` | "= 7" and its blocks (hidden at l3, cut in half at l2) |
| `hint_tapb_sentence_l3_phone` | "= ?" |
| `hint_tapb_ten_more_l3_phone`, `_l2_phone` | "+ ?" of 12 = 10 + ? |
| `hint_tapb_add_more_l3_phone` | the second ten-frame (the four more) |
| `hint_tapb_whole_parts_l3_phone` | the right half of the strip |
| `hint_tapb_to_ten_l3_phone` | the fifth column of the ten-frame (cut) |
| `hint_share_l3_phone` | the cat's card and the apples it got |
| `hint_balance_weigh_l3_phone` | the right pan and its two cubes |
| `hint_balance_l3_phone` | the right pan and what is on it |
| `hint_shop_l3_phone`, `hint_shop_l3_pay_phone`, `hint_shop_l3_phone_se`, `hint_shop_l3_pay_phone_se` | the right column of the coin tray, the coins the line names |

### B. Hides part of the scene, the key part still shows (13)

`hint_tapb_after_l3_phone` (the line after 30), `hint_qa_sequence_l3_phone_se` and `hint_tap_sequence_l3_phone` (9 and 10; the 5 the
hint is about shows), `hint_sort_l3_phone` (the red box's right side), `hint_match_l3_phone` (card 3 cut), `hint_give_l1_phone` (half
the flower), `hint_tapb_clues_l3_phone` (the third card), `hint_tapb_coins_l3_phone` (the end of the ten-bar and its badge),
`hint_tapb_to_ten_card_l3_phone` (the frame's edge), `unit_balance_compare_phone` (the right pan's last chick), and two where a drop
target is under the bubble: `unit_drag_share_phone` (the cat's card) and `unit_shop_pay_phone` (the coin tray). Whether a drop on the
covered part still lands must be checked (the bubble is above the stage in the frame's Stack).

### C. Over sky only (32)

For example `hint_tapb_sides_l3_phone`: the triangle and its badges 1 to 3 all show; the bubble lies over sky. Also the stage goldens
`stage_p1_captions_on_phone`, `stage_p3_activity_phone`, `stage_p3_activity_phone_se`, `stage_p4_activity_phone_se` (three apples, all
visible).

### Related: the hint's hand over the caption

Since 5145d134 the hand is drawn above the bubble. Where the bubble widened down-left into the band above the tiles, the hand pointing
at a tile now lies over the caption's last words (`hint_qa_count_l3_phone_se`, `hint_tap_add_l3_phone`, `hint_tap_count_l3_phone`,
`hint_tapb_after_l3_phone`, `hint_share_l3_phone`, `hint_balance_weigh_l3_phone`, `hint_tapb_ten_more_l3_phone`,
`hint_tap_sequence_l3_phone`, `hint_qa_sequence_l3_phone_se`, `hint_tap_numerals_l3_phone`, `hint_tapb_to_ten_card_l3_phone`). The
fix below brings the bubble back to its own column and clears most of these by itself.

## The rule

**On a phone the scene is never covered. The caption gives way first: it gets taller, then smaller, and only a line that does not fit
at 14 pt drawn may reach into the stage, as a content defect.**

The options weighed:

- *Reserve a caption band above the scene*: no room on a landscape phone (controls 12 to 76, stage 96 to 224, tiles 244 to 372 of
  393). Right for tablets, where the bubble already stands above the stage.
- *Shrink the scene into the room left beside the bubble*: at the widest bubble the scene would be 142 x 128; a ten-frame's cells and a
  1 to 10 line's numerals drop to about 13 pt, and stage taps (match cards, sort boxes, drop targets) fall under the 2 cm hit area.
  Not as the fix.
- *Cap the bubble's growth on phones* (chosen): the voice says the whole line; the scene carries the count (the badges 1, 2, 3 ... are
  drawn on it), so a smaller caption costs less than a hidden apple.

## Spec for the app-developer

`app/lib/play/activity_frame.dart`, phone boards only (`!s.stageIsCard && !s.tailAtMouth`); tablets and the blocks' layout unchanged.

1. `widest` stops at the stage's right edge: `rightEdge - s.stage.right` (phone 603 - 401 = 202, phone_se 476 - 286 = 190), the
   gutter between stage and bubble and no more. Today it is `rightEdge - s.stage.left - minStageRoom` (382 / 310).
2. `fitBubble` order on a phone:
   1. board width, the stage's caption down to `captionFloor` within the board's limit (D1, unchanged);
   2. up to `widest`, at the floor, within the room between trail and tiles (unchanged loop);
   3. **new:** at `widest`, the font from floor - 1 down to **14 drawn** (`min / factor` as today) within the room;
   4. **new:** only then widen into the stage up to today's limit (`spill = rightEdge - s.stage.left - minStageRoom`), at 14;
   5. down to `hardMinFont` at `spill` (unchanged last resort).
   Steps 3 to 5 are the D1 content-defect list; steps 4 and 5 also fail the audit below.
   Suggested shape: `fitBubble(..., widest: 202, spill: 382, longFloor: 14)`; `spill` null keeps today's behaviour for every other
   caller.
3. Estimate from the goldens: the longest level-3 lines then draw at about 15 to 16 pt on phone and 15 on phone_se, inside the
   bubble's own column, instead of 22 to 24 over the scene.
4. Goldens to redraw: the 64 listed above (the bubble moves back for all of them); none on tablets.

## The audit test

Add to `app/test/support/bubble_audit.dart`, next to `bubbleOverTiles`:

```dart
/// What the speech bubble covers of the stage on a phone board: one line when it reaches into it; empty when it keeps clear.
List<String> bubbleOverStage(WidgetTester t) {
  final Finder bubble = find.byKey(const Key('bubble-body'));
  final Finder stage = find.byKey(const Key('lesson-stage'));
  if (bubble.evaluate().isEmpty || stage.evaluate().isEmpty) return const <String>[];
  final Rect b = t.getRect(bubble.first), s = t.getRect(stage.first);
  final Rect hit = b.intersect(s);
  return hit.width > 0.5 && hit.height > 0.5 ? <String>['the bubble $b lies ${hit.width} pt over the stage $s'] : const <String>[];
}
```

Call it from `auditBubbles` in the same `check(state)` (start, hint 1, 2, 3) on `phone` and `phoneSE`, for every activity of the
starter pack, at stages P1 with captions on, P3 and P4, at text 1.0 and 1.3. A failure names the activity id, the state and the
overlap, which is the list for the hebrew-text-editor. Tablets skip it (the bubble stands above the stage there).

A second, smaller check that the scene's key objects show, for the hint plans that know their geometry (the count badges, the "?"
slot, the pans, the coin tray, `tap_plans*.dart`): every target rect, moved to board coordinates by the stage's offset, must not
intersect `bubble-body`. With the rule above it is implied by the first check; it stays useful if a later layout lets the bubble
into the stage's empty margin.

## Hand-offs

- **app-developer:** the spec above, `bubbleOverStage` in the audit, the 64 goldens; and check whether a drag that ends on the part of a
  drop target under the bubble still lands (`unit_drag_share_phone`, `unit_shop_pay_phone`).
- **hebrew-text-editor** with the **curriculum-expert:** the level-3 lines that land in steps 3 to 5 on a phone (the audit's list). Either
  shorter lines, or a screen caption that is only the line's last sentence (the action and the number) while the voice says it all;
  they decide which, since a reader following along may expect the words that are spoken.
- **qa-engineer:** after the change, the 64 goldens on phone and phone_se, and the audit at text 1.3.
