#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

BOOTSTRAP_ROOT="${BOOTSTRAP_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
# shellcheck source=bootstrap/lib/common.sh
. "${BOOTSTRAP_ROOT}/bootstrap/lib/common.sh"

packages_file="${BOOTSTRAP_ROOT}/bootstrap/packages/npm.txt"

trim() {
  local s
  s="$1"
  s="${s#"${s%%[![:space:]]*}"}"
  s="${s%"${s##*[![:space:]]}"}"
  printf '%s' "${s}"
}

if ! have_cmd npm; then
  warn "npm not found; skipping npm packages"
  exit 0
fi

if [ ! -f "${packages_file}" ]; then
  warn "NPM package list not found: ${packages_file}"
  exit 0
fi

count=0
while IFS= read -r line || [ -n "${line}" ]; do
  line="${line%%#*}"
  line="$(trim "${line}")"
  if [ -z "${line}" ]; then
    continue
  fi

  count=$((count + 1))
  if npm list -g --depth=0 "${line}" >/dev/null 2>&1; then
    log "npm package already installed: ${line}"
  else
    log "Installing npm package: ${line}"
    npm install -g "${line}"
  fi
done <"${packages_file}"

if [ "${count}" -eq 0 ]; then
  log "No npm packages configured"
fi
