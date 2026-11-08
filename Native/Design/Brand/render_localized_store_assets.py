from __future__ import annotations

from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

from render_connect_assets import (
    BACKGROUND,
    ROOT,
    cover,
    paste_shadow,
    phone_card,
    pill,
    wordmark,
)


APPSTORE = ROOT / "AppStore"
SYSTEM_FONTS = Path("/System/Library/Fonts")
USER_FONTS = Path.home() / "Library" / "Fonts"

FONT_CONFIG = {
    "en": {
        "black": SYSTEM_FONTS / "Avenir Next.ttc",
        "medium": SYSTEM_FONTS / "Avenir Next.ttc",
        "accent": USER_FONTS / "JasonHandwriting6.ttf",
    },
    "ja": {
        "black": SYSTEM_FONTS / "ヒラギノ角ゴシック W8.ttc",
        "medium": SYSTEM_FONTS / "ヒラギノ角ゴシック W4.ttc",
        "accent": SYSTEM_FONTS / "ヒラギノ角ゴシック W4.ttc",
    },
    "ko": {
        "black": SYSTEM_FONTS / "AppleSDGothicNeo.ttc",
        "medium": SYSTEM_FONTS / "AppleSDGothicNeo.ttc",
        "accent": SYSTEM_FONTS / "AppleSDGothicNeo.ttc",
    },
}

COPY = {
    "en": {
        "wide_title": (
            "WORLD FLAG CHALLENGE",
            "Discover the world",
            "One flag at a time",
            "Challenge, explore, review, and build your own flag collection.",
        ),
        "wide_search": (
            "PLAY ONE ROUND. DISCOVER ONE MORE COUNTRY.",
            "198 world flags",
            "Ready for your challenge",
            "Quick quizzes, six regions, and similar-flag training.",
        ),
        "badges": ("6 regions", "Spaced review", "4 languages"),
        "screens": [
            ("home", "Discover the world", "One flag at a time", "Choose a mode and begin your flag challenge."),
            ("game", "Name that flag", "Which country?", "Find the correct answer from four choices."),
            ("answer", "One answer", "One new discovery", "Learn a little more before the next challenge."),
            ("journeys", "Choose a region", "Start your journey", "Six regions, each with flags to discover."),
            ("records", "Your flag collection", "How many remain?", "Track progress and find flags to practice."),
            ("results", "Round complete", "Practice mistakes", "Review your score and retry missed flags."),
            ("pause", "Take a break", "Continue when ready", "Return to the question or restart the round."),
        ],
    },
    "ja": {
        "wide_title": (
            "世界の国旗に挑戦",
            "国旗から",
            "世界を知ろう",
            "挑戦・探索・復習で、自分だけの国旗図鑑を完成させよう。",
        ),
        "wide_search": (
            "1プレイごとに、世界をひとつ発見",
            "198の国旗に",
            "挑戦しよう",
            "4択クイズ、6地域の旅、似た国旗の見分け方。",
        ),
        "badges": ("6地域を探索", "間隔復習", "4言語対応"),
        "screens": [
            ("home", "世界を知ろう", "一枚の国旗から", "プレイ方法を選んで、国旗チャレンジを始めよう。"),
            ("game", "この国旗は", "どこの国？", "4つの選択肢から正解を見つけよう。"),
            ("answer", "1問ごとに", "世界が広がる", "答えとヒントを確認して、次の問題へ。"),
            ("journeys", "地域を選んで", "国旗の旅へ", "6つの地域で、さまざまな国旗を発見しよう。"),
            ("records", "国旗コレクション", "あと何枚？", "進捗を確認して、苦手な国旗を練習しよう。"),
            ("results", "ラウンド終了", "間違いを復習", "成績を確認して、間違えた国旗に再挑戦。"),
            ("pause", "ひと休み", "準備できたら再開", "元の問題に戻るか、最初からやり直せます。"),
        ],
    },
    "ko": {
        "wide_title": (
            "세계 국기 도전",
            "국기 한 장으로",
            "세계를 만나 보세요",
            "도전·탐험·복습으로 나만의 국기 도감을 완성하세요.",
        ),
        "wide_search": (
            "한 번 플레이할 때마다 새로운 나라를 발견",
            "198개의 국기",
            "도전해 보세요",
            "빠른 퀴즈, 6개 지역 여행, 비슷한 국기 구별 연습.",
        ),
        "badges": ("6개 지역", "간격 복습", "4개 언어"),
        "screens": [
            ("home", "세계를 만나 보세요", "국기 한 장부터", "플레이 방식을 선택하고 국기 도전을 시작하세요."),
            ("game", "이 국기는", "어느 나라일까요?", "네 개의 선택지에서 정답을 찾아보세요."),
            ("answer", "한 문제마다", "새로운 나라를 발견", "정답과 힌트를 확인하고 다음 문제에 도전하세요."),
            ("journeys", "지역을 선택하고", "국기 여행 시작", "6개 지역의 다양한 국기를 만나보세요."),
            ("records", "나의 국기 도감", "얼마나 남았을까요?", "진행도를 확인하고 부족한 국기를 연습하세요."),
            ("results", "라운드 완료", "오답 다시 도전", "결과를 확인하고 틀린 국기를 다시 연습하세요."),
            ("pause", "잠시 쉬어 가세요", "준비되면 계속", "문제로 돌아가거나 라운드를 다시 시작하세요."),
        ],
    },
}


def get_font(lang: str, weight: str, size: int) -> ImageFont.FreeTypeFont:
    return ImageFont.truetype(str(FONT_CONFIG[lang][weight]), size)


def fit_font(lang: str, weight: str, text: str, start: int, max_width: int, minimum: int) -> ImageFont.FreeTypeFont:
    size = start
    while size > minimum:
        candidate = get_font(lang, weight, size)
        box = candidate.getbbox(text)
        if box[2] - box[0] <= max_width:
            return candidate
        size -= 2
    return get_font(lang, weight, minimum)


def add_wide_copy(canvas: Image.Image, lang: str, copy: tuple[str, str, str, str]) -> None:
    kicker, first, second, subtitle = copy
    draw = ImageDraw.Draw(canvas)
    x, y = 300, 470
    draw.text((x, y), kicker, font=fit_font(lang, "accent", kicker, 92, 2700, 58), fill="#74F4D3")
    draw.text(
        (x, y + 145), first,
        font=fit_font(lang, "black", first, 214, 2700, 130),
        fill="#FFFFFF", stroke_width=3, stroke_fill="#080414",
    )
    draw.text(
        (x, y + 375), second,
        font=fit_font(lang, "black", second, 214, 2700, 130),
        fill="#C4B5FD", stroke_width=3, stroke_fill="#080414",
    )
    draw.text(
        (x, y + 655), subtitle,
        font=fit_font(lang, "medium", subtitle, 76, 2750, 48), fill="#E7E4F4",
    )


def raw_path(lang: str, family: str, index: int, source: str) -> Path:
    return APPSTORE / lang / family / f"{index:02d}-{source}.jpg"


def render_wide(lang: str) -> None:
    output = APPSTORE / lang / "Creative"
    output.mkdir(parents=True, exist_ok=True)
    size = (5244, 2950)
    background = cover(Image.open(BACKGROUND).convert("RGB"), size).convert("RGBA")

    title = background.copy()
    add_wide_copy(title, lang, COPY[lang]["wide_title"])
    mark = wordmark(710)
    title.alpha_composite(mark, (380, 1720))
    home = phone_card(Image.open(raw_path(lang, "iPhone-Raw", 1, "home")).convert("RGB"), 1130, -9)
    game = phone_card(Image.open(raw_path(lang, "iPhone-Raw", 2, "game")).convert("RGB"), 1030, 10)
    paste_shadow(title, game, (3920, 280), 55)
    paste_shadow(title, home, (3000, 300), 60)
    title.convert("RGB").save(output / "title-5244x2950.png", optimize=True)

    search = background.copy()
    add_wide_copy(search, lang, COPY[lang]["wide_search"])
    for x, label, dot in zip((320, 1190, 2060), COPY[lang]["badges"], ("#FF7855", "#62F2CF", "#FFD23F")):
        # The shared badge renderer uses a playful font; localized fonts are used for Japanese/Korean below.
        if lang == "en":
            pill(search, (x, 1900), label, 84, dot, dark=True)
        else:
            badge_font = get_font(lang, "medium", 72)
            bbox = badge_font.getbbox(label)
            badge_w = bbox[2] - bbox[0] + 160
            badge_h = 136
            badge = Image.new("RGBA", (badge_w, badge_h))
            badge_draw = ImageDraw.Draw(badge)
            badge_draw.rounded_rectangle((0, 0, badge_w - 1, badge_h - 1), 44, fill="#25164D", outline="#6EF2D4", width=3)
            badge_draw.ellipse((40, 48, 72, 80), fill=dot)
            badge_draw.text((94, badge_h // 2), label, font=badge_font, fill="#F8FAFF", anchor="lm")
            search.alpha_composite(badge, (x, 1900))
    journeys = phone_card(Image.open(raw_path(lang, "iPhone-Raw", 4, "journeys")).convert("RGB"), 1110, -8)
    answer = phone_card(Image.open(raw_path(lang, "iPhone-Raw", 3, "answer")).convert("RGB"), 1000, 9)
    paste_shadow(search, answer, (4060, 300), 55)
    paste_shadow(search, journeys, (3100, 260), 60)
    search.convert("RGB").save(output / "search-result-5244x2950.png", optimize=True)


def preview_canvas(width: int, height: int) -> Image.Image:
    canvas = cover(Image.open(BACKGROUND).convert("RGB"), (width, height)).convert("RGBA")
    canvas.alpha_composite(Image.new("RGBA", canvas.size, (5, 2, 18, 82)))
    return canvas


def preview_header(canvas: Image.Image, lang: str, first: str, second: str, subtitle: str, scale: float) -> None:
    draw = ImageDraw.Draw(canvas)
    width = canvas.width
    draw.ellipse(tuple(round(v * scale) for v in (-480, 740, 1800, 3060)), fill=(76, 42, 154, 60))
    draw.arc(tuple(round(v * scale) for v in (-420, 790, 1740, 2980)), 194, 338, fill="#5CECCB", width=max(3, round(4 * scale)))
    margin = round(64 * scale)
    max_text = width - margin * 2 - round(170 * scale)
    draw.text(
        (margin, round(58 * scale)), first,
        font=fit_font(lang, "black", first, round(126 * scale), max_text, round(70 * scale)),
        fill="#FFFFFF", stroke_width=max(2, round(2 * scale)), stroke_fill="#080414",
    )
    draw.text(
        (margin, round(190 * scale)), second,
        font=fit_font(lang, "black", second, round(132 * scale), max_text, round(70 * scale)),
        fill="#C4B5FD", stroke_width=max(2, round(2 * scale)), stroke_fill="#080414",
    )
    draw.text(
        (round(70 * scale), round(370 * scale)), subtitle,
        font=fit_font(lang, "medium", subtitle, round(46 * scale), width - round(140 * scale), round(28 * scale)),
        fill="#ECE9F8",
    )
    mark = wordmark(round(185 * scale))
    canvas.alpha_composite(mark, (width - mark.width - round(50 * scale), round(34 * scale)))


def render_phone_family(lang: str, family: str, output_name: str, width: int, height: int, phone_width: int, y: int, angle: float) -> None:
    output = APPSTORE / lang / output_name
    output.mkdir(parents=True, exist_ok=True)
    scale = width / 1320
    for index, (source, first, second, subtitle) in enumerate(COPY[lang]["screens"], 1):
        canvas = preview_canvas(width, height)
        preview_header(canvas, lang, first, second, subtitle, scale)
        shot = Image.open(raw_path(lang, family, index, source)).convert("RGB")
        phone = phone_card(shot, round(phone_width * scale), -angle if index % 2 else angle)
        x = (width - phone.width) // 2 + round((24 if index % 2 else -24) * scale)
        paste_shadow(canvas, phone, (x, round(y * scale)), round(38 * scale))
        canvas.convert("RGB").save(output / f"{index:02d}-{source}.jpg", quality=94, optimize=True, progressive=True)


def render_ipad(lang: str) -> None:
    output = APPSTORE / lang / "iPad-13-Preview"
    output.mkdir(parents=True, exist_ok=True)
    width, height = 2064, 2752
    for index, (source, first, second, subtitle) in enumerate(COPY[lang]["screens"], 1):
        canvas = preview_canvas(width, height)
        preview_header(canvas, lang, first, second, subtitle, width / 1320)
        shot = Image.open(raw_path(lang, "iPad-13-Raw", index, source)).convert("RGB")
        tablet = phone_card(shot, 1450, -1.5 if index % 2 else 1.5, border=22)
        x = (width - tablet.width) // 2 + (24 if index % 2 else -24)
        paste_shadow(canvas, tablet, (x, 680), 48)
        canvas.convert("RGB").save(output / f"{index:02d}-{source}.jpg", quality=94, optimize=True, progressive=True)


def render_language(lang: str) -> None:
    render_wide(lang)
    # App Store Connect's medium Dynamic Island slot accepts 1206 x 2622 portrait screenshots.
    render_phone_family(lang, "iPhone-Raw", "iPhone-Dynamic-Island-Medium", 1206, 2622, 850, 650, 2)
    render_phone_family(lang, "iPhone-Duo-Raw", "iPhone-Duo-Preview", 1398, 2034, 887, 535, 2)
    render_ipad(lang)


if __name__ == "__main__":
    for language in ("en", "ja", "ko"):
        render_language(language)
