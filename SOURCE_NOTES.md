# Source notes

Base project: <https://github.com/kumapauz/project-reignition>

Base branch and version: `dev/v0.5.0`, matching the C# source paths embedded in the public Windows v1.0.0 PDB.

This package changes thirteen source files:

- `Project/core/ModManager.cs`: registers `.translation` resources, preserves original bitmap fonts on Latin-only HUD labels, applies Korean fonts only to Hangul labels, and selects a pre-rendered Korean bitmap atlas for labels originally using `Bonus.fnt`.
- `Project/interface/menu/Description.cs`: applies the localization font at the same moment a menu description changes, avoiding a visible system-font flash.
- `Project/interface/gameplay/pause/PauseMenu.cs`: applies fonts immediately after dynamic pause-menu mission data is assigned.
- `Project/interface/gameplay/hud/script/Bonus.cs`: applies the Korean styled font immediately whenever a dynamic in-game bonus label changes.
- `Project/interface/menu/level select/script/StatusMenu.cs`: reapplies the Korean font after the next-story value changes from a placeholder to a localized area name.
- `Project/interface/menu/level select/script/ReadyMenu.cs`: applies fonts immediately to dynamically assigned map and mission labels.
- `Project/interface/menu/level select/script/LevelOption.cs`: applies fonts immediately to dynamically assigned mission and time-attack labels.
- `Project/interface/menu/special book/script/SpecialBook.cs`: reapplies the Korean font after dynamically assigning the Special Book chapter label and name.
- `Project/interface/transition/TransitionManager.cs`: applies LINE Seed immediately to dynamic loading and mission-description text.
- `Project/resource/script/LocalizationResource.cs`: adds optional general, classic-menu, and decorated-bitmap Korean font properties.
- `Project/interface/menu/options/script/Options.cs`: refreshes the text-language label from the selected locale, including mod languages.
- `Project/video/EventPlayer.cs`: applies the active localization font directly to cutscene subtitles.
- `Project/sound/script/SoundManager.cs`: reapplies the active localization font whenever gameplay dialog text changes.

Copies of all modified files are included in `source/`. They are intended to make later review or submission to the Project Reignition developers straightforward.

The Korean PCK is built separately from `Locale.ko.csv`, LINE Seed KR Regular, 학교안심 상장, two pre-rendered 838-glyph Korean BMFont atlases, the Korean localization resource, and their OFL notices. One atlas matches `Bonus.fnt`; the other matches `Skill Select.fnt` for pause and status screens. Their faces, rims, and shadows are baked into each glyph, so no delayed duplicate labels are used at runtime.
