#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

BOOTSTRAP_ROOT="${BOOTSTRAP_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
# shellcheck source=bootstrap/lib/common.sh
. "${BOOTSTRAP_ROOT}/bootstrap/lib/common.sh"

need_cmd sudo
need_cmd curl

target_user="${SUDO_USER:-${USER:-$(id -un)}}"
if [ -z "${target_user}" ]; then
  die "Unable to determine target user."
fi
if [ "${target_user}" = "root" ]; then
  die "Run this step as a regular user (not root)."
fi

target_uid="$(id -u "${target_user}")"
target_home="$(getent passwd "${target_user}" | cut -d: -f6)"
if [ -z "${target_home}" ]; then
  target_home="${HOME}"
fi

run_as_user() {
  if [ "$(id -un)" = "${target_user}" ]; then
    "$@"
  else
    sudo -u "${target_user}" -H "$@"
  fi
}

conflicting_packages=(
  docker.io
  docker-doc
  docker-compose
  docker-compose-v2
  podman-docker
  containerd
  runc
)

remove_packages=()
for pkg in "${conflicting_packages[@]}"; do
  if dpkg -s "${pkg}" >/dev/null 2>&1; then
    remove_packages+=("${pkg}")
  fi
done

if [ "${#remove_packages[@]}" -gt 0 ]; then
  log "Removing conflicting container packages: ${remove_packages[*]}"
  sudo apt-get remove -y "${remove_packages[@]}"
else
  log "No conflicting container packages installed"
fi

if ! have_cmd gpg; then
  log "Installing gnupg for Docker apt key"
  sudo apt-get update
  sudo apt-get install -y gnupg
fi

log "Adding Docker apt repository"
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

arch="$(dpkg --print-architecture)"
# shellcheck disable=SC1091
codename="$(. /etc/os-release && printf '%s' "${VERSION_CODENAME}")"
repo_line="deb [arch=${arch} signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu ${codename} stable"
if [ ! -f /etc/apt/sources.list.d/docker.list ] || ! grep -Fxq "${repo_line}" /etc/apt/sources.list.d/docker.list; then
  printf '%s\n' "${repo_line}" | sudo tee /etc/apt/sources.list.d/docker.list >/dev/null
fi

log "Installing Docker Engine packages"
sudo apt-get update
sudo apt-get install -y \
  docker-ce \
  docker-ce-cli \
  containerd.io \
  docker-buildx-plugin \
  docker-compose-plugin \
  docker-ce-rootless-extras \
  uidmap

ensure_subid() {
  local file flag
  file="$1"
  flag="$2"
  if ! grep -q "^${target_user}:" "${file}" 2>/dev/null; then
    log "Adding subid range in ${file} for ${target_user}"
    sudo usermod "${flag}" "100000-65536" "${target_user}"
  fi
}

ensure_subid /etc/subuid --add-subuids
ensure_subid /etc/subgid --add-subgids

need_cmd dockerd-rootless-setuptool.sh
need_cmd dockerd-rootless.sh

systemd_user_available=0
if have_cmd systemctl && [ -d /run/systemd/system ]; then
  if run_as_user systemctl --user show-environment >/dev/null 2>&1; then
    systemd_user_available=1
  fi
fi

runtime_dir="/run/user/${target_uid}"
if [ "${systemd_user_available}" -eq 0 ]; then
  runtime_dir="${target_home}/.docker/run"
fi

docker_host="unix://${runtime_dir}/docker.sock"

log "Configuring rootless Docker for ${target_user}"
if [ "${systemd_user_available}" -eq 0 ]; then
  run_as_user mkdir -p "${runtime_dir}"
  run_as_user chmod 700 "${runtime_dir}" 2>/dev/null || true
  run_as_user env XDG_RUNTIME_DIR="${runtime_dir}" dockerd-rootless-setuptool.sh install
else
  run_as_user dockerd-rootless-setuptool.sh install
fi

if [ "${systemd_user_available}" -eq 1 ]; then
  if have_cmd loginctl; then
    sudo loginctl enable-linger "${target_user}" >/dev/null 2>&1 || true
  fi
  run_as_user systemctl --user daemon-reload
  if ! run_as_user systemctl --user enable --now docker; then
    warn "Failed to enable docker user service; falling back to manual start."
    systemd_user_available=0
  fi
fi

if [ "${systemd_user_available}" -eq 0 ]; then
  if ! run_as_user env DOCKER_HOST="${docker_host}" docker info >/dev/null 2>&1; then
    log "Starting rootless dockerd in the user session"
    run_as_user env XDG_RUNTIME_DIR="${runtime_dir}" DOCKER_HOST="${docker_host}" sh -c \
      "nohup dockerd-rootless.sh --host=\"${docker_host}\" >\"${runtime_dir}/dockerd-rootless.log\" 2>&1 &"
  fi
fi

docker_ready=0
for _ in 1 2 3 4 5; do
  if run_as_user env DOCKER_HOST="${docker_host}" docker info >/dev/null 2>&1; then
    docker_ready=1
    break
  fi
  sleep 1
done

if [ "${docker_ready}" -eq 1 ]; then
  log "Docker rootless is running"
  if run_as_user env DOCKER_HOST="${docker_host}" docker run --rm hello-world >/dev/null 2>&1; then
    log "OK: docker run hello-world"
  else
    warn "docker run hello-world failed (network/image access?)"
  fi
else
  warn "Docker rootless is not responding yet (check dockerd-rootless logs)."
fi
