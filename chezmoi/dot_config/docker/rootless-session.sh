#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

if command -v systemctl >/dev/null 2>&1 && [ -d /run/systemd/system ]; then
  exit 0
fi

if ! command -v dockerd-rootless.sh >/dev/null 2>&1; then
  exit 0
fi

runtime_dir="${XDG_RUNTIME_DIR:-$HOME/.docker/run}"
if [ ! -d "${runtime_dir}" ]; then
  mkdir -p "${runtime_dir}"
  chmod 700 "${runtime_dir}" 2>/dev/null || true
fi

socket="${runtime_dir}/docker.sock"
if [ -S "${socket}" ]; then
  if DOCKER_HOST="unix://${socket}" docker info >/dev/null 2>&1; then
    exit 0
  fi
fi

if command -v pgrep >/dev/null 2>&1; then
  if pgrep -u "$(id -u)" -f "dockerd-rootless.sh" >/dev/null 2>&1; then
    exit 0
  fi
fi

nohup env XDG_RUNTIME_DIR="${runtime_dir}" dockerd-rootless.sh --host="unix://${socket}" \
  >"${runtime_dir}/dockerd-rootless.log" 2>&1 &
