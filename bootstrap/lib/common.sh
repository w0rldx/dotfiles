#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

log() {
  printf '[INFO] %s\n' "$*"
}

warn() {
  printf '[WARN] %s\n' "$*" >&2
}

die() {
  printf '[ERROR] %s\n' "$*" >&2
  exit 1
}

have_cmd() {
  command -v "$1" >/dev/null 2>&1
}

need_cmd() {
  have_cmd "$1" || die "Missing command: $1"
}

is_wsl() {
  grep -qi microsoft /proc/version 2>/dev/null || [ -n "${WSL_INTEROP:-}" ] || [ -n "${WSL_DISTRO_NAME:-}" ]
}

is_ubuntu() {
  [ -r /etc/os-release ] || return 1
  . /etc/os-release
  [ "${ID:-}" = "ubuntu" ]
}

ubuntu_version_id() {
  [ -r /etc/os-release ] || return 1
  . /etc/os-release
  printf '%s' "${VERSION_ID:-}"
}

download_to_tmp() {
  local url tmp
  url="$1"
  tmp="$(mktemp)"
  log "Downloading ${url}"
  curl -fsSL "${url}" -o "${tmp}"
  printf '%s' "${tmp}"
}

link_file() {
  local src dest
  src="$1"
  dest="$2"

  if [ -L "${dest}" ] && [ "$(readlink "${dest}")" = "${src}" ]; then
    log "Link exists: ${dest}"
    return 0
  fi

  if [ -e "${dest}" ]; then
    warn "Skip existing path: ${dest}"
    return 0
  fi

  mkdir -p "$(dirname "${dest}")"
  ln -s "${src}" "${dest}"
  log "Linked ${dest} -> ${src}"
}
