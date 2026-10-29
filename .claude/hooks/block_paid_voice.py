#!/usr/bin/env python3
"""PreToolUse hook (Bash and PowerShell): Claude and its subagents may never spend ElevenLabs money.

The owner's rule (2026-10-29): no voice is generated, no ElevenLabs call is made and the ElevenLabs key is not used
without the owner doing it himself, in his own terminal. This hook reads the command text and refuses:
  - `voice_gen` paid commands: `generate`, `audition`, `audition-batch` anything but `plan` (free: `plan`, `mock`, `list`);
  - the tutor prewarm tool and live tutor calls through the gateway (they voice lines on ElevenLabs);
  - any direct call to api.elevenlabs.io or the `xi-api-key` header;
  - any mention of ELEVENLABS_API_KEY (reading, printing, setting).
Read-only commands (git, grep, cat, ...) that only mention these words are allowed. The check is on the text of one
command, so it is a guard rail on top of the permission rules in .claude/settings.json, not a sandbox: the real gate
is that paid commands need the owner to type the character count in an interactive terminal.
Fails closed: a command it cannot parse is refused when it mentions a guarded word.
"""
import json
import re
import sys

READ_ONLY = {
    "git", "grep", "egrep", "fgrep", "rg", "cat", "ls", "dir", "head", "tail", "wc", "type", "get-content", "gc",
    "select-string", "sls", "findstr", "less", "more", "diff", "get-childitem", "gci", "test-path", "stat",
}
FREE_VOICE_GEN = {"plan", "mock", "list", "help", "--help", "-h"}

GUARDED_WORDS = (
    "api.elevenlabs.io",
    "xi-api-key",
    "elevenlabs_api_key",
    "tutor_prewarm",
    "tutor-prewarm",
    "functions/v1/tutor-turn",
    "functions/v1/tutor-prewarm",
)

REASON = (
    "Blocked: paid ElevenLabs voicing is the owner's to run himself, in his own terminal "
    "(CLAUDE.md, 'Characters and money'). Free commands are allowed: `voice_gen plan`, `audition-batch plan`, "
    "`mock`, `list`. Ask the owner to run the paid command and type the character count."
)


def segments(command):
    """Split a command line into simple commands at ; && || | & and new lines (quotes are not honoured on purpose:
    an attacker-friendly split only makes the check stricter)."""
    return [s.strip() for s in re.split(r"[;\n|]|&&|\|\||&(?!>)", command) if s.strip()]


def tokens(segment):
    return [t.strip("\"'") for t in re.findall(r"\"[^\"]*\"|'[^']*'|\S+", segment)]


def first_word(toks):
    for t in toks:
        base = t.replace("\\", "/").rsplit("/", 1)[-1].lower()
        if base in ("&", "call", "env", "sudo", "start-process", "invoke-expression", "iex", "command"):
            continue
        return base
    return ""


def voice_gen_paid(toks):
    """True when this simple command runs voice_gen with a paid (or unknown) sub-command."""
    idx = [i for i, t in enumerate(toks) if "voice_gen" in t.lower()]
    if not idx:
        return False
    i = idx[0]
    rest = toks[i + 1:]
    sub = None
    sub_at = -1
    skip = False
    for k, r in enumerate(rest):
        if skip:
            skip = False
            continue
        if r.startswith("-"):
            # options that take a value
            if r in ("--repo", "--characters", "--out", "--model", "--price", "--voices", "--work"):
                skip = True
            continue
        sub = r.lower()
        sub_at = k
        break
    if sub is None:
        return False  # `dart compile exe tool/voice_gen.dart -o x` and the like carry no sub-command
    if sub in FREE_VOICE_GEN:
        return False
    if sub == "audition-batch":
        after = [r.lower() for r in rest[sub_at + 1:] if not r.startswith("-")]
        return not (after and after[0] == "plan")
    if sub in ("generate", "audition"):
        return True
    # unknown sub-command or a path-like token after a tool name (compile, analyze, format, git add ...): only the
    # known paid ones are refused here; anything else cannot spend money.
    return False


def check(command):
    low = command.lower()
    for seg in segments(command):
        toks = tokens(seg)
        if not toks:
            continue
        head = first_word(toks)
        seg_low = seg.lower()
        if head in READ_ONLY:
            continue
        if voice_gen_paid(toks):
            return "voice_gen paid command"
        for w in GUARDED_WORDS:
            if w in seg_low:
                return "guarded word: " + w
    # An indirect form: a guarded word anywhere while the first word of the whole command is not read-only.
    if re.search(r"\b(curl|wget|invoke-webrequest|invoke-restmethod|iwr|irm)\b", low) and "elevenlabs" in low:
        return "direct ElevenLabs call"
    return None


def main():
    try:
        data = json.load(sys.stdin)
    except Exception:
        # Cannot read the payload: fail closed (the hook is configured with onFailure=block as well).
        print(json.dumps({"hookSpecificOutput": {"hookEventName": "PreToolUse", "permissionDecision": "deny",
                                                 "permissionDecisionReason": REASON + " (hook input unreadable)"}}))
        return 0
    if data.get("tool_name") not in ("Bash", "PowerShell"):
        return 0
    command = (data.get("tool_input") or {}).get("command") or ""
    why = check(command)
    if why:
        print(json.dumps({"hookSpecificOutput": {"hookEventName": "PreToolUse", "permissionDecision": "deny",
                                                 "permissionDecisionReason": REASON + " [" + why + "]"}}))
        sys.stderr.write(REASON + " [" + why + "]\n")
        return 2
    return 0


if __name__ == "__main__":
    sys.exit(main())
