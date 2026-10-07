extends Control

const DESTINATION = "user://content/marches-riders-0.6.pck"
var requirements: Dictionary = {}
var status = "Checking installed game data…"
var busy = false
var import_button: Button
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
	picker.filters = PackedStringArray(["*.pck ; Iron Crowns game data"])
	picker.file_selected.connect(import_data)
	add_child(picker)
	call_deferred("prepare")

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO,size),Color("101c20"))
	var title = "IRON CROWNS / RIDERS OF THE MARCHES"
	draw_string(heading,Vector2(135,155),title,HORIZONTAL_ALIGNMENT_LEFT,-1,29,Color("ded5c1"))
	draw_string(body,Vector2(135,215),"APK + DATA  /  OFFLINE INSTALLATION",HORIZONTAL_ALIGNMENT_LEFT,-1,16,Color("c0a67e"))
	var lines = ["This APK is the game engine and code. Its separate Data file contains", "materials, sound and the equipment/world catalog. Both downloads are required.", "1. Download Iron-Crowns-0.6.0-Data.pck from the same release as this APK.", "2. Tap Import Game Data and select that file in Android's file picker.", "3. Keep the game open while it verifies and installs. No Android/obb copying needed."]
	for i in range(lines.size()):
		draw_string(body,Vector2(135,275+i*31),lines[i],HORIZONTAL_ALIGNMENT_LEFT,-1,17,Color("b7c3be"))
	draw_string(body,Vector2(135,590),status,HORIZONTAL_ALIGNMENT_LEFT,-1,16,Color("ddc9a6"))
	draw_string(body,Vector2(135,650),"Wrong or damaged files are rejected before mounting. Your campaign save is not erased.",HORIZONTAL_ALIGNMENT_LEFT,-1,14,Color("899b96"))

func prepare() -> void:
	# Source/editor builds have unpacked assets; shipped Android builds do not.
	if OS.has_feature("editor"):
		start_game()
		return
	var parsed = JSON.parse_string(FileAccess.get_file_as_string("res://assets/data_requirements.json"))
	if not parsed is Dictionary or str(parsed.get("sha256","")).length()!=64 or int(parsed.get("bytes",0))<=0:
		status = "This APK lacks a valid Data manifest. Rebuild with godot-build-split.sh."
		import_button.disabled = true
		queue_redraw()
		return
	requirements = parsed
	if FileAccess.file_exists(DESTINATION):
		await check_installed()
	else:
		require_data("Game Data not installed. Select the matching .pck file to continue.")

func require_data(message: String) -> void:
	busy = false
	import_button.disabled = false
	status = message
	queue_redraw()
	print("IRON_DATA_REQUIRED: "+message)

func select_data() -> void:
	if busy or requirements.is_empty():
		return
	picker.popup_centered_ratio(.85)

func check_installed() -> void:
	busy = true
	import_button.disabled = true
	status = "Verifying installed Data…"
	queue_redraw()
	await get_tree().process_frame
	if await verify(DESTINATION):
		mount_data()
	else:
		require_data("Installed Data is invalid. Import a fresh matching copy; your save is untouched.")

func verify(path: String) -> bool:
	var file = FileAccess.open(path,FileAccess.READ)
	if file==null:
		return false
	if file.get_length()!=int(requirements.bytes):
		file.close()
		return false
	var hash = HashingContext.new()
	hash.start(HashingContext.HASH_SHA256)
	var total = file.get_length()
	var read = 0
	while read<total:
		var bytes = file.get_buffer(mini(1048576,total-read))
		if bytes.is_empty():
			file.close()
			return false
		hash.update(bytes)
		read += bytes.size()
		status = "Checking SHA-256: "+str(int(float(read)/total*100))+"%"
		queue_redraw()
		await get_tree().process_frame
	file.close()
	return hash.finish().hex_encode()==str(requirements.sha256)

func import_data(path: String) -> void:
	if busy or requirements.is_empty():
		return
	busy = true
	import_button.disabled = true
	var source = FileAccess.open(path,FileAccess.READ)
	if source==null:
		require_data("Cannot read that file. Select the downloaded .pck in the system picker.")
		return
	if source.get_length()!=int(requirements.bytes):
		source.close()
		require_data("Wrong Data file size. Download the matching 0.6 file, not an older pack or ZIP.")
		return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("user://content"))
	var target = FileAccess.open(DESTINATION+".part",FileAccess.WRITE)
	if target==null:
		source.close()
		require_data("Cannot create Data storage. Check free device space and try again.")
		return
	var total = source.get_length()
	var read = 0
	var failed = false
	while read<total:
		var bytes = source.get_buffer(mini(1048576,total-read))
		if bytes.is_empty():
			failed = true
			break
		target.store_buffer(bytes)
		if target.get_error()!=OK:
			failed = true
			break
		read += bytes.size()
		status = "Installing Game Data: "+str(int(float(read)/total*100))+"%"
		queue_redraw()
		await get_tree().process_frame
	target.flush()
	failed = failed or target.get_error()!=OK
	target.close()
	source.close()
	if failed or not await verify(DESTINATION+".part"):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(DESTINATION+".part"))
		require_data("Data verification failed. No game files were mounted. Download it again.")
		print("IRON_DATA_REJECTED")
		return
	var error = DirAccess.rename_absolute(ProjectSettings.globalize_path(DESTINATION+".part"),ProjectSettings.globalize_path(DESTINATION))
	if error!=OK:
		require_data("Could not finish the install. Check free storage and retry.")
		return
	mount_data()

func mount_data() -> void:
	if not ProjectSettings.load_resource_pack(ProjectSettings.globalize_path(DESTINATION),true):
		require_data("The verified Data could not be mounted by this engine version.")
		return
	if not ResourceLoader.exists("res://assets/materials/meadow.jpg") or not FileAccess.file_exists("res://assets/content/catalog.json"):
		require_data("Required resources are missing from the Data pack.")
		return
	var catalog = JSON.parse_string(FileAccess.get_file_as_string("res://assets/content/catalog.json"))
	if not catalog is Dictionary or catalog.get("id","")!=requirements.id:
		require_data("Data catalog version does not match this APK.")
		return
	print("IRON_DATA_READY: verified and mounted "+str(requirements.id))
	start_game()

func start_game() -> void:
	get_tree().change_scene_to_file("res://main.tscn")
