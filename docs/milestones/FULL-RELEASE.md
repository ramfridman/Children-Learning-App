# The full release: every band of every island, ready for the owner's phone

**The owner's goal (2026-11-07):** "I want to finish up all the Bands of all the islands and L5. Once everything is done we will do a full sweep on all the hebrew texts so we make sure they are written and sound (pronounce) in the right way. My goal is to make the app perfectly ready to install on my phone."

This file orders the work that is left. Each part already has its own approved plan, named below; nothing here changes those plans. The team, the QA rule (once per finished feature or batch) and the security rules of `CLAUDE.md` apply as always.

## What is left

| # | Part | Plan (approved) | Size |
|---|---|---|---|
| 0 | **Close the open work**: the riddles-island sweep, the Hebrew review (PR 39), M10 C1 | sweep-2026-11-06, M10 | 3 PRs |
| 1 | **Languages Band A** of all three courses (English, Hebrew, Russian; ENG-1, HEB-1, RUS-1) and the language packs, so the Languages island can be played | frame.md §6, `docs/languages/*/band-a-content.md` | 3 courses |
| 2 | **L5**: the Band B activity types (sound boxes, change one part, blend slide, build a word, follow and echo, co-play cards), then **Languages Band B** of all three courses (ENG-2, HEB-2, RUS-2) | L5.md | 6 templates, 76 skills |
| 3 | **M10**: Band C of the six lands, C2 to C9 (C9 needs the owner's choice) | M10.md | about 1,100 activities |
| 4 | **L6**: the Band C activity types, then **Languages Band C** of all three courses (ENG-3, HEB-3, RUS-3) | L6.md | 3 templates, about 80 skills |
| 4b | **The head of the line** in the ordinal items (NUM-A-13: first, third, last): the start flag drawn from the first view, and the animals facing it (math-teacher's finding, 2026-11-07; app-developer, design-director) | — | 6 items |
| 5 | **B-29 steps 5 to 9**: the parent's month and year and school stage screens, the look by age, the languages' gates, Today's Adventure | B29.md | 5 steps |
| 6 | **The full Hebrew sweep**: every text read again for grammar, nikud and wording (hebrew-text-editor), and for how the voice will say it (voice-and-sound-director: the pronunciation list, the words kept pointed for the voice, a listening pilot) | owner, 2026-11-07 | every Hebrew line |
| 7 | **The voices**: one voicing batch of every line, planned with its character count and cost; **the owner runs and pays** | B-45 | owner |
| 8 | **The release**: the open security findings (SEC-6, SEC-7, SEC-M10-6 and -7), a full QA audit on the four boards, a release build, the owner signs the final packs, install on the owner's phone, the phone check | release gate | owner |

**Every band of every island is built:** the six lands (Bands A and B are there; Band C is part 3) and the Languages island's three courses (Band A part 1, Band B part 2, Band C part 4).

Parts 1, 2 and 3 run side by side: the lands' Band C and the language courses touch different files. Part 4 follows part 2 (L6 builds on L5). Part 6 starts only when every text is final, and part 7 only after part 6, so every line is voiced once.

## The owner's order (2026-11-07)

1. Finish part 0 (QA of Band C step 1 and of Languages Band A), then the owner signs one pack and installs the build on his phone.
2. **L5 leftovers** (part 2): LS06 build a word, LS08 follow and echo, the co-play cards, the catalogue, then the Band B lessons of the three courses and their packs.
3. **B-29 steps 5 to 9** (part 5): the parent screens, the look by age, the languages' gates, Today's Adventure, the guard tests.
4. Then **Band C of the six lands** (part 3, C2 to C9), and the rest in the order of the table (L6 and Languages Band C, the head-of-line fix, the Hebrew sweep, the voices, the release).

## The owner's order, revised (2026-11-08): a working app to try with children first

Before any new feature (the L5 leftovers, Band C C2 to C9, L6 wait):
1. Merge the signed release (starter 0.11.0, lang-eng/heb/rus 0.1.0; branch `content-release`).
2. **The full text sweep** (part 6, now): every text in the app (lessons, hints, feedback, screens, parent area, the language courses' Hebrew frame), for grammar and vocabulary by the hebrew-text-editor, and for pronunciation by the voice-and-sound-director (how each voice will say it: pointed words, the lexicon, short listening pilots).
3. **B-29 steps 5 to 9** (part 5).
4. **The voices** (part 7): every line so far, Hebrew and the English and Russian target clips, after the voice pilots for those languages; the owner runs and pays after seeing the counts and cost.
5. Build the app, install it on the owner's phone, and give him an APK to share with test families.

## What only the owner does

1. **Sign the starter pack** whenever its content changes (the pack check fails until then). To keep this rare, content is merged in a few batches, and each batch asks for one signature.
2. **Choose** where a plan leaves the choice to him (C9 of M10, any new Hebrew wording he wants to see).
3. **Run and pay for every voice step** (the pilots and the voicing), after he sees the character count.
4. **Approve** each merge, deploy and the final install.
