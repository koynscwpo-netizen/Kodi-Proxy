"""Render the original FF CACHE MANAGER launcher/background artwork."""

from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter


SCALE = 2
SIZE = 1024 * SCALE
OUTPUT = Path(__file__).with_name("FFCacheManagerBackground.jpg")


def point(value):
    return int(value * SCALE)


def color_at(first, second, ratio):
    return tuple(round(a + (b - a) * ratio) for a, b in zip(first, second))


def glow(base, center, radius, color):
    layer = Image.new("RGBA", base.size)
    draw = ImageDraw.Draw(layer)
    x, y = map(point, center)
    draw.ellipse((x - point(radius), y - point(radius), x + point(radius), y + point(radius)), fill=color)
    return layer.filter(ImageFilter.GaussianBlur(point(radius) // 2))


def main():
    background = Image.new("RGB", (SIZE, SIZE))
    pixels = background.load()
    for y in range(SIZE):
        for x in range(SIZE):
            diagonal = min(1.0, (x * 0.40 + y * 0.85) / (SIZE * 1.25))
            pixels[x, y] = color_at((5, 20, 40), (4, 12, 27), diagonal)

    art = Image.new("RGBA", (SIZE, SIZE))
    draw = ImageDraw.Draw(art)
    cx = cy = point(512)
    draw.rounded_rectangle((0, 0, SIZE, SIZE), radius=point(218), fill=(5, 20, 40, 255))

    art.alpha_composite(glow(art, (512, 430), 230, (17, 210, 250, 90)))
    art.alpha_composite(glow(art, (690, 730), 190, (101, 76, 250, 75)))

    for radius, width, color in ((385, 11, (27, 83, 116, 220)), (342, 26, (42, 220, 255, 255)), (310, 4, (191, 250, 255, 160))):
        box = (cx - point(radius), cy - point(radius), cx + point(radius), cy + point(radius))
        draw.ellipse(box, outline=color, width=point(width))

    shield = [(point(512), point(144)), (point(777), point(256)), (point(777), point(468)),
              (point(730), point(642)), (point(642), point(784)), (point(512), point(886)),
              (point(382), point(784)), (point(294), point(642)), (point(247), point(468)),
              (point(247), point(256))]
    draw.polygon(shield, fill=(9, 35, 60, 255), outline=(51, 219, 255, 255), width=point(19))
    inner = [(point(512), point(198)), (point(726), point(288)), (point(726), point(467)),
             (point(676), point(646)), (point(596), point(764)), (point(512), point(821)),
             (point(428), point(764)), (point(348), point(646)), (point(298), point(467)),
             (point(298), point(288))]
    draw.polygon(inner, fill=(12, 55, 82, 255))

    # Antenna and chassis.
    draw.line((point(512), point(295), point(512), point(222)), fill=(122, 238, 255, 255), width=point(16))
    draw.ellipse((point(470), point(210), point(554), point(294)), fill=(16, 50, 76, 255), outline=(106, 240, 255, 255), width=point(10))
    draw.ellipse((point(494), point(234), point(530), point(270)), fill=(88, 250, 255, 255))

    head_box = (point(321), point(383), point(703), point(692))
    draw.rounded_rectangle(head_box, radius=point(112), fill=(43, 96, 128, 255), outline=(205, 250, 255, 255), width=point(10))
    draw.rounded_rectangle((point(338), point(400), point(686), point(674)), radius=point(92), fill=(25, 63, 91, 255))
    draw.rounded_rectangle((point(363), point(444), point(661), point(582)), radius=point(56), fill=(4, 25, 41, 255), outline=(77, 235, 255, 255), width=point(9))

    # Ears and illuminated face.
    draw.rounded_rectangle((point(286), point(483), point(355), point(587)), radius=point(28), fill=(43, 102, 135, 255), outline=(155, 248, 255, 255), width=point(7))
    draw.rounded_rectangle((point(669), point(483), point(738), point(587)), radius=point(28), fill=(43, 102, 135, 255), outline=(155, 248, 255, 255), width=point(7))
    eye_glow = Image.new("RGBA", art.size)
    eye = ImageDraw.Draw(eye_glow)
    eye.polygon([(point(401), point(508)), (point(475), point(508)), (point(448), point(538)), (point(376), point(538))], fill=(50, 245, 255, 230))
    eye.polygon([(point(623), point(508)), (point(549), point(508)), (point(576), point(538)), (point(648), point(538))], fill=(50, 245, 255, 230))
    art.alpha_composite(eye_glow.filter(ImageFilter.GaussianBlur(point(13))))
    art.alpha_composite(eye_glow)
    draw = ImageDraw.Draw(art)
    draw.arc((point(431), point(586), point(593), point(651)), 12, 168, fill=(104, 238, 255, 255), width=point(7))
    draw.arc((point(431), point(586), point(593), point(651)), 12, 168, fill=(7, 40, 63, 255), width=point(18))
    draw.arc((point(440), point(598), point(584), point(643)), 15, 165, fill=(96, 237, 255, 255), width=point(5))

    # External signal motif: precisely four bright nodes and radial traces.
    for x, y, hue in ((207, 377, (62, 245, 255, 255)), (817, 377, (62, 245, 255, 255)),
                      (179, 514, (149, 102, 255, 255)), (845, 514, (149, 102, 255, 255))):
        art.alpha_composite(glow(art, (x, y), 24, hue))
        draw.ellipse((point(x - 9), point(y - 9), point(x + 9), point(y + 9)), fill=hue)
    traces = (
        (((162, 628), (284, 628)), (58, 220, 250, 190)),
        (((740, 628), (862, 628)), (135, 100, 255, 190)),
    )
    for (start, end), hue in traces:
        draw.line((point(start[0]), point(start[1]), point(end[0]), point(end[1])), fill=hue, width=point(8))

    draw.arc((point(332), point(666), point(692), point(877)), 22, 158, fill=(115, 88, 255, 255), width=point(18))
    draw.arc((point(352), point(685), point(672), point(855)), 22, 158, fill=(84, 228, 250, 210), width=point(7))

    background = Image.alpha_composite(background.convert("RGBA"), art).convert("RGB")
    background.resize((1024, 1024), Image.Resampling.LANCZOS).save(OUTPUT, "JPEG", quality=96, optimize=True)
    print(OUTPUT)


if __name__ == "__main__":
    main()
