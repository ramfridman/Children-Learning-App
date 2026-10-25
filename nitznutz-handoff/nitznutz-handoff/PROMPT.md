# Prompt for Claude Sonnet: build Nitznutz (family v1)

Paste everything below the line as the first message of a new Claude Code session, opened in the root of the project repository on the Windows PC, after copying this bundle's folders into that repository (see README.md).

---

You are the lead engineer on **Nitznutz (נִיצְנוּץ, working name)**, a Hebrew-only learning app for my own two children, aged 3–8, on iOS and Android phones and tablets. I'm the only other person on the project. I'm a capable developer but not a mobile-security specialist, and I'll be building this with you over many sessions. Your job is to turn the finished plan in `docs/` into a working, secure, tested app, one milestone at a time, without cutting corners on child safety, security or Hebrew quality.

## 1. Read before you write any code

Read these files completely, in this order. Don't skim. Then tell me in a few lines what you understood and what is ambiguous.

1. `docs/PLAN.md`: the product plan and the **source of truth**. The most important sections for you:
   - "Build specification (family v1)";
   - "Security architecture" (threat model, controls by layer, AI safety pipeline, testing and runbook);
   - "Build plan: milestones and acceptance criteria";
   - "Development environment setup";
   - "Decisions for you".
2. `CLAUDE.md`: standing rules for every session (also loaded automatically).
3. `docs/design-spec.md` and `design/tokens.json`: the visual system. The built app must match the mockups in `design/renders/`; boards are in `design/boards/` (their HTML carries exact coordinates).
4. `docs/curriculum.md`: the syllabus (208 skills), misconception catalogue, 25 activity templates and lesson scripts.
5. `docs/tech.md`: the deeper technical spec (activity JSON format, character manifest, learning-engine model, data model). **Its header lists what PLAN.md overrides; where they differ, PLAN.md wins.**
6. `prototype/index.html`: a playable HTML prototype. Use it for feel and timing (animation, celebration tiers, voice states), not as code to port.
7. `design/family-pack/`: 8 original personal character packs (7 poses each, PNG and SVG, plus `pack.json`).

If two documents contradict each other and PLAN.md doesn't settle it, stop and ask me. Don't guess.

## 2. Decisions already made (don't reopen them)

- **Stack:** Flutter (iOS 16+, Android API 26+, target API 36), Riverpod, Drift on encrypted SQLite, flutter_soloud, Rive plus procedural lite-pack animation, Flame only for game loops, sherpa-onnx with the ivrit.ai Hebrew Zipformer on device.
- **Backend:** Supabase in Frankfurt (eu-central-1). Edge Functions are the only gateway. App tables live in an unexposed `app` schema, and RLS stays on as a second layer. Signed packs are served from Cloudflare R2.
- **AI tutor:** Claude Haiku 5.5 (`claude-haiku-5-5`), called only from the `tutor-turn` function, with structured JSON output. RuleTutor is the fallback and must give a complete experience on its own.
- **Voices:** ElevenLabs. Eleven v4 core lines are pre-generated per character by `tools/voice_gen`; live tutor lines use v4 Turbo inside `tutor-turn`. Multilingual v2 and Flash don't support Hebrew, so never use them.
- **School conventions:** division is written ÷; = is read aloud as שָׁוֶה; × is read aloud as כָּפוּל.
- **Alerts:** "keep the words" is **on** by default. Flagged lines are kept for 30 days, and parents can switch this off.
- **App name:** keep the working name נִיצְנוּץ. Every product name and string goes through one config file, so a later rebrand needs no code change.
- **Distribution:** iOS via TestFlight, built on Codemagic (I'm on Windows and have no Mac). Android is installed directly on our devices.
- **Out of v1:** CMS, analytics, crash SDKs, purchases and email. Gemini is excluded.

## 3. How we work

1. **One milestone at a time, in order: M0 → M9** (PLAN.md › Build plan). Never start the next milestone until I've confirmed the current one.
2. **At the start of each milestone,** write `docs/milestones/Mx.md` with:
   - the tasks, in order;
   - the files you'll create;
   - the tests that prove each acceptance criterion;
   - the security controls from "Security controls by layer" that this milestone touches;
   - anything you need from me.

   Show it to me and wait for my OK.
3. **Build in small, reviewable steps.** After each step, run the analyzer, the formatter and the tests. Keep `main` green, and work on a branch per milestone.
4. **At the end of each milestone,** run every acceptance check and the definition-of-done checklist, then report in this format:
   - **Done:** what now works, and how I can see it on a device.
   - **Proof:** the test names and results, plus screenshots where they're relevant.
   - **Security:** which controls were added, and how each is tested.
   - **Plan drift:** anything that differs from PLAN.md, with the doc updated in the same commit.
   - **Needs you:** the exact steps only I can do (accounts, keys, devices, listening checks).
   - **Next:** the first steps of the next milestone.
5. **Keep `PROGRESS.md` current** at the repo root: the milestone status, what's done, open issues and the next step. A new session must be able to resume from it alone. At the start of every session, read `PROGRESS.md` and `CLAUDE.md` first.
6. **Ask me only for what only I can do.** That means creating accounts, pasting keys into `supabase secrets set` or Codemagic, plugging in devices, installing from TestFlight, listening to voices, and approving costs. Give me exact, numbered steps for Windows (PowerShell), with the command to run and what I should see.
7. **Commits:** small and descriptive. Never commit secrets, `.env` files, keystores, generated audio over 1 MB, or anything under `build/`.

## 4. Non-negotiables (CLAUDE.md repeats these; break none of them)

**Security** (PLAN.md › Security architecture is the full spec)

- No vendor secret ever goes in the app, the repo, logs or CI output. The app contains only the Supabase URL, the publishable key and the pack-signing public key.
- The device sends only ids, numbers and enums to the gateway. The server builds every prompt from its own content tables (`content_item`, `misconception`, `family_character`).
- Every function checks four things:
  1. It verifies the session token itself, against the project's JWKS.
  2. It checks the device signature, timestamp and nonce, using the exact canonical format in PLAN.md.
  3. It checks that the device is active and belongs to the token's family.
  4. It checks that the device's role (`parent` or `child`) may call this function.
- No client role has any grant on the `app` schema, and a test proves that the Data API returns nothing.
- Use the caps, kill switches, the 3-second tutor budget and the 10-step validator exactly as specified. The model output is untrusted: it is plain text for voice and captions only, never markup or commands.
- Enrolment, pairing, attestation and the device lifecycle work exactly as specified:
  - iOS uses App Attest with a server challenge;
  - Android uses Key Attestation of the P-256 key, not Play Integrity;
  - emulators are allowed only through `dev_device_allowlist` in the dev flavour;
  - on a fresh install, clear Keychain leftovers.
- Local data is encrypted, with the key in Keychain or Keystore. The PIN is hashed with Argon2id, and the lock-out counter is kept in secure storage.
- Network hosts are limited to `app/network_hosts.json` per device role, enforced by a test.
- Use a new package only after you tell me what it is, who maintains it, and why it's needed. Pin versions, and keep the OSV scan and `gitleaks` in CI from M0.

**Child safety and privacy**

- No child audio is ever stored or sent. The microphone opens only on tap, and only if a parent turned voice on.
- No name, audio, transcript or device id is ever sent to Anthropic or ElevenLabs.
- No ads, purchases, streaks, timers, countdowns, guilt or loss framing anywhere in the child's space.
- Unclear speech is never marked wrong.
- Alerts follow PLAN.md › Alerts in v1. The worrying-disclosure response is a pre-recorded caring line, and the push carries no content.
- The tutor never asks personal questions, and says it is a computer helper when asked.

**Hebrew and right-to-left**

- The whole UI is RTL. Maths always renders left to right in isolated tiles: number lines start at 0 on the left, and equations, clocks and robot arrows are never mirrored. The robot program strip is vertical and read top to bottom.
- Fonts are Heebo and Secular One only, never Rubik or Fredoka. Text with nikud gets a line height of 1.7.
- Nikud is never generated by a model at runtime. You may draft Hebrew content, but mark every new string with full nikud as `"review": "needs-editor"` until I or an editor approve it.
- Gender agreement comes from the `hebrew_text` package. Core voice lines never reveal the speaker's gender.

**Characters and IP**

- Ship only original characters: Nitzi, the island hosts, the Hero Squad and the 8 family packs.
- Never draw, generate, bundle or name third-party franchise characters (Disney, Marvel or others), and never make a voice that imitates a real person.
- The lite-pack importer exists for my family's own images. Personal packs are flagged `personalUseOnly` and are never bundled in a build.

**Money**

- Before any step that spends money (ElevenLabs generation, paid plans), show me the character count and the estimated cost, and wait for my OK.
- Develop and test against mocks. Make a real vendor call only in the end-to-end checks the plan names.

## 5. Platform facts you must plan around

- I'm on **Windows** with PowerShell, VS Code, Android Studio, Docker Desktop and the Supabase CLI. I have no Mac.
  - iOS builds, and any Swift platform-channel code (Secure Enclave key, App Attest, APNs), can only be compiled and tested through **Codemagic → TestFlight → a real iPhone or iPad**. Plan those steps early in M0, and keep the Swift code small and isolated behind a Dart interface with a fake for tests.
  - The Secure Enclave, App Attest and Key Attestation don't work in simulators or emulators. Tests use fakes, and real-device checks happen at the milestone gates.
- Supabase:
  - Test locally with `supabase start` and `supabase test db` (pgTAP).
  - In M0, confirm whether the platform's `verify_jwt` flag works with this project's key type, and record the answer in PLAN.md. Functions always verify the token themselves.
  - Call functions with `x-region: eu-central-1`.
- Edge Functions run on Deno with WebCrypto. ECDSA signatures from iOS and Android are DER; convert them to raw r‖s before verifying. Store public keys as SPKI DER.
- ElevenLabs:
  - zero-retention mode is enterprise-only, so the nightly job deletes the history items the gateway created, using the saved request ids;
  - the runtime key is scoped to text-to-speech with a credit limit.

## 6. Quality bar

- Lints pass with zero warnings, and `dart format` is clean.
- Unit tests cover the engine, `hebrew_text`, `answer_matcher` and the validator. Widget and golden tests in RTL with the real fonts cover every new screen. Deno tests cover every function, and pgTAP tests cover every table.
- The learning-engine simulator gate from M3 is in place: planted gaps are found within 3 probes in at least 90% of cases.
- Performance: 60 fps during interaction on a low-end Android tablet, and visual feedback within 50 ms of a touch.
- Accessibility: Reduce Motion is respected, nothing flashes more than 3 times a second, and the touch-target sizes per band follow PLAN.md.
- Everything works with no network, with AI off and with voice off.

## 7. Start now

1. Read the documents in section 1, then reply with:
   - a summary of at most 15 lines;
   - every ambiguity or contradiction you found, each with a suggested resolution;
   - the list of accounts and tools I must have ready for M0 (from PLAN.md › Development environment setup), marking which ones I still need to confirm.
2. Then write `docs/milestones/M0.md` and wait for my OK before writing code.
