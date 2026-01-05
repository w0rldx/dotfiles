#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

BOOTSTRAP_ROOT="${BOOTSTRAP_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
# shellcheck source=bootstrap/lib/common.sh
. "${BOOTSTRAP_ROOT}/bootstrap/lib/common.sh"

check_cmd() {
  local name
  name="$1"
  if have_cmd "${name}"; then
    log "OK: ${name}"
  else
    warn "MISSING: ${name}"
  fi
}

check_cmd zsh
check_cmd git
check_cmd curl
check_cmd fzf
check_cmd rg
check_cmd fd
check_cmd eza
check_cmd zoxide
check_cmd podman
check_cmd podman-compose
check_cmd gh
check_cmd lazygit
check_cmd lazydocker
check_cmd try
check_cmd nvim
check_cmd mise
check_cmd chezmoi
check_cmd shellcheck
check_cmd shfmt

if have_cmd systemctl; then
  if systemctl --user is-active --quiet podman.socket; then
    log "OK: podman.socket (user)"
  else
    warn "MISSING: podman.socket (user)"
  fi
fi

if have_cmd podman; then
  if podman info --format '{{.Host.Security.Rootless}}' >/dev/null 2>&1; then
    rootless="$(podman info --format '{{.Host.Security.Rootless}}')"
    log "Podman rootless: ${rootless}"
  else
    warn "Podman info unavailable"
  fi
fi

if is_wsl; then
  if have_cmd code; then
    log "OK: code (WSL remote)"
  else
    warn "VS Code not detected in WSL"
    cat >&2 <<'EOM'
Install VS Code on Windows (not inside WSL).
During install, enable "Add to PATH".
Install the "Remote Development" extension pack (or at minimum the WSL extension).
Then in WSL run: code .
This will download/install the VS Code Server automatically.
EOM
  fi
fi
