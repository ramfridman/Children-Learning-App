# Listening sheet: Russian course voices (pilot)

Folder: `C:\Users\ramfr\nitznutz-voice\auditions\ru-pilot`. Spec: `pilot.json` (134 clips; voices `ru-female` and `ru-male`). 21 items, about 25 minutes.

**Who listens.** Items **1 to 19 need a native-level Russian listener**: someone who hears a hard/soft consonant, the vowel ы against и, and a stress or a vowel reduction that is wrong. The owner cannot judge these. Items **20 and 21 are Hebrew: the owner judges them.**

Play `<name>.mp3`. **ok** = right, **x** = wrong, **?** = unsure.

## Part 1. One sound alone, the female voice (what form to use)

Listen for the sound alone: steady, no added vowel, not the letter name ("эм"). **S** = the letter(s), **I** = IPA, **N** = none is clean.

| # | Sound | Play | Pick |
|---|---|---|---|
| 1 | м | `ru-female-01-snd-m`, `ru-female-01-snd-m-ipa` | S / I / N |
| 2 | мь (soft) | `ru-female-01-snd-mj` | ok / x |
| 3 | с: the sound alone against the stretched-word forms | `ru-female-01-snd-s` (ссс), `ru-female-01-str-som-1` (с-с-сом), `ru-female-01-str-som-2` (со-о-ом), `ru-female-01-str-som-3` (сом-м-м) | S / 1 / 2 / 3 / N |
| 4 | щ (and ш) | `ru-female-01-snd-sh`, `ru-female-01-snd-shch`, `ru-female-01-snd-shch-ipa` | S / I / N (for щ) |
| 5 | ы | `ru-female-01-snd-y`, `ru-female-01-snd-y-ipa` | S / I / N |
| 6 | а (a vowel) | `ru-female-01-snd-a` | ok / x |
| 7 | к (a stop) | `ru-female-01-snd-k` | ok / x (**x** is expected: a stop alone gets a vowel) |

## Part 2. Syllables

| # | Play | Listen for | Answer |
|---|---|---|---|
| 8 | `ru-female-02-syl-ma`, `ru-female-02-syl-my`, `ru-female-02-syl-mi` | "мы" has a true ы, not "ми"; the three are different | ok / x |
| 9 | `ru-female-02-syl-la`, `ru-female-02-syl-lja` | hard "ла" against soft "ля" | ok / x |
| 10 | `ru-female-02-slide-mma` | "ммма": m held, then merged into the syllable | ok / x |

## Part 3. Pairs that must differ (a failure here is fatal)

| # | Play | Listen for | Answer |
|---|---|---|---|
| 11 | `ru-female-03-mp-luk`, `ru-female-03-mp-ljuk` | лук / люк: hard against soft | ok / x |
| 12 | `ru-female-03-mp-bil`, `ru-female-03-mp-byl` | бил / был: и against ы | ok / x |
| 13 | `ru-female-03-mp-mal`, `ru-female-03-mp-mjal` | мал / мял | ok / x |

## Part 4. Stress and vowel reduction (does the voice honour the stress mark?)

The mark is the accent on the vowel (U+0301). **M** = right with the mark, **U** = right without it, **I** = right with IPA, **B** = right both with and without, **N** = wrong in all.

| # | Play | Listen for | Pick |
|---|---|---|---|
| 14 | `ru-female-04-w-moloko`, `ru-female-04-w-moloko-nomark`, `ru-female-04-w-moloko-ipa` | молоко: stress on the last syllable, the first two o's reduced ("мълако́"), not three full o's | M / U / I / B / N |
| 15 | `ru-female-04-w-ruka`, `ru-female-04-w-ruka-nomark` | рука: stress on ка | M / U / B / N |
| 16 | `ru-female-04-sen-1` | "Я ви́жу ко́шку." calm, natural | ok / x |
| 17 | `ru-female-04-call-ruka` | calling "ру-ка́-а": the stress stays on ка | ok / x |

## Part 5. The male voice (the puppet Саша) and the pair

| # | Play | Listen for | Answer |
|---|---|---|---|
| 18 | `ru-male-04-sen-2`, `ru-male-04-sen-1` | "Э́то кот.", "Я ви́жу ко́шку." natural, clear | ok / x |
| 19 | `ru-female-04-sen-1`, then `ru-male-04-sen-1` | would a child take them for a teacher and her friend? similar loudness and pace | ok (a pair) / x |

## Part 6. The owner: can the Russian voices also say the Hebrew frame? (Hebrew)

**G** = natural Israeli Hebrew, I would use it; **A** = accented but fine for a child; **B** = bad.

| # | Play | Answer |
|---|---|---|
| 20 | `ru-female-05-he-long`, `ru-female-05-he-your-turn` | G / A / B |
| 21 | `ru-male-05-he-long` | G / A / B |

**Answer, copy and fill:**

```
1:_ 2:_ 3:_ 4:_ 5:_ 6:_ 7:_ 8:_ 9:_ 10:_ 11:_ 12:_ 13:_ 14:_ 15:_ 16:_ 17:_ 18:_ 19:_ 20:_ 21:_
```

## What your answers change

| Items | Answer | Then |
|---|---|---|
| 1 to 5 | a letter | the `say` form for that sound in `russian/pronunciation.csv` (decision D2). **N** means the app shows that sound only inside a syllable or a word (the fallback of `voices.md` section 6) |
| 6, 7 | x | а: the syllable form; к: expected, a stop is never alone |
| 8 to 10 | x | the syllable falls back to the word form |
| 11 to 13 | x | the voice fails a fatal check (hard/soft, ы/и): I propose a replacement voice before any Russian clip is voiced |
| 14, 15 | M / B | the stress mark is kept in all 232 clips (as now). **U** alone: the marks are dropped. **I**: the clip is sent as IPA. **N**: the words get a respelling the pilot passes |
| 16 to 18 | x | the line is respelled or the stress changed |
| 19 | x | the male voice is changed, or the puppet's 11 lines are said by the female voice |
| 20, 21 | G on both | option A is allowed: the native voices may say the Hebrew frame too. Anything else: **option B**, nitzi says the Hebrew frame (the default) |
