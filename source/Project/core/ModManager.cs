using Godot;
using System;
using System.Collections.Generic;
using Project.Gameplay;
using System.Linq;

namespace Project.Core;

public partial class ModManager : Node
{
	public static ModManager Instance;
	public readonly List<LevelDataResource> LevelMods = [];
	public readonly List<SkillResource> CharacterMods = [];

	// Mod paths
	private readonly string ResourceModPath = "res://mods/";
	private readonly string LevelPaths = "levels/";
	private readonly string CustomCharacterPaths = "characters/";
	private readonly string LanguagePaths = "lang/";
	private readonly string ExtrasPaths = "extras/";
	private readonly string PackExtension = "pck";
	private readonly string ZipExtension = "zip";
	private readonly string ResourceExtension = "tres";
	private readonly string TranslationExtension = "translation";
	private readonly string InterfaceFontPath = "res://interface/font/";
	private Font activeTextFontFallback;
	private Font activeMenuFontFallback;
	private Font activeBonusFontFallback;
	private Font activeSkillSelectFontFallback;
	private bool isUiFontWatcherActive;
	private bool isConfigAppliedConnected;
	private readonly Dictionary<ulong, LabelFontState> localizedLabelFonts = [];

	private sealed class LabelFontState
	{
		public LabelSettings OriginalLabelSettings;
		public bool HadFontOverride;
		public Font OriginalFontOverride;
		public Font OriginalEffectiveFont;
		public Font AppliedFont;
		public LabelSettings LocalizedLabelSettings;
	}

	public override void _EnterTree() => Instance = this;

	public override void _Ready()
	{
		ExtractZipFiles();
		CallDeferred(MethodName.SetUpMods);
	}

	public void SetUpMods()
	{
		if (SaveManager.Config.areLevelModsEnabled)
			LoadLevelMods();
		if (SaveManager.Config.areCharaModsEnabled)
			LoadCharacterMods();
		if (SaveManager.Config.areLangModsEnabled)
			LoadLanguageMods();

		if (!DirAccess.DirExistsAbsolute(SaveManager.ModDirectory + ExtrasPaths))
			DirAccess.MakeDirRecursiveAbsolute(SaveManager.ModDirectory + ExtrasPaths);
	}

	/// <summary> Extracts all zip files, then deletes the original zip file. </summary>
	private void ExtractZipFiles()
	{
		LoadZips(SaveManager.ModDirectory);

		// Switch to local resource folder, now that zip are loaded
		DirAccess dirAccess = DirAccess.Open(ResourceModPath);
		if (DirAccess.GetOpenError() != Error.Ok)
			return;

		foreach (string folder in dirAccess.GetDirectories())
			LoadZips(ResourceModPath + folder + "/");
	}

	/// <summary> Loads a .pck from a directory. </summary>
	private void LoadPck(string file, string dir)
	{
		if (!file.GetExtension().Equals(PackExtension))
			return;

		if (!ProjectSettings.LoadResourcePack(dir + file))
			GD.PrintErr($"Couldn't load mod {dir + file}!");

		GD.Print($"Loaded PCK {dir + file}");
	}

	/// <summary> Loads pcks from a given directory. </summary>
	private void LoadPcks(string dir)
	{
		DirAccess dirAccess = DirAccess.Open(dir);
		foreach (string file in dirAccess.GetFiles())
			LoadPck(file, dir);
	}

	private void LoadZip(string file, string dir)
	{
		if (!file.GetExtension().Equals(ZipExtension))
			return;

		ZipReader reader = new();
		reader.Open(dir.PathJoin(file));

		// Extract the zip, copied directly from Godot Docs
		DirAccess rootDir = DirAccess.Open(dir);
		foreach (string filePath in reader.GetFiles())
		{
			if (filePath.EndsWith("/"))
			{
				rootDir.MakeDirRecursive(filePath);
				continue;
			}

			rootDir.MakeDirRecursive(rootDir.GetCurrentDir().PathJoin(filePath).GetBaseDir());
			FileAccess fileAccess = FileAccess.Open(rootDir.GetCurrentDir().PathJoin(filePath), FileAccess.ModeFlags.Write);
			byte[] buffer = reader.ReadFile(filePath);
			fileAccess.StoreBuffer(buffer);
		}

		reader.Close();
		OS.MoveToTrash(dir.PathJoin(file)); // Delete the original zip file
		GD.Print($"Extracted ZIP from {dir.PathJoin(file)} to {dir}");
	}

	/// <summary> Loads pcks from a given directory. </summary>
	private void LoadZips(string dir)
	{
		GD.Print($"Loading directory {dir}");
		DirAccess dirAccess = DirAccess.Open(dir);

		foreach (string folder in dirAccess.GetDirectories())
			LoadZips(dir.PathJoin(folder));

		foreach (string file in dirAccess.GetFiles())
			LoadZip(file, dir);
	}

	private void LoadLevelMods()
	{
		if (!DirAccess.DirExistsAbsolute(SaveManager.ModDirectory + LevelPaths))
			DirAccess.MakeDirRecursiveAbsolute(SaveManager.ModDirectory + LevelPaths);

		LoadPcks(SaveManager.ModDirectory + LevelPaths);

		// Switch to local resource folder, now that pcks are loaded
		DirAccess dirAccess = DirAccess.Open(ResourceModPath + LevelPaths);
		if (DirAccess.GetOpenError() != Error.Ok)
			return;

		foreach (string level in dirAccess.GetDirectories())
			LoadModLevel(ResourceModPath + LevelPaths + level + "/");
	}

	private void LoadModLevel(string dir)
	{
		DirAccess levelDir = DirAccess.Open(dir); // Access the specific mod directory
		string[] files = levelDir.GetFiles();
		foreach (string file in files) // Find the level data resource
		{
			string fileName = file;
			if (fileName.EndsWith(".remap"))
				fileName = fileName.Replace(".remap", string.Empty);

			if (!fileName.GetFile().GetExtension().Equals(ResourceExtension))
				continue;

			Resource resource = ResourceLoader.Load(dir + fileName);
			if (resource is not LevelDataResource)
				continue;

			LevelMods.Add(resource as LevelDataResource);
			GD.Print($"Loaded custom level {fileName}.");
		}
	}

	private void LoadCharacterMods()
	{
		if (!DirAccess.DirExistsAbsolute(SaveManager.ModDirectory + CustomCharacterPaths))
			DirAccess.MakeDirRecursiveAbsolute(SaveManager.ModDirectory + CustomCharacterPaths);

		LoadPcks(SaveManager.ModDirectory + CustomCharacterPaths);

		// Switch to local resource folder, now that pcks are loaded
		DirAccess dirAccess = DirAccess.Open(ResourceModPath + CustomCharacterPaths);
		if (DirAccess.GetOpenError() != Error.Ok)
			return;

		SkillResource baseCharacterSkill = Runtime.Instance.SkillList.GetSkill(SkillKey.Character);
		baseCharacterSkill.Augments = [];
		foreach (string character in dirAccess.GetDirectories())
			LoadModCharacter(ResourceModPath + CustomCharacterPaths + character + "/", baseCharacterSkill);
	}

	private void LoadModCharacter(string dir, SkillResource baseCharacterSkill)
	{
		DirAccess levelDir = DirAccess.Open(dir); // Access the specific mod directory
		string[] files = levelDir.GetFiles();
		foreach (string file in files) // Find the level data resource
		{
			string fileName = file;
			if (fileName.EndsWith(".remap"))
				fileName = fileName.Replace(".remap", string.Empty);

			if (!fileName.GetFile().GetExtension().Equals(ResourceExtension))
				continue;

			Resource resource = ResourceLoader.Load(dir + fileName);
			if (resource is not SkillResource)
				continue;

			SkillResource characterResource = resource.Duplicate() as SkillResource;
			characterResource.Key = SkillKey.Character;
			characterResource.Element = SkillResource.SkillElement.Config;
			characterResource.Category = SkillResource.SkillCategory.Setting;
			characterResource.AugmentIndex = baseCharacterSkill.Augments.Count + 1;
			baseCharacterSkill.Augments.Add(characterResource);
			CharacterMods.Add(characterResource);
			GD.Print($"Loaded custom character {fileName} in slot {characterResource.AugmentIndex}");
		}
	}

	private void LoadModLanguage(string dir)
	{
		DirAccess levelDir = DirAccess.Open(dir); // Access the specific mod directory
		string[] files = levelDir.GetFiles();
		foreach (string file in files) // Load language resources
		{
			string fileName = file;
			if (fileName.EndsWith(".remap"))
				fileName = fileName.Replace(".remap", string.Empty);

			string extension = fileName.GetFile().GetExtension();
			if (extension.Equals(TranslationExtension))
			{
				Translation translation = ResourceLoader.Load<Translation>(dir + fileName);
				if (translation == null)
					continue;

				TranslationServer.AddTranslation(translation);
				GD.Print($"Loaded custom translation {fileName}.");
				continue;
			}

			if (!extension.Equals(ResourceExtension))
				continue;

			Resource resource = ResourceLoader.Load(dir + fileName);
			if (resource is not LocalizationResource)
				continue;

			GD.Print($"Found localization resource {fileName}.");
			LocalizationResource locale = resource as LocalizationResource;
			locale.IsMod = true;
			if (locale.LocaleType == LocalizationResource.LocalizationType.Text)
			{
				if (locale.TextFontFallback != null)
					RegisterTextFontFallback(locale.TextFontFallback);
				if (locale.MenuTextFontFallback != null)
					RegisterMenuTextFontFallback(locale.MenuTextFontFallback);
				if (locale.BonusFontFallback != null)
					RegisterBonusFontFallback(locale.BonusFontFallback);
				if (locale.SkillSelectFontFallback != null)
					RegisterSkillSelectFontFallback(locale.SkillSelectFontFallback);

				if (SaveManager.FindTextLocaleIndex(locale.LocaleId) != -1) // Already exists
					continue;

				SaveManager.Instance.TextLocalizations.Add(locale);
			}
			else
			{
				if (SaveManager.FindVoiceLocaleIndex(locale.LocaleId) != -1) // Already exists
					continue;

				SaveManager.Instance.VoiceLocalizations.Add(locale);
			}

			GD.Print($"Loaded custom language {fileName}.");
		}
	}

	/// <summary> Adds a localization font after the game's original fonts, preserving their Latin styling. </summary>
	private void RegisterTextFontFallback(Font fallback)
	{
		activeTextFontFallback = fallback;
		AddFontFallback(ThemeDB.FallbackFont, fallback);
		RegisterTextFontFallbacksInDirectory(InterfaceFontPath, fallback);
		ActivateUiFontWatcher();
		GD.Print($"Registered localization font fallback {fallback.ResourcePath}. Hangul support: {fallback.HasChar('한')}.");
	}

	/// <summary> Uses a separate fallback for the book-like Greco font used by menus and options. </summary>
	private void RegisterMenuTextFontFallback(Font fallback)
	{
		activeMenuFontFallback = fallback;
		string[] menuFontPaths =
		{
			"res://interface/font/otf/Greco Std B.otf",
			"res://interface/font/otf/Greco Std DB.otf",
			"res://interface/font/otf/Greco Std M.otf",
			"res://interface/font/otf/Greco SSi Italic.ttf",
			"res://interface/font/otf/Greco Std B Fallback.otf",
			"res://interface/font/bitmap fonts/Skill Select.fnt",
			"res://interface/font/bitmap fonts/Keyboard Style.fnt"
		};

		foreach (string path in menuFontPaths)
			AddFontFallback(ResourceLoader.Load<Font>(path), fallback, true);

		ActivateUiFontWatcher();

		GD.Print($"Registered localization menu font fallback {fallback.ResourcePath}. Hangul support: {fallback.HasChar('한')}.");
	}

	/// <summary> Uses a pre-rendered Hangul atlas for labels originally drawn with Bonus.fnt. </summary>
	private void RegisterBonusFontFallback(Font fallback)
	{
		activeBonusFontFallback = fallback;
		Font originalBonusFont = ResourceLoader.Load<Font>("res://interface/font/bitmap fonts/Bonus.fnt");
		AddFontFallback(fallback, originalBonusFont);
		ActivateUiFontWatcher();
		GD.Print($"Registered Korean Bonus bitmap font {fallback.ResourcePath}. Hangul support: {fallback.HasChar('한')}.");
	}

	/// <summary> Uses a pre-rendered Hangul atlas for labels originally drawn with Skill Select.fnt. </summary>
	private void RegisterSkillSelectFontFallback(Font fallback)
	{
		activeSkillSelectFontFallback = fallback;
		Font originalFont = ResourceLoader.Load<Font>("res://interface/font/bitmap fonts/Skill Select.fnt");
		AddFontFallback(fallback, originalFont);
		ActivateUiFontWatcher();
		GD.Print($"Registered Korean Skill Select bitmap font {fallback.ResourcePath}. Hangul support: {fallback.HasChar('한')}.");
	}

	private void ActivateUiFontWatcher()
	{
		if (!isUiFontWatcherActive)
		{
			GetTree().NodeAdded += ApplyUiFontToNode;
			isUiFontWatcherActive = true;
		}
		if (!isConfigAppliedConnected && SaveManager.Instance != null)
		{
			SaveManager.Instance.ConfigApplied += RefreshUiFonts;
			isConfigAppliedConnected = true;
		}

		CallDeferred(MethodName.ApplyUiFontsToExistingTree);
	}

	private void RefreshUiFonts()
	{
		CallDeferred(MethodName.ApplyUiFontsToExistingTree);
	}

	private void ApplyUiFontsToExistingTree() => ApplyUiFontToBranch(GetTree().Root);

	private void ApplyUiFontToBranch(Node node)
	{
		ApplyUiFontToNode(node);
		foreach (Node child in node.GetChildren())
			ApplyUiFontToBranch(child);
	}

	public void ApplyLocalizationFont(Label label) => ApplyUiFontToNode(label);

	private void ApplyUiFontToNode(Node node)
	{
		if (node is not Label label || activeTextFontFallback == null)
			return;
		ulong id = label.GetInstanceId();
		if (!IsKoreanTextLocaleActive())
		{
			RestoreOriginalFont(label, id);
			return;
		}

		string localizedText = TranslationServer.Translate(label.Text).ToString();
		if (!ContainsHangul(localizedText))
		{
			// Latin-only HUD counters and result labels must keep their original
			// bitmap fonts, including baked colors and decorative outlines.
			RestoreOriginalFont(label, id);
			return;
		}

		if (!localizedLabelFonts.TryGetValue(id, out LabelFontState state))
		{
			state = new LabelFontState
			{
				OriginalLabelSettings = label.LabelSettings,
				HadFontOverride = label.HasThemeFontOverride("font"),
				OriginalFontOverride = label.HasThemeFontOverride("font") ? label.GetThemeFont("font") : null,
				OriginalEffectiveFont = label.LabelSettings?.Font ?? label.GetThemeFont("font")
			};
			localizedLabelFonts.Add(id, state);
			label.TreeExiting += () => localizedLabelFonts.Remove(id);
		}

		bool isBonusBitmapFont = IsBonusBitmapFont(state.OriginalEffectiveFont);
		bool isSkillSelectBitmapFont = IsSkillSelectBitmapFont(state.OriginalEffectiveFont);
		bool isClassicMenuFont = IsClassicMenuFont(state.OriginalEffectiveFont);
		Font targetFont = isBonusBitmapFont && activeBonusFontFallback != null
			? activeBonusFontFallback
			: isSkillSelectBitmapFont && activeSkillSelectFontFallback != null
			? activeSkillSelectFontFallback
			: isClassicMenuFont && activeMenuFontFallback != null
			? activeMenuFontFallback
			: activeTextFontFallback;
		bool isLocalizedFontStillApplied = label.LabelSettings == state.LocalizedLabelSettings;
		if (state.AppliedFont == targetFont && isLocalizedFontStillApplied)
			return;

		// Godot's bitmap UI fonts do not consistently follow fallback chains for
		// Hangul. Replace the font only on labels that actually contain Korean,
		// while retaining every other LabelSettings property (color, outline,
		// spacing, shadow, and size). Latin-only HUD labels stay untouched above.
		LabelSettings localizedSettings = state.OriginalLabelSettings != null
			? state.OriginalLabelSettings.Duplicate() as LabelSettings
			: CreateLabelSettingsFromTheme(label);
		localizedSettings.Font = targetFont;
		ApplyScreenSpecificKoreanStyle(label, localizedSettings, state.OriginalEffectiveFont, isClassicMenuFont);
		label.LabelSettings = localizedSettings;
		state.LocalizedLabelSettings = localizedSettings;
		state.AppliedFont = targetFont;
	}

	private static LabelSettings CreateLabelSettingsFromTheme(Label label) => new()
	{
		FontSize = label.GetThemeFontSize("font_size"),
		FontColor = label.GetThemeColor("font_color"),
		OutlineColor = label.GetThemeColor("font_outline_color"),
		OutlineSize = label.GetThemeConstant("outline_size"),
		ShadowColor = label.GetThemeColor("font_shadow_color"),
		ShadowSize = label.GetThemeConstant("shadow_outline_size"),
		ShadowOffset = new Vector2(
			label.GetThemeConstant("shadow_offset_x"),
			label.GetThemeConstant("shadow_offset_y")),
		LineSpacing = label.GetThemeConstant("line_spacing")
	};

	private static bool IsKoreanTextLocaleActive() => SaveManager.Config.textLocale?.LocaleId == "ko";

	private static bool ContainsHangul(string text)
	{
		foreach (char character in text)
		{
			if ((character >= '\u1100' && character <= '\u11FF') ||
				(character >= '\u3130' && character <= '\u318F') ||
				(character >= '\uAC00' && character <= '\uD7A3'))
				return true;
		}
		return false;
	}

	private static bool IsPauseInterfaceLabel(Label label)
	{
		string path = label.GetPath().ToString().ToLowerInvariant();
		return path.Contains("/pause/") && !path.Contains("/quitmenu/");
	}

	private static bool IsBonusBitmapFont(Font font) =>
		font?.ResourcePath.ToLowerInvariant().Contains("bonus.fnt") == true;

	private static bool IsSkillSelectBitmapFont(Font font) =>
		font?.ResourcePath.ToLowerInvariant().Contains("skill select.fnt") == true;

	/// <summary>
	/// The original pause font stores its brown-and-gold appearance inside bitmap
	/// glyph textures. Vector Hangul has no such pixels, so recreate the closest
	/// equivalent with normal label colors, outline, and shadow.
	/// </summary>
	private static void ApplyScreenSpecificKoreanStyle(Label label, LabelSettings settings, Font originalFont, bool isClassicMenuFont)
	{
		if (!isClassicMenuFont)
			return;
		if (IsSkillSelectBitmapFont(originalFont))
			return;

		if (!IsPauseInterfaceLabel(label))
			return;

		settings.FontColor = new Color("B96A27");
		settings.OutlineColor = new Color("3A170A");
		settings.OutlineSize = Math.Max(settings.OutlineSize, 2);
		settings.ShadowColor = new Color(0.0f, 0.0f, 0.0f, 0.5f);
		settings.ShadowSize = Math.Max(settings.ShadowSize, 3);
		settings.ShadowOffset = new Vector2(1.0f, 2.0f);
	}

	private void RestoreOriginalFont(Label label, ulong id)
	{
		if (!localizedLabelFonts.Remove(id, out LabelFontState state))
			return;

		label.LabelSettings = state.OriginalLabelSettings;

		if (state.HadFontOverride)
			label.AddThemeFontOverride("font", state.OriginalFontOverride);
		else
			label.RemoveThemeFontOverride("font");
	}

	private bool IsClassicMenuFont(Font font)
	{
		if (font == null)
			return false;
		if (font == activeMenuFontFallback)
			return true;

		string path = font.ResourcePath.ToLowerInvariant();
		return path.Contains("greco") ||
			path.Contains("skill select.fnt") || path.Contains("keyboard style.fnt") || path.Contains("bonus.fnt");
	}

	private void RegisterTextFontFallbacksInDirectory(string dir, Font fallback)
	{
		DirAccess fontDir = DirAccess.Open(dir);
		if (DirAccess.GetOpenError() != Error.Ok)
			return;

		foreach (string folder in fontDir.GetDirectories())
			RegisterTextFontFallbacksInDirectory(dir.PathJoin(folder), fallback);

		foreach (string file in fontDir.GetFiles())
		{
			string fileName = file.EndsWith(".remap") ? file.Replace(".remap", string.Empty) : file;
			string extension = fileName.GetExtension();
			if (!extension.Equals("fnt") && !extension.Equals("otf") && !extension.Equals("ttf"))
				continue;

			Font font = ResourceLoader.Load<Font>(dir.PathJoin(fileName));
			AddFontFallback(font, fallback);
		}
	}

	private static void AddFontFallback(Font font, Font fallback, bool insertFirst = false)
	{
		if (font == null || font == fallback)
			return;

		int fallbackIndex = font.Fallbacks.IndexOf(fallback);
		if (fallbackIndex != -1)
		{
			if (insertFirst && fallbackIndex > 0)
			{
				font.Fallbacks.RemoveAt(fallbackIndex);
				font.Fallbacks.Insert(0, fallback);
			}
			return;
		}

		if (insertFirst)
			font.Fallbacks.Insert(0, fallback);
		else
			font.Fallbacks.Add(fallback);
	}

	private void LoadLanguageMods()
	{
		if (!DirAccess.DirExistsAbsolute(SaveManager.ModDirectory + LanguagePaths))
			DirAccess.MakeDirRecursiveAbsolute(SaveManager.ModDirectory + LanguagePaths);

		LoadPcks(SaveManager.ModDirectory + LanguagePaths);

		// Switch to local resource folder, now that pcks are loaded
		DirAccess dirAccess = DirAccess.Open(ResourceModPath + LanguagePaths);
		if (DirAccess.GetOpenError() != Error.Ok)
			return;

		LoadModLanguage(ResourceModPath + LanguagePaths + "/"); // Load base language folder
		foreach (string language in dirAccess.GetDirectories())
			LoadModLanguage(ResourceModPath + LanguagePaths + language + "/"); // Load nested language folders

		SaveManager.LoadConfig(); // Reload the config in case a mod language was originally selected
	}
}
