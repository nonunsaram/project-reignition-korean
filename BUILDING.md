# Building the Korean language pack

This repository contains the source inputs and patch sources. It does not include a copy of the game.

1. Place the Project Reignition v1.0.0 source checkout beside this repository and apply the files under `source/Project/` to the matching paths.
2. Run both atlas builders from the repository root with Python and Pillow:
   `python scripts/build_korean_bonus_bitmap_font.py`
   `python scripts/build_korean_skill_select_bitmap_font.py`
3. Open `korean-pack-project` once with Godot 4.7 Standard so the fonts, BMFonts, and translation are imported.
4. Run `build_pack.gd` headlessly with the output PCK path as its only argument.
5. Use the Windows installer files and the generated PCK/DLL to assemble a release ZIP.

The shipped release ZIP is the supported end-user artifact. Always test installation and removal against an untouched v1.0.0 game before publishing a new tag.

