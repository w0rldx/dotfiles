#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

BOOTSTRAP_ROOT="${BOOTSTRAP_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
# shellcheck source=bootstrap/lib/common.sh
. "${BOOTSTRAP_ROOT}/bootstrap/lib/common.sh"

ohmyzsh_dir="${HOME}/.oh-my-zsh"

if [ ! -d "${ohmyzsh_dir}" ]; then
  install_url="https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh"
  tmpfile="$(download_to_tmp "${install_url}")"

  RUNZSH=no CHSH=no KEEP_ZSHRC=yes bash "${tmpfile}"
  rm -f "${tmpfile}"

  log "Oh-My-Zsh installed"
else
  log "Oh-My-Zsh already installed"
fi

ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
mkdir -p "${ZSH_CUSTOM}/themes" "${ZSH_CUSTOM}/plugins"

install_or_update_repo() {
  local repo_dir repo_url clone_depth
  repo_dir="$1"
  repo_url="$2"
  clone_depth="$3"

  if [ -d "${repo_dir}/.git" ]; then
    log "Updating ${repo_dir}"
    git -C "${repo_dir}" pull --ff-only
    return 0
  fi

  if [ -e "${repo_dir}" ]; then
    warn "${repo_dir} exists and is not a git repo; skipping"
    return 0
  fi

  log "Cloning ${repo_url}"
  if [ -n "${clone_depth}" ]; then
    git clone --depth=1 "${repo_url}" "${repo_dir}"
  else
    git clone "${repo_url}" "${repo_dir}"
  fi
}

install_or_update_repo \
  "${ZSH_CUSTOM}/themes/powerlevel10k" \
  "https://github.com/romkatv/powerlevel10k.git" \
  "depth"

install_or_update_repo \
  "${ZSH_CUSTOM}/plugins/zsh-autosuggestions" \
  "https://github.com/zsh-users/zsh-autosuggestions" \
  ""

install_or_update_repo \
  "${ZSH_CUSTOM}/plugins/zsh-syntax-highlighting" \
  "https://github.com/zsh-users/zsh-syntax-highlighting.git" \
  ""
