#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

BOOTSTRAP_ROOT="${BOOTSTRAP_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
# shellcheck source=bootstrap/lib/common.sh
. "${BOOTSTRAP_ROOT}/bootstrap/lib/common.sh"

if is_wsl; then
  log "WSL detected; ensuring VS Code Server dependencies"
  sudo apt-get update
  sudo apt-get install -y wget ca-certificates
  log "WSL VS Code Server dependencies installed"
  exit 0
fi

if [ "${INSTALL_VSCODE_LINUX:-0}" != "1" ]; then
  log "INSTALL_VSCODE_LINUX not set; skipping VS Code install"
  exit 0
fi

need_cmd sudo

log "Installing VS Code (native Linux) via Microsoft apt repo"
sudo apt-get update
sudo apt-get install -y wget gpg ca-certificates

key_url="https://packages.microsoft.com/keys/microsoft.asc"
tmpfile="$(download_to_tmp "${key_url}")"
tmpgpg="${tmpfile}.gpg"

gpg --dearmor -o "${tmpgpg}" "${tmpfile}"
sudo install -d -m 0755 /etc/apt/keyrings
sudo install -m 0644 "${tmpgpg}" /etc/apt/keyrings/microsoft.gpg
rm -f "${tmpfile}" "${tmpgpg}"

arch="$(dpkg --print-architecture)"
sudo tee /etc/apt/sources.list.d/vscode.sources >/dev/null <<EOF_VSCODE
Types: deb
URIs: https://packages.microsoft.com/repos/code
Suites: stable
Components: main
Architectures: ${arch}
Signed-By: /etc/apt/keyrings/microsoft.gpg
EOF_VSCODE

sudo apt-get update
sudo apt-get install -y code
