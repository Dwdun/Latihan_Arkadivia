extends Node

# 1. GUNAKAN user:// AGAR BISA DISIMPAN PERMANEN
var SETTINGS_PATH = "user://settings.json"

func save_settings():
	# Tidak perlu cek file_exists saat write, langsung overwrite saja
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
	if file == null: return false
	
	var data = JSON.parse_string(file.get_as_text())
	file.close()
	
	if data != null:
		# Update dictionary Global dengan data yang dimuat
		# Kita gunakan merge agar jika ada setting baru di update game, tidak error
		Global.settings.merge(data, true)
		apply_settings() # Langsung terapkan saat load
		return true
	return false

func apply_settings():
	# 2. KONVERSI VOLUME (PENTING!)
	# Slider 0.0 - 1.0 harus diubah ke Decibel (dB)
	
	var master_bus = AudioServer.get_bus_index("Master")
	var music_bus = AudioServer.get_bus_index("Music") # Pastikan bus ini ada!
	
	# Atur Mute
	AudioServer.set_bus_mute(master_bus, Global.settings["master_is_muted"])
	# Cek apakah index music valid (-1 artinya tidak ditemukan)
	if music_bus != -1:
		AudioServer.set_bus_mute(music_bus, Global.settings["music_is_muted"])
	
	# Atur Volume (Gunakan linear_to_db)
	AudioServer.set_bus_volume_db(master_bus, linear_to_db(Global.settings["master_volume"]))
	
	if music_bus != -1:
		AudioServer.set_bus_volume_db(music_bus, linear_to_db(Global.settings["music_volume"]))
