# Presenting the app by actual age (B-29): design research and recommendation

Design-director, 2026-10-29. This is the presentation half of B-29. The teaching half is `docs/research/age-fit-teaching.md` (curriculum-expert); the two agree on one point in particular: **age in months is computed on the device, and the presentation steps at a few fixed ages, never month by month**. The children's exact ages are not in any file and are not guessed here. Sources are listed in §9, each marked with what I actually read (the full text, or only the abstract or a snippet).

## 0. The answer in one page

1. **Presentation should follow the child's age in months, but in four steps (stages), not a smooth scale.** Research reports changes per year or half-year, not per month (Vatavu 2015; Hiniker 2015, 2016; CDC). The fastest change is between 3 and 3½, when children start following in-app voice prompts and on-screen demonstrations (Hiniker 2015). Smooth scaling would make sizes creep without any benefit, and it would multiply the goldens.
2. **Reading-related settings follow the school stage, not the age.** Decoding pointed Hebrew is taught in grade 1. Whole-word reading comes in grade 2, and text without nikud starts around grade 3 (Share and Bar-On 2018). Two children in the same class can be almost 12 months apart (curriculum-expert §3).
3. **Most of the design is shared by all ages.** Voice first with replay, no timers, a tap alternative for every drag, colour never used alone, nikud with line height 1.7, home in the top corner, nothing in the bottom band. Age changes the *density* (number of choices, steps, words), the *tone* and the *size of the celebrations*. It changes the size of targets only a little.
4. **Today the app hardly varies its look by band at all.** All the band tokens exist (touch, caption, numeral, title, pebble and motion per band), but the child screens size everything from the device only (`ActivitySpec.of(board)`). A 3-year-old and an 8-year-old see the same tiles, text, motion and celebrations. The band changes only the time limits, the session size, the warm-up, the hidden live-tutor caption in Band A and the 2-second mic silence in Band A (§5.3).
5. **Six things are wrong for some age today** (§5.4). The worst are: the question bubble shrinks text down to 14 pt (bad for every age, and worst for new readers), Band A sees full question captions although PLAN says they should be hidden, and phone answer tiles are about 15 mm, below the 2 cm that NN/g gives for children under 9.

## 1. Motor and touch

**What the sources say**
- **Target size.** NN/g gives at least 2 × 2 cm for children under 9, against 1 × 1 cm for adults. It describes fine motor skills as "very limited" at ages 3 to 5 and "limited" at 6 to 8, so precise actions and precise drags should be avoided (Liu 2018).
- **Accuracy grows quickly between 3 and 6.** Touch accuracy improved significantly from age 3 to age 6. Accuracy and speed correlated with finger dexterity, graphomotor and visuospatial skills (Vatavu et al. 2015; I read the dataset page and the abstract only, so I have no per-age numbers).
- **Children aged 5 to 10** miss targets more often than adults. They make "holdover" touches, repeated taps after a touch that was accepted, and miss towards the screen edges. MTAGIC recommends ignoring holdovers, giving a larger hit area than the drawn target, aligning targets to the screen edge, and showing clear feedback that a touch was accepted (Anthony 2019, Table 2).
- **Gestures.** Tap is the most intuitive gesture. Drag and trace work, but children lift the finger part-way, so partial completion should be accepted. Flicks should also work as a tap or drag. Pinch, tilt and multi-touch are hard. A double tap feels unresponsive, so use it only to block accidental navigation. Register a touch on touch-down, not on lift (Sesame Workshop 2012, read in full).
- **Ages 2 to 3** can tap, drag and even long-press. Precise end positions are the problem, which calls for snapping ("boundary detection"), filtering of spurious events and no time-based gestures (Nacher et al. 2015, design guidelines 1 to 6). By age 4, children could do drag and drop, and 4-year-olds did rotation less well than 5-year-olds (both studies as summarised in Anthony 2019).
- **Motor milestones** (CDC, at the 75th percentile): at 3 a child draws a circle when shown how; at 4 holds a crayon between the fingers and thumb; at 5 writes some letters of their name.

**Recommendation by age** (phone / tablet in points; 1 pt is about 0.156 mm on a phone and 0.19 mm on a full-size iPad)

| | 3 | 4 | 5 | 6 | 7 | 8 |
|---|---|---|---|---|---|---|
| Primary answer, drawn | 96 / 112 | 96 / 112 | 88 / 104 | 88 / 104 | 80 / 96 | 80 / 96 |
| Hit area, with slop | ≥ 128 wide (2 cm) | ≥ 128 | ≥ 112 | ≥ 112 | ≥ 104 | ≥ 104 |
| Gap between targets | 24 / 32 | 24 / 32 | 16 / 24 | 16 / 24 | 12 / 16 | 12 / 16 |
| Drag snap radius | 1.5 × target | 1.5 × | 1.25 × | 1.25 × | 1 × | 1 × |
| Gestures | tap; short drag with tap-then-tap | + longer drag | + trace numerals (wide rail) | + reorder | + precise drag, grid path, keypad | same as 7 |
| Ordered tap sequence | up to 3 | up to 3 | up to 5 | up to 8 | with loops | with loops |

- **Do not shrink targets much for older children.** Big targets do not look babyish; drawing style and tone do. A 7-year-old's targets shrink only so that a keypad or 5 choices fit.
- **Shared by all ages:** touch-down feedback within 50 ms; the 300 ms / 24 pt holdover filter; palm rejection; edge targets extend to the edge; no long-press, double tap, pinch or tilt for any content; every drag has a tap-then-tap alternative; partial traces are accepted.

## 2. Perception and cognition

**What the sources say**
- **Prompts.** Children under 3 followed a new gesture only when a live adult showed it. Between 3 and 3½ they improved quickly and could follow in-app audio and on-screen demonstrations. A **visual state change alone (glow, pulse) did not work at any age from 2 to 5** (Hiniker et al. 2015, abstract). Children do not attend to audio alone, so a spoken instruction needs a matching visual, such as the path being highlighted. Put the action at the end of the sentence. Time-outs for games come after 6 to 8 s of inactivity (Sesame 2012).
- **Symbols.** Progress bars and cartoon-hand demos are "entirely inaccessible" under 3. At 3 to 5 they work when they are minimal, not embellished, and when the link is said aloud ("I'll add a star each time you…"). By 4, children did equally well with symbolic and non-symbolic versions (Hiniker et al. 2016, read in full).
- **Feedback.** Children under 6 miss subtle feedback, so it must be exaggerated or spoken. Working memory is small, so the interface should ask them to hold little in mind (Liu, NN/g 2018). Working memory grows roughly linearly with age from 4 to 15 (Gathercole et al. 2004, abstract).
- **Reading.** Ages 3 to 5 do not read, and 6 to 8 read tentatively (Sherwin and Nielsen, NN/g 2019). The ICO says text is "of very limited use" at 0 to 5, and at 6 to 9 you "should not assume" children will engage with written material (ICO Annex B). For 7- to 9-year-olds, a larger x-height made reading 9% faster, and keeping the type size from shrinking added about four months of measured reading age (Wilkins et al. 2009, abstract).
- **Clutter.** In e-books, multimedia that carries the story helps, while hotspots and games distract (Takacs, Swart and Bus 2015, abstract). Embellishment unrelated to the target adds cognitive load (Hiniker 2016).
- **Pacing.** Nine minutes of a fast-paced cartoon immediately lowered the executive function of 4-year-olds (Lillard and Peterson 2011). A 5-year-old pays attention for 5 to 10 minutes to an activity (CDC).
- **Contrast and flashes.** Text contrast of at least 4.5:1 and non-text contrast of 3:1; colour is never the only cue; nothing flashes more than 3 times a second (WCAG 2.2).

**Recommendation by age**

| | 3 | 4 | 5 | 6 | 7 | 8 |
|---|---|---|---|---|---|---|
| Answer choices on screen | 2–3 | 3 | 3–4 | 4 | 4–5 | 5, or a keypad |
| Steps in one instruction | 1 | 1 | 1–2 | 2 | 2–3 | 3 |
| Instruction mode | voice + Nitzi points or demos | voice + demo; a symbol only with a spoken link | voice + caption with word highlight | voice + caption | caption + voice (both automatic) | the same; the parent may choose "read first" |
| Caption (question text) | hidden | hidden by default (open question 3) | ≤ 5 words, nikud | 1 sentence ≤ 7 words | ≤ 2 short lines | ≤ 2 lines |
| Caption size, phone / tablet | — | 26 / 32 | 26 / 32 | 24 / 30 | 22 / 28 | 22 / 28 |
| First idle prompt | 8 s, voice + pointing | 8 s | 12 s | 12 s | 20 s | 20 s |
| Motion: base transition | 450 ms, overshoot 1.12 | 450 | 350, 1.08 | 350 | 280, 1.04 | 280 |
| Moving things at once | 1 focal | 1 | 1 | 1–2 | 2 | 2 |

- **Never shrink a caption below the age's size.** Shorten the text instead (hebrew-text-editor), or give the bubble a second line.
- **Nikud:** full for every age through grade 2. In grade 3, full by default, and the parent can switch to partial (PLAN).
- **Numerals and the child's name** are shown at every age. Sesame recommends showing numerals on screen whenever a character counts.

## 3. Characters, tone and rewards

**What the sources say**
- Familiar characters as hosts or guides give "friendship and fun" (Sesame 2012). Children aged 3 to 6 with stronger emotional ties to a character, and more maths talk with it, learned early maths better (Calvert; the 2016 article read, the 2019 *Child Development* study seen only in a search summary).
- **Process praise** (for effort and strategy) given to 1- to 3-year-olds predicted a liking for challenge at 7 to 8 (Gunderson et al. 2013, abstract and press release).
- Wrong answers are a learning moment: name it gently, restate the goal and give a hint, then highlight the answer (Sesame 2012). Payoffs matter, and they should name the concept the child chose (Sesame 2012).
- Children are "very sensitive" to content that looks younger than them. A 6-year-old called a site "for babies" because of its cartoons and trains (NN/g 2019).
- CDC: at 4 a child "likes to be a helper" and pretends; at 5 follows game rules and takes turns. PLAN already says that 7- to 8-year-olds want challenge, secrets and codes, and dislike anything babyish.

**Recommendation by age**

| | 3 | 4 | 5 | 6 | 7 | 8 |
|---|---|---|---|---|---|---|
| Nitzi's role | a warm friend; the same greeting every time | a friend who needs help ("help Nitzi") | a play partner; pretend and rules | a partner; "big kid" missions; the Hero Squad appears | a teammate; "this one is tricky, want to try?" | the same; codes and secrets |
| Tier-1 (each correct item) | ≤ 0.8 s, voice + sparkle + Nitzi cheers | ≤ 0.8 s | ≤ 0.8 s | 0.6 s | 0.5 s tick + spark + a specific line | 0.5 s |
| Tier-2 (end of activity) | 3 s, Nitzi and the host dance | 3 s | 2.5 s | 2.5 s | 2 s, skip at once | 2 s |
| Praise words | short, the same few lines | short | specific ("you counted every one") | specific | about the strategy ("you counted on from 8") | the same |
| What is collected | stickers | stickers | stickers, the island | + trophies | trophies, codes, golden stars | the same |

- **Shared by all ages:** the same cast and world; process praise; no mocking; "not yet" never ends in loss; Tier 3 stays rare; the same calm wind-down.
- **For 7 and 8:** less bounce (overshoot 1.04), no diminutives or baby talk in the voice, no "sweetie" tone, more humour and more error-spotting with the robot. For 3: repetition is a feature, so the same ritual and the same lines are fine.

## 4. Navigation and layout

**What the sources say**
- Pre-readers rely on spatial, real-world metaphors such as a map. Redundant navigation confuses them, and an in-app back button works when it is prominent (NN/g 2019).
- Keep a menu reachable at all times. Horizontal scrolling is intuitive and vertical scrolling is hard; every important control should be on screen at load (Sesame 2012).
- Keep navigation always visible with familiar icons, and do not use text-only buttons (Google, Designing engaging apps).
- For a pre-literate child, use a voice-over prompt that says to call a parent at the parental gate (Apple, Kids apps).

**Recommendation by age**

| | 3 | 4 | 5 | 6 | 7 | 8 |
|---|---|---|---|---|---|---|
| Map labels | none needed: icon, host and the name voiced on touch | the same; the sign text is decoration | sign text with nikud, ≥ 24 pt | the same | the same, plus "how far along" per land | the same |
| Button labels | voiced on touch (hover-speak) | voiced on touch | voiced + small text | text + voice | text + voice | text + voice |
| Way to the next step | the bottle only (one big call to action) | the bottle | the bottle + lands | free choice | free choice + Trophy Hall | the same |

- **Shared by all ages:** home is the island icon, always in the same top corner, with the "go home?" bubble; the map pans horizontally only; nothing important is in the bottom 24 pt; the Parents button stays grey and adult.

## 5. Recommendation for this app

### 5.1 Steps

**Presentation stage** (from the age in months, computed on the device; boundaries chosen to match the evidence, not birthdays):

| Stage | Age | Why this boundary |
|---|---|---|
| P1 | up to 3;5 | prompts work only with a demo plus voice; symbols need a spoken link (Hiniker 2015, 2016) |
| P2 | 3;6 to 4;11 | follows in-app voice and demos; symbols work by 4 |
| P3 | 5;0 to 6;5 | writes letters, follows game rules (CDC); entering gan hova and grade 1 |
| P4 | 6;6 and up | school age; avoid babyish design (NN/g); in the tables above, 7 and 8 are equal |

**Reading stage** comes from the school stage (curriculum-expert §5.2), not the age: gan means no reading is needed; grade 1 means captions with word highlight; grade 2 means short pointed sentences; grade 3 means two lines and optional partial nikud.

**Why not by month:** no source gives monthly differences. Steps of a few points per month would be invisible to the child and would multiply the goldens (4 stages × 3 devices is already 12 per screen). The curriculum-expert proposes half-year rows for content. Presentation needs only four stages, and the ages in the tables above map onto them.

### 5.2 What every age shares

Voice first and unlimited replay; no timers, countdowns or streaks; a tap alternative for every drag; touch-down feedback within 50 ms; the holdover and palm filters; colour never used alone; nikud at line height 1.7 with Heebo and Secular One only; home in the top corner; nothing in the bottom band; the hint ladder with "I'm not sure"; reduce-motion respected; nothing flashing above 3 Hz; process praise; the same world and cast.

### 5.3 What the existing screens do per band today (read in the code)

- **Size by device only.** `ActivitySpec.of(board)` (`app/lib/child/activity_shell.dart`) fixes the tile area, bubble font (26 on a phone, 28 on a tablet) and tile font (56 / 64) per device. `AppLayout.touch`, `answerSize`, `answerGap` and `pebbleSize` (`app/lib/design/layout.dart`) are band-aware, but no child screen calls them. `TokenType.caption/title/numeral` per band are unused, and `TokenMotion` has no per-band timing in code.
- **What the band does change:** the time limits (`parent_rules.dart`), the session size, warm-up and revisit share (`session_builder.dart`), a hidden live-tutor bubble for Band A (`lesson_controller.dart:266`), the mic silence (2.0 s for A, `lesson_screen.dart:164`), the band sent to the tutor, and nikud checking in packs (C is not checked as pointed).
- **Answer tiles** are about 96 pt high on every device, roughly Band A size for everyone. `maxChoices` is in the tokens but is not enforced by the UI; the number of options comes from the content.
- **The home map** has land signs at 18 pt weight 700, button labels at 14 pt weight 700, and stickers and hall pebbles drawn at 48 pt with a 12 pt slop.
- I did not find an idle ladder (8 / 15 / 30 s) in `app/lib/play`.

### 5.4 Where the current design is wrong for an age

1. **The question bubble shrinks text down to 14 pt** (`ActivityFrame.fitFont`, `min = 14`). That is below every band's caption size. For pointed text it makes the marks tiny, and it is worst for new readers (Wilkins 2009). **Fix:** set the floor to the stage's caption size, and shorten long texts instead (hebrew-text-editor), or let the bubble grow to a second line.
2. **Band A sees the full question caption.** PLAN says Band A captions are hidden by default, but `bubbleText` is shown for every band. This is harmless at 4 and useless at 3 (open question 3).
3. **Phone answer tiles are about 15 mm**, below NN/g's 2 cm for children under 9. A 3- or 4-year-old on a phone needs at most 3 choices so that each hit area can be at least 128 pt wide. The tablet already passes (112 pt is about 21 mm).
4. **Home map labels** at 18 pt and 14 pt weight 700 break §9.4 for pointed text (below 24 pt, Heebo 500 at most). They are too small for a 6-year-old reader, and a 3-year-old does not need them. The 48 pt drawn pebbles are below the 64 / 56 pt drawn minimum of §6.1; the hit area of 72 pt is fine.
5. **Idle prompts that only pulse** (spec §6.3, at 8 s) do not work for ages 2 to 5 (Hiniker 2015). The first prompt must be voice plus Nitzi pointing.
6. **The 7- to 8-year-old gets Band A pacing and size everywhere.** Overshoot, celebration length and density are the same as for a 3-year-old, which is the "babyish" risk (NN/g 2019).

## 6. Risks

- **Age labelling.** Never show an age, band or "little ones" mode in the child's space. Siblings on one device see the same world. Only the density and tone differ, and no screen compares the children. The profile picker uses the largest (P1) sizes, because anyone may tap it.
- **Babyish for older children.** The risk is in the tone, voice pitch, bounce, celebration length and too few choices, not in the size of targets. Test P4 screens with the 7- or 8-year-old, if there is one, before calling them done.
- **Too fast for younger children.** Watch idle prompts that come too early, several things moving at once, celebrations that cover the item, and voice lines that are too long. Keep one focal motion for P1 and P2.
- **Phones versus tablets.** All sizes are physical (mm). The phone is the constraint for P1: answer tiles about 15 mm and a 330 × 128 pt stage. Recommend the tablet for the youngest when the family has one (open question 5).
- **The birthday step.** No jump in the middle of a session:
  - A new stage applies at the start of the next session after the boundary month, never mid-activity.
  - Changes come in over about two weeks: first the tone and the text, then the number of choices, and last the sizes and motion.
  - Nothing the child relies on is removed. Replay, voice and "I'm not sure" stay forever.
  - **A guard:** if, after a step up, mis-taps or not-yet answers clearly rise (the thresholds are for the app-developer and curriculum-expert to set), the presentation quietly steps back, and the parent sees it in plain Hebrew.
  - The parent can always override the stage per child.
- **Privacy.** Presentation needs only the stage, computed on the device. The exact day of birth is not needed for anything in this file (security-engineer).

## 7. Open questions for the owner (my recommendation first)

1. **Four presentation stages from age in months, or a separate value per year?** Recommendation: four stages (P1 to P4). Per-year values add goldens and no visible benefit.
2. **Should reading settings follow the school stage that the parent confirms?** Recommendation: yes. It is the same field the curriculum-expert proposes, and age alone mislabels the youngest in a class.
3. **Captions for the youngest:** hidden at 3, and also hidden by default at 4 (the parent can turn them on)? Recommendation: hidden up to 4;11, shown from 5. Numerals and the name are always shown.
4. **A "growing up" moment when a stage changes:** a short Nitzi scene ("look how you've grown, here's a new path") or a silent change? Recommendation: a short scene with no reward attached. With month and year only, it plays at the first session of the month after the boundary.
5. **The 3-year-old on a phone:** accept 2 to 3 big choices on the phone, or prefer the tablet for that child? Recommendation: allow the phone with at most 3 choices, and suggest the tablet in the parent area.
6. **A parent override per child** ("younger / automatic / older" presentation)? Recommendation: yes, in the parent area, defaulting to automatic.
7. **Who enforces the number of choices?** Recommendation: content is written per stage (curriculum-expert), and the UI caps it as a safety net.

## 8. What this file did not do

There is no art, no code and no mock in this file. No screen was rendered for this task, so I looked at no PNG. All findings about the code come from reading `app/lib` in `D:\nitznutz-b26`. Values marked as recommendations are design judgment built on the sources. In particular, **no study gives a number of answer choices per age**; those values come from working memory, the PLAN bands and Sesame's "large and isolated hot spots".

## 9. Sources (opened on 2026-10-29)

Read in full, or the parts cited:
- Sesame Workshop, *Best Practices: Designing Touch Tablet Experiences for Preschoolers*, 2012. PDF via the Joan Ganz Cooney Center: https://joanganzcooneycenter.org/wp-content/uploads/2020/02/SesameWorkshop-2012.pdf (full text read).
- L. Anthony, *Physical Dimensions of Children's Touchscreen Interactions: Lessons from Five Years of Study on the MTAGIC Project*, Int. J. Human-Computer Studies, 2019 (preprint): https://init.cise.ufl.edu/wp-content/uploads/sites/378/2019/03/anthony-et-al-IJHCS2019-MTAGIC-final-preprint.pdf (Table 2 and the related-work section read).
- A. Hiniker et al., *Hidden symbols: How informal symbolism in digital interfaces disrupts usability for preschoolers*, Int. J. Human-Computer Studies 90, 2016: https://faculty.washington.edu/alexisr/HiddenSymbols.pdf (abstract, results and design implications read).
- V. Nacher et al., *Multi-touch gestures for pre-kindergarten children*, Int. J. Human-Computer Studies 73, 2015, author version: https://riunet.upv.es/bitstream/10251/64752/3/VersionAutor.pdf (results and design guidelines read).
- F. Liu, *Design for Kids Based on Their Stage of Physical Development*, Nielsen Norman Group, 2018: https://www.nngroup.com/articles/children-ux-physical-development/
- F. Liu, *Designing for Kids: Cognitive Considerations*, Nielsen Norman Group, 2018: https://www.nngroup.com/articles/kids-cognition/
- K. Sherwin and J. Nielsen, *Children's UX: Usability Issues in Designing for Young People*, Nielsen Norman Group, 2019: https://www.nngroup.com/articles/childrens-websites-usability-issues/
- CDC, *Developmental Milestones* at 3, 4 and 5 years, Learn the Signs. Act Early., updated 2026: https://www.cdc.gov/act-early/milestones/3-years.html (also `4-years.html` and `5-years.html`).
- ICO (UK), *Age appropriate design code, Annex B: Age and developmental stages*: https://ico.org.uk/for-organisations/uk-gdpr-guidance-and-resources/childrens-information/childrens-code-guidance-and-resources/age-appropriate-design-a-code-of-practice-for-online-services/annex-b-age-and-developmental-stages/
- NAEYC and Fred Rogers Center, *Technology and Interactive Media as Tools in Early Childhood Programs Serving Children from Birth through Age 8*, 2012: https://www.fredrogersinstitute.org/files/resources/16/NAEYC-FRC-Position-Statement.pdf (the principles on age- and individually-appropriate use read).
- Google for Developers, *Designing engaging apps* (Building for kids), no date: https://developers.google.com/building-for-kids/designing-engaging-apps
- Google Play, *Teacher Approved* criteria: https://google.play/business/programs/teacherapproved/
- Apple, *Design safe and age-appropriate experiences* (Kids apps): https://developer.apple.com/app-store/kids-apps/
- W3C, *WCAG 2.2*, Recommendation, 12 December 2024: https://www.w3.org/TR/WCAG22/
- S. Calvert, *Children's favorite media characters as teachers*, Bold (Jacobs Foundation), 2016: https://boldscience.org/childrens-favorite-media-characters-as-teachers/
- Joan Ganz Cooney Center, *The App Fairy talks to Toca Boca*, 2018: https://joanganzcooneycenter.org/?p=18640 (Toca's approach: no words on toys, constant testing with children.)

Abstract, author page or summary only (the claims above are limited to what these say):
- R.-D. Vatavu, G. Cramariuc and D. M. Schipor, *Touch interaction for children aged 3 to 6 years*, IJHCS 74, 2015; dataset page: https://raduvatavu.usv.ro/projects/ChildrenTouchInput (no per-age numbers seen).
- A. Hiniker et al., *Touchscreen prompts for preschoolers*, IDC 2015 (abstract via https://www.sciweavers.org/node/356413; lab page https://depts.washington.edu/chilllab/?p=186).
- S. Gathercole et al., *The structure of working memory from 4 to 15 years of age*, Developmental Psychology 40, 2004: https://pubmed.ncbi.nlm.nih.gov/14979759/
- A. Wilkins et al., *Typography for children may be inappropriately designed*, J. Research in Reading 32(4), 2009: https://repository.essex.ac.uk/1476/
- O. Takacs, E. Swart and A. Bus, *Benefits and Pitfalls of Multimedia and Interactive Features in Technology-Enhanced Storybooks*, Review of Educational Research 85(4), 2015: https://journals.sagepub.com/doi/pdf/10.3102/0034654314566989
- A. Lillard and J. Peterson, *The Immediate Impact of Different Types of Television on Young Children's Executive Function*, Pediatrics 128(4), 2011: https://pmc.ncbi.nlm.nih.gov/articles/PMC9923845
- E. Gunderson et al., *Parent praise to 1- to 3-year-olds predicts children's motivational frameworks 5 years later*, Child Development 84(5), 2013 (abstract and the Temple University release): https://now.temple.edu/news/2013-02-11/praising-effort-toddlers-predicts-positive-attitudes-toward-challenges
- D. Share and A. Bar-On, *Learning to Read a Semitic Abjad: The Triplex Model of Hebrew Reading Development*, J. Learning Disabilities 51(5), 2018: https://cris.haifa.ac.il/en/publications/learning-to-read-a-semitic-abjad-the-triplex-model-of-hebrew-read/

Could not verify:
- Apple's Human Interface Guidelines page on kids (404).
- The Khan Academy Kids help page on its Learning Path (403). A search snippet says the path "will progress according to how your child is doing", which suggests it adapts by mastery rather than age, but I could not read the page.
- No PBS KIDS producer guideline was found.
- The full text of Vatavu 2015 and Hiniker 2015 (only the abstracts were read).
