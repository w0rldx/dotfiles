#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

BOOTSTRAP_ROOT="${BOOTSTRAP_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
# shellcheck source=bootstrap/lib/common.sh
. "${BOOTSTRAP_ROOT}/bootstrap/lib/common.sh"

need_cmd git

nvim_config="${HOME}/.config/nvim"

is_lazyvim_starter() {
  [ -d "${nvim_config}" ] &&
    [ ! -d "${nvim_config}/.git" ] &&
    [ -f "${nvim_config}/lua/config/lazy.lua" ]
}

backup_path() {
  local path backup
  path="$1"

  if [ ! -e "${path}" ]; then
    return 0
  fi

  backup="${path}.bak"
  if [ -e "${backup}" ]; then
    backup="${path}.bak-$(date +%Y%m%d%H%M%S)"
  fi

  mv "${path}" "${backup}"
  log "Backed up ${path} -> ${backup}"
}

if is_lazyvim_starter; then
  log "LazyVim starter already present; skipping setup"
  exit 0
fi

backup_path "${nvim_config}"
backup_path "${HOME}/.local/share/nvim"
backup_path "${HOME}/.local/state/nvim"
backup_path "${HOME}/.cache/nvim"

log "Cloning LazyVim starter"
git clone https://github.com/LazyVim/starter "${nvim_config}"
rm -rf "${nvim_config}/.git"

overlay_dir="${BOOTSTRAP_ROOT}/chezmoi/dot_config/nvim"
if [ -d "${overlay_dir}" ]; then
  need_cmd rsync
  log "Overlaying Neovim dotfiles from ${overlay_dir}"
  rsync -a "${overlay_dir}/" "${nvim_config}/"
else
  warn "Overlay directory not found: ${overlay_dir}"
fi
