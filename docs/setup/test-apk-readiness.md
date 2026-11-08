# Test APK for other families: readiness (assessment, 2026-11-08)

Question from the owner: after the text sweep, B-29 and the voicing, build the app, install it on his phone, and make an APK he can share with other test families, who create their own parent accounts on his Supabase project `ungkvkabqxssggttajfs` (approved by him).

This is a read-only assessment from the code, CI and docs of `content-release` (commit ab5d4cd4) and the docs in `D:\Children-Learning-App`. Nothing was built, committed, pushed or changed on the server. The live project's settings (Auth page, `app.config` rows, spend consoles) were not looked at; where a point depends on them it says "check live".

## Blockers first

| # | Blocker | Why | Who | Size |
|---|---|---|---|---|
| 1 | **A new person cannot sign up.** | The app asks for the code with `create_user: false` (`app/lib/auth/auth_client.dart` line 39, doc comment "Never creates a new user"), and the live project has "Allow new users to sign up" **off** (`docs/setup/supabase-deploy.md` step 6b). A stranger's email gets an error, not a code. | Decision for the owner, then app-developer (one line plus tests) and the owner (dashboard switch). See section 2. | Small, but needs a decision |
| 2 | **No release signing key exists, and the build does not use one.** | `buildTypes.release` still signs with the debug key (`app/android/app/build.gradle.kts` lines 46 to 51, TODO). The owner's keystore steps are written (`docs/setup/ci-m9.md` section 6) but not done: `nitznutz.releaseSigning` is not in `~/.gradle/gradle.properties`. The Gradle side (read the signing file, fail the prod release build if it is missing) is not written yet. | Owner makes the key (steps in section 1); infrastructure-engineer wires Gradle. | About 30 minutes owner, small change |
| 3 | **The server refuses every enrolment from the prod app until a row is added.** | `android_allowed_apps` on the live project lists only the dev package with the debug-key fingerprint (`supabase-deploy.md` step 7). The server fails closed (`supabase/functions/_shared/enrol.ts` `androidPolicy`). It must also list `app.nitznutz.nitznutz` with the fingerprint of the key that signs the APK. | Infrastructure-engineer, after the owner reports the fingerprint ("keystore done"). A live-database change: needs the orchestrator's brief. | Small |
| 4 | **No prod config file and no prod Firebase file in the release worktree.** | Only `app/config/dev.example.json` exists. The build needs `app/config/prod.local.json` (git-ignored; URL, publishable key, `"FLAVOR": "prod"`). `app/android/app/src/prod/google-services.json` exists in `D:\Children-Learning-App` (git-ignored) but not in `D:\nitznutz-release`; without it the app builds but push is not offered. | Owner pastes the publishable key (public by design); the file is copied by the infrastructure-engineer. | Small |
| 5 | **Not verified: key attestation on a phone other than the owner's Samsung, and on the prod package.** | The path worked from the dev package on the Samsung. The code has "Not yet checked: Google's revocation list of attestation keys; to add before any build leaves the family" (`docs/PLAN.md` line 720). Phones with an unlocked bootloader, a custom ROM or no hardware keystore are refused on purpose (`android_require_verified_boot`). | Do one real enrolment of the signed prod APK on a second ordinary phone before handing it out. The revocation-list check is a security-engineer decision (see section 2). | One test |
| 6 | **Owner decision on spend before more families use the tutor** (section 3). | The tutor is capped per family but the sum over families is only bounded by the two vendor limits. | Owner | Decision |

Nothing else blocks it from the code. The family, guardian and first parent device are created automatically on a user's first enrolment (`device-enroll` "creates the family and guardian row on a user's first device", `docs/PLAN.md` line 720); no step by the owner is needed per family once blockers 1 to 3 are done.

## 1. Flavour, build type and the signing key

**For testers: `prod` flavour, `release` build type, signed with the owner's own release key.**

- `prod` has application id `app.nitznutz.nitznutz` and the name "Nitznutz". `dev` has the suffix `.dev`, the name "Nitznutz Dev" and the only dev-only tools (the harness page, the dev lessons page, the dev-allowlist enrolment). The dev flavour should not go to other families: the dev page is not for children's parents, and a `dev` build would be on the allowlist entry that exists for the owner's lab.
- The app refuses to enrol with a dev secret in `prod` (`enrolment_service.dart` lines 48 and 81). The server's `ALLOW_DEV_ENROLMENT` is off on the cloud project and must stay off. So a tester's phone enrols only through Android Key Attestation (`attestation_kind: key_attestation`). An emulator cannot do this, so testers need a real phone (Android 8 or newer, `minSdk = 26`, a hardware keystore, a locked bootloader).
- Signing today: none of its own. The release build type uses the debug key. A debug-signed APK would work for a very first, trusted round, but the debug key is the public default (password `android`), the server would have to trust that fingerprint, and an app signed with the debug key can never be updated by an app signed with the real key (Android refuses; the tester must uninstall, which deletes the child's local data and the enrolment). So make the real key **before** the first APK leaves the house.
- The release keystore does not exist yet (`~/.gradle/gradle.properties` has no `nitznutz.releaseSigning`). It is made by the owner. The nine steps (password in 1Password, `keytool`, backup twice, `release-signing.properties` with `icacls`, the Gradle property) are in `docs/setup/ci-m9.md` section 6 and are correct as written. In short, the owner runs, in PowerShell:

```powershell
$kt = "C:\Program Files\Android\Android Studio1\jbr\bin\keytool.exe"
if (-not (Test-Path $kt)) { $kt = "C:\Program Files\Android\Android Studio\jbr\bin\keytool.exe" }
$ks = "$env:USERPROFILE\nitznutz-secrets\nitznutz-release.jks"
Test-Path $ks     # must say False
```

then `keytool -genkeypair ...` with the password typed at its prompt, `keytool -list -v ... | Select-String "SHA256:"`, the 1Password backup of the `.jks` and a USB copy, the properties file, and the one `Add-Content` line for Gradle. He then tells the orchestrator "keystore done" with the `SHA256:` line (public). Never the password or the file.
- After that the infrastructure-engineer: writes the `release` signing config in `build.gradle.kts` (reads the file named by `nitznutz.releaseSigning`; a prod release build without it fails with a clear message), builds, checks the certificate with `apksigner verify --print-certs`, and adds the `app.nitznutz.nitznutz` entry to `android_allowed_apps` (keeping the dev entry). The `dev` flavour stays on the debug key.
- If the key is lost, every installed tester app is orphaned. Back it up as the doc says.

## 2. Can a new family go from nothing to a child's profile with no manual server step?

Walk-through of the real path (parent area: `app/lib/parent/entry_flow.dart`, `setup_flow.dart`, `backends.dart`):

| Step | Works for a stranger? | Detail |
|---|---|---|
| Install the APK | Yes | Sideload (section 5). |
| Enter email, get a 6-digit code | **No today** (blocker 1) | `create_user: false` plus sign-ups off. Also, for a *new* user Supabase sends the "Confirm sign up" email template, not the "Magic Link" one. The owner set `{{ .Token }}` only in the Magic Link template (step 6b). The Confirm signup template must carry `{{ .Token }}` too, or a new user gets only a link the app cannot use. |
| Verify email | Yes once the above is fixed | Typing the emailed code (`/auth/v1/verify`, `type: email`) is the verification; there is no separate confirmation link. Check live that "Confirm email" does not add a second step that the app does not know. |
| Set the PIN | Yes | Local, Argon2id; no server step. |
| Enrol the device | **Not yet** (blocker 3) | Within 10 minutes of the code (`FRESH_SIGN_IN_SECONDS = 600`, measured on the `otp` sign-in time in the token's `amr` claim). Key Attestation, package and certificate fingerprint must be in `android_allowed_apps`; the verified-boot check is on. The family and guardian row are created automatically. |
| Add children | Yes | `child-put`; no per-family server setup. At most 6 active devices per family (database trigger). |
| Push to the parent's phone | Only with the prod Firebase file | See blocker 4. The server needs the `FCM_SERVICE_ACCOUNT` secret (the dev setup already uses it; check live that it is for the Firebase project that holds the prod app). Without it, alerts still appear in the app, only the push is missing. |

**Decision for the owner on blocker 1.** There are two honest options.

- **A. Invite-only (no code change, nothing to build).** The owner adds each tester's email by hand: Dashboard > Authentication > Users > Add user > "Auto Confirm User" ticked (as for himself, step 6). The tester then signs in with the code. Safest while there are a few families; it is one minute per family, but it is a manual server step per family, which is what the owner wanted to avoid.
- **B. Open sign-up (what the owner asked for).** (i) Dashboard > Authentication > Sign In / Providers: turn "Allow new users to sign up" **on**, Email on. (ii) The Confirm sign up email template gets the same `{{ .Token }}` line as Magic Link. (iii) App change by the **app-developer**: send `create_user: true` (or leave the field out) in `sendEmailCode`, change the doc comment, and update the tests that pin the request body. (iv) The security-engineer reviews it: anyone with the APK, or who reads the project URL and publishable key out of it (they are public by design), can create accounts and get emailed codes. What they cannot do without a genuine, allow-listed app on a genuine phone is enrol a device, call any other function, or reach the tutor, because every function needs an enrolled device (security rule 3). The remaining exposure is email sending through the owner's SMTP (below) and fake-user rows. Settings: keep the per-hour email rate limit low, consider CAPTCHA only if abuse appears.
- **Email sending limits (both options).** Supabase's built-in sender is for trying only. The doc set up a Gmail SMTP app password (step 6a). Gmail allows only a few hundred messages a day, and Supabase has its own "emails per hour" limit on the Rate Limits page. Fine for a handful of families; check the numbers live. A sender on the owner's own domain (Resend or Brevo) is cleaner if the test grows.
- **The revocation list.** "Google's revocation list of attestation keys" is stated as to be added "before any build leaves the family". The security-engineer should say whether a test with a few known families may go first (the owner decides; a revoked key would only matter for a stolen, leaked attestation key).
- The server-side Auth settings (sign-ups, templates, SMTP, rate limits) live only in the Supabase dashboard, not in the repository (`supabase/config.toml` is the local stack and has `enable_signup = false`). This assessment could not see what is set live.

## 3. Costs and caps with more families

What the code enforces (all in `supabase/functions/_shared/tutor_core.ts`, config rows in `app.config`, no deploy needed to change them):

| Control | Default if the row is missing | Where | Effect |
|---|---|---|---|
| `tutor_enabled` | off | global kill switch | off = RuleTutor only, authored lines, no cost |
| `live_voice_enabled` | off | global kill switch | off = no ElevenLabs |
| `tutor_cost_cap_micro` | 500000 (0.50 USD) | **per family, per UTC day** (millionths of a dollar) | over the cap = RuleTutor (`cost_cap`) |
| `tutor_session_cap` | 20 turns | per session | |
| `tutor_day_cap` | 60 turns | per child, per day | |
| `tutor_prefetch_cap` | 40 | per child | |
| `tutor_price_micro` | placeholders (1 / 5 USD per million tokens, 0.30 per 1,000 voice characters) | the cap's arithmetic | **the cap is only as true as these prices** (they must match what Anthropic and ElevenLabs charge for the chosen models, `supabase-deploy.md` step 8.5) |
| 6 active devices | fixed | database trigger | |

Also: the tutor is for the maths pack only; the language courses never reach the model. The first turn of a day is allowed before the cap bites, so the real daily maximum is the cap plus one turn. A parent also has an "AI helper in lessons" switch per family (default off for a new family; check in `parent_rules.dart`).

There is **no global daily budget across families and no limit on the number of families** in the code. The real ceilings are the vendor consoles: the Anthropic workspace limit (the plan says 5 USD a month, `PROGRESS.md` and `supabase-deploy.md` step 8.1) and the credit limit on the ElevenLabs key (set when the key was made, step 8.2). When either runs out the API refuses and the app falls back to RuleTutor (`model_failed` / `voice_failed`), so the children are not harmed. Worst case on paper: N families times 0.50 USD a day, up to the vendor limit; the limits are the real guard.

Checks and decisions for the owner:

1. **Should the tutor be on for testers at all?** The safest first round: `tutor_enabled` and `live_voice_enabled` **off** (nothing can be spent, and the tutor's per-family "AI helper" stays off). Test families then get the maths, languages, rewards and progress; the voiced pre-warmed lines in the packs still work (they are in the pack). Turn the tutor on for one family at a time later.
2. If it is on: lower `tutor_cost_cap_micro` to something small for testers (for example 100000 = 0.10 USD a family a day), and confirm the prices row matches the real prices. The infrastructure-engineer sets rows on a brief, and the live values are to be read with `select key, value from app.config` in the SQL Editor (read-only, and no key shows there).
3. Confirm the Anthropic workspace limit (screenshot P2 is still on his list) and the ElevenLabs key's credit limit. Decide how much a test month may cost at most. The owner's rule stands: Claude never uses the ElevenLabs key.
4. Supabase plan: `docs/PLAN.md` line 899 notes that a free project pauses and `pg_cron` jobs (nightly retention and the ElevenLabs history clean-up) stop while paused. A few families keep it awake; check the plan and the monthly limits (database size, function calls, emails) on the dashboard before inviting.
5. The kill switch and the tutor off state can be flipped live with one row; document who does it. Re-check them live before the APK goes out (release gate, M9 section 6).

## 4. What to tell the test families (draft, plain English; translate or use as is)

> **Nitznutz test: what you should know**
>
> Nitznutz is a Hebrew learning app for children aged 3 to 8, made by one parent for his own children. You are testing an early version. It may have mistakes, and I may ask what you think.
>
> **What is stored.** On a server in Frankfurt (Germany) that I, the owner, run: your email address (to sign you in); the first name or nickname you give each child, the child's age group (and school stage if you set it), the character they chose; their progress (which activities and skills were done, right or wrong, never the child's voice); the settings you choose; the alerts the app shows you; and the device that is registered as yours. On the phone: the same, plus the packs and a PIN you choose (kept as a hash, I cannot see it).
>
> **What is not stored.** No recordings of your child, ever. The microphone opens only when your child taps it and only if you turned voice on; the audio is not kept and not sent. No ads, no purchases, no timers. No surname, address, school name or photos.
>
> **AI helper and voice (if I switch it on for your family).** When your child makes a mistake, the helper can write a short hint on my server using an AI service (Anthropic). It never sees the child's name (it sees placeholders) or anything personal. Spoken hints are made by a voice service (ElevenLabs), and for that service the child's first name, as you spelled it for the app, may be inside the sentence to be spoken. Nothing else about the child goes to them. The helper says it is a computer when asked. You can switch it off in the parent area.
>
> **Who holds the data.** I am the data holder: [owner's name and contact email]. I use it only to run and improve the app for this test. I do not sell it or share it, other than the two services above. Delete a child in the parent area and their profile and progress are removed from the server; to delete everything, including your account, write to me and I will do it within [7] days.
>
> **Installing.** The file is not from the Play Store. Open it on your Android phone and allow "install unknown apps" for the app you opened it from (your browser, Files or WhatsApp). You can turn that permission off afterwards. Use a normal, up-to-date phone (Android 8 or newer, not rooted, bootloader locked). On first start you enter your email, type the 6-digit code you receive, choose a PIN, and add your child.
>
> **Something wrong?** Write to me at [contact]. Please do not send screenshots of your child's profile; tell me what happened and on which screen.

Notes for the owner: the privacy rules in `docs/PLAN.md` line 1091 onward say Israel's Amendment 13 and, for foreign families, GDPR/COPPA may apply once other people's children are involved; this note is a plain explanation, not legal advice, and `docs/PLAN.md` says counsel should look at it before a public release. Whether the tester note needs a consent tick-box in the app (a consent log is listed in PLAN.md) is a decision for him and the security-engineer. Do not hand the APK to families outside Israel or the EU without that look. The repository is public (P8); the tester note must not link to anything with children's data.

## 5. Install on the owner's phone, and make the shareable APK

**Does a prod install sit beside the dev app?** Yes. The ids differ (`app.nitznutz.nitznutz` against `app.nitznutz.nitznutz.dev`), the names differ ("Nitznutz" and "Nitznutz Dev"), and each keeps its own local data, packs, PIN and device key. The existing dev app is not touched. Points to know:

- The first install of prod on the Samsung is a fresh app: set up again, enrol again.
- If the owner signs in with the **same email**, the prod install joins his existing family as another parent device (up to 6), and the children sync from the server. If he wants a clean test family, use a second address he controls (a Gmail `+` alias such as `name+tester@gmail.com` also receives mail); under option A that user must be added by hand.
- The Samsung's prod build is only enrollable once blocker 3 is done (cert row).
- Never install a debug-signed `app.nitznutz.nitznutz` and later try to update it with the release-signed one. Android refuses the update, and uninstalling first deletes the local data and the enrolment. Make the keystore first.
- Do not use `-r` with a different signing key; use `adb install -r` only for the same key. `adb` is `%LOCALAPPDATA%\Android\Sdk\platform-tools\adb.exe`.

**Build (for the infrastructure-engineer to run, after the keystore, the Gradle change and the prod config file are in place; from `D:\nitznutz-release\app`):**

```powershell
flutter pub get
flutter build apk --release --flavor prod --target-platform android-arm64 --dart-define-from-file=config/prod.local.json
apksigner verify --print-certs build\app\outputs\flutter-apk\app-prod-release.apk
```

`config/prod.local.json` is the same shape as `dev.example.json` with `"FLAVOR": "prod"`. Optionally add `--dart-define=APP_VERSION=...` and bump `version:` in `pubspec.yaml` (now `0.5.0+5`) so the app and the server logs agree on the version. The result must be installed with `adb install` (same key) and checked: enrol, add a child, one activity, push if the Firebase file was in place.

**Size.** The Oct 28 all-ABI dev release APK was 144 MB (`app-dev-release.apk`); the debug build was 253 MB, which must not be shared. The assets are 13 MB (packs 12 MB). An arm64-only release should be clearly smaller than 144 MB; the real number is known only after the build, and the infrastructure-engineer reports it. Nearly all modern Android phones are arm64; an old 32-bit phone would not install it, and the tester note says "Android 8 or newer, 64-bit". Under about 100 MB it can go by a link; a larger one is better as a file-share link than as a WhatsApp attachment (WhatsApp's file limit is 2 GB, but some mail services stop at 25 MB, so use a link there).

**Sharing.**
- Give testers a download link to the file, not an attachment in a chat that later is hard to recall. A private link on his drive, with the file's SHA-256 beside it (`Get-FileHash <apk> -Algorithm SHA256`) so a tester can check it; nothing in the repository (it is public and the APK would be a binary of the family's build; no secrets are in it, the URL and publishable key are public by design, but keep the repository clean).
- The tester: opens the link on the phone, downloads, taps the file, and Android asks to allow "install unknown apps" for that app (browser or Files): Settings > Apps > the app > Install unknown apps. After installing, turn it off again. Samsung phones show a Google Play Protect scan prompt ("Scan app"): the app is unknown to Play Protect; it is safe to tap Scan or "Install anyway"; the tester note should say so.
- Updates are by sending a new APK signed with the same key and a higher build number (`+5` in `pubspec.yaml` goes up). Android installs it over the old one and keeps the data.
- Before each share: the six CI jobs are green on the commit the APK was built from, `gitleaks` is clean, the server's `android_allowed_apps` row has the fingerprint of this APK, and the weekly backup workflow has run.

## Suggested order of work

1. Owner: decides option A or B (section 2), the tutor on/off and the caps (section 3), and makes the release keystore (section 1). Owner also confirms the Anthropic and ElevenLabs limits.
2. Infrastructure-engineer: Gradle release signing, the `android_allowed_apps` row (brief needed), the prod config file and the Firebase file in the release worktree.
3. App-developer (only for option B): `create_user` change and tests. Security-engineer: reviews that and the revocation-list question.
4. Owner: dashboard changes for option B (sign-ups on, Confirm sign up template with the code), re-check the live `app.config` rows.
5. After the text sweep, B-29 and the voicing are in: build, install on the Samsung (side by side with dev), run the device checks on prod, test enrolment on one other phone, then share.
6. Orchestrator: QA-engineer run for the release, security review, then the owner's go.
