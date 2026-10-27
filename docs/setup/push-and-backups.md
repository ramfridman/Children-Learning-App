# Push to the parent's phone, and the weekly backups (M7b): what only you can do

Nothing here is needed to use the parent area, sync or alerts: alerts already wait in the app and arrive when a phone syncs. These two things add (1) a push on the parent's other phone, and (2) a weekly encrypted backup. The build is done; what is left is below.

## Done already

- The Firebase project, its two Android apps (`app.nitznutz.nitznutz.dev` and `app.nitznutz.nitznutz`) and the sending key on the server (`FCM_SERVICE_ACCOUNT`).
- The `age` key pair for backups. The public half is in the backup workflow; the private half is `C:\Users\ramfr\nitznutz-secrets\backup-age-key.txt`.
- The read-only database login `backup_reader` and its address, saved in `C:\Users\ramfr\nitznutz-secrets\backup-database-url.txt`.

## 1. Clean up the secrets on this PC (once)

1. Save these in 1Password as file attachments, then delete the copies you do not need on disk:
   - `Downloads\google services\...firebase-adminsdk-fbsvc-....json` (the Firebase sending key: **delete it from Downloads** after saving).
   - `Downloads\google services\google-services.json` and `google services prod.json` (not secret in the same way, but keep them: without them a new PC cannot build push).
   - `C:\Users\ramfr\nitznutz-secrets\backup-age-key.txt` (**the only key that opens a backup**; keep a second copy offline).
2. The two `google-services` files are also copied into the repository folders `app\android\app\src\dev\` and `src\prod\`. Git ignores them; leave them there.

## 2. Give GitHub the backup login (the one thing I may not do for you)

A GitHub secret is stored by you. In PowerShell, from the repository root:

```powershell
Get-Content -Raw C:\Users\ramfr\nitznutz-secrets\backup-database-url.txt | gh secret set BACKUP_DATABASE_URL --repo ramfridman/Children-Learning-App
```

Then tell me "backup secret is set", and I start the first run and check that it produced an encrypted file.

## 3. Prove push on your phone

1. Install the newest dev build (I do this for you when the phone is connected by USB).
2. Open the parent area, find the card **התראות בטלפון הזה**, turn it on, and press **Allow** when Android asks to show notifications.
3. Tell me "push is on". I check that the server has the phone's address and send one real test push. You should see a notification that says only "יש התראה חדשה"; tapping it opens the parent gate.

## What I will not ask you to do

I never need the Firebase private key, the age private key or any password in this chat. If a step asks for one, stop and tell me.
