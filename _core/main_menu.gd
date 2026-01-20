extends Control

@onready var mute_master_btn = $Panel/MarginContainer/Container/HBoxContainer/MuteMasterButton
@onready var mute_music_btn = $Panel/MarginContainer/Container/HBoxContainer/MuteMusicButton
func _ready() -> void:
	if GlobalUI:
		GlobalUI.hide_ui()
	SettingsManager.load_settings()
	_update_mute_master_button_visual()
	# HAPUS baris SavingSystem.load_game() disini.
	# Kita tidak ingin load game otomatis saat menu terbuka,
	# tapi hanya saat tombol "Load/Resume" ditekan.
	
	# print(Global.data) <- Hapus atau comment
	# print(Global.settings)

func _on_new_game_pressed() -> void:
	# 1. RESET DATA DULU (Penting! Agar inventory/gold sisa main sebelumnya hilang)
	GameManager.reset_game_data()
	
	# 2. Pindah ke Level 1 (Gunakan SceneManager agar ada loading screen)
	# Pastikan path level 1 Anda benar
	get_tree().change_scene_to_file("res://ui/main_menu.tscn")
	# Atau jika pakai nama dummy level teman:
	# SceneManager.change_scene("res://levels/dummy_level_1.tscn", "start")

func _on_load_pressed() -> void:
	# 1. Panggil Load dari SavingSystem
	var success = SavingSystem.load_game()
	
	if success:
		print("Save file ditemukan, sedang memuat...")
		# Tidak perlu get_tree().change_scene... lagi disini, 
		# karena SavingSystem otomatis memanggil SceneManager.
	else:
		print("Tidak ada file save ditemukan!")
		# (Opsional) Tampilkan pop-up "No Save Data" ke player

func _on_settings_pressed() -> void:
	get_tree().change_scene_to_file("res://_core/settings_menu.tscn")

func _on_quit_pressed() -> void:
	get_tree().quit()

func _on_credit_pressed() -> void:
	SceneManager.change_scene("res://_core/credit.tscn", "", false)

# ... (Bagian Volume/Mute biarkan saja, itu sudah benar logika teman Anda) ...
func _on_mute_master_pressed() -> void:
	var bus_index := AudioServer.get_bus_index("Master")
	AudioServer.set_bus_mute(bus_index, not AudioServer.is_bus_mute(bus_index))
	Global.settings["master_is_muted"] = AudioServer.is_bus_mute(bus_index)
	SettingsManager.apply_settings()
	SettingsManager.save_settings()
	_update_mute_master_button_visual()

func _on_mute_music_pressed() -> void:
	var bus_index := AudioServer.get_bus_index("Music")
	AudioServer.set_bus_mute(bus_index, not AudioServer.is_bus_mute(bus_index))
	Global.settings["music_volume"] = 0
	Global.settings["music_is_muted"] = AudioServer.is_bus_mute(bus_index)
	SettingsManager.apply_settings()
	SettingsManager.save_settings()
	_update_mute_music_button_visual()

func _update_mute_master_button_visual():
	# Cek apakah master sedang di-mute?
	var is_muted = Global.settings["master_is_muted"]
	
	if is_muted:
		mute_master_btn.modulate = Color.RED # Beri warna merah biar jelas mati
	else:
		mute_master_btn.modulate = Color.WHITE
		
func _update_mute_music_button_visual():
	# Cek apakah master sedang di-mute?
	var is_muted = Global.settings["music_is_muted"]
	
	if is_muted:
		mute_music_btn.modulate = Color.RED # Beri warna merah biar jelas mati
	else:
		mute_music_btn.modulate = Color.WHITE
