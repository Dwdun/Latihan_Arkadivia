extends Node

var current_level_path: String = ""

var enchanter = preload("res://entities/player/enchanter.tscn") # Ganti path sesuai file Anda
var executioner = preload("res://entities/player/executioner.tscn")
var item_test = load("res://items/resources/potion_item.tres") # 
var item_test2 = load("res://items/resources/key.tres") # 

var current_character_scene: PackedScene

var is_cutscene: bool = false

func _ready() -> void:
	# Cheat isi tasPastikan path benar
	if item_test:
		InventoryManager.add_item(item_test, 5)
		InventoryManager.add_item(item_test, 10) # Total 15
		InventoryManager.add_item(item_test2, 5)
		InventoryManager.add_item(item_test2, 11) # Total 15

# Fungsi untuk membekukan waktu sejenak
func hit_stop(time_scale: float, duration: float):
	Engine.time_scale = time_scale
	
	# Kita harus menunggu menggunakan timer yang mengabaikan time_scale (real time)
	# create_timer(waktu, process_always, process_in_physics, ignore_time_scale)
	await get_tree().create_timer(duration, true, false, true).timeout
	
	Engine.time_scale = 1.0 # Kembalikan waktu normal

# Fungsi untuk ganti karakter (Dipanggil dari Menu Select)
func select_character(type: String):
	match type:
		"enchanter": current_character_scene = enchanter
		"executioner": current_character_scene = executioner
		_: print("Karakter tidak dikenal!")

func respawn_player():
	print("GameManager: Memulai proses respawn...")
	
	# 1. Delay sedikit (agar animasi mati/partikel sempat terlihat)
	await get_tree().create_timer(0.5).timeout
	
	# 2. Ambil path scene saat ini sebelum dihapus
	if get_tree().current_scene:
		current_level_path = get_tree().current_scene.scene_file_path
	
	# 3. Validasi Path
	if current_level_path == "":
		push_error("GameManager: Gagal reload, path level tidak ditemukan!")
		return

	# 4. PANGGIL SCENE MANAGER (KUNCI SUKSES)
	# Kita minta SceneManager memuat ulang level ini DAN menaruh player di titik "start"
	# Parameter: (Path Level, ID Pintu Default)
	SceneManager.change_scene(current_level_path, "start")

# Di game_manager.gd

func set_cutscene_mode(active: bool):
	is_cutscene = active
	
	if active:
		if GlobalUI: GlobalUI.hide_ui()
		# Matikan kontrol player (Opsional: Bisa lewat Group)
		var player = get_tree().get_first_node_in_group("player")
		if player:
			player.set_physics_process(false) # Bekukan gerakan
			player.velocity = Vector2.ZERO # Stop momentum
			if player.has_node("AnimationPlayer"):
				player.get_node("AnimationPlayer").play("Idle") # Paksa Idle
	else:
		if GlobalUI: GlobalUI.show_ui()
		# Nyalakan kontrol player lagi
		var player = get_tree().get_first_node_in_group("player")
		if player:
			player.set_physics_process(true)
