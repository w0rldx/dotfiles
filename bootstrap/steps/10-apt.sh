#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

BOOTSTRAP_ROOT="${BOOTSTRAP_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
# shellcheck source=bootstrap/lib/common.sh
. "${BOOTSTRAP_ROOT}/bootstrap/lib/common.sh"

packages=(
  zsh
  git
  curl
  ca-certificates
  fzf
  ripgrep
  fd-find
  eza
  zoxide
  podman
  podman-compose
)

log "Updating apt metadata"
sudo apt-get update

log "Installing apt packages"
sudo apt-get install -y "${packages[@]}"

if have_cmd fdfind && ! have_cmd fd; then
  mkdir -p "${HOME}/.local/bin"
  ln -sf "$(command -v fdfind)" "${HOME}/.local/bin/fd"
  log "Linked fd -> fdfind in ~/.local/bin"
fi
