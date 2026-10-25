#!/usr/bin/env bash
# Runs a command and, if it fails, copies the end of its output into GitHub annotations and the
# job summary. That makes failures readable from the check-run API without downloading logs.
# Usage: tools/ci/run-with-annotations.sh "<title>" <command> [args...]
# Only use it for steps whose output holds no secrets (tests, linters, builds).
set -uo pipefail

title="$1"; shift
out="$(mktemp)"
"$@" 2>&1 | tee "$out"
code="${PIPESTATUS[0]}"

if [ "$code" -ne 0 ]; then
  tail_text="$(tail -n 80 "$out" | sed 's/\x1b\[[0-9;]*[A-Za-z]//g' | cut -c1-400)"
  # Annotations are limited in size; keep the end of the output, escape newlines for the runner.
  esc="$(printf '%s' "$tail_text" | tail -c 3500 | sed ':a;N;$!ba;s/%/%25/g;s/\r/%0D/g;s/\n/%0A/g')"
  echo "::error title=${title} failed (exit ${code})::${esc}"
  if [ -n "${GITHUB_STEP_SUMMARY:-}" ]; then
    {
      echo "### ${title} failed (exit ${code})"
      echo '```'
      echo "$tail_text"
      echo '```'
    } >> "$GITHUB_STEP_SUMMARY"
  fi
fi
exit "$code"
