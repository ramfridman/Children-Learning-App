#!/usr/bin/env bash
# Runs the Dart formatter. If it would change anything, the change is printed as a compressed,
# base64 patch split over a few annotations, so it can be read from the check-run API and applied
# with: (concatenate the parts) | base64 -d | gunzip | git apply
# Usage: tools/ci/format-or-patch.sh <flutter project dir> <dir>...
set -uo pipefail

project="$1"; shift
cd "$project"
dart format "$@" > /dev/null
if git diff --quiet -- "$@"; then
  echo "format: clean"
  exit 0
fi

git diff --no-color -- "$@" | gzip -9 | base64 -w0 > "${RUNNER_TEMP:-/tmp}/format.patch.b64"
echo "format: files need formatting; patch follows as annotations"
git diff --stat -- "$@"
part=0
split -b 3000 -d -a 2 "${RUNNER_TEMP:-/tmp}/format.patch.b64" "${RUNNER_TEMP:-/tmp}/fp."
for f in "${RUNNER_TEMP:-/tmp}"/fp.*; do
  echo "::error title=format patch part ${f##*.}::$(cat "$f")"
  part=$((part + 1))
done
exit 1
