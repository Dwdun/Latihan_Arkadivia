extends Node

const SAVE_PATH := "res://_core/data/saved_session.json"

func save_game():
	if not FileAccess.file_exists(SAVE_PATH):
		return false

	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		return false
	
	Global.data["stage"] = Global.current_stage
	file.store_string(JSON.stringify(Global.data))
	file.close()
	return true
	
func load_game():
	if not FileAccess.file_exists(SAVE_PATH):
		return false
		
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	var data = JSON.parse_string(file.get_as_text())
	file.close()
	
	if data != null:
		Global.data = data
		return true
