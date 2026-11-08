# Open sign-up for test families (owner's decision, 2026-11-08)

Test families create their own parent accounts on the owner's Supabase project
`ungkvkabqxssggttajfs`. The AI tutor and live voice stay switched off on the server for now. This is
option B of `docs/setup/test-apk-readiness.md` section 2.

## What changed in the app (done)

- `app/lib/auth/auth_client.dart`: the email-code request now sends `create_user: true`. A new address
  gets an account and a 6-digit code; a returning parent gets a code the same way. The server's
  "Allow new users to sign up" switch still decides whether a new address is accepted.
- The sign-in page tells a new parent that the first sign-in creates the account, and a throttled code
  request says "wait a few minutes" instead of "check the connection" (both Hebrew strings are
  `needs-editor`: `setupNewAccountHint`, `setupRateLimited`).
- Nothing else changes for a brand-new account, and no server step is needed besides the dashboard
  clicks below. The path: code email, verify (`/auth/v1/verify`, `type: email`, which accepts the
  sign-up code as well), PIN (local), enrolment (the family, the guardian row and the first parent
  device are created by `device-enroll` on the user's first enrolment, inside one transaction), add
  a child (`child-put`). The user must enrol within 10 minutes of the code (`FRESH_SIGN_IN_SECONDS`).
- What a stranger gets by signing up: an Auth user row and an emailed code. Nothing else. Every other
  function needs an enrolled device, and enrolment needs a genuine, allow-listed app on a genuine phone
  (security rule 3, `android_allowed_apps`). No family row exists until a device enrols.

## What you do in the Supabase dashboard

Project `ungkvkabqxssggttajfs`, in a browser (no PowerShell needed for these clicks).

1. **Allow new users to sign up.** Authentication > Sign In / Providers (older dashboards:
   Authentication > Settings). Under **User Signups** turn on **Allow new users to sign up**. Check
   that the **Email** provider is enabled.
2. **Confirm email.** In the Email provider's settings, **Confirm email** may stay on. Typing the emailed
   code is the confirmation; the app has no second step. (If it is on, a new user gets the "Confirm
   sign up" email, which is why the next click matters. If it is off, a new user gets the "Magic Link"
   email like before.)
3. **Put the code in the "Confirm sign up" template.** Authentication > Emails (Templates) >
   **Confirm sign up**. Make the body carry the code, as the Magic Link template already does
   (`docs/setup/supabase-deploy.md` step 6b):

   ```html
   <p>Your Nitznutz sign-in code is <strong>{{ .Token }}</strong></p>
   ```

   Without `{{ .Token }}` a new user receives only a link, and the app has nowhere to type it. Save.
4. **Leave SMTP as it is** (custom Gmail SMTP, step 6a). Supabase's built-in sender sends to very few
   addresses and cannot serve test families.
5. **Look at Authentication > Rate Limits** and write the numbers down (section "Email limits" below).
   Keep the email limit low. Leave sign-ups and sign-ins per IP at the default.

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
- Open sign-up means anyone who has the APK can ask for codes to any address. They cannot do more than
  that, but each request spends one email from your quota. If abuse shows up, lower the per-hour
  limit, turn on CAPTCHA (Authentication > Bot and Abuse Protection), or switch sign-ups off again
  (step 1 reversed; nothing in the app needs to change, a new address just gets an error).

## What to check live (after the clicks)

1. Install a build with this change on a real phone and sign up with an address that has never been
   used (a Gmail `+` alias such as `name+signup1@gmail.com` also receives mail).
2. The email arrives and shows a 6-digit code (not only a link). If it shows a link only, step 3 was
   not saved on the **Confirm sign up** template.
3. Type the code: the app moves on to the device-registration step. Register the device (the prod
   package also needs its `android_allowed_apps` row; the dev package already has one), set the PIN,
   add a child.
4. In the dashboard, Authentication > Users shows the new user. Table `app.guardian` has a row for it
   after enrolment (see the read-only queries below).
5. Ask for a code again for the same address: the second email is a "Magic Link" email and also has
   the code.
6. Ask for codes quickly several times: the app says to wait, and no error text names the cause as the
   network.

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
       (select count(*) from app.device where revoked_at is null) as active_devices;
'@
npx supabase db query --linked $sql
```

`users` above `guardians` means someone asked for a code but never registered a device; those rows are
harmless.
