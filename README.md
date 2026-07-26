# developer-environment

Ryse Software (Vitality South) developer environment for Debian 13 on
WSL2, with VS Code running from inside WSL. Everything installs per-user
into your home directory except the apt baseline.

## Fresh machine

```bash
sudo apt update && sudo apt install -y git curl   # just enough to clone
git clone git@github.com:Vitality-South/developer-environment.git
~/developer-environment/provision.sh   # OS baseline via sudo apt
~/developer-environment/setup.sh       # per-user toolchains
# close and re-open your shell when done
```

## Keeping up to date

Re-run either script any time - both are idempotent. setup.sh always
tracks the latest: stable Go, LTS node (installed with nvm and set as the
default), bun, and the Go/npm tools at @latest. Detailed output goes to
~/.vs-dev-setup.log; progress lines print to the terminal.

## What's what

- setup.sh - toolchains and dev tools: latest stable Go (auto-detected
  from go.dev) plus gopls, staticcheck, golangci-lint, dlv and friends;
  nvm + latest LTS node as default; bun; AWS CLI v2; the protobuf /
  gRPC / Connect toolchain; and the npm global tool set. The first run on
  a fresh machine also appends the PATH block to ~/.bashrc (guarded by
  VS_DEVENV_IS_SET).
- provision.sh - baseline Debian packages via sudo apt (build tools,
  ripgrep/fd/fzf, jq, tmux, shellcheck, db clients, network debugging,
  imagemagick, ...) plus fd/bat name shims in ~/bin.

New Vue or Vite projects need no global CLI - scaffold on demand with
`npm create vue@latest` / `npm create vite@latest` (or `bun create vue`);
these always fetch the current scaffolder.
- old.setup.debian12.sh - the previous full Debian 12 script, kept for
  reference.
