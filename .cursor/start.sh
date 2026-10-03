#!/usr/bin/env bash
# Start a local Prefect server, then the repo's scheduled jobs. Safe to rerun.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

# shellcheck disable=SC1091
source "$ROOT/.cursor/env.sh"

export PREFECT_API_URL="${PREFECT_API_URL:-http://127.0.0.1:4200/api}"

if [ ! -x "$ROOT/.venv/bin/python" ]; then
  echo "Python environment is missing. Run bash .cursor/install.sh first." >&2
  exit 1
fi
if ! command -v raku >/dev/null 2>&1; then
  echo "raku is not on PATH. Run bash .cursor/install.sh first." >&2
  exit 1
fi

mkdir -p /tmp/bitflip

server_healthy() {
  curl -fsS "http://127.0.0.1:4200/api/health" >/dev/null 2>&1
}

jobs_running() {
  pgrep -f "jobs/githubStars.py" >/dev/null && pgrep -f "jobs/checkETHBitfinex.py" >/dev/null
}

pane_dead() {
  local session="$1"
  tmux has-session -t "$session" 2>/dev/null || return 1
  [ "$(tmux list-panes -t "$session" -F '#{pane_dead}' 2>/dev/null | head -n 1)" = "1" ]
}

# A profile with PREFECT_API_URL keeps `prefect server start` from prompting,
# and gives the jobs a stable local API address. `profile use` refuses to
# switch while that server is down, so activate the profile directly.
if ! prefect --no-prompt profile inspect bitflip >/dev/null 2>&1; then
  prefect --no-prompt profile create bitflip
fi
python - <<'PY'
import prefect.settings

profiles = prefect.settings.load_profiles()
profiles.set_active("bitflip")
prefect.settings.save_profiles(profiles)
PY
prefect --no-prompt -p bitflip config set PREFECT_API_URL="$PREFECT_API_URL" >/dev/null

if server_healthy && jobs_running; then
  echo "bitflip jobs already running"
  exit 0
fi

if ! server_healthy; then
  if tmux has-session -t bitflip-prefect 2>/dev/null; then
    tmux kill-session -t bitflip-prefect
  fi
  tmux new-session -d -s bitflip-prefect -c "$ROOT" \
    "bash -c 'source \"$ROOT/.cursor/env.sh\" && exec prefect --no-prompt server start --host 0.0.0.0 --port 4200 --analytics-off' > /tmp/bitflip/prefect.log 2>&1"
  for _ in $(seq 1 60); do
    if server_healthy; then
      break
    fi
    if pane_dead bitflip-prefect; then
      echo "prefect server exited during startup" >&2
      cat /tmp/bitflip/prefect.log >&2 || true
      exit 1
    fi
    sleep 1
  done
  if ! server_healthy; then
    echo "prefect server did not become ready" >&2
    cat /tmp/bitflip/prefect.log >&2 || true
    exit 1
  fi
fi

if ! jobs_running; then
  if tmux has-session -t bitflip-jobs 2>/dev/null; then
    tmux kill-session -t bitflip-jobs
  fi
  tmux new-session -d -s bitflip-jobs -c "$ROOT" \
    "bash -c 'source \"$ROOT/.cursor/env.sh\" && export PREFECT_API_URL=\"$PREFECT_API_URL\" && exec bash \"$ROOT/start.sh\"' > /tmp/bitflip/jobs.log 2>&1"
  for _ in $(seq 1 90); do
    if jobs_running; then
      echo "bitflip jobs ready"
      exit 0
    fi
    if pane_dead bitflip-jobs; then
      echo "bitflip jobs exited during startup" >&2
      cat /tmp/bitflip/jobs.log >&2 || true
      exit 1
    fi
    sleep 1
  done
  echo "bitflip jobs did not become ready" >&2
  cat /tmp/bitflip/jobs.log >&2 || true
  exit 1
fi

echo "bitflip jobs ready"
