from __future__ import annotations

from functools import lru_cache
from math import sin, tau
from pathlib import Path
from PIL import Image, ImageDraw, ImageFilter, ImageFont


ROOT = Path(__file__).resolve().parents[1]
OUTPUT = ROOT / "AppStore" / "zh-Hant"
PREVIEWS = ROOT / "Previews" / "iPhone17Pro"
TITLE_GOLD = "#FFE278"
SUBTITLE_MINT = "#D7F3E5"
TEXT_OUTLINE = "#0B2324"
BADGE_GREEN = "#173C36"

FONT_DIR = Path.home() / "Library" / "Fonts"
FONT_BLACK = FONT_DIR / "ChironGoRoundTC-Black.ttf"
FONT_MEDIUM = FONT_DIR / "ChironGoRoundTC-Medium.ttf"
FONT_HAND = FONT_DIR / "JasonHandwriting6.ttf"


def font(path: Path, size: int) -> ImageFont.FreeTypeFont:
    return ImageFont.truetype(str(path), size)


def explorer_stamp(symbol: str, tint: str, side: int, angle: float) -> Image.Image:
    tile = Image.new("RGBA", (side, side))
    draw = ImageDraw.Draw(tile)
    draw.rounded_rectangle((1, 1, side - 2, side - 2), side // 5, fill=BADGE_GREEN,
                           outline=tint, width=max(2, side // 36))

    def points(*coordinates: tuple[int, int]) -> list[tuple[int, int]]:
        return [(round(x * side / 100), round(y * side / 100)) for x, y in coordinates]

    stroke = max(2, side // 20)
    if symbol == "plane":
        draw.polygon(points((20, 48), (76, 24), (66, 76), (50, 58), (42, 70), (40, 54)), fill=tint)
        draw.line(points((40, 54), (68, 32)), fill=BADGE_GREEN, width=stroke)
    elif symbol == "compass":
        draw.ellipse(points((23, 23), (77, 77)), outline=tint, width=stroke)
        draw.polygon(points((62, 35), (54, 56), (36, 65), (45, 44)), fill=tint)
    elif symbol == "flag":
        draw.line(points((33, 78), (33, 24)), fill=tint, width=stroke)
        draw.polygon(points((36, 26), (72, 30), (63, 43), (72, 54), (36, 51)), fill=tint)
    else:
        draw.line(points((20, 69), (41, 35), (53, 53), (65, 42), (82, 69), (20, 69)),
                  fill=tint, width=stroke, joint="curve")
    return tile.rotate(angle, expand=True, resample=Image.Resampling.BICUBIC)


@lru_cache(maxsize=4)
def explorer_background(size: tuple[int, int]) -> Image.Image:
    width, height = size
    gradient = Image.new("RGB", (96, 96))
    pixels = []
    for y in range(96):
        for x in range(96):
            across, down = x / 95, y / 95
            glow = max(0, 1 - ((across - 0.27) ** 2 + (down - 0.62) ** 2) * 4)
            pixels.append((round(15 + 9 * glow), round(38 + 30 * glow - 8 * across),
                           round(35 + 12 * glow + 15 * across)))
    gradient.putdata(pixels)
    canvas = gradient.resize(size, Image.Resampling.BICUBIC).convert("RGBA")
    overlay = Image.new("RGBA", size)
    draw = ImageDraw.Draw(overlay)
    scale = min(size) / 1200
    step = round(39 * scale)
    dot = max(1, round(1.5 * scale))
    for x in range(step // 2, width, step):
        for y in range(step // 2, height, step):
            draw.ellipse((x - dot, y - dot, x + dot, y + dot), fill=(160, 230, 208, 55))

    for cx, cy in ((0, 0), (width, height)):
        for ring in range(1, 8):
            radius = (52 + ring * 41) * scale
            draw.ellipse((cx - radius * 1.65, cy - radius, cx + radius * 1.65, cy + radius),
                         outline=(154, 225, 219, 65), width=max(1, round(2 * scale)))

    wide = width > height
    edges = (0.54, 0.93) if wide else (0.08, 0.92)
    stamps = [("compass", "#FFE278", -14), ("plane", "#A7E9FF", -12),
              ("mountain", "#FFAA88", 11), ("flag", "#AFEBC9", 12)]
    for lane, center in enumerate(edges):
        route = [(round(width * (center + 0.035 * sin(tau * sample / 120 + lane))),
                  round(height * (0.18 + sample * 0.72 / 120))) for sample in range(121)]
        for start in range(0, 120, 4):
            draw.line(route[start:start + 3], fill=(147, 229, 204, 139), width=max(2, round(4 * scale)))
        for stop, (symbol, tint, angle) in zip((24, 94), stamps[lane::2]):
            x, y = route[stop]
            tile = explorer_stamp(symbol, tint, round(86 * scale), angle)
            overlay.alpha_composite(tile, (x - tile.width // 2, y - tile.height // 2))
            for distance, radius in ((52, 7), (75, 4)):
                fx, fy = x + (distance * scale if lane == 0 else -distance * scale), y - distance * scale
                r = radius * scale
                draw.polygon([(fx, fy - r), (fx + r * 0.3, fy - r * 0.3), (fx + r, fy),
                              (fx + r * 0.3, fy + r * 0.3), (fx, fy + r),
                              (fx - r * 0.3, fy + r * 0.3), (fx - r, fy), (fx - r * 0.3, fy - r * 0.3)],
                             fill=tint)
    canvas.alpha_composite(overlay)
    return canvas


def rounded_mask(size: tuple[int, int], radius: int) -> Image.Image:
    result = Image.new("L", size)
    ImageDraw.Draw(result).rounded_rectangle(
        (0, 0, size[0] - 1, size[1] - 1), radius, fill=255
    )
    return result


def phone_card(
    screenshot: Image.Image,
    width: int,
    angle: float = 0,
    border: int | None = None,
) -> Image.Image:
    border = border if border is not None else max(16, width // 48)
    height = round(screenshot.height * width / screenshot.width)
    shot = screenshot.resize((width, height), Image.Resampling.LANCZOS)
    card = Image.new("RGBA", (width + border * 2, height + border * 2))
    draw = ImageDraw.Draw(card)
    radius = max(52, width // 13)
    draw.rounded_rectangle(
        (0, 0, card.width - 1, card.height - 1),
        radius,
        fill="#101416",
        outline="#747B78",
        width=max(3, width // 200),
    )
    card.paste(shot, (border, border), rounded_mask(shot.size, radius - border))
    if angle:
        card = card.rotate(angle, expand=True, resample=Image.Resampling.BICUBIC)
    return card


def paste_shadow(canvas: Image.Image, item: Image.Image, xy: tuple[int, int], blur: int) -> None:
    shadow = Image.new("RGBA", canvas.size)
    alpha = item.getchannel("A")
    shadow.paste((4, 20, 24, 90), (xy[0] + 16, xy[1] + 32), alpha)
    canvas.alpha_composite(shadow.filter(ImageFilter.GaussianBlur(blur)))
    canvas.alpha_composite(item, xy)


def pill(
    canvas: Image.Image,
    xy: tuple[int, int],
    text: str,
    size: int,
    dot: str = "#DE624A",
    dark: bool = False,
) -> None:
    badge_font = font(FONT_HAND, size)
    bbox = badge_font.getbbox(text)
    width = bbox[2] - bbox[0] + size * 2
    height = round(size * 1.65)
    badge = Image.new("RGBA", (width, height))
    draw = ImageDraw.Draw(badge)
    draw.rounded_rectangle(
        (0, 0, width - 1, height - 1),
        height // 3,
        fill=BADGE_GREEN if dark else "white",
        outline="#6EF2D4" if dark else None,
        width=max(2, size // 24),
    )
    radius = max(10, size // 3)
    draw.ellipse((size // 2, height // 2 - radius, size // 2 + radius * 2, height // 2 + radius), fill=dot)
    draw.text(
        (size * 1.2, height // 2),
        text,
        font=badge_font,
        fill="#F8FAFF" if dark else "#151A1B",
        anchor="lm",
    )
    canvas.alpha_composite(badge, xy)


def add_copy(
    canvas: Image.Image,
    kicker: str,
    line_one: str,
    line_two: str,
    subtitle: str,
    origin: tuple[int, int],
    scale: float,
) -> None:
    draw = ImageDraw.Draw(canvas)
    x, y = origin
    draw.text((x, y), kicker, font=font(FONT_HAND, round(92 * scale)), fill="#74F4D3")
    draw.text(
        (x, y + round(145 * scale)), line_one,
        font=font(FONT_BLACK, round(214 * scale)), fill="#FFFFFF",
        stroke_width=max(2, round(3 * scale)), stroke_fill=TEXT_OUTLINE,
    )
    draw.text(
        (x, y + round(375 * scale)), line_two,
        font=font(FONT_BLACK, round(214 * scale)), fill=TITLE_GOLD,
        stroke_width=max(2, round(3 * scale)), stroke_fill=TEXT_OUTLINE,
    )
    draw.text(
        (x, y + round(655 * scale)), subtitle,
        font=font(FONT_MEDIUM, round(76 * scale)), fill=SUBTITLE_MINT,
    )


def render_wide_assets() -> None:
    destination = OUTPUT / "Creative"
    destination.mkdir(parents=True, exist_ok=True)
    size = (5244, 2950)
    background = explorer_background(size)

    title = background.copy()
    add_copy(
        title,
        "世界國旗挑戰",
        "玩著認識世界",
        "一面旗，開啟旅程",
        "用圖卡一起學，按自己的步調練習，或來一場國旗挑戰。",
        (300, 470),
        1.0,
    )
    home = phone_card(Image.open(PREVIEWS / "home.png").convert("RGB"), 1130, -9)
    game = phone_card(Image.open(PREVIEWS / "game.png").convert("RGB"), 1030, 10)
    paste_shadow(title, game, (3920, 280), 55)
    paste_shadow(title, home, (3000, 300), 60)
    title.convert("RGB").save(destination / "title-5244x2950.png", optimize=True)

    search = background.copy()
    add_copy(
        search,
        "玩一局，就多認識一個國家",
        "198 面國旗",
        "等你來挑戰",
        "四選一快答、六大地區旅程、易混淆國旗特訓。",
        (290, 390),
        1.0,
    )
    pill(search, (320, 1900), "六大地區", 84, "#FF7855", dark=True)
    pill(search, (1190, 1900), "間隔複習", 84, "#62F2CF", dark=True)
    pill(search, (2060, 1900), "四語支援", 84, "#FFD23F", dark=True)
    journeys = phone_card(Image.open(PREVIEWS / "journeys.png").convert("RGB"), 1110, -8)
    answer = phone_card(Image.open(PREVIEWS / "answer.png").convert("RGB"), 1000, 9)
    paste_shadow(search, answer, (4060, 300), 55)
    paste_shadow(search, journeys, (3100, 260), 60)
    search.convert("RGB").save(destination / "search-result-5244x2950.png", optimize=True)


SCREEN_DATA = [
    ("home", "認識世界", "從一面旗開始", "一起看圖卡、自己練習，或挑戰國旗問答。", "#F5F5F3"),
    ("game", "這面旗幟", "是哪一國？", "從四個選項找出正確答案。", "#EDF4EF"),
    ("answer", "答完一題", "認識一個國家", "看答案與小知識，再挑戰下一題。", "#FBF1E5"),
    ("journeys", "挑一個地區", "開始國旗探險", "六大地區，各有不同的國旗等你辨認。", "#F3F5F3"),
    ("records", "你的國旗圖鑑", "還差幾面？", "追蹤進度，找到還沒記熟的國旗。", "#F7EEEA"),
    ("results", "回合結束", "錯題再挑戰", "查看答對率，再練習這一輪的錯題。", "#F7F2DF"),
    ("pause", "暫停一下", "準備好再繼續", "回到原題，或重新開始一輪。", "#ECF3EF"),
]


def render_duo_previews() -> None:
    native_screenshots = OUTPUT / "iPhone-Duo"
    destination = OUTPUT / "iPhone-Duo-Preview"
    destination.mkdir(parents=True, exist_ok=True)
    width, height = 1398, 2034
    for index, (source, line_one, line_two, subtitle, color) in enumerate(SCREEN_DATA, 1):
        canvas = explorer_background((width, height)).copy()
        draw = ImageDraw.Draw(canvas)
        draw.text(
            (70, 52), line_one, font=font(FONT_BLACK, 126), fill="#FFFFFF",
            stroke_width=2, stroke_fill=TEXT_OUTLINE,
        )
        draw.text(
            (70, 185), line_two, font=font(FONT_BLACK, 132), fill=TITLE_GOLD,
            stroke_width=2, stroke_fill=TEXT_OUTLINE,
        )
        draw.text((76, 365), subtitle, font=font(FONT_MEDIUM, 48), fill=SUBTITLE_MINT)
        shot_path = native_screenshots / f"{index:02d}-{source}-1398x2034.jpg"
        if not shot_path.exists():
            raise SystemExit(f"Missing native iPhone Duo screenshot: {shot_path}")
        shot = Image.open(shot_path).convert("RGB")
        if shot.size != (1398, 2034):
            raise SystemExit(f"Unexpected native iPhone Duo size: {shot_path} {shot.size}")
        phone = phone_card(shot, 940, -2 if index % 2 else 2)
        x = (width - phone.width) // 2 + (22 if index % 2 else -22)
        y = 570
        paste_shadow(canvas, phone, (x, y), 36)
        canvas.convert("RGB").save(
            destination / f"{index:02d}-{source}-1398x2034.jpg",
            quality=94,
            optimize=True,
            progressive=True,
        )


def render_standard_iphone_previews() -> None:
    targets = [
        (OUTPUT / "iPhone-6.9", 1320, 2868, "jpg"),
        (OUTPUT / "iPhone-Dynamic-Island-Medium", 1206, 2622, "jpg"),
        (OUTPUT / "iPhone", 1206, 2622, "png"),
    ]
    for destination, width, height, extension in targets:
        destination.mkdir(parents=True, exist_ok=True)
        scale = width / 1320
        for index, (source, line_one, line_two, subtitle, _) in enumerate(SCREEN_DATA, 1):
            canvas = explorer_background((width, height)).copy()
            draw = ImageDraw.Draw(canvas)
            draw.text(
                (round(64 * scale), round(58 * scale)),
                line_one,
                font=font(FONT_BLACK, round(126 * scale)),
                fill="#FFFFFF",
                stroke_width=max(2, round(2 * scale)),
                stroke_fill=TEXT_OUTLINE,
            )
            draw.text(
                (round(64 * scale), round(190 * scale)),
                line_two,
                font=font(FONT_BLACK, round(132 * scale)),
                fill=TITLE_GOLD,
                stroke_width=max(2, round(2 * scale)),
                stroke_fill=TEXT_OUTLINE,
            )
            draw.text(
                (round(70 * scale), round(370 * scale)),
                subtitle,
                font=font(FONT_MEDIUM, round(46 * scale)),
                fill=SUBTITLE_MINT,
            )
            shot_path = PREVIEWS / f"{source}.png"
            shot = Image.open(shot_path).convert("RGB")
            if shot.size != (1206, 2622):
                raise SystemExit(f"Unexpected iPhone preview size: {shot_path} {shot.size}")
            phone = phone_card(shot, round(850 * scale), -2 if index % 2 else 2)
            x = (width - phone.width) // 2 + round((24 if index % 2 else -24) * scale)
            y = round(650 * scale)
            paste_shadow(canvas, phone, (x, y), round(38 * scale))

            output = destination / f"{index:02d}-{source}.{extension}"
            if extension == "jpg":
                canvas.convert("RGB").save(output, quality=94, optimize=True, progressive=True)
            else:
                canvas.convert("RGB").save(output, optimize=True)


def render_ipad_previews() -> None:
    raw_screenshots = OUTPUT / "iPad-13-Raw"
    destination = OUTPUT / "iPad-13-Preview"
    destination.mkdir(parents=True, exist_ok=True)
    width, height = 2064, 2752
    for index, (source, line_one, line_two, subtitle, _) in enumerate(SCREEN_DATA, 1):
        canvas = explorer_background((width, height)).copy()
        draw = ImageDraw.Draw(canvas)
        draw.text(
            (86, 66), line_one, font=font(FONT_BLACK, 160), fill="#FFFFFF",
            stroke_width=3, stroke_fill=TEXT_OUTLINE,
        )
        draw.text(
            (86, 232), line_two, font=font(FONT_BLACK, 170), fill=TITLE_GOLD,
            stroke_width=3, stroke_fill=TEXT_OUTLINE,
        )
        draw.text((94, 462), subtitle, font=font(FONT_MEDIUM, 62), fill=SUBTITLE_MINT)
        shot_path = raw_screenshots / f"{index:02d}-{source}-2064x2752.jpg"
        if not shot_path.exists():
            raise SystemExit(f"Missing native iPad screenshot: {shot_path}")
        shot = Image.open(shot_path).convert("RGB")
        if shot.size != (2064, 2752):
            raise SystemExit(f"Unexpected native iPad size: {shot_path} {shot.size}")
        tablet = phone_card(shot, 1450, -1.5 if index % 2 else 1.5, border=22)
        x = (width - tablet.width) // 2 + (24 if index % 2 else -24)
        y = 680
        paste_shadow(canvas, tablet, (x, y), 48)
        canvas.convert("RGB").save(
            destination / f"{index:02d}-{source}-2064x2752.jpg",
            quality=94,
            optimize=True,
            progressive=True,
        )


if __name__ == "__main__":
    render_wide_assets()
    # These previews use only screenshots captured from the real Duo simulator display.
    render_duo_previews()
    render_standard_iphone_previews()
    render_ipad_previews()
