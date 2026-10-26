# Putting the gateway on your Supabase project (Frankfurt)

Everything here runs in PowerShell from `D:\Children-Learning-App`. Nothing secret goes into the
repository, into chat, or into a command you type: secrets are generated on your machine, saved in
1Password, and sent to Supabase from a temporary file that you delete afterwards.

Project reference: `ungkvkabqxssggttajfs`. Do these steps in order.

## 1. Get the tools and log in

```powershell
npm ci
npx supabase --version        # expect 2.122.0
npx supabase login            # opens the browser; approve
npx supabase link --project-ref ungkvkabqxssggttajfs
```

`link` asks for the database password you set when creating the project (it is in 1Password).

## 2. Create the closed database schema

```powershell
npx supabase db push
```

It shows the two migrations (`app_schema`, `app_jobs`) and asks to confirm. Answer `y`.

Check in the dashboard (Table Editor, schema picker): the `app` schema is **not** listed under
exposed schemas, and Settings > API > "Exposed schemas" shows only `public`.

## 3. Give the gateway its own limited database login

The gateway never uses the all-powerful `postgres` login. Make a password for the limited role:

```powershell
function New-Secret($bytes) {
  $b = New-Object byte[] $bytes
  $rng = [System.Security.Cryptography.RandomNumberGenerator]::Create()
  $rng.GetBytes($b)
  [Convert]::ToBase64String($b).TrimEnd('=').Replace('+','-').Replace('/','_')
}
New-Secret 30 | Set-Clipboard
```

1. Paste it into a new 1Password item called `Nitznutz gateway DB password`.
2. In the Supabase dashboard open **SQL Editor**, paste this with your password in place of
   `PASTE_HERE`, and run it:

   ```sql
   alter role app_gateway with login password 'PASTE_HERE';
   ```
3. Dashboard > **Connect** > **Session pooler** shows a connection string that starts with
   `postgresql://postgres.ungkvkabqxssggttajfs:`. Build yours by changing `postgres.` to
   `app_gateway.` and putting your password where `[YOUR-PASSWORD]` is. Keep it for step 4.

## 4. Send the secrets to the functions

You need four values. Three are made now; the fourth is a new Supabase secret key.

1. Dashboard > Settings > **API Keys** > create a new **secret** key named `gateway-auth-admin`.
   Copy it into 1Password as `Nitznutz gateway auth admin key`.
2. Create the temporary file **outside the repository**:

   ```powershell
   $dir = "$env:USERPROFILE\nitznutz-secrets"
   New-Item -ItemType Directory -Force -Path $dir | Out-Null
   notepad "$dir\functions.env"
   ```
3. In Notepad write these four lines (generate the two `...KEY` values with `New-Secret 32`,
   run it twice, and save each in 1Password as well):

   ```
   APP_GATEWAY_DB_URL=<the session pooler string from step 3>
   AUTH_ADMIN_KEY=<the secret key from step 4.1>
   PAIRING_CODE_KEY=<New-Secret 32>
   IP_HASH_KEY=<New-Secret 32>
   ```
4. Send them and delete the file:

   ```powershell
   npx supabase secrets set --env-file "$dir\functions.env"
   Remove-Item -Recurse -Force $dir
   npx supabase secrets list
   ```

   `secrets list` shows names and digests only, never values. Do **not** set
   `ALLOW_DEV_ENROLMENT` on the cloud project.

## 5. Deploy the functions

```powershell
npx supabase functions deploy --use-api
```

(`--use-api` bundles on Supabase's side, so Docker is not needed.) It lists
`signed-ping`, `app-config`, `enroll-challenge`, `device-enroll`, `device-pair`,
`pairing-code-create`, `device-list` and `device-revoke`; from M6 also `content-publish`, `tutor-turn` and `tutor-prewarm`.

Quick check that the gateway is closed to strangers:

```powershell
curl.exe -s -X POST https://ungkvkabqxssggttajfs.supabase.co/functions/v1/signed-ping
```

Expected: `{"error":"unauthorized"}`.

## 6. Create your own user (sign-ups are off)

Dashboard > Authentication > Users > **Add user** > **Create new user**, with your email and
"Auto Confirm User" ticked. Sign-in on the phone is by email code to that address.

### 6a. Set up an SMTP sender (needed before 6b can be used)

Supabase's built-in sender is for trying things out only: it sends to few addresses and a handful
of emails an hour, and the dashboard asks for your own SMTP before you customise emails. Use a
sender you control. The simplest is a Gmail app password (no domain needed):

1. Google Account > Security: 2-Step Verification must be on. Then open
   https://myaccount.google.com/apppasswords, create an app password named `Nitznutz Supabase`, and
   save the 16 characters in 1Password (item `Nitznutz SMTP app password`). It can be revoked there
   at any time. (If you own a domain, Resend or Brevo work the same way and are cleaner.)
2. Dashboard > Authentication > Emails > **SMTP Settings** > turn on **Enable custom SMTP**:
   - Sender email: your Gmail address; Sender name: `Nitznutz`
   - Host: `smtp.gmail.com`; Port: `465`; Username: your full Gmail address
   - Password: the 16-character app password (typed into this form only, never into chat or a file)
3. Save. Then Authentication > Rate Limits: leave the email limit at its default (it rises once
   custom SMTP is on).

### 6b. Make the sign-in email carry a code

Dashboard > Authentication > Emails (Templates) > **Magic Link**. Change the body so it contains
the code, for example:

```html
<p>Your Nitznutz sign-in code is <strong>{{ .Token }}</strong></p>
```

Without `{{ .Token }}` Supabase sends only a link, and the app has nowhere to type it. Also
check Authentication > Sign In / Providers: **Allow new users to sign up** is off and Email is on.

## 7. Tell the server which app is yours (any time after step 2)

The fingerprint comes from the debug key on this PC (`%USERPROFILE%\.android\debug.keystore`), so it
is the same for every dev build made here and the app does not need to exist yet. Claude read it on
2026-10-25: `3d5b8c4ab4722dfcf736ce16bdb9a6297bf216307efcf2b5fd5d2a3e1b25ffb9` (it matches the
built dev APK). To read it yourself:

```powershell
keytool -list -v -keystore "$env:USERPROFILE\.android\debug.keystore" -alias androiddebugkey -storepass android -keypass android | Select-String "SHA256"
```

Remove the colons and make it lower case, then in the SQL Editor:

```sql
insert into app.config (key, value) values
  ('android_allowed_apps',
   '[{"package_name": "app.nitznutz.nitznutz.dev", "cert_sha256": ["PASTE_64_HEX_CHARS"]}]'::jsonb)
on conflict (key) do update set value = excluded.value, updated_at = now();
```

Until this row exists the server refuses every Android enrolment on purpose.

## 8. The AI tutor (M6): keys, rows, publish, pre-warm

Do this only when you are at the PC, have created both keys with their spend limits in the
consoles (Anthropic: a workspace with a monthly limit; ElevenLabs: a credit limit), and have chosen
the voice ids (M4 Phase H). Claude never sees a key: each is typed into a hidden prompt.

1. Send the three secrets (no value is shown or kept; the file is deleted at once):

   ```powershell
   $dir = "$env:USERPROFILE\nitznutz-secrets"
   New-Item -ItemType Directory -Force -Path $dir | Out-Null
   function Ask($name) {
     $s = Read-Host -AsSecureString $name
     [System.Net.NetworkCredential]::new("", $s).Password
   }
   function New-Secret($bytes) {
     $b = New-Object byte[] $bytes
     $rng = [System.Security.Cryptography.RandomNumberGenerator]::Create()
     $rng.GetBytes($b)
     [Convert]::ToBase64String($b).TrimEnd('=').Replace('+','-').Replace('/','_')
   }
   $publish = New-Secret 32
   @(
     "ANTHROPIC_API_KEY=$(Ask 'Anthropic key')",
     "ELEVENLABS_API_KEY=$(Ask 'ElevenLabs key')",
     "CONTENT_PUBLISH_SECRET=$publish"
   ) | Set-Content -Path "$dir\tutor.env" -Encoding ascii
   npx supabase secrets set --env-file "$dir\tutor.env"
   Remove-Item -Recurse -Force $dir
   $publish | Set-Clipboard
   ```

   The publish secret is now on the clipboard: save it in 1Password as `Nitznutz content publish
   secret`, then clear the clipboard. Set it for your PowerShell window with
   `$env:NITZNUTZ_PUBLISH_SECRET = "<paste>"` whenever you run the tools below (never write it in a file).

2. Deploy the functions: `npx supabase functions deploy --use-api`.

3. In the Supabase SQL Editor, set the rows (the model id and prices come from the providers' pages;
   write what you read there, not a guess):

   ```sql
   insert into app.config (key, value) values
     ('elevenlabs_model_id', '"<model id from ElevenLabs>"'::jsonb),
     ('tutor_cost_cap_micro', '500000'::jsonb),
     ('tutor_price_micro', '{"in_per_mtok": <micro-dollars per million input tokens>, "out_per_mtok": <same, output>, "voice_per_1k_chars": <micro-dollars per 1,000 characters>}'::jsonb)
   on conflict (key) do update set value = excluded.value, updated_at = now();
   ```

   Leave `tutor_enabled` and `live_voice_enabled` off until the lines have been listened to (step 6).

4. Publish the starter pack's item index (from the `app` folder; `--dry-run` first shows only counts):

   ```powershell
   cd app
   dart run tool/pack_builder.dart publish assets/packs/starter-0.2.0.nnpack --dry-run
   dart run tool/pack_builder.dart publish assets/packs/starter-0.2.0.nnpack
   ```

5. Pre-warm. `plan` makes nothing; `make` refuses unless you type back the number `plan` printed:

   ```powershell
   dart run tool/tutor_prewarm.dart plan assets/packs/starter-0.2.0.nnpack --characters nitzi
   dart run tool/tutor_prewarm.dart make assets/packs/starter-0.2.0.nnpack --characters nitzi --confirm-lines <N>
   ```

   The tool prints the number of lines, the voice characters and the estimated cost before it
   starts, and stops at 1.5 times the estimate. Switch the server on for the measurement:
   `update app.config set value = 'true'::jsonb where key in ('tutor_enabled', 'live_voice_enabled');`
   (insert the rows if they do not exist yet), then
   `dart run tool/tutor_prewarm.dart measure assets/packs/starter-0.2.0.nnpack --characters nitzi --count 10`
   prints the median server time with the model's and the voice's share.

6. Read every made line before a child can meet one. In the SQL Editor:
   `select item_id, mistake, band, address_form, line from app.tutor_cache order by 1, 2, 3, 4;`
   (the lines are vocalised Hebrew). Then listen to them on the phone, in device checks
   section 10, with the **AI helper** switched on in the dev page. Only after both, tell Claude
   you are happy for the helper to be offered to the parent in M7.

## What this does not do

- It does not turn on the AI tutor or voice. `app-config` reports both switches off until you set
  the rows `tutor_enabled` / `live_voice_enabled` to `true` in `app.config` (section 8).
- It does not enable the dev allowlist. Emulator enrolment works only on the local stack
  (`ALLOW_DEV_ENROLMENT=true`, needs Docker Desktop) or during a short, deliberate test window.
