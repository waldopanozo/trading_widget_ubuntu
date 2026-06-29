#!/usr/bin/env bash
set -euo pipefail

WIDGET_DIR="$(cd "$(dirname "$0")/.." && pwd)"
CONFIG_DIR="$HOME/.config/conky"
AUTOSTART_DIR="$HOME/.config/autostart"
CONKY_CONF="$WIDGET_DIR/conky.conf"
DESKTOP_FILE="$AUTOSTART_DIR/panel-escritorio-conky.desktop"

detect_net_interface() {
  local iface
  iface="$(ip route get 1.1.1.1 2>/dev/null | awk '{for (i = 1; i <= NF; i++) if ($i == "dev") print $(i + 1)}')"
  if [[ -n "$iface" ]]; then
    echo "$iface"
    return
  fi
  iface="$(ip -o link show up 2>/dev/null | awk -F': ' '!/ lo:/ {print $2; exit}')"
  echo "${iface:-eth0}"
}

render_template() {
  local template="$1"
  local output="$2"
  sed \
    -e "s|@WIDGET_DIR@|${WIDGET_DIR}|g" \
    -e "s|@NET_INTERFACE@|${NET_INTERFACE}|g" \
    "$template" >"$output"
}

echo "Installing Desktop Panel Conky from: $WIDGET_DIR"

mkdir -p "$CONFIG_DIR" "$AUTOSTART_DIR"

chmod +x "$WIDGET_DIR/scripts/"*.sh "$WIDGET_DIR/scripts/"*.py

if ! command -v conky >/dev/null; then
  echo "Conky is not installed. Run: sudo apt install conky-all"
  exit 1
fi

if ! python3 -c "import PIL" 2>/dev/null; then
  echo "Pillow is missing. Run: sudo apt install python3-pil"
  exit 1
fi

if ! command -v jq >/dev/null; then
  echo "jq is missing. Run: sudo apt install jq"
  exit 1
fi

NET_INTERFACE="$(detect_net_interface)"
echo "Detected network interface: $NET_INTERFACE"

render_template "$WIDGET_DIR/conky.conf.in" "$CONKY_CONF"

rm -f "$DESKTOP_FILE"
render_template "$WIDGET_DIR/autostart/panel-escritorio-conky.desktop.in" "$DESKTOP_FILE"

ln -sf "$CONKY_CONF" "$CONFIG_DIR/panel-escritorio-conky.conf"

"$WIDGET_DIR/scripts/conky-clocks-panel.sh"

echo "Done."
echo "Start now: conky -c $CONKY_CONF &"
echo "Stop: pkill conky"
