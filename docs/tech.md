# Technical Architecture: Hebrew Learning App for Ages 3–8

Lead Developer / Technical Architect · 24 October 2026 · Proposal for the coordinator to merge with the Curriculum and Design plans.

> **Superseded for the family v1 build (25 October 2026).** The product plan doc's sections "Build specification (family v1)", "Security architecture" and "Build plan" win wherever they differ from this file. In particular: voices are ElevenLabs per character (not studio recordings or Chirp/Azure TTS), the gateway is Supabase Edge Functions (not Hono containers), content is JSON in Git (no Payload CMS), Gemini is excluded, and there is no RevenueCat, analytics or crash SDK in v1.
>
> Also superseded for v1: §8.1 studio voice-over and its budget; §8.2/§9.6 Chirp/Azure TTS options and costs; §9.1 Gemini failover, the 15-minute attestation token, SSE streaming and the separate TTS step (voice now returns in the same `tutor-turn` call); §9.4 "Hebrew moderation classifier" (replaced by the vocabulary gate, blocklists and evaluation suite); §10 Hono, Payload CMS, Sentry, Metabase, RevenueCat and no-account mode; the §6.5 manifest's `"vendor": "azure"` (now ElevenLabs voice ids registered via `character-register`); §7.8 sync (now a server sequence cursor and child tombstones); §14 team and budget. Device enrolment, pairing, roles, signed requests, the unexposed `app` schema and the API list are defined only in the plan doc.

Conventions:
- **verified**: checked against a current page listed in Sources.
- **estimate** / **assumption**: my judgement.
- Section 11 is a technical reading of the rules, not legal advice. Privacy counsel must review it.

Contents:
1. Recommendation summary
2. Cross-platform stack decision
3. Architecture
4. Hebrew & RTL engineering
5. Content system
6. Character pack system
7. Learning engine
8. Voice pipeline
9. AI tutor
10. Backend & services
11. Privacy, child safety & store compliance
12. Responsive layout & devices
13. Quality engineering
14. Team & roadmap
15. Technical risks & mitigations
16. Open decisions
17. Sources

---

## 1. Recommendation summary

- **Stack: one Flutter app** for iOS and Android phones and tablets. Current stable is 3.47, supporting iOS 15+ and Android API 24+ (verified).
  - **Rive** (0.14.x) state machines with Data Binding for characters: emotions, gaze and lip-sync.
  - **Lottie** only for small UI effects.
  - **Flame** (1.38.x) only for activity templates that need a game loop.
  - **flutter_soloud** (5.2.x) as the single low-latency audio engine.
  - **Drift/SQLite** for local-first learner data.

  Flutter draws every pixel itself, so the RTL layouts, nikud, animation and golden screenshots are the same on a cheap Android tablet and an iPad. For this product that matters more than a native look.
- **Architecture.** Six layers: presentation, activity engine, learning engine, content, voice/AI, and sync/services.
  - Activities are **data** (JSON) that drive a small set of engineered templates.
  - The learning engine is pure, deterministic Dart.
  - **Everything a child does works offline.** Only the optional AI tutor needs the network.
- **Content.** Educators write in a self-hosted headless CMS (Payload) with Hebrew/RTL and nikud fields.
  - They preview drafts in **Studio Preview**: the real engine compiled for the web, plus a QR code to open the draft on a device.
  - CI validates every activity against a JSON Schema and Hebrew lint rules, then builds signed, content-addressed packs and publishes them to a CDN.
  - The store download stays ≤ 100 MB.
- **Learning engine, built for genuine understanding at the child's own pace.** It runs fully on the device.
  - A skill graph with a **diagnostic walk** back to the weakest prerequisite.
  - **Misconception tags** on every distractor, tap pattern and expected wrong spoken answer, which trigger targeted repair.
  - **Representation switching** (concrete, pictorial, story, embodied, symbolic) after struggle, with per-child records of what works.
  - **Mastery plus memory:** BKT/Elo for mastery and an FSRS-style retention model for revisit checks, distinguishing **fresh** from **durable** mastery.
  - Transfer, reverse, error-spotting and explain-back checks; "I'm not sure" with no penalty; per-domain placement.
  - Parents see each skill as understood, practicing, needs a revisit, or gap found.
- **Characters are content, not code.** Views reference **role slots**, and a resolver fills them with the child's companion at runtime.
  - **Full packs** use Rive and a fixed state-machine/view-model contract with studio VO.
  - **Lite packs** are owner-supplied images animated by the engine, with a TTS voice. They are flagged `personalUseOnly` and are excluded automatically from store builds.
  - Licence metadata, a kill switch and remote enable/disable make licensed characters possible later. Adding a full character takes about 14–22 person-days with no engineering; a lite pack takes about 1–2 hours.
- **Voice.**
  - **Voice-over** is studio-recorded human speech (Ogg/Opus) with mouth cues generated at build time.
  - **The AI tutor speaks through Hebrew TTS.** Hebrew support verified for Google Chirp 3 HD, Azure Hila/Avri and ElevenLabs v3/v4. Each character pack names its TTS voice and style, chosen by a blind listening test. A character's online and offline lines always use that same voice, with caching.
  - **Children's speech is recognised on the device by default.** The leading candidate is ivrit.ai's streaming Hebrew Zipformer, run through sherpa-onnx.
  - Answers are matched against the expected answers, including Hebrew number and colour variants. A "confirm" step handles uncertain results, and the app falls back to tap. Uncertainty is never scored as wrong.
- **AI tutor.**
  - The device calls our EU **Tutor Gateway**, never the LLM directly.
  - The default model is **Claude Haiku 5.5** (`claude-haiku-5-5`, $0.10/$0.50 per million tokens, verified). Gemini Flash is the evaluated alternative.
  - The tutor receives the learner state (misconceptions, representations tried, mastery and retention). It returns structured JSON: say-text, mascot emotion, hint level, next action, and which representation to switch to.
  - An output validator blocks answer leaks, wrong gender forms and off-scope content.
  - A deterministic **RuleTutor** gives the full experience offline or when AI is off.
  - Estimated cost: **$0.15–0.45 per active child per month**, with TTS the largest share.
- **Backend.** Supabase in Frankfurt, an EU gateway, a Cloudflare R2 CDN, and RevenueCat for purchases behind the parental gate.
  - First-party analytics only, self-hosted crash reporting, and **no third-party analytics or ad SDKs**.
  - Child profiles hold a nickname, avatar, age range and grammatical gender. No date of birth and no photos.
- **Compliance.**
  - App stores: Apple Kids Category (1.3/5.1.4) and Google Play Families / Expert Approved.
  - Children's privacy: COPPA as amended (compliance date 22 April 2026), GDPR Article 8, and Israel's Amendment 13 (in force 14 August 2025).
  - EU AI Act transparency from 2 August 2026.

  All of these point to the same design: on-device processing, minimal data, separate consent for anything extra, and written retention and security programmes.
- **Plan.** 6–8 weeks of technical spikes, a 5–6 month MVP, an 8–10 week family beta, and launch at about **10–12 months**.
  - About 5.5 engineering FTE plus animation and VO.
  - **About $1.1–1.6M to launch**, excluding the curriculum and design teams and marketing (estimate).
- **Biggest risks:**
  - **Recognising young children's Hebrew speech.** Mitigations: voice is optional, answers come from a closed set, and we measure on a consented child evaluation set from month one.
  - **Third-party character IP reaching a store build without a licence.** This breaks Apple 5.2.1 and Google Play's IP policy. The store build is blocked automatically.

---

## 2. Cross-platform stack decision

### 2.1 Comparison for this app

| Criterion | **Flutter** | React Native (Expo SDK 56) | Unity 6 | Native ×2 |
|---|---|---|---|---|
| Heavy 2D animation | Excellent. Impeller is the only renderer on iOS and the default on Android API 29+ (verified). First-class Rive runtime. | Good: Reanimated, Skia and Rive, with more native seams | Excellent | Excellent, built twice |
| Game-like activities | Flame with `flame_rive`/`flame_audio` where needed; plain widgets elsewhere | Possible; less mature | Best | SpriteKit + custom Android |
| RTL + nikud | App-wide `Directionality`; HarfBuzz shaping; same on both OSes | `I18nManager.forceRTL` needs a restart; text engines differ per OS | Weak. RTL exists only in UI Toolkit via an opt-in generator; TextMeshPro needs plugins (verified) | Excellent |
| App UI (parent area) | Good | Very good | Poor | Excellent |
| Audio | flutter_soloud: buses, Opus, PCM streaming (verified) | expo-audio, which added streaming in SDK 56 (verified) | Excellent | Excellent |
| Golden pixel tests | Built in; headless in CI | Third-party | Custom | Two toolchains |
| Small-team fit | One language, one UI tree | Good for React teams | Needs game developers | About 1.8–2× the people |

**Decision: Flutter.**
- **One renderer means the same experience on every device.** Golden tests can then guard visual quality, the owner's second priority.
- **Expo is the credible runner-up.** SDK 56 ships React Native 0.85 and requires iOS 16.4+ (verified). It loses on RTL consistency, game-loop maturity and pixel testing.
- **Unity loses** on Hebrew text, the parent UI and app size.
- **Native loses** on team size.
- **Watch items:**
  - `rive` is still 0.x and `rive_native` is not public on GitHub (verified). We pin versions and hide Rive behind a `CharacterView` interface.
  - Material and Cupertino are leaving Flutter's core SDK. That barely affects us, because we use our own design system.

### 2.2 Runtime components

| Concern | Choice | Notes |
|---|---|---|
| Characters | **Rive** state machines + Data Binding view models | Rive Renderer by default, with the Flutter renderer on "lite" devices. Avoid runtime Rive Events and text runs, which are deprecated in favour of Data Binding (verified). |
| UI effects | Flutter animations; **Lottie** 3.6 for designer effects | `renderCache` trades memory for CPU (verified) |
| Game layer | **Flame** for selected templates | e.g. the CS robot grid, catch games, physics sorting |
| Audio | **flutter_soloud** | Separate VO, SFX, music and tutor buses with ducking; Opus/Ogg; buffer streams for TTS; wave/FFT data for amplitude lip-sync (verified) |
| Speech recognition (ASR) | **sherpa-onnx** (1.13.x) plus platform channels to Apple Speech and Android `SpeechRecognizer` | See 8.3 |
| Storage | **Drift** (SQLite: reactive queries, migrations); file system for packs; secure storage for tokens | |
| State / DI | **Riverpod**, plus explicit finite-state machines (FSMs) inside activities | See 3.2 |

---

## 3. Architecture

### 3.1 Layers and boundaries

```
PRESENTATION   child shell · parent shell (gated) · design system · CharacterView{Rive|Lite}
ACTIVITY ENGINE  template registry · ActivityRuntime FSM · interaction primitives
LEARNING ENGINE  skill graph · diagnostic walk · misconceptions · representation bandit ·
               BKT/Elo mastery · FSRS retention · session builder               (pure Dart)
CONTENT        pack manager · signature check · asset resolver · CharacterResolver ·
               hebrew_text                                                      (pure Dart)
VOICE / AI     AudioService · SpeechInput + answer_matcher · TutorPolicy{Rule|Llm} · TTS cache
SYNC/SERVICES  Drift DB · event outbox · auth · subscriptions · config · analytics · crash
```

A layer may only depend on the layers below it. `learning_engine`, `content_schema`, `hebrew_text` and `answer_matcher` have no Flutter imports. They also run in Studio Preview (web), in the CI validator (a Dart CLI) and in server-side simulations.

Interfaces the other agents can rely on:
- `ActivityTemplate.build(spec, stageGeometry, slots)` emits `AttemptResult {itemId, skillIds, outcome (correct|incorrect|unsure|timeout), errorClass, misconceptionIds, representation, checkType, hintsUsed, inputMode, latencyMs, asrConfidence?}`.
- `CharacterResolver.resolve(slot, context) → CharacterView`. `CharacterView` exposes `set(state, mood)`, `lookAt`, `trigger`, `speak(audio|tts)`; Rive and lite implementations are interchangeable.
- `TutorPolicy.onEvent(ctx) → TutorAction {lineRef|sayText, emotion, hintLevel, nextAction, highlightTargets}`. `RuleTutor` and `LlmTutor` both implement it, and the user interface cannot tell them apart.
- `SpeechInput.listen(expectedAnswers, band) → AnswerMatch {value?, confidence, decision: accept|confirm|retry|noSpeech}`.

### 3.2 State management and runtime flow
- **Riverpod** holds app state (current child, settings, entitlements, pack catalogue) and wires dependencies. Tests swap in fakes such as `FakeAsr` or `FakeClock`.
- **Each activity is an explicit state machine** with these states:

  `intro → prompt → awaitingInput(tap|voice) → evaluating → feedback → [hint n → awaitingInput] → complete`

  Sealed-class states and a reducer make it deterministic. A recorded event log replays any bug exactly.
- **Rive state machines handle visuals only.** A `CharacterController` maps semantic states onto view-model properties.
- **Flame games** talk to the activity only through command and result streams.
- **Preloading.** The next item's audio and art load during the feedback step, so transitions feel instant.

### 3.3 Repository structure (monorepo using Dart pub workspaces)

```
apps/mobile            Flutter app; flavors dev | beta | prod
apps/studio_preview    Flutter Web educator preview
packages/              design_system · hebrew_text · content_schema · content_runtime ·
                       activity_engine · templates/<name> · learning_engine · characters
                       (resolver, Rive + lite views, sandbox) · voice · tutor ·
                       data (Drift, outbox, sync) · services
native/                Swift/Kotlin plugins (Apple Speech, Android SpeechRecognizer)
backend/               api (TypeScript/Hono) · tutor_gateway · cms (Payload) ·
                       pack_builder (Dart CLI: validate, validate-character, sign, publish) ·
                       supabase (migrations, RLS)
tools/                 asr_eval · tutor_eval · vo_pipeline · learner_sim · studio import-lite
content-repo/          (separate) CMS exports as diffable JSON + pack recipes
```

---

## 4. Hebrew & RTL engineering

### 4.1 Bidi and LTR maths
- The app root is `Locale('he','IL')` with `Directionality(rtl)`.
- All spacing and alignment use the direction-aware forms (`EdgeInsetsDirectional`, `AlignmentDirectional`). A lint rule bans `left`/`right` spacing in child UI.
- **Maths is never a raw string inside Hebrew text.** The bidi algorithm reorders `3 + 4 = 7` into `7 = 3+4`. So:
  - On-screen equations are `EquationRow` widgets made of tiles, inside `Directionality(ltr)`. The tiles stay draggable.
  - Captions use a typed token `{"t":"math","v":"3+4=7"}`. It is rendered between the Unicode isolate controls LRI (U+2066) and PDI (U+2069).
  - The CMS lint rejects digits combined with operators outside a math token.
  - Minus is written as U+2212.
- **What mirrors and what does not:**
  - *Relative* chrome mirrors: back/next arrows and progress bars.
  - *Absolute* directions never mirror: the CS robot's "left" arrow, number lines and clocks. These use `matchTextDirection: false` and have golden tests.
  - Whether a CS program reads right-to-left or left-to-right is for Curriculum and Design to decide. The engine supports both through `sequenceDirection`.

### 4.2 Nikud, shaping, fonts and licensing
- **Nikud renders correctly only if the font positions vowel marks properly.** Flutter shapes text with HarfBuzz; the font's GPOS mark tables do the positioning. If a mark falls back to another font, it is placed wrongly.
- **Stress test.** Every font must pass a nikud stress string with dagesh plus vowel, qamats qatan (U+05C7) and hataf vowels, e.g. `כׇּל הַכָּבוֹד · שֻׁלְחָן · בְּקֻבּוּץ · אֳנִיָּה`.
- **Font facts** (verified, all SIL OFL 1.1):

  | Font | Nikud support |
  |---|---|
  | Noto Sans Hebrew | Full niqqud and cantillation, but no Latin digits; pair it with a digit font |
  | Heebo, Assistant, Alef, Varela Round, Secular One | Niqqud, but missing rare marks such as varika and meteg; fine for children's text after testing |
  | Rubik | Severely broken niqqud: never use for vocalised text |
  | Fredoka | Positioning errors |

- **Font requirements for Design.**
  - A "school print" style for early-reader text.
  - If the font is commercial, an **app-embedding licence** that covers mobile, web preview and unlimited installs.
  - Line height ≥ 1.45 for vocalised text.
  - Subset fonts only after the stress test passes.
- **Nikud is authored in the content and never generated at runtime.**
  - The CMS suggests vowels with a diacritiser: Dicta Nakdan or Phonikud's base diacritiser.
  - A human reviewer approves every string. Approval is a workflow state.

### 4.3 Grammar: the `hebrew_text` package
- **Lexicon.** Each noun is stored with its gender and its singular, plural and construct forms, with nikud and audio IDs: בָּלוֹן (m), בֻּבָּה (f).
- **Number words** follow `numberWords(n, gender, form)`:
  - שְׁלוֹשָׁה בָּלוֹנִים (masculine noun) but שָׁלוֹשׁ בֻּבּוֹת (feminine noun).
  - Construct form: שְׁלֹשֶׁת.
  - "One" follows the noun: בָּלוֹן אֶחָד.
  - Two before a noun: שְׁנֵי / שְׁתֵּי.
  - The counting form children use: אַחַת, שְׁתַּיִם, שָׁלוֹשׁ.
- **Colours** agree with the noun: אָדֹם / אֲדֻמָּה / אֲדֻמִּים / אֲדֻמּוֹת.
- **Second person** in the tutor's dynamic lines follows the child's gender: נַסֶּה / נַסִּי. Pre-recorded VO uses gender-neutral or plural forms, e.g. בּוֹאוּ נִסְפֹּר.
- **One package, three uses:** it generates captions, builds the speech-recognition accept-lists (8.3) and lints content.

### 4.4 Number and locale formatting
- Western digits, `.` for decimals and `,` for thousands, via `intl` with locale `he`. Child UI shows no thousands separators below 10,000.
- **Locale codes:**
  - Legacy Android APIs report Hebrew as **`iw`**.
  - Google STT uses `iw-IL` (verified).
  - Everything else uses `he`.

  Normalise them in one function.

### 4.5 RTL testing
- **Golden tests** use real Hebrew fonts, not the default Ahem test font. Coverage: every template × phone/tablet × portrait/landscape × band typography.
- **Dedicated goldens** for the nikud string, an equation inside a Hebrew sentence, non-mirroring arrows and text overflow.
- **Generation.** Goldens are generated on Linux CI because font rasterisation differs between operating systems (verified, Alchemist).
- **Manual checks** each release: accessibility text sizes, and VoiceOver/TalkBack reading Hebrew.

### 4.6 Hebrew in TTS and STT
- **TTS.** Unvocalised Hebrew is ambiguous: ספר can be *sefer*, *sapar* or *siper*. So the gateway:
  1. asks the LLM for short sentences;
  2. replaces known words with vocalised forms from the lexicon;
  3. keeps a pronunciation regression set per vendor.

  Chirp 3 HD offers **no custom pronunciation or pause control for he-IL** (verified), so for that vendor all fixes are made in the text.
- **STT.** Output may contain digits or words, prefixes (הָאָדֹם, "the red") and final-letter forms. ivrit.ai warns that its number formatting is inconsistent (verified). Normalisation is described in 8.3.

---

## 5. Content system

### 5.1 Activity templates as data
**Engineers build templates; educators build activities as data.** No code and no app release are needed. An MVP template set might include count-choose, drag-sort, match-pairs, pattern-continue, trace-shape, build-shape, robot-path, compare-quantities, number-line-jump and colour-mix. The Curriculum agent owns the final list.

Each activity is JSON validated by `activity/v1` plus a per-template sub-schema. Assets are referenced by logical IDs (`vo:`, `asset:`, `lex:`) that the build step resolves to content-hashed files.

```json
{
  "schema": "activity/v1",
  "id": "num.count.a.balloons.003",
  "revision": 4,
  "template": "count_choose", "templateVersion": "1.2",
  "domain": "numbers", "band": "A",
  "skills": [{ "id": "num.count.1to5", "weight": 1.0 }],
  "purpose": "practice",
  "checkType": "practice",
  "representation": "pictorial",
  "variantGroup": "num.count.howmany.small",
  "difficulty": { "authored": 0.25 },
  "scene": {
    "background": "asset:bg/park_day",
    "characters": [{ "slot": "activity_helper", "pose": "point", "anchor": "stage.bottom_start" }],
    "objects": { "generator": "scatter", "lexeme": "lex:balloon",
                 "sprite": "asset:props#Balloon", "attributes": { "color": "red" },
                 "count": 3, "tapToCount": true }
  },
  "prompt": {
    "vo": "vo:num.count.howmany.balloons",
    "caption": [{ "t": "he", "v": "כַּמָּה בָּלוֹנִים יֵשׁ?" }],
    "replayButton": true
  },
  "answer": {
    "type": "choice",
    "options": [
      { "id": "o2", "value": 2, "misconception": "num.count.skip_object" },
      { "id": "o3", "value": 3 },
      { "id": "o4", "value": 4, "misconception": "num.count.double_count" }
    ],
    "correct": "o3", "optionDisplay": "numeral_and_dots", "shuffle": true,
    "unsureAllowed": true
  },
  "traceClassifiers": [
    { "when": "same_object_tapped_twice", "misconception": "num.count.double_count" },
    { "when": "object_never_tapped", "misconception": "num.count.skip_object" }
  ],
  "voice": {
    "enabled": true,
    "expect": { "kind": "number", "values": [2, 3, 4], "nounLexeme": "lex:balloon" },
    "expectWrong": [
      { "values": [5, 6], "misconception": "num.count.double_count" },
      { "pattern": "count_sequence_without_total", "misconception": "num.count.cardinality" }
    ],
    "generateVariants": true,
    "thresholds": { "accept": 0.75, "confirm": 0.5 }
  },
  "feedback": {
    "correct": { "vo": "vo:num.correct.balloons.3", "anim": "celebrate_small", "sfx": "sfx:pop_chime" },
    "incorrect": [
      { "when": "misconception:num.count.double_count", "vo": "vo:generic.lets_mark_each_one" },
      { "when": "default", "vo": "vo:generic.almost_try_again" }
    ],
    "unsure": { "vo": "vo:generic.lets_find_out_together", "then": "next_hint" }
  },
  "hints": [
    { "level": 1, "action": "replay_prompt_slow" },
    { "level": 2, "action": "highlight_objects_sequentially", "vo": "vo:generic.count_with_me" },
    { "level": 3, "action": "switch_representation", "prefer": ["concrete", "embodied"] }
  ],
  "scoring": { "maxAttempts": 3, "creditByHintLevel": [1.0, 0.8, 0.5, 0.0] },
  "tutor": {
    "llmAllowed": true,
    "goal": "Count up to 5 objects with one-to-one correspondence",
    "mustNotRevealBeforeHint": 3
  },
  "a11y": { "altText": "שְׁלוֹשָׁה בָּלוֹנִים אֲדֻמִּים" }
}
```

What the new fields do:
- **`misconception` tags** connect each wrong answer to the learning engine (7.2):
  - on a distractor option;
  - on a tap-trace pattern (`traceClassifiers`);
  - on an expected wrong spoken answer (`expectWrong`).
- **`purpose`, `checkType` and `representation`** let the engine use the activity in the right role (7.3–7.5):
  - `purpose`: learn, practice, probe, repair or check.
  - `checkType`: practice, transfer, reverse, error_spotting, explain_back or predict.
  - `representation`: concrete, pictorial, story, embodied or symbolic.
  - `variantGroup` groups equivalent items, so a revisit check can pick a *different* one.
- **`characters` names a role slot, never a specific character** (6.3).
- **`unsureAllowed`** shows the "I'm not sure" bubble. It defaults to true.
- **`generateVariants`** builds the voice accept-list with `hebrew_text` (8.3).
- **`when`** values refer to error classifiers that each template defines. The Curriculum agent lists them per template.
- **What the LLM may see:** `tutor.goal`, the misconception catalogue entries and the learner state (9.1).

Skills and misconceptions are content too. Curriculum authors them in the CMS, and they ship in packs:

```json
{ "schema": "skill/v1", "id": "math.add.within5", "domain": "math", "band": "B",
  "prerequisites": [ { "skill": "num.cardinality", "weight": 1.0 },
                     { "skill": "num.count.1to10", "weight": 0.9 },
                     { "skill": "num.compose.within5", "weight": 0.7 } ],
  "representations": ["concrete", "pictorial", "story", "embodied", "symbolic"],
  "masteryRequires": { "representations": ["symbolic"], "checkTypes": ["transfer", "reverse"] },
  "misconceptions": ["math.add.count_all_restart", "math.add.plus_sign_confusion"],
  "retention": { "targetRetention": 0.9, "initialStabilityDays": 2 } }
```

```json
{ "schema": "misconception/v1", "id": "num.count.double_count",
  "skills": ["num.count.1to5", "num.count.1to10"],
  "parentText": "לִפְעָמִים אוֹתוֹ פְּרִיט נִסְפָּר פַּעֲמַיִם",
  "repairActivities": ["num.count.repair.move_aside.001", "num.count.repair.touch_and_say.002"],
  "preferredRepresentations": ["concrete", "embodied"] }
```

(The `parentText` means "sometimes the same item is counted twice".)

### 5.2 Content packs and CDN
- **Format.** A pack is a zip holding `manifest.json` (id, semver, minimum app and template versions, asset hashes), the activity JSON files and hash-named assets.
- **Signing.** Each pack is **signed with Ed25519**, and the app verifies the signature before installing.
- **Pack types:**
  - a **starter pack**, bundled in the app: about 2 hours across all six domains, Bands A–B;
  - **domain/band packs**;
  - **character packs** (section 6);
  - an optional **speech-model pack** (70–90 MB, estimate), downloaded only when a parent enables voice.
- **Compatibility.** A pack that needs a newer template stays hidden until the app is updated, so old apps never crash.
- **Delivery.** Packs are served from Cloudflare R2 behind its CDN with a signed catalogue.
  - Downloads resume after interruption and use Wi-Fi only by default.
  - Hashed assets mean an update downloads only the files that changed.
  - CDN logs keep IP addresses for at most 7 days.

### 5.3 Authoring, CMS and preview
- **CMS: Payload, open source, self-hosted on Postgres in the EU.** Custom field components:
  - RTL text with a nikud palette and an auto-vocalise button;
  - a visual drop-zone editor drawn over the background;
  - a lexicon picker with a gender-agreement preview;
  - a VO-line picker that shows recording status.

  Workflow: `draft → nikud-reviewed → pedagogy-reviewed → VO-ready → published`.
- **Alternatives considered:**
  - Directus: quicker admin, weaker custom editors.
  - Sanity or Contentful: SaaS; data residency and cost would need checking.
  - A fully custom tool: too slow to build.
- **Studio Preview** is embedded in the CMS. It runs the real engine against the draft and can switch band, gender, device frame and orientation, and simulate a recognised speech result. A QR code opens the draft in the beta app on a real device.
- **CI checks on every publish:**
  - JSON Schema validation;
  - references (every `vo:` and `asset:` exists);
  - Hebrew lint (nikud present for Bands A–B, gender agreement, math tokens);
  - audio QC (loudness, clipping);
  - the Rive contract;
  - an automatic headless playthrough of each activity.

### 5.4 Versioning and A/B tests
- **Versioning.** Activities have a stable `id` plus a `revision`; packs use semver. Every attempt logs `(activityId, revision, packVersion, templateVersion)`.
- **A/B tests:**
  - Assignment happens on the device: `hash(childPseudoId + salt)`.
  - **The primary metric is learning, not engagement:** accuracy on the same skill at the next spaced review, and how many hints the child needs.
  - Guard metrics: frustration loops, quitting after an error, and session length against the parent's limit.
  - Results are reported only once each variant has at least 200 children.
- **Rollout and rollback.** Packs roll out through remote config (internal → 5% → 50% → 100%), and we can roll back instantly.

### 5.5 Asset pipeline
- **Rive.** Characters follow the standard contract in 6.2. Props and scenes have their own smaller contracts.
  - CI loads every `.riv` file headlessly and checks it against its contract.
  - **No Hebrew text inside Rive files**, because Rive's RTL support is unverified. All text comes from Flutter.
- **Audio.**
  - Masters are 48 kHz/24-bit WAV, normalised to −16 LUFS with true peak ≤ −1.5 dBTP.
  - They are encoded as **Ogg/Opus 32 kbps mono**, about 4 KB per second, so 1,000 three-second lines take about 12 MB.
  - Music uses Ogg at 64–96 kbps.
- **Lip-sync.** For each VO line, the build writes a mouth-cue file using Rhubarb Lip Sync's phonetic mode or an energy heuristic. Cartoon mouths need only 6–9 shapes.
- **Images.** Vector art inside Rive where possible. Otherwise WebP in two density buckets, with backgrounds that bleed past the stage.

### 5.6 App size budget

| Component | Budget |
|---|---|
| Engine + Dart AOT, per ABI after store splitting | ≤ 25 MB |
| Native libraries (Rive, SoLoud, sherpa-onnx, SQLite) | ≤ 15 MB |
| Fonts + design-system assets | ≤ 5 MB |
| Starter pack | ≤ 50 MB |
| **Store download** | **≤ 100 MB** |
| Speech-model pack (optional) / each domain pack | 70–90 MB / 20–60 MB |
| Fully downloaded | ≤ 700 MB; parents manage storage in the parent area |

---

## 6. Character pack system

**Goal: a new character is content, not code.** Views and activities never name a character; they name a **role slot**. The child's chosen companion and the pack catalogue fill the slots at runtime.

There are two tiers:
- **Full packs**: Rive, studio VO, and shipped to stores.
- **Lite packs**: owner-supplied images, animated by the engine.

Both tiers implement the same `CharacterView` contract, so every slot works with either.

### 6.1 Character manifest

```json
{
  "schema": "character/v1",
  "id": "char.pilpel_owl",
  "packVersion": "1.3.0",
  "tier": "full",
  "name": { "he": "פִּלְפֵּל", "heNoNikud": "פלפל", "grammaticalGender": "m" },
  "roles": ["guide_tutor", "domain_friend", "activity_helper", "celebration_cameo", "map_companion", "sticker"],
  "domainAffinity": ["logic", "cs"],
  "ageBands": ["A", "B", "C"],
  "rive": {
    "file": "asset:rive/pilpel_owl.riv",
    "artboard": "Main",
    "viewModel": "CharacterVM",
    "contract": "character-sm/v1"
  },
  "lipSync": {
    "mode": "visemes",
    "visemeMap": { "A": 0, "B": 1, "C": 2, "D": 3, "E": 4, "F": 5, "G": 6, "H": 7, "X": 8 },
    "amplitudeFallback": { "gain": 1.4, "smoothingMs": 60 }
  },
  "vo": {
    "pack": "vo:char.pilpel_owl@1.3",
    "requiredLineSets": ["core.greetings", "core.encourage", "core.celebrate", "core.listen_prompt",
                         "core.thinking", "core.goodbye", "catchphrases"]
  },
  "tts": {
    "vendor": "google", "voiceId": "he-IL-Chirp3-HD-<voice>", "style": { "rate": 0.92, "pitchSemitones": 2 },
    "fallback": { "vendor": "azure", "voiceId": "he-IL-AvriNeural" }
  },
  "catchphrases": [{ "vo": "vo:char.pilpel_owl.catch.hoo_hoo_lets_think", "text": "הוּ-הוּ, בּוֹאוּ נַחְשֹׁב!" }],
  "palette": { "primary": "#6B4FA0", "accent": "#F2B544", "onPrimary": "#FFFFFF" },
  "anchors": { "mouth": [0.52, 0.61], "handRight": [0.78, 0.55], "pointTip": [0.92, 0.48], "head": [0.5, 0.2] },
  "sizeClasses": {
    "guide_tutor": { "phone": "M", "tablet": "L" },
    "activity_helper": { "phone": "S", "tablet": "M" },
    "celebration_cameo": { "phone": "L", "tablet": "XL" },
    "map_companion": { "phone": "S", "tablet": "S" },
    "sticker": { "all": "XS" }
  },
  "availability": {
    "enabled": true, "distribution": "store", "personalUseOnly": false,
    "territories": ["*"], "from": "2027-01-01", "until": null,
    "entitlement": "subscription"
  },
  "licence": null
}
```

The `licence` field is used only for third-party IP (6.6). In the example the character is original, so it is `null`.

### 6.2 Standard character contract (`character-sm/v1`)
- Rive has **deprecated state-machine inputs in favour of Data Binding** (verified). The contract is therefore a **view model with fixed property names**.
- One state machine (`Main`) reacts to these properties. Its required states are named exactly: `idle`, `talk`, `listen`, `think`, `encourage`, `celebrate`, `surprised`, `sleepy`.

| Property | Type | Meaning |
|---|---|---|
| `state` | enum {idle, talk, listen, think, encourage, celebrate, surprised, sleepy} | Main behaviour |
| `mood` | enum {neutral, happy, encouraging, curious, calm, proud} | Facial colouring of any state; maps 1:1 to the tutor's `emotion` |
| `viseme` | number 0–8 (Rhubarb A–H, X) | Mouth shape, set every frame while talking |
| `mouthOpen` | number 0–1 | Amplitude fallback when there are no viseme cues |
| `gazeX`, `gazeY` | number −1…1 | Look at a target, e.g. the highlighted object |
| `pointAt` | number −1…1 | Optional pointing direction (in-world, never mirrored) |
| `celebrate`, `blink`, `wave` | trigger | One-shot actions |
| `sizeClass` | enum {XS, S, M, L, XL} | Lets the artist simplify detail at small sizes |

- **Views drive any character the same way** through `CharacterController.set(state, mood)` and `LipSyncDriver`.
- Optional extras, for example a `dance` trigger, are declared in the manifest. Views must check that an extra exists before using it.

### 6.3 Role slots and runtime resolution
- **The slots:**
  - `guide_tutor`: the companion who speaks the tutor lines;
  - `domain_friend`: hosts a domain's world on the map;
  - `activity_helper`: stands inside an activity and points or demonstrates;
  - `celebration_cameo`;
  - `map_companion`;
  - `sticker`: a static reward.
- **Activities and views reference only slots:** `"characters": [{ "slot": "activity_helper", ... }]`.
- **The `CharacterResolver`** fills each slot by priority:
  1. the companion the child chose, if its manifest allows that role;
  2. the domain friend for the current domain;
  3. the activity's suggested default;
  4. a house character that is always bundled.

  Only *available* packs take part: enabled, inside the date and territory window, entitled, licence valid, and allowed in this build.
- **Progress never belongs to a character.** Progress, stickers and companion choice are keyed to the child and to slots. If a pack is removed or disabled, the resolver quietly falls back to the next candidate, and earned stickers render as a neutral silhouette with the same name. Nothing breaks.
- **Gender agreement.** Tutor lines follow the *child's* grammatical gender. Lines where a character refers to itself use the character's `grammaticalGender` from the manifest. Pre-recorded VO stays neutral.

### 6.4 Distribution, flags and validation
- **Packaging.** Characters ship as **signed, downloadable content packs** (5.2). The starter house character is bundled with the app.
- **Remote control.** Remote config can enable or disable any pack by id, territory, app version or date. Rules with an end date (`until`) and a global **kill switch** take effect at the next launch, or within 15 minutes while the app is running.
  - When the app is offline, a pack whose `until` date has passed is disabled locally, because each pack carries its availability window in its signed manifest.
- **CI pack validator**, `pack_builder validate-character`:
  - **Rive check:** loads the `.riv` file with the runtime and enumerates the view model's properties (the runtime can list a view model's properties; verified in the Rive data-binding docs). It fails if a required property, enum value or state is missing, and renders every state at each size class to golden images.
  - **VO check:** every required line set is complete and every line has a mouth-cue file. It also checks loudness and length, and that `name.he` is vocalised.
  - **TTS check:** the voice id resolves and a test phrase synthesises.
  - Palette contrast checks, anchors inside bounds, and the licence rule (6.6).
- **Character Sandbox**, a dev and beta screen, also inside Studio Preview. Designers see a new character in **every slot**, every state and mood and every size class, on phone and tablet frames, with sample VO and TTS. Toggles cover band, child gender and RTL.

### 6.5 Lite packs: owner-supplied images
For personal and family use, a **lite pack** is a manifest plus a few images. The engine animates them procedurally, so a lite character works in every slot.

**Contents** (PNG or WebP, transparent background, about 1024 px, centred in a shared canvas; at most 8 MB per pack):

| Image key | Required | Used for |
|---|---|---|
| `idle` | yes | Default; also the sticker |
| `talk_open`, `talk_closed` | yes | Mouth-flap lip-sync |
| `happy` | yes | encourage / celebrate |
| `thinking` | yes | think |
| `listening` | yes | listen |
| `sad_encouraging` | yes | "let's try again" moments; gentle, never upset |
| `blink` (eyes-closed overlay) | optional | Random blinks every 2–6 s |
| `surprised`, `sleepy` | optional | Otherwise mapped to `happy` and `idle` |

**Procedural animation** (`LiteCharacterView`, which implements the same `CharacterView` API as Rive):
- An idle "breathing" bob of 2–3% scale and a gentle sway.
- Squash and stretch on landing and on celebrate.
- An optional blink overlay.
- Entrance and exit tweens: hop-in, pop and slide.
- A hop with confetti on `celebrate`; head tilt on `think`; lean towards the screen on `listen`.
- **Mouth-flap lip-sync driven by audio amplitude** from SoLoud's wave data. It switches between `talk_open` and `talk_closed` using a hysteresis threshold, with at least 70 ms per frame, so it does not flicker.
- Gaze is approximated with a small horizontal offset and flip, and anchors come from the manifest.

**Voice.** A lite pack has no studio VO. It sets `tts.voiceId` and `style` (rate and pitch), so the tutor speaks "as" that character:
- Dynamic lines go through the tutor TTS path.
- Fixed instructions keep the narrator's VO. Optionally, the owner pre-synthesises the core line sets with the pack's voice at import time, which caches them for offline use.

```json
{
  "schema": "character-lite/v1",
  "id": "lite.family.blue_robot",
  "tier": "lite",
  "name": { "he": "רוֹבּוֹ", "grammaticalGender": "m" },
  "roles": ["guide_tutor", "activity_helper", "celebration_cameo", "map_companion", "sticker"],
  "ageBands": ["A", "B", "C"],
  "images": {
    "idle": "idle.png", "talk_open": "talk_open.png", "talk_closed": "talk_closed.png",
    "happy": "happy.png", "thinking": "thinking.png", "listening": "listening.png",
    "sad_encouraging": "sad_encouraging.png", "blink": "blink_overlay.png"
  },
  "motion": { "bounciness": 0.6, "idleSway": 0.3, "entrance": "hop_in" },
  "tts": { "vendor": "azure", "voiceId": "he-IL-AvriNeural", "style": { "rate": 0.95, "pitchSemitones": 3 } },
  "palette": { "primary": "#2D7FF9", "accent": "#FFD23F" },
  "anchors": { "mouth": [0.5, 0.62], "pointTip": [0.85, 0.5] },
  "availability": { "distribution": "personal", "personalUseOnly": true },
  "licence": null
}
```

(The name רוֹבּוֹ is "Robo".)

**How the owner adds one.**
1. Create a folder or zip containing `manifest.json` and the images.
2. Import it through **Import character** in the parent area, behind the gate, from Files or Drive, or through the `dev` tool (`studio import-lite <folder>`).
3. The importer validates it: schema, required images present, transparency, canvas size and centre alignment, file size, a TTS test phrase, and that the Hebrew name has nikud.
4. The importer shows the **Character Sandbox preview** in every slot.
5. On save, the pack is stored **on that device only, under the parent account**. It can be shared to the family's other devices through sync, but it is never uploaded to the CDN.

**`personalUseOnly`.**
- Packs with this flag set are **never distributed**.
- The CDN publisher refuses them.
- Store-flavour builds exclude them: the build fails if a flagged pack is in the bundled assets.
- The production app hides the import screen behind a `personalPacks` capability, which is off in store builds unless the owner decides otherwise.
- Swapping or removing a lite pack follows the same fallback rules as 6.3. Progress and views never break.

### 6.6 Licensed third-party characters
- **Policy.** Characters owned by a third party, for example a major studio's franchise characters, ship in store builds **only under a signed licence**. Until then they exist only as owner-supplied `personalUseOnly` lite packs on the owner's family devices.
- **Licence metadata**, required whenever `distribution` is `store` and the character is not our original IP:

```json
"licence": {
  "licensor": "<Licensor legal name>", "agreementId": "<contract ref>",
  "properties": ["<character name as licensed>"],
  "territories": ["IL"], "start": "2027-03-01", "end": "2029-02-28",
  "approval": { "status": "approved", "approvedAssetsHash": "sha256:…", "approvedAt": "2027-02-10" },
  "usage": { "roles": ["celebration_cameo", "sticker"], "ttsVoiceAllowed": false, "aiDialogueAllowed": false },
  "creditLine": "© <Licensor>", "killSwitch": "lic.<agreementId>"
}
```

- **Enforcement** at three points:
  - **The CI publisher** refuses a store pack whose licence is missing, not `approved`, or out of date, or whose asset hash differs from the approved one.
  - **The app** enforces territory and dates offline from the signed manifest, and honours the licence kill switch.
  - **The resolver** enforces `usage`. Licensors often forbid AI-generated dialogue or synthetic voices for their characters, so the tutor would use the narrator instead.

### 6.7 Effort to add one character after launch (estimate)

| Step | Who | Full Rive pack | Lite pack |
|---|---|---|---|
| Concept, turnarounds, palette | Character designer | 3–5 days | owner: images |
| Rive rig to `character-sm/v1`: 8 states, moods, 9 visemes, size classes | Rive animator | 6–10 days | — |
| Manifest, anchors, size classes | Content-ops | 0.5 day | owner: about 30 min |
| VO: casting plus about 150 core lines, cues | Audio producer + studio | 2–3 days | TTS voice choice: about 15 min |
| TTS voice and style tuning | Audio + ML engineer | 0.5 day | included |
| Validation, sandbox review, child playtest | QA + Design | 1–2 days | import validator + sandbox |
| Remote-config rollout | Content-ops | 0.5 day | — |
| **Total** | | **≈ 14–22 person-days, no engineering and no app release** | **≈ 1–2 hours after the art exists** |

---

## 7. Learning engine

**Design goal: genuine understanding at the child's own pace.** The engine:
- finds the actual gap;
- explains it a different way;
- practises it playfully;
- then **comes back later to check that the understanding lasted**.

Every rule below is a parameter shipped with content, so Curriculum can tune it without engineering.

### 7.1 Skill graph and diagnostic walk
- **The skill graph.** Skills form a DAG with weighted prerequisite edges (the `skill/v1` example in 5.1). Curriculum owns the graph; CI checks it for cycles, orphan skills, and skills with no items in some representation.
- **Diagnostic walk on a failure.** It starts after 2 failed attempts on a skill, or a misconception threshold crossed (7.2).
  1. Rank the skill's prerequisites by `weight × (1 − P(mastery))`. A prerequisite with stale retention (7.4) counts as weaker.
  2. Serve **one short probe item**, which is a `purpose: probe` item with no hints, for the weakest prerequisite. A probe is presented as a playful "can you help me?" moment, never as a test.
  3. If the probe fails, recurse into that prerequisite: at most depth 3 and 3 probes per session.
  4. If it passes, move to the next-weakest prerequisite. If every prerequisite passes, the gap is in the skill itself.
  5. Result: a `gap` record `{skill, foundAt, evidence}`. The session builder then schedules **repair on the gap first** and returns to the original skill afterwards.

### 7.2 Misconception evidence and repair
- **Where evidence comes from.** Every distractor, tap-trace pattern and expected wrong spoken answer can carry a misconception id (5.1). Each match adds evidence to `misconception_state` for that child:

  `score ← 0.8·score + strength`

  where strength is 1.0 for a tap answer and 0.5 for a voice answer accepted below 0.85 confidence. Correct answers on items that *could* have shown the misconception lower the score: `score ← 0.8·score`.
- **Triggers:**
  - `score ≥ 1.5` with at least 2 independent items marks the misconception **active**.
  - The builder then queues that misconception's `repairActivities`, in the misconception's preferred representations.
  - After 3 *diagnostic* items that could have shown it but did not, the misconception is **resolved**. It is checked again at the next revisit check.
- **Parents see** the misconception's `parentText` in plain Hebrew. Children never see labels.

### 7.3 Representations: different ways to explain
- **Five representation kinds per skill:**
  - **concrete**: virtual manipulatives such as blocks, counters and a ten-frame;
  - **pictorial**;
  - **story**: a character problem or narrative;
  - **embodied/song**: clap, jump or a counting song with movement;
  - **symbolic**: numerals and signs.

  Items carry `representation`, and skills list the kinds they support.
- **Switching after struggle.** After 2 errors, or a hint at level 3, the next item uses a **different** representation:
  - chosen by a per-child Thompson-sampling bandit over the representation kinds;
  - the reward is success on the *next two* items of that skill;
  - priors come from Curriculum, e.g. concrete first for Band A.
- **Recorded per child.** `representation_stats` holds (child, skill family, representation, tries, successes). The bandit uses it, and so does the parent view ("learns well with hands-on objects").
- **Concreteness fading.** For mastery the child must succeed on the skill's `masteryRequires.representations`, usually including symbolic. Concrete support is faded out gradually, not removed in one step.

### 7.4 Mastery with memory: two layers
1. **Mastery estimate** (BKT per skill, plus Elo item difficulty):
   - BKT parameters: P(L0), P(T), P(G) and P(S). P(G) is 1/k for k-option choices and about 0 for open drag or trace tasks.
   - Evidence weights: hint credit, low-confidence voice (×0.5) and "I'm not sure" (7.6).
   - Elo: `p = g + (1−g)·σ(θ − b)`, used to choose items in the target success band (**0.80–0.90 in Band A, 0.75–0.85 in Bands B–C**).
   - Parameters are refit on the server every quarter and shipped in packs.
2. **Retention**, an FSRS-style memory model per skill:
   - Each skill keeps a stability *S* (days) and a difficulty *D*.
   - Retrievability is `R(t) = (1 + (19/81)·t/S)^(−0.5)`, the FSRS-4.5/5 form, which gives R = 0.9 when t = S (verified).
   - The next check is scheduled when R falls to the skill's `targetRetention` (default 0.9, so t = S). It is capped by a minimum gap of 1 day and a maximum of 90 days.
   - A successful delayed check raises *S*. The gain is bigger when R was lower, and smaller when the skill is harder (*D*). A failure resets *S* lower and marks the skill `needs_revisit`.
   - FSRS stability updates and difficulty mean-reversion use open-source default weights, refitted later on our data.
   - **Alternative:** half-life regression, `p = 2^(−Δ/h)` with `h = 2^(Θ·x)`. Duolingo reported roughly half the error of Leitner (verified). The `RetentionModel` interface allows either. FSRS is the default because it works with per-skill data before global training data exists.

**Status per skill:**

| Status | Rule | Parent label (Hebrew UI; meaning) |
|---|---|---|
| `not_started` / `ready` | prerequisites below or above 0.8 | — |
| `learning` | P(L) < 0.95 | **practicing** |
| `fresh_mastery` | P(L) ≥ 0.95, at least 4 successes over at least 2 days, mastery representation and understanding checks passed (7.5) | **practicing** (almost there) |
| `durable_mastery` | fresh mastery **plus a passed delayed check at least 7 days later** using a *different* item from the `variantGroup`, with R still at or above target | **understood** |
| `needs_revisit` | a failed delayed check, or R below 0.7 | **needs a revisit** |
| `gap` | found by a diagnostic walk; repair pending | **gap found** |

### 7.5 Understanding checks beyond accuracy
Mastery requires more than correct answers on the familiar format. Each skill's `masteryRequires.checkTypes` lists which checks apply:

| Check type | Example | Bands |
|---|---|---|
| **transfer** | count circles after learning with balloons; a new context or format | all |
| **reverse** | "make 3" (build the set) after "how many?"; 5 − 2 after 2 + 3 = 5 | all |
| **error_spotting** | "the robot counted these, is it right?"; find the bug in a CS sequence | B, C |
| **predict** | "where will the robot be after these 3 steps?" | B, C |
| **explain_back** (voice, optional) | "how did you know?" | C (B optional) |

How explain-back is assessed:
- On-device ASR plus keyword or concept spotting against a rubric, e.g. *counted each one / one at a time*.
- With AI enabled, the LLM rubric scorer receives the *transcript text only*, never audio.
- It counts **only as positive evidence**: a missed or unclear explanation never lowers mastery. Tapping instead is always fine.

### 7.6 Self-paced, and "I'm not sure"
- **No fixed calendar.** Placement and progress are **per domain**:
  - a 3–5 minute placement mini-game per domain at onboarding;
  - the child may then be in Band A for Math and Band B for Shapes;
  - mastery moves each domain independently, and there are no deadlines.
- **"I'm not sure" is a first-class answer.** There is a "?" bubble on every item, and the voice intent "לֹא יוֹדֵעַ / לֹא יוֹדַעַת" ("I don't know") does the same.
  - It is **never penalised**: no error sound, and no negative effect on rewards.
  - The engine records it as an `unsure` outcome. That is weak evidence of not-yet-mastered: a BKT update weighted 0.3 as incorrect, and no misconception evidence.
  - It immediately starts the next hint or a representation switch with a warm line: "בּוֹאוּ נְגַלֶּה יַחַד!" ("let's find out together!").
  - Repeated "unsure" answers on a skill send the builder into a diagnostic walk instead of more items.

### 7.7 Session builder

| Phase | Band A (≈8 min) | Band B (≈12 min) | Band C (≈15 min) |
|---|---|---|---|
| Warm-up (easy, high success) | 1 item | 1–2 | 2 |
| Repair (active gaps/misconceptions, if any) | ≤ 25% | ≤ 25% | ≤ 25% |
| Focus (1–2 learning skills; representation per 7.3) | 35–55% | 35–50% | 30–45% |
| **Revisit checks** (due by retention; interleaved across domains in B–C) | 15–20% | 20–25% | 25–30% |
| Delight (creative, low stakes) | 20% | 20% | 20% |
| Wind-down celebration, then stop | always | always | always |

- **Progression limits.** A skill unlocks only when all its prerequisites reach P(L) ≥ 0.8. At most 2 new skills per session.
- **After struggle.** After 2 errors on a skill: switch representation, then run a diagnostic walk. The same item is never simply repeated.
- **Variety.** Revisit checks always use a different item in the `variantGroup`. Band A is kept mostly blocked by domain; Bands B–C are interleaved.
- **Ending.** Sessions **end** rather than loop, with one optional "one more" if the parent allows it.
- **No streaks and no loss framing.** The EU's 2025 guidelines on minors discourage streaks and engagement counters (verified via Bird & Bird).

### 7.8 Data model (on-device in Drift, mirrored on the server)

| Entity | Key fields |
|---|---|
| `parent_account` (server) | id, auth_provider, region, created_at (the email address stays with the auth provider) |
| `consent` | parent_id, kind (terms, ai_tutor, voice_on_device, cloud_asr, research_audio, parent_analytics, personal_packs), policy_version, method, granted_at, revoked_at; append-only |
| `child_profile` | id (random UUID), parent_id, nickname?, avatar_id, **companion_character_id**, grammatical_gender, age_range, settings. **No date of birth, photo, school or location.** |
| `domain_progress` | child_id, domain, band, theta, placed_at |
| `skill_state` | child_id, skill_id, p_mastery, status (7.4), n, n_correct, n_unsure, checks_passed {transfer, reverse, …}, mastery_reps_passed[] |
| `retention_state` | child_id, skill_id, stability_days, difficulty, last_check_at, next_check_at, fresh_mastery_at, durable_mastery_at |
| `misconception_state` | child_id, misconception_id, score, status (suspected/active/resolved), evidence_count, last_seen_at |
| `gap` | child_id, origin_skill_id, gap_skill_id, found_at, status (open/repaired), probe_attempt_ids[] |
| `representation_stats` | child_id, skill_family, representation, tries, successes |
| `session` | id (UUIDv7), child_id, started/ended_at, plan, end_reason |
| `attempt` | id (UUIDv7), session_id, activity_id, revision, pack_version, skill_ids, purpose, check_type, representation, outcome (correct/incorrect/unsure/timeout), error_class, misconception_ids[], hints_used, input_mode, asr_confidence?, latency_ms, character_slot_map. Immutable. **No audio and no transcript.** |
| `tutor_turn` | attempt_id, policy (rule/llm), action_json, latency_ms |
| `character_install` (device) | character_id, tier, version, distribution, personal_use_only, licence_status, installed_at |
| `reward_state`, `experiment_assignment` | stickers (keyed by character id plus a silhouette fallback); experiment variant |
| Device only | `pack_install`, `tts_cache`, `outbox` |
| Server only | `item_stats` (p_correct, b_calibrated), `param_fits` (BKT/FSRS weights per skill family) |

- **Sync by replay.** Every derived table (skill, retention, misconception, gap, representation) **can be recomputed** by replaying `attempt` events through the same Dart engine. Multi-device sync is therefore event replay: devices converge on the same state, and the logic is never re-implemented on the server.
- **Parent view per skill**, from `skill_state` + `retention_state` + `gap`: **understood / practicing / needs a revisit / gap found**, with the misconception's `parentText` and "learns well with …" from `representation_stats`.

---

## 8. Voice pipeline

### 8.1 (a) Voice-over: studio-recorded human voice is the primary source
- **Casting.** One narrator and one voice per character: native Israeli Hebrew, warm, and slower for Band A.
- **Scripts.** Exported from the CMS with nikud, pronunciation notes and a screenshot for context. Gender-neutral wording throughout.
- **Variety.** We record 15–30 variants of frequent feedback lines, so a child rarely hears the same line twice in a session.
- **Lines with a slot** (a number or colour plus a noun):
  - Up to about 200 combinations per prompt family, we record every full line.
  - Beyond that, we record a carrier phrase and the slot words with matched intonation, joined with 15 ms crossfades. Every join is checked by ear.
- **Formats.** WAV masters, then Ogg/Opus 32 kbps (5.5). SoLoud plays Opus natively (verified).
- **Lip-sync.** `LipSyncDriver` reads the playback position each frame and sets the Rive `mouth` from the cue file. If a line has no cues, it falls back to the amplitude envelope (SoLoud wave data).
- **Volume.** About 3,500 lines for the MVP, roughly 10–14 studio days (estimate).

### 8.2 (b) Dynamic TTS for the AI tutor
**Design decision: whichever character fills the `guide_tutor` slot speaks *all* its tutor lines in the one TTS voice its manifest names** (6.1).
- RuleTutor lines are pre-synthesised in each character pack, so a character sounds the same online and offline.
- Mixing a human narrator with a different synthetic character works. The *same* character switching between a human and a synthetic voice does not.
- A full-pack character with studio VO therefore needs either a contracted, consented TTS clone of its voice actor, or a design where its studio lines are only reactions (catchphrases, celebrations) and its tutor speech is synthetic (open decision 1).
- **No voice cloning of real people without a written contract and consent**, and never for licensed characters unless the licence allows it (6.6).

| Option | Hebrew status (verified) | Strengths | Gaps | List price |
|---|---|---|---|---|
| **Google Chirp 3 HD** | he-IL supported, not marked preview; streaming; EU region GA | Very natural; streaming Opus/PCM output | No custom pronunciation or pause control for he-IL; no SSML when streaming | $30 per million characters; first million free each month |
| **Azure neural** | he-IL **Hila** (female) and **Avri** (male), both GA (third-party voice catalogue) | SSML, custom lexicon, viseme events with audio offsets; EU regions | Only two voices; he-IL viseme support unconfirmed; Israel Central is not a Speech region | ≈ $15 per million characters (pricing aggregator, Oct 2026) |
| **ElevenLabs** | Hebrew on v3, v3 Conversational (~280 ms), v4 and **v4 Turbo (~100 ms)**; **not** on Flash v2.5 or Multilingual v2 | Most expressive; custom character voices | Price, data-processing agreement (DPA) and residency not verified | not verified |
| On-device (Phonikud + small TTS model) | Research shows small local models "approach large proprietary systems" | Offline, free | Not proven in production | n/a |

- **Selection (spike 3).**
  - A blind listening test of 40 tutor lines with 10 Israeli parents and 5 early-childhood teachers. It scores warmth, clarity for a 4-year-old, stress placement and gender forms.
  - A pronunciation regression set.
  - Time-to-first-byte measured from Israel to EU endpoints.
  - **My prior: Chirp 3 HD for quality, with Azure as the more controllable fallback.**
- **Text preparation.** The text goes through `hebrew_text`: vocalise known words, turn numbers into words with the right gender, strip emojis. **No names or other PI ever go to TTS.**
- **Caching.**
  - Key: `sha256(vendor, voice, model, text, rate)`.
  - A 50 MB least-recently-used Opus cache on the device.
  - An R2 cache on the server for repeated lines. These contain no child data: the text is about the activity.
  - Each month, frequent LLM lines are promoted into an offline **phrasebook pack** after review.

### 8.3 (c) Recognising young children's Hebrew speech
**Open dictation will fail for young children. Choosing among a few known answers can work, and the design builds on that.**
- **The evidence:**
  - Whisper fine-tuned on child speech went from 13.9% to 9.1% word error rate (Kid-Whisper).
  - For Arabic-speaking children aged 6–13, the best Whisper model scored 0.66 WER, against under 0.20 for adults.
  - The CHILDES Hebrew BSF corpus (ages 1;6–5;11) has transcripts only; its audio is "no longer available" (verified).
  - So no public Hebrew child-speech audio exists for us, and ages 3–4 will be hardest (assumption).

| Engine | Hebrew status (verified) | Biasing | Privacy | Verdict |
|---|---|---|---|---|
| **ivrit.ai Zipformer2 66M streaming** via sherpa-onnx | Hebrew-specific; **5.1 / 8.9 WER** (vs 5.3 / 7.1 for ivrit's Whisper-turbo); int8; 1.28 s chunks; CC-BY-4.0 | Hotwords (to verify) plus our own matcher | On-device, identical on both OSes | **Primary candidate** |
| Apple `SFSpeechRecognizer` | he-IL supported; Apple lists Hebrew under "On-Device Dictation" | `contextualStrings` | Force `requiresOnDeviceRecognition`; depends on Hebrew dictation assets being on the device | iOS alternative |
| Apple `SpeechAnalyzer` (iOS 26+) | Hebrew **not confirmed**; Apple admitted Arabic was wrongly listed as supported | Up to 100 contextual strings (Dictation) | On-device | Watch; check `supportedLocales` at runtime |
| Android `SpeechRecognizer` | On-device API from API 31; support check and model download from API 34; Hebrew availability varies by device | Biasing extras (to verify) | Must use the on-device recogniser; the default may send audio to Google | Alternative where present |
| ivrit.ai Whisper large-v3-turbo (0.8B, Apache-2.0) | Strong Hebrew | Prompt | Too heavy for 2–3 GB devices | Server-side only, for labelling the evaluation set |
| Google STT Chirp 3 | Hebrew `iw-IL` **Preview**; streaming; EU region | Adaptation (Hebrew support unconfirmed) | Cloud | Opt-in fallback only |
| Azure STT | he-IL supported; **Custom Speech accepts Hebrew audio + text** | Phrase list for he-IL unconfirmed | Cloud, EU regions | Later route to a child-adapted model, with consent |

**Decision.**
- Default: on-device ivrit.ai Zipformer on both platforms.
- The bake-off on our child evaluation set (13.1) may choose native recognisers per device instead.
- Cloud recognition is only ever a separately consented option.
- The CC-BY attribution goes on the credits screen.

**How the matcher works (`answer_matcher`, pure Dart):**
1. **Constrain to expected answers.** `hebrew_text` expands each answer into an accept-list. For 3 it includes:
   - שָׁלוֹשׁ, שְׁלוֹשָׁה, שְׁלֹשֶׁת and the digit "3";
   - number plus noun (שלוש בלונים);
   - prefixed forms (וְשָׁלוֹשׁ, "and three");
   - child pronunciations (שָׁלוֹס).

   Colours accept all four gender and number forms. Near-misses such as תְּכֵלֶת (light blue) for כָּחֹל (blue) are *soft* matches that lead to a confirm step.
2. **Global intents are always available:**
   - repeat: עוֹד פַּעַם ("again"), מָה? ("what?");
   - help: לֹא יוֹדֵעַ / לֹא יוֹדַעַת ("I don't know"), עֶזְרָה ("help");
   - stop: דַּי ("enough").
3. **Normalise:**
   - strip nikud;
   - fold final letters (ך→כ, ם→מ, ן→נ, ף→פ, ץ→צ);
   - remove one-letter prefixes (ו ה ב ל כ ש מ) when the rest is a known word;
   - convert digits to values.
4. **Score.** Compare the n-best hypotheses with the accept-list using edit distance on a Hebrew phonetic key: consonant skeleton plus confusable sets (כ/ח, ת/ט, ק/כ, א/ע/ה, ב/ו, and child substitutions such as ר→ל).
   - `score = confidence^0.5 × similarity`.
   - It must beat the next-best expected answer by a margin.
5. **Decide:**
   - **≥ accept (0.75):** take the answer.
   - **confirm (0.50–0.75):** the mascot asks "שָׁלוֹשׁ?" ("three?") and highlights that option; the child taps or says "כֵּן" ("yes").
   - **Below 0.50 or silence:** "I didn't hear — say it again or tap." **Never scored as wrong.**
   - Thresholds can be set per item and are tuned on the evaluation set.
6. **Fallback.**
   - After 2 failed listens, the mic fades and the tap targets pulse.
   - A per-child *voice-reliability* score per answer type quietly stops inviting voice where recognition keeps failing.
7. **Mic hygiene.**
   - Tap-to-talk with voice-activity auto-stop; never always-on, never in the background.
   - VO is stopped before listening.
   - Echo cancellation and noise suppression on.
   - Utterances capped at 5 s.

**Latency budget: from end of speech to feedback.**

| Step | Target |
|---|---|
| Tap → "listening" animation | ≤ 100 ms |
| Mic ready (pre-warmed when the item loads) | ≤ 150 ms |
| End-of-speech silence (Band A / B / C) | 700 / 600 / 500 ms |
| Final recognition (streaming, int8) on the reference low-end device | ≤ 150 ms |
| Match and decision | ≤ 10 ms |
| Feedback audio and animation (preloaded) | ≤ 80 ms |
| **End of speech → feedback** | **≤ 1.0 s p50, ≤ 1.4 s p90** |

A strong, stable partial result can be accepted after 300 ms of silence, which saves about 300 ms.

---

## 9. AI tutor

### 9.1 Architecture
**In the MVP the tutor is not an open chat.** It writes targeted hints, encouragement and short explanations inside activities. Because its input is structured, there is little room for prompt injection or for a child to disclose personal details. Free conversation, such as a Band C "explain how you solved it", comes later and needs separate parental consent.

```
Device TutorPolicy ──HTTPS + 15-min token (App Attest / Play Integrity)──▶ Tutor Gateway (EU)
  structured context only (no name, audio or transcript)     auth · caps · prompt · cache
                                                             ├─▶ LLM (Haiku 5.5 | Gemini Flash failover)
                                                             ├─▶ validator + Hebrew moderation
                                                             └─▶ streaming TTS + cache
  ◀── SSE: action JSON first, then audio ──┘
  timeout / offline / AI off / invalid ─▶ RuleTutor (same TutorAction schema)
```

- **No vendor API keys exist on the device.**
- **When the LLM is called:**
  - after the 2nd wrong attempt, for a targeted hint;
  - when the child asks for help;
  - for a short explanation after a hard item is solved (Bands B–C).

  Everything else is RuleTutor.
- **What the LLM receives**, all structured:
  - band, grammatical gender, and the speaking character's name and self-gender (6.3);
  - the activity's `goal`, the item, and its current representation;
  - the last 3 *structured* attempts (e.g. "chose 4; touch trace shows balloon 2 counted twice");
  - the current hint level and the allowed actions;
  - the tutor's last 5 lines.
- **It also receives a learner-state summary** built from the 7.8 tables:

```json
"learner_state": {
  "skill": { "id": "num.count.1to5", "status": "learning", "p_mastery": 0.62,
             "retention": "fresh_mastery_pending_check", "checks_passed": ["reverse"] },
  "active_misconceptions": [{ "id": "num.count.double_count", "score": 1.8,
                              "description": "Counts the same object more than once" }],
  "open_gap": null,
  "representations_tried": [{ "kind": "pictorial", "tries": 3, "successes": 1 },
                            { "kind": "concrete", "tries": 0, "successes": 0 }],
  "representations_available": ["concrete", "embodied", "story", "symbolic"],
  "unsure_count_this_skill": 1
}
```

- **What it never receives:** a name, the child's speech (except the transcript text for Band C explain-back scoring, 7.5), device data, or raw history from other sessions.

### 9.2 Model selection (model names checked on Anthropic's docs today)

| Model | ID | Price per million tokens, input / output | Role |
|---|---|---|---|
| **Claude Haiku 5.5** | `claude-haiku-5-5` | $0.10 / $0.50 for prompts ≤ 100k tokens; cache hits $0.01 | **Default**: fastest tier; structured outputs supported |
| Claude Sonnet 5.5 | `claude-sonnet-5-5` | $2 / $10 | Fallback if Haiku fails the Band C evaluation; offline authoring help, always reviewed by a person |
| Gemini 3.6 Flash | `gemini-3.6-flash` | $0.75 / $3.75 (doubles 1 Jan 2027) | Evaluated alternative and failover; paid-tier data is not used to improve Google's products |
| Gemini 3.1 Flash-Lite | `gemini-3.1-flash-lite` | $0.25 / $1.50 | Low-cost alternative |

- **How we choose.** `tools/tutor_eval` runs 300 scenarios across 3 bands × 2 genders. Israeli educators score each response blind for:
  - correct teaching;
  - not leaking the answer;
  - **gender agreement**;
  - brevity and age-appropriate words;
  - warmth;
  - TTS-friendliness.

  An LLM judge pre-screens; humans decide. **We pick the cheapest model that passes.**
- **Vendor terms to check before launch.**
  - Anthropic's guidelines for organisations serving minors require extra safeguards, use of any child-safety system prompt Anthropic provides, COPPA-level compliance and **disclosure that the user is talking to AI**. Anthropic audits compliance (verified).
  - Confirm contractually that our data is not used for training, the retention period, and the region. The Claude API offers `inference_geo: "us"` at 1.1× price. For EU processing, check Anthropic's data-residency options or Bedrock/Vertex EU endpoints (about a 10% premium).

### 9.3 Structured output
- The JSON Schema is passed in `output_config.format` (verified).
- Claude's structured outputs do not support numeric or length constraints, so our validator enforces them.
- Required fields come out in schema order. The gateway can therefore animate `emotion` and start TTS on `say_text` before the full object arrives.

```json
{
  "type": "object", "additionalProperties": false,
  "required": ["emotion", "say_text", "hint_level", "next_action", "switch_representation", "target_misconception", "highlight_targets", "reveals_answer", "safety_flag"],
  "properties": {
    "emotion": { "enum": ["neutral","happy","encouraging","curious","thinking","surprised","celebrating","calm"] },
    "say_text": { "type": "string", "description": "Hebrew, ≤2 short sentences, child's grammatical gender" },
    "hint_level": { "enum": [0, 1, 2, 3] },
    "next_action": { "enum": ["wait_for_answer","replay_prompt","highlight_targets","demonstrate","switch_representation","simplify_item","start_repair","next_item","end_activity"] },
    "switch_representation": { "enum": ["none","concrete","pictorial","story","embodied","symbolic"] },
    "target_misconception": { "type": "string", "description": "id from active_misconceptions, or empty" },
    "highlight_targets": { "type": "array", "items": { "type": "string" } },
    "reveals_answer": { "type": "boolean" },
    "safety_flag": { "enum": ["none", "off_topic", "unsafe"] }
  }
}
```

- `emotion` maps onto the character contract's `state`/`mood` (6.2).
- `switch_representation` and `start_repair` are **suggestions**. The session builder accepts them only if the chosen representation exists for the skill and repair is allowed in the current phase. Otherwise it keeps its own choice.

Example for a Band A girl who counted a balloon twice ("Almost! Let's count together, each balloon only once."):

```json
{"emotion":"encouraging","say_text":"כמעט! בואי נספור יחד, כל בלון רק פעם אחת.","hint_level":2,"next_action":"switch_representation","switch_representation":"concrete","target_misconception":"num.count.double_count","highlight_targets":["obj1","obj2","obj3"],"reveals_answer":false,"safety_flag":"none"}
```

### 9.4 Guardrails, scope and moderation
- **System prompt** (a cached prefix of about 2.5k tokens) sets:
  - the persona;
  - the band's language level;
  - the child's grammatical gender;
  - **never ask about or comment on personal information**;
  - stay inside the activity;
  - never reveal the answer before `mustNotRevealBeforeHint`;
  - no negative judgement, guilt, pressure or "don't leave" lines;
  - no purchases, apps or links;
  - the tutor says it is a computer helper, never a person.
- **Scope by band:**
  - **A:** one sentence of at most about 8 words; only replay, highlight or demonstrate.
  - **B:** at most 2 sentences and one guiding question.
  - **C:** at most 3 sentences; may ask Socratic "why" questions and simplify the item.
- **Server-side validator, run before TTS:**
  - schema and length checks;
  - Hebrew script only;
  - second-person gender agreement;
  - **answer-leak check**: no accept-list form of the correct answer before the hint threshold;
  - blocklists for PI questions, URLs, brands, purchases, and fear or violence words;
  - a Hebrew moderation classifier;
  - the action must be allowed for the template;
  - the speaking character's `licence.usage` must allow AI dialogue (6.6). If it does not, the narrator speaks instead.

  On failure: retry once, then RuleTutor.
- **Limits.** 20 LLM turns per session and 60 per day per child. A global daily spend cap and a remote kill switch.
- **For parents.** A 30-day "what the helper said" log in the parent area, with a **report** button. This also meets Google Play's expectation of user feedback on AI-generated content.
- **No emotion recognition.** `emotion` is the *mascot's* emotion. We never infer the child's emotions from voice or face; the EU AI Act prohibits emotion recognition in education.

### 9.5 Privacy
- **No child audio is stored by default.** Audio stays in memory on the device and is released once recognised.
- The gateway logs metadata under a pseudonymous ID, plus LLM text for 30 days for safety QA, and never logs audio.
- Vendors receive no identifiers.

### 9.6 Cost per active child per month (estimate)
Assumptions:
- **Typical child:** 12 sessions × 8 LLM turns ≈ 100 turns.
- **Heavy child:** 300 turns.
- **Per turn:** 2,500 cached input tokens, 600 fresh input tokens, 150 output tokens.
- **TTS:** 60 characters per line, 40% cache hits.

| Item | Typical | Heavy |
|---|---|---|
| Haiku 5.5 (≈ $0.00016 per turn) | $0.02 | $0.05 |
| TTS, Chirp 3 HD at $30 per million characters (Azure about half) | $0.11 | $0.32 |
| Gateway compute and egress | $0.02 | $0.05 |
| On-device ASR | $0 | $0 |
| **Total** | **≈ $0.15** | **≈ $0.42** |
| Same with Sonnet 5.5 (≈ $0.003 per turn) | ≈ $0.43 | ≈ $1.26 |

**TTS dominates the cost**, so caching and the phrasebook matter more than the choice of model. Google's free first million characters each month covers the beta.

### 9.7 Latency targets for a tutor turn
- **≤ 100 ms:** the mascot shows "thinking" and plays a pre-recorded "הממ…" ("hmm…").
- **First tutor audio: p50 ≤ 1.5 s, p90 ≤ 2.5 s.** Budget, all estimates:
  - Israel → EU round trip: about 60 ms;
  - gateway: about 30 ms;
  - LLM first token: about 400 ms;
  - `say_text` complete: about 300 ms later;
  - TTS first byte: about 250 ms.
- **Hard timeout at 3.0 s.** RuleTutor speaks and the late reply is dropped.

### 9.8 Deterministic fallback (RuleTutor)
- A decision table per template: (error class or misconception, attempt, hint level, band, representations tried) → `TutorAction` with a VO or phrasebook line. That includes representation switches and repair triggers, using the same rules as 7.2–7.3.
- Curriculum authors the tables in the CMS, and they ship in packs.
- RuleTutor runs whenever the device is offline, AI is off, the budget is spent or validation fails.
- **The learning experience must be complete with RuleTutor alone.** The LLM only adds variety and better-targeted hints.

---

## 10. Backend & services

| Service | Choice | Notes |
|---|---|---|
| Database, auth, storage | **Supabase, eu-central-1 (Frankfurt)** | No Israeli region (verified). Row-level security by parent; point-in-time backups. |
| API + Tutor Gateway | TypeScript (Hono) containers in the EU (Fly.io Frankfurt or AWS eu-central-1) | Stateless; SSE streaming |
| CDN | Cloudflare R2 | Packs, phrasebook audio, signed catalogue |
| CMS | Payload, self-hosted in the EU | Staff single sign-on; audit log |
| Analytics | First-party endpoint → ClickHouse/Postgres → self-hosted Metabase | No third-party SDK |
| Crash reporting | **Self-hosted Sentry** (or GlitchTip) in the EU | `sendDefaultPii=false`, `beforeSend` scrubbing, no screenshots or replay (verified hooks) |
| Subscriptions | **RevenueCat**, parent area only | Anonymous app user ID; no attribution integrations, no customer attributes. It collects purchase history, and device IDs only with ad integrations (verified). Needs a DPA. |
| Remote config / flags | Signed JSON on the CDN; later self-hosted GrowthBook or Unleash | No extra SDK |

- **Accounts.** Parents sign in with Apple, Google or an email code, in the parent area only.
  - **Children never log in.**
  - **No-account mode** (local profiles, no sync) is available as the minimal-data path.
- **Sync.** Local-first, with an append-only event outbox sent in batches over HTTPS when the app goes to the background and every 10 minutes during play.
  - Settings: field-level last write wins.
  - Learning state: converges by event replay (7.8).
  - Personal lite packs sync **only between the family's own devices**, through private per-account storage, never through the CDN. The parent can switch this off.
- **Analytics.**
  - Only events on an allow-list.
  - A random pseudonymous child ID. **No IDFA, AAID, IDFV or hardware IDs.** IP addresses are truncated at the edge. Device *class* only.
  - Each report slice needs at least 20 children.
  - Raw events are aggregated after 13 months.
  - Parent-area UX analytics is a separate stream that needs parental consent.
- **Admin console:**
  - one-click data export and delete, with backups purged within 30 days;
  - the consent ledger;
  - pack rollouts;
  - the tutor kill switch;
  - spend dashboards and validator failures.
- **Hosting region.**
  - EU hosting serves Israel and the EU, since Israel holds an EU adequacy decision that Amendment 13 was designed to preserve.
  - Latency from Israel to Frankfurt suits sync and the tutor.
  - Speech and LLM vendors run in EU regions: Azure West Europe / Germany West Central / Sweden Central, and Google `eu`.
  - **Counsel must confirm** Israeli outbound-transfer rules and the US subprocessors, such as RevenueCat.

---

## 11. Privacy, child safety & store compliance

### 11.1 Apple App Store Kids Category (guidelines 1.3 and 5.1.4)
**Status (verified):**
- No links out, purchasing opportunities or distractions, except behind a parental gate.
- No PII or device information sent to third parties.
- Kids apps "should not include third-party analytics or third-party advertising". Narrow exceptions apply only when no IDFA, identifiable data, location or device data is sent.
- A privacy policy is required.
- A birthdate or parental contact may be collected only for legal compliance.
- Age bands: **5 and under, 6–8, 9–11**.
- For pre-literate children, a voice-over prompt telling them to fetch a parent is recommended.

**What it means for the build:**
- **Child and parent shells are separated in code.** Links, the subscription, ratings, support and the policy live behind the gate.
- **A gate a reading 8-year-old cannot pass:**
  - a random multiplication written in Hebrew *words* ("שִׁבְעָה כָּפוּל שְׁמוֹנָה", "seven times eight"), answered on a keypad, plus a 2-second hold;
  - VO says "קִרְאוּ לְאַבָּא אוֹ לְאִמָּא" ("call Dad or Mum").
- **No third-party analytics or ads.** Crash reporting is self-hosted. RevenueCat is used in the parent shell only, with anonymous IDs.
- Speech, LLM and TTS calls are server to server, with no device or child IDs.
- Accurate privacy labels: aim for "Data Not Linked to You."
- **Intellectual property, guideline 5.2.1** (verified): "Don't use protected third-party material such as trademarks, copyrighted works, or patented ideas in your app without permission." Apps should be submitted by the rights holder or licensee. Character packs enforce this (6.6).
- **iOS 27 SDK** (verified, TN3192): a launch screen is required, and `UIRequiresFullScreen` no longer stops resizing (see 12.2).

### 11.2 Google Play Families policy and Expert (Teacher) Approved
**Status (verified):**
- Apps aimed only at children must not send AAID, SIM or build serial, BSSID, MAC, SSID, IMEI or IMSI, and should not request `AD_ID` on API 33+.
- They may not request location.
- Only APIs and SDKs approved for child-directed services.
- Ads only through Families-certified SDKs. We have none.
- The AI-generated content policy requires preventing offensive output and building in user feedback.
- **Target API 36 is required for updates from 31 August 2026.**
- The programme is now branded **"Expert approved"**. It rates age appropriateness, design, appeal, enrichment, and ads/IAP. Opting in is open to apps that meet the Families policies; inclusion is not guaranteed and Hebrew coverage is not stated.

**What it means for the build:**
- A CI check fails the build if `AD_ID`, location, phone or Bluetooth permissions appear in the merged manifest.
- An audit of every SDK, including confirming Play Integrity is acceptable under Families.
- **The Intellectual Property policy** (verified) bars copyright and trademark infringement, citing cartoon and movie artwork and indistinguishable fan art. The same character-pack gates apply (6.5–6.6).
- The parent "report a line" feature.
- Design to the Expert-approved rubric, and ask Google whether Hebrew apps are rated.

### 11.3 COPPA, as amended
**Status (verified):**
- Published 22 April 2025, effective 23 June 2025, **compliance required from 22 April 2026**. The FTC says enforcement is a priority.
- New obligations:
  - **Separate verifiable parental consent for disclosures to third parties**, unless the disclosure is integral to the service. Advertising and AI training are *not* integral.
  - A **written retention policy**; no indefinite retention.
  - A **written information-security programme**, with annual risk assessments and written assurances from vendors.
  - **Biometric identifiers, including voiceprints**, are now personal information.
  - An audio-file exception, provided the notice says audio is deleted immediately after use.
  - The notice must describe how persistent identifiers are used for internal operations.

**What it means for the build** (we design for this even before launching in the US):
- **By default, we collect nothing that needs more than the minimum:** pseudonymous IDs for internal operations, recognition on the device, and no PI sent to vendors.
- **Cloud ASR, research audio and parent analytics** require verifiable consent in the parent area. The method is to be chosen with counsel; the new rule adds knowledge-based and "text-plus" methods.
- Vendor DPAs must prohibit training on our data.
- **No voiceprints or speaker ID, ever.**
- Published retention: attempts until deletion or 24 months of inactivity; tutor text 30 days; crash data 90 days; CDN logs 7 days.
- `SECURITY_PROGRAM.md` in the repo, reviewed annually.

### 11.4 GDPR / "GDPR-K" and the EU AI Act
**Status (verified):**
- Under Article 8, where consent is the legal basis, a parent must consent for children under 13–16 (the age varies by member state), with reasonable efforts to verify.
- Privacy information must be child-friendly.
- The EDPB does not consider neutral age gates effective.
- The Commission's 2025 guidelines on minors call for the most protective defaults and no streaks.
- **EU AI Act:**
  - **Article 50 transparency applies from 2 August 2026.**
  - The AI Omnibus (Regulation 2026/1744, in force 27 July 2026) moves Annex III high-risk obligations, including education, to **2 December 2027**.
  - Emotion recognition in education is prohibited.

**What it means for the build:**
- **Legal basis:** a contract with the parent for the core service; consent for optional features.
- A **DPIA** before an EU launch.
- An Article 27 EU representative if we have no EU establishment.
- A pictogram notice for children plus a full notice for parents.
- AI disclosure to the parent at onboarding and to the child within the story ("the helper is a computer").
- **Counsel to decide whether the adaptive engine counts as Annex III high-risk.** We keep the documentation anyway: risk register, logs, and human oversight through parent controls.

### 11.5 Israel: Protection of Privacy Law and Amendment 13
**Status (verified):**
- **In force since 14 August 2025.**
- GDPR-style definitions and a category of "specially sensitive information."
- Section 11 notices: purpose, whether providing data is voluntary, recipients and rights.
- A **privacy protection officer** is required for public bodies, data brokers, systematic monitoring and large-scale sensitive processing. The Privacy Protection Authority (PPA) expects the officer to be properly resourced.
- Databases with sensitive data on more than 100,000 people must be notified to the PPA.
- The 2017 Data Security Regulations still apply, including penetration tests every 18 months at higher levels.
- Administrative fines, and statutory damages up to ILS 100,000 without proof of harm.
- Draft PPA guidance applies the law to AI systems.
- **There is no specific child-consent age.** Minors' consent works through guardianship, so parental consent is the practical norm. The regulator has held collection without parental consent unlawful.

**What it means for the build:**
- Hebrew section 11 notices in parent onboarding.
- Consent recorded in the ledger.
- **Appoint a privacy protection officer from launch:** cheap insurance for a children's product.
- Treat data as at least "medium" security level: access logs, a database definition document, an incident playbook and penetration tests.
- Plan the PPA notification before reaching 100k children.
- Ask counsel whether children's learning data counts as "specially sensitive."

### 11.6 Child-safety checklist (all regimes)
- No chat, user-generated content or public profiles.
- No push notifications to children. Parent reminders are opt-in, with quiet hours.
- No dark patterns: no countdowns, loss framing or sad-mascot exits.
- Parent time limits with a gentle wind-down.
- The mic runs only on a child's tap, with a visible indicator.
- A parent dashboard for progress, time, the helper log and voice/AI switches.

---

## 12. Responsive layout & devices

### 12.1 Support matrix

| Platform | Minimum | Notes |
|---|---|---|
| iOS / iPadOS | **16.0** | Flutter supports iOS 15+ (verified). iOS 16 simplifies audio-session and speech behaviour. Revisit at beta. |
| Android | **API 26** minimum, **target API 36** | Flutter supports API 24+. Impeller/Vulkan from API 29; older or non-Vulkan devices fall back to OpenGL (verified) and run the "lite" tier. |
| Reference devices | 2–3 GB Android tablet (Galaxy Tab A / Lenovo Tab M class), budget Android phone, iPhone SE, base iPad, iPad mini | The devices Israeli families hand to children (assumption; confirm in discovery) |

### 12.2 Layouts
- **Stage model.** Each activity renders on a safe stage with an aspect ratio between 4:3 and 19.5:9, with backgrounds that bleed beyond it.
  - Positions are stage-relative, using normalised zones from the spec.
  - Templates provide **"wide" and "tall" variants**, e.g. answer options in a row or a 2×2 grid.
  - This leaves Design free to choose orientation.
- **Breakpoints** by shortest side: < 600 dp phone; 600–839 small tablet; ≥ 840 large tablet.
- **Tap targets:** ≥ 64 dp in Band A and ≥ 56 dp in Bands B–C, with 12 dp gaps. No drag targets within 24 dp of the screen edge (gesture areas). `SafeArea` for everything interactive.
- **Tablets cannot be locked to one orientation any more.**
  - On Android, apps targeting API 36 have orientation, resizability and aspect-ratio locks **ignored on screens ≥ 600 dp**, unless the app is categorised as a game. The opt-out disappears at API 37 (verified).
  - On iPadOS, `UIRequiresFullScreen` is deprecated. With the iOS 27 SDK the system resizes the app "discretely", and the app must support all orientations (verified).
  - **So tablets support both orientations.** A preferred minimum scene size is set. Below the minimum stage size, a friendly "make me bigger" screen appears. Play pauses during an interactive resize and the layout is redone afterwards.
  - Phones may lock to whatever Design prefers.
- **Android fragmentation.** A first-run 2-second benchmark plus the RAM size picks one of three tiers:

  | Tier | Rendering | Effects | Frame rate |
  |---|---|---|---|
  | full | Rive Renderer | particles | 60 fps |
  | standard | Rive Renderer | fewer particles | 60 fps |
  | lite | Flutter renderer | no blur | 30 fps ambient, 60 fps interactions |

  Native libraries are built for 16 KB memory pages.

### 12.3 Performance budgets (low-end Android / iPhone SE)
- **Frame rate:** 60 fps during interaction, with ≥ 99% of frames under 16.6 ms. Impeller avoids shader-compilation jank.
- **Cold start** to an interactive screen: ≤ 2.5 s / ≤ 1.5 s. Item transitions ≤ 300 ms. Tap-to-sound ≤ 50 ms.
- **Memory** (PSS, the app's share of RAM):
  - ≤ 350 MB during play, or ≤ 450 MB with the ASR model loaded.
  - One character and one scene loaded at a time.
  - The ASR model is loaded only when voice is on, and unloaded after 2 minutes of idle.
- **Battery:** ≤ 8% per 15-minute session on the reference tablet. The render loop pauses when idle, and there is no background work except sync.
- **Network:** fully offline after install. A tutor turn sends ≤ 5 KB and streams about 15 KB per second of audio.

### 12.4 Accessibility
- Every prompt can be replayed; captions with nikud are optional.
- Large targets, generous drag snapping, and a tap-to-select / tap-to-place alternative to dragging. Nothing is timed unless Curriculum explicitly wants it.
- Colour tasks also use shape or pattern cues and colour-blind-safe palettes.
- High-contrast option; "reduce motion" is respected.
- Visual feedback always accompanies sound.
- Hebrew screen-reader labels in the parent area, and semantics nodes per template.
- **Voice is never required.** The reliability score adapts quietly to children with speech differences.

---

## 13. Quality engineering

### 13.1 Testing strategy
- **Unit tests** (≥ 90% coverage on engine packages):
  - BKT and Elo;
  - the scheduler;
  - the session builder, with property tests: no locked skill is served and the time budget is respected;
  - the diagnostic walk and misconception scoring;
  - FSRS retention scheduling and the transitions between mastery states (fresh → durable → needs revisit);
  - table-driven tests for the answer matcher over thousands of Hebrew variants;
  - grammar tables and schema validators;
  - the `CharacterResolver` fallbacks: a removed pack, an expired licence, a personal-use pack in a store build.
- **Learner simulation.** 10,000 synthetic learners with known skills, planted misconceptions, missing prerequisites and forgetting curves. Release thresholds:
  - mastery estimates converge;
  - success rates stay inside the target band;
  - planted gaps are found within at most 3 probes in at least 90% of cases;
  - planted misconceptions are flagged within at most 4 diagnostic items;
  - children whose durable mastery has decayed are scheduled for revisit before R falls below 0.8.

  This gates every change to learning parameters.
- **Widget and golden tests:** templates × layouts × device classes × bands in RTL with real fonts, plus the Hebrew-specific goldens (4.5) and Rive frames rendered at fixed times.
- **Content tests.** A headless playthrough of every published activity: the correct path, each tagged wrong path and the full hint ladder.
- **Content graph checks:**
  - every skill has items in each of its `masteryRequires` representations and check types;
  - every misconception has at least one repair activity;
  - every `variantGroup` has at least 3 items, so revisit checks can use a different one.
- **Character tests.** The pack validator (6.4) and Sandbox goldens for every slot, for both full and lite tiers.
- **Integration tests** (`integration_test` + Patrol for native dialogs):
  - onboarding → gate → profile → session;
  - offline → sync;
  - pack download, interruption and resume;
  - subscription sandbox.
- **Device lab.** 8–10 in-house physical devices (12.1, plus a foldable). Nightly performance runs check against the budgets in 12.3. A cloud device farm adds broad Android coverage.
- **Voice-recognition evaluation set.**
  - Children aged 3–8 recorded with **written, separate parental research consent**, stored in the consent ledger.
  - Collected in supervised sessions with partner kindergartens and schools, plus an opt-in programme for beta families.
  - Scripted answers cover every answer type: numbers 0–20 in both genders, colours in all forms, shapes, yes/no, directions and the help/repeat intents. Also off-script answers and background noise.
  - Metadata is limited to age range, gender and environment. No names.
  - Encrypted EU storage with access logs. Used for **evaluation and tuning only**; training would need separate consent. Deleted on request, and after 3 years at the latest.
  - **Target: about 300 children and 30k utterances by launch** (estimate).
  - Metrics, broken down by age range and engine:

    | Metric | Meaning | Launch target |
    |---|---|---|
    | Accept-precision | When we accept an answer, we heard it right | ≥ 97% |
    | Coverage | Utterances resolved without falling back to tap | ≥ 70% (Band A), ≥ 85% (Band C) |
    | False-reject rate | Correct answers we failed to accept | tracked |
    | Latency | End of speech to decision | tracked |

- **Tutor evaluation.** The scenario suite plus red-team prompts: disclosure attempts, off-topic requests, attempts to get the answer revealed. It runs on every prompt or model change; **any critical failure blocks release**.
- **Child playtests** every 2 weeks from the prototype onward. Engineers review frame drops, ASR decisions and rage-taps from those sessions.

### 13.2 CI/CD and releases
- **GitHub Actions** for analysis, tests, goldens, content validation and backend deployment.
- **Codemagic** (or macOS runners) with **Fastlane** for signing and store uploads.
- **Flavors:** dev (staging backend, debug menu, Studio QR), beta, prod.
- **Release train every two weeks:**
  1. internal build;
  2. **TestFlight internal / Play internal testing**;
  3. **TestFlight external / Play closed testing** with beta families;
  4. Play staged rollout (5 → 20 → 50 → 100%) and App Store phased release.
- Content ships separately through pack rollouts. **No code push in the child app.** Packs already allow iteration, and fewer moving parts make Kids Category review easier.
- **Release gates:**
  - all tests green;
  - no new beta crashes for 72 hours;
  - performance budgets met;
  - tutor evaluation passed;
  - a reviewed privacy-manifest diff (no new SDKs or permissions);
  - **for store flavours, no `personalUseOnly` or unlicensed character pack in the bundle or catalogue** (6.5–6.6).

### 13.3 Observability
- **App.** Self-hosted Sentry, targeting ≥ 99.8% crash-free sessions and < 0.2% ANRs (app freezes). One first-party performance sample per session: frame times, jank, start time, peak memory. Also ASR decision histograms and tutor/TTS latency.
- **Backend.** OpenTelemetry → Grafana (EU). SLOs: tutor first audio p90 ≤ 2.5 s; gateway availability 99.5%. The child degrades gracefully to RuleTutor.
- **Spend.** LLM and TTS cost per 1,000 active children per day, with alerts and automatic throttling.
- **Learning health**, reported weekly to Curriculum:
  - attempts needed to reach mastery, per skill;
  - **the fresh-to-durable conversion rate** and delayed-check pass rate per skill;
  - the most frequent misconceptions and the success rate of their repair activities;
  - which representations work, per skill family;
  - outlier items, hint rate, "I'm not sure" rate and frustration loops.

---

## 14. Team & roadmap

### 14.1 Engineering and production team (Curriculum and Design are covered by the other agents)

| Role | FTE |
|---|---|
| Tech lead / architect (Flutter, learning engine, performance) | 1 |
| Senior Flutter engineers (templates, Flame, Rive, RTL) | 2 |
| Native + audio/speech engineer (platform channels, SoLoud, sherpa-onnx, ASR evaluation) | 1 |
| Backend/platform engineer (Supabase, gateway, CMS, pack builder, CI, security programme) | 1 |
| ML/AI engineer (tutor prompts and evaluation, ASR thresholds; later child ASR) | 0.5 → 1 |
| QA / automation (device lab, goldens, beta) | 1 from mid-MVP |
| Rive technical animator(s) (characters to `character-sm/v1`, Sandbox reviews) | 1–2 |
| Audio producer / VO director + studio | 0.5 + contract |
| Content-ops / CMS specialist (nikud workflow) | 0.5 |
| Privacy counsel + privacy protection officer | contract |

### 14.2 Phases

| Phase | Duration | Outcomes |
|---|---|---|
| **0. Discovery & spikes** | 6–8 weeks | (1) Rive character with lip-sync at 60 fps on the low-end tablet; (2) ASR bake-off on the first 50 children's recordings; (3) TTS listening test; (4) nikud font test; (5) two templates driven by JSON; (6) tutor evaluation v0: Haiku 5.5 vs Gemini Flash; (7) `character-sm/v1` contract + `CharacterResolver` prototype with one Rive and one lite character in every slot; (8) learner simulator v0 with planted gaps. **Go/no-go on voice scope.** |
| **1. MVP** | 5–6 months | 10–12 templates; **understanding-focused learning engine** (skill graph, diagnostic walk, misconception tagging and repair, representation switching, BKT + FSRS retention, fresh vs durable mastery, understanding checks, "I'm not sure"); starter pack + 6 domain packs for Bands A–B (Band C partial) with at least 3 representations per core skill; RuleTutor; LLM tutor behind a flag; on-device voice for numbers, colours, shapes and yes/no; **character pack system** (manifest, contract, role slots, resolver, validator, Sandbox; 3–4 original Rive characters; lite-pack import in personal/dev builds); CMS + Studio Preview; parent area with per-skill status, gate, accounts and sync; first-party analytics; compliance documents |
| **2. Family beta (Israel)** | 8–10 weeks | 150–300 families; weekly content drops; ASR threshold tuning by age; learning-parameter calibration; performance hardening; store pre-review |
| **3. Launch (Israel)** | 4 weeks | Kids Category + Families / Expert-approved submissions; subscription live; staged rollout; on-call |
| **4. Expansion** | ongoing | Full Band C; consented conversational tutor; voice explain-back in Band B; child-adapted ASR (fine-tuned Zipformer or Azure Custom Speech); a new original character pack every 1–2 months (6.7) and licensed packs if contracts are signed (6.6); retention-model refit on real data; diaspora markets |

**Kickoff to launch: about 10–12 months.**

**MVP vs later.**
- **In the MVP:**
  - everything playable by tap; human VO; voice for closed answer sets;
  - complete RuleTutor, and LLM hints (on for beta);
  - **learning:** skill graph + diagnostic walk; misconception tags on distractors, traces and expected wrong voice answers, with repair; representation switching with per-child stats; mastery plus retention (fresh vs durable) with interleaved revisit checks; transfer, reverse and error-spotting checks; "I'm not sure"; per-domain placement;
  - **characters:** the full character pack system with original characters; lite-pack import (personal builds only); licence metadata and kill switch (built in, unused until a licence exists);
  - packs + CDN;
  - parent dashboard showing understood / practicing / needs a revisit / gap found;
  - subscription; phones and tablets.
- **Later:** voice explain-back beyond Band C pilots; open conversation; cloud ASR opt-in; child-adapted ASR; licensed character packs; play-together mode; AI progress summaries for parents; classroom mode (a separate regulatory scope); Arabic, which reuses the RTL work.

### 14.3 Budget (estimates)
Assumptions:
- An Israeli senior engineer's fully loaded cost is about $16–20k per month.
- 11 months to launch.
- Curriculum, Design and marketing are excluded.

| Item | USD |
|---|---|
| Engineering (≈5.5 FTE × 11 months) | $0.95–1.25M |
| Rive animation (3–4 original characters to the standard contract, plus scenes) | $80–150k |
| VO studio, talent, SFX/music (≈3,500 lines) | $40–80k |
| Legal and privacy (DPIA, notices, DPAs, privacy officer) | $30–60k |
| Devices, tooling, CI, Rive Voyager seats ($39 per seat per month, verified), font licence | $15–30k |
| Cloud during build and beta | $5–15k |
| **Total to launch** | **≈ $1.1–1.6M** |
| Running cost per 10k monthly active children | ≈ $2.5–6k per month (AI $1.5–4.2k + infrastructure $1–2k) |

---

## 15. Technical risks & mitigations

| Risk | Likelihood / impact | Mitigation |
|---|---|---|
| **Child Hebrew ASR too inaccurate**, especially at ages 3–4 | High / Medium | Voice optional; closed answer sets; confirm step; ≥ 97% accept-precision gate; per-child reliability score; evaluation set from month 1; voice scope set per band from data |
| On-device Hebrew models missing on some devices; SpeechAnalyzer lacks he-IL | Medium / Low | sherpa-onnx with the ivrit.ai model as primary; runtime locale checks |
| Rive 0.x breaking changes, or poor performance on Mali GPUs | Medium / High | Pinned versions; `CharacterView` abstraction; renderer chosen per tier; nightly performance runs; contract tests |
| Hebrew TTS mispronunciation, or wrong gender forms from the LLM | High / Medium | Lexicon vocalisation; validator gender check; approved phrasebook; listening QA |
| Inappropriate LLM output, or an answer leak | Low / High | Structured input; strict schema; validator + moderation; band scope; kill switch; parent log and report; red-team release gate |
| Store rejection over an SDK or a weak gate | Medium / High | No third-party SDKs on the child path; manifest/privacy diff in CI; gate tested on 8-year-olds |
| Regulatory change (Israeli PPA guidance on minors, EU high-risk rules from Dec 2027, US state laws) | Medium / Medium | Minimal-data design; consent ledger; DPIA; counsel retainer; quarterly review |
| OS-forced tablet resizing breaks layouts | Certain / Medium | Stage model with wide/tall variants; goldens in both orientations; minimum-size screen |
| Low-end Android kills the app under memory pressure | Medium / High | Asset budgets; lazy-loaded ASR; resume exactly from an FSM snapshot |
| Engineers become the content bottleneck | Medium / High | CMS + Studio Preview in the MVP; schema-driven forms; content-ops role |
| AI cost overrun, or vendor deprecation | Low / Medium | Caps, caching, phrasebook, alerts; gateway abstraction with two evaluated vendors per service |
| **Unlicensed third-party characters reach a store build.** This breaks Apple guideline **5.2.1** ("Don't use protected third-party material such as trademarks, copyrighted works… without permission"; apps must be submitted by the rights holder or licensee) and Google Play's **Intellectual Property** policy, which names cartoon and movie artwork and indistinguishable fan art (both verified). Consequences: rejection, removal, a developer-account strike, and legal exposure. | Medium (owner intends personal packs) / Critical | `personalUseOnly` flag; store-flavour build and CDN publisher both refuse flagged or unlicensed packs (6.5–6.6); release gate; licence metadata with asset-hash approval, dates, territories and kill switch; legal review before any licensed pack ships |
| Personal packs leak: a family device is shared, or a pack file is passed on | Low / Medium | Packs stay on the device and in the parent account; never on the CDN; import only behind the gate in personal builds; no share/export feature for packs |
| The learning model misdiagnoses: false gaps or misconceptions annoy children with unneeded repair | Medium / Medium | Evidence thresholds requiring at least 2 independent items; probes capped per session; repair framed as play; simulator gates; Curriculum reviews the weekly misconception report |
| Retention checks feel like repetitive tests | Medium / Medium | Different items from the `variantGroup`; checks interleaved inside playful activities; caps per session; transfer formats |

---

## 16. Open decisions

1. **Tutor voice per character:** synthetic-only tutor voices (recommended), or contracted TTS clones of each full character's voice actor. Needs Design and owner input.
2. **TTS vendor:** Chirp 3 HD vs Azure Hila/Avri vs ElevenLabs v4 Turbo, decided by the listening test.
3. **ASR engine per platform:** ivrit.ai Zipformer vs the native recognisers, decided by the bake-off. Also confirm that sherpa-onnx hotwords work with that model.
4. **Voice scope per band at launch**, in particular whether Band A gets voice at all. Decided by the evaluation metrics.
5. **LLM vendor and processing region**, once terms for minors, retention and EU residency are confirmed.
6. **Kids Category age band** (5 and under, or 6–8) for a 3–8 audience, and whether to ship one app or two.
7. **Display font and its licence** (Design), which must pass the nikud test.
8. **Direction of CS program sequences** (Curriculum and Design).
9. **Whether an account is required for sync at launch**, or local-only is the default.
10. **Launch markets:** Israel only, or Israel plus the diaspora. The latter turns COPPA and GDPR from preparation into active obligations.
11. **Phone orientation** (Design). Tablets must support both.
12. **Business model details** (trial, family plan, free content). These affect pack gating only.
13. **Licensed characters:** whether to pursue a licence from the rights holder for any franchise characters before a commercial launch, or launch with original characters only. Until a licence is signed, such characters exist only as owner-supplied personal lite packs, excluded from store builds. Needs the owner and counsel; it affects budget, and possibly the tutor (licensors often bar synthetic voices or AI dialogue).
14. **Personal-pack capability in production:** keep lite-pack import limited to dev/personal builds (recommended), or offer it to all parents as a "make your own character" feature. The latter needs content moderation and an IP policy for user uploads.
15. **Retention model:** FSRS-style (default) vs half-life regression, once enough delayed-check data exists to compare them on our learners.
16. **Explain-back in Band B:** pilot or not, depending on ASR results for 5–6-year-olds.

---

## 17. Sources

Pages opened during this research (October 2026).

**Frameworks & runtimes**
- [Flutter — Supported deployment platforms](https://docs.flutter.dev/reference/supported-platforms)
- [Flutter — Release notes](https://docs.flutter.dev/release/release-notes)
- [Flutter — Impeller rendering engine](https://docs.flutter.dev/perf/impeller)
- [CMARIX — Latest Flutter version (3.44)](https://www.cmarix.com/blog/latest-flutter-version/)
- [pub.dev — rive](https://pub.dev/packages/rive)
- [Rive — rive_native (Flutter)](https://rive.app/docs/runtimes/flutter/rive-native)
- [Rive — Feature support](https://rive.app/docs/feature-support)
- [Rive — Data binding (runtimes)](https://rive.app/docs/runtimes/data-binding)
- [Rive — Audio events](https://rive.app/docs/editor/events/audio-events)
- [Rive — Text overview](https://rive.app/docs/editor/text/text-overview)
- [Rive — Text (runtimes)](https://rive.app/docs/runtimes/text)
- [Rive — Pricing](https://rive.app/docs/account-admin/pricing.md)
- [Rive — Inputs (deprecated in favour of Data Binding)](https://rive.app/docs/runtimes/inputs)
- [Rive — C++ runtime data binding (property types and enumeration)](https://rive.app/docs/runtimes/cpp/data-binding.md)
- [DEV — Duolingo-style AI mascot animations with Rive](https://dev.to/uianimation/building-duolingo-style-ai-mascot-animations-with-rive-2446)
- [pub.dev — Flame](https://pub.dev/documentation/flame/latest/)
- [pub.dev — flutter_soloud](https://pub.dev/packages/flutter_soloud)
- [Flutter cookbook — flutter_soloud](https://docs.flutter.dev/cookbook/audio/soloud)
- [pub.dev — lottie](https://pub.dev/packages/lottie)
- [pub.dev — drift](https://pub.dev/packages/drift)
- [FlutterGems — sherpa_onnx](https://fluttergems.dev/packages/sherpa_onnx/)
- [Expo — SDK 56 changelog](https://expo.dev/changelog/sdk-56.md)
- [Unity — Announcing full RTL language support](https://discussions.unity.com/t/announcing-full-rtl-language-support/1544214)
- [Very Good Ventures — Alchemist golden tests](https://verygood.ventures/blog/alchemist-golden-tests-tutorial.md)

**Hebrew text, fonts & speech**
- [Open Siddur — Hebrew fonts by diacritic support](https://opensiddur.org/help/fonts/)
- [Google Fonts — Noto Sans Hebrew](https://fonts.google.com/specimen/Noto+Sans+Hebrew/about)
- [arXiv — Phonikud: Hebrew G2P](https://arxiv.org/abs/2506.12311)
- [Hugging Face — ivrit.ai](https://huggingface.co/ivrit-ai)
- [Hugging Face — ivrit-ai/whisper-large-v3-turbo-ct2](https://huggingface.co/ivrit-ai/whisper-large-v3-turbo-ct2)
- [Hugging Face — ivrit-ai/zipformer2-66m-streaming-he](https://huggingface.co/ivrit-ai/zipformer2-66m-streaming-he)
- [Apple — SpeechTranscriber](https://developer.apple.com/documentation/speech/speechtranscriber.md)
- [Blake Crosley — SpeechAnalyzer vs SFSpeechRecognizer](https://blakecrosley.com/blog/speech-framework-vs-sfspeechrecognizer)
- [Apple Forums — SpeechAnalyzer asset not found for some languages](https://developer.apple.com/forums/thread/797835)
- [Apple Forums — On-device recognition requirements](https://developer.apple.com/forums/thread/731230)
- [Apple Forums — SpeechAnalyzer sample app](https://developer.apple.com/forums/thread/790108?page=2)
- [Apple — iOS feature availability](https://www.apple.com/ios/feature-availability/)
- [MBS — Speech recognition supported locales](https://mbsplugins.eu/SpeechRecognitionSupportedLocales.shtml)
- [VoiceScriber — Offline Hebrew transcription](https://voicescriber.com/offline-transcription/hebrew)
- [Android — SpeechRecognizer reference](https://developer.android.com/reference/android/speech/SpeechRecognizer?hl=es)
- [Microsoft Learn — Azure Speech language support](https://learn.microsoft.com/en-us/azure/ai-services/speech-service/language-support?tabs=tts)
- [Microsoft Learn — Azure viseme events](https://learn.microsoft.com/en-us/azure/ai-services/speech-service/how-to-speech-synthesis-viseme)
- [Microsoft Learn — Azure Speech regions](https://learn.microsoft.com/en-us/azure/ai-services/speech-service/regions)
- [Azure — Speech pricing](https://azure.microsoft.com/pricing/details/cognitive-services/speech-services)
- [Developers Digest — Azure speech pricing](https://www.developersdigest.tech/models/speech/azure)
- [json2video — he-IL-HilaNeural](https://json2video.com/ai-voices/azure/voices/he-il-hilaneural)
- [json2video — he-IL-AvriNeural](https://json2video.com/ai-voices/azure/voices/he-il-avrineural/)
- [Google Cloud — Chirp 3 HD voices](https://docs.cloud.google.com/text-to-speech/docs/chirp3-hd)
- [Google Cloud — Text-to-Speech pricing](https://cloud.google.com/text-to-speech/pricing)
- [Google Cloud — Chirp 3 transcription](https://docs.cloud.google.com/speech-to-text/docs/models/chirp-3)
- [Google Cloud — Speech-to-Text pricing](https://cloud.google.com/speech-to-text/pricing)
- [ElevenLabs — Supported languages](https://elevenlabs.io/docs/help-center/other/what-languages-do-you-support)
- [ElevenLabs — Models](https://elevenlabs.io/docs/overview/models)
- [arXiv — Arabic Little STT (child speech)](https://arxiv.org/abs/2510.23319v1)
- [AAAI/AIES — Kid-Whisper](https://ojs.aaai.org/index.php/AIES/article/view/31618)
- [TalkBank — CHILDES Hebrew BSF](https://talkbank.org/childes/access/Other/Hebrew/BSF.html)

**AI models**
- [Anthropic — Models overview](https://platform.claude.com/docs/en/models/overview)
- [Anthropic — Pricing](https://platform.claude.com/docs/en/about-claude/pricing)
- [Anthropic — Structured outputs](https://platform.claude.com/docs/en/build-with-claude/structured-outputs)
- [Anthropic — Guidelines for organizations serving minors](https://support.claude.com/en/articles/9307344-responsible-use-of-anthropic-s-models-guidelines-for-organizations-serving-minors)
- [Anthropic — Child safety guidance for developers](https://support.claude.com/en/articles/15591275-child-safety-guidance-for-developers)
- [Google — Gemini API pricing](https://ai.google.dev/gemini-api/docs/pricing)
- [Morph — Gemini API pricing 2026](https://www.morphllm.com/gemini-api-pricing)

**Stores, platforms & services**
- [Apple — App Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)
- [Apple — Kids apps](https://developer.apple.com/app-store/kids-apps/)
- [Google Play — Intellectual Property policy](https://support.google.com/googleplay/android-developer/answer/9888072?hl=en)
- [Apple — TN3192: UIRequiresFullScreen migration](https://developer.apple.com/tutorials/data/documentation/technotes/tn3192-migrating-your-app-from-the-deprecated-uirequiresfullscreen-key.md)
- [Apple Forums — iOS 27 SDK UIRequiresFullScreen](https://developer.apple.com/forums/thread/820475)
- [AppsOnAir — WWDC 2026 child-safety updates (third-party; unverified claims)](https://www.appsonair.com/blogs/wwdc-2026-apples-biggest-child-safety-parental-control-updates-explained)
- [Google Play — Families policies](https://support.google.com/googleplay/android-developer/answer/9893335?hl=en)
- [Google Play — Expert (Teacher) approved](https://play.google.com/intl/en-GB/console/about/programs/teacherapproved)
- [Google Play — AI-generated content policy](https://support.google.com/googleplay/android-developer/answer/14094294)
- [Android — Target API level requirements](https://developer.android.com/google/play/requirements/target-sdk)
- [Android Developers Blog — Orientation and resizability changes in Android 16](https://android-developers.googleblog.com/2025/01/orientation-and-resizability-changes-in-android-16.html)
- [Supabase — Regions](https://supabase.com/docs/guides/platform/regions)
- [RevenueCat — Apple App Privacy](https://www.revenuecat.com/docs/platform-resources/apple-platform-resources/apple-app-privacy)
- [Sentry — Flutter sensitive data](https://docs.sentry.io/platforms/dart/guides/flutter//data-management/sensitive-data/)

**Learning science**
- [TheoremPath — FSRS spaced-repetition scheduling](https://theorempath.com/topics/fsrs-spaced-repetition-scheduling)
- [Duolingo — How we learn how you learn (half-life regression)](https://blog.duolingo.com/how-we-learn-how-you-learn)
- [ACL Anthology — Settles & Meeder 2016, A Trainable Spaced Repetition Model](https://aclanthology.org/P16-1174/)

**Law & regulation**
- [Davis Polk — COPPA enforcement as new obligations take effect](https://www.davispolk.com/insights/client-update/ftc-prioritizes-coppa-enforcement-new-compliance-obligations-take-effect)
- [Hunton — Final COPPA rule amendments](https://www.hunton.com/privacy-and-cybersecurity-law-blog/ftc-publishes-final-coppa-rule-amendments)
- [Wiley — Amended COPPA rule](https://www.wiley.law/alert-FTC-Adopts-Amended-Childrens-Online-Protection-Act-Rule)
- [Bird & Bird — Children in the digital world: EU](https://childreninthedigitalworld.twobirds.com/home/eu)
- [Reed Smith — Protecting children online in 2026](https://www.reedsmith.com/our-insights/blogs/technology-law-dispatch/102mela/protecting-children-online-what-to-expect-in-2026/)
- [Mondaq — EU Digital Omnibus on AI enters into force](https://www.mondaq.com/eu-digital-omnibus-on-ai-enters-into-force/1825722)
- [SayMine — Israel Amendment 13](https://advisor.saymine.com/blog-1/israel-enforces-major-privacy-reform-under-amendment-13)
- [Pearl Cohen — Amendment to Israeli privacy law](https://www.pearlcohen.com/major-amendment-to-israeli-privacy-law-set-to-take-effect/)
- [BigID — Israel Amendment 13 for businesses](https://bigid.com/blog/what-israel-amendment-13-means-for-businesses-in-2025/)
- [Mondaq — Israel privacy review 2025, outlook 2026](https://www.mondaq.com/privacy-protection/1733296/annual-privacy-review-2025-outlook-for-2026)
- [EdLaw — Israel Protection of Privacy Law](https://edlaw.eduverse.com/docs/jurisdiction/nat/il/protection-of-privacy-law)
- [Winston & Strawn — Israeli parental consent for children's data](https://www.winston.com/en/blogs-and-podcasts/privacy-law-corner/israeli-site-needs-parental-consent-under-local-law-to-collect-information)
