#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

BOOTSTRAP_ROOT="${BOOTSTRAP_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
# shellcheck source=bootstrap/lib/common.sh
. "${BOOTSTRAP_ROOT}/bootstrap/lib/common.sh"

if [ -z "${DOCTOR_RELOADED:-}" ] && have_cmd zsh; then
  log "Reloading shell environment via zsh -lc"
  exec zsh -lc 'DOCTOR_RELOADED=1 BOOTSTRAP_ROOT="$1" bash "$2"' _ "${BOOTSTRAP_ROOT}" "${BOOTSTRAP_ROOT}/bootstrap/steps/90-doctor.sh"
fi

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
check_cmd docker
check_cmd gh
check_cmd lazygit
check_cmd lazydocker
check_cmd try
check_cmd nvim
check_cmd mise
check_cmd chezmoi
check_cmd shellcheck
check_cmd shfmt

if have_cmd nvim; then
  if nvim --version >/dev/null 2>&1; then
    log "OK: nvim --version"
  else
    warn "nvim --version failed"
  fi
fi

if [ -d "${HOME}/.config/nvim/lua" ]; then
  log "OK: LazyVim config detected (run :LazyHealth in Neovim)"
else
  warn "MISSING: LazyVim config (~/.config/nvim/lua not found)"
  warn "Hint: run Neovim and execute :LazyHealth"
fi

if have_cmd systemctl; then
  if [ -d /run/systemd/system ]; then
    if systemctl --user is-active --quiet docker; then
      log "OK: docker.service (user)"
    else
      warn "MISSING: docker.service (user)"
    fi
  fi
fi

runtime_dir="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
socket="${runtime_dir}/docker.sock"
if [ -S "${socket}" ]; then
  log "OK: docker.sock (${socket})"
else
  warn "MISSING: docker.sock (${socket})"
fi

if have_cmd docker; then
  if docker compose version >/dev/null 2>&1; then
    log "OK: docker compose"
  else
    warn "docker compose unavailable"
  fi

  security_opts="$(docker info --format '{{json .SecurityOptions}}' 2>/dev/null || true)"
  if [ -n "${security_opts}" ]; then
    if printf '%s' "${security_opts}" | grep -q 'rootless'; then
      log "Docker rootless: true"
    else
      warn "Docker rootless: false"
    fi
  else
    warn "Docker info unavailable"
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
