# Ubuntu 24.04 Developer Bootstrap (WSL2 + native)

Reproducible, idempotent bootstrap for Ubuntu 24.04 that installs a full developer distro and applies dotfiles via chezmoi.

## One-liner install

```bash
git clone https://github.com/w0rldx/dotfiles.git ~/.dotfiles && bash ~/.dotfiles/bootstrap/install.sh
```

## WSL2 systemd requirement (mandatory for Podman rootless)

Podman rootless socket activation uses `systemctl --user`, which requires systemd. If running in WSL2:

1. Edit `/etc/wsl.conf`:

```
[boot]
systemd=true
```

2. From Windows, run:

```powershell
wsl.exe --shutdown
```

3. Re-open your WSL distro and rerun the installer.

Microsoft Learn: https://learn.microsoft.com/windows/wsl/systemd

## VS Code on WSL (recommended)

- Install VS Code on Windows (not inside WSL).
- During install, enable "Add to PATH".
- Install the "Remote Development" extension pack (or at minimum the WSL extension).
- From WSL, run: `code .` — this opens the folder in VS Code and installs the VS Code Server in WSL automatically.

## VS Code on Ubuntu (optional)

Native Linux VS Code is opt-in. Set the environment variable to install via the official Microsoft apt repo:

```bash
INSTALL_VSCODE_LINUX=1 ./bootstrap/install.sh
```

## Neovim (tarball) + LazyVim Starter

- Neovim is installed from the official tarball into `/opt/nvim-linux-x86_64` (x86_64 only).
- PATH is set via zsh env: `export PATH="$PATH:/opt/nvim-linux-x86_64/bin"` (managed in `chezmoi/dot_zshenv`).
- LazyVim Starter setup:
  - If `~/.config/nvim` already looks like LazyVim (and `.git` is removed), the step is a NOOP.
  - Existing Neovim dirs are backed up with `.bak` (timestamped if needed).
  - Starter is cloned to `~/.config/nvim` and `.git` is removed.
  - Overlay dotfiles from `chezmoi/dot_config/nvim/` are applied via `rsync -a` (no deletions).

## Dotfiles with chezmoi

- Source state lives in `chezmoi/` (enabled via `.chezmoiroot`).
- The installer runs `chezmoi init --apply <repo>` on first run, then `chezmoi apply` on subsequent runs.
- Daily operations:
  - `chezmoi diff`
  - `chezmoi apply`
  - `chezmoi update`
- Neovim overlay files live in `chezmoi/dot_config/nvim/` and are layered on top of the LazyVim Starter base.

## Shell quality

- Lint: `./scripts/lint-shell.sh`
- Format: `./scripts/format-shell.sh`
- Prereqs:
  - ShellCheck is installed by the bootstrap (or via `sudo apt-get install -y shellcheck`).
  - shfmt via Go: `go install mvdan.cc/sh/v3/cmd/shfmt@latest`

## What this installs

- Apt packages: zsh, git, curl, ca-certificates, fzf, ripgrep, fd-find (+ fd symlink), eza, zoxide, rsync, podman, podman-compose
- From official sources/releases: GitHub CLI (apt repo), Oh-My-Zsh, Powerlevel10k theme, zsh-autosuggestions, zsh-syntax-highlighting, mise, lazygit, lazydocker, try, Neovim (tarball to /opt)
- Toolchains via mise: Rust (cargo), Go, .NET SDK, Node.js LTS, Bun

## Usage

- Run full bootstrap:
  ```bash
  ./bootstrap/install.sh
  ```
- Run doctor checks only:

  ```bash
  ./bootstrap/steps/90-doctor.sh
  ```

If the installer is not executable, either run:

```bash
chmod +x ./bootstrap/install.sh
```

or execute it explicitly:

```bash
bash ./bootstrap/install.sh
```
