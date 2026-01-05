# Ubuntu 24.04 Developer Bootstrap (WSL2 + native)

Reproducible, idempotent bootstrap for Ubuntu 24.04 that installs a full developer distro and links dotfiles.

## One-liner install

Replace `<REPO_URL>` with your GitHub repo URL:

```bash
git clone <REPO_URL> ~/.dotfiles && ~/.dotfiles/bootstrap/install.sh
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

## What this installs

- Apt packages: zsh, git, curl, ca-certificates, fzf, ripgrep, fd-find (+ fd symlink), eza, zoxide, podman, podman-compose
- From official sources/releases: GitHub CLI (apt repo), Oh-My-Zsh, Powerlevel10k theme, zsh-autosuggestions, zsh-syntax-highlighting, mise, lazygit, lazydocker, try, Neovim
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

## Notes & assumptions

- Ubuntu 24.04 only. Other distros/versions are rejected by preflight.
- WSL best practice: keep repos inside the Linux filesystem (e.g. `~/src`), not `/mnt/c`.
- Existing dotfiles are not overwritten; the installer skips paths that already exist.
- After opening a new shell, run `p10k configure` to personalize the Powerlevel10k prompt.
- Neovim and lazygit use GitHub “latest release” assets resolved at install time.
- `zsh-syntax-highlighting` must remain last in the plugins list; this repo enforces that ordering.
- The mise installer URL is assumed to be `https://mise.run` (official). Update it if upstream changes.
- For deterministic toolchains, pin exact versions in `mise/mise.toml`. A `mise.lock` can be generated and committed using mise tooling when needed.
