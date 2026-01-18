extends Node

var current_level_path: String = ""

var enchanter = preload("res://entities/player/enchanter.tscn")
var executioner = preload("res://entities/player/executioner.tscn")
var item_test = load("res://items/resources/potion_item.tres")
var item_test2 = load("res://items/resources/key.tres")

var last_checkpoint_pos: Vector2 = Vector2.INF
var last_checkpoint_level: String = ""

var collected_items_state: Dictionary = {}

var current_character_scene: PackedScene
var current_character_name: String = ""

var is_cutscene: bool = false

var camera_left: int
var camera_right: int
var camera_top: int
var camera_bottom: int
var camera_zoom: int

func _ready() -> void:
	if item_test:
		InventoryManager.add_item(item_test, 5)
		InventoryManager.add_item(item_test, 10)
		InventoryManager.add_item(item_test2, 5)
		InventoryManager.add_item(item_test2, 11)

func hit_stop(time_scale: float, duration: float):
	Engine.time_scale = time_scale

	await get_tree().create_timer(duration, true, false, true).timeout
	
	Engine.time_scale = 1.0 

func select_character(type: String):
	current_character_name = type
	match type:
		"enchanter": current_character_scene = enchanter
		"executioner": current_character_scene = executioner
		_: print("Karakter tidak dikenal!")

func respawn_player():
	print("GameManager: Memulai proses respawn...")

	await get_tree().create_timer(0.5).timeout

	if get_tree().current_scene:
		current_level_path = get_tree().current_scene.scene_file_path

	if current_level_path == "":
		push_error("GameManager: Gagal reload!")
		return

	if last_checkpoint_pos != Vector2.INF and last_checkpoint_level == current_level_path:
		SceneManager.change_scene(current_level_path, "", true, last_checkpoint_pos)
	else:
		SceneManager.change_scene(current_level_path, "start")


func is_item_collected(id: String) -> bool:
	return collected_items_state.has(id)

func register_collected_item(id: String):
	collected_items_state[id] = true

func set_cutscene_mode(active: bool):
	is_cutscene = active
	
	if active:
		if GlobalUI: GlobalUI.hide_ui()

		var player = get_tree().get_first_node_in_group("player")
		if player:
			player.set_physics_process(false)
			player.velocity = Vector2.ZERO
			if player.has_node("AnimationPlayer"):
				player.get_node("AnimationPlayer").play("Idle")
	else:
		if GlobalUI: GlobalUI.show_ui()
		var player = get_tree().get_first_node_in_group("player")
		if player:
			player.set_physics_process(true)

func register_checkpoint(pos: Vector2, level_path: String):
	last_checkpoint_pos = pos
	last_checkpoint_level = level_path
	print("Checkpoint Saved at: ", pos)
	
func rescue_player_from_fall(player_node: Node2D):
	# 1. Ambil Path Level yang SEDANG AKTIF secara langsung (Real-time)
	var active_scene_path = ""
	if get_tree().current_scene:
		active_scene_path = get_tree().current_scene.scene_file_path
	
	print("Rescue Check: Checkpoint Level [", last_checkpoint_level, "] vs Active Level [", active_scene_path, "]")
	
	# 2. Tentukan Posisi Target
	var target_pos = Vector2.ZERO
	
	# Bandingkan dengan active_scene_path, BUKAN current_level_path
	if last_checkpoint_pos != Vector2.INF and last_checkpoint_level == active_scene_path:
		target_pos = last_checkpoint_pos
		print(" -> Menggunakan CHECKPOINT di: ", target_pos)
	else:
		# Fallback ke Pintu Start
		var doors = get_tree().get_nodes_in_group("doors")
		for door in doors:
			if door.has_method("get_id") and door.get_id() == "start":
				target_pos = door.get_spawn_position()
				print(" -> Checkpoint tidak valid/beda level. Menggunakan PINTU START.")
				break
	
	# 3. Teleportasi
	if target_pos != Vector2.ZERO:
		player_node.global_position = target_pos
		
		# Reset Velocity & State
		if player_node.get("velocity"):
			player_node.velocity = Vector2.ZERO
		
		# Reset Kamera agar langsung snap (tidak pusing)
		if player_node.has_node("Camera2D"):
			player_node.get_node("Camera2D").reset_smoothing()
			
		# (Opsional) Efek visual spawn ulang (misal kedip)
		if player_node.has_method("_start_iframe_blink"):
			player_node._start_iframe_blink()
	else:
		push_error("GameManager: TIDAK ADA TEMPAT RESPAWN! Cek apakah Checkpoint aktif atau ada pintu ID 'start'.")
	
	# Tambahkan di bagian bawah script

func reset_game_data():
	# Reset Checkpoint
	last_checkpoint_pos = Vector2.INF
	last_checkpoint_level = ""
	
	# Reset Item yang diambil (Koin muncul lagi)
	collected_items_state.clear()
	
	# Reset Inventory (Jika InventoryManager punya fungsi reset)
	InventoryManager.gold = 0
	# InventoryManager.clear_inventory() 
	
	print("Data Game Direset (New Game Mode)")
