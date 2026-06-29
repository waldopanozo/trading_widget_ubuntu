#!/usr/bin/env bash
set -euo pipefail

mode="${1:-all}"
cache="/tmp/conky-btc.cache"
api="https://api.coingecko.com/api/v3/simple/price?ids=bitcoin&vs_currencies=usd&include_24hr_change=true"

print_mode() {
  case "$mode" in
    price) sed -n '1p' "$cache" ;;
    change) sed -n '2p' "$cache" ;;
    *) cat "$cache" ;;
  esac
}

if [[ -f "$cache" ]] && [[ $(($(date +%s) - $(stat -c %Y "$cache" 2>/dev/null || echo 0))) -lt 60 ]]; then
  print_mode
  exit 0
fi

json="$(curl -fsS --max-time 8 "$api" 2>/dev/null)" || {
  [[ -f "$cache" ]] && print_mode && exit 0
  [[ "$mode" == "price" ]] && echo "sin conexion" && exit 0
  [[ "$mode" == "change" ]] && echo "-- (24h)" && exit 0
  echo "BTC/USD: sin conexion"
  exit 0
}

price="$(jq -r '.bitcoin.usd' <<<"$json")"
change="$(jq -r '.bitcoin.usd_24h_change' <<<"$json")"

if [[ "$price" == "null" || "$change" == "null" ]]; then
  [[ -f "$cache" ]] && print_mode && exit 0
  [[ "$mode" == "price" ]] && echo "error API" && exit 0
  [[ "$mode" == "change" ]] && echo "-- (24h)" && exit 0
  echo "BTC/USD: error API"
  exit 0
fi

formatted_price="$(printf '%.0f' "$price" | sed ':a;s/\B[0-9]\{3\}\>/,&/;ta')"
sign="$(awk -v c="$change" 'BEGIN { if (c >= 0) print "+"; else print "" }')"
formatted_change="$(printf '%s%.2f%% (24h)' "$sign" "$change")"

{
  printf '%s USD\n' "$formatted_price"
  printf '%s\n' "$formatted_change"
} > "$cache"

print_mode
