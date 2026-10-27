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

## 6. M2 checks: the butterflies lesson and damaged packs

Use the same dev build (section 3). The lesson needs a finished setup (parent enrolled, PIN, one child), as in M1.

**A. Play the lesson (about 4 minutes).** Pick the child, tap the counting hills. Play all five steps by touch:
the red flower; three butterflies (touch each once, then the answer); four scattered; five that stay and glow;
give four of seven (drag, or touch a butterfly and then the flower, then the tick). Try one wrong answer, the
lamp, and the eye ("show me"): none of them should ever show a cross or a harsh sound. At the end a card praises
the counting and a gold button goes home. Tell me anything that is hard to touch, too small, or confusing.

**B. Show that a damaged pack is refused.** On the PC (PowerShell, from `D:\Children-Learning-App\app`):

```powershell
dart run tool/pack_builder.dart damage assets/packs/starter-0.1.0.nnpack --source ../content/starter --out damaged
$env:Path += ";$env:LOCALAPPDATA\Android\Sdk\platform-tools"
$pkg = "app.nitznutz.nitznutz.dev"
adb shell run-as $pkg mkdir -p no_backup/incoming
foreach ($f in Get-ChildItem damaged\*.nnpack) {
  adb push $f.FullName /data/local/tmp/$($f.Name)
  adb shell run-as $pkg cp /data/local/tmp/$($f.Name) no_backup/incoming/$($f.Name)
  adb shell rm /data/local/tmp/$($f.Name)
}
```

Then on the phone: parent area > the dev harness > section 5 **Install .nnpack files from the incoming folder**.
Expect one line per file, every one of them `REFUSED at <step>: ...` (`damaged-picture`: files, `damaged-manifest`,
`damaged-signature`, `damaged-one-byte`, `stranger-key`: signature or zip, `truncated`: zip). Then tap **List
installed packs**: only `starter 0.1.0` is there. Play the lesson again: it still works.

**C. Timing (optional).** Checking a pack's signature happens once when the app starts. If the lesson takes
noticeably longer than before to open the first time, tell me.

## 7. M3 check: what the learning engine concluded

After you have played the butterflies lesson on the phone (section 6, A), open the dev harness (parent area) and
tap **Show what the engine knows about each child** (section 6 of the page). Expect, for the child who played:
`NUM-A-03` and `NUM-A-04` as `learning` with a mastery estimate and a count of answers, `NUM-A-01` and `COL-A-02`
as `ready`, and nothing about misconceptions or gaps unless you made the same wrong answer on two different counting
steps (then `misconception M-CNT-DOUBLE` or `M-CNT-SKIP` appears as `suspected` or `active`). Play again on another
day and the numbers move; nothing is ever taken away. Tell me if a number looks wrong for what you did.

## 8. M4 checks: characters and voices

Use the dev build. These use free test voices (a tone, not speech): they prove the machinery. Real voices come later.

**A. Put the characters and voices on the phone.** On the PC (PowerShell, from `D:\Children-Learning-App`, phone plugged in):

```powershell
powershell -ExecutionPolicy Bypass -File tools\make-m4-device-packs.ps1 -Push
```

It builds 17 packs (8 family characters, 9 test voices) and copies them to the app's incoming folder. On the phone:
Parents > dev harness > section 5 **Install .nnpack files from the incoming folder**. Expect 17 lines, each `installed ...`.

**B. Meet the friends.** Pick the child, tap the plus button beside the character on the map. Nine friends appear (Nitzi and
the eight). Touch each: it waves and a tone plays in its own pitch. The one with the gold frame is the companion. Go home:
that friend now stands on the map where Nitzi stood. Tap it: it waves and says hello (a tone).

**C. The lesson.** Tap the counting hills. The guide is your friend, and a tone plays with each line while its mouth
opens and closes. Touch the guide: the question again. Leave with the home button in the middle of a line: the sound stops.
At the end the friend celebrates on the card, and (the first time only) you land on Friends' Beach.

**D. Switch back and forth.** Choose Nitzi again and replay: her tone has a different pitch from the others.

**E. Smoothness (optional).** `flutter run --profile` on the Samsung, open the lesson, and watch the performance overlay
while the guide talks. Tell me if the raster and UI bars leave the green. (A real low-end phone is the only true test of
"60 fps on the low-end Android", and I have none.)

Tell me: does anything look cut, stiff, too small or too slow to touch? Which friend would the children pick first?

