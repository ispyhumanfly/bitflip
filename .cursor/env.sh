#!/usr/bin/env bash
# Toolchain PATH for Bitflip install and start. Safe to source under `set -u`.

_bitflip_nounset=0
case $- in
  *u*) _bitflip_nounset=1 ;;
esac
set +u

BITFLIP_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"
if [ -s "$NVM_DIR/nvm.sh" ]; then
  # shellcheck disable=SC1091
  . "$NVM_DIR/nvm.sh"
  if [ -f "$BITFLIP_ROOT/.nvmrc" ]; then
    nvm use --silent >/dev/null 2>&1 || true
  fi
fi

if [ "$_bitflip_nounset" -eq 1 ]; then
  set -u
fi
unset _bitflip_nounset

export PATH="/opt/node-20:${BITFLIP_ROOT}/.venv/bin:${HOME}/.local/bin:${HOME}/.raku/bin:/opt/rakudo-pkg/bin:/opt/rakudo-pkg/share/perl6/site/bin:${PATH}"
hash -r 2>/dev/null || true
