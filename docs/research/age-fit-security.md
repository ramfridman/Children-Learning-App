# Age-fit (B-29): the security and privacy design

Author: security-engineer, 2026-10-29. Status: PLAN-step review for the owner's decisions of 2026-10-29. Nothing here is built.
Read in worktree `D:\nitznutz-b26`: `tables.dart`, `app_database.dart`, `encrypted_storage.dart`, `child_form.dart`, `sync_engine.dart`, `core/log.dart`, `lesson_screen.dart`, `tutor/tutor.dart`, `child-put`, `sync-pull`, `tutor-turn`, `tutor-log`, `alert-create`, `device-pair`, `_shared/{schema,db,tutor_prompt}.ts`, the migrations `20261027120000_parent_sync.sql` and `20261029120000_prizes_and_ribbons.sql`, `backup.yml`, the Android manifest.

**The rule in one line:** month and year of birth live in one table on the device. The age in months and the presentation stage (P1 to P4) are computed from it in memory. Only `age_band` (0 to 2) and `school_stage` (a closed enum, set by the parent) ever leave the device.

## (a) Data model

| Value | Where | Type and control |
|---|---|---|
| Month and year of birth | Device only: a **new table** `ProfileBirths` (`profileId` text PK = `Profiles.id`; `birthYm` int, `YYYYMM`; `presentationOverride` int nullable: -1, 0 or +1; `lastStageShown` int nullable: 1 to 4). Local schema v9 to v10 | Check: `birthYm % 100 between 1 and 12`, year between the current year minus 10 and minus 2 (also checked in the form). Picked from closed lists (month, year), so there is no free text. It is inside the SQLCipher database (`encrypted_storage.dart`: a 256-bit key from `Random.secure()` kept only in Keystore secure storage; `applyKey` fails closed if there is no cipher; the file is in `noBackupFilesDir`; `allowBackup=false`). No extra field encryption is needed. |
| Why a separate table, not a column on `Profiles` | | `Profiles` is read by sync (`_pushProfiles`, the fingerprint), the child picker and the tutor context. Drift's generated `Profile.toString()` prints every column, so one stray `Log.d('$p')` would print a column kept there. Only one file (the age service) and the parent form read `ProfileBirths`, and a source-rule test pins that. |
| `schoolStage` | `Profiles` (local) and `app.child_profile.school_stage` (server) | Text, nullable, closed enum `gan3`, `gan4`, `gan5`, `grade1`, `grade2`, `grade3`. Set or confirmed only by the parent. **No school year is stored or synced.** In September a parent device shows a card proposing the next stage, and nothing changes until the parent confirms. |
| `ageBand` | As today | **Derived from `schoolStage`** when there is one (gan3 and gan4 give A, gan5 and grade1 give B, grade2 and grade3 give C), **never from the age in months** (see risk R2). |
| Age in months, presentation stage | Memory only | Computed from `birthYm` and the device clock at the start of a session. Never stored, never in an event, setting, alert, log or request. |
| Never stored anywhere | | The day of birth, a full date, the age as a number, the stage history, "turned N" markers. |

Per-child age data lives only in `ProfileBirths`, never in `AppSettings` keys like `stage_seen_<id>`. That way one delete removes all of it.

## (b) Where it could leak, and the control for each

| Path | Today | Control after the change |
|---|---|---|
| `child-put` body (`sync_engine.dart:224`) and the fingerprint (`:221`, `:578`) | Sends the nickname, avatar, companion, outfit, address form and band | Adds an optional `school_stage` and nothing else. The fingerprint adds `schoolStage` only. The gateway already refuses any key outside the shape (`schema.ts:110`, `unknown_field`). **Gap:** `test/support/fake_family_server.dart` accepts any key, so app tests would not notice an extra field. It must refuse unknown keys exactly like the gateway does. |
| `sync-pull` children (`sync-pull/handler.ts:45`, `db.ts:447`) | Sends the band | Adds `school_stage`. The app parses it against the closed enum and ignores any other value (a bad server must not write junk). |
| Timing of band or stage writes (`child_profile.updated_at`) | n/a | The band and stage change only by a parent action (setup, edit, or the September confirmation). They never change automatically on a birthday, because an automatic change would reveal the birth month through `updated_at` (R2). |
| Events (`_attemptEvent`, `_sessionEvent`, `_rewardEvent`) | `plan` is `lesson:<id>` or `session:A` (band) | No event, reward or plan string carries P1 to P4, the override, or the "growing up" scene. The scene writes no row that syncs. Pin `plan` to `^(lesson:[a-z0-9._-]+|session:[ABC])$` in an app test (the gateway pattern `[a-z0-9:._-]{0,80}` would let `session:p3` through). |
| `tutor-turn` and `_shared/tutor_prompt.ts` (the prompt goes to Anthropic) | `band` A/B/C (`handler.ts:43`), also in `tutor_log`, `tutor_cache` and the prompt (`band="A"`) | **`band` stays the only age value.** The curriculum's §5.1 row "presentation stage replaces band in tutor-turn" is **rejected**: the presentation stage must not reach a vendor. Word limits stay per band. No `school_stage` either (data minimisation, and it would split the cache). |
| ElevenLabs (lines with the child's name) | The name inside a line to be voiced | No voiced line mentions an age or "you are N now" (the growing-up scene uses fixed lines without a name and without an age). A rule for the hebrew-text-editor and the voice-and-sound-director. |
| Alerts and FCM push (`alert-create`) | Fixed categories, a fixed push phrase | No new category for a stage change or a "stepped back" guard. Those notices stay local in the parent area. |
| Logs (`core/log.dart`) | Pattern scrubber (tokens, keys, e-mails, 6-digit codes), debug only | A pattern cannot recognise "2019-07". The control is structural: `Log.d` never gets a `Profile`, a `ProfileBirth`, `birthYm`, an age or a stage (source-rule test), plus the canary test (f). |
| Crash reports | None (PLAN: an on-device error log that the parent can export, not built yet) | When it is built, it records codes only, never profile rows. The canary covers it. `firebase_crashlytics` and `analytics` stay banned (package rule). |
| Parent export (`data-export`, PLAN line 737, not built) | n/a | The server has nothing to export. A local report excludes `birthYm`, and the parent sees it on the profile screen. |
| Pairing (`pairing-code-create`, `device-pair`) | No profile fields (verified) | Unchanged. A paired device gets the stage through `sync-pull` and asks for the month and year itself. |
| Weekly `pg_dump` (`backup.yml`) and `tutor-log` | `child_profile` with the band; `tutor-log` has no band | The dump gains `school_stage` (the same class of data as the band). A schema-pin test keeps birth columns out of `app`. Deletion reaches the backups within 28 days, as today. |
| Device backup | Android: `allowBackup=false`, DB in `noBackupFilesDir` | **Before iOS:** `noBackupDir` has no iOS implementation yet (only `PlatformChannel.kt`). The iOS folder must have `isExcludedFromBackup`, otherwise the DB (now with the birth month) goes to iCloud. |
| Screenshots, goldens, fixtures, docs (the repo is public) | Goldens use test data | The parent area already uses `FLAG_SECURE` (`parent_session.dart:28`). Goldens and fixtures use **synthetic** values only. The children's real months and years never go into a file, commit message, board or PROGRESS. gitleaks cannot catch them, so the orchestrator checks diffs by eye. |
| Deletion | `deleteChildData` (`app_database.dart:383`); `app.delete_child` deletes the `child_profile` row | Local: `deleteChildData` also deletes the `ProfileBirths` row in the same transaction; "Forget this phone" already removes the key and the files. Server: the `school_stage` column goes with the row, and `delete_child` needs no change. Optional: `PRAGMA secure_delete=ON`, so deleted rows are not left in free pages (they are encrypted anyway). |

## (c) Server schema and validation (additive, gateway first)

1. Migration `2026103x_child_school_stage.sql`: `alter table app.child_profile add column school_stage text check (school_stage is null or school_stage in ('gan3','gan4','gan5','grade1','grade2','grade3'));`. Nullable, no default. No grant, RLS or policy change: the column inherits `app_gateway`'s table grants, and `anon` and `authenticated` still get nothing. `delete_child` is unchanged.
2. `child-put` shape: `school_stage: { t: "enum", values: [the six], optional: true }`. Absent means **keep the stored value** (`school_stage = coalesce(excluded.school_stage, app.child_profile.school_stage)`), so a parent phone still on app 0.5 cannot wipe it. A `null`, an empty string, an integer, `GAN3`, `grade4` or any other value gets `bad_request`. The same goes for `birth_ym`, `birth_month`, `age_months`, `presentation_stage` (`unknown_field`). There is no cross-check of band against stage on the server.
3. `ChildProfile.schoolStage` in `store.ts` and `db.ts` (parameterised `sql` template as today). `sync-pull` returns it.
4. **Order:** migration, then functions (deployed and tested), then the app. If the app ships first, `child-put` refuses `school_stage` and `_pushProfiles` swallows the error (`:233`), so **all** profile edits (the nickname too) stop syncing without any sign. Add a test: the app sends `school_stage` only when it has one.

## (d) Parent flow and defaults

- **Where:** the child's profile in the parent area only (behind the gate and `FLAG_SECURE`). It is never asked of or shown to the child, and the child picker shows no age. In the setup flow, the age chips in `child_form.dart` are replaced by a month picker, a year picker and the school stage, pre-filled from the year and editable. All of it is optional.
- **What the text must say** (the hebrew-text-editor words it; English intent):
  1. "Month and year of birth (optional), so the app fits the look and pace to the age. No day."
  2. "Kept only on this phone or tablet. Not sent to our server or to any company. Enter it on each device."
  3. "The school stage (gan or grade) is saved with the family so all your devices agree. Lessons still follow what the child knows."
  4. A "Remove" action that deletes the month and year. The presentation then falls back to the stage or the band.
  5. The September card: "A new school year: is [nickname] now in [next stage]?" with Yes and Not yet.
- **Existing band-only profiles:** nothing changes on update. `birthYm` and `schoolStage` stay null and are not inferred or pushed. The presentation defaults to the middle of the band (A gives P2, B gives P3, C gives P4). One calm card in the parent area offers to add them. If the band would go down, nothing changes without the parent's OK.
- **Consent:** entering the data after reading the notice is the consent. No consent row goes to the server, because it would carry nothing useful and would be one more write.

## (e) Proposed wording (not edited)

**PLAN.md line 1036, replace with:**
"- A child profile holds only a nickname, avatar, age band, school stage (gan or grade, confirmed by the parent) and grammatical gender. The month and year of birth (never the day) may be kept on the device only, in the encrypted database, to fit the presentation to the age. It is never synced, sent to any vendor, logged, exported or put in a backup. The age in months and the presentation stage are computed on the device and never stored or sent. No full date of birth, photo, school name or location."

**PLAN.md line 710 (M7b `child_profile`):** add "school stage (enum, optional, set by the parent)" after "age band".
**CLAUDE.md › Child safety, add one bullet:** "A child's month and year of birth (never the day) stay on the device: never synced, logged, sent to a vendor or exported. Only the age band and the school stage enum go to the server, and neither changes on a birthday."

## (f) Tests for QA (regression set)

1. **Canary (app, end to end on the harness):** a profile with a distinctive synthetic birth (for example 2019-07). Run setup, a session that crosses a stage boundary (the clock moved across 5;0), mistakes with the tutor on, a reward, an alert, settings-put, a pairing code, the September confirmation, sync, and delete. Record every outgoing request (URL, headers, body), every `Log.d` line and every `AppSettings` row. Assert that none contains `201907`, `2019-07`, `07/2019`, `7/2019` or a key matching `/birth|dob|age_?month|presentation|p[1-4]\b|override/i`. Then assert that `ProfileBirths` has no row for the deleted child.
2. **Payload shape pins:** `child-put` keys are exactly `{child_id, nickname, avatar_id, address_form, age_band}` plus the optional `{companion_id, outfit_id, school_stage}`. `Tutor.toJson` and the `tutor-turn` shape are pinned with `band` as the only age key. The event `data` keys are pinned for each type. The `plan` pattern from (b). The fake server refuses unknown keys.
3. **Gateway (Deno):** `child-put` accepts each of the six stages. It refuses `null`, `""`, `3`, `GAN3` and `grade4` (`bad_request`), and refuses `birth_ym` and `age_months` (`unknown_field`). Absent keeps the stored stage (DB integration). `sync-pull` returns it. After `delete_child` there is no row.
4. **Schema pin (DB integration):** the columns of `app.child_profile` are pinned exactly, and no column in schema `app` matches `/birth|dob|age_month|presentation/`.
5. **Local:** migration v9 to v10 keeps the profiles and adds no birth data. `deleteChildData` and `wipeLocalData` remove `ProfileBirths`. The band is derived from the stage, never from months. A source rule says only `age_service.dart` and the parent form reference `profileBirths`, and no `Log.d` argument mentions birth, age or stage.

## (g) Risks, rated

| Id | Risk | Rating and why | Control |
|---|---|---|---|
| R1 | A later change adds the birth to `child-put`, an event or the tutor | High impact, low likelihood after the controls | `unknown_field` at the gateway, the shape pins, the canary, the schema pin |
| R2 | The birth month is inferred from **when** the band or stage changes on the server | Medium: it would rebuild exactly what the owner kept off the server | Band from stage; changes only by a parent action; no auto-step at birthdays |
| R3 | The month is inferred from behaviour (items per activity and session length change at 5;0 and 6;6, visible in events) | Low: needs DB access and analysis, and gives ±1 month at best | Accept (needs the owner); keep counts out of the plan strings |
| R4 | Quasi-identifiers on the server: nickname + address form + school stage + band + family | Low to medium: the stage narrows the band (2 years) to one school cohort, while month and year (which, with a first name and gender, nearly identify a child) are never there | Only the stage and band go up; a Frankfurt DB; backups encrypted with `age` |
| R5 | Real ages in the public repo (goldens, fixtures, docs) | Medium while the repo is public | Synthetic values only; ages given in the session only; review of diffs |
| R6 | Age said to ElevenLabs next to the name | Low | No voiced line carries an age |
| R7 | The DB goes to iCloud on iOS | Medium, iOS only | `isExcludedFromBackup` before any iOS build carries B-29 |
| R8 | Deleted rows left in free pages of the SQLite file | Low (the file is encrypted) | `secure_delete` optional |

Advisories: no new package, so there is no version-specific advisory to check. Read: OWASP MASVS v2.1.0, MASVS-PRIVACY-1 (data minimisation) and -2 (prevent identification), https://mas.owasp.org/MASVS/controls/MASVS-PRIVACY-1/, release of 2024-01-18, read on 2026-10-29. Verified in the code: everything in tables (a) and (b) marked as today. Not verified: iOS behaviour (there is no iOS channel yet).
