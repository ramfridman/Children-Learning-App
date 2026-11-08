# Restoring a weekly backup

A backup is one file, `nitznutz-backup-YYYY-MM-DD.dump.age`: a PostgreSQL dump of the `app` schema (families, devices, children with their nicknames, school stages, answers, visits, alerts, settings), encrypted so that only the private key can open it. It sits in the private Storage bucket `nitznutz-backups` on the Supabase project. The weekly job deletes copies older than 27 days, so the last four weeks are there. (Before 2026-11-08 backups were GitHub artifacts; see the end.)

1. **Get the file.** Supabase dashboard, project `ungkvkabqxssggttajfs`, **Storage**, bucket `nitznutz-backups`, click the newest `.age` file, **Download**. Save it in a new folder on your PC (for example `C:\Users\ramfr\restore-test`), not in a synced or shared folder.
2. **Get `age`.** Download the Windows build from <https://github.com/FiloSottile/age/releases> (a zip with `age.exe`; no installer needed) and unzip it anywhere.
3. **Open it.** The private key is the file you saved in 1Password (`backup-age-key.txt`). Keep it outside the restore folder:

   ```powershell
   .\age.exe --decrypt -i C:\path\to\backup-age-key.txt -o nitznutz.dump nitznutz-backup-2026-11-01.dump.age
   ```

4. **Read it.** Use PostgreSQL 17's `pg_restore`; nothing is restored by this:

   ```powershell
   pg_restore --list nitznutz.dump
   ```

5. **Restore it into a scratch database only.** Use a new, empty database that you can throw away: a local PostgreSQL 17 on your PC, or a temporary Supabase project made just for this. Never the live project, and never a database that holds anything else.

   ```powershell
   createdb nitznutz_scratch
   pg_restore --no-owner --no-privileges --dbname nitznutz_scratch nitznutz.dump
   ```

   **CVE-2026-18408.** A dump made on a malicious server can run code on the machine that restores it (through the `\restrict` and `\unrestrict` lines of `psql`, when a plain-format script is produced or replayed). Our dump comes from our own project, and the step above restores straight into a database without a script, but treat the file as untrusted anyway: use a PostgreSQL 17 client that includes the fix (17.11 or newer; check with `pg_restore --version` and update first), never turn the dump into a plain `.sql` script (`pg_restore --file`) and pipe it to `psql`, restore as an ordinary user and not as a superuser, and do it on a PC where nothing else is at risk. The advisory is at <https://www.postgresql.org/support/security/CVE-2026-18408/>.

   Also, the app's devices keep their own copies, and a restore over the live project can make a server count backwards. If the live project must be repaired from a backup, ask for help first.
6. **Delete what you opened.** `nitznutz.dump` and the scratch database are not encrypted and hold children's nicknames: run `dropdb nitznutz_scratch`, then delete the dump and the downloaded `.age` file.

## Older backups (GitHub artifacts, until 2026-11-08)

Backups made before the move are GitHub artifacts: on GitHub, **Actions**, **backup**, a run, artifact `nitznutz-backup` (a zip with the `.age` file inside); each expires 28 days after its run. Then continue from step 2. The weekly job no longer makes artifacts.
