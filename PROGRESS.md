# PROGRESS

Read `CLAUDE.md` and this file at the start of every session. The next agent's brief is `docs/handoff/next-session.md`.

## Status

| Milestone | Status |
|---|---|
| Reading pass over the plan, docs and design bundle | Done |
| M0 Foundations | **Approved 2026-10-25** (`docs/milestones/M0.md`; build status in its section 11). Android first, iOS gate later. Backend (8 functions) and Flutter harness are written and **green in CI** (6 jobs). **Not yet proven on a real phone or on the live Supabase project.** Branch `m0-foundations`, not merged to `main`. |
| M1–M9 | Not started |

## Done

- Plan, docs and design bundle read; M0 plan written and approved.
- Accounts: 1Password, Supabase (Frankfurt, ref `ungkvkabqxssggttajfs`), Anthropic Console ($5 limit), ElevenLabs, Codemagic (linked, no build).
- Guardrails: gitleaks hook and CI with canary, hygiene check, OSV scan, actions pinned by SHA, Dependabot (actions, npm, pub).
- Database: `app` schema, jobs, 79 pgTAP checks.
- Gateway (Deno): common handler, signed-request check, JWKS token check, rate limits, Postgres store (role `app_gateway`), Android Key Attestation, `device-enroll`, `device-pair`, `pairing-code-create`, `device-list`, `device-revoke`, `signed-ping`, `app-config`, `enroll-challenge`; 67 Deno tests plus a real-database integration test in CI.
- Flutter harness (Android): `dev`/`prod` flavours, Keystore key channel (Kotlin), signed-request client, host allowlist, Supabase Auth client, parent enrolment and child pairing, log scrubber, one dev-only test page, about 50 tests, debug APK built in CI.
- Docs: PLAN.md build-detail bullets, `docs/setup/supabase-deploy.md` (steps 1 to 7, with the email-template step 6b), `M0.md` section 11.

## Open issues

- **Not yet run anywhere real:** the Flutter app has never run on a phone; the gateway has never been deployed. Expect small surprises (Auth email template, Keystore on this Samsung, pooler connection string).
- `verify_jwt` experiment on the live project (M0 task C8): run `signed-ping` with the flag on and off against the publishable key and write the result into PLAN.md. Until then every function has `verify_jwt = false`.
- Google's attestation revocation list is not checked yet. Add before any build leaves the family.
- Release builds are signed with the debug key for now. A real release keystore (and its offline backup) comes before M9.
- Dev harness page is English and dev-flavour only; the prod flavour shows a blank placeholder.
- The emulator child test needs `ALLOW_DEV_ENROLMENT=true`, which must never be set on the cloud project. Options: local Supabase stack with Docker Desktop, or a short deliberate test window with a one-hour row in `dev_device_allowlist`, removed afterwards. The owner may also get a second Android phone.
- iOS gate (Swift, App Attest, `attest/ios.ts`, Codemagic, TestFlight, Apple Developer enrolment, the iPad) is deferred; it must pass before an iPad build is relied on and before M6 at the latest. `cbor-x` is installed for it and unused until then.
- Character pool size (sets ElevenLabs cost): decide in M4. Weekly-garden wording, retention scheduling (M3), and the short server name per pack in `character-register` (M4) are still open.

## Waiting on the owner

- Turn on branch protection for `main` with the six CI checks required (M0 E2).
- Follow `docs/setup/supabase-deploy.md` (steps 1 to 6b), then build and install the dev app on the Samsung, then step 7 (allow-list the app's signing certificate).
- Send the spend-limit screenshots (Anthropic and ElevenLabs consoles) for Phase G.

## Next step

Claude, in the next session: write the owner's numbered PowerShell guide for building and installing the dev app, and run the real-device checks with him (M0 Phase G): parent sign-in and enrolment, `signed-ping` as parent, child pairing, child refused on `device-list`, revoke, reinstall starts clean. Then C8, the closed-schema Data API test, the gitleaks canary on a throwaway branch, merge to `main`, and the M0 report (Done / Proof / Security / Plan drift / Needs you / Next).
