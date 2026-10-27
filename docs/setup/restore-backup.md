# Restoring a weekly backup

A backup is one file, `nitznutz-backup-YYYY-MM-DD.dump.age`: a PostgreSQL dump of the `app` schema (families, devices, children with their nicknames, answers, visits, alerts, settings), encrypted so that only the private key can open it. The last four weeks are kept for 28 days.

1. **Get the file.** On GitHub, open the repository, **Actions**, **backup**, pick a run, and download the artifact `nitznutz-backup` (a zip with the `.age` file inside).
2. **Get `age`.** Download the Windows build from <https://github.com/FiloSottile/age/releases> (a zip with `age.exe`; no installer needed) and unzip it anywhere.
3. **Open it.** The private key is the file you saved in 1Password (`backup-age-key.txt`):

   ```powershell
   .\age.exe --decrypt -i C:\path\to\backup-age-key.txt -o nitznutz.dump nitznutz-backup-2026-11-01.dump.age
   ```

4. **Read it or restore it.** Use PostgreSQL 17's `pg_restore`:

   ```powershell
   pg_restore --list nitznutz.dump                                   # what is inside
   pg_restore --no-owner --dbname "<address of an empty database>" nitznutz.dump
   ```

   Restore into a new, empty database first and look at it. Never restore over the live project without asking for help: the app's devices keep their own copies, and a restore can make a server count backwards.
5. **Delete the opened dump** when you are done (`nitznutz.dump` is not encrypted).
