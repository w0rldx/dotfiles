#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

BOOTSTRAP_ROOT="${BOOTSTRAP_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
# shellcheck source=bootstrap/lib/common.sh
. "${BOOTSTRAP_ROOT}/bootstrap/lib/common.sh"

need_cmd curl
need_cmd tar

arch="$(uname -m)"
if [ "${arch}" != "x86_64" ]; then
  die "Unsupported architecture for Neovim tarball install: ${arch}. Expected x86_64."
fi

tmpdir="$(mktemp -d)"
cleanup() {
  rm -rf "${tmpdir}"
}
trap cleanup EXIT

log "Downloading Neovim tarball from https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz"
(
  cd "${tmpdir}"
  curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz
  sudo rm -rf /opt/nvim-linux-x86_64
  sudo tar -C /opt -xzf nvim-linux-x86_64.tar.gz
)
