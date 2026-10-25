#!/usr/bin/env bash
# Installs pinned, checksum-verified security tools on a Linux CI runner.
# Usage: tools/ci/install-tools.sh gitleaks|osv ...
set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$here/tool-versions.env"

dest="${TOOLS_DIR:-$HOME/.local/bin}"
mkdir -p "$dest"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

verify() { # file expected_sha256
  echo "$2  $1" | sha256sum --check --status || {
    echo "Checksum mismatch for $1. Nothing was installed." >&2
    exit 1
  }
}

install_gitleaks() {
  local f="$tmp/gitleaks.tar.gz"
  curl -fsSL --retry 3 -o "$f" \
    "https://github.com/gitleaks/gitleaks/releases/download/v${GITLEAKS_VERSION}/gitleaks_${GITLEAKS_VERSION}_linux_x64.tar.gz"
  verify "$f" "$GITLEAKS_SHA256_LINUX_X64"
  tar -xzf "$f" -C "$tmp" gitleaks
  install -m 0755 "$tmp/gitleaks" "$dest/gitleaks"
}

install_osv() {
  local f="$tmp/osv-scanner"
  curl -fsSL --retry 3 -o "$f" \
    "https://github.com/google/osv-scanner/releases/download/v${OSV_VERSION}/osv-scanner_linux_amd64"
  verify "$f" "$OSV_SHA256_LINUX_AMD64"
  install -m 0755 "$f" "$dest/osv-scanner"
}

for tool in "$@"; do
  case "$tool" in
    gitleaks) install_gitleaks ;;
    osv) install_osv ;;
    *) echo "Unknown tool: $tool" >&2; exit 2 ;;
  esac
done

# Make the tools available to later workflow steps.
if [ -n "${GITHUB_PATH:-}" ]; then echo "$dest" >> "$GITHUB_PATH"; fi
