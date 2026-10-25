#!/usr/bin/env bash
# Fails if the repository tracks a file that must never be committed.
set -euo pipefail

fail=0

# 1. Secret-bearing or signing files, and build output.
while IFS= read -r -d '' f; do
  case "$f" in
    .env.example) continue ;;
  esac
  case "$f" in
    .env|.env.*|*/.env|*/.env.*|*.p8|*.p12|*.pem|*.key|*.jks|*.keystore|*/key.properties|key.properties|build/*|*/build/*)
      echo "Forbidden tracked file: $f" >&2
      fail=1 ;;
  esac
done < <(git ls-files -z)

# 2. Audio over 1 MB.
while IFS= read -r -d '' f; do
  case "${f,,}" in
    *.wav|*.mp3|*.ogg|*.opus|*.m4a|*.flac|*.aac)
      size=$(wc -c < "$f")
      if [ "$size" -gt 1048576 ]; then
        echo "Audio file over 1 MB: $f ($size bytes)" >&2
        fail=1
      fi ;;
  esac
done < <(git ls-files -z)

if [ "$fail" -ne 0 ]; then exit 1; fi
echo "Hygiene OK."
