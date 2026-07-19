# Panel Escritorio Conky

**Español** | [English](README.md)

Widget de escritorio ligero para **Ubuntu + GNOME (Wayland)** pensado para **traders** y **trabajadores remotos** que necesitan ver de un vistazo horarios de mercado, precio de Bitcoin y estado del sistema — sin salir del escritorio.

![Platform](https://img.shields.io/badge/platform-Ubuntu%20%2B%20GNOME-blue)
![License](https://img.shields.io/badge/license-MIT-green)
![Wayland](https://img.shields.io/badge/Wayland-soportado-orange)

**Autor:** [Waldo Panozo](https://waldopanozo.github.io/)

## Vista previa

![Panel de escritorio en Ubuntu GNOME — relojes mundiales, Bitcoin y estadísticas del sistema](docs/screenshot.png)

*Ejemplo: relojes de Cochabamba, Asunción y Phoenix con clima (°C), BTC/USD en vivo, y CPU/RAM/red sobre el fondo del escritorio.*

## ¿Por qué este widget?

| Perfil | Qué obtienes |
|--------|--------------|
| **Traders** | Precio BTC/USD en vivo con variación 24h (CoinGecko) + compra/venta P2P USDT para PY y BO |
| **Trabajadores remotos** | Relojes multi-zona con banderas y clima actual para coordinar equipos |
| **Usuarios avanzados** | CPU, RAM y velocidad de red de un vistazo |

El panel aparece en la **esquina superior derecha**, semitransparente, queda debajo de las ventanas y se actualiza cada segundo sin robar el foco.

## Qué muestra

| Sección | Contenido | Actualización |
|---------|-----------|---------------|
| Relojes | Cochabamba, Asunción, Phoenix: bandera, hora, emoji de clima y temperatura °C | Cada 1 s (clima cacheado 15 min) |
| Bitcoin | Precio BTC/USD y cambio 24h | Cada 60 s |
| P2P USDT | Precios compra/venta para Paraguay (PYG) y Bolivia (BOB) vía API TradersWorld | Cada 60 s |
| Sistema | CPU, RAM y velocidad de red (subida/bajada) | Cada 1 s |

## Requisitos

```bash
sudo apt install conky-all curl jq python3-pil
```

| Paquete | Uso |
|---------|-----|
| `conky-all` | Motor del widget de escritorio |
| `curl` + `jq` | Consulta y parseo del precio BTC en CoinGecko |
| `python3-pil` | Renderiza relojes + banderas + clima en una sola imagen PNG |

## Instalación rápida

```bash
git clone https://github.com/waldopanozo/trading_widget_ubuntu.git
cd trading_widget_ubuntu/scripts
./install.sh
```

Iniciar el widget manualmente:

```bash
conky -c ~/panel-escritorio-conky/conky.conf &
```

El script de instalación también registra un **autostart de GNOME** para que el widget arranque al iniciar sesión en Wayland.

## Estructura del proyecto

```
panel-escritorio-conky/
├── README.md                          # Documentación en inglés
├── README.es.md                       # Documentación en español (este archivo)
├── LICENSE                            # MIT
├── docs/
│   └── screenshot.png                 # Captura de vista previa del README
├── conky.conf.in                      # Plantilla Conky (rutas rellenadas por install.sh)
├── scripts/
│   ├── install.sh                     # Instala deps, detecta red, genera config
│   ├── conky-clocks-panel.py          # Renderiza relojes + banderas + clima a PNG
│   ├── conky-clocks-panel.sh          # Wrapper de Python
│   ├── conky-btc-info.sh              # Consulta precio BTC en CoinGecko
│   ├── conky-p2p-info.sh              # Precios P2P USDT de TradersWorld (PY/BO)
│   └── conky-launch.sh                # Lanzador seguro en Wayland/Xwayland
├── assets/
│   └── flags/                         # Banderas PNG (Bolivia, Paraguay, USA)
└── autostart/
    └── panel-escritorio-conky.desktop.in
```

## Comandos útiles

```bash
# Reiniciar el widget
pkill conky && conky -c ~/panel-escritorio-conky/conky.conf &

# Detener el widget
pkill conky

# Ver logs de autostart
tail -f ~/.cache/panel-escritorio-conky/launch.log
```

## Personalización

### Cambiar zonas horarias o ciudades

Edita `scripts/conky-clocks-panel.py`, sección `ZONES`:

```python
ZONES = (
    ("bo.png", "Cochabamba", "America/La_Paz", -17.3895, -66.1568),
    ("py.png", "Asuncion", "America/Asuncion", -25.2637, -57.5759),
    ("us.png", "Phoenix", "America/Phoenix", 33.4484, -112.0740),
)
```

Cada tupla es `(archivo_bandera, nombre_visible, zona_IANA, lat, lon)`. Las coordenadas alimentan el clima de Open-Meteo. Agrega banderas PNG en `assets/flags/` (recomendado 32×22 px).

**Ejemplos para traders / equipos remotos:**

```python
ZONES = (
    ("us.png", "Nueva York", "America/New_York", 40.7128, -74.0060),
    ("gb.png", "Londres", "Europe/London", 51.5074, -0.1278),
    ("jp.png", "Tokio", "Asia/Tokyo", 35.6762, 139.6503),
)
```

### Cambiar interfaz de red

Vuelve a ejecutar install si cambias de Wi-Fi/Ethernet, o edita `conky.conf` directamente:

```bash
ip route get 1.1.1.1 | awk '{for(i=1;i<=NF;i++) if($i=="dev") print $(i+1)}'
```

Luego ejecuta `./install.sh` de nuevo para regenerar `conky.conf`.

### Cambiar posición del panel

Edita `conky.conf` (generado tras install):

```lua
alignment = 'top_right'   -- top_left, bottom_right, bottom_left, etc.
gap_x = 24
gap_y = 48
```

### Cambiar frecuencia del precio BTC

En `conky.conf`, el valor `60` en `${execpi 60 ...}` son segundos. El script también cachea respuestas 60 s en `/tmp/conky-btc.cache`.

## Notas técnicas

- **Workaround Wayland:** GNOME/Mutter no soporta la salida Wayland nativa de Conky. El widget usa **Xwayland** (`out_to_x = true`).
- **Renderizado de relojes:** Las banderas, horas y clima se componen con **Pillow** en una sola imagen (`/tmp/conky-clocks.png`) porque Conky en Wayland no alinea bien varias imágenes sueltas. El `${image ... -n}` y `imlib_cache_size = 0` evitan que Imlib2 deje congelada la primera captura (p. ej. la hora del arranque).
- **Clima:** [Open-Meteo](https://open-meteo.com/) (sin API key). Emoji + temperatura °C por ciudad; caché 15 min en `/tmp/conky-weather.cache`.
- **Autostart fiable:** `conky-launch.sh` espera a `gnome-shell` y Xwayland, luego reintenta cada 2 s hasta ~4 minutos.
- **Datos Bitcoin:** API pública de [CoinGecko](https://www.coingecko.com/) — sin API key. Respeta límites con cache de 60 s.
- **Datos P2P:** API privada de [TradersWorld](https://tradersworld.top) (`/api/public/p2p/{py|bo}`) con autenticación `X-API-Key`. La key se guarda en `~/.config/conky-p2p.env` (no se sube a git). Cache: 60 s en `/tmp/conky-p2p-{py|bo}.cache`.
- **Logs:** `~/.cache/panel-escritorio-conky/launch.log`
- **Probado en:** Ubuntu con GNOME Shell en Wayland.

## Limitaciones conocidas

- **Solo GNOME Wayland** — las sesiones X11 no son el objetivo principal; el autostart omite sesiones que no sean Wayland.
- **Ruta del clone** — `install.sh` resuelve rutas desde donde clones el repo; puedes clonarlo en cualquier carpeta.
- **Un solo par crypto** — BTC/USD desde CoinGecko; los precios P2P USDT requieren API key de TradersWorld en `~/.config/conky-p2p.env`.
- **Interfaz de red** — se detecta al instalar; vuelve a ejecutar install si cambia el nombre de tu dispositivo Wi-Fi/Ethernet.

## Contribuir

Ver [CONTRIBUTING.md](CONTRIBUTING.md). Issues y pull requests son bienvenidos.

## Licencia

MIT — ver [LICENSE](LICENSE).

Las banderas provienen de [flagcdn.com](https://flagcdn.com).

## Autor

Creado por [Waldo Panozo](https://waldopanozo.github.io/) ([GitHub](https://github.com/waldopanozo)) para productividad personal como trader y trabajador remoto.
