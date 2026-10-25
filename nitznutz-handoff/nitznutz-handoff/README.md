# Nitznutz hand-off bundle

This bundle has everything a new Claude Code session needs to build the app. That session can't see the earlier conversation or open the online plan doc, so everything is here as files.

## How to use it
1. Create the private GitHub repository and clone it to `C:\dev\nitznutz` (PLAN.md › Development environment setup, steps 1–5).
2. Copy this bundle's contents into the repository root: `CLAUDE.md`, `docs/`, `design/` and `prototype/`. Keep `PROMPT.md` and `README.md` outside the repo, or delete them after use.
3. Open a terminal in `C:\dev\nitznutz`, start Claude Code, choose the Claude Sonnet model, and paste everything below the line in `PROMPT.md` as your first message.
4. In later sessions, just say "continue". Claude Code reads `CLAUDE.md` automatically and is told to read `PROGRESS.md` first.

## What's inside
- `PROMPT.md`: the first message for the new session.
- `CLAUDE.md`: standing rules that Claude Code loads every session.
- `docs/PLAN.md`: the full product plan, exported from the plan doc on 25 October 2026. Mockup images and diagrams appear as placeholders; the pictures themselves are in `design/renders/`.
- `docs/tech.md`: the detailed technical spec. PLAN.md overrides it where noted.
- `docs/curriculum.md`: the syllabus, misconceptions, templates and lessons.
- `docs/design-spec.md`: the design system and screen specs.
- `design/tokens.json`: colours, sizes and timings, read by the app.
- `design/renders/`: PNG mockups of every board (01–07, 10–36).
- `design/boards/`: the board source files, with exact coordinates.
- `design/assets/`: original character and avatar SVGs.
- `design/family-pack/`: 8 original personal character packs.
- `prototype/index.html`: the playable prototype, for feel and timing.
