#!/usr/bin/env bash
set -u

WIDGET_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CONFIG="$WIDGET_ROOT/conky.conf"
LOG_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/panel-escritorio-conky"
LOG="$LOG_DIR/launch.log"
WORKER_PID_FILE="$LOG_DIR/launch.pid"
RUNTIME="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
MAX_ATTEMPTS=120
RETRY_INTERVAL=2

conky_running() {
  pgrep -f "${WIDGET_ROOT}/conky.conf" >/dev/null 2>&1
}

xwayland_ready() {
  local display_num socket_path auth_file
  export DISPLAY="${DISPLAY:-:0}"
  display_num="${DISPLAY#:}"
  socket_path="/tmp/.X11-unix/X${display_num}"
  auth_file="$(ls -t "${RUNTIME}"/.mutter-Xwaylandauth.* 2>/dev/null | head -1 || true)"
  [[ -n "$auth_file" ]] || return 1
  export XAUTHORITY="$auth_file"
  [[ -S "$socket_path" ]] || return 1
  xdpyinfo >/dev/null 2>&1
}

try_launch_conky() {
  "$WIDGET_ROOT/scripts/conky-clocks-panel.sh" >>"$LOG" 2>&1 || true

  {
    echo "=== $(date -Is) lanzando Conky ==="
    echo "WAYLAND_DISPLAY=${WAYLAND_DISPLAY:-}"
    echo "XDG_SESSION_TYPE=${XDG_SESSION_TYPE:-}"
    echo "DISPLAY=${DISPLAY:-}"
    echo "XAUTHORITY=${XAUTHORITY:-}"
  } >>"$LOG"

  if conky -d -c "$CONFIG" >>"$LOG" 2>&1; then
    sleep 1
    conky_running
  else
    return 1
  fi
}

worker_main() {
  trap 'rm -f "$WORKER_PID_FILE"' EXIT
  echo "$$" >"$WORKER_PID_FILE"

  for attempt in $(seq 1 "$MAX_ATTEMPTS"); do
    if conky_running; then
      echo "$(date -Is) Conky activo (intento ${attempt})" >>"$LOG"
      exit 0
    fi

    if ! pgrep -x gnome-shell >/dev/null 2>&1; then
      echo "$(date -Is) intento ${attempt}: esperando gnome-shell" >>"$LOG"
      sleep "$RETRY_INTERVAL"
      continue
    fi

    if ! xwayland_ready; then
      echo "$(date -Is) intento ${attempt}: esperando Xwayland (DISPLAY=${DISPLAY:-}:0)" >>"$LOG"
      sleep "$RETRY_INTERVAL"
      continue
    fi

    if try_launch_conky; then
      echo "$(date -Is) Conky iniciado en intento ${attempt}" >>"$LOG"
      exit 0
    fi

    pkill -f "${WIDGET_ROOT}/conky.conf" >/dev/null 2>&1 || true
    echo "$(date -Is) intento ${attempt}: fallo al iniciar, reintentando..." >>"$LOG"
    sleep "$RETRY_INTERVAL"
  done

  echo "$(date -Is) ERROR: agotados ${MAX_ATTEMPTS} intentos" >>"$LOG"
  exit 1
}

if [[ "${XDG_SESSION_TYPE:-}" != "wayland" ]]; then
  exit 0
fi

mkdir -p "$LOG_DIR"

if conky_running; then
  exit 0
fi

if [[ "${1:-}" == "--worker" ]]; then
  worker_main
fi

if [[ -f "$WORKER_PID_FILE" ]]; then
  worker_pid="$(cat "$WORKER_PID_FILE" 2>/dev/null || true)"
  if [[ -n "$worker_pid" ]] && kill -0 "$worker_pid" 2>/dev/null; then
    exit 0
  fi
fi

nohup "$0" --worker >>"$LOG" 2>&1 &
echo $! >"$WORKER_PID_FILE"
exit 0
