# Diseño: temperatura e icono de clima en el panel de relojes

**Fecha:** 2026-07-18  
**Estado:** aprobado e implementado  
**Repo:** `panel-escritorio-conky` (`trading_widget_ubuntu`)

## Objetivo

Aprovechar el espacio vacío a la izquierda de cada fila de relojes para mostrar **emoji de clima + temperatura en °C**, sin romper el layout actual (bandera, ciudad, hora).

## Decisiones acordadas

| Tema | Elección |
|------|----------|
| Ciudades | Cochabamba, Asunción, Phoenix |
| Formato | Icono emoji + temperatura (`☀ 18°`) |
| Fuente de datos | Open-Meteo (sin API key) |
| Render | Mismo PNG Pillow (`/tmp/conky-clocks.png`) |

## Layout por fila (ancho 250 px)

```
[emoji][temp°]   [bandera]  Ciudad
                            HH:MM
```

- Bloque clima anclado a la **izquierda** (margen ~4–8 px).
- Bandera + etiqueta + hora siguen alineados a la **derecha**, como hoy.
- Si el clima no está disponible: `—°` (o emoji neutro `·`) sin romper la hora.

## Datos

### Ciudades y coordenadas (Open-Meteo)

| Etiqueta UI | Zona horaria | Lat | Lon |
|-------------|--------------|-----|-----|
| Cochabamba | America/La_Paz | -17.3895 | -66.1568 |
| Asuncion | America/Asuncion | -25.2637 | -57.5759 |
| Phoenix | America/Phoenix | 33.4484 | -112.0740 |

> Nota: la etiqueta de la primera fila pasa de `Bolivia` a `Cochabamba` para coincidir con el clima.

### API

- Endpoint: `https://api.open-meteo.com/v1/forecast`
- Parámetros: `latitude`, `longitude`, `current=temperature_2m,weather_code`, `timezone=auto`
- Una petición por ciudad **o** una petición batch si la API lo permite; preferir **una petición por ciudad** con caché compartida para simplicidad.
- Timeout corto (p. ej. 5–8 s). Fallo → mantener caché previa si existe; si no, placeholder.

### Caché

- Archivo: `/tmp/conky-weather.cache` (JSON: temp, weather_code, fetched_at por ciudad).
- TTL: **15 minutos**.
- El script de relojes corre cada 1 s; **solo consulta red si el caché expiró**.

### Mapeo weather_code → emoji (WMO)

Mapeo mínimo (ampliable):

| Códigos WMO | Emoji |
|-------------|-------|
| 0 | ☀ |
| 1, 2 | 🌤 |
| 3 | ☁ |
| 45, 48 | 🌫 |
| 51–67 | 🌧 |
| 71–77 | ❄ |
| 80–82 | 🌦 |
| 85, 86 | 🌨 |
| 95–99 | ⛈ |
| otro / error | · |

Temperatura: entero redondeado + sufijo `°` (sin `C` para ahorrar espacio).

## Cambios de código previstos

1. **`scripts/conky-clocks-panel.py`**
   - Extender `ZONES` con lat/lon (y renombrar label a Cochabamba).
   - Función `load_weather()` / `weather_for(city)` con caché.
   - Dibujar emoji + temp a la izquierda de cada bloque.
   - Fuente emoji: Noto Color Emoji / Noto Sans Symbols si está instalada; fallback a texto ASCII si no hay glifo.

2. **Docs** (`README.es.md` / `README.md`): mención breve de clima Open-Meteo y caché 15 min.

3. **Sin cambios** a `conky.conf` salvo que el alto/ancho del PNG cambie (no previsto).

## Fuera de alcance

- Pronóstico por horas / días.
- API keys o proveedores de pago.
- Iconos PNG de clima (se eligió emoji).
- Otras ciudades además de las tres acordadas.

## Riesgos

| Riesgo | Mitigación |
|--------|------------|
| Emoji mal renderizado en Pillow | Probar fuentes Noto; si falla, usar caracteres ASCII (`*`, `~`, etc.) o un solo glifo genérico |
| Rate limit / red caída | Caché 15 min + placeholder |
| Escritura concurrente del PNG | Escritura atómica (temp + `rename`) si hace falta |

## Criterios de éxito

- Cada fila muestra emoji + °C a la izquierda y hora correcta a la derecha.
- Sin API key ni config nueva del usuario.
- Si no hay red, el panel de relojes sigue funcionando.
- CPU/red: no más de ~1 petición por ciudad cada 15 min.
