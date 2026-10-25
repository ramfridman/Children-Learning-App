#!/usr/bin/env bash
# Prints each Google attestation root certificate (PEM, fingerprint, subject, expiry) as a GitHub
# annotation. Public data only. Usage: bash tools/ci/fetch-google-roots.sh
set -euo pipefail

work="$(mktemp -d)"
curl -fsS --proto '=https' --tlsv1.2 -m 30 -o "$work/roots.json" https://android.googleapis.com/attestation/root

python3 - "$work" <<'PY'
import json, sys, subprocess, os
work = sys.argv[1]
roots = json.load(open(os.path.join(work, "roots.json")))
if not isinstance(roots, list) or not roots:
    sys.exit("unexpected response shape")
for i, pem in enumerate(roots):
    path = os.path.join(work, f"root{i}.pem")
    open(path, "w").write(pem if pem.endswith("\n") else pem + "\n")
    info = subprocess.run(["openssl", "x509", "-in", path, "-noout", "-fingerprint", "-sha256", "-subject", "-enddate"],
                          capture_output=True, text=True, check=True).stdout.strip().replace("\n", " | ")
    esc = (pem.strip() + "\n").replace("%", "%25").replace("\r", "%0D").replace("\n", "%0A")
    print(f"::notice title=google root {i}::{info}%0A{esc}")
    print(f"root {i}: {info}")
PY
