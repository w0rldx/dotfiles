#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

BOOTSTRAP_ROOT="${BOOTSTRAP_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
# shellcheck source=bootstrap/lib/common.sh
. "${BOOTSTRAP_ROOT}/bootstrap/lib/common.sh"

if [ "${EUID:-$(id -u)}" -eq 0 ]; then
  die "Run this installer as a regular user (not root)."
fi

need_cmd sudo

if ! is_ubuntu; then
  die "This installer supports Ubuntu only."
fi

version_id="$(ubuntu_version_id)"
if [ "${version_id}" != "24.04" ]; then
  die "This installer targets Ubuntu 24.04. Detected: ${version_id}."
fi

if is_wsl; then
  if [ ! -d /run/systemd/system ]; then
    warn "WSL detected, but systemd is not running. Using rootless Docker session fallback."
    cat >&2 <<'EOM'
[WARN] For systemd user services (recommended), enable systemd in /etc/wsl.conf:

[boot]
systemd=true

Then run from Windows:
  wsl.exe --shutdown

Re-open your WSL distro and rerun the installer.
EOM
  fi
fi

log "Preflight OK"
