# QA verification: the voice-tool change (voice text from the master table, pre-flight check, ledger, gated auditions)

2026-10-29, qa-engineer. Worktree `D:\nitznutz-voicefix`, branch `voice-quality-diagnosis` at `aea8e56`, plus the
app-developer's uncommitted changes. Nothing was sent to ElevenLabs. No key was used, and nothing was paid for.

## Round 2: re-verification after the fix round

**Verdict.**
- **QA-22 to QA-29 are closed.**
- **May be committed.** No path sends a request unless a number is typed at the keyboard. That number must equal the
  total printed in the same process. The key is read only after that.
- **New: QA-30 (major).** One promise of the new gate does not hold on Windows. When stdin is the NUL device, Dart
  says `stdin.hasTerminal` is true. This happens in the PowerShell tool of an agent session, often in its Bash tool
  too, and with `< NUL` or `< /dev/null` in Git Bash.
  - So a paid command passes the first half of the gate.
  - It then prints the plan, including the count, and asks for the number.
  - Reading from NUL then throws, and the run stops with "FAILED: unexpected StdinException". Nothing is sent.
  - Its test is in the QA file, behind `QA_OPEN`.
  - It should be fixed before the first paid audition. It does not block the commit.

### What ran (in `app/`)

| Command | Result |
|---|---|
| `flutter analyze` | No issues found (also after QA's additions) |
| `dart format --output=none --set-exit-if-changed .` | 285 files, 0 changed |
| `flutter test test/voice_text_test.dart test/audition_test.dart test/voice_gen_test.dart test/voice_gen_cli_test.dart` | 85 passed. With QA's 6 tests: 91 |
| `flutter test` (the whole suite, before QA's round-2 additions) | **1251 passed, 8 skipped, 0 failed** (10 min 19 s). Frame cost in the full run: 95th percentile 1.94 ms |
| `flutter test test/character_view_test.dart`, 3 times | 7 passed each time; 95th percentile 1.81, 1.84 and 1.06 ms (the limit is 8) |
| `flutter test test/qa_voice_tool_test.dart` (with the round-2 additions) | 14 passed, 1 skipped (QA-30, open) |
| `flutter test test/qa_voice_tool_test.dart --dart-define=QA_OPEN=true --plain-name QA-30` | 1 failed, as expected: the plan and its count are printed with stdin from NUL |
| `deno task check` | not run: `supabase/` is untouched |

### By hand (no `ELEVENLABS_API_KEY` in the environment)

`%USERPROFILE%\nitznutz-voice` was compared before and after (every file, size and mtime): no change.

| Check | Result |
|---|---|
| `generate nitzi`, `audition-batch run tool/audition_example.json` and `audition nitzi "שלום."`, from the agent's Bash | Depends on what stdin the agent's shell gets, and that varies from call to call. A small probe printed `stdin.hasTerminal` false in one call and true in a later one, with the same command. When stdin is a pipe: exit 1, "runs only in an interactive terminal ... Nothing was sent", no stdout, no digit. When stdin is NUL: QA-30 (next rows) |
| The same three with `--confirm-chars N` | exit 1, "--confirm-chars is not accepted ... Nothing was sent". No digit in the output |
| The same, with stdin piped (`echo 57 \|`) | refused at the terminal check |
| The same, with stdin from NUL (`< /dev/null`, or the agent's PowerShell tool) | **QA-30**: the plan and its total (57, or 5) are printed with the prompt, then "FAILED: unexpected StdinException". Nothing sent, no folder. For `generate`, the gate passes and it then stops at the 2,831 lines that wait (no character count is shown) |
| A pretend terminal (`FakeKeyboard`, read in the tests) | `generateGated` and `runAudition` print the plan. They refuse an empty line, 41, 43, `42x` and `forty-two`. With the exact number they go ahead through a mock HTTP client. The voice (and so the key) is made only after the number |
| `plan --characters nitzi --list` | free, exit 0: 0 lines to say, 0 characters. 2,831 lines wait: 2,740 `text-ready` and 91 `proposed` |
| `audition-batch plan tool/audition_example.json` | free: total 57. No `--confirm-chars` hint, nothing written |
| `audition-batch plan` on the director's `docs/audio/audition/round1.json` and `round2.json` | Both parse and pass the pre-flight check. Round 1: 34 clips, 1,852 characters, 0.1178 USD. Round 2: 59 clips, 2,774 characters, 0.2219 USD |
| `main()` catch-all: a spec whose title is a number; a spec that is not JSON | "FAILED: unexpected _TypeError" and "FAILED: unexpected FormatException": no stack trace, no message text |
| Every `voice_text` in the master table (7,075 rows, all sources), checked by an independent Python copy of the allowlist | all pass; each has a Hebrew letter |
| `git status` | Only `app/tool/*`, `app/test/*`, `content/voices.json` (valid JSON, nine voices), one line of `docs/PLAN.md`, and the other agents' docs (`docs/audio/*`, `docs/security/voice-tool-review.md`). No `supabase/`, pack, pubspec or lock, `.github` or screen |

### QA's round-2 tests (`app/test/qa_voice_tool_test.dart`, test code only)

- **The allowlist:** 56 more cases are refused, including:
  - fullwidth punctuation and digits, Arabic-Indic and enclosed digits;
  - Hebrew presentation forms (U+FB1D, U+FB2A, U+FB29, U+FB4F), Yiddish ligatures;
  - cantillation, meteg, rafe, upper dot, paseq, sof pasuq;
  - NBSP and other spaces, tab, CR and LF;
  - LRM, ALM, RLE, RLO, soft hyphen;
  - combining marks on Hebrew and on Latin, CGJ, VS16;
  - emoji (with skin tone, keycap, ZWJ family);
  - Arabic, Samaritan, a lone surrogate;
  - `( ) / \ % + = ÷ ×`;
  - a text of only punctuation, or only points.
- **The allowances:**
  - `exclamation` lets only the plain `!` through, never its 8 look-alikes.
  - `ipa` refuses a space, a digit, a click letter, a combining mark, an unclosed or empty `/…/`, more than 40 letters, a second bad pair, and IPA with no Hebrew.
  - `audio-tags` refuses a capital, a space, an unknown tag, an unclosed tag, and a tag alone.
  - `line-breaks` lets only LF through; CR and U+2028 are refused.
- **The key:**
  - 200 printable characters are accepted.
  - Refused by name, and never shown: 201 characters, é, a BOM, NUL, DEL, empty, spaces, CR/LF.
  - A client error whose message quotes the key comes out of `say()` as an error that names only its kind.
- **SEC-20:** `nitzi`, `nitzi\`, `nitzi\\` and `nitzi\.` share one ledger, beside the folder. A folder that ends in `.` or `..` is refused.
- **QA-30 (open).**

### The defects

| Id | Sev. | State | Proof |
|---|---|---|---|
| QA-22 | major | closed: `owner-approved`, `voice-ready` and `voiced` only; today 0 voiceable, 2,831 waiting | QA-22, the plan above |
| QA-23 | minor | closed: an allowlist instead of a denylist | QA-23 (18 cases) plus round 2 (56 cases) |
| QA-24 | minor | closed: IPA letters and stress and length marks only | QA-24 plus round 2 |
| QA-25 | blocker | closed: the key is checked in the constructor; `say()` and `main()` catch everything and name only the kind of error | QA-25 (now a mock client), round-2 key tests, the bad-spec runs |
| QA-26 | minor | closed: a value that is not finite is refused | QA-26 |
| QA-27 | minor | closed: a duplicate key with a different text or status waits | QA-27 |
| QA-28 | nit | closed: `plan` offers no `--confirm-chars`; it explains the per-voice run | `voice_gen_cli_test.dart` |
| QA-29 | nit | closed: the CLI tests run on their own fixture repo (`--repo`) and compile once. The frame-cost test passes in the full run and alone | the runs above |
| **QA-30** | **major** | **open**, owner app-developer (and security-engineer, SEC-3). On Windows, `stdin.hasTerminal` is true for NUL. Fix: also require `stdout.hasTerminal`, and probe the console (for example `stdin.echoMode` in a try: it throws on NUL); treat a `StdinException` while reading as "Nothing was sent", by name | QA-30 (`--dart-define=QA_OPEN=true`) |
| QA-31 | nit | open, owner app-developer. Inside a paid run, the printed plan still says "Nothing was sent. To make them, run in a terminal: ..." right before it asks for the number | output text only |

### Not checked (round 2)

- A real interactive console: I have none. The real keyboard path (`TerminalKeyboard`) was checked only by reading
  the code and through the NUL case.
- A real ElevenLabs call (on purpose).
- Real redirects: the `followRedirects = false` flag is checked on the mock request, not with a live server.
- Audio.
- The gateway side of H1 to H3 and H8.
- C2 (scope), C3 (one clip per distinct text) and C8 (loudness) are not built.

## Round 1: the first pass (kept for the record)

**Gate and texts.** The gate held. The texts sent equal the master `voice_text`, checked by an independent
re-computation: 2,740 lines, 109,803 characters, 0 mismatches. The 91 blocked lines were exactly the voiced lines that
have `proposed` rows:
- 78 from the 100 V1 rows. The 100th, `skill.NUM-A-14 › childLine`, has no `vo`.
- 13 from Q2 to Q5 (28 rows).

**Suite.** The full suite gave 1227 passed, 8 skipped and 1 failed. The failure was frame cost under load (QA-29).

**Defects filed:**
- QA-25 (blocker): a malformed key was printed through an uncaught `FormatException` from `package:http`.
- QA-22 (major): the wrong statuses were voiceable.
- QA-23, QA-24, QA-26 and QA-27 (minor).
- QA-28 and QA-29 (nits).

**Not covered by `voice_gen`:**
- the 66 hero-son tutor lines (gateway);
- 100 skill `childLine` rows marked `spoken=yes` that have no `vo`;
- `homeBubble` (`{child}`).

The 27 duplicate keys are all in `hero-son.json`.

**Pointing.** 669 approved lines have more than one pointed word in three, mostly number words that are pointed by
design. The director's suggested "one in three" test needs a rule from the director and the editor first.

**Other notes from round 1:**
- `respelled()` still replaces substrings, not whole words (C5/H7). `pronunciation` is empty today.
