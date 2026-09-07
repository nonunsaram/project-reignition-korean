using Godot;

[GlobalClass]
/// <summary> Represents a localization. </summary>
public partial class LocalizationResource : Resource
{
	[Export(PropertyHint.LocaleId)] public string LocaleId { get; private set; } = "en";
	[Export] public LocalizationType LocaleType { get; private set; }
	/// <summary> General-purpose fallback used for body and description text. </summary>
	[Export] public Font TextFontFallback { get; private set; }
	/// <summary> Classic menu fallback used for Greco-styled headings and option labels. </summary>
	[Export] public Font MenuTextFontFallback { get; private set; }
	/// <summary> Pre-rendered bitmap fallback matching the decorated Bonus.fnt style. </summary>
	[Export] public Font BonusFontFallback { get; private set; }
	/// <summary> Pre-rendered bitmap fallback matching the parchment Skill Select.fnt style. </summary>
	[Export] public Font SkillSelectFontFallback { get; private set; }

	/// <summary> Tracks wether this localization was modded in or not. </summary>
	public bool IsMod { get; set; }
	public enum LocalizationType
	{
		Text,
		Voice
	}
}
