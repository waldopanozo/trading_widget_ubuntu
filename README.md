# Panel Escritorio Conky

Widget de escritorio para **Ubuntu + GNOME (Wayland)** que muestra relojes con banderas, precio de Bitcoin y estadisticas basicas del sistema.

## Que muestra

| Seccion | Contenido | Actualizacion |
|---------|-----------|---------------|
| Relojes | Bolivia, Asuncion (Paraguay), Arizona (EE.UU.) con bandera | Cada 1 segundo |
| Bitcoin | Precio BTC/USD y cambio 24h (CoinGecko) | Cada 60 segundos |
| Sistema | CPU, RAM y velocidad de red | Cada 1 segundo |

El panel aparece en la **esquina superior derecha** del escritorio, semitransparente, y no molesta al trabajar (queda debajo de las ventanas).

## Requisitos

```bash
sudo apt install conky-all curl jq python3-pil
```

## Estructura del proyecto

```
panel-escritorio-conky/
├── README.md
├── conky.conf                 # Configuracion principal de Conky
├── scripts/
│   ├── install.sh             # Enlaza config y autostart
│   ├── conky-clocks-panel.py  # Genera imagen de relojes + banderas
│   ├── conky-clocks-panel.sh  # Wrapper del panel de relojes
│   ├── conky-btc-info.sh      # Consulta precio BTC en CoinGecko
│   └── conky-launch.sh        # Arranque seguro en sesion Wayland
├── assets/
│   └── flags/                 # Banderas PNG (Bolivia, Paraguay, USA)
└── autostart/
    └── panel-escritorio-conky.desktop
```

## Instalacion

```bash
cd ~/panel-escritorio-conky/scripts
./install.sh
```

Luego inicia el widget:

```bash
conky -c ~/panel-escritorio-conky/conky.conf &
```

Para que arranque solo al iniciar sesion, el script `install.sh` ya crea el enlace en `~/.config/autostart/`.

## Comandos utiles

```bash
# Reiniciar el widget
pkill conky && conky -c ~/panel-escritorio-conky/conky.conf &

# Detener el widget
pkill conky
```

## Personalizacion

### Cambiar zonas horarias o ciudades

Edita `scripts/conky-clocks-panel.py`, seccion `ZONES`:

```python
ZONES = (
    ("bo.png", "Bolivia", "America/La_Paz"),
    ("py.png", "Asuncion", "America/Asuncion"),
    ("us.png", "Arizona", "America/Phoenix"),
)
```

Puedes cambiar el nombre visible, la zona (`TZ`) y la bandera en `assets/flags/`.

### Cambiar interfaz de red

En `conky.conf`, busca `wlp108s0` y reemplazala por tu interfaz:

```bash
ip route get 1.1.1.1 | awk '{for(i=1;i<=NF;i++) if($i=="dev") print $(i+1)}'
```

### Cambiar posicion del panel

En `conky.conf`:

```lua
alignment = 'top_right'   -- top_left, bottom_right, bottom_left, etc.
gap_x = 24
gap_y = 48
```

### Cambiar frecuencia del precio BTC

En `conky.conf`, el valor `60` en `${execpi 60 ...}` son segundos. Tambien hay cache de 60 s en `scripts/conky-btc-info.sh`.

## Notas tecnicas

- Las banderas se dibujan con **Pillow** en una sola imagen (`/tmp/conky-clocks.png`) porque Conky en Wayland no alinea bien varias imagenes sueltas.
- El precio de BTC usa la API publica de [CoinGecko](https://www.coingecko.com/) (sin API key).
- Usa **Xwayland** (`out_to_x = true`) porque GNOME/Mutter no soporta el protocolo Wayland nativo de Conky.
- El script de arranque espera a que Xwayland responda y usa la cookie de auth de Mutter.
- El autostart lanza un worker en segundo plano que reintenta cada 2 s hasta que Xwayland y Conky esten listos (max. ~4 min).
- Logs de arranque: `~/.cache/panel-escritorio-conky/launch.log`
- Probado en Ubuntu con GNOME Shell y Wayland.

## Licencia

Uso personal libre. Las banderas provienen de [flagcdn.com](https://flagcdn.com).
