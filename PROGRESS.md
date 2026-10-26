# PROGRESS

Read `CLAUDE.md` and this file at the start of every session. The next agent's brief is `docs/handoff/next-session.md`.

## Status

| Milestone | Status |
|---|---|
| Reading pass over the plan, docs and design bundle | Done |
| M0 Foundations | **Done, merged to `main` 2026-10-26** (approved 2026-10-25; see `docs/milestones/M0.md`, section 11). Android first, iOS gate later. Backend (8 functions) and Flutter harness are **green in CI** (6 jobs) and **proven on the owner's Samsung against the live Supabase project** for the parent device. Reinstall check done. Left: spend-limit screenshots and the owner's confirmation of the M0 report. Branch `m0-foundations`, not merged to `main`. |
| M1 App shell and design system | **Done and merged to `main` on 2026-10-26** (CI green; child screens match the design boards, checked by 16 geometry tests). The on-phone checks (install, wrong-PIN lock-outs, database file pulled with adb, Argon2id timing) are still to do when the Samsung is plugged into the PC. The Hebrew child strings await the owner's review. |
| M2 Content system and first activity | **Done and merged to `main` on 2026-10-26** (CI green, all six jobs; report in `docs/milestones/M2.md` section 11). The owner chose to continue without testing on the phone; the on-phone checks (`docs/setup/android-device-checks.md` section 6) and the Hebrew review come later. |
| M3 Learning engine | **Plan written, waiting for the owner's OK** (`docs/milestones/M3.md`, branch `m3-learning-engine`). No code yet. |
| M4–M9 | Not started |

## Done

- Plan, docs and design bundle read; M0 plan written and approved.
- Accounts: 1Password, Supabase (Frankfurt, ref `ungkvkabqxssggttajfs`), Anthropic Console ($5 limit), ElevenLabs, Codemagic (linked, no build).
- Guardrails: gitleaks hook and CI with canary, hygiene check, OSV scan, actions pinned by SHA, Dependabot (actions, npm, pub).
- Database: `app` schema, jobs, 79 pgTAP checks.
- Gateway (Deno): common handler, signed-request check, JWKS token check, rate limits, Postgres store (role `app_gateway`), Android Key Attestation, `device-enroll`, `device-pair`, `pairing-code-create`, `device-list`, `device-revoke`, `signed-ping`, `app-config`, `enroll-challenge`; Deno tests plus a real-database integration test in CI.
- Flutter harness (Android): `dev`/`prod` flavours, Keystore key channel (Kotlin), signed-request client, host allowlist, Supabase Auth client, parent enrolment and child pairing, log scrubber, one dev-only test page, 58 tests, debug APK built in CI.
- Docs: PLAN.md build-detail bullets, `docs/setup/supabase-deploy.md` (steps 1 to 7, with the SMTP step 6a and email-template step 6b), `docs/setup/android-device-checks.md`, `M0.md` section 11.
- **Phase G on the owner's Samsung (SM-S938B), 2026-10-25:** gateway deployed to the live project. Email-code sign-in, parent enrolment with Key Attestation (StrongBox), `signed-ping` (role parent), `app-config` and `device-list` all work. Found and fixed on the way: the gateway's database role password (`28P01`), and Google's P-384 keys signing with SHA-256, which the Edge runtime's WebCrypto refuses (`_shared/ecdsa.ts` over `@noble/curves`, tested against OpenSSL signatures and a real OpenSSL chain). Log reasons for unexpected errors now carry a short code (`internal:<code>`, `malformed:<stage>:<class>`), never a message.
- **C8 `verify_jwt` experiment:** done, result in PLAN.md (works with this project's keys, adds little, stays off).
- **Closed schema:** `tools/data-api-closed-check.ps1` run as a signed-in user: 15 of 15 checks pass (every `app` table, insert and function refused with `PGRST106`; storage has no buckets and refuses writes).
- **Canary:** a planted fake key on a throwaway branch was refused by the pre-commit hook; CI scans the full history and self-tests the scanner on every push.

- **M2 (2026-10-26):** schemas and validator (61 broken-file cases), canonical zip, Ed25519-signed packs, pack builder (`app/tool/pack_builder.dart`), installer with hidden packs and rollback, database v2 (`installed_pack`, `attempt`), lesson player and templates (`count_tap`, `tap_answer`, `give_n`), the butterflies lesson as a signed pack, goldens for every step, dev-page pack tools, on-phone steps in `docs/setup/android-device-checks.md` section 6. The signing key is at `%USERPROFILE%
itznutz-secretspack-signing.key` (outside the repo).

## Open issues

- **Signing key backup:** `pack-signing.key` exists only on this PC. The owner is away from it; he will save it in 1Password when he is next at the PC. Do not delete it. If the PC were lost before then, a new key means rebuilding the starter pack and shipping an app with the new public key.
- **M2 on-phone check** (play the lesson; damaged packs refused) waits for the Samsung to be plugged in; same sitting as the M1 on-phone checks.
- Packs are proven again when loaded, which reads the whole pack into memory; fine for the 37 KB starter, to be made lazy when packs hold recordings (M4).

- **Child-device pairing on hardware is not proven.** The owner's children share parent phones and a tablet, so the main model is a parent-role device with a PIN-gated parent area (M1, PLAN.md line 81). The `child` role is for a kid-only device; its server rules are covered by automated tests. Hardware proof (a second phone, or Samsung Secure Folder, which adb cannot install into) is deferred by the owner's choice. The emulator route needs `ALLOW_DEV_ENROLMENT=true`, which must never be set on the cloud project.
- **Branch protection is unavailable:** GitHub refuses it for a private repo on the free plan (needs GitHub Pro or a public repo). Owner to decide. Until then: merge only with all six jobs green.
- The live project exposes `public` and `graphql_public` (Supabase default); the plan said `public` only. Harmless for `app`; noted as drift.
- Google's attestation revocation list is not checked yet. Add before any build leaves the family.
- ECDSA fallback now uses the audited `@noble/curves` 2.0.1 (approved 2026-10-26); the hand-written verifier is gone.
- Release builds are signed with the debug key for now. A real release keystore (and its offline backup) comes before M9.
- Dev harness page is English and dev-flavour only; the prod flavour shows a blank placeholder.
- iOS gate (Swift, App Attest, `attest/ios.ts`, Codemagic, TestFlight, Apple Developer enrolment, the iPad) is deferred; it must pass before an iPad build is relied on and before M6 at the latest. `cbor-x` is installed for it and unused until then.
- Character pool size (sets ElevenLabs cost): decide in M4. Weekly-garden wording, retention scheduling (M3), and the short server name per pack in `character-register` (M4) are still open.

## Waiting on the owner

- Save the pack signing key in 1Password (next time at the PC); on-phone checks for M1 and M2; Hebrew review; confirm "OK to M3" (plan written).
- Spend-limit screenshots (Anthropic and ElevenLabs consoles).
- Confirm M0 after the report (then Claude merges `m0-foundations` into `main`).

- 2026-10-26: all 8 functions redeployed to the live project by Claude (audited `@noble/curves` is live). It has not yet run against a real attestation; the next enrolment on the phone will exercise it.

## Next step

Claude: wait for the owner's "OK to M3" (or changes to `docs/milestones/M3.md`), then build M3 on `m3-learning-engine`. Do not code M3 before that.
