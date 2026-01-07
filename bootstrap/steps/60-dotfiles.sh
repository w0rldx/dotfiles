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
  if ! sh "${tmpfile}" -- -b "${HOME}/.local/bin"; then
    warn "chezmoi installer failed with -- -b, retrying with -b"
    sh "${tmpfile}" -b "${HOME}/.local/bin"
  fi
  rm -f "${tmpfile}"
fi

export PATH="${HOME}/.local/bin:${PATH}"
if ! have_cmd chezmoi; then
  die "chezmoi installation failed"
fi

chezmoi_state_dir="${HOME}/.local/share/chezmoi"
if [ -d "${chezmoi_state_dir}" ]; then
  log "Applying chezmoi dotfiles"
  chezmoi apply
else
  log "Initializing chezmoi"
  chezmoi init --apply "${BOOTSTRAP_ROOT}"
fi
