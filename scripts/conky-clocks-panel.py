#!/usr/bin/env python3
from pathlib import Path
import subprocess

from PIL import Image, ImageDraw, ImageFont

WIDGET_ROOT = Path(__file__).resolve().parent.parent
FLAGS = WIDGET_ROOT / "assets" / "flags"
OUT = Path("/tmp/conky-clocks.png")
WIDTH = 250
BLOCK_H = 58
ZONES = (
    ("bo.png", "Bolivia", "America/La_Paz"),
    ("py.png", "Asuncion", "America/Asuncion"),
    ("us.png", "Arizona", "America/Phoenix"),
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


def zone_time(tz):
    return subprocess.check_output(["date", f"+%H:%M"], env={"TZ": tz}, text=True).strip()


def main():
    height = BLOCK_H * len(ZONES)
    panel = Image.new("RGBA", (WIDTH, height), (0, 0, 0, 0))
    draw = ImageDraw.Draw(panel)
    label_font = load_font(11)
    time_font = load_font(28, bold=True)
    label_color = (88, 166, 255, 255)
    time_color = (232, 232, 232, 255)

    for index, (flag_name, place, tz) in enumerate(ZONES):
        y = index * BLOCK_H
        flag = Image.open(FLAGS / flag_name).convert("RGBA")
        flag = flag.resize((32, 22), Image.Resampling.LANCZOS)
        time_text = zone_time(tz)

        time_box = draw.textbbox((0, 0), time_text, font=time_font)
        time_w = time_box[2] - time_box[0]
        label_box = draw.textbbox((0, 0), place, font=label_font)
        label_w = label_box[2] - label_box[0]

        time_x = WIDTH - time_w
        label_x = WIDTH - label_w
        flag_x = min(label_x, time_x) - 38

        panel.paste(flag, (flag_x, y + 1), flag)
        draw.text((label_x, y), place, fill=label_color, font=label_font)
        draw.text((time_x, y + 18), time_text, fill=time_color, font=time_font)

    panel.save(OUT)


if __name__ == "__main__":
    main()
