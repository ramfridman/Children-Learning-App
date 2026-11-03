# The Languages category (B-44)

**Status:** in the plan, not built (owner, 2026-11-03). Plan first: research, then a milestone plan per language, each with the owner's OK before any code.

## What the owner asked for
- A **Languages** category in the child's space with three languages: **English**, **Hebrew** and **Russian**. More may follow.
- The child **chooses which language to learn now**. Each language keeps its own path, progress and mastery; switching never loses anything.
- Each language has a **dedicated teacher agent** who makes sure the curriculum is correct, every character, word and phrase is written properly and pronounced properly, the teaching relies on real, working, evidence-based techniques, and everything fits the child's age and level in that language.
- "This is a major learning area and a very important one, so we must do it properly."

## The teachers
| Language | Agent | What the course is |
|---|---|---|
| English | `english-language-teacher` | A foreign language for Hebrew-speaking children: listening and speaking first, phonics later (Band C). |
| Hebrew | `hebrew-language-teacher` | The children's first language: oral language growth and early literacy (phonological awareness, letters, nikud, reading and writing). |
| Russian | `russian-language-teacher` | A heritage or a new foreign language (the owner decides): speaking first, literacy in Cyrillic if wanted. |

All three follow the skills `.claude/skills/curriculum-research`, `.claude/skills/lesson-review` and `.claude/skills/pronunciation-spec`. The **curriculum-expert** (head of curriculum) owns the shared frame: the category's place on the map, the engine, bands, mastery and revisits across languages. Hebrew around a lesson (instructions, praise, parent texts) stays with the **hebrew-text-editor**.

## Shared rules (bind every language)
1. **Plan first.** For each language: a research report (`docs/research/`), a syllabus (`docs/languages/<language>/syllabus.md`), then a milestone plan with the skills, templates, voices, fonts and their cost. The owner approves each step.
2. **Correct before shipped.** No text in English or Russian reaches a child without its teacher's approval; no Hebrew without the hebrew-text-editor's. Every spoken item has a pronunciation spec and a listening check (`pronunciation-spec`).
3. **Voices.** Each language is spoken by a native-sounding voice for that language, only inside its lessons; the companion's Hebrew voice speaks the Hebrew around it. No real person's voice is imitated. Claude never runs a paid voice command; the owner runs every paid step.
4. **Direction and fonts.** English and Russian are left to right, in isolated runs inside the right-to-left app. The app allows only Heebo and Secular One today; Cyrillic (and any teaching font for letter shapes) needs a font the owner approves (new asset, licence checked).
5. **Choosing a language.** The child picks a language at the category's entrance; a parent can turn each language on or off in the parent area and see progress per language. No pressure, no streaks, no "you haven't practised".
6. **Child safety** as everywhere (`CLAUDE.md` › Child safety). The microphone, if a language uses speaking practice, opens only on a tap and only when a parent turned voice on; no child audio is stored or sent; an unclear answer is never "wrong".

## Open questions for the owner (before the research starts)
1. **Russian:** a heritage language (someone at home speaks Russian to the children) or a new foreign language? It changes the whole syllabus.
2. **Literacy:** should English and Russian teach reading and writing (from about age 7), or speaking and listening only?
3. **Hebrew lessons:** literacy and language growth for native speakers (as planned above), and should they replace or connect to the Hebrew already spread through the other lands?
4. **Order:** which language is built first?
