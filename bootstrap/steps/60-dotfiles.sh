#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

BOOTSTRAP_ROOT="${BOOTSTRAP_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
# shellcheck source=bootstrap/lib/common.sh
. "${BOOTSTRAP_ROOT}/bootstrap/lib/common.sh"

zshrc_src="${BOOTSTRAP_ROOT}/dotfiles/zsh/.zshrc"
zshenv_src="${BOOTSTRAP_ROOT}/dotfiles/zsh/.zshenv"
aliases_src="${BOOTSTRAP_ROOT}/dotfiles/zsh/aliases.zsh"
gitconfig_src="${BOOTSTRAP_ROOT}/dotfiles/git/.gitconfig"
lazydocker_src="${BOOTSTRAP_ROOT}/dotfiles/lazydocker/config.yml"

link_file "${zshrc_src}" "${HOME}/.zshrc"
link_file "${zshenv_src}" "${HOME}/.zshenv"
link_file "${aliases_src}" "${HOME}/.config/zsh/aliases.zsh"
link_file "${gitconfig_src}" "${HOME}/.gitconfig"
link_file "${lazydocker_src}" "${HOME}/.config/lazydocker/config.yml"

nvim_dir="${HOME}/.config/nvim"
if [ ! -d "${nvim_dir}" ]; then
  log "Cloning AstroNvim"
  git clone --depth 1 https://github.com/AstroNvim/AstroNvim "${nvim_dir}"
else
  if [ ! -d "${nvim_dir}/.git" ]; then
    warn "${nvim_dir} exists and is not a git repo; skipping AstroNvim clone"
  fi
fi

user_src="${BOOTSTRAP_ROOT}/dotfiles/nvim/lua/user"
user_dest="${nvim_dir}/lua/user"
mkdir -p "${nvim_dir}/lua"
link_file "${user_src}" "${user_dest}"
