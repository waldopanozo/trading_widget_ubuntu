# Desktop Panel Conky

**English** | [Español](README.es.md)

A lightweight desktop widget for **Ubuntu + GNOME (Wayland)** built for **traders** and **remote workers** who need quick glances at market hours, Bitcoin price, and system health — without leaving the desktop.

![Platform](https://img.shields.io/badge/platform-Ubuntu%20%2B%20GNOME-blue)
![License](https://img.shields.io/badge/license-MIT-green)
![Wayland](https://img.shields.io/badge/Wayland-supported-orange)

**Author:** [Waldo Panozo](https://waldopanozo.github.io/)

## Preview

![Desktop panel on Ubuntu GNOME — world clocks, Bitcoin price, and system stats](docs/screenshot.png)

*Example: Bolivia, Asunción, and Arizona clocks, live BTC/USD, and CPU/RAM/network stats over a desktop wallpaper.*

## Why this widget?

| Audience | What you get |
|----------|--------------|
| **Traders** | Live BTC/USD price with 24h change (CoinGecko) + P2P USDT buy/sell for PY and BO |
| **Remote workers** | Multi-timezone clocks with country flags for team coordination |
| **Power users** | CPU, RAM, and network throughput at a glance |

The panel sits in the **top-right corner**, semi-transparent, stays below application windows, and updates every second without stealing focus.

## What it shows

| Section | Content | Refresh rate |
|---------|---------|--------------|
| Clocks | Bolivia, Asunción (Paraguay), Arizona (US) with flags | Every 1 s |
| Bitcoin | BTC/USD price and 24h change | Every 60 s |
| P2P USDT | Buy/sell prices for Paraguay (PYG) and Bolivia (BOB) via TradersWorld API | Every 60 s |
| System | CPU, RAM, and network up/down speed | Every 1 s |

## Requirements

```bash
sudo apt install conky-all curl jq python3-pil
```

| Package | Purpose |
|---------|---------|
| `conky-all` | Desktop widget engine |
| `curl` + `jq` | Fetch and parse Bitcoin price from CoinGecko |
| `python3-pil` | Render timezone clocks + flags into a single PNG |

## Quick start

```bash
git clone https://github.com/waldopanozo/trading_widget_ubuntu.git
cd trading_widget_ubuntu/scripts
./install.sh
```

Start the widget manually:

```bash
conky -c ~/panel-escritorio-conky/conky.conf &
```

The install script also registers a **GNOME autostart entry** so the widget launches after login on Wayland sessions.

## Project structure

```
panel-escritorio-conky/
├── README.md                          # English documentation (this file)
├── README.es.md                       # Spanish documentation
├── LICENSE                            # MIT
├── docs/
│   └── screenshot.png                 # README preview screenshot
├── conky.conf.in                      # Conky template (paths filled by install.sh)
├── scripts/
│   ├── install.sh                     # Install deps, detect network, generate config
│   ├── conky-clocks-panel.py          # Renders clocks + flags to PNG
│   ├── conky-clocks-panel.sh          # Python wrapper
│   ├── conky-btc-info.sh              # CoinGecko BTC price fetcher
│   ├── conky-p2p-info.sh              # TradersWorld P2P USDT rates (PY/BO)
│   └── conky-launch.sh                # Safe Wayland/Xwayland autostart launcher
├── assets/
│   └── flags/                         # PNG flags (Bolivia, Paraguay, USA)
└── autostart/
    └── panel-escritorio-conky.desktop.in
```

## Useful commands

```bash
# Restart the widget
pkill conky && conky -c ~/panel-escritorio-conky/conky.conf &

# Stop the widget
pkill conky

# View autostart logs
tail -f ~/.cache/panel-escritorio-conky/launch.log
```

## Customization

### Change timezones or cities

Edit `scripts/conky-clocks-panel.py`, section `ZONES`:

```python
ZONES = (
    ("bo.png", "Bolivia", "America/La_Paz"),
    ("py.png", "Asuncion", "America/Asuncion"),
    ("us.png", "Arizona", "America/Phoenix"),
)
```

Each tuple is `(flag_file, display_name, IANA_timezone)`. Add PNG flags under `assets/flags/` (32×22 px recommended).

**Examples for traders / remote teams:**

```python
ZONES = (
    ("us.png", "New York", "America/New_York"),
    ("gb.png", "London", "Europe/London"),
    ("jp.png", "Tokyo", "Asia/Tokyo"),
)
```

### Change network interface

Re-run install after connecting to a different interface, or edit `conky.conf` directly:

```bash
ip route get 1.1.1.1 | awk '{for(i=1;i<=NF;i++) if($i=="dev") print $(i+1)}'
```

Then run `./install.sh` again to regenerate `conky.conf`.

### Change panel position

Edit `conky.conf` (generated after install):

```lua
alignment = 'top_right'   -- top_left, bottom_right, bottom_left, etc.
gap_x = 24
gap_y = 48
```

### Change Bitcoin refresh interval

In `conky.conf`, the value `60` in `${execpi 60 ...}` is seconds. The shell script also caches responses for 60 seconds in `/tmp/conky-btc.cache`.

## Technical notes

- **Wayland workaround:** GNOME/Mutter does not support Conky's native Wayland output. The widget uses **Xwayland** (`out_to_x = true`).
- **Clock rendering:** Flags and times are composited with **Pillow** into one image (`/tmp/conky-clocks.png`) because Conky on Wayland misaligns multiple separate images. `${image ... -n}` plus `imlib_cache_size = 0` prevent Imlib2 from freezing the first frame (e.g. startup time).
- **Autostart reliability:** `conky-launch.sh` waits for `gnome-shell` and Xwayland, then retries every 2 s for up to ~4 minutes.
- **Bitcoin data:** Public [CoinGecko API](https://www.coingecko.com/) — no API key required. Respects rate limits via 60 s cache.
- **P2P data:** [TradersWorld](https://tradersworld.top) private API (`/api/public/p2p/{py|bo}`) with `X-API-Key` header auth. API key stored in `~/.config/conky-p2p.env` (not committed to git). Cache: 60 s in `/tmp/conky-p2p-{py|bo}.cache`.
- **Logs:** `~/.cache/panel-escritorio-conky/launch.log`
- **Tested on:** Ubuntu with GNOME Shell on Wayland.

## Known limitations

- **GNOME Wayland only** — X11 sessions are not the primary target; autostart skips non-Wayland sessions.
- **Hardcoded clone path in docs** — `install.sh` resolves paths from the clone location; you can clone anywhere.
- **Single crypto pair** — BTC/USD from CoinGecko; P2P USDT rates require a TradersWorld API key in `~/.config/conky-p2p.env`.
- **Network interface** — detected at install time; re-run install if your Wi-Fi/Ethernet device name changes.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md). Issues and pull requests are welcome.

## License

MIT — see [LICENSE](LICENSE).

Flag images are sourced from [flagcdn.com](https://flagcdn.com).

## Author

Built by [Waldo Panozo](https://waldopanozo.github.io/) ([GitHub](https://github.com/waldopanozo)) for personal productivity as a trader and remote worker.
