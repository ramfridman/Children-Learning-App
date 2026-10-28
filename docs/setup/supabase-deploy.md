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

**Deploy order (SEC-12).** Deploy the gateway functions first, from `main`, and only in a way that keeps what an installed app may still send (new fields optional, patterns and enums only wider). To narrow anything, release the app first and the server later. A server that suddenly refuses what the app sends makes the app mark its unsent answers as refused.

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

## 8. The AI tutor (M6): what is done, and what only you can do

**Done by Claude on 2026-10-27 (nothing to repeat):** the database migration `20261026120000_tutor_tables`
(`npx supabase db push`; on a new project it is part of step 2), and all 11 functions deployed
(`npx supabase functions deploy --use-api --project-ref ungkvkabqxssggttajfs`), including the new
`content-publish`, `tutor-turn` and `tutor-prewarm`. They are closed: strangers get 401, and the two
functions that need the publish secret answer "unavailable" until you do step 4.

**What is still missing, in order.** Do steps 1 to 4 at the PC; steps 5 and 6 Claude can run once you say
the earlier ones are done. Never paste a key into the chat.

1. **Anthropic key (about 5 minutes).** console.anthropic.com > your workspace for Nitznutz > check that
   its monthly spend limit is set (your plan says 5 USD) > API keys > create a key named
   `nitznutz-tutor` in that workspace. Copy it into 1Password as `Nitznutz Anthropic key`. (A screenshot
   of the limit page is also on your list, P2.)
2. **ElevenLabs key (about 5 minutes).** elevenlabs.io > your profile > API keys > create a key named
   `nitznutz-tutor`, allow **only Text to Speech** (and "history" if it is a separate switch: the
   server deletes each made line afterwards), and set a credit limit on the key. Copy it into
   1Password as `Nitznutz ElevenLabs key`.
3. **A voice for the guide (about 30 minutes, the same as M4 Phase H).** The tutor speaks in the guide's
   own voice, so a character with no voice id cannot have live lines. Start with **one** character, the
   one your child picked (`hero-son`), and add the others later.
   1. In ElevenLabs open the voice library, filter for Hebrew, listen, and copy the **voice id** of the
      one you like (a short code of letters and digits).
   2. Put it in `content/voices.json` under `"hero-son": { "voiceId": "<the id>" }`.
   3. Tell Claude which model you want ("Eleven v3", "Multilingual v2", ...): Claude will read the
      current model list and prices on ElevenLabs' and Anthropic's pages and show you the exact model id
      and the prices to confirm. Nobody should guess the model id.
   4. Listen: `$env:ELEVENLABS_API_KEY` is set from a hidden prompt, then
      `dart run tool/voice_gen.dart audition hero-son "<a short sentence>"` plays one line.
4. **Send the three secrets** (the keys are typed into hidden prompts; nothing is shown or kept; the
   temporary file is deleted at once):

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
   npx supabase secrets set --env-file "$dir\tutor.env" --project-ref ungkvkabqxssggttajfs
   Remove-Item -Recurse -Force $dir
   $publish | Set-Clipboard
   ```

   The publish secret is now on the clipboard: save it in 1Password as `Nitznutz content publish
   secret`, then copy something else to clear the clipboard. For each PowerShell window in which you (or
   Claude) run the tools below: `$env:NITZNUTZ_PUBLISH_SECRET = "<paste>"` (never write it in a file).
5. **Claude: set the rows** in `app.config` (the model id and prices from step 3.3; the daily cap stays
   0.50 USD): `elevenlabs_model_id`, `tutor_price_micro` (`in_per_mtok`, `out_per_mtok`,
   `voice_per_1k_chars`, in millionths of a dollar) and, for the test, `tutor_enabled` and
   `live_voice_enabled`:

   ```sql
   insert into app.config (key, value) values
     ('elevenlabs_model_id', '"<model id>"'::jsonb),
     ('tutor_cost_cap_micro', '500000'::jsonb),
     ('tutor_price_micro', '{"in_per_mtok": <n>, "out_per_mtok": <n>, "voice_per_1k_chars": <n>}'::jsonb),
     ('tutor_enabled', 'true'::jsonb),
     ('live_voice_enabled', 'true'::jsonb)
   on conflict (key) do update set value = excluded.value, updated_at = now();
   ```
6. **Claude: publish, pre-warm, measure** (from the `app` folder, with the secret set as above):

   ```powershell
   dart run tool/pack_builder.dart publish assets/packs/starter-0.3.0.nnpack --dry-run
   dart run tool/pack_builder.dart publish assets/packs/starter-0.3.0.nnpack
   dart run tool/tutor_prewarm.dart plan assets/packs/starter-0.3.0.nnpack --characters hero-son
   dart run tool/tutor_prewarm.dart make assets/packs/starter-0.3.0.nnpack --characters hero-son --confirm-lines <N>
   dart run tool/tutor_prewarm.dart measure assets/packs/starter-0.3.0.nnpack --characters hero-son --count 10
   ```

   `plan` prints the number of lines, the voice characters and the estimated cost, and `make` refuses
   unless you type that number back (Claude shows it to you first and waits for your OK). `measure`
   prints the median server time with the model's and the voice's share: the real latency figure.
7. **You: listen.** Read the made lines in the SQL Editor
   (`select item_id, mistake, band, address_form, line from app.tutor_cache order by 1, 2, 3, 4;`), then
   on the phone switch **AI helper in lessons** on in the dev page and make two mistakes in the counting
   hills (device checks section 10). Only after that is the helper ever offered to a parent (M7).

## What this does not do

- It does not turn on the AI tutor or voice. `app-config` reports both switches off until you set
  the rows `tutor_enabled` / `live_voice_enabled` to `true` in `app.config` (section 8).
- It does not enable the dev allowlist. Emulator enrolment works only on the local stack
  (`ALLOW_DEV_ENROLMENT=true`, needs Docker Desktop) or during a short, deliberate test window.
