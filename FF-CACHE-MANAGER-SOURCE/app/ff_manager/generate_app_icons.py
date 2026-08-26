import sys
from pathlib import Path

from PIL import Image, ImageDraw


ICON_SIZES = {
    "AppIcon60x60@2x.png": 120,
    "AppIcon60x60@3x.png": 180,
    "AppIcon76x76.png": 76,
    "AppIcon76x76@2x.png": 152,
    "AppIcon83.5x83.5@2x.png": 167,
    "AppIcon1024.png": 1024,
}


def square_crop(image):
    edge = min(image.width, image.height)
    left = (image.width - edge) // 2
    top = (image.height - edge) // 2
    return image.crop((left, top, left + edge, top + edge))


def fallback_brand():
    """Create a self-contained FF Cache Manager launcher mark for reproducible builds."""
    image = Image.new("RGB", (1024, 1024), "#080d1b")
    draw = ImageDraw.Draw(image)
    draw.rounded_rectangle((36, 36, 988, 988), radius=216, fill="#0d1930",
                           outline="#37d2ff", width=28)
    draw.rounded_rectangle((86, 86, 938, 938), radius=176, outline="#f5b542", width=12)

    # A font-independent robot face makes the brand unambiguous even where a
    # custom typeface is unavailable during the Windows cross-build.
    cyan = "#37d2ff"
    gold = "#f5b542"
    dark = "#080d1b"
    draw.rounded_rectangle((206, 278, 818, 734), radius=132, fill=cyan, outline="#ffffff", width=18)
    draw.rounded_rectangle((270, 358, 754, 604), radius=76, fill=dark)
    draw.rounded_rectangle((320, 424, 406, 510), radius=28, fill=gold)
    draw.rounded_rectangle((618, 424, 704, 510), radius=28, fill=gold)
    draw.rounded_rectangle((420, 628, 604, 660), radius=16, fill="#ffffff")
    draw.rounded_rectangle((490, 164, 534, 278), radius=22, fill=gold)
    draw.ellipse((456, 116, 568, 228), fill=cyan, outline="#ffffff", width=12)
    draw.rounded_rectangle((236, 790, 788, 838), radius=24, fill="#ffffff")
    draw.rounded_rectangle((354, 868, 670, 900), radius=16, fill=gold)
    return image


def main():
    if len(sys.argv) != 3:
        raise SystemExit("usage: generate_app_icons.py SOURCE_IMAGE|--fallback APP_DIRECTORY")
    source_arg = sys.argv[1]
    source = Path(source_arg)
    app = Path(sys.argv[2])
    if not app.is_dir():
        raise RuntimeError("Application directory is unavailable")
    if source_arg == "--fallback":
        image = fallback_brand()
    else:
        if not source.is_file():
            raise RuntimeError("Icon source is unavailable")
        with Image.open(source) as loaded:
            image = square_crop(loaded.convert("RGB"))
    for name, size in ICON_SIZES.items():
        icon = image.resize((size, size), Image.Resampling.LANCZOS)
        icon.save(app / name, "PNG", optimize=True)
    print("APP_ICON_GENERATION_PASS")


if __name__ == "__main__":
    main()
