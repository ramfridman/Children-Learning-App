# Nitznutz (נִיצְנוּץ)

A Hebrew-only learning app for two children, ages 3–8. Flutter app for Android and iOS, with a small Supabase backend in Frankfurt. Private family project.

## Where things are

| Path | What |
|---|---|
| `docs/PLAN.md` | The product and engineering plan. The source of truth. |
| `docs/milestones/` | One plan per milestone, written and approved before coding. |
| `CLAUDE.md` | Standing rules for every working session. |
| `PROGRESS.md` | Current status, open issues, next step. |
| `app/` | The Flutter app (arrives in M0 Phase D). |
| `supabase/` | Migrations, Edge Functions and their tests (arrives in M0 Phase C). |
| `config/product.json` | The one file with the product name and rebrand-able strings. |
| `design/`, `prototype/` | Design boards, tokens, family character packs, and the HTML prototype. |
| `tools/` | Scripts for CI, hooks and (later) content and voice. |

## One-time setup on Windows

1. Install Git, Node.js LTS, and (from M0 Phase D) Flutter and Android Studio.
2. From the repository folder, install the secret-scanning hook:
   ```
   powershell -ExecutionPolicy Bypass -File tools\install-hooks.ps1
   ```
   It downloads a pinned, checksum-verified `gitleaks`, turns on the pre-commit hook, and runs a self-test. Commits are refused until it is installed.
3. Install the pinned repository tools: `npm ci`. Run the Supabase CLI with `npx supabase ...`. Do not install it globally.

## Rules that matter most

- No secret in the repository, the app, logs or CI output. Vendor keys live only in Supabase secrets and the password manager. `.env` is ignored by Git.
- One milestone at a time, on its own branch. `main` stays green.
- Every new dependency needs the owner's OK and a pinned version; lock files are committed.

See `CLAUDE.md` for the full list.

## CI

Every push runs: a full-history `gitleaks` scan plus a self-test that plants fake secrets and requires them to be caught; a check for forbidden tracked files; and an OSV vulnerability scan of every lock file. More jobs (Flutter, Deno, database tests) are added as the code arrives.
