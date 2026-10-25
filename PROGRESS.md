# PROGRESS

Read `CLAUDE.md` and this file at the start of every session.

## Status

| Milestone | Status |
|---|---|
| Reading pass over the plan, docs and design bundle | Done |
| M0 Foundations | **Approved 2026-10-25** (`docs/milestones/M0.md`, sections 3a and 3b). Android first; iOS gate (iPad) later. Phase A (owner: baseline push, Flutter, Android phone, Cloudflare/Firebase/Rive) and Phase B (Claude: repo guardrails) in progress. |
| M1–M9 | Not started |

## Done

- Read the plan, docs, design bundle and family packs (prototype only opened, not read in full).
- M0 plan written and approved with changes.
- Accounts: 1Password, Supabase (Frankfurt, ref `ungkvkabqxssggttajfs`), Anthropic Console (workspace, $5 limit, key), ElevenLabs (two keys), Codemagic linked.

## Open issues

- Plan drift to apply in the B5 doc-fix commit: names allowed in spoken lines (ElevenLabs only, never Anthropic); `÷` default with `:` setting; M0 proven on Android first; GitHub secret scanning unavailable on private repos (gitleaks instead); Supabase CLI pinned in repo.
- iOS gate (Swift, Codemagic, TestFlight, Apple Developer enrolment, iPad) is deferred. Must pass before any iPad build is relied on, and before M6 at the latest.
- Child-device test needs a second Android device, or the emulator with the dev allowlist. Waiting for the owner's answer.
- Character pool size (sets ElevenLabs cost): decide in M4.
- To settle before the milestone that needs them: weekly-garden wording (parent-only), retention scheduling (M3), short server name per pack in `character-register` (M4).

## Next step

Owner: push the baseline to `main`, install Flutter and Android SDK pieces, connect the Android phone, finish Cloudflare/Firebase/Rive. Claude: push Phase B guardrail files on branch `m0-foundations` as soon as `main` exists.
