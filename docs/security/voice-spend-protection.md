# Protecting paid voicing: options beyond the typed count (SEC-3 follow-up)

Security-engineer, 2026-10-29. The owner asked for stronger protection than the terminal gate before any audition. Today
`voice_gen` spends only after the owner types the plan's total at an interactive terminal. A program running as the
owner's Windows user that fakes a console, or types into one, can still pass that gate. The options below either keep the
key away from such a program or limit the worst case to a fixed amount of money. Facts about vendors are cited at the end,
as read on 2026-10-29; dashboard labels may have moved since. Details of weaknesses are in the private notes.

## Ranking

1. **A: a restricted, capped, per-round ElevenLabs key, read from 1Password only after the gate.** Recommended.
2. **C: voicing in GitHub Actions behind an approval.** Only if the approval cannot be given from this PC.
3. **D: the baseline (a separate window, the key from a hidden prompt), plus the account caps of A.**
4. **B: a one-time code.** Adds little and is not recommended.

## A. A restricted, capped key per voicing round, read from 1Password after the gate (recommended)

**How it works.**
- For each round (an audition, a full voicing) the owner creates a new ElevenLabs key. The key:
  - may call text to speech only;
  - has a credit limit just above that round's plan;
  - may be allowlisted to his home IP if it is stable.
- The account's Auto Top Up is off, with a monthly spend cap, so even the account cannot overspend.
- The key lives only in 1Password. After the typed count, `voice_gen` runs `op read` itself. On Windows, 1Password
  authorises the CLI per invoking process, so every run shows a Windows Hello prompt (face, fingerprint or PIN) that the
  owner approves. The key is never in an environment variable, a window, a file or a command line.
- After the round the owner deletes the key.

**What a program running as the owner could still do.**
- Trigger the tool, and so a Windows Hello prompt. The owner must refuse any prompt he did not expect.
- Read the key from the memory of the running tool during a run.
- In every case, spend at most the key's credit limit, and only on text to speech; the account cap holds above that.

This is the only option that limits the worst case in money.

**Setup (the owner):**
1. Browser, elevenlabs.io: Developers › API Keys › Create key. Leave "Restrict key" on and enable only Text to Speech.
   Set the credit limit to the round's planned characters plus 10% (`voice_gen plan` shows the characters; a credit is
   about one character on most models, so check the plan's model). Optionally add an IP allowlist entry for your home IP.
2. Developers › Top Up (or Subscription › Manage subscription on an older plan): turn Auto Top Up (or usage-based
   billing) off, and set the monthly spend cap to what you accept losing.
3. In 1Password: create an "API Credential" item named `ElevenLabs voice_gen` in the vault `Private` and paste the key
   there only.
4. Install the 1Password CLI (a new tool, so it needs your OK), in PowerShell: `winget install AgileBits.1Password.CLI`.
   Then in the 1Password app: Settings › Developer › "Integrate with 1Password CLI" on, and "Unlock using Windows Hello"
   on.
5. Run the paid command in your own PowerShell window. Type the count. Approve the Windows Hello prompt only if you just
   typed a count.
6. After the round: ElevenLabs › API Keys › delete the key, and remove it from 1Password.

**Cost and effort.** Free (1Password is already used). About 15 minutes per round for the owner.

**Code changes.** Yes, small, for the app-developer:
- After the gate, the key comes from `op read "op://Private/ElevenLabs voice_gen/credential"` (stdout captured, never
  echoed, never a command-line argument). The environment variable is refused for paid runs.
- A missing `op` or a refused prompt is a clean "Nothing was sent".

## C. Voicing in GitHub Actions behind an approval (key never on this PC)

**How it works.**
- A `workflow_dispatch` workflow runs `voice_gen` on a GitHub runner. Its inputs are the round and the count, which must
  equal the plan the job prints.
- The job uses an environment `voicing` that:
  - requires the owner's approval;
  - is limited to `main`;
  - holds the ElevenLabs key as an environment secret, written by the owner (we never write GitHub secrets).
- The clips come back as an artifact; the pack is built and signed locally, so the signing key stays on the PC.

**What a program running as the owner could still do.** Anything the owner's GitHub login on this PC allows, which
matters here (see the private notes). On a public repository:
- Run logs and artifacts are public: plans and clips, though never a name.
- Forked pull requests get no secrets, and the branch limit keeps an edited workflow on another branch from reaching the
  key.

**The plan problem.** On GitHub Free, required reviewers and environment secrets work only in public repositories, so
this breaks when the repository goes private (to-do P8).

**Setup:** an environment with a reviewer, a branch rule and a secret; the owner's GitHub login on this PC narrowed or
removed; a new workflow. **Cost and effort:** free on a public repository, about a day of work, and every voicing goes
through CI. **Code changes:** yes, a non-interactive gate mode for CI, plus the workflow (infrastructure-engineer).

## D. The baseline: a separate window and the key from a hidden prompt

**How it works.** As in `docs/setup/supabase-deploy.md` step 3.4: a PowerShell window that does not run Claude Code
holds the key for one run, and the owner types the count.

**What a program running as the owner could still do.** While that window is open:
- read the key from its memory;
- type into it.

With an unrestricted key and no account cap, there is no bound in money.

**Setup:** none beyond today's. **Cost:** none. **Code changes:** none. Worth keeping only together with steps 1, 2 and
6 of A (a restricted, capped, per-round key), which give most of A's protection without the 1Password CLI.

## B. A one-time code (not recommended)

- **A code the tool prints and the owner types back.** Whatever can read the console can type the code too, so it is no
  stronger than the typed count.
- **A code checked against the owner's phone (an authenticator code).** The tool must hold the code's secret to check
  it, and that secret sits on this PC where the same program can read it.
- **A code sent to the phone.** Needs a new vendor and network host (a messaging service) for no bound in money.
- **Effort:** a day of code. **Gain:** small.

## Recommendation

Take **A**. If the owner does not want the 1Password CLI, take **D with A's steps 1, 2 and 6**: a restricted key per
round with a credit limit, Auto Top Up off and a spend cap. The bound in money is what an attacker cannot get around.
Leave the gateway's own ElevenLabs key (a Supabase secret) alone for now; it gets its own restricted key with the
gateway change.

**Tool hardening worth doing whichever option is chosen** (app-developer):
- Require `stdout.hasTerminal` as well as `stdin.hasTerminal`, and turn a stdin read error into the normal refusal.
- SEC-22: refuse `--repo` on the paid commands, and print the repository folder at the top of every plan.
- Print the key's source (1Password or the environment) and the plan's model, without the key, before the count is typed.

## Sources (read 2026-10-29)

- ElevenLabs, API authentication (per-key endpoint scope, credit limit, IP allowlist): https://elevenlabs.io/docs/api-reference/authentication
- ElevenLabs, workspace API keys (1 to 100 IP entries, public IPs only): https://elevenlabs.io/docs/overview/administration/workspaces/api-keys
- ElevenLabs, Pay As You Go (Auto Top Up toggle, optional monthly spend cap, off by default): https://elevenlabs.io/docs/overview/administration/pay-as-you-go
- ElevenLabs, usage-based billing (legacy; toggle and threshold): https://elevenlabs.io/docs/help-center/account/general/what-is-usage-based-billing
- 1Password CLI app-integration security (Windows: authorisation per invoking process, 10-minute idle and 12-hour limits): https://www.1password.dev/cli/app-integration-security/
- GitHub, deployments and environments (required reviewers and environment secrets on Free only in public repositories; prevent self-reviews; branch rules): https://docs.github.com/en/actions/reference/workflows-and-actions/deployments-and-environments
- GitHub REST, review pending deployments for a workflow run: https://docs.github.com/en/rest/actions/workflow-runs#review-pending-deployments-for-a-workflow-run
