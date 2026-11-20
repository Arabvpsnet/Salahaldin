#!/usr/bin/env python3
"""Conservative tracked-secret guard; supplement with GitHub secret scanning, not a replacement."""
from __future__ import annotations
import re
import subprocess
import sys
from pathlib import Path

files = subprocess.check_output(["git", "ls-files", "-z"]).decode("utf-8").split("\0")
bad_names = re.compile(r"(?i)(^|/)(\.env|google-services\.json|GoogleService-Info\.plist|id_rsa|id_ed25519)(\.|$)")
bad_ext = {".p12", ".pfx", ".jks", ".keystore"}
patterns = {
    "private key": re.compile(r"-----BEGIN (?:RSA |EC |OPENSSH |DSA )?PRIVATE KEY-----"),
    "GitHub personal access token": re.compile(r"gh[pousr]_[A-Za-z0-9_]{35,}"),
    "GitHub fine-grained token": re.compile(r"github_pat_[A-Za-z0-9_]{40,}"),
    "AWS access key": re.compile(r"AKIA[0-9A-Z]{16}"),
    "Google API key": re.compile(r"AIza[0-9A-Za-z_-]{35}"),
}
excluded = ("server/vendor/", "mobile/assets/", "tv/public/", "server/public/", "tv/src/data/", "server/database/seeders/")
issues = []
for name in filter(None, files):
    path = Path(name)
    if not name.endswith(".env.example") and (bad_names.search(name) or path.suffix.lower() in bad_ext):
        issues.append((name, "sensitive filename"))
    if name.startswith(excluded) or path.suffix.lower() not in {".php", ".js", ".ts", ".dart", ".json", ".yml", ".yaml", ".py", ".env", ".md"}:
        continue
    try:
        data = path.read_bytes()
    except OSError:
        continue
    if len(data) > 1_000_000 or b"\0" in data:
        continue
    text = data.decode("utf-8", "replace")
    for reason, regex in patterns.items():
        if regex.search(text):
            issues.append((name, reason))
for name, reason in sorted(set(issues)):
    print(f"SECURITY FINDING: {name}: {reason}")
print(f"Scanned {len(files)} tracked paths; findings: {len(set(issues))}")
if issues:
    sys.exit(1)
