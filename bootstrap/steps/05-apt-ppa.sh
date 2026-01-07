#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

BOOTSTRAP_ROOT="${BOOTSTRAP_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
# shellcheck source=bootstrap/lib/common.sh
. "${BOOTSTRAP_ROOT}/bootstrap/lib/common.sh"

ppa_slug="zhangsongcui3371/fastfetch"
ppa="ppa:${ppa_slug}"
ppa_pattern="ppa.launchpad.net/${ppa_slug}/ubuntu"

list_files=(/etc/apt/sources.list /etc/apt/sources.list.d/*.list)
if grep -Rqs "${ppa_pattern}" "${list_files[@]}" 2>/dev/null; then
  log "PPA already present: ${ppa}"
  exit 0
fi

if ! have_cmd add-apt-repository; then
  log "Installing software-properties-common for add-apt-repository"
  sudo apt-get update
  sudo apt-get install -y software-properties-common
fi

log "Adding PPA: ${ppa}"
sudo add-apt-repository -y --no-update "${ppa}"
