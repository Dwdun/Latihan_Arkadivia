extends CanvasLayer

@onready var fader: ColorRect = $Fader

func _ready() -> void:
	fader.color.a = 0.0
	visible = false

# PERHATIKAN BARIS INI: Tambahkan ", spawn_player: bool = true" di akhir kurung
func change_scene(scene_path: String, target_door_id: String = "", spawn_player: bool = true):
	visible = true
	get_tree().paused = true
	
	# 1. Fade Out
	var tween = create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(fader, "color:a", 1.0, 0.5)
	await tween.finished
	
	# 2. Ganti Scene
	get_tree().change_scene_to_file(scene_path)
	
	# Tunggu scene baru benar-benar siap
	await get_tree().process_frame 
	while get_tree().current_scene == null:
		await get_tree().process_frame
	
	# --- LOGIKA SPAWN (YANG TADI ERROR) ---
	var player_instance = null
	
	# Sekarang variabel spawn_player sudah dikenali karena ada di judul fungsi
	if spawn_player:
		player_instance = _spawn_player_in_new_level()
	
	# 3. Teleport ke Pintu
	if target_door_id != "" and player_instance:
		_teleport_player_to_door(player_instance, target_door_id)
	
	# 4. Fade In
	var tween_in = create_tween()
	tween_in.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween_in.tween_property(fader, "color:a", 0.0, 0.5)
	await tween_in.finished
	
	visible = false
	get_tree().paused = false

# Fungsi Baru: Menciptakan Player
func _spawn_player_in_new_level() -> CharacterBody2D:
	# Ambil cetak biru karakter yang dipilih dari GameManager
	var char_scene = GameManager.current_character_scene
	if not char_scene:
		push_error("GameManager: Tidak ada karakter yang dipilih!")
		return null
	
	# Instantiate
	var new_player = char_scene.instantiate()
	
	# Masukkan ke Scene saat ini
	var current_scene = get_tree().current_scene
	current_scene.add_child(new_player)
	
	return new_player

# Update Fungsi Teleport: Menerima 'player' sebagai parameter langsung
func _teleport_player_to_door(player: Node2D, door_id: String):
	if not player: return
	
	var doors = get_tree().get_nodes_in_group("doors")
	for door in doors:
		if door.has_method("get_id") and door.get_id() == door_id:
			player.global_position = door.get_spawn_position()
			# Paksa update kamera jika perlu
			if player.has_node("Camera2D"):
				player.get_node("Camera2D").enabled = false
				player.get_node("Camera2D").enabled = true
			return
	
	push_warning("Pintu " + door_id + " tidak ditemukan! Player spawn di (0,0)")
