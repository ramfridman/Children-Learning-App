# B-42: the daily welcome on the map (design check, work item 6)

The rules of the welcome are in `docs/milestones/B42.md` sections 2.3 to 2.5. This page holds only the layout of the
friend's bubble while the welcome speaks, and the pill's glow. Checked by `app/test/welcome_bubble_test.dart` (every
welcome sentence, both text scales, all four boards) and its goldens `app/test/goldens/welcome_*.png`.

## The bubble

- One sentence at a time, the same `BoardBubble` as the map's own words (paper, radius `lg`, the small tail on the right
  edge pointing at the friend's mouth; B-34), the same font per board (18 phone, 17 SE, 24 tablets, weight 500, line
  height 1.7). The first sentence puts the child's name on its own line ("<name>,"), shortened by the sign's rule when it
  is too long for the line.
- **Phones:** as the map's bubble: at most 210 wide (190 on the SE), held by its bottom beside the mouth, growing upwards
  over the home island's palm. The longest sentences take 3 rows at text scale 1.0 and 4 at 1.3 (the first-day greeting
  with the name); the bubble never reaches the pill (12 or more points clear) and covers no land's sign.
- **Tablets:** the welcome is taller than the map's one-line words, and above the friend there is a land's sign (Market
  Village in landscape, Colour Bay in portrait), below it the home island's sign. So the welcome's bubble keeps to a band
  between them (`_HomeSpec.welcomeTop` / `welcomeBottom`, at text scale 1.3 6 to 8 clear of each sign):

  | Board | Band (world y) | Widest |
  |---|---|---|
  | tablet landscape | 426 to 660 | 245 (left edge 760, 12 clear of Counting Hills' stairs) |
  | tablet portrait | 1282 to 1504 | 245 (left edge 376, 20 clear of the Counting Hills sign) |

  The bubble starts 210 wide; a sentence too tall for the band widens it 5 at a time up to 245. It grows upwards from the
  mouth as on the phone; when it would reach the band's top it stands lower instead, and its tail moves up its right
  edge (`BoardBubble.tailBottom`) so it still points at the mouth. Worst case, the first-day greeting with the name at
  1.3: 245 by 220.
- Nothing in it asks anything: no line has a question mark (a test), there are no answer pictures, no buttons, no
  score. The bubble takes no touch (any touch goes to the map and stops the welcome). After the welcome the bubble says
  its own words again (`homeBubble`, the existing invitation "<name>, מַה בַּבַּקְבּוּק?").
- The optional land sign beside the topic (B42.md 2.3) is left out: the land's own sign is on the map, and a second
  small sign in the bubble would add a picture to read while the friend talks.

## The pill's glow

During the closing line ("בּוֹאוּ נִפְתַּח אֶת הַבַּקְבּוּק.") the Today's Adventure pill has a still light: a gold rim
(`spark`, 5 out, blur 4) and a pale cream glow beyond it (`sparkTint` at 80 percent, 12 out, blur 28), drawn under the
pill's own clay lip so the pill keeps its edge. The cream keeps the glow from turning green where it meets the sea's
blue. It does not pulse, and with reduced motion there is none (a test).
