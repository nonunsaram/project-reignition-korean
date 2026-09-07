extends SceneTree

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() < 1 or args.size() > 2 or !ProjectSettings.load_resource_pack(args[0]):
		push_error("Could not load Korean PCK.")
		quit(1)
		return

	var translation := load("res://mods/lang/korean/Locale.ko.translation") as Translation
	var text_font := load("res://mods/lang/korean/LINESeedKR-Rg.fontdata") as Font
	var menu_font := load("res://mods/lang/korean/Hakgyoansim_SangjangR.fontdata") as Font
	var bonus_font := load("res://mods/lang/korean/KoreanBonus.fontdata") as Font
	var skill_select_font := load("res://mods/lang/korean/KoreanSkillSelect.fontdata") as Font
	if translation == null or text_font == null or menu_font == null or bonus_font == null or skill_select_font == null:
		push_error("Korean translation or a required font is missing.")
		quit(2)
		return

	print("Locale: %s" % translation.locale)
	print("Language label: %s" % translation.get_message("lang_ko"))
	print("English baseline: %s" % translation.get_message("sys_select"))
	print("LINE Seed Hangul glyph: %s, height/ascent/descent at 42: %s/%s/%s" % [text_font.has_char("한".unicode_at(0)), text_font.get_height(42), text_font.get_ascent(42), text_font.get_descent(42)])
	print("School Safety Hangul glyph: %s, height/ascent/descent at 42: %s/%s/%s" % [menu_font.has_char("한".unicode_at(0)), menu_font.get_height(42), menu_font.get_ascent(42), menu_font.get_descent(42)])
	print("Bonus bitmap Hangul glyph: %s" % bonus_font.has_char("한".unicode_at(0)))
	print("Skill Select bitmap Hangul glyph: %s" % skill_select_font.has_char("한".unicode_at(0)))
	if args.size() == 2:
		if !ProjectSettings.load_resource_pack(args[1]):
			push_error("Could not load the original game PCK for font metrics.")
			quit(3)
			return
		var greco := load("res://interface/font/otf/Greco Std B.otf") as Font
		var chiaro := load("res://interface/font/otf/Chiaro Std B.otf") as Font
		if greco == null or chiaro == null:
			push_error("Could not load original menu fonts for metrics.")
			quit(4)
			return
		print("Greco menu font height/ascent/descent at 42: %s/%s/%s" % [greco.get_height(42), greco.get_ascent(42), greco.get_descent(42)])
		print("Chiaro description font height/ascent/descent at 42: %s/%s/%s" % [chiaro.get_height(42), chiaro.get_ascent(42), chiaro.get_descent(42)])
	quit()
