# Sign-up for test families, by invitation (owner's decisions, 2026-11-08)

Test families create their own parent accounts on the owner's Supabase project
`ungkvkabqxssggttajfs`, but **only with an address the owner approved**. The list is a table in the
database (`signup_gate.approved_email`) and a "Before User Created" hook refuses every other address
(security review SEC-SU-1). Later, when the attestation revocation check is in, sign-up can be opened
to everyone by switching the hook off (end of this file). The AI tutor and live voice stay switched
off on the server for now. This is option B of `docs/setup/test-apk-readiness.md` section 2, made
invite-only.

## What changed in the app and the server (done in the repository, not deployed yet)

- `app/lib/auth/auth_client.dart`: the email-code request now sends `create_user: true`. A new
  approved address gets an account and a 6-digit code; a returning parent gets a code the same way.
  An address that is not approved gets an error from Supabase (HTTP 403, "This address is not
  invited yet.") and the app shows its usual "could not send the code" message; no email is sent.
- The sign-in page tells a new parent that the first sign-in creates the account, and a throttled code
  request says "wait a few minutes" instead of "check the connection" (both Hebrew strings are
  `needs-editor`: `setupNewAccountHint`, `setupRateLimited`).
- The path: code email, verify (`/auth/v1/verify`, `type: email`, which accepts the sign-up code as
  well), PIN (local), enrolment (the family, the guardian row and the first parent device are created
  by `device-enroll` on the user's first enrolment, inside one transaction), add a child (`child-put`).
- **Enrolment needs a sign-in by emailed code in the last 10 minutes** (SEC-SU-2,
  `signedInByCodeRecently` in `supabase/functions/_shared/token.ts`): the gateway reads the token's
  `amr` claim and wants an `otp` entry with a time within 600 seconds. A password sign-in (someone
  registering an address with a password of his own before the tester does) and a refreshed session
  no longer count. The user must therefore enrol within 10 minutes of typing the code.
- What a stranger gets by signing up: nothing, while the hook is on. Without it: an Auth user row, an
  emailed code and, with a Key Attestation chain made from a leaked key, a family of his own. Every
  other function needs an enrolled device, and enrolment needs a genuine, allow-listed app on a genuine
  phone (security rule 3, `android_allowed_apps`). No family row exists until a device enrols.
- `supabase/config.toml` now matches the live settings that matter (sign-up on, Confirm email on, the
  hook on; SEC-SU-7). See "supabase/config.toml" below before any `supabase config push`.

## Deploy order (the orchestrator, with the owner's OK; nothing is deployed yet)

1. **Migration first**: `20261108130000_signup_allowlist.sql` creates the schema `signup_gate`, the list
   and the hook function. It changes no existing table. From the repository folder, after
   `npx supabase login` and the link in step 1 of `docs/setup/supabase-deploy.md`:

   ```powershell
   npx supabase db push --linked --dry-run
   npx supabase db push --linked
   ```

2. **Put the owner's own address and the first testers on the list** (existing accounts keep working
   without it, since the hook runs only when an account is created, but a new phone for a new address
   needs it):

   ```powershell
   powershell -ExecutionPolicy Bypass -File tools\signup-allowlist.ps1 -Add owner@example.com, tester1@example.com
   powershell -ExecutionPolicy Bypass -File tools\signup-allowlist.ps1 -Count
   ```

3. **Switch the hook on** in the dashboard (next section, step 1), **then** switch "Allow new users to sign
   up" on. If sign-ups are already on, do step 1 at once and run "What to check live" 1.
4. **Redeploy the functions** (every function bundles `_shared/`, so redeploy all of them to keep them in
   step; `enroll-challenge` and `device-enroll` are the two that changed behaviour):

   ```powershell
   npx supabase functions deploy --use-api --project-ref ungkvkabqxssggttajfs
   ```

   (The form of `docs/setup/supabase-deploy.md` step 4.) Then "What to check live" 4 at once. If enrolment is refused for a genuine code sign-in, redeploy the
   previous commit's functions and tell the security-engineer.

## What you do in the Supabase dashboard

Project `ungkvkabqxssggttajfs`, in a browser (no PowerShell needed for these clicks).

1. **The hook (do this first).** Authentication > Hooks (older dashboards: Authentication > Auth Hooks).
   **Before User Created** > Add hook > type **Postgres function** > schema `signup_gate`, function
   `before_user_created` > Create/Save, and make sure it is **enabled**. If the schema or function is
   not in the list, the migration is not applied (deploy order step 1). Fallback if the dashboard cannot
   do it: the Management API call `PATCH /v1/projects/ungkvkabqxssggttajfs/config/auth` with
   `hook_before_user_created_enabled: true` and
   `hook_before_user_created_uri: "pg-functions://postgres/signup_gate/before_user_created"`; the
   orchestrator makes it with your OK.
2. **Allow new users to sign up.** Authentication > Sign In / Providers (older dashboards:
   Authentication > Settings). Under **User Signups** turn on **Allow new users to sign up**.
3. **Only the Email provider.** Same page: **Email** on; Apple, Azure, Google, Phone, Anonymous sign-ins
   and every other provider **off**. (Another provider is a second way to create an account; the hook
   would see it too, but there is no reason to leave one on.)
4. **Confirm email must stay ON** (SEC-SU-3). In the Email provider's settings, **Confirm email** on.
   Typing the emailed code is the confirmation; the app has no second step. With it off, anyone can
   make unlimited accounts with a password and no mailbox, and "User already registered" tells whether
   an address has an account.
5. **Put the code in the "Confirm sign up" template.** Authentication > Emails (Templates) >
   **Confirm sign up**. Make the body carry the code, as the Magic Link template already does
   (`docs/setup/supabase-deploy.md` step 6b):

   ```html
   <p>Your Nitznutz sign-in code is <strong>{{ .Token }}</strong></p>
   ```

   Without `{{ .Token }}` a new user receives only a link, and the app has nowhere to type it. Save.
6. **Leave SMTP as it is** (custom Gmail SMTP, step 6a). Supabase's built-in sender sends to very few
   addresses and cannot serve test families. Prefer a sender that is not your personal mailbox.
7. **Do not turn on CAPTCHA** (SEC-SU-4). Authentication > Bot and Abuse Protection stays off: the
   app sends no CAPTCHA token, so every code request, new and returning, would be refused.
8. **Rate limits.** Authentication > Rate Limits: write the numbers down. Keep **emails per hour** low
   (about 30 or fewer; a handful of testers need far fewer). Leave sign-ups and sign-ins per IP at the
   default.
9. **The hook's schema stays closed.** Settings > API (or Data API) > **Exposed schemas** lists only
   `public` (and `graphql_public`). It must not list `signup_gate` or `app`. The gateway reaches the
   database over its own connection and needs none of them exposed.

## Adding and removing testers

Run by the orchestrator, with your OK each time, from the repository folder. The addresses are given on
the command line, go only into the live database and are never written to a file, a commit or a pull
request:

```powershell
powershell -ExecutionPolicy Bypass -File tools\signup-allowlist.ps1 -Add name@example.com, other@example.com
powershell -ExecutionPolicy Bypass -File tools\signup-allowlist.ps1 -Remove name@example.com
powershell -ExecutionPolicy Bypass -File tools\signup-allowlist.ps1 -Count
powershell -ExecutionPolicy Bypass -File tools\signup-allowlist.ps1 -List
```

- `-DryRun` prints the SQL instead of running it. The same works in the dashboard SQL Editor:
  `insert into signup_gate.approved_email (email) select signup_gate.normalise_email('Name@Example.com') on conflict do nothing;`
- Every address is trimmed and lower-cased (letters A to Z only) before it is stored and before it is
  compared. A plus-alias (`name+kid@gmail.com`) is a different address and is listed as written.
- The list decides only who can **create** an account. Removing an address does not delete an account
  that exists, or sign it out. To lock a tester out, also delete the user (Authentication > Users) and
  revoke the family's devices.
- An address that already has an account gets its code without being on the list. So an unlisted address
  that gets a code has an account; one that is refused has none. That is the only thing a stranger can
  learn from the hook.

## supabase/config.toml and `supabase config push` (SEC-SU-7)

`supabase/config.toml` is the local stack's file. It now says sign-up on, Confirm email on and the hook
on, as the live project should be. It still has the local stack's own `[auth.rate_limit] email_sent = 2`
and `max_frequency = "1s"`, so **do not run `supabase config push` against the live project** without
reading the whole `[auth]` section first: it would write those over the dashboard's values and stop the
testers' codes. The live settings are changed in the dashboard (above) or with the Management API.

## Email limits (what to know)

- Each new family needs at least one email (the code), and each later sign-in another. A code is valid
  for about an hour by default (Authentication > Sign In / Providers > Email > "Email OTP expiration").
- **Supabase**: Authentication > Rate Limits shows "Rate limit for sending emails" (per hour, for the
  whole project; with custom SMTP it starts low, about 30 an hour, and you can change it). One
  address can ask for a new code only about once a minute. The app shows "wait a few minutes" when
  Supabase answers 429.
- **Gmail SMTP**: a personal Gmail account allows only a few hundred sent messages a day (about 500 as of
  Google's published limit; going over it blocks sending for about a day). Fine for a handful of
  families. If the test grows, move the sender to a domain of your own (Resend or Brevo, same form in
  step 6a).
- With the hook on, a stranger cannot make the project mail a code to an address that is not on the list
  and has no account, so the hourly budget is spent only on testers.
- **Emergency stop**: switch "Allow new users to sign up" off (dashboard step 2 reversed; nothing in the
  app needs to change, a new address just gets an error), or empty the list
  (`delete from signup_gate.approved_email;`). Do **not** use CAPTCHA (dashboard step 7).

## What to check live (after the clicks)

1. **A stranger is refused.** From a PowerShell window in the repository folder (the project URL and
   publishable key come from `app\config\dev.local.json`; the key is public in every APK, but do not
   paste it into chats):

   ```powershell
   $cfg = Get-Content app\config\dev.local.json -Raw | ConvertFrom-Json
   $body = '{"email":"not-invited-check@example.com","create_user":true}'
   curl.exe -s -i -X POST "$($cfg.SUPABASE_URL)/auth/v1/otp" -H "apikey: $($cfg.SUPABASE_PUBLISHABLE_KEY)" -H "content-type: application/json" --data-raw $body
   ```

   Expected: an HTTP 4xx (403) whose body says `This address is not invited yet.`, no email sent, and
   no new row in Authentication > Users. If it answers 200, the hook is not enabled: switch sign-ups off
   at once (dashboard step 2 reversed) and tell the orchestrator.
2. Install a build with this change on a real phone and sign up with an address on the list (a Gmail `+`
   alias such as `name+signup1@gmail.com` also receives mail, but is a different address and must be
   listed as written).
3. The email arrives and shows a 6-digit code (not only a link). If it shows a link only, dashboard
   step 5 was not saved on the **Confirm sign up** template.
4. Type the code: the app moves on to the device-registration step. Register the device within 10
   minutes (the prod package also needs its `android_allowed_apps` row; the dev package already has
   one), set the PIN, add a child. Your own existing parent account must also still enrol a new phone:
   sign in by code and enrol at once. This proves the `otp` sign-in method is what Supabase puts in the
   token for the emailed code (SEC-SU-2). If enrolment is refused after a fresh code, see deploy order 4.
5. In the dashboard, Authentication > Users shows the new user. Table `app.guardian` has a row for it
   after enrolment (see the read-only queries below).
6. Ask for a code again for the same address: the second email is a "Magic Link" email and also has
   the code.
7. Ask for codes quickly several times: the app says to wait, and no error text names the cause as the
   network.
8. Dashboard read-only checks: Storage has no bucket that `authenticated` can read or write; Providers
   shows only Email; "Confirm email" is on; CAPTCHA is off; the emails-per-hour number is the one you
   wrote down.

## Opening sign-up to everyone, later

Not yet. First the attestation revocation check (the signing review's smallest step, so that a leaked
factory key stops working) and a per-family daily event cap at `sync-push`; and before the tutor or live
voice are ever switched on with open sign-up, a project-wide daily cost cap and the vendors' own hard
limits (SEC-SU-6). Then the hook is switched off in the dashboard (Authentication > Hooks > Before User
Created), after the security-engineer's review.

## Confirm the tutor and live voice are off (read-only)

The gateway treats a missing row or any value other than the JSON boolean `true` as off
(`supabase/functions/_shared/tutor_core.ts`). Step 8.5 of `docs/setup/supabase-deploy.md` set both rows
to `true` for the owner's own test, so read the live values first. This query only reads
(`select`), so you or Claude can run it from the repository folder, after `npx supabase login` and the
link in step 1 of the deploy guide:

```powershell
$sql = @'
select k.key,
       c.value,
       case when c.key is null then 'missing: the server treats it as OFF'
            when c.value = 'true'::jsonb then 'ON: must be off for the open-sign-up test'
            else 'off' end as state
  from (values ('tutor_enabled'), ('live_voice_enabled')) as k(key)
  left join app.config c on c.key = k.key
 order by k.key;
'@
npx supabase db query --linked $sql
```

Expected: both rows `off` (or `missing`). The same query works pasted in the dashboard SQL Editor.

If a row says **ON**, nothing here changes it. Tell the orchestrator; with your OK the
infrastructure-engineer sets it (one row each, no deploy):

```sql
insert into app.config (key, value) values
  ('tutor_enabled', 'false'::jsonb),
  ('live_voice_enabled', 'false'::jsonb)
on conflict (key) do update set value = excluded.value, updated_at = now();
```

The app reads `tutor_enabled` from the `app-config` function, so a parent is not offered the AI helper
while it is off; the server refuses a tutor turn anyway. (`app-config` also reports a row named
`voice_enabled`; it is a separate, informational row, and the one that gates the spoken line and
ElevenLabs on the server is `live_voice_enabled`.) The voiced pre-warmed lines that ship inside the packs still play,
and RuleTutor is the only tutor.

Optional read-only checks of who has signed up (counts only, nothing personal):

```powershell
$sql = @'
select (select count(*) from auth.users) as users,
       (select count(*) from app.guardian) as guardians,
       (select count(*) from app.family) as families,
       (select count(*) from app.device where revoked_at is null) as active_devices,
       (select count(*) from signup_gate.approved_email) as approved_addresses;
'@
npx supabase db query --linked $sql
```

`users` above `guardians` means someone asked for a code but never registered a device; those rows are
harmless.
