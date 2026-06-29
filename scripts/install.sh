#!/usr/bin/env bash
set -euo pipefail

WIDGET_DIR="$(cd "$(dirname "$0")/.." && pwd)"
CONFIG_DIR="$HOME/.config/conky"
AUTOSTART_DIR="$HOME/.config/autostart"

echo "Instalando Panel Escritorio Conky desde: $WIDGET_DIR"

mkdir -p "$CONFIG_DIR" "$AUTOSTART_DIR"

chmod +x "$WIDGET_DIR/scripts/"*.sh "$WIDGET_DIR/scripts/"*.py
chmod +x "$WIDGET_DIR/scripts/conky-launch.sh"

ln -sf "$WIDGET_DIR/conky.conf" "$CONFIG_DIR/conky.conf"
ln -sf "$WIDGET_DIR/autostart/panel-escritorio-conky.desktop" "$AUTOSTART_DIR/panel-escritorio-conky.desktop"

if ! command -v conky >/dev/null; then
  echo "Conky no esta instalado. Instala con: sudo apt install conky-all"
  exit 1
fi

if ! python3 -c "import PIL" 2>/dev/null; then
  echo "Falta Pillow. Instala con: sudo apt install python3-pil"
  exit 1
fi

if ! command -v jq >/dev/null; then
  echo "Falta jq. Instala con: sudo apt install jq"
  exit 1
fi

"$WIDGET_DIR/scripts/conky-clocks-panel.sh"

echo "Listo."
echo "Iniciar ahora: conky -c $WIDGET_DIR/conky.conf &"
echo "Detener: pkill conky"
