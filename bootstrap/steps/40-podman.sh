#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

BOOTSTRAP_ROOT="${BOOTSTRAP_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
# shellcheck source=bootstrap/lib/common.sh
. "${BOOTSTRAP_ROOT}/bootstrap/lib/common.sh"

need_cmd podman
need_cmd systemctl

missing_deps=()

if ! have_cmd newuidmap || ! have_cmd newgidmap; then
  missing_deps+=(uidmap)
fi

if ! have_cmd slirp4netns; then
  missing_deps+=(slirp4netns)
fi

if ! have_cmd fuse-overlayfs; then
  missing_deps+=(fuse-overlayfs)
fi

if [ "${#missing_deps[@]}" -gt 0 ]; then
  log "Installing Podman rootless dependencies: ${missing_deps[*]}"
  sudo apt-get install -y "${missing_deps[@]}"
fi

log "Enabling Podman user socket"
if ! systemctl --user enable --now podman.socket; then
  die "Failed to enable podman.socket (systemd user session required)."
fi

log "Podman rootless socket enabled"
