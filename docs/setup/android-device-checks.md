# Build and install the dev app, then run the Phase G checks (Android)

Everything runs in PowerShell from `D:\Children-Learning-App`. Do `docs/setup/supabase-deploy.md`
steps 1 to 7 first (including 6b, the email code). The dev app shows one plain English page with
four sections (sign in, enrol, pair, signed calls) and an Output list. It carries only the project
URL and the publishable key, never a secret key.

## 1. Give the app the project URL and the publishable key

1. Supabase dashboard > Settings > **API Keys**. Copy the **publishable** key (starts with
   `sb_publishable_`). Not the secret key: the app refuses to start with one.
2. Make your local, Git-ignored settings file and open it:

   ```powershell
   Copy-Item app\config\dev.example.json app\config\dev.local.json
   notepad app\config\dev.local.json
   ```
3. Replace the whole `"paste the sb_publishable_... key ..."` text with the key (keep the quotes),
   save, close Notepad.

## 2. Check the phone is seen

1. Samsung: Settings > Developer options > USB debugging on. Plug it in and accept "Allow USB
   debugging" on the phone.
2. ```powershell
   $env:Path += ";$env:LOCALAPPDATA\Android\Sdk\platform-tools"
   adb devices
   flutter devices
   ```
   Expect a line ending in `device` (not `unauthorized`), and the SM S938B in the Flutter list.

## 3. Build and install

```powershell
cd app
flutter pub get
flutter run --flavor dev --dart-define-from-file=config/dev.local.json -d <the phone's id from flutter devices>
```

The first build takes several minutes. The app is called "Nitznutz Dev" on the phone, and its page
is titled "Nitznutz dev harness". Leave PowerShell running: it shows the app's log. To stop, press `q`. (To keep the app on
the phone without the cable, run once, then it stays installed.)

If it opens on a plain screen saying the build settings are missing, the key in `dev.local.json` was
not replaced properly.

## 4. Checks on the parent phone (the Samsung)

Each action adds one line at the top of **Output**. Nothing secret is ever printed there.

| # | Do this | You should see |
|---|---|---|
| 1 | Section 1: type your email, tap **Send code**. | `send code: requested` |
| 2 | Type the 6-digit code from the email, tap **Verify**. | `sign in: signed in` |
| 3 | Section 2: tap **Enrol as parent** (within 10 minutes of step 2). | `enrol: device <id> role parent level strongbox` or `tee`; "Enrolled device" at the top shows the id |
| 4 | Section 4: tap **Signed ping**. | `ping: {ok: true, role: parent, ...}` |
| 5 | Tap **App config**. | `app config: {server_time: ..., tutor_enabled: false, voice_enabled: false}` |
| 6 | Tap **List devices (parent)**. | `devices: {devices: [{id: <id>, role: parent, ... this_device: true}]}` |

## 5. The child device

A child device needs its own hardware-backed key. Two ways; Claude will ask which one you want.

- **A second Android phone or tablet** (Android 8 or newer, with a hardware keystore): run step 3
  for it too (`-d <its id>`), then use the child steps below.
- **The Android emulator** cannot pass Key Attestation. It enrols only through the server's dev
  allowlist, which must never be on in your cloud project. Options are the local Supabase stack
  (Docker Desktop) or a short, deliberate test window. Claude gives the exact steps if you choose it.

| # | Do this | You should see |
|---|---|---|
| 7 | Parent phone: **Create pairing code (parent)**. | `pairing code: created (shown below)` and `Code: 123456` under the button (valid 9 minutes) |
| 8 | Child device: section 3, type the code, tap **Pair as child**. | `pair: device <id> role child level ...` |
| 9 | Child: **Signed ping**. | `ping: {ok: true, role: child, ...}` |
| 10 | Child: **List devices (parent)**. | `devices: refused: forbidden (403)` |
| 11 | Parent: **List devices (parent)**, select and copy the child's `id`. Paste it into "Device id to revoke", tap **Revoke device (parent)**. | `revoke: {revoked: true}` |
| 12 | Child: **Signed ping** again. | `ping: refused: unauthorized (401)` |
| 13 | Reinstall: on the parent phone tap **Forget this phone (local only)**, then uninstall the app (`adb uninstall app.nitznutz.nitznutz.dev`) and run step 3 again. Tap **Signed ping**. | `ping: not done: this phone is not enrolled` |
| 14 | Sign in and enrol again (steps 1 to 3), then **List devices**: two parent entries (the old install and this one). Revoke the old one as in step 11. | `revoke: {revoked: true}` |

## If something goes wrong

- `refused: <code> (<http status>)` is all the server tells the app. Codes: `unauthorized` (token,
  signature, device or family), `forbidden` (role, or the attestation was refused), `clock_skew`
  (phone clock more than 60 s off, the app retries once by itself), `rate_limited`, `device_limit`
  (six devices), `unavailable` (e.g. the `android_allowed_apps` row is missing, deploy step 7).
- `refused: bad_response (404)`: the function is not deployed (deploy step 5).
- Sign-in fails with `auth_failed`: the email template has no `{{ .Token }}` (step 6b) or that user
  does not exist (step 6).
- For the precise reason: Dashboard > Edge Functions > the function > Logs. It holds a reason label
  such as `attestation_app_not_allowed`, never keys or tokens.
