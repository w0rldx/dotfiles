#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

BOOTSTRAP_ROOT="${BOOTSTRAP_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
# shellcheck source=bootstrap/lib/common.sh
. "${BOOTSTRAP_ROOT}/bootstrap/lib/common.sh"

mise_url="https://mise.run"

if ! have_cmd mise; then
  tmpfile="$(download_to_tmp "${mise_url}")"
  bash "${tmpfile}"
  rm -f "${tmpfile}"
fi

if ! have_cmd mise && [ -x "${HOME}/.local/bin/mise" ]; then
  export PATH="${HOME}/.local/bin:${PATH}"
fi

if ! have_cmd mise; then
  die "mise installation failed"
fi

config_src="${BOOTSTRAP_ROOT}/mise/mise.toml"
config_dest="${HOME}/.config/mise/config.toml"
link_file "${config_src}" "${config_dest}"

log "Installing mise toolchains"
MISE_CONFIG_FILE="${config_src}" mise install
