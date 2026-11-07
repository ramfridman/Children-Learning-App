# The full release: every band of every island, ready for the owner's phone

**The owner's goal (2026-11-07):** "I want to finish up all the Bands of all the islands and L5. Once everything is done we will do a full sweep on all the hebrew texts so we make sure they are written and sound (pronounce) in the right way. My goal is to make the app perfectly ready to install on my phone."

This file orders the work that is left. Each part already has its own approved plan, named below; nothing here changes those plans. The team, the QA rule (once per finished feature or batch) and the security rules of `CLAUDE.md` apply as always.

## What is left

| # | Part | Plan (approved) | Size |
|---|---|---|---|
| 0 | **Close the open work**: the riddles-island sweep, the Hebrew review (PR 39), M10 C1 | sweep-2026-11-06, M10 | 3 PRs |
| 1 | **Languages Band A**: ENG-1, HEB-1, RUS-1 and the language packs, so the Languages island can be played | frame.md §6, `docs/languages/*/band-a-content.md` | 3 courses |
| 2 | **L5**: the Band B activity types (sound boxes, change one part, blend slide, build a word, follow and echo, co-play cards), then ENG-2, HEB-2, RUS-2 | L5.md | 6 templates, 76 skills |
| 3 | **M10**: Band C of the six lands, C2 to C9 (C9 needs the owner's choice) | M10.md | about 1,100 activities |
| 4 | **L6**: the Band C activity types, then ENG-3, HEB-3, RUS-3 | L6.md | 3 templates, about 80 skills |
| 5 | **B-29 steps 5 to 9**: the parent's month and year and school stage screens, the look by age, the languages' gates, Today's Adventure | B29.md | 5 steps |
| 6 | **The full Hebrew sweep**: every text read again for grammar, nikud and wording (hebrew-text-editor), and for how the voice will say it (voice-and-sound-director: the pronunciation list, the words kept pointed for the voice, a listening pilot) | owner, 2026-11-07 | every Hebrew line |
| 7 | **The voices**: one voicing batch of every line, planned with its character count and cost; **the owner runs and pays** | B-45 | owner |
| 8 | **The release**: the open security findings (SEC-6, SEC-7, SEC-M10-6 and -7), a full QA audit on the four boards, a release build, the owner signs the final packs, install on the owner's phone, the phone check | release gate | owner |

Parts 1, 2 and 3 run side by side: the lands' Band C and the language courses touch different files. Part 4 follows part 2 (L6 builds on L5). Part 6 starts only when every text is final, and part 7 only after part 6, so every line is voiced once.

## What only the owner does

1. **Sign the starter pack** whenever its content changes (the pack check fails until then). To keep this rare, content is merged in a few batches, and each batch asks for one signature.
2. **Choose** where a plan leaves the choice to him (C9 of M10, any new Hebrew wording he wants to see).
3. **Run and pay for every voice step** (the pilots and the voicing), after he sees the character count.
4. **Approve** each merge, deploy and the final install.
