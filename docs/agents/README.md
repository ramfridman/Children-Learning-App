# The two content agents

Two project agents (in `.claude/agents/`) look after what the children read and hear. They work with each other and with the owner. The owner decides; the agents prepare.

| Agent | Owns | Does not do |
|---|---|---|
| **hebrew-text-editor** | Every Hebrew text: grammar, vocabulary, syntax, nikud, gender and number agreement, who is addressed, spoken or screen-only, and the `voice_text` of every spoken line. | Decide how a line sounds; change the pack or the generators without the owner's OK; spend money. |
| **voice-and-sound-director** | Every sound and voice: character voices, tone, rhythm, pauses, music, effects, ducking, loudness, haptics, the plan and the checks for voicing and re-voicing. | Change the letters of a Hebrew text; run paid generation without the owner's typed count; change app code or the pack without the owner's OK. |

Start one by name in a session (for example "ask the hebrew-text-editor to review the Colours texts"). The main assistant may also hand work to them. They report back to the main assistant, who reports to the owner.

## The one table

`docs/review/hebrew-master.csv` has one row for every text in the app (made by `python tools/hebrew_voice_review.py` from `docs/review/hebrew-review.csv`). Columns: `group`, `source`, `id`, `kind`, `spoken` (yes or no), `text` (the original), `ui_text` (corrected, for the screen), `voice_text` (ready for ElevenLabs; empty when not spoken), `changes` (what and why), `status`, `correction (fill in)` and `comment` (the owner's own words; they are never overwritten). `hebrew-elevenlabs-review.md` and `.csv` list only the rows that changed or are spoken, deduplicated.

## Statuses

`unchanged` (nothing to do, screen-only and correct) or `proposed` (a machine or agent proposal) → `text-ready` (the text editor finished the grammar, the vocabulary and the voice text) → `owner-approved` (the owner approved the text) → `voice-ready` (the voice director gave the direction, in `docs/audio/voice-direction.csv`) → `voiced` (generated, checked, and in a voice pack).

Rows only move forward when the previous owner of the step is done. A row the owner corrects (the `correction (fill in)` column) goes back to the text editor.

## The order of work (the owner's plan, 2026-10-28)

1. All texts are analysed and corrected in the one table. No voice is made while any text is still `proposed`.
2. The owner reviews. The text editor applies the owner's corrections.
3. The voice director designs the voices, tones and sounds, and gives direction for every spoken line.
4. The owner listens to auditions and decides the voices, then sees the character count and the cost and types the number.
5. Everything is voiced once, and the lines that are voiced already are voiced again with the new voices and tones. The voice director checks the result.
6. Only then do the fixed texts go into the pack (a new pack version), together with the new voice packs.

## Rules both agents keep

- `CLAUDE.md` wins. No secret anywhere; devices send ids and numbers, never text; the model only sees placeholders; no child audio is stored or sent; a first name may go to ElevenLabs only inside a line to be voiced.
- Show the character count and the cost before any paid generation, and wait for the owner's typed number. Tests use mocks.
- Original characters only; never imitate a real person's voice.
- They say what they have checked and what they have not. A claim that something sounds right is only made about audio that was measured or listened to by a person.
- When they disagree, the owner decides; each writes its reasoning in the `comment` column or in `docs/agents/`.
