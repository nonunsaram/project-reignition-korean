extends SceneTree

func _initialize() -> void:
	var args = OS.get_cmdline_user_args()
	var resource_path = "res://Locale.ko.ko.translation"
	if args.size() > 0:
		if not ProjectSettings.load_resource_pack(args[0]):
			quit(3)
			return
		resource_path = "res://locale/Locale.ko.translation"
	var translation = load(resource_path) as Translation
	if translation == null:
		quit(1)
		return
	TranslationServer.add_translation(translation)
	TranslationServer.set_locale("ko")
	TranslationServer.get_or_add_domain(&"").enabled = true
	var csv = FileAccess.open("res://Locale.ko.csv", FileAccess.READ)
	csv.get_csv_line("\t")
	var count = 0
	var failures = 0
	var blank_rows = 0
	var froggy_rows = 0
	while not csv.eof_reached():
		var row = csv.get_csv_line("\t")
		if row.size() < 2:
			continue
		var actual = String(TranslationServer.translate(row[0]))
		var expected = row[1].c_unescape()
		if expected.is_empty():
			blank_rows += 1
			expected = row[0]
		if actual != expected or actual.contains("개굴이"):
			push_error("Mismatch: " + row[0])
			failures += 1
		if row[0] in ["spb_desc_ch16_3", "spb_desc_ch16_11", "spb_desc_ch16_15"]:
			froggy_rows += 1
			print(row[0] + " = " + actual)
			if not actual.contains("개구리 군"):
				failures += 1
		count += 1
	if froggy_rows != 3:
		failures += 1
	if args.size() > 0:
		for filename in ["KoreanLocalization.gd", "KoreanFontWatcher.gd"]:
			var source = FileAccess.get_file_as_string("res://mods/lang/korean/" + filename)
			if source.contains("Translation.new") or source.contains("add_translation") or source.contains("TRANSLATION_CORRECTIONS"):
				push_error("Temporary override remains in PCK")
				failures += 1
		print("PCK temporary translation override absent")
	print("Verified CSV rows: %d; empty fallback rows: %d; Froggy rows: %d; failures: %d; class: %s" % [count, blank_rows, froggy_rows, failures, translation.get_class()])
	quit(0 if failures == 0 else 2)
