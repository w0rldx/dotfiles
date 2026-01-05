#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

BOOTSTRAP_ROOT="${BOOTSTRAP_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
# shellcheck source=bootstrap/lib/common.sh
. "${BOOTSTRAP_ROOT}/bootstrap/lib/common.sh"

if ! have_cmd chezmoi; then
  install_url="https://get.chezmoi.io"
  tmpfile="$(download_to_tmp "${install_url}")"
  mkdir -p "${HOME}/.local/bin"
  bash "${tmpfile}" -- -b "${HOME}/.local/bin"
  rm -f "${tmpfile}"
fi

export PATH="${HOME}/.local/bin:${PATH}"
if ! have_cmd chezmoi; then
  die "chezmoi installation failed"
fi

nvim_dir="${HOME}/.config/nvim"
if [ ! -d "${nvim_dir}" ]; then
  log "Cloning AstroNvim"
  git clone --depth 1 https://github.com/AstroNvim/AstroNvim "${nvim_dir}"
else
  if [ ! -d "${nvim_dir}/.git" ]; then
    warn "${nvim_dir} exists and is not a git repo; skipping AstroNvim clone"
  fi
fi

chezmoi_state_dir="${HOME}/.local/share/chezmoi"
if [ -d "${chezmoi_state_dir}" ]; then
  log "Applying chezmoi dotfiles"
  chezmoi apply
else
  log "Initializing chezmoi"
  chezmoi init --apply "${BOOTSTRAP_ROOT}"
fi
