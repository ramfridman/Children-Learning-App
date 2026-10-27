# PROGRESS

Read `CLAUDE.md` and this file at the start of every session. The next agent's brief is `docs/handoff/next-session.md`.

## Status

| Milestone | Status |
|---|---|
| Reading pass over the plan, docs and design bundle | Done |
| M0 Foundations | **Done, merged to `main` 2026-10-26** (approved 2026-10-25; see `docs/milestones/M0.md`, section 11). Android first, iOS gate later. Backend (8 functions) and Flutter harness are **green in CI** (6 jobs) and **proven on the owner's Samsung against the live Supabase project** for the parent device. Reinstall check done. Left: spend-limit screenshots and the owner's confirmation of the M0 report. Branch `m0-foundations`, not merged to `main`. |
| M1 App shell and design system | **Done and merged to `main` on 2026-10-26** (CI green; child screens match the design boards, checked by 16 geometry tests). The on-phone checks (install, wrong-PIN lock-outs, database file pulled with adb, Argon2id timing) are still to do when the Samsung is plugged into the PC. The Hebrew child strings await the owner's review. |
| M2 Content system and first activity | **Done and merged to `main` on 2026-10-26** (CI green, all six jobs; report in `docs/milestones/M2.md` section 11). The owner chose to continue without testing on the phone; the on-phone checks (`docs/setup/android-device-checks.md` section 6) and the Hebrew review come later. |
| M3 Learning engine | **Done and merged to `main` on 2026-10-26** (CI green, all six jobs; report in `docs/milestones/M3.md` section 11). The simulator names the planted gap within 3 probes in 96.2% of 1,000 invented children (history on 80% of skills; 91.0% at 50%, 51.3% at none). On-phone checks (section 7 of the device checks) come later. |
| M4 Characters and voice out | **Done and merged to `main` on 2026-10-27** (CI green, all six jobs; report in `docs/milestones/M4.md` section 11). Phone-tested by the owner: nine friends on Friends' Beach, a tone per friend with the mouth moving, the companion on the map and in lessons, the celebration. The voices are free test tones; real ElevenLabs voices (Phase H, to-do P3) are still to do. |
| M5 Voice in | **Done and merged to `main` on 2026-10-27** (CI green, all six jobs; report in `docs/milestones/M5.md` section 11). Phone-tested by the owner: the parent switch, answering by word and number, the "I heard… right?" check, the repair steps and the commands. **Accuracy is still not measured**: adult recordings (to-do P4) next, children's later (stays open, as agreed). |
| M6 Gateway and AI tutor | **Merged into `main` on 2026-10-27** after the owner's confirmation and all six CI jobs green. Real Haiku 5.5 and ElevenLabs run through the gateway; device checks A to D passed on the phone (check E, Band A caption, is still to confirm); cache-hit round trip 0.6 s median; 66 reviewed hero-son lines voiced (review-and-voice flow); lexicon 570 words, teaching moves, all awaiting the Hebrew editor. Report: `docs/milestones/M6.md` section 11. |
| M7 Parent area | **Merged into `main` on 2026-10-28** after the owner's confirmation and all six CI jobs green. 7a (time rules, progress view, alerts) was checked on the phone. 7b (sync, deletion, alerts and rules across devices, the helper log): the server is live and the owner's phone synced to it (child with nickname, 54 answers, 29 visits, alerts, rules). Push (app side) and the weekly encrypted backup are built (the first backup ran and opens with his key); push was proved on his phone (a tap goes straight to the gate). Open: a second real device, the report button on the helper log, home activities (pack 0.3.0 and the `carry` step), recorded lines (need his OK on cost), the Firebase key file to 1Password and out of Downloads, the alert word lists and Hebrew strings to an editor. Reports: `docs/milestones/M7.md` sections 11 and 12. |
| M8 Rewards and world | **Plan accepted (Q1 to Q11 as recommended). Part 8a built on branch `m8-rewards-world`, not merged** (rules, rewards table and sync, stickers, the world's islands, golden stars, the bell flag and revisit mission; report in `docs/milestones/M8.md` section 11). Server side live. Open: a check on the owner's phone; then 8b (Trophy Hall, ceremony, prizes, medals, decorations, ribbons, pack 0.3.0). |
| M9 | Not started |

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
itznutz-secrets\pack-signing.key` (outside the repo).

- **M4 (2026-10-26):** database v4 (`companion_id`), character packs and resolver, `CharacterView`, voice packs and `VoiceDirector` with `audioplayers` 6.8.1, `voice_gen` (plan, mock, audition, generate with a confirmed character count), Friends' Beach, live characters on the map, in lessons and on the celebration card, 587 tests. The 17 packs for the phone are made by `tools/make-m4-device-packs.ps1`.

- **M5 (2026-10-26):** `sherpa_onnx` 2.0.0 and `record` 7.1.2 added (owner approved); `app/lib/speech/` (matcher, lexicon, engine, mic controller), database v5 (`attempt.input`, `voice_listen`), the five mic states, the repair sequence, the parent's "Voice answers" switch, the ivrit.ai model with pinned hashes, `tools/make-m5-model.ps1`, `tools/run-asr-eval.ps1` and `app/tool/asr_eval.dart`.

- **M6 (2026-10-26):** migration `20261026120000_tutor_tables.sql`, `content-publish`, `tutor-turn`, `tutor-prewarm`, `_shared/{hebrew,lexicon,validator,tutor_prompt,anthropic,elevenlabs,tutor_core}.ts`, the starter lexicon, `app/lib/tutor/`, `app/tool/{publish_lib,prewarm_lib,tutor_prewarm}.dart`; 132 Deno tests, 695 app tests, the pgTAP suite extended.

- **2026-10-27:** the parent gate is now a small sum in digits (was a multiplication in Hebrew words; the owner found it too hard). PLAN.md updated.

- **2026-10-27 (phone test day):** the voice mic is never withdrawn after failed listens (owner's decision; PLAN.md and M5.md updated); the map bubble follows the companion's mouth; a line starting after leaving a lesson is stopped.

- **2026-10-27:** the map now shows a calm loading scene (three pearls) until the character and its voice are ready, and the characters start loading while the child picker is on screen. The owner asked that the dev "what the engine knows" view become a parent-facing learning curve; it belongs to M7's progress view (PLAN.md, "Mockups": understanding versus retention over 8 weeks, skills by status per domain).

- **2026-10-27, phone test day (Samsung SM-S938B):** M1 to M5 checked on the phone by the owner: signed ping, PIN lock-out, the butterflies lesson, damaged packs all refused (6 of 6), engine view, Friends' Beach with nine friends and test tones, celebration, voice answers (word, number, wrong number with confirmation, repair steps, commands, switch off). Not run: frame times (T5), the adult-recording accuracy run (P4), real voices (P3), the AI helper on the phone (T7).

## Open issues

- **Probe items:** the engine's gap search needs open probe items (give, drag, trace) for every skill that can be a gap; the starter pack has none. An authoring rule for M9; in the simulator, three-option probes alone make a search too long for a Band A session.
- **FSRS weights** were written from memory of the FSRS 4.5 defaults and not checked against the reference; refit on real data.

- **M6 live phase (2026-10-27, merged):** real Haiku 5.5 and ElevenLabs calls work; hero-son pre-warmed (94 of 99 lines, 0.29 USD; 5 refused for vocabulary). Server time for a fresh line 2 to 3 s. Device checks A to D passed on the phone; cache-hit round trip median 625 ms. Reviewed-line flow built; 66 reviewed lines for hero-son voiced (0.18 USD). Still to do: owner listens on the phone, check E (Band A), cells without a reviewed line (33) use the authored line, Hebrew editor review (lexicon, prefix vocalisation nits), M6 merge needs his confirmation. The lexicon is small and unreviewed; the helper is off by default.
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

The full checklist is `docs/owner-todo.md`. In short:

- **M6:** done. Open from it: check E on the phone, Hebrew editor review of the lexicon and the reviewed lines, fix the prefix vocalisation nits, the 33 cells without a reviewed line (authored lines used).
- **M4 and M5:** the phone checks passed on 2026-10-27; waiting for his explicit "confirmed" to merge. The adult recordings (P4) and real voices (P3) remain.
- Save the pack signing key in 1Password (next time at the PC); on-phone checks for M1, M2 and M3; Hebrew review; confirm M3 after the report.
- Spend-limit screenshots (Anthropic and ElevenLabs consoles).
- Confirm M0 after the report (then Claude merges `m0-foundations` into `main`).

- 2026-10-26: all 8 functions redeployed to the live project by Claude (audited `@noble/curves` is live). It has not yet run against a real attestation; the next enrolment on the phone will exercise it.

## Next step

Claude: M7 is merged. M8 part 8a is built on `m8-rewards-world` (report in `docs/milestones/M8.md` section 11); install the dev build on the owner's phone and let him look, then start 8b. Do not merge without his confirmation and six green CI jobs. Do not merge anything without the owner's confirmation.
