# The Languages category (B-44)

**Status:** in the plan, not built (owner, 2026-11-03). Plan first: research, then a milestone plan per language, each with the owner's OK before any code.

**Band A packs (2026-11-07):** how the teachers' content becomes the signed `lang-eng`, `lang-heb` and `lang-rus` packs (the authoring files, the generator, signing, bundling, tests) is in `band-a-build.md`.

## What the owner asked for
- A **Languages** category in the child's space with three languages: **English**, **Hebrew** and **Russian**. More may follow.
- The child **chooses which language to learn now**. Each language keeps its own path, progress and mastery; switching never loses anything.
- Each language has a **dedicated teacher agent** who makes sure the curriculum is correct, every character, word and phrase is written properly and pronounced properly, the teaching relies on real, working, evidence-based techniques, and everything fits the child's age and level in that language.
- "This is a major learning area and a very important one, so we must do it properly."

## The teachers
| Language | Agent | What the course is |
|---|---|---|
| English | `english-language-teacher` | A foreign language for Hebrew-speaking children: listening and speaking first, then reading and writing step by step (phonics), placed by level. |
| Hebrew | `hebrew-language-teacher` | The children's first language: oral language growth and early literacy (phonological awareness, letters, nikud, reading and writing). |
| Russian | `russian-language-teacher` | For every learner, from a child new to Russian to a heritage speaker: listening, speaking, reading and writing in Cyrillic, placed by level. |

All three follow the skills `.claude/skills/curriculum-research`, `.claude/skills/lesson-review` and `.claude/skills/pronunciation-spec`. The **curriculum-expert** (head of curriculum) owns the shared frame: the category's place on the map, the engine, bands, mastery and revisits across languages. Hebrew around a lesson (instructions, praise, parent texts) stays with the **hebrew-text-editor**.

## Shared rules (bind every language)
1. **Plan first.** For each language: a research report (`docs/research/`), a syllabus (`docs/languages/<language>/syllabus.md`), then a milestone plan with the skills, templates, voices, fonts and their cost. The owner approves each step.
2. **Correct before shipped.** No text in English or Russian reaches a child without its teacher's approval; no Hebrew without the hebrew-text-editor's. Every spoken item has a pronunciation spec and a listening check (`pronunciation-spec`).
3. **Voices.** Each language has its own teaching voice that speaks natural Hebrew and the target language natively (decision 6), only inside its lessons. No real person's voice is imitated. Claude never runs a paid voice command; the owner runs every paid step.
4. **Direction and fonts.** English and Russian are left to right, in isolated runs inside the right-to-left app. A Cyrillic font (and a Latin teaching font if needed) is approved in principle (decision 1); the design-director chooses it, checks the licence, and shows it to the owner.
5. **Choosing a language.** The child picks a language at the category's entrance; a parent can turn each language on or off in the parent area and see progress per language. No pressure, no streaks, no "you haven't practised".
6. **Child safety** as everywhere (`CLAUDE.md` › Child safety). The microphone, if a language uses speaking practice, opens only on a tap and only when a parent turned voice on; no child audio is stored or sent; an unclear answer is never "wrong".

## The owner's decisions (2026-11-03)
1. **Fonts:** add a Cyrillic font (and a Latin teaching font if needed). The design-director chooses it so it looks good beside Heebo and Secular One, with letter shapes right for teaching young children.
2. **Any child, any level.** The app was started for the owner's children but must be perfect for **any** child, at **any** level, in **any** topic. So each language serves every learner: a child starting from zero, a child who already understands some (for Russian, for example, a heritage speaker who hears it at home), and a child who already reads. Placement decides where a child starts; nothing assumes one family.
3. **Reading and writing in every language.** English and Russian teach listening, speaking, **reading and writing**, step by step from the very basics, each step built on real, researched best practice. The same holds for the Hebrew course.
4. **The Hebrew course is its own course.** The app's interface is Hebrew, but that has nothing to do with learning the Hebrew language: the Hebrew lessons are a separate course (language and literacy), and nothing in the other lands depends on them.
5. **All three languages are built**, each independent of the others; none waits for or relies on another.
6. **Dedicated voices per language that speak both.** The lessons are taught in Hebrew and teach another language, so each language's teaching voice must speak **natural Hebrew and the target language natively**, so the child understands the instruction and hears the language right. These may be new ElevenLabs voice ids (the current ones are for Hebrew). The voice-and-sound-director finds and auditions them (the owner runs and pays for every audition); the language teacher listen-checks the target language, the hebrew-text-editor the Hebrew. If no single voice is excellent in both, the plan proposes the best alternative with samples for the owner.

## What happens next
For each language, in parallel: the research report and the syllabus (all bands, from the first sound to independent reading and writing), then a milestone plan with the templates, voices, fonts and their cost, each with the owner's OK before code.
