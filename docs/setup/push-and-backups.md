# Push to the parent's phone, and the weekly backups (M7b): what only you can do

Nothing here is needed to use the parent area, sync or alerts: alerts already wait in the app and arrive when a phone syncs. These two things add (1) a push on the parent's other phone, and (2) a weekly encrypted backup. Do them in this order, in PowerShell, from the repository root. I run the commands that need your project ref myself once you tell me each step is done.

## 1. A Firebase project (for the push on Android)

Firebase is Google's service that delivers a push to an Android phone. Only the parent's phones use it. The push says only "יש התראה חדשה"; no name, no alert, no child data.

1. Open <https://console.firebase.google.com> and sign in with the Google account you want to own this (the same one you use for the app is fine).
2. **Add project**. Name it `nitznutz`. When it asks about Google Analytics, switch it **off**.
3. In the project, **Add app**, choose **Android**.
   - Package name: `app.nitznutz.nitznutz.dev` (the development build you install now). Skip the optional fields. **Register app**.
   - **Download `google-services.json`**. Then add a second Android app the same way for the release build, package name `app.nitznutz.nitznutz`, and download its file too.
   - Do not commit them. Put them anywhere outside the repository, for example `C:\Users\ramfr\nitznutz-secrets\firebase\`, and tell me the two file names. I place them where the build needs them and add the one allow-list entry the secret scanner will want (these files hold a client key that is public by design, not a secret).
4. Still in the project, open **Project settings**, then **Service accounts**, then **Generate new private key**. A `.json` file downloads. This one **is a secret**: it lets someone send pushes in your name.
   - Keep it outside the repository, for example `C:\Users\ramfr\nitznutz-secrets\firebase\service-account.json`.
   - Give it to the server (the value never appears on screen or in Git):

     ```powershell
     $raw = Get-Content -Raw 'C:\Users\ramfr\nitznutz-secrets\firebase\service-account.json'
     npx supabase secrets set "FCM_SERVICE_ACCOUNT=$raw" --project-ref ungkvkabqxssggttajfs
     Remove-Variable raw
     ```

   - Save the file in 1Password, then delete it from the disk.
5. Tell me "Firebase is done". I then add the Firebase packages to the app (you already approved `firebase_core` and `firebase_messaging` for parent devices only), register each parent phone's token, and prove the push on your phone.

## 2. The weekly encrypted backup

Every week a job dumps the family data, encrypts it with a public key, and stores the last four. Only you can open them, with the private key.

1. Install `age` (a small encryption tool):

   ```powershell
   winget install --id FiloSottile.age
   ```

   Close and reopen PowerShell.
2. Make the key pair:

   ```powershell
   age-keygen -o C:\Users\ramfr\nitznutz-secrets\backup-age-key.txt
   ```

   It prints a line `Public key: age1...`. **Copy that line.** The file is the **private** key: save it in 1Password, and keep a second copy somewhere offline. Without it a backup cannot be opened, and anyone with it can read every backup.
3. Tell me the public key (it is safe to share) and "age is done". I add it to the backup workflow, set up the backup login on the database, and ask you for one more thing then (a GitHub secret, with exact steps).

## What I will not ask you to do

I never need the Firebase private key, the age private key or any password in this chat. If a step asks for one, stop and tell me.
