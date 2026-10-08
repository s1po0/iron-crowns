extends Control

var bundle = ContentBundle.new()
var updating = false
var needs_restart = false
var status = "Checking installed game data…"
var busy = false
var import_button: Button
var android_picker: Object
var picker: FileDialog
var heading: Font = preload("res://assets/fonts/cinzel.ttf")
var body: Font = preload("res://assets/fonts/lato.ttf")

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	import_button = Button.new()
	import_button.text = "IMPORT GAME DATA"
	import_button.position = Vector2(400,485)
	import_button.size = Vector2(480,60)
	import_button.add_theme_font_size_override("font_size",20)
	import_button.pressed.connect(select_data)
	add_child(import_button)
	picker = FileDialog.new()
	picker.access = FileDialog.ACCESS_FILESYSTEM
	picker.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	picker.use_native_dialog = true
	picker.filters = PackedStringArray(["*.icdata ; Iron Crowns game data"])
	picker.file_selected.connect(import_data)
	add_child(picker)
	if OS.get_name()=="Android" and Engine.has_singleton("DataPicker"):
		android_picker = Engine.get_singleton("DataPicker")
		android_picker.connect("data_selected",complete_native_import)
		android_picker.connect("data_error",require_data)
		android_picker.connect("data_progress",native_progress)
	call_deferred("prepare")

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO,size),Color("101c20"))
	var title = "IRON CROWNS / PEOPLES OF THE MARCHES"
	draw_string(heading,Vector2(135,155),title,HORIZONTAL_ALIGNMENT_LEFT,-1,29,Color("ded5c1"))
	draw_string(body,Vector2(135,215),"APK + DATA  /  OFFLINE INSTALLATION",HORIZONTAL_ALIGNMENT_LEFT,-1,16,Color("c0a67e"))
	var lines = ["This APK is the game engine and code. Its separate Data file contains", "human meshes, materials, sound, factions and the world. No scripts are loaded.", "1. Download compatible API 1 .icdata content. Later Data releases need no new APK.", "2. Tap Import Game Data and select that file in Android's file picker.", "3. Keep the game open while it verifies and installs. No Android/obb copying needed."]
	for i in range(lines.size()):
		draw_string(body,Vector2(135,275+i*31),lines[i],HORIZONTAL_ALIGNMENT_LEFT,-1,17,Color("b7c3be"))
	draw_string(body,Vector2(135,590),status,HORIZONTAL_ALIGNMENT_LEFT,-1,16,Color("ddc9a6"))
	draw_string(body,Vector2(135,650),"Checksums detect corruption, not publisher identity. Only install content from sources you trust.",HORIZONTAL_ALIGNMENT_LEFT,-1,14,Color("899b96"))

func prepare() -> void:
	updating = bool(get_tree().get_meta("update_data",false)) or FileAccess.file_exists("user://manage_data.request")
	DirAccess.remove_absolute(ProjectSettings.globalize_path("user://manage_data.request"))
	get_tree().set_meta("update_data",false)
	if updating:
		require_data("Choose compatible replacement Data. A failed import keeps your previous installation.")
		return
	if OS.has_feature("editor"):
		start_game()
		return
	busy = true
	import_button.disabled = true
	if await bundle.installed(get_tree()):
		print("IRON_DATA_READY: API 1 revision "+str(bundle.manifest.revision))
		start_game()
	else:
		require_data("Compatible Data not installed or damaged. Import an API 1 .icdata file.")

func require_data(message: String) -> void:
	busy = false
	import_button.disabled = false
	status = message
	queue_redraw()
	print("IRON_DATA_REQUIRED: "+message)

func select_data() -> void:
	if needs_restart:
		get_tree().quit()
		return
	if busy:
		return
	if OS.get_name()=="Android":
		if android_picker==null:
			require_data("Missing native importer. Install the official foundation APK.")
			return
		busy = true
		import_button.disabled = true
		android_picker.selectData(ContentBundle.LIMIT)
	else:
		picker.popup_centered_ratio(.85)

func import_data(path: String) -> void:
	if busy:
		return
	await complete_native_import(path)

func complete_native_import(path: String) -> void:
	busy = true
	import_button.disabled = true
	var ok = await bundle.install(path,get_tree(),native_progress)
	# Delete only the native bridge's own temporary copy, never the chosen source.
	if path==ProjectSettings.globalize_path("user://content/selected-data.part"):
		DirAccess.remove_absolute(path)
	if not ok:
		require_data(bundle.error)
		print("IRON_DATA_REJECTED")
		return
	print("IRON_DATA_INSTALLED: API 1 revision "+str(bundle.manifest.revision))
	if updating:
		needs_restart = true
		busy = false
		import_button.disabled = false
		import_button.text = "CLOSE GAME — THEN REOPEN"
		status = "New Data installed. Restart to clear old model/material caches. Your save is kept."
		queue_redraw()
		return
	if await bundle.installed(get_tree()):
		print("IRON_DATA_READY: API 1 revision "+str(bundle.manifest.revision))
		start_game()
	else:
		require_data("Installed content could not be verified. Import a fresh copy.")

func native_progress(percent: int) -> void:
	status = "Installing and checking Data: "+str(percent)+"%"
	queue_redraw()

func start_game() -> void:
	get_tree().change_scene_to_file("res://main.tscn")

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch and event.pressed and not import_button.disabled:
		if import_button.get_global_rect().has_point(event.position):
			get_viewport().set_input_as_handled()
			select_data()
