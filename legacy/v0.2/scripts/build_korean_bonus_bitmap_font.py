"""Build a Korean BMFont atlas matching Project Reignition's Bonus.fnt look."""

from __future__ import annotations

import json
import math
from pathlib import Path

from PIL import Image, ImageChops, ImageDraw, ImageFilter, ImageFont


ROOT = Path(__file__).resolve().parents[1]
TRANSLATION = ROOT / "translation" / "human_translation_ko.json"
FONT = ROOT / "korean-pack-project" / "Hakgyoansim_SangjangR.ttf"
OUTPUT = ROOT / "korean-pack-project"

ATLAS_SIZE = 1024
CELL_SIZE = 100
CELLS_PER_ROW = ATLAS_SIZE // CELL_SIZE
CELLS_PER_PAGE = CELLS_PER_ROW * CELLS_PER_ROW
FONT_SIZE = 72
LINE_HEIGHT = 80
BASELINE = 66


def is_korean(character: str) -> bool:
    code = ord(character)
    return (
        0x1100 <= code <= 0x11FF
        or 0x3130 <= code <= 0x318F
        or 0xAC00 <= code <= 0xD7A3
    )


def shifted(mask: Image.Image, x: int, y: int) -> Image.Image:
    result = Image.new("L", mask.size)
    result.paste(mask, (x, y))
    return result


def render_glyph(character: str, font: ImageFont.FreeTypeFont) -> Image.Image:
    size = CELL_SIZE
    center = size // 2

    glyph_mask = Image.new("L", (size, size))
    draw_mask = ImageDraw.Draw(glyph_mask)
    draw_mask.text((center, center - 1), character, font=font, fill=255, anchor="mm")

    # The original Bonus.fnt uses a compact two-step edge. Keep only about
    # two pixels of red and another two pixels of dark shadow at source size.
    outer = glyph_mask.filter(ImageFilter.MaxFilter(9))
    red_border = glyph_mask.filter(ImageFilter.MaxFilter(5))

    image = Image.new("RGBA", (size, size))
    image.paste((35, 7, 5, 255), mask=outer)
    image.paste((126, 24, 19, 255), mask=red_border)

    # Warm paper-colored face, like the original bitmap font.
    face = Image.new("RGBA", (size, size), (255, 245, 223, 255))
    image.paste(face, mask=glyph_mask)

    # Inner lower-right red shade. Subtracting a shifted mask leaves only the
    # inside edge, instead of producing a second external drop shadow.
    inner_edge = ImageChops.subtract(glyph_mask, shifted(glyph_mask, -1, -1))
    inner_edge = inner_edge.filter(ImageFilter.GaussianBlur(0.3))
    image.paste((154, 43, 34, 230), mask=inner_edge)

    # Fine top-left highlight gives the face the same embossed direction.
    highlight = ImageChops.subtract(glyph_mask, shifted(glyph_mask, 1, 1))
    highlight = highlight.filter(ImageFilter.GaussianBlur(0.35))
    image.paste((255, 255, 247, 210), mask=highlight)
    return image


def main() -> None:
    document = json.loads(TRANSLATION.read_text(encoding="utf-8"))
    characters = sorted(
        {
            character
            for entry in document["entries"]
            for character in entry["ko"]
            if is_korean(character)
        },
        key=ord,
    )
    font = ImageFont.truetype(str(FONT), FONT_SIZE)
    page_count = math.ceil(len(characters) / CELLS_PER_PAGE)
    pages = [Image.new("RGBA", (ATLAS_SIZE, ATLAS_SIZE)) for _ in range(page_count)]

    char_lines: list[str] = []
    for index, character in enumerate(characters):
        page_index = index // CELLS_PER_PAGE
        cell_index = index % CELLS_PER_PAGE
        column = cell_index % CELLS_PER_ROW
        row = cell_index // CELLS_PER_ROW
        x = column * CELL_SIZE
        y = row * CELL_SIZE
        pages[page_index].alpha_composite(render_glyph(character, font), (x, y))
        advance = max(45, round(font.getlength(character)))
        char_lines.append(
            f"char id={ord(character)} x={x} y={y} width={CELL_SIZE} height={CELL_SIZE} "
            f"xoffset=-10 yoffset=-10 xadvance={advance} page={page_index} chnl=15"
        )

    page_lines = []
    for page_index, page in enumerate(pages):
        filename = f"KoreanBonus_{page_index}.png"
        page.save(OUTPUT / filename, optimize=True)
        page_lines.append(f'page id={page_index} file="{filename}"')

    descriptor = [
        'info face="Hakgyoansim Sangjang Reignition Thin" size=80 bold=0 italic=0 charset="" unicode=1 stretchH=100 smooth=1 aa=1 padding=10,10,10,10 spacing=1,1 outline=0',
        f"common lineHeight={LINE_HEIGHT} base={BASELINE} scaleW={ATLAS_SIZE} scaleH={ATLAS_SIZE} pages={page_count} packed=0 alphaChnl=0 redChnl=4 greenChnl=4 blueChnl=4",
        *page_lines,
        f"chars count={len(characters)}",
        *char_lines,
        "kernings count=0",
        "",
    ]
    (OUTPUT / "KoreanBonus.fnt").write_text("\n".join(descriptor), encoding="utf-8")
    print(f"Built {len(characters)} Korean glyphs across {page_count} bitmap-font pages")


if __name__ == "__main__":
    main()
