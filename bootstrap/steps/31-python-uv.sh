#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

BOOTSTRAP_ROOT="${BOOTSTRAP_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
# shellcheck source=bootstrap/lib/common.sh
. "${BOOTSTRAP_ROOT}/bootstrap/lib/common.sh"

need_cmd curl

if have_cmd uv; then
  log "uv already installed"
  exit 0
fi

install_url="https://astral.sh/uv/install.sh"
log "Installing uv via ${install_url}"
tmpfile="$(download_to_tmp "${install_url}")"
sh "${tmpfile}"
rm -f "${tmpfile}"
