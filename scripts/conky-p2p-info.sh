#!/usr/bin/env bash
set -euo pipefail

# Usage: conky-p2p-info.sh <py|bo|all> [mode]
# mode: buy | sell | line (default: line = "C: X  V: Y")
country="${1:-all}"
mode="${2:-line}"

ENV_FILE="${HOME}/.config/conky-p2p.env"
if [[ -f "$ENV_FILE" ]]; then
  # shellcheck disable=SC1090
  source "$ENV_FILE"
fi
API_KEY="${TRADERSWORLD_API_KEY:-}"
if [[ -z "$API_KEY" ]]; then
  echo "API key not configured in ${ENV_FILE}"
  exit 1
fi

BASE_URL="https://tradersworld.top/api/public/p2p"
CACHE_TTL=60

fetch_country() {
  local cc="$1"
  local cache="/tmp/conky-p2p-${cc}.cache"

  if [[ -f "$cache" ]] && [[ $(($(date +%s) - $(stat -c %Y "$cache" 2>/dev/null || echo 0))) -lt $CACHE_TTL ]]; then
    cat "$cache"
    return 0
  fi

  local json
  json="$(curl -fsS --max-time 8 -H "X-API-Key: ${API_KEY}" "${BASE_URL}/${cc}" 2>/dev/null)" || {
    [[ -f "$cache" ]] && cat "$cache" && return 0
    echo '{"buy":null,"sell":null,"currency":"?"}'
    return 0
  }

  echo "$json" > "$cache"
  echo "$json"
}

format_price() {
  local price="$1"
  local currency="$2"
  if [[ "$price" == "null" || -z "$price" ]]; then
    echo "--"
    return
  fi
  if [[ "$currency" == "PYG" ]]; then
    printf "%'.0f" "$price"
  else
    printf "%.2f" "$price"
  fi
}

print_country() {
  local cc="$1"
  local json
  json="$(fetch_country "$cc")"

  local buy sell currency
  buy="$(jq -r '.buy // empty' <<<"$json")"
  sell="$(jq -r '.sell // empty' <<<"$json")"
  currency="$(jq -r '.currency // "?"' <<<"$json")"

  local fb fs
  fb="$(format_price "$buy" "$currency")"
  fs="$(format_price "$sell" "$currency")"

  case "$mode" in
    buy) echo "$fb" ;;
    sell) echo "$fs" ;;
    *) printf "%s  C: %s  V: %s\n" "$(echo "$cc" | tr '[:lower:]' '[:upper:]')" "$fb" "$fs" ;;
  esac
}

case "$country" in
  py|bo) print_country "$country" ;;
  all)
    print_country "py"
    print_country "bo"
    ;;
  *)
    echo "Usage: $0 <py|bo|all> [buy|sell|line]"
    exit 1
    ;;
esac
