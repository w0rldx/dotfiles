#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

BOOTSTRAP_ROOT="${BOOTSTRAP_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
# shellcheck source=bootstrap/lib/common.sh
. "${BOOTSTRAP_ROOT}/bootstrap/lib/common.sh"

need_cmd curl
need_cmd tar

arch="$(uname -m)"
case "${arch}" in
  x86_64)
    lazygit_arch="x86_64"
    nvim_arch="x86_64"
    ;;
  aarch64|arm64)
    lazygit_arch="arm64"
    nvim_arch="arm64"
    ;;
  *)
    die "Unsupported architecture: ${arch}"
    ;;
 esac

install_gh() {
  if have_cmd gh; then
    log "gh already installed"
    return 0
  fi

  log "Setting up GitHub CLI apt repository"
  sudo mkdir -p /usr/share/keyrings

  if [ ! -f /usr/share/keyrings/githubcli-archive-keyring.gpg ]; then
    key_url="https://cli.github.com/packages/githubcli-archive-keyring.gpg"
    tmpfile="$(download_to_tmp "${key_url}")"
    sudo install -m 0644 "${tmpfile}" /usr/share/keyrings/githubcli-archive-keyring.gpg
    rm -f "${tmpfile}"
  fi

  list_file="/etc/apt/sources.list.d/github-cli.list"
  repo_line="deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main"

  if [ ! -f "${list_file}" ] || ! grep -q "cli.github.com/packages" "${list_file}"; then
    echo "${repo_line}" | sudo tee "${list_file}" >/dev/null
  fi

  sudo apt-get update
  sudo apt-get install -y gh
}

latest_github_tag() {
  local repo tag
  repo="$1"
  tag="$(curl -fsSLI "https://github.com/${repo}/releases/latest" | tr -d '\r' | awk -F'/' '/^location:/I {print $NF}')"
  if [ -z "${tag}" ]; then
    return 1
  fi
  printf '%s' "${tag}"
}

install_lazygit() {
  if have_cmd lazygit; then
    log "lazygit already installed"
    return 0
  fi

  tag="$(latest_github_tag "jesseduffield/lazygit")" || die "Unable to resolve lazygit release tag"
  if [ -z "${tag}" ]; then
    die "Unable to resolve lazygit release tag"
  fi
  version="${tag#v}"
  asset="lazygit_${version}_Linux_${lazygit_arch}.tar.gz"
  url="https://github.com/jesseduffield/lazygit/releases/download/${tag}/${asset}"

  tmpfile="$(download_to_tmp "${url}")"
  tmpdir="$(mktemp -d)"
  tar -xzf "${tmpfile}" -C "${tmpdir}"
  mkdir -p "${HOME}/.local/bin"
  install -m 0755 "${tmpdir}/lazygit" "${HOME}/.local/bin/lazygit"
  rm -rf "${tmpfile}" "${tmpdir}"
}

install_lazydocker() {
  if have_cmd lazydocker; then
    log "lazydocker already installed"
    return 0
  fi

  script_url="https://raw.githubusercontent.com/jesseduffield/lazydocker/master/scripts/install_update_linux.sh"
  tmpfile="$(download_to_tmp "${script_url}")"
  bash "${tmpfile}"
  rm -f "${tmpfile}"
}

install_try() {
  if [ -x "${HOME}/.local/bin/try" ]; then
    log "try already installed"
    return 0
  fi

  script_url="https://raw.githubusercontent.com/binpash/try/master/try"
  tmpfile="$(download_to_tmp "${script_url}")"
  mkdir -p "${HOME}/.local/bin"
  install -m 0755 "${tmpfile}" "${HOME}/.local/bin/try"
  rm -f "${tmpfile}"
}

resolve_nvim_url() {
  local base
  base="https://github.com/neovim/neovim/releases/latest/download"

  if [ "${nvim_arch}" = "x86_64" ]; then
    candidates=(
      "nvim-linux-x86_64.tar.gz"
      "nvim-linux64.tar.gz"
      "nvim-linux-x86_64.appimage"
      "nvim.appimage"
    )
  else
    candidates=(
      "nvim-linux-arm64.tar.gz"
      "nvim-linux-aarch64.tar.gz"
    )
  fi

  for asset in "${candidates[@]}"; do
    url="${base}/${asset}"
    if curl -fsSLI "${url}" >/dev/null 2>&1; then
      printf '%s' "${url}"
      return 0
    fi
  done

  return 1
}

install_neovim() {
  if have_cmd nvim; then
    log "neovim already installed"
    return 0
  fi

  url="$(resolve_nvim_url)" || die "Unable to resolve Neovim release asset"
  tmpfile="$(download_to_tmp "${url}")"
  mkdir -p "${HOME}/.local/bin"

  case "${url}" in
    *.appimage)
      install -m 0755 "${tmpfile}" "${HOME}/.local/bin/nvim"
      rm -f "${tmpfile}"
      ;;
    *.tar.gz)
      tmpdir="$(mktemp -d)"
      tar -xzf "${tmpfile}" -C "${tmpdir}"
      nvim_path="$(find "${tmpdir}" -type f -path '*/bin/nvim' | head -n 1)"
      if [ -z "${nvim_path}" ]; then
        rm -rf "${tmpfile}" "${tmpdir}"
        die "Neovim binary not found in release archive"
      fi
      install -m 0755 "${nvim_path}" "${HOME}/.local/bin/nvim"
      rm -rf "${tmpfile}" "${tmpdir}"
      ;;
    *)
      rm -f "${tmpfile}"
      die "Unsupported Neovim asset type"
      ;;
  esac
}

install_gh
install_lazygit
install_lazydocker
install_try
install_neovim
