#!/usr/bin/env bash
set -euo pipefail

# Usage: conky-p2p-info.sh <py|bo|all> [buy|sell|line|conky]
# Outputs nothing when the API key is not configured (widget hides P2P section).
country="${1:-all}"
mode="${2:-conky}"

ENV_FILE="${HOME}/.config/conky-p2p.env"
if [[ -f "$ENV_FILE" ]]; then
  # shellcheck disable=SC1090
  source "$ENV_FILE"
fi
API_KEY="${TRADERSWORLD_API_KEY:-}"
if [[ -z "$API_KEY" ]]; then
  exit 0
fi

BASE_URL="https://tradersworld.top/api/public/p2p"
CACHE_TTL=60

COUNTRY_LABEL_py="PYG"
COUNTRY_LABEL_bo="BOB"
COUNTRY_COLOR_py="CE1126"
COUNTRY_COLOR_bo="007934"
COUNTRY_TAG_py="PY"
COUNTRY_TAG_bo="BO"

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

  local label_var="COUNTRY_LABEL_${cc}"
  local color_var="COUNTRY_COLOR_${cc}"
  local tag_var="COUNTRY_TAG_${cc}"
  local label="${!label_var:-$(echo "$cc" | tr '[:lower:]' '[:upper:]')}"
  local ccolor="${!color_var:-FFFFFF}"
  local tag="${!tag_var:-$(echo "$cc" | tr '[:lower:]' '[:upper:]')}"

  case "$mode" in
    buy)   echo "$fb" ;;
    sell)  echo "$fs" ;;
    line)  printf "%s  C: %s  V: %s\n" "$label" "$fb" "$fs" ;;
    conky)
      printf '${color %s}${font Sans:bold:size=10}%s${font}${color} ${color BBBBBB}${font Sans:size=10}%s${font}${color}\n' "$ccolor" "$tag" "$label"
      printf '${goto 10}${color 00C853}${font DejaVu Sans:bold:size=12}▲${font}${font Sans:bold:size=13} %s${font}${color}' "$fb"
      printf '${goto 135}${color FF1744}${font DejaVu Sans:bold:size=12}▼${font}${font Sans:bold:size=13} %s${font}${color}\n' "$fs"
      ;;
  esac
}

print_header() {
  cat <<'CONKY'
${voffset 6}${hr 1}
${color 26A17B}${font Sans:bold:size=12}P2P USDT${font}${color}  ${color 888888}${font Sans:size=8}tradersworld.top${font}${color}
CONKY
}

case "$country" in
  py|bo) print_country "$country" ;;
  all)
    if [[ "$mode" == "conky" ]]; then
      print_header
    fi
    print_country "py"
    print_country "bo"
    ;;
  *)
    echo "Usage: $0 <py|bo|all> [buy|sell|line|conky]"
    exit 1
    ;;
esac
