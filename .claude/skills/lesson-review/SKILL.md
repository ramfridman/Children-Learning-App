---
name: lesson-review
description: The checklist a Nitznutz subject teacher (maths, computer science, English, Hebrew, Russian) runs on a lesson, unit or batch of activities before it reaches a child - correctness, one right answer, distractors that reveal a named error, hints that change the help, age and level fit, language and script correctness, pronunciation, pictures that teach, child safety. Use when reviewing or auditing content, and before calling any lesson ready.
---

# Lesson review checklist

Review the real content (the unit files in `content/units/`, the generated items in `content/starter/` or the next-pack files), not a summary. Use small scripts for counts and for recomputing answers. Every finding names the item or skill id, the problem, why it matters for the child, the fix, and its severity: **wrong** (a wrong answer, a second right answer, a wrong word or spelling, a wrong pronunciation) > **misleading** (a picture or hint that teaches the wrong idea) > **unfit** (wrong level, too long, too many new things at once) > **weak** (a hint that repeats, a dull distractor).

## 1. Correct
- The right answer is right, recomputed or re-checked by script, not by eye.
- Exactly one answer is right, unless the item says otherwise and the checker accepts all of them.
- The picture matches the item (counts, colours, shapes, the word's meaning).

## 2. Teaches the skill
- The item tests the skill it is tagged with, not something else (reading when the skill is listening; counting when the skill is comparing).
- Each distractor is plausible and wrong for a reason the child could see, and carries the misconception or error it reveals (at least two tagged per activity).
- The hint ladder gives a new kind of help at each step (level 2 changes the representation); "show me" is a real worked example; no hint gives the answer before the ladder allows.

## 3. Fits the child
- Band A: no reading, one instruction at a time, big targets, no left and right words. Band B: short pointed captions at most. Band C: short pointed instructions.
- At most one new idea per item; items per session and session length fit the band; numbers, words and sentences stay in the band's range.
- New content builds on what was taught before (prerequisites met, decodable words use only letters and vowels already taught).

## 4. Language and script (for any language)
- Spelling and grammar are correct; for Hebrew the hebrew-text-editor has approved the wording and nikud; English and Russian are approved by their teacher agent.
- Script check by code: Hebrew text has only Hebrew letters, nikud and the allowed punctuation; Russian only Cyrillic (and ё where it belongs); English only Latin. No look-alike letters from another script.
- Left-to-right text and maths sit in isolated left-to-right runs inside the right-to-left app; arrows, number lines and clocks are never mirrored.

## 5. Pronunciation (every spoken line)
- The line has a pronunciation spec (the `pronunciation-spec` skill) and the voiced clip was listen-checked against it; stress, vowel quality and the hard sounds for Hebrew speakers are right.

## 6. Safe and kind
- No timers, speed, streaks, scarcity, guilt or "you failed"; an unclear spoken answer is never "wrong".
- No personal questions; nothing frightening; no franchise characters; content fits the family's values (no politics, no brand names).

## Output
A review file (`docs/knowledge/<subject>/review-<topic>-<yyyy-mm-dd>.md` or the place the brief names) with the counts checked, every finding by severity, what was NOT checked, and the hand-offs in the team format.
