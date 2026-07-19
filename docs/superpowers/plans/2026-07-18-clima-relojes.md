# Plan: clima (emoji + °C) en panel de relojes

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Mostrar emoji de clima + temperatura °C a la izquierda de cada fila (Cochabamba, Asunción, Phoenix) en el PNG de relojes de Conky, vía Open-Meteo con caché 15 min.

**Architecture:** Extender `conky-clocks-panel.py`: coordenadas por zona, fetch/caché JSON en `/tmp/conky-weather.cache`, mapeo WMO→emoji, dibujo a la izquierda; bandera/hora siguen a la derecha. Sin cambios a `conky.conf` salvo verificación visual.

**Tech Stack:** Python 3, Pillow, `urllib.request` (stdlib), Open-Meteo HTTP API, Conky `${image}` existente.

**Spec:** `docs/superpowers/specs/2026-07-18-clima-relojes-design.md`

## Global Constraints

- Sin API key ni config nueva del usuario.
- Ciudades: Cochabamba, Asunción, Phoenix (labels UI; primera deja de ser "Bolivia"/"Arizona" → "Cochabamba"/"Phoenix").
- Formato: emoji + `NN°` (°C, sin letra C).
- Caché TTL 15 min; si falla red, usar caché previa o `· —°`.
- No crear scripts de prueba permanentes; verificar con comandos manuales y el PNG.
- Docs persistentes en español (`README.es.md`); actualizar también `README.md` en inglés (ya existente en el repo).
- No commit/push salvo que el usuario lo pida.

## File map

| Archivo | Rol |
|---------|-----|
| `scripts/conky-clocks-panel.py` | ZONES+lat/lon, weather fetch/cache, layout clima, save PNG |
| `README.es.md` / `README.md` | Documentar clima Open-Meteo + caché |
| `/tmp/conky-weather.cache` | Runtime JSON (no versionar) |

---

### Task 1: Datos de zona + fetch/caché Open-Meteo + mapeo emoji

**Files:**
- Modify: `scripts/conky-clocks-panel.py`

**Interfaces:**
- Produces:
  - `ZONES`: tuplas `(flag_name, place, tz, lat, lon)`
  - `WEATHER_CACHE = Path("/tmp/conky-weather.cache")`
  - `WEATHER_TTL_SEC = 900`
  - `weather_code_to_emoji(code: int | None) -> str`
  - `fetch_city_weather(lat: float, lon: float) -> dict | None` → `{"temp_c": int, "weather_code": int}`
  - `load_weather(zones) -> dict[str, dict]` keyed by `place`

- [ ] **Step 1: Ampliar imports y constantes**

Al inicio del archivo, tras los imports existentes, dejar:

```python
#!/usr/bin/env python3
from pathlib import Path
import json
import subprocess
import time
import urllib.error
import urllib.parse
import urllib.request

from PIL import Image, ImageDraw, ImageFont

WIDGET_ROOT = Path(__file__).resolve().parent.parent
FLAGS = WIDGET_ROOT / "assets" / "flags"
OUT = Path("/tmp/conky-clocks.png")
WEATHER_CACHE = Path("/tmp/conky-weather.cache")
WEATHER_TTL_SEC = 900
WIDTH = 250
BLOCK_H = 58
ZONES = (
    ("bo.png", "Cochabamba", "America/La_Paz", -17.3895, -66.1568),
    ("py.png", "Asuncion", "America/Asuncion", -25.2637, -57.5759),
    ("us.png", "Phoenix", "America/Phoenix", 33.4484, -112.0740),
)
```

- [ ] **Step 2: Añadir mapeo WMO y helpers de red/caché**

Insertar después de `zone_time`:

```python
def weather_code_to_emoji(code):
    if code is None:
        return "·"
    if code == 0:
        return "☀"
    if code in (1, 2):
        return "🌤"
    if code == 3:
        return "☁"
    if code in (45, 48):
        return "🌫"
    if 51 <= code <= 67:
        return "🌧"
    if 71 <= code <= 77:
        return "❄"
    if 80 <= code <= 82:
        return "🌦"
    if code in (85, 86):
        return "🌨"
    if 95 <= code <= 99:
        return "⛈"
    return "·"


def fetch_city_weather(lat, lon):
    qs = urllib.parse.urlencode(
        {
            "latitude": lat,
            "longitude": lon,
            "current": "temperature_2m,weather_code",
            "timezone": "auto",
        }
    )
    url = f"https://api.open-meteo.com/v1/forecast?{qs}"
    try:
        with urllib.request.urlopen(url, timeout=8) as resp:
            data = json.loads(resp.read().decode())
        current = data.get("current") or {}
        temp = current.get("temperature_2m")
        code = current.get("weather_code")
        if temp is None:
            return None
        return {"temp_c": int(round(float(temp))), "weather_code": int(code) if code is not None else None}
    except (urllib.error.URLError, TimeoutError, ValueError, json.JSONDecodeError, TypeError):
        return None


def load_weather(zones):
    now = time.time()
    cache = {}
    if WEATHER_CACHE.exists():
        try:
            cache = json.loads(WEATHER_CACHE.read_text(encoding="utf-8"))
        except (OSError, json.JSONDecodeError):
            cache = {}

    cities = cache.get("cities") if isinstance(cache.get("cities"), dict) else {}
    fetched_at = float(cache.get("fetched_at") or 0)
    fresh = (now - fetched_at) < WEATHER_TTL_SEC and all(
        place in cities for _, place, *_ in zones
    )

    if not fresh:
        new_cities = dict(cities)
        for _, place, _, lat, lon in zones:
            result = fetch_city_weather(lat, lon)
            if result is not None:
                new_cities[place] = result
        if new_cities:
            payload = {"fetched_at": now, "cities": new_cities}
            tmp = WEATHER_CACHE.with_suffix(".cache.tmp")
            tmp.write_text(json.dumps(payload), encoding="utf-8")
            tmp.replace(WEATHER_CACHE)
            cities = new_cities

    return cities
```

- [ ] **Step 3: Verificar fetch manual (sin tocar el layout aún)**

Run:

```bash
cd /home/wpanozo/panel-escritorio-conky
python3 - <<'PY'
from scripts import importlib
# o ejecutar funciones importando el módulo
import importlib.util
spec = importlib.util.spec_from_file_location("clocks", "scripts/conky-clocks-panel.py")
m = importlib.util.module_from_spec(spec)
spec.loader.exec_module(m)
print(m.fetch_city_weather(-17.3895, -66.1568))
print(m.weather_code_to_emoji(0), m.weather_code_to_emoji(61))
w = m.load_weather(m.ZONES)
print(w)
print("cache:", m.WEATHER_CACHE.exists(), m.WEATHER_CACHE.read_text()[:200] if m.WEATHER_CACHE.exists() else None)
PY
```

Expected: dicts con `temp_c` / `weather_code` para Cochabamba; emojis `☀` y `🌧`; archivo `/tmp/conky-weather.cache` creado.

- [ ] **Step 4: Commit solo si el usuario lo pide** (omitir por defecto)

---

### Task 2: Dibujar clima a la izquierda + fuentes emoji + save atómico

**Files:**
- Modify: `scripts/conky-clocks-panel.py` (`main`, `load_font` / fuente emoji)

**Interfaces:**
- Consumes: `load_weather`, `weather_code_to_emoji`, `ZONES` de Task 1
- Produces: PNG `/tmp/conky-clocks.png` con clima a la izquierda

- [ ] **Step 1: Extender carga de fuentes para emoji**

Añadir:

```python
def load_emoji_font(size):
    candidates = (
        "/usr/share/fonts/truetype/noto/NotoColorEmoji.ttf",
        "/usr/share/fonts/truetype/noto/NotoEmoji-Regular.ttf",
    )
    for path in candidates:
        if Path(path).exists():
            try:
                return ImageFont.truetype(path, size)
            except OSError:
                continue
    return load_font(size)
```

Nota: si `NotoColorEmoji.ttf` falla al dibujar (CBDT), Pillow puede lanzar o dibujar vacío — en ese caso usar `NotoEmoji-Regular.ttf` o dibujar solo la temperatura y un ASCII (`*`).

- [ ] **Step 2: Actualizar `main()` para layout con clima**

Reemplazar el cuerpo de `main` por:

```python
def main():
    height = BLOCK_H * len(ZONES)
    panel = Image.new("RGBA", (WIDTH, height), (0, 0, 0, 0))
    draw = ImageDraw.Draw(panel)
    label_font = load_font(11)
    time_font = load_font(28, bold=True)
    weather_font = load_font(16, bold=True)
    emoji_font = load_emoji_font(16)
    label_color = (88, 166, 255, 255)
    time_color = (232, 232, 232, 255)
    weather_color = (200, 200, 200, 255)
    weather = load_weather(ZONES)

    for index, (flag_name, place, tz, _lat, _lon) in enumerate(ZONES):
        y = index * BLOCK_H
        flag = Image.open(FLAGS / flag_name).convert("RGBA")
        flag = flag.resize((32, 22), Image.Resampling.LANCZOS)
        time_text = zone_time(tz)

        city_wx = weather.get(place) or {}
        emoji = weather_code_to_emoji(city_wx.get("weather_code"))
        if "temp_c" in city_wx:
            temp_text = f"{city_wx['temp_c']}°"
        else:
            emoji = "·"
            temp_text = "—°"
        weather_text = f"{emoji} {temp_text}"

        time_box = draw.textbbox((0, 0), time_text, font=time_font)
        time_w = time_box[2] - time_box[0]
        label_box = draw.textbbox((0, 0), place, font=label_font)
        label_w = label_box[2] - label_box[0]

        time_x = WIDTH - time_w
        label_x = WIDTH - label_w
        flag_x = min(label_x, time_x) - 38

        # Clima a la izquierda
        wx_x = 4
        try:
            draw.text((wx_x, y + 16), emoji, fill=weather_color, font=emoji_font)
            emoji_w = draw.textbbox((0, 0), emoji, font=emoji_font)[2]
        except Exception:
            draw.text((wx_x, y + 16), "*", fill=weather_color, font=weather_font)
            emoji_w = draw.textbbox((0, 0), "*", font=weather_font)[2]
        draw.text((wx_x + emoji_w + 4, y + 18), temp_text, fill=weather_color, font=weather_font)

        panel.paste(flag, (flag_x, y + 1), flag)
        draw.text((label_x, y), place, fill=label_color, font=label_font)
        draw.text((time_x, y + 18), time_text, fill=time_color, font=time_font)

    tmp = OUT.with_suffix(".png.tmp")
    panel.save(tmp)
    tmp.replace(OUT)
```

Ajuste fino permitido: si emoji + temp solapan la bandera, reducir `weather_font` a 14 o mover `flag_x` un poco a la derecha (mínimo `flag_x = max(flag_x, 72)`).

- [ ] **Step 3: Regenerar PNG y revisar visualmente**

Run:

```bash
/home/wpanozo/panel-escritorio-conky/scripts/conky-clocks-panel.sh
file /tmp/conky-clocks.png
# abrir /tmp/conky-clocks.png en el visor o leerlo en Cursor
```

Expected: tres filas con clima a la izquierda, labels Cochabamba/Asuncion/Phoenix, horas correctas a la derecha. Conky ya tiene `-n` en `${image}` así que debería refrescar solo.

- [ ] **Step 4: Probar degradación sin red**

Run:

```bash
# simular caché válida
python3 -c 'import json,time; from pathlib import Path; Path("/tmp/conky-weather.cache").write_text(json.dumps({"fetched_at": time.time(),"cities":{"Cochabamba":{"temp_c":12,"weather_code":0},"Asuncion":{"temp_c":18,"weather_code":3},"Phoenix":{"temp_c":35,"weather_code":0}}}))'
# bloquear red momentáneamente no es obligatorio; vaciar caché y forzar fallo:
mv /tmp/conky-weather.cache /tmp/conky-weather.cache.bak 2>/dev/null || true
# con red OK el script rellena; para placeholder, mockear fetch devolviendo None en una corrida local si hace falta
/home/wpanozo/panel-escritorio-conky/scripts/conky-clocks-panel.sh
```

Expected: con caché buena se ven temps; sin datos → `· —°` y relojes intactos.

---

### Task 3: Documentación

**Files:**
- Modify: `README.es.md`
- Modify: `README.md`

- [ ] **Step 1: Actualizar tabla de features y notas técnicas (ES)**

En `README.es.md`:

- En la tabla de features / relojes, mencionar clima Open-Meteo (emoji + °C) para Cochabamba, Asunción, Phoenix.
- En notas técnicas, añadir viñeta: clima vía Open-Meteo, caché 15 min en `/tmp/conky-weather.cache`.
- Actualizar mención de ciudades si aún dice Bolivia / Arizona.

- [ ] **Step 2: Espejo en `README.md` (EN)**

Misma información en inglés, coherente con el README ES.

- [ ] **Step 3: Verificación rápida**

```bash
grep -n -i 'open-meteo\|Cochabamba\|weather\|clima' README.es.md README.md
```

Expected: al menos una mención en cada README.

---

## Spec coverage (self-review)

| Requisito spec | Task |
|----------------|------|
| Ciudades CBBA / Asunción / Phoenix + coords | Task 1 |
| Emoji + °C izquierda | Task 2 |
| Open-Meteo sin key | Task 1 |
| Caché 15 min `/tmp/conky-weather.cache` | Task 1 |
| Mapeo WMO | Task 1 |
| Placeholder si falla | Task 1–2 |
| Docs | Task 3 |
| Save atómico PNG | Task 2 |
| Sin cambio obligatorio conky.conf | — (ya tiene `-n`) |

## Placeholder scan

Sin TBD / “implement later”. Verificación manual en lugar de pytest (preferencia del usuario).
