export PATH="$HOME/.local/bin:$PATH"

export DOCKER_HOST="unix://${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/podman/podman.sock"
export PODMAN_COMPOSE_PROVIDER="podman-compose"

if command -v mise >/dev/null 2>&1; then
  eval "$(mise activate zsh)"
fi
