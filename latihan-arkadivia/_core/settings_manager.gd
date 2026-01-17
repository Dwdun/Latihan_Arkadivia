extends Node

var SETTINGS_PATH = "res://_core/data/settings.json"

func save_settings():
	if not FileAccess.file_exists(SETTINGS_PATH):
		return false

	var file = FileAccess.open(SETTINGS_PATH, FileAccess.WRITE)
	if file == null:
		return false
		
	file.store_string(JSON.stringify(Global.settings))
	file.close()
	return true
	
func load_settings():
	if not FileAccess.file_exists(SETTINGS_PATH):
		return false
		
	var file = FileAccess.open(SETTINGS_PATH, FileAccess.READ)
	var data = JSON.parse_string(file.get_as_text())
	file.close()
	
	if data != null:
		Global.settings = data
		return true
	
func apply_settings():
	# Audio
	var master_bus = AudioServer.get_bus_index("Master")
	var music_bus = AudioServer.get_bus_index("Music")
	AudioServer.set_bus_mute(master_bus, Global.settings["master_is_muted"])
	AudioServer.set_bus_mute(music_bus, Global.settings["music_is_muted"])
	AudioServer.set_bus_volume_db(master_bus, Global.settings["master_volume"])
	AudioServer.set_bus_volume_db(music_bus, Global.settings["music_volume"])
