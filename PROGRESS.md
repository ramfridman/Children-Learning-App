# PROGRESS

Read `CLAUDE.md` and this file at the start of every session.

## Status

| Milestone | Status |
|---|---|
| Reading pass over the plan, docs and design bundle | Done |
| M0 Foundations | **Approved 2026-10-25** (`docs/milestones/M0.md`, sections 3a and 3b). Android first; iOS gate (iPad) later. Phase A (owner) mostly done: baseline pushed, Flutter 3.47.8 installed, Supabase region confirmed Frankfurt; Android SDK 36 and licences still to do. Phase B (guardrails) and Phase C part 1 (database, pgTAP) done and green in CI. Phase C part 2 (gateway) in progress. |
| M1–M9 | Not started |

## Done

- Read the plan, docs, design bundle and family packs (prototype only opened, not read in full).
- M0 plan written and approved with changes.
- Phase C part 1: `app` schema, jobs and 79 pgTAP checks, green in CI.
- Phase C part 2 so far: `supabase/functions/_shared/` (base64url, canonical string, signature check with strict DER and on-curve test, body limits and strict schema, quiet error codes, redacted log), 19 Deno tests, shared vectors in `testvectors/signed-request.json`, Deno CI job.
- Phase C part 2 (later steps): common handler, Postgres store, entry points for `signed-ping`, `app-config`, `enroll-challenge`, `pairing-code-create`, `device-list`, `device-revoke`, `device-enroll`; Android Key Attestation verifier with Google roots; JWKS token check; 60 Deno tests plus a DB integration test run in CI as the limited gateway role.
- Accounts: 1Password, Supabase (Frankfurt, ref `ungkvkabqxssggttajfs`), Anthropic Console (workspace, $5 limit, key), ElevenLabs (two keys), Codemagic linked.

## Open issues

- Plan drift to apply in the B5 doc-fix commit: names allowed in spoken lines (ElevenLabs only, never Anthropic); `÷` default with `:` setting; M0 proven on Android first; GitHub secret scanning unavailable on private repos (gitleaks instead); Supabase CLI pinned in repo.
- iOS gate (Swift, Codemagic, TestFlight, Apple Developer enrolment, iPad) is deferred. Must pass before any iPad build is relied on, and before M6 at the latest.
- Child-device test needs a second Android device, or the emulator with the dev allowlist. Waiting for the owner's answer.
- Character pool size (sets ElevenLabs cost): decide in M4.
- To settle before the milestone that needs them: weekly-garden wording (parent-only), retention scheduling (M3), short server name per pack in `character-register` (M4).

## Waiting on the owner

## Next step

Claude: `device-pair` (child device, one-time sign-in via the Auth admin API), iOS attestation stays deferred to the iOS gate, the `verify_jwt` experiment and deploy steps (Phase H), then the Flutter harness (Phase D) on the owner's Android phone.
