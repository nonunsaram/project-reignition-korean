"""Build a Korean BMFont atlas matching Project Reignition's Skill Select.fnt."""

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
    return 0x1100 <= code <= 0x11FF or 0x3130 <= code <= 0x318F or 0xAC00 <= code <= 0xD7A3


def shifted(mask: Image.Image, x: int, y: int) -> Image.Image:
    result = Image.new("L", mask.size)
    result.paste(mask, (x, y))
    return result


def render_glyph(character: str, font: ImageFont.FreeTypeFont) -> Image.Image:
    center = CELL_SIZE // 2
    glyph = Image.new("L", (CELL_SIZE, CELL_SIZE))
    ImageDraw.Draw(glyph).text((center, center - 1), character, font=font, fill=255, anchor="mm")

    # Skill Select.fnt has a pale parchment face, a narrow tan rim and a soft,
    # dark red-brown edge extending mostly down and right.
    dark_edge = shifted(glyph.filter(ImageFilter.MaxFilter(9)), 1, 2)
    tan_rim = glyph.filter(ImageFilter.MaxFilter(5))

    image = Image.new("RGBA", (CELL_SIZE, CELL_SIZE))
    image.paste((77, 15, 0, 225), mask=dark_edge)
    image.paste((194, 150, 103, 255), mask=tan_rim)
    image.paste((234, 219, 185, 255), mask=glyph)

    lower_shade = ImageChops.subtract(glyph, shifted(glyph, -1, -1))
    lower_shade = lower_shade.filter(ImageFilter.GaussianBlur(0.35))
    image.paste((194, 150, 103, 210), mask=lower_shade)

    highlight = ImageChops.subtract(glyph, shifted(glyph, 1, 1))
    highlight = highlight.filter(ImageFilter.GaussianBlur(0.3))
    image.paste((255, 244, 215, 180), mask=highlight)
    return image


def main() -> None:
    document = json.loads(TRANSLATION.read_text(encoding="utf-8"))
    characters = sorted(
        {character for entry in document["entries"] for character in entry["ko"] if is_korean(character)},
        key=ord,
    )
    font = ImageFont.truetype(str(FONT), FONT_SIZE)
    page_count = math.ceil(len(characters) / CELLS_PER_PAGE)
    pages = [Image.new("RGBA", (ATLAS_SIZE, ATLAS_SIZE)) for _ in range(page_count)]

    char_lines: list[str] = []
    for index, character in enumerate(characters):
        page_index = index // CELLS_PER_PAGE
        cell_index = index % CELLS_PER_PAGE
        x = (cell_index % CELLS_PER_ROW) * CELL_SIZE
        y = (cell_index // CELLS_PER_ROW) * CELL_SIZE
        pages[page_index].alpha_composite(render_glyph(character, font), (x, y))
        advance = max(45, round(font.getlength(character)))
        char_lines.append(
            f"char id={ord(character)} x={x} y={y} width={CELL_SIZE} height={CELL_SIZE} "
            f"xoffset=-10 yoffset=-10 xadvance={advance} page={page_index} chnl=15"
        )

    page_lines = []
    for page_index, page in enumerate(pages):
        filename = f"KoreanSkillSelect_{page_index}.png"
        page.save(OUTPUT / filename, optimize=True)
        page_lines.append(f'page id={page_index} file="{filename}"')

    descriptor = [
        'info face="Hakgyoansim Sangjang Skill Select" size=80 bold=0 italic=0 charset="" unicode=1 stretchH=100 smooth=1 aa=1 padding=10,10,10,10 spacing=1,1 outline=0',
        f"common lineHeight={LINE_HEIGHT} base={BASELINE} scaleW={ATLAS_SIZE} scaleH={ATLAS_SIZE} pages={page_count} packed=0 alphaChnl=0 redChnl=4 greenChnl=4 blueChnl=4",
        *page_lines,
        f"chars count={len(characters)}",
        *char_lines,
        "kernings count=0",
        "",
    ]
    (OUTPUT / "KoreanSkillSelect.fnt").write_text("\n".join(descriptor), encoding="utf-8")
    print(f"Built {len(characters)} Korean glyphs across {page_count} Skill Select pages")


if __name__ == "__main__":
    main()
