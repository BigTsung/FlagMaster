from __future__ import annotations

from pathlib import Path
from PIL import Image, ImageDraw, ImageFilter, ImageFont


ROOT = Path(__file__).resolve().parents[1]
OUTPUT = ROOT / "AppStore" / "zh-Hant"
BACKGROUND = ROOT / "Brand" / "store-night-background-v2.png"
PREVIEWS = ROOT / "Previews" / "iPhone17Pro"
WORDMARK = ROOT / "Brand" / "FlagMaster-Wordmark.png"

FONT_DIR = Path.home() / "Library" / "Fonts"
FONT_BLACK = FONT_DIR / "ChironGoRoundTC-Black.ttf"
FONT_MEDIUM = FONT_DIR / "ChironGoRoundTC-Medium.ttf"
FONT_HAND = FONT_DIR / "JasonHandwriting6.ttf"


def font(path: Path, size: int) -> ImageFont.FreeTypeFont:
    return ImageFont.truetype(str(path), size)


def cover(image: Image.Image, size: tuple[int, int]) -> Image.Image:
    scale = max(size[0] / image.width, size[1] / image.height)
    resized = image.resize(
        (round(image.width * scale), round(image.height * scale)),
        Image.Resampling.LANCZOS,
    )
    left = (resized.width - size[0]) // 2
    top = (resized.height - size[1]) // 2
    return resized.crop((left, top, left + size[0], top + size[1]))


def rounded_mask(size: tuple[int, int], radius: int) -> Image.Image:
    result = Image.new("L", size)
    ImageDraw.Draw(result).rounded_rectangle(
        (0, 0, size[0] - 1, size[1] - 1), radius, fill=255
    )
    return result


def remove_white_background(image: Image.Image) -> Image.Image:
    rgba = image.convert("RGBA")
    pixels = []
    for red, green, blue, _ in rgba.getdata():
        distance = max(255 - red, 255 - green, 255 - blue)
        alpha = max(0, min(255, (distance - 8) * 8))
        pixels.append((red, green, blue, alpha))
    rgba.putdata(pixels)
    return rgba


def wordmark(width: int) -> Image.Image:
    mark = remove_white_background(Image.open(WORDMARK))
    mark.thumbnail((width, width), Image.Resampling.LANCZOS)
    return mark


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
        fill="#25164D" if dark else "white",
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
        stroke_width=max(2, round(3 * scale)), stroke_fill="#080414",
    )
    draw.text(
        (x, y + round(375 * scale)), line_two,
        font=font(FONT_BLACK, round(214 * scale)), fill="#C4B5FD",
        stroke_width=max(2, round(3 * scale)), stroke_fill="#080414",
    )
    draw.text(
        (x, y + round(655 * scale)), subtitle,
        font=font(FONT_MEDIUM, round(76 * scale)), fill="#E7E4F4",
    )


def render_wide_assets() -> None:
    destination = OUTPUT / "Creative"
    destination.mkdir(parents=True, exist_ok=True)
    size = (5244, 2950)
    background = cover(Image.open(BACKGROUND).convert("RGB"), size).convert("RGBA")

    title = background.copy()
    add_copy(
        title,
        "世界國旗挑戰",
        "玩著認識世界",
        "一面旗，開啟旅程",
        "挑戰、探索、複習，把世界裝進你的國旗圖鑑。",
        (300, 470),
        1.0,
    )
    mark = wordmark(710)
    title.alpha_composite(mark, (380, 1720))
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
    ("home", "認識世界", "從一面旗開始", "選擇玩法，開始你的國旗挑戰。", "#F5F5F3"),
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
        canvas = cover(Image.open(BACKGROUND).convert("RGB"), (width, height)).convert("RGBA")
        canvas.alpha_composite(Image.new("RGBA", canvas.size, (5, 2, 18, 76)))
        draw = ImageDraw.Draw(canvas)
        draw.ellipse((-420, 650, 1780, 2390), fill=(76, 42, 154, 62))
        draw.arc((-360, 690, 1700, 2280), 194, 338, fill="#5CECCB", width=4)
        draw.text(
            (70, 52), line_one, font=font(FONT_BLACK, 126), fill="#FFFFFF",
            stroke_width=2, stroke_fill="#080414",
        )
        draw.text(
            (70, 185), line_two, font=font(FONT_BLACK, 132), fill="#C4B5FD",
            stroke_width=2, stroke_fill="#080414",
        )
        draw.text((76, 365), subtitle, font=font(FONT_MEDIUM, 48), fill="#ECE9F8")
        mark = wordmark(190)
        canvas.alpha_composite(mark, (width - mark.width - 54, 34))

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
            canvas = cover(Image.open(BACKGROUND).convert("RGB"), (width, height)).convert("RGBA")
            canvas.alpha_composite(Image.new("RGBA", canvas.size, (5, 2, 18, 82)))
            draw = ImageDraw.Draw(canvas)
            draw.ellipse(
                tuple(round(value * scale) for value in (-480, 740, 1800, 3060)),
                fill=(76, 42, 154, 60),
            )
            draw.arc(
                tuple(round(value * scale) for value in (-420, 790, 1740, 2980)),
                194,
                338,
                fill="#5CECCB",
                width=max(3, round(4 * scale)),
            )
            draw.text(
                (round(64 * scale), round(58 * scale)),
                line_one,
                font=font(FONT_BLACK, round(126 * scale)),
                fill="#FFFFFF",
                stroke_width=max(2, round(2 * scale)),
                stroke_fill="#080414",
            )
            draw.text(
                (round(64 * scale), round(190 * scale)),
                line_two,
                font=font(FONT_BLACK, round(132 * scale)),
                fill="#C4B5FD",
                stroke_width=max(2, round(2 * scale)),
                stroke_fill="#080414",
            )
            draw.text(
                (round(70 * scale), round(370 * scale)),
                subtitle,
                font=font(FONT_MEDIUM, round(46 * scale)),
                fill="#ECE9F8",
            )
            mark = wordmark(round(185 * scale))
            canvas.alpha_composite(mark, (width - mark.width - round(50 * scale), round(34 * scale)))

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
        canvas = cover(Image.open(BACKGROUND).convert("RGB"), (width, height)).convert("RGBA")
        canvas.alpha_composite(Image.new("RGBA", canvas.size, (5, 2, 18, 82)))
        draw = ImageDraw.Draw(canvas)
        draw.ellipse((-620, 730, 2700, 3200), fill=(76, 42, 154, 62))
        draw.arc((-560, 790, 2600, 3120), 194, 338, fill="#5CECCB", width=6)
        draw.text(
            (86, 66), line_one, font=font(FONT_BLACK, 160), fill="#FFFFFF",
            stroke_width=3, stroke_fill="#080414",
        )
        draw.text(
            (86, 232), line_two, font=font(FONT_BLACK, 170), fill="#C4B5FD",
            stroke_width=3, stroke_fill="#080414",
        )
        draw.text((94, 462), subtitle, font=font(FONT_MEDIUM, 62), fill="#ECE9F8")
        mark = wordmark(255)
        canvas.alpha_composite(mark, (width - mark.width - 72, 46))

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
    if not BACKGROUND.exists():
        raise SystemExit(f"Missing generated background: {BACKGROUND}")
    render_wide_assets()
    # These previews use only screenshots captured from the real Duo simulator display.
    render_duo_previews()
    render_standard_iphone_previews()
    render_ipad_previews()
