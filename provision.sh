#!/usr/bin/env bash
# Baseline OS toolset for a Ryse Software / Vitality South dev machine
# (Debian 13 on WSL2). apt-only and idempotent; safe to re-run any time.
# Language toolchains (Go, node via nvm, bun) live in setup.sh, not here.
set -u

command -v apt-get >/dev/null || { echo "provision.sh: no apt-get - Debian only" >&2; exit 1; }

PKGS=(
  # build + version control
  build-essential pkg-config git git-lfs gh
  # search + files
  ripgrep fd-find fzf tree bat ncdu file rsync unzip zip p7zip-full zstd moreutils
  # data wrangling
  jq yq sqlite3 xxd
  # editor + terminal
  vim tmux bash-completion
  # shell-script quality + watch-rerun dev loops
  shellcheck entr
  # python tooling
  python3-pip python3-venv pipx
  # network + system debugging
  curl wget httpie bind9-dnsutils netcat-openbsd mtr-tiny nmap whois
  openssl ca-certificates lsof strace htop btop psmisc
  # db clients
  postgresql-client default-mysql-client
  # image ops (favicons, screenshots, resizes)
  imagemagick
)

sudo apt-get update

# Skip names this release doesn't know (renames like dnsutils->bind9-dnsutils)
# so one bad name can't fail the whole transaction.
install=() missing=()
for p in "${PKGS[@]}"; do
  if apt-cache policy "$p" 2>/dev/null | grep -q "Candidate: [^(]"; then
    install+=("$p")
  else
    missing+=("$p")
  fi
done
[ "${#missing[@]}" -gt 0 ] && echo "skip (unknown in this release): ${missing[*]}"
sudo apt-get install -y "${install[@]}"

# Debian names fd and bat differently; give them their usual names in ~/bin.
mkdir -p "$HOME/bin"
[ -x /usr/bin/fdfind ] && [ ! -e "$HOME/bin/fd" ] && \
  ln -s /usr/bin/fdfind "$HOME/bin/fd" && echo "link ~/bin/fd -> fdfind"
[ -x /usr/bin/batcat ] && [ ! -e "$HOME/bin/bat" ] && \
  ln -s /usr/bin/batcat "$HOME/bin/bat" && echo "link ~/bin/bat -> batcat"

echo "provision.sh: done (log out and back in once if ~/bin was just created)"
