# Security review: the voice tool change (voice text from the master table, pre-flight, ledger, gated auditions)

Security-engineer, 2026-10-29, two rounds (the first review, then a re-review of the app-developer's fixes). Branch
`voice-quality-diagnosis`, uncommitted changes on `aea8e56`. While the repository is public, the detail of open findings is
kept in the git-ignored `docs/security/private/voice-tool-review.md`; this file holds the public record only.

## Scope

In scope: `app/tool/voice_gen.dart`, `voice_gen_lib.dart`, `voice_text_lib.dart`, `audition_lib.dart`,
`audition_example.json`, `content/voices.json`, and the tests `voice_text_test.dart`, `audition_test.dart`,
`voice_gen_test.dart`, `voice_gen_cli_test.dart` and `test/support/fake_eleven.dart`; for comparison the gateway's
`supabase/functions/_shared/elevenlabs.ts` and its caller. Not in scope: the app, the other gateway functions, the voice packs
themselves.

## Verified

- **The paid-run gate.** `generate`, `audition-batch run` and `audition` work only when stdin is an interactive terminal.
  In one process they plan exactly what they will send, print it, and go ahead only when the number typed on the keyboard
  equals the total. `--confirm-chars` is refused, and no refusal names a number. One audition clip is at most 300
  characters. Re-run with the real command: a number piped into it is refused, and with stdin on the NUL device it shows the
  plan, then stops with nothing sent. The gate cannot tell a console faked on purpose from a real one; the owner's
  safeguard for that is below.
- **The key.** Read only from `ELEVENLABS_API_KEY`, only after the gate. It must be 1 to 200 printable ASCII characters
  with no space; a key that is not is refused without being shown. It is never printed, never in a URL (header only), and
  not in the clip ledger, the audition records, error messages (status or error type only; an unexpected error prints its
  type only) or test fixtures (dummy values only). No command-line option carries it.
- **What is sent.** Words come from the `voice_text` column, only for rows the owner approved. Every text passes an
  allowlist pre-flight check before anything is sent and again just before the HTTP call; pack lines carry no allowance.
  No `{child}` line reaches the tool. Spec and settings input is strict, and clip ids are plain file names.
- **The ledger** holds ids, hashes, file names, counts, the text sent, the voice id, model, format and settings: no key, no
  device id, no personal data. It is always next to the work folder, never inside it.
- **The HTTP client.** package:http 1.6.0, already a direct dependency; `pubspec.yaml` and `pubspec.lock` unchanged. The
  host is a constant, redirects are not followed, every call has a timeout, and TLS verification is the platform default.
- **`--repo <folder>`** cannot change the host, the key or the gate.

## Findings

| Id | Severity | Status |
|---|---|---|
| SEC-3 | medium | closed in code (re-verified 2026-10-29); residual risk below |
| SEC-5 | medium | open (part (a) closed by this change) |
| SEC-10 | low | closed (re-verified 2026-10-29) |
| SEC-17 | medium | closed (re-verified 2026-10-29) |
| SEC-18 | low | open (the tool's part closed; the gateway's part open) |
| SEC-19 | low | closed (re-verified 2026-10-29) |
| SEC-20 | low | closed (re-verified 2026-10-29) |
| SEC-21 | low | closed (re-verified 2026-10-29) |
| SEC-22 | low | open |

Closed in short:
- **SEC-3:** a paid voice run now needs the owner's number typed at an interactive terminal, against a plan printed by
  the same process.
- **SEC-10:** the voice id is checked as 10 to 40 letters and digits before it goes into the request.
- **SEC-17:** only rows the owner approved (`owner-approved`, `voice-ready`, `voiced`) are voiced.
- **SEC-19:** the pre-flight check is an allowlist that no audition allowance can widen to digits, placeholders, markup or
  `!` look-alikes.
- **SEC-20:** the clip ledger's place comes from the normalised folder, and odd `--out` spellings are refused.
- **SEC-21:** a row that appears twice with a different text or status waits.

**Residual risk (SEC-3).** A process that deliberately runs the tool in a real or simulated console and types the number
into it (a pseudoconsole, keystrokes sent to a window, a desktop-control tool) passes the gate. The control for that is
where the key lives: only in the owner's own window, never at user or machine level.

Gateway items for the later gateway change (rated, detail private): 22.05 kHz live voice (informational), no explicit
voice settings (low), the live and prewarm model id not checked as a Hebrew model (low), lexicon points reaching the voice
(informational), no server-side pre-flight before the voice call (low), redirects followed with the key header (low, the
open part of SEC-18).

## Advisories checked

- OSV.dev query for `pub/http` 1.6.0 and for all versions (2026-10-29): none for 1.6.0 (the only one for the package,
  GHSA-4rgh-jx4f-qfcq / CVE-2020-35669, affects versions before 0.13.3).
- Dart SDK GHSA-c8mh-jj22-xg5h / CVE-2022-0451 (cross-origin redirect headers, fixed in 2.16 for the listed sensitive
  headers only); read against the installed SDK 3.13.7 source; the tool no longer follows redirects.
- CVE-2026-103030 (`dio_http2_adapter`, published 2026-10-13): not used here (no `dio` in the lock file).

Not run by the security-engineer: the Flutter tests (the qa-engineer ran them at the same time), gitleaks (not installed on
this PC; CI runs it; the changed files were searched by pattern instead), the Deno tests.
