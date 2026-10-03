#!/usr/bin/env bash
# Idempotent Bitflip dependency install for Cloud Agent environments.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

RAKUDO_VERSION="2026.04"
RAKUDO_DEB="rakudo-pkg-Ubuntu24.04_${RAKUDO_VERSION}-01_amd64.deb"
RAKUDO_URL="https://github.com/nxadm/rakudo-pkg/releases/download/v${RAKUDO_VERSION}/${RAKUDO_DEB}"
RAKUDO_SHA_URL="${RAKUDO_URL}.sha512"

install_node() {
  export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"
  if [ ! -s "$NVM_DIR/nvm.sh" ]; then
    echo "nvm is required to install the Node version in .nvmrc" >&2
    exit 1
  fi
  # nvm is not safe under `set -u`.
  set +u
  # shellcheck disable=SC1091
  . "$NVM_DIR/nvm.sh"
  nvm install
  local ver node_dir
  # `nvm version` with no args follows whichever `node` is first on PATH.
  # Resolve the .nvmrc major instead so /exec-daemon/node cannot win.
  ver="$(nvm version "$(tr -d '[:space:]' < "$ROOT/.nvmrc")")"
  if [ -z "$ver" ] || [ "$ver" = "N/A" ] || [ "$ver" = "system" ]; then
    echo "nvm did not install the Node version from .nvmrc (got '${ver:-empty}')" >&2
    exit 1
  fi
  nvm alias default "$ver" >/dev/null
  set -u
  # `nvm which` follows the first `node` on PATH. In this image that is
  # /exec-daemon/node, which is not the version .nvmrc selected.
  node_dir="${NVM_DIR}/versions/node/${ver}/bin"
  if [ ! -x "${node_dir}/node" ]; then
    echo "Node ${ver} is missing at ${node_dir}" >&2
    exit 1
  fi
  sudo ln -sfn "$node_dir" /opt/node-20
  export PATH="/opt/node-20:${PATH}"
  hash -r
  echo "node $(node -v) npm $(npm -v)"
}

install_python() {
  if ! command -v uv >/dev/null 2>&1; then
    curl -LsSf https://astral.sh/uv/install.sh | sh
  fi
  export PATH="${HOME}/.local/bin:${PATH}"
  sudo ln -sfn "${HOME}/.local/bin/uv" /usr/local/bin/uv
  if [ -x "${HOME}/.local/bin/uvx" ]; then
    sudo ln -sfn "${HOME}/.local/bin/uvx" /usr/local/bin/uvx
  fi

  local py_version
  py_version="$(tr -d '[:space:]' < "$ROOT/.python-version")"
  uv python install "$py_version"
  if [ ! -x "$ROOT/.venv/bin/python" ] || ! "$ROOT/.venv/bin/python" -c "import sys; raise SystemExit(0 if sys.version.startswith('${py_version}') else 1)"; then
    uv venv "$ROOT/.venv" --python "$py_version" --clear
  fi
  uv pip install --python "$ROOT/.venv/bin/python" -r "$ROOT/requirements.txt"
  sudo ln -sfn "$ROOT/.venv/bin/python" /usr/local/bin/bitflip-python
  echo "python $($ROOT/.venv/bin/python -V)"
}

install_rakudo() {
  if ! dpkg -s rakudo-pkg >/dev/null 2>&1; then
    sudo apt-get update
    sudo apt-get install -y --no-install-recommends ca-certificates curl build-essential libssl-dev
    local tmp
    tmp="$(mktemp -d)"
    curl -fsSL -o "${tmp}/${RAKUDO_DEB}" "$RAKUDO_URL"
    curl -fsSL -o "${tmp}/${RAKUDO_DEB}.sha512" "$RAKUDO_SHA_URL"
    (
      cd "$tmp"
      # The checksum file records the upstream filename.
      sha512sum -c "${RAKUDO_DEB}.sha512"
    )
    sudo apt-get install -y "${tmp}/${RAKUDO_DEB}"
    rm -rf "$tmp"
  fi

  if [ -f /etc/profile.d/rakudo-pkg.sh ]; then
    # shellcheck disable=SC1091
    . /etc/profile.d/rakudo-pkg.sh
  fi
  sudo ln -sfn /opt/rakudo-pkg/bin/raku /usr/local/bin/raku
  sudo ln -sfn /opt/rakudo-pkg/bin/raku /usr/local/bin/rakudo

  if [ ! -x "${HOME}/.raku/bin/zef" ]; then
    /opt/rakudo-pkg/bin/install-zef
  fi
  sudo ln -sfn "${HOME}/.raku/bin/zef" /usr/local/bin/zef
  export PATH="${HOME}/.raku/bin:/opt/rakudo-pkg/bin:${PATH}"
  hash -r
  raku -v
  zef --version
}

install_raku_modules() {
  # Required by jobs/checkETHBitfinex.py -> scripts/bitfinex.raku.
  # IO::Socket::SSL is what HTTP::UserAgent needs for https:// exchange APIs.
  zef install --/test HTTP::UserAgent JSON::Fast IO::Socket::SSL

  # Imported by the other exchange scripts. A missing optional module
  # must not hide a failed install of the ticker client above.
  local module
  # Other scripts import these. Crypt::Hmac and OpenSSL::HMAC are not in the ecosystem.
  for module in MIME::Base64 Env::Dotenv Base64 Shell::Command; do
    zef install --/test "$module"
  done

  raku -c "$ROOT/scripts/bitfinex.raku"
  raku -e 'use IO::Socket::SSL; use HTTP::UserAgent; say "raku https client ready"'
}

write_profile() {
  sudo tee /etc/profile.d/bitflip-dev.sh >/dev/null <<'EOF'
export PATH="/opt/node-20:/workspace/.venv/bin:${HOME}/.local/bin:${HOME}/.raku/bin:/opt/rakudo-pkg/bin:/opt/rakudo-pkg/share/perl6/site/bin:${PATH}"
EOF
}

install_node
npm ci
install_python
install_rakudo
install_raku_modules
write_profile

# shellcheck disable=SC1091
source "$ROOT/.cursor/env.sh"
node_major="$(node -v | sed 's/^v//' | cut -d. -f1)"
if [ "$node_major" != "20" ]; then
  echo "expected Node 20 from .nvmrc, got $(node -v) ($(command -v node))" >&2
  exit 1
fi
echo "install complete: node $(node -v), $(python -V), raku $(raku -v | head -n 1)"
