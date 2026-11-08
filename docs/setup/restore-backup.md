# Restoring a weekly backup

A backup is one file, `nitznutz-backup-YYYY-MM-DD.dump.age`: a PostgreSQL dump of the `app` schema (families, devices, children with their nicknames, school stages, answers, visits, alerts, settings), encrypted so that only the private key can open it. It sits in the private Storage bucket `nitznutz-backups` on the Supabase project. The weekly job deletes copies older than 27 days, so the last four weeks are there. (Before 2026-11-08 backups were GitHub artifacts; see the end.)

1. **Get the file.** Supabase dashboard, project `ungkvkabqxssggttajfs`, **Storage**, bucket `nitznutz-backups`, click the newest `.age` file, **Download**. Save it in a new folder on your PC (for example `C:\Users\ramfr\restore-test`), not in a synced or shared folder.
2. **Check the file is the one the job made.** In GitHub, **Actions**, **backup**, the run of that date, open the step *Upload it to the private bucket* and read the `sha256 after upload` line (logs are kept for 90 days; for older files use the *Encrypt it* step's line). Compare it with the file you downloaded:

   ```powershell
   Get-FileHash -Algorithm SHA256 .\nitznutz-backup-2026-11-01.dump.age
   ```

   If they differ, do not open the file, and tell me: anyone who can write to the bucket could plant a file (the age public key is public, and `age` does not say who sent a file).
3. **Get `age`.** Download the Windows build from <https://github.com/FiloSottile/age/releases> (a zip with `age.exe`; no installer needed) and unzip it anywhere.
4. **Open it.** The private key is the file you saved in 1Password (`backup-age-key.txt`). Keep it outside the restore folder:

   ```powershell
   .\age.exe --decrypt -i C:\path\to\backup-age-key.txt -o nitznutz.dump nitznutz-backup-2026-11-01.dump.age
   ```

5. **Read it.** Use PostgreSQL 17's `pg_restore`; nothing is restored by this:

   ```powershell
   pg_restore --list nitznutz.dump
   ```

6. **Restore it into a scratch database only.** Use a new, empty database that you can throw away: a local PostgreSQL 17 on your PC, or a temporary Supabase project made just for this. Never the live project, and never a database that holds anything else.

   ```powershell
   createuser --no-superuser --no-createrole --no-createdb nitznutz_restore
   createdb --owner nitznutz_restore nitznutz_scratch
   pg_restore --username nitznutz_restore --no-owner --no-privileges --dbname nitznutz_scratch nitznutz.dump
   ```

   (`createuser` and `createdb` are run once as the PostgreSQL administrator; the restore itself runs as the ordinary user `nitznutz_restore`, never as `postgres`.)

   **CVE-2026-18408.** A dump made on a malicious server can run code on the machine that restores it (through the `\restrict` and `\unrestrict` lines of `psql`, when a plain-format script is produced or replayed). Our dump comes from our own project, and the step above restores straight into a database without a script, but treat the file as untrusted anyway: use a PostgreSQL 17 client that includes the fix (17.11 or newer; check with `pg_restore --version` and update first), never turn the dump into a plain `.sql` script (`pg_restore --file`) and pipe it to `psql`, restore as the ordinary user shown above, and do it on a PC where nothing else is at risk. The advisory is at <https://www.postgresql.org/support/security/CVE-2026-18408/>.

   Also, the app's devices keep their own copies, and a restore over the live project can make a server count backwards. If the live project must be repaired from a backup, ask for help first.
7. **Delete what you opened.** `nitznutz.dump` and the scratch database are not encrypted and hold children's nicknames: run `dropdb nitznutz_scratch` and `dropuser nitznutz_restore`, then delete the dump and the downloaded `.age` file.

## Older backups (GitHub artifacts, until 2026-11-08)

Backups made before the move are GitHub artifacts: on GitHub, **Actions**, **backup**, a run, artifact `nitznutz-backup` (a zip with the `.age` file inside); each expires 28 days after its run. Then continue from step 3 (there is no checksum line for artifacts; take them from the run's *Encrypt it* step). The weekly job no longer makes artifacts.
