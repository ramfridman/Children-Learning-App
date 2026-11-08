# Push to the parent's phone, and the weekly backups (M7b): what only you can do

Nothing here is needed to use the parent area, sync or alerts: alerts already wait in the app and arrive when a phone syncs. These two things add (1) a push on the parent's other phone, and (2) a weekly encrypted backup, kept in a private bucket. The build is done; what is left is below.

## Done already

- The Firebase project, its two Android apps (`app.nitznutz.nitznutz.dev` and `app.nitznutz.nitznutz`) and the sending key on the server (`FCM_SERVICE_ACCOUNT`).
- The `age` key pair for backups. The public half is in the backup workflow; the private half is `C:\Users\ramfr\nitznutz-secrets\backup-age-key.txt`.
- The private bucket and the Storage access key (step 3), once you have done them.
- The read-only database login `backup_reader` and its address, saved in `C:\Users\ramfr\nitznutz-secrets\backup-database-url.txt`.

## 1. Clean up the secrets on this PC (once)

1. Save these in 1Password as file attachments, then delete the copies you do not need on disk:
   - `Downloads\google services\...firebase-adminsdk-fbsvc-....json` (the Firebase sending key: **delete it from Downloads** after saving).
   - `Downloads\google services\google-services.json` and `google services prod.json` (not secret in the same way, but keep them: without them a new PC cannot build push).
   - `C:\Users\ramfr\nitznutz-secrets\backup-age-key.txt` (**the only key that opens a backup**; keep a second copy offline).
2. The two `google-services` files are also copied into the repository folders `app\android\app\src\dev\` and `src\prod\`. Git ignores them; leave them there.

## 2. Give GitHub the backup login (done 2026-10-27)

A GitHub secret is stored by you. In PowerShell, from the repository root:

```powershell
Get-Content -Raw C:\Users\ramfr\nitznutz-secrets\backup-database-url.txt | gh secret set BACKUP_DATABASE_URL --repo ramfridman/Children-Learning-App
```

Then tell me "backup secret is set", and I start the first run and check that it produced an encrypted file.

## 3. Move the backups to a private bucket (2026-11-08)

Until now the weekly backup was a GitHub artifact. The repository is public, so any signed-in GitHub user could download it. From now on it goes to a private bucket on your own Supabase project, and the workflow stops making artifacts. The backup stays encrypted either way; this keeps it out of strangers' hands too. Do these in order; none of them shows or needs a value in this chat.

1. **Make the bucket.** Supabase dashboard, project `ungkvkabqxssggttajfs`, **Storage**, **New bucket**:
   - Name: `nitznutz-backups` (exactly).
   - **Public bucket: off.** (If you can set them: file size limit `50 MB` or leave it empty, since the project's own upload limit is 50 MB; allowed MIME types `application/octet-stream`.)
   - Open the bucket, then **Storage**, **Policies**: there must be **no policy at all** on `storage.objects`, for this bucket or any other (a policy without a bucket name would still let signed-in users read it). Do not add one, and do not accept a template.
2. **Make an S3 access key.** Dashboard, **Storage**, **S3 Configuration** (or **Settings**, Storage), **New access key**, name it `github-backup`. The page shows an access key ID and a secret **once**. Keep that page open, and do not copy them into any chat, file or note. Compare the endpoint and region it shows with `https://ungkvkabqxssggttajfs.storage.supabase.co/storage/v1/s3` and `eu-central-1`, and check that the **S3 protocol** switch is on; if any differs, stop and tell me. (Supabase has no key that is limited to one bucket; this key reaches only Storage, nothing else, and this project has no other bucket. It is not the `service_role` key.)
3. **Give them to GitHub.** Set each secret from the page without printing it, one command at a time. In PowerShell, from the repository root, `gh` asks for the value and hides what you type (paste it, press Enter):

   ```powershell
   gh secret set BACKUP_S3_ACCESS_KEY_ID --repo ramfridman/Children-Learning-App
   ```

   then the same for the second one:

   ```powershell
   gh secret set BACKUP_S3_SECRET_ACCESS_KEY --repo ramfridman/Children-Learning-App
   ```

   then, to see the names:

   ```powershell
   gh secret list --repo ramfridman/Children-Learning-App
   ```

   The last command should list `BACKUP_DATABASE_URL`, `BACKUP_S3_ACCESS_KEY_ID` and `BACKUP_S3_SECRET_ACCESS_KEY` (names and dates only). Then close the Supabase page.
4. **Merge** the change that moves the workflow (I tell you when it is ready), then tell me "bucket and secrets are set". I start the workflow by hand and check these lines in its log: `uploaded nitznutz-backup-... to the private bucket`, `public address refused with http 400` (or 404), `sha256 after upload ...` (write that line down for restores), and the list of deleted old copies (none on the first run).
5. **Check it yourself once** (read-only), in the dashboard SQL editor:

   ```sql
   select id, public from storage.buckets;
   select policyname, roles, cmd from pg_policies where schemaname = 'storage' and tablename = 'objects';
   ```

   The first query should show one bucket, `nitznutz-backups`, with `public = false`. The second query should return **no rows** at all.
   Optionally, to run the closed-check against the bucket, add `-BackupKey nitznutz-backup-YYYY-MM-DD.dump.age` (a real name, copied from the `uploaded` line of a run) to `tools\data-api-closed-check.ps1`; without it the two bucket checks are skipped.
6. **Old artifacts.** Three older `nitznutz-backup` artifacts (2026-10-27, 2026-11-01, 2026-11-08) are still downloadable from the Actions page until they expire (28 days after each). Whether to delete them now (Actions, the run, **Artifacts**, the bin icon) or let them expire is your call; nothing is deleted for you. They are encrypted with your public key, and hold the children's nicknames; the school stage and birth month will be in later ones.
7. **If a key is ever exposed**, delete it in the dashboard (S3 Configuration), make a new one and repeat step 3. Storage contents are unchanged.

## 4. Prove push on your phone

1. Install the newest dev build (I do this for you when the phone is connected by USB).
2. Open the parent area, find the card **התראות בטלפון הזה**, turn it on, and press **Allow** when Android asks to show notifications.
3. Tell me "push is on". I check that the server has the phone's address and send one real test push. You should see a notification that says only "יש התראה חדשה"; tapping it opens the parent gate.

## What I will not ask you to do

I never need the Firebase private key, the age private key or any password in this chat. If a step asks for one, stop and tell me.
