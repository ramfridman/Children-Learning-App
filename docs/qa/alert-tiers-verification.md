# QA verification: word alerts in three tiers (branch `alerts-tiers`)

**qa-engineer, 2026-10-30.** Worktree `D:\nitznutz-alerts`, branch `alerts-tiers` from `origin/main` (46bab79), uncommitted.
Read against `docs/child-safety/alert-test-list.md` (the test list), `alert-word-lists-proposed.md` (tiers, C-1 to C-5,
age table), `alert-word-lists-review.md`, `hebrew-validation.md` (final lists and parent texts, owner's answers of
2026-10-29), and `docs/PLAN.md` › Alerts. QA's own tests: `app/test/qa_alert_tiers_test.dart`.

**Verdict after the final pass (section F, below): ready to commit; no open defect that blocks it.** The text after this
line is the second pass, kept as the record (QA-45 and QA-47 in it are now fixed; `QA_OPEN` in it is stale).

**Verdict after the second pass (section 0): ready to commit, with one open major defect (QA-45)** that the owner
may accept for the commit or have fixed first: a phone whose clock runs more than 2 minutes fast can lose an act for
the rest of that app version. Every first-pass defect (QA-34 to QA-44) is fixed and its test passes; the security
proofs SEC-25 to SEC-29 hold on the phone and the gateway; nothing on the alerts screen overflows. E4.6 (the dates on a
"repeated" act) stays open as briefed. Section 1 onwards is the first pass, kept as the record.

## F. Final pass (2026-10-30, after the renumbering, SEC-26, SEC-30, SEC-33)

| Command | Result |
|---|---|
| `flutter test`, whole suite (`app/`, developer's state plus QA's file as it was) | **+1565 ~8, 0 failed** ("All tests passed!"; the 8 skipped are the older QA-13, 14, 17, 18 and QA-19 x4, none an alert test) |
| `flutter test test/qa_alert_tiers_test.dart` (QA added 4 tests: 3 for SEC-30 call counts, 1 for the floor's own budget) | **+119, 0 skipped, 0 failed** |
| `flutter test --dart-define=QA_OPEN=true test/qa_alert_tiers_test.dart` | +118 (before the 4 new tests), 0 failed: the flag is no longer read by this file, the run is the same as a normal one. **The `QA_OPEN` text in sections 0.4, 0.5 and 5 is stale** |
| The six alert test files together (alert_safety, sync_engine, alerts_flow, alerts, alert_words, word_alert_text) after the last edit | +318, 0 failed |
| `flutter analyze`; `dart format --output=none --set-exit-if-changed .` | No issues; 284 files, 0 changed (after `dart format` on QA's file) |
| `deno fmt --check`, `deno lint` (supabase/functions), `deno task check` (Deno 2.9.6) | all exit 0; **188 passed, 0 failed, 7 ignored** |
| `db_integration_test.ts` (7) and pgTAP 08, 09 | **not run here** (no database); CI runs them |

The whole suite was started before QA's 4 new tests were written, so it does not include them; they were run on their own
(+119 in the file) and with the other alert files. The suite was not run a second time.

- **Renumbering:** no `SEC-17` to `SEC-24` and no `QA-22` to `QA-33` left anywhere in the repo except the explanatory note in
  `docs/security/findings.md` (lines 143 and 144). `main` has no SEC-17..24 either, so no id means two things here. QA-34 to
  QA-47 and SEC-25 to SEC-33 each point to one thing; QA-36 and QA-37 are each used by two tests of the same defect (the
  original and "in full" / "the other order"); no test name is repeated (the runner would have shown it twice).
- **SEC-30 (a bounded `_sendAlert`):** a gateway that always answers `bad_request`, a phone 10 minutes fast, 3 alerts
  (with words, without, with words), 3 sync rounds. Clock never changes: 5 calls (2, 1, 2), the second without words,
  nothing in rounds 2 and 3. Skew learned after the first call: the second call has the words and the corrected time, no
  third, 5 calls, the alert kept aside. A clock that moves on every call: 6 calls (2 each). Mutation (a third call without
  words added): killed by QA's test, `sync_engine_test.dart` (2 tests) and `alert_safety_test.dart`.
- **SEC-26 (floor first, own budget):** mutation "floor last, as before": killed by QA-47 (1 failure in the three alert
  files). Mutation "floor without its own budget" **survived** the existing tests, so QA added one (a heavy list burns its
  budget on hypothesis 1, the act is in hypothesis 2); it passes now and fails with that mutation.
- **SEC-33 (no selection on the child's words):** mutation "plain Text, no `SelectionContainer.disabled`": killed by the
  `SEC-33` test in `alerts_flow_test.dart` (a select-all and copy reaches the clipboard with the help numbers and without the
  words). Every line that quotes the words carries `hasWords` (heard, repeated-heard, note); read in `word_alert_text.dart`.
- **QA-46:** the code now sets every line as plain text on one edge; the golden `alerts_view.png` was opened: lines and
  bullets sit on the same edge, bullets hang, nothing cut. No test of its own for QA-46.
- Every product file was restored from a byte copy after each mutation (`git diff --stat`: 37 files changed, 3835
  insertions, 361 deletions, the same before and after; `git status --short`: 50 entries).

**The SEC-30 trade-off, judged.** Acceptable, but say it out loud. What is lost: one alert, that is kept aside until the
next app version, **with no push and no card for the parents** (the child's words never reach them). It needs both: (1) the
phone's clock moved while the first call was made (it learned the server's time, so a phone with a wrong clock and nothing
learned yet in that run), and (2) the gateway refused both calls with `bad_request`. With the deployed gateway
(it stores the server's time instead of refusing an `at` ahead, and the words are cleaned to its pattern first) neither
call has a reason to be refused, so the pair is a second, unrelated fault (a category the gateway does not know, i.e. an old
gateway). The only case that stays hard is "the words were the problem and the clock also moved", where the old rule
would have saved the alert without words. For a first-tier act this is the worst outcome (a parent not told), so QA's view:
accept it for the commit, because the alternative was an unbounded retry loop, and keep the deploy order (migration and
gateway first, then the app) as the protection. A cheap improvement for later (app-developer): keep such an alert aside
only until the next app start, not the next version.

**Open defects:** none that blocks. QA-46 fixed in code (not proven by a test). E4.6 (dates on a "repeated" act) as briefed.
`alertHeardTimes` is still a draft not approved by the owner. Gaps: M7b, D4, the SQL and pgTAP only in CI.

## 0. Second pass after the fixes (2026-10-30)

The app-developer fixed QA-34 to QA-44 and SEC-25 to SEC-29 (uncommitted, same worktree). The owner decided: SEC-28
"keep the words" off wipes everywhere; the three drafts (C-5 "often", the secret note, the self-hit note) approved;
alone at home stays tier 1 in band B (O-1 closed).

### 0.1 What ran

| Command | Result |
|---|---|
| `flutter analyze` (app/) | No issues found |
| `dart format --output=none --set-exit-if-changed .` | 284 files, 0 changed |
| `flutter test`, whole suite, developer's state | **+1547 ~8, 0 failed** |
| `flutter test test/qa_alert_tiers_test.dart` (QA's file, 7 tests added) | **+112 ~1, 0 failed** (the 1 skipped is QA-45, open) |
| `flutter test`, whole suite with QA's final file (after the mutation runs), with analyze and format again | **+1553 ~9, 0 failed**; no issues; 284 files, 0 changed |
| `deno task check` (fmt, lint, type check, tests; Deno 2.9.6) | **186 passed, 0 failed, 7 ignored** (the 7 need Postgres: CI) |
| pgTAP `08`, `09` and migration `20261030130000_alert_words_retention.sql` | read, not run (no local database) |

The developer edited QA's file to drop `skip: _open` from QA-34 to QA-42 now that they pass. QA compared those tests
with the first pass: no assertion was changed or weakened. QA added `_open` back for QA-45 only.

**Migration and pgTAP 09, read:** the words check (`not valid`, so old rows are not re-read; new rows and updates are
checked) uses the gateway's class; `revoke update` then `grant update (count, read_at, words)` covers the upsert, the
read mark and the keep-words wipe, and nothing else; `purge_expired` is the parent-sync body unchanged except the alert
line (`least(client_at, created_at)`); pgTAP 09 tests the character check (an angle bracket, U+202E), the column
privileges, and the purge of a far-future and an old row. pgTAP 08 unchanged.

### 0.2 First-pass defects: re-checked

| Id | Status | Proof |
|---|---|---|
| QA-34 | **closed**: `בגלל` no longer cancels W-31 | `QA-34` test; mutation M8 killed |
| QA-35 | **closed**: the maqaf is a space | `QA-35` test |
| QA-36 | **closed** (with SEC-25): words cleaned once to the gateway's pattern and 200 characters; a refused alert is retried without words, then kept aside, and never holds up the next | QA's stronger test: a long answer with `3:30`, `50%` and brackets arrives cleaned and the death wish after it arrives in the same round; N1, N2, N3 killed |
| QA-37 | **closed**: W-47 is a weekly note (`SECRET`), and C-2 pairs a later harm with it within 24 hours; after 25 hours it does not | `QA-37` and QA's new test; N9, N15, M11 killed |
| QA-38 | **closed**: B31 is W-42 / ONLINE | `QA-38` test |
| QA-39 | **closed**: `ויש לי`, `הייתה לי`, `היה לי` | `QA-39` test; M18 killed |
| QA-40 | **closed**: `מרוב` is an idiom word | `QA-40` test; M8 killed |
| QA-41 | **closed**: `Str.fill` is one pass | `QA-41` test; N8 killed |
| QA-42 | **closed**: the category decides the tier; a detail of another tier lends no subcategory or flags | `QA-42` and QA's new test; N7 killed (by QA's new test only) |
| QA-43 | **closed**: the fake server reads `alert_create` from `wire-patterns.json` and counts only word alerts again | read |
| QA-44 | **closed**: bullets hang; an act or a check says how many times it was heard; alerts first, settings card below | renders (0.6); new QA-46 |

### 0.3 Security proofs (private review, read-only)

| Finding | Proof re-checked | Result |
|---|---|---|
| SEC-25 (a) a character the model writes (`%`) | `alert_safety_test` (every BMP character, every character of the model's `tokens.txt`, fixture hash checked against `model_spec.dart`); QA-36 | holds |
| SEC-25 (b) a category the gateway lacks | `alert_safety_test` (b): kept aside, the act after it arrives, sent again by the next version | holds |
| SEC-25 fix 4: `alert_create` in `wire-patterns.json` | Deno test holds the gateway equal to it; the fake server and `alert_safety_test` read it | holds |
| SEC-26 bad version, sub, id; the 14-second list; wrong types; an older or emptier list | `alert_safety_test` SEC-26; the token cap (120 from each end) | holds; N10, N11, N12 killed |
| SEC-27 20 pushes a day per family, collapse key, PLAN | Deno tests; PLAN's `alert-create` row now says the same | holds; D6, D7 killed |
| SEC-28 (a) keep-words off empties server, other phones, child phone | `alert_safety_test`; Deno "empties them everywhere"; `putSettings` in one transaction (read) | holds |
| SEC-28 (b) purge by the earlier time; `at` at most 2 minutes ahead | pgTAP 09 (read); Deno test; D5 killed | holds, **but see QA-45** |
| SEC-28 (c) tidy after every sync, at app start, in the parent area | N5, N13, N14 killed | holds |
| SEC-28 (d) no words pulled when this phone does not keep them | N6 killed | holds |
| SEC-29 DB check, column grant, tier from category | migration and pgTAP 09 (read); N7 | holds |

### 0.4 New defects

| Id | Severity | Title | Owner of the fix | Proof |
|---|---|---|---|---|
| QA-45 | **major** | a phone whose clock runs more than 2 minutes fast loses its act for the rest of that app version | app-developer; security-engineer reviews | `QA-45` test (fails with `--dart-define=QA_OPEN=true`) |
| QA-46 | minor | lines that can be selected (any line with a digit: 118, 1201, "heard 3 times", a note's count) sit about 5 pixels off the other lines | design-director (app-developer for code) | renders `t1_phone_13_full`, `rep_tabletLandscape_13_full`; the golden `alerts_view.png` |

**QA-45.**
- **Where:** `app/lib/sync/sync_engine.dart` `_sendAlert`, with `app/lib/net/gateway_client.dart`. `at` is
  `min(alert time, serverNowMs())`, computed once before the call; `serverNowMs()` is the phone's clock plus the skew
  learned from a `clock_skew` answer, 0 until the first such answer in this run of the app.
- **Steps (QA's test: the real `GatewayClient` over a server that checks the signed time ±60 s and `at` ≤ now + 2 min):**
  the phone's clock is 10 minutes fast; the child says `מכים אותי`; `alert-create` is the first signed call of the run
  (a child phone with no new events, after a restart).
- **Expected:** the act reaches the parents (the brief: "a phone minutes ahead must not lose acts").
- **Actual (trace):** `alert-create@+10 min` → `clock_skew` → the client learns the skew and resends **the same body**
  (`at` still 10 minutes ahead) → `bad_request` (`at_ahead`) → `_sendAlert` tries without words, same `at` →
  `bad_request` → kept aside ("sync: an alert refused by the server, kept aside"). The next round does not try it: it
  waits for the next app version.
- **Fix idea:** work out `at` again on each try (after a `clock_skew`), or let the server clamp `at` to its now instead
  of refusing it; never keep an alert aside for `at_ahead`.

### 0.5 Mutation re-run

`qa_mutate3.ps1` (QA scratchpad): 32 device mutations against the alert test files (a name in the list,
`strings_test.dart`, does not exist and fails to load in every run: subtracted), then `qa_mutate4.ps1` for the three
survivors and M16's new pattern; `qa_mutate_deno.ps1` for 7 gateway mutations. Every product file restored from a byte
copy (`git diff --stat` the same before and after).

- **Killed:** M1–M7, M8, M9, M10, M11, M12, M15, M16, M17, M18; N1–N6 (SEC-25, SEC-28), N7 (QA's new test), N8, N9,
  N10–N12 (SEC-26), N13, N14 (QA's new test), N15; gateway D1 quiet push, D2 words on any alert, D3 words kept when the
  family does not keep them, D5 a time far ahead, D6 no push cap, D7 no collapse key.
- **Survived:**
  - **M7b**, the lesson screen dropping the answers on screen: no starter activity has a listed word as its answer.
  - **D4**, `alert-list` sending words when the family does not keep them: `settings-put` already emptied them and
    `alert-create` drops them, so no test reaches this third layer. Minor gap: a Deno test with a row that still holds
    words while the rules say off (app-developer).
  - The SQL of `putSettings` and the upsert in `_shared/db.ts`: only CI's integration test reaches them.

### 0.6 Renders with the new order

32 runs again (an act with `often` and count 3, "repeated", a check with count 2, four notes: swearing with Latin words
and a Latin name, adult world, the secret note, the self-hit note; phone 852×393, small phone 667×375, tablet portrait
and landscape; text 1.0 and 1.3), 64 PNGs in the QA scratchpad `qa_render2/`. **No overflow.** Looked at
`t1_phone_13_view` (the act now opens the screen), `t1_phone_13_full`, `t3_phoneSE_13_full`,
`rep_tabletLandscape_13_full`, and the golden `alerts_view.png`. Bullets hang, the count and the C-5 sentence show,
notes read as notes, numbers read left to right. New: QA-46.

### 0.7 Still open

- **QA-45** (major), **QA-46** (minor).
- **E4.6:** the "repeated" act shows no dates (as briefed; QA's test records today's behaviour).
- **`alertHeardTimes`** (`זה נשמע {n} פעמים בתוך חצי שעה.`) is a draft only: `he.dart` says "new, for the editor", the
  review CSV has it as `needs-editor`; `docs/child-safety/hebrew-validation-app.md` §6.1 has the editor's language check
  ("Correct Hebrew", `פעמיים` for 2 optional). Not approved by the owner.
- **Gaps:** M7b, D4; the SQL and pgTAP 08/09 run only in CI.
- **Deploy order** (the migration's header and SEC-25): migration, then `alert-create`, `alert-list`, `settings-put`,
  then the app.
- First-pass observations O-2, O-4, O-6, O-7, O-9 stand; O-1 (owner decided), O-3 (C-5 shown), O-5 (order set) and
  O-11 (PLAN updated) are closed.

## 1. What ran

| Command | Where | Result |
|---|---|---|
| `flutter analyze` | `app/` | No issues found |
| `dart format --output=none --set-exit-if-changed .` | `app/` | 282 files, 0 changed (exit 0); after QA's file: 283, 0 changed |
| `flutter test` (whole suite, developer's state) | `app/` | **+1419 ~8, 0 failed** ("All tests passed!") |
| `flutter test test/qa_alert_tiers_test.dart` | `app/` | **+97 ~9, 0 failed** (the 9 skipped are QA's open defects) |
| `flutter test --dart-define=QA_OPEN=true test/qa_alert_tiers_test.dart` | `app/` | -9: each open defect fails as reported (proof) |
| `flutter test` (whole suite with QA's file, after the mutation run) | `app/` | **+1516 ~17, 0 failed** |
| `flutter analyze`, `dart format` again with QA's file | `app/` | No issues; 283 files, 0 changed |
| `deno task check` (fmt, lint, type check, tests) | repo root, Deno 2.9.6 from the scratchpad | **182 passed, 0 failed, 7 ignored** |
| pgTAP `supabase/tests/database/08_word_alert_tiers.test.sql` | read only | **not run**: no local database (see section 7) |

The 7 ignored Deno tests are the `db_integration_test.ts` suites that need the local Postgres on 127.0.0.1:54322
(`alerts, push tokens, settings and the tutor log against the real tables` among them). So **the new SQL in
`_shared/db.ts` (`on conflict … do update set count … returning (xmax = 0)`) has not run anywhere yet**; CI runs it
(`ci.yml`: `supabase start`, `supabase test db`, the integration tests).

## 2. The test list, row by row

Every row of `alert-test-list.md` maps to a test. "dev" is the developer's file, "QA" is `qa_alert_tiers_test.dart`.

| Rows | Where | Note |
|---|---|---|
| A1–A42 (42) | dev `alert_words_test.dart` › A (A24, A25 in their own test) | all pass with the listed rule |
| B1–B37 (37) | dev › B | B31 passes as tier 2 but as **W-24 (FEAR)**, not W-42 (ONLINE): QA-38 |
| C1–C19 (19) | dev › C | C18 (W-47) matches at tier 3 but is never saved (section 6) |
| D1 (7) | dev › D (6 words) and "an empty answer" | |
| D2.1–D2.14 | dev › D, "D2.13–14" | QA adds niqqud and two-word answers on screen, `ז` itself, `זין זין`, `האות זין` |
| D3.1–D3.23 | dev › D (D3.19 at age 3) | |
| D4.1–D4.23 | dev › D | |
| D5.1–D5.13 | dev › D | |
| E1.1–E1.6 | dev › E1 | QA adds the Hebrew geresh U+05F3 (`צ׳אט`, `ביץ׳`), three yods, RLM, tabs |
| E2.1–E2.6 | dev › E2 | QA adds "me" first with a filler, the window's far edge, `וש`, adult prefixes |
| E3.1–E3.7 | dev › E3 | QA adds an act in hypothesis 2 beating a check in 1, a check and a secret only in single lower hypotheses |
| E4.1–E4.9 | dev `alerts_test.dart` › words | E4.1/E4.3 "push" is the server's (`alerts_test.ts`); E4.6 "showing the dates" is **not built** (minor, section 6) |
| E5.1 | dev (tier) and QA (band A saves the note) | the row's "no digest at 3–4" was overruled by the owner (swearing in the digest at every age) |
| E5.2–E5.5 | dev › E5; QA › ages, band A against C for 14 rows | |
| E6.1–E6.5 | dev `alerts_test.dart` (E6), `word_alert_text_test.dart` | |
| E7.1–E7.4 | dev › D, the lists, E3 | E7.2 with ordinary words only; QA adds three hostile mixes (section 4) |
| F (changes to old tests) | dev `alerts_test.dart` | done as listed |

**Rows not covered:** none. **Rows covered but not met:** B31's rule (QA-38), E4.6's dates (not built), and C18/W-47's
"T2 if combined" (QA-37).

## 3. QA's own cases (`app/test/qa_alert_tiers_test.dart`)

- **Matcher, 26 positive and 34 negative cases** the developer did not try: word order with a filler, the window's far
  edge, the prefixes `וש`/`ו` on verbs and `ו`/`שה`/`ה`/`מה` on adults, feminine plural and singular, `שם לי אצבע`,
  `לפיפי`, three yods, `מזויין`, the Hebrew geresh, ASCII apostrophe, upper-case Latin with a Hebrew phrase, RLM and
  tabs instead of spaces; nothing for half a phrase, the child as hitter (three forms), idioms with `מרעב`/`מהבושה`,
  "I don't want to die", surprises with a prefix, emoji, a lone RLM, gershayim, `שיט`.
- **Hypotheses:** an act in a lower one beats a check in the best one and its own text is kept; five hypotheses; a
  note or a check only in one lower hypothesis is nothing; a swear only in a lower hypothesis is not passed on with an
  act; the same swear five times in one answer is one count.
- **Ages:** 14 rows, band A against band C; a band outside 0–2 is clamped.
- **Long answers:** a phrase at the start or end of 2,000 tokens is found.
- **Cool-down:** the 29/30/31-minute edge, two children, two answers at the same moment (one alert, count 2), the
  Saturday-midnight edge of the weekly note, band A swear saved and band A self-hitting not saved, a restart of the
  app (the same database file opened again: counts 2 and 2); C-2 across answers raising a check to an act on its own
  (after C-1 was used that week); the child as hitter with "me" further on (both added after the mutation run).
- **What is stored:** only the matching hypothesis, `detail` `1:PHYS:W-01:<version>:often`, key `words:p-1:<ms>`, no
  event logged; with "keep the words" off no Hebrew anywhere in the row.
- **Two phones:** one episode across a child phone and a parent phone (no second alert, server count 2, no second
  push); the count only goes up on a phone (7, then a remote 2 keeps 7); a replay after a lost answer (one alert,
  `duplicate`, nothing left unsent); exactly the described fields are sent, words only when kept, `detail` and key
  valid for the server's patterns.
- **Parent texts as rendered:** 11 kinds × kept/not kept × counts 0/1/2/31 × a Latin and a Hebrew name: no placeholder
  left, no prefix on the name, no 100 or 101, every number of three or more digits wrapped in U+2066…U+2069, no
  protection claim, no empty quotes; "once" for 0 and 1; ten odd or hostile `detail` strings on every word category
  never break the card; the secrets add-on is not doubled.
- **Wiring:** the voice controller hands on the answers on screen (the letter name `זין` is then not a swear); in the
  real lesson a band A child saying `הוא הוריד לי את המכנסיים` saves nothing, band B saves a check, and band C `אני לבד
  בבית` is a check (W-25).

## 4. Speed

`checkWords` on one hypothesis of 1,000 tokens, after a warm-up, on this Windows desktop in the test runner (JIT):

| Input | 1 × 1,000 tokens | 5 × 1,000 tokens |
|---|---|---|
| developer's mix (`פרפר אדום`) | 5.8 ms | – |
| QA hostile mix 1 (strangers, contact, ask, touch, prefixed adults) | 12.3 ms | 47.1 ms |
| QA hostile mix 2 (negations, `אני`, fillers, plural verbs) | 8.8 ms | 36.5 ms |
| QA hostile mix 3 (adults with prefixes, body, secret game) | 6.2 ms | 35.0 ms |

E7.2 asks for under 10 ms on a phone. The worst hostile mix is 12 ms here; a real answer is capped at 8 seconds of
speech (a few dozen tokens), so this is not a defect, but the 10 ms target is not proven for adversarial text. The
phone was not measured (not plugged in).

## 5. Defects

Each has a failing test in `qa_alert_tiers_test.dart` that runs with `--dart-define=QA_OPEN=true` (it fails today;
the owner of the fix removes `skip: _open` when it passes), except QA-43 (read).

| Id | Severity | Title | Owner of the fix | Proof |
|---|---|---|---|---|
| QA-34 | major | "I don't want to live because…" is missed (tier 1 self-harm) | app-developer (list data); curriculum-expert confirms | `QA-34` test |
| QA-35 | minor | `normalizeHebrew` deletes the maqaf instead of making it a space | app-developer | `QA-35` test |
| QA-36 | major | one alert the server refuses blocks every later alert, acts included, for ever | app-developer; security-engineer reviews (sync) | `QA-36` test |
| QA-37 | major | C-2 works one way only: "don't tell mum" (W-47) then a harm is not an act | app-developer, after the owner's decision | `QA-37` test |
| QA-38 | minor | B31 online bullying is matched as W-24 (FEAR), not W-42 (ONLINE) | app-developer; curriculum-expert | `QA-38` test |
| QA-39 | minor | "I have / had a bruise" (`ויש לי מכה`, `הייתה לי מכה`) is a check; two in a week are a pushed act | curriculum-expert (guard words), app-developer | `QA-39` test |
| QA-40 | major | the idiom with `מרוב` is not guarded: `אני רוצה למות מרוב צחוק` is a pushed act | curriculum-expert, hebrew-text-editor (idiom list); app-developer | `QA-40` test |
| QA-41 | minor | `Str.fill` fills placeholders inside the child's words or name | app-developer | `QA-41` test |
| QA-42 | minor | a `detail` that contradicts the category decides the card (a quiet note shown as an act); the server checks neither | app-developer; security-engineer | `QA-42` test |
| QA-43 | minor | the fake family server raises the count of any alert; the real one only of word alerts | app-developer (test support) | reading `test/support/fake_family_server.dart` against `_shared/db.ts` |
| QA-44 | minor | alerts screen polish: bullets wrap under the bullet; the act and the check never show their count; on the phone the settings card fills the first screen | design-director (app-developer for code) | renders in section 9 |

### QA-34 (major): "I don't want to live because of it" is missed
- **Where:** `app/lib/speech/alert_lists.dart`, set `LIVE_WHERE` (`'ב*'`), rule W-31 tier 1 (`after: @LIVE_WHERE|@IDIOM`).
- **Steps:** `checkWords(['אני לא רוצה לחיות בגלל זה'])`; `checkWords(['לא רוצה לחיות בגלל שכולם צוחקים עלי'])`.
- **Expected:** tier 1, W-31. Proposal W-31: only "a place or person follows" (`בעיר / בבית הזה / בישראל / איתו`)
  cancels the act.
- **Actual:** nothing. The stem `ב*` takes every word that starts with ב as a place: `בגלל` (because), and also
  `בעולם הזה` ("in this world", a death wish) and `בלי אמא` (without mum).
- **Fix idea:** list the places (`בעיר`, `בבית`, `בדירה`, `בישראל`, `בארץ`, …) instead of `ב*`; the curriculum-expert
  decides `בעולם הזה` and `בלי`.

### QA-35 (minor): the maqaf is deleted, not turned into a space
- **Where:** `app/lib/speech/hebrew_text.dart` `normalizeHebrew`: the niqqud range `[֑-ׇ]` (U+0591–U+05C7) contains the
  maqaf U+05BE, so it is removed before `.replaceAll('־', ' ')` runs.
- **Expected:** `normalizeHebrew('בן־זונה') == 'בנ זונה'` (its own comment: "turns the maqaf into a space").
- **Actual:** `'בנזונה'`; `מכים־אותי` is one token, nothing matches. Also affects the answer matcher (shared helper).
  Low likelihood from the recogniser, so minor.

### QA-36 (major): one refused alert blocks the alert sync for ever
- **Where:** `app/lib/sync/sync_engine.dart` `_pushAlerts` with `alert-create`'s shape (`words` at most 200
  characters, pattern `^[֐-׿A-Za-z0-9 .,?!'"-]*$`; `detail` 80).
- **Steps:** a child says a worrying phrase inside a long answer (more than 200 characters, or with any other character
  the recogniser may write); then says `אני רוצה למות`; the phone syncs twice.
- **Expected:** the death wish reaches the parents (PLAN › Alerts; the act is the only push). The refused one is
  dealt with (cut to the limits, or marked refused like a refused event in `_pushEvents`).
- **Actual:** the server answers `bad_request`, `call` throws, the loop stops, nothing is marked sent. `unsyncedAlerts`
  is ordered by id, so the refused alert is first again on every sync and **no later alert is ever sent**. The words
  are now the matching hypothesis (not cut), and a counted alert is sent again, so this path is more likely than before.

### QA-37 (major): C-2 one way only
- **Where:** `app/lib/parent/alerts.dart` `planWordAlert`: a tier 3 row that is not SWEAR or EXPOSE returns no step, so
  W-47 is never saved and a later harm cannot pair with it.
- **Steps:** `אל תספר לאמא`, then 2 hours later `הוא מרביץ לי`.
- **Expected:** an act (rule C-2 covers W-43 to W-47 "in the same answer or within 24 hours"; W-47: "T3; T2 if
  combined").
- **Actual:** one check (`concern`). The other order (a harm, then a secret) works.
- **Needs the owner:** keeping a marker means storing something new (a wordless, unsynced local row for 24 hours, or a
  note with an editor's text). QA's view in section 6.

### QA-38 (minor): B31 is the bullying row, not the online one
- `checkWords(['מקללים אותי בקבוצה בוואטסאפ'], ageBand: 2)` gives W-24 / FEAR (the list expects W-42 / ONLINE). Both
  match; the first rule in the table wins. A "repeated" act built from it has no online add-on (105, keep the
  screenshots). Prefer the more specific row when both match.

### QA-39 (minor): a bruise the child has is someone hitting
- `ME`'s `notAfter` holds only `יש` and `אין`. `נפלתי ויש לי מכה ברגל`, `הייתה לי מכה ברגל`, `היה לי מכה בראש` are a
  check (W-03; D3.5 covers only the bare `יש לי`). Two in a week become a "repeated" act, which pushes (C-1).
- Add the prefixed and past forms (`ויש`, `שיש`, `היה`, `הייתה`, `יהיה`, `תהיה`), or do not take `מכה` as a verb right
  after `לי`. The curriculum-expert decides the words.

### QA-40 (major): the `מרוב` idiom
- The idiom guard lists `מצחוק`, `מבושה`, … but not `מרוב` ("from so much"): `בא לי למות מרוב בושה` is a check (W-34)
  and **`אני רוצה למות מרוב צחוק` is an act with a push** (W-30). Proposal §3.5: these idioms "never fire".
- Add `מרוב` to `IDIOM` (and check `מרוב כאב`, which is not an idiom) – curriculum-expert and hebrew-text-editor.

### QA-41 (minor): placeholders filled inside the child's words
- `Str.fill` replaces `{child}`, then `{w}`, then `{n}` one after another; words `אמר {n} {child}` are shown as
  `אמר 5 {child}`. The recogniser and the server pattern do not produce braces today, so it is theoretical; a one-pass
  fill fixes it.

### QA-42 (minor): `detail` decides the card, not the category
- `wordAlertText` reads the tier from `detail` first. A row `inappropriateWords` (info, never pushed) with detail
  `1:PHYS:…` is shown with the act's title and steps. Neither the phone (`takeRemoteAlert`) nor `alert-create` checks
  that detail, category and severity agree. Only a faulty or hostile family device can do this; the category should win.

### QA-43 (minor): the fake server is kinder than the real one
- `test/support/fake_family_server.dart` raises the count for any category with the same key; `_shared/db.ts` and
  `FakeStore` only for `inappropriateWords`, `disclosure`, `concern`. Make the fake match, so a phone test cannot pass
  on behaviour the server refuses.

## 6. Decisions and observations (not defects against the written spec)

### For the owner
- **O-1, alone at home at age 6.** The developer made W-25 tier 1 in band B (5–6) and tier 2 in band C. The owner's
  answer as briefed is "tier 1 up to 5, tier 2 at 6–8"; the proposal's own §3.4 row says "T1 at 3 to 5", while its
  age table (§6) says "5 to 6: T1" and the law note says "up to six". **The app keeps only the band, not the age**, so
  5 and 6 cannot be told apart: either a 6-year-old gets an act (as built) or a 5-year-old gets a check (against test
  rows A25 and E5.2). QA's view: keep band B at tier 1 (the cheaper mistake), and have the owner confirm it in words.
- **O-2, W-47 and W-37 in band A are matched but not saved** (developer's question). W-47 is needed for C-2 (QA-37);
  W-37 at 3–4 is "T3, counted" in the proposal, so dropping it loses the only trace. QA's view: W-37 band A belongs in
  the weekly note with a sentence the hebrew-text-editor writes; W-47 needs either a 24-hour local marker (wordless,
  never synced, gone after a day) or a note with its own sentence. Both are new things stored, so the owner decides.
- **O-3, C-5 "said it happens often" is recorded (`often` in `detail`) but not shown** (developer's question). The
  proposal asks for it in the parent text; there is no sentence in `hebrew-validation.md` §5.1. QA's view: acceptable
  until the hebrew-text-editor writes one sentence; when "keep the words" is on the words already show it.
- **O-4, the numbers are not tappable** (developer's question). `hebrew-validation.md` §8.3 asks for `tel:` and the
  WhatsApp link (a new package needs the owner's OK; the hosts go through the security-engineer and
  `network_hosts.json`). QA's view: not a blocker; meanwhile the help lines should at least be selectable so a parent
  can copy `050-2270118` (no package needed) – design-director and app-developer.
- **O-5, the parent card has no spec** (developer's question). It sits after the last alert, before "the alerts are
  never shown on the children's side", on every visit and also when there is no alert. The design-director places it;
  its "doctor" sentence still waits for the counsellor (owner: ship it before that or not).

### For the curriculum-expert and the counsellor review (the lists behave as written, with these results)
- **Missed, as written:** `לא, מרביצים לי` and `לא נכון, מרביצים לי` (the negation guard reaches two tokens back and
  the recogniser writes no comma); `לא יודע, רוצה למות`; `אני, מכים אותי` (the child-as-hitter guard); `מרביצים לנו`
  ("us" is not in ME); `אני לא רוצה לחיות בעולם הזה` (a place, so cancelled; see QA-34); `אני רוצה למות, מפחד מאבא`
  is a check, not an act (`מפחד` is an idiom word).
- **Acts that will push for ordinary things, as written:** `אמא ביקשה ממני להוריד את הבגדים` (bath time; W-13 with an
  adult), `הרופא נגע לי בפיפי` and `הוא נוגע לי בפיפי כשאמא מקלחת אותי` (W-11), `אמא אמרה שתהרוג אותי אם אשבור את
  הכוס` (W-17: the idiom with a reporting verb), `מרביצים לי בכדורגל` and `בתופסת מכים אותי` (W-01: sport and tag).
- **The letter name:** `האות זין` outside a letter activity is a swear note (D2.14 as written). Adding `האות` to the
  `notAfter` of S-02 (like `כלי`) would end it.

### Behaviour worth knowing
- **O-6:** one alert per 30 minutes is counted from the first hit, not "after 30 quiet minutes" (review R5). A child
  who says it every 20 minutes makes a new act (and a push) every 30 minutes. The owner's brief says "30 minutes", so
  this is as asked.
- **O-7:** across two phones the family count is the higher of the two, not the sum (each phone says 3: the family
  sees 3).
- **O-8:** counting an alert again does not make it unread again; a parent who read the act sees the new count only on
  opening the screen.
- **O-9:** a note keeps saying "this week" (`השבוע`, and "repeated" says `בשבוע האחרון`) for the 30 days it is kept;
  the card's date is the first hit. The hebrew-text-editor and design-director may want the week on the card.
- **O-10:** `alert-create` takes any severity with any category (a `concern` with `important`); the phone never sends
  that, so it matters only for a faulty or hostile family device (security-engineer).
- **O-11:** PLAN's table says `alert-create` is limited to "20 a day per device"; the code allows 300 an hour
  (`ALERTS_PER_HOUR_PER_DEVICE`). Older than this change, but recounts now use calls; PLAN should say what is built.

## 7. pgTAP `08_word_alert_tiers.test.sql` (read, not run)

No local database here, so the file was read, not run. It checks that `concern` is a known category and may carry the
kept words, that a weekly note and an act with flags are accepted, that a `detail` with spaces is refused (23514),
that an unknown category is still refused and that `ribbonEarned` stays. The migration drops the old category check
by looking for `pastLimit` in its definition and adds `alert_category_check` with `concern`; that is right for the
check created by `20261027120000_parent_sync.sql`. Not covered by pgTAP (it is in SQL that lives in `_shared/db.ts`,
covered only by `db_integration_test.ts`, which CI runs): the count that only goes up, and that only word alerts are
counted again. Runs in CI on the push.

### QA-44 (minor): alerts screen polish
- **Bullets:** the second line of a bullet starts under the `•` (`'• ${text}'` in one `Text`), not under the text
  (every render, e.g. the 118 line). A hanging indent (a `Row` with the bullet and an `Expanded` text) reads better.
- **The count is invisible on an act and a check.** The cool-down counts "said again" (`count` 3 in the render), but
  only the weekly note says how many times. A parent cannot tell one sentence from five. Needs a short line from the
  hebrew-text-editor (the C-5 "often" sentence could sit beside it, O-3).
- **Phone, text 1.3:** the settings card (keep the words, plus the new "what alerts can do" text) takes the whole first
  screen; the act starts below the fold (`t1_phone_13_view.png`). Moving the card under the alerts, or folding it, puts
  the act first.

## 8. Mutation checks

Each mutation was applied to one product file, the alert test files were run (`alert_words_test`, `alerts_test`,
`word_alert_text_test`, `sync_engine_test`, `alerts_flow_test`, `voice_answer_test`, `qa_alert_tiers_test`; QA's open
defects skipped), and the file restored from a byte copy (no git command; `git diff --stat app/lib` identical before
and after). Script: `qa_mutate.ps1` in the QA scratchpad.

| Mutation | Result | Killed by |
|---|---|---|
| M1 negation guard dropped (`_before`) | killed, 8 failures | developer and QA |
| M2 the 30-minute episode dropped | killed, 7 | developer and QA |
| M3 tier 2 and 3 from a single lower hypothesis | killed, 4 | developer and QA |
| M4 a remote count may lower the local one (`takeRemoteAlert`) | killed, 1 | **QA only** ("the count only goes up on a phone") |
| M4b counting again without going up | killed, 10 | developer and QA |
| M5 age rule swapped (band A read as C) | killed, 23 | developer and QA |
| M6 the lesson ignores the child's band | killed, 2 | **QA only** (the band A and band C lesson tests) |
| M7 the voice controller hands on no answers | killed, 1 | **QA only** (the controller test) |
| M7b the lesson screen drops the answers on screen | **survived** | no starter activity has a listed word as its answer (gap, below) |
| M8 the after-guards (idioms, a place after "to live") dropped | killed, 9 | developer and QA |
| M9 the child-as-hitter guard dropped | survived the first run; **killed** by QA's added test ("me" further on) | QA |
| M10 C-1 never escalates | killed, 1 | developer |
| M11 C-2 across answers never escalates | survived the first run (C-1 hid it); **killed** by QA's added test (C-1 already used) | QA |
| M12 words kept when the parent said no | killed, 3 | developer and QA |
| M15 the first hypothesis kept, not the matching one | killed, 5 | developer and QA |
| M16 the answers-on-screen filter dropped | killed, 3 | developer and QA |
| M17 C-2 in one answer dropped | killed, 1 | developer |
| M18 the `יש לי` guard dropped | killed, 1 | developer |
| M13 (Deno) quiet alerts pushed (`QUIET_CATEGORIES` ignored) | killed, 1 of 20 | developer (`alerts_test.ts`) |
| M14 (Deno) words allowed on any alert | killed, 3 of 20 | developer |
| server count may go down (`_shared/db.ts`) | **not run here** | only `db_integration_test.ts`, which needs Postgres (CI) |

Gap: nothing proves that `lesson_screen.dart` passes the answers on screen to `recordWordAlert` (M7b); a lesson test
needs an activity whose spoken answer is a listed word (the letter name `זין`). The voice controller part is proved.

## 9. Visual audit

Rendered the alerts screen in the real app (rig, parent gate and PIN, `open-alerts`) for four kinds: an act (PHYS,
`often`, count 3, words kept), a "repeated" act (C-1), a check (count 2), and the two weekly notes (swearing, count 5,
Latin words `fuck you`, child named `Dana`; adult world, words not kept); each on the phone (852×393), a small phone
(667×375), a tablet portrait (820×1180) and landscape (1180×820), at text scale 1.0 and 1.3: the visible screen and the
whole scrolled page, 64 PNGs (QA scratchpad `qa_render/`, not in the repo; the temporary render test was deleted).
**No overflow on the alerts screen in any of the 32 runs** (the only overflow was the child home's daily pill at 1.3
before the parent area opened: QA-19, already open).

Looked at: `app/test/goldens/alerts_view.png` (the developer's golden), `t1_phone_13_full`, `t1_phone_13_view`,
`t1_tabletPortrait_10_full`, `rep_phoneSE_13_full`, `t2_tabletLandscape_13_full`, `t3_phone_13_full`.
- Right to left throughout; Heebo; 118, 1201, 105 and `050-2270118` read left to right in place, also when `105.`
  wraps alone at the end of a line; `ער״ן` and `צ׳אט` as the editor wrote them.
- A Latin name (`Dana: …`, `של Dana`) and Latin words in quotes (`"fuck you"`) sit in the right order.
- Nothing cut, no text over text; the severity word and its colour both show (colour is not the only cue).
- Findings: QA-44; O-9 (a note dated last week says "this week"); the parent card after the alerts on every visit (O-5).

## 10. Not checked

- The real phone (not plugged in): a child's speech through the real recogniser, speed on the device, the push.
- The new SQL and pgTAP 08 (no local database; CI runs them).
- Whether the lists are complete or right for children: the counsellor's review, not QA's.
- The tutor's caring line: not built (owner, 2026-10-29).
