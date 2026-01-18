extends Node

# GUNAKAN user:// AGAR BISA DISIMPAN DI HP/PC PEMAIN (res:// itu read-only)
const SAVE_PATH := "user://save_game_data.json"

func save_game():
	# 1. Siapkan Dictionary Data Utama
	var save_data = {
		"stage": Global.current_stage,
		"current_level_path": GameManager.current_level_path,
		"character_type": GameManager.current_character_name,
		# --- SIMPAN CHECKPOINT ---
		"checkpoint_level": GameManager.last_checkpoint_level,
		# Vector2 tidak bisa di-JSON, jadi kita simpan X dan Y terpisah
		"checkpoint_x": GameManager.last_checkpoint_pos.x,
		"checkpoint_y": GameManager.last_checkpoint_pos.y,
		
		# --- SIMPAN PROGRESS WORLD ---
		"collected_items": GameManager.collected_items_state,
		
		# --- SIMPAN INVENTORY & PLAYER ---
		# Asumsi InventoryManager punya variabel 'gold'
		"gold": InventoryManager.gold,
		# (Opsional) Jika ingin simpan item, InventoryManager butuh fungsi 'get_save_data()'
		# "inventory": InventoryManager.get_save_data() 
	}

	# 2. Tulis ke File
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("Gagal membuka file untuk save!")
		return false
	
	# Simpan sebagai teks JSON
	var json_string = JSON.stringify(save_data)
	file.store_string(json_string)
	file.close()
	
	print("Game Tersimpan! Data: ", save_data)
	return true
	
func load_game():
	if not FileAccess.file_exists(SAVE_PATH):
		print("File save tidak ditemukan.")
		return false
		
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return false
		
	# Baca dan Parse JSON
	var content = file.get_as_text()
	var data = JSON.parse_string(content)
	file.close()
	
	if data:
		_apply_loaded_data(data)
		return true
	return false

func _apply_loaded_data(data: Dictionary):
	# 1. Load Data Global
	Global.current_stage = data.get("stage", 1)
	
	# 2. Load ke GameManager
	if data.has("current_level_path"):
		GameManager.current_level_path = data["current_level_path"]
	
	if data.has("character_type"):
		var char_type = data["character_type"]
		# Beritahu GameManager untuk menyiapkan scene karakter tersebut
		GameManager.select_character(char_type)
	
	# Load Checkpoint
	if data.has("checkpoint_level"):
		GameManager.last_checkpoint_level = data["checkpoint_level"]
		var cx = data.get("checkpoint_x", 0)
		var cy = data.get("checkpoint_y", 0)
		# Jika X dan Y INF (tak terhingga), kembalikan ke Vector2.INF
		if cx == INF or cy == INF:
			GameManager.last_checkpoint_pos = Vector2.INF
		else:
			GameManager.last_checkpoint_pos = Vector2(cx, cy)
	
	# Load Item yang sudah diambil (Coin Anti-Respawn)
	if data.has("collected_items"):
		GameManager.collected_items_state = data["collected_items"]
	
	# 3. Load Inventory
	if data.has("gold"):
		InventoryManager.gold = data["gold"]
		# Update UI Gold
		if GlobalUI: GlobalUI.update_gold_ui(InventoryManager.gold)
	
	print("Data Save Berhasil Dimuat!")
	
	# 4. PINDAHKAN SCENE KE POSISI TERAKHIR
	# Gunakan checkpoint jika ada, jika tidak gunakan level terakhir
	if GameManager.last_checkpoint_pos != Vector2.INF:
		SceneManager.change_scene(GameManager.last_checkpoint_level, "", true, GameManager.last_checkpoint_pos)
	elif GameManager.current_level_path != "":
		SceneManager.change_scene(GameManager.current_level_path, "start")
