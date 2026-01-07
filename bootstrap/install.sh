#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

BOOTSTRAP_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export BOOTSTRAP_ROOT

# shellcheck source=bootstrap/lib/common.sh
. "${BOOTSTRAP_ROOT}/bootstrap/lib/common.sh"

log "Starting bootstrap"

steps=(
  "00-preflight.sh"
  "05-apt-ppa.sh"
  "10-apt.sh"
  "20-zsh-ohmyzsh.sh"
  "30-mise.sh"
  "35-cargo-packages.sh"
  "36-npm-packages.sh"
  "40-podman.sh"
  "50-tools-github.sh"
  "50-neovim.sh"
  "55-lazyvim.sh"
  "60-dotfiles.sh"
  "70-vscode.sh"
  "90-doctor.sh"
)

for step in "${steps[@]}"; do
  log "Running ${step}"
  bash "${BOOTSTRAP_ROOT}/bootstrap/steps/${step}"
  log "Completed ${step}"
  echo
done

log "Bootstrap finished"
