# QA verification: B-28 (a child's first name: one limit of 24 UTF-16 units on the phone and the server)

2026-10-30, qa-engineer. Worktree `D:\nitznutz-b28`, branch `b28-name-limit`, commit `942c91d` on `origin/main` `64afdfe`. QA ids are `QA-B28-n` because other branches use `QA-n` (the last on main in `docs/qa/` is QA-21).

**Verdict: PASS with three minor open defects, none blocks the merge.** All four acceptance criteria hold. The three defects (QA-B28-1, -2, -3) each have a failing test that is skipped in a normal run.

## What ran

| Command | Result |
|---|---|
| `dart format --output=none --set-exit-if-changed .` (in `app/`, at the end, with QA's file) | 0 changed, exit 0 |
| `flutter analyze` (in `app/`, at the end) | No issues found |
| `flutter test child_name sync_engine sync_wiring source_rules_m1 wire_format response_contract alerts_flow` | 92 passed, 0 failed |
| `flutter test app_flow golden_screens` | 46 passed, 0 failed (the stack trace printed in `app_flow` is the "debug builds" warning, not a failure) |
| `flutter test test/qa_b28_test.dart` | 16 passed, 4 skipped (the open defects) |
| `flutter test --dart-define=QA_OPEN=true test/qa_b28_test.dart` | 16 passed, 4 failed (QA-B28-1a, -1b, -2, -3), as intended |
| `deno test --frozen --allow-read=... supabase/functions/child_name_vectors_test.ts` (deno 2.9.6 from the old scratchpad `node_modules/.bin`) | 5 passed, 0 failed |
| `deno fmt --check`, `deno lint`, `deno check --frozen` on that file | all clean |
| Throwaway render test, 8 renders (form and parent list, phone 360x740 and tablet 800x1024, text scale 1.0 and 1.3) | 8 passed, no overflow in the form or the list; file deleted afterwards |

Not run: the whole `flutter test` suite (the brief named the touched and related files), the whole `deno task check`, `deno` DB integration tests (they need a database on 127.0.0.1:54322), the pgTAP checks, any real phone or real gateway. There is no `strings_test.dart`; the Hebrew strings rules are in `source_rules_m1_test.dart`, which passed.

## Criteria

| # | Criterion | Result | Evidence |
|---|---|---|---|
| 1 | A 25th character cannot be typed; a long paste is cut to 24; an emoji is never split; the counter counts UTF-16 units | PASS | `child_name_test.dart` (form: 25 letters typed gives 24 and "24/24"; emoji ending at unit 25 stays out whole; formatter unit tests). QA's `qa_b28_test.dart`: paste of two emoji at 20 to 23 units leaves 0, 1 or 2 whole emoji, never a lone half; selection replaced at the limit by a 30-letter paste gives 24; paste in the middle keeps 24 and the cursor inside; a 0 to 40 unit sweep of mixed text (Latin, Hebrew, nikud, emoji, spaces, brackets, U+200F) through `fitChildNameForServer` always gives a string the server's pattern takes, trimmed, with no lone surrogate. The counter is `_name.text.length`, so nikud counts 2 and an emoji 2 (picture `form_full_phone_13`: 12 letters with nikud show "24/24"). |
| 2 | Bad-characters note and disabled Save for `<`, `>`, U+200F, U+202E; nothing for spaces only | PASS | `child_name_test.dart` (form test over the four). QA: `'  <  '` and `' > '` give `badChars` and send nothing; a name over 24 that also holds `<` says `badChars`, not "too long". Spaces only (also NBSP and U+3000) is `empty`: no note, Save disabled. Picture `form_bad_phone_13`: red two-line note, Save greyed. |
| 3 | A child saved earlier with a 25 to 40 character name keeps the full name, shows the legacy line, syncs as 24, is not re-sent every round, and a second phone receives the 24-unit name | PASS | `sync_engine_test.dart` B-28 group and `child_name_test.dart` list test, plus QA: three rounds give one `child-put` and the whole name stays; a rename on another device (server nickname changed) while the phone holds the long name: the pull takes the server's value, and it is not pushed back; the long name changed on this phone after the cut: the new cut goes once, the phone keeps it whole, nothing more is sent; long changed to short: pushed and kept; two children with 30-letter names sharing the first 24 each keep their own name (one `child-put` each); 23 letters plus an emoji plus `bc`: server holds 23 units, phone whole, sent once; offline at first, then online: one cut, name whole; a second phone never pushes the cut name back. |
| 4 | The real gateway rule and the app agree | PASS, with the gaps listed as defects | Derived by hand, not from the vector file (below). |

### Independent derivation of the server rule

- `supabase/functions/child-put/handler.ts`: field `nickname` is `{t:"string", max:24, pattern:NICKNAME}`, `NICKNAME = /^[^\u0000-\u001f\u007f<>]{1,24}$/` with no `u` flag. `_shared/schema.ts` `checkField` tests `v.length > f.max` (UTF-16 units) and then the pattern. So the server counts UTF-16 units, refuses only C0, DEL, `<`, `>`, and does not trim.
- The migration `20261027120000_parent_sync.sql` has `check (char_length(nickname) between 1 and 24)`. `char_length` counts code points, never more than units, so anything the handler takes passes the check (the DB is never the stricter rule).
- I ran the handler's own `NICKNAME` in Deno on 14 adversarial strings (script in the scratchpad, not committed). Server verdicts: lone high or low surrogate takes; U+200B alone takes; `נו\u061Cעה` takes; NBSP or U+3000 at both ends takes (no trim on the server); U+FEFF, U+2028, U+0085 inside take; 24 letters plus NBSP (25 units) refuses; `'  <  '` refuses; 22 letters plus an emoji (24) takes; 23 letters plus an emoji (25) refuses. `JSON.parse` of a lone surrogate escape gives 3 units, and encoding it to UTF-8 gives U+FFFD. All of this agrees with the vector file and with what the app does, except where the app is stricter on purpose (C1, direction marks) and the three defects below.
- The Dart `trim()` removes NBSP, U+3000, U+FEFF and the line separators at the ends; the form saves `_name.text.trim()`, so the server never sees such ends from a new name. The raw field is capped at 24, so a name with a leading space has 24 raw units.
- `_pull` rule: the phone keeps its whole name only when `fitChildNameForServer(local) == server nickname`; any other server value wins. I checked the cases that could break this (rename elsewhere, cut again, two children with the same 24-unit prefix): none loses a rename. A rename elsewhere to exactly the cut text of this phone's long name would keep the long one: harmless, it is the same name as far as the server is concerned.

## Defects

| id | severity | owner of the fix | what | failing test |
|---|---|---|---|---|
| QA-B28-1 | minor | app-developer (security-engineer's B-32 item 1 covers the same set) | A name made only of characters that draw nothing is `ok`: U+200B, U+2060, U+2800, U+3164, U+00AD (Dart `trim()` does not remove them). The parent can save a child with a blank name, and it syncs. Also the Arabic letter mark U+061C, a direction mark like U+200F, is not refused although the library comment says the invisible direction marks are. | `qa_b28_test.dart` QA-B28-1a, QA-B28-1b |
| QA-B28-2 | minor | app-developer | A lone surrogate is `ok`. Dart sends it as a JSON escape, the gateway's pattern takes it, the database driver stores U+FFFD, and the next pull replaces the phone's name with the replacement character (`fit(local) != server`). Very unlikely input (a corrupt paste). | `qa_b28_test.dart` QA-B28-2 |
| QA-B28-3 | minor | design-director, then app-developer | In the parent list the name and the legacy line share the row with the "progress" and "remove" buttons. On a 360 pt phone the line gets a column 86 pt wide at text scale 1.0 (7 lines), and 65 pt at 1.3 (300 pt tall, words cut in the middle: "המשפח/ה", "הראשוני/ם"); a 40-unit name is cut into columns of 4 letters. Nothing overflows, but it is hard to read. On the 800 pt tablet it is one line. Only children saved before B-28 with 25 to 40 characters see it. | `qa_b28_test.dart` QA-B28-3 (`width >= 160`, gets 86.4) |

Run the open tests with `flutter test --no-pub --dart-define=QA_OPEN=true test/qa_b28_test.dart`. The owner of a fix removes `skip: _open` from its test when it is fixed.

### Notes that are not defects

- The security-engineer's board rows B-32 and B-33 (SEC-B28-1 to -7) already cover the stricter character set (zero-width, lone surrogates, a name with no visible character) and the gateway tightening; QA-B28-1 and -2 are the app-side tests for those.
- `<` and `>` are mirrored by the right-to-left text in the field and in the red note (`נו<עה` shows as `נו>עה`); the Hebrew notes say it is harmless when both are named.
- At text scale 1.3 the child's home and profile picker overflow (QA-19, `home_screen.dart:672`, `profile_picker.dart:124`, known and open). The render test drained that before reaching the parent area; the form and the list themselves had no overflow.
- The age chips on a 360 pt phone leave "8" alone on a second line; not from B-28.
- Two children with the same first 24 units look the same on the second phone (by design: that is all the server holds).
- The "too long" red error cannot be reached by typing (the formatter stops at 24); it only protects a programmatic set. Not a defect.
- The new Hebrew strings are not yet in `docs/review/hebrew-master.csv` by the orchestrator's instruction (export after the other lines merge). Wording is the hebrew-text-editor's; the open owner question is whether "חשבון המשפחה" is the right name.

## Pictures looked at

In the scratchpad `b28qa/png` (not committed): `form_full_phone_13`, `form_bad_phone_13`, `list_phone_13`, `listname_phone_13`, `list_phone_10`, `list_tablet_10`, `form_full_tablet_13`. The other renders (phone and tablet at 1.0, bad and full forms, list tablet 1.3) were produced and passed the no-overflow check but I did not open each PNG.

## Hand-offs

- to app-developer: make QA-B28-1a, -1b, -2 pass (one shared `safeChildName`, as security's B-32 item 1 says), then remove `skip: _open` from them in `app/test/qa_b28_test.dart`; vectors for the new refused characters go into `testvectors/child-name.json` (marked `appOnly`).
- to design-director then app-developer: QA-B28-3, give the legacy line the full row width (below the name, buttons on their own line or a Wrap), check at text scale 1.3 on a 360 pt phone.
- to orchestrator: `docs/agents/board.md` and `docs/security/findings.md` are modified in this worktree and are not from QA.
