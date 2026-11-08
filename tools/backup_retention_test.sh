#!/usr/bin/env bash
# Regression test for SEC-BK-1: the retention filter of .github/workflows/backup.yml, run on a listing in the form the
# AWS CLI v2 really prints (ISO 8601 with "+00:00", optional microseconds; awscli/customizations/timestampformat.py
# formats every timestamp with datetime.isoformat()). Needs bash, GNU date and jq (all on ubuntu-24.04 runners).
#
#   bash tools/backup_retention_test.sh
#
# The jq program is read out of backup.yml itself, so the test checks the filter that runs. It is given both
# `$cutoff` (epoch seconds, 27 days ago) and `$cutoffday` (YYYY-MM-DD, 27 days ago); the filter may use either.
set -euo pipefail
here=$(cd "$(dirname "$0")/.." && pwd)
wf="$here/.github/workflows/backup.yml"
[ -f "$wf" ] || { echo "FAIL: $wf not found"; exit 1; }

# The text from the `jq -r ...cutoff...` line to the line with `' listing.json`, then what is between the quotes.
block=$(awk '/jq -r .*cutoff/ {on=1} on {print} on && /'"'"' listing\.json/ {exit}' "$wf")
[ -n "$block" ] || { echo "FAIL: could not find the retention jq program in backup.yml"; exit 1; }
prog=${block#*\'}
prog=${prog%%\' listing.json*}
[ -n "$prog" ] && [ "$prog" != "$block" ] || { echo "FAIL: could not cut the jq program out of backup.yml"; exit 1; }

cutoff=$(date -u -d '27 days ago' +%s)
cutoffday=$(date -u -d '27 days ago' +%Y-%m-%d)
day() { date -u -d "$1 days ago" +%Y-%m-%d; }
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

run() { # $1 = listing file; prints the keys the filter would delete, sorted
  jq -r --argjson cutoff "$cutoff" --arg cutoffday "$cutoffday" "$prog" "$1" | sort
}
fails=0
check() { # $1 = name, $2 = listing file, $3 = expected keys (newline separated, sorted)
  local got
  if ! got=$(run "$2" 2>"$tmp/err"); then
    echo "FAIL: $1: the filter stopped with an error: $(cat "$tmp/err")"; fails=$((fails + 1)); return
  fi
  if [ "$got" = "$3" ]; then echo "PASS: $1"; else
    echo "FAIL: $1"; echo "  expected: $(echo "$3" | tr '\n' ' ')"; echo "  got:      $(echo "$got" | tr '\n' ' ')"
    fails=$((fails + 1))
  fi
}
obj() { # $1 = key, $2 = LastModified as the AWS CLI v2 prints it
  printf '{"Key":"%s","LastModified":"%s","ETag":"\\"x\\"","Size":12345,"StorageClass":"STANDARD"}' "$1" "$2"
}
k() { echo "nitznutz-backup-$(day "$1").dump.age"; }

# 1. Six weekly copies (one with microseconds) and one foreign object: the 35- and 28-day copies go, nothing else.
{
  echo '{"Contents":['
  obj "$(k 35)" "$(day 35)T03:20:01.123000+00:00"; echo ','
  obj "$(k 28)" "$(day 28)T03:20:01+00:00"; echo ','
  obj "$(k 21)" "$(day 21)T03:20:01+00:00"; echo ','
  obj "$(k 14)" "$(day 14)T03:20:01.5+00:00"; echo ','
  obj "$(k 7)" "$(day 7)T03:20:01+00:00"; echo ','
  obj "$(k 0)" "$(day 0)T00:00:01+00:00"; echo ','
  obj "notes.txt" "$(day 60)T03:20:01+00:00"
  echo ']}'
} > "$tmp/weekly.json"
check 'weekly copies: only those older than 27 days are deleted' "$tmp/weekly.json" "$(printf '%s\n%s' "$(k 28)" "$(k 35)" | sort)"

# 2. Backups failed for weeks: one copy, 60 days old. It is the newest, so it stays.
{ echo '{"Contents":['; obj "$(k 60)" "$(day 60)T03:20:01+00:00"; echo ']}'; } > "$tmp/one.json"
check 'a lone old copy is never deleted' "$tmp/one.json" ''

# 3. Two old copies: the older goes, the newest stays.
{ echo '{"Contents":['; obj "$(k 67)" "$(day 67)T03:20:01+00:00"; echo ','; obj "$(k 60)" "$(day 60)T03:20:01+00:00"; echo ']}'; } > "$tmp/two.json"
check 'of two old copies only the older is deleted' "$tmp/two.json" "$(k 67)"

# 4. An empty bucket: list-objects-v2 prints no Contents at all.
echo '{"RequestCharged":null}' > "$tmp/empty.json"
check 'an empty bucket deletes nothing' "$tmp/empty.json" ''

# 5. A key that only looks like a backup is left alone.
{ echo '{"Contents":['; obj "nitznutz-backup-$(day 90).dump.age.bak" "$(day 90)T03:20:01+00:00"; echo ','; obj "$(k 0)" "$(day 0)T03:20:01+00:00"; echo ']}'; } > "$tmp/odd.json"
check 'a key that is not exactly a backup name is kept' "$tmp/odd.json" ''

if [ "$fails" -ne 0 ]; then echo "$fails check(s) failed."; exit 1; fi
echo 'All retention checks passed.'
