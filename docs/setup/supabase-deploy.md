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
`pairing-code-create`, `device-list` and `device-revoke`.

Quick check that the gateway is closed to strangers:

```powershell
curl.exe -s -X POST https://ungkvkabqxssggttajfs.supabase.co/functions/v1/signed-ping
```

Expected: `{"error":"unauthorized"}`.

## 6. Create your own user (sign-ups are off)

Dashboard > Authentication > Users > **Add user** > **Create new user**, with your email and
"Auto Confirm User" ticked. Sign-in on the phone is by email code to that address.

## 7. Tell the server which app is yours (after the first build)

Once the debug app exists, take its signing-certificate fingerprint:

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

## What this does not do

- It does not turn on the AI tutor or voice. `app-config` reports both switches off until you set
  the rows `tutor_enabled` / `voice_enabled` to `true` in `app.config`.
- It does not enable the dev allowlist. Emulator enrolment works only on the local stack
  (`ALLOW_DEV_ENROLMENT=true`, needs Docker Desktop) or during a short, deliberate test window.
