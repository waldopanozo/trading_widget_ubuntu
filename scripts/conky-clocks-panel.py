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


def load_font(size, bold=False):
    candidates = (
        "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf"
        if bold
        else "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf",
        "/usr/share/fonts/truetype/liberation/LiberationSans-Bold.ttf"
        if bold
        else "/usr/share/fonts/truetype/liberation/LiberationSans-Regular.ttf",
    )
    for path in candidates:
        if Path(path).exists():
            return ImageFont.truetype(path, size)
    return ImageFont.load_default()


def load_emoji_font(size):
    # Noto Color Emoji (CBDT) no sirve en Pillow; Symbols2 sí tiene glifos de clima.
    candidates = (
        "/usr/share/fonts/truetype/noto/NotoSansSymbols2-Regular.ttf",
        "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf",
    )
    for path in candidates:
        if Path(path).exists():
            try:
                return ImageFont.truetype(path, size)
            except OSError:
                continue
    return load_font(size)


def zone_time(tz):
    return subprocess.check_output(["date", "+%H:%M"], env={"TZ": tz}, text=True).strip()


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
        return {
            "temp_c": int(round(float(temp))),
            "weather_code": int(code) if code is not None else None,
        }
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


def main():
    height = BLOCK_H * len(ZONES)
    panel = Image.new("RGBA", (WIDTH, height), (0, 0, 0, 0))
    draw = ImageDraw.Draw(panel)
    label_font = load_font(11)
    time_font = load_font(28, bold=True)
    weather_font = load_font(20, bold=True)
    emoji_font = load_emoji_font(22)
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

        time_box = draw.textbbox((0, 0), time_text, font=time_font)
        time_w = time_box[2] - time_box[0]
        label_box = draw.textbbox((0, 0), place, font=label_font)
        label_w = label_box[2] - label_box[0]

        time_x = WIDTH - time_w
        label_x = WIDTH - label_w
        flag_x = max(min(label_x, time_x) - 38, 88)

        wx_x = 2
        try:
            draw.text((wx_x, y + 12), emoji, fill=weather_color, font=emoji_font)
            emoji_w = draw.textbbox((0, 0), emoji, font=emoji_font)[2]
        except Exception:
            draw.text((wx_x, y + 12), "*", fill=weather_color, font=weather_font)
            emoji_w = draw.textbbox((0, 0), "*", font=weather_font)[2]
        draw.text((wx_x + emoji_w + 4, y + 14), temp_text, fill=weather_color, font=weather_font)

        panel.paste(flag, (flag_x, y + 1), flag)
        draw.text((label_x, y), place, fill=label_color, font=label_font)
        draw.text((time_x, y + 18), time_text, fill=time_color, font=time_font)

    tmp = Path(str(OUT) + ".tmp")
    panel.save(tmp, format="PNG")
    tmp.replace(OUT)


if __name__ == "__main__":
    main()
