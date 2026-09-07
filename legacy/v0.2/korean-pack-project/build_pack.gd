extends SceneTree

const TARGET_ROOT := "res://mods/lang/korean/"

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() != 1:
		push_error("Expected the output PCK path as the only user argument.")
		quit(1)
		return

	var project_root := ProjectSettings.globalize_path("res://")
	var imported_root := project_root.path_join(".godot/imported")
	var translation_source := project_root.path_join("Locale.ko.ko.translation")
	var text_font_source := _find_import(imported_root, "LINESeedKR-Rg.ttf-", ".fontdata")
	var menu_font_source := _find_import(imported_root, "Hakgyoansim_SangjangR.ttf-", ".fontdata")
	var bonus_font_source := _find_import(imported_root, "KoreanBonus.fnt-", ".fontdata")
	var skill_select_font_source := _find_import(imported_root, "KoreanSkillSelect.fnt-", ".fontdata")
	if translation_source.is_empty() or text_font_source.is_empty() or menu_font_source.is_empty() or bonus_font_source.is_empty() or skill_select_font_source.is_empty():
		push_error("Required imported resources were not found.")
		quit(2)
		return

	var packer := PCKPacker.new()
	var output_path := args[0]
	var error := packer.pck_start(output_path)
	if error != OK:
		push_error("Could not create PCK: %s" % error_string(error))
		quit(3)
		return

	_add(packer, TARGET_ROOT + "Locale.ko.translation", translation_source)
	_add(packer, TARGET_ROOT + "LINESeedKR-Rg.fontdata", text_font_source)
	_add(packer, TARGET_ROOT + "Hakgyoansim_SangjangR.fontdata", menu_font_source)
	_add(packer, TARGET_ROOT + "KoreanBonus.fontdata", bonus_font_source)
	_add(packer, TARGET_ROOT + "KoreanSkillSelect.fontdata", skill_select_font_source)
	_add(packer, TARGET_ROOT + "text korean.tres", project_root.path_join("staging/text korean.tres"))
	_add(packer, TARGET_ROOT + "LINE-SEED-OFL-1.1.txt", project_root.path_join("staging/LINE-SEED-OFL-1.1.txt"))
	_add(packer, TARGET_ROOT + "SCHOOL-SAFETY-CERTIFICATE-OFL-1.1.txt", project_root.path_join("staging/SCHOOL-SAFETY-CERTIFICATE-OFL-1.1.txt"))
	error = packer.flush()
	if error != OK:
		push_error("Could not finish PCK: %s" % error_string(error))
		quit(4)
		return

	print("Created Korean language pack: %s" % output_path)
	quit()

func _find_import(directory: String, prefix: String, suffix: String) -> String:
	for file_name in DirAccess.get_files_at(directory):
		if file_name.begins_with(prefix) and file_name.ends_with(suffix):
			return directory.path_join(file_name)
	return ""

func _add(packer: PCKPacker, target: String, source: String) -> void:
	var error := packer.add_file(target, source)
	if error != OK:
		push_error("Could not add %s: %s" % [target, error_string(error)])
		quit(5)
