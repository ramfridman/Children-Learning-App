# Stage 2 text for your approval (before voicing)

`owner-approval-stage2.csv` lists every Hebrew text of Stage 2 (the five lands and their re-cut items) that waits for you. Nothing in it is approved: the editor finished each text (`text-ready`), and a voice is made only after you say yes. Open it in Excel or Google Sheets (UTF-8, right to left is fine).

## How to read a line

One line is one **distinct text**; `rows` says in how many places of the app it stands (the same hint in ten items is one line with `rows` 10). Lines are sorted by land (Counting Hills, Market Village, Riddle Grotto, Colour Bay, Robot Harbour), then by speaker (the host first, then the narrator and companion), then re-opened lines before new ones.

| Column | Meaning |
|---|---|
| `no` | the line's number, S2-0001 and on |
| `land`, `speaker` | where it is and who says it: the host of the land (Nekudi, Pnina, Timi, Goni, Tza'adon), or the narrator / companion. A label, a screen-reader text or a taught word is listed with the speaker of its own screen. |
| `kind` | `re-opened`: you approved a different text at this place before, the item was re-cut and the place now holds the text in `new text`. `new`: nothing was approved at this place before. |
| `what` | the part of the screen: prompt, hint 1 to 3, right answer, wrong answer, Show line, host hand-over, bin label and so on (with how many times) |
| `rows`, `status` | how many places; `text-ready` (finished by the editor) or `proposed` |
| `same text already approved elsewhere (rows)` | a number means you have already approved exactly this text in that many other places (for example `בּוֹאוּ נְנַסֶּה שׁוּב.`). Such a line is a quick yes. |
| `old text (re-opened rows)` | what was approved at this place before (the first text, when several) |
| `new text (screen)` | the text with its nikud, as the child sees it |
| `voice text` | what the voice will say (plain spelling; the number words keep their nikud; no `!`) |
| `examples` | up to three places (file and part) to find it |
| `approve (fill in: yes / no)`, `correction (fill in)` | yours: `yes`, or `no` and the text you want |

A `yes` on a line approves that text in every place it stands, including the screen-reader copy of a prompt. Lines you leave empty stay as they are.

## What is in it

- **1,368 lines, 3,203 rows.** 899 lines (1,606 rows) are `re-opened`; 469 lines (1,597 rows) are `new`.
- 445 lines (1,404 rows) carry a text you already approved in another place: they are the quick ones. The other 923 lines are fresh to you.
- Hosts: Nekudi 125 lines, Pnina 98, Timi 76, Goni 53, Tza'adon 29 (their Show lines, predict questions, hand-overs and lead-ins). Narrator and companion: Counting Hills 408, Market Village 276, Riddle Grotto 136, Colour Bay 141, Robot Harbour 26.

## What is not in it

- The Shape Forest pilot's texts (Kubi and the shapes), which the editor finished earlier and which still wait for you.
- The 64 app screens (`he.dart`) of the other agents.
- Lines that stay approved: a text you approved that did not change.

## What happens next

You send the file back. The editor applies your answers: `yes` rows become `owner-approved`, a correction goes back to the editor. Only owner-approved rows are voiced, and you type the character count yourself before any paid step.
