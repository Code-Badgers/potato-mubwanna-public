from pathlib import Path

from PIL import Image, ImageDraw, ImageFont


ROOT = Path(__file__).resolve().parents[3]
SOURCE = Path(__file__).with_name("stamp_base_source.png")
OUTPUT = ROOT / "frontend" / "assets" / "stamps"
CONTACT_SHEET = Path(__file__).with_name("stamp_contact_sheet.png")
FONT = Path(r"C:\Windows\Fonts\malgunbd.ttf")

STAMPS = {
    "nami_island": "남이섬",
    "soyang_skywalk": "소양강\n스카이워크",
    "museum_san": "뮤지엄 산",
    "anmok_beach": "안목해변",
    "gyeongpodae": "경포대",
    "mukho_lighthouse": "묵호등대",
    "nongoldam_road": "논골담길",
    "hwangji_pond": "황지연못",
    "sokcho_market": "속초관광\n수산시장",
    "yeonggeumjeong": "영금정",
    "hwanseon_cave": "환선굴",
    "jangho_port": "장호항",
    "sutasa": "수타사",
    "vivaldi_park": "비발디파크",
    "hoengseong_lake_trail": "횡성호수길",
    "cheongnyeongpo": "청령포",
    "jangneung": "장릉",
    "daegwallyeong_sheep_ranch": "대관령\n양떼목장",
    "lee_hyoseok_museum": "이효석\n문학관",
    "jeongseon_market": "정선 5일장",
    "goseokjeong": "고석정",
    "sancheoneo_festival": "산천어\n축제장",
    "park_sookeun_museum": "박수근\n미술관",
    "dutayeon": "두타연",
    "wondaeri_birch_forest": "원대리\n자작나무숲",
    "unification_observatory": "통일전망대",
    "hwajinpo": "화진포",
    "surfyy_beach": "서피비치",
    "naksansa": "낙산사",
}


def remove_magenta(image: Image.Image) -> Image.Image:
    rgba = image.convert("RGBA")
    pixels = rgba.load()
    for y in range(rgba.height):
        for x in range(rgba.width):
            red, green, blue, alpha = pixels[x, y]
            if red > 205 and blue > 150 and green < 110:
                pixels[x, y] = (red, green, blue, 0)
            elif red > 190 and blue > 135 and green < 135:
                # Fade antialiased chroma-key edge pixels instead of leaving a halo.
                distance = max(red - green, blue - green)
                pixels[x, y] = (red, green, blue, max(0, 255 - distance * 2))
    return rgba


def clear_chroma_halo(image: Image.Image) -> Image.Image:
    pixels = image.load()
    for y in range(image.height):
        for x in range(image.width):
            red, green, blue, alpha = pixels[x, y]
            if red > green * 1.15 and blue > green * 1.1:
                pixels[x, y] = (0, 0, 0, 0)
            elif alpha == 0:
                pixels[x, y] = (0, 0, 0, 0)
    return image


def fit_font(draw: ImageDraw.ImageDraw, text: str) -> ImageFont.FreeTypeFont:
    max_width = 150
    max_height = 88
    for size in range(46, 19, -1):
        font = ImageFont.truetype(str(FONT), size)
        bounds = draw.multiline_textbbox((0, 0), text, font=font, spacing=2, align="center")
        if bounds[2] - bounds[0] <= max_width and bounds[3] - bounds[1] <= max_height:
            return font
    return ImageFont.truetype(str(FONT), 20)


def main() -> None:
    OUTPUT.mkdir(parents=True, exist_ok=True)
    base = remove_magenta(Image.open(SOURCE))
    alpha = base.getchannel("A")
    bounds = alpha.getbbox()
    if bounds is None:
        raise RuntimeError("Generated stamp base has no visible pixels")
    base = base.crop(bounds).resize((240, 240), Image.Resampling.LANCZOS)

    generated = []
    for slug, label in STAMPS.items():
        canvas = Image.new("RGBA", (256, 256), (0, 0, 0, 0))
        canvas.alpha_composite(base, (8, 8))
        draw = ImageDraw.Draw(canvas)
        font = fit_font(draw, label)
        center = (128, 125)
        draw.multiline_text(
            center,
            label,
            font=font,
            fill=(61, 105, 55, 255),
            anchor="mm",
            align="center",
            spacing=2,
            stroke_width=1,
            stroke_fill=(252, 248, 227, 210),
        )
        clear_chroma_halo(canvas).save(OUTPUT / f"{slug}.png", optimize=True)
        generated.append(canvas.copy())

    sheet = Image.new("RGB", (5 * 180, 6 * 180), (239, 246, 235))
    for index, stamp in enumerate(generated):
        thumbnail = stamp.resize((156, 156), Image.Resampling.LANCZOS)
        x = (index % 5) * 180 + 12
        y = (index // 5) * 180 + 12
        sheet.paste(thumbnail, (x, y), thumbnail)
    sheet.save(CONTACT_SHEET, optimize=True)


if __name__ == "__main__":
    main()
