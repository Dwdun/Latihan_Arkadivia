extends Node

const SAVE_PATH := "user://save_game_data.json"

func save_game():
	var cp_x = 0.0
	var cp_y = 0.0
	var is_cp_valid = false
	
	if GameManager.last_checkpoint_pos != Vector2.INF:
		cp_x = GameManager.last_checkpoint_pos.x
		cp_y = GameManager.last_checkpoint_pos.y
		is_cp_valid = true

	var save_data = {
		"stage": Global.current_stage,
		"current_level_path": GameManager.current_level_path,
		"character_type": GameManager.current_character_name,

		"checkpoint_active": is_cp_valid,
		"checkpoint_x": cp_x,
		"checkpoint_y": cp_y,
		"checkpoint_level": GameManager.last_checkpoint_level,
		
		"collected_items": GameManager.collected_items_state,
		"gold": InventoryManager.gold,
	}

	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		return false
	
	file.store_string(JSON.stringify(save_data))
	file.close()
	print("Game Tersimpan Aman!")
	return true
	
func load_game():
	if not FileAccess.file_exists(SAVE_PATH):
		print("File save tidak ditemukan.")
		return false
		
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return false

	var content = file.get_as_text()
	var data = JSON.parse_string(content)
	file.close()
	
	if data:
		_apply_loaded_data(data)
		return true
	return false

func _apply_loaded_data(data: Dictionary):
	Global.current_stage = data.get("stage", 1)
	
	if data.has("current_level_path"):
		GameManager.current_level_path = data["current_level_path"]
	
	if data.has("character_type"):
		GameManager.select_character(data["character_type"])
	
	if data.get("checkpoint_active", false) == true:
		GameManager.last_checkpoint_level = data.get("checkpoint_level", "")
		var cx = data.get("checkpoint_x", 0)
		var cy = data.get("checkpoint_y", 0)
		GameManager.last_checkpoint_pos = Vector2(cx, cy)
	else:
		GameManager.last_checkpoint_pos = Vector2.INF
		GameManager.last_checkpoint_level = ""
	
	if data.has("collected_items"):
		GameManager.collected_items_state = data["collected_items"]
	
	if data.has("gold"):
		InventoryManager.gold = data["gold"]
		if GlobalUI: GlobalUI.update_gold_ui(InventoryManager.gold)
	
	print("Data Save Berhasil Dimuat!")

	if GameManager.last_checkpoint_pos != Vector2.INF:
		SceneManager.change_scene(GameManager.last_checkpoint_level, "", true, GameManager.last_checkpoint_pos)
	elif GameManager.current_level_path != "":
		SceneManager.change_scene(GameManager.current_level_path, "start")
