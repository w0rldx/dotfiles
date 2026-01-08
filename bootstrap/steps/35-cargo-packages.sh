#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

BOOTSTRAP_ROOT="${BOOTSTRAP_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
# shellcheck source=bootstrap/lib/common.sh
. "${BOOTSTRAP_ROOT}/bootstrap/lib/common.sh"

packages_file="${BOOTSTRAP_ROOT}/bootstrap/packages/cargo.txt"

trim() {
  local s
  s="$1"
  s="${s#"${s%%[![:space:]]*}"}"
  s="${s%"${s##*[![:space:]]}"}"
  printf '%s' "${s}"
}

if ! have_cmd cargo; then
  warn "cargo not found; skipping cargo packages"
  exit 0
fi

if [ ! -f "${packages_file}" ]; then
  warn "Cargo package list not found: ${packages_file}"
  exit 0
fi

installed_list="$(cargo install --list 2>/dev/null || true)"

count=0
while IFS= read -r line || [ -n "${line}" ]; do
  line="${line%%#*}"
  line="$(trim "${line}")"
  if [ -z "${line}" ]; then
    continue
  fi

  count=$((count + 1))
  if printf '%s\n' "${installed_list}" | grep -q "^${line} v"; then
    log "cargo package already installed: ${line}"
  else
    log "Installing cargo package: ${line}"
    cargo install "${line}"
  fi
done <"${packages_file}"

if [ "${count}" -eq 0 ]; then
  log "No cargo packages configured"
fi
