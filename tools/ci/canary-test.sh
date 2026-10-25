#!/usr/bin/env bash
# Proves the secret scanner is actually working: plants fake secrets in a temp folder
# and requires gitleaks to flag every one of them. The fake values are built at run time
# from fragments, so this script does not contain a complete fake secret itself.
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
dir="$(mktemp -d)"
trap 'rm -rf "$dir"' EXIT

pad() { printf "%${2}s" "" | tr ' ' "$1"; }

printf 'KEY=%s%s\n'  'sk-ant-' "api03-$(pad A 40)_canary0canary0"            > "$dir/anthropic.txt"
printf 'KEY=%s%s\n'  'sk_'     "$(pad a 48)"                                  > "$dir/elevenlabs.txt"
printf 'KEY=%s%s\n'  'sb_secret_' "$(pad B 30)"                                > "$dir/supabase.txt"
printf 'URL=%s%s\n'  'postgresql://app_gateway:' "S3cretPassw0rd@db.example.supabase.co:5432/postgres" > "$dir/dburl.txt"
{
  printf -- '-----BEGIN %s-----\n' 'PRIVATE KEY'
  printf 'MIIBVQIBADANBgkqhkiG9w0BAQEFAASCAT8wggE7AgEAAkEAu%s\n' "$(pad A 60)"
  printf 'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA\n'
  printf -- '-----END %s-----\n' 'PRIVATE KEY'
} > "$dir/pem.txt"

report="$dir/report.json"
set +e
gitleaks dir --no-banner --config "$root/.gitleaks.toml" --report-format json --report-path "$report" "$dir" >/dev/null 2>&1
code=$?
set -e

if [ "$code" -eq 0 ]; then
  echo "CANARY FAILED: gitleaks found nothing in the planted fake secrets." >&2
  exit 1
fi

for f in anthropic.txt elevenlabs.txt supabase.txt dburl.txt pem.txt; do
  if ! grep -q "\"File\": \".*${f}\"" "$report"; then
    echo "CANARY FAILED: the fake secret in ${f} was not flagged." >&2
    exit 1
  fi
done
echo "Canary OK: all 5 planted fake secrets were flagged."
